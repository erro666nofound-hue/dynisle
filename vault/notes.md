---
title: NOTES — read this first, every session
updated: 2026-09-02
---

# notes.md — read before anything else

This file exists because facts get established over many prompts/sessions and
then silently forgotten by a later session that never re-reads the full vault
closely enough to catch them. This is the digest: short, high-signal, "never
silently drop this" facts only. Full detail lives in the linked vault files —
go read those before acting, this file is a trigger to make you go look, not
a replacement for looking.

**Read order every session: this file → `00-README.md` → `05-session-log.md`
→ `06-decisions.md`, then whatever specific file is relevant to the task.**

## Never-drop facts

1. **Blur = felt, not seen.** Near-solid dark surface + real Hyprland
   compositor blur. NOT glassmorphism — the desktop must not read as visibly
   smeared/see-through behind the panel, blur should only add soft depth.
   **The hard constraint (verified live 2026-09-01):** the user's Hyprland
   config already applies `blur = true` + `ignore_alpha = 0.79` to
   `quickshell:.*`, which covers `quickshell:dynisle` — so **no new Hyprland
   config is needed, and the island's fill alpha MUST stay above 0.79** or
   blur switches off and it degrades into the exact see-through look the user
   hates. Working band is **0.85–0.90**; currently 0.88. Full detail:
   `04-technical-reference.md`.
   **The island's blur is PROVEN working (2026-09-01), don't re-investigate.**
   Controlled experiment: expanded the panel over a terminal, then rendered it
   at alpha **0.75** (below the 0.79 floor → blur off) and at **0.80** (above
   → blur on). At 0.75 the terminal text behind was fully legible; at 0.80 it
   was smeared into flat darkness. Screenshots in that session.
   **Why it still looks un-blurred when idle:** the pill sits over a patch of
   sky whose pixels have stddev < 1 and differ from their blurred version by at
   most 2/255 — there is literally nothing there to smear, and only 12% of it
   shows through anyway. The user asked about this and chose to keep 0.88.

2. **One island, top-center, no separate bar/dock/panel.** The island itself
   is the whole shell. Confirmed by 4 reference screenshots (see fact 4).
   Detail: `01-vision.md`, `06-decisions.md`.

2a. **The island is a BAR, not a floating overlay.** It *looks* floating
   (fact 2b) but it behaves like a bar: it reserves screen space
   (`ExclusionMode.Normal`) so tiled/maximised windows stop below it, and it
   **hides completely when its monitor's active workspace has a fullscreen
   client** (`Hyprland.monitorFor(screen).activeWorkspace.hasFullscreen`).
   The reserved zone is pinned to the **idle** height on purpose — when the
   island expands it must grow *over* the desktop, never push windows down.
   **Gap arithmetic (don't break it):** gap above = gap below = 7px, achieved
   by `exclusiveZone = idleHeight + screenGap - compositorGapsOut`, because
   Hyprland adds its own `gaps_out` (5) below the reserved zone. If `gaps_out`
   changes in `shellOverrides/main.lua`, change `Theme.compositorGapsOut` too.
   Detail: `06-decisions.md`.

2b. **Island shape = plain rounded rectangle, all 4 corners equal, FLOATING
   with a gap below the top screen edge.** The user explicitly rejected the
   flush-to-edge / flared-top-corner "notch" geometry after two iterations
   and chose the simple option. The reference screenshots show the flared
   flush look — **the user's spoken decision overrides the screenshots on
   this specific point.** Never reintroduce the flare/notch shape or a zero
   top margin unless asked. Detail: `06-decisions.md`.

3. **Theming = curated named color schemes** (catppuccin, gruvbox, kanagawa,
   nightfox, rose-pine, everforest, e-ink, etc.), not purely
   wallpaper-auto-extracted colors. Wallpapers appear paired with a specific
   scheme name. Detail: `01-vision.md`.

4. **Real reference screenshots exist** at
   `vault/assets/reference-screenshots/01-04*.png` — idle pill, expanded
   media player, theme picker, wallpaper picker. LOOK at them before building
   any UI piece, don't work from text description alone.

5. **Project name: `dynisle`.** Launch/test command: `qs -c dynisle` (run
   manually in a terminal during dev). Entry point: `shell.qml` at the
   project root, `ShellRoot` pattern — matches how `ii`/`end4-pC` are
   structured, verified on this machine.

6. **`~/.config/hypr/startup.conf` tries `exec-once = qs -c noctalia-shell`,
   but that package is NOT actually installed** (`pacman -Qs noctalia` → no
   match; `/etc/xdg/quickshell/` only contains `caelestia`, not
   `noctalia-shell`). Confirmed 2026-09-01. This means nothing was reliably
   rendering wallpaper/shell UI before this session touched anything — the
   "wallpaper lost" incident wasn't caused by dynisle testing, it was
   latent breakage. **Still never edit `startup.conf`** or assume any other
   shell is reliably running — check with `ps aux | grep "qs -c"` rather
   than trusting the hypr config's intent.
   No wallpaper daemon (`swww`/`hyprpaper`/`wpaperd`/`swaybg`) is installed
   either — wallpaper is only ever rendered by whichever quickshell config
   is actually running. Because of this, **dynisle now renders its own
   fullscreen background layer** (see fact 11) so the user always has a
   wallpaper regardless of what else is or isn't running.

7. **`ii` and `end4-pC` are reference-only.** Read them freely for real,
   working QML patterns (they're the grounding for how PanelWindow/blur/
   services actually work on this machine) — never modify them.

8. **Workflow the user requires** (detail: `08-roadmap.md`,
   `09-ultra-tasks.md`):
   - Work is split into small "Ultra Tasks" (UT), ordered so each one turns a
     hard problem into a small provable step, not split randomly.
   - After finishing a UT, stop and tell the user exactly what to run/look at
     to test it. Wait for their feedback before starting the next UT.
   - Never do a big uncheckpointed batch of work — that's the thing the user
     explicitly said produces "trash."

9. **Before starting any UT, go through this sequence** (the user asked for
   this explicitly, don't skip steps):
   1. Restate the actual end goal / what the user really wants from it.
   2. Re-read the relevant existing code (in `dynisle` and in `ii`/`end4-pC`
      for real working patterns) and the relevant vault files — don't rely on
      memory of what's there.
   3. Write a short plan.
   4. Self-critique that plan specifically for bugs/errors it would produce.
   5. Fix the plan.
   6. Then implement.

10. **Ground technical QML/Hyprland claims in real inspected code or fresh
    docs/web search — not training-data memory.** Quickshell moves fast and
    this user explicitly does not want hallucinated APIs. Verified example so
    far: `PanelWindow` with only `anchors.top: true` set (no left/right) —
    self-centers horizontally; make it `color: "transparent"` and put a
    shaped child `Rectangle` inside sized via `implicitWidth`/`implicitHeight`
    — this is how `end4-pC/ReloadPopup.qml` builds a small centered blurred
    popup, and is the base pattern for the island itself.

11. **dynisle pins the wallpaper to `/home/toast/Downloads/Clouds.png`** via
    its own `PanelWindow` (`WlrLayershell.layer: WlrLayer.Background`,
    fullscreen anchors, `Image` with `PreserveAspectCrop`) added directly in
    `shell.qml` alongside the island window. This is a deliberate pinned
    default per the user's explicit request ("always make this wallpaper
    turned on"), not yet the general wallpaper-picker feature (that's
    Phase 7, `08-roadmap.md`) — when that's built, it should replace this
    hardcoded path with the real picker/state, not duplicate it.
    Also updated `~/.cache/noctalia/wallpapers.json` to point at
    `Clouds.png` too (backed up the original first, same directory,
    timestamped `.bak-*`), in case noctalia-shell ever gets reinstalled.

12. **The user's `qs -c dynisle` is currently left running in the background**
    (started by Claude via `nohup ... & disown`, PID logged in
    `05-session-log.md`) specifically so the wallpaper stays up between
    testing rounds. If a future session needs to restart it after editing
    `shell.qml`, kill the old one first: `pkill -f "qs -c dynisle"`.

13-NEW. **dynisle's blur/opacity values live in
    `~/.config/hypr/custom/dynisle-blur.lua`, NOT in `shellOverrides/main.lua`.
    Never put them back in main.lua.** `hyprland.lua` requires the custom file
    **last**, after `hyprland.shellOverrides.main`, so it wins.
    **Why this exists:** `shellOverrides/main.lua` is regenerated by
    illogical-impulse. The user accidentally launched ii on 2026-09-02 and it
    reset `blur.size` to **1** (invisible blur) and `active_opacity` to **1**
    (no translucency for blur to act on) — which is almost certainly the real
    cause of the "blur works, then stops" mystery, not a stale blur cache.
    ii only rewrites the keys it manages; unknown lines survive.
    **Proof the fix holds:** main.lua still reads `blur.size = 1` while
    `hyprctl getoption` reports 8.
    Current authoritative values: `blur.size 8`, `passes 3`,
    `new_optimizations false`, `active_opacity 0.85`, `inactive_opacity 0.78`,
    `fullscreen_opacity 1.0`.
    **Residual risk:** if ii ever regenerates `hyprland.lua` itself, the final
    `require("custom.dynisle-blur")` disappears and blur breaks. Check that
    line first if blur dies again.
    Note `custom/rules.lua` and `custom/general.lua` load *before*
    shellOverrides and therefore cannot override it — that is why this needed a
    separate require rather than reusing an existing custom file.

19. **Terminals hide their own blur behind an OPAQUE-SURFACE declaration.
    This hit both foot and kitty; do not add Hyprland rules for either.**
    **First, the thing that wasted the most time: `SUPER + Return` does NOT open
    kitty.** `hyprland/variables.lua` sets
    `terminal = launch_first_available.sh 'foot' 'kitty -1' ...` and foot is
    installed, so the terminal the user actually sees is **foot**. A kitty
    window opened by hand blurred correctly while their Super+Enter terminal did
    not - because they are two different programs. Check
    `hyprctl clients -j` for the real class before debugging a terminal.
    **The mechanism:** at `alpha`/`background_opacity` = 1.0 (the default for
    both), the terminal declares its whole surface opaque to the compositor, so
    Hyprland skips blurring behind it; Hyprland's `active_opacity` then makes it
    see-through with UNBLURRED content underneath. Exactly "transparent but not
    blurred".
    **Fix, one line each, in the app's own config - not in Hyprland:**
    `alpha=0.95` under `[colors]` in `~/.config/foot/foot.ini`, and
    `background_opacity 0.95` in `~/.config/kitty/kitty.conf`. Just enough to
    drop the opaque declaration; Hyprland's global 0.85 still does the visible
    work. Backups: `foot.ini.bak-*`, `kitty.conf.bak-*`.
    **The user asked for all terminal special-casing to be deleted** - there are
    now no per-app window rules anywhere, and the stale `^kitty$`/`^foot$`
    `opacity 1.00` lines in `~/.config/hypr/windowrules.conf` were removed too
    (that whole file is **dead config** - only `.bak`/`.old` files source it;
    the live entry point is `hyprland.lua`).

20. **`fileManager` is nautilus, set in `~/.config/hypr/custom/variables.lua`.**
    Changed from dolphin on the user's request 2026-09-02. That custom file is
    the update-friendly override point: `hyprland/keybinds.lua` requires
    `hyprland.variables` and then `custom.variables`, so the custom one wins.
    Do not edit `hyprland/variables.lua` directly - its own header says to copy
    into `custom/` instead.

13. **Hyprland decoration settings live in
    `~/.config/hypr/hyprland/shellOverrides/main.lua`** — originally
    auto-generated by illogical-impulse (header said "DO NOT EDIT"), which
    forced `blur.size = 1` and made blur invisible. **As of 2026-09-01 the
    user chose to go dynisle-only; ii is no longer running, and this file
    was hand-edited** to `blur.size = 8`, `blur.popups = true`, and — final
    values as of 2026-09-01 — **`active_opacity = 0.85`,
    `inactive_opacity = 0.78`, `fullscreen_opacity = 1.0`**.
    Input/touchpad/gaps/rounding lines were deliberately left untouched.
    **The thing that was actually broken was never the opacity.** Blur was
    disabled on every window by
    `hl.window_rule({match = {class = ".*"}, no_blur = true})` in
    `hyprland/rules.lua` (now commented out, backup `rules.lua.bak-*`), so the
    opacity was the *only* visible effect: plain see-through, the look fact 1
    forbids. The user caught this. With blur on, opacity is the knob that
    controls how much backdrop the blur has to work with — 0.92 leaves only 8%,
    which is imperceptible; 0.85 is the chosen setting. `fullscreen_opacity`
    keeps games and video fully opaque regardless. Detail: `09-ultra-tasks.md`
    UT-03c/UT-03d. Original backed up as
    `main.lua.bak-*` in the same dir.
    **If ii is ever run again it will overwrite this file** and blur breaks
    again — that's the first thing to check if blur mysteriously dies.
    **Load order** (`~/.config/hypr/hyprland.lua`): `hyprland.rules` (17) →
    `custom.rules` (~29) → `hyprland.shellOverrides.main` (44, **wins**).
    Settings put in `custom/rules.lua` will NOT override shellOverrides.
    Runtime testing (`hyprctl keyword` does NOT work with the Lua parser):
    `hyprctl eval 'hl.config({ decoration = { blur = { size = 8 } } })'`

13b. **The user is now dynisle-only — there is NO bar, launcher, clock, or
    tray on their system.** ii is stopped, noctalia isn't installed. dynisle
    currently provides only the wallpaper + an empty pill. Nothing
    auto-starts a shell on boot either (`startup.conf` still points at the
    uninstalled `noctalia-shell`), so after a reboot they must run
    `qs -c dynisle &` manually until autostart is wired (Phase 12).
    **This raises the priority of the launcher (Phase 9)** — the user has no
    other way to launch apps from the shell. Consider proposing it earlier
    than the roadmap order if they hit friction.

14. **`grim` is installed — Claude can screenshot and self-verify UI work.**
    Use it instead of burning the user's feedback cycles on things that can
    be checked directly:
    `grim /tmp/shot.png`, then crop/zoom with PIL and Read the image.
    Don't spam it while the user is actively using the machine.

15. **The machine's timezone is/was `UTC`, not `Asia/Ho_Chi_Minh`.** Confirmed
    2026-09-01 with `timedatectl`: NTP is active and the clock **is**
    synchronised — it is not drifting. Every clock simply reads 7 hours behind
    local time. The fix needs the user's password, so it was handed to them:
    `sudo timedatectl set-timezone Asia/Ho_Chi_Minh`, then restart
    `qs -c dynisle` so Qt re-reads the zone. **If the user says the clock is
    wrong again, check `timedatectl` before touching any QML** — it is a system
    setting, not a `DateTime.qml` bug.

16. **The island is sized BY its content, never by fixed numbers.**
    `IslandShape` measures its children and grows/shrinks to fit, animated by
    `Behavior on width/height`. Two traps that will silently break it:
    - **Bind `width: implicitWidth` / `height: implicitHeight` explicitly.**
      The Item default that makes width follow implicitWidth happens in C++
      with no QML binding, so `Behavior` never fires and the island teleports
      between sizes instead of animating. Verified by measurement, not theory.
    - **Never `anchors.fill: parent` inside the island.** The shape's size is
      derived from the content, so anchoring back to it is a binding loop.
      Panels declare their own implicit size.
    The ONE thing that must stay fixed is `Theme.islandMinHeight` — the
    reserved zone and the 7px gaps are computed from it (fact 2a), so letting
    it follow content would push the user's windows around on every expand.

16b. **NEVER bind the island's PanelWindow size to the animated shape.** The
    window is a FIXED 720×480 transparent canvas (`Theme.islandMaxWidth/
    MaxHeight`); only `IslandShape` inside it animates. Resizing a layer-shell
    surface forces the compositor to reallocate and re-commit it every frame —
    the user reported this as "giật kinh khủng" and diagnosed the cause
    correctly. Two things this makes mandatory:
    - **`mask: Region { item: shape }`** — otherwise the transparent canvas
      swallows every click meant for the windows under it. Verified pattern:
      end4-pC's `Bar.qml`, `Dock.qml`, `MediaControls.qml` all do this.
    - **The shape is `anchors.top` + `horizontalCenter`, never `centerIn`** —
      the window is far taller than the island now.
    Blur is unaffected: `ignore_alpha 0.79` excludes the transparent pixels,
    which is exactly why an oversized transparent window is safe. Detail:
    `07-architecture.md`.

16d. **`IslandShape` is a `ClippingRectangle` (Quickshell.Widgets).** Qt's
    `clip: true` clips to the bounding RECTANGLE and ignores `radius`, so
    content paints into the island's rounded corners. Do not swap it back for a
    plain Rectangle.

16c. **Never declare anything inside a `Loader`.** A Loader's default property
    is `sourceComponent`, so a child object silently becomes the thing it tries
    to load. Cost an hour: the fade `NumberAnimation` was written inside the
    Loader, which left the expanded panel correctly sized but stuck at
    `opacity 0` — a fully blank island, with no error in the log.

17. **Quickshell's hot reload cannot always be trusted during dev.** Seen twice
    on 2026-09-01: a `sed -i` edit was never picked up (it replaces the inode
    and breaks the inotify watch), and a `Timer` from a removed test block kept
    firing in the running scene after the file was cleaned. **If a change seems
    ignored, restart rather than debugging the code.** Restart carefully —
    **`pkill -f "qs -c dynisle"` also matches the shell running the command and
    kills it mid-script** (exit 144), leaving the user with no wallpaper and no
    island. Happened twice. **Use `pkill -x qs`** — it matches the process name
    only, never the calling shell's command line. Restart with
    `setsid nohup qs -c dynisle > /tmp/dynisle.log 2>&1 < /dev/null &`.

18. **The pointer cannot be moved programmatically on this machine.** Tried and
    failed: `hyprctl dispatch movecursor X Y` (the Lua parser rejects the bare
    syntax — same class of problem as `hyprctl keyword` in fact 13),
    `hl.dispatch(hl.dsp.cursor.move{...})` (reports `ok` but the cursor does not
    move), and `ydotool` (daemon runs, command succeeds, cursor unmoved).
    **So hover behaviour cannot be self-verified — it needs the user.** What
    *can* be verified alone: drive `IslandState.expanded` from a temporary
    `Timer`, which exercises the panel swap, the fade and the resize animation
    without touching the pointer. Remove the Timer afterwards.

21. **`XDG_DATA_DIRS` grows on every `hyprctl reload` - this is a real bug in
    `~/.config/hypr/hyprland/env.lua`.** That file does
    `hl.env("XDG_DATA_DIRS", <4 dirs> .. os.getenv("XDG_DATA_DIRS"))`, i.e. it
    appends a fresh copy of itself each time the config is parsed. By
    2026-09-02 it had reached **27 copies (108 entries)**, and every GTK/GIO app
    rescans each entry for icons, mime types and desktop files. Measured effect:
    nautilus took **14.0s** to start; after the fix, **0.645s** (~22x).
    Found with `strace -f -tt` - 122k syscalls, no single stall, 36k of them
    under `/var/lib/flatpak/exports/share`, which is only 15 files. That
    mismatch is what exposed the duplication.
    **Fix:** `~/.config/hypr/custom/env.lua` pins the variable to a fixed
    4-entry value and never reads the old one, so it is idempotent. custom/env
    is required after hyprland.env, so it wins.
    **Claude made this worse** by running `hyprctl reload` many times in one
    session. Prefer fewer reloads, and if any GTK app feels slow, check
    `tr ':' '\n' <<< "$XDG_DATA_DIRS" | wc -l` first - it should be 4.

22. **Terminal and file-manager defaults are overridden in
    `~/.config/hypr/custom/variables.lua`** (loaded by `keybinds.lua` after
    `hyprland.variables`, so it wins and survives dotfiles updates):
    `terminal` -> kitty first (was foot), `fileManager` -> nautilus (was
    dolphin). Both on the user's request, 2026-09-02.
    **Nautilus icon** is overridden in
    `~/.local/share/applications/org.gnome.Nautilus.desktop` (a user copy of the
    system entry) pointing at
    `/usr/share/icons/Papirus/64x64/apps/nautilus.svg`. It must be an
    **absolute path**: the active icon theme is Yaru-sage, so a bare icon name
    would never resolve to Papirus artwork. Delete that file to revert.

23. **GTK warnings nautilus printed, both fixed 2026-09-02.**
    - `Theme parser error: gtk.css:312 Unknown name of pseudo-class` -
      `:insensitive` is GTK3; GTK4 calls it `:disabled`. **`~/.config/gtk-4.0/
      gtk.css` is generated by Matugen**, so the template at
      `~/.config/matugen/templates/gtk-4.0/gtk.css` was patched too, otherwise
      the fix is regenerated away.
    - `Adwaita-WARNING: Using GtkSettings:gtk-application-prefer-dark-theme
      with libadwaita is unsupported` - commented that line out of
      `~/.config/gtk-4.0/settings.ini` only (gtk-3.0 keeps it). libadwaita
      takes its colour scheme from the portal, which was verified to return
      `color-scheme = 1` (prefer dark) in 15ms.
    Two messages remain and are NOT fixable: nautilus connecting to Tracker3,
    and `org.gnome.Mutter.ServiceChannel` missing - nautilus looking for GNOME's
    compositor. Both harmless on Hyprland.

24. **Opacity in QML multiplies down into children - never put a visible
    element inside a container that fades to 0.** Cost a full round: the
    transport buttons were built as `Rectangle { opacity: hovered ? 0.12 : 0 }`
    with the glyph `Text` *inside* it, so the glyphs were invisible until
    hovered. There is no error for this; the buttons simply render as nothing.
    The hover pad and the glyph must be SIBLINGS, with the press `scale` on a
    wrapper around both.

25. **The cava visualiser is the album art's BORDER** (user's design, 2026-09-02),
    not a separate block: 56 bars seated along the artwork's rounded rectangle
    **including the corners**, each rotated to point along the outward normal,
    with fully rounded caps. `ExpandedPanel.borderSeat(s)` walks the perimeter
    (4 straight runs + 4 quarter-circle corners) and returns `[x, y, nx, ny]`.
    A rect at `rotation: 0` grows downward, which is the bottom edge's normal -
    hence the `-90` in the rotation. Do not go back to splitting the perimeter
    into four straight sides; that leaves the corners bare and the user
    rejected it.
    Config is `config/cava.conf` (bars 56, framerate 30, raw ascii to stdout),
    grounded in end4-pC's `raw_output_config.txt`.

