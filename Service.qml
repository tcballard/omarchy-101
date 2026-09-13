import QtQuick
import QtCore
import "Paths.js" as Paths
import Quickshell
import "Welcome.js" as Welcome
Item {
  id: root
  property string omarchyPath: ""
  property var shell: null
  property var manifest: null
  property int attempts: 0
  property bool requested: false
  readonly property alias storage: welcome
  ProgressStore { id: welcome; kind: "welcome" }
  function acknowledge(action) {
    if (!welcome.ready || welcome.blocked) return
    welcome.save({version:1, state:Welcome.acknowledge(welcome.value.state, action)})
  }
  Timer {
    interval: 1000
    repeat: true
    running: !!root.shell && !root.requested && root.attempts < 5 && welcome.ready && !welcome.blocked && Welcome.shouldOffer(welcome.value.state)
    onTriggered: {
      root.attempts += 1
      // Mark offered only when the panel actually opens and acknowledges it.
      root.requested = root.shell.summon("io.github.tcballard.omarchy-101", '{"welcome":true}') === true
    }
  }
}
