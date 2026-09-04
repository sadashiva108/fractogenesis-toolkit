# Resolutions — four bookend runs are dated the day the recorder was extended

**Bundle:** `0005-boundary-runs-recorded-long-after-their-phase` · **Status:** `resolved`
**Resolved:** 2026-09-04, session `session_01KcZvrKMgfenhrT9DvxW9Jk`.

| Finding | Resolved by | Commit |
|---|---|---|
| Four bookend runs are dated the day the recorder was extended, not the day the phase ran | `APPLY-MANIFEST.md` Revision 193 — D2's point-rule correction, D3's rebuild flagging, D4's standing rule, D5's `--note` | pending; the owner commits |

## What was done

**`entry` and `initial` became first-wins.** That is the substance of the
resolution and the owner's ruling. `ARTIFACT_RUNS_FIRST_WINS_POINTS` is now
`before entry initial pre-restart`; `exit`, `after` and `post-restart` stay
latest-wins; `diff` and `delta` are documented as having no rule, because both
captures they join were settled before either ran and their failure mode is a
missing pair rather than a wrong pointer. `initial` was not in
`ARTIFACT_RUNS_KNOWN_POINTS` at all, so it fell to latest-wins by default rather
than by decision — it is added.

This is what closes the finding. A bookend recorded after its phase now refuses
to advance its pointer and says so in the manifest, which is the guard the
original reading said did not exist.

**A later run at a first-wins point is flagged, never rejected.**
`artifact_run_finalize` already wrote `first-wins point: pointer left at <run>`
into the `Note` column and already composed it with an operator note; what
changed is which points reach it. New: `artifact_runs_rebuild` reports, per
lineage, when the official run is not the newest, and names
`artifact_run_set_official` as the way to decide it. A rebuild was previously
silent about this — the pointer simply moved — and that matters most for runs
recorded before the rule existed, which carry no flag of their own.

**The hazard is written where the machinery is read.**
`.internal/artifact-runs.sh`'s header gains it beside the naming rule: a run's
timestamp says when the recorder ran, never when the phase did; `restarts/` is
the honest clock for Phases 8 and 9 because those lineages were written live. It
states the limit plainly — the rule does not *detect* lateness, because nothing
on the machine knows when a phase ran. It declines to let a late run become
official.

**`--note TEXT` now reaches the manifest.** The library already carried it; only
`record-enrollment.sh` and `record-reimaged-system.sh` failed to expose it. Five
`artifact_run_finalize` call sites pass `$RUN_NOTE`, empty by default, which the
library renders as an em dash.

Exercised end to end against a scratch category rather than assumed — two `entry`
runs a second apart, the second recorded and flagged, the pointer left on the
first, the rebuild naming it:

```text
| … | run | `restore-x-entry` | entry | `restore-x-entry-…-191727` | 2 pass / 0 warn / 0 fail | first-wins point: pointer left at `restore-x-entry-…-191726` |

artifact-runs: 'restore-x-entry': official is …-191726; …-191727 is newer and not official
```

## Five pointers move, and one is owed a pin

D2 is retroactive, because officialness is computed. On the next
`artifact_runs_rebuild` four `entry` lineages and one `initial` lineage take
their earliest run:

| Lineage | Official now | Becomes |
|---|---|---|
| `restore-repos-entry` | `20260902-160157` | `20260825-033849` — 5 pass / 2 warn / **1 fail** |
| `restore-git-entry` | `20260901-083539` | `20260824-174717` — 3 pass / 1 warn / **2 fail** |
| `restore-access-entry` | `20260824-063529` | `20260820-011553` — WARN, `node`/`npm` missing |
| `restore-apps-entry` | `20260825-065638` | `20260825-042828` — WARN, secrets DMG still attached |
| `enroll-and-stabilize-initial` | `20260818-063116` | `20260818-051819` |

**All four `entry` lineages regress to a run recording something other than the
machine's entry state**, and all four are pinned back on the owner's instruction:
`restore-repos-entry` (damaged `repos.tsv`), `restore-git-entry` (Step 0c had not
run yet), `restore-access-entry` (dev-environment steps skipped — `node`/`npm`
missing at 08-20, present at 08-24) and `restore-apps-entry` (the secrets DMG was
still attached at 04:28 and correctly detached at 06:56).

Four out of four, and the same cause each time: the operator's own setup, noticed
and fixed, and the phase re-entered. D6 records that as an argument against D2 as
much as for it — re-entering after fixing your own setup is the normal path, not
an edge case, and D2 makes each occurrence a pin. It is still right, because
latest-wins was not answering the question either: it moved the pointer silently,
so a genuinely late `entry` looked exactly like a legitimate re-entry.

**`enroll-and-stabilize-initial` is the one flip left to stand, and it vindicates
the rule.** Its earlier run carries `First stabilization restart completed` =
**TODO**; the later one carries `yes` — so the later run records a machine that
had already restarted, under a point named `initial`, when
`enroll-and-stabilize-post-restart-20260819-000715` is where that belongs.
First-wins moves the pointer to the honest first-boot record.

That pair also closes this bundle's own loop. `initial` is the default context,
reachable only by omitting `--context`, which the current runbook never does —
Step 7 passes `pre-restart`, Step 9 passes `post-restart`. Both runs are from
2026-08-18, before the entry and exit bookends existed. The bookends for this
phase were backfilled on 08-31, which is the finding; the `initial` pair is what
the phase recorded while there was nothing else to record into.

`enroll-and-stabilize-entry` has one run and is untouched.

That second one corrected this session. D6 first read the 08-24 FAILs as the
honest entry state. They are not: both rows gated on `$GIT_WORK_SSH_KEY` and
`$GIT_PERSONAL_SSH_KEY`, which `restore-git.md` **Step 0c** sets — so Step 0a
could never pass on a first traversal, and the recorder exits non-zero on FAIL.
Both rows were removed from `check_restore_git()` by `bb7e2d5` for exactly that
reason. Recorded as
[`0034`](../../runbook-findings/restore-git/0034-step-0a-names-two-rows-the-recorder-no-longer-emits/),
unowned, because `restore-git.md` Step 0a still tells the reader to read one of
the removed rows twice.

**All four pins are evidence writes and none is made here.** They need the
owner's word for `reimaged-system/bookends/`, and until taken all four pointers
regress on the next rebuild. Stated rather than mitigated: mitigating it would
mean pinning without permission.

None of these lineages carries a pin today and none needs one: `entry` is
latest-wins in the tree as it stands, so the later run is official by the ordinary
rule. The pins exist only because this change makes it first-wins, and they are
part of the same act.

## What was deliberately not done

**Nothing was re-run and no volume file was touched.** That is D1 and it is the
substance of the finding rather than an omission: a re-run replaces an 08-31
stamp with an 09-04 one and widens the gap, and under D2 an `entry` re-run would
not become official anyway.

**The four existing bookend runs are not annotated.** The manifest is append-only
and their rows stand. `--note` prevents recurrence; it does not reach backwards.
This bundle is their annotation, and the header paragraph points a reader at it.

## Verification

`bash -n` clean on all four edited scripts. Baselines held: findings counts
0 FAIL, doc paths 0 MISSING / 0 ANCHOR BROKEN, runbook structure 213 PASS /
5 WARN / 25 FAIL across 27 documents, script portability 0 WARN / 0 FAIL.

**Linux, Bash 5.x.** The point-rule change is two space-delimited strings and a
`for` loop over them, and the rebuild reporting uses `cat`, `tail -1` and
parameter expansion — all stock 3.2, none of it run there. `/bin/bash -n` under
macOS Bash 3.2 is owed, as on every revision this session has carried.
