---
title: Vision & Aesthetic Spec
updated: 2026-09-01
---

# Vision

Source: the user's own description, 2026-09-01. This is the spec — treat it as
authoritative over any inferred "typical quickshell setup" pattern.

## What the user is bored of

- illogical-impulse (`ii`, already present locally at `~/.config/quickshell/ii`)
- Noctalia
- Both are already installed locally as reference/fallback, not to be deleted.

## What the user wants instead

A **single dynamic island** (macOS-style notch/pill UI), not a traditional bar
with a launcher/panel/dock bolted on separately. The island itself is the shell.

The island should host, in one cohesive minimal surface:
- Wallpaper (switching/selection)
- Clock
- Date
- Media player (MPRIS — play/pause/skip, art, progress)
- Cava (terminal audio visualizer, rendered as a live spectrum, likely piped via
  cava's `raw` output format into the island rather than shelling to the cava
  TUI — see `04-technical-reference.md`)
- App launcher
- Theme switching

## Visual language — non-negotiable

- **Minimal.** Not feature-dense chrome, not a control-center-everything panel.
- **Blur, not glass/opacity/transparency.** The user was explicit: they don't
  want a translucent/frosted "glassmorphism" panel with alpha transparency
  showing the desktop through it in the traditional sense — they want real
  compositor-level **blur** behind the island (Hyprland blurring what's behind
  the surface), which reads very differently from a semi-transparent tinted
  panel. This is a strong aesthetic preference, not incidental. See
  `04-technical-reference.md` for the actual Hyprland mechanism
  (`layerrule = blur true` + `ignore_alpha`) — do not implement this as a
  `Rectangle { opacity: 0.6 }` fake-blur or a `FastBlur`/`GaussianBlur` QML
  shader hack unless real compositor blur is proven insufficient.

## Concrete visual reference (2026-09-01)

The user provided 4 screenshots that pin down the actual target look — saved
permanently at `vault/assets/reference-screenshots/`. These now supersede the
earlier "we don't have visual detail" caveat in `02-research-saneaspect.md`
for these specific points. Read the images directly before implementing UI —
this is a summary, not a replacement for looking at them.

**`01-collapsed-idle.png` — idle state:**
A small pill, anchored top-center of the screen, flush with the top edge
(square top corners, rounded bottom corners only — like a real notch/camera
housing hanging off the screen edge). Shows only the time (`15:43`). Very
small footprint — this is the resting state, not a bar.

**`02-expanded-media-player.png` — expanded state:**
The same top-center surface widens into one horizontal row combining:
album art thumbnail (left) → track title + artist/album text → transport
controls (prev/play/next) below the text → clock (top right) → a small
7-day week strip with today highlighted (bottom right, e.g. `W T F S S` with
the current date circled). Everything lives in **one unified row**, not
separate stacked widgets. This appears to be the "hover/active" expansion,
distinct from the idle pill.

**`03-theme-picker.png` — theme switcher panel:**
A panel drops down from the same top-center anchor (title "Theme" top-left)
showing a grid of named color-scheme swatches: `anime`, `ariadne`,
`catppuccin`, `e-ink`, `everforest`, `gruvbox`, `gruvbox-material`, `horizon`,
`industrial`, `kanagawa`, and more (list scrolls/continues) including
`nightfox`. Each entry is a small color-bar preview, not a live wallpaper
preview. **This is a curated list of named schemes** (these are well-known
terminal/Neovim colorscheme names — catppuccin, gruvbox, kanagawa, nightfox,
rose-pine, everforest, horizon are all popular base16-style ports), which
means theming is likely driven by a **static/curated palette set**, not
purely algorithmic wallpaper-color-extraction (matugen). Revise the
`04-technical-reference.md` assumption accordingly — matugen may still be
used for one "auto from wallpaper" entry, but the picker itself is a fixed
list.

**`04-wallpaper-picker.png` — wallpaper switcher panel:**
Same drop-down surface, title "Wallpaper" top-left, and notably **a scheme
name label top-right ("rose-pine")** — meaning each wallpaper is tagged with
a paired color scheme, and picking a wallpaper likely also switches the
active theme to its paired scheme (wallpaper↔theme pairing metadata), rather
than (or in addition to) deriving colors live. Grid of wallpaper thumbnails,
selected one shown with a highlight border.

**Cross-cutting observations:**
- All panels (idle pill, expanded player, theme picker, wallpaper picker)
  share one consistent visual surface: rounded rect, top-center anchored,
  near-black background, and — per screenshots — **read as solid, not
  visibly see-through/frosted.** This doesn't contradict the "blur not
  glass/opacity" requirement — it's consistent with a near-opaque dark fill
  (e.g. alpha ~0.85–0.95) combined with real Hyprland blur (`ignore_alpha`)
  so the *edges* pick up soft blur/depth rather than the surface reading as a
  washed-out translucent glass panel like typical glassmorphism. The
  distinction is subtlety: blur should be felt (soft edge, depth) not
  obviously seen (no visible smeared desktop content through the middle of
  the panel). Don't implement this as a fully see-through blurred pane —
  match the screenshots' near-solid look.
- No visible top bar, dock, or side panel anywhere in any screenshot — full
  confirmation of the "island only, no separate persistent bar" reading in
  `06-decisions.md`.
- Corner radius looks large/pill-like on the idle state, slightly less
  rounded (but still soft) on the wider expanded/panel states.
- Font looks like a clean sans-serif (not monospace) at small sizes; icons
  for playback controls are simple line/glyph icons, not skeuomorphic.

## Non-goals (unless the user asks later)

- Multi-widget bar layout (workspaces indicator, tray, etc. bolted to a top bar)
  — not the ask. If any of that is wanted it should still live inside/around
  the island concept, not as a separate always-visible bar.
- Copying `ii`/`end4-pC`/Noctalia's visual style. Their *code patterns* (Hyprland
  IPC, Mpris service, layer rules) are fair game as engineering reference —
  their *look* is explicitly what the user is moving away from.
