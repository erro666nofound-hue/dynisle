---
title: "Research: saneAspect"
updated: 2026-09-01
---

# saneAspect research

## Who they are

YouTube channel: [@saneAspect](https://www.youtube.com/@saneAspect). Makes
content about Hyprland + Quickshell setups.

## Confirmed via oEmbed lookups (title + channel verified, not guessed)

- ["The Prettiest Quickshell Setup You've Ever Seen"](https://www.youtube.com/watch?v=wcm95W876OU) — author confirmed `saneAspect`
- ["Here's everything you need to make a Quickshell bar on Hyprland today"](https://www.youtube.com/watch?v=EG41Kjtqh40) — author confirmed `saneAspect`

## Seen in search results, channel not individually re-verified per video

- "Quickshell Is a Joy To Use on Hyprland"
- "So I've been working on this new Quickshell feature…"
- "Is Quickshell Hyprland's Future?"

These titles came back under the same query cluster as the two confirmed
videos and match the channel's known subject matter, but I did not run an
oEmbed check on each one individually — don't treat channel attribution on
these as fully confirmed the way the two above are.

## The "teaches, doesn't publish dots" pattern — confirmed

`github.com/saneaspect` has 9 public repos. The relevant one is
[`saneaspect/dotfiles`](https://github.com/saneaspect/dotfiles) ("My Hyprland
dotfiles", 171 stars) — but its actual contents are an **older Waybar + Wofi +
Alacritty setup with the Everforest GTK theme**, not a Quickshell dynamic
island. None of the 9 repos (`dotfiles`, `env`, `fonts`, `hyprstylish`,
`sane1090x.github.io`, `sf-fonts`, `test-dots`, `theme-switcher`, `vitreous`)
is a published Quickshell dynamic-island shell.

This matches exactly what the user described: saneAspect teaches the
Quickshell techniques on video but does not ship the polished dynamic-island
configs as ready-to-clone dotfiles. There is no repo to clone or diff against —
**the island has to be built from the video-demonstrated concepts and the
user's own description, not copied from a source tree.**

## What I could NOT verify

- I could not pull transcripts or frame-by-frame visual detail from the videos
  themselves (YouTube's watch pages are JS-rendered; oEmbed only gives
  title/author/thumbnail, not captions). So exact widget layout, animation
  curves, corner radii, exact color palette, etc. used in saneAspect's own
  island are **not confirmed** — only the general concept (single island,
  minimal, wallpaper/clock/date/media/cava/launcher/theme, blur) as relayed by
  the user.
- If the user wants pixel-accurate replication of a specific video's look, the
  fastest path is the user pointing to a specific timestamp/screenshot rather
  than me guessing from search snippets.

## Implication for `dynisle`

Treat this as **"build in the spirit of," not "clone."** The vision doc
(`01-vision.md`) — written from the user's own words — is the real spec.
Use saneAspect's public videos as directional inspiration/validation once we's
building (e.g. "does this match what you saw in his videos?") rather than as a
source of extractable implementation detail.
