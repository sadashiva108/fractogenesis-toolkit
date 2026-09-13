# allocation-and-inquiry-design-20260906-233205 — final summary

**Closed 2026-09-13 by the owner.** Nineteen revisions, 211 through 247, across
fifteen commits.

## Disposal

**This session owned no findings bundle at any point, so there is nothing to
dispose of** — no bundle is stranded by its closing, and the rule that a session
may not end leaving a bundle owned by a session that has stopped is satisfied
vacuously rather than by work.

That is not a tidy ending. It is `0045` F1: *a session whose output is not a
findings bundle has no state that fits.* This session read `available` for its
entire life while writing three architecture records, building the allocator and
the interviewer, creating two session bundles and recording six findings bundles
it handed to others. It now reads `closed`, which is the same word a session gets
for finishing twenty findings. **The vocabulary cannot tell those apart, and this
record is the evidence.**

## What it produced

| | |
|---|---|
| Architecture | `allocation-and-inquiry.md`, `the-record-and-the-graph.md`, `typed-bundles-and-work.md` |
| Tooling | `plan-findings-work.sh` — the allocator, the interviewer, the conformance check and the stamper — plus `review-changes.sh`, `verify-doc-currency.sh`, the write-location guard, and 48 tests |
| Session bundles | `typed-bundles-architecture-20260908-204724`, `assurance-coverage-20260908-204724` |
| Findings recorded, none owned | `0044` `0045` `0046` `0047` `0048` `0049` |
| Contributions | eleven, listed in `metadata.md` |

## What it got wrong, and where each is recorded

**`0049` is this session's account of its own failure** and is the one that
matters. Seven revisions named a patch as the deliverable and produced none,
writing straight into the owner's checkout instead. The same shape recurred twice
more after the finding was recorded: Revision 237 proposed session bundles in a
prompt instead of creating them, and Revisions 241–246 wrote commit messages
instead of manifest entries — six revision numbers taken in the log that this
file's own allocator could not see, which blocked the next session from taking a
number at all. Revision 247 repaired it and recorded that no instrument compares
the numbers the log claims against the numbers the manifest allocates.

**Three further corrections, all caught by other sessions reading cold.** A false
claim written into Revision 236's manifest entry — *nothing in the tree could have
caught these* — when the `state-schema` watch existed, was correct, and had simply
never been armed. Two session bundles stamped in UTC where the rule says
America/New_York, not caught before they were committed. And a mechanical rename
at Revision 246 that broke the code, caught by the test suite this session had
built.

**The pattern across all of them is one thing**: reasoning about an instrument
instead of opening it. It is worth carrying forward.

## Owed to whoever picks it up

- **`0036` and `0043` are stranded.** Both are owned by
  `session-management-re-evaluation-20260906-110105`, which stands `handoff` with
  no successor. `run-index-design-20260901-000000` holds **eleven** more in the
  same state. Thirteen bundles owned by sessions that have stopped.
- **The granular write categories are drafted and unapplied.** The scheme keys on
  location while its own justification is about failure mode, and a bad **rule**
  write propagates in a way neither a record nor a toolkit write does. It is
  `0037`.
- **`analyzing` is overloaded.** Twelve bundles held it across five genuinely
  different situations, including one where something was decided and nothing had
  been read. The finding vocabulary distinguishes *being read* from *decided and
  outstanding*; the bundle vocabulary does not. `0039` F18 and `0037`.
- **The provenance campaign is one file of four done.** `docs/legend.md` at
  Revision 246; `session-management-instructions.md` (17 passages),
  `conformant-prompt.md` (29) and `session-management-prompt.md` (15) remain.
  The rule cuts four ways, not two — history moves, a live unsettled warning
  stays, a currency declaration stays, and **evidence for why a rule exists stays
  inline in a document read once and moves in a document that is consulted.**
- **`conformant-prompt.md:12` declares Revision 221** against a tree at 317. It
  needs an audit, not a bumped number — bumping without reading is what shipped a
  session two bundles belonging to another session.
