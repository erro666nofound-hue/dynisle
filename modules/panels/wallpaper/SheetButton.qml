import QtQuick
import qs.modules.common

// The button at the foot of a sheet: Cancel beside a primary action.
Rectangle {
    id: root

    property string label: ""
    property bool primary: false
    property bool usable: true

    signal pressed

    width: label_.implicitWidth + 32
    height: 32
    radius: height / 2
    opacity: root.usable ? 1 : 0.4
    color: root.primary
        ? (hover.hovered && root.usable ? Theme.accent : Theme.accentStrong)
        : Qt.rgba(1, 1, 1, hover.hovered && root.usable ? 0.12 : 0.06)

    Behavior on color {
        ColorAnimation { duration: Theme.animDuration }
    }

    Text {
        id: label_

        anchors.centerIn: parent
        text: root.label
        color: root.primary && hover.hovered && root.usable
            ? Theme.surfaceTint : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }

    HoverHandler {
        id: hover
        enabled: root.usable
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.usable
        onTapped: root.pressed()
    }
}
