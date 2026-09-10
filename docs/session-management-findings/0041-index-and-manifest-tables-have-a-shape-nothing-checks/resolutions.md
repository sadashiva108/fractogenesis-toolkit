# Resolutions — the index and manifest tables have a shape nothing checks

**Bundle:** `0041-index-and-manifest-tables-have-a-shape-nothing-checks`  
**Session:** `assurance-coverage-20260908-204724`  
**Resolved:** 2026-09-09, and 2026-09-10 for F6

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F1 | D2 | `.internal/ai-scripts/session-management/verify-findings-structure.sh` gained the per-table column-count check: the header that opens a table fixes its width and every data row is compared against it. Run on this tree, 62 OK / 0 FAIL. The later `Bundle:`-value half of F1 was checked separately on 2026-09-09 by comparing each `decisions.md` and `resolutions.md` header against the directory it sits in; all ten agree | 195 | `92a4f79` |
| F6 | D6 | `.internal/ai-scripts/session-management/verify-findings-counts.sh` gained a fourth section and two functions, `total_lines()` and `members_column_of()`. In any document holding a table whose header carries a `Findings` or `Members` column over bundle-numbered rows, every prose total of the form `N bundles · M findings` is compared against that table's row count and the sum of that column. A fenced block, an inline code span and a table row are excluded, and a document carrying `<!-- historical-record -->` is skipped. **First run raised one, uncorrected**: `docs/session-management-findings/INDEX.md` line 53, **18 bundles · 113 findings** against **120** summed. Directed tests in a throwaway copy: a wrong bundles half caught, a wrong members half on a manifest using the newer word caught, the same sentence moved out of its backticks caught, left inside them silent, and the document declared a historical record skipped | 288 | — |

**F2, F3, F4 and F5 are `decided` and not resolved**, and are absent from this
table deliberately. F2's remedy is D1 and is a toolkit write; F3 decided the tree
and changed nothing; F4 is closed on the record by section 6 and open on the
check; F5 specifies a check that does not exist yet.

**F6 left that group at Revision 288** and is the first of the five to be carried
out. It was the shortest: D6 named the comparison, the false positive it would
produce, the suppressor to reuse, and the avenue — **check, not guard** — so
nothing was left to decide and the whole of the work was building it. **The other
four are not that shape.** F2 and F5 are D1's question, which `0041` D1 declines
to answer inside another finding; F3 changed nothing by design; F4's remaining
half is D1 again.

**This file exists because it was missing.** F1 was moved to `resolved` with its
claim recorded in `metadata.json` and in D2, and no row here — which is the state
`0047` F3 names from one side and section 9b names from the other: *a decided
finding whose decisions have been carried out and which has no row is a defect.*
`./bin/verify-session-findings.sh headers` did not catch it, because a bundle
with no `resolutions.md` has no citations to cross-check and passes vacuously.
That is `0041` F1's own shape — **a required thing, absent, and the check reads
as clean** — arriving inside the bundle that records it, on the day it was
decided.
