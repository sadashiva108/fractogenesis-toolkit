# Resolutions — the instruction set lags the rules it governs

**Bundle:** `0039-the-instruction-set-lags-the-rules-it-governs`  
**Session:** `session-management-re-evaluation-20260906-110105` (`session_01FhFbEgG4wmrtJqUCcryNVQ`)  
**Decisions:** `decisions.md`, seventeen across sixteen findings.

Four findings are closed. The reasoning is in `decisions.md` and is not repeated;
this file records what was actually done.

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F7 | D5 | Ordering became a typed, directed edge, stored in the asserting bundle and carried in `metadata.json` | 222 | `42d08a4` |
| F12 | D7, D8, D9, D10, D11, D12 | Every transition in `docs/legend.md` names its triggering event; the reason, outcome and provenance vocabularies are defined; §9 gains the provenance gate and §9a the reopen and withdraw procedures | 221, 223 | `b09a69d`, `5ad7304` |
| F15 | D15 | A decision must cite at least one `F<n>`, checked in `verify-findings-headers.sh` | 224 | `44c5289` |
| F16 | D16, D17 | A `completeness` check joined the verify group, and the extractor refuses to run once the markdown is a projection | 225 | `44c5289` |
| F19 | D19 | The record is scoped to this repository and `foreign` named as a fourth write kind, in §6 and the legend | 227 | *(taken at apply time)* |

---

## What changed

**`docs/legend.md`** — the lifecycle diagram labels every arrow with the **event**
that causes it, and states that assignment, sweeps, renames, retrofits and
readings move nothing (D7). Three reason tables, seven decision outcomes and five
provenance edge kinds are defined (D8–D12). The file lost 76 lines to §9's
procedure sections and holds vocabulary only.

**`.github/session-management-instructions.md`** — §9 gains *Provenance, and the
gate on the tag*, with coverage and exclusivity refusing the `superseded` tag
until every predecessor finding is accounted for. §9a is new: reopening takes a
reason from nine, withdrawing takes one per finding, and `reopened.md` is
generated rather than written. §6 takes the write gating that D2 assigned to it in
2026-09-04 and never received.

**`bin/verify-session-findings.sh`** — one callsite for the framework's own
checks, with the three findings checkers moved to
`.internal/ai-scripts/session-management/` and the revision ledger to `.share/`.

**`.internal/ai-scripts/session-management/verify-findings-headers.sh`** — a
decision row with no `F<n>` now fails (D15). The check that existed asked whether
every citation resolved, which is vacuously true of a row with none.

**`.internal/ai-scripts/session-management/extract-metadata.py`** — `--check`
asserts completeness rather than well-formedness (D16), and a one-way guard
refuses extraction once any generated-region marker exists (D17).

## F7 — ordering, and where the resolution actually came from

D4 said *say it in prose inside `Relates to`*; D5 replaced it with a typed edge.
**The edge contract was not this bundle's work** — it was settled as `0043` D1
between this session and `allocation-and-inquiry-design-20260906-233205`, with the
owner relaying, and recorded at Revision 215. What closes F7 here is that the
edges now **exist as data**: 31 of them across six bundles in `metadata.json`,
derived rather than asserted.

## What was NOT done, and is owed

**F8 stays `decided`.** D6 — the hand-over step joining §6's composition rule — is
accepted and **not installed**. It is a toolkit write and belongs to whoever works
this bundle next. It is the only decided finding here whose work has not been
carried out.

**Eleven findings remain `framing`**, including F13 and F14, which were recorded
unanswered on purpose: whether the vocabulary file is renamed into
`docs/reference/` — sixty-three citations, a `0030`-class change — and whether a
README and quick-start exist for a reader arriving cold.

**The standing baseline D15 created is not cleared.** The check reports rows in
`0005`, `0012`, `0013`, `0025`, `0030` and `0035`, all owned by
`run-index-design-20260901-000000` and
`pre-image-capture-conformance-20260903-194532`. One table cell each, and not this
session's to edit. Ten further rows in `0031` and `0032` are frozen and exempt.

**Nothing ran on macOS.** Five shell scripts and one Python helper have new
self-location lines at depths they have never been executed at. `/bin/bash -n`
against real Bash 3.2 is owed for these and for Revisions 116 onward.

## The instruments, recorded because the pattern is now a law

Every check written or changed while resolving these four **failed loudly against
a healthy tree on its first run**: the completeness check at 18 false positives on
prose fields whose schema amendment it had not read; the one-way guard refusing
because `state-as-data.md` documents its own marker inside a fenced example; D15's
check at 40 hits of which 10 were frozen and 20 derivable. With `0041`'s lint,
`0042` F4's audit at 128-of-131 and the parallel session's sweep at 65-of-77, that
is seven. **The half that reads is wrong; the half that judges is fine.**
