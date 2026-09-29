pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.island
import qs.services

// Third layer: which speaker or microphone the slider above is actually
// driving. Reached from the small "tune" link under each slider.
Column {
    id: root

    // "output" or "input".
    property string kind: "output"

    readonly property bool isOutput: root.kind === "output"
    readonly property var devices: root.isOutput ? Audio.sinks : Audio.sources
    readonly property var activeDevice: root.isOutput ? Audio.sink : Audio.source

    spacing: 2

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
            text: root.isOutput ? "Output" : "Input"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
        }

        Icon {
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            size: 20
            text: root.isOutput ? "speaker" : "graphic_eq"
            color: Theme.textDim
        }
    }

    // The fade cannot be a sibling of the Flickable: a Column positions
    // every visible child, so the overlay would be laid out as another
    // row instead of sitting on top of the list.
    Item {
        width: Theme.ccWidth
        height: Math.min(deviceColumn.implicitHeight, 288)

        Flickable {
            id: scroller

            anchors.fill: parent
            contentWidth: width
            contentHeight: deviceColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Column {
                id: deviceColumn

                width: parent.width
                spacing: 2

                Text {
                    visible: root.devices.length === 0
                    topPadding: 14
                    bottomPadding: 14
                    leftPadding: 12
                    text: root.isOutput ? "No outputs found" : "No inputs found"
                    color: Theme.textDisabled
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                Repeater {
                    model: root.devices

                    Item {
                        id: deviceRow

                        required property var modelData
                        readonly property bool selected: deviceRow.modelData === root.activeDevice

                        width: Theme.ccWidth
                        height: Theme.ccListRowHeight

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.ccListRadius
                            color: deviceRow.selected ? Theme.accentStrong
                                : Qt.rgba(1, 1, 1, deviceHover.hovered ? 0.06 : 0)

                            Behavior on color {
                                ColorAnimation { duration: Theme.animDuration }
                            }
                        }

                        Icon {
                            id: deviceGlyph

                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            size: 18
                            // Headphones and speakers are told apart by name,
                            // because PipeWire does not label the difference.
                            text: {
                                const n = (deviceRow.modelData?.description ?? "").toLowerCase();
                                if (!root.isOutput)
                                    return "mic";
                                if (n.includes("headphone") || n.includes("headset"))
                                    return "headphones";
                                return "speaker";
                            }
                            color: deviceRow.selected ? Theme.accent : Theme.textDim
                        }

                        Text {
                            anchors.left: deviceGlyph.right
                            anchors.leftMargin: 10
                            anchors.right: tick.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: deviceRow.modelData?.description
                                ?? deviceRow.modelData?.nickname ?? deviceRow.modelData?.name ?? ""
                            color: deviceRow.selected ? Theme.text : Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        Icon {
                            id: tick

                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            size: 18
                            text: "check"
                            color: Theme.accent
                            opacity: deviceRow.selected ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.animDuration }
                            }
                        }

                        HoverHandler {
                            id: deviceHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: {
                                if (root.isOutput)
                                    Audio.setSink(deviceRow.modelData);
                                else
                                    Audio.setSource(deviceRow.modelData);
                            }
                        }
                    }
                }
            }
        }

    }
}
