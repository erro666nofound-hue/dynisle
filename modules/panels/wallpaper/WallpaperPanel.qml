pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Quickshell.Widgets
import qs.modules.common
import qs.modules.island
import qs.services

// The wallpaper picker: FOLDERS of pictures, and one of them on the desktop.
//
// Two views in one panel:
//   grid     the pictures in the folder being browsed
//   folders  the folders it knows about, and the way to add one
//
// The folder chip in the header is both the label and the way in - it says
// where you are and opens the list. Themes were built as a second panel here
// and removed; see `06-decisions.md`.
Item {
    id: root

    readonly property real islandPaddingH: 14
    readonly property real islandMinWidth: Theme.wallWidth + 28

    readonly property bool inFolders: IslandState.wallpaperView === "folders"
    readonly property bool inColour: IslandState.wallpaperView === "colour"

    // Keyboard cursor. Hover writes to it too, so the pointer and the keys can
    // never disagree about which cell is the live one - the same rule the
    // session panel follows.
    property int cursor: 0

    // The grid's first cell is "No wallpaper", so a picture at model index i is
    // cursor i + 1. The folder view has no such cell but does have the Add
    // card at the end, which IS reachable.
    readonly property int cells: root.inFolders
        ? Wallpapers.roots.length + 1 : Wallpapers.pictures.count + 1

    readonly property int columns: root.inFolders ? 4 : Theme.wallColumns

    // Coming back out of the folders lands on the folder you are in, not on
    // whatever index the picture grid had left behind.
    onInFoldersChanged: {
        root.cursor = root.inFolders
            ? Math.max(0, Wallpapers.roots.indexOf(Wallpapers.folder)) : 0;
    }

    implicitWidth: Theme.wallWidth
    implicitHeight: header.height + 10 + (root.inColour ? picker.height : body.height)

    // Escape backs out one step, then closes - the same shape as the back arrow
    // beside the title, so the key and the button never disagree.
    //
    // This is why the panel takes the keyboard at all: a layer surface with no
    // keyboard focus is never sent a key, so there was nothing for Escape to
    // arrive at. The cost is that typing goes here while it is open, which is
    // already true of the launcher and the control centre.
    focus: true

    Keys.onLeftPressed: root.move(-1)
    Keys.onRightPressed: root.move(1)
    Keys.onUpPressed: root.move(-root.columns)
    Keys.onDownPressed: root.move(root.columns)
    Keys.onReturnPressed: root.activate()
    Keys.onEnterPressed: root.activate()

    function move(by: int): void {
        root.cursor = Math.max(0, Math.min(root.cells - 1, root.cursor + by));
        root.reveal();
    }

    // Enter does whatever tapping the live cell would do, so the key and the
    // pointer can never mean two different things.
    function activate(): void {
        if (root.inFolders) {
            if (root.cursor >= Wallpapers.roots.length) {
                Wallpapers.addFolder();
                return;
            }

            Wallpapers.setFolder(Wallpapers.roots[root.cursor]);
            IslandState.wallpaperView = "grid";
            return;
        }

        if (root.cursor === 0) {
            Wallpapers.clearWallpaper();
            return;
        }

        Wallpapers.apply(Wallpapers.pictures.get(root.cursor - 1, "filePath"));
    }

    // Scrolls only as far as it has to. The grid is taller than the panel, so a
    // cursor moved with the keyboard would otherwise walk off the bottom into
    // the Flickable's clip and vanish.
    function reveal(): void {
        const row = Math.floor(root.cursor / root.columns);
        const h = root.inFolders
            ? Theme.folderCardHeight + Theme.sessionGap : Theme.wallCellHeight;
        const top = row * h;

        if (top < scroller.contentY)
            scroller.contentY = top;
        else if (top + h > scroller.contentY + scroller.height)
            scroller.contentY = top + h - scroller.height;
    }

    // MEASURED: `focus: true` alone left `activeFocus` false and NO key event
    // ever arrived. The control centre gets away with it only because a child
    // of it holds activeFocus and Escape propagates up to its root; this panel
    // has nothing focusable in it, so there was nothing for a key to reach.
    // Island calls this on the turn after the panel opens - the surface's
    // keyboard focus flips in the same turn, so asking any earlier asks a
    // window that is not focusable yet (notes.md fact 30).
    function claimFocus(): void {
        root.forceActiveFocus();
    }

    Keys.onEscapePressed: {
        if (root.inFolders)
            IslandState.wallpaperView = "grid";
        else
            IslandState.closeWallpaper();
    }

    // ---- header ------------------------------------------------------------
    Item {
        id: header

        width: parent.width
        height: 30

        Icon {
            id: mark

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            size: 19
            text: root.inFolders || root.inColour ? "arrow_back" : "wallpaper"
            color: root.inFolders || root.inColour ? Theme.textDim : Theme.accent

            HoverHandler {
                enabled: root.inFolders || root.inColour
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                enabled: root.inFolders || root.inColour
                onTapped: root.leaveColour()
            }
        }

        Text {
            anchors.left: mark.right
            anchors.leftMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            text: root.inFolders ? "Folders"
                : (root.inColour ? "Colour" : "Wallpaper")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            // Where the palette comes from: two buttons, one per source. The lit
            // one is the source in use. "Wallpaper colour" switches at once;
            // "Custom colour" opens the colour picker.
            HeaderChip {
                visible: !root.inFolders && !root.inColour
                icon: "wallpaper"
                label: "Wallpaper colour"
                lit: !Wallpapers.colourFixed
                onPressed: Wallpapers.setColourMode("wallpaper")
            }

            HeaderChip {
                visible: !root.inFolders && !root.inColour
                icon: "palette"
                label: "Custom colour"
                lit: Wallpapers.colourFixed
                onPressed: root.enterColour()
            }

            HeaderChip {
                visible: !root.inFolders && !root.inColour
                icon: "folder_open"
                label: Wallpapers.folderName
                trailing: "expand_more"
                onPressed: IslandState.wallpaperView = "folders"
            }

            HeaderChip {
                visible: root.inFolders
                icon: "create_new_folder"
                label: "Add folder"
                onPressed: Wallpapers.addFolder()
            }

            HeaderChip {
                visible: root.inColour
                icon: "wallpaper"
                label: "From wallpaper"
                lit: !Wallpapers.colourFixed
                onPressed: {
                    Theme.previewAccent = "transparent";
                    Wallpapers.setColourMode("wallpaper");
                    IslandState.wallpaperView = "grid";
                }
            }
        }
    }

    // ---- body --------------------------------------------------------------
    Item {
        id: body

        anchors.top: header.bottom
        anchors.topMargin: 10
        width: parent.width
        height: Math.min(inner.implicitHeight, Theme.wallMaxHeight)
        visible: !root.inColour

        transform: Translate { id: shift }

        // The folder list used to appear with no animation at all, which read
        // as a glitch rather than a move. It slides the way the depth goes.
        ParallelAnimation {
            id: swap

            NumberAnimation {
                target: shift
                property: "x"
                from: root.inFolders ? 22 : -22
                to: 0
                duration: Theme.animDuration
                easing.type: Theme.animEasing
            }

            NumberAnimation {
                target: scroller
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.animDuration
            }
        }

        Connections {
            target: IslandState

            function onWallpaperViewChanged(): void {
                swap.restart();
            }
        }

        Flickable {
            id: scroller

            anchors.fill: parent
            contentWidth: width
            contentHeight: inner.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Grid {
                id: inner

                width: scroller.width
                columns: root.inFolders ? 4 : Theme.wallColumns
                spacing: root.inFolders ? 8 : Theme.wallGap

                // ---- the pictures ------------------------------------------
                // "No wallpaper" is the first cell of the grid, not an item in
                // a menu: it is the same kind of choice as every picture beside
                // it.
                Item {
                    visible: !root.inFolders
                    width: Theme.wallCell
                    height: Theme.wallCellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Theme.wallPad
                        radius: Theme.wallRadius - Theme.wallPad
                        color: Qt.rgba(1, 1, 1,
                            noneHover.hovered || root.cursor === 0 ? 0.09 : 0.04)

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }
                    }

                    Icon {
                        anchors.centerIn: parent
                        size: 20
                        text: "block"
                        color: Wallpapers.current.length === 0 ? Theme.accent : Theme.textDisabled
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.wallRadius
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.accent
                        opacity: Wallpapers.current.length === 0 ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animDuration }
                        }
                    }

                    // The keyboard cursor, drawn in text colour so it never
                    // reads as "this is your wallpaper" - that is the accent
                    // ring plus the check badge, and only one cell has it.
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Theme.wallPad
                        radius: Theme.wallRadius - Theme.wallPad
                        color: "transparent"
                        border.width: 2
                        border.color: Qt.rgba(1, 1, 1, 0.55)
                        opacity: root.cursor === 0 && Wallpapers.current.length > 0 ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animDuration }
                        }
                    }

                    HoverHandler {
                        id: noneHover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: {
                            if (noneHover.hovered)
                                root.cursor = 0;
                        }
                    }

                    TapHandler {
                        onTapped: Wallpapers.clearWallpaper()
                    }
                }

                Repeater {
                    model: root.inFolders ? 0 : Wallpapers.pictures

                    Item {
                        id: cell

                        required property int index
                        required property string filePath
                        readonly property bool chosen: Wallpapers.current === cell.filePath
                        readonly property bool here: root.cursor === cell.index + 1

                        width: Theme.wallCell
                        height: Theme.wallCellHeight

                        ClippingRectangle {
                            anchors.fill: parent
                            anchors.margins: Theme.wallPad
                            radius: Theme.wallRadius - Theme.wallPad
                            color: Theme.skeleton

                            Image {
                                anchors.fill: parent
                                source: `file://${cell.filePath}`
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                // Decoded at roughly the size drawn - full
                                // wallpapers would be decoded whole, dozens at
                                // a time.
                                sourceSize.width: Theme.wallCell * 2
                            }
                        }

                        // Drawn INSIDE the cell: at a negative margin it fell
                        // outside the item's bounds and the Flickable's clip
                        // sliced it off.
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.wallRadius
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.accent
                            opacity: cell.chosen ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.animDuration }
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 2
                            visible: cell.chosen
                            width: 20
                            height: 20
                            radius: height / 2
                            color: Theme.accent

                            Icon {
                                anchors.centerIn: parent
                                size: 14
                                text: "check"
                                color: Theme.surfaceTint
                            }
                        }

                        // The keyboard cursor. Text colour, not accent: the
                        // accent ring and the check badge mean "this is your
                        // wallpaper", and only one cell may claim that.
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Theme.wallPad
                            radius: Theme.wallRadius - Theme.wallPad
                            color: "transparent"
                            border.width: 2
                            border.color: Qt.rgba(1, 1, 1, 0.55)
                            opacity: cell.here && !cell.chosen ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.animDuration }
                            }
                        }

                        HoverHandler {
                            id: cellHover
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: {
                                if (cellHover.hovered)
                                    root.cursor = cell.index + 1;
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Theme.wallPad
                            radius: Theme.wallRadius - Theme.wallPad
                            color: "white"
                            opacity: cell.here && !cell.chosen ? 0.12 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.animDuration }
                            }
                        }

                        TapHandler {
                            onTapped: Wallpapers.apply(cell.filePath)
                        }
                    }
                }

                // ---- the folders -------------------------------------------
                Repeater {
                    model: root.inFolders ? Wallpapers.roots : 0

                    Item {
                        id: dir

                        required property int index
                        required property var modelData
                        readonly property string path: dir.modelData
                        readonly property bool here: Wallpapers.folder === dir.path
                        readonly property bool live: root.cursor === dir.index
                        readonly property string label: {
                            const parts = dir.path.split("/").filter(p => p.length > 0);
                            return parts.length > 0 ? parts[parts.length - 1] : dir.path;
                        }

                        width: (scroller.width - 8 * 3) / 4
                        height: Theme.folderCardHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Theme.wallPad
                            radius: Theme.wallRadius - Theme.wallPad
                            color: dir.here ? Theme.accentFill
                                : Qt.rgba(1, 1, 1, dir.live ? 0.09 : 0.05)

                            Behavior on color {
                                ColorAnimation { duration: Theme.animDuration }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.wallRadius
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.accent
                            opacity: dir.here ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.animDuration }
                            }
                        }

                        // The mark and the remove button used to sit on top of
                        // each other in opposite corners of too small a card.
                        // The card is taller now and they are on one row, with
                        // the name below.
                        Item {
                            id: dirTop

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.wallPad + 6
                            height: 22

                            Icon {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                size: 19
                                text: dir.here ? "folder" : "folder_open"
                                color: dir.here ? Theme.accent : Theme.textDim
                            }

                            // Hover only - it must never be the thing you hit
                            // while choosing a folder.
                            Item {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                visible: dir.live
                                width: 22
                                height: 22

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: Qt.rgba(0, 0, 0, tuckHover.hovered ? 0.75 : 0.45)
                                }

                                Icon {
                                    anchors.centerIn: parent
                                    size: 14
                                    text: "close"
                                    color: tuckHover.hovered ? Theme.text : Theme.textDim
                                }

                                HoverHandler {
                                    id: tuckHover
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    onTapped: Wallpapers.removeFolder(dir.path)
                                }
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: Theme.wallPad + 6
                            anchors.top: dirTop.bottom
                            anchors.topMargin: 5
                            elide: Text.ElideMiddle
                            text: dir.label
                            color: dir.here ? Theme.text : Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: dir.here ? Font.Medium : Font.Normal
                        }

                        // The keyboard cursor, distinct from "this is the
                        // folder you are browsing" above.
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.wallRadius
                            color: "transparent"
                            border.width: 2
                            border.color: Qt.rgba(1, 1, 1, 0.55)
                            opacity: dir.live && !dir.here ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.animDuration }
                            }
                        }

                        HoverHandler {
                            id: dirHover
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: {
                                if (dirHover.hovered)
                                    root.cursor = dir.index;
                            }
                        }

                        // Choosing a folder takes you straight to its pictures:
                        // the only reason to pick one is to look inside it.
                        TapHandler {
                            onTapped: {
                                Wallpapers.setFolder(dir.path);
                                IslandState.wallpaperView = "grid";
                            }
                        }
                    }
                }

                // Adding one sits with the folders, as one more card.
                Item {
                    id: addCard

                    visible: root.inFolders
                    width: (scroller.width - 8 * 3) / 4
                    height: Theme.folderCardHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Theme.wallPad
                        radius: Theme.wallRadius - Theme.wallPad
                        color: Qt.rgba(1, 1, 1, addCard.live ? 0.07 : 0.03)
                        border.width: 2
                        border.color: Qt.rgba(1, 1, 1, addCard.live ? 0.55 : 0.14)

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            size: 21
                            text: "add"
                            color: addCard.live ? Theme.accent : Theme.textDim
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Add folder"
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }

                    readonly property bool live: root.inFolders
                        && root.cursor === Wallpapers.roots.length

                    HoverHandler {
                        id: addHover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: {
                            if (addHover.hovered)
                                root.cursor = Wallpapers.roots.length;
                        }
                    }

                    TapHandler {
                        onTapped: Wallpapers.addFolder()
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !root.inFolders && Wallpapers.pictures.count === 0
            text: Wallpapers.folder.length === 0
                ? "No folder yet - add one above"
                : "No pictures in this folder"
            color: Theme.textDisabled
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }

    // ---- the colour, in the bar --------------------------------------------
    function enterColour(): void {
        const saved = Wallpapers.colourHex.toLowerCase();
        const n = root.neutrals.indexOf(saved);

        if (n >= 0) {
            root.pick = 6 + n;
        } else {
            root.hue = root.hueOf(saved);
            root.pick = 3;
        }

        IslandState.wallpaperView = "colour";
        root.preview();
    }

    function leaveColour(): void {
        Theme.previewAccent = "transparent";
        IslandState.wallpaperView = "grid";
    }

    property real hue: 0.5

    function hueOf(hex: string): real {
        const c = Qt.color(hex);
        return c.hsvHue < 0 ? 0 : c.hsvHue;
    }

    // Six shades of the hue on the rail, from dark to light...
    readonly property var shades: [
        Qt.hsva(root.hue, 0.35, 0.22, 1),
        Qt.hsva(root.hue, 0.45, 0.42, 1),
        Qt.hsva(root.hue, 0.45, 0.66, 1),
        Qt.hsva(root.hue, 0.40, 1.00, 1),
        Qt.hsva(root.hue, 0.22, 1.00, 1),
        Qt.hsva(root.hue, 0.10, 1.00, 1)
    ]

    // ...then black, grey and white, which no hue can reach.
    readonly property var neutrals: ["#000000", "#808080", "#ffffff"]

    readonly property var swatches: root.shades.concat(root.neutrals.map(h => Qt.color(h)))

    // EVERY swatch can be picked. It used to be that only the fourth one ever
    // counted - the row was a picture, not a control - so clicking the dark
    // or the light end did nothing at all.
    property int pick: 3

    readonly property color chosen: root.swatches[root.pick]

    // The island previews the accent matugen will REALLY produce, not the
    // swatch itself. They differ a lot at the extremes: black becomes a light
    // grey accent (a black one would vanish on the dark bar). matugen answers
    // a dry run in ~29ms, so this is still instant; the timer only stops a
    // drag on the rail from starting one per frame.
    function preview(): void {
        previewDelay.restart();
    }

    Timer {
        id: previewDelay

        interval: 40
        onTriggered: {
            previewProc.running = false;
            previewProc.command = ["matugen", "color", "hex", root.chosen.toString().slice(0, 7),
                "-t", "scheme-fidelity", "-m", "dark", "--dry-run", "-j", "hex"];
            previewProc.running = true;
        }
    }

    Process {
        id: previewProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const accent = JSON.parse(text).colors.primary.dark.color;
                    if (root.inColour)
                        Theme.previewAccent = accent;
                } catch (e) {
                    // A half-written answer from a dry run cut short by the
                    // next one. The next one will answer.
                }
            }
        }
    }

    Item {
        id: picker

        anchors.top: header.bottom
        anchors.topMargin: 10
        width: parent.width
        height: 16 + 12 + 34 + 12 + 32
        visible: root.inColour

        Rectangle {
            id: rail

            width: parent.width
            height: 16
            radius: height / 2

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop { position: 0.00; color: Qt.hsva(0.00, 0.40, 1, 1) }
                GradientStop { position: 0.17; color: Qt.hsva(0.17, 0.40, 1, 1) }
                GradientStop { position: 0.33; color: Qt.hsva(0.33, 0.40, 1, 1) }
                GradientStop { position: 0.50; color: Qt.hsva(0.50, 0.40, 1, 1) }
                GradientStop { position: 0.67; color: Qt.hsva(0.67, 0.40, 1, 1) }
                GradientStop { position: 0.83; color: Qt.hsva(0.83, 0.40, 1, 1) }
                GradientStop { position: 1.00; color: Qt.hsva(1.00, 0.40, 1, 1) }
            }

            Rectangle {
                x: rail.width * root.hue - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                radius: height / 2
                color: root.shades[3]
                border.width: 3
                border.color: Qt.rgba(1, 1, 1, 0.9)
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -10
                cursorShape: Qt.PointingHandCursor

                function grab(mx: real): void {
                    root.hue = Math.max(0, Math.min(1, (mx - 10) / rail.width));

                    // Moving the hue means you want a hue: leave black, grey
                    // or white for the same shade you last had, or the middle.
                    if (root.pick > 5)
                        root.pick = 3;

                    root.preview();
                }

                onPressed: mouse => grab(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        grab(mouse.x);
                }
            }
        }

        Row {
            id: shadeRow

            anchors.top: rail.bottom
            anchors.topMargin: 12
            width: parent.width
            spacing: 6

            Repeater {
                model: root.swatches

                Rectangle {
                    id: swatch

                    required property int index
                    required property var modelData

                    width: (shadeRow.width - 6 * (root.swatches.length - 1)) / root.swatches.length
                    height: 34
                    radius: 10
                    color: swatch.modelData
                    border.width: root.pick === swatch.index ? 2 : (swatchHover.hovered ? 1 : 0)
                    border.color: root.pick === swatch.index
                        ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.35)

                    // Black, grey and white carry a hairline so the black one
                    // is not simply a hole in the panel.
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        visible: swatch.index > 5 && root.pick !== swatch.index
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.16)
                    }

                    HoverHandler {
                        id: swatchHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            root.pick = swatch.index;
                            root.preview();
                        }
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.top: shadeRow.bottom
            anchors.topMargin: 12
            spacing: 8

            SheetButton {
                label: "Cancel"
                onPressed: root.leaveColour()
            }

            SheetButton {
                label: "Use this"
                primary: true
                onPressed: {
                    Theme.previewAccent = "transparent";
                    Wallpapers.setColour(root.chosen.toString().slice(0, 7));
                    IslandState.wallpaperView = "grid";
                }
            }
        }
    }
}
