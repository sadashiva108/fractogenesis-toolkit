[[reimaging-guide#Phase 2D — Backup Apps|← Back to Mac Reimaging Guide]]

# Backup IntelliJ

**Last updated:** 2026-09-02

The IntelliJ-specific companion to Backup Apps (Phase 2D). It preserves IDE state that Git remotes and project backups miss — Scratches, Consoles, global IDE config, plugins, and project-level `.idea` metadata across every project — while keeping credential-bearing files out of the plaintext backup and staging the ones you select into the encrypted secrets DMG instead.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#What Gets Backed Up|What Gets Backed Up]]
    - [[#Why HTTP Client Files Are Handled Separately|Why HTTP Client Files Are Handled Separately]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Bundle Layout|Bundle Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Prepare and Validate|Step 1 — Prepare and Validate]]
    - [[#Step 2 — Run the IntelliJ Backup|Step 2 — Run the IntelliJ Backup]]
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

The preferred path is the entrypoint: `backup-apps.sh --intellij-only`. It self-locates, loads shared config, and invokes the internal helper — which auto-detects the active IntelliJ config directory (the most recently modified one) and receives the projects root from `LOCAL_WORK_REPO_ROOT`. Running the helper directly is possible but reserved for standalone or troubleshooting use (see [[#Run the Helper Standalone|Run the Helper Standalone]]).

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
| Projects root | The broader directory tree the capture scans for project-level `.idea` metadata (default from `LOCAL_WORK_REPO_ROOT`), covering all projects. |
| HTTP Client env files | `http-client.env.json` / `http-client.private.env.json` — credential-bearing, routed to the encrypted secrets flow. |
| Secret review template | `intellij-secret-review-template.txt` under `$REIMAGE_WORKSPACE_ROOT/intellij-review/`. `[x]`-checked patterns are staged into the encrypted secrets tree; nothing is preselected. |
| Plaintext exclude list | `intellij-plaintext-exclude-list.txt` in the same folder. One pattern per line; drops noise (e.g. `httpRequests/`, `shelf/`) from the clear-text copy. Same file format as `gitignore-superset/backup-exclude-list.txt`, but a separate file with a separate purpose. |
| Review evidence copy | The copy of both files written into `app-settings-backup/intellij/secret-review/` on every run. Read-only in practice: it records what the capture obeyed, and the next run overwrites it from the workspace originals. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/backup-apps.sh                         # entrypoint -- run with --intellij-only
```

Related scripts, alphabetical:

```text
$FRACTOGENESIS_HOME/.internal/apps/backup-intellij-state.sh    # helper -- invoked by backup-apps.sh
$FRACTOGENESIS_HOME/bin/report-size-audit.sh                   # entrypoint -- capacity check for the backup root
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/           # non-secret IDE state
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/intellij/             # staged secrets, packaged in Phase 3C
$REIMAGE_WORKSPACE_ROOT/intellij-review/                       # your reviewed selections, kept outside the artifact root
```

### Bundle Layout

Where each kind of IntelliJ artifact lands. Non-secret IDE state — scratches, consoles, the config copy, project `.idea` metadata, logs, manifests and the README — goes under `app-settings-backup/intellij/`, safe to inspect on the external drive. The manual settings ZIP sits in `manual-settings-export/` as a second, app-controlled restore path, and `restore-notes/` holds sanitized notes only, never secret values. A credential-like file matching your reviewed patterns is staged into `secrets-encrypted/intellij/` for the Phase 3C DMG, never left loose in `intellij/` and never in cloud storage. This runbook owns both `intellij/` layouts:

```text
$REIMAGE_ARTIFACT_ROOT/
├── app-settings-backup/
│   ├── ...
│   ├── intellij/
│   │   ├── IntelliJIdeaYYYY.N/
│   │   │   ├── config-copy/
│   │   │   └── scratches-and-consoles/
│   │   ├── logs/
│   │   │   ├── IntelliJIdeaYYYY.N/
│   │   │   └── system-cache-not-copied.txt
│   │   ├── manifests/
│   │   ├── manual-settings-export/
│   │   │   └── IntelliJ-settings-YYYYMMDD-HHMMSS.zip
│   │   ├── project-metadata/
│   │   ├── README.md
│   │   ├── restore-notes/
│   │   └── secret-review/
│   └── ...
├── ...
├── secrets-encrypted/
│   ├── ...
│   ├── intellij/
│   │   ├── ide-config/
│   │   │   └── IntelliJIdeaYYYY.N/
│   │   │       └── options/
│   │   └── projects/
│   │       └── <project>/
│   │           └── .idea/
│   └── ...
└── ...
```

The staged secrets are split by the root each file came from, and paths under each bucket are relative to *that* root, so a restore is one substitution: `ide-config/` is relative to `~/Library/Application Support/JetBrains/`, and `projects/` is relative to `$LOCAL_WORK_REPO_ROOT`. An `other/` bucket appears only if a staged file came from neither root — it should stay empty.

Your reviewed selections live in the workspace instead, so they survive the artifact root and carry across reimages:

```text
$REIMAGE_WORKSPACE_ROOT/
├── ...
├── intellij-review/
│   ├── intellij-plaintext-exclude-list.txt
│   └── intellij-secret-review-template.txt
└── ...
```

`intellij-secret-review-template.txt` decides what is staged into the DMG — a checked `[x]` row stages that pattern — and `intellij-plaintext-exclude-list.txt` names the noise dropped from the clear-text copy. Seed them with `./bin/backup-apps.sh --init-intellij-review`, edit them in place, and every later run reads them from there, so there is nothing to copy back before a rerun. This resolves the same way the staged-certs fragments do: the workspace copy wins when `$REIMAGE_WORKSPACE_ROOT/intellij-review/` exists. With no `REIMAGE_WORKSPACE_ROOT` set, both files fall back to living in the artifact root and are seeded there on first capture; everything still works, but the selections die with the drive.

Each run also writes a copy of both files into `app-settings-backup/intellij/secret-review/`. That copy is evidence, not a control surface — it records which patterns the capture obeyed, so a restore months later can tell. Editing it changes nothing; the next run overwrites it from the workspace originals.

The complete `$REIMAGE_ARTIFACT_ROOT` map is drawn once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the Phase 2 artifact root where `app-settings-backup/` and `secrets-encrypted/` live. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. |
| `LOCAL_WORK_REPO_ROOT` | Work repository root. Also the default IntelliJ **projects root** scanned for project-level `.idea` metadata — the same value used by the Git repo backup, so set it once (e.g. `/Users/<user>/Development/IdeaProjects`). |
| `REIMAGE_WORKSPACE_ROOT` | Local workspace holding `intellij-review/`, the durable copy of your IntelliJ secret selections. Every run reads them from here; with the value unset both files fall back to the artifact root and die with the drive. Resolved by `prepare-artifact-root.md`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what this run is for.

### Prerequisites

- `REIMAGE_ARTIFACT_ROOT` resolves and its destination volume is mounted (`reimage.env` produced by `prepare-artifact-root.md`).
- `REIMAGE_WORKSPACE_ROOT` is set in `reimage.env`. Your review selections live there so they outlast the artifact root; without it they can only be written to the drive.
- You are running commands from `$FRACTOGENESIS_HOME`.
- **IntelliJ is quit before the capture.** A running IDE can flush or overwrite config mid-copy, so close it first (the manual settings ZIP export in Step 3 is the one time you reopen it).

> [!bug] Troubleshooting
> If the capture exits with a prerequisite error naming the JetBrains root, see [[#No IntelliJ config directory was found|No IntelliJ config directory was found]].

### Confirm Your Intent

- Whether IntelliJ applies to this Mac and you want to preserve IDE state — skip it if Settings Sync or another source already covers it.
- Which **projects root** to scan for project `.idea` metadata — normally `LOCAL_WORK_REPO_ROOT`.
- Whether to also export the settings ZIP (recommended — it is the easiest restore path) and whether you need the optional captures (all config dirs, shelves, or the system cache).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order: prepare, run the scripted capture, export the settings ZIP by hand, then verify. The ZIP export is not cleanup after the script — it is a required second restore path.

### Step 1 — Prepare and Validate

Confirm the environment resolves and IntelliJ is closed before anything writes.

`backup-apps.sh` self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand — the artifact root was already confirmed in Phase 2D and nothing here changes it.

Confirm IntelliJ is not running:

```bash
pgrep -xl "idea" || echo "OK: IntelliJ does not appear to be running"
```

IntelliJ's executable is `Contents/MacOS/idea`, so the process to look for is named `idea`, not `IntelliJ`. Step 2 runs the same check and warns if it fires — but it does not stop, so a capture taken with the IDE open still lands. When that happens it writes `manifests/ide-was-running-during-capture.txt`, and quitting IntelliJ then rerunning `--intellij-only` clears both the marker and the doubt.

You can cross-check the active config path inside IntelliJ under `Help → Diagnostic Tools → Special Files and Folders`, then compare it with the capture's `manifests/intellij-config-dirs.tsv`.

> [!note]
> That same screen reports a **PROJECT BasePath** for whatever project is focused. It is expected that it does not match what the backup scans — the capture uses the broader projects root on purpose, so all projects are covered.

Two files decide what the capture treats as a secret and what it drops as noise. Settle them here, before anything writes:

| File | Decides |
|---|---|
| `intellij-secret-review-template.txt` | Which patterns are **staged** into `secrets-encrypted/intellij/` for the Phase 3C DMG. Nothing is staged unless you check it. |
| `intellij-plaintext-exclude-list.txt` | Which patterns are **dropped** from the clear-text copy as noise — `httpRequests/`, `shelf/`, `.DS_Store`. Never put secrets here; this only omits, it does not protect. |

Both live in your workspace, not the artifact root, so your decisions outlive any single drive. Check whether you already have them:

```bash
ls -la "$REIMAGE_WORKSPACE_ROOT/intellij-review/"
```

- [[#No Durable Copy Yet|No Durable Copy Yet]] — the listing is empty or the directory is missing.
- [[#A Durable Copy Already Exists|A Durable Copy Already Exists]] — both files are listed.

#### No Durable Copy Yet

Seed it. This needs no artifact root and no mounted drive, and it never overwrites a file that already exists:

```bash
./bin/backup-apps.sh --init-intellij-review
```

Both files are written with **every pattern unchecked**. Open the review template and check what you want staged:

```bash
open -e "$REIMAGE_WORKSPACE_ROOT/intellij-review/intellij-secret-review-template.txt"
```

Change `[ ]` to `[x]` for each pattern whose matching files belong in the encrypted secrets DMG. `http-client.private.env.json` is the usual one.

> [!warning] Pitfall
> Leaving everything unchecked is not the safe default it looks like. Credential-shaped files are excluded from the plaintext copy on **every** run, and only checked patterns are staged into `secrets-encrypted/intellij/`. A pattern you leave unchecked is therefore backed up **nowhere at all** — unchecked means discarded, not "kept in the clear". Skip this and the capture is a two-pass job: review, then run again.

[[#Step 2 — Run the IntelliJ Backup|⮕ Continue to Step 2 — Run the IntelliJ Backup]]

#### A Durable Copy Already Exists

It carries decisions from an earlier run or an earlier reimage — not defaults. The capture will obey it exactly, so read it first:

```bash
grep -c '^\[x\]' "$REIMAGE_WORKSPACE_ROOT/intellij-review/intellij-secret-review-template.txt"
```

A count of `0` means nothing is checked. That is not a neutral outcome: credential-shaped files are excluded from the plaintext copy on every run, so patterns you leave unchecked are backed up nowhere at all. Check the ones you need before continuing.

> [!note]
> Each run copies both files into `app-settings-backup/intellij/secret-review/` in the artifact root, alongside a README pointing back here. That copy is evidence of what the capture obeyed — editing it changes nothing, because the next run rereads the workspace originals.

[[#Step 2 — Run the IntelliJ Backup|⮕ Continue to Step 2 — Run the IntelliJ Backup]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Run the IntelliJ Backup

Two things decide what this run produces, and both are settled before the command.

**IntelliJ must be quit.** The Step 1 check is the same one the script runs. If the script finds it running it warns, writes `manifests/ide-was-running-during-capture.txt`, and carries on — so an open IDE does not stop you, it just makes the result untrustworthy. Quit it now rather than rerunning later.

**Which projects get scanned.** The entrypoint defaults the projects root to `LOCAL_WORK_REPO_ROOT` and the helper auto-detects the active IntelliJ config directory, so neither is passed below.

- [[#Work Repositories Only|Work Repositories Only]] — every IntelliJ project lives under `LOCAL_WORK_REPO_ROOT`.
- [[#Projects Outside the Work Root|Projects Outside the Work Root]] — you also keep personal or other projects elsewhere.

#### Work Repositories Only

Nothing to do — the default is correct.

[[#Run It|⮕ Continue to Run It]]

#### Projects Outside the Work Root

Add `--intellij-projects-root PATH` to the command in the next section, pointing at a common parent that contains every tree you want scanned:

```text
--intellij-projects-root ~/Development
```

The flag takes a **single** path, and a rerun replaces `project-metadata/` rather than adding to it — so running it once per root does not accumulate. Raise `--intellij-projects-max-depth` if the projects sit deeper than 6 levels under that parent.

> [!warning] Pitfall
> A common parent widens the scan. Confirm afterwards in `manifests/projects.tsv` that only the projects you expected were picked up — a parent like `$HOME` would sweep far more than intended.

[[#Run It|⮕ Continue to Run It]]

#### Run It

```bash
./bin/backup-apps.sh --intellij-only --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
```

This refreshes the generated IntelliJ content in place under `app-settings-backup/intellij/` — preserving `manual-settings-export/` and `restore-notes/` — and stages the secrets matching your reviewed patterns into `secrets-encrypted/intellij/` for the Phase 3C packaging.

Optional passthrough flags, when they apply:

```text
--intellij-all-config-dirs        back up every IntelliJIdea*/IdeaIC* config dir, not just the active one
--intellij-projects-root PATH     scan a different projects root (default: LOCAL_WORK_REPO_ROOT)
--intellij-projects-max-depth N   change the .idea scan depth (default 6)
--intellij-skip-project-scan      skip the project-level .idea scan
--intellij-include-shelf          include .idea/shelf folders (skipped by default)
--intellij-include-system-cache   copy the IntelliJ system/cache dir (large; off by default)
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Export the Settings ZIP

This is the manual, app-controlled restore path. Open IntelliJ just for this export, then quit it again before any rerun.

In IntelliJ: `File → Manage IDE Settings → Export Settings`. Save under:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manual-settings-export/IntelliJ-settings-YYYYMMDD-HHMMSS.zip
```

Include at least code style schemes, color schemes/themes, keymaps, inspection profiles, live and file templates, file types, tools/external tools, path variables, and global data sources if shown.

> [!note]
> The ZIP is usually easier to import after reimage than restoring individual config files, which is why it is worth capturing even though the scripted backup already copied most of this state.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

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

[[#Step 2 — Run the IntelliJ Backup|⮕ Continue to Step 2 — Run the IntelliJ Backup]]

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

Secret handling is driven by two files under `$REIMAGE_WORKSPACE_ROOT/intellij-review/`: `intellij-secret-review-template.txt` (which patterns to stage) and `intellij-plaintext-exclude-list.txt` (noise to drop from the clear-text copy). The review template is seeded with these patterns, every one unchecked — change `[ ]` to `[x]` on the ones whose files you want staged:

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
  --projects-root "$LOCAL_WORK_REPO_ROOT"
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
