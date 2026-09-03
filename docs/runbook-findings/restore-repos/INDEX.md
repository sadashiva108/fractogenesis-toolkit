# Runbook findings — `restore-repos`

Finding bundles whose ramifications are functionally felt in `restore-repos.md`,
including its scripts and the artifacts it owns.

A finding whose impact is broad and agnostic to any particular runbook belongs
in `docs/cross-cutting-findings/` instead — not merely because it touches a
shared script.

**The bundle layout, the status vocabulary and the numbering rule are defined
once**, in `.github/copilot-instructions.md` section 4c. This file carries the
rows and nothing else.

Each bundle also carries a `STATUS-<status>` tag file so a directory listing
answers the status without opening anything. The row here is authoritative.

## Bundles

| # | Bundle | Subject | Findings | Status | Session | Notes |
|---:|---|---|---:|---|---|---|
| 0008 | [0008-carrier-services-storage-foreign-remote](0008-carrier-services-storage-foreign-remote/) | `carrier-services-storage` carries a remote pointing at `dotfiles` | 1 | `unresolved` | [`restore-repos-refactor-20260902-000000`](../../../sessions/restore-repos-refactor-20260902-000000/) | — |
| 0011 | [0011-emit-extra-remotes-readds-the-clone-url](0011-emit-extra-remotes-readds-the-clone-url/) | `emit_extra_remotes` re-adds the URL the clone already used | 1 | `unresolved` | [`restore-repos-refactor-20260902-000000`](../../../sessions/restore-repos-refactor-20260902-000000/) | — |
| 0016 | [0016-post-image-restore-per-run-manifest](0016-post-image-restore-per-run-manifest/) | `MANIFEST.txt` duplicates the category run index | 1 | `unresolved` | [`restore-repos-refactor-20260902-000000`](../../../sessions/restore-repos-refactor-20260902-000000/) | — |
| 0017 | [0017-post-image-restore-runs-truncated](0017-post-image-restore-runs-truncated/) | Every post-image-restore run on disk stops before its report | 1 | `unresolved` | [`restore-repos-refactor-20260902-000000`](../../../sessions/restore-repos-refactor-20260902-000000/) | — |
| 0020 | [0020-repo-audit-tsv-column-shift](0020-repo-audit-tsv-column-shift/) | `repos.tsv` remote column is shifted by embedded tabs | 1 | `resolved` | [`restore-repos-refactor-20260902-000000`](../../../sessions/restore-repos-refactor-20260902-000000/) | closed by Revision 131 |
| 0022 | [0022-restore-repos-missing-exit-recorder-steps](0022-restore-repos-missing-exit-recorder-steps/) | `restore-repos.md` opens its boundary but never closes it | 1 | `resolved` | [`run-index-design-20260901-000000`](../../../sessions/run-index-design-20260901-000000/) | closed by Revision 131 |
| 0023 | [0023-restore-repos-rsync-targets-pre-image-path](0023-restore-repos-rsync-targets-pre-image-path/) | Emitted rsync commands target the pre-image path, not the clone | 1 | `resolved` | [`run-index-design-20260901-000000`](../../../sessions/run-index-design-20260901-000000/) | closed by Revision 131 |
