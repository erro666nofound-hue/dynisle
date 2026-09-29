import QtQuick
import qs.modules.common

// A small round icon button. Used for mute and for the back arrow, so it lives
// in one place rather than being re-declared per view.
Item {
    id: root

    property string icon: ""
    property bool active: false

    signal pressed

    implicitWidth: Theme.ccRoundSize
    implicitHeight: Theme.ccRoundSize

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.active ? Theme.accentStrong : Theme.accentFill
        opacity: root.active || hover.hovered ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animDuration }
        }
    }

    Icon {
        anchors.centerIn: parent
        size: 18
        text: root.icon
        color: root.active || hover.hovered ? Theme.accent : Theme.textDim

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.pressed()
    }
}
