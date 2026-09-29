pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import Quickshell.Io

// App search over Quickshell's own DesktopEntries - no .desktop scanner of our
// own, and no vendored fuzzy-search library.
//
// Same service convention as the others: Singleton root, no qs.modules.* import.
Singleton {
    id: root

    property string query: ""
    property int selected: 0

    readonly property int maxResults: 10

    // `noDisplay` entries are the ones that ask not to be listed. Deduped on
    // exec+name because this Quickshell build's DesktopEntry has no `id`
    // property - end4-pC dedupes on `app.id`, which would silently be
    // `undefined` here and collapse the whole list to one entry.
    readonly property var apps: Array.from(DesktopEntries.applications.values)
        .filter(a => !a.noDisplay)
        .filter((a, i, self) => i === self.findIndex(b =>
            b.execString === a.execString && b.name === a.name))

    // Apps pinned in config/pinned.json, matched by their display name. Edited
    // by hand; the file is watched, so a save shows up without a restart.
    property var pinnedNames: []

    readonly property var pinned: root.pinnedNames
        .map(n => root.apps.find(a => a.name === n))
        .filter(a => a !== undefined)

    FileView {
        id: pinnedFile

        path: Quickshell.shellPath("config/pinned.json")
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            try {
                root.pinnedNames = JSON.parse(text());
            } catch (e) {
                // A half-saved file is normal while editing; keep the last good
                // list rather than emptying the row.
                console.warn("dynisle: pinned.json is not valid JSON yet");
            }
        }
    }

    // What the results panel renders: matching apps first, then the two
    // fallbacks the reference always offers, so a query that matches nothing
    // installed can still do something.
    readonly property var rows: {
        const q = root.query.trim();
        if (q.length === 0)
            return [];

        const out = root.results.map(entry => ({ kind: "app", entry: entry, value: entry.name }));
        out.push({ kind: "run", entry: null, value: q });
        out.push({ kind: "web", entry: null, value: q });
        return out;
    }

    readonly property var results: {
        const q = root.query.trim().toLowerCase();

        if (q.length === 0)
            return root.apps
                .slice()
                .sort((a, b) => a.name.localeCompare(b.name))
                .slice(0, root.maxResults);

        return root.apps
            .map(entry => ({ entry: entry, score: root.score(entry, q) }))
            .filter(hit => hit.score >= 0)
            .sort((a, b) => b.score - a.score)
            .slice(0, root.maxResults)
            .map(hit => hit.entry);
    }

    onRowsChanged: root.selected = 0

    // Ranked by how deliberate the match looks, best first:
    // a prefix beats a word start, which beats initials, which beats a
    // substring, which beats a keyword hit, which beats a loose subsequence.
    // Shorter names win ties, so "Files" outranks "Files (Nautilus) Settings".
    function score(entry, q: string): real {
        const name = (entry.name ?? "").toLowerCase();
        if (name.length === 0)
            return -1;

        if (name.startsWith(q))
            return 1000 - name.length;

        const words = name.split(/[\s\-_.]+/).filter(w => w.length > 0);

        if (words.some(w => w.startsWith(q)))
            return 800 - name.length;

        // "fdev" -> "Firefox Developer Edition"
        if (words.map(w => w.charAt(0)).join("").startsWith(q))
            return 700 - name.length;

        const at = name.indexOf(q);
        if (at >= 0)
            return 600 - at - name.length * 0.1;

        // categories and keywords are plain strings on this build, not lists.
        const extra = ((entry.genericName ?? "") + " " + (entry.keywords ?? "")
            + " " + (entry.comment ?? "")).toLowerCase();
        if (extra.includes(q))
            return 400;

        // Loose subsequence, e.g. "frfx" -> "firefox".
        let i = 0;
        for (const ch of name) {
            if (ch === q.charAt(i))
                i++;
        }
        return i === q.length ? 200 - name.length * 0.1 : -1;
    }

    // The name with the matched characters wrapped in <b>, for StyledText.
    // Greedy first-occurrence subsequence, the same walk the score uses, so
    // what is emphasised is exactly what earned the match: "vc" over
    // "VS Code" bolds the V and the C.
    function highlight(name: string, q: string): string {
        const esc = t => t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        const query = q.trim().toLowerCase();

        if (query.length === 0)
            return esc(name);

        const lower = name.toLowerCase();
        let out = "";
        let qi = 0;

        for (let i = 0; i < name.length; i++) {
            const ch = esc(name.charAt(i));

            if (qi < query.length && lower.charAt(i) === query.charAt(qi)) {
                out += "<b>" + ch + "</b>";
                qi++;
            } else {
                out += ch;
            }
        }

        return out;
    }

    // What the arrow keys walk. With nothing typed that is the pinned row, so
    // the launcher is usable from the keyboard the moment it opens instead of
    // only after typing something.
    readonly property var navRows: root.query.trim().length === 0
        ? root.pinned.map(entry => ({ kind: "app", entry: entry, value: entry.name }))
        : root.rows

    // Up and down on the PINNED grid jump a whole row; left and right step one
    // tile. They used to be the same thing, which made two of the four arrow
    // keys pointless.
    function moveRow(delta: int): void {
        if (root.query.trim().length > 0) {
            root.move(delta);
            return;
        }

        const n = root.navRows.length;
        if (n === 0)
            return;

        const next = root.selected + delta * Theme.launcherPerRow;
        // Clamped rather than wrapped: wrapping a row at a time lands somewhere
        // unrelated, which is disorienting on a grid.
        root.selected = Math.max(0, Math.min(n - 1, next));
    }

    function move(delta: int): void {
        const n = root.navRows.length;
        if (n === 0)
            return;

        // Wraps, so holding a direction never dead-ends.
        root.selected = (root.selected + delta % n + n) % n;
    }

    // With nothing pinned and nothing typed there is nothing to put in the
    // results surface, so Island.qml does not draw it at all - the launcher is
    // just the search field.
    readonly property bool showPanel: root.query.trim().length > 0
        || root.pinned.length > 0

    // No ceiling. The panel wraps pinned apps onto more rows and scrolls once
    // there are too many for its cap, so there is no reason to refuse a pin -
    // and the old limit of 8 made the row overflow the panel's own width,
    // which pushed the selection mark out past the rounded edge.
    readonly property bool canPin: true

    function isPinned(name: string): bool {
        return root.pinnedNames.indexOf(name) >= 0;
    }

    function togglePin(name: string): void {
        const next = root.pinnedNames.slice();
        const at = next.indexOf(name);

        if (at >= 0)
            next.splice(at, 1);
        else
            next.push(name);

        root.pinnedNames = next;
        // Written back immediately so a pin survives a restart. The FileView
        // watches the file, so this reload is harmless and keeps the two in
        // step if it is also edited by hand.
        pinnedFile.setText(JSON.stringify(next, null, 2) + "\n");
    }

    function launch(entry): void {
        if (entry)
            Quickshell.execDetached(entry.command);
    }

    // Runs whatever is selected: an app, a raw command, or a web search.
    function activate(): void {
        const row = root.navRows[root.selected];
        if (!row)
            return;

        if (row.kind === "app")
            root.launch(row.entry);
        else if (row.kind === "run")
            Quickshell.execDetached(["sh", "-c", row.value]);
        else
            Quickshell.execDetached(["xdg-open",
                "https://duckduckgo.com/?q=" + encodeURIComponent(row.value)]);
    }
}
