[[reimaging-guide#Phase 1 — Prepare the External Artifact Root|← Back to Mac Reimaging Guide]]

# Prepare Artifact Root

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
- [[#Sequential Steps|Sequential Steps]]
    - [[#Confirm the Repo Is Cloned|Confirm the Repo Is Cloned]]
    - [[#Choose the External Data Volume|Choose the External Data Volume]]
    - [[#Confirm External Data Volume Readiness|Confirm External Data Volume Readiness]]
    - [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]]
    - [[#Set Up direnv|Set Up direnv]]
    - [[#Define Git Repository Roots|Define Git Repository Roots]]
    - [[#Create the Artifact Root|Create the Artifact Root]]
    - [[#Load and Confirm the Environment|Load and Confirm the Environment]]
    - [[#Understand artifact-config.sh|Understand artifact-config.sh]]
        - [[#If You Already Have Real Config Fragments|If You Already Have Real Config Fragments]]
        - [[#Initialize the Fragments From Scratch|Initialize the Fragments From Scratch]]
    - [[#Create the Standard Directory Layout|Create the Standard Directory Layout]]
    - [[#Copy the Filled IT Reimage Confirmation Into reimage-confirmation|Copy the Filled IT Reimage Confirmation Into reimage-confirmation]]
    - [[#Verify the Prepared Root|Verify the Prepared Root]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Repo Path Variables and Self-Locating Scripts|Repo Path Variables and Self-Locating Scripts]]
    - [[#Handle Existing Reimage Environment|Handle Existing Reimage Environment]]
    - [[#reimage.env Must Contain Resolved Values, Not Literal References|reimage.env Must Contain Resolved Values, Not Literal References]]
- [[#Troubleshooting|Troubleshooting]]
    - [[#External Data Volume Not Visible|External Data Volume Not Visible]]
    - [[#External Data Volume Is Read Only|External Data Volume Is Read Only]]
    - [[#External Data Volume Is Writable but Current User Cannot Write|External Data Volume Is Writable but Current User Cannot Write]]
    - [[#Terminal Privacy Access Is Blocking External Volume Access|Terminal Privacy Access Is Blocking External Volume Access]]
    - [[#REIMAGE_ARTIFACT_ROOT Is Empty in Scripts|REIMAGE_ARTIFACT_ROOT Is Empty in Scripts]]
    - [[#Pasted Code Breaks in Interactive zsh|Pasted Code Breaks in Interactive zsh]]
    - [[#reimage.env Contains Helper Variables or Literal Paths|reimage.env Contains Helper Variables or Literal Paths]]
    - [[#Accidental Literal-Named Folder Under the Repo Checkout|Accidental Literal-Named Folder Under the Repo Checkout]]
    - [[#Existing reimage.env Has Stale Values From a Previous Reimage|Existing reimage.env Has Stale Values From a Previous Reimage]]
    - [[#Empty or Unrecognized reimage.env|Empty or Unrecognized reimage.env]]
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

Top-level directories created under `$REIMAGE_ARTIFACT_ROOT` by [[#Create the Standard Directory Layout|Create the Standard Directory Layout]]:

These are the standard top-level folders this phase creates — the ones
needed on every reimage run, regardless of symptoms or which situational
phases apply. Folders tied to a situational capture, such as a performance
or Office-stability symptom, are created later by that phase's own script
when it actually runs, not here. See `master-directory-reference.md` for
the complete superset.

```text
$REIMAGE_ARTIFACT_ROOT/
├── app-settings-backup/
├── gitignore-superset/
├── home-files-backup/
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
└── workflow-snapshot/
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

`$FRACTOGENESIS_HOME` above is reference notation showing where these files live, not a literal path you can use from a fresh terminal -- direnv only populates it once you've already `cd`ed into the repo. Commands elsewhere in this guide `cd "$FRACTOGENESIS_HOME"` first for that reason; see [[#Repo Path Variables and Self-Locating Scripts|Repo Path Variables and Self-Locating Scripts]] for the full explanation.

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

Troubleshooting is intentionally at the end. Specific steps link to the relevant troubleshooting section only when something fails. Background material that isn't needed to execute a step -- but that a step may still link out to for deeper context -- lives in [[#Supplemental Reference|Supplemental Reference]], also at the end, just before Troubleshooting.

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

### Artifact Root Naming Convention

This is background/reference material -- read it before running anything so the name you pick in [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]] makes sense the first time, rather than getting renamed later. It does not itself involve running any commands.

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

The actual computation of `$REIMAGE_ARTIFACT_ROOT` from these patterns is an active step -- see [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]] in Sequential Steps.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Sequential Steps

This section is the ordered execution path for preparing the artifact root: confirm the repo checkout, choose and verify the external volume, set up or resume `reimage.env`, load it into the shell (direnv or manual `source`), define the git repo roots, create the artifact root and its standard folder layout, drop in the filled IT reimage confirmation, then verify the result. Each step assumes the ones before it are already done -- see [[#Preparation Sequence|Preparation Sequence]] above for why the order matters.

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

If `.internal/artifact-config.sh` is missing, stop and confirm you are in the right repo checkout.

See [[#Path variable definitions|Path variable definitions]] above if the difference between `FRACTOGENESIS_PARENT`, `FRACTOGENESIS_HOME`, and `$HOME` isn't clear yet -- it's used throughout this section.

#### If the repo is already cloned

If `pwd`/`find` above already showed the expected files, you're done with this step -- just make sure you're sitting at the repo root, not a subdirectory:

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
pwd
```

Skip straight to [[#Choose the External Data Volume|Choose the External Data Volume]].

#### If the repo is not cloned yet

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

**On a freshly reimaged Mac** (no Git/SSH yet — this is the actual scenario Phase 6 onward depends on): use the bootstrap mechanism instead of `git clone` — no auth needed, no Xcode Command Line Tools popup:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-github-account>/fractogenesis-toolkit/main/bootstrap.sh | bash
```

This installs to `$HOME/fractogenesis-toolkit` by default -- in other words, on a fresh reimage, `FRACTOGENESIS_PARENT` is implicitly `$HOME` and `FRACTOGENESIS_HOME` becomes `$HOME/fractogenesis-toolkit`, without you having to set `FRACTOGENESIS_PARENT` yourself. `cd` into it the same way:

```bash
cd "$HOME/fractogenesis-toolkit"
pwd
```

If there's no network yet, use the prepared jump drive fallback instead — see the repo README or Phase 6 of `reimaging-guide.md` for the exact command.

The repo is public, so no access request is needed either way.

#### Stay here

Every remaining step in this guide, through [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]], assumes the current working directory is this repo root (`FRACTOGENESIS_HOME`). Keep this terminal session open and `cd`ed here -- or re-`cd` here first -- for every command from this point on, including the plain `export` commands in the next two steps, which don't strictly require it but are shown assuming it.

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

This is the one place in the guide where `EXTERNAL_DATA_VOLUME` and `EXTERNAL_APPLE_BACKUPS_VOLUME` get created -- as plain shell exports, not written to a file, since `reimage.env` doesn't exist yet.

**Run this in the same terminal session you've been in since [[#Confirm the Repo Is Cloned|Confirm the Repo Is Cloned]]**, and keep that session open through the next two steps, which reuse these same two exports rather than re-creating them:

- [[#Confirm External Data Volume Readiness|Confirm External Data Volume Readiness]]
- [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]]

```bash
export EXTERNAL_DATA_VOLUME="/Volumes/<external-data-volume-name>"
export EXTERNAL_APPLE_BACKUPS_VOLUME="/Volumes/<time-machine-volume-name>"
```

Do not use the Time Machine volume as the manual artifact volume. In the example above, the artifact root should live under `/Volumes/Data`, not `/Volumes/AppleBackups`.

These values get written into `reimage.env` for real once it's created a few steps from now ([[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]]) -- no need to edit any file yet.

If the expected external data volume is missing, jump to [[#External Data Volume Not Visible|External Data Volume Not Visible]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Confirm External Data Volume Readiness

Confirm the selected external parent volume is mounted, is not read-only, and allows the current macOS user to write at the parent path. This step checks the external drive itself before the artifact root exists.

This step reuses the `EXTERNAL_DATA_VOLUME`/`EXTERNAL_APPLE_BACKUPS_VOLUME` exported in the previous step -- confirm they're still set before continuing:

```bash
printf 'EXTERNAL_DATA_VOLUME=%s\n' "${EXTERNAL_DATA_VOLUME:-}"
printf 'EXTERNAL_APPLE_BACKUPS_VOLUME=%s\n' "${EXTERNAL_APPLE_BACKUPS_VOLUME:-}"
```

If either printed blank -- for example because you opened a new terminal since the last step -- re-export them now (same values as [[#Choose the External Data Volume|Choose the External Data Volume]]; do not source `reimage.env` here, it doesn't exist yet):

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

### Create Local Reimage Environment Profile

Create `reimage.env`, the local, machine-specific config file the rest of this guide reads for `REIMAGE_ARTIFACT_ROOT`, `REIMAGE_WORKSPACE_ROOT`, and related paths.

Before running anything below, confirm these are still exported in this terminal session from [[#Choose the External Data Volume|Choose the External Data Volume]]:

- `EXTERNAL_DATA_VOLUME`
- `EXTERNAL_APPLE_BACKUPS_VOLUME` (if used)

And confirm you're still sitting in the repo root (`FRACTOGENESIS_HOME`) from [[#Confirm the Repo Is Cloned|Confirm the Repo Is Cloned]]:

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

Example output when a file from an earlier attempt is still present:


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

- **`No existing reimage.env.`** -- the common case. Nothing to reconcile; continue to [[#Required and Default Values|Required and Default Values]] below.
- **Values printed** -- compare them against the ground truth, then go to [[#Handle Existing Reimage Environment|Handle Existing Reimage Environment]] in Supplemental Reference to resume, archive, or repair it before continuing here.

#### Required and Default Values

Before creating `reimage.env`, confirm you have the required environment variables, and decide whether to accept the computed defaults below or override them.

Required, exported earlier in [[#Choose the External Data Volume|Choose the External Data Volume]]:

| Variable | Required? | Source |
|---|---|---|
| `EXTERNAL_DATA_VOLUME` | Required | [[#Choose the External Data Volume\|Choose the External Data Volume]] |
| `EXTERNAL_APPLE_BACKUPS_VOLUME` | Optional | Same step, if a Time Machine destination is in use |

`bin/setup-reimage-env.sh` computes the rest for you -- you rarely need to type anything, but each can be overridden by exporting your own value beforehand:

| Variable | Default the script computes | Override when... |
|---|---|---|
| `ASSET_OR_HOST` | The Mac's short hostname | You want a shorter/cleaner tag than the raw hostname, or need to anonymize it in shared notes. |
| `REIMAGE_START_DATE` | Today's date (`YYYYMMDD`) | The reimage effort actually started on an earlier date than when you're running this command. |
| `REIMAGE_ARTIFACT_ROOT` * | `$EXTERNAL_DATA_VOLUME/reimage-$ASSET_OR_HOST-$REIMAGE_START_DATE-open` | Not set directly -- always built from the two values above. |

\* See [[#Artifact Root Naming Convention|Artifact Root Naming Convention]] for the full naming pattern this interpolation follows.

To override a default, export before running the script:

```bash
export ASSET_OR_HOST="my-custom-tag"
```

#### Files and .gitignore

This file is local-only and should not be committed. Neither should any archived copy of it.

| File | Commit to repo? | Purpose |
|---|---:|---|
| `reimage.env.example` | Yes | Template showing required variables and naming conventions. |
| `reimage.env` | No | Local machine-specific config used by your terminal and scripts. |
| `reimage.env.stale-*` | No | Archived copies created while [[#Handle Existing Reimage Environment\|handling an existing reimage.env]] -- same machine-specific/sensitive content as `reimage.env` itself, just renamed, not sanitized. |

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
3. Confirms `EXTERNAL_DATA_VOLUME` is exported -- refuses to run otherwise, rather than silently writing a blank/placeholder value you'd have to fix later.
4. Copies the template to `reimage.env`.
5. Runs `prepare-artifact-root.py init-reimage-env`, which resolves `ASSET_OR_HOST` and `REIMAGE_START_DATE` (your exported override, or its own default if unset), builds `REIMAGE_ARTIFACT_ROOT` from them, and writes all three into `reimage.env` in the same step -- along with the remaining resolved starter values (default workspace paths, confirmed volume paths).
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
| `REIMAGE_WORKSPACE_ROOT`     | Must point to a local workspace outside this repo. Recommended default: the same planning folder used for the IT reimage confirmation.                                                                                                                     |
| `PERFORMANCE_HISTORY_SOURCE` | Optional. Leave blank unless you already have a reusable local performance-history source such as `~/Library/Logs/mac-memory-health`.                                                                                                                              |
| `EXTERNAL_DATA_VOLUME`         | Should already match the volume confirmed a few steps ago.                                                                                                                                                                                      |
| `EXTERNAL_APPLE_BACKUPS_VOLUME`    | Should already match the Time Machine destination volume, if one was set.                                                                                                 |
| `ASSET_OR_HOST`              | Resolved once by `bin/setup-reimage-env.sh` and reused for both this field and `REIMAGE_ARTIFACT_ROOT` -- no separate detection to drift out of sync with. |
| `REIMAGE_START_DATE`         | Resolved once, the same way. |
| `REIMAGE_ARTIFACT_ROOT`                | Should already be the resolved absolute path -- not blank.                                                                                                                             |
| `OFFICE_WATCH`               | Optional. Leave blank unless Office stability watcher output is part of this workflow. If used, store a resolved absolute path such as `/Users/<user>/Desktop/<office-watch-folder>`, not a literal `$HOME/...` string. `artifact-config.sh` shares it with scripts. |
| `ONEDRIVE_FOLDER_NAME`       | Optional. Use only when the local OneDrive folder should be resolved under `$HOME/Library/CloudStorage/`. Leave blank if OneDrive is not used.                                                                                                                     |
| `ONEDRIVE_ROOT`              | Optional. Prefer a resolved absolute path to the local OneDrive sync folder when OneDrive is used. Leave blank if OneDrive is not used. Do not store a literal `$HOME/...` string.                                                                                 |
| `ONEDRIVE_DEST_SUBDIR`       | Already defaulted to the artifact root folder name by `setup-reimage-env.sh`.                                                                                            |

There's no environment variable to set for the repository's own path. `prepare-artifact-root.py` self-locates from its own position in the repo -- wherever this checkout lives, the script finds `bin/` and `.internal/` relative to itself, so nothing needs to be told where the repo is. See [[#Repo Path Variables and Self-Locating Scripts|Repo Path Variables and Self-Locating Scripts]] in Supplemental Reference for what that does and doesn't cover. Stay in `FRACTOGENESIS_HOME` for this and every remaining step.

`reimage.env` should contain resolved values only:

- Never a helper-variable reference.
- Never a literal `$HOME/...`-style path.

If a script reports an unbound variable while sourcing `reimage.env`, or a verification step prints a path such as `$HOME/Desktop/...`, jump to [[#reimage.env Contains Helper Variables or Literal Paths|reimage.env Contains Helper Variables or Literal Paths]].

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

- [[#First-Time direnv Setup|First-Time direnv Setup]]
- [[#direnv Already Set Up From a Previous Effort|direnv Already Set Up From a Previous Effort]]

Then confirm your shell has `reimage.env` loaded correctly

- [[#Confirm reimage.env Is Loaded|Confirm reimage.env Is Loaded]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

#### First-Time direnv Setup

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
printf 'FRACTOGENESIS_HOME=%s\n' "$FRACTOGENESIS_HOME"
printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
```

Both should print resolved values with no further action. `cd` out of the repo and both should be unset; `cd` back in and both should reappear — that round trip is the actual proof direnv is doing its job, not just that the file exists.

The `if [[ -f reimage.env ]]; then dotenv reimage.env; fi` line in `.envrc` is why a stale `reimage.env` matters even though `.envrc` itself doesn't go stale: direnv will happily `dotenv` whatever `reimage.env` currently exists, old or new, with no distinction. That's the scenario [[#Handle Existing Reimage Environment|Handle Existing Reimage Environment]] exists to catch earlier in this guide -- if you skipped it, go back and run it before trusting what `REIMAGE_ARTIFACT_ROOT` just printed above.

[[#Set Up direnv|⬆ Back to Set Up direnv]]

---

#### direnv Already Set Up From a Previous Effort

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
printf 'FRACTOGENESIS_HOME=%s\n' "$FRACTOGENESIS_HOME"
printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
```

Both should print resolved values with no further action. `cd` out of the repo and both should be unset; `cd` back in and both should reappear — that round trip is the actual proof direnv is doing its job, not just that the file exists.

The `if [[ -f reimage.env ]]; then dotenv reimage.env; fi` line in `.envrc` is why a stale `reimage.env` matters even though `.envrc` itself doesn't go stale: direnv will happily `dotenv` whatever `reimage.env` currently exists, old or new, with no distinction. That's the scenario [[#Check for an Existing reimage.env|Check for an Existing reimage.env]] exists to catch earlier in this guide -- if you skipped it, go back and run it before trusting what `REIMAGE_ARTIFACT_ROOT` just printed above.

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

A resolved, non-blank `REIMAGE_ARTIFACT_ROOT` here only proves *a* value loaded -- not that it's *this* effort's value. If you skipped [[#Handle Existing Reimage Environment|Handle Existing Reimage Environment]] or arrived here after a break of days or weeks, double-check the printed path actually matches the effort you're working on today; see [[#Existing reimage.env Has Stale Values From a Previous Reimage|Existing reimage.env Has Stale Values From a Previous Reimage]] if it doesn't.

[[#Set Up direnv|⬆ Back to Set Up direnv]]

---

### Define Git Repository Roots

Define the local repository root directories in `reimage.env` before the Backup Repos phase.

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
if [[ -z "$GIT_WORK_REPO_ROOT" ]]; then
  echo "ERROR: GIT_WORK_REPO_ROOT is empty -- the export above didn't take. Fix it before continuing; do not run upsert-env with an empty value."
  return 1 2>/dev/null || exit 1
fi
```

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
OK: backup root exists
```

Route based on what it actually prints:

- **Both `OK:` lines above** -- continue to [[#Load and Confirm the Environment|Load and Confirm the Environment]] (or [[#Rename after final post-image capture|Rename after final post-image capture]], but only once the effort is actually done).
- **`Permission denied`** → [[#External Data Volume Is Writable but Current User Cannot Write|External Data Volume Is Writable but Current User Cannot Write]].
- **`Operation not permitted`** → [[#Terminal Privacy Access Is Blocking External Volume Access|Terminal Privacy Access Is Blocking External Volume Access]].
- **Literal variable text in `REIMAGE_ARTIFACT_ROOT`** (e.g. it still contains `$EXTERNAL_DATA_VOLUME`), or an empty value → [[#reimage.env Contains Helper Variables or Literal Paths|reimage.env Contains Helper Variables or Literal Paths]].
- **You previously ran a manual `sudo mkdir` repair and suspect it created a folder under this repo checkout instead of the real external path** → [[#Accidental Literal-Named Folder Under the Repo Checkout|Accidental Literal-Named Folder Under the Repo Checkout]].

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

### Understand artifact-config.sh

`artifact-config.sh` is the single source of truth for local-file backup targets, excludes, descriptions, and expected top-level folders used by the backup scripts.

The arrays and flags are now stored in reusable shell config fragments instead of being hard-coded inline in the loader. Shell fragments were chosen instead of YAML so the existing bash scripts can source them directly while keeping the annotation comments intact.

It is sourced by scripts such as:

```text
bin/backup-home.sh
bin/capture-size-audit.sh
bin/capture-workflow-snapshot.sh
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
| It prefers workspace-backed config fragments when they exist. | `REIMAGE_WORKSPACE_ROOT/artifact-config/` becomes the reusable local copy for reruns; otherwise the loader falls back to `.github/copilot-templates/artifact-config/`. |
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
managed-inventory
public-certs
reimage-confirmation
reimage-prep-checks
reimaged-system
repo-audit-reports
secrets-encrypted
size-audit-reports
staged-ignored-files
time-machine
workflow-snapshot
```

The layout created in [[#Create the Standard Directory Layout|Create the Standard Directory Layout]] includes only the stable top-level folders. Child folders for setup notes, secrets staging, optional evidence captures, and other workflow-owned artifacts are created later by their owning runbooks or scripts.

Route based on whether you already have real config fragments:

- **You already have real `*.conf.sh` fragments** -- from a previous setup, a `fractogenesis-toolkit` checkout, or anywhere else → [[#If You Already Have Real Config Fragments|If You Already Have Real Config Fragments]].
- **You don't have them yet** and need to start from this repo's placeholder templates → [[#Initialize the Fragments From Scratch|Initialize the Fragments From Scratch]].

Either way, before running local-file backup scripts, confirm the loader can still be parsed:

```bash
bash -n .internal/artifact-config.sh
```

If a script reports that `REIMAGE_ARTIFACT_ROOT` is not set, jump to [[#REIMAGE_ARTIFACT_ROOT Is Empty in Scripts|REIMAGE_ARTIFACT_ROOT Is Empty in Scripts]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### If You Already Have Real Config Fragments

If you already have real `*.conf.sh` fragments -- from a previous setup, copied out of a `fractogenesis-toolkit` checkout, or anywhere else -- **you don't need to copy them anywhere**. Place (or confirm they already exist) at:

`artifact-config.sh` checks this path first, automatically, every time it's sourced -- see the "prefers workspace-backed config fragments" row in [[#Understand artifact-config.sh|Understand artifact-config.sh]]. There's no manual copy step, no flag to set; the presence of real files at this exact path is the entire mechanism. Confirm it's actually picking them up:

```bash
bash -c 'source .internal/artifact-config.sh && printf "%s\n" "${EXPECTED_ARTIFACT_FOLDERS[@]}"'
```

The printed list should match the stable top-level folders shown in [[#Understand artifact-config.sh|Understand artifact-config.sh]], plus any optional folders your fragments add for the situational phases you intend to run -- see [Master Directory Reference](./references/master-directory-reference.md) for the complete set of folder names the workflow recognizes. These aren't names you choose: later runbook and script steps check for them by exact match, so anything printed here that isn't in that reference means either the fragment has a typo or the workspace copy at `$REIMAGE_WORKSPACE_ROOT/artifact-config/` isn't the one actually being sourced.

`EXPECTED_ARTIFACT_FOLDERS` is required to be the same fixed list everywhere, though, so a match there only proves sourcing succeeded -- not which copy actually won. To confirm the *workspace* copy specifically is the one being used (rather than silently falling back to the repo's own template), check a fragment that's genuinely supposed to differ per machine, such as `EXTERNAL_TARGETS`:

```bash
bash -c 'source .internal/artifact-config.sh && printf "%s\n" "${EXTERNAL_TARGETS[@]}"'
```

This should print your real backup targets -- actual paths and folder names specific to this Mac -- not the repo's placeholder example values. If it prints placeholders instead, the fragment precedence fell through to the committed template rather than picking up your workspace copy; double check the files actually exist at `$REIMAGE_WORKSPACE_ROOT/artifact-config/external-targets.conf.sh`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Initialize the Fragments From Scratch

Use this path if you don't already have real config fragments -- see [[#If You Already Have Real Config Fragments|If You Already Have Real Config Fragments]] if you do.

```bash
python3 bin/prepare-artifact-root.py \
  init-artifact-config \
  --env-file reimage.env
```

This copies this repo's committed template fragments into `$REIMAGE_WORKSPACE_ROOT/artifact-config/` -- **but only for files that don't already exist there**. These aren't blank placeholders; each fragment ships with working, usable defaults (generic backup targets, standard excludes, the required `EXPECTED_ARTIFACT_FOLDERS` set) so the workflow runs correctly out of the box. Edit them afterward for values specific to this Mac -- real backup target paths, real excludes -- the same way you'd edit any local config. It refuses to overwrite anything you already have (confirmed by testing: running it against a workspace directory with real fragments in place reports `Copied: 0, Skipped existing: 9` and leaves every real file untouched). Safe to run either way, whether or not you already have real fragments.

Use the workspace copy going forward when you rerun backups later and most of the target/exclude config has not changed. You can adjust only the files that actually changed instead of rebuilding the full artifact-config setup from scratch.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Create the Standard Directory Layout

Create only the stable top-level generated-artifact directories owned by this preparation guide. Optional evidence-capture roots are created later by the capture guides that actually use them. Child directories belong to the runbook or script that creates them.

For example:

- `secrets-encrypted/` is created here only as a top-level container.
- nested secrets folders are created later by the secrets runbook, manual staging steps, `backup-home-files-backup.sh`, or `create-secrets-dmg.sh`.
- `reimage-confirmation/` is created here so the filled Phase 0 IT confirmation can be copied into the external root during Phase 1.
- workflow snapshot child folders are created later by `capture-workflow-snapshot.md`.

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
└── workflow-snapshot/
```

For child-directory details, use the guide that owns that workflow. For example, `backup-dmg-secrets.md` owns the expected `secrets-encrypted/` staging, DMG, validation, and cleanup layout.

Folder purpose:

| Folder                     | Purpose                                                                                                                                                                                                                                   |
|-----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `app-settings-backup/`      | App-specific exported settings, inventories, notes, and app-owned restore artifacts such as Chrome bookmarks, Docker settings, Postman exports, Raycast exports, Obsidian copies, VS Code fallback state, and IntelliJ backup material.    |
| `gitignore-superset/`       | Reviewable superset of ignored patterns across repos.                                                                                                                                                                                        |
| `home-files-backup/`        | Home folders, dotfiles, and selected local files copied by `backup-home.sh`.                                                                                                                                                                 |
| `managed-inventory/`        | Company-managed component inventory before erase — MDM/Intune enrollment status, installed profiles, managed app bundles and package receipts, background managed services, and managed preference payloads.                              |
| `public-certs/`             | Non-secret certificate material — sanitized notes, inventories, decision logs, and public-only convenience certificate copies. Secret-bearing or uncertain certificate material goes under `secrets-encrypted/certs/` instead.              |
| `reimage-confirmation/`     | Filled copy of the Phase 0 IT reimage confirmation kept with the external backup root from the start of the reimage effort.                                                                                                                 |
| `reimage-prep-checks/`      | Final reimage preparation checks go/no-go checklist reports.                                                                                                                                                                                 |
| `reimaged-system/`          | Initial enrollment captures and checks, reimaged system evidence, restart notes, restore notes, Time Machine notes, and final validation artifacts.                                                                                         |
| `repo-audit-reports/`       | Repository state reports; not a full source backup.                                                                                                                                                                                          |
| `secrets-encrypted/`        | Top-level container for the secrets workflow. Nested secret staging folders, final DMG artifacts, Java inventory, certificate review reports, and restore README are created later by the owning secrets steps.                            |
| `size-audit-reports/`       | Backup-size-audit run history from `capture-size-audit.sh` — append-only manifest, latest-run pointer, and self-contained timestamped run directories with the full colorized report; not a copy of backup content itself.                 |
| `staged-ignored-files/`     | Ignored/local file staging output from the Git-repo backup selected-pattern workflow — dry run, filtered dry run, and final live copies.                                                                                                    |
| `system-inventory/`         | Developer-tool version and workstation inventory captured before erase, to speed up rebuilding the environment afterward.                                                                                                                   |
| `time-machine/`             | Time Machine status capture bundles only. Actual Time Machine backups live on the Time Machine volume.                                                                                                                                       |
| `workflow-snapshot/`        | Workflow snapshot captures and workflow documentation snapshots.                                                                                                                                                                              |
                                                                                                                                                                            |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Copy the Filled IT Reimage Confirmation Into reimage-confirmation

After the standard layout exists, copy the filled Phase 0 IT confirmation into the new top-level `reimage-confirmation/` folder:

```bash
python3 bin/prepare-artifact-root.py \
  copy-it-plan \
  --env-file reimage.env
```

This looks for the newest `it-reimage-confirmation-*.md` under `IT_PLAN_DIR` (if set in `reimage.env`), otherwise under `<REIMAGE_WORKSPACE_ROOT>/reimage-confirmation/`.

If you do not want to persist `IT_PLAN_DIR` or `REIMAGE_WORKSPACE_ROOT` in `reimage.env`, pass the workspace root directly instead:

```bash
python3 bin/prepare-artifact-root.py \
  copy-it-plan \
  --env-file reimage.env \
  --workspace-root "$REIMAGE_WORKSPACE_ROOT"
```

This searches `<REIMAGE_WORKSPACE_ROOT>/reimage-confirmation/` without requiring either variable to already be defined in `reimage.env` (`--workspace-root` is ignored if `IT_PLAN_DIR` is already set there, or if `--source` is used).

If the filled note is not under `IT_PLAN_DIR` or `REIMAGE_WORKSPACE_ROOT`, provide the explicit source path:

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

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Background material that earlier steps link to but don't require you to read to execute them. Nothing in here is a step to run -- come back to it when a step points you here, or if you want the deeper "why," not as part of the sequential path.

### Repo Path Variables and Self-Locating Scripts

"Self-locate" only means the scripts find their own code (`bin/`, `.internal/`) from `bin/prepare-artifact-root.py`'s own file path, no matter how it's invoked. It does **not** mean the commands in this guide can be run from any directory. Every command in this guide that references `reimage.env`, `reimage.env.example`, or `--env-file reimage.env` uses a path relative to the repo root, so the current working directory still has to *be* the repo root (or you have to pass an absolute path) for those relative references to resolve. `export` commands themselves attach to the shell session, not to a directory, so they survive a `cd` -- but this guide keeps you in the repo root the whole time anyway, since that's also where the relative `reimage.env` lives. See [[#Confirm the Repo Is Cloned|Confirm the Repo Is Cloned]] for where that working directory gets established.

`bin/setup-reimage-env.sh` is a concrete example of this boundary: it explicitly checks that `reimage.env.example` exists in the current directory before doing anything else, precisely because it expects to be run from the repo root -- run it from anywhere else and it refuses to proceed rather than silently failing later. See [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]] for the rest of what that script does.

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

- `FRACTOGENESIS_PARENT` is scratch, throwaway convenience -- it exists only to make the three-line `mkdir`/`cd`/`git clone` sequence in [[#Confirm the Repo Is Cloned|Confirm the Repo Is Cloned]] easier to read and re-run. Nothing reads it afterward, and it is never written to any file. You could skip setting it entirely and just `cd` to wherever you want and run `git clone ...` directly, with the same result.
- `FRACTOGENESIS_HOME` is set automatically by `.envrc` once direnv is active, purely as a human-facing "where am I right now" reference -- nothing documented in this guide consumes it. Treat it as informational output, not an input you need to set or override.

In practice: you only ever *set* `FRACTOGENESIS_PARENT` yourself, and only if cloning manually; you never set `FRACTOGENESIS_HOME` yourself, since direnv derives it from `pwd`; and you never set `$HOME` at all, since macOS does. What actually matters for every command in this guide is simply having your current working directory be the repo root -- see [[#Confirm the Repo Is Cloned|Confirm the Repo Is Cloned]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Handle Existing Reimage Environment

Reached from [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]] when `bin/check-reimage-env.sh` reports an existing `reimage.env`. This only matters if an earlier, unfinished reimage attempt already left a file behind -- most runs never reach this section.

This must be resolved before running `bin/setup-reimage-env.sh`, since that script refuses to run at all once `reimage.env` exists. A file left in place unresolved is what every later backup, evidence-capture, and restore script will resolve `REIMAGE_ARTIFACT_ROOT` from -- resolved or stale, with no error either way.

Route based on what `bin/check-reimage-env.sh` printed:

- **Values printed, and they match today's date, this Mac's hostname, and the chosen volume** -- see [[#Resuming an Existing reimage.env|Resuming an Existing reimage.env]] below.
- **Values printed, and any of them don't match** -- see [[#Archiving a Stale reimage.env|Archiving a Stale reimage.env]] below.
- **`reimage.env already exists:` printed, but no variable lines after it** -- see [[#Empty or Unrecognized reimage.env|Empty or Unrecognized reimage.env]] in Troubleshooting.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

#### Resuming an Existing reimage.env

The file's `REIMAGE_START_DATE` matches today, `ASSET_OR_HOST` matches this Mac's hostname (or you know you set a deliberate custom tag earlier today), and `EXTERNAL_DATA_VOLUME` matches the volume you just chose in [[#Choose the External Data Volume|Choose the External Data Volume]]. This `reimage.env` already reflects the effort you're on right now -- it is not stale.

Skip [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]] entirely; there's nothing to recompute or rewrite. Jump straight to [[#Confirm reimage.env Is Loaded|Confirm reimage.env Is Loaded]].

[[#Handle Existing Reimage Environment|⬆ Back to Handle Existing Reimage Environment]]

---

#### Archiving a Stale reimage.env

Archive the file if any of these are true: `REIMAGE_START_DATE` is an earlier date than today; `EXTERNAL_DATA_VOLUME` doesn't match the volume you just chose; or `ASSET_OR_HOST` doesn't match this Mac's hostname and you don't recall setting a deliberate custom tag earlier today. Left in place, a file like this would silently point every later step at the wrong artifact root, with no error to warn you. Archive it -- don't edit it in place or delete it outright, the old values may still be needed for reference:

```bash
mv reimage.env "reimage.env.stale-$(date +%Y%m%d-%H%M%S)"
```

Confirm the archived file is actually ignored by Git, not just untracked-but-visible -- a `.gitignore` from an earlier pass through this guide may only have the bare `reimage.env` line and not yet the `reimage.env.stale-*` pattern (see [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]] for the recommended entry):

```bash
git status --short | grep 'reimage.env.stale' && echo "WARNING: archived file is untracked and not ignored -- update .gitignore before committing anything" || echo "OK: archived file is ignored or already clean"
```

**Moving the file is not enough on its own.** If this repo checkout was previously `cd`ed into with direnv active, the old file's values were already loaded into shell variables, not just left sitting in the file -- and a moved/renamed file doesn't retroactively unset variables already exported into the current shell. What happens next depends on how those values got loaded:

- **direnv is active**: it re-evaluates `.envrc` on every prompt, so the very next command you run should trigger a `direnv: export ...` line unloading the old values -- watch for that, don't assume it happened.
- **direnv is not active yet**, or the values reached this shell via a manual `source reimage.env`: nothing auto-unloads them. They remain exported until you clear them or open a new terminal.

Clear and re-verify explicitly, then continue to [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]] with a genuinely clean shell:

```bash
unset REIMAGE_ARTIFACT_ROOT ASSET_OR_HOST REIMAGE_START_DATE REIMAGE_WORKSPACE_ROOT

printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "${REIMAGE_ARTIFACT_ROOT:-<unset, good>}"
```

(Deliberately not unsetting `EXTERNAL_DATA_VOLUME`/`EXTERNAL_APPLE_BACKUPS_VOLUME` here -- those are still correct from [[#Choose the External Data Volume|Choose the External Data Volume]]; only values that could have come from the *old* file need clearing.)

If that still prints an old path instead of `<unset, good>`, something is re-exporting it (a leftover `.envrc` in a parent directory, a sourced profile script, etc.) -- track that down before continuing.

If you're not sure the old effort is actually finished, check whether its `REIMAGE_ARTIFACT_ROOT` folder still exists and looks incomplete (see [[#Verify the Prepared Root|Verify the Prepared Root]] for what "complete" looks like) before archiving. If backup or evidence scripts already ran against the stale root, that generated data needs to be dealt with rather than silently abandoned.

[[#Handle Existing Reimage Environment|⬆ Back to Handle Existing Reimage Environment]]

---

### reimage.env Must Contain Resolved Values, Not Literal References

`reimage.env` should be boring: one `export NAME=value` line per setting, with actual, resolved values -- never a helper-variable reference, a template placeholder, or a literal shell-expansion string left un-evaluated.

Specifically, never store any of these in `reimage.env`:

- Helper-variable references such as `REIMAGE_START_DATE_DEFAULT` or `ASSET_OR_HOST_DEFAULT` -- these are internal names the tooling may use for its own defaulting logic, not values meant to be written into the file.
- A literal, unexpanded reference such as `$EXTERNAL_DATA_VOLUME` or `$ASSET_OR_HOST` where an actual path or value belongs -- for example `REIMAGE_ARTIFACT_ROOT=$EXTERNAL_DATA_VOLUME/reimage-...` instead of the real resolved path.
- A literal `$HOME/...` string in an optional path such as `OFFICE_WATCH` or `ONEDRIVE_ROOT` -- write the fully resolved absolute path instead (e.g. `/Users/<user>/Desktop/...`, not `$HOME/Desktop/...`).

Optional paths should either be left blank or written as absolute resolved paths -- never as an unresolved template.

Why this matters: `reimage.env` gets `source`d with `set -a`/`set +a` by multiple scripts across this guide, sometimes under `set -u` (nounset). An unresolved reference like `$ASSET_OR_HOST` sourced before that variable exists in the same shell throws an "unbound variable" error; a literal `$HOME/...` string just silently fails to expand into a real path, since `reimage.env` is sourced as data, not re-evaluated as a template each time. Both failure modes are avoided entirely by only ever writing fully resolved values into the file in the first place.

If you already have a `reimage.env` with this problem, see [[#reimage.env Contains Helper Variables or Literal Paths|reimage.env Contains Helper Variables or Literal Paths]] in Troubleshooting for symptoms and a repair command.

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

### Pasted Code Breaks in Interactive zsh

Symptoms:

```text
command not found: #
```

Cause: zsh (the default macOS shell) does not treat a trailing `#` as a comment character in interactive mode the way bash does. A line like `VALUE="..."  # some note` fails with `command not found: #` -- and worse, silently drops the assignment, because zsh parses it as a temporary variable assignment scoped only to that failed command, not a persistent shell variable. This guide avoids trailing same-line comments in its code blocks for exactly this reason; if you still hit this, you're likely pasting from a modified or partially-copied block.

If you see `command not found: #` after pasting any block in this guide, don't assume the lines around it ran cleanly -- check whether an assignment just above it actually stuck:

```bash
printf 'VAR=%s\n' "$VAR"
```

Fix: rerun the block cleanly -- retype it, or save it as a `.sh` file and run that instead of pasting -- rather than continuing with a value you haven't confirmed.

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

This means `reimage.env` contains helper-variable references or quoted literal paths instead of resolved values -- see [[#reimage.env Must Contain Resolved Values, Not Literal References|reimage.env Must Contain Resolved Values, Not Literal References]] in Supplemental Reference for what belongs in the file instead.

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

### Accidental Literal-Named Folder Under the Repo Checkout

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

Then confirm `REIMAGE_ARTIFACT_ROOT` prints as an absolute `/Volumes/...` path -- see [[#reimage.env Contains Helper Variables or Literal Paths|reimage.env Contains Helper Variables or Literal Paths]] if it still doesn't -- before rerunning [[#Create the Artifact Root|Create the Artifact Root]].

Return to: [[#Create the Artifact Root|Create the Artifact Root]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Existing reimage.env Has Stale Values From a Previous Reimage

Symptoms:

```text
bin/setup-reimage-env.sh refuses immediately with a message that reimage.env already exists, and you don't remember creating one
Backups or evidence captures appear to be landing under a REIMAGE_ARTIFACT_ROOT dated days/weeks ago, or naming a Mac you don't recognize
REIMAGE_ARTIFACT_ROOT, once loaded, points at an external volume that isn't the one currently mounted
```

This almost always means `reimage.env` was created during an earlier reimage effort on this Mac and never cleaned up. Neither direnv nor a manual `source` distinguishes an old file from a fresh one -- both load whatever is on disk, silently.

Confirm and resolve it using [[#Handle Existing Reimage Environment|Handle Existing Reimage Environment]], which walks through comparing the file's values against the current effort and archiving it if it's genuinely stale:

```bash
grep -E '^(export[[:space:]]+)?(REIMAGE_ARTIFACT_ROOT|ASSET_OR_HOST|REIMAGE_START_DATE|EXTERNAL_DATA_VOLUME)=' reimage.env
```

If backup or evidence scripts already ran before you caught this, they wrote into the *old* `REIMAGE_ARTIFACT_ROOT`, not a new one. Before archiving the stale `reimage.env`, note that old path -- you'll need it to find and deal with anything already written there, rather than losing track of it once the file is renamed out of the way.

Return to: [[#Handle Existing Reimage Environment|Handle Existing Reimage Environment]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Empty or Unrecognized reimage.env

The file exists, but `bin/check-reimage-env.sh` found none of the expected variables -- usually because an earlier run was interrupted before writing anything, or the file predates this guide's current variable names.

Inspect it directly before deciding anything:

```bash
cat reimage.env
```

If it's genuinely empty or clearly unusable, treat it exactly like [[#Archiving a Stale reimage.env|Archiving a Stale reimage.env]] and continue from there. If it has content under different/older variable names, same treatment -- archive it rather than trying to reconcile the old names by hand.

Return to: [[#Handle Existing Reimage Environment|Handle Existing Reimage Environment]]

[[#Table of Contents|⬆ Back to Table of Contents]]

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
./bin/backup-home-files-backup.sh --dry-run --onedrive-only
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

Use this only for a temporary shell session when you intentionally do not want to create `reimage.env`. The normal workflow is still [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]].

```bash
export REIMAGE_WORKSPACE_ROOT="$HOME/Documents/reimage-workspace"
export EXTERNAL_DATA_VOLUME="/Volumes/<external-data-volume-name>"
export EXTERNAL_APPLE_BACKUPS_VOLUME="/Volumes/<time-machine-volume-name>"
export ASSET_OR_HOST="<asset-or-host>"
export REIMAGE_START_DATE="$(date +%Y%m%d)"
export REIMAGE_ARTIFACT_ROOT="$EXTERNAL_DATA_VOLUME/reimage-$ASSET_OR_HOST-$REIMAGE_START_DATE-open"
```

Optional -- leave these blank unless these workflows are used:

```bash
export OFFICE_WATCH=""
export ONEDRIVE_FOLDER_NAME=""
export ONEDRIVE_ROOT=""
export ONEDRIVE_DEST_SUBDIR="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"
```

For repeatable reimage work, write those values to `reimage.env` instead of relying on terminal history.

Return to: [[#Create Local Reimage Environment Profile|Create Local Reimage Environment Profile]]

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
