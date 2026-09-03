# `carrier-services-storage` carries a remote pointing at `dotfiles`

**Found:** 2026-09-01, Restore Repositories Refactor session, while re-deriving
the pre-image `repos.tsv`.
**Severity:** operator decision, not a defect in the toolkit.
**Owner:** the repository owner, at `restore-repos.md` Step 2.

## What the audit recorded

`/Users/dkittrell/Development/documentation/carrier-services-storage`, on branch
`mlMultiNodeCluster`, had three remotes:

| Name | URL |
|---|---|
| `omkara` | `https://github.com/sadashiva108/dotfiles.git` |
| `orah` | `https://github.gaig.com/dkittrell/carrier-services-storage.git` |
| `origin` | `https://github.gaig.com/MarkLogic/carrier-services-storage.git` |

`omkara` points at a **different repository entirely** — a personal `dotfiles`
repo on the public host — from a work repository on the Enterprise server.

## Why it matters here

Two things follow from it, and both are already handled:

- It is the repository that exposed the `paste -sd '; '` delimiter-cycling
  defect. With `origin` third alphabetically, the old consumer resolved the
  repository to `omkara`'s URL and would have cloned `dotfiles` into
  `workspace/shiva/carrier-services-storage`. Fixed at the source.
- `emit_extra_remotes` restores `omkara` faithfully, because the audit recorded
  it. That is correct behaviour for a restore: the runbook does not get to decide
  that a remote was a mistake.

## The decision

At Step 2, decide whether `omkara` comes back. If it was added by accident on the
pre-image machine, delete those two lines from `clone-commands.sh` before running
it — restoring it re-creates a path from a work checkout to a personal
repository, which is the kind of thing that later pushes work content somewhere
public.
