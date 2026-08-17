#!/usr/bin/env bash
# =============================================================================
# record-reimaged-system.sh
#
# Phase 9 — Verify Reimaged System evidence recorder. Runs read-only day-one
# health checks (identity, MDM/profiles, FileVault, expected managed and
# personal apps, running managed processes, volumes, Time Machine destination,
# software updates, brew/git/xcode presence, optional network reachability),
# stamps PASS/WARN/TODO on the automated rows, and writes a first-boot
# evidence bundle plus companion planning documents (initial checklist,
# restart checkpoints, Time Machine plan, manual captures).
#
# Meant to run twice: once after Phase 8 completes and the external artifact
# drive is reconnected, and once again after the second stabilization restart
# so the two bundles can be compared for regressions. See
# verify-reimaged-system.md for the full runbook.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/record-reimaged-system.sh
#
#   # Default -- writes under $REIMAGE_ARTIFACT_ROOT when mounted, otherwise
#   # under ~/Desktop/reimaged-system-artifacts/.
#   ./bin/record-reimaged-system.sh
#
#   # Reveal the generated bundle in Finder after completion.
#   ./bin/record-reimaged-system.sh --open
#
#   # Override the artifact root for this invocation.
#   ./bin/record-reimaged-system.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Write to an exact output root (skips the reimaged-system/ layout and the
#   # fallback path entirely).
#   ./bin/record-reimaged-system.sh --output-root /absolute/path/to/output
#
#   # Skip curl/ping reachability probes (offline runs, or when a captive
#   # portal is intercepting HTTP HEAD).
#   ./bin/record-reimaged-system.sh --no-network
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --output-root PATH    Parent directory that will hold the timestamped
#                         first-boot bundle. Overrides the default layout.
#   --no-network          Skip network reachability probes.
#   --open                Reveal the generated bundle in Finder on completion.
#   -h, --help            Show this message and exit.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Output location precedence (used only when --output-root is not supplied):
#   1. $REIMAGE_ARTIFACT_ROOT/reimaged-system/
#        when REIMAGE_ARTIFACT_ROOT is set and currently mounted. The bundle
#        lands at reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/,
#        matching the layout documented in references/master-directory-reference.md.
#   2. ~/Desktop/reimaged-system-artifacts/
#        as a fallback so the checklist can complete on a bare Mac before the
#        external artifact volume is reconnected.
#
# Exit status:
#   0  Bundle written successfully. Individual failed checks are recorded as
#      WARN/TODO rows rather than changing the exit status; a failed
#      latest-bundle pointer update prints a WARNING and still exits 0.
#   2  Usage, configuration, or prerequisite error, including an output root
#      the bundle directory cannot be created under.
# --- END USAGE ---
# =============================================================================

# Aggregate validator/checklist strict mode.
# NOTE: intentionally NOT set -e. Failed individual checks are converted into
# PASS/WARN/TODO records rather than aborting the run, so a single unavailable
# subsystem cannot cost the whole first-boot bundle. Every read-only command
# below is guarded with `|| true` or a checker function.
set -uo pipefail

# ---------------------------------------------------------------------------
# Locate repository and load shared reimage config
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"

if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi

# The external artifact volume may not be mounted yet on the first pre-restart
# run; keep loading permissive so the Desktop fallback path is reachable.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

SCRIPT_NAME="${REIMAGE_SCRIPT_DISPLAY_NAME:-record-reimaged-system.sh}"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

# ---------------------------------------------------------------------------
# Defaults and command-line parsing
# ---------------------------------------------------------------------------
OUTPUT_ROOT=""
OPEN_RESULT=false
RUN_NETWORK=true
ARTIFACT_ROOT_EXPLICIT=false

require_option_value() {
  local option="$1"
  local value="${2:-}"

  if [[ -z "$value" || "$value" == --* ]]; then
    echo "ERROR: $option requires a non-empty value." >&2
    usage >&2
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      ARTIFACT_ROOT_EXPLICIT=true
      shift 2
      ;;
    --output-root)
      require_option_value "$1" "${2:-}"
      OUTPUT_ROOT="$2"
      shift 2
      ;;
    --no-network)
      RUN_NETWORK=false
      shift
      ;;
    --open)
      OPEN_RESULT=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve output location
