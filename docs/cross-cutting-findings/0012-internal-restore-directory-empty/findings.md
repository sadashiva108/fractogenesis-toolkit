# `.internal/restore/` is empty, and is not tracked

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`.
**Severity:** trivial. Recorded so it is not rediscovered.

**Corrected for accuracy 2026-09-04**, by the session that recorded it, while the
bundle was still `unresolved`. The original title and first sentence said the
directory was *tracked*. It is not, and the correction changes what the finding
is about — see below.

## What is wrong

`.internal/restore/` exists in the working tree and contains nothing. **Git does
not track it**, and cannot: an empty directory has no blob, so
`git ls-files .internal/restore` and `git ls-tree -r HEAD` both return nothing
and a fresh clone has no such directory. It is a residue of this checkout, not
of the repository.

What *is* in the repository is one sentence. `.internal/artifact-runs.sh` names
the directory in its classification note —

> its callers span `restore/`, `home/`, and the artifact-root reporters

— and that is wrong on its first item. Counted 2026-09-04: **29 files source
`artifact-runs.sh`**, twenty-three of them in `bin/`, the rest
`.internal/git/capture-repo-audit.sh`, `.internal/home/` (two),
`.internal/sign-offs.sh` and `.internal/artifact-run-cli.sh`. **None is under
`.internal/restore/`.** The restore domain's shared pieces exist but sit at the
`.internal/` root — `restore-state-targets.conf.sh`, `state-walk.sh` — and its
entrypoints are the `bin/record-restore-*.sh` family.

So a reader looking for the restore helpers finds an empty directory *and* a
sentence in the shared library telling them helpers live there.

## Related, and the reason this is worth a line

`reimaging-scripts-guide.md`'s `.internal/` tree is stale for the same reason it
was already flagged in both 2026-09-01 session handoffs: it predates
`artifact-runs.sh`, `state-walk.sh`, `sign-offs.sh`, `restore/` and
`ssh-host-list.sh`. `./bin/verify-doc-paths.sh` passes because nothing links into
that tree, so no check will ever catch it.

Two stale things in one guide is the point: the guide is drifting faster than the
checks can see.

## What to do

The empty directory cannot be fixed by a patch — it is not in the repository, so
there is no diff to make. Removing it is a local act on each checkout that has
one.

The repairable part is the sentence in `artifact-runs.sh`. A `.gitkeep` would be
the wrong answer: it would *create* the tracked directory the finding was
originally written about, to hold nothing, on the strength of a claim that is
itself the error.
