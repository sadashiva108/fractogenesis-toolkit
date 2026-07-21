---
title: Backup Apps
back_link: "reimaging-guide#Phase 2C — Backup Apps"
runbook_version: 0.1.0
verb_first: true
primary_scripts:
  - bin/backup-apps.sh
related_scripts:
  - .internal/apps/backup-docker-settings.sh
  - .internal/apps/backup-intellij-scratches-consoles.sh
  - bin/capture-size-audit.sh
artifact_paths:
  - $REIMAGE_ARTIFACT_ROOT/app-settings-backup/
  - $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/
author: Orah Kittrell
last_updated: 2026-07-21
---
[[reimaging-guide#Phase 2C — Backup Apps|← Back to Mac Reimaging Guide]]

# Backup Apps

Collect and stage application state — settings, exports, inventories, and profiles — for apps whose restore source is defined by the app itself, not by copying known local files. Some of this is automated by a script; much of it is manual, because the app's own UI owns the export, secret handling needs judgment, or the backup decision is really about app state, sync, or restore semantics. Not every app is covered, and not every covered app applies to your Mac — you decide which ones to back up.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#Why App Backup Differs from Local File Backup|Why App Backup Differs from Local File Backup]]
    - [[#What Gets Backed Up, and How|What Gets Backed Up, and How]]
    - [[#Apps Not Covered Here|Apps Not Covered Here]]
    - [[#Run Modes|Run Modes]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Destination Rules|Destination Rules]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Prepare and Validate|Step 1 — Prepare and Validate]]
    - [[#Step 2 — Check Backup-Root Capacity|Step 2 — Check Backup-Root Capacity]]
    - [[#Step 3 — Determine Which Apps to Back Up|Step 3 — Determine Which Apps to Back Up]]
    - [[#Step 4 — Run the Automated Backup|Step 4 — Run the Automated Backup]]
    - [[#Step 5 — Complete Manual Exports|Step 5 — Complete Manual Exports]]
        - [[#Chrome|Chrome]]
        - [[#Postman|Postman]]
        - [[#Terminal|Terminal]]
        - [[#IntelliJ Settings Export|IntelliJ Settings Export]]
    - [[#Step 6 — Verify Outputs|Step 6 — Verify Outputs]]
    - [[#Optional Apps|Optional Apps]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Optional App Exports|Optional App Exports]]
        - [[#Raycast|Raycast]]
        - [[#Obsidian|Obsidian]]
    - [[#Optional Note Capture|Optional Note Capture]]
    - [[#Relationship to Later Phases|Relationship to Later Phases]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Back up application state where the app itself controls export, sync, or restore semantics, and stage any secret-bearing exports for the later consolidated secrets workflow. Producing this backup means the app-specific state you cannot recreate cheaply survives the erase.

This runbook owns:

```text
app-controlled backups for Chrome, Docker, IntelliJ IDEA, Obsidian, Postman, Raycast, Terminal, and VS Code
non-secret app backup artifacts under app-settings-backup/
secret-bearing app export staging under secrets-encrypted/
app-local notes and artifact-local validation of those exports
```

It does not own:

```text
general local-file copy — backup-home.md (Phase 2B)
the managed-inventory capture — capture-managed-inventory.md (its own phase, run before this one)
IntelliJ settings ZIP export, review, and restore detail — backup-intellij.md
certificate and Keychain staging — Phase 2E
final encrypted DMG packaging — Phase 2F
cross-phase cloud-sync and final pre-image readiness sign-off — reimage-prep-checks.md (Phase 4B)
```

This runbook can be rerun independently and incrementally. Rerunning the script re-detects installed apps and refreshes the manifest; manual exports can be redone one app at a time.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The goal is a complete, correctly-sorted backup of app-defined state: non-secret material staged in plaintext where it is easy to restore, and secret-bearing material staged separately for the later encrypted-DMG step.

This phase is deliberately part automated and part manual, because a script can only safely do part of the job. `backup-apps.sh` detects which apps are present and captures the state that lives predictably on disk. Everything the app's own UI owns — browser exports, collection exports, vault exports, profile exports — stays manual, because a script cannot trigger those flows or judge whether an export is safe in plaintext. Running the script is never the whole phase; the manual exports are the rest of it.

### Why App Backup Differs from Local File Backup

Local-file backup copies known filesystem paths with predictable rules. App backup is different because the meaningful restore source is often defined by the application, not by files sitting on disk:

```text
an app-owned export flow
sync state or signed-in state
a restore-source choice
secret vs non-secret export handling
app-specific metadata that matters more than raw files on disk
```

A step is manual whenever a script cannot safely perform it, or cannot prove it is complete without human judgment.

### What Gets Backed Up, and How

Coverage falls into three classes. The first two are the apps this runbook documents; the third is everything else (see [[#Apps Not Covered Here|Apps Not Covered Here]]).

1. **Backed up by the script** — `backup-apps.sh` captures the state directly, fully or in part.
2. **Backed up manually** — the script may prepare a folder, but you perform the actual export from the app's UI.
3. **Not covered** — no backup support here; the app is your responsibility.

The table lists every covered app, how it is backed up, and whether it is in the common or optional group. The grouping is a hint for deciding, not a rule — the [[#Confirm Your Intent|app you actually use]] is the one that matters. Destinations follow the [[#Destination Rules|Destination Rules]] and are not repeated per app.

| App | How it is backed up | Group |
|---|---|---|
| Docker Desktop | Script — settings, contexts, image/container inventories; `config.json` staged as secret | Common |
| VS Code | Script — extension list, user settings, keybindings, snippets, profiles | Common |
| IntelliJ IDEA | Script for Scratches/Consoles/config; **manual** settings ZIP export | Common |
| Chrome | Manual — bookmarks export; optional password CSV | Common |
| Postman | Manual — collections, environments, optional vault export | Common |
| Terminal | Manual — custom profile export (no script folder) | Common |
| Raycast | Manual — Quick Links and settings/data export | Optional |
| Obsidian | Manual — restore-source decision; optional vault copy | Optional |

The two optional apps (Raycast, Obsidian) keep their full steps in [[#Optional App Exports|Supplemental Reference]], indexed from [[#Optional Apps|Optional Apps]] at the end of Sequential Steps, so the main flow stays focused on what most Macs have.

> [!note]
> The script only acts on apps it detects. For an app you do not have, it creates no folder and the manifest marks it "Not detected on this Mac" — so a clean run on a Mac without Docker is correct, not a failure.

### Apps Not Covered Here

It is not possible to maintain an exhaustive backup strategy for every app. If you rely on an app that is not in the table above, backing it up is your responsibility — export or copy its state to a location you control before the erase. If that app has state worth a repeatable strategy, consider contributing support back to this toolkit so a future reimage covers it automatically.

### Run Modes

`backup-apps.sh` has two modes. Both detect whether each app is present before touching anything.

| Mode | Command | What it does |
|---|---|---|
| Candidate review | `./bin/backup-apps.sh --candidate-review` | Scan-only. Writes a review bundle listing what a real run would create. Creates no app folders, runs no captures, writes no `MANIFEST.md`. |
| Real backup | `./bin/backup-apps.sh` | Creates a folder for each detected app, runs the Docker/IntelliJ/VS Code captures where applicable, and writes `MANIFEST.md`. |

### Terminology

| Term | Meaning |
|---|---|
| Non-secret export | App artifact safe to keep in plaintext under `app-settings-backup/` after review. |
| Secret-bearing export | Artifact that may carry tokens, passwords, keys, cookies, or unreviewed values; staged under `secrets-encrypted/`. |
| Candidate review | The scan-only mode; detects apps and reports intent without creating real backup artifacts. |
| Managed app | An app installed and restored by company management (MDM). It usually returns automatically, so it may not need a backup here — though its user-specific state still might. |
| Artifact-local validation | Confirming an export landed in the correct folder — the only validation this runbook owns. |
| Restore source | Where a given app's state will actually come back from after reimage (Git, sync, a copy, a password manager, re-enrollment). |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/backup-apps.sh          # entrypoint
```

Related scripts:

```text
$FRACTOGENESIS_HOME/.internal/apps/backup-docker-settings.sh              # helper — invoked by backup-apps.sh
$FRACTOGENESIS_HOME/.internal/apps/backup-intellij-scratches-consoles.sh  # helper — invoked by backup-apps.sh
$FRACTOGENESIS_HOME/bin/capture-size-audit.sh                            # entrypoint — capacity check for the backup root
```

Artifact roots:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/     # non-secret app artifacts
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/       # secret-bearing app exports, staged for Phase 2F
```

Directories this runbook's steps touch, alphabetized at every level. Omitted siblings are shown as `...`:

```text
$REIMAGE_ARTIFACT_ROOT/
├── app-settings-backup/
│   ├── candidate-review/
│   ├── chrome/
│   ├── docker/
│   ├── intellij/                  # full subtree drawn in backup-intellij.md
│   ├── MANIFEST.md
│   ├── obsidian/
│   │   ├── global-settings/
│   │   └── vault-copy/
│   ├── postman/
│   │   ├── collections/
│   │   ├── environments-redacted/
│   │   └── inventory/
│   ├── raycast/
│   ├── terminal/
│   └── vscode/
│       └── user/
├── ...
├── secrets-encrypted/
│   ├── ...
│   ├── chrome/
│   ├── docker/
│   ├── postman/
│   │   ├── environments/
│   │   └── vault-if-export-allowed/
│   ├── raycast/
│   │   └── quicklinks-if-sensitive/
│   └── ...
└── ...
```

Step 3 consults the managed-inventory artifacts produced by the prior managed-inventory phase under `managed-inventory/`; that layout and the complete `$REIMAGE_ARTIFACT_ROOT` map are drawn once elsewhere:

[[backup-intellij|Backup IntelliJ]] — full `intellij/` subtree

[[master-directory-reference|Master Directory Reference]] — complete artifact-root layout

### Destination Rules

Where each kind of artifact goes. Every per-app export sorts its outputs by these three rules.

| Category | Destination | Rule |
|---|---|---|
| Non-secret app exports | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/<app>/` | Default home for app artifacts that are safe in plaintext. |
| Redacted examples and inventories | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/<app>/` | Keep with the owning app unless they are secret-bearing. |
| Secret-bearing app exports | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/<app>/` | Stage here; the consolidated secrets DMG is built later in Phase 2F. |

### Environment Variables

The `reimage.env` values these scripts depend on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the Phase 2 artifact root where `app-settings-backup/` and `secrets-encrypted/` are written. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. |
| `REIMAGE_WORKSPACE_ROOT` | Local planning area outside the artifact root, used only for optional temporary working notes. |

> [!note]
> `capture-size-audit.sh` also checks the external destination volume configured in `reimage.env`. If that volume is not mounted, resolve it in `prepare-artifact-root.md` before running the audit.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then decide what this run is for. The concepts and the *why* are in [[#How the Workflow Works|How the Workflow Works]]; this is just the checklist.

### Prerequisites

- `REIMAGE_ARTIFACT_ROOT` resolves and its destination volume is mounted (`reimage.env` produced by `prepare-artifact-root.md`).
- You are running commands from `$FRACTOGENESIS_HOME`.
- The managed-inventory phase (`capture-managed-inventory.md`) has already run for this pre-image pass, so its artifacts are available to consult in Step 3.
- Docker Desktop is running **if** you want current image and container inventories captured; settings files are captured either way.

> [!bug] Troubleshooting
> If `REIMAGE_ARTIFACT_ROOT` is empty, fix `reimage.env` or pass `--artifact-root PATH` explicitly on every command below.

### Confirm Your Intent

The decision this phase turns on is **which apps you actually need to back up** — not how. Just because a step exists does not mean it applies to you: app sets differ from person to person, several of the covered apps skew toward developer machines, and some apps you have are restored another way.

For each app, skip the backup here when its state is already covered, and keep it when the state is local-only, easy to miss, or costly to recreate:

| Skip the backup here when… | Keep it when… |
|---|---|
| A managed/MDM reinstall or built-in sync restores it | Its state is local-only or not synced |
| Git or Phase 2B local-file backup already holds the state | The state lives only in the app, not in files you already back up |
| You do not use the app, or do not care about its state | The state is costly or annoying to recreate by hand |

Step 3 helps you make this call with actual detection of what is installed and what management will restore. Managed apps are the common trap: management may bring the app back, but not necessarily its user-specific state.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. Prepare, check capacity, decide your app set, run the automated capture, complete the manual exports, then verify. The manual exports are not cleanup after the script — for the manual-class apps they are the actual backup.

> [!note] Pending toolkit support
> A few commands below assume capabilities being added in the script phase: the `--supported-apps` info mode (Step 1), the `--context` label on `capture-size-audit.sh` (Step 2), and a `--vscode-only` rerun (Step 4). Until each lands, use the fallback noted at its step.

### Step 1 — Prepare and Validate

Confirm the script runs and the environment resolves before writing anything. `backup-apps.sh` self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand.

List what this toolkit can back up, and confirm the script runs:

```bash
cd "$FRACTOGENESIS_HOME"
./bin/backup-apps.sh --supported-apps
```

> [!note]
> Until `--supported-apps` lands, use `./bin/backup-apps.sh --help` to confirm the script runs; the covered apps are the table in [[#What Gets Backed Up, and How|What Gets Backed Up, and How]].

Confirm the artifact root that will be used (scan-only, creates nothing):

```bash
./bin/backup-apps.sh --candidate-review --artifact-root "$REIMAGE_ARTIFACT_ROOT" 2>&1 | head -5
```

### Step 2 — Check Backup-Root Capacity

Run the size audit before writing app artifacts, to confirm the destination has room. The `--context` label keeps this phase's audit distinct from the ones `backup-home` and `backup-repos` run against the same backup root.

```bash
./bin/capture-size-audit.sh --context pre-image-backup-apps
```

Review these lines in the output:

- `Target backup root`
- `Available on /Volumes/<drive>`
- `✓ External drive: enough space` or `✗ External drive: NOT ENOUGH SPACE`

> [!note]
> This audit is global to the Phase 2 backup root. It confirms the destination volume is mounted and shows headroom; it does **not** estimate the size of individual app-controlled exports.

### Step 3 — Determine Which Apps to Back Up

Decide your app set with real detection instead of memory. Two detectors answer two different questions: this runbook's `--candidate-review` scan finds what is *installed*, and the managed-inventory phase — already run before this one — reports what *management will restore* (so you can skip those). Use both, then apply the [[#Confirm Your Intent|Confirm Your Intent]] criteria.

Scan installed apps and see what a real run would create, without touching anything:

```bash
cd "$FRACTOGENESIS_HOME"
./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --candidate-review --open
```

The bundle lands under `app-settings-backup/candidate-review/` and contains a known-candidates summary with an install-detected column, a "planned directories and artifacts" table, a related-app review table (for apps that belong elsewhere, such as Music), and raw installed-app and state-signal files under `raw/`.

Then consult the managed-inventory artifacts from the prior phase to see which installed apps management will bring back, so you can skip them here:

```bash
find "$REIMAGE_ARTIFACT_ROOT/managed-inventory" -maxdepth 2 -name '03-installed-app-bundles.txt' | sort | tail -1
```

> [!note]
> This runbook only *reads* those artifacts — it does not run the capture. If the managed-inventory phase has not run yet, run it first (`capture-managed-inventory.md`) or decide managed apps by hand.

> [!warning] Pitfall
> Detection tells you what is *present*, not what is *worth backing up*. A managed app that reinstalls automatically may still hold local-only user state that management will not restore — judge each app, do not assume.

### Step 4 — Run the Automated Backup

Run the real backup. It creates a folder only for each app it detects, so apps you do not have are silently skipped.

```bash
cd "$FRACTOGENESIS_HOME"
./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

This captures the script-class apps and prepares folders for the manual-class ones:

- **Docker** — `settings-store.json`, `daemon.json`, `contexts/`, and image/container/compose inventories to `app-settings-backup/docker/`; `config.json` staged to `secrets-encrypted/docker/`. `Docker.raw`, image layers, and volumes are intentionally not backed up.
- **VS Code** — extension list, `settings.json`, `keybindings.json`, `snippets/`, and `profiles/` to `app-settings-backup/vscode/`. Caches, logs, and workspace history are intentionally excluded.
- **IntelliJ IDEA** — Scratches, Consoles, and config to `app-settings-backup/intellij/`. The settings ZIP is manual — see [[#IntelliJ Settings Export|Step 5]].
- **Chrome, Postman, Raycast, Obsidian** — an empty, ready folder only, for the manual exports below.
- the stable summary at `app-settings-backup/MANIFEST.md`, with a per-app "Detected / Not detected" row.

Rerun a single script-class portion through the same entrypoint when needed — for example after starting Docker Desktop, or to refresh one app:

```bash
./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --docker-only --open
./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT" --intellij-only --open
```

> [!note]
> A `--vscode-only` rerun is planned for parity with `--docker-only` and `--intellij-only`. Until it lands, rerun the full backup to refresh VS Code.

> [!warning] Pitfall
> A successful run here is **not** a completed phase. It backs up only the script-class apps; Chrome, Postman, Terminal, the IntelliJ settings ZIP, and (if you use them) Raycast and Obsidian still need their manual exports.

> [!bug] Troubleshooting
> If Docker Desktop is not running, `settings-store.json`, `daemon.json`, and `contexts/` are still captured, but `image-inventory.txt` and `container-inventory.txt` are skipped. Start Docker Desktop, wait for the daemon, then rerun `--docker-only`.

### Step 5 — Complete Manual Exports

These exports must be triggered from each app's own UI — the script cannot perform them or prove they are complete. Do the ones you decided to keep in Step 3; skip the rest. For the optional apps (Raycast, Obsidian), the full steps are in [[#Optional App Exports|Supplemental Reference]], indexed at [[#Optional Apps|Optional Apps]].

Each export sorts its outputs by the [[#Destination Rules|Destination Rules]]: reviewed non-secret material under `app-settings-backup/<app>/`, anything secret-bearing under `secrets-encrypted/<app>/`.

> [!bug] Troubleshooting
> If an app was installed after your last script run, its folder will not exist yet. See [[#Troubleshooting|Troubleshooting]] before creating folders by hand.

#### Chrome

Chrome exports are manual: the browser UI owns bookmarks export and password CSV export, and a script cannot prove profile sync state. If Step 4 detected Chrome, its folders already exist; otherwise create them:

```bash
mkdir -p \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome"
```

Export bookmarks from Chrome Desktop:

```text
Chrome > Bookmarks and lists > Bookmark Manager > three-dot menu > Export bookmarks
```

Save the HTML under the non-secret folder:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome/bookmarks_YYYYMMDD-HHMMSS.html
```

Passwords are optional — prefer Chrome profile sync or your approved password manager as the restore source. If you do export, use Chrome Desktop:

```text
Chrome > Settings > Autofill and passwords > Google Password Manager > Settings > Export passwords
```

Save the CSV **only** under secret-bearing staging:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/Chrome Passwords YYYYMMDD-HHMMSS.csv
```

> [!warning] Pitfall
> Never save a password CSV under `app-settings-backup/`, OneDrive, iCloud, email, Desktop, Downloads, or a repo. It belongs only under `secrets-encrypted/chrome/`.

#### Postman

Postman exports are manual because the app UI owns the export flow. Treat Postman data as distinct categories:

| Category | Destination | Rule |
|---|---|---|
| Non-secret collections | `app-settings-backup/postman/collections/` | Safe only after review — no hard-coded tokens, passwords, cookies, or client secrets. |
| Redacted environment examples or notes | `app-settings-backup/postman/environments-redacted/` | Safe when values are removed or replaced with placeholders. |
| Vault exports, if allowed | `secrets-encrypted/postman/vault-if-export-allowed/` | Secret-bearing even when encrypted. Do not bypass export restrictions. |
| Inventory when export is blocked | `app-settings-backup/postman/inventory/` | Redacted list of variable names, owning collection/environment, and restore source. No secret values. |
| External-vault references | `app-settings-backup/postman/README.md` | Document the provider and restore steps, not the secret values. |

If Step 4 detected Postman, its folders already exist; otherwise create them:

```bash
mkdir -p \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/collections" \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/environments-redacted" \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/inventory" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/environments" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/vault-if-export-allowed"
```

Export collections from `Postman Desktop > Collections > Export` and save non-secret ones under `app-settings-backup/postman/collections/`. Before trusting a collection as non-secret, scan it for embedded credentials:

```bash
grep -RniE 'token|password|passwd|secret|apikey|api_key|authorization|bearer|cookie|client_secret' \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/collections" \
  || true
```

Export environments from `Postman Desktop > Environments > Export`. Environments often carry tokens, usernames, passwords, bearer tokens, API keys, or client secrets — stage them under `secrets-encrypted/postman/environments/` unless you are certain they are non-secret, and keep only redacted copies under `app-settings-backup/postman/environments-redacted/` using placeholders such as:

```text
TODO_RESTORE_FROM_POSTMAN_VAULT
TODO_RESTORE_FROM_1PASSWORD
TODO_RESTORE_FROM_AZURE_KEY_VAULT
TODO_REAUTHENTICATE_AFTER_REIMAGE
```

Postman Local Vault export may be blocked by app, workspace, account, or corporate policy. If export is **allowed**, use `Postman Desktop > Vault > Export` and save under `secrets-encrypted/postman/vault-if-export-allowed/` as `postman-vault-secrets-YYYYMMDD-HHMMSS.encrypted.json`. If Postman requests pull from an external vault or password manager, do not duplicate those values — document the restore path in `app-settings-backup/postman/README.md` instead.

> [!warning] Pitfall
> If Vault export is blocked, do not work around the control. Record a redacted inventory under `app-settings-backup/postman/inventory/` (variable names, owning collection/environment, and restore source — no values) and restore from the approved source after reimage.

#### Terminal

Include Terminal only if you use a custom Terminal.app profile (color scheme, font, window size) you do not want to re-create by hand. Export the specific profile, not the whole plist — `com.apple.Terminal.plist` also stores window positions and other machine-specific state that does not restore cleanly.

Terminal exposes profile export only through its UI:

```bash
mkdir -p "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/terminal"
open -a Terminal
```

In Terminal, go to **Settings → Profiles**, select your custom profile, then use the action menu → **Export…** and save it as `<profile-name>.terminal` under:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/terminal/
```

If a specific default window size matters and is not captured by the export, note it alongside the file:

```bash
cat > "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/terminal/window-size-note.txt" <<'EOF'
Default window size: <columns> columns x <rows> rows
Default profile: <profile-name>
EOF
```

#### IntelliJ Settings Export

The scriptable IntelliJ capture ran in [[#Step 4 — Run the Automated Backup|Step 4]]; the settings ZIP is the manual, app-controlled piece. Export it from IntelliJ IDEA and follow the review, validation, and restore detail in its companion runbook:

[[backup-intellij|Backup IntelliJ]]

> [!warning] Pitfall
> IntelliJ HTTP Client environment files can contain working credentials. Route them to Phase 2E encrypted secrets, not the normal IntelliJ backup.

### Step 6 — Verify Outputs

Confirm the exports landed in the right places before moving on. This runbook owns artifact-local validation only — did the file get created, and is it in the correct `app-settings-backup/` or `secrets-encrypted/` location. The cross-phase readiness sign-off happens later in `reimage-prep-checks.md` (Phase 4B).

Confirm the manifest and review what landed:

```bash
test -f "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/MANIFEST.md" && echo "PASS: MANIFEST.md"
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup" -maxdepth 4 -type f | sort 2>/dev/null || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted" -maxdepth 3 -type f | sort 2>/dev/null || true
```

> [!warning] Pitfall
> Do not treat a missing optional note or unfilled template as a failure. Optional notes are not required backup artifacts; at most, a note you intended to capture and forgot is worth a warning, not a blocked phase.

### Optional Apps

These apps are manual and belong to the optional group, so their full steps live under Supplemental Reference to keep the main flow lean. Complete any you kept in Step 3 as part of [[#Step 5 — Complete Manual Exports|Step 5]] — this index just points to each one.

| App | Use when | Steps |
|---|---|---|
| Raycast | Quick Links or settings/data export matter | [[#Raycast|Optional App Exports → Raycast]] |
| Obsidian | Vault content, vault-local config, or a restore-source choice matters | [[#Obsidian|Optional App Exports → Obsidian]] |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The scripts sort artifacts by rule and detect installed apps; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Which installed apps actually warrant a backup here? | Only you can weigh each app against Git, Phase 2B, sync, and managed-reinstall coverage — detection reports presence, not worth. |
| Is a given collection, environment, or Quick Links export actually non-secret? | Only you can judge whether the values are safe in plaintext; the script cannot inspect intent. |
| Export an app's secrets at all, or restore from a password manager, SSO, or sync instead? | Depends on your chosen restore source and on policy — including whether an export is even permitted. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### An app was installed after your last backup run and has no folder

Detection runs only while the script runs, so a newly installed app has no folder yet. Rerun the entrypoint so it is detected and its folders are created:

```bash
./bin/backup-apps.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT"
```

For a single script-class app, use `--docker-only` or `--intellij-only`. For a manual-class app (Chrome, Postman, Terminal, Raycast, Obsidian), create the folders by hand from that app's export section.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Optional App Exports

Raycast and Obsidian are manual-class apps in the optional group. Their folders are still created by [[#Step 4 — Run the Automated Backup|Step 4]] when detected; complete these exports only if you decided to keep them in Step 3.

#### Raycast

Raycast export is manual because the app owns the export flow and the settings export can include sensitive data. Treat Raycast as distinct export types:

| Category | Destination | Rule |
|---|---|---|
| Reviewed non-secret Quick Links JSON | `app-settings-backup/raycast/` | Safe only after reviewing URLs, query strings, identifiers, and internal links. |
| Raycast restore notes and inventory | `app-settings-backup/raycast/` | App-specific notes only. No `.rayconfig` files and no secret values. |
| Sensitive or unreviewed Quick Links JSON | `secrets-encrypted/raycast/quicklinks-if-sensitive/` | Secret-bearing until reviewed. |
| Raycast `.rayconfig` | `secrets-encrypted/raycast/` | Secret-bearing even when password-protected. |

If Step 4 detected Raycast, its folders already exist; otherwise create them:

```bash
mkdir -p \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/quicklinks-if-sensitive"
```

Find the export commands from Raycast root search:

```text
Open Raycast
Search: Export Quicklinks
Search: Export Settings & Data
```

If they do not appear, enable the built-in commands under `Raycast > Settings > Extensions > Quicklinks` and `Raycast > Settings > Extensions > Raycast`.

Use `Export Quicklinks` for the standalone JSON. Save it under the non-secret folder **only after review**:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/raycast-quicklinks-YYYYMMDD-HHMMSS.json
```

If the Quick Links contain or might contain sensitive data, save them under secret-bearing staging instead:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/quicklinks-if-sensitive/raycast-quicklinks-YYYYMMDD-HHMMSS.json
```

Use `Export Settings & Data` for the full `.rayconfig`. Because it is password-protected and carries sensitive data, save it only under secret-bearing staging:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/raycast-settings-and-data-YYYYMMDD-HHMMSS.rayconfig
```

> [!warning] Pitfall
> Do not store the `.rayconfig` export password in this runbook or in any app backup. Keep it in your approved password manager; if you need a reminder, record only a non-secret hint such as `TODO_ENTRY_NAME`.

> [!info] Return
> Back to [[#Optional Apps|Optional Apps]].

#### Obsidian

`backup-apps.sh` prepares the Obsidian folder but does not choose your restore source. The decision here is **which restore source you are using**, and what to record about it.

| Restore source | What to capture |
|---|---|
| Obsidian Sync | Record that the vault is signed in, sync is enabled, and no pending sync or errors show. |
| Git-backed vault | Record Git status, remotes, and whether local commits are pushed or intentionally preserved. |
| OneDrive- or iCloud-backed vault | Record which cloud is the restore source for this vault. |
| External manual copy | Record the copied-vault destination and the notes you spot-checked. |

For a Git-backed vault, capture status without duplicating the vault:

```bash
VAULT="/path/to/obsidian-vault"
cd "$VAULT"
git status -sb
git remote -v
git log --oneline -5
```

For a free manual copy outside Git or cloud sync:

```bash
VAULT="/path/to/obsidian-vault"
DEST="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/obsidian/vault-copy"
mkdir -p "$DEST"
rsync -a "$VAULT/" "$DEST/$(basename "$VAULT")/"
```

To preserve app-global Obsidian settings separately from any vault:

```bash
GLOBAL_OBSIDIAN="$HOME/Library/Application Support/obsidian"
GLOBAL_DEST="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/obsidian/global-settings"
if [[ -d "$GLOBAL_OBSIDIAN" ]]; then
  mkdir -p "$GLOBAL_DEST"
  rsync -a "$GLOBAL_OBSIDIAN/" "$GLOBAL_DEST/"
fi
```

> [!note]
> `.obsidian/` at the vault root holds themes, hotkeys, and community-plugin config. Confirm your chosen restore source actually includes it, or copy it with the vault.

> [!info] Return
> Back to [[#Optional Apps|Optional Apps]].

### Optional Note Capture

Per-app notes, mini checklists, and inventories are optional. Use them only when they reduce risk or preserve a restore decision you are likely to forget. From most central to most app-local:

| Option | Where | Use when |
|---|---|---|
| Central final-validation note | later Phase 4 / final-checks workflow | You want one place for restore-source decisions and notable exceptions. |
| Temporary working note | `$REIMAGE_WORKSPACE_ROOT` or another local area outside `$REIMAGE_ARTIFACT_ROOT` | You need short-lived prep notes while working through the backup. |
| App-local note | `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/<app>/` | The note is tightly coupled to a specific app artifact and worth keeping with it. |

Use app-local notes sparingly; you do not need one for every app. A missing or unfilled optional note should not block final validation by itself — at most it warrants a warning if you meant to capture it and forgot.

### Relationship to Later Phases

The main forward dependency is the secret-staging sequence that ends at the consolidated secrets DMG. Stage secret-bearing app exports under `secrets-encrypted/` as you work through this phase. Phase 2E then handles certificate and Keychain staging. Phase 2F builds the encrypted DMG **once**, after both this phase's app-secret staging and Phase 2E's certificate/Keychain staging are complete, so the DMG covers the full staged secret set in a single build.

If you add any Docker `config.json`, Chrome password CSV, secret-bearing Postman export, or Raycast secret export later, rerun Phase 2F so the DMG includes the complete final secret set before final validation.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link;
  Sequential Steps carries its single link at the end of Step 6.
-->
