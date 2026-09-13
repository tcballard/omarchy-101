import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import "Paths.js" as Paths
import "Lessons.js" as Lessons

// One owner per file: the kept-loaded panel owns progress, the service owns welcome.
Item {
  id: root
  property string kind: "progress"
  readonly property string directory: Paths.configDirectory(Quickshell.env("HOME"), Quickshell.env("XDG_CONFIG_HOME"))
  property bool ready: false
  property bool blocked: false
  property bool readFailed: false
  property bool busy: false
  property bool dirty: false
  property string error: ""
  property var value: ({})
  property string pending: ""
  property string inFlight: ""
  property int revision: 0
  signal restored()

  // Read-only migration: never modify the original INI, including on reset.
  Settings {
    id: legacy
    location: Paths.settingsUrl(Quickshell.env("HOME"), Quickshell.env("XDG_CONFIG_HOME"))
    category: root.kind === "progress" ? "101" : "Welcome"
  }
  FileView {
    id: legacyFile
    path: ""
    printErrors: false
    onLoaded: root.migrate()
    onLoadFailed: function(reason) {
      if (reason === FileViewError.FileNotFound) root.finish(root.defaults(), false)
      else root.failRead()
    }
  }
  FileView {
    id: file
    path: root.directory ? root.directory + "/omarchy-101-" + root.kind + ".json" : ""
    atomicWrites: true
    printErrors: false
    onLoaded: {
      if (root.ready) return
      try {
        var raw = text()
        var parsed = raw.length <= 16384 ? JSON.parse(raw) : null
        root.finish(root.valid(parsed) ? parsed : root.defaults(), !root.valid(parsed))
      } catch (_) { root.finish(root.defaults(), true) }
    }
    onLoadFailed: function(reason) {
      if (root.ready) return
      if (reason === FileViewError.FileNotFound) legacyFile.path = root.directory + "/omarchy-101.ini"
      else root.failRead()
    }
    onSaved: {
      root.busy = false
      root.dirty = root.pending !== root.inFlight
      if (root.dirty) Qt.callLater(root.flush)
      else root.error = ""
    }
    onSaveFailed: {
      root.busy = false
      root.dirty = true
      root.error = "Could not save. Your changes are kept in this session. Free some disk space or check folder permissions, then retry before restarting the shell."
    }
  }
  Component.onCompleted: { if (!directory) failRead() }
  function defaults() {
    return kind === "progress" ? {version:1, completed:{}, currentLesson:""} : {version:1, state:""}
  }
  function valid(data) {
    if (!data || data.version !== 1) return false
    if (kind === "welcome") return ["", "offered", "started", "dismissed", "finished"].indexOf(data.state) >= 0
    return Lessons.progressReadable(JSON.stringify(data)) && typeof data.currentLesson === "string" &&
      (data.currentLesson === "" || Lessons.lessons.some(function(lesson) { return lesson.id === data.currentLesson }))
  }
  function finish(data, rejected) {
    value = data
    blocked = rejected
    ready = true
    restored()
  }
  function failRead() {
    readFailed = true
    error = "Saved data could not be read. It has not been replaced. Check folder permissions and reopen the shell to try again."
    finish(defaults(), true)
  }
  function migrate() {
    legacy.sync()
    if (kind === "welcome") {
      var state = legacy.value("state", "")
      var data = {version:1, state:state}
      finish(valid(data) ? data : defaults(), !valid(data))
    } else {
      var progress = legacy.value("progress", "")
      var current = legacy.value("currentLesson", "")
      var data = {version:1, completed:Lessons.restore(progress), currentLesson:current}
      finish(data, !Lessons.progressReadable(progress) || !valid(data))
    }
  }
  function save(data) {
    if (!ready || blocked || !valid(data)) return
    value = data
    // A unique attempt also avoids FileView deduplicating a retry after failure.
    pending = JSON.stringify(Object.assign({}, data, {writeAttempt:Date.now() + ":" + (++revision)})) + "\n"
    dirty = true
    // FileView emits completion before clearing its live operation. Defer writes.
    Qt.callLater(root.flush)
  }
  function flush() {
    if (!ready || blocked || busy || !dirty) return
    busy = true
    error = ""
    inFlight = pending
    file.setText(inFlight)
  }
  function retry() { if (dirty && !busy) save(value) }
  function reset(data) {
    if (!ready || readFailed || busy) return
    blocked = false
    save(data)
  }
}
