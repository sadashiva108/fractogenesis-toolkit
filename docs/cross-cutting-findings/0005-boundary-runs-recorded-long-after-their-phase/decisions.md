# Decisions — four bookend runs are dated the day the recorder was extended

**Bundle:** `0005-boundary-runs-recorded-long-after-their-phase` · **Status:** `in progress`
**Decided:** 2026-09-04, session `session_01KcZvrKMgfenhrT9DvxW9Jk`, which owns it.
**Point rules ruled on by the owner, 2026-09-04**, correcting this session's first
answer. See D2.

Re-verified against the volume before deciding. Both pairs still carry their
2026-08-31 and 2026-09-01 stamps against phases that ran 08-18/19. The category is
`bookends/` now, renamed by Revision 156; the runs and the dates are the same.

## D1 — Nothing is re-run, and nothing on the volume is repaired

A bookend recorded late is better than none, each run is honest about its own
generation time, and re-recording now would move the stamps *further* from the
phase.

**Rejected — re-run the four to get truthful ordering.** It cannot produce
truthful ordering. The timestamp records when the recorder ran, and no re-run
changes when the phase did; under D2 a re-run of `entry` would not even become
official.

**Rejected — edit the manifest rows to the phase dates.** The manifest is
append-only by its own header, and a date is a *value*, which `0030` D2 puts on
the wrong side of the only line that matters.

## D2 — `entry` and `initial` are first-wins

**This reverses the answer this session first gave.** The rejected alternative
below was written as *"make `entry` first-wins like `before`" — superficially
attractive and wrong in both directions*. The owner ruled otherwise on
2026-09-04, and the ruling is right; the reasoning that led here is recorded so
the reversal is legible rather than silent.

The test is **whether the point names a moment the phase has not yet passed.**
`before`, `entry`, `initial` and `pre-restart` all describe the machine as it
stood before something happened to it. That moment occurs once. A second run at
the same point is either the same unchanged state re-measured — because the
capture itself improved — or a machine the phase has already moved, recorded
under a name that says it has not.

`exit`, `after` and `post-restart` stay **latest-wins**, and for the opposite
reason: they ask *where did this end up*, which is a question about now, and
re-running one is how a stale answer is replaced.

`diff` and `delta` get **no rule at all**, which is a third category rather than
a weaker version of latest-wins. Both captures a diff joins were already settled
by the time it ran, so a later diff cannot contradict an earlier one. Their
failure mode is a **missing pair**, not a wrong pointer, and a point rule cannot
see that.

`initial` was not in `ARTIFACT_RUNS_KNOWN_POINTS` at all, so it resolved to
`unknown` and fell to latest-wins by default rather than by decision. It is added.

**Rejected — leave `entry` latest-wins and rely on `--note`.** This session's
first answer. It treats a rule that can refuse a wrong run as interchangeable
with a free-text field that asks an operator to describe one. The note is the
annotation; the rule is the guard.

**Rejected — make every point first-wins.** The symmetry is tempting and wrong.
`exit` and `after` name the end of a phase, and freezing the first one recorded
would make a corrected finish permanently unofficial — which is exactly what
`0021`, still open in this session, is about.

## D3 — A later run at a first-wins point is flagged for a person, never rejected

The refusal is not an error. The ordinary case is a capture improved while the
machine still sat at that point, and `restore-repos-entry` is a live instance:
its first run reported a FAIL that came from a defect in the script rather than
from the machine.

So the run records normally, the pointer does not move, and the manifest `Note`
column says so — `first-wins point: pointer left at <run>`, composed with any
operator note. That behaviour already existed in `artifact_run_finalize`; what
changes is which points reach it.

**What did not exist is a way to find these later**, and a rule applied
retroactively makes that urgent: the runs affected today were recorded before the
rule existed and so carry no flag in their own rows. `artifact_runs_rebuild` now
reports, per lineage, when the official run is not the newest, and names
`artifact_run_set_official` as the way to decide it. A rebuild was previously
silent about this — the pointer simply moved.

**Rejected — refuse the run outright.** It would discard the improved capture and
leave the operator with nothing to promote.

**Rejected — auto-promote when the later run has a better result.** `restore-git-entry`
shows why: its first run is 3 pass / 1 warn / **2 fail**, and that is very likely
the honest entry state — Phase 11A's prerequisites genuinely were not met when it
started. A rule that prefers the tidier number would erase exactly the evidence
the bookend exists to hold.

