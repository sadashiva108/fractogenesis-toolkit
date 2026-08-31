[[reimaging-guide#Phase 9 — Initial Captures and Sanity Checks|← Back to Mac Reimaging Guide]]

# Verify Reimaged System

**Last updated:** 2026-08-31

Reconnect the external artifact drive, prove the freshly reimaged Mac is basically usable, and record the first-boot evidence twice around a stabilization restart before deeper restore work begins. This phase pairs the human-driven day-one checks — network, browser, terminal, displays, peripherals, audio — with `record-reimaged-system.sh`, which records the same 14 read-only signals into two comparable evidence bundles, and hands off to Phase 10 once the pair is clean. This phase installs nothing managed: the managed app set belongs to Phase 8, and arriving here with it incomplete invalidates the bundle comparison the phase is built around.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#What Gets Recorded|What Gets Recorded]]
    - [[#Two Runs Around One Restart|Two Runs Around One Restart]]
    - [[#Automated vs Manual Rows|Automated vs Manual Rows]]
    - [[#Run Order and When to Fill Rows|Run Order and When to Fill Rows]]
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
    - [[#Step 7 — Close Out the Exit Criteria|Step 7 — Close Out the Exit Criteria]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Companion Documents in the Bundle|Companion Documents in the Bundle]]
    - [[#Manual Review Focus|Manual Review Focus]]
    - [[#Output Location Fallback|Output Location Fallback]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Confirm that the rebuilt Mac is basically usable after Phase 8 — enrolled, connected, with browser, network, terminal, displays, and peripherals in working shape — and leave behind two timestamped first-boot evidence bundles that prove the managed baseline survived the second restart. The post-image Time Machine backup is deliberately **not** taken here — see
[[reimaging-guide#Phase 16 — Post-Image Time Machine|Phase 16]]. At this point the
rebuilt Mac holds nothing that cannot be reproduced by re-enrolling, so a
multi-hour backup buys almost nothing and blocks every later phase. The
pre-image Time Machine chain remains the fallback until Phase 15 is finished
with it.

**What it sets up**

- **The reconnected artifact root** — the external artifact drive brought back online and spot-checked, so Phase 9 and later evidence lands under `reimaged-system/` instead of the Desktop fallback.
- **Two first-boot evidence bundles** — a pre-restart and a post-restart `initial-reimaged-system-*` bundle, each holding `checklist.md`, the companion planning documents, `raw/`, and `logs/`.
- **The pre/post-restart comparison** — the row-by-row read across the second stabilization restart that names anything which regressed.
- **The `reimaged-system/` working subfolders** — `boundaries/`, `comparisons/`, `state/`, `restarts/`, `restore-notes/`, and `time-machine/`, written into by later phases. Everything the post-image half produces lands under `reimaged-system/`; unlike the pre-image phases, it adds no new top-level directories to the artifact root.

**What the rest of the workflow relies on it for**

- Phase 10 onward assumes `reimaged-system/` is mounted and readable; it is the single sink for every post-image artifact — prerequisite checks, restore notes, restart records, comparison bundles, and the Phase 14 sign-off.
- Phase 14 reads the post-restart bundle's `manual-captures-required.md` as its pre-flight list of manual rows still open.
- The pre-image Time Machine chain — not a new backup — is the fallback the
  restore phases lean on if a later phase goes wrong. Phase 16 takes the
  post-image backup after Phase 15, once there is something worth preserving.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| external-artifact-drive reconnection and the sanity check that follows it | managed enrollment and the first stabilization restart — `enroll-and-stabilize` (Phase 8) |
| the two first-boot evidence bundles and the pre/post-restart comparison | runtime tooling restore (Xcode CLT, Homebrew, Java, Node) — `restore-runtime` (Phase 10A) |
| the second stabilization restart and its exit criteria | access material and secrets restore — `restore-access` (Phase 10B) |
| | the post-image Time Machine backup — `run-time-machine` (Phase 16), after Restore Home |
| | post-image managed-inventory comparison — `capture-managed-inventory` (Phase 13C) |
| relocating any Phase 8 record that landed on a fallback path | the managed application set and its Company Portal installs — `enroll-and-stabilize` (Phase 8 Step 4) |
| the `reimaged-system/` subfolders used by later phases (`boundaries`, `comparisons`, `state`, `restarts`, `restore-notes`, `time-machine`) | the final validated sign-off — its `reimage-checklist.sh --phase post` bundle and the resolution of the manual rows this phase only enumerates — `reimaged-system-checks` (Phase 14) |

This runbook can be rerun. Each run of `record-reimaged-system.sh` writes a fresh timestamped bundle and updates the `latest-initial-reimaged-system-bundle.txt` pointer, so a later run does not overwrite the pre-restart bundle you use for comparison.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Phase 8 established the managed baseline; Phase 9 asks the different question, "Is the Mac actually usable?" — a question no single command can answer. The runbook interleaves human checks (browser, terminal, displays, peripherals) with two runs of the same script, and uses the pair of resulting bundles to decide whether anything regressed across the second restart. There is deliberately no Time Machine backup in this phase; it belongs to Phase 16, after Restore Home.

The preferred path is script-first: run the script before the restart, do the human checks, take the restart, run the script again, then compare. There is no individual-command alternative for this phase — the point is a consistent bundle-to-bundle comparison, and 14 different single commands are hard to compare by eye.

### What Gets Recorded

Each `record-reimaged-system.sh` run writes one timestamped bundle containing:

```text
checklist.md               automated + manual rows with PASS/WARN/TODO on the automated ones
README.md                          bundle summary and reading order
restart-checkpoints.md             planned restart points across restore phases
time-machine-plan.md               notes for the Phase 16 backup; nothing runs here
manual-captures-required.md        rows only a human can close
raw/*.txt                          the 14 read-only command outputs the checklist reads from
logs/commands.log                  every command the script ran
logs/errors.log                    stderr collected during the run
checks/                            reserved for future automated cross-checks
```

The 14 automated rows cover: identity (`whoami`, hostname), managed baseline (`profiles`, `fdesetup`, Company Portal / CrowdStrike / Zscaler presence), common apps (Office, OneDrive, Chrome), plumbing (Time Machine destination, volumes, `sw_vers`, `softwareupdate --list`), platform tools (Homebrew, Git, `xcode-select`), and — unless `--no-network` — network reachability to `github.com` and `login.microsoftonline.com`.

### Two Runs Around One Restart

**A bundle is a snapshot; the restart is the test.** Anything that must be
proven to survive a reboot has to be installed *before* the pre-restart bundle.
Anything installed between the two runs appears in the Step 6 diff as a change,
and a diff full of newly-arrived applications hides the one row that actually
regressed. If managed apps are still missing or still installing when you reach
Step 2, return to [[enroll-and-stabilize#Step 4 — Install and Confirm Required and Available Managed Apps|Phase 8 Step 4]]
and finish there first. If you discover this after Step 2 has already run,
simply rerun the record — each run writes a fresh timestamped bundle, and the
comparison reads the two most recent.

### Automated vs Manual Rows

The script asserts fixed verdicts on what a command can prove; the rest stays a human check.

| Row group | What the script does | What you do |
|---|---|---|
| Automated | Records the raw command output and stamps `PASS` / `WARN` / `TODO` on 14 rows. | Read the raw file for context on any `WARN`. |
| Manual | Nothing. The row is left as `TODO` in `checklist.md` and enumerated in `manual-captures-required.md`. | Sign the row after the UI, peripheral, or restart observation. |

`WARN` is not the same as `FAIL`: it means the command ran and the recorded output did not obviously match the expected pattern. `TODO` on an automated row means the check was skipped (for example, no `--artifact-root` was in scope) or its precondition was not met.

### Run Order and When to Fill Rows

Three things are worth knowing before the first command rather than after it.

**Finish the installing before the first bundle.** A bundle is a snapshot; the
restart is the test. Anything that must be proven to survive a reboot has to
exist before the Step 2 record. If managed apps are still missing or still
installing when you get here, go back to
[[enroll-and-stabilize#Step 4 — Install and Confirm Required and Available Managed Apps|Phase 8 Step 4]]
and finish there. If you discover it after Step 2 has already run, just rerun
the record — each run writes a fresh timestamped bundle, and Step 6 compares
the two most recent.

**Fill the manual rows in the post-restart bundle only.** Each run regenerates
`checklist.md` with the manual rows reset, so anything hand-written into
the pre-restart bundle is discarded by the next run. Step 5 produces the
sign-off bundle and Step 8 is where its rows get answered. *Second
stabilization restart completed* in particular cannot honestly be answered in
the Step 2 bundle, because the restart is Step 4.

| Step | What you do | Manual rows |
|---|---|---|
| 1 | Reconnect the artifact drive, relocate any fallback records. | — |
| 2 | Record the pre-restart bundle. | Leave every `TODO` alone. |
| 3 | Review browser, terminal, displays, peripherals, network. | — |
| 4 | Take the second stabilization restart. | — |
| 5 | Record the post-restart bundle. | Leave them for Step 8. |
| 6 | Compare the two bundles. | — |
| 7 | Close out the exit criteria. | Fill them all, here, once. |

**Every script run has options.** Each step previews `--help` before the
command and names the flags that matter for that step. `--artifact-root` and
`--output-root` change where the bundle lands, `--no-network` changes how the
network row is scored, and `--context` labels the run so Step 6 can pair the
bundles by name — read the preview before running the bare form rather than
discovering the flag after a bundle has gone to the wrong place.

### Terminology

| Term | Meaning |
|---|---|
| First-boot bundle | One timestamped `[context-]initial-reimaged-system-YYYYMMDD-HHMMSS/` directory produced by `record-reimaged-system.sh`. |
| Context label | The optional `--context` value prefixed to the bundle directory name — `pre-restart-initial-reimaged-system-YYYYMMDD-HHMMSS` — conventionally `pre-restart` or `post-restart`. Matches the leading-phase convention of `post-image-performance-audit-*` and `pre-image-*`. |
| Pre-restart bundle | The first-boot bundle written before the second stabilization restart. |
| Post-restart bundle | The first-boot bundle written after the second stabilization restart; the sign-off bundle. |
| Second stabilization restart | The Phase 9 restart taken after the pre-restart bundle, distinct from the Phase 8 first stabilization restart. |
| Companion documents | The four Markdown files (`restart-checkpoints.md`, `time-machine-plan.md`, `manual-captures-required.md`, `README.md`) written alongside `checklist.md` in each bundle. |

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
$FRACTOGENESIS_HOME/bin/record-enrollment.sh    # entrypoint — Phase 8 enrollment record; run before this phase
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/    # first-boot bundles, restart notes, Time Machine notes, restore notes
```

### Bundle Layout

The bundle name keeps `initial-reimaged-system` and a trailing `YYYYMMDD-HHMMSS`, matching the artifact tree documented in the Master Directory Reference. A `--context` label is prefixed to it — `pre-restart-initial-reimaged-system-YYYYMMDD-HHMMSS` — matching the leading-phase convention of `post-image-performance-audit-*`, `post-reimage-*`, and the `pre-image-*` repo-audit runs. `bin/reimage-checklist.sh` therefore globs `*initial-reimaged-system-*` with a leading wildcard, and extracts the trailing stamp to compare bundle age against the Time Machine backup.

> [!warning] Pitfall
> Because the label precedes the timestamp, bundle names no longer sort
> chronologically once more than one label is in use: `post-restart` sorts
> before `pre-restart` whatever their timestamps. Pick a latest bundle by
> modification time (`ls -1dt`) or glob one label at a time; never lexically
> sort the mixed set and take the last entry.

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/
├── latest-initial-reimaged-system-bundle.txt
├── [context-]initial-reimaged-system-YYYYMMDD-HHMMSS/
│   ├── README.md
│   ├── checklist.md
│   ├── restart-checkpoints.md
│   ├── time-machine-plan.md
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
├── boundaries/
├── comparisons/
├── state/
├── restarts/
├── restore-notes/
└── time-machine/
```

The complete `$REIMAGE_ARTIFACT_ROOT/reimaged-system/` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

When the artifact volume is not yet mounted, the script falls back to a Desktop path instead; the full precedence order is under Supplemental Reference.

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the artifact root where `reimaged-system/` lives. Optional here — the script falls back if unset or unmounted. |
| `EXTERNAL_DATA_VOLUME` | Physical volume that hosts the artifact root; referenced by the generated Time Machine plan. |
| `EXTERNAL_APPLE_BACKUPS_VOLUME` | Dedicated Time Machine destination volume when defined. Referenced by the generated `time-machine-plan.md`; not used by any step in this phase. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. Set by your shell startup / `.envrc`, not stored in `reimage.env`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the toolkit root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 8 (`enroll-and-stabilize`) is complete: enrollment finished, the managed
  app set installed from **both** assignment modes — the Required push and the
  Available catalog — and the first stabilization restart taken. If anything
  this Mac needs is still listed as installable in the Company Portal **Apps**
  tab, return to
  [[enroll-and-stabilize#Step 4 — Install and Confirm Required and Available Managed Apps|Phase 8 Step 4]]
  and finish there before running anything here.
- You have signed back in after the Phase 8 restart and network is connected.
- The external artifact drive is available to reconnect. On a bare Mac the
  Phase 8 records will have landed on a fallback path — `$REIMAGE_WORKSPACE_ROOT/enrollment/`
  when a workspace was set, otherwise `~/Desktop/reimaged-system-artifacts/enrollment/`.
  Either is fine; Phase 9 owns relocating them.

> [!note]
> `REIMAGE_ARTIFACT_ROOT` becomes relevant in Step 1 (when you reconnect the drive). The script itself does not require it — a run without a mounted artifact root lands on the Desktop fallback and can be copied into place later.

> [!bug] Troubleshooting
> If Step 1 shows the artifact volume mounted but `REIMAGE_ARTIFACT_ROOT` still resolves to a path that does not exist, the volume was reimaged / renamed / remounted at a new path. Update `reimage.env` or pass `--artifact-root PATH` on each run.

### Confirm Your Intent

- Whether this is the **pre-restart** first-boot run (Step 2) or the
  **post-restart** first-boot run (Step 5). Pass that answer as
  `--context pre-restart` or `--context post-restart` so the pair is
  distinguishable on disk and Step 6 can select them by name rather than by
  recency. The flag is optional; Step 6 falls back to the two most recent
  bundles when it is not used.
- Whether the network probes should run. On a captive portal or intentionally offline session, add `--no-network` so the checklist row is stamped `INFO` instead of `WARN`.
- That you are **not** about to fill manual rows. They belong in the Step 5
  bundle and are answered in Step 8; anything written earlier is regenerated
  away.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The two script runs bracket the human checks and the second restart, and the comparison between them is what this phase produces.

### Step 1 — Reconnect the External Artifact Drive

Reconnect the external artifact drive so subsequent runs land under `$REIMAGE_ARTIFACT_ROOT/reimaged-system/` instead of the Desktop fallback.

Confirm the volume is mounted and the resolved artifact root exists:

```bash
printf 'REIMAGE_ARTIFACT_ROOT=%q\n' "${REIMAGE_ARTIFACT_ROOT:-<unset>}"
ls -la "$REIMAGE_ARTIFACT_ROOT" 2>/dev/null || echo "artifact root not visible"
find "$REIMAGE_ARTIFACT_ROOT/reimaged-system" -maxdepth 2 -type d 2>/dev/null | sort
```

If the Phase 8 records landed on either fallback path, copy them under
`reimaged-system/enrollment/` now so all Phase 8+ evidence lives together:

```bash
mkdir -p "$REIMAGE_ARTIFACT_ROOT/reimaged-system/enrollment"
cp -Rp "$REIMAGE_WORKSPACE_ROOT/enrollment/"*record-enrollment-* \
  "$REIMAGE_ARTIFACT_ROOT/reimaged-system/enrollment/" 2>/dev/null || true
cp -Rp "$HOME/Desktop/reimaged-system-artifacts/enrollment/"*record-enrollment-* \
  "$REIMAGE_ARTIFACT_ROOT/reimaged-system/enrollment/" 2>/dev/null || true
```

> [!note]
> Do not copy the fallback's `latest-enrollment-record.txt` — it names the old
> location and would point at a path that no longer receives new records. The
> next `record-enrollment.sh` run writes a correct pointer beside the relocated
> bundles.

Records relocated this way are historical evidence of the state at the time they
were written. Do not edit them to reflect what is true now; rerun
`record-enrollment.sh` instead and let the newer record supersede them.

Confirm the workspace fragments are in place before recording anything. This is
a gate, not a note: a missing `artifact-config/` does not fail any script, it
silently substitutes the committed templates, and the bundle you record is then
evidence about a configuration you do not use.

```bash
if [ -n "${REIMAGE_WORKSPACE_ROOT:-}" ] && [ ! -d "$REIMAGE_WORKSPACE_ROOT/artifact-config" ]; then
  echo "STOP: REIMAGE_WORKSPACE_ROOT is set but artifact-config/ is missing." >&2
  echo "      Restore it before recording -- see enroll-and-stabilize.md Step 2." >&2
else
  ls -1 "${REIMAGE_WORKSPACE_ROOT:-/nonexistent}/artifact-config/" 2>/dev/null \
    || echo "No workspace configured; committed templates apply by design."
fi
```

An empty `REIMAGE_WORKSPACE_ROOT` is a legitimate configuration — the templates
are then the intended source. What must not pass unnoticed is a workspace that is
configured but not present.

> [!warning] Pitfall
> Do not run heavy restore work before this step lands cleanly. Later phases assume `reimaged-system/` is the sink for restore notes and comparison bundles; a missing artifact root means those writes silently miss their intended home.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Record the Pre-Restart First-Boot Bundle

Run the first-boot record before the second stabilization restart. Preview the flags first:

```bash
./bin/record-reimaged-system.sh --help
```

Run it, labelling it as the pre-restart bundle. With no `--output-root`, the script picks its output root by the fallback precedence — the artifact root when it is set and mounted, otherwise a Desktop path:

```bash
./bin/record-reimaged-system.sh --context pre-restart
```

> [!note]
> The bundle lands at `pre-restart-initial-reimaged-system-YYYYMMDD-HHMMSS` —
> the label leads, matching `post-image-performance-audit-*`,
> `post-reimage-*`, and the `pre-image-*` repo-audit runs.
> `bin/reimage-checklist.sh` globs `*initial-reimaged-system-*` with a leading
> wildcard, so labelled and unlabelled bundles are both found. The label is
> also written inside `checklist.md`, so a bundle stays self-describing even if
> it is later moved or renamed.


If the artifact drive was reconnected but `REIMAGE_ARTIFACT_ROOT` still resolves oddly, force it explicitly:

```bash
./bin/record-reimaged-system.sh --context pre-restart --artifact-root "$REIMAGE_ARTIFACT_ROOT"
```

If Step 1 could not bring the artifact root online (network-only workspace, VPN not yet up), keep the pre-restart bundle local:

```bash
./bin/record-reimaged-system.sh --context pre-restart --output-root ~/Desktop/reimaged-system-artifacts/first-boot
```

The script emits `checklist.md` with automated rows prefilled, three companion planning documents, a `raw/` directory of read-only command captures, and a `logs/` directory. It also updates `latest-initial-reimaged-system-bundle.txt` at the parent level.

> [!warning] Pitfall
> Do not fill the manual rows in this bundle. Step 5 regenerates the checklist
> from scratch and your answers are lost. Worse, the restart rows cannot be
> answered truthfully yet — the Phase 9 restart is Step 4.

> [!bug] Troubleshooting
> If the bundle landed on the Desktop when you expected the artifact root, see [[#The bundle landed on the Desktop instead of the artifact root|The bundle landed on the Desktop instead of the artifact root]].

> [!bug] Troubleshooting
> If the network row is stamped `WARN` on a Mac that clearly has internet, see [[#Network row is WARN on a machine that clearly has internet|Network row is WARN on a machine that clearly has internet]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Review Manual First-Boot Areas

Focus on what the checklist cannot prove. The companion
`manual-captures-required.md` inside the bundle enumerates these. Restore only
low-risk UI defaults needed to keep working — anything requiring secrets,
certificates, or repositories waits for Phase 10+.

| Area | What to confirm |
|---|---|
| Company Portal | Device shows **In compliance** with a recent check timestamp. |
| Managed apps | Everything from Phase 8 Step 4 is present, including nested bundles. |
| Network | An actual internal work site loads, not just public internet. If it needs VPN and VPN needs a certificate not yet re-enrolled, record that as known-blocked rather than failed. |
| Browser | Default browser set; profile signed in; the extensions you depend on are back. Under MDM, check `chrome://policy` if anything behaves oddly. |
| Terminal | Profile, font, and window size restored. Confirm `echo $SHELL` is what you expect **before** Phase 10 begins writing to shell rc files. |
| Displays | Arrangement, scaling, and refresh rate set — then re-verified after the Step 4 restart. This is the setting most likely to silently fail to persist on a rebuilt Mac. |
| Peripherals | Keyboard, mouse/trackpad, audio input and output. |
| Finder and system | File extensions, path bar, status bar, keyboard repeat rate, Dock, screenshot location. |

> [!note]
> Deliberately **not** in this phase: OneDrive sign-in and initial sync. See
> [[enroll-and-stabilize#Step 4 — Install and Confirm Required and Available Managed Apps|Phase 8 Step 4]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Take the Second Stabilization Restart

Restart the Mac. This is the Phase 9 restart, distinct from the Phase 8 first stabilization restart.

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

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Record the Post-Restart First-Boot Bundle

Rerun the record, labelled as the post-restart bundle. This is the sign-off bundle — it is the one you cite in Step 8.

```bash
./bin/record-reimaged-system.sh --context post-restart
```

Each run writes a fresh timestamped bundle, so the pre-restart bundle from Step 2 stays in place for the comparison in Step 6. This is the bundle whose manual rows you fill, in Step 8.

> [!bug] Troubleshooting
> If `latest-initial-reimaged-system-bundle.txt` still names the pre-restart bundle after this run, see [[#latest-initial-reimaged-system-bundle.txt points at the pre-restart bundle after a Step 5 run|latest-initial-reimaged-system-bundle.txt points at the pre-restart bundle after a Step 5 run]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 6 — Compare the Two Bundles

Read the two `checklist.md` files side by side and look for rows that flipped from `PASS` to `WARN` or `TODO`:

```bash
BUNDLES="$REIMAGE_ARTIFACT_ROOT/reimaged-system"

# Prefer the labelled pair when --context was used. Sorting is safe here
# because each glob covers a single label, so the timestamp is the only part
# that varies within it.
PRE=$(ls -1d "$BUNDLES"/pre-restart-initial-reimaged-system-* 2>/dev/null | sort | tail -1)
POST=$(ls -1d "$BUNDLES"/post-restart-initial-reimaged-system-* 2>/dev/null | sort | tail -1)

# Fall back to the two most recent bundles when the labels are absent.
if [ -z "$PRE" ] || [ -z "$POST" ]; then
  PRE=$(ls -1dt "$BUNDLES"/*initial-reimaged-system-*/ 2>/dev/null | sed -n '2p')
  POST=$(cat "$BUNDLES/latest-initial-reimaged-system-bundle.txt" 2>/dev/null)
fi

printf 'PRE  = %s\nPOST = %s\n' "$PRE" "$POST"
diff -u "$PRE/checklist.md" "$POST/checklist.md" | head -80
```

> [!warning] Pitfall
> Read the printed `PRE` and `POST` before reading the diff. Under the recency
> fallback the pair is whatever ran most recently, which is wrong if you
> recorded three bundles instead of two — the extra run silently becomes the
> "pre" side. Labelling both runs with `--context` removes the guesswork.

Focus on rows that regressed. A managed process the pre-restart run saw and the post-restart run did not is usually the first thing IT will ask about.

> [!bug] Troubleshooting
> If a key row regressed after the restart (managed process gone, network reachability lost, enrollment reporting unenrolled), stop and resolve that with IT before signing off. Do not start Phase 10 on a broken baseline.

> [!bug] Troubleshooting
> If a row disagrees across the pair that should have been stable, see [[#The two bundles disagree on a row that should be stable|The two bundles disagree on a row that should be stable]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 7 — Close Out the Exit Criteria

This is the **only** step that fills manual rows. Open the post-restart
`checklist.md` — the Step 5 bundle, not the Step 2 one — and answer
every row from what you actually observed. Every row must be effectively `yes`
before proceeding to Phase 10:

| Check | Verification mode | How to verify |
|---|---|---|
| `$REIMAGE_ARTIFACT_ROOT` is mounted and readable | Command | `ls "$REIMAGE_ARTIFACT_ROOT"` and Step 1 spot-check |
| Pre-restart first-boot bundle recorded | Command | `pre-restart-initial-reimaged-system-*/` from Step 2 exists, or the Step 2 bundle by timestamp |
| Post-restart first-boot bundle recorded | Command | `post-restart-initial-reimaged-system-*/` from Step 5 exists, or the Step 5 bundle by timestamp |
| No new critical regressions across the two bundles | Mixed | Step 6 diff plus row-by-row review |
| Managed app set complete and unchanged since the pre-restart bundle | Mixed | Company Portal **Apps** tab plus `raw/applications-managed.txt` in both bundles |
| Browser, network, terminal, display, keyboard, mouse, and audio basics are usable | Manual | Step 3 review |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script records uniformly and applies fixed heuristics; interpreting whether the machine is really "day-one usable" is the judgment call.

| Decision | Why it stays with you |
|---|---|
| Whether a `WARN` or regressed row is acceptable at this point. | Rollouts are asynchronous; only you can weigh the raw evidence against what IT expects on this Mac right now. |
| Whether to run `--no-network` on either bundle. | Captive portals and delayed VPN can make network probes noise; deliberate offline runs are a valid choice, not a failure. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Four first-boot outcomes look like failures but usually are not, and each has a fix long enough to break the flow of the step that surfaces it. Each step links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### The two bundles disagree on a row that should be stable

Confirm you did not switch networks or unlock a captive portal between runs — several rows (network reachability, managed processes waiting on the network) can flip legitimately when the network changes. If the disagreement is not network-related, open the two raw files and compare their command output directly; the row verdict is a heuristic and the raw evidence is authoritative.

[[#Step 7 — Close Out the Exit Criteria|⮕ Continue to Step 7 — Close Out the Exit Criteria]]

### latest-initial-reimaged-system-bundle.txt points at the pre-restart bundle after a Step 5 run

A stale pointer does not mean the Step 5 run failed. The bundle is written first and the pointer is rewritten afterwards; if that write fails the script prints `WARNING: could not update the latest-bundle pointer:` with the pointer path and still exits `0`, because the bundle itself is valid. So check the Step 5 run output for that warning first — if it is there, the pointer is stale for a write reason (the output root is read-only, full, or the volume was unmounted), and the authoritative bundle path is the one the script printed on the `First-boot evidence bundle written:` line. Fix the write problem and rerun only if you want the pointer current; the evidence is already recorded.

Only if there was no such warning does a stale pointer suggest the Step 5 run did not reach the end — in that case check the tail of `logs/errors.log` inside the newest bundle and rerun the post-restart record.

[[#Step 6 — Compare the Two Bundles|⮕ Continue to Step 6 — Compare the Two Bundles]]

### Network row is WARN on a machine that clearly has internet

`curl -I https://github.com` is intercepted by many captive portals and by some corporate proxies. Retry after signing in to the portal, or rerun with `--no-network` and confirm reachability by hand.

[[#Step 3 — Review Manual First-Boot Areas|⮕ Continue to Step 3 — Review Manual First-Boot Areas]]

### The bundle landed on the Desktop instead of the artifact root

Expected fallback when `REIMAGE_ARTIFACT_ROOT` was unset or the volume was not mounted at run time. Once the artifact root is mounted and resolving, copy the Desktop bundle under `reimaged-system/` and rerun subsequent recordings with the artifact root in scope so `latest-initial-reimaged-system-bundle.txt` points at the right place.

[[#Step 3 — Review Manual First-Boot Areas|⮕ Continue to Step 3 — Review Manual First-Boot Areas]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Companion Documents in the Bundle

Each `record-reimaged-system.sh` run emits four planning documents alongside `checklist.md`. They are seeded from templates in the script and are safe to edit inside the bundle — they are per-run notes, not global toolkit files.

| File | What it is for |
|---|---|
| `README.md` | Bundle summary and reading order for someone opening the bundle cold. |
| `restart-checkpoints.md` | Suggested restart checkpoints across the remaining restore phases, not just this one. Update the `TODO` rows as you take each restart. |
| `time-machine-plan.md` | Forward-looking notes for the Phase 16 backup: the exclusion gate (resolved artifact volume, `tmutil isexcluded` verification, and refusal to start a backup unless it reports `[Excluded]`) and the anti-patterns to avoid (OneDrive sync in flight, Docker restore in flight). Nothing in it runs during Phase 9. |
| `manual-captures-required.md` | Enumeration of the manual rows in `checklist.md` with a one-line reason each cannot be scripted. |

### Manual Review Focus

The script proves most command-checkable state on its own. Manual attention should focus on what only a human can see:

| Area | Manual question |
|---|---|
| Company Portal | Does the UI show the device in the expected state? |
| Managed apps | Is everything installed in Phase 8 Step 4 still present? |
| Network | Can you reach real work sites, not just public internet? |
| Displays and peripherals | Are monitor arrangement, scaling, keyboard, mouse, and audio usable? |
| Browser and terminal | Are Chrome/Safari and Terminal good enough to continue setup? |
| Restart comparison | Did anything regress after the second restart? |

### Output Location Fallback

`record-reimaged-system.sh` picks its output root in this order when `--output-root` is not supplied:

| Order | Condition | Path |
|---|---|---|
| 1 | `REIMAGE_ARTIFACT_ROOT` set and directory exists | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/[context-]initial-reimaged-system-YYYYMMDD-HHMMSS/` |
| 2 | Neither of the above | `~/Desktop/reimaged-system-artifacts/[context-]initial-reimaged-system-YYYYMMDD-HHMMSS/` |

The script refuses to write output under the toolkit repo checkout as a safety invariant — a bundle landing inside the working tree almost always signals an unset or relative root variable.

> [!note]
> `record-reimaged-system.sh` has two tiers here; `record-enrollment.sh` has
> three, with `$REIMAGE_WORKSPACE_ROOT/enrollment/` in the middle. A Phase 8
> record is therefore more likely to be found in the workspace than on the
> Desktop. Step 1 relocates both.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- the `initial-reimaged-system-*` bundle prefix and the anchors other files link
  to are preserved as-is;
- each top-level section and each Sequential Step ends with a "Back to Table of
  Contents" link and a divider, except the first step, which has nothing above it
  to return from, and Troubleshooting, whose back-link sits under its intro and
  whose routed symptom subsections stay out of the Table of Contents.
-->
