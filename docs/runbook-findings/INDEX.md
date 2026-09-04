# Runbook findings

Findings whose ramifications are functionally felt in one runbook, including the
scripts and artifacts that runbook owns. One bundle per reading, in a directory
named for the runbook stem; this file indexes all of them.

The line against the other two trees:

| Tree | Subject |
|---|---|
| **`docs/runbook-findings/`** | **one runbook, its scripts and its artifacts** |
| `docs/cross-cutting-findings/` | the workflow's shared machinery — recorders, the run index, the lints, the artifact layout |
| `docs/instruction-set-findings/` | how a session is told to work at all |

The test is where the ramifications are functionally felt, not which file a fix
happens to touch: a defect in a shared script whose impact lands in one runbook
belongs here, and a runbook's own script whose impact is broad does not.

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

### By runbook

Sorted by findings, most first. Each runbook's bundles are the block of
rows in the same position in the table below.

| Runbook | Bundles | Findings | Resolved |
|---|---:|---:|---:|
| `restore-apps` | 1 | 10 | 0 |
| `restore-repos` | 7 | 7 | 3 |
| `backup-repos` | 1 | 1 | 1 |
| `capture-office-stability` | 1 | 1 | 1 |
| `reimage-prep-checks` | 1 | 1 | 1 |
| `restore-access` | 1 | 1 | 0 |
| `restore-docker` | 1 | 1 | 0 |
| `restore-runtime` | 1 | 1 | 0 |
| `stage-loose-secrets` | 1 | 1 | 1 |
| **Total** | **15** | **24** | **7** |

### Every bundle

| # | Runbook | Bundle | Subject | Findings | Status | Session | Notes |
|---:|---|---|---|---:|---|---|---|
| 0001 | `restore-apps` | [0001-restore-repos-evidence](restore-apps/0001-restore-repos-evidence/) | Phase 11B evidence review — what `restore-repos` actually left behind | 10 | `in progress` | [`restore-apps-outstanding-20260903-000000`](../sessions/restore-apps-outstanding-20260903-000000/) | Recorded 2026-09-03. 10 findings: 1–3 block a truthful Phase 12 entry, 4–5 are shared-machinery defects, 6–7 answer the two unreviewed repositories |
| 0008 | `restore-repos` | [0008-carrier-services-storage-foreign-remote](restore-repos/0008-carrier-services-storage-foreign-remote/) | `carrier-services-storage` carries a remote pointing at `dotfiles` | 1 | `unresolved` | — | — |
| 0011 |  | [0011-emit-extra-remotes-readds-the-clone-url](restore-repos/0011-emit-extra-remotes-readds-the-clone-url/) | `emit_extra_remotes` re-adds the URL the clone already used | 1 | `unresolved` | — | — |
| 0016 |  | [0016-post-image-restore-per-run-manifest](restore-repos/0016-post-image-restore-per-run-manifest/) | `MANIFEST.txt` duplicates the category run index | 1 | `unresolved` | — | — |
| 0017 |  | [0017-post-image-restore-runs-truncated](restore-repos/0017-post-image-restore-runs-truncated/) | Every post-image-restore run on disk stops before its report | 1 | `unresolved` | — | — |
| 0020 |  | [0020-repo-audit-tsv-column-shift](restore-repos/0020-repo-audit-tsv-column-shift/) | `repos.tsv` remote column is shifted by embedded tabs | 1 | `resolved` | [`phase-11b-hydrate-and-bookends-20260903-141500`](../sessions/phase-11b-hydrate-and-bookends-20260903-141500/) | closed by Revision 131 |
| 0022 |  | [0022-restore-repos-missing-exit-recorder-steps](restore-repos/0022-restore-repos-missing-exit-recorder-steps/) | `restore-repos.md` opens its boundary but never closes it | 1 | `resolved` | [`run-index-design-20260901-000000`](../sessions/run-index-design-20260901-000000/) | closed by Revision 131 |
| 0023 |  | [0023-restore-repos-rsync-targets-pre-image-path](restore-repos/0023-restore-repos-rsync-targets-pre-image-path/) | Emitted rsync commands target the pre-image path, not the clone | 1 | `resolved` | [`run-index-design-20260901-000000`](../sessions/run-index-design-20260901-000000/) | closed by Revision 131 |
| 0025 | `backup-repos` | [0025-staged-ignored-files-live-parent-root-bundles](backup-repos/0025-staged-ignored-files-live-parent-root-bundles/) | `staged-ignored-files/live/` holds two bundles no lookup can reach | 1 | `resolved` | [`pre-image-capture-conformance-20260903-194532`](../sessions/pre-image-capture-conformance-20260903-194532/) | closed 2026-09-03; the answer is recorded, no code change |
| 0013 | `capture-office-stability` | [0013-office-stability-checklists-are-evidence-bundles](capture-office-stability/0013-office-stability-checklists-are-evidence-bundles/) | `office-stability/checklists/` does not hold checklists | 1 | `resolved` | [`pre-image-capture-conformance-20260903-194532`](../sessions/pre-image-capture-conformance-20260903-194532/) | closed 2026-09-03 by Revisions 137, 138 and this one |
| 0019 | `reimage-prep-checks` | [0019-reimage-checklist-repo-audit-manifest-header](reimage-prep-checks/0019-reimage-checklist-repo-audit-manifest-header/) | Phase 6B records FAIL against a correct repository-audit manifest | 1 | `resolved` | [`pre-image-capture-conformance-20260903-194532`](../sessions/pre-image-capture-conformance-20260903-194532/) | closed by Revision 129 |
| 0021 | `restore-access` | [0021-restore-access-exit-predates-its-own-state-walk](restore-access/0021-restore-access-exit-predates-its-own-state-walk/) | The Phase 10B exit was recorded a week before the evidence it stands on | 1 | `unresolved` | [`run-index-design-20260901-000000`](../sessions/run-index-design-20260901-000000/) | — |
| 0024 | `restore-docker` | [0024-restore-docker-stack-differs-from-pre-image](restore-docker/0024-restore-docker-stack-differs-from-pre-image/) | The running Docker stack is not the one `restore-docker.md` restores | 1 | `unresolved` | — | — |
| 0014 | `restore-runtime` | [0014-orphaned-comparison-lineage-runtime-version-comparison](restore-runtime/0014-orphaned-comparison-lineage-runtime-version-comparison/) | `restore-runtime-version-comparison` is a lineage with no producer | 1 | `unresolved` | [`run-index-design-20260901-000000`](../sessions/run-index-design-20260901-000000/) | — |
| 0007 | `stage-loose-secrets` | [0007-content-scans-keeps-a-bespoke-index](stage-loose-secrets/0007-content-scans-keeps-a-bespoke-index/) | `content-scans/` looks like a run category and is not one | 1 | `resolved` | [`pre-image-capture-conformance-20260903-194532`](../sessions/pre-image-capture-conformance-20260903-194532/) | closed by Revision 141 |