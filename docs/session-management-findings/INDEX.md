# Session management findings

Findings about how sessions and findings bundles work — the statuses, the states,
the rules binding them, the instruction set that carries those rules, and the
checks that hold them. **Not the reimaging workflow.** A defect in
`bin/reindex-artifact-runs.sh` is cross-cutting; a defect in the rule that says
when a session may edit it is here.

The line against the other two trees:

| Tree | Subject | Fix lands in |
|---|---|---|
| `docs/runbook-findings/` | one runbook, its scripts and its artifacts | that runbook and what it owns |
| `docs/cross-cutting-findings/` | the toolkit's shared machinery — recorders, the run index, the lints, the artifact layout | `bin/`, `.internal/`, the shared config |
| `docs/instruction-set-findings/` | the rules a session follows when working the toolkit | `.github/toolkit-instructions.md` |
| **`docs/session-management-findings/`** | **how sessions and findings bundles themselves work** | **`.github/session-management-instructions.md`, `docs/legend.md`** |

This tree replaced `docs/session-management-findings/` on 2026-09-06 and absorbed
three bundles from `docs/cross-cutting-findings/`. The earlier tree drew its line
at *the instruction set*, which was too narrow: the statuses, the states and the
checks that enforce them are the same subject and were scattered across two
trees.

Numbering is one sequence shared with both other trees, so a finding number names
a bundle without needing its tree.

Statuses and states are defined in [`docs/legend.md`](../legend.md).

## Findings Bundles

| # | Bundle | Subject | Findings | Status | Session | Notes |
|---:|---|---|---:|---|---|---|
| 0026 | [0026-verify-doc-paths-counts-gitignored-docs](0026-verify-doc-paths-counts-gitignored-docs/) | `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold | 1 | `unclaimed` | — | Reopened 2026-09-06. Its exclusion rests on a reason false since Revision 162; every link under `docs/` is unverified. Option (iii) still undecided |
| 0027 | [0027-findings-architecture-conformance](0027-findings-architecture-conformance/) | The findings-and-sessions architecture disagrees with itself and with the tree | 7 | `unclaimed` | — | Reopened 2026-09-06 for the ground-up re-evaluation |
| 0028 | [0028-sessions-write-into-the-tree-the-owner-commits-from](0028-sessions-write-into-the-tree-the-owner-commits-from/) | Sessions compose their changes in the tree the owner commits from | 6 | `unclaimed` | — | Reopened 2026-09-06 for the ground-up re-evaluation |
| 0029 | [0029-the-instruction-set-lags-the-rules-it-governs](0029-the-instruction-set-lags-the-rules-it-governs/) | The instruction set lags the rules it governs | 8 | `unclaimed` | — | 7 findings `decided`, finding 8 never decided. Parked for the ground-up re-evaluation |
| 0031 | [0031-superseding-a-bundle-whose-session-is-gone](0031-superseding-a-bundle-whose-session-is-gone/) | Superseding a bundle whose session is gone is instructed but never defined | 4 | `unclaimed` | — | Reopened 2026-09-06. Its rows read `in progress` on a `resolved` bundle — the Revision 197 defect |
| 0032 | [0032-index-and-manifest-tables-have-a-shape-nothing-checks](0032-index-and-manifest-tables-have-a-shape-nothing-checks/) | The index and manifest tables have a shape nothing checks | 4 | `unclaimed` | — | Reopened 2026-09-06. Its rows read `unresolved` on a `resolved` bundle — the Revision 197 defect |

**6 bundles · 30 findings.** Every one is `unclaimed`: parked and closed to every
session until the owner assigns them to the session that will re-evaluate them.
