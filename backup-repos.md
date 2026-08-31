[[reimaging-guide#Phase 2A — Backup Repositories|← Back to Mac Reimaging Guide]]

# Backup Repositories

**Last updated:** 2026-08-13

This runbook preserves repository state and intentionally chosen local files before a Mac reimage.

Git remotes protect what you have committed and pushed. They do not protect local-only commits, uncommitted changes, stashes, untracked files, or the ignored local files — env files, IDE settings, certificates, local scripts — that never leave your machine. This runbook captures that gap.

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
    - [[#Step 1 — Define Git Repository Roots|Step 1 — Define Git Repository Roots]]
    - [[#Step 2 — Load Shared Configuration|Step 2 — Load Shared Configuration]]
    - [[#Step 3 — Run the Size Audit|Step 3 — Run the Size Audit]]
    - [[#Step 4 — Run the Repository Audit|Step 4 — Run the Repository Audit]]
    - [[#Step 5 — Review the Repository Audit|Step 5 — Review the Repository Audit]]
    - [[#Step 6 — Scan for Stale Ignore Entries|Step 6 — Scan for Stale Ignore Entries]]
    - [[#Step 7 — Review the Gitignore Superset|Step 7 — Review the Gitignore Superset]]
    - [[#Step 8 — Choose Your Path|Step 8 — Choose Your Path]]
    - [[#Step 9 — Choose Which Ignored Files to Keep|Step 9 — Choose Which Ignored Files to Keep]]
    - [[#Step 10 — Create or Update the Exclude List|Step 10 — Create or Update the Exclude List]]
    - [[#Step 11 — Set Up the Secrets-Patterns List|Step 11 — Set Up the Secrets-Patterns List]]
    - [[#Step 12 — Run the Selected Dry Run|Step 12 — Run the Selected Dry Run]]
    - [[#Step 13 — Run the Filtered Dry Run|Step 13 — Run the Filtered Dry Run]]
    - [[#Step 14 — Run the Selected Copy|Step 14 — Run the Selected Copy]]
    - [[#Step 15 — Run the Direct Dry Run|Step 15 — Run the Direct Dry Run]]
    - [[#Step 16 — Run the Direct Copy|Step 16 — Run the Direct Copy]]
    - [[#Step 17 — Review Output Files|Step 17 — Review Output Files]]
- [[#Manual Decisions That Remain Manual|Manual Decisions That Remain Manual]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Worked Example|Worked Example]]
    - [[#Gitignore Superset Generated Files|Gitignore Superset Generated Files]]
    - [[#Verifying Branch and Remote State|Verifying Branch and Remote State]]
    - [[#Known Gaps and Future Considerations|Known Gaps and Future Considerations]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

`backup-repos` (Phase 2A) carries forward, through a reimage, the two things Git remotes leave behind — repository state and the intentionally-kept local files Git ignores — so that afterward you restore a clean, reviewed set instead of an unfiltered dump of everything Git was ignoring.

**What it sets up**

- **A repository audit** — a per-repo inventory of what remotes don't protect: uncommitted changes, local-only commits, stashes, untracked non-ignored files, and repos with no remote or on a temporary branch.
- **A reviewed backup of ignored local files** — the gitignore superset plus the three review files (select, exclude, route) that turn everything your repos ignore into a small, deliberate set staged under `staged-ignored-files/`.
- **Segregated secret candidates** — credential-shaped kept files routed into `secrets-encrypted/repos-gitignored/` so they never sit beside cloud-synced output.

**What the rest of the workflow relies on it for**

- A trustworthy inventory so nothing local-only is lost before the machine is wiped.
- A staged, reviewed set of ignored files ready to restore after the reimage.
- Secret candidates parked where the Phase 3C consolidated DMG will encrypt them.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| the repository audit and its reports (`repo-audit-reports/`) | encrypting the routed secrets — `create-secrets-dmg` (Phase 3C) |
| the gitignore superset and the three review files (select / exclude / route) | IntelliJ HTTP Client env files — `backup-intellij` |
| staging kept ignored files into `staged-ignored-files/`, and routing secret-shaped files into `secrets-encrypted/repos-gitignored/` | the size-audit implementation — `report-size-audit` |

It does not turn `repo-audit-reports/` into a full source backup, and it routes secret candidates without building or replacing the consolidated DMG.

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
every ignore    files whose          noise dropped        │    → repos-gitignored/
pattern found   pattern you          via backup-          │      (in secrets-encrypted/)
across the      checked [x] in       exclude-list.txt     │
scanned repos   the template                              └─▶ [ backup candidates ]
                                                                → ordinary staging
```

- **Collect** — scan every repo under your configured roots and gather all their `.gitignore` patterns into one **superset**. Nothing is staged yet; this is only the catalog of what *could* be kept.
- **Select** — check `[x]` the patterns whose files you want. Matched against disk, they become the **selected set**.
- **Exclude** — drop generated, cache, and build noise from the selected set. What survives is the **filtered set** — the files that will actually be backed up.
- **Route** — sort the filtered set by shape: credential-shaped files go to `secrets-encrypted/repos-gitignored/` so the Phase 3C DMG sweeps them, everything else to ordinary staging.

> [!note]
> Both routing destinations are files you are keeping. Routing decides *where a kept file lands*, never *whether* it is kept.

### Terminology

The word "ignored" is doing double duty in Git, so this runbook fixes precise terms:

| Term | Meaning |
|---|---|
| Ignored file | A file Git does not track because a `.gitignore` rule matches it. Being ignored by Git is exactly why it needs manual backup. |
| Superset | Every unique ignore pattern found across all scanned repos. |
| Selected set | Files matched by the patterns you checked `[x]`. These are the files you want to keep. |
| Filtered set | The selected set after the exclude list removes noise. |
| Secret candidates | Filtered files whose pattern matches the secrets list; staged into `secrets-encrypted/repos-gitignored/` and listed in `secrets-candidates.tsv`. |
| Backup candidates | Filtered files that are not secret-shaped; staged normally. |

> [!note]
> "Selected" means *chosen to keep*, not *chosen to discard*. Checking a pattern preserves its files.

### Files, Stages, and Modes

Three files you maintain drive the three review stages:

| Stage | File | What it does |
|---|---|---|
| Select | `gitignore-review-template.txt` | Checkbox list of which ignored patterns to keep. |
| Exclude | `backup-exclude-list.txt` | Patterns to drop back out of the selected set. |
| Route | `secrets-patterns.txt` | Patterns whose kept matches divert to `secrets-encrypted/repos-gitignored/`. |

`bin/backup-repos.sh` is the single entrypoint, and its mode flag decides how far down the pipeline a run goes:

| Mode | Runs | Copies? |
|---|---|---|
| default (no mode flag) | Collect the superset and refresh the repo audit | No |
| `--selected-dry-run` | Select (+ Route) | No |
| `--selected-filtered-dry-run` | Select + Exclude (+ Route) | No |
| `--selected-copy` | Select + Exclude + Route | Yes |
| `--direct-ignored-dry-run` | Broad dump of every ignored file, no review | No |
| `--direct-ignored-copy` | Broad dump of every ignored file, no review | Yes |

> [!note]
> Route is always on whenever `secrets-patterns.txt` exists — it is not named in the flag. `--selected` adds Select; `--selected-filtered` adds Exclude; Route rides along in both when the file is present. The run that exercises all three files is therefore `--selected-filtered-dry-run` with all three sitting in `gitignore-superset/`. The `Secrets patterns:` line in `summary.txt` confirms Route fired.

> [!warning] Pitfall
> The `--direct-ignored-*` modes read none of the three files. Anything you selected, excluded, or flagged as a secret is ignored by them. They are an off-ramp, covered in [[#Selected Path vs Direct Path|Selected Path vs Direct Path]].

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
├── ...
├── gitignore-superset/
├── repo-audit-reports/
├── size-audit-reports/
├── staged-ignored-files/
└── ...
```

`prepare-artifact-root.md` creates these top-level containers. `bin/backup-repos.sh` checks for `gitignore-superset/`, `repo-audit-reports/`, and `staged-ignored-files/` on startup and exits with a pointer back to that runbook if any is missing, rather than creating them silently.

> [!note]
> The `dryrun/`, `dryrun-filtered/`, and `live/` children under `staged-ignored-files/` are owned by this runbook's own scripts, so `bin/backup-repos.sh` creates those itself on startup.

| Container | Holds |
|---|---|
| `gitignore-superset/` | The reviewable superset, your three review files, and the selection template. |
| `repo-audit-reports/` | Append-only audit index, latest-run pointer, and timestamped run directories. Not a full source backup. |
| `size-audit-reports/` | Append-only size-audit index, latest-run pointer, and timestamped colorized reports. |
| `staged-ignored-files/` | Dry-run and final copies of the kept ignored files. |

### Workspace Layout

Your three review files can also be kept under `$REIMAGE_WORKSPACE_ROOT`, so a reviewed set survives between backup reruns without the only copy living on the external drive:

```text
$REIMAGE_WORKSPACE_ROOT/
├── ...
├── gitignore-superset/
│   ├── backup-exclude-list.txt
│   ├── gitignore-review-template.txt
│   └── secrets-patterns.txt
└── ...
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

Staged ignored files. Each stage directory has the same shape; the `secrets-*.tsv` files appear only when `secrets-patterns.txt` is in use, and the `copied`/`copy-failed` files only under `--selected-copy`. Routed secret files are copied out to `secrets-encrypted/repos-gitignored/` (so the Phase 3C DMG sweeps them), not kept beside the ordinary staged files:

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
    ├── secrets-candidates.tsv    # routed secrets → secrets-encrypted/repos-gitignored/
    ├── secrets-copied.tsv
    ├── secrets-copy-failed.tsv
    └── <repo-label>/<relative-path>
```

The routed secret files themselves land under the encrypted-secrets root, where `create-secrets-dmg` sweeps them:

```text
secrets-encrypted/
├── ...
├── repos-gitignored/
│   └── <repo-label>/<relative-path>
└── ...
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

Each part below answers *why* a step exists before the Sequential Steps show *how* to run it.

### Prerequisites

This runbook assumes the external artifact volume, `$REIMAGE_ARTIFACT_ROOT`, the standard generated-artifact folders, and `reimage.env` are already in place. The Git repository roots (`GIT_WORK_REPO_ROOT`, `GIT_PERSONAL_REPO_ROOT`) are set by this runbook's first step.

| Item | Location |
|---|---|
| Workflow docs and scripts | `$FRACTOGENESIS_HOME` |
| Generated Git artifacts | `$REIMAGE_ARTIFACT_ROOT` |
| Local machine-specific values | `$FRACTOGENESIS_HOME/reimage.env` |
| Git repository roots | `GIT_WORK_REPO_ROOT`, `GIT_PERSONAL_REPO_ROOT` |

> [!bug] Troubleshooting
> If a root path does not exist, fix `reimage.env` before continuing. The entrypoint refuses to run against a missing root rather than silently skipping it.

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

> [!warning] Pitfall
> The Direct path reads none of your three review files and performs no secrets routing. Reach for it only when an unreviewed dump is genuinely what you want; otherwise stay on the Selected path.

### Why Secrets Are Routed Separately

Some files you need for development are also credential-shaped — env files, keys, keystores, IDE data sources. You still want them after the reimage, so you keep them; you just must not let them sync in the clear. `secrets-patterns.txt` diverts kept, credential-shaped files into `secrets-encrypted/repos-gitignored/`, where the Phase 3C DMG encrypts them. See [[#Step 11 — Set Up the Secrets-Patterns List|Step 11 — Set Up the Secrets-Patterns List]] for how to configure it, and the [[#Worked Example|Worked Example]] to see it in action.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The steps up to Choose Your Path are common setup: they define the repository roots, load shared configuration, and produce the audits and superset every later step reads. Choose Your Path then forks into the Selected chain or the Direct off-ramp, and the two rejoin at the final review of output files.

### Step 1 — Define Git Repository Roots

Define the local repository root directories in `reimage.env` before running the backups below.

These values tell the Git helper scripts where to search for repositories. They should point to parent folders that contain one or more Git repositories, not necessarily to a single repo.

You do **not** need both roots. `GIT_WORK_REPO_ROOT` should point to your existing work/corporate repo path. `GIT_PERSONAL_REPO_ROOT` is optional and can stay blank when you do not maintain a separate personal/reference repo area on this Mac.

Common examples:

| Variable                 | Purpose                                        | Example shape                            |
| ------------------------ | ---------------------------------------------- | ---------------------------------------- |
| `GIT_WORK_REPO_ROOT`     | Work/corporate development repositories.       | `/Users/<user>/Development/IdeaProjects` |
| `GIT_PERSONAL_REPO_ROOT` | Personal/reference/documentation repositories. | `/Users/<user>/Development/personal`     |

Keep these values in `reimage.env` as resolved absolute paths. Do not write literal values such as `$HOME/path/to/repos` or `${GIT_WORK_REPO_ROOT:-...}` into `reimage.env`; those can become stale or fail under `set -u`.

**These should already exist on disk as folders containing your cloned repos.** This guide doesn't create them -- it only points the Git helper scripts at them and validates that they're really there further down in this same step. If a path you set here doesn't exist yet, that's very likely a typo, not something to paper over; the validation below is specifically designed to catch that and tell you.

Set the values in the current shell first, using real paths for this Mac. **Export these under their final names directly** -- `GIT_WORK_REPO_ROOT` and `GIT_PERSONAL_REPO_ROOT`, matching every other export in this guide -- not a separately-named staging variable:

```bash
export GIT_WORK_REPO_ROOT="$HOME/path/to/work/repos"

export GIT_PERSONAL_REPO_ROOT=""
```

Only if you intentionally use a second personal/reference repo root, set it instead of leaving it blank:

```bash
export GIT_PERSONAL_REPO_ROOT="$HOME/path/to/personal/repos"
```

`bin/prepare-artifact-root.py upsert-env` accepts any `KEY=VALUE` pair it's given, including an empty `VALUE` -- it does not check that the value is non-empty before writing it, so a typo'd or unset shell variable on the next line gets written into `reimage.env` silently, with no error at all. Guard against that here, before it can happen, rather than relying on catching it downstream:

```bash
if [ -z "$GIT_WORK_REPO_ROOT" ]; then
  printf 'ERROR: GIT_WORK_REPO_ROOT is empty -- the export above did not take.\n'
  printf 'Fix it before continuing; do not run upsert-env with an empty value.\n'
fi
```

> [!warning] Pitfall
> The guard reports rather than aborting. `return 1 2>/dev/null || exit 1` reads
> like a safe abort and is not one in a pasted block: at the top level of an
> interactive shell `return` sets status 1, the `||` fires, and `exit` closes the
> terminal you are working in. A block you paste has no function to return from,
> so it has nothing to abort except your session.

Write the resolved Git root values into `reimage.env`:

```bash
python3 bin/prepare-artifact-root.py \
  upsert-env \
  --env-file reimage.env \
  "GIT_WORK_REPO_ROOT=${GIT_WORK_REPO_ROOT%/}" \
  "GIT_PERSONAL_REPO_ROOT=${GIT_PERSONAL_REPO_ROOT%/}"
```

After updating `reimage.env`, source it again in the current terminal. This is required because updating the file does not automatically update variables that are already loaded in an open shell.

```bash
set -a
source ./reimage.env
set +a
```

Confirm the loaded values and make sure they are resolved paths, not literal shell variables:

```bash
printf 'GIT_WORK_REPO_ROOT=%s\n' "${GIT_WORK_REPO_ROOT:-}"
printf 'GIT_PERSONAL_REPO_ROOT=%s\n' "${GIT_PERSONAL_REPO_ROOT:-}"

case "${GIT_WORK_REPO_ROOT:-}${GIT_PERSONAL_REPO_ROOT:-}" in
  *'$'*)
    echo "ERROR: Git root values contain literal shell variable text. Rewrite them as resolved absolute paths."
    exit 2
    ;;
esac
```

Validate the roots before continuing. The scripts support either the work root alone or both roots together, but the work root should exist before you continue:

```bash
if [[ -z "${GIT_WORK_REPO_ROOT:-}" ]]; then
  echo "GIT_WORK_REPO_ROOT is not set."
  echo "Add GIT_WORK_REPO_ROOT to reimage.env, then source it again."
  exit 2
fi

for root in "${GIT_WORK_REPO_ROOT:-}" "${GIT_PERSONAL_REPO_ROOT:-}"; do
  [[ -z "$root" ]] && continue

  if [[ -d "$root" ]]; then
    echo "OK: Git root exists: $root"
    find "$root" -name .git -type d -prune 2>/dev/null \
      | sed 's|/.git$||' \
      | head -25
  else
    echo "MISSING: $root"
  fi
done
```

If the validation prints no Git repositories, confirm the variables are loaded and point to parent folders that actually contain Git checkouts.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Load Shared Configuration

Source the local environment before running any command below, and re-source it after any edit to `reimage.env` in the same shell:

```bash
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

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Run the Size Audit

Check destination capacity first:

```bash
./bin/report-size-audit.sh --context pre-image-backup-repos
```

Look for `✓ External drive: enough space` (or the `✗ NOT ENOUGH SPACE` counterpart) and the available-space line.

> [!bug] Troubleshooting
> The saved report keeps ANSI color codes on purpose; view it in a terminal, not an editor. `less -R "$REIMAGE_ARTIFACT_ROOT/size-audit-reports/runs/<run>/size-audit-report.txt"`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Run the Repository Audit

This step refreshes both the repo audit and the gitignore superset in one run. The refresh regenerates `gitignore-review-template.txt`, so route by whether you have selections to carry into it — running first and deciding after costs you either your previous marks or this run's newly discovered patterns.

- [[#Fresh Superset|Fresh Superset]] — first run against a new artifact root, nothing to carry forward.
- [[#Carry Selections Forward|Carry Selections Forward]] — you kept a reviewed template from a previous backup.

> [!warning] Pitfall
> Restoring a previous template *after* the refresh overwrites the freshly generated file and silently drops every pattern this run discovered — new repos, changed ignore rules. The copy belongs before the refresh, and `--preserve-selections` is what carries your marks across.

> [!note]
> The script reads `gitignore-review-template.txt`, `backup-exclude-list.txt`, and `secrets-patterns.txt` from `$REIMAGE_ARTIFACT_ROOT/gitignore-superset/` only. The workspace copies are a manual stash so your decisions survive a new artifact root — nothing reads them directly.

#### Fresh Superset

The superset is generated from scratch and `gitignore-review-template.txt` arrives with every box `[ ]`:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

[[#Step 5 — Review the Repository Audit|⮕ Continue to Step 5 — Review the Repository Audit]]

---

#### Carry Selections Forward

Restore all three operator-maintained files into the artifact root first. `gitignore-superset/` already exists — `prepare-artifact-root.md` creates it as one of the expected artifact folders:

```bash
for f in \
  gitignore-review-template.txt \
  backup-exclude-list.txt \
  secrets-patterns.txt
do
  if [ -f "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/$f" ]; then
    cp -p "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/$f" \
          "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/$f"
    echo "restored  $f"
  else
    echo "no copy   $f"
  fi
done
```

Anything you have no workspace copy of is left alone here and seeded from the committed template by the refresh below, so a partial carry-forward is fine.

Then refresh with `--preserve-selections`, so the regenerated superset inherits your `[x]` marks instead of resetting to all `[ ]`. Any `[x]` pattern no longer present in the new superset is reported as a warning rather than kept:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --preserve-selections --open
```

> [!note]
> Only the review template needs the flag. It is the one file the refresh regenerates, so without `--preserve-selections` your marks are reset. `backup-exclude-list.txt` and `secrets-patterns.txt` are never regenerated — the refresh seeds them only when absent and reports `kept existing` otherwise, so restoring them is the whole job.

[[#Step 5 — Review the Repository Audit|⮕ Continue to Step 5 — Review the Repository Audit]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Review the Repository Audit

Open the newest summary to review it:

```bash
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$(cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/latest-run.txt")/repo-audit-summary.txt"
```

Act on what the audit surfaces — push feature branches, preserve uncommitted work or stashes on a `reimage/YYYYMMDD/…` branch, and decide what to do with untracked non-ignored files — before moving on. The ignored files it lists are handled by the path you choose next.

> [!note]
> A repo can have many modified files and still show `Untracked non-ignored files: 0`; that is expected when all local work is on files Git already tracks. Review `tracked-changes.tsv` for those.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 6 — Scan for Stale Ignore Entries

Optional, and worth running when repos have been renamed or restructured since the last backup.

A `.gitignore` line naming one literal file — `src/test/http_tests/elastic.http` rather than `src/test/http_tests/*.http` — stops working the moment that file is renamed or moved. Git does not warn. The rule covers nothing, the file quietly stops being ignored, and this runbook stops backing it up, because everything here only ever sees ignored files. When the guarded file held credentials, the same rename makes the secret tracked on the next commit.

The scan reads the pattern/source map the refresh already wrote, so it costs no second walk over your repositories:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --stale-ignore-scan --open
```

It writes `gitignore-superset/stale-ignore-entries.tsv`, one row per entry that matches nothing in the repo that declares it, highest signal first.

| Column | Meaning |
|---|---|
| `pattern` | The `.gitignore` line, exactly as written. |
| `kind` | `anchored` — the pattern contains a path, so it is fixed to one location; both a rename and a *move* break it. `bare` — a filename only, matched anywhere in the repo, so it survives a move but still breaks on a rename. |
| `guards_secret` | `yes` when the filename reads as credential-bearing — env files, credentials, tokens, keys, vaults. These are the rows where a stale rule stops being a backup gap and becomes an exposure. |
| `declared_in` | How many repositories declare this same line. |
| `repo` / `repo_path` | Which checkout this row is about. |

**Read `declared_in` before anything else.** An entry matching nothing is not automatically stale — most are *preventive*, ignoring a file if it ever appears. `Thumbs.db` on a Mac, the JetBrains `.idea/*` boilerplate, Spring's `HELP.md`: copied into many repos at once, expected to match nothing, nothing to fix. A line declared in **exactly one** repo is the opposite — somebody added it for a file that was really there. Those are the rows the console prints.

A review-worthy row is one of two things: a file you deleted, in which case delete the rule too, or a file you renamed — in which case find where the new name went before assuming it is safe.

> [!warning] Pitfall
> A renamed secret file is the case that matters. Confirm whether the new name is tracked before doing anything else — `git ls-files --error-unmatch <path>` — because adding it to `.gitignore` does not untrack an already-tracked file, and a committed credential needs rotating rather than ignoring.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 7 — Review the Gitignore Superset

The audit run above already generated the superset, with your previous selections carried forward if you restored a template and passed `--preserve-selections`. Review it here — do not re-collect it.

Open the template and the summary:

```bash
open "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt"
open "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/summary.txt"
```

> [!note]
> Carried-forward marks still need re-reviewing against this run's superset. New repos or changed ignore rules can mean last time's selection is no longer complete, and any previously checked pattern that has since disappeared was dropped with a warning. See [[#Gitignore Superset Generated Files|Gitignore Superset Generated Files]] for how to read the evidence files.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 8 — Choose Your Path

Common setup is done — route by how much review you want:

- [[#Step 9 — Choose Which Ignored Files to Keep|Step 9 — Choose Which Ignored Files to Keep]] — the **Selected path** (preferred): reviewed, reads all three files.
- [[#Step 15 — Run the Direct Dry Run|Step 15 — Run the Direct Dry Run]] — the **Direct path** (off-ramp): an unreviewed broad dump.

Both chains rejoin at the Review Output Files step.

> [!warning] Pitfall
> If you want the template, exclude list, or secrets routing to apply, take the Selected path. The Direct commands ignore all three.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 9 — Choose Which Ignored Files to Keep

This is the **Select** stage. In `gitignore-review-template.txt`, change the box on each pattern whose files you want to keep from `[ ]` to `[x]`:

```text
[x] .env.local
```

Checking a pattern *keeps* its files; leaving it unchecked means they are not backed up through this flow at all.

Give credential-shaped patterns particular attention — `.env`, `*.pem`, `*.key`, `*.p12`, `*.jks`, `*.keystore`, `credentials.json`, `.idea/dataSources.local.xml`, `*.http`, and similar:

> [!note]
> Do not skip a secret you need just because it is a secret. Checking is what *captures* a file; the next-but-one step ([[#Step 11 — Set Up the Secrets-Patterns List|Step 11 — Set Up the Secrets-Patterns List]]) is what keeps it segregated. Capture here, segregate there.

Save your edited template back to the workspace so you can reuse it later:

```bash
cp -p \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt" \
  "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/gitignore-review-template.txt"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 10 — Create or Update the Exclude List

This is the **Exclude** stage. `backup-exclude-list.txt` drops generated, cache, dependency, and build-output noise back out of the selected set.

> [!note]
> `backup-exclude-list.txt` is operator-maintained, not regenerated. The audit run seeds it from the
> committed template on first use and never overwrites it afterwards, so your edits
> survive every rerun. Review the seeded entries before trusting them.

Open it under the backup root to review and edit:

```bash
open "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/backup-exclude-list.txt"
```

> [!note]
> The exclude list can only trim what the template already selected; it cannot remove anything you did not check. Patterns aimed at folders you never selected have no effect, and heavy directories like `node_modules/` are pruned during the scan regardless.

> [!warning] Pitfall
> Do not use the exclude list to hide secrets. It drops files entirely. Secrets you want to keep belong in the Route stage, not here.

Save it back to the workspace for reuse:

```bash
cp -p \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/backup-exclude-list.txt" \
  "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/backup-exclude-list.txt"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 11 — Set Up the Secrets-Patterns List

This is the **Route** stage. `secrets-patterns.txt` diverts kept, credential-shaped files into `secrets-encrypted/repos-gitignored/` so they never sit beside the ordinary staged files that sync to cloud storage, and so the Phase 3C DMG sweeps them. It uses the same one-pattern-per-line format and matching engine as the exclude list, and `bin/backup-repos.sh` picks it up automatically whenever it exists — no flag.

> [!note]
> `secrets-patterns.txt` is operator-maintained, not regenerated. The audit run seeds it from the
> committed template on first use and never overwrites it afterwards, so your edits
> survive every rerun. Review the seeded entries before trusting them.

Open it under the backup root to review and edit:

```bash
open "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/secrets-patterns.txt"
```

The seeded file already carries the credential-shaped patterns below. Adjust them for your repos:

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

> [!note]
> Routing is not staging. A file must be checked `[x]` in the template to be captured at all; this list only decides *where* a captured, matching file lands. See [[#Why Secrets Are Routed Separately|Why Secrets Are Routed Separately]].

> [!note]
> IntelliJ HTTP Client env files (`http-client.env.json`, `http-client.private.env.json`) are owned by `backup-intellij`, which stages them into `secrets-encrypted/intellij/`. Do not list them here — routing them again would stage the same file twice.

Save it back to the workspace for reuse:

```bash
cp -p \
  "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/secrets-patterns.txt" \
  "$REIMAGE_WORKSPACE_ROOT/gitignore-superset/secrets-patterns.txt"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 12 — Run the Selected Dry Run

First pass — Select only, before the exclude list applies:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-dry-run --open
```

Review `staged-ignored-files/dryrun/candidates.tsv`. If `secrets-patterns.txt` exists, confirm the credential-shaped files landed in `secrets-candidates.tsv` rather than `candidates.tsv`, and that `parsed-secrets-patterns.txt` shows the list was read.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 13 — Run the Filtered Dry Run

Second pass — Select + Exclude, with all three files in play. This is the run that exercises the whole pipeline before any copy:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-filtered-dry-run --open
```

Confirm excluded files moved into `dryrun-filtered/excluded.tsv`, and that the `secrets-candidates.tsv` output matches what the first pass showed.

The summary reports two exclusion numbers because `excluded.tsv` holds one row per include pattern that selected a file, not one row per file. `Excluded files` is the distinct count and is the one that balances: `Candidate files` plus `Excluded files` equals the candidate total from the unfiltered dry run. `Excluded match rows` is the raw row count of the TSV, always the larger of the two.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 14 — Run the Selected Copy

Only after both dry runs look right. This copies the filtered, routed set into `staged-ignored-files/live/`:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-copy
```

Secret candidates are copied out to `secrets-encrypted/repos-gitignored/`, with `secrets-copied.tsv` and `secrets-copy-failed.tsv` recorded under `live/` alongside the ordinary `copied.tsv`.

[[#Step 17 — Review Output Files|⮕ Continue to Step 17 — Review Output Files]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 15 — Run the Direct Dry Run

> [!warning] Pitfall
> This is the Direct off-ramp. It reads none of your three review files and does no secrets routing. If you meant to use them, go back to [[#Step 8 — Choose Your Path|Step 8 — Choose Your Path]].

Broad dump of every ignored file, no review:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --direct-ignored-dry-run
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 16 — Run the Direct Copy

Only after reviewing the direct dry run:

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --direct-ignored-copy
```

> [!warning] Pitfall
> Because the Direct path does no routing, this can copy `.env` files, keys, certificates, and keystores straight into ordinary output. Do not treat it as a shortcut around secret review — handle those through `secrets-encrypted/` and the consolidated DMG workflow.

[[#Step 17 — Review Output Files|⮕ Continue to Step 17 — Review Output Files]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 17 — Review Output Files

Both paths land here. Before final validation, review the run outputs under `staged-ignored-files/`:

```text
candidates.tsv           backup candidates
excluded.tsv             dropped by the exclude list
secrets-candidates.tsv   diverted secret candidates
copied.tsv               copied files (live only)
copy-failed.tsv          copy failures (live only)
summary.txt              counts and the paths above
```

Watch for: copy failures, credential-shaped files that landed in `candidates.tsv` instead of `secrets-candidates.tsv`, and large generated folders that should have been excluded.

> [!note]
> Routed secrets are already segregated under `secrets-encrypted/repos-gitignored/` for exactly this review. Before syncing anything to cloud storage, confirm no credential-bearing file remains in the ordinary output.

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
| Route | `.env` → `secrets-encrypted/repos-gitignored/` (listed in `secrets-candidates.tsv`); the other three → backup candidates |

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

> [!bug] Troubleshooting
> The `.tsv` files are true tab-delimited data. View them formatted only at display time, e.g. `column -s $'\t' -t <file> | less -S`, and never save the padded output back over the file.

### Verifying Branch and Remote State

The audit answers "is anything here local-only" for every repo at once. `capture-repo-audit.sh` populates `local-only-commits.tsv` from:

```bash
git -C "$repo" log --branches --not --remotes --oneline --decorate
```

Commits reachable from any local branch, minus everything reachable from any remote-tracking ref — reachability across every remote at once. When the audit reports zero local-only commits for a repo, that answer is complete. In particular it is not fooled by a branch that shows no upstream in `git branch -vv`: a missing bracket means no tracking configured, not never pushed, and chasing those per repo produces false alarms the audit does not have.

General branch, upstream, and multi-remote inspection commands live in the Git and GitHub daily cheatsheets, not here.

> [!warning] Pitfall
> Run the audit from the branch you actually work on. `git ls-files --others --ignored` lists files that are ignored *and untracked*, so on a stale branch that predates files tracked on master, real source appears as ignored and gets staged as though Git were not protecting it. Confirm `git status` shows the expected branch before trusting a run.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Known Gaps and Future Considerations

Analyzed but not yet decided. Nothing here changes script behavior.

**Secret-shaped files are flagged only by pattern, not content.** `stage-selected-patterns.py` routes on filename patterns via `secrets-patterns.txt`; it does not scan file contents. A credential-shaped file with an unexpected name still lands in ordinary output. Content-based detection remains a manual review gate.

**The superset refresh has no automated diff.** There is no built-in comparison between a previously reviewed template and a freshly generated superset. "What is new since last time" is a manual read across the list. Worth revisiting if the repo set grows large enough that a full manual re-review becomes impractical each refresh.

[[#Table of Contents|⬆ Back to Table of Contents]]
