# Findings owned — `run-index-design-20260901-000000`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than
restating the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Status |
|---:|---|---|---|---:|---|
| 0003 | `docs/cross-cutting-findings/0003-boundary-recorder-coverage-is-uneven/` | cross-cutting | The boundary-recorder family is applied unevenly across the phases it covers | 1 | `resolved` |
| 0005 | `docs/cross-cutting-findings/0005-boundary-runs-recorded-long-after-their-phase/` | cross-cutting | Four boundary runs are dated the day the recorder was extended, not the day the phase ran | 1 | `resolved` |
| 0009 | `docs/cross-cutting-findings/0009-dated-artifacts-cite-run-ids-a-rename-breaks/` | cross-cutting | Renaming a lineage silently breaks every citation already written | 1 | `superseded` |
| 0012 | `docs/cross-cutting-findings/0012-internal-restore-directory-empty/` | cross-cutting | `.internal/restore/` is empty, and is not tracked | 1 | `resolved` |
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
lineage name is unrecoverable from the index* — was assigned to this session.
The bundle,
`docs/cross-cutting-findings/0030-renames-break-citations-and-which-may-be-repaired/`,
is owned by `pre-image-capture-conformance-20260903-194532` and is `resolved` as
of Revision 196. Its decision 6 had held finding 3 open deliberately: the
`rename` row belongs to whoever performs the next conversion, and that is this
session's item 4. Because `resolving` gates on the whole bundle, `0030` could not
advance until finding 3 was decided, so a bundle owned elsewhere was blocked
here.

**It was decided as D7, by this session, under an owner's override given
2026-09-04**, and the override is named in the `APPLY-MANIFEST.md` entry that
carried it. Two things about D7 belong in this session's own record rather than
only in the other session's:

- **Its closing claim was wrong.** D7 asserted that every finding in `0030` then
  carried a decision — the condition the `resolving` gate turns on — and finding
  1 did not, as D7's own text says two paragraphs earlier. The owning session
  caught it, added D8, and held its toolkit write in its composing copy until the
  gate closed honestly. `0030`'s `resolutions.md` records this.
- **Its toolkit write was made by the owning session, not by this one.**
  `artifact_run_record_rename()` and the rename procedure are in
  `.internal/artifact-runs.sh`. What remains owed here is the three retroactive
  `rename` rows themselves, which are evidence writes and are listed in
  `outstanding-20260904.md`.

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
