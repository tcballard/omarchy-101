import QtQuick
import qs.Ui as Ui

Ui.Button {
  id: root
  focusable: true
  Accessible.name: text
  Accessible.role: Accessible.Button
  onActiveFocusChanged: {
    if (!activeFocus) return
    // Keep keyboard navigation visible inside the scrollable lesson card.
    var ancestor = parent
    for (var i = 0; ancestor && i < 32; i++, ancestor = ancestor.parent) {
      if (ancestor.contentItem !== undefined && ancestor.contentY !== undefined) {
        var point = mapToItem(ancestor.contentItem, 0, 0)
        var next = ancestor.contentY
        if (point.y < next) next = point.y
        else if (point.y + height > next + ancestor.height) next = point.y + height - ancestor.height
        ancestor.contentY = Math.max(0, Math.min(Math.max(0, ancestor.contentHeight - ancestor.height), next))
        break
      }
    }
  }
}
