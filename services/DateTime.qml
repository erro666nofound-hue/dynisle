pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// The single source of clock/date state for the whole shell.
//
// Convention every service in this folder follows:
//   - pragma Singleton + a Singleton root, so it is used by name (DateTime.time)
//   - it NEVER imports qs.modules.* — services expose state, modules render it
//     (vault/07-architecture.md). Format strings therefore live here until a
//     real Config singleton exists.
Singleton {
    id: root

    // Minutes, not Seconds. Nothing in the UI shows seconds, and Seconds would
    // wake the clock and repaint the island 60x more often for no visible gain.
    readonly property var clock: SystemClock {
        precision: SystemClock.Minutes
    }

    readonly property date now: root.clock.date

    // 12-hour with AM/PM, by request. "h" gives no leading zero ("3:57 PM"),
    // and "AP" forces uppercase AM/PM independent of locale.
    // `time24` stays available for anything that wants an unambiguous clock:
    // "HH" is always 24-hour, whereas a bare "hh" silently flips to 12-hour as
    // soon as the format string carries AM/PM.
    readonly property string time: Qt.formatDateTime(root.now, "h:mm AP")
    readonly property string time24: Qt.formatDateTime(root.now, "HH:mm")
    readonly property string shortDate: Qt.formatDateTime(root.now, "ddd d MMM")
    readonly property string longDate: Qt.formatDateTime(root.now, "dddd, d MMMM yyyy")
}
