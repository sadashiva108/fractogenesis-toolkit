[[reimaging-guide#Phase 2C — Company Managed Inventory Capture|← Back to Mac Reimaging Guide]]

# Capture Managed Inventory

**Last updated:** 2026-09-01

A read-only record of what a company-managed Mac has under management — MDM enrollment, configuration profiles, installed apps and package receipts, background agents and daemons, system extensions, and managed preferences. It observes and records only; it never modifies managed state. Run it pre-image (Phase 2C) to preserve a before-reimage picture, and again post-image (Phase 13C) to compare the freshly re-enrolled machine against that record.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#What Gets Captured|What Gets Captured]]
    - [[#Read-Only Guarantee|Read-Only Guarantee]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Category Layout|Category Layout]]
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

> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

`capture-managed-inventory` (Phase 2C) preserves a precise, timestamped record of what management controls on this Mac before it is wiped, so the same record taken after re-enrollment can be compared against it. The capture is diagnostic evidence, not a backup you restore from — nothing here is re-applied to the machine.

**What it sets up**

- **A timestamped managed-state bundle** — seven section files covering enrollment, configuration profiles, installed apps, package receipts, background agents and extensions, managed preferences, and a corporate-tooling filter pass, plus a `MANIFEST.txt`.
- **A per-app managed verdict** — section 03 tags every installed app `[managed: …]`, `[likely: receipt]`, or `[-]`, and is the single authoritative per-app call for the whole workflow.
- **A comparable baseline** — the post-image run produces the same seven-section shape, so the two bundles diff cleanly.

**What the rest of the workflow relies on it for**

- Phase 2D reads section 03's verdicts to decide which installed apps are MDM-restored and can be skipped, which is why this phase runs before the app pass rather than after it.
- Phase 13C diffs its bundle against this one to confirm re-enrollment restored what it should have.
- The Phase 6B readiness sign-off checks that a pre-image bundle exists.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| the managed-inventory capture and its timestamped bundles | your own app settings and installers — `backup-apps` (Phase 2D) |
| interpretation of MDM, profile, package, agent/daemon, extension, and managed-preference evidence | the managed apps and profiles themselves — IT-owned, and never modified here |
| the pre-image (Phase 2C) and post-image (Phase 13C) comparison workflow | certificate and Keychain staging — `stage-certs-keychain` (Phase 3A) |
| the full `managed-inventory/` layout | encrypted DMG packaging — `create-secrets-dmg` (Phase 3C) |
| | cross-phase readiness sign-off — `reimage-prep-checks` (Phase 6B) |

This capture can be rerun at any time and on any managed Mac: each run writes a fresh timestamped bundle and leaves earlier runs untouched.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Management state is spread across several independent macOS subsystems, and no single command reports all of it. This capture runs one command per subsystem, writes each result to its own numbered file, and adds a filtered pass that narrows everything to likely corporate tooling. The result is a self-contained bundle you can read on the external drive without the machine present.

Each run is indexed, not just written. The script stages the bundle, promotes it when every section has completed, records a row in the category's `MANIFEST.md`, and points `official/<context>.txt` at it. That pointer is how every later reader finds this capture: `backup-apps` reads the official **pre-image** run for its managed-app partition, and so do the Phase 8 enrollment record and the Phase 10 restored-state comparison. Naming the lineage is the point — once Phase 13C writes a post-image bundle beside the pre-image one, "the newest bundle" stops meaning "what this Mac had before the erase", and a comparison that took it would measure the machine against itself.

The workflow is script-first. `capture-managed-inventory.sh` runs every section in one pass and writes the bundle plus a `MANIFEST.txt`. The same sections are documented as individual commands in [[#Per-Section Command Reference|Per-Section Command Reference]] for the rare case where you need to rerun or troubleshoot just one — use the script for the standard run, the individual commands only when isolating a single section.

### What Gets Captured

One numbered file per subsystem, plus a manifest:

```text
01  MDM enrollment status              profiles status -type enrollment
02  configuration profiles             profiles show -type configuration
03  installed app bundles              /Applications + /System/Applications + ~/Applications (verdict-tagged)
04  installed package receipts         pkgutil --pkgs
05  background managed components       LaunchAgents/Daemons + system extensions
06  managed preference payloads         /Library/Managed Preferences
07  company-focused filter pass         the above, narrowed to likely corporate tooling
```

The filter pass (section 07) does not add new data — it re-runs the earlier queries with a name filter for common corporate vendors (Microsoft, Intune, Company Portal, CrowdStrike, Zscaler, Defender, VPN, and similar) so the likely IT-owned components stand out from everything else.

### Read-Only Guarantee

Every command in this capture reads state and writes only into the bundle. Nothing unenrolls the Mac, removes a profile, unloads an agent, or changes a managed preference. `profiles`, `pkgutil`, `find`, `ls`, `systemextensionsctl`, and `PlistBuddy` (used only to read each app's bundle identifier for the section 03 annotation) are all used in their reporting modes only. You can run it on a live managed machine without risk to compliance.

> [!warning] Pitfall
> Do not substitute the removal variants of these commands (for example `profiles remove`) while poking around. This runbook is inventory only; changing managed state is out of scope and can break enrollment.

### Terminology

| Term | Meaning |
|---|---|
| Managed state | Anything IT/MDM installs or enforces: enrollment, profiles, managed preferences, deployed packages, security/VPN agents. |
| Configuration profile | A `.mobileconfig` payload pushed by MDM to enforce settings; listed by `profiles show -type configuration`. |
| Package receipt | A record left by an installer (`pkgutil`), the best clue for centrally deployed software. |
| Managed preference | A preference file under `/Library/Managed Preferences` enforced or delivered by management. |
| Context | The `--context` label (`pre-image` / `post-image`) that prefixes the run directory. It is also the lineage name: one official pointer per context. |
| Bundle | One timestamped run directory under `managed-inventory/runs/`, holding the seven section files and its own `MANIFEST.txt`. |
| Official run | The bundle a reader gets when it asks this category for a context. Computed, not stored: latest completed run of that context wins, and `official/<context>.txt` caches the answer. |

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
$FRACTOGENESIS_HOME/bin/report-size-audit.sh           # entrypoint — capacity check for the artifact root
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/managed-inventory/               # the run category; all bundles land under its runs/
```

### Category Layout

`managed-inventory/` is a run category. Bundles live under `runs/`, `MANIFEST.md` is the append-only index of completed runs, and each file under `official/` names the current run for one context:

```text
$REIMAGE_ARTIFACT_ROOT/managed-inventory/
├── MANIFEST.md                         # append-only index; one row per completed run
├── official/
│   ├── pre-image.txt                   # → runs/pre-image-YYYYMMDD-HHMMSS
│   └── post-image.txt                  # → runs/post-image-YYYYMMDD-HHMMSS (after Phase 13C)
└── runs/
    └── <context>-YYYYMMDD-HHMMSS/      # one bundle; see Bundle Layout
```

`MANIFEST.md` is the source of truth and is never edited by hand; the pointers under `official/` are a derived cache. If one goes missing or names a run that is not on disk, regenerate them rather than writing one:

```bash
./bin/reindex-artifact-runs.sh --category "$REIMAGE_ARTIFACT_ROOT/managed-inventory"
```

A directory whose name still carries a `.incomplete` suffix is a capture that died part way through. It is deliberately not indexed and not official — delete it, or leave it; no reader will see it.

### Bundle Layout

Each run writes one timestamped bundle under `runs/`. The `<context>` prefix comes from `--context` (default `pre-image`), and is also the run's lineage:

```text
$REIMAGE_ARTIFACT_ROOT/managed-inventory/runs/
└── <context>-YYYYMMDD-HHMMSS/
    ├── 01-enrollment-status.txt
    ├── 02-profiles-configuration.txt
    ├── 03-installed-app-bundles.txt
    ├── 04-installed-package-receipts.txt
    ├── 05-background-managed-components.txt
    ├── 06-managed-preference-payloads.txt
    ├── 07-company-filter-pass.txt
    └── MANIFEST.txt                    # this bundle's own file list, run id, and context
```

The bundle's `MANIFEST.txt` describes one capture; the category's `MANIFEST.md` indexes them all. They are different files answering different questions, and the bundle keeps its own so a directory copied off the drive still says what it is.

The complete `$REIMAGE_ARTIFACT_ROOT` map is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The values this script reads. `REIMAGE_ARTIFACT_ROOT` is resolved and written into `reimage.env` during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `FRACTOGENESIS_HOME` | The toolkit checkout holding the scripts and this runbook. A shell-startup or `.envrc` value, not a `reimage.env` key. |
| `REIMAGE_ARTIFACT_ROOT` | The artifact root where `managed-inventory/` lives. `--artifact-root PATH` overrides it for one invocation. |

`capture-managed-inventory.sh` reads no other configured values — it takes no artifact-config fragments and no OneDrive settings.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what this run is for.

### Prerequisites

- `REIMAGE_ARTIFACT_ROOT` resolves and its destination volume is mounted (`reimage.env` produced by `prepare-artifact-root.md`).
- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- You are on the company-managed Mac itself (not a personal machine) — the capture reports on the host it runs on.

> [!note]
> No admin privileges are required for the read-only queries. Some sections may show fewer results without elevated rights, but the capture still completes and records what it can see.

### Confirm Your Intent

- Whether this is the **pre-image** run (Phase 2C, before wiping) or the **post-image** run (Phase 13C, after re-enrollment) — this sets `--context` and the bundle prefix.
- That you want a full managed picture, not just your own app settings — those belong to Phase 2D and are captured separately.
- Whether you will compare this bundle against an earlier one; if so, keep the pre-image bundle so the post-image run has something to diff against (see [[#Pre-Image vs Post-Image Comparison|Pre-Image vs Post-Image Comparison]]).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order: confirm the environment, run the capture, then verify the bundle. The capture is one command; the surrounding steps make sure it landed where you expect.

### Step 1 — Prepare and Validate

Confirm the artifact root resolves and the destination volume is mounted. `capture-managed-inventory.sh` self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand:

```bash
./bin/capture-managed-inventory.sh --help
```

Confirm the destination has room if you have not already run the size audit for this artifact root:

```bash
./bin/report-size-audit.sh --context pre-image-managed-inventory
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Run the Capture

Run the full capture. For the pre-image run, the default context is correct, so no flag is needed:

```bash
./bin/capture-managed-inventory.sh
```

For the post-image run (Phase 13C, after the Mac is re-enrolled), set the context so the bundle is labelled distinctly:

```bash
./bin/capture-managed-inventory.sh --context post-image
```

To point at a different artifact root for one invocation, add `--artifact-root PATH`. To write to an exact directory, use `--output DIR` — that skips the run layout *and* the index, so nothing under `official/` will point at the result and no later phase will find it. Use it for a scratch capture you intend to read yourself, never for the Phase 2C or 13C evidence.

The script prints each section as it runs and finishes with the bundle path and its run id. It writes the seven section files and `MANIFEST.txt` under `managed-inventory/runs/<context>-<stamp>/`, then indexes the run and moves `official/<context>.txt` onto it.

The line `context 'pre-image' has no recognised point suffix; latest-wins applies` is expected. The shared run index reserves a small set of trailing words (`before`, `entry`, `exit`, and similar) that select a pointer rule; `pre-image` is not one of them, so the run gets the default rule — the latest completed capture of that context is the official one — which is what this category wants.

> [!note]
> Section 07 (the company-focused filter pass) is expected to be a subset of the earlier sections. Empty results there are normal on a lightly managed machine — it means none of the filtered vendor names matched, not that the capture failed.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Verify Outputs

Confirm the bundle landed, was indexed, and holds all seven sections plus the manifest. Resolve it through the pointer the rest of the workflow will use rather than by picking the newest directory — checking the same way the later phases read it is what proves those phases will find it:

```bash
CATEGORY="$REIMAGE_ARTIFACT_ROOT/managed-inventory"
CONTEXT="pre-image"   # post-image on the Phase 13C run
if [ -f "$CATEGORY/official/$CONTEXT.txt" ]; then
  OFFICIAL="$CATEGORY/$(cat "$CATEGORY/official/$CONTEXT.txt")"
  echo "$OFFICIAL"
  ls -1 "$OFFICIAL"
else
  printf 'ERROR: no official %s run — the capture was not indexed.\n' "$CONTEXT"
fi
```

You should see `01-` through `07-` and `MANIFEST.txt`. Spot-check the enrollment and profile sections, which carry the most decision-relevant evidence:

```bash
sed -n '1,40p' "$OFFICIAL/01-enrollment-status.txt"
sed -n '1,40p' "$OFFICIAL/02-profiles-configuration.txt"
```

The row this run added to the category index, which is what `backup-apps` and the Phase 8 record resolve through:

```bash
tail -3 "$REIMAGE_ARTIFACT_ROOT/managed-inventory/MANIFEST.md"
```

> [!bug] Troubleshooting
> If a section file is empty or thinner than expected, see [[#A section is empty or shows fewer results than expected|A section is empty or shows fewer results than expected]]. If the bundle holds fewer than seven section files, see [[#Fewer than seven section files in the bundle|Fewer than seven section files in the bundle]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script captures uniformly; interpreting what management owns is the judgment call.

| Decision | Why it stays with you |
|---|---|
| Which components are actually IT-owned vs personal? | The filter pass flags likely corporate tooling, but only you know which apps and agents you installed yourself. |
| Is a managed difference between pre- and post-image expected? | Re-enrollment legitimately changes some managed state; deciding whether a delta is normal or worth raising with IT is yours to make. |
| Do you need the post-image run at all? | If you are not verifying re-enrollment, the pre-image bundle alone may be enough — the Phase 13C run is for comparison. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Three things look like failures but usually are not. Each step that can hit one links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### A section is empty or shows fewer results than expected

Some queries return less without elevated rights, and a genuinely lightly-managed Mac will have empty sections (for example no third-party system extensions). An empty section file with its header intact means the command ran and found nothing — that is a valid result, not an error.

[[#Step 3 — Verify Outputs|⮕ Continue to Step 3 — Verify Outputs]]

---

### `profiles` reports nothing on an enrolled machine

`profiles status`/`profiles show` can be restricted by management on some configurations. Record what it returns; the package-receipt, app-bundle, and Managed Preferences sections still provide corroborating evidence of what is deployed.

[[#Step 3 — Verify Outputs|⮕ Continue to Step 3 — Verify Outputs]]

---

### Fewer than seven section files in the bundle

The run was interrupted before completing. Delete or ignore the partial bundle and rerun the capture — each run writes a fresh timestamped directory, so a rerun does not overwrite anything.

[[#Step 2 — Run the Capture|⮕ Continue to Step 2 — Run the Capture]]

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

**`03` — Installed app bundles.** The full list of apps present, without the slow `system_profiler` enumeration. In the script's output each line carries a managed verdict — and this is the single authoritative per-app call the Phase 2D candidate review reads for its managed partition, rather than deriving its own. A **strong** signal prints `[managed: …]`: a configuration profile (02), a managed preference (06), or the corporate-tooling filter (07). A receipt-only match prints `[likely: receipt]` — weak, because a package receipt means pkg-installed, which can be self-installed. Neither prints `[-]`. Bundle-identifier matches use the app's real `CFBundleIdentifier` (read via `PlistBuddy`) for precision. The list stays complete on purpose, so 03 remains the installed-apps baseline for pre-image/post-image comparison; the verdict is a heuristic hint, not proof (an MDM or App Store install may leave no receipt, so `[-]` does not prove an app is unmanaged). The raw, unannotated equivalent:

```bash
find /Applications /System/Applications "$HOME/Applications" -maxdepth 2 -name "*.app" -type d 2>/dev/null | sort
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

**`07` — Company-focused filter pass.** The earlier queries narrowed to likely corporate tooling across the managed fleet (Microsoft/Intune/Company Portal, CrowdStrike/Falcon, Zscaler, Defender, Checkpoint, Absolute, Proofpoint, Jamf, Flexera/ManageSoft). The script runs these directly — not through a login shell — so your shell profile's output (SDKMAN completions, etc.) can't leak into the capture, and it reuses the already-collected package receipts.

```bash
printf '%s\n' "$ALL_RECEIPTS" | grep -Ei 'microsoft|intune|companyportal|crowdstrike|falcon|zscaler|defender|wdav|checkpoint|absolute|proofpoint|jamf|flexera|managesoft'
find /Applications /System/Applications "$HOME/Applications" -maxdepth 2 -name "*.app" -type d 2>/dev/null | grep -Ei 'Company Portal|Microsoft|CrowdStrike|Falcon|Zscaler|Defender|Intune|VPN'
find /Library/LaunchAgents /Library/LaunchDaemons -maxdepth 1 -type f 2>/dev/null | grep -Ei 'microsoft|intune|companyportal|crowdstrike|falcon|zscaler|defender|wdav|checkpoint|absolute|proofpoint|jamf|flexera|managesoft'
systemextensionsctl list 2>/dev/null | grep -Ei 'microsoft|intune|companyportal|crowdstrike|falcon|zscaler|defender|wdav|checkpoint|absolute|proofpoint|jamf|flexera|managesoft'
```

### Interpretation Notes

Read each section for what it is best at: `profiles` for what MDM manages, `find /Applications` for what is installed, `pkgutil` for what installers deployed, LaunchAgents/Daemons plus `systemextensionsctl` for background managed and security components, and Managed Preferences for enforced settings. No single source is authoritative on its own — a component deployed by IT typically shows up across several sections at once (a package receipt, an app bundle, and a launch agent), and that overlap is what makes something confidently IT-owned.

The bundle is the evidence. Do not retype app, profile, package, agent, daemon, system-extension, or managed-preference details into a separate note — reference the section file instead. Add a short written comparison note only when a managed-state difference still needs explanation after reviewing the captured files.

### Pre-Image vs Post-Image Comparison

The pre-image bundle (Phase 2C) and the post-image bundle (Phase 13C) share the same seven-section shape, so they diff cleanly. After re-enrollment, compare matching section files to see what management restored, added, or dropped:

```bash
CATEGORY="$REIMAGE_ARTIFACT_ROOT/managed-inventory"
if [ -f "$CATEGORY/official/pre-image.txt" ] && [ -f "$CATEGORY/official/post-image.txt" ]; then
  PRE="$CATEGORY/$(cat "$CATEGORY/official/pre-image.txt")"
  POST="$CATEGORY/$(cat "$CATEGORY/official/post-image.txt")"
  diff "$PRE/04-installed-package-receipts.txt" "$POST/04-installed-package-receipts.txt"
  diff "$PRE/02-profiles-configuration.txt"    "$POST/02-profiles-configuration.txt"
else
  printf 'Both a pre-image and a post-image run must be official before they can be compared.\n'
fi
```

Timestamps and generation dates in the file headers will always differ; focus on the payload lines. Expect some legitimate churn from re-enrollment — the point is to surface anything unexpected, not to demand an identical match.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- the three routed Troubleshooting symptoms are deliberately absent from the
  Table of Contents — their inline `> [!bug]` callout is the only entry point,
  and each ends with a single Continue link to the step it resumes at;
- the Troubleshooting parent carries its Table-of-Contents back-link under the
  intro, above the first symptom;
- each remaining section ends with one "Back to Table of Contents" link
  followed by a `---` divider.
-->
