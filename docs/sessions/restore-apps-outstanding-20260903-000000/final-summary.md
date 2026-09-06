# Final summary — `restore-apps-outstanding-20260903-000000`

**Session:** Claude, `session_016EbjB7M527qEFqZFzpv2C9`, 2026-09-03 to 2026-09-06  
**State:** `closed`  
**Revisions:** 160–166, 168–169, 172, 174, 177–182, 198–204

## Every bundle this session owned, and its disposal

| # | Bundle | Disposal |
|---:|---|---|
| 0001 | [`0001-restore-repos-evidence`](../../runbook-findings/restore-apps/0001-restore-repos-evidence/) | **Released to `unclaimed`** on closing, undecided |
| 0027 | [`0027-findings-architecture-conformance`](../../cross-cutting-findings/0027-findings-architecture-conformance/) | `resolved` 2026-09-04, then `superseded` by `0037` on 2026-09-06 |
| 0028 | [`0028-sessions-write-into-the-tree-the-owner-commits-from`](../../cross-cutting-findings/0028-sessions-write-into-the-tree-the-owner-commits-from/) | `resolved` 2026-09-04, then `superseded` by `0038` on 2026-09-06 |
| 0029 | [`0029-the-instruction-set-lags-the-rules-it-governs`](../../instruction-set-findings/0029-the-instruction-set-lags-the-rules-it-governs/) | 7 of 8 findings `decided`; `superseded` by `0039` on 2026-09-06 |

It also **recorded** `0033` and `0042` without owning either. Both are
`unclaimed`.

## `0001` is released, not finished

Ten findings. **F1 is answered** — `decisions.md` records D1 through D6 against
it with nothing outstanding. **The other nine were never read.** The bundle is
`analyzing` no longer; it is `unclaimed`, parked and closed to every session
until the owner assigns it.

**One question is left open on it deliberately.** F1's row reads `framing`, and
its own prose says nothing about it is still open — which under the current
vocabulary is `decided`. Moving a finding to `decided` is the owner's act, the
owner was asked and did not answer, and this session did not move it. Whoever
takes the bundle should settle that first, because the bundle's derived status
depends on it.

`0009`'s single finding carries `un-started`, which understates a reading that
did happen. It was recorded during Revision 202 and is also unanswered.

## What this session actually did

It began on eight parked items and `restore-apps.md`, and became a session about
how findings and sessions are recorded at all.

**The status model was rebuilt** (Revisions 198–200): a finding carries the
status, a bundle *derives* it by an ordered ladder, `transferred` joins the model,
and the instruction set split into a project-agnostic session-management half and
a toolkit half.

**The conformed files got a schema and then had to earn it** (Revisions 201–203).
Header fields, table shapes, `F1`/`D1` numbering — written in 201, and then
corrected twice, because the schema was verified by reading the source and the
defects were only visible on the rendered page. Along the way the retrofit's own
damage was found and repaired: fourteen wrong cells in a `Findings` column that
had been *derived* by taking the last number out of a heading, sixty-one rows
carrying a sentence that belonged to another table, and `0001`'s own Decisions
table holding three of its six decisions.

**That gap is now a bundle** (Revision 204). `0042` records that no check reads
the rendered page, that three consecutive revisions shipped defects of exactly
that kind while all six checkers passed, and that fixing it is a dependency
decision the owner has not been asked for.

## What is owed, and by whom

Not this session's to close, but written down so it is not lost.

- **`0042` F3** — whether a rendering check belongs in `bin/`. A CommonMark
  parser is a dependency this repository does not have. Four options, none
  costed.
- **The rollup in `docs/runbook-findings/INDEX.md` has 27 unchecked derived
  figures.** Added in Revision 190 by this session, reconciled by hand, and
  `verify-findings-counts.sh` still has no rule for them. **This session's unpaid
  debt.**
- **`0039` finding 8** — the composition rule says *where* a change is composed
  and never said *when* it is handed over. Undecided, and the reason `0029` never
  closed.
- **`/bin/bash -n` under real macOS Bash 3.2** is owed for Revisions 116 onward.
  Every check this session ran was on Linux with Bash 5.1 and GNU coreutils.
  `verify-script-portability.sh` catches what `bash -n` cannot see; neither
  substitutes for the other, and only one of them has been run.
- **`0041` finding 3 and `0039` D3 disagree** on how a bundle is classified:
  *classify by subject* against §4c's *where the fix lands*.

## The one thing worth carrying forward

Three revisions in a row, this session verified its work by reading the source
and shipped a defect visible in the rendered page. The checkers grew from 205
assertions to 887 across those revisions and did not catch any of the three.
**Every one was found by the owner opening the file.**

That is `0042`, and it is the finding this session would most want its successor
to read first.
