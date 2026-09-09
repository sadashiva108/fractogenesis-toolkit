# Resolutions — the index and manifest tables have a shape nothing checks

**Bundle:** `0041-index-and-manifest-tables-have-a-shape-nothing-checks`  
**Session:** `assurance-coverage-20260908-204724`  
**Resolved:** 2026-09-09

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F1 | D2 | `.internal/ai-scripts/session-management/verify-findings-structure.sh` gained the per-table column-count check: the header that opens a table fixes its width and every data row is compared against it. Run on this tree, 62 OK / 0 FAIL. The later `Bundle:`-value half of F1 was checked separately on 2026-09-09 by comparing each `decisions.md` and `resolutions.md` header against the directory it sits in; all ten agree | 195 | `92a4f79` |

**F2, F3, F4, F5 and F6 are `decided` and not resolved**, and are absent from
this table deliberately. F2's remedy is D1 and is a toolkit write; F3 decided the
tree and changed nothing; F4 is closed on the record by section 6 and open on the
check; F5 and F6 specify checks that do not exist yet.

**This file exists because it was missing.** F1 was moved to `resolved` with its
claim recorded in `metadata.json` and in D2, and no row here — which is the state
`0047` F3 names from one side and section 9b names from the other: *a decided
finding whose decisions have been carried out and which has no row is a defect.*
`./bin/verify-session-findings.sh headers` did not catch it, because a bundle
with no `resolutions.md` has no citations to cross-check and passes vacuously.
That is `0041` F1's own shape — **a required thing, absent, and the check reads
as clean** — arriving inside the bundle that records it, on the day it was
decided.
