#!/usr/bin/env bash
# =============================================================================
# backup-repose.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SNIPPET="$SCRIPT_DIR/load-reimage-config-snippet.sh"
if [[ ! -f "$CONFIG_SNIPPET" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_SNIPPET" >&2
  exit 2
fi
# shellcheck source=load-reimage-config-snippet.sh
source "$CONFIG_SNIPPET"

usage() {
  cat <<'USAGE'
Usage:
  backup-repos.sh[--backup-root BACKUP_ROOT] [--root DIR ...] [mode] [--include-heavy] [--open]

Default mode:
  Refresh the repo audit and gitignore superset outputs for Phase 2A.

Modes:
  --direct-ignored-dry-run         Run the broad ignored-file dry run.
  --direct-ignored-copy            Run the broad ignored-file copy.
  --selected-dry-run               Run the reviewed selected-pattern dry run.
  --selected-filtered-dry-run      Run the reviewed selected-pattern dry run with exclude list.
  --selected-copy                  Run the reviewed selected-pattern final copy.

Options:
  --root DIR                       Override Git roots from reimage.env. Repeatable.
  --include-heavy                  Only valid with direct ignored-file modes.
  --open                           Open the primary output after the run.
USAGE
}

OPEN_AFTER=false
INCLUDE_HEAVY=false
MODE="default"
MODE_SET_COUNT=0
ROOTS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backup-root) BACKUP_ROOT="${2:-}"; shift 2 ;;
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

if [[ -z "${BACKUP_ROOT:-}" ]]; then
  echo "ERROR: BACKUP_ROOT is not set. Source reimage.env or pass --backup-root PATH." >&2
  exit 1
fi

if [[ ! -d "$BACKUP_ROOT" ]]; then
  echo "ERROR: backup root not found: $BACKUP_ROOT" >&2
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

GIT_AUDIT_DIR="$BACKUP_ROOT/git-audit-reports"
GITIGNORE_DIR="$BACKUP_ROOT/gitignore-superset"
SELECTED_DRYRUN_DIR="$BACKUP_ROOT/selected-ignored-files-dryrun"
SELECTED_FILTERED_DRYRUN_DIR="$BACKUP_ROOT/selected-ignored-files-filtered-dryrun"
SELECTED_FINAL_DIR="$BACKUP_ROOT/selected-ignored-files"
MANIFEST_PATH="$GIT_AUDIT_DIR/MANIFEST.md"

mkdir -p \
  "$GIT_AUDIT_DIR" \
  "$GITIGNORE_DIR" \
  "$SELECTED_DRYRUN_DIR" \
  "$SELECTED_FILTERED_DRYRUN_DIR" \
  "$SELECTED_FINAL_DIR"

AUDIT_HELPER="$SCRIPT_DIR/helpers/git/capture-git-audit.sh"
DIRECT_IGNORED_HELPER="$SCRIPT_DIR/helpers/git/backup-git-ignored-files.sh"
SUPERSET_HELPER="$SCRIPT_DIR/helpers/git/collect-gitignore-superset.sh"
SELECTED_HELPER="$SCRIPT_DIR/helpers/git/backup-selected-gitignore-patterns.py"

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
  "$AUDIT_HELPER" "${HELPER_ROOT_ARGS[@]}" --dest "$GIT_AUDIT_DIR"
  "$SUPERSET_HELPER" "${HELPER_ROOT_ARGS[@]}" --dest "$GITIGNORE_DIR" --include-git-excludes --include-global-excludes
  LATEST_AUDIT_REPORT="$(ls -1t "$GIT_AUDIT_DIR"/git-audit-summary-*.txt 2>/dev/null | head -1 || true)"
  OPEN_TARGET="${LATEST_AUDIT_REPORT:-$GITIGNORE_DIR}"
  MODE_SUMMARY="Refreshed Git audit and gitignore superset outputs"
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
    echo "Run backup-repos.shwith no mode first to refresh the gitignore superset." >&2
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
  echo "# Git Repository Backup Manifest"
  echo
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Backup root: $BACKUP_ROOT"
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
  echo '$BACKUP_ROOT/git-audit-reports/'
  echo '$BACKUP_ROOT/gitignore-superset/'
  echo '$BACKUP_ROOT/selected-ignored-files-dryrun/'
  echo '$BACKUP_ROOT/selected-ignored-files-filtered-dryrun/'
  echo '$BACKUP_ROOT/selected-ignored-files/'
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
      echo "- Run \`./scripts/backup-repos.sh--backup-root \"\$BACKUP_ROOT\" --selected-dry-run\`."
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
} > "$MANIFEST_PATH"

echo "Git repository backup: $MODE_SUMMARY"
echo "Manifest: $MANIFEST_PATH"
if [[ -n "$LATEST_AUDIT_REPORT" ]]; then
  echo "Latest audit report: $LATEST_AUDIT_REPORT"
fi
if [[ "$OPEN_AFTER" == true && -n "$OPEN_TARGET" ]]; then
  open "$OPEN_TARGET" 2>/dev/null || true
fi
