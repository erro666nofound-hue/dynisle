---
title: Technical Reference (grounded facts)
updated: 2026-09-01
---

# Technical reference

Everything in this file was verified on the user's actual machine or against
docs this session — not recalled from training data. Re-verify anything older
than a few weeks before relying on it, since Quickshell moves fast.

## Confirmed local environment (checked 2026-09-01)

- Compositor: **Hyprland 0.56.2** (`hyprctl version`)
- Shell toolkit: **Quickshell 0.2.1** (AUR package `quickshell-git`)
- `cava` 0.10.7-1 installed
- `playerctl` 2.4.1-5 installed
- `matugen` 4.2.0-1 installed (Material You color generation from wallpaper —
  both `ii` and `end4-pC` likely use this for theming; confirms a
  wallpaper-driven theme pipeline is viable without extra deps)
- `wl-clipboard` installed
- `git` 2.55.0

## Blur mechanism (this is the key technical fact behind the whole aesthetic)

Quickshell `PanelWindow`s under Hyprland are layer-shell surfaces. Hyprland can
target them by namespace and apply **real compositor blur**, independent of
the surface's own alpha:

```
# Quickshell sets WlrLayershell.namespace in QML, convention: quickshell:<name>
layerrule = blur true, match:namespace quickshell:<name>
layerrule = ignore_alpha 0.2, match:namespace quickshell:<name>
```

`ignore_alpha` is what makes this "blur, not glass" — it tells Hyprland to
still blur the surface even where it's near-transparent, instead of the blur
only kicking in behind fully-opaque pixels. This is very likely the mechanism
behind the aesthetic the user wants (Hyprland blurring the desktop behind a
mostly-transparent island shape), as opposed to a `Rectangle { color; opacity:
0.x }` translucent panel, or a QML-side `FastBlur`/`GaussianBlur` shader
(Qt5Compat.GraphicalEffects) which blurs the *content behind the QML item*,
not the desktop behind the window — much heavier and lower quality than
compositor blur.

Source: [Quickshell.Hyprland HyprlandWindow docs](https://quickshell.org/docs/v0.2.1/types/Quickshell.Hyprland/HyprlandWindow/),
cross-referenced against end-4/dots-hyprland's layer-rule docs (mirrored on
DeepWiki) and matches the layer rule structure already likely present in
`~/.config/quickshell/end4-pC`'s Hyprland config fragments (not yet inspected
directly — do that before implementing).

## VERIFIED 2026-09-01 — how blur actually works on this machine

Checked live, not assumed:

- Global blur is **on**: `hyprctl getoption decoration:blur:enabled` → `true`,
  `blur:size` 1, `blur:passes` 3.
- The root Hyprland config is **`~/.config/hypr/hyprland.lua`** (Lua format,
  Hyprland 0.55+), not `hyprland.conf` (the `.conf` files there are `.bak`/
  `.old` leftovers). It does `require("hyprland.rules")` on line 17, so
  `~/.config/hypr/hyprland/rules.lua` **is** loaded.
- `rules.lua` already contains, under a `-- Quickshell: illogical-impulse`
  comment:
  ```lua
  hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur_popups = true})
  hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur = true})
  hl.layer_rule({ match = { namespace = "quickshell:.*" }, ignore_alpha = 0.79})
  ```
  The `quickshell:.*` wildcard **already matches `quickshell:dynisle`**, so
  dynisle gets compositor blur for free. **Do NOT add a dynisle-specific
  layer rule or a standalone conf snippet — it would be redundant**, and we
  don't touch the user's live hypr config anyway. (This supersedes the
  earlier plan in `07-architecture.md` to ship a separate snippet; that's
  only relevant if dynisle ever moves to a machine without these rules.)
- `hyprctl layers` confirms our surfaces register as
  `namespace: quickshell:dynisle` (the island) and
  `quickshell:dynisle-wallpaper` (the background layer).

### `ignore_alpha` semantics (confirmed via Hyprland docs/wiki, not memory)

`ignore_alpha <threshold>` excludes pixels **below** that alpha from the blur
pass. With the live threshold at **0.79**, the island's fill must be **more
opaque than 0.79** or blur switches off entirely and it degrades into plain
see-through transparency — i.e. exactly the glassmorphism look the user
rejects (`notes.md` fact 1).

**Practical band for dynisle: alpha ~0.85–0.90.** Currently set to **0.88**
(`Qt.rgba(0.102, 0.102, 0.102, 0.88)` in `shell.qml`). Below ~0.80 → blur
dies. Above ~0.95 → blur becomes imperceptible. Tune inside that band only.

Known Hyprland quirk worth remembering if blur ever looks absent: issue
[#6130](https://github.com/hyprwm/Hyprland/issues/6130) — a `blur` layer rule
may not apply until a window is open on the workspace. An empty workspace can
make blur look broken when the config is actually fine.

**Not yet verified**: the exact rounded-shape masking approach for a pill/island
shape (Quickshell PanelWindow is rectangular by default — a non-rectangular
blurred region typically needs either an `exclusive` layer region trick, a
mask, or relying on the item's own `radius` + Hyprland `rounding`/`blur`
following the surface bounds via `layerrule = blur true` + the window's actual
size hugging the content, i.e. the PanelWindow is sized to just the island, not
full-width). Confirm against a live test once building starts — don't assume.

## Quickshell service pattern used by `ii`/`end4-pC` (for reference, not verified line-by-line)

Both have a `services/` directory of singleton QML files wrapping system state:
`MprisController.qml`, `Audio.qml`, `Wallpapers.qml`, `DateTime.qml`,
`Network.qml`, etc., loaded as global singletons and consumed by `modules/`.
Cava integration lives under `scripts/cava/` (shell scripts, not inline QML) —
worth reading before building the cava widget, since piping cava's raw output
into a `Process`/`SplitParser` is fiddlier than the other services.
