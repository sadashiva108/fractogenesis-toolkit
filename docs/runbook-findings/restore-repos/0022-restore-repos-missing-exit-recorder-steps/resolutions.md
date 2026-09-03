# Resolutions — `restore-repos.md` opens its boundary but never closes it

**Bundle:** `0022-restore-repos-missing-exit-recorder-steps` · **Status:** `resolved`
**Recorded:** 2026-09-03, during the `docs/*-findings/` migration.

This finding was closed before findings bundles existed, as a parked note whose
`**Status: CLOSED**` line named the revision that closed it. That line is the
resolution; this file states it in the shape every bundle now uses.
`findings.md` is unchanged and carries the reasoning.

| Finding | Resolved by | Commit |
|---|---|---|
| `restore-repos.md` opens its boundary but never closes it | `APPLY-MANIFEST.md` Revision 131 | not identifiable from `git log` — the revision is the record |

Commit hashes for revisions before 141 are not derivable from the log: those
commit messages describe the change rather than naming its revision number. The
revision is authoritative and the manifest entry carries the detail.
