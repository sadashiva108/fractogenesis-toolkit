# Renames break citations, and only a record's values are frozen

**Found:** 2026-09-03, session `session_01PcgHu9kz9Hm5RatLQuFR8H`, while reading
four pre-image runbook findings against the artifact volume.
**Relates to:** `0009` — **supersedes it.** `0009` carried the reading below as
its findings 1 and 3; it is marked `superseded` and left unedited, so the
2026-09-01 reading survives as it was written.
**Severity:** the reading itself is low. Finding 2 is what matters: without it,
every citation a rename breaks is treated as unrepairable, and the tree
accumulates broken pointers to evidence that is still there.
**Scope:** cross-cutting. Felt in `.internal/artifact-runs.sh`, in every category
manifest, and in dated artifacts across the volume.

## Why this bundle exists rather than an edit to `0009`

`0009` read the problem correctly and drew one conclusion from it: *no repair of
the 2026-08-20 checklist: it is a dated record and correcting it would be worse
than leaving it.* That conclusion is broader than the reasoning supports, and the
owner has since said what the intent was — the prohibition is on changing dates
and values, not on repairing a filename. A reading that has been overtaken is
superseded rather than rewritten, so this bundle carries the merged reading and
`0009` keeps its own.

---

## Findings

| # | Finding | Status |
|---:|---|---|
| 1 | A lineage rename leaves every prior citation naming something gone, and nothing detects it | `in progress` |
| 2 | The repair rule was never written down, so every broken citation looked unrepairable | `in progress` |
| 3 | A category manifest records no `rename` row, so a former lineage name is unrecoverable from the index | `unresolved` |
| 4 | `0009`'s own text cites a path that Revision 156 moved | `in progress` |
| 5 | The Revision 138 conversion broke a citation inside the run it was converting | `in progress` |

---

### 1 — a rename breaks citations, and nothing detects it

Carried from `0009` unchanged in substance. A dated artifact is never
regenerated, so it holds run ids and filenames as literal text. A rename updates
the runs, the manifest and the pointers, and leaves every prior citation naming
something that is gone. `verify-doc-paths.sh` scans repository paths, not
artifact-root run ids, and the artifact root is not in the repository at all.

`.internal/artifact-runs.sh` states the sibling rule in its header — name a
lineage for its runbook, never for its phase ordinal, *because a dated artifact
is never regenerated*. Renames are the same hazard from another direction and
are not covered.

### 2 — the repair rule was never written down

`0009` recorded a prohibition without its boundary, and the boundary is where the
whole question lives. Stated by the owner 2026-09-03:

> A dated record's **values** are never edited — dates, measurements, verdicts,
> counts. A **reference** inside one — a filename, a path, a run id — may be
> repaired when the thing it names still exists, provided any timestamp in the
> name is retained exactly. The stamp is what binds the citation to the same
> evidence; changing it would falsify. Repairing the name around it restores a
> pointer.

Nothing in `0009`, `artifact-runs.sh` or the instruction set draws that line. The
cost of leaving it undrawn is visible in `0009` itself: it declines to repair a
citation whose target it had already located on the volume, unchanged, under a
new lineage name.

**One case the rule does not reach**, and it is not hypothetical — see finding 5:
a reference that was wrong when it was written, naming a file the producer never
created. Repairing that changes what the producer *claimed* rather than what it
*measured*. It is still a reference and not a value, so the rule admits it, but
the rule does not say so and should.

### 3 — no `rename` row, so the old name is unrecoverable from the index

`0009` proposed a `rename` row in the category `MANIFEST.md` — the manifest is
append-only and already carries `pin` rows — and left it as a decision for
whoever did the first conversion. Two conversions have since happened and neither
added one:

- `office-stability/MANIFEST.md` carries two rows, both noted `recovered by
  reindex`. Neither records that this lineage was `pre-image-office-stability-checklist`
  until Revision 138. The old id survives only in `_pre-conversion-backup-20260902/`.
- The `boundaries` → `bookends` rename of Revision 156 added none either, which
  the `phase-11b-hydrate-and-bookends-20260903-141500` final summary records.

So the mechanism that would make a broken citation traceable rather than merely
disbelieved does not exist yet, and the two events that would have exercised it
have passed.

### 4 — `0009` cites a path that has moved

`0009`'s instance names
`reimaged-system/boundaries/runs/restore-runtime-exit-20260820-032645/checklist.md`.
Revision 156 renamed that directory to `bookends/` and the record inside it to
`bookend.md`. Verified on the volume 2026-09-03: `boundaries/` does not exist;
the run is at `bookends/runs/restore-runtime-exit-20260820-032645/bookend.md`.

The finding about renames breaking citations contains a citation a rename broke.
It is in the repository rather than on the volume, which makes it cheaper to
repair and no different in kind.

The citation it *reports* is still live at `bookend.md` line 19:

```text
| Runtime comparison recorded | `PASS` | `post-image-restore-runtime-diff-20260820-032625` |
```

and its target exists as
`reimaged-system/comparisons/runs/restore-runtime-inventory-diff-20260820-032625`.
Under finding 2's rule it is repairable, stamp retained. Note it is stale twice:
the lineage was renamed *and* the `post-image-` prefix was later dropped, because
`artifact-runs.sh` holds that everything under `reimaged-system/` is post-image by
construction. The correct repair is
`restore-runtime-inventory-diff-20260820-032625`.

### 5 — Revision 138 broke a citation inside the run it was converting

`office-stability/runs/pre-image-office-stability-assessment-20260817-175050/README.md`
listed two files that did not resolve:

| Line | Named | Why broken |
|---|---|---|
| 7 | `pre-image-office-stability-checklist.md` | Revisions 137/138 renamed it to `office-stability-assessment.md`. The target existed the whole time |
| 8 | `watcher/marker-timestamp.txt` | never written into this bundle. `watcher/` holds `marker-and-current-time.txt`. The August producer named a file it did not create |

Two different causes in one file: a rename, and a producer that was wrong from
the start. **Both are historical only** — the current
`bin/assess-office-stability.sh` interpolates `$REPORT_FILENAME` into the README
(line 736) and does write a `marker-timestamp` target, so Phase 13E produces a
correct one. No producer fix is owed.

A scan of every `README.md` inside every converted run — office-stability,
time-machine, toolkit-snapshot and the three performance-audit lineages — found
this file and no other. The conversion did not do this generally; it did it once.

**Both lines were repaired 2026-09-03** on the owner's direction, under finding
2's rule. The pre-conversion copy in
`_pre-conversion-backup-20260902/office-stability/checklists/pre-image-office-stability-checklist-20260817-175050/README.md`
retains both original lines verbatim, so the repair destroyed no evidence — which
is the condition that makes a repair safe and which `0009` did not consider.

---

## What it costs to leave

Findings 1 and 4 cost accuracy in documents that exist to be read back later.
Finding 3 costs traceability: a citation that no longer resolves cannot be
distinguished from one that was always wrong.

Finding 2 is the one that compounds, and in the opposite direction to how these
usually do. An over-broad prohibition does not fail loudly. It quietly converts
every repairable pointer into permanent damage, and each conversion of a category
— six are still queued in item 4 — adds more of them.
