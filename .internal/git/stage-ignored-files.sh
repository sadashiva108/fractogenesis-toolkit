#!/usr/bin/env bash
# =============================================================================
# stage-ignored-files.sh
#
# Crawl local Git repos and stage all Git-ignored files for backup review,
# preserving repo-relative paths. This is the broad/direct staging path;
# normally invoked by bin/backup-repos.sh --direct-ignored-dry-run /
# --direct-ignored-copy. The reviewed selected-pattern flow
# (stage-selected-patterns.py) is preferred -- use this only when you
# intentionally want everything Git reports as ignored, without review.
#
# Default behavior:
#   - Dry run only.
#   - Searches roots from GIT_WORK_REPO_ROOT and GIT_PERSONAL_REPO_ROOT in reimage.env.
#   - Falls back to ~/Development when no Git roots are configured.
#   - Writes to $REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live when --copy is used.
#   - Skips common generated/heavy folders like node_modules, target, build, .gradle, .venv.
#   - Skips files that disappear between Git's scan and the copy step.
#
# Usage:
#   cd <repo-root>
#   chmod +x .internal/git/stage-ignored-files.sh
#
#   ./.internal/git/stage-ignored-files.sh
#   ./.internal/git/stage-ignored-files.sh --copy
#   ./.internal/git/stage-ignored-files.sh --root ~/Development/IdeaProjects --copy
#   ./.internal/git/stage-ignored-files.sh --root ~/Development/IdeaProjects --root ~/Development/personal --copy
#   ./.internal/git/stage-ignored-files.sh --dest "$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live" --copy
#   ./.internal/git/stage-ignored-files.sh --include-heavy --copy
#
# Options:
#   --root <dir>       Root directory to crawl for Git repos.
#                      Can be passed multiple times.
#                      Default: GIT_WORK_REPO_ROOT and GIT_PERSONAL_REPO_ROOT
#                      from reimage.env when set; otherwise ~/Development.
#   --dest <dir>       Destination staging directory.
#                      Default: $REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live.
#   --copy             Actually copy files.
#                      Without this, the script performs a dry run.
#   --include-heavy    Include commonly ignored/generated folders such as:
#                      node_modules, .gradle, target, build, dist, out, .venv, venv.
#   -h, --help         Show this help.
#
# What it stages:
#   Ignored files reported by:
#     git ls-files --others --ignored --exclude-standard
#
# What it preserves:
#   Destination layout:
#     <dest>/<repo-name>/<relative/path/to/ignored-file>
#
# Safety notes:
#   - Review the dry run first.
#   - Ignored files may contain secrets such as .env.local, certs, keys, and tokens.
#   - Store the staged output somewhere secure before reimaging.
# =============================================================================

set -euo pipefail

# ── Load shared reimage config ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# This script lives at <repo>/.internal/git/stage-ignored-files.sh, so the
# shared config loader is one level up, alongside the other .internal/ helpers.
CONFIG_LOADER="$(dirname "$SCRIPT_DIR")/load-reimage-config.sh"
if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi
# shellcheck source=../load-reimage-config.sh
source "$CONFIG_LOADER"
# ─────────────────────────────────────────────────────────────────────────────

ROOTS=()
_default_dest="${REIMAGE_ARTIFACT_ROOT:+${REIMAGE_ARTIFACT_ROOT}/staged-ignored-files/live}"
DEST="${_default_dest:-$HOME/Desktop/git-ignored-backup-$(date +%Y%m%d-%H%M%S)}"
unset _default_dest
DO_COPY="false"
INCLUDE_HEAVY="false"

usage() {
  sed -n 's/^# \{0,2\}//p' "$0" | head -56
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    "")
      # Ignore accidental empty arguments, commonly caused by copying
      # "${ROOT_ARGS[@]}" before ROOT_ARGS was built as an array.
      shift
      ;;
    --root)
      if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "ERROR: --root requires a non-empty directory path." >&2
        usage >&2
        exit 2
      fi
      ROOTS+=("$2")
      shift 2
      ;;
    --dest)
      if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "ERROR: --dest requires a non-empty directory path." >&2
        usage >&2
        exit 2
      fi
      DEST="$2"
      shift 2
      ;;
    --copy)
      DO_COPY="true"
      shift
      ;;
    --include-heavy)
      INCLUDE_HEAVY="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

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

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git is not installed or is not on PATH." >&2
  exit 1
fi

for root in "${ROOTS[@]}"; do
  if [[ ! -d "$root" ]]; then
    echo "ERROR: root directory does not exist: $root" >&2
    exit 1
  fi
done

should_skip_heavy_path() {
  local rel="$1"

  [[ "$INCLUDE_HEAVY" == "true" ]] && return 1

  case "$rel" in
    node_modules/*|*/node_modules/*) return 0 ;;
    .gradle/*|*/.gradle/*) return 0 ;;
    target/*|*/target/*) return 0 ;;
    build/*|*/build/*) return 0 ;;
    dist/*|*/dist/*) return 0 ;;
    out/*|*/out/*) return 0 ;;
    .venv/*|*/.venv/*) return 0 ;;
    venv/*|*/venv/*) return 0 ;;
    __pycache__/*|*/__pycache__/*) return 0 ;;
    .pytest_cache/*|*/.pytest_cache/*) return 0 ;;
    .mypy_cache/*|*/.mypy_cache/*) return 0 ;;
    .ruff_cache/*|*/.ruff_cache/*) return 0 ;;
    .idea/workspace.xml|*/.idea/workspace.xml) return 0 ;;
    .DS_Store|*/.DS_Store) return 0 ;;
  esac

  return 1
}

