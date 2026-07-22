---
title: Capture Managed Inventory
back_link: "reimaging-guide#Phase 2C — Company-Managed Inventory Capture"
runbook_version: 0.1.0
verb_first: true
primary_scripts:
  - bin/capture-managed-inventory.sh
related_scripts:
  - bin/capture-size-audit.sh
artifact_paths:
  - $REIMAGE_ARTIFACT_ROOT/managed-inventory/
author: Orah Kittrell
last_updated: 2026-07-21
---
[[reimaging-guide#Phase 2C — Company-Managed Inventory Capture|← Back to Mac Reimaging Guide]]

# Capture Managed Inventory

A read-only record of what a company-managed Mac has under management — MDM enrollment, configuration profiles, installed apps and package receipts, background agents and daemons, system extensions, and managed preferences. It observes and records only; it never modifies managed state. Run it pre-image (Phase 2C) to preserve a before-reimage picture, and again post-image (Phase 11C) to compare the freshly re-enrolled machine against that record.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#What Gets Captured|What Gets Captured]]
    - [[#Read-Only Guarantee|Read-Only Guarantee]]
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
    - [[#Per-Section Command Reference|Per-Section Command Reference]]
    - [[#Interpretation Notes|Interpretation Notes]]
    - [[#Pre-Image vs Post-Image Comparison|Pre-Image vs Post-Image Comparison]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Preserve a precise, timestamped inventory of what management controls on this Mac before it is wiped, and produce the same inventory afterward so the two can be compared. The capture is diagnostic evidence, not a backup you restore from — nothing here is re-applied to the machine. It exists so that, after reimage and re-enrollment, you can tell what management put back, what is missing, and what changed.

This runbook owns:

```text
the managed-inventory capture and its timestamped bundle
interpretation of MDM, profile, package, agent/daemon, extension, and managed-preference evidence
the pre-image (Phase 2C) and post-image (Phase 11C) comparison workflow
the full managed-inventory/ layout
```

It does not own:

```text
backing up your own app settings — backup-apps.md (Phase 2D)
the managed apps and profiles themselves — they are IT-owned and are never modified here
certificate and Keychain staging — Phase 2E
final encrypted DMG packaging — create-secrets-dmg.md (Phase 2F)
cross-phase readiness sign-off — reimage-prep-checks.md (Phase 4B)
```

This capture can be rerun at any time and on any managed Mac: each run writes a fresh timestamped bundle and leaves earlier runs untouched.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Management state is spread across several independent macOS subsystems, and no single command reports all of it. This capture runs one command per subsystem, writes each result to its own numbered file, and adds a filtered pass that narrows everything to likely corporate tooling. The result is a self-contained bundle you can read on the external drive without the machine present.

The workflow is script-first. `capture-managed-inventory.sh` runs every section in one pass and writes the bundle plus a `MANIFEST.txt`. The same sections are documented as individual commands in [[#Per-Section Command Reference|Per-Section Command Reference]] for the rare case where you need to rerun or troubleshoot just one — use the script for the standard run, the individual commands only when isolating a single section.

### What Gets Captured

One numbered file per subsystem, plus a manifest:

```text
01  MDM enrollment status              profiles status -type enrollment
02  configuration profiles             profiles show -type configuration
03  installed app bundles              /Applications + /System/Applications
04  installed package receipts         pkgutil --pkgs
05  background managed components       LaunchAgents/Daemons + system extensions
06  managed preference payloads         /Library/Managed Preferences
07  company-focused filter pass         the above, narrowed to likely corporate tooling
```

The filter pass (section 07) does not add new data — it re-runs the earlier queries with a name filter for common corporate vendors (Microsoft, Intune, Company Portal, CrowdStrike, Zscaler, Defender, VPN, and similar) so the likely IT-owned components stand out from everything else.

### Read-Only Guarantee

Every command in this capture reads state and writes only into the bundle. Nothing unenrolls the Mac, removes a profile, unloads an agent, or changes a managed preference. `profiles`, `pkgutil`, `find`, `ls`, and `systemextensionsctl` are all used in their reporting modes only. You can run it on a live managed machine without risk to compliance.

> [!warning] Pitfall
> Do not substitute the removal variants of these commands (for example `profiles remove`) while poking around. This runbook is inventory only; changing managed state is out of scope and can break enrollment.

### Terminology

| Term | Meaning |
|---|---|
| Managed state | Anything IT/MDM installs or enforces: enrollment, profiles, managed preferences, deployed packages, security/VPN agents. |
| Configuration profile | A `.mobileconfig` payload pushed by MDM to enforce settings; listed by `profiles show -type configuration`. |
| Package receipt | A record left by an installer (`pkgutil`), the best clue for centrally deployed software. |
| Managed preference | A preference file under `/Library/Managed Preferences` enforced or delivered by management. |
| Context | The `--context` label (`pre-image` / `post-image`) that prefixes the run directory. |
| Bundle | One timestamped run directory under `managed-inventory/`, holding the seven section files and `MANIFEST.txt`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/capture-managed-inventory.sh    # entrypoint — runs every section in one pass
```

Related scripts:

```text
$FRACTOGENESIS_HOME/bin/capture-size-audit.sh           # entrypoint — capacity check for the artifact root
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/managed-inventory/               # all managed-inventory bundles land here
```

### Bundle Layout

Each run writes one timestamped bundle. The `<context>` prefix comes from `--context` (default `pre-image`):

```text
$REIMAGE_ARTIFACT_ROOT/managed-inventory/
└── <context>-YYYYMMDD-HHMMSS/
    ├── 01-enrollment-status.txt
    ├── 02-profiles-configuration.txt
    ├── 03-installed-app-bundles.txt
    ├── 04-installed-package-receipts.txt
    ├── 05-background-managed-components.txt
    ├── 06-managed-preference-payloads.txt
    ├── 07-gaig-filter-pass.txt
    └── MANIFEST.txt
```

The complete `$REIMAGE_ARTIFACT_ROOT` map is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the Phase 2 artifact root where `managed-inventory/` lives. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what this run is for. The concepts and the *why* are in [[#How the Workflow Works|How the Workflow Works]]; this is just the checklist.

### Prerequisites

- `REIMAGE_ARTIFACT_ROOT` resolves and its destination volume is mounted (`reimage.env` produced by `prepare-artifact-root.md`).
- You are running commands from `$FRACTOGENESIS_HOME`.
- You are on the company-managed Mac itself (not a personal machine) — the capture reports on the host it runs on.

> [!note]
> No admin privileges are required for the read-only queries. Some sections may show fewer results without elevated rights, but the capture still completes and records what it can see.

### Confirm Your Intent

- Whether this is the **pre-image** run (Phase 2C, before wiping) or the **post-image** run (Phase 11C, after re-enrollment) — this sets `--context` and the bundle prefix.
- That you want a full managed picture, not just your own app settings — those are [[backup-apps|Backup Apps]] (Phase 2D), a separate phase.
- Whether you will compare this bundle against an earlier one; if so, keep the pre-image bundle so the post-image run has something to diff against (see [[#Pre-Image vs Post-Image Comparison|Pre-Image vs Post-Image Comparison]]).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order: confirm the environment, run the capture, then verify the bundle. The capture is one command; the surrounding steps make sure it landed where you expect.

### Step 1 — Prepare and Validate

Confirm the artifact root resolves and the destination volume is mounted. `capture-managed-inventory.sh` self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand:

```bash
cd "$FRACTOGENESIS_HOME"
./bin/capture-managed-inventory.sh --help
```

Confirm the destination has room if you have not already run the size audit for this artifact root:

```bash
./bin/capture-size-audit.sh --context pre-image-managed-inventory
```

### Step 2 — Run the Capture

Run the full capture. For the pre-image run, the default context is correct, so no flag is needed:

```bash
cd "$FRACTOGENESIS_HOME"
./bin/capture-managed-inventory.sh
```

For the post-image run (Phase 11C, after the Mac is re-enrolled), set the context so the bundle is labelled distinctly:

```bash
./bin/capture-managed-inventory.sh --context post-image
```

To point at a different artifact root for one invocation, add `--artifact-root PATH`. To write to an exact directory and skip the `managed-inventory/<context>-<stamp>` layout entirely, use `--output DIR`.

The script prints each section as it runs and finishes with the bundle path. It writes the seven section files and `MANIFEST.txt` under `managed-inventory/<context>-<stamp>/`.

> [!note]
> Section 07 (the company-focused filter pass) is expected to be a subset of the earlier sections. Empty results there are normal on a lightly managed machine — it means none of the filtered vendor names matched, not that the capture failed.

### Step 3 — Verify Outputs

Confirm the bundle landed and holds all seven sections plus the manifest.

```bash
LATEST="$(ls -dt "$REIMAGE_ARTIFACT_ROOT"/managed-inventory/*/ | head -1)"
echo "$LATEST"
ls -1 "$LATEST"
```

You should see `01-` through `07-` and `MANIFEST.txt`. Spot-check the enrollment and profile sections, which carry the most decision-relevant evidence:

```bash
sed -n '1,40p' "$LATEST/01-enrollment-status.txt"
sed -n '1,40p' "$LATEST/02-profiles-configuration.txt"
```

> [!bug] Troubleshooting
> Empty or permission-limited sections are covered in [[#Troubleshooting|Troubleshooting]]. A missing section file (fewer than seven) means the run was interrupted — rerun the capture rather than trusting a partial bundle.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script captures uniformly; interpreting what management owns is the judgment call.

| Decision | Why it stays with you |
|---|---|
| Which components are actually IT-owned vs personal? | The filter pass flags likely corporate tooling, but only you know which apps and agents you installed yourself. |
| Is a managed difference between pre- and post-image expected? | Re-enrollment legitimately changes some managed state; deciding whether a delta is normal or worth raising with IT is yours to make. |
| Do you need the post-image run at all? | If you are not verifying re-enrollment, the pre-image bundle alone may be enough — the Phase 11C run is for comparison. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### A section is empty or shows fewer results than expected

Some queries return less without elevated rights, and a genuinely lightly-managed Mac will have empty sections (for example no third-party system extensions). An empty section file with its header intact means the command ran and found nothing — that is a valid result, not an error.

### `profiles` reports nothing on an enrolled machine

`profiles status`/`profiles show` can be restricted by management on some configurations. Record what it returns; the package-receipt, app-bundle, and Managed Preferences sections still provide corroborating evidence of what is deployed.

### Fewer than seven section files in the bundle

The run was interrupted before completing. Delete or ignore the partial bundle and rerun `capture-managed-inventory.sh` — each run writes a fresh timestamped directory, so a rerun does not overwrite anything.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Per-Section Command Reference

The individual commands behind each section file. Use these only to rerun or troubleshoot a single section; the script runs all of them in one pass.

**`01`/`02` — MDM enrollment and configuration profiles.** Whether the Mac is enrolled and what payloads management has pushed.

```bash
profiles status -type enrollment
profiles show -type configuration
```

**`03` — Installed app bundles.** A practical list of apps present without the slow `system_profiler` enumeration.

```bash
find /Applications /System/Applications -maxdepth 2 -name "*.app" -type d 2>/dev/null | sort
```

**`04` — Installed package receipts.** Installer receipts, often the best clue for centrally deployed software.

```bash
pkgutil --pkgs | sort
```

**`05` — Background managed components.** Persistent agents, daemons, and system extensions used by security, VPN, sync, and management tools.

```bash
ls -1 /Library/LaunchAgents /Library/LaunchDaemons 2>/dev/null
systemextensionsctl list
```

**`06` — Managed preference payloads.** Preference files enforced or delivered by management.

```bash
find /Library/Managed\ Preferences -maxdepth 2 -type f 2>/dev/null
```

**`07` — Company-focused filter pass.** The earlier queries narrowed to likely corporate tooling.

```bash
pkgutil --pkgs | grep -Ei 'microsoft|intune|companyportal|crowdstrike|zscaler|defender|vpn|security|falcon'
find /Applications /System/Applications -maxdepth 2 -name "*.app" -type d 2>/dev/null | grep -Ei 'Company Portal|Microsoft|CrowdStrike|Zscaler|Defender|VPN'
ls /Library/LaunchAgents /Library/LaunchDaemons 2>/dev/null | grep -Ei 'microsoft|intune|companyportal|crowdstrike|zscaler|defender'
systemextensionsctl list | grep -Ei 'microsoft|crowdstrike|zscaler|defender'
```

### Interpretation Notes

Read each section for what it is best at: `profiles` for what MDM manages, `find /Applications` for what is installed, `pkgutil` for what installers deployed, LaunchAgents/Daemons plus `systemextensionsctl` for background managed and security components, and Managed Preferences for enforced settings. No single source is authoritative on its own — a component deployed by IT typically shows up across several sections at once (a package receipt, an app bundle, and a launch agent), and that overlap is what makes something confidently IT-owned.

The bundle is the evidence. Do not retype app, profile, package, agent, daemon, system-extension, or managed-preference details into a separate note — reference the section file instead. Add a short written comparison note only when a managed-state difference still needs explanation after reviewing the captured files.

### Pre-Image vs Post-Image Comparison

The pre-image bundle (Phase 2C) and the post-image bundle (Phase 11C) share the same seven-section shape, so they diff cleanly. After re-enrollment, compare matching section files to see what management restored, added, or dropped:

```bash
PRE="$REIMAGE_ARTIFACT_ROOT/managed-inventory/pre-image-YYYYMMDD-HHMMSS"
POST="$REIMAGE_ARTIFACT_ROOT/managed-inventory/post-image-YYYYMMDD-HHMMSS"
diff "$PRE/04-installed-package-receipts.txt" "$POST/04-installed-package-receipts.txt"
diff "$PRE/02-profiles-configuration.txt"    "$POST/02-profiles-configuration.txt"
```

Timestamps and generation dates in the file headers will always differ; focus on the payload lines. Expect some legitimate churn from re-enrollment — the point is to surface anything unexpected, not to demand an identical match.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link.
-->
