---
title: Ultra Tasks (UT) — the whole build, 14 tasks
updated: 2026-09-02
---

# Ultra Tasks

**14 tasks, start to finish.** Deliberately coarse — each UT is a meaningful,
visible chunk of work, not a micro-step. Ordered easy → hard, with
dependencies respected over pure difficulty.

## Working rules

- **One UT at a time.** Finish it, then stop and tell the user exactly what to
  run/look at. Wait for feedback before starting the next.
- **Before starting any UT**: restate the real goal → re-read the actual code
  and the relevant vault files → write a short plan → self-critique it for
  bugs → fix the plan → implement.
- **Self-verify first.** `grim` is installed. Screenshot and check your own
  work before asking the user to look (`notes.md` fact 14). Don't spend their
  rounds on things you can confirm yourself.
- **Use subagents/forks to save context** where a task produces bulky tool
  output you won't need again — reading `end4-pC`'s large reference files
  (MPRIS controller, cava scripts, launcher service) is the prime case. Don't
  delegate small work you already have full context for; a fresh agent's
  ramp-up costs more than it saves. User preference, stated 2026-09-01.
- Update this file's status column and `05-session-log.md` as you go.

## Status legend

`DONE` · `NEXT` · `TODO`

---

## Foundation — unblocks everything else

### UT-01 · Restructure `DONE` (awaiting user sign-off)
Split the monolith into: `modules/island/Island.qml`,
`modules/island/IslandShape.qml`, `modules/wallpaper/WallpaperLayer.qml`, and
`shell.qml` reduced to 13 lines of wiring. Zero behaviour change.
**Verified:** `qs.modules.island` / `qs.modules.wallpaper` imports resolve with
**no `qmldir` files** — confirms the Quickshell 0.2 auto-module system works as
documented. Hyprland reports byte-identical surface geometry before and after
(`quickshell:dynisle` at `593 10 180 40`), and a screenshot confirms the island
looks unchanged.
**Deliberately NOT included:** `IslandState.qml` — there are no states to
switch between yet, so an empty singleton would be speculative. It arrives in
UT-05/06 when the state machine is real.

### UT-02 · Theme singleton `DONE` (awaiting user sign-off)
`modules/common/Theme.qml` — `pragma Singleton` + `Singleton` root, owning
surface color/alpha, text colors, accent, radius, screen gap, idle size,
spacing, fonts. `IslandShape`, `Island` and `WallpaperLayer` all read from it;
**zero hardcoded values remain** in those three files.
**Verified objectively:** temporarily set `idleWidth: 300`, restarted, and
Hyprland reported the surface at `533 10 300 40` — width propagated *and* the
layer re-centered on its own. Reverted to `593 10 180 40`. This proves the
chain Theme → IslandShape → Island `implicitWidth` → real layer-shell surface.
**Fonts verified installed** before use (`fc-list`), not guessed:
`Google Sans Flex` for text, `JetBrainsMono Nerd Font` for icons — avoids a
silent fallback. Text/accent/font tokens are included ahead of use because
UT-03 (clock) needs them immediately.

## First real content

### UT-03 · Clock in the idle pill `DONE` (awaiting user sign-off)
`services/DateTime.qml` + `modules/panels/idle/IdlePill.qml`. The pill stops
being empty.
**Scope corrected against the reference:** the idle pill shows the **time only**
— screenshot 01 has no date in it. The date belongs to the expanded week strip
(UT-04). Format is 12-hour with AM/PM (`"h:mm AP"`), by user request.
**Service convention this sets for the other six:** `pragma Singleton` +
`pragma ComponentBehavior: Bound` + a `Singleton` root, and **no
`qs.modules.*` import** — end4-pC's `DateTime.qml` imports `qs.modules.common`
for `Config`, which dynisle's one-way data rule forbids, so format strings live
in the service until a real Config singleton exists.
`SystemClock.precision: Minutes`, not Seconds — nothing shows seconds.
**Test:** time matches the system clock and ticks over on the minute.

### UT-03b · Island behaves like a bar `DONE` (unplanned, user-reported)
Three fixes that came out of the same feedback round:
1. **Reserves space.** `ExclusionMode.Normal`, zone pinned to the *idle* height
   so future expansion grows over the desktop instead of pushing windows down.
2. **Hides on fullscreen.** `Hyprland.monitorFor(screen).activeWorkspace
   .hasFullscreen` → `visible: false`. Verified live with a fullscreen game
   running: the layer reported `a: 0`.
