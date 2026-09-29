pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Night light through hyprsunset, which is already running on this machine and
// is controlled at runtime with `hyprctl hyprsunset`.
//
// "Off" is the identity matrix rather than 6500K: identity means no colour
// transform at all, which is not quite the same as a neutral temperature.
Singleton {
    id: root

    readonly property int warmTemperature: 4000
    readonly property int neutralTemperature: 6000

    property int temperature: root.neutralTemperature
    readonly property bool active: root.temperature < root.neutralTemperature

    Process {
        id: query

        command: ["hyprctl", "hyprsunset", "temperature"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = parseInt(text.trim());
                if (!isNaN(t))
                    root.temperature = t;
            }
        }
    }

    Process { id: apply }

    Component.onCompleted: root.refresh()

    function refresh(): void {
        query.running = false;
        query.running = true;
    }

    function set(kelvin: int): void {
        root.temperature = kelvin;
        apply.running = false;
        apply.command = ["hyprctl", "hyprsunset", "temperature", String(kelvin)];
        apply.running = true;
    }

    function toggle(): void {
        root.set(root.active ? root.neutralTemperature : root.warmTemperature);
    }
}
