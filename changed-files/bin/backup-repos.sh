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
#   ./bin/backup-repos.sh --artifact-root /Volumes/Data/reimage-backup-YYYYMMDD
#   ./bin/backup-repos.sh --root ~/Development/IdeaProjects --root ~/Development/personal
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
#   --open                  Open the primary output after the run.
#   -h, --help               Show this message and exit.
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

SCRIPT_NAME="${REIMAGE_SCRIPT_DISPLAY_NAME:-backup-repos.sh}"

usage() {
  sed -n 's/^# \{0,2\}//p' "$0" | head -45
}

OPEN_AFTER=false
INCLUDE_HEAVY=false
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

if [[ ${#ROOTS[@]} -eq 0 && -d "$HOME/Development" ]]; then
  ROOTS=("$HOME/Development")
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

# These subdirectories are part of the standard artifact-root layout created
# by Phase 1 (prepare-artifact-root.sh / prepare-artifact-root.md). They are
# a required prerequisite for this script, not something backup-repos.sh
# creates itself -- see the "Prerequisites" section of backup-repos.md.
REPO_AUDIT_DIR="$REIMAGE_ARTIFACT_ROOT/repo-audit-reports"
GITIGNORE_DIR="$REIMAGE_ARTIFACT_ROOT/gitignore-superset"
SELECTED_DRYRUN_DIR="$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-dryrun"
SELECTED_FILTERED_DRYRUN_DIR="$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-filtered-dryrun"
SELECTED_FINAL_DIR="$REIMAGE_ARTIFACT_ROOT/selected-ignored-files"
MANIFEST_PATH="$REPO_AUDIT_DIR/MANIFEST.md"

for dir in \
  "$REPO_AUDIT_DIR" \
  "$GITIGNORE_DIR" \
  "$SELECTED_DRYRUN_DIR" \
  "$SELECTED_FILTERED_DRYRUN_DIR" \
  "$SELECTED_FINAL_DIR"; do
  if [[ ! -d "$dir" ]]; then
    echo "ERROR: expected artifact directory not found: $dir" >&2
    echo "This directory should already exist as part of the standard artifact-root" >&2
    echo "layout created by Phase 1. Run prepare-artifact-root.sh first, or confirm" >&2
    echo "REIMAGE_ARTIFACT_ROOT points at the right location." >&2
    exit 2
  fi
done

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

run_default_refresh() {
  chmod +x "$AUDIT_HELPER" "$SUPERSET_HELPER"
  "$AUDIT_HELPER" "${HELPER_ROOT_ARGS[@]}" --dest "$REPO_AUDIT_DIR"
  "$SUPERSET_HELPER" "${HELPER_ROOT_ARGS[@]}" --dest "$GITIGNORE_DIR" --include-git-excludes --include-global-excludes
  LATEST_AUDIT_REPORT="$(ls -1t "$REPO_AUDIT_DIR"/git-audit-summary-*.txt 2>/dev/null | head -1 || true)"
  OPEN_TARGET="${LATEST_AUDIT_REPORT:-$GITIGNORE_DIR}"
  MODE_SUMMARY="Refreshed repo audit and gitignore superset outputs"
}

run_direct_ignored() {
  local dest="$1"
  shift
  chmod +x "$DIRECT_IGNORED_HELPER"
  "$DIRECT_IGNORED_HELPER" "${HELPER_ROOT_ARGS[@]}" --dest "$dest" "$@"
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

{
  echo "# Repo Backup Manifest"
  echo
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Artifact root: $REIMAGE_ARTIFACT_ROOT"
  echo "Mode: $MODE"
  echo
  echo "## Git roots"
  for root in "${ROOTS[@]}"; do
    echo "- $root"
  done
  echo
  echo "## Latest action"
  echo
  echo "- $MODE_SUMMARY"
  echo
  echo "## Primary outputs"
  echo
  echo '```text'
  echo '$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/'
  echo '$REIMAGE_ARTIFACT_ROOT/gitignore-superset/'
  echo '$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-dryrun/'
  echo '$REIMAGE_ARTIFACT_ROOT/selected-ignored-files-filtered-dryrun/'
  echo '$REIMAGE_ARTIFACT_ROOT/selected-ignored-files/'
  echo '```'
  echo
  echo "## Next step"
  echo
  case "$MODE" in
    default)
      echo "- Review the newest \`git-audit-summary-*.txt\` report."
      echo "- Push backup branches or convert stashes where needed."
      echo "- Mark selections in \`$TEMPLATE_PATH\`."
      echo "- Create or update \`$EXCLUDE_LIST_PATH\`."
      echo "- Run \`./bin/backup-repos.sh --artifact-root \"\$REIMAGE_ARTIFACT_ROOT\" --selected-dry-run\`."
      ;;
    direct-ignored-dry-run)
      echo "- Review \`$SELECTED_DRYRUN_DIR\` before using \`--direct-ignored-copy\`."
      ;;
    direct-ignored-copy)
      echo "- Review copied ignored files and move any secret-bearing material into the encrypted secrets flow."
      ;;
    selected-dry-run)
      echo "- Review \`$SELECTED_DRYRUN_DIR\`, then run \`--selected-filtered-dry-run\` after updating the exclude list."
      ;;
    selected-filtered-dry-run)
      echo "- Review \`$SELECTED_FILTERED_DRYRUN_DIR\`, then run \`--selected-copy\` when it looks correct."
      ;;
    selected-copy)
      echo "- Review \`$SELECTED_FINAL_DIR\` and move secret-bearing files into the encrypted secrets flow when needed."
      ;;
  esac
  echo
  echo "---"
  echo
  echo "*Report generated by \`$SCRIPT_NAME\`*"
} > "$MANIFEST_PATH"

echo "Repo backup: $MODE_SUMMARY"
echo "Manifest: $MANIFEST_PATH"
if [[ -n "$LATEST_AUDIT_REPORT" ]]; then
  echo "Latest audit report: $LATEST_AUDIT_REPORT"
fi
if [[ "$OPEN_AFTER" == true && -n "$OPEN_TARGET" ]]; then
  open "$OPEN_TARGET" 2>/dev/null || true
fi
