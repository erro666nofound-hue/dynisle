pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// The system notifications dynisle raises itself, because nothing else on this
// machine raises them:
//
//   - a USB device being plugged in or pulled out
//   - pending pacman updates
//
// The input method used to be watched here too, and it is gone on purpose:
// `fcitx5-remote -n` reports an EMPTY name whenever no window holds an input
// context, which happens on every workspace switch. The empty-then-restored
// reading looked exactly like a real switch, so changing workspace raised a
// spurious "Keyboard" notification every time. fcitx5 emits no DBus signal to
// use instead (notes.md fact 45), so the feature was dropped rather than
// papered over.
//
// Battery is deliberately NOT here: ~/user_scripts/battery/notify runs as
// battery_notify.service and already covers charging, unplugged, full, low,
// critical and empty. Duplicating it would show everything twice.
//
// Each one goes out through `notify-send`, the same door every other sender
// uses, so they get the same rendering, the same Do Not Disturb, and the same
// slot replacement as everything else.
Singleton {
    id: root

    // ---- plumbing ---------------------------------------------------------
    // Nothing is announced for the first few seconds. Everything here reports
    // a CHANGE, and at startup every watcher reports its current state once -
    // which is not a change the user made and must not look like one.
    property bool armed: false

    Timer {
        interval: 5000
        running: true
        onTriggered: root.armed = true
    }

    Process { id: send }

    // A slot id per kind, so a second update check replaces the first instead
    // of stacking behind it.
    function notify(slot: string, app: string, summary: string, body: string): void {
        if (!root.armed)
            return;

        send.running = false;
        send.command = ["notify-send",
            "-a", app,
            "-h", `string:x-canonical-private-synchronous:dynisle-${slot}`,
            summary, body];
        send.running = true;
    }

    // ---- devices ----------------------------------------------------------
    // udevadm runs fine as a normal user. `--property` is what carries the
    // model name; without it the event only names a sysfs path, which is not
    // something worth putting on screen.
    property var pending: ({})

    Process {
        running: true
        command: ["udevadm", "monitor", "--udev", "--property",
                  "--subsystem-match=usb", "--subsystem-match=block"]

        // PROVEN, by logging every line the parser saw: it received udevadm's
        // two header lines and NOT the blank line after them. Quickshell's
        // SplitParser drops empty segments, and udev separates event blocks
        // with exactly that - so the blank-line flush this used to rely on had
        // never once fired, and no USB event was ever completed.
        //
        // Two boundaries that do arrive: a line with no "=" is a new event's
        // header (`UDEV [123.4] add /devices/... (usb)`), and a short silence
        // means the last block is finished.
        stdout: SplitParser {
            onRead: line => {
                const text = line.trim();
                if (text.length === 0)
                    return;

                const eq = text.indexOf("=");
                if (eq <= 0) {
                    root.flushDevice();
                    return;
                }

                root.pending[text.slice(0, eq)] = text.slice(eq + 1);
                settle.restart();
            }
        }
    }

    // The last block of a burst has no header after it to close it.
    Timer {
        id: settle

        interval: 150
        onTriggered: root.flushDevice()
    }

    function flushDevice(): void {
        const p = root.pending;
        root.pending = ({});

        // One plug produces an event for the device AND for every interface it
        // exposes. Only the device itself is worth a notification.
        if (p["DEVTYPE"] !== "usb_device" && p["DEVTYPE"] !== "disk")
            return;

        const action = p["ACTION"] ?? "";
        if (action !== "add" && action !== "remove")
            return;

        // Hubs only. The old test here rejected anything with no `ID_MODEL` and
        // no `ID_BUS`, on the assumption that only internal hubs lack them -
        // and that is what silently swallowed real plugs: the log showed an
        // event reaching this line and being thrown out as "hub/root". Real
        // devices DO carry both (checked with `udevadm info`), so whatever the
        // user plugs in does not always. Class 09 is the USB hub class, and it
        // is the only honest way to recognise one.
        const interfaces = p["ID_USB_INTERFACES"] ?? "";
        if ((p["DRIVER"] ?? "") === "hub" || interfaces.indexOf(":09") >= 0)
            return;

        const name = p["ID_MODEL_FROM_DATABASE"] ?? p["ID_MODEL"]
            ?? p["ID_VENDOR_FROM_DATABASE"] ?? p["ID_VENDOR"]
            ?? p["ID_SERIAL_SHORT"] ?? "";
        const label = name.replace(/_/g, " ").trim();

        root.notify("device", "Devices",
            action === "add" ? "USB device connected" : "USB device disconnected",
            label.length > 0 ? label : "USB");
    }

    // ---- pacman updates ---------------------------------------------------
    // `checkupdates` syncs its own temporary database, so it never touches the
    // real pacman lock and never needs root. It took 6.7s here, which is why it
    // runs on a timer and not on demand.
    property int updateCount: 0

    Process {
        id: checkUpdates

        command: ["checkupdates"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                const count = lines.length;
                root.updateCount = count;

                if (count === 0) {
                    root.notify("updates", "Updates", "You're up to date", "");
                    return;
                }

                root.notify("updates", "Updates",
                    count === 1 ? "1 update available" : `${count} updates available`,
                    "Run sudo pacman -Syu to install.");
            }
        }
    }

    // Not the instant the shell starts: logging in is the worst moment to be
    // told about 142 packages, and the shell has better things to do first.
    Timer {
        interval: 90000
        running: true
        onTriggered: checkUpdates.running = true
    }

    // Once per launch, and that is the whole schedule. A repeating check said
    // the same sentence every few hours, which is spam, not information - if
    // you want a fresh answer, restart the shell.
}
