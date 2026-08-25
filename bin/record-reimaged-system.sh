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
#   # Label the run so the two bundles around the stabilization restart are
#   # distinguishable on disk without opening them. Matches the --context
#   # convention already used by report-loose-secrets.sh.
#   ./bin/record-reimaged-system.sh --context pre-restart     # Step 2
#   ./bin/record-reimaged-system.sh --context post-restart    # Step 5
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --output-root PATH    Parent directory that will hold the timestamped
#                         first-boot bundle. Overrides the default layout.
#   --context LABEL       Prefix the bundle directory name with LABEL:
#                         LABEL-initial-reimaged-system-YYYYMMDD-HHMMSS.
#                         Conventional values are pre-restart and post-restart.
#                         Letters, digits, dot, underscore, and hyphen only.
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
# Bundle naming:
#   [LABEL-]initial-reimaged-system-YYYYMMDD-HHMMSS
#
#   The label leads, matching post-image-performance-audit-*, post-reimage-*,
#   and the pre-image-* repo-audit runs. bin/reimage-checklist.sh therefore
#   globs *initial-reimaged-system-* when validating Phase 9 evidence.
#
#   Because the label precedes the timestamp, directory names no longer sort
#   chronologically once more than one label is in play: post-restart sorts
#   before pre-restart regardless of when each ran. Select a "latest" record
#   by modification time, or glob one label at a time, rather than sorting the
#   mixed set lexically.
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

# Shared run index. The first-boot bundles are indexed runs under
# reimaged-system/restarts/ rather than directories at the reimaged-system/
# root, so this script brackets its work with artifact_run_begin / finalize the
# way the boundary recorders and the comparison do.
RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/artifact-runs.sh
source "$RUNS_LIB"

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
CONTEXT_LABEL=""

# Validate a --context label before it becomes part of a directory name. A label
# carrying a slash, a space, or a quote produces either a nested path or a name
# that later globs and `cp` invocations mishandle, so reject it outright rather
# than silently rewriting what the operator typed. The character class is a
# POSIX `case` glob rather than a regex so this behaves identically on the
# stock macOS Bash 3.2.
validate_context() {
  local value="$1"
  case "$value" in
    "")
      return 0
      ;;
    *[!A-Za-z0-9._-]*)
      echo "ERROR: --context may contain only letters, digits, dot, underscore, and hyphen: $value" >&2
      echo "HINT:  the label becomes part of the bundle directory name." >&2
      exit 2
      ;;
    -*)
      echo "ERROR: --context may not begin with a hyphen: $value" >&2
      exit 2
      ;;
  esac
}

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
    --context)
      require_option_value "$1" "${2:-}"
      validate_context "$2"
      CONTEXT_LABEL="$2"
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
# The context label leads the directory name:
# pre-restart-initial-reimaged-system-YYYYMMDD-HHMMSS. This matches the
# convention already used by post-image-performance-audit-*, post-reimage-*,
# and the pre-image-* repo-audit runs, where the phase or context comes first.
#
# Two consequences for anything that reads these bundles back:
#   - the artifact name is no longer at the start, so globs need a leading
#     wildcard: *initial-reimaged-system-* rather than initial-reimaged-system-*;
#   - names group by label before timestamp, so a "latest bundle" lookup must
#     rank on the trailing stamp and never on a plain lexical sort.
# The stamp stays at the end of the name, which is what reimage-checklist.sh
# extracts to compare bundle age against the Time Machine backup.
# The context label becomes the run's POINT. `pre-restart` and `post-restart`
# are both points the run index already knows, so `--context pre-restart` lands
# in the pre-restart lineage with no further mapping. A run with no context gets
# `initial`, which is NOT a known point and therefore indexes as `unknown` --
# the honest answer, since nothing recorded which side of a restart it was on.
RUN_CATEGORY_ROOT="$OUTPUT_ROOT/restarts"
RUN_CONTEXT="verify-reimaged-system-${CONTEXT_LABEL:-initial}"

# Approved exception to the validator's no-abort rule: this is the validator
# creating its own report destination, not observing system state. Without the
# bundle directory every later write fails silently and the run would still
# claim "First-boot evidence bundle written".
if ! artifact_run_begin "$RUN_CATEGORY_ROOT" "$RUN_CONTEXT"; then
  echo "ERROR: cannot stage an evidence run under: $RUN_CATEGORY_ROOT" >&2
  echo "ERROR: no evidence was written. Choose a writable --output-root (or reconnect the artifact volume) and rerun." >&2
  exit 2
fi
OUT="$ARTIFACT_RUN_DIR"