## D4 — The hazard is written where the machinery is read

`.internal/artifact-runs.sh`'s header gains it, beside the naming rule: a run's
timestamp says when the recorder ran, never when the phase did; `restarts/` is
the honest clock for Phases 8 and 9 because those lineages were written live; and
the first-wins points are what catch the late-`entry` case. It states the limit
plainly — the rule does not *detect* lateness, because nothing on the machine
knows when a phase ran. It declines to let a late run become official.

**Rejected — the ledger.** `docs/ledgers/` is re-derived and replaced wholesale
by its own convention, so a standing rule placed there has a scheduled expiry.

**Rejected — this bundle alone.** A resolved findings bundle is not where someone
reading `bookends/MANIFEST.md` will look.

## D5 — `--note` is added to both recorders

Cheap, because the library already carries it end to end:
`artifact_run_finalize <root> <result> <note>` writes the manifest `Note` column,
and it already composes an operator note with the first-wins flag. Only
`record-enrollment.sh` and `record-reimaged-system.sh` failed to expose it; five
`artifact_run_finalize` call sites gain the pass-through.

It does **not** annotate the four existing runs. The manifest is append-only and
their rows stand; this bundle is their annotation.

**Rejected — build nothing, since the event that motivated it has passed.**
The same shape recurs whenever a recorder gains a phase it did not previously
cover: `check_restore_home()` was added in Revision 137 for a phase with no runs
yet. The next one is owed, not hypothetical.

## D6 — Five pointers move, one is pinned back, four are the owner's to decide

Officialness is computed, so D2 takes effect against every existing lineage on
the next `artifact_runs_rebuild`. Measured 2026-09-04:

| Lineage | Official now | Becomes | Result of the new official |
|---|---|---|---|
| `restore-repos-entry` | `20260902-160157` | `20260825-033849` | 5 pass / 2 warn / **1 fail** |
| `restore-git-entry` | `20260901-083539` | `20260824-174717` | 3 pass / 1 warn / **2 fail** |
| `restore-access-entry` | `20260824-063529` | `20260820-011553` | 6 pass / **1 warn** / 0 fail |
| `restore-apps-entry` | `20260825-065638` | `20260825-042828` | 4 pass / **1 warn** / 0 fail |
| `enroll-and-stabilize-initial` | `20260818-063116` | `20260818-051819` | — |

**All four `entry` lineages are pinned back, on the owner's instruction**, each
because the earlier run records something other than the machine's entry state —
which is exactly what a pin is for.

| Lineage | Pinned to | Why the earlier run is not the entry state |
|---|---|---|
| `restore-repos-entry` | `restore-repos-entry-20260902-160157` | its FAIL came from the damaged `repos.tsv` the Phase 11B session later re-derived |
| `restore-git-entry` | `restore-git-entry-20260901-083539` | its two FAILs record that Step **0c** had not run yet — see below |
| `restore-access-entry` | `restore-access-entry-20260824-063529` | the operator had skipped dev-environment steps; the 08-20 run WARNs on missing `node` and `npm`, the 08-24 one carries `node v26.7.0 / npm 11.19.0` |
| `restore-apps-entry` | `restore-apps-entry-20260825-065638` | the secrets DMG was still attached; the 04:28 run WARNs `currently attached … it holds plaintext`, the 06:56 one reads `not attached, which is correct at phase entry` |

### Four out of four, and the same cause each time

Every one of these is the operator's own setup rather than the machine's state at
entry: a damaged capture, a step ordering, a skipped prerequisite, a volume left
mounted. In each case the operator noticed, fixed it, and re-entered the phase.

**That is worth naming rather than passing over, because it is an argument
against D2 as much as for it.** Re-entering a phase after fixing your own setup is
not an edge case — it is how the workflow is actually walked, four times out of
four — and D2 turns each occurrence into a pin, which is an evidence write needing
the owner per category. A rule that fires on the normal path is a rule with a
running cost.

