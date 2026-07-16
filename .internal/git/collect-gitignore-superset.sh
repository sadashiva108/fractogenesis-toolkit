#!/usr/bin/env bash
# =============================================================================
# collect-gitignore-superset.sh
#
# Crawl local workspace/repo directories and compile a reviewable superset of
# .gitignore patterns. This does NOT back up files yet. It creates reports so
# you can decide which ignored patterns/files you want staged for backup later
# via stage-selected-patterns.py. Normally invoked by bin/backup-repos.sh
# (default mode), but can be run standalone.
#
# Why this exists:
#   git ls-files --others --ignored --exclude-standard only reports ignored files for a
#   specific Git repo. If you have IntelliJ workspace folders under IdeaProjects that
#   contain multiple module repos, a workspace-level .gitignore may exist above those repos.
#   This script searches the directory tree itself for every .gitignore, including those
#   workspace-level files.
#
# Default roots:
#   GIT_WORK_REPO_ROOT and GIT_PERSONAL_REPO_ROOT from reimage.env.
#   Pass --root more than once to override them for a specific run.
#
# Default output:
#   $REIMAGE_ARTIFACT_ROOT/gitignore-superset, or
#   ~/Desktop/gitignore-superset-YYYYMMDD-HHMMSS if REIMAGE_ARTIFACT_ROOT is unset
#
# Usage:
#   cd <repo-root>
#   chmod +x .internal/git/collect-gitignore-superset.sh
#
#   ./.internal/git/collect-gitignore-superset.sh
#
#   ./.internal/git/collect-gitignore-superset.sh \
#     --root ~/Development/IdeaProjects \
#     --dest /Volumes/Data/reimage-backup-YYYYMMDD/gitignore-superset
#
#   ./.internal/git/collect-gitignore-superset.sh --include-git-excludes --include-global-excludes
#
# Options:
#   --root <dir>                  Add a root directory to crawl.
#                                 Can be passed multiple times.
#                                 If omitted, uses configured Git roots from reimage.env.
#   --dest <dir>                   Destination directory for reports.
#                                 Default: $REIMAGE_ARTIFACT_ROOT/gitignore-superset
#   --include-git-excludes         Also collect per-repo .git/info/exclude files.
#   --include-global-excludes      Also collect your global Git excludes file from:
#                                   git config --global core.excludesfile
#                                 and the common default:
#                                   ~/.config/git/ignore
#   -h, --help                     Show this help.
#
# Output files:
#   gitignore-files.tsv
#       Machine-readable inventory of every discovered ignore source.
#   gitignore-files-review.txt
#       Human-readable view of the ignore-source inventory.
#   gitignore-patterns-all.tsv
#       Machine-readable provenance for every non-comment pattern occurrence.
#   gitignore-patterns-all-review.txt
#       Human-readable patterns grouped by source file.
#   gitignore-patterns-superset.txt
#       Unique normalized pattern list for review.
#   gitignore-patterns-superset-with-counts.tsv
#       Unique normalized pattern list with occurrence counts.
#   gitignore-pattern-sources.tsv
#       Machine-readable unique-pattern-to-source summary.
#   gitignore-pattern-sources-review.txt
#       Human-readable pattern provenance grouped by pattern.
#   gitignore-concatenated-with-sources.txt
#       Exact source contents with structured provenance headings.
#   gitignore-review-template.txt
#       A copy-friendly template where you can mark patterns to stage for backup later.
#
# Notes:
#   - This script does not copy ignored files.
#   - This script intentionally finds .gitignore files outside repo roots too, including
#     workspace-level .gitignore files under IdeaProjects.
#   - By default, it skips huge/generated directories while crawling for .gitignore files.
# =============================================================================

set -euo pipefail

# ── Load shared reimage config ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# This script lives at <repo>/.internal/git/collect-gitignore-superset.sh, so
# the shared config loader is one level up, alongside the other .internal/ helpers.
CONFIG_LOADER="$(dirname "$SCRIPT_DIR")/load-reimage-config.sh"
if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi
# shellcheck source=../load-reimage-config.sh
source "$CONFIG_LOADER"
# ─────────────────────────────────────────────────────────────────────────────

