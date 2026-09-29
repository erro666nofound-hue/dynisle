---
title: Vault Index
updated: 2026-09-01
---

# dynisle vault

This vault is the **single source of truth** for the `dynisle` quickshell project.
It exists to stop any AI session (Claude or otherwise) from hallucinating
architecture, file layout, or decisions that were never actually made.

## Rule for any AI session working in this project

0. **Read `notes.md` first, before this file even finishes.** It's the
   short "never silently drop this" digest — the fix for facts getting
   established after many prompts and then forgotten sessions later.
1. **Read `05-session-log.md` next.** It says exactly what exists, what doesn't,
   and what the next step is. Do not assume prior sessions built more than the
   log says.
2. **Never invent a file path, module name, or API and present it as existing.**
   If it's not in this vault or not actually on disk (verify with `ls`/`Read`),
   say so and propose it as new, don't state it as fact.
3. **Update `05-session-log.md` before the session ends** (or when told to wrap
   up) — one entry: what changed, what's next, any open decision.
4. **Update `06-decisions.md`** whenever the user makes a call on naming, scope,
   or tech choice. Don't re-ask a question that's already answered there.
5. Ground technical claims about Quickshell/Hyprland APIs in `04-technical-reference.md`
   or in fresh docs lookups — not memory. Quickshell is a fast-moving project;
   assume anything not verified this session may be stale.

## Files

| File | Purpose |
|---|---|
| `notes.md` | **Read first.** Short digest of facts that must never be silently dropped |
| `01-vision.md` | The aesthetic/UX spec — what we're building and why, in the user's own terms |
| `02-research-saneaspect.md` | Research findings on saneAspect, sourced |
| `03-prior-art.md` | Other quickshell dynamic-island projects checked for architecture ideas |
| `04-technical-reference.md` | Confirmed technical facts (versions, APIs, mechanisms) — grounded, not guessed |
| `05-session-log.md` | Continuity log — read this next every session |
| `06-decisions.md` | Decisions log — settled questions, don't re-ask |
| `07-architecture.md` | Directory layout, state model, the verified PanelWindow/blur pattern |
| `08-roadmap.md` | Phased build order, riskiest/foundational work first |
| `09-ultra-tasks.md` | The actual task backlog — one Ultra Task at a time, checkpointed with the user |
| `assets/reference-screenshots/` | The 4 real screenshots of the target UI — look at these, don't just read about them |

## Status

**Phase: building, UT-by-UT.** See `09-ultra-tasks.md` for the current task
and `05-session-log.md` for exactly what's been done. Work proceeds one
Ultra Task at a time with a user checkpoint after each — never a big
uncheckpointed batch.
