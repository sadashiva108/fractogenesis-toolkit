[[reimaging-guide#Phase 1 — Prepare the External Artifact Root|← Back to Mac Reimaging Guide]]

# Prepare Artifact Root

**Last updated:** 2026-08-13

Run-book for preparing the external backup/capture location before running pre-image backups, evidence captures, validation scripts, restore steps, and post-image comparison captures.

Recommended path: create the local `reimage.env` file first, then source it in each terminal session. This guide uses `reimage.env` as the normal source of truth for `REIMAGE_WORKSPACE_ROOT`, `EXTERNAL_DATA_VOLUME`, `EXTERNAL_APPLE_BACKUPS_VOLUME`, and `REIMAGE_ARTIFACT_ROOT`. Manual export-only commands are kept later as a fallback, not as the normal path.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Preparation Sequence|Preparation Sequence]]
    - [[#Repo, Workspace, and External Drive Boundary|Repo, Workspace, and External Drive Boundary]]
    - [[#Artifact Root Naming Convention|Artifact Root Naming Convention]]
    - [[#About artifact-config.sh|About artifact-config.sh]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Confirm the Repo Is Cloned|Confirm the Repo Is Cloned]]
    - [[#Choose the External Data Volume|Choose the External Data Volume]]
    - [[#Confirm External Data Volume Readiness|Confirm External Data Volume Readiness]]
    - [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]]
    - [[#Set Up direnv|Set Up direnv]]
    - [[#Create the Artifact Root|Create the Artifact Root]]
    - [[#Load and Confirm the Environment|Load and Confirm the Environment]]
    - [[#Set Up the artifact-config Fragments|Set Up the artifact-config Fragments]]
    - [[#Create the Standard Directory Layout|Create the Standard Directory Layout]]
    - [[#Copy the Filled IT Reimage Confirmation Into reimage-confirmation|Copy the Filled IT Reimage Confirmation Into reimage-confirmation]]
    - [[#Verify the Prepared Root|Verify the Prepared Root]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Repo Path Variables and Self-Locating Scripts|Repo Path Variables and Self-Locating Scripts]]
    - [[#reimage.env Must Contain Resolved Values, Not Literal References|reimage.env Must Contain Resolved Values, Not Literal References]]
- [[#Troubleshooting|Troubleshooting]]
    - [[#External Data Volume Not Visible|External Data Volume Not Visible]]
    - [[#External Data Volume Is Read Only|External Data Volume Is Read Only]]
    - [[#Can't Write to the Volume|Can't Write to the Volume]]
    - [[#Terminal Privacy Block|Terminal Privacy Block]]
    - [[#REIMAGE_ARTIFACT_ROOT Is Empty in Scripts|REIMAGE_ARTIFACT_ROOT Is Empty in Scripts]]
    - [[#Literal Paths in reimage.env|Literal Paths in reimage.env]]
    - [[#Folder Under the Repo|Folder Under the Repo]]
    - [[#Empty / Unrecognized|Empty / Unrecognized]]
    - [[#Directory Verification Is Missing Folders|Directory Verification Is Missing Folders]]
    - [[#Permission Issues Restoring Files|Permission Issues Restoring Files]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

`prepare-artifact-root` is the first phase of the reimage workflow — it establishes the environment and the storage every later phase builds on.

**What it sets up**

- **The local reimage environment** — `reimage.env` with resolved machine-specific values, direnv auto-loading, and the `artifact-config` fragments that drive the backup and capture scripts.
- **The external artifact root** — one dated, per-Mac directory on the chosen volume, its standard top-level folders, the filled IT reimage confirmation, and an end-to-end verification gate.

**What the rest of the workflow relies on it for**

- A single, resolvable `REIMAGE_ARTIFACT_ROOT` that every downstream phase reads from `reimage.env` and writes under.
- A consistent folder layout so backups, captures, reimage evidence, and restore notes all land in one predictable place.

**Ownership**

| This runbook owns | Owned elsewhere (fills the root later) |
|---|---|
| `reimage.env` — resolved values + direnv loading | app / repo / home backups — `backup-*.md` |
| `artifact-config` fragments | managed inventory + evidence captures — `capture-*.md` |
| the external root: creation, naming, standard folders | Time Machine status |
| the IT reimage confirmation drop-in | the reimage itself |
| end-to-end verification | restore / enrollment / validation — `restore-*.md` |

The root houses everything later phases generate: the reimage plan copy, app backups, system inventory, performance and Office-stability evidence, Time Machine status, reimage-prep go/no-go reports, reimaged-system captures, enrollment and validation bundles, and redacted restore notes.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

These are the standard top-level folders this phase creates — the ones
needed on every reimage run, regardless of symptoms or which situational
phases apply. Folders tied to a situational capture, such as a performance
or Office-stability symptom, are created later by that phase's own script
when it actually runs, not here. 

```text
$REIMAGE_ARTIFACT_ROOT/
├── app-settings-backup/
├── gitignore-superset/
├── home-files-backup/
├── loose-secrets-reports/
├── managed-inventory/
├── public-certs/
├── reimage-confirmation/
├── reimage-prep-checks/
├── reimaged-system/
├── repo-audit-reports/
├── secrets-encrypted/
├── size-audit-reports/
├── staged-ignored-files/
├── system-inventory/
├── time-machine/
└── toolkit-snapshot/
```
See [Master Directory Reference](./references/master-directory-reference.md) for the full tree with per-folder descriptions.

Script locations:

```text
$FRACTOGENESIS_HOME/bin/                          # entrypoints -- run directly
$FRACTOGENESIS_HOME/bin/check-reimage-env.sh      # diagnostic -- reports whether reimage.env already exists, never writes
$FRACTOGENESIS_HOME/bin/setup-reimage-env.sh      # creates reimage.env, fully resolved, in one pass
$FRACTOGENESIS_HOME/bin/prepare-artifact-root.py  # invoked via subcommands, e.g. `python3 bin/prepare-artifact-root.py init-reimage-env` -- not run bare
$FRACTOGENESIS_HOME/.internal/                    # sourced-only helpers, never run directly
$FRACTOGENESIS_HOME/.internal/artifact-config.sh  # sourced by backup scripts, never run directly
```

`$FRACTOGENESIS_HOME` above is reference notation showing where these files live, not a literal path you can use from a fresh terminal -- direnv only populates it once you've already `cd`ed into the repo. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], you `cd` into the repository root once at the start of a session, which is what populates `$FRACTOGENESIS_HOME`.

Both self-locate relative to their own position in the repo — nothing needs to be told where the repo is; there's no `REIMAGE_ROOT`-equivalent variable to keep in sync. For what that does and doesn't mean in practice, and how `FRACTOGENESIS_PARENT`/`FRACTOGENESIS_HOME`/`$HOME` relate to each other, see [[#Repo Path Variables and Self-Locating Scripts|Repo Path Variables and Self-Locating Scripts]] in the supplemental reference at the end of this guide -- not required reading to continue, only if you want the detail.

This guide references three directory locations in total, but only two of them are "storage roles" in the sense of holding files this workflow *generates*. The third -- this repo checkout, i.e. `FRACTOGENESIS_HOME` -- holds tracked source instead (scripts, docs, config templates), and is listed below only so the boundary is explicit, not because anything gets generated into it:

| Path name                | Location                     | Role                                                                                                                  | What belongs there                                                                                                                                                                                                 |
| ------------------------ | ---------------------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `REIMAGE_WORKSPACE_ROOT` | Local workspace              | Local-only staging and reusable config area outside this repo.                                                | IT reimage confirmation working copy, reusable artifact-config workspace copies, staged chart/history artifacts, and other local files that may be reused across backup reruns before copying to the external drive. |
| `REIMAGE_ARTIFACT_ROOT`            | External artifact root | Generated artifacts, logs, inventories, encrypted bundles, manual notes, validation reports, and post-image evidence. | The active reimage artifact tree under the selected external data volume.                                                                                                                                    |
| *(no variable -- self-locating)* | This repo checkout (`FRACTOGENESIS_HOME`) | Tracked source of truth: entrypoint scripts, sourced-only helpers, this guide, and config templates. Not a destination for generated artifacts. | `bin/`, `.internal/`, `reimage.env.example`, this guide's own `.md` files. `reimage.env` also lives here, but its *contents* are machine-local, not tracked. |

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
| 4 | Check for an existing `reimage.env` | Catch a leftover file (and any stale shell exports it already loaded) from a previous reimage effort on this Mac, *before* the next step's auto-detect logic can silently reuse a stale value instead of recomputing it. |
| 5 | Decide the artifact root path | Compute the resolved `$REIMAGE_ARTIFACT_ROOT` path, still as a plain export. |
| 6 | Create `reimage.env` | Write the local source of truth, seeded with the already-confirmed volume and artifact-root values -- resolved correctly from the start, no follow-up edit needed. |
| 7 | Set up direnv | Make `reimage.env` load automatically on `cd` into the repo from here on. |
| 8 | Load and print the config | Confirm the environment resolves as expected. |
| 9 | Define Git repository roots | Save the parent folders that later Git backup steps will search. |
| 10 | Create the artifact root | Actually create the directory on the external volume, now that `reimage.env` has the resolved path. |
| 11 | Load and confirm the environment | Deeper validation that the created root and full config are consistent. |
| 12 | Confirm `artifact-config.sh` is aligned | Verify backup scripts can read the same environment and expected top-level folders -- must happen before step 13, since it determines what that step creates. |
| 13 | Create the standard workflow layout | Seed the directories used across the reimage workflow, using the folder list `artifact-config.sh` just resolved. |
| 14 | Verify the prepared root | Confirm the prepared top-level structure is ready for backup and evidence scripts. |

Troubleshooting is intentionally at the end. Specific steps link to the relevant troubleshooting section only when something fails. Background material that isn't needed to execute a step -- but that a step may still link out to for deeper context -- lives in Supplemental Reference, also at the end, just before Troubleshooting.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Repo, Workspace, and External Drive Boundary

Keep these boundaries clear before creating directories.

#### This repo

Stores active source files: runbooks, `bin/` entrypoint scripts, `.internal/` helper scripts and config templates, and reference/template docs — all tracked in Git. Self-located by the scripts that need it; no path to it needs to be saved in `reimage.env`.

#### Local workspace

The local workspace is outside this repo and outside the external artifact root. Use it for staging and reusable local config that may survive more than one backup attempt.

Pick a path and export it as `REIMAGE_WORKSPACE_ROOT`; there is no default, and nothing guesses one for you. Any location outside this repo and outside the external artifact root works — a directory directly under `$HOME` keeps it clear of whatever the backup targets already sweep:

```text
$HOME/<workspace-dir>/
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

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Artifact Root Naming Convention

This is background/reference material -- read it before running anything so the name you pick makes sense the first time, rather than getting renamed later. It does not itself involve running any commands.

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

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### About artifact-config.sh

`artifact-config.sh` is the single source of truth for local-file backup targets, excludes, descriptions, and expected top-level folders used by the backup scripts.

The arrays and flags are now stored in reusable shell config fragments instead of being hard-coded inline in the loader. Shell fragments were chosen instead of YAML so the existing bash scripts can source them directly while keeping the annotation comments intact.

It is sourced by scripts such as:

```text
bin/backup-home.sh
bin/report-size-audit.sh
bin/capture-toolkit-snapshot.sh
bin/create-secrets-dmg.sh
```

Do not run it directly.

Important behavior:

| Behavior | Meaning |
|---|---|
| It self-locates `REPO_ROOT` from its own script path (parent of `.internal/`). | Sourcing scripts must reference it by its actual path relative to the repo root, e.g. `bin/backup-home-files-backup.sh` — there's no `REIMAGE_ROOT` variable to fall back on. |
| It loads `reimage.env` if present. | Your local `REIMAGE_ARTIFACT_ROOT` plus optional `OFFICE_WATCH`, `ONEDRIVE_FOLDER_NAME`, `ONEDRIVE_ROOT`, and related paths are shared with scripts. |
| It defines `EXTERNAL_APPLE_BACKUPS_VOLUME`. | Time Machine scripts use this as the backup destination mount path instead of assuming the destination volume is named `AppleBackups`. |
| It exits if `REIMAGE_ARTIFACT_ROOT` is empty. | Create and source `reimage.env` before running scripts that depend on the backup root. |
| It prefers workspace-backed config fragments when they exist. | `REIMAGE_WORKSPACE_ROOT/artifact-config/` becomes the reusable local copy for reruns; otherwise the loader falls back to `.internal/templates/artifact-config/`. |
| It defines `EXTERNAL_TARGETS`. | These become subfolders under `$REIMAGE_ARTIFACT_ROOT/home-files-backup/`. |
| It defines OneDrive handling. | `ONEDRIVE_ROOT` should be a full path, or `ONEDRIVE_FOLDER_NAME` can be used to resolve a folder under `~/Library/CloudStorage/`. Do not use a bare OneDrive folder name relative to the current directory. |
| It defines `SECRETS_TARGETS`. | These become file or directory entries under `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/`. Use `certs/` for certificate/keystore material and `certs/java-security/` for Java `jssecacerts`. |
| It defines `EXTERNAL_EXCLUDES` and `ONEDRIVE_EXTRA_EXCLUDES`. | Add backup exclusions in config, not in each script. |
| It defines `EXPECTED_ARTIFACT_FOLDERS`. | Keep this aligned with the stable top-level folders created by this guide. Optional evidence roots are created later by capture guides. |

Current expected top-level folders from `artifact-config.sh`:

```text
app-settings-backup
gitignore-superset
home-files-backup
loose-secrets-reports
managed-inventory
public-certs
reimage-confirmation
reimage-prep-checks
reimaged-system
repo-audit-reports
secrets-encrypted
size-audit-reports
staged-ignored-files
system-inventory
time-machine
toolkit-snapshot
```

These are the stable top-level folders the Create the Standard Directory Layout step produces. Child folders for setup notes, secrets staging, optional evidence captures, and other workflow-owned artifacts are created later by their owning runbooks or scripts.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Sequential Steps

This section is the ordered execution path for preparing the artifact root: confirm the repo checkout, choose and verify the external volume, set up or resume `reimage.env`, load it into the shell (direnv or manual `source`), create the artifact root and its standard folder layout, drop in the filled IT reimage confirmation, then verify the result. Each step assumes the ones before it are already done.

---

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

Route based on whether the `find` output listed those files:

If they're present:

→ [[#Already Cloned|Already Cloned]]

If `.internal/artifact-config.sh` and the other expected files are missing:

→ [[#Repo Not Cloned|Repo Not Cloned]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

#### Already Cloned

If `pwd`/`find` above already showed the expected files, you're done with this step -- just make sure you're sitting at the repo root, not a subdirectory:

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
pwd
```

[[#Choose the External Data Volume|⮕ Continue to Choose the External Data Volume]]

---

#### Repo Not Cloned

Two paths, depending on context:

**On your normal dev machine** (Git/SSH already working): clone normally into wherever you organize documentation or source repos. `FRACTOGENESIS_PARENT` here is only the *parent* folder you're cloning into -- it is a plain shell variable used for this clone command, not something written to `reimage.env`.

```bash
FRACTOGENESIS_PARENT="/path/to/local/repo-parent"

mkdir -p "$FRACTOGENESIS_PARENT"
cd "$FRACTOGENESIS_PARENT"

git clone git@github.com:<your-github-account>/fractogenesis-toolkit.git
```

`cd` into the checkout itself -- this directory is what the rest of the guide calls `FRACTOGENESIS_HOME`:

```bash
cd "$FRACTOGENESIS_PARENT/fractogenesis-toolkit"
pwd
```

**On a freshly reimaged Mac** (no Git/SSH yet — this is the actual scenario Phase 8 onward depends on): use the bootstrap mechanism instead of `git clone` — no auth needed, no Xcode Command Line Tools popup:

```bash
export TOOLKIT_GITHUB_ACCOUNT=<your-github-account>
curl -fL -o /tmp/bootstrap.sh \
  "https://raw.githubusercontent.com/$TOOLKIT_GITHUB_ACCOUNT/fractogenesis-toolkit/main/bootstrap.sh"
bash /tmp/bootstrap.sh
```

Download and run as two steps, not `curl … | bash`. Piped, `-f -s` makes a 404 or a captive-portal redirect print nothing; `bash` reads an empty stdin and the pipeline exits **0**, so the install silently does not happen and the only symptom is that `cd "$HOME/fractogenesis-toolkit"` below fails.

This installs to `$HOME/fractogenesis-toolkit` by default -- in other words, on a fresh reimage, `FRACTOGENESIS_PARENT` is implicitly `$HOME` and `FRACTOGENESIS_HOME` becomes `$HOME/fractogenesis-toolkit`, without you having to set `FRACTOGENESIS_PARENT` yourself. `cd` into it the same way:

```bash
cd "$HOME/fractogenesis-toolkit"
pwd
```

If there's no network yet, use the prepared jump drive fallback instead — see the repo README or Phase 8 of `reimaging-guide.md` for the exact command.

The repo is public, so no access request is needed either way.

[[#Choose the External Data Volume|⮕ Continue to Choose the External Data Volume]]

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

This is the one place in the guide where `EXTERNAL_DATA_VOLUME` and `EXTERNAL_APPLE_BACKUPS_VOLUME` get created -- as plain shell exports, not written to a file, since `reimage.env` doesn't exist yet.

**Run this in the same terminal session you've been in since cloning the repo**, and keep that session open through the next two steps, which reuse these same two exports rather than re-creating them:

```bash
export EXTERNAL_DATA_VOLUME="/Volumes/<external-data-volume-name>"
export EXTERNAL_APPLE_BACKUPS_VOLUME="/Volumes/<time-machine-volume-name>"
```

Do not use the Time Machine volume as the manual artifact volume. In the example above, the artifact root should live under `/Volumes/Data`, not `/Volumes/AppleBackups`.

These values get written into `reimage.env` for real once it's created a few steps from now  -- no need to edit any file yet.

> [!bug] Troubleshooting
> If the expected external data volume is missing, see [[#External Data Volume Not Visible|External Data Volume Not Visible]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Confirm External Data Volume Readiness

Confirm the selected external parent volume is mounted, is not read-only, and allows the current macOS user to write at the parent path. This step checks the external drive itself before the artifact root exists.

This step reuses the `EXTERNAL_DATA_VOLUME`/`EXTERNAL_APPLE_BACKUPS_VOLUME` exported in the previous step -- confirm they're still set before continuing:

```bash
printf 'EXTERNAL_DATA_VOLUME=%s\n' "${EXTERNAL_DATA_VOLUME:-}"
printf 'EXTERNAL_APPLE_BACKUPS_VOLUME=%s\n' "${EXTERNAL_APPLE_BACKUPS_VOLUME:-}"
```

If either printed blank -- for example because you opened a new terminal since the last step -- re-export them now; do not source `reimage.env` here, it doesn't exist yet):

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

> [!bug] Troubleshooting
> If the write test fails with `Permission denied` while `Volume Read-Only: No`, see [[#Can't Write to the Volume|Can't Write to the Volume]].
>
> If it fails with `Operation not permitted`, see [[#Terminal Privacy Block|Terminal Privacy Block]].
>
> If the volume is mounted read-only, see [[#External Data Volume Is Read Only|External Data Volume Is Read Only]].

[[#Table of Contents|⬆ Back to Table of Contents]]


---

### Create Local Reimage Environment Profile

Create `reimage.env`, the local, machine-specific config file the rest of this guide reads for `REIMAGE_ARTIFACT_ROOT`, `REIMAGE_WORKSPACE_ROOT`, and related paths.

Before running anything below, confirm these are still exported in this terminal session:

- `EXTERNAL_DATA_VOLUME`
- `EXTERNAL_APPLE_BACKUPS_VOLUME` (if used)

And confirm you're still sitting in the repo root (`FRACTOGENESIS_HOME`):

```bash
pwd
```

This should print the repo root -- the folder containing `reimage.env.example`.

Most likely `reimage.env` doesn't exist yet. But if you've previously worked through this guide -- from an earlier reimage effort, or one you started and abandoned partway -- it may already be sitting here from that attempt.

It matters which case you're in. If an old file is reused without being checked first, every later backup, evidence-capture, and restore script inherits whatever `REIMAGE_ARTIFACT_ROOT` it happens to contain -- resolved and correct for this effort, or silently stale from a previous one -- with no error either way to warn you which. That's the whole reason the check below comes first.

#### Check for an Existing Profile First

Run the diagnostic -- it only reads, it never writes or deletes anything:

```bash
bin/check-reimage-env.sh
```

If it prints:

```text
No existing reimage.env.
```

→ [[#Required and Default Values|Required and Default Values]] — the common case; nothing to reconcile, continue below.

If instead it prints values under a `reimage.env already exists:` header, for example:

```text
reimage.env already exists:

export EXTERNAL_DATA_VOLUME=/Volumes/Data
export ASSET_OR_HOST=example-mac-01
export REIMAGE_START_DATE=20260719
export REIMAGE_ARTIFACT_ROOT=/Volumes/Data/reimage-example-mac-01-20260719-open

Ground truth to compare against:
Today:         20260719
This Mac:      example-mac-01
Chosen volume: /Volumes/Data
```

→ compare them against the ground truth, then go to [[#Handle Existing Reimage Environment|Handle Existing Reimage Environment]] to resume, archive, or repair it before continuing here.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

#### Required and Default Values

Before creating `reimage.env`, confirm you have the required environment variables, and decide whether to accept the computed defaults below or override them.

| Variable | Required? | Source |
|---|---|---|
| `EXTERNAL_DATA_VOLUME` | Required | [[#Choose the External Data Volume\|Choose the External Data Volume]] |
| `REIMAGE_WORKSPACE_ROOT` | Required | [[#Local workspace\|Local workspace]] |
| `EXTERNAL_APPLE_BACKUPS_VOLUME` | Optional | Same step, if a Time Machine destination is in use |
| `ONEDRIVE_FOLDER_NAME` | Required *for OneDrive* | The sync folder's name, e.g. `OneDrive-AcmeGroup`. Leave unset to skip OneDrive entirely |

Export them before running the script:

```bash
export EXTERNAL_DATA_VOLUME="/Volumes/<data-volume>"
export REIMAGE_WORKSPACE_ROOT="$HOME/<workspace-dir>"
export EXTERNAL_APPLE_BACKUPS_VOLUME="/Volumes/<time-machine-volume>"   # only if one is in use
```

Then confirm each landed, because an unset value here is the failure that costs the most later:

```bash
printf '%-32s %s\n' \
  EXTERNAL_DATA_VOLUME "${EXTERNAL_DATA_VOLUME:-<unset>}" \
  REIMAGE_WORKSPACE_ROOT "${REIMAGE_WORKSPACE_ROOT:-<unset>}" \
  EXTERNAL_APPLE_BACKUPS_VOLUME "${EXTERNAL_APPLE_BACKUPS_VOLUME:-<unset>}"
```

> [!warning] Pitfall
> `REIMAGE_WORKSPACE_ROOT` is required because the workspace holds the artifact-config and staged-certs fragments every later script reads. Point it at a directory that does not exist and those loaders fall back to the repository's generic templates — the run continues, against placeholder targets. `setup-reimage-env.sh` and `prepare-artifact-root.py` both refuse to run without it, and `artifact-config.sh` warns when the value is set but the directory is missing.

If you intend to use the optional OneDrive secondary copy, also export the folder name — and its parent directory when the sync folder is not a macOS file-provider mount under `~/Library/CloudStorage`:

```bash
export ONEDRIVE_FOLDER_NAME="OneDrive-<OrgName>"
export ONEDRIVE_PARENT_DIR="/path/to/<sync-parent>"   # only when overriding the default
```

`bin/setup-reimage-env.sh` computes the rest for you -- you rarely need to type anything, but each can be overridden by exporting your own value beforehand:

| Variable | Default the script computes | Override when... |
|---|---|---|
| `ASSET_OR_HOST` | The Mac's short hostname | You want a shorter/cleaner tag than the raw hostname, or need to anonymize it in shared notes. |
| `REIMAGE_START_DATE` | Today's date (`YYYYMMDD`) | The reimage effort actually started on an earlier date than when you're running this command. |
| `REIMAGE_ARTIFACT_ROOT` * | `$EXTERNAL_DATA_VOLUME/reimage-$ASSET_OR_HOST-$REIMAGE_START_DATE-open` | Not set directly -- always built from the two values above. |
| `ONEDRIVE_FOLDER_NAME` | Unset -- OneDrive is skipped | You want the optional OneDrive secondary copy. Export it to the CloudStorage OneDrive folder name (for example `OneDrive-AcmeGroup`); `setup-reimage-env.sh` then resolves `ONEDRIVE_ROOT` and pre-creates the per-reimage OneDrive destination. |
| `ONEDRIVE_PARENT_DIR` | `~/Library/CloudStorage` | The OneDrive folder is not a macOS file-provider mount -- a legacy sync client, a relocated folder, or a non-standard setup. `ONEDRIVE_ROOT` is always built as `$ONEDRIVE_PARENT_DIR/$ONEDRIVE_FOLDER_NAME`, so overriding the parent is how you point at a folder outside CloudStorage. |

This interpolation follows naming convention previously mentioned.

To override a default, export before running the script:

```bash
export ASSET_OR_HOST="my-custom-tag"
```

[[#Optional Values (Set in Their Own Phase)|⮕ Continue to Optional Values (Set in Their Own Phase)]]

---

#### Handle Existing Reimage Environment

This only matters if an earlier, unfinished reimage attempt already left a file behind -- most runs never reach this section. The usual signs:

```text
bin/setup-reimage-env.sh refuses immediately with a message that reimage.env already exists, and you don't remember creating one
Backups or evidence captures appear to be landing under a REIMAGE_ARTIFACT_ROOT dated days/weeks ago, or naming a Mac you don't recognize
REIMAGE_ARTIFACT_ROOT, once loaded, points at an external volume that isn't the one currently mounted
```

It almost always means `reimage.env` was created during an earlier reimage effort on this Mac and never cleaned up. Neither direnv nor a manual `source` distinguishes an old file from a fresh one -- both load whatever is on disk, silently.

This must be resolved before running `bin/setup-reimage-env.sh`, since that script refuses to run at all once `reimage.env` exists. A file left in place unresolved is what every later backup, evidence-capture, and restore script will resolve `REIMAGE_ARTIFACT_ROOT` from -- resolved or stale, with no error either way.

If the file is stale rather than resumable, you'll either archive it or delete it. **Archiving** (renaming it aside) keeps the old values readable in case you still need them; **deleting** is fine when you're certain nothing about the old file matters, such as a leftover from a different Mac with nothing generated against its root. When unsure, archive -- it's the reversible choice. One thing to capture either way: if backup or evidence scripts already ran before you caught this, they wrote into the *old* `REIMAGE_ARTIFACT_ROOT`. Note that path before you archive or delete the file, so you can find and deal with what was written there instead of losing track of it once the file is gone.

Route based on how the values `bin/check-reimage-env.sh` printed compare to the ground truth it printed alongside them:

If `ASSET_OR_HOST` matches this Mac's hostname and `EXTERNAL_DATA_VOLUME` matches the volume you chose:

→ [[#Resuming|Resuming]] (`REIMAGE_START_DATE` need not be today — a reimage often spans several days).

If `ASSET_OR_HOST` or `EXTERNAL_DATA_VOLUME` doesn't match:

→ [[#Archiving|Archiving]] — the file is from a different Mac or drive, the most reliable signs it's stale.

If the `reimage.env already exists:` header printed with no `export` lines after it:

→ [[#Empty / Unrecognized|Empty / Unrecognized]]

[[#Check for an Existing Profile First|⬆ Back to Check for an Existing Profile First]]

---

##### Resuming

`ASSET_OR_HOST` matches this Mac's hostname (or you know you set a deliberate custom tag) and `EXTERNAL_DATA_VOLUME` matches the volume you just chose. That pair is what identifies this file as the effort you're on right now. Do not gate the decision on `REIMAGE_START_DATE`: a reimage commonly runs across multiple days, so a start date earlier than today is normal and does not make the file stale -- the date only records when this effort began.

[[#Set Up direnv|⮕ Continue to Set Up direnv]]

---

##### Archiving

Archive the file when its identity no longer matches this effort: `ASSET_OR_HOST` doesn't match this Mac's hostname (and you don't recall setting a deliberate custom tag), or `EXTERNAL_DATA_VOLUME` doesn't match the volume you just chose. A hostname mismatch is the strongest signal -- it usually means the file was carried over from a different or older Mac. An earlier `REIMAGE_START_DATE` is *not*, on its own, a reason to archive: a multi-day reimage legitimately keeps its original start date, so treat an old date as a cue to confirm you're still on that same effort, not as proof it's stale. Left in place, a mismatched file would silently point every later step at the wrong artifact root, with no error to warn you. Archive it -- don't edit it in place or delete it outright, the old values may still be needed for reference:

```bash
mv reimage.env "reimage.env.stale-$(date +%Y%m%d-%H%M%S)"
```

Confirm the archived file is actually ignored by Git, not just untracked-but-visible -- a `.gitignore` from an earlier pass through this guide may only have the bare `reimage.env` line and not yet a `reimage.env.stale-*` entry. Add `reimage.env.stale-*` to `.gitignore` if it isn't there already:

```bash
git status --short | grep 'reimage.env.stale' && echo "WARNING: archived file is untracked and not ignored -- update .gitignore before committing anything" || echo "OK: archived file is ignored or already clean"
```

**Moving the file is not enough on its own.** If this repo checkout was previously `cd`ed into with direnv active, the old file's values were already loaded into shell variables, not just left sitting in the file -- and a moved/renamed file doesn't retroactively unset variables already exported into the current shell. What happens next depends on how those values got loaded:

- **direnv is active**: it re-evaluates `.envrc` on every prompt, so the very next command you run should trigger a `direnv: export ...` line unloading the old values -- watch for that, don't assume it happened.
- **direnv is not active yet**, or the values reached this shell via a manual `source reimage.env`: nothing auto-unloads them. They remain exported until you clear them or open a new terminal.

Clear those old values and confirm the shell is actually clean before continuing. The block below unsets every variable the old file could have exported, then prints `REIMAGE_ARTIFACT_ROOT` so you can confirm it's gone:

```bash
unset REIMAGE_ARTIFACT_ROOT ASSET_OR_HOST REIMAGE_START_DATE REIMAGE_WORKSPACE_ROOT

printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "${REIMAGE_ARTIFACT_ROOT:-<unset, good>}"
```

(Deliberately not unsetting `EXTERNAL_DATA_VOLUME`/`EXTERNAL_APPLE_BACKUPS_VOLUME` here -- those describe the drive you're using for this effort, not the old one, so they're still correct; only values that could have come from the *old* file need clearing.)

If that still prints an old path instead of `<unset, good>`, something is re-exporting it (a leftover `.envrc` in a parent directory, a sourced profile script, etc.) -- track that down before continuing.

[[#Required and Default Values|⮕ Continue to Required and Default Values]]

---

#### Optional Values (Set in Their Own Phase)

These optional variables have no computed default and are **not** set here. Following the same principle as folder creation -- each is set by the runbook that first uses it -- they stay blank in `reimage.env` until that phase. They are listed here only so you know they exist and where they get set; the full catalog with comments lives in `reimage.env.example`. (If you export one before creating `reimage.env`, `bin/setup-reimage-env.sh` captures it — but you don't need to; the phase that uses it will set it.)

| Variable | Set in |
|---|---|
| `GIT_WORK_REPO_ROOT`, `GIT_PERSONAL_REPO_ROOT` | [[backup-repos\|backup-repos.md]] (Phase 2A) |
| `PERFORMANCE_HISTORY_SOURCE` | [[capture-performance-audit\|capture-performance-audit.md]] (Phase 4C) |
| `OFFICE_WATCH` | [[capture-office-stability\|capture-office-stability.md]] (Phase 4D) |
| Git identity / SSH / host / branch values | [[restore-git\|restore-git.md]] (Phase 11A) |

`JUMP_DRIVE_VOLUME` is reference-only -- the no-network bootstrap jump drive path, not read by `prepare-artifact-root.py` (see the Phase 6A jump-drive fallback).

#### Files and .gitignore

This file is local-only and should not be committed. Neither should any archived copy of it.

| File | Commit to repo? | Purpose |
|---|---:|---|
| `reimage.env.example` | Yes | Template showing required variables and naming conventions. |
| `reimage.env` | No | Local machine-specific config used by your terminal and scripts. |
| `reimage.env.stale-*` | No | Archived copies created -- same machine-specific/sensitive content as `reimage.env` itself, just renamed, not sanitized. |

Recommended `.gitignore` entry -- list both patterns explicitly rather than a single glob like `reimage.env*`, which would also match (and needlessly warn about) the intentionally-tracked `reimage.env.example`:

```gitignore
# Local Mac reimage workflow config
reimage.env
# Archived/stale copies from Handle Existing Reimage Environment
reimage.env.stale-*
```

#### Script Execution

Run `bin/setup-reimage-env.sh` to create the file. It does the following, in order:

1. Confirms `reimage.env.example` exists in the current directory (i.e., you're actually in the repo).
2. Confirms `reimage.env` doesn't already exist -- refuses otherwise, and points you at `bin/check-reimage-env.sh` rather than overwriting anything.
3. Confirms `EXTERNAL_DATA_VOLUME` and `REIMAGE_WORKSPACE_ROOT` are exported -- refuses to run otherwise, rather than silently writing a blank/placeholder value you'd have to fix later. `EXTERNAL_APPLE_BACKUPS_VOLUME` stays optional and is written through as-is, blank when no Time Machine destination is in use.
4. Copies the template to `reimage.env`.
5. Runs `prepare-artifact-root.py init-reimage-env`, which resolves `ASSET_OR_HOST` and `REIMAGE_START_DATE` (your exported override, or its own default if unset), builds `REIMAGE_ARTIFACT_ROOT` from them, and writes all three into `reimage.env` in the same step -- along with the remaining resolved starter values (default workspace paths, confirmed volume paths). When `ONEDRIVE_FOLDER_NAME` is exported, it also resolves `ONEDRIVE_ROOT` as `$ONEDRIVE_PARENT_DIR/$ONEDRIVE_FOLDER_NAME` -- using `~/Library/CloudStorage` unless you exported `ONEDRIVE_PARENT_DIR` -- and pre-creates the per-reimage OneDrive destination, but only when that parent already exists (OneDrive signed in); otherwise it notes that the backup run will create it.
6. Locks the file down to `chmod 600`.
7. Prints the result for review.

Run it from inside the repo:

```bash
bin/setup-reimage-env.sh
```

#### Review the Result

Review these values -- they should already be correct, since they came from confirmed exports and computed defaults, not placeholders:

| Variable                     | Review rule                                                                                                                                                                                                                                                        |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `REIMAGE_WORKSPACE_ROOT`     | Should match the path you exported, and must be an existing directory outside this repo and outside the external root. It is where the artifact-config and staged-certs fragments live, so a wrong value silently degrades every later script to the committed templates. |
| `EXTERNAL_DATA_VOLUME`         | Should already match the volume confirmed a few steps ago.                                                                                                                                                                                      |
| `EXTERNAL_APPLE_BACKUPS_VOLUME`    | Should already match the Time Machine destination volume, if one was set.                                                                                                 |
| `ASSET_OR_HOST`              | Resolved once by `bin/setup-reimage-env.sh` and reused for both this field and `REIMAGE_ARTIFACT_ROOT` -- no separate detection to drift out of sync with. |
| `REIMAGE_START_DATE`         | Resolved once, the same way. |
| `REIMAGE_ARTIFACT_ROOT`                | Should already be the resolved absolute path -- not blank.                                                                                                                             |
| `ONEDRIVE_FOLDER_NAME`       | Optional. Set it by exporting `ONEDRIVE_FOLDER_NAME` before running `setup-reimage-env.sh`; blank means OneDrive is skipped.                                                                                                                     |
| `ONEDRIVE_PARENT_DIR`        | Optional. The directory the sync folder lives under; blank means the `$HOME/Library/CloudStorage` default was used. Override only when the OneDrive folder is not a macOS file-provider mount. |
| `ONEDRIVE_ROOT`              | Auto-resolved to `$ONEDRIVE_PARENT_DIR/$ONEDRIVE_FOLDER_NAME` when the folder name is set; blank otherwise. Stored as a resolved absolute path, never a literal `$HOME/...` string. |
| `ONEDRIVE_DEST_SUBDIR`       | Already defaulted to the artifact root folder name by `setup-reimage-env.sh`.                                                                                            |

There's no environment variable to set for the repository's own path. `prepare-artifact-root.py` self-locates from its own position in the repo -- wherever this checkout lives, the script finds `bin/` and `.internal/` relative to itself, so nothing needs to be told where the repo is.  Stay in `FRACTOGENESIS_HOME` for this and every remaining step.

`reimage.env` should contain resolved values only:

- Never a helper-variable reference.
- Never a literal `$HOME/...`-style path.

> [!bug] Troubleshooting
> If a script reports an unbound variable while sourcing `reimage.env`, or a verification step prints a path such as `$HOME/Desktop/...`, see [[#Literal Paths in reimage.env|Literal Paths in reimage.env]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Set Up direnv

This makes `reimage.env` load automatically whenever you `cd` into this repo, and unload automatically the moment you `cd` out — no manual `source` needed each terminal session.

**`.envrc` itself can't go stale the way `reimage.env` can.** It's a tracked, committed file in this repo -- the same for every reimage effort on every Mac, not machine- or effort-specific -- so there's no old hostname or date baked into it to worry about.

Check whether this looks like the first time on this Mac, or a repeat from a previous reimage effort:

```bash
if command -v direnv >/dev/null 2>&1 && grep -qxF 'eval "$(direnv hook zsh)"' ~/.zshrc 2>/dev/null; then
  echo "direnv already appears installed and hooked into this Mac -- likely set up during a previous reimage effort."
else
  echo "direnv is not fully set up yet on this Mac -- this looks like the first time."
fi
```

Route based on what printed:

If it prints:

```text
direnv is not fully set up yet on this Mac -- this looks like the first time.
```

→ [[#First-Time Setup|First-Time Setup]]

If it prints:

```text
direnv already appears installed and hooked into this Mac -- likely set up during a previous reimage effort.
```

→ [[#Already Set Up|Already Set Up]]

Then confirm your shell has `reimage.env` loaded correctly:

- [[#Confirm reimage.env Is Loaded|Confirm reimage.env Is Loaded]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

#### First-Time Setup

```bash
brew install direnv
```

Add the hook to `.zshrc` once -- this check keeps the command safe to rerun on a later reimage effort without appending a duplicate line each time:

```bash
grep -qxF 'eval "$(direnv hook zsh)"' ~/.zshrc || echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
```

(Must run before any tool like SDKMAN that requires being the literal last line — direnv doesn't need to be last, just present.)

Open a new terminal so the hook takes effect. `.envrc` is already committed in this repo's root -- no need to create it yourself:

```bash
cat .envrc
```

Expect to see:

```bash
export FRACTOGENESIS_HOME="$(pwd)"

if [[ -f "$(pwd)/reimage.env" ]]; then
  dotenv reimage.env
fi

PATH_add bin
```

direnv refuses to load a new `.envrc` until you explicitly approve it — a safety gate so a repo can't silently run code on you just by `cd`ing in:

```bash
direnv allow
```

Confirm it worked:

```bash
printf '%-32s %s\n' \
  EXTERNAL_DATA_VOLUME "${EXTERNAL_DATA_VOLUME:-<unset>}" \
  REIMAGE_WORKSPACE_ROOT "${REIMAGE_WORKSPACE_ROOT:-<unset>}" \
  EXTERNAL_APPLE_BACKUPS_VOLUME "${EXTERNAL_APPLE_BACKUPS_VOLUME:-<unset>}"
```

Both should print resolved values with no further action. `cd` out of the repo and both should be unset; `cd` back in and both should reappear — that round trip is the actual proof direnv is doing its job, not just that the file exists.

The `if [[ -f reimage.env ]]; then dotenv reimage.env; fi` line in `.envrc` is why a stale `reimage.env` matters even though `.envrc` itself doesn't go stale: direnv will happily `dotenv` whatever `reimage.env` currently exists, old or new, with no distinction. 

[[#Set Up direnv|⬆ Back to Set Up direnv]]

---

#### Already Set Up

direnv and the shell hook are already in place, so most of first-time setup is unnecessary here. Two things from a previous pass through this guide *can* still bite you, though -- both idempotency-shaped rather than staleness-shaped:

**Local, uncommitted edits to `.envrc` itself** -- for example, someone adding extra exports directly into it instead of into `reimage.env`. `.envrc` is tracked in Git, so check for drift against the tracked version rather than trusting `cat` alone:

```bash
git status --short .envrc
git diff .envrc
```

Both should print nothing. If either shows a change, decide deliberately whether to keep it (and understand what it does before relying on it) or reset it to the tracked version (`git checkout -- .envrc`) -- don't leave it drifted without knowing why.

**Re-approving `.envrc`.** If this exact `.envrc` content was already approved during an earlier reimage effort on this Mac, running this again is a harmless no-op -- direnv tracks approval by content hash, not by session, so you won't be re-prompted and that's expected, not a sign something's wrong:

```bash
direnv allow
```

Confirm it worked:

```bash
printf '%-32s %s\n' \
  EXTERNAL_DATA_VOLUME "${EXTERNAL_DATA_VOLUME:-<unset>}" \
  REIMAGE_WORKSPACE_ROOT "${REIMAGE_WORKSPACE_ROOT:-<unset>}" \
  EXTERNAL_APPLE_BACKUPS_VOLUME "${EXTERNAL_APPLE_BACKUPS_VOLUME:-<unset>}"
```

Both should print resolved values with no further action. `cd` out of the repo and both should be unset; `cd` back in and both should reappear — that round trip is the actual proof direnv is doing its job, not just that the file exists.

The `if [[ -f reimage.env ]]; then dotenv reimage.env; fi` line in `.envrc` is why a stale `reimage.env` matters even though `.envrc` itself doesn't go stale: direnv will happily `dotenv` whatever `reimage.env` currently exists, old or new, with no distinction. 

[[#Set Up direnv|⬆ Back to Set Up direnv]]

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

A resolved, non-blank `REIMAGE_ARTIFACT_ROOT` here only proves *a* value loaded -- not that it's *this* effort's value. If you arrived here after a break of days or weeks, double-check the printed path actually matches the effort you're working on today.

[[#Create the Artifact Root|⮕ Continue to Create the Artifact Root]]

---

### Create the Artifact Root

By this point `reimage.env` already has `REIMAGE_ARTIFACT_ROOT` resolved correctly -- it was written in at creation time, not left blank. This step runs the entrypoint that actually creates the directory on the external volume.

Run the Phase 1 entrypoint from the repo root:

```bash
python3 bin/prepare-artifact-root.py \
  create-artifact-root \
  --env-file reimage.env
```

On success it prints:

```text
OK: REIMAGE_ARTIFACT_ROOT is under EXTERNAL_DATA_VOLUME
OK: artifact root exists
```

Route based on what it actually prints:

> [!check] Both `OK:` lines printed → [[#Load and Confirm the Environment|Load and Confirm the Environment]]
> ```text
> OK: REIMAGE_ARTIFACT_ROOT is under EXTERNAL_DATA_VOLUME
> OK: artifact root exists
> ```

> [!fail] `Permission denied` → [[#Confirm External Data Volume Readiness|⬆ Back to Confirm External Data Volume Readiness]]
> ```text
> Permission denied while creating REIMAGE_ARTIFACT_ROOT.
> ```

> [!fail] `Operation not permitted` → [[#Confirm External Data Volume Readiness|⬆ Back to Confirm External Data Volume Readiness]]
> ```text
> Operation not permitted while creating REIMAGE_ARTIFACT_ROOT.
> ```

> [!fail] Literal variable text, or an empty `REIMAGE_ARTIFACT_ROOT` → [[#Literal Paths in reimage.env|Literal Paths in reimage.env]]
> ```text
> REIMAGE_ARTIFACT_ROOT contains literal variable text instead of a resolved path.
> ```

> [!warning] You ran a manual `sudo mkdir` repair and suspect it landed under the repo checkout → [[#Folder Under the Repo|Folder Under the Repo]]

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

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Set Up the artifact-config Fragments

`artifact-config.sh` reads its backup targets, excludes, and expected folders from reusable shell config fragments. Set those fragments up before the local-file backup phases run.

Route based on whether you already have real config fragments:

- [[#Already Have Fragments|Already Have Fragments]] — from a previous setup or checkout.
- [[#Initialize From Scratch|Initialize From Scratch]] — start from this repo's placeholder templates.

Either way, before running local-file backup scripts, confirm the loader can still be parsed:

```bash
bash -n .internal/artifact-config.sh
```

> [!bug] Troubleshooting
> If a script reports that `REIMAGE_ARTIFACT_ROOT` is not set, see [[#REIMAGE_ARTIFACT_ROOT Is Empty in Scripts|REIMAGE_ARTIFACT_ROOT Is Empty in Scripts]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Already Have Fragments

If you already have real `*.conf.sh` fragments -- from a previous setup, copied out of a `fractogenesis-toolkit` checkout, or anywhere else -- **you don't need to copy them anywhere**. They belong at exactly one path, and it is under the workspace, never the artifact root:

```text
$REIMAGE_WORKSPACE_ROOT/artifact-config/
```

`artifact-config.sh` checks that path automatically every time it is sourced, ahead of the repo's committed templates. There is no manual copy step and no flag to set -- real files sitting at that exact path *are* the mechanism.

Confirm they are actually there. The loader requires all nine fragments and aborts if one is missing, so list them and count:

```bash
ls -l "$REIMAGE_WORKSPACE_ROOT/artifact-config/"*.conf.sh
```

```bash
find "$REIMAGE_WORKSPACE_ROOT/artifact-config" -maxdepth 1 -name '*.conf.sh' | wc -l
```

Nine is the expected count:

- `external-targets.conf.sh`
- `external-dotfiles.conf.sh`
- `secrets-targets.conf.sh`
- `secret-flags.conf.sh`
- `external-excludes.conf.sh`
- `onedrive-targets.conf.sh`
- `onedrive-extra-excludes.conf.sh`
- `skip-entries.conf.sh`
- `expected-artifact-folders.conf.sh`

Then read the two that must differ per machine. These hold this Mac's real paths; if they read like generic examples, they are the shipped templates rather than your own:

```bash
head -40 "$REIMAGE_WORKSPACE_ROOT/artifact-config/external-targets.conf.sh"
```

```bash
head -20 "$REIMAGE_WORKSPACE_ROOT/artifact-config/secrets-targets.conf.sh"
```

#### Confirm the Loader Resolved to the Workspace

Files existing is not the same as the loader using them. Ask the loader which directory it chose -- it exports the answer, so this is a direct reading rather than an inference from values:

```bash
bash -c 'source .internal/artifact-config.sh && echo "$ARTIFACT_CONFIG_SOURCE_DIR"'
```

That must print `$REIMAGE_WORKSPACE_ROOT/artifact-config`. A path ending in `.internal/templates/artifact-config` means the fragment precedence fell through to the committed templates -- either the workspace directory is missing, or `REIMAGE_WORKSPACE_ROOT` points somewhere that does not exist. The loader also prints a `WARNING:` on stderr in that case, naming the directory it looked for.

> [!warning] Pitfall
> The fallback does not fail. Scripts keep running against the repo's generic example targets, and most of those resolve to `not found, skipping` -- so a run against the wrong config looks like a thin but successful backup rather than an error. Check the source directory before the backup phases, not after.

As a second, value-level confirmation, print a fragment whose contents are unmistakably yours:

```bash
bash -c 'source .internal/artifact-config.sh && printf "%s\n" "${EXTERNAL_TARGETS[@]}"'
```

This should list your real backup targets -- actual paths and folder names specific to this Mac -- not the repo's placeholder example values.

Or run the aggregate validator, which resolves the same directory, reports it, and syntax-checks every fragment in one pass:

```bash
./bin/verify-artifact-config.sh
```

[[#Create the Standard Directory Layout|⮕ Continue to Create the Standard Directory Layout]]

---

### Initialize From Scratch

Use this path if you don't already have real config fragments.

```bash
python3 bin/prepare-artifact-root.py \
  init-artifact-config \
  --env-file reimage.env
```

This copies this repo's committed template fragments into `$REIMAGE_WORKSPACE_ROOT/artifact-config/` -- **but only for files that don't already exist there**. These aren't blank placeholders; each fragment ships with working, usable defaults (generic backup targets, standard excludes, the required `EXPECTED_ARTIFACT_FOLDERS` set) so the workflow runs correctly out of the box. Edit them afterward for values specific to this Mac -- real backup target paths, real excludes -- the same way you'd edit any local config. It refuses to overwrite anything you already have (confirmed by testing: running it against a workspace directory with real fragments in place reports `Copied: 0, Skipped existing: 9` and leaves every real file untouched). Safe to run either way, whether or not you already have real fragments.

Use the workspace copy going forward when you rerun backups later and most of the target/exclude config has not changed. You can adjust only the files that actually changed instead of rebuilding the full artifact-config setup from scratch.

[[#Create the Standard Directory Layout|⮕ Continue to Create the Standard Directory Layout]]

---

### Create the Standard Directory Layout

Creates only the stable top-level generated-artifact directories owned by this preparation guide. Optional evidence-capture roots are created later by the capture guides that actually use them. Child directories belong to the runbook or script that creates them.

For example:

- `secrets-encrypted/` is created here only as a top-level container.
- nested secrets folders are created later by the secrets runbook, manual staging steps, `backup-home-files-backup.sh`, or `create-secrets-dmg.sh`.
- `reimage-confirmation/` is created here so the filled Phase 0 IT confirmation can be copied into the external root during Phase 1.
- toolkit snapshot child folders are created later by `capture-toolkit-snapshot.md`.

```bash
python3 bin/prepare-artifact-root.py \
  create-standard-layout \
  --env-file reimage.env
```

Layout after this step, top-level directories only:

```text
$REIMAGE_ARTIFACT_ROOT/
├── app-settings-backup/
├── gitignore-superset/
├── home-files-backup/
├── loose-secrets-reports/
├── managed-inventory/
├── public-certs/
├── reimage-confirmation/
├── reimage-prep-checks/
├── reimaged-system/
├── repo-audit-reports/
├── secrets-encrypted/
├── size-audit-reports/
├── staged-ignored-files/
├── system-inventory/
├── time-machine/
└── toolkit-snapshot/
```

For child-directory details, use the guide that owns that workflow. For example, `backup-dmg-secrets.md` owns the expected `secrets-encrypted/` staging, DMG, validation, and cleanup layout.

Folder purpose:

| Folder                     | Purpose                                                                                                                                                                                                                                   |
|-----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `app-settings-backup/`      | App-specific exported settings, inventories, notes, and app-owned restore artifacts such as Chrome bookmarks, Docker settings, Postman exports, Raycast exports, Obsidian copies, VS Code fallback state, and IntelliJ backup material.    |
| `gitignore-superset/`       | Reviewable superset of ignored patterns across repos.                                                                                                                                                                                        |
| `home-files-backup/`        | Home folders, dotfiles, and selected local files copied by `backup-home.sh`.                                                                                                                                                                 |
| `loose-secrets-reports/`    | Loose-plaintext-secret check history from `report-loose-secrets.sh` (Phase 3B) — rolling `open-findings.md`, the `findings-ledger.tsv` behind it, an append-only manifest, and timestamped run directories. Names candidate paths, never file contents.                          |
| `managed-inventory/`        | Company-managed component inventory before erase — MDM/Intune enrollment status, installed profiles, managed app bundles and package receipts, background managed services, and managed preference payloads.                              |
| `public-certs/`             | Non-secret certificate material — sanitized notes, inventories, decision logs, and public-only convenience certificate copies. Secret-bearing or uncertain certificate material goes under `secrets-encrypted/certs/` instead.              |
| `reimage-confirmation/`     | Filled copy of the Phase 0 IT reimage confirmation kept with the external backup root from the start of the reimage effort.                                                                                                                 |
| `reimage-prep-checks/`      | Final reimage preparation checks go/no-go checklist reports.                                                                                                                                                                                 |
| `reimaged-system/`          | Initial enrollment captures and checks, reimaged system evidence, restart notes, restore notes, Time Machine notes, and final validation artifacts.                                                                                         |
| `repo-audit-reports/`       | Repository state reports; not a full source backup.                                                                                                                                                                                          |
| `secrets-encrypted/`        | Top-level container for the secrets workflow. Nested secret staging folders, final DMG artifacts, Java inventory, certificate review reports, and restore README are created later by the owning secrets steps.                            |
| `size-audit-reports/`       | Backup-size-audit run history from `report-size-audit.sh` — append-only manifest, latest-run pointer, and self-contained timestamped run directories with the full colorized report; not a copy of backup content itself.                 |
| `staged-ignored-files/`     | Ignored/local file staging output from the Git-repo backup selected-pattern workflow — dry run, filtered dry run, and final live copies.                                                                                                    |
| `system-inventory/`         | Developer-tool version and workstation inventory captured before erase, to speed up rebuilding the environment afterward.                                                                                                                   |
| `time-machine/`             | Time Machine status capture bundles only. Actual Time Machine backups live on the Time Machine volume.                                                                                                                                       |
| `toolkit-snapshot/`        | Toolkit snapshot captures and workflow documentation snapshots.                                                                                                                                                                              |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Copy the Filled IT Reimage Confirmation Into reimage-confirmation

After the standard layout exists, copy the filled Phase 0 IT confirmation into the new top-level `reimage-confirmation/` folder:

```bash
python3 bin/prepare-artifact-root.py \
  copy-it-plan \
  --env-file reimage.env
```

This looks for the newest `it-reimage-confirmation-*.md` under `<REIMAGE_WORKSPACE_ROOT>/reimage-confirmation/`.

If `REIMAGE_WORKSPACE_ROOT` isn't set in `reimage.env`, pass the workspace root directly instead:

```bash
python3 bin/prepare-artifact-root.py \
  copy-it-plan \
  --env-file reimage.env \
  --workspace-root "$REIMAGE_WORKSPACE_ROOT"
```

This searches `<REIMAGE_WORKSPACE_ROOT>/reimage-confirmation/` without requiring `REIMAGE_WORKSPACE_ROOT` to be defined in `reimage.env` (`--workspace-root` is ignored if `--source` is used).

If the filled note is not under `<REIMAGE_WORKSPACE_ROOT>/reimage-confirmation/`, provide the explicit source path:

```bash
python3 bin/prepare-artifact-root.py \
  copy-it-plan \
  --env-file reimage.env \
  --source "/absolute/path/to/it-reimage-confirmation-YYYYMMDD.md"
```

Expected destination:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-confirmation/it-reimage-confirmation-YYYYMMDD.md
```

The entrypoint preserves the source filename and saves a timestamped `.previous-*` backup only when the destination already exists and differs.

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

If instead it reports missing top-level folders:

```text
MISSING: app-settings-backup
MISSING: home-files-backup
MISSING: secrets-encrypted
```

> [!bug] Troubleshooting
> If verification reports `MISSING:` folders, see [[#Directory Verification Is Missing Folders|Directory Verification Is Missing Folders]].

If the parent write test fails on permissions or ownership:

```text
WRITE TEST FAILED: [Errno 13] Permission denied: '.../write-test'
```

> [!bug] Troubleshooting
> If the write test fails with a permission or ownership error, see [[#Permission Issues Restoring Files|Permission Issues Restoring Files]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Background material that earlier steps link to but don't require you to read to execute them. Nothing in here is a step to run -- come back to it when a step points you here, or if you want the deeper "why," not as part of the sequential path.

### Repo Path Variables and Self-Locating Scripts

"Self-locate" only means the scripts find their own code (`bin/`, `.internal/`) from `bin/prepare-artifact-root.py`'s own file path, no matter how it's invoked. It does **not** mean the commands in this guide can be run from any directory. Every command in this guide that references `reimage.env`, `reimage.env.example`, or `--env-file reimage.env` uses a path relative to the repo root, so the current working directory still has to *be* the repo root (or you have to pass an absolute path) for those relative references to resolve. `export` commands themselves attach to the shell session, not to a directory, so they survive a `cd` -- but this guide keeps you in the repo root the whole time anyway, since that's also where the relative `reimage.env` lives. 

`bin/setup-reimage-env.sh` is a concrete example of this boundary: it explicitly checks that `reimage.env.example` exists in the current directory before doing anything else, precisely because it expects to be run from the repo root -- run it from anywhere else and it refuses to proceed rather than silently failing later. 

#### Path variable definitions

Three different paths related to the cloned repo get referenced across this guide and the repo's `bootstrap.sh`/`.envrc`. They are easy to conflate because two of them can resolve to the same literal value depending on how you installed the repo:

| Variable | What it is | Set by | Lifetime |
|---|---|---|---|
| `FRACTOGENESIS_PARENT` | The **parent** directory you clone the repo into -- i.e. the folder that will contain `fractogenesis-toolkit/` after `git clone`. Only meaningful during the initial clone. | You, manually, only if cloning with `git clone`. | This terminal session only, during cloning. Not written to any file. |
| `FRACTOGENESIS_HOME` | The **repo root itself** -- the top-level `fractogenesis-toolkit/` directory, i.e. `$FRACTOGENESIS_PARENT/fractogenesis-toolkit` if you cloned it, or `$HOME/fractogenesis-toolkit` if you used `bootstrap.sh`'s default. This is the directory that contains `bin/`, `.internal/`, and `reimage.env`. | `.envrc` (`export FRACTOGENESIS_HOME="$(pwd)"`) once direnv is set up. Before direnv is set up, it is simply wherever you `cd`ed after cloning/bootstrapping. | Reappears automatically on every `cd` into the repo once direnv is active. |
| `$HOME` | The standard macOS user home directory. Only relevant here as `bootstrap.sh`'s *default* clone parent (`$HOME/fractogenesis-toolkit`) and as the base for unrelated paths like `~/.ssh` or `~/Library/CloudStorage`. It is not a repo-specific variable. | macOS. | Always set. |

In short: `FRACTOGENESIS_PARENT` is where you clone *into*; `FRACTOGENESIS_HOME` is the checkout *itself*; `$HOME` is just the user's home directory and only overlaps with `FRACTOGENESIS_HOME`'s value when you accept `bootstrap.sh`'s default location.

#### Why set these at all, if the scripts self-locate?

Neither `bin/prepare-artifact-root.py` nor `.internal/artifact-config.sh` ever reads `FRACTOGENESIS_PARENT` or `FRACTOGENESIS_HOME`. Both self-locate from their own file path, so neither variable is required for the core tooling in this guide to work correctly. They exist for two different, narrower reasons -- neither of which is "the script needs it":

- `FRACTOGENESIS_PARENT` is scratch, throwaway convenience -- it exists only to make the three-line `mkdir`/`cd`/`git clone` sequence easier to read and re-run. Nothing reads it afterward, and it is never written to any file. You could skip setting it entirely and just `cd` to wherever you want and run `git clone ...` directly, with the same result.
- `FRACTOGENESIS_HOME` is set automatically by `.envrc` once direnv is active, purely as a human-facing "where am I right now" reference -- nothing documented in this guide consumes it. Treat it as informational output, not an input you need to set or override.

In practice: you only ever *set* `FRACTOGENESIS_PARENT` yourself, and only if cloning manually; you never set `FRACTOGENESIS_HOME` yourself, since direnv derives it from `pwd`; and you never set `$HOME` at all, since macOS does. What actually matters for every command in this guide is simply having your current working directory be the repo root.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### reimage.env Must Contain Resolved Values, Not Literal References

`reimage.env` should be boring: one `export NAME=value` line per setting, with actual, resolved values -- never a helper-variable reference, a template placeholder, or a literal shell-expansion string left un-evaluated.

Specifically, never store any of these in `reimage.env`:

- Helper-variable references such as `REIMAGE_START_DATE_DEFAULT` or `ASSET_OR_HOST_DEFAULT` -- these are internal names the tooling may use for its own defaulting logic, not values meant to be written into the file.
- A literal, unexpanded reference such as `$EXTERNAL_DATA_VOLUME` or `$ASSET_OR_HOST` where an actual path or value belongs -- for example `REIMAGE_ARTIFACT_ROOT=$EXTERNAL_DATA_VOLUME/reimage-...` instead of the real resolved path.
- A literal `$HOME/...` string in an optional path such as `OFFICE_WATCH` or `ONEDRIVE_ROOT` -- write the fully resolved absolute path instead (e.g. `/Users/<user>/Desktop/...`, not `$HOME/Desktop/...`).

Optional paths should either be left blank or written as absolute resolved paths -- never as an unresolved template.

Why this matters: `reimage.env` gets `source`d with `set -a`/`set +a` by multiple scripts across this guide, sometimes under `set -u` (nounset). An unresolved reference like `$ASSET_OR_HOST` sourced before that variable exists in the same shell throws an "unbound variable" error; a literal `$HOME/...` string just silently fails to expand into a real path, since `reimage.env` is sourced as data, not re-evaluated as a template each time. Both failure modes are avoided entirely by only ever writing fully resolved values into the file in the first place.

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

[[#Confirm External Data Volume Readiness|⮕ Continue to Confirm External Data Volume Readiness]]

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

[[#Create Local Reimage Environment Profile|⮕ Continue to Create Local Reimage Environment Profile]]

---

### Can't Write to the Volume

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

After the repair succeeds, rerun the create helper.

[[#Create Local Reimage Environment Profile|⮕ Continue to Create Local Reimage Environment Profile]]

---

### Terminal Privacy Block

Symptoms:

```text
mkdir: cannot create directory '/Volumes/<external-data-volume-name>/reimage-<asset-or-host>-<start-date>-open': Operation not permitted
touch: ... Operation not permitted
```

Use this section for `Operation not permitted`.

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

Do not erase, repair, or repartition the external drive until you are certain which disk and volume you are looking at.

[[#Create Local Reimage Environment Profile|⮕ Continue to Create Local Reimage Environment Profile]]

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

Or add the optional zsh persistence block from Load and Confirm the Environment.

[[#Create the Standard Directory Layout|⮕ Continue to Create the Standard Directory Layout]]

---

### Literal Paths in reimage.env

Symptoms:

```text
reimage.env: line 7: REIMAGE_START_DATE_DEFAULT: unbound variable
REIMAGE_ARTIFACT_ROOT=<$EXTERNAL_DATA_VOLUME/reimage-$ASSET_OR_HOST-$REIMAGE_START_DATE-open>
OFFICE_WATCH=$HOME/Desktop/ms-office-stability-watch
REIMAGE_ARTIFACT_ROOT or an optional path contains literal variable text instead of a resolved path
```

This means `reimage.env` contains helper-variable references or quoted literal paths instead of resolved values.

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

[[#Set Up direnv|⮕ Continue to Set Up direnv]]

---

### Folder Under the Repo

Symptoms:

```text
A folder literally named $EXTERNAL_DATA_VOLUME exists under this repo's checkout
You previously ran a manual sudo mkdir repair while REIMAGE_ARTIFACT_ROOT still printed unresolved text
```

Cause: if you ran a manual, targeted `sudo mkdir` repair while `REIMAGE_ARTIFACT_ROOT` still contained unresolved text such as `$EXTERNAL_DATA_VOLUME/reimage-$ASSET_OR_HOST-$REIMAGE_START_DATE-open`, that repair did **not** create the real external-drive folder. It most likely created a relative folder literally named `$EXTERNAL_DATA_VOLUME` under whatever directory the command was run in -- almost always this repo checkout.

Check for and remove that accidental literal folder, only after confirming it's under this repo's checkout and not under `/Volumes`:

```bash
if [[ -d './$EXTERNAL_DATA_VOLUME' ]]; then
  echo "Found accidental literal folder under the repo checkout:"
  /bin/ls -la './$EXTERNAL_DATA_VOLUME' 2>/dev/null || ls -la './$EXTERNAL_DATA_VOLUME'
  echo
  echo "Remove it only if this is the accidental folder from the earlier literal REIMAGE_ARTIFACT_ROOT repair."
else
  echo "OK: no accidental literal ./\$EXTERNAL_DATA_VOLUME folder found under the repo checkout"
fi
```

If that confirms it's the accidental folder, remove it manually rather than as part of a pasted block:

```bash
rm -rf './$EXTERNAL_DATA_VOLUME'
```

Then confirm `REIMAGE_ARTIFACT_ROOT` prints as an absolute `/Volumes/...` path before rerunning the create helper.

[[#Load and Confirm the Environment|⮕ Continue to Load and Confirm the Environment]]

---

### Empty / Unrecognized

The file exists, but `bin/check-reimage-env.sh` found none of the expected variables -- usually because an earlier run was interrupted before writing anything, or the file predates this guide's current variable names.

Inspect it directly before deciding anything:

```bash
cat reimage.env
```

If it's genuinely empty or clearly unusable, delete it and continue from there. If it has content under different/older variable names, same treatment -- archive it rather than trying to reconcile the old names by hand.

[[#Required and Default Values|⮕ Continue to Required and Default Values]]

---

### Directory Verification Is Missing Folders

Symptoms:

```text
MISSING: app-settings-backup
MISSING: home-files-backup
MISSING: secrets-encrypted
```

Rerun the standard directory creation helper:

```bash
python3 bin/prepare-artifact-root.py \
  create-standard-layout \
  --env-file reimage.env
```

This rerun creates only the stable top-level folders. It must not create any child folders under optional capture roots. If a missing folder is a workflow-owned child folder such as `secrets-encrypted/certs/keychain-manual-exports/`, `secrets-encrypted/extra-secrets-certs-review/`, `system-inventory/`, `performance-audit/`, or `office-stability/`, go back to the owning runbook or script instead of adding it here.

[[#Verify the Prepared Root|⬆ Back to Verify the Prepared Root]]

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

[[#Verify the Prepared Root|⬆ Back to Verify the Prepared Root]]
