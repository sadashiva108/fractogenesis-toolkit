# Resolutions — the tree carries status drift that no check looks for

**Bundle:** `0047-the-tree-carries-drift-no-check-looks-for`  
**Session:** `typed-bundles-architecture-20260908-204724`  
**Resolved:** 2026-09-09

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F4 | D1 | The carve-out is in `.github/session-management-instructions.md` §3 again, naming the class and why writing decisions into it would be worse than the gap | 255 | — |
| F5 | D4 | Nothing, by decision. `is_clone()` exempted superseding clones from both ordering comparisons at Revision 231 and the finding was never moved. The sixty-five this finding named are gone: the two comparisons report **15** rows at Revision 263, and `0030` — one of the three bundles F3 lists — is among the ones that went, being a clone of `0009`. The row records the revision that did the work, not the one that noticed | 231 | `c1da011` |
| F6 | D7 | `.github/session-management-instructions.md` §6 gains the warn-only rule for anything that refuses a write, in both directions — shown not to fire on correct work **and** shown to fire on a case it should catch — with the three clauses `0047` F9, Revision 278 and the never-quote-`OK` rule supply | 280 | — |
| F7 | D2 | `plan_findings_work.py` no longer reports a `transferred` bundle under `CLOSED-BUNDLE-LIVE-FINDING`; the `unclaimed` half stays and its detail names `0047` F1 as undecided. `test_transferred_is_treated_the_same` is replaced by `test_a_transferred_bundle_may_hold_worked_findings` over three standings, and `test_0047_F7_a_transfer_of_worked_findings_is_not_a_failure` reproduces Revision 248's twenty-three-finding transfer | 268 | — |
| F8 | D3 | `OUTCOMES` is the legend's six bare values with `replaced` matched by prefix, and the two retired prefixes are gone. Two contract tests replaced, two regressions added, and `test_outcomes_and_statuses_share_no_word` is the disjointness assertion `docs/legend.md` has claimed since Revision 233 and nothing performed | 268 | — |
| F11 | D5 | `VOCABULARIES` and `DECLARED_OVERLAPS` replace three hand-listed comparisons with every pair of every closed set, `SESSION_STATES` is added and `conformance` reports `VOCAB` on a session state outside it, and the one unowned pair is excluded by a named constant and asserted separately under `expectedFailure`. Suite 64 → 68, `OK (expected failures=1)` | 272 | — |
| F12 | D6 | `.share/check-manifest-revision.sh` scans the commit log as a third place and takes the highest of the three, degrading to the file's two places where git is unavailable; `bin/verify-manifest-coverage.sh` is new and reports `MISSING` / `ORPHANED` / `DUPLICATE` against the log, failing only on `MISSING` | 278 | — |

F1, F2 and F3 are untouched and remain `un-started`; F9 and F10 stand `framing`; **F12 was recorded at
Revision 272 and stands `framing`, deliberately undecided** — reading the git log
to find a number taken there is a different instrument from reading a file, and
which wins when they disagree is what F12 owes. F6 was
written to at Revision 255 and stands `framing`; F9 and F10 were recorded at
Revision 268 and stand `framing`.

**F7 and F8 are one change to one file and two decisions, so they are two rows.**
`check` goes from **52** conformance findings to **43**: five
`CLOSED-BUNDLE-LIVE-FINDING` rows clear, one per bundle Revision 261 transferred,
and four `VOCAB` rows on `replaced → DX` clear. The suite goes from 48 tests to
54, all passing. **Neither number is an `OK` total** — both are failure counts,
and both were measured in the session copy against Revision 267. Every other
baseline is unmoved: `headers` 11 FAIL, runbook structure 25 FAIL, doc-paths 0
MISSING and 0 ANCHOR BROKEN, portability 0 FAIL, `stamp` writing nothing.

**The revision was re-taken at apply time.** This work was composed against
Revision 263 and the checkout was at 267 when the owner called for it, so the
number went from 264 to 268 and the three tables carrying it were corrected
before the patch was rebuilt.
