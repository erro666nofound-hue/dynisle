pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The freedesktop notification server. dynisle owns the bus name while it runs
// - if end4-pC or another shell is started too, only one of them gets it.
//
// The behaviour here is built from what this machine actually sends, harvested
// out of ~/user_scripts and the running battery unit rather than assumed:
// https://claude.ai/code/artifact/5e75b1b0-4290-4b05-b600-21ebc6ade253
Singleton {
    id: root

    // While this is on, notifications are still recorded but never shown.
    property bool doNotDisturb: false

    // The one currently being shown, or null.
    property var current: null

    readonly property var list: server.trackedNotifications.values

    signal arrived

    // Senders whose notifications are never worth a popup. The control centre
    // already shows the network, live and permanently, so a toast every time it
    // reconnects is the same fact told twice.
    //
    // They are still TRACKED - dropped from the screen, not from history.
    readonly property var muted: ["Network Architect"]

    // slot id -> the notification currently holding it. See `slotOf`.
    property var slots: ({})

    // How many arrived while an earlier popup was still on screen and were
    // therefore never read. NOT the size of history: that only ever grows, and
    // a "+37" that counts everything since login tells you nothing.
    property int pending: 0

    NotificationServer {
        id: server

        // Declared capabilities, so senders know what they can use.
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        // Both off, and honestly so: the popup draws neither, and telling a
        // sender otherwise would make it offer buttons that go nowhere.
        actionsSupported: false
        inlineReplySupported: false

        // Non-standard hints arrive ONLY if they are named here. Eight of the
        // local senders pass `x-canonical-private-synchronous`, so without this
        // line every volume keypress queued a new notification instead of
        // replacing the one on screen.
        extraHints: [
            "x-canonical-private-synchronous",
            "x-dunst-stack-tag",
            "value",
            "category",
            "image-path",
            "sound-name"
        ]

        onNotification: notification => {
            const slot = root.slotOf(notification);
            const clearing = root.isSlotClear(notification);
            const prev = slot.length > 0 ? root.slots[slot] : null;

            // A sender replacing its own slot is not a second notification -
            // it is the same one, updated. Nudging the volume five times must
            // not read as five missed messages.
            const replacingOnScreen = prev !== null && prev === root.current;

            if (slot.length > 0) {

                // Replaced by its own sender, so it did not expire and it did
                // not get dismissed by the user - it is simply superseded.
                if (prev && prev !== notification)
                    prev.dismiss();

                if (clearing) {
                    delete root.slots[slot];
                    if (root.current === prev || root.current === null)
                        root.current = null;
                    notification.dismiss();
                    return;
                }

                root.slots[slot] = notification;
            } else if (clearing) {
                notification.dismiss();
                return;
            }

            // `transient` means "do not keep this in history" - the volume OSD
            // says so, and it is right: nobody wants to scroll back through 40
            // volume steps.
            notification.tracked = !notification.transient;

            if (root.muted.indexOf(notification.appName ?? "") >= 0)
                return;

            if (root.doNotDisturb) {
                root.pending += 1;
                return;
            }

            if (root.current !== null && !replacingOnScreen)
                root.pending += 1;

            root.current = notification;
            root.arrived();
        }
    }

    // The synchronous-slot id, if the sender named one. Two spellings exist in
    // the wild and both are handled: mako/notify-send use the canonical name,
    // dunst uses its own.
    function slotOf(notification): string {
        const h = notification.hints ?? {};
        return h["x-canonical-private-synchronous"] ?? h["x-dunst-stack-tag"] ?? "";
    }

    // How these scripts release a slot: resend it empty with a 1 ms timeout.
    // Rendering that would flash a blank island for a frame.
    function isSlotClear(notification): bool {
        if (notification.expireTimeout === 1)
            return true;

        const summary = (notification.summary ?? "").trim();
        const body = (notification.body ?? "").trim();
        return summary.length === 0 && body.length === 0;
    }

    // Senders on this machine put an emoji or a Nerd Font glyph at the front of
    // the summary as a type marker - "⚡ Charging", "󰂚 Do Not Disturb". The
    // island draws its own icon, so the marker is redundant text.
    //
    // Done by codepoint rather than a regex: Vietnamese sits entirely below
    // U+2000, so everything at or above it that leads the string is a symbol,
    // an emoji, or private-use - and QML's engine has no \p{...} support to
    // lean on anyway (notes.md fact 34).
    function stripMarkers(text: string): string {
        let i = 0;
        while (i < text.length) {
            const c = text.codePointAt(i);
            if (c === 0x20 || c === 0x09 || c === 0xa0) {
                i += 1;
            } else if (c >= 0x2000) {
                i += c > 0xffff ? 2 : 1;
            } else {
                break;
            }
        }
        return text.slice(i);
    }

    // Rung 4 of the icon ladder: no image and no resolvable app icon, so the
    // glyph is guessed from the words. The table is ordered - the first match
    // wins, so the specific battery states have to sit above the generic
    // "battery", whose own app name is "Battery Monitor".
    readonly property var glyphTable: [
        // Removable storage sits FIRST so nothing below can shadow it, and the
        // "off" wordings come before their positive forms - "disconnected"
        // contains no substring the others match, but "unmounted" contains
        // "mounted" and would otherwise take the wrong glyph.
        ["usb device disconnected", "usb_off"],
        ["device disconnected", "usb_off"],
        ["unmounted", "usb_off"],
        ["ejected", "usb_off"],
        ["safe to remove", "usb_off"],
        ["usb", "usb"],
        ["device connected", "usb"],
        ["removable", "usb"],
        ["mounted", "usb"],

        ["fully charged", "battery_full_alt"],
        ["battery full", "battery_full_alt"],
        ["critical battery", "battery_alert"],
        ["battery empty", "battery_error"],
        ["battery low", "battery_low"],
        ["charging", "battery_charging_full"],
        ["unplugged", "power"],
        ["battery", "power"],
        ["muted", "volume_off"],
        ["volume", "volume_up"],
        ["microphone", "mic"],
        ["brightness", "light_mode"],
        ["layout", "keyboard_alt"],
        ["input method", "keyboard_alt"],
        ["keyboard", "keyboard_alt"],
        ["rotated", "screen_rotation"],
        ["do not disturb", "notifications_off"],
        ["bluetooth", "bluetooth"],
        ["network", "wifi"],
        ["wifi", "wifi"],
        ["wallpaper", "wallpaper"],
        ["favorites", "wallpaper"],
        ["hyprshade", "contrast"],
        ["screenshot", "screenshot_monitor"],
        ["record", "screen_record"],
        ["cooldown", "schedule"],
        ["copied", "content_copy"],
        ["listening", "record_voice_over"],
        ["transcri", "record_voice_over"],
        ["success", "check_circle"],
        ["failed", "error"],
        ["error", "error"],
        ["unable", "error"],
        ["couldn't", "error"],
        ["warning", "warning"],
        ["conversion", "movie"],
        ["lens", "image_search"],
        ["installed", "update"],
        ["update", "update"],
        ["reboot", "restart_alt"],
        ["restart", "restart_alt"],
        ["reloaded", "settings"],
        ["config", "settings"],
        ["music", "queue_music"],
        ["copying", "folder_copy"],
        ["message", "mail"],
        ["mail", "mail"]
    ]

    function glyphFor(summary: string, appName: string, critical: bool): string {
        // The app name is part of the haystack on purpose: "OSD",
        // "Network Architect" and "Google Lens" carry the type when the summary
        // is just a device name or a level.
        const hay = `${summary} ${appName}`.toLowerCase();

        for (const pair of root.glyphTable) {
            if (hay.includes(pair[0]))
                return pair[1];
        }

        return critical ? "priority_high" : "chat";
    }

    function dismiss(): void {
        root.current = null;
        root.pending = 0;
    }
}
