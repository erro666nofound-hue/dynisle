import QtQuick
import qs.modules.common

// A pill in a panel header. `muted` is for a chip that only reports a state -
// it takes no taps and does not answer the pointer.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string trailing: ""
    property bool lit: false
    property bool muted: false

    signal pressed

    width: row.width + 22
    height: 26
    radius: height / 2
    color: root.lit ? Theme.accentFill
        : Qt.rgba(1, 1, 1, hover.hovered ? 0.12 : 0.06)

    Behavior on color {
        ColorAnimation { duration: Theme.animDuration }
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 6

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            size: 15
            text: root.icon
            color: root.lit ? Theme.accent
                : (root.muted ? Theme.textDisabled : Theme.textDim)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.lit ? Theme.accent
                : (root.muted ? Theme.textDisabled : Theme.textDim)
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.trailing.length > 0
            size: 15
            text: root.trailing
            color: Theme.textDim
        }
    }

    HoverHandler {
        id: hover
        enabled: !root.muted
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: !root.muted
        onTapped: root.pressed()
    }
}
