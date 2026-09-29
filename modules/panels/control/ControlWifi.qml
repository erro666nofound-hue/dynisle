pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.island
import qs.services

// Second layer: the network list. It expands the bar itself - there is no
// separate window - so it is capped in height and scrolls instead.
Column {
    id: root

    spacing: 2

    // ---- header -----------------------------------------------------------
    Item {
        width: Theme.ccWidth
        height: 34

        RoundButton {
            id: back

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            icon: "arrow_back"
            onPressed: IslandState.popView()
        }

        Text {
            anchors.left: back.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "Wi-Fi"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
        }

        Icon {
            anchors.right: toggle.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            visible: Network.scanning
            size: 15
            text: "autorenew"
            color: Theme.textDisabled

            RotationAnimation on rotation {
                running: Network.scanning
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 1400
            }
        }

        // A switch, because Wi-Fi being off is the reason an empty list is
        // empty and that has to be visible from here.
        Item {
            id: toggle

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            height: 20

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Network.enabled ? Theme.accent : Theme.track

                Behavior on color {
                    ColorAnimation { duration: Theme.animDuration }
                }
            }

            Rectangle {
                x: Network.enabled ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                radius: height / 2
                color: Network.enabled ? "#101012" : Theme.textDim

                Behavior on x {
                    NumberAnimation {
                        duration: Theme.animDuration
                        easing.type: Theme.animEasing
                    }
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Network.setEnabled(!Network.enabled)
            }
        }
    }

    // ---- list -------------------------------------------------------------
    // The fade cannot be a sibling of the Flickable: a Column positions
    // every visible child, so the overlay would be laid out as another
    // row instead of sitting on top of the list.
    Item {
        width: Theme.ccWidth
        height: Math.min(listColumn.implicitHeight, 288)

        Flickable {
            id: scroller

            anchors.fill: parent
            contentWidth: width
            contentHeight: listColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Column {
                id: listColumn

                width: parent.width
                spacing: 2

                Text {
                    visible: Network.enabled && Network.known.length === 0 && Network.unknown.length === 0
                    topPadding: 14
                    bottomPadding: 14
                    leftPadding: 12
                    text: Network.scanning ? "Looking for networks…" : "No networks in range"
                    color: Theme.textDisabled
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                Text {
                    visible: !Network.enabled
                    topPadding: 14
                    bottomPadding: 14
                    leftPadding: 12
                    text: "Wi-Fi is off"
                    color: Theme.textDisabled
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                GroupLabel {
                    visible: Network.known.length > 0
                    text: "Saved"
                }

                Repeater {
                    model: Network.known

                    WifiRow {
                        required property var modelData

                        ssid: modelData.ssid
                        strength: modelData.signal
                        secure: modelData.secure
                        current: modelData.current
                        forgettable: !modelData.current
                        connecting: Network.connectingTo === modelData.ssid
                        connectingFor: Network.connectingFor

                        onPressed: Network.connectSaved(modelData.ssid)
                        onForgetPressed: Network.forget(modelData.ssid)
                    }
                }

                GroupLabel {
                    visible: Network.unknown.length > 0
                    text: "Other networks"
                }

                Repeater {
                    model: Network.unknown

                    WifiRow {
                        required property var modelData

                        ssid: modelData.ssid
                        strength: modelData.signal
                        secure: modelData.secure
                        connecting: Network.connectingTo === modelData.ssid
                        connectingFor: Network.connectingFor

                        onPressed: {
                            if (modelData.secure)
                                IslandState.askPassword(modelData);
                            else
                                Network.connectNew(modelData.ssid, "");
                        }
                    }
                }
            }
        }

    }

    component GroupLabel: Text {
        topPadding: 10
        bottomPadding: 2
        leftPadding: 12
        color: Theme.textDisabled
        font.family: Theme.fontFamily
        font.pixelSize: Theme.ccGroupSize
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.8
    }
}
