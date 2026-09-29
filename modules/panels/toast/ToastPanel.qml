import QtQuick
import qs.modules.common
import qs.modules.island

// A one-line confirmation the island wears for a moment. Nothing to press and
// nothing to read twice - it exists so an action that produced no visible
// result still says it happened.
Item {
    id: root

    implicitWidth: glyph.width + label.implicitWidth + 10 + 4
    implicitHeight: 24

    Icon {
        id: glyph

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        size: 18
        text: IslandState.toastIcon
        color: Theme.accent
    }

    Text {
        id: label

        anchors.left: glyph.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: IslandState.toastText
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.weight: Font.Medium
    }
}
