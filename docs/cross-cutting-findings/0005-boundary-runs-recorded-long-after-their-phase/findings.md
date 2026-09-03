# Four boundary runs are dated the day the recorder was extended, not the day the phase ran

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, item 2.
**Severity:** none to the workflow; real to anyone reading timestamps as phase
timestamps.

## What the dates say

| Phase | Boundary runs | The phase's own evidence |
|---|---|---|
| `enroll-and-stabilize` | entry 2026-08-31 14:43, exit 2026-09-01 14:44 | restarts: initial 08-18 06:31, pre-restart 08-18 23:57, post-restart 08-19 00:07 |
| `verify-reimaged-system` | entry 2026-08-31 15:17, exit 2026-08-31 16:02 | restarts: initial 08-18 07:32, pre-restart 08-19 01:26, post-restart 08-19 01:34 |

Both phases ran on 18–19 August. Both boundaries were recorded on 31 August —
the same day as commit `b94fa58`, *"Refactored entry and exit captures and added
where missing."*

So the boundaries are **retro-recorded**, and deliberately: the recorders did not
exist in that form when the phases ran. The `boundaries/MANIFEST.md` answer to
*"did this phase both start and finish"* is yes for both, which is true. What it
cannot tell you is when.

## Why it is worth writing down rather than fixing

There is nothing to fix. A boundary recorded late is better than no boundary, the
runs are honest about their own generation time, and re-recording them now would
only move the timestamps further from the phase.

The hazard is interpretive, and it is the same one `artifact-runs.sh` guards
against for `before`:

> a `before` captured after the runbook has already written is well-formed and
> wrong

An `entry` captured thirteen days after the phase started is well-formed and
describes a machine that had already been through the phase, Phase 10A, Phase 10B
and Phase 11A. `entry` is latest-wins, so nothing refused it and nothing warned.

## Plan

No re-run. Two cheap things instead, for whoever next touches these recorders:

1. **Say so in the runs themselves.** `record-enrollment.sh` and
   `record-reimaged-system.sh` already title their output by runbook and carry
   the phase as context sourced from the invocation. A `--note` passed through to
   the manifest `Note` column would let a retro-recorded boundary say
   *"recorded retrospectively; the phase ran 2026-08-18"* in the one file a
   reader consults.
2. **Do not read boundary timestamps as phase timestamps** anywhere in items 5
   through 7. The restart lineages under `restarts/` are the honest clock for
   Phases 8 and 9, because those were recorded as the phase ran.

Item 5's post-image inventory should treat this as the worked example of why
*"what exists"* and *"when it was true"* are different columns.
