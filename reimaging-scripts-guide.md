[[reimaging-guide#Workflow Map and Reference Guides|← Back to Mac Reimaging Guide]]

# Reimaging Scripts Guide

**Last updated:** 2026-08-13

Use this as the script index for the Mac reimage workflow. The Markdown runbooks explain the workflow; this guide maps each phase to the scripts that generate backups, evidence captures, and validation checklists.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#Script Source and Artifact Rules|Script Source and Artifact Rules]]
- [[#Phase-to-Script Map|Phase-to-Script Map]]
- [[#Reference-Vault Script Layout|Reference-Vault Script Layout]]
- [[#Reference-Vault Script Layout|Reference-Vault Script Layout]]
- [[#Phase 1 Preparation Entrypoint|Phase 1 Preparation Entrypoint]]
- [[#Pre-Image Backup Automation|Pre-Image Backup Automation]]
    - [[#Size Audit|Size Audit]]
    - [[#Phase 2A Git Repository Backups|Phase 2A Git Repository Backups]]
    - [[#Phase 2B Local Files Backup|Phase 2B Local Files Backup]]
    - [[#Phase 2D Backup Apps|Phase 2D Backup Apps]]
    - [[#Phase 2D IntelliJ Detail|Phase 2D IntelliJ Detail]]
    - [[#Phase 3A Certificate and Keychain Staging|Phase 3A Certificate and Keychain Staging]]
    - [[#Phase 3B Loose Secret Sweep|Phase 3B Loose Secret Sweep]]
    - [[#Phase 3C Encrypted DMG Secrets Backup|Phase 3C Encrypted DMG Secrets Backup]]
    - [[#Phase 5 Time Machine Backup and Status Capture|Phase 5 Time Machine Backup and Status Capture]]
- [[#Separate Capture Script Reference|Separate Capture Script Reference]]
- [[#Pre-Image Capture Automation|Pre-Image Capture Automation]]
    - [[#Phase 4A Capture Toolkit Snapshot|Phase 4A Capture Toolkit Snapshot]]
    - [[#Phase 4B Pre-Image System Inventory Capture|Phase 4B Pre-Image System Inventory Capture]]
    - [[#Phase 2C Pre-Image Company-Managed Inventory Capture|Phase 2C Pre-Image Company-Managed Inventory Capture]]
    - [[#Phase 4C Pre-Image Performance Audit Capture|Phase 4C Pre-Image Performance Audit Capture]]
    - [[#Phase 4D Pre-Image Office Stability Capture|Phase 4D Pre-Image Office Stability Capture]]
- [[#Post-Image Evidence Capture Automation|Post-Image Evidence Capture Automation]]
- [[#Validation Automation|Validation Automation]]
    - [[#Phase 6B Final Pre-Image Validation|Phase 6B Final Pre-Image Validation]]
    - [[#Phase 9 First-Boot Record|Phase 9 First-Boot Record]]
    - [[#Phase 11B Repository Restore|Phase 11B Repository Restore]]
    - [[#Phase 12 Restore-Apps Plan-Note|Phase 12 Restore-Apps Plan-Note]]
    - [[#Phase 12 Restore-IntelliJ Plan-Note|Phase 12 Restore-IntelliJ Plan-Note]]
    - [[#Phase 12 Restore-Docker Plan-Note|Phase 12 Restore-Docker Plan-Note]]
    - [[#Phase 14 Post-Image Final Validation|Phase 14 Post-Image Final Validation]]
- [[#Environment and Repository Utilities|Environment and Repository Utilities]]
- [[#Manual Captures That Remain Manual|Manual Captures That Remain Manual]]
- [[#Common Run Order|Common Run Order]]

> In Obsidian, click links in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

The workflow separates three different kinds of work:

| Kind | Meaning | Where it belongs |
|---|---|---|
| Backup | Files or state needed to restore the machine. | Phase 2 subphases and `$REIMAGE_ARTIFACT_ROOT/<backup-topic>/`. |
| Capture | Read-only snapshots and reference bundles used for comparison, troubleshooting, or workflow recovery. | Phase 4 subphases and `$REIMAGE_ARTIFACT_ROOT/system-inventory`, `performance-audit`, `office-stability`. |
| Validation | Generated checklist that proves prior steps were completed as much as a script can prove. | Phase 6 pre-image validation, Phase 9 initial post-image validation, and Phase 14 final post-image validation. |

This matters because Phase 4 captures are stored on the backup drive, but they are not restore backups. They can be run any time before the reimage as long as they are complete before the final pre-image validation.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Script Source and Artifact Rules

| Item | Location | Rule |
|---|---|---|
| Working directory | Repository root (`$FRACTOGENESIS_HOME`) | Run every script command from here; `cd` there once per session. Runbooks assume this (see [[reimaging-guide#Core Assumptions\|Core Assumptions]]) and do not repeat `cd "$FRACTOGENESIS_HOME"` before each command. |
| Script source of truth | `workflows/mac/reimage/scripts/` | Keep in Git. Do not treat the external backup copy as authoritative. |
| Pre-image backup artifacts | `$REIMAGE_ARTIFACT_ROOT/<topic>/` | Store under the prepared external data/artifact `$REIMAGE_ARTIFACT_ROOT`. |
| Pre-image evidence artifacts | `$REIMAGE_ARTIFACT_ROOT/system-inventory/`, `$REIMAGE_ARTIFACT_ROOT/performance-audit/`, `$REIMAGE_ARTIFACT_ROOT/office-stability/`, `$REIMAGE_ARTIFACT_ROOT/time-machine/` | Generated captures only. |
| Post-image evidence | `$REIMAGE_ARTIFACT_ROOT/post-image/<topic>/` and matching pre/post evidence folders | Store generated post-image checklists and captures beside pre-image evidence. |
| Secrets | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-*.dmg` | Store in encrypted DMGs. Remove temporary loose secret copies after validation. |
| Time Machine backups | `/Volumes/AppleBackups` | Keep separate from manual evidence. Exclude the external backup drive from Time Machine. |

Standard variables are set once in `reimage.env` and loaded by every script automatically — see [[reimaging-guide#Phase 1 — Prepare the External Artifact Root|Phase 1 — Prepare the External Artifact Root]] (the standalone "Shared Setup and Externalized Configuration" section this used to point to no longer exists as its own heading; reimage.env setup is now covered there and in `prepare-artifact-root.md`):

Example entries, to adjust to your environment. `reimage.env` holds **resolved
absolute values only** — no `${VAR:-...}`, no `$HOME/...`, and no `$(...)`
expressions, since those can go stale or fail under `set -u`.

`REIMAGE_ROOT` is retired: scripts self-locate from their own position in the
repo (see `REPO_ROOT` in `prepare-artifact-root.py`), and `FRACTOGENESIS_HOME`,
set via `.envrc` rather than `reimage.env`, is the shell-level equivalent when
one is needed.

```bash
export REIMAGE_ARTIFACT_ROOT="/Volumes/<external-data-volume-name>/reimage-<asset-or-host>-<start-date>-open"
export ONEDRIVE_ROOT="/Users/<user>/Library/CloudStorage/OneDrive-AcmeGroup"
export ONEDRIVE_DEST_SUBDIR="reimage-<asset-or-host>-<start-date>-open"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase-to-Script Map

| Phase | Purpose | Markdown guide | Primary script(s) | Generated output |
|---|---|---|---|---|
| Phase 1 | Prepare external artifact root | `reimaging-guide.md`, `prepare-artifact-root.md` | `prepare-artifact-root.py` plus guide-owned shell checks and directory creation | `reimage.env`, `$REIMAGE_ARTIFACT_ROOT/` structure, `$REIMAGE_ARTIFACT_ROOT/reimage-confirmation/it-reimage-confirmation-*.md` |
| Phase 2A | Git repository backups | `backup-repos.md` | `backup-repos.sh` (public entrypoint), Git helpers under `scripts/helpers/git/` | `$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/`, `$REIMAGE_ARTIFACT_ROOT/gitignore-superset/`, `$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live/*` |
| Phase 2B | Local files backup | `backup-home.md` | `backup-home.sh` | `$REIMAGE_ARTIFACT_ROOT/home-files-backup/` |
| Phase 2D | Backup apps | `backup-apps.md` | `backup-apps.sh` (public entrypoint), `helpers/apps/backup-docker-settings.sh` and `helpers/apps/backup-intellij-scratches-consoles.sh` (internal helpers), plus app-controlled/manual exports for other apps | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/` plus matching `secrets-encrypted/` folders |
| Phase 2D detail | IntelliJ companion flow | `backup-intellij.md` | `backup-apps.sh` (public IntelliJ path), `helpers/apps/backup-intellij-scratches-consoles.sh` (internal helper) | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/` |
| Phase 3A | Certificate and Keychain staging | `stage-certs-keychain.md` | `stage-certs-keychain.sh` | `$REIMAGE_ARTIFACT_ROOT/public-certs/`, `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/`, `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/extra-secrets-certs-review/` |
| Phase 3C | Encrypted secrets backup | `create-secrets-dmg.md` | `create-secrets-dmg.sh` | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-*.dmg` |
| Phase 5 | Time Machine backup/status | `run-time-machine.md` | `run-time-machine.sh`, `record-time-machine-evidence.sh` | `/Volumes/AppleBackups`, `$REIMAGE_ARTIFACT_ROOT/time-machine/`, `final-time-machine-checklist-*.md` |
| Phase 4A | Toolkit snapshot capture | `capture-toolkit-snapshot.md` | `capture-toolkit-snapshot.sh` | `$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/pre-image-toolkit-snapshot-*/`, `$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/latest-docs/` |
| Phase 4B | Pre-image system inventory evidence | `reimaging-guide.md` (Phase 4) | `capture-system-inventory.sh` | `$REIMAGE_ARTIFACT_ROOT/system-inventory/` |
| Phase 2C | Pre-image company-managed inventory evidence | `reimaging-guide.md` (Phase 4), `capture-managed-inventory.md` | `capture-managed-inventory.sh` | `$REIMAGE_ARTIFACT_ROOT/managed-inventory/` |
| Phase 4C | Pre-image performance evidence | `reimaging-guide.md` (Phase 4), `capture-performance-audit.md` | `capture-performance-audit.sh` | `$REIMAGE_ARTIFACT_ROOT/performance-audit/pre-image-*` |
| Phase 4D | Pre-image Office stability evidence | `reimaging-guide.md` (Phase 4), `capture-office-stability.md` | `watch-office-today.sh `, `capture-workload-snapshot.sh`, `capture-office-stability.sh`, `office-stability-checklist.sh --phase pre-reimage` | `$REIMAGE_ARTIFACT_ROOT/office-stability/`, `$REIMAGE_ARTIFACT_ROOT/office-stability/checklists/` |
| Phase 6A | Guide access validation (curl/jump drive) | `reimaging-guide.md`, `reimage-guide-access.md` | `bootstrap.sh`, `bin/build-jump-drive-payload.sh` | throwaway test installs only -- no `$REIMAGE_ARTIFACT_ROOT` output |
| Phase 6B | Final pre-image validation | `reimaging-guide.md`, `reimage-prep-checks.md` | `bin/reimage-checklist.sh --phase pre --artifact-root ...` | `$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/` |
| Phase 10A | Restore-phase entry record | `restore-runtime.md` | `bin/record-restore-prereqs.sh` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/boundaries/runs/*-entry-*/` |
| Phase 10A | Restore-phase exit record | `restore-runtime.md` | `bin/record-restore-exit.sh` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/boundaries/runs/*-exit-*/` |
| Phase 10A | Restored-state comparison | `restore-runtime.md` | `bin/compare-restored-state.sh` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/comparisons/runs/*-inventory-diff-*/` |
| Phase 10B | Restored-state comparison | `restore-access.md` | `bin/compare-restored-state.sh --runbook restore-access` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/comparisons/runs/*-inventory-diff-*/` |
| Phase 10B | Phase delta | `restore-access.md` | `bin/record-restore-state.sh --runbook restore-access --point after` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/state/runs/*-after-*/delta.md` |
| Phase 8 | Toolkit install and shell environment | `enroll-and-stabilize.md` | `bootstrap.sh`, `bin/init-shell-env.sh` | `~/.zprofile` block; `$FRACTOGENESIS_HOME/reimage.env` restored from the jump drive |
| Phase 8 | Enrollment/stabilization record | `enroll-and-stabilize.md` | `record-enrollment.sh` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts/runs/enroll-and-stabilize-<point>-*/`, falling back to `$REIMAGE_WORKSPACE_ROOT/` or `~/Desktop/reimaged-system-artifacts/` |
| Phase 8 | Entry and exit boundary | `enroll-and-stabilize.md` | `record-enrollment.sh --context entry\|exit` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/boundaries/runs/enroll-and-stabilize-{entry,exit}-*/` |
| Phase 9 | Restart comparison | `verify-reimaged-system.md` | `record-reimaged-system.sh --context diff` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/comparisons/runs/verify-reimaged-system-restart-diff-*/` |
| Phase 9 | Entry and exit boundary | `verify-reimaged-system.md` | `record-reimaged-system.sh --context entry\|exit` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/boundaries/runs/verify-reimaged-system-{entry,exit}-*/` |
| any | Index relocated or migrated runs | `verify-reimaged-system.md` | `reindex-artifact-runs.sh` | rewrites `<category>/MANIFEST.md` and `<category>/official/` |
| any | Record a decision no capture can hold | `restore-access.md`, `restore-home.md` | `record-decision.sh` | appends to `$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/decisions.md`; `compare-restored-state.sh` reads it back and marks the covered rows **decided** |
| Phase 9 | First-boot record twice around a stabilization restart | `verify-reimaged-system.md` | `record-reimaged-system.sh` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/` |
| Phase 10 | Runtime/access restore helpers | `restore-runtime.md`, `restore-access.md` | targeted manual checks; no single public restore script | selective restore from `home-files-backup/` and `secrets-encrypted/` |
| Phase 11A | Git identity restore | `restore-git.md` | targeted manual writes to `~/.gitconfig`, `~/.ssh/config`, and the personal-root override; no toolkit script | consumes `secrets-encrypted/ssh/` and `secrets-encrypted/git/` restored in Phase 10B |
| Phase 11B | Repository restore | `restore-repos.md` | `restore-repos.sh` | `$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/post-image-restore-YYYYMMDD-HHMMSS/`; consumes pre-image `repo-audit-reports/runs/pre-image-*/repos.tsv` and `staged-ignored-files/live/<label>/` |
| Phase 12 | App restore | `restore-apps.md`, `restore-intellij.md`, `restore-docker.md` | `restore-apps.sh`, `restore-intellij.sh`, `restore-docker.sh` | restore-planning notes under `$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/` plus app restore from `app-settings-backup/` and `secrets-encrypted/` |
| Phase 13 | Post-image system inventory evidence | `capture-system-inventory.md` | `capture-system-inventory.sh` | `$REIMAGE_ARTIFACT_ROOT/system-inventory/runs/post-image-*` |
| Phase 13 | Post-image company-managed inventory evidence | `capture-managed-inventory.md` | `capture-managed-inventory.sh --phase post-image` | `$REIMAGE_ARTIFACT_ROOT/managed-inventory/runs/post-image-*` |
| Phase 13 | Post-image performance evidence | `capture-performance-audit.md` | `capture-performance-audit.sh` | `$REIMAGE_ARTIFACT_ROOT/performance-audit/post-image-*` |
| Phase 13 | Post-image Office stability evidence | `capture-office-stability.md` | `capture-office-stability.sh`, `office-stability-checklist.sh --phase post-reimage` | `$REIMAGE_ARTIFACT_ROOT/office-stability/post-reimage-*`, `$REIMAGE_ARTIFACT_ROOT/office-stability/checklists/` |
| Phase 14 | Final post-image validation | `reimaged-system-checks.md` | `bin/reimage-checklist.sh --phase post` | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists/` |
| Phase 16 | Post-image Time Machine backup | `run-time-machine.md` | `run-time-machine.sh`, `record-time-machine-evidence.sh` | `/Volumes/AppleBackups`, `$REIMAGE_ARTIFACT_ROOT/time-machine/` |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Reference-Vault Script Layout

Current preferred script layout:

```text
<repo-root>/
├── <repo-root>/
│   ├── <repo-root>/
│   │   ├── .internal/
│   │   │   ├── artifact-config.sh
│   │   │   ├── git/
│   │   │   │   ├── stage-ignored-files.sh
│   │   │   │   ├── stage-selected-patterns.py
│   │   │   │   ├── capture-repo-audit.sh
│   │   │   │   └── collect-gitignore-superset.sh
│   │   │   └── load-reimage-config.sh
│   │   ├── bin/
│   │   │   ├── backup-apps.sh
│   │   │   ├── backup-repos.sh
│   │   │   ├── backup-home.sh
│   │   │   ├── backup-docker-settings.sh
│   │   │   ├── backup-intellij-scratches-consoles.sh
│   │   │   ├── reimage-checklist.sh
│   │   │   └── report-size-audit.sh
│   │   ├── workflows/
│   │   │   └── mac/
│   │   │       └── reimage/
│   │   │           └── scripts/
│   │   │               ├── capture-office-stability.sh
│   │   │               ├── prepare-artifact-root.py
│   │   │               ├── record-reimaged-system.sh
│   │   │               ├── record-enrollment.sh
│   │   │               ├── record-decision.sh
│   │   │               ├── reindex-artifact-runs.sh
│   │   │               ├── restore-repos.sh
│   │   │               └── helpers/
│   │   │                   ├── apps/
│   │   │                   └── git/
│   │   └── reimaging-scripts-guide.md
│   └── bin/
│       ├── capture-managed-inventory.sh
│       ├── create-secrets-dmg.sh
│       └── stage-certs-keychain.sh
└── bin/
    ├── capture-toolkit-snapshot.sh
    ├── run-time-machine.sh
    ├── record-time-machine-evidence.sh
    ├── capture-performance-audit.sh
    ├── capture-system-inventory.sh
    ├── capture-workload-snapshot.sh
    ├── office-stability-checklist.sh
    ├── restore-apps.sh
    ├── restore-docker.sh
    ├── restore-intellij.sh
    └── watch-office-today.sh 
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 1 Preparation Entrypoint

`prepare-artifact-root.py` is the public Phase 1 entrypoint. It keeps the longer `reimage.env` rewrite logic out of the Markdown guide while leaving the overall sequence in `prepare-artifact-root.md`, and it reads `.internal/artifact-config.sh` (renamed from `artifact-config.sh`) when Phase 1 needs the shared expected backup-folder layout.

Use it only when `prepare-artifact-root.md` tells you to:

```text
init-reimage-env  -> write the starter resolved values into reimage.env after copying reimage.env.example
upsert-env        -> write or update any resolved KEY=VALUE in reimage.env. Replaces a matching
                     `export KEY=` line, and APPENDS the key when the file does not carry it yet --
                     which is why a key another runbook owns is absent from reimage.env.example
                     rather than sitting in it blank. See references/environment-variable-reference.md
```

This helper does not replace Phase 1. The drive checks, shell validation, root creation, and directory layout still belong to `prepare-artifact-root.md` and must be followed in order.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Pre-Image Backup Automation

Run pre-image backup scripts from:

```bash
chmod +x bin/*.sh bin/*.py
```

### Size Audit

Run before copying large folders:

```bash
./bin/report-size-audit.sh
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 2A Git Repository Backups

```bash
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT"
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-dry-run
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-filtered-dry-run
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --selected-copy
```

Then review the generated Git audit report, mark selected ignored-file patterns, update the exclude list, and use the later entrypoint modes from `backup-repos.md`.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 2B Local Files Backup

```bash
./bin/backup-home.sh --external-only
```

Optionally copy to OneDrive as well, but only after confirming `ONEDRIVE_ROOT`
points at the real sync directory under `~/Library/CloudStorage/`:

```bash
./bin/backup-home.sh --onedrive-only
```

Primary output:

```text
$REIMAGE_ARTIFACT_ROOT/local-files/
```

The OneDrive copy, when used, still requires manual sync verification later in Phase 6B using `reimage-prep-checks.md`.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 2D Backup Apps

`backup-apps.md` owns the Phase 2D app backup flow. `backup-apps.sh` is the single-script path; it prepares the standard app folders, runs the Docker helper when applicable, captures the local VS Code fallback, writes `app-settings-backup/MANIFEST.md`, and can also generate the optional candidate-review bundle when you add `--candidate-review`.

Preferred Phase 2D run:

```bash
./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

Optional candidate-review pass in the same script:

```bash
./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --candidate-review --open
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

If Docker `config.json`, Chrome password CSVs, secret-bearing Postman exports, or Raycast secret exports are staged, rerun Phase 3B and then Phase 3C before final validation.

Docker-only rerun through the main Phase 2D entrypoint:

```bash
./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --docker-only
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 2D IntelliJ Detail

```bash
./bin/backup-apps.sh \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --intellij-projects-root ~/path/to/projects
```

Manual sign-off still required: export IntelliJ settings ZIP through the IntelliJ UI.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 3A Certificate and Keychain Staging

The certificate/Keychain staging workflow is manual, but it now has its own public entrypoint:

```bash
./bin/stage-certs-keychain.sh
```

Manual staging destinations:

```text
$REIMAGE_ARTIFACT_ROOT/public-certs/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/extra-secrets-certs-review/
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 3B Loose Secret Sweep

Two entrypoints, split so the reporting side is always safe to run. Both read the same `SECRET_SHAPES` from shared config.

```bash
./bin/report-loose-secrets.sh
./bin/stage-loose-secrets.sh
./bin/stage-loose-secrets.sh --apply
./bin/report-loose-secrets.sh --context pre-image-stage-loose-secrets-after
```

`report-loose-secrets.sh` reports only and never writes to what it scans.
`stage-loose-secrets.sh` is a dry run unless given `--apply`, which moves the
findings inside the encryption boundary. The final line re-reports, so the run
carries its own before and after.

Outputs:

```text
$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/staged-loose/
```

Run after Phase 3A and before Phase 3C: 3A can leave candidates of its own, and 3C encrypts only what is already inside `secrets-encrypted/`.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 3C Encrypted DMG Secrets Backup

```bash
./bin/create-secrets-dmg.sh
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

### Phase 5 Time Machine Backup and Status Capture

Use `record-time-machine-evidence.sh` for read-only Time Machine captures:

The full pre-backup evidence bundle:

```bash
./bin/record-time-machine-evidence.sh pre-run --open
```

A focused APFS destination-volume verification, optional, and only after Time
Machine has been stopped:

```bash
./bin/record-time-machine-evidence.sh verify-volume --open
```

The final checklist, once the backup and any optional verification are complete:

```bash
./bin/record-time-machine-evidence.sh final --open
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

Use `run-time-machine.sh` only for runtime Time Machine operations:

```bash
./bin/run-time-machine.sh start
./bin/run-time-machine.sh monitor --interval 300
./bin/run-time-machine.sh complete --open
```

Optional runtime checks, after completion:

```bash
./bin/run-time-machine.sh verify-latest --mount-if-needed --open
./bin/run-time-machine.sh unmount-latest
./bin/run-time-machine.sh compare --open
./bin/run-time-machine.sh compare --compare-path /Users/$(whoami)/Development/documentation/reference-vault --open
./bin/run-time-machine.sh logs --start "YYYY-MM-DD HH:MM:SS" --end "YYYY-MM-DD HH:MM:SS" --open
```

The completion artifact intentionally does not embed noisy Time Machine logs. It prints a recommended `logs` command when log evidence is needed.

The runtime script can eject the volumes after validation:

```bash
./bin/run-time-machine.sh eject --physical-disk disk4
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
verify-reimaged-system.md
reimaged-system-checks.md
restore-intellij.md
restore-apps.md
backup-intellij.md
```

Use those guides from the phase sections in `reimaging-guide.md` when you need human-only sign-off rows or a fillable template after reviewing the generated evidence.

This scripts guide remains the broader map for all backup, evidence, validation, restore, and checklist scripts.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Pre-Image Capture Automation

Phase 4 captures can be run before or after the backup sub-phases. Any captures you choose to run must be completed before Phase 6 final pre-image validation and should be repeated post-image where comparison is useful.

All pre-image captures are optional. Phase 4A is the lightweight toolkit snapshot capture; run it when you want the current reimage workflow docs and restore reference bundle preserved on the external root. If you run only one system-state capture, run the system inventory capture. Installed apps, Homebrew, and shell-state ownership now belong with the system inventory capture rather than the toolkit snapshot capture. Add the others when you need performance comparison evidence, Office stability evidence, or a precise inventory of company-managed software and policy.

### Phase 4A Capture Toolkit Snapshot

```bash
./bin/capture-toolkit-snapshot.sh \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --open
```

The toolkit snapshot capture writes one timestamped toolkit snapshot bundle per run:

```text
$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/pre-image-toolkit-snapshot-YYYYMMDD-HHMMSS/
```

It is safe to rerun. Existing filled IT confirmation copies are preserved under the stable manual area.

Quick validation:

```bash
TOOLKIT_SNAPSHOT_CAPTURE="$(find "$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot" -maxdepth 1 -type d -name 'pre-image-toolkit-snapshot-*' -print 2>/dev/null | sort | tail -1)"

printf 'Using toolkit snapshot capture: %s\n' "$TOOLKIT_SNAPSHOT_CAPTURE"
test -f "$TOOLKIT_SNAPSHOT_CAPTURE/README.md" && echo "PASS: toolkit snapshot README captured"
test -d "$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/latest-docs" && echo "PASS: workflow docs snapshot captured"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 4B Pre-Image System Inventory Capture

```bash
./bin/capture-system-inventory.sh
```

This is the active capture home for:

```text
installed applications
Homebrew inventory
shell state
```

Post-image comparison:

```bash
./bin/capture-system-inventory.sh
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 2C Pre-Image Company-Managed Inventory Capture

```bash
./bin/capture-managed-inventory.sh
```

This writes a timestamped bundle under:

```text
$REIMAGE_ARTIFACT_ROOT/managed-inventory/runs/pre-image-YYYYMMDD-HHMMSS/
```

If you want a matching post-image comparison bundle later, rerun it with a different phase label:

```bash
./bin/capture-managed-inventory.sh --phase post-image
```

Use it when you want a more precise record of company-managed apps, package receipts, MDM profiles, launch agents/daemons, system extensions, and managed preference payloads before erase or after reimage. See `capture-managed-inventory.md` (not yet migrated) for the individual commands and interpretation notes.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 4C Pre-Image Performance Audit Capture

Clean-boot / quiet baseline:

```bash
./bin/capture-performance-audit.sh \
  --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" \
  --phase pre-image \
  --scenario clean-boot \
  --sample-count 6 \
  --sample-interval 30
```

For this scenario, Docker Desktop may be intentionally stopped. The script records Docker daemon reachability under `docker/docker-daemon-state.txt` and skips daemon-dependent Docker commands when the daemon is unavailable, so expected clean-boot Docker messages do not become `logs/errors.log` failures.

Normal workload pre-image:

```bash
./bin/capture-performance-audit.sh \
  --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" \
  --phase pre-image \
  --scenario normal-workload \
  --sample-count 6 \
  --sample-interval 30
```

Post-image, use the same scenario name as the matching pre-image bundle:

```bash
./bin/capture-performance-audit.sh \
  --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" \
  --phase post-image \
  --scenario normal-workload \
  --sample-count 6 \
  --sample-interval 30
```

[[#Table of Contents|⬆ Back to Table of Contents]]

Quantitative rollups are produced separately from the capture itself, by a Python helper that reads the mac-memory-health output the capture leaves behind:

```bash
PERF_RUN="replace-with-the-performance-audit-run-directory"
python3 ./bin/generate-performance-rollup-summary.py --input "$PERF_RUN"
```

It is owned by `capture-performance-audit.md`; run it after a capture, and again post-image so the two rollups can be compared.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 4D Pre-Image Office Stability Capture

Start or continue the watcher:

```bash
caffeinate -dimsu scripts/watch-office-today.sh
```

Pre-image Office baseline and checklist:

```bash
./bin/capture-office-stability.sh \
  --phase pre-reimage \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT"

./bin/office-stability-checklist.sh \
  --phase pre-reimage \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT"
```

Post-image Office comparison, or symptom recurrence:

```bash
./bin/capture-office-stability.sh \
  --phase post-reimage \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT"

./bin/office-stability-checklist.sh \
  --phase post-reimage \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT"
```

Office stability details belong in `capture-office-stability.md`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Post-Image Evidence Capture Automation

Post-image evidence captures are documented in Phase 13 of `reimaging-guide.md`. Use the same scripts as Phase 4 — run under the same approximate workload as the matching pre-image scenario.

Common command set:

```bash
./bin/capture-system-inventory.sh

./bin/capture-performance-audit.sh \
  --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" \
  --phase post-image \
  --scenario normal-workload \
  --sample-count 6 \
  --sample-interval 30

./bin/capture-office-stability.sh \
  --phase post-reimage \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT"
```

For post-image clean-boot comparisons, keep Docker stopped only if the matching pre-image clean-boot capture also kept Docker stopped. For Docker/container comparisons, run a separate `normal-workload` or `active-dev` scenario with Docker Desktop started.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Validation Automation

Phase 6B uses the unified pre-image validator. The post-image flow now has a dedicated initial-checklist entrypoint for Phase 9 and a dedicated final-validation entrypoint for Phase 14.

### Phase 6B Final Pre-Image Validation

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

Use the generated report as the primary Phase 6B checklist. Do not proceed to Phase 7 until `FAIL` items are resolved. Then use `reimage-prep-checks.md` only for the remaining manual sign-off rows.

For toolkit-snapshot checks, the validator should discover the newest timestamped bundle directly from `toolkit-snapshot/pre-image-toolkit-snapshot-*`. VS Code local fallback state is validated from `app-settings-backup/vscode/`.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 9 First-Boot Record

```bash
./bin/record-reimaged-system.sh --open
```

The generated bundle is written under:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 11B Repository Restore

```bash
./bin/restore-repos.sh --open
```

Reads the latest pre-image `repo-audit-reports/runs/pre-image-*/repos.tsv`, classifies each repo's current state on disk, and emits reviewable `clone-commands.sh` and `rsync-ignored-files.sh` action files. The operator reviews and runs them selectively; the script does not autonomously clone. Pass `--apply-ignored-files` to interactively rsync `staged-ignored-files/live/<label>/` into each cloned working tree.

The generated bundle is written under:

```text
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/post-image-restore-YYYYMMDD-HHMMSS/
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/post-image-restore.txt
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 12 Restore-Apps Plan-Note

```bash
./bin/restore-apps.sh --open
```

Surveys the Phase 2D `app-settings-backup/` subtree plus the encrypted-secrets sources that feed Postman, IntelliJ, Docker, and licenses, marks each as `PRESENT` / `MISSING`, and emits a plan-note with the ordered restore sequence. The rows the operator ticks go to a separate sign-off, so regenerating the plan-note never discards an answer. Installs nothing on its own; the operator ticks the sign-off by hand while following [[restore-apps|restore-apps.md]].

The generated plan-note and its sign-off are written under:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-apps-plan-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimaged-system/sign-offs/restore-apps-YYYYMMDD-HHMMSS.md
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 12 Restore-IntelliJ Plan-Note

```bash
./bin/restore-intellij.sh --open
```

Surveys the Phase 2D `app-settings-backup/intellij/` subtree (per-version `config-copy/`, `scratches-and-consoles/`, `manifests/`, plus `manual-settings-export/IntelliJ-settings-*.zip` and `project-metadata/`) and the encrypted-secrets sources that hold HTTP Client `*.env.json` files. Marks each as `PRESENT` / `MISSING`, points at the most recent settings ZIP for `File → Manage IDE Settings → Import Settings`, and emits an IntelliJ-specific sign-off checklist. Install nothing on its own; the operator ticks the checklist by hand while following [[restore-intellij|restore-intellij.md]].

The generated plan-note and its sign-off are written under:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-intellij-plan-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimaged-system/sign-offs/restore-intellij-YYYYMMDD-HHMMSS.md
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 12 Restore-Docker Plan-Note

```bash
./bin/restore-docker.sh --open
```

Surveys the Phase 2D `app-settings-backup/docker/` subtree (settings-store, daemon.json, contexts/, image/container/compose inventories) plus the encrypted `secrets-encrypted/docker/config.json`, checks whether Docker Desktop is installed and whether the daemon is currently reachable on the reimaged Mac, and emits a Docker-specific sign-off checklist that covers Desktop install, resource settings, registry credentials, and the local container fleet (Redis, RabbitMQ, Elasticsearch + Kibana, MarkLogic).

The generated plan-note and its sign-off are written under:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-docker-plan-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimaged-system/sign-offs/restore-docker-YYYYMMDD-HHMMSS.md
```

[[#Table of Contents|⬆ Back to Table of Contents]]

### Phase 14 Post-Image Final Validation

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

## Environment and Repository Utilities

Not phase steps. These check the setup the phases depend on, and none of them writes workflow artifacts.

```bash
./bin/setup-reimage-env.sh
./bin/check-reimage-env.sh
./bin/verify-artifact-config.sh
./bin/verify-doc-paths.sh
./bin/verify-runbook-structure.sh
```

| Script | The question it answers |
|---|---|
| `setup-reimage-env.sh` | Bootstrap — creates `reimage.env` before anything else exists. |
| `check-reimage-env.sh` | Does `reimage.env` match this effort, or is it left over from the last one? |
| `verify-artifact-config.sh` | Are the artifact-config fragments present and syntactically valid? |
| `verify-doc-paths.sh` | Do the repository paths named in the governance docs still exist? |
| `verify-runbook-structure.sh` | Do the runbooks still follow the structural house rules? |

`verify-artifact-config.sh` prints a `Selected by:` line naming which fragment directory actually won — the per-machine workspace copy or the committed templates. A run that says "committed templates" verified the generic set, not yours.

`verify-doc-paths.sh` is repository maintenance rather than reimage work: run it after moving or renaming anything the docs point at.

`verify-runbook-structure.sh` is the same kind of maintenance, aimed at a failure the other checks cannot see. Paths resolve and anchors resolve in a runbook whose steps were never enumerated, so a document written before a house rule existed keeps passing everything until someone reads it beside a conforming one. It also catches unbalanced code fences — a bulk edit that eats a newline welds a `` ``` `` to the sentence after it, and from there to the end of the file Obsidian renders prose as code.

[[#Table of Contents|⬆ Back to Table of Contents]]

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

Two sequences, pre-image and post-image. Every command assumes the shell is at
the repository root with `reimage.env` loaded.

```bash
cd "$FRACTOGENESIS_HOME"
chmod +x bin/*.sh bin/*.py
```

**Phase 1 — preparation.** Follow `prepare-artifact-root.md` first; it uses
`prepare-artifact-root.py` when `reimage.env` needs resolved values written back
to disk. There is no command to run here.

**Phase 2 — backups.**

```bash
./bin/report-size-audit.sh
./bin/backup-repos.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --root ~/path/to/projects --root ~/path/to/docs
./bin/backup-home.sh --external-only
./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --intellij-projects-root ~/path/to/projects
```

Optional, and only after `ONEDRIVE_ROOT` resolves to the real sync directory:

```bash
./bin/backup-home.sh --onedrive-only
```

Then the manual, app-controlled exports `backup-apps.sh` cannot complete —
Chrome, Postman, Raycast, Obsidian and any others. Phase 3A certificate and
Keychain staging follows:

```bash
./bin/stage-certs-keychain.sh
```

**Phase 3C — the secrets DMG, after all manual staging is done.** If Chrome
password CSVs, secret-bearing Postman exports, optional app secret exports,
IntelliJ HTTP Client env files, or cert/Keychain material were staged, this has
to run after that staging rather than before it:

```bash
./bin/create-secrets-dmg.sh
```

**Phase 5 — Time Machine, last before validation.**

```bash
./bin/record-time-machine-evidence.sh pre-run --open
./bin/run-time-machine.sh start
./bin/run-time-machine.sh monitor --interval 300
./bin/run-time-machine.sh complete --open
./bin/record-time-machine-evidence.sh final --open
```

Optional verification between `complete` and `final`:

```bash
./bin/record-time-machine-evidence.sh verify-volume --open
./bin/run-time-machine.sh verify-latest --mount-if-needed --open
./bin/run-time-machine.sh unmount-latest
./bin/run-time-machine.sh compare --open
```

**Phase 4 — captures and reference snapshots.**

```bash
./bin/capture-toolkit-snapshot.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
./bin/capture-system-inventory.sh
./bin/capture-performance-audit.sh --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" --phase pre-image --scenario clean-boot --sample-count 6 --sample-interval 30
./bin/capture-performance-audit.sh --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" --phase pre-image --scenario normal-workload --sample-count 6 --sample-interval 30
./bin/capture-office-stability.sh --phase pre-reimage --artifact-root "$REIMAGE_ARTIFACT_ROOT"
./bin/office-stability-checklist.sh --phase pre-reimage --artifact-root "$REIMAGE_ARTIFACT_ROOT"
```

**Phase 6 — final pre-image validation.** `reimage-prep-checks.md` is the manual
sign-off reference for the rows this does not cover:

```bash
./bin/reimage-checklist.sh --phase pre --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

Post-image (Phases 8–14). The boundary recorders that bracket each phase are not
listed here — each runbook's Step 0 and close-out own those.

**Phase 8 — enroll and stabilize.**

```bash
./bin/record-enrollment.sh --context pre-restart
./bin/record-enrollment.sh --context post-restart
```

**Phase 9 — first-boot record, once either side of the stabilization restart.**

```bash
./bin/record-reimaged-system.sh --context pre-restart
./bin/record-reimaged-system.sh --context post-restart
```

**Phase 11B — repository restore**, after Phase 11A has done the Git identity
plumbing:

```bash
./bin/restore-repos.sh --open
```

Optionally, interactively rsync reviewed kept-ignored files into each cloned
repository:

```bash
./bin/restore-repos.sh --apply-ignored-files --open
```

**Phase 12 — restore helpers.**

```bash
./bin/restore-apps.sh --open
./bin/restore-intellij.sh --open
./bin/restore-docker.sh --open
```

**Phase 13 — post-image evidence captures.**

```bash
./bin/capture-system-inventory.sh
./bin/capture-performance-audit.sh --output "$REIMAGE_ARTIFACT_ROOT/performance-audit" --phase post-image --scenario normal-workload --sample-count 6 --sample-interval 30
./bin/capture-office-stability.sh --phase post-reimage --artifact-root "$REIMAGE_ARTIFACT_ROOT"
./bin/office-stability-checklist.sh --phase post-reimage --artifact-root "$REIMAGE_ARTIFACT_ROOT"
```

**Phase 14 — final post-image validation.**

```bash
./bin/reimage-checklist.sh \
  --phase post \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --workspace-root ~/path/to/projects \
  --open
```

[[#Table of Contents|⬆ Back to Table of Contents]]
