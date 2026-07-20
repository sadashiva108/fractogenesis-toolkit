[[reimaging-guide#Phase 2A — Backup Repositories|← Back to Mac Reimaging Guide]]

# Backup Repositories

This runbook owns the backup repositories workflow before a Mac reimage.

It keeps the repo audit, local branch preservation, stash handling, `.gitignore` superset review, selected ignored-file dry runs, exclude list, and final selected ignored-file copy in one place.

It does not turn `repo-audit-reports/` into a full source backup, and it does not replace secret handling through `secrets-encrypted/` and the consolidated DMG workflow.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Size Audit Report Layout|Size Audit Report Layout]]
    - [[#Repository Audit Run Layout|Repository Audit Run Layout]]
    - [[#Gitignore Superset Outputs at a Glance|Gitignore Superset Outputs at a Glance]]
    - [[#Preferred Scripted Workflow|Preferred Scripted Workflow]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Load Shared Configuration|Load Shared Configuration]]
    - [[#Run the Size Audit First|Run the Size Audit First]]
    - [[#Run the Repo Audit|Run the Repo Audit]]
    - [[#Back Up Git Repository State|Back Up Git Repository State]]
    - [[#Optional Direct Ignored-File Backup Script|Optional Direct Ignored-File Backup Script]]
    - [[#Collect the gitignore Superset|Collect the gitignore Superset]]
    - [[#Mark Selected Ignored Patterns|Mark Selected Ignored Patterns]]
    - [[#Create or Update the Exclude List|Create or Update the Exclude List]]
    - [[#Run the Selected Ignored-File Dry Run|Run the Selected Ignored-File Dry Run]]
    - [[#Run the Filtered Dry Run|Run the Filtered Dry Run]]
    - [[#Run the Final Selected Ignored-File Copy|Run the Final Selected Ignored-File Copy]]
    - [[#Review Output Files|Review Output Files]]
- [[#Manual Decisions That Remain Manual|Manual Decisions That Remain Manual]]
- [[#Appendix A — Gitignore Superset Generated Files|Appendix A — Gitignore Superset Generated Files]]
    - [[#How the Superset Files Are Generated|How the Superset Files Are Generated]]
    - [[#Recommended Review Order|Recommended Review Order]]
    - [[#Generated File Reference|Generated File Reference]]
    - [[#TSV Column Reference|TSV Column Reference]]
- [[#Appendix B — Known Gaps and Future Considerations|Appendix B — Known Gaps and Future Considerations]]
  - [[#Secret-Shaped Selected Ignored Files Are Not Automatically Flagged|Secret-Shaped Selected Ignored Files Are Not Automatically Flagged]]
  - [[#Gitignore Superset Refresh Has No Automated Diff|Gitignore Superset Refresh Has No Automated Diff]]

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
$FRACTOGENESIS_HOME/bin/backup-repos.sh
```

Git backup artifacts are part of the standard shared generated-artifact layout:

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── gitignore-superset/
│   ├── summary.txt
│   ├── gitignore-files.tsv
│   ├── gitignore-files-review.txt
│   ├── gitignore-concatenated-with-sources.txt
│   ├── gitignore-patterns-all.tsv
│   ├── gitignore-patterns-all-review.txt
│   ├── gitignore-patterns-superset.txt
│   ├── gitignore-patterns-superset-with-counts.tsv
│   ├── gitignore-pattern-sources.tsv
│   ├── gitignore-pattern-sources-review.txt
│   ├── gitignore-review-template.txt
│   └── backup-exclude-list.txt
├── repo-audit-reports/
│   ├── MANIFEST.md
│   ├── latest-run.txt
│   └── runs/
│       ├── pre-image-YYYYMMDD-HHMMSS/
│       │   ├── repo-audit-summary.txt
│       │   ├── repos.tsv
│       │   ├── tracked-changes.tsv
│       │   ├── local-only-commits.tsv
│       │   ├── stashes.tsv
│       │   ├── untracked-nonignored.tsv
│       │   └── ignored-files.tsv
│       └── post-image-YYYYMMDD-HHMMSS/
│           └── ...
├── size-audit-reports/
│   ├── MANIFEST.md
│   ├── latest-run.txt
│   └── runs/
│       ├── pre-image-backup-repos-YYYYMMDD-HHMMSS/
│       │   └── size-audit-report.txt
│       └── post-image-backup-repos-YYYYMMDD-HHMMSS/
│           └── ...
├── staged-ignored-files/
│   ├── dryrun/
│   │   ├── summary.txt
│   │   ├── candidates.tsv
│   │   └── excluded.tsv
│   ├── dryrun-filtered/
│   │   ├── summary.txt
│   │   ├── candidates.tsv
│   │   └── excluded.tsv
│   └── live/
│       ├── summary.txt
│       ├── candidates.tsv
│       ├── excluded.tsv
│       ├── copied.tsv
│       ├── copy-failed.tsv
│       └── <repo-label>/
│           └── <relative-path-within-repo>
└── ...
```

The following top-level containers are assumed to have already been created
by `prepare-artifact-root.md`'s standard artifact-root layout:

- `size-audit-reports/`
- `repo-audit-reports/`
- `gitignore-superset/`
- `staged-ignored-files/` (the folder itself, not its children)

This runbook does not create them.

`bin/backup-repos.sh` checks three of these on startup:

- `repo-audit-reports/`
- `gitignore-superset/`
- `staged-ignored-files/`

If any are missing, it exits with an error pointing back to
`prepare-artifact-root.md` rather than silently creating them. If you see
that error, either run that runbook first or confirm
`REIMAGE_ARTIFACT_ROOT` points at the right location.

`staged-ignored-files/dryrun/`, `dryrun-filtered/`, and `live/` are
different — those are child directories owned by this runbook's own
scripts, not by `prepare-artifact-root.md`, so `bin/backup-repos.sh` creates
them itself on startup instead of treating their absence as a prerequisite
error.

> `size-audit-reports/` isn't checked by `bin/backup-repos.sh` directly —
> it's provisioned independently by `capture-size-audit.sh` — but it's
> listed above since "Run the Size Audit First" is now the first step in
> this runbook's Sequential Steps.


Folder purpose:

| Folder | Purpose                                                                               |
|---|---------------------------------------------------------------------------------------|
| `size-audit-reports/` | Append-only backup-size-audit index, latest-run pointer, and self-contained timestamped run directories with the full colorized report. |
| `repo-audit-reports/` | Append-only repository-audit index, latest-run pointer, and self-contained timestamped run directories; not a full source backup. |
| `gitignore-superset/` | Reviewable superset of ignored patterns, selected-pattern template, and exclude list. |
| `staged-ignored-files/dryrun/` | First dry-run candidate output before exclusions.                                     |
| `staged-ignored-files/dryrun-filtered/` | Filtered dry-run output after `backup-exclude-list.txt`.                              |
| `staged-ignored-files/live/` | Final selected ignored/local file copy for restore.                                   |

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

Define the Git repository root paths during Phase 1 in [[prepare-artifact-root#Step 3 Define Git Repository Roots|Prepare Backup and Capture Root — Step 3]] before starting this Git backup workflow.

```text
$FRACTOGENESIS_HOME/bin/         # entrypoints, e.g. backup-repos.sh
$FRACTOGENESIS_HOME/.internal/   # helpers, e.g. .internal/git/capture-repo-audit.sh
```

### Size Audit Report Layout

Each successful size audit is stored as one self-contained run directory. The
directory name owns the context and timestamp; the report inside uses a
stable name.

```text
$REIMAGE_ARTIFACT_ROOT/size-audit-reports/
├── MANIFEST.md
├── latest-run.txt
└── runs/
    ├── pre-image-backup-repos-YYYYMMDD-HHMMSS/
    │   └── size-audit-report.txt
    └── post-image-restore-repos-YYYYMMDD-HHMMSS/
        └── ...
```

`capture-size-audit.sh` defaults to `--context pre-image` but instead use the more descriptive `--context pre-image-backup-repos` since other pre-image phases run this script. Pass
`--context post-image-restore-repos` for a later comparison run.

`MANIFEST.md` is an append-only index of successful runs; `latest-run.txt`
contains one relative run path and is updated only after a run completes
successfully — same contract as `repo-audit-reports/`.

The saved report keeps its original ANSI color codes on purpose, so the same
yellow/red/green severity cues read the same way later. Text editors such as
VS Code or IntelliJ render the raw escape codes as literal characters instead
of color — view the report in a terminal instead:

```bash
AUDIT_ROOT="$REIMAGE_ARTIFACT_ROOT/size-audit-reports"
LATEST_RUN_RELATIVE="$(cat "$AUDIT_ROOT/latest-run.txt" 2>/dev/null || true)"
less -R "$AUDIT_ROOT/$LATEST_RUN_RELATIVE/size-audit-report.txt"
```


### Repository Audit Run Layout

Each successful repository audit is stored as one self-contained run directory. The directory name owns the context and timestamp; files inside the run use stable names without repeated timestamps.

```text
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/
├── MANIFEST.md
├── latest-run.txt
└── runs/
    ├── pre-image-YYYYMMDD-HHMMSS/
    │   ├── repo-audit-summary.txt
    │   ├── repos.tsv
    │   ├── tracked-changes.tsv
    │   ├── local-only-commits.tsv
    │   ├── stashes.tsv
    │   ├── untracked-nonignored.tsv
    │   └── ignored-files.tsv
    └── post-image-YYYYMMDD-HHMMSS/
        └── ...
```

`backup-repos.sh` is the Phase 2A pre-image entrypoint, so it creates `pre-image-...` runs. A standalone invocation of `.internal/git/capture-repo-audit.sh --context post-image` creates a `post-image-...` run when a later comparison is intentionally needed.

`MANIFEST.md` is an append-only index of successful audits. Selected ignored-file dry runs and copies do not rewrite it. `latest-run.txt` contains one relative run path, such as `runs/pre-image-20260714-221500`, and is updated only after a run completes successfully.

The current workflow does not read flat timestamped audit files. If `repo-audit-reports/MANIFEST.md` contains the former single-run summary format, remove it before the first run with the current scripts.

### Gitignore Superset Outputs at a Glance

The default repo-backup refresh creates two kinds of gitignore evidence under `$REIMAGE_ARTIFACT_ROOT/gitignore-superset/`:

| Output type | Purpose |
|---|---|
| Machine-readable TSV files | Preserve complete, sortable provenance for scripts, spreadsheets, `awk`, `cut`, and later analysis. |
| Human-readable review files | Present the same information in grouped sections that are easier to inspect in a text editor. |

Start with `summary.txt`, then review `gitignore-files-review.txt` and `gitignore-pattern-sources-review.txt`. Use `gitignore-concatenated-with-sources.txt` when you need the original file context, and make backup selections only in `gitignore-review-template.txt`.

The TSV files intentionally remain tab-delimited and are not padded with decorative spacing. See [[#Appendix A — Gitignore Superset Generated Files|Appendix A — Gitignore Superset Generated Files]] for the complete file descriptions, generation flow, column definitions, and review order.

### Preferred Scripted Workflow

Use `backup-repos.sh` as the public Phase 2A entrypoint.

What it does by default:

- resolves Git roots from `reimage.env` or repeated `--root` flags
- creates a self-contained `repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/` audit run
- appends the successful run to `repo-audit-reports/MANIFEST.md`
- updates `repo-audit-reports/latest-run.txt` to the newest successful run
- refreshes the gitignore superset under `gitignore-superset/`

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

The Git entrypoint script loads shared path handling through `.internal/load-reimage-config.sh`, which in turn sources `.internal/artifact-config.sh` and loads `reimage.env`. This keeps `REIMAGE_ARTIFACT_ROOT`, OneDrive, Office watcher, and Git-root path handling centralized instead of duplicated in each script.

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
./bin/capture-size-audit.sh --context pre-image-backup-repos
```

Review these lines in the output:

- `Target backup root`
- `Available on /Volumes/<drive>`
- `✓ External drive: enough space` or `✗ External drive: NOT ENOUGH SPACE`

The saved report keeps its original ANSI color codes so the severity colors
match what you saw on screen. See [[#Size Audit Report Layout|Size Audit Report Layout]]
below for the run directory structure and how to view it.

### Run the Repo Audit

Run from the workflow root. The default Phase 2A command refreshes both the audit and the gitignore superset so you can move directly into review.

```bash
cd "$FRACTOGENESIS_HOME"
set -a
source ./reimage.env
set +a

chmod +x bin/backup-repos.sh
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

The audit creates one prefixed run directory:

```text
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/
```

The timestamp and context are carried by the directory name. Inside the run, filenames are stable:

```text
repo-audit-summary.txt
repos.tsv
tracked-changes.tsv
local-only-commits.tsv
stashes.tsv
untracked-nonignored.tsv
ignored-files.tsv
```

After the run succeeds, the helper appends one row to `repo-audit-reports/MANIFEST.md` and updates `repo-audit-reports/latest-run.txt`. Failed or interrupted runs are not added to the manifest and do not replace the latest-run pointer.

Important distinction:

| Report item | Meaning |
|---|---|
| `Uncommitted tracked changes` | Files already known to Git that are modified, added, deleted, renamed, or otherwise changed. These are also visible in `git status -sb`. |
| `Untracked non-ignored files` | Brand-new files that are not tracked by Git and are not excluded by `.gitignore`, `.git/info/exclude`, or global Git excludes. |
| `Ignored files reported by Git` | Brand-new files that are intentionally ignored and may need separate selected ignored-file backup review. |

A repo can have many modified files and still show `Untracked non-ignored files: 0`. That is expected when all local work is on files Git already tracks. Review `Uncommitted tracked changes` and `tracked-changes.tsv` in that run directory for those files.

Confirm the append-only manifest and latest-run pointer exist:

```bash
AUDIT_ROOT="$REIMAGE_ARTIFACT_ROOT/repo-audit-reports"
test -f "$AUDIT_ROOT/MANIFEST.md" && echo "PASS: manifest exists"
test -f "$AUDIT_ROOT/latest-run.txt" && echo "PASS: latest-run pointer exists"
```

Review the newest report safely:

```bash
AUDIT_ROOT="$REIMAGE_ARTIFACT_ROOT/repo-audit-reports"
LATEST_RUN_RELATIVE="$(cat "$AUDIT_ROOT/latest-run.txt" 2>/dev/null || true)"

case "$LATEST_RUN_RELATIVE" in
  runs/pre-image-*|runs/post-image-*) ;;
  *)
    printf 'ERROR: invalid latest-run pointer: %s\n' "${LATEST_RUN_RELATIVE:-<empty>}" >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

case "$LATEST_RUN_RELATIVE" in
  *..*|/*)
    printf 'ERROR: unsafe latest-run pointer: %s\n' "$LATEST_RUN_RELATIVE" >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

LATEST_REPO_AUDIT="$AUDIT_ROOT/$LATEST_RUN_RELATIVE/repo-audit-summary.txt"
if [[ ! -f "$LATEST_REPO_AUDIT" ]]; then
  printf 'ERROR: latest repository audit was not found: %s\n' "$LATEST_REPO_AUDIT" >&2
  return 1 2>/dev/null || exit 1
fi

printf 'LATEST_REPO_AUDIT=%s\n' "$LATEST_REPO_AUDIT"
open "$LATEST_REPO_AUDIT"
```

This guarded lookup prevents an empty `open` command from opening the current Finder directory when no report was found.

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

These are files that appear in the audit under `Uncommitted tracked changes` or in `tracked-changes.tsv` in the selected audit run. They are not counted as `Untracked non-ignored files` because Git already knows about them.

Review the exact changes first:

```bash
git status -sb
git diff --stat
git diff
```

If the changes should be preserved as a temporary backup branch, use the canonical branch structure:

```text
reimage/YYYYMMDD/reason
```

`wip` means **work in progress** and is the safe default when the purpose is unclear.

| Situation | Recommended branch |
|---|---|
| Purpose is unclear | `reimage/YYYYMMDD/wip` |
| Known ticket or feature | `reimage/YYYYMMDD/TICKET-short-description` |
| Local commits on the default branch | `reimage/YYYYMMDD/default-branch-commits` |
| First stash | `reimage/YYYYMMDD/stash-0` |
| Second general backup on the same day | `reimage/YYYYMMDD/wip-2` |

Safe default:

```bash
BACKUP_BRANCH="reimage/$(date +%Y%m%d)/wip"

git switch -c "$BACKUP_BRANCH"
git add -A
git commit -m "Preserve work in progress before computer reimage"
git push -u origin "$BACKUP_BRANCH"
```

When the purpose is known, replace `wip` with a short ticket or feature description:

```bash
BACKUP_BRANCH="reimage/$(date +%Y%m%d)/<ticket-or-short-purpose>"
```

#### Local commits on the default branch that should not go to the remote default branch

Use the branch name from the repo instead of assuming every repo uses `master`:

```bash
DEFAULT_BRANCH="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-${GIT_DEFAULT_BRANCH:-master}}"

BACKUP_BRANCH="reimage/$(date +%Y%m%d)/default-branch-commits"

git switch "$DEFAULT_BRANCH"
git branch "$BACKUP_BRANCH"
git push -u origin "$BACKUP_BRANCH"
```

#### Stashes

```bash
git stash list

BACKUP_BRANCH="reimage/$(date +%Y%m%d)/stash-0"
git stash branch "$BACKUP_BRANCH" 'stash@{0}'
git add -A
git commit -m "Preserve stashed work before computer reimage"
git push -u origin "$BACKUP_BRANCH"
```

#### Untracked non-ignored files

These are brand-new files that Git is not tracking and that are not ignored. They appear in `untracked-nonignored.tsv` in the selected audit run.

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

For a file-by-file explanation of the generated superset evidence, use [[#Appendix A — Gitignore Superset Generated Files|Appendix A — Gitignore Superset Generated Files]].

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
open "$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/dryrun"
```

### Run the Filtered Dry Run

This pass applies `backup-exclude-list.txt` and should be reviewed before copying files.

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-filtered-dry-run --open
```

Review:

```bash
open "$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/dryrun-filtered"
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
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/MANIFEST.md
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/latest-run.txt
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/repo-audit-summary.txt
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/repos.tsv
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/tracked-changes.tsv
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/local-only-commits.tsv
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/stashes.tsv
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/untracked-nonignored.tsv
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/ignored-files.tsv
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/summary.txt
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-files.tsv
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-files-review.txt
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-patterns-all.tsv
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-patterns-all-review.txt
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-pattern-sources.tsv
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-pattern-sources-review.txt
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-concatenated-with-sources.txt
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/backup-exclude-list.txt
$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/dryrun/
$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/dryrun-filtered/
$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live/
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

Use [[#Appendix A — Gitignore Superset Generated Files|Appendix A — Gitignore Superset Generated Files]] when you need to interpret a gitignore superset output or understand how one file was derived from another.

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

---

## Appendix A — Gitignore Superset Generated Files

This appendix documents the stable evidence written by `.internal/git/collect-gitignore-superset.sh` under:

```text
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/
```

The collector scans the configured Git roots from `GIT_WORK_REPO_ROOT`, `GIT_PERSONAL_REPO_ROOT`, or repeated `--root` overrides. It discovers ignore sources, records their provenance, extracts active patterns, creates aggregate views, and writes the selection template used by the later selected ignored-file stages.

The TSV files are the machine-readable source of truth. The `*-review.txt` files and the concatenated text file are human-readable views derived from those TSV records and source files.

### How the Superset Files Are Generated

```text
Configured Git roots
    │
    ├── discover .gitignore files
    ├── optionally discover .git/info/exclude
    └── optionally include global Git excludes
            │
            ▼
    gitignore-files.tsv
            │
            ├── gitignore-files-review.txt
            └── gitignore-concatenated-with-sources.txt
            │
            ▼
    extract every nonblank, non-comment pattern occurrence
            │
            ▼
    gitignore-patterns-all.tsv
            │
            ├── gitignore-patterns-all-review.txt
            ├── gitignore-patterns-superset.txt
            ├── gitignore-patterns-superset-with-counts.tsv
            ├── gitignore-pattern-sources.tsv
            ├── gitignore-pattern-sources-review.txt
            └── gitignore-review-template.txt
```

The collector preserves negated patterns such as `!example.env`, removes surrounding whitespace for the normalized value, preserves the original source line in `raw_pattern`, and omits blank lines and full-line comments from the pattern datasets.

### Recommended Review Order

1. Open `summary.txt` for the roots scanned, counts, output paths, and next step.
2. Open `gitignore-files-review.txt` to confirm the expected ignore sources were discovered.
3. Open `gitignore-pattern-sources-review.txt` to see which patterns are shared across multiple source files.
4. Open `gitignore-concatenated-with-sources.txt` when a pattern needs its original surrounding comments or file context.
5. Use `gitignore-patterns-all-review.txt` when you need exact source line numbers.
6. Mark only intentionally preserved patterns in `gitignore-review-template.txt`.
7. Run the selected ignored-file dry run and review its candidate output before copying anything.

The TSV files are most useful for sorting, filtering, spreadsheet import, scripted checks, and deeper troubleshooting. The review text files are intended for normal manual inspection.

### Generated File Reference

| File | Represents | How it is generated | Primary use |
|---|---|---|---|
| `summary.txt` | Run-level overview, roots scanned, counts, output paths, and suggested review order. | Written after all source and pattern datasets are complete. | Start here after every refresh. |
| `gitignore-files.tsv` | One row for every discovered ignore source. | The collector finds `.gitignore` files under each configured scan root and optionally adds repository and global exclude files; rows are deduplicated and sorted by source kind and path. | Machine-readable source inventory and provenance. |
| `gitignore-files-review.txt` | A grouped, readable rendering of `gitignore-files.tsv`. | Each TSV row is expanded into labeled fields such as source path, nearest Git root, scan root, and relative paths. | Confirm the collector found the expected source files. |
| `gitignore-concatenated-with-sources.txt` | The exact contents of all discovered ignore sources with structured provenance headings. | Sources are processed in the deterministic order recorded by `gitignore-files.tsv`; the original file content is copied between begin/end markers. | Review surrounding comments and source-file context without opening each file separately. |
| `gitignore-patterns-all.tsv` | Every active pattern occurrence, including duplicates, source path, and source line number. | Blank lines and full-line comments are skipped. Each remaining line is recorded with both normalized and raw values plus source provenance. | Authoritative detailed pattern provenance. |
| `gitignore-patterns-all-review.txt` | Patterns grouped by source file and displayed with line numbers. | Derived from `gitignore-patterns-all.tsv` in source-path and line-number order. | Human review of exact pattern occurrences. |
| `gitignore-patterns-superset.txt` | One sorted copy of each unique normalized pattern. | The normalized pattern column from `gitignore-patterns-all.tsv` is deduplicated and sorted. | Compact complete pattern list. |
| `gitignore-patterns-superset-with-counts.tsv` | Unique normalized patterns with total occurrence counts. | Patterns are grouped and counted across all rows in `gitignore-patterns-all.tsv`. | Find common or repeated patterns. |
| `gitignore-pattern-sources.tsv` | One row per unique normalized pattern, with the number of distinct source files and the combined source list. | Pattern/source pairs from `gitignore-patterns-all.tsv` are deduplicated, aggregated, and sorted by descending source count and then pattern. | Machine-readable pattern-to-source summary. |
| `gitignore-pattern-sources-review.txt` | A readable pattern-to-source report. | Each row from `gitignore-pattern-sources.tsv` is expanded into a pattern heading and one source path per line. | Quickly understand where a pattern is used. |
| `gitignore-review-template.txt` | The actionable checklist of unique patterns using `[ ]` and `[x]` markers. | Each unique pattern from `gitignore-patterns-superset.txt` is written as an unchecked entry. | Select patterns for the reviewed ignored-file dry run. |
| `backup-exclude-list.txt` | Manual exclusions applied after selecting patterns. | Created or maintained by the operator; it is not regenerated by the collector. | Remove generated, cache, dependency, or otherwise unwanted matches from later staging. |

#### The Four Core Provenance Files

`gitignore-files.tsv` answers:

```text
Which ignore files were discovered, and where do they sit relative to a Git repo and configured scan root?
```

`gitignore-patterns-all.tsv` answers:

```text
What active pattern occurred on which exact line of which source file?
```

`gitignore-pattern-sources.tsv` answers:

```text
For each unique pattern, how many distinct ignore sources use it, and which sources are they?
```

`gitignore-concatenated-with-sources.txt` answers:

```text
What did every original ignore source contain, including comments and surrounding context?
```

### TSV Column Reference

#### `gitignore-files.tsv`

| Column | Meaning |
|---|---|
| `kind` | Source classification: `gitignore`, `git_info_exclude`, `global_git_ignore`, or `ignore_file`. |
| `source_path` | Absolute path to the discovered ignore source. |
| `nearest_git_root` | Closest enclosing Git repository root, when one exists. |
| `relative_to_git_root` | Source path relative to `nearest_git_root`. |
| `scan_root` | Configured `--root` path that contained the source. Global exclude files can have this field blank. |
| `relative_to_scan_root` | Source path relative to `scan_root`. |

#### `gitignore-patterns-all.tsv`

| Column | Meaning |
|---|---|
| `normalized_pattern` | Pattern after carriage-return removal, surrounding-whitespace trimming, and blank/comment filtering. |
| `raw_pattern` | Original source line after only a trailing carriage return is removed. |
| `line_number` | One-based line number in the source ignore file. |
| `source_kind` | Same source classification used by `gitignore-files.tsv`. |
| `source_path` | Absolute path to the source ignore file. |
| `nearest_git_root` | Closest enclosing Git repository root, when one exists. |
| `relative_to_git_root` | Source path relative to the Git root. |
| `scan_root` | Configured root that contained the source. |
| `relative_to_scan_root` | Source path relative to the configured root. |

#### `gitignore-pattern-sources.tsv`

| Column | Meaning |
|---|---|
| `normalized_pattern` | Unique normalized ignore pattern. |
| `source_count` | Number of distinct ignore source files containing that pattern. |
| `sources` | Deterministically ordered, semicolon-separated absolute source paths. |

Because these files are true TSV data, use a TSV-aware viewer or format them only at display time:

```bash
column -s $'\t' -t \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-files.tsv" \
  | less -S
```

Do not save the padded `column` output back over the TSV file.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Appendix B — Known Gaps and Future Considerations

This appendix records known gaps in the current selected-ignored-file
workflow that have been analyzed but not yet decided or implemented. Nothing
in this appendix changes script behavior — it exists so the analysis isn't
lost between sessions, and so a future implementation pass starts from a
reviewed design space instead of from scratch.

### Secret-Shaped Selected Ignored Files Are Not Automatically Flagged

`stage-selected-patterns.py` has no secret-awareness today. `candidates.tsv`
has no classification column — every matched pattern's files land in the
same `candidates.tsv` / `dryrun/` / `live/` output, secret-shaped or not.
The current workflow handles this purely as a manual gate:

| Decision | Why |
|---|---|
| Whether a selected ignored file is a secret | Requires content review before cloud sync. |

(This is the same row already in [[#Manual Decisions That Remain Manual|Manual Decisions That Remain Manual]].)

[[#Mark Selected Ignored Patterns|Mark Selected Ignored Patterns]] already
lists a starter set of credential-shaped patterns to watch for — `.env`,
`.env.local`, `*.pem`, `*.key`, `*.p12`, `*.jks`, `credentials.json`, and
similar — but that list is prose in the runbook, not wired into the script.

Three directions have been considered for closing this gap. **No direction
has been chosen** — these are documented as separate alternatives, not a
combined design, so a future decision can pick one (or explicitly decline
all three) without re-deriving the analysis:

**Option A — Marking file (`secrets-patterns.txt`)**

A `secrets-patterns.txt` sibling file next to `gitignore-review-template.txt`
in `$REIMAGE_WORKSPACE_ROOT/gitignore-superset/` — a persisted, reusable list
(like `backup-exclude-list.txt`, but marking rather than excluding) of
patterns already known to be credential-shaped. The script would tag any
candidate whose matched pattern appears in that list with a `flagged_secret`
column in `candidates.tsv`, making it visible without re-deriving it every
run.

**Option B — Separate output bucket**

A separate output bucket, e.g. `staged-ignored-files/secrets-candidates/`,
so flagged files physically land apart from ordinary `dryrun/`/`live/`
output — making it harder to accidentally sync a secret-shaped file into the
same place as regular staged files.

**Option C — Naming-convention alignment with `backup-home`**

`backup-home` already has `SECRETS_TARGETS`/`secret-flags.conf.sh`
conventions on the home-directory side. A `secrets-patterns.txt` here would
be the git-repo-side counterpart, giving one mental model across both
phases instead of two unrelated ones.

None of the three options require touching `stage-selected-patterns.py`'s
matching engine — each would be an additional cross-reference step against
`candidates.tsv` after the existing dry run, keeping it additive rather than
a rewrite.

### Gitignore Superset Refresh Has No Automated Diff

The existing refresh workflow handles "the superset is a moving target"
reasonably well: copy a reviewed template in as a starting point, then
re-review against the freshly generated superset rather than trusting the
old one blindly.

The gap: there is no automated diff between the last-reviewed template and
the new superset. "What's actually new since last time" is currently a
manual eyeball job across the whole list, not a filtered one. Worth
considering later if the repo set grows large enough that a full manual
re-review becomes impractical each refresh.

[[#Table of Contents|⬆ Back to Table of Contents]]
