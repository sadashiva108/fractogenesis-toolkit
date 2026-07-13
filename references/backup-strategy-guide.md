[[reimaging-guide#Backup Strategy|← Back to Mac Reimaging Guide]]

# Backup Strategy Guide

Detailed backup strategy, destination guidance, and safety rules for the Mac reimage workflow.

This document supports `reimaging-guide.md`, `backup-apps.md`, and `backup-file-reference.md` by keeping backup strategy and safety guidance in one place.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#Guiding Backup Strategy|Guiding Backup Strategy]]
- [[#Recommended Backup Destinations|Recommended Backup Destinations]]
- [[#Cloud and Obsidian Sync Sign-Off|Cloud and Obsidian Sync Sign-Off]]
- [[#Important Safety Rules|Important Safety Rules]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

Use this guide before running backup, evidence, restore, or validation steps. The goal is to avoid relying on a single backup destination and to keep sensitive or managed data protected throughout the reimage effort.

The main principle is:

```text
Before reimaging, every important file, credential, evidence capture, or local Git state must exist in at least one safe place outside the laptop.
```

Preferably, important non-sensitive items should exist in more than one place, while secrets should be encrypted or stored only in approved secret storage.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Guiding Backup Strategy

Use multiple layers of protection instead of relying on one backup method.

Recommended layers:

```text
1. Git remotes for committed code and backup branches
2. Manual external-drive backup/capture root on the external data/artifact volume
3. Encrypted DMG for secrets
4. Company OneDrive for selected non-sensitive work backup copies
5. Time Machine as the final full-system safety net before final pre-image validation
```

Each destination has strengths and weaknesses:

| Destination | Best For | Weakness |
|---|---|---|
| Git remotes | Committed code and branches | Does not include ignored files, local config, stashes, or untracked files |
| Manual external-drive folder | Easy-to-browse backup artifacts, setup notes, and evidence captures | Only one physical device unless copied elsewhere |
| Encrypted DMG | SSH/GPG/certs/env files/secrets | Requires password saved in LastPass |
| Company OneDrive | Work-safe extra copy of selected files | Sync must be verified; sensitive files need encryption/exclusion |
| Time Machine | Full system safety net | Harder to inspect selectively |

Do not rely on only one of these. Use the external backup/capture root, Git remotes, encrypted secrets storage, optional approved cloud copies, and Time Machine as complementary layers.

For optional evidence that may need to be gathered over several days or weeks before the actual backup window, it is acceptable to stage those captures locally first under `REIMAGE_WORKSPACE_ROOT` and copy the finalized artifacts into `$BACKUP_ROOT` later. This is especially relevant for performance-history collection that may start well before the external backup drive is mounted.


[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Recommended Backup Destinations

### 1. External drive

Use the external drive as the primary manual backup/capture location and, if configured that way, as the Time Machine destination.

Keep the roles separate:

```text
<time-machine-volume-name>       -> Time Machine / Apple backup destination
<external-data-volume-name>      -> Destination for artifacts like generated backup artifacts, evidence captures, checklists, and redacted restore notes
```

Do not manually place backup working files under the Time Machine volume. Keep that volume reserved for Time Machine.

If you are collecting optional multi-day evidence before the backup drive is mounted, keep those staged artifacts under `REIMAGE_WORKSPACE_ROOT` until you are ready to copy them into `$BACKUP_ROOT` on the external data volume.

### 2. Company OneDrive

Use company OneDrive mainly for the approved work-safe secondary copy created by `backup-local-files.sh`, plus any additional manual work-safe artifacts you intentionally duplicate there. Typical examples are:

```text
Documents/ and Desktop/ copied under <OneDrive root>/$ONEDRIVE_DEST_SUBDIR/
selected redacted notes or inventories that are safe for company cloud storage
reference-vault docs or other non-secret planning material, when useful
```

Do not treat OneDrive as the default destination for secrets, dotfiles, or local dev artifacts. Before relying on OneDrive, verify the files are actually synced by checking OneDrive from the web interface.

### 3. iCloud Drive

Use iCloud Drive only as an optional extra copy for personal or non-sensitive notes/scripts.

Avoid company credentials, certificates, secrets, or proprietary source files unless company policy explicitly allows it.


[[#Table of Contents|⬆ Back to Table of Contents]]

---


## Cloud and Obsidian Sync Sign-Off

Cloud copies are useful, but they are not considered complete until the cloud service reports upload completion and a spot-check confirms the files are visible from the service side.

Minimum checks:

| Item                  | Check                                                                                                              | Why                                                                                                                |
| --------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| VS Code Settings Sync | Confirm Settings Sync state in VS Code and record the signed-in account or that sync is intentionally unused.      | Local `settings.json`, keybindings, snippets, and extension list do not prove Settings Sync is enabled or settled. |
| OneDrive              | Confirm the menu bar icon has no pending uploads or sync errors, then spot-check the matching OneDrive web folder. | Copying into the OneDrive folder does not prove upload completion.                                                 |
| iCloud Drive          | Confirm no pending upload cloud icons remain for files you rely on.                                                | Finder presence alone may include local-only pending uploads.                                                      |
| Obsidian              | Record the vault path and source of truth: Obsidian Sync, Git, iCloud, OneDrive, or manual external-drive copy.    | The app-backups snapshot preserves reimage docs, but it does not prove the whole vault is synced.                  |

For OneDrive copies created by `backup-local-files.sh`, the default cloud folder name should match the external backup/capture root basename unless `ONEDRIVE_DEST_SUBDIR` is intentionally overridden:

```text
External root: $REIMAGE_ARTIFACT_ROOT
OneDrive copy: <OneDrive root>/<basename-of-$REIMAGE_ARTIFACT_ROOT>/
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Important Safety Rules

### Do not treat Git audit reports as backups

`git-audit-reports/` is an audit trail and checklist. It tells you which repos need attention, but it does not replace pushing branches, committing work, or copying local files.

### Do not put secrets loose in cloud storage

Files such as `.env.local`, private keys, certificates, IntelliJ HTTP Client environment files, and app credentials should not be placed unencrypted in OneDrive, iCloud, or email.

Prefer:

```text
external drive only
consolidated encrypted DMG
company-approved password manager
```

### Do not delete Office profile/cache data unless IT asks

The Office issue appears related to app bundle replacement/update activity, not necessarily user profile corruption. Avoid deleting these unless IT explicitly asks:

```text
~/Library/Group Containers/UBF8T346G9.Office
~/Library/Containers/com.microsoft.Outlook
~/Library/Containers/com.microsoft.onenote.mac
Outlook profiles
OneNote cache
```

### Do not remove MDM, Company Portal, Intune, or FileVault management yourself

For a managed work Mac, IT should confirm whether the wipe is self-service, IT-initiated, or performed through MDM. Do not unenroll, remove profiles, disable FileVault, or alter management agents unless IT gives that exact instruction.

### Keep scripts in the reference-vault repo, not on the external backup/capture root

The external backup/capture root should contain evidence outputs, logs, snapshots, summaries, and compressed evidence bundles. Keep active helper scripts in Git under `workflows/mac/reimage/scripts/`. Do not copy `*.sh` or `*.py` helper scripts to `$BACKUP_ROOT` unless IT specifically requests script copies as evidence.

### Do not reopen Outlook or OneNote immediately after unexpected closure if evidence is needed

If Outlook or OneNote closes unexpectedly, capture evidence first. Reopening immediately can obscure whether the closure created a crash report or was tied to Microsoft AutoUpdate / Intune / installer activity.


[[#Table of Contents|⬆ Back to Table of Contents]]
