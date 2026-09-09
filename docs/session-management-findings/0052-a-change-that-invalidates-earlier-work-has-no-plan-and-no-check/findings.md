# A change that invalidates earlier work has neither a plan nor a check

**Recorded:** 2026-09-09, while resolving `0037` and finding its seven resolutions had been undone.  
**Session:** `typed-bundles-architecture-20260908-204724` (`session_01QvZrvKpoKwCmyLNjzXzCdQ`)  
**Severity:** F1 is high — one commit reverted seven resolved findings and no instrument noticed, in the tree whose whole purpose is that work is not lost. F2 is the owner's standing preference with nothing behind it.  
**Felt at:** commit `1c48deb`; `0037` F1–F7; the ten migrated bundles under `0037` D2  
**Scope:** session management. F1 wants a check, F2 wants a rule  
**Relates to:** `0037` — its seven findings are F1's evidence, and its D2 is why F2 exists  
**Relates to:** `0047` — F5's family: the instrument that is not there rather than the one that is wrong

**Read:**

- `docs/cross-cutting-findings/0027-findings-architecture-conformance/resolutions.md`
- `docs/session-management-findings/0037-findings-architecture-conformance/findings.md`
- `.github/session-management-instructions.md` §§7, 9, 9b
- commit `1c48deb` and commit `88aed77`

Recorded `unclaimed`. Not owned, and no session should open it until the owner
assigns it. It is recorded by a session that owns six bundles already, and
recording is not owning.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | Nothing re-verifies that a resolution still holds, and one refactor reverted seven without anything noticing | `un-started` |
| F2 | A breaking change to a record format has no migration-plan requirement, so what happens to what predates it is decided per change or not at all | `un-started` |

## F1 — a resolution is written once and never checked again

`0027` decided and resolved seven findings at commit `88aed77`. Commit
`1c48deb` then split `.github/copilot-instructions.md` into two files and
**dropped fifteen rules with no decision recording the removal** — among them the
rules five of those seven resolutions had installed.

**The seven resolutions became false and the record went on saying `resolved`.**
Nothing detected it. Not the six checkers, which read whether a document is well
formed. Not `verify-doc-currency.sh`, which watches source-to-dependent edges and
has never been armed — `0039` F22. Not a reader, until this session opened
`0027` by hand nineteen revisions later while resolving its successor.

**The general shape.** A resolution asserts *the tree now does X*. It is checked
once, at the moment it is written, by the session that wrote it. **Every later
change to the tree can falsify it and nothing looks.** `resolved` is the one
status the legend calls frozen, and freezing the record does not freeze the thing
it describes.

**Why this is not `0036`.** `0036` is a check whose scope is narrower than its
claim. This is a claim with no check at all, about the status the framework
treats as final.

**What it costs to leave.** The tree currently reads 36 findings `resolved`, and
nothing establishes that any of them still holds. **The number this bundle exists
to produce is how many are false**, and it cannot be produced by reading a
status. It needs each resolution re-read against the tree — which is the sweep
this session has proposed and not run.

## F2 — a breaking change has no migration plan

`0037` D2 restores a carve-out for ten bundles that predate the shape they are
measured against, and it is the second time this class has been handled by
noticing it late. The owner's standing preference is **retrofit and backfill
older evidence to match the current shape wherever that is possible**, and the
exception is narrow: where the missing thing records deliberation or a
measurement that never happened, inventing it is worse than the gap.

**Nothing states that preference and nothing requires the question to be asked.**
A change to a record format — the header schema, the status vocabulary, the
`metadata.json` shape — currently ships without saying what happens to what
predates it, and the answer arrives as a finding months later. Revision 162's
twenty-five converted notes, Revision 203's schema pass, Revision 224's clean
slate and `0037` D2 are four instances.

**What a migration plan would have to name**: what predates the change, whether
it is retrofitted or exempted, why, and where the exemption is written so a
checker does not report it forever. **The retrofit is the default and the
exemption is the thing that needs a reason** — which is the reverse of how all
four instances were handled.

**What this finding does not propose.** That every change carry one. A format
change does; a wording change does not, and where that line falls is what F2
owes.
