# Two recorders still tell you your own phase is unsupported

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, item 2.
**Status: CLOSED** by Revision 136, 2026-09-02. Both scripts now derive every
message from one `SUPPORTED_RUNBOOKS` string, the shape `record-restore-state.sh`
already used. Kept for the reasoning.
**Severity:** low to fix, high to hit — it turns a working command into an error
message at the moment an operator is following a runbook.

## What is wrong

Revision 126 fixed exactly this defect in `bin/record-restore-exit.sh`:

> Usage strings advertised only `restore-runtime, restore-access` while
> dispatching on four runbooks — running it bare told you your own phase was
> unsupported.

It was fixed in that one script. Two siblings carry the identical defect.

| Script | Dispatches on | Advertises | Where the stale string is |
|---|---|---|---|
| `bin/record-restore-prereqs.sh` | **5** — runtime, access, git, repos, apps | 2 | the `HINT:` at the `case` fallthrough (~line 166) |
| `bin/compare-restored-state.sh` | **3** — runtime, access, git | 2 | usage header (~line 61), `resolve_runbook` HINT (~line 173), required-argument error (~line 237) |
| `bin/record-restore-exit.sh` | 4 | 4 | consistent — fixed in Revision 126 |
| `bin/record-restore-state.sh` | 4 | 4 | consistent — single `SUPPORTED_RUNBOOKS` string |

`compare-restored-state.sh` is the one that actually misleads: `restore-git.md`
Step 8 calls `./bin/compare-restored-state.sh --runbook restore-git`, which
works, while the script's own `--help` says that runbook is not supported.

## Fix

`record-restore-state.sh` already shows the shape: one `SUPPORTED_RUNBOOKS`
string, used in the required-argument error, the `case` guard and the HINT, so
there is no second table to drift. Adopt it in both scripts rather than editing
three literals in one of them.

`bin/record-restore-prereqs.sh` also has a `restore-repos` case, but the change
is to its usage string, not to any Phase 11B behaviour — it does not collide with
the Restore Repositories Refactor session.

One revision covers both. No runbook changes; the commands the runbooks already
give are the ones that work.
