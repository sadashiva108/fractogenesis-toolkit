# Mac Reimaging Guide

This is the canonical top-level guide for the Mac reimage workflow.

---
## Table of Contents

- [[#Purpose|Purpose]]
- [[#Core Assumptions|Core Assumptions]]
- [[#Workflow Map and Reference Guides|Workflow Map and Reference Guides]]
    - [[#Pre-Image|Pre-Image]]
    - [[#Reimaging Process|Reimaging Process]]
    - [[#Post-Image|Post-Image]]
- [[#Backup Strategy|Backup Strategy]]
- [[#Restore Strategy|Restore Strategy]]
- [[#Phase 0 — Confirm the Reimage Plan with IT|Phase 0 — Confirm the Reimage Plan with IT]]
- [[#Phase 1 — Prepare the External Artifact Root|Phase 1 — Prepare the External Artifact Root]]
- [[#Phase 2 — Pre-Image Backups|Phase 2 — Pre-Image Backups]]
    - [[#Phase 2A — Backup Git Repositories|Phase 2A — Backup Git Repositories]]
    - [[#Phase 2B — Backup Local Files|Phase 2B — Backup Local Files]]
    - [[#Phase 2C — Backup Apps|Phase 2C — Backup Apps]]
    - [[#Phase 2D — Certificate and Keychain Staging|Phase 2D — Certificate and Keychain Staging]]
    - [[#Phase 2E — Create Secrets DMG|Phase 2E — Create Secrets DMG]]
    - [[#Phase 2F — Backup Time Machine|Phase 2F — Backup Time Machine]]
- [[#Phase 3 — Pre-Image Captures|Phase 3 — Pre-Image Captures]]
    - [[#Phase 3A — Capture Workflow Snapshot|Phase 3A — Capture Workflow Snapshot]]
    - [[#Phase 3B — Pre-Image System Inventory Capture|Phase 3B — Pre-Image System Inventory Capture]]
    - [[#Phase 3C — Pre-Image Company-Managed Inventory Capture|Phase 3C — Pre-Image Company-Managed Inventory Capture]]
    - [[#Phase 3D — Pre-Image Performance Audit Capture|Phase 3D — Pre-Image Performance Audit Capture]]
    - [[#Phase 3E — Pre-Image Office Stability Capture|Phase 3E — Pre-Image Office Stability Capture]]
- [[#Phase 4 — Reimage Preparation Checks|Phase 4 — Reimage Preparation Checks]]
- [[#Phase 5 — Reimage / Erase Procedure|Phase 5 — Reimage / Erase Procedure]]
- [[#Phase 6 — Enroll and Stabilize|Phase 6 — Enroll and Stabilize]]
- [[#Phase 7 — Initial Captures and Sanity Checks|Phase 7 — Initial Captures and Sanity Checks]]
- [[#Phase 8 — Restore Runtime Environment|Phase 8 — Restore Runtime Environment]]
    - [[#Phase 8A — Restore Runtime Libraries|Phase 8A — Restore Runtime Libraries]]
    - [[#Phase 8B— Restore Access|Phase 8B — Restore Access]]
- [[#Phase 9 — Restore Git|Phase 9 — Restore Git]]
- [[#Phase 10 — Restore Apps|Phase 10 — Restore Apps]]
- [[#Phase 11 — Post-Image Captures|Phase 11 — Post-Image Captures]]
    - [[#Phase 11A — Capture Workflow Snapshot|Phase 11A — Capture Workflow Snapshot]]
    - [[#Phase 11B — Post-Image System Inventory Capture|Phase 11B —Post-Image System Inventory Capture]]
    - [[#Phase 11C — Post-Image Company-Managed Inventory Capture|Phase 11C — Post-Image Company-Managed Inventory Capture]]
    - [[#Phase 11D — Post-Image Performance Audit Capture|Phase 11D — Post-Image Performance Audit Capture]]
    - [[#Phase 11E — Post-Image Office Stability Capture|Phase 11E — Post-Image Office Stability Capture]]
- [[#Phase 12 — Reimaged System Checks|Phase 12 — Reimaged System Checks]]
- [[#Phase 13 — Restore Local Files|Phase 13 — Restore Local Files]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---
## Purpose

Use this guide as the practical sequence for preparing, reimaging, restoring, and validating a managed Mac laptop.

> This repo holds only the reimage runbooks and scripts, split out from the personal `reference-vault` repo referenced later in this guide (Phase 9, Restore Strategy) — that's a separate, private repo for general notes, unrelated to reimaging. For how to get this repo's contents onto a freshly reimaged Mac before Git/SSH access exists, see the [README's Quickstart](README.md#quickstart).

---
## Migration Status

This repo is being built phase by phase, not all at once. Links to phases below marked 🔲 point to files that don't exist here yet on purpose — check `reference-vault`'s copy of this workflow instead until a phase flips to ✅. Flip the box when a phase's runbook + scripts land here with working links and a passing gist/jump-drive test.

- 🔲 Phase 0 — Confirm the Reimage Plan with IT
- 🔲 Phase 1 — Prepare the External Artifact Root (scripts migrated and tested: `prepare-artifact-root.py`, `artifact-config.sh`; `prepare-artifact-root.md` rework in progress)
- 🔲 Phase 2 — Pre-Image Backups (2A–2F)
- 🔲 Phase 3 — Pre-Image Captures (3A–3E)
- 🔲 Phase 4 — Reimage Preparation Checks
- 🔲 Phase 5 — Reimage / Erase Procedure
- 🔲 Phase 6 — Enroll and Stabilize
- 🔲 Phase 7 — Initial Captures and Sanity Checks
- 🔲 Phase 8 — Restore Runtime Environment (8A–8B)
- 🔲 Phase 9 — Restore Git
- 🔲 Phase 10 — Restore Apps
- 🔲 Phase 11 — Post-Image Captures (11A–11E)
- 🔲 Phase 12 — Reimaged System Checks
- 🔲 Phase 13 — Restore Local Files

[[#Table of Contents|⬆ Back to Table of Contents]]

The goals are:

- document the approved IT handoff or self-service reimage steps before starting disruptive work
- avoid losing local-only source code, Git branches, stashes, untracked files, ignored files, and credentials
- preserve selected local config files such as `.env.local`, certificates, and local application settings
- preserve IntelliJ Scratches, Consoles, IDE settings, plugins, and HTTP Client files
- preserve enough workstation inventory to rebuild quickly
- optionally capture a pre-image performance baseline when slow-system behavior is part of the reason for the reimage
- optionally capture Microsoft Office stability evidence when Outlook or OneNote closure/update issues are part of the reason for the reimage
- restore and validate the development environment in a controlled order

[[#Table of Contents|⬆ Back to Table of Contents]]

---
## Core Assumptions

This guide assumes:

- A developer using a company-managed Apple silicon Mac laptop, typically a MacBook Pro or similar model enrolled through company MDM / Intune / Company Portal.
- A local `reimage.env` file created from `reimage.env.example`, then updated with the machine-specific resolved paths used by the scripts.
- Company-managed components may include:
    - Intune / Company Portal enrollment
    - Microsoft 365 apps and helpers
    - OneDrive
    - Teams
    - Defender
    - CrowdStrike Falcon
    - Zscaler
    - company-pushed Wi-Fi policies
    - certificate profiles and policies
    - FileVault policies
    - TCC policies
    - login-item policies
    - system-extension policies
    - browser policies
    - web-filtering policies

  Treat those apps, profiles, agents, daemons, and managed preferences as IT-owned state; do not remove Office caches, Outlook profiles, OneNote caches, Office licensing data, security/network agents, management profiles, or other managed-app data unless IT explicitly asks.
- Credential-bearing files should be stored on the external drive and preferably encrypted before placing any copy in cloud storage.

[[#Table of Contents|⬆ Back to Table of Contents]]


---
## Workflow Map and Reference Guides

Follow **this guide** in order. Then, when you reach a phase that points to another guide, follow that guide as the next step in the sequence. The linked files below are part of the expected workflow, not optional references or alternate starting points.

### Pre-Image

| Category | Purpose | Primary Docs |
|---|---|---|
| Reimage plan confirmation | Capture the IT-approved erase/reinstall method, ownership, timing, and restore constraints before backups begin. | Phase 0 and `templates/it-reimage-confirmation-template.md`. |
| Preparation and backup drive setup | Prepare the external backup/capture volume, create `$REIMAGE_ARTIFACT_ROOT`, create the standard subdirectories, set up `reimage.env`, and establish the generated-artifact layout used by the rest of the workflow. | Phase 1 in this guide. |
| Backups | Preserve files that must be restored after reimage. | Phase 2 sections, `backup-file-reference.md`, and backup-specific guides. |
| Validation | Decide whether it is safe to proceed with erase and reimage. | Phase 4 in this guide. |

For the full list of phase guides used in this stage, in the order they are typically reached, see [Backup File Reference — Phase Guide Reference](references/backup-file-reference.md#phase-guide-reference).

### Reimaging Process

| Category | Purpose | Primary Docs |
|---|---|---|
| Reimage / erase procedure | Perform the erase, reinstall, or IT-led reimage using the approved plan from Phase 0. | Phase 5 in this guide and the IT-approved reimage plan captured earlier in the workflow. |

Phase guides used in this stage, in the order they are typically reached:

| File | Purpose |
|---|---|
| `reimaging-guide.md` | Canonical Phase 5 sequence for the actual erase/reinstall process. |
| `templates/it-reimage-confirmation-template.md` | Source template for the IT-approved plan that governs the actual reimage path. |

### Post-Image

| Category | Purpose | Primary Docs |
|---|---|---|
| Enroll and stabilize | Complete enrollment, base managed-app install, required updates, and the first stabilization restart before restore work. | Phase 6 in this guide and `enroll-and-stabilize.md`. |
| Initial captures and sanity checks | Reconnect the backup root, run the initial post-image checklist twice around a restart, and confirm the rebuilt Mac is basically usable. | Phase 7 in this guide and `capture-initial-reimaged-system.md`. |
| Runtime and access restore | Restore the toolchain, shell/CLI config, certificates, SSH, credentials, and activation material that the later phases depend on. | Phase 8 in this guide, `restore-runtime.md`, and `restore-access.md`. |
| Git restore | Restore Git identities, SSH routing, `reference-vault`, and core repositories. | Phase 9 in this guide and `restore-git.md`. |
| App restore | Restore daily apps through the umbrella app phase, with dedicated sub-runbooks for IntelliJ and Docker. | Phase 10 in this guide, `restore-apps.md`, `restore-intellij.md`, and `restore-docker.md`. |
| Post-image evidence captures | Capture the post-image comparison evidence for system inventory, optional managed-state verification, performance, and Office stability. | Phase 11 in this guide plus `capture-system-inventory.md`, `capture-managed-inventory.md`, `capture-performance-audit.md`, and `capture-office-stability-audit.md`. |
| Final validation and late local-file restore | Validate the rebuilt Mac, then restore bulk local files only after the rebuild is already trusted. | Phase 12 and Phase 13 in this guide, `capture-validated-reimaged-system.md`, and `restore-local-files.md`. |

For the full list of phase guides used in this stage, in the order they are typically reached, see [Restore File Reference — Phase Guide Reference](references/restore-file-reference.md#phase-guide-reference).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Backup Strategy

Keep the top-level rule simple: do not rely on one backup method, do not store secrets loose in cloud storage, keep active scripts in Git rather than `$REIMAGE_ARTIFACT_ROOT`, avoid deleting managed Office/MDM data unless IT explicitly instructs it, and capture evidence before reopening Outlook or OneNote after unexpected closure.

Full strategy, destination guidance, and safety rules: [Backup Strategy Guide](references/backup-strategy-guide.md).

If you plan to collect optional performance evidence for several days or weeks before the actual backup window, start those captures locally under `REIMAGE_WORKSPACE_ROOT` first and copy the finalized artifacts into `$REIMAGE_ARTIFACT_ROOT` later. This avoids missing the evidence window just because the external backup drive is not mounted yet.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Restore Strategy

The `reference-vault` repo, Obsidian, and Git/SSH access are all gone right after the reimage — but Phase 6 onward assumes you can read this guide and its linked runbooks. This repo is fetchable without any of those (see the README Quickstart) precisely so this dependency doesn't block early restore phases. `reference-vault` itself stays gone until Phase 9 restores Git/SSH properly — nothing before that needs it.

Full strategy, the three-tier access model, and where to keep the cheat sheet: [Restore Strategy Guide](references/restore-strategy-guide.md).

Standalone cheat sheet to copy out to the external drive and OneDrive: [templates/bootstrap-cheatsheet.md](templates/bootstrap-cheatsheet.md).

[[#Table of Contents|⬆ Back to Table of Contents]]

---
## Phase 0 — Confirm the Reimage Plan with IT

Captures the IT-approved erase/reinstall method, ownership, timing, wipe expectations, and restore constraints in writing before any backup work starts. Verify the plan with **IT or the department that supports the company-managed asset and specifically the Mac** — ask first if you don't know which team owns that support path.

Primary guide: [templates/it-reimage-confirmation-template.md](templates/it-reimage-confirmation-template.md)

Fill out a working copy of the template in a local workspace outside this repo (`$REIMAGE_WORKSPACE_ROOT/reimage-planning/`). Do not copy it into `$REIMAGE_ARTIFACT_ROOT` yet — Phase 1 copies the filled version into `$REIMAGE_ARTIFACT_ROOT/reimage-plan/` once the external root exists. See [Prepare Artifact Root](prepare-artifact-root.md) for `REIMAGE_WORKSPACE_ROOT` setup and the `copy-it-plan` command.

Primary outputs:

```text
$REIMAGE_WORKSPACE_ROOT/reimage-planning/it-reimage-confirmation-YYYYMMDD.md
$REIMAGE_ARTIFACT_ROOT/reimage-plan/it-reimage-confirmation-YYYYMMDD.md    # copied in Phase 1
```

[[#Table of Contents|⬆ Back to Table of Contents]]


---
## Phase 1 — Prepare the External Artifact Root

After the reimage plan has been confirmed, prepare the external data/artifact volume, create and verify `$REIMAGE_ARTIFACT_ROOT`, set up `reimage.env`, and create the standard generated-artifact folders.

Keep this phase concise but complete:

1. Verify the correct external backup drive is mounted, writable, has enough free space, and uses the expected volumes before any backup starts.
2. Verify `reimage.env` resolves to the intended external drive and `REIMAGE_ARTIFACT_ROOT`, not an old path or a local fallback.
3. Verify the standard folder layout exists and the current workflow docs have been copied into the backup so the same instructions travel with the artifacts.
4. Refresh the jump-drive fallback: copy `bootstrap.sh` and a current `bin/build-jump-drive-payload.sh`-built tarball onto the prepared jump drive — this is the artifact that gets this repo onto a bare reimaged Mac without needing Git/SSH. See [[#Restore Strategy|Restore Strategy]] above and Phase 6's callout for the exact commands.

Follow this phase guide: [Prepare Artifact Root](prepare-artifact-root.md).

[[#Table of Contents|⬆ Back to Table of Contents]]

---
## Phase 2 — Pre-Image Backups

This phase groups the backup work that preserves files, source-code state, secrets, IntelliJ state, and a full Time Machine copy before the Mac is erased.

The subphases can be repeated as needed, but the intended Phase 2 order is:

1. Git repository backups and selected ignored-file review.
2. Local file backup.
3. App backups: common apps first, then optional apps when they apply.
4. IntelliJ-specific backup.
5. Certificate and Keychain staging: use reviewed temporary staging folders and normalized review artifacts to prepare only the certificate/Keychain material that should feed the encrypted secrets backup.
6. Extra certificate/Keychain review, then encrypted secrets DMG after any manual secret exports, selected certificate/Keychain files, and other secret-bearing staged material are ready.
7. Time Machine backup after the backup root on the external drive has been reviewed and excluded from Time Machine.

Phase 3 capture work, including `capture-workflow-snapshot.md`, follows after these Phase 2 backups rather than inside this backup sequence.

[[#Table of Contents|⬆ Back to Table of Contents]]

---
### Phase 2A — Backup Git Repositories

Follow this phase guide: [Backup Git Repositories](backup-git-repository.md).

Preserves Git repository risk state (local-only commits, dirty repos, stashes, untracked files) and selected ignored-file backups before erase.

Primary outputs:

```text
$REIMAGE_ARTIFACT_ROOT/git-audit-reports/
$REIMAGE_ARTIFACT_ROOT/gitignore-superset/
$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-dryrun/
$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-filtered-dryrun/
$REIMAGE_ARTIFACT_ROOT/selected-ignored-files/
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---
### Phase 2B — Backup Local Files

Follow this phase guide: [Backup Local Files](backup-local-files.md).

This phase owns the plain local-file copy driven by `backup-local-files.sh`.

Use it for the authoritative pre-image copies of home-directory files, dotfiles, shell scripts, and other non-secret local config selected by `artifact-config.sh`.

Primary output:

```text
$REIMAGE_ARTIFACT_ROOT/local-files/
$REIMAGE_ARTIFACT_ROOT/local-files/dotfiles/
```

If OneDrive is enabled, this phase may also create a secondary local CloudStorage copy, but OneDrive completion is not considered proven until the Phase 4 manual sync checks from `capture-validated-reimage-prep.md` are complete.

[[#Table of Contents|⬆ Back to Table of Contents]]

---
### Phase 2C — Backup Apps

Follow this phase guide: [Backup Apps](backup-apps.md).

Preserves app-specific state for apps installed on this Mac that are worth keeping and not already covered by local-file backup, Git, sync, or company-managed reinstall. Optional apps include Docker, IntelliJ, VS Code, Raycast, and Obsidian when a local fallback backup is worth keeping. Use the app coverage map in `backup-apps.md` to decide which optional subsections apply.

IntelliJ has a dedicated companion runbook, `backup-intellij.md`, for detailed review, validation, or settings ZIP export — the normal scripted path now starts from `backup-apps.sh`.

Primary outputs:

```text
$REIMAGE_ARTIFACT_ROOT/app-backups/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/, if used
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---
### Phase 2D — Certificate and Keychain Staging

Follow this phase guide: [Stage Certificate and Keychain](stage-cert-keychain.md).

This phase owns the certificate and Keychain review/export/staging workflow before encryption. In this context, **staging** means placing reviewed files, manual Keychain exports, notes, and generated review artifacts into the correct temporary backup folders so Phase 2E can package them into the encrypted secrets DMG. The planning pass also produces normalized/deduped review tables, proposed staged-certs fragments, out-of-cert-scope secret crosswalks, and generated-noise filter evidence before anything is copied.

Primary outputs:

```text
$REIMAGE_ARTIFACT_ROOT/public-certs/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/extra-secrets-certs-review/
```

Important ordering rule: if you add any new Keychain export, `.p12` / `.pfx`, keystore, private key, or selected certificate/key candidate, rerun the Phase 2D scan/plan pass and then rerun Phase 2E so the newest consolidated secrets DMG includes those files before final validation.

[[#Table of Contents|⬆ Back to Table of Contents]]

---
### Phase 2E — Create Secrets DMG

Follow this phase guide: [Create Secrets DMG](create-secrets-dmg.md).

By Phase 2E, the expectation is that all secret material that needs to be preserved has already been intentionally staged.

A **DMG** is a macOS disk image file. In this workflow, `all-secrets-*.dmg` is the encrypted restore container that packages the reviewed secret staging folders from earlier phases.

This phase is the consolidated encrypted-secrets pass: build the final `all-secrets-*.dmg`, validate that the required staged secret material is inside the mounted DMG, and only then clean up loose plaintext staging.

[[#Table of Contents|⬆ Back to Table of Contents]]

---
### Phase 2F — Backup Time Machine

Follow this phase guide: [Backup Time Machine](backup-time-machine.md).

Run Time Machine after the other Phase 2 backup subphases are complete — by default it's the last backup action before final pre-image validation. It's the broad safety-net backup layer, separate from the manual `$REIMAGE_ARTIFACT_ROOT` artifacts on the external `Data` volume.

Time Machine destination: `/Volumes/AppleBackups`

Primary outputs:

```text
$REIMAGE_ARTIFACT_ROOT/time-machine/pre-image-time-machine-status-YYYYMMDD-HHMMSS/
```

The Time Machine status workflow automates the status table as much as possible. Manual sign-off remains for reviewing the Phase 4 sync/manual sign-off note, the external root spot-check, and final eject (see `backup-time-machine.md` — Eject the Drive Before Reimage).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 3 — Pre-Image Captures

Pre-image captures are **not backups** in the restore sense. They are read-only snapshots stored under the prepared `$REIMAGE_ARTIFACT_ROOT` so the post-image system can be compared against the pre-image state.

This section owns the **phase order**. The linked capture runbooks explain command details and output structure, and the owning runbook keeps any manual-only notes or templates for that phase.

Reference link: [[reimage-prep-evidence]]

All Phase 3 captures are optional. **Phase 3A** is the lightweight workflow snapshot capture; run it when you want the current reimage workflow docs and lightweight restore reference bundle preserved on the external root. If you run only one **system-state** capture, run **Phase 3B system inventory** because it preserves the broadest rebuild context.

If a capture needs to run for days or weeks before the broader backup phase, stage it locally under `REIMAGE_WORKSPACE_ROOT` first and then copy it into `$REIMAGE_ARTIFACT_ROOT` before Phase 4 final validation.

Use the others when they answer a specific need:

- **Phase 3A workflow snapshot** — when you want the current reimage workflow docs and lightweight restore reference bundle preserved on the external root.
- **Phase 3C company-managed inventory** — when you want a precise record of MDM-delivered apps, profiles, agents, daemons, system extensions, and managed preferences before erase.
- **Phase 3D performance audit** — when you want before/after evidence for slowness, resource pressure, or workload-specific regressions.
- **Phase 3E Office stability** — when Outlook or OneNote instability, update churn, or unexpected closures are part of the reason for the reimage.

### Recommended Pre-Image Capture Order

1. Confirm `$REIMAGE_ARTIFACT_ROOT` exists and matches your current `reimage.env`.
2. Run Phase 3A workflow snapshot capture.
3. Run Phase 3B system inventory.
4. Run Phase 3C company-managed inventory if you want a precise record of IT-managed state before erase.
5. Run Phase 3D performance audit under one or more named scenarios if performance comparison will be useful.
6. Start or continue the Office watcher if Office stability evidence is still needed.
7. Confirm the Office marker timestamp.
8. Run Phase 3E Office stability baseline and Office-specific checklist.
9. Review the generated evidence and any remaining manual rows in the owning capture runbooks before Phase 4 final validation.

Do not reset the Office marker after an incident until the incident evidence has been captured.

| Subphase | Evidence | Destination | Supporting reference | Manual notes or checklist section |
|---|---|---|---|---|
| Phase 3A | Workflow snapshot | `$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/pre-image-workflow-snapshot-*`, `$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/reimage-workflow-docs/` | capture-workflow-snapshot.md | — |
| Phase 3B | System inventory | `$REIMAGE_ARTIFACT_ROOT/system-inventory/pre-image-*` | capture-system-inventory.md | `capture-system-inventory.md` — Manual context note only when needed |
| Phase 3C | Company-managed inventory | `$REIMAGE_ARTIFACT_ROOT/managed-inventory/pre-image-*` | capture-managed-inventory.md | — |
| Phase 3D | Performance audit | `$REIMAGE_ARTIFACT_ROOT/performance-audit/pre-image-*` | capture-performance-audit.md | `capture-performance-audit.md` — Manual Observations |
| Phase 3E | Office stability | `$REIMAGE_ARTIFACT_ROOT/office-stability/pre-reimage-*` | capture-office-stability-audit.md | `capture-office-stability-audit.md` — Final Pre-Reimage Checklist |


[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Phase 3A — Capture Workflow Snapshot

Use this capture to preserve the current reimage workflow docs and the lightweight snapshot bundle that helps you follow the restore workflow later.

Follow this capture runbook: [capture-workflow-snapshot.md](capture-workflow-snapshot.md).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Phase 3B — Pre-Image System Inventory Capture

Use this capture to preserve hardware/macOS identity, installed apps, Homebrew inventory, shell state, developer tool inventory, Docker state, network, SSH, cloud, environment, and display context.

Follow this capture runbook: [capture-system-inventory.md](capture-system-inventory.md).

This is the active Phase 3 home for the older `apps/`, `homebrew/`, and `shell/` setup-note style captures.

Manual notes, if needed: [capture-system-inventory.md — Manual context note only when needed](capture-system-inventory.md#manual-context-note-only-when-needed).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Phase 3C — Pre-Image Company-Managed Inventory Capture

Run this when you want a more precise record of company-managed apps, package receipts, MDM profiles, launch agents/daemons, system extensions, and managed preference payloads before the reimage.

Follow this capture runbook: [capture-managed-inventory.md](capture-managed-inventory.md).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Phase 3D — Pre-Image Performance Audit Capture

Run this when you want before/after evidence for general Mac performance.

At minimum, capture a `normal-workload` scenario. Add `clean-boot`, `active-dev`, or `symptom-capture` only when they will help the post-image comparison.

Review the auto-filled `manual-observations.md` and `workload-reproduction-config.md` so the post-image run can match the pre-image workload as closely as possible.

Follow this capture runbook: [capture-performance-audit.md](capture-performance-audit.md).

Manual notes, if needed: [capture-performance-audit.md — Manual Observations](capture-performance-audit.md#manual-observations).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Phase 3E — Pre-Image Office Stability Capture

If you are collecting Office stability evidence, start or continue the Office watcher, then capture the structured Office baseline and checklist using that capture runbook.

If Outlook or OneNote closes unexpectedly, do not reopen either app first. Capture a workload snapshot and a fast Office baseline.

Follow this capture runbook: [capture-office-stability-audit.md](capture-office-stability-audit.md).

Manual checklist, if needed: [capture-office-stability-audit.md — Final Pre-Reimage Checklist](capture-office-stability-audit.md#final-pre-reimage-checklist).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 4 — Reimage Preparation Checks

**Phase 4 — Reimage Preparation Checks** is the final pre-erase gate that confirms the backup, capture, and staging work is complete enough to proceed safely. It brings together the results of the earlier pre-image phases so you can verify that critical Git history, local files, app backups, certificates, secrets, Time Machine state, and any chosen evidence captures are present, readable, and stored in the expected locations before the Mac is erased. The goal is to catch missing or incomplete preparation work while the original system is still available, so the reimage starts only after the recovery path and supporting evidence are in place.

Primary guide: [[capture-validated-reimage-prep|capture-validated-reimage-prep.md]]

Primary generated evidence:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/
```


### Disconnect backup media

After final verification, eject the entire external drive — it may expose multiple partitions (for example, `Data` and `AppleBackups`), and ejecting either one unmounts the whole physical drive. See `backup-time-machine.md` — Eject the Drive Before Reimage for the full command sequence and confirmation steps.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 5 — Reimage / Erase Procedure

Use the IT-approved path. Do not improvise on a managed Mac.

### Preferred managed-device path

Use this when IT says the device will be wiped or reinstalled through company process:

1. Confirm all backups are complete.
2. Eject and disconnect the external backup drive.
3. Connect to power.
4. Connect to reliable Wi-Fi or Ethernet.
5. Leave the laptop awake and unlocked if IT requires remote management.
6. Follow IT instructions for Company Portal, Intune, Self Service, MDM, or helpdesk handoff.
7. Record who initiated the reimage and when.

Record:

| Item | Value |
|---|---|
| Reimage started | `TODO` |
| Reimage initiated by | `TODO` |
| Method used | `TODO` |
| Asset tag / serial confirmed | `TODO` |
| Local data expected to be erased | `TODO` |
| Notes | `TODO` |

### IT-confirmed self-service path from `reimage-laptop.md`

The attached IT note identifies the self-service clean OS path as:

```text
System Settings / General / Transfer or Reset / Erase All Content and Settings
```

After the erase completes and the Mac restarts, connect to Wi-Fi and sign in with the company Microsoft 365 / O365 account when prompted. That sign-in should enroll the Mac into Intune and start installation of required profiles and base software such as CrowdStrike, Zscaler, Microsoft Office, and other managed apps.

> **This is also the earliest point you can fetch this toolkit onto the Mac** — curl doesn't need Intune enrollment to finish, just Wi-Fi. See the callout at the top of Phase 6 below for the exact command and the jump-drive fallback.

Do not reconnect the external backup drive or begin development restore until the initial Intune enrollment and base profile/app installation has had time to complete.

### Self-service Erase All Content and Settings path

Only use this if IT says it is approved for this managed Mac.

Typical macOS path:

```text
System Settings > General > Transfer or Reset > Erase All Content and Settings
```

Expected prompts may include:

```text
administrator password
Apple Account / Activation Lock prompts, if applicable
confirmation that content and settings will be erased
sign-out or management-related prompts
restart confirmation
```

After the erase starts:

- keep power connected
- do not close the lid
- do not interrupt the process
- do not reconnect the external backup drive until the new setup is complete

### macOS Recovery path

Only use Recovery if IT says to use it or the normal erase path is unavailable.

Typical reasons:

```text
Erase Assistant is unavailable
macOS installation is damaged
IT needs a full disk erase
managed workflow requires Recovery
```

Record the exact method used in the notes.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 6 — Enroll and Stabilize

This phase brings the rebuilt Mac to a clean, trusted managed baseline before any restore work begins. It focuses on completing company enrollment, letting required profiles, security tools, and base managed apps install, applying any required macOS updates, performing the first stabilization restart, and confirming afterward that the managed state still looks healthy. Its purpose is to make sure the machine is ready for the later restore phases without mixing in Git, apps, secrets, or local-file recovery too early.

> **Step 1 of this phase: get this toolkit onto the Mac.** No repo, `git`, or SSH key exists yet — this is by design (see the Restore Strategy section above). Do this before anything else in Phase 6:
>
> **Primary — if Wi-Fi is connected (it should be, from Phase 5's sign-in step):**
> ```bash
> curl -fsSL https://raw.githubusercontent.com/sadashiva108/fractogenesis-toolkit/main/bootstrap.sh | bash
> ```
> Installs to `$HOME/reimage-toolkit` (or `$FRACTOGENESIS_HOME` if set). No `git` needed — installing `git` on a bare Mac triggers a large Xcode Command Line Tools popup/download, which this deliberately avoids.
>
> **Fallback — if there's no network yet** (captive portal, delayed profile push, etc.), use the prepared jump drive:
> ```bash
> bash /Volumes/REIMAGEKIT/bootstrap.sh /Volumes/REIMAGEKIT/fractogenesis-toolkit.tar.gz
> ```
> Checksum-verified before installing; refuses to proceed on a corrupted copy rather than installing something broken.
>
> Once either succeeds, continue this phase's remaining steps using the local copy — no further network dependency for reading the guide itself.

Primary guide: [[enroll-and-stabilize|enroll-and-stabilize.md]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 7 — Initial Captures and Sanity Checks

**Initial Captures and Sanity Checks** is the first post-enrollment verification phase after the managed baseline is stable. It reconnects the backup and capture root, records the first post-image checklist evidence, and confirms that the rebuilt Mac is basically usable before deeper restore work begins. The focus is on validating backup-root visibility, rerunning the initial checklist around a restart, and checking core day-one usability such as browser, network, terminal, display, keyboard, mouse, and audio so later restore phases start from a known-good state.

Primary guide: [[capture-initial-reimaged-system|capture-initial-reimaged-system.md]]

Primary generated evidence:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/initial-reimaged-system--YYYYMMDD-HHMMSS/
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 8 — Restore Runtime Environment

**Restore Runtime Environment** rebuilds the technical foundation that the remaining restore phases depend on. This phase is about getting the rebuilt Mac back to a state where it can run development tooling, authenticate to required systems, and support later repo, IDE, and app restoration without mixing those concerns together too early. It is intentionally split into two parts: first restoring the non-secret runtime layer such as Xcode Command Line Tools, Homebrew, Java, Node, Gradle, Maven, Groovy, and platform CLIs, and then restoring the access layer such as SSH keys, certificates, Java trust overrides, shell and CLI configuration, credentials, and license or activation material from approved encrypted sources. The goal is to establish a stable, usable platform before moving on to Git, application restore, and local project state.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 8A — Restore Runtime Libraries

**Restore Runtime Libraries** focuses on the non-secret toolchain and execution layer of the rebuilt Mac. This is where the workstation regains the core components needed to build, run, and support development workflows, including Xcode Command Line Tools, Homebrew, language runtimes, build tools, and supporting platform CLIs. By restoring these pieces first, later phases can assume the machine is already capable of compiling code, installing dependencies, and running the expected local tooling without mixing in account access, secrets, or environment-specific credentials too early.

Primary guides:

- [[restore-runtime|restore-runtime.md]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 8B — Restore Access

**Restore Access** focuses on the identity, trust, and credential material that allows the rebuilt Mac to securely reach the systems and services required for normal work. This includes restoring SSH keys, certificates, Java trust overrides, shell and CLI configuration, private credentials, and license or activation material from approved encrypted sources. The purpose of this phase is to make sure the workstation can authenticate correctly and use the expected secure access paths before Git restore, IDE restore, and broader application restore continue.

Primary guides:

- [[restore-access|restore-access.md]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 9 — Restore Git

**Restore Git** reestablishes source-control access and repository context on top of the restored runtime and access foundation. It focuses on restoring or recreating Git configuration, SSH routing, work and personal identity handling, and the reference-vault checkout first, then restoring or recloning the repositories needed for the remaining setup work. The goal is to ensure the rebuilt Mac can authenticate to the correct remotes, use the intended Git identity automatically, and bring the core repo workspace back online before broader app and local-file restore begins.

Primary guide: [[restore-git|restore-git.md]]


[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 10 — Restore Apps

**Restore Apps** brings back the day-to-day application layer after the managed baseline, runtime, access, and Git foundations are already in place. It covers restoring or reconnecting apps such as Office, OneDrive, Chrome, Obsidian, Postman, VS Code, Raycast, and other daily tools, while using dedicated companion runbooks for more complex restores like IntelliJ and Docker. The goal is to restore application usability in a controlled order, rely on sync or supported import flows where appropriate, and keep secret-bearing settings, activation material, and app-specific state handled deliberately instead of through broad copy-back restores.

Primary guides:

- [[restore-apps|restore-apps.md]]
- [[restore-intellij|restore-intellij.md]]
- [[restore-docker|restore-docker.md]]


[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 11 — Post-Image Captures

Reference link: [[reimaged-system-evidence]]

Phase 11 is the **comparison side** of the capture workflow. The goal is not just to take fresh snapshots, but to capture the rebuilt Mac in a way that can be compared directly against the matching Phase 3 evidence and used to confirm what was restored, what changed intentionally, and what still needs attention.

If a particular capture from Phase 3 was run, run the corresponding Phase 11 capture so the before/after pair stays useful.

### Recommended Post-Image Capture Order

1. Confirm `$REIMAGE_ARTIFACT_ROOT` exists and matches your current `reimage.env`.
2. Run Phase 11A workflow snapshot capture if you want a refreshed workflow-doc bundle on the external root.
3. Run Phase 11B post-image system inventory.
4. Run Phase 11C post-image company-managed inventory if you want a precise record of IT-managed state after rebuild.
5. Run Phase 11D post-image performance audit under the same named scenarios used pre-image if performance comparison will be useful.
6. Start or continue the Office watcher if post-image Office stability evidence is still needed.
7. Confirm the Office marker timestamp.
8. Run Phase 11E post-image Office stability baseline and Office-specific checklist steps as needed.
9. Review the generated evidence and any remaining manual rows in the owning capture runbooks before Phase 12 final validation.

Do not reset the Office marker after an incident until the incident evidence has been captured.

| Subphase | Evidence | Destination | Supporting reference | Manual notes or checklist section |
|---|---|---|---|---|
| Phase 11A | Workflow snapshot | `$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/pre-image-workflow-snapshot-*`, `$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/reimage-workflow-docs/` | capture-workflow-snapshot.md | — |
| Phase 11B | System inventory | `$REIMAGE_ARTIFACT_ROOT/system-inventory/post-image-*` | capture-system-inventory.md | `capture-system-inventory.md` — Manual context note only when needed |
| Phase 11C | Company-managed inventory | `$REIMAGE_ARTIFACT_ROOT/managed-inventory/post-image-*` | capture-managed-inventory.md | — |
| Phase 11D | Performance audit | `$REIMAGE_ARTIFACT_ROOT/performance-audit/post-image-*` | capture-performance-audit.md | `capture-performance-audit.md` — Manual Observations |
| Phase 11E | Office stability | `$REIMAGE_ARTIFACT_ROOT/office-stability/post-reimage-*` | capture-office-stability-audit.md | `capture-office-stability-audit.md` — Post-Image Office Stability Checklist Template |


[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Phase 11A — Capture Workflow Snapshot

Use this capture to preserve the **final post-image version** of the workflow docs, scripts, and lightweight restore reference bundle that actually reflect the rebuilt system. Unlike Phase 3A, which freezes the workflow you planned to use before erase, Phase 11A records the workflow state you ended up using after the rebuild, including any runbook or script refinements made during restoration.

Follow this capture runbook: [capture-workflow-snapshot.md](capture-workflow-snapshot.md).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Phase 11B — Post-Image System Inventory Capture

Use this capture to record the rebuilt system state so it can be compared directly against Phase 3B. The emphasis here is on confirming that the Mac came back with the expected hardware/macOS identity, apps, Homebrew packages, shell setup, developer tooling, Docker state, network context, SSH state, cloud tooling, environment variables, and display/peripheral context rather than just documenting what existed before erase.

Follow this capture runbook: [capture-system-inventory.md](capture-system-inventory.md).

Manual notes, if needed: [capture-system-inventory.md — Manual context note only when needed](capture-system-inventory.md#manual-context-note-only-when-needed).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Phase 11C — Post-Image Company-Managed Inventory Capture

Run this when you want to verify that company-managed state was correctly re-applied after enrollment. Unlike Phase 3C, which preserves the pre-image managed footprint, Phase 11C is used to confirm that expected MDM profiles, managed apps, package receipts, launch agents/daemons, system extensions, and managed preference payloads returned on the rebuilt Mac and to highlight anything missing or unexpectedly added.

Follow this capture runbook: [capture-managed-inventory.md](capture-managed-inventory.md).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Phase 11D — Post-Image Performance Audit Capture

Run this when you want the **after** side of the performance comparison. Unlike Phase 3D, which establishes the baseline before erase, Phase 11D reruns the same named scenarios on the rebuilt Mac so you can judge whether responsiveness, resource pressure, memory health, and workload behavior improved, stayed the same, or regressed.

At minimum, capture a `normal-workload` scenario. Add `clean-boot`, `active-dev`, or `symptom-capture` only when they will help the comparison. Use the same scenario names that were used pre-image whenever comparison matters.

Review the auto-filled `manual-observations.md` and `workload-reproduction-config.md` so the post-image run matches the pre-image workload as closely as possible.

Follow this capture runbook: [capture-performance-audit.md](capture-performance-audit.md).

Manual notes, if needed: [capture-performance-audit.md — Manual Observations](capture-performance-audit.md#manual-observations).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Phase 11E — Post-Image Office Stability Capture

If you are collecting Office stability evidence, start or continue the Office watcher, then capture the structured Office baseline and checklist using that capture runbook. Unlike Phase 3E, which documents the unstable or suspicious pre-image state, Phase 11E is intended to show whether Outlook, OneNote, Office update behavior, and related supporting processes are now stable on the rebuilt Mac or whether the original issue still reproduces.

If Outlook or OneNote closes unexpectedly, do not reopen either app first. Capture a workload snapshot and a fast Office baseline.

Follow this capture runbook: [capture-office-stability-audit.md](capture-office-stability-audit.md).

Generated checklist, when needed: `scripts/office-stability-checklist.sh --phase post-reimage --backup-root "$REIMAGE_ARTIFACT_ROOT"`.

> **Naming TODO:** the `--backup-root` flag name itself belongs to `office-stability-checklist.sh`, which isn't migrated to this repo yet (Phase 11E). Only its *value* was updated above (`$BACKUP_ROOT` → `$REIMAGE_ARTIFACT_ROOT`) — revisit whether the flag itself should become `--artifact-root` or similar once that script actually lands here.

Manual checklist, if needed: [capture-office-stability-audit.md — Post-Image Office Stability Checklist Template](capture-office-stability-audit.md#post-image-office-stability-checklist-template).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 12 — Reimaged System Checks

**Capture Validated Reimaged System** is the final proof step for the rebuilt Mac. It confirms that the restored system is ready for normal work by collecting the last validation evidence, reviewing automated checklist results, and closing any remaining manual sign-off items that scripts cannot prove on their own. This phase focuses on overall readiness rather than individual restore tasks: device state, enrollment and security posture, app presence, development tooling, workspace status, backup state, and any final usability or access checks needed before the rebuild is considered complete.

Primary guide: [[capture-validated-reimaged-system|capture-validated-reimaged-system.md]]

Primary generated evidence:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 13 — Restore Local Files

Primary guide: [[restore-local-files|restore-local-files.md]]

### Phase 13 summary order

1. Restore only the local-file categories still needed.
2. Prefer cloud resync over manual copy for OneDrive-managed content.
3. Merge dotfiles selectively rather than overwriting blindly.
4. Leave obsolete or risky content behind on purpose.

[[#Table of Contents|⬆ Back to Table of Contents]]


---
