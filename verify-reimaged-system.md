[[reimaging-guide#Phase 7 — Initial Captures and Sanity Checks|← Back to Mac Reimaging Guide]]

# Verify Reimaged System

**Last updated:** 2026-08-04

Reconnect the external artifact drive, prove the freshly reimaged Mac is basically usable, and record the first-boot evidence twice around a stabilization restart before deeper restore work begins. This phase pairs the human-driven day-one checks — network, browser, terminal, displays, peripherals, audio — with `record-reimaged-system.sh`, which recorded the same 14 read-only signals into two comparable evidence bundles, and closes with the first post-image Time Machine backup so the machine has a safety net before Phase 8 begins.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#What Gets Recorded|What Gets Recorded]]
    - [[#Two Runs Around One Restart|Two Runs Around One Restart]]
    - [[#Automated vs Manual Rows|Automated vs Manual Rows]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Bundle Layout|Bundle Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Reconnect the External Artifact Drive|Step 1 — Reconnect the External Artifact Drive]]
    - [[#Step 2 — Record the Pre-Restart First-Boot Bundle|Step 2 — Record the Pre-Restart First-Boot Bundle]]
    - [[#Step 3 — Review Manual First-Boot Areas|Step 3 — Review Manual First-Boot Areas]]
    - [[#Step 4 — Take the Second Stabilization Restart|Step 4 — Take the Second Stabilization Restart]]
    - [[#Step 5 — Record the Post-Restart First-Boot Bundle|Step 5 — Record the Post-Restart First-Boot Bundle]]
    - [[#Step 6 — Compare the Two Bundles|Step 6 — Compare the Two Bundles]]
    - [[#Step 7 — Take the First Post-Image Time Machine Backup|Step 7 — Take the First Post-Image Time Machine Backup]]
    - [[#Step 8 — Close Out the Exit Criteria|Step 8 — Close Out the Exit Criteria]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Companion Documents in the Bundle|Companion Documents in the Bundle]]
    - [[#Manual Review Focus|Manual Review Focus]]
    - [[#Output Location Fallback|Output Location Fallback]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Confirm that the rebuilt Mac is basically usable after Phase 6 — enrolled, connected, with browser, network, terminal, displays, and peripherals in working shape — and leave behind two timestamped first-boot evidence bundles that prove the managed baseline survived the second restart. Close the phase with the first post-image Time Machine backup so a fallback exists before restore work begins.

This runbook owns:

```text
external-artifact-drive reconnection and the sanity check that follows it
the two first-boot evidence bundles and the pre/post-restart comparison
the second stabilization restart and its exit criteria
the first post-image Time Machine backup timing
the reimaged-system/ subfolders used by later phases (restore-notes, restarts, time-machine)
```

It does not own:

```text
managed enrollment and the first stabilization restart — enroll-and-stabilize.md (Phase 6)
runtime tooling restore (Xcode CLT, Homebrew, Java, Node) — Phase 8A (restore-runtime)
access material and secrets restore — Phase 8B (restore-access)
post-image managed-inventory comparison — capture-managed-inventory.md (Phase 11C)
final validated sign-off — reimaged-system-checks.md (Phase 12)
```

This runbook can be rerun. Each run of `record-reimaged-system.sh` writes a fresh timestamped bundle and updates the `latest-initial-reimaged-system-bundle.txt` pointer, so a later run does not overwrite the pre-restart bundle you use for comparison.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Phase 6 established the managed baseline; Phase 7 asks the different question, "Is the Mac actually usable?" — a question no single command can answer. The runbook interleaves human checks (browser, terminal, displays, peripherals) with two runs of the same script, and uses the pair of resulting bundles to decide whether anything regressed across the second restart. Only after the pair looks clean does the first post-image Time Machine backup happen — a Time Machine snapshot of a broken baseline is worse than none.

The preferred path is script-first: run the script before the restart, do the human checks, take the restart, run the script again, compare, then start Time Machine. There is no individual-command alternative for this phase — the point is a consistent bundle-to-bundle comparison, and 14 different single commands are hard to compare by eye.

### What Gets Recorded

Each `record-reimaged-system.sh` run writes one timestamped bundle containing:

```text
initial-checklist.md               automated + manual rows with PASS/WARN/TODO on the automated ones
README.md                          bundle summary and reading order
restart-checkpoints.md             planned restart points across restore phases
time-machine-reimaged-system-plan.md  where and when to run Time Machine after reimage
manual-captures-required.md        rows only a human can close
raw/*.txt                          the 14 read-only command outputs the checklist reads from
logs/commands.log                  every command the script ran
logs/errors.log                    stderr collected during the run
checks/                            reserved for future automated cross-checks
```

The 14 automated rows cover: identity (`whoami`, hostname), managed baseline (`profiles`, `fdesetup`, Company Portal / CrowdStrike / Zscaler presence), common apps (Office, OneDrive, Chrome), plumbing (Time Machine destination, volumes, `sw_vers`, `softwareupdate --list`), platform tools (Homebrew, Git, `xcode-select`), and — unless `--no-network` — network reachability to `github.com` and `login.microsoftonline.com`.

### Two Runs Around One Restart

The workflow is deliberately a pair. The pre-restart run proves what the machine looks like when Phase 6 finished; the post-restart run proves the same signals survived a reboot. Anything that flipped from `PASS` to `WARN`/`TODO` across the pair is a regression worth investigating before restore work — a login item that stopped launching, a managed process that no longer runs, network reachability that broke because a profile did not reload. Two separate bundles matter because a single run cannot tell "installed but not yet started" apart from "started, then stopped after reboot".

### Automated vs Manual Rows

The script asserts fixed verdicts on what a command can prove; the rest stays a human check.

| Row group | What the script does | What you do |
|---|---|---|
| Automated | Records the raw command output and stamps `PASS` / `WARN` / `TODO` on 14 rows. | Read the raw file for context on any `WARN`. |
| Manual | Nothing. The row is left as `TODO` in `initial-checklist.md` and enumerated in `manual-captures-required.md`. | Sign the row after the UI, peripheral, or restart observation. |

`WARN` is not the same as `FAIL`: it means the command ran and the recorded output did not obviously match the expected pattern. `TODO` on an automated row means the check was skipped (for example, no `--artifact-root` was in scope) or its precondition was not met.

### Terminology

| Term | Meaning |
|---|---|
| First-boot bundle | One timestamped `initial-reimaged-system-YYYYMMDD-HHMMSS/` directory produced by `record-reimaged-system.sh`. |
| Pre-restart bundle | The first-boot bundle written before the second stabilization restart. |
| Post-restart bundle | The first-boot bundle written after the second stabilization restart; the sign-off bundle. |
| Second stabilization restart | The Phase 7 restart taken after the pre-restart bundle, distinct from the Phase 6 first stabilization restart. |
| Companion documents | The four Markdown files (`restart-checkpoints.md`, `time-machine-reimaged-system-plan.md`, `manual-captures-required.md`, `README.md`) written alongside `initial-checklist.md` in each bundle. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/record-reimaged-system.sh    # entrypoint — records one first-boot evidence bundle per invocation
```

Related script:

```text
$FRACTOGENESIS_HOME/bin/record-enrollment.sh    # entrypoint — Phase 6 enrollment record; run before this phase
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/    # first-boot bundles, restart notes, Time Machine notes, restore notes
```

### Bundle Layout

The bundle prefix is kept as `initial-reimaged-system-*` to match the artifact tree documented in the Master Directory Reference and the pattern `bin/reimage-checklist.sh` looks for when validating Phase 7 evidence.

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/
├── latest-initial-reimaged-system-bundle.txt
├── initial-reimaged-system-YYYYMMDD-HHMMSS/
│   ├── README.md
│   ├── initial-checklist.md
│   ├── restart-checkpoints.md
│   ├── time-machine-reimaged-system-plan.md
│   ├── manual-captures-required.md
│   ├── raw/
│   │   ├── applications-managed.txt
│   │   ├── artifact-root-spotcheck.txt
│   │   ├── brew-version.txt
│   │   ├── computer-name.txt
│   │   ├── date.txt
│   │   ├── filevault.txt
│   │   ├── git-version.txt
│   │   ├── hardware.txt
│   │   ├── host-name.txt
│   │   ├── hostname.txt
│   │   ├── local-host-name.txt
│   │   ├── managed-processes.txt
│   │   ├── network-github.txt
│   │   ├── network-microsoft.txt
│   │   ├── network-ping.txt
│   │   ├── profiles-enrollment.txt
│   │   ├── profiles-list.txt
│   │   ├── softwareupdate-list.txt
│   │   ├── sw_vers.txt
│   │   ├── time-machine-destination.txt
│   │   ├── time-machine-latest.txt
│   │   ├── uname.txt
│   │   ├── volumes.txt
│   │   ├── whoami.txt
│   │   └── xcode-select.txt
│   ├── logs/
│   │   ├── commands.log
│   │   └── errors.log
│   └── checks/
├── restore-notes/
├── restarts/
└── time-machine/
```

The complete `$REIMAGE_ARTIFACT_ROOT/reimaged-system/` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

When the artifact volume is not yet mounted, the script falls back to a Desktop path. That fallback is documented in [[#Output Location Fallback|Output Location Fallback]].

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the artifact root where `reimaged-system/` lives. Optional here — the script falls back if unset or unmounted. |
| `EXTERNAL_DATA_VOLUME` | Physical volume that hosts the artifact root; referenced by the generated Time Machine plan. |
| `EXTERNAL_APPLE_BACKUPS_VOLUME` | Dedicated Time Machine destination volume when defined, used in Step 7. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what this run is for. The concepts and the *why* are in [[#How the Workflow Works|How the Workflow Works]]; this is just the checklist.

### Prerequisites

- Phase 6 ([[enroll-and-stabilize|Enroll and Stabilize]]) is complete: enrollment finished, required managed apps and security tools installed or clearly installing, and the first stabilization restart taken.
- You have signed back in after the Phase 6 restart and network is connected.
- The external artifact drive is available to reconnect. On a bare Mac the Phase 6 record may have landed on `~/Desktop/reimaged-system-artifacts/`; that is fine — Phase 7 owns the reconnection.
- You are running commands from `$FRACTOGENESIS_HOME`.

> [!note]
> `REIMAGE_ARTIFACT_ROOT` becomes relevant in Step 1 (when you reconnect the drive). The script itself does not require it — a run without a mounted artifact root lands on the Desktop fallback and can be copied into place later.

> [!bug] Troubleshooting
> If Step 1 shows the artifact volume mounted but `REIMAGE_ARTIFACT_ROOT` still resolves to a path that does not exist, the volume was reimaged / renamed / remounted at a new path. Update `reimage.env` or pass `--artifact-root PATH` on each run.

### Confirm Your Intent

- Whether this is the **pre-restart** first-boot run (Step 2) or the **post-restart** first-boot run (Step 5). Both use the same command; they differ in when they happen and which bundle you cite for the sign-off.
- Whether the network probes should run. On a captive portal or intentionally offline session, add `--no-network` so the checklist row is stamped `INFO` instead of `WARN`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The two script runs bracket the human checks and the second restart; the Time Machine backup at the end is the payoff that only makes sense once the pair looks clean.

### Step 1 — Reconnect the External Artifact Drive

Reconnect the external artifact drive so subsequent runs land under `$REIMAGE_ARTIFACT_ROOT/reimaged-system/` instead of the Desktop fallback.

Confirm the volume is mounted and the resolved artifact root exists:

```bash
printf 'REIMAGE_ARTIFACT_ROOT=%q\n' "${REIMAGE_ARTIFACT_ROOT:-<unset>}"
ls -la "$REIMAGE_ARTIFACT_ROOT" 2>/dev/null || echo "artifact root not visible"
find "$REIMAGE_ARTIFACT_ROOT/reimaged-system" -maxdepth 2 -type d 2>/dev/null | sort
```

If a Phase 6 record landed on the Desktop fallback, copy it under `reimaged-system/enrollment/` now so all Phase 6+ evidence lives together.

> [!warning] Pitfall
> Do not run heavy restore work before this step lands cleanly. Later phases assume `reimaged-system/` is the sink for restore notes and comparison bundles; a missing artifact root means those writes silently miss their intended home.

### Step 2 — Record the Pre-Restart First-Boot Bundle

Run the first-boot record before the second stabilization restart. Preview the flags first:

```bash
./bin/record-reimaged-system.sh --help
```

Run it. The default output location follows the fallback described in [[#Output Location Fallback|Output Location Fallback]]:

```bash
./bin/record-reimaged-system.sh
```

If the artifact drive was reconnected but `REIMAGE_ARTIFACT_ROOT` still resolves oddly, force it explicitly:

```bash
./bin/record-reimaged-system.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT"
```

If Step 1 could not bring the artifact root online (network-only workspace, VPN not yet up), keep the pre-restart bundle local:

```bash
./bin/record-reimaged-system.sh --output-root ~/Desktop/reimaged-system-artifacts/first-boot
```

The script emits `initial-checklist.md` with automated rows prefilled, three companion planning documents, a `raw/` directory of read-only command captures, and a `logs/` directory. It also updates `latest-initial-reimaged-system-bundle.txt` at the parent level.

### Step 3 — Review Manual First-Boot Areas

Focus on what the checklist cannot prove. The companion `manual-captures-required.md` inside the bundle enumerates these; the shortlist is:

| Area | Manual question |
|---|---|
| Company Portal | Does the UI show the device in the expected state? |
| Network | Can you reach real work sites, not just public internet? |
| Displays and peripherals | Are monitor arrangement, scaling, keyboard, mouse, and audio usable? |
| Browser and terminal | Are Chrome/Safari and Terminal good enough to continue setup? |
| Chrome baseline | Default browser set, JSON Formatter / other essential extensions present? |
| Terminal baseline | Preferred profile / window size restored? |

Restore only low-risk UI defaults needed to keep working. Anything that requires secrets, certificates, or repos waits for Phase 8+.

### Step 4 — Take the Second Stabilization Restart

Restart the Mac. This is the Phase 7 restart, distinct from the Phase 6 first stabilization restart.

Before restarting, confirm:

```text
the pre-restart bundle was written and its checklist opened cleanly
no manual restore work in progress (browser sync, OneDrive initial sync, Docker install) will be interrupted
you are ready to rerun the same commands after login
```

After the restart:

1. Sign back in.
2. Reconnect network if needed.
3. Continue directly to Step 5.

### Step 5 — Record the Post-Restart First-Boot Bundle

Rerun the record. This is the sign-off bundle — it is the one you cite in Step 8.

```bash
./bin/record-reimaged-system.sh
```

Each run writes a fresh timestamped bundle, so the pre-restart bundle from Step 2 stays in place for the comparison in Step 6.

### Step 6 — Compare the Two Bundles

Read the two `initial-checklist.md` files side by side and look for rows that flipped from `PASS` to `WARN` or `TODO`:

```bash
PRE=$(ls -1dt "$REIMAGE_ARTIFACT_ROOT"/reimaged-system/initial-reimaged-system-*/ 2>/dev/null | sed -n '2p')
POST=$(cat "$REIMAGE_ARTIFACT_ROOT/reimaged-system/latest-initial-reimaged-system-bundle.txt" 2>/dev/null)
diff -u "$PRE/initial-checklist.md" "$POST/initial-checklist.md" | head -80
```

Focus on rows that regressed. A managed process the pre-restart run saw and the post-restart run did not is usually the first thing IT will ask about.

> [!bug] Troubleshooting
> If a key row regressed after the restart (managed process gone, network reachability lost, enrollment reporting unenrolled), stop and resolve that with IT before Step 7. Do not run Time Machine on a broken baseline.

### Step 7 — Take the First Post-Image Time Machine Backup

The generated `time-machine-reimaged-system-plan.md` inside the post-restart bundle documents the recommended commands and timing. Before starting the backup, make sure the artifact volume is excluded so the manual backup directory is not folded into Time Machine:

```bash
sudo tmutil addexclusion -v "$EXTERNAL_DATA_VOLUME"
tmutil listexclusions | grep "$EXTERNAL_DATA_VOLUME" || true
tmutil destinationinfo
tmutil startbackup
```

Avoid starting the backup while OneDrive is still doing a large initial sync, while Docker images are being restored, or while Company Portal / Intune is actively pushing a large managed install — a Time Machine backup during those windows can take dramatically longer and includes churn you would rather not preserve.

### Step 8 — Close Out the Exit Criteria

Open the post-restart `initial-checklist.md` and complete the manual rows. Every row must be effectively `yes` before proceeding to [[reimaging-guide#Phase 8 — Restore Runtime Environment|Phase 8]]:

| Check | Verification mode | How to verify |
|---|---|---|
| `$REIMAGE_ARTIFACT_ROOT` is mounted and readable | Command | `ls "$REIMAGE_ARTIFACT_ROOT"` and Step 1 spot-check |
| Pre-restart first-boot bundle recorded | Command | `initial-reimaged-system-*/` from Step 2 exists |
| Post-restart first-boot bundle recorded | Command | `initial-reimaged-system-*/` from Step 5 exists |
| No new critical regressions across the two bundles | Mixed | Step 6 diff plus row-by-row review |
| Browser, network, terminal, display, keyboard, mouse, and audio basics are usable | Manual | Step 3 review |
| First post-image Time Machine backup completed or intentionally deferred | Manual | `tmutil latestbackup` plus operator sign-off |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script records uniformly and applies fixed heuristics; interpreting whether the machine is really "day-one usable" and when to take Time Machine is the judgment call.

| Decision | Why it stays with you |
|---|---|
| Whether a `WARN` or regressed row is acceptable at this point. | Rollouts are asynchronous; only you can weigh the raw evidence against what IT expects on this Mac right now. |
| Whether to take the first post-image Time Machine backup now or intentionally defer it. | Long OneDrive syncs, in-progress Docker restore, or an in-progress managed push all make immediate Time Machine less useful. |
| Whether to run `--no-network` on either bundle. | Captive portals and delayed VPN can make network probes noise; deliberate offline runs are a valid choice, not a failure. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### The two bundles disagree on a row that should be stable

Confirm you did not switch networks or unlock a captive portal between runs — several rows (network reachability, managed processes waiting on the network) can flip legitimately when the network changes. If the disagreement is not network-related, open the two raw files and compare their command output directly; the row verdict is a heuristic and the raw evidence is authoritative.

### `latest-initial-reimaged-system-bundle.txt` points at the pre-restart bundle after a Step 5 run

The pointer is rewritten on every successful run. If it still points at the pre-restart bundle, Step 5 did not complete successfully — check the tail of `logs/errors.log` inside the older bundle for the failure and rerun Step 5.

### Network row is `WARN` on a machine that clearly has internet

`curl -I https://github.com` is intercepted by many captive portals and by some corporate proxies. Retry after signing in to the portal, or rerun with `--no-network` and confirm reachability by hand.

### The bundle landed on the Desktop instead of the artifact root

Expected fallback when `REIMAGE_ARTIFACT_ROOT` was unset or the volume was not mounted at run time. Once Step 1 succeeds, copy the Desktop bundle under `reimaged-system/` and rerun subsequent recordings with the artifact root in scope so `latest-initial-reimaged-system-bundle.txt` points at the right place.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Companion Documents in the Bundle

Each `record-reimaged-system.sh` run emits four planning documents alongside `initial-checklist.md`. They are seeded from templates in the script and are safe to edit inside the bundle — they are per-run notes, not global toolkit files.

| File | What it is for |
|---|---|
| `README.md` | Bundle summary and reading order for someone opening the bundle cold. |
| `restart-checkpoints.md` | Suggested restart checkpoints across the remaining restore phases, not just this one. Update the `TODO` rows as you take each restart. |
| `time-machine-reimaged-system-plan.md` | Recommended Time Machine checkpoints, the volume-exclusion command, and the anti-patterns to avoid (OneDrive sync in flight, Docker restore in flight). |
| `manual-captures-required.md` | Enumeration of the manual rows in `initial-checklist.md` with a one-line reason each cannot be scripted. |

### Manual Review Focus

The script proves most command-checkable state on its own. Manual attention should focus on what only a human can see:

| Area | Manual question |
|---|---|
| Company Portal | Does the UI show the device in the expected state? |
| Network | Can you reach real work sites, not just public internet? |
| Displays and peripherals | Are monitor arrangement, scaling, keyboard, mouse, and audio usable? |
| Browser and terminal | Are Chrome/Safari and Terminal good enough to continue setup? |
| Restart comparison | Did anything regress after the second restart? |
| Time Machine | Was the first post-image backup completed or intentionally deferred? |

### Output Location Fallback

`record-reimaged-system.sh` picks its output root in this order when `--output-root` is not supplied:

| Order | Condition | Path |
|---|---|---|
| 1 | `REIMAGE_ARTIFACT_ROOT` set and directory exists | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/` |
| 2 | Neither of the above | `~/Desktop/reimaged-system-artifacts/initial-reimaged-system-YYYYMMDD-HHMMSS/` |

The script refuses to write output under the toolkit repo checkout as a safety invariant — a bundle landing inside the working tree almost always signals an unset or relative root variable.

[[#Table of Contents|⬆ Back to Table of Contents]]

---
