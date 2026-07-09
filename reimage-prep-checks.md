[[reimaging-guide#Phase 4B — Reimage Preparation Checks|← Back to Mac Reimaging Guide]]

# Reimage Preparation Checks

Use this guide to run the Phase 4 final pre-image validation, review the generated go / no-go checklist, and complete the manual sign-off items that the script cannot prove by itself -- including app backup status, certificate/Keychain staging, VS Code Settings Sync state, and cloud sync confirmation.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Readiness Criteria for Sync Items|Readiness Criteria for Sync Items]]
- [[#Sequential Capture Steps|Sequential Capture Steps]]
- [[#Run Single Script - Combines Commands|Run Single Script - Combines Commands]]
    - [[#Generated Go / no-go report|Generated Go / no-go report]]
        - [[#Go / no-go checklist|Go / no-go checklist]]
        - [[#Template — Pre-Image Final Manual Sign-Off|Template — Pre-Image Final Manual Sign-Off]]
- [[#Individual Commands Alternative|Individual Commands Alternative]]
    - [[#Create or Refresh the Manual Sign-Off Note|Create or Refresh the Manual Sign-Off Note]]
    - [[#Capture Local Cloud Folder Paths as Reference|Capture Local Cloud Folder Paths as Reference]]
    - [[#Confirm VS Code Settings Sync State|Confirm VS Code Settings Sync State]]
    - [[#Confirm OneDrive Sync Separately|Confirm OneDrive Sync Separately]]
        - [[#Fix an Accidental OneDrive Folder Under FRACTOGENESIS_HOME|Fix an Accidental OneDrive Folder Under FRACTOGENESIS_HOME]]
    - [[#Confirm iCloud Drive Sync Separately|Confirm iCloud Drive Sync Separately]]
- [[#Final Spot Checks|Final Spot Checks]]

---

## Purpose

The goal of this phase is to have confidence that the reimage preparation of the Mac prior to reimaging will reliably and safely restore the environment after reimaging.

`reimage-checklist.sh` is the authoritative validation path: it proves as many items as automation reasonably can, including app backup status, certificate/Keychain staging presence, and evidence of an OneDrive backup copy. The manual checks that remain -- Obsidian restore-source decisions belong in `backup-apps.md`, not here -- are the ones automation cannot prove by itself: VS Code Settings Sync state, whether OneDrive/iCloud uploads have actually settled, and where export passwords were saved.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Primary script:

```text
bin/reimage-checklist.sh
```

Generated output root:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/
```

Current generated files remain compatible with the existing validation layout:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/reimage-checklist-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/latest-reimage-checklist.txt
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual-captures-required.md
```

Manual sign-off note created or refreshed under:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/manual-app-export-and-sync-signoff-YYYYMMDD.md
```

Template for that note:

```text
workflows/mac/reimage/templates/app-backup-and-cloud-sync-signoff-template.md
```

Related artifact roots reviewed in this guide:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

Review the manual readiness criteria before final reimage-prep validation.

### Readiness Criteria for Sync Items

Before running reimage preparation checks, these manual rows should be complete or intentionally marked as not applicable:

| Check | Required evidence |
|---|---|
| VS Code Settings Sync | Signed-in/sync state recorded, or local rebuild-reference capture chosen as source of truth. |
| OneDrive | Menu bar shows no pending uploads or errors, the current-run marker is visible in OneDrive web, and OneDrive web spot-check confirms the expected folder/files. |
| iCloud Drive | Enabled and settled for any relied-on files, or marked not used. |
| Certificate/Keychain staging | Chosen Keychain/cert files are staged under `secrets-encrypted/certs/`; skipped/non-exportable identities have notes. |
| Secret safety | No Chrome password CSV, private keys, `.p12` / `.pfx`, keystores, or unreviewed exports are loose in OneDrive or iCloud. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Capture Steps

Use the single script for the standard run. Use the individual commands only for the sync-specific manual checks that the script cannot fully prove, or when troubleshooting a specific section.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Run Single Script - Combines Commands

From the reimage workflow root:

```bash
cd "$FRACTOGENESIS_HOME"
set -a
source ./reimage.env
set +a

chmod +x bin/reimage-checklist.sh

./bin/reimage-checklist.sh \
  --phase pre \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --open
```

Optional additions:

```bash
./bin/reimage-checklist.sh \
  --phase pre \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --internal-url "https://your-internal-url" \
  --workspace-root ~/path/to/projects \
  --open
```

Use the generated report as the primary Phase 4 checklist. Then use the [[#Individual Commands Alternative|Individual Commands Alternative]] section below only for the cloud sync checks and manual sign-off rows that remain after reviewing that generated report.

The script creates:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/reimage-checklist-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/latest-reimage-checklist.txt
```

Open the results:

```bash
open "$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks"
```

For workflow-snapshot validation, the expected source is the newest timestamped workflow snapshot bundle:

```text
$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/
```

The checklist should discover that folder directly from `workflow-snapshot/pre-image-workflow-snapshot-*`. VS Code local fallback state is validated from `app-backups/vscode/`.

The script exits with a non-zero status if any **FAIL** item is found. Do not proceed to Phase 5 until it exits cleanly with zero FAILs.

Use **either** the script above **or** the individual commands below. Do not run both unless you are intentionally rerunning or troubleshooting a specific section.

### Generated Go / no-go report

After the script run, review the generated report and complete the remaining manual sign-off rows before proceeding.

The Go / no-go checklist is generated by the Phase 4 validation workflow. The generated report fills automated rows with status such as `PASS`, `WARN`, `FAIL`, or explanatory notes. Human-only rows remain manual because automation cannot prove the decision or UI state.

Generated locations:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/reimage-checklist-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/latest-reimage-checklist.txt
```

Use the table below as the readable checklist map. Use the generated report as the actual evidence, then complete any remaining manual rows.

#### Go / no-go checklist

Do not proceed until each critical item is complete. The script validates all automated items; the manual sign-off rows at the bottom require manual confirmation.

|Check|Automated|Status|
|---|---|---|
|IT confirmed approved reimage method|Manual|`TODO`|
|External backup drive backup root exists|✅ Script|—|
|Git audit report reviewed|✅ Script|—|
|Local-only commits pushed or backed up|✅ Script|—|
|Stashes converted to branches or intentionally ignored|✅ Script|—|
|Untracked non-ignored files reviewed|✅ Script|—|
|Selected ignored files copied|✅ Script|—|
|Secrets encrypted or stored safely|✅ Script|—|
|Backup IntelliJ completed|✅ Script|—|
|IntelliJ settings ZIP exported|✅ Script|—|
|Consolidated secrets DMG created and manifest present|✅ Script|—|
|Extra certificate/Keychain review inventory generated|✅ Script|—|
|Keychain manual exports staged under `secrets-encrypted/certs/keychain-manual-exports/`, if needed|✅ Script|—|
|Loose private-key/keystore/certificate candidates reviewed|Manual|`TODO`|
|`.p12` / `.pfx` export passwords saved only in approved password manager, if applicable|Manual|`TODO`|
|System inventory captured|✅ Script|—|
|Performance baseline captured|✅ Script|—|
|Office stability evidence copied, if applicable|✅ Script|—|
|Office stability baseline captured and copied to `office-stability/`|✅ Script|—|
|Confirmed no active scripts were copied to external backup drive|✅ Script|—|
|Postman exports saved, if applicable|✅ Script / Manual review|—|
|Chrome bookmarks exported or Chrome sync intentionally used|✅ Script|—|
|Chrome password CSV staged under `secrets-encrypted/chrome/`, if exported|✅ Script|—|
|Backup Apps manifest generated|✅ Script|—|
|VS Code settings/extensions captured|✅ Script|—|
|Dotfiles captured|✅ Script|—|
|Time Machine status bundle generated|✅ Script|—|
|Time Machine backup completed and `tmutil latestbackup` confirmed|Manual|`TODO`|
|External backup root opened and spot-checked|✅ Script|—|
|LastPass vault verified accessible at lastpass.com|Manual|`TODO`|
|DMG password saved to LastPass immediately after creation|Manual|`TODO`|
|DMG verified — opens in Finder, `gnupg/private-keys-v1.d/`, `ssh/`, `certs/java-security/*/jssecacerts`, `certs/keychain-manual-exports/`, and `extra-secrets-certs-review/` present if expected|Manual|`TODO`|
|User/client public certificate PEM verified with balanced BEGIN/END blocks, if exported|Manual|`TODO`|
|Keychain export summary and duplicate/fingerprint notes created, if manual Keychain exports were reviewed|Manual|`TODO`|
|VS Code Settings Sync state confirmed|Manual|`TODO`|
|OneDrive backup folder detected in CloudStorage with an upload marker (evidence only, not proof of sync)|✅ Script|—|
|OneDrive — no pending uploads (check menu bar icon and web spot-check)|Manual|`TODO`|
|iCloud Drive available, if used|✅ Script / SKIP|—|
|iCloud Drive — no pending uploads for relied-on files, if used|Manual|`TODO`|
|Obsidian vault synced or manually copied|Manual|`TODO`|
|App backup and cloud sync manual sign-off note completed (see [[#Individual Commands Alternative|Individual Commands Alternative]] below)|Manual|`TODO`|
|External drive ejected before reimage starts|Manual|`TODO`|

#### Template — Pre-Image Final Manual Sign-Off

Save this as a working note under `$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/` before you start checking items off, so you don't lose the capture:

```bash
mkdir -p "$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual"
FINAL_SIGNOFF_NOTE="$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/pre-image-final-manual-signoff-$(date +%Y%m%d).md"

if [[ ! -e "$FINAL_SIGNOFF_NOTE" ]]; then
cat > "$FINAL_SIGNOFF_NOTE" <<'EOF'
Pre-Image Final Manual Sign-Off — YYYY-MM-DD

IT approval:
  [ ] Approved method confirmed
  Method:
  Notes:

Time Machine:
  [ ] Backup completed
  Latest backup path:

Secrets:
  [ ] DMG password saved in approved password manager
  [ ] DMG mounted and verified
  Notes:

Cloud/manual sync:
  [ ] OneDrive sync complete
  [ ] Obsidian/reference-vault sync or backup complete
  Notes:

External backup root:
  [ ] Spot-checked
  [ ] No active scripts under $REIMAGE_ARTIFACT_ROOT/scripts
  [ ] External drive ejected before reimage

Completed by: TODO
Date: YYYY-MM-DD
EOF
fi

open "$FINAL_SIGNOFF_NOTE"
```

For the fuller app-backup and cloud-sync note (Chrome, Postman, Keychain, VS Code Settings Sync, OneDrive/iCloud), use `app-backup-and-cloud-sync-signoff-template.md` from `workflows/mac/reimage/templates/` -- see [[#Create or Refresh the Manual Sign-Off Note|Create or Refresh the Manual Sign-Off Note]] below.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Individual Commands Alternative

These commands cover the manual checks that the script cannot prove by itself: app backup status, certificate and Keychain staging status, VS Code Settings Sync state, OneDrive upload completion, and iCloud Drive upload completion. Obsidian restore-source decisions belong in `backup-apps.md`, not here.

### Create or Refresh the Manual Sign-Off Note

Copy `app-backup-and-cloud-sync-signoff-template.md` from this repo's `templates/` into place and fill it in only if the generated checklist still leaves manual rows you want recorded in a separate note:

```bash
SYNC_NOTE="$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/manual-app-export-and-sync-signoff-$(date +%Y%m%d).md"
mkdir -p "$(dirname "$SYNC_NOTE")"

cp "$FRACTOGENESIS_HOME/templates/app-backup-and-cloud-sync-signoff-template.md" "$SYNC_NOTE"

open "$SYNC_NOTE"
```

The path above assumes `$FRACTOGENESIS_HOME` is set (see [[reimaging-guide#Phase 4A — Guide Access on a Freshly Reimaged Mac|Phase 4A]] / `.envrc`); adjust if your checkout isn't loaded into that variable.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Capture Local Cloud Folder Paths as Reference

Run this to record local cloud folder candidates and the expected OneDrive folder name. This does not prove sync completion, but it gives the manual sign-off note concrete paths to review.

```bash
CLOUD_ROOT="$HOME/Library/CloudStorage"
BACKUP_BASENAME="$(basename "$REIMAGE_ARTIFACT_ROOT")"

printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
printf 'Expected OneDrive folder basename=%s\n' "$BACKUP_BASENAME"

echo
echo 'CloudStorage roots:'
find "$CLOUD_ROOT" -maxdepth 1 -type d -print 2>/dev/null | sort || true
```

Paste relevant output into the sign-off note.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Confirm VS Code Settings Sync State

The rebuild-reference capture collects local VS Code files such as `settings.json`, `keybindings.json`, snippets, and `code --list-extensions`. That does not prove Settings Sync is enabled, signed in, or settled.

Check in VS Code:

```text
Accounts icon or Manage gear > Settings Sync
Command Palette > Settings Sync: Show Synced Data
```

Record in the sign-off note:

```text
signed-in account
Settings Sync on/off
last synced data visible or not visible
whether the local VS Code backup under `app-backups/vscode/` or Settings Sync is the restore source instead
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Confirm OneDrive Sync Separately

Use this when `backup-local-files.sh` was run with OneDrive enabled or when any relied-on file depends on OneDrive. The script's "OneDrive backup folder detected" check only confirms the folder and an upload marker exist locally -- it cannot prove the cloud copy is current.

The detailed procedure -- identifying the expected OneDrive target, dropping a current-run upload marker, the local spot-check commands, and the four-point confirmed checklist -- now lives in the "Confirm OneDrive Sync" section of `backup-local-files.md`. Run that procedure, then come back here and record the result in the go/no-go checklist below.

Pass/fail for this phase:

```text
[ ] OneDrive menu bar shows fully synced, no pending uploads or errors
[ ] expected backup folder and current-run marker file are both visible in OneDrive web
```

[[#Table of Contents|⬆ Back to Table of Contents]]

#### Fix an Accidental OneDrive Folder Under FRACTOGENESIS_HOME

If an older script run wrote to a relative path under `$FRACTOGENESIS_HOME` instead of the real OneDrive CloudStorage folder, see the "Accidental relative OneDrive folder" note in the "Confirm OneDrive Sync" section of `backup-local-files.md` for the fix.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Confirm iCloud Drive Sync Separately

Use this only for files where iCloud is allowed and where iCloud is part of the restore plan. The script's "iCloud Drive available" check only confirms the local iCloud Drive folder exists -- it cannot prove upload completion.

Check:

```text
System Settings > Apple Account > iCloud > iCloud Drive
Finder > iCloud Drive
```

Confirm for any relied-on file or folder:

```text
iCloud Drive is enabled
no pending cloud upload icons remain
no waiting/error icons remain
file is visible from another Apple device or icloud.com, if that is the restore proof
```

Optional local open command:

```bash
ICLOUD_DRIVE="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
test -d "$ICLOUD_DRIVE" && open "$ICLOUD_DRIVE"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Final Spot Checks

```bash
find "$REIMAGE_ARTIFACT_ROOT" -maxdepth 2 -type f | sort | sed "s|$REIMAGE_ARTIFACT_ROOT/||" | head -200

du -sh "$REIMAGE_ARTIFACT_ROOT"/*

printf '\nCurrent secrets-encrypted tree after DMG validation/cleanup:\n'
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted" -maxdepth 4 -print 2>/dev/null | sort | sed "s|$REIMAGE_ARTIFACT_ROOT/||" | head -200
```

Check that the most important directories are non-empty:

```bash
for d in \
  git-audit-reports \
  gitignore-superset \
  selected-ignored-files \
  intellij \
  secrets-encrypted \
  system-inventory \
  performance-audit \
  app-backups \
  time-machine \
  reimage-prep-checks; do
  echo "--- $d"
  find "$REIMAGE_ARTIFACT_ROOT/$d" -maxdepth 2 -type f | head -20
done
```

Review the manual sign-off note and the secrets staging areas:

```bash
find "$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual" -maxdepth 1 -type f -name 'manual-app-export-and-sync-signoff-*.md' -print | sort
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome" -maxdepth 3 -type f | sort 2>/dev/null || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman" -maxdepth 3 -type f | sort 2>/dev/null || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs" -maxdepth 4 -type f | sort 2>/dev/null || true
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---
