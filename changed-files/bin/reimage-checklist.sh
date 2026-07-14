#!/usr/bin/env bash
# =============================================================================
# reimage-checklist.sh
#
# Unified validation checklist for both the pre-image reimage-prep-checks
# (Phase 4B) and post-image reimaged-system (Phase 12) Mac reimage workflow
# stages.
#
# Usage:
#   cd <repo-root>
#   chmod +x bin/reimage-checklist.sh
#
#   # Phase 4B -- final reimage-prep-checks validation
#   ./bin/reimage-checklist.sh --phase pre
#
#   # Phase 12 -- final reimaged-system validation
#   ./bin/reimage-checklist.sh --phase post
#
#   # Override artifact root
#   ./bin/reimage-checklist.sh --phase pre --artifact-root /Volumes/Data/reimage-backup-YYYYMMDD
#
#   # Open output in Finder after run
#   ./bin/reimage-checklist.sh --phase post --open
#
# Options:
#   --phase pre|post       Required. Which checklist to run.
#   --artifact-root PATH     Override REIMAGE_ARTIFACT_ROOT from reimage.env.
#   --output-root PATH     Override where the report bundle is written.
#                          Default: $REIMAGE_ARTIFACT_ROOT/reimage-prep-checks         (pre)
#                                   $REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists  (post)
#   --workspace-root PATH  Workspace root to scan for Git repo status.
#                          Can be repeated. (post only)
#   --internal-url URL     Optional internal URL to verify VPN/network. (post only)
#   --no-color             Disable colored terminal output.
#   --open                 Open the output directory in Finder after run.
#   -h, --help             Show this message and exit.
#
# The script exits non-zero when any FAIL items are found so it can be used
# in shell pipelines and makefiles.
# =============================================================================

set -uo pipefail
# NOTE: intentionally NOT set -e. Arithmetic and checks that return non-zero
# must not abort the script; every check must produce a PASS/WARN/FAIL line.

# ── Load shared reimage config ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# This script lives at <repo>/bin/reimage-checklist.sh, so .internal/ is a
# sibling of bin/, one level up from this script's own directory.
CONFIG_LOADER="$(dirname "$SCRIPT_DIR")/.internal/load-reimage-config.sh"
if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_NAME="${REIMAGE_SCRIPT_DISPLAY_NAME:-reimage-checklist.sh}"
PHASE=""
OUTPUT_ROOT=""
OPEN_RESULT="false"
USE_COLOR=true
WORKSPACE_ROOTS=()
INTERNAL_URL=""

usage() {
  sed -n 's/^# \{0,2\}//p' "$0" | head -40
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)
      PHASE="${2:-}"
      shift 2
      ;;
    --artifact-root)
      REIMAGE_ARTIFACT_ROOT="${2:-}"
      shift 2
      ;;
    --output-root)
      OUTPUT_ROOT="${2:-}"
      shift 2
      ;;
    --workspace-root)
      WORKSPACE_ROOTS+=("${2:-}")
      shift 2
      ;;
    --internal-url)
      INTERNAL_URL="${2:-}"
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
  echo "Error: --phase pre|post is required." >&2
  usage >&2
  exit 2
fi

case "$PHASE" in
  pre|post) ;;
  *)
    echo "Error: --phase must be 'pre' or 'post', got: '$PHASE'" >&2
    exit 2
    ;;
esac

