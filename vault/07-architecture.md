---
title: Architecture
updated: 2026-09-01
---

# Architecture

Grounded in: Quickshell 0.2.1 / Qt 6.11.2 / Hyprland 0.56.2 as installed, the
Quickshell docs on the `qs.*` module system, and live inspection of
`~/.config/quickshell/end4-pC` (a real 300+ file working shell).

Anything marked **PLANNED** does not exist yet. Never describe it as if it does.

## The core idea: one surface, many states

A conventional shell (end4-pC, noctalia, caelestia) draws **many separate
layer-shell surfaces** — a bar, a dock, a launcher, a notification popup, an
overview. end4-pC has 24 such folders under `modules/ii/`.

dynisle has **exactly one visible surface**: the island. Everything a normal
shell puts in a separate window becomes a *state* of that single surface.
This is the whole design, and it drives the folder layout:

| A normal shell has… | dynisle has… |
|---|---|
| `bar/` | `island/` — the one persistent surface |
| `launcher/` | `panels/launcher/` — rendered **inside** the island |
| `notificationPopup/` | `panels/notifications/` — inside the island |
| `mediaControls/` | `panels/player/` — inside the island |
| `wallpaperSelector/` | `panels/wallpaper/` — inside the island |
| `settings/` (own window) | `panels/themes/` — inside the island |
| `dock/`, `overview/`, `sidebar*/` | *(not built — not wanted)* |

So: **`panels/` are not windows.** They are content swapped into the island
by `IslandState`. There is one `PanelWindow` for the island, ever.

## Reality check — what exists RIGHT NOW

```
dynisle/
  shell.qml     # 54 lines, everything inline. Two PanelWindows. That's all.
  CLAUDE.md
  vault/
```

`shell.qml` currently holds: (1) a fullscreen wallpaper `PanelWindow` on
`WlrLayer.Background` showing `~/Downloads/Clouds.png`, and (2) the island
`PanelWindow` — a 180×40 `Rectangle`, `radius: 20`, alpha 0.88, **empty**.

No `services/`, no `modules/`, no state machine, no content. The first
structural task is breaking this monolith apart into the layout below.

## Module system (Quickshell 0.2+) — how files find each other

Verified from Quickshell docs and from end4-pC's real usage:

- **Every subdirectory automatically becomes a QML module** named
  `qs.<path>`. `services/` → `import qs.services`. `modules/panels/player/`
  → `import qs.modules.panels.player`.
- **Do NOT write `qmldir` files.** Quickshell's QmlScanner synthesizes them.
  (end4-pC has zero `qmldir` files and imports `qs.modules.common` fine.)
- **Singletons**: `pragma Singleton` on line 1, and the root item must be
  `Singleton { }`. Then `import qs.services` and use it by name —
  `DateTime.timeString`.
- Components are files with **Uppercase** names; the filename is the type name.
- Add a **`.qmlls.ini`** in the shell root — Quickshell auto-populates it and
  it gives the QML language server working autocomplete for `qs.*` imports.

