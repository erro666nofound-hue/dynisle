---
title: Decisions Log
updated: 2026-09-01
---

# Decisions

Settled = don't re-ask. Open = ask before assuming.

## Settled

- **Project name: `dynisle`** (chosen over `nyx`, `islet`), folder
  `~/.config/quickshell/dynisle/`.
- **Shape of the thing: single dynamic island**, not a traditional bar. The
  island IS the shell.
- **Blur, not opacity/glass/transparency.** Real Hyprland compositor blur via
  layer rules on the PanelWindow's namespace, not a QML shader fake-blur or a
  translucent tinted `Rectangle`. Non-negotiable per the user.
- **Feature scope for v1**: wallpaper, clock, date, media player (mpris),
  cava, launcher, theme switching — all inside/behind the island.
- **Don't touch `ii` or `end4-pC`.** They stay as-is, reference only.
- **Build order preference (implied, confirm at build start)**: get the
  island shell + blur right first before layering in every widget — see
  `05-session-log.md` next-step list.
- **Tech approach**: pure QML/JS, singleton `services/` pattern like
  `ii`/`end4-pC`, no custom C++/Go backend (rejected the "Tide Island"/
  DankMaterialShell heavier-backend approach as unnecessary).

## Settled (added 2026-09-01, session 1 continued)

- **Visual reference confirmed.** User shared 4 screenshots (saved at
  `vault/assets/reference-screenshots/`) matching the vision almost exactly:
  top-center pill, idle = clock only, expanded = media player + clock + week
  strip in one row, drop-down panels for theme/wallpaper pickers, near-solid
  dark surface (blur felt at edges, not an obviously see-through pane). Full
  breakdown in `01-vision.md` → "Concrete visual reference" section.
- **No persistent top bar/dock alongside the island** — confirmed by absence
  in all 4 screenshots. Island-only reading was correct.
- **Theming is a curated named-scheme list** (catppuccin, gruvbox, kanagawa,
  nightfox, rose-pine, everforest, etc.), not purely wallpaper-derived
  matugen colors — see picker screenshot. Wallpapers appear tagged with a
  paired scheme name.

## Settled (2026-09-01, shape decision — supersedes earlier shape notes)

