---
title: Session Log
updated: 2026-09-02
---

# Session log

Newest entry on top. **Read this before doing anything else in this project.**
Each entry: date, what happened, what's next.

---

## 2026-09-01 — Session 2: UT-03 clock, island became a bar, blur bug root-caused

**What happened:**
- **UT-03 done.** `services/DateTime.qml` (first real service — sets the
  convention for the other six, see `09-ultra-tasks.md`) +
  `modules/panels/idle/IdlePill.qml`. Pill shows **time only**, matching
  reference screenshot 01; the date belongs to UT-04's week strip. Format
  changed mid-session at the user's request to **12-hour with AM/PM**
  (`"h:mm AP"`); `time24` kept alongside for anything that wants 24-hour.
- **UT-03b, unplanned:** user said the island "thực ra là bar", it must not
  float over windows and must hide on fullscreen. Implemented exclusive zone +
  fullscreen hide + equal 7px gaps. Found and fixed a bug this introduced:
  the wallpaper layer was being pushed down by the island's new reservation
  (`exclusiveZone: 0` still honours other zones — needed `ExclusionMode.Ignore`).
- **UT-03c, the important one:** user was right that the desktop was showing
  **opacity, not blur**. Root cause was *not* the blur config —
  `hyprland/rules.lua` had `no_blur = true` matching `class = ".*"`, i.e. blur
  disabled on **every window**, leaving `active_opacity 0.88` as the only
  visible effect. Commented that rule out, restored opacities to `1.0`.
- **User's clock-drift complaint diagnosed:** the machine is **not** drifting.
  `timedatectl` shows NTP active and synchronised — but **timezone is `UTC`**,
  so every clock reads 7 hours behind Vietnam time. Needs
  `sudo timedatectl set-timezone Asia/Ho_Chi_Minh` (requires the user's
  password, so it was handed to them to run, not run by Claude).
- **Launcher decision finally answered: yes, pull it forward.** UT-08 now runs
  right after UT-06. Behaviour agreed: island grows → search field → typed
  query filters apps → results show name + icon.

**Verified live (not assumed):** island layer `593 7 180 40`, reserved `49`,
tiled window content at `y 55` → 7px gap above and below the island. Fullscreen
hide confirmed working (`a: 0` on the layer while a fullscreen game ran on
workspace 2). QML reloads clean, no errors in `/tmp/dynisle.log`.

**Confirmed at the end of the session** (user left fullscreen, screenshotted
with `grim`): island renders `11:05 PM` — AM/PM format working, and the
timezone fix took effect (`date` read 23:05). User had reported AM/PM missing,
but that was an older dynisle instance; the pid had changed by the time of the
screenshot, i.e. their restart picked up both changes at once. Gaps look even,
window sits below the island, fullscreen hide works.

**Window blur (UT-03d) — asked for and applied.** After the trade-off was
explained (blur needs translucency to act on), the user said to go ahead.
Persisted in `shellOverrides/main.lua`: `active_opacity 0.92`,
`inactive_opacity 0.85`, plus a new `fullscreen_opacity 1.0` guard so games and
video are never made translucent. Checked `fullscreen_opacity` was already
defaulting to 1.0 **before** applying, then screenshotted with the fullscreen
game running to confirm it stayed fully opaque. The desktop look at these
values still needs the user's eye.

**UT-05 done, reframed by the user.** They said the pill looked empty, wanted
bigger text, and — the important part — that the island should "luôn bám sát
theo nội dung". So UT-05 became content-driven sizing rather than a hover
gimmick: `IslandShape` measures its children and animates to fit. Font 13 → 16,
measured off the reference rather than guessed. Idle pill 180×40 → **102×40**.
Two non-obvious bugs found and fixed along the way — `Behavior on width` not
firing under the implicitWidth default, and the anchors.fill binding loop. Both
written up in `notes.md` fact 16 and UT-05's entry.
The hover trigger was deliberately left out: with one content state there is
nothing to expand into, so it belongs to UT-06.

**Process note worth keeping:** hot reload silently failed twice (see
`notes.md` fact 17), which cost time chasing a non-existent code bug. Also,
`pkill -f "qs -c dynisle"` killed the command's own shell and left the user
with no shell running at all for a few seconds — use the documented restart.

**UT-06 done (slice 1 of 3).** User asked for a hover-expanded panel and gave
their own layout sketch — clock+date row, divider, media row with cava. Design
was written up and four choices put to them before any code: 3 slices (not one
big batch), keep the frame + "Nothing playing" when idle, English dates, and
hover with no open/close delay.
Built: `IslandState` singleton, `Loader` swapping, hover, `ExpandedPanel` with
row 1 real and the media row as placeholders. 102×40 → ~400×98.

**The significant fix:** the user reported the animation as "giật kinh khủng"
and correctly blamed the box scaling with content. Root cause was one level
deeper — the *layer-shell surface itself* was being resized every frame, so the
compositor reallocated and re-committed it 60x/second. Rebuilt as a fixed
720×480 transparent window with `mask: Region { item: shape }`, only the shape
animating. Confirmed this is exactly what end4-pC's `Bar.qml`/`Dock.qml` do
before adopting it. Duration also cut 220 → 150ms as asked.
Two more bugs fixed: a `NumberAnimation` declared inside a `Loader` (default
property is `sourceComponent`) left the panel blank at opacity 0, and the
transport icons were rewind/fast-forward rather than prev/next track.

**Blocked on the user, not on work:** hover and click-through cannot be
self-verified — the pointer cannot be moved programmatically here (three
methods tried, `notes.md` fact 18).

