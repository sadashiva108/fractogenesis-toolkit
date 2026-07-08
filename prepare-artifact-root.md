[[reimaging-guide#Phase 1 — Prepare the External Backup and Capture Root|← Back to Mac Reimaging Guide]]

# Prepare Backup and Capture Root

Sequential guide for preparing the external backup/capture location before running pre-image backups, evidence captures, validation scripts, restore steps, and post-image comparison captures.

Recommended path: create the local `reimage.env` file first, then source it in each terminal session. This guide uses `reimage.env` as the normal source of truth for `REIMAGE_WORKSPACE_ROOT`, `EXTERNAL_DATA_VOLUME`, `EXTERNAL_APPLE_BACKUPS_VOLUME`, and `REIMAGE_ARTIFACT_ROOT`. Manual export-only commands are kept later as a fallback, not as the normal path.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Preparation Sequence|Preparation Sequence]]
    - [[#Repo, Workspace, and External Drive Boundary|Repo, Workspace, and External Drive Boundary]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Confirm the Repo Is Cloned|Confirm the Repo Is Cloned]]
    - [[#Choose the External Data Volume|Choose the External Data Volume]]
    - [[#Confirm External Data Volume Readiness|Confirm External Data Volume Readiness]]
    - [[#Artifact Root Naming Convention|Artifact Root Naming Convention]]
    - [[#Create the Local Reimage Environment File|Create the Local Reimage Environment File]]
    - [[#Set Up direnv (.envrc)|Set Up direnv (.envrc)]]
    - [[#Confirm reimage.env Is Loaded|Confirm reimage.env Is Loaded]]
    - [[#Define Git Repository Roots|Define Git Repository Roots]]
    - [[#Create the Artifact Root|Create the Artifact Root]]
    - [[#Load and Confirm the Environment|Load and Confirm the Environment]]
    - [[#Create the Standard Directory Layout|Create the Standard Directory Layout]]
    - [[#Understand artifact-config.sh|Understand artifact-config.sh]]
    - [[#Verify the Prepared Root|Verify the Prepared Root]]
- [[#Troubleshooting|Troubleshooting]]
    - [[#External Data Volume Not Visible|External Data Volume Not Visible]]
    - [[#External Data Volume Is Read Only|External Data Volume Is Read Only]]
    - [[#External Data Volume Is Writable but Current User Cannot Write|External Data Volume Is Writable but Current User Cannot Write]]
    - [[#Terminal Privacy Access Is Blocking External Volume Access|Terminal Privacy Access Is Blocking External Volume Access]]
    - [[#REIMAGE_ARTIFACT_ROOT Is Empty in Scripts|REIMAGE_ARTIFACT_ROOT Is Empty in Scripts]]
    - [[#reimage.env Contains Helper Variables or Literal Paths|reimage.env Contains Helper Variables or Literal Paths]]
    - [[#Directory Verification Is Missing Folders|Directory Verification Is Missing Folders]]
    - [[#OneDrive Backup Wrote Under the Repo Checkout|OneDrive Backup Wrote Under the Repo Checkout]]
    - [[#Manual Export-Only Fallback|Manual Export-Only Fallback]]
    - [[#Permission Issues Restoring Files|Permission Issues Restoring Files]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

Prepare one external backup/capture root for the full reimage effort.

The root stores generated artifacts such as:

```text
reimage plan copy
app backups
system inventory
performance evidence
Office stability evidence
Time Machine status captures
reimage preparation checks with go/no-go reports to begin reimaging
reimaged system initial captures and enrollment and validation bundles
redacted restore notes
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Keep active helper scripts in this repo under:

```text
bin/         # entrypoints — run directly
.internal/   # sourced-only helpers, never run directly
```

Do **not** create a normal `$REIMAGE_ARTIFACT_ROOT/scripts` folder. The external artifact root should hold generated artifacts, not the script source of truth.

Key files referenced by this guide include:

```text
bin/prepare-artifact-root.py
.internal/artifact-config.sh
```

Both self-locate relative to their own position in the repo — nothing needs to be told where the repo is; there's no `REIMAGE_ROOT`-equivalent variable to keep in sync.

The reimage workflow has two separate storage roles (a third, this repo itself, is self-locating and needs no variable at all):

| Path name                | Location                     | Role                                                                                                                  | What belongs there                                                                                                                                                                                                 |
| ------------------------ | ---------------------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `REIMAGE_WORKSPACE_ROOT` | Local workspace              | Local-only staging and reusable config area outside this repo.                                                | IT reimage confirmation working copy, reusable artifact-config workspace copies, staged chart/history artifacts, and other local files that may be reused across backup reruns before copying to the external drive. |
| `REIMAGE_ARTIFACT_ROOT`            | External artifact root | Generated artifacts, logs, inventories, encrypted bundles, manual notes, validation reports, and post-image evidence. | The active reimage artifact tree under the selected external data volume.                                                                                                                                    |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

### Preparation Sequence

This guide is intentionally ordered so each command only depends on values that have already been confirmed or exported earlier -- either as plain shell exports before `reimage.env` exists, or read from `reimage.env` once it does. The external volume and artifact-root name are decided *before* `reimage.env` is created, specifically so it's written correctly the first time instead of created with placeholder values and edited afterward.

Use this sequence:

| Order | Action | Why it comes here |
|---:|---|---|
| 1 | Confirm the repo is cloned | Nothing else in this guide works without the repo actually being present. |
| 2 | Choose the external data/artifact volume | Identify the parent volume that will hold manual artifacts -- as a plain export, since `reimage.env` doesn't exist yet. |
| 3 | Confirm external data volume readiness | Prove the parent external volume is mounted, not read-only, and writable by the current user before creating `$REIMAGE_ARTIFACT_ROOT`. |
| 4 | Decide the artifact root naming convention | Compute the resolved `$REIMAGE_ARTIFACT_ROOT` path, still as a plain export. |
| 5 | Create `reimage.env` | Write the local source of truth, seeded with the already-confirmed volume and artifact-root values -- resolved correctly from the start, no follow-up edit needed. |
| 6 | Set up direnv | Make `reimage.env` load automatically on `cd` into the repo from here on. |
| 7 | Load and print the config | Confirm the environment resolves as expected. |
| 8 | Define Git repository roots | Save the parent folders that later Git backup steps will search. |
| 9 | Create the artifact root | Actually create the directory on the external volume, now that `reimage.env` has the resolved path. |
| 10 | Load and confirm the environment | Deeper validation that the created root and full config are consistent. |
| 11 | Create the standard workflow layout | Seed the directories used across the reimage workflow. |
| 12 | Confirm `artifact-config.sh` is aligned | Verify backup scripts can read the same environment and expected top-level folders. |
| 13 | Verify the prepared root | Confirm the prepared top-level structure is ready for backup and evidence scripts. |

Troubleshooting is intentionally at the end. Specific steps link to the relevant troubleshooting section only when something fails.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Repo, Workspace, and External Drive Boundary

Keep these boundaries clear before creating directories.

#### This repo

Stores active source files: runbooks, `bin/` entrypoint scripts, `.internal/` helper scripts and config templates, and reference/template docs — all tracked in Git. Self-located by the scripts that need it; no path to it needs to be saved in `reimage.env`.

#### Local workspace

The local workspace is outside this repo and outside the external artifact root. Use it for staging and reusable local config that may survive more than one backup attempt.

Recommended default:

```text
$HOME/Documents/reimage-workspace/
```

Typical uses:

```text
filled IT reimage confirmation working copy
workspace-backed artifact-config copies under artifact-config/
locally staged history/chart artifacts before copying to $REIMAGE_ARTIFACT_ROOT
other local notes or artifacts that are not ready for the external drive yet
```

#### External backup/capture root

The external root stores generated files only. This guide lists the top-level folders only; child directories belong to the runbook or script that creates them.

Do not copy active `*.sh` or `*.py` helper scripts into the external root. The script source of truth is this repo's Git history.

Workflow snapshot captures and workflow documentation snapshots are handled by `capture-workflow-snapshot.md`, not by this preparation guide.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

### Confirm the Repo Is Cloned

Before anything else in Sequential Steps -- confirm this repo is actually checked out on this Mac.

```bash
pwd
find . -maxdepth 2 -type f | sort | sed 's|^\./||' | head -80
```

Expected files include:

```text
reimaging-guide.md
prepare-artifact-root.md
.internal/artifact-config.sh
...
```

If `.internal/artifact-config.sh` is missing, stop and confirm you are in the right repo checkout.

#### If the repo is not cloned yet

Two paths, depending on context:

**On your normal dev machine** (Git/SSH already working): clone normally into wherever you organize documentation or source repos.

```bash
FRACTOGENESIS_PARENT="/path/to/local/repo-parent"

mkdir -p "$FRACTOGENESIS_PARENT"
cd "$FRACTOGENESIS_PARENT"

git clone git@github.com:sadashiva108/fractogenesis-toolkit.git
```

Then `cd` into it:

```text
cd "$FRACTOGENESIS_PARENT/fractogenesis-toolkit"
```

**On a freshly reimaged Mac** (no Git/SSH yet — this is the actual scenario Phase 6 onward depends on): use the bootstrap mechanism instead of `git clone` — no auth needed, no Xcode Command Line Tools popup:

```bash
curl -fsSL https://raw.githubusercontent.com/sadashiva108/fractogenesis-toolkit/main/bootstrap.sh | bash
```

Installs to `$HOME/reimage-toolkit` by default. If there's no network yet, use the prepared jump drive fallback instead — see the repo README or Phase 6 of `reimaging-guide.md` for the exact command.

The repo is public, so no access request is needed either way.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Choose the External Data Volume

Identify the external data/artifact volume. This step only chooses the parent external data/artifact volume. Do not create `$REIMAGE_ARTIFACT_ROOT` yet.

```bash
ls -la /Volumes
diskutil list external
```

Expected role split:

```text
<time-machine-volume-name>      -> Time Machine / Apple backup destination only
<external-data-volume-name>     -> manual backup files, generated evidence, setup notes, validation reports
```

#### How to choose from the command output

Use these rules:

| Output clue | Meaning | Use for `EXTERNAL_DATA_VOLUME`? |
|---|---|---:|
| `Macintosh HD -> /` | Internal system volume symlink. | No |
| `com.apple.TimeMachine.localsnapshots` | Local Time Machine snapshot mount. | No |
| A volume named like `AppleBackups`, `TimeMachine`, or similar | Dedicated Time Machine destination. | No |
| A separate external APFS volume named like `Data`, `Backups`, `Artifacts`, or similar | Manual artifact/data volume. | Yes |
| `diskutil list external` shows the volume under an external physical disk | Confirms the volume is on the external drive. | Yes, if it is not the Time Machine volume |

Example from one external drive:

```text
/Volumes
├── AppleBackups
├── Data
├── com.apple.TimeMachine.localsnapshots
└── Macintosh HD -> /

diskutil list external
├── APFS Volume AppleBackups
└── APFS Volume Data
```

Interpretation:

| Volume | Role | Decision |
|---|---|---|
| `/Volumes/AppleBackups` | Time Machine destination. | Do not use for manual artifacts. |
| `/Volumes/Data` | External data/artifact volume. | Recommended `EXTERNAL_DATA_VOLUME`. |
| `/Volumes/com.apple.TimeMachine.localsnapshots` | Time Machine local snapshot mount. | Ignore. |
| `/Volumes/Macintosh HD` | Internal system volume symlink. | Ignore. |

`reimage.env` doesn't exist yet at this point in the guide -- export the confirmed values as plain shell variables instead, and keep this terminal session open through the next few steps (Confirm External Data Volume Readiness and Artifact Root Naming Convention both use these same exports):

```bash
export EXTERNAL_DATA_VOLUME="/Volumes/<external-data-volume-name>"
export EXTERNAL_APPLE_BACKUPS_VOLUME="/Volumes/<time-machine-volume-name>"
```

Do not use the Time Machine volume as the manual artifact volume. In the example above, the artifact root should live under `/Volumes/Data`, not `/Volumes/AppleBackups`.

These values get written into `reimage.env` for real once it's created a few steps from now (Create the Local Reimage Environment File) -- no need to edit any file yet.

If the expected external data volume is missing, jump to [[#External Data Volume Not Visible|External Data Volume Not Visible]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Confirm External Data Volume Readiness

Confirm the selected external parent volume is mounted, is not read-only, and allows the current macOS user to write at the parent path. This step checks the external drive itself before the artifact root exists.

Uses the `EXTERNAL_DATA_VOLUME`/`EXTERNAL_APPLE_BACKUPS_VOLUME` exported in the previous step -- if this is a new terminal session, re-export them first rather than sourcing `reimage.env` (it doesn't exist yet):

```bash
export EXTERNAL_DATA_VOLUME="/Volumes/<external-data-volume-name>"
export EXTERNAL_APPLE_BACKUPS_VOLUME="/Volumes/<time-machine-volume-name>"
```

Confirm the external parent volume is mounted and not read-only:

```bash
test -d "$EXTERNAL_DATA_VOLUME" && echo "OK: external data volume is mounted"
diskutil info "$EXTERNAL_DATA_VOLUME" | grep -E "Volume Name|Mount Point|File System|Read-Only|Writable|Owners|APFS"
mount | grep "$EXTERNAL_DATA_VOLUME" || true
df -h "$EXTERNAL_DATA_VOLUME"
```

Confirm the Time Machine destination volume is mounted:

```bash
test -d "$EXTERNAL_APPLE_BACKUPS_VOLUME" && echo "OK: Time Machine destination is mounted"
diskutil info "$EXTERNAL_APPLE_BACKUPS_VOLUME" | grep -E "Volume Name|Mount Point|File System|Read-Only|Writable|Owners|APFS"
df -h "$EXTERNAL_APPLE_BACKUPS_VOLUME"
```

Good signs:

```text
Volume Read-Only: No
Media Read-Only: No
```

Also inspect the parent directory ownership and ACLs. This matters on APFS external volumes with `Owners: Enabled`. Use `/bin/ls` so the command works even if your shell aliases `ls` to GNU `ls`, which does not support macOS/BSD `-e` ACL output:

```bash
if [[ -x /bin/ls ]]; then
  /bin/ls -ldeO@ "$EXTERNAL_DATA_VOLUME"
else
  ls -ld "$EXTERNAL_DATA_VOLUME"
fi

stat -f 'owner=%Su group=%Sg mode=%Sp path=%N' "$EXTERNAL_DATA_VOLUME" 2>/dev/null || stat "$EXTERNAL_DATA_VOLUME" 2>/dev/null || true
id
```

Run a parent-volume write test that does not depend on `$REIMAGE_ARTIFACT_ROOT` existing yet:

```bash
TEST_FILE="$EXTERNAL_DATA_VOLUME/reimage-parent-write-test-$(date +%Y%m%d-%H%M%S).txt"
date > "$TEST_FILE"
cat "$TEST_FILE"
rm -f "$TEST_FILE"
```

If the write test fails with `Permission denied` while `Volume Read-Only: No`, jump to [[#External Data Volume Is Writable but Current User Cannot Write|External Data Volume Is Writable but Current User Cannot Write]].

If the write test fails with `Operation not permitted`, jump to [[#Terminal Privacy Access Is Blocking External Volume Access|Terminal Privacy Access Is Blocking External Volume Access]].

If the volume is mounted read-only, jump to [[#External Data Volume Is Read Only|External Data Volume Is Read Only]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Artifact Root Naming Convention

Decide the final `REIMAGE_ARTIFACT_ROOT` path here, using the `EXTERNAL_DATA_VOLUME` exported in the previous steps. This step only computes the value as a plain shell variable -- `reimage.env` doesn't exist yet, so there's nothing to write into a file yet. The next step (Create the Local Reimage Environment File) is what actually writes it in, resolved correctly from the start.

Do **not** eventually store `REIMAGE_ARTIFACT_ROOT` in `reimage.env` as a literal string such as:

```text
$EXTERNAL_DATA_VOLUME/reimage-$ASSET_OR_HOST-$REIMAGE_START_DATE-open
```

The file should contain the resolved path, for example:

```text
/Volumes/Data/reimage-<asset-or-host>-<start-date>-open
```

The root name should describe the **whole reimage effort**, not only a single script run. Individual tools can still create timestamped folders inside the root using `YYYYMMDD-HHMMSS` when they need unique output bundles.

#### Naming goals

- Use a generic, repeatable pattern instead of a one-off machine-specific path.
- Use `-open` while backup/capture work is still active if the effort spans more than one day.
- Rename the root to `-to-<final-postimage-capture-date>` after the final post-image capture is complete.
- Optionally include `<asset-or-host>` in the backup/capture root name.
- Keep active scripts in this repo. Store only generated artifacts, logs, inventories, encrypted secret bundles, and redacted notes under `$REIMAGE_ARTIFACT_ROOT`.

#### Preferred full-effort pattern

Use one root for the full pre-image, reimage, restore, and post-image comparison effort unless there is a specific reason to split pre-image and post-image artifacts.

For a single-day reimage effort:

```text
reimage-<start-date>
```

Or with an asset/host value:

```text
reimage-<asset-or-host>-<start-date>
```

For a multi-day reimage effort:

```text
reimage-<start-date>-open
reimage-<start-date>-to-<final-postimage-capture-date>
```

Or with an asset/host value:

```text
reimage-<asset-or-host>-<start-date>-open
reimage-<asset-or-host>-<start-date>-to-<final-postimage-capture-date>
```

This guide uses the active multi-day shape by default:

```text
reimage-<asset-or-host>-<start-date>-open
```

#### Optional split-root patterns

Use these only if pre-image and post-image artifacts are intentionally separated.

```text
reimage-preimage-<asset-or-host>-<start-date>-open
reimage-preimage-<asset-or-host>-<start-date>-to-<final-preimage-capture-date>

reimage-postimage-<asset-or-host>-<reimage-date>-open
reimage-postimage-<asset-or-host>-<reimage-date>-to-<final-postimage-capture-date>
```

If the asset or hostname is intentionally omitted, keep the rest of the pattern intact:

```text
reimage-<start-date>-open
reimage-<start-date>-to-<final-postimage-capture-date>
```

#### Placeholder meanings

| Placeholder | Meaning |
|---|---|
| `<external-data-volume-name>` | Mounted external volume used for manual artifacts and evidence, for example a dedicated data/artifact volume. |
| `<asset-or-host>` | Generic asset tag or hostname placeholder. Use the actual value only in private `reimage.env`, not in shared docs. |
| `<start-date>` | `YYYYMMDD` date the reimage backup/capture effort started. |
| `<final-preimage-capture-date>` | `YYYYMMDD` date the final pre-image capture or validation completed. |
| `<reimage-date>` | `YYYYMMDD` date the Mac was reimaged. |
| `<final-postimage-capture-date>` | `YYYYMMDD` date the final post-image capture or validation completed. |

Why this is better:

- `reimage` is flexible enough to cover backup, evidence, restore, and validation artifacts.
- `-open` makes it obvious the capture set is still being built.
- `-to-<final-postimage-capture-date>` preserves the full multi-day capture window.
- Timestamped subfolders still preserve exact script-run times without making the top-level root look like a single-run artifact.

#### Compute the artifact root path

Uses the `EXTERNAL_DATA_VOLUME` exported earlier, plus an asset tag and today's date. These become `ASSET_OR_HOST`/`REIMAGE_START_DATE` in `reimage.env` in the next step -- set them here first if you want to control them rather than letting the next step auto-detect/default them:

```bash
ASSET_OR_HOST="<asset-or-host>"                 # or leave to auto-detect in the next step
REIMAGE_START_DATE="$(date +%Y%m%d)"

EXTERNAL_DATA_VOLUME="${EXTERNAL_DATA_VOLUME%/}"
export REIMAGE_ARTIFACT_ROOT="$EXTERNAL_DATA_VOLUME/reimage-$ASSET_OR_HOST-$REIMAGE_START_DATE-open"

printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
```

The printed `REIMAGE_ARTIFACT_ROOT` should be an absolute path and should not contain literal `$EXTERNAL_DATA_VOLUME`, `$ASSET_OR_HOST`, or `$REIMAGE_START_DATE` text. This exported value is what `bin/setup-reimage-env.sh` reads in the next step.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Create the Local Reimage Environment File

Create `reimage.env` now that the external data volume is confirmed ready (previous two steps) and the artifact root path is computed (previous step) -- `EXTERNAL_DATA_VOLUME`, `EXTERNAL_APPLE_BACKUPS_VOLUME`, and `REIMAGE_ARTIFACT_ROOT` should all still be exported in this same terminal session.

This file is local-only. It should not be committed.

Recommended files:

| File | Commit to repo? | Purpose |
|---|---:|---|
| `reimage.env.example` | Yes | Template showing required variables and naming conventions. |
| `reimage.env` | No | Local machine-specific config used by your terminal and scripts. |

Recommended `.gitignore` entry:

```gitignore
# Local Mac reimage workflow config
reimage.env
```

There's no `REIMAGE_ROOT` to set -- `prepare-artifact-root.py` self-locates from its own position in the repo (`bin/`), so nothing needs to be told where the repo is.

`REIMAGE_WORKSPACE_ROOT` should point to a local workspace outside this repo. By default, the Phase 1 entrypoint seeds it to the same planning folder used for the Phase 0 IT reimage confirmation so the local planning note, reusable artifact-config copies, and staged artifacts stay together unless you intentionally choose a different path.

`bin/setup-reimage-env.sh` does the following, in order, so you don't have to paste a multi-step block by hand:

1. Confirms `reimage.env.example` exists in the current directory (i.e., you're actually in the repo).
2. Confirms `reimage.env` doesn't already exist, so it never silently overwrites an existing one.
3. Confirms `EXTERNAL_DATA_VOLUME` and `REIMAGE_ARTIFACT_ROOT` are already exported (from the previous three steps) -- refuses to run otherwise, rather than silently writing blank/placeholder values you'd have to come back and fix later.
4. Copies the template to `reimage.env`.
5. Runs `prepare-artifact-root.py init-reimage-env` to fill in resolved starter values (detected hostname, today's date, default workspace paths, and the confirmed volume paths).
6. Writes the already-computed `REIMAGE_ARTIFACT_ROOT` in immediately -- not left blank for a later edit.
7. Locks the file down to `chmod 600` (owner-read-write only, since it can contain machine-specific paths).
8. Prints the result so you can review it immediately.

Run it from inside the repo:

```bash
bin/setup-reimage-env.sh
```

Review these values -- they should already be correct, since they came from the confirmed exports, not placeholders:

| Variable                     | Review rule                                                                                                                                                                                                                                                        |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `REIMAGE_WORKSPACE_ROOT`     | Must point to a local workspace outside this repo. Recommended default: the same planning folder used for the IT reimage confirmation.                                                                                                                     |
| `PERFORMANCE_HISTORY_SOURCE` | Optional. Leave blank unless you already have a reusable local performance-history source such as `~/Library/Logs/mac-memory-health`.                                                                                                                              |
| `EXTERNAL_DATA_VOLUME`         | Should already match the volume confirmed a few steps ago.                                                                                                                                                                                      |
| `EXTERNAL_APPLE_BACKUPS_VOLUME`    | Should already match the Time Machine destination volume, if one was set.                                                                                                 |
| `ASSET_OR_HOST`              | Auto-detected from hostname unless you set it explicitly in the Artifact Root Naming Convention step.                                                                                                                                                                                  |
| `REIMAGE_START_DATE`         | Defaults to today's date unless you set it explicitly in the Artifact Root Naming Convention step.                                                                                                                                                                                                                 |
| `REIMAGE_ARTIFACT_ROOT`                | Should already be the resolved absolute path computed in the Artifact Root Naming Convention step -- not blank.                                                                                                                             |
| `OFFICE_WATCH`               | Optional. Leave blank unless Office stability watcher output is part of this workflow. If used, store a resolved absolute path such as `/Users/<user>/Desktop/<office-watch-folder>`, not a literal `$HOME/...` string. `artifact-config.sh` shares it with scripts. |
| `ONEDRIVE_FOLDER_NAME`       | Optional. Use only when the local OneDrive folder should be resolved under `$HOME/Library/CloudStorage/`. Leave blank if OneDrive is not used.                                                                                                                     |
| `ONEDRIVE_ROOT`              | Optional. Prefer a resolved absolute path to the local OneDrive sync folder when OneDrive is used. Leave blank if OneDrive is not used. Do not store a literal `$HOME/...` string.                                                                                 |
| `ONEDRIVE_DEST_SUBDIR`       | Already defaulted to the artifact root folder name by `setup-reimage-env.sh`.                                                                                            |

If the repo is not cloned yet, use [[#Confirm reimage.env Is Loaded|Confirm reimage.env Is Loaded]] to clone it, then return to the start of Sequential Steps.

Do not store helper-variable references such as `REIMAGE_START_DATE_DEFAULT`, `ASSET_OR_HOST_DEFAULT`, literal `$EXTERNAL_DATA_VOLUME` values, or literal `$HOME/...` optional paths in `reimage.env`. The file should contain resolved values only. If a script reports an unbound variable while sourcing `reimage.env`, or a verification step prints a path such as `$HOME/Desktop/...`, jump to [[#reimage.env Contains Helper Variables or Literal Paths|reimage.env Contains Helper Variables or Literal Paths]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Set Up direnv (.envrc)

This makes `reimage.env` load automatically whenever you `cd` into this repo, and unload automatically the moment you `cd` out — no manual `source` needed each terminal session.

Prerequisite, if not already installed:

```bash
brew install direnv
```

Add the hook to `.zshrc` once, if not already there (must run before any tool like SDKMAN that requires being the literal last line — direnv doesn't need to be last, just present):

```bash
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
```

Open a new terminal so the hook takes effect, then create `.envrc` in the repo root:

```bash
cat > .envrc << 'EOF'
export FRACTOGENESIS_HOME="$(pwd)"

if [[ -f "$(pwd)/reimage.env" ]]; then
  dotenv reimage.env
fi

PATH_add bin
EOF
```

direnv refuses to load a new `.envrc` until you explicitly approve it — a safety gate so a repo can't silently run code on you just by `cd`ing in:

```bash
direnv allow
```

Confirm it worked:

```bash
printf 'FRACTOGENESIS_HOME=%s\n' "$FRACTOGENESIS_HOME"
printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
```

Both should print resolved values with no further action. `cd` out of the repo and both should be unset; `cd` back in and both should reappear — that round trip is the actual proof direnv is doing its job, not just that the file exists.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Confirm reimage.env Is Loaded

Confirm your shell has `reimage.env` loaded correctly — there's no `REIMAGE_ROOT` to check anymore, since the repo's location is no longer stored in a variable at all.

If you just set up direnv above, open a new terminal and confirm a resolved value is available:

```bash
printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
```

If your shell does not load `reimage.env` automatically yet, source it by absolute path for this terminal session, then `cd` into the repo:

```bash
REIMAGE_ENV="/path/to/<repo-checkout>/reimage.env"
set -a
source "$REIMAGE_ENV"
set +a
unset REIMAGE_ENV

cd "$(dirname "$REIMAGE_ENV")"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Define Git Repository Roots

Define the local repository root directories in `reimage.env` before the Git backup phase.

These values tell the Git helper scripts where to search for repositories. They should point to parent folders that contain one or more Git repositories, not necessarily to a single repo.

You do **not** need both roots. `GIT_WORK_REPO_ROOT` should be created and set for the normal work/corporate repo path. `GIT_PERSONAL_REPO_ROOT` is optional and can stay blank when you do not maintain a separate personal/reference repo area on this Mac.

Common examples:

| Variable                 | Purpose                                        | Example shape                            |
| ------------------------ | ---------------------------------------------- | ---------------------------------------- |
| `GIT_WORK_REPO_ROOT`     | Work/corporate development repositories.       | `/Users/<user>/Development/IdeaProjects` |
| `GIT_PERSONAL_REPO_ROOT` | Personal/reference/documentation repositories. | `/Users/<user>/Development/personal`     |

Keep these values in `reimage.env` as resolved absolute paths. Do not write literal values such as `$HOME/path/to/repos` or `${GIT_WORK_REPO_ROOT:-...}` into `reimage.env`; those can become stale or fail under `set -u`.

Set the values in the current shell first. Use real paths for this Mac. Create the work root even if the personal root stays blank:

```bash

export GIT_WORK_REPO_ROOT_VALUE="$HOME/path/to/work/repos"
mkdir -p "$GIT_WORK_REPO_ROOT_VALUE"

export GIT_PERSONAL_REPO_ROOT_VALUE=""
# Example only when you intentionally use a second personal/reference repo root:
# export GIT_PERSONAL_REPO_ROOT_VALUE="$HOME/path/to/personal/repos"
# mkdir -p "$GIT_PERSONAL_REPO_ROOT_VALUE"
```

Write the resolved Git root values into `reimage.env`:

```bash
python3 bin/prepare-artifact-root.py \
  upsert-env \
  --env-file reimage.env \
  "GIT_WORK_REPO_ROOT=${GIT_WORK_REPO_ROOT_VALUE%/}" \
  "GIT_PERSONAL_REPO_ROOT=${GIT_PERSONAL_REPO_ROOT_VALUE%/}"
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

### Create the Artifact Root

By this point `reimage.env` already has `REIMAGE_ARTIFACT_ROOT` resolved correctly -- it was written in at creation time, not left blank. This step runs the entrypoint that actually creates the directory on the external volume.

This is the command that actually creates the dedicated backup/capture directory. Do not continue to the standard directory layout step until it prints both:

```text
OK: REIMAGE_ARTIFACT_ROOT is under EXTERNAL_DATA_VOLUME
OK: backup root exists
```

Run the Phase 1 entrypoint from the repo root:

```bash
python3 bin/prepare-artifact-root.py \
  create-artifact-root \
  --env-file reimage.env
```

If the entrypoint reports literal variable text in `REIMAGE_ARTIFACT_ROOT`, something upstream wasn't actually resolved. Reload `reimage.env` and confirm `REIMAGE_ARTIFACT_ROOT` prints a real path before rerunning.

If you previously ran the targeted `sudo mkdir` repair while `REIMAGE_ARTIFACT_ROOT` still printed literal variable text such as `$EXTERNAL_DATA_VOLUME/reimage-$ASSET_OR_HOST-$REIMAGE_START_DATE-open`, that earlier repair did **not** create the real external-drive folder. It likely created a relative folder named `$EXTERNAL_DATA_VOLUME` under the directory where the command was run.

Check for and remove that accidental literal folder only after confirming it is under this repo's checkout and not under `/Volumes`:

```bash

if [[ -d './$EXTERNAL_DATA_VOLUME' ]]; then
  echo "Found accidental literal folder under the repo checkout:"
  /bin/ls -la './$EXTERNAL_DATA_VOLUME' 2>/dev/null || ls -la './$EXTERNAL_DATA_VOLUME'

  echo
  echo "Remove it only if this is the accidental folder from the earlier literal REIMAGE_ARTIFACT_ROOT repair."
  # rm -rf './$EXTERNAL_DATA_VOLUME'
else
  echo "OK: no accidental literal ./\$EXTERNAL_DATA_VOLUME folder found under the repo checkout"
fi
```

Then confirm `REIMAGE_ARTIFACT_ROOT` prints as an absolute `/Volumes/...` path before running any `sudo mkdir` repair again.

If the create step fails, stop and use the linked troubleshooting section before continuing:

- `Permission denied` → [[#External Data Volume Is Writable but Current User Cannot Write|External Data Volume Is Writable but Current User Cannot Write]]
- `Operation not permitted` → [[#Terminal Privacy Access Is Blocking External Volume Access|Terminal Privacy Access Is Blocking External Volume Access]]
- literal variable text or empty values → [[#reimage.env Contains Helper Variables or Literal Paths|reimage.env Contains Helper Variables or Literal Paths]]

#### Rename after final post-image capture

After the final post-image capture is complete, rename the root if the effort spanned multiple days:

```bash
set -a
source ./reimage.env
set +a

FINAL_POSTIMAGE_CAPTURE_DATE="<final-postimage-capture-date>"
FINAL_REIMAGE_ARTIFACT_ROOT="${EXTERNAL_DATA_VOLUME%/}/reimage-${ASSET_OR_HOST}-${REIMAGE_START_DATE}-to-${FINAL_POSTIMAGE_CAPTURE_DATE}"

mv "$REIMAGE_ARTIFACT_ROOT" "$FINAL_REIMAGE_ARTIFACT_ROOT"
export REIMAGE_ARTIFACT_ROOT="$FINAL_REIMAGE_ARTIFACT_ROOT"

python3 bin/prepare-artifact-root.py \
  upsert-env \
  --env-file reimage.env \
  "REIMAGE_ARTIFACT_ROOT=$REIMAGE_ARTIFACT_ROOT"
```

If you rename the root later, update `REIMAGE_ARTIFACT_ROOT` in `reimage.env` before running more scripts.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Load and Confirm the Environment

Load the local config into the current terminal after the backup/capture root has been created:

```bash

set -a
source ./reimage.env
set +a
```

Then run the Phase 1 confirmation entrypoint:

```bash
python3 bin/prepare-artifact-root.py \
  confirm-env \
  --env-file reimage.env
```

If the helper reports a `REIMAGE_ARTIFACT_ROOT` or literal-path error, stop here and use the relevant troubleshooting section before continuing.

If you set up direnv earlier, this already persists automatically across terminal sessions -- no manual `.zshrc` block needed. See [[#Set Up direnv (.envrc)|Set Up direnv (.envrc)]] if you haven't yet.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Create the Standard Directory Layout

Create only the stable top-level generated-artifact directories owned by this preparation guide. Optional evidence-capture roots are created later by the capture guides that actually use them. Child directories belong to the runbook or script that creates them.

For example:

- `secrets-encrypted/` is created here only as a top-level container.
- nested secrets folders are created later by the secrets runbook, manual staging steps, `backup-local-files.sh`, or `create-secrets-dmg.sh`.
- `reimage-plan/` is created here so the filled Phase 0 IT confirmation can be copied into the external root during Phase 1.
- workflow snapshot child folders are created later by `capture-workflow-snapshot.md`.

```bash
python3 bin/prepare-artifact-root.py \
  create-standard-layout \
  --env-file reimage.env
```

Layout after this step, top-level directories only:

```text
$REIMAGE_ARTIFACT_ROOT/
├── app-backups/
├── reimage-prep-checks/
├── git-audit-reports/
├── gitignore-superset/
├── local-files/
├── reimaged-system/
├── reimage-plan/
├── secrets-encrypted/
├── selected-ignored-files/
├── selected-ignored-files-dryrun/
├── selected-ignored-files-filtered-dryrun/
├── time-machine/
└── workflow-snapshot/
```

For child-directory details, use the guide that owns that workflow. For example, `backup-dmg-secrets.md` owns the expected `secrets-encrypted/` staging, DMG, validation, and cleanup layout.

Folder purpose:

| Folder | Purpose                                                                                                                                                                                                                                 |
|---|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `app-backups/` | App-specific exported settings, inventories, notes, and app-owned restore artifacts such as Chrome bookmarks, Docker settings, Postman exports, Raycast exports, Obsidian copies, VS Code fallback state, and IntelliJ backup material. |
| `reimage-prep-checks/` | Final reimage preparation checks go/no-go checklist reports.                                                                                                                                                                            |
| `git-audit-reports/` | Git state reports; not a full source backup.                                                                                                                                                                                            |
| `gitignore-superset/` | Reviewable superset of ignored patterns across repos.                                                                                                                                                                                   |
| `local-files/` | Home folders, dotfiles, and selected local files copied by `backup-local-files.sh`.                                                                                                                                                     |
| `reimage-plan/` | Filled copy of the Phase 0 IT reimage confirmation kept with the external backup root from the start of the reimage effort.                                                                                                             |
| `secrets-encrypted/` | Top-level container for the secrets workflow. Nested secret staging folders, final DMG artifacts, Java inventory, certificate review reports, and restore README are created later by the owning secrets steps.                         |
| `selected-ignored-files/` | Final selected ignored/local file copies needed for restore.                                                                                                                                                                            |
| `selected-ignored-files-dryrun/` | Initial dry-run output for selected ignored/local file backups.                                                                                                                                                                         |
| `selected-ignored-files-filtered-dryrun/` | Filtered dry-run output after exclusions are applied.                                                                                                                                                                                   | |
| `time-machine/` | Time Machine status capture bundles only. Actual Time Machine backups live on the Time Machine volume.                                                                                                                                  |
| `reimaged-system/` | Initial enrollment captures and checks, reimaged system evidence, restart notes, restore notes, Time Machine notes, and final validation artifacts.                                                                                     |

Do not create a normal `$REIMAGE_ARTIFACT_ROOT/scripts` folder. Scripts live in this repo (`bin/`, `.internal/`).

#### Copy the filled IT reimage confirmation into reimage-plan

After the standard layout exists, copy the filled Phase 0 IT confirmation into the new top-level `reimage-plan/` folder:

```bash
python3 bin/prepare-artifact-root.py \
  copy-it-plan \
  --env-file reimage.env
```

This looks for the newest `it-reimage-confirmation-*.md` under `IT_PLAN_DIR` (if set in `reimage.env`), otherwise under `<REIMAGE_WORKSPACE_ROOT>/reimage-planning/`.

If you do not want to persist `IT_PLAN_DIR` or `REIMAGE_WORKSPACE_ROOT` in `reimage.env`, pass the workspace root directly instead:

```bash
python3 bin/prepare-artifact-root.py \
  copy-it-plan \
  --env-file reimage.env \
  --workspace-root "$REIMAGE_WORKSPACE_ROOT"
```

This searches `<REIMAGE_WORKSPACE_ROOT>/reimage-planning/` without requiring either variable to already be defined in `reimage.env` (`--workspace-root` is ignored if `IT_PLAN_DIR` is already set there, or if `--source` is used).

If the filled note is not under `IT_PLAN_DIR` or `REIMAGE_WORKSPACE_ROOT`, provide the explicit source path:

```bash
python3 bin/prepare-artifact-root.py \
  copy-it-plan \
  --env-file reimage.env \
  --source "/absolute/path/to/it-reimage-confirmation-YYYYMMDD.md"
```

Expected destination:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-plan/it-reimage-confirmation-YYYYMMDD.md
```

The entrypoint preserves the source filename and saves a timestamped `.previous-*` backup only when the destination already exists and differs.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Understand artifact-config.sh

`artifact-config.sh` is the single source of truth for local-file backup targets, excludes, descriptions, and expected top-level folders used by the backup scripts.

The arrays and flags are now stored in reusable shell config fragments instead of being hard-coded inline in the loader. Shell fragments were chosen instead of YAML so the existing bash scripts can source them directly while keeping the annotation comments intact.

It is sourced by scripts such as:

```text
bin/backup-local-files.sh
bin/capture-size-audit.sh
bin/capture-workflow-snapshot.sh
bin/create-secrets-dmg.sh
```

Do not run it directly.

Important behavior:

| Behavior | Meaning |
|---|---|
| It self-locates `REPO_ROOT` from its own script path (parent of `.internal/`). | Sourcing scripts must reference it by its actual path relative to the repo root, e.g. `bin/backup-local-files.sh` — there's no `REIMAGE_ROOT` variable to fall back on. |
| It loads `reimage.env` if present. | Your local `REIMAGE_ARTIFACT_ROOT` plus optional `OFFICE_WATCH`, `ONEDRIVE_FOLDER_NAME`, `ONEDRIVE_ROOT`, and related paths are shared with scripts. |
| It defines `EXTERNAL_APPLE_BACKUPS_VOLUME`. | Time Machine scripts use this as the backup destination mount path instead of assuming the destination volume is named `AppleBackups`. |
| It exits if `REIMAGE_ARTIFACT_ROOT` is empty. | Create and source `reimage.env` before running scripts that depend on the backup root. |
| It prefers workspace-backed config fragments when they exist. | `REIMAGE_WORKSPACE_ROOT/artifact-config/` becomes the reusable local copy for reruns; otherwise the loader falls back to `.internal/templates/artifact-config/`. |
| It defines `EXTERNAL_TARGETS`. | These become subfolders under `$REIMAGE_ARTIFACT_ROOT/local-files/`. |
| It defines OneDrive handling. | `ONEDRIVE_ROOT` should be a full path, or `ONEDRIVE_FOLDER_NAME` can be used to resolve a folder under `~/Library/CloudStorage/`. Do not use a bare OneDrive folder name relative to the current directory. |
| It defines `SECRETS_TARGETS`. | These become file or directory entries under `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/`. Use `certs/` for certificate/keystore material and `certs/java-security/` for Java `jssecacerts`. |
| It defines `EXTERNAL_EXCLUDES` and `ONEDRIVE_EXTRA_EXCLUDES`. | Add backup exclusions in config, not in each script. |
| It defines `EXPECTED_BACKUP_FOLDERS`. | Keep this aligned with the stable top-level folders created by this guide. Optional evidence roots are created later by capture guides. |

Current expected top-level folders from `artifact-config.sh`:

```text
app-backups
reimage-prep-checks
git-audit-reports
gitignore-superset
local-files
reimaged-system
reimage-plan
secrets-encrypted
selected-ignored-files
selected-ignored-files-dryrun
selected-ignored-files-filtered-dryrun
time-machine
workflow-snapshot
```

The layout created in [[#Create the Standard Directory Layout|Create the Standard Directory Layout]] includes only the stable top-level folders. Child folders for setup notes, secrets staging, optional evidence captures, and other workflow-owned artifacts are created later by their owning runbooks or scripts.

Initialize the reusable workspace-backed config fragments:

```bash
python3 bin/prepare-artifact-root.py \
  init-artifact-config \
  --env-file reimage.env
```

This copies the template fragments into:

```text
$REIMAGE_WORKSPACE_ROOT/artifact-config/
```

Use that workspace copy when you rerun backups later and most of the target/exclude config has not changed. You can adjust only the files that actually changed instead of rebuilding the full artifact-config setup from scratch.

Before running local-file backup scripts, confirm the loader can still be parsed:

```bash
bash -n .internal/artifact-config.sh
```

If a script reports that `REIMAGE_ARTIFACT_ROOT` is not set, jump to [[#REIMAGE_ARTIFACT_ROOT Is Empty in Scripts|REIMAGE_ARTIFACT_ROOT Is Empty in Scripts]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Verify the Prepared Root

Run the verification helper after creating the standard layout and sourcing `reimage.env`:

```bash
python3 bin/prepare-artifact-root.py \
  verify-prepared-root \
  --env-file reimage.env
```

The phase is ready when:

```text
external data/artifact volume is mounted
external parent-volume write test succeeds
REIMAGE_ARTIFACT_ROOT follows the selected reimage naming pattern
reimage.env is created locally and not committed
standard generated-artifact top-level directories exist
write test succeeds without sudo
artifact-config.sh can be parsed with bash -n
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Use this section only when a sequential step fails.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### External Data Volume Not Visible

Symptoms:

```text
/Volumes/<external-data-volume-name> is missing
diskutil list external does not show the expected external disk
only Macintosh HD appears under /Volumes
```

Check mounted volumes:

```bash
ls -la /Volumes
diskutil list external
diskutil apfs list
```

Try:

```text
unplug/replug the external drive
try another cable
try another port
open Disk Utility
mount the expected external volume manually
```

Do not erase, repair, repartition, or reformat the external drive until you are certain which disk and volume you are looking at.

Return to: [[#Choose the External Data Volume|Choose the External Data Volume]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### External Data Volume Is Read Only

Symptoms:

```text
Volume Read-Only: Yes
Media Read-Only: Yes
mkdir fails even though the volume is visible
touch fails on the external data volume
```

Check the volume:

```bash
diskutil info "$EXTERNAL_DATA_VOLUME" | grep -E "Volume Name|Mount Point|File System|Read-Only|Writable|Owners|APFS"
mount | grep "$EXTERNAL_DATA_VOLUME"
df -h "$EXTERNAL_DATA_VOLUME"
```

Good signs:

```text
Volume Read-Only: No
Media Read-Only: No
```

If the volume is mounted read-only, stop and inspect the drive in Disk Utility. Do not force repair or erase during the reimage workflow unless you have already confirmed the disk identity and have another known-good backup.

Return to: [[#Confirm External Data Volume Readiness|Confirm External Data Volume Readiness]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### External Data Volume Is Writable but Current User Cannot Write

Symptoms:

```text
Volume Read-Only: No
Media Read-Only: No
Owners: Enabled
mkdir: cannot create directory '/Volumes/<external-data-volume-name>/reimage-<asset-or-host>-<start-date>-open': Permission denied
zsh: permission denied: /Volumes/<external-data-volume-name>/reimage-parent-write-test-YYYYMMDD-HHMMSS.txt
```

This means the disk is writable, but the current macOS user does not have write permission at the selected parent path. Full Disk Access does not override normal Unix ownership, ACL, or mode restrictions on the APFS volume.

Inspect the parent volume root with the helper:

```bash
python3 bin/prepare-artifact-root.py \
  diagnose-external-root \
  --env-file reimage.env
```

Recommended repair: create only the reimage backup/capture root with elevated permissions once, then hand that folder back to the current user. Do not run the rest of the backup workflow with `sudo`.

Use numeric UID/GID values instead of group names. This is safer on corporate or directory-service accounts where `id -gn` can fail even though `id -g` returns a valid primary group ID.

```bash
python3 bin/prepare-artifact-root.py \
  repair-artifact-root-perms \
  --env-file reimage.env
```

If `id -gn` prints an error such as `cannot find name for group ID ...`, that is not a blocker for this repair. The numeric `id -g` value is the group value to use with `chown`.

Use `chmod 700` if the root will contain secrets staging, restore notes, or local machine evidence. If the backup root must be readable by another trusted local admin account, choose a more permissive mode intentionally instead of broadly changing the whole external volume.

Avoid these during the reimage workflow unless you are deliberately changing the entire external volume policy:

```text
sudo chmod -R ... /Volumes/<external-data-volume-name>
sudo chown -R ... /Volumes/<external-data-volume-name>
sudo diskutil disableOwnership ...
```

Those broader changes can affect Time Machine-adjacent data, other folders, or future restore behavior. Prefer repairing only the dedicated `$REIMAGE_ARTIFACT_ROOT`.

After the repair succeeds, return to [[#Create the Artifact Root|Create the Artifact Root]] and rerun the create helper, then continue with [[#Load and Confirm the Environment|Load and Confirm the Environment]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Terminal Privacy Access Is Blocking External Volume Access

Symptoms:

```text
mkdir: cannot create directory '/Volumes/<external-data-volume-name>/reimage-<asset-or-host>-<start-date>-open': Operation not permitted
touch: ... Operation not permitted
```

Use this section for `Operation not permitted`. If the error says `Permission denied`, use [[#External Data Volume Is Writable but Current User Cannot Write|External Data Volume Is Writable but Current User Cannot Write]] first.

The likely fix is to grant the terminal app external-volume access or Full Disk Access, then rerun directory creation without relying on `sudo`.

Open:

```text
System Settings
Privacy & Security
Full Disk Access
```

Enable the terminal app being used:

```text
Terminal
iTerm
Warp
VS Code
IntelliJ IDEA
```

Also check:

```text
System Settings
Privacy & Security
Files and Folders
```

Enable removable or external volume access if present.

Fully quit and reopen the terminal app after changing permissions.

Retry the create helper without `sudo`:

```bash
python3 bin/prepare-artifact-root.py \
  create-artifact-root \
  --env-file reimage.env
```

If this still fails, confirm the drive is not mounted read-only and inspect ownership with [[#External Data Volume Is Writable but Current User Cannot Write|External Data Volume Is Writable but Current User Cannot Write]]. Do not erase, repair, or repartition the external drive until you are certain which disk and volume you are looking at.

Return to: [[#Create the Artifact Root|Create the Artifact Root]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### REIMAGE_ARTIFACT_ROOT Is Empty in Scripts

Symptoms:

```text
REIMAGE_ARTIFACT_ROOT is not set. Create/source reimage.env or pass an explicit output path.
```

Confirm the file exists:

```bash
ls -la reimage.env
cat reimage.env
```

Reload it:

```bash

set -a
source ./reimage.env
set +a

printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
```

Confirm the config file can be parsed:

```bash
bash -n .internal/artifact-config.sh
```

If running a script from another terminal window, that terminal may not have sourced `reimage.env`.

Either source it in the terminal:

```bash
set -a
source ./reimage.env
set +a
```

Or add the optional zsh persistence block from [[#Load and Confirm the Environment|Load and Confirm the Environment]].

Return to: [[#Understand artifact-config.sh|Understand artifact-config.sh]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### reimage.env Contains Helper Variables or Literal Paths

Symptoms:

```text
reimage.env: line 7: REIMAGE_START_DATE_DEFAULT: unbound variable
REIMAGE_ARTIFACT_ROOT=<$EXTERNAL_DATA_VOLUME/reimage-$ASSET_OR_HOST-$REIMAGE_START_DATE-open>
OFFICE_WATCH=$HOME/Desktop/ms-office-stability-watch
REIMAGE_ARTIFACT_ROOT or an optional path contains literal variable text instead of a resolved path
```

This means `reimage.env` contains helper-variable references or quoted literal paths instead of resolved values. `reimage.env` should be boring: one `export NAME=value` line per setting, with actual values. Optional paths should either be blank or absolute resolved paths.

Inspect the file:

```bash
grep -nE 'REIMAGE_START_DATE_DEFAULT|ASSET_OR_HOST_DEFAULT|\$EXTERNAL_DATA_VOLUME|\$ASSET_OR_HOST|\$REIMAGE_START_DATE|\$HOME|REIMAGE_ARTIFACT_ROOT|OFFICE_WATCH|ONEDRIVE_ROOT|REIMAGE_START_DATE|ASSET_OR_HOST|EXTERNAL_DATA_VOLUME|EXTERNAL_APPLE_BACKUPS_VOLUME' \
  reimage.env
```

Repair it with one command -- recomputes `REIMAGE_ARTIFACT_ROOT` from `EXTERNAL_DATA_VOLUME`/`ASSET_OR_HOST`/`REIMAGE_START_DATE`, and resolves any literal `$HOME` text in `OFFICE_WATCH`/`ONEDRIVE_ROOT`. Safe to run even if the file currently has unbound-variable references -- it explicitly disables shell nounset before sourcing, so it isn't affected by your own shell profile's settings:

```bash
python3 bin/prepare-artifact-root.py \
  repair-literal-paths \
  --env-file reimage.env
```

Reload and confirm the repair took effect:

```bash
set -a
source ./reimage.env
set +a

printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
printf 'OFFICE_WATCH=%s\n' "${OFFICE_WATCH:-}"
printf 'ONEDRIVE_ROOT=%s\n' "${ONEDRIVE_ROOT:-}"
```

If the terminal prompt prints an error such as `virtualenv_info:1: VIRTUAL_ENV: parameter not set`, run this in the current terminal window:

```bash
set +u
```

That prompt error means shell nounset mode was enabled while the prompt/theme expected optional variables such as `VIRTUAL_ENV` to be unset sometimes. It is not a artifact-root failure.

Then return to [[#Load and Confirm the Environment|Load and Confirm the Environment]].

Return to: [[#Load and Confirm the Environment|Load and Confirm the Environment]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Directory Verification Is Missing Folders

Symptoms:

```text
MISSING: app-backups
MISSING: local-files
MISSING: secrets-encrypted
```

Rerun the standard directory creation helper:

```bash
python3 bin/prepare-artifact-root.py \
  create-standard-layout \
  --env-file reimage.env
```

This rerun creates only the stable top-level folders. It must not create any child folders under optional capture roots. If a missing folder is a workflow-owned child folder such as `secrets-encrypted/certs/keychain-manual-exports/`, `secrets-encrypted/extra-secrets-certs-review/`, `system-inventory/`, `performance-audit/`, or `office-stability/`, go back to the owning runbook or script instead of adding it here.

Then rerun [[#Verify the Prepared Root|Verify the Prepared Root]].

Return to: [[#Verify the Prepared Root|Verify the Prepared Root]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### OneDrive Backup Wrote Under the Repo Checkout

Symptoms:

```text
<repo checkout>/<OneDrive-folder-name>/ exists
OneDrive backup output is under the repo checkout instead of ~/Library/CloudStorage
The script printed OneDrive dest as a relative path
```

The cause is usually a local config value like this:

```bash
ONEDRIVE_ROOT="<OneDrive-folder-name>"
```

That bare folder name can be interpreted relative to the current working directory by older script versions. The correct root is the full CloudStorage-backed OneDrive folder path:

```bash
ONEDRIVE_FOLDER_NAME="<OneDrive-folder-name>"
export ONEDRIVE_ROOT="$HOME/Library/CloudStorage/$ONEDRIVE_FOLDER_NAME"
export ONEDRIVE_DEST_SUBDIR="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"
```

After updating `reimage.env`, reload it and run a dry run:

```bash
set -a
source ./reimage.env
set +a

printf 'ONEDRIVE_ROOT=%s\n' "$ONEDRIVE_ROOT"
./bin/backup-local-files.sh --dry-run --onedrive-only
```

If a previous run already created the wrong folder, copy it into the real OneDrive root before removing anything (run this from inside the repo checkout, since `$(pwd)` below assumes that):

```bash
ONEDRIVE_FOLDER_NAME="<OneDrive-folder-name>"
WRONG_ONEDRIVE_ROOT="$(pwd)/$ONEDRIVE_FOLDER_NAME"
RIGHT_ONEDRIVE_ROOT="$HOME/Library/CloudStorage/$ONEDRIVE_FOLDER_NAME"
BACKUP_BASENAME="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"

if [[ -d "$WRONG_ONEDRIVE_ROOT/$BACKUP_BASENAME" ]]; then
  mkdir -p "$RIGHT_ONEDRIVE_ROOT/$BACKUP_BASENAME"
  rsync -a "$WRONG_ONEDRIVE_ROOT/$BACKUP_BASENAME/" "$RIGHT_ONEDRIVE_ROOT/$BACKUP_BASENAME/"
  mv "$WRONG_ONEDRIVE_ROOT" "$WRONG_ONEDRIVE_ROOT.migrated-$(date +%Y%m%d-%H%M%S)"
fi
```

Do not delete the migrated folder until the OneDrive menu bar shows no sync errors and a OneDrive web spot-check confirms the expected backup folder and files are visible.

Return to: [[#Understand artifact-config.sh|Understand artifact-config.sh]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Manual Export-Only Fallback

Use this only for a temporary shell session when you intentionally do not want to create `reimage.env`. The normal workflow is still [[#Create the Local Reimage Environment File|Create the Local Reimage Environment File]].

```bash
export REIMAGE_WORKSPACE_ROOT="$HOME/Documents/reimage-workspace"
export EXTERNAL_DATA_VOLUME="/Volumes/<external-data-volume-name>"
export EXTERNAL_APPLE_BACKUPS_VOLUME="/Volumes/<time-machine-volume-name>"
export ASSET_OR_HOST="<asset-or-host>"
export REIMAGE_START_DATE="$(date +%Y%m%d)"
export REIMAGE_ARTIFACT_ROOT="$EXTERNAL_DATA_VOLUME/reimage-$ASSET_OR_HOST-$REIMAGE_START_DATE-open"

# Optional. Leave blank unless these workflows are used.
export OFFICE_WATCH=""
export ONEDRIVE_FOLDER_NAME=""
export ONEDRIVE_ROOT=""
export ONEDRIVE_DEST_SUBDIR="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"
```

For repeatable reimage work, write those values to `reimage.env` instead of relying on terminal history.

Return to: [[#Create the Local Reimage Environment File|Create the Local Reimage Environment File]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Permission Issues Restoring Files

This issue usually appears later during restore, but it is useful to keep the reference here.

Check ownership and mode:

```bash
ls -la path/to/file
stat path/to/file
```

Fix only files you own:

```bash
chmod 600 path/to/secret-file
chmod 644 path/to/non-secret-config
```

For restored SSH keys:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/*.pub
```

Do not broadly `chmod -R` the whole backup root or home directory.

Return to: [[#Verify the Prepared Root|Verify the Prepared Root]]

[[#Table of Contents|⬆ Back to Table of Contents]]
