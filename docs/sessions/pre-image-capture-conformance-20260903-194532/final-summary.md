# Final summary — `pre-image-capture-conformance-20260903-194532`

**Closed 2026-09-13** at the owner's direction. Assistant Claude,
`session_01PcgHu9kz9Hm5RatLQuFR8H`, owned from 2026-09-03.

Assigned four pre-image runbook findings from `run-index-design-20260901-000000`
and told to read them and decide nothing. It answered those four, recorded four
more bundles of its own, and closes holding six — four answered, two superseded.
**Two were released rather than carried**, and that is the part of this record
that matters most, because a released bundle leaves no other trace.

## What it contributed

| Revision | Commit | What |
|---:|---|---|
| 178 | `7b8695c` | The session bundle itself; four findings reassigned from `run-index-design` |
| 183 | `cf251ab` | `0009` superseded by `0030`; a reference inside a dated record may be repaired where the target still exists and the timestamp is retained |
| 185 | `132432b` | `0025` answered — both unreachable staged directories opened on the volume |
| 187 | `5197268` | `0013` answered — `Evidence` and `Assessment` defined in the runbook glossary |
| 191 | `f4159da` | Finding 7 contributed to `0033`: five of six token fallbacks in `indigo` had drifted from the contract |
| 184 | `6a53bf5` | The procedure for superseding a bundle whose session is gone, written into what was then §4c |
| 194 | `92a4f79` | `artifact_run_record_rename`; `0030` and `0032` declared closed, `0035` recorded |
| 195 | `92a4f79` | `bin/verify-findings-structure.sh` |
| 196 | `3604743` | `artifact_run_rename_lineage`; `0035` declared closed |

Nine revisions across eight commits, every one carrying this session's
`Claude-Session` trailer and no commit carrying it that is not listed here.
Revisions 194 and 195 shipped in one commit. The bundle behind Revision 184,
`0031`, is now superseded by `0040`.

## Disposal of every bundle it held

| # | Disposition | Date | Standing at disposal |
|---|---|---|---|
| 0007 | answered, retained | 2026-09-03 | `answered` |
| 0013 | answered, retained | 2026-09-03 | `answered` |
| 0019 | answered, retained | 2026-09-03 | `answered` |
| 0025 | answered, retained | 2026-09-03 | `answered` |
| 0031 | superseded by `0040`, retained | — | `superseded` |
| 0032 | superseded by `0041`, retained | — | `superseded` |
| **0030** | **released to `unclaimed`** | **2026-09-13** | `analyzing`, 5 members open |
| **0035** | **released to `unclaimed`** | **2026-09-13** | `assigned`, 3 members open |

### Why `0030` and `0035` were released rather than held

Both were declared closed by this session on 2026-09-04 and **neither was
terminal**. Their per-finding tables were never moved: `0030`'s five members and
`0035`'s three still read `framing`, so the derived standing is `analyzing` and
`assigned` rather than `answered`.

That is this session's defect, found by `run-index-design-20260901-000000` on
2026-09-04 and recorded in its `outstanding-20260904.md` §4.1. `docs/legend.md`
states the rule — *a bundle advances when its first finding advances and reaches
its terminal standing only when its last one does* — and four bundles of this
session's were closed against it, two of them the very bundles about invariants
nothing enforces. `bin/verify-findings-structure.sh`, written by this session for
that class of defect, passes on all four and correctly so: per-member coherence is
a third invariant it does not check.

No successor is named. The work each holds is real and neither is abandoned:

- **`0030`** — its eight decisions stand and its toolkit write shipped. What is
  unfinished is the record, not the reasoning. Three retroactive `rename` rows
  remain owed as evidence writes, one per category, and D5's citation repair is
  queued and unperformed — `run-index` has since re-censused it and found **eight**
  volume-side citations rather than the one D5 named.
- **`0035`** — `artifact_run_rename_lineage` shipped and was exercised end to end.
  No rename has been performed with it.