safe_repo_dest() {
  local repo="$1"
  local base
  base="$(basename "$repo")"
  printf '%s' "$DEST/$base"
}

echo "Roots:"
for root in "${ROOTS[@]}"; do
  echo "  - $root"
done
echo "Destination: $DEST"
echo "Mode:        $([[ "$DO_COPY" == "true" ]] && echo "COPY" || echo "DRY RUN")"
echo "Heavy dirs:  $([[ "$INCLUDE_HEAVY" == "true" ]] && echo "included" || echo "skipped")"
echo

if [[ "$DO_COPY" == "true" ]]; then
  mkdir -p "$DEST"
fi

MANIFEST="$DEST/manifest.tsv"
SKIPPED_LOG="$DEST/skipped-missing-or-failed.tsv"

if [[ "$DO_COPY" == "true" ]]; then
  printf "repo_root\trepo_name\trelative_path\tbackup_path\n" > "$MANIFEST"
  printf "reason\trepo_root\trelative_path\tsource_path\n" > "$SKIPPED_LOG"
fi

mapfile -t REPOS < <(
  for root in "${ROOTS[@]}"; do
    find "$root" -type d -name .git -prune 2>/dev/null \
      | sed 's#/.git$##'
  done | sort -u
)

if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "No Git repositories found under configured roots."
  exit 0
fi

total_repos=0
repos_with_ignored=0
total_files=0
total_skipped_heavy=0
total_skipped_missing=0
total_copy_failed=0

for repo in "${REPOS[@]}"; do
  top="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -n "$top" ]] || continue

  total_repos=$((total_repos + 1))
  repo_name="$(basename "$top")"
  repo_dest="$(safe_repo_dest "$top")"

  repo_files=0
  repo_skipped_heavy=0
  repo_skipped_missing=0
  repo_copy_failed=0

  while IFS= read -r -d '' rel; do
    src="$top/$rel"

    if should_skip_heavy_path "$rel"; then
      repo_skipped_heavy=$((repo_skipped_heavy + 1))
      total_skipped_heavy=$((total_skipped_heavy + 1))
      continue
    fi

    # Generated files can disappear between the git scan and cp.
    # Skip them instead of aborting the whole staging run.
    if [[ ! -e "$src" && ! -L "$src" ]]; then
      repo_skipped_missing=$((repo_skipped_missing + 1))
      total_skipped_missing=$((total_skipped_missing + 1))
      if [[ "$DO_COPY" == "true" ]]; then
        printf "missing\t%s\t%s\t%s\n" "$top" "$rel" "$src" >> "$SKIPPED_LOG"
      else
        printf "[DRY RUN SKIP MISSING] %s\n" "$src"
      fi
      continue
    fi

    # Only copy regular files and symlinks. Empty ignored directories are skipped.
    if [[ ! -f "$src" && ! -L "$src" ]]; then
      continue
    fi

    repo_files=$((repo_files + 1))
    total_files=$((total_files + 1))

    backup_path="$repo_dest/$rel"

    if [[ "$DO_COPY" == "true" ]]; then
      mkdir -p "$(dirname "$backup_path")"
      if cp -p "$src" "$backup_path"; then
        printf "%s\t%s\t%s\t%s\n" "$top" "$repo_name" "$rel" "$backup_path" >> "$MANIFEST"
      else
        repo_copy_failed=$((repo_copy_failed + 1))
        total_copy_failed=$((total_copy_failed + 1))
        printf "copy_failed\t%s\t%s\t%s\n" "$top" "$rel" "$src" >> "$SKIPPED_LOG"
        echo "WARN: failed to copy, continuing: $src" >&2
      fi
    else
      printf "[DRY RUN] %s -> %s\n" "$src" "$backup_path"
    fi
  done < <(git -C "$top" ls-files --others --ignored --exclude-standard -z)

  if [[ "$repo_files" -gt 0 || "$repo_skipped_heavy" -gt 0 || "$repo_skipped_missing" -gt 0 || "$repo_copy_failed" -gt 0 ]]; then
    repos_with_ignored=$((repos_with_ignored + 1))
    echo
    echo "Repo: $top"
    echo "  ignored files selected:      $repo_files"
    echo "  heavy/generated skipped:     $repo_skipped_heavy"
    echo "  disappeared/missing skipped: $repo_skipped_missing"
    echo "  copy failures skipped:       $repo_copy_failed"
  fi
done

echo
echo "Summary"
echo "-------"
echo "Repos scanned:                 $total_repos"
echo "Repos with ignored files:      $repos_with_ignored"
echo "Ignored files selected:        $total_files"
echo "Heavy/generated skipped:       $total_skipped_heavy"
echo "Disappeared/missing skipped:   $total_skipped_missing"
echo "Copy failures skipped:         $total_copy_failed"

if [[ "$DO_COPY" == "true" ]]; then
  echo
  echo "Staging complete:"
  echo "  $DEST"
  echo
  echo "Manifest:"
  echo "  $MANIFEST"
  echo
  echo "Skipped/missing log:"
  echo "  $SKIPPED_LOG"
else
  echo
  echo "Dry run only. To actually copy files, run again with:"
  echo "  $0 --dest \"$DEST\" --copy"
fi
