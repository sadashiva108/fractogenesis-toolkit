# Resolutions — instruments that cannot fire, and one that unmakes the record

**Bundle:** `0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record`  
**Session:** `assurance-coverage-20260908-204724`  
**Resolved:** 2026-09-09

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F5 | D2 | `doc_currency.py` gained `coverage_roots()`, which parses the directory table in `docs/INDEX.md` and adds `alsoWalk` from `doc-currency.json`; the five-element `roots` tuple is gone. `cmd_coverage` sweeps those, plus every repository-root `*.md`, and prints what it swept and what was declared out. `doc-currency.json` gained a `coverage` block with `alsoWalk` and five `exclude` entries, each carrying its reason. Reported unwatched moves 21 → 62 | 255 | — |

**F1, F2, F3 and F4 are `framing` and owe no row.** F1's remedy is decided as
`0049` D4 and is another bundle's to carry out; F2 and F3 are repairs waiting on
a bundle type that can hold a build; F4 is a class whose members are still
arriving — F5 was its fifth.

**`Commit` is `—` because the commit does not exist yet.** The revision is taken
at apply time and the owner commits.
