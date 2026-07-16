[[reimaging-guide#Phase 2B — Backup Home|← Back to Mac Reimaging Guide]]

# Backup Home

Use this phase to copy home-directory files and secrets-encrypted targets into `$REIMAGE_ARTIFACT_ROOT` before the Mac is erased. This guide covers the plain-file and secrets-encrypted backup produced by `bin/backup-home.sh`, including selected home-directory targets, dotfiles, and secrets-encrypted targets (ssh, gnupg, docker/config.json, Java `jssecacerts`, and other secret staging), plus an optional OneDrive secondary copy of approved work-safe targets. It does not cover automated workflow snapshot capture, app-specific backup work (including Docker settings — see `backup-apps.md`), developer-tool version inventory (see `capture-system-inventory.md`), or Phase 4 cloud sync sign-off.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Related Guides|Related Guides]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Load the Shared Reimage Environment|Load the Shared Reimage Environment]]
    - [[#Confirm Artifact-Config Fragments|Confirm Artifact-Config Fragments]]
    - [[#Run the Size Audit First|Run the Size Audit First]]
    - [[#SSH Agent Sockets Are Intentionally Excluded|SSH Agent Sockets Are Intentionally Excluded]]
    - [[#Run the Backup|Run the Backup]]
    - [[#Review Output|Review Output]]
        - [[#Confirm OneDrive Sync|Confirm OneDrive Sync]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

Use this phase to copy home-directory files and secrets-encrypted targets into `$REIMAGE_ARTIFACT_ROOT` before the Mac is erased.

This phase owns:

```text
home-directory targets selected by external-targets.conf.sh
dotfiles selected by external-dotfiles.conf.sh
secrets-encrypted targets selected by secrets-targets.conf.sh and secret-flags.conf.sh
Java jssecacerts collected directly by backup-home.sh
optional OneDrive secondary copy of approved work-safe targets from onedrive-targets.conf.sh
```

This guide does **not** own:

```text
automated workflow snapshot capture in capture-workflow-snapshot.md
app-specific backup work, including Docker settings/contexts/inventories, in backup-apps.md
developer-tool version inventory in capture-system-inventory.md
cloud sync and final manual sign-off during Phase 4 in reimage-prep-checks.md
```

This phase can be rerun independently when the home-directory and secrets copy needs to be refreshed.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Primary scripts:

```text
$FRACTOGENESIS_HOME/bin/backup-home.sh
$FRACTOGENESIS_HOME/bin/capture-size-audit.sh
```

Subdirectories under `$REIMAGE_ARTIFACT_ROOT` touched by this runbook's steps:

```text
$REIMAGE_ARTIFACT_ROOT/
├── home-files-backup/
│   ├── dotfiles/
│   │   ├── .zshrc
│   │   ├── .zprofile
│   │   ├── .bashrc
│   │   ├── .bash_profile
│   │   ├── .shell_common.sh
│   │   └── .shell_local.sh
│   └── MANIFEST.md
└── secrets-encrypted/
    └── certs/java-security/       # Java jssecacerts, staged for create-secrets-dmg.sh
```

Docker settings land under `app-settings-backup/docker/` via `backup-apps.md` (Phase 2C); developer-tool version inventory lands under `system-inventory/` via `capture-system-inventory.md` (Phase 3B) — neither is written by this runbook.

The full `secrets-encrypted/` target list (ssh, gnupg, docker/config.json, Chrome, Postman, Raycast) is owned by `secrets-targets.conf.sh` and `secret-flags.conf.sh`, not reproduced here — see [[#Confirm Artifact-Config Fragments|Confirm Artifact-Config Fragments]].

Optional OneDrive secondary copy:

```text
$ONEDRIVE_ROOT/<basename-of-$REIMAGE_ARTIFACT_ROOT>/
```

The OneDrive copy is only a secondary destination for approved work-safe targets. It is not considered complete until the Phase 4 manual OneDrive checks in `reimage-prep-checks.md` are finished.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

Review the workflow boundaries below, then proceed through the sequential steps in order.

### Related Guides

- use this guide for `backup-home.sh`
- use `capture-workflow-snapshot.md` for the automated workflow snapshot capture
- use `backup-apps.md` for app-specific backup work, including Docker settings/contexts/inventories
- use `capture-system-inventory.md` for developer-tool version inventory
- use `reimage-prep-checks.md` during Phase 4 for cloud sync and final manual sign-off

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Use this order for the runnable backup flow.

### Load the Shared Reimage Environment

`backup-home.sh` and `capture-size-audit.sh` self-locate and load shared config through `.internal/load-reimage-config.sh` automatically — you do not need to source `reimage.env` by hand before running them. Confirm it resolves correctly first:

```bash
cd "$FRACTOGENESIS_HOME"
bash -n bin/backup-home.sh
bash -n bin/capture-size-audit.sh
```

Confirm the artifact root that will be used:

```bash
./bin/backup-home.sh --dry-run --external-only 2>&1 | head -5
```

If `REIMAGE_ARTIFACT_ROOT` is empty, either fix `reimage.env` or pass `--artifact-root PATH` explicitly on every command below.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Confirm Artifact-Config Fragments

Before running the external-only home backup, confirm the artifact-config fragments are present and reviewed. These fragments define the backup scope, exclusions, secret routing, OneDrive behavior, and expected artifact-root structure used by the local files backup and related validation scripts.

Key fragments (under the active `ARTIFACT_CONFIG_DIR`):

- `expected-artifact-folders.conf.sh` — expected top-level `$REIMAGE_ARTIFACT_ROOT` folders used by size-audit and preparation validation.
- `external-targets.conf.sh` — external-drive backup targets copied under `$REIMAGE_ARTIFACT_ROOT/home-files-backup/`.
- `external-dotfiles.conf.sh` — individual home-directory dotfiles copied when present.
- `external-excludes.conf.sh` — global rsync excludes applied to every external sync.
- `secrets-targets.conf.sh` — sensitive targets routed to `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/`, not `home-files-backup/`.
- `secret-flags.conf.sh` — optional secret backup toggles such as SSH, GPG, Docker, Postman, Raycast, and Java `jssecacerts`.
- `onedrive-targets.conf.sh` — narrower document-only OneDrive sync target list.
- `onedrive-extra-excludes.conf.sh` — extra excludes used only for OneDrive syncs.
- `skip-entries.conf.sh` — intentionally skipped paths and the reason each is skipped.

Run this check from the repo root:

```bash
cd "$FRACTOGENESIS_HOME"

echo "Checking artifact-config fragment references:"
grep -RInE \
  'expected-artifact-folders|external-dotfiles|external-excludes|external-targets|onedrive-extra-excludes|onedrive-targets|secret-flags|secrets-targets|skip-entries' \
  bin .internal *.md 2>/dev/null || true

echo
echo "Checking fragment syntax:"
for f in \
  expected-artifact-folders.conf.sh \
  external-dotfiles.conf.sh \
  external-excludes.conf.sh \
  external-targets.conf.sh \
  onedrive-extra-excludes.conf.sh \
  onedrive-targets.conf.sh \
  secret-flags.conf.sh \
  secrets-targets.conf.sh \
  skip-entries.conf.sh
do
  found=$(find .internal -name "$f" -type f | head -1)
  if [[ -z "$found" ]]; then
    echo "MISSING: $f"
  else
    bash -n "$found" && echo "OK: $found"
  fi
done
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Run the Size Audit First

Run `capture-size-audit.sh` before copying home-directory files when you want to confirm both:

- the estimated size of the home-directory files selected by the artifact-config fragments
- the available space on the external drive and, when used, the local OneDrive volume

Recommended preflight:

```bash
./bin/capture-size-audit.sh
```

Review these lines in the output:

- `Estimated external backup size`
- `Target backup root`
- `Target home-files-backup destination`
- `Planned OneDrive sync size`, when OneDrive applies
- `Target OneDrive destination`, when OneDrive applies
- `Available on <drive>`
- `Available on OneDrive local volume`, when OneDrive applies
- `✓ ... enough space` or `✗ ... NOT ENOUGH SPACE` in the fit check section

If you are only preparing the external backup and do not care about OneDrive for this run, use `--local-only` and ignore the OneDrive-specific lines. OneDrive cloud quota still needs manual confirmation when applicable.

[[#Table of Contents|⬆ Back to Table of Contents]]

### SSH Agent Sockets Are Intentionally Excluded

`backup-home.sh` copies the `ssh` `SECRETS_TARGETS` directory (`~/.ssh/`) with `rsync -a --no-specials --no-devices --exclude="random_seed"`, not a plain `rsync -a`.

This matters because `~/.ssh/agent/` can contain live SSH agent Unix domain sockets, for example:

```text
~/.ssh/agent/s.<agent-id>.agent.<token>
```

These are runtime-only control sockets created by the running SSH agent process. They are not restorable secrets — a copied socket file cannot be reconnected to an agent process after a reimage. Attempting to copy them with a socket-preserving rsync also fails outright (`rsync: mkstempsock: Invalid argument`, rsync exit `23`), which is what originally broke this step.

`--no-specials --no-devices` tells rsync to skip sockets, FIFOs, and device files instead of trying to recreate them at the destination. Regular SSH key material (`id_ed25519`, `id_rsa`, `known_hosts`, `config`, etc.) under `~/.ssh/` is unaffected and still copies normally.

Nothing to restore here after reimage — a new SSH agent will create fresh sockets on its own.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Run the Backup

Choose the mode intentionally:

| Mode | Command | Use when |
|---|---|---|
| External drive only | `./bin/backup-home.sh --external-only` | You only want `$REIMAGE_ARTIFACT_ROOT` updated. |
| External drive plus OneDrive | `./bin/backup-home.sh` | You want the external backup and a secondary OneDrive copy of approved work-safe targets. |
| OneDrive only | `./bin/backup-home.sh --onedrive-only` | You already ran the external backup and only need to refresh the OneDrive copy. |
| Dry run, external only | `./bin/backup-home.sh --dry-run --external-only` | You want to preview the external copy. |
| Dry run, OneDrive only | `./bin/backup-home.sh --dry-run --onedrive-only` | You want to preview the OneDrive copy. |

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

`ONEDRIVE_DEST_SUBDIR` should normally match the basename of `$REIMAGE_ARTIFACT_ROOT` so the OneDrive copy uses the same directory name as the external artifact root.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Review Output

Review the generated external-drive manifest before final validation:

```bash
open "$REIMAGE_ARTIFACT_ROOT/home-files-backup"
find "$REIMAGE_ARTIFACT_ROOT/home-files-backup" -maxdepth 3 -type f | sort | head -100
```

Review the OneDrive copy only after OneDrive finishes syncing:

```bash
ARTIFACT_BASENAME="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"
EXPECTED_ONEDRIVE_ROOT="${ONEDRIVE_ROOT:-$HOME/Library/CloudStorage/OneDrive-AcmeGroup}"
find "$EXPECTED_ONEDRIVE_ROOT" -maxdepth 1 -type d -name "$ARTIFACT_BASENAME" -print -exec open {} \; 2>/dev/null || true
```

Do not use either output as a bulk restore source without review. Some dotfiles and local configs may be obsolete or unsafe to copy directly onto the post-image system.

[[#Table of Contents|⬆ Back to Table of Contents]]

#### Confirm OneDrive Sync

Use this whenever `backup-home.sh` ran with OneDrive enabled (the default mode, or `--onedrive-only`). The local folder/file-count check above only proves the files were written to the local OneDrive-synced folder — it does not prove OneDrive has actually uploaded them to the cloud.

Identify the expected OneDrive target:

```bash
ARTIFACT_BASENAME="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"
printf 'Expected OneDrive folder basename: %s\n' "$ARTIFACT_BASENAME"

find "$HOME/Library/CloudStorage" -maxdepth 1 -type d -name 'OneDrive*' -print 2>/dev/null | sort
```

`ONEDRIVE_DEST_SUBDIR` should match `$ARTIFACT_BASENAME`; if it doesn't, the OneDrive copy landed under a different folder name than expected.

After the OneDrive copy finishes, drop a current-run marker so a later check (including the automated Phase 4 script) can confirm this specific run's copy, not just an old one:

```bash
EXPECTED_ONEDRIVE_ROOT="${ONEDRIVE_ROOT:-$HOME/Library/CloudStorage/OneDrive-AcmeGroup}"
ONEDRIVE_DEST="$EXPECTED_ONEDRIVE_ROOT/$ARTIFACT_BASENAME"
MARKER="$ONEDRIVE_DEST/onedrive-upload-marker-$(date +%Y%m%d-%H%M%S).txt"

mkdir -p "$ONEDRIVE_DEST"
{
  echo "OneDrive upload marker"
  echo "REIMAGE_ARTIFACT_ROOT=$REIMAGE_ARTIFACT_ROOT"
  echo "ONEDRIVE_DEST=$ONEDRIVE_DEST"
  date
} > "$MARKER"
```

Then spot-check what actually landed and when:

```bash
du -sh "$ONEDRIVE_DEST" 2>/dev/null || true
find "$ONEDRIVE_DEST" -type f -print0 2>/dev/null \
  | xargs -0 stat -f '%Sm %N' -t '%Y-%m-%d %H:%M:%S' 2>/dev/null | sort | tail -25
```

Treat the OneDrive copy as confirmed only when all of these are true:

- OneDrive menu bar icon shows fully synced, with no pending uploads or errors
- the expected folder (`$ARTIFACT_BASENAME`) is visible in OneDrive web
- the current-run `onedrive-upload-marker-YYYYMMDD-HHMMSS.txt` file is visible in OneDrive web
- at least one recently changed file opens or previews correctly from OneDrive web

**Accidental relative OneDrive folder.** If an older or misconfigured run wrote to `$FRACTOGENESIS_HOME/OneDrive-AcmeGroup/` instead of the real CloudStorage-mounted OneDrive folder (usually because `ONEDRIVE_ROOT` was unset or relative when the script ran), that folder is not actually syncing to OneDrive at all — `backup-home.sh` now actively refuses to write under the repo checkout and will error instead. Move any pre-existing stray contents into the real OneDrive root and quarantine the stray folder until the move is confirmed in OneDrive web, then correct `ONEDRIVE_ROOT` in `reimage.env` before rerunning.

This home-files-backup check is the detailed sync-confirmation procedure. The single pass/fail checkbox for OneDrive sync in the Phase 4 sign-off still lives in `reimage-prep-checks.md` — come back here if that checkbox needs troubleshooting.

[[#Table of Contents|⬆ Back to Table of Contents]]

---
