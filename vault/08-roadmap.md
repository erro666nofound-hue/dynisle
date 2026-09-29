---
title: Roadmap — ordering rationale
updated: 2026-09-01
---

# Roadmap

**The task list itself lives in `09-ultra-tasks.md` — 14 Ultra Tasks, start to
finish.** This file only explains *why* they're in that order, so a future
session doesn't reshuffle them without understanding the dependencies.

## The shape of it

```
Foundation  →  Content  →  Mechanic  →  Features  →  Finish
UT-01,02       UT-03,04     UT-05,06     UT-07..12    UT-13,14
```

## Why this order

**Foundation first (UT-01 restructure, UT-02 theme singleton), even though
neither adds a visible feature.** Both get exponentially more expensive later:
restructuring after five features means moving five features, and retrofitting
a theme singleton after six panels means hunting hardcoded colors through all
of them. These are the only two "boring" tasks in the list and they're both
up front on purpose.

**Content before mechanic (UT-03/04 before UT-05/06).** The clock is the
simplest possible real data binding — service → singleton → rendered text. Get
that path working on something trivial before the state machine depends on it.

**The mechanic is its own checkpoint (UT-05, UT-06).** Expand/collapse motion
is the single most identity-defining thing about a dynamic island, and it's
pure feel — it needs its own iteration round with the user, not to be buried
inside a feature UT where "does the media panel work" and "does the animation
feel right" get tangled together.

**Features are deliberately last and deliberately independent (UT-07..12).**
After UT-06 every remaining feature is "write a service, write a panel, register
a state." They're additive, they don't block each other, and the order among
them is **flexible** — reorder freely based on what the user actually wants
next. The listed order is roughly easy → hard.

**Theme system (UT-12) is last of the features** because it touches every other
module. Doing it before the panels exist means doing it twice.

## Known tension: the launcher

UT-08 sits mid-list by difficulty, but the user currently has **no launcher on
the system at all** (ii stopped, noctalia uninstalled). It only depends on the
panel system (UT-06), so it can move to immediately after UT-06 at no
architectural cost. Ask if they want it pulled forward rather than assuming.

## What "finished" means

UT-14 done: dynisle autostarts on boot, survives a reboot, handles both
monitors, and degrades gracefully with no media / no notifications / no
wallpapers. At that point it's a daily driver, and anything further is polish.
