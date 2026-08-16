[[reimaging-guide#Phase 11B — Restore Repositories|← Back to Mac Reimaging Guide]]

# Restore Repositories

**Last updated:** 2026-08-05

Consume the pre-image repository audit produced by Phase 2C ([[backup-repos|backup-repos.md]]) to re-clone the tracked repositories onto the reimaged Mac, rsync the reviewed kept ignored files back into each working tree, and reconcile every pre-image carry-forward row (local-only commits, stashes, tracked changes) against the state of the freshly cloned repos. Runs after Phase 11A ([[restore-git|restore-git.md]]) has wired up the dual-identity `~/.gitconfig` and `~/.ssh/config`, so every clone command emitted here already routes through the correct SSH key.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#Carry-Forward Model|Carry-Forward Model]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Status Bundle Layout|Status Bundle Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Produce the Initial Status Report|Step 1 — Produce the Initial Status Report]]
    - [[#Step 2 — Review the Emitted Clone Commands|Step 2 — Review the Emitted Clone Commands]]
    - [[#Step 3 — Execute the Clone Commands|Step 3 — Execute the Clone Commands]]
    - [[#Step 4 — Restore Staged Ignored Files|Step 4 — Restore Staged Ignored Files]]
    - [[#Step 5 — Reconcile Rescue Branches|Step 5 — Reconcile Rescue Branches]]
    - [[#Step 6 — Reconcile Stashes and Tracked Changes|Step 6 — Reconcile Stashes and Tracked Changes]]
    - [[#Step 7 — Rerun the Status Report and Close the Exit Criteria|Step 7 — Rerun the Status Report and Close the Exit Criteria]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Per-Repo Status Categories|Per-Repo Status Categories]]
    - [[#Reading the Pre-Image TSVs|Reading the Pre-Image TSVs]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Restore the *content* side of the Git story: get every repository that existed on the pre-image machine back onto the reimaged Mac with its kept ignored files in place and its pre-image carry-forward material (rescue branches, stashes, uncommitted work) either merged in or explicitly discarded with a note. Phase 11A restored the identity plumbing; this phase uses that plumbing to bring the repositories themselves back.

This runbook owns:

```text
reading the pre-image repo-audit-reports/runs/pre-image-*/repos.tsv inventory
per-repo status classification (present | needs clone | ignored bundle available | carry-forward pending)
emitting `git clone` commands that route through the correct dual-identity host alias
rsyncing $REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live/<label>/ back into each cloned working tree
the exit-criteria table for Phase 11B and its sign-off
generating a timestamped restore-status bundle under repo-audit-reports/runs/post-image-restore-*/
```

It does not own:

```text
dual-identity ~/.gitconfig, ~/.ssh/config, and the clone command template itself — Phase 11A (restore-git)
the pre-image push of rescue branches, stash preservation, and the reviewed kept ignored files — Phase 2C (backup-repos)
the encrypted secret ignored files under secrets-encrypted/repos-gitignored/ — Phase 10B (restore-access) via the DMG
IDE-specific repo state (IntelliJ project files, VS Code workspace) — Phase 12 (restore-intellij.md, restore-apps.md)
```

This runbook can be rerun. Each run writes a fresh timestamped bundle under `repo-audit-reports/runs/post-image-restore-*/`; earlier runs stay untouched, so an early "before any clones" run and a later "everything cloned" run can be diffed to prove progress.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The phase is script-driven for the loop (repo enumeration, status classification, action-command emission) and human-driven for the judgment calls (which repos are actually still needed, whether a rescue branch should be merged or discarded, whether the reviewed kept ignored files still apply on the reimaged machine).

`bin/restore-repos.sh` opens `repo-audit-reports/latest-run.txt`, walks the `repos.tsv` inside that pre-image run, and for each row it computes four things:

1. whether the repo is currently on disk at the pre-image path;
2. which SSH host alias to use for cloning (personal alias if the pre-image path was under `$GIT_PERSONAL_REPO_ROOT`, work alias otherwise);
3. whether a `staged-ignored-files/live/<label>/` directory exists for this repo (kept ignored files ready to rsync back);
4. how many carry-forward rows the pre-image audit recorded (local-only commits + stashes + tracked changes).

The script writes those results into a `restore-status.md` report plus a machine-readable `raw/status.tsv`, and it writes two ready-to-run helper scripts — `clone-commands.sh` and `rsync-ignored-files.sh` — that you review, edit if needed, and run selectively. It never autonomously clones a repository, because a stale pre-image inventory would silently repopulate repos you no longer want.

### Carry-Forward Model

The pre-image machine has three things that can be lost across a reimage that plain `git clone` won't recover: (a) commits that were only on a local branch and never pushed, (b) stashes, and (c) modifications to tracked files that were neither committed nor stashed. `backup-repos.md` handles this by asking the operator, *before the reimage*, to push a `reimage/YYYYMMDD/*` rescue branch that includes those changes.

Restoring is then a two-step reconciliation: `git clone` gets the mainline back, and `git fetch origin 'reimage/*'` picks up the rescue branch. This runbook's Step 5 walks that reconciliation per repo. If a pre-image row shows carry-forward count > 0 but no matching rescue branch exists on the remote, that is a real gap in Phase 2C's execution, not something Phase 11B can silently fix.

### Terminology

| Term | Meaning |
|---|---|
| Pre-image audit run | A timestamped `repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/` bundle produced by Phase 2C. Contains `repos.tsv` and the carry-forward TSVs. |
| Post-image restore run | A timestamped `repo-audit-reports/runs/post-image-restore-YYYYMMDD-HHMMSS/` bundle produced by this runbook. Contains the status report and emitted action-command scripts. |
| Label | The basename of a repo path — `basename $REPO_PATH` — used by `backup-repos.md` as the directory name under `staged-ignored-files/live/`. |
| Carry-forward row | A row in `local-only-commits.tsv`, `stashes.tsv`, or `tracked-changes.tsv` from the pre-image run. Each row represents a change the remote does not carry and that must be preserved via a rescue branch or explicitly discarded. |
| Rescue branch | A `reimage/YYYYMMDD/*` branch created and pushed pre-image by Phase 2C to preserve carry-forward material. Restored by fetching `refs/heads/reimage/*` after clone. |
| Staged ignored bundle | A `staged-ignored-files/live/<label>/` directory containing the reviewed kept ignored files for one repo. Rsynced back into the cloned working tree in Step 4. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/restore-repos.sh   # entrypoint
```

Input evidence produced by Phase 2C:

```text
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/latest-run.txt
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/
├── repos.tsv                   # inventory the script iterates
├── local-only-commits.tsv      # carry-forward: commits never pushed
├── stashes.tsv                 # carry-forward: stash list
├── tracked-changes.tsv         # carry-forward: modified tracked files
├── untracked-nonignored.tsv    # informational; not a carry-forward
└── ignored-files.tsv           # informational; the reviewed subset lives under staged-ignored-files/
$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live/
└── <label>/                    # reviewed kept ignored files per repo
```

Output written by this runbook:

```text
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/post-image-restore-YYYYMMDD-HHMMSS/
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/latest-post-image-restore.txt   # pointer to the newest run
```

The complete `repo-audit-reports/` and `staged-ignored-files/` layouts are defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Status Bundle Layout

Each `post-image-restore-*` run is self-contained. Filenames inside are stable across runs.

```text
post-image-restore-YYYYMMDD-HHMMSS/
├── restore-status.md            # human-readable report with the exit-criteria table
├── clone-commands.sh            # one `git clone` per repo not yet on disk
├── rsync-ignored-files.sh       # one `rsync` per repo with staged ignored files
├── MANIFEST.txt
└── raw/
    ├── status.tsv                     # per-repo classification (machine-readable)
    ├── repos-input.tsv                # copy of the pre-image repos.tsv
    ├── local-only-commits-input.tsv   # copy of the pre-image carry-forward rows
    ├── stashes-input.tsv
    └── tracked-changes-input.tsv
```

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md` (paths and roots) and set by the operator (identity keys) before Phase 11A.

| Variable | Meaning |
|---|---|
| `FRACTOGENESIS_HOME` | Repository root for this toolkit checkout; where `reimage.env` lives. |
| `REIMAGE_ARTIFACT_ROOT` | Artifact root where Phase 2C wrote the pre-image audit and where this runbook writes its status bundle. Must be mounted; the script fails fast if it is not. |
| `GIT_WORK_REPO_ROOT` | Directory holding work repos. Repos whose pre-image path was not under `$GIT_PERSONAL_REPO_ROOT` clone into here. |
| `GIT_PERSONAL_REPO_ROOT` | Directory holding personal repos. Repos whose pre-image path was under here clone through the personal SSH host alias. |
| `GIT_WORK_GITHUB_HOST` | SSH host alias for work clones. Emitted in the clone commands. |
| `GIT_PERSONAL_GITHUB_HOST` | SSH host alias for personal clones. Rewrites `git@github.com:` in the pre-image remote URL when routing to personal. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 11A ([[restore-git|restore-git.md]]) closed out with both `ssh -T` identity checks passing. Repositories need the dual-identity `~/.gitconfig` and `~/.ssh/config` in place before any clone command from Step 3 will authenticate correctly.
- The external artifact volume is mounted and `reimage.env` resolves. `ls "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/latest-run.txt"` should print the pointer file.
- The pre-image `repos.tsv` has non-empty rows — this runbook cannot restore repositories that were never inventoried.

> [!bug] Troubleshooting
> If `bin/restore-repos.sh` exits with "latest-run pointer not found", the pre-image audit from Phase 2C either never ran or was written under a different artifact root. Reconnect the correct drive or point at a specific pre-image run with `--input-run pre-image-YYYYMMDD-HHMMSS`.

### Confirm Your Intent

- Are you doing a **full first-time restore** (Steps 1 through 7 in order) or a **rerun** to update the status table after cloning some repos by hand? Both are safe; a rerun writes a fresh timestamped bundle and shows fewer `Needs clone` rows.
- Do you want to **rsync ignored files interactively** during this run (`--apply-ignored-files`), or **inspect the emitted `rsync-ignored-files.sh` first** and run it later? Interactive is faster; inspect-first is safer when you are unsure whether some kept ignored files are still appropriate on the reimaged machine.
- Which **subset of repositories** do you actually want back? The default clone list mirrors the pre-image inventory verbatim. If a repo is stale or archived, delete its line from `clone-commands.sh` before running it rather than cloning and then removing.

> [!warning] Pitfall
> The script's classification depends on the pre-image `repos.tsv` reflecting reality *at that moment*. If you moved or deleted repos between the pre-image audit and the reimage, the emitted actions will still assume the old layout — review before executing.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The status report has to exist before you can review the action files, the action files have to be reviewed before they are executed, and the exit criteria can only be closed after a rerun confirms the state after cloning and rsyncing.

### Step 1 — Produce the Initial Status Report

Run the script with no extra flags to write the first status bundle. This is a read-only pass — no clones happen, no ignored files are rsynced.

Preview the flags first:

```bash
bash -n bin/restore-repos.sh
./bin/restore-repos.sh --help
```

Then run:

```bash
./bin/restore-repos.sh
```

The script prints a summary — total repos, present on disk, needs clone, staged ignored bundles available, carry-forward rows total — and points at the newly written report:

```text
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/post-image-restore-YYYYMMDD-HHMMSS/restore-status.md
```

Open it:

```bash
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/$(cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/latest-post-image-restore.txt")/restore-status.md"
```

> [!note]
> The pre-image inventory is what the script trusts. If a repo was created after Phase 2C ran, it won't appear here — clone it by hand later. If a repo was deleted after Phase 2C ran but is still in the TSV, the emitted clone command will re-create it; delete that line from `clone-commands.sh` in Step 2.

### Step 2 — Review the Emitted Clone Commands

The script emits `clone-commands.sh` alongside the report. Open and review it before running anything:

```bash
LATEST_RUN="$(cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/latest-post-image-restore.txt")"
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/clone-commands.sh"
```

For each block, decide:

- **Keep** — the repo is still relevant. Leave the command as-is.
- **Skip** — the repo is archived or no longer needed. Delete the block or comment it out.
- **Redirect** — the pre-image parent directory no longer applies. Change the `cd` target to a new directory.
- **Reroute** — the URL uses the wrong host alias (rare — the script rewrites `git@github.com:` when routing to personal). Fix by hand.

> [!warning] Pitfall
> The script only rewrites `git@github.com:` when routing to the personal host. It leaves HTTPS URLs and non-github remotes alone. If the pre-image inventory shows an HTTPS clone URL, the resulting clone will use the OS keychain credential, not your restored SSH key — convert to SSH if that matters.

### Step 3 — Execute the Clone Commands

Source `reimage.env` first so `$GIT_WORK_REPO_ROOT` and friends resolve, then run the reviewed clone script:

```bash
source ./reimage.env
bash "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/clone-commands.sh"
```

`clone-commands.sh` is written with `set -euo pipefail`, so the first `git clone` failure stops the batch. Fix that repo (typically a stale URL or a target directory that already exists), delete the completed clones above the failure point, and rerun the tail.

### Step 4 — Restore Staged Ignored Files

Two paths — pick the one you decided on in [[#Confirm Your Intent|Confirm Your Intent]]:

**Interactive path (preferred when you trust the reviewed set).** Rerun the script with `--apply-ignored-files`. It prompts Y/n per repo before rsyncing:

```bash
./bin/restore-repos.sh --apply-ignored-files
```

**Inspect-first path.** Open `rsync-ignored-files.sh` from the latest status bundle, review each block, and run selectively:

```bash
LATEST_RUN="$(cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/latest-post-image-restore.txt")"
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/rsync-ignored-files.sh"
bash "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/rsync-ignored-files.sh"
```

> [!note]
> Kept ignored files that were routed to `secrets-encrypted/repos-gitignored/` by Phase 2C are *not* under `staged-ignored-files/live/` — they come back with the DMG mount in Phase 10B ([[restore-access|restore-access.md]]) and are outside the scope of this runbook.

### Step 5 — Reconcile Rescue Branches

For each repo with `carry-forward rows > 0` in the status report, confirm the pre-image rescue branch made it onto the remote before reimage:

```bash
cd "$GIT_WORK_REPO_ROOT/<repo>"
git fetch origin 'refs/heads/reimage/*:refs/remotes/origin/reimage/*'
git branch -r | grep reimage/ || echo "no rescue branches found on remote"
```

For each rescue branch that shows up, choose one:

- **Merge back** into the intended branch:

  ```bash
  git checkout <target-branch>
  git merge origin/reimage/YYYYMMDD/<name>
  ```

- **Cherry-pick specific commits** when only some of the rescue-branch commits should land:

  ```bash
  git cherry-pick <sha>..<sha>
  ```

- **Leave as a branch** for later triage. Track that decision in the restore notes so it isn't forgotten.

> [!bug] Troubleshooting
> `no rescue branches found on remote` for a repo whose pre-image row shows carry-forward > 0 means Phase 2C's push step was skipped or failed for that repo. This is a real gap. Reconstruct from local backups if any exist; otherwise the carry-forward material is lost, and the row must be closed as "intentionally discarded" in the exit criteria.

### Step 6 — Reconcile Stashes and Tracked Changes

Cross-check `raw/stashes-input.tsv` and `raw/tracked-changes-input.tsv` against the current state of each cloned repo. The pre-image push of a rescue branch typically covered these too, so they usually clear in Step 5. Anything still outstanding here is either:

- Material that was neither committed nor pushed to a rescue branch (real loss);
- A stash the operator intentionally decided not to preserve.

Note the intentional-discard cases in the restore notes.

### Step 7 — Rerun the Status Report and Close the Exit Criteria

Run the script one more time to write a fresh bundle that reflects the post-clone reality:

```bash
./bin/restore-repos.sh
```

Open the new report and confirm the exit criteria:

| Check | Verification mode | How to verify | Expected |
|---|---|---|---|
| Pre-image inventory read | Command | `repos.tsv` produced status rows | PASS |
| Every tracked repo present on disk | Mixed | rerun shows `Needs clone: 0` | PASS |
| Every staged ignored bundle applied | Mixed | rerun shows `Ignored bundles applied` equals `Ignored bundles available` | PASS |
| Rescue branches accounted for | Manual | Step 5 outcome recorded per repo | Every repo with carry-forward > 0 closed as merged / cherry-picked / intentionally discarded |
| Personal repos route via personal SSH host alias | Manual | `git remote -v` in each personal clone | Remote uses `$GIT_PERSONAL_GITHUB_HOST` |

Once every row is closed, Phase 11B is complete. Proceed to Phase 12 ([[restore-apps|restore-apps.md]]).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script does X; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Which repositories in the pre-image inventory are still needed. | The script trusts the inventory verbatim; only you know which repos are archived, stale, or moved elsewhere. |
| Whether a rescue branch should be merged, cherry-picked, or left as a branch. | Depends on how much of the pre-image work is still relevant on the target branch — a call this runbook cannot make. |
| Whether a kept ignored file from the pre-image is still safe on the reimaged Mac. | Machine-specific paths, IDE settings, and env files may reference tooling that changed in Phase 10A. Review before blindly rsyncing every bundle. |
| Whether a carry-forward row with no matching rescue branch is a real loss or an intentional discard. | Only the operator knows which pre-image work was worth preserving; the script only reports the gap. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### `bin/restore-repos.sh` exits with "REIMAGE_ARTIFACT_ROOT is not set or not a directory"

The artifact volume is not mounted, or the environment was not loaded. `ls "$REIMAGE_ARTIFACT_ROOT"` and reconnect the drive.

### `clone-commands.sh` stops at the first repo because the target directory already exists

`git clone` refuses to write into a non-empty directory. Either the repo was already restored by an earlier run of this workflow, or the target directory has stale content. Confirm which, delete the empty stub if that is the cause, and rerun the tail of the batch.

### A repo cloned successfully but `git remote -v` shows the default `github.com` for a personal repo

The pre-image inventory recorded an HTTPS URL, so the script did not rewrite it to the personal host alias. Fix by hand:

```bash
git remote set-url origin "git@${GIT_PERSONAL_GITHUB_HOST}:<personal-username>/<repo>.git"
```

### `--apply-ignored-files` says "yes" but no files appear in the working tree

`rsync -a` respects existing files with newer mtimes. If a clean clone already carries the file with a newer timestamp than the pre-image copy, rsync leaves it alone. Verify with `rsync --dry-run -av` before assuming loss.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Per-Repo Status Categories

| Column | Values | Meaning |
|---|---|---|
| `path_present` | `yes` / `no` | Whether the pre-image path currently exists as a `.git`-containing directory. |
| `ignored_files_available` | `yes` / `no` | Whether `staged-ignored-files/live/<label>/` exists for this repo. |
| `ignored_files_applied` | `unknown` / `yes` / `skipped` / `failed` | Result of the optional interactive rsync in Step 4. `unknown` when the run did not use `--apply-ignored-files`. |
| `carry_forward_rows` | integer | Sum of `local_only_commit_count + stash_count + tracked_change_count` from the pre-image row. Rows requiring rescue-branch reconciliation. |
| `clone_host` | SSH host alias | Which `~/.ssh/config` `Host` entry the emitted clone command will use. |

### Reading the Pre-Image TSVs

Each pre-image TSV serves a different reconciliation step. The columns come from `.internal/git/capture-repo-audit.sh` and are stable across runs.

| File | Purpose in Phase 11B |
|---|---|
| `repos.tsv` | Master inventory. One row per repo; drives the classification loop. |
| `local-only-commits.tsv` | One row per unpushed commit. Cross-check after fetching rescue branches — every row should now be reachable from a `reimage/*` ref. |
| `stashes.tsv` | One row per stash. Same reconciliation as above; stashes typically ride along in the rescue branch as separate commits or a `WIP` note. |
| `tracked-changes.tsv` | One row per modified tracked file. Usually cleared by the rescue branch; anything remaining here after Step 5 is a real loss or an intentional discard. |
| `untracked-nonignored.tsv` | Informational. New files never `git add`-ed. Rarely worth preserving; handle case-by-case if the count is nonzero. |
| `ignored-files.tsv` | Informational. The full list of ignored files; the reviewed subset lives under `staged-ignored-files/live/`. |

[[#Table of Contents|⬆ Back to Table of Contents]]