_default_dest="${REIMAGE_ARTIFACT_ROOT:+${REIMAGE_ARTIFACT_ROOT}/gitignore-superset}"
DEST="${_default_dest:-$HOME/Desktop/gitignore-superset-$(date +%Y%m%d-%H%M%S)}"
unset _default_dest
INCLUDE_GIT_EXCLUDES="false"
INCLUDE_GLOBAL_EXCLUDES="false"

ROOTS=()

usage() {
  sed -n 's/^# \{0,2\}//p' "$0" | head -73
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOTS+=("${2:?Missing value for --root}")
      shift 2
      ;;
    --dest)
      DEST="${2:?Missing value for --dest}"
      shift 2
      ;;
    --include-git-excludes)
      INCLUDE_GIT_EXCLUDES="true"
      shift
      ;;
    --include-global-excludes)
      INCLUDE_GLOBAL_EXCLUDES="true"
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
  if [[ -n "${GIT_WORK_REPO_ROOT:-}" ]]; then
    ROOTS+=("$GIT_WORK_REPO_ROOT")
  fi
  if [[ -n "${GIT_PERSONAL_REPO_ROOT:-}" ]]; then
    ROOTS+=("$GIT_PERSONAL_REPO_ROOT")
  fi
fi

if [[ ${#ROOTS[@]} -eq 0 ]]; then
  echo "ERROR: no Git roots are configured." >&2
  echo "Set GIT_WORK_REPO_ROOT and/or GIT_PERSONAL_REPO_ROOT in reimage.env," >&2
  echo "or pass one or more --root <dir> arguments." >&2
  exit 2
fi

for root in "${ROOTS[@]}"; do
  if [[ ! -d "$root" ]]; then
    echo "ERROR: root directory does not exist: $root" >&2
    exit 2
  fi
done

mkdir -p "$DEST"

IGNORE_FILES_TSV="$DEST/gitignore-files.tsv"
IGNORE_FILES_REVIEW="$DEST/gitignore-files-review.txt"
PATTERNS_ALL_TSV="$DEST/gitignore-patterns-all.tsv"
PATTERNS_ALL_REVIEW="$DEST/gitignore-patterns-all-review.txt"
PATTERNS_SUPERSET_TXT="$DEST/gitignore-patterns-superset.txt"
PATTERNS_SUPERSET_COUNTS_TSV="$DEST/gitignore-patterns-superset-with-counts.tsv"
PATTERN_SOURCES_TSV="$DEST/gitignore-pattern-sources.tsv"
PATTERN_SOURCES_REVIEW="$DEST/gitignore-pattern-sources-review.txt"
CONCAT_TXT="$DEST/gitignore-concatenated-with-sources.txt"
REVIEW_TEMPLATE="$DEST/gitignore-review-template.txt"
SUMMARY_TXT="$DEST/summary.txt"

tmp_sources="$(mktemp)"
trap 'rm -f "$tmp_sources"' EXIT
GENERATED_AT="$(date '+%Y-%m-%d %H:%M:%S %Z')"

# Git root helper. Returns blank if path is not inside a Git repo.
nearest_git_root() {
  local dir="$1"
  git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true
}

# Top-level IdeaProjects workspace helper.
# For /Users/me/Development/IdeaProjects/workspace/module/.gitignore,
# returns /Users/me/Development/IdeaProjects/workspace.
workspace_root_for_path() {
  local path="$1"
  local marker="/Development/IdeaProjects/"
  local prefix suffix first

  case "$path" in
    *"$marker"*)
      prefix="${path%%$marker*}$marker"
      suffix="${path#*$marker}"
      first="${suffix%%/*}"
      if [[ -n "$first" && "$first" != "$suffix" ]]; then
        printf '%s%s' "$prefix" "$first"
      else
        printf '%s' "$path"
      fi
      ;;
    *)
      printf ''
      ;;
  esac
}

source_kind_for_path() {
  local path="$1"
  case "$path" in
    */.gitignore) printf 'gitignore' ;;
    */.git/info/exclude) printf 'git_info_exclude' ;;
    */.config/git/ignore) printf 'global_git_ignore' ;;
    *) printf 'ignore_file' ;;
  esac
}

