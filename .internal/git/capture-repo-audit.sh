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
#     --root "$GIT_WORK_REPO_ROOT" \
#     --root "$GIT_PERSONAL_REPO_ROOT" \
#     --dest "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports"
#
#   ./.internal/git/capture-repo-audit.sh \
#     --root /path/to/repositories \
#     --dest /path/to/repo-audit-reports \
#     --rollup-threshold 3 \
#     --max-lines-per-section 80
#
# Options:
#   --root <dir>                  Root directory to crawl for Git repos.
#                                 Can be passed multiple times.
#                                 Default: configured GIT_WORK_REPO_ROOT and
#                                 GIT_PERSONAL_REPO_ROOT values.
#   --dest <dir>                  Repository-audit root directory.
#                                 Default: $REIMAGE_ARTIFACT_ROOT/repo-audit-reports.
#                                 Required when REIMAGE_ARTIFACT_ROOT is not set.
#   --context pre-image|post-image
#                                 Context prefix for the timestamped run directory.
#                                 Default: pre-image
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
# Output (written beneath --dest):
#   MANIFEST.md          shared run index (artifact-runs.sh)
#   repo-audit-index.md  per-run repository counts, this category only
#       Append-only index of successful repository-audit runs.
#   official/<context>.txt
#       Relative path to the newest successful run directory.
#   runs/<context>-YYYYMMDD-HHMMSS/
#       One self-contained audit run with stable filenames:
#         repo-audit-summary.txt
#         repos.tsv
#         tracked-changes.tsv
#         local-only-commits.tsv
#         stashes.tsv
#         untracked-nonignored.tsv
#         ignored-files.tsv
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

DEST="${REIMAGE_ARTIFACT_ROOT:+${REIMAGE_ARTIFACT_ROOT}/repo-audit-reports}"
ROLLUP_THRESHOLD=3
MAX_LINES_PER_SECTION=80
INCLUDE_IGNORED="true"
CONTEXT="pre-image"

ROOTS=()

usage() {
  sed -n '/^# Usage:/,/^# =============================================================================/p' "$0" \
    | sed 's/^# \{0,2\}//' \
    | sed '$d'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
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
    --context)
      if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "ERROR: --context requires pre-image or post-image." >&2
        usage >&2
        exit 2
      fi
      CONTEXT="$2"
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

case "$CONTEXT" in
  pre-image|post-image) ;;
  *)
    echo "ERROR: --context must be pre-image or post-image, got: $CONTEXT" >&2
    exit 2
    ;;
esac

