#!/usr/bin/env bash
# =============================================================================
# office-stability-checklist.sh
#
# Office Stability Checklist generator (Phase 4D pre-image / Phase 13E
# post-image). Aggregate validator: it inspects the watcher directory, marker,
# baseline bundles, and live Office/management state, and records every result
# as a PASS / WARN / FAIL / SKIP check into a timestamped checklist bundle under
# office-stability/checklists/ (report .md, README, and per-check evidence
# files). It observes and reports only; it does not create the artifacts it is
# meant to verify. Its findings roll up to the Phase 6B sign-off. See
# capture-office-stability.md, Step 4.
#
# --- BEGIN USAGE ---
# Generate an Office stability checklist bundle for pre-image or post-image use.
#
# Usage:
#   cd <repo-root>
#   chmod +x bin/office-stability-checklist.sh
#
#   # Pre-image checklist
#   ./bin/office-stability-checklist.sh --phase pre-reimage --artifact-root "$REIMAGE_ARTIFACT_ROOT"
#
#   # Post-image checklist, opened when finished
#   ./bin/office-stability-checklist.sh --phase post-reimage --artifact-root "$REIMAGE_ARTIFACT_ROOT" --open
#
# Options:
#   --phase PHASE             One of: pre-reimage, pre-image, post-reimage, post-image.
#                             Default: pre-reimage.
#   --artifact-root PATH      Override REIMAGE_ARTIFACT_ROOT from shared config.
#                             Default: REIMAGE_ARTIFACT_ROOT from reimage.env.
#   --office-watch-dir PATH   Local watcher directory.
#                             Default: OFFICE_WATCH from shared config.
#   --output-root PATH        Output root for the generated checklist bundle.
#                             Default: <artifact-root>/office-stability/checklists,
#                             falling back to <office-watch-dir>/checklists when
#                             no artifact root is set. With neither set and no
#                             --output-root, the run exits 2.
#   --max-log-age-minutes N   Freshness threshold for the latest watcher log.
#                             Default: 30.
#   --no-color                Disable colored terminal output.
#   --open                    Open the generated checklist bundle in Finder.
#   -h, --help                Show this message and exit.
#
# Notes:
#   - Use --phase pre-reimage for the final Office-specific pre-image checklist.
#   - Use --phase post-reimage for the post-image Office comparison checklist.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Exit status:
#   0  Checklist generated with no FAIL checks.
#   1  Checklist generated with one or more FAIL checks.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -uo pipefail
# NOTE: intentionally NOT set -e. This is an aggregate validator/checklist: a
# failing probe must be converted into a PASS/WARN/FAIL/SKIP record rather than
# aborting the run. The final exit status is derived from the FAIL count.

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

# The checklist reports on a missing artifact root rather than failing to load,
# so keep loading permissive. Read by artifact-config.sh through the sourced
# loader below, which is why shellcheck cannot see the use from here.
# shellcheck disable=SC2034
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# A failed config load leaves the artifact root, watcher directory, and marker
# unresolved, so every check below would report on paths that were never
# computed. This is the one place the validator aborts instead of recording a
# row -- same form as reimage-checklist.sh.
# shellcheck source=../.internal/load-reimage-config.sh
if ! source "$CONFIG_LOADER"

RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/artifact-runs.sh
source "$RUNS_LIB"

SIGNOFF_LIB="$REPO_ROOT/.internal/sign-offs.sh"
if [[ ! -f "$SIGNOFF_LIB" ]]; then
  echo "ERROR: shared sign-off helper not found: $SIGNOFF_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/sign-offs.sh
source "$SIGNOFF_LIB"; then
  echo "ERROR: shared reimage configuration could not be loaded." >&2
  exit 2
fi

SCRIPT_NAME="${REIMAGE_SCRIPT_DISPLAY_NAME:-office-stability-checklist.sh}"
PHASE="pre-reimage"
REIMAGE_ARTIFACT_ROOT="${REIMAGE_ARTIFACT_ROOT:-}"
OFFICE_WATCH_DIR="${OFFICE_WATCH_DIR:-${OFFICE_WATCH:-}}"
OUTPUT_ROOT=""
USE_COLOR=true
OPEN_RESULT=false
MAX_LOG_AGE_MINUTES=30