**Blur round two — everything measured, nothing guessed.** User said the island
still wasn't blurred, and that kitty looked transparent-without-blur while zen
looked blurred. Three findings, all backed by numbers (details in UT-03d and
`notes.md` fact 1):
- The island's blur **works** — proven with a controlled 0.75 vs 0.80 alpha
  experiment over a terminal. It is invisible at idle only because the sky
  behind the pill is flat (stddev < 1).
- **kitty is blurred too** — verified by blend-modelling its background against
  sharp vs blurred wallpaper; the blurred model fits better.
- **zen looked different only because it was fullscreen**, where the
  `fullscreen_opacity 1.0` guard makes it fully opaque.
- `~/.config/hypr/windowrules.conf` (which does hold a kitty `opacity 1.00`
  rule) is **not loaded at all** — only `.bak`/`.old` files source it.
Root cause: `active_opacity 0.92` leaves only 8% of the backdrop for blur to
act on. User chose windows at **0.85/0.78** and the island to stay at **0.88**.
Applied and verified live via `hyprctl getoption`.

**Blur round three — the actual root cause found.** Mid-session the user
accidentally launched ii, which **regenerated
`hyprland/shellOverrides/main.lua`** and reset `blur.size` to 1 and
`active_opacity` to 1. That is almost certainly what was really behind "blur
works then stops" all along — not the blur cache. Fixed durably: all dynisle
blur/opacity values moved to **`~/.config/hypr/custom/dynisle-blur.lua`**, with
a final `require` appended to `hyprland.lua` so it loads *after* shellOverrides
and survives ii. Verified: main.lua still says `size = 1` while the live value
is 8. See `notes.md` fact 13-NEW.

**kitty solved.** At its default `background_opacity 1.0`, kitty declares an
opaque surface and Hyprland skips blurring behind it. Set `0.95` in kitty.conf —
just enough to drop that declaration — and, at the user's explicit request
("xóa thẳng tay conf riêng cho kitty đi"), removed **all** kitty special-casing:
the window rule that had been added to `rules.lua`, and the stale
`opacity 1.00` line in the dead `windowrules.conf`. Backups taken of both.
**Not measured:** kitty keeps opening on a fresh empty workspace, so `grim`
captured the wrong workspace and the blend-model measurement was invalid. Handed
to the user to eyeball rather than burning more rounds on it.

**Confirmed working by the user:** hover no longer stutters after the
fixed-window refactor, and blur now looks right on VS Code, zen and everything
else.
**Still open:** clicks in the island window's transparent area. The user
reported them not passing through, but **the test instruction was wrong** — they
were asked to click the strip *beside* the pill, where nothing but wallpaper
sits underneath, so "nothing happened" was the expected result either way. The
wallpaper layer was separately given `mask: Region { item: null }` since a
fullscreen background layer really does swallow desktop clicks. Needs a re-test
at a point clearly over a window, e.g. (500, 250).

**The terminal blur mystery, finally solved (2026-09-02).** The user reported
that a kitty window Claude opened blurred correctly, while their own Super+Enter
terminal stayed transparent. Cause: **Super+Enter does not open kitty.**
`hyprland/variables.lua` sets
`terminal = launch_first_available.sh 'foot' 'kitty -1' ...` and foot is
installed, so their terminal has been **foot** all along - two different
programs, which is why the two behaved differently. Read straight out of the
keybind and the launcher script, not guessed.
Both terminals share the same quirk: at `alpha`/`background_opacity` 1.0 they
declare an opaque surface, Hyprland skips blurring behind them, and
`active_opacity` then makes them see-through with unblurred content underneath.
Fixed with one line in each app's own config (`alpha=0.95` in foot.ini,
`background_opacity 0.95` in kitty.conf) and, per the user's request, **zero**
per-app Hyprland rules. `notes.md` fact 19.

**File manager switched dolphin -> nautilus** via
`~/.config/hypr/custom/variables.lua`, which is the update-friendly override
point (`keybinds.lua` loads `hyprland.variables` then `custom.variables`).
`notes.md` fact 20.

**Not measured:** foot's blur after the fix. The active workspace kept moving
while the user worked, so `grim` captured empty workspaces and the measurement
was invalid. Handed to the user - one glance settles it faster than more probing.

**UT-07 done (slice 2 of 3) - real MPRIS.** `services/Media.qml` + the expanded
panel's media row wired to live data: album art, title, artist, working
transport. API was read out of the installed qmltypes first (transport methods
do not show up in a property-only scan). `playerctld` filtered out; album art
uses `ClippingRectangle` because Qt's `clip` ignores `radius`; unprintable
titles fall back to the player identity - the test track's title was entirely
U+3164 HANGUL FILLER and rendered as tofu until guarded. Verified by screenshot
against the user's running `lumen` player. Details in UT-07's entry.

**Panel redesigned from scratch (2026-09-02), to the user's own sketch.**
Album art 4x bigger (44 -> 176), bigger transport controls, week strip (UT-04)
and a big clock on the right, and **cava as the album art's border** (UT-09) -
corners included, rounded caps. `islandMaxWidth` raised 720 -> 900.
Two bugs found and fixed in the process:
- **Buttons rendered as nothing**, no error: the glyph Text was a child of the
  hover pad, whose opacity is 0 until hovered, and QML opacity multiplies into
  children. `notes.md` fact 24.
- **The island's hover MouseArea sat on top of the content and ate hover**, so
  the buttons could never highlight. Replaced with a `HoverHandler` - input
  handlers compose instead of competing.
Verified by screenshot with rendering forced (the user's MPRIS player keeps
quitting, so capability flags flap between true and false).

