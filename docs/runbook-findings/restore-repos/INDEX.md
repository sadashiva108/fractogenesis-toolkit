# Runbook findings — `restore-repos`

Finding bundles whose ramifications are functionally felt in `restore-repos.md`,
including its scripts and the artifacts it owns.

A finding whose impact is broad and agnostic to any particular runbook belongs
in `docs/cross-cutting-findings/` instead — not merely because it touches a
shared script.

The bundle layout and the numbering rule are defined once, in
`.github/copilot-instructions.md` section 4c.

Each bundle also carries a `STATUS-<status>` tag file so a directory listing
answers the status without opening anything. The row here is authoritative.

## Status key

| | |
|---|---|
| `unresolved` | Recorded. No decisions yet. **Any session may add, correct or remove findings here.** |
| `in progress` | The owner is reviewing and deciding. Produces `decisions.md`. **Only the owner writes from here on.** |
| `resolving` | Every finding decided; the decided work is being carried out. Produces `resolutions.md`. |
| `resolved` | Every finding has a resolution recorded. |
| `superseded` | A later bundle replaces this reading. The row names which. |

A bundle advances with its first finding and reaches `resolved` only with its
last. Full definitions, the transitions and the write rules:
[`docs/legend.md`](../../legend.md).

## Bundles

| # | Bundle | Subject | Findings | Status | Session | Notes |
|---:|---|---|---:|---|---|---|
| 0008 | [0008-carrier-services-storage-foreign-remote](0008-carrier-services-storage-foreign-remote/) | `carrier-services-storage` carries a remote pointing at `dotfiles` | 1 | `unresolved` | [`phase-11b-hydrate-and-bookends-20260903-141500`](../../../sessions/phase-11b-hydrate-and-bookends-20260903-141500/) | — |
| 0011 | [0011-emit-extra-remotes-readds-the-clone-url](0011-emit-extra-remotes-readds-the-clone-url/) | `emit_extra_remotes` re-adds the URL the clone already used | 1 | `unresolved` | [`phase-11b-hydrate-and-bookends-20260903-141500`](../../../sessions/phase-11b-hydrate-and-bookends-20260903-141500/) | — |
| 0016 | [0016-post-image-restore-per-run-manifest](0016-post-image-restore-per-run-manifest/) | `MANIFEST.txt` duplicates the category run index | 1 | `unresolved` | [`phase-11b-hydrate-and-bookends-20260903-141500`](../../../sessions/phase-11b-hydrate-and-bookends-20260903-141500/) | — |
| 0017 | [0017-post-image-restore-runs-truncated](0017-post-image-restore-runs-truncated/) | Every post-image-restore run on disk stops before its report | 1 | `unresolved` | [`phase-11b-hydrate-and-bookends-20260903-141500`](../../../sessions/phase-11b-hydrate-and-bookends-20260903-141500/) | — |
| 0020 | [0020-repo-audit-tsv-column-shift](0020-repo-audit-tsv-column-shift/) | `repos.tsv` remote column is shifted by embedded tabs | 1 | `resolved` | [`phase-11b-hydrate-and-bookends-20260903-141500`](../../../sessions/phase-11b-hydrate-and-bookends-20260903-141500/) | closed by Revision 131 |
| 0022 | [0022-restore-repos-missing-exit-recorder-steps](0022-restore-repos-missing-exit-recorder-steps/) | `restore-repos.md` opens its boundary but never closes it | 1 | `resolved` | [`run-index-design-20260901-000000`](../../../sessions/run-index-design-20260901-000000/) | closed by Revision 131 |
| 0023 | [0023-restore-repos-rsync-targets-pre-image-path](0023-restore-repos-rsync-targets-pre-image-path/) | Emitted rsync commands target the pre-image path, not the clone | 1 | `resolved` | [`run-index-design-20260901-000000`](../../../sessions/run-index-design-20260901-000000/) | closed by Revision 131 |
