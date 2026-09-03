# Findings owned — `restore-repos-refactor-20260902-000000`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than
restating the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Status |
|---:|---|---|---|---:|---|
| 0006 | `docs/cross-cutting-findings/0006-caller-environment-precedence-covers-only-listed-keys/` | cross-cutting | Caller-environment precedence holds only for the keys `artifact-config.sh` lists | 1 | `resolved` |
| 0008 | `docs/runbook-findings/restore-repos/0008-carrier-services-storage-foreign-remote/` | runbook | `carrier-services-storage` carries a remote pointing at `dotfiles` | 1 | `unresolved` |
| 0011 | `docs/runbook-findings/restore-repos/0011-emit-extra-remotes-readds-the-clone-url/` | runbook | `emit_extra_remotes` re-adds the URL the clone already used | 1 | `unresolved` |
| 0016 | `docs/runbook-findings/restore-repos/0016-post-image-restore-per-run-manifest/` | runbook | `MANIFEST.txt` duplicates the category run index | 1 | `unresolved` |
| 0017 | `docs/runbook-findings/restore-repos/0017-post-image-restore-runs-truncated/` | runbook | Every post-image-restore run on disk stops before its report | 1 | `unresolved` |
| 0020 | `docs/runbook-findings/restore-repos/0020-repo-audit-tsv-column-shift/` | runbook | `repos.tsv` remote column is shifted by embedded tabs | 1 | `resolved` |

Ownership was reconstructed during the Revision 162 conversion from the
`**Found:**` line each note carries, which names the session that recorded it.