**Workspace flash added (new, not in the original roadmap).** Switching
workspace grows the island into a workspace strip for 1.5s, keeping the clock,
then it returns on its own. Hover takes priority over the flash.
**The blocker was a measurement, not a guess:** `Hyprland.focusedWorkspace` and
`focusedMonitor` are `undefined` on this build, which is why the first two
attempts silently did nothing. Driven from `Hyprland.rawEvent`
(`workspacev2 >> <id>,<name>`) instead, with `workspaces.values` used only for
occupancy. See `notes.md` fact 26.
Also added a slide+fade transition between panels, using a `Translate` because
animating `y` would have dragged the island's measured height with it (fact 28).

**Expanded panel scaled to 75%** via a single new `Theme.panelScale`, kept
separate from the generic font tokens so the idle clock is untouched (fact 29).

**Second pass on both, after the user saw them (2026-09-02):**
- Workspace strip: clock removed, only existing workspaces listed (plus the
  focused one), and the per-item boxes dropped for bare numbers - the island's
  own body is the container. Active/inactive colours verified by sampling
  pixels: `(127,212,221)` = accent, `(153,160,165)` = textDim.
- Expanded panel: widened (`panelColumnGap` 22->30, `trackTextWidth` 210->250),
  clock enlarged (`panelFontTime` base 30->44), and a hairline separator with
  air either side now divides the media half from the time/calendar half.

**UT-08 done - the launcher.** Design was settled on a web mockup first at the
user's request (`notes.md` fact 32), modelled on end4-pC's search widget after
they pointed at it. Built as TWO surfaces of equal width inside the one window:
the island becomes the search field, the results sit below it.
Quickshell provided `DesktopEntries`, `execDetached`, `iconPath` and
`GlobalShortcut`, so there is no .desktop scanner and no vendored fuzzy library
- scoring is ~30 hand-written lines, tested by porting it to Python and running
the user's own example (`gay` -> "Goblin Are You").
Pinning is interactive and persists to `config/pinned.json`. The tool buttons
were dropped because they did nothing.
**The risky part is exclusive keyboard focus** - see `notes.md` fact 30 for the
three exits.

**Getting the field to actually accept typing took three separate fixes**, and
each looked like the whole problem on its own - written up in `notes.md`
fact 30:
1. `text: Launcher.query` **plus** `onTextChanged` was a two-way binding that
   re-asserted the old value over each keystroke.
2. `keyboardFocus` had to be `Exclusive` with **no** `focusable` beside it.
   Two rounds were wasted because both were changed at once, so the one correct
   combination went untested, and because `Window.active` reads false for a
   layer surface even when focus works.
3. Vietnamese input goes through an IME, so keystrokes sit in the preedit
   buffer and `text` does not change until space or enter commits them. The
   field now reports `text + preeditText`.

**Next step:** the user needs to press SUPER+D and try it - it could not be
screenshotted, they were in a fullscreen game where the island correctly hides.
Then UT-04's remaining polish, UT-10..UT-14. Still unchecked
by the user: transport clicks and the "Nothing playing" state (both need a
pointer or their music stopped), and click-through on the island's transparent
area.

---

## 2026-09-01 — Session 1 continued: architecture rewritten, roadmap set, UT-01 done

