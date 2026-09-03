# Findings owned — `run-index-design-20260901-000000`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than
restating the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Status |
|---:|---|---|---|---:|---|
| 0003 | `docs/cross-cutting-findings/0003-boundary-recorder-coverage-is-uneven/` | cross-cutting | The boundary-recorder family is applied unevenly across the phases it covers | 1 | `resolved` |
| 0005 | `docs/cross-cutting-findings/0005-boundary-runs-recorded-long-after-their-phase/` | cross-cutting | Four boundary runs are dated the day the recorder was extended, not the day the phase ran | 1 | `unresolved` |
| 0007 | `docs/runbook-findings/stage-loose-secrets/0007-content-scans-keeps-a-bespoke-index/` | runbook | `content-scans/` looks like a run category and is not one | 1 | `resolved` |
| 0009 | `docs/cross-cutting-findings/0009-dated-artifacts-cite-run-ids-a-rename-breaks/` | cross-cutting | Renaming a lineage silently breaks every citation already written | 1 | `unresolved` |
| 0012 | `docs/cross-cutting-findings/0012-internal-restore-directory-empty/` | cross-cutting | `.internal/restore/` is tracked and empty | 1 | `unresolved` |
| 0013 | `docs/runbook-findings/capture-office-stability/0013-office-stability-checklists-are-evidence-bundles/` | runbook | `office-stability/checklists/` does not hold checklists | 1 | `unresolved` |
| 0014 | `docs/runbook-findings/restore-runtime/0014-orphaned-comparison-lineage-runtime-version-comparison/` | runbook | `restore-runtime-version-comparison` is a lineage with no producer | 1 | `unresolved` |
| 0018 | `docs/cross-cutting-findings/0018-recorder-usage-strings-understate-supported-runbooks/` | cross-cutting | Two recorders still tell you your own phase is unsupported | 1 | `resolved` |
| 0019 | `docs/runbook-findings/reimage-prep-checks/0019-reimage-checklist-repo-audit-manifest-header/` | runbook | Phase 6B records FAIL against a correct repository-audit manifest | 1 | `resolved` |
| 0021 | `docs/runbook-findings/restore-access/0021-restore-access-exit-predates-its-own-state-walk/` | runbook | The Phase 10B exit was recorded a week before the evidence it stands on | 1 | `unresolved` |
| 0022 | `docs/runbook-findings/restore-repos/0022-restore-repos-missing-exit-recorder-steps/` | runbook | `restore-repos.md` opens its boundary but never closes it | 1 | `resolved` |
| 0023 | `docs/runbook-findings/restore-repos/0023-restore-repos-rsync-targets-pre-image-path/` | runbook | Emitted rsync commands target the pre-image path, not the clone | 1 | `resolved` |
| 0025 | `docs/runbook-findings/backup-repos/0025-staged-ignored-files-live-parent-root-bundles/` | runbook | `staged-ignored-files/live/` holds two bundles no lookup can reach | 1 | `unresolved` |
| 0026 | `docs/cross-cutting-findings/0026-verify-doc-paths-counts-gitignored-docs/` | cross-cutting | `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold | 1 | `resolved` |

A finding this session *found* but handed to another session is listed in that
session's manifest, not here: `0020` was recorded by this session while planning
item 1 and owned by the Restore Repositories Refactor session, which closed it.

Ownership was reconstructed during the Revision 162 conversion from the
`**Found:**` line each note carries, which names the session that recorded it.