# ---------------------------------------------------------------------------
# Both runbooks tell the operator to pass --artifact-root "$REIMAGE_ARTIFACT_ROOT"
# explicitly. If that value does not resolve to a mounted directory the run
# still completes against the fallback location — say so instead of silently
# downgrading. The fallback chain itself is unchanged.
if [[ "$ARTIFACT_ROOT_EXPLICIT" == "true" && ! -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "WARNING: --artifact-root does not resolve to an existing directory: ${REIMAGE_ARTIFACT_ROOT:-<unset>}" >&2
  echo "WARNING: the artifact volume is probably not mounted. This run falls back to the local output location below; reconnect the drive and rerun to file the bundle with the rest of the evidence." >&2
fi

if [[ -z "$OUTPUT_ROOT" ]]; then
  if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system"
  else
    OUTPUT_ROOT="$HOME/Desktop/reimaged-system-artifacts"
  fi
fi

# Resolve a relative --output-root against the current directory before the
# guard below compares it with the repo root; a relative path can never match
# "$REPO_ROOT"/*, so without this `--output-root subdir` run from the checkout
# slips past the guard. The directory need not exist yet, so this is a plain
# textual prefix rather than a realpath() call (also keeps Bash 3.2 support).
case "$OUTPUT_ROOT" in
  /*) ;;
  *) OUTPUT_ROOT="$PWD/$OUTPUT_ROOT" ;;
esac

if [[ -n "${REPO_ROOT:-}" && ( "$OUTPUT_ROOT" == "$REPO_ROOT" || "$OUTPUT_ROOT" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $OUTPUT_ROOT" >&2
  exit 2
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
# Bundle prefix kept as initial-reimaged-system-* to match the artifact tree
# documented in references/master-directory-reference.md and the pattern that
# bin/reimage-checklist.sh looks for when validating Phase 9 evidence.
OUT="$OUTPUT_ROOT/initial-reimaged-system-$STAMP"
# Approved exception to the validator's no-abort rule: this is the validator
# creating its own report destination, not observing system state. Without the
# bundle directory every later write fails silently and the run would still
# claim "First-boot evidence bundle written".
if ! mkdir -p "$OUT/logs" "$OUT/raw" "$OUT/checks"; then
  echo "ERROR: cannot create the evidence bundle directory: $OUT" >&2
  echo "ERROR: no evidence was written. Choose a writable --output-root (or reconnect the artifact volume) and rerun." >&2
  exit 2
fi

# Pre-create the sibling reimaged-system subfolders when writing to the
# artifact tree so later phases (restore notes, restart notes, Time Machine
# planning) have somewhere to land without extra shell work.
if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" \
      && "$OUTPUT_ROOT" == "$REIMAGE_ARTIFACT_ROOT/reimaged-system" ]]; then
  mkdir -p \
    "$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists" \
    "$REIMAGE_ARTIFACT_ROOT/reimaged-system/time-machine" \
    "$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts" \
    "$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes" 2>/dev/null || true
fi

COMMAND_LOG="$OUT/logs/commands.log"
ERROR_LOG="$OUT/logs/errors.log"
CHECKLIST="$OUT/initial-checklist.md"
SUMMARY="$OUT/README.md"

: > "$COMMAND_LOG"
: > "$ERROR_LOG"

# ---------------------------------------------------------------------------
# Evidence-capture helpers
# ---------------------------------------------------------------------------
log_cmd() {
  printf '%s\n' "$*" >> "$COMMAND_LOG"
}

capture() {
  local name="$1"
  shift
  local target="$OUT/raw/$name.txt"
  {
    echo "# $name"
    echo "# captured: $(date)"
    echo "# command: $*"
    echo ""
    "$@"
  } > "$target" 2>> "$ERROR_LOG" || true
  log_cmd "$* > raw/$name.txt"
}

capture_shell() {
  # Wrap grep-based filters without invoking a login shell so profile output
  # (SDKMAN, direnv chatter, etc.) cannot leak into the recorded evidence.
  # Any arguments after the command string are passed to `bash -c` as "$1",
  # "$2", ... so paths never have to be interpolated into the command text.
  local name="$1"
  local cmd="$2"
  shift 2
  local display="$cmd"
  if [[ $# -gt 0 ]]; then
    display="$cmd -- $*"
  fi
  local target="$OUT/raw/$name.txt"
  {
    echo "# $name"
    echo "# captured: $(date)"
    echo "# command: $display"
    echo ""
    bash -c "$cmd" "$name" "$@"
  } > "$target" 2>> "$ERROR_LOG" || true
  log_cmd "$display > raw/$name.txt"
}

write_text() {
  local name="$1"
  shift
  local target="$OUT/raw/$name.txt"
  {
    echo "# $name"
    echo "# captured: $(date)"
    echo ""
    printf '%s\n' "$*"
  } > "$target"
}

# ---------------------------------------------------------------------------
# Row checkers (PASS/WARN/TODO)
# ---------------------------------------------------------------------------
check_contains_file() {
  local file="$1"
  local pattern="$2"
  if [[ -f "$file" ]] && grep -Eiq "$pattern" "$file"; then
    echo "PASS"
  else
    echo "WARN"
  fi
}

check_dir_exists() {
  if [[ -d "$1" ]]; then echo "PASS"; else echo "TODO"; fi
}

check_any_app() {
  local pattern="$1"
  if ls -1 /Applications 2>/dev/null | grep -Eiq "$pattern"; then
    echo "PASS"
  else
    echo "TODO"
  fi
}

check_process() {
  local pattern="$1"
  if pgrep -fl "$pattern" >/dev/null 2>&1; then
    echo "PASS"
  else
    echo "TODO"
  fi
}

# ---------------------------------------------------------------------------
# Core read-only captures
# ---------------------------------------------------------------------------
capture date            date
capture sw_vers         sw_vers
capture uname           uname -a
capture whoami          whoami
capture hostname        hostname
capture computer-name   scutil --get ComputerName
capture local-host-name scutil --get LocalHostName
capture host-name       scutil --get HostName
capture hardware        system_profiler SPHardwareDataType
capture filevault       fdesetup status
capture profiles-enrollment profiles status -type enrollment
capture profiles-list   profiles list

capture_shell applications-managed \
  "ls -1 /Applications | grep -Ei 'Company Portal|CrowdStrike|Falcon|Zscaler|Microsoft|Teams|Outlook|OneNote|Chrome|Visual Studio Code|IntelliJ|Docker|Postman|Obsidian|Raycast' || true"
capture_shell managed-processes \
  "ps aux | grep -Ei 'Intune|Company Portal|CrowdStrike|falcon|Zscaler|Microsoft AutoUpdate|MAU|OneDrive|mdmclient' | grep -v grep || true"
capture_shell volumes \
  "ls -la /Volumes && echo && df -h"

capture time-machine-destination tmutil destinationinfo
capture_shell time-machine-latest "tmutil latestbackup 2>/dev/null || true"
capture softwareupdate-list      softwareupdate --list

capture_shell brew-version   "command -v brew >/dev/null 2>&1 && brew --version || echo 'brew not installed yet'"
capture_shell git-version    "command -v git  >/dev/null 2>&1 && git  --version || echo 'git not installed yet'"
capture_shell xcode-select   "xcode-select -p 2>/dev/null || echo 'xcode-select path not configured yet'"

if [[ "$RUN_NETWORK" == "true" ]]; then
  capture_shell network-ping      "ping -c 3 github.com"
  capture_shell network-github    "curl -I --max-time 10 https://github.com 2>/dev/null | head -20"
  capture_shell network-microsoft "curl -I --max-time 10 https://login.microsoftonline.com 2>/dev/null | head -20"
else
  write_text network-skipped "Network checks skipped with --no-network."
fi

# Optional artifact-root spot check.
if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  # Pass the artifact root as a positional argument: interpolating it into the
  # command string breaks on a path containing an apostrophe.
  capture_shell artifact-root-spotcheck \
    'find "$1" -maxdepth 2 -type f | sort | head -200' \
    "$REIMAGE_ARTIFACT_ROOT"
else
  write_text artifact-root-missing \
    "REIMAGE_ARTIFACT_ROOT was not provided or does not exist." \
    "Pass --artifact-root PATH after reconnecting the external artifact drive."
fi

# ---------------------------------------------------------------------------
# Compute row verdicts
# ---------------------------------------------------------------------------
MDM_STATUS="$(check_contains_file "$OUT/raw/profiles-enrollment.txt" 'MDM enrollment: Yes|Enrolled via DEP: Yes|User Approved')"
FILEVAULT_STATUS="$(check_contains_file "$OUT/raw/filevault.txt" 'FileVault is On')"
COMPANY_PORTAL_STATUS="$(check_any_app 'Company Portal')"
ZSCALER_STATUS="$(check_any_app 'Zscaler')"
CROWDSTRIKE_APP_STATUS="$(check_any_app 'CrowdStrike|Falcon')"
CROWDSTRIKE_PROC_STATUS="$(check_process 'falcon|CrowdStrike')"
OFFICE_STATUS="$(check_any_app 'Microsoft Outlook|Microsoft Word|Microsoft Excel|Microsoft PowerPoint|Microsoft OneNote')"
ONEDRIVE_STATUS="$(check_any_app 'OneDrive')"
CHROME_STATUS="$(check_any_app 'Google Chrome')"

ARTIFACT_ROOT_STATUS="TODO"
if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  ARTIFACT_ROOT_STATUS="PASS"
fi

# Time Machine destination. The volume label is taken from the configured
# EXTERNAL_APPLE_BACKUPS_VOLUME instead of a hardcoded volume name; artifact-
# config.sh defaults that variable to /Volumes/AppleBackups, so the default
# configuration evaluates exactly the same 'AppleBackups|Name' union this check
# has always used, while a Mac whose backup volume is named something else now
# matches its own volume. The volume name is compared as a fixed string so a
# label containing regex metacharacters cannot corrupt the pattern.
TM_DEST_FILE="$OUT/raw/time-machine-destination.txt"
TM_DEST_STATUS="$(check_contains_file "$TM_DEST_FILE" 'Name')"
if [[ "$TM_DEST_STATUS" != "PASS" && -n "${EXTERNAL_APPLE_BACKUPS_VOLUME:-}" && -f "$TM_DEST_FILE" ]]; then
  if grep -Fiq "$(basename "${EXTERNAL_APPLE_BACKUPS_VOLUME%/}")" "$TM_DEST_FILE"; then
    TM_DEST_STATUS="PASS"
  fi
fi

GIT_STATUS="TODO"
if grep -q "git version" "$OUT/raw/git-version.txt" 2>/dev/null; then
  GIT_STATUS="PASS"
fi

BREW_STATUS="TODO"
if grep -q "Homebrew" "$OUT/raw/brew-version.txt" 2>/dev/null; then
  BREW_STATUS="PASS"
fi

NETWORK_STATUS="INFO"
if [[ "$RUN_NETWORK" == "true" ]]; then
  NETWORK_STATUS="$(check_contains_file "$OUT/raw/network-github.txt" '^HTTP/|HTTP/[0-9]')"
fi

# ---------------------------------------------------------------------------
# Companion planning documents
# ---------------------------------------------------------------------------
cat > "$OUT/restart-checkpoints.md" <<'EOF_RESTART'
# Reimaged System Restart Checkpoints

Use restarts as deliberate stabilization points, not as random troubleshooting.

| Checkpoint | Recommended Action | Status | Notes |
|---|---|---|---|
| After initial Intune / Company Portal enrollment and security tools start appearing | Restart once, then rerun record-reimaged-system.sh | `TODO` | Helps confirm MDM profiles, login items, network filters, and security agents survive reboot. |
| After macOS updates | Restart when prompted, then rerun record-reimaged-system.sh | `TODO` | Required for OS/security updates. |
| After Homebrew, shell, Git, Java, Node, Python, Gradle, Maven, Docker CLI basics | Restart once before heavy repo restore | `TODO` | Helps catch path, shell, Rosetta, Java, and developer-tool setup issues. |
| After Docker Desktop, VPN/Zscaler, certificates, and corporate network access are restored | Restart once before project validation | `TODO` | Helps stabilize network extensions, Docker helpers, and cert trust. |
| After Office, OneDrive, Teams, Chrome, Obsidian, Postman, VS Code, Raycast are installed/configured | Restart once before reimaged-system validation | `TODO` | Helps confirm login items, background services, and managed app registration. |
| After Phase 12 validation passes | Final restart, then capture reimaged-system performance/Office baseline | `TODO` | Produces a cleaner comparison point against the pre-image baseline. |

If Outlook or OneNote closes unexpectedly, capture evidence before restarting or reopening the app.
EOF_RESTART

cat > "$OUT/time-machine-reimaged-system-plan.md" <<'EOF_TM'
# Reimaged System Time Machine Plan

Keep Time Machine backups on the dedicated Apple backups partition ($EXTERNAL_APPLE_BACKUPS_VOLUME when defined). Keep workflow evidence and generated checklists under the artifact-root partition ($EXTERNAL_DATA_VOLUME / $REIMAGE_ARTIFACT_ROOT).

Recommended reimaged-system Time Machine checkpoints:

1. **Clean managed baseline backup** — after Phase 8 completes, after initial Intune / Company Portal enrollment is stable, after required security tools are installed or clearly installing, after macOS updates, and after one restart.
2. **Working development baseline backup** — after Phases 9 through 11 are substantially restored and Phase 12 validation passes.
3. **Normal ongoing backups** — after the machine is back to daily use.

Before starting reimaged-system Time Machine, confirm the artifact volume is excluded so the manual backup directory is not backed up into the Time Machine partition:

```bash
sudo tmutil addexclusion -v "$EXTERNAL_DATA_VOLUME"
tmutil listexclusions | grep "$EXTERNAL_DATA_VOLUME" || true
tmutil destinationinfo
tmutil startbackup
```

Avoid starting a Time Machine backup while OneDrive is still doing a large initial sync, while Docker images are being restored, or while Company Portal / Intune is actively installing large apps.
EOF_TM

cat > "$OUT/manual-captures-required.md" <<'EOF_MANUAL_FIRST_BOOT'
# Manual Captures Required After First Boot

The record-reimaged-system script captures command output and app/process evidence, but these items still require human confirmation.

| Area | Manual Item | Why Manual |
|---|---|---|
| Microsoft 365 / O365 sign-in | Confirm sign-in completed during setup | CLI cannot prove the setup prompt was completed correctly. |
| Company Portal | Confirm device shows registered/compliant in UI | CLI can show enrollment evidence but not the full compliance state. |
| VPN / Zscaler | Confirm real internal sites load | Process/app presence does not prove internal access. |
| OneDrive / iCloud | Confirm sync state is acceptable before restore | CLI cannot reliably prove sync completion. |
| Chrome | Confirm default browser and JSON Formatter/important extensions | Browser settings/extensions are best verified in UI. |
| Terminal | Confirm Ocean profile/window size or chosen profile | CLI cannot prove the UI preference is visually correct. |
| Displays and peripherals | Confirm arrangement, scaling, keyboard, mouse, audio | System information does not prove physical usability. |
| Restart checkpoint | Confirm the second stabilization restart happened | Script can be rerun after restart, but cannot know user intent. |
EOF_MANUAL_FIRST_BOOT

# ---------------------------------------------------------------------------
# Generate the initial checklist and README summary
# ---------------------------------------------------------------------------
sed_escape() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

replace_token() {
  local file="$1"
  local token="$2"
  local value="$3"
  local escaped
  escaped="$(sed_escape "$value")"
  sed -i.bak "s|$token|$escaped|g" "$file" && rm -f "$file.bak"
}

cat > "$CHECKLIST" <<'EOF_CHECKLIST'
# Reimaged System Initial Checklist

Generated: __GENERATED_DATE__

Source script: `__SCRIPT_NAME__`

Output bundle:

~~~text
__OUT__
~~~

## Artifact Policy

| Item | Location |
|---|---|
| Checklist runbook | `verify-reimaged-system.md` |
| Script | `bin/record-reimaged-system.sh` |
| Generated evidence bundle | `__OUTPUT_ROOT__/initial-reimaged-system-YYYYMMDD-HHMMSS/` |
| Preferred generated-artifact root | `__ARTIFACT_ROOT__/reimaged-system/` when the artifact drive is mounted |
| Local fallback if the artifact drive is unavailable | `~/Desktop/reimaged-system-artifacts/` |

Keep active scripts in the toolkit checkout. Store generated evidence, checklist reports, and reimaged-system comparison outputs under the artifact root.

## Automated Checks

| Check | Result | Evidence |
|---|---|---|
| MDM / Intune enrollment appears active | `__MDM_STATUS__` | `raw/profiles-enrollment.txt` |
| FileVault status captured and appears on | `__FILEVAULT_STATUS__` | `raw/filevault.txt` |
| Company Portal app present | `__COMPANY_PORTAL_STATUS__` | `raw/applications-managed.txt` |
| Zscaler app present | `__ZSCALER_STATUS__` | `raw/applications-managed.txt` |
| CrowdStrike/Falcon app present | `__CROWDSTRIKE_APP_STATUS__` | `raw/applications-managed.txt` |
| CrowdStrike/Falcon process present | `__CROWDSTRIKE_PROC_STATUS__` | `raw/managed-processes.txt` |
| Microsoft Office apps present or installing | `__OFFICE_STATUS__` | `raw/applications-managed.txt` |
| OneDrive app present | `__ONEDRIVE_STATUS__` | `raw/applications-managed.txt` |
| Chrome app present | `__CHROME_STATUS__` | `raw/applications-managed.txt` |
| External artifact root visible | `__ARTIFACT_ROOT_STATUS__` | `raw/artifact-root-spotcheck.txt` |
| Time Machine destination captured | `__TM_DEST_STATUS__` | `raw/time-machine-destination.txt` |
| Git available | `__GIT_STATUS__` | `raw/git-version.txt` |
| Homebrew available | `__BREW_STATUS__` | `raw/brew-version.txt` |
| Network check | `__NETWORK_STATUS__` | `raw/network-github.txt` |

## Manual First-Boot Checklist

| Check | Status | Notes |
|---|---|---|
| Mac restarted after erase | `TODO` |  |
| Wi-Fi connected | `TODO` |  |
| Microsoft 365 / O365 sign-in completed | `TODO` |  |
| Company Portal signed in | `TODO` |  |
| Device shows registered / compliant | `TODO` |  |
| Required profiles/certificates visible | `TODO` |  |
| VPN or Zscaler works for internal sites | `TODO` |  |
| Office install left to approved managed channel | `TODO` |  |
| macOS updates checked/applied | `TODO` |  |
| Second stabilization restart completed | `TODO` |  |
| External artifact drive reconnected after enrollment stabilized | `TODO` |  |
| Chrome baseline settings restored | `TODO` |  |
| Terminal baseline settings restored | `TODO` |  |
| Display/keyboard/mouse basics restored | `TODO` |  |
| Ready to move to Phase 10 runtime environment restore | `TODO` |  |

## Recommended Next Actions

1. Review `raw/profiles-enrollment.txt`, `raw/filevault.txt`, and `raw/applications-managed.txt`.
2. Complete the manual checklist above.
3. Restart once after managed enrollment and security tools are stable.
4. Rerun this script after the restart and compare results.
5. Take the first reimaged-system Time Machine backup after Phase 8 is stable, macOS updates are complete, and the first restart has completed.

EOF_CHECKLIST

replace_token "$CHECKLIST" "__GENERATED_DATE__" "$(date)"
replace_token "$CHECKLIST" "__SCRIPT_NAME__" "$SCRIPT_NAME"
replace_token "$CHECKLIST" "__OUT__" "$OUT"
replace_token "$CHECKLIST" "__OUTPUT_ROOT__" "$OUTPUT_ROOT"
replace_token "$CHECKLIST" "__ARTIFACT_ROOT__" "${REIMAGE_ARTIFACT_ROOT:-<unset>}"
replace_token "$CHECKLIST" "__MDM_STATUS__" "$MDM_STATUS"
replace_token "$CHECKLIST" "__FILEVAULT_STATUS__" "$FILEVAULT_STATUS"
replace_token "$CHECKLIST" "__COMPANY_PORTAL_STATUS__" "$COMPANY_PORTAL_STATUS"
replace_token "$CHECKLIST" "__ZSCALER_STATUS__" "$ZSCALER_STATUS"
replace_token "$CHECKLIST" "__CROWDSTRIKE_APP_STATUS__" "$CROWDSTRIKE_APP_STATUS"
replace_token "$CHECKLIST" "__CROWDSTRIKE_PROC_STATUS__" "$CROWDSTRIKE_PROC_STATUS"
replace_token "$CHECKLIST" "__OFFICE_STATUS__" "$OFFICE_STATUS"
replace_token "$CHECKLIST" "__ONEDRIVE_STATUS__" "$ONEDRIVE_STATUS"
replace_token "$CHECKLIST" "__CHROME_STATUS__" "$CHROME_STATUS"
replace_token "$CHECKLIST" "__ARTIFACT_ROOT_STATUS__" "$ARTIFACT_ROOT_STATUS"
replace_token "$CHECKLIST" "__TM_DEST_STATUS__" "$TM_DEST_STATUS"
replace_token "$CHECKLIST" "__GIT_STATUS__" "$GIT_STATUS"
replace_token "$CHECKLIST" "__BREW_STATUS__" "$BREW_STATUS"
replace_token "$CHECKLIST" "__NETWORK_STATUS__" "$NETWORK_STATUS"

cat > "$SUMMARY" <<'EOF_SUMMARY'
# Reimaged System First-Boot Evidence Bundle

Generated: __GENERATED_DATE__

Open first:

- `initial-checklist.md`
- `restart-checkpoints.md`
- `time-machine-reimaged-system-plan.md`
- `manual-captures-required.md`

Raw captures are under `raw/`. Command and error logs are under `logs/`.

This bundle is generated evidence. The runbook source of truth is `verify-reimaged-system.md`; the script source of truth is `bin/record-reimaged-system.sh`.
EOF_SUMMARY

replace_token "$SUMMARY" "__GENERATED_DATE__" "$(date)"

# Plain-text pointer for shell users so `cat latest-...` reveals the most
# recent bundle without a `ls -t | head` dance. Written at the parent level.
# A failed pointer write is not fatal — the bundle above is still valid — but
# it must be reported: a silently stale pointer sends the operator to an older
# bundle, which is exactly the symptom verify-reimaged-system.md troubleshoots.
LATEST_POINTER="$OUTPUT_ROOT/latest-initial-reimaged-system-bundle.txt"
if ! echo "$OUT" > "$LATEST_POINTER" 2>/dev/null; then
  echo "WARNING: could not update the latest-bundle pointer: $LATEST_POINTER" >&2
  echo "WARNING: it may still name an older bundle. Use the bundle path printed below." >&2
fi

echo ""
echo "First-boot evidence bundle written: $OUT"
echo "Open checklist: $CHECKLIST"

if [[ "$OPEN_RESULT" == "true" ]]; then
  open "$OUT" 2>/dev/null || true
fi
