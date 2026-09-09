# Decisions — instruments that cannot fire, and one that unmakes the record

**Bundle:** `0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record`  
**Session:** `assurance-coverage-20260908-204724`  
**Decided:** 2026-09-09

Assigned by the owner on 2026-09-09 and read on assignment. **Only F5 is decided
here.** F1 through F4 are `framing` and stay there: F1's remedy is already
decided as `0049` D4, F2 and F3 are one-line repairs waiting on a bundle type
that can hold a build, and F4 is a class whose members are still arriving.

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | The coverage sweep derives its roots from `docs/INDEX.md` instead of keeping a second copy, and reports the repository-root runbooks and `references/` explicitly | F5 | 2026-09-09 | `replaced → D2` |
| D2 | Derive the roots, **default in and explicitly out**: a directory in `docs/INDEX.md` is swept from the moment it appears, and excluding one is a declaration in `doc-currency.json` carrying its reason | F5 | 2026-09-09 | `accepted` |

---

## D1 — take the list from the file that owns it

`docs/INDEX.md` is authoritative for the directories under `docs/`. It already
lists `rules/`. `doc_currency.py:104` keeps a parallel list in code and that copy
went stale the day Revision 249 created the directory.

**The fix is to stop keeping the copy**, not to add `docs/rules` to it. Adding
the missing entry repairs today's instance and leaves the mechanism that produced
it, which is the retrofit error `0044` D1 names: a defect class whose only remedy
is attention has been repaired twice and grew both times.

**What the sweep walks, after:** every directory `docs/INDEX.md` lists, plus
`.claude/` and `.github/` — which `docs/INDEX.md` does not govern and which must
stay named explicitly — plus `references/` and the repository-root runbooks,
which are the toolkit's own documents and have no index that owns them.

**The false positive, measured before proposing it.** On the tree at Revision
253 this takes the reported unwatched count from **21 to 64** in one step: 43
files that have never been watched appear at once, and every one is a true
positive by construction — none is watched, which is precisely what the report
says. **It will read as a regression and is not one.** That is `0047` F5's shape
— an instrument whose first honest run looks like a failure — and the mitigation
is not to soften the number but to say in the same revision that the number moved
because the instrument stopped lying, not because the tree got worse.

**Rejected: watching the 43 as part of this decision.** Coverage and watching are
different acts, and F3 of `0053` is the one that decides what gets a watch.
Conflating them would mean choosing 43 watches to make a number look better,
which is how a coverage report becomes decoration.

**Rejected: failing the run on a non-empty coverage list.** `0041` D1 argues that
an undeclared remainder must fail rather than inform, and this is the case where
that rule does not yet apply: with 64 unwatched and no way to declare one out
deliberately, the check would fail permanently from its first run. **The
declaration mechanism has to exist first** — a way to mark a file *watched by
nobody, on purpose* — and it does not. Recorded so the gap is deliberate rather
than an omission, and so `0041` D1 is not quoted as satisfied here.

## D2 — default in, explicitly out, and the records are declared out with a reason

**D1 was under-specified and implementing it found the gap**, which is what
implementing a decision is for. Its prose says *every directory `docs/INDEX.md`
lists*. Taken literally that sweeps `docs/runbook-findings/`,
`docs/cross-cutting-findings/`, `docs/instruction-set-findings/`,
`docs/session-management-findings/` and `docs/sessions/` — **179 files, of which
157 are findings and session records.**

**Those are evidence.** A `findings.md` is a reading taken at a moment; a
handoff records what a session held and when. The standing constraint is that
evidence is never rewritten to match a later rule, and §9 spends three
prohibitions keeping a superseded reading exactly as it was. **A staleness report
over them would be asking for precisely the retrofit that is forbidden**, and it
would bury the 22 documents that can go stale under 157 that cannot.

D1's own false-positive estimate said the count would go 21 → 64, which is the
*correct* reading. **The prose and the measurement in one decision disagreed**,
and the prose was wrong.

### The rule D2 states

**Roots are derived from `docs/INDEX.md`**, which owns the directory list, plus
what that file does not govern — `.claude/`, `.github/`, `references/` — and the
repository-root runbooks, which belong to no index.

**Exclusion is a declaration, not a rule in code.** `doc-currency.json` gains a
`coverage` block naming the five excluded paths, each with its reason. A
directory added to `docs/INDEX.md` is **swept from the moment it appears**;
keeping it out takes a deliberate line in a file a reader opens.

That inverts the failure direction. Before, a new directory was silently
invisible — which is how `docs/rules/` was missed for four revisions. After, a
new directory is noisy until somebody declares it out. **`0041` D1's rule
exactly: the undeclared remainder is visible, and declaring something out is
deliberate.**

**Rejected: inferring the split from `docs/INDEX.md`'s Index column.** It
correlates perfectly today — the four findings trees and `sessions/` carry an
index link, the four description directories carry `—`. It is still an
inference, and `doc_currency.py`'s own docstring is the argument against it:
*"an inferred edge is how a checker tells one project's game engine that another
project's intake docs need updating."* A correlation that holds today is not a
declaration.

**Rejected: hard-coding the exclusions in the script.** That is the defect being
fixed, moved one line down.

### Measured, after

**21 → 62 unwatched.** Not the 64 D1 predicted, and the two are accounted for:
`README.md` is a dependent in two watches so it was never unwatched, and
`APPLY-MANIFEST.md` was already in the 21 as a named file rather than arriving
with the root sweep. **The estimate was high by two and the difference is
explainable**, which is the only reason to state a prediction before measuring.

`docs/rules/rule-enforcement-avenues.md` and all eleven `references/` documents
now appear. The run prints what it swept and what was declared out, so the
number can be read without opening the config.