normalize_phase() {
  case "${1:-}" in
    pre|pre-image|preimage|pre-reimage)
      echo "pre-reimage"
      ;;
    post|post-image|postimage|post-reimage)
      echo "post-reimage"
      ;;
    *)
      return 1
      ;;
  esac
}

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
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
    --phase)
      require_option_value "$1" "${2:-}"
      if ! PHASE="$(normalize_phase "$2")"; then
        echo "--phase must be one of: pre-reimage, pre-image, post-reimage, post-image" >&2
        exit 2
      fi
      shift 2
      ;;
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --office-watch-dir)
      require_option_value "$1" "${2:-}"
      OFFICE_WATCH_DIR="$2"
      shift 2
      ;;
    --output-root)
      require_option_value "$1" "${2:-}"
      OUTPUT_ROOT="$2"
      shift 2
      ;;
    --max-log-age-minutes)
      require_option_value "$1" "${2:-}"
      MAX_LOG_AGE_MINUTES="$2"
      if [[ ! "$MAX_LOG_AGE_MINUTES" =~ ^[0-9]+$ ]]; then
        echo "--max-log-age-minutes requires a non-negative integer" >&2
        exit 2
      fi
      shift 2
      ;;
    --no-color)
      USE_COLOR=false
      shift
      ;;
    --open)
      OPEN_RESULT=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$OUTPUT_ROOT" ]]; then
  # With neither value set the watcher-dir fallback would resolve to the
  # absolute path /checklists. Require one of the pair rather than writing the
  # bundle to the filesystem root.
  if [[ -z "$REIMAGE_ARTIFACT_ROOT" && -z "$OFFICE_WATCH_DIR" ]]; then
    echo "ERROR: no output location could be resolved." >&2
    echo "Set REIMAGE_ARTIFACT_ROOT or OFFICE_WATCH (or pass --artifact-root, --office-watch-dir, or --output-root)." >&2
    exit 2
  fi
  # The category root, not a `checklists/` subdirectory. What this writes is an
  # evidence bundle -- system state, process transitions, watcher output, a
  # command log -- with a rendered report on top that is a VIEW of the bundle
  # rather than the artifact. Those are runs, and they belong beside the other
  # runs of this category. `checklists/` is reserved for the two capstone lists
  # that close a whole pre-image or post-image half.
  if [[ -n "$REIMAGE_ARTIFACT_ROOT" ]]; then
    OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/office-stability"
  else
    OUTPUT_ROOT="$OFFICE_WATCH_DIR"
  fi
fi

TS="$(date +%Y%m%d-%H%M%S)"
if [[ "$PHASE" == "pre-reimage" ]]; then
  BANNER_TITLE="Phase 4D -- Office Stability Pre-Image Checklist"
  RUN_SLUG="pre-image-office-stability-checklist"
  REPORT_FILENAME="pre-image-office-stability-checklist.md"
  REPORT_TITLE="Pre-Image Office Stability Checklist Report"
  README_TITLE="Pre-Image Office Stability Checklist Bundle"
  RUN_CONTEXT="pre-image-office-stability-checks"
else
  BANNER_TITLE="Phase 13E -- Office Stability Post-Image Checklist"
  RUN_SLUG="post-image-office-stability-checklist"
  REPORT_FILENAME="post-image-office-stability-checklist.md"
  REPORT_TITLE="Post-Image Office Stability Checklist Report"
  README_TITLE="Post-Image Office Stability Checklist Bundle"
  RUN_CONTEXT="post-image-office-stability-checks"
fi

if ! artifact_run_begin "$OUTPUT_ROOT" "$RUN_CONTEXT"; then
  echo "ERROR: could not stage a run under: $OUTPUT_ROOT" >&2
  exit 2
fi
OUT="$ARTIFACT_RUN_DIR"

cleanup_office_checks_run() {
  artifact_run_abort
  return 0
}
trap cleanup_office_checks_run EXIT
trap 'exit 130' INT TERM
LOG_DIR="$OUT/logs"
WATCHER_DIR="$OUT/watcher"
PROCESS_DIR="$OUT/processes"
SYSTEM_DIR="$OUT/system"
REPORT_FILE="$OUT/$REPORT_FILENAME"
README="$OUT/README.md"
COMMAND_LOG="$LOG_DIR/commands.log"
ERROR_LOG="$LOG_DIR/errors.log"
MARKER="$OFFICE_WATCH_DIR/bundle-watch-start.marker"

mkdir -p "$LOG_DIR" "$WATCHER_DIR" "$PROCESS_DIR" "$SYSTEM_DIR"

if $USE_COLOR && [[ -t 1 ]]; then
  RED='\033[0;31m'
  YELLOW='\033[1;33m'
  GREEN='\033[0;32m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; BOLD=''; RESET=''
fi

PASS=0
WARN=0
FAIL=0
SKIP=0
REPORT=""

append_report() {
  REPORT="${REPORT}${1}"$'\n'
}

record_section() {
  local title="$1"
  printf "\n%b-- %s --%b\n" "$BOLD" "$title" "$RESET"
  append_report ""
  append_report "### ${title}"
  append_report ""
  append_report "| Status | Check | Detail |"
  append_report "|---|---|---|"
}

record_check() {
  local symbol="$1"
  local label="$2"
  local detail="$3"
  local md_icon term_color

  case "$symbol" in
    PASS)
      PASS=$(( PASS + 1 ))
      md_icon="[PASS]"
      term_color="$GREEN"
      ;;
    WARN)
      WARN=$(( WARN + 1 ))
      md_icon="[WARN]"
      term_color="$YELLOW"
      ;;
    FAIL)
      FAIL=$(( FAIL + 1 ))
      md_icon="[FAIL]"
      term_color="$RED"
      ;;
    SKIP)
      SKIP=$(( SKIP + 1 ))
      md_icon="[SKIP]"
      term_color="$RESET"
      ;;
    *)
      symbol="WARN"
      WARN=$(( WARN + 1 ))
      md_icon="[WARN]"
      term_color="$YELLOW"
      ;;
  esac

  printf "  %b[%s]%b %s -- %s\n" "$term_color" "$symbol" "$RESET" "$label" "$detail"
  detail="${detail//|/\\|}"
  label="${label//|/\\|}"
  append_report "| ${md_icon} | ${label} | ${detail} |"
}