3. **Equal 7px gaps** above and below, via
   `exclusiveZone = idleHeight + screenGap - compositorGapsOut`. See
   `06-decisions.md` for why the subtraction is needed.
**Bug this introduced and fixed:** the wallpaper layer had `exclusiveZone: 0`,
which still *honours* other surfaces' zones — it got shoved down to `0 60 1366
708`, leaving a bare strip. Now `ExclusionMode.Ignore`.

### UT-03c · Blur vs opacity, fixed properly `DONE`
The desktop was using **opacity, not blur**, and the user called it out.
Root cause was **not** in the blur settings at all:
`~/.config/hypr/hyprland/rules.lua` line 7 carried
`hl.window_rule({match = {class = ".*"}, no_blur = true})` — blur was disabled
for **every window**, so `active_opacity 0.88` / `inactive_opacity 0.82` were
the only visible effect: plain see-through, exactly the look `notes.md` fact 1
rejects. Hyprland only blurs what sits behind translucent pixels, so with blur
off, transparency is all that is left.
**Fix:** commented out the global `no_blur` rule, set both opacities back to
`1.0`. Windows are opaque again; blur now actually reaches anything with real
translucency — the island's layer surface, and any app with its own background
alpha. Backups: `rules.lua.bak-*`, `main.lua.bak-*`.

### UT-03d · Visible blur on windows `DONE` (awaiting the user's eyeball)
Blur on windows is invisible while windows are at `opacity 1.0` — fully opaque
means **there is nothing behind them to blur**. That was correct behaviour, not
a bug, but it is not what the user wants to see.
**The trade-off, since it will come up again:** visible blur needs *some*
translucency. Opacity alone = see-through (rejected, fact 1). Opacity **plus**
blur = frosted glass. Neither half works on its own. The old setup failed
because of the global `no_blur` rule (UT-03c), not because of the opacity value.
**Applied and persisted** in `shellOverrides/main.lua`: `active_opacity 0.92`,
`inactive_opacity 0.85`, against the existing `blur.size 8`, `passes 3`,
`ignore_opacity true`, `xray true`.
**Also added: `fullscreen_opacity = 1.0`** so games and video are never made
translucent whatever the other values are. Verified live — screenshotted with a
fullscreen game running, the game was fully opaque and untouched.
**Follow-up, resolved the same day.** The user reported the island still not
blurred, and kitty looking transparent-but-not-blurred while zen looked
blurred. All three were measured rather than guessed:
- **The island's blur works** — proven by the 0.75-vs-0.80 alpha experiment
  described in `notes.md` fact 1. It is invisible when idle only because the
  wallpaper behind the pill is a flat patch of sky.
- **kitty is blurred too.** Opened a kitty window, modelled its `#151B1F`
  background blended at 0.92 over the wallpaper, and compared the screenshot
  against a sharp backdrop (mean error 1.12) and a blurred one (**0.89**). The
  blurred model fits. Closed the window afterwards.
- **zen only looked different because it was fullscreen**, where the
  `fullscreen_opacity 1.0` guard makes it fully opaque.
- **`~/.config/hypr/windowrules.conf` is dead config** — it holds
  `windowrule = match:class ^kitty$, opacity 1.00`, but only `.bak`/`.old`
  files source it. The live entry point is `hyprland.lua`. Don't waste time
  editing it.
**Root cause of the whole complaint:** at `active_opacity 0.92` only 8% of the
backdrop shows through, and blur over 8% of a soft wallpaper is imperceptible.
**Final values, chosen by the user:** windows `0.85`/`0.78`, island fill stays
`0.88`. Tune window opacity in `shellOverrides/main.lua`, **never** in
`Theme.qml` — the island's fill alpha is a different thing with a hard 0.79
floor.

### UT-04 · Week strip `DONE` - built into the redesigned panel
Seven days centred on today (a rolling window, matching reference screenshot
02 - not a calendar month; the user chose this over a full grid). Today gets an
accent pill, weekends are tinted.
**Two details taken from a close re-read of reference 02, after the user said
the strip looked "not real":**
- **The strip fades toward both ends.** Opacity falls off from the centre
  (`1 - (|i-3|/3)^2.2 * 0.85`), so the outermost pair is nearly gone. In the
  reference those edge columns are barely visible - it frames today without a
  hard edge.
- **Today spells its day out (`WED`); every other day is a single letter**
  (`S M T . T F S`). That contrast is what makes today read as today, more than
  the highlight behind it does.

