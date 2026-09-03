# `repos.tsv` remote column is shifted by embedded tabs

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, while planning item 1.
**Severity:** blocks Phase 11B's entire automated path.
**Owner:** the Restore Repositories Refactor session.
**Status: CLOSED** by Revision 131, 2026-09-02, same session. Both defects on
that line are fixed forward — the embedded tabs *and* the cycling `paste -sd '; '`
delimiter found while executing this note. The damaged run was repaired by
re-derivation into `pre-image-20260901-234636`, which is pinned official; the
2026-08-16 capture is untouched. Kept for the reasoning.

## What is wrong

`.internal/git/capture-repo-audit.sh` line 429:

```bash
remotes="$(git -C "$repo" remote -v 2>/dev/null | awk '!seen[$0]++' | paste -sd '; ' - || true)"
```

`git remote -v` emits `name<TAB>url (fetch)`. `paste -sd '; ' -` joins the lines
with `; ` but leaves the internal tabs intact. The `printf` at line 462 then
writes that cell into a tab-separated file, so each remote line contributes two
extra columns and every field to its right shifts.

The number of extra columns varies per repository (one pair per remote), so the
damage is not a fixed offset and cannot be undone by a positional re-read.

## Blast radius, verified on disk

Against `repo-audit-reports/runs/pre-image-20260816-035617/repos.tsv`:

- `remote_urls` (column 4) holds `origin` — the remote **name**. The URL sits
  where `status_summary` belongs.
- `extract_remote_url()` in `bin/restore-repos.sh` returns empty for **27 of 27**
  repositories.
- The latest `clone-commands.sh` holds **0** `git clone` lines and **27**
  `# <label> -- no remote URL recorded in pre-image audit` comments.
- `local_only_commit_count`, `stash_count` and `tracked_change_count` are read
  from shifted columns, so every `carry_forward_rows` value in
  `restore-status.md` is meaningless. `ingestion-related: 38` is column drift,
  not 38 pieces of unpreserved work.

`bin/record-restore-prereqs.sh` already detects it. The entry run
`restore-repos-entry-20260825-033849` records:

> `Audit remote URLs are URLs` — `FAIL` — 25 row(s) hold a remote NAME where the
> URL belongs

## The fix, forward

Squash the tabs before joining:

```bash
remotes="$(git -C "$repo" remote -v 2>/dev/null | tr '\t' ' ' | awk '!seen[$0]++' | paste -sd '; ' - || true)"
```

`extract_remote_url` already splits on `;` and then on whitespace, so the
corrected format is exactly what the consumer expects. No consumer change is
needed.

Runbook step: `backup-repos.md` **Step 4 — Run the Repository Audit**, invoked
through `bin/backup-repos.sh` (the runbook never calls the helper directly).
Reviewed at Step 5.

## The fix, backward — needs a decision

The pre-image machine no longer exists, so the audit cannot be re-captured. But
line 539 writes `git remote -v` verbatim into `repo-audit-summary.txt`: 60 URL
lines across 27 repositories, all recoverable, including the two repositories
with no remote and the two spanning both hosts.

Four options with their costs are in
`docs/sessions/phase-11b-hydrate-and-bookends-20260903-141500/restore-repos-phase-11b-plan.md` → Decision A. The recommendation
is to write a corrected run as a new indexed `pre-image-*` run carrying a
manifest note that it is a re-derivation, and pin it — which touches no existing
evidence and keeps the immutability rule intact.
