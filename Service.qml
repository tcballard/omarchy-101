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
  Settings {
    id: welcome
    location: Paths.settingsUrl(Quickshell.env("HOME"), Quickshell.env("XDG_CONFIG_HOME"))
    category: "Welcome"
    property string state: ""
  }
  function acknowledge(action) {
    welcome.state = Welcome.acknowledge(welcome.state, action)
    welcome.setValue("state", welcome.state)
    welcome.sync()
  }
  Timer {
    interval: 1000
    repeat: true
    running: !!root.shell && !root.requested && root.attempts < 5 && Welcome.shouldOffer(welcome.state)
    onTriggered: {
      root.attempts += 1
      // Mark offered only when the panel actually opens and acknowledges it.
      root.requested = root.shell.summon("io.github.tcballard.omarchy-101", '{"welcome":true}') === true
    }
  }
}
