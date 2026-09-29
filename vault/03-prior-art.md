---
title: Prior Art / Architecture References
updated: 2026-09-01
---

# Prior art checked

Not to copy the look of — see `01-vision.md` non-goals — but useful for
engineering patterns (Hyprland IPC, Mpris service wiring, layer rules, blur).

## Already on disk locally

- `~/.config/quickshell/ii` — illogical-impulse, a full-featured Quickshell
  shell (bar, launcher, notifications, cava scripts under `scripts/cava`,
  Mpris service at `services/MprisController.qml`, wallpaper service, etc.)
  Not a git repo (looks like a plain copy, no `.git`).
- `~/.config/quickshell/end4-pC` — end-4/dots-hyprland, **is** a git repo.
  Same service inventory as `ii` plus extras (`LyricsService.qml`,
  `WorldClock.qml`, niri support, `Presets.qml`). This is the upstream project
  `ii` is presumably a fork/snapshot of.
  - Its docs (mirrored on DeepWiki: "Hyprland-Quickshell Integration" and
    "Window Rules & Layer Rules" pages) confirm the layer-rule blur pattern
    used for Quickshell surfaces under Hyprland — see `04-technical-reference.md`.

Both are good places to check *how an existing, working Mpris/Cava/Wallpaper
service is structured in QML* if we get stuck later — not to copy wholesale.

## Other Quickshell dynamic-island projects found via search (not local, not cloned)

- **DankMaterialShell** (`AvengeMedia/DankMaterialShell`) — full desktop shell
  replacement (Quickshell + QML frontend, Go backend), credits Noctalia,
  Caelestia, dots-hyprland as inspiration. Has blur, MPRIS media controls,
  wallpaper-based theming, launcher. No explicit cava mention found. Heavier
  architecture (separate Go backend) than what we likely want.
- **"Tide Island"** (`enhaoswen/Dynamic-island-on-hyprland`) — an actual
  dynamic-island-shaped Quickshell project. Stack is Quickshell/QML **plus a
  C++/Qt6 backend** (CMake build), supports both Hyprland and niri. Features:
  clock, media+lyrics, control center, launcher, wallpaper switcher, cava page,
  power menu. Architecturally closest match to what the user wants
  feature-wise, but the C++ backend is more machinery than a QML/JS-only setup
  like `ii`/`end4-pC` use. Worth a closer look for the *state-machine* approach
  to expanding/collapsing the island shape if we get to that point, but not a
  base to build on top of.

## Verdict

Best approach is almost certainly: **pure QML/JS, no custom C++ backend**,
following the `ii`/`end4-pC` service-object pattern (singleton `.qml` services
under a `services/` dir wrapping `Quickshell.Services.Mpris`, `Process` for
`cava`/`playerctl`, etc.), but with a from-scratch minimal single-island shell
UI instead of their multi-panel bar UI.