if [[ -z "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "Error: REIMAGE_ARTIFACT_ROOT is not set. Source reimage.env or pass --artifact-root PATH." >&2
  exit 2
fi

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
mkdir -p "$OUTPUT_ROOT"

# Ensure the standard reimaged-system subdirectories exist if post
if [[ "$PHASE" == "post" && -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  mkdir -p \
    "$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists" \
    "$REIMAGE_ARTIFACT_ROOT/reimaged-system/time-machine" \
    "$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts" \
    "$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Default workspace roots (post only)
# ---------------------------------------------------------------------------
if [[ "$PHASE" == "post" && ${#WORKSPACE_ROOTS[@]} -eq 0 ]]; then
  [[ -d "$HOME/Development/IdeaProjects" ]]  && WORKSPACE_ROOTS+=("$HOME/Development/IdeaProjects")
  [[ -d "$HOME/Development/Documentation" ]] && WORKSPACE_ROOTS+=("$HOME/Development/Documentation")
  [[ -d "$HOME/Development/documentation" ]] && WORKSPACE_ROOTS+=("$HOME/Development/documentation")
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
  [[ -d "$dir" ]] && [[ -n "$(find "$dir" -maxdepth 3 -type f 2>/dev/null | head -1)" ]]
}

newest_matching() {
  local dir="$1" pattern="$2"
  find "$dir" -maxdepth 3 -name "$pattern" -type f 2>/dev/null | sort | tail -1
}

file_age_hours() {
  local f="$1"
  if [[ ! -f "$f" ]]; then echo 999; return; fi
  local now mtime
  now="$(date +%s)"
  mtime="$(stat -f %m "$f" 2>/dev/null || echo 0)"
  echo $(( (now - mtime) / 3600 ))
}

check_app() {
  local app_name="$1"
  if [[ -d "/Applications/$app_name.app" || -d "$HOME/Applications/$app_name.app" ]]; then
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
PHASE_LABEL="Phase 4B — Reimage Preparation Checks"
[[ "$PHASE" == "post" ]] && PHASE_LABEL="Phase 12 — Reimaged System Checks"

printf "\n"
printf "%b+--------------------------------------------------------------+%b\n" "$BOLD" "$RESET"
printf "%b|  %-60s|%b\n" "$BOLD" "$PHASE_LABEL" "$RESET"
printf "%b+--------------------------------------------------------------+%b\n" "$BOLD" "$RESET"
printf "\n"
printf "  PHASE       : %s\n" "$PHASE"
printf "  REIMAGE_ARTIFACT_ROOT : %s\n" "$REIMAGE_ARTIFACT_ROOT"
printf "  Report      : %s\n" "$REPORT_FILE"
printf "  Timestamp   : %s\n" "$TIMESTAMP"
printf "\n"

# =============================================================================
# SHARED CHECKS — run for both pre and post
# =============================================================================

# ---------------------------------------------------------------------------
record_section "External Drive and Backup Root"
# ---------------------------------------------------------------------------

VOLUMES_DATA="$(dirname "$REIMAGE_ARTIFACT_ROOT")"
if [[ -d "$VOLUMES_DATA" ]]; then
  record_check PASS "External backup volume mounted" "$VOLUMES_DATA exists"
else
  record_check FAIL "External backup volume mounted" "$VOLUMES_DATA not found -- drive not mounted"
fi

if [[ -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  record_check PASS "Backup root exists" "$REIMAGE_ARTIFACT_ROOT"
else
  record_check FAIL "Backup root exists" "$REIMAGE_ARTIFACT_ROOT not found"
fi

if [[ -d "$VOLUMES_DATA" ]]; then
  FREE_KB="$(df -k "$VOLUMES_DATA" 2>/dev/null | awk 'NR==2{print $4}')"
  FREE_GB=$(( ${FREE_KB:-0} / 1048576 ))
  if [[ $FREE_GB -ge 5 ]]; then
    record_check PASS "External drive free space" "${FREE_GB} GB free"
  elif [[ $FREE_GB -ge 1 ]]; then
    record_check WARN "External drive free space" "${FREE_GB} GB free -- low"
  else
    record_check FAIL "External drive free space" "${FREE_GB} GB free -- critically low"
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

BACKUP_BASENAME="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"
ONEDRIVE_MATCH="$(find "$HOME/Library/CloudStorage" -maxdepth 3 -type d -name "$BACKUP_BASENAME" 2>/dev/null | head -1)"
if [[ -n "$ONEDRIVE_MATCH" ]]; then
  MARKER_COUNT="$(find "$ONEDRIVE_MATCH" -maxdepth 1 -name "onedrive-upload-marker-*.txt" 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$MARKER_COUNT" -gt 0 ]]; then
    record_check PASS "OneDrive backup folder detected" "$ONEDRIVE_MATCH -- upload marker present (evidence only, not proof of sync)"
  else
    record_check WARN "OneDrive backup folder detected" "$ONEDRIVE_MATCH -- no upload marker found; confirm sync manually"
  fi
else
  record_check WARN "OneDrive backup folder detected" "No $BACKUP_BASENAME folder found under $HOME/Library/CloudStorage -- confirm OneDrive copy manually"
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
  for subdir in app-backups repo-audit-reports gitignore-superset managed-inventory office-stability performance-audit secrets-encrypted system-inventory workflow-snapshot; do
    if dir_nonempty "$REIMAGE_ARTIFACT_ROOT/$subdir"; then
      SIZE="$(du -sh "$REIMAGE_ARTIFACT_ROOT/$subdir" 2>/dev/null | cut -f1)"
      record_check PASS "Subdir: $subdir" "$SIZE on disk"
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
  LATEST_AUDIT="$(newest_matching "$REPO_AUDIT_DIR" "git-audit-summary-*.txt")"

  if [[ -n "$LATEST_AUDIT" ]]; then
    AGE_H="$(file_age_hours "$LATEST_AUDIT")"
    if [[ $AGE_H -le 24 ]]; then
      record_check PASS "Git audit report" "$(basename "$LATEST_AUDIT") (${AGE_H}h ago)"
    else
      record_check WARN "Git audit report" "$(basename "$LATEST_AUDIT") is ${AGE_H}h old -- consider re-running"
    fi
    if grep -qi "local.only\|unpushed\|no remote" "$LATEST_AUDIT" 2>/dev/null; then
      record_check WARN "Local-only commits" "Audit may still contain local-only commits -- review"
    else
      record_check PASS "Local-only commits" "No warnings found in audit"
    fi
    if grep -qi "stash" "$LATEST_AUDIT" 2>/dev/null; then
      record_check WARN "Stashes" "Stash references found -- confirm converted or abandoned"
    else
      record_check PASS "Stashes" "No stash references found"
    fi
  else
    record_check FAIL "Git audit report" "No git-audit-summary-*.txt under $REPO_AUDIT_DIR"
    record_check SKIP "Local-only commits" "Skipped -- no audit report"
    record_check SKIP "Stashes" "Skipped -- no audit report"
  fi

  if [[ -n "$(newest_matching "$REPO_AUDIT_DIR" "local-only-commits-*.tsv")" ]]; then
    record_check PASS "Git audit TSV present" "local-only-commits TSV found"
  else
    record_check WARN "Git audit TSV present" "Not found"
  fi

  UNTRACKED_TSV="$(newest_matching "$REPO_AUDIT_DIR" "untracked-nonignored-*.tsv")"
  if [[ -n "$UNTRACKED_TSV" ]]; then
    UNTRACKED_COUNT="$(($(wc -l <"$UNTRACKED_TSV" 2>/dev/null || echo 1) - 1))"
    if [[ "$UNTRACKED_COUNT" -gt 0 ]]; then
      record_check WARN "Untracked non-ignored files reviewed" "$(basename "$UNTRACKED_TSV") lists $UNTRACKED_COUNT file(s) -- review before reimage"
    else
      record_check PASS "Untracked non-ignored files reviewed" "$(basename "$UNTRACKED_TSV") -- none found"
    fi
  else
    record_check WARN "Untracked non-ignored files reviewed" "No untracked-nonignored-*.tsv under $REPO_AUDIT_DIR"
  fi

  # -------------------------------------------------------------------------
  record_section ".gitignore Superset and Selected Ignored Files"
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

  if dir_nonempty "$REIMAGE_ARTIFACT_ROOT/selected-ignored-files"; then
    SIZE="$(du -sh "$REIMAGE_ARTIFACT_ROOT/selected-ignored-files" 2>/dev/null | cut -f1)"
    record_check PASS "Selected ignored files copied" "$SIZE"
  else
    record_check WARN "Selected ignored files copied" "Empty -- intentional if no patterns needed"
  fi

  if dir_nonempty "$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-filtered-dryrun"; then
    record_check PASS "Filtered dry run completed" "Non-empty"
  else
    record_check WARN "Filtered dry run completed" "No results found"
  fi

  # -------------------------------------------------------------------------
  record_section "IntelliJ Backup"
  # -------------------------------------------------------------------------
  INTELLIJ_DIR="$REIMAGE_ARTIFACT_ROOT/app-backups/intellij"

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
  if [[ -n "$(find "$INTELLIJ_DIR" -name "*.zip" 2>/dev/null | head -1)" ]]; then
    record_check PASS "IntelliJ settings ZIP" "$(find "$INTELLIJ_DIR" -name "*.zip" 2>/dev/null | head -1 | xargs basename)"
  else
    record_check WARN "IntelliJ settings ZIP" "Not found -- File > Export Settings"
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
    record_check WARN "Extra certificate/Keychain review inventory" "Directory exists but no MANIFEST.md -- re-run stage-cert-keychain.sh"
  else
    record_check WARN "Extra certificate/Keychain review inventory" "No extra-secrets-certs-review/ under $SECRETS_DIR -- run stage-cert-keychain.sh"
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

  for danger in \
    "$HOME/Desktop/Chrome Passwords.csv" \
    "$HOME/Downloads/Chrome Passwords.csv" \
    "$HOME/Desktop/<company>-issuing-ca.pem" \
    "$HOME/Downloads/<company>-issuing-ca.pem"; do
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
    record_check FAIL "Performance audit captured" "Empty -- run capture-performance-audit.sh"
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
    record_check WARN "Office stability evidence present" "Empty -- run capture-office-stability-baseline.sh"
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
    record_check WARN "Time Machine status bundle" "Empty -- run capture-time-machine-status.sh"
  fi

  # -------------------------------------------------------------------------
  record_section "Workflow Snapshot and Manual Notes"
  # -------------------------------------------------------------------------
  WORKFLOW_SNAPSHOT_ROOT="$REIMAGE_ARTIFACT_ROOT/workflow-snapshot"
  APP_BACKUPS_ROOT="$REIMAGE_ARTIFACT_ROOT/app-backups"
  LOCAL_FILES_DIR="$REIMAGE_ARTIFACT_ROOT/local-files"

  LATEST_WORKFLOW_CAPTURE="$(
    find "$WORKFLOW_SNAPSHOT_ROOT" -maxdepth 1 -type d -name 'pre-image-workflow-snapshot-*' -print 2>/dev/null \
      | sort \
      | tail -1
  )"

  if [[ -n "$LATEST_WORKFLOW_CAPTURE" && -d "$LATEST_WORKFLOW_CAPTURE" ]]; then
    record_check PASS "Latest workflow snapshot" "$(basename "$LATEST_WORKFLOW_CAPTURE")"
  else
    record_check WARN "Latest workflow snapshot" "No pre-image-workflow-snapshot-* bundle found under $WORKFLOW_SNAPSHOT_ROOT"
  fi

  # Automated workflow snapshot material lives directly inside the newest timestamped
  # capture bundle:
  #
  #   $REIMAGE_ARTIFACT_ROOT/workflow-snapshot/pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/{logs,...}
  #
  # Stable hand-maintained/export folders stay directly under
  # app-backups/ and are checked separately.
  if dir_nonempty "$WORKFLOW_SNAPSHOT_ROOT/reimage-workflow-docs"; then
    record_check PASS "workflow-snapshot/reimage-workflow-docs" "$(du -sh "$WORKFLOW_SNAPSHOT_ROOT/reimage-workflow-docs" 2>/dev/null | cut -f1)"
  else
    record_check WARN "workflow-snapshot/reimage-workflow-docs" "Empty or missing"
  fi

  REIMAGE_PLAN_DIR="$REIMAGE_ARTIFACT_ROOT/reimage-plan"
  if [[ -n "$(find "$REIMAGE_PLAN_DIR" -maxdepth 1 -type f -name 'it-reimage-confirmation-*.md' -print -quit 2>/dev/null)" ]]; then
    record_check PASS "reimage-plan IT confirmation" "Found"
  else
    record_check WARN "reimage-plan IT confirmation" "Missing -- copy the filled IT confirmation into reimage-plan/"
  fi

  if [[ -f "$APP_BACKUPS_ROOT/vscode/extensions.txt" ]]; then
    EXT_COUNT="$(wc -l < "$APP_BACKUPS_ROOT/vscode/extensions.txt" 2>/dev/null | tr -d ' ')"
    record_check PASS "VS Code extensions.txt" "${EXT_COUNT} extensions"
  else
    record_check WARN "VS Code extensions.txt" "Not found in app-backups/vscode"
  fi

  DOTFILES_DIR="$LOCAL_FILES_DIR/dotfiles"
  if dir_nonempty "$DOTFILES_DIR"; then
    record_check PASS "local-files/dotfiles" "$(du -sh "$DOTFILES_DIR" 2>/dev/null | cut -f1)"
  else
    record_check WARN "local-files/dotfiles" "Empty or missing -- run Phase 2B local-files backup"
  fi

  POSTMAN_DIR="$APP_BACKUPS_ROOT/postman"
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
  if dir_nonempty "$LOCAL_FILES_DIR"; then
    record_check PASS "backup-local-files.sh run" "$(du -sh "$LOCAL_FILES_DIR" 2>/dev/null | cut -f1)"
  else
    record_check FAIL "backup-local-files.sh run" "Empty -- run backup-local-files.sh"
  fi
  if [[ -f "$LOCAL_FILES_DIR/MANIFEST.md" ]]; then
    record_check PASS "local-files/MANIFEST.md" "Found"
  else
    record_check WARN "local-files/MANIFEST.md" "Not found"
  fi

  # -------------------------------------------------------------------------
  record_section "App Backups"
  # -------------------------------------------------------------------------
  if [[ -f "$APP_BACKUPS_ROOT/MANIFEST.md" ]]; then
    record_check PASS "app-backups/MANIFEST.md" "Found"
  else
    record_check WARN "app-backups/MANIFEST.md" "Not found"
  fi

  VSCODE_DIR="$APP_BACKUPS_ROOT/vscode"
  if dir_nonempty "$VSCODE_DIR"; then
    record_check PASS "VS Code local fallback" "Non-empty"
  else
    record_check WARN "VS Code local fallback" "Empty -- run backup-apps.sh if VS Code applies"
  fi

  # -------------------------------------------------------------------------
  record_section "Docker and Chrome"
  # -------------------------------------------------------------------------
  DOCKER_DIR="$REIMAGE_ARTIFACT_ROOT/app-backups/docker"
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

  CHROME_DIR="$REIMAGE_ARTIFACT_ROOT/app-backups/chrome"
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

  FV_STATUS="$(fdesetup status 2>/dev/null || echo unknown)"
  if echo "$FV_STATUS" | grep -qi "FileVault is On"; then
    record_check PASS "FileVault" "$FV_STATUS"
  else
    record_check WARN "FileVault" "$FV_STATUS -- confirm FileVault is enabled"
  fi

  # -------------------------------------------------------------------------
  record_section "MDM and Security"
  # -------------------------------------------------------------------------
  MDM_RAW="$(profiles status -type enrollment 2>/dev/null || echo 'unknown')"
  if echo "$MDM_RAW" | grep -qi "enrolled"; then
    record_check PASS "MDM / Intune enrollment" "Enrolled"
  else
    record_check WARN "MDM / Intune enrollment" "Enrollment not confirmed -- check Company Portal"
  fi

  for app in "Company Portal" "CrowdStrike Falcon" "Zscaler"; do
    STATUS="$(check_app "$app")"
    if [[ "$STATUS" == "PASS" ]]; then
      record_check PASS "$app present" "Found in /Applications"
    else
      record_check WARN "$app present" "Not found -- may still be installing"
    fi
  done

  if pgrep -fl "CrowdStrike\|falcon" >/dev/null 2>&1; then
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

  SOFTWAREUPDATE_PENDING="$(softwareupdate --list 2>&1 | grep -c "^\s*\*" || true)"
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
  if [[ -d "$HOME/Development/documentation/reference-vault" ]]; then
    record_check PASS "reference-vault restored" "Found at ~/Development/documentation/reference-vault"
  else
    record_check WARN "reference-vault restored" "Not found at expected path -- clone/restore it"
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
  if [[ ${#WORKSPACE_ROOTS[@]} -gt 0 ]]; then
    for WROOT in "${WORKSPACE_ROOTS[@]}"; do
      if [[ -d "$WROOT" ]]; then
        REPO_COUNT="$(find "$WROOT" -maxdepth 3 -name ".git" -type d 2>/dev/null | wc -l | tr -d ' ')"
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

  # personal (non-work) repos
  if [[ -d "$HOME/<personal-projects-dir>" ]]; then
    PERSONAL_COUNT="$(find "$HOME/<personal-projects-dir>" -maxdepth 3 -name ".git" -type d 2>/dev/null | wc -l | tr -d ' ')"
    record_check PASS "Personal repos in ~/<personal-projects-dir>" "${PERSONAL_COUNT} repo(s)"
  else
    record_check WARN "Personal repos in ~/<personal-projects-dir>" "~/<personal-projects-dir> does not exist"
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
  if echo "$TM_DEST" | grep -qi "Name\s*:"; then
    record_check PASS "Time Machine destination configured" "$(echo "$TM_DEST" | grep -i "Name" | head -1 | sed 's/^ *//')"
  else
    record_check WARN "Time Machine destination configured" "No destination configured yet"
  fi

  TM_LATEST_CHECK="$(tmutil latestbackup 2>/dev/null || true)"
  if [[ -n "$TM_LATEST_CHECK" ]]; then
    record_check PASS "Time Machine latest backup" "$(basename "$TM_LATEST_CHECK")"
  else
    record_check WARN "Time Machine latest backup" "No completed backup found yet"
  fi

  # -------------------------------------------------------------------------
  record_section "Reimaged-System Evidence Bundle"
  # -------------------------------------------------------------------------
  POST_DIR="$REIMAGE_ARTIFACT_ROOT/reimaged-system"

  POST_ENROLLMENT="$(find "$POST_DIR/enrollment" -maxdepth 1 -type d -name "capture-enrollment-*" 2>/dev/null | sort | tail -1)"
  if [[ -n "$POST_ENROLLMENT" ]]; then
    record_check PASS "reimaged-system/enrollment" "$(basename "$POST_ENROLLMENT")"
  else
    record_check WARN "reimaged-system/enrollment" "Empty -- run bin/capture-enrollment.sh"
  fi

  POST_INITIAL="$(find "$POST_DIR" -maxdepth 1 -type d -name "initial-reimaged-system-*" 2>/dev/null | sort | tail -1)"
  if [[ -n "$POST_INITIAL" ]]; then
    record_check PASS "reimaged-system/initial-reimaged-system-*" "$(basename "$POST_INITIAL")"
  else
    record_check WARN "reimaged-system/initial-reimaged-system-*" "Empty -- run bin/initial-reimaged-system-checklist.sh"
  fi

  if dir_nonempty "$REIMAGE_ARTIFACT_ROOT/performance-audit"; then
    # Look specifically for a post-image performance bundle (naming matches capture-performance-audit.sh: <phase>-performance-audit-<scenario>-YYYYMMDD-HHMMSS)
    POST_PERF="$(find "$REIMAGE_ARTIFACT_ROOT/performance-audit" -maxdepth 1 -type d -name "post-image-performance-audit-*" 2>/dev/null | head -1)"
    if [[ -n "$POST_PERF" ]]; then
      record_check PASS "Post-image performance audit bundle" "$(basename "$POST_PERF")"
    else
      record_check WARN "Post-image performance audit bundle" "No post-image-performance-audit-* bundle yet -- run capture-performance-audit.sh --phase post-image"
    fi
  else
    record_check WARN "Performance audit directory" "Empty"
  fi

  if dir_nonempty "$REIMAGE_ARTIFACT_ROOT/office-stability"; then
    POST_OFFICE="$(find "$REIMAGE_ARTIFACT_ROOT/office-stability" -maxdepth 1 -type d -name "post-reimage-*" 2>/dev/null | head -1)"
    if [[ -n "$POST_OFFICE" ]]; then
      record_check PASS "Post-image Office stability bundle" "$(basename "$POST_OFFICE")"
    else
      record_check WARN "Post-image Office stability bundle" "No post-reimage-* bundle yet -- run capture-office-stability-baseline.sh --phase post-reimage"
    fi
  else
    record_check WARN "Office stability directory" "Empty"
  fi

  TM_EXCL="$(tmutil listexclusions 2>/dev/null | grep -c "Data" || true)"
  if [[ $TM_EXCL -gt 0 ]]; then
    record_check PASS "/Volumes/Data excluded from Time Machine" "Exclusion found"
  else
    record_check WARN "/Volumes/Data excluded from Time Machine" "Run: sudo tmutil addexclusion -v /Volumes/Data"
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
  NEXT_PHASE="Phase 5"
  [[ "$PHASE" == "post" ]] && NEXT_PHASE="sign-off"
  printf "  %b[STOP] %d critical failure(s) -- do NOT proceed to %s.%b\n" "$RED" "$FAIL" "$NEXT_PHASE" "$RESET"
elif [[ $WARN -gt 0 ]]; then
  printf "  %b[WARN] %d warning(s) -- review before proceeding.%b\n" "$YELLOW" "$WARN" "$RESET"
else
  NEXT="Phase 5 -- Reimage"
  [[ "$PHASE" == "post" ]] && NEXT="manual sign-off"
  printf "  %b[OK] All checks passed. Proceed to %s.%b\n" "$GREEN" "$NEXT" "$RESET"
fi
printf "\n"

# =============================================================================
# WRITE MARKDOWN REPORT
# =============================================================================
{
  if [[ "$PHASE" == "pre" ]]; then
    printf "# Phase 4B -- Final Pre-Image Validation Checklist\n\n"
  else
    printf "# Phase 11 -- Final Post-Image Validation Checklist\n\n"
  fi

  printf "Generated: \`%s\`\n\n" "$TIMESTAMP"
  printf "| | |\n| --- | --- |\n"
  printf "| **Phase** | \`%s\` |\n" "$PHASE"
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
    printf "Complete these items manually before proceeding to Phase 5:\n\n"
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
    printf "| Both Data and AppleBackups partitions ejected before reimage starts | TODO |\n"
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
    printf "| Work Git identity confirmed in a real work repo | TODO | git config user.email == <your-work-email> |\n"
    printf "| Personal Git identity confirmed inside ~/<personal-projects-dir>/ | TODO | git config user.email == <your-personal-email> |\n"
    printf "| Personal SSH (github-personal) authenticated | TODO | ssh -T git@github-personal |\n"
    printf "| SSH key fingerprints match GitHub Settings | TODO | ssh-keygen -lf against both keys |\n"
    printf "| Git Together decision made (use it or skip it) | TODO | Confirm installed and alias working, or document the decision to skip |\n"
    printf "| Shell aliases restored and tested | TODO | Source ~/.zshrc; confirm ll, jdk17, nvm |\n"
    printf "| Second reimaged-system Time Machine backup completed | TODO | Run after restart and validation |\n"
  fi

  printf "\n%s\n\n" "---"
  printf "*Report generated by \`%s\` at %s*\n" "$SCRIPT_NAME" "$TIMESTAMP"
} > "$REPORT_FILE"

printf "  Report written to:\n  %s\n\n" "$REPORT_FILE"

# Latest-pointer convenience file
printf '%s\n' "$REPORT_FILE" > "$OUTPUT_ROOT/latest-reimage-checklist.txt" 2>/dev/null || true

if [[ "$OPEN_RESULT" == "true" ]]; then
  open "$OUTPUT_ROOT" 2>/dev/null || true
fi

# Exit non-zero if any failures
[[ $FAIL -eq 0 ]]
