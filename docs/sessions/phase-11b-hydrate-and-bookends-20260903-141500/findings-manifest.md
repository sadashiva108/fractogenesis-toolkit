# Findings owned — `phase-11b-hydrate-and-bookends-20260903-141500`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than restating
the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Status |
|---:|---|---|---|---:|---|
| 0006 | `docs/cross-cutting-findings/0006-caller-environment-precedence-covers-only-listed-keys/` | cross-cutting | Caller-environment precedence holds only for the keys `artifact-config.sh` lists | 1 | `resolved` |
| 0008 | `docs/runbook-findings/restore-repos/0008-carrier-services-storage-foreign-remote/` | runbook | `carrier-services-storage` carries a remote pointing at `dotfiles` | 1 | `unresolved` |
| 0011 | `docs/runbook-findings/restore-repos/0011-emit-extra-remotes-readds-the-clone-url/` | runbook | `emit_extra_remotes` re-adds the URL the clone already used | 1 | `unresolved` |
| 0015 | `docs/cross-cutting-findings/0015-portability-lint-cannot-see-heredoc-context/` | cross-cutting | The portability lint cannot see a defect that needs heredoc context | 1 | `unresolved` |
| 0016 | `docs/runbook-findings/restore-repos/0016-post-image-restore-per-run-manifest/` | runbook | `MANIFEST.txt` duplicates the category run index | 1 | `unresolved` |
| 0017 | `docs/runbook-findings/restore-repos/0017-post-image-restore-runs-truncated/` | runbook | Every post-image-restore run on disk stops before its report | 1 | `unresolved` |
| 0020 | `docs/runbook-findings/restore-repos/0020-repo-audit-tsv-column-shift/` | runbook | `repos.tsv` remote column is shifted by embedded tabs | 1 | `resolved` |

## Where these came from

All seven were recorded by this same session under two earlier briefs, and were
listed in the manifests of the bundles those briefs produced — `0006`, `0008`,
`0011`, `0016`, `0017` and `0020` under `restore-repos-refactor-20260902-000000`,
`0015` under `restore-repos-clone-plan-20260902-000000`. The owner merged them
here on 2026-09-03, and on the same day the two closed bundles were absorbed into
this one — their documents are the `prompt-`, `metadata-` and `brief-summary-`
files beside this manifest.

Ownership had followed the brief a finding was recorded under. That rule fails
when a session outlives its briefs, which this one did: both of those bundles are
correctly `closed` — their briefs finished — and five of the seven findings are
still `unresolved`. A closed bundle cannot work a finding, so the findings sat
against an owner that had, by its own state, stopped. Ownership follows the
session that can still act, and for these seven that is this bundle.

Nothing about the findings themselves changed. Each bundle's `**Found:**` line
still names `session_019yzcjm2QneJ5ymVEQDi1bu`, which is the same session in all
three cases — that is what made the merge a consolidation rather than a transfer.

The two closed manifests are now pointers here and list nothing, so a finding is
listed under exactly one owner.

## Recorded but not owned

`0027-findings-architecture-conformance` was recorded by this session in
Revision 167, at the owner's request and with the explicit instruction not to
address it. Recording a finding and owning one are different acts: recording is
the reading, owning is a commitment to work it. The owner assigns ownership and
has not assigned this one — `0027`'s index row reads `—` and that is correct.