# capture_bash NAME SCRIPT [ARG...]
#
# Runs SCRIPT with `bash -c` and records its output as evidence. Values the
# probe needs are passed as positional arguments ("$1", "$2", ...) instead of
# being interpolated into the script text: interpolation breaks on any path
# containing a quote and would let a path influence the command that runs.
# `-c` rather than `-lc` so captured evidence does not depend on whatever the
# operator's login profile happens to set.
capture_bash() {
  local name="$1"
  local script="$2"
  shift 2
  local target
  target="$(target_file "$name")"
  {
    echo "# $name"
    echo "# captured: $(date)"
    echo "# command: bash -c $script"
    if [[ "$#" -gt 0 ]]; then
      echo "# args: $*"
    fi
    echo
    bash -c "$script" _ "$@"
  } > "$target" 2>> "$ERROR_LOG" || true
  if [[ "$#" -gt 0 ]]; then
    printf '%s\n' "bash -c $script _ $* > $(rel_path "$target")" >> "$COMMAND_LOG"
  else
    printf '%s\n' "bash -c $script > $(rel_path "$target")" >> "$COMMAND_LOG"
  fi
}

# Evidence body only: every checked evidence file starts with `# name`,
# `# captured:`, and `# command:` provenance lines, and the command text
# contains the same sentinels the checks below look for. Strip the comment
# header so a check reads the probe's output and not its own command line.
evidence_body() {
  grep -v '^#' "$1" 2>/dev/null || true
}

file_age_minutes() {
  local f="$1"
  if [[ ! -e "$f" ]]; then echo 999999; return; fi
  local now mtime
  now="$(date +%s)"
  mtime="$(stat -f %m "$f" 2>/dev/null || echo 0)"
  # A non-numeric mtime (unreadable file, non-BSD stat) would make the
  # arithmetic below fail and print nothing; an empty age then compares as 0
  # and the log would be recorded "fresh" with a blank age.
  if [[ ! "$mtime" =~ ^[0-9]+$ ]]; then
    mtime=0
  fi
  echo $(( (now - mtime) / 60 ))
}

watcher_running_pids() {
  pgrep -fl "watch-office-today\.sh|bundle-watch-.*\.log|ms-office-stability-watch" 2>/dev/null \
    | grep -E "watch-office-today\.sh|caffeinate .*watch-office-today" \
    | grep -v grep || true
}

target_file() {
  case "$1" in
    marker-timestamp|marker-and-current-time|watcher-running-processes|latest-watcher-log-path|latest-watcher-tail-800|watcher-installer-office-signals)
      printf '%s/%s.txt\n' "$WATCHER_DIR" "$1"
      ;;
    installer-update-management-processes|outlook-onenote-processes|outlook-onenote-process-transitions)
      printf '%s/%s.txt\n' "$PROCESS_DIR" "$1"
      ;;
    office-crash-reports-after-marker|office-bundle-status|install-log-office-events-tail|autoupdate-office-events-tail)
      printf '%s/%s.txt\n' "$SYSTEM_DIR" "$1"
      ;;
    *)
      printf '%s/%s.txt\n' "$OUT" "$1"
      ;;
  esac
}

rel_path() {
  local path="$1"
  printf '%s\n' "${path#"$OUT"/}"
}

printf "\n%b+--------------------------------------------------------------+%b\n" "$BOLD" "$RESET"
printf "%b|  %-58s|%b\n" "$BOLD" "$BANNER_TITLE" "$RESET"
printf "%b+--------------------------------------------------------------+%b\n" "$BOLD" "$RESET"
printf "\n"
printf "  PHASE             : %s\n" "$PHASE"
printf "  ARTIFACT_ROOT     : %s\n" "$REIMAGE_ARTIFACT_ROOT"
printf "  OFFICE_WATCH_DIR  : %s\n" "$OFFICE_WATCH_DIR"
printf "  Report            : %s\n" "$REPORT_FILE"
printf "  Timestamp         : %s\n" "$TS"
printf "\n"

OFFICE_BACKUP="$REIMAGE_ARTIFACT_ROOT/office-stability"

# Counted here, before this run copies its own watcher tail into the watcher
# directory below: the check that reports on it must describe state that
# already existed, not the artifact this run just created.
TAIL_COUNT="$(find "$OFFICE_WATCH_DIR" "$OFFICE_BACKUP" -maxdepth 1 -type f -name 'latest-watcher-after-close-*.txt' 2>/dev/null | wc -l | tr -d ' ')"

record_section "Watcher and Marker"

if [[ -d "$OFFICE_WATCH_DIR" ]]; then
  record_check PASS "Local watcher directory exists" "$OFFICE_WATCH_DIR"
else
  record_check FAIL "Local watcher directory exists" "$OFFICE_WATCH_DIR missing"
fi

WATCHER_RUNNING="$(watcher_running_pids)"
WATCHER_RUNNING_FILE="$(target_file "watcher-running-processes")"
if [[ -n "$WATCHER_RUNNING" ]]; then
  printf '%s\n' "$WATCHER_RUNNING" > "$WATCHER_RUNNING_FILE"
  record_check PASS "Watcher process currently running" "See $(rel_path "$WATCHER_RUNNING_FILE")"
