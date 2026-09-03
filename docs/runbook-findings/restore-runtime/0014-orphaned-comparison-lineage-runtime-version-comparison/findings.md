# `restore-runtime-version-comparison` is a lineage with no producer

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, item 2.
**Severity:** low. It will trip the item 4 coverage audit if it is not recorded
here first.
**Mechanism added by Revision 136:** the retirement it needed did not exist.
`artifact_run_clear_official` clears a *pin*, and officialness is computed — so
deleting the pointer by hand lasted until the next `artifact_runs_rebuild` put it
back. `artifact_run_retire_lineage` / `artifact_run_reopen_lineage` now exist and
`artifact_runs_rebuild` honours a `retire` row. **The command against the volume
is still owed** — see the report.

## What is wrong

`reimaged-system/comparisons/official/restore-runtime-version-comparison.txt`
points at `runs/restore-runtime-version-comparison-20260819-121523`, and the
manifest carries its row. Nothing in the repository writes that context.

`bin/compare-restored-state.sh` derives its context as
`${PHASE_RUNBOOK%.md}-inventory-diff` in both places it needs it (lines 600 and
926), so the only runtime lineage it can produce is
`restore-runtime-inventory-diff`. No other script, and no runbook, names
`version-comparison` — the string appears only in `APPLY-MANIFEST.md`, which is a
change log.

## Why it exists

The manifest explains it, and the explanation is correct:

> The output moved into the run index, from a flat
> `restore-notes/runtime-version-comparison-*.md` to a `comparisons/` category
> […] **Consequence worth knowing:** the existing
> `runtime-version-comparison-20260819-121523.md` is now invisible to that row.
> The Phase 10A exit already recorded with it and that artifact stands […] The
> old file is left in place — it is evidence of what was compared on the 19th,
> not clutter.

Leaving the file was right. What went one step further than intended is that the
migration also gave it an `official/` pointer of its own, which made a one-off
historical artifact look like a live lineage. Officialness is computed per
lineage, so a lineage that will never receive another run has a pointer that will
never advance, and nothing in the category says why.

## Plan

Two defensible answers; neither is urgent.

- **(i) Leave the run, drop the pointer.** `artifact_run_clear_official` takes a
  reason, which is exactly the field for *"one-off migrated from
  `restore-notes/`; superseded by `restore-runtime-inventory-diff`"*. The run
  stays indexed and readable; the category stops advertising a lineage nothing
  feeds. **Preferred.**
- **(ii) Leave both and document it** in the item 4 survey as a known one-off.
  Cheaper now, and it means every future coverage pass rediscovers it.

Either way, item 4 should list this lineage explicitly as *not a conversion
candidate* so the question is answered once.