if [[ ${#ROOTS[@]} -eq 0 ]]; then
  if [[ -n "${GIT_WORK_REPO_ROOT:-}" && -d "${GIT_WORK_REPO_ROOT:-}" ]]; then
    ROOTS+=("$GIT_WORK_REPO_ROOT")
  fi

  if [[ -n "${GIT_PERSONAL_REPO_ROOT:-}" && -d "${GIT_PERSONAL_REPO_ROOT:-}" ]]; then
    ROOTS+=("$GIT_PERSONAL_REPO_ROOT")
  fi
fi

if [[ ${#ROOTS[@]} -eq 0 ]]; then
  echo "ERROR: No Git repository roots configured." >&2
  echo "Set GIT_WORK_REPO_ROOT and/or GIT_PERSONAL_REPO_ROOT in reimage.env, or pass --root <dir>." >&2
  exit 2
fi

for root in "${ROOTS[@]}"; do
  if [[ ! -d "$root" ]]; then
    echo "ERROR: Git repository root does not exist: $root" >&2
    exit 2
  fi
done

if [[ -z "$DEST" ]]; then
  echo "ERROR: No audit destination configured." >&2
  echo "Set REIMAGE_ARTIFACT_ROOT in reimage.env, or pass --dest <dir>." >&2
  exit 2
fi

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git is not installed or not on PATH." >&2
  exit 1
fi

mkdir -p "$DEST/runs"

# Staging, the atomic rename, the append-only index and the pointer were all
# hand-rolled here first; `artifact-runs.sh` is that implementation extracted so
# every producer shares one contract. This now calls it rather than carrying a
# second copy that can drift from the original.
#
# The five domain columns the old manifest carried -- repositories, dirty,
# local-only, stash, untracked -- have no home in the shared seven-column
# schema, and squashing them into free text would lose a scannable index. They
# keep their own file, `repo-audit-index.md`, which IS the old manifest: it was
# renamed rather than regenerated, so every historical row survives verbatim.
# Two indexes over one set of runs is a drift risk, and the mitigation is that
# only this script writes either of them, in one place, at one moment.
RUNS_LIB="$SCRIPT_DIR/../artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../artifact-runs.sh
source "$RUNS_LIB"

INDEX_PATH="$DEST/repo-audit-index.md"

if [[ -e "$INDEX_PATH" ]] && ! grep -q '^# Repository Audit Index$' "$INDEX_PATH" 2>/dev/null; then
  echo "ERROR: existing file is not the canonical repository-audit domain index:" >&2
  echo "  $INDEX_PATH" >&2
  echo "Remove that file before running the current audit workflow." >&2
  exit 2
fi

if ! artifact_run_begin "$DEST" "$CONTEXT"; then
  echo "ERROR: could not stage a repository-audit run under: $DEST" >&2
  exit 1
fi

# Named for what the rest of this script already calls them, so the body below
# is unchanged: it writes into the staging directory and reads the promoted one.
RUN_ID="$ARTIFACT_RUN_ID"
RUN_RELATIVE="$ARTIFACT_RUN_RELATIVE"
WORK_RUN_DIR="$ARTIFACT_RUN_DIR"
FINAL_RUN_DIR="$DEST/$RUN_RELATIVE"

cleanup_incomplete_run() {
  artifact_run_abort
}
trap cleanup_incomplete_run EXIT
trap 'exit 130' INT TERM

REPORT="$WORK_RUN_DIR/repo-audit-summary.txt"
REPOS_TSV="$WORK_RUN_DIR/repos.tsv"
COMMITS_TSV="$WORK_RUN_DIR/local-only-commits.tsv"
STASHES_TSV="$WORK_RUN_DIR/stashes.tsv"
UNTRACKED_TSV="$WORK_RUN_DIR/untracked-nonignored.tsv"
IGNORED_TSV="$WORK_RUN_DIR/ignored-files.tsv"
TRACKED_TSV="$WORK_RUN_DIR/tracked-changes.tsv"

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
  echo "Git Repository Audit"
  echo "===================="
  echo
  echo "Context: $CONTEXT"
  echo "Run: $RUN_ID"
  echo "Generated: $(date)"
  echo "Run directory: $FINAL_RUN_DIR"
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
  echo "Run files:"
  echo "  Main report:            repo-audit-summary.txt"
  echo "  Repo index:             repos.tsv"
  echo "  Local-only commits:     local-only-commits.tsv"
  echo "  Stashes:                stashes.tsv"
  echo "  Tracked changes:        tracked-changes.tsv"
  echo "  Untracked files:        untracked-nonignored.tsv"
  echo "  Ignored files:          ignored-files.tsv"
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
  echo "  repos.tsv"
  echo "  local-only-commits.tsv"
  echo "  stashes.tsv"
  echo "  tracked-changes.tsv"
  echo "  untracked-nonignored.tsv"
  echo "  ignored-files.tsv"
} >> "$REPORT"

if [[ ! -e "$INDEX_PATH" ]]; then
  cat > "$INDEX_PATH" <<'EOF'
# Repository Audit Index

Append-only, and specific to this category: the per-run repository counts that
the shared seven-column `MANIFEST.md` has no room for. `MANIFEST.md` is the
authority on which runs exist and which is official; this file exists so those
counts stay scannable side by side rather than buried in each run's report.

| Completed | Context | Run | Repositories | Dirty repos | Local-only commit repos | Stash repos | Untracked repos | Summary |
|---|---|---|---:|---:|---:|---:|---:|---|
EOF
fi

# The domain row first: if finalize fails, an indexed run with no counts is
# easier to spot and repair than counts pointing at a run nothing indexed.
COMPLETED_AT="$(date '+%Y-%m-%d %H:%M:%S')"
printf '| %s | `%s` | `%s` | %d | %d | %d | %d | %d | [Open report](%s/repo-audit-summary.txt) |\n' \
  "$COMPLETED_AT" "$CONTEXT" "$RUN_ID" \
  "$repo_count" "$dirty_repo_count" "$local_commit_repo_count" \
  "$stash_repo_count" "$untracked_repo_count" "$RUN_RELATIVE" >> "$INDEX_PATH"

if ! artifact_run_finalize "$DEST" \
     "$repo_count repos / $dirty_repo_count dirty / $local_commit_repo_count local-only / $stash_repo_count stash / $untracked_repo_count untracked"; then
  echo "ERROR: the audit was written but could not be indexed." >&2
  exit 1
fi

trap - EXIT INT TERM

echo "Audit complete:"
echo "  $FINAL_RUN_DIR/repo-audit-summary.txt"
echo
echo "Run directory:"
echo "  $FINAL_RUN_DIR"
echo
echo "TSV indexes:"
echo "  $FINAL_RUN_DIR/repos.tsv"
echo "  $FINAL_RUN_DIR/local-only-commits.tsv"
echo "  $FINAL_RUN_DIR/stashes.tsv"
echo "  $FINAL_RUN_DIR/tracked-changes.tsv"
echo "  $FINAL_RUN_DIR/untracked-nonignored.tsv"
echo "  $FINAL_RUN_DIR/ignored-files.tsv"
echo
echo "Manifest:"
echo "  $DEST/MANIFEST.md"
echo "Domain index:"
echo "  $INDEX_PATH"
echo "Official pointer:"
echo "  $DEST/official/$CONTEXT.txt"