## The core mechanic

### UT-05 · Content-driven sizing + resize animation `DONE` (awaiting sign-off)
Reframed from the original "hover to expand": the user asked for the island to
**always hug its content** ("dynamic island luôn bám sát theo nội dung"), which
is the real mechanic — hover is just one thing that could trigger a content
change. So the island no longer has a fixed size at all.
- `IslandShape` measures whatever is declared inside it and sizes itself to
  `content + padding`, with a floor of `islandMinWidth`/`islandMinHeight`.
- `Behavior on width/height` animates every size change (220ms, OutCubic).
- Clock font raised 13 → 16, measured off reference screenshot 01: digits are
  7px tall in a 25px pill (ratio 0.28), so a 40px pill wants ~11px digits.
- Idle pill went from a fixed 180×40 to **102×40**, hugging "11:20 PM" — which
  happens to be exactly the reference pill's width.

**Two real bugs found by testing, both non-obvious — do not undo these:**
1. **`Behavior on width` silently does nothing when width follows
   implicitWidth.** An Item's width-follows-implicitWidth default is applied in
   C++ without creating a QML binding, so the Behavior never sees the change and
   the island teleports. `IslandShape` therefore binds `width: implicitWidth`
   and `height: implicitHeight` explicitly. Proven by polling the layer during a
   content change: without the bindings, only the two end widths ever appeared;
   with them (and the duration temporarily raised to 2000ms so `hyprctl` could
   sample it) 40 distinct intermediate widths were captured, 180→182→186→…→238.
2. **Content must never anchor to the shape.** The shape's size comes *from* the
   content, so `anchors.fill: parent` on a panel closes a binding loop. Panels
   state their own implicit size; the island follows.

**Deliberately NOT done here:** the hover trigger. There is still only one
content state, so there is nothing to expand *into* — wiring a hover that grows
the island to an arbitrary hardcoded size would be a fake. It lands in UT-06
with the panel system, which is where a second state first exists.
**Test:** the pill should hug the time text with even padding, and the clock
should be noticeably larger.

### UT-06 · Panel system + hover `DONE` (awaiting sign-off) — SLICE 1 of 3
`IslandState` singleton + `Loader` panel swapping + hover trigger +
`panels/expanded/ExpandedPanel.qml`.
Agreed layout (user's own sketch, not the reference screenshot's): time + full
date on one row, a divider, then a media row — album art and track text on the
left, cava above transport controls on the right. Measured ~400×98 expanded vs
102×40 idle.
**Slice 1 scope:** row 1 is real (live clock + full English date), divider is
real, hover is real. Album art / track text / cava are **placeholders**.
Slice 2 = UT-07 (real MPRIS + the "Nothing playing" state the user chose),
slice 3 = UT-09 (real cava).
**Decisions taken with the user:** date in English; keep the panel's frame when
nothing is playing and show "Nothing playing" rather than shrinking; hover
opens and closes immediately, no delay.

**Three real bugs found and fixed here — see `notes.md` facts 16b and 16c:**
1. **The window must never be bound to the animated shape.** It was, and the
   animation stuttered badly because the compositor reallocates a layer-shell
   surface every frame. The user reported it and diagnosed the cause. The
   window is now a fixed 720×480 transparent canvas with
   `mask: Region { item: shape }`; only the shape animates.
2. **Nothing may be declared inside a `Loader`** — its default property is
   `sourceComponent`, so the fade `NumberAnimation` became the thing the Loader
   tried to load. Symptom: a correctly-sized, completely blank island, no error.
3. **Wrong transport glyphs** — `f04a`/`f04e` are rewind/fast-forward
   double arrows, not previous/next track. Now `f048`/`f04b`/`f051`.

**Animation duration lowered 220 → 150ms** at the user's request.
**NOT self-verified:** hover, and whether the mask really lets clicks through.
The pointer cannot be moved programmatically on this machine (`notes.md`
fact 18), so both need the user.

## Features — each self-contained, order is flexible

