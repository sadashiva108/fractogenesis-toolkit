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
| `superseded` | A later bundle replaces this reading — including a bundle overtaken while `in progress`. The row names which; the replacement carries `Relates to`. |

A bundle advances with its first finding and reaches `resolved` only with its
last. The owner may override any rule; a revision carrying an overridden change
says so. Full definitions, the transitions and the write rules:
[`docs/legend.md`](../legend.md).

## Bundles

| # | Bundle | Subject | Findings | Status | Session | Notes |
|---:|---|---|---:|---|---|---|
| 0029 | [0029-the-instruction-set-lags-the-rules-it-governs](0029-the-instruction-set-lags-the-rules-it-governs/) | The instruction set lags the rules it governs | 6 | `unresolved` | [`restore-apps-outstanding-20260903-000000`](../sessions/restore-apps-outstanding-20260903-000000/) | Every rule written into `docs/legend.md` since Revision 169 is absent from or duplicated in §§4b–4d |
