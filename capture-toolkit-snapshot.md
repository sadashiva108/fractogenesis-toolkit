[[reimaging-guide#Phase 4A — Capture Toolkit Snapshot|← Back to Mac Reimaging Guide]]

# Capture Toolkit Snapshot

**Last updated:** 2026-08-04

A lightweight capture that preserves the reimage workflow's own documentation and templates alongside a timestamped snapshot bundle, so the state of the runbooks that drove this reimage travels with the backup drive. Run it pre-image (Phase 4A) to record the workflow as it stands before the rebuild, and again post-image (Phase 13A) to record the final workflow state after any runbook or script refinements made during the effort.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Prepare and Validate|Step 1 — Prepare and Validate]]
    - [[#Step 2 — Capture the Toolkit Snapshot|Step 2 — Capture the Toolkit Snapshot]]
    - [[#Step 3 — Verify Outputs|Step 3 — Verify Outputs]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Record what produced the artifacts on this drive. Every other capture in the workflow describes the Mac — its hardware, its installed apps, its performance; this one describes the toolkit that acted on it. It runs after the Phase 2 backups and the Phase 3 secrets pass, so the state it records is the state those phases actually ran against.

**What it captures**

- A timestamped, self-contained bundle under `toolkit-snapshot/` that no later run rewrites.
- `docs/` — the runbooks and templates as they read for this run.
- `config/` — the artifact-config and staged-certs fragments the scripts resolved, plus the `reimage.env` that resolved every path.
- `config/SOURCES.txt` — where each config input came from, and whether it was this Mac's workspace copy or the repository's committed fallback.
- Config-only refresh bundles, for when fragments change partway through a multi-day effort.

**What the rest of the workflow relies on it for**

- Reading the runbooks off the backup drive on a freshly reimaged Mac, through the stable `latest-docs` path, before Git access is restored.
- Answering "which config was in effect when this ran?" after the fact, when a backup step has been rerun days later against edited fragments.
- Proving a run used this Mac's fragments rather than the generic committed examples — a distinction the Phase 6B sign-off can check because `SOURCES.txt` states it in writing.
- Comparing pre-image and post-image toolkit state, since both bundles survive.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| The timestamped `pre-image-toolkit-snapshot-*` and `pre-image-toolkit-config-*` bundles | Broad local-file and home-directory backup — `backup-home.md` |
| The per-bundle `docs/` copy of runbooks and templates | System-state and tooling inventory — `capture-system-inventory.md` |
| The per-bundle `config/` copy and its `SOURCES.txt` | Company-managed app and profile inventory — `capture-managed-inventory.md` |
| The `latest-docs` symlink and the per-series latest pointers | Which copy of a config fragment a script reads — `master-directory-reference.md` |
| | The full `$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/` tree layout — `master-directory-reference.md` |
| | Encrypted packaging of any credential-bearing material — `create-secrets-dmg.md` |

The bundles hold non-secret reference material only: readable Markdown, shell config fragments, and resolved paths — never keys, keystores, or credential files.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Every run writes one **self-contained bundle** — docs and config together, in a dated directory that no later run rewrites. That immutability is the whole design: point-in-time evidence is worthless if a rerun days later silently replaces it, which is exactly what a single shared folder would do.

Two series share the `toolkit-snapshot/` root, and a directory's name always tells you what is inside it. A `-toolkit-snapshot-` bundle carries `docs/` and `config/`. A `-toolkit-config-` bundle, written by `--config-only`, carries `config/` alone — for when you edit fragments partway through a multi-day effort and want the change recorded without re-copying every runbook.

Immutable bundles create one problem, and `latest-docs` solves it. From Phase 8 onward you are reading these runbooks off the backup drive on a rebuilt Mac with no Git access, and hunting for the newest timestamp by hand is a poor thing to ask of someone mid-restore. `latest-docs` is a symlink to the newest full bundle's `docs/` — one stable path, repointed on every full run and left alone by `--config-only`.

Ordering follows the reimage timeline. The pre-image run (Phase 4A) records the toolkit before the machine is wiped, after the Phase 2 backups and Phase 3 secrets pass have already run against that config. The post-image run (Phase 13A) records the final state after the rebuild, capturing refinements made along the way — so the two bundles together show how the toolkit itself evolved across the reimage.

### Terminology

| Term | Meaning |
|---|---|
| Bundle | One timestamped run directory (`<context>-toolkit-snapshot-YYYYMMDD-HHMMSS/`); immutable point-in-time evidence. |
| Documentation copy | The single `docs/` folder holding the latest workflow runbooks and templates; refreshed in place. |
| Context | The `pre-image` / `post-image` label that prefixes the bundle name and marks which side of the reimage it records. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/capture-toolkit-snapshot.sh    # entrypoint
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/    # all toolkit-snapshot artifacts land here
```

The subtree this runbook touches — one self-contained bundle per run, plus the pointers into the newest of each series:

```text
$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/
├── README.md
├── pre-image-toolkit-snapshot-YYYYMMDD-HHMMSS/
│   ├── README.md
│   ├── docs/
│   │   ├── *.md
│   │   └── templates/
│   ├── config/
│   │   ├── artifact-config/*.conf.sh
│   │   ├── staged-certs/*.conf.sh
│   │   ├── reimage.env
│   │   └── SOURCES.txt
│   └── logs/
│       └── latest-aliases.txt
├── pre-image-toolkit-config-YYYYMMDD-HHMMSS/    # --config-only refresh
│   ├── README.md
│   ├── config/
│   └── logs/
├── latest-pre-image-toolkit-snapshot.txt
├── latest-pre-image-toolkit-snapshot -> pre-image-toolkit-snapshot-YYYYMMDD-HHMMSS
├── latest-pre-image-toolkit-config.txt
├── latest-pre-image-toolkit-config -> pre-image-toolkit-config-YYYYMMDD-HHMMSS
└── latest-docs -> pre-image-toolkit-snapshot-YYYYMMDD-HHMMSS/docs
```

`latest-docs` is the one stable path for reading the runbooks off the drive on a freshly reimaged Mac, so no phase has to resolve a timestamp by hand. It always points at the newest *full* bundle's `docs/`; a `--config-only` run leaves it alone.

`config/SOURCES.txt` records where each config input came from and whether it was this Mac's workspace copy or the repository's committed fallback. An origin of `committed-template` means the run used generic example values — treat anything produced alongside it as suspect.

The complete `$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the artifact root where `toolkit-snapshot/` lives. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here, and it is the source of the docs and templates copied into `docs/`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what this run is for. The concepts and the *why* are in [[#How the Workflow Works|How the Workflow Works]]; this is just the checklist.

### Prerequisites

- `REIMAGE_ARTIFACT_ROOT` resolves and its destination volume is mounted (`reimage.env` produced by `prepare-artifact-root.md`).
- You are running commands from `$FRACTOGENESIS_HOME`.
- The repository holds the current workflow runbooks and templates you intend to snapshot — the doc copy reflects `$FRACTOGENESIS_HOME` as it is right now.

### Confirm Your Intent

- Whether this is the **pre-image** run (Phase 4A, before wiping) or the **post-image** run (Phase 13A, after the rebuild) — this sets the bundle's `context` prefix and which side of the reimage it records.
- Whether you are producing a new timestamped bundle, refreshing the documentation copy, or both — the bundle is fresh every run, the doc copy changes only when you rerun the doc-copy step.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order: confirm the environment, capture the bundle, then verify what landed. The capture is a single scripted pass — `bin/capture-toolkit-snapshot.sh` writes the bundle, copies the docs and config, and repoints the aliases without further steps.

### Step 1 — Prepare and Validate

Confirm the artifact root resolves and its volume is mounted before writing anything into it:

```bash
test -d "$REIMAGE_ARTIFACT_ROOT" && echo "artifact root: $REIMAGE_ARTIFACT_ROOT"
```

Syntax-check the entrypoint before the first run:

```bash
bash -n bin/capture-toolkit-snapshot.sh
```

> [!note]
> The entrypoint self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand for the scripted path.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Capture the Toolkit Snapshot

Run the scripted capture. It writes a fresh timestamped bundle carrying both `docs/` and `config/`, and repoints `latest-docs` at it; `--open` reveals the bundle when it finishes:

```bash
./bin/capture-toolkit-snapshot.sh --open
```

For the post-image run (Phase 13A, after the rebuild), set the context so the bundle is labelled distinctly and sits beside the pre-image bundle rather than overwriting it:

```bash
./bin/capture-toolkit-snapshot.sh --context post-image --open
```

Watch the Config fragments section of the output. Each line reports the origin of what it copied, and a run that fell back to the committed templates ends with a red summary line rather than passing quietly.

If you edit artifact-config or staged-certs fragments partway through a multi-day run — or rerun a backup step after changing them — capture the new config without re-copying the docs:

```bash
./bin/capture-toolkit-snapshot.sh --config-only
```

That writes a `pre-image-toolkit-config-YYYYMMDD-HHMMSS/` bundle holding `config/` alone, leaving the docs snapshot and `latest-docs` untouched. Earlier bundles are never rewritten, so the sequence of config bundles is the record of how the fragments changed across the effort.

> [!note]
> Run the full capture once per phase pass and a `--config-only` refresh after each fragment edit. Two series under one root keep a bundle's name honest about its contents: `-toolkit-snapshot-` always has docs, `-toolkit-config-` never does.

> [!warning] Pitfall
> Do not copy `*.sh` or `*.py` helper scripts into the backup drive. The script source of truth is the Git repository; `docs/` carries the readable runbooks and templates only, not the executables.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Verify Outputs

Confirm the newest bundle landed and its README is present. Adjust the `pre-image` prefix to `post-image` when verifying the Phase 13A run:

```bash
TOOLKIT_SNAPSHOT_ROOT="$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot"
LATEST="$(find "$TOOLKIT_SNAPSHOT_ROOT" -maxdepth 1 -type d -name 'pre-image-toolkit-snapshot-*' 2>/dev/null | sort | tail -1)"
printf 'Latest toolkit snapshot: %s\n' "$LATEST"
```

Confirm the bundle README and the refreshed documentation copy both exist:

```bash
test -f "$LATEST/README.md" && echo "PASS: bundle README captured"
test -d "$LATEST/docs" && echo "PASS: docs captured in the bundle"
test -d "$TOOLKIT_SNAPSHOT_ROOT/latest-docs" && echo "PASS: latest-docs resolves"
```

Confirm the config capture recorded this Mac's fragments rather than the committed examples. This is the line the Phase 6B sign-off reads:

```bash
grep -A2 '^artifact-config' "$LATEST/config/SOURCES.txt"
grep -A2 '^staged-certs' "$LATEST/config/SOURCES.txt"
```

> [!warning] Pitfall
> An origin of `committed-template` means the run read the repository's generic example fragments, not yours. Any artifact produced by that run was driven by placeholder targets. Re-run the matching init step, then rerun this capture with `--config-only`.

> [!bug] Troubleshooting
> A missing bundle README means the scripted capture has not run yet. An empty `docs/` on a bundle whose name contains `-toolkit-config-` is expected — a `--config-only` run captures no docs by design; check the newest `-toolkit-snapshot-` bundle instead, or follow `latest-docs`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections (How the Workflow Works subsections beyond Terminology,
  Decisions, Troubleshooting, Supplemental Reference) were also removed from the
  Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link.
-->
