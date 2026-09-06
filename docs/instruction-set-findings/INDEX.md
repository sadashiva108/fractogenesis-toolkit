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

| # | Bundle | Subject | Findings | Status | Session | Notes |
|---:|---|---|---:|---|---|---|

**0 bundles · 0 findings.** The tree's three original bundles — `0029`, `0031`
and `0032` — moved to `docs/session-management-findings/` on 2026-09-06, because
all three were about sessions and bundles rather than the workflow. The tree is
kept for what it was named for: findings about the toolkit's own instruction set,
which had nowhere else to go and still does not.
