"""Execute production QML logic offscreen; replace only unavailable host boundaries.
This does not validate Quickshell geometry, IPC, native process signals or Hyprland.
"""
import os, sys, tempfile, shutil, re, json
from pathlib import Path
os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
os.environ.setdefault('QT_QUICK_BACKEND', 'software')
from PySide6.QtCore import QUrl, qInstallMessageHandler, QObject, QSettings, Qt, Signal, Property, Slot, QTimer, QSaveFile, QIODevice
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlEngine, QQmlComponent, qmlRegisterType
from PySide6.QtTest import QTest
from PySide6.QtQuick import QQuickWindow, QQuickItem

root = Path(__file__).resolve().parents[2]
tmp = tempfile.TemporaryDirectory()
stage = Path(tmp.name)
os.environ['XDG_CONFIG_HOME'] = str(stage / 'config')
(stage / 'config').mkdir()
messages = []
def handler(kind, context, message):
    messages.append(message)
qInstallMessageHandler(handler)
app = QGuiApplication([])
app.setOrganizationName('101-test')
app.setApplicationName('101-test')
for source in root.glob('*.js'): shutil.copy(source, stage/source.name)
for source in root.glob('*.qml'):
    text = source.read_text()
    text = re.sub(r'^import (Quickshell.*|qs\..*)\n', '', text, flags=re.M)
    # Native window anchoring and layer-shell attached properties are unavailable.
    text = text.replace('PanelWindow {', 'Rectangle {\n    property var screen: ({width:1280, height:900})')
    text = re.sub(r'^    (anchors \{ top:.*|margins \{.*|WlrLayershell\..*|exclusionMode:.*)\n', '', text, flags=re.M)
    text = text.replace('Quickshell.env(', 'Environment.env(').replace('Ui.Button {', 'Button {')
    (stage/source.name).write_text(text)
