pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Wi-Fi through nmcli. There is no Quickshell network API, so this is the one
// service that really does shell out - but only to nmcli's `-t` terse mode,
// which is a stable colon-separated format meant for exactly this.
Singleton {
    id: root

    property bool enabled: true
    property string currentSsid: ""
    property var networks: []      // [{ ssid, signal, secure, saved, current }]
    property var savedNames: []
    property bool scanning: false

    // Which network we are in the middle of joining, and for how long. nmcli
    // returns before the association has settled, so without this the row went
    // from doing nothing at all to simply being connected.
    property string connectingTo: ""
    property int connectingFor: 0

    Timer {
        interval: 1000
        running: root.connectingTo.length > 0
        repeat: true
        onTriggered: {
            root.connectingFor += 1;

            // nmcli's own timeout is 90s; giving up sooner would leave the row
            // saying nothing while the attempt is still alive.
            if (root.connectingFor > 90)
                root.connectingTo = "";
        }
    }

    // The moment the link is really up, the attempt is over.
    onCurrentSsidChanged: {
        if (root.currentSsid.length > 0 && root.currentSsid === root.connectingTo)
            root.connectingTo = "";
    }

    function beginConnect(ssid: string): void {
        root.connectingTo = ssid;
        root.connectingFor = 0;
    }

    readonly property var known: root.networks
        .filter(n => n.saved)
        .sort((a, b) => b.signal - a.signal)

    readonly property var unknown: root.networks
        .filter(n => !n.saved)
        .sort((a, b) => b.signal - a.signal)

    // Rescanning costs a moment of radio time, so it only runs while something
    // is actually looking at the list.
    property bool watching: false
    onWatchingChanged: {
        if (root.watching) {
            root.refresh();
            root.rescan();
        }
    }

    Timer {
        interval: 10000
        running: root.watching
        repeat: true
        onTriggered: root.refresh()
    }

    // Separate from the listing, and much slower: this is the one that actually
    // makes the radio sweep the band.
    Timer {
        interval: 25000
        running: root.watching
        repeat: true
        onTriggered: root.rescan()
    }

    Component.onCompleted: root.refresh()

    // Never restarts a scan that is already in flight. Killing nmcli mid-stream
    // makes its StdioCollector finish with an empty or half-read buffer, and
    // that empty parse used to land last and blank the whole list - which is
    // what made the panel read "Not connected" while nmcli said otherwise.
    function refresh(): void {
        if (savedProc.running || scanProc.running)
            return;
        savedProc.running = true;
        radioProc.running = false;
        radioProc.running = true;
    }

    Process {
        id: radioProc

        command: ["nmcli", "-t", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.enabled = text.trim() === "enabled"
        }
    }

    // Saved connections are resolved first, because the scan below needs them
    // to split the list into known and unknown.
    Process {
        id: savedProc

        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedNames = text.split("\n")
                    .filter(l => l.includes("wireless"))
                    .map(l => l.split(":")[0])
                    .filter(n => n.length > 0);

                scanProc.running = true;
            }
        }
    }

    Process {
        id: scanProc

        // `--rescan no` is the whole point: nmcli's default is `auto`, which
        // makes the radio sweep the band when the cache is older than 30s and
        // takes 9.7 SECONDS to return (measured). The list would have sat empty
        // for that whole time every time it was opened. Reading the cache takes
        // 15ms, and the sweep is triggered separately below.
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY",
                  "device", "wifi", "list", "--rescan", "no"]

        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                // Collected during the loop and assigned after it: writing
                // straight to currentSsid would leave a stale name behind when
                // the link drops, because nothing in the scan says "none".
                let active = "";

                for (const line of text.split("\n")) {
                    // SSIDs may contain a colon, which nmcli escapes as "\:".
                    // Split by hand rather than with a lookbehind regex - QML's
                    // JS engine does not support lookbehind, and the handler
                    // died silently on it, leaving the list permanently empty.
                    const parts = [];
                    let field = "";
                    for (let i = 0; i < line.length; i++) {
                        const ch = line.charAt(i);
                        if (ch === "\\" && i + 1 < line.length) {
                            field += line.charAt(++i);
                        } else if (ch === ":") {
                            parts.push(field);
                            field = "";
                        } else {
                            field += ch;
                        }
                    }
                    parts.push(field);
                    if (parts.length < 4)
                        continue;

                    const ssid = parts[1];
                    if (ssid.length === 0 || seen[ssid])
                        continue;
                    seen[ssid] = true;

                    const current = parts[0].trim() === "*";
                    if (current)
                        active = ssid;

                    out.push({
                        ssid: ssid,
                        signal: parseInt(parts[2]) || 0,
                        secure: parts[3].trim().length > 0,
                        saved: root.savedNames.indexOf(ssid) >= 0,
                        current: current
                    });
                }

                root.networks = out;
                root.currentSsid = active;
            }
        }
    }

    Process {
        id: rescanProc

        command: ["nmcli", "device", "wifi", "rescan"]
        // The spinner in the header tracks THIS, not the listing: the listing
        // is instant, so a spinner on it would never be seen.
        onRunningChanged: root.scanning = rescanProc.running
        onExited: root.refresh()
    }

    // Asks the radio to sweep. nmcli errors out if a scan is already in flight,
    // which is harmless and deliberately ignored.
    function rescan(): void {
        if (rescanProc.running)
            return;
        rescanProc.running = true;
    }

    // nmcli writes the interesting part of a failure to stderr ("Secrets were
    // required, but not provided" for a wrong password), so it is kept: the
    // join sheet has no other way to know the password was rejected.
    property string lastError: ""

    Process {
        id: action

        stderr: StdioCollector {
            onStreamFinished: root.lastError = text.trim()
        }

        // nmcli exiting non-zero means the attempt is over and it failed -
        // leaving the row spinning would be a lie.
        onExited: exitCode => {
            if (exitCode !== 0)
                root.connectingTo = "";
        }
    }

    function run(args): void {
        root.lastError = "";
        action.running = false;
        action.command = args;
        action.running = true;
        // nmcli returns before the connection settles, so give it a moment
        // before asking what the state is now.
        settle.restart();
    }

    Timer {
        id: settle

        interval: 1200
        onTriggered: root.refresh()
    }

    function connectSaved(ssid: string): void {
        root.beginConnect(ssid);
        root.run(["nmcli", "connection", "up", "id", ssid]);
    }

    function connectNew(ssid: string, password: string): void {
        root.beginConnect(ssid);
        root.run(["nmcli", "device", "wifi", "connect", ssid, "password", password]);
    }

    function forget(ssid: string): void {
        root.run(["nmcli", "connection", "delete", "id", ssid]);
    }

    function setEnabled(on: bool): void {
        root.run(["nmcli", "radio", "wifi", on ? "on" : "off"]);
    }
}
