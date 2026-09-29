pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Screenshots go to the CLIPBOARD and nowhere else - no folder is created. Two
// short-lived files live in XDG_RUNTIME_DIR (RAM, cleared at logout) per
// capture; the previous set is deleted each time.
//
//   SHIFT + Print   FREEZES the screen, then you drag a region out of the
//                   frozen picture. Freezing is the point: a menu that only
//                   exists while a key is held, a tooltip, an animation
//                   mid-frame - none of that survives long enough to be
//                   selected on a live screen.
//   SUPER + Print   the whole screen.
//
// slurp is gone. Once the screen is frozen the selection is just a drag over a
// still image, and doing it here rather than in another process is what makes
// the rounded selection, Escape, and a crosshair that disappears when it should
// all possible - slurp offers none of the three.
//
// Load-bearing details found the hard way (vault/notes.md 49a-49g):
//  - `grim -l 0` skips PNG compression and takes 37ms instead of 642ms. For a
//    freeze that has to feel instant, that difference is the whole feature.
//  - The pipeline is launched with `Quickshell.execDetached`, NOT `Process`.
//  - Every capture uses UNIQUE filenames, or the poll reads the previous
//    capture's marker before the shell has deleted it.
Singleton {
    id: root

    property bool busy: false

    // Geometry first, picture second: the flight starts as soon as the area is
    // known and the encoding happens behind it.
    signal started(int x, int y, int w, int h)
    signal copied()

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") ?? "/tmp"

    property string token: ""
    property string lastToken: ""

    readonly property string freezePath: `${root.runtimeDir}/dynisle-${root.token}.freeze.png`
    readonly property string shotPath: `${root.runtimeDir}/dynisle-${root.token}.png`
    readonly property string frozenPath: `${root.runtimeDir}/dynisle-${root.token}.frozen`
    readonly property string readyPath: `${root.runtimeDir}/dynisle-${root.token}.ready`

    // ---- selection state, read by ShotLayer -------------------------------
    // The frozen picture. Both paths take one: a region is chosen out of it,
    // and a full screen IS it - which also gives the flight something real to
    // carry without waiting for anything to be encoded.
    property string freezeImage: ""

    // Only the region path puts a chooser on screen. Kept separate from the
    // image, or a full-screen capture would drop an interactive overlay over
    // the machine.
    property bool selecting: false

    // Where the pointer was when the screen froze. The chooser draws its own
    // crosshair, and a drawn one has to START somewhere: a surface mapping
    // under a stationary pointer does not reliably produce a position, so
    // without this there was simply no cursor until the mouse was moved.
    property real cursorX: 0
    property real cursorY: 0

    // ---- region -----------------------------------------------------------
    function region(): void {
        // Pressing the shortcut again while choosing means "never mind", which
        // is the other half of what Escape does.
        if (root.selecting) {
            root.cancel();
            return;
        }

        root.reset();
        root.busy = true;
        root.pendingFull = false;

        Quickshell.execDetached(["sh", "-c",
            root.sweep() +
            `grim -l 0 '${root.freezePath}' && ` +
            `hyprctl cursorpos > '${root.frozenPath}'`]);

        root.elapsed = 0;
        root.waitingFor = "frozen";
        poll.restart();
    }

    // Called by ShotLayer once a rectangle has been dragged out of the frozen
    // picture. The crop comes from the FROZEN file, not the live screen - that
    // is what makes the capture the moment the key was pressed.
    function takeRegion(x: int, y: int, w: int, h: int): void {
        if (w < 2 || h < 2) {
            root.cancel();
            return;
        }

        // The flight can begin immediately: ShotLayer already has the frozen
        // image and can show the selected part of it without waiting for a
        // single byte to be written.
        root.selecting = false;
        root.started(x, y, w, h);

        Quickshell.execDetached(["sh", "-c",
            `magick '${root.freezePath}' -crop ${w}x${h}+${x}+${y} +repage '${root.shotPath}' && ` +
            `wl-copy -t image/png < '${root.shotPath}' && ` +
            `printf 1 > '${root.readyPath}'`]);

        root.elapsed = 0;
        root.waitingFor = "ready";
        poll.restart();
    }

    function cancel(): void {
        root.selecting = false;
        root.freezeImage = "";
        poll.stop();
        root.busy = false;
    }

    // ---- whole screen -----------------------------------------------------
    // The same 37ms freeze, then recompressed rather than captured twice: two
    // grims would be two different moments, and the uncompressed one is 3MB to
    // hand to the clipboard.
    property bool pendingFull: false

    function full(): void {
        if (root.selecting)
            root.cancel();

        root.reset();
        root.busy = true;
        root.pendingFull = true;

        Quickshell.execDetached(["sh", "-c",
            root.sweep() +
            `grim -l 0 '${root.freezePath}' && printf 1 > '${root.frozenPath}' && ` +
            `magick '${root.freezePath}' '${root.shotPath}' && ` +
            `wl-copy -t image/png < '${root.shotPath}' && ` +
            `printf 1 > '${root.readyPath}'`]);

        root.elapsed = 0;
        root.waitingFor = "frozen";
        poll.restart();
    }

    function reset(): void {
        poll.stop();
        root.selecting = false;
        root.freezeImage = "";
        root.lastToken = root.token;
        root.token = `shot-${Date.now()}`;
    }

    function sweep(): string {
        return root.lastToken.length > 0
            ? `rm -f '${root.runtimeDir}/dynisle-${root.lastToken}.'*; ` : "";
    }

    // ---- waiting for the markers ------------------------------------------
    property int elapsed: 0
    property string waitingFor: ""

    Timer {
        id: poll

        // Fast on purpose: it re-reads a handful of bytes out of RAM.
        interval: 30
        repeat: true

        onTriggered: {
            root.elapsed += poll.interval;

            // Choosing a region is a human action; give it a minute, then stop
            // watching rather than polling forever.
            if (root.elapsed > 60000) {
                root.cancel();
                return;
            }

            if (root.waitingFor === "frozen")
                frozen.reload();
            else
                ready.reload();
        }
    }

    FileView {
        id: frozen

        path: root.frozenPath
        // The poll deliberately reads a file that is not there yet. Not an
        // error worth logging.
        printErrors: false

        onLoaded: {
            const text = frozen.text().trim();

            // The file is created before it is written, and a 30ms poll is fast
            // enough to read it empty. An empty read is not an answer.
            if (text.length === 0)
                return;

            // "915, 271" - the pointer position, written by hyprctl at freeze
            // time so the chooser's own crosshair starts in the right place.
            // ONLY the region path writes it; a full-screen capture has no
            // crosshair and writes a plain marker instead. Requiring the parse
            // for both is what silently killed SUPER+Print - the guard returned
            // early on a marker that read "1" and nothing ever happened.
            const at = text.split(",").map(v => parseInt(v.trim()));
            if (at.length === 2 && !isNaN(at[0]) && !isNaN(at[1])) {
                root.cursorX = at[0];
                root.cursorY = at[1];
            } else if (!root.pendingFull) {
                return;
            }

            root.freezeImage = `file://${root.freezePath}`;

            if (root.pendingFull) {
                // Nothing to choose - the whole screen is the shot, so it flies
                // straight away while the clipboard copy finishes behind it.
                const screen = Quickshell.screens[0];
                root.started(0, 0, screen?.width ?? 0, screen?.height ?? 0);
                root.waitingFor = "ready";
                return;
            }

            poll.stop();
            root.selecting = true;
        }
    }

    FileView {
        id: ready

        path: root.readyPath
        printErrors: false

        onLoaded: {
            poll.stop();
            root.busy = false;
            root.copied();
        }
    }
}
