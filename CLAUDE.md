# dynisle

A custom Quickshell "dynamic island" shell for Hyprland (Arch Linux), built in
the spirit of saneAspect's Quickshell teaching content — not a clone of
illogical-impulse/`ii` or Noctalia, both of which live alongside this folder
as reference only (`../ii`, `../end4-pC`) and must not be modified by work on
this project.

## Before doing anything in this project

Read, in order: `vault/notes.md` (short digest of facts that must never be
silently dropped), then `vault/00-README.md`, then `vault/05-session-log.md`,
then `vault/09-ultra-tasks.md` for the current task. The vault is the source
of truth for architecture, research, and decisions — it exists specifically
to stop hallucinated claims about what has or hasn't been built. Don't state
a file, module, or decision exists unless it's in the vault or you just
verified it on disk.

Work proceeds **one Ultra Task at a time** (`vault/09-ultra-tasks.md`). Before
starting one: restate the real goal, re-read the relevant real code (this
project and `../ii`/`../end4-pC` for grounding — never modify those two) and
vault files, write a short plan, self-critique it for bugs, fix, then
implement. After finishing one, stop and tell the user exactly what to
run/look at to test it — wait for feedback before starting the next one.

Update `vault/05-session-log.md` before ending a session or when asked to wrap
up: what changed, what's next. Update `vault/09-ultra-tasks.md`'s Completed
section too.