**What happened:**
- User rejected the monolithic `shell.qml` — correctly. Researched real
  Quickshell structure (docs + end4-pC's 300+ file tree) and rewrote
  `07-architecture.md` around the actual finding: **end4-pC organizes by
  *surface* (24 folders under `modules/ii/`), and since dynisle has exactly
  one surface, all of those collapse into `panels/` — content states, not
  windows.** Hence the rule: only `Island.qml` and `WallpaperLayer.qml` may
  create a `PanelWindow`.
- Confirmed the Quickshell 0.2 module system: subdirectories auto-become
  `qs.<path>` modules, **no `qmldir` files** (end4-pC has zero and imports
  `qs.modules.common` fine). Singletons need `pragma Singleton` + `Singleton`
  root. `.qmlls.ini` in shell root gives LSP support.
- Roadmap rewritten to **14 Ultra Tasks** (user capped it at 10–15, not 100+),
  in `09-ultra-tasks.md`, with ordering rationale in `08-roadmap.md`.
- Published architecture + roadmap as an artifact:
  https://claude.ai/code/artifact/4e7dd6c5-c72a-4934-9709-a92c27a2fd3b
- **UT-01 (restructure) implemented and self-verified.** See its entry in
  `09-ultra-tasks.md`. Awaiting user sign-off.

**Open decision:** whether to pull the launcher (UT-08) forward to right after
UT-06 — the user has no launcher on their system at all. Asked, not answered.

**Next step:** user confirms UT-01 looks unchanged → then UT-02 (Theme
singleton). User also asked that a **handoff prompt for the next session** be
written once they've signed off on the current test.

---

## 2026-09-01 — Session 1 continued: UT-003 blur, went dynisle-only

**What happened:**
- UT-002 resolved by user decision: simple rounded rect, floating. Confirmed
  good ("yep, this good").
- UT-003 (blur): found the existing `quickshell:.*` Hyprland layer rules
  already cover `quickshell:dynisle`, so no new layer rule was needed. Set
  island fill alpha to 0.88.
- User reported no visible blur. **Root-caused it properly instead of
  guessing**: `hyprland/shellOverrides/main.lua` (auto-written by ii) forced
  `decoration.blur.size = 1`, overriding `general.lua`'s `size = 10`. Blur
  radius of 1 = effectively no blur. See `notes.md` fact 13.
- **Discovered `grim` is installed** — Claude can now screenshot and
  self-verify UI instead of spending user feedback rounds. Used it to confirm
  the pill was rendering correctly and that alpha was in fact working (it was
  picking up a faint wallpaper tint). See `notes.md` fact 14.
- Learned `hyprctl keyword` does NOT work on this machine (Lua parser);
  must use `hyprctl eval 'hl.config({...})'`.
- User asked for the blur effect on all windows too, and chose **"kill ii, go
  dynisle-only"** when asked how to persist it. ii turned out to already be
  stopped. Backed up and hand-edited `shellOverrides/main.lua`:
  `blur.size 8`, `blur.popups true`, `active_opacity 0.88`,
  `inactive_opacity 0.82`; left input/touchpad/gaps/rounding untouched.
  Verified the values survive `hyprctl reload`.

**State now:** dynisle (pid varies) is the ONLY shell running — it provides
the wallpaper and the empty pill, nothing else. No bar/launcher/tray exists
on the system anymore. Blur is live at size 8 with window opacity 0.88/0.82.

**Not verified:** the actual look of blur behind the island — the user was in
a fullscreen game during verification, which covers layer-shell surfaces.
Needs a look at the plain desktop.

**Next step:** get the user's read on the blur look, then UT-004 (live clock).
Consider raising the launcher's priority — see `notes.md` fact 13b.

---

## 2026-09-01 — Session 1 continued: UT-001 shipped, UT-002 in progress, wallpaper fix

**What happened:**
- Wrote `07-architecture.md`, `08-roadmap.md`, `09-ultra-tasks.md`, and
  `notes.md` (the "read first" digest the user explicitly asked for, to stop
  facts getting silently dropped across sessions). `00-README.md` and
  `CLAUDE.md` updated to point to `notes.md` first.
- **UT-001 (boot + visible placeholder pill): done, confirmed by the user.**
  `shell.qml` created — `ShellRoot` + transparent `PanelWindow`, pattern
  verified against `end4-pC/ReloadPopup.qml` (top-only anchor auto-centers,
  transparent window + shaped child renders the actual visible surface).
- User feedback on the pill's shape (two rounds): (1) uniform rounded
  corners on all 4 sides read as "floating"/detached from the screen edge
  instead of flush; (2) more precisely, the top corners aren't square either
  — they flare slightly outward before curving down, like something being
  "pulled out" of a slot at the top edge. Looked directly at
  `vault/assets/reference-screenshots/01-collapsed-idle.png` (Read tool, not
  guessed) to confirm this — it's a concave-to-convex transition, not a
  simple rounded rect.
- **UT-002 (idle shape fidelity): implemented, not yet confirmed by user.**
  Replaced the plain `Rectangle` with a `QtQuick.Shapes` `Shape`/`ShapePath`:
  flat top segment → `PathCubic` flare out to each side edge → `PathLine`
  down → `PathArc` convex rounded bottom corners → flat bottom → mirrored
  flare back up. Sizes are relative (`width`/`height`-based), not hardcoded,
  so this can be reused when the expand/collapse state machine (Phase 4)
  needs the same shape at a different size. **Explicit uncertainty flagged
  to self**: the `PathArc.Counterclockwise` direction for the bottom corners
  was my best guess for "bulge outward" (convex) — could not visually verify
  since I can't see the screen; may need flipping to `Clockwise` if it
  renders concave instead. Ask the user to check this specifically.
- **Wallpaper incident (unplanned, urgent, fixed):** user reported wallpaper
  disappeared and asked to always pin `~/Downloads/Clouds.png`. Root-caused:
  `noctalia-shell` (what `~/.config/hypr/startup.conf` tries to launch) is
  **not actually installed** (`pacman -Qs noctalia` empty,
  `/etc/xdg/quickshell/` only has `caelestia`) — this predates this session,
  not caused by dynisle testing. No wallpaper daemon installed either
  (checked `swww`/`hyprpaper`/`wpaperd`/`swaybg` — none present). Fix: added
  a second `PanelWindow` in `shell.qml` on `WlrLayer.Background`, fullscreen,
  rendering `~/Downloads/Clouds.png` via `Image`/`PreserveAspectCrop` — see
  `notes.md` fact 11. Also updated `~/.cache/noctalia/wallpapers.json` to
  point at `Clouds.png` (backed up original as `.bak-<timestamp>` in the same
  dir) in case noctalia-shell ever comes back.
- Started `qs -c dynisle` persistently in the background
  (`nohup qs -c dynisle > /tmp/dynisle.log 2>&1 & disown`) so the wallpaper
  and pill stay visible between testing rounds instead of dying with a
  foreground/timeout test run.

**What's NOT done:**
- UT-002's shape has NOT been visually confirmed correct yet — waiting on
  user feedback, specifically on the bottom-corner arc direction and the
  overall flare amount/curve feel.
- No blur yet (UT-003), no clock yet (UT-004).
- The wallpaper fix is a hardcoded pin, not the real wallpaper picker
  service — don't confuse the two, see `notes.md` fact 11.

**Next step:** get UT-002 confirmed/corrected by the user (shape direction,
flare amount), then UT-003 (real Hyprland blur layer rule).

## 2026-09-01 — Session 1 continued: visual reference confirmed

**What happened:**
- User shared 4 screenshots showing the actual target UI (idle pill, expanded
  media player, theme picker, wallpaper picker) — saved permanently to
  `vault/assets/reference-screenshots/01-04*.png` so they survive past this
  chat. Full breakdown written into `01-vision.md` under "Concrete visual
  reference." Decisions updated in `06-decisions.md` (several previously-open
  items are now settled).
