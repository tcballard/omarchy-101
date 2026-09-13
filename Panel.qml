import QtQuick
import QtCore
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Lessons.js" as Lessons
import "Shortcuts.js" as ShortcutRules

Item {
  id: root
  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool started: false
  property bool choosingLesson: false
  property bool welcomeInvocation: false
  property bool contextEnabled: false
  property int lessonIndex: 0
  property bool hintVisible: false
  property bool practising: false
  property bool detected: false
  property var baseline: ({})
  property var completed: ({})
  readonly property var lesson: Lessons.lessons[lessonIndex]
  readonly property var context: contextLoader.item ? contextLoader.item.snapshot : ({available: false})
  readonly property int completionCount: Object.keys(completed).length

  Settings {
    id: saved
    fileName: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy-101.ini"
    category: "101"
    property string progress: ""
    property string currentLesson: ""
  }
  Component.onCompleted: {
    completed = Lessons.restore(saved.progress)
    var index = Lessons.lessons.findIndex(function(item) { return item.id === saved.currentLesson })
    lessonIndex = index >= 0 ? index : Lessons.nextIncomplete(completed)
  }
  Shortcuts { id: shortcuts; enabledForSession: root.opened }
  function acknowledgeWelcome(action) {
    var service = shell ? shell.serviceFor("io.github.tcballard.omarchy-101") : null
    if (service) service.acknowledge(action)
  }
  function startTour() {
    started = true
    choosingLesson = false
    select(Lessons.nextIncomplete(completed))
    acknowledgeWelcome("started")
  }
  Loader { id: contextLoader; active: root.opened && root.contextEnabled; source: "Context.qml" }
  onContextChanged: {
    if (opened && practising && !detected && Lessons.observed(lesson.check, baseline, context)) {
      detected = true
      practising = false
      mark("observed")
    }
  }
  function open(payloadJson) {
    var payload = ({})
    if (typeof payloadJson === "string" && payloadJson.length <= 1024) {
      try { payload = JSON.parse(payloadJson) || ({}) } catch (_) {}
    }
    welcomeInvocation = payload.welcome === true
    if (welcomeInvocation) { started = false; choosingLesson = false; acknowledgeWelcome("offered") }
    opened = true
  }
  function close() {
    if (!started) acknowledgeWelcome("dismissed")
    opened = false
    practising = false
    baseline = ({})
    contextEnabled = false
  }
  function select(index) {
    lessonIndex = Math.max(0, Math.min(Lessons.lessons.length - 1, index))
    practising = false
    detected = false
    baseline = ({})
    hintVisible = false
    saved.currentLesson = lesson.id
    saved.sync()
    scroller.contentY = 0
  }
  function mark(evidence) {
    var next = Object.assign({}, completed)
    // A later self-confirmation must not erase previously observed evidence.
    if (next[lesson.id] !== "observed") next[lesson.id] = evidence
    completed = next
    saved.progress = Lessons.encode(next)
    saved.sync()
    practising = false
    if (completionCount === Lessons.lessons.length) acknowledgeWelcome("finished")
  }
  function practise() {
    baseline = Lessons.cleanContext(context)
    detected = false
    practising = true
  }
  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; right: true }
    margins { top: Style.gapsOut + Style.space(40); right: Style.gapsOut }
    implicitWidth: Math.min(Style.space(390), screen ? screen.width - Style.gapsOut * 2 : Style.space(390))
    implicitHeight: Math.min(Style.space(690), screen ? screen.height - Style.space(100) : Style.space(690))
    color: "transparent"
    WlrLayershell.namespace: "io-github-tcballard-omarchy-101"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    BorderSurface {
      anchors.fill: parent
      color: Color.popups.background
      radius: Style.cornerRadius
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, 1)
      padding: 0
      Flickable {
        id: scroller
        anchors.fill: parent
        anchors.margins: Style.spacing.panelPadding
        contentHeight: content.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Keys.onEscapePressed: root.close()
        Column {
          id: content
          width: parent.width
          spacing: Style.spacing.md
          GuideText { text: "101"; font.pixelSize: Style.font.displayLarge; font.bold: true }
          GuideText { width: parent.width; text: "Explaining Omarchy. Now try it."; color: Color.accent }
          GuideText {
            width: parent.width
            text: root.started ? root.completionCount + " / " + Lessons.lessons.length + " lessons completed" : "Welcome to Omarchy. Seven small lessons will help you find your feet. Skip, repeat or stop whenever you like."
          }
          Button { text: root.started ? "Close guide" : "Not now"; focusable: true; onClicked: root.close() }
          Button { visible: !root.started; text: root.completionCount > 0 ? "Continue learning" : "Start the tour"; focusable: true; onClicked: root.startTour() }
          Button {
            visible: root.started
            text: root.choosingLesson ? "Back to exercise" : "Choose a lesson"
            focusable: true
            onClicked: { root.practising = false; root.choosingLesson = !root.choosingLesson }
          }
          Column {
            visible: root.started && root.choosingLesson
            width: parent.width
            spacing: Style.spacing.sm
            Repeater {
              model: Lessons.lessons
              delegate: Column {
                required property var modelData
                required property int index
                width: parent.width
                GuideText { width: parent.width; text: (index + 1) + ". " + modelData.title }
                Button {
                  text: root.completed[modelData.id] ? "Practise again" : "Try lesson"
                  focusable: true
                  onClicked: { root.select(index); root.choosingLesson = false }
                }
              }
            }
          }
          GuideText {
            visible: root.completionCount === Lessons.lessons.length
            width: parent.width
            text: "Tour complete. You have practised the basics — come back any time to try them again."
            color: Color.accent
          }
          Column {
            visible: root.started && !root.choosingLesson
            width: parent.width
            spacing: Style.spacing.md
            GuideText { width: parent.width; text: (root.lessonIndex + 1) + ". " + root.lesson.title; font.pixelSize: Style.font.heading; font.bold: true }
            GuideText { width: parent.width; text: root.lesson.explain }
            GuideText { width: parent.width; text: "TRY THIS"; color: Color.accent; font.pixelSize: Style.font.caption }
            GuideText { width: parent.width; text: root.lesson.action }
            Button { text: "Find my shortcuts"; enabled: shortcuts.status !== "loading"; focusable: true; onClicked: shortcuts.refresh() }
            GuideText {
              width: parent.width
              text: {
                if (shortcuts.status === "loading") return "Reading your configured shortcuts…"
                if (shortcuts.status === "idle") return "You can use the mouse, or look up your current shortcuts."
                if (shortcuts.status !== "ready") return "Shortcuts could not be resolved. Use your menu or mouse, or try again."
                var matches = ShortcutRules.forLesson(shortcuts.bindings, root.lesson.id)
                return matches.length ? "From your current bindings:\n" + matches.join("\n") : "No matching shortcut could be resolved. Use your menu or mouse."
              }
            }
            Button { text: root.hintVisible ? "Hide hint" : "Give me a hint"; focusable: true; onClicked: root.hintVisible = !root.hintVisible }
            GuideText { width: parent.width; visible: root.hintVisible; text: root.lesson.hint }
            Button {
              visible: root.lesson.check !== "manual" && root.contextEnabled && root.context.available && !root.practising
              text: "Watch me try"; focusable: true; onClicked: root.practise()
            }
            GuideText {
              width: parent.width
              visible: root.practising || root.detected || !!root.completed[root.lesson.id]
              text: root.practising ? "Ready. Try the action now. If it cannot be detected, you can confirm it below." : (root.completed[root.lesson.id] === "observed" ? "Observed on your desktop. Nicely done." : "Completed — confirmed by you.")
            }
            Button { text: "I've done this"; focusable: true; onClicked: root.mark("self") }
            Flow {
              width: parent.width; spacing: Style.spacing.sm
              Button { text: "Previous"; enabled: root.lessonIndex > 0; focusable: true; onClicked: root.select(root.lessonIndex - 1) }
              Button { text: "Next"; enabled: root.lessonIndex < Lessons.lessons.length - 1; focusable: true; onClicked: root.select(root.lessonIndex + 1) }
            }
            GuideText { width: parent.width; text: "Skipping ahead does not mark a lesson complete."; font.pixelSize: Style.font.caption }
          }
          Rectangle { width: parent.width; height: 1; color: Color.popups.border }
          GuideText { width: parent.width; text: "Help for this moment"; font.bold: true }
          GuideText { width: parent.width; text: root.contextEnabled ? Lessons.suggestion(root.context) : "Allow app and workspace context while this guide is open. No screenshots, window titles, typed text or uploads." }
          Button {
            text: root.contextEnabled ? "Stop using desktop context" : "Use desktop context"
            focusable: true
            onClicked: { root.practising = false; root.baseline = ({}); root.contextEnabled = !root.contextEnabled }
          }
          GuideText { width: parent.width; text: "Progress stays on this computer. Context switches off when you close 101."; font.pixelSize: Style.font.caption }
          Button {
            visible: root.completionCount > 0
            text: "Reset lesson progress"; focusable: true
            onClicked: { root.completed = ({}); saved.progress = Lessons.encode({}); saved.sync(); root.select(0) }
          }
        }
      }
    }
  }
}
