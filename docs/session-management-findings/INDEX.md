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

This tree replaced `docs/instruction-set-findings/`'s wider half on 2026-09-06 and absorbed
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
| 0036 | [0036-verify-doc-paths-counts-gitignored-docs](0036-verify-doc-paths-counts-gitignored-docs/) | `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold | 1 | `resolved` | [`session-management-re-evaluation-20260906-110105`](../sessions/session-management-re-evaluation-20260906-110105/) | Supersedes `0026`. Its exclusion rests on a reason false since Revision 162; every link under `docs/` is unverified. Original retained in its own tree, reading unchanged, brought onto the schema in Revision 203; still held by the session that had it |
| 0037 | [0037-findings-architecture-conformance](0037-findings-architecture-conformance/) | The findings-and-sessions architecture disagrees with itself and with the tree | 7 | `unclaimed` | — | Supersedes `0027`. Reopened for the ground-up re-evaluation. Original retained in its own tree, reading unchanged, brought onto the schema in Revision 203; still held by the session that had it |
| 0038 | [0038-sessions-write-into-the-tree-the-owner-commits-from](0038-sessions-write-into-the-tree-the-owner-commits-from/) | Sessions compose their changes in the tree the owner commits from | 6 | `unclaimed` | — | Supersedes `0028`. Reopened for the ground-up re-evaluation. Original retained in its own tree, reading unchanged, brought onto the schema in Revision 203; still held by the session that had it |
| 0039 | [0039-the-instruction-set-lags-the-rules-it-governs](0039-the-instruction-set-lags-the-rules-it-governs/) | The instruction set lags the rules it governs | 20 | `analyzing` | [`session-management-re-evaluation-20260906-110105`](../sessions/session-management-re-evaluation-20260906-110105/) | Supersedes `0029`. 7 findings `decided`, finding 8 never decided. Original retained in its own tree, reading unchanged, brought onto the schema in Revision 203; still held by the session that had it |
| 0040 | [0040-superseding-a-bundle-whose-session-is-gone](0040-superseding-a-bundle-whose-session-is-gone/) | Superseding a bundle whose session is gone is instructed but never defined | 4 | `unclaimed` | — | Supersedes `0031`. Its rows read `in progress` on a `resolved` bundle — the Revision 197 defect. Original retained in its own tree, reading unchanged, brought onto the schema in Revision 203; still held by the session that had it |
| 0041 | [0041-index-and-manifest-tables-have-a-shape-nothing-checks](0041-index-and-manifest-tables-have-a-shape-nothing-checks/) | The index and manifest tables have a shape nothing checks | 5 | `unclaimed` | — | Supersedes `0032`. Its rows read `unresolved` on a `resolved` bundle — the Revision 197 defect. Original retained in its own tree, reading unchanged, brought onto the schema in Revision 203; still held by the session that had it |
| 0042 | [0042-no-check-reads-the-rendered-page](0042-no-check-reads-the-rendered-page/) | No check reads the rendered page, and three revisions shipped defects that only the rendering showed | 4 | `unclaimed` | — | Recorded by `restore-apps-outstanding-20260903-000000`, which does not own it. Supersedes nothing. F3 is a dependency question and is the owner's to decide |
| 0043 | [0043-framework-state-lives-in-documents-not-data](0043-framework-state-lives-in-documents-not-data/) | The framework's own state lives in documents rather than in data | 9 | `analyzing` | [`session-management-re-evaluation-20260906-110105`](../sessions/session-management-re-evaluation-20260906-110105/) | Recorded 2026-09-07 from the owner's config proposal. **Deliberately open** — a second architecture is being designed in parallel and another session should record here rather than open a near-duplicate. Supersedes nothing |
| 0044 | [0044-citations-under-docs-resolve-nowhere-and-nothing-reads-them](0044-citations-under-docs-resolve-nowhere-and-nothing-reads-them/) | Citations under `docs/` resolve nowhere, and nothing reads them | 2 | `unclaimed` | — | Recorded 2026-09-06 by `allocation-and-inquiry-design-20260906-233205`, which does not own it. **The first demonstrated instance of `0036`** — four broken links inside the region `verify-doc-paths.sh` cannot see. Parked and closed to every session until the owner assigns it. `session-management-re-evaluation-20260906-110105` recommends it stay unassigned until the allocation demo has run against it, since assigning it removes the test |
| 0045 | [0045-a-session-whose-output-is-not-a-bundle-has-no-state](0045-a-session-whose-output-is-not-a-bundle-has-no-state/) | A session whose output is not a findings bundle has no state that fits | 2 | `unclaimed` | — | Recorded 2026-09-07 by `allocation-and-inquiry-design-20260906-233205` from its own state, which it does not own. Parked and closed to every session until the owner assigns it |
| 0046 | [0046-supersession-moves-authority-and-leaves-every-citation-behind](0046-supersession-moves-authority-and-leaves-every-citation-behind/) | Supersession moves authority and leaves every citation behind | 2 | `unclaimed` | — | Recorded 2026-09-07 by `allocation-and-inquiry-design-20260906-233205`, which does not own it. Twelve documents cite `0028`, superseded 2026-09-06. The citations are correct as written and must not be repaired, so the remedy is a marker or a check |
| 0047 | [0047-the-tree-carries-drift-no-check-looks-for](0047-the-tree-carries-drift-no-check-looks-for/) | The tree carries status drift that no check looks for | 5 | `unclaimed` | — | Recorded 2026-09-07 by `allocation-and-inquiry-design-20260906-233205`, which does not own it. The inventory behind the retrofit. **F5 is the instrument's own defect** — 65 of its 77 first-run hits are correct by construction. The retrofit waits on `state-as-data.md` |
| 0048 | [0048-the-session-capacity-limit-has-no-datum](0048-the-session-capacity-limit-has-no-datum/) | The session capacity limit has no datum, and its only proxy points the wrong way | 3 | `unclaimed` | — | Recorded 2026-09-08 by `allocation-and-inquiry-design-20260906-233205`, which does not own it. A capacity is CHOSEN and every report says so. Carries the first asserted decision edge in the tree |
| 0049 | [0049-the-patch-is-named-as-the-deliverable-and-never-produced](0049-the-patch-is-named-as-the-deliverable-and-never-produced/) | The patch is named as the deliverable, never defined, and would drop half the work if produced | 4 | `unclaimed` | — | Recorded 2026-09-08 by `allocation-and-inquiry-design-20260906-233205` — **a session's account of its own failure.** F3 is independent and worse: the prescribed `git diff` drops every new file |

**15 bundles · 65 findings.** Six of them — `0036` through `0041`, 31 findings, with `0043` recorded and owned here on 2026-09-07 —
were assigned on 2026-09-06 to
[`session-management-re-evaluation-20260906-110105`](../sessions/session-management-re-evaluation-20260906-110105/)
and read on assignment, so each is `analyzing` with every finding in it
`framing`. **`0042` was not assigned** and stays `unclaimed`: parked and closed
to every session until the owner assigns it.

`0042` is the exception to the paragraph below in a second way as well: it
supersedes nothing and was recorded here rather than moved.

Each of the first six supersedes a bundle that stays where it was. **The
originals keep their numbers, their trees, their sessions and their manifests**;
only their status changed, to `superseded`, and their Status cell links here.
**Nothing any of them says was changed** — that is the point of superseding
rather than moving, and it is why `0026` through `0032` are still readable as the
work they were. Their files were brought onto the header schema in Revision 203,
which is a reformat and not an edit to the reading.
