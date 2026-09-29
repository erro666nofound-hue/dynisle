import QtQuick
import qs.modules.common

// One network in the Wi-Fi list. The "Forget" action only appears on hover, so
// a list of saved networks stays a list of names rather than a wall of buttons.
Item {
    id: root

    property string ssid: ""
    property int strength: 0
    property bool secure: false
    property bool current: false
    property bool forgettable: false
    property bool connecting: false
    property int connectingFor: 0

    signal pressed
    signal forgetPressed

    implicitWidth: Theme.ccWidth
    implicitHeight: Theme.ccListRowHeight

    // Windows-style wedge: the bars grow out of a single triangle rather than
    // the old free-standing arcs.
    readonly property string signalIcon: root.strength >= 75 ? "signal_wifi_4_bar"
        : root.strength >= 50 ? "network_wifi_3_bar"
        : root.strength >= 25 ? "network_wifi_2_bar"
        : root.strength > 0 ? "network_wifi_1_bar"
        : "signal_wifi_0_bar"

    Rectangle {
        anchors.fill: parent
        radius: Theme.ccListRadius
        color: root.current ? Theme.accentStrong
            : Qt.rgba(1, 1, 1, rowHover.hovered ? 0.06 : 0)

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration }
        }
    }

    Icon {
        id: bars

        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        size: 19
        text: root.signalIcon
        color: root.current ? Theme.accent : Theme.textDim
    }

    Text {
        id: name

        anchors.left: bars.right
        anchors.leftMargin: 10
        anchors.right: trailing.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.ssid
        color: root.current ? Theme.text : Theme.textDim
        font.family: Theme.fontFamily
        font.pixelSize: 13
        elide: Text.ElideRight
    }

    Row {
        id: trailing

        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // Joining takes real time - nmcli returns long before the association
        // has settled - so the row says so, and counts, instead of sitting
        // there doing nothing and then suddenly being connected.
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.connecting
            spacing: 6

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                size: 14
                text: "autorenew"
                color: Theme.accent

                RotationAnimation on rotation {
                    running: root.connecting
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1100
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.connectingFor > 0 ? `Connecting… ${root.connectingFor}s` : "Connecting…"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.current && !root.connecting
            text: "Connected"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }

        // Sits in the row rather than replacing anything, so the name never
        // shifts when the pointer arrives.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.forgettable && !root.connecting && opacity > 0
            opacity: rowHover.hovered && !root.connecting ? 1 : 0
            width: forgetLabel.implicitWidth + 16
            height: 22

            Behavior on opacity {
                NumberAnimation { duration: Theme.animDuration }
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Qt.rgba(1, 1, 1, forgetHover.hovered ? 0.14 : 0.07)

                Behavior on color {
                    ColorAnimation { duration: Theme.animDuration }
                }
            }

            Text {
                id: forgetLabel

                anchors.centerIn: parent
                text: "Forget"
                color: forgetHover.hovered ? Theme.urgent : Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }

            HoverHandler {
                id: forgetHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.forgetPressed()
            }
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.secure
            size: 15
            text: "lock"
            // textDisabled (0.28 alpha) left this all but invisible at 15px -
            // the outline is thin enough that subpixel fringing was most of
            // what showed. Dim, but actually legible.
            color: Qt.rgba(1, 1, 1, 0.42)
        }
    }

    HoverHandler {
        id: rowHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.pressed()
    }
}
