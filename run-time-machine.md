[[reimaging-guide#Phase 5 — Run Time Machine|← Back to Mac Reimaging Guide]]

<!--
Migrated from reference-vault/workflows/mac/reimage/backup-time-machine.md.
Renaming considerations:
- backup-time-machine.md → run-time-machine.md; run-time-machine.sh → bin/run-time-machine.sh.
  "backup-time-machine" is redundant (Time Machine is Apple's backup system); "run-" names the
  runtime driver and pairs with the read-only record-time-machine-evidence.sh helper.
- capture-time-machine.sh → record-time-machine-evidence.sh. "capture-" was overused and
  had stopped distinguishing anything. It now marks one group only: paired pre-image /
  post-image state inventories that are re-run after the reimage and compared — every
  capture-* script but one has a Phase 13 sibling. "record-" marks the other group:
  one-time evidence that a specific operation succeeded, with nothing to compare it
  against later. That is what this is, alongside record-enrollment.sh and
  record-reimaged-system.sh. "-evidence" names the output. run-time-machine.md owns
  both scripts.
-->

# Run Time Machine

**Last updated:** 2026-08-04

Run and validate a Time Machine backup before a Mac reimage — the broad, whole-home safety net that sits alongside, and never replaces, the targeted `$REIMAGE_ARTIFACT_ROOT` artifacts produced by the earlier Phase 2 backups.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#The Two Scripts|The Two Scripts]]
    - [[#Full vs Incremental|Full vs Incremental]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Exclude Volumes and Confirm the Destination|Step 1 — Exclude Volumes and Confirm the Destination]]
    - [[#Step 2 — Capture Pre-Run Evidence and Keep the Mac Awake|Step 2 — Capture Pre-Run Evidence and Keep the Mac Awake]]
    - [[#Step 3 — Start and Monitor the Backup|Step 3 — Start and Monitor the Backup]]
    - [[#Step 4 — Confirm Completion and Verify|Step 4 — Confirm Completion and Verify]]
    - [[#Step 5 — Capture Post-Run Evidence and Compare|Step 5 — Capture Post-Run Evidence and Compare]]
    - [[#Step 6 — Eject Before Reimage|Step 6 — Eject Before Reimage]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Subcommand Reference|Subcommand Reference]]
    - [[#Raw Command Equivalents|Raw Command Equivalents]]
    - [[#Estimate Remaining Time from Real Progress|Estimate Remaining Time from Real Progress]]
    - [[#Verify the Installed Capture Script Version|Verify the Installed Capture Script Version]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Produce a completed, verified Time Machine backup before the Mac is erased, so the home directory is recoverable from a known-good snapshot even if something is missed in the manual backup workflow. Time Machine is a broad safety net; it does not replace the targeted restore/evidence layer, so both must be complete before the reimage.

Proceed to the reimage only once all of these hold:

```text
latest completed Time Machine backup exists and is newer than the major pre-reimage manual backup work
Time Machine destination is the intended backup volume, not the manual data volume
the external data volume and the artifact root remain excluded from Time Machine
verification and spot checks show no corruption or destination confusion
```

This runbook owns:

```text
running, monitoring, and completing the pre-image Time Machine backup — bin/run-time-machine.sh
read-only Time Machine evidence capture — bin/record-time-machine-evidence.sh
Time Machine verification, comparison, and the final eject before erase
the $REIMAGE_ARTIFACT_ROOT/time-machine/ evidence layout
```

It does not own:

```text
source-code state — backup-repos.md (Phase 2A)
broad local-file copy — backup-home.md (Phase 2B)
application settings and IntelliJ state — backup-apps.md / backup-intellij.md (Phase 2D)
certificate and Keychain staging, and encrypted secrets packaging — stage-certs-keychain.md (Phase 3A) / create-secrets-dmg.md (Phase 3C)
cross-phase readiness sign-off — reimage-prep-checks.md (Phase 6B)
```

This runbook can be rerun independently: rerunning the backup produces a fresh incremental snapshot and new timestamped evidence without disturbing earlier runs.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The flow is: exclude the wrong volumes and confirm the right destination, capture lightweight pre-run evidence, start the backup and watch it to completion, verify the completed snapshot, capture post-run evidence and compare against the previous backup, then eject cleanly before the erase. The order matters because a backup pointed at the wrong destination, or one that swept in the manual artifact root, wastes hours and produces confusing validation evidence — so destination and exclusions are settled first, before anything is written.

The preferred path is the scripted one: drive every runtime action through `bin/run-time-machine.sh` and capture evidence through `bin/record-time-machine-evidence.sh`, falling back to the raw `tmutil`/`diskutil` commands in [[#Raw Command Equivalents|Raw Command Equivalents]] only when a script is unavailable or you are debugging it.

### The Two Scripts

Two scripts split runtime control from evidence capture, so read-only capture never risks starting or stopping a backup.

| Script | Role | Use it for |
|---|---|---|
| `bin/run-time-machine.sh` | Runtime driver | start, monitor, complete, verify-latest, compare, mount/unmount snapshots, logs, diagnose, eject |
| `bin/record-time-machine-evidence.sh` | Read-only evidence capture | pre-run snapshot, focused `verify-volume`, and the final checklist bundle — it never starts, stops, or mounts a backup |

The full per-subcommand tables are in [[#Subcommand Reference|Subcommand Reference]].

### Full vs Incremental

Time Machine chooses the backup mode; you do not pass a flag. For this pre-reimage pass an incremental backup is acceptable when a healthy full backup already exists and the new run completes after the latest manual pre-image changes.

| Mode | When it happens | What to expect |
|---|---|---|
| First full | First backup to a destination, after it is erased/reformatted, or when prior history is unusable. | Long runtime, large `totalBytes`, high disk activity. |
| Incremental | A prior completed backup exists for this Mac on the same destination. | Usually faster; copies only new or changed items since the previous backup. |

There is no `tmutil startbackup --full` flag; do not force a full backup just because the current run is incremental. Whether a large incremental or a fresh full is warranted is a judgment call — see [[#Decisions|Decisions]].

### Terminology

| Term | Meaning |
|---|---|
| Time Machine destination | The volume Time Machine writes snapshots to — `EXTERNAL_APPLE_BACKUPS_VOLUME` (e.g. `/Volumes/AppleBackups`). |
| External data volume | The physical/mounted volume holding the manual reimage artifacts — `EXTERNAL_DATA_VOLUME` (e.g. `/Volumes/Data`). Excluded from Time Machine. |
| Artifact root | This reimage event's generated tree — `REIMAGE_ARTIFACT_ROOT`, under the external data volume. Also excluded from Time Machine. |
| APFS snapshot | The APFS-format point-in-time backup Time Machine records on the destination; addressable under `/Volumes/.timemachine/…`. |
| `Running = 1` | `tmutil status` reports an active backup session; `Running = 0` means none is active. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary and related scripts (alphabetical; each classified):

```text
$FRACTOGENESIS_HOME/bin/report-size-audit.sh      # entrypoint — capacity check for the Time Machine destination
$FRACTOGENESIS_HOME/bin/record-time-machine-evidence.sh    # entrypoint — read-only evidence capture
$FRACTOGENESIS_HOME/bin/run-time-machine.sh        # entrypoint — Time Machine runtime driver
```

Evidence is written under the artifact root; this is the layout this runbook owns:

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── time-machine/
│   ├── compare-YYYYMMDD-HHMMSS.txt
│   ├── completion-check-YYYYMMDD-HHMMSS.md
│   ├── diskutil-verifyvolume-applebackups-YYYYMMDD-HHMMSS.txt
│   ├── logs-YYYYMMDD-HHMMSS.txt
│   ├── pre-image-time-machine-status-YYYYMMDD-HHMMSS/
│   │   ├── README.md
│   │   ├── raw/
│   │   │   ├── backup-root-spot-check.txt
│   │   │   ├── cloud-sync-process-hints.txt
│   │   │   ├── diskutil-applebackups-snapshots.txt
│   │   │   ├── diskutil-applebackups.txt
│   │   │   ├── diskutil-data.txt
│   │   │   ├── diskutil-verifyvolume-applebackups.txt
│   │   │   ├── tmutil-currentphase.txt
│   │   │   ├── tmutil-destinationinfo.txt
│   │   │   ├── tmutil-isexcluded-applebackups.txt
│   │   │   ├── tmutil-isexcluded-data.txt
│   │   │   ├── tmutil-latestbackup-targeted-applebackups.txt
│   │   │   ├── tmutil-latestbackup.txt
│   │   │   ├── tmutil-listbackups-targeted-applebackups.txt
│   │   │   ├── tmutil-listbackups.txt
│   │   │   ├── tmutil-status.txt
│   │   │   └── volumes.txt
│   │   ├── time-machine-pre-run.md
│   │   └── time-machine-status.md
│   ├── pre-run-YYYYMMDD-HHMMSS.md
│   ├── preflight-YYYYMMDD-HHMMSS.md
│   └── verifychecksums-YYYYMMDD-HHMMSS.txt
└── ...
```

The complete `$REIMAGE_ARTIFACT_ROOT` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to this reimage event's artifact root, under the external data volume. Excluded from Time Machine; Time Machine evidence is written to `time-machine/` here. |
| `EXTERNAL_DATA_VOLUME` | The mounted external volume holding the artifact root (e.g. `/Volumes/Data`). Excluded from Time Machine. |
| `EXTERNAL_APPLE_BACKUPS_VOLUME` | The dedicated Time Machine destination volume (e.g. `/Volumes/AppleBackups`). |

> [!note]
> The external data volume and the Time Machine destination may be separate APFS volumes on one physical drive, or on two drives. Ejecting either volume unmounts the whole physical drive when they share one — see [[#Step 6 — Eject Before Reimage|Step 6]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you mean this run to do. The conceptual background is in [[#How the Workflow Works|How the Workflow Works]]; this is just the checklist.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- `REIMAGE_ARTIFACT_ROOT`, `EXTERNAL_DATA_VOLUME`, and `EXTERNAL_APPLE_BACKUPS_VOLUME` resolve, and both external volumes are mounted (`reimage.env` produced by `prepare-artifact-root.md`).
- The earlier Phase 2 backups are done — Time Machine is the last backup action, so its snapshot post-dates them.
- Heavy apps that churn files are closed: IntelliJ IDEA, Docker Desktop, Outlook/OneNote, and any dev servers or build processes. OneDrive, Finder, and Terminal are fine to leave running.

> [!bug] Troubleshooting
> If `tmutil addexclusion` seems to have no effect, confirm the volume is actually mounted: `mount | grep -F "$EXTERNAL_DATA_VOLUME"`. If it is not, reconnect the drive, reload `reimage.env`, and rerun.

### Confirm Your Intent

- That this run is the pre-image safety net, taken after the manual backups — not a routine backup.
- Whether an incremental backup is acceptable (it usually is when a healthy full already exists), or whether you have a real reason to establish a fresh full — see [[#Decisions|Decisions]].
- Whether the backup may run for hours; if so, plan to keep the Mac awake with `caffeinate` (Step 2).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order for the pre-reimage Time Machine pass: settle the destination and exclusions, capture pre-run evidence, run and watch the backup, verify it, capture post-run evidence and compare, then eject. Each command block is preceded by a one-line statement of what it is for.

### Step 1 — Exclude Volumes and Confirm the Destination

Keep Time Machine off the manual artifact data and pointed at the right volume, before anything is written. Excluding the data volume and artifact root avoids duplicate backup data, long runtimes, and confusing validation evidence.

Add the exclusions. `-p` records a sticky path exclusion; the artifact root is the one that matters, since that is where the bulky manual backups live:

```bash
sudo tmutil addexclusion -p "$REIMAGE_ARTIFACT_ROOT"
sudo tmutil addexclusion -p "$EXTERNAL_DATA_VOLUME"
```

Verify both are excluded — this, not the command's exit status, is the real gate. The output uses the actual mounted paths and should read `[Excluded]`:

```bash
tmutil isexcluded "$EXTERNAL_DATA_VOLUME" "$REIMAGE_ARTIFACT_ROOT"
```

> [!bug] Troubleshooting
> `addexclusion -p` on a mounted volume root can fail with `The operation couldn't be completed. Invalid argument` / `POSIXError … Code=22` — a known quirk of setting a sticky exclusion on a volume mountpoint. It changes nothing. If `isexcluded` already shows the volume `[Excluded]` (it usually will, from the artifact-root exclusion or a prior run), you are done. If it shows `[Included]`, add it as a fixed exclusion without `-p` (`sudo tmutil addexclusion "$EXTERNAL_DATA_VOLUME"`), or set it via System Settings → General → Time Machine → Options → Exclude from Backups.

> [!warning] Pitfall
> Exclusion and destination are separate facts: `isexcluded` controls what Time Machine must not copy, `destinationinfo` controls where it may write. A volume can be excluded and still be wrongly configured as a destination — check both. Do not rely on `tmutil listexclusions`; that verb is missing on some macOS versions.

Confirm the configured destination is the Time Machine volume and does not list the external data volume:

```bash
tmutil destinationinfo
```

> [!bug] Troubleshooting
> If the external data volume appears as a destination, remove it by ID before starting — see [[#Troubleshooting|Troubleshooting]].

Optionally sanity-check destination capacity before a long run:

```bash
./bin/report-size-audit.sh --context pre-image-time-machine --drive "$EXTERNAL_APPLE_BACKUPS_VOLUME"
```

### Step 2 — Capture Pre-Run Evidence and Keep the Mac Awake

Record the starting state and prevent sleep before a potentially multi-hour run. Confirm heavy apps are closed (see Prerequisites) first, so the pre-run snapshot reflects a quiet system.

Capture the lightweight pre-run snapshot (destination, latest backup, backup list, exclusions):

```bash
./bin/record-time-machine-evidence.sh pre-run --open
```

> [!note]
> The generated pre-run evidence should show the actual mounted paths, and its exclusion lines should name the external data volume and the Time Machine destination — not a hard-coded unrelated volume.

Start a keep-awake session in its own Terminal tab; it holds until you stop it with `Ctrl+C`:

```bash
caffeinate -dimsu
```

### Step 3 — Start and Monitor the Backup

Kick off an explicit immediate backup and watch real progress. An explicit start is the recommended default for the pre-image run.

Start the backup:

```bash
./bin/run-time-machine.sh start
```

Monitor progress every five minutes:

```bash
./bin/run-time-machine.sh monitor --interval 300
```

> [!note]
> `Running = 1` means a session is active; treat that as running even if a value like `Percent = "-1"` appears between phases. Stopping the monitor with `Ctrl+C` stops only the monitor loop, not the backup. Do not start a second `tmutil startbackup` — concurrent runs do not copy in parallel.

While it runs, keep the Mac plugged in and the destination attached, and avoid large file churn (Docker pulls, big `node_modules` installs, Gradle refreshes, large build loops). If it looks stalled, diagnose before restarting — see [[#Troubleshooting|Troubleshooting]].

### Step 4 — Confirm Completion and Verify

Confirm Time Machine recorded a completed backup, then corroborate it. After the monitor loop exits or `tmutil status` shows `Running = 0`, capture completion evidence:

```bash
./bin/run-time-machine.sh complete --open
```

The completion artifact records both when it was generated and the completed backup timestamp derived from the latest Time Machine record — that stamp (e.g. `2026-07-06-083233` → `2026-07-06 08:32:33`) is the durable value to cite in later validation.

Confirm the latest completed backup is present:

```bash
tmutil latestbackup
```

> [!bug] Troubleshooting
> If generic `latestbackup`/`listbackups` return nothing or error, the backup may still be fine — use the targeted `-d "$EXTERNAL_APPLE_BACKUPS_VOLUME" -t` lookups in [[#Troubleshooting|Troubleshooting]] before treating it as missing.

Run targeted checksum verification (a readable user-data path by default, avoiding restricted system paths):

```bash
./bin/run-time-machine.sh verify-latest --mount-if-needed --open
```

> [!warning] Pitfall
> `verifychecksums` walking an APFS snapshot can print `error 257`, `?`-prefixed lines, or `POSIXError Code=22` on restricted paths. These are not corruption by themselves — only `MISMATCH` or `FAILED` lines are. If the summary shows zero of those, corroborate with the completion evidence, targeted lookups, APFS snapshot list, volume verification, logs, and a Time Machine UI spot check ([[#Troubleshooting|Troubleshooting]]).

Spot-check user data through the Time Machine UI, confirming recent folders (`~/Documents`, `~/Desktop`, `~/Development`) are browsable:

```text
System Settings → General → Time Machine → Browse Backups
```

### Step 5 — Capture Post-Run Evidence and Compare

Record the verified end state and confirm what changed since the previous backup. Run this only after the backup is complete and Time Machine is stopped.

Capture APFS volume verification, then the final read-only checklist bundle:

```bash
./bin/record-time-machine-evidence.sh verify-volume --open
./bin/record-time-machine-evidence.sh final --open
```

Compare the latest backup to the previous one:

```bash
./bin/run-time-machine.sh compare --open
```

The compare helper mounts previous and latest APFS snapshots read-only as needed, picks a useful compare target, writes output under `time-machine/`, and unmounts anything it mounted. Interpret the prefixes: `+` added, `-` removed, `!` changed since the previous backup.

> [!bug] Troubleshooting
> If compare reports `Must specify at least one item inside a backup`, it compared two snapshot roots instead of items inside them — pass a broader `--compare-path` ([[#Troubleshooting|Troubleshooting]]). This is a usage error, not corruption.

### Step 6 — Eject Before Reimage

Detach the drive cleanly so no volume is mid-write when the erase begins. Eject both selected volumes:

```bash
./bin/run-time-machine.sh eject
```

If both volumes are on one physical drive, eject the whole disk by identifier instead:

```bash
./bin/run-time-machine.sh eject --physical-disk disk4
```

Confirm the volumes are gone, then physically disconnect the drive:

```bash
ls /Volumes
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The scripts drive and verify the backup; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Accept a large incremental, or establish a fresh full backup? | A large incremental is normal after big app/OS updates or tree changes and preserves history; a fresh full costs hours and, if it means erasing the destination, discards history. Only you know whether prior history is healthy. Prefer the incremental when latest-backup, destination, logs, and validation are all healthy. |
| Is the backup trustworthy despite restricted-path noise in `verifychecksums`? | `error 257` / `?` / `POSIXError Code=22` lines are expected on system paths and are not mismatches. Weigh them against the corroborating evidence; only `MISMATCH`/`FAILED` indicate real corruption. |
| Verify a targeted user-data path, or the full snapshot? | Targeted verification is the fast default; full-snapshot (`--full-snapshot`) is broad and noisy — choose it only when you deliberately want exhaustive validation. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### `tmutil destinationinfo` shows the external data volume as a destination

The manual data volume is wrongly configured as a Time Machine destination. Capture the current destinations, remove the wrong one by ID, then re-confirm:

```bash
tmutil destinationinfo
sudo tmutil removedestination <destination-id-for-external-data-volume>
tmutil destinationinfo
```

Re-check exclusions afterward with `tmutil isexcluded "$EXTERNAL_DATA_VOLUME" "$EXTERNAL_APPLE_BACKUPS_VOLUME"`.

### Generic `latestbackup` / `listbackups` fail, but targeted lookup works

Generic commands can fail even when the APFS snapshots exist and targeted lookup works. Confirm the destination and that no backup is running, list snapshots, then target the destination directly:

```bash
tmutil destinationinfo
diskutil apfs listSnapshots "$EXTERNAL_APPLE_BACKUPS_VOLUME"
tmutil latestbackup -d "$EXTERNAL_APPLE_BACKUPS_VOLUME" -t
tmutil listbackups -d "$EXTERNAL_APPLE_BACKUPS_VOLUME" -t | tail -5
```

Treat the backup as acceptable for pre-image safety when the destination is correct, both volumes are excluded, `tmutil status` shows `Running = 0`, the snapshot list and `diskutil verifyVolume` are clean, and targeted `latestbackup` returns the expected timestamp.

### `verifychecksums` reports `error 257`, `?` entries, or `POSIXError Code=22`

These come from restricted or unreadable system paths while walking the snapshot; they are not mismatches. The helper appends a verification summary to `verifychecksums-YYYYMMDD-HHMMSS.txt`. If it shows zero `MISMATCH`/`FAILED` lines, corroborate with the completion evidence, targeted `latestbackup`/`listbackups`, the APFS snapshot list, `diskutil verifyVolume`, the completion-window logs, and a Time Machine UI spot check. Only `MISMATCH`/`FAILED` are real corruption indicators.

### `verifychecksums` reports `No such file or directory`

Usually `verifychecksums` could not open the APFS snapshot path returned by `latestbackup`, not corruption. Use the helper mount first:

```bash
./bin/run-time-machine.sh verify-latest --mount-if-needed --open
```

Treat the backup as suspect only if `latestbackup`/`listbackups` lack the expected timestamp, the destination is wrong, `status`/logs show a failure, the UI cannot browse the backup, or `verifychecksums` actually prints `MISMATCH`/`FAILED`.

### The backup looks stalled

Check whether it is actually moving before restarting. Sample twice, two minutes apart:

```bash
tmutil status | grep -E "files|totalFiles|Percent|bytes"
sleep 120
tmutil status | grep -E "files|totalFiles|Percent|bytes"
```

Many tiny files incrementing (`files` up, `bytes` flat) is slow but progressing; both flat may be a genuine stall. To see what `backupd` is copying (use `fs_usage`, not `iotop`, which SIP blocks on Apple silicon):

```bash
sudo fs_usage -f filesys backupd 2>/dev/null | head -30
```

For a real estimate, compare byte samples over time rather than trusting `TimeRemaining` — see [[#Estimate Remaining Time from Real Progress|Estimate Remaining Time from Real Progress]].

### A large incremental looks like a full backup

Large incrementals happen after big app/OS updates, Homebrew/Python/Node tree changes, Docker/VM changes, or exclusion changes. Confirm prior history is still visible before assuming a reset:

```bash
tmutil listbackups -d "$EXTERNAL_APPLE_BACKUPS_VOLUME" -t | tail -10
```

Do not erase the destination just because the estimate is large — let it proceed and watch byte/file progress.

### `tmutil compare` reports "Must specify at least one item inside a backup"

`compare` needs an item inside each backup, not two snapshot roots. Use the helper, or pass a broader compare path:

```bash
./bin/run-time-machine.sh compare --open
./bin/run-time-machine.sh compare --compare-path "Data/Users/$(whoami)" --open
```

### Verify sleep is actually prevented

Check the sleep state; look for `sleep prevented by backupd`, `powerd`, or `caffeinate`:

```bash
pmset -g | grep sleep
```

If sleep is not prevented, keep the Mac awake with `caffeinate -dimsu`.

### Stop a running backup

Stopping the monitor does not stop the backup. Stop the actual session only when necessary, then confirm:

```bash
sudo tmutil stopbackup
tmutil status
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Subcommand Reference

`bin/run-time-machine.sh` — runtime driver:

| Task | Command |
|---|---|
| Capture runtime preflight evidence | `./bin/run-time-machine.sh preflight --open` |
| Start an explicit immediate backup | `./bin/run-time-machine.sh start` |
| Monitor progress | `./bin/run-time-machine.sh monitor --interval 300` |
| Capture one runtime status snapshot | `./bin/run-time-machine.sh status` |
| Capture completion evidence | `./bin/run-time-machine.sh complete --open` |
| Verify latest backup checksums | `./bin/run-time-machine.sh verify-latest --mount-if-needed --open` |
| Compare latest to previous backup | `./bin/run-time-machine.sh compare --open` |
| Mount latest APFS snapshot read-only | `./bin/run-time-machine.sh mount-latest --open` |
| Unmount helper-mounted latest snapshot | `./bin/run-time-machine.sh unmount-latest` |
| Capture recent Time Machine logs | `./bin/run-time-machine.sh logs --last 30m --open` |
| Capture logs for a known window | `./bin/run-time-machine.sh logs --start "YYYY-MM-DD HH:MM:SS" --end "YYYY-MM-DD HH:MM:SS" --open` |
| Capture diagnostics | `./bin/run-time-machine.sh diagnose --open` |
| Eject selected volumes | `./bin/run-time-machine.sh eject` |

`bin/record-time-machine-evidence.sh` — read-only evidence capture:

| Task | Command |
|---|---|
| Capture lightweight pre-run evidence | `./bin/record-time-machine-evidence.sh pre-run --open` |
| Capture focused APFS destination verification | `./bin/record-time-machine-evidence.sh verify-volume --open` |
| Capture the final read-only checklist bundle | `./bin/record-time-machine-evidence.sh final --open` |

### Raw Command Equivalents

Use these only when debugging a script or when a script is unavailable; prefer the scripted commands above otherwise.

Pre-run state:

```bash
tmutil destinationinfo
tmutil latestbackup
tmutil listbackups
tmutil isexcluded "$EXTERNAL_DATA_VOLUME" "$EXTERNAL_APPLE_BACKUPS_VOLUME"
```

Start and monitor:

```bash
tmutil startbackup
tmutil status
tmutil currentphase
```

Recent and windowed Time Machine logs (`log` must be the system `/usr/bin/log`):

```bash
log show --predicate 'subsystem == "com.apple.TimeMachine"' --last 30m | tail -40
log show --predicate 'subsystem == "com.apple.TimeMachine"' --start "2026-07-06 08:00:00" --end "2026-07-06 09:00:00" | tail -80
```

Post-run verification, compare, and eject:

```bash
diskutil apfs listSnapshots "$EXTERNAL_APPLE_BACKUPS_VOLUME"
diskutil verifyVolume "$EXTERNAL_APPLE_BACKUPS_VOLUME"
sudo tmutil compare "$PREVIOUS_ITEM" "$LATEST_ITEM"
diskutil eject "$EXTERNAL_DATA_VOLUME"
diskutil eject "$EXTERNAL_APPLE_BACKUPS_VOLUME"
```

### Estimate Remaining Time from Real Progress

`TimeRemaining` swings wildly between small-file and large-file phases. Take two byte readings over a known interval and compute the rate instead; treat the result as directional only:

```bash
python3 - <<'PY'
b1 = 36068737024      # bytes at reading 1
b2 = 58734936064      # bytes at reading 2
minutes = 54          # minutes between readings
total = 272871763968  # totalBytes from tmutil status

rate_mb_s = (b2 - b1) / (minutes * 60) / 1e6
remaining_gb = (total - b2) / 1e9
remaining_hours = ((total - b2) / (rate_mb_s * 1e6)) / 3600

print(f"Rate: {rate_mb_s:.2f} MB/s")
print(f"Remaining: {remaining_gb:.1f} GB")
print(f"Estimated remaining: {remaining_hours:.1f} hours")
PY
```

### Verify the Installed Capture Script Version

`record-time-machine-evidence.sh` splits evidence across `pre-run`, `verify-volume`, and `final` (there is no `status` subcommand). Confirm the installed script before relying on the capture commands:

```bash
./bin/record-time-machine-evidence.sh version
```

If this prints an older version string, or `verify-volume` / `final` print `Unknown command` or fall through to `run-time-machine.sh` usage, the local capture script is stale — replace it. None of the generated bundles should include a `## Resolved Paths` / `## Selected Paths` table listing environment-variable names; if one appears, the installed script is stale.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link.
-->
