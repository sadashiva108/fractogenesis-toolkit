[[reimaging-guide#Phase 2A — Backup Repositories|← Back to Mac Reimaging Guide]]

# Backup Repositories

This runbook owns the Git repository backup workflow before a Mac reimage.

It keeps the Git audit, local branch preservation, stash handling, `.gitignore` superset review, selected ignored-file dry runs, exclude list, and final selected ignored-file copy in one place.

It does not turn `repo-audit-reports/` into a full source backup, and it does not replace secret handling through `secrets-encrypted/` and the consolidated DMG workflow.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Preferred Scripted Workflow|Preferred Scripted Workflow]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Load Shared Configuration|Load Shared Configuration]]
    - [[#Run the Size Audit First|Run the Size Audit First]]
    - [[#Run the Repo Audit|Run the Repo Audit]]
    - [[#Back Up Repository State|Back Up Repository State]]
    - [[#Optional Direct Ignored-File Backup Script|Optional Direct Ignored-File Backup Script]]
    - [[#Collect the gitignore Superset|Collect the gitignore Superset]]
    - [[#Mark Selected Ignored Patterns|Mark Selected Ignored Patterns]]
    - [[#Create or Update the Exclude List|Create or Update the Exclude List]]
    - [[#Run the Selected Ignored-File Dry Run|Run the Selected Ignored-File Dry Run]]
    - [[#Run the Filtered Dry Run|Run the Filtered Dry Run]]
    - [[#Run the Final Selected Ignored-File Copy|Run the Final Selected Ignored-File Copy]]
    - [[#Review Output Files|Review Output Files]]
- [[#Manual Decisions That Remain Manual|Manual Decisions That Remain Manual]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

Use this workflow to preserve repository state and intentionally selected .gitignore local files before a Mac reimage.

Git remotes protect committed and pushed code, but they do not automatically protect:

```text
local-only commits
uncommitted tracked changes
stashes
untracked non-ignored files
ignored local configuration
ignored certificates or env files
workspace-level ignored files above nested module repos
```

This workflow has two goals:

```text
1. Preserve repository state.
2. Preserve intentionally selected .gitignore local files.
```

This guide does **not** own:

```text
full source backup through repo-audit-reports/
direct ignored-file copy as a substitute for secret handling through secrets-encrypted/ and the consolidated DMG workflow
manual publish/sync decisions about local branches, default-branch commits, stashes, or selected ignored files
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Primary script:

```text
bin/backup-repos.sh
```

Git backup artifacts are part of the standard shared generated-artifact layout:

```text
$REIMAGE_ARTIFACT_ROOT/
├── repo-audit-reports/
├── gitignore-superset/
├── selected-ignored-files/
├── selected-ignored-files-dryrun/
└── selected-ignored-files-filtered-dryrun/
```

Create or re-confirm the Git folders before running the scripts:

```bash
mkdir -p \
  "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports" \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset" \
  "$REIMAGE_ARTIFACT_ROOT/selected-ignored-files" \
  "$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-dryrun" \
  "$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-filtered-dryrun"
```

Folder purpose:

| Folder | Purpose                                                                               |
|---|---------------------------------------------------------------------------------------|
| `repo-audit-reports/` | Repo state reports; not a full source backup.                                         |
| `gitignore-superset/` | Reviewable superset of ignored patterns, selected-pattern template, and exclude list. |
| `selected-ignored-files-dryrun/` | First dry-run candidate output before exclusions.                                     |
| `selected-ignored-files-filtered-dryrun/` | Filtered dry-run output after `backup-exclude-list.txt`.                              |
| `selected-ignored-files/` | Final selected ignored/local file copy for restore.                                   |

Optional reusable local review files can live under:

```text
$REIMAGE_WORKSPACE_ROOT/gitignore-superset/
├── gitignore-review-template.txt
└── backup-exclude-list.txt
```

Use that workspace folder when you want to carry a previously reviewed template or exclude list forward to a later backup rerun without keeping the only copy on the external drive.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

Review these assumptions and reference notes before you run the workflow commands below.

### Prerequisites

This runbook assumes the external data/artifact volume, `$REIMAGE_ARTIFACT_ROOT`, standard generated-artifact folders, and `reimage.env` are already in place.

Required source-of-truth locations:

| Item | Location |
|---|---|
| Workflow docs and scripts | `$FRACTOGENESIS_HOME` |
| Generated Git artifacts | `$REIMAGE_ARTIFACT_ROOT` |
| Local machine-specific paths | `$FRACTOGENESIS_HOME/reimage.env` |
| Git repository root paths | `GIT_WORK_REPO_ROOT` and `GIT_PERSONAL_REPO_ROOT` in `reimage.env` |

Define the Git repository root paths during Phase 1 in [[prepare-backup-root#Step 3 Define Git Repository Roots|Prepare Backup and Capture Root — Step 3]] before starting this Git backup workflow.

```text
$FRACTOGENESIS_HOME/bin/         # entrypoints, e.g. backup-repos.sh
$FRACTOGENESIS_HOME/.internal/   # helpers, e.g. .internal/git/capture-repo-audit.sh
```

### Preferred Scripted Workflow

Use `backup-repos.sh` as the public Phase 2A entrypoint.

What it does by default:

- resolves Git roots from `reimage.env` or repeated `--root` flags
- refreshes the Git audit under `repo-audit-reports/`
- refreshes the gitignore superset under `gitignore-superset/`
- writes a stable summary at `$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/MANIFEST.md`

Later reviewed stages stay explicit and use the same entrypoint:

| Mode | Use when |
|---|---|
| default | Refresh the audit and gitignore superset before manual review. |
| `--selected-dry-run` | Generate the first selected ignored-file dry run after marking patterns in `gitignore-review-template.txt`. |
| `--selected-filtered-dry-run` | Re-run the selected dry run with `backup-exclude-list.txt` applied. |
| `--selected-copy` | Perform the final reviewed selected ignored-file copy. |
| `--direct-ignored-dry-run` | Optional broad ignored-file dry run without the selected-pattern review flow. |
| `--direct-ignored-copy` | Optional broad ignored-file copy without the selected-pattern review flow. |

Normal command path:

```bash
cd "$FRACTOGENESIS_HOME"
chmod +x bin/backup-repos.sh
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

Explicit-root override when you intentionally do not want the roots from `reimage.env`:

```bash
./bin/backup-repos.sh \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --root "$GIT_WORK_REPO_ROOT" \
  --root "$GIT_PERSONAL_REPO_ROOT" \
  --open
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Use this order for the runnable Git backup procedure, including the optional ignored-file branch when you need it.

### Load Shared Configuration

Source the local environment file before running the manual commands in this guide. Re-run this block any time you edit `reimage.env` in the same terminal session:

```bash
cd "$FRACTOGENESIS_HOME"
set -a
source ./reimage.env
set +a
```

The Git entrypoint script loads shared path handling through `.internal/load-reimage-config-snippet.sh`, which in turn sources `.internal/artifact-config.sh` and loads `reimage.env`. This keeps `REIMAGE_ARTIFACT_ROOT`, OneDrive, Office watcher, and Git-root path handling centralized instead of duplicated in each script.

Confirm the important paths:

```bash
printf 'FRACTOGENESIS_HOME=%s\n' "$FRACTOGENESIS_HOME"
printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
printf 'GIT_WORK_REPO_ROOT=%s\n' "${GIT_WORK_REPO_ROOT:-}"
printf 'GIT_PERSONAL_REPO_ROOT=%s\n' "${GIT_PERSONAL_REPO_ROOT:-}"
```

Confirm the shared config parses before running the Git workflow:

```bash
bash -n .internal/artifact-config.sh
```

The Git roots must exist before running the entrypoint. If a path does not exist, fix `reimage.env` before continuing.

### Run the Size Audit First

Run `capture-size-audit.sh` before refreshing Git artifacts when you want a quick destination-capacity check for the shared backup root.

This audit is still global to the Phase 2 backup root. It does **not** estimate the exact size of the Git audit reports or selected ignored-file copies, but it does confirm that the external destination volume is mounted and shows current destination headroom before you generate more artifacts.

```bash
cd "$FRACTOGENESIS_HOME"
bash -n bin/capture-size-audit.sh
./bin/capture-size-audit.sh
```

Review these lines in the output:

- `Target backup root`
- `Available on /Volumes/<drive>`
- `✓ External drive: enough space` or `✗ External drive: NOT ENOUGH SPACE`

### Run the Git Audit

Run from the workflow root. The default Phase 2A command refreshes both the audit and the gitignore superset so you can move directly into review.

```bash
cd "$FRACTOGENESIS_HOME"
set -a
source ./reimage.env
set +a

chmod +x bin/backup-repos.sh
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

The audit script writes the checklist-compatible report name:

```text
git-audit-summary-YYYYMMDD-HHMMSS.txt
```

It also writes the TSV evidence files:

```text
repos-YYYYMMDD-HHMMSS.tsv
tracked-changes-YYYYMMDD-HHMMSS.tsv
local-only-commits-YYYYMMDD-HHMMSS.tsv
stashes-YYYYMMDD-HHMMSS.tsv
untracked-nonignored-YYYYMMDD-HHMMSS.tsv
ignored-files-YYYYMMDD-HHMMSS.tsv
```


Important distinction:

| Report item | Meaning |
|---|---|
| `Uncommitted tracked changes` | Files already known to Git that are modified, added, deleted, renamed, or otherwise changed. These are also visible in `git status -sb`. |
| `Untracked non-ignored files` | Brand-new files that are not tracked by Git and are not excluded by `.gitignore`, `.git/info/exclude`, or global Git excludes. |
| `Ignored files reported by Git` | Brand-new files that are intentionally ignored and may need separate selected ignored-file backup review. |

A repo can have many modified files and still show `Untracked non-ignored files: 0`. That is expected when all local work is on files Git already tracks. Review `Uncommitted tracked changes` and `tracked-changes-*.tsv` for those files.

Confirm the checklist-facing summary exists:

```bash
ls -1t "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports"/git-audit-summary-*.txt | head -3
```

Review the newest report:

```bash
LATEST_GIT_AUDIT="$(ls -1t "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports"/git-audit-summary-*.txt | head -1)"
printf 'LATEST_GIT_AUDIT=%s\n' "$LATEST_GIT_AUDIT"
open "$LATEST_GIT_AUDIT"
```

Optional explicit-root variant. Use this only when you want to override the roots from `reimage.env`:

```bash
./bin/backup-repos.sh \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --root "$GIT_WORK_REPO_ROOT" \
  --root "$GIT_PERSONAL_REPO_ROOT" \
  --open
```

Look for:

```text
uncommitted tracked changes / dirty working trees
local-only commits
stashes
untracked non-ignored files
ignored files that may need backup
repos with no remote
repos on temporary branches
upstream/tracking branch problems
```

### Back Up Git Repository State

#### Existing feature branch

```bash
git switch <branch-name>
git status
git push -u origin HEAD
```

#### Uncommitted tracked work

These are files that appear in the audit under `Uncommitted tracked changes` or in `tracked-changes-YYYYMMDD-HHMMSS.tsv`. They are not counted as `Untracked non-ignored files` because Git already knows about them.

Review the exact changes first:

```bash
git status -sb
git diff --stat
git diff
```

If the changes should be preserved as a temporary backup branch:

```bash
git switch -c backup/pre-reimage-YYYYMMDD
git add -A
git commit -m "WIP backup before computer reimage"
git push -u origin HEAD
```

#### Local commits on the default branch that should not go to the remote default branch

Use the branch name from the repo instead of assuming every repo uses `master`:

```bash
DEFAULT_BRANCH="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-${GIT_DEFAULT_BRANCH:-master}}"

git switch "$DEFAULT_BRANCH"
git branch "backup/pre-reimage-YYYYMMDD"
git push -u origin "backup/pre-reimage-YYYYMMDD"
```

#### Stashes

```bash
git stash list
git stash branch backup/pre-reimage-stash-YYYYMMDD stash@{0}
git add -A
git commit -m "WIP backup from stash before computer reimage"
git push -u origin HEAD
```

#### Untracked non-ignored files

These are brand-new files that Git is not tracking and that are not ignored. They appear in `untracked-nonignored-YYYYMMDD-HHMMSS.tsv`.

For files shown as untracked but not ignored:

```text
commit them
copy them intentionally
add them to selected ignored-file backup if appropriate
delete them if they are not needed
```

### Optional Direct Ignored-File Backup Script

The selected-pattern workflow below remains the preferred path because it forces review through `gitignore-review-template.txt` and `backup-exclude-list.txt` before anything is copied.

Use the direct ignored-file mode only when you intentionally want a broad dry run or copy of Git-ignored files without the selected-pattern review flow.

Dry run using roots from `reimage.env`:

```bash
cd "$FRACTOGENESIS_HOME"
chmod +x bin/backup-repos.sh
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --direct-ignored-dry-run
```

Copy using roots from `reimage.env` only after reviewing the dry run:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --direct-ignored-copy
```

Do not use the direct ignored-file mode as a shortcut around secret review. Ignored files may include `.env.local`, keys, certificates, keystores, or local credentials that should be handled through `secrets-encrypted/` and the consolidated DMG workflow.

### Collect the gitignore Superset

The default Phase 2A command already refreshes the gitignore superset. Rerun the same entrypoint whenever you want a fresh template after Git-root or ignore-rule changes.

```bash
cd "$FRACTOGENESIS_HOME"
chmod +x bin/backup-repos.sh
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT"
```

If you already have a previously reviewed template saved under `REIMAGE_WORKSPACE_ROOT`, copy it over the freshly generated backup-root copy before you start editing:

```bash
mkdir -p "$REIMAGE_WORKSPACE_ROOT/gitignore-superset"

cp -p \
  "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/gitignore-review-template.txt" \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt"
```

After copying it in, still review it against the newly generated superset for this run. New repos or changed ignore rules may mean the previous selection is no longer complete.

If you prefer to keep the newly generated default template as a reusable workspace starting point, copy it there now:

```bash
mkdir -p "$REIMAGE_WORKSPACE_ROOT/gitignore-superset"

cp -p \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt" \
  "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/gitignore-review-template.txt"
```

Review:

```bash
open "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt"
```

### Mark Selected Ignored Patterns

In:

```text
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt
```

Change entries from:

```text
[ ] .env.local
```

to:

```text
[x] .env.local
```

Review carefully:

```text
.env
.env.local
.env.test
*.pem
*.key
*.p12
*.jks
*.keystore
application-local.yml
application-credentials.yml
credentials.yml
credentials.json
http-client.env.json
http-client.private.env.json
*.env.json
.idea/httpRequests/
```

Credential-bearing selected files should eventually be inside the encrypted secrets DMG, not loose in cloud storage.

If you update the template during this run and want to keep that version for reuse on a later rerun, copy it back into the workspace:

```bash
mkdir -p "$REIMAGE_WORKSPACE_ROOT/gitignore-superset"

cp -p \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt" \
  "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/gitignore-review-template.txt"
```

### Create or Update the Exclude List

Choose one starting point:

Reuse a previously configured workspace copy:

```bash
mkdir -p "$REIMAGE_WORKSPACE_ROOT/gitignore-superset"

cp -p \
  "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/backup-exclude-list.txt" \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/backup-exclude-list.txt"
```

Or create/edit a fresh file directly under the backup root:

```bash
touch "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/backup-exclude-list.txt"
```

Common exclusions:

```text
node_modules/
build/
target/
.gradle/
.cache/
.venv/
.venv313/
.venv314/
.idea/httpRequests/http-requests-log.http
.idea/shelf/
**/.idea/httpRequests/**
```

Do not use the exclude list for files that should be backed up securely. Use it for generated, cache, dependency, build-output, or high-noise folders that are not useful after restore.

If you copied in an older workspace version, review it against the current dry-run results before assuming every old exclusion still makes sense.

If you update the exclude list during this run and want to reuse it later, copy it back into the workspace:

```bash
mkdir -p "$REIMAGE_WORKSPACE_ROOT/gitignore-superset"

cp -p \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/backup-exclude-list.txt" \
  "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/backup-exclude-list.txt"
```

### Run the Selected Ignored-File Dry Run

This first pass shows selected candidates before applying the exclude list.

```bash
cd "$FRACTOGENESIS_HOME"
chmod +x bin/backup-repos.sh
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-dry-run --open
```

Review:

```bash
open "$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-dryrun"
```

### Run the Filtered Dry Run

This pass applies `backup-exclude-list.txt` and should be reviewed before copying files.

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-filtered-dry-run --open
```

Review:

```bash
open "$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-filtered-dryrun"
```

Confirm excluded files moved from candidates to excluded output when applicable.

### Run the Final Selected Ignored-File Copy

Only run `--copy` after the dry run and filtered dry run are reviewed.

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-copy
```

### Review Output Files

Review these before final validation:

```text
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/git-audit-summary-YYYYMMDD-HHMMSS.txt
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/repos-YYYYMMDD-HHMMSS.tsv
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/tracked-changes-YYYYMMDD-HHMMSS.tsv
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/local-only-commits-YYYYMMDD-HHMMSS.tsv
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/stashes-YYYYMMDD-HHMMSS.tsv
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/untracked-nonignored-YYYYMMDD-HHMMSS.tsv
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/ignored-files-YYYYMMDD-HHMMSS.tsv
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/backup-exclude-list.txt
$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-dryrun/
$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-filtered-dryrun/
$REIMAGE_ARTIFACT_ROOT/selected-ignored-files/
```

Look for:

```text
copy-failed.tsv
copied.tsv
excluded.tsv
summary.txt
unexpected secrets outside secrets-encrypted/
large generated folders that should have been excluded
```

Before copying anything to cloud storage, review any selected ignored files that might contain credentials. Credential-bearing files should be encrypted or restored from an approved password manager / encrypted backup path.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Manual Decisions That Remain Manual

| Decision | Why |
|---|---|
| Whether to push a local branch | Requires knowing whether the branch is safe to publish. |
| Whether local default-branch commits should become a backup branch | Prevents accidental push to the remote default branch. |
| Whether a stash is important | Script can list stashes, not judge usefulness. |
| Which `.gitignore` patterns should be backed up | Requires project knowledge. |
| Whether a selected ignored file is a secret | Requires content review before cloud sync. |
| Whether a repo root should be included | Requires knowing the current Mac's local workspace layout. |

[[#Table of Contents|⬆ Back to Table of Contents]]
