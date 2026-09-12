import QtQuick
import Quickshell.Hyprland

// Instantiated only while the user has explicitly enabled context in an open guide.
QtObject {
  readonly property var monitor: Hyprland.focusedMonitor
  readonly property var window: Hyprland.activeToplevel
  readonly property var snapshot: ({
    available: monitor !== null,
    monitor: monitor ? monitor.name : "",
    workspace: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : null,
    app: window && window.lastIpcObject ? String(window.lastIpcObject["class"] || "").slice(0, 160) : "",
    address: window ? window.address : ""
  })
}
