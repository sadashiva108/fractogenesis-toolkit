[[reimaging-guide#Phase 14 — Reimaged System Checks|← Back to Mac Reimaging Guide]]

# Reimaged System Checks

**Last updated:** 2026-08-17

Run the final proof step for the rebuilt Mac: generate the Phase 14 automated checklist with `bin/reimage-checklist.sh --phase post`, resolve the remaining manual sign-off rows, and land the evidence next to the rest of the reimage artifacts. This is the phase where "the rebuild is trusted" transitions from a plan to a recorded fact, and it deliberately runs after every restore that is expected to produce evidence a script can validate.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Sweep Outstanding Manual Follow-Ups|Step 1 — Sweep Outstanding Manual Follow-Ups]]
    - [[#Step 2 — Run the Post-Image Checklist|Step 2 — Run the Post-Image Checklist]]
    - [[#Step 3 — Review Automated Rows|Step 3 — Review Automated Rows]]
    - [[#Step 4 — Resolve Manual Sign-Off Areas|Step 4 — Resolve Manual Sign-Off Areas]]
    - [[#Step 5 — Rerun and Confirm the Sign-Off Artifact|Step 5 — Rerun and Confirm the Sign-Off Artifact]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#What the Script Covers|What the Script Covers]]
    - [[#Individual Commands Alternative|Individual Commands Alternative]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Prove that the rebuilt Mac is usable for daily work and development, keep the final validation bundle beside the rest of the reimage evidence, and close every manual sign-off row that automation cannot reach. This is the phase that turns a stack of successful restore runs into a signed-off rebuild — Phase 15 is allowed to touch bulk home content only after Phase 14 is clean.

**What it sets up**

- **The post-image checklist bundle** — a timestamped `reimage-checklist-*.md` under `reimaged-system/checklists/` recording PASS, WARN, FAIL, or SKIP for every area automation can reach, plus the `latest-reimage-checklist.txt` pointer to the newest run.
- **The closed manual sign-off areas** — Company Portal, internal access, OneDrive sync, Office stability, project readiness, and final cleanliness, each resolved by hand and recorded as a Phase 14 note under `restore-notes/`.

**What the rest of the workflow relies on it for**

- Phase 15 merges bulk personal home content only after this phase's checklist is clean and every manual row is closed.
- The recorded checklist file is the written evidence that the rebuild was trusted at a point in time, rather than something remembered.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| the Phase 14 `--phase post` checklist run and the sign-off bundle it generates | pre-image validation, the same script under `--phase pre` — `reimage-prep-checks` (Phase 6B) |
| the review of PASS / WARN / FAIL / SKIP rows and the decision to act on each versus record it | early post-image sanity checks and the initial "manual captures required" list this phase reads as pre-flight — `verify-reimaged-system` (Phase 9) |
| closing the manual sign-off areas (Company Portal, internal access, OneDrive sync, Office stability, project readiness, final cleanliness) | the individual restore evidence — the Phase 10–12 `restore-*` runbooks |
| | post-image comparison captures — the Phase 13 `capture-*` runbooks |
| | the post-image Time Machine backup — `run-time-machine` (Phase 16), after Restore Home |
| | bulk personal-home restore, which runs after this sign-off — `restore-home` (Phase 15) |

This runbook is rerunnable: the checklist is meant to run twice (once to see what needs attention, once after fixes) and the final `--phase post` run produces the sign-off artifact.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Phase 14 is the *proof* phase, not another *capture* phase. The rebuilt Mac has already been through every restore that is going to happen before final sign-off (Phases 8–13); the goal here is to force each of those restores to declare itself with a machine-observable fact — a running daemon, an installed binary, a mounted volume, a Git config with two identities, a Docker CLI that talks to a daemon — and to name the ones that can only be validated by eye so they don't slip through.

The workflow depends on two facts working together: the checklist script covers the categories automation can cover, and the manual sign-off table covers the ones it cannot. Running the script once and stopping there is the most common Phase 14 mistake — the point is to run it, act on what it says, then run it again so the recorded artifact reflects the resolved state. The Phase 9 initial post-image run wrote a `manual-captures-required.md` inside its own bundle; that file is the pre-flight for this phase, not this phase's output.

The same script serves Phase 6B with `--phase pre`; that run is the pre-image gate and belongs to a different runbook. This runbook is `--phase post` only, and it is the closing sign-off rather than the first post-image bundle Phase 9 produced.

There is no Time Machine backup in this phase. It was previously taken here, on
the reasoning that it should preserve the trusted rebuild before Phase 15 merges
bulk personal content into it — but that ordering left the restored home
directory out of the only post-image backup, and Phase 15's own guidance is to
prefer cloud resync over manual copy, so little of what it does is
irreversible. The backup now runs once, in
[[reimaging-guide#Phase 16 — Post-Image Time Machine|Phase 16]], after Restore
Home. Until then the pre-image Time Machine chain remains the fallback.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path this runbook uses is defined here, once. Later steps refer back to these names instead of restating them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/reimage-checklist.sh          # entrypoint — aggregate validator (--phase post)
```

Related script (Phase 9 initial post-image bundle; its `manual-captures-required.md` is the pre-flight for this phase):

```text
$FRACTOGENESIS_HOME/bin/record-reimaged-system.sh     # entrypoint — owned by Phase 9
```

Generated output roots:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists/reimage-checklist-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists/latest-reimage-checklist.txt
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/                # optional manual follow-up notes
```

Pre-flight file written by Phase 9 (read, not written here):

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/manual-captures-required.md
```

Directory shape read and written by this runbook:

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── reimaged-system/
│   ├── checklists/
│   │   ├── latest-reimage-checklist.txt
│   │   └── reimage-checklist-YYYYMMDD-HHMMSS.md
│   ├── restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/
│   │   └── manual-captures-required.md
│   └── restore-notes/
└── ...
```

The complete `$REIMAGE_ARTIFACT_ROOT/reimaged-system/` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Mounted external artifact volume. `bin/reimage-checklist.sh --phase post` writes here under `reimaged-system/checklists/`. |
| `FRACTOGENESIS_HOME` | Local checkout of `fractogenesis-toolkit`; entrypoints are run from here. Set by your shell startup / `.envrc`, not stored in `reimage.env`. |

Optional script flags:

| Flag | When to pass |
|---|---|
| `--phase post` | Required for Phase 14. Selects the post-image ruleset and the `reimaged-system/checklists/` output root. |
| `--artifact-root PATH` | Override `$REIMAGE_ARTIFACT_ROOT` for a scratch run. |
| `--open` | Reveal the generated checklist in Finder when the script finishes. |
| `--internal-url URL` | Add an internal service to the reachability check row. |
| `--workspace-root PATH` | Add a projects directory to the Git-status check row. Repeatable. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the toolkit root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Every Phase 8–13 runbook that is expected to run has finished, including any restore-notes plan-notes under `reimaged-system/restore-notes/`.
- The external artifact volume is mounted and `$REIMAGE_ARTIFACT_ROOT` resolves; `reimaged-system/checklists/` will be created if missing.
- The Phase 9 post-restart bundle is the official run for `verify-reimaged-system-post-restart` under `reimaged-system/restarts/`; its `manual-captures-required.md` is reachable.
- OneDrive is signed in and sync has settled — the checklist has a row for this, but you reach a clean result faster by resolving it up front.

> [!bug] Troubleshooting
> If `bin/reimage-checklist.sh` reports "no such directory" for `reimaged-system/checklists/`, either mount the artifact volume and re-source `reimage.env`, or pass `--artifact-root PATH` explicitly.

### Confirm Your Intent

- Are you running the *diagnostic* pass (expect WARN/FAIL rows and plan to act on them) or the *sign-off* pass (rows are expected to resolve or be documented, and the resulting file is the final artifact)? Every Phase 14 typically does both — the diagnostic run first, the sign-off run after fixes.
- Do you want the checklist opened in Finder on completion (`--open`) or are you running headless?
- Are there additional internal URLs or workspace roots for this rebuild? Have them ready before the checklist run so a single script invocation covers them.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The first pass surfaces the issues; the second pass records the resolved state.

### Step 1 — Sweep Outstanding Manual Follow-Ups

Before the automated checklist, resolve or acknowledge the manual rows Phase 9 already flagged:

```bash
RESTARTS="$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts"
LATEST_INITIAL="$RESTARTS/$(cat "$RESTARTS/official/verify-reimaged-system-post-restart.txt" 2>/dev/null)"
printf 'BUNDLE = %s\n' "$LATEST_INITIAL"
open "$LATEST_INITIAL/manual-captures-required.md"
```

The bundle is resolved through the run index rather than by listing directories:
Phase 9's first-boot bundles are indexed runs under `restarts/`, and
`official/<context>.txt` names the one that counts. The post-restart lineage is
the one this phase is asking about, because it is the run taken after the second
stabilization restart.

Also scan any plan-notes from the restore phases:

```bash
ls -1t "$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/" 2>/dev/null | head
```

For each outstanding row, either fix the underlying issue now, or record the deliberate skip in a fresh Phase 14 note under `restore-notes/` so the Phase 14 checklist has something to reference when it lands on the matching row.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Run the Post-Image Checklist

Run the unified checklist entrypoint in post-image mode:

```bash
./bin/reimage-checklist.sh \
  --phase post \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --open
```

Optional additions:

```bash
./bin/reimage-checklist.sh \
  --phase post \
  --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
  --internal-url "https://your-internal-url" \
  --workspace-root ~/path/to/projects \
  --open
```

The generated file lands at:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists/reimage-checklist-YYYYMMDD-HHMMSS.md
```

with `latest-reimage-checklist.txt` updated to point at the fresh run.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Review Automated Rows

Read the generated checklist end-to-end. For each row:

| Status | Do this |
|---|---|
| `PASS` | Move on. |
| `WARN` | Decide whether it blocks sign-off. If yes, act. If no, record why in a `restore-notes/` note so the next Phase 14 pass carries the reasoning. |
| `FAIL` | Act. This row must resolve or be explicitly waived with a note before the sign-off pass. |

Only four post-image rows can record `FAIL`, and each one means a phase did not
finish rather than a detail needing attention:

| Row | Why it blocks sign-off |
|---|---|
| MDM / Intune enrollment | Phase 8 did not complete; every managed-app and certificate assumption after it is unfounded. |
| FileVault | A rebuilt managed Mac with FileVault off is a compliance and data-loss problem, and this is the last point anyone looks. |
| Global Git identity | Phase 11A did not complete; commits made afterwards are mis-attributed and only fixable by rewriting history. |
| Secrets DMG detached | A decrypted secrets volume is still attached, leaving every credential in it readable. |

Everything else is `WARN` or `SKIP` by design — including absent optional Phase 13
captures, security agents still installing, and Docker not yet running. So
`./bin/reimage-checklist.sh --phase post` exiting **0** now genuinely means "no
phase was left unfinished", and exiting **1** names which one.
| `SKIP` | Confirm the skip is intended (e.g., you did not pass `--internal-url` on purpose). If not, rerun with the correct flag. |

> [!warning] Pitfall
> A `PASS` row proves the check ran, not that the underlying state is what you want. Read the value the row emitted (the specific version, the specific enrollment state) — a `PASS` on a stale value is still a problem.

> [!bug] Troubleshooting
> If the checklist reports `WARN` for Docker although Docker Desktop is installed, see [[#The checklist reports `WARN` for Docker even though Docker Desktop is installed|The checklist reports `WARN` for Docker even though Docker Desktop is installed]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Resolve Manual Sign-Off Areas

These rows cannot be proved by a script. Walk them by hand:

| Area | Manual question |
|---|---|
| Company Portal | Does the UI show the expected compliant / registered state? |
| Internal access | Do real internal work sites and services function end-to-end (not just reachable)? |
| OneDrive | Is sync complete or acceptably close, with no pending conflict copies? |
| Office stability | Do Outlook and OneNote behave normally after setup has had time to settle? |
| Project readiness | Do the key repos open, build, and run as expected in their real IDE? |
| Final cleanliness | Are temporary secret copies removed, DMGs ejected, and no scratch credentials left in `$HOME`? |

Record decisions in a Phase 14 note under `restore-notes/` — especially any manual `PASS` that would look ambiguous to a future reader.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Rerun and Confirm the Sign-Off Artifact

After Steps 3–4 have resolved every actionable row:

1. Restart once if any Step 3 fix touched a login item, launch agent, or system setting that only re-settles across reboot.
2. Rerun `./bin/reimage-checklist.sh --phase post --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open`.
3. Confirm the second run is the sign-off artifact — no unexplained WARN/FAIL rows remain.

Phase 14 is complete when the second checklist file exists and the manual sign-off table is fully resolved.

> [!note]
> The `Time Machine latest backup` row will read `WARN` here, saying the latest
> backup predates the reimaged-system evidence. That is correct and expected:
> the post-image backup is Phase 16, after Restore Home. Rerun
> `./bin/reimage-checklist.sh --phase post` once Phase 16 completes if you want
> that row to close green.

> [!bug] Troubleshooting
> If a row that was `PASS` on the first run comes back `FAIL` on the rerun, see [[#A row that was `PASS` on the first run went `FAIL` on the rerun|A row that was `PASS` on the first run went `FAIL` on the rerun]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The scripts do X; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Which WARN rows block sign-off vs. get waived with a note | Only you know whether a specific WARN (e.g., a still-syncing OneDrive, a missing rarely-used app) is compatible with "the rebuild is trusted". |
| Whether Office stability is "back to normal" | The script can only observe presence and versions; the stability sign-off is behavioral over time. |
| Whether to add `--internal-url` / `--workspace-root` flags this run | Depends on which internal services and workspace roots are in scope for this rebuild. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Two post-image outcomes need more than a rerun to clear, and each would break the flow of the step that surfaces it. The steps that find them link in from callouts.

[[#Table of Contents|⬆ Back to Table of Contents]]

### The checklist reports `WARN` for Docker even though Docker Desktop is installed

The Docker CLI check needs the Docker daemon to be responsive, not just the app installed. Launch Docker Desktop, wait for the whale icon to stabilize, and rerun the checklist.

[[#Step 3 — Review Automated Rows|⮕ Continue to Step 3 — Review Automated Rows]]

### A row that was `PASS` on the first run went `FAIL` on the rerun

Something between the two runs changed the underlying state (a fix regressed a different check). Read the row values from both files under `reimaged-system/checklists/` and diff — the earlier PASS captures the last known-good state, and the current FAIL captures the regression.

[[#Step 5 — Rerun and Confirm the Sign-Off Artifact|⮕ Continue to Step 5 — Rerun and Confirm the Sign-Off Artifact]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### What the Script Covers

The Phase 14 run captures or checks:

```text
system identity
FileVault and enrollment state
managed apps and processes
Office / OneDrive / Chrome / IntelliJ / Docker / Postman / Obsidian / Raycast app presence
Homebrew and development tool versions
Docker CLI and daemon evidence
Time Machine destination and latest backup
workspace Git repo status for configured --workspace-root paths
final validation summaries and manual follow-up rows
```

Use [[capture-system-inventory|capture-system-inventory.md]] as the canonical capture for device identity and display/peripheral context, and use the phase-specific restore runbooks only for the things this script cannot prove.

### Individual Commands Alternative

Useful for spot-checking a category between checklist runs. The generated checklist runs these same categories and writes the output into the bundle.

**System identity**

```bash
sw_vers
uname -a
whoami
hostname
scutil --get ComputerName
scutil --get LocalHostName
system_profiler SPHardwareDataType | sed -n '1,80p'
fdesetup status
profiles status -type enrollment 2>/dev/null || true
```

**Development tools**

```bash
brew --version
git --version
/usr/libexec/java_home -V
java -version
gradle --version
mvn --version
python3 --version
node --version
npm --version
docker version
docker compose version
```

**Apps and Office versions**

```bash
for app in "Microsoft Outlook" "Microsoft OneNote" "Microsoft Word" "Microsoft Excel" "Microsoft PowerPoint" "Microsoft Teams" "OneDrive" "Google Chrome" "IntelliJ IDEA" "Visual Studio Code" "Docker" "Postman" "Obsidian" "Raycast"; do
  APP="/Applications/$app.app"
  echo "--- $app"
  if [[ -d "$APP" ]]; then
    /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Contents/Info.plist" 2>/dev/null || true
    /usr/bin/stat -f "modified=%Sm path=%N" -t "%Y-%m-%d %H:%M:%S" "$APP"
  else
    echo "MISSING"
  fi
done
```

**Time Machine**

```bash
tmutil destinationinfo
tmutil latestbackup 2>/dev/null || true
tmutil listexclusions | grep "$(dirname "$REIMAGE_ARTIFACT_ROOT")" || true
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link,
  except Troubleshooting, whose back-link sits under its intro and whose routed
  symptom subsections stay out of the Table of Contents.
-->
