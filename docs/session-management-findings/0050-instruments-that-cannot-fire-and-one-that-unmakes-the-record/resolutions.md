# Resolutions — instruments that cannot fire, and one that unmakes the record

**Bundle:** `0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record`  
**Session:** `assurance-coverage-20260908-204724`  
**Resolved:** 2026-09-09, and 2026-09-11 for F11

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F5 | D2 | `doc_currency.py` gained `coverage_roots()`, which parses the directory table in `docs/INDEX.md` and adds `alsoWalk` from `doc-currency.json`; the five-element `roots` tuple is gone. `cmd_coverage` sweeps those, plus every repository-root `*.md`, and prints what it swept and what was declared out. `doc-currency.json` gained a `coverage` block with `alsoWalk` and five `exclude` entries, each carrying its reason. Reported unwatched moves 21 → 62 | 255 | — |
| F3 | D3 | `.internal/ai-scripts/session-management/extract-metadata.py` is deleted. Its `--check` half is `check-metadata-completeness.py`, a new file in the same directory holding `ATOMIC` and `check_completeness()` unchanged, self-locating from `BASH_SOURCE`-equivalent rather than shelling out to `git rev-parse`; `check-completeness.sh` `exec`s it. **Nothing in the new file writes.** Fired on all three of its classes in a throwaway — a dash where `null` belongs, a bold marker in an `ATOMIC` value, a markdown row that did not become an object — and is silent on the tree | 299 | — |
| F6 | D3 | The same deletion. F6's measurement half is answered by the re-measurement recorded in F3, and its procedure half is not resolved here: §10a still has no fifth step, and that file belongs to `entity-model-and-vocabulary-20260909-053548`. **What the deletion removes is the hazard, not the gap** — the by-hand act F6 names is now the only act | 299 | — |

| F11 | D4 | The copy in `verify-findings-structure.sh` is deleted. The script imports `plan_findings_work`, emits `bundle_standing` for all 56 bundles and `session_state` for all 12 sessions into one table and looks answers up; a failure to run it exits 2 rather than skipping. `TestLadder` gained the ordering assertion — both overrides on one bundle, over both ownership values and four status shapes, plus each override alone. Suite 73 → 74; inverting the two `if` statements in the module fails two of them | 308 | — |

**F1, F2, F4, F7, F8, F9 and F10 are `framing` and owe no row.** F1's remedy is decided as
`0049` D4 and is another bundle's to carry out; F2 and F3 are repairs waiting on
a bundle type that can hold a build; F4 is a class whose members are still
arriving — F5 was its fifth.

**`Commit` is `—` because the commit does not exist yet.** The revision is taken
at apply time and the owner commits.

<!-- historical: .internal/ai-scripts/session-management/extract-metadata.py -->
<!-- Deleted at Revision 299, carrying out D3. This document is the record of
     that decision and its carrying-out, so the citation is evidence and is not
     repaired. The check half is now check-metadata-completeness.py. -->
