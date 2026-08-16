[[reimaging-guide#Phase 2D — Backup Apps|← Back to Mac Reimaging Guide]]

# Backup IntelliJ

**Last updated:** 2026-08-03

The IntelliJ-specific companion to Backup Apps (Phase 2D). It preserves IDE state that Git remotes and project backups miss — Scratches, Consoles, global IDE config, plugins, and project-level `.idea` metadata across every project — while keeping credential-bearing files out of the plaintext backup and staging the ones you select into the encrypted secrets DMG instead.

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

> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Preserve IntelliJ IDE state that is not covered by Git remotes or project-level backups, and stage the credential-bearing material you select into the encrypted secrets workflow rather than leaving it loose. IntelliJ earns a dedicated runbook because its backup scope is broader than the lighter app sections in Backup Apps: it mixes global IDE state, Scratches, Consoles, plugins, settings, and per-project metadata.

**What it sets up**

- **A clear-text IDE state copy** — Scratches, Consoles, selected global config, per-project `.idea` metadata, and diagnostic logs under `app-settings-backup/intellij/`, safe to inspect on the external drive.
- **A reviewed secret staging area** — credential-shaped files matching patterns you check are copied into `secrets-encrypted/intellij/`, split by the root they came from, and recorded in a manifest.
- **A second restore path** — the manual settings ZIP, exported from the IntelliJ UI, independent of the scripted copy.

**What the rest of the workflow relies on it for**

- Phase 3C encrypts the staged IntelliJ secrets into the consolidated DMG.
- The post-image `restore-intellij` phase reads this layout to bring IDE state back.
- The Phase 6B readiness sign-off checks the capture and the settings ZIP exist.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| the IntelliJ scriptable capture detail, run through `backup-apps.sh --intellij-only` | the umbrella app-backup phase and every other app — `backup-apps` (Phase 2D) |
| the manual IntelliJ settings ZIP export | general local-file copy — `backup-home` (Phase 2B) |
| IntelliJ backup validation and restore notes | repo-local files a project happens to contain — `backup-repos` (Phase 2A) |
| the full `app-settings-backup/intellij/` and `secrets-encrypted/intellij/` layouts | certificate and Keychain staging — `stage-certs-keychain` (Phase 3A) |
| | encrypted DMG packaging — `create-secrets-dmg` (Phase 3C) |
| | cross-phase readiness sign-off — `reimage-prep-checks` (Phase 6B) |

This runbook can be rerun independently: `backup-apps.sh --intellij-only` re-detects the active config and refreshes the generated IntelliJ content in place, preserving `manual-settings-export/` and `restore-notes/`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. IntelliJ keeps state in two very different places: a global config directory under `~/Library/Application Support/JetBrains/<product>` (Scratches, Consoles, code styles, keymaps, inspections, plugins, options) and per-project `.idea` folders scattered across your projects. The capture pulls both, plus diagnostic logs, into `app-settings-backup/intellij/`.

The work is part automated and part manual. `backup-apps.sh --intellij-only` runs the scriptable capture; a manual settings ZIP export from IntelliJ's own UI is a second, cleaner restore path that is usually easier to import after reimage than hand-restoring individual config files. Do both — the ZIP is not a substitute for the scripted capture, and the scripted capture does not produce the ZIP.

The preferred path is the entrypoint: `backup-apps.sh --intellij-only`. It self-locates, loads shared config, and invokes the internal helper — which auto-detects the active IntelliJ config directory (the most recently modified one) and receives the projects root from `GIT_WORK_REPO_ROOT`. Running the helper directly is possible but reserved for standalone or troubleshooting use (see [[#Run the Helper Standalone|Run the Helper Standalone]]).

### What Gets Backed Up

The scripted capture collects, from the active config directory and every project under the projects root:

```text
Scratches and Consoles
global IDE config — codestyles, colors, keymaps, inspections, templates, options, tools, plugins, and more
project-level .idea metadata for every project, not just the one currently open
diagnostic logs
```

It deliberately excludes HTTP Client environment files and other secret-like material from the plaintext copy (see below). The full target-to-destination map is in [[#Backup Target Reference|Backup Target Reference]].

> [!note]
> The capture scans a broad **projects root** (all your projects), not IntelliJ's single active-project BasePath. That is why it covers projects you do not currently have open — see [[#Terminology|Terminology]].

### Why HTTP Client Files Are Handled Separately

IntelliJ HTTP Client environment files (`http-client.env.json`, `http-client.private.env.json`) and other credential-like files can hold working tokens, passwords, and client secrets. The capture keeps them out of the plaintext `app-settings-backup/intellij/` copy, and stages the ones matching your reviewed patterns into `secrets-encrypted/intellij/` for the Phase 3C encrypted DMG. Which patterns count as secrets is yours to choose in a review template that follows the same `[x]`/`[ ]` model as `gitignore-review-template.txt` — nothing is staged unless you check it. They belong in the encrypted DMG, never loose in the IntelliJ backup or in cloud storage. The selection files and the recommended split-env pattern are in [[#HTTP Client Credential Handling|HTTP Client Credential Handling]].

### Terminology

| Term | Meaning |
|---|---|
| Active config directory | The JetBrains config dir for the running IDE version, e.g. `~/Library/Application Support/JetBrains/IntelliJIdea2026.1`. Auto-detected as the most recently modified `IntelliJIdea*`/`IdeaIC*` directory (override with `IDE_PRODUCT`). |
| Special Files and Folders | IntelliJ's `Help → Diagnostic Tools → Special Files and Folders` screen, which reports the active config, logs, plugins, and Project BasePath. |
| Project BasePath | The path of the *currently open* project/window. It changes with focus, so it is not what the backup scans. |
| Projects root | The broader directory tree the capture scans for project-level `.idea` metadata (default from `GIT_WORK_REPO_ROOT`), covering all projects. |
| HTTP Client env files | `http-client.env.json` / `http-client.private.env.json` — credential-bearing, routed to the encrypted secrets flow. |
| Secret review template | `intellij-secret-review-template.txt` under `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/secret-review/`. `[x]`-checked patterns are staged into the encrypted secrets tree; nothing is preselected. |
| Plaintext exclude list | `backup-exclude-list.txt` in the same folder. One pattern per line; drops noise (e.g. `httpRequests/`, `shelf/`) from the clear-text copy. Mirrors `gitignore-superset/backup-exclude-list.txt`. |

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
$FRACTOGENESIS_HOME/.internal/apps/backup-intellij-state.sh   # helper — invoked by backup-apps.sh
$FRACTOGENESIS_HOME/bin/report-size-audit.sh                 # entrypoint — capacity check for the backup root
```

Artifact roots:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/               # non-secret IDE state
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/intellij/                 # staged secrets, packaged in Phase 3C
```

Your reviewed secret selections are written to the external artifact root, the same way the gitignore superset writes its review template:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/secret-review/intellij-secret-review-template.txt   # [x] = stage into the DMG
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/secret-review/backup-exclude-list.txt               # noise dropped from the clear-text copy
```

Both are seeded on the first capture (every pattern unchecked) and edited in place afterward. To keep a reviewed set across reimages, copy them into `$REIMAGE_WORKSPACE_ROOT/intellij-secrets/` by hand, and copy them back to the artifact root before a later run — the same manual persistence pattern the gitignore review template uses.

This runbook owns both `intellij/` layouts; they are drawn here once and referenced elsewhere.

The clear-text copy:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/
├── IntelliJIdeaYYYY.N/
│   ├── config-copy/
│   └── scratches-and-consoles/
├── logs/
│   ├── IntelliJIdeaYYYY.N/
│   └── system-cache-not-copied.txt
├── manifests/
├── manual-settings-export/
│   └── IntelliJ-settings-YYYYMMDD-HHMMSS.zip
├── project-metadata/
├── restore-notes/
├── secret-review/
└── README.md
```

The staged secrets, split by the root each file came from. Paths under each
bucket are relative to *that* root, so a restore is one substitution:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/intellij/
├── ide-config/                 # relative to ~/Library/Application Support/JetBrains/
│   └── IntelliJIdeaYYYY.N/
│       └── options/
└── projects/                   # relative to $GIT_WORK_REPO_ROOT
    └── <project>/
        └── .idea/
```

An `other/` bucket appears only if a staged file came from neither root — it should stay empty.

The complete `$REIMAGE_ARTIFACT_ROOT` map is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Destination Rules

Where each kind of IntelliJ artifact goes.

| Category | Destination | Rule |
|---|---|---|
| Non-secret IDE state | `app-settings-backup/intellij/` | Scratches, Consoles, config copy, project `.idea` metadata, logs, manifests, README. Safe to inspect locally on the external drive. |
| Manual settings ZIP | `app-settings-backup/intellij/manual-settings-export/` | Exported from the IntelliJ UI; a clean second restore path. |
| Restore notes | `app-settings-backup/intellij/restore-notes/` | Sanitized notes only — no secret values. |
| Credential-like files matching your reviewed patterns | `secrets-encrypted/intellij/ide-config/` or `.../projects/`, by which root the file came from; packaged into the Phase 3C DMG | Staged only when checked in the review template. Never left loose in `intellij/` or in cloud storage. |

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the Phase 2 artifact root where `app-settings-backup/` and `secrets-encrypted/` live. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. |
| `GIT_WORK_REPO_ROOT` | Work repository root. Also the default IntelliJ **projects root** scanned for project-level `.idea` metadata — the same value used by the Git repo backup, so set it once (e.g. `/Users/<user>/Development/IdeaProjects`). |
| `REIMAGE_WORKSPACE_ROOT` | Optional. Local workspace where you can keep a persisted copy of your IntelliJ secret selections (`intellij-secrets/`) between reimages. Not required for the capture — the selections live on the artifact root. Resolved by `prepare-artifact-root.md`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what this run is for.

### Prerequisites

- `REIMAGE_ARTIFACT_ROOT` resolves and its destination volume is mounted (`reimage.env` produced by `prepare-artifact-root.md`).
- You are running commands from `$FRACTOGENESIS_HOME`.
- **IntelliJ is quit before the capture.** A running IDE can flush or overwrite config mid-copy, so close it first (the manual settings ZIP export in Step 3 is the one time you reopen it).

> [!bug] Troubleshooting
> [!bug] Troubleshooting
> If the capture exits with a prerequisite error naming the JetBrains root, see [[#No IntelliJ config directory was found|No IntelliJ config directory was found]].

### Confirm Your Intent

- Whether IntelliJ applies to this Mac and you want to preserve IDE state — skip it if Settings Sync or another source already covers it.
- Which **projects root** to scan for project `.idea` metadata — normally `GIT_WORK_REPO_ROOT`.
- Whether to also export the settings ZIP (recommended — it is the easiest restore path) and whether you need the optional captures (all config dirs, shelves, or the system cache).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order: prepare, run the scripted capture, export the settings ZIP by hand, then verify. The ZIP export is not cleanup after the script — it is a required second restore path.

### Step 1 — Prepare and Validate

Confirm the environment resolves and IntelliJ is closed before anything writes.

Confirm the artifact root and (optionally) the active config directory. `backup-apps.sh` self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand:

```bash
./bin/backup-apps.sh --supported-apps
```

Confirm IntelliJ is not running:

```bash
pgrep -xl "idea" || echo "OK: IntelliJ does not appear to be running"
```

IntelliJ's executable is `Contents/MacOS/idea`, so the process to look for is named `idea`, not `IntelliJ`. Step 2 runs the same check and warns if it fires — but it does not stop, so a capture taken with the IDE open still lands. When that happens it writes `manifests/ide-was-running-during-capture.txt`, and quitting IntelliJ then rerunning `--intellij-only` clears both the marker and the doubt.

Now check the two files that decide what this capture keeps and what it treats as a secret. Both are seeded on first use and then reused, so on a second reimage — or a re-run after editing them — the ones already in your workspace are what the run will obey:

```text
secret-review/intellij-secret-review-template.txt   which credential-shaped files get staged
secret-review/backup-exclude-list.txt               noise dropped from the clear-text copy
```

```bash
ls -la "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/secret-review/"
```

If they already exist, read them before running — they carry the decisions you made last time, not defaults. If they do not, Step 2 seeds them and **nothing is staged as a secret on that first run**, because nothing is checked yet. That is why the capture is normally two passes: run it, review the template, run it again.

> [!warning] Pitfall
> An empty `secrets-encrypted/intellij/` after a run does not mean no secrets were found. It usually means the review template exists but nothing in it is checked. Confirm against `manifests/intellij-secret-candidates.txt` — candidates listed there with an empty staging directory means the review is still outstanding.

You can cross-check the active config path inside IntelliJ under `Help → Diagnostic Tools → Special Files and Folders`, then compare it with the capture's `manifests/intellij-config-dirs.tsv`.

> [!note]
> That same screen reports a **PROJECT BasePath** for whatever project is focused. It is expected that it does not match what the backup scans — the capture uses the broader projects root on purpose, so all projects are covered.

### Step 2 — Run the IntelliJ Capture

Run the scriptable capture through the Phase 2D entrypoint. `--intellij-only` skips the Docker and VS Code captures and runs just the IntelliJ helper:

```bash
./bin/backup-apps.sh --intellij-only --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

The entrypoint defaults the projects root to `GIT_WORK_REPO_ROOT` from `reimage.env`, and the helper auto-detects the active IntelliJ config directory (the most recently modified one under the JetBrains root) — so neither is passed here. Override the projects root with `--intellij-projects-root PATH` if you need a different tree.

This refreshes the generated IntelliJ content in place under `app-settings-backup/intellij/` (preserving `manual-settings-export/` and `restore-notes/`) and stages the secrets matching your reviewed patterns into `secrets-encrypted/intellij/` for the Phase 3C packaging.

> [!note]
> On the first capture, `intellij-secret-review-template.txt` and `backup-exclude-list.txt` are written to `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/secret-review/` with every pattern unchecked, and nothing is staged. Check the patterns you want staged (for example `http-client.private.env.json`), then rerun `--intellij-only` to stage the matches. Credential-shaped files are kept out of the plaintext copy on every run regardless.

Optional passthrough flags, when they apply:

```text
--intellij-all-config-dirs        back up every IntelliJIdea*/IdeaIC* config dir, not just the active one
--intellij-projects-max-depth N  change the .idea scan depth (default 6)
--intellij-skip-project-scan        skip the project-level .idea scan
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

Confirm the capture landed and that no credential files leaked into the plaintext backup. This runbook owns artifact-local validation only; the cross-phase readiness sign-off happens later in `reimage-prep-checks.md` (Phase 6B).

Count files and confirm the generated shape:

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij" -type f | wc -l
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij" -maxdepth 2 -type d | sort
```

Review the manifests:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manifests/intellij-config-dirs.tsv
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manifests/files-backed-up.txt
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manifests/intellij-secret-candidates.txt
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manifests/intellij-secrets-staged.tsv
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manifests/projects.tsv
```

Confirm there are **no** loose HTTP Client or secret-like files in the plaintext backup:

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij" -type f \
  \( -name 'http-client.env.json' -o -name 'http-client.private.env.json' -o -name '*.env.json' \
     -o -name 'dataSources.local.xml' -o -name 'dataSourcesLocal.xml' \) -print
```

> [!warning] Pitfall
> The command above must print **nothing**. If it lists files, remove them from `app-settings-backup/intellij/` and make sure they are captured by the Phase 3C encrypted secrets workflow instead.

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

One prerequisite failure has a fix long enough to break a step's flow. The step that hits it links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### No IntelliJ config directory was found

The capture auto-detects the active config directory as the most recently modified `IntelliJIdea*` / `IdeaIC*` directory under `~/Library/Application Support/JetBrains/`. If none exist, it exits with a prerequisite error. If your config lives under a non-standard directory name, set `IDE_PRODUCT` explicitly and rerun. An explicit `IDE_PRODUCT` that points to a missing directory prints a warning and falls back to backing up every `IntelliJIdea*` / `IdeaIC*` directory.

[[#Step 2 — Run the IntelliJ Capture|⮕ Continue to Step 2 — Run the IntelliJ Capture]]

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
| `http-client.env.json`, `http-client.private.env.json` | May hold working credentials | staged to `secrets-encrypted/intellij/` when checked → Phase 3C encrypted DMG |

### HTTP Client Credential Handling

Secret handling is driven by two files under `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/secret-review/`: `intellij-secret-review-template.txt` (which patterns to stage) and `backup-exclude-list.txt` (noise to drop from the clear-text copy). The review template is seeded with these patterns, every one unchecked — change `[ ]` to `[x]` on the ones whose files you want staged:

```text
http-client.env.json
http-client.private.env.json
*.env.json
*.secrets.json
*.private.env.json
dataSources.local.xml
dataSourcesLocal.xml
*.pem
*.key
*.p12
*.pfx
*.jks
*.keystore
*credential*
*secret*
```

Credential-shaped files are kept out of the clear-text copy on every run — a fixed safety floor covers every seeded secret pattern — including `*.pem`, `*.key`, `*credential*` and `*secret*` — even before you review anything. Files matching a checked pattern are copied into `secrets-encrypted/intellij/` and recorded in `manifests/intellij-secrets-staged.tsv`, so Phase 3C encrypts them into `all-secrets-YYYYMMDD-HHMMSS.dmg`. Store the DMG password in your approved password manager.

The preferred HTTP Client layout after restore splits secret from non-secret:

```text
http-client.env.json           # non-secret shared values only
http-client.private.env.json   # passwords, tokens, client secrets, private values
```

If `http-client.env.json` currently holds working credentials, treat it as a private file until it is split.

### Run the Helper Standalone

The single source for the capture logic is the helper; running it directly is the non-entrypoint path (for a standalone rerun or troubleshooting), with no duplicated commands to maintain:

```bash
.internal/apps/backup-intellij-state.sh \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --projects-root "$GIT_WORK_REPO_ROOT"
```

Run standalone, the helper has no baked-in projects-root default, so pass `--projects-root` (or export `INTELLIJ_PROJECTS_ROOT`) for the project-level scan; the active config directory is still auto-detected. The secret review files are written under the artifact root, so no extra flag is needed to enable staging.

This is the same capture `backup-apps.sh --intellij-only` runs — prefer the entrypoint unless you specifically need to bypass it.

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
