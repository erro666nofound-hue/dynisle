import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.modules.common
import qs.modules.island
import qs.services

// Two jobs, one surface: choosing a region out of a frozen screen, and then
// flying the result up into the island.
//
// This is the only PanelWindow in dynisle besides Island and WallpaperLayer,
// and it earns the exception - both jobs cover the whole screen, which nothing
// living inside the island can reach.
//
// It is on `WlrLayer.Top` and declared BEFORE Island in shell.qml, because
// Hyprland stacks same-layer surfaces in CREATION order and the flying picture
// has to pass underneath the island at the end of its flight. It is also
// mapped for the whole session for that same reason: creating it lazily put it
// on top of the island instead, and cost a visible pause besides.
PanelWindow {
    id: root

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    color: "transparent"
    visible: true

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:dynisle-shot"

    // Only while choosing. The rest of the time this surface must be invisible
    // to the keyboard, or it would swallow every key on the machine.
    WlrLayershell.keyboardFocus: Screenshot.selecting
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore

    // Empty unless a region is being chosen.
    //
    // A fullscreen dismiss layer to catch clicks landing outside the launcher
    // was tried here and REMOVED: measured with the panel open, the pointer at
    // (708,639) - far outside the island - the mask a constant 1366x768 item,
    // and no focus grab anywhere to consume input, `containsMouse` stayed
    // false. A Top-layer surface simply does not receive the pointer in this
    // setup, whatever the mask says. See vault/notes.md fact 70.
    mask: Region {
        item: Screenshot.selecting ? hit : null
    }

    // ---- choosing a region -------------------------------------------------
    Item {
        id: chooser

        anchors.fill: parent
        visible: Screenshot.selecting
        focus: Screenshot.selecting

        // The frozen screen. Everything below is drawn over this, so what you
        // are selecting out of is a still picture and a menu that vanishes the
        // moment you let go of a key can still be captured.
        Image {
            id: frozen

            anchors.fill: parent
            source: Screenshot.freezeImage
            cache: false
            asynchronous: false
        }

        // Dimmed everywhere - and it EASES in. The freeze and the dimming
        // arrive on the same frame, so without this the screen went dark in one
        // step, which is what the rewrite lost.
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: Screenshot.selecting ? 0.55 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }

        // ...except the selection, which is the same frozen picture drawn again
        // at full brightness. Redrawing it is what allows ROUNDED corners: a
        // hole cut in the dimming could only ever be a rectangle.
        ClippingRectangle {
            id: hole

            x: chooser.selX
            y: chooser.selY
            width: chooser.selW
            height: chooser.selH
            visible: chooser.dragging && width > 1 && height > 1
            radius: Math.min(12, Math.min(width, height) / 2)
            color: "transparent"

            Image {
                // Positioned so the frozen picture lines up with the screen
                // behind it - the crop is done by the parent's clipping, not by
                // moving the image.
                x: -hole.x
                y: -hole.y
                width: chooser.width
                height: chooser.height
                source: Screenshot.freezeImage
                cache: false
                asynchronous: false
            }
        }

        property bool dragging: false
        property bool moved: false
        property real anchorX: 0
        property real anchorY: 0
        property real pointX: 0
        property real pointY: 0

        readonly property real selX: Math.min(chooser.anchorX, chooser.pointX)
        readonly property real selY: Math.min(chooser.anchorY, chooser.pointY)
        readonly property real selW: Math.abs(chooser.pointX - chooser.anchorX)
        readonly property real selH: Math.abs(chooser.pointY - chooser.anchorY)

        MouseArea {
            id: hit

            width: Screenshot.selecting ? chooser.width : 0
            height: Screenshot.selecting ? chooser.height : 0
            enabled: Screenshot.selecting
            // The crosshair belongs to this surface, so it goes away with it -
            // no cursor left stranded after the selection is cancelled.
            // The system crosshair comes from the session cursor theme, which
            // here is Bibata-Modern-Classic: a BLACK cross with a white
            // outline, nearly invisible on a dimmed screen. Blanking it and
            // drawing our own is the only way to get a plain white one - and it
            // cannot be left stranded on screen either, because it is part of
            // this surface.
            cursorShape: Qt.BlankCursor
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPressed: mouse => {
                if (mouse.button === Qt.RightButton) {
                    Screenshot.cancel();
                    return;
                }

                chooser.moved = true;
                chooser.anchorX = mouse.x;
                chooser.anchorY = mouse.y;
                chooser.pointX = mouse.x;
                chooser.pointY = mouse.y;
                chooser.dragging = true;
            }

            onPositionChanged: mouse => {
                chooser.moved = true;

                if (!chooser.dragging)
                    return;

                chooser.pointX = mouse.x;
                chooser.pointY = mouse.y;
            }

            onReleased: {
                if (!chooser.dragging)
                    return;

                chooser.dragging = false;
                Screenshot.takeRegion(Math.round(chooser.selX), Math.round(chooser.selY),
                    Math.round(chooser.selW), Math.round(chooser.selH));
            }
        }

        // Drawn last so it sits over everything, including the bright hole.
        // Bound to the MouseArea's OWN position rather than tracked by hand:
        // hand-tracking only starts on the first movement, so opening the
        // chooser and not moving the mouse left no cursor on screen at all.
        // A real size with the bars INSIDE it. A zero-sized Item whose children
        // sit at negative offsets drew nothing at all - the arms have to live
        // within the item's own bounds.
        Item {
            id: crosshair

            readonly property real arm: 9
            readonly property real gap: 3
            readonly property real half: crosshair.arm + crosshair.gap

            // Seeded from where the pointer actually was when the screen froze,
            // then handed over to the MouseArea the moment it reports one: a
            // surface mapping under a stationary pointer does not reliably
            // produce a position, so without the seed there was no cursor at
            // all until the mouse moved.
            x: (chooser.moved ? hit.mouseX : Screenshot.cursorX) - crosshair.half
            y: (chooser.moved ? hit.mouseY : Screenshot.cursorY) - crosshair.half
            width: crosshair.half * 2
            height: crosshair.half * 2
            z: 10

            Rectangle {
                x: 0
                y: crosshair.half - 1
                width: crosshair.arm
                height: 2
                color: "white"
            }

            Rectangle {
                x: crosshair.half + crosshair.gap
                y: crosshair.half - 1
                width: crosshair.arm
                height: 2
                color: "white"
            }

            Rectangle {
                x: crosshair.half - 1
                y: 0
                width: 2
                height: crosshair.arm
                color: "white"
            }

            Rectangle {
                x: crosshair.half - 1
                y: crosshair.half + crosshair.gap
                width: 2
                height: crosshair.arm
                color: "white"
            }
        }

        Keys.onEscapePressed: Screenshot.cancel()
    }

    // ---- the flight --------------------------------------------------------
    // Smaller than the idle pill on purpose: it has to be swallowed whole, not
    // parked on the island's edge.
    readonly property real targetW: 58
    readonly property real targetH: 34
    readonly property real targetX: (root.width - root.targetW) / 2
    readonly property real targetY: Theme.screenGap
        + (Theme.islandMinHeight - root.targetH) / 2

    ClippingRectangle {
        id: shot

        opacity: 0
        radius: shot.width < root.width * 0.5 ? 10 : 0
        color: "transparent"

        Behavior on radius {
            NumberAnimation { duration: Theme.animDuration }
        }

        // The captured region, taken straight out of the frozen picture with no
        // file to wait for. `sourceClipRect` is what makes that possible - the
        // whole screen is loaded once and only the selected part is shown.
        Image {
            anchors.fill: parent
            source: root.flightSource
            cache: false
            asynchronous: false
            fillMode: Image.Stretch
            sourceClipRect: root.flightClip
        }
    }

    property string flightSource: ""
    property rect flightClip: Qt.rect(0, 0, 0, 0)

    ParallelAnimation {
        id: fly

        NumberAnimation { target: shot; property: "x"; to: root.targetX; duration: 460; easing.type: Easing.InOutCubic }
        NumberAnimation { target: shot; property: "y"; to: root.targetY; duration: 460; easing.type: Easing.InOutCubic }
        NumberAnimation { target: shot; property: "width"; to: root.targetW; duration: 460; easing.type: Easing.InOutCubic }
        NumberAnimation { target: shot; property: "height"; to: root.targetH; duration: 460; easing.type: Easing.InOutCubic }

        // No fade. The picture stays solid the whole way and the island covers
        // it - it goes INTO the bar rather than dissolving in front of it.
        onFinished: shot.opacity = 0
    }

    Connections {
        target: Screenshot

        function onStarted(x: int, y: int, w: int, h: int): void {
            // For a region this is the frozen picture, still loaded; for a full
            // screen there is nothing to show yet, so the frame flies empty and
            // the toast does the talking.
            root.flightSource = Screenshot.freezeImage;
            root.flightClip = Qt.rect(x, y, w, h);

            shot.x = x;
            shot.y = y;
            shot.width = w;
            shot.height = h;
            shot.opacity = root.flightSource.length > 0 ? 1 : 0;
            fly.restart();
        }

        // Said only once the clipboard really has it.
        function onCopied(): void {
            IslandState.showToast("Copied to clipboard");
        }
    }
}
