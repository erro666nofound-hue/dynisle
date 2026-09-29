---
title: Session handoff prompt
updated: 2026-09-01
---

# Handoff

Paste the block below into a fresh Claude Code session started in
`~/.config/quickshell/dynisle`. **Keep this file updated at the end of every
session** — it should always reflect confirmed state, never assumed state.

---

```
I'm building dynisle — a custom Quickshell dynamic-island shell for Hyprland
on Arch. Before doing anything, read these in order:

  1. vault/notes.md          — facts that must never be silently dropped
  2. vault/05-session-log.md — what actually exists vs what doesn't
  3. vault/09-ultra-tasks.md — the 14-task roadmap and where we are
  4. vault/07-architecture.md — folder layout, module system, blur pipeline

Then look at vault/assets/reference-screenshots/ — that's the target UI.

How I want you to work:
- One Ultra Task at a time. Finish it, tell me exactly what to run/look at,
  then WAIT for my ok before starting the next. Don't batch work.
- Before each task: restate the goal, re-read the real code, write a short
  plan, self-critique it for bugs, fix the plan, then implement.
- Self-verify before asking me. grim is installed — screenshot your own work
  and check it rather than spending my feedback rounds.
- Use subagents/forks for bulky research (reading end4-pC's big reference
  files), but not for small work you already have context for.
- Never modify ~/.config/quickshell/ii or end4-pC — reference only.
- Update vault/05-session-log.md and vault/09-ultra-tasks.md as you go.

Tell me which Ultra Task is next and your plan for it before you start.
```

---

## Current state as of 2026-09-01 (update this section each session)

- **Done:** pipeline proof, idle shape, compositor blur, wallpaper pin,
  **UT-01 restructure** (signed off), **UT-02 theme singleton**,
  **UT-03 clock** (time only, 12-hour AM/PM), **UT-03b island-as-a-bar**
  (exclusive zone + fullscreen hide + equal 7px gaps), **UT-03c blur/opacity
  fix** (the global `no_blur` window rule in `hyprland/rules.lua` was the real
  culprit — see `09-ultra-tasks.md`).
- **UT-05 done:** the island is sized by its content and animates between
  sizes (`notes.md` fact 16 — two traps in there that will silently break it).
  Idle pill is 102×40, clock at pixelSize 16.
- **UT-06 done (slice 1 of 3):** hover expands the island into a panel —
  clock + full date, divider, media row. Media art/text/cava are placeholders.
  The window is now a FIXED 720×480 masked canvas; read `notes.md` fact 16b
  before touching `Island.qml`, this is easy to regress.
- **UT-07 done (slice 2 of 3):** real MPRIS in the expanded panel - art,
  title, artist, transport. `services/Media.qml`.
- **Next:** UT-09 (cava, slice 3 of 3) →
  **UT-08 launcher, pulled forward by user decision** → UT-04 week strip.
- **Still unverified by a human:** the clock text's size/weight/position. The
  user was in a fullscreen game all session, so the island was correctly
  hidden and it could not be screenshotted.
- **Handed to the user, not done by Claude:** the system timezone is `UTC`,
  which is why every clock reads 7 hours behind. Needs
  `sudo timedatectl set-timezone Asia/Ho_Chi_Minh`, then restart dynisle so Qt
  picks up the new zone.
- **Running:** `qs -c dynisle` started manually in the background. dynisle is
  the *only* shell on the system — no bar, launcher, tray, or notifications
  exist. Nothing autostarts it; after a reboot run `qs -c dynisle &`.

## Wallpaper: one panel, folders

- `SUPER + A` -> `modules/panels/wallpaper/WallpaperPanel.qml`. Two views:
  `grid` (the folder's pictures) and `folders` (the folders it knows plus an
  Add card), switched by `IslandState.wallpaperView`.
- `services/Wallpapers.qml`: `roots` / `folder` / `current`, persisted in
  `config/wallpaper.json`. Listing is a `FolderListModel` - no process, and it
  watches the directory (notes.md fact 88).
- Adding a folder runs `scripts/pick-folder`, which asks the XDG portal - the
  same dialog the browser opens for a file upload. It needs the
  `xdg-desktop-portal-gtk` float rule in `custom/rules.lua` or Hyprland tiles
  it off-screen (fact 89).
- `config/themes.json` is read once, only if there is no folder state, to
  recover folders from the themes era. It has NO path until then, because a
  `FileView` with one loads eagerly and races the real reader (fact 81).
- Themes existed for a few hours on 2026-09-03 and were removed -
  `06-decisions.md`. `SUPER + S` is no longer ours.
- `HeaderChip.qml` and `SheetButton.qml` sit beside the panel as shared files.

Facts 81-84 and 86-88 came out of building this. Read 81 (eager `FileView`),
83 (the `activewindow` guard) and 87 (an empty `Image.source` never becomes
Ready) before touching any of it.

**Not tested by me** (needs clicks): the folder chip opening the list, picking
a folder, Add folder, forgetting a folder with the hover x, and "No wallpaper"
after the fact-87 fix.

## Session panel (SUPER + S)

`modules/panels/session/SessionPanel.qml` + `services/Session.qml`. Four tiles:
Lock screen, Sleep, Restart, Shut down. The two destructive ones ask twice -
see notes.md fact 92 for what each runs and why.

`hypridle.conf`'s `lock_cmd` had to be fixed first: nothing on this machine
could lock at all (fact 91). If locking ever breaks again, read that fact
before anything else.

Pressing Sleep, Restart or Shut down sends the island DOWN TO THE MIDDLE of the
screen, big, saying "Sleeping" / "Restarting" / "Shutting down" over a blurred
full-screen veil; the command goes out 900ms later, once it has landed. Startup
is the same journey in reverse: "Welcome, <user>" in the centre, then it rises
into the bar (facts 93, 94, 97, 98).

Three things this needs, and each was a bug first: `ignore_alpha = 0.3` in
`custom/dynisle-blur.lua` (or it dims without blurring), `margins.top: 0` while
centred (or the top 7px stay unpainted), and the commit Timer in `IslandState`
NOT in the panel (or it is destroyed before it fires - fact 96).

Resume comes in through hypridle's `after_sleep_cmd` -> the `dynisleWoke`
global. The greeting then waits for hyprlock to exit, polled, because hyprlock
is an ext-session-lock client and no event announces it (fact 100).

The wallpaper grid takes arrow keys and Enter (fact 95).

**Not tested by me**, because they would lock or suspend the machine: the Lock
and Sleep tiles firing for real, and the letter keys L / S. Everything else was
driven with `wtype` and verified - navigation, arming into "Press again",
disarm-on-Escape, close, the veil (with the commands stubbed out), and applying
a wallpaper with the keyboard.

The LOCK SCREEN ITSELF is still unbuilt and deferred by the user. Two designs
are drawn in the artifact above; `hyprlock.conf` still paints flat `#181818`
while matugen already generates an unused `$background_image`, and two of its
labels run scripts that do not exist.