26. **`Hyprland.focusedWorkspace` and `Hyprland.focusedMonitor` read
    `undefined` on this Quickshell build - do not build on them.** Measured
    2026-09-02 with a logging timer, after they silently produced no workspace
    updates at all. What DOES work:
    - `Hyprland.workspaces.values` is populated (use it for *which workspaces
      exist*), and
    - `Hyprland.rawEvent` fires reliably - `workspacev2 >> <id>,<name>` on
      every switch. That is the source of truth for *which workspace*.
    `Hyprland.monitorFor(screen)` also works (Island.qml's fullscreen check
    uses it), so the breakage is specific to the `focused*` properties.

27. **The island flashes a workspace strip for 1.5s on a workspace switch.**
    **Revised 2026-09-02 after the user saw it:** NO clock in this panel, and
    it lists only the workspaces that actually exist (Hyprland destroys a
    workspace when its last window closes, so "in the model" already means
    "has windows"), unioned with the focused one so it never omits where you
    just landed. Special/scratchpad workspaces have negative ids and are
    excluded. The numbers are bare - no per-item boxes - because the island's
    own rounded body is the container: that is what the user's `| 1  2  3 |`
    sketch means. The focused workspace is wrapped in a **mark**: the bar's own
    shape shortened - `radius = height / 2` over a width comfortably greater
    than the height - in a flat accent fill with **no border**. It is
    deliberately INSET (`Theme.wsMarkScale` 0.9, applied as the same margin on
    all four sides): spanning the bar's whole height made it read as jammed in.
    At `wsSpacingScale` 1 the focused cell is square and the mark becomes a
    circle, which the user found too thin - 1.5 is the shortened-bar look.
    **Spacing comes from cell width, never from a `spacing` value** - the Row's
    is 0, and the strip sets `islandPaddingH: 0` and `islandMinWidth: 0` on the
    shape. `Theme.wsSpacingScale` is the single knob: the focused cell is
    `wsBarHeight * scale`, every other cell half that. Everything derives from
    `wsBarHeight`, so changing the bar's height cannot desynchronise the strip. So the strip is tight everywhere except
    around the mark, which is the only place it opens up. The first cell starts
    at the bar's left edge, so its mark sits evenly inside the bar's rounded cap.
    **The mark's position is computed from the layout the strip is HEADING for**
    (`markSeat`, summing the target cell widths), not read off the live cells.
    Cell widths animate when focus moves, and a mark chasing live geometry lags
    behind them; both now run the same duration and easing toward the same
    endpoint and arrive together. Verified 80ms into a switch: the mark was
    already centred on the new digit.
    **Five shapes were tried, in this order:** a dot under the number (too
    quiet); a small rounded box (right in spirit, `| 1  2  [ 3 ] |`, but did not
    reach the bar's edge); *stretching* the end mark to reach the edge (pushed
    the number off centre - the fix is padding, never stretching); a shortened
    bar shape at ~69x40 (the user found the strip too fat); and finally the
    circle. **The CELL is what sizes the mark** - the mark always spans exactly
    its own cell, so the number cannot drift off centre.
    The mark overflows its cell vertically by `islandPaddingV` to reach the
    bar's top and bottom; IslandShape clips, and `childrenRect` measures direct
    children only, so neither the island's height nor its width is affected.
    Surveyed end4-pC's `modules/ii/bar/Workspaces.qml` for reference: square
    cells, a circular indicator inset by 2px that stretches across adjacent
    occupied workspaces - a different design, not adopted.

    **The strip must not rebuild its delegates or change length - five separate
    fixes, all needed, none of them optional:**
    1. **The mark lives OUTSIDE the Repeater.** One long-lived Rectangle whose
       `x`/`width` follow whichever cell is focused (the cells report their
       geometry via `seatMark`). Inside a delegate it could never travel - it
       vanished at one number and reappeared at the next.
    2. **The model is a `ListModel` edited in place** (`syncCells()`), never a
       fresh JS array. A Repeater cannot diff an array, so any change destroys
       and rebuilds every delegate; for a frame the strip is empty, the island
       animates its width toward nothing and back, and the focused number
       visibly gets recreated. Stepping between two EMPTY workspaces (3 -> 4)
       is the pure case: only one digit should change. **Measured after the
       fix:** the shape's width held at 202 for 44 of 45 samples across such a
       switch, where it used to collapse.
    3. **Cells use a fixed advance per digit** (`Theme.wsDigitWidth`), not their
       own text width - glyph widths differ and the strip jittered 3px when the
       focused number changed.
    4. **The strip lists workspaces with WINDOWS, plus the focused one - not
       every workspace that exists.** "Exists in Hyprland's model" is not the
       same thing: Hyprland keeps an empty workspace alive while it is focused,
       and stepping off it creates the NEXT workspace *before* destroying the
       old empty one. Filtering on existence alone produced a frame showing
       BOTH - `1 2 3 [4]` flashing between `1 2 [3]` and `1 2 [4]` - which
       shoved the numbers sideways and resized the island twice. The user
       spotted this after the other fixes had already landed.
       Verified: `toplevels` counts are real (`1:1 2:1 3:0`), the id sequence
       goes `[1,2,7] -> [1,2,8]` in one step, and the island's width held
       constant across the switch.
    5. **`IslandShape` is a `ClippingRectangle`, not a `Rectangle` with
       `clip: true`.** Qt's clip is rectangular and ignores `radius`, so the
       mark painted into the island's rounded corners and poked out past the
       bar's end while the shape was animating.