# Context is a boundary: scenarios explicitly supply compositor state.
(stage/'Context.qml').write_text('import QtQuick\nQtObject { property var snapshot: ({available:false}) }')
(stage/'Environment.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { function env(key) { return key === "XDG_CONFIG_HOME" ? '+repr(str(stage/'config')).replace("'",'"')+' : "" } }')
(stage/'Style.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
 property int gapsOut: 8
 property int cornerRadius: 0
 property var spacing: ({panelPadding:16, md:12, sm:6})
 property var font: ({family:"monospace", body:12, displayLarge:28, heading:16, caption:10})
 function space(value) { return value }
}''')
(stage/'Color.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { property var popups: ({background:"#111111",text:"#ffffff",border:"#555555"}); property color accent: "#00ffff" }')
(stage/'Border.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { function surfaceSpec() { return {} } }')
(stage/'BorderSurface.qml').write_text('import QtQuick\nRectangle { property var borderSpec; property int padding:0 }')
(stage/'Button.qml').write_text('''import QtQuick
Rectangle {
 property string text
 property bool focusable: false
 signal clicked()
 implicitWidth: 180; implicitHeight: 30
 activeFocusOnTab: focusable
 Keys.onSpacePressed: clicked()
 Keys.onReturnPressed: clicked()
}''')
(stage/'Process.qml').write_text('''import QtQuick
QtObject {
 property bool running:false
 property var command
 property QtObject stdout
 signal exited(int exitCode, int exitStatus)
 signal started()
 function signal(value) { running=false }
}''')
(stage/'StdioCollector.qml').write_text('import QtQuick\nQtObject { property string text:""; signal streamFinished() }')
(stage/'qmldir').write_text('\n'.join('singleton '+n+' 1.0 '+n+'.qml' for n in ['Environment','Style','Color','Border']))
(stage/'Host.qml').write_text('''import QtQuick
QtObject {
 property var guide
 property var service
 property int summons: 0
 function serviceFor(id) { return service }
 function summon(id, payload) { summons += 1; guide.open(payload); return true }
}''')

# FileView is a host boundary. Exercise real Qt atomic disk writes via QSaveFile,
# with queued completion signals; native Quickshell integration remains a host gate.
class TestFileView(QObject):
    loaded = Signal()
    loadFailed = Signal(int)
    saved = Signal()
    saveFailed = Signal(int)
    pathChanged = Signal()
    def __init__(self, parent=None):
        super().__init__(parent); self._path=''; self._text=''
    def get_path(self): return self._path
    def set_path(self, path):
        self._path=path; self.pathChanged.emit()
        if path: QTimer.singleShot(0,self.read)
    path = Property(str,get_path,set_path,notify=pathChanged)
    printErrors = Property(bool,lambda self:False,lambda self,v:None)
    atomicWrites = Property(bool,lambda self:True,lambda self,v:None)
    def read(self):
        try:
            self._text=Path(self._path).read_text(); self.loaded.emit()
        except FileNotFoundError: self.loadFailed.emit(2)
        except OSError: self.loadFailed.emit(1)
    @Slot(result=str)
    def text(self): return self._text
    @Slot(str)
    def setText(self,text):
        def write():
            f=QSaveFile(self._path)
            data=text.encode()
            if not f.open(QIODevice.WriteOnly): self.saveFailed.emit(1); return
            if f.write(data) != len(data): f.cancelWriting(); self.saveFailed.emit(1); return
            if not f.commit(): self.saveFailed.emit(1); return
            self._text=text; self.saved.emit()
        QTimer.singleShot(0,write)
qmlRegisterType(TestFileView,'TestIO',1,0,'FileView')
store=stage/'ProgressStore.qml'
store.write_text('import TestIO 1.0\n'+store.read_text())
(stage/'FileViewError.qml').write_text('pragma Singleton\nimport QtQuick\nQtObject { enum Error { PermissionDenied = 1, FileNotFound = 2 } }')
with (stage/'qmldir').open('a') as f: f.write('\nsingleton FileViewError 1.0 FileViewError.qml\n')

engine = QQmlEngine()
components=[]
def create(name, settle=True):
    component=QQmlComponent(engine,QUrl.fromLocalFile(str(stage/name)))
    obj=component.create()
    assert obj is not None, '\n'.join(e.toString() for e in component.errors())
    components.append(component)
    if settle: QTest.qWait(30)
    return obj

def call(obj, expr):
    # Run in QML so JS objects and method calls preserve the actual engine semantics.
    engine.globalObject().setProperty('subject', engine.newQObject(obj))
    value=engine.evaluate(expr)
    assert not value.isError(), value.toString()
    return value.toVariant()

early=create('Panel.qml',False)
call(early,'subject.open("{\\"lesson\\":\\"browser\\"}")')
QTest.qWait(80)
assert early.property('lessonIndex') == 4, 'targeted summon must survive initial asynchronous loading'
early.deleteLater(); QTest.qWait(20)

panel=create('Panel.qml')
window=QQuickWindow(); window.resize(600,900)
panel.setParentItem(window.contentItem()); window.show()
call(panel, 'subject.open("{\\"lesson\\":\\"terminal\\"}")')
assert panel.property('opened') and panel.property('started')
assert panel.property('lessonIndex') == 1
call(panel, 'subject.mark("self")')
assert panel.property('completionCount') == 1
call(panel, 'subject.close()')
assert not panel.property('opened') and not panel.property('practising') and not panel.property('contextEnabled')
call(panel, 'subject.open("null")')
assert panel.property('opened')
call(panel, 'subject.select(NaN)')
assert panel.property('lessonIndex') == 1, 'invalid selection must preserve the current lesson'
# Real focus and scrolling in an offscreen Qt window, with stub button chrome.
call(panel,'subject.open("{}"); subject.started=true')
QTest.qWait(30)
button=next(o for o in panel.findChildren(QQuickItem) if o.property('text') == 'Use desktop context')
button.forceActiveFocus()
QTest.qWait(20)
scroller=panel.findChild(QObject,'guideScroller')
assert button.hasActiveFocus() and scroller.property('contentY') > 0, 'focused controls must scroll into view'
QTest.keyClick(window,Qt.Key_Escape)
assert not panel.property('opened'), 'Escape from a focused button must close the panel'
# Settings is real QtCore, not a stub; verify actual on-disk progress and reload.
QTest.qWait(600)
ini = stage / 'config' / 'omarchy-101.ini'
progress_file = stage / 'config' / 'omarchy-101-progress.json'
assert progress_file.exists() and 'terminal' in progress_file.read_text(), 'completion must reach disk'
restored=create('Panel.qml')
assert restored.property('completionCount') == 1, 'progress must survive a new panel'
# Disarming must happen before changing any exercise state.
call(panel, 'subject.open("{}")')
call(panel, 'subject.practising=true; subject.select(2)')
assert not panel.property('practising')
call(panel, 'subject.close(); subject.practise(); subject.mark("self")')
assert not panel.property('practising') and panel.property('completionCount') == 1

# Actual QML Process handlers with a signal-controlled process boundary.
shortcuts=create('Shortcuts.qml')
shortcuts.setProperty('enabledForSession', True)
call(shortcuts,'subject.refresh()')
process=shortcuts.findChild(QObject,'shortcutProcess')
assert process is not None and shortcuts.property('status') == 'loading'
process.setProperty('running',False)  # FailedToStart: no exited signal.
QTest.qWait(20)
assert shortcuts.property('status') == 'failed', 'missing executable must leave loading'
call(shortcuts,'subject.refresh()')
shortcuts.setProperty('enabledForSession',False)
shortcuts.setProperty('enabledForSession',True)
call(shortcuts,'subject.refresh()')
QTest.qWait(20)
assert shortcuts.property('status') == 'idle', 'cancelled request must not restart during shutdown'
call(shortcuts,'subject.refresh()')
assert shortcuts.property('status') == 'loading'
process.exited.emit(1,0)
process.setProperty('running',False)
QTest.qWait(20)
assert shortcuts.property('status') == 'failed'

# First-run service receives its host late and acknowledges only a shown panel.
service=create('Service.qml'); host=create('Host.qml')
host.setProperty('guide',restored); host.setProperty('service',service)
restored.setProperty('shell',host)
service.setProperty('shell',host)
QTest.qWait(1100)
assert host.property('summons') == 1 and restored.property('opened')
call(restored,'subject.close()')
service2=create('Service.qml'); service2.setProperty('shell',host)
QTest.qWait(1100)
assert host.property('summons') == 1, 'dismissed welcome must not be offered on reload'

# A failed write keeps the current session and can retry the same value.
progress_file.unlink(); progress_file.mkdir()
call(panel,'subject.open("{}"); subject.mark("self")')
QTest.qWait(50)
store=panel.findChild(QObject,'progressStore')
assert store.property('dirty') and store.property('error') and not store.property('busy')
assert panel.property('completionCount') == 2
progress_file.rmdir()
call(store,'subject.retry()')
QTest.qWait(50)
assert not store.property('dirty') and not store.property('error')
assert len(json.loads(progress_file.read_text())['completed']) == 2
# Rapid changes while an asynchronous write is active must save the latest state.
call(panel,'subject.select(3); subject.mark("self"); subject.select(4); subject.mark("self")')
QTest.qWait(80)
assert json.loads(progress_file.read_text())['currentLesson'] == 'browser'
assert len(json.loads(progress_file.read_text())['completed']) == 4
# Reset failure is visible and retryable too.
progress_file.unlink(); progress_file.mkdir()
call(store,'subject.reset({version:1,completed:{},currentLesson:"super"})')
QTest.qWait(50)
assert store.property('dirty') and store.property('error')
progress_file.rmdir(); call(store,'subject.retry()'); QTest.qWait(50)
assert json.loads(progress_file.read_text())['completed'] == {}
# A future JSON schema is preserved even when practising.
future='{"version":9,"completed":{"future-lesson":"observed"}}'
progress_file.write_text(future)
protected=create('Panel.qml')
assert protected.property('progressBlocked')
call(protected,'subject.open("{}"); subject.mark("self"); subject.select(1)')
QTest.qWait(50)
assert progress_file.read_text() == future
# A read failure is not treated as an empty save, and reset cannot bypass it.
progress_file.unlink(); progress_file.mkdir()
unreadable=create('ProgressStore.qml')
assert unreadable.property('readFailed') and unreadable.property('blocked')
call(unreadable,'subject.reset({version:1,completed:{},currentLesson:"super"})')
assert unreadable.property('blocked') and progress_file.is_dir()
progress_file.rmdir()
# Real QtCore migration: original INI remains byte-for-byte unchanged.
settings=QSettings(str(ini),QSettings.IniFormat)
settings.setValue('101/progress','{"version":1,"completed":{"terminal":"observed"}}')
settings.setValue('101/currentLesson','terminal'); settings.sync()
legacy_bytes=ini.read_bytes()
migrated=create('Panel.qml')
assert migrated.property('completionCount') == 1 and migrated.property('lessonIndex') == 1
call(migrated,'subject.open("{}"); subject.mark("self")'); QTest.qWait(50)
assert ini.read_bytes() == legacy_bytes
assert json.loads(progress_file.read_text())['completed']['terminal'] == 'observed'
# Corrupt legacy data is protected when no new-format file exists.
progress_file.unlink()
settings.setValue('101/progress',future); settings.sync()
legacy_protected=create('Panel.qml')
assert legacy_protected.property('progressBlocked')
call(legacy_protected,'subject.open("{}"); subject.mark("self")'); QTest.qWait(50)
assert not progress_file.exists()
# Failed welcome writes expose the same retry state through the service.
welcome_file=stage/'config'/'omarchy-101-welcome.json'
welcome_file.unlink(); welcome_file.mkdir()
call(service,'subject.acknowledge("finished")'); QTest.qWait(50)
assert call(service,'subject.storage.dirty && subject.storage.error.length > 0')
welcome_file.rmdir(); call(service,'subject.storage.retry()'); QTest.qWait(50)
assert json.loads(welcome_file.read_text())['state'] == 'finished'

QTest.qWait(20)
errors=[m for m in messages if any(x in m for x in ['TypeError','ReferenceError','Error:','Cannot assign','Binding loop'])]
assert not errors, '\n'.join(errors)
print('QML: load, summon, selection, disk persistence, schema preservation, atomic save failure/retry, migration, queued writes, cancellation, process failure and welcome reload passed')
for obj in [panel,restored,protected,unreadable,migrated,legacy_protected,shortcuts,service,service2,host]: obj.deleteLater()
QTest.qWait(20)
engine.deleteLater()
QTest.qWait(20)