It is still right, and the reason is that **latest-wins was not answering the
question either.** It simply moved the pointer to the newest run and said nothing,
so nobody had to decide whether the earlier run was the entry state — the four
runs above sat unexamined until first-wins made them visible. The cost of D2 is a
pin per re-entry; the cost of latest-wins was that a genuinely late `entry`, which
is what this bundle was opened about, looked exactly like a legitimate re-entry
and nothing distinguished them.

If the running cost proves too high, the answer is a lighter way to record
"re-entered after fixing setup" — not a return to a pointer that moved silently.

**This session had `restore-git-entry` wrong, and the owner caught it.** D6 first
read its 08-24 FAILs as *"plausibly the honest entry state for a phase whose
prerequisites were not yet met"*. They are not. Both rows gated on
`$GIT_WORK_SSH_KEY` and `$GIT_PERSONAL_SSH_KEY` being set in `reimage.env`, and
`restore-git.md` **Step 0c is what sets them** — so Step 0a could never pass on a
first traversal, and `record-restore-prereqs.sh` exits non-zero on FAIL, stopping
the phase over its own ordering. Both rows were removed from
`check_restore_git()` by commit `bb7e2d5` for that reason, and the current
recorder emits four rows, neither of them these.

So the 08-24 run records the runbook's ordering, not the machine's state, and the
distinction is the whole point of the pin. Recorded separately as
[`0034`](../../runbook-findings/restore-git/0034-step-0a-names-two-rows-the-recorder-no-longer-emits/),
because `restore-git.md` Step 0a still tells the reader to read one of the
removed rows twice.

**`enroll-and-stabilize-initial` is left to move, and it is the case that
vindicates the rule.** Its earlier run (`20260818-051819`) carries
`First stabilization restart completed` = **TODO** and a WARN on macOS updates;
the later one (`20260818-063116`) carries `yes` and PASS. So the later run
records a machine that has *already restarted* — which is what
`enroll-and-stabilize-post-restart` exists to hold, and that run exists at
`20260819-000715`. The earlier run is the honest `initial`: first boot, before the
restart. First-wins moves the pointer to it, which is an improvement rather than
a cost.

**Why an `initial` pair exists at all closes this bundle's own loop.** `initial`
is the default context — `RUN_CONTEXT="enroll-and-stabilize-${CONTEXT_LABEL:-initial}"`
— reachable only by omitting `--context`, which the current runbook never does:
Step 7 passes `pre-restart` and Step 9 passes `post-restart`. Those two runs are
from 2026-08-18, before the entry and exit bookends existed, which is the same
gap this bundle was opened about. The bookends for this phase were backfilled on
08-31; the `initial` pair is what the phase recorded while there was nothing else
to record into.

`enroll-and-stabilize-entry` has exactly one run, `20260831-144302`, so nothing
moves and nothing is decided for it. Its entry is taken at Step 3 rather than
Step 0 because Phase 8 begins on a Mac with no toolkit on it — Steps 2 and 3 are
what create `$FRACTOGENESIS_HOME` and `reimage.env`, so Step 3 is the first
moment there is anything to run.

One of five flips is a straightforward correction; four are pins. Both numbers
belong in the record.

**Rejected — pin all five to their current pointers.** It would make the rule
change cosmetic: every lineage it touches would be exempted from it on the day it
was introduced, and `enroll-and-stabilize-initial` shows what that would have
cost — the pointer would have stayed on a run recording a machine that had
already restarted, under a point named `initial`.

**Rejected — apply the rule and say nothing.** A silent retroactive flip is the
failure mode D3 exists to prevent, and four of these runs predate the flag that
would have recorded it.

## What this authorises

Toolkit writes: the point-rule constants, the header paragraph, the rebuild
reporting, and the `--note` pass-through in the two recorders.

**Four evidence writes are named but not authorised here**: the
`restore-repos-entry`, `restore-git-entry`, `restore-access-entry` and
`restore-apps-entry` pins. All four need the owner's word for
`reimaged-system/bookends/`, and until they are taken all four pointers regress on
the next rebuild — stated rather than mitigated, because mitigating it would mean
pinning without permission.

**None of these lineages carries a pin today, and none needs one today.** `entry`
is latest-wins in the tree as it stands, so the later run is official by the
ordinary rule. The pins exist only because D2 changes that, and they are part of
the same act.

It also produced one new reading, `0034`, recorded unowned. Recording a bundle and
owning one are different acts, and this session's manifest is unchanged at ten.
