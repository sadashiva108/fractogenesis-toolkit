# The manual measures a tree that has moved, and its documents disagree with each other

**Recorded:** 2026-09-10, from auditing all thirteen `iris/` documents against the tree before building anything on them.  
**Session:** `instruments-and-blind-spots-20260909-220203` (`session_01Fo6sBeux1JTyDzgKhCx2KU`)  
**Severity:** F2 is the high one — the census it corrects is the evidence for a claim `iris/README.md` repeats as the honest summary of the system. F3 and F4 are one line each. F5 costs nothing today and is the largest unexercised mechanism in the framework.  
**Felt at:** `iris/vocabulary.md`; `iris/schema.md`; `iris/prism.md`; `iris/lumen.md`; `iris/verifications.md`; `iris/README.md`; `iris/lifecycles.md`  
**Scope:** `iris/`. No rule document and no `docs/` record is implicated; every defect here is in the manual.  
**Relates to:** `0050` — F8 is an instrument nobody runs; this is a document nobody re-measures, which is the same failure one layer up  
**Relates to:** `0043` — its F13 owns the closed set; F2 here is that set's census rather than the set itself

**Read:**

- all thirteen documents under `iris/`
- every `metadata.json` under `docs/`, at `d127b0e`
- `docs/legend.md` *Session states*
- `bin/test-session-management.sh`, `bin/verify-doc-paths.sh --all`

**Recorded, not owned.** A session may record a bundle it never owns. Nothing
here is decided, and the audit that produced it is
`docs/ledgers/iris-conformance.md`.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | Every measured figure in the manual has moved, by different amounts, and two documents already disagreed with each other | `un-started` |
| F2 | The edge census is wrong in four of twelve rows, and one row falsifies the claim the section rests on | `un-started` |
| F3 | The sentence that says the code is the tiebreak cites a path that does not exist | `un-started` |
| F4 | A session state's `Produces` column names a file that has never existed, against the legend | `un-started` |
| F5 | The reopen lifecycle is fully specified, has a generated document, and has never run | `un-started` |

---

## F1 — every figure has moved, and by different amounts

Measured at `d127b0e`:

| Figure | The manual says | Measured | Where the claim is |
|---|---:|---:|---|
| findings bundles | 54 | **54** | `prism.md`, `verifications.md` |
| members | 191 | **211** | `prism.md` twice, `lumen.md` four times, `verifications.md` |
| decisions | 143 / 134 | **155** | `schema.md` / `verifications.md` |
| edges | 59 | **70** | `prism.md` twice, `schema.md` |
| sessions | 11 | **12** | `schema.md` three times, `verifications.md`, `lifecycles.md` |
| `metadata.json` files | 65 | **66** | `schema.md` three times, `verifications.md` twice |
| tests in the suite | 67 | **69** | `README.md` §9 |

**Only the bundle count still holds.**

**And the manual already disagreed with itself before the tree moved.**
`schema.md` says **143** decisions and `verifications.md` says **134**, in
documents written days apart against the same tree. Neither is right now, and
**no reader could have told which was right then** — which is the defect, rather
than the drift.

**`verifications.md` is the one document that says how to read it**: *"Every
number below was measured on 2026-09-09 … Re-run the commands; do not quote these
figures forward."* That instruction is correct and it appears in one of the seven
documents carrying figures. **A currency note on one document does not cover the
six beside it**, and `prism.md` and `lumen.md` carry the same 191 with no such
line.

## F2 — the census is wrong in four rows, and one of them is load-bearing

`vocabulary.md` §8 lists twelve edge kinds with an **In the tree** column.
Measured against every `metadata.json`:

| Kind | Claimed | Actual |
|---|---:|---:|
| `blocks` | 5 | **7** |
| `constrains` | 3 | **4** |
| `evidences` | 0 | **1** |
| `relates-to` | 16 | **23** |
| the other eight | — | agree |

**Four of twelve, and the `evidences` row is the one that matters.**
`vocabulary.md` §13 closes on it: *"Six of the twelve edge kinds have zero
instances, and two of those six — `evidences` and `contradicts` — are the pair
that makes a trial recordable. **The machinery is present and unexercised.**"*
§8 says the same in its own words: *"Both are at zero today, so nothing in the
tree has yet been tested this way."* `iris/README.md` §9 repeats it as the honest
summary of the system.

**It is no longer true.** `0039/F28 evidences 0047/F1` exists, asserted with a
reason: the vocabulary half of a defect standing as the evidence the instrument
half rests on. **A trial has been recorded**, which is the thing three documents
say has never happened, and the count that would have shown it is a hand-typed
column.

**This is `0050` F8 one layer up.** There, an instrument that could have reported
the condition was reached by nothing. Here the condition is derivable from the
data by one query, and the document holds a copy nobody re-derives — which
`docs/legend.md` permits *only* where a check fails when it drifts, and nothing
checks this one.

## F3 — the tiebreak points at a path that does not exist

`vocabulary.md` line 11, in the masthead:

> **The tiebreak is the code.** Where this file and `lib/plan_findings_work.py`
> disagree, the code is what the data was stamped from, and this file is the
> defect.

**There is no `lib/` in this repository.** The file is
`.internal/ai-scripts/session-management/plan_findings_work.py`.

**The sentence that tells a reader where to go when the documents conflict is the
sentence with the broken address**, and it is the rule `docs/rules/README.md`
§6 states as the first of the things nothing else tells you. A reader who follows
it finds nothing and is left with the documents that disagree.

`verify-doc-paths.sh` does not catch it: `lib/plan_findings_work.py` is not
rooted at a `REPO_DIRS` component, and the bare-filename fallback resolves
`plan_findings_work.py` successfully somewhere else in the tree. **The path is
wrong in a way that reads as right to the checker.**

## F4 — a `Produces` column names a file that has never existed

`vocabulary.md` §6, session states:

| State | Produces |
|---|---|
| `active` | `manifest.md` |

**No `manifest.md` exists anywhere in the tree and none ever has.** The file is
`findings-manifest.md`, and `docs/legend.md` says so in the same table — which
makes this a rank-3 home and a rank-4 copy disagreeing on a filename, in the
column whose whole job is to name the file.

Every other row in that table is right, which is why it reads as correct.

## F5 — the reopen lifecycle is fully specified and has never run

`.github/session-management-instructions.md` §9a, `docs/legend.md` and three
`iris/` documents specify it: **nine reasons in a closed set**, an exit table
routing six of them to `decided` and three to `framing`, a required commit SHA,
and a generated document — *"`reopened.md` is GENERATED from those fields … Do not
hand-write it."*

Measured at `d127b0e`:

| | |
|---|---:|
| members with status `reopened` | **0** |
| non-null `reopened` blocks in any record | **0** |
| `reopened.md` files in the tree | **0** |

**Nothing has ever been reopened**, so no reason has ever been used, no exit has
ever been taken, and the generator has never been written — `reopened.md` is
described as generated by three documents and there is no generator for it
anywhere.

**This is not an argument for exercising it.** Reopening is reachable only from
`resolved` and only on a fault; a framework with nothing to reopen is a framework
that has not needed to. **It is an argument for saying so**, which is what
`iris/README.md` §9 already does for the actionable half and for edges, and does
not do here. The reopen machinery is the largest specified-and-unexercised
mechanism in the system and the manual presents it as working procedure.

**And it compounds F2.** `evidences` and `contradicts` were the stated example of
present-and-unexercised machinery; one of them has now fired. The reopen
lifecycle is the better example and nobody has named it.