else
  echo "No active watch-office-today.sh process found." > "$WATCHER_RUNNING_FILE"
  record_check WARN "Watcher process currently running" "Not running now; acceptable if test window is complete, but verify latest watcher log"
fi

# `ls -t` for newest-first ordering; watcher log names are script-generated
# and contain no whitespace or newlines.
# shellcheck disable=SC2012
LATEST_WATCH="$(ls -t "$OFFICE_WATCH_DIR"/bundle-watch-*.log 2>/dev/null | head -1 || true)"

if [[ -n "$LATEST_WATCH" && -f "$LATEST_WATCH" ]]; then
  AGE_MIN="$(file_age_minutes "$LATEST_WATCH")"
  LATEST_WATCH_PATH_FILE="$(target_file "latest-watcher-log-path")"
  LATEST_WATCH_TAIL_FILE="$(target_file "latest-watcher-tail-800")"
  printf '%s\n' "$LATEST_WATCH" > "$LATEST_WATCH_PATH_FILE"
  if [[ "$AGE_MIN" -le "$MAX_LOG_AGE_MINUTES" ]]; then
    record_check PASS "Latest watcher log exists and is fresh" "$(basename "$LATEST_WATCH") (${AGE_MIN}m old)"
  else
    record_check WARN "Latest watcher log exists" "$(basename "$LATEST_WATCH") (${AGE_MIN}m old); watcher may have stopped"
  fi
  tail -n 800 "$LATEST_WATCH" > "$LATEST_WATCH_TAIL_FILE" 2>> "$ERROR_LOG" || true
  cp "$LATEST_WATCH_TAIL_FILE" "$OFFICE_WATCH_DIR/latest-watcher-after-close-$TS.txt" 2>/dev/null || true
else
  record_check FAIL "Latest watcher log exists" "No bundle-watch-*.log under $OFFICE_WATCH_DIR"
  echo "No watcher log found." > "$(target_file "latest-watcher-tail-800")"
fi

if [[ -e "$MARKER" ]]; then
  MARKER_AGE_H=$(( $(file_age_minutes "$MARKER") / 60 ))
  MARKER_FILE="$(target_file "marker-timestamp")"
  /usr/bin/stat -f "path=%N modified=%Sm size=%z" -t "%Y-%m-%d %H:%M:%S" "$MARKER" > "$MARKER_FILE" 2>> "$ERROR_LOG" || true
  record_check PASS "Marker timestamp confirmed" "$(tr '\n' ' ' < "$MARKER_FILE")"
  if [[ "$MARKER_AGE_H" -gt 72 ]]; then
    if [[ "$PHASE" == "pre-reimage" ]]; then
      record_check WARN "Marker age" "Marker is ${MARKER_AGE_H}h old; OK for multi-day evidence, but confirm intentional"
    else
      record_check WARN "Marker age" "Marker is ${MARKER_AGE_H}h old; confirm it was intentionally reset after the post-image Office install settled"
    fi
  else
    record_check PASS "Marker age" "Marker is ${MARKER_AGE_H}h old"
  fi
else
  echo "Marker missing: $MARKER" > "$(target_file "marker-timestamp")"
  record_check FAIL "Marker timestamp confirmed" "Missing: $MARKER"
fi

# The single quotes are required: "$1" must reach the child bash, which
# receives the marker path as a positional argument.
# shellcheck disable=SC2016
capture_bash "marker-and-current-time" 'MARKER="$1"; if [[ -e "$MARKER" ]]; then /usr/bin/stat -f "path=%N modified=%Sm size=%z" -t "%Y-%m-%d %H:%M:%S" "$MARKER"; else echo "Marker is missing: $MARKER"; fi; echo; date "+current=%Y-%m-%d %H:%M:%S"' "$MARKER"

record_section "Office Stability Evidence"

if [[ -d "$OFFICE_BACKUP" ]]; then
  record_check PASS "Office stability backup folder exists" "$OFFICE_BACKUP"
else
  record_check FAIL "Office stability backup folder exists" "$OFFICE_BACKUP missing"
fi

if [[ "$PHASE" == "pre-reimage" ]]; then
  BASELINE_DIR="$(find "$OFFICE_BACKUP" -maxdepth 1 -type d -name 'pre-reimage-office-baseline-*' 2>/dev/null | sort | tail -1 || true)"
  if [[ -n "$BASELINE_DIR" ]]; then
    record_check PASS "Pre-reimage Office baseline directory exists" "$(basename "$BASELINE_DIR")"
  else
    record_check WARN "Pre-reimage Office baseline directory exists" "Not found; run capture-office-stability.sh --phase pre-reimage"
  fi

  BASELINE_ZIP="$(find "$OFFICE_BACKUP" -maxdepth 1 -type f -name 'pre-reimage-office-baseline-*.zip' 2>/dev/null | sort | tail -1 || true)"
  if [[ -n "$BASELINE_ZIP" ]]; then
    record_check PASS "Pre-reimage Office baseline ZIP exists" "$(basename "$BASELINE_ZIP")"
  else
    record_check WARN "Pre-reimage Office baseline ZIP exists" "Not found; run capture-office-stability.sh --phase pre-reimage"
  fi
