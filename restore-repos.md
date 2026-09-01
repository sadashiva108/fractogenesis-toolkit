[[reimaging-guide#Phase 11B — Restore Repositories|← Back to Mac Reimaging Guide]]

# Restore Repositories

**Last updated:** 2026-09-01

Consume the pre-image repository audit produced by Phase 2A to re-clone the tracked repositories onto the reimaged Mac, rsync the reviewed kept ignored files back into each working tree, and reconcile every pre-image carry-forward row (local-only commits, stashes, tracked changes) against the state of the freshly cloned repos. Runs after Phase 11A has wired up the dual-identity `~/.gitconfig` and `~/.ssh/config`, so every clone command emitted here already routes through the correct SSH key.

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
    - [[#Step 0 — Record Prerequisites and the Before-State|Step 0 — Record Prerequisites and the Before-State]]
    - [[#Step 1 — Produce the Initial Status Report|Step 1 — Produce the Initial Status Report]]
    - [[#Step 2 — Review the Emitted Clone Commands|Step 2 — Review the Emitted Clone Commands]]
    - [[#Step 3 — Execute the Clone Commands|Step 3 — Execute the Clone Commands]]
    - [[#Step 4 — Repoint at the Cloned Toolkit|Step 4 — Repoint at the Cloned Toolkit]]
    - [[#Step 5 — Restore Staged Ignored Files|Step 5 — Restore Staged Ignored Files]]
    - [[#Step 6 — Restore Per-Repo Gitignored Secrets from the DMG|Step 6 — Restore Per-Repo Gitignored Secrets from the DMG]]
    - [[#Step 7 — Reconcile Rescue Branches|Step 7 — Reconcile Rescue Branches]]
    - [[#Step 8 — Reconcile Stashes and Tracked Changes|Step 8 — Reconcile Stashes and Tracked Changes]]
    - [[#Step 9 — Rerun the Status Report and Close the Exit Criteria|Step 9 — Rerun the Status Report and Close the Exit Criteria]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Per-Repo Status Categories|Per-Repo Status Categories]]
    - [[#Reading the Pre-Image TSVs|Reading the Pre-Image TSVs]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Restore the *content* side of the Git story: get every repository that existed on the pre-image machine back onto the reimaged Mac with its kept ignored files in place and its pre-image carry-forward material (rescue branches, stashes, uncommitted work) either merged in or explicitly discarded with a note. Phase 11A restored the identity plumbing; this phase uses that plumbing to bring the repositories themselves back.

**What it sets up**

- **The restore-status bundle** — a timestamped `post-image-restore-*` run under `repo-audit-reports/runs/` holding `restore-status.md`, the machine-readable `raw/status.tsv`, and copies of the pre-image inputs it classified against.
- **The Phase 11B sign-off** — `repo-audit-reports/sign-offs/post-image-restore-YYYYMMDD-HHMMSS.md`, holding the two rows only you can answer. It sits beside `runs/` rather than inside one, because a run directory is replaced on every rerun and an answered row must not be.
- **Reviewable action files** — `clone-commands.sh` and `rsync-ignored-files.sh`, emitted per run so you decide which repositories are cloned and which kept ignored files are rsynced back, rather than the script deciding for you.
- **The restored working trees** — every tracked repository back on disk under the correct Git root, with its `staged-ignored-files/live/<label>/` bundle rsynced into place.
- **A closed carry-forward ledger** — every pre-image rescue branch, stash, and tracked change either merged, cherry-picked, left as a branch with a note, or explicitly discarded.

**What the rest of the workflow relies on it for**

- Phase 12 restores app and IDE state on top of the repositories this phase puts back on disk.
- The exit-criteria table inside `restore-status.md` is the Phase 11B sign-off evidence that every tracked repo and its kept ignored files are accounted for.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| reading the pre-image `repo-audit-reports/runs/pre-image-*/repos.tsv` inventory and classifying each repo (present / needs clone / ignored bundle available / carry-forward pending) | the pre-image push of rescue branches, stash preservation, and the reviewed kept ignored files — `backup-repos` (Phase 2A) |
| emitting `git clone` commands that route through the correct dual-identity host alias | dual-identity `~/.gitconfig`, `~/.ssh/config`, and the clone command template itself — `restore-git` (Phase 11A) |
| rsyncing `$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live/<label>/` back into each cloned working tree | the encrypted secret ignored files under `secrets-encrypted/repos-gitignored/`, which come back with the DMG — `restore-access` (Phase 10B) |
| the timestamped restore-status bundle under `repo-audit-reports/runs/post-image-restore-*/`, its exit-criteria table, and the Phase 11B sign-off | IDE-specific repo state such as IntelliJ project files and the VS Code workspace — `restore-intellij` and `restore-apps` (Phase 12) |

This runbook can be rerun. Each run writes a fresh timestamped bundle under `repo-audit-reports/runs/post-image-restore-*/`; earlier runs stay untouched, so an early "before any clones" run and a later "everything cloned" run can be diffed to prove progress. A rerun also writes a new sign-off carrying your answers forward, so rerunning never costs you a row you already closed.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The phase is script-driven for the loop (repo enumeration, status classification, action-command emission) and human-driven for the judgment calls (which repos are actually still needed, whether a rescue branch should be merged or discarded, whether the reviewed kept ignored files still apply on the reimaged machine).

`bin/restore-repos.sh` opens `repo-audit-reports/official/pre-image.txt`, walks the `repos.tsv` inside that pre-image run, and for each row it computes four things:

1. whether the repo is currently on disk at the pre-image path;
2. which SSH host alias to use for cloning (personal alias if the pre-image path was under `$GIT_PERSONAL_REPO_ROOT`, work alias otherwise);
3. whether a `staged-ignored-files/live/<label>/` directory exists for this repo (kept ignored files ready to rsync back);
4. how many carry-forward rows the pre-image audit recorded (local-only commits + stashes + tracked changes).

The script writes those results into a `restore-status.md` report plus a machine-readable `raw/status.tsv`, and it writes two ready-to-run helper scripts — `clone-commands.sh` and `rsync-ignored-files.sh` — that you review, edit if needed, and run selectively. It never autonomously clones a repository, because a stale pre-image inventory would silently repopulate repos you no longer want.

### Carry-Forward Model

The pre-image machine has three things that can be lost across a reimage that plain `git clone` won't recover: (a) commits that were only on a local branch and never pushed, (b) stashes, and (c) modifications to tracked files that were neither committed nor stashed. `backup-repos.md` handles this by asking the operator, *before the reimage*, to push a `reimage/YYYYMMDD/*` rescue branch that includes those changes.

Restoring is then a two-step reconciliation: `git clone` gets the mainline back, and `git fetch origin 'reimage/*'` picks up the rescue branch. The rescue-branch reconciliation gets its own step, run once per repo. If a pre-image row shows carry-forward count > 0 but no matching rescue branch exists on the remote, that is a real gap in Phase 2A's execution, not something Phase 11B can silently fix.

### Terminology

| Term | Meaning |
|---|---|
| Pre-image audit run | A timestamped `repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/` bundle produced by Phase 2A. Contains `repos.tsv` and the carry-forward TSVs. |
| Post-image restore run | A timestamped `repo-audit-reports/runs/post-image-restore-YYYYMMDD-HHMMSS/` bundle produced by this runbook. Contains the status report and emitted action-command scripts. |
| Label | The basename of a repo path — `basename $REPO_PATH` — used by `backup-repos.md` as the directory name under `staged-ignored-files/live/`. |
| Carry-forward row | A row in `local-only-commits.tsv`, `stashes.tsv`, or `tracked-changes.tsv` from the pre-image run. Each row represents a change the remote does not carry and that must be preserved via a rescue branch or explicitly discarded. |
| Rescue branch | A `reimage/YYYYMMDD/*` branch created and pushed pre-image by Phase 2A to preserve carry-forward material. Restored by fetching `refs/heads/reimage/*` after clone. |
| Staged ignored bundle | A `staged-ignored-files/live/<label>/` directory containing the reviewed kept ignored files for one repo, rsynced back into the cloned working tree. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/restore-repos.sh   # entrypoint
```

Input evidence produced by Phase 2A:

```text
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/pre-image.txt
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
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/post-image-restore.txt   # pointer to the newest run
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

The `reimage.env` values this runbook depends on. `REIMAGE_ARTIFACT_ROOT` is resolved during `prepare-artifact-root.md`, the repository roots during [[backup-repos|backup-repos.md]] Step 1, and the host aliases during [[restore-git|restore-git.md]] Step 0c. `GIT_PERSONAL_GITHUB_OWNER` is written **by this runbook**, in Step 0c. Who owns which key, across every phase: [[references/environment-variable-reference|Environment Variable Reference]].

| Variable | Meaning |
|---|---|
| `FRACTOGENESIS_HOME` | Toolkit root; where `reimage.env` lives. Until this phase it points at the `curl` or jump-drive install from Phase 8, not a clone — see [[#Step 4 — Repoint at the Cloned Toolkit|Step 4 — Repoint at the Cloned Toolkit]]. |
| `REIMAGE_ARTIFACT_ROOT` | Artifact root where Phase 2A wrote the pre-image audit and where this runbook writes its status bundle. Must be mounted; the script fails fast if it is not. |
| `GIT_WORK_REPO_ROOT` | Directory holding work repos. Repos whose pre-image path was not under `$GIT_PERSONAL_REPO_ROOT` clone into here. |
| `GIT_PERSONAL_REPO_ROOT` | Directory holding personal repos. Repos whose pre-image path was under here clone through the personal SSH host alias. |
| `GIT_WORK_GITHUB_HOST` | SSH host alias for work clones. Emitted in the clone commands. |
| `GIT_PERSONAL_GITHUB_HOST` | SSH host alias for personal clones. Rewrites `git@github.com:` in the pre-image remote URL when routing to personal. |
| `GIT_PERSONAL_GITHUB_OWNER` | Optional. The GitHub account that owns your personal repositories. `bin/restore-repos.sh` rewrites a clone URL to `$GIT_PERSONAL_GITHUB_HOST` **only** when the URL's owner matches this, so a work-org repository sitting under the personal root is never handed a personal SSH alias. Blank means never rewrite — every candidate is flagged for review in Step 2 instead. Written **by this runbook**, in Step 0c; it is not in `reimage.env.example` and no earlier phase sets it. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the toolkit root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 11A ([[restore-git|restore-git.md]]) closed out with both `ssh -T` identity checks passing. Repositories need the dual-identity `~/.gitconfig` and `~/.ssh/config` in place before any emitted clone command will authenticate correctly.
- The external artifact volume is mounted and `reimage.env` resolves. `ls "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/pre-image.txt"` should print the pointer file.
- The pre-image `repos.tsv` has non-empty rows — this runbook cannot restore repositories that were never inventoried.

> [!bug] Troubleshooting
> If `bin/restore-repos.sh` exits with "latest-run pointer not found", the pre-image audit from Phase 2A either never ran or was written under a different artifact root. Reconnect the correct drive or point at a specific pre-image run with `--input-run pre-image-YYYYMMDD-HHMMSS`.

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

### Step 0 — Record Prerequisites and the Before-State

Two recordings, both taken before anything is cloned. They answer different
questions and only one of them can be taken late.

**0a — may this phase start?** Writes a checklist under
`reimaged-system/boundaries/` and exits non-zero only on `FAIL`:

```bash
./bin/record-restore-prereqs.sh --runbook restore-repos --dry-run
./bin/record-restore-prereqs.sh --runbook restore-repos
```

The first four rows are derived from *Prerequisites* above, so the two cannot
drift. The last three read the pre-image audit itself, and they exist because
`bin/restore-repos.sh` is read-only and always produces a status bundle — a run
against an empty or damaged audit looks exactly like a clean one.

**Audit remote URLs are URLs** is the row to read twice. `capture-repo-audit.sh`
builds that column from `git remote -v`, whose output is *itself* tab-separated,
and writes it into a TSV unsquashed — so the URL can land in a later column and
leave the remote *name* where the URL belongs. `restore-repos.sh` feeds that
field to `rewrite_remote_for_host`, so a damaged column surfaces as clone
commands that are malformed rather than as an error. When this row FAILs, read
the real URLs out of `repo-audit-summary.txt` before trusting anything in
`clone-commands.sh`.

The two WARN rows name repositories that need a decision rather than a fix. A
repository with **no remote** cannot be cloned by anything — its only copy is
whatever the backup staged, so it is a Time Machine recovery or a deliberate
loss. A repository whose remotes span **both hosts** has no automatic answer to
which root it belongs in, because the host is what decides that everywhere else.
Both are recorded in *Decisions*.

**0b — what is on disk right now?** Writes a run under `reimaged-system/state/`
recording the clone destinations as they stand before this phase fills them:

```bash
./bin/record-restore-state.sh --runbook restore-repos --point before --dry-run
./bin/record-restore-state.sh --runbook restore-repos --point before
```

Two targets, both walked at depth 1: `$GIT_WORK_REPO_ROOT/` and
`$GIT_PERSONAL_REPO_ROOT/`. Depth 1 rather than a full walk because the question
is *which repositories exist*, not what is inside them — a recursive capture of
27 checkouts would hash tens of thousands of files to answer a question that is
one row per repository. The before-state is normally two empty roots; the delta
against the after-state is then literally the list of what this phase restored.

> [!note]
> Every block in this runbook shows a `--dry-run` line above the real one. It
> prints the table and writes nothing. On **0b** that preview matters most:
> `before` is a first-wins point, so the first capture recorded is the one that
> stays official, and a mistimed one cannot be replaced — only annotated with a
> pin explaining why it is wrong.

> [!warning] Pitfall
> **0b expires and 0a does not.** The prerequisite check is rerunnable at any
> point and costs nothing to repeat. The before-state is gone the moment the
> first clone lands in either root, so take 0b before Step 0c — and confirm no
> scratch repository is sitting in a clone root, since one left behind by
> `restore-git` Step 7 records as restored content.

**0c — record the personal-repo owner.** `bin/restore-repos.sh` rewrites a clone
URL to `$GIT_PERSONAL_GITHUB_HOST` only when the URL's owner matches
`GIT_PERSONAL_GITHUB_OWNER`. That match is what keeps a work-org repository
sitting under the personal root from being handed a personal SSH alias. It is the
only `reimage.env` key this phase owns, no earlier phase sets it, and Step 1 is
the first thing that reads it.

Blank is a valid answer and means *never rewrite*: every repository that would
have routed personal is flagged for review in Step 2 instead. Skip this on a Mac
with no personal identity — 0a's *Clone roots set and distinct* row has already
established there is no personal root, and an owner without a root routes
nothing.

```bash
export GIT_PERSONAL_GITHUB_OWNER="your-personal-github-account"

if [ -n "$GIT_PERSONAL_GITHUB_OWNER" ] && [ -z "${GIT_PERSONAL_REPO_ROOT:-}" ]; then
  printf 'REFUSING to write. An owner is set but GIT_PERSONAL_REPO_ROOT is empty,\n'
  printf 'so no repository can route to the personal host regardless of the owner.\n'
  printf 'Leave the owner blank, or record the root in backup-repos and source\n'
  printf 'reimage.env again.\n'
else
  python3 bin/prepare-artifact-root.py \
    upsert-env \
    --env-file reimage.env \
    "GIT_PERSONAL_GITHUB_OWNER=$GIT_PERSONAL_GITHUB_OWNER"
fi
```

Confirm what landed, rather than trusting the write:

```bash
grep -E '^(export )?GIT_PERSONAL_GITHUB_OWNER=' reimage.env
```

`upsert-env` writes an empty value without complaint, which is correct here — a
blank owner is a decision, not an omission. What it cannot tell you is whether
the account you typed is the right one; Step 2 is where that shows up, as a clone
command routed to the wrong host.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

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

Open it — the pointer file already carries the `runs/` segment, so it joins straight onto `repo-audit-reports/`:

```bash
LATEST_RUN="$(cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/post-image-restore.txt")"
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/restore-status.md"
```

> [!note]
> The pre-image inventory is what the script trusts. If a repo was created after Phase 2A ran, it won't appear here — clone it by hand later. If a repo was deleted after Phase 2A ran but is still in the TSV, the emitted clone command will re-create it; delete that line from `clone-commands.sh` in the next step.

> [!bug] Troubleshooting
> If the run stops with `REIMAGE_ARTIFACT_ROOT is not set or not a directory`, see [[#`bin/restore-repos.sh` exits with "REIMAGE_ARTIFACT_ROOT is not set or not a directory"|`bin/restore-repos.sh` exits with "REIMAGE_ARTIFACT_ROOT is not set or not a directory"]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Review the Emitted Clone Commands

The script emits `clone-commands.sh` alongside the report. Open and review it before running anything:

```bash
LATEST_RUN="$(cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/post-image-restore.txt")"
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/clone-commands.sh"
```

For each block, decide:

- **Keep** — the repo is still relevant. Leave the command as-is.
- **Skip** — the repo is archived or no longer needed. Delete the block or comment it out.
- **Redirect** — the pre-image parent directory no longer applies. Change the `cd` target to a new directory.
- **Reroute** — the URL uses the wrong host alias (rare — the script rewrites `git@github.com:` when routing to personal). Fix by hand.

> [!warning] Pitfall
> The script only rewrites `git@github.com:` when routing to the personal host. It leaves HTTPS URLs and non-github remotes alone. If the pre-image inventory shows an HTTPS clone URL, the resulting clone will use the OS keychain credential, not your restored SSH key — convert to SSH if that matters.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Execute the Clone Commands

Source `reimage.env` first so `$GIT_WORK_REPO_ROOT` and friends resolve, then run the reviewed clone script:

```bash
source ./reimage.env
bash "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/clone-commands.sh"
```

`clone-commands.sh` is written with `set -euo pipefail`, so the first `git clone` failure stops the batch and the clones above it stay done. Fix that repo — a stale remote URL is the usual cause — then delete the command blocks that already succeeded and rerun the tail.

> [!bug] Troubleshooting
> If the batch stops because a clone target directory already exists, see [[#`clone-commands.sh` stops at the first repo because the target directory already exists|`clone-commands.sh` stops at the first repo because the target directory already exists]].

**Cloning one repository by hand.** The batch is the normal path, but a single repo clones directly — proving the identity plumbing end to end, or picking up one you need before the rest are ready. Naming the destination rather than `cd`-ing into the root keeps the shell where it started, so a directory-scoped `direnv` does not unload `reimage.env` mid-block:

```bash
source ./reimage.env

REPO_PATH="replace-with-owner/repo"
git clone "git@${GIT_WORK_GITHUB_HOST}:${REPO_PATH}.git" "$GIT_WORK_REPO_ROOT/${REPO_PATH##*/}"
```

For a personal repo, both variables change:

```bash
source ./reimage.env

REPO_PATH="replace-with-owner/repo"
git clone "git@${GIT_PERSONAL_GITHUB_HOST}:${REPO_PATH}.git" "$GIT_PERSONAL_REPO_ROOT/${REPO_PATH##*/}"
```

**Which root a repo belongs in is decided by its remote host, not by where it lived pre-image.** A repository on the corporate Enterprise server belongs under `$GIT_WORK_REPO_ROOT` even if it sat in the personal directory before — an old directory named for its contents rather than an identity will have collected both. Clone one of those under the personal root and `includeIf` authors its commits with the personal address and `core.sshCommand` offers the personal key, which the Enterprise host rejects.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Repoint at the Cloned Toolkit

`clone-commands.sh` clones every repo from the pre-image inventory, and the
toolkit is one of them — it lives under `$GIT_PERSONAL_REPO_ROOT` like any other
personal repo. So the previous step has just produced a **second** copy of the
toolkit, and `$FRACTOGENESIS_HOME` still points at the first.

Left alone, that is a quiet trap: you read a runbook from one copy, edit it, and
commit from the other. Only the clone has `.git`, so only the clone can commit —
and only the bootstrap copy has `reimage.env`, so only the bootstrap copy can
run scripts. Neither is complete until you merge the two facts.

Capture the current root before anything repoints it. After the shell is
repointed the variable names the clone, and this is the only handle on the old
copy:

```bash
TOOLKIT_BOOTSTRAP="$FRACTOGENESIS_HOME"
TOOLKIT_CLONE="$GIT_PERSONAL_REPO_ROOT/fractogenesis-toolkit"
```

**1. Carry `reimage.env` across.** It is gitignored, so the clone does not have it:

```bash
cp "$TOOLKIT_BOOTSTRAP/reimage.env" "$TOOLKIT_CLONE/reimage.env"
```

**2. Repoint the shell.** `init-shell-env.sh` self-locates, so running it from the
clone rewrites the profile block to point there:

```bash
bash "$TOOLKIT_CLONE/bin/init-shell-env.sh"
```

**3. Approve `.envrc` in the clone.** direnv approval is per-path and per-content,
so the clone needs its own:

```bash
cd "$TOOLKIT_CLONE" && direnv allow
```

**4. Start a fresh login shell**, then confirm before removing the old copy:

```bash
exec zsh -l
```

After the new shell starts, confirm both facts before deleting anything:

```bash
echo "$FRACTOGENESIS_HOME"
echo "$REIMAGE_ARTIFACT_ROOT"
git -C "$FRACTOGENESIS_HOME" status --short
```

Only once all three hold:

```bash
rm -rf "$TOOLKIT_BOOTSTRAP"
```

> [!note]
> `TOOLKIT_BOOTSTRAP` was set in the block above and does not survive
> `exec zsh -l`. Set it again in the new shell — or just confirm the path by eye
> before removing anything, which is the safer habit for an `rm -rf` either way.

> [!warning] Pitfall
> Do the deletion last, and only after the checks pass. `reimage.env` exists in
> exactly one place on this Mac until step 1 lands — delete the bootstrap copy
> first and you have destroyed it, with the jump drive as your only remaining
> source.

> [!note]
> If direnv is already active from
> [[restore-runtime#Step 6 — Install direnv and Restore the Repo Environment Hook|Phase 10A Step 6]],
> the `~/.zprofile` bridge block has already been removed and step 2 above is
> unnecessary — `.envrc` in the clone sets `FRACTOGENESIS_HOME` on `cd`. Running
> it anyway is harmless but reintroduces a block you would then remove again.
> Full picture: [[references/toolkit-environment-reference|Toolkit Environment Reference]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Restore Staged Ignored Files

Two paths — pick the one you settled on in the pre-flight.

**Interactive path (preferred when you trust the reviewed set).** Rerun the script with `--apply-ignored-files`. It prompts Y/n per repo before rsyncing:

```bash
./bin/restore-repos.sh --apply-ignored-files
```

**Inspect-first path.** Open `rsync-ignored-files.sh` from the latest status bundle, review each block, and run selectively:

```bash
LATEST_RUN="$(cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/post-image-restore.txt")"
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/rsync-ignored-files.sh"
bash "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/rsync-ignored-files.sh"
```

> [!note]
> Kept ignored files that were routed to `secrets-encrypted/repos-gitignored/` by Phase 2A are *not* under `staged-ignored-files/live/` — they are inside the encrypted DMG and are restored by Step 6 below, which needs the image attached.

> [!bug] Troubleshooting
> If the interactive run reports a repo applied but the files are not in the working tree, see [[#`--apply-ignored-files` says "yes" but no files appear in the working tree|`--apply-ignored-files` says "yes" but no files appear in the working tree]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 6 — Restore Per-Repo Gitignored Secrets from the DMG

Phase 2A routed secret-shaped gitignored files — `.env`, `secrets/`, `gradle.properties` with real passwords — to `secrets-encrypted/repos-gitignored/<label>/` rather than to `staged-ignored-files/live/`, so the Phase 3C DMG would encrypt them. Step 5 does not touch those: they are inside the image, and until this step runs, every cloned repo is missing exactly the files it cannot start without.

Step 1 emitted `rsync-repos-gitignored.sh` alongside the other command files. It carries one guarded block per repo; blocks for repos the image does not carry skip themselves, so it is safe to run whole.

**1. Attach the secrets DMG** if it is not still mounted from Phase 10B. Capture the real mount point rather than globbing the filename — the volume name comes from `-volname` at build time:

```bash
DMG="$(ls -1 "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/"all-secrets-*.dmg | sort | tail -1)"
MNT="$(hdiutil attach "$DMG" | awk -F'\t' '/\/Volumes\//{print $NF}' | tail -1)"
echo "$MNT"
```

**2. Read the emitted commands before running them:**

```bash
cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/rsync-repos-gitignored.sh"
```

**3. Run it.** It locates the image itself by looking for `/Volumes/*/repos-gitignored`; set `DMG_MOUNT` explicitly if more than one image is attached:

```bash
bash "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/rsync-repos-gitignored.sh"
```

**4. Detach the image as soon as the copy finishes** — these are live credentials on a mounted volume:

```bash
hdiutil detach "$MNT"
```

**5. Trust any restored `.envrc`.** `direnv` blocks an `.envrc` it has not been told to trust, and does so silently as far as the shell is concerned:

```bash
cd "$GIT_WORK_REPO_ROOT/<repo>" && direnv allow
```

> [!warning] Pitfall
> The bundle label is `basename` of the repo path. Two repos sharing a basename across the work and personal roots collapse to one bundle, and the emitted script would copy it into both — potentially putting work credentials into a repo you push publicly. Check before running:
>
> ```bash
> cut -f1 "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/raw/repos-input.tsv" \
>   | xargs -n1 basename | sort | uniq -d
> ```
>
> Anything printed needs its two blocks reconciled by hand before you run the script.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 7 — Reconcile Rescue Branches

For each repo with `carry-forward rows > 0` in the status report, confirm the pre-image rescue branch made it onto the remote before reimage:

```bash
cd "$GIT_WORK_REPO_ROOT/<repo>"
git fetch origin 'refs/heads/reimage/*:refs/remotes/origin/reimage/*'
git branch -r | grep reimage/ || echo "no rescue branches found on remote"
```

For each rescue branch that shows up, choose one:

- **Merge back** into the intended branch:

  ```bash
  git checkout "<target-branch>"
  git merge "origin/reimage/YYYYMMDD/<name>"
  ```

- **Cherry-pick specific commits** when only some of the rescue-branch commits should land:

  ```bash
  git cherry-pick "<first-sha>..<last-sha>"
  ```

- **Leave as a branch** for later triage. Track that decision in the restore notes so it isn't forgotten.

> [!bug] Troubleshooting
> `no rescue branches found on remote` for a repo whose pre-image row shows carry-forward > 0 means Phase 2A's push step was skipped or failed for that repo. This is a real gap. Reconstruct from local backups if any exist; otherwise the carry-forward material is lost, and the row must be closed as "intentionally discarded" in the exit criteria.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 8 — Reconcile Stashes and Tracked Changes

Cross-check `raw/stashes-input.tsv` and `raw/tracked-changes-input.tsv` against the current state of each cloned repo. The pre-image push of a rescue branch typically covered these too, so they usually clear during the rescue-branch reconciliation. Anything still outstanding here is either:

- Material that was neither committed nor pushed to a rescue branch (real loss);
- A stash the operator intentionally decided not to preserve.

Note the intentional-discard cases in the restore notes.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 9 — Rerun the Status Report and Close the Exit Criteria

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
| Rescue branches accounted for | Manual | rescue-branch reconciliation outcome recorded per repo | Every repo with carry-forward > 0 closed as merged / cherry-picked / intentionally discarded |
| Personal repos route via personal SSH host alias | Manual | `git remote -v` in each personal clone | Remote uses `$GIT_PERSONAL_GITHUB_HOST` |

> [!bug] Troubleshooting
> If `git remote -v` in a personal clone prints the default `github.com` host, see [[#A repo cloned successfully but `git remote -v` shows the default `github.com` for a personal repo|A repo cloned successfully but `git remote -v` shows the default `github.com` for a personal repo]].

Once every row is closed, Phase 11B is complete and the workflow moves on to Phase 12.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script classifies and emits uniformly; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Which repositories in the pre-image inventory are still needed. | The script trusts the inventory verbatim; only you know which repos are archived, stale, or moved elsewhere. |
| Whether a rescue branch should be merged, cherry-picked, or left as a branch. | Depends on how much of the pre-image work is still relevant on the target branch — a call this runbook cannot make. |
| Whether a kept ignored file from the pre-image is still safe on the reimaged Mac. | Machine-specific paths, IDE settings, and env files may reference tooling that changed in Phase 10A. Review before blindly rsyncing every bundle. |
| Whether a carry-forward row with no matching rescue branch is a real loss or an intentional discard. | Only the operator knows which pre-image work was worth preserving; the script only reports the gap. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Four failures land here rather than inline: each either spans more than one step or has a fix long enough to break the flow of the step that surfaces it. The step that surfaces each one links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### `bin/restore-repos.sh` exits with "REIMAGE_ARTIFACT_ROOT is not set or not a directory"

The artifact volume is not mounted, or the environment was not loaded. `ls "$REIMAGE_ARTIFACT_ROOT"` and reconnect the drive.

[[#Step 1 — Produce the Initial Status Report|⮕ Continue to Step 1 — Produce the Initial Status Report]]

### `clone-commands.sh` stops at the first repo because the target directory already exists

`git clone` refuses to write into a non-empty directory. Either the repo was already restored by an earlier run of this workflow, or the target directory has stale content. Confirm which, delete the empty stub if that is the cause, then delete the command blocks that already succeeded and rerun the tail of the batch.

[[#Step 3 — Execute the Clone Commands|⮕ Continue to Step 3 — Execute the Clone Commands]]

### A repo cloned successfully but `git remote -v` shows the default `github.com` for a personal repo

The pre-image inventory recorded an HTTPS URL, so the script did not rewrite it to the personal host alias. Fix by hand:

```bash
git remote set-url origin "git@${GIT_PERSONAL_GITHUB_HOST}:<personal-username>/<repo>.git"
```

[[#Step 9 — Rerun the Status Report and Close the Exit Criteria|⮕ Continue to Step 9 — Rerun the Status Report and Close the Exit Criteria]]

### `--apply-ignored-files` says "yes" but no files appear in the working tree

`rsync -a` respects existing files with newer mtimes. If a clean clone already carries the file with a newer timestamp than the pre-image copy, rsync leaves it alone. Verify with `rsync --dry-run -av` before assuming loss.

[[#Step 5 — Restore Staged Ignored Files|⮕ Continue to Step 5 — Restore Staged Ignored Files]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Per-Repo Status Categories

| Column | Values | Meaning |
|---|---|---|
| `path_present` | `yes` / `no` | Whether the pre-image path currently exists as a `.git`-containing directory. |
| `ignored_files_available` | `yes` / `no` | Whether `staged-ignored-files/live/<label>/` exists for this repo. |
| `ignored_files_applied` | `unknown` / `yes` / `skipped` / `failed` | Result of the optional interactive rsync. `unknown` when the run did not use `--apply-ignored-files`. |
| `carry_forward_rows` | integer | Sum of `local_only_commit_count + stash_count + tracked_change_count` from the pre-image row. Rows requiring rescue-branch reconciliation. |
| `clone_host` | SSH host alias | Which `~/.ssh/config` `Host` entry the emitted clone command will use. |

### Reading the Pre-Image TSVs

Each pre-image TSV serves a different reconciliation step. The columns come from `.internal/git/capture-repo-audit.sh` and are stable across runs.

| File | Purpose in Phase 11B |
|---|---|
| `repos.tsv` | Master inventory. One row per repo; drives the classification loop. |
| `local-only-commits.tsv` | One row per unpushed commit. Cross-check after fetching rescue branches — every row should now be reachable from a `reimage/*` ref. |
| `stashes.tsv` | One row per stash. Same reconciliation as above; stashes typically ride along in the rescue branch as separate commits or a `WIP` note. |
| `tracked-changes.tsv` | One row per modified tracked file. Usually cleared by the rescue branch; anything remaining after that reconciliation is a real loss or an intentional discard. |
| `untracked-nonignored.tsv` | Informational. New files never `git add`-ed. Rarely worth preserving; handle case-by-case if the count is nonzero. |
| `ignored-files.tsv` | Informational. The full list of ignored files; the reviewed subset lives under `staged-ignored-files/live/`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link,
  except Troubleshooting, whose back-link sits under its intro and whose routed
  symptom subsections stay out of the Table of Contents.
-->
