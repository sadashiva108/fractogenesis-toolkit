# Emitted rsync commands target the pre-image path, not the clone

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, while planning item 1.
**Severity:** unsafe to run. Writes decrypted secrets outside every repository.
**Owner:** the Restore Repositories Refactor session.
**Status: CLOSED** by Revision 131, 2026-09-02, same session. All three edits
landed as one change, plus a fourth the note did not ask for: both emitted rsync
scripts now *guard* on the clone destination rather than merely aiming at it, so
`rsync -a` can no longer create a tree for a repository that is not cloned yet.
The Troubleshooting entry named below is retired. Kept for the reasoning.

> **Do not run `rsync-repos-gitignored.sh` from any existing bundle.**

## What is wrong

`bin/restore-repos.sh` emits both rsync scripts with `"$repo_path/"` as the
destination — the path the repository occupied on the **pre-image** machine —
while `clone-commands.sh` clones into `$CLONE_TARGET_ROOT/$label`.

From `post-image-restore-20260825-040841/rsync-ignored-files.sh`:

```bash
# fractogenesis-toolkit
rsync -a --stats \
  "/Volumes/Data/reimage-.../staged-ignored-files/live/fractogenesis-toolkit/" \
  "/Users/dkittrell/Development/documentation/fractogenesis-toolkit/"
```

`/Users/dkittrell/Development/...` does not exist on the reimaged Mac. `rsync -a`
**creates it**. `rsync-repos-gitignored.sh` carries the identical target, so
running it writes DMG-decrypted credentials into a resurrected `Development/`
tree, in the clear, outside every repository, where nothing later in the
workflow looks.

## The same root cause, propagated

`classify_repo()` sets `PATH_PRESENT` by testing `$repo_path/.git` — also the
pre-image path. It is therefore permanently `no`, which means:

- `Needs clone: 0` in Step 9 can never be reached, so the phase has no
  reachable exit criterion;
- `--apply-ignored-files` is gated on `PATH_PRESENT == yes` and silently does
  nothing for every repository;
- `IGNORED_FILES_COMPLETE` can never become true;
- the Troubleshooting entry *"`clone-commands.sh` stops at the first repo because
  the target directory already exists"* documents a symptom of this defect as if
  it were normal behaviour.

## Fix

Three interlocking edits in `bin/restore-repos.sh`, best made as one change
because routing decides `CLONE_TARGET_ROOT`, which the other two depend on:

1. Emit both rsync destinations at `$CLONE_TARGET_ROOT/$label`.
2. Test `PATH_PRESENT` at the resolved clone destination.
3. Route by **remote host**, not by the pre-image directory —
   `restore-repos.md` Step 3 already states this rule in prose, and
   `bin/record-restore-exit.sh` row 3 grades against it. The script is the only
   thing still routing by directory, and on this machine the pre-image roots
   (`Development/...`) sit under neither configured root, so it routes all 27
   repositories to work.

Runbook steps: emitted at `restore-repos.md` **Step 1**, consumed at **Step 5**
and **Step 6**, graded at **Step 9**. Entrypoint: `bin/restore-repos.sh`.

Retire the Troubleshooting entry named above in the same change.
