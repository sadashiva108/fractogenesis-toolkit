# Decisions — `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold

**Bundle:** `0036-verify-doc-paths-counts-gitignored-docs`  
**Session:** `session-management-re-evaluation-20260906-110105` (`session_01FhFbEgG4wmrtJqUCcryNVQ`)  
**Recorded:** 2026-09-06, after measuring what scanning `docs/` finds.

This bundle has had no `decisions.md` since it was written on 2026-09-01. It was
closed by Revision 130 without one — option (i) was applied, and options (ii) and
(iii) were left open in prose. Reopening it is what surfaced that the closing
decision was never recorded anywhere a reader could find it.

## Decisions

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | — | F1 | — | not yet decided |

## D1 — how `docs/` is checked, if at all

Four options. **None is chosen; this is the owner's.** The measurement they rest
on is in `findings.md` and is not repeated.

### (i) Keep the prune — what is in place today

`docs/` is not scanned. The OK total is stable against parked notes.

**Costs.** Ten MISSING and two ANCHOR BROKEN stay invisible, three of the ten
being genuinely stale citations and both anchors being self-references inside
architecture records. Every future one is invisible too. The exclusion's stated
reason has been false since Revision 162, so the comment at
`bin/verify-doc-paths.sh:174` would have to be rewritten to say something true —
which is the argument against, stated plainly: there is no longer a reason to
give.

### (ii) Scan `docs/` and report it as a second total

Two OK totals, one stable and one that moves.

**Costs.** More code in a lint nobody asked to grow, and two baselines quoted in
every manifest entry. It does not touch the seven false positives — they appear
under the second total every run.

### (iii) Scan everything, and stop quoting `OK` — the option open since 2026-09-01

One total, explicitly not a baseline. `MISSING` and `ANCHOR BROKEN` are the rows
that mean anything and both are already required by the conformant prompt.

**Costs.** **Seven standing false positives**, every run, forever. That is the
objection `0037` D6 made in another context and it holds here: a reader who
learns to ignore seven MISSING lines is a reader who will ignore the eighth. It
is nearly free to adopt and it makes the check less trustworthy, not more.

### (iv) Scan `docs/`, and let a reading say a path is proposed

The option the measurement points at, and the only one that separates the two
defects instead of trading them.

A path a reading *proposes* is not a broken citation. Two shapes:

- **A marker in the document** — `` `bin/verify-index-tables.sh` (proposed) `` —
  which the checker skips. Explicit, costs a convention, and every existing
  instance has to be marked.
- **The checker demotes MISSING to WARN inside `docs/*-findings/` and
  `docs/ideas/`**, where proposing is the point, and leaves MISSING as MISSING
  everywhere else under `docs/`. No new convention, no retrofit, and it is wrong
  in exactly one direction: a genuinely stale citation inside a findings bundle
  reads as WARN rather than MISSING.

Under either shape, **MISSING under `docs/` today would be 3, not 10**, and all
three are in one file.

**Costs.** Real work in the checker rather than a flag, and the second shape
guesses from a directory name what the first shape states outright.

### What is not in scope here

The three stale citations and the two broken anchors are corrections, not
findings, and they belong to whoever owns those files. `0041` finding 3's
question — whether a bundle whose fix is a lint belongs in this tree — reaches
this bundle too, and is not answered here.
