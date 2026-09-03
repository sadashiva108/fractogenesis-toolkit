# `.internal/restore/` is tracked and empty

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`.
**Severity:** trivial. Recorded so it is not rediscovered.

## What is wrong

`.internal/restore/` exists in the working tree and contains nothing.
`.internal/artifact-runs.sh` names it in its classification note —

> its callers span `restore/`, `home/`, and the artifact-root reporters

— so a reader looking for the restore helpers finds an empty directory and no
indication of whether they were moved, never written, or removed.

## Related, and the reason this is worth a line

`reimaging-scripts-guide.md`'s `.internal/` tree is stale for the same reason it
was already flagged in both 2026-09-01 session handoffs: it predates
`artifact-runs.sh`, `state-walk.sh`, `sign-offs.sh`, `restore/` and
`ssh-host-list.sh`. `./bin/verify-doc-paths.sh` passes because nothing links into
that tree, so no check will ever catch it.

Two stale things in one guide is the point: the guide is drifting faster than the
checks can see.

## What to do

Either delete the empty directory, or put a `.gitkeep` in it with a one-line note
saying what is expected to land there. Fold it into whichever change next touches
`reimaging-scripts-guide.md`, rather than spending a manifest revision on it
alone.