- **The island is a simple rounded rectangle, all 4 corners equally rounded,
  floating with a gap below the top screen edge.** It does NOT touch/sit
  flush with the screen edge, and it does NOT have the flared/"pulled out of
  a slot" top corners seen in the reference screenshot.
  **Why:** the user tried the flush + flared-top direction across two
  iterations and chose the simpler option explicitly ("just go ahead and
  choose the easy option, rounded all 4 corners and let it float instead of
  touching the edge of screen"). The custom `QtQuick.Shapes` path attempt
  rendered wrong (bad arc direction) and wasn't worth debugging for the
  aesthetic gain.
  **How to apply:** implement the island body as a plain `Rectangle` with a
  uniform `radius` and a non-zero `margins.top` on the `PanelWindow`. Do not
  reintroduce the flare/notch shape or a zero top margin unless the user
  explicitly asks for it again. Anything in `01-vision.md` describing
  square-top/flush-notch geometry is superseded by this entry.
- Current starting values (tunable, not sacred): `180×40`, `radius: 20`,
  `margins.top: 10`.

## Settled (2026-09-01, the island is a BAR, not a floating overlay)

- **The island reserves screen space and hides on fullscreen.** It is still
  visually a floating rounded rect (the shape decision above stands
  unchanged), but it now behaves like a bar: `ExclusionMode.Normal` with a
  reserved zone, so maximised/tiled windows stop underneath it instead of
  sliding beneath it; and `visible: false` whenever its own monitor's active
  workspace has a fullscreen client, so it never sits on top of a game or a
  video.
  **Why:** user, 2026-09-01 — "cái dynamic island thực ra là bar, nó không
  phải chỉ là một cục nên nó không thể cứ float trên màn hình được và khi
  mình để full screen thì nó phải ẩn đi."
  **How to apply:** the reserved zone is pinned to the *idle* height. When
  the island expands (UT-05/06) it must grow **over** the desktop —
  `ExclusionMode.Auto` would shove every window down the screen each time
  the launcher opens. Fullscreen detection uses
  `Hyprland.monitorFor(screen).activeWorkspace.hasFullscreen` (verified
  present in the installed Quickshell 0.2.1 qmltypes).

- **The gap above and below the island are equal, and both are 7px.**
  User asked for them equalised at 2/3 of the previous value (10 → ~6.7 → 7,
  kept integer for crisp edges).
  **The arithmetic that makes them equal, don't lose it:** Hyprland adds its
  own `general:gaps_out` (5) between the reserved zone and the first tiled
  window, so the island must reserve *less* by exactly that amount:
  `exclusiveZone = idleHeight + screenGap - compositorGapsOut`. Measured
  live: island `y 7..47`, reserved `49`, tiled window content at `y 55`
  (border outer edge 54) → 7px above, 7px below.
  **If `gaps_out` is ever changed in `shellOverrides/main.lua`,
  `Theme.compositorGapsOut` must change with it** or the two gaps drift apart.

- **Launcher (UT-08) is pulled forward** to immediately after UT-06, ahead of
  UT-04/05's remaining polish work. User, 2026-09-01: "phần launcher thì chơi
  luôn". Agreed behaviour: pressing the launcher grows the island, which then
  shows a search field; typing filters apps; results show name + icon.

## 2026-09-03 — Themes removed

Built, then deleted the same day at the user's request: "Thôi bỏ themes đi cho
nhanh." A theme was a named set of pictures with its own colour rule
(from-wallpaper or a fixed hue), and selecting one handed it the desktop.

Why it went: it needed two picture libraries kept in step, two panels, and a
lock deciding which of them owned the desktop - a lot of machinery for
"wallpapers I like, grouped". The user hit real friction with it twice before
calling it (an inert card, and select/deselect looking identical) and chose the
simpler thing over another repair.

What survived: `Wallpapers.library` (the picker's own pictures) and
`Wallpapers.current`. Colours always come from the current wallpaper now.
What went with it: the fixed-colour hue rail, `Theme.previewAccent`, the theme
cards, `SUPER + S` (given back to `hyprland/keybinds.lua`).
The shape is recorded in notes.md fact 85 if it is ever wanted back.

## 2026-09-03 — Folders restored, "add pictures" rejected

Removing themes left their per-picture library behind as the picker's model,
and the user caught it immediately: "hiện tại thì wallpaper không phải chọn
thư mục mà lại thành thêm ảnh."

Back to folders, which is what was designed and approved before themes existed
and what the reference screenshots show: `roots` is every folder the picker
knows, `folder` is the one being browsed, and the header chip
`[ folder <name> v ]` is both the label and the way into the folder list. That
chip is the control the user singled out as the good part of the original
design, so it is back verbatim.

`Qt.labs.folderlistmodel` does the listing declaratively - no `find`, and the
directory is watched. State moved back to `config/wallpaper.json`, whose shape
was already exactly this; `config/themes.json` is read ONCE, only if there is
no folder state, to recover the folders that the themes era's pictures came
from.

## 2026-09-29 - No animation around sleep

The greeting ("Welcome, <user>") and the "Sleeping" veil are removed. Closing
the lid sleeps; the Sleep tile sleeps. Weeks of fixes had each created the next
fault in exactly the part of the machine that was already fragile.

## 2026-09-29 - Colour source is two buttons

"Wallpaper colour" and "Custom colour" on the Wallpaper header, per the user's
exact description. Custom opens the existing colour view, unchanged in layout;
every swatch is now clickable and black/grey/white were added. A redesign was
drafted and rejected ("ko design linh tinh") - modify what exists.

## 2026-09-29 - One repo, one installer

The repo root is the shell; `dots/` holds the configs it depends on and
`install.sh` installs everything from official repos. Push is the user's.

## Open (ask, don't assume)

- **Git init for `dynisle/`?** Was mid-question when the user redirected to
  "research first." Ask again before/at the start of the build session.
- **Exact pixel values**: precise corner radius, sizing breakpoints, animation
  curve/duration, exact font — not derivable from static screenshots alone.
  Propose a first draft and iterate visually once building starts.
- **Panel-fill alpha / how "solid but blurred" is tuned** — needs a live visual
  test against Hyprland's blur once code exists; screenshots tell us the
  target look, not the exact alpha value to start from.