else
  POST_BASELINE_DIR="$(find "$OFFICE_BACKUP" -maxdepth 1 -type d -name 'post-reimage-office-baseline-*' 2>/dev/null | sort | tail -1 || true)"
  if [[ -n "$POST_BASELINE_DIR" ]]; then
    record_check PASS "Post-reimage Office baseline directory exists" "$(basename "$POST_BASELINE_DIR")"
  else
    record_check WARN "Post-reimage Office baseline directory exists" "Not found; run capture-office-stability.sh --phase post-reimage"
  fi

  POST_BASELINE_ZIP="$(find "$OFFICE_BACKUP" -maxdepth 1 -type f -name 'post-reimage-office-baseline-*.zip' 2>/dev/null | sort | tail -1 || true)"
  if [[ -n "$POST_BASELINE_ZIP" ]]; then
    record_check PASS "Post-reimage Office baseline ZIP exists" "$(basename "$POST_BASELINE_ZIP")"
  else
    record_check WARN "Post-reimage Office baseline ZIP exists" "Not found; rerun capture-office-stability.sh --phase post-reimage if a shareable ZIP is needed"
  fi

  PRE_BASELINE_DIR="$(find "$OFFICE_BACKUP" -maxdepth 1 -type d -name 'pre-reimage-office-baseline-*' 2>/dev/null | sort | tail -1 || true)"
  if [[ -n "$PRE_BASELINE_DIR" ]]; then
    record_check PASS "Pre-reimage Office baseline directory exists for comparison" "$(basename "$PRE_BASELINE_DIR")"
  else
    record_check WARN "Pre-reimage Office baseline directory exists for comparison" "Not found; comparison can still proceed, but before/after confidence is reduced"
  fi

  PRE_BASELINE_ZIP="$(find "$OFFICE_BACKUP" -maxdepth 1 -type f -name 'pre-reimage-office-baseline-*.zip' 2>/dev/null | sort | tail -1 || true)"
  if [[ -n "$PRE_BASELINE_ZIP" ]]; then
    record_check PASS "Pre-reimage Office baseline ZIP exists for comparison" "$(basename "$PRE_BASELINE_ZIP")"
  else
    record_check WARN "Pre-reimage Office baseline ZIP exists for comparison" "Not found; only local folder comparison is available"
  fi
fi

SUMMARY_FILE="$(find "$OFFICE_BACKUP" -maxdepth 1 -type f -name 'office-stability-summary-*.md' 2>/dev/null | sort | tail -1 || true)"
if [[ -n "$SUMMARY_FILE" ]]; then
  record_check PASS "Office stability summary exists" "$(basename "$SUMMARY_FILE")"
else
  record_check WARN "Office stability summary exists" "No office-stability-summary-*.md under $OFFICE_BACKUP"
fi

SNAPSHOT_COUNT="$(find "$OFFICE_WATCH_DIR" "$OFFICE_BACKUP" -maxdepth 1 -type f -name 'workload-snapshot-*.txt' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$SNAPSHOT_COUNT" -gt 0 ]]; then
  record_check PASS "Workload snapshots captured" "$SNAPSHOT_COUNT snapshot file(s) found"
else
  record_check WARN "Workload snapshots captured" "None found; run bin/capture-workload-snapshot.sh before/after opening Office"
fi

if [[ "$TAIL_COUNT" -gt 0 ]]; then
  record_check PASS "Latest watcher tail captured" "$TAIL_COUNT tail file(s) found"
else
  record_check WARN "Latest watcher tail captured" "None found; this run writes watcher/latest-watcher-tail-800.txt"
fi

record_section "Live Office Checks"

capture_bash "installer-update-management-processes" "ps -axo pid,ppid,etime,stat,%cpu,%mem,command | egrep '(^|/)(installd|system_installd|appstored|appstoreagent)( |$)|Microsoft AutoUpdate|Microsoft Update Assistant|com\\.microsoft\\.autoupdate|Company Portal|Intune|ManagedClient|mdmclient|jamf|Self Service' | grep -v egrep || echo 'No installer/update/management processes found'"
if evidence_body "$(target_file "installer-update-management-processes")" | grep -q "No installer/update/management processes found"; then
  record_check PASS "Installer/update/management process check captured" "No active processes found at capture time"
else
  record_check WARN "Installer/update/management process check captured" "Active management/update processes found; review processes/installer-update-management-processes.txt"
fi

capture_bash "outlook-onenote-processes" "pgrep -fl 'Microsoft Outlook|Microsoft OneNote' || echo 'No Outlook/OneNote processes'"
if evidence_body "$(target_file "outlook-onenote-processes")" | grep -q "No Outlook/OneNote processes"; then
  record_check WARN "Outlook/OneNote process state captured" "No Outlook/OneNote processes at capture time"
else
  record_check PASS "Outlook/OneNote process state captured" "Review processes/outlook-onenote-processes.txt"
fi

