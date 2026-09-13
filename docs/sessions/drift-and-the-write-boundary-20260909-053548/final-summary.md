# Final summary — `drift-and-the-write-boundary-20260909-053548`

**Closed:** 2026-09-13, latched at Revision 313 under the owner’s override  
**Owned:** 3 bundles, 28 members. **All three terminal.** `0055` recorded and left `unclaimed`  
**Revisions:** 270, 268, 272, 276, 277, 278, 280, 281, 282, 283, 295, 298, 300, 302, 305, 311, 313

The session was given three bundles that turned out to be one question: **`0038`,
sessions write into the tree the owner commits from; `0047`, the tree carries
drift no check looks for; `0052`, a change that invalidates earlier work has
neither a plan nor a check.** Everything below is that question in a different
costume.

## The answer, if only one thing is carried forward

**`0038` D9: declare the scope of a change; do not derive it from a tree state.**

It recurred in five disguises in four days, and each one looked like a different
bug until the fifth:

- A patch composed from a dirty checkout carried **five files of another
  session's uncommitted work**. `git diff` computes *what I changed* from *what
  differs from HEAD*, which is only true if nothing else is there.
- A revision number was taken between composing and applying, **twice** — 290 to
  a race, 291 to a commit message that named it while carrying someone else's
  work.
- A findings total was hand-incremented **three times** while the column beneath
  it moved by seven more, each write locally correct.
- A commit message described three changes **none of which were in its commit**,
  and `git apply` exited 0.
- `§0` step 3's own recipe dropped a deletion, because `git add -N` stages the
  removal and bare `git diff` then reads the working tree against the index.

**None of these is a git defect.** In each, something computed the extent of a
change by differencing two states instead of being told what the change was.

## Disposal, bundle by bundle

| | | |
|---|---|---|
| `0038` | `answered`, 12 members | §0 steps 1–3 rewritten: the checkout's dirt is recorded at copy time, the patch's file list is compared against it, and the recipe is `git diff HEAD`. **Requiring a clean copy was rejected** — serialising sessions is the cost `0038` exists to avoid |
| `0047` | `answered`, 13 members | Every ordering comparison the bundle inventoried was either repaired, exempted with a counted reason, or shown to be the rule working. **Not one row was cleared by editing a record.** F13 is the one worth re-reading: closing a bundle has no single act |
| `0052` | `answered`, 3 members | §6's migration-plan gate, the re-verification instrument that already existed, and F3 — a rollover is a format change whose casualty is a **reader**, not a record, so the gate does not fire |
| `0055` | `unclaimed`, 2 members | The manifest measured and no remedy proposed. Revision 310 rolled it over, which is F1's answer arriving from the owner rather than from this bundle |

## What this session got wrong

Recorded because a summary listing only what worked is not a summary.

- **It nearly shipped another session's work**, and caught it by reading the
  patch's file list rather than by any instrument. The same defect then made it
  refuse to write into a dirty checkout — same cause, opposite directions.
- **It rewrote a `metadata.json` with `ensure_ascii=False`** and converted every
  em dash in the file. That is Revision 289's own defect, committed inside the
  session that had just recorded it.
- **It drifted two projection rows** — `0038` and `0047`'s standings in this
  session's own manifest, inverted — and the owner found them by eye.
- **`0038` D11's rationale conflates two abilities.** Revision 312 showed that
  *cannot write §0 or §6* is not *cannot decide*, and deciding is the one thing
  an owner may always do. The decision stands; the sentence is amended in place.
- **It proposed a check that fails on its own commit** — *every bundle named in a
  commit message must be touched by it* — and withdrew it after running it
  against the commit that proposed it.

**The pattern in the errors is the same as the pattern in the findings**: each was
found by reading a thing against its source, and none by an instrument.

## What it hands on

- **A decision whose remedy is not a write leaves no trace of its own
  completion.** `0012` D2 was accepted and went uncarried-out for 115 revisions
  because the only tree in which it mattered was one person's. Named in `0038`
  D11, opened by nobody.
- **`0055`**, `unclaimed`, for whoever takes §7 and the manifest.
- **The vocabulary settled with the owner on 2026-09-13**: a **disposition** is
  the class of `status`, `standing` and `state`; a **transition** is a change in
  one; a **crossing** is a transition a derivation produced and a **declaration**
  one an actor performed. **A crossing is silent and must be detected; a
  declaration announces itself and carries its obligations inline.** This session
  closed by crossing, which is why its own record was incomplete.
- **`docs/ideas/big-picture.md` § Detection and Verification**, whose claim is
  that IRIS verifies documents and has never verified an event.

## The measurement worth keeping

**Five projections disagreed with their source across 613 rows and not one was
found by an instrument** — two by the owner reading rows by eye, two by sessions
rechecking their own work, one by a session reading its own table back after
being questioned. **`check` went 52 conformance rows to 26 across this session's
revisions, and not one of those was cleared by editing a record.** Every one was
an instrument reporting something untrue, or reporting something nobody was
permitted to act on.
