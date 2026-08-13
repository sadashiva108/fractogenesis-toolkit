[[reimaging-guide#Phase 3C — Performance Audit Capture|← Back to Mac Reimaging Guide]]

# Capture Performance Audit

**Last updated:** 2026-08-04

A repeatable, read-only performance baseline. It captures short-duration scenario bundles under named workloads so general workstation performance can be compared like-for-like across a reimage. Run it pre-image (Phase 3C) under one or more named scenarios, then run the same scenarios post-image (Phase 11D) so the two sets compare cleanly.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#Scenarios|Scenarios]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Bundle Layout|Bundle Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Prepare and Validate|Step 1 — Prepare and Validate]]
    - [[#Step 2 — Run the Capture|Step 2 — Run the Capture]]
    - [[#Step 3 — Verify Outputs|Step 3 — Verify Outputs]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#What the Script Captures|What the Script Captures]]
    - [[#Optional Helper History and Rollup Summary|Optional Helper History and Rollup Summary]]
    - [[#Reviewing and Comparing Bundles|Reviewing and Comparing Bundles]]
    - [[#Manual Observations|Manual Observations]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Capture read-only performance evidence under one or more named workloads before the Mac is wiped, then repeat the same named workloads after reimage so general workstation responsiveness can be compared like-for-like. The bundles are diagnostic evidence, not something you restore from — nothing here is re-applied to the machine. They exist so that, after reimage, you can tell whether the new image is faster, slower, or unchanged under comparable load, and where any regression lives.

This runbook owns:

```text
the performance-audit capture and its per-scenario timestamped bundles
the optional quantitative rollup summary
interpretation of the captured performance metrics
the pre-image (Phase 3C) and post-image (Phase 11D) comparison workflow
```

It does not own:

```text
broad system inventory — capture-system-inventory.md (Phase 3B)
Office-specific stability evidence — capture-office-stability.md (Phase 3D)
cross-phase readiness sign-off — reimage-prep-checks.md (Phase 4B)
```

This capture can be rerun at any time: each run writes a fresh timestamped bundle under its scenario name and leaves earlier runs untouched.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. General workstation performance is only meaningful in comparison, so this capture is built around **matched pairs**: the same named workload run once before the reimage and once after. Each run collects repeated samples (memory pressure, top processes, app rollups, responsiveness probes, Docker and IntelliJ state) into one self-contained, timestamped bundle you can read from the external drive without the machine present.

The workflow is script-first. `capture-performance-audit.sh` runs every collection area in one pass and writes the bundle, its `manifest.txt`, and the auto-filled `manual-observations.md` / `workload-reproduction-config.md` files. You choose the `--scenario` (which workload) and `--phase` (`pre-image` or `post-image`); the script does the rest. Longer-running trend history and a quantitative rollup are optional add-ons, covered in [[#Optional Helper History and Rollup Summary|Optional Helper History and Rollup Summary]] — most runs need only the scenario bundle.

The preferred path is: capture at least the `normal-workload` scenario pre-image, capture the same scenario post-image under the closest matching workload, then compare the pair. Extra scenarios add resolution but are optional.

### Scenarios

A scenario is a run mode: a named workload the capture samples under. Every run sets `--phase pre-image` (Phase 3C) or `--phase post-image` (Phase 11D) so the pre/post pair is labelled distinctly, and reuses the **same scenario name** on both sides so the folders line up.

| Scenario | Flags | What it captures |
|---|---|---|
| `normal-workload` (minimum) | `--scenario normal-workload --sample-count 6 --sample-interval 30` | ~3 min daily-realistic baseline with your usual apps open (IntelliJ, Chrome, Teams, Docker, Terminal, etc.). |
| `clean-boot` | `--scenario clean-boot --sample-count 6 --sample-interval 30` | ~3 min quiet baseline right after reboot, before heavy tools are opened. |
| `active-dev` | `--scenario active-dev --sample-count 10 --sample-interval 30` | ~5 min stress-ish state while actively coding, indexing, building, testing, or running containers. |
| `symptom-capture` | `--scenario symptom-capture` (run long enough to catch it) | Evidence gathered while the Mac is actually slow; start it during the sluggishness. |

> [!warning] Pitfall
> Do not run `purge`, cleanup tools, or app killers immediately before a baseline. They change the very state you are trying to measure. If you need cleanup evidence, capture it as a separate, clearly-labelled run.

### Terminology

| Term | Meaning |
|---|---|
| Scenario | A named workload the capture samples under (`clean-boot`, `normal-workload`, `active-dev`, `symptom-capture`); set via `--scenario`. |
| Phase | The `--phase` label (`pre-image` / `post-image`) that prefixes the bundle name. |
| Scenario bundle | One timestamped run directory under `performance-audit/`, holding that run's samples, the manifest, and the manual-context files. |
| Helper history | The long-running `mac_memory_health.sh` output tree under `PERFORMANCE_HISTORY_SOURCE`; optional trend context, independent of any single bundle. |
| Rollup summary | An optional quantitative CSV package generated from helper history for multi-snapshot analysis. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/capture-performance-audit.sh          # entrypoint
```

Related scripts, alphabetical:

```text
$FRACTOGENESIS_HOME/.internal/performance/generate-performance-manual-observations.py   # helper — auto-fills the manual-context files (called by the entrypoint)
$FRACTOGENESIS_HOME/bin/generate-performance-rollup-summary.py        # entrypoint — optional quantitative rollup from helper history
mac_memory_health.sh                                                  # external helper — not part of this toolkit; run from ~/.local/bin/ when present
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/performance-audit/                     # all scenario bundles and the rollup summary land here
```

### Bundle Layout

Each run writes one timestamped bundle whose name carries `<phase>` and `<scenario>`; the optional rollup summary writes under `rollup-summary/`:

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── performance-audit/
│   ├── <phase>-performance-audit-<scenario>-YYYYMMDD-HHMMSS/
│   │   ├── README.md
│   │   ├── manifest.txt
│   │   ├── manual-observations.md
│   │   ├── workload-reproduction-config.md
│   │   ├── docker/
│   │   ├── intellij/
│   │   ├── logs/
│   │   ├── mac-memory-health-output/
│   │   ├── memory/
│   │   ├── processes/
│   │   ├── raw/
│   │   ├── responsiveness/
│   │   └── system/
│   └── rollup-summary/
│       └── <phase>-YYYYMMDD-HHMMSS/
│           ├── performance-rollup-summary.md
│           └── summary/
└── ...
```

The complete `$REIMAGE_ARTIFACT_ROOT/performance-audit/` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the artifact root where `performance-audit/` lives; the default capture destination. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. |
| `REIMAGE_WORKSPACE_ROOT` | Optional local staging root. Use it when captures run for days or weeks before the backup drive is mounted; stage bundles here, then copy them into `REIMAGE_ARTIFACT_ROOT`. |
| `PERFORMANCE_HISTORY_SOURCE` | Optional. The long-lived `mac_memory_health.sh` output directory read by the rollup summary (typically `~/Library/Logs/mac-memory-health`). |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what this run is for. The concepts and the *why* are in [[#How the Workflow Works|How the Workflow Works]]; this is just the checklist.

### Prerequisites

- `REIMAGE_ARTIFACT_ROOT` resolves and its destination volume is mounted (`reimage.env` produced by `prepare-artifact-root.md`) — unless you are staging locally under `REIMAGE_WORKSPACE_ROOT` first.
- You are running commands from `$FRACTOGENESIS_HOME`, per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]].
- You are on the Mac being measured — the capture reports on the host it runs on.

> [!note]
> No admin privileges are required for the read-only samples. The `mac_memory_health.sh` helper and its longer history are optional; the scenario bundle still completes with live samples when the helper is absent.

### Confirm Your Intent

- Which **phase** this is: `pre-image` (Phase 3C, before wiping) or `post-image` (Phase 11D, after setup settles) — sets `--phase` and the bundle prefix.
- Which **scenario(s)** to capture. `normal-workload` is the minimum; add `clean-boot`, `active-dev`, or `symptom-capture` when they add resolution (see [[#Scenarios|Scenarios]]). Post-image, reuse the same scenario names you captured pre-image.
- Where the bundle lands: the default `REIMAGE_ARTIFACT_ROOT/performance-audit/`, or a local stage under `REIMAGE_WORKSPACE_ROOT/performance-audit/` when the backup drive is not mounted yet.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order: confirm the environment, run the capture for each chosen scenario, then verify the bundle landed and review the manual-context files. Post-image runs repeat Step 2 with `--phase post-image` and the matching scenario names.

### Step 1 — Prepare and Validate

Confirm the entrypoint parses and the environment resolves. `capture-performance-audit.sh` self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand:

```bash
./bin/capture-performance-audit.sh --help
```

> [!note]
> With no `--output`, the capture defaults to `$REIMAGE_ARTIFACT_ROOT/performance-audit/`. Pass `--output "$REIMAGE_WORKSPACE_ROOT/performance-audit"` only when staging locally before the backup drive is mounted, or `--artifact-root PATH` to point at a different artifact root for one invocation.

### Step 2 — Run the Capture

Run one invocation per scenario. For the pre-image `normal-workload` baseline:

```bash
./bin/capture-performance-audit.sh --phase pre-image --scenario normal-workload --sample-count 6 --sample-interval 30
```

Add scenarios as needed, reusing the flags from the [[#Scenarios|Scenarios]] table (for example `--scenario active-dev --sample-count 10 --sample-interval 30`).

For the post-image run (Phase 11D, after the new image settles), keep the same scenario name and switch the phase:

```bash
./bin/capture-performance-audit.sh --phase post-image --scenario normal-workload --sample-count 6 --sample-interval 30
```

The script prints each area as it runs and finishes with the bundle path. It writes the samples, `manifest.txt`, and the auto-filled `manual-observations.md` / `workload-reproduction-config.md` under `performance-audit/<phase>-performance-audit-<scenario>-<stamp>/`.

If you staged a bundle under `REIMAGE_WORKSPACE_ROOT`, copy it into the artifact root before the Phase 4B (pre-image) or Phase 11 (post-image) sign-off:

```bash
cp -R "$REIMAGE_WORKSPACE_ROOT/performance-audit/." "$REIMAGE_ARTIFACT_ROOT/performance-audit/"
```

### Step 3 — Verify Outputs

Confirm the newest bundle landed and holds its sample directories and manifest:

```bash
LATEST="$(ls -dt "$REIMAGE_ARTIFACT_ROOT"/performance-audit/*performance-audit-*/ | head -1)"
echo "$LATEST"
ls -1 "$LATEST"
```

Review the auto-filled manual-context files so the post-image run can reproduce this workload — this is a hand check that rolls up to the Phase 4B sign-off. Confirm `manual-observations.md` records the workload context and any remaining TODOs, and that `workload-reproduction-config.md` reflects the apps and Docker state you actually had open; see [[#Manual Observations|Manual Observations]] for what to fill in:

```bash
sed -n '1,40p' "$LATEST/manual-observations.md"
```

> [!bug] Troubleshooting
> Non-fatal stderr entries and missing-history warnings are expected on some Macs; they are covered in [[#Troubleshooting|Troubleshooting]]. A bundle missing its sample directories means the run was interrupted — rerun rather than trusting a partial bundle.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script captures uniformly; deciding what is worth capturing and what a difference means stays with you.

| Decision | Why it stays with you |
|---|---|
| Which scenarios are worth capturing? | `normal-workload` is the floor, but only you know whether `clean-boot`, `active-dev`, or `symptom-capture` reflect the slowness you are chasing. |
| Is a pre/post delta real degradation or just noise? | Sample-to-sample variance and workload mismatch both move the numbers; deciding whether a delta is signal or noise is a judgment call (see [[#Reviewing and Comparing Bundles|Reviewing and Comparing Bundles]]). |
| Do you need the longer helper history at all? | For a straight before/after the scenario bundles may be enough; helper history and the rollup only earn their place when you need chronic-vs-intermittent trend context. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### The error log shows warnings but the run "succeeded"

The script writes command stderr to `logs/errors.log` inside the bundle. Several entries are evidence, not failures.

| Error / warning | Meaning | Action |
|---|---|---|
| `system_profiler` warnings | Some profiler subfields write to stderr. | Safe to ignore when the profiler output exists. |
| Docker plugin warnings | The Docker CLI found stale or missing plugin references. | Keep as pre/post Docker state; not an audit failure. |
| Command exited for an unavailable tool | A tool is not present or not applicable on this Mac. | Continue if the main evidence for that area exists. |
| No historical metrics | The optional hourly helper history was not installed. | Run anyway; live samples are still captured. |

### `clean-boot` shows Docker stopped

For a `clean-boot` scenario it is fine for Docker Desktop to be off. The script records that in `docker/docker-daemon-state.txt` and skips daemon-dependent commands. Note in `manual-observations.md` that Docker was intentionally stopped so the matching post-image `clean-boot` uses the same assumption.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### What the Script Captures

Each scenario bundle collects one area per subdirectory:

| Area | Evidence captured |
|---|---|
| Run metadata (`README.md`, `manifest.txt`, `logs/`) | timestamp, hostname, elapsed seconds, command log, error log, file inventory. |
| `system/` | macOS version, architecture, uptime, boot time, RAM, CPU, disks/APFS, power/thermal, battery, visible GUI apps, selected `system_profiler` output. |
| `memory/` | repeated live samples — `vm_stat`, `memory_pressure`, `sysctl vm.swapusage`, top-memory and top-CPU snapshots. |
| `processes/` | grouped RAM/CPU app rollups (IntelliJ, Chrome, Teams, Docker, VS Code, Postman, Obsidian, Java, Gradle, Node, and more) and development-agent parent chains (Copilot, Codex, Claude, Aider, Cursor) when present. |
| `responsiveness/` | repeated timing probes for repeatable responsiveness checks. |
| `docker/` | Docker version/info/context, system disk usage, container list, and resource-related settings extracts. |
| `intellij/` | IntelliJ app/process candidates and `idea.vmoptions` discovery and contents. |
| `mac-memory-health-output/` | a fresh `mac_memory_health.sh` snapshot redirected into the bundle when the helper is available. |

### Optional Helper History and Rollup Summary

Two optional pieces sit outside the scenario bundle and add longer-range context.

**`mac_memory_health.sh` (helper history).** A reusable workstation helper that keeps long-running trend history under `PERFORMANCE_HISTORY_SOURCE` (typically `~/Library/Logs/mac-memory-health`), via hourly LaunchAgent capture or short-interval monitoring. Keep it separate from the reimage collector: the scenario bundle is for apples-to-apples pre/post comparison, the helper history is for deciding whether the machine is consistently slow, slow only under certain workloads, or slow only during occasional spikes. The capture does not copy the whole history into every bundle — it points `MAC_MEMORY_HEALTH_DIR` at the bundle-local `mac-memory-health-output/` and takes a fresh snapshot, keeping the bundle self-contained.

For a clean pre/post cutover, keep the final pre-image history window intact, archive it (for example under `REIMAGE_WORKSPACE_ROOT/performance-audit/history-archives/`), then start a fresh post-image series so the windows do not intermix. Use the most recent representative 7–14 days as the pre-image window and the first representative 2–7 days after setup settles as the post-image window.

> [!note]
> Only `mac_memory_health.sh` is external — it lives at `~/.local/bin/`, is not part of this toolkit, and may be absent. `generate-performance-rollup-summary.py` is a migrated `bin/` entrypoint.

**Rollup summary (`generate-performance-rollup-summary.py`).** When you have many diagnostic rollups over days or weeks, this produces a quantitative CSV package under `performance-audit/rollup-summary/<phase>-<stamp>/` (`performance-rollup-summary.md` plus a `summary/` of grouped app RSS/CPU/process-count pivots and health-window CSVs). It does not compute a single merged pre/post score — it produces structured inputs that make that follow-up analysis possible.

### Reviewing and Comparing Bundles

Once matching pre-image and post-image bundles exist, compare like files. Point a shell variable at the bundle root you actually used (artifact root or local stage), open its `README.md`, then read the first-pass evidence: `memory/sample_1_memory.txt`, `processes/app_rollup.csv`, `responsiveness/responsiveness-probes.txt`, `docker/docker-settings-resource-extract.txt`, and `intellij/intellij-vmoptions-contents.txt`. Compare each against the post-image bundle's matching file under the same scenario name.

What counts as degraded — the helper's own thresholds are the reference:

- `CRITICAL` when `memory_pressure_free_pct < 10` **or** `swap_used_mb >= 4096`.
- `WARN` when `memory_pressure_free_pct < 20` **or** `swap_used_mb >= 1024`.
- `WATCH` when `delta_swapouts > 0` within a recent window; `OK` otherwise.

Reading guidance: low `memory_pressure` free percentage is more concerning than high used memory alone; swap growth during normal work is a stronger degradation sign than raw RAM usage; one app group repeatedly dominating grouped RSS or CPU points to workload-level pressure rather than an OS-wide mystery; and a post-image `clean-boot` that still feels slow points toward system-management, indexing, network, or disk activity rather than restored user workload.

### Manual Observations

`capture-performance-audit.sh` auto-fills two manual-context files inside every bundle (via `generate-performance-manual-observations.py`) so you review rather than author them from scratch:

```text
manual-observations.md
workload-reproduction-config.md
```

`manual-observations.md` opens pre-filled with captured context and a short list of remaining TODOs — workload details the scripts cannot infer. Fill those in while the run is fresh: which apps and projects were open, whether Docker was intentionally running or stopped, and anything unusual about the session.

`workload-reproduction-config.md` is the more objective companion. Use it, when running the post-image scenario, to get as close as possible to the same setup by matching the scenario label, whether Docker was running, the visible app set, the top app-group mix, and the responsiveness-probe timings. Exact one-to-one reproduction is not automatic, but reviewing these files is what makes the post-image comparison trustworthy — the comparison is only meaningful if the post-image workload really matches the pre-image workload.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link.
-->