27b. **`IslandShape.paddingH` AND `IslandShape.minWidth` are overridable per
    panel.** A loaded panel may declare
    `readonly property real islandPaddingH: <n>` / `islandMinWidth: <n>` and
    `Island.qml` picks them up
    (`panelLoader.item?.islandPaddingH ?? Theme.islandPaddingH`, same for the
    minimum). Only the workspace strip uses them so far, and it needs 0 for
    both. The minimum width matters as much as the padding: at
    `Theme.islandMinWidth` (96) a single focused workspace rendered as
    `|  [1]  |` - a 40px circle with 28px of dead bar on each end - instead of
    `[1]`. **Vertical** padding is NOT overridable; the reserved zone depends on
    it (fact 2a).

28. **Animate content swaps with a `Translate`, never with `y`.** The island
    measures its content through `childrenRect`, so animating a panel's `y`
    drags the island's own height along with it. Transforms are invisible to
    layout. `Island.qml` slides the incoming panel from `-6` and fades it in.

29. **`Theme.panelScale` is the single knob for the expanded panel's size**
    (0.75 as of 2026-09-02, at the user's request). Every panel dimension and
    the panel's own font sizes derive from it, so "make it a bit smaller" is
    one number, not a sweep. It is deliberately separate from the generic font
    tokens so shrinking the panel never touches the idle pill's clock.

30. **Two things had to be right before the launcher's field would accept a
    keystroke. Both are easy to break again.**

    **(a) Never two-way bind a `TextInput.text`.** It was written as
    `text: Launcher.query` *plus* `onTextChanged: Launcher.query = field.text`.
    The binding stays live while you type, so it re-asserts the old value over
    the character just entered and the field looks like it is ignoring the
    keyboard. The query now flows one way, field -> service, and the field is
    seeded once in `Component.onCompleted`.

    **(b) `WlrLayershell.keyboardFocus: Exclusive`, and NEVER `focusable`
    alongside it.** On this build `focusable` is the portable alias for the
    same setting, so having both silently downgrades it to OnDemand. OnDemand
    alone is no good either - it hands focus over on a CLICK, and this launcher
    opens from a keybind, so no click ever comes. (end4-pC's overview uses
    OnDemand, but it is a different interaction; do not copy it here.)
    Exclusive is also the one setting in dynisle that could swallow every key
    on the machine, so it is granted ONLY for the launcher panel, with three
    ways out: Escape on the field, `SUPER + D` again, and clicking away.

    **`HyprlandFocusGrab` must be armed on a ~180ms delay.** Grabbing in the
    same turn as the shortcut's own key event made Hyprland clear it instantly
    and slam the launcher shut as it opened. Verified by logging `onCleared`.

    **`Window.active` reads false for a layer surface even when focus works.**
    Do not use it as a signal - it sent this chase down a blind alley for two
    rounds.

    **(c) Read `preeditText`, not just `text`.** The user types Vietnamese, so
    an input method is running and every keystroke lands in the IME's PREEDIT
    buffer - `text` does not change until it is committed. Search only updated
    after pressing space or enter until the field started reporting
    `field.text + field.preeditText`, on both `onTextChanged` and
    `onPreeditTextChanged`. The placeholder checks both lengths for the same
    reason. Confirmed by the user: typing in English worked all along, Vietnamese
    did not. **Any future text input in dynisle needs this**, not just the
    launcher.

31. **`SUPER + D` is the launcher, and it DISPLACED Hyprland's
    fullscreen/maximize toggle.** The bind lives in
    `~/.config/hypr/custom/keybinds.lua`, which loads after
    `hyprland.keybinds` and therefore wins. The user picked the key knowing
    this; the old maximize binding has not been relocated anywhere.

32. **Launcher design was agreed on a web mockup before any QML** - the user
    asked for it, and it was the right call: the layout went through several
    revisions there for the price of a republish.
    https://claude.ai/code/artifact/a323226a-2950-4419-8eae-808138e26049
    It carries the real installed apps, their real icons (resolved through the
    icon theme and embedded) and the scoring function ported verbatim, so it is
    a faithful stand-in rather than a sketch. Keep it in step if the launcher's
    design changes again.

33. **Quickshell singletons are created on FIRST REFERENCE, and populate
    asynchronously after that.** A probe that touches a service and reads it in
    the same instant sees zeros - which briefly looked like five broken
    services. Touch them at startup, read them later.

34. **Four traps hit while writing the UT-10 services. All were measured, none
    were guessed:**
    - **`UPowerDevice.percentage` is a FRACTION**, not a percentage. Multiply by
      100 or a half-full battery renders as "1%".
    - **QML's JS engine has no regex lookbehind.** `line.split(/(?<!\\):/)`
      threw inside a signal handler and died silently, leaving the Wi-Fi list
      permanently empty while `nmcli` was working fine. Split by hand.
    - **`Pipewire.defaultAudioSink` hands back an opaque wrapper** - every
      property on it reads `undefined`. The same node taken from
      `Pipewire.nodes` works normally, so look the default up by identity in
      that list and use the list's copy. Typing the property as `PwNode` rather
      than `var` makes it worse.
    - **`Pipewire.defaultAudioSink` is read-only.** Changing device goes through
      `preferredDefaultAudioSink`, which is writable.

35. **Only `nmcli` needs shelling out.** Everything else in the control centre
    has a real API: `Pipewire` for volume and devices, `UPower` +
    `PowerProfiles` for battery and profile, `NotificationServer` for
    notifications, `Bluetooth` if it is ever wanted, and sysfs +
    `brightnessctl` for the backlight. Reading brightness through `FileView`
    with `watchChanges` means the laptop's own brightness keys move the slider
    too.

36. **Every icon goes through `modules/common/Icon.qml`.** Material Symbols is
    a variable font whose **FILL axis** is what separates outline glyphs from
    solid ones, so setting `font.family` by hand gets filled shapes. Icon.qml
    sets `font.variableAxes: { "FILL": 0, ... }` in one place. The user asked
    for flat one-plane line art and sketched a coffee cup to say so; the same
    font is what the web mockups use, so mockup and shell render identically.

37. **`notify-send -A` blocks until the action is invoked.** It hung a test
    command for two full minutes. Run it detached when testing actions.
    Also: a `critical` notification never auto-dismisses by design, so a test
    one stays on screen until clicked - restart the shell to clear it.

38. **`nmcli device wifi list` defaults to `--rescan auto`, which takes 9.7
    SECONDS.** Measured: `--rescan no` returns the cache in 15ms, `auto` makes
    the radio sweep the band when the cache is older than 30s. The Wi-Fi list
    sat empty for that whole time on every open. `Network.qml` now lists with
    `--rescan no` and triggers `nmcli device wifi rescan` separately, on a
    25s timer while `watching`; the header spinner tracks the rescan, not the
    listing.

39. **Never restart a `Process` that is still running to "refresh" it.**
    Killing nmcli mid-stream makes its `StdioCollector` finish with an empty
    or half-read buffer, and that empty parse lands last and blanks the whole
    list. `Network.refresh()` now returns early while a scan is in flight.
    Same class of bug as fact 16c: the failure is silent and looks like a
    data problem, not a lifecycle one.

40. **`state` and `enabled` are Item properties - do not redeclare them.**
    `ControlTile` had `property string state`, which shadows `Item.state`, and
    a button had `property bool enabled`. Qt logs
    "overrides a member of the base object" for these, and the shadowed base
    property silently stops being driven. Renamed to `detail` and `usable`.

41. **Anchoring across siblings produced a zero-sized overlay.** `ListFade`
    with `anchors.fill: someSiblingFlickable` drew nothing at all, no warning.
    Wrapping the Flickable in an `Item` and using `anchors.fill: parent` for
    both fixed it. Related: an overlay can never be a plain sibling inside a
    `Column` anyway - the positioner lays every visible child out as a row.

42. **`notification.appIcon` ALWAYS arrives empty.** Whatever the sender put
    in `app_icon` is folded into `notification.image` as `image://icon/<name>`
    - and Quickshell builds that url even for a name that resolves to nothing.
    So the url proves nothing. `Quickshell.iconPath(name, true)` is the only
    honest check: it returns `""` for a name the theme does not have.
    `image://icon//home/x.png` (double slash) means the sender passed a FILE
    PATH, which is how a screenshot tool hands over its own PNG.

43. **`Pipewire.defaultAudioSink` is unusable in this build.** It is typed
    `PwNodeIface`, is not null, and still reaches QML as a QVariant box that
    never coerces - `?.description`, `?.audio?.volume` and `?.ready` all come
    out nullish, and it never `===` the same node from `Pipewire.nodes`.
    Assigning it to a typed `PwNode` property (what end4-pC does) does not help.
    Consequence: `Audio.qml` silently used `sinks[0]` - Easy Effects, NOT the
    default - so the control centre drove the wrong device and its volume never
    moved. Fixed with `pactl get-default-sink`, whose output matches
    `PwNode.name` exactly, refreshed off `pactl subscribe`.

44. **Restarting the shell and `hyprctl reload` break Vietnamese input.** Both
    drop the Wayland `text-input` binding of already-open windows; fcitx5 then
    reports `State = 0` (no input context) and nothing can be typed. fcitx5
    itself is fine (`Using Wayland native input method protocol: 1`). The fix
    is `systemctl --user restart app-org.fcitx.Fcitx5@autostart.service` while
    the window is focused - after which it comes back on `keyboard-us`, so the
    user still has to toggle to bamboo. **Restart the shell sparingly.**

45. **fcitx5 emits no DBus signal when the input method changes.** Checked with
    `dbus-monitor` across the whole session bus while switching: nothing. The
    kimpanel interface stays silent too. So it has to be polled -
    `fcitx5-remote -n` costs ~4ms, and one long-lived `sh` loop that prints
    only on change keeps it to a single process.

46. **Notification scope is deliberately small** (user, 2026-09-02): system
    notifications are Battery, new device and pacman updates. Keyboard layout
    was built and then removed - it fired on every workspace switch, see 45.
    App notifications are icon + app name + content, nothing else. **No inline
    reply, no action buttons, no progress rail, no timestamp, no OSD for
    brightness/volume.** Reply was cut for a real reason: nothing on this
    machine sends an `inline-reply` action, and Discord/Zalo arrive through the
    browser, which never sets one - the box would have been decoration.

47. **The launcher results panel must be capped and scrollable.** It used to
    grow with the match count straight past the bottom of the fixed 480px
    island window, and the compositor sliced it - the rounded bottom corners
    became a flat cut. Searching "a" was enough to trigger it.
    `Theme.launcherMaxListHeight: 322` keeps the whole thing inside the window
    (field 56 + gap 10 + panel 338 = 404 < 480), the rows live in a Flickable,
    and `ListFade` (moved to `modules/common`) marks the cut.

48. **Closing on an outside click has TWO mechanisms, on purpose.**
    `HyprlandFocusGrab` is the primary one, but it did not always fire and the
    user was left pressing SUPER+D or Escape. Hyprland's `activewindow` raw
    event is the second: a window taking focus while the launcher is up can
    only mean the click landed elsewhere. Both are gated behind a short timer,
    because opening the launcher itself pulls focus off the current window.

49. **Screenshots are clipboard-only** (user, 2026-09-02). No folder is
    created. Two files live in XDG_RUNTIME_DIR while a capture animates (the
    picture and a marker carrying the geometry); both are replaced each time.
    `SHIFT + Print` = region, `SUPER + Print` = whole screen. The region
    overlay is slurp's own drawing: `-b '#000000b0'` dims the screen,
    `-s '#00000000'` leaves the selection fully transparent so it reads as a
    hole, `-w 0` removes the border - all that is left is the crosshair.

49a. **`#` OPENS A COMMENT IN THE SHELL.** `sh -c "slurp -b #000000b0 ..."`
    became `slurp -b` and the rest of the line vanished, dying with exit 2 on
    every keypress. Single-quote any colour passed through a shell.

49b. **A GUI child launched from `Process` may never map a surface.** slurp
    started that way runs, prints nothing, exits nothing - and has NO sockets
    in /proc/PID/fd, so it never connected to Wayland at all. The identical
    argv from a terminal dims the screen correctly. `Quickshell.execDetached`
    works (it is what the launcher uses to start real apps), so the capture
    pipeline is detached and writes its geometry to a marker file that
    `Screenshot.qml` polls with a FileView. Set `printErrors: false` there -
    polling a file that does not exist yet is not an error.

49d. **The capture animation runs in TWO phases, and must.** Encoding a PNG
    costs time in proportion to the area - a small snip is instant, a full
    screen is not - so waiting for the picture put a pause between the shutter
    and anything moving, and the user noticed it scaling with selection size.
    The shell writes the geometry marker the moment it is known (before grim),
    dynisle starts the flight immediately with a placeholder over the very
    region it is lifting, and the real picture fades in when a second marker
    says grim finished. The screen underneath still shows those exact pixels,
    so the placeholder is not noticeable.
    Measured: the placeholder does NOT leak into the capture - clipboard and
    screen pixels match exactly - because grim grabs the buffer before a QML
    frame can commit.

49e. **Only ONE thing may dim the screen.** slurp snaps its background on with
    no transition, so dynisle eases its own veil in over 190ms instead - and
    slurp is launched with `-b '#00000000'`, no background at all. Both dimming
    at 0.69 composites to 0.90, which the user saw as "getting dark, VERY dark,
    less dark". slurp still marks the selection (`-s '#ffffff26'`, a faint
    lift rather than a hole) and `-w 0` keeps it borderless.
    Measured after the fix: 80ms -> (15,19,21), 160ms -> (11,14,15), flat
    thereafter. One layer, no bump.
    `XCURSOR_THEME=Breeze_Light` is set for slurp because the session theme
    (Bibata-Modern-Classic) draws a BLACK crosshair with a white outline, which
    all but disappears on a dimmed screen.