Example service header (end4-pC's actual convention):

```qml
pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    // ...
}
```

## PLANNED folder layout

```
dynisle/
  shell.qml                  # ShellRoot only — wires windows together, no UI logic
  .qmlls.ini                 # LSP config, auto-populated by Quickshell

  modules/
    island/
      Island.qml             # THE PanelWindow. Owns size + blur surface + animation
      IslandState.qml        # singleton: which panel is showing
      IslandShape.qml        # the rounded rect + fill/alpha (blur-critical, one place)
    panels/                  # CONTENT swapped into the island — never windows
      idle/     IdlePill.qml         # clock + date, the resting state
      player/   PlayerPanel.qml      # MPRIS: art, title, transport
      cava/     CavaBars.qml         # audio visualiser
      launcher/ LauncherPanel.qml    # app search + results
      wallpaper/WallpaperPanel.qml   # wallpaper grid
      themes/   ThemePanel.qml       # curated scheme grid
      notifications/NotificationPanel.qml
    wallpaper/
      WallpaperLayer.qml     # the fullscreen background window (its own surface)
    common/
      Theme.qml              # singleton: active colors, radii, spacing, fonts
      Typography.qml         # text styles
      widgets/               # shared small components (IconButton, etc.)

  services/                  # singletons wrapping system state, no UI
    DateTime.qml  Media.qml  Cava.qml
    Wallpapers.qml  Themes.qml  Launcher.qml  Notifications.qml

  config/
    themes/                  # one JSON per curated scheme (catppuccin, gruvbox…)
    wallpapers.json          # wallpaper path → paired scheme name

  vault/                     # docs (this file)
```

**Rule: `services/` never imports `modules/`.** Data flows one way — services
expose state, modules render it. This keeps panels swappable and testable.

**Rule: only `Island.qml` and `WallpaperLayer.qml` create `PanelWindow`s.**
If a new file ever creates one, that's a design smell — question it.

## The island state model

```
Idle | Player | Launcher | Wallpaper | Themes | Notifications
```

`IslandState` is a singleton holding the current state plus the target
size for it. `Island.qml` binds `implicitWidth`/`implicitHeight` to that and
animates between values — the "dynamic" in dynamic island. Panels are loaded
via `Loader` so inactive panels cost nothing.

## The panel window pattern (verified, in use)

**The window is a fixed, still, transparent canvas. Only the shape inside it
moves.** An earlier version bound the window to the island's animated size
(`implicitWidth: shape.width`). It read elegantly and animated terribly:
resizing a layer-shell surface makes the compositor reallocate and re-commit it
on every frame. The user reported it as "giật kinh khủng" and correctly
identified the cause. Do not go back to it.

```qml
PanelWindow {
    anchors.top: true        // only top → layer-shell auto-centers horizontally
    margins.top: Theme.screenGap
    color: "transparent"     // the WINDOW is invisible

    WlrLayershell.namespace: "quickshell:dynisle"

    // FIXED. Big enough for the largest panel, never animated.
    implicitWidth: Theme.islandMaxWidth      // 720
    implicitHeight: Theme.islandMaxHeight    // 480

    // Reserves only the idle strip — an expanded panel overlays the desktop
    // instead of shoving every window down the screen.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.islandMinHeight + Theme.screenGap - Theme.compositorGapsOut

    // Without this, that transparent canvas swallows every click meant for the
    // windows underneath it. Same pattern as end4-pC's Bar.qml and Dock.qml.
    mask: Region { item: shape }

    IslandShape {
        id: shape
        anchors.top: parent.top                            // NOT centerIn —
        anchors.horizontalCenter: parent.horizontalCenter  // the window is tall
    }
}
```

Blur still follows the island and not the whole 720×480 canvas, because
Hyprland's `ignore_alpha 0.79` excludes the transparent pixels from blurring.
That is precisely *why* an oversized transparent window is safe here.

## The blur pipeline — four links, all must hold

Blur is the one non-negotiable aesthetic. Any broken link silently degrades
it into flat transparency, which is the look the user rejects.

1. **Namespace** — `WlrLayershell.namespace: "quickshell:dynisle"`.
2. **Layer rule** — `~/.config/hypr/hyprland/rules.lua` already applies
   `blur = true` + `ignore_alpha = 0.79` to `quickshell:.*`, which matches us.
   **No new layer rule needed — don't add a redundant one.**
3. **Fill alpha above the floor** — `ignore_alpha 0.79` excludes pixels
   *below* 0.79 alpha from blur. Island fill must stay **>0.79**. Working
   band **0.85–0.90**, currently **0.88**. Keep this in `IslandShape.qml`
   only, so there's a single place to tune it.
4. **A real blur radius** — `decoration:blur:size`. ii's generated
   `shellOverrides/main.lua` forced this to `1` (invisible blur); now
   hand-set to **8**, `passes 3`, `popups true`, `active_opacity 0.88`,
   `inactive_opacity 0.82`. See `notes.md` fact 13.

Runtime testing: `hyprctl keyword` does **not** work here (Lua parser). Use
`hyprctl eval 'hl.config({ decoration = { blur = { size = 8 } } })'`.

## Services — read these before writing them

| Service | Wraps | Read first |
|---|---|---|
| `DateTime.qml` | system clock | `end4-pC/services/DateTime.qml` |
| `Media.qml` | `Quickshell.Services.Mpris` | `end4-pC/services/MprisController.qml` |
| `Cava.qml` | `cava` via `Process` | `end4-pC/scripts/cava/*` — parsing already solved |
| `Launcher.qml` | desktop entries | `end4-pC/services/LauncherApps.qml`, `AppSearch.qml` |
| `Notifications.qml` | `Quickshell.Services.Notifications` | `end4-pC/services/Notifications.qml` |
| `Wallpapers.qml` | **nothing external** | No wallpaper daemon exists here (`swww`/`hyprpaper`/`swaybg` absent). dynisle renders it itself — build on `WallpaperLayer.qml`; don't add a daemon dependency without asking. |
| `Themes.qml` | curated JSON palettes | New work. `MaterialThemeLoader.qml` does wallpaper-derived Material You — a **different** mechanism. Conventions only. |

## Deliberately deferred

Exact pixel values — animation curves/durations, fonts, per-widget spacing,
final palette — are tuned per Ultra Task against the reference screenshots
and live feedback. See `09-ultra-tasks.md`.
