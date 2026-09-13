# Final summary — `instruments-and-blind-spots-20260909-220203`

**Closed:** 2026-09-13, Revision 320, at the owner's direction
**Owner stint:** Claude · `session_01Fo6sBeux1JTyDzgKhCx2KU`, 2026-09-10 to 2026-09-13
**Owned at close:** nothing. Both dossiers were released at Revision 317.

---

## What it was given

Two bundles, assigned at the owner's direction at Revision 286, both standing
`unclaimed` since Revision 264:

| | Subject |
|---|---|
| `0041` | The index and manifest tables have a shape nothing checks |
| `0050` | Three instruments are correct and cannot fire, and one unmakes the record |

**Nineteen members between them. Six were answered.** The prompt asked for three
things: a working check for `0041` D6, a decision on `extract-metadata.py`, and a
written answer to which instruments can fire. All three were delivered — at
Revisions 288, 289/299 and 297.

## Disposal

**Both released to `unclaimed` on 2026-09-13, no successor named**, on the
owner's instruction that a bundle a session has not answered goes back to the
queue rather than waiting on a session that has stopped advancing it. §10a's four
steps were carried out at Revision 317 and the full disposal record — what each
bundle is, what stands open, and what a taker should know — is in
[`findings-manifest.md`](findings-manifest.md).

| Bundle | Standing at release | Open members |
|---|---|---:|
| `0041` | `analyzing` | **6** — F2–F5 `decided` with remedies unbuilt, F8–F9 `framing` |
| `0050` | `analyzing` | **8** — all `framing`, all measured, none blocked on measurement |

**Neither reached `answered`, and neither was abandoned mid-measurement.** Every
open member carries its measurement; what they wait on is a decision.

**`0041` supersedes `0032`**, which `pre-image-capture-conformance-20260903-194532`
retains. The lineage is unaffected by the release.

## What it built

| Revision | |
|---:|---|
| 288 | **`0041` D6** — the prose total beneath a table is summed from the rows it describes. Its first run raised one the tree had carried for three revisions: `113` against `120` summed |
| 299 | **`0050` D3** — `extract-metadata.py` deleted rather than guarded, on a re-measurement of **740 values destroyed and 620 irrecoverable**; `check-metadata-completeness.py` split out |
| 306 | **The derivation fixture set** — an enumeration over all **63** presence-combinations rather than chosen bundles, which answered `0043` F7 on the way |
| 308 | **`0041` D7** — `structure` gains the two projection assertions, 105 rows of §6.1 where it compared 56. And **`0050` D4**, removing a fourth copy of the standing derivation |
| 309 | **`docs/ledgers/iris-conformance.md`** landed, nine revisions after it was composed and cited as existing by two documents |
| 312 | **`0041` D8** — F7 answered by adoption, after the owner's test showed the bundle could not otherwise terminate |

Three ledgers were produced: `instrument-firing.md`, `projection-conformance.md`
and `iris-conformance.md`.

## What it got wrong, and where the correction is

**Recorded because a summary that lists only what worked is not a record.**

| | |
|---|---|
| **`0041` F7's disposal** | Settled at Revision 304 as staying `framing`, agreed by two sessions, and **wrong** — it left the bundle unable to reach any terminal standing. Reversed by D8 at Revision 312 on the owner's test. The Revision 304 paragraph is left standing in `findings.md` because the reasoning is the finding |
| **`0049` F6 filed UNCLEARABLE** | Verdict right, stated reason wrong. The ledger said *moving a member is the owner's act and there is no owner*; the member had moved at Revision 258 and the real bar was that `unclaimed` is closed to everyone. Corrected at Revision 317 under owner authorisation |
| **Two manifest gaps called permanent** | Reported to the owner as undetected and permanent at Revision 292; **both halves were wrong**. Recorded as `0050` F8 and F9 rather than quietly fixed |
| **A resolution field written under the wrong key** | `what` instead of `whatWasDone`, twice, at Revisions 308 and 312. **Every instrument passed.** Found at Revision 313 and left unfixed: `docs/ideas/big-picture.md` is re-architecting the resolution object, and the owner's rule is not to do work the re-architecture repeats |
| **Four failed sweeps before a correct measurement** | 18 → 13 → 6 → 5 raised, and **every error ran in the direction of making the tree look worse**. Recorded in `projection-conformance.md` because it bears on the number |

## Revision 289 has no commit

**Its manifest entry exists and its content landed inside `15069fe`**, whose
`Claude-Session` trailer names `session_01H9nWPECCmRoZDipJSYA2iS`. So this
session wrote thirteen revision entries and twelve commits carry its trailer.

**That is `0050` F7 recorded against this session's own work** — nothing compares
a commit message's assertion against what the commit contains — and it is why the
`ended` block lists revisions and commits as two different lengths rather than
reconciling them.

## What is still owed, and by whom

**Nothing by this session.** Both dossiers are in the queue with their state
recorded; the three ledgers are landed; `0057` was recorded at Revision 309 and
was never owned here.

**By whoever takes `0050`:** F8, F9 and F10 are one cluster and should be decided
together — an instrument that is correct and reached by nothing, no rule for who
owes a missing entry, and a metric that moves against its own repair.

**By whoever takes `0041`:** F5 is the one with a concrete next step and it is
blocked — nothing compares a resolution's claim against the tree, and the
resolution object is being re-architected.

**Re-run, do not quote forward.** Every figure in both bundles names the commit it
was taken at. This session recorded three separate cases of a figure that had
moved under a document still asserting it.
