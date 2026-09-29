pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Audio levels from `cava`, one value per bar, normalised to 0..1.
//
// Same service convention as DateTime/Media: Singleton root, no qs.modules.*
// import. The cava config lives in config/cava.conf and is grounded in
// end4-pC's known-working raw_output_config.txt.
Singleton {
    id: root

    // Must match `bars` in config/cava.conf. The border around the album art
    // is built from exactly this many bars, 14 per side.
    readonly property int barCount: 56

    property var values: new Array(root.barCount).fill(0)

    Process {
        id: proc

        running: true
        command: ["cava", "-p", Quickshell.shellPath("config/cava.conf")]

        stdout: SplitParser {
            // cava emits one frame per line: 56 values, semicolon separated.
            splitMarker: "\n"

            onRead: data => {
                const parts = data.split(";");
                const out = new Array(root.barCount);
                for (let i = 0; i < root.barCount; i++) {
                    // ascii_max_range is 1000; clamp because autosens can
                    // briefly overshoot after a volume change.
                    const v = parseInt(parts[i]);
                    out[i] = isNaN(v) ? 0 : Math.min(1, v / 1000);
                }
                root.values = out;
            }
        }
    }
}
