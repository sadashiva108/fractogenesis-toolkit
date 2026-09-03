# Knowing when it is safe to write, and which revision is free

**Raised:** 2026-09-03, restore-apps session, immediately after both failures
happened in the same sitting.

This is an idea rather than a finding: nothing is broken. Two sessions working
concurrently have no mechanism for either question, and the rules that stand in
for one are conventions a session has to remember rather than something it can
check.

## The two failures, both observed

**Two Revision 167s existed at once.** The restore-apps session wrote Revision
167, uncommitted. The concurrent session re-read the header, correctly saw 166 as
the highest committed, and took 167 as well. The manifest held two entries with
the same number until one was renumbered forward, which is the resolution the
Revision 123 collision already set as precedent. The existing rule — *re-read the
header immediately before writing and take the next free number* — was followed
exactly, by both, and produced the collision. **It cannot work while entries are
uncommitted, because an uncommitted entry is not in the header the other session
reads.**

**A session bundle was created twice.** The restore-apps session was asked to
create one for the concurrent session, and did — while the concurrent session was
creating its own, under a different name, in the same minute. Both were correct;
one had to be deleted. The same minute also produced two rows for that bundle in
`docs/sessions/INDEX.md`.

## What exists today

- `docs/sessions/session-responsibilities.md` — one file, one owner, written by
  hand. It describes two sessions from 2026-09-01 and has not tracked a session
  since; it is the right idea, kept manually, and manual is why it is stale.
- The re-read-the-header rule, which the collision above defeated.
- `git status`, which shows another session's uncommitted work — the only
  mechanism here that actually worked, and only because someone looked.

## Shapes worth considering

Sketched, not chosen; whichever is picked wants its rejected alternatives written
down, at which point it becomes an architecture record.

**For the revision number**

- A helper that prints the next free number by scanning the manifest for `##
  Revision N` headings rather than the header block — an uncommitted entry is
  visible to it, which is exactly what the header is not.
- Let the number be assigned at commit rather than at write: an entry is written
  as `## Revision NEXT` and numbered by the owner or a hook when it lands. No
  collision is possible because no number is chosen while two sessions can choose.
- Accept collisions and make renumbering cheap and routine, since the precedent
  already exists and nothing was lost either time.

**For knowing what is safe to write**

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

Reserving revision numbers in advance. The repository already rejected that once,
and for a good reason: a reserved number that is never used leaves a hole in a
sequence whose whole value is that it has none.

## Note

This interacts with `0027`, which is reading the same architecture for
conformance. If that bundle's decisions change how sessions declare what they
own, this idea should be re-read against them before anything is built.
