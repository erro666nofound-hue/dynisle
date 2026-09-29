import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.common
import qs.modules.island
import qs.services

// The second surface: pinned apps while the field is empty, matches once you
// type. Drawn by Island.qml below the island itself, with its own rounded body
// - two surfaces of the SAME width, as the design calls for, still inside the
// one PanelWindow.
//
// Blur-critical: this fill matches the island's and must stay above Hyprland's
// ignore_alpha floor (vault/notes.md fact 1).
Rectangle {
    id: root

    readonly property bool searching: Launcher.query.trim().length > 0

    // Full width while searching; while showing pins it shrinks to just fit
    // them, so one or two pinned apps do not sit in a mostly empty box. Past
    // one row it stays at full width and the tiles wrap.
    implicitWidth: root.searching
        ? Theme.launcherWidth
        : Math.min(Launcher.pinned.length, Theme.launcherPerRow)
            * (Theme.launcherPinSize + Theme.launcherPinSpacing)
            - Theme.launcherPinSpacing + Theme.launcherPanelPad * 2
    implicitHeight: content.implicitHeight + Theme.launcherPanelPad * 2

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animDuration
            easing.type: Theme.animEasing
        }
    }

    radius: Theme.launcherPanelRadius
    color: Theme.surface

    // Grows and shrinks with the results rather than snapping to each height.
    Behavior on implicitHeight {
        NumberAnimation {
            duration: Theme.animDuration
            easing.type: Theme.animEasing
        }
    }

    // Arrow keys must not walk the selection off the bottom of the visible
    // list. Rows are exactly launcherRowHeight tall and the Column has no
    // spacing, so the row's position is simply its index.
    function revealSelected(): void {
        const top = Launcher.selected * Theme.launcherRowHeight;
        const bottom = top + Theme.launcherRowHeight;

        if (top < scroller.contentY)
            scroller.contentY = top;
        else if (bottom > scroller.contentY + scroller.height)
            scroller.contentY = bottom - scroller.height;
    }

    Connections {
        target: Launcher

        function onSelectedChanged(): void {
            root.revealSelected();
        }

        // A new query is a new list; staying scrolled down would hide the best
        // match, which is always the first row.
        function onQueryChanged(): void {
            scroller.contentY = 0;
        }
    }

    Item {
        id: content

        anchors.fill: parent
        anchors.margins: Theme.launcherPanelPad
        implicitHeight: root.searching
            ? Math.min(rows.implicitHeight, Theme.launcherMaxListHeight)
            : Math.min(pinned.implicitHeight, Theme.launcherMaxPinHeight)

        // ---- pinned apps, while nothing has been typed --------------------
        // Wraps rather than running off the edge. At the old fixed limit of 8
        // the row was wider than the panel, so the last tile - and the
        // selection mark on it - poked out past the rounded corner.
        Flickable {
            id: pinScroller

            anchors.fill: parent
            visible: !root.searching
            contentWidth: width
            contentHeight: pinned.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

        Flow {
            id: pinned

            width: pinScroller.width
            spacing: Theme.launcherPinSpacing

            // A Repeater destroys a delegate the instant it leaves the model,
            // so an unpinned tile cannot animate itself out. What CAN be
            // animated is everything around it: the survivors slide across and
            // the surface shrinks to fit, which is what reads as the tile
            // leaving. Pinning gets a real entrance.
            add: Transition {
                NumberAnimation {
                    properties: "scale"
                    from: 0.6
                    to: 1
                    duration: Theme.animDuration
                    easing.type: Theme.animEasing
                }
                NumberAnimation {
                    properties: "opacity"
                    from: 0
                    to: 1
                    duration: Theme.animDuration
                }
            }

            move: Transition {
                NumberAnimation {
                    properties: "x"
                    duration: Theme.animDuration
                    easing.type: Theme.animEasing
                }
            }

            Repeater {
                model: Launcher.pinned

                Item {
                    id: pin

                    required property int index
                    required property var modelData
                    readonly property bool isSelected: !root.searching
                        && Launcher.selected === pin.index

                    implicitWidth: Theme.launcherPinSize
                    implicitHeight: Theme.launcherPinSize

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.launcherPinRadius
                        // The keyboard selection reads stronger than hover, so
                        // the two are distinguishable when both are on a tile.
                        color: pin.isSelected ? Theme.accentStrong : Theme.accentFill
                        opacity: pin.isSelected || pinArea.containsMouse ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animDuration }
                        }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: Theme.launcherPinIcon
                        source: Quickshell.iconPath(pin.modelData.icon, "application-x-executable")
                    }

                    MouseArea {
                        id: pinArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Launcher.launch(pin.modelData);
                            IslandState.closeLauncher();
                        }
                    }

                    // Unpin, on hover. Its own MouseArea, so the click lands
                    // here and never reaches the tile underneath.
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 2
                        width: Theme.launcherBadgeSize
                        height: Theme.launcherBadgeSize
                        radius: width / 2
                        color: Theme.surfaceTint
                        border.width: 1
                        border.color: Theme.divider
                        opacity: pinArea.containsMouse || unpinArea.containsMouse ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animDuration }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf00d"
                            color: unpinArea.containsMouse ? Theme.weekend : Theme.textDim
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                        }

                        MouseArea {
                            id: unpinArea

                            anchors.fill: parent
                            anchors.margins: -3
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Launcher.togglePin(pin.modelData.name)
                        }
                    }
                }
            }
        }
        }

        // ---- matches ------------------------------------------------------
        // Capped and scrollable: a search for "a" matches far more apps than
        // fit, and the panel used to just keep growing until the window edge
        // cut it flat. The fade at the bottom says there is more below.
        Flickable {
            id: scroller

            anchors.fill: parent
            visible: root.searching
            contentWidth: width
            contentHeight: rows.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Column {
                id: rows
                width: scroller.width
                Repeater {
                    model: Launcher.rows
                    Item {
                        id: row
                        required property int index
                        required property var modelData
                        readonly property bool isSelected: Launcher.selected === row.index
                        readonly property bool isApp: row.modelData.kind === "app"
                        readonly property bool pinnedHere: row.isApp
                            && Launcher.isPinned(row.modelData.value)
                        width: rows.width
                        height: Theme.launcherRowHeight
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.launcherRowRadius
                            color: Theme.accentStrong
                            opacity: row.isSelected ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation { duration: Theme.animDuration }
                            }
                        }
                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: Launcher.selected = row.index
                            onClicked: {
                                Launcher.selected = row.index;
                                Launcher.activate();
                                IslandState.closeLauncher();
                            }
                        }
                        // An app shows its real icon; command and web rows get a
                        // glyph tile so the column still lines up.
                        IconImage {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: Theme.launcherIconSize
                            visible: row.isApp
                            source: row.isApp
                                ? Quickshell.iconPath(row.modelData.entry.icon, "application-x-executable")
                                : ""
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.launcherIconSize
                            height: Theme.launcherIconSize
                            radius: 7
                            visible: !row.isApp
                            color: Qt.rgba(1, 1, 1, 0.07)
                            Text {
                                anchors.centerIn: parent
                                text: row.modelData.kind === "run" ? "\uf120" : "\uf002"
                                color: Theme.textDim
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                            }
                        }
                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12 + Theme.launcherIconSize + 12
                            anchors.right: action.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                visible: !row.isApp
                                text: row.modelData.kind === "run" ? "RUN COMMAND" : "WEB SEARCH"
                                color: Theme.textDisabled
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.launcherKindSize
                                font.letterSpacing: 0.8
                            }
                            Text {
                                width: scroller.width
                                elide: Text.ElideRight
                                // StyledText so the <u> spans Launcher.highlight()
                                // puts around the matched characters render.
                                textFormat: Text.StyledText
                                text: row.isApp
                                    ? Launcher.highlight(row.modelData.value, Launcher.query)
                                    : row.modelData.value
                                color: row.isSelected ? Theme.text : Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.launcherNameSize
                                Behavior on color {
                                    ColorAnimation { duration: Theme.animDuration }
                                }
                            }
                        }
                        Text {
                            id: action
                            anchors.right: pinButton.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.kind === "app" ? "Open"
                                : (row.modelData.kind === "run" ? "Run" : "Search")
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelFontBody
                            opacity: row.isSelected ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation { duration: Theme.animDuration }
                            }
                        }
                        // Pin / unpin without launching. Its own MouseArea, so the
                        // click never falls through to the row.
                        Item {
                            id: pinButton
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.launcherPinButtonSize
                            height: Theme.launcherPinButtonSize
                            visible: row.isApp
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: Theme.accentFill
                                opacity: pinBtnArea.containsMouse ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation { duration: Theme.animDuration }
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                // A filled pin once it is pinned, an outline while
                                // it is not, so the row says which way it will go.
                                text: row.pinnedHere ? "\uf08d" : "\uf08d"
                                rotation: row.pinnedHere ? 0 : -35
                                color: row.pinnedHere ? Theme.accent
                                    : (pinBtnArea.containsMouse ? Theme.text : Theme.textDisabled)
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                Behavior on rotation {
                                    NumberAnimation {
                                        duration: Theme.animDuration
                                        easing.type: Theme.animEasing
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation { duration: Theme.animDuration }
                                }
                            }
                            MouseArea {
                                id: pinBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Launcher.togglePin(row.modelData.value)
                            }
                        }
                    }
                }
            }
        }

    }
}
