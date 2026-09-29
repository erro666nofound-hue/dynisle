pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Battery and power profile. Both come from Quickshell directly; only
// `PowerProfiles.profile` is writable, everything on the device is read-only.
Singleton {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: root.battery?.isLaptopBattery ?? false
    // UPower reports this as a FRACTION, not a percentage - reading it as one
    // showed a half-full battery as 1%.
    readonly property real percentage: (root.battery?.percentage ?? 0) * 100
    readonly property bool charging: root.battery?.state === UPowerDeviceState.Charging

    // UPower reports seconds; the panel wants something a person can read.
    readonly property string timeRemaining: {
        const secs = root.charging ? (root.battery?.timeToFull ?? 0)
                                   : (root.battery?.timeToEmpty ?? 0);
        if (secs <= 0)
            return "";

        const mins = Math.round(secs / 60);
        if (mins < 60)
            return `${mins} min ${root.charging ? "to full" : "left"}`;

        const h = Math.floor(mins / 60);
        const m = mins % 60;
        return `${h}h ${m}m ${root.charging ? "to full" : "left"}`;
    }

    // ---- power plans ------------------------------------------------------
    // NOT PowerProfiles. Measured on this machine, setting a PPD profile does
    // nothing at all: the CPU is an i5-5200U (Broadwell) with no HWP, so
    // intel_pstate never exposes an EPP knob and PPD has nothing to write -
    // governor, EPP and max frequency came back identical for all three
    // profiles (vault/notes.md fact 59).
    //
    // What does work is the governor and the frequency ceiling, so the plan is
    // read from the governor - the truth, whoever set it - and written through
    // a small root helper.
    readonly property string helper: "/usr/local/bin/dynisle-powerplan"
    property bool helperReady: false

    property string governor: ""

    readonly property int profile: {
        if (root.governor === "powersave")
            return PowerProfile.PowerSaver;
        if (root.governor === "performance")
            return PowerProfile.Performance;
        return PowerProfile.Balanced;
    }

    // The control is worth showing only if it can actually do something.
    readonly property bool hasPerformance: root.helperReady

    FileView {
        id: governorFile

        path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
        watchChanges: true
        printErrors: false

        onFileChanged: governorFile.reload()
        onLoaded: root.governor = governorFile.text().trim()
    }

    FileView {
        id: helperFile

        path: root.helper
        printErrors: false

        onLoaded: root.helperReady = true
    }

    Process { id: apply }

    function setProfile(p: int): void {
        if (!root.helperReady)
            return;

        const plan = p === PowerProfile.PowerSaver ? "saver"
            : (p === PowerProfile.Performance ? "performance" : "balanced");

        apply.running = false;
        // `--disable-internal-agent`: if the polkit rule is ever wrong, this
        // FAILS rather than sitting there waiting for a password dialog. A
        // hung pkexec is worse than a no-op - repeated prompts trip
        // pam_faillock and lock the account out of sudo entirely.
        apply.command = ["pkexec", "--disable-internal-agent", root.helper, plan];
        apply.running = true;
    }
}
