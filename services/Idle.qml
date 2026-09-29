pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// "Keep awake".
//
// NOT `systemctl --user stop hypridle`, which is what this did at first and
// which did nothing at all: hypridle is started by Hyprland itself
// (`hl.exec_cmd("hypridle")` in hyprland/execs.lua), so it is a plain process
// and not a user unit. `systemctl --user is-active hypridle` answered
// "inactive" about a process that was very much running, which - because the
// reading was inverted - left the tile permanently showing "On".
//
// The right lever is a logind idle inhibitor. hypridle honours those unless
// `ignore_dbus_inhibit` is set, and it is not set here. So this holds one open
// for as long as the toggle is on, which is also the standard mechanism every
// video player uses.
Singleton {
    id: root

    // The state IS the process. Nothing to query and nothing to poll: if the
    // inhibitor is held, idling is inhibited, and if the shell dies the
    // process dies with it and the inhibit is released - which is the right
    // behaviour for something this temporary.
    property bool inhibited: false

    Process {
        // `sleep infinity` is the whole job: systemd-inhibit holds the
        // inhibitor for as long as its child lives, so the child only has to
        // exist. Quickshell terminates it when `running` goes false, which
        // releases the inhibitor.
        running: root.inhibited
        command: ["systemd-inhibit",
            "--what=idle",
            "--who=dynisle",
            "--why=Keep awake",
            "--mode=block",
            "sleep", "infinity"]
    }

    function toggle(): void {
        root.inhibited = !root.inhibited;
    }
}
