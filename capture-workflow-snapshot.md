[[reimaging-guide#Phase 3A — Capture Workflow Snapshot|← Back to Mac Reimaging Guide]]

# Capture Workflow Snapshot

**Last updated:** 2026-08-04

A lightweight capture that preserves the reimage workflow's own documentation and templates alongside a timestamped snapshot bundle, so the state of the runbooks that drove this reimage travels with the backup drive. Run it pre-image (Phase 3A) to record the workflow as it stands before the rebuild, and again post-image (Phase 11A) to record the final workflow state after any runbook or script refinements made during the effort.

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
    - [[#Step 2 — Capture the Workflow Snapshot|Step 2 — Capture the Workflow Snapshot]]
    - [[#Step 3 — Verify Outputs|Step 3 — Verify Outputs]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Preserve a portable copy of the reimage workflow itself — the runbooks and templates that guided this effort — so the instructions survive the wipe on the backup drive, and produce a fresh copy after the rebuild so refinements made along the way are recorded. The capture is documentation evidence, not application or user data; it exists so the workflow that drove a given reimage can be read back later without the repository checked out, and so the pre-image and post-image states of the runbooks can be compared.

This runbook owns:

```text
the timestamped workflow-snapshot bundle (pre-image-workflow-snapshot-*)
the refreshable reimage-workflow-docs/ copy of the workflow runbooks and templates
```

It does not own:

```text
broad local-file and home-directory backup — backup-home.md (Phase 2B)
system-state and tooling inventory — capture-system-inventory.md (Phase 3B)
the full $REIMAGE_ARTIFACT_ROOT/workflow-snapshot/ tree layout — master-directory-reference.md
```

This capture can be rerun at any time: each run writes a fresh timestamped bundle and leaves earlier bundles untouched, while the documentation copy is refreshed only when you intentionally rerun the doc-copy step.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The capture produces two distinct things under `workflow-snapshot/`, and they behave differently on purpose. The **timestamped bundle** (`pre-image-workflow-snapshot-*`) is point-in-time evidence: each run creates a new dated directory, and old ones are never overwritten, so you always have the workflow as it stood at a given moment. The **documentation copy** (`reimage-workflow-docs/`) is a single refreshable folder that holds the latest runbooks and templates, so the backup drive can carry a current, readable copy of the instructions without the repository present.

Ordering follows the reimage timeline. The pre-image run (Phase 3A) records the workflow before the machine is wiped. The post-image run (Phase 11A) records the final workflow state after the rebuild, capturing any runbook or script refinements you made while working through the effort — so the two bundles together show how the workflow itself evolved across the reimage.

The preferred path is the scripted capture: one entrypoint writes the bundle and refreshes the documentation copy in a single pass. Until that entrypoint is migrated into `bin/` (see the note below), the documentation copy is produced by running the doc-copy block directly.

### Terminology

| Term | Meaning |
|---|---|
| Bundle | One timestamped run directory (`<context>-workflow-snapshot-YYYYMMDD-HHMMSS/`); immutable point-in-time evidence. |
| Documentation copy | The single `reimage-workflow-docs/` folder holding the latest workflow runbooks and templates; refreshed in place. |
| Context | The `pre-image` / `post-image` label that prefixes the bundle name and marks which side of the reimage it records. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/capture-workflow-snapshot.sh    # entrypoint
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/    # all workflow-snapshot artifacts land here
```

The subtree this runbook touches — the timestamped bundle and the documentation copy:

```text
$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/
├── ...
├── pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/
│   ├── README.md
│   └── logs/
│       └── latest-aliases.txt
└── reimage-workflow-docs/
    ├── *.md
    └── templates/
```

The complete `$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the artifact root where `workflow-snapshot/` lives. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here, and it is the source of the docs and templates copied into `reimage-workflow-docs/`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what this run is for. The concepts and the *why* are in [[#How the Workflow Works|How the Workflow Works]]; this is just the checklist.

### Prerequisites

- `REIMAGE_ARTIFACT_ROOT` resolves and its destination volume is mounted (`reimage.env` produced by `prepare-artifact-root.md`).
- You are running commands from `$FRACTOGENESIS_HOME`.
- The repository holds the current workflow runbooks and templates you intend to snapshot — the doc copy reflects `$FRACTOGENESIS_HOME` as it is right now.

### Confirm Your Intent

- Whether this is the **pre-image** run (Phase 3A, before wiping) or the **post-image** run (Phase 11A, after the rebuild) — this sets the bundle's `context` prefix and which side of the reimage it records.
- Whether you are producing a new timestamped bundle, refreshing the documentation copy, or both — the bundle is fresh every run, the doc copy changes only when you rerun the doc-copy step.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order: confirm the environment, capture the snapshot and refresh the docs, then verify what landed. The capture is a single scripted pass once the entrypoint exists; today the documentation copy is produced by the doc-copy block within Step 2.

### Step 1 — Prepare and Validate

Confirm the artifact root resolves and its volume is mounted before writing anything into it:

```bash
test -d "$REIMAGE_ARTIFACT_ROOT" && echo "artifact root: $REIMAGE_ARTIFACT_ROOT"
```

Syntax-check the entrypoint before the first run:

```bash
bash -n bin/capture-workflow-snapshot.sh
```

> [!note]
> The entrypoint self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand for the scripted path.

### Step 2 — Capture the Workflow Snapshot

Run the scripted capture. It writes a fresh timestamped bundle and refreshes the documentation copy in one pass; `--open` reveals the bundle when it finishes:

```bash
./bin/capture-workflow-snapshot.sh --open
```

For the post-image run (Phase 11A, after the rebuild), set the context so the bundle is labelled distinctly and sits beside the pre-image bundle rather than overwriting it:

```bash
./bin/capture-workflow-snapshot.sh --context post-image --open
```

If the docs changed after a bundle was captured and you want the backup drive to carry the latest instructions without a full recapture, refresh the documentation copy directly. This copies the repository's top-level workflow docs and its `templates/` into `reimage-workflow-docs/`:

```bash
DOC_DEST="$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/reimage-workflow-docs"
mkdir -p "$DOC_DEST" "$DOC_DEST/templates"
find "$FRACTOGENESIS_HOME" -maxdepth 1 -type f -name '*.md' -exec cp {} "$DOC_DEST/" \;
cp "$FRACTOGENESIS_HOME/templates/"*.md "$DOC_DEST/templates/" 2>/dev/null || true
```

> [!warning] Pitfall
> Do not copy `*.sh` or `*.py` helper scripts into the backup drive. The script source of truth is the Git repository; the doc copy carries the readable runbooks and templates only, not the executables.

### Step 3 — Verify Outputs

Confirm the newest bundle landed and its README is present. Adjust the `pre-image` prefix to `post-image` when verifying the Phase 11A run:

```bash
WORKFLOW_SNAPSHOT_ROOT="$REIMAGE_ARTIFACT_ROOT/workflow-snapshot"
LATEST="$(find "$WORKFLOW_SNAPSHOT_ROOT" -maxdepth 1 -type d -name 'pre-image-workflow-snapshot-*' 2>/dev/null | sort | tail -1)"
printf 'Latest workflow snapshot: %s\n' "$LATEST"
```

Confirm the bundle README and the refreshed documentation copy both exist:

```bash
test -f "$LATEST/README.md" && echo "PASS: bundle README captured"
test -d "$WORKFLOW_SNAPSHOT_ROOT/reimage-workflow-docs" && echo "PASS: workflow docs snapshot present"
```

> [!bug] Troubleshooting
> An empty `reimage-workflow-docs/` means the doc-copy block did not run — run it from Step 2. A missing bundle README means the scripted capture has not run yet; the manual doc copy alone does not create the timestamped bundle.

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