add_source_file() {
  local source_path="$1"
  local kind git_root workspace_root rel_to_git_root rel_to_workspace

  [[ -f "$source_path" ]] || return 0

  kind="$(source_kind_for_path "$source_path")"

  git_root=""
  if [[ "$source_path" == */.git/info/exclude ]]; then
    git_root="${source_path%/.git/info/exclude}"
  else
    git_root="$(nearest_git_root "$(dirname "$source_path")")"
  fi

  workspace_root="$(workspace_root_for_path "$source_path")"

  rel_to_git_root=""
  if [[ -n "$git_root" && "$source_path" == "$git_root/"* ]]; then
    rel_to_git_root="${source_path#"$git_root/"}"
  fi

  rel_to_workspace=""
  if [[ -n "$workspace_root" && "$source_path" == "$workspace_root/"* ]]; then
    rel_to_workspace="${source_path#"$workspace_root/"}"
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$kind" "$source_path" "$git_root" "$rel_to_git_root" "$workspace_root" "$rel_to_workspace" >> "$tmp_sources"
}

echo "Scanning roots:"
for root in "${ROOTS[@]}"; do
  echo "  $root"
done
echo
echo "Destination:"
echo "  $DEST"
echo

# Find every .gitignore under each root.
# Prune common huge/generated folders to keep the crawl fast.
for root in "${ROOTS[@]}"; do
  [[ -d "$root" ]] || continue

  while IFS= read -r -d '' file; do
    add_source_file "$file"
  done < <(
    find "$root" \
      \( -type d \( \
          -name .git \
          -o -name node_modules \
          -o -name .gradle \
          -o -name target \
          -o -name build \
          -o -name dist \
          -o -name out \
          -o -name .venv \
          -o -name venv \
          -o -name __pycache__ \
          -o -name .pytest_cache \
          -o -name .mypy_cache \
          -o -name .ruff_cache \
        \) -prune \) \
      -o \( -type f -name .gitignore -print0 \) 2>/dev/null
  )
done

# Optionally collect .git/info/exclude for repos under the roots.
if [[ "$INCLUDE_GIT_EXCLUDES" == "true" ]]; then
  for root in "${ROOTS[@]}"; do
    [[ -d "$root" ]] || continue

    while IFS= read -r -d '' file; do
      add_source_file "$file"
    done < <(
      find "$root" -type f -path '*/.git/info/exclude' -print0 2>/dev/null
    )
  done
fi

# Optionally collect global Git exclude files.
if [[ "$INCLUDE_GLOBAL_EXCLUDES" == "true" ]]; then
  global_excludes="$(git config --global --get core.excludesfile 2>/dev/null || true)"

  if [[ -n "$global_excludes" ]]; then
    # Expand a leading ~ manually.
    case "$global_excludes" in
      "~/"*) global_excludes="$HOME/${global_excludes#~/}" ;;
    esac
    add_source_file "$global_excludes"
  fi

  add_source_file "$HOME/.config/git/ignore"
fi

# De-duplicate source file records and sort them deterministically by kind/path.
{
  printf "kind\tsource_path\tnearest_git_root\trelative_to_git_root\tidea_workspace_root\trelative_to_workspace\n"
  LC_ALL=C sort -u -t $'\t' -k1,1 -k2,2 "$tmp_sources"
} > "$IGNORE_FILES_TSV"

source_count="$(tail -n +2 "$IGNORE_FILES_TSV" | wc -l | tr -d ' ')"

# Human-readable source inventory. The TSV remains the machine-readable source of truth.
{
  echo "Gitignore Source Inventory"
  echo "=========================="
  echo
  echo "Generated: $GENERATED_AT"
  echo "Sources:   $source_count"
  echo

  source_index=0
  tail -n +2 "$IGNORE_FILES_TSV" | while IFS=$'\t' read -r kind source_path git_root rel_git workspace_root rel_workspace; do
    source_index=$((source_index + 1))
    printf '[%d] %s\n' "$source_index" "$kind"
    printf '    Source:              %s\n' "$source_path"
    printf '    Nearest Git root:    %s\n' "${git_root:-<none>}"
    printf '    Repo-relative path:  %s\n' "${rel_git:-<none>}"
    printf '    Workspace root:      %s\n' "${workspace_root:-<none>}"
    printf '    Workspace-relative:  %s\n' "${rel_workspace:-<none>}"
    echo
  done
} > "$IGNORE_FILES_REVIEW"

