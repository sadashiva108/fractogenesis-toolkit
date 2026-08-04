---
title: Capture Office Stability
back_link: "reimaging-guide#Phase 3D — Office Stability Capture"
runbook_version: 0.1.0
verb_first: true
primary_scripts:
  - bin/capture-office-stability.sh
related_scripts:
  - bin/capture-workload-snapshot.sh
  - bin/office-stability-checklist.sh
  - bin/watch-office-today.sh
artifact_paths:
  - $REIMAGE_ARTIFACT_ROOT/office-stability/
author: Orah Kittrell
last_updated: 2026-08-04
---
[[reimaging-guide#Phase 3D — Office Stability Capture|← Back to Mac Reimaging Guide]]

# Capture Office Stability

Capture the evidence behind Outlook / OneNote instability when Office update churn or unexpected app closures are part of the reason this Mac is being reimaged. A continuous watcher logs the apps, their bundles, crash reports, and Microsoft update/management activity over days or weeks; a baseline collector then summarizes everything newer than a timestamp marker into a self-contained bundle. Run it pre-image (Phase 3D) to record the before picture, and again post-image (Phase 11E) to show whether the rebuilt Mac stayed stable.

> [!note]
> Renamed during migration from `capture-office-stability-audit.md` → `capture-office-stability.md` (verb-first, dropping the redundant "audit" suffix). Update any inbound links accordingly.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#Run Modes|Run Modes]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Bundle Layout|Bundle Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Prepare a Clean Test Window|Step 1 — Prepare a Clean Test Window]]
    - [[#Step 2 — Exercise Office and Snapshot the Workload|Step 2 — Exercise Office and Snapshot the Workload]]
    - [[#Step 3 — Run the Baseline Collector|Step 3 — Run the Baseline Collector]]
    - [[#Step 4 — Generate the Checklist Report|Step 4 — Generate the Checklist Report]]
    - [[#Step 5 — Verify Outputs|Step 5 — Verify Outputs]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
    - [[#Outlook or OneNote Closed Unexpectedly|Outlook or OneNote Closed Unexpectedly]]
    - [[#The Watcher Is Not Running|The Watcher Is Not Running]]
    - [[#No Crash Reports but Office Still Closed|No Crash Reports but Office Still Closed]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Per-Section Baseline Files|Per-Section Baseline Files]]
    - [[#Baseline and Incident Queries|Baseline and Incident Queries]]
    - [[#Interpreting the Evidence|Interpreting the Evidence]]
    - [[#Post-Image Run (Phase 11E)|Post-Image Run (Phase 11E)]]
    - [[#Suggested IT Ticket|Suggested IT Ticket]]
    - [[#Local Mitigations While Managed|Local Mitigations While Managed]]
    - [[#Final Pre-Reimage Checklist|Final Pre-Reimage Checklist]]
    - [[#Post-Image Office Stability Checklist Template|Post-Image Office Stability Checklist Template]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Preserve timestamped evidence that Outlook and OneNote close during managed Microsoft 365 / Office update, repair, replacement, or re-registration activity — often without generating a normal crash report — so the pattern is documented before the machine is wiped and can be re-checked after reimage. This is diagnostic evidence for IT and for the post-image comparison, not a backup you restore from.

This runbook owns:

```text
the Office stability capture (Outlook / OneNote) and its timestamped baseline bundles
the Office watcher and the bundle-watch-start.marker workflow
the pre-image (Phase 3D) and post-image (Phase 11E) Office comparison
the Office stability checklists (pre-image and post-image)
the full office-stability/ layout
```

It does not own:

```text
general system performance and workload evidence — capture-performance-audit.md (Phase 3C)
the managed-app footprint (Office as a managed install) — capture-managed-inventory.md (Phase 2C / 11C)
cross-phase readiness sign-off — reimage-prep-checks.md (Phase 4B)
the Office/Outlook/OneNote caches, containers, and profiles themselves — these are IT-owned managed data and are never deleted here
```

This capture can be rerun at any time: each baseline collector run writes a fresh timestamped bundle and leaves earlier runs untouched.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. No single command proves what is closing Outlook and OneNote, because the cause is spread across app bundles, crash reports, `install.log`, Microsoft AutoUpdate, and MDM/App Store activity. The workflow solves this in two layers: a long-running **watcher** that quietly records those signals over the days or weeks you actually use the machine, and a one-shot **baseline collector** that, at the end of a clean test window, gathers everything newer than a timestamp **marker** into a single reviewable bundle. You establish the marker at the start of a clean window, use Office normally, then run the collector — the marker is what lets it find only the evidence from this window.

The order in the steps is deliberate: start from a known-clean state (Office quit, no installer activity, no stale watcher) so a later bundle change is unambiguous, then layer the workload on in a fixed order (baseline snapshot → Outlook → OneNote → Docker last) so the watcher records clean process transitions.

The single most important behavioral rule: **if Outlook or OneNote closes unexpectedly, do not reopen it first.** Reopening while the Office bundle is mid-replacement is exactly what produces the misleading DYLD missing-framework crashes. Capture a workload snapshot and a fast baseline first — see [[#Outlook or OneNote Closed Unexpectedly|Outlook or OneNote Closed Unexpectedly]].

### Run Modes

There is one capture flow, run at two capture depths. The depth is the only thing that changes; the phase (`pre-reimage` / `post-reimage`) sets the bundle label, not the mechanics.

| Mode | When to use it | How |
|---|---|---|
| Full baseline | The normal end-of-window capture. | `./bin/capture-office-stability.sh --phase pre-reimage --backup-root "$REIMAGE_ARTIFACT_ROOT"` |
| Fast incident baseline | Immediately after an unexpected close, before reopening — skips the slow unified-log pull. | add `--skip-unified-log` |

### Terminology

| Term | Meaning |
|---|---|
| Watcher | The continuous logger (`watch-office-today.sh`) that writes bundle-watch logs to `$OFFICE_WATCH`. |
| Marker | `bundle-watch-start.marker` — a timestamp anchor. Crash/bundle/log checks report only items *newer than* the marker. |
| Baseline bundle | One timestamped `pre-reimage-office-baseline-*` (or `post-reimage-*`) directory plus its `.zip`, written by the collector. |
| Workload snapshot | A point-in-time capture of visible apps, processes, and Office bundle status (`capture-workload-snapshot.sh`). |
| Phase | The `--phase` value (`pre-reimage` / `post-reimage`) that prefixes the bundle name. |
| Incident | An unexpected Outlook/OneNote close during the test window. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

> [!note]
> None of the Office-stability scripts have been migrated into `bin/` yet. The `bin/` paths below are the reflowed target names; each is marked `TODO: not yet migrated to bin/`. Flag names are carried over from the reference-vault scripts and may be revisited once the scripts land — in particular `--backup-root` now takes `$REIMAGE_ARTIFACT_ROOT` and may be renamed to `--artifact-root`.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/capture-office-stability.sh    # entrypoint — TODO: not yet migrated to bin/ (baseline collector; runs every section in one pass)
```

Related scripts, alphabetical:

```text
$FRACTOGENESIS_HOME/bin/capture-workload-snapshot.sh   # entrypoint — TODO: not yet migrated to bin/ (point-in-time workload snapshot)
$FRACTOGENESIS_HOME/bin/office-stability-checklist.sh  # entrypoint — TODO: not yet migrated to bin/ (generates the sign-off checklist report)
$FRACTOGENESIS_HOME/bin/watch-office-today.sh          # entrypoint — TODO: not yet migrated to bin/ (long-running Office watcher)
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/office-stability/               # all generated Office evidence, bundles, and checklists land here
```

Local watcher directory (stays on the Mac; not on the backup volume):

```text
$OFFICE_WATCH/                                          # live watcher logs, workload snapshots, and bundle-watch-start.marker
```

### Bundle Layout

Each collector run writes one timestamped bundle; the `pre-reimage` / `post-reimage` prefix comes from `--phase`:

```text
$REIMAGE_ARTIFACT_ROOT/office-stability/
├── checklists/
│   └── ...
├── office-stability-summary-YYYYMMDD-HHMMSS.md
├── post-reimage-office-baseline-YYYYMMDD-HHMMSS/
│   └── ...
└── pre-reimage-office-baseline-YYYYMMDD-HHMMSS/
    ├── 00-baseline-window.txt
    ├── 01-crash-reports-newer-than-marker.txt
    ├── 02-office-bundle-status.txt
    ├── 03-outlook-onenote-process-transitions.txt
    ├── 04-watcher-installer-office-signals.txt
    ├── 05-install-log-office-events-tail.txt
    ├── 06-autoupdate-office-events-tail.txt
    ├── 07-unified-log-office-since-marker.txt
    ├── 08-watcher-running-status.txt
    └── office-stability-summary.md
```

The complete `$REIMAGE_ARTIFACT_ROOT/office-stability/` layout (baseline `.zip`s and the full `checklists/` subtree) is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the artifact root where `office-stability/` lives. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. |
| `OFFICE_WATCH` | Local Office watcher directory holding live watcher logs and `bundle-watch-start.marker`. |
| `REIMAGE_WORKSPACE_ROOT` | Optional local staging root for evidence gathered over days/weeks, before the backup volume is mounted. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what this run is for. The concepts and the *why* are in [[#How the Workflow Works|How the Workflow Works]]; this is just the checklist.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- You are on the affected company-managed Mac, and Office instability is genuinely part of this reimage's reason — otherwise skip this situational capture.
- `REIMAGE_ARTIFACT_ROOT` resolves and its volume is mounted (or `REIMAGE_WORKSPACE_ROOT` is set if you are staging evidence locally before the backup drive is attached).
- `OFFICE_WATCH` resolves and its directory exists, so the watcher and marker have a home.

> [!bug] Troubleshooting
> A missing `$OFFICE_WATCH` directory or missing marker will stop the collector — see [[#The Watcher Is Not Running|The Watcher Is Not Running]].

### Confirm Your Intent

- Which phase this is — **pre-image** (Phase 3D, before wiping) or **post-image** (Phase 11E, after re-enrollment). This sets `--phase` and the bundle prefix.
- Whether this is a scheduled **full baseline** or a **fast incident baseline** (`--skip-unified-log`) — see [[#Run Modes|Run Modes]].
- Whether you can reproduce the same Docker workload later; if pre/post comparison matters, record the exact containers now so the post-image run matches.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order: open a clean window, exercise Office while the watcher records, collect the baseline, generate the checklist, then verify. The watcher runs across the whole window; the collector is a single command at the end.

### Step 1 — Prepare a Clean Test Window

Start from a known-clean state so any later Office bundle change is unambiguous. Confirm Outlook and OneNote are fully quit (`Cmd+Q`, not backgrounded), Docker is not yet running, and no stale watcher is left over:

```bash
pgrep -fl "Microsoft Outlook|Microsoft OneNote" || echo "Outlook and OneNote are both closed"
pgrep -fl "Docker|com\.docker" || echo "Docker is not running"
pgrep -fl "watch-office-today\.sh|caffeinate .*watch-office-today" || echo "No watcher currently running"
```

Also confirm no installer/update/management activity is already in progress; if any is, let it finish first (the query is in [[#Baseline and Incident Queries|Baseline and Incident Queries]]).

Start the watcher for the window. `caffeinate` keeps the Mac awake so the log has fewer gaps; stop it later with `Control + C`:

```bash
caffeinate -dimsu ./bin/watch-office-today.sh
```

Set a fresh marker at the start of the clean window — everything newer than this is "this window's" evidence:

```bash
touch "$OFFICE_WATCH/bundle-watch-start.marker"
```

> [!warning] Pitfall
> Do not reset the marker after an incident until that incident's evidence is captured. The most common mistake is resetting it too late; resetting it too early erases the window you were trying to document. Reset it only when you deliberately want a new clean window.

### Step 2 — Exercise Office and Snapshot the Workload

Build the workload up in a fixed order so the watcher records clean transitions. Run a workload snapshot at each stage below — the command is the same every time, and it writes into `$OFFICE_WATCH`:

```bash
./bin/capture-workload-snapshot.sh
```

Stages, in order:

1. **Baseline** — Office still closed; snapshot the non-Office daily-driver apps you left running.
2. **Open Outlook**, let it run 30–60 minutes, then snapshot.
3. **Open OneNote**, let it sync, then snapshot.
4. **Start Docker last** — one representative day-to-day workload, then snapshot. Record the project/compose name and container count so the post-image run can match it.

> [!warning] Pitfall
> If Outlook or OneNote closes on its own at any point, **do not reopen it.** Reopening mid-replacement is what produces misleading DYLD crashes and destroys the evidence. Capture first — [[#Outlook or OneNote Closed Unexpectedly|Outlook or OneNote Closed Unexpectedly]].

### Step 3 — Run the Baseline Collector

At the end of the window, turn everything the watcher recorded into a structured, timestamped bundle and ZIP under `office-stability/`. The collector re-runs the marker-relative crash/bundle/process checks itself, so you do not need to have run them by hand:

```bash
./bin/capture-office-stability.sh --phase pre-reimage --backup-root "$REIMAGE_ARTIFACT_ROOT"
```

It writes the numbered section files `00`–`08` and `office-stability-summary.md` into the bundle (see [[#Bundle Layout|Bundle Layout]] for the tree and [[#Per-Section Baseline Files|Per-Section Baseline Files]] for what each file holds).

> [!note]
> If the unified-log pull is slow and you want a faster first pass, add `--skip-unified-log`; file `07-unified-log-office-since-marker.txt` then just records that it was skipped. This is the [[#Run Modes|fast incident baseline]] mode.

### Step 4 — Generate the Checklist Report

Turn the bundle into a readable sign-off report under `office-stability/checklists/`. Run this after the collector and before closing out the phase; `--open` opens the report when it finishes:

```bash
./bin/office-stability-checklist.sh --phase pre-reimage --backup-root "$REIMAGE_ARTIFACT_ROOT" --open
```

This is Office-specific and runs separately from the general Phase 4B checklist. Its findings roll up to the [[reimaging-guide#Core Assumptions|Phase 4B]] sign-off. The manual equivalents are in [[#Final Pre-Reimage Checklist|Final Pre-Reimage Checklist]].

### Step 5 — Verify Outputs

Confirm the bundle landed with all nine section files plus the summary:

```bash
LATEST="$(ls -dt "$REIMAGE_ARTIFACT_ROOT"/office-stability/pre-reimage-office-baseline-*/ | head -1)"
echo "$LATEST"
ls -1 "$LATEST"
```

You should see `00-` through `08-` and `office-stability-summary.md`. Spot-check the two most decision-relevant sections — crash reports and bundle status:

```bash
sed -n '1,40p' "$LATEST/01-crash-reports-newer-than-marker.txt"
sed -n '1,40p' "$LATEST/02-office-bundle-status.txt"
```

> [!warning] Pitfall
> An empty `01-crash-reports-newer-than-marker.txt` does not mean "nothing happened." Office frequently closes with no crash report at all — that absence is itself part of the evidence, so still check `02-office-bundle-status.txt` for bundles modified after the marker.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The scripts capture uniformly; interpreting the managed-update context is the judgment call.

| Decision | Why it stays with you |
|---|---|
| Is an Office bundle change after the marker expected? | Managed channels legitimately update Office; only you know whether a given change lines up with normal activity or is the disruptive pattern under investigation. |
| Is this ready to escalate to IT? | The evidence supports a ticket ([[#Suggested IT Ticket|Suggested IT Ticket]]), but whether the pattern is strong enough to raise now is yours to weigh. |
| Post-image: is the issue resolved, unchanged, or still open? | Some churn is normal after re-enrollment; deciding whether the post-image bundle shows the problem gone is a human comparison call. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### Outlook or OneNote Closed Unexpectedly

Do **not** reopen the app. Capture the live state first, because reopening mid-replacement destroys the evidence and can trigger a misleading DYLD crash.

Snapshot the current workload immediately:

```bash
./bin/capture-workload-snapshot.sh
```

Save a larger tail of the latest watcher log before anything else changes it:

```bash
latest="$(ls -t "$OFFICE_WATCH"/bundle-watch-*.log | head -1)"
tail -n 800 "$latest" > "$OFFICE_WATCH/latest-watcher-after-close-$(date +%Y%m%d-%H%M%S).txt"
```

Check for crash reports newer than the marker (their absence is meaningful — see [[#No Crash Reports but Office Still Closed|No Crash Reports but Office Still Closed]]):

```bash
find "$HOME/Library/Logs/DiagnosticReports" "/Library/Logs/DiagnosticReports" \
  -maxdepth 1 -type f -newer "$OFFICE_WATCH/bundle-watch-start.marker" \
  \( -iname "*Outlook*.ips" -o -iname "*Outlook*.crash" \
     -o -iname "*OneNote*.ips" -o -iname "*OneNote*.crash" \) \
  -print 2>/dev/null | sort
```

Then run the fast incident baseline to snapshot everything before reopening:

```bash
./bin/capture-office-stability.sh --phase pre-reimage --backup-root "$REIMAGE_ARTIFACT_ROOT" --skip-unified-log
```

### The Watcher Is Not Running

If the collector reports a missing watcher directory or marker, or you are unsure the watcher is live, check for the process and the newest log:

```bash
pgrep -fl "watch-office-today\.sh|caffeinate .*watch-office-today" || echo "Office watcher is not currently running"
ls -lt "$OFFICE_WATCH"/bundle-watch-*.log 2>/dev/null | head -5 || echo "No watcher logs found"
```

If no process and no recent log exists, start the watcher and set a fresh marker (Step 1) before opening Outlook or OneNote — a bundle collected without a covering watcher log will be missing the process-transition and signal sections.

### No Crash Reports but Office Still Closed

This is the expected pattern, not a failure. Office closing with no `.ips`/`.crash` file points to a forced close, clean termination, or app-bundle replacement during a managed update — not a resource crash. Do not conclude "nothing happened": check `02-office-bundle-status.txt` for bundles modified after the marker and the AutoUpdate / install.log tails (`05`, `06`) for the update window. Interpretation cues are in [[#Interpreting the Evidence|Interpreting the Evidence]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Per-Section Baseline Files

What the collector writes into each baseline bundle:

| File | What it captures |
|---|---|
| `00-baseline-window.txt` | Phase label, marker timestamp, and the start/end window for this run. |
| `01-crash-reports-newer-than-marker.txt` | Outlook/OneNote `.ips`/`.crash` files newer than the marker. |
| `02-office-bundle-status.txt` | Office app bundle versions and modified dates, flagged if changed after the marker. |
| `03-outlook-onenote-process-transitions.txt` | Outlook/OneNote process start/stop transitions from the latest watcher log. |
| `04-watcher-installer-office-signals.txt` | Installer/updater/management signals from the latest watcher log. |
| `05-install-log-office-events-tail.txt` | Recent `/var/log/install.log` Office-related events. |
| `06-autoupdate-office-events-tail.txt` | Recent Microsoft AutoUpdate log events. |
| `07-unified-log-office-since-marker.txt` | Unified-log pull since the marker, scoped to Office/installer/MDM signals (or "skipped" with `--skip-unified-log`). |
| `08-watcher-running-status.txt` | Whether the watcher is currently running. |
| `office-stability-summary.md` | Review-order summary and interpretation hints; also copied to the top-level `office-stability-summary-YYYYMMDD-HHMMSS.md`. |

### Baseline and Incident Queries

The collector runs every check below automatically. Use these standalone only to isolate one check — for example while triaging live, or to zero in on a narrower window than "since the marker."

Check for installer / update / management activity:

```bash
ps -axo pid,ppid,etime,stat,%cpu,%mem,command \
  | egrep '(^|/)(installd|system_installd|appstored|appstoreagent)( |$)|Microsoft AutoUpdate|Microsoft Update Assistant|com\.microsoft\.autoupdate|Company Portal|Intune|ManagedClient|mdmclient|jamf|Self Service' \
  | grep -v egrep || echo "No installer/update/management processes found"
```

Check whether any Office bundle changed after the marker:

```bash
MARKER="$OFFICE_WATCH/bundle-watch-start.marker"
for app in "Microsoft Outlook" "Microsoft OneNote" "Microsoft Word" "Microsoft Excel" "Microsoft PowerPoint" "Microsoft Teams"; do
  APP="/Applications/$app.app"
  echo; echo "===== $app ====="
  if [[ -d "$APP" ]]; then
    [[ "$APP" -nt "$MARKER" ]] && echo "CHANGED_AFTER_MARKER: YES" || echo "CHANGED_AFTER_MARKER: NO"
    /usr/bin/stat -f "modified=%Sm path=%N" -t "%Y-%m-%d %H:%M:%S" "$APP"
    /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || true
  else
    echo "MISSING: $APP"
  fi
done
```

Focused unified-log pull for a known incident window (adjust `--start`/`--end`):

```bash
log show --style compact \
  --start "2026-05-29 16:10:00" --end "2026-05-29 16:30:00" \
  --predicate 'process == "installd" OR process == "system_installd" OR process == "appstored" OR process == "appstoreagent" OR process CONTAINS[c] "Intune" OR process CONTAINS[c] "mdmclient" OR process CONTAINS[c] "Microsoft AutoUpdate" OR eventMessage CONTAINS[c] "Office" OR eventMessage CONTAINS[c] "Outlook" OR eventMessage CONTAINS[c] "OneNote" OR eventMessage CONTAINS[c] "forcibly closing"' \
  > "$OFFICE_WATCH/unified-log-office-$(date +%Y%m%d-%H%M).txt" 2>&1
```

Focused `install.log` pull for the same window:

```bash
awk '$0 >= "2026-05-29 16:10" && $0 <= "2026-05-29 16:30"' /var/log/install.log \
  | grep -Ei "Microsoft|Office|Outlook|OneNote|AutoUpdate|forcibly closing|preinstall|postinstall|Installed|Touched bundle|Registered bundle" \
  > "$OFFICE_WATCH/install-log-office-$(date +%Y%m%d-%H%M).txt"
```

### Interpreting the Evidence

No single section is authoritative alone; a managed Office event typically shows up across several at once (a bundle change, an AutoUpdate entry, and an installer process in the same window).

| Result / Evidence | Meaning |
|---|---|
| No crash report after Outlook/OneNote disappear | Likely forced close, clean termination, update, or app replacement — not a resource crash. |
| Outlook/OneNote bundle missing or framework missing | Transient app-bundle replacement while an installer/update runs. |
| Outlook, OneNote, Word, Excel, PowerPoint modified at the same timestamp | Strong evidence of an Office suite update / replacement / re-registration. |
| Teams unchanged while core Office apps changed | Points to a Microsoft 365 Office suite update, not all Microsoft apps. |
| New `.ips`/`.crash` with DYLD missing-framework errors | App likely launched while its bundle was incomplete during replacement. |
| AutoUpdate log mentions preinstall / "forcibly closing" | Strong evidence apps were closed by the update/install process. |
| `installd` / `appstored` / Intune / mdmclient active in the window | Confirms update/management context was present (context, not proof of causality). |

### Post-Image Run (Phase 11E)

The post-image window repeats every step above; only two things change:

1. **When you reset the marker** — wait until Office has finished installing from the approved managed channel and appears settled, then set a fresh marker. Do not manually install Office from another channel unless IT instructs it.
2. **The `--phase` value** — use `post-reimage` in Step 3 and Step 4.

For Docker, start the **same workload** you recorded pre-image so the two captures stay comparable; if you cannot, record that explicitly rather than silently comparing different loads. Then compare matching sections between the pre- and post-image bundles (app versions, bundle modified dates, process transitions, crash reports, AutoUpdate/Intune/PackageKit activity, and whether the same build is repeatedly reapplied).

### Suggested IT Ticket

Subject:

```text
MacBook Pro: Outlook and OneNote repeatedly closing during Microsoft 365 update/install activity
```

Key points to include: Outlook/OneNote closing repeatedly, often with no crash report; earlier DYLD launch failures naming Microsoft frameworks (e.g. `HxPlorer.framework`, `CocoaUI.framework`) that existed and validated shortly after; unified logs showing Office package preinstall activity in the same window as OneNote/Outlook quit events; core Office apps touched together on the same build; `appstored`, `installd`, Microsoft AutoUpdate, Company Portal, Intune, and `mdmclient` present during investigation. Ask IT which system initiates the installs, whether more than one update channel is active, whether forced updates run during business hours while apps are open, whether the same build is reapplied, and whether Office can be reinstalled cleanly from one approved channel.

### Local Mitigations While Managed

Mitigation is limited on a managed Mac, but useful temporary steps: avoid reopening Outlook/OneNote immediately after a close; check for active installer/update processes first and wait for them to finish; capture a workload snapshot before reopening; reboot after Office updates if the bundle was modified or a DYLD crash occurred; use browser-based Outlook/OneNote temporarily if the desktop apps keep closing.

> [!warning] Pitfall
> Do **not** delete Outlook/OneNote profiles or caches (`~/Library/Group Containers/UBF8T346G9.Office`, `~/Library/Containers/com.microsoft.Outlook`, `~/Library/Containers/com.microsoft.onenote.mac`). The evidence points to managed app-bundle/update behavior, not profile corruption, and this managed data is IT-owned — deleting it is out of scope for this workflow.

### Final Pre-Reimage Checklist

The generated report from `office-stability-checklist.sh --phase pre-reimage` (Step 4) is the preferred sign-off. This is the human-readable equivalent when you are tracking it by hand:

```text
[ ] Watcher ran with an early marker before reimage
[ ] Marker timestamp confirmed
[ ] Baseline workload snapshot captured
[ ] Installer/update activity checked before opening Office during the window
[ ] Crash reports after marker checked
[ ] Office bundle status after marker captured
[ ] Outlook/OneNote process transitions extracted
[ ] Latest watcher tail saved after any unexpected closure
[ ] install.log / AutoUpdate / unified-log evidence captured around any Office bundle change
[ ] Pre-image Office stability evidence present under $REIMAGE_ARTIFACT_ROOT/office-stability/
[ ] Evidence ZIP created
[ ] External drive holds evidence outputs and summaries only (no active scripts)
[ ] Pre-image Office stability conclusion recorded in work log
```

### Post-Image Office Stability Checklist Template

Use this after reimage when Outlook/OneNote stability still needs verifying. The generated report from `office-stability-checklist.sh --phase post-reimage` is preferred; this is the compact manual comparison template:

```text
Post-Image Office Stability Sign-Off — YYYY-MM-DD

Setup state:
  [ ] Initial Intune / Company Portal setup complete
  [ ] Office installed from the approved managed channel only
  [ ] AutoUpdate / Intune / Company Portal install activity appears settled
  [ ] Fresh watcher marker set after Office installation settled

Watcher and evidence:
  [ ] Watcher started from the bin/ script path
  [ ] Marker timestamp confirmed
  [ ] Baseline workload snapshot captured before opening Outlook/OneNote
  [ ] Outlook and OneNote opened and observed
  [ ] Docker started last (same workload as pre-image, if used)
  [ ] Post-reimage baseline captured with capture-office-stability.sh --phase post-reimage

Comparison to pre-image:
  [ ] Office app versions compared
  [ ] Office bundle modified dates compared
  [ ] Crash reports after marker checked
  [ ] Outlook/OneNote process transitions reviewed
  [ ] AutoUpdate / Intune / PackageKit activity reviewed
  [ ] Confirmed whether the same Office build was reapplied

Conclusion:
  [ ] Outlook and OneNote remain open during normal use
  [ ] No unexplained Office bundle replacement after the marker
  [ ] If the issue recurred, an evidence bundle is ready for IT

Completed by: TODO
Date: YYYY-MM-DD
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link.
- anchors #final-pre-reimage-checklist and #post-image-office-stability-checklist-template
  are preserved for inbound links from reimaging-guide.md (Phase 3D / Phase 11E).
-->