- Key new facts: island-only confirmed (no bar anywhere in screenshots);
  panels read as near-solid dark with blur felt at the edges, not an obvious
  see-through pane; theming is a curated named-scheme list
  (catppuccin/gruvbox/kanagawa/nightfox/rose-pine/etc.), wallpapers appear
  paired with a scheme name rather than colors purely auto-generated by
  matugen from the image.
- Still no code written. Still paused before implementation — user has not
  yet said "go ahead and build."

**Next step:** same as below (git-init question, read end4-pC's cava/layer-rule
config, then scaffold the idle-pill state first) — now with a real visual
target to build toward instead of just the verbal spec.

---

## 2026-09-01 — Session 1: research only, no code

**What happened:**
- Explored existing local setup: `~/.config/quickshell/ii` (illogical-impulse,
  not a git repo) and `~/.config/quickshell/end4-pC` (end-4/dots-hyprland,
  is a git repo). Neither is being modified — kept as reference/fallback.
- Confirmed environment: Hyprland 0.56.2, Quickshell 0.2.1, cava, playerctl,
  matugen, wl-clipboard all installed.
- User picked the project name **"dynisle"** for the future config directory.
- User then interrupted before the git-init question was answered and said:
  **do NOT build yet — research the desired style first, build later.**
- Did web research on saneAspect (see `02-research-saneaspect.md`): confirmed
  channel, confirmed the "teaches concepts, doesn't publish the polished
  dotfiles" pattern the user described (his public `dotfiles` repo is an
  older Waybar setup, not the Quickshell island work). Could not extract
  video transcripts/visual detail — only title/channel via oEmbed.
- Wrote the vision spec (`01-vision.md`) from the user's own description:
  single dynamic island (not a bar) hosting wallpaper, clock, date, media
  player, cava, launcher, theme switching. Minimal. **Real compositor blur**
  (Hyprland `layerrule = blur true` + `ignore_alpha`), explicitly not
  opacity/glassmorphism/translucency.
- Researched and confirmed the technical blur mechanism (`04-technical-reference.md`)
  and surveyed other Quickshell dynamic-island projects for architecture ideas
  (`03-prior-art.md`) — DankMaterialShell, "Tide Island". Verdict: build pure
  QML/JS following the `ii`/`end4-pC` singleton-service pattern, no custom
  backend.
- Created this vault at `~/.config/quickshell/dynisle/vault/`.

**What's NOT done:**
- No QML has been written. No `shell.qml`, no `services/`, nothing.
- The `dynisle/` folder currently contains only `vault/`.
- Git init for the new project: **not decided** — the question was interrupted,
  don't assume yes or no, ask again when build actually starts.
- Haven't inspected `end4-pC`'s actual Hyprland layer-rule config or its cava
  scripts firsthand — flagged as a to-do before implementing blur/cava.

**Next step (start of next build session):**
1. Confirm with the user they're ready to move from research → build.
2. Re-ask (or confirm still wants) git-init for `dynisle/`.
3. Read `end4-pC/scripts/cava/*` and whatever Hyprland conf fragment sets its
   layer rules, to ground the cava + blur implementation in a known-working
   example before writing new code.
4. Scaffold minimal `shell.qml` + one `PanelWindow` island with just
   clock+date and blur working — get that visually confirmed by the user
   before adding wallpaper/media/cava/launcher/theme widgets one at a time.
   Ship small, confirm the blur/shape look is right early, since that's the
   single non-negotiable aesthetic requirement.

**Session budget note:** this session had a very large remaining token budget
(started ~15M tokens) — session-switch guidance in `00-README.md` /
`06-decisions.md` applies more once budget is actually tight. No action needed
yet.

## Wallpaper and themes, split apart

The user rejected the one-panel-three-depths architecture outright: "chung là
khi bảo bạn làm cái này nó đã có vấn đề rồi nên là thôi, bây giờ wallpaper
riêng, themes riêng". Three complaints, all one root cause:

1. The big "New theme" card was inert — it called `Wallpapers.addTheme()`,
   a function replaced by the naming sheet and defined nowhere. QML logs
   nothing for that (fact 86).
2. Select/deselect a theme looked identical — `select()` deliberately did not
   touch `current`, so the mark moved and the screen did not.
3. SUPER+A kept opening the themes — both keys drove one `wallpaperOpen` flag
   and differed only by a view string.

2 and 3 were architecture, not bugs, so the split was designed on the web and
approved ("ok chắc cx đc, triển đi") before any QML changed.

Two more faults surfaced while building, both found by LOGGING rather than
theorising — the first attempt to reason them out went three wrong ways:

- The theme was wiped on the first restart. Cause: the legacy `FileView` has a
  `path`, so it loads eagerly and ran the migration next to a perfectly good
  themes file — two loaders writing `root.themes` in an unspecified order
  (fact 81). Its `onLoaded` catch had been swallowing the evidence (fact 82).
- The themes panel opened and closed itself ~0.5s later, every time. A stack
  trace out of `closeThemes` named `Island.qml`'s `activewindow` guard, which
  only makes sense for panels holding exclusive keyboard focus (fact 83).

Verified: 3 clean restarts leave `themes.json` untouched (1 theme × 12
pictures, library 12, released); both panels stay open past 3s; the lock bar
renders and names the theme; 0 warnings in the log.

## Themes out, folders back

"Thôi bỏ themes đi cho nhanh" — themes deleted the same day they were split
out. Then, immediately: "hiện tại thì wallpaper không phải chọn thư mục mà lại
thành thêm ảnh". Removing themes had left their per-picture library behind as
the picker's model, which was never the approved design.

The picker is folder-based again, with the `[ folder <name> v ]` chip the user
had singled out as the good part. `FolderListModel` replaced the `find`
process: declarative, and it watches the directory.