# Exact source contents with structured provenance headings for manual review.
{
  echo "Gitignore Sources — Concatenated Review"
  echo "========================================"
  echo
  echo "Generated: $GENERATED_AT"
  echo "Sources included: $source_count"
  echo "Roots scanned:"
  for root in "${ROOTS[@]}"; do
    echo "  - $root"
  done
  echo
} > "$CONCAT_TXT"

source_index=0
while IFS=$'\t' read -r kind source_path git_root rel_git workspace_root rel_workspace; do
  source_index=$((source_index + 1))
  {
    printf 'Source %d of %d\n' "$source_index" "$source_count"
    echo "=============================="
    printf 'Kind:                  %s\n' "$kind"
    printf 'Source path:           %s\n' "$source_path"
    printf 'Nearest Git root:      %s\n' "${git_root:-<none>}"
    printf 'Repo-relative path:    %s\n' "${rel_git:-<none>}"
    printf 'Workspace root:        %s\n' "${workspace_root:-<none>}"
    printf 'Workspace-relative:    %s\n' "${rel_workspace:-<none>}"
    echo
    echo "--- BEGIN IGNORE CONTENT ---"
    echo
    cat "$source_path"
    echo
    echo "--- END IGNORE CONTENT ---"
    echo
  } >> "$CONCAT_TXT"
done < <(tail -n +2 "$IGNORE_FILES_TSV")

# Extract patterns from all ignore files.
# Keep negations (!) as distinct patterns.
# Strip CRs, surrounding whitespace, blank lines, and full-line comments.
# Preserve inline # because in .gitignore it can be literal unless escaped/positioned with whitespace.
tmp_pattern_rows="$(mktemp)"
trap 'rm -f "$tmp_sources" "$tmp_pattern_rows"' EXIT

