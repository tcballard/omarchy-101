import QtQuick
import Quickshell.Io
import "Shortcuts.js" as Shortcuts
Item {
  id: root
  property bool enabledForSession: false
  property string status: "idle"
  property var bindings: []
  property string output: ""
  property bool cancelling: false
  function refresh() {
    if (!enabledForSession || process.running || cancelling) return
    bindings = []; output = ""; status = "loading"
    watchdog.restart()
    process.running = true
  }
  onEnabledForSessionChanged: {
    if (!enabledForSession) {
      watchdog.stop()
      cancelling = cancelling || process.running
      process.signal(14)
      output = ""; bindings = []; status = "idle"
    }
  }
  Timer {
    id: watchdog
    interval: 7000
    onTriggered: {
      root.cancelling = process.running
      process.signal(14)
      root.output = ""; root.bindings = []; root.status = "failed"
    }
  }
  Process {
    id: process
    objectName: "shortcutProcess"
    onRunningChanged: {
      if (!running) Qt.callLater(function() {
        // FailedToStart does not emit exited in Quickshell.
        if (!process.running && root.status === "loading") {
          watchdog.stop(); root.output = ""; root.bindings = []; root.status = "failed"
        }
        if (!process.running) root.cancelling = false
      })
    }
    // Fixed pipeline; no payload, binding or user string enters shell source.
    // head bounds output before collection. GNU timeout owns a new process group.
    // SIGALRM (14) asks timeout to apply its configured KILL to the entire group,
    // including descendants that ignore TERM. Never kill only the supervisor.
    command: ["timeout", "--signal=KILL", "5s", "bash", "-c", "set -o pipefail; LC_ALL=C hyprctl binds | head -c 131073"]
    stdout: StdioCollector { onStreamFinished: if (root.enabledForSession && !root.cancelling) root.output = text }
    onExited: function(exitCode, exitStatus) {
      watchdog.stop()
      if (root.cancelling) { root.cancelling = false; root.output = ""; return }
      if (!root.enabledForSession) return
      if (exitCode !== 0 || exitStatus !== 0) { root.status = "failed"; root.output = ""; return }
      var parsed = Shortcuts.parse(root.output)
      root.output = ""; root.bindings = parsed.bindings; root.status = parsed.status
    }
  }
}
