import QtQuick
import qs.modules.common

// A press target. Everything that is simply on or off lives in the grid as one
// of these, and everything you drag stays a full-width row above - that is the
// whole organising idea, and it is why every tile is the same height.
//
// Two shapes, and the difference is width, not behaviour: a one-column tile
// stacks its glyph over its label, a wider one puts them side by side because
// it has the room and usually leads somewhere.
Item {
    id: root

    property string icon: ""
    property string label: ""

    // The live reading - the network's name, a colour temperature, "Off".
    // Tiles used to carry only an icon and a name, so the only way to read a
    // state was the tint.
    property string state: ""
    property bool active: false
    property bool leadsOn: false
    property int span: 1

    signal pressed
    signal held

    implicitWidth: Theme.ccSpan(root.span)
    implicitHeight: Theme.ccTileHeight

    readonly property bool wide: root.span > 1

    Rectangle {
        anchors.fill: parent
        radius: Theme.ccTileRadius
        color: root.active ? Theme.accentFill
            : Qt.rgba(1, 1, 1, hover.hovered ? 0.09 : 0.05)

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration }
        }
    }

    // ---- narrow: glyph above, text below -----------------------------------
    Icon {
        id: stackedIcon

        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 12
        visible: !root.wide
        size: 20
        text: root.icon
        color: root.active ? Theme.accent : Theme.textDim

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration }
        }
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 11
        visible: !root.wide
        spacing: 1

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.label
            color: root.active ? Theme.text : Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            visible: root.state.length > 0
            text: root.state
            color: root.active ? Theme.accent : Theme.textDisabled
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }

    // ---- wide: glyph beside the text ---------------------------------------
    Icon {
        id: sideIcon

        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        visible: root.wide
        size: 23
        text: root.icon
        color: root.active ? Theme.accent : Theme.textDim

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration }
        }
    }

    Column {
        anchors.left: sideIcon.right
        anchors.leftMargin: 11
        anchors.right: chevron.visible ? chevron.left : parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        visible: root.wide
        spacing: 1

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.label
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            visible: root.state.length > 0
            text: root.state
            color: root.active ? Theme.accent : Theme.textDisabled
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }

    Icon {
        id: chevron

        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: root.wide && root.leadsOn
        size: 18
        text: "chevron_right"
        color: Theme.textDisabled
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        // A long press is a second, optional gesture - night light uses it to
        // reach its warmth slider without spending a tile on a chevron.
        longPressThreshold: 0.4
        onTapped: root.pressed()
        onLongPressed: root.held()
    }
}