Found while restarting: "No wallpaper" had never worked. Not a panel bug — an
empty `Image.source` never reaches `Image.Ready`, so WallpaperLayer's
crossfade never started and the old picture stayed up forever while the state
underneath cleared correctly (fact 87). Clearing has its own fade now.

## The folder chooser is the portal now

The user put the browser's upload dialog next to dynisle's yad chooser and
asked for the first one: "đã là upload từ web rồi thì nó sẽ mở file manager mặc
định lên... mình muốn cái file manager chọn thư mục wallpaper cũng giống như
thế."

That dialog is `xdg-desktop-portal-gtk`, which is already running on this
machine. `scripts/pick-folder` asks the portal directly, so it IS the same
dialog - header bar, rounded corners, adw-gtk3-dark, the same sidebar. yad
could never match it: with no header bar GTK draws it square and titleless.

One thing needed fixing on top: the browser's dialog floats because it is a
modal of the browser window. Ours has no parent window, so Hyprland tiled it
against the right edge with half the dialog cut off. Measured `float=False`
in `hyprctl clients`, added a rule for the class, measured `float=True
at=[233,99] size=[900,620]`. See notes.md fact 89.

## Session panel, and the lock that never locked

SUPER+S opens four tiles: Lock screen, Sleep, Restart, Shut down. Designed on
the web and approved before any QML ("Triển phần session đúng như những gì bạn
nói... và hỏi 2 lần nhé"). Keep awake stayed in the control centre, as asked.

Two things had to be dug out first, both by reading rather than assuming:

- **Nothing on this machine could lock.** hypridle's inherited `lock_cmd`
  parses as `A & (B || C)`, and `pidof qs` succeeds, so its `|| hyprlock`
  fallback never ran - while the global it dispatched belongs to end4-pC's
  shell, not dynisle. Idle timeout, lid switch and `loginctl lock-session` were
  all silently dead. A Lock tile would have been meaningless (fact 91).
- **Sleep must not lock.** hypridle already has `before_sleep_cmd = loginctl
  lock-session`, so the tile is `systemctl suspend` alone.

Also measured, and it explains an older mystery: `focus: true` on a panel root
does NOT give it activeFocus, and no key event arrives at all. The control
centre's Escape only ever worked because a child of it holds focus and the key
propagates up. Every keyboard panel now gets `claimFocus()` (fact 90).

Verified with `wtype`: arrow navigation, Return arming Shut down into
"Press again", Escape disarming without closing, Escape again closing. Lock and
Sleep were NOT triggered - they would have locked or suspended the machine.

## The leaving veil, and a blur threshold

"Ấn sleep thì nó kiểu không có chuyển gì xảy ra xong vài giây sau tự nhiên đi
ngủ." A real gap: `systemctl suspend` takes a second or two and nothing said so.

Now `IslandState.leaving` raises a full-screen veil and grows the island into
"Sleeping" / "Restarting" / "Shutting down", and the command only goes out once
that has settled. The veil lives inside the island window, which was already
full-screen and transparent, so the architecture rule holds.

It took two measurements to get right. First: Qt WAS drawing the veil
(1366x768, black, opacity 0.55, visible - logged) and the screen dimmed
(luminance 75.8 -> 34.4) but nothing blurred. Cause: `hyprland/rules.lua` sets
`ignore_alpha = 0.79` for every `quickshell:.*` layer, and that is the threshold
below which Hyprland SKIPS blur. The island's 0.88 fill cleared it; a 0.5 veil
did not. Fixed with a 0.3 rule for `quickshell:dynisle` alone - not 0, because
the island canvas is fully transparent and 0 would blur the whole screen
forever.

The wallpaper grid also takes arrow keys and Enter now. Verified by driving it:
3x Right, Down, Enter changed the wallpaper from `bridge.png` to `fall.png` and
saved it.

## The island travels

"Mình muốn cái bar nó sẽ di chuyển xuống giữa màn hình, to ra và sleeping ở đó,
mở máy thì ban đầu nó cũng sẽ hiện cái bar siêu to ở giữa với tên là welcome."

Both bookends now exist and are one mechanism: `IslandState.centred` drives the
shape's `y`, the veil, and the window's top margin together. The shape moved
from `anchors.top` to a `y` binding with a 560ms curve - at `animDuration`
(150ms) crossing the screen read as a jump rather than a journey.

Two real bugs came out of the user's report, and the first was mine:

- **It never actually slept.** The command was fired from a Timer inside
  SessionPanel, and `beginLeaving()` closes that panel first - so the Loader
  destroyed the panel and its Timer before it could fire. Proven by stubbing
  `Session.sleep()` to touch a marker file: after moving the Timer into
  `IslandState`, the marker appears (fact 96).
- **The veil was not full screen.** `margins.top: Theme.screenGap` moves the
  SURFACE, so the top 7 pixels could not be painted at all. Zeroed while
  centred; verified row y=0 luminance 30.1, matching the rest of the veil.

## Sleep now, greet on the way back

"Từ lúc khi đặt lệnh sleep thì phải một lúc sau nó mới sleep... sau khi bật máy
lại lên thì nó thành welcome."

The 900ms delay existed so the island could finish travelling before the
machine stopped responding. Wrong trade: it made the machine feel like it had
ignored the press. Now 200ms - measured at 228ms end to end with a marker file -
and the travel animation simply plays into the suspend, where the dark screen
hides the fact it never finished.

Resume closes the loop. hypridle's `after_sleep_cmd` was dispatching
`quickshell:lockFocus`, yet another end4-pC-only global doing nothing; it now
dispatches `dynisleWoke`, and dynisle answers by dropping the veil and greeting.

The greeting cannot start on resume, though: `before_sleep_cmd` locks the
screen, so it would play out entirely behind hyprlock while the password was
being typed. Hyprland does emit `openlayer`/`closelayer` (verified with fuzzel),
but hyprlock is an ext-session-lock client, not a layer surface, and is
hypridle's child rather than ours - so `pidof hyprlock` is polled at 800ms, only
between waking and unlocking. A wall-clock-versus-monotonic guard backs it up,
because a veil stuck on for ever would mask the entire screen.

## The gap on the way back

The user timed the resume precisely: sleeping screen (a stale framebuffer, not
ours), then it vanishes, then THE BARE DESKTOP, then blur and welcome.

The middle step was the bug. `wokeUp()` dropped the veil immediately while the
greeting waited on a `pidof hyprlock` poll - so between unlocking and the next
poll tick there was nothing covering the screen. The poll now decides only when
the greeting's countdown STARTS; the greeting itself is drawn the instant we
wake, behind the lock screen. The veil never dips.

Found while fixing it: `beginLeaving()` still called `leavingTimer.restart()`
after that Timer had been deleted - a ReferenceError on every sleep, harmless
only by accident of being the last line of the function.

## The greeting's exit

The user described it precisely: the Welcome text vanishes, the box loses some
of its corner, the full-screen blur opens a gap at the top, and only then does
the box become the bar. Three separate jumps, all on one frame, because
`greeting` going false swapped the panel, changed `radiusHint`, and flipped
`margins.top` simultaneously - and none of the three was animated.

Fixed as three: `margins.top` is now permanently 0 with `exclusiveZone`
carrying the gap (reserved measured identical at [0, 49, 0, 0]); `IslandShape`
has a `Behavior on radius`; and the greeting fades its words out over 260ms
before anything else is allowed to move.

The lock-screen-after-sleep and the occasional rejected-but-correct password
are hyprlock/PAM, predate dynisle, and the user explicitly asked not to spend
time on them.

## The blur that was never there

"Màn ko blur, nó chỉ transperent và hiện toàn bộ windows đằng sau." Correct, and
the cause was a line I had added myself: `blur:new_optimizations = false`, set
to avoid a stale blur cache. On Hyprland 0.56.2 that switch disables blur for
LAYER SURFACES completely, and dynisle is a layer surface.

It survived several sessions because I had checked it against a dark, smooth
desktop, where dimming alone drops the edge score - I read 2.37 as "blurred"
when the clear baseline was 2.79. The honest test is the clear frame of the
SAME desktop: 14.20 clear, 6.74 veiled, nothing readable.

Turning the cache back on revived xray (rules.lua sets it for every namespace),
so the veil blurred a snapshot of the wallpaper instead of the windows. Fixed
with a per-layer `xray = false`; the global option does not cover per-layer
rules.

Also fixed: the veil is now a curtain (constant alpha, animated height) because
fading opacity from 0 spends its first third under `ignore_alpha` and the blur
pops in; the greeting's words take 380ms to leave before anything else moves;
and the greeting takes the hover latch, so a pointer resting on it no longer
turns into the media panel on the way out.

## Locked out by my own greeting

"Oh god, mình bị stuck ở cái welcome rồi." The greeting never ended and its veil
masks the entire screen, so the machine was unusable. Freed with `pkill -x qs`.

Cause, found in one command: `pidof hyprlock` returned 18240 while the user was
typing normally. hyprlock on this machine does not reliably exit after a
successful unlock - the same fault as their long-standing "right password,
still locked out" - and I had made the greeting's countdown WAIT for that
process to disappear. It never did.

The design error is the lesson, not the bug: nothing that blocks input may
depend on a signal that might not arrive. The poll is gone; the countdown runs
on a fixed delay. Two escape hatches now exist regardless - a full-screen click
and any key - and both were driven and verified rather than assumed.

Getting the key hatch working turned up a second fact: a layer surface asking
for Exclusive keyboard focus from its very first frame never receives keys,
because Hyprland acts on the None -> Exclusive transition and there was none.

## The lock screen exists

Option A with the clock, as chosen. Blurred wallpaper, big clock, date, and one
password field - no outline, a dark pill darker than what is behind it, no user
label, and none of the two script-backed labels that pointed at files this
machine does not have.

Previewing it needed care: `hyprlock --grace 90` locks for real, and killing an
ext-session-lock client can leave the compositor locked with nothing to type
into. One preview did stick; `loginctl unlock-session` released it. That command
belongs in the notes before anyone previews this again.

Alongside: sleep now fires 1477ms after the press (measured) so the island lands
before the machine stops, and the greeting's words shrink with the box instead
of blinking out ahead of it.

The rise had one more fault after that: the panel was swapped for the clock
mid-flight, so the content faded in from zero while the shape resized halfway
across the screen. Now the box shrinks in place to exactly the pill's size and
only then rises, which makes the handover invisible.

## One clock for one motion

"Ở đoạn này ta toàn bị lỗi này đè lỗi kia, cẩn thận đấy" - fair, and the reason
was always the same: two animations of different lengths. Shrink 300 against
rise 560 put the panel swap mid-flight; shrinking first and rising after made
the words leave ahead of the box.

`Theme.islandTravel` (560ms) and `Theme.islandTravelEasing` are now the single
clock for the shape's y, the panel's implicit size, the words' scale and the
swap timer. They cannot drift apart because they are the same number.

The fourth attempt found what the first three had all missed: the box could not
shrink, because `islandMinWidth: 520` on GreetingPanel is a floor the shape
applies with `Math.max`. Everything done to the panel's content was invisible
underneath it. With the floor lifted, `IslandShape`'s own width/height
Behaviours still ran at 150ms, so the shrink finished long before the rise -
those now run on the journey's clock too.

## Cleaning up after myself

"Ấn sleep = hiện animation + chạy lệnh sleep thế thôi... Không bịa bug, truy
thật và dọn rác."

Deleted from IslandState: `wokeUp`, `sleepGuard`, `lastTick`, `pendingGreeting`,
`lockWatch`, `lockProbe`, and the `Quickshell.Io` import that only the poll
needed. Each had been added to patch the one before it. What is left is
`beginLeaving` -> `commit` (fire the command) -> `release` (drop the veil
unconditionally). Nothing waits for the machine to come back.

The greeting now hangs off the unlock rather than the resume: hypridle's
`$lock_cmd` runs hyprlock and dispatches `dynisleUnlocked` when it exits. If
hyprlock ever hangs, the greeting just never plays - a missing animation, not a
masked screen.

The boot audio gap was real and had nothing to do with dynisle: the journal
shows easyeffects starting at 18:27:38 and pipewire at 18:27:39, because
pipewire is socket-activated and easyeffects was what woke it. execs.lua now
starts the sound server first and waits for `pactl info`. rtkit is also simply
not installed.

## Two faults that were never dynisle's

The frozen wake: `journalctl -b -1` ends on `PM: suspend entry (deep)` with
nothing after it. The kernel never resumed. Across boots, deep suspend resumed
6/6, then 8/9, then 0/1 - unreliable on this Asus TP300LA. The "stuck sleep
box" is just the last framebuffer. s2idle is available and is the user's call
since it costs battery and needs root.

The boot audio: EasyEffects takes the default sink and starts it at 0%.
Reordering startup did nothing because timing was never the problem. It came
from the inherited setup, was never asked for, and is no longer started.

## Correcting myself on the frozen wake

I blamed the hardware from missing journal lines. That was wrong twice over:
hard power-offs lose buffered log, so absence proved nothing, and the user said
it happens every single time.

The complete log of the one resume that did get written shows the machine
resuming fine, the password accepted, and then - six seconds later - a fresh
`systemctl suspend` from within the user session. hypridle never ran its
suspend command that boot; dynisle's `Session.sleep()` is the only other
caller on this machine.

I could not prove how it fires twice, so I did not pretend to. `sleep()` now
refuses a second request inside 45 seconds using the WALL clock, and every
session action is logged to ~/.cache/dynisle/session.log so the next time there
is a record.

dynisle is also out of the lock/sleep/resume path completely now. Both hooks
are gone. During a test I locked the screen by accident and `loginctl
unlock-session` would not release hyprlock - twice - which is exactly the
user's old "right password, still locked out". An animation is not worth a
moving part in there.

## The freeze was the lock screen, and it was mine

"Âm thanh bị lỗi, lặp đi lặp lại lúc bị đơ" was the clue that turned it around:
a looping audio buffer means the kernel stopped scheduling, so the machine hung
GOING DOWN, not coming back. And it hung exactly as the lock screen appeared.

`before_sleep_cmd = loginctl lock-session` starts hyprlock inside the suspend
window. The lock config I wrote had it load a 1672x941 PNG and blur it four
passes on a Broadwell iGPU right there. The config it replaced painted a flat
colour and did no GPU work at all - which is why twenty suspends in a row
worked before this, and none after.

`scripts/lock-wallpaper` now bakes the blur when the wallpaper changes, and
hyprlock draws a flat image in 52ms.

My two earlier conclusions were both wrong and are marked as such in the notes:
it was not flaky hardware, and it was not a second suspend after resume.

## The welcome waits

With the sleep freeze actually fixed, the two hooks could come back - the ones
removed while it was still unexplained. The greeting is now ARMED on resume:
drawn behind the lock screen, veil up, clock not running. hyprlock's exit
starts the clock, so the welcome is already there the instant the lock goes.

Two things guard it. It does not take the keyboard while armed, because
exclusive focus over a live hyprlock is how you swallow someone's password. And
a 25s cap starts the clock regardless, because waiting for ever on another
program's message is what locked the user out earlier today.

## Loose ends

foot was the last thing not following the wallpaper - its `[colors]` section
held only `alpha`. It has a matugen template now, included from the top of
foot.ini, and `foot --check-config` is silent for the first time (it had been
warning that `[colors]` is deprecated).

`CTRL + SUPER + T` unbound: end4's switchwall.sh changed the wallpaper behind
dynisle's back, which now also means the lock screen's baked background would
be stale for the new picture.

## USB notifications: the blank line that never came

The user was right to push back - I twice changed logic that was never reached.
What settled it was logging every raw line the parser received: udevadm's two
header lines arrived, the blank line after them did not. Quickshell's
SplitParser drops empty segments, and udev separates event blocks with exactly
that, so `flushDevice()` had never run once.

Flushing now keys off the next event's header line and a 150ms idle timer. The
speculative `stdbuf` changes were reverted; a one-line test showed udevadm's
output comes through a plain pipe immediately.

## 2026-09-29 - Removing the greeting, colours that reach grey, install.sh

- Greeting + leaving veil removed entirely (fact 131). Sleep is a command.
- Colour picker: two source buttons, every swatch clickable, black/grey/white,
  and fixed colours through `scheme-fidelity` - the default scheme had been
  turning black pink and grey cyan (fact 132).
- install.sh + dots/ + README + .gitignore (fact 134). Quickshell 0.3.1 from
  extra verified against a copy of dynisle first (fact 133).
- Found on the way: terminals run fish, so the neofetch hook never ran (now
  fastfetch in config.fish); hyprsunset was never started, so Night light was
  dead (now a user unit).
