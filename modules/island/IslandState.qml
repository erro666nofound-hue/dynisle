pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.services

// Which content the island is showing. It holds the decision, never sizes -
// the island measures whatever panel is loaded and grows to fit
// (vault/notes.md fact 16).
Singleton {
    id: root

    // Hover.
    // Whether the pointer is on the island's own shape. Island writes this.
    property bool hovered: false

    // Hovering expands the island - unless the pointer is only there because it
    // was using something bigger that has just closed. Without this latch,
    // dismissing the control centre with the pointer still over it let the
    // island collapse, flash the media panel for a moment, and only then
    // settle: the panel closed, `hovered` was still true, and the priority
    // chain fell straight through to "expanded".
    property bool hoverLatched: false

    readonly property bool expanded: root.hovered && !root.hoverLatched

    onHoveredChanged: {
        // The latch is released by leaving, never by time - so the pointer has
        // to actually go away and come back for hover to mean anything again.
        if (!root.hovered)
            root.hoverLatched = false;
    }

    // The launcher, opened by a global shortcut.
    property bool launcherOpen: false

    // A notification is being shown. The popup itself owns the countdown, so
    // that hovering can pause it.
    property bool notificationOpen: false

    // The control centre, opened by a global shortcut. `controlView` is which
    // layer of it is showing - Wi-Fi and the device pickers grow the bar itself
    // rather than opening anything, so they are views here, not windows.
    property bool controlOpen: false
    property string controlView: "home"
    // Which way the next view should slide in from.
    property bool controlForward: true

    // A workspace switch flashes the island into a workspace indicator for a
    // moment, then it returns on its own.
    property bool workspaceFlash: false

    property int workspace: 0

    // The launcher outranks everything: it is the only state the user opened
    // deliberately, it owns the keyboard, and nothing may pull it out from
    // under them mid-search. Hover then beats the workspace flash, because if
    // the pointer is on the island they are reading the panel.
    // A notification outranks hover on purpose. Moving the pointer onto the
    // island to read one must not replace it with the media panel - instead the
    // popup treats hover as "hold", and pauses its own countdown.
    readonly property string panel: root.launcherOpen ? "launcher"
        : (root.controlOpen ? "control"
        : (root.sessionOpen ? "session"
        : (root.wallpaperOpen ? "wallpaper"
        : (root.toastOpen ? "toast"
        : (root.notificationOpen ? "notification"
        : (root.expanded ? "expanded"
        : (root.workspaceFlash ? "workspaces" : "idle")))))))

    // A confirmation the island wears for a moment - a screenshot landing on
    // the clipboard, and nothing else so far. It outranks notifications
    // because it answers something the user just did, this second.
    property bool toastOpen: false
    property string toastText: ""
    property string toastIcon: "content_copy"

    function showToast(text: string): void {
        root.toastText = text;
        root.toastOpen = true;
        toastTimer.restart();
    }

    Timer {
        id: toastTimer

        interval: 1600
        onTriggered: root.toastOpen = false
    }

    // The panels are mutually exclusive, and each of these says so out loud.
    // They used to be independent flags that a priority chain merely ranked, so
    // opening one while another was up left the first one running BEHIND it -
    // press SUPER+R over the launcher, dismiss the launcher, and the control
    // centre was suddenly there instead of the island returning to the bar.

    // The greeting ("Welcome, <user>") and the "Sleeping" veil were removed
    // on 2026-09-29 at the user's request: sleep is just sleep now, with no
    // animation on the way down or the way back. See vault/06-decisions.md.

    // Leaving the machine: lock, sleep, restart, shut down. Its own panel on
    // SUPER+S, deliberately NOT inside the control centre - that is for things
    // you adjust and come back from.
    property bool sessionOpen: false

    function openSession(): void {
        root.closeLauncher();
        root.closeControl();
        root.closeWallpaper();
        root.sessionOpen = true;
    }

    function closeSession(): void {
        root.hoverLatched = root.hovered;
        root.sessionOpen = false;
    }

    function toggleSession(): void {
        if (root.sessionOpen)
            root.closeSession();
        else
            root.openSession();
    }

    // The wallpaper picker. Themes lived beside it as a second panel; they were
    // removed, so the only depth left is the folder list:
    //   "grid"    the pictures in the folder being browsed
    //   "folders" the folders it knows about
    property bool wallpaperOpen: false
    property string wallpaperView: "grid"

    function openWallpaper(): void {
        root.closeLauncher();
        root.closeControl();
        root.closeSession();
        root.wallpaperView = "grid";
        root.wallpaperOpen = true;
    }

    function closeWallpaper(): void {
        root.hoverLatched = root.hovered;
        root.wallpaperOpen = false;
        root.wallpaperView = "grid";
    }

    function toggleWallpaper(): void {
        if (root.wallpaperOpen)
            root.closeWallpaper();
        else
            root.openWallpaper();
    }

    function openControl(): void {
        root.closeWallpaper();
        root.closeSession();
        root.closeLauncher();
        root.controlView = "home";
        root.controlForward = true;
        root.controlOpen = true;
    }

    function closeControl(): void {
        root.hoverLatched = root.hovered;
        root.controlOpen = false;
        root.controlView = "home";
        root.joinTarget = null;
    }

    function toggleControl(): void {
        if (root.controlOpen)
            root.closeControl();
        else
            root.openControl();
    }

    // Descending into a layer slides forward; coming back slides the other way,
    // so the direction says which is happening.
    function pushView(view: string): void {
        root.controlForward = true;
        root.controlView = view;
    }

    // The password sheet belongs to the network list, so backing out of it
    // returns there rather than all the way to the top.
    function popView(): void {
        root.controlForward = false;
        root.controlView = root.controlView === "join" ? "wifi" : "home";
        if (root.controlView !== "join")
            root.joinTarget = null;
    }

    // The network the password sheet is asking about.
    property var joinTarget: null

    function askPassword(network): void {
        root.joinTarget = network;
        root.pushView("join");
    }

    function openLauncher(): void {
        root.closeWallpaper();
        root.closeSession();
        root.closeControl();
        Launcher.query = "";
        Launcher.selected = 0;
        root.launcherOpen = true;
    }

    // Every exit from the launcher goes through here, so the surface can never
    // be left holding exclusive keyboard focus with nothing on screen.
    function closeLauncher(): void {
        root.hoverLatched = root.hovered;
        root.launcherOpen = false;
        Launcher.query = "";
    }

    function toggleLauncher(): void {
        if (root.launcherOpen)
            root.closeLauncher();
        else
            root.openLauncher();
    }

    // MEASURED, not assumed: on this Quickshell build `Hyprland.focusedWorkspace`
    // and `Hyprland.focusedMonitor` both read `undefined`, so neither can drive
    // this. `Hyprland.workspaces.values` IS populated, and the raw event stream
    // fires reliably - `workspacev2 >> <id>,<name>` on every switch. So events
    // are the source of truth for "which workspace", and the model is only used
    // for "which workspaces exist".
    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name !== "workspacev2")
                return;

            const id = parseInt(event.data.split(",")[0]);
            if (isNaN(id) || id === root.workspace)
                return;

            root.workspace = id;
            root.workspaceFlash = true;
            flashTimer.restart();
        }
    }

    // Seeded without flashing: starting the shell is not a workspace switch.
    Component.onCompleted: {
        const active = Hyprland.workspaces.values.find(w => w.active);
        if (active)
            root.workspace = active.id;
    }

    Connections {
        target: Notifications

        function onArrived(): void {
            root.notificationOpen = true;
        }
    }

    function dismissNotification(): void {
        root.notificationOpen = false;
        Notifications.dismiss();
    }

    Timer {
        id: flashTimer

        interval: 1500
        onTriggered: root.workspaceFlash = false
    }
}
