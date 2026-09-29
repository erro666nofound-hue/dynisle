pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.island
import qs.services

// Four ways out of the machine, in the bar. Built to the design agreed on the
// web: https://claude.ai/code/artifact/1fa44bf8-3932-41ef-9533-3a83081accd3
//
// Nothing else is in here on purpose - no uptime, no battery, no keep awake
// (that stays in the control centre). You opened this deliberately with a
// keybind; it should answer in one press.
Item {
    id: root

    readonly property real islandPaddingH: 14
    readonly property real islandMinWidth: Theme.sessionWidth + 28

    // Order is the order of consequence: the two that lose work are last, and
    // furthest from where the pointer arrives.
    readonly property var actions: [
        { name: "Lock screen", icon: "lock",                letter: "L", danger: false },
        { name: "Sleep",       icon: "bedtime",             letter: "S", danger: false },
        { name: "Restart",     icon: "restart_alt",         letter: "R", danger: true  },
        { name: "Shut down",   icon: "power_settings_new",  letter: "P", danger: true  }
    ]

    property int selected: 0

    // Which tile is waiting for a second press. -1 is none.
    property int armed: -1

    implicitWidth: Theme.sessionWidth
    implicitHeight: header.height + 10 + tiles.height

    // Island claims this on the turn after the panel opens - the surface's
    // keyboard focus flips in the same turn, so asking any earlier asks a
    // window that is not focusable yet (notes.md fact 30).
    focus: true

    function claimFocus(): void {
        root.forceActiveFocus();
    }

    // A danger tile arms on the first press and runs on the second. Not a
    // dialog on top of it: a stray press on Shut down should not cost an
    // afternoon, and a modal you have to dismiss is a worse answer than the
    // button saying what it is about to do.
    function run(index: int): void {
        if (index < 0 || index >= root.actions.length)
            return;

        if (root.actions[index].danger && root.armed !== index) {
            root.armed = index;
            disarm.restart();
            return;
        }

        root.armed = -1;

        // Straight to the command - the "Sleeping" veil that used to stand in
        // front of it was removed on 2026-09-29. The command goes out BEFORE
        // the panel is closed: closing it destroys this panel, and a command
        // fired from a panel that is being torn down is exactly how Sleep once
        // silently did nothing (notes.md fact 96).
        switch (index) {
        case 0: Session.lock(); break;
        case 1: Session.sleep(); break;
        case 2: Session.restart(); break;
        case 3: Session.shutdown(); break;
        }

        IslandState.closeSession();
    }

    // Moving to another tile takes the arming back with you.
    onSelectedChanged: {
        if (root.armed >= 0 && root.armed !== root.selected)
            root.armed = -1;
    }

    Timer {
        id: disarm

        interval: 3000
        onTriggered: root.armed = -1
    }

    // Escape gives up the confirmation first and only then the panel, so the
    // key never does two things at once.
    Keys.onEscapePressed: {
        if (root.armed >= 0)
            root.armed = -1;
        else
            IslandState.closeSession();
    }

    Keys.onLeftPressed: root.selected = Math.max(0, root.selected - 1)
    Keys.onRightPressed: root.selected = Math.min(root.actions.length - 1, root.selected + 1)
    Keys.onReturnPressed: root.run(root.selected)
    Keys.onEnterPressed: root.run(root.selected)

    // The letter under each tile goes straight there. Safe even for the
    // destructive two, because those still need the second press.
    Keys.onPressed: event => {
        const hit = root.actions.findIndex(a => a.letter.charCodeAt(0) === event.key);
        if (hit < 0)
            return;

        root.selected = hit;
        root.run(hit);
        event.accepted = true;
    }

    // ---- header ------------------------------------------------------------
    Item {
        id: header

        width: parent.width
        height: 28

        Icon {
            id: mark

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            size: 19
            text: "power_settings_new"
            color: Theme.accent
        }

        Text {
            anchors.left: mark.right
            anchors.leftMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            text: "Session"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
        }
    }

    // ---- the four ----------------------------------------------------------
    Row {
        id: tiles

        anchors.top: header.bottom
        anchors.topMargin: 10
        spacing: Theme.sessionGap

        Repeater {
            model: root.actions

            Item {
                id: tile

                required property int index
                required property var modelData

                readonly property bool here: root.selected === tile.index
                readonly property bool danger: tile.modelData.danger
                readonly property bool waiting: root.armed === tile.index
                readonly property color tone: tile.danger ? Theme.danger : Theme.accent

                width: Theme.sessionTile
                height: body.height

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: tile.waiting ? Theme.dangerFill
                        : (tile.here ? (tile.danger ? Theme.dangerFill : Theme.accentFill)
                        : Qt.rgba(1, 1, 1, 0.055))
                    border.width: 2
                    border.color: tile.here || tile.waiting ? tile.tone : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration }
                    }

                    Behavior on border.color {
                        ColorAnimation { duration: Theme.animDuration }
                    }
                }

                Column {
                    id: body

                    width: parent.width
                    topPadding: 14
                    bottomPadding: 11
                    spacing: 7

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        size: 26
                        text: tile.modelData.icon
                        color: tile.here || tile.waiting ? tile.tone
                            : (tile.danger ? Theme.danger : Theme.text)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.name
                        color: tile.here || tile.waiting ? tile.tone : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }

                    // The key hint becomes the confirmation, in the same place,
                    // so nothing moves and the tile does not change size.
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.waiting ? "Press again" : tile.modelData.letter
                        color: tile.waiting ? Theme.danger : Theme.textDisabled
                        font.family: tile.waiting ? Theme.fontFamily : Theme.fontMono
                        font.pixelSize: tile.waiting ? 11 : 10
                        font.weight: tile.waiting ? Font.DemiBold : Font.Normal
                    }
                }

                // Hover moves the selection, so the keyboard and the pointer
                // never disagree about which tile is the live one.
                HoverHandler {
                    id: hover

                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: {
                        if (hover.hovered)
                            root.selected = tile.index;
                    }
                }

                TapHandler {
                    onTapped: root.run(tile.index)
                }
            }
        }
    }
}
