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
| D1 | The coverage sweep derives its roots from `docs/INDEX.md` instead of keeping a second copy, and reports the repository-root runbooks and `references/` explicitly | F5 | 2026-09-09 | `accepted` |

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
