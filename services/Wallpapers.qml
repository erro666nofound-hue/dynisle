pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// The wallpaper, and the colours that come out of it.
//
// FOLDERS, not a list of individual pictures. A folder you already keep
// wallpapers in is the unit the user actually has; adding pictures one at a
// time made you re-do work the filesystem had already done. Several folders
// can be known at once and you move between them from the bar.
//
// Themes were built here briefly and removed - see `06-decisions.md`. Their
// per-picture library is what this replaces.
Singleton {
    id: root

    // Every folder the picker knows about.
    property var roots: []

    // The one being browsed.
    property string folder: ""

    // The picture on screen.
    property string current: ""

    // Where the palette comes from: "wallpaper" reads it out of the picture,
    // "fixed" builds it from one colour you chose. This was a per-theme setting
    // once; themes are gone and it belongs to the shell as a whole now.
    property string colourMode: "wallpaper"
    property string colourHex: "#7fd4dd"

    readonly property bool colourFixed: root.colourMode === "fixed"

    readonly property string folderName: {
        const parts = root.folder.split("/").filter(p => p.length > 0);
        return parts.length > 0 ? parts[parts.length - 1] : "No folder";
    }

    // Declarative, and no process: FolderListModel watches the directory
    // itself, so a picture dropped into the folder appears without a rescan.
    // The panel binds a Repeater straight to this.
    readonly property alias pictures: pics

    FolderListModel {
        id: pics

        folder: root.folder.length > 0 ? `file://${root.folder}` : ""
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
        caseSensitive: false
    }

    // ---- folders -----------------------------------------------------------
    Process {
        id: chooser

        stdout: StdioCollector {
            onStreamFinished: {
                // One absolute path per line, and nothing at all if cancelled.
                const picked = text.trim().split("\n")
                    .map(p => p.trim().replace(/\/$/, ""))
                    .filter(p => p.length > 0);

                if (picked.length === 0)
                    return;

                const have = root.roots.slice();
                for (const p of picked) {
                    if (have.indexOf(p) < 0)
                        have.push(p);
                }

                root.roots = have;
                root.folder = picked[picked.length - 1];
                root.save();
            }
        }
    }

    // The one dialog in the whole shell. Everything else happens in the bar,
    // but this is browsing a filesystem, and rebuilding a directory tree inside
    // a 44px bar would be worse than the dialog.
    //
    // It goes through the XDG portal, so it is literally the dialog the browser
    // opens for a file upload - decorated, rounded and themed by the toolkit.
    // `yad` was here first and could never match it: with no header bar GTK
    // draws it square and titleless. custom/rules.lua floats it, because ours
    // has no parent window to be a modal of.
    function addFolder(): void {
        chooser.running = false;
        chooser.command = [Quickshell.shellPath("scripts/pick-folder")];
        chooser.running = true;
    }

    function setFolder(path: string): void {
        root.folder = path;
        root.save();
    }

    // Forgetting a folder deletes nothing on disk. If it was the one being
    // browsed, fall back to another rather than showing an empty grid with no
    // way to explain itself.
    function removeFolder(path: string): void {
        root.roots = root.roots.filter(r => r !== path);

        if (root.folder === path)
            root.folder = root.roots.length > 0 ? root.roots[0] : "";

        root.save();
    }

    // ---- applying ----------------------------------------------------------
    Process { id: recolourProc }

    // With no picture there is nothing to read a colour from, so the palette is
    // left exactly as it is rather than reset to something arbitrary.
    function setColourMode(mode: string): void {
        root.colourMode = mode;
        root.save();
        root.recolour();
    }

    // matugen runs ONCE, here, on commit - not on every frame of a drag, which
    // is what `Theme.previewAccent` is for.
    function setColour(hex: string): void {
        root.colourHex = hex;
        root.colourMode = "fixed";
        root.save();
        root.recolour();
    }

    function recolour(): void {
        // A fixed colour still works with no wallpaper at all; reading one out
        // of a picture obviously does not.
        if (!root.colourFixed && root.current.length === 0)
            return;

        const source = root.colourFixed
            // `scheme-fidelity`, not matugen's default `scheme-tonal-spot`.
            // tonal-spot forces one fixed colourfulness on every seed, so
            // MEASURED: black came out PINK (#ffb1c8) and grey and white came
            // out CYAN (#82d3e0). fidelity keeps what was picked - black gives a
            // black-and-white palette, grey a grey one, red a red one.
            ? `matugen color hex '${root.colourHex}' -t scheme-fidelity`
            : `matugen image '${root.current}' --prefer saturation`;

        // The SIGUSR1 is what makes kitty follow: its config includes the file
        // matugen writes, but a running kitty only reads it at startup.
        // The lock screen's background is baked HERE, at the one moment when
        // spending two seconds of CPU costs nothing. Doing it at lock time
        // instead meant hyprlock blurring a full-size image inside the suspend
        // window, which wedged the machine (notes.md fact 126).
        // The fastfetch black hole is redrawn in the new colours too (~0.2s).
        recolourProc.running = false;
        recolourProc.command = ["sh", "-c",
            `${source}; `
            + `pkill -USR1 -x kitty || true; `
            + `python3 '${Quickshell.shellPath("scripts/blackhole.py")}' || true; `
            + (root.current.length > 0
                ? `'${Quickshell.shellPath("scripts/lock-wallpaper")}' '${root.current}' || true` : "true")];
        recolourProc.running = true;
    }

    function apply(path: string): void {
        root.current = path;
        root.save();
        root.recolour();
    }

    function clearWallpaper(): void {
        root.current = "";
        root.save();
    }

    // ---- persistence -------------------------------------------------------
    // ONE file and ONE reader. Two views assigning the same property in an
    // order neither controlled is what wiped this state once (notes.md fact
    // 81), so the themes file is read once, for what it can still give, and
    // never again.
    FileView {
        id: state

        path: Quickshell.shellPath("config/wallpaper.json")
        watchChanges: true
        printErrors: false

        onFileChanged: state.reload()
        onLoaded: {
            try {
                const saved = JSON.parse(state.text());
                root.roots = saved.roots ?? [];
                root.folder = saved.folder ?? "";
                root.current = saved.current ?? "";
                root.colourMode = saved.colourMode ?? "wallpaper";
                root.colourHex = saved.colourHex ?? "#7fd4dd";
                root.loaded = true;
            } catch (e) {
                // A half-saved file is normal - the watcher re-reads it. It is
                // still said out loud, because a silent catch here hid a real
                // fault: the load threw, nothing was applied, and the only
                // symptom was state that quietly did not change.
                console.warn(`Wallpapers: could not read wallpaper.json - ${e}`);
            }
        }

        onLoadFailed: legacy.path = Quickshell.shellPath("config/themes.json")
    }

    property bool loaded: false

    // Only if there is no folder state at all: recover the folders the themes
    // era's individual pictures came from, so nothing the user gathered is
    // lost. NO path until it is needed - a FileView with one loads eagerly and
    // would race the reader above (notes.md fact 81).
    FileView {
        id: legacy

        path: ""
        printErrors: false

        onLoaded: {
            if (root.loaded)
                return;

            let old;
            try {
                old = JSON.parse(legacy.text());
            } catch (e) {
                // Nothing to recover from - and crucially nothing is saved
                // either. A failed read must never write over good state.
                return;
            }

            root.loaded = true;
            root.current = old.wallpaper ?? "";

            const folders = [];
            for (const p of (old.library ?? [])) {
                const dir = p.slice(0, p.lastIndexOf("/"));
                if (dir.length > 0 && folders.indexOf(dir) < 0)
                    folders.push(dir);
            }

            root.roots = folders;
            root.folder = folders.length > 0 ? folders[0] : "";
            root.save();
        }
    }

    function save(): void {
        state.setText(JSON.stringify({
            roots: root.roots,
            folder: root.folder,
            current: root.current,
            colourMode: root.colourMode,
            colourHex: root.colourHex
        }, null, 2) + "\n");
    }
}
