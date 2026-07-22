---
title: Backup IntelliJ
back_link: "reimaging-guide#Phase 2D — Backup Apps"
runbook_version: 0.1.0
verb_first: true
primary_scripts:
  - bin/backup-apps.sh
related_scripts:
  - .internal/apps/backup-intellij-scratches-consoles.sh
  - bin/capture-size-audit.sh
artifact_paths:
  - $REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/
  - $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/intellij/
author: Orah Kittrell
last_updated: 2026-07-21
---
[[reimaging-guide#Phase 2D — Backup Apps|← Back to Mac Reimaging Guide]]

# Backup IntelliJ

The IntelliJ-specific companion to [[backup-apps|Backup Apps]] (Phase 2D). It preserves IDE state that Git remotes and project backups miss — Scratches, Consoles, global IDE config, plugins, and project-level `.idea` metadata across every workspace — while keeping credential-bearing HTTP Client files out of the plaintext backup and recording them for the encrypted secrets DMG instead.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#What Gets Backed Up|What Gets Backed Up]]
    - [[#Why HTTP Client Files Are Handled Separately|Why HTTP Client Files Are Handled Separately]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Destination Rules|Destination Rules]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Prepare and Validate|Step 1 — Prepare and Validate]]
    - [[#Step 2 — Run the IntelliJ Capture|Step 2 — Run the IntelliJ Capture]]
    - [[#Step 3 — Export the Settings ZIP|Step 3 — Export the Settings ZIP]]
    - [[#Step 4 — Verify Outputs|Step 4 — Verify Outputs]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Backup Target Reference|Backup Target Reference]]
    - [[#HTTP Client Credential Handling|HTTP Client Credential Handling]]
    - [[#Run the Helper Standalone|Run the Helper Standalone]]
    - [[#OneDrive Guidance|OneDrive Guidance]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Preserve IntelliJ IDE state that is not covered by Git remotes or project-level backups, and record credential-bearing HTTP Client material for the encrypted secrets workflow rather than leaving it loose. IntelliJ earns a dedicated runbook because its backup scope is broader than the lighter app sections in Backup Apps: it mixes global IDE state, Scratches, Consoles, plugins, settings, and per-project metadata.

This runbook owns:

```text
the IntelliJ scriptable capture detail (run through backup-apps.sh --intellij-only)
the manual IntelliJ settings ZIP export
IntelliJ backup validation and restore notes
the full app-settings-backup/intellij/ layout
```

It does not own:

```text
the umbrella app-backup phase and every other app — backup-apps.md (Phase 2D)
general local-file copy — backup-home.md (Phase 2B)
certificate and Keychain staging — Phase 2E
final encrypted DMG packaging — create-secrets-dmg.md (Phase 2F)
cross-phase readiness sign-off — reimage-prep-checks.md (Phase 4B)
```

This runbook can be rerun independently: `backup-apps.sh --intellij-only` re-detects the active config and refreshes the generated IntelliJ content in place, preserving `manual-settings-export/` and `restore-notes/`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. IntelliJ keeps state in two very different places: a global config directory under `~/Library/Application Support/JetBrains/<product>` (Scratches, Consoles, code styles, keymaps, inspections, plugins, options) and per-project `.idea` folders scattered across your workspaces. The capture pulls both, plus diagnostic logs, into `app-settings-backup/intellij/`.

The work is part automated and part manual. `backup-apps.sh --intellij-only` runs the scriptable capture; a manual settings ZIP export from IntelliJ's own UI is a second, cleaner restore path that is usually easier to import after reimage than hand-restoring individual config files. Do both — the ZIP is not a substitute for the scripted capture, and the scripted capture does not produce the ZIP.

The preferred path is the entrypoint: `backup-apps.sh --intellij-only`. It self-locates, loads shared config, and invokes the internal helper — which auto-detects the active IntelliJ config directory (the most recently modified one) and receives the workspace root from `GIT_WORK_REPO_ROOT`. Running the helper directly is possible but reserved for standalone or troubleshooting use (see [[#Run the Helper Standalone|Run the Helper Standalone]]).

### What Gets Backed Up

The scripted capture collects, from the active config directory and every project under the workspace root:

```text
Scratches and Consoles
global IDE config — codestyles, colors, keymaps, inspections, templates, options, tools, plugins, and more
project-level .idea metadata for every workspace, not just the one currently open
diagnostic logs
```

It deliberately excludes HTTP Client environment files and other secret-like material from the plaintext copy (see below). The full target-to-destination map is in [[#Backup Target Reference|Backup Target Reference]].

> [!note]
> The capture scans a broad **workspace root** (all your projects), not IntelliJ's single active-project BasePath. That is why it covers projects you do not currently have open — see [[#Terminology|Terminology]].

### Why HTTP Client Files Are Handled Separately

IntelliJ HTTP Client environment files (`http-client.env.json`, `http-client.private.env.json`) and other credential-like files can hold working tokens, passwords, and client secrets. The capture excludes them from the plaintext `app-settings-backup/intellij/` copy and instead **records** them in a manifest so the later encrypted secrets workflow can package them. They belong in the Phase 2F encrypted DMG, never loose in the IntelliJ backup or in cloud storage. The handling detail and the recommended split-env pattern are in [[#HTTP Client Credential Handling|HTTP Client Credential Handling]].

### Terminology

| Term | Meaning |
|---|---|
| Active config directory | The JetBrains config dir for the running IDE version, e.g. `~/Library/Application Support/JetBrains/IntelliJIdea2026.1`. Auto-detected as the most recently modified `IntelliJIdea*`/`IdeaIC*` directory (override with `IDE_PRODUCT`). |
| Special Files and Folders | IntelliJ's `Help → Diagnostic Tools → Special Files and Folders` screen, which reports the active config, logs, plugins, and Project BasePath. |
| Project BasePath | The path of the *currently open* project/window. It changes with focus, so it is not what the backup scans. |
| Workspace root | The broader directory tree the capture scans for project-level `.idea` metadata (default from `GIT_WORK_REPO_ROOT`), covering all projects. |
| HTTP Client env files | `http-client.env.json` / `http-client.private.env.json` — credential-bearing, routed to the encrypted secrets flow. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/backup-apps.sh          # entrypoint — run with --intellij-only
```

Related scripts:

```text
$FRACTOGENESIS_HOME/.internal/apps/backup-intellij-scratches-consoles.sh   # helper — invoked by backup-apps.sh
$FRACTOGENESIS_HOME/bin/capture-size-audit.sh                              # entrypoint — capacity check for the backup root
```

Artifact roots:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/     # non-secret IDE state
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/intellij/       # secret-bearing staging, packaged in Phase 2F
```

This runbook owns the full `intellij/` layout; it is drawn here once and referenced elsewhere:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/
├── IntelliJIdeaYYYY.N/
│   ├── config-copy/
│   ├── manifests/
│   └── scratches-and-consoles/
├── logs/
│   ├── IntelliJIdeaYYYY.N/
│   └── system-cache-not-copied.txt
├── manifests/
├── manual-settings-export/
│   └── IntelliJ-settings-YYYYMMDD-HHMMSS.zip
├── project-metadata/
├── restore-notes/
└── README.md
```

The complete `$REIMAGE_ARTIFACT_ROOT` map is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Destination Rules

Where each kind of IntelliJ artifact goes.

| Category | Destination | Rule |
|---|---|---|
| Non-secret IDE state | `app-settings-backup/intellij/` | Scratches, Consoles, config copy, project `.idea` metadata, logs, manifests, README. Safe to inspect locally on the external drive. |
| Manual settings ZIP | `app-settings-backup/intellij/manual-settings-export/` | Exported from the IntelliJ UI; a clean second restore path. |
| Restore notes | `app-settings-backup/intellij/restore-notes/` | Sanitized notes only — no secret values. |
| HTTP Client env files and other credential-like files | recorded in a manifest, staged under `secrets-encrypted/intellij/`, packaged into the Phase 2F DMG | Never left loose in `intellij/` or in cloud storage. |

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the Phase 2 artifact root where `app-settings-backup/` and `secrets-encrypted/` live. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. |
| `GIT_WORK_REPO_ROOT` | Work repository root. Also the default IntelliJ **workspace root** scanned for project-level `.idea` metadata — the same value used by the Git repo backup, so set it once (e.g. `/Users/<user>/Development/IdeaProjects`). |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what this run is for. The concepts and the *why* are in [[#How the Workflow Works|How the Workflow Works]]; this is just the checklist.

### Prerequisites

- `REIMAGE_ARTIFACT_ROOT` resolves and its destination volume is mounted (`reimage.env` produced by `prepare-artifact-root.md`).
- You are running commands from `$FRACTOGENESIS_HOME`.
- **IntelliJ is quit before the capture.** A running IDE can flush or overwrite config mid-copy, so close it first (the manual settings ZIP export in Step 3 is the one time you reopen it).

> [!bug] Troubleshooting
> If the active config directory is not found, the helper falls back to every `IntelliJIdea*` / `IdeaIC*` directory under the JetBrains root — see [[#Troubleshooting|Troubleshooting]].

### Confirm Your Intent

- Whether IntelliJ applies to this Mac and you want to preserve IDE state (it is a common developer app, but the [[backup-apps#Confirm Your Intent|Backup Apps intent criteria]] still apply — skip it if Settings Sync or another source already covers it).
- Which **workspace root** to scan for project `.idea` metadata — normally `GIT_WORK_REPO_ROOT`.
- Whether to also export the settings ZIP (recommended — it is the easiest restore path) and whether you need the optional captures (all config dirs, shelves, or the system cache).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order: prepare, run the scripted capture, export the settings ZIP by hand, then verify. The ZIP export is not cleanup after the script — it is a required second restore path.

### Step 1 — Prepare and Validate

Confirm the environment resolves and IntelliJ is closed before anything writes.

Confirm the artifact root and (optionally) the active config directory. `backup-apps.sh` self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand:

```bash
cd "$FRACTOGENESIS_HOME"
./bin/backup-apps.sh --supported-apps
```

Confirm IntelliJ is not running:

```bash
pgrep -afil 'IntelliJ|idea' || echo "OK: IntelliJ does not appear to be running"
```

You can cross-check the active config path inside IntelliJ under `Help → Diagnostic Tools → Special Files and Folders`, then compare it with the capture's `manifests/intellij-config-dirs.tsv`.

> [!note]
> That same screen reports a **PROJECT BasePath** for whatever project is focused. It is expected that it does not match what the backup scans — the capture uses the broader workspace root on purpose, so all projects are covered.

### Step 2 — Run the IntelliJ Capture

Run the scriptable capture through the Phase 2D entrypoint. `--intellij-only` skips the Docker and VS Code captures and runs just the IntelliJ helper:

```bash
cd "$FRACTOGENESIS_HOME"
./bin/backup-apps.sh --intellij-only --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

The entrypoint defaults the workspace root to `GIT_WORK_REPO_ROOT` from `reimage.env`, and the helper auto-detects the active IntelliJ config directory (the most recently modified one under the JetBrains root) — so neither is passed here. Override the workspace root with `--intellij-workspace-root PATH` if you need a different tree.

This refreshes the generated IntelliJ content in place under `app-settings-backup/intellij/` (preserving `manual-settings-export/` and `restore-notes/`), records HTTP Client and secret-like candidates in manifests, and prepares `secrets-encrypted/intellij/` for the Phase 2F packaging.

Optional passthrough flags, when they apply:

```text
--intellij-all-config-dirs        back up every IntelliJIdea*/IdeaIC* config dir, not just the active one
--intellij-workspace-max-depth N  change the .idea scan depth (default 6)
--intellij-skip-workspaces        skip the project-level .idea scan
--intellij-include-shelf          include .idea/shelf folders (skipped by default)
--intellij-include-system-cache   copy the IntelliJ system/cache dir (large; off by default)
```

> [!warning] Pitfall
> Do not treat a running-IDE warning lightly: if IntelliJ was open during the copy, config files may be partial. Quit IntelliJ and rerun `--intellij-only` rather than trusting a capture taken while it was running.

### Step 3 — Export the Settings ZIP

This is the manual, app-controlled restore path. Open IntelliJ just for this export, then quit it again before any rerun.

In IntelliJ: `File → Manage IDE Settings → Export Settings`. Save under:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manual-settings-export/IntelliJ-settings-YYYYMMDD-HHMMSS.zip
```

Include at least code style schemes, color schemes/themes, keymaps, inspection profiles, live and file templates, file types, tools/external tools, path variables, and global data sources if shown.

> [!note]
> The ZIP is usually easier to import after reimage than restoring individual config files, which is why it is worth capturing even though the scripted backup already copied most of this state.

### Step 4 — Verify Outputs

Confirm the capture landed and that no credential files leaked into the plaintext backup. This runbook owns artifact-local validation only; the cross-phase readiness sign-off happens later in `reimage-prep-checks.md` (Phase 4B).

Count files and confirm the generated shape:

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij" -type f | wc -l
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij" -maxdepth 2 -type d | sort
```

Review the manifests:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manifests/intellij-config-dirs.tsv
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manifests/files-backed-up.txt
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manifests/http-client-env-candidates.txt
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manifests/secret-like-files.txt
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manifests/workspace-projects.tsv
```

Confirm there are **no** loose HTTP Client or secret-like files in the plaintext backup:

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij" -type f \
  \( -name 'http-client.env.json' -o -name 'http-client.private.env.json' -o -name '*.env.json' \
     -o -name 'dataSources.local.xml' -o -name 'dataSourcesLocal.xml' \) -print
```

> [!warning] Pitfall
> The command above must print **nothing**. If it lists files, remove them from `app-settings-backup/intellij/` and make sure they are captured by the Phase 2F encrypted secrets workflow instead.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script sorts artifacts and detects config directories; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Does `http-client.env.json` currently hold real credentials? | If it does, treat it as a private file and route it to the encrypted DMG until it is split into shared vs private env files — only you know its contents. |
| Back up only the active config directory, or all of them? | `--intellij-all-config-dirs` captures every installed IntelliJ version; worth it only if you rely on more than the current one. |
| Include shelves or the system cache? | Both are large and rarely needed for restore; include them only for a specific diagnostic reason. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### No IntelliJ config directory was found

The capture auto-detects the active config directory as the most recently modified `IntelliJIdea*` / `IdeaIC*` directory under `~/Library/Application Support/JetBrains/`. If none exist, it exits with a prerequisite error. If your config lives under a non-standard directory name, set `IDE_PRODUCT` explicitly and rerun. An explicit `IDE_PRODUCT` that points to a missing directory prints a warning and falls back to backing up every `IntelliJIdea*` / `IdeaIC*` directory.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Backup Target Reference

The scriptable capture's targets and where each lands under `app-settings-backup/intellij/`.

| Target | Why it matters | Destination |
|---|---|---|
| `scratches/` | Scratch files and scratch HTTP requests | `.../<product>/scratches-and-consoles/scratches/` |
| `consoles/` | Database query consoles | `.../<product>/scratches-and-consoles/consoles/` |
| `codestyles/` | Code style schemes | `.../<product>/config-copy/codestyles/` |
| `inspection/`, `inspectionProfiles/` | Inspection profiles | `.../<product>/config-copy/` |
| `colors/` | Color schemes and themes | `.../<product>/config-copy/colors/` |
| `keymaps/` | Custom keymaps | `.../<product>/config-copy/keymaps/` |
| `templates/`, `fileTemplates/` | Live and file templates | `.../<product>/config-copy/` |
| `options/` | IDE options and appearance | `.../<product>/config-copy/options/` |
| `plugins/` and plugin manifest | Plugin list and state | `.../<product>/config-copy/plugins/` and manifests |
| Project-level `.idea` | Run configs, code style, inspections, selected project settings | `.../project-metadata/` |
| `http-client.env.json`, `http-client.private.env.json` | May hold working credentials | recorded in manifests → Phase 2F encrypted DMG |

### HTTP Client Credential Handling

Treat these as secrets if they contain real credentials, and keep them out of the plaintext backup and out of unencrypted cloud storage:

```text
http-client.env.json
http-client.private.env.json
*.env.json
*credential*
*secret*
*.pem
*.key
*.p12
*.pfx
*.jks
*.keystore
dataSources.local.xml
```

The capture excludes these from the clear-text copy and lists them in `manifests/http-client-env-candidates.txt` and `manifests/secret-like-files.txt` so Phase 2E/2F can stage and encrypt them into `all-secrets-YYYYMMDD-HHMMSS.dmg`. Store the DMG password in your approved password manager.

The preferred HTTP Client layout after restore splits secret from non-secret:

```text
http-client.env.json           # non-secret shared values only
http-client.private.env.json   # passwords, tokens, client secrets, private values
```

If `http-client.env.json` currently holds working credentials, treat it as a private file until it is split.

### Run the Helper Standalone

The single source for the capture logic is the helper; running it directly is the non-entrypoint path (for a standalone rerun or troubleshooting), with no duplicated commands to maintain:

```bash
.internal/apps/backup-intellij-scratches-consoles.sh \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --workspace-root "$GIT_WORK_REPO_ROOT"
```

Run standalone, the helper has no baked-in workspace default, so pass `--workspace-root` (or export `INTELLIJ_WORKSPACE_ROOT`) for the project-level scan; the active config directory is still auto-detected.

> [!info] Return
> This is the same capture `backup-apps.sh --intellij-only` runs. Prefer the entrypoint in [[#Step 2 — Run the IntelliJ Capture|Step 2]] unless you specifically need to bypass it.

### OneDrive Guidance

Reasonable OneDrive candidates:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manifests/
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manual-settings-export/
backup-intellij.md
```

Do **not** put these in OneDrive unencrypted: `http-client.env.json`, `http-client.private.env.json`, `*.env.json`, private certificates, client secrets, bearer tokens, passwords, or `dataSources.local.xml`. Encrypted DMG files may be acceptable if company policy allows encrypted secret archives in OneDrive.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link.
-->
