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
    bindings = []; output = ""; status = "loading"; process.running = true
  }
  onEnabledForSessionChanged: {
    if (!enabledForSession) {
      cancelling = process.running
      process.running = false
      output = ""; bindings = []; status = "idle"
    }
  }
  Process {
    id: process
    // Fixed pipeline; no payload, binding or user string enters shell source.
    // head bounds the producer before the QML collector; timeout bounds the process group.
    command: ["timeout", "--kill-after=1s", "5s", "bash", "-c", "set -o pipefail; LC_ALL=C hyprctl binds | head -c 131073"]
    stdout: StdioCollector { onStreamFinished: if (root.enabledForSession && !root.cancelling) root.output = text }
    onExited: function(exitCode, exitStatus) {
      if (root.cancelling) { root.cancelling = false; root.output = ""; return }
      if (!root.enabledForSession) return
      if (exitCode !== 0 || exitStatus !== 0) { root.status = "failed"; root.output = ""; return }
      var parsed = Shortcuts.parse(root.output)
      root.output = ""; root.bindings = parsed.bindings; root.status = parsed.status
    }
  }
}