49g. **dynisle's veil is a committed surface, so grim WOULD capture it.** The
    shell writes a `.done` marker the moment the selection ends, waits 120ms
    for the compositor to drop the veil, and only then captures - otherwise the
    screenshot comes out dark. The veil eases in but is cut off instantly, for
    the same reason. A full-screen capture never dims and skips both.
    And `.done` must be written even when slurp is CANCELLED: bailing out on
    `|| exit 1` before writing it left the screen frozen dark for good.

49c. **Every capture MUST use unique filenames.** This is what made
    screenshots work only sometimes. With fixed marker paths the 30ms poll read
    the PREVIOUS capture's marker before the detached shell had run its `rm`,
    so the animation replayed the old screenshot and the new capture finished
    unnoticed. A per-capture token (`dynisle-shot-<ms>.png/.geom/.ready`) makes
    the race impossible, and it also settles QML's URL-keyed Image cache, which
    otherwise animated the FIRST screenshot forever.

49f. **Cancelling a selection must not block the next one.** `busy` was left
    set until the 60s poll timeout, so pressing Escape on slurp silently killed
    screenshots for a minute. A new request now resets any in-flight wait
    instead of being ignored.

50. **`modules/screenshot/ShotLayer.qml` is the third PanelWindow**, and the
    only exception to "only Island and WallpaperLayer make windows": confirming
    a capture means animating from wherever on screen it happened, which
    nothing inside the island can reach. The picture shrinks out of the place
    it was taken from, flies into the island, and the island then says
    "Copied to clipboard" (IslandState `toast` panel, 1.6s). It sits on the
    Overlay layer and carries an EMPTY `mask: Region {}` so it can never eat a
    click, and it is mapped ~60ms BEFORE the animation starts - binding
    `visible` straight to the running animation ate the first third of the
    flight while the layer surface was still being created.

51. **Update notifications fire once per shell launch**, 90s after start, and
    say "You're up to date" when there is nothing. A repeating check said the
    same sentence every few hours, which the user called spam.

52. **The flying screenshot passes UNDER the island, and that needs two
    things.** `ShotLayer` sits on `WlrLayer.Top` (not Overlay) and is declared
    BEFORE `Island` in shell.qml, because Hyprland stacks same-layer surfaces
    in creation order. It must also be `visible: true` for the whole session -
    mapping it lazily created its surface AFTER the island and put it on top,
    which is backwards. Idle cost is nil: transparent, empty mask, content at
    opacity 0. It shrinks to 58x34 (smaller than the idle pill) and does not
    fade - the island simply covers it.

53. **Two captures per screenshot.** `grim -s 0.12 -l 0` takes 130ms and gives
    163x92; a full-quality one takes 642ms (measured). The animation gets the
    cheap one - far more detail than a 58px thumbnail can show - and the
    clipboard gets the real one. The toast waits for the clipboard, so
    "Copied to clipboard" is never said before it is true.

54. **The launcher has no pin limit.** The old `maxPinned: 8` made the pinned
    row wider than the panel, so the last tile and its selection mark poked out
    past the rounded corner. Tiles now wrap in a `Flow` and scroll past three
    rows, and the panel only shrinks to fit while they fit on one row.

55. **A binding loop stops a panel appearing at all.** `ControlSlider`'s device
    label derived its width from a child that was anchored back to it; Qt logged
    "Binding loop detected for property width" and the control centre simply
    never opened - no error about opening, nothing in the grab or focus paths,
    just an unsettled layout. Read the FULL log, not a grep for "error": the
    only clue was a WARN.

56. **Closing a panel under the pointer used to flash the media panel.**
    `hovered` was written straight into `expanded`, so dismissing the control
    centre with the pointer still over it collapsed the island, fell through
    the priority chain to "expanded" for a moment, and only then settled.
    `IslandState` now latches: `expanded = hovered && !hoverLatched`, the latch
    is set when a panel closes while hovered, and released only by the pointer
    LEAVING - never by a timer.

57. **Two animations for one size is what "giật" actually was.** `ControlPanel`
    animated its own `implicitHeight` while `IslandShape` animated its height
    from that same value: the content settled at one size, then drifted again as
    the island caught up. One animation, in one place, and the view slide uses
    the SAME duration so the whole thing is a single motion.

58. **The control centre takes the keyboard so Escape can close it.** Same
    treatment as the launcher, and focus is claimed via `Qt.callLater` for the
    same reason (fact 30). Three ways out: Escape, SUPER+R, clicking away.

59. **The power profile buttons do NOTHING on this machine. Verified.**
    `powerprofilesctl set power-saver|balanced|performance` leaves
    `scaling_governor=schedutil`, `scaling_max_freq=2700000` and no
    `energy_performance_preference` file at all - identical in all three.
    Why: the cpufreq driver is `intel_cpufreq`, i.e. intel_pstate in PASSIVE
    mode, which exposes no EPP knob, and there is no
    `/sys/firmware/acpi/platform_profile`. PPD itself reports
    `PlatformDriver: placeholder` for balanced and power-saver.
    The UI is honest about what it SET, but nothing downstream acts on it.
    Root cause is the CPU: an i5-5200U (Broadwell) has **no HWP**, so
    intel_pstate can never expose EPP here, in active mode or passive.
    The control is KEPT and made real through `system/dynisle-powerplan` (a
    root helper) and `system/49-dynisle-powerplan.rules` (a polkit rule scoped
    to that one program path and one user). `Power.qml` reads the plan from
    `scaling_governor` - the truth, whoever set it - and writes through
    `pkexec`. The row hides itself until the helper is installed, because a
    control that cannot do anything should not be on screen.

    **`scaling_max_freq` is the WRONG knob here.** intel_pstate is in PASSIVE
    mode and governs the policy ceiling itself, so writes were quietly ignored:
    asking for 2200000 read back as 2700000 every time, even with the governor
    left unchanged. Verified by re-running with no governor change at all.
    The knobs that work are the driver's own, at
    `/sys/devices/system/cpu/intel_pstate/`:
      no_turbo      1 pins the ceiling to base clock (2.2 GHz), 0 allows turbo
      max_perf_pct  a percentage of whatever the ceiling then is
    And the governor must be written FIRST - changing it can reset the limits.

    Ceilings, so the three plans genuinely differ:
      saver       powersave   no_turbo=1 pct=55   ~1.2 GHz
      balanced    schedutil   no_turbo=1 pct=100   2.2 GHz  (base, NO turbo)
      performance performance no_turbo=0 pct=100   2.7 GHz  (turbo)
    Balanced cutting turbo is the point - on a 15W part turbo is where the heat
    and the watts are.

    The helper prints what actually TOOK, read back from sysfs, rather than
    what it was asked for. The first version reported success on a write the
    kernel had ignored, which is exactly how the wrong knob went unnoticed.

    **The polkit action id is `org.freedesktop.policykit.exec`** - NOT
    `...policykit.exec.path`. With the wrong id the rule matched nothing,
    polkit fell through to asking for a password, and `pkexec` sat waiting for
    an agent. Confirmed twice: polkitd's own log line, and
    `/usr/share/polkit-1/actions/org.freedesktop.policykit.policy`.
    Retrying it three times tripped `pam_faillock` (deny=3) and locked the
    account out of **sudo as well**, for 600s - `pam_faillock` lives in
    `system-auth`, not just the polkit stack. So: `pkexec` is called with
    `--disable-internal-agent`, which fails fast instead of prompting, and a
    failing pkexec must NEVER be retried in a loop.

    VERIFIED working end to end: `pkexec` returns 0 with no prompt, the plan
    applies (schedutil/no_turbo=1/2100MHz for balanced, powersave for saver),
    and the travelling mark in the control centre follows the governor even
    when the plan is changed from OUTSIDE dynisle.

    Measured on this laptop (29 Wh of a 50 Wh design battery, 58% health):
      idle                    7.2 W   ~4.1 h
      4 cores at 2.5 GHz     22.5 W   ~1.3 h, package 78 C
    So the ceiling is worth having: power scales with roughly f*V^2 and the
    voltage falls with the clock, so cutting the clock cuts power by more than
    the ratio. A fixed task takes longer, which eats into that - but the net is
    still a saving, and the thermal difference on an 11-year-old machine is
    not a rounding error.

63. **A zero-sized `Item` whose children sit at NEGATIVE offsets draws
    nothing.** The screenshot crosshair was built that way and never appeared -
    no warning, no error. The arms have to live inside the item's own bounds.

64. **A marker file is created before it is written.** A 30ms poll read the
    cursor-position marker EMPTY, took that as the answer, and parked the
    crosshair at 0,0. An unparseable read is not an answer: return and keep
    polling.

65. **The pinned launcher icons came up grey on the first open after a
    restart.** The panel is built lazily, so every icon was resolved and
    decoded while already on screen. A hidden, zero-opacity Repeater of the
    same IconImages at the same size in `Island.qml` loads them during startup
    instead; Qt caches decoded images by URL, so the first open is now as fast
    as the second.

60. **slurp is gone; dynisle chooses the region itself.** SHIFT+Print now
    FREEZES the screen (`grim -l 0`, 37ms - compression level 0 is what makes
    it instant; the default level 6 takes 642ms) and the drag happens over that
    still image. Doing it in-shell is what makes three things possible that
    slurp offers none of: a ROUNDED selection, Escape to cancel, and a
    crosshair that disappears with the surface instead of being left stranded.
    Pressing the shortcut again also cancels.
    The rounded selection is drawn by RE-DRAWING the frozen picture at full
    brightness inside a `ClippingRectangle` - a hole cut in the dimming could
    only ever be a rectangle.
    The crop comes from the FROZEN file via `magick`, so what lands on the
    clipboard is the moment the key was pressed. The flight needs no file at
    all: `Image.sourceClipRect` shows the selected part of the already-loaded
    freeze.

61. **Joining a network shows that it is joining.** nmcli returns long before
    the association settles, so `Network.connectingTo` / `connectingFor` drive a
    spinner and an elapsed count on the row. Cleared when `currentSsid` matches,
    when nmcli exits non-zero, or after 90s (nmcli's own timeout).

62. **No fade-out at the bottom of any scrolling list** (user, 2026-09-02).
    `ListFade` is deleted, not just unused.

66. **"Keep awake" was never doing anything.** `Idle.qml` used
    `systemctl --user stop/start hypridle`, but hypridle is NOT a user unit
    here - Hyprland starts it directly (`hl.exec_cmd("hypridle")` in
    hyprland/execs.lua). `systemctl --user is-active hypridle` answered
    "inactive" about a process that was running, and because the reading was
    inverted the tile sat permanently on "On".
    The right lever is a logind idle inhibitor: hypridle honours those unless
    `ignore_dbus_inhibit` is set, and it is not set here. The service now holds
    `systemd-inhibit --what=idle ... sleep infinity` for as long as the toggle
    is on. The state IS the process - nothing to query, nothing to poll, and if
    the shell dies the inhibit is released with it.
    VERIFIED: `systemd-inhibit --list` shows the dynisle idle inhibitor while
    on and nothing while off.
    Note when testing: `Idle` is a LAZY singleton (fact 33), so it does not
    exist until the control centre has been opened once - a first test showed
    no inhibitor for exactly that reason, not because the code was wrong.

67. **`qsConfig` is the one line that decides which shell this machine runs.**
    It lives in `~/.config/hypr/custom/variables.lua` and is read by
    `hyprland/execs.lua` (`qs -c $qsConfig` on hyprland.start) and by
    CTRL+SUPER+R. It said `end4-pC`, so Hyprland was still AUTOSTARTING
    end4-pC on every login - which would have taken the notification bus from
    dynisle. Now `dynisle`, which also gives dynisle autostart for free.
    Side effect handled: `qsScripts` is built from `$qsConfig`, so end4-pC's
    screen recorder and wallpaper switcher (real, working scripts with no
    dynisle replacement) are re-bound to an ABSOLUTE path in
    `custom/keybinds.lua` instead of breaking.

68. **The Hyprland config is Lua, and every `.conf` file was dead.**
    `hyprctl systeminfo` reports `configProvider: lua`; the entry point is
    `hyprland.lua`, which requires `hyprland/*` then `custom/*`. Nothing
    sources a `.conf`, so keybinds.conf (99 lines of noctalia binds),
    windowrules.conf, inputs.conf, animations.conf, monitors.conf,
    workspaces.conf, themes/theme.conf and animations/default.conf were all
    leftovers from a pre-Lua config. Moved to `~/.config/hypr/_unused/`.
    KEPT, because other programs read them directly: hyprlock.conf (+
    hyprlock/colors.conf, which it sources), hypridle.conf, lumen.conf.
    Full backup at `~/.config/hypr-backup-<timestamp>`.

69. **Clicking outside is caught by dynisle, not by HyprlandFocusGrab.**
    The grab arms correctly - verified, `grab.active` goes true and stays -
    but it only reacts when the compositor hands the grab back, which clicking
    empty desktop, or the window that already had focus, never does. So
    `ShotLayer` (already a fullscreen always-mapped surface) takes a
    fullscreen input mask while the launcher or control centre is up and
    closes them on press. The island is created AFTER it on the same layer, so
    it sits above and keeps its own clicks.

70. **Click-outside-to-dismiss is UNSOLVED. Do not re-try these three.**
    Measured, not guessed:

    a) **Quickshell has no idea what "click outside" means.** Its only
       primitive is `HyprlandFocusGrab`, whose entire API is `active`,
       `windows` and a `cleared` signal - a thin wrapper over the compositor's
       `hyprland_focus_grab_v1`. All the logic lives in Hyprland.

    b) **Binding `active` directly to "is a panel open" - the way end4-pC's
       GlobalFocusGrab does it - makes the panel close on the frame it opens.**
       Hyprland clears the grab immediately when the panel was opened by a
       keybind, because no click ever established it. The 180ms arming timer
       that used to be here existed for exactly this reason.
       end4-pC gets away with the direct binding because its panels are
       FULLSCREEN windows with `WlrKeyboardFocus.OnDemand`. dynisle's island is
       a 900x480 window holding EXCLUSIVE focus - it needs Exclusive because a
       small window with OnDemand never gets the keyboard from a keybind
       (notes.md fact 30), and the two combinations behave differently.

    c) **A fullscreen Top-layer surface does not receive the pointer here.**
       Tried catching the click with `ShotLayer` instead. Measured with the
       control centre open, the pointer at (708,639) - far below the island's
       y-extent - the mask a CONSTANT item sized 1366x768 and enabled, and no
       focus grab anywhere to consume input: `containsMouse` stayed false.
       Constant item vs swapped item made no difference; nested vs flat Region
       made no difference.

    Note when testing this: a grab that IS active makes the compositor swallow
    input outside the grabbed window, so any hover test run while a grab is up
    proves nothing. Two of the tests above were invalidated that way.

    **SOLVED, by the fourth approach.** The click is caught on the ISLAND
    window, not on a separate surface - that window demonstrably receives the
    pointer, which is how hovering the island opens the expanded panel in the
    first place. While the launcher or the control centre is open:
      - the window grows from 900x480 to the full screen,
      - a `dismissArea` MouseArea fills it and is added to the mask,
      - it is declared BEFORE IslandShape so the shape stays above it and
        keeps its own clicks,
      - and it collapses to 0x0 the moment the panel closes, so an idle island
        still lets every click through.
    Keyboard focus stays EXCLUSIVE, so typing in the launcher is unaffected -
    end4-pC's OnDemand was never an option here (fact 30).
    This is a resize twice per open, not once per frame, so the reason the
    window is otherwise fixed-size (fact 16b) still holds.

