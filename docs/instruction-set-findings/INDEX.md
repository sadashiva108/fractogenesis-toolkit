# Instruction set findings

Findings about **the toolkit's instruction set** — the rules a session follows
when it works on the reimaging workflow, and the prompts and templates that carry
them. The fix lands in
[`.github/toolkit-instructions.md`](../../.github/toolkit-instructions.md) or in
the authoring prompts and templates beside it.

**Not the rules about sessions and findings bundles.** Those are the same kind of
thing one level up, and they have their own tree: a finding whose fix lands in
`.github/session-management-instructions.md` belongs in
[`docs/session-management-findings/`](../session-management-findings/INDEX.md).
The two instruction sets were one file until Revision 191, which is why findings
about them were one tree until 2026-09-06.

The line against the other three:

| Tree | Subject | Fix lands in |
|---|---|---|
| `docs/runbook-findings/` | one runbook, its scripts and its artifacts | that runbook and what it owns |
| `docs/cross-cutting-findings/` | the toolkit's shared machinery — recorders, the run index, the lints, the artifact layout | `bin/`, `.internal/`, the shared config |
| **`docs/instruction-set-findings/`** | **the rules a session follows when working the toolkit** | **`.github/toolkit-instructions.md`** |
| `docs/session-management-findings/` | how sessions and findings bundles themselves work | `.github/session-management-instructions.md`, `docs/legend.md` |

Numbering is one sequence shared across all four, so a finding number names a
bundle without needing its tree.

Statuses and states are defined in [`docs/legend.md`](../legend.md).

## Findings Bundles

| # | Bundle | Subject | Findings | Standing | Session | Notes |
|---:|---|---|---:|---|---|---|
| 0029 | [0029-the-instruction-set-lags-the-rules-it-governs](0029-the-instruction-set-lags-the-rules-it-governs/) | The instruction set lags the rules it governs | 8 | [`superseded`](../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | [`restore-apps-outstanding-20260903-000000`](../sessions/restore-apps-outstanding-20260903-000000/) | Superseded 2026-09-06 by `0039` for the ground-up re-evaluation. Reading retained here unchanged, brought onto the schema in Revision 203; still held by this session |
| 0031 | [0031-superseding-a-bundle-whose-session-is-gone](0031-superseding-a-bundle-whose-session-is-gone/) | Superseding a bundle whose session is gone is instructed but never defined | 4 | [`superseded`](../session-management-findings/0040-superseding-a-bundle-whose-session-is-gone/) | [`pre-image-capture-conformance-20260903-194532`](../sessions/pre-image-capture-conformance-20260903-194532/) | Superseded 2026-09-06 by `0040` for the ground-up re-evaluation. Reading retained here unchanged, brought onto the schema in Revision 203; still held by this session |
| 0032 | [0032-index-and-manifest-tables-have-a-shape-nothing-checks](0032-index-and-manifest-tables-have-a-shape-nothing-checks/) | The index and manifest tables have a shape nothing checks | 4 | [`superseded`](../session-management-findings/0041-index-and-manifest-tables-have-a-shape-nothing-checks/) | [`pre-image-capture-conformance-20260903-194532`](../sessions/pre-image-capture-conformance-20260903-194532/) | Superseded 2026-09-06 by `0041` for the ground-up re-evaluation. Reading retained here unchanged, brought onto the schema in Revision 203; still held by this session |
