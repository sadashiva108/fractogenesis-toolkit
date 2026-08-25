#!/usr/bin/env bash
# =============================================================================
# reimage-checklist.sh
#
# Unified validation checklist for both the pre-image reimage-prep-checks
# (Phase 6B) and post-image reimaged-system (Phase 14) Mac reimage workflow
# stages. It backs two runbooks: reimage-prep-checks.md (--phase pre) and
# reimaged-system-checks.md (--phase post).
#
# This file is intended for bin/. It is an AGGREGATE VALIDATOR: it observes and
# records state, converting every failed command into a PASS/WARN/FAIL/SKIP row
# instead of aborting. It creates only its own report destination and never
# creates the artifacts it is supposed to verify.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/reimage-checklist.sh
#
#   # Phase 6B -- final reimage-prep-checks validation
#   ./bin/reimage-checklist.sh --phase pre
#
#   # Phase 14 -- final reimaged-system validation
#   ./bin/reimage-checklist.sh --phase post
#
#   # Override config-backed paths
#   ./bin/reimage-checklist.sh \
#     --phase post \
#     --artifact-root /path/to/reimage-artifact-root \
#     --external-data-volume /path/to/external-data-volume \
#     --workspace-root /path/to/work-repositories \
#     --workspace-root /path/to/personal-repositories
#
#   # Open output in Finder after run
#   ./bin/reimage-checklist.sh --phase post --open
#
# Options:
#   --phase pre|post            Required. Which checklist to run.
#   --artifact-root PATH        Override REIMAGE_ARTIFACT_ROOT from reimage.env.
#   --external-data-volume PATH Override EXTERNAL_DATA_VOLUME from reimage.env.
#   --output-root PATH          Override where the report bundle is written.
#                               Default: $REIMAGE_ARTIFACT_ROOT/reimage-prep-checks          (pre)
#                                        $REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists  (post)
#   --workspace-root PATH       Workspace root to scan for Git repo status.
#                               Can be repeated. (post only)
#                               Default: configured GIT_WORK_REPO_ROOT and
#                                        GIT_PERSONAL_REPO_ROOT when set.
#   --onedrive-root PATH        Override ONEDRIVE_ROOT from reimage.env. (post only)
#   --internal-url URL          Optional internal URL to verify VPN/network. (post only)
#   --no-color                  Disable colored terminal output.
#   --open                      Open the output directory in Finder after run.
#   -h, --help                  Show this message and exit.
#
# Configuration precedence:
#   1. Command-line options
#   2. Already-exported environment values
#   3. reimage.env
#   4. artifact-config.sh defaults
#
# Exit status:
#   0  Checklist completed with no FAIL items.
#   1  One or more FAIL items were recorded.
#   2  Invalid arguments or required configuration could not be loaded.
# --- END USAGE ---
# =============================================================================

set -uo pipefail
# NOTE: intentionally NOT set -e. Arithmetic and checks that return non-zero
# must not abort the script; every check must produce a PASS/WARN/FAIL line.

# ── Locate repo and load shared reimage config ────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"
if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi

# Keep loading permissive: --artifact-root is parsed AFTER the loader runs, so
# an empty REIMAGE_ARTIFACT_ROOT must not fail config load. The resolved value
# is validated below, once option parsing is complete.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
if ! source "$CONFIG_LOADER"; then
  echo "ERROR: shared reimage configuration could not be loaded." >&2
  exit 2
fi

# Shared run index. The post branch resolves indexed evidence through
# artifact_run_official rather than globbing directory names, because the
# first-boot bundles now live at reimaged-system/restarts/runs/ under the run
# grammar and a name-shaped glob can neither find them nor say which lineage it
# wanted.
RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/artifact-runs.sh
source "$RUNS_LIB"
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_NAME="${REIMAGE_SCRIPT_DISPLAY_NAME:-reimage-checklist.sh}"
PHASE=""
OUTPUT_ROOT=""
OPEN_RESULT=false
USE_COLOR=true
WORKSPACE_ROOTS=()
INTERNAL_URL=""

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

append_unique_workspace_root() {
  local candidate="$1"
  local existing

  [[ -n "$candidate" ]] || return 0

  # Guard the expansion: on stock macOS Bash 3.2, "${arr[@]}" on an EMPTY array
  # is an unbound-variable error under `set -u`, which would abort this script
  # on the very first --workspace-root value.
  if (( ${#WORKSPACE_ROOTS[@]} > 0 )); then
    for existing in "${WORKSPACE_ROOTS[@]}"; do
      [[ "$existing" == "$candidate" ]] && return 0
    done
  fi

  WORKSPACE_ROOTS+=("$candidate")
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)
      require_option_value "$1" "${2:-}"
      PHASE="$2"
      shift 2
      ;;
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --external-data-volume)
      require_option_value "$1" "${2:-}"
      EXTERNAL_DATA_VOLUME="${2%/}"
      shift 2
      ;;
    --output-root)
      require_option_value "$1" "${2:-}"
      OUTPUT_ROOT="$2"
      shift 2
      ;;
    --workspace-root)
      require_option_value "$1" "${2:-}"
      append_unique_workspace_root "${2%/}"
      shift 2
      ;;
    --onedrive-root)
      require_option_value "$1" "${2:-}"
      ONEDRIVE_ROOT="${2%/}"
      shift 2
      ;;
    --internal-url)
      require_option_value "$1" "${2:-}"
      INTERNAL_URL="$2"
      shift 2
      ;;
    --no-color)
      USE_COLOR=false
      shift
      ;;
    --open)
      OPEN_RESULT="true"
      shift
      ;;
    -h|--help)
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

# ---------------------------------------------------------------------------
# Validate required args
# ---------------------------------------------------------------------------
if [[ -z "$PHASE" ]]; then
  echo "ERROR: --phase pre|post is required." >&2
  usage >&2
  exit 2
fi

case "$PHASE" in
  pre|post) ;;
  *)
    echo "ERROR: --phase must be 'pre' or 'post', got: '$PHASE'" >&2
    exit 2
    ;;
esac

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set. Configure reimage.env or pass --artifact-root PATH." >&2
  exit 2
fi

if [[ -z "${EXTERNAL_DATA_VOLUME:-}" ]]; then
  echo "ERROR: EXTERNAL_DATA_VOLUME is not set. Configure reimage.env or pass --external-data-volume PATH." >&2
  exit 2
fi

REIMAGE_ARTIFACT_ROOT="${REIMAGE_ARTIFACT_ROOT%/}"
EXTERNAL_DATA_VOLUME="${EXTERNAL_DATA_VOLUME%/}"

# ---------------------------------------------------------------------------
# Output paths
# ---------------------------------------------------------------------------
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

if [[ -z "$OUTPUT_ROOT" ]]; then
  if [[ "$PHASE" == "pre" ]]; then
    OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks"
  else
    OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists"
  fi
fi

REPORT_FILE="$OUTPUT_ROOT/reimage-checklist-${TIMESTAMP}.md"
if [[ -z "$OUTPUT_ROOT" ]]; then
  echo "ERROR: output root resolved to an empty path; refusing to write the checklist." >&2
  exit 2
fi
# Unchecked, a read-only or unwritable destination produced a run that printed a
# report path that did not exist -- the sign-off artifact for the whole rebuild.
if ! mkdir -p "$OUTPUT_ROOT" 2>/dev/null; then
  echo "ERROR: cannot create output root: $OUTPUT_ROOT" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Configured workspace roots (post only)
# ---------------------------------------------------------------------------
# Explicit --workspace-root values win. When none are provided, use the Git
# roots loaded from reimage.env. Do not invent broad development-directory defaults:
# missing configured roots are useful post-image findings and should be reported.
if [[ "$PHASE" == "post" && ${#WORKSPACE_ROOTS[@]} -eq 0 ]]; then
  append_unique_workspace_root "${GIT_WORK_REPO_ROOT:-}"
  append_unique_workspace_root "${GIT_PERSONAL_REPO_ROOT:-}"
fi

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
if $USE_COLOR && [[ -t 1 ]]; then
  RED='\033[0;31m'
  YELLOW='\033[1;33m'
  GREEN='\033[0;32m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; BOLD=''; RESET=''
fi

# ---------------------------------------------------------------------------
# Counters and report buffer
# ---------------------------------------------------------------------------
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
  append_report "| --- | --- | --- |"
}

record_check() {
  local symbol="$1"
  local label="$2"
  local detail="$3"
  local md_icon term_color

  case "$symbol" in
    PASS)
      PASS=$(( PASS + 1 ))
      md_icon="[PASS]"; term_color="$GREEN" ;;
    WARN)
      WARN=$(( WARN + 1 ))
      md_icon="[WARN]"; term_color="$YELLOW" ;;
    FAIL)
      FAIL=$(( FAIL + 1 ))
      md_icon="[FAIL]"; term_color="$RED" ;;
    SKIP)
      SKIP=$(( SKIP + 1 ))
      md_icon="[SKIP]"; term_color="$RESET" ;;
    *)
      WARN=$(( WARN + 1 ))
      md_icon="[WARN]"; term_color="$YELLOW" ;;
  esac

  printf "  %b[%s]%b %s -- %s\n" "$term_color" "$symbol" "$RESET" "$label" "$detail"
  append_report "| ${md_icon} | ${label} | ${detail} |"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
dir_nonempty() {
  local dir="$1"
  # -L so a symlinked directory is followed. The toolkit snapshot publishes
  # latest-docs and latest-pre-image-toolkit-snapshot as symlinks into the
  # timestamped bundle; without -L, find refuses to descend and a populated
  # snapshot reported "Empty or missing".
  [[ -d "$dir" ]] && [[ -n "$(find -L "$dir" -maxdepth 3 -type f 2>/dev/null | head -1)" ]]
}

newest_matching() {
  local dir="$1" pattern="$2"
  find "$dir" -maxdepth 3 -name "$pattern" -type f 2>/dev/null | sort | tail -1
}

# Newest directory matching a glob, ranked by the trailing YYYYMMDD-HHMMSS stamp
# rather than by the whole name.
#
# Bundle names carry a variable label -- a leading --context label on the Phase
# 8/9 recorders, a --scenario mid-name on the performance audit -- so a plain
# `sort | tail -1` ranks by label first and returns whichever label sorts last,
# not whichever bundle ran last. With pre-restart and post-restart in play that
# is actively wrong: "post" precedes "pre" alphabetically, so the older bundle
# wins. Emit "<stamp>\t<path>", sort on the stamp, and drop the key. Callers
# pass a leading-wildcard pattern because the artifact name may not start the
# directory name.
#
# Directories whose names carry no trailing stamp cannot be ranked this way; if
# nothing at all could be ranked, fall back to the previous lexical behaviour so
# an unconventional layout still reports something rather than reporting empty.
newest_stamped_dir() {
  local dir="$1" pattern="$2"
  local ranked=""

  ranked="$(find "$dir" -maxdepth 1 -type d -name "$pattern" 2>/dev/null \
    | while IFS= read -r candidate; do
        stamp="$(printf '%s\n' "${candidate##*/}" \
          | sed -n 's/^.*-\([0-9]\{8\}-[0-9]\{6\}\)$/\1/p')"
        [ -n "$stamp" ] && printf '%s\t%s\n' "$stamp" "$candidate"
      done \
    | sort | tail -1 | cut -f2-)"

  if [[ -n "$ranked" ]]; then
    printf '%s\n' "$ranked"
    return 0
  fi

  find "$dir" -maxdepth 1 -type d -name "$pattern" 2>/dev/null | sort | tail -1
}

