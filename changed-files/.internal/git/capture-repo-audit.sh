#!/usr/bin/env bash
# =============================================================================
# capture-repo-audit.sh
#
# Create concise repo-state audit reports before reimaging a machine. Normally
# invoked by bin/backup-repos.sh (default mode), but can be run standalone.
#
# The report is intended to answer:
#   - Which repos have uncommitted work?
#   - Which repos have local-only commits?
#   - Which repos have stashes?
#   - Which repos have untracked non-ignored files?
#   - Which repos have ignored files that may need staging for backup?
#
# It avoids giant file listings by rolling many files under the same directory
# into entries like:
#   src/test/resources/* (42 files)
#
# Usage:
#   cd <repo-root>
#   chmod +x .internal/git/capture-repo-audit.sh
#
#   ./.internal/git/capture-repo-audit.sh
#
#   ./.internal/git/capture-repo-audit.sh \
#     --root ~/Development/IdeaProjects \
#     --root ~/Development/Documentation \
#     --dest /Volumes/Data/reimage-backup-YYYYMMDD/repo-audit-reports
#
#   ./.internal/git/capture-repo-audit.sh \
#     --root ~/Development \
#     --dest /Volumes/Data/reimage-backup-YYYYMMDD/repo-audit-reports \
#     --rollup-threshold 3 \
#     --max-lines-per-section 80
#
# Options:
#   --root <dir>                  Root directory to crawl for Git repos.
#                                 Can be passed multiple times.
#                                 Default: GIT_WORK_REPO_ROOT and GIT_PERSONAL_REPO_ROOT
#                                 from reimage.env when set; otherwise ~/Development
#   --dest <dir>                   Destination directory for audit reports.
#                                 Default: $REIMAGE_ARTIFACT_ROOT/repo-audit-reports
#   --rollup-threshold <n>         If a directory contains more than this many files,
#                                 show "directory/* (N files)" instead of listing each file.
#                                 Default: 3
#   --max-lines-per-section <n>    Maximum displayed lines for long sections.
#                                 Full details are still written to TSV files.
#                                 Default: 80
#   --include-ignored              Include a concise ignored-files section. Default.
#   --no-ignored                   Do not list ignored files in the text report.
#   -h, --help                     Show this help.
#
# Output (written to --dest):
#   git-audit-summary-YYYYMMDD-HHMMSS.txt
#       Main concise human-readable report expected by the pre-image checklist.
#   git-pre-reimage-audit-YYYYMMDD-HHMMSS.txt
#       Legacy compatibility copy of the main report.
#   repos-YYYYMMDD-HHMMSS.tsv
#       One row per repo with branch, HEAD, remote info, and status counts.
#   local-only-commits-YYYYMMDD-HHMMSS.tsv
#       Local commits not present on any remote.
#   stashes-YYYYMMDD-HHMMSS.tsv
#       Git stashes.
#   untracked-nonignored-YYYYMMDD-HHMMSS.tsv
#       Full untracked non-ignored file list.
#   ignored-files-YYYYMMDD-HHMMSS.tsv
#       Full ignored file list reported by Git.
#
# Notes:
#   - This script does not copy files.
#   - It creates a human-readable .txt report and several TSV index files.
#   - Use this with the ignored-file staging scripts, not instead of them.
# =============================================================================

set -euo pipefail

# ── Load shared reimage config ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# This script lives at <repo>/.internal/git/capture-repo-audit.sh, so the
# shared config loader is one level up, alongside the other .internal/ helpers.
CONFIG_LOADER="$(dirname "$SCRIPT_DIR")/load-reimage-config.sh"
if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi
# shellcheck source=../load-reimage-config.sh
source "$CONFIG_LOADER"
# ─────────────────────────────────────────────────────────────────────────────

