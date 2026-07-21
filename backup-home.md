---
title: Backup Home
back_link: "reimaging-guide#Phase 2B — Backup Home"
runbook_version: 0.1.0
verb_first: true
primary_scripts:
  - bin/backup-home.sh
  - bin/capture-size-audit.sh
  - bin/verify-artifact-config.sh
related_scripts: []
artifact_paths:
  - $REIMAGE_ARTIFACT_ROOT/home-files-backup/
  - $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/java-security/
author: dkittrell
last_updated: 2026-07-21
---
[[reimaging-guide#Phase 2B — Backup Home|← Back to Mac Reimaging Guide]]

# Backup Home

This runbook copies the home-directory files, dotfiles, and secret-bearing targets that a reimage would otherwise erase into `$REIMAGE_ARTIFACT_ROOT`, driven by `bin/backup-home.sh`. The external artifact root is the authoritative copy; an optional OneDrive secondary copy carries only the work-safe subset.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#The Two Destinations|The Two Destinations]]
    - [[#Terminology|Terminology]]
    - [[#Configuration Fragments and Run Modes|Configuration Fragments and Run Modes]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Load the Shared Reimage Environment|Load the Shared Reimage Environment]]
    - [[#Confirm the Artifact-Config Fragments|Confirm the Artifact-Config Fragments]]
    - [[#Run the Size Audit First|Run the Size Audit First]]
    - [[#Choose the Backup Mode|Choose the Backup Mode]]
    - [[#Run the Backup|Run the Backup]]
    - [[#Review Output|Review Output]]
    - [[#Confirm the OneDrive Sync|Confirm the OneDrive Sync]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Copy home-directory files and secret-bearing targets into `$REIMAGE_ARTIFACT_ROOT` before the Mac is erased, so a reviewed set of local configuration can be restored afterward. This phase can be rerun independently whenever the copy needs refreshing.

This runbook owns:

```text
home-directory targets selected by external-targets.conf.sh
dotfiles selected by external-dotfiles.conf.sh
secrets-encrypted targets selected by secrets-targets.conf.sh and secret-flags.conf.sh
Java jssecacerts collected directly by backup-home.sh
optional OneDrive secondary copy of approved work-safe targets from onedrive-targets.conf.sh
```

It does not own:

```text
automated workflow snapshot capture — capture-workflow-snapshot.md
app-specific backup work, including Docker settings/contexts/inventories — backup-apps.md
developer-tool version inventory — capture-system-inventory.md
cloud sync and final manual sign-off during Phase 4B — reimage-prep-checks.md
OneDrive root configuration and folder creation — prepare-artifact-root.md
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything; the steps assume it. The flow carries the local files a reimage would erase — home-directory content, shell dotfiles, and credential-shaped material — onto the external artifact drive, keeping the credential-shaped material staged apart so it never syncs to the cloud in the clear. A single entrypoint, `bin/backup-home.sh`, does this; a run mode decides which destinations it writes to.

The size audit and the fragment check run before any copy for one reason: they catch a full or unmounted drive, or a missing config fragment, while it is cheap to fix — before a long copy commits to the wrong scope.

### The Two Destinations

The backup has one authoritative destination and one optional secondary destination. The difference is a safety boundary, not a convenience.

| Destination | What it receives | Status |
|---|---|---|
| External artifact root (`$REIMAGE_ARTIFACT_ROOT`) | The full selected set: home targets, dotfiles, and the secrets-encrypted staging (including Java `jssecacerts`). | Authoritative — the copy the restore phases trust. |
| OneDrive secondary (`$ONEDRIVE_ROOT/$ONEDRIVE_DEST_SUBDIR`) | Only the narrower, work-safe targets from `onedrive-targets.conf.sh`. | Secondary and optional — not proven until the Phase 4B checks confirm the upload. |

> [!note]
> The secrets-encrypted targets never travel to OneDrive. Only the external artifact root holds them, and only the encrypted DMG (built later) is intended to leave the drive. The OneDrive copy is a convenience mirror of work-safe documents, not a secrets backup.

### Terminology

| Term | Meaning |
|---|---|
| External artifact root | `$REIMAGE_ARTIFACT_ROOT` on the external drive — the authoritative backup destination. |
| Secrets-encrypted target | A credential-shaped source (ssh, gnupg, `docker/config.json`, Java `jssecacerts`, and others) routed into `secrets-encrypted/`, not into `home-files-backup/`. |
| Work-safe target | A non-sensitive target approved for the optional OneDrive copy, listed in `onedrive-targets.conf.sh`. |
| Secondary copy | The optional OneDrive mirror of work-safe targets. It supplements the external root; it never replaces it. |

### Configuration Fragments and Run Modes

The artifact-config fragments (sourced from the active `ARTIFACT_CONFIG_DIR`) are the single definition of what is backed up, what is excluded, what routes to secrets, and how OneDrive behaves. Their names and roles are the reference table in [[#Confirm the Artifact-Config Fragments|Confirm the Artifact-Config Fragments]].

The mode flag on `bin/backup-home.sh` decides which destinations a run touches:

| Mode | Command | Writes to |
|---|---|---|
| External only (preferred) | `./bin/backup-home.sh --external-only` | External artifact root only. |
| External plus OneDrive (default) | `./bin/backup-home.sh` | External artifact root, then the OneDrive secondary of work-safe targets. |
| OneDrive only | `./bin/backup-home.sh --onedrive-only` | OneDrive secondary only — refreshes it after the external copy already ran. |
| Dry run | add `--dry-run` to any mode above | Nothing; previews the copy the chosen scope would make. |

External-only is the preferred first run because it fills the authoritative destination without waiting on cloud sync. The SSH target is copied with socket-skipping options so live agent sockets are left behind; the mechanics are in [[#SSH Agent Socket Exclusion in Detail|SSH Agent Socket Exclusion in Detail]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary scripts (alphabetical):

```text
$FRACTOGENESIS_HOME/bin/backup-home.sh              # entrypoint
$FRACTOGENESIS_HOME/bin/capture-size-audit.sh       # entrypoint
$FRACTOGENESIS_HOME/bin/verify-artifact-config.sh   # entrypoint
```

Subdirectories under `$REIMAGE_ARTIFACT_ROOT` this runbook's steps touch:

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── home-files-backup/
│   ├── dotfiles/
│   │   ├── ...
│   │   ├── .bash_profile
│   │   ├── .bashrc
│   │   ├── .shell_common.sh
│   │   ├── .shell_local.sh
│   │   ├── .zprofile
│   │   ├── .zshrc
│   │   └── ...
│   └── MANIFEST.md
├── secrets-encrypted/
│   └── certs/java-security/       # Java jssecacerts, staged for create-secrets-dmg.sh
└── ...
```

The dotfiles shown are representative; the authoritative list is `external-dotfiles.conf.sh`.

The complete `home-files-backup/` layout (including the `home/` subtree) is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

Secret-bearing targets routed to `secrets-encrypted/` (not reproduced here):

```text
ssh
gnupg
docker/config.json
chrome
postman
raycast
```

Owned by `secrets-targets.conf.sh` and `secret-flags.conf.sh` — see [[#Confirm the Artifact-Config Fragments|Confirm the Artifact-Config Fragments]].

Optional OneDrive secondary copy:

```text
$ONEDRIVE_ROOT/$ONEDRIVE_DEST_SUBDIR/
```

Docker settings land under `app-settings-backup/docker/` via `backup-apps.md` (Phase 2C); the developer-tool version inventory lands under `system-inventory/` via `capture-system-inventory.md` (Phase 3B). Neither is written by this runbook.

### Environment Variables

These `reimage.env` values drive this runbook. `REIMAGE_ARTIFACT_ROOT` and the OneDrive values are resolved and written during `prepare-artifact-root.md`; secret toggles live in the artifact-config fragments.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | The external artifact root — authoritative backup destination. |
| `FRACTOGENESIS_HOME` | The toolkit checkout that holds the scripts and this runbook. |
| `ARTIFACT_CONFIG_DIR` | Active directory the artifact-config fragments are sourced from. |
| `ONEDRIVE_FOLDER_NAME` | The CloudStorage OneDrive folder name; feeds `ONEDRIVE_ROOT`. |
| `ONEDRIVE_ROOT` | `$HOME/Library/CloudStorage/$ONEDRIVE_FOLDER_NAME` — the OneDrive account root. |
| `ONEDRIVE_DEST_SUBDIR` | The per-reimage OneDrive subfolder — the basename of `$REIMAGE_ARTIFACT_ROOT`. |
| `BACKUP_*` (secret flags) | Per-target secret toggles from `secret-flags.conf.sh` (e.g. `BACKUP_JAVA_JSSECACERTS`). |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight. Confirm you are set up, then confirm what you intend this run to do. The conceptual background is in [[#How the Workflow Works|How the Workflow Works]]; this is the checklist.

### Prerequisites

- The external artifact volume is mounted and `$REIMAGE_ARTIFACT_ROOT` resolves (not empty, and the directory exists).
- `reimage.env` holds resolved absolute values, produced by `prepare-artifact-root.md`.
- If you will use OneDrive, `ONEDRIVE_FOLDER_NAME` and `ONEDRIVE_ROOT` are already configured and the OneDrive folder was created during `prepare-artifact-root.md`.
- `bash` and `rsync` are available.

> [!bug] Troubleshooting
> If `REIMAGE_ARTIFACT_ROOT` resolves empty, either fix `reimage.env` or pass `--artifact-root PATH` explicitly on every command below.

### Confirm Your Intent

- Which mode you want: external-only (preferred first run), external plus OneDrive (default), or OneDrive-only (refresh an existing copy).
- Whether this run should touch OneDrive at all. If not, use `--external-only`.
- Whether to preview first with `--dry-run` before copying.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The first three are shared setup; you then choose the backup mode, and the final OneDrive check applies only if you ran a OneDrive mode.

### Load the Shared Reimage Environment

`backup-home.sh` and `capture-size-audit.sh` self-locate and load shared config through `.internal/load-reimage-config.sh` automatically — you do not source `reimage.env` by hand. `verify-artifact-config.sh` resolves the fragment directory on its own and does not load the shared config, so a broken fragment gets reported instead of aborting the load.

Confirm the scripts parse:

```bash
cd "$FRACTOGENESIS_HOME"
bash -n bin/backup-home.sh
bash -n bin/capture-size-audit.sh
```

Confirm the artifact root that will be used:

```bash
./bin/backup-home.sh --dry-run --external-only 2>&1 | head -5
```

### Confirm the Artifact-Config Fragments

The fragments are the entire definition of what gets backed up, what is excluded, what routes to secrets, and how OneDrive behaves. Confirm they are present and parse before the backup runs:

```bash
./bin/verify-artifact-config.sh
```

The fragments it verifies, and what each defines:

| Fragment | Defines |
|---|---|
| `expected-artifact-folders.conf.sh` | Expected top-level `$REIMAGE_ARTIFACT_ROOT` folders used by the size audit and validation. |
| `external-dotfiles.conf.sh` | Individual home-directory dotfiles copied when present. |
| `external-excludes.conf.sh` | Global rsync excludes applied to every external sync. |
| `external-targets.conf.sh` | Home-directory targets copied under `home-files-backup/`. |
| `onedrive-extra-excludes.conf.sh` | Extra excludes applied only to OneDrive syncs. |
| `onedrive-targets.conf.sh` | The narrower, document-only OneDrive sync target list. |
| `secret-flags.conf.sh` | Optional secret backup toggles (SSH, GPG, Docker, Postman, Raycast, Java `jssecacerts`). |
| `secrets-targets.conf.sh` | Sensitive targets routed to `secrets-encrypted/` instead of `home-files-backup/`. |
| `skip-entries.conf.sh` | Intentionally skipped paths and the reason each is skipped. |

To change what gets backed up, excluded, or routed to secrets, edit these fragments — see [[#Customizing the Artifact-Config Fragments|Customizing the Artifact-Config Fragments]].

> [!warning] Pitfall
> A missing fragment means the backup runs with different scope than you expect. Resolve every missing fragment before continuing.

### Run the Size Audit First

Run the size audit before copying, so a full or unmounted drive is caught early. Use the **`backup-home`** context label so this capture is distinguishable from other same-day audits in the manifest:

```bash
./bin/capture-size-audit.sh --context pre-image-backup-home
```

Review these lines in the output:

- `Estimated external backup size`
- `Target backup root`
- `Target local-files destination`
- `Available on <drive>`
- `✓ External drive: enough space` or `✗ External drive: NOT ENOUGH SPACE`
- `Planned OneDrive sync size`, `Target OneDrive destination`, `Available on OneDrive local volume` — when OneDrive applies

> [!note]
> `--local-only` shows the local target inventory only; it skips *both* the OneDrive and the external-drive-capacity sections. Reach for it for a quick size estimate when the external drive is not mounted yet — not when you need the external fit check, which that flag hides. OneDrive cloud quota always needs manual confirmation.

> [!bug] Troubleshooting
> The saved report keeps ANSI color codes on purpose; view it in a terminal, not an editor: `less -R "$REIMAGE_ARTIFACT_ROOT/size-audit-reports/runs/<run>/size-audit-report.txt"`.

### Choose the Backup Mode

Pick the mode intentionally — the full mode table is in [[#Configuration Fragments and Run Modes|Configuration Fragments and Run Modes]]. External-only fills the authoritative destination first; the default adds the OneDrive secondary; OneDrive-only refreshes just the secondary. Preview with `--dry-run` when unsure.

> [!warning] Pitfall
> Any mode that includes OneDrive still leaves the OneDrive copy unproven until [[#Confirm the OneDrive Sync|Confirm the OneDrive Sync]]. Writing to the local OneDrive folder is not the same as OneDrive uploading it.

### Run the Backup

Run the mode you chose.

External-drive-only run:

```bash
./bin/backup-home.sh --external-only
```

External drive plus OneDrive run:

```bash
./bin/backup-home.sh
```

OneDrive-only rerun:

```bash
./bin/backup-home.sh --onedrive-only
```

Override the artifact root for a one-off run instead of editing `reimage.env`:

```bash
./bin/backup-home.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --external-only
```

### Review Output

Review the external-drive manifest before final validation:

```bash
open "$REIMAGE_ARTIFACT_ROOT/home-files-backup"
```

```bash
find "$REIMAGE_ARTIFACT_ROOT/home-files-backup" -maxdepth 3 -type f | sort | head -100
```

> [!warning] Pitfall
> Do not use this output as a bulk restore source without review. Some dotfiles and local configs may be obsolete or unsafe to copy directly onto the post-image system.

### Confirm the OneDrive Sync

This step applies only when `backup-home.sh` ran with OneDrive enabled (the default mode, or `--onedrive-only`). The local folder check proves the files were *written* to the local OneDrive-synced folder; it does not prove OneDrive *uploaded* them.

Drop a current-run marker so a later check (including the Phase 4B script) can confirm this specific run's copy:

```bash
ARTIFACT_BASENAME="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"
ONEDRIVE_DEST="$ONEDRIVE_ROOT/$ARTIFACT_BASENAME"
MARKER="$ONEDRIVE_DEST/onedrive-upload-marker-$(date +%Y%m%d-%H%M%S).txt"

mkdir -p "$ONEDRIVE_DEST"
{
  echo "OneDrive upload marker"
  echo "REIMAGE_ARTIFACT_ROOT=$REIMAGE_ARTIFACT_ROOT"
  echo "ONEDRIVE_DEST=$ONEDRIVE_DEST"
  date
} > "$MARKER"
```

Spot-check what landed and when:

```bash
du -sh "$ONEDRIVE_DEST" 2>/dev/null || true
find "$ONEDRIVE_DEST" -type f -print0 2>/dev/null \
  | xargs -0 stat -f '%Sm %N' -t '%Y-%m-%d %H:%M:%S' 2>/dev/null | sort | tail -25
```

Treat the OneDrive copy as confirmed only when all of these are true:

- OneDrive menu bar icon shows fully synced, with no pending uploads or errors
- the expected folder (`$ONEDRIVE_DEST_SUBDIR`) is visible in OneDrive web
- the current-run `onedrive-upload-marker-YYYYMMDD-HHMMSS.txt` file is visible in OneDrive web
- at least one recently changed file opens or previews correctly from OneDrive web
- the OneDrive cloud quota has room for the planned sync size

> [!bug] Troubleshooting
> If a run wrote to a relative `OneDrive-…/` folder inside the repo checkout instead of the real CloudStorage-mounted folder, that folder is not syncing. See [[#Accidental Relative OneDrive Folder|Accidental Relative OneDrive Folder]].

The single pass/fail checkbox for OneDrive sync in the Phase 4B sign-off lives in `reimage-prep-checks.md` — come back here if that checkbox needs troubleshooting.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The scripts copy and inventory; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Whether a dotfile or local config is safe to restore later | Some are obsolete or machine-specific and should not be copied back blindly. |
| Whether a flagged file is truly a secret | Content review, not filename, decides what must stay in `secrets-encrypted/`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### Accidental Relative OneDrive Folder

If an older or misconfigured run wrote to a bare-name `OneDrive-…/` folder inside the repo checkout instead of the real CloudStorage-mounted OneDrive folder, that folder is not syncing to OneDrive at all. The usual cause is a `reimage.env` value like:

```bash
ONEDRIVE_ROOT="<OneDrive-folder-name>"
```

A bare folder name is interpreted relative to the working directory. The correct root is the full CloudStorage path, built from the folder name:

```bash
ONEDRIVE_FOLDER_NAME="<OneDrive-folder-name>"
export ONEDRIVE_ROOT="$HOME/Library/CloudStorage/$ONEDRIVE_FOLDER_NAME"
export ONEDRIVE_DEST_SUBDIR="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"
```

`backup-home.sh` now refuses to write under the repo checkout and errors instead. To recover: move any stray contents into the real OneDrive root, quarantine the stray folder until the move shows in OneDrive web, then correct `reimage.env` (via `prepare-artifact-root.md`) before rerunning.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

### Customizing the Artifact-Config Fragments

The fragments are ordinary Bash files: an array (or, for `secret-flags.conf.sh`, a set of variables) with one commented format line at the top. Edit the *active* copy — the directory `verify-artifact-config.sh` reports — which is a workspace copy under `$REIMAGE_WORKSPACE_ROOT/artifact-config` when present, otherwise the committed templates in `.internal/templates/artifact-config`. After any edit, re-run `./bin/verify-artifact-config.sh` and a `--dry-run` before copying.

**`external-targets.conf.sh`** — directories copied into `home-files-backup/`. Pipe-delimited: `LABEL | SOURCE | DEST | CATEGORY | DESCRIPTION`. A trailing slash on `SOURCE` copies the directory's *contents*; no slash copies the directory itself. Comment a line out to drop that target; copy a line and repoint `SOURCE` to add one.

**`external-dotfiles.conf.sh`** — individual `~/` dotfiles. `FILENAME | CATEGORY | DESCRIPTION`; missing files are skipped silently. A dotfile marked `CATEGORY = secrets` is *not* copied here — it is expected in `secrets-targets.conf.sh` instead, so it lands encrypted rather than in the clear. Keep credential-shaped dotfiles out of this list unless their category is `secrets`.

**`external-excludes.conf.sh`** — rsync filter patterns applied to *every* external sync. Add a pattern here rather than editing a script, to drop noise (caches, installers, `.DS_Store`) from otherwise-wanted targets.

**`secrets-targets.conf.sh`** — credential-shaped sources copied to `secrets-encrypted/` for the later DMG. `KEY | SOURCE | DEST | DESCRIPTION`, with `DEST` relative to `secrets-encrypted/`. Each `KEY` is gated by a `BACKUP_<KEY>` flag. Add a secret by giving it a `KEY` and a `secrets-encrypted/`-relative `DEST`; never route a secret through `external-targets.conf.sh`.

**`secret-flags.conf.sh`** — `BACKUP_<KEY>=true|false` toggles for the secrets targets (and Java `jssecacerts`). An unset flag defaults to `true`; set one to `false` to skip a secret this run, e.g. `BACKUP_GNUPG=false`.

**`onedrive-targets.conf.sh`** — the work-safe subset mirrored to OneDrive. Same format as `external-targets.conf.sh`, `DEST` relative to the OneDrive destination. Keep it narrow — documents only, never dotfiles or secrets. Comment lines in or out to widen or narrow the mirror.

**`onedrive-extra-excludes.conf.sh`** — excludes applied to OneDrive syncs *in addition to* `external-excludes.conf.sh`. This is the guardrail that keeps sensitive file types (`*.pem`, `*.key`, `.netrc`, `*.env`, …) and personal folders off corporate cloud even if a broad target would sweep them in. When in doubt, extend it rather than trim it.

**`skip-entries.conf.sh`** — `PATH | REASON`, informational only. It does *not* cause anything to be skipped; it documents intentional omissions so the size audit can explain them. To actually exclude something, add a pattern to `external-excludes.conf.sh` or leave it out of the targets — then, optionally, record why here.

**`expected-artifact-folders.conf.sh`** — the top-level folder names expected under `$REIMAGE_ARTIFACT_ROOT`, checked by the size audit and the Phase 4B checklist. This tracks the standard artifact-root layout from `prepare-artifact-root.md`; change it only when that layout changes, and keep it alphabetized.

### SSH Agent Socket Exclusion in Detail

`backup-home.sh` copies the `ssh` `SECRETS_TARGETS` directory (`~/.ssh/`) with `rsync -a --no-specials --no-devices --exclude="random_seed"`, not a plain `rsync -a`.

This matters because `~/.ssh/agent/` can contain live SSH agent Unix domain sockets, for example:

```text
~/.ssh/agent/s.<agent-id>.agent.<token>
```

These are runtime-only control sockets created by the running SSH agent process. They are not restorable secrets — a copied socket file cannot be reconnected to an agent after a reimage. Copying them with a socket-preserving rsync also fails outright (`rsync: mkstempsock: Invalid argument`, rsync exit `23`), which is what originally broke this step.

`--no-specials --no-devices` tells rsync to skip sockets, FIFOs, and device files instead of trying to recreate them. Regular SSH key material (`id_ed25519`, `id_rsa`, `known_hosts`, `config`, etc.) under `~/.ssh/` is unaffected and still copies normally. A new SSH agent creates fresh sockets on its own, so there is nothing to restore here.

[[#Table of Contents|⬆ Back to Table of Contents]]

---
