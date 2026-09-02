[[reimaging-guide#Phase 4A — Capture Toolkit Snapshot|← Back to Mac Reimaging Guide]]

# Capture Toolkit Snapshot

**Last updated:** 2026-09-02

A lightweight capture that preserves the reimage workflow's own documentation and templates alongside a timestamped snapshot bundle, so the state of the runbooks that drove this reimage travels with the backup drive. Run it pre-image (Phase 4A) to record the workflow as it stands before the rebuild, and again post-image (Phase 13A) to record the final workflow state after any runbook or script refinements made during the effort.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Bundle Layout|Bundle Layout]]
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
> Two kinds, used sparingly. `[!warning]` **Pitfall** — skipping it costs something you do not get back: state overwritten, a security boundary crossed, or a wrong result that stays quiet until a later phase. `[!bug]` **Troubleshooting** — what to do when a step misbehaves. Everything else is prose, in the paragraph that needed it. A box around an explanation only makes the explanation easier to skip.

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

- Reading the runbooks off the backup drive on a freshly reimaged Mac, through the `official/` pointer, before Git access is restored.
- Answering "which config was in effect when this ran?" after the fact, when a backup step has been rerun days later against edited fragments.
- Proving a run used this Mac's fragments rather than the generic committed examples — a distinction the Phase 6B sign-off can check because `SOURCES.txt` states it in writing.
- Comparing pre-image and post-image toolkit state, since both bundles survive.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| The timestamped `pre-image-toolkit-snapshot-*` and `pre-image-toolkit-config-*` bundles | Broad local-file and home-directory backup — `backup-home.md` |
| The per-bundle `docs/` copy of runbooks and templates | System-state and tooling inventory — `capture-system-inventory.md` |
| The per-bundle `config/` copy and its `SOURCES.txt` | Company-managed app and profile inventory — `capture-managed-inventory.md` |
| The two run lineages and the `official/` pointer into each | Which copy of a config fragment a script reads — `master-directory-reference.md` |
| | The full `$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/` tree layout — `master-directory-reference.md` |
| | Encrypted packaging of any credential-bearing material — `create-secrets-dmg.md` |

The bundles hold non-secret reference material only: readable Markdown, shell config fragments, and resolved paths — never keys, keystores, or credential files.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Every run writes one **self-contained bundle** — docs and config together, in a dated directory that no later run rewrites. That immutability is the whole design: point-in-time evidence is worthless if a rerun days later silently replaces it, which is exactly what a single shared folder would do.

Two series share the `toolkit-snapshot/` root, and a directory's name always tells you what is inside it. A `-toolkit-snapshot-` bundle carries `docs/` and `config/`. A `-toolkit-config-` bundle, written by `--config-only`, carries `config/` alone — for when you edit fragments partway through a multi-day effort and want the change recorded without re-copying every runbook.

Immutable bundles create one problem, and the `official/` pointer solves it. From Phase 8 onward you are reading these runbooks off the backup drive on a rebuilt Mac with no Git access, and hunting for the newest timestamp by hand is a poor thing to ask of someone mid-restore. `official/pre-image-toolkit-snapshot.txt` is a one-line text file holding `runs/<id>`, so a single `cat` names the current bundle and `<that>/docs` is the documentation — no tooling, on a Mac with nothing installed yet.

There are no symlinks and no `latest-*.txt` files in this category. A symlink cannot express a point rule, cannot be pinned, and does not survive the copy this bundle exists to be made of: `rsync` without `-l` writes either a broken link or a second full copy of the tree. A second pointer beside a computed one can only ever disagree with it.

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

### Bundle Layout

Two lineages share the category, one per series, and `official/` names the current run of each. Both are latest-wins, so a rerun supersedes; `--config-only` advances only the `-toolkit-config` pointer:

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
└── toolkit-snapshot/
    ├── MANIFEST.md
    ├── README.md
    ├── official/
    │   ├── <context>-toolkit-config.txt
    │   └── <context>-toolkit-snapshot.txt
    └── runs/
        ├── <context>-toolkit-config-YYYYMMDD-HHMMSS/
        │   ├── README.md
        │   ├── config/
        │   └── logs/
        └── <context>-toolkit-snapshot-YYYYMMDD-HHMMSS/
            ├── README.md
            ├── config/
            │   ├── SOURCES.txt
            │   ├── artifact-config/
            │   ├── reimage.env
            │   └── staged-certs/
            ├── docs/
            │   ├── templates/
            │   └── *.md
            └── logs/
                └── run-location.txt
```

`<context>` is `pre-image` for the Phase 4A run and `post-image` for the Phase 13A one. `logs/run-location.txt` inside a bundle records where the run landed and which pointer names it, so a bundle copied elsewhere still says where it came from.

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

The entrypoint self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand for the scripted path.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Capture the Toolkit Snapshot

Run the scripted capture. It writes a fresh run carrying both `docs/` and `config/`, and advances the `<context>-toolkit-snapshot` pointer to it; `--open` reveals the bundle when it finishes:

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

That writes a `pre-image-toolkit-config-YYYYMMDD-HHMMSS/` run holding `config/` alone, advancing only the `-toolkit-config` pointer and leaving the docs snapshot where it is. Earlier runs are never rewritten, so the sequence of config runs is the record of how the fragments changed across the effort.

Run the full capture once per phase pass and a `--config-only` refresh after each fragment edit. Two lineages under one root keep a run's name honest about its contents: `-toolkit-snapshot-` always has docs, `-toolkit-config-` never does.

> [!warning] Pitfall
> Do not copy `*.sh` or `*.py` helper scripts into the backup drive. The script source of truth is the Git repository; `docs/` carries the readable runbooks and templates only, not the executables.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Verify Outputs

Confirm the newest bundle landed and its README is present. Adjust the `pre-image` prefix to `post-image` when verifying the Phase 13A run:

```bash
TOOLKIT_SNAPSHOT_ROOT="$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot"
LATEST="$TOOLKIT_SNAPSHOT_ROOT/$(cat "$TOOLKIT_SNAPSHOT_ROOT/official/pre-image-toolkit-snapshot.txt")"
printf 'Official toolkit snapshot: %s\n' "$LATEST"
```

Confirm the bundle README and the refreshed documentation copy both exist:

```bash
test -f "$LATEST/README.md" && echo "PASS: bundle README captured"
test -d "$LATEST/docs" && echo "PASS: docs captured in the bundle"
```

Confirm the config capture recorded this Mac's fragments rather than the committed examples. This is the line the Phase 6B sign-off reads:

```bash
grep -A2 '^artifact-config' "$LATEST/config/SOURCES.txt"
grep -A2 '^staged-certs' "$LATEST/config/SOURCES.txt"
```

> [!warning] Pitfall
> An origin of `committed-template` means the run read the repository's generic example fragments, not yours. Any artifact produced by that run was driven by placeholder targets. Re-run the matching init step, then rerun this capture with `--config-only`.

> [!bug] Troubleshooting
> A missing bundle README means the scripted capture has not run yet. An empty `docs/` on a bundle whose name contains `-toolkit-config-` is expected — a `--config-only` run captures no docs by design; read the `<context>-toolkit-snapshot` pointer instead.

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
