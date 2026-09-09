# Decisions — citations under `docs/` resolve nowhere, and nothing reads them

**Bundle:** `0044-citations-under-docs-resolve-nowhere-and-nothing-reads-them`  
**Session:** `assurance-coverage-20260908-204724`  
**Decided:** 2026-09-09

`0041` F2 co-decides F1 and the coverage question is answered once, in `0041`'s
`decisions.md` D1. This file records what that answer means here, and repairs the
tree.

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | The eight broken citations are repaired now, as a record write. **The repair is undone by the next writer until the check exists**, and saying so is the argument for building it | F1 | 2026-09-09 | `accepted` |
| D2 | A citation to a rule that moved is repaired; a citation to a record's own moment is marked `historical` and never repaired. F2 is the first kind | F2 | 2026-09-09 | `accepted` |
| D3 | The check `0041` D1 specifies is not built here. It is a toolkit write with no bundle type yet | F1, F2 | 2026-09-09 | `accepted` |

---

## D1 — repair the eight, and say what the repair does not buy

`docs/cross-cutting-findings/INDEX.md` cites session bundles from a directory one
level under `docs/`. The correct spelling from that depth is `../sessions/`,
used **30 times elsewhere in the tree**. Eight rows use `../../sessions/`, which
resolves to `sessions/` at the repository root, where nothing exists.

**F1 recorded four. There are eight.** The four were recorded 2026-09-06; four
more were written between then and 2026-09-09, and the broken spelling is now the
one a reader meets first in that file. F1 predicted this in its own words — *"the
majority form is the broken one, which is why reading the file teaches the wrong
pattern"* — and the prediction came true inside three days, unobserved, while
`./bin/verify-doc-paths.sh --all` reported **0 MISSING / 0 ANCHOR BROKEN** over
the whole tree on every run in between.

**Repaired here: all eight, to `../sessions/`.** Verified by resolving each
target against the tree after the edit.

**This repair does not hold.** Nothing reads these citations, so nothing will
report the ninth. The reason to write that down rather than leave it implied is
that it is the entire argument for `0041` D1: a defect class whose only remedy is
attention has been repaired twice and has grown both times.

**Its enforcement avenue today is `nowhere`**, in the sense
`docs/rules/rule-enforcement-avenues.md` §2 gives the word: not unimportant, but
held by a person remembering, and *"discovered by breaking it"*. Recording that
is what stops a clean `verify-doc-paths.sh --all` being quoted as evidence these
citations resolve — which it has been, on every run since Revision 219.

## D2 — repair what moved, mark what is frozen

`0046` F2 constrains this decision, and its constraint is the distinction between
two things that look identical at the point of citation:

- **A citation to a rule that moved** names something that still exists
  elsewhere. Repairing it is correcting a pointer, and the reading is untouched.
- **A citation to a record's own moment** names something as it stood. Repairing
  it would falsify the record, and `bin/verify-doc-paths.sh` already carries the
  marker for it — `<!-- historical: -->`, documented in that script's header as
  *"This is `0046`'s marker"*, with 62 paths in the tree using it.

**F2 is the first kind.** `docs/cross-cutting-findings/INDEX.md` line 15 and
`docs/sessions/INDEX.md` line 9 cite `.github/copilot-instructions.md` sections
4c and 4d. Revision 191 split that file; the bundle layout and the numbering rule
are now sections 3 and 2 of `.github/session-management-instructions.md`, and the
session shape is section 5. Both citations are live navigation in an index — not
evidence, not dated, not a record of a moment. They are repaired.

**Rejected: marking them `historical`.** It was considered because the citation
was correct when written. It is wrong here: `historical` says *this path is
retained as it stood*, and an index row exists to be followed. Applying the
marker to live navigation would make the marker useless everywhere by making it
mean *this used to be right*.

## D3 — the check is specified here and built elsewhere

`0041` D1 carries the specification, the measurement and the false positive.
Building it changes `bin/verify-doc-paths.sh`, which is a **toolkit write**.
Section 6 gates one on a `decided` finding, which now exists — but the bundle
type for work whose output is a built thing does not, and that is
`docs/architecture/typed-bundles-and-work.md`, owned by
`typed-bundles-architecture-20260908-204724`. Deciding it from here would settle
by accident what that session is deciding deliberately.
