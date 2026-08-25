[[reimaging-guide#Phase 2B — Backup Home|← Back to Mac Reimaging Guide]]

# Backup Home

**Last updated:** 2026-08-16

This runbook copies the home-directory files, dotfiles, and secret-bearing targets that a reimage would otherwise erase into `$REIMAGE_ARTIFACT_ROOT`, driven by `bin/backup-home.sh`.

The external artifact root is the authoritative copy. An optional OneDrive secondary copy carries only the work-safe subset, and credential-shaped material never travels to it.

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
    - [[#Run the Size Audit|Run the Size Audit]]
    - [[#Scan Archives for Credential Material|Scan Archives for Credential Material]]
    - [[#Choose the Backup Mode|Choose the Backup Mode]]
    - [[#Run the Backup|Run the Backup]]
    - [[#Review Output|Review Output]]
    - [[#Confirm the OneDrive Sync|Confirm the OneDrive Sync]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Customizing the Artifact-Config Fragments|Customizing the Artifact-Config Fragments]]
    - [[#Re-running This Phase|Re-running This Phase]]
    - [[#SSH Agent Socket Exclusion in Detail|SSH Agent Socket Exclusion in Detail]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

`backup-home` (Phase 2B) carries the local files a reimage erases — home-directory content, shell dotfiles, and credential-shaped material — onto the external artifact drive, with the credential-shaped material staged apart so it never syncs to the cloud in the clear.

**What it sets up**

- **A reviewed home-directory copy** — the directory targets and individual dotfiles named in the artifact-config fragments, synced under `home-files-backup/` with a `MANIFEST.md` recording what was taken and where it came from.
- **Staged secret material** — the credential-shaped sources named in `secrets-targets.conf.sh`, plus any corporate Java `jssecacerts`, copied into `secrets-encrypted/` with restrictive permissions.
- **An optional OneDrive secondary copy** — the narrower, work-safe target list from `onedrive-targets.conf.sh`, mirrored into the per-reimage OneDrive subfolder.

**What the rest of the workflow relies on it for**

- A restorable set of dotfiles and home content for the post-image phases to draw from selectively.
- Secret material parked where the Phase 3C consolidated DMG will encrypt it.
- A `home-files-backup/` directory the Phase 6B sign-off checks for before the erase.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| the `home-files-backup/` copy and its `MANIFEST.md` | app-specific backups, including Docker settings, contexts, and inventories — `backup-apps` (Phase 2C) |
| staging `secrets-targets.conf.sh` sources and Java `jssecacerts` into `secrets-encrypted/` | encrypting the staged secrets — `create-secrets-dmg` (Phase 3C) |
| the optional OneDrive secondary copy of work-safe targets | OneDrive root configuration and folder creation — `prepare-artifact-root` |
| | the developer-tool version inventory — `capture-system-inventory` (Phase 4B) |
| | the automated toolkit snapshot — `capture-toolkit-snapshot` |
| | cloud-sync and final manual sign-off — `reimage-prep-checks` (Phase 6B) |

This phase is safe to re-run at any point before the erase; the only precondition is that a re-run touching a secret target invalidates an already-built Phase 3C DMG — rerun Phase 3B and then Phase 3C after it.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. It is short, and every later step assumes it.

The goal is to get everything a wipe would destroy onto the external drive, while keeping credential-shaped material on a separate track from anything that touches corporate cloud storage. A single entrypoint, `bin/backup-home.sh`, does the copying; a run mode decides which destinations it writes to.

Two checks run before any copy, for one reason: they catch a full or unmounted drive, or a missing config fragment, while it is still cheap to fix — before a long copy commits to the wrong scope.

### The Two Destinations

The backup has one authoritative destination and one optional secondary destination. The difference is a safety boundary, not a convenience.

| Destination | What it receives | Status |
|---|---|---|
| External artifact root (`$REIMAGE_ARTIFACT_ROOT`) | The full selected set: home targets, dotfiles, and the secrets-encrypted staging, including Java `jssecacerts`. | Authoritative — the copy the restore phases trust. |
| OneDrive secondary (`$ONEDRIVE_ROOT/$ONEDRIVE_DEST_SUBDIR`) | Only the narrower, work-safe targets from `onedrive-targets.conf.sh`. | Secondary and optional — not proven until the Phase 6B checks confirm the upload. |

> [!note]
> The secrets-encrypted targets never travel to OneDrive. Only the external artifact root holds them, and only the encrypted DMG built later is intended to leave the drive. The OneDrive copy is a convenience mirror of work-safe documents, not a secrets backup.

### Terminology

| Term | Meaning |
|---|---|
| External artifact root | `$REIMAGE_ARTIFACT_ROOT` on the external drive — the authoritative backup destination. |
| Secrets-encrypted target | A credential-shaped source (SSH, GnuPG, `docker/config.json`, package-manager credentials, Java `jssecacerts`, and the rest) routed into `secrets-encrypted/` rather than `home-files-backup/`. |
| Work-safe target | A non-sensitive target approved for the optional OneDrive copy, listed in `onedrive-targets.conf.sh`. |
| Secondary copy | The optional OneDrive mirror of work-safe targets. It supplements the external root; it never replaces it. |
| Active fragment directory | The artifact-config directory a run actually reads — the per-machine workspace copy when one exists, otherwise the committed templates. |

### Configuration Fragments and Run Modes

The artifact-config fragments sourced from the active fragment directory are the single definition of what is backed up, what is excluded, what routes to secrets, and how OneDrive behaves. Nothing in the scripts hardcodes a target; changing scope means editing a fragment.

For the fragment set, how a `SECRETS_TARGETS` row is written, why a secrets source is held back from the clear-text pass, and which values are derived rather than configured, see [[artifact-config-reference|Artifact Config Reference]].

The mode flag on `bin/backup-home.sh` decides which destinations a run touches:

| Mode | Command | Writes to |
|---|---|---|
| External only (preferred) | `./bin/backup-home.sh --external-only` | External artifact root only. |
| External plus OneDrive (default) | `./bin/backup-home.sh` | External artifact root, then the OneDrive secondary of work-safe targets. |
| OneDrive only | `./bin/backup-home.sh --onedrive-only` | OneDrive secondary only — refreshes it after the external copy already ran. |
| Dry run | add `--dry-run` to any mode above | Nothing. It previews the copy the chosen scope would make and leaves the artifact root untouched. |

External-only is the preferred first run because it fills the authoritative destination without waiting on cloud sync. The SSH target is copied with socket-skipping options so live agent sockets are left behind; the mechanics are in [[#SSH Agent Socket Exclusion in Detail|SSH Agent Socket Exclusion in Detail]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary scripts, alphabetical:

```text
$FRACTOGENESIS_HOME/bin/backup-home.sh              # entrypoint
$FRACTOGENESIS_HOME/bin/report-size-audit.sh       # entrypoint
$FRACTOGENESIS_HOME/bin/verify-artifact-config.sh   # entrypoint (aggregate validator)
```

Artifact locations:

```text
$REIMAGE_ARTIFACT_ROOT/home-files-backup/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/
$REIMAGE_ARTIFACT_ROOT/size-audit-reports/
$ONEDRIVE_ROOT/$ONEDRIVE_DEST_SUBDIR/
```

Subdirectories under `$REIMAGE_ARTIFACT_ROOT` this runbook's steps touch:

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── home-files-backup/
│   ├── dotfiles/
│   ├── home/
│   └── MANIFEST.md
├── secrets-encrypted/
│   ├── ...
│   ├── certs/
│   │   └── java-security/
│   ├── cli-credentials/
│   ├── cloud/
│   ├── docker/
│   ├── git/
│   ├── gnupg/
│   ├── kube/
│   ├── package-managers/
│   ├── postman/
│   └── ssh/
└── ...
```

The `secrets-encrypted/` subdirectories shown are the destinations `secrets-targets.conf.sh` routes to; that fragment is the authoritative list. The dotfiles that land in `home-files-backup/dotfiles/` are named in `external-dotfiles.conf.sh`.

The complete layout of both trees, including the `home/` subtree and the `secrets-encrypted/` entries other phases add, is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The values these scripts read. `REIMAGE_ARTIFACT_ROOT`, the volume paths, and the OneDrive values are resolved and written into `reimage.env` during `prepare-artifact-root.md`; the derived and fragment-supplied values are noted as such.

| Variable | Meaning |
|---|---|
| `ARTIFACT_CONFIG_DIR` | Optional explicit override for the active fragment directory. Derived by `artifact-config.sh` when unset. |
| `BACKUP_*` | Per-target secret toggles from `secret-flags.conf.sh`, one per `secrets-targets.conf.sh` key (for example `BACKUP_GNUPG`, `BACKUP_JAVA_JSSECACERTS`). Unset means enabled. |
| `EXTERNAL_DATA_VOLUME` | The mounted external volume. `report-size-audit.sh` reads its capacity and treats it as the default `--drive`. |
| `FRACTOGENESIS_HOME` | The toolkit checkout holding the scripts and this runbook. A shell-startup or `.envrc` value, not a `reimage.env` key. |
| `ONEDRIVE_DEST_SUBDIR` | The per-reimage OneDrive subfolder. Defaults to the basename of `$REIMAGE_ARTIFACT_ROOT`. |
| `ONEDRIVE_FOLDER_NAME` | The OneDrive sync folder name. Combined with `ONEDRIVE_PARENT_DIR` to build the root. |
| `ONEDRIVE_PARENT_DIR` | Directory the OneDrive sync folder lives under. Blank uses `$HOME/Library/CloudStorage`. |
| `ONEDRIVE_PREFERRED_ROOT` | Derived by `artifact-config.sh` from the two values above; the root the scripts try first. |
| `ONEDRIVE_ROOT` | The resolved OneDrive account root. Must be absolute — a bare folder name is rejected. |
| `REIMAGE_ARTIFACT_ROOT` | The external artifact root — authoritative backup destination. |
| `REIMAGE_WORKSPACE_ROOT` | Holds the per-machine `artifact-config/` copy. When it has no such copy, runs fall back to the committed templates. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight. Confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- The external artifact volume is mounted and `$REIMAGE_ARTIFACT_ROOT` resolves to an existing directory.
- `reimage.env` holds resolved absolute values, produced by `prepare-artifact-root.md`.
- `rsync` is installed and on `PATH`. Every directory copy in this phase is an rsync sync, and `backup-home.sh` refuses to start without it.
- If you will use OneDrive, `ONEDRIVE_FOLDER_NAME` and `ONEDRIVE_ROOT` are configured and the OneDrive folder was created during `prepare-artifact-root.md`.

> [!bug] Troubleshooting
> If `REIMAGE_ARTIFACT_ROOT` resolves empty, either fix `reimage.env` or pass `--artifact-root PATH` explicitly on every command below.

### Confirm Your Intent

- Which mode you want: external-only (preferred first run), external plus OneDrive (default), or OneDrive-only (refresh an existing copy).
- Whether this run should touch OneDrive at all. If not, use `--external-only`.
- Whether to preview first with `--dry-run`. A dry run writes nothing at all, including no `home-files-backup/` directory.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The first three are shared setup; you then choose the backup mode, run it, and review what landed. The final OneDrive check applies only to a run that included OneDrive.

### Load the Shared Reimage Environment

`backup-home.sh` and `report-size-audit.sh` self-locate and load shared config through `.internal/load-reimage-config.sh` — you never source `reimage.env` by hand. `verify-artifact-config.sh` resolves the fragment directory on its own without sourcing the fragments, so a broken fragment gets reported instead of aborting the load.

Confirm the scripts parse:

```bash
bash -n bin/backup-home.sh
```

```bash
bash -n bin/report-size-audit.sh
```

Confirm every destination a run would write to, without writing anything:

```bash
./bin/backup-home.sh --dry-run | head -16
```

The header block names each one before any copying starts:

```text
  Config       : <active artifact-config directory>
  Artifact root: <$REIMAGE_ARTIFACT_ROOT>
  OneDrive root: <resolved $ONEDRIVE_ROOT>
  OneDrive dest: <$ONEDRIVE_ROOT/$ONEDRIVE_DEST_SUBDIR>
  External     : yes | skipped
  OneDrive     : yes | skipped | unavailable
```

> [!note]
> The two OneDrive lines appear only when that run resolves a usable root. `skipped` means you asked to skip it with `--external-only`; `unavailable` means the run wanted OneDrive and could not resolve it, and the reason prints directly underneath. If any of these is not what you expect, stop here rather than at the copy.

### Confirm the Artifact-Config Fragments

The fragments are the entire definition of what gets backed up, what is excluded, what routes to secrets, and how OneDrive behaves. Confirm they are present and parse before the backup runs:

```bash
./bin/verify-artifact-config.sh
```

The fragments it verifies, and what each defines:

| Fragment | Defines |
|---|---|
| `archive-policy.conf.sh` | *Optional.* Which compressed archives are copied. Default is keep; `ARCHIVE_SKIP` names the exceptions. |
| `expected-artifact-folders.conf.sh` | Expected top-level `$REIMAGE_ARTIFACT_ROOT` folders used by the size audit and validation. |
| `external-dotfiles.conf.sh` | Individual home-directory dotfiles copied when present. |
| `external-excludes.conf.sh` | Global rsync excludes applied to every external sync. |
| `external-targets.conf.sh` | Home-directory targets copied under `home-files-backup/`. |
| `loose-secret-exceptions.conf.sh` | *Optional.* Phase 3B sweep findings confirmed as noise, each with the evidence for that call. Read by `report-loose-secrets.sh`, not by this phase. |
| `onedrive-extra-excludes.conf.sh` | Extra excludes applied only to OneDrive syncs. |
| `onedrive-targets.conf.sh` | The narrower, document-only OneDrive sync target list. |
| `secret-flags.conf.sh` | Optional secret backup toggles, one per secrets target. |
| `secret-shapes.conf.sh` | *Optional.* Extra credential-shaped filename globs, added to the built-in floor. Read by `report-loose-secrets.sh` and `stage-loose-secrets.sh`, not by this phase. |
| `secrets-targets.conf.sh` | Sensitive targets routed to `secrets-encrypted/` instead of `home-files-backup/`. |
| `skip-entries.conf.sh` | Intentionally skipped paths and the reason each is skipped. |

To change what gets backed up, excluded, or routed to secrets, edit these fragments — see [[#Customizing the Artifact-Config Fragments|Customizing the Artifact-Config Fragments]].

> [!warning] Pitfall
> Read the `Selected by:` line, not just the fragment results. A run that reports `committed templates (no workspace copy found)` verified the generic fragment set, not this Mac's — and `backup-home.sh` will back up that same generic set.

### Run the Size Audit

Run the size audit before copying, so a full or unmounted drive is caught early. Give it a sub-label so this capture stays distinguishable from other same-day audits in `size-audit-reports/MANIFEST.md`:

```bash
./bin/report-size-audit.sh --context pre-image-backup-home
```

Review these lines in the output:

- `Estimated external backup size`
- `Target backup root`
- `Target home-files destination`
- `Available on <volume>`
- `✓ External drive: enough space` or `✗ External drive: NOT ENOUGH SPACE`
- `Planned OneDrive sync size`, `Target OneDrive destination`, `Available on OneDrive local volume` — when OneDrive applies

> [!note]
> `--local-only` shows the local target inventory only; it skips *both* the OneDrive and the external-drive-capacity sections. Reach for it for a quick size estimate when the external drive is not mounted yet — not when you need the external fit check, which that flag hides. OneDrive cloud quota always needs manual confirmation.

> [!bug] Troubleshooting
> The saved report keeps ANSI color codes on purpose; view it in a terminal, not an editor: `less -R "$REIMAGE_ARTIFACT_ROOT/size-audit-reports/runs/<run>/size-audit-report.txt"`.

### Scan Archives for Credential Material

A compressed archive is opaque to every filename sweep in this workflow, so a credential sealed inside one is copied in the clear and passes Phase 3B without comment. Run this before the copy, while the decision is still cheap:

```bash
.internal/home/scan-archive-contents.sh --context pre-image-backup-home
```

The report lands under `loose-secrets-reports/content-scans/runs/<context>-<stamp>/`, beside the Phase 3B sweep's own reports, with a `MANIFEST.md` row and a `latest-run.txt` pointer. Give each run a sub-label so same-day scans stay distinguishable, the same way the size audit and the sweep do. `--dest` moves the report root, `--report FILE` writes one file to an explicit path without a manifest row, and `--no-report` prints to the terminal only.

With no leg flag it scans **both legs**, the same convention as `bin/backup-home.sh` — `--external-only` and `--onedrive-only` narrow it to one, and passing both is an error rather than a merged scan.

Each leg is a separate pass with its own report and its own `MANIFEST.md` row, because they answer different questions. The external leg reads `external-targets.conf.sh` and prunes with the directory-shaped entries in `external-excludes.conf.sh`. The OneDrive leg reads `onedrive-targets.conf.sh` and prunes with `external-excludes.conf.sh` **and** `onedrive-extra-excludes.conf.sh`, so it reports a narrower set — an archive under a folder kept off corporate cloud, such as `Personal/`, appears in the external pass and correctly not in the OneDrive one. Merging them would mean nothing, since the prune sets differ.

The distinction matters because the two outcomes are not equally reversible. An archive copied to the artifact drive can be deleted; one uploaded to corporate cloud cannot be recalled by a local delete. Treat a finding on the OneDrive leg as the stricter of the two.

Every mode is read-only and exits 1 when anything is found, which is informational rather than a failure.

Resolve a finding one of three ways: leave it as-is, add the filename to `ARCHIVE_SKIP` in `archive-policy.conf.sh`, or give the archive a `secrets-targets.conf.sh` row so it is encrypted into the DMG instead of copied in the clear. Archives already named in `ARCHIVE_SKIP` are still scanned and reported, marked as not-copied.

> [!note]
> Postman exports are the other file type whose credentials hide from a name sweep, and they are covered where the Postman export flow is documented — see [[backup-apps#Postman|backup-apps.md — Postman]].

### Choose the Backup Mode

Pick the mode intentionally before running it. External-only fills the authoritative destination first and does not wait on cloud sync; the default adds the OneDrive secondary in the same run; OneDrive-only refreshes just the secondary after the external copy already succeeded. Add `--dry-run` to any of them when you want to see the scope before committing to it.

> [!warning] Pitfall
> Any mode that includes OneDrive still leaves the OneDrive copy unproven. Writing to the local OneDrive folder is not the same as OneDrive uploading it, which is why the last step of this runbook exists.

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
./bin/backup-home.sh --artifact-root /Volumes/<volume>/<artifact-root> --external-only
```

The run exits `0` on success, `2` for a usage or prerequisite problem, and `1` when a copy fails — the failing target, its source and destination, and the underlying rsync exit code are printed. Warnings for rsync exit `23` and `24` are counted and summarized at the end without failing the run.

### Review Output

Confirm what landed before moving on:

```bash
find "$REIMAGE_ARTIFACT_ROOT/home-files-backup" -maxdepth 3 -type f | sort | head -100
```

Open the manifest and the copy for a visual pass:

```bash
open "$REIMAGE_ARTIFACT_ROOT/home-files-backup"
```

Confirm the secret staging landed with the directory targets you expect:

```bash
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted" -maxdepth 2 | sort
```

> [!warning] Pitfall
> Do not use this output as a bulk restore source without review. Some dotfiles and local configs may be obsolete or unsafe to copy directly onto the post-image system.

Re-run the archive scan against the artifact root, this time to confirm what actually landed rather than to decide:

```bash
.internal/home/scan-archive-contents.sh --root "$REIMAGE_ARTIFACT_ROOT" --context pre-image-post-backup
```

`--root` scans a directory directly, ignoring the target lists and the both-legs default. An archive you added to `ARCHIVE_SKIP` should be absent from the results entirely; one you chose to keep should appear with the same members it had at the source.

> [!warning] Pitfall
> Finding a credential-bearing archive *here* is worse than finding it before the copy. The plaintext is now on the drive, and if the run included the OneDrive leg it may already be uploading — a local delete does not recall it. That is why the scan step comes before the copy, not after.

> [!bug] Troubleshooting
> If a directory you listed in `external-targets.conf.sh` is missing from the copy, see [[#Directory Target Not Backed Up|Directory Target Not Backed Up]].

### Confirm the OneDrive Sync

This step applies only when `backup-home.sh` ran with OneDrive enabled. Checking the local folder proves the files were *written* to the local OneDrive-synced folder; it does not prove OneDrive *uploaded* them.

Drop a current-run marker so a later check, including the Phase 6B script, can confirm this specific run's copy:

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

- the OneDrive menu bar icon shows fully synced, with no pending uploads or errors
- the expected folder (`$ONEDRIVE_DEST_SUBDIR`) is visible in OneDrive web
- the current-run `onedrive-upload-marker-YYYYMMDD-HHMMSS.txt` file is visible in OneDrive web
- at least one recently changed file opens or previews correctly from OneDrive web
- the OneDrive cloud quota has room for the planned sync size

> [!bug] Troubleshooting
> If a run wrote to a relative `OneDrive-…/` folder inside the repo checkout instead of the real CloudStorage-mounted folder, that folder is not syncing. See [[#Accidental Relative OneDrive Folder|Accidental Relative OneDrive Folder]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The scripts copy and inventory; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Whether a dotfile or local config is safe to restore later | Some are obsolete or machine-specific and should not be copied back blindly. |
| Whether a flagged file is truly a secret | Content review, not filename, decides what must stay in `secrets-encrypted/`. |
| Whether to widen `onedrive-targets.conf.sh` | Every added target is corporate-cloud exposure that no exclude pattern fully guarantees against. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Two failures span more than one step and have fixes long enough to break a step's flow. Each step that can hit one links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

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

`backup-home.sh` refuses to write under the repo checkout and errors instead. To recover: move any stray contents into the real OneDrive root, quarantine the stray folder until the move shows in OneDrive web, then correct `reimage.env` through `prepare-artifact-root.md` before rerunning.

[[#Confirm the OneDrive Sync|⮕ Continue to Confirm the OneDrive Sync]]

---

### Directory Target Not Backed Up

If a directory you added to `external-targets.conf.sh` doesn't show up in the backup, the entry is almost always being read but skipped — not unread. The run's **External drive — directory targets** section tells you which of two cases you are in.

The target's label prints with `– <label>  not found, skipping`. The entry is active, but its `SOURCE` (field 2) does not exist as written. This is the most common cause. Watch for:

- a misspelled or wrong-plurality folder name — `ai-contexts` when the folder is `ai-context`;
- a path pointing at a **file or script instead of its directory** — `…/elastic-start-local.sh` instead of the `…/elastic-start-local/` directory that contains it;
- a path pointing at a **single loose file** rather than a directory. `EXTERNAL_TARGETS` entries are directory targets; capture a one-off file through its parent directory, or route it via a dotfile or secret fragment instead.

The label does not appear at all. The entry is not active: it starts with `#` (commented out), is malformed (not five `|`-delimited fields), or sits outside the `EXTERNAL_TARGETS=( … )` parentheses.

A third case hides even a valid, existing target: a pattern in `external-excludes.conf.sh` filters it out. If a directory that exists and is correctly listed still comes back empty or missing, check the excludes fragment before anything else — an exclude added earlier quietly wins over a later include.

> [!note]
> `SOURCE` uses trailing-slash semantics: `…/dir/` syncs the directory's contents into `DEST`, while `…/dir` syncs the directory itself. Before assuming the script is at fault, confirm the source resolves to a directory exactly as written: `ls -d "$HOME/path/you/entered"`.

[[#Run the Backup|⮕ Continue to Run the Backup]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Customizing the Artifact-Config Fragments

The fragments are ordinary Bash files: an array — or, for `secret-flags.conf.sh`, a set of variables — with one commented format line at the top. Edit the *active* copy, which is the directory `verify-artifact-config.sh` reports on its `Directory:` line: a workspace copy under `$REIMAGE_WORKSPACE_ROOT/artifact-config` when present, otherwise the committed templates in `.internal/templates/artifact-config`. After any edit, re-run `./bin/verify-artifact-config.sh` and a `--dry-run` before copying.

**`external-targets.conf.sh`** — directories copied into `home-files-backup/`. Pipe-delimited: `LABEL | SOURCE | DEST | CATEGORY | DESCRIPTION`. A trailing slash on `SOURCE` copies the directory's *contents*; no slash copies the directory itself. Comment a line out to drop that target; copy a line and repoint `SOURCE` to add one.

**`external-dotfiles.conf.sh`** — individual `~/` dotfiles. `FILENAME | CATEGORY | DESCRIPTION`; missing files are skipped silently. A dotfile marked `CATEGORY = secrets` is *not* copied here — it is expected in `secrets-targets.conf.sh` instead, so it lands staged for encryption rather than in the clear. Keep credential-shaped dotfiles out of this list unless their category is `secrets`.

**`external-excludes.conf.sh`** — rsync filter patterns applied to *every* external sync. Add a pattern here rather than editing a script, to drop noise (caches, installers, `.DS_Store`) from otherwise-wanted targets.

**`archive-policy.conf.sh`** *(optional)* — which compressed archives (`.zip`, `.dmg`, `.tar.gz`, and the rest) are copied. The default is **keep**: every archive under a target is copied unless a pattern in `ARCHIVE_SKIP` matches it, and `ARCHIVE_KEEP` is evaluated first so it can carve an exception out of a broad skip. Skip an archive when it is large *and* its content is already captured in a better form elsewhere; say which in the comment. Note that `ARCHIVE_KEEP` cannot rescue a file from a directory excluded by `external-excludes.conf.sh` — rsync never descends into a pruned directory, so a filename include is never consulted. Extension patterns belong here, never in `external-excludes.conf.sh`, which applies to every target at any depth.

**`secrets-targets.conf.sh`** — credential-shaped sources copied to `secrets-encrypted/` for the later DMG. `KEY | SOURCE | DEST | DESCRIPTION`, with `DEST` relative to `secrets-encrypted/`. Each `KEY` is gated by a `BACKUP_<KEY>` flag. Add a secret by giving it a `KEY` and a `secrets-encrypted/`-relative `DEST`; never route a secret through `external-targets.conf.sh`. A row here also **holds the file back from the clear-text pass**: any source that falls inside a directory target is excluded from both `home-files-backup/` and OneDrive, so a row means the DMG and only the DMG. That exclusion applies to future runs, not retroactively — a clear-text copy left by an earlier run must be deleted by hand, because rsync's `--delete` leaves excluded files alone on the destination.

**`secret-flags.conf.sh`** — `BACKUP_<KEY>=true|false` toggles for the secrets targets, and for Java `jssecacerts`. An unset flag defaults to `true`; set one to `false` to skip a secret this run, for example `BACKUP_GNUPG=false`.

**`onedrive-targets.conf.sh`** — the work-safe subset mirrored to OneDrive. Same format as `external-targets.conf.sh`, `DEST` relative to the OneDrive destination. Keep it narrow — documents only, never dotfiles or secrets. Comment lines in or out to widen or narrow the mirror.

**`onedrive-extra-excludes.conf.sh`** — excludes applied to OneDrive syncs *in addition to* `external-excludes.conf.sh`. This is the guardrail that keeps sensitive file types (`*.pem`, `*.key`, `.netrc`, `*.env`, …) and personal folders off corporate cloud even if a broad target would sweep them in. When in doubt, extend it rather than trim it.

**`skip-entries.conf.sh`** — `PATH | REASON`, informational only. It does *not* cause anything to be skipped; it documents intentional omissions so the size audit can explain them. To actually exclude something, add a pattern to `external-excludes.conf.sh` or leave it out of the targets — then, optionally, record why here.

**`expected-artifact-folders.conf.sh`** — the top-level folder names expected under `$REIMAGE_ARTIFACT_ROOT`, checked by the size audit and the Phase 6B checklist. This tracks the standard artifact-root layout from `prepare-artifact-root.md`; change it only when that layout changes, and keep it alphabetized.

### Re-running This Phase

This phase is safe to re-run at any point before the erase — including right after a later pre-image phase. A re-run refreshes the home copy to match your disk as it is now; nothing about the earlier run has to be undone first, and no later phase has to be re-run because of it.

It does not disturb other phases' output. `backup-home.sh` writes only to `home-files-backup/` and its own `secrets-encrypted/` destinations. It never touches `app-settings-backup/`, so a re-run leaves the Backup Apps artifacts intact.

What a re-run changes: the external home targets are synced with `rsync -a --delete`, so the backup is brought into line with your current home directory — new and changed files are copied in, and files you have since deleted are pruned from the backup. Secret-bearing targets are refreshed additively, with no delete.

Preview first:

```bash
./bin/backup-home.sh --dry-run --external-only
```

Then refresh just the authoritative external copy:

```bash
./bin/backup-home.sh --external-only
```

Use the default mode instead only when you also want the OneDrive work-safe subset refreshed — that run needs the OneDrive confirmation done again.

> [!warning] Pitfall
> If you have already built the Phase 3C secrets DMG, a re-run that changes any secret-bearing target means that DMG no longer covers the full staged secret set — rerun Phase 3B and rebuild it in Phase 3C after this refresh. While you are still staging and have not built the DMG yet, which is the normal case here, there is nothing extra to do.

### SSH Agent Socket Exclusion in Detail

`backup-home.sh` copies the `ssh` `SECRETS_TARGETS` directory (`~/.ssh/`) with `rsync -a --no-specials --no-devices --exclude="random_seed"`, not a plain `rsync -a`.

This matters because `~/.ssh/agent/` can contain live SSH agent Unix domain sockets, for example:

```text
~/.ssh/agent/s.<agent-id>.agent.<token>
```

These are runtime-only control sockets created by the running SSH agent process. They are not restorable secrets — a copied socket file cannot be reconnected to an agent after a reimage. Copying them with a socket-preserving rsync also fails outright (`rsync: mkstempsock: Invalid argument`, rsync exit `23`), which is what originally broke this step.

`--no-specials --no-devices` tells rsync to skip sockets, FIFOs, and device files instead of trying to recreate them. Regular SSH key material (`id_ed25519`, `id_rsa`, `known_hosts`, `config`, and the rest) under `~/.ssh/` is unaffected and still copies normally. A new SSH agent creates fresh sockets on its own, so there is nothing to restore here.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- the two routed Troubleshooting destinations are deliberately absent from the
  Table of Contents — their inline `> [!bug]` callouts are the only entry point,
  and each ends with a single Continue link to the step it resumes at;
- each remaining section ends with one "Back to Table of Contents" link
  followed by a `---` divider.
-->
