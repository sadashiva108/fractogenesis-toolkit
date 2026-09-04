# Findings owned — `run-index-design-20260901-000000`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than
restating the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Status |
|---:|---|---|---|---:|---|
| 0003 | `docs/cross-cutting-findings/0003-boundary-recorder-coverage-is-uneven/` | cross-cutting | The boundary-recorder family is applied unevenly across the phases it covers | 1 | `resolved` |
| 0005 | `docs/cross-cutting-findings/0005-boundary-runs-recorded-long-after-their-phase/` | cross-cutting | Four boundary runs are dated the day the recorder was extended, not the day the phase ran | 1 | `unresolved` |
| 0009 | `docs/cross-cutting-findings/0009-dated-artifacts-cite-run-ids-a-rename-breaks/` | cross-cutting | Renaming a lineage silently breaks every citation already written | 1 | `superseded` |
| 0012 | `docs/cross-cutting-findings/0012-internal-restore-directory-empty/` | cross-cutting | `.internal/restore/` is tracked and empty | 1 | `unresolved` |
| 0014 | `docs/runbook-findings/restore-runtime/0014-orphaned-comparison-lineage-runtime-version-comparison/` | runbook | `restore-runtime-version-comparison` is a lineage with no producer | 1 | `unresolved` |
| 0018 | `docs/cross-cutting-findings/0018-recorder-usage-strings-understate-supported-runbooks/` | cross-cutting | Two recorders still tell you your own phase is unsupported | 1 | `resolved` |
| 0021 | `docs/runbook-findings/restore-access/0021-restore-access-exit-predates-its-own-state-walk/` | runbook | The Phase 10B exit was recorded a week before the evidence it stands on | 1 | `unresolved` |
| 0022 | `docs/runbook-findings/restore-repos/0022-restore-repos-missing-exit-recorder-steps/` | runbook | `restore-repos.md` opens its boundary but never closes it | 1 | `resolved` |
| 0023 | `docs/runbook-findings/restore-repos/0023-restore-repos-rsync-targets-pre-image-path/` | runbook | Emitted rsync commands target the pre-image path, not the clone | 1 | `resolved` |
| 0026 | `docs/cross-cutting-findings/0026-verify-doc-paths-counts-gitignored-docs/` | cross-cutting | `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold | 1 | `resolved` |

A finding this session *found* but handed to another session is listed in that
session's manifest, not here: `0020` was recorded by this session while planning
item 1 and owned by the Restore Repositories Refactor session, which closed it.

Four findings left this manifest on 2026-09-03 and are listed the same way, in
the manifest of the session they went to: `0007`, `0013`, `0019` and `0025` were
reassigned by the owner to
`docs/sessions/pre-image-capture-conformance-20260903-194532/` under Revision
178, and are all resolved there. The rows are absent above because ownership
moved. **A reassignment is not a handover** — this session transferred nothing
and made no successor — and the distinction is why its state was corrected to
`owned` on 2026-09-04 rather than left at `handoff`.

## One finding inside another session's bundle

`0030` finding 3 — *a category manifest records no `rename` row, so a former
lineage name is unrecoverable from the index* — is assigned to this session.
The bundle,
`docs/cross-cutting-findings/0030-renames-break-citations-and-which-may-be-repaired/`,
is owned by `pre-image-capture-conformance-20260903-194532` and is `in progress`.
Its decision 6 holds finding 3 open deliberately: the `rename` row belongs to
whoever performs the next conversion, and that is this session's item 4. Because
`resolving` gates on the whole bundle, `0030` cannot advance until finding 3 is
decided — a bundle owned elsewhere is blocked here.

**It is deliberately not a row in the table above.** That table is one row per
bundle and is authoritative for what this session *owns*; a row would put one
bundle in two manifests and make `docs/sessions/INDEX.md` count it twice. The
counts stay `10` and `10`, which is what `./bin/verify-findings-counts.sh`
checks.

The instruction set has no shape for a finding-level assignment across bundles —
4d's manifest is per-bundle throughout — so this note is the nearest the existing
conventions reach. Whether that gap is worth a finding of its own is the owner's
call.

Ownership was reconstructed during the Revision 162 conversion from the
`**Found:**` line each note carries, which names the session that recorded it.