# The single quotes are required: "$1" must reach the child bash, which
# receives the marker path as a positional argument.
# shellcheck disable=SC2016
capture_bash "office-crash-reports-after-marker" 'MARKER="$1"; if [[ -e "$MARKER" ]]; then find "$HOME/Library/Logs/DiagnosticReports" "/Library/Logs/DiagnosticReports" -maxdepth 1 -type f -newer "$MARKER" \( -iname "*Outlook*.ips" -o -iname "*Outlook*.crash" -o -iname "*OneNote*.ips" -o -iname "*OneNote*.crash" \) -print 2>/dev/null | sort; else echo "Marker missing"; fi' "$MARKER"
if ! evidence_body "$(target_file "office-crash-reports-after-marker")" | grep -q "Marker missing" && grep -Ev '^#|^$' "$(target_file "office-crash-reports-after-marker")" >/dev/null 2>&1; then
  record_check WARN "Crash reports after marker checked" "Crash report(s) found; inspect system/office-crash-reports-after-marker.txt"
else
  record_check PASS "Crash reports after marker checked" "No new Outlook/OneNote crash reports listed after marker"
fi

# The single quotes are required: "$1" must reach the child bash, which
# receives the marker path as a positional argument.
# shellcheck disable=SC2016
capture_bash "office-bundle-status" 'MARKER="$1"; for app in "Microsoft Outlook" "Microsoft OneNote" "Microsoft Word" "Microsoft Excel" "Microsoft PowerPoint" "Microsoft Teams"; do APP="/Applications/$app.app"; echo; echo "===== $app ====="; if [[ -d "$APP" ]]; then if [[ -e "$MARKER" && "$APP" -nt "$MARKER" ]]; then echo "CHANGED_AFTER_MARKER: YES"; else echo "CHANGED_AFTER_MARKER: NO"; fi; /usr/bin/stat -f "modified=%Sm path=%N" -t "%Y-%m-%d %H:%M:%S" "$APP" 2>&1 || true; /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist" 2>/dev/null || true; /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP/Contents/Info.plist" 2>/dev/null || true; else echo "MISSING: $APP"; fi; done' "$MARKER"
if evidence_body "$(target_file "office-bundle-status")" | grep -q "CHANGED_AFTER_MARKER: YES"; then
  record_check WARN "Office bundle status captured" "At least one Office bundle changed after marker; review system/office-bundle-status.txt"
else
  record_check PASS "Office bundle status captured" "No Office bundle changes after marker shown at capture time"
fi

record_section "Watcher Log Derivatives"

if [[ -n "${LATEST_WATCH:-}" && -f "$LATEST_WATCH" ]]; then
  awk '
  function emit() {
    state=(outlook?"Outlook":"") (onenote?(outlook?"+":"")"OneNote":"")
    if (state=="") state="none"
    if (ts != "" && state != last) {
      print ts " | " state
      last=state
    }
  }
  /^Timestamp:/ { ts=substr($0,12); next }
  /^=== Outlook\/OneNote processes ===/ { inproc=1; outlook=0; onenote=0; next }
  /^=== / && inproc { emit(); inproc=0; next }
  inproc {
    if ($0 ~ /Microsoft Outlook/) outlook=1
    if ($0 ~ /Microsoft OneNote/) onenote=1
    if ($0 ~ /No Outlook\/OneNote processes/) { outlook=0; onenote=0 }
  }
  END { if (inproc) emit() }
  ' "$LATEST_WATCH" > "$(target_file "outlook-onenote-process-transitions")" 2>> "$ERROR_LOG" || true

  grep -nEi "Timestamp:|forcibly closing|Microsoft 365|Microsoft_365_and_Office|BusinessPro_Installer|Installed \"Microsoft 365|preinstall|postinstall|Outlook|OneNote|appstored|appstoreagent|installd|system_installd|AutoUpdate|Update Assistant|Intune|Company Portal|mdmclient|ManagedClient|MISSING|CHANGED|modified=" "$LATEST_WATCH" \
    | tail -1200 > "$(target_file "watcher-installer-office-signals")" 2>> "$ERROR_LOG" || true

  if [[ -s "$(target_file "outlook-onenote-process-transitions")" ]]; then
    record_check PASS "Outlook/OneNote process transitions extracted" "processes/outlook-onenote-process-transitions.txt"
  else
    record_check WARN "Outlook/OneNote process transitions extracted" "No transitions extracted from latest watcher log"
  fi

  if [[ -s "$(target_file "watcher-installer-office-signals")" ]]; then
    record_check PASS "Watcher Office/update signals extracted" "watcher/watcher-installer-office-signals.txt"
  else
    record_check WARN "Watcher Office/update signals extracted" "No matching signals extracted"
  fi
else
  echo "No watcher log found." > "$(target_file "outlook-onenote-process-transitions")"
  echo "No watcher log found." > "$(target_file "watcher-installer-office-signals")"
  record_check SKIP "Outlook/OneNote process transitions extracted" "Skipped; no watcher log"
  record_check SKIP "Watcher Office/update signals extracted" "Skipped; no watcher log"
fi

capture_bash "install-log-office-events-tail" "grep -Ei 'Microsoft|Office|Outlook|OneNote|Word|Excel|PowerPoint|AutoUpdate|forcibly closing|preinstall|postinstall|Installed|BusinessPro_Installer|Microsoft_365_and_Office' /var/log/install.log 2>/dev/null | tail -500 || true"
capture_bash "autoupdate-office-events-tail" "grep -Ei 'Outlook|OneNote|Word|Excel|PowerPoint|Office|Microsoft 365|AutoUpdate|Update Assistant|forcibly closing|preinstall|postinstall|restore|clone|install|BusinessPro_Installer|Microsoft_365_and_Office' '/Library/Logs/Microsoft/autoupdate.log' 2>/dev/null | tail -800 || true"
record_check PASS "install.log and AutoUpdate tails captured" "system/install-log-office-events-tail.txt, system/autoupdate-office-events-tail.txt"