_default_dest="${REIMAGE_ARTIFACT_ROOT:+${REIMAGE_ARTIFACT_ROOT}/repo-audit-reports}"
DEST="${_default_dest:-$HOME/Desktop/repo-audit-reports}"
unset _default_dest
ROLLUP_THRESHOLD=3
MAX_LINES_PER_SECTION=80
INCLUDE_IGNORED="true"

ROOTS=()

usage() {
  sed -n 's/^# \{0,2\}//p' "$0" | head -73
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    "")
      # Ignore an accidental empty argument. This can happen when a copied
      # command includes "${ROOT_ARGS[@]}" but ROOT_ARGS was not built as an
      # array in the current shell.
      shift
      ;;
    --root)
      if [[ $# -lt 2 || "${2:-}" == --* ]]; then
        echo "ERROR: --root requires a directory path." >&2
        usage >&2
        exit 2
      fi
      if [[ -n "${2:-}" ]]; then
        ROOTS+=("$2")
      fi
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
    --rollup-threshold)
      if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "ERROR: --rollup-threshold requires a number." >&2
        usage >&2
        exit 2
      fi
      ROLLUP_THRESHOLD="$2"
      shift 2
      ;;
    --max-lines-per-section)
      if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "ERROR: --max-lines-per-section requires a number." >&2
        usage >&2
        exit 2
      fi
      MAX_LINES_PER_SECTION="$2"
      shift 2
      ;;
    --include-ignored)
      INCLUDE_IGNORED="true"
      shift
      ;;
    --no-ignored)
      INCLUDE_IGNORED="false"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: ${1:-<empty>}" >&2
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
  echo "ERROR: git is not installed or not on PATH." >&2
  exit 1
fi

mkdir -p "$DEST"

STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$DEST/git-audit-summary-$STAMP.txt"
LEGACY_REPORT="$DEST/git-pre-reimage-audit-$STAMP.txt"
REPOS_TSV="$DEST/repos-$STAMP.tsv"
COMMITS_TSV="$DEST/local-only-commits-$STAMP.tsv"
STASHES_TSV="$DEST/stashes-$STAMP.tsv"
UNTRACKED_TSV="$DEST/untracked-nonignored-$STAMP.tsv"
IGNORED_TSV="$DEST/ignored-files-$STAMP.tsv"
TRACKED_TSV="$DEST/tracked-changes-$STAMP.tsv"

printf "repo\tbranch\thead\tremote_urls\tstatus_summary\tlocal_only_commit_count\tstash_count\ttracked_change_count\tuntracked_nonignored_count\tignored_count\n" > "$REPOS_TSV"
printf "repo\tcommit\tmessage\n" > "$COMMITS_TSV"
printf "repo\tstash\tmessage\n" > "$STASHES_TSV"
printf "repo\tpath\n" > "$UNTRACKED_TSV"
printf "repo\tpath\n" > "$IGNORED_TSV"
printf "repo\tstatus\tpath\n" > "$TRACKED_TSV"