resolve_latest_repo_audit_run() {
  local audit_root="$1"
  local pointer="$audit_root/latest-run.txt"
  local run_relative=""
  local run_dir=""

  [[ -f "$pointer" ]] || return 1
  IFS= read -r run_relative < "$pointer" || true

  case "$run_relative" in
    runs/pre-image-*|runs/post-image-*) ;;
    *) return 1 ;;
  esac

  case "$run_relative" in
    *..*|/*) return 1 ;;
  esac

  run_dir="$audit_root/$run_relative"
  [[ -d "$run_dir" ]] || return 1
  printf '%s\n' "$run_dir"
}

file_age_hours() {
  local f="$1"
  local now=""
  local mtime=""

  if [[ ! -f "$f" ]]; then
    echo 999
    return
  fi

  now="$(date +%s)"
  mtime="$(stat -f %m "$f" 2>/dev/null || true)"
  case "$mtime" in
    # portability-ok: GNU-STATC — guarded retry; BSD stat -f runs first and this covers a non-numeric result
    ''|*[!0-9]*) mtime="$(stat -c %Y "$f" 2>/dev/null || true)" ;;
  esac

  case "$now:$mtime" in
    *[!0-9:]*|:|*:)
      echo 999
      return
      ;;
  esac

  echo $(( (now - mtime) / 3600 ))
}

tsv_data_count() {
  local file="$1"
  local line_count=""

  if [[ ! -f "$file" ]]; then
    echo 0
    return
  fi

  line_count="$(wc -l < "$file" 2>/dev/null | tr -d ' ')"
  case "$line_count" in
    ''|*[!0-9]*) line_count=1 ;;
  esac

  if [[ "$line_count" -gt 0 ]]; then
    echo $((line_count - 1))
  else
    echo 0
  fi
}

check_app() {
  local app_name="$1"
  if [[ -d "/Applications/$app_name.app" || -d "$HOME/Applications/$app_name.app" ]]; then
    echo "PASS"
  else
    echo "TODO"
  fi
}

check_any_app() {
  # Some vendors do not ship /Applications/<marketing name>.app: CrowdStrike
  # installs Falcon.app and Zscaler nests Zscaler.app inside /Applications/
  # Zscaler/. Match those with a case-insensitive ERE over the top level of
  # /Applications, the same way bin/record-reimaged-system.sh does.
  local pattern="$1"
  if ls -1 /Applications 2>/dev/null | grep -Eiq "$pattern"; then
    echo "PASS"
  else
    echo "TODO"
  fi
}

check_command() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then echo "PASS"; else echo "TODO"; fi
}

check_file_pattern() {
  local file="$1" pattern="$2"
  if [[ -f "$file" ]] && grep -Ev '^# command:' "$file" 2>/dev/null | grep -Eiq "$pattern" 2>/dev/null; then
    echo "PASS"
  else
    echo "TODO"
  fi
}

# Portable command timeout (no dependency on GNU coreutils `timeout`, which is
# not installed on macOS by default). Runs "$@" in the background, redirects
# its stdout/stderr to $out_file, and kills it if still alive after $secs
# seconds. Used for network-facing commands like `ssh -T` that can hang
# indefinitely on some corporate VPN/proxy setups even with ConnectTimeout
# and BatchMode set.
run_with_timeout() {
  local secs="$1" out_file="$2"
  shift 2
  ( "$@" </dev/null > "$out_file" 2>&1 & local cmd_pid=$!
    ( sleep "$secs"; kill -9 "$cmd_pid" 2>/dev/null ) & local watcher_pid=$!
    wait "$cmd_pid" 2>/dev/null
    kill "$watcher_pid" 2>/dev/null; wait "$watcher_pid" 2>/dev/null ) 2>/dev/null
}

# =============================================================================
# HEADER
# =============================================================================
PHASE_LABEL="Phase 6B — Reimage Preparation Checks"
[[ "$PHASE" == "post" ]] && PHASE_LABEL="Phase 14 — Reimaged System Checks"

printf "\n"
printf "%b+--------------------------------------------------------------+%b\n" "$BOLD" "$RESET"
printf "%b|  %-60s|%b\n" "$BOLD" "$PHASE_LABEL" "$RESET"
printf "%b+--------------------------------------------------------------+%b\n" "$BOLD" "$RESET"
printf "\n"
printf "  PHASE                  : %s\n" "$PHASE"
printf "  EXTERNAL_DATA_VOLUME   : %s\n" "$EXTERNAL_DATA_VOLUME"
printf "  REIMAGE_ARTIFACT_ROOT  : %s\n" "$REIMAGE_ARTIFACT_ROOT"
printf "  Report                 : %s\n" "$REPORT_FILE"
printf "  Timestamp   : %s\n" "$TIMESTAMP"
printf "\n"

# =============================================================================
# SHARED CHECKS — run for both pre and post
# =============================================================================

# ---------------------------------------------------------------------------
record_section "External Drive and Backup Root"
# ---------------------------------------------------------------------------

if [[ -d "$EXTERNAL_DATA_VOLUME" ]]; then
  record_check PASS "External data volume mounted" "$EXTERNAL_DATA_VOLUME exists"
else
  record_check FAIL "External data volume mounted" "$EXTERNAL_DATA_VOLUME not found -- drive not mounted"
fi

case "$REIMAGE_ARTIFACT_ROOT" in
  "$EXTERNAL_DATA_VOLUME"/*)
    record_check PASS "Artifact root location" "$REIMAGE_ARTIFACT_ROOT is under $EXTERNAL_DATA_VOLUME"
    ;;
  *)
    record_check FAIL "Artifact root location" "$REIMAGE_ARTIFACT_ROOT is not under configured EXTERNAL_DATA_VOLUME: $EXTERNAL_DATA_VOLUME"
    ;;
esac

if [[ -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  record_check PASS "Artifact root exists" "$REIMAGE_ARTIFACT_ROOT"
else
  record_check FAIL "Artifact root exists" "$REIMAGE_ARTIFACT_ROOT not found"
fi

if [[ -d "$EXTERNAL_DATA_VOLUME" ]]; then
  FREE_KB="$(df -k "$EXTERNAL_DATA_VOLUME" 2>/dev/null | awk 'NR==2{print $4}')"
  FREE_GB=$(( ${FREE_KB:-0} / 1048576 ))
  if [[ $FREE_GB -ge 5 ]]; then
    record_check PASS "External data volume free space" "${FREE_GB} GB free"
  elif [[ $FREE_GB -ge 1 ]]; then
    record_check WARN "External data volume free space" "${FREE_GB} GB free -- low"
  else
    record_check FAIL "External data volume free space" "${FREE_GB} GB free -- critically low"
  fi
fi

# ---------------------------------------------------------------------------
record_section "Cloud and Sync"
# ---------------------------------------------------------------------------

if pgrep -xq "OneDrive" 2>/dev/null; then
  record_check PASS "OneDrive process running" "Running -- confirm no pending uploads"
else
  record_check WARN "OneDrive process running" "Not running -- confirm sync was completed before this run"
fi

BACKUP_BASENAME="$(basename "$REIMAGE_ARTIFACT_ROOT")"
ONEDRIVE_BACKUP_SUBDIR="${ONEDRIVE_DEST_SUBDIR:-$BACKUP_BASENAME}"
ONEDRIVE_MATCH=""

if [[ -n "${ONEDRIVE_ROOT:-}" ]]; then
  ONEDRIVE_MATCH="${ONEDRIVE_ROOT%/}/$ONEDRIVE_BACKUP_SUBDIR"
  if [[ -d "$ONEDRIVE_MATCH" ]]; then
    MARKER_COUNT="$(find "$ONEDRIVE_MATCH" -maxdepth 1 -name "onedrive-upload-marker-*.txt" 2>/dev/null | wc -l | tr -d ' ')"
    if [[ "$MARKER_COUNT" -gt 0 ]]; then
      record_check PASS "OneDrive backup folder detected" "$ONEDRIVE_MATCH -- upload marker present (evidence only, not proof of sync)"
    else
      record_check WARN "OneDrive backup folder detected" "$ONEDRIVE_MATCH -- no upload marker found; confirm sync manually"
    fi
  elif [[ -d "$ONEDRIVE_ROOT" ]]; then
    record_check WARN "OneDrive backup folder detected" "$ONEDRIVE_MATCH not found -- confirm the configured destination and sync state"
  else
    record_check WARN "OneDrive root available" "$ONEDRIVE_ROOT not found -- sign in or correct ONEDRIVE_ROOT"
  fi
else
  record_check SKIP "OneDrive backup folder detected" "ONEDRIVE_ROOT is not configured"
fi

ICLOUD_DRIVE="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
if [[ -d "$ICLOUD_DRIVE" ]]; then
  record_check PASS "iCloud Drive available" "Found -- confirm no pending uploads manually if relied upon"
else
  record_check SKIP "iCloud Drive available" "Not found or not enabled -- skip if not used"
fi

TM_LAST="$(tmutil latestbackup 2>/dev/null || true)"
if [[ -n "$TM_LAST" ]]; then
  record_check PASS "Time Machine last backup" "$(basename "$TM_LAST")"
else
  record_check WARN "Time Machine last backup" "No completed backup found"
fi

# =============================================================================
# PRE-IMAGE CHECKS
# =============================================================================
if [[ "$PHASE" == "pre" ]]; then

  # -------------------------------------------------------------------------
  record_section "Backup Root Subdirectories"
  # -------------------------------------------------------------------------
  # This list is intentionally separate from EXPECTED_ARTIFACT_FOLDERS and must
  # not be replaced by it. That fragment is the CREATION list — what Phase 1
  # makes, empty. This is the COMPLETENESS list — what must hold content before
  # the erase. The two differ in both directions: office-stability and
  # performance-audit are checked here but never scaffolded (optional captures,
  # created by their runbooks only when relevant), while folders Phase 1 always
  # creates can legitimately still be empty here and are checked elsewhere.
  # office-stability and performance-audit are OPTIONAL per reimaging-guide.md
  # ("All Phase 4 captures are optional"), so their absence must not FAIL — a
  # machine reimaged for neither an Office nor a performance problem could
  # otherwise never reach a green Phase 6B. They report SKIP with the reason.
  OPTIONAL_SUBDIRS=":office-stability:performance-audit:"
  for subdir in app-settings-backup repo-audit-reports gitignore-superset managed-inventory office-stability performance-audit secrets-encrypted system-inventory toolkit-snapshot; do
    if dir_nonempty "$REIMAGE_ARTIFACT_ROOT/$subdir"; then
      SIZE="$(du -sh "$REIMAGE_ARTIFACT_ROOT/$subdir" 2>/dev/null | cut -f1)"
      record_check PASS "Subdir: $subdir" "$SIZE on disk"
    elif [[ "$OPTIONAL_SUBDIRS" == *":$subdir:"* ]]; then
      record_check SKIP "Subdir: $subdir" "Optional capture — only needed when it is part of why this Mac is being reimaged"
    elif [[ -d "$REIMAGE_ARTIFACT_ROOT/$subdir" ]]; then
      record_check WARN "Subdir: $subdir" "Exists but empty"
    else
      record_check FAIL "Subdir: $subdir" "Missing entirely"
    fi
  done

  # -------------------------------------------------------------------------
  record_section "Git Audit"
  # -------------------------------------------------------------------------
  REPO_AUDIT_DIR="$REIMAGE_ARTIFACT_ROOT/repo-audit-reports"
  REPO_AUDIT_MANIFEST="$REPO_AUDIT_DIR/MANIFEST.md"
  LATEST_AUDIT_RUN="$(resolve_latest_repo_audit_run "$REPO_AUDIT_DIR" 2>/dev/null || true)"
  LATEST_AUDIT="${LATEST_AUDIT_RUN:+$LATEST_AUDIT_RUN/repo-audit-summary.txt}"

  if [[ -f "$REPO_AUDIT_MANIFEST" ]] && grep -q '^# Repository Audit Runs$' "$REPO_AUDIT_MANIFEST" 2>/dev/null; then
    record_check PASS "Repository audit manifest" "$REPO_AUDIT_MANIFEST"
  elif [[ -f "$REPO_AUDIT_MANIFEST" ]]; then
    record_check FAIL "Repository audit manifest" "Existing MANIFEST.md is not the canonical append-only run index"
  else
    record_check FAIL "Repository audit manifest" "Missing $REPO_AUDIT_MANIFEST"
  fi

  if [[ -n "$LATEST_AUDIT_RUN" && -f "$LATEST_AUDIT" ]]; then
    AGE_H="$(file_age_hours "$LATEST_AUDIT")"
    if [[ $AGE_H -le 24 ]]; then
      record_check PASS "Git audit report" "$(basename "$LATEST_AUDIT_RUN")/repo-audit-summary.txt (${AGE_H}h ago)"
    else
      record_check WARN "Git audit report" "$(basename "$LATEST_AUDIT_RUN")/repo-audit-summary.txt is ${AGE_H}h old -- consider re-running"
    fi
    LOCAL_ONLY_COUNT="$(tsv_data_count "$LATEST_AUDIT_RUN/local-only-commits.tsv")"
    if [[ "$LOCAL_ONLY_COUNT" -gt 0 ]]; then
      record_check WARN "Local-only commits" "$LOCAL_ONLY_COUNT local-only commit row(s) in the latest audit -- review"
    else
      record_check PASS "Local-only commits" "Latest audit reports none"
    fi

    STASH_COUNT="$(tsv_data_count "$LATEST_AUDIT_RUN/stashes.tsv")"
    if [[ "$STASH_COUNT" -gt 0 ]]; then
      record_check WARN "Stashes" "$STASH_COUNT stash row(s) in the latest audit -- review"
    else
      record_check PASS "Stashes" "Latest audit reports none"
    fi
  else
    record_check FAIL "Git audit report" "latest-run.txt does not resolve to a run containing repo-audit-summary.txt"
    record_check SKIP "Local-only commits" "Skipped -- latest audit report unavailable"
    record_check SKIP "Stashes" "Skipped -- latest audit report unavailable"
  fi

  if [[ -n "$LATEST_AUDIT_RUN" && -f "$LATEST_AUDIT_RUN/local-only-commits.tsv" ]]; then
    record_check PASS "Git audit TSV present" "$(basename "$LATEST_AUDIT_RUN")/local-only-commits.tsv"
  else
    record_check WARN "Git audit TSV present" "local-only-commits.tsv not found in the latest audit run"
  fi

  UNTRACKED_TSV="${LATEST_AUDIT_RUN:+$LATEST_AUDIT_RUN/untracked-nonignored.tsv}"
  if [[ -n "$UNTRACKED_TSV" && -f "$UNTRACKED_TSV" ]]; then
    UNTRACKED_COUNT="$(tsv_data_count "$UNTRACKED_TSV")"
    if [[ "$UNTRACKED_COUNT" -gt 0 ]]; then
      record_check WARN "Untracked non-ignored files reviewed" "Latest run lists $UNTRACKED_COUNT file(s) -- review before reimage"
    else
      record_check PASS "Untracked non-ignored files reviewed" "Latest run reports none"
    fi
  else
    record_check WARN "Untracked non-ignored files reviewed" "untracked-nonignored.tsv not found in the latest audit run"
  fi

  # -------------------------------------------------------------------------
  record_section ".gitignore Superset and Staged Ignored Files"
  # -------------------------------------------------------------------------
  GITIGNORE_DIR="$REIMAGE_ARTIFACT_ROOT/gitignore-superset"

  if [[ -f "$GITIGNORE_DIR/gitignore-review-template.txt" ]]; then
    record_check PASS "gitignore-review-template.txt generated" "Found"
    if grep -q '^\[x\]' "$GITIGNORE_DIR/gitignore-review-template.txt" 2>/dev/null; then
      MARKED="$(grep -c '^\[x\]' "$GITIGNORE_DIR/gitignore-review-template.txt" 2>/dev/null || echo 0)"
      record_check PASS "gitignore-review-template.txt reviewed" "${MARKED} pattern(s) marked [x]"
    else
      record_check WARN "gitignore-review-template.txt reviewed" "No [x] marks -- may not have been reviewed"
    fi
  else
    record_check FAIL "gitignore-review-template.txt generated" "Not found under $GITIGNORE_DIR"
    record_check SKIP "gitignore-review-template.txt reviewed" "Skipped"
  fi

  if dir_nonempty "$REIMAGE_ARTIFACT_ROOT/staged-ignored-files"; then
    SIZE="$(du -sh "$REIMAGE_ARTIFACT_ROOT/staged-ignored-files" 2>/dev/null | cut -f1)"
    record_check PASS "Staged ignored files copied" "$SIZE"
  else
    record_check WARN "Staged ignored files copied" "Empty -- intentional if no patterns needed"
  fi

  if dir_nonempty "$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/dryrun-filtered"; then
    record_check PASS "Filtered dry run completed" "Non-empty"
  else
    record_check WARN "Filtered dry run completed" "No results found"
  fi

  # -------------------------------------------------------------------------
  record_section "IntelliJ Backup"
  # -------------------------------------------------------------------------
  INTELLIJ_DIR="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij"

  if dir_nonempty "$INTELLIJ_DIR"; then
    record_check PASS "IntelliJ backup directory" "$(du -sh "$INTELLIJ_DIR" 2>/dev/null | cut -f1)"
  else
    record_check FAIL "IntelliJ backup directory" "Empty"
  fi
  if [[ -n "$(find "$INTELLIJ_DIR" -type d -name "scratches-and-consoles" 2>/dev/null | head -1)" ]]; then
    record_check PASS "IntelliJ Scratches and Consoles" "scratches-and-consoles/ found"
  else
    record_check WARN "IntelliJ Scratches and Consoles" "Not found"
  fi
  INTELLIJ_SETTINGS_ZIP="$(find "$INTELLIJ_DIR" -name "*.zip" 2>/dev/null | head -1)"
  if [[ -n "$INTELLIJ_SETTINGS_ZIP" ]]; then
    record_check PASS "IntelliJ settings ZIP" "$(basename "$INTELLIJ_SETTINGS_ZIP")"
  else
    record_check WARN "IntelliJ settings ZIP" "Not found -- File > Export Settings"
  fi

  # -------------------------------------------------------------------------
  record_section "Loose Secret Sweep"
  # -------------------------------------------------------------------------
  # Existence alone would be a weak check: re-runs are expected, so what matters
  # is ORDER. The chain is backups -> sweep -> DMG, and each link has to be newer
  # than the one before it. A backup re-run after the sweep means credentials may
  # have been re-copied into the clear; a sweep after the DMG means the DMG does
  # not contain what was staged.
  LOOSE_REPORTS_DIR="$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports"
  LOOSE_MANIFEST="$LOOSE_REPORTS_DIR/MANIFEST.md"

  if [[ -f "$LOOSE_MANIFEST" ]]; then
    LOOSE_RUNS="$(grep -c '^| 20' "$LOOSE_MANIFEST" 2>/dev/null)"
    record_check PASS "Loose secret sweep ran" "${LOOSE_RUNS:-0} recorded run(s)"

    # Each backup tree stamps a completion file on every real run, so staleness
    # is three stat comparisons rather than three tree walks. Walking a full
    # artifact root here would add minutes to the sign-off that runs last.
    #   home-files-backup/MANIFEST.md          end of backup-home
    #   app-settings-backup/MANIFEST.md        end of backup-apps (candidate
    #                                          review deliberately does not write it)
    #   staged-ignored-files/live/summary.txt  end of the live staging copy
    STALE_SINCE_SWEEP=""
    for _lsflag in \
      "home-files-backup/MANIFEST.md" \
      "app-settings-backup/MANIFEST.md" \
      "staged-ignored-files/live/summary.txt"; do
      _lspath="$REIMAGE_ARTIFACT_ROOT/$_lsflag"
      [[ -f "$_lspath" ]] || continue
      if [[ "$_lspath" -nt "$LOOSE_MANIFEST" ]]; then
        STALE_SINCE_SWEEP="$STALE_SINCE_SWEEP ${_lsflag%%/*}"
      fi
    done

    if [[ -n "$STALE_SINCE_SWEEP" ]]; then
      record_check WARN "Sweep is current with backups" \
        "Re-run after the last sweep:${STALE_SINCE_SWEEP} -- re-run bin/report-loose-secrets.sh before the erase"
    else
      record_check PASS "Sweep is current with backups" "Sweep is newer than every backup tree"
    fi

    OPEN_FINDINGS="$LOOSE_REPORTS_DIR/open-findings.md"
    if [[ -n "$OPEN_FINDINGS" && -f "$OPEN_FINDINGS" ]]; then
      # open-findings.md has an "## Open" section and a "## Resolved" section,
      # and both use the same row shape. Counting matches across the whole file
      # reported every resolved candidate as still open -- 37 unresolved on a
      # drive whose own report said "Open - 0". Count only inside "## Open".
      OPEN_COUNT="$(awk '
        /^## Open/      { in_open = 1; next }
        /^## /          { in_open = 0 }
        in_open && /^\| (OUTSIDE|INSIDE) / { n++ }
        END             { print n + 0 }
      ' "$OPEN_FINDINGS" 2>/dev/null)"
      if [[ "${OPEN_COUNT:-0}" -gt 0 ]]; then
        record_check FAIL "Open loose-secret findings" \
          "${OPEN_COUNT} unresolved in open-findings.md -- stage them, or record each as an exception with a reason in loose-secret-exceptions.conf.sh"
      else
        record_check PASS "Open loose-secret findings" "None open"
      fi
    else
      record_check SKIP "Open loose-secret findings" "open-findings.md not present"
    fi
  else
    record_check FAIL "Loose secret sweep ran" \
      "No MANIFEST.md under loose-secrets-reports/ -- Phase 3B has never completed a saved run"
    record_check SKIP "Sweep is current with backups" "Skipped -- no sweep recorded"
    record_check SKIP "Open loose-secret findings" "Skipped -- no sweep recorded"
  fi

  # -------------------------------------------------------------------------
  record_section "Secrets and Encrypted DMG"
  # -------------------------------------------------------------------------
  SECRETS_DIR="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"
  SECRETS_DMG="$(newest_matching "$SECRETS_DIR" "all-secrets-*.dmg")"

  if [[ -n "$SECRETS_DMG" ]]; then
    record_check PASS "Consolidated secrets DMG" "$(basename "$SECRETS_DMG") -- $(du -sh "$SECRETS_DMG" 2>/dev/null | cut -f1)"
    DMG_BASE="${SECRETS_DMG%.dmg}"
    if [[ -f "${DMG_BASE}-manifest.txt" ]]; then
      record_check PASS "DMG manifest" "$(basename "${DMG_BASE}-manifest.txt")"
    else
      record_check WARN "DMG manifest" "No manifest found next to DMG"
    fi

    # Third link in the backups -> sweep -> DMG chain. A DMG older than the last
    # sweep does not contain what the sweep moved into staged-loose/.
    #
    # But "a sweep ran later" is not the same as "the sweep staged something".
    # A clean sweep -- the normal case once findings are resolved -- moves
    # nothing, so the DMG is still complete. Comparing mtimes alone reported
    # FAIL after every clean re-run and told the operator to rebuild.
    #
    # That advice is worse than noise after `cleanup`: cleanup removes the
    # pre-staged trees, so a rebuild then produces a SUBSET of the existing DMG.
    # Gate on whether staged-loose/ actually holds content newer than the image.
    STAGED_LOOSE_DIR="$SECRETS_DIR/staged-loose"
    if [[ -f "$LOOSE_MANIFEST" ]]; then
      if [[ ! "$LOOSE_MANIFEST" -nt "$SECRETS_DMG" ]]; then
        record_check PASS "DMG is current with the sweep" "DMG is newer than the last sweep"
      elif [[ -d "$STAGED_LOOSE_DIR" ]] \
        && find "$STAGED_LOOSE_DIR" -type f ! -name '.DS_Store' -newer "$SECRETS_DMG" 2>/dev/null | grep -q .; then
        record_check FAIL "DMG is current with the sweep" \
          "Phase 3B staged new files after this DMG was built -- rebuild so staged-loose/ is included"
      else
        record_check PASS "DMG is current with the sweep" \
          "Sweep ran after the DMG but staged nothing new -- DMG still complete"
      fi
    else
      record_check SKIP "DMG is current with the sweep" "Skipped -- no sweep recorded"
    fi
  else
    record_check FAIL "Consolidated secrets DMG" "No all-secrets-*.dmg under $SECRETS_DIR"
    record_check SKIP "DMG manifest" "Skipped -- DMG not found"
  fi

  if [[ -f "$SECRETS_DIR/RESTORE-README.md" ]]; then
    record_check PASS "RESTORE-README.md" "Found"
  else
    record_check WARN "RESTORE-README.md" "Missing"
  fi

  EXTRA_CERTS_REVIEW_DIR="$SECRETS_DIR/extra-secrets-certs-review"
  if [[ -f "$EXTRA_CERTS_REVIEW_DIR/MANIFEST.md" ]]; then
    record_check PASS "Extra certificate/Keychain review inventory" "MANIFEST.md found under extra-secrets-certs-review/"
  elif [[ -d "$EXTRA_CERTS_REVIEW_DIR" ]]; then
    record_check WARN "Extra certificate/Keychain review inventory" "Directory exists but no MANIFEST.md -- re-run stage-certs-keychain.sh"
  else
    record_check WARN "Extra certificate/Keychain review inventory" "No extra-secrets-certs-review/ under $SECRETS_DIR -- run stage-certs-keychain.sh"
  fi

  KEYCHAIN_EXPORTS_DIR="$SECRETS_DIR/certs/keychain-manual-exports"
  if dir_nonempty "$KEYCHAIN_EXPORTS_DIR"; then
    record_check PASS "Keychain manual exports staged" "$(du -sh "$KEYCHAIN_EXPORTS_DIR" 2>/dev/null | cut -f1) under certs/keychain-manual-exports/"
  elif [[ -d "$KEYCHAIN_EXPORTS_DIR" ]]; then
    record_check SKIP "Keychain manual exports staged" "Directory exists but empty -- skip if no manual Keychain exports were needed"
  else
    record_check SKIP "Keychain manual exports staged" "Not found -- skip if no manual Keychain exports were needed"
  fi

  CHROME_SECRETS_DIR="$SECRETS_DIR/chrome"
  CHROME_PW_CSV="$(find "$CHROME_SECRETS_DIR" -maxdepth 1 -iname "*.csv" 2>/dev/null | head -1)"
  if [[ -n "$CHROME_PW_CSV" ]]; then
    record_check PASS "Chrome password CSV staged" "$(basename "$CHROME_PW_CSV") found under secrets-encrypted/chrome/"
  elif [[ -d "$CHROME_SECRETS_DIR" ]]; then
    record_check SKIP "Chrome password CSV staged" "Directory exists but no CSV found -- skip if not exported"
  else
    record_check SKIP "Chrome password CSV staged" "No secrets-encrypted/chrome/ -- skip if not exported"
  fi

  # Named, well-known plaintext exports only. A literal "<company>-issuing-ca.pem"
  # placeholder used to sit in this list; it could never match a real file, so it
  # checked nothing. Certificate/key shapes are covered for real by the Phase 3B
  # sweep (bin/report-loose-secrets.sh), which reads SECRET_SHAPES_FLOOR in
  # .internal/artifact-config.sh — *.pem, *.key, *.p12 and the rest are already
  # in that floor. Do not reintroduce a private pattern list here.
  for danger in \
    "$HOME/Desktop/Chrome Passwords.csv" \
    "$HOME/Downloads/Chrome Passwords.csv"; do
    if [[ -f "$danger" ]]; then
      record_check WARN "Loose plaintext secret" "$danger -- delete after confirming it is in DMG"
    fi
  done

  # -------------------------------------------------------------------------
  record_section "System Inventory"
  # -------------------------------------------------------------------------
  SYS_INV_DIR="$REIMAGE_ARTIFACT_ROOT/system-inventory"

  if dir_nonempty "$SYS_INV_DIR"; then
    record_check PASS "System inventory captured" "$(du -sh "$SYS_INV_DIR" 2>/dev/null | cut -f1)"
  else
    record_check FAIL "System inventory captured" "Empty -- run capture-system-inventory.sh"
  fi
  if [[ -n "$(find "$SYS_INV_DIR" -name "Brewfile*" 2>/dev/null | head -1)" ]]; then
    record_check PASS "Brewfile saved" "Found"
  else
    record_check WARN "Brewfile saved" "Not found -- run: brew bundle dump"
  fi

  # -------------------------------------------------------------------------
  record_section "Performance and Office Evidence"
  # -------------------------------------------------------------------------
  PERF_DIR="$REIMAGE_ARTIFACT_ROOT/performance-audit"

  if dir_nonempty "$PERF_DIR"; then
    record_check PASS "Performance audit captured" "$(du -sh "$PERF_DIR" 2>/dev/null | cut -f1)"
  else
    record_check SKIP "Performance audit captured" "Optional -- run capture-performance-audit.sh only when before/after evidence for slowness matters"
  fi

  MANUAL_OBS="$(newest_matching "$PERF_DIR" "manual-observations.md")"
  if [[ -n "$MANUAL_OBS" ]]; then
    OBS_SIZE="$(wc -c < "$MANUAL_OBS" 2>/dev/null | tr -d ' ')"
    if [[ $OBS_SIZE -gt 200 ]]; then
      record_check PASS "manual-observations.md filled in" "${OBS_SIZE} bytes"
    else
      record_check WARN "manual-observations.md filled in" "${OBS_SIZE} bytes -- appears unfilled"
    fi
  else
    record_check WARN "manual-observations.md" "Not found"
  fi

  OFFICE_DIR="$REIMAGE_ARTIFACT_ROOT/office-stability"
  if dir_nonempty "$OFFICE_DIR"; then
    record_check PASS "Office stability evidence present" "$(du -sh "$OFFICE_DIR" 2>/dev/null | cut -f1)"
  else
    record_check SKIP "Office stability evidence present" "Optional -- run capture-office-stability.sh only when Office instability is part of why this Mac is being reimaged"
  fi
  if [[ -n "$(find "$OFFICE_DIR" \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | head -1)" ]]; then
    record_check WARN "No active scripts in office-stability/" "Scripts found -- remove; keep in Git repo only"
  else
    record_check PASS "No active scripts in office-stability/" "Clean"
  fi

  if dir_nonempty "$REIMAGE_ARTIFACT_ROOT/office-stability/checklists"; then
    record_check PASS "Pre-image Office stability checklist generated" "checklists/ non-empty"
  else
    record_check WARN "Pre-image Office stability checklist generated" "Run office-stability-checklist.sh --phase pre-reimage"
  fi

  # -------------------------------------------------------------------------
  record_section "Time Machine Status Bundle"
  # -------------------------------------------------------------------------
  TM_DIR="$REIMAGE_ARTIFACT_ROOT/time-machine"
  if dir_nonempty "$TM_DIR"; then
    record_check PASS "Time Machine status bundle" "$(du -sh "$TM_DIR" 2>/dev/null | cut -f1)"
  else
    record_check WARN "Time Machine status bundle" "Empty -- run the Phase 4 Time Machine status capture (see run-time-machine.md)"
  fi

  # -------------------------------------------------------------------------
  record_section "Toolkit Snapshot and Manual Notes"
  # -------------------------------------------------------------------------
  TOOLKIT_SNAPSHOT_ROOT="$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot"
  APP_SETTINGS_BACKUP_ROOT="$REIMAGE_ARTIFACT_ROOT/app-settings-backup"
  HOME_FILES_BACKUP_DIR="$REIMAGE_ARTIFACT_ROOT/home-files-backup"

  LATEST_WORKFLOW_CAPTURE="$(
    find "$TOOLKIT_SNAPSHOT_ROOT" -maxdepth 1 -type d -name 'pre-image-toolkit-snapshot-*' -print 2>/dev/null \
      | sort \
      | tail -1
  )"

  if [[ -n "$LATEST_WORKFLOW_CAPTURE" && -d "$LATEST_WORKFLOW_CAPTURE" ]]; then
    record_check PASS "Latest toolkit snapshot" "$(basename "$LATEST_WORKFLOW_CAPTURE")"
  else
    record_check WARN "Latest toolkit snapshot" "No pre-image-toolkit-snapshot-* bundle found under $TOOLKIT_SNAPSHOT_ROOT"
  fi

  # Automated toolkit snapshot material lives directly inside the newest timestamped
  # capture bundle:
  #
  #   $REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/pre-image-toolkit-snapshot-YYYYMMDD-HHMMSS/{logs,...}
  #
  # Stable hand-maintained/export folders stay directly under
  # app-settings-backup/ and are checked separately.
  if dir_nonempty "$TOOLKIT_SNAPSHOT_ROOT/latest-docs"; then
    record_check PASS "toolkit-snapshot/latest-docs" "$(du -sh "$TOOLKIT_SNAPSHOT_ROOT/latest-docs/" 2>/dev/null | cut -f1)"
  else
    record_check WARN "toolkit-snapshot/latest-docs" "Empty or missing"
  fi

  if dir_nonempty "$TOOLKIT_SNAPSHOT_ROOT/latest-pre-image-toolkit-snapshot/config"; then
    record_check PASS "toolkit-snapshot/latest .../config" "$(du -sh "$TOOLKIT_SNAPSHOT_ROOT/latest-pre-image-toolkit-snapshot/config/" 2>/dev/null | cut -f1)"
  else
    record_check WARN "toolkit-snapshot/latest .../config" "Empty or missing"
  fi

  REIMAGE_CONFIRMATION_DIR="$REIMAGE_ARTIFACT_ROOT/reimage-confirmation"
  if [[ -n "$(find "$REIMAGE_CONFIRMATION_DIR" -maxdepth 1 -type f -name 'it-reimage-confirmation-*.md' -print -quit 2>/dev/null)" ]]; then
    record_check PASS "reimage-confirmation IT confirmation" "Found"
  else
    record_check WARN "reimage-confirmation IT confirmation" "Missing -- copy the filled IT confirmation into reimage-confirmation/"
  fi

  if [[ -f "$APP_SETTINGS_BACKUP_ROOT/vscode/extensions.txt" ]]; then
    EXT_COUNT="$(wc -l < "$APP_SETTINGS_BACKUP_ROOT/vscode/extensions.txt" 2>/dev/null | tr -d ' ')"
    record_check PASS "VS Code extensions.txt" "${EXT_COUNT} extensions"
  else
    record_check WARN "VS Code extensions.txt" "Not found in app-settings-backup/vscode"
  fi

  DOTFILES_DIR="$HOME_FILES_BACKUP_DIR/dotfiles"
  if dir_nonempty "$DOTFILES_DIR"; then
    record_check PASS "home-files-backup/dotfiles" "$(du -sh "$DOTFILES_DIR" 2>/dev/null | cut -f1)"
  else
    record_check WARN "home-files-backup/dotfiles" "Empty or missing -- run Phase 2B backup-home.sh"
  fi

  POSTMAN_DIR="$APP_SETTINGS_BACKUP_ROOT/postman"
  if [[ -d "$POSTMAN_DIR" ]]; then
    if dir_nonempty "$POSTMAN_DIR"; then
      record_check PASS "Postman exports" "Files present"
    else
      record_check WARN "Postman exports" "Directory exists but empty"
    fi
  else
    record_check SKIP "Postman exports" "No postman dir -- skip if not used"
  fi

  # -------------------------------------------------------------------------
  record_section "Local Files Backup"
  # -------------------------------------------------------------------------
  if dir_nonempty "$HOME_FILES_BACKUP_DIR"; then
    record_check PASS "backup-home.sh run" "$(du -sh "$HOME_FILES_BACKUP_DIR" 2>/dev/null | cut -f1)"
  else
    record_check FAIL "backup-home.sh run" "Empty -- run backup-home.sh"
  fi
  if [[ -f "$HOME_FILES_BACKUP_DIR/MANIFEST.md" ]]; then
    record_check PASS "home-files-backup/MANIFEST.md" "Found"
  else
    record_check WARN "home-files-backup/MANIFEST.md" "Not found"
  fi

  # -------------------------------------------------------------------------
  record_section "App Backups"
  # -------------------------------------------------------------------------
  if [[ -f "$APP_SETTINGS_BACKUP_ROOT/MANIFEST.md" ]]; then
    record_check PASS "app-settings-backup/MANIFEST.md" "Found"
  else
    record_check WARN "app-settings-backup/MANIFEST.md" "Not found"
  fi

  VSCODE_DIR="$APP_SETTINGS_BACKUP_ROOT/vscode"
  if dir_nonempty "$VSCODE_DIR"; then
    record_check PASS "VS Code local fallback" "Non-empty"
  else
    record_check WARN "VS Code local fallback" "Empty -- run backup-apps.sh if VS Code applies"
  fi

  # -------------------------------------------------------------------------
  record_section "Docker and Chrome"
  # -------------------------------------------------------------------------
  DOCKER_DIR="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker"
  if dir_nonempty "$DOCKER_DIR"; then
    record_check PASS "Docker settings backed up" "Non-empty"
  else
    record_check WARN "Docker settings backed up" "Empty -- run backup-apps.sh --docker-only with Docker running"
  fi
  if [[ -f "$DOCKER_DIR/image-inventory.txt" ]]; then
    IMG_COUNT="$(wc -l < "$DOCKER_DIR/image-inventory.txt" 2>/dev/null | tr -d ' ')"
    record_check PASS "Docker image inventory" "${IMG_COUNT} lines"
  else
    record_check WARN "Docker image inventory" "image-inventory.txt not found"
  fi

  CHROME_DIR="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome"
  if dir_nonempty "$CHROME_DIR"; then
    record_check PASS "Chrome bookmarks exported" "Non-empty"
  else
    record_check WARN "Chrome bookmarks exported" "Empty -- export bookmarks from Chrome"
  fi

  # -------------------------------------------------------------------------
  record_section "Active Scripts Check"
  # -------------------------------------------------------------------------
  if [[ -d "$REIMAGE_ARTIFACT_ROOT/scripts" ]]; then
    record_check WARN "No \$REIMAGE_ARTIFACT_ROOT/scripts folder" "Directory exists -- scripts belong in the fractogenesis-toolkit repo (bin/ or .internal/), not the backup drive"
  else
    record_check PASS "No \$REIMAGE_ARTIFACT_ROOT/scripts folder" "Clean"
  fi
  STRAY_SCRIPTS="$(find "$REIMAGE_ARTIFACT_ROOT" \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | head -5)"
  if [[ -n "$STRAY_SCRIPTS" ]]; then
    record_check WARN "No active scripts copied to backup drive" "Found: $(echo "$STRAY_SCRIPTS" | tr '\n' ' ' | sed "s|$REIMAGE_ARTIFACT_ROOT/||g")"
  else
    record_check PASS "No active scripts copied to backup drive" "Clean -- no .sh/.py files found under $REIMAGE_ARTIFACT_ROOT"
  fi

  TOTAL_FILES="$(find "$REIMAGE_ARTIFACT_ROOT" -type f 2>/dev/null | wc -l | tr -d ' ')"
  TOTAL_SIZE="$(du -sh "$REIMAGE_ARTIFACT_ROOT" 2>/dev/null | cut -f1)"
  record_check PASS "Backup root total" "$TOTAL_SIZE across $TOTAL_FILES files"

fi   # end reimage-prep-checks (pre-image) checks

# =============================================================================
# REIMAGED SYSTEM CHECKS
# =============================================================================
if [[ "$PHASE" == "post" ]]; then

  # -------------------------------------------------------------------------
  record_section "System Identity"
  # -------------------------------------------------------------------------
  record_check PASS "macOS version" "$(sw_vers -productVersion 2>/dev/null || echo unknown)"
  record_check PASS "Current user" "$(whoami 2>/dev/null || echo unknown)"
  record_check PASS "Hostname" "$(scutil --get ComputerName 2>/dev/null || hostname)"

  # FAIL, not WARN: a rebuilt managed Mac with FileVault off is a compliance and
  # data-loss problem, and Phase 14 is the last point anyone looks. It is also
  # trivially fixable at this stage, so failing here costs minutes, not a rerun.
  FV_STATUS="$(fdesetup status 2>/dev/null || echo unknown)"
  if echo "$FV_STATUS" | grep -qi "FileVault is On"; then
    record_check PASS "FileVault" "$FV_STATUS"
  else
    record_check FAIL "FileVault" "$FV_STATUS -- enable FileVault (System Settings > Privacy & Security), then confirm the recovery key is escrowed to MDM"
  fi

  # -------------------------------------------------------------------------
  record_section "MDM and Security"
  # -------------------------------------------------------------------------
  # `profiles status -type enrollment` prints two lines, e.g.
  #     Enrolled via DEP: No
  #     MDM enrollment: Yes (User Approved)
  # A bare `grep -qi enrolled` matches the FIRST line's label regardless of its
  # Yes/No value, so a DEP-registered but NOT MDM-enrolled Mac scored PASS --
  # exactly the state Phase 8 exists to catch. Anchor on the field prefix.
  #
  # FAIL, not WARN: if MDM enrollment did not complete, Phase 8 did not complete,
  # and every managed-app and certificate assumption downstream is unfounded.
  MDM_RAW="$(profiles status -type enrollment 2>/dev/null || echo 'unknown')"
  if echo "$MDM_RAW" | grep -Eqi '^[[:space:]]*MDM enrollment:[[:space:]]*Yes'; then
    record_check PASS "MDM / Intune enrollment" "$(echo "$MDM_RAW" | tr '\n' ' ')"
  else
    record_check FAIL "MDM / Intune enrollment" "Not MDM-enrolled -- $(echo "$MDM_RAW" | tr '\n' ' ') -- re-run enrollment via Company Portal (Phase 8)"
  fi

  if [[ "$(check_app "Company Portal")" == "PASS" ]]; then
    record_check PASS "Company Portal present" "Found in /Applications"
  else
    record_check WARN "Company Portal present" "Not found -- may still be installing"
  fi

  # CrowdStrike ships /Applications/Falcon.app and Zscaler nests its app under
  # /Applications/Zscaler/, so an exact <name>.app test WARNs on a healthy Mac.
  if [[ "$(check_any_app 'CrowdStrike|Falcon')" == "PASS" ]]; then
    record_check PASS "CrowdStrike Falcon present" "Found in /Applications"
  else
    record_check WARN "CrowdStrike Falcon present" "Not found -- may still be installing"
  fi

  if [[ "$(check_any_app 'Zscaler')" == "PASS" ]]; then
    record_check PASS "Zscaler present" "Found in /Applications"
  else
    record_check WARN "Zscaler present" "Not found -- may still be installing"
  fi

  if pgrep -f 'CrowdStrike|falcon' >/dev/null 2>&1; then
    record_check PASS "CrowdStrike/Falcon process" "Running"
  else
    record_check WARN "CrowdStrike/Falcon process" "Not detected -- confirm in Activity Monitor"
  fi

  # -------------------------------------------------------------------------
  record_section "Microsoft Office and OneDrive"
  # -------------------------------------------------------------------------
  for app in "Microsoft Outlook" "Microsoft OneNote" "Microsoft Word" "Microsoft Excel" "Microsoft PowerPoint" "Microsoft Teams" "OneDrive"; do
    STATUS="$(check_app "$app")"
    if [[ "$STATUS" == "PASS" ]]; then
      VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "/Applications/$app.app/Contents/Info.plist" 2>/dev/null || echo 'unknown')"
      record_check PASS "$app" "Version $VERSION"
    else
      record_check WARN "$app" "Not found -- may still be installing from managed channel"
    fi
  done

  OFFICE_CRASH_COUNT="$(find "$HOME/Library/Logs/DiagnosticReports" -maxdepth 1 -type f \( -iname "*Outlook*" -o -iname "*OneNote*" -o -iname "*Microsoft*" \) 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$OFFICE_CRASH_COUNT" -eq 0 ]]; then
    record_check PASS "Office crash/diagnostic reports" "None found"
  else
    record_check WARN "Office crash/diagnostic reports" "$OFFICE_CRASH_COUNT report(s) found -- review ~/Library/Logs/DiagnosticReports"
  fi

  SOFTWAREUPDATE_PENDING="$(softwareupdate --list 2>&1 | grep -c "^[[:space:]]*\*" || true)"
  if [[ "$SOFTWAREUPDATE_PENDING" -eq 0 ]]; then
    record_check PASS "Pending macOS software updates" "None found"
  else
    record_check WARN "Pending macOS software updates" "$SOFTWAREUPDATE_PENDING update(s) available -- run softwareupdate --list"
  fi

  # -------------------------------------------------------------------------
  record_section "Developer Tools"
  # -------------------------------------------------------------------------
  for cmd_label in "brew:Homebrew" "git:Git" "java:Java" "gradle:Gradle" "mvn:Maven" "python3:Python 3" "node:Node" "npm:npm" "docker:Docker CLI" "cf:Cloud Foundry CLI" "jq:jq" "yq:yq"; do
    cmd="${cmd_label%%:*}"
    label="${cmd_label##*:}"
    STATUS="$(check_command "$cmd")"
    if [[ "$STATUS" == "PASS" ]]; then
      case "$cmd" in
        brew)    VERSION="$(brew --version 2>/dev/null | head -1 || echo unknown)" ;;
        git)     VERSION="$(git --version 2>/dev/null || echo unknown)" ;;
        java)    VERSION="$(java -version 2>&1 | head -1 || echo unknown)" ;;
        gradle)  VERSION="$(gradle --version 2>/dev/null | grep '^Gradle' | head -1 || echo unknown)" ;;
        mvn)     VERSION="$(mvn --version 2>/dev/null | head -1 || echo unknown)" ;;
        python3) VERSION="$(python3 --version 2>/dev/null || echo unknown)" ;;
        node)    VERSION="$(node --version 2>/dev/null || echo unknown)" ;;
        npm)     VERSION="$(npm --version 2>/dev/null || echo unknown)" ;;
        docker)  VERSION="$(docker --version 2>/dev/null || echo unknown)" ;;
        *)       VERSION="available" ;;
      esac
      record_check PASS "$label installed" "$VERSION"
    else
      record_check WARN "$label installed" "Not found in PATH -- may need installation or shell reload"
    fi
  done

  for app in "IntelliJ IDEA" "Docker" "Visual Studio Code" "Obsidian" "Postman" "Google Chrome" "Raycast"; do
    STATUS="$(check_app "$app")"
    if [[ "$STATUS" == "PASS" ]]; then
      record_check PASS "$app app present" "Found"
    else
      record_check WARN "$app app present" "Not found"
    fi
  done

  for cmd_label in "mvn:Maven" "nvm:nvm" "groovy:Groovy" "kotlin:Kotlin" "fly:fly" "xcodebuild:Xcodebuild"; do
    cmd="${cmd_label%%:*}"
    label="${cmd_label##*:}"
    STATUS="$(check_command "$cmd")"
    if [[ "$STATUS" == "PASS" ]]; then
      record_check PASS "$label installed" "Found in PATH"
    else
      record_check WARN "$label installed" "Not found in PATH -- may need installation or shell reload"
    fi
  done

  if command -v xcode-select >/dev/null 2>&1; then
    XCODE_PATH="$(xcode-select -p 2>/dev/null || true)"
    if [[ -n "$XCODE_PATH" ]]; then
      record_check PASS "xcode-select path configured" "$XCODE_PATH"
    else
      record_check WARN "xcode-select path configured" "Not configured yet -- run xcode-select --install"
    fi
  else
    record_check WARN "xcode-select path configured" "xcode-select not found"
  fi

  # -------------------------------------------------------------------------
  record_section "Development Environment Extras"
  # -------------------------------------------------------------------------
  if [[ -f "$REPO_ROOT/reimaging-guide.md" && -d "$REPO_ROOT/bin" && -d "$REPO_ROOT/.internal" ]]; then
    if [[ -d "$REPO_ROOT/.git" ]]; then
      record_check PASS "fractogenesis-toolkit checkout" "$REPO_ROOT -- Git checkout available"
    else
      record_check WARN "fractogenesis-toolkit checkout" "$REPO_ROOT -- toolkit files are available, but this is not a Git checkout"
    fi
  else
    record_check WARN "fractogenesis-toolkit checkout" "$REPO_ROOT is missing expected toolkit files or directories"
  fi

  if command -v brew >/dev/null 2>&1; then
    BREW_DOCTOR_OUT="$(brew doctor 2>&1 || true)"
    if echo "$BREW_DOCTOR_OUT" | grep -qi "ready to brew"; then
      record_check PASS "brew doctor" "System is ready to brew"
    else
      record_check WARN "brew doctor" "brew doctor reported issues -- review output"
    fi
  else
    record_check WARN "brew doctor" "Homebrew not installed"
  fi

  if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
      record_check PASS "Docker daemon reachable" "docker info succeeded"
    else
      record_check WARN "Docker daemon reachable" "docker info failed -- start Docker Desktop"
    fi
    RABBITMQ_COUNT="$(docker ps -a --filter name=rabbitmq --format '{{.Names}}' 2>/dev/null | wc -l | tr -d ' ')"
    if [[ "$RABBITMQ_COUNT" -gt 0 ]]; then
      record_check PASS "RabbitMQ container present" "$RABBITMQ_COUNT container(s) found"
    else
      record_check WARN "RabbitMQ container present" "Not found -- recreate if a project needs it"
    fi
  else
    record_check WARN "Docker daemon reachable" "Docker CLI not found"
    record_check WARN "RabbitMQ container present" "Docker CLI not found"
  fi

  JSSECACERTS_FOUND="$(find /Library/Java/JavaVirtualMachines /Applications -path "*/lib/security/jssecacerts" -type f 2>/dev/null | head -1)"
  if [[ -n "$JSSECACERTS_FOUND" ]]; then
    record_check PASS "Corporate jssecacerts candidate found" "$JSSECACERTS_FOUND"
  else
    record_check WARN "Corporate jssecacerts candidate found" "None found under installed JDKs or IntelliJ bundled JBR"
  fi

  if git config --global --list >/dev/null 2>&1 && [[ -n "$(git config --global --list 2>/dev/null)" ]]; then
    record_check PASS "Global git config restored" "git config --global --list is non-empty"
  else
    record_check WARN "Global git config restored" "Global git config appears empty"
  fi

  SSH_GITHUB_OUT="$(mktemp)"
  run_with_timeout 10 "$SSH_GITHUB_OUT" ssh -T git@github.com -o BatchMode=yes -o ConnectTimeout=8
  if grep -qi "successfully authenticated" "$SSH_GITHUB_OUT" 2>/dev/null; then
    record_check PASS "Git work SSH (github.com) authenticated" "successfully authenticated"
  else
    record_check WARN "Git work SSH (github.com) authenticated" "Not confirmed within 10s -- check SSH key/agent or VPN"
  fi
  rm -f "$SSH_GITHUB_OUT"

  if command -v git-together >/dev/null 2>&1; then
    record_check PASS "git-together installed" "$(git-together --version 2>&1 | head -1 || echo 'found')"
  else
    record_check SKIP "git-together installed" "Not found -- optional tool, confirm decision to use or skip it"
  fi

  DOTFILES_MISSING=""
  for f in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.gitconfig" "$HOME/.ssh/config"; do
    [[ -f "$f" ]] || DOTFILES_MISSING="${DOTFILES_MISSING}${DOTFILES_MISSING:+, }$(basename "$f")"
  done
  if [[ -z "$DOTFILES_MISSING" ]]; then
    record_check PASS "Shell dotfiles present" ".zshrc, .zprofile, .gitconfig, ssh/config all found"
  else
    record_check WARN "Shell dotfiles present" "Missing: $DOTFILES_MISSING"
  fi

  # -------------------------------------------------------------------------
  record_section "Git Repository Status"
  # -------------------------------------------------------------------------
  # FAIL, not WARN: an empty global identity means Phase 11A did not complete.
  # Every commit made afterwards is mis-attributed, and the damage is only
  # discoverable by rewriting history later.
  GIT_G_NAME="$(git config --global user.name 2>/dev/null || true)"
  GIT_G_EMAIL="$(git config --global user.email 2>/dev/null || true)"
  if [[ -n "$GIT_G_NAME" && -n "$GIT_G_EMAIL" ]]; then
    record_check PASS "Global Git identity" "$GIT_G_NAME <$GIT_G_EMAIL>"
  else
    record_check FAIL "Global Git identity" "user.name/user.email not set globally -- re-run restore-git.md (Phase 11A) before committing anything"
  fi

  # The dual-identity setup is what keeps work commits off personal repos. An
  # absent includeIf means the personal root silently inherits the work identity.
  if git config --global --get-regexp '^includeIf' >/dev/null 2>&1; then
    record_check PASS "Git conditional include (dual identity)" "includeIf present in global config"
  else
    record_check WARN "Git conditional include (dual identity)" "No includeIf -- personal repos will use the work identity; see restore-git.md"
  fi

  # FAIL, not WARN: signing off with a decrypted secrets volume still attached
  # leaves every credential in the DMG readable to anything running on the Mac.
  ATTACHED_DMG="$(hdiutil info 2>/dev/null | grep -c 'all-secrets' || true)"
  [[ -n "$ATTACHED_DMG" ]] || ATTACHED_DMG=0
  if [[ "$ATTACHED_DMG" -eq 0 ]]; then
    record_check PASS "Secrets DMG detached" "No all-secrets image attached"
  else
    record_check FAIL "Secrets DMG detached" "A secrets DMG is still attached -- hdiutil detach it before signing off"
  fi

  if [[ ${#WORKSPACE_ROOTS[@]} -gt 0 ]]; then
    for WROOT in "${WORKSPACE_ROOTS[@]}"; do
      if [[ -d "$WROOT" ]]; then
        REPO_COUNT="$(find "$WROOT" -maxdepth 4 -name ".git" \( -type d -o -type f \) 2>/dev/null | wc -l | tr -d ' ')"
        if [[ $REPO_COUNT -gt 0 ]]; then
          record_check PASS "Git repos in $WROOT" "${REPO_COUNT} repo(s) found"
        else
          record_check WARN "Git repos in $WROOT" "No repos found -- may not be cloned yet"
        fi
      else
        record_check WARN "Workspace root $WROOT" "Directory does not exist -- not cloned yet"
      fi
    done
  else
    record_check SKIP "Git workspace roots" "No workspace roots configured"
  fi

  # -------------------------------------------------------------------------
  record_section "Network"
  # -------------------------------------------------------------------------
  if curl -sI --max-time 8 https://github.com >/dev/null 2>&1; then
    record_check PASS "Public network (github.com)" "Reachable"
  else
    record_check WARN "Public network (github.com)" "Not reachable -- check Wi-Fi/VPN"
  fi

  if curl -sI --max-time 8 https://login.microsoftonline.com >/dev/null 2>&1; then
    record_check PASS "Microsoft login endpoint" "Reachable"
  else
    record_check WARN "Microsoft login endpoint" "Not reachable -- check Wi-Fi/VPN"
  fi

  if [[ -n "$INTERNAL_URL" ]]; then
    if curl -sI --max-time 8 "$INTERNAL_URL" >/dev/null 2>&1; then
      record_check PASS "Internal network ($INTERNAL_URL)" "Reachable"
    else
      record_check WARN "Internal network ($INTERNAL_URL)" "Not reachable -- check VPN/Zscaler"
    fi
  else
    record_check SKIP "Internal network check" "Pass --internal-url URL to enable"
  fi

  # -------------------------------------------------------------------------
  record_section "Time Machine"
  # -------------------------------------------------------------------------
  TM_DEST="$(tmutil destinationinfo 2>/dev/null || true)"
  if echo "$TM_DEST" | grep -qi "^[[:space:]]*Name[[:space:]]*:"; then
    record_check PASS "Time Machine destination configured" "$(echo "$TM_DEST" | grep -i "Name" | head -1 | sed 's/^ *//')"
  else
    record_check WARN "Time Machine destination configured" "No destination configured yet"
  fi

  TM_LATEST_CHECK="$(tmutil latestbackup 2>/dev/null || true)"
  if [[ -n "$TM_LATEST_CHECK" ]]; then
    TM_LATEST_NAME="$(basename "$TM_LATEST_CHECK")"
    # A non-empty tmutil latestbackup is not evidence of a POST-image backup:
    # a destination still holding the pre-erase backup answers just as happily.
    # tmutil names backups YYYY-MM-DD-HHMMSS[.backup]; reduce that to the same
    # sortable YYYYMMDD-HHMMSS stamp the Phase 8/9 evidence bundles use and
    # compare the two lexicographically (equivalent to chronologically here).
    #
    # The bundle-side extraction below anchors the stamp to the END of the
    # directory name. An optional --context label therefore leads the name --
    # <label>-record-enrollment-<stamp> -- and never trails it: a trailing
    # label fails this match, gets filtered out by the grep, and leaves
    # POST_EVIDENCE_STAMP empty -- at which point this check degrades to a
    # cheerful "age not comparable" PASS and stops catching a pre-erase backup,
    # which is the entire reason it exists. The globs carry a leading wildcard
    # for the same reason: the artifact name is no longer at the start.
    TM_STAMP="$(printf '%s\n' "$TM_LATEST_NAME" | sed -e 's/\.backup$//' -e 's/^\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\)-\([0-9]\{6\}\)$/\1\2\3-\4/')"
    case "$TM_STAMP" in
      [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
      *) TM_STAMP="" ;;
    esac
    # -maxdepth 3 and the run-grammar name: indexed runs sit at
    # <category>/runs/<id>, one level deeper than the enrollment bundles, which
    # still use the [context-]record-enrollment-<stamp> form at depth 2.
    POST_EVIDENCE_STAMP="$(find "$REIMAGE_ARTIFACT_ROOT/reimaged-system" -maxdepth 3 -type d \( -name "verify-reimaged-system-*" -o -name "*record-enrollment-*" \) 2>/dev/null | sed -e 's#.*/##' -e 's/^.*-\([0-9]\{8\}-[0-9]\{6\}\)$/\1/' | grep -E '^[0-9]{8}-[0-9]{6}$' | sort | tail -1)"
    if [[ -n "$TM_STAMP" && -n "$POST_EVIDENCE_STAMP" ]]; then
      if [[ "$TM_STAMP" < "$POST_EVIDENCE_STAMP" ]]; then
        record_check WARN "Time Machine latest backup" "$TM_LATEST_NAME predates the reimaged-system evidence bundle ($POST_EVIDENCE_STAMP) -- this is the pre-erase backup. Expected until Phase 16 runs the post-image backup after Restore Home; rerun this checklist afterwards to close the row"
      else
        record_check PASS "Time Machine latest backup" "$TM_LATEST_NAME (newer than reimaged-system bundle $POST_EVIDENCE_STAMP)"
      fi
    else
      record_check PASS "Time Machine latest backup" "$TM_LATEST_NAME (age not comparable -- no timestamped reimaged-system bundle to compare against)"
    fi
  else
    record_check WARN "Time Machine latest backup" "No completed backup found yet"
  fi

  # -------------------------------------------------------------------------
  record_section "Reimaged-System Evidence Bundle"
  # -------------------------------------------------------------------------
  POST_DIR="$REIMAGE_ARTIFACT_ROOT/reimaged-system"

  POST_ENROLLMENT="$(newest_stamped_dir "$POST_DIR/enrollment" "*record-enrollment-*")"
  if [[ -n "$POST_ENROLLMENT" ]]; then
    record_check PASS "reimaged-system/enrollment" "$(basename "$POST_ENROLLMENT")"
  else
    record_check WARN "reimaged-system/enrollment" "Empty -- run bin/record-enrollment.sh"
  fi

  # Resolved through the run index, not a glob. The first-boot bundles moved to
  # reimaged-system/restarts/runs/ and were renamed to the run grammar, so the
  # old `*initial-reimaged-system-*` search at -maxdepth 1 matches nothing --
  # wrong name, and one level too shallow. Asking the index also separates two
  # states the glob could not: never having run it, and having run the
  # pre-restart half and never come back after the restart. The second is the
  # one worth catching, because it looks like progress.
  RESTARTS_ROOT="$POST_DIR/restarts"
  POST_INITIAL="$(artifact_run_official "$RESTARTS_ROOT" "verify-reimaged-system-post-restart" 2>/dev/null)"
  POST_INITIAL_PRE="$(artifact_run_official "$RESTARTS_ROOT" "verify-reimaged-system-pre-restart" 2>/dev/null)"
  if [[ -n "$POST_INITIAL" ]]; then
    record_check PASS "reimaged-system/restarts (post-restart)" "$(basename "$POST_INITIAL")"
  elif [[ -n "$POST_INITIAL_PRE" ]]; then
    record_check WARN "reimaged-system/restarts (post-restart)" "Pre-restart run $(basename "$POST_INITIAL_PRE") exists but no post-restart one -- the pair is incomplete. Run bin/record-reimaged-system.sh --context post-restart"
  else
    record_check WARN "reimaged-system/restarts (post-restart)" "Empty -- run bin/record-reimaged-system.sh --context pre-restart, restart, then --context post-restart"
  fi

  if dir_nonempty "$REIMAGE_ARTIFACT_ROOT/performance-audit"; then
    # Look specifically for a post-image performance bundle (naming matches capture-performance-audit.sh: <phase>-performance-audit-<scenario>-YYYYMMDD-HHMMSS)
    POST_PERF="$(newest_stamped_dir "$REIMAGE_ARTIFACT_ROOT/performance-audit" "post-image-performance-audit-*")"
    if [[ -n "$POST_PERF" ]]; then
      record_check PASS "Post-image performance audit bundle" "$(basename "$POST_PERF")"
    else
      record_check WARN "Post-image performance audit bundle" "No post-image-performance-audit-* bundle yet -- run capture-performance-audit.sh --phase post-image"
    fi

    # A post-image bundle for SOME scenario is not enough: the before/after
    # comparison is per scenario, so a pre-image scenario with no matching
    # post-image bundle makes that comparison silently empty. Derive the
    # scenario set from the pre-image bundle names (prefix and trailing
    # -YYYYMMDD-HHMMSS stripped) and report each one.
    PRE_PERF_SCENARIOS="$(find "$REIMAGE_ARTIFACT_ROOT/performance-audit" -maxdepth 1 -type d -name "pre-image-performance-audit-*" 2>/dev/null | sed -e 's#.*/##' -e 's/^pre-image-performance-audit-//' -e 's/-[0-9]\{8\}-[0-9]\{6\}$//' | grep -v '^$' | sort -u)"
    for perf_scenario in $PRE_PERF_SCENARIOS; do
      # Existence test, not a newest-selection: any match answers the question, so
      # no stamp ranking is needed here.
      if [[ -n "$(find "$REIMAGE_ARTIFACT_ROOT/performance-audit" -maxdepth 1 -type d -name "post-image-performance-audit-$perf_scenario-*" 2>/dev/null | head -1)" ]]; then
        record_check PASS "Performance scenario comparable: $perf_scenario" "pre-image and post-image bundles both present"
      else
        record_check WARN "Performance scenario comparable: $perf_scenario" "No post-image-performance-audit-$perf_scenario-* bundle -- run capture-performance-audit.sh --phase post-image --scenario $perf_scenario"
      fi
    done
  else
    record_check WARN "Performance audit directory" "Empty"
  fi

  if dir_nonempty "$REIMAGE_ARTIFACT_ROOT/office-stability"; then
    POST_OFFICE="$(newest_stamped_dir "$REIMAGE_ARTIFACT_ROOT/office-stability" "post-reimage-*")"
    if [[ -n "$POST_OFFICE" ]]; then
      record_check PASS "Post-image Office stability bundle" "$(basename "$POST_OFFICE")"
    else
      record_check WARN "Post-image Office stability bundle" "No post-reimage-* bundle yet -- run capture-office-stability.sh --phase post-reimage"
    fi
  else
    record_check WARN "Office stability directory" "Empty"
  fi

  TM_EXCLUSION_STATUS="$(tmutil isexcluded "$EXTERNAL_DATA_VOLUME" 2>/dev/null || true)"
  if printf '%s\n' "$TM_EXCLUSION_STATUS" | grep -q '^\[Excluded\]'; then
    record_check PASS "External data volume excluded from Time Machine" "$EXTERNAL_DATA_VOLUME"
  elif [[ -n "$TM_EXCLUSION_STATUS" ]]; then
    record_check WARN "External data volume excluded from Time Machine" "$EXTERNAL_DATA_VOLUME is not reported as excluded -- review tmutil output"
  else
    record_check WARN "External data volume excluded from Time Machine" "Could not determine exclusion status for $EXTERNAL_DATA_VOLUME"
  fi

  # -------------------------------------------------------------------------
  record_section "Post-Image Backup Root Summary"
  # -------------------------------------------------------------------------
  TOTAL_FILES="$(find "$REIMAGE_ARTIFACT_ROOT" -type f 2>/dev/null | wc -l | tr -d ' ')"
  TOTAL_SIZE="$(du -sh "$REIMAGE_ARTIFACT_ROOT" 2>/dev/null | cut -f1)"
  record_check PASS "Backup root total" "$TOTAL_SIZE across $TOTAL_FILES files"

fi   # end reimaged-system checks

# =============================================================================
# TERMINAL SUMMARY
# =============================================================================
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

if [[ $FAIL -gt 0 ]]; then
  NEXT_PHASE="Phase 7"
  [[ "$PHASE" == "post" ]] && NEXT_PHASE="sign-off"
  printf "  %b[STOP] %d critical failure(s) -- do NOT proceed to %s.%b\n" "$RED" "$FAIL" "$NEXT_PHASE" "$RESET"
elif [[ $WARN -gt 0 ]]; then
  printf "  %b[WARN] %d warning(s) -- review before proceeding.%b\n" "$YELLOW" "$WARN" "$RESET"
else
  NEXT="Phase 7 -- Reimage"
  [[ "$PHASE" == "post" ]] && NEXT="manual sign-off"
  printf "  %b[OK] All checks passed. Proceed to %s.%b\n" "$GREEN" "$NEXT" "$RESET"
fi
printf "\n"

# =============================================================================
# WRITE MARKDOWN REPORT
# =============================================================================
{
  if [[ "$PHASE" == "pre" ]]; then
    printf "# Phase 6B -- Final Pre-Image Validation Checklist\n\n"
  else
    printf "# Phase 14 -- Final Post-Image Validation Checklist\n\n"
  fi

  printf "Generated: \`%s\`\n\n" "$TIMESTAMP"
  printf "| | |\n| --- | --- |\n"
  printf "| **Phase** | \`%s\` |\n" "$PHASE"
  printf "| **EXTERNAL_DATA_VOLUME** | \`%s\` |\n" "$EXTERNAL_DATA_VOLUME"
  printf "| **REIMAGE_ARTIFACT_ROOT** | \`%s\` |\n" "$REIMAGE_ARTIFACT_ROOT"
  printf "| **PASS** | %d |\n" "$PASS"
  printf "| **WARN** | %d |\n" "$WARN"
  printf "| **FAIL** | %d |\n" "$FAIL"
  printf "| **SKIP** | %d |\n\n" "$SKIP"

  if [[ $FAIL -gt 0 ]]; then
    printf "> **[STOP] %d critical failure(s) -- do NOT proceed.**\n\n" "$FAIL"
  elif [[ $WARN -gt 0 ]]; then
    printf "> **[WARN] %d warning(s) -- review before proceeding.**\n\n" "$WARN"
  else
    printf "> **[OK] All automated checks passed.**\n\n"
  fi

  printf "%s\n\n" "---"
  printf "%s\n" "$REPORT"
  printf "%s\n\n" "---"

  if [[ "$PHASE" == "pre" ]]; then
    printf "## Manual Sign-Off (Pre-Image)\n\n"
    printf "Complete these items manually before proceeding to Phase 7:\n\n"
    printf "| Item | Confirmed |\n| --- | --- |\n"
    printf "| IT confirmed approved reimage method in writing | TODO |\n"
    printf "| LastPass vault verified accessible at lastpass.com | TODO |\n"
    printf "| DMG password saved to LastPass immediately after creation | TODO |\n"
    printf "| DMG verified -- opens in Finder; gnupg/private-keys-v1.d/, ssh/, and certs/java-security/ present | TODO |\n"
    printf "| Time Machine backup completed and tmutil latestbackup confirmed | TODO |\n"
    printf "| OneDrive -- no pending uploads (check menu bar icon and web spot-check) | TODO |\n"
    printf "| iCloud Drive -- no pending uploads for relied-on files, if used | TODO |\n"
    printf "| VS Code Settings Sync state confirmed (signed-in account, on/off, last synced data) | TODO |\n"
    printf "| Obsidian vault synced or manually copied | TODO |\n"
    printf "| Export passwords (.p12/.pfx, DMG) saved only in approved password manager | TODO |\n"
    printf "| Loose private-key/keystore/certificate candidates reviewed | TODO |\n"
    printf "| All important branches pushed to remote | TODO |\n"
    printf "| Stashes converted to branches/commits or intentionally abandoned | TODO |\n"
    if [[ -n "${EXTERNAL_APPLE_BACKUPS_VOLUME:-}" ]]; then
      printf "| External volumes ejected before reimage starts (\`%s\` and \`%s\`) | TODO |\n" "$EXTERNAL_DATA_VOLUME" "$EXTERNAL_APPLE_BACKUPS_VOLUME"
    else
      printf "| External data volume ejected before reimage starts (\`%s\`) | TODO |\n" "$EXTERNAL_DATA_VOLUME"
    fi
  else
    printf "## Manual Sign-Off (Post-Image)\n\n"
    printf "Complete these items manually before final sign-off:\n\n"
    printf "| Item | Result | Notes |\n| --- | --- | --- |\n"
    printf "| Company Portal shows device registered/compliant | TODO | Confirm in Company Portal UI |\n"
    printf "| VPN / Zscaler can reach real internal work sites | TODO | Use browser; optional --internal-url evidence |\n"
    printf "| OneDrive sync completed or backlog is acceptable | TODO | Confirm from OneDrive menu bar |\n"
    printf "| Outlook remains open during normal use | TODO | Observe after managed install/update activity settles |\n"
    printf "| OneNote remains open during normal use | TODO | Observe after managed install/update activity settles |\n"
    printf "| IntelliJ opens important projects successfully | TODO | Confirm SDK, Gradle JVM, run configs, plugins, scratches |\n"
    printf "| HTTP Client private env files restored only where intended | TODO | Manual -- sensitive and project-specific |\n"
    printf "| Docker Desktop resource settings match intended values | TODO | Confirm in Docker Desktop UI |\n"
    printf "| Important Git branches/commits/stashes restored | TODO | Review raw git-repos-summary if available |\n"
    printf "| Core Java/Gradle project test passes | TODO | Run project-specific tests |\n"
    printf "| Corporate Java TLS works after jssecacerts restore | TODO | Validate with internal Maven/Gradle |\n"
    printf "| Core Python project test passes | TODO | Run project-specific tests |\n"
    printf "| Core Node/UI project test passes | TODO | Run project-specific tests |\n"
    printf "| Obsidian vault opens and internal links work | TODO | Confirm Reading View and Cmd-click in Live Preview |\n"
    printf "| Postman collections/environments imported | TODO | Confirm in Postman UI |\n"
    printf "| Chrome JSON Formatter and important extensions restored | TODO | Confirm in Chrome extension UI |\n"
    printf "| Display arrangement, scaling, keyboard, mouse, audio correct | TODO | Confirm physically |\n"
    if [[ -n "${GIT_WORK_REPO_ROOT:-}" ]]; then
      printf "| Work Git identity confirmed in configured work repo root | TODO | %s; verify git config user.email |\n" "$GIT_WORK_REPO_ROOT"
    else
      printf "| Work Git identity confirmed in a real work repo | TODO | GIT_WORK_REPO_ROOT is not configured; verify git config user.email in an actual work repo |\n"
    fi
    if [[ -n "${GIT_PERSONAL_REPO_ROOT:-}" ]]; then
      printf "| Personal Git identity confirmed in configured personal repo root | TODO | %s; verify git config user.email |\n" "$GIT_PERSONAL_REPO_ROOT"
    else
      printf "| Personal Git identity confirmed, if personal repos are used | TODO | GIT_PERSONAL_REPO_ROOT is not configured |\n"
    fi
    printf "| Personal SSH (github-personal) authenticated | TODO | ssh -T git@github-personal |\n"
    printf "| SSH key fingerprints match GitHub Settings | TODO | ssh-keygen -lf against both keys |\n"
    printf "| Git Together decision made (use it or skip it) | TODO | Confirm installed and alias working, or document the decision to skip |\n"
    printf "| Shell aliases restored and tested | TODO | Source ~/.zshrc; confirm ll, jdk17, nvm |\n"
    printf "| Second reimaged-system Time Machine backup completed | TODO | Run after restart and validation |\n"
  fi

  printf "\n%s\n\n" "---"
  printf "*Report generated by \`%s\` at %s*\n" "$SCRIPT_NAME" "$TIMESTAMP"
} > "$REPORT_FILE"

if [[ ! -s "$REPORT_FILE" ]]; then
  echo "ERROR: checklist report was not written: $REPORT_FILE" >&2
  exit 2
fi
printf "  Report written to:\n  %s\n\n" "$REPORT_FILE"

# Latest-pointer convenience file
printf '%s\n' "$REPORT_FILE" > "$OUTPUT_ROOT/latest-reimage-checklist.txt" 2>/dev/null || true

if [[ "$OPEN_RESULT" == "true" ]]; then
  open "$OUTPUT_ROOT" 2>/dev/null || true
fi

# Exit non-zero if any failures
[[ $FAIL -eq 0 ]]