if [[ "$PHASE" == "post-reimage" ]]; then
  record_section "Comparison Readiness"

  if [[ -n "$PRE_BASELINE_DIR" && -n "$POST_BASELINE_DIR" ]]; then
    record_check PASS "Pre/post baseline folders available for comparison" "$(basename "$PRE_BASELINE_DIR") vs $(basename "$POST_BASELINE_DIR")"
  else
    record_check WARN "Pre/post baseline folders available for comparison" "One side of the before/after pair is missing"
  fi

  if evidence_body "$(target_file "office-bundle-status")" | grep -q "CFBundleShortVersionString" \
    || evidence_body "$(target_file "office-bundle-status")" | grep -Eq '^[0-9]+'; then
    record_check PASS "Office app version evidence captured" "Review system/office-bundle-status.txt"
  else
    record_check WARN "Office app version evidence captured" "Bundle status file exists but version evidence may be incomplete"
  fi
fi

record_section "Backup Hygiene"

if [[ -d "$OFFICE_BACKUP" ]]; then
  SCRIPT_COUNT="$(find "$OFFICE_BACKUP" \( -name '*.sh' -o -name '*.py' \) 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$SCRIPT_COUNT" -eq 0 ]]; then
    record_check PASS "No active scripts copied to office-stability" "Clean"
  else
    record_check WARN "No active scripts copied to office-stability" "$SCRIPT_COUNT script file(s) found; keep scripts in Git repo only"
  fi
else
  record_check SKIP "No active scripts copied to office-stability" "Skipped; office backup dir missing"
fi

# The rows a person answers leave the report.
#
# They used to be `record_check WARN` rows inside the automated table, which made
# them answered rows wearing an automated verdict: they came back as WARN on
# every run however many times they had been answered, because a rerun writes a
# fresh report and nothing carried an answer forward. The sign-off carries them,
# and records which run each was answered against.
if ! signoff_begin "$OUTPUT_ROOT/sign-offs" "$RUN_CONTEXT" "$ARTIFACT_RUN_ID"; then
  echo "ERROR: cannot open a sign-off under: $OUTPUT_ROOT/sign-offs" >&2
  exit 2
fi

if [[ "$PHASE" == "pre-reimage" ]]; then
  signoff_row "IT escalation summary reviewed" "Confirm the Suggested IT Ticket still matches the evidence in this bundle."
  signoff_row "Pre-image conclusion recorded" "Record the current conclusion in capture-office-stability.md or the work log."
  signoff_row "Decision made about reopening Office" "Do not reopen immediately after closure if the evidence window is still needed."
  signoff_row "Evidence bundle ready to send to IT" "Confirm the ZIP and summaries are ready to share."
else
  signoff_row "Managed Office install state reviewed" "Confirm Office came only from the intended managed channel and settled before testing."
  signoff_row "Post-image conclusion recorded" "Record whether the original symptom is gone, unchanged, or still under investigation."
  signoff_row "Normal-use observation completed" "Confirm whether Outlook and OneNote remain open during normal use."
  signoff_row "Evidence bundle ready for IT if symptom recurred" "Confirm the summary, baseline ZIPs, and signal files are ready to share."
fi

cat > "$README" <<EOF_README
# $README_TITLE

Generated: $(date)

Open first:

- \`$REPORT_FILENAME\`
- \`watcher/marker-timestamp.txt\`
- \`watcher/watcher-running-processes.txt\`
- \`watcher/latest-watcher-tail-800.txt\`
- \`system/office-bundle-status.txt\`
- \`system/office-crash-reports-after-marker.txt\`
- \`processes/outlook-onenote-process-transitions.txt\`
- \`watcher/watcher-installer-office-signals.txt\`

This bundle is generated evidence. Keep the source script in the fractogenesis-toolkit repo.
EOF_README

{
  printf "# %s\n\n" "$REPORT_TITLE"
  printf "Generated: \`%s\`\n\n" "$TS"
  printf "| | |\n"
  printf "|---|---|\n"
  printf "| **PHASE** | \`%s\` |\n" "$PHASE"
  printf "| **ARTIFACT_ROOT** | \`%s\` |\n" "$REIMAGE_ARTIFACT_ROOT"
  printf "| **OFFICE_WATCH_DIR** | \`%s\` |\n" "$OFFICE_WATCH_DIR"
  printf "| **MARKER** | \`%s\` |\n" "$MARKER"
  printf "| **PASS** | %d |\n" "$PASS"
  printf "| **WARN** | %d |\n" "$WARN"
  printf "| **FAIL** | %d |\n" "$FAIL"
  printf "| **SKIP** | %d |\n\n" "$SKIP"

  if [[ "$PHASE" == "pre-reimage" ]]; then
    if [[ "$FAIL" -gt 0 ]]; then
      printf "> **[STOP] %d critical failure(s). Resolve these before treating Office evidence as ready for reimage.**\n\n" "$FAIL"
    elif [[ "$WARN" -gt 0 ]]; then
      printf "> **[WARN] %d warning(s). Review them before proceeding.**\n\n" "$WARN"
    else
      printf "> **[OK] Office stability evidence checklist passed.**\n\n"
    fi
  else
    if [[ "$FAIL" -gt 0 ]]; then
      printf "> **[STOP] %d critical failure(s). Resolve these before treating the post-image Office comparison as ready.**\n\n" "$FAIL"
    elif [[ "$WARN" -gt 0 ]]; then
      printf "> **[WARN] %d warning(s). Review them before closing the post-image Office stability step.**\n\n" "$WARN"
    else
      printf "> **[OK] Post-image Office stability evidence checklist passed.**\n\n"
    fi
  fi

  printf "%s\n" "---"
  printf "%s\n" "$REPORT"
  printf "%s\n" "---"
  printf "\n## Manual Completion Template\n\n"
  if [[ "$PHASE" == "pre-reimage" ]]; then
    cat <<'EOF_TEMPLATE'
Copy this block into the generated bundle or your work log after review:

```text
Pre-Image Office Stability Sign-Off — YYYY-MM-DD

