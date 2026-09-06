# Resolutions — the index and manifest tables have a shape nothing checks

**Bundle:** `0032-index-and-manifest-tables-have-a-shape-nothing-checks` · **Status:** `resolved`
**Recorded:** 2026-09-04, session `session_01PcgHu9kz9Hm5RatLQuFR8H`.

One toolkit write: `bin/verify-findings-structure.sh`, a fifth repo lint.

| Finding | Decision | What was done |
|---|---|---|
| 1 — a required column shape that no check enforces | D1 | The check takes each table's column count from its own header and compares every data row beneath it |
| 2 — `verify-doc-paths.sh` gives false assurance | D2 | **Nothing.** That lint was correct; the error was reading *the lints are clean* as a claim about shape. D1's check makes the reading true |
| 3 — the fix is a lint, so the tree may be wrong | D3 | **Stays here**, on the owner's routing. The disagreement between §4c's test and `0029`'s principle is recorded, not resolved |
| 4 — a patch containing a deletion under-applies silently | D4 | The tag half of D1's check catches the residue every one of the four instances left. Prevention is procedural and is owed elsewhere |

## What the check does

Two invariants §§4c–4d state and nothing tested:

- **every data row carries its own table's column count.** The count comes from
  the header that opens the table, not from the file, because
  `docs/runbook-findings/INDEX.md` holds a rollup above the detail table with
  different columns. Blank cells are legal and are not flagged — that detail
  table leaves `Runbook` empty on continuation rows, meaning *same as above*.
- **every bundle carries exactly one `STATUS-` tag, agreeing with its index row.**
  Both halves, because the defect this exists for left the old tag *beside* the
  new one rather than replacing it.

43 OK / 0 FAIL on the tree as it stands.

## It was verified against the defects, not just against a clean tree

Each of the three classes was reproduced and the check was made to fail on it:

```text
row has 8 cells, its table header has 7        <- the Revision 183 malformed row
expected exactly one STATUS- tag, found 2      <- the four-instance deletion residue
tag says 'resolved', row says 'in progress'    <- §4c's stated, unenforced rule
```

## Two bugs in the check itself, found by running it

The first version reported **36 failures** against a tree every other validator
passes, which is a broken detector rather than 36 defects.

- A greedy `gsub(/^.*`/, "", s)` ran past the closing backtick: it returned the
  URL from `[`superseded`](0030-…/)` and an empty string from a plain
  `` `resolved` ``, so 34 bundles read as unindexed. Replaced with a `match` on
  the first backticked token.
- The cell counter treated the escaped `\|` inside `[[path\|Label]]` as a
  separator, so the one legitimate wikilink in `docs/sessions/INDEX.md` read as a
  row with an extra cell. Escaped pipes are stripped before counting.

Recorded because a lint that cries wolf on its first run is worse than no lint,
and because both bugs were in the part of the check that reads the tree rather
than the part that judges it.

## Why a fifth validator rather than an extension

`bin/verify-findings-counts.sh` already opens every index, every manifest and
every bundle directory, so extending it was the obvious move. Its header states
its charter — *a fact has one home, and a copy is permitted only where a check
fails on drift* — and it exists for **derived facts displayed twice**. A tag and
its row are such a pair; **a table's column count is not a copy of anything**.
D1 records the trade: a fifth baseline in every manifest entry, accepted, against
a script whose own header would have become untrue.

`0029` decision 3.1 rejected a lint of its own and named this bundle while doing
it. That rejection was of a check whose purpose was to *license a duplicate that
could be removed instead* — and 3.1 removes the duplicates. Nothing here can be
removed: the tables must exist and their shape is load-bearing.

## Owed, and named so it is not rediscovered

**Prevention for finding 4.** *Verify a deletion actually happened with
`git diff --summary` after applying any patch that contains one.* That is a rule
about how a session applies work, which belongs where `0028`'s compose-in-a-copy
rule lives — `docs/legend.md` and §§4c–4d, both held by another session.

**The rollup rows are still unchecked.** Revision 190 added
`| Runbook | Bundles | Findings | Resolved |` to `docs/runbook-findings/INDEX.md`,
27 derived figures with no source relationship expressed.
`verify-findings-counts.sh` is owed the rule that each rollup row equals the detail
rows beneath it. That is a gap in a check that exists, not in one that is missing,
and `restore-apps-outstanding-20260903-000000` has claimed it.

## Validation

Documentation lint 0 MISSING, 0 ANCHOR BROKEN. Findings counts 0 FAIL. Findings
structure **43 OK / 0 FAIL**. Runbook structure 213 PASS / 5 WARN / 25 FAIL across
27 documents, unchanged. Script portability **0 WARN / 0 FAIL** with the new
script, `bash -n` clean. Composed in a copy outside the owner's checkout, per
`0028`. **`/bin/bash -n` against macOS stock Bash 3.2 is owed** — the script uses
`awk`, `sed`, `grep`, `cut` and no Bash 4 construct, and the portability lint
agrees, which is not the same claim.
