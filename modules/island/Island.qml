import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.modules.common
import qs.services
import qs.modules.island
import qs.modules.panels.idle
import qs.modules.panels.expanded
import qs.modules.panels.workspaces
import qs.modules.panels.launcher
import qs.modules.panels.notification
import qs.modules.panels.control
import qs.modules.panels.toast
import qs.modules.panels.session
import qs.modules.panels.wallpaper

PanelWindow {
    id: root

    // The island behaves like a bar, not like a floating overlay:
    //  - it reserves its own strip, so maximised windows sit below it instead
    //    of sliding underneath it,
    //  - and it disappears entirely when something on its monitor goes
    //    fullscreen, instead of sitting on top of a game or a video.
    readonly property var hyprMonitor: root.screen ? Hyprland.monitorFor(root.screen) : null
    readonly property bool fullscreenActive: root.hyprMonitor?.activeWorkspace?.hasFullscreen ?? false

    visible: !root.fullscreenActive

    anchors.top: true

    // Zero, with the bar's gap paid by the shape's own `y` and carried in the
    // exclusive zone below. MEASURED to reserve exactly what a `screenGap`
    // margin did (`hyprctl monitors` reserved [0, 49, 0, 0] both ways).
    margins.top: 0
    color: "transparent"

    // Pinned to the IDLE height on purpose. The expanded panel grows *over* the
    // desktop; an Auto exclusion zone would shove every window down the screen
    // every time the pointer touched the island.
    exclusionMode: ExclusionMode.Normal
    // `margins.top` used to contribute `screenGap` to what Hyprland reserved.
    // With the margin at 0 the zone has to carry it, or every window creeps up
    // by 7px. MEASURED both ways: reserved stays [0, 49, 0, 0].
    exclusiveZone: Theme.islandMinHeight + Theme.screenGap * 2 - Theme.compositorGapsOut

    WlrLayershell.namespace: "quickshell:dynisle"

    // The launcher needs to be typed into, so the surface must be able to take
    // keyboard focus.
    //
    // Exclusive, and **never** alongside `focusable` - on this build that is the
    // portable alias for the same setting, and having both silently downgraded
    // this to OnDemand. OnDemand alone is no good either: it hands focus over on
    // a CLICK, and this launcher is opened by a keybind, so no click ever comes.
    // Exclusive is what makes the compositor hand the surface the keyboard the
    // moment it appears.
    //
    // It is also the one setting in dynisle that could swallow every key on the
    // machine, so it is granted ONLY for the launcher panel and there are three
    // ways out: Escape on the field, SUPER+D again, and clicking away.
    // The control centre gets it too, so Escape can close it - it is opened by
    // a keybind, so it is reasonable for it to answer one. There are three ways
    // out either way: Escape, SUPER+R again, and clicking away.
    // Notifications no longer take the keyboard at all; the reply box is gone.
    readonly property bool wantsKeyboard: IslandState.panel === "launcher"
        || IslandState.panel === "control"
        || IslandState.panel === "wallpaper"
        || IslandState.panel === "session"

    WlrLayershell.keyboardFocus: root.wantsKeyboard
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    // FIXED size — this is the whole reason the animation is smooth. Binding the
    // window to the island's animated size meant the compositor reallocated and
    // re-committed a layer-shell surface on every frame, which stutters badly.
    // The window is a still, transparent canvas and only the shape inside it
    // moves, which is pure GPU compositing.
    //
    // FULL SCREEN, always. Not because anything is drawn out there - the canvas
    // is transparent and the mask keeps input to the shape - but because
    // clicking outside has to land on THIS window to be caught, and resizing
    // the surface to do that on demand was worse than the problem: growing it
    // to full screen at the same moment the shape began animating made the
    // compositor reallocate and re-commit mid-animation, and the open stuttered
    // badly. A surface that never changes size never does that.
    //
    // It has to be this window. A separate fullscreen surface was tried and
    // measured not to receive the pointer at all (vault/notes.md fact 70c),
    // while this one demonstrably does - hovering the island is how the
    // expanded panel opens.
    implicitWidth: root.screen?.width ?? Theme.islandMaxWidth
    implicitHeight: root.screen?.height ?? Theme.islandMaxHeight

    // Declared BEFORE IslandShape so the shape sits above it and keeps its own
    // clicks. Sized to nothing when idle, so it can never eat one.
    MouseArea {
        id: dismissArea

        width: root.grabbing ? root.width : 0
        height: root.grabbing ? root.height : 0
        enabled: root.grabbing

        onPressed: {
            if (IslandState.panel === "launcher")
                IslandState.closeLauncher();
            else if (IslandState.panel === "wallpaper")
                IslandState.closeWallpaper();
            else if (IslandState.panel === "session")
                IslandState.closeSession();
            else
                IslandState.closeControl();
        }
    }

    // Singletons are created on FIRST REFERENCE (vault/notes.md fact 33), and
    // nothing in the UI reads this one - it only watches udev and pacman and
    // raises notifications of its own. Without a touch it would never be
    // constructed and would silently do nothing at all.
    Component.onCompleted: SystemNotify.updateCount

    // The launcher's pinned icons used to come up grey on the FIRST open after
    // a restart and only render on the second - the panel is built lazily, so
    // every icon was being resolved and decoded while it was already on screen.
    // These load the same icons at the same size during startup instead. Qt
    // caches decoded images by URL, so by the time the panel is opened they are
    // already there. Zero opacity, no input, never seen.
    Item {
        opacity: 0
        enabled: false
        width: 1
        height: 1

        Repeater {
            model: Launcher.pinned

            IconImage {
                required property var modelData

                implicitSize: Theme.launcherPinIcon
                asynchronous: true
                // must match the launcher's, or the cache entries differ
                backer.autoTransform: Launcher.iconKey
                source: Quickshell.iconPath(modelData.icon, "application-x-executable")
            }
        }
    }

    IslandShape {
        id: shape

        // The bar's gap from the screen edge. It lives here rather than in the
        // window's `margins.top` - see the comment on that above.
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.screenGap

        // A panel may ask for its own horizontal padding and minimum width;
        // most do not.
        paddingH: panelLoader.item?.islandPaddingH ?? Theme.islandPaddingH
        radiusHint: panelLoader.item?.islandRadius ?? Theme.radius
        minWidth: panelLoader.item?.islandMinWidth ?? Theme.islandMinWidth

        // The notification panel owns a countdown; nothing else does, and the
        // default of -1 keeps the bar off for every other panel.
        drain: panelLoader.item?.drain ?? -1
        drainColor: panelLoader.item?.drainColor ?? Theme.accent

        onHoveredChanged: IslandState.hovered = shape.hovered

        // Nothing may be declared INSIDE this Loader: a Loader's default
        // property is `sourceComponent`, so a child object silently becomes the
        // thing it tries to load. The fade animation lives outside for exactly
        // that reason — declared in here it left the panel stuck at opacity 0,
        // correctly sized but completely invisible.
        Loader {
            id: panelLoader

            sourceComponent: {
                switch (IslandState.panel) {
                case "expanded":   return expandedPanel;
                case "workspaces": return workspacePanel;
                case "launcher":   return launcherField;
                case "notification": return notificationPanel;
                case "control":    return controlPanel;
                case "toast":      return toastPanel;
                case "wallpaper":  return wallpaperPanel;
                case "session":    return sessionPanel;
                default:           return idlePill;
                }
            }

            // The Loader swaps content instantly while the shape takes
            // animDuration to grow, so the incoming panel is faded and slid
            // into place rather than appearing at full size inside a shape that
            // has not finished moving.
            onSourceComponentChanged: contentSwap.restart()

            // A Translate, NOT `y`. The island measures its content via
            // childrenRect, so animating the Loader's y would drag the island's
            // own height along with it. Transforms are invisible to layout.
            transform: Translate {
                id: slide
            }
        }
    }

    ParallelAnimation {
        id: contentSwap

        NumberAnimation {
            target: panelLoader
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.contentFadeDuration
        }

        NumberAnimation {
            target: slide
            property: "y"
            from: -6
            to: 0
            duration: Theme.contentFadeDuration
            easing.type: Theme.animEasing
        }
    }

    // The results are their own surface, sitting below the island with a gap -
    // two shapes, as the design calls for, still inside this one PanelWindow so
    // the architecture rule holds (only Island and WallpaperLayer make windows).
    Loader {
        id: resultsLoader

        active: IslandState.panel === "launcher" && Launcher.showPanel
        anchors.top: shape.bottom
        anchors.topMargin: Theme.launcherGap
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: LauncherResults {}

        // Rises into place rather than appearing, and leaves the same way.
        opacity: resultsLoader.active ? 1 : 0

        transform: Translate {
            y: resultsLoader.active ? 0 : -8

            Behavior on y {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Theme.animEasing
                }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.contentFadeDuration }
        }
    }

    // Without a mask the whole transparent canvas swallows clicks meant for the
    // windows underneath, so the input region is restricted to what is actually
    // drawn. Assigned AFTER the loader above: an id is not resolvable from a
    // property binding created before the object it names exists.
    //
    // Nested regions combine, so the results surface is added to the clickable
    // area - without it the panel would be visible but dead.
    mask: Region {
        item: shape

        Region {
            item: resultsLoader.item ?? null
        }

        // Whole screen while a panel is open, nothing otherwise.
        Region {
            item: dismissArea
        }

    }

    // Kept outside IslandShape: everything declared inside it lands in the
    // shape's content, and content is what the island measures itself against.
    Component {
        id: idlePill
        IdlePill {}
    }

    Component {
        id: expandedPanel
        ExpandedPanel {}
    }

    Component {
        id: workspacePanel
        WorkspacePanel {}
    }

    Component {
        id: launcherField
        LauncherField {}
    }

    Component {
        id: notificationPanel
        NotificationPanel {}
    }

    Component {
        id: controlPanel
        ControlPanel {}
    }

    Component {
        id: toastPanel
        ToastPanel {}
    }

    Component {
        id: wallpaperPanel
        WallpaperPanel {}
    }

    Component {
        id: sessionPanel
        SessionPanel {}
    }

    // The two panels that are opened by a keybind and have to close again when
    // attention goes elsewhere.
    readonly property bool grabbing: IslandState.panel === "launcher"
        || IslandState.panel === "control"
        || IslandState.panel === "wallpaper"
        || IslandState.panel === "session"

    // NO HyprlandFocusGrab here, and that is deliberate. Bound directly to
    // "is something open" - the way end4-pC does it - Hyprland cleared the grab
    // on the very frame it was taken, so the launcher and the control centre
    // slammed shut the instant they opened. end4-pC gets away with it because
    // its panels are FULLSCREEN windows with OnDemand keyboard focus; dynisle's
    // island is a small window holding EXCLUSIVE focus, and the two behave
    // differently. Clicking outside is still unsolved - see vault/notes.md.

    // The second way out, alongside ShotLayer's dismiss layer: Hyprland
    // announces `activewindow` whenever a window takes focus, and a window
    // taking focus while the launcher is up can only mean attention went
    // elsewhere. Costs nothing and catches cases a click never produces, such
    // as another application raising itself.
    Timer {
        id: outsideGuard

        // Opening the launcher itself pulls focus off whatever window had it,
        // and that announcement must not be mistaken for a click away.
        interval: 500
    }

    // ONLY for the two panels that hold exclusive keyboard focus. For those, a
    // window taking focus can only mean the user went elsewhere, because
    // nothing else could have taken it from us. The wallpaper picker and the
    // wallpaper picker takes no keyboard focus at all, so ordinary focus churn
    // is not a signal about it - MEASURED: with this enabled for it, an
    // `activewindow` arriving about half a second after opening closed the
    // panel on its own, every time. Clicking away still dismisses it, through
    // `dismissArea`, which is the mechanism that was actually asked for.
    Connections {
        target: Hyprland
        enabled: IslandState.panel === "launcher" || IslandState.panel === "control"

        function onRawEvent(event): void {
            if (event.name !== "activewindow" && event.name !== "activewindowv2")
                return;
            if (outsideGuard.running)
                return;

            if (IslandState.panel === "launcher")
                IslandState.closeLauncher();
            else
                IslandState.closeControl();
        }
    }

    Connections {
        target: IslandState

        function onPanelChanged(): void {
            if (!root.grabbing)
                return;

            outsideGuard.restart();

            // The panel and the surface's keyboard focus flip in the same turn,
            // so the panel can be created before the window is focusable.
            // Claim it again once both have settled. Every panel that wants the
            // keyboard needs this, not just the launcher: without it a panel
            // with nothing focusable inside it is sent no keys at all, and its
            // `Keys.onEscapePressed` never fires.
            if (root.wantsKeyboard)
                Qt.callLater(() => panelLoader.item?.claimFocus?.());
        }
    }

    // Already bound in ~/.config/hypr/custom/keybinds.lua as
    // `SHIFT + Print` -> `hl.dsp.global("quickshell:regionScreenshot")`, with a
    // comment saying it expects a Quickshell shortcut by that exact name. So
    // implementing it here is all that was missing - the keybind was waiting.
    GlobalShortcut {
        id: screenshotShortcut

        appid: "quickshell"
        name: "regionScreenshot"
        description: "Copy a screen region to the clipboard"

        onPressed: {
            if (screenshotShortcut.pressed)
                Screenshot.region();
        }
    }

    // SUPER + S. Leaving the machine.
    GlobalShortcut {
        id: sessionShortcut

        appid: "quickshell"
        name: "dynisleSession"
        description: "Toggle the dynisle session panel"

        onPressed: {
            if (sessionShortcut.pressed)
                IslandState.toggleSession();
        }
    }

    // SUPER + A. The wallpaper picker.
    GlobalShortcut {
        id: wallpaperShortcut

        appid: "quickshell"
        name: "dynisleWallpaper"
        description: "Toggle the dynisle wallpaper picker"

        onPressed: {
            if (wallpaperShortcut.pressed)
                IslandState.toggleWallpaper();
        }
    }

    // SUPER + Print. Whole screen straight to the clipboard, then a flash.
    GlobalShortcut {
        id: fullShortcut

        appid: "quickshell"
        name: "fullScreenshot"
        description: "Copy the whole screen to the clipboard"

        onPressed: {
            if (fullShortcut.pressed)
                Screenshot.full();
        }
    }

    // Bound in Hyprland with `hl.dsp.global("quickshell:dynisleLauncher")`.
    // A compositor shortcut, not an IpcHandler: `qs ipc call` spawns a whole
    // process per keypress.
    GlobalShortcut {
        id: launcherShortcut

        appid: "quickshell"
        name: "dynisleLauncher"
        description: "Toggle the dynisle launcher"

        // Guarded on the `pressed` property: this fires for the release too,
        // which toggled the launcher open and shut again within one frame and
        // made it look like the shortcut did nothing at all.
        // Guarded on the `pressed` property so a release event can never toggle
        // the launcher shut again in the same breath.
        onPressed: {
            if (launcherShortcut.pressed)
                IslandState.toggleLauncher();
        }
    }

    // SUPER + R. Same reasoning as the launcher shortcut: a compositor global,
    // guarded on `pressed` so the key release cannot toggle it shut again.
    GlobalShortcut {
        id: controlShortcut

        appid: "quickshell"
        name: "dynisleControl"
        description: "Toggle the dynisle control centre"

        onPressed: {
            if (controlShortcut.pressed)
                IslandState.toggleControl();
        }
    }
}
