# Resolutions — renames break citations, and only a record's values are frozen

**Bundle:** `0030-renames-break-citations-and-which-may-be-repaired` · **Status:** `resolved`
**Recorded:** 2026-09-04, session `session_01PcgHu9kz9Hm5RatLQuFR8H`.

Five findings, five decisions, one toolkit write. `findings.md` is unchanged apart
from its per-finding status table, which is the one part of it that moves.

| Finding | Decision | What was done |
|---|---|---|
| 1 — a rename breaks citations and nothing detects it | D8 | **Deferred, with a measurement.** Both detector designs were prototyped read-only against the volume; neither works today, and the second is structurally blind for the reason the finding names. Detection is downstream of D7 and becomes tractable once `rename` rows exist |
| 2 — the repair rule was never written down | D2 | Written down. A record's **values** are frozen; a **reference** inside one may be repaired where the target still exists and the timestamp is retained exactly. `.internal/artifact-runs.sh` now names the bundle that holds it |
| 3 — no `rename` row, so a former name is unrecoverable | D7 | **`artifact_run_record_rename` added** to `.internal/artifact-runs.sh`, with the header rule that explains it |
| 4 — `0009`'s own text cites a path Revision 156 moved | D4 | **Deliberately not repaired.** A superseded reading is frozen; `0030` finding 4 records the current path instead |
| 5 — Revision 138 broke a citation inside its own run | D3 | Two lines repaired 2026-09-03 on the owner's word for that run. The pre-conversion backup retains both originals |

## The toolkit write

`.internal/artifact-runs.sh`, one function and one header rule:

```text
artifact_run_record_rename "$CATEGORY_ROOT" "<surviving-context>" "<former-context>" "<reason>"
```

Appends one row with `rename` in the Kind column, the **surviving** context in
Context, and the former key in `Run or target` — the shape D7 specified. Modelled
on `artifact_run_retire_lineage`; `_artifact_runs_append_row` already takes the
kind, so the row needed no new machinery. Refuses a missing argument or reason
with `2`, a missing manifest with `1`, an invalid or identical context with `2`,
and is idempotent: a second identical call notes and returns `0`.

The header gains **A LINEAGE RENAME IS A MIGRATION, NOT AN EDIT**, beside the
phase-ordinal rule it extends. It states why the row is filed under the surviving
context, that the row records rather than repairs, that lineage renames are its
scope and category renames have no record here, and it names the bundle.

**D7's inertness claim was verified rather than trusted.** In a scratch category:
the pointer was byte-identical before and after `artifact_runs_rebuild`, no extra
`official/` file appeared, a `run` lookup could not see the `rename` row, and a
`rename` lookup recovered the former name. Return codes were exercised
individually and match the file's documented contract.

## What is owed and was not done here

- **Three retroactive `rename` rows** — D7's table, two categories. Evidence
  writes, needing the owner per category. **Not authorised by this bundle.**
- **The `bookend.md` citation** — D5, queued not taken, and the probe found it in
  **two** files rather than one: `restore-runtime-exit-20260820-032645/bookend.md`
  line 19 and `restore-access-entry-20260824-063529/bookend.md` line 16. Both
  repairable under D2; both need the owner's word.
- **Detection** — D8. Deferred, not rejected, and downstream of the rows.
- **Category renames** — D7 scoped itself to lineage renames and said so. A
  category rename still has no record in the index.
- **The rename procedure itself** — parked as `0035`, recorded in the same sitting.

## A note on how this bundle was decided

D7 was written by `run-index-design-20260901-000000` under an owner's override of
`docs/legend.md`'s rule that from `in progress` onward only the owner writes to a
bundle. D7's closing claim that every finding then carried a decision was wrong —
finding 1 did not, as D7's own text says two paragraphs earlier — and this session
made the toolkit write before noticing. The write was held in the composing copy
until D8 closed the gate honestly, and reached the repository only afterwards.
Recorded because a gate crossed and then un-crossed leaves no trace otherwise.

## Validation

Documentation lint: 0 MISSING, 0 ANCHOR BROKEN. Findings counts 0 FAIL. Runbook
structure 213 PASS / 5 WARN / 25 FAIL across 27 documents, unchanged. Script
portability **0 WARN / 0 FAIL** with the new function present, and `bash -n` clean.
Functionally exercised in a scratch category, never against the artifact volume,
which was read-only throughout. Ran on Linux with Bash 5.1: **`/bin/bash -n`
against macOS stock Bash 3.2 is owed for this revision**, as it is from Revision
116 onward. The function uses no construct newer than 3.2 by inspection —
`local`, `[ ]`, `printf`, no arrays — and the portability lint agrees, but that is
not the same claim as having run it there.
