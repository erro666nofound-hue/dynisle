pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Backlight, read from sysfs and written with brightnessctl.
//
// Reading through FileView rather than shelling out means the brightness keys
// on the keyboard move this slider too - the file changes, the view reloads.
Singleton {
    id: root

    readonly property string device: "intel_backlight"

    property int raw: 0
    property int max: 1

    // Never allow 0: a black screen with no way back is not a state a control
    // centre should be able to produce.
    readonly property real minFraction: 0.05
    readonly property real value: root.max > 0 ? root.raw / root.max : 0

    FileView {
        path: `/sys/class/backlight/${root.device}/max_brightness`
        onLoaded: root.max = parseInt(text()) || 1
    }

    FileView {
        path: `/sys/class/backlight/${root.device}/brightness`
        watchChanges: true

        onFileChanged: reload()
        onLoaded: root.raw = parseInt(text()) || 0
    }

    Process {
        id: apply
    }

    function set(fraction: real): void {
        const clamped = Math.max(root.minFraction, Math.min(1, fraction));
        // Optimistic: the slider should not wait for the file watcher to catch
        // up before it moves under the pointer.
        root.raw = Math.round(clamped * root.max);

        apply.running = false;
        apply.command = ["brightnessctl", "-d", root.device, "set", `${Math.round(clamped * 100)}%`];
        apply.running = true;
    }
}
