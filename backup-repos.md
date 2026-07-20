[[reimaging-guide#Phase 2A — Backup Repositories|← Back to Mac Reimaging Guide]]

# Backup Repositories

This runbook preserves repository state and intentionally chosen local files before a Mac reimage.

Git remotes protect what you have committed and pushed. They do not protect local-only commits, uncommitted changes, stashes, untracked files, or the ignored local files — env files, IDE settings, certificates, local scripts — that never leave your machine. This runbook captures that gap.

It does not turn `repo-audit-reports/` into a full source backup, and it does not replace secret handling through `secrets-encrypted/` and the consolidated DMG workflow.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#The Four Stages|The Four Stages]]
    - [[#Terminology|Terminology]]
    - [[#Files, Stages, and Modes|Files, Stages, and Modes]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Artifact Root Layout|Artifact Root Layout]]
    - [[#Workspace Layout|Workspace Layout]]
    - [[#Generated-Artifact Trees|Generated-Artifact Trees]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Why the Size Audit|Why the Size Audit]]
    - [[#Why the Repository Audit|Why the Repository Audit]]
    - [[#Why the Gitignore Superset|Why the Gitignore Superset]]
    - [[#Selected Path vs Direct Path|Selected Path vs Direct Path]]
    - [[#Why Secrets Are Routed Separately|Why Secrets Are Routed Separately]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Load Shared Configuration|Load Shared Configuration]]
    - [[#Run the Size Audit|Run the Size Audit]]
    - [[#Run the Repository Audit|Run the Repository Audit]]
    - [[#Review the Gitignore Superset|Review the Gitignore Superset]]
    - [[#Choose Your Path|Choose Your Path]]
    - [[#Choose Which Ignored Files to Keep|Choose Which Ignored Files to Keep]]
    - [[#Create or Update the Exclude List|Create or Update the Exclude List]]
    - [[#Set Up the Secrets-Patterns List|Set Up the Secrets-Patterns List]]
    - [[#Run the Selected Dry Run|Run the Selected Dry Run]]
    - [[#Run the Filtered Dry Run|Run the Filtered Dry Run]]
    - [[#Run the Selected Copy|Run the Selected Copy]]
    - [[#Run the Direct Dry Run|Run the Direct Dry Run]]
    - [[#Run the Direct Copy|Run the Direct Copy]]
    - [[#Review Output Files|Review Output Files]]
- [[#Manual Decisions That Remain Manual|Manual Decisions That Remain Manual]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Worked Example|Worked Example]]
    - [[#Gitignore Superset Generated Files|Gitignore Superset Generated Files]]
    - [[#Known Gaps and Future Considerations|Known Gaps and Future Considerations]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

Use this workflow to carry forward, through a reimage, the two things Git remotes leave behind:

1. Repository state — local branches, uncommitted work, stashes, and local-only commits.
2. Chosen local files — the ignored files you actually want back, kept apart from the ones you don't.

The reward for doing this deliberately is that after the reimage you restore a clean, reviewed set of local files instead of a full unfiltered dump of everything Git was ignoring.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. It is short, and every later step assumes it.

The goal is to turn *everything your repos ignore* into *a small, reviewed set of files worth keeping* — with credential-shaped files separated out so they never sync in the clear. The workflow does that in four stages, each driven by one input you control.

### The Four Stages

```text
   Collect                Select                  Exclude                 Route
     │                      │                        │                       │
[ superset ] ─▶ [ selected set ] ─▶ [ filtered set ] ─▶ ┬─▶ [ secret candidates ]
every ignore    files whose          noise dropped        │    → secrets-candidates/
pattern found   pattern you          via backup-          │      (held for encryption)
across the      checked [x] in       exclude-list.txt     │
scanned repos   the template                              └─▶ [ backup candidates ]
                                                                → ordinary staging
```

- **Collect** — scan every repo under your configured roots and gather all their `.gitignore` patterns into one **superset**. Nothing is staged yet; this is only the catalog of what *could* be kept.
- **Select** — check `[x]` the patterns whose files you want. Matched against disk, they become the **selected set**.
- **Exclude** — drop generated, cache, and build noise from the selected set. What survives is the **filtered set** — the files that will actually be backed up.
- **Route** — sort the filtered set by shape: credential-shaped files go to `secrets-candidates/` for encrypted handling, everything else to ordinary staging.

> **Note —** Both routing destinations are files you are keeping. Routing decides *where a kept file lands*, never *whether* it is kept.

### Terminology

The word "ignored" is doing double duty in Git, so this runbook fixes precise terms:

| Term | Meaning |
|---|---|
| Ignored file | A file Git does not track because a `.gitignore` rule matches it. Being ignored by Git is exactly why it needs manual backup. |
| Superset | Every unique ignore pattern found across all scanned repos. |
| Selected set | Files matched by the patterns you checked `[x]`. These are the files you want to keep. |
| Filtered set | The selected set after the exclude list removes noise. |
| Secret candidates | Filtered files whose pattern matches the secrets list; staged into `secrets-candidates/`. |
| Backup candidates | Filtered files that are not secret-shaped; staged normally. |

> **Note —** "Selected" means *chosen to keep*, not *chosen to discard*. Checking a pattern preserves its files.

### Files, Stages, and Modes

Three files you maintain drive the three review stages:

| Stage | File | What it does |
|---|---|---|
| Select | `gitignore-review-template.txt` | Checkbox list of which ignored patterns to keep. |
| Exclude | `backup-exclude-list.txt` | Patterns to drop back out of the selected set. |
| Route | `secrets-patterns.txt` | Patterns whose kept matches divert to `secrets-candidates/`. |

`bin/backup-repos.sh` is the single entrypoint, and its mode flag decides how far down the pipeline a run goes:

| Mode | Runs | Copies? |
|---|---|---|
| default (no mode flag) | Collect the superset and refresh the repo audit | No |
| `--selected-dry-run` | Select (+ Route) | No |
| `--selected-filtered-dry-run` | Select + Exclude (+ Route) | No |
| `--selected-copy` | Select + Exclude + Route | Yes |
| `--direct-ignored-dry-run` | Broad dump of every ignored file, no review | No |
| `--direct-ignored-copy` | Broad dump of every ignored file, no review | Yes |

> **Note —** Route is always on whenever `secrets-patterns.txt` exists — it is not named in the flag. `--selected` adds Select; `--selected-filtered` adds Exclude; Route rides along in both when the file is present. The run that exercises all three files is therefore `--selected-filtered-dry-run` with all three sitting in `gitignore-superset/`. The `Secrets patterns:` line in `summary.txt` confirms Route fired.

> **Pitfall —** The `--direct-ignored-*` modes read none of the three files. Anything you selected, excluded, or flagged as a secret is ignored by them. They are an off-ramp, covered in [[#Selected Path vs Direct Path|Selected Path vs Direct Path]].

This is the preferred workflow because every file that reaches cloud storage passed through an explicit select-then-exclude-then-route review, rather than being copied wholesale.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/backup-repos.sh
```

Supporting helpers it calls:

```text
$FRACTOGENESIS_HOME/.internal/git/capture-repo-audit.sh
$FRACTOGENESIS_HOME/.internal/git/collect-gitignore-superset.sh
$FRACTOGENESIS_HOME/.internal/git/stage-ignored-files.sh
$FRACTOGENESIS_HOME/.internal/git/stage-selected-patterns.py
```

### Artifact Root Layout

Generated Git artifacts live under `$REIMAGE_ARTIFACT_ROOT` in the standard shared layout:

```text
$REIMAGE_ARTIFACT_ROOT/
├── gitignore-superset/
├── repo-audit-reports/
├── size-audit-reports/
└── staged-ignored-files/
```

`prepare-artifact-root.md` creates these top-level containers. `bin/backup-repos.sh` checks for `gitignore-superset/`, `repo-audit-reports/`, and `staged-ignored-files/` on startup and exits with a pointer back to that runbook if any is missing, rather than creating them silently.

> **Note —** The `dryrun/`, `dryrun-filtered/`, and `live/` children under `staged-ignored-files/` are owned by this runbook's own scripts, so `bin/backup-repos.sh` creates those itself on startup.

| Container | Holds |
|---|---|
| `gitignore-superset/` | The reviewable superset, your three review files, and the selection template. |
| `repo-audit-reports/` | Append-only audit index, latest-run pointer, and timestamped run directories. Not a full source backup. |
| `size-audit-reports/` | Append-only size-audit index, latest-run pointer, and timestamped colorized reports. |
| `staged-ignored-files/` | Dry-run and final copies of the kept ignored files. |

### Workspace Layout

Your three review files can also be kept under `$REIMAGE_WORKSPACE_ROOT`, so a reviewed set survives between backup reruns without the only copy living on the external drive:

```text
$REIMAGE_WORKSPACE_ROOT/gitignore-superset/
├── backup-exclude-list.txt
├── gitignore-review-template.txt
└── secrets-patterns.txt
```

The Sequential Steps copy these in from the workspace at the start and back out to it at the end.

### Generated-Artifact Trees

Each generated area uses a self-contained, timestamped run directory whose name owns the context and timestamp, with stable filenames inside.

Size audit:

```text
size-audit-reports/
├── MANIFEST.md            # append-only index of successful runs
├── latest-run.txt         # one relative run path, updated only on success
└── runs/
    └── pre-image-backup-repos-YYYYMMDD-HHMMSS/
        └── size-audit-report.txt
```

Repository audit:

```text
repo-audit-reports/
├── MANIFEST.md
├── latest-run.txt
└── runs/
    └── pre-image-YYYYMMDD-HHMMSS/
        ├── repo-audit-summary.txt
        ├── repos.tsv
        ├── tracked-changes.tsv
        ├── local-only-commits.tsv
        ├── stashes.tsv
        ├── untracked-nonignored.tsv
        └── ignored-files.tsv
```

Gitignore superset (see [[#Gitignore Superset Generated Files|Gitignore Superset Generated Files]] for what each file is):

```text
gitignore-superset/
├── summary.txt
├── gitignore-files.tsv
├── gitignore-files-review.txt
├── gitignore-concatenated-with-sources.txt
├── gitignore-patterns-all.tsv
├── gitignore-patterns-all-review.txt
├── gitignore-patterns-superset.txt
├── gitignore-patterns-superset-with-counts.tsv
├── gitignore-pattern-sources.tsv
├── gitignore-pattern-sources-review.txt
├── gitignore-review-template.txt   # you edit this (Select)
├── backup-exclude-list.txt         # you edit this (Exclude)
└── secrets-patterns.txt            # you edit this (Route)
```

Staged ignored files. Each stage directory has the same shape; `secrets-candidates/` and the `secrets-*.tsv` files appear only when `secrets-patterns.txt` is in use, and the `copied`/`copy-failed` files only under `--selected-copy`:

```text
staged-ignored-files/
├── dryrun/            # Select only
├── dryrun-filtered/   # Select + Exclude
└── live/              # Select + Exclude + Route, files actually copied
    ├── summary.txt
    ├── candidates.tsv            # backup candidates
    ├── excluded.tsv
    ├── skipped.tsv
    ├── copied.tsv
    ├── copy-failed.tsv
    ├── secrets-candidates.tsv
    ├── secrets-copied.tsv
    ├── secrets-copy-failed.tsv
    ├── secrets-candidates/       # secret candidates, held apart
    │   └── <repo-label>/<relative-path>
    └── <repo-label>/<relative-path>
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

Each part below answers *why* a step exists before the Sequential Steps show *how* to run it.

### Prerequisites

This runbook assumes the external artifact volume, `$REIMAGE_ARTIFACT_ROOT`, the standard generated-artifact folders, and `reimage.env` are already in place, and that the Git repository roots are defined in `reimage.env` as `GIT_WORK_REPO_ROOT` and `GIT_PERSONAL_REPO_ROOT`.

| Item | Location |
|---|---|
| Workflow docs and scripts | `$FRACTOGENESIS_HOME` |
| Generated Git artifacts | `$REIMAGE_ARTIFACT_ROOT` |
| Local machine-specific values | `$FRACTOGENESIS_HOME/reimage.env` |
| Git repository roots | `GIT_WORK_REPO_ROOT`, `GIT_PERSONAL_REPO_ROOT` |

> **Troubleshooting —** If a root path does not exist, fix `reimage.env` before continuing. The entrypoint refuses to run against a missing root rather than silently skipping it.

### Why the Size Audit

Before generating more artifacts, confirm the destination volume is mounted and has headroom. The size audit is a quick capacity check on the whole backup root — it does not size the Git artifacts precisely, but it catches a full or unmounted drive before you waste a long run. It leads naturally into the audit and staging that follow.

### Why the Repository Audit

The audit is what makes the reimage safe. It inventories, per repo, the state Git remotes do not protect:

```text
uncommitted tracked changes
local-only commits
stashes
untracked non-ignored files
ignored files that may need backup
repos with no remote or on a temporary branch
```

Its `ignored-files.tsv` is the raw material the superset and the whole selected flow build on.

### Why the Gitignore Superset

Different repos ignore different things, and you cannot review what you cannot see in one place. The superset gathers every ignore pattern across all scanned repos into a single catalog, then writes the checkbox template you select from. It is generated automatically during the repo-audit run, so by the time you reach selection it already exists — the Sequential Steps *review* it rather than re-collect it.

### Selected Path vs Direct Path

From the superset onward there are two ways to run, and it matters which one you pick.

The **Selected path** is the default and the one the Sequential Steps walk end to end. It is the only path that reads your three review files, so it is the one that reflects any selecting, excluding, or secret routing you set up.

The **Direct path** is an off-ramp: a broad dump of every file Git reports as ignored, with no review. Use it only for a quick look at the full ignored surface, or when you knowingly want everything.

> **Pitfall —** The Direct path reads none of your three review files and performs no secrets routing. Reach for it only when an unreviewed dump is genuinely what you want; otherwise stay on the Selected path.

### Why Secrets Are Routed Separately

Some files you need for development are also credential-shaped — env files, keys, keystores, IDE data sources. You still want them after the reimage, so you keep them; you just must not let them sync in the clear. `secrets-patterns.txt` diverts kept, credential-shaped files into `secrets-candidates/`, held apart for the encrypted secrets DMG. See [[#Set Up the Secrets-Patterns List|Set Up the Secrets-Patterns List]] for how to configure it, and the [[#Worked Example|Worked Example]] to see it in action.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The first four — [[#Load Shared Configuration|Load Shared Configuration]] through [[#Review the Gitignore Superset|Review the Gitignore Superset]] — are common setup for both paths. [[#Choose Your Path|Choose Your Path]] then sends you down either the Selected chain or the Direct off-ramp, and both rejoin at [[#Review Output Files|Review Output Files]].

### Load Shared Configuration

Source the local environment before running any command below, and re-source it after any edit to `reimage.env` in the same shell:

```bash
cd "$FRACTOGENESIS_HOME"
set -a
source ./reimage.env
set +a
```

Confirm the paths resolved:

```bash
printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
printf 'GIT_WORK_REPO_ROOT=%s\n' "${GIT_WORK_REPO_ROOT:-}"
printf 'GIT_PERSONAL_REPO_ROOT=%s\n' "${GIT_PERSONAL_REPO_ROOT:-}"
```

### Run the Size Audit

Check destination capacity first:

```bash
./bin/capture-size-audit.sh --context pre-image-backup-repos
```

Look for `✓ External drive: enough space` (or the `✗ NOT ENOUGH SPACE` counterpart) and the available-space line.

> **Troubleshooting —** The saved report keeps ANSI color codes on purpose; view it in a terminal, not an editor. `less -R "$REIMAGE_ARTIFACT_ROOT/size-audit-reports/runs/<run>/size-audit-report.txt"`.

### Run the Repository Audit

The default entrypoint refreshes both the repo audit and the gitignore superset in one run:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

Open the newest summary to review it:

```bash
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$(cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/latest-run.txt")/repo-audit-summary.txt"
```

Act on what the audit surfaces — push feature branches, preserve uncommitted work or stashes on a `reimage/YYYYMMDD/…` branch, and decide what to do with untracked non-ignored files — before moving on. The ignored files it lists are handled by the path you choose next.

> **Note —** A repo can have many modified files and still show `Untracked non-ignored files: 0`; that is expected when all local work is on files Git already tracks. Review `tracked-changes.tsv` for those.

### Review the Gitignore Superset

The audit run above already generated the superset. Review it here — do not re-collect it. If you kept a reviewed template from a previous backup, copy it in before editing so you start from your last decisions:

```bash
cp -p \
  "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/gitignore-review-template.txt" \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt"
```

Open the template and the summary:

```bash
open "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt"
open "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/summary.txt"
```

> **Note —** Even a copied-in template must be re-reviewed against this run's superset. New repos or changed ignore rules can mean last time's selection is no longer complete. See [[#Gitignore Superset Generated Files|Gitignore Superset Generated Files]] for how to read the evidence files.

### Choose Your Path

Common setup is done. Pick one:

- **Selected path (preferred).** Reviewed, reads all three files. Continue to [[#Choose Which Ignored Files to Keep|Choose Which Ignored Files to Keep]].
- **Direct path (off-ramp).** Unreviewed broad dump. Jump to [[#Run the Direct Dry Run|Run the Direct Dry Run]].

Both paths end at [[#Review Output Files|Review Output Files]].

> **Pitfall —** If you want the template, exclude list, or secrets routing to apply, take the Selected path. The Direct commands ignore all three.

### Choose Which Ignored Files to Keep

This is the **Select** stage. In `gitignore-review-template.txt`, change the box on each pattern whose files you want to keep from `[ ]` to `[x]`:

```text
[x] .env.local
```

Checking a pattern *keeps* its files; leaving it unchecked means they are not backed up through this flow at all.

Give credential-shaped patterns particular attention — `.env`, `*.pem`, `*.key`, `*.p12`, `*.jks`, `*.keystore`, `credentials.json`, `.idea/dataSources.local.xml`, `*.http`, and similar:

> **Note —** Do not skip a secret you need just because it is a secret. Checking is what *captures* a file; the next-but-one step ([[#Set Up the Secrets-Patterns List|Set Up the Secrets-Patterns List]]) is what keeps it segregated. Capture here, segregate there.

Save your edited template back to the workspace so you can reuse it later:

```bash
cp -p \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt" \
  "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/gitignore-review-template.txt"
```

### Create or Update the Exclude List

This is the **Exclude** stage. `backup-exclude-list.txt` drops generated, cache, dependency, and build-output noise back out of the selected set. Create or edit it under the backup root:

```bash
open "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/backup-exclude-list.txt"
```

> **Note —** The exclude list can only trim what the template already selected; it cannot remove anything you did not check. Patterns aimed at folders you never selected have no effect, and heavy directories like `node_modules/` are pruned during the scan regardless.

> **Pitfall —** Do not use the exclude list to hide secrets. It drops files entirely. Secrets you want to keep belong in the Route stage, not here.

Save it back to the workspace for reuse:

```bash
cp -p \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/backup-exclude-list.txt" \
  "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/backup-exclude-list.txt"
```

### Set Up the Secrets-Patterns List

This is the **Route** stage. `secrets-patterns.txt` diverts kept, credential-shaped files into `secrets-candidates/` so they never sit beside the ordinary staged files that sync to cloud storage. It uses the same one-pattern-per-line format and matching engine as the exclude list, and `bin/backup-repos.sh` picks it up automatically whenever it exists — no flag.

Create or edit it under the backup root:

```bash
open "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/secrets-patterns.txt"
```

A starter list based on the credential-shaped patterns from [[#Choose Which Ignored Files to Keep|Choose Which Ignored Files to Keep]] is the expected starting point, adjusted for your repos:

```text
.env
.env.*
*.pem
*.key
*.p12
*.jks
*.keystore
.idea/dataSources.local.xml
*.http
credentials*.json
*.secrets.json
```

> **Note —** Routing is not staging. A file must be checked `[x]` in the template to be captured at all; this list only decides *where* a captured, matching file lands. See [[#Why Secrets Are Routed Separately|Why Secrets Are Routed Separately]].

Save it back to the workspace for reuse:

```bash
cp -p \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/secrets-patterns.txt" \
  "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/secrets-patterns.txt"
```

### Run the Selected Dry Run

First pass — Select only, before the exclude list applies:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-dry-run --open
```

Review `staged-ignored-files/dryrun/candidates.tsv`. If `secrets-patterns.txt` exists, confirm the credential-shaped files landed in `secrets-candidates.tsv` rather than `candidates.tsv`, and that `parsed-secrets-patterns.txt` shows the list was read.

### Run the Filtered Dry Run

Second pass — Select + Exclude, with all three files in play. This is the run that exercises the whole pipeline before any copy:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-filtered-dry-run --open
```

Confirm excluded files moved into `dryrun-filtered/excluded.tsv`, and that the `secrets-candidates/` output matches what the first pass showed.

### Run the Selected Copy

Only after both dry runs look right. This copies the filtered, routed set into `staged-ignored-files/live/`:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-copy
```

Secret candidates are copied under `live/secrets-candidates/`, with `secrets-copied.tsv` and `secrets-copy-failed.tsv` alongside the ordinary `copied.tsv`.

> **Return —** Selected path done. Continue to [[#Review Output Files|Review Output Files]].

### Run the Direct Dry Run

> **Pitfall —** This is the Direct off-ramp. It reads none of your three review files and does no secrets routing. If you meant to use them, go back to [[#Choose Your Path|↩ Choose Your Path]].

Broad dump of every ignored file, no review:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --direct-ignored-dry-run
```

### Run the Direct Copy

Only after reviewing the direct dry run:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --direct-ignored-copy
```

> **Pitfall —** Because the Direct path does no routing, this can copy `.env` files, keys, certificates, and keystores straight into ordinary output. Do not treat it as a shortcut around secret review — handle those through `secrets-encrypted/` and the consolidated DMG workflow.

> **Return —** Direct path done. Continue to [[#Review Output Files|Review Output Files]].

### Review Output Files

Both paths land here. Before final validation, review the run outputs under `staged-ignored-files/`:

```text
candidates.tsv           backup candidates
excluded.tsv             dropped by the exclude list
secrets-candidates.tsv   diverted secret candidates
copied.tsv               copied files (live only)
copy-failed.tsv          copy failures (live only)
summary.txt              counts and the paths above
```

Watch for: copy failures, credential-shaped files that landed in `candidates.tsv` instead of `secrets-candidates/`, and large generated folders that should have been excluded.

> **Note —** Anything under `secrets-candidates/` is already segregated for exactly this review. Before syncing anything to cloud storage, confirm no credential-bearing file remains in the ordinary output.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Manual Decisions That Remain Manual

The scripts inventory and stage; these judgments stay with you.

| Decision | Why it stays manual |
|---|---|
| Whether to push a local branch | Requires knowing whether the branch is safe to publish. |
| Whether local default-branch commits should become a backup branch | Prevents an accidental push to the remote default branch. |
| Whether a stash is important | The script can list stashes, not judge them. |
| Which ignore patterns to keep | Requires project knowledge. |
| Whether a kept file is a secret | Requires content review before cloud sync. |
| Whether a repo root should be included | Requires knowing the current machine's workspace layout. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Worked Example

A concrete walk through both paths on two small repos, so you can see exactly what lands where.

Setup — two repos under one root, each with a `.gitignore` and a mix of files:

```text
~/dev/demo-root/
├── app-service/                 # git repo
│   ├── .gitignore               # ignores: .env, build/, .idea/, *.log
│   ├── .env                     # local DB credentials  (want, but secret)
│   ├── src/local_main.py        # local-only script     (want)
│   ├── build/output.jar         # compiled artifact      (don't want)
│   ├── app.log                  # runtime log            (don't want)
│   └── .idea/workspace.xml      # IDE window state       (want)
└── notes-vault/                 # git repo
    ├── .gitignore               # ignores: .DS_Store, docs/user/
    ├── docs/user/design.md      # working design notes   (want)
    └── docs/user/.DS_Store      # macOS junk             (don't want)
```

The three review files:

```text
# gitignore-review-template.txt  (Select — [x] = keep)
[x] .env
[x] src/local_main.py
[x] .idea/workspace.xml
[x] docs/user/
[ ] build/
[ ] *.log
```

```text
# backup-exclude-list.txt  (Exclude — drop noise from the selected set)
.DS_Store
```

```text
# secrets-patterns.txt  (Route — divert secret-shaped kept files)
.env
```

How the four stages resolve for the Selected path:

| Stage | Result |
|---|---|
| Collect | superset = `.env`, `build/`, `.idea/`, `*.log`, `.DS_Store`, `docs/user/` |
| Select | selected set = `.env`, `src/local_main.py`, `.idea/workspace.xml`, `docs/user/design.md`, `docs/user/.DS_Store` |
| Exclude | `.DS_Store` dropped → filtered set = `.env`, `src/local_main.py`, `.idea/workspace.xml`, `docs/user/design.md` |
| Route | `.env` → `secrets-candidates/`; the other three → backup candidates |

Resulting dry-run output (abbreviated):

```text
staged-ignored-files/dryrun-filtered/
├── candidates.tsv           app-service/src/local_main.py
│                            app-service/.idea/workspace.xml
│                            notes-vault/docs/user/design.md
├── excluded.tsv             notes-vault/docs/user/.DS_Store
└── secrets-candidates.tsv   app-service/.env   (matched: .env)
```

Note that `build/output.jar` and `app.log` never appear — their patterns were never checked, so Select left them out entirely. `.DS_Store` was selected via `docs/user/` but Exclude removed it. `.env` was kept but routed aside.

The same two repos on the **Direct path** (`--direct-ignored-dry-run`) instead produce every ignored file, unreviewed:

```text
app-service/.env            ← secret, now in ordinary output
app-service/build/output.jar
app-service/app.log
app-service/.idea/workspace.xml
notes-vault/docs/user/design.md
notes-vault/docs/user/.DS_Store
```

That is the trade-off in one screen: the Direct path is faster but dumps the compiled artifact, the log, the junk file, and — worst — the credential file into ordinary output. The Selected path took four small files and set the secret aside. This is why the Selected path is preferred and the Direct path is an off-ramp.

### Gitignore Superset Generated Files

The superset collector (`.internal/git/collect-gitignore-superset.sh`) writes both machine-readable TSVs and human-readable review files under `gitignore-superset/`. The TSVs are the source of truth; the `*-review.txt` files and the concatenated file are views derived from them.

Recommended reading order after a refresh:

1. `summary.txt` — roots scanned, counts, output paths.
2. `gitignore-files-review.txt` — confirm the expected ignore sources were found.
3. `gitignore-pattern-sources-review.txt` — which patterns are shared across repos.
4. `gitignore-concatenated-with-sources.txt` — a pattern's original comments and context.
5. `gitignore-patterns-all-review.txt` — exact source line numbers.
6. `gitignore-review-template.txt` — where you make selections.

| File | Represents |
|---|---|
| `summary.txt` | Run overview: roots, counts, output paths, review order. |
| `gitignore-files.tsv` | One row per discovered ignore source, with provenance. |
| `gitignore-files-review.txt` | Grouped, readable rendering of the above. |
| `gitignore-concatenated-with-sources.txt` | Exact contents of every ignore source, with provenance headings. |
| `gitignore-patterns-all.tsv` | Every active pattern occurrence, with source path and line number. |
| `gitignore-patterns-all-review.txt` | The above grouped by source file. |
| `gitignore-patterns-superset.txt` | One sorted copy of each unique normalized pattern. |
| `gitignore-patterns-superset-with-counts.tsv` | Unique patterns with occurrence counts. |
| `gitignore-pattern-sources.tsv` | Per unique pattern: how many sources use it, and which. |
| `gitignore-pattern-sources-review.txt` | Readable pattern-to-source report. |
| `gitignore-review-template.txt` | The `[ ]`/`[x]` selection checklist. |
| `backup-exclude-list.txt` | Operator-maintained exclusions; not regenerated. |
| `secrets-patterns.txt` | Operator-maintained secret routing patterns; not regenerated. |

> **Troubleshooting —** The `.tsv` files are true tab-delimited data. View them formatted only at display time, e.g. `column -s $'\t' -t <file> | less -S`, and never save the padded output back over the file.

### Known Gaps and Future Considerations

Analyzed but not yet decided. Nothing here changes script behavior.

**Secret-shaped files are flagged only by pattern, not content.** `stage-selected-patterns.py` routes on filename patterns via `secrets-patterns.txt`; it does not scan file contents. A credential-shaped file with an unexpected name still lands in ordinary output. Content-based detection remains a manual review gate.

**The superset refresh has no automated diff.** There is no built-in comparison between a previously reviewed template and a freshly generated superset. "What is new since last time" is a manual read across the list. Worth revisiting if the repo set grows large enough that a full manual re-review becomes impractical each refresh.

[[#Table of Contents|⬆ Back to Table of Contents]]