### UT-07 · Media player `DONE` (awaiting sign-off) - SLICE 2 of 3
`services/Media.qml` (MPRIS) + the expanded panel's media row made real:
album art, title, artist, working prev / play-pause / next.
**API verified against the installed qmltypes, not memory:** `Mpris.players` is
an `UntypedObjectModel` (use `.values`); `MprisPlayer` has `next()`,
`previous()`, `togglePlaying()`, and `isPlaying` is writable. Transport methods
do NOT appear in a naive qmltypes property scan - check for Methods too.
**Decisions carried over:** frame is kept and shows "Nothing playing" when no
player exists (user's choice in UT-06); title/artist elide at 150px so a long
track name can never widen the island on a song change.
**Details worth keeping:**
- `playerctld` is filtered out - it mirrors other buses and would double every
  track. Same filter end4-pC uses.
- Album art uses `ClippingRectangle` from `Quickshell.Widgets`. A plain
  `Rectangle` will not do: Qt's `clip` is rectangular and ignores `radius`, so
  the artwork's square corners show through.
- **Unprintable titles are guarded.** The track playing during testing had a
  title made entirely of U+3164 HANGUL FILLER, which rendered as a row of tofu
  boxes. `Media.title` now falls back to the player's `identity` when a title
  leaves no visible glyphs - verified, the panel showed "Lumen" instead.
- Buttons grey out via `canGoNext` / `canGoPrevious` / `canTogglePlaying`.
  The inline `TransportButton` component uses `usable`, not `enabled`:
  `enabled` is an existing Item property and shadowing it breaks input.
**Verified by screenshot** with a real player (`lumen`): art, artist, pause
glyph while playing, divider and layout all correct.
**NOT verified:** the "Nothing playing" state (would mean stopping the user's
music) and whether the transport buttons actually respond to clicks - the
pointer cannot be moved programmatically here (`notes.md` fact 18).

### UT-08 · Launcher `DONE` (awaiting the user's hands on it)
`services/Launcher.qml` + `modules/panels/launcher/{LauncherField,LauncherResults}.qml`
+ `config/pinned.json`.

**Design was agreed on a web mockup first**, at the user's request, rather than
in QML - https://claude.ai/code/artifact/a323226a-2950-4419-8eae-808138e26049 -
with the real installed apps, their real icons and the real scoring function
ported over, so the layout argument was settled cheaply. Modelled on end4-pC's
search widget after the user pointed at it as the nicest one.

**Shape:** the island IS the search field, and the results are a SECOND surface
below it with a `launcherGap`. Both are `Theme.launcherWidth` wide - the field
declares `islandPaddingH: 0` so the island does not add its own padding and
come out wider. Still one `PanelWindow`, so the architecture rule holds.

**What Quickshell already provided** (verified in the installed qmltypes, no
custom .desktop scanner and no vendored fuzzy library):
- `DesktopEntries.applications` - `name`, `icon`, `command`, `noDisplay`,
  `keywords`. **No `id` property on this build**, so dedupe on `execString` +
  `name`; end4-pC dedupes on `app.id`, which here is `undefined` and would
  collapse the list to one entry.
- `Quickshell.execDetached`, `Quickshell.iconPath`, `IconImage`.
- `GlobalShortcut { appid: "quickshell" }`, bound with
  `hl.dsp.global("quickshell:dynisleLauncher")` - not `qs ipc call`, which
  spawns a process per keypress.

**Scoring is hand-written, ~30 lines**, no fuzzysort: prefix > word start >
initials > substring > keyword > loose subsequence, shorter names winning ties.
The user's spec was "the characters just have to appear in order", e.g. `gay`
matching "Goblin Are You". Verified by porting the function to Python and
running it: `gay` matches at 686 via initials and does NOT match "Nautilus";
`fls`/`kt`/`sptfy` match Files/kitty/Spotify by subsequence.
Matched characters are **underlined** in the row (Text.StyledText), as in the
reference - not bolded.

**Pinning is interactive:** every app row carries a pin button, every pinned
tile an unpin badge, both on their own `MouseArea` so the click never falls
through to the row underneath. `Launcher.togglePin()` writes
`config/pinned.json` back through `FileView.setText`, and the view watches the
file so hand edits work too.

**KEYBOARD FOCUS IS THE DANGEROUS PART.**
`WlrLayershell.keyboardFocus: Exclusive` while the launcher panel is up means
the surface swallows every keystroke on the machine. It is granted ONLY for
`IslandState.panel === "launcher"`, and `closeLauncher()` is the single exit,
so the island can never be left holding the keyboard with nothing on screen.
Escape is wired directly on the field. If this ever sticks, kill the shell from
a TTY.

**Keybind:** `SUPER + D` in `~/.config/hypr/custom/keybinds.lua`, which loads
after `hyprland.keybinds` and therefore **displaces that file's SUPER+D
fullscreen/maximize toggle** - the user chose the key knowing this; offer to
relocate the old binding.

**Three ways out, all wired:** Escape on the field, the shortcut again, and
`HyprlandFocusGrab` - clicking anywhere outside the island dismisses it, since
Hyprland hands the grab back and fires `onCleared`. Same pattern end4-pC's
`GlobalFocusGrab.qml` uses. That third route matters for safety, not just
convenience: it is one more way out of exclusive keyboard focus.

**Verified:** state trace across a real shortcut press showed
`panel: launcher`, the results Loader reaching `status 1`, and the island's
shape growing from `102x40` to `510x56`. The mask combines both surfaces via a
nested `Region`, or the results panel would be visible but dead.
**NOT verified visually in QML** - the user was in a fullscreen game for the
whole verification window, where the island correctly hides.

### UT-09 · Cava visualiser `DONE` - as the album art's border
`services/Cava.qml` + `config/cava.conf`. Real `cava` process, raw ascii on
stdout, 56 bars parsed to 0..1. **Not a separate block** - the bars form the
border of the album art, corners included. See `notes.md` fact 25.
Verified live: `cava0: 0.595` with audio playing, and the ring renders around
all four corners.

### UT-10 · Notifications + control centre `DONE` - all 3 slices
Design was settled on a web mockup first, at the user's request:
https://claude.ai/code/artifact/9fe004f3-9728-4ddc-b072-727398f7a276

**Agreed shape:** notifications expand the island for 5s then collapse.
`SUPER + R` opens a control centre with three sliders (brightness, speaker,
microphone), a Wi-Fi row and three toggles (night light, silence, keep awake),
and a battery + power-profile row whose selection mark TRAVELS between icons.
Wi-Fi and both device pickers **grow the bar itself** - no extra window - and
slide, forward from the right and back from the left. Wi-Fi splits Saved from
Other networks, each ordered strongest first, asks for a password inline, and
offers "Forget this network" on a saved row's hover.
Icons are Material Symbols at **FILL 0** - outline, one plane. That variable
font is already installed, so the mockup and the shell render identical glyphs.
Dropped after review: Bluetooth (the user's adapter is unreliable), colour
picker, and screenshot (going to a keybind instead).

**Slice 1 DONE - five services, all verified against real values:**
`Audio` (Easy Effects Sink / Built-in mic), `Brightness` (347/937 = 37%),
`Power` (86%, charging, 32 min to full), `Network` (<home Wi-Fi>, 4 saved, 5 other),
`Notifications` (server owns the bus).
Four non-obvious bugs were found and fixed on the way - `notes.md` fact 34.

**Slice 2 DONE - the notification popup.** Every state from the review page is
implemented and the important ones were tested with real `notify-send` calls:
- Urgency drives colour and the dismissal rule. **Critical never expires** and
  drops the countdown bar entirely - verified, it rendered `priority_high` in a
  red-tinted box with no bar.
- Actions render as buttons, first one primary. Verified with two real actions.
  `NotificationAction.invoke()` DOES exist even though a naive qmltypes scan for
  Methods misses it.
- Inline reply is a real field. It is the only other place in dynisle that takes
  the keyboard, so it goes through the same `IslandState.replying` gate as the
  launcher and reads `preeditText` for input methods.
- A `hints.value` percentage replaces the countdown - the notification then
  lives as long as the job.
- Image beats icon; nothing supplied falls back to a `notifications` glyph.
- The app-name line hides when it merely repeats the summary. This was found by
  testing, not designed: `notify-send -a Sober "Sober"` printed it twice.
- Hover, progress, replying and critical all HOLD the countdown, and the bar
  greys while held - the only cue that it is waiting.
- A `+N` count shows how many more are in history.

**Testing note:** `notify-send -A` **blocks until the action is invoked** - it
hung a command for two minutes. Run it detached.

**Slice 3 DONE - the control centre.** Eight files under
`modules/panels/control/`: `ControlPanel` (shell + view Loader + slide),
`ControlHome`, `ControlWifi`, `ControlJoin`, `ControlDevices`, plus the pieces
`ControlSlider`, `ControlTile`, `RoundButton`, `WifiRow`, `ListFade`.
`SUPER + R` -> `GlobalShortcut` "dynisleControl", bound in
`custom/keybinds.lua`. SUPER+R was free, so nothing was displaced.
- Every layer lives in the one bar, as agreed. `IslandState.controlView` picks
  the view; `controlForward` decides which side it slides in from.
- The power-profile mark travels: each button seats it from its own `x`, and
  watches `onXChanged` too - seating only at `Component.onCompleted` parks the
  mark at zero, because a `Row` has not positioned its children on frame one.
- Wi-Fi splits Saved / Other, strongest first, with the Windows-style wedge
  icons (`signal_wifi_4_bar` -> `network_wifi_1_bar`), a radio switch in the
  header, hover-revealed **Forget**, and an inline password sheet whose
  Connect button unlocks at 8 characters (WPA2's own minimum).
- Both device pickers list PipeWire nodes and set
  `preferredDefaultAudioSink/Source`; output guesses a headphones glyph from
  the device name, since PipeWire does not label the difference.
- Long lists scroll inside the bar and fade at the cut (`ListFade`) instead of
  slicing the last row in half.
- Screenshot got its own `GlobalShortcut` after all (`SHIFT + Print`), because
  the keybind for exactly that name was **already** in `custom/keybinds.lua`.

**Verified by screenshot**, all five views: home reads 37% brightness, Easy
Effects Sink, <home Wi-Fi> with the right wedge, 99% battery + "7 min to full", and
the mark seated on Power saver. Wi-Fi, the password sheet and the output
picker all render with a clean log.

**Two real bugs found while verifying, both in `Network.qml`** - see
`notes.md` facts 38 and 39. The visible symptom of both was the same: the
panel said "Not connected" while `nmcli` said `<home Wi-Fi>`.

### UT-10b · Notification rebuild `DONE`
The first notification pass was redesigned on the web at the user's request,
after they pointed out the icon left a gap: the 44 px square was pinned to the
top of the row, so a two-line body left a bare column under it.
https://claude.ai/code/artifact/5273fe4c-739d-47c7-8fe1-a746b6d250b7
A field guide of every sender on this machine was harvested first - not from
memory, from `~/user_scripts`, the running battery unit and the icon theme:
https://claude.ai/code/artifact/5e75b1b0-4290-4b05-b600-21ebc6ade253

**Shape:** the media block is square by default and stretches to the row's
height when the text makes the row taller, so it never leaves a gap. A photo
is the exception and stays square - cropping a screenshot into a tall slot
mangles it (the user asked for this explicitly). The countdown became a
hairline on the island's own bottom edge, drawn by `IslandShape` because
anything a panel declares is measured as content.

**Scope, cut by the user:** system notifications are Battery, new device and
pacman updates; app notifications are icon + app name + content. Keyboard
layout was implemented, then removed - see below. Inline reply, actions, the progress rail, the timestamp and the
brightness/volume OSD were all removed. Lifetime is 3s, and a sender asking
for longer is capped - `expireTimeout: 0` (never) is still honoured.

**Three real bugs found while testing, all in `notes.md`:** `appIcon` always
empty (42), `Pipewire.defaultAudioSink` unusable so the wrong audio device was
being driven (43), and `x-canonical-private-synchronous` never arriving unless
named in `extraHints` - without which every volume keypress queued a new
notification instead of replacing the one on screen.

**`services/SystemNotify.qml`** raises what nothing else on this machine does:
udev USB add/remove and `checkupdates` on a 90s-then-3h timer. The device
summaries say "USB device connected/disconnected" rather than just "Device",
and the removable-storage keywords sit at the TOP of the glyph table, so the
usb glyph cannot be shadowed by anything below and a mount notification from
gvfs gets the same icon. Battery is
deliberately absent - `battery_notify.service` already covers it.

**Keyboard-layout notifications were built, then removed.** They worked, but
`fcitx5-remote -n` reports an EMPTY name whenever no window holds an input
context - which happens on every workspace switch - so the empty-then-restored
reading looked like a real switch and fired a notification each time. fcitx5
emits no DBus signal to use instead (notes.md fact 45), so the user chose to
drop the feature rather than paper over it.

**Verified:** slot replacement (five rapid volume steps → one popup, no `+N`),
queue count, emoji/Nerd-Font marker stripping, theme icon vs glyph fallback for
a name that does not resolve, file-path icon as a square preview, critical with
no countdown, and the keyboard-layout notification switching en ↔ Vietnamese.

### UT-10c · Control centre rebuild `DONE`
Redesigned on the web first and agreed there:
https://claude.ai/code/artifact/5252ee00-3c6d-4c84-aff3-8eadcac0d145

The first version was a stack of full-width rows - every control the same
shape, so shape said nothing about behaviour. The rebuild is organised around
one rule: **things you DRAG are full-width rows, things you PRESS are tiles in
a four-column grid, and status is neither.**

- `MediaStrip.qml` (new) puts MPRIS at the top: art, title, artist, transport,
  and the artist line rides a live Cava waveform. Cava was already running for
  `ExpandedPanel`, so it costs nothing extra. The whole strip disappears when
  nothing is playing - the island fits its content.
- The device name moved onto the slider row. It used to be its own line under
  each slider with a tiny `tune` link: two lines for something touched once a
  month. That is where the room for media came from.
- Tiles carry their state as text (the network's name, `4000 K`, `Off`); the
  old ones were an icon and a name, so the only cue was the tint.
- Battery shares the bottom strip with the power profiles, which are the one
  control it belongs to. The travelling mark is unchanged - that part worked.
- `ControlWarmth.qml` (new) is reached by HOLDING the night light tile.
  `hyprctl hyprsunset temperature` takes any number, so on/off was only half of
  what the service could do. Warmer runs to the LEFT, because a raw Kelvin
  scale would run backwards under the hand.
- Grid arithmetic lives in Theme: `ccColumns`, `ccColWidth` and `ccSpan(n)`, so
  a two-column tile lines up exactly with two tiles plus their gap.

**Found while building:** `ccTileHeight` had to go from 66 to 78 - a narrow
tile stacks a 20px glyph over two lines of text, and at 66 the label climbed
onto the icon.

### UT-10d · System vitals `DONE`
Designed on the web first:
https://claude.ai/code/artifact/af913347-2812-4151-9e23-4a37da42bbae
The user then asked for it IN the control centre home rather than behind a
deeper view, so the detail layer in that design was dropped and only the strip
was built.

`services/SysInfo.qml` + `modules/panels/control/VitalsStrip.qml`. Three equal
cells under the tile grid: CPU, RAM in gigabytes, package temperature.

**No processes at all** - every figure is a file the kernel already keeps:
- CPU: `/proc/stat`, differenced against the previous sample. A percentage
  cannot come from one reading; the file counts time SPENT.
- RAM: `/proc/meminfo`, used = MemTotal - MemAvailable (not MemFree), so
  reclaimable cache is not counted as used - the figure `free -h` calls
  available. Shown in GB because "50%" says nothing on its own.
- Temperature: the thermal zones, because this machine has NO hwmon sensors
  (coretemp is not loaded). Zone NUMBERING is not stable across boots, so one
  `sh` at startup resolves the zone whose `type` is `x86_pkg_temp`; after that
  it is a plain FileView.

Sampled at 1s only while `SysInfo.watching` is true, which `ControlPanel` sets
the same way it gates the Wi-Fi scan. The CPU baseline is cleared on close so
the next open does not difference against a reading from minutes ago.

Only temperature is coloured (amber past 70, red past 85) and it is drawn
against 30-90 degrees rather than 0-100 - against the full range the bar would
sit near the middle and never visibly move.

**Found while building:** `anchors.baseline` inside a `Row` is ignored - a Row
positions its own children - and the whole readout escaped out of the top of
the cell. Baseline-aligning two type sizes needs a plain `Item`.

### UT-11 + UT-12 · Wallpaper picker and themes `DONE`
`services/Wallpapers.qml` + `panels/wallpaper/`. Grid, selection, switching.
Builds on the existing `WallpaperLayer.qml` — **no wallpaper daemon exists on
this machine, don't add one without asking.** Reference screenshot 04.
**Test:** pick a wallpaper, it applies and persists.

### UT-12 · (folded into UT-11) `DONE`
Curated named schemes (`config/themes/*.json`) + `panels/themes/` picker +
live re-theming through `Theme.qml`. Wallpapers carry a paired scheme name.
Reference screenshot 03.
**Test:** switch scheme, the whole island re-colors live.
**Hardest UT** — it touches every module, which is exactly why `Theme.qml`
(UT-02) exists.

## Finish

### UT-13 · Keybinds + config cleanup `DONE`
- `qsConfig` -> `dynisle`, which both stops Hyprland autostarting end4-pC and
  gives dynisle autostart (notes.md fact 67).
- end4-pC's recorder and wallpaper switcher pinned to absolute paths so the
  qsConfig change does not break them.
- Unbound the welcome-window keybind, which pointed at a shell that no longer
  runs and had nothing to re-point to.
- Eight dead `.conf` files archived to `~/.config/hypr/_unused/` - the config
  is Lua and nothing ever sourced them (fact 68). noctalia's six binds lived
  in one of them and had been inert all along.
- SUPER+D keeping fullscreen/maximize is fine per the user: SUPER+F is the
  fullscreen key they actually use.

### UT-13b · Old keybinds + IPC `DONE` (2026-09-03)
Every dynisle key is a compositor GLOBAL, not `qs ipc call` - ipc spawns a
process per keypress. The dead ones are gone: ii's `ipc call search toggle`
(which was bound to SUPER + D ALONGSIDE the real one, so Hyprland ran both and
one failed silently every time), the cliphist IPC watchers, end4's
`switchwall.sh`, and the welcome-window bind. What is deliberately kept:
end4-pC's screen recorder, pinned to an absolute path.
**Verified:** `hyprctl binds` reports exactly one binding for SUPER + D.

### UT-14 · Autostart `DONE` - multi-monitor still `TODO`
Autostart came free with the `qsConfig` change: `hyprland/execs.lua` already
ran `qs -c $qsConfig` on hyprland.start, it was just starting the wrong shell.
Multi-monitor is untouched and still open.
Wire dynisle into Hyprland startup (currently `startup.conf` points at the
uninstalled `noctalia-shell`). Empty states — no media playing, no
notifications, no wallpapers found. Multi-monitor check (`eDP-1` + `HDMI-A-1`
both exist).
**Test:** reboot. Island comes up on its own and behaves on both monitors.

---

## Completed

- **Pipeline proof** — `qs -c dynisle` renders a window at the right position.
- **Idle shape** — rounded rect, floating, 180×40 radius 20. User rejected the
  flared/flush notch; see `06-decisions.md`.
- **Real compositor blur** — full 4-link chain working, `blur:size` 8, fill
  alpha 0.88. See `07-architecture.md`.
- **Wallpaper pin** (unplanned) — `Clouds.png` rendered by dynisle's own
  background layer, since no daemon and no other shell exists. Stand-in for
  UT-11, not the final feature.

- **UT-11 wallpaper + themes, SPLIT** — two panels, two libraries, one owner of
  the desktop. Designed on the web first:
  https://claude.ai/code/artifact/ba23a0a0-63b1-470b-8ad2-634bf55ffb80
  `WallpaperPanel.qml` is now the picker alone (its own `Wallpapers.library`);
  `panels/themes/ThemesPanel.qml` holds themes / inside-a-theme / naming /
  colour. `HeaderChip`, `SheetButton`, `ModeChip` split out as shared files.
  Selecting a theme puts a picture up; picking a picture releases the theme;
  the picker locks with a "Take it back" bar while a theme holds the desktop.
  See notes.md facts 81-86 for the four bugs found on the way.
- **Themes removed** (2026-09-03) — split into two panels, then deleted
  entirely a few hours later at the user's request. `06-decisions.md` has the
  reasoning; the picker keeps its own library and is the only wallpaper UI.
- **UT-15 session panel** `DONE` — SUPER+S, four actions, press-again on the
  destructive two. Designed on the web and approved first. Fixing hypridle's
  `lock_cmd` was a prerequisite (notes.md fact 91).
- **UT-16 lock screen** `DONE` — hyprlock rebuilt on the blurred wallpaper.
  See notes.md fact 115, and 116 before ever previewing it again.

## Actually left (2026-09-03)

- **Multi-monitor** — the ONE structural gap. `shell.qml` builds a single
  `Island`, `WallpaperLayer` and `ShotLayer`; none is wrapped in `Variants` over
  `Quickshell.screens`, so a second display gets no bar, no wallpaper and no
  screenshot layer. Cannot be built blind: only `eDP-1` is connected.
- **GTK4 apps do not follow the palette** — `~/.config/gtk-4.0/gtk.css` is a
  symlink into root-owned adw-gtk3, so matugen's gtk4 template is disabled. Note
  ONE failing template aborts the whole matugen run (that is how colors.json
  stopped being written once). Fix is a real gtk.css that @imports both the
  theme and a generated colours file - touches the user's GTK look, so ask.
- **rtkit not installed** — `sudo pacman -S rtkit`. Not silence, but pipewire
  runs without realtime priority and the boot log is full of RTKit errors.
- **Clipboard history and tray** — never built. `cliphist` still stores; there
  is no UI reading it.
