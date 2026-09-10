# Resolutions — sessions write into the tree the owner commits from

**Bundle:** `0038-sessions-write-into-the-tree-the-owner-commits-from`  
**Session:** `drift-and-the-write-boundary-20260909-053548`  
**Resolved:** 2026-09-09

**Five of these six were carried out before this bundle was read**, in revisions
that answered `0028` rather than `0038`. The `Revision` column names the revision
that did the work and not the one that noticed, which is what the column is for
and what `0047` D4 established. Only F1 and F4 are carried out here.

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F1 | D1 | §0 gains the rebase step — compare the base at step 6, rebase in a fresh scratch copy with `git apply -3`, resolve every conflict to the checkout's content and re-make this session's edits on top, recompute counts from the data, re-take the revision number and re-measure. And `git --no-optional-locks` for every git read of the checkout, which is what lets step 6's cleanliness assertion coexist with the rule against git in the checkout | 270 | — |
| F2 | D2 | Nothing here. §0 step 2 requires every verification in the scratch tree, and `docs/rules/README.md` §6 carries `0026`'s option (iii) as a standing rule — quote `MISSING`, `FAIL`, `WARN`, never `OK` | 232 | `d0e6d7d` |
| F3 | D3 | Nothing here. §0 steps 3 and 4 make the patch the unit and the review the deliverable; `bin/review-changes.sh` produces it | 232 | `d0e6d7d` |
| F4 | D4 | §0 step 5 now states the asymmetry it always relied on: declining a patch is free because nothing is in the checkout to reverse, and reverting after an apply is a hand edit per file | 270 | — |
| F5 | D5 | Nothing here. §7 takes the number at apply time against the tree being applied to and never retro-edits an entry. **The helper `0028` named as `bin/check-manifest-revision.sh` is `.share/check-manifest-revision.sh`**, invoked as `./bin/verify-session-findings.sh manifest-revision`; the citation is corrected here and the tool is not moved back | 181 | `87ff205` |
| F6 | D6 | Nothing here. §6 carries four write kinds — `record`, `toolkit`, `evidence`, `foreign` — with gating per kind and composition stated once for all three tracked kinds. **The `docs/legend.md` section `0028` created for this no longer exists**; `0039` D2 and D13 moved the rule to the instruction set and widened it, and nothing connected the move to the resolution that pointed at it | 226 | `55e753e` |
| F7 | D8 | Nothing built. `docs/rules/rule-enforcement-avenues.md` §3 gains test 3.0 and §4 re-scores all four candidates against it; the answer F7 asked for is that the enforcement dividend cannot be drawn at this layer, and the avenue available is the checker | 283 | — |
| F8 | D8 | §4.1 carries its route — the committing is the owner's and reaches no hook, and a `Stop` hook would have to know which tree. Built as a checker at Revision 278 instead | 283 | — |
| F9 | D8 | §3.0's third route, with Revision 282's measurement; and the installed set is corrected in §4 to one guard and two annotators | 283 | — |

**All nine members are `resolved` and the bundle derives `answered`.** Six were
carried out before this bundle was read, in revisions that answered `0028`; F1
and F4 at Revision 270; F7, F8 and F9 at Revision 283.

**F7 stood `decided` from Revision 270 to Revision 283**, deliberately. D7 chose
which of the four guards to build first and under what discipline; **building it
is what found that the choice was not a guard at all**, and D8 is that reading
turned into a test. A finding held open between a decision and its carrying-out
is the state §9b describes, and this is what it looks like when the carrying-out
changes the answer.

**Nothing was built for F7, F8 or F9 and the resolution rows say so.** What was
written is a test and a re-scoring — `docs/rules/rule-enforcement-avenues.md` §3.0
and §4 — because **the rules are worth holding and this layer cannot hold them**,
and the record now carries the second sentence as well as the first.

## What re-verification found, and it is the reason this file reads as it does

`0028` decided and resolved all six of these at Revision 181. Re-reading each
against the tree at Revision 269:

| | `0028` said the remedy was | At Revision 269 |
|---|---|---|
| `0028` F1 | the composition rule in `.github/copilot-instructions.md` §3 | **that file and that section no longer exist** — `1c48deb` split it. The rule was re-installed as §0 at Revision 232 |
| `0028` F2 | validators run in the copy | holds, in §0 step 2 |
| `0028` F3 | the patch is the unit | holds, in §0 steps 3–4 |
| `0028` F4 | declining a patch replaces reversal | **stated nowhere.** Structurally true for four revisions and never written down |
| `0028` F5 | `bin/check-manifest-revision.sh` | **that path does not exist.** The helper moved to `.share/` |
| `0028` F6 | a new section in `docs/legend.md` | **that section does not exist.** The rule moved to §6 and got wider |

**Two of six hold as written. Three name a home that is gone. One was never
stated at all.** No remedy was lost — every rule is alive somewhere, and two are
better than they were. What decayed is the record's ability to say so.

**This is `0052` F1 measured rather than argued**, on the one bundle where it
could be measured cheaply, and it is recorded in `0052` F1 as well as here. It
also answers the question that finding says it exists to produce a number for:
**a resolution's failure mode here is not being reverted — it is naming a place.**
Five of these six cite a file, a section or a path, and three of the five decayed
in four months while every rule they installed survived.

## Validation

Run in the session copy against this change alone, then re-run after the rebase
onto Revision 269.

| Check | Result | Against baseline |
|---|---|---|
| `plan-findings-work.sh check` | 43 | unchanged — this revision moves no conformance row |
| `plan-findings-work.sh stamp --dry-run` | writes nothing | derived fields agree |
| `verify-session-findings.sh counts` | ok | — |
| `verify-session-findings.sh headers` | 11 FAIL | unchanged, all in `0030` and `0035` |
| `verify-session-findings.sh structure` | ok | — |
| `check-completeness.sh` | ok | — |
| `verify-doc-paths.sh` | 0 MISSING / 0 ANCHOR BROKEN | unchanged |
| `verify-runbook-structure.sh` | 213 PASS / 5 WARN / 25 FAIL | unchanged |
| `verify-script-portability.sh` | 0 FAIL | unchanged |
| `test-session-management.sh` | 54 tests, all pass | unchanged |

The environment was a Linux VM on the owner's Mac — Bash 5.1.16, Python 3.10.12,
Ubuntu 22.04 aarch64 — and **not** the macOS Bash 3.2 target.
`docs/ledgers/target-platform-verification.md` remains the only run that was.
