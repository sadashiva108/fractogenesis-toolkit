#!/usr/bin/env bash
# =============================================================================
# backup-repos.sh
#
# Phase 2A repo backup entrypoint: refreshes the repo audit and gitignore
# superset reports, then (once reviewed) stages ignored/gitignored files for
# backup before a reimage.
#
# Usage:
#   cd <repo-root>
#   chmod +x bin/backup-repos.sh
#
#   # Default -- refresh repo audit + gitignore superset outputs
#   ./bin/backup-repos.sh
#
#   # Broad ignored-file dry run / copy (everything Git reports as ignored)
#   ./bin/backup-repos.sh --direct-ignored-dry-run
#   ./bin/backup-repos.sh --direct-ignored-copy
#
#   # Reviewed selected-pattern flow (recommended -- see gitignore-review-template.txt)
#   ./bin/backup-repos.sh --selected-dry-run
#   ./bin/backup-repos.sh --selected-filtered-dry-run
#   ./bin/backup-repos.sh --selected-copy
#
#   # Override artifact root or Git roots
#   ./bin/backup-repos.sh --artifact-root /path/to/reimage-artifact-root
#   ./bin/backup-repos.sh --root /path/to/work-repositories --root /path/to/personal-repositories
#
#   # Open primary output after the run
#   ./bin/backup-repos.sh --open
#
# Modes:
#   (default)                     Refresh the repo audit and gitignore superset outputs.
#   --direct-ignored-dry-run      Run the broad ignored-file dry run.
#   --direct-ignored-copy         Run the broad ignored-file copy.
#   --selected-dry-run            Run the reviewed selected-pattern dry run.
#   --selected-filtered-dry-run   Run the reviewed selected-pattern dry run with exclude list.
#   --selected-copy                Run the reviewed selected-pattern final copy.
#
# Options:
#   --artifact-root PATH   Override REIMAGE_ARTIFACT_ROOT from reimage.env.
#   --root DIR              Override Git roots from reimage.env. Repeatable.
#   --include-heavy         Only valid with direct ignored-file modes.
#   --status-interval SEC   Print a still-running update every SEC seconds. Default: 10.
#   --no-status             Disable periodic still-running updates.
#   --open                  Open the primary output after the run.
#   -h, --help              Show this message and exit.
# =============================================================================

set -euo pipefail

# ── Load shared reimage config ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# This script lives at <repo>/bin/backup-repos.sh, so .internal/ is a
# sibling of bin/, one level up from this script's own directory.
CONFIG_LOADER="$(dirname "$SCRIPT_DIR")/.internal/load-reimage-config.sh"
if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"
# ─────────────────────────────────────────────────────────────────────────────

usage() {
  awk '
    NR == 2 { in_header = 1; next }
    in_header && /^# =+$/ { exit }
    in_header { sub(/^# ?/, ""); print }
  ' "$0"
}

OPEN_AFTER=false
INCLUDE_HEAVY=false
STATUS_ENABLED=true
STATUS_INTERVAL=10
MODE="default"
MODE_SET_COUNT=0
ROOTS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      REIMAGE_ARTIFACT_ROOT="${2:-}"
      shift 2
      ;;
    --root)
      if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "ERROR: --root requires a non-empty directory path." >&2
        exit 2
      fi
      ROOTS+=("$2")
      shift 2
      ;;
    --direct-ignored-dry-run) MODE="direct-ignored-dry-run"; MODE_SET_COUNT=$((MODE_SET_COUNT + 1)); shift ;;
    --direct-ignored-copy) MODE="direct-ignored-copy"; MODE_SET_COUNT=$((MODE_SET_COUNT + 1)); shift ;;
    --selected-dry-run) MODE="selected-dry-run"; MODE_SET_COUNT=$((MODE_SET_COUNT + 1)); shift ;;
    --selected-filtered-dry-run) MODE="selected-filtered-dry-run"; MODE_SET_COUNT=$((MODE_SET_COUNT + 1)); shift ;;
    --selected-copy) MODE="selected-copy"; MODE_SET_COUNT=$((MODE_SET_COUNT + 1)); shift ;;
    --include-heavy) INCLUDE_HEAVY=true; shift ;;
    --status-interval)
      if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "ERROR: --status-interval requires a positive integer." >&2
        exit 2
      fi
      STATUS_INTERVAL="$2"
      shift 2
      ;;
    --no-status) STATUS_ENABLED=false; shift ;;
    --open) OPEN_AFTER=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$MODE_SET_COUNT" -gt 1 ]]; then
  echo "ERROR: choose only one mode flag per run." >&2
  exit 1
