# Final summary — `run-index-design-20260901-000000`

**Closed:** 2026-09-13, at the owner's direction
**Owned:** 11 bundles, 10 members. **Eight terminal** — six `answered`, `0009` and `0026` `superseded`. **Three released** to `unclaimed`: `0014`, `0021`, `0034`, each with its single member still `un-started`
**Revisions:** 116–134, 141, 192, 193, 197
**Stints:** 2026-09-01 to 2026-09-02, then 2026-09-04. It stood `handoff` between and after, and never satisfied it.

The session was given one question in two halves, two days apart. The first half
was **what an evidence run is**; the second was **which run is the true one**.

## The answer, if only one thing is carried forward

**Officialness is computed, not stored.**

A category keeps an append-only `MANIFEST.md`, a directory of runs, and one
`official/<context>.txt` pointer per lineage that is *derived* — a default rule by
point, then pins on top. Nothing writes "this is the official one" as a fact. That
single decision is what made every later correction cheap: when the default rule
itself turned out to be wrong for four points, changing it was a one-line edit to
a list of point names, and the tree re-derived.

The rule it changed to, at Revision 193:

| | Points | Why |
|---|---|---|
| **first-wins** | `before` `entry` `initial` `pre-restart` | A later run at one of these is a bookend recorded after its phase. The first capture is the only one taken while the state it describes was still true |
| **latest-wins** | `after` `exit` `post-restart` `final` `result` | The state keeps moving; the last reading is the current one |
| **no rule** | `diff` `delta` | Both captures were settled before either ran. The only failure mode is a missing pair |

**The exception is a pin, and a pin is a row.** Four lineages needed one, because a
later run was the honest one for reasons outside the rule — a recorder that
misreported, a check whose FAIL was the expected state, skipped prerequisites, a
mounted DMG. All four were written on 2026-09-04.

## Disposal, bundle by bundle

| | | |
|---|---|---|
| `0003` | `answered`, 1 member | The boundary-recorder family was applied unevenly; Revisions 136–137 evened it |
| `0005` | `answered`, 1 member | Four boundary runs dated the day the recorder was extended. **No re-run** — it would widen the gap. The point rules above are this bundle's real output, and the four pins are its evidence |
| `0009` | `superseded`, 1 member | Superseded by `0030`, which merged its reading with a repair rule it did not have. Left unedited, as §9 requires |
| `0012` | `answered`, 1 member | `.internal/restore/` is empty **and was never tracked** — git cannot track an empty directory, so the finding's own premise was wrong and was corrected while it was still open. Its original plan proposed a `.gitkeep`, which would have created the tracked directory it complained about |
| `0018` | `answered`, 1 member | Recorder usage strings understated the runbooks they support |
| `0022` | `answered`, 1 member | `restore-repos` was missing exit-recorder steps |
| `0023` | `answered`, 1 member | `restore-repos` rsync targeted a pre-image path |
| `0026` | `superseded`, 0 members | `verify-doc-paths.sh` counted gitignored docs |
| `0014` | `unclaimed`, 1 open | **Released.** The comparison lineage has no producer, and `comparisons/official/restore-runtime-version-comparison.txt` still points at the orphan. A `rename` row now exists in that category, so the former name is recoverable from the index rather than only from a broken citation |
| `0021` | `unclaimed`, 1 open | **Released.** Same shape as `0005` — a boundary run dated well after the state it records. `0005` is `answered`; its decisions are where to start |
| `0034` | `unclaimed`, 1 open | **Released.** Recorded 2026-09-04 and deliberately left unowned, because `restore-git.md` is the owner's active work. A retrofit since then put a row in this manifest, and ownership derives from the row — so it was owned without anyone deciding to own it. Its index row already named no session, so the release ends a projection disagreement rather than starting one |

## What this session got wrong

**`0030` D7's closing claim was false, and this session did not notice.** D7
asserted that every member of `0030` then carried a decision — the condition the
`resolving` gate turns on — and one did not, as D7's own text said two paragraphs
earlier. `pre-image-capture-conformance-20260903-194532` caught it, added D8, and
held its toolkit write in its composing copy until the gate closed honestly. The
gate is only worth having if the session standing at it reads its own bundle
rather than its own summary.

**A hazard was described as silent and was not.** The draft of
`outstanding-20260904.md` said an unpinned rebuild would flip four pointers and
report nothing. Running it — on a stripped copy, both directions — showed
Revision 193's own reporting firing on each of the four and naming the call that
settles it. **A loud report nobody reads is a different defect from a missing
check**, and the file was corrected before it was applied. The same measurement
showed the blast radius was exactly four: every other multi-run lineage in
`bookends/` sits at a latest-wins point.

**An early reading of `restore-git-entry` was backwards.** Its FAILs were read as
the honest entry state; the owner showed that Step 0a gated on values Step 0c
writes, so the FAIL was the expected state and the *later* run was the true one.
That correction is `0034`, which this session recorded against itself and has now
released.

**Its own D2 was reversed.** The first reading rejected making `entry` first-wins
as "superficially attractive and wrong in both directions". The owner reversed it
and the rule above is the result. The reversal is recorded inside D2 rather than
edited away, because a decision without its rejected alternative is what these
files exist to prevent.

**A zero-byte file was written into the artifact root.** Testing whether the
volume was writable by touching a path inside it, rather than against scratch, on
a root the session had been told was read-only by default. It was removed under a
deletion grant the same day.

## What it leaves

A ninth item nobody owns: **four `resolved` bundles carry per-member rows that
still read `in progress`** — `0030`, `0031`, `0032`, `0035`, all closed and owned
elsewhere. The rule is stated in both the instruction set and `docs/legend.md`;
the validator written for exactly this class of defect passes all four, because
its invariants are column count and tag-versus-row, and per-member coherence is a
third nobody wrote. Recorded here rather than opened as a bundle, because every
bundle it concerns is closed.

**The Bash 3.2 debt is not "not yet" — it is unreachable from here.** Both
ownership periods ran on Linux with Bash 5.x. The shell this session reaches
through the desktop bridge is a Linux VM, not the Mac host, so `/bin/bash -n`
under stock 3.2 cannot be run from this side at all. It is owed for everything
this session wrote and only the owner can discharge it.