Watcher and marker:
  [ ] Marker timestamp confirmed
  [ ] Watcher was running during the intended test window or latest watcher log reviewed
  [ ] Latest watcher log tail reviewed

Evidence:
  [ ] Baseline workload snapshot reviewed
  [ ] Crash reports after marker reviewed
  [ ] Office bundle status reviewed
  [ ] Outlook/OneNote process transitions reviewed
  [ ] install.log / AutoUpdate / watcher signals reviewed
  [ ] Pre-reimage baseline directory and ZIP copied to office-stability/
  [ ] No active scripts copied to external backup drive

Conclusion:
  [ ] Current preimage conclusion recorded
  [ ] IT ticket summary updated if evidence changed
  [ ] Safe to proceed with reimage from Office evidence perspective

Completed by: TODO
Date: YYYY-MM-DD
```
EOF_TEMPLATE
  else
    cat <<'EOF_TEMPLATE'
Copy this block into the generated bundle or your work log after review:

```text
Post-Image Office Stability Sign-Off — YYYY-MM-DD

Setup state:
  [ ] Initial Intune / Company Portal setup complete
  [ ] Office installed from the approved managed channel only
  [ ] Microsoft AutoUpdate / Intune / Company Portal activity appears settled
  [ ] Fresh watcher marker set after Office installation settled

Watcher and evidence:
  [ ] Marker timestamp confirmed
  [ ] Watcher was running during the intended test window or latest watcher log reviewed
  [ ] Post-reimage baseline directory and ZIP reviewed
  [ ] Crash reports after marker reviewed
  [ ] Office bundle status reviewed
  [ ] Outlook/OneNote process transitions reviewed
  [ ] install.log / AutoUpdate / watcher signals reviewed

Comparison to pre-image:
  [ ] Pre-reimage baseline available for comparison
  [ ] Office app versions compared
  [ ] Office bundle modified dates compared
  [ ] Confirmed whether the same issue is gone, unchanged, or regressed

Conclusion:
  [ ] Outlook remains open during normal use
  [ ] OneNote remains open during normal use
  [ ] If issue recurred, evidence bundle is ready for IT

Completed by: TODO
Date: YYYY-MM-DD
```
EOF_TEMPLATE
  fi
  printf "\n---\n"
  printf "\n*Report generated by \`%s\` at %s*\n" "$SCRIPT_NAME" "$TS"
} > "$REPORT_FILE"

trap - EXIT INT TERM
if ! artifact_run_finalize "$OUTPUT_ROOT" "$PASS pass / $WARN warn / $FAIL fail / $SKIP skip"; then
  echo "ERROR: the bundle was written but could not be indexed under: $OUTPUT_ROOT" >&2
  echo "Repair the index with: ./bin/reindex-artifact-runs.sh --category \"$OUTPUT_ROOT\"" >&2
  exit 2
fi
OUT="$ARTIFACT_RUN_FINAL_DIR"
REPORT_FILE="$OUT/$REPORT_FILENAME"
signoff_finalize "$PHASE" "$REPORT_FILE"

printf "\n"
printf "%b+--------------------------------------------------------------+%b\n" "$BOLD" "$RESET"
printf "%b|  Summary                                                     |%b\n" "$BOLD" "$RESET"
printf "%b+--------------------------------------------------------------+%b\n" "$BOLD" "$RESET"
printf "\n"
printf "  %bPASS%b : %d\n" "$GREEN" "$RESET" "$PASS"
printf "  %bWARN%b : %d\n" "$YELLOW" "$RESET" "$WARN"
printf "  %bFAIL%b : %d\n" "$RED" "$RESET" "$FAIL"
printf "  SKIP : %d\n" "$SKIP"
printf "\n"
printf "  Report written to:\n  %s\n\n" "$REPORT_FILE"
printf "  Rows you answer:\n  %s\n\n" "$SIGNOFF_FILE"

if [[ "$OPEN_RESULT" == "true" ]]; then
  open "$OUT" 2>/dev/null || true
fi

[[ "$FAIL" -eq 0 ]]