fi

case "$STATUS_INTERVAL" in
  ''|*[!0-9]*|0)
    echo "ERROR: --status-interval must be a positive integer." >&2
    exit 2
    ;;
esac

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set. Source reimage.env or pass --artifact-root PATH." >&2
  exit 1
fi

if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: artifact root not found: $REIMAGE_ARTIFACT_ROOT" >&2
  exit 1
fi

if [[ ${#ROOTS[@]} -eq 0 ]]; then
  if [[ -n "${GIT_WORK_REPO_ROOT:-}" && -d "${GIT_WORK_REPO_ROOT:-}" ]]; then
    ROOTS+=("$GIT_WORK_REPO_ROOT")
  fi
  if [[ -n "${GIT_PERSONAL_REPO_ROOT:-}" && -d "${GIT_PERSONAL_REPO_ROOT:-}" ]]; then
    ROOTS+=("$GIT_PERSONAL_REPO_ROOT")
  fi
fi


if [[ ${#ROOTS[@]} -eq 0 ]]; then
  echo "ERROR: No Git repository roots found." >&2
  echo "Set GIT_WORK_REPO_ROOT and/or GIT_PERSONAL_REPO_ROOT in reimage.env, or pass --root <dir>." >&2
  exit 2
fi

for root in "${ROOTS[@]}"; do
  if [[ ! -d "$root" ]]; then
    echo "ERROR: Git root does not exist: $root" >&2
    exit 1
  fi
done

if [[ "$INCLUDE_HEAVY" == true && "$MODE" != "direct-ignored-dry-run" && "$MODE" != "direct-ignored-copy" ]]; then
  echo "ERROR: --include-heavy is only valid with direct ignored-file modes." >&2
  exit 1
fi

# The top-level containers below are assumed to already exist, created by
# prepare-artifact-root.md's standard artifact-root layout -- this script
# does not create them itself, see the "Prerequisites" section of
# backup-repos.md. dryrun/, dryrun-filtered/, and live/ under
# staged-ignored-files/ are different: those are child directories owned by
# this runbook's own helper scripts, not by prepare-artifact-root.md, so
# they're created below instead of checked as a prerequisite.
REPO_AUDIT_DIR="$REIMAGE_ARTIFACT_ROOT/repo-audit-reports"
GITIGNORE_DIR="$REIMAGE_ARTIFACT_ROOT/gitignore-superset"
STAGED_IGNORED_DIR="$REIMAGE_ARTIFACT_ROOT/staged-ignored-files"
SELECTED_DRYRUN_DIR="$STAGED_IGNORED_DIR/dryrun"
SELECTED_FILTERED_DRYRUN_DIR="$STAGED_IGNORED_DIR/dryrun-filtered"
SELECTED_FINAL_DIR="$STAGED_IGNORED_DIR/live"
MANIFEST_PATH="$REPO_AUDIT_DIR/MANIFEST.md"
LATEST_RUN_PATH="$REPO_AUDIT_DIR/latest-run.txt"

for dir in \
  "$REPO_AUDIT_DIR" \
  "$GITIGNORE_DIR" \
  "$STAGED_IGNORED_DIR"; do
  if [[ ! -d "$dir" ]]; then
    echo "ERROR: expected artifact directory not found: $dir" >&2
    echo "This directory should already exist as part of the standard artifact-root" >&2
    echo "layout created by prepare-artifact-root.md. Run that runbook first, or confirm" >&2
    echo "REIMAGE_ARTIFACT_ROOT points at the right location." >&2
    exit 2
  fi
done

mkdir -p "$SELECTED_DRYRUN_DIR" "$SELECTED_FILTERED_DRYRUN_DIR" "$SELECTED_FINAL_DIR"

# This script lives at <repo>/bin/backup-repos.sh; helpers live alongside
# the shared config loader under <repo>/.internal/git/.
HELPERS_DIR="$(dirname "$SCRIPT_DIR")/.internal/git"
AUDIT_HELPER="$HELPERS_DIR/capture-repo-audit.sh"
DIRECT_IGNORED_HELPER="$HELPERS_DIR/stage-ignored-files.sh"
SUPERSET_HELPER="$HELPERS_DIR/collect-gitignore-superset.sh"
SELECTED_HELPER="$HELPERS_DIR/stage-selected-patterns.py"

for helper in "$AUDIT_HELPER" "$DIRECT_IGNORED_HELPER" "$SUPERSET_HELPER" "$SELECTED_HELPER"; do
  if [[ ! -f "$helper" ]]; then
    echo "ERROR: helper not found: $helper" >&2
    exit 2
  fi
done

HELPER_ROOT_ARGS=()
for root in "${ROOTS[@]}"; do
  HELPER_ROOT_ARGS+=(--root "$root")
done

TEMPLATE_PATH="$GITIGNORE_DIR/gitignore-review-template.txt"
EXCLUDE_LIST_PATH="$GITIGNORE_DIR/backup-exclude-list.txt"
LATEST_AUDIT_REPORT=""
OPEN_TARGET=""
MODE_SUMMARY=""
ACTIVE_CHILD_PID=""

stop_active_child() {
  if [[ -n "$ACTIVE_CHILD_PID" ]] && kill -0 "$ACTIVE_CHILD_PID" 2>/dev/null; then
    kill "$ACTIVE_CHILD_PID" 2>/dev/null || true
    wait "$ACTIVE_CHILD_PID" 2>/dev/null || true
  fi
}

trap 'stop_active_child; exit 130' INT TERM

run_with_status() {
  local label="$1"
  shift

  local started now elapsed next_update rc
  printf '\n==> %s\n' "$label"
  printf '    Started: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"

  "$@" &
  ACTIVE_CHILD_PID=$!
  started="$(date +%s)"
  next_update="$STATUS_INTERVAL"

  while kill -0 "$ACTIVE_CHILD_PID" 2>/dev/null; do
    sleep 1
    if [[ "$STATUS_ENABLED" == true ]] && kill -0 "$ACTIVE_CHILD_PID" 2>/dev/null; then
      now="$(date +%s)"
      elapsed=$((now - started))
      if (( elapsed >= next_update )); then
        printf '    [%s] Still running: %s (%ds elapsed)\n' "$(date '+%H:%M:%S')" "$label" "$elapsed"
        next_update=$((next_update + STATUS_INTERVAL))
      fi
    fi
  done

  if wait "$ACTIVE_CHILD_PID"; then
    rc=0
  else
    rc=$?
  fi
  ACTIVE_CHILD_PID=""

  now="$(date +%s)"
  elapsed=$((now - started))
  if [[ "$rc" -eq 0 ]]; then
    printf '    Completed: %s (%ds)\n' "$label" "$elapsed"
  else
    printf '    FAILED: %s (exit %d after %ds)\n' "$label" "$rc" "$elapsed" >&2
  fi
  return "$rc"
}

resolve_latest_audit_report() {
  local latest_run_relative=""
  local latest_report=""

  if [[ ! -f "$LATEST_RUN_PATH" ]]; then
    echo "ERROR: latest repository-audit pointer not found: $LATEST_RUN_PATH" >&2
    return 1
  fi

  IFS= read -r latest_run_relative < "$LATEST_RUN_PATH" || true
  case "$latest_run_relative" in
    runs/pre-image-*|runs/post-image-*) ;;
    *)
      echo "ERROR: invalid latest repository-audit run pointer: ${latest_run_relative:-<empty>}" >&2
      return 1
      ;;
  esac

  case "$latest_run_relative" in
    *..*|/*)
      echo "ERROR: unsafe latest repository-audit run pointer: $latest_run_relative" >&2
      return 1
      ;;
  esac

  latest_report="$REPO_AUDIT_DIR/$latest_run_relative/repo-audit-summary.txt"
  if [[ ! -f "$latest_report" ]]; then
    echo "ERROR: latest repository-audit report not found: $latest_report" >&2
    return 1
  fi

  printf '%s\n' "$latest_report"
}

run_default_refresh() {
  run_with_status "Repository audit" \
    bash "$AUDIT_HELPER" "${HELPER_ROOT_ARGS[@]}" --dest "$REPO_AUDIT_DIR" --context pre-image
  LATEST_AUDIT_REPORT="$(resolve_latest_audit_report)"
  run_with_status "Gitignore superset scan" \
    bash "$SUPERSET_HELPER" "${HELPER_ROOT_ARGS[@]}" --dest "$GITIGNORE_DIR" --include-git-excludes --include-global-excludes
  OPEN_TARGET="$LATEST_AUDIT_REPORT"
  MODE_SUMMARY="Refreshed repo audit and gitignore superset outputs"
}

run_direct_ignored() {
  local dest="$1"
  shift
  run_with_status "Broad ignored-file scan" \
    bash "$DIRECT_IGNORED_HELPER" "${HELPER_ROOT_ARGS[@]}" --dest "$dest" "$@"
  OPEN_TARGET="$dest"
}

run_selected() {
  local dest="$1"
  shift
  if [[ ! -f "$TEMPLATE_PATH" ]]; then
    echo "ERROR: include template not found: $TEMPLATE_PATH" >&2
    echo "Run backup-repos.sh with no mode first to refresh the gitignore superset." >&2
    exit 2
  fi
  run_with_status "Selected-pattern staging scan" \
    python3 "$SELECTED_HELPER" --include-template "$TEMPLATE_PATH" "${HELPER_ROOT_ARGS[@]}" --dest "$dest" "$@"
  OPEN_TARGET="$dest"
}

case "$MODE" in
  default)
    run_default_refresh
    ;;
  direct-ignored-dry-run)
    if [[ "$INCLUDE_HEAVY" == true ]]; then
      run_direct_ignored "$SELECTED_DRYRUN_DIR" --include-heavy
    else
      run_direct_ignored "$SELECTED_DRYRUN_DIR"
    fi
    MODE_SUMMARY="Ran broad ignored-file dry run"
    ;;
  direct-ignored-copy)
    if [[ "$INCLUDE_HEAVY" == true ]]; then
      run_direct_ignored "$SELECTED_FINAL_DIR" --include-heavy --copy
    else
      run_direct_ignored "$SELECTED_FINAL_DIR" --copy
    fi
    MODE_SUMMARY="Ran broad ignored-file copy"
    ;;
  selected-dry-run)
    run_selected "$SELECTED_DRYRUN_DIR"
    MODE_SUMMARY="Ran selected-pattern dry run"
    ;;
  selected-filtered-dry-run)
    if [[ ! -f "$EXCLUDE_LIST_PATH" ]]; then
      echo "ERROR: exclude list not found: $EXCLUDE_LIST_PATH" >&2
      exit 2
    fi
    run_selected "$SELECTED_FILTERED_DRYRUN_DIR" --exclude-list "$EXCLUDE_LIST_PATH"
    MODE_SUMMARY="Ran selected-pattern filtered dry run"
    ;;
  selected-copy)
    if [[ ! -f "$EXCLUDE_LIST_PATH" ]]; then
      echo "ERROR: exclude list not found: $EXCLUDE_LIST_PATH" >&2
      exit 2
    fi
    run_selected "$SELECTED_FINAL_DIR" --exclude-list "$EXCLUDE_LIST_PATH" --copy
    MODE_SUMMARY="Ran selected-pattern final copy"
    ;;
esac

echo "Repo backup: $MODE_SUMMARY"
if [[ "$MODE" == "default" ]]; then
  echo "Audit manifest: $MANIFEST_PATH"
  echo "Latest-run pointer: $LATEST_RUN_PATH"
  echo "Latest audit report: $LATEST_AUDIT_REPORT"
fi
if [[ "$OPEN_AFTER" == true ]]; then
  if [[ -z "$OPEN_TARGET" || ! -e "$OPEN_TARGET" ]]; then
    echo "ERROR: primary output is not available to open: ${OPEN_TARGET:-<empty>}" >&2
    exit 1
  fi
  open "$OPEN_TARGET"
fi
