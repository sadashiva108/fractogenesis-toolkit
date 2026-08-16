[[reimaging-guide#Phase 8 — Enroll and Stabilize|← Back to Mac Reimaging Guide]]

# Enroll and Stabilize

**Last updated:** 2026-08-04

Bring the freshly reimaged Mac to a clean, trusted managed baseline before any restore work begins. This phase covers the human-driven work — completing MDM enrollment, letting required managed apps and security tools install, applying required macOS updates, taking the first stabilization restart, and reconfirming afterward — and pairs it with `record-enrollment.sh`, which records read-only command evidence for each managed subsystem and prefills the Phase 8 exit-criteria table for the command-verifiable rows.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#What Gets Recorded|What Gets Recorded]]
    - [[#Command-Verifiable vs Mixed vs Manual Rows|Command-Verifiable vs Mixed vs Manual Rows]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Record Bundle Layout|Record Bundle Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Complete Managed Enrollment|Step 1 — Complete Managed Enrollment]]
    - [[#Step 2 — Wait for Required Managed Apps and Security Tools|Step 2 — Wait for Required Managed Apps and Security Tools]]
    - [[#Step 3 — Apply Required macOS Updates|Step 3 — Apply Required macOS Updates]]
    - [[#Step 4 — Record the Pre-Restart Baseline|Step 4 — Record the Pre-Restart Baseline]]
    - [[#Step 5 — Take the First Stabilization Restart|Step 5 — Take the First Stabilization Restart]]
    - [[#Step 6 — Record the Post-Restart Baseline|Step 6 — Record the Post-Restart Baseline]]
    - [[#Step 7 — Close Out the Exit Criteria|Step 7 — Close Out the Exit Criteria]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Per-Section Command Reference|Per-Section Command Reference]]
    - [[#Output Location Fallback Chain|Output Location Fallback Chain]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Establish a clean, managed, and stable macOS baseline before restoring runtime tools, access material, repositories, apps, or local files, and leave behind a timestamped record of the evidence that supports each Phase 8 exit-criteria row. The record is diagnostic evidence, not a backup you restore from — nothing here re-applies to the machine.

This runbook owns:

```text
Phase 8 managed-baseline enrollment, stabilization, and evidence recording
the record-enrollment.sh run and its timestamped bundle
the Phase 8 exit-criteria table and its sign-off
```

It does not own:

```text
the encrypted secrets DMG or any restore of secrets — Phase 10B (restore-access)
runtime tooling restore (Xcode CLT, Homebrew, Java, Node) — Phase 10A (restore-runtime)
the first post-enrollment usability sanity check — Phase 9 (verify-reimaged-system)
company-managed inventory comparison across pre-image and post-image — capture-managed-inventory.md (Phases 2C / 13C)
```

This runbook can be rerun. Each run writes a fresh timestamped bundle and leaves earlier runs untouched, so an early pre-restart record and a later post-restart record can coexist and be compared.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The phase is mixed by design: some rows in the exit-criteria table are things a shell command can prove, some are things a shell command can only hint at, and some can only be confirmed by looking at the UI or by watching a restart happen. `record-enrollment.sh` runs one read-only command per managed subsystem, writes each result to a numbered raw file, applies a small set of heuristic PASS/WARN verdicts on the rows it can meaningfully judge, and leaves the truly human-judgment rows as `TODO`. You close those out after the UI review and the first stabilization restart.

The preferred path is script-first: run the script once before the restart to capture the pre-restart baseline, take the restart, then run it again afterward to capture the post-restart baseline. The same commands appear individually in [[#Per-Section Command Reference|Per-Section Command Reference]] for the rare case where you need to rerun or troubleshoot a single subsystem — use the script for the standard run, the individual commands only when isolating one section.

### What Gets Recorded

One numbered file per managed subsystem, plus a Markdown record with the exit-criteria table prefilled and a small manifest:

```text
01  MDM enrollment status              profiles status -type enrollment
02  configuration profiles list        profiles list
03  FileVault status                   fdesetup status
04  managed applications present       /Applications name-filter for expected managed apps
05  managed processes present          ps aux name-filter for expected managed agents
06  macOS version and build            sw_vers
07  available software updates         softwareupdate --list
```

Every command reads state; nothing writes to managed state. You can run this on a live managed machine without risk to compliance.

### Command-Verifiable vs Mixed vs Manual Rows

The Phase 8 exit-criteria table groups checks by how they can be proven. The script only prefills rows in the first two groups:

| Row group | What the script does | What you do |
|---|---|---|
| Command-verifiable / Mixed | Records the raw command output and stamps `PASS`/`WARN` based on a small heuristic. | Review the raw file, decide whether `WARN` is expected on this Mac, and finalize the row. |
| Manual-only | Nothing. The row is left as `TODO`. | Watch the UI, watch the restart, and fill the row in by hand. |

`WARN` is not the same as `FAIL`: it means the recorded evidence did not obviously match the expected pattern and needs a human look before the row is signed off (for example, `softwareupdate --list` still shows offered updates, or `profiles list` was empty at the moment of the run because policy was still landing).

### Terminology

| Term | Meaning |
|---|---|
| Managed baseline | The enrolled, profile-controlled, security-tooled state IT expects on a compliant Mac after Phase 8. |
| Configuration profile | A `.mobileconfig` payload pushed by MDM to enforce settings; listed by `profiles list`. |
| Stabilization restart | The first reboot taken after enrollment and required tool install, before restore work begins. |
| Pre-restart record | The Phase 8 record captured before the stabilization restart. |
| Post-restart record | The Phase 8 record captured after the stabilization restart; used as the sign-off record. |
| Record bundle | One timestamped run directory holding the seven raw files, `enrollment-record.md`, and `MANIFEST.txt`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/record-enrollment.sh    # entrypoint — records Phase 8 evidence and prefills the exit-criteria table
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/enrollment/    # all Phase 8 record bundles land here
```

### Record Bundle Layout

Each run writes one timestamped bundle plus a `latest-enrollment-record.txt` pointer at the parent level:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/enrollment/
├── latest-enrollment-record.txt
└── record-enrollment-YYYYMMDD-HHMMSS/
    ├── enrollment-record.md
    ├── MANIFEST.txt
    └── raw/
        ├── 01-enrollment-status.txt
        ├── 02-profiles-list.txt
        ├── 03-filevault-status.txt
        ├── 04-managed-apps.txt
        ├── 05-managed-processes.txt
        ├── 06-macos-version.txt
        └── 07-softwareupdate-list.txt
```

The complete `$REIMAGE_ARTIFACT_ROOT/reimaged-system/` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

When the artifact volume is not yet mounted, the script falls back to a workspace path and then a Desktop path. That fallback chain is documented in [[#Output Location Fallback Chain|Output Location Fallback Chain]].

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`; on a freshly reimaged Mac the artifact root may not be mounted yet, and the script's fallback chain handles that case.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the artifact root where `reimaged-system/enrollment/` lives. Optional here — the script falls back if it is unset or unmounted. |
| `REIMAGE_WORKSPACE_ROOT` | Absolute path to a local workspace used as the intermediate fallback when the artifact root is not available. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what this run is for. The concepts and the *why* are in [[#How the Workflow Works|How the Workflow Works]]; this is just the checklist.

### Prerequisites

- The reimage/erase in [[reimaging-guide#Phase 7 — Reimage / Erase Procedure|Phase 7]] is complete and the Mac has restarted into Setup Assistant or the first login session.
- You have signed into the company Microsoft 365 / O365 account when prompted and network (Wi-Fi or Ethernet) is connected.
- The toolkit is present on the Mac. If not, install it first via the bootstrap step in the [[reimaging-guide#Phase 8 — Enroll and Stabilize|Phase 8 bootstrap callout]] (`curl` primary, jump drive fallback).
- You are running commands from `$FRACTOGENESIS_HOME`.

> [!note]
> `REIMAGE_ARTIFACT_ROOT` and the external artifact volume are *not* required at this point. `record-enrollment.sh` falls back to `$REIMAGE_WORKSPACE_ROOT/enrollment/` and then to `~/Desktop/reimaged-system-artifacts/enrollment/` so Phase 8 can complete before the external drive is reconnected in Phase 9.

> [!bug] Troubleshooting
> If the script errors with "shared config loader not found", the toolkit was placed in the wrong location or is a partial extract — re-run bootstrap and confirm `$FRACTOGENESIS_HOME/.internal/load-reimage-config.sh` exists before continuing.

### Confirm Your Intent

- Whether this is the **pre-restart** run (Step 4, before the stabilization restart) or the **post-restart** run (Step 6, the sign-off record). Both use the same command; the difference is which record you cite when closing out the exit criteria.
- Where the record should land. Default is the artifact root when it is mounted, otherwise the workspace, otherwise `~/Desktop/reimaged-system-artifacts/`. Pass `--output DIR` to force a specific path.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The human-driven steps (enrollment, tool install, updates, the restart) come first; the script runs are the evidence that proves each step landed. The pre-restart record in Step 4 is the "everything installed and updates applied" snapshot, and the post-restart record in Step 6 is the sign-off snapshot that proves the baseline survived the reboot.

### Step 1 — Complete Managed Enrollment

Complete the managed enrollment flow driven by the OS and Company Portal:

1. Restart the Mac if it has not already restarted after Phase 7.
2. Connect to Wi-Fi or Ethernet.
3. Sign in with the company Microsoft 365 / O365 account when prompted.
4. Confirm Intune / MDM enrollment starts and let the required profiles and base software begin installing.

Expected managed components arriving in this step:

```text
Intune enrollment
required management profiles
CrowdStrike
Zscaler
Microsoft Office
other base software assigned by company policy
```

> [!warning] Pitfall
> Do not manually install Office or security tooling from a separate channel unless IT explicitly asks. Duplicate installs can conflict with the managed copy that policy is about to push.

### Step 2 — Wait for Required Managed Apps and Security Tools

Before doing any restore work, confirm the managed baseline is settling: Company Portal opens without obvious errors, the device appears in the expected state, and the managed app set looks normal for current company policy. This is a human check against the UI — the script will record supporting shell evidence in Step 4.

> [!warning] Pitfall
> Do not remove profiles, disable security software, or change management settings while waiting for installs to complete, even to work around a slow rollout. IT owns that state.

### Step 3 — Apply Required macOS Updates

If IT policy, Company Portal, or System Settings requires macOS updates before restore work, complete them here.

1. Apply the required macOS updates using the approved path.
2. Allow any required reboot to complete.
3. Return to this runbook before doing restore work.

If a policy-required reboot happens here, it may satisfy the stabilization restart in Step 5. In that case, still run Step 4 (pre-restart record) beforehand so the "before restart" evidence exists, then treat Step 5 as already-taken and continue to Step 6.

### Step 4 — Record the Pre-Restart Baseline

Record the evidence that Steps 1–3 landed as expected. Preview the script's options first so you know which fallback path it will pick:

```bash
./bin/record-enrollment.sh --help
```

Run the record. The default output location follows the fallback chain described in [[#Output Location Fallback Chain|Output Location Fallback Chain]]:

```bash
./bin/record-enrollment.sh
```

If the external artifact volume is already reconnected, force the record onto it explicitly:

```bash
./bin/record-enrollment.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT"
```

The script prints each subsystem as it runs, writes the seven `raw/NN-*.txt` files, generates `enrollment-record.md` with the exit-criteria table prefilled, writes `MANIFEST.txt`, and updates `latest-enrollment-record.txt` at the parent level.

> [!note]
> `WARN` on a row does not mean failure. Review the raw file for context — a `WARN` on `Required macOS updates are complete or intentionally deferred` while updates are still pending is expected before Step 3 finishes.

### Step 5 — Take the First Stabilization Restart

Restart the Mac to confirm the managed baseline survives a reboot.

Before restarting, confirm:

```text
required managed installs are not obviously in a broken state
any required update-triggered restart is already done or in motion
you are ready to validate the same baseline again after login
```

After the restart:

1. Sign back in.
2. Reconnect network if needed.
3. Continue directly to Step 6.

### Step 6 — Record the Post-Restart Baseline

Rerun the record after the restart. This is the sign-off record: it is the one you cite when closing out the exit criteria in Step 7.

```bash
./bin/record-enrollment.sh
```

Each run writes a fresh timestamped bundle, so the pre-restart record from Step 4 is left in place for comparison.

Confirm manually that:

```text
Company Portal still opens and looks normal
required security tools appear to have survived reboot cleanly
there is no obvious loss of enrollment, profiles, or base managed apps
```

> [!bug] Troubleshooting
> If a key item disappeared after the restart (missing profiles, missing security tool, enrollment reporting unenrolled), stop and resolve that with IT before moving on. Do not begin restore work on a broken managed baseline.

### Step 7 — Close Out the Exit Criteria

Open the post-restart `enrollment-record.md` and finish the table by filling the `TODO` rows with your observations:

```bash
LATEST_RECORD="$(cat "$REIMAGE_ARTIFACT_ROOT/reimaged-system/enrollment/latest-enrollment-record.txt" 2>/dev/null \
  || find "$HOME/Desktop/reimaged-system-artifacts/enrollment" -name enrollment-record.md -maxdepth 3 | sort | tail -1)"
echo "$LATEST_RECORD"
```

Confirm every row is effectively `yes` before proceeding to [[reimaging-guide#Phase 9 — Initial Captures and Sanity Checks|Phase 9]]:

| Check | Verification mode | How to verify |
|---|---|---|
| Enrollment completed or clearly stabilized | Mixed | `profiles status -type enrollment` plus expected company state |
| Required profiles/certificates appear | Mixed | `profiles list` plus expected profile/cert presence |
| Required security tools are installed or actively installing | Mixed | managed app/process checks plus visual sanity review |
| Company Portal opens and shows expected state | Manual | open Company Portal and review the device state |
| Required macOS updates are complete or intentionally deferred | Mixed | `sw_vers`, `softwareupdate --list`, and policy/UI review |
| First stabilization restart completed | Manual | observed restart and successful return to login/session |
| Post-restart baseline still looks healthy | Mixed | rerun the Step 4 commands and confirm no obvious regressions |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script records uniformly and applies fixed heuristics; interpreting the managed state itself is the judgment call.

| Decision | Why it stays with you |
|---|---|
| Whether a `WARN` row is actually acceptable on this Mac. | Policy varies (deferred updates, staged security-tool rollouts, in-flight profile pushes); only you can weigh the raw evidence against what IT expects right now. |
| Whether an update-triggered restart satisfies the Step 5 stabilization restart. | If updates required their own reboot, deciding whether to count it as the stabilization restart or take another is yours to make. |
| Whether a missing managed component means "wait longer" or "escalate to IT". | Rollouts are asynchronous; the script cannot tell in-progress from stalled. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### Enrollment row is `WARN` even though the Mac is clearly enrolled

`profiles status -type enrollment` phrasing has changed across macOS versions; the heuristic looks for `enrolled|yes|mdm`. Open `raw/01-enrollment-status.txt` and read the actual line — if it reports MDM enrollment in different wording, mark the row `PASS` by hand and note the wording.

### Profiles list is empty right after enrollment

Profile push is asynchronous. Wait a few minutes and rerun `./bin/record-enrollment.sh`. If it stays empty for more than roughly 10–15 minutes on a network-connected machine, check Company Portal for a pending enrollment issue before escalating.

### Security tools row is `WARN`

Confirm the app or process name in `raw/04-managed-apps.txt` / `raw/05-managed-processes.txt`. CrowdStrike ships as `Falcon.app`, and the heuristic looks for both names — but a vendor rename or a staged rollout can miss the pattern. Rerun after the install finishes; if the tool is genuinely absent and policy expects it, escalate.

### The record landed on the Desktop instead of the artifact root

That is the intended final fallback when neither `REIMAGE_ARTIFACT_ROOT` nor `REIMAGE_WORKSPACE_ROOT` resolves to a mounted directory. Once the external artifact volume is reconnected in Phase 9, either move the bundle into `reimaged-system/enrollment/` or rerun the script with `--artifact-root "$REIMAGE_ARTIFACT_ROOT"` so the sign-off record lives with the other Phase 8+ evidence.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Per-Section Command Reference

Use these only when you need to rerun or troubleshoot a single subsystem outside the script. Do not duplicate evidence the script already recorded successfully — the script and this reference cover the same commands.

Enrollment status:

```bash
profiles status -type enrollment 2>/dev/null || true
```

Installed configuration profiles:

```bash
profiles list 2>/dev/null || true
```

FileVault status:

```bash
fdesetup status
```

Expected managed applications present under `/Applications`:

```bash
ls -1 /Applications | grep -Ei 'Company Portal|CrowdStrike|Falcon|Zscaler|Microsoft|Teams|Outlook|OneNote' || true
```

Expected managed processes running:

```bash
ps aux | grep -Ei 'Intune|Company Portal|CrowdStrike|falcon|Zscaler|Microsoft AutoUpdate|MAU|mdmclient' | grep -v grep || true
```

Current macOS version and build:

```bash
sw_vers
```

Available software updates:

```bash
softwareupdate --list 2>/dev/null || true
```

### Output Location Fallback Chain

`record-enrollment.sh` picks its output directory in this order when `--output` is not supplied. The chain exists because Phase 8 typically runs before the external artifact volume is reconnected.

| Order | Condition | Path |
|---|---|---|
| 1 | `REIMAGE_ARTIFACT_ROOT` set and directory exists | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/enrollment/record-enrollment-YYYYMMDD-HHMMSS/` |
| 2 | Artifact root unavailable, `REIMAGE_WORKSPACE_ROOT` set and directory exists | `$REIMAGE_WORKSPACE_ROOT/enrollment/record-enrollment-YYYYMMDD-HHMMSS/` |
| 3 | Neither of the above | `~/Desktop/reimaged-system-artifacts/enrollment/record-enrollment-YYYYMMDD-HHMMSS/` |

The script refuses to write output under the toolkit repo checkout as a safety invariant — a record landing inside the working tree almost always signals an unset or relative root variable, not a real destination.

[[#Table of Contents|⬆ Back to Table of Contents]]

---
