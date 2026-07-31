---
title: Backup Apps
back_link: "reimaging-guide#Phase 2D — Backup Apps"
runbook_version: 0.2.0
verb_first: true
primary_scripts:
  - bin/backup-apps.sh
related_scripts:
  - .internal/apps/backup-docker-settings.sh
  - .internal/apps/backup-intellij-scratches-consoles.sh
  - .internal/apps/backup-app-config.sh
  - .internal/apps/app-selection.sh
  - bin/capture-size-audit.sh
artifact_paths:
  - $REIMAGE_ARTIFACT_ROOT/app-settings-backup/
  - $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/
author: Orah Kittrell
last_updated: 2026-07-30
---
[[reimaging-guide#Phase 2D — Backup Apps|← Back to Mac Reimaging Guide]]

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
        - [[#Fiddler Everywhere|Fiddler Everywhere]]
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
        - [[#TNAS PC|TNAS PC]]
        - [[#iMovie|iMovie]]
        - [[#Note-Only Apps|Note-Only Apps]]
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
app-controlled backups for BBEdit, Chrome, Claude, Docker, draw.io, Fiddler Everywhere, iMovie, IntelliJ IDEA, Mos, Obsidian, Postman, Raycast, TNAS PC, Terminal, VS Code, Wireshark, and Zoom
the app-backup selection checklist that decides which detected apps are backed up
non-secret app backup artifacts under app-settings-backup/
secret-bearing app export staging under secrets-encrypted/
drop-folders and manual TODOs for selected unsupported apps under app-settings-backup/manual-unsupported/
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
| BBEdit | Script — app config (scripts, text filters, clippings, color schemes) and preferences | Common |
| Claude | Script — MCP config (`claude_desktop_config.json`) staged as secret; account restored by sign-in | Common |
| draw.io | Script — app config and custom libraries; diagrams themselves restored as files (Phase 2B / Git) | Common |
| Zoom | Script — local settings plist; account and most settings restored by sign-in | Common |
| Chrome | Manual — bookmarks export; optional password CSV | Common |
| Postman | Manual — collections, environments, optional vault export | Common |
| Fiddler Everywhere | Manual — session / AutoResponder export; captures are secret-bearing | Common |
| Terminal | Manual — custom profile export (no script folder) | Common |
| Mos | Script — preferences plist (scroll settings, per-app exceptions) | Optional |
| Wireshark | Script — profiles, capture/display filters, coloring rules | Optional |
| Raycast | Manual — Quick Links and settings/data export | Optional |
| Obsidian | Manual — restore-source decision; optional vault copy | Optional |
| TNAS PC | Manual — reconnect / re-auth; saved credentials secret-bearing | Optional |
| iMovie | Manual — confirm libraries (user files) are backed up via Phase 2B | Optional |
| 4K Live Wallpaper | Note only — no meaningful local state; reconfigure after reimage | Optional |
| NexiGo Webcam Settings | Note only — no meaningful local state; reconfigure after reimage | Optional |

Optional-group apps with manual steps (Raycast, Obsidian, TNAS PC, iMovie) keep those steps in [[#Optional App Exports|Supplemental Reference]], indexed from [[#Optional Apps|Optional Apps]] at the end of Sequential Steps, so the main flow stays focused on what most Macs have. Scripted optional apps (Mos, Wireshark) are captured automatically in Step 4 and need no manual steps; the note-only apps need nothing at all.

> [!note]
> The script only acts on apps it detects **and** that you check in the selection checklist (see [[#Step 3 — Determine Which Apps to Back Up|Step 3]]). For an app you do not have, it creates no folder and the manifest marks it "Not detected on this Mac" — so a clean run on a Mac without Docker is correct, not a failure.

> [!note]
> Two Zoom entries were reconciled into one. "Join for Zoom Meetings" is a third-party App Store launcher that only opens meeting links and holds no state to back up; only the full **zoom.us** client is covered (detected in both `/Applications` and `~/Applications`). Recordings under `~/Documents/Zoom` belong to Phase 2B.

### Apps Not Covered Here

It is not possible to maintain an exhaustive backup strategy for every app. If you rely on an app that is not in the table above, backing it up is your responsibility — export or copy its state to a location you control before the erase. If that app has state worth a repeatable strategy, consider contributing support back to this toolkit so a future reimage covers it automatically.

### Run Modes

`backup-apps.sh` has two modes. Both detect whether each app is present before touching anything.

| Mode | Command | What it does |
|---|---|---|
| Candidate review | `./bin/backup-apps.sh --candidate-review` | Scan-only. Detects installed apps, folds in the managed-inventory bundle, writes a review that partitions managed apps out of the candidate list, and generates/refreshes the [[#Step 3 — Determine Which Apps to Back Up\|app-backup selection checklist]]. Creates no app folders, runs no captures, writes no `MANIFEST.md`. |
| Real backup | `./bin/backup-apps.sh` | Reads the selection checklist and backs up only the apps you checked: runs the Docker/IntelliJ/VS Code and registry-driven captures for selected supported apps, creates drop-folders for selected unsupported apps, and writes `MANIFEST.md`. Requires the checklist (errors if missing). |
| Real backup, no checklist | `./bin/backup-apps.sh --all-detected` | Same as above but bypasses the checklist and backs up every detected supported app. |

### Terminology

| Term | Meaning |
|---|---|
| Non-secret export | App artifact safe to keep in plaintext under `app-settings-backup/` after review. |
| Secret-bearing export | Artifact that may carry tokens, passwords, keys, cookies, or unreviewed values; staged under `secrets-encrypted/`. |
| Candidate review | The scan-only mode; detects installed apps, consults the managed inventory, and reports intent without creating real backup artifacts. |
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
$FRACTOGENESIS_HOME/.internal/apps/backup-app-config.sh                   # helper — registry-driven config capture (Claude, draw.io, Zoom, Mos, Wireshark)
$FRACTOGENESIS_HOME/.internal/apps/app-selection.sh                       # helper — generates and reads the app-backup selection checklist
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
│   ├── app-backup-selection.md    # the Step 3 checklist Step 4 reads
│   ├── bbedit/
│   ├── candidate-review/
│   ├── chrome/
│   ├── claude/
│   ├── docker/
│   ├── drawio/
│   ├── fiddler-everywhere/
│   ├── imovie/
│   ├── intellij/                  # full subtree drawn in backup-intellij.md
│   ├── MANIFEST.md
│   ├── manual-unsupported/        # drop-folders for selected unsupported apps
│   │   └── <app>/
│   ├── mos/
│   ├── obsidian/
│   │   ├── global-settings/
│   │   └── vault-copy/
│   ├── postman/
│   │   ├── collections/
│   │   ├── environments-redacted/
│   │   └── inventory/
│   ├── raycast/
│   ├── terminal/
│   ├── tnas-pc/
│   ├── vscode/
│   │   └── user/
│   ├── wireshark/
│   └── zoom/
├── ...
├── secrets-encrypted/
│   ├── ...
│   ├── chrome/
│   ├── claude/
│   ├── docker/
│   ├── fiddler-everywhere/
│   ├── postman/
│   │   ├── environments/
│   │   └── vault-if-export-allowed/
│   ├── raycast/
│   │   └── quicklinks-if-sensitive/
│   ├── tnas-pc/
│   └── ...
└── ...
```

Step 3's candidate review folds in the managed-inventory artifacts produced by the prior managed-inventory phase under `managed-inventory/`; that layout and the complete `$REIMAGE_ARTIFACT_ROOT` map are drawn once elsewhere:

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
- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- The managed-inventory phase (`capture-managed-inventory.md`) has already run for this pre-image pass, so its artifacts are available to consult in Step 3.
- Docker Desktop is running **if** you want current image and container inventories captured; settings files are captured either way.

> [!note]
> The commands below omit `--artifact-root`: `backup-apps.sh` resolves the artifact root automatically from `reimage.env` (via shared config), so it is implicit. Pass `--artifact-root PATH` only when you want to override that value for a single run.

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

Step 3 helps you make this call with actual detection of what is installed and what management will restore. Managed apps are the common trap: management may bring the app back, but not necessarily its user-specific state. You record the decision itself in the **app-backup selection checklist** that Step 3 generates — Step 4 backs up exactly the apps you check there, and nothing else.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. Prepare, check capacity, decide your app set, run the automated capture, complete the manual exports, then verify. The manual exports are not cleanup after the script — for the manual-class apps they are the actual backup.

### Step 1 — Prepare and Validate

Confirm the script runs and the environment resolves before writing anything. `backup-apps.sh` self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand.

List what this toolkit can back up, and confirm the script runs:

```bash
./bin/backup-apps.sh --supported-apps
```

> [!note]
> `--supported-apps` is info only — it lists coverage and exits without writing anything or computing sizes. The same coverage is in the table under [[#What Gets Backed Up, and How|What Gets Backed Up, and How]].

Confirm the artifact root that will be used (scan-only, creates nothing):

```bash
./bin/backup-apps.sh --candidate-review 2>&1 | head -5
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

Decide your app set with real detection instead of memory. `--candidate-review` answers both questions in one pass: it scans what is *installed* and folds in the managed-inventory bundle from the prior phase to see what *management will restore*, then partitions the two so managed apps are moved out of your main candidate list automatically. Apply the [[#Confirm Your Intent|Confirm Your Intent]] criteria to what remains.

Scan installed apps, consult the managed inventory, and see what a real run would create — without touching anything:

```bash
./bin/backup-apps.sh --candidate-review --open
```

The bundle lands under `app-settings-backup/candidate-review/`. Read `app-backup-candidates.md`, which now splits the covered apps into two tables:

- **Known Phase 2D candidates** — installed apps with no managed-inventory match. These are the ones to decide on.
- **Managed — likely restored by IT** — apps with a **strong** managed signal in the managed-inventory section 03 verdict (a configuration profile, a managed preference, or the corporate-tooling filter), shown in a **Managed evidence** column. Management will almost certainly reinstall these, so they are out of the main list — but still skim them for local-only user state a reinstall will not bring back. Apps whose only signal is a package receipt stay in **Known** on purpose, since installed-from-a-package is not proof of management.

A **related-app review** table (for apps that belong elsewhere, such as Music) and the raw files under `raw/` round out the bundle. Two of those raw files come from this fold-in: `raw/managed-apps-detected.txt` (the managed and likely-managed apps read from section 03) and `raw/managed-inventory-source.txt` (which bundle was consulted).

Two TSVs sit alongside the Markdown. `known-app-candidates.tsv` is the **full** candidate inventory — every installed app under `/Applications` and `~/Applications`, whether or not the toolkit supports it, each with its managed verdict and a `toolkit_supported` column. `toolkit-supported-candidates.tsv` is the subset this toolkit can back up (the apps in the curated tables). Sort `known-app-candidates.tsv` by `toolkit_supported` to find installed apps you may need to back up by hand — the curated tables above only cover the supported ones.

By default candidate review consults the newest `pre-image-*` bundle under `managed-inventory/`. Point it at a specific one with `--managed-inventory DIR`:

```bash
./bin/backup-apps.sh --candidate-review \
  --managed-inventory "$REIMAGE_ARTIFACT_ROOT/managed-inventory/pre-image-YYYYMMDD-HHMMSS"
```

> [!note]
> Candidate review reads the managed verdict from the bundle's `03-installed-app-bundles.txt` — the single authoritative per-app call written by the managed-inventory phase — and never re-derives its own, so the two never disagree. It only reads; it never runs the capture. If no bundle exists yet, the run still succeeds but skips the partition (every detected app stays a Known candidate) and says so in `raw/managed-inventory-source.txt`; run `capture-managed-inventory.md` first for the managed split.

> [!warning] Pitfall
> Only a *strong* signal — a configuration profile, a managed preference, or the corporate-tooling filter — moves an app to the Managed table; a lone package receipt is treated as weak and left in the candidate list, because installed-from-a-package is not "managed". And a managed app that reinstalls automatically may still hold local-only user state management will not restore, so judge each managed app rather than assuming it is fully covered.

#### Select the apps to back up

Candidate review also generates your **app-backup selection checklist** — the file Step 4 reads to decide what to back up:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/app-backup-selection.md
```

It has four selectable sections, each listing only apps detected on *this* Mac. The three supported sections are split by backup mechanism, derived from each app's registry coverage (not a hand-maintained list), so they stay accurate as apps change:

- **Automatic backup (supported)** — the script fully backs these up; no manual step. They start **checked**; uncheck any you do not want.
- **Both automatic and manual backup (supported)** — the script captures part of these **and** each also has a manual export step (an app lands here only when it is both script-backed *and* has a manual section under [[#Step 5 — Complete Manual Exports|Step 5]] or its companion runbook — currently IntelliJ IDEA). They start **checked** for the automatic capture; the manual half is still yours to do.
- **Manual backup (supported)** — the toolkit supports these but the backup is entirely manual (Chrome, Postman, Fiddler Everywhere, Terminal, Raycast, Obsidian, TNAS PC, iMovie). Step 4 makes a ready folder for the ones you keep; you perform the export from the app's UI. They start **checked**.
- **Unsupported apps on this Mac (manual backup)** — installed apps the toolkit does not cover, **excluding company-managed apps** (a strong managed verdict means IT restores the app, so it is not a manual-backup candidate). Check the ones you will back up by hand; Step 4 creates a drop-folder under `app-settings-backup/manual-unsupported/<app>/` and lists them as manual TODOs in the manifest. The excluded managed apps are recorded in the candidate review's `raw/unsupported-managed-excluded.txt`.

> [!note]
> Note-only apps (like 4K Live Wallpaper and NexiGo Webcam Settings) have no automatic backup and no manual export step, so they are left off the checklist entirely — reconfigure them from their app UI after reimage. They remain documented in the coverage table.

Open the checklist, put an `x` between the brackets for each app to act on, and save:

```text
- [x] Wireshark      # backed up
- [ ] Zoom           # skipped
```

> [!note]
> The managed exclusion reads the managed verdict from the managed-inventory bundle. If managed apps (Company Portal, the Microsoft suite, security agents, and so on) still appear in the unsupported list, candidate review ran without a managed inventory — run [[capture-managed-inventory|Capture Managed Inventory]] first, then rerun candidate review to regenerate the checklist with those apps dropped. Apps flagged only by a weak, receipt-only signal are treated as not-managed and remain in the list on purpose.

Re-running candidate review is safe — it **preserves the choices you have made** (checked or unchecked) and adds newly-installed apps at their section default (supported checked, unsupported unchecked), so you can iterate as you install or remove apps.

> [!warning] Pitfall
> Step 4 backs up **only what is checked here**. A freshly generated checklist starts with **all supported apps checked** (across the automatic, both, and manual sections) and all unsupported apps unchecked — so review it before Step 4: uncheck any supported app you do not want, and check any unsupported app you will back up by hand. Remember the both- and manual-section apps still need their manual export done. The candidate tables above help you decide.

> [!note]
> The full Step 4 backup **requires** this checklist and stops with instructions if it is missing. To deliberately skip the checklist and back up everything detected instead, run Step 4 with `--all-detected`.

### Step 4 — Run the Automated Backup

Run the real backup. It reads your selection checklist from [[#Select the apps to back up|Step 3]] and acts only on the apps you checked — running the scripted captures for selected supported apps, creating drop-folders for selected unsupported apps, and skipping everything else. Apps you do not have are silently skipped even when checked.

```bash
./bin/backup-apps.sh --open
```

> [!note]
> If you have not built the checklist yet, this run stops and points you to Step 3. To back up every detected app without a checklist, add `--all-detected`.

This captures the script-class apps and prepares folders for the manual-class ones:

- **Docker** — `settings-store.json`, `daemon.json`, `contexts/`, and image/container/compose inventories to `app-settings-backup/docker/`; `config.json` staged to `secrets-encrypted/docker/`. `Docker.raw`, image layers, and volumes are intentionally not backed up.
- **VS Code** — extension list, `settings.json`, `keybindings.json`, `snippets/`, and `profiles/` to `app-settings-backup/vscode/`. Caches, logs, and workspace history are intentionally excluded.
- **IntelliJ IDEA** — Scratches, Consoles, and config to `app-settings-backup/intellij/`. The settings ZIP is manual — see [[#IntelliJ Settings Export|Step 5]].
- **BBEdit, Claude, draw.io, Zoom, Mos, Wireshark** — registry-driven config capture to `app-settings-backup/<app>/` for each selected app detected; Claude's MCP config (`claude_desktop_config.json`) is staged to `secrets-encrypted/claude/`.
- **Chrome, Postman, Fiddler Everywhere, Raycast, Obsidian, TNAS PC, iMovie** — an empty, ready folder only (when selected), for the manual exports below.
- **selected unsupported apps** — a drop-folder with a README under `app-settings-backup/manual-unsupported/<app>/`, for you to fill by hand.
- the stable summary at `app-settings-backup/MANIFEST.md`, with the selection used and the manual TODOs that remain.

Rerun a single script-class portion through the same entrypoint when needed — for example after starting Docker Desktop, or to refresh one app. These `--*-only` reruns bypass the checklist and act on their portion for every detected app:

```bash
./bin/backup-apps.sh --docker-only --open
./bin/backup-apps.sh --intellij-only --open
./bin/backup-apps.sh --vscode-only --open
./bin/backup-apps.sh --apps-only --open   # Claude, draw.io, Zoom, Mos, Wireshark
```

> [!warning] Pitfall
> A successful run here is **not** a completed phase. It backs up only the selected script-class apps; any selected Chrome, Postman, Fiddler Everywhere, Terminal, the IntelliJ settings ZIP, and (if you use them) Raycast, Obsidian, TNAS PC, and iMovie still need their manual exports, and your selected unsupported apps still need to be filled into their drop-folders.

> [!note]
> BBEdit's support folder can live in different places: the direct-download build uses `~/Library/Application Support/BBEdit/`, the Mac App Store build is sandboxed under `~/Library/Containers/com.barebones.bbedit/`, and recent versions can sync it to iCloud Drive. The capture copies whichever local paths exist; if your support folder is in iCloud, it already syncs and restores through your Apple ID.

> [!bug] Troubleshooting
> If Docker Desktop is not running, `settings-store.json`, `daemon.json`, and `contexts/` are still captured, but `image-inventory.txt` and `container-inventory.txt` are skipped. Start Docker Desktop, wait for the daemon, then rerun `--docker-only`.

### Step 5 — Complete Manual Exports

These exports must be triggered from each app's own UI — the script cannot perform them or prove they are complete. Do the ones you checked in Step 3; skip the rest. For the optional apps (Raycast, Obsidian, TNAS PC, iMovie), the full steps are in [[#Optional App Exports|Supplemental Reference]], indexed at [[#Optional Apps|Optional Apps]].

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

Use `app-settings-backup/postman/` only for non-secret collection exports, redacted environment examples, variable inventories, and restore notes. Use `secrets-encrypted/postman/` for anything that may contain tokens, passwords, API keys, client secrets, cookies, bearer tokens, or unreviewed environment exports.

If Step 4 detected Postman, its folders already exist; otherwise create them:

```bash
mkdir -p \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/collections" \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/environments-redacted" \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/inventory" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/environments" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/vault-if-export-allowed"
```

Create the starter READMEs so each area documents its own rules. These use an unquoted heredoc (`<<EOF`) so `$REIMAGE_ARTIFACT_ROOT` expands to the resolved path in the written file:

```bash
cat > "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/README.md" <<EOF
# Postman Backup Notes

Use this folder for non-secret Postman collection exports, redacted environment
examples, inventories, and restore notes.

Do not place tokens, passwords, client secrets, API keys, cookies, bearer
tokens, or unreviewed environment exports here.

If Postman Vault export is blocked, document variable names and restore sources
under:

  $REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/inventory/

Secret-bearing Postman files belong under:

  $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/
EOF

cat > "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/README.md" <<EOF
# Postman Secret Material

Stage secret-bearing Postman exports here, for example:

- environment exports containing tokens, passwords, API keys, client secrets,
  cookies, or bearer tokens
- Postman Local Vault export files, only when export is allowed
- unreviewed Postman exports that may contain credentials

Vault export may be unavailable or blocked by policy. If export is blocked, do
not bypass it. Keep only a redacted inventory under app-settings-backup and
restore the values from the approved secret source after reimage.
EOF
```

##### Collections

Export collections from `Postman Desktop > Collections > Export` and save non-secret ones under `app-settings-backup/postman/collections/`. Before trusting a collection as non-secret, scan it for embedded credentials:

```bash
grep -RniE 'token|password|passwd|secret|apikey|api_key|authorization|bearer|cookie|client_secret' \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/collections" \
  || true
```

##### Environments

Export environments from `Postman Desktop > Environments > Export`. Environments often carry URLs, IDs, tokens, usernames, passwords, bearer tokens, API keys, or client secrets — stage them under `secrets-encrypted/postman/environments/` unless you are certain they are non-secret, and keep only redacted copies under `app-settings-backup/postman/environments-redacted/` using placeholders such as:

```text
TODO_RESTORE_FROM_POSTMAN_VAULT
TODO_RESTORE_FROM_LASTPASS
TODO_RESTORE_FROM_1PASSWORD
TODO_RESTORE_FROM_AZURE_KEY_VAULT
TODO_RESTORE_FROM_TEAM_POSTMAN_ENVIRONMENT
TODO_REAUTHENTICATE_AFTER_REIMAGE
```

Do not leave unreviewed environment exports loose in `app-settings-backup/` or cloud-synced folders.

##### Postman Local Vault

Postman Local Vault export may be blocked by app, workspace, account, or corporate policy. Treat vault export as optional.

###### If vault export is allowed

Use `Postman Desktop > Vault > Export` and save under `secrets-encrypted/postman/vault-if-export-allowed/`:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/vault-if-export-allowed/postman-vault-secrets-YYYYMMDD-HHMMSS.encrypted.json
```

If Postman requests pull values from an external vault or password manager, do not duplicate those secret values into the backup — document the restore path in `app-settings-backup/postman/README.md` instead. Useful non-secret notes:

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

###### If vault export is blocked

Do not bypass the restriction. Record a redacted inventory so each required value has a known restore source — never put secret values in the file. This uses a quoted heredoc (`<<'EOF'`) so the template is written verbatim:

```bash
VAULT_INVENTORY="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/inventory/postman-vault-inventory-$(date +%Y%m%d-%H%M%S).md"
mkdir -p "$(dirname "$VAULT_INVENTORY")"

cat > "$VAULT_INVENTORY" <<'EOF'
# Postman Vault Inventory — Export Blocked

Vault export status: blocked / unavailable
Captured by: manual review

## Restore plan

Do not store secret values in this file. Restore values after reimage from the
approved source.

| Workspace | Collection / Request | Environment | Variable / Vault Key Name | Secret Value Stored Here? | Restore Source | Restore Action | Notes |
|---|---|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | No | TODO_LASTPASS_OR_APPROVED_SOURCE | Recreate after reimage | TODO |

## Sign-off

- [ ] Confirmed vault export was blocked or unavailable.
- [ ] Confirmed no vault secret values were copied into the inventory note.
- [ ] Confirmed restore source is known for each required value.
EOF
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

##### Artifact-local checks

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman" -maxdepth 3 -type f | sort 2>/dev/null || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman" -maxdepth 3 -type f | sort 2>/dev/null || true
```

> [!warning] Pitfall
> If Vault export is blocked, do not work around the control. Record a redacted inventory under `app-settings-backup/postman/inventory/` (variable names, owning collection/environment, and restore source — no values) and restore from the approved source after reimage.

#### Fiddler Everywhere

Fiddler Everywhere is manual because the app UI owns session and rule export, and its settings sync to your Progress (Telerik) account rather than to predictable local files. Treat its data as distinct categories:

| Category | Destination | Rule |
|---|---|---|
| Reviewed AutoResponder rules / composed requests | `app-settings-backup/fiddler-everywhere/` | Safe only after review — no tokens, cookies, or credentials in URLs, headers, or bodies. |
| Saved sessions (captured traffic) | `secrets-encrypted/fiddler-everywhere/` | Captured traffic routinely carries auth headers, cookies, and tokens — treat as secret-bearing. |
| Account-synced settings | (no local artifact) | Return on sign-in; record only that sync is enabled. |

If Step 4 detected and you selected Fiddler Everywhere its folder already exists; otherwise create both:

```bash
mkdir -p \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/fiddler-everywhere" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/fiddler-everywhere"
```

Export your saved sessions from the Fiddler Everywhere UI (session list → export, typically a `.saz` archive) and save them **only** under secret-bearing staging:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/fiddler-everywhere/fiddler-sessions-YYYYMMDD-HHMMSS.saz
```

Export any AutoResponder rules or composed requests you want to keep. Before trusting a rule set as non-secret, scan it for embedded credentials, then save reviewed copies under `app-settings-backup/fiddler-everywhere/`:

```bash
grep -RniE 'token|password|passwd|secret|apikey|api_key|authorization|bearer|cookie|client_secret' \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/fiddler-everywhere" \
  || true
```

After reimage, sign back into your Progress account to restore synced settings.

> [!warning] Pitfall
> Fiddler session captures almost always contain live auth material. Default any exported traffic to `secrets-encrypted/fiddler-everywhere/`; keep only reviewed, credential-free rule sets under `app-settings-backup/`.

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

These apps are manual and belong to the optional group, so their full steps live under Supplemental Reference to keep the main flow lean. Complete any you checked in Step 3 as part of [[#Step 5 — Complete Manual Exports|Step 5]] — this index just points to each one. The scripted optional apps (Mos, Wireshark) are captured automatically in Step 4 and are not listed here.

| App | Use when | Steps |
|---|---|---|
| Raycast | Quick Links or settings/data export matter | [[#Raycast\|Optional App Exports → Raycast]] |
| Obsidian | Vault content, vault-local config, or a restore-source choice matters | [[#Obsidian\|Optional App Exports → Obsidian]] |
| TNAS PC | Saved TNAS connections or credentials matter | [[#TNAS PC\|Optional App Exports → TNAS PC]] |
| iMovie | You keep iMovie projects/libraries and must confirm they are backed up | [[#iMovie\|Optional App Exports → iMovie]] |

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

Detection runs only while the script runs, so a newly installed app has no folder yet. Rerun Step 3 first so the app is added to the selection checklist, check it, then rerun the entrypoint so it is detected and its folders are created:

```bash
./bin/backup-apps.sh --candidate-review   # adds the new app to the checklist
# check the new app in app-backup-selection.md, then:
./bin/backup-apps.sh
```

For a single script-class app, use `--docker-only`, `--intellij-only`, or `--apps-only` (these bypass the checklist). For a manual-class app (Chrome, Postman, Fiddler Everywhere, Terminal, Raycast, Obsidian, TNAS PC), create the folders by hand from that app's export section.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Optional App Exports

Raycast, Obsidian, TNAS PC, and iMovie are manual-class apps in the optional group. Their folders are created by [[#Step 4 — Run the Automated Backup|Step 4]] when detected and selected; complete these exports only if you checked them in Step 3.

#### Raycast

Raycast export is manual because the app owns the export flow and the settings export can include sensitive data. Treat Raycast as distinct export types:

| Category | Destination | Rule |
|---|---|---|
| Reviewed non-secret Quick Links JSON | `app-settings-backup/raycast/` | Safe only after reviewing URLs, query strings, identifiers, and internal links. |
| Raycast restore notes and inventory | `app-settings-backup/raycast/` | App-specific notes only. No `.rayconfig` files and no secret values. |
| Sensitive or unreviewed Quick Links JSON | `secrets-encrypted/raycast/quicklinks-if-sensitive/` | Secret-bearing until reviewed. |
| Raycast `.rayconfig` | `secrets-encrypted/raycast/` | Secret-bearing even when password-protected. |

##### Directories and starter notes

If Step 4 detected Raycast, its folders already exist; otherwise create them:

```bash
mkdir -p \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/quicklinks-if-sensitive"
```

Create the starter READMEs so each area documents its own rules. These use an unquoted heredoc (`<<EOF`) so `$REIMAGE_ARTIFACT_ROOT` expands to the resolved path in the written file:

```bash
cat > "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/README.md" <<EOF
# Raycast App Settings Backup Notes

Use this folder for reviewed non-secret Raycast exports and restore notes.

Expected examples:

- raycast-quicklinks-YYYYMMDD-HHMMSS.json
- raycast-export-inventory-YYYYMMDD-HHMMSS.md

Before saving Quick Links here, review whether the exported links include
sensitive internal URLs, tokens, query strings, private identifiers, customer
references, repo links, or company-only information.

If Quick Links are sensitive or unreviewed, save them under:

  $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/quicklinks-if-sensitive/

Do not store the password-protected .rayconfig file here. It belongs under:

  $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/
EOF

cat > "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/README.md" <<EOF
# Raycast Secret Material

Stage secret-bearing Raycast exports here, for example:

- raycast-settings-and-data-YYYYMMDD-HHMMSS.rayconfig
- quicklinks-if-sensitive/raycast-quicklinks-YYYYMMDD-HHMMSS.json

Treat the Raycast .rayconfig export as secret-bearing even when
password-protected.
EOF
```

##### Find the export commands

The simplest way to find the export actions is from Raycast root search:

```text
Open Raycast
Search: Export Quicklinks
Search: Export Settings & Data
```

If they do not appear, enable the built-in commands:

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

Use `Export Quicklinks` for the standalone Quick Links JSON. Use `Export Settings & Data` for the full `.rayconfig` backup.

##### Quick Links

Save the exported JSON under the non-secret folder **only after review**:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/raycast-quicklinks-YYYYMMDD-HHMMSS.json
```

If the Quick Links contain or might contain sensitive data, save them under secret-bearing staging instead:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/quicklinks-if-sensitive/raycast-quicklinks-YYYYMMDD-HHMMSS.json
```

##### Settings and data

The `.rayconfig` from `Export Settings & Data` is password-protected and carries sensitive data, so save it only under secret-bearing staging:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/raycast-settings-and-data-YYYYMMDD-HHMMSS.rayconfig
```

> [!warning] Pitfall
> Do not store the `.rayconfig` export password in this runbook or in any app backup. Keep it in your approved password manager; if you need a reminder, record only a non-secret hint such as `TODO_ENTRY_NAME`.

##### Artifact-local checks

After exporting, confirm the files landed in the correct folders:

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast" -maxdepth 2 -type f | sort 2>/dev/null || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast" -maxdepth 3 -type f | sort 2>/dev/null || true
```

If an export landed in Downloads, move it by sensitivity (swap in the real filename):

```bash
# Password-protected settings/data export — secret-bearing.
mv "$HOME/Downloads/raycast-settings-and-data-YYYYMMDD-HHMMSS.rayconfig" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/"

# Reviewed non-secret Quick Links JSON.
mv "$HOME/Downloads/raycast-quicklinks-YYYYMMDD-HHMMSS.json" \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/"

# Sensitive or unreviewed Quick Links JSON.
mv "$HOME/Downloads/raycast-quicklinks-YYYYMMDD-HHMMSS.json" \
  "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/quicklinks-if-sensitive/"
```

Optionally record a redacted inventory. This uses a quoted heredoc (`<<'EOF'`) so the template is written verbatim:

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
- [ ] Sensitive or unreviewed Quick Links were staged under secrets-encrypted/raycast/.
- [ ] Raycast .rayconfig was staged under secrets-encrypted/raycast/.
EOF
```

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

#### TNAS PC

`backup-apps.sh` does not capture TNAS PC automatically: its connection profiles live in an app-specific location that varies, and any saved NAS credentials are secret-bearing. The decision here is whether you have saved connections worth preserving, or will simply re-add them after reimage.

| What to capture | Destination | Rule |
|---|---|---|
| Redacted list of TNAS connections (host/IP, share names, account — no passwords) | `app-settings-backup/tnas-pc/` | Safe inventory that speeds re-adding connections. |
| Any exported or stored credential file you locate | `secrets-encrypted/tnas-pc/` | Secret-bearing; stage for the Phase 2F encrypted DMG. |

Most people just re-add their TNAS in the app after reimage. If you want a reminder of what to re-add, record a redacted note:

```bash
mkdir -p "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/tnas-pc"
cat > "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/tnas-pc/connections-note.txt" <<'EOF'
TNAS connections to re-add after reimage:
- <name> — host/IP: <...>  shares: <...>  account: <...>  (password from your password manager)
EOF
```

> [!warning] Pitfall
> Do not copy TNAS-stored passwords into `app-settings-backup/`. Restore credentials from your password manager, and stage any credential file only under `secrets-encrypted/tnas-pc/`.

> [!info] Return
> Back to [[#Optional Apps|Optional Apps]].

#### iMovie

iMovie has no app settings worth capturing here — its real content is your **iMovie libraries**, which are user files, not app state. The toolkit deliberately does not script them: a library is often tens of gigabytes and belongs to your Phase 2B local-file backup or an external drive, not the app-settings artifact root. The manual step is to make sure the libraries are actually captured somewhere.

- **Find your libraries.** The default is `~/Movies/iMovie Library.imovielibrary`; you may have more, and some may live on external drives. In iMovie, open the library list (**File → Open Library → Other…**) to see each one's location.
- **Confirm coverage.** Check that each library's location is inside what Phase 2B (`backup-home.md`) actually backs up. `~/Movies` is large and may be excluded, or a library may live on an external volume — if so, copy the `.imovielibrary` package to your backup destination explicitly.
- **Record where they are**, so restore is unambiguous:

```bash
mkdir -p "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/imovie"
cat > "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/imovie/libraries-note.txt" <<'EOF'
iMovie libraries to preserve (restore as files, not app settings):
- <path to Library.imovielibrary>   size: <...>   backed up by: <Phase 2B / external drive / Time Machine>
EOF
```

> [!warning] Pitfall
> Do not copy multi-gigabyte iMovie libraries into the app-settings artifact root. Keep them in your local-file backup (Phase 2B) or on an external drive; record only their locations here.

> [!info] Return
> Back to [[#Optional Apps|Optional Apps]].

#### Note-Only Apps

**4K Live Wallpaper** and **NexiGo Webcam Settings** are registered so they appear in the candidate review and selection checklist, but they have no meaningful local state worth backing up — wallpaper choices and webcam presets are cosmetic and quick to redo. The toolkit captures nothing and stages nothing for them; reconfigure both from their app UI after reimage. If you have another app like this, leave it unchecked in the supported section, or check it in the **unsupported** section to get a drop-folder for a manual copy.

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

If you add any Docker `config.json`, Chrome password CSV, secret-bearing Postman export, Claude MCP config, Fiddler Everywhere session export, TNAS PC credential, or Raycast secret export later, rerun Phase 2F so the DMG includes the complete final secret set before final validation.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link;
  Sequential Steps carries its single link at the end of Step 6.
-->
