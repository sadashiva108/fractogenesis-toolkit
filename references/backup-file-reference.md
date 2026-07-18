[[reimaging-guide#Phase 2 — Pre-Image Backups|← Back to Mac Reimaging Guide]]

# Backup File Reference

A complete reference for every file and directory category included in the pre-image local-file backup workflow.

This document assumes the standard artifact model: workflow source files stay in the fractogenesis-toolkit repo, while generated backup artifacts live under `$REIMAGE_ARTIFACT_ROOT` on the external data/artifact volume.

---

## Table of Contents

- [[#Phase Guide Reference|Phase Guide Reference]]
- [[#How the Backup is Organized|How the Backup is Organized]]
- [[#External Backup and Capture Root Layout|External Backup and Capture Root Layout]]
- [[#Home Directories|Home Directories]]
- [[#Media|Media]]
- [[#Root-Level Personal Dirs|Root-Level Personal Dirs]]
- [[#Development Extras|Development Extras]]
- [[#Dotfile Directories|Dotfile Directories]]
- [[#Individual Dotfiles|Individual Dotfiles]]
- [[#Secrets|Secrets]]
- [[#Chrome|Chrome]]
- [[#Docker|Docker]]
- [[#Postman|Postman]]
- [[#Intentionally Skipped|Intentionally Skipped]]
- [[#OneDrive Targets|OneDrive Targets]]
- [[#Global Excludes|Global Excludes]]
- [[#OneDrive Extra Excludes|OneDrive Extra Excludes]]

---

## Phase Guide Reference

Single source of truth for the phase guides used across the pre-image stage (Phase 0 through Phase 4), in the order they are typically reached. Linked from [[reimaging-guide#Pre-Image|Pre-Image]] in Workflow Map and Reference Guides — update this table, not a copy in the guide, when a pre-image runbook is added, renamed, or retired.

| File | Purpose |
|---|---|
| `reimaging-guide.md` | Canonical workflow sequence and checkpoint map for the full pre-image process. |
| `backup-strategy-guide.md` | Backup strategy, destination boundaries, cloud-copy safety, and handling rules. |
| `backup-file-reference.md` | File and directory reference for Phase 2 backup artifacts under `$REIMAGE_ARTIFACT_ROOT` (this file). |
| `backup-repos.md` | Git audit, backup branches, stashes, `.gitignore` superset, dry runs, and selected ignored-file backup. |
| `backup-home.md` | Scripted home-directory and secrets-encrypted backup workflow and output review. |
| `backup-apps.md` | App backup runbook for common apps first, then optional apps when they apply. |
| `backup-intellij.md` | Pre-image IntelliJ Scratches, Consoles, IDE settings, plugins, run configs, and project metadata backup. |
| `stage-cert-keychain.md` | Certificate and Keychain review, export, and staging workflow before DMG encryption. |
| `backup-dmg-secrets.md` | Consolidated encrypted secrets DMG staging, validation, cleanup, and restore notes. |
| `backup-time-machine.md` | Time Machine setup, status capture, monitoring, and pre-reimage completion checks. |
| `reimage-prep-evidence.md` | Comprehensive pre-image evidence reference for Phase 3 capture artifacts plus Phase 4 manual sign-off rows and templates under `$REIMAGE_ARTIFACT_ROOT`. |
| `capture-workflow-snapshot.md` | Automated workflow snapshot capture and workflow-doc snapshots. |
| `capture-system-inventory.md` | System inventory and workstation rebuild reference capture. |
| `capture-managed-inventory.md` | Company-managed app/profile inventory capture guide and interpretation notes. |
| `capture-performance-audit.md` | Performance baseline capture methodology for before/after comparison. |
| `capture-office-stability-audit.md` | Outlook / OneNote stability evidence, watcher/marker usage, and comparison workflow. |
| `reimage-prep-checks.md` | Phase 4 final pre-image validation: go / no-go checklist, cloud sync checks, and manual sign-off reference. |
| `templates/it-reimage-confirmation-template.md` | Copyable Phase 0 IT reimage confirmation template. |
| `templates/app-backup-and-cloud-sync-signoff-template.md` | Manual sign-off template for app backup status, certificate/Keychain staging, VS Code Settings Sync, and cloud sync. |
| `reimaging-scripts-guide.md` | Supporting command reference for automation used across the pre-image workflow. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Backup is Organized

This file focuses on the **backup artifacts themselves**: what categories are preserved, where they land under `$REIMAGE_ARTIFACT_ROOT`, and which items intentionally stay out of the local-file backup.

It complements the broader workflow docs:

| Need                                              | Use |
|---------------------------------------------------|---|
| Backup phase order and decisions                  | `reimaging-guide.md` Phase 2 |
| Home files backup workflow                        | `backup-home.md` |
| App backups                                       | `backup-apps.md` |
| Phase 4 cloud sync and manual sign-off reference  | `reimage-prep-checks.md` |
| Certificate and Keychain staging                  | `stage-cert-keychain.md` |
| Encrypted secret staging, validation, and cleanup | `backup-dmg-secrets.md` |
| IntelliJ-specific backup artifacts                | `backup-intellij.md` |
| Time Machine backup and status evidence           | `backup-time-machine.md`; runtime script `bin/backup-time-machine.sh`; read-only capture script `bin/capture-time-machine.sh` |

[[#Table of Contents|⬆ Back to Table of Contents]]

Time Machine command ownership:

| Script | Role |
|---|---|
| `bin/backup-time-machine.sh` | Runtime Time Machine operations: start, monitor, completion evidence, logs, mount/unmount, targeted verification, compare, diagnostics, and eject. |
| `bin/capture-time-machine.sh` | Read-only Time Machine captures: `pre-run` full evidence bundle, optional `verify-volume` APFS destination-volume verification, and `final` auto-filled Time Machine checklist. |


---

## External Backup and Capture Root Layout

The external root should use this naming convention:

```text
$REIMAGE_ARTIFACT_ROOT=/Volumes/<external-data-volume-name>/reimage-<asset-or-host>-<start-date>-open
```

Recommended layout relevant to this file:

```text
$REIMAGE_ARTIFACT_ROOT/
├── app-settings-backup/
│   ├── MANIFEST.md
│   ├── candidate-review/
│   │   └── app-backup-candidates-YYYYMMDD-HHMMSS/
│   ├── chrome/
│   │   ├── bookmarks_YYYYMMDD-HHMMSS.html
│   │   ├── chrome-export-inventory-YYYYMMDD-HHMMSS.md
│   │   └── README.md
│   ├── docker/
│   │   ├── settings-store.json
│   │   ├── daemon.json
│   │   ├── contexts/
│   │   ├── image-inventory.txt
│   │   ├── container-inventory.txt
│   │   ├── compose-projects.txt
│   │   └── MANIFEST.md
│   ├── intellij/
│   │   ├── IntelliJIdeaYYYY.N/
│   │   │   ├── config-copy/
│   │   │   ├── scratches-and-consoles/
│   │   │   └── manifests/
│   │   ├── logs/
│   │   ├── manifests/
│   │   ├── manual-settings-export/
│   │   ├── project-metadata/
│   │   ├── restore-notes/
│   │   └── README.md
│   ├── obsidian/
│   │   ├── global-settings/
│   │   └── vault-copy/
│   ├── postman/
│   │   ├── collections/
│   │   ├── environments-redacted/
│   │   ├── inventory/
│   │   │   └── postman-vault-inventory-YYYYMMDD-HHMMSS.md
│   │   └── README.md
│   ├── raycast/
│   │   ├── raycast-quicklinks-YYYYMMDD-HHMMSS.json
│   │   ├── raycast-export-inventory-YYYYMMDD-HHMMSS.md
│   │   └── README.md
│   └── vscode/
│       ├── extensions.txt
│       └── user/
│           ├── keybindings.json
│           ├── profiles/
│           ├── settings.json
│           └── snippets/
├── home-files-backup/
│   ├── home/
│   │   ├── Documents/
│   │   ├── Desktop/
│   │   ├── Music/
│   │   ├── Pictures/
│   │   ├── Movies/
│   │   ├── scripts/
│   │   └── config-files-backups/
│   ├── dotfiles/
│   │   ├── .zshrc
│   │   ├── .gitconfig
│   │   ├── .shell_common.sh
│   │   ├── config/
│   │   ├── kube/
│   │   ├── cf/
│   │   ├── azure/
│   │   ├── fiddler/
│   │   ├── copilot/
│   │   └── dotfiles.falkor.d/
│   └── MANIFEST.md
├── public-certs/
│   └── certs/
│       ├── README.md
│       ├── keychain-cert-export-inventory-YYYYMMDD-HHMMSS.md
│       └── *.cer / *.pem                          # optional public-only convenience copies
├── workflow-snapshot/
│   ├── reimage-workflow-docs/
│   └── pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/
├── time-machine/
│   ├── completion-check-YYYYMMDD-HHMMSS.md
│   ├── final-time-machine-checklist-YYYYMMDD-HHMMSS.md
│   ├── compare-YYYYMMDD-HHMMSS.txt
│   ├── logs-YYYYMMDD-HHMMSS.txt
│   ├── verifychecksums-YYYYMMDD-HHMMSS.txt
│   ├── diskutil-verifyvolume-applebackups-YYYYMMDD-HHMMSS.txt
│   └── pre-image-time-machine-status-YYYYMMDD-HHMMSS/
│       ├── README.md
│       ├── time-machine-pre-run.md
│       ├── time-machine-status.md
│       └── raw/
│           ├── backup-root-spot-check.txt
│           ├── cloud-sync-process-hints.txt
│           ├── diskutil-applebackups.txt
│           ├── diskutil-applebackups-snapshots.txt
│           ├── diskutil-verifyvolume-applebackups.txt
│           ├── diskutil-data.txt
│           ├── tmutil-currentphase.txt
│           ├── tmutil-destinationinfo.txt
│           ├── tmutil-isexcluded-applebackups.txt
│           ├── tmutil-isexcluded-data.txt
│           ├── tmutil-latestbackup-targeted-applebackups.txt
│           ├── tmutil-latestbackup.txt
│           ├── tmutil-listbackups-targeted-applebackups.txt
│           ├── tmutil-listbackups.txt
│           ├── tmutil-status.txt
│           └── volumes.txt
└── secrets-encrypted/
    ├── all-secrets-YYYYMMDD-HHMMSS.dmg
    ├── all-secrets-YYYYMMDD-HHMMSS-manifest.txt
    ├── RESTORE-README.md
    ├── chrome/
    │   ├── Chrome Passwords*.csv              # if exported; temporary plaintext staging only
    │   └── README.md
    ├── certs/
    │   ├── README.md
    │   ├── java-security/
    │   ├── keychain-manual-exports/
    │   │   ├── README.md
    │   │   └── keychain-export-summary-YYYYMMDD-HHMMSS.md
    │   ├── loose-candidates-selected/
    │   ├── project-local/
    │   └── tool-local/
    ├── cli-credentials/
    ├── cloud/
    │   └── aws/
    ├── docker/config.json
    ├── extra-secrets-certs-review/
    ├── git/
    ├── gnupg/
    ├── intellij/
    ├── kube/
    ├── licenses/                                  # manual freeform staging, if applicable -- no fixed filenames
    ├── package-managers/
    ├── postman/
    │   ├── environments/                          # if exported
    │   ├── vault-if-export-allowed/                # if exported
    │   └── README.md
    ├── raycast/
    │   ├── *.rayconfig                            # if exported
    │   ├── quicklinks-if-sensitive/
    │   │   └── raycast-quicklinks-YYYYMMDD-HHMMSS.json   # if sensitive/unreviewed
    │   └── README.md
    └── ssh/
```

Expected final secrets state after DMG validation is different from staging. After the newest `all-secrets-*.dmg` has been mounted and verified, loose plaintext secret folders such as `ssh/`, `gnupg/`, `chrome/`, `postman/`, and `intellij/` should be removed unless you intentionally keep them temporarily for a documented reason.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Home Directories

Current enabled home-directory targets:

| Directory | Source | Backup Destination | Description |
|---|---|---|---|
| Documents | `~/Documents/` | `$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Documents/` | Work documents, project notes, architecture docs, and personal files. |
| Desktop | `~/Desktop/` | `$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Desktop/` | Active working files, crash triage folders, and desktop scripts. |

Optional commented-out target:

| Directory | Source | Backup Destination | Note |
|---|---|---|---|
| Downloads | `~/Downloads/` | `$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Downloads/` | Commented out in config by default. Enable only if needed after reviewing size and excluding installers. |


[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Media

Current enabled media targets:

| Directory | Source | Backup Destination | Description |
|---|---|---|---|
| Music | `~/Music/` | `$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Music/` | Personal music library. |
| Pictures | `~/Pictures/` | `$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Pictures/` | Photos library and screenshots. |
| Movies | `~/Movies/` | `$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Movies/` | Screen recordings and captured video. |


[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Root-Level Personal Dirs

| Directory | Source | Backup Destination | Description |
|---|---|---|---|
| `scripts/` | `~/scripts/` | `$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/scripts/` | Personal shell scripts at home root. |
| `config-files-backups/` | `~/config-files-backups/` | `$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/config-files-backups/` | Manual config file snapshots taken outside this workflow. |


[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Development Extras

These targets are useful when enabled, but they are commented out in the current config by default. Enable only when the folder exists and is still needed.

| Path | Source | Backup Destination | Description |
|---|---|---|---|
| `IdeaSnapshots/` | `~/IdeaSnapshots/` | `$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/IdeaSnapshots/` | IntelliJ workspace snapshots stored outside the project tree. |
| `runConfigurations/` | `~/Development/runConfigurations/` | `$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Development/runConfigurations/` | IntelliJ run/debug configurations stored outside repos. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Dotfile Directories

Config directories from `~/` backed up under `$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/`.

| Dir | Source | Backup Destination | Description |
|---|---|---|---|
| `config/` | `~/.config/` | `home-files-backup/dotfiles/config/` | CLI tool configs: `gh`, `git`, Wireshark, configstore, Raycast; GitHub Copilot cache excluded. |
| `kube/` | `~/.kube/` | `home-files-backup/dotfiles/kube/` | Kubernetes cluster config and context definitions. Review for secrets before cloud copy. |
| `cf/` | `~/.cf/` | `home-files-backup/dotfiles/cf/` | Cloud Foundry CLI config and installed plugins. |
| `azure/` | `~/.azure/` | `home-files-backup/dotfiles/azure/` | Azure CLI subscriptions, credentials, and command config; logs and telemetry excluded. |
| `fiddler/` | `~/.fiddler/` | `home-files-backup/dotfiles/fiddler/` | Fiddler proxy certificates, settings, and unmanaged resources. |
| `copilot/instructions/` | `~/.copilot/instructions/` | `home-files-backup/dotfiles/copilot/instructions/` | GitHub Copilot custom instruction files. |
| `copilot/prompts/` | `~/.copilot/prompts/` | `home-files-backup/dotfiles/copilot/prompts/` | GitHub Copilot saved prompt templates. |
| `copilot/ide/` | `~/.copilot/ide/` | `home-files-backup/dotfiles/copilot/ide/` | GitHub Copilot IDE integration settings. |
| `dotfiles.falkor.d/` | `~/dotfiles.falkor.d/` | `home-files-backup/dotfiles/dotfiles.falkor.d/` | Falkor dotfiles framework — shell theme, aliases, and environment config. |


[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Individual Dotfiles

Individual non-secret files at `~/` are backed up to `$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/` when present. Secret-bearing dotfiles are staged under `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/` instead of being copied to `home-files-backup/`.

### Shell Config

| File | Description |
|---|---|
| `.zshrc` | Primary Zsh config — prompt, options, plugin loading. |
| `.bashrc` | Bash interactive shell config. |
| `.bash_profile` | Bash login shell config. |
| `.zprofile` | Zsh login shell config — PATH and env setup. |
| `.exports` | Exported environment variables. |
| `.aliases` | Additional alias definitions. |
| `.functions` | Shell function definitions. |

### Git

| File | Description |
|---|---|
| `.gitconfig` | Global Git config — user, aliases, merge tool, credential helper. |
| `.gitignore_global` | Global gitignore patterns applied to all repos. |

### Package Managers

| File | Description |
|---|---|
| `.npmrc` | npm config — registry, auth tokens, default options. Secret-bearing copy is staged under `secrets-encrypted/package-managers/`; do not put token-bearing copies in OneDrive. |
| `.yarnrc` | Yarn v1 config. May contain registry auth; secret-bearing copy is staged under `secrets-encrypted/package-managers/`. |
| `.yarnrc.yml` | Yarn v2+ config. May contain npm auth tokens; secret-bearing copy is staged under `secrets-encrypted/package-managers/`. |

### Sensitive Dotfiles

| File | Description | Note |
|---|---|---|
| `.netrc` | FTP/HTTP credentials for command-line tools. | Treat as secret-bearing and include in the consolidated secrets DMG. |


Do not bulk overwrite a fresh post-image home directory. Compare first, then restore selectively.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Secrets

Secret material is staged under `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/`, then encrypted by the consolidated AES-256 DMG workflow described in [Create Secrets DMG](../create-secrets-dmg.md).

This area includes both live secret sources, such as Docker `~/.docker/config.json`, and manual secret-staging folders that already live under `secrets-encrypted/`, such as Postman and Raycast.

| Category                      | Source / Manual Source                                                                                          | Staging Destination                                                     | Description                                                                                                                                                                                            |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `ssh/`                        | `~/.ssh/`                                                                                                       | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/ssh/`                         | SSH config, public keys, private keys, and known hosts. Preserve permissions.                                                                                                                          |
| `gnupg/`                      | `~/.gnupg/`                                                                                                     | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/gnupg/`                       | GPG private keys and trust DB. `random_seed` excluded.                                                                                                                                                 |
| `docker/`                     | `~/.docker/config.json`                                                                                         | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker/config.json`           | Docker auth tokens and credential helpers.                                                                                                                                                             |
| `kube/`                       | `~/.kube/config`                                                                                                | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/kube/config`                  | Kubernetes contexts, tokens, certificates, and cluster credentials.                                                                                                                                    |
| `certs/`                      | `~/.keystore`, manual Keychain exports, and Phase 2D reviewed loose cert/key/truststore selections              | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/`                       | Certificate, keystore, truststore, and private-key-bearing material. Phase 2D manual exports land under `keychain-manual-exports/`, `loose-candidates-selected/`, `project-local/`, and `tool-local/`. |
| `certs/java-security/`        | discovered `jssecacerts` under `$JAVA_HOME`, installed JDKs, or IntelliJ JBR                                    | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/java-security/`         | Java-specific corporate trust override; restore only after target JDK is confirmed.                                                                                                                    |
| `cli-credentials/`            | `~/.netrc` and similar CLI credential files                                                                     | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/cli-credentials/`             | Command-line HTTP/FTP credentials.                                                                                                                                                                     |
| `git/`                        | `~/.git-credentials`                                                                                            | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/git/`                         | Git credential-helper plaintext cache, if present.                                                                                                                                                     |
| `licenses/`                   | vendor-issued license keys, serial files, activation exports, or recovery bundles                               | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/licenses/`                    | Secret-bearing license/activation material when local export is actually required.                                                                                                                     |
| `package-managers/`           | `.npmrc`, `.yarnrc`, `.yarnrc.yml`, `.pypirc`, Gradle properties, Maven settings                                | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/package-managers/`            | Internal package registry tokens and server credentials.                                                                                                                                               |
| `cloud/`                      | `~/.aws/`                                                                                                       | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/cloud/aws/`                   | AWS CLI profiles, cached SSO material, and credentials when present.                                                                                                                                   |
| `chrome/`                     | Chrome manual password CSV export                                                                               | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/Chrome Passwords*.csv` | Optional password CSV. Must be included in the consolidated secrets DMG, then loose CSV deleted after validation.                                                                                      |
| `intellij/`                   | IntelliJ HTTP Client env files such as `http-client.private.env.json`, `http-client.env.json`, and `*.env.json` | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/intellij/`                    | HTTP Client environment files may contain tokens and should not be left loose.                                                                                                                         |
| `postman/`                    | Postman environment exports, Vault exports, or other secret-bearing Postman staging                             | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/`                     | Secret-bearing Postman exports. Use `environments/` and `vault-if-export-allowed/` under this root; redacted inventories belong in app-settings-backup.                                                |
| `extra-secrets-certs-review/` | Keychain inventories and loose cert/key candidate inventories                                                   | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/extra-secrets-certs-review/`  | Pre-DMG review artifacts. Manual Keychain certificate exports belong under `secrets-encrypted/certs/keychain-manual-exports/`.                                                                         |

Validation and cleanup are covered in [Create Secrets DMG](../create-secrets-dmg.md).



[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Chrome

Chrome has two different backup paths:

| Item                       | Destination                                                                      | Secret? | Notes                                                                                                        |
| -------------------------- | -------------------------------------------------------------------------------- | ------: | ------------------------------------------------------------------------------------------------------------ |
| Bookmarks HTML export      | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome/bookmarks_YYYYMMDD-HHMMSS.html`                 |      No | Manual export from Chrome Bookmark Manager.                                                                  |
| Chrome profile sync status | `$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/manual-app-export-and-sync-signoff-YYYYMMDD.md` |      No | Manual confirmation only; automation cannot prove sync completion. Optional app-local inventory notes can still live under `app-settings-backup/chrome/`. |
| Chrome password CSV export | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/Chrome Passwords*.csv`                    |     Yes | Optional. Rerun the consolidated secrets DMG immediately after export and delete loose CSV after validation. |

Export details live in [Backup Apps](../backup-apps.md#chrome).

Useful checks:

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome" -maxdepth 2 -type f | sort
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome" -maxdepth 2 -type f | sort
```

An empty `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome/` means the bookmarks export has not been done yet, or Chrome sync was intentionally chosen as the restore source and documented manually.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Docker

Settings are backed up under `app-settings-backup/docker/`. `Docker.raw` is intentionally not backed up; rebuild images from registries and compose files after reimage.

| File | Source | Destination | Description |
|---|---|---|---|
| `settings-store.json` | `~/Library/Group Containers/group.com.docker/settings-store.json` | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/settings-store.json` | Docker Desktop CPU/RAM/disk resource limits, VirtioFS, and feature flags. |
| `daemon.json` | `~/.docker/daemon.json` | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/daemon.json` | Registry mirrors, log drivers, insecure registries. |
| `config.json` | `~/.docker/config.json` | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker/config.json` | Auth tokens and credential helpers; encrypted in the secrets DMG. |
| `contexts/` | `~/.docker/contexts/` | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/contexts/` | Named Docker contexts. |
| `image-inventory.txt` | `docker images` output | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/image-inventory.txt` | Reference for re-pulling images. |
| `container-inventory.txt` | `docker ps -a` output | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/container-inventory.txt` | Reference for container state. |
| `compose-projects.txt` | `docker compose ls` output | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/compose-projects.txt` | Reference list when Docker Compose is available. |



[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Postman

Postman exports are documented in [Backup Apps](../backup-apps.md#postman).

| Item | Destination | Secret? | Rule |
|---|---|---:|---|
| Non-secret collection exports | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/collections/` | Usually no | Review for hard-coded tokens, cookies, client secrets, and passwords before storing here. |
| Redacted environment examples | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/environments-redacted/` | No | Replace secret values with placeholders. |
| Vault inventory when export is blocked | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/inventory/` | No | Capture key names and restore sources only. No secret values. |
| Environment exports with real values | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/environments/` | Yes | Secret-bearing staging/reference material. |
| Vault export, if allowed | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/vault-if-export-allowed/` | Yes | Do not bypass app/workspace/corporate restrictions. |
| External-vault references | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/README.md` | No | Document the approved provider and restore path there, not the secret values. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Intentionally Skipped

These are intentionally skipped because they are regenerated, very large, or better restored through installation.

### Large Caches — Skip, Rebuilds Automatically

| Path | Reason |
|---|---|
| `~/Documents/DockerDesktop/` | Docker.raw virtual disk; rebuild images from registries. |
| `~/.gradle/` | Gradle dependency cache; re-downloads on first build. |
| `~/.m2/` | Maven dependency cache; re-downloads on first build. |
| `~/Documents/github-copilot-intellij/` | IntelliJ Copilot plugin cache; reinstall post-reimage. |
| `~/.config/github-copilot/` | GitHub Copilot cache. |
| `~/.cache/` | Assorted tool caches. |
| `~/.npm/` | npm download cache. |

### Version Managers — Reinstall, Then Re-Pin Versions

| Path | Reason | Post-Reimage Action |
|---|---|---|
| `~/.nvm/` | Node Version Manager install. | Reinstall nvm, then `nvm install <version>`. |
| `~/.rbenv/` | Ruby version manager install. | Reinstall rbenv, then restore repo `.ruby-version` files. |
| `~/.sdkman/` | SDKMAN install. | Reinstall SDKMAN, then install required candidates. |

### Generated / Reinstallable

| Path | Reason |
|---|---|
| `~/.android/` | Android SDK cache. |
| `~/.aspnet/` | .NET DataProtection keys; regenerated automatically. |
| `JDK lib/security/cacerts` | Default JDK truststore; do not copy wholesale. Capture corporate `jssecacerts` instead. |
| `~/.hawtjni/` | JNI native library cache. |
| `~/.gem/` | Ruby gem cache; reinstall via Gemfile. |
| `~/.local/` | Mostly generated state and bin symlinks. |
| `~/.parallel/` | GNU parallel temp files. |
| `~/.azure/logs/`, `~/.azure/telemetry/` | Azure CLI noise. |
| `~/.copilot/logs/`, `~/.copilot/history-session-state/`, `~/.copilot/session-state/` | Copilot session noise. |
| `~/.Trash/` | Empty before reimage. |
| `Downloads/*.dmg`, `Downloads/*.pkg`, `Downloads/*.zip` | Installers; re-download post-reimage. |
| `~/Library/Logs/OneDrive/*/general.keystore` | OneDrive internal TLS cert store; auto-generated. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## OneDrive Targets

OneDrive is optional and narrower than the external drive backup. It is for selected work-safe files, not secrets, dotfiles, or local dev artifacts.

The OneDrive root should be the macOS CloudStorage-backed corporate OneDrive folder:

```bash
export ONEDRIVE_ROOT="$HOME/Library/CloudStorage/OneDrive-AcmeGroup"
```

Do not use a bare relative value such as `OneDrive-AcmeGroup` as the actual destination. Resolve it under `$HOME/Library/CloudStorage` so it points to the actual CloudStorage-backed OneDrive folder and does not accidentally land under `$FRACTOGENESIS_HOME`, for example:

```text
$FRACTOGENESIS_HOME/OneDrive-AcmeGroup/
```

By default, the OneDrive subdirectory can match the same directory name as the external backup/capture root:

```bash
ONEDRIVE_DEST_SUBDIR="${ONEDRIVE_DEST_SUBDIR:-$(basename "${REIMAGE_ARTIFACT_ROOT%/}")}"
```

That means the external drive and OneDrive folders line up like this:

```text
External:  $REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Documents/
OneDrive:  $HOME/Library/CloudStorage/OneDrive-AcmeGroup/<basename-of-$REIMAGE_ARTIFACT_ROOT>/Documents/

External:  $REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Desktop/
OneDrive:  $HOME/Library/CloudStorage/OneDrive-AcmeGroup/<basename-of-$REIMAGE_ARTIFACT_ROOT>/Desktop/
```

Current OneDrive targets:

| Label | Source | OneDrive Destination | Description |
|---|---|---|---|
| Documents | `~/Documents/` | `$ONEDRIVE_ROOT/<basename-of-$REIMAGE_ARTIFACT_ROOT>/Documents/` | Work documents synced to corporate OneDrive. |
| Desktop | `~/Desktop/` | `$ONEDRIVE_ROOT/<basename-of-$REIMAGE_ARTIFACT_ROOT>/Desktop/` | Desktop files synced to corporate OneDrive. |

Additional targets are available but commented out in config:

```text
# Downloads
# Music
# Pictures
```

Useful OneDrive path check:

```bash
BACKUP_BASENAME="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"
EXPECTED_ONEDRIVE_ROOT="${ONEDRIVE_ROOT:-$HOME/Library/CloudStorage/OneDrive-AcmeGroup}"
printf 'Expected OneDrive root: %s\n' "$EXPECTED_ONEDRIVE_ROOT"
find "$EXPECTED_ONEDRIVE_ROOT" -maxdepth 1 -type d -name "$BACKUP_BASENAME" -print 2>/dev/null || true
```

Before relying on OneDrive, check the menu bar icon and the OneDrive web interface. A local copy into the OneDrive folder does not prove upload completion.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Global Excludes

Applied to every external-drive local-file backup copy and also included in OneDrive syncs.

| Pattern                                           | Category     | Reason                            |
| ------------------------------------------------- | ------------ | --------------------------------- |
| `.DS_Store`, `desktop.ini`, `.localized`          | OS noise     | Metadata files.                   |
| `~$*`                                             | Office temp  | Office lock/temp files.           |
| `DockerDesktop/`                                  | Dev artifact | Docker.raw virtual disk.          |
| `github-copilot-intellij/`                        | Dev artifact | Plugin cache.                     |
| `*.dmg`, `*.pkg`, `*.zip`                         | Installers   | Re-download post-reimage.         |
| `$RECYCLE.BIN/`                                   | Windows stub | Recycle-bin stub.                 |
| `github-copilot/`                                 | Cache        | Copilot cache inside `~/.config`. |
| `logs/`, `telemetry/`                             | Noise        | Azure/Copilot logs and telemetry. |
| `history-session-state/`, `session-state/`, `jb/` | Noise        | Copilot session state.            |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## OneDrive Extra Excludes

Applied only to OneDrive syncs in addition to the global excludes.

### Dev Folders

```text
DockerDesktop/
github-copilot-intellij/
Kubernetes/
Falcon/
Dynatrace/
```

### Sensitive File Types

```text
*.pem
*.key
*.p12
*.pfx
*.cer
*.crt
*.der
*.p7b
*.p8
*.rayconfig
*.env
*.env.local
http-client.private.env.json
.netrc
.git-credentials
.pypirc
.yarnrc
.yarnrc.yml
settings.xml
gradle.properties
credentials
*.keystore
*.jks
*.exe
*.dll
*.msi
*.bat
*.cmd
*.ps1
node_modules/
.vscode/extensions/
github-copilot/
github-copilot-intellij/
```

### Personal

```text
Personal/
```

[[#Table of Contents|⬆ Back to Table of Contents]]