71. **The panels must CLOSE each other, not just outrank each other.**
    `IslandState.panel` is a priority chain over independent booleans, so
    opening one while another was up left the first still open BEHIND it:
    launcher up, press SUPER+R, dismiss the launcher, and the control centre
    appeared instead of the island returning to the bar. `openLauncher()` now
    calls `closeControl()` and `openControl()` calls `closeLauncher()`.
    The priority chain still exists - it decides what wins for the states that
    genuinely can coexist, like a notification arriving over a hover - but two
    keybind-opened panels are never two states at once.

72. **`blur:xray` was why the island's blur kept showing the OLD wallpaper.**
    With xray on, Hyprland blurs a SNAPSHOT of the desktop background instead
    of whatever is really behind the surface, and it does not retake that
    snapshot when the wallpaper changes. `hyprland/general.lua` sets it true;
    `custom/dynisle-blur.lua` now sets it false and loads last, so it wins.
    Off also means the island blurs the real windows underneath, which is what
    blur was supposed to mean here all along (fact 1).

73. **One failing matugen template aborts the WHOLE run.**
    `~/.config/gtk-4.0/gtk.css` is a symlink into
    `/usr/share/themes/adw-gtk3-dark/`, which is root-owned, so matugen died
    with "Permission denied" and generated NOTHING - including the colors.json
    the shell reads. The gtk4 template is commented out in
    `~/.config/matugen/config.toml`; nothing is lost, because that symlink
    meant GTK4 was never being recoloured anyway.
    Also: `matugen image X` REQUIRES `--prefer` when several source colours are
    possible and no terminal is attached. dynisle passes `--prefer saturation`.

74. **The wallpaper picker (UT-11) and themes (UT-12) are one feature.**
    A theme IS a folder under `~/Pictures`; there is no config file, no
    palette, nothing to keep in step. Folders are listed with Qt's
    `FolderListModel` (declarative, no process). Folders can be HIDDEN - the
    list keeps them out, nothing on disk is touched - and un-hidden from the
    same view.
    Colours come from the wallpaper, not from the theme: `Theme.qml` reads
    matugen's generated palette and derives everything from FOUR keys -
    `background`, `on_background`, `outline`, `primary`. Verified end to end:
    applying wallhaven-7p23p9 produced `primary #ffb695`, and the island's
    measured fill was (21,17,18) against a generated background of #1a120e.
    `surfaceAlpha` stays 0.88 regardless, or blur stops (fact 1).

75a. **SUPERSEDED by fact 79 - a theme is no longer a folder at all.**
    Kept only because the reasoning about discovery still holds.

75. **Wallpaper folders are ADDED by hand, never discovered.** Scanning
    `~/Pictures` offered readme_assets and lumen-kiemthu - folders full of
    pictures that are never wallpapers. `Wallpapers.roots` is a list the user
    builds through a real directory chooser (`yad --file --directory`; GTK,
    which matches the portal this machine is pinned to - kdialog is installed
    but opens the KDE dialog the user moved away from). Removing a folder
    removes it from that list until it is added again; nothing on disk is
    touched. Grid is capped at TWO rows and scrolls, with NO fade at the cut.

76. **kitty was never following the wallpaper because nothing generated its
    theme.** `kitty.conf` already had
    `include ~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf`
    - illogical-impulse's own pipeline wrote that file once, in September, and
    matugen had no template for it. Added one. Running kitty instances need
    ctrl+shift+F5 to re-read; new windows pick it up on their own.
    foot is NOT covered: its `[colors]` block is inline in foot.ini with no
    include, so wiring it needs an edit to that file.

77. **A theme card previews the folder it stands for.** Each card carries its
    own `FolderListModel` and shows four of that folder's pictures in a 2x2
    mosaic, with the name and the count under it - a row with a name on it is a
    file manager, not a theme picker.
    Trap: inside the Image, `parent` is the ClippingRectangle's CONTENT item,
    which has no `index`, so `peek.get(parent.index, ...)` silently resolved to
    the same picture four times. The delegate needs an id and `tile.index`.

78. **Recolouring is animated, in two places.** `Theme.qml`'s four base colours
    dropped `readonly` so they can carry a `Behavior` - a Behavior intercepts
    writes INCLUDING the ones a binding makes, so a new matugen palette eases
    across instead of snapping, and every derived colour follows as one.
    `WallpaperLayer` crossfades between TWO Images: the incoming one loads at
    zero opacity and only fades up once its status is Ready, so a slow decode
    never shows a blank screen. Same 550ms for both, so picture and colour move
    together. `Component.onCompleted: back.source = ...` is required - the
    binding already has a value when the object is built, so
    `onWallpaperChanged` never fires for the first picture.

