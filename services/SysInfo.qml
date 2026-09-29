pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory and temperature - every one of them read straight out of a file
// the kernel already keeps, so this costs NO processes at all. The single
// exception runs once at startup, to find out which thermal zone is which.
//
// Sampled only while something is watching (the control centre being open).
// Reading four small files a second is nothing, but doing it forever for a
// panel nobody is looking at is still waste - the same rule Network follows.
Singleton {
    id: root

    property bool watching: false

    // ---- CPU --------------------------------------------------------------
    // A percentage cannot come from one reading: /proc/stat counts time SPENT,
    // so it has to be differenced against the previous sample.
    property real cpu: 0

    property real lastBusy: -1
    property real lastTotal: -1

    FileView {
        id: stat

        path: "/proc/stat"
        printErrors: false

        onLoaded: {
            const line = stat.text().split("\n")[0];
            const n = line.trim().split(/\s+/).slice(1).map(Number);
            if (n.length < 5)
                return;

            const total = n.reduce((a, b) => a + b, 0);
            // idle + iowait: the machine is doing nothing useful in both.
            const idle = n[3] + n[4];
            const busy = total - idle;

            if (root.lastTotal >= 0 && total > root.lastTotal)
                root.cpu = (busy - root.lastBusy) / (total - root.lastTotal);

            root.lastBusy = busy;
            root.lastTotal = total;
        }
    }

    // ---- memory -----------------------------------------------------------
    property real memTotal: 0      // bytes
    property real memUsed: 0
    property real swapTotal: 0
    property real swapUsed: 0

    readonly property real memFraction: root.memTotal > 0 ? root.memUsed / root.memTotal : 0
    readonly property real swapFraction: root.swapTotal > 0 ? root.swapUsed / root.swapTotal : 0

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        printErrors: false

        onLoaded: {
            const kb = {};
            for (const line of meminfo.text().split("\n")) {
                const m = line.match(/^(\w+):\s+(\d+)/);
                if (m)
                    kb[m[1]] = parseInt(m[2]) * 1024;
            }

            root.memTotal = kb["MemTotal"] ?? 0;
            // MemAvailable, not MemFree: reclaimable cache is not "used" in any
            // sense that matters to someone about to open another window. This
            // is the same figure `free -h` prints as available.
            root.memUsed = root.memTotal - (kb["MemAvailable"] ?? 0);
            root.swapTotal = kb["SwapTotal"] ?? 0;
            root.swapUsed = root.swapTotal - (kb["SwapFree"] ?? 0);
        }
    }

    // ---- temperature ------------------------------------------------------
    // There are no hwmon sensors on this machine (coretemp is not loaded), so
    // the thermal zones are the only source. Their NUMBERING is not stable
    // across boots, so the zone is resolved by type once, at startup.
    property string tempPath: ""
    property real temperature: 0

    Process {
        running: true
        command: ["sh", "-c",
            "for z in /sys/class/thermal/thermal_zone*; do " +
            "[ \"$(cat $z/type 2>/dev/null)\" = x86_pkg_temp ] && { echo $z/temp; exit 0; }; done; " +
            "echo /sys/class/thermal/thermal_zone0/temp"]

        stdout: StdioCollector {
            onStreamFinished: root.tempPath = text.trim()
        }
    }

    FileView {
        id: thermal

        path: root.tempPath
        printErrors: false

        // Millidegrees.
        onLoaded: root.temperature = (parseInt(thermal.text()) || 0) / 1000
    }

    // ---- sampling ---------------------------------------------------------
    Timer {
        interval: 1000
        running: root.watching
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            stat.reload();
            meminfo.reload();
            if (root.tempPath.length > 0)
                thermal.reload();
        }
    }

    // A percentage needs two samples, so the first tick after opening can only
    // produce a zero. Clearing the baseline on close means the next open starts
    // fresh rather than differencing against a reading from minutes ago.
    onWatchingChanged: {
        if (!root.watching) {
            root.lastBusy = -1;
            root.lastTotal = -1;
        }
    }

    function gib(bytes: real): string {
        return (bytes / 1073741824).toFixed(1);
    }
}