tail -n +2 "$IGNORE_FILES_TSV" | while IFS=$'\t' read -r kind source_path git_root rel_git workspace_root rel_workspace; do
  awk -v kind="$kind" \
      -v source_path="$source_path" \
      -v git_root="$git_root" \
      -v rel_git="$rel_git" \
      -v workspace_root="$workspace_root" \
      -v rel_workspace="$rel_workspace" '
    BEGIN { OFS = "\t" }
    {
      raw = $0
      sub(/\r$/, "", raw)

      trimmed = raw
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", trimmed)

      if (trimmed == "") next
      if (trimmed ~ /^#/) next

      print trimmed, raw, NR, kind, source_path, git_root, rel_git, workspace_root, rel_workspace
    }
  ' "$source_path" >> "$tmp_pattern_rows"
done

{
  printf "normalized_pattern\traw_pattern\tline_number\tsource_kind\tsource_path\tnearest_git_root\trelative_to_git_root\tidea_workspace_root\trelative_to_workspace\n"
  LC_ALL=C sort -t $'\t' -k5,5 -k3,3n -k1,1 "$tmp_pattern_rows"
} > "$PATTERNS_ALL_TSV"

# Human-readable pattern provenance grouped by source file.
{
  echo "Gitignore Pattern Occurrences"
  echo "============================="
  echo
  echo "Generated: $GENERATED_AT"
  echo

  current_source=""
  tail -n +2 "$PATTERNS_ALL_TSV" | while IFS=$'\t' read -r normalized raw line_number source_kind source_path git_root rel_git workspace_root rel_workspace; do
    if [[ "$source_path" != "$current_source" ]]; then
      [[ -z "$current_source" ]] || echo
      echo "SOURCE: $source_path"
      echo "KIND:   $source_kind"
      echo "------------------------------------------------------------"
      current_source="$source_path"
    fi
    printf 'Line %-6s %s\n' "$line_number" "$raw"
    if [[ "$normalized" != "$raw" ]]; then
      printf '           normalized: %s\n' "$normalized"
    fi
  done
} > "$PATTERNS_ALL_REVIEW"

# Unique pattern list.
tail -n +2 "$PATTERNS_ALL_TSV" | cut -f1 | sort -u > "$PATTERNS_SUPERSET_TXT"

# Counts.
{
  printf "count\tnormalized_pattern\n"
  tail -n +2 "$PATTERNS_ALL_TSV" | cut -f1 | sort | uniq -c | awk 'BEGIN{OFS="\t"} {count=$1; $1=""; sub(/^ /,""); print count,$0}'
} > "$PATTERNS_SUPERSET_COUNTS_TSV"

# Pattern-to-source mapping, ordered by most widely used patterns first.
{
  printf "normalized_pattern\tsource_count\tsources\n"
  tail -n +2 "$PATTERNS_ALL_TSV" \
    | awk -F'\t' '
        BEGIN { OFS="\t" }
        {
          pattern=$1
          src=$5
          if (!(pattern SUBSEP src in seen)) {
            seen[pattern SUBSEP src]=1
            counts[pattern]++
            if (sources[pattern] == "") sources[pattern]=src
            else sources[pattern]=sources[pattern] "; " src
          }
        }
        END {
          for (pattern in counts) {
            print pattern, counts[pattern], sources[pattern]
          }
        }
      ' \
    | LC_ALL=C sort -t $'\t' -k2,2nr -k1,1
} > "$PATTERN_SOURCES_TSV"

# Human-readable pattern-to-source view.
{
  echo "Gitignore Pattern Sources"
  echo "========================="
  echo
  echo "Generated: $GENERATED_AT"
  echo

  tail -n +2 "$PATTERN_SOURCES_TSV" | while IFS=$'\t' read -r pattern source_total sources; do
    printf 'PATTERN: %s\n' "$pattern"
    printf 'Used by %s ignore source(s):\n' "$source_total"
    printf '%s\n' "$sources" | awk -F'; ' '{ for (i = 1; i <= NF; i++) print "  - " $i }'
    echo
  done
} > "$PATTERN_SOURCES_REVIEW"

# Review template.
{
  echo "# Gitignore Superset Review Template"
  echo
  echo "# Mark patterns you want staged for backup by changing:"
  echo "#   [ ] pattern"
  echo "# to:"
  echo "#   [x] pattern"
  echo
  echo "# Generated: $(date)"
  echo "# Destination: $DEST"
  echo
  while IFS= read -r pattern; do
    printf "[ ] %s\n" "$pattern"
  done < "$PATTERNS_SUPERSET_TXT"
} > "$REVIEW_TEMPLATE"

pattern_count="$(wc -l < "$PATTERNS_SUPERSET_TXT" | tr -d ' ')"
all_pattern_rows="$(tail -n +2 "$PATTERNS_ALL_TSV" | wc -l | tr -d ' ')"

{
  echo "Gitignore Superset Summary"
  echo "==========================="
  echo
  echo "Generated: $GENERATED_AT"
  echo
  echo "Roots scanned:"
  for root in "${ROOTS[@]}"; do
    echo "  - $root"
  done
  echo
  echo "Output directory:"
  echo "  $DEST"
  echo
  echo "Counts:"
  echo "  Ignore source files found:      $source_count"
  echo "  Total non-comment pattern rows: $all_pattern_rows"
  echo "  Unique normalized patterns:     $pattern_count"
  echo
  echo "Files:"
  echo "  $SUMMARY_TXT"
  echo "  $IGNORE_FILES_TSV"
  echo "  $IGNORE_FILES_REVIEW"
  echo "  $PATTERNS_ALL_TSV"
  echo "  $PATTERNS_ALL_REVIEW"
  echo "  $PATTERNS_SUPERSET_TXT"
  echo "  $PATTERNS_SUPERSET_COUNTS_TSV"
  echo "  $PATTERN_SOURCES_TSV"
  echo "  $PATTERN_SOURCES_REVIEW"
  echo "  $CONCAT_TXT"
  echo "  $REVIEW_TEMPLATE"
  echo
  echo "Suggested review order:"
  echo "  1. summary.txt"
  echo "  2. gitignore-files-review.txt"
  echo "  3. gitignore-pattern-sources-review.txt"
  echo "  4. gitignore-concatenated-with-sources.txt when source context is needed"
  echo "  5. gitignore-review-template.txt"
  echo
  echo "Next step:"
  echo "  Mark patterns in gitignore-review-template.txt with [x], then run"
  echo "  stage-selected-patterns.py (via bin/backup-repos.sh --selected-dry-run)."
} > "$SUMMARY_TXT"

cat "$SUMMARY_TXT"
