import QtQuick
import qs.modules.common

// A drag target, so it keeps a full-width row of its own - that separation from
// the tile grid below is the point: shape says whether a thing is dragged or
// pressed.
//
// The device name rides this row rather than costing a line underneath. It used
// to be its own line with a tiny `tune` link, two lines spent on something
// touched once a month.
Item {
    id: root

    property string icon: ""
    property string mutedIcon: ""
    property real value: 0
    property real minimum: 0
    property bool off: false

    // Optional: the device this slider is actually driving.
    property string device: ""

    signal moved(real value)
    signal iconPressed
    signal devicePressed

    implicitWidth: Theme.ccWidth
    implicitHeight: Theme.ccRowHeight

    // Pressing the glyph mutes, which is where everyone reaches for it.
    Item {
        id: glyphButton

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26

        Icon {
            anchors.centerIn: parent
            size: 20
            text: root.off && root.mutedIcon.length > 0 ? root.mutedIcon : root.icon
            color: root.off ? Theme.textDisabled : Theme.textDim

            Behavior on color {
                ColorAnimation { duration: Theme.animDuration }
            }
        }

        HoverHandler {
            enabled: root.mutedIcon.length > 0
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            enabled: root.mutedIcon.length > 0
            onTapped: root.iconPressed()
        }
    }

    Item {
        id: railArea

        anchors.left: glyphButton.right
        anchors.leftMargin: 11
        anchors.right: value.left
        anchors.rightMargin: 11
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height

        Rectangle {
            id: rail

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.ccTrackHeight
            radius: height / 2
            color: Theme.track

            Rectangle {
                width: rail.width * Math.max(0, Math.min(1, root.value))
                height: parent.height
                radius: parent.radius
                color: root.off ? Theme.textDisabled : Theme.accent

                Behavior on color {
                    ColorAnimation { duration: Theme.animDuration }
                }
            }
        }

        Rectangle {
            x: rail.width * Math.max(0, Math.min(1, root.value)) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.ccKnobSize
            height: Theme.ccKnobSize
            radius: height / 2
            color: "#eaf7f9"
            visible: !root.off
        }

        // Negative margins on purpose: once you are dragging, the pointer
        // wandering a few pixels off the rail must not drop the drag.
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function apply(mx: real): void {
                const f = (mx + 6 - (railArea.width - rail.width) / 2) / rail.width;
                root.moved(Math.max(root.minimum, Math.min(1, f)));
            }

            onPressed: mouse => apply(mouse.x)
            onPositionChanged: mouse => {
                if (pressed)
                    apply(mouse.x);
            }
        }
    }

    Text {
        id: value

        anchors.right: root.device.length > 0 ? deviceLabel.left : parent.right
        anchors.rightMargin: root.device.length > 0 ? 10 : 0
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        horizontalAlignment: Text.AlignRight
        text: `${Math.round(root.value * 100)}%`
        color: Theme.textDim
        font.family: Theme.fontMono
        font.pixelSize: Theme.ccValueSize
    }

    Item {
        id: deviceLabel

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.device.length > 0
        // Width comes from the label's OWN width, and the label is capped
        // directly rather than anchored to this item's right edge - anchoring
        // it there made the two derive their width from each other, which Qt
        // reported as a binding loop and left the layout unsettled.
        width: visible ? tune.width + 4 + name.width : 0
        height: 22

        Icon {
            id: tune

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            size: 13
            text: "tune"
            color: deviceHover.hovered ? Theme.textDim : Theme.textDisabled
        }

        Text {
            id: name

            anchors.left: tune.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(name.implicitWidth, 96)
            elide: Text.ElideRight
            text: root.device
            color: deviceHover.hovered ? Theme.textDim : Theme.textDisabled
            font.family: Theme.fontFamily
            font.pixelSize: Theme.ccDeviceSize

            Behavior on color {
                ColorAnimation { duration: Theme.animDuration }
            }
        }

        HoverHandler {
            id: deviceHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: root.devicePressed()
        }
    }
}
