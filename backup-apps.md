[[reimaging-guide#Phase 2C — Backup Apps|← Back to Mac Reimaging Guide]]

# Backup Apps

Use this guide for app-specific backup actions where the restore source is defined by the app itself, not just by copying known local files. Some steps are manual because the app UI controls export, because secret handling requires judgment, or because the backup decision is really about app state, sync, or restore semantics.

This runbook groups apps by how likely they are to apply:

- **common apps first**
- **optional apps second**

Artifact-local verification stays here. Cross-phase readiness sign-off belongs later in the workflow.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Rules|Rules]]
	-  [[#Why App Backup Differs from Local File Backup|Why App Backup Differs from Local File Backup]]
	- [[#When an App Belongs in Phase 2C|When an App Belongs in Phase 2C]]
	- [[#App Coverage Map|App Coverage Map]]
	- [[#Optional Note Capture|Optional Note Capture]]
- [[#Sequential Steps|Sequential Steps]]
	- [[#Run Automated App File Backup Script|Run Automated App File Backup Script]]
	- [[#Manual Backup Steps Not Covered By Script|Manual Backup Steps Not Covered By Script]]
		- [[#Load the Shared Reimage Environment|Load the Shared Reimage Environment]]
		- [[#Run the Size Audit First|Run the Size Audit First]]
		- [[#Common Apps|Common Apps]]
		  - [[#IntelliJ IDEA|IntelliJ IDEA]]
		  - [[#Docker|Docker]]
		    - [[#Settings Inventories and Config|Settings Inventories and Config]]
		    - [[#Docker artifact-local checks|Docker artifact-local checks]]
		  - [[#Chrome|Chrome]]
		    - [[#Chrome Export Directories and Starter Notes|Chrome Export Directories and Starter Notes]]
		    - [[#Bookmarks|Bookmarks]]
		    - [[#Passwords|Passwords]]
		      - [[#Chrome artifact-local checks|Chrome artifact-local checks]]
		  - [[#Postman|Postman]]
		    - [[#Postman Export Directories and Starter Notes|Postman Export Directories and Starter Notes]]
		    - [[#Collections|Collections]]
		    - [[#Environments|Environments]]
		    - [[#Postman Local Vault|Postman Local Vault]]
		      - [[#If vault export is allowed|If vault export is allowed]]
		        - [[#Local vault|Local vault]]
		        - [[#External vault or password-manager backed values|External vault or password-manager backed values]]
		      - [[#If vault export is blocked|If vault export is blocked]]
		    - [[#Postman artifact-local checks|Postman artifact-local checks]]
		- [[#Optional Apps|Optional Apps]]
		  - [[#VS Code|VS Code]]
		    - [[#VS Code Directories|VS Code Directories]]
		    - [[#Extensions, Key Bindings, Snippets, and Profiles|Extensions, Key Bindings, Snippets, and Profiles]]
		    - [[#VS Code artifact-local checks|VS Code artifact-local checks]]
		  - [[#Raycast|Raycast]]
		    - [[#Raycast Directories and Starter Notes|Raycast Directories and Starter Notes]]
		    - [[#Find the Raycast export commands|Find the Raycast export commands]]
		    - [[#Quick Links|Quick Links]]
		    - [[#Settings and data configuration|Settings and data configuration]]
		    - [[#Raycast artifact-local Checks|Raycast artifact-local Checks]]
		  - [[#Obsidian|Obsidian]]
		    - [[#GitHub and Local Setup|GitHub and Local Setup]]
		    - [[#Manual Backup and Global Settings|Manual Backup and Global Settings]]
		    - [[#Restore Source|Restore Source]]
		    - [[#Obsidian artifact-local checks|Obsidian artifact-local checks]]
		  - [[#Terminal|Terminal]]
		    - [[#Export the Custom Profile|Export the Custom Profile]]
		    - [[#Terminal artifact-local checks|Terminal artifact-local checks]]
- [[#Artifact-Local Validation|Artifact-Local Validation]]
- [[#Relationship to Later Phases|Relationship to Later Phases]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

Use this phase for app backup work where the app itself controls export, sync, or restore semantics.

This guide owns:

**Common App Backups**

```text
IntelliJ IDEA
Docker
Chrome - bookmark exports and Chrome password export staging notes
Postman - export notes and non-secret collection exports

```
**Optional App Backups**

```text
VS Code - extension inventory and user settings copies
Raycast - Quick Links export notes and Raycast configuration export staging notes
Obsidian
non-secret app backup artifacts under app-settings-backup/
secret-bearing app export staging under secrets-encrypted/
app-local notes and artifact-local validation
```

This guide does **not** own:

```text
general local-file copy
cross-phase cloud sync sign-off
certificate and Keychain staging
final encrypted DMG packaging
final pre-image readiness checklist
```

[[#Table of Contents|⬆ Back to Table of Contents]]


---

## Artifact and Script Locations

Primary script:

```text
$FRACTOGENESIS_HOME/bin/backup-apps.sh
```


Phase 2C uses two primary artifact roots:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/
```

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── app-settings-backup/
│   ├── docker/
│   │   ├── settings-store.json
│   │   ├── daemon.json
│   │   ├── contexts/
│   │   ├── image-inventory.txt
│   │   ├── container-inventory.txt
│   │   └── compose-projects.txt
│   ├── chrome/
│   │   ├── bookmarks_YYYYMMDD-HHMMSS.html
│   │   ├── chrome-export-inventory-YYYYMMDD-HHMMSS.md
│   │   └── README.md
│   ├── postman/
│   │   ├── collections/
│   │   ├── environments-redacted/
│   │   ├── inventory/
│   │   └── README.md
│   ├── raycast/
│   │   ├── raycast-quicklinks-YYYYMMDD-HHMMSS.json
│   │   ├── raycast-export-inventory-YYYYMMDD-HHMMSS.md
│   │   └── README.md
│   └── obsidian/
│       ├── global-settings/
│       └── vault-copy/
└── ...
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---


## Before You Run Anything


[[#Table of Contents|⬆ Back to Table of Contents]]

---


### Rules

| Category | Destination | Rule |
|---|---|---|
| Non-secret app exports | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/<app>/` | Default home for app backup artifacts that are safe in plaintext. |
| Redacted examples and inventories | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/<app>/` | Keep with the owning app unless they are secret-bearing. |
| Secret-bearing app exports | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/<app>/` | Stage here and rerun the consolidated secrets DMG workflow before final validation. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---


## Why App Backup Differs from Local File Backup

Local-file backup is usually about copying known filesystem paths with predictable rules.

App backup is different because the meaningful restore source is often defined by the application:

```text
app-owned export flow
sync state or signed-in state
restore-source choice
secret vs non-secret export handling
app-specific metadata that matters more than raw files on disk
```

A backup step is manual when a script cannot safely perform it or cannot prove it is complete without manual judgment.

[[#Table of Contents|⬆ Back to Table of Contents]]

---


## When an App Belongs in Phase 2C

Use these questions to decide whether an app belongs in this runbook at all:

| Question | If yes | If no |
|---|---|---|
| Is the app installed on this Mac? | Keep evaluating. | Skip it. |
| Does the user care about restoring app state or app-specific data? | Keep evaluating. | Skip it. |
| Is that state already adequately covered by Git, Phase 2B local-file backup, built-in sync, company-managed reinstall, or another dedicated workflow? | If fully covered, record the restore source only if that adds clarity. | Keep evaluating. |
| Does the app have user state that is local-only, easy to miss, costly to recreate, or split between secret and non-secret material? | Include it in Phase 2C. | It probably does not need a Phase 2C backup step. |

Use this phase when the answer is really about app-defined state such as:

```text
an app-owned export flow
vault or workspace configuration
restore-source choice
secret-bearing exports vs non-secret exports
metadata that matters more than raw files on disk
```

This is why not every installed app belongs here. Many apps fall into one of these categories instead:

```text
reinstall only
company-managed reinstall or re-enrollment
already covered by Phase 2B local-file backup
already covered by Git or another backup source
no meaningful state worth preserving
```

Company-managed apps are a special case: the app itself may come back automatically, but that does not guarantee that user-specific local state, exports, or special configuration is restored automatically. Use `capture-managed-inventory.md` when you need evidence about what is managed on this machine.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## App Coverage Map

Use this table after applying the criteria above:

| App | Likelihood | Use when | Non-secret destination | Secret-bearing destination |
|---|---|---|---|---|
| IntelliJ IDEA | Common | IntelliJ IDEA is installed and you care about IDE state such as Scratches, Consoles, settings export, plugins, or selected project metadata | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/` | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/` for HTTP Client env files and other credential-bearing material |
| Docker Desktop | Common | Docker Desktop settings, contexts, image inventory, or container inventory matter | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/` | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker/` |
| Chrome | Common | Bookmarks export or password export is needed | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome/` | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/` |
| Postman | Common | Collections, environments, or Vault state matter | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/` | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/` |
| VS Code | Optional | VS Code is installed and you want a local fallback for extensions, user settings, keybindings, snippets, or profiles in addition to or instead of Settings Sync | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/vscode/` | usually none from this runbook |
| Raycast | Optional | Quick Links or settings/data export matter | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/` | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/` |
| Obsidian | Optional | Obsidian is installed and you want to preserve vault content, vault-local config, or a clear restore-source decision not already adequately covered elsewhere | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/obsidian/` | usually none from this runbook |
| Terminal | Optional | You use a custom Terminal.app profile (color scheme, font, window size) you don't want to manually re-create | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/terminal/` | none |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Optional Note Capture

Per-app notes, mini checklists, and inventories are optional. Use them only when they reduce risk or preserve a restore decision you are likely to forget.

Preferred capture options, from most central to most app-local:

| Option | Where | Use when |
|---|---|---|
| Central final validation note | later Phase 4 / final-checks workflow | You want one place for restore-source decisions and notable exceptions. |
| Temporary working note | `$REIMAGE_WORKSPACE_ROOT` or another local planning area outside `$REIMAGE_ARTIFACT_ROOT` | You need short-lived prep notes while working through the backup. |
| App-local note | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/<app>/` | The note is tightly coupled to a specific app artifact and is worth keeping with it. |

Use app-local notes sparingly. Do not feel required to create one for every app although ofter provided.

Missing optional notes or unfilled optional note templates should not block final validation by themselves. At most, they should produce a warning if you intended to capture them and forgot.

[[#Table of Contents|⬆ Back to Table of Contents]]


---

## Sequential Steps


[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Run Automated App File Backup Script

This script does not complete every app backup by itself.

It backs up the app files, manifests, candidate lists, and script-controlled app backup artifacts that can be safely collected from disk. It is one part of the app-backup phase, not the entire phase.

Manual or app-controlled steps still remain for:

- Chrome exports that must be triggered from Chrome.
- Postman exports that must be triggered from Postman.
- Raycast exports that must be triggered from Raycast.
- Obsidian vault copy/sync decisions.
- IntelliJ settings ZIP export from IntelliJ IDEA.
- Later review of secret-like files before the consolidated secrets DMG is created.

### `--candidate-review` is a real scan-only / dry-run mode

`backup-apps.sh` detects whether each app (Docker, IntelliJ, VS Code, Chrome, Postman, Raycast, Obsidian) is actually present on this Mac before creating that app's folder. Nothing is created for an app that isn't detected — this applies to both modes below.

- **`--candidate-review`** — scan-only. Detects installed apps and writes a review bundle under `app-settings-backup/candidate-review/` that lists what a real run would create on this Mac. Does **not** create any app folder, does **not** run the Docker/IntelliJ/VS Code capture, and does **not** write `MANIFEST.md`.
- **Default (no `--candidate-review`)** — the real backup. Creates a folder only for each app it actually detects, runs the Docker/IntelliJ capture helpers and the VS Code fallback capture where applicable, and writes `MANIFEST.md`.

### Docker inventory prerequisite

Docker Desktop should be running before the real backup if you want current image and container inventories captured, in addition to Docker Desktop's settings files.

Recommended check:

```bash
docker version
docker context ls
docker ps
```

If Docker is not running, open Docker Desktop and wait until the daemon is ready before running the app backup script. The script still captures `settings-store.json`, `daemon.json`, and `contexts/` even when the daemon is not running — only the `image-inventory.txt` and `container-inventory.txt` files require Docker to actually be running, and are silently skipped without it.

### Per-app scaffolding, created only when detected

Unlike earlier versions of this script, folders are no longer created for every possible app up front. Each app gets its own folder only when the script actually detects it on this Mac:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/                          — only if Docker is detected
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/                         — only if IntelliJ IDEA is detected
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/vscode/user/                      — only if VS Code is detected
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome/                           — only if Chrome is detected
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/collections/              — only if Postman is detected
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/environments-redacted/    — only if Postman is detected
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/inventory/                — only if Postman is detected
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/                          — only if Raycast is detected
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/obsidian/                         — only if Obsidian is detected
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker/                     — only if Docker is detected
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/                     — only if Chrome is detected
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/environments/                 — only if Postman is detected
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/vault-if-export-allowed/       — only if Postman is detected
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/quicklinks-if-sensitive/       — only if Raycast is detected
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/candidate-review/                 — only when `--candidate-review` is used
```

`MANIFEST.md` (real backup only) reports a per-app status row — "Detected (path) — folder prepared..." or "Not detected on this Mac; no folder created" — so you can see at a glance which apps this Mac actually had.

Do not manually create app folders for apps you know aren't installed. The `mkdir -p` blocks in the per-app sections below (Chrome, Postman, Raycast) are a fallback for the rare case you need a folder before running the script — if you already ran `backup-apps.sh` and the app was detected, skip straight to the app-controlled export steps in each section instead of recreating the directories.

### Recommended order

1. Run `--candidate-review` first to see which apps this Mac actually has and what a real run would create, without touching anything.
2. Inspect the generated candidate-review bundle.
3. Complete required manual, app-controlled exports for whichever apps were detected (Chrome, Postman, Raycast, Obsidian, IntelliJ settings ZIP).
4. Run the real backup.
5. Continue secret review and deferred DMG creation in the later secrets/cert phase.

### Scan first (recommended)

```bash
cd "$FRACTOGENESIS_HOME"

./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --candidate-review --open
```

Generated review artifact:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/candidate-review/app-backup-candidates-YYYYMMDD-HHMMSS/
```

This bundle generates:

- a Markdown summary of known Phase 2C candidates such as IntelliJ IDEA, Docker, Chrome, Postman, VS Code, Raycast, and Obsidian, with an install-detected column
- a "planned directories and artifacts" table showing exactly what a real run would create on this Mac right now
- a related-app review table for apps that usually belong somewhere else, such as Music
- raw installed-app and state-signal files under `raw/`

Use the generated bundle to narrow your review set, then use the criteria below to decide what actually belongs in this runbook.

### Run the real backup

```bash
cd "$FRACTOGENESIS_HOME"

./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

What this does:

- creates the shared `app-settings-backup/` and `secrets-encrypted/` roots
- creates a folder and runs the internal Docker backup helper only when Docker is detected
- creates a folder and runs the internal IntelliJ backup helper only when IntelliJ IDEA is detected
- creates a folder and captures the local VS Code fallback only when VS Code is detected
- creates a folder for Chrome, Postman, Raycast, or Obsidian only when each is detected, ready for their manual export steps below
- writes the stable summary file at `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/MANIFEST.md`

### Required manual app-backup steps not performed by this script

- app-controlled exports that must be triggered in Chrome, Postman, or Raycast
- Obsidian vault copy decisions
- the IntelliJ settings ZIP export or later secret-review decisions

Use the per-app sections below only for the app-controlled or manual follow-up items that the script cannot safely complete, or when you intentionally prefer the manual path.

[[#Table of Contents|⬆ Back to Table of Contents]]

---


## Manual Backup Steps Not Covered By Script

The optional individual-command runs begin at the next section: [[#Load the Shared Reimage Environment|Load the Shared Reimage Environment]].

Use **either** the script above **or** the individual commands below. Do not run both unless you are intentionally rerunning or troubleshooting a specific section.

[[#Table of Contents|⬆ Back to Table of Contents]]

---


## Load the Shared Reimage Environment

`backup-apps.sh` and `capture-size-audit.sh` self-locate and load shared config through `.internal/load-reimage-config.sh` automatically — you do not need to source `reimage.env` by hand before running them. Confirm it resolves correctly first:

```bash
cd "$FRACTOGENESIS_HOME"
bash -n bin/backup-apps.sh
bash -n bin/capture-size-audit.sh
```

Confirm the artifact root that will be used:

```bash
./bin/backup-apps.sh --candidate-review --artifact-root "$REIMAGE_ARTIFACT_ROOT" 2>&1 | head -5
```

If `REIMAGE_ARTIFACT_ROOT` is empty, either fix `reimage.env` or pass `--artifact-root PATH` explicitly on every command below.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Run the Size Audit First

Run `capture-size-audit.sh` before generating or refreshing app backup artifacts when you want a quick capacity check for the shared backup root.

This audit is still global to the Phase 2 backup root. It does **not** estimate the exact size of every app-controlled export, but it does confirm that the external destination volume is mounted and shows the current backup-root destination headroom before you write more app artifacts.

```bash
./bin/capture-size-audit.sh
```

Review these lines in the output:

- `Target backup root`
- `Available on /Volumes/<drive>`
- `✓ External drive: enough space` or `✗ External drive: NOT ENOUGH SPACE`

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Common Apps

---

### IntelliJ IDEA

IntelliJ IDEA is common in this environment, and the normal scripted path now runs through `backup-apps.sh`. It still keeps a **dedicated companion runbook** because its backup scope is broader than the lighter app sections here. It mixes IDE state, Scratches, Consoles, settings export, plugins, project metadata, and credential-bearing HTTP Client material.

Use this section as the Phase 2C decision point:

| If this applies | Then |
|---|---|
| IntelliJ IDEA is installed and you care about preserving IDE state | Run `backup-apps.sh` as the primary Phase 2C command, then use [Backup IntelliJ](backup-intellij.md) for the IntelliJ-specific review, validation, and manual follow-up. |
| HTTP Client environment files may contain working credentials | Make sure they are handled through Phase 2F encrypted secrets, not left loose under the normal IntelliJ backup. |

Primary IntelliJ destinations:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/
```

If you want to rerun only the IntelliJ portion through the same Phase 2C entrypoint:

```bash
./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --intellij-only --open
```

Keep the detailed IntelliJ-specific review steps, settings ZIP export flow, validation, and restore notes in `backup-intellij.md`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Docker

Docker Desktop is common in this environment, so treat it as a default Phase 2C review item for developer Macs.

### Settings Inventories and Config

If you ran `backup-apps.sh`, the Docker portion was already attempted for you. Use the same Phase 2C entrypoint again when you want a Docker-only rerun, especially if Docker Desktop was not running the first time.

Run the Docker-only rerun path through the main Phase 2C script:

```bash
./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --docker-only --open
```

What this captures:

| Item | Destination | Rule |
|---|---|---|
| `settings-store.json` | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/` | Docker Desktop resource limits, feature flags, and UI-managed settings. |
| `daemon.json` | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/` | Registry mirrors, log drivers, DNS, and insecure registries. |
| `contexts/` | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/contexts/` | Named Docker contexts for local or remote targets. |
| `image-inventory.txt` | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/` | Reference list for re-pulling images after reimage. |
| `container-inventory.txt` | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/` | Reference list for container recreation/state review. |
| `compose-projects.txt` | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/` | Reference list when Docker Compose is available. |
| `config.json` | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker/config.json` | Treat as secret-bearing because it may include auth tokens or credential-helper state. |

`Docker.raw`, image layers, container writable state, and local volumes are intentionally **not** backed up by this workflow. Rebuild those from repos, registries, Compose files, and other restore sources after reimage.

If Docker Desktop is not running, you can still capture local settings files, but rerun `backup-apps.sh --docker-only` later with Docker running if you want current image and container inventories.

### Docker artifact-local checks

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker" -maxdepth 3 -type f | sort 2>/dev/null || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker" -maxdepth 2 -type f | sort 2>/dev/null || true
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Chrome

Chrome is a manual app export like Postman because the browser UI controls bookmarks export and password CSV export. The scripts can create folders and templates, but they cannot prove Chrome profile sync or safely export a password CSV for you.

### Chrome Export Directories and Starter Notes

If `backup-apps.sh` detected Chrome, the Chrome plaintext and secret-staging directories already exist. Complete the app-controlled export steps below. If Chrome wasn't detected (for example, it was installed after the last run), create the folders manually below, or rerun `backup-apps.sh`.

Create the Chrome folders:

```bash
mkdir -p \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome"
  
cat > "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome/README.md" <<'EOF_CHROME_APP_README'
# Chrome Backup Notes

Use this folder for non-secret Chrome exports such as bookmarks HTML files.

Expected examples:

- bookmarks_YYYYMMDD-HHMMSS.html
- chrome-export-inventory-YYYYMMDD-HHMMSS.md

Do not store Chrome password CSV exports here. Password CSV files belong under:

- $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/

EOF_CHROME_APP_README

cat > "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/README.md" <<'EOF_CHROME_SECRET_README'
# Chrome Secret Material


Expected examples:

- Chrome Passwords YYYYMMDD-HHMMSS.csv
- Chrome Passwords.csv

EOF_CHROME_SECRET_README
```

### Bookmarks

Use Chrome Desktop:

```text
Chrome > Bookmarks and lists > Bookmark Manager > three-dot menu > Export bookmarks
```

Save the exported HTML file under:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome/bookmarks_YYYYMMDD-HHMMSS.html
```

Recommended command after saving the export:

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome" -maxdepth 1 -type f -print | sort
```

### Passwords

Chrome password export is optional. Prefer Chrome profile sync or the approved password manager when that is the intended restore source.

If needed, use Chrome Desktop:

```text
Chrome > Settings > Autofill and passwords > Google Password Manager > Settings > Export passwords
```

Save the CSV only under:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/Chrome Passwords YYYYMMDD-HHMMSS.csv
```

Do **not** save password CSVs under `app-settings-backup/`, OneDrive, iCloud, email, Desktop, Downloads, or a repo.


Optional inventory note:

```bash
CHROME_INV="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome/chrome-export-inventory-$(date +%Y%m%d-%H%M%S).md"
cat > "$CHROME_INV" <<'EOF'
# Chrome Export Inventory

| Item | Status | Destination | Notes |
|---|---|---|---|
| Bookmarks HTML export | TODO | $REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome/bookmarks_YYYYMMDD-HHMMSS.html | TODO |
| Chrome profile sync | TODO | Chrome profile / managed account | TODO |
| Password CSV export | TODO | $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/ | Optional; secret-bearing |
EOF
open "$CHROME_INV"
```

#### Chrome artifact-local checks

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome" -maxdepth 2 -type f | sort
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome" -maxdepth 2 -type f | sort
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Postman

Postman exports are partly manual because the app UI owns the export flow. Treat Postman data as separate categories:

| Category                                       | Destination                                                       | Rule                                                                                                             |
| ---------------------------------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Non-secret collections                         | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/collections/`                   | Safe only after review. Collections should not contain hard-coded tokens, passwords, cookies, or client secrets. |
| Redacted environment examples or notes         | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/environments-redacted/`         | Safe when values are removed or replaced with placeholders.                                                      |
| Postman Local Vault exports, if allowed        | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/vault-if-export-allowed/` | Treat as secret-bearing, even when exported in encrypted form. Do not bypass export restrictions.                |
| Postman inventory when export is blocked       | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/inventory/`                     | Redacted list of variable names, owning collection/environment, and restore source. No secret values.            |
| External-vault references                      | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/README.md`                      | Document the provider and restore steps, not the secret values.                                                  |


If `backup-apps.sh` detected Postman, the Postman destination folders already exist. Complete the Postman-controlled export steps below. If Postman wasn't detected (for example, it was installed after the last run), create the folders manually below, or rerun `backup-apps.sh`.


### Postman Export Directories and Starter Notes

Use `app-settings-backup/postman/` only for non-secret collection exports, redacted environment examples, variable inventories, and restore notes. Use `secrets-encrypted/postman/` for anything that may contain tokens, passwords, API keys, client secrets, cookies, bearer tokens, or unreviewed environment exports.

Postman Vault export may be blocked by app controls, workspace policy, account policy, or corporate restrictions. Treat vault export as optional. If export is blocked, do **not** work around the control; create a redacted vault inventory and plan to restore values from the approved password manager, SSO flow, team environment, or secret owner after reimage.

```bash
mkdir -p \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/collections" \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/environments-redacted" \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/inventory" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/environments" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/vault-if-export-allowed"
```

Create starter notes:

```bash
cat > "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/README.md" <<'EOF'
# Postman Backup Notes

Use this folder for non-secret Postman collection exports, redacted environment examples, inventories, and restore notes.

Do not place tokens, passwords, client secrets, API keys, cookies, bearer tokens, or unreviewed environment exports here.

If Postman Vault export is blocked, document variable names and restore sources under:

$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/inventory/

Secret-bearing Postman files belong under:

$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/

EOF

cat > "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/README.md" <<'EOF'
# Postman Secret Material


Examples:

- environment exports containing tokens, passwords, API keys, client secrets, cookies, or bearer tokens
- Postman Local Vault export files, only when export is allowed
- unreviewed Postman exports that may contain credentials

Vault export may be unavailable or blocked by policy. If export is blocked, do not bypass it. Keep only a redacted inventory under app-settings-backup and restore the values from the approved secret source after reimage.

EOF
```

### Collections

Use the Postman Desktop export flow:

```text
Postman Desktop > Collections > Export
```

Save non-secret collection exports here:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/collections/
```

Before treating a collection export as non-secret, inspect it for hard-coded credentials:

```bash
grep -RniE 'token|password|passwd|secret|apikey|api_key|authorization|bearer|cookie|client_secret' \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/collections" \
  || true
```

### Environments

Use the Postman Desktop export flow:

```text
Postman Desktop > Environments > Export
```

Postman environments often contain URLs, IDs, tokens, usernames, passwords, bearer tokens, API keys, or client secrets. Export environments to the secret-bearing staging area first unless you are certain they are non-secret:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/environments/
```

Use redacted copies only under:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/environments-redacted/
```

Use placeholders such as:

```text
TODO_RESTORE_FROM_POSTMAN_VAULT
TODO_RESTORE_FROM_LASTPASS
TODO_RESTORE_FROM_1PASSWORD
TODO_RESTORE_FROM_AZURE_KEY_VAULT
TODO_RESTORE_FROM_TEAM_POSTMAN_ENVIRONMENT
TODO_REAUTHENTICATE_AFTER_REIMAGE
```

Do not leave unreviewed environment exports loose in app-settings-backup/` or cloud-synced folders.

### Postman Local Vault

#### If vault export is allowed

##### Local vault

Use the Postman Desktop export flow only when the option is available and allowed by policy:

```text
Postman Desktop > Vault > Export
```

Save it under:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/vault-if-export-allowed/
```

Recommended filename pattern:

```text
postman-vault-secrets-YYYYMMDD-HHMMSS.encrypted.json
```
##### External vault or password-manager backed values

If Postman requests use values from an external vault or password manager, do not duplicate those secret values into backup apps.

Instead, document the restore path in:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/README.md
```

Useful non-secret notes:

```text
workspace name
collection name
environment name
variable or vault key names with values redacted
which approved vault/password manager, team environment, SSO flow, or secret owner owns the values
whether the value must be recreated, reauthorized, imported, or requested after reimage
```

Example redacted note:

```text
Collection: Carrier Services Local Testing
Environment: dev
Variables requiring restore:
- api_base_url = non-secret URL
- access_token = TODO_RESTORE_FROM_POSTMAN_VAULT_OR_REAUTHENTICATE
- client_secret = TODO_RESTORE_FROM_LASTPASS_OR_SECRET_OWNER
Vault restore: vault export was blocked; recreate/import required values from the approved secret source after signing in to Postman Desktop.
```

#### If vault export is blocked

If Vault export is blocked, do not bypass the restriction. If a restore reminder would be useful, you can optionally create a redacted inventory note. Prefer a central note first; use an app-local note only if keeping it with the Postman artifacts is genuinely helpful.

Optional inventory note:


```bash
mkdir -p "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/inventory"

VAULT_INVENTORY="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/inventory/postman-vault-inventory-$(date +%Y%m%d-%H%M%S).md"
mkdir -p "$(dirname "$VAULT_INVENTORY")"

cat > "$VAULT_INVENTORY" <<'EOF'
# Postman Vault Inventory — Export Blocked

Vault export status: blocked / unavailable
Captured by: manual review

## Restore plan

Do not store secret values in this file. Restore values after reimage from the approved source.

| Workspace | Collection / Request | Environment | Variable / Vault Key Name | Secret Value Stored Here? | Restore Source | Restore Action | Notes |
|---|---|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | No | TODO_LASTPASS_OR_APPROVED_SOURCE | Recreate after reimage | TODO |

## Sign-off

- [ ] Confirmed vault export was blocked or unavailable.
- [ ] Confirmed no vault secret values were copied into the inventory note.
- [ ] Confirmed restore source is known for each required value.
EOF

open "$VAULT_INVENTORY"
```

Useful non-secret details to capture:

```text
workspace name
collection/request name
environment name
variable or vault key names
which approved password manager, team environment, SSO flow, or secret owner can restore the value
whether the value should be recreated rather than restored
```

Example redacted inventory entry:

```text
Workspace: Carrier Services
Collection: Local Testing
Environment: dev
Variable / Vault key: client_secret
Secret Value Stored Here?: No
Restore Source: TODO_RESTORE_FROM_LASTPASS_OR_SECRET_OWNER
Restore Action: Recreate/import after signing in to Postman Desktop
```

### Postman artifact-local checks

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman" -maxdepth 3 -type f | sort 2>/dev/null || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman" -maxdepth 3 -type f | sort 2>/dev/null || true
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Optional Apps

Skip any subsection that does not apply to this machine.

---


## VS Code

VS Code is optional in the Phase 2C sense: include it when VS Code is installed on this Mac and you want a local restore fallback for editor state that is not adequately covered by Git alone.

Recommended scope:

| Item               | Destination                                      | Rule                                                                                  |
| ------------------ | ------------------------------------------------ | ------------------------------------------------------------------------------------- |
| `extensions.txt`   | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/vscode/`               | Plain extension inventory for later reinstall.                                        |
| `settings.json`    | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/vscode/user/`          | Review before restore because settings may reference machine-specific paths or tools. |
| `keybindings.json` | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/vscode/user/`          | Safe local editor-state fallback.                                                     |
| `snippets/`        | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/vscode/user/snippets/` | Preserve custom user snippets when present.                                           |
| `profiles/`        | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/vscode/user/profiles/` | Preserve named VS Code profiles when present.                                         |

Keep the boundary tight. Do **not** treat VS Code caches, logs, workspace history, or extension storage as default Phase 2C backup material because they are noisy, machine-specific, and may contain auth state or disposable data.

If you use VS Code Settings Sync, keep using it as a restore source when that is your preference, but still confirm the signed-in/sync state later in `reimage-prep-checks.md`. This Phase 2C backup path is the local fallback, not proof that sync is enabled or settled.

### VS Code Directories

If you ran `backup-apps.sh`, the local fallback capture below was already attempted. Use these commands as the direct manual rerun path.

Create the VS Code backup folder:

```bash
mkdir -p "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/vscode/user"
```

Capture the local VS Code state you actually want as a fallback:

```bash
VSCODE_DEST="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/vscode"
VSCODE_USER="$HOME/Library/Application Support/Code/User"

mkdir -p "$VSCODE_DEST/user"
```

### Extensions, Key Bindings, Snippets, and Profiles

```bash
if command -v code >/dev/null 2>&1; then
  code --list-extensions > "$VSCODE_DEST/extensions.txt"
fi

for f in settings.json keybindings.json; do
  [[ -f "$VSCODE_USER/$f" ]] && cp -p "$VSCODE_USER/$f" "$VSCODE_DEST/user/$f"
done

for d in snippets profiles; do
  [[ -d "$VSCODE_USER/$d" ]] && rsync -a "$VSCODE_USER/$d/" "$VSCODE_DEST/user/$d/"
done
```

### VS Code artifact-local checks

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/vscode" -maxdepth 4 -type f | sort 2>/dev/null || true
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Raycast

Raycast export is manual because the app owns the export flow and the configuration export may include sensitive data. Treat Raycast as two separate export types:

| Category                                 | Destination                                                       | Rule                                                                                                                |
| ---------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Reviewed non-secret Quick Links JSON     | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/`                               | Safe only after reviewing URLs, query strings, identifiers, and internal links.                                     |
| Raycast restore notes and inventory      | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/`                               | Only if you want to keep app-specific restore notes with the artifacts. No `.rayconfig` files and no secret values. |
| Sensitive or unreviewed Quick Links JSON | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/quicklinks-if-sensitive/` | Treat as secret-bearing until reviewed.                                                                             |
| Raycast `.rayconfig`                     | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/`                         | Treat as secret-bearing even when password-protected.                                                               |

### Raycast Directories and Starter Notes

If `backup-apps.sh` detected Raycast, the Raycast destination folders already exist. Complete the Raycast-controlled export steps below. If Raycast wasn't detected (for example, it was installed after the last run), create the folders manually below, or rerun `backup-apps.sh`.

Create the Raycast folders:

```bash
mkdir -p \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/quicklinks-if-sensitive"
```

Create starter notes:

```bash
cat > "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/README.md" <<'EOF'
# Raycast Backup Notes

Use this folder for Raycast restore notes, export inventory, and sensitivity review notes.

Do not store Raycast secrets, password-protected configuration exports, tokens, API keys, extension credentials, or unreviewed Quick Links here.

Non-secret reviewed Quick Links JSON exports may be stored under:

$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/

Raycast `.rayconfig` exports and sensitive/unreviewed Quick Links exports belong under:

$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/

EOF

cat > "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/README.md" <<'EOF'
# Raycast App Settings Backup Notes

Use this folder for reviewed non-secret Raycast exports.

Expected examples:

- raycast-quicklinks-YYYYMMDD-HHMMSS.json
- raycast-export-inventory-YYYYMMDD-HHMMSS.md

Before saving Quick Links here, review whether the exported links include sensitive internal URLs, tokens, query strings, private identifiers, customer references, repo links, or company-only information.

If Quick Links are sensitive or unreviewed, save them under:

$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/quicklinks-if-sensitive/

Do not store the password-protected `.rayconfig` file here. The `.rayconfig` belongs under:

$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/
EOF

cat > "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/README.md" <<'EOF'
# Raycast Secret Material


Expected examples:

- raycast-settings-and-data-YYYYMMDD-HHMMSS.rayconfig
- quicklinks-if-sensitive/raycast-quicklinks-YYYYMMDD-HHMMSS.json

The Raycast `.rayconfig` export should be treated as secret-bearing even when password-protected.

EOF
```

### Find the Raycast export commands

The simplest way to find the export actions is from Raycast root search:

```text
Open Raycast
Search: Export Quicklinks
Search: Export Settings & Data
```

If the commands do not appear in root search, check that the built-in commands are enabled:

```text
Raycast > Settings > Extensions > Quicklinks
Raycast > Settings > Extensions > Raycast
```

Useful places to review before exporting:

```text
Raycast > Settings > Quicklinks
Raycast > Settings > Extensions
Raycast > Settings > Account / Sync, if used
```

Use `Export Quicklinks` for the standalone Quick Links JSON export. Use `Export Settings & Data` for the full `.rayconfig` backup.

### Quick Links

Use Raycast Desktop:

```text
Raycast > search for: Export Quicklinks
```

Save the exported JSON file under the non-secret app-settings folder only after review:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/raycast-quicklinks-YYYYMMDD-HHMMSS.json
```

If the Quick Links contain or may contain sensitive data, save the export under secret-bearing staging instead:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/quicklinks-if-sensitive/raycast-quicklinks-YYYYMMDD-HHMMSS.json
```

If the `.rayconfig` export uses a password, store that password only in the approved password manager.

### Settings and data configuration

Use Raycast Desktop:

```text
Raycast > search for: Export Settings & Data
```

Since your configuration required a password because it contains sensitive data, save the `.rayconfig` only under secret-bearing staging:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/raycast-settings-and-data-YYYYMMDD-HHMMSS.rayconfig
```

Do not save the `.rayconfig` under `app-settings-backup/raycast`, OneDrive, iCloud, email, Desktop, Downloads, or a repo.

Do not store the Raycast export password in this markdown file or in app backups. Store the password in the approved password manager or another approved secret source. If you need a reminder, record only a non-secret hint such as:

```text
Raycast `.rayconfig` password stored in approved password manager entry: TODO_ENTRY_NAME
```

### Raycast artifact-local Checks

After exporting, review or inventory the files:

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast" -maxdepth 2 -type f -print | sort
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast" -maxdepth 3 -type f -print | sort
```

Use these checks after saving Quick Links JSON or the `.rayconfig` file. They help confirm whether the files landed in the correct backup folders.

Open the expected folders:

```bash
open "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast" 2>/dev/null || true
open "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast" 2>/dev/null || true
```

List all Raycast-related files under the backup root:

```bash
find "$REIMAGE_ARTIFACT_ROOT" \
  -path '*/raycast/*' \
  -type f \
  \( -iname '*.rayconfig' -o -iname '*.json' -o -iname '*raycast*' -o -iname '*quicklink*' \) \
  -print | sort
```

Look specifically for the expected exports:

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast" \
  -maxdepth 2 \
  -type f \
  \( -iname '*quicklink*.json' -o -iname '*raycast*.json' \) \
  -print | sort

find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast" \
  -maxdepth 3 \
  -type f \
  \( -iname '*.rayconfig' -o -iname '*quicklink*.json' -o -iname '*raycast*.json' \) \
  -print | sort
```

Move misplaced files based on sensitivity:

```bash
# Password-protected settings/data export; secret-bearing.
mv "$HOME/Downloads/raycast-settings-and-data-YYYYMMDD-HHMMSS.rayconfig" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/"

# Reviewed non-secret Quick Links JSON.
mv "$HOME/Downloads/raycast-quicklinks-YYYYMMDD-HHMMSS.json" \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/"

# Sensitive or unreviewed Quick Links JSON.
mv "$HOME/Downloads/raycast-quicklinks-YYYYMMDD-HHMMSS.json" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/quicklinks-if-sensitive/"
```

Optional inventory note:

```bash
RAYCAST_INV="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/raycast-export-inventory-$(date +%Y%m%d-%H%M%S).md"
mkdir -p "$(dirname "$RAYCAST_INV")"

cat > "$RAYCAST_INV" <<'EOF'
# Raycast Export Inventory

| Item | Status | Destination | Sensitive? | Notes |
|---|---|---|---|---|
| Quick Links JSON | TODO | TODO_APP_SETTINGS_OR_SECRETS_ENCRYPTED | TODO | TODO |
| Raycast account/sync status | TODO | Raycast app UI | TODO | TODO |

## Sign-off

- [ ] Quick Links were exported or intentionally skipped.
- [ ] Quick Links were reviewed for sensitive URLs, query strings, tokens, private identifiers, and internal links.
- [ ] Sensitive or unreviewed Quick Links were staged under `secrets-encrypted/raycast/`.
- [ ] Raycast `.rayconfig` was staged under `secrets-encrypted/raycast/`.
EOF

open "$RAYCAST_INV"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Obsidian

`backup-apps.sh` prepares the Obsidian destination directory but does not choose the restore source for you. Use this section only when Obsidian applies to this Mac.

Obsidian is optional only in the Phase 2C sense: include it when Obsidian is installed on this Mac and you care about preserving vault content, vault-local configuration, or a clear restore-source decision. The table below is about **which restore source you are using**, not about whether Obsidian qualifies for backup work.

| Restore source | What to capture |
|---|---|
| Obsidian Sync, if available and used | Record that the vault is signed in, sync is enabled, and no pending sync/errors are shown. |
| Git-backed vault | Record Git status, remotes, and whether local commits are pushed or intentionally preserved. |
| OneDrive-backed vault | Record that OneDrive is the restore source for this vault. |
| iCloud-backed vault | Record that iCloud Drive is the restore source for this vault. |
| External manual copy | Record the copied-vault destination and the notes you spot-checked. |

| Item | Where Obsidian stores it | Suggested Phase 2C handling |
|---|---|---|
| Vault notes and attachments | Inside the vault folder | Preserve via Git if the vault is fully committed there, or make a manual vault copy if that is the chosen restore source. |
| Vault-specific Obsidian config | `.obsidian/` at the root of the vault | Preserve with the vault copy, or verify that the Git-backed vault already includes the `.obsidian` files you care about. |
| Themes, hotkeys, community plugin config | Usually inside `.obsidian/` | Treat as part of the vault-local config. |
| Global Obsidian settings | `~/Library/Application Support/obsidian` on macOS | Copy only if you intentionally want app-global Obsidian settings preserved outside the vault itself. |

### GitHub and Local Setup

Useful commands for a Git-backed vault:

```bash
VAULT="/path/to/obsidian-vault"
cd "$VAULT"
git status -sb
git remote -v
git log --oneline -5
```

Optional commands to inspect what is present locally:

```bash
VAULT="/path/to/obsidian-vault"

find "$VAULT" -maxdepth 2 -type f | sort | head -100
find "$VAULT/.obsidian" -maxdepth 3 -type f | sort 2>/dev/null || true
find "$HOME/Library/Application Support/obsidian" -maxdepth 3 -type f | sort 2>/dev/null | head -100
```

### Manual Backup and Global Settings

If you want a free manual backup copy of an Obsidian vault outside Git or cloud sync:

```bash
VAULT="/path/to/obsidian-vault"
DEST="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/obsidian/vault-copy"

mkdir -p "$DEST"
rsync -a "$VAULT/" "$DEST/$(basename "$VAULT")/"
```

If you want to preserve Obsidian global settings separately:

```bash
GLOBAL_OBSIDIAN="$HOME/Library/Application Support/obsidian"
GLOBAL_DEST="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/obsidian/global-settings"

if [[ -d "$GLOBAL_OBSIDIAN" ]]; then
  mkdir -p "$GLOBAL_DEST"
  rsync -a "$GLOBAL_OBSIDIAN/" "$GLOBAL_DEST/"
fi
```

### Restore Source

If you want to record the chosen restore source, prefer one of these:

1. a short row in the later central final validation note
2. a temporary working note outside `$REIMAGE_ARTIFACT_ROOT`
3. an app-local note under `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/obsidian/`, only if keeping it with the Obsidian artifacts is actually useful

Suggested fields if you choose to capture them anywhere:

```text
Vault path
Restore source
Whether `.obsidian/` is included in that restore source
Whether global Obsidian settings were copied separately
Manual copy destination, if used
```

If the restore source is an external manual copy, store that copied vault under an intentional location inside `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/obsidian/` or another clearly documented backup location.

### Obsidian artifact-local checks

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/obsidian" -maxdepth 2 -type f | sort 2>/dev/null || true
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Terminal

Terminal is optional in the Phase 2C sense: include it only if you use a custom Terminal.app profile (color scheme, font, window size) that you don't want to manually re-create after the reimage.

Recommended scope:

| Item | Destination | Rule |
|---|---|---|
| `<profile-name>.terminal` | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/terminal/` | Exported custom profile(s); safe, self-contained, and portable. |

Do **not** treat the full `com.apple.Terminal.plist` as default backup material — it also stores window positions and other machine-specific state that doesn't restore cleanly. Export the specific profile(s) instead.

### Export the Custom Profile

This step is manual because Terminal only exposes profile export through its UI, not a CLI flag.

```bash
mkdir -p "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/terminal"
open -a Terminal
```

In Terminal: **Terminal → Settings → Profiles**, select your custom profile (for example, an "Ocean" variant), then use the gear/action menu → **Export…** and save it as `<profile-name>.terminal` into:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/terminal/
```

If you also rely on a specific default window size (columns/rows) that isn't captured by the profile export, note it alongside the exported file:

```bash
cat > "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/terminal/window-size-note.txt" <<'EOF'
Default window size: <columns> columns x <rows> rows
Default profile: <profile-name>
EOF
```

### Terminal artifact-local checks

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/terminal" -maxdepth 1 -type f | sort 2>/dev/null || true
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---


## Artifact-Local Validation

This runbook owns app-local validation only:

```text
did the export file get created
did it land in the right app-settings-backup/ or secrets-encrypted/ location
if you intentionally created an optional note or inventory, is it where you expected it
```

This runbook does **not** own the final cross-phase readiness checklist before erase/reimage.

Optional notes are not required backup artifacts by themselves and should not fail final validation just because they are missing or unfilled.

Combined review:

```bash
test -f "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/MANIFEST.md" && echo "PASS: app-settings-backup/MANIFEST.md"
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup" -maxdepth 4 -type f | sort 2>/dev/null || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker" -maxdepth 2 -type f | sort 2>/dev/null || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome" -maxdepth 3 -type f | sort 2>/dev/null || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman" -maxdepth 3 -type f | sort 2>/dev/null || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast" -maxdepth 3 -type f | sort 2>/dev/null || true
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Relationship to Later Phases

The main later-phase dependency from this runbook is the Phase 2E → Phase 2F secret-staging sequence.

Stage secret-bearing app exports here as you work through Phase 2C. Phase 2E then handles certificate and Keychain staging. Run the consolidated secrets DMG workflow in Phase 2F only after both app secret staging and Phase 2E certificate/Keychain staging are complete so the DMG only needs to be built once for the full staged secret set.

If you add any Docker `config.json`, Chrome password CSV, secret-bearing Postman export, or Raycast secret export later, rerun Phase 2F so the DMG includes the complete final secret set before final validation.

[[#Table of Contents|⬆ Back to Table of Contents]]