79. **A theme is a NAMED LIST OF PICTURE PATHS, not a folder** (user, agreed
    on https://claude.ai/code/artifact/456e3bcd-35b9-4db6-a3a6-1a4e7ec7a816).
    It remembers paths, so the same picture can be in two themes, pictures can
    be gathered from anywhere on disk, and deleting a theme deletes nothing.
    A folder could not express "gather from many places" without moving the
    user's files, which is not a trade worth making.

    Three pieces of state in `config/themes.json` and no more: `themes`,
    `selected` (or ""), `wallpaper` (or "" = no wallpaper at all).

    Keys: SUPER+S is the themes; SUPER+A is the pictures - of the selected
    theme, or of EVERY theme when nothing is selected. Pressing the selected
    theme again unselects it, and the wallpaper on screen STAYS: unselecting
    changes what you are browsing, not your desktop.

    Colour precedence is strict, so there is never a question of which won:
      fixed theme colour  >  current wallpaper  >  nothing changes
    A theme set to `fixed` means changing the picture changes the picture and
    NOTHING else. With no wallpaper there is nothing to read a colour from, so
    the palette is left exactly as it is.
    Both paths run through the same tool - `matugen image <path>` and
    `matugen color hex '#rrggbb'` (verified to exist) - so a fixed colour
    recolours GTK, hyprlock, fuzzel and kitty exactly as a wallpaper does.

    **Naming a theme and choosing its colour happen IN THE BAR.** `yad --entry`
    and `yad --color` were tried and rejected by the user: this shell is built
    so everything happens in the island - the launcher, the Wi-Fi password, the
    screenshot - and a floating window to type six letters breaks the one rule
    it keeps. Naming reuses the same TextInput pattern as the launcher (read
    `text + preeditText`, fact 30). The colour is a hue rail showing the SHADES
    matugen would build, with `Theme.previewAccent` recolouring the island live
    while the handle moves - matugen itself runs ONCE, on commit, because
    running it per frame is not viable.
    Only `yad --file --multiple` remains, for adding pictures: that is browsing
    a filesystem, and rebuilding a file manager inside a 44px bar would be
    worse than the dialog. custom/rules.lua floats it.

    Migration ran once: the old folder became a theme keeping its name, already
    selected, so nothing the user had arranged disappeared.

    `font.pixelSize` is an INT - 11.5 fails the whole config to load.

80. **A migration must never save on failure.** `migrate()` parsed a FileView
    that had not loaded yet, threw, set `themes = []`, and that empty list was
    then written over a perfectly good theme file - the migrated theme vanished.
    The migration now lives in the LEGACY file's own `onLoaded`, and its catch
    branch returns without saving anything.

81. **A `FileView` with a `path` loads EAGERLY - it does not wait to be asked.**
    The legacy `wallpaper.json` view was only ever meant to be read when
    `themes.json` failed (`onLoadFailed: legacy.reload()`), but having a `path`
    at all made it load on every start and run the migration alongside a
    perfectly good themes file. Two loaders then assigned `root.themes` in an
    order neither controlled, and the theme was sometimes wiped. Fix: `path: ""`
    and set the real path inside `onLoadFailed`. A one-shot reader must have NO
    path until the moment it is needed.

82. **Never swallow an exception in a `FileView.onLoaded`.** The catch there was
    commented "a half-saved file is normal" and hid a genuine fault for two
    sessions: the load threw, nothing was applied, and the only symptom was
    state that quietly did not change. It now `console.warn`s and the watcher
    still re-reads.

83. **The `activewindow` dismiss guard only suits panels that hold EXCLUSIVE
    keyboard focus.** For the launcher and control centre a window taking focus
    can only mean the user went elsewhere - nothing else could have taken it
    from us. The wallpaper picker and the themes take no keyboard focus, so
    ordinary focus churn is not a signal about them: MEASURED, an `activewindow`
    arriving ~0.5s after opening the themes closed the panel on its own, every
    single time. `dismissArea` is what dismisses those two.

84. **A `Row` does not compute its own `baselineOffset`.** So
    `anchors.baseline: someText.baseline` on a Row puts the Row's TOP on that
    baseline, not its text's baseline - the theme card's picture count fell off
    the bottom of the card. Use `anchors.verticalCenter` between the two.
    (Related to the older fact that `anchors.baseline` on a Row's CHILD is
    ignored - a Row and baselines simply do not mix.)

85. **REMOVED 2026-09-03, kept as a record.** Themes are gone (see
    `06-decisions.md`); what follows is the shape they had, for if they are
    ever wanted back. Facts 81-84 and 86 are still live.

    Wallpaper and themes were two panels with two libraries, and exactly one
    owned the desktop. Designed on the web first:
    https://claude.ai/code/artifact/ba23a0a0-63b1-470b-8ad2-634bf55ffb80
    - `Wallpapers.library` is the picker's OWN pictures. It used to show the
      union of every theme's pictures, so the picker was empty until a theme
      existed and showed pictures filed under a theme you were not using.
    - `Wallpapers.select(id)` PUTS A PICTURE UP (the theme's first). Without
      that half, select and deselect looked identical: the mark moved, the
      screen did not - which is exactly what the user reported.
    - `Wallpapers.apply(path)` clears `selected`. Picking is itself the claim.
    - `Wallpapers.locked` = a theme holds the desktop. The picker then dims,
      `enabled: false` on one parent Item makes every cell inert, and a bar
      names the theme with one "Take it back" button. A dead panel with no way
      out is a trap.
    - The THEMES panel is never locked: it is the only place a theme can be
      built, and locking it would stop you building one while you use a loose
      picture, which is the normal way to build one.
    - `IslandState.wallpaperOpen` / `themesOpen` are separate, and
      `wallpaperView` became `themesView`. As one flag with a view string,
      SUPER+A and SUPER+S landed wherever the other key had left the panel.

86. **QML swallows a call to a function that does not exist.** The big
    "New theme" card called `Wallpapers.addTheme()`, replaced by the naming
    sheet and defined nowhere. No error reached the log; the card simply did
    nothing while the header button beside it worked. When a control is inert,
    grep the handler's callee before theorising about hit testing.


87. **An empty `Image.source` never reaches `Image.Ready`.** WallpaperLayer
    crossfades by handing the new picture to `front` and fading it in
    `onStatusChanged`. Clearing the wallpaper handed it `""`, which goes to
    `Image.Null`, so the fade never started, its `onFinished` never ran, and
    `back` kept the old picture on screen forever - "No wallpaper" looked
    completely inert while the state underneath had changed correctly. Clearing
    needs its OWN animation, fading `back` out, because there is nothing to
    fade in.

88. **The wallpaper picker is FOLDER-based, and that is the second time it has
    been decided.** `Qt.labs.folderlistmodel`'s `FolderListModel` does it with
    no process at all: bind `folder`, set `nameFilters`, `showDirs: false`, and
    a Repeater takes it directly (`required property string filePath`). It
    watches the directory, so a picture dropped in appears without a rescan.
    `Wallpapers.roots` is every folder it knows, `folder` the one being
    browsed, `current` the picture up. The header chip is both the label and
    the way into the folder list - the user singled that control out as the
    part they liked.

    Adding pictures one at a time (the themes-era model) was rejected: "hiện
    tại thì wallpaper không phải chọn thư mục mà lại thành thêm ảnh". A folder
    the user already keeps wallpapers in is the unit they have.


89. **Use the XDG PORTAL for file dialogs, not `yad`.** The user compared the
    browser's upload dialog with dynisle's folder chooser and asked for the
    former. The browser's is `xdg-desktop-portal-gtk` - decorated, rounded,
    themed and sized by the toolkit. `yad` can never match it: with no header
    bar GTK draws it square and titleless, and yad has no option for one.

    `scripts/pick-folder` calls
    `org.freedesktop.portal.FileChooser.OpenFile` with `directory: true` and
    prints one path per line. Two things it gets right that are easy to get
    wrong:
    - SUBSCRIBE to the Request's `Response` signal BEFORE calling, on the path
      derived from `handle_token` and the bus's own unique name
      (`/org/freedesktop/portal/desktop/request/<unique_no_dots>/<token>`).
      Subscribing after the call is a documented race.
    - The portal returns URIs; convert with `GLib.filename_from_uri`, never by
      slicing off `file://` (percent-encoding).

    It needs a Hyprland rule of its own: the browser's dialog floats because it
    is a MODAL of the browser window, ours passes `parent_window: ""` and comes
    up as a plain toplevel, so Hyprland TILED it against the screen edge with
    half of it off-screen. `custom/rules.lua` floats and centres class
    `xdg-desktop-portal-gtk` at 900x620.


90. **`focus: true` on a panel root is NOT enough - call `forceActiveFocus()`
    on the next turn.** MEASURED: the wallpaper panel had `focus: true`,
    `activeFocus` stayed FALSE and no key event ever arrived, so
    `Keys.onEscapePressed` could not fire. The control centre appears to work
    without it only because a CHILD of it holds activeFocus and Escape
    propagates up to its root; a panel with nothing focusable inside it gets
    nothing. Island's `onPanelChanged` now calls
    `panelLoader.item?.claimFocus?.()` for every panel in `wantsKeyboard`, not
    just the launcher, and each such panel exposes
    `function claimFocus() { root.forceActiveFocus(); }`.

91. **hypridle's `lock_cmd` meant NOTHING EVER LOCKED.** Inherited from
    end4-pC, it read:
    `hyprctl dispatch 'hl.dsp.global("quickshell:lock")' & pidof qs quickshell hyprlock || hyprlock`
    which the shell parses as `A & (B || C)`. `pidof qs` SUCCEEDS because qs is
    running, so `|| hyprlock` was skipped - and the global it dispatched,
    `quickshell:lock`, exists only in end4-pC's shell. So the idle timeout, the
    lid switch and `loginctl lock-session` all silently did nothing. Now
    `pidof hyprlock || hyprlock`, which was sitting commented out on the very
    next line. Backup: `hypridle.conf.bak-*`.

92. **The session panel is SUPER+S, its own panel, four actions.** Designed on
    the web first:
    https://claude.ai/code/artifact/1fa44bf8-3932-41ef-9533-3a83081accd3
    - Lock -> `loginctl lock-session`, never `hyprlock` directly, so hypridle's
      idle lock, the lid switch and this all reach one screen and logind
      guarantees a single hyprlock.
    - Sleep -> `systemctl suspend` ALONE. hypridle already holds
      `before_sleep_cmd = loginctl lock-session`, so locking here too would
      race two hyprlocks for the same screen.
    - Restart / Shut down -> `systemctl reboot` / `poweroff`, and both ARM on
      the first press and run on the second. The key hint under the tile
      becomes "Press again" in the same place, so nothing moves. Disarms on
      moving to another tile, on Escape, or after 3s.
    - `Quickshell.execDetached`, not `Process`: a Process is a child of the
      shell, and reboot/poweroff kill the shell.
    - NO Hibernate: swap is `/dev/zram0` only - compressed RAM - and logind
      answers `CanHibernate = "na"`. NO Log out: one session, one shell.
    - Keep awake deliberately stays in the control centre.


93. **`ignore_alpha` is a threshold BELOW WHICH HYPRLAND SKIPS BLUR.**
    `hyprland/rules.lua` sets it to 0.79 for every `quickshell:.*` layer, tuned
    for ii's near-opaque panels. The island's own fill is 0.88 and blurs fine;
    the session veil is a 0.5-alpha black sheet and fell UNDER the threshold, so
    it dimmed the screen (measured: mean luminance 75.8 -> 34.4) while leaving
    the text behind it perfectly sharp. `custom/dynisle-blur.lua` now sets
    `ignore_alpha = 0.3` for `quickshell:dynisle` alone, and loads last so it
    wins.

    0.3 and NOT 0: the island window is a full-screen TRANSPARENT canvas, and
    at 0 Hyprland would blur the entire screen permanently. The threshold has to
    sit between "the transparent canvas" and "the veil".

94. **The leaving veil: feedback for a command that takes seconds.**
    `systemctl suspend` does not bite for a second or two, and nothing moved on
    screen meanwhile - the user pressed Sleep, saw nothing, and the machine went
    dark later for no visible reason.

    `IslandState.leaving` is "" | "sleep" | "restart" | "shutdown" and OUTRANKS
    every panel in the priority chain: nothing may be raised in front of a
    machine on its way out. The panel calls `beginLeaving()` first and a Timer
    fires the actual command `animDuration + 320` ms later, so the veil has
    faded in and the island has finished growing before anything happens.

    The veil is drawn INSIDE the island window - which is already full-screen,
    transparent and masked - so the "only three files make windows" rule holds.
    It is added to the mask while visible, so nothing behind it can be clicked.

    Sleep is the only one the machine returns from, so it is the only one with a
    4s clear timer. Qt timers use the monotonic clock, which does not advance
    across a suspend, so it fires shortly AFTER resume rather than during -
    by which time hyprlock is already covering the screen (hypridle's
    `before_sleep_cmd`). Restart and shutdown hold the veil until the machine is
    gone.

95. **The wallpaper grid is keyboard-driven.** `cursor` is an index into
    1 + picture count (cell 0 is "No wallpaper"), or roots + 1 in the folder view
    (the last is the Add card). Left/Right move by one, Up/Down by
    `Theme.wallColumns`, Enter does exactly what tapping the live cell does, and
    `reveal()` scrolls the Flickable only as far as it must - without it a
    cursor moved with the keys walks off the bottom into the clip and vanishes.
    HOVER WRITES TO `cursor` TOO, so the pointer and the keys can never disagree
    about which cell is live. The cursor ring is text-coloured; the accent ring
    plus check badge means "this is your wallpaper" and only one cell may claim
    that.


96. **A Timer inside a panel DIES WITH THE PANEL.** The session panel fired its
    command from a Timer of its own - but the first thing `beginLeaving()` does
    is close the session panel, so the Loader destroyed the panel, and the
    Timer with it, before it could ever fire. The veil came up, NOTHING RAN, and
    four seconds later it faded away: the user reported exactly that ("có
    animation nhưng nó không sleep"). Anything that must outlive the thing that
    started it belongs in a singleton. The commit Timer now lives in
    `IslandState`.

97. **`margins.top` moves the SURFACE, so a full-screen veil cannot paint above
    it.** The island sits at `margins.top: Theme.screenGap`, so `hyprctl layers`
    reports it at `xywh: 0 7 1366 768` - and the veil left a bright strip of
    wallpaper across the top 7 pixels, which the user spotted immediately
    ("nó chưa full screen"). The margin is now zeroed while
    `IslandState.centred`, and the shape's own `y` puts the gap back when it is
    a bar, so nothing moves visually. Verified: row y=0 luminance 30.1, same as
    the rest of the veil.

98. **The island TRAVELS, so the shape uses a `y` binding, not `anchors.top`.**
    Both bookends put it in the middle of the screen:
    - `IslandState.greeting` is true at startup for 2600ms: a big
      "Welcome, <user>" pill in the centre over a blurred screen, which then
      rides up into the bar and becomes the clock.
    - `IslandState.leaving` sends it back down to the centre to say
      "Sleeping" / "Restarting" / "Shutting down".

    `IslandState.centred` drives the shape's `y`, the veil's opacity and the
    window's top margin together. The `Behavior on y` is 560ms, not
    `animDuration` - at 150ms crossing the screen read as a jump, not a
    journey. The commit delay is 900ms so the island has LANDED before the
    machine stops responding.

    The greeting fires on every `qs -c dynisle` start, which is what "when the
    machine comes up" means here since the shell autostarts at login - but it
    also means it plays on every dev restart.


99. **Sleep fires ~200ms after the press, and the journey finishes on the way
    BACK.** The commit delay was 900ms so the island could reach the middle of
    the screen before suspending, and that read as a machine that ignored you
    and went to sleep later for reasons of its own ("phải một lúc sau nó mới
    sleep"). MEASURED end to end with a marker file: 228ms from the keypress to
    the command leaving. The travel animation now plays INTO the suspend and is
    cut off by the screen going dark, which nobody sees.

100. **Resume is an event, not a poll - but the greeting has to wait for the
     LOCK SCREEN, not for the resume.** hypridle's `after_sleep_cmd` now
     dispatches `quickshell:dynisleWoke` (it pointed at `quickshell:lockFocus`,
     another end4-pC-only global, so it did nothing). `wokeUp()` drops the veil
     and sets `pendingGreeting`.

     It must NOT greet immediately: `before_sleep_cmd` locked the screen, so
     hyprlock is on top and the whole 2.6s greeting would play and finish
     behind it while the password was still being typed.

     And hyprlock CANNOT be watched by event. MEASURED: Hyprland does emit
     `openlayer` / `closelayer` with the namespace (verified with fuzzel, which
     is `launcher`), but hyprlock is an `ext-session-lock` client and not a
     layer surface at all - and it is hypridle's child, not ours, so it cannot
     be waited on either. So `pidof hyprlock` is polled at 800ms, and ONLY
     between waking and unlocking.

     A second, independent guard exists because the first rests on one config
     line in another program: while `leaving === "sleep"`, a 2s timer compares
     `Date.now()` deltas. Qt timers run on the monotonic clock, which does not
     advance across a suspend, while the calendar does - so a gap far larger
     than the interval IS the suspend. Without this, a failed `after_sleep_cmd`
     would leave the veil up for ever with the whole screen masked and
     unclickable.


101. **The greeting must APPEAR where it starts - gate the Behaviours with
     `IslandState.snap`.** With `Behavior on y` and the veil's
     `Behavior on opacity` always live, the island flew DOWN from the bar and
     back up (a round trip, not a welcome), and on a resume the desktop was
     visible for those frames - the user saw their own open tabs before the
     blur arrived. `snap` is true for 90ms at launch and again at the start of
     every greeting; both Behaviours carry `enabled: !IslandState.snap`, so the
     first assignment PLACES and everything after ANIMATES.

102. **Startup work that is not the animation waits for it.**
     `Island.warm` is `!IslandState.greeting`; the `SystemNotify` touch and the
     launcher's icon pre-decode are both gated on it. Decoding a screenful of
     icons on the first frames is what the greeting was competing with.

103. **The centred island is rounder.** `IslandShape.radiusHint` lets a panel
     ask for its own corner (still capped at `height / 2`); the leaving panel
     asks 38 and the greeting 42, because in the middle of the screen the
     island reads as a card, not a strip.

104. **neofetch: black-hole ASCII, run from `.zshrc`.**
     `~/.config/neofetch/blackhole.txt` (a hollow ring - block characters for
     the accretion disk, spaces for the event horizon) plus a trimmed
     `config.conf`. MEASURED: neofetch did NOT pick up
     `~/.config/neofetch/config.conf` on its own here even though
     `XDG_CONFIG_HOME` is `/home/toast/.config`, so `.zshrc` passes both
     `--config` and `--source` explicitly.

     The zshrc guard is `[[ -o interactive && -t 1 ]]` - BOTH, because a fetch
     printed into a pipe corrupts whatever is parsing it.


105. **The veil must be CONTINUOUS across a resume - the poll decides when the
     countdown starts, not when the greeting appears.** `wokeUp()` used to
     clear `leaving` at once while the greeting waited for a `pidof hyprlock`
     poll to notice the lock had gone. In between there was nothing over the
     screen, so waking read as: sleeping -> YOUR BARE DESKTOP -> blur ->
     welcome, which is exactly what the user reported.

     Now `wokeUp()` turns the greeting on and the leaving state off in ONE
     step, and only stops the greeting's own timer. The greeting is drawn
     immediately, behind hyprlock where nobody can see it; the poll's only job
     is to restart `greetingTimer` once the lock is gone, so a late poll costs
     a moment of "Welcome" instead of a moment of bare desktop.

     ORDER MATTERS in `wokeUp()`: `centred` is an OR of `greeting` and
     `leaving`, so the greeting goes on BEFORE leaving goes off. The other way
     round, `centred` is false for one notification and the veil starts fading.

     The poll gives up after 300 ticks (~3 min) rather than spawning `pidof`
     for ever if nobody comes back.

106. **A dangling `Timer` id throws on every call and QML carries on.**
     `beginLeaving()` called `leavingTimer.restart()` after that Timer had been
     deleted; it threw a ReferenceError on every single sleep, and was harmless
     ONLY because it happened to be the last statement in the function. When
     deleting a Timer, grep its id.


107. **`margins.top` is 0 FOR EVER; the bar's gap is paid by the shape's `y`.**
     The margin moves the whole surface, so any non-zero value means the veil
     cannot paint the top `screenGap` pixels - and TOGGLING it was worse than
     leaving it, because the surface jumped the moment the veil released. That
     jump is the "blur bị hở một chút trên cùng" in the middle of the
     greeting's exit. `exclusiveZone` carries the gap instead
     (`islandMinHeight + screenGap * 2 - compositorGapsOut`); MEASURED both
     ways, `hyprctl monitors` reports `reserved [0, 49, 0, 0]` either way, and
     the layer is now `xywh: 0 0 1366 768`.

108. **The greeting leaves in TWO BEATS, and the corner eases.** As one beat,
     `greeting` went false and the Loader swapped the panel on that same frame:
     the text vanished instantly while the box, the corner and the veil all
     changed underneath it - three simultaneous jumps, which is what the user
     described. Now `greetingFading` holds for 260ms (VERIFIED: two logged
     transitions 263ms apart) while the words fade and scale out, and only then
     does `greeting` go false and everything move. `IslandShape` also has a
     `Behavior on radius`, or the corner pops the instant a panel with its own
     `radiusHint` is swapped away.

     `grim` takes ~0.7s per frame on this machine and CANNOT resolve a 260ms
     transition - two log lines are the proof here, not screenshots.

109. **The veil's opacity animates again, always.** It was gated on
     `IslandState.snap` to stop a resume flashing the desktop; that is no
     longer needed since the veil is held up continuously across a resume
     (fact 105), and on a cold start the blur arriving over half a second is
     the point. `snap` now gates the shape's `y` only.


110. **`blur:new_optimizations = false` DISABLES LAYER-SURFACE BLUR ENTIRELY
     on Hyprland 0.56.2.** This was my own line, added to dodge a stale blur
     cache, and it silently cost the whole feature: dynisle IS a layer surface,
     so the island and its full-screen veil dimmed the screen and blurred
     nothing at all. MEASURED - edge energy 9.19 veiled vs 9.29 clear, and text
     behind the veil stayed READABLE at 85% black; with it on, 6.74 vs 14.20
     and an unreadable wash.

     It hid for a long time because a dark, smooth desktop dims to a low edge
     score anyway - I read 2.37 as "blurred" when the unveiled baseline was
     already 2.79. ALWAYS measure the clear frame of the SAME desktop.

     The stale-cache bug it was guarding against is really xray, so that is
     handled directly now:
     `hl.layer_rule({ namespace = "quickshell:dynisle", xray = false })`.
     `hyprland/rules.lua` turns xray on for EVERY namespace (`.*`) and the
     global `decoration:blur:xray = false` does NOT override a per-layer rule.

111. **The veil is a CURTAIN, not a fade.** `ignore_alpha` is the threshold
     below which Hyprland skips blur, so animating the veil's opacity up from 0
     spends the first third of every fade UNDER it: the screen goes
     see-through with every window sharp, then the blur pops in. Constant
     `opacity: 0.5` with an animated `height` keeps the alpha above the
     threshold for every pixel that is ever drawn.

112. **The greeting takes the hover latch on its way out.** Same rule as every
     panel: without `hoverLatched = hovered`, a pointer resting on the greeting
     box counted as hovering the island the moment it closed, and the priority
     chain fell through to "expanded" - the media panel flashed up before the
     clock.


113. **NEVER gate anything that blocks input on a signal that might not
     arrive.** The greeting waited for `pidof hyprlock` to come back empty
     before it would start ageing. On this machine HYPRLOCK DOES NOT RELIABLY
     EXIT after a successful unlock - pid 18240 was still alive while the user
     was typing normally, which is also the fault behind their long-standing
     "right password, still locked out". So the poll never succeeded, the
     greeting never ended, and its veil - which masks the WHOLE SCREEN - stayed
     up for ever. The user was locked out of their own machine and had to say
     so in chat.

     The countdown now starts on a fixed delay and on nothing else. Greeting
     played behind a lock screen is a cosmetic loss; that was not.

     Two independent escape hatches were added on top, because this thing masks
     everything: a full-screen MouseArea (in the input mask) and ANY KEY, not
     just Escape - someone trying to get their machine back should not have to
     guess. VERIFIED by driving it: `wtype -k a` logs the key reaching the
     panel and `endGreeting` taking `greeting` true -> false, `centred` false.

114. **A layer surface that asks for Exclusive keyboard focus AT BIRTH never
     gets it.** The greeting is on screen from the shell's first frame, so
     `wantsKeyboard` was true from the start - MEASURED: the binding was true,
     the panel had `activeFocus`, and NOT ONE KEY arrived. Hyprland acts on the
     None -> Exclusive TRANSITION, and there was none. A 200ms timer that flips
     the flag on afterwards fixes it, and keys arrive.

     Related to fact 90 but distinct: 90 is Qt-side focus, this is
     compositor-side.


115. **The lock screen: `~/.config/hypr/hyprlock.conf`, rebuilt 2026-09-03.**
     Designed on the web first:
     https://claude.ai/code/artifact/52e1a456-ab57-4440-b31a-ec5f7606d726
     - `path = $background_image` - matugen had been generating it all along
       while the config painted a flat `#181818` and ignored it.
       `blur_passes = 4`, `blur_size = 9`, `brightness = 0.62`.
     - Clock, date, and ONE input-field: `outline_thickness = 0`,
       `inner_color = rgba(0000004D)` (darker than the blurred backdrop),
       `rounding = 29` = height/2, a true pill. hyprlock cannot blur a widget,
       so "a blurred box" is a dark translucent fill over an already-blurred
       background - which is the same thing to look at.
     - The `$USER` label is gone, and so are the two labels that called
       `status.sh` and `check-capslock.sh`, neither of which exists here.
       Caps lock and failures are `input-field`'s own `capslock_color`,
       `fail_color` and `fail_text = <i>$FAIL · $ATTEMPTS</i>`. The attempt
       count matters: `pam_faillock deny=3` locks `sudo` too.
     - Backup at `hyprlock.conf.bak-*`.

116. **How to preview hyprlock WITHOUT risking a lockout.**
     `hyprlock --grace 90` locks but accepts any input as an unlock for 90s.
     NEVER `pkill` an `ext-session-lock` client to escape - if it dies without
     unlocking, the compositor is entitled to stay locked with nothing to type
     into. When input did not release it (`wtype` was ignored), what worked was
     `loginctl unlock-session`. Keep that command to hand before starting.

117. **Sleep fires 1.5s after the press, not 200ms.** The island's journey to
     the middle takes 560ms; firing at 200ms suspended it MID-FLIGHT, so the
     screen died before the machine had finished saying what it was doing, and
     that read as a delay rather than an answer. MEASURED end to end at 1477ms.

118. **The greeting's words shrink WITH the box.** Fading the text out first
     and collapsing the box after was tried and rejected by the user - the
     words are part of the box. `GreetingPanel` animates its own
     `implicitWidth`/`implicitHeight` down (the shape measures its content, so
     that IS the box shrinking) while the Row scales on the same curve and
     duration.

     THE RULE THAT MAKES IT WORK: everything in this transition runs for
     exactly `Theme.islandTravel` (560ms) on `Theme.islandTravelEasing`. The
     shape's `y`, the panel's `implicitWidth`/`implicitHeight`, the words'
     `scale`, and the timer that finally swaps the panel are all the same
     number. Three attempts failed on mismatched clocks, each fix creating the
     next fault:
       - shrink 300 / rise 560, both from the start -> the clock was swapped in
         MID-FLIGHT and the island appeared to stall;
       - shrink in place 300, then rise 560 -> the words left first and the box
         followed, which is not one object;
       - one duration for all three -> the box, its words and the journey are
         literally the same animation on different properties.

     The words hold full opacity for the first 62% and fade over the last 38%,
     so they stay legible while travelling instead of dissolving on frame one.
     The panel shrinks to exactly `Theme.islandMinWidth` x `islandMinHeight`,
     so the swap for the clock resizes nothing and is invisible.
     `islandRadius: 48` is half the greeting's height, so `min(hint, height/2)`
     tracks the shrink all the way down to the pill's own corner with nothing
     to animate separately.

     AND THE FOURTH FAULT, which none of the above touched: the box did not
     shrink AT ALL while rising. `IslandShape.implicitWidth` is
     `Math.max(root.minWidth, childrenRect.width + paddingH * 2)`, and
     GreetingPanel declared `islandMinWidth: 520` - a FLOOR. Nothing done to the
     panel's own size could get under it, so the box stayed 520 wide until the
     panel was swapped, and the only shrink anyone ever saw was that swap.
     `islandMinWidth` and `islandPaddingH` now collapse to the bar's values the
     moment the greeting starts leaving.

     Second half of the same fault: `IslandShape` animates its own width and
     height at `animDuration` (150ms), so even once the floor was gone the
     shrink finished in 150ms and the remaining 400ms of the rise happened at
     the final size. Those two Behaviours now run at `Theme.islandTravel` while
     `IslandState.greetingFading`. The panel has NO size Behaviours of its own -
     two animations on one journey only fight.

     `grim` takes ~0.5s per frame on this machine and CANNOT resolve a 560ms
     transition - matching durations by construction is the guarantee here,
     not a screenshot.


119. **The sleep path is now: animation, then the command. Nothing else.**
     Everything that had accreted around it was deleted - a wall-clock suspend
     detector (`sleepGuard`, `lastTick`), a resume hook (`wokeUp`), a
     `pidof hyprlock` poll (`lockWatch`, `lockProbe`), a `pendingGreeting`
     flag, and a `Quickshell.Io` import that only the poll needed. Every one of
     them was added to patch the previous one, and the last locked the user out
     of their own screen.

     `beginLeaving()` sets the state, starts `commit` (fires the command at
     `islandTravel + 940`), and starts `release` - which drops the veil
     UNCONDITIONALLY at `islandTravel + 3000`. By then the screen is off or
     locked so nobody sees it, and on the way back there is nothing left over.
     Nothing waits for the machine to return, because the veil masks the whole
     screen and anything it waited on could fail to arrive.

120. **The greeting is driven by the UNLOCK, not by the resume.**
     hypridle's `$lock_cmd` is now
     `pidof hyprlock || { hyprlock; hyprctl dispatch 'hl.dsp.global("quickshell:dynisleUnlocked")'; }`
     so the global fires when hyprlock EXITS - the moment the password was
     accepted. Resume is the wrong moment: the lock screen is still up.
     hypridle has NO `unlock_cmd` (checked: it knows only `on-resume` and
     `on-timeout`), so hyprlock's own exit is the signal.

     If hyprlock ever fails to exit, the global never fires and there is simply
     no greeting. That is the point: the failure mode is a missing animation,
     never a masked screen.

     `after_sleep_cmd` no longer talks to dynisle at all.

121. **The boot audio gap: easyeffects starts BEFORE pipewire.** MEASURED from
     the boot journal - kernel bound the codec at 18:27:27, easyeffects started
     at 18:27:38, pipewire at 18:27:39. pipewire is SOCKET-ACTIVATED, so it
     only starts when something connects; easyeffects, launched from
     `hyprland/execs.lua`, was that something. It created `easyeffects_sink`
     and took the default before its own pipeline could carry audio, so
     anything playing in that window went nowhere - "phải chờ một lúc thì nhạc
     mới nghe được", on every boot.

     `execs.lua` now starts pipewire/pipewire-pulse/wireplumber explicitly and
     waits for `pactl info` to answer before launching easyeffects.

     Also found there: `rtkit` IS NOT INSTALLED, so the boot log is full of
     `RTKit error: ServiceUnknown` and pipewire runs without realtime priority.
     Needs `sudo pacman -S rtkit`.

     And the two `wl-paste` watchers were calling
     `qs -c dynisle ipc call cliphistService update`, an ii handler dynisle
     does not have - a process spawned and failed on EVERY copy. Removed; the
     `cliphist store` half is kept.


122. **WRONG, CORRECTED BY FACT 124 - DO NOT ACT ON THIS ONE.** I concluded
     from missing journal lines that the hardware was at fault. Hard power-offs
     lose buffered log, so absent lines proved nothing, and the user said the
     freeze happens EVERY time, not occasionally. The original text:

     `deep` SUSPEND IS UNRELIABLE ON THIS MACHINE, AND IT IS NOT DYNISLE.
     The frozen-on-wake report was chased to the journal, and the previous
     boot's log ENDS on `kernel: PM: suspend entry (deep)` with nothing after
     it - no `suspend exit`, no device restore, nothing. The kernel never came
     back. What is on screen afterwards is the last framebuffer contents, which
     is why it looks like dynisle's veil is stuck.

     Counted across boots: -3 suspended 6 times and resumed 6; -2 suspended 9
     and resumed 8; -1 suspended once and resumed none. So it works most of the
     time and then does not. Asus TP300LA, BIOS 205, Broadwell.

     `/sys/power/mem_sleep` offers `s2idle [deep]`. s2idle does no firmware
     handoff and is far more likely to survive; it costs battery. Needs root,
     so it is the user's call:
       one session: `echo s2idle | sudo tee /sys/power/mem_sleep`
       permanent:   kernel cmdline `mem_sleep_default=s2idle`

     DO NOT attribute a frozen wake to shell code again without checking for
     `PM: suspend exit` first.

123. **EasyEffects was the boot audio bug, and reordering startup did not fix
     it.** It SEIZES THE DEFAULT SINK: `pactl info` reported
     `Default Sink: easyeffects_sink`, and the control centre showed 0% on a
     device named "Easy Effects Sink" that would not turn up. The problem is
     not when it starts, it is that it takes the default output before its own
     pipeline carries audio. It was inherited from ii/end4 and never asked for,
     so `hyprland/execs.lua` no longer starts it - the real hardware sink stays
     the default, where the volume sticks. The line is left commented with
     instructions to restore it.


124. **The machine DOES resume - and then something suspends it again.** The
     one resume with a complete log reads:

         18:26:37.573  PM: suspend exit
         18:26:41.664  hyprlock: auth: authenticated
         18:26:41.779  hyprlock: Unlocked, exiting!
         18:26:47.430  systemd-logind: suspend requested from client
                       PID 7717 ('systemctl')
         18:26:47.430  The system will suspend now!

     Six seconds after a SUCCESSFUL unlock, something asked logind to suspend
     again. hypridle is ruled out: it logs every command it runs and that boot
     it ran only `pidof hyprlock || hyprlock` (12x), `loginctl lock-session`
     (6x) and the `dynisleWoke` dispatch (5x) - never `$suspend_cmd`. Grepped
     dynisle: `Session.sleep()` is its ONLY `systemctl suspend`, and there is no
     battery auto-suspend of the kind end4-pC has in `services/Battery.qml`.

     THE MECHANISM IS STILL UNPROVEN. So rather than invent one,
     `Session.sleep()` now REFUSES a second request within 45 seconds of the
     last, on `Date.now()` - the wall clock, which unlike Qt timers advances
     across a suspend. And every session action is appended to
     `~/.cache/dynisle/session.log` with a timestamp, so the next occurrence is
     evidence instead of an argument.

125. **PARTLY REVERSED - see fact 127.** The hooks were removed while the
     sleep freeze was unexplained and every moving part was suspect; the cause
     turned out to be fact 126, not these. The original text:

     dynisle is OUT of the lock, sleep and resume path. Both hooks it had
     there are gone - `after_sleep_cmd` (fired 5x per resume) and an unlock
     global on `$lock_cmd`. `$lock_cmd` is back to the plain
     `pidof hyprlock || hyprlock`; my version ran hyprlock in the foreground of
     hypridle's spawned shell and kept a process alive for the whole lock just
     to trigger an animation.

     Weighing that: during a test I locked the screen by accident and
     `loginctl unlock-session` did NOT release hyprlock - twice - it needed
     `pkill`. That is the user's long-standing "right password, still locked
     out". The lock path is the fragile part of this machine, and an animation
     is not worth a moving part inside it. The greeting plays at shell start
     and nowhere else.


126. **NEVER MAKE THE LOCK SCREEN DO GPU WORK - IT RUNS INSIDE THE SUSPEND
     WINDOW.** This is the fault that froze the machine on every single sleep,
     and it was mine.

     `before_sleep_cmd = loginctl lock-session` starts hyprlock while systemd
     is already tearing the session down. My lock config had it load a
     1672x941 PNG and run `blur_passes = 4`, `blur_size = 9`, plus noise and
     vibrancy, on a Broadwell HD 5500 at exactly that moment. The kernel
     wedged: screen stuck with the lock half-drawn over the fading sleep
     island, and the sound card LOOPING its last DMA buffer - which is what a
     machine that has stopped scheduling sounds like, and was the clue that
     said "hang while going down", not "failed to come back".

     Nothing is ever logged for this, because a wedged kernel cannot log. The
     absence of `PM: suspend exit` had nothing to do with hardware.

     The fix is the one mature configs use: bake the background ONCE, when the
     wallpaper changes. `scripts/lock-wallpaper` writes
     `~/.cache/dynisle/lock.png` - downscaled to the screen, blurred, darkened,
     grained - in about 2 seconds of CPU at a moment with nothing at stake, and
     `Wallpapers.recolour()` calls it alongside matugen. hyprlock draws it flat
     with `blur_passes = 0`, and is up in 52ms (MEASURED, from launch to the
     process existing).

     `$lock_cmd` also passes `--immediate-render` so it does not wait on
     resources in that window.

     RULE: anything hypridle runs from `before_sleep_cmd` must be cheap enough
     to finish in a few frames. Blur, decode and scale belong to whatever
     changes the wallpaper.


127. **The welcome WAITS behind the lock screen, in two stages.** "Instantly,
     already waiting" was the ask, and the only way to get that is to draw it
     while the lock is still up.

     - `after_sleep_cmd` -> `dynisleWoke` -> `IslandState.armGreeting()`. The
       greeting is drawn and the veil is up, but `greetingTimer` is NOT
       running, so it does not age.
     - `$lock_cmd` runs hyprlock and, WHEN IT EXITS, dispatches
       `dynisleUnlocked` -> `startGreeting()`, which only starts the clock.
       `startGreeting` deliberately leaves `greeting` alone if it is already
       true, so nothing blinks or jumps at the moment the lock disappears.

     TWO SAFETY PROPERTIES, both deliberate:
     - `greetingArmed` is excluded from `wantsKeyboard`. The island asks for
       EXCLUSIVE keyboard focus for the greeting, and doing that while hyprlock
       is up risks swallowing the password - which is this machine's own
       long-standing "right password, still locked out".
     - `armCap` (25s) starts the clock regardless. Nothing that covers the
       screen may wait for ever on a message from another program; that mistake
       already locked the user out once.

     MEASURED end to end: armed -> still on screen 4.5s later -> unlock ->
     ages out and rises. Luminance 47.2 / 25.6 / 25.6 / 25.6 / 47.2.


128. **foot follows the wallpaper now.** Its `[colors]` section contained
     nothing but `alpha=0.95`, so foot kept its built-in palette while kitty and
     the shell followed matugen. Added `[templates.foot]` writing
     `~/.config/foot/colors.ini`, and an `include=` at the TOP of `foot.ini` -
     foot only accepts `include` above every section. The section is
     `[colors-dark]`, not `[colors]`: foot deprecated the latter and warned
     about it on every start. Verified with `foot --check-config`, which is now
     completely silent (it used to print the deprecation).

     foot wants bare `RRGGBB`, hence `hex_stripped` in the template.

129. **`CTRL + SUPER + T` is unbound.** It ran end4's `switchwall.sh`, which
     changed the wallpaper and regenerated colours BEHIND dynisle's back:
     `config/wallpaper.json` and the picture actually on screen would drift
     apart, and the lock screen's baked background (fact 126) would never be
     regenerated for the new picture. SUPER + A is the only way in.


130. **Quickshell's `SplitParser` DROPS EMPTY SEGMENTS.** This is why USB
     notifications never worked. `udevadm monitor --property` separates event
     blocks with a BLANK LINE, and the parser was built to flush on one - so
     `flushDevice()` had literally never run and no event was ever completed.

     PROVEN by logging every raw line the parser saw: it received udevadm's two
     header lines and NOT the blank line after them. Nothing else would have
     settled it - the process was alive, `notify-send` worked by hand, and the
     properties looked right.

     Flush on boundaries that DO arrive: a line with no "=" is the next event's
     header (`UDEV [123.4] add /devices/... (usb)`), plus a 150ms idle Timer for
     the last block of a burst.

     Two wrong turns on the way, both mine, both recorded so they are not
     repeated: I "fixed" the hub filter (it was never reached), and I added
     `stdbuf -oL` on a buffering theory that a one-line test then disproved -
     udevadm's header comes through a plain pipe immediately. The stdbuf on
     `pactl subscribe` was reverted with it.

     RULE: before touching the logic that consumes a stream, prove the stream
     arrives. Log the raw lines first.


131. **The greeting and the leaving veil are GONE (2026-09-29).** The user:
     "bỏ cả cái wellcome các thứ đi vì nó vẫn bị lỗi, gập máy xuống là sleep".
     Deleted: GreetingPanel, LeavingPanel, the veil, `centred`/`snap`, the
     `dynisleWoke`/`dynisleUnlocked` globals and both hypridle hooks, the
     `islandTravel` tokens, the `ignore_alpha = 0.3` rule that only existed for
     the veil, and Session.qml's 45s re-suspend guard + log (built on a theory
     fact 126 disproved, and able to refuse a legitimate second sleep). The
     session tiles fire their command BEFORE closing the panel (fact 96).
     Facts 94-105 and 127 describe removed code.

132. **Custom colours use `matugen ... -t scheme-fidelity`.** MEASURED with
     matugen's default `scheme-tonal-spot`: black -> PINK #ffb1c8, grey and
     white -> CYAN #82d3e0 - it forces one colourfulness on every seed. fidelity
     keeps the pick: black -> accent #c6c6c6 on #131313, grey -> grey, white ->
     white. In dark mode the seed's BRIGHTNESS barely matters (dark, mid and
     light blue all land near #aac7ff) - so a black pick gives a black-and-white
     look with a light-grey accent; a literally black accent would vanish.
     The colour view previews the REAL accent via
     `matugen color hex X -t scheme-fidelity -m dark --dry-run -j hex` (~29ms),
     read from `colors.primary.dark.color`. Every swatch is clickable now (only
     the 4th ever counted before) and black/grey/white follow the six shades.

133. **dynisle loads cleanly on Quickshell 0.3.1** - the version Arch's `extra`
     ships, so a new machine needs no AUR. Verified by downloading the package
     (`pacman -Sp` + curl, nothing installed), running a COPY of dynisle on it
     with `QML_IMPORT_PATH` pointing at the package's own qml dir: "Configuration
     Loaded", no QML errors. This machine still runs end4's quickshell-git 0.2.1.

134. **`install.sh`** (repo root). Official repos only - 48 packages, each
     checked with `pacman -Si`. `--collect` copies this machine's configs into
     `dots/`; `--dry-run` prints every step. Tested into a fake $HOME with the
     real colour files hashed before and after (untouched): stray hyprland.conf
     moved to backup, the machine's own monitors.lua kept, every matugen output
     generated, font + lock.png installed, a second run is a no-op for the
     palette. greetd is only configured when no display manager is enabled.

135. **Terminals run FISH, not zsh.** kitty.conf and foot.ini both say `shell
     fish`, so the neofetch hook put in ~/.zshrc never ran. fastfetch (neofetch
     is not in the official repos; it was `unifetch` from chaotic-aur here) now
     runs from fish's config.fish with the black-hole logo.

136. **hyprsunset was not running**, so Night light did nothing (`hyprctl
     hyprsunset temperature` could not connect). `hyprsunset.service` is now
     enabled as a user unit; it answers 6000.


137. **Ghost F10 from this laptop's keyboard, swallowed by Hyprland.** The built-in
     keyboard ("AT Translated Set 2 keyboard", scancode 0x44) fired F10 on its
     own - 28 times in 3 minutes during one episode, then nearly none: it comes
     in waves. F10 threw Chrome's focus to its menu (breaking Telex "ee" -> ê
     mid-word), Shift+F10 opened Discord's context menu, Roblox raised its
     graphics. `custom/general.lua` binds F10 under all 16 modifier combos
     (SUPER included - a SUPER+F10 slipped through the first version) to a
     no-op ONLY when /sys/class/dmi/id/product_name is TP300LAB, so
     Hyprland swallows it here and other machines keep F10. Not caused by any
     program: injected input shows up as its own device, and none sent F10.
     The autoclickers found on the way (GClicker, Toast Clicker, leftovers of
     XClicker and a Flatpak clicker) were removed and ydotoold disabled.
     Kernel-level lock (hwdb `KEYBOARD_KEY_44=reserved`) is a script the user
     runs with sudo, kept outside the repo: ~/.cache/dynisle/f10-off.sh.

138. **Terminal greeting: ray-traced black hole in the middle, hardware left,
     software right** (user, 09-29: "để blackhole ở giữa", the Gargantua
     angle, sides minimal with ONE edge each - no full table).
     `scripts/blackhole-trace.py` ray-traces a Schwarzschild hole + thin disk
     at 84 deg (u'' = -u + 3u^2, first disk crossing wins, photon ring added
     at b = 3*sqrt(3)) ONCE into `scripts/blackhole-map.json` (~5 s, committed).
     `scripts/blackhole.py` paints that map in matugen colours into
     ~/.config/fastfetch/blackhole.ansi - install.sh and
     `Wallpapers.recolour()` run it. `scripts/fetch.py` (fish hook) gets facts
     from `fastfetch --config none --format json` and lays out 3 columns
     (needs ~106 cols; falls back to hole-on-top, then columns only); ~70 ms.
     fastfetch would name fetch.py as the shell, so the shell is read from
     the script's parent process. Text grey, icons white, 90%+ in red.
     Both sides are padded to the same width so the hole sits at the
     window's centre (user, 09-30); no colour-dot row under user@host.
     kitty font_size 11 -> 12 (user wanted text bigger). Plain `fastfetch`
     still shows the older boxed table config.


139. **Log lines that are NOT bugs - do not "fix" them** (checked 2026-09-30
     against the running instance's own log, `qs log -i <id>`, 25 h uptime):
     - `Member data of the object ClippingRectangle_QMLTYPE_n overrides a
       member of the base object` - Quickshell's own
       /usr/lib/qt6/qml/Quickshell/Widgets/ClippingRectangle.qml line 46
       (`default property alias data`). Not our code.
     - `QObject: Cannot create children for a parent that is in a different
       thread` + `installEventFilter(): ... different thread` - once per
       launch, the first app icon (the launcher's pinned icons, pre-loaded
       invisibly in Island.qml with `asynchronous: true`) is loaded on Qt's
       image-reader thread and the
       KDE platform theme (`QT_QPA_PLATFORMTHEME=kde`) sets itself up there.
       Harmless; changing the platform theme would change icon lookup.
     - `QDBusError ... ServiceUnknown` / `Error updating property
       org.mpris.MediaPlayer2.mpv.instance-...` - an mpv window closed while
       its playback position was being read.
     - `Unable to assign [undefined] to bool` at lines that do not match the
       current files = a reload that caught a file half-way through an edit.
       Check the line numbers against the file before believing it.

140. **Launcher icons all grey after `pacman -Syu` = a cached fallback, not a
     broken icon theme** (2026-09-30). Pinned apps with THEME icons showed the
     grey `application-x-executable`; apps whose .desktop `Icon=` is a file
     path (Blender, Steach, Stocking) were fine, and TYPING in the launcher
     showed Firefox etc. correctly - so lookups worked. Qt caches decoded
     images by URL + size + `autoTransform`, and the pre-warm in Island.qml
     holds the pinned ones forever: one lookup mid-upgrade returned the
     fallback and it stuck. Fix: `Launcher.iconEpoch` bumps 15 s after the
     app list stops changing; every launcher `IconImage` sets
     `backer.autoTransform: Launcher.iconKey`, so the icons load again under
     a fresh key (proved with a file swapped on disk: same key -> old image,
     flipped key -> new one). NOT a URL parameter: Quickshell's icon provider
     takes everything after `?fallback=` as the fallback's name.
     Ruled out on the way: rebuilding a hicolor icon-theme.cache under a
     running shell does not lose existing icons (only new ones stay unseen
     by `iconPath(name, true)` until restart); the KDE
     `org.kde.KIconLoader.iconChanged` signal did not clear it.

## If you're about to contradict one of these

Stop and re-read the linked file in full first. If the user is actually
changing a past decision, update the fact here AND in the source file AND add
a dated line to `06-decisions.md` — don't just overwrite silently.
