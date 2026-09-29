pragma Singleton

import Quickshell

// Leaving the machine. Four commands and no state.
//
// `execDetached`, not `Process`: a Process is a CHILD of the shell, and reboot
// and poweroff kill the shell. A child dying with its parent mid-shutdown is a
// race there is no reason to run.
//
// Through logind for the lock, never `hyprlock` directly: hypridle's idle lock,
// the lid switch and this all end up at the same screen, and logind's Lock
// signal is what guarantees only one hyprlock ever exists.
Singleton {
    function lock(): void {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    // No lock here: hypridle's `before_sleep_cmd = loginctl lock-session`
    // already locks on the way down, so the machine cannot wake up unlocked.
    function sleep(): void {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function restart(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function shutdown(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