# `checks/` is deliberately absent. All six migrated bundles carried one and
# every one was empty -- nothing has ever written into it. See the
# "Before adding a directory" rule in script-types-and-locations.md.
if ! mkdir -p "$OUT/logs" "$OUT/raw"; then
  echo "ERROR: cannot create the evidence bundle directory: $OUT" >&2
  artifact_run_abort
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
CHECKLIST="$OUT/checklist.md"
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

# Look one level deep as well as at the top of /Applications. Agents such as
# Zscaler install as /Applications/Zscaler/Zscaler.app, and a top-level listing
# alone matches only the enclosing folder — which an empty leftover directory
# would also satisfy.
check_any_app() {
  local pattern="$1"
  local listing
  # Build the listing first, then match against a here-string. Piping into
  # `grep -q` is unsafe under `set -o pipefail`: grep exits on the first match,
  # the upstream `ls` takes SIGPIPE, and the pipeline reports failure even
  # though the pattern matched. That race is size-dependent, so it surfaces as
  # an intermittent TODO on an app that is plainly installed.
  listing="$( { ls -1 /Applications 2>/dev/null; \
                ls -1d /Applications/*/*.app 2>/dev/null \
                  | sed 's#^/Applications/##'; } || true )"
  if grep -Eiq "$pattern" <<< "$listing"; then
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

# Record every application plus one level of nesting rather than a vendor-name
# filter. A filter can only confirm what someone thought to list, so an app this
# Mac was assigned but nobody anticipated is invisible in the evidence. The full
# list is also what makes the pre/post-restart bundle diff meaningful.
capture_shell applications-managed \
  "{ ls -1 /Applications 2>/dev/null; ls -1d /Applications/*/*.app 2>/dev/null | sed 's#^/Applications/##'; } | sort -u"
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

# Not TODO: Phase 10A installs these, so their absence here is the expected
# state rather than operator action, and a TODO row that no step in this phase
# can clear teaches the reader to ignore TODO. Presence is still worth
# recording -- Xcode Command Line Tools supplies git, so it can legitimately
# appear before Phase 10A runs.
GIT_STATUS="INFO"
if grep -q "git version" "$OUT/raw/git-version.txt" 2>/dev/null; then
  GIT_STATUS="PASS"
fi

BREW_STATUS="INFO"
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
| After Intune / Company Portal enrollment **and** the managed app set is installed from the Company Portal Apps tab (Phase 8 Step 4) | Restart once, then rerun record-reimaged-system.sh | `TODO` | Helps confirm MDM profiles, login items, network filters, security agents, and managed app registration survive reboot. Managed apps belong here, not later — installing them after the first bundle fills the Phase 9 diff with spurious rows. |
| After macOS updates | Restart when prompted, then rerun record-reimaged-system.sh | `TODO` | Required for OS/security updates. |
| After Homebrew, shell, Git, Java, Node, Python, Gradle, Maven, Docker CLI basics | Restart once before heavy repo restore | `TODO` | Helps catch path, shell, Rosetta, Java, and developer-tool setup issues. |
| After Docker Desktop, VPN/Zscaler, certificates, and corporate network access are restored | Restart once before project validation | `TODO` | Helps stabilize network extensions, Docker helpers, and cert trust. |
| After the non-managed apps are installed/configured — Obsidian, Postman, VS Code, Raycast, Docker Desktop | Restart once before reimaged-system validation | `TODO` | Helps confirm login items and background services. Managed apps (Office, Teams, OneDrive, Chrome) are **not** installed here; they arrive in Phase 8 via Company Portal. |
| After Phase 12 validation passes | Final restart, then capture reimaged-system performance/Office baseline | `TODO` | Produces a cleaner comparison point against the pre-image baseline. |

If Outlook or OneNote closes unexpectedly, capture evidence before restarting or reopening the app.

Do not restart while a Company Portal install, a Microsoft AutoUpdate download,
or a large OneDrive initial sync is in flight. A restart taken mid-install
produces a bundle that reads as a regression when nothing regressed.
EOF_RESTART

cat > "$OUT/time-machine-plan.md" <<'EOF_TM'
# Reimaged System Time Machine Plan

Nothing in this file runs during Phase 9. The post-image Time Machine backup is
Phase 16, taken after Phase 15 — Restore Home, and owned by `run-time-machine.md`.
These are the notes to carry into it.

Keep Time Machine backups on the dedicated Apple backups partition ($EXTERNAL_APPLE_BACKUPS_VOLUME when defined). Keep workflow evidence and generated checklists under the artifact-root partition ($EXTERNAL_DATA_VOLUME / $REIMAGE_ARTIFACT_ROOT).

Recommended reimaged-system Time Machine checkpoints:

1. **First post-image backup (Phase 16)** — after Phase 15 — Restore Home
   completes. This is the first backup of the rebuilt Mac and the one that
   matters; everything before it would capture a machine holding nothing that
   re-enrolling could not reproduce.
2. **Normal ongoing backups** — after the machine is back to daily use.

Until Phase 16 runs, the pre-image Time Machine chain is still the fallback.
Check free space before starting: Time Machine thins oldest-first, so a rebuilt
system added to the same destination can silently delete that chain.

Before starting reimaged-system Time Machine, the artifact volume MUST be confirmed
excluded. This is a gate, not a note: if the exclusion did not take, Time Machine
backs the entire manual backup directory into the Time Machine partition. The block
below refuses to start a backup unless `tmutil isexcluded` reports `[Excluded]`.

EOF_TM

# The exclusion gate is appended separately from the quoted heredoc above so the
# artifact volume resolved at capture time is baked into the generated plan. A
# quoted heredoc emits "$EXTERNAL_DATA_VOLUME" literally, and pasting that into a
# shell that has not sourced reimage.env hands `addexclusion` an empty argument --
# a silent no-op immediately followed by a full backup of the artifact drive. The
# resolved value is written as a defaulted assignment, and the gate still refuses
# to run if that value is empty or the exclusion does not verify.
{
  echo '```bash'
  printf 'EXTERNAL_DATA_VOLUME="${EXTERNAL_DATA_VOLUME:-%s}"\n' "${EXTERNAL_DATA_VOLUME:-}"
  cat <<'EOF_TM_GATE'
if [ -z "$EXTERNAL_DATA_VOLUME" ]; then
  echo "REFUSING: EXTERNAL_DATA_VOLUME is empty; set it before starting Time Machine." >&2
else
  sudo tmutil addexclusion -v "$EXTERNAL_DATA_VOLUME"
  if tmutil isexcluded "$EXTERNAL_DATA_VOLUME" | grep -q '\[Excluded\]'; then
    tmutil destinationinfo
    tmutil startbackup
  else
    echo "REFUSING: $EXTERNAL_DATA_VOLUME is not excluded from Time Machine." >&2
    echo "REFUSING: not starting a backup that would include the artifact drive." >&2
  fi
fi
EOF_TM_GATE
  echo '```'
} >> "$OUT/time-machine-plan.md"

cat >> "$OUT/time-machine-plan.md" <<'EOF_TM_TAIL'

Avoid starting a Time Machine backup while OneDrive is still doing a large initial sync, while Docker images are being restored, or while Company Portal / Intune is actively installing large apps.
EOF_TM_TAIL

cat > "$OUT/manual-captures-required.md" <<'EOF_MANUAL_FIRST_BOOT'
# Manual Captures Required After First Boot

The record-reimaged-system script captures command output and app/process evidence, but these items still require human confirmation.

**Fill these in the post-restart bundle only.** Each run of the script
regenerates `checklist.md` with every manual row reset, so answers
written into the pre-restart bundle are discarded by the next run. The
post-restart bundle is the sign-off bundle; its rows are answered in
`verify-reimaged-system.md` Step 7. Note in particular that the restart row
cannot be answered truthfully in a pre-restart bundle.

| Area | Manual Item | Why Manual |
|---|---|---|
| Microsoft 365 / O365 sign-in | Confirm sign-in completed during setup | CLI cannot prove the setup prompt was completed correctly. |
| Company Portal | Confirm device shows registered/compliant in UI | CLI can show enrollment evidence but not the full compliance state. |
| VPN / Zscaler | Confirm real internal sites load | Process/app presence does not prove internal access. |
| Managed app set | Confirm everything installed in Phase 8 Step 4 is still present, including nested bundles | Presence is scripted; whether the set is *complete for this Mac* is a Company Portal judgment. |
| OneDrive | Confirm the app is present. Sign-in and initial sync are deliberately deferred | Starting a large sync here collides with the Phase 9 restart, and the ordering against the Phase 15 home-file restore is not settled. |
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

Context: `__CONTEXT__`

Output bundle:

~~~text
__OUT__
~~~

## Artifact Policy

| Item | Location |
|---|---|
| Checklist runbook | `verify-reimaged-system.md` |
| Script | `bin/record-reimaged-system.sh` |
| Generated evidence bundle | `__OUTPUT_ROOT__/[context-]initial-reimaged-system-YYYYMMDD-HHMMSS/` |
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
| Microsoft Office apps present (Phase 8 Step 4) | `__OFFICE_STATUS__` | `raw/applications-managed.txt` |
| OneDrive app present (sign-in deliberately deferred) | `__ONEDRIVE_STATUS__` | `raw/applications-managed.txt` |
| Chrome app present | `__CHROME_STATUS__` | `raw/applications-managed.txt` |
| External artifact root visible | `__ARTIFACT_ROOT_STATUS__` | `raw/artifact-root-spotcheck.txt` |
| Time Machine destination captured | `__TM_DEST_STATUS__` | `raw/time-machine-destination.txt` |
| Git available (installed in Phase 10A) | `__GIT_STATUS__` | `raw/git-version.txt` |
| Homebrew available (installed in Phase 10A) | `__BREW_STATUS__` | `raw/brew-version.txt` |
| Network check | `__NETWORK_STATUS__` | `raw/network-github.txt` |

## Manual First-Boot Checklist

> Fill these in the **post-restart** bundle only. A rerun regenerates this file
> and resets every row, so answers written into a pre-restart bundle are lost.
> See `verify-reimaged-system.md` Step 7.

| Check | Status | Notes |
|---|---|---|
| Mac restarted after erase | `TODO` |  |
| Wi-Fi connected | `TODO` |  |
| Microsoft 365 / O365 sign-in completed | `TODO` |  |
| Company Portal signed in | `TODO` |  |
| Device shows registered / compliant | `TODO` |  |
| Required profiles/certificates visible | `TODO` |  |
| VPN or Zscaler works for internal sites | `TODO` |  |
| Managed app set installed from the Company Portal Apps tab (Phase 8 Step 4) | `TODO` |  |
| macOS updates checked/applied | `TODO` |  |
| Second stabilization restart completed | `TODO` |  |
| External artifact drive reconnected after enrollment stabilized | `TODO` |  |
| Chrome baseline settings restored | `TODO` |  |
| Terminal baseline settings restored | `TODO` |  |
| Display/keyboard/mouse basics restored | `TODO` |  |
| Ready to move to Phase 10 runtime environment restore | `TODO` |  |

## Recommended Next Actions

1. Review `raw/profiles-enrollment.txt`, `raw/filevault.txt`, and `raw/applications-managed.txt`.
2. If any automated row above reads `TODO` for a managed app, finish
   `enroll-and-stabilize.md` Step 4 and rerun this script **before** restarting —
   this bundle is the pre-restart baseline the comparison depends on.
3. Restart once after managed enrollment, the managed app set, and security tools are all stable.
4. Rerun this script after the restart, compare results, and complete the manual checklist in that newer bundle.
5. Do **not** take a Time Machine backup here. The post-image backup is Phase 16,
   after Phase 15 restores your home directory — a backup taken now would capture
   a machine holding nothing that re-enrolling could not reproduce, and would miss
   the home files entirely. Until then the pre-image Time Machine chain is the
   fallback.

EOF_CHECKLIST

replace_token "$CHECKLIST" "__GENERATED_DATE__" "$(date)"
replace_token "$CHECKLIST" "__SCRIPT_NAME__" "$SCRIPT_NAME"
replace_token "$CHECKLIST" "__CONTEXT__" "${CONTEXT_LABEL:-(none supplied)}"
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

- `checklist.md`
- `restart-checkpoints.md`
- `time-machine-plan.md`
- `manual-captures-required.md`

Raw captures are under `raw/`. Command and error logs are under `logs/`.

This bundle is generated evidence. The runbook source of truth is `verify-reimaged-system.md`; the script source of truth is `bin/record-reimaged-system.sh`.
EOF_SUMMARY

replace_token "$SUMMARY" "__GENERATED_DATE__" "$(date)"

# Index the run. The `latest-initial-reimaged-system-bundle.txt` pointer this
# script used to write is gone: one pointer cannot name three lineages --
# initial, pre-restart, post-restart -- and naming whichever ran last is
# precisely the bug that made verify-reimaged-system.md Step 6 hand-roll its own
# prefix-filtered selection. `official/<context>.txt` answers per lineage.
RUN_PASS="$(grep -c '`PASS`' "$CHECKLIST" 2>/dev/null || true)"
RUN_WARN="$(grep -c '`WARN`' "$CHECKLIST" 2>/dev/null || true)"
RUN_TODO="$(grep -c '`TODO`' "$CHECKLIST" 2>/dev/null || true)"

if ! artifact_run_finalize "$RUN_CATEGORY_ROOT" \
     "${RUN_PASS:-0} pass / ${RUN_WARN:-0} warn / ${RUN_TODO:-0} todo"; then
  echo "ERROR: the bundle was written but artifact-runs reported a problem indexing it — see above." >&2
  exit 2
fi
# finalize promotes the staging directory, so the paths must be re-derived.
OUT="$ARTIFACT_RUN_DIR"
CHECKLIST="$OUT/checklist.md"

echo ""
echo "First-boot evidence bundle written: $OUT"
echo "Open checklist: $CHECKLIST"
echo "Run indexed at: $RUN_CATEGORY_ROOT/MANIFEST.md"

if [[ "$OPEN_RESULT" == "true" ]]; then
  open "$OUT" 2>/dev/null || true
fi
