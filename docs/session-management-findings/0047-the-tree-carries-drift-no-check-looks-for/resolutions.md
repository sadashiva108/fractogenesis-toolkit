# Resolutions — the tree carries status drift that no check looks for

**Bundle:** `0047-the-tree-carries-drift-no-check-looks-for`  
**Session:** `typed-bundles-architecture-20260908-204724`  
**Resolved:** 2026-09-09

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F1 | D10 | `CLOSED-BUNDLE-LIVE-FINDING` removed; `unclaimed` joins the counted ordering exemptions. Revision 287 dissolved the premise — the legend no longer says an unclaimed bundle is unreadable — so this is a removal rather than a repair | 295 | — |
| F2 | D10 | Nothing repaired. The six accepted decisions in `0001` could not have moved its F1: `decided` is the owner's act and `0001` has no owner, so what F2 recorded as drift is the only state the rules permit | 295 | — |
| F3 | D11 | Answered with no instrument change. Of the three bundles F3 named, `0036` cleared itself when its F1 reached `resolved` and `0030` is inside the clone exemption; `0035` alone still reports, and its three rows are a true positive its live owner may clear. The cause — closure recorded in the session and not in the members — is F13 | 298 | — |
| F4 | D1 | The carve-out is in `.github/session-management-instructions.md` §3 again, naming the class and why writing decisions into it would be worse than the gap | 255 | — |
| F5 | D4 | Nothing, by decision. `is_clone()` exempted superseding clones from both ordering comparisons at Revision 231 and the finding was never moved. The sixty-five this finding named are gone: the two comparisons report **15** rows at Revision 263, and `0030` — one of the three bundles F3 lists — is among the ones that went, being a clone of `0009`. The row records the revision that did the work, not the one that noticed | 231 | `c1da011` |
| F6 | D7 | `.github/session-management-instructions.md` §6 gains the warn-only rule for anything that refuses a write, in both directions — shown not to fire on correct work **and** shown to fire on a case it should catch — with the three clauses `0047` F9, Revision 278 and the never-quote-`OK` rule supply | 280 | — |
| F7 | D2 | `plan_findings_work.py` no longer reports a `transferred` bundle under `CLOSED-BUNDLE-LIVE-FINDING`; the `unclaimed` half stays and its detail names `0047` F1 as undecided. `test_transferred_is_treated_the_same` is replaced by `test_a_transferred_bundle_may_hold_worked_findings` over three standings, and `test_0047_F7_a_transfer_of_worked_findings_is_not_a_failure` reproduces Revision 248's twenty-three-finding transfer | 268 | — |
| F8 | D3 | `OUTCOMES` is the legend's six bare values with `replaced` matched by prefix, and the two retired prefixes are gone. Two contract tests replaced, two regressions added, and `test_outcomes_and_statuses_share_no_word` is the disjointness assertion `docs/legend.md` has claimed since Revision 233 and nothing performed | 268 | — |
| F9 | D8 | A `superseded` bundle is exempt from both ordering comparisons — 8 rows in `0031` and `0032` — and `check` now counts both exemptions and names their bundles instead of asserting one in a footer. `check` 43 → 35 | 281 | — |
| F10 | D9 | The clone exemption is per member and lapses when the member leaves `un-started`/`framing`; `reopened` is exempt from the resolution comparison in every bundle, because nothing is reverted when a member is reopened. The two comparisons move into one `ordering_hits()` read by the reporter and the counter | 281 | — |
| F11 | D5 | `VOCABULARIES` and `DECLARED_OVERLAPS` replace three hand-listed comparisons with every pair of every closed set, `SESSION_STATES` is added and `conformance` reports `VOCAB` on a session state outside it, and the one unowned pair is excluded by a named constant and asserted separately under `expectedFailure`. Suite 64 → 68, `OK (expected failures=1)` | 272 | — |
| F12 | D6 | `.share/check-manifest-revision.sh` scans the commit log as a third place and takes the highest of the three, degrading to the file's two places where git is unavailable; `bin/verify-manifest-coverage.sh` is new and reports `MISSING` / `ORPHANED` / `DUPLICATE` against the log, failing only on `MISSING` | 278 | — |

**One of twelve members remains live: F3, `un-started`.** F1 and F2 were
resolved at Revision 295, once Revision 287 supplied the ruling they were parked
behind. They are the drift the tree already carries, and they are parked behind
the entity model at the owner's direction — the retrofit they point at should not
begin until the state format lands, and F1's question is what an `unclaimed`
bundle may hold, which is a vocabulary ruling rather than an instrument one.
**F1 has grown while it waited**: one live instance at Revision 267, **33 across
eight bundles** at Revision 270, after the assurance session closed and released
seven.

**The other nine are `resolved`, and eight of the nine were defects in the
instruments rather than in the tree.** F4 at Revision 255; F5 against Revision
231, which shipped its remedy and never moved the finding; F7 and F8 at 268; F11
at 272; F12 at 278; F6 at 280; F9 and F10 here. **`check` has gone from 52
conformance rows to 35 across those six revisions, and not one row was cleared by
editing a record** — every one was an instrument reporting something that was not
true, or reporting something nobody was permitted to act on.

**The revision on each row is the one that did the work, not the one that
noticed.** F5's names Revision 231 and commit `c1da011`; the rest name their own.

**The revision was re-taken at apply time.** This work was composed against
Revision 263 and the checkout was at 267 when the owner called for it, so the
number went from 264 to 268 and the three tables carrying it were corrected
before the patch was rebuilt.
