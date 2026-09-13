import QtQuick
import QtCore
import "Paths.js" as Paths
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Lessons.js" as Lessons
import "Articles.js" as Articles
import "Shortcuts.js" as ShortcutRules

Item {
  id: root
  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool started: false
  readonly property bool progressBlocked: saved.blocked
  property bool resetPending: false
  property bool choosingLesson: false
  property bool welcomeInvocation: false
  property bool contextEnabled: false
  property int lessonIndex: 0
  property int pendingLesson: -1
  property bool hintVisible: false
  property bool practising: false
  property bool detected: false
  property var exerciseBaseline: ({})
  property var completed: ({})
  readonly property var lesson: Lessons.lessons[lessonIndex]
  readonly property var article: Articles.forLesson(lesson.id)
  property string articleError: ""
  readonly property var context: contextLoader.item ? contextLoader.item.snapshot : ({available: false})
  readonly property int completionCount: Object.keys(completed).length

  ProgressStore {
    id: saved
    objectName: "progressStore"
    onRestored: {
      root.completed = value.completed
      var index = Lessons.lessons.findIndex(function(item) { return item.id === value.currentLesson })
      root.lessonIndex = index >= 0 ? index : Lessons.nextIncomplete(root.completed)
      if (root.pendingLesson >= 0) { root.select(root.pendingLesson); root.pendingLesson = -1 }
    }
  }
  readonly property var welcomeStore: shell && shell.serviceFor("io.github.tcballard.omarchy-101") ? shell.serviceFor("io.github.tcballard.omarchy-101").storage : null
  function saveProgress() {
    saved.save({version:1, completed:completed, currentLesson:lesson.id})
  }
  Shortcuts { id: shortcuts; enabledForSession: root.opened }
  function acknowledgeWelcome(action) {
    var service = shell ? shell.serviceFor("io.github.tcballard.omarchy-101") : null
    if (service) service.acknowledge(action)
  }
  function startTour() {
    if (!saved.ready) return
    started = true
    choosingLesson = false
    select(Lessons.nextIncomplete(completed))
    acknowledgeWelcome("started")
  }
  Loader { id: contextLoader; active: root.opened && root.contextEnabled; source: "Context.qml" }
  onContextChanged: {
    if (opened && practising && !detected && Lessons.observed(lesson.check, exerciseBaseline, context)) {
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
    var requested = Articles.requestedLesson(payloadJson, Lessons.lessons)
    if (requested >= 0) {
      started = true
      choosingLesson = false
      if (saved.ready) select(requested)
      else pendingLesson = requested
    }
    welcomeInvocation = requested < 0 && payload.welcome === true
    if (welcomeInvocation) { started = false; choosingLesson = false; acknowledgeWelcome("offered") }
    opened = true
  }
  function close() {
    if (!started) acknowledgeWelcome("dismissed")
    opened = false
    practising = false
    exerciseBaseline = ({})
    contextEnabled = false
    resetPending = false
  }
  function select(index) {
    if (!saved.ready) return
    if (typeof index !== "number" || !Number.isInteger(index) || index < 0 || index >= Lessons.lessons.length) return
    // Disarm before changing the lesson: QML bindings evaluate synchronously.
    practising = false
    detected = false
    exerciseBaseline = ({})
    lessonIndex = index
    hintVisible = false
    articleError = ""
    saveProgress()
    scroller.contentY = 0
  }
  function mark(evidence) {
    if (!saved.ready || !opened || ["self", "observed"].indexOf(evidence) < 0) return
    var next = Object.assign({}, completed)
    // A later self-confirmation must not erase previously observed evidence.
    if (next[lesson.id] !== "observed") next[lesson.id] = evidence
    completed = next
    saveProgress()
    practising = false
    if (completionCount === Lessons.lessons.length) acknowledgeWelcome("finished")
  }
  function practise() {
    if (!opened || !contextEnabled || !context.available || lesson.check === "manual") return
    exerciseBaseline = Lessons.cleanContext(context)
    detected = false
    practising = true
  }
  PanelWindow {
    id: panel
    objectName: "guideWindow"
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
        objectName: "guideScroller"
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
          GuideText { width: parent.width; visible: !saved.ready; text: "Loading saved progress…" }
          GuideText { width: parent.width; visible: saved.busy || saved.error !== ""; text: saved.busy ? "Saving progress…" : saved.error }
          GuideButton { visible: saved.dirty && !saved.busy; text: "Retry saving progress"; onClicked: saved.retry() }
          GuideText { width: parent.width; visible: !!root.welcomeStore && root.welcomeStore.error !== ""; text: root.welcomeStore ? root.welcomeStore.error : "" }
          GuideButton { visible: !!root.welcomeStore && root.welcomeStore.dirty && !root.welcomeStore.busy; text: "Retry saving welcome choice"; onClicked: root.welcomeStore.retry() }
          GuideButton { text: root.started ? "Close guide" : "Not now"; focusable: true; onClicked: root.close() }
          GuideButton { visible: !root.started; enabled: saved.ready; text: root.completionCount > 0 ? "Continue learning" : "Start the tour"; focusable: true; onClicked: root.startTour() }
          GuideButton {
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
                GuideButton {
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
            enabled: saved.ready
            width: parent.width
            spacing: Style.spacing.md
            GuideText { width: parent.width; text: (root.lessonIndex + 1) + ". " + root.lesson.title; font.pixelSize: Style.font.heading; font.bold: true }
            GuideText { width: parent.width; text: root.lesson.explain }
            GuideText { width: parent.width; visible: !!root.article; text: root.article ? "Explaining Omarchy: " + root.article.title : "" }
            GuideButton {
              visible: !!root.article
              text: "Read Tom's explanation"; focusable: true
              onClicked: {
                var article = Articles.forLesson(root.lesson.id)
                root.articleError = article && Qt.openUrlExternally(article.url) ? "" : "Could not open the article in your browser."
              }
            }
            GuideText { width: parent.width; visible: root.articleError !== ""; text: root.articleError }

            GuideText { width: parent.width; text: "TRY THIS"; color: Color.accent; font.pixelSize: Style.font.caption }
            GuideText { width: parent.width; text: root.lesson.action }
            GuideButton { text: "Find my shortcuts"; enabled: shortcuts.status !== "loading"; focusable: true; onClicked: shortcuts.refresh() }
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
            GuideButton { text: root.hintVisible ? "Hide hint" : "Give me a hint"; focusable: true; onClicked: root.hintVisible = !root.hintVisible }
            GuideText { width: parent.width; visible: root.hintVisible; text: root.lesson.hint }
            GuideButton {
              visible: root.lesson.check !== "manual" && root.contextEnabled && root.context.available && !root.practising
              text: "Watch me try"; focusable: true; onClicked: root.practise()
            }
            GuideText {
              width: parent.width
              visible: root.practising || root.detected || !!root.completed[root.lesson.id]
              text: root.practising ? "Ready. Try the action now. If it cannot be detected, you can confirm it below." : (root.completed[root.lesson.id] === "observed" ? "Observed on your desktop. Nicely done." : "Completed — confirmed by you.")
            }
            GuideButton { text: "I've done this"; focusable: true; onClicked: root.mark("self") }
            Flow {
              width: parent.width; spacing: Style.spacing.sm
              GuideButton { text: "Previous"; enabled: root.lessonIndex > 0; focusable: true; onClicked: root.select(root.lessonIndex - 1) }
              GuideButton { text: "Next"; enabled: root.lessonIndex < Lessons.lessons.length - 1; focusable: true; onClicked: root.select(root.lessonIndex + 1) }
            }
            GuideText { width: parent.width; text: "Skipping ahead does not mark a lesson complete."; font.pixelSize: Style.font.caption }
          }
          Rectangle { width: parent.width; height: 1; color: Color.popups.border }
          GuideText { width: parent.width; text: "Help for this moment"; font.bold: true }
          GuideText { width: parent.width; text: root.contextEnabled ? Lessons.suggestion(root.context) : "Allow app and workspace context while this guide is open. No screenshots, window titles, typed text or uploads." }
          GuideButton {
            text: root.contextEnabled ? "Stop using desktop context" : "Use desktop context"
            focusable: true
            onClicked: { root.practising = false; root.exerciseBaseline = ({}); root.contextEnabled = !root.contextEnabled }
          }
          GuideText { width: parent.width; text: "Progress is saved on this computer when storage is available. Context switches off when you close 101."; font.pixelSize: Style.font.caption }
          GuideText {
            width: parent.width
            visible: root.progressBlocked
            text: "Saved progress could not be understood. It has been preserved. You can practise for this session, or reset it below."
          }
          GuideButton {
            visible: root.completionCount > 0 || root.progressBlocked
            enabled: saved.ready && !saved.readFailed && !saved.busy
            text: root.resetPending ? "Confirm reset" : "Reset lesson progress"; focusable: true
            onClicked: {
              if (!root.resetPending) { root.resetPending = true; return }
              root.practising = false; root.detected = false; root.exerciseBaseline = ({}); root.completed = ({}); root.lessonIndex = 0; saved.reset({version:1, completed:{}, currentLesson:root.lesson.id}); root.resetPending = false
            }
          }
          GuideButton { visible: root.resetPending; text: "Keep my progress"; focusable: true; onClicked: root.resetPending = false }
        }
      }
    }
  }
}