# Summarize a list of repo-relative paths from stdin.
# If more than threshold files share the same parent directory, collapse them to:
#   dir/* (N files)
summarize_paths() {
  local threshold="$1"
  local max_lines="$2"

  awk -v threshold="$threshold" -v max_lines="$max_lines" '
    function dirname_of(path, tmp) {
      tmp = path
      if (tmp !~ /\//) return "."
      sub(/\/[^\/]+$/, "", tmp)
      return tmp
    }

    {
      path = $0
      if (path == "") next

      dir = dirname_of(path)
      count[dir]++
      if (files[dir] == "") files[dir] = path
      else files[dir] = files[dir] "\034" path
      dirs[dir] = 1
      total++
    }

    END {
      if (total == 0) {
        print "  <none>"
        exit
      }

      shown = 0
      omitted = 0

      for (dir in dirs) {
        if (count[dir] > threshold) {
          line = (dir == "." ? "*" : dir "/*") " (" count[dir] " files)"
          if (shown < max_lines) {
            print "  " line
            shown++
          } else {
            omitted++
          }
        } else {
          n = split(files[dir], arr, "\034")
          for (i = 1; i <= n; i++) {
            if (shown < max_lines) {
              print "  " arr[i]
              shown++
            } else {
              omitted++
            }
          }
        }
      }

      if (omitted > 0) {
        print "  ... omitted " omitted " additional summarized/listed entries from text report"
      }

      print "  Total files: " total
    }
  ' | sort
}

count_lines() {
  if [[ -z "${1:-}" ]]; then
    echo "0"
  else
    printf "%s\n" "$1" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' '
  fi
}

status_counts() {
  git status --porcelain=v1 2>/dev/null | awk '
    BEGIN {
      modified=0; added=0; deleted=0; renamed=0; untracked=0; other=0
    }
    /^\?\?/ { untracked++; next }
    /^ R|^R |^R/ { renamed++; next }
    /^ D|^D |^D/ { deleted++; next }
    /^ A|^A |^A/ { added++; next }
    /^ M|^M |^M/ { modified++; next }
    { other++ }
    END {
      printf "modified=%d added=%d deleted=%d renamed=%d untracked=%d other=%d", modified, added, deleted, renamed, untracked, other
    }
  '
}

find_repos() {
  for root in "${ROOTS[@]}"; do
    [[ -d "$root" ]] || continue
    find "$root" -type d -name .git -prune 2>/dev/null | sed 's#/.git$##'
  done | sort -u
}

{
  echo "Git Pre-Reimage Audit"
  echo "====================="
  echo
  echo "Generated: $(date)"
  echo
  echo "Roots scanned:"
  for root in "${ROOTS[@]}"; do
    echo "  - $root"
  done
  echo
  echo "Settings:"
  echo "  Rollup threshold:       $ROLLUP_THRESHOLD"
  echo "  Max lines per section:  $MAX_LINES_PER_SECTION"
  echo "  Include ignored files:  $INCLUDE_IGNORED"
  echo
  echo "Reports:"
  echo "  Main report:            $REPORT"
  echo "  Legacy report copy:     $LEGACY_REPORT"
  echo "  Repo index:             $REPOS_TSV"
  echo "  Local-only commits:     $COMMITS_TSV"
  echo "  Stashes:                $STASHES_TSV"
  echo "  Tracked changes:        $TRACKED_TSV"
  echo "  Untracked files:        $UNTRACKED_TSV"
  echo "  Ignored files:          $IGNORED_TSV"
  echo
} > "$REPORT"

repo_count=0
dirty_repo_count=0
local_commit_repo_count=0
stash_repo_count=0
untracked_repo_count=0

while IFS= read -r repo; do
  [[ -d "$repo" ]] || continue

  repo_count=$((repo_count + 1))

  branch="$(git -C "$repo" branch --show-current 2>/dev/null || true)"
  [[ -n "$branch" ]] || branch="<detached-or-unknown>"

  head_line="$(git -C "$repo" log -1 --oneline --decorate 2>/dev/null || true)"
  [[ -n "$head_line" ]] || head_line="<no commits>"

  remotes="$(git -C "$repo" remote -v 2>/dev/null | awk '!seen[$0]++' | paste -sd '; ' - || true)"
  [[ -n "$remotes" ]] || remotes="<none>"

  status_short="$(git -C "$repo" status -sb 2>/dev/null || true)"
  status_summary="$(cd "$repo" && status_counts)"
  status_porcelain="$(git -C "$repo" status --porcelain=v1 2>/dev/null || true)"
  dirty_count="$(count_lines "$status_porcelain")"
  tracked_changes="$(printf "%s\n" "$status_porcelain" | grep -v '^??' || true)"
  tracked_change_count="$(count_lines "$tracked_changes")"

  local_commits="$(git -C "$repo" log --branches --not --remotes --oneline --decorate 2>/dev/null || true)"
  local_commit_count="$(count_lines "$local_commits")"

  stashes="$(git -C "$repo" stash list 2>/dev/null || true)"
  stash_count="$(count_lines "$stashes")"

  untracked="$(git -C "$repo" ls-files --others --exclude-standard 2>/dev/null || true)"
  untracked_count="$(count_lines "$untracked")"

  if [[ "$INCLUDE_IGNORED" == "true" ]]; then
    ignored="$(git -C "$repo" ls-files --others --ignored --exclude-standard 2>/dev/null || true)"
    ignored_count="$(count_lines "$ignored")"
  else
    ignored=""
    ignored_count="0"
  fi

  if [[ "$dirty_count" -gt 0 ]]; then dirty_repo_count=$((dirty_repo_count + 1)); fi
  if [[ "$local_commit_count" -gt 0 ]]; then local_commit_repo_count=$((local_commit_repo_count + 1)); fi
  if [[ "$stash_count" -gt 0 ]]; then stash_repo_count=$((stash_repo_count + 1)); fi
  if [[ "$untracked_count" -gt 0 ]]; then untracked_repo_count=$((untracked_repo_count + 1)); fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$repo" "$branch" "$head_line" "$remotes" "$status_summary" \
    "$local_commit_count" "$stash_count" "$tracked_change_count" "$untracked_count" "$ignored_count" >> "$REPOS_TSV"

  if [[ "$tracked_change_count" -gt 0 ]]; then
    printf "%s\n" "$tracked_changes" | while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      status_code="${line:0:2}"
      path="${line:3}"
      printf "%s\t%s\t%s\n" "$repo" "$status_code" "$path" >> "$TRACKED_TSV"
    done
  fi

  if [[ "$local_commit_count" -gt 0 ]]; then
    printf "%s\n" "$local_commits" | while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      commit="${line%% *}"
      message="${line#* }"
      printf "%s\t%s\t%s\n" "$repo" "$commit" "$message" >> "$COMMITS_TSV"
    done
  fi

  if [[ "$stash_count" -gt 0 ]]; then
    printf "%s\n" "$stashes" | while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      stash_id="${line%%:*}"
      printf "%s\t%s\t%s\n" "$repo" "$stash_id" "$line" >> "$STASHES_TSV"
    done
  fi

  if [[ "$untracked_count" -gt 0 ]]; then
    printf "%s\n" "$untracked" | while IFS= read -r path; do
      [[ -n "$path" ]] || continue
      printf "%s\t%s\n" "$repo" "$path" >> "$UNTRACKED_TSV"
    done
  fi

  if [[ "$ignored_count" -gt 0 ]]; then
    printf "%s\n" "$ignored" | while IFS= read -r path; do
      [[ -n "$path" ]] || continue
      printf "%s\t%s\n" "$repo" "$path" >> "$IGNORED_TSV"
    done
  fi

  {
    echo
    echo "============================================================"
    echo "$repo"
    echo "============================================================"
    echo
    echo "Branch:"
    echo "  $branch"
    echo
    echo "HEAD:"
    echo "  $head_line"
    echo
    echo "Status summary:"
    echo "  $status_summary"
    echo
    echo "Status -sb:"
    if [[ -n "$status_short" ]]; then
      printf "%s\n" "$status_short" | sed 's/^/  /'
    else
      echo "  <none>"
    fi
    echo
    echo "Uncommitted tracked changes: $tracked_change_count"
    if [[ "$tracked_change_count" -gt 0 ]]; then
      printf "%s\n" "$tracked_changes" | head -n "$MAX_LINES_PER_SECTION" | sed 's/^/  /'
      if [[ "$tracked_change_count" -gt "$MAX_LINES_PER_SECTION" ]]; then
        echo "  ... omitted $((tracked_change_count - MAX_LINES_PER_SECTION)) additional tracked changes from text report"
      fi
    else
      echo "  <none>"
    fi
    echo
    echo "Remote URLs:"
    if [[ "$remotes" != "<none>" ]]; then
      git -C "$repo" remote -v 2>/dev/null | awk '!seen[$0]++' | sed 's/^/  /'
    else
      echo "  <none>"
    fi
    echo
    echo "Local branches:"
    git -C "$repo" branch -vv 2>/dev/null | sed 's/^/  /' || echo "  <none>"
    echo
    echo "Local commits not on any remote: $local_commit_count"
    if [[ "$local_commit_count" -gt 0 ]]; then
      printf "%s\n" "$local_commits" | head -n "$MAX_LINES_PER_SECTION" | sed 's/^/  /'
      if [[ "$local_commit_count" -gt "$MAX_LINES_PER_SECTION" ]]; then
        echo "  ... omitted $((local_commit_count - MAX_LINES_PER_SECTION)) additional commits from text report"
      fi
    else
      echo "  <none>"
    fi
    echo
    echo "Stashes: $stash_count"
    if [[ "$stash_count" -gt 0 ]]; then
      printf "%s\n" "$stashes" | head -n "$MAX_LINES_PER_SECTION" | sed 's/^/  /'
      if [[ "$stash_count" -gt "$MAX_LINES_PER_SECTION" ]]; then
        echo "  ... omitted $((stash_count - MAX_LINES_PER_SECTION)) additional stashes from text report"
      fi
    else
      echo "  <none>"
    fi
    echo
    echo "Untracked non-ignored files: $untracked_count"
    if [[ "$untracked_count" -gt 0 ]]; then
      printf "%s\n" "$untracked" | summarize_paths "$ROLLUP_THRESHOLD" "$MAX_LINES_PER_SECTION"
    else
      echo "  <none>"
    fi

    if [[ "$INCLUDE_IGNORED" == "true" ]]; then
      echo
      echo "Ignored files reported by Git: $ignored_count"
      if [[ "$ignored_count" -gt 0 ]]; then
        printf "%s\n" "$ignored" | summarize_paths "$ROLLUP_THRESHOLD" "$MAX_LINES_PER_SECTION"
      else
        echo "  <none>"
      fi
    fi
  } >> "$REPORT"

done < <(find_repos)

{
  echo
  echo "============================================================"
  echo "Overall Summary"
  echo "============================================================"
  echo
  echo "Repos scanned:                         $repo_count"
  echo "Repos with uncommitted status entries: $dirty_repo_count"
  echo "Repos with local-only commits:         $local_commit_repo_count"
  echo "Repos with stashes:                    $stash_repo_count"
  echo "Repos with untracked non-ignored:      $untracked_repo_count"
  echo
  echo "Next checks:"
  echo "  1. Review repos with local-only commits."
  echo "  2. Review repos with stashes."
  echo "  3. Review untracked non-ignored files."
  echo "  4. Commit/push important work or back it up before reimaging."
  echo
  echo "Full detail TSV files:"
  echo "  $REPOS_TSV"
  echo "  $COMMITS_TSV"
  echo "  $STASHES_TSV"
  echo "  $TRACKED_TSV"
  echo "  $UNTRACKED_TSV"
  echo "  $IGNORED_TSV"
} >> "$REPORT"

# Keep the historical filename available for older docs/scripts while making the
# checklist-friendly git-audit-summary-*.txt the primary report.
if [[ "$LEGACY_REPORT" != "$REPORT" ]]; then
  cp -p "$REPORT" "$LEGACY_REPORT"
fi

echo "Audit complete:"
echo "  $REPORT"
echo "  $LEGACY_REPORT"
echo
echo "TSV indexes:"
echo "  $REPOS_TSV"
echo "  $COMMITS_TSV"
echo "  $STASHES_TSV"
echo "  $TRACKED_TSV"
echo "  $UNTRACKED_TSV"
echo "  $IGNORED_TSV"
