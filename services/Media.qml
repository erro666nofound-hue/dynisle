pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The one source of "what is playing" for the whole shell.
//
// Follows the same convention as DateTime.qml: pragma Singleton, a Singleton
// root, and NO import of qs.modules.* - services expose state, modules render
// it (vault/07-architecture.md).
Singleton {
    id: root

    // playerctld mirrors whatever other players are on the bus, so leaving it
    // in makes every track show up twice. end4-pC filters it out the same way.
    readonly property list<MprisPlayer> players: Mpris.players.values.filter(p =>
        !(p.dbusName ?? "").startsWith("org.mpris.MediaPlayer2.playerctld"))

    // Prefer something actually playing; otherwise fall back to the first
    // player that merely exists, so a paused track still shows.
    readonly property MprisPlayer active: players.find(p => p.isPlaying) ?? players[0] ?? null

    readonly property bool hasPlayer: root.active !== null
    // Real-world metadata is not always printable: the track playing during
    // UT-07 testing had a title made entirely of U+3164 HANGUL FILLER, which
    // renders as a row of tofu boxes. Anything that leaves no visible glyphs is
    // treated as absent and falls back to the player's own name.
    readonly property string title: {
        const raw = root.active?.trackTitle ?? "";
        const visible = raw.replace(/[\u3164\u200b-\u200d\u2800\ufeff\s]/g, "");
        return visible.length > 0 ? raw : (root.active?.identity ?? "");
    }
    readonly property string artist: root.active?.trackArtist ?? ""
    readonly property string artUrl: root.active?.trackArtUrl ?? ""
    readonly property bool isPlaying: root.active?.isPlaying ?? false

    // Every player advertises what it supports; calling an unsupported action
    // is a no-op at best, so the UI greys the button out instead.
    readonly property bool canToggle: root.active?.canTogglePlaying ?? false
    readonly property bool canGoNext: root.active?.canGoNext ?? false
    readonly property bool canGoPrevious: root.active?.canGoPrevious ?? false

    function togglePlaying(): void {
        if (root.canToggle)
            root.active.togglePlaying();
    }

    function next(): void {
        if (root.canGoNext)
            root.active.next();
    }

    function previous(): void {
        if (root.canGoPrevious)
            root.active.previous();
    }
}
