pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import qs.modules.common
import qs.modules.island
import qs.services

// The control centre's first layer. Designed on the web and agreed there:
// https://claude.ai/code/artifact/5252ee00-3c6d-4c84-aff3-8eadcac0d145
//
// The organising idea is that shape tells you the behaviour: things you DRAG
// are full-width rows, things you PRESS are tiles in a four-column grid, and
// status is neither. The first version made every control a full-width row, so
// shape said nothing at all.
Column {
    id: root

    spacing: Theme.ccGap

    // ---- now playing ------------------------------------------------------
    MediaStrip {
        visible: Media.hasPlayer
    }

    Rectangle {
        width: Theme.ccWidth
        height: 1
        color: Theme.divider
        visible: Media.hasPlayer
    }

    // ---- the things you drag ----------------------------------------------
    ControlSlider {
        icon: "light_mode"
        value: Brightness.value
        minimum: Brightness.minFraction
        onMoved: v => Brightness.set(v)
    }

    ControlSlider {
        icon: "volume_up"
        mutedIcon: "volume_off"
        value: Audio.volume
        off: Audio.muted || Audio.volume === 0
        device: Audio.sinkName
        onMoved: v => Audio.setVolume(v)
        onIconPressed: Audio.toggleMute()
        onDevicePressed: IslandState.pushView("output")
    }

    ControlSlider {
        icon: "mic"
        mutedIcon: "mic_off"
        value: Audio.micVolume
        off: Audio.micMuted || Audio.micVolume === 0
        device: Audio.sourceName
        onMoved: v => Audio.setMicVolume(v)
        onIconPressed: Audio.toggleMicMute()
        onDevicePressed: IslandState.pushView("input")
    }

    Rectangle {
        width: Theme.ccWidth
        height: 1
        color: Theme.divider
    }

    // ---- the things you press ---------------------------------------------
    Row {
        spacing: Theme.ccGap

        ControlTile {
            span: 2
            leadsOn: true
            // The same wedge ladder the network list uses, so signal strength
            // reads the same in both places.
            icon: {
                if (!Network.enabled)
                    return "wifi_off";
                const s = Network.networks.find(n => n.current)?.signal ?? -1;
                if (s < 0)
                    return "signal_wifi_bad";
                return s >= 75 ? "signal_wifi_4_bar"
                    : s >= 50 ? "network_wifi_3_bar"
                    : s >= 25 ? "network_wifi_2_bar"
                    : "network_wifi_1_bar";
            }
            label: "Wi-Fi"
            state: Network.enabled
                ? (Network.currentSsid.length > 0 ? Network.currentSsid : "Not connected")
                : "Off"
            active: Network.enabled && Network.currentSsid.length > 0
            onPressed: IslandState.pushView("wifi")
        }

        ControlTile {
            icon: "bedtime"
            label: "Night light"
            // The service takes any temperature, so the tile reports the real
            // one rather than just "On".
            state: NightLight.active ? `${NightLight.temperature} K` : "Off"
            active: NightLight.active
            onPressed: NightLight.toggle()
            // Hold for the warmth slider - no chevron spent on it, and it costs
            // nothing when nobody holds it.
            onHeld: IslandState.pushView("warmth")
        }

        ControlTile {
            icon: "notifications_off"
            label: "Silence"
            state: Notifications.doNotDisturb ? "On" : "Off"
            active: Notifications.doNotDisturb
            onPressed: Notifications.doNotDisturb = !Notifications.doNotDisturb
        }
    }

    // ---- how the machine is doing -----------------------------------------
    VitalsStrip {}

    Row {
        spacing: Theme.ccGap

        ControlTile {
            icon: "coffee"
            label: "Keep awake"
            state: Idle.inhibited ? "On" : "Off"
            active: Idle.inhibited
            onPressed: Idle.toggle()
        }

        // ---- status, sharing its strip with the one control it belongs to --
        Item {
            width: Theme.ccSpan(3)
            height: Theme.ccTileHeight

            Rectangle {
                anchors.fill: parent
                radius: Theme.ccTileRadius
                color: Qt.rgba(1, 1, 1, 0.05)
            }

            // Drawn rather than a glyph, because it has to show a real level.
            Rectangle {
                id: cell

                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                visible: Power.hasBattery
                width: 26
                height: 13
                radius: 3.5
                color: "transparent"
                border.width: 1.5
                border.color: Theme.textDim

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: (parent.width - 3) * Power.percentage / 100
                    height: parent.height - 3
                    radius: 1.5
                    color: Power.percentage <= 15 && !Power.charging ? Theme.urgent : Theme.accent

                    Behavior on width {
                        NumberAnimation { duration: Theme.animDuration }
                    }
                }

                Rectangle {
                    anchors.left: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 5
                    radius: 1
                    color: Theme.textDim
                }
            }

            Text {
                id: pct

                anchors.left: cell.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                visible: Power.hasBattery
                text: `${Math.round(Power.percentage)}%`
                color: Theme.text
                font.family: Theme.fontMono
                font.pixelSize: 13
            }

            Text {
                anchors.left: pct.right
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                visible: Power.hasBattery && text.length > 0
                text: Power.timeRemaining
                color: Theme.textDisabled
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }

            // One pill that TRAVELS between the three rather than a background
            // vanishing here and appearing there.
            Rectangle {
                id: profiles

                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                visible: Power.hasPerformance
                width: profileRow.width + 6
                height: 34
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.05)

                Rectangle {
                    id: mark

                    y: 3
                    height: parent.height - 6
                    radius: height / 2
                    color: Theme.accentStrong

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Theme.animEasing
                        }
                    }
                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Theme.animEasing
                        }
                    }
                }

                Row {
                    id: profileRow

                    x: 3
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Repeater {
                        model: [
                            { p: PowerProfile.PowerSaver,  icon: "battery_saver" },
                            { p: PowerProfile.Balanced,    icon: "balance" },
                            { p: PowerProfile.Performance, icon: "bolt" }
                        ]

                        Item {
                            id: profileButton

                            required property var modelData
                            readonly property bool selected: Power.profile === profileButton.modelData.p

                            width: 38
                            height: 28

                            // Seated from here so the mark follows whichever
                            // button is selected. `x` is watched too: a Row has
                            // not positioned its children on frame one, so
                            // seating only at completion parks it at zero.
                            onSelectedChanged: if (profileButton.selected) profileButton.seat()
                            onXChanged: if (profileButton.selected) profileButton.seat()
                            Component.onCompleted: if (profileButton.selected) profileButton.seat()

                            function seat(): void {
                                mark.x = profileRow.x + profileButton.x;
                                mark.width = profileButton.width;
                            }

                            Icon {
                                anchors.centerIn: parent
                                size: 18
                                text: profileButton.modelData.icon
                                color: profileButton.selected ? Theme.accent : Theme.textDim

                                Behavior on color {
                                    ColorAnimation { duration: Theme.animDuration }
                                }
                            }

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: Power.setProfile(profileButton.modelData.p)
                            }
                        }
                    }
                }
            }
        }
    }
}