## What it leaves owed elsewhere

- **Four bundles closed over open members** — `0030`, `0031`, `0032`, `0035`.
  `0031` and `0032` are superseded and frozen; the two released carry it forward.
  A third invariant for `verify-findings-structure.sh` would catch the class and
  has no bundle.
- **The §4c numbering command** globbed two findings trees when there were three.
  Relayed to no one; held at the owner's word pending `0029`. The correction is
  one line, and the collision it would have caused was avoided only because this
  session used a different command.
- **Table 3's banner** in `docs/ledgers/evidence-conformance.md` still reads *"No
  artifact was migrated"*, untrue since Revision 138. `0013`'s decisions routed it
  to a bundle nobody has opened.

## What the release itself turned up

**§10a's four steps do not complete a release.** Removing the manifest row, setting
the index row and decrementing the session counts leaves the bundle's own
`ownership` at `null`, so `stamp` goes on deriving `analyzing` and `assigned` from
the members and `structure` raises both rows as disagreeing with their data. §10a
says *there is no step for setting the status ... removing the row IS the release
and `unclaimed` follows from it*, and it does not: `ownership` is authored, not
derived. It and `ownershipOn`, added at Revision 317, were set by hand here, as
they were on the two bundles released at that revision. The instruction is one
step short of the practice every release has actually followed.

**The eleven standing `headers` failures in this tree are all inside `0030` and
`0035`** — eight and three, every decision row citing no finding. They are
pre-existing at HEAD and were not caused by the release, but they leave with the
bundles, and `verify-session-findings.sh` still describes that baseline as *"six
bundles owned by other sessions"*, which it is not and cannot be while both are
`unclaimed`.

**The release lowered the conformance count by suppressing three true positives.**
`plan-findings-work.sh check` reads 26 before and 23 after, and nothing was
repaired. `0035` F1, F2 and F3 each carry a resolution over an `un-started`
member — the defect Revision 315 named in this tree and deliberately left
visible *because their owner may clear them* — and the moment the bundle became
`unclaimed` all three moved into the bucket for rows nobody may clear. `0030`'s
five moved likewise, out of the clone-being-re-read bucket and into the same one.
**Unclearable rows are not reported, so releasing a bundle makes its defects
cheaper to look at and no easier to fix.** That is `0047` F1 and F2 operating as
designed; it is recorded here because the arithmetic looks like progress and is
not.

**And the release itself nearly repeated Revision 313's defect.** Rewriting the two
bundle records with `json.dump(..., ensure_ascii=False)` converted **21 `\u2014`
escapes to literal em dashes** across `0030` and `0035` — three lines of real
change hidden inside a 56-line diff. Caught by comparing escape counts against
`HEAD`, which is how `entity-model-and-vocabulary-20260909-053548` caught the same
thing in itself at Revision 316, in the session that had just read the record of
it. Both files were restored and edited as text; the three lines that changed are
`standing`, `ownership` and the new `ownershipOn`.

## Validation and environment

Every revision it wrote held the baselines of its day: doc paths 0 MISSING /
0 ANCHOR BROKEN, runbook structure 213 PASS / 5 WARN / 25 FAIL across 27
documents, script portability 0 WARN / 0 FAIL, and — once they existed — findings
counts and findings structure 0 FAIL.

Everything ran on Linux with Bash 5.1 in a VM on the owner's machine. **`/bin/bash -n`
against macOS stock Bash 3.2 was never run**, and is owed for every revision this
session wrote, as it is from Revision 116 onward. Two functions it added to
`.internal/artifact-runs.sh` use no construct newer than 3.2 by inspection and the
portability lint agrees, which is not the same claim.

One evidence write was made, on the owner's word for that specific run: two lines
of `office-stability/runs/pre-image-office-stability-assessment-20260817-175050/README.md`,
Revision 183. Nothing else on the artifact volume was touched.
