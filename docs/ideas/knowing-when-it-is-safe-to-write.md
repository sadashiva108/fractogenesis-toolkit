# Knowing when it is safe to write

**Raised:** 2026-09-03, restore-apps session, immediately after two failures
happened in the same sitting.

This is an idea rather than a finding: nothing is broken. Two sessions working
concurrently have no mechanism for the question, and the rule that stands in for
one is a convention a session has to remember rather than something it can check.

**Half of this idea has since been decided and built.** It was raised as two
questions — which revision number is free, and which files are safe to touch.
The first was answered by
[`0028`](../cross-cutting-findings/0028-sessions-write-into-the-tree-the-owner-commits-from/):
the number is taken at apply time by `bin/check-manifest-revision.sh`, which
scans the entry headings as well as the header block and so sees the uncommitted
entry that defeated the old rule. That half is no longer an idea and is not
restated here. What remains open is the second question, below.

## The failure this idea is still about

**A session bundle was created twice.** The restore-apps session was asked to
create one for the concurrent session, and did — while the concurrent session was
creating its own, under a different name, in the same minute. Both were correct;
one had to be deleted. The same minute also produced two rows for that bundle in
`docs/sessions/INDEX.md`.

## What exists today

- `docs/sessions/session-responsibilities.md` — one file, one owner, written by
  hand. It describes two sessions from 2026-09-01 and has not tracked a session
  since; it is the right idea, kept manually, and manual is why it is stale.
- Each `owned` session bundle's `findings-manifest.md`, which says what a session
  owns but not what it is holding open right now.
- `git status`, which shows another session's uncommitted work — the only
  mechanism here that ever worked, and only because someone looked. Since `0028`
  a session composes in its own copy, so the owner's tree is usually clean and
  `git status` no longer shows a concurrent session at all. The observability it
  gave up has not been replaced.

## Shapes worth considering

Sketched, not chosen; whichever is picked wants its rejected alternatives written
down, at which point it becomes an architecture record.

- Each `owned` session bundle declares the files it is holding, and a session
  reads the other bundles before its first edit. Closest to
  `session-responsibilities.md`, but per bundle and therefore maintained by the
  session that knows.
- Derive it instead: `git status` plus the session bundles already say who is
  writing what, and a helper could report *these paths are dirty and this bundle
  claims them*.
- A pre-write hook that refuses an edit to a file another `owned` bundle claims.
  Strongest, and the one most likely to obstruct legitimate work.

## What is not proposed

Reserving files in advance, for the same reason revision numbers are not
reserved: a claim that is never released blocks work nobody is doing.

## Note

`0027` and `0028` have both been resolved since this was raised, and both bear on
it. `0027` settled how sessions declare what they own; `0028` moved composition
out of the shared tree, which removed the collisions this idea's first half was
about and removed `git status` as the informal signal at the same time. Re-read
this against both before anything is built.
