# Resolutions — a lineage rename is a procedure, not an operation

**Bundle:** `0035-a-lineage-rename-is-a-procedure-not-an-operation` · **Status:** `resolved`
**Recorded:** 2026-09-04, session `session_01PcgHu9kz9Hm5RatLQuFR8H`.

One toolkit write: `artifact_run_rename_lineage` in `.internal/artifact-runs.sh`.

| Finding | Decision | What was done |
|---|---|---|
| 1 — a rename is three manual acts with no operation | D1 | `artifact_run_rename_lineage` performs all five steps in the one order that leaves the category consistent |
| 2 — recovery is one-way, so a half-done rename completes wrongly | D2 | **Corrected.** `artifact_runs_rebuild` is loud; `bin/reindex-artifact-runs.sh` is the silent one. The header now records the stale-pointer behaviour |
| 3 — a run carries no lineage identity | D3 | **Not built.** D1 removes the need, and a marker cannot cover the case it exists for — a pre-existing run renamed by hand |

## The operation

    artifact_run_rename_lineage "$CATEGORY_ROOT" "<former>" "<surviving>" "<reason>"

Five steps, in this order:

1. `artifact_run_record_rename` — the former name, **first**, so a failure part-way
   leaves the record present and the rest recoverable.
2. move each `runs/<former>-STAMP` to `runs/<surviving>-STAMP`, keeping the stamp.
3. append a `run` row per moved run, carrying its original completion time and a
   note naming the id it was renamed from.
4. `artifact_run_retire_lineage` on the former context.
5. `artifact_runs_rebuild`.

**Step 4 is the one that was missing, and it is why a former name was lost.**
Measured rather than assumed: without it the old context keeps its `run` rows, so
every later rebuild loops over it, reports *computed official run is not on disk*,
and **leaves its stale pointer file in place** — the rebuild continues past the
error without removing it. `artifact_run_retire_lineage` has existed since
Revision 136 and is exactly the right instrument; nothing had ever called it as
part of a rename.

Refusals rather than damage: a pre-existing target id, an unmovable directory, a
former context with no runs, a missing reason, identical contexts. Each returns
before doing more, and a partial move reports how many runs had already moved.

## Verified end to end

In a scratch category, two runs on a first-wins lineage:

```text
before   runs/post-image-old-name-before-20260904-203657, -203658
after    runs/post-image-new-name-before-20260904-203657, -203658
official/  post-image-new-name-before.txt   (one file; the old pointer is gone)
manifest   rename row, two new run rows, one retire row -- all appended
recover    _artifact_runs_rows_for ... rename -> post-image-old-name-before
```

A rebuild afterwards reports nothing about the former lineage. Argument guards
were exercised individually and return `2` for caller error, `1` for a stated
refusal.

## A known limitation, stated rather than discovered later

The `run` rows appended in step 3 carry `—` in the **Result** column. The library
has no accessor for a prior row's result, and inventing one for this is more
machinery than the case earns. **The original rows remain in the manifest with
their results intact** — the manifest is append-only, so nothing is lost; a reader
wanting the result of a renamed run reads the row under the former context, which
the `rename` row tells them how to find. That is the mechanism working, and it is
also why this was acceptable to leave.

## What is not done

**No rename was performed.** Running this against a category is an evidence write
and needs the owner per category. Three are queued: `0030` D7's retroactive rows
for `office-stability/` and `reimaged-system/comparisons/`, whose renames already
happened by hand and which therefore want `artifact_run_record_rename` rather than
this operation.

**`0014`'s orphaned lineage** — `comparisons/official/restore-runtime-version-comparison`
names a producer that does not exist. That is a retirement, not a rename, and it
belongs to the session that owns `0014`.

## Validation

Documentation lint 0 MISSING, 0 ANCHOR BROKEN. Findings counts 0 FAIL. Findings
structure 0 FAIL. Runbook structure 213 PASS / 5 WARN / 25 FAIL across 27
documents, unchanged. Script portability **0 WARN / 0 FAIL**, `bash -n` clean.
Exercised only in a scratch category; **the artifact volume was not touched**.
Composed in a copy outside the owner's checkout, per `0028`. **`/bin/bash -n`
against macOS stock Bash 3.2 is owed** — the function uses `local`, `[ ]`, `case`,
`mv`, `sed` and `printf` with no Bash 4 construct, and the portability lint agrees,
which is not the same claim.
