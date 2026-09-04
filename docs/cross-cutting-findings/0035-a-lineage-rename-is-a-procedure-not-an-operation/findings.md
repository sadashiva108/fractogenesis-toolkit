# A lineage rename is a procedure, not an operation

**Recorded:** 2026-09-04, `pre-image-capture-conformance-20260903-194532`
(`session_01PcgHu9kz9Hm5RatLQuFR8H`), from the owner asking what keeps a run
directory and its manifest row in step during a rename.
**Relates to:** `0030` — that bundle decided what a rename must *record* (D7) and
that detection waits on those records (D8). This is the third question: what
performs the rename, and what happens when it half-happens.
**Severity:** low today and self-inflicting. The volume is currently consistent —
162 manifest rows, 162 run directories, exact correspondence, no dangling
pointers. Every future rename is an opportunity to break that by hand.
**Scope:** cross-cutting. `.internal/artifact-runs.sh`,
`bin/reindex-artifact-runs.sh`, and every category that is ever renamed.

## Findings

| # | Finding | Status |
|---:|---|---|
| 1 | A rename is three manual acts with no defined order and no operation that performs them | `unresolved` |
| 2 | Recovery runs one way, so a half-done rename is silently completed in the wrong direction | `unresolved` |
| 3 | A run directory does not carry its own lineage identity, though the pin precedent shows how | `unresolved` |

---

### 1 — three acts, no operation

Renaming a lineage means: move the run directories under `runs/`, get the
manifest to describe the new name, and refresh `official/`. Nothing in
`.internal/artifact-runs.sh` performs that. `artifact_run_retire_lineage` and
`artifact_run_reopen_lineage` exist for lifecycle changes an order of magnitude
smaller; a rename, which touches all three surfaces, is left to whoever is doing
it.

`0030` D7 adds a fourth act — `artifact_run_record_rename`, the `rename` row — and
does not say when in the sequence it happens. That is not a defect in D7; it
decided what the row is. Nothing has decided what the *procedure* is, and a
four-step procedure with no defined order is a procedure that will be done in
different orders.

### 2 — recovery is one-way, so a half-done rename completes itself wrongly

The two repair commands regenerate in opposite directions, and neither treats the
other as authoritative:

- `bin/reindex-artifact-runs.sh` walks `"$CATEGORY"/runs/*` and appends a row for
  any directory with no row, noted *recovered by reindex*. **The disk regenerates
  the manifest.**
- `artifact_runs_rebuild` takes its context list from the manifest's Context
  column and recomputes `official/` from it. **The manifest regenerates the
  pointers.**

So identity flows `runs/ → MANIFEST.md → official/`, one way, and **the directory
name wins**. Two consequences, and both are silent:

- Rename the directories and then reindex, and the manifest is rebuilt describing
  the new name with no memory of the old. **This is what happened.**
  `office-stability/MANIFEST.md` carries exactly two rows and both read *recovered
  by reindex*, which is the fingerprint of that sequence; the former lineage name
  survives only in `_pre-conversion-backup-20260902/`, which is what made `0030`
  finding 3 recordable at all.
- Rename the manifest rows first instead, and the next reindex or rebuild quietly
  undoes it, because the directories still say otherwise.

There is no order that is safe by construction — only an order that happens to be
recoverable, and nothing states which it is.

### 3 — the run does not carry its own identity, and the pin shows the shape

`.internal/artifact-runs.sh` already solved this once, for pins, and its header
says why:

> A pin additionally drops `PINNED-OFFICIAL.txt` inside the run it promotes, so a
> run directory copied elsewhere carries its own pin, and a manifest rebuilt from
> `runs/` recovers pins that no longer have a manifest row.

That is precisely the property a renamed run lacks. A run directory holds no file
naming the lineage it belongs to, so its identity is its directory name and
nothing else — which is why renaming the directory is renaming the run, and why a
reindex after the fact cannot know anything was renamed rather than created.

The same trick would let a former name survive in the run itself, where a rebuild
cannot outrun it and a copy carries it along.

## What it costs to leave

Nothing until the next rename, and the next rename is already scheduled: item 4's
remaining conversions, `0030` D7's three retroactive rows, and `0014`'s orphaned
lineage all touch this machinery. The last rename cost the tree a lineage name
that is now recoverable only from a dated backup directory, and nobody noticed
until a finding was written about a broken citation two categories away.

## What this does not cover

Whether the retroactive `rename` rows are written, which is `0030` D7 and needs
the owner per category. Whether a citation detector is built, which is `0030` D8.
And `0014`'s untouched `comparisons/official/restore-runtime-version-comparison`
pointer, which `artifact_run_retire_lineage` has existed to remove since Revision
136 — that is a lineage with no producer rather than a rename, and it belongs to
the session that owns `0014`.
