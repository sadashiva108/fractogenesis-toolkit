[[reimaging-guide#Workflow Map and Reference Guides|← Back to Mac Reimaging Guide]]

# Reimaging Scripts Guide

> **Migration note:** this guide describes the full pre-split script layout and is only *partially* updated. Confirmed migrated into `fractogenesis-toolkit` so far: `prepare-artifact-root.py`/`.md`, `.internal/artifact-config.sh` (renamed from `artifact-config.sh`), `bin/reimage-checklist.sh`, `.internal/load-reimage-config-snippet.sh`, and `reimage-prep-checks.md` (renamed from `capture-validated-reimage-prep.md`) — these have updated paths, names, and the `$REIMAGE_ARTIFACT_ROOT`/`REIMAGE_ROOT`-retirement changes applied and cross-checked against the real migrated files. Every other script referenced below (`backup-apps.sh`, `backup-repos.sh`, the `capture-*.sh`/`restore-*.sh` family, etc.) still reflects the **old** `scripts/`-prefixed, `--backup-root`-flagged reference-vault layout, since those haven't been migrated yet — don't assume their paths or flag names below are current until they get their own migration pass.

Use this as the script index for the Mac reimage workflow. The Markdown runbooks explain the workflow; this guide maps each phase to the scripts that generate backups, evidence captures, and validation checklists.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#Script Source and Artifact Rules|Script Source and Artifact Rules]]
- [[#Phase-to-Script Map|Phase-to-Script Map]]
- [[#Reference-Vault Script Layout|Reference-Vault Script Layout]]
- [[#External Backup Artifact Layout|External Backup Artifact Layout]]
- [[#Phase 1 Preparation Entrypoint|Phase 1 Preparation Entrypoint]]
- [[#Pre-Image Backup Automation|Pre-Image Backup Automation]]
    - [[#Size Audit|Size Audit]]
    - [[#Phase 2A Git Repository Backups|Phase 2A Git Repository Backups]]
    - [[#Phase 2B Local Files Backup|Phase 2B Local Files Backup]]
    - [[#Phase 2C Backup Apps|Phase 2C Backup Apps]]
    - [[#Phase 2C IntelliJ Detail|Phase 2C IntelliJ Detail]]
    - [[#Phase 2D Certificate and Keychain Staging|Phase 2D Certificate and Keychain Staging]]
    - [[#Phase 2E Encrypted DMG Secrets Backup|Phase 2E Encrypted DMG Secrets Backup]]
    - [[#Phase 2F Time Machine Backup and Status Capture|Phase 2F Time Machine Backup and Status Capture]]
- [[#Separate Capture Script Reference|Separate Capture Script Reference]]
- [[#Pre-Image Capture Automation|Pre-Image Capture Automation]]
    - [[#Phase 3A Capture Workflow Snapshot|Phase 3A Capture Workflow Snapshot]]
    - [[#Phase 3B Pre-Image System Inventory Capture|Phase 3B Pre-Image System Inventory Capture]]
    - [[#Phase 3C Pre-Image Company-Managed Inventory Capture|Phase 3C Pre-Image Company-Managed Inventory Capture]]
    - [[#Phase 3D Pre-Image Performance Audit Capture|Phase 3D Pre-Image Performance Audit Capture]]
    - [[#Phase 3E Pre-Image Office Stability Capture|Phase 3E Pre-Image Office Stability Capture]]
- [[#Post-Image Evidence Capture Automation|Post-Image Evidence Capture Automation]]
- [[#Validation Automation|Validation Automation]]
    - [[#Phase 4B Final Pre-Image Validation|Phase 4B Final Pre-Image Validation]]
    - [[#Phase 7 Initial Reimaged System Checklist|Phase 7 Initial Reimaged System Checklist]]
    - [[#Phase 12 Post-Image Final Validation|Phase 12 Post-Image Final Validation]]
- [[#Manual Captures That Remain Manual|Manual Captures That Remain Manual]]
- [[#Common Run Order|Common Run Order]]

> In Obsidian, click links in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

The workflow separates three different kinds of work:

| Kind | Meaning | Where it belongs |
|---|---|---|
| Backup | Files or state needed to restore the machine. | Phase 2 subphases and `$REIMAGE_ARTIFACT_ROOT/<backup-topic>/`. |
| Capture | Read-only snapshots and reference bundles used for comparison, troubleshooting, or workflow recovery. | Phase 3 subphases and `$REIMAGE_ARTIFACT_ROOT/system-inventory`, `performance-audit`, `office-stability`. |
| Validation | Generated checklist that proves prior steps were completed as much as a script can prove. | Phase 4 pre-image validation, Phase 7 initial post-image validation, and Phase 12 final post-image validation. |

This matters because Phase 3 captures are stored on the backup drive, but they are not restore backups. They can be run any time before the reimage as long as they are complete before the final pre-image validation.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Script Source and Artifact Rules

| Item | Location | Rule |
|---|---|---|
| Script source of truth | `workflows/mac/reimage/scripts/` | Keep in Git. Do not treat the external backup copy as authoritative. |
| Pre-image backup artifacts | `$REIMAGE_ARTIFACT_ROOT/<topic>/` | Store under the prepared external data/artifact `$REIMAGE_ARTIFACT_ROOT`. |
| Pre-image evidence artifacts | `$REIMAGE_ARTIFACT_ROOT/system-inventory/`, `$REIMAGE_ARTIFACT_ROOT/performance-audit/`, `$REIMAGE_ARTIFACT_ROOT/office-stability/`, `$REIMAGE_ARTIFACT_ROOT/time-machine/` | Generated captures only. |
| Post-image evidence | `$REIMAGE_ARTIFACT_ROOT/post-image/<topic>/` and matching pre/post evidence folders | Store generated post-image checklists and captures beside pre-image evidence. |
| Secrets | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-*.dmg` | Store in encrypted DMGs. Remove temporary loose secret copies after validation. |
| Time Machine backups | `/Volumes/AppleBackups` | Keep separate from manual evidence. Exclude the external backup drive from Time Machine. |

Standard variables are set once in `reimage.env` and loaded by every script automatically — see [[reimaging-guide#Phase 1 — Prepare the External Artifact Root|Phase 1 — Prepare the External Artifact Root]] (the standalone "Shared Setup and Externalized Configuration" section this used to point to no longer exists as its own heading; reimage.env setup is now covered there and in `prepare-artifact-root.md`):

```bash
# Example reimage.env entries — adjust to match your environment
# Note: REIMAGE_ROOT is retired. Scripts self-locate from their own position
# in the repo (see prepare-artifact-root.py's REPO_ROOT); FRACTOGENESIS_HOME
# (set via .envrc, not reimage.env) is the shell-level equivalent if needed.
export REIMAGE_ARTIFACT_ROOT="${REIMAGE_ARTIFACT_ROOT:-/Volumes/<external-data-volume-name>/reimage-<asset-or-host>-<start-date>-open}"
export ONEDRIVE_ROOT="${ONEDRIVE_ROOT:-$HOME/Library/CloudStorage/OneDrive-AcmeGroup}"
export ONEDRIVE_DEST_SUBDIR="${ONEDRIVE_DEST_SUBDIR:-$(basename "${REIMAGE_ARTIFACT_ROOT%/}")}"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase-to-Script Map

| Phase | Purpose | Markdown guide | Primary script(s) | Generated output |
|---|---|---|---|---|
| Phase 1 | Prepare external artifact root | `reimaging-guide.md`, `prepare-artifact-root.md` | `prepare-artifact-root.py` plus guide-owned shell checks and directory creation | `reimage.env`, `$REIMAGE_ARTIFACT_ROOT/` structure, `$REIMAGE_ARTIFACT_ROOT/reimage-confirmation/it-reimage-confirmation-*.md` |
| Phase 2A | Git repository backups | `backup-repos.md` | `backup-repos.sh` (public entrypoint), Git helpers under `scripts/helpers/git/` | `$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/`, `$REIMAGE_ARTIFACT_ROOT/gitignore-superset/`, `$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live/*` |
| Phase 2B | Local files backup | `backup-home.md` | `backup-home.sh` | `$REIMAGE_ARTIFACT_ROOT/home-files-backup/` |
| Phase 2C | Backup apps | `backup-apps.md` | `backup-apps.sh` (public entrypoint), `helpers/apps/backup-docker-settings.sh` and `helpers/apps/backup-intellij-scratches-consoles.sh` (internal helpers), plus app-controlled/manual exports for other apps | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/` plus matching `secrets-encrypted/` folders |
| Phase 2C detail | IntelliJ companion flow | `backup-intellij.md` | `backup-apps.sh` (public IntelliJ path), `helpers/apps/backup-intellij-scratches-consoles.sh` (internal helper) | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/` |
| Phase 2D | Certificate and Keychain staging | `stage-cert-keychain.md` | `stage-cert-keychain.sh` | `$REIMAGE_ARTIFACT_ROOT/public-certs/`, `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/`, `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/extra-secrets-certs-review/` |
| Phase 2E | Encrypted secrets backup | `backup-dmg-secrets.md` | `create-secrets-dmg.sh` | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-*.dmg` |
| Phase 2F | Time Machine backup/status | `backup-time-machine.md` | `backup-time-machine.sh`, `capture-time-machine.sh` | `/Volumes/AppleBackups`, `$REIMAGE_ARTIFACT_ROOT/time-machine/`, `final-time-machine-checklist-*.md` |
| Phase 3A | Workflow snapshot capture | `capture-workflow-snapshot.md` | `capture-workflow-snapshot.sh` | `$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/pre-image-workflow-snapshot-*/`, `$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/reimage-workflow-docs/` |
| Phase 3B | Pre-image system inventory evidence | `reimaging-guide.md` (Phase 3) | `capture-system-inventory.sh` | `$REIMAGE_ARTIFACT_ROOT/system-inventory/` |
| Phase 3C | Pre-image company-managed inventory evidence | `reimaging-guide.md` (Phase 3), `capture-managed-inventory.md` | `capture-managed-inventory.sh` | `$REIMAGE_ARTIFACT_ROOT/managed-inventory/` |
| Phase 3D | Pre-image performance evidence | `reimaging-guide.md` (Phase 3), `capture-performance-audit.md` | `capture-performance-audit.sh` | `$REIMAGE_ARTIFACT_ROOT/performance-audit/pre-image-*` |
| Phase 3E | Pre-image Office stability evidence | `reimaging-guide.md` (Phase 3), `capture-office-stability-audit.md` | `watch-office-today.sh`, `capture-workload-snapshot.sh`, `capture-office-stability-baseline.sh`, `office-stability-checklist.sh --phase pre-reimage` | `$REIMAGE_ARTIFACT_ROOT/office-stability/`, `$REIMAGE_ARTIFACT_ROOT/office-stability/checklists/` |
| Phase 4A | Guide access validation (curl/jump drive) | `reimaging-guide.md`, `reimage-guide-access.md` | `bootstrap.sh`, `bin/build-jump-drive-payload.sh` | throwaway test installs only -- no `$REIMAGE_ARTIFACT_ROOT` output |
| Phase 4B | Final pre-image validation | `reimaging-guide.md`, `reimage-prep-checks.md` | `bin/reimage-checklist.sh --phase pre --artifact-root ...` | `$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/` |
| Phase 6 | Enrollment/stabilization capture | `enroll-and-stabilize.md` | `capture-enrollment.sh` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/enrollment/*` when mounted, otherwise `$REIMAGE_WORKSPACE_ROOT/enrollment/*` or `~/Desktop/post-image-artifacts/enrollment/*` |
| Phase 7 | Initial post-image checklist | `capture-initial-reimaged-system.md` | `initial-reimaged-system-checklist.sh` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/` |
| Phase 8 | Runtime/access restore helpers | `restore-runtime.md`, `restore-access.md` | targeted manual checks; no single public restore script | selective restore from `home-files-backup/` and `secrets-encrypted/` |
| Phase 9 | Git restore | `restore-git.md` | targeted manual checks; optional `bin/reimage-checklist.sh --phase post` later | repo restore state and later validation under `$REIMAGE_ARTIFACT_ROOT/reimaged-system/` |
| Phase 10 | App restore | `restore-apps.md`, `restore-intellij.md`, `restore-docker.md` | `restore-apps.sh`, `restore-intellij.sh`, `restore-docker.sh` | restore-planning notes under `$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/` plus app restore from `app-settings-backup/` and `secrets-encrypted/` |
| Phase 11 | Post-image system inventory evidence | `capture-system-inventory.md` | `capture-system-inventory.sh` | `$REIMAGE_ARTIFACT_ROOT/system-inventory/post-image-*` |
| Phase 11 | Post-image company-managed inventory evidence | `capture-managed-inventory.md` | `capture-managed-inventory.sh --phase post-image` | `$REIMAGE_ARTIFACT_ROOT/managed-inventory/post-image-*` |
| Phase 11 | Post-image performance evidence | `capture-performance-audit.md` | `capture-performance-audit.sh` | `$REIMAGE_ARTIFACT_ROOT/performance-audit/post-image-*` |
| Phase 11 | Post-image Office stability evidence | `capture-office-stability-audit.md` | `capture-office-stability-baseline.sh`, `office-stability-checklist.sh --phase post-reimage` | `$REIMAGE_ARTIFACT_ROOT/office-stability/post-reimage-*`, `$REIMAGE_ARTIFACT_ROOT/office-stability/checklists/` |
| Phase 12 | Final post-image validation | `capture-validated-reimaged-system.md` | `bin/reimage-checklist.sh --phase post` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists/` |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Reference-Vault Script Layout

Current preferred script layout:

```text
<repo-root>/
├── .internal/
│   ├── artifact-config.sh
│   ├── git/
│   │   ├── stage-ignored-files.sh
│   │   ├── stage-selected-patterns.py
│   │   ├── capture-repo-audit.sh
│   │   └── collect-gitignore-superset.sh
│   └── load-reimage-config.sh
├── bin/
│   ├── backup-apps.sh
│   ├── backup-repos.sh
│   ├── backup-home.sh
│   ├── backup-docker-settings.sh
│   ├── backup-intellij-scratches-consoles.sh
│   ├── reimage-checklist.sh
│   └── capture-size-audit.sh
├── workflows/
│   └── mac/
│       └── reimage/
│           └── scripts/
│               ├── capture-managed-inventory.sh
│               ├── capture-office-stability-baseline.sh
│               ├── capture-workflow-snapshot.sh
│               ├── backup-time-machine.sh
│               ├── capture-time-machine.sh
│               ├── capture-performance-audit.sh
│               ├── capture-system-inventory.sh
│               ├── capture-workload-snapshot.sh
│               ├── create-secrets-dmg.sh
│               ├── stage-cert-keychain.sh
│               ├── prepare-artifact-root.py
│               ├── office-stability-checklist.sh
│               ├── initial-reimaged-system-checklist.sh
│               ├── capture-enrollment.sh
│               ├── restore-apps.sh
│               ├── restore-intellij.sh
│               ├── restore-docker.sh
│               ├── watch-office-today.sh
│               └── helpers/
│                   ├── apps/
│                   └── git/
└── reimaging-scripts-guide.md
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## External Backup Artifact Layout

Recommended generated artifact layout under the prepared external data/artifact `$REIMAGE_ARTIFACT_ROOT`:

```text
$REIMAGE_ARTIFACT_ROOT/
├── app-settings-backup/
│   ├── chrome/
│   ├── docker/
│   ├── intellij/
│   ├── obsidian/
│   ├── postman/
│   ├── raycast/
│   └── vscode/
├── reimage-prep-checks/
├── repo-audit-reports/
├── gitignore-superset/
├── home-files-backup/
├── office-stability/
├── performance-audit/
├── secrets-encrypted/
│   ├── certs/
│   ├── chrome/
│   ├── cli-credentials/
│   ├── cloud/
│   ├── docker/
│   ├── extra-secrets-certs-review/
│   ├── git/
│   ├── gnupg/
│   ├── intellij/
│   ├── kube/
│   ├── licenses/
│   ├── package-managers/
│   ├── postman/
│   ├── raycast/
│   └── ssh/
├── staged-ignored-files/
│   ├── live/
│   ├── dryrun/
│   └── dryrun-filtered/
├── workflow-snapshot/
│   ├── reimage-workflow-docs/
│   └── pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/
│       └── logs/
├── system-inventory/
├── time-machine/
└── reimaged-system/
    ├── enrollment/
    ├── checklists/
    ├── initial-reimaged-system-YYYYMMDD-HHMMSS/
    ├── time-machine/
    ├── restarts/
    └── restore-notes/
```

Do not copy active `*.sh` or `*.py` helper scripts into this artifact tree unless IT explicitly requests script copies as evidence.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 1 Preparation Entrypoint

`prepare-artifact-root.py` is the public Phase 1 entrypoint. It keeps the longer `reimage.env` rewrite logic out of the Markdown guide while leaving the overall sequence in `prepare-artifact-root.md`, and it reads `.internal/artifact-config.sh` (renamed from `artifact-config.sh`) when Phase 1 needs the shared expected backup-folder layout.

Use it only when `prepare-artifact-root.md` tells you to:

```text
init-reimage-env  -> write the starter resolved values into reimage.env after copying reimage.env.example
upsert-env        -> write resolved Git root values, resolved BACKUP_ROOT values, or a renamed final BACKUP_ROOT back into reimage.env
```

This helper does not replace Phase 1. The drive checks, shell validation, root creation, and directory layout still belong to `prepare-artifact-root.md` and must be followed in order.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Pre-Image Backup Automation

Run pre-image backup scripts from:

```bash
cd "$FRACTOGENESIS_HOME"  
chmod +x scripts/*.sh scripts/*.py
```

### Size Audit

Run before copying large folders:

```bash
./scripts/capture-size-audit.sh
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 2A Git Repository Backups

```bash
./scripts/backup-git-repository.sh --backup-root "$REIMAGE_ARTIFACT_ROOT"
./scripts/backup-git-repository.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --selected-dry-run
./scripts/backup-git-repository.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --selected-filtered-dry-run
./scripts/backup-git-repository.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --selected-copy
```

Then review the generated Git audit report, mark selected ignored-file patterns, update the exclude list, and use the later entrypoint modes from `backup-repos.md`.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 2B Local Files Backup

```bash
./scripts/backup-local-files.sh --external-only
# Optional OneDrive copy after confirming ONEDRIVE_ROOT points at ~/Library/CloudStorage/OneDrive-AcmeGroup:
# ./scripts/backup-local-files.sh --onedrive-only
```

Primary output:

```text
$REIMAGE_ARTIFACT_ROOT/local-files/
```

The OneDrive copy, when used, still requires manual sync verification later in Phase 4B using `reimage-prep-checks.md`.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 2C Backup Apps

`backup-apps.md` owns the Phase 2C app backup flow. `backup-apps.sh` is the single-script path; it prepares the standard app folders, runs the Docker helper when applicable, captures the local VS Code fallback, writes `app-settings-backup/MANIFEST.md`, and can also generate the optional candidate-review bundle when you add `--candidate-review`.

Preferred Phase 2C run:

```bash
./scripts/backup-apps.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --open
```

Optional candidate-review pass in the same script:

```bash
./scripts/backup-apps.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --candidate-review --open
```

Common destinations:

```text
$REIMAGE_ARTIFACT_ROOT/app-backups/MANIFEST.md
$REIMAGE_ARTIFACT_ROOT/app-backups/candidate-review/app-backup-candidates-YYYYMMDD-HHMMSS/
$REIMAGE_ARTIFACT_ROOT/app-backups/docker/
$REIMAGE_ARTIFACT_ROOT/app-backups/vscode/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker/config.json, if staged
$REIMAGE_ARTIFACT_ROOT/app-backups/chrome/bookmarks_YYYYMMDD-HHMMSS.html
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/Chrome Passwords*.csv, if exported
$REIMAGE_ARTIFACT_ROOT/app-backups/postman/collections/
$REIMAGE_ARTIFACT_ROOT/app-backups/postman/environments-redacted/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/, for secret-bearing exports
$REIMAGE_ARTIFACT_ROOT/app-backups/raycast/, if used
$REIMAGE_ARTIFACT_ROOT/app-backups/obsidian/, if used
```

If Docker `config.json`, Chrome password CSVs, secret-bearing Postman exports, or Raycast secret exports are staged, rerun Phase 2E before final validation.

Docker-only rerun through the main Phase 2C entrypoint:

```bash
./scripts/backup-apps.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --docker-only
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 2C IntelliJ Detail

```bash
./scripts/backup-apps.sh \
  --backup-root "$REIMAGE_ARTIFACT_ROOT" \
  --intellij-workspace-root ~/path/to/projects
```

Manual sign-off still required: export IntelliJ settings ZIP through the IntelliJ UI.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 2D Certificate and Keychain Staging

The certificate/Keychain staging workflow is manual, but it now has its own public entrypoint:

```bash
./scripts/stage-cert-keychain.sh
```

Manual staging destinations:

```text
$REIMAGE_ARTIFACT_ROOT/public-certs/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/extra-secrets-certs-review/
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 2E Encrypted DMG Secrets Backup

```bash
./scripts/create-secrets-dmg.sh
```

Manual sign-off still required: save password in LastPass, mount and verify the DMG, confirm manual Chrome/Postman secret exports are included if staged, then remove temporary loose plaintext copies only after validation succeeds. For Postman cleanup, do not remove the whole `secrets-encrypted/postman/` folder when `postman/environments/` and `postman/README.md` were not included in the DMG.

Postman-safe cleanup pattern:

```bash
POSTMAN_SECRET_ROOT="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman"

if [[ -d "$POSTMAN_SECRET_ROOT" ]]; then
  find "$POSTMAN_SECRET_ROOT" -mindepth 1 -maxdepth 1 \
    ! -name 'environments' \
    ! -name 'README.md' \
    -exec rm -rf {} +
fi
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 2F Time Machine Backup and Status Capture

Use `capture-time-machine.sh` for read-only Time Machine captures:

```bash
# Full pre-backup evidence bundle.
./scripts/capture-time-machine.sh pre-run --open

# Optional focused APFS destination-volume verification after Time Machine is stopped.
./scripts/capture-time-machine.sh verify-volume --open

# Final Time Machine checklist after the backup and any optional verification are complete.
./scripts/capture-time-machine.sh final --open
```

`pre-run` writes the timestamped bundle under:

```text
$REIMAGE_ARTIFACT_ROOT/time-machine/pre-image-time-machine-status-YYYYMMDD-HHMMSS/
├── README.md
├── time-machine-pre-run.md
├── time-machine-status.md
└── raw/
```

`time-machine-pre-run.md` intentionally keeps the older minimal layout:

```text
# Time Machine Pre-Run Snapshot
Generated: <date>

## Destination
## Latest Backup
## Backup List
## Exclusions
```

`final` writes the checklist directly under `$REIMAGE_ARTIFACT_ROOT/time-machine/`:

```text
$REIMAGE_ARTIFACT_ROOT/time-machine/final-time-machine-checklist-YYYYMMDD-HHMMSS.md
```

The final checklist auto-fills Time Machine completion, targeted latest backup visibility, selected external data-volume exclusion, pre-run bundle presence, completion evidence presence, optional destination-volume verification, and optional targeted checksum evidence when present. It leaves human-only rows such as UI spot-check and final evidence review as `TODO`.

Use `backup-time-machine.sh` only for runtime Time Machine operations:

```bash
./scripts/backup-time-machine.sh start
./scripts/backup-time-machine.sh monitor --interval 300
./scripts/backup-time-machine.sh complete --open

# Optional runtime checks after completion.
./scripts/backup-time-machine.sh verify-latest --mount-if-needed --open
./scripts/backup-time-machine.sh unmount-latest
./scripts/backup-time-machine.sh compare --open
./scripts/backup-time-machine.sh compare --compare-path /Users/$(whoami)/Development/documentation/reference-vault --open
./scripts/backup-time-machine.sh logs --start "YYYY-MM-DD HH:MM:SS" --end "YYYY-MM-DD HH:MM:SS" --open
```

The completion artifact intentionally does not embed noisy Time Machine logs. It prints a recommended `logs` command when log evidence is needed.

The runtime script can eject the volumes after validation:

```bash
./scripts/backup-time-machine.sh eject --physical-disk disk4
```

Replace `disk4` with the current physical disk identifier from `diskutil list external`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Separate Capture Script Reference

Detailed pre/post evidence capture manual rows and templates now live in the owning guides:

```text
capture-system-inventory.md
capture-performance-audit.md
capture-office-stability-audit.md
capture-initial-reimaged-system.md
capture-validated-reimaged-system.md
restore-intellij.md
restore-apps.md
backup-intellij.md
```

Use those guides from the phase sections in `reimaging-guide.md` when you need human-only sign-off rows or a fillable template after reviewing the generated evidence.

This scripts guide remains the broader map for all backup, evidence, validation, restore, and checklist scripts.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Pre-Image Capture Automation

Phase 3 captures can be run before or after the backup sub-phases. Any captures you choose to run must be completed before Phase 4 final pre-image validation and should be repeated post-image where comparison is useful.

All pre-image captures are optional. Phase 3A is the lightweight workflow snapshot capture; run it when you want the current reimage workflow docs and restore reference bundle preserved on the external root. If you run only one system-state capture, run the system inventory capture. Installed apps, Homebrew, and shell-state ownership now belong with the system inventory capture rather than the workflow snapshot capture. Add the others when you need performance comparison evidence, Office stability evidence, or a precise inventory of company-managed software and policy.

### Phase 3A Capture Workflow Snapshot

```bash
./scripts/capture-workflow-snapshot.sh \
  --backup-root "$REIMAGE_ARTIFACT_ROOT" \
  --open
```

The workflow snapshot capture writes one timestamped workflow snapshot bundle per run:

```text
$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/
```

It is safe to rerun. Existing filled IT confirmation copies are preserved under the stable manual area.

Quick validation:

```bash
WORKFLOW_SNAPSHOT_CAPTURE="$(find "$REIMAGE_ARTIFACT_ROOT/workflow-snapshot" -maxdepth 1 -type d -name 'pre-image-workflow-snapshot-*' -print 2>/dev/null | sort | tail -1)"

printf 'Using workflow snapshot capture: %s\n' "$WORKFLOW_SNAPSHOT_CAPTURE"
test -f "$WORKFLOW_SNAPSHOT_CAPTURE/README.md" && echo "PASS: workflow snapshot README captured"
test -d "$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/reimage-workflow-docs" && echo "PASS: workflow docs snapshot captured"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 3B Pre-Image System Inventory Capture

```bash
./scripts/capture-system-inventory.sh
```

This is the active capture home for:

```text
installed applications
Homebrew inventory
shell state
```

Post-image comparison:

```bash
./scripts/capture-system-inventory.sh
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 3C Pre-Image Company-Managed Inventory Capture

```bash
./scripts/capture-managed-inventory.sh
```

This writes a timestamped bundle under:

```text
$REIMAGE_ARTIFACT_ROOT/managed-inventory/pre-image-YYYYMMDD-HHMMSS/
```

If you want a matching post-image comparison bundle later, rerun it with a different phase label:

```bash
./scripts/capture-managed-inventory.sh --phase post-image
```

Use it when you want a more precise record of company-managed apps, package receipts, MDM profiles, launch agents/daemons, system extensions, and managed preference payloads before erase or after reimage. See `capture-managed-inventory.md` (not yet migrated) for the individual commands and interpretation notes.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 3D Pre-Image Performance Audit Capture

Clean-boot / quiet baseline:

```bash
./scripts/capture-performance-audit.sh \
  --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" \
  --phase pre-image \
  --scenario clean-boot \
  --sample-count 6 \
  --sample-interval 30
```

For this scenario, Docker Desktop may be intentionally stopped. The script records Docker daemon reachability under `docker/docker-daemon-state.txt` and skips daemon-dependent Docker commands when the daemon is unavailable, so expected clean-boot Docker messages do not become `logs/errors.log` failures.

Normal workload pre-image:

```bash
./scripts/capture-performance-audit.sh \
  --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" \
  --phase pre-image \
  --scenario normal-workload \
  --sample-count 6 \
  --sample-interval 30
```

Post-image, use the same scenario name as the matching pre-image bundle:

```bash
./scripts/capture-performance-audit.sh \
  --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" \
  --phase post-image \
  --scenario normal-workload \
  --sample-count 6 \
  --sample-interval 30
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 3E Pre-Image Office Stability Capture

Start or continue the watcher:

```bash
caffeinate -dimsu scripts/watch-office-today.sh
```

Pre-image Office baseline and checklist:

```bash
./scripts/capture-office-stability-baseline.sh \
  --phase pre-reimage \
  --backup-root "$REIMAGE_ARTIFACT_ROOT"

./scripts/office-stability-checklist.sh \
  --phase pre-reimage \
  --backup-root "$REIMAGE_ARTIFACT_ROOT"
```

Post-image Office comparison, or symptom recurrence:

```bash
./scripts/capture-office-stability-baseline.sh \
  --phase post-reimage \
  --backup-root "$REIMAGE_ARTIFACT_ROOT"

./scripts/office-stability-checklist.sh \
  --phase post-reimage \
  --backup-root "$REIMAGE_ARTIFACT_ROOT"
```

Office stability details belong in `capture-office-stability-audit.md`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Post-Image Evidence Capture Automation

Post-image evidence captures are documented in Phase 11 of `reimaging-guide.md`. Use the same scripts as Phase 3 — run under the same approximate workload as the matching pre-image scenario.

Common command set:

```bash
./scripts/capture-system-inventory.sh

./scripts/capture-performance-audit.sh \
  --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" \
  --phase post-image \
  --scenario normal-workload \
  --sample-count 6 \
  --sample-interval 30

./scripts/capture-office-stability-baseline.sh \
  --phase post-reimage \
  --backup-root "$REIMAGE_ARTIFACT_ROOT"
```

For post-image clean-boot comparisons, keep Docker stopped only if the matching pre-image clean-boot capture also kept Docker stopped. For Docker/container comparisons, run a separate `normal-workload` or `active-dev` scenario with Docker Desktop started.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Validation Automation

Phase 4B uses the unified pre-image validator. The post-image flow now has a dedicated initial-checklist entrypoint for Phase 7 and a dedicated final-validation entrypoint for Phase 12.

### Phase 4B Final Pre-Image Validation

```bash
./bin/reimage-checklist.sh \
  --phase pre \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --open
```

The report is written to:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/reimage-checklist-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/latest-reimage-checklist.txt
```

Use the generated report as the primary Phase 4B checklist. Do not proceed to Phase 5 until `FAIL` items are resolved. Then use `reimage-prep-checks.md` only for the remaining manual sign-off rows.

For workflow-snapshot checks, the validator should discover the newest timestamped bundle directly from `workflow-snapshot/pre-image-workflow-snapshot-*`. VS Code local fallback state is validated from `app-settings-backup/vscode/`.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 7 Initial Reimaged System Checklist

```bash
./scripts/initial-reimaged-system-checklist.sh \
  --backup-root "$REIMAGE_ARTIFACT_ROOT" \
  --open
```

The generated bundle is written under:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 12 Post-Image Final Validation

```bash
./bin/reimage-checklist.sh \
  --phase post \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --workspace-root ~/path/to/projects \
  --open
```

Pass `--internal-url URL` to also check VPN/Zscaler reachability for a corporate URL.

The generated report is written under:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists/reimage-checklist-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists/latest-reimage-checklist.txt
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Manual Captures That Remain Manual

Scripts cannot fully prove these items:

```text
IT confirmed the approved reimage method
LastPass vault is accessible
DMG password was saved and verified
Chrome bookmarks exported or Chrome sync intentionally used
Chrome password CSV included in the DMG if exported
VS Code Settings Sync state recorded
OneDrive/iCloud sync actually settled
Postman collections and protected environments imported correctly
Outlook/OneNote remained open during real use
IntelliJ projects and run configs work in the UI
Docker Desktop resource settings are correct in the UI
Corporate Java TLS works against internal systems
Display layout, keyboard, mouse, and audio are correct
```

Use the manual tables in the owning phase guides and save completed copies beside the generated evidence bundle when you need a human-only record.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Common Run Order

```bash
cd "$FRACTOGENESIS_HOME"   # REIMAGE_ROOT is retired -- see reimaging-scripts-guide.md Script Source and Artifact Rules
chmod +x scripts/*.sh scripts/*.py

# Phase 1 — preparation
# Follow prepare-artifact-root.md first. That guide uses prepare-artifact-root.py
# when reimage.env needs resolved values written back to disk.

# Phase 2 — backups
./scripts/capture-size-audit.sh
./scripts/backup-git-repository.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --root ~/path/to/projects --root ~/path/to/docs
./scripts/backup-local-files.sh --external-only
# Optional: run the OneDrive copy only after ONEDRIVE_ROOT resolves to ~/Library/CloudStorage/OneDrive-AcmeGroup.
# ./scripts/backup-local-files.sh --onedrive-only
./scripts/backup-apps.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --open
./scripts/backup-apps.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --intellij-workspace-root ~/path/to/projects
# Manual/app-controlled follow-up: Chrome, Postman, Raycast, Obsidian, and any other app exports that backup-apps.sh cannot complete.
# Phase 2D certificate/Keychain staging:
# ./scripts/stage-cert-keychain.sh
# Phase 2E final DMG after all manual secret staging:
# If Chrome password CSVs, secret-bearing Postman exports, optional app secret exports,
# IntelliJ HTTP Client env files, or cert/Keychain material were staged, run secrets DMG after that.
./scripts/create-secrets-dmg.sh

# Phase 2F — Time Machine last before validation
./scripts/capture-time-machine.sh pre-run --open
./scripts/backup-time-machine.sh start
./scripts/backup-time-machine.sh monitor --interval 300
./scripts/backup-time-machine.sh complete --open
# Optional:
# ./scripts/capture-time-machine.sh verify-volume --open
# ./scripts/backup-time-machine.sh verify-latest --mount-if-needed --open
# ./scripts/backup-time-machine.sh unmount-latest
# ./scripts/backup-time-machine.sh compare --open
./scripts/capture-time-machine.sh final --open

# Phase 3 — captures and reference snapshots
./scripts/capture-workflow-snapshot.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --open
./scripts/capture-system-inventory.sh
./scripts/capture-performance-audit.sh --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" --phase pre-image --scenario clean-boot --sample-count 6 --sample-interval 30
./scripts/capture-performance-audit.sh --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" --phase pre-image --scenario normal-workload --sample-count 6 --sample-interval 30
./scripts/capture-office-stability-baseline.sh --phase pre-reimage --backup-root "$REIMAGE_ARTIFACT_ROOT"
./scripts/office-stability-checklist.sh --phase pre-reimage --backup-root "$REIMAGE_ARTIFACT_ROOT"

# Phase 4 — final pre-image validation
# Manual sign-off reference for the remaining rows in this phase: reimage-prep-checks.md
./bin/reimage-checklist.sh --phase pre --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

Post-image (Phases 6–12):

```bash
cd "$FRACTOGENESIS_HOME"   # REIMAGE_ROOT is retired -- see reimaging-scripts-guide.md Script Source and Artifact Rules

# Phase 6 — enroll and stabilize capture
./scripts/capture-enrollment.sh --open

# Phase 7 — initial checklist
./scripts/initial-reimaged-system-checklist.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --open

# Phase 10 — restore helpers
./scripts/restore-apps.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --open
# Optional focused helpers:
# ./scripts/restore-intellij.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --open
# ./scripts/restore-docker.sh --backup-root "$REIMAGE_ARTIFACT_ROOT" --open

# Phase 11 — post-image evidence captures
./scripts/capture-system-inventory.sh
./scripts/capture-performance-audit.sh --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" --phase post-image --scenario normal-workload --sample-count 6 --sample-interval 30
./scripts/capture-office-stability-baseline.sh --phase post-reimage --backup-root "$REIMAGE_ARTIFACT_ROOT"
./scripts/office-stability-checklist.sh --phase post-reimage --backup-root "$REIMAGE_ARTIFACT_ROOT"

# Phase 12 — final post-image validation
./bin/reimage-checklist.sh \
  --phase post \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --workspace-root ~/path/to/projects \
  --open
```

[[#Table of Contents|⬆ Back to Table of Contents]]
