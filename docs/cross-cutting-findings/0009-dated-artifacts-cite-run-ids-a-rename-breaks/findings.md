# Renaming a lineage silently breaks every citation already written

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, item 2.
**Severity:** low today, structural for items 3 and 4 — both propose renaming
lineages.

## The instance

`reimaged-system/boundaries/runs/restore-runtime-exit-20260820-032645/checklist.md`
records:

```
| Runtime comparison recorded | PASS | post-image-restore-runtime-diff-20260820-032625 |
```

No run by that name exists. The comparison lineage was later renamed from
`restore-runtime-diff` to `restore-runtime-inventory-diff` — for a good reason,
recorded in the manifest: two questions were sharing one `-diff` pointer, so it
named whichever ran last regardless of which question it answered.

The **evidence survived** the rename. The run is on the volume as
`restore-runtime-inventory-diff-20260820-032625`, and its readers
(`record-restore-prereqs.sh:494`, `record-restore-exit.sh:321`) were correctly
repointed. Only the *citation* dangles, and it dangles in the one artifact whose
whole purpose is to be read back later.

## The general property

A dated artifact is never regenerated — that is the point of it. So it holds run
ids as literal text, and a lineage rename updates the runs, the manifest and the
pointers while leaving every prior citation naming something that is gone. There
is no check that would catch it: `verify-doc-paths.sh` scans repository paths,
not artifact-root run ids, and the artifact root is not in the repository at all.

`artifact-runs.sh` already states the sibling rule for exactly this reason:

> NAME A LINEAGE FOR ITS RUNBOOK, NEVER FOR ITS PHASE ORDINAL. […] every artifact
> naming the old ordinal was wrong from that moment with nothing to catch it,
> because a dated artifact is never regenerated.

Renames are the same hazard from a different direction, and are not covered.

## Why this matters now rather than in the abstract

Two queued items rename lineages:

- **Item 3** converts `time-machine/` and gives every context a phase
  discriminator (`pre-image-status`, `post-image-status`, …). Phase 5 evidence
  is signed off and cites flat filenames.
- **Item 4** surveys every remaining category for conversion, which is a rename
  by another name.

So the cost of a rename is not only the migration — it is every sign-off and
checklist that already names the old thing.

## Plan

No code change proposed, and no repair of the 2026-08-20 checklist: it is a
dated record and correcting it would be worse than leaving it.

What is worth adopting is a rule, and the cheapest place for it is the
`artifact-runs.sh` header beside the phase-ordinal rule it extends:

> **A lineage rename is a migration, not an edit.** Repoint the readers, and
> record in the manifest what the lineage used to be called, so a citation that
> no longer resolves can be traced rather than merely disbelieved.

A `rename` row in the category `MANIFEST.md` — the manifest is append-only and
already carries `pin` rows — would make the old name recoverable from the same
file that holds the runs. Whether that earns its complexity is a decision for
whoever does item 3, since that is the first conversion that will need it.
