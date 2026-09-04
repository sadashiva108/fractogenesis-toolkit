# Instruction-set findings

Findings whose subject is **the rules a session works under**, rather than the
workflow those rules produce: `.github/copilot-instructions.md`,
`.claude/CLAUDE.md`, `.github/ai-prompts/`, `.github/ai-templates/`,
`.github/guides/`, and `docs/legend.md` while it carries rules the instruction
set has not yet adopted.

The line against the other two trees:

| Tree | Subject |
|---|---|
| `docs/runbook-findings/<runbook>/` | one runbook, its scripts and its artifacts |
| `docs/cross-cutting-findings/` | the workflow's shared machinery — recorders, the run index, the lints, the artifact layout |
| **`docs/instruction-set-findings/`** | **how a session is told to work at all** |

A defect in `bin/reindex-artifact-runs.sh` is cross-cutting; a defect in the rule
that says when a session may edit it is here. The test is the same one the other
two use: where the ramifications are functionally felt.

Numbering is one sequence shared with both other trees, so a finding number names
a bundle without needing its tree.

## Status key

| | |
|---|---|
| `unresolved` | Recorded. No decisions yet. **Any session may add, correct or remove findings here.** |
| `in progress` | The owner is reviewing and deciding. Produces `decisions.md`. **Only the owner writes from here on.** |
| `resolving` | Every finding decided; the decided work is being carried out. Produces `resolutions.md`. |
| `resolved` | Every finding has a resolution recorded. |
| `superseded` | A later findings bundle replaces this reading — including one overtaken while `in progress`. The row names which. |
| `withdrawn` | The reading is dropped and nothing replaces it. The row says why. |

A bundle advances with its first finding and reaches `resolved` only with its
last. The owner may override any rule; a revision carrying an overridden change
says so. Full definitions, the transitions and the write rules:
[`docs/legend.md`](../legend.md).

## Findings Bundles

| # | Bundle | Subject | Findings | Status | Session | Notes |
|---:|---|---|---:|---|---|---|
| 0029 | [0029-the-instruction-set-lags-the-rules-it-governs](0029-the-instruction-set-lags-the-rules-it-governs/) | The instruction set lags the rules it governs | 8 | `unresolved` | [`restore-apps-outstanding-20260903-000000`](../sessions/restore-apps-outstanding-20260903-000000/) | Every rule written into `docs/legend.md` since Revision 169 is absent from or duplicated in §§4b–4d |
| 0031 | [0031-superseding-a-bundle-whose-session-is-gone](0031-superseding-a-bundle-whose-session-is-gone/) | Superseding a bundle whose session is gone is instructed but never defined | 4 | `resolved` | [`pre-image-capture-conformance-20260903-194532`](../sessions/pre-image-capture-conformance-20260903-194532/) | closed by this revision; §4c gains the procedure |
| 0032 | [0032-index-and-manifest-tables-have-a-shape-nothing-checks](0032-index-and-manifest-tables-have-a-shape-nothing-checks/) | The index and manifest tables have a shape nothing checks | 3 | `unresolved` | [`pre-image-capture-conformance-20260903-194532`](../sessions/pre-image-capture-conformance-20260903-194532/) | tree placement is its own finding 3 |
