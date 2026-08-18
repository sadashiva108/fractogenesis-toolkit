#!/usr/bin/env bash
# =============================================================================
# restore-repos.sh
#
# Phase 11B — Restore Repositories status recorder and action emitter.
#
# Reads the most recent pre-image repository audit produced by Phase 2A
# (backup-repos.md), classifies every tracked repo against the current state
# of the reimaged Mac, and emits a per-repo restore-status report along with
# ready-to-run `git clone` and `rsync` commands the operator executes by hand.
#
# This file is intended for bin/. It is the post-image counterpart to
# bin/backup-repos.sh: that script writes repo-audit-reports/runs/pre-image-*,
# this one consumes the latest such run and writes
# repo-audit-reports/runs/post-image-restore-*.
#
# This is an aggregate validator: it records evidence and prints action items,
# it does not autonomously clone repositories or overwrite working trees. The
# only mutating operation it performs is an opt-in rsync of pre-image kept
# ignored files back into repos already present on disk, and only when
# --apply-ignored-files is passed and the operator confirms each repo.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/restore-repos.sh
#
#   # Default -- read-only status report. Emits clone and rsync commands but
#   # does not run them. Writes under
#   # $REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/post-image-restore-*.
#   ./bin/restore-repos.sh
#
#   # Apply staged-ignored-files/live/<label>/ back into each repo already
#   # present on disk, prompting Y/n per repo before rsyncing.
#   ./bin/restore-repos.sh --apply-ignored-files
#
#   # Override the artifact root for this invocation.
#   ./bin/restore-repos.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Point at a specific pre-image audit run instead of the latest.
#   ./bin/restore-repos.sh --input-run pre-image-YYYYMMDD-HHMMSS
#
#   # Reveal the generated report in Finder after completion.
#   ./bin/restore-repos.sh --open
#
# Options:
#   --artifact-root PATH   Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --input-run NAME       Basename of a run under repo-audit-reports/runs/
#                          to consume instead of the latest-run.txt pointer.
#                          Must name a pre-image-* or post-image-* run; values
#                          containing .. or starting with / are rejected. The
#                          same guards apply to latest-run.txt's contents.
#   --apply-ignored-files  Rsync staged-ignored-files/live/<label>/ into each
#                          repo present on disk, prompting Y/n per repo.
#   --output DIR           Exact output directory for the generated report.
#                          A relative value is resolved against the current
#                          directory, and a destination inside the repo
#                          checkout is refused. Because the run then lives
#                          outside repo-audit-reports/runs/, the
#                          latest-post-image-restore.txt pointer is left
#                          unchanged and Phase 14 keeps reading the previous
#                          default-located run.
#   --open                 Reveal the generated report in Finder on completion.
#   -h, --help             Show this message and exit.
#
# Requires:
#   rsync   Used only by --apply-ignored-files and by the emitted
#           rsync-ignored-files.sh commands.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Output location:
#   $REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/post-image-restore-YYYYMMDD-HHMMSS/
#
# Exit status:
#   0  Status report written; no fatal errors.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -uo pipefail
# NOTE: intentionally NOT set -e. This is an aggregate validator: individual
# command failures become WARN/TODO rows in the report rather than aborting the
# run, so one unreachable repo cannot hide the status of the rest. -u and
# pipefail stay on.

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

# Phase 11B needs the artifact drive mounted so the pre-image repo audit
# produced by Phase 2A is reachable, but --artifact-root may supply that path
# after parsing. Keep loading permissive and validate the resolved value below.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
if ! source "$CONFIG_LOADER"; then
  echo "ERROR: shared reimage configuration could not be loaded." >&2
  echo "Refusing to continue: REIMAGE_ARTIFACT_ROOT may still hold a stale value exported by a previous run." >&2
  exit 2
fi

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

# ---------------------------------------------------------------------------
# Defaults and command-line parsing
# ---------------------------------------------------------------------------
STAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_DIR=""
INPUT_RUN=""
APPLY_IGNORED_FILES=false
OPEN_RESULT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --input-run)
      require_option_value "$1" "${2:-}"
      INPUT_RUN="$2"
      shift 2
      ;;
    --apply-ignored-files)
      APPLY_IGNORED_FILES=true
      shift
      ;;
    --output)
      require_option_value "$1" "${2:-}"
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --open)
      OPEN_RESULT=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve inputs (pre-image audit) and outputs
# ---------------------------------------------------------------------------
absolute_path() {
  # Lexically resolve a possibly-relative path against $PWD without requiring
  # it to exist, so prefix checks below cannot be defeated by relativity.
  # No symlink resolution; Bash 3.2 safe (no arrays, no word splitting).
  local input="$1"
  local resolved=""
  local rest
  local segment

  case "$input" in
    /*) ;;
    *) input="$PWD/$input" ;;
  esac

  rest="$input"
  while [[ -n "$rest" ]]; do
    segment="${rest%%/*}"
    if [[ "$segment" == "$rest" ]]; then
      rest=""
    else
      rest="${rest#*/}"
    fi
    case "$segment" in
      ''|.) ;;
      ..) resolved="${resolved%/*}" ;;
      *) resolved="$resolved/$segment" ;;
    esac
  done

  printf '%s' "${resolved:-/}"
}

validate_run_reference() {
  # Reject run references that are not repo-audit run names, and reject path
  # traversal or absolute paths. Mirrors the guards in
  # bin/backup-repos.sh -> resolve_latest_audit_report().
  local source_label="$1"
  local value="$2"

  case "$value" in
    runs/pre-image-*|runs/post-image-*|pre-image-*|post-image-*) ;;
    *)
      echo "ERROR: invalid $source_label repository-audit run reference: ${value:-<empty>}" >&2
      return 1
      ;;
  esac

  case "$value" in
    *..*|/*)
      echo "ERROR: unsafe $source_label repository-audit run reference: $value" >&2
      return 1
      ;;
  esac
}

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" || ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set or not a directory. Reconnect the artifact volume and rerun." >&2
  exit 2
fi

AUDIT_ROOT="$REIMAGE_ARTIFACT_ROOT/repo-audit-reports"
RUNS_DIR="$AUDIT_ROOT/runs"
LATEST_POINTER="$AUDIT_ROOT/latest-run.txt"

if [[ -z "$INPUT_RUN" ]]; then
  if [[ ! -f "$LATEST_POINTER" ]]; then
    echo "ERROR: latest-run pointer not found: $LATEST_POINTER" >&2
    echo "Phase 2A (backup-repos.md) must produce a pre-image audit before Phase 11B can restore from it." >&2
    exit 2
  fi
  INPUT_RUN="$(tr -d '[:space:]' < "$LATEST_POINTER")"
  validate_run_reference "latest-run pointer" "$INPUT_RUN" || exit 2
  # latest-run.txt stores a path relative to repo-audit-reports/; strip a
  # leading runs/ segment when present so we can join uniformly below.
  INPUT_RUN="${INPUT_RUN#runs/}"
else
  validate_run_reference "--input-run" "$INPUT_RUN" || exit 2
  INPUT_RUN="${INPUT_RUN#runs/}"
fi

INPUT_RUN_DIR="$RUNS_DIR/$INPUT_RUN"
if [[ ! -d "$INPUT_RUN_DIR" ]]; then
  echo "ERROR: input run directory not found: $INPUT_RUN_DIR" >&2
  exit 2
fi

REPOS_TSV="$INPUT_RUN_DIR/repos.tsv"
COMMITS_TSV="$INPUT_RUN_DIR/local-only-commits.tsv"
STASHES_TSV="$INPUT_RUN_DIR/stashes.tsv"
TRACKED_TSV="$INPUT_RUN_DIR/tracked-changes.tsv"

if [[ ! -f "$REPOS_TSV" ]]; then
  echo "ERROR: repos.tsv not found in pre-image audit run: $REPOS_TSV" >&2
  exit 2
fi

STAGED_LIVE="$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live"

OUTPUT_DIR_DEFAULTED=false
if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="$RUNS_DIR/post-image-restore-$STAMP"
  OUTPUT_DIR_DEFAULTED=true
fi

# Resolve before the checkout guard below: a relative --output would otherwise
# slip past a prefix comparison against the absolute REPO_ROOT.
OUTPUT_DIR="$(absolute_path "$OUTPUT_DIR")"

# Safety invariant: refuse to write generated output under the repo checkout.
if [[ -n "${REPO_ROOT:-}" && ( "$OUTPUT_DIR" == "$REPO_ROOT" || "$OUTPUT_DIR" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $OUTPUT_DIR" >&2
  exit 2
fi

OUT="$OUTPUT_DIR"
RAW_DIR="$OUT/raw"
mkdir -p "$RAW_DIR"

# Preserve the pre-image inputs alongside the report for provenance.
cp -p "$REPOS_TSV" "$RAW_DIR/repos-input.tsv" 2>/dev/null || true
[[ -f "$COMMITS_TSV" ]] && cp -p "$COMMITS_TSV" "$RAW_DIR/local-only-commits-input.tsv" 2>/dev/null || true
[[ -f "$STASHES_TSV" ]] && cp -p "$STASHES_TSV" "$RAW_DIR/stashes-input.tsv" 2>/dev/null || true
[[ -f "$TRACKED_TSV" ]] && cp -p "$TRACKED_TSV" "$RAW_DIR/tracked-changes-input.tsv" 2>/dev/null || true

STATUS_TSV="$RAW_DIR/status.tsv"
REPORT_MD="$OUT/restore-status.md"

printf "repo_path\tlabel\tpath_present\tremote_url\tclone_host\tclone_target_root\tignored_files_available\tignored_files_applied\tcarry_forward_rows\n" > "$STATUS_TSV"

# ---------------------------------------------------------------------------
# Per-repo classification
# ---------------------------------------------------------------------------
# repos.tsv columns:
#   1 repo         (absolute path on the pre-image machine)
#   2 branch
#   3 head
#   4 remote_urls  (semicolon-joined `name url (fetch|push)` lines)
#   5 status_summary
#   6 local_only_commit_count
#   7 stash_count
#   8 tracked_change_count
#   9 untracked_nonignored_count
#  10 ignored_count

# Derived Git roots from reimage.env (may be empty if not set).
WORK_ROOT="${GIT_WORK_REPO_ROOT:-}"
PERSONAL_ROOT="${GIT_PERSONAL_REPO_ROOT:-}"
WORK_HOST="${GIT_WORK_GITHUB_HOST:-github.com}"
PERSONAL_HOST="${GIT_PERSONAL_GITHUB_HOST:-github-personal}"

# Strip trailing slashes so prefix checks are consistent.
WORK_ROOT="${WORK_ROOT%/}"
PERSONAL_ROOT="${PERSONAL_ROOT%/}"

extract_remote_url() {
  # Given the raw remote_urls field, return the first origin fetch URL, or
  # any URL if origin fetch is not present.
  local remotes="$1"
  local url
  url="$(printf '%s\n' "$remotes" | tr ';' '\n' | awk '/^ *origin[[:space:]]+.*\(fetch\)/{print $2; exit}')"
  if [[ -z "$url" ]]; then
    url="$(printf '%s\n' "$remotes" | tr ';' '\n' | awk 'NF>=2{print $2; exit}')"
  fi
  printf '%s' "$url"
}

numeric_or_zero() {
  case "${1:-}" in
    ''|*[!0-9]*) printf '0' ;;
    *)           printf '%s' "$1" ;;
  esac
}

classify_repo() {
  # Sets globals: PATH_PRESENT, CLONE_HOST, CLONE_TARGET_ROOT, IGN_AVAILABLE,
  # IGN_APPLIED, CARRY_FORWARD_ROWS. Reads: repo_path, label, remote_url,
  # local_commit_count, stash_count, tracked_change_count.
  local repo_path="$1"
  local remote_url="$2"

  if [[ -d "$repo_path/.git" ]]; then
    PATH_PRESENT="yes"
  else
    PATH_PRESENT="no"
  fi

  # Route by original repo location on the pre-image machine.
  if [[ -n "$PERSONAL_ROOT" && "$repo_path" == "$PERSONAL_ROOT"/* ]]; then
    CLONE_HOST="$PERSONAL_HOST"
    CLONE_TARGET_ROOT="$PERSONAL_ROOT"
  else
    CLONE_HOST="$WORK_HOST"
    if [[ -n "$WORK_ROOT" ]]; then
      CLONE_TARGET_ROOT="$WORK_ROOT"
    else
      # Fall back to the pre-image parent directory when GIT_WORK_REPO_ROOT
      # is unset.
      CLONE_TARGET_ROOT="$(dirname "$repo_path")"
    fi
  fi

  # staged-ignored-files/live/<basename(repo)>/
  if [[ -n "$label" && -d "$STAGED_LIVE/$label" ]]; then
    IGN_AVAILABLE="yes"
  else
    IGN_AVAILABLE="no"
  fi

  IGN_APPLIED="unknown"

  local carry=0
  # numeric_or_zero, not [[ -gt ]]: [[ ]] evaluates its operands arithmetically,
  # so a non-numeric cell such as "n/a" is treated as a variable name, trips
  # set -u, and aborts the whole run with the message swallowed by 2>/dev/null.
  carry=$(( carry + $(numeric_or_zero "$local_commit_count") ))
  carry=$(( carry + $(numeric_or_zero "$stash_count") ))
  carry=$(( carry + $(numeric_or_zero "$tracked_change_count") ))
  CARRY_FORWARD_ROWS="$carry"
}

# Rewrite remote_url with the personal host alias when routing to personal.
# Returns the owner segment of a github SSH or HTTPS URL, or "" if not github.
remote_owner() {
  local url="$1" rest=""
  case "$url" in
    git@github.com:*)             rest="${url#git@github.com:}" ;;
    https://github.com/*)         rest="${url#https://github.com/}" ;;
    ssh://git@github.com/*)       rest="${url#ssh://git@github.com/}" ;;
    *) printf ''; return 0 ;;
  esac
  printf '%s' "${rest%%/*}"
}

rewrite_remote_for_host() {
  local url="$1"
  local host="$2"
  # Routing to the personal host alias is decided by the pre-image DIRECTORY the
  # repo sat in, which says nothing about who owns the remote. Swapping only the
  # host while keeping the path produced
  #   git@github-personal:<work-org>/<repo>.git
  # -- a personal key pointed at the work org's repo, which either fails auth or,
  # worse, silently resolves to a different account's repo of the same name.
  # So rewrite ONLY when the URL's owner really is the personal account.
  # GIT_PERSONAL_GITHUB_OWNER unset => never rewrite; the emitted command carries
  # a REVIEW comment with the aliased form so the operator can decide.
  local owner
  owner="$(remote_owner "$url")"
  if [[ "$url" == git@github.com:* && "$host" != "github.com" \
        && -n "${GIT_PERSONAL_GITHUB_OWNER:-}" && "$owner" == "${GIT_PERSONAL_GITHUB_OWNER}" ]]; then
    printf 'git@%s:%s' "$host" "${url#git@github.com:}"
  else
    printf '%s' "$url"
  fi
}

# Emits `git remote add` lines for every remote in the pre-image field except
# origin. Without this only origin survives the restore: every other remote is
# dropped and the branch's upstream silently re-points at origin, so the next
# push goes somewhere the operator did not intend.
emit_extra_remotes() {
  local remotes="$1" target="$2"
  printf '%s\n' "$remotes" | tr ';' '\n' | awk -v t="$target" '
    /\(fetch\)/ && NF>=2 && $1 != "origin" {
      printf "git -C \"%s\" remote add %s \"%s\" 2>/dev/null || \\\n", t, $1, $2
      printf "  git -C \"%s\" remote set-url %s \"%s\"\n", t, $1, $2
    }'
}

# ---------------------------------------------------------------------------
# Iterate repos.tsv and build the per-repo status report
# ---------------------------------------------------------------------------
TOTAL=0
PRESENT_COUNT=0
NEEDS_CLONE_COUNT=0
IGN_AVAILABLE_COUNT=0
IGN_APPLIED_COUNT=0
CARRY_FORWARD_TOTAL=0

# ---------------------------------------------------------------------------
# Duplicate-basename guard
#
# Staged bundles are keyed by `basename "$repo_path"`. Two repos sharing a
# basename across the work and personal roots collapse to one
# staged-ignored-files/live/<label>/ and one repos-gitignored/<label>/, and the
# emitted commands would rsync that single bundle into BOTH working trees --
# which can put work credentials into a repo that gets pushed publicly.
# Detect it up front and name the offenders rather than failing quietly.
# ---------------------------------------------------------------------------
DUPLICATE_LABELS="$(
  tail -n +2 "$REPOS_TSV" | cut -f1 | while IFS= read -r rp; do
    [[ -n "$rp" ]] && basename "$rp"
  done | sort | uniq -d
)"
DUPLICATE_LABEL_COUNT=0
if [[ -n "$DUPLICATE_LABELS" ]]; then
  DUPLICATE_LABEL_COUNT="$(printf '%s\n' "$DUPLICATE_LABELS" | grep -c .)"
  echo "" >&2
  echo "WARNING: $DUPLICATE_LABEL_COUNT repo basename(s) appear more than once." >&2
  echo "Staged bundles are keyed by basename, so these share one bundle:" >&2
  printf '%s\n' "$DUPLICATE_LABELS" | sed 's/^/  - /' >&2
  echo "Reconcile these by hand before running the emitted rsync commands." >&2
  echo "" >&2
fi

# Build clone-commands and rsync-commands as here-doc-friendly text lines
# collected in temporary files (avoids Bash 3.2 array-under-set-u pitfalls).
CLONE_CMDS="$OUT/clone-commands.sh"
RSYNC_CMDS="$OUT/rsync-ignored-files.sh"
GITIGNORED_CMDS="$OUT/rsync-repos-gitignored.sh"
{
  echo "#!/usr/bin/env bash"
  echo "# Generated by restore-repos.sh on $(date)"
  echo "# Source repo-audit run: $INPUT_RUN"
  echo "# Review each command before running. This script does NOT autorun."
  echo "set -euo pipefail"
  echo ""
  echo "# Every path and URL below is already resolved, so this script needs no"
  echo "# reimage.env and runs in a plain shell."
  echo ""
  echo "# Neither clone root is guaranteed to exist on a freshly reimaged Mac;"
  echo "# without this the first 'cd' fails and set -e kills the whole batch."
  echo "mkdir -p \"$GIT_WORK_REPO_ROOT\" \"$GIT_PERSONAL_REPO_ROOT\""
  echo ""
} > "$CLONE_CMDS"
{
  echo "#!/usr/bin/env bash"
  echo "# Generated by restore-repos.sh on $(date)"
  echo "# Rsync pre-image kept ignored files back into cloned repos."
  echo "# Review each command before running. This script does NOT autorun."
  echo "set -euo pipefail"
  echo ""
} > "$RSYNC_CMDS"
{
  echo "#!/usr/bin/env bash"
  echo "# Generated by restore-repos.sh on $(date)"
  echo "# Restore per-repo gitignored SECRETS from secrets-encrypted/repos-gitignored/."
  echo "# These live inside the encrypted DMG, so it must be attached first."
  echo "# Review each command before running. This script does NOT autorun."
  echo "set -euo pipefail"
  echo ""
  echo "# Locate the mounted image by content, not by volume name -- the volname"
  echo "# used at hdiutil create time need not match the .dmg filename."
  echo 'DMG_MOUNT="${DMG_MOUNT:-}"'
  echo 'if [ -z "$DMG_MOUNT" ]; then'
  echo '  for c in /Volumes/*/repos-gitignored; do'
  echo '    [ -d "$c" ] && DMG_MOUNT="$(dirname "$c")" && break'
  echo '  done'
  echo 'fi'
  echo 'if [ -z "$DMG_MOUNT" ]; then'
  echo '  echo "ERROR: secrets DMG is not attached (no /Volumes/*/repos-gitignored found)." >&2'
  echo '  echo "Attach it first -- see restore-access.md Step 1 -- or set DMG_MOUNT=/Volumes/<name>." >&2'
  echo '  exit 2'
  echo 'fi'
  echo 'echo "Using image at: $DMG_MOUNT"'
  echo ""
} > "$GITIGNORED_CMDS"

# Read repos.tsv, skipping the header row.
first=true
while IFS=$'\t' read -r repo_path branch head_line remotes status_summary \
  local_commit_count stash_count tracked_change_count untracked_count ignored_count
do
  if [[ "$first" == true ]]; then
    first=false
    continue
  fi
  [[ -n "$repo_path" ]] || continue

  TOTAL=$((TOTAL + 1))
  label="$(basename "$repo_path")"
  remote_url="$(extract_remote_url "$remotes")"

  classify_repo "$repo_path" "$remote_url"

  clone_url="$(rewrite_remote_for_host "$remote_url" "$CLONE_HOST")"

  if [[ "$PATH_PRESENT" == "yes" ]]; then
    PRESENT_COUNT=$((PRESENT_COUNT + 1))
  else
    NEEDS_CLONE_COUNT=$((NEEDS_CLONE_COUNT + 1))
    if [[ -n "$clone_url" ]]; then
      {
        echo "# $label"
        if [[ "$clone_url" != "$remote_url" ]]; then
          echo "# routed to the personal host alias (owner matches GIT_PERSONAL_GITHUB_OWNER)"
        elif [[ "$CLONE_HOST" != "github.com" && "$remote_url" == git@github.com:* ]]; then
          echo "# REVIEW: pre-image directory says personal, but the remote owner is"
          echo "#   $(remote_owner "$remote_url") -- not GIT_PERSONAL_GITHUB_OWNER (${GIT_PERSONAL_GITHUB_OWNER:-unset})."
          echo "#   Left on github.com. If it really is yours, use instead:"
          echo "#   git clone \"git@$CLONE_HOST:${remote_url#git@github.com:}\""
        fi
        echo "cd \"$CLONE_TARGET_ROOT\" && git clone \"$clone_url\""
        emit_extra_remotes "$remotes" "$CLONE_TARGET_ROOT/$label"
        if [[ -n "$branch" && "$branch" != "-" ]]; then
          echo "git -C \"$CLONE_TARGET_ROOT/$label\" checkout \"$branch\" 2>/dev/null || \\"
          echo "  echo \"WARN: $label -- pre-image branch '$branch' not found in the clone\""
        fi
        # The pre-image HEAD is the cheapest possible proof you cloned the right
        # remote. A repo whose personal remote was ahead of its work remote
        # clones "successfully" from the stale one and looks fine until much later.
        if [[ -n "$head_line" && "$head_line" != "-" ]]; then
          echo "git -C \"$CLONE_TARGET_ROOT/$label\" cat-file -e '$head_line^{commit}' 2>/dev/null || \\"
          echo "  echo \"WARN: $label -- pre-image HEAD $head_line absent; wrong remote, or unpushed work\""
        fi
        echo ""
      } >> "$CLONE_CMDS"
    else
      {
        echo "# $label -- no remote URL recorded in pre-image audit; clone manually."
        echo ""
      } >> "$CLONE_CMDS"
    fi
  fi

  if [[ "$IGN_AVAILABLE" == "yes" ]]; then
    IGN_AVAILABLE_COUNT=$((IGN_AVAILABLE_COUNT + 1))
    {
      echo "# $label"
      echo "rsync -a --stats \\"
      echo "  \"$STAGED_LIVE/$label/\" \\"
      echo "  \"$repo_path/\""
      echo ""
    } >> "$RSYNC_CMDS"
  fi

  # repos-gitignored/ is inside the DMG and cannot be probed from here, so emit
  # a guarded block for every repo and let the generated script skip the ones
  # the image does not carry.
  if [[ -n "$label" ]]; then
    {
      echo "# $label"
      echo "SRC=\"\$DMG_MOUNT/repos-gitignored/$label\""
      echo "if [ -d \"\$SRC\" ]; then"
      echo "  rsync -a --stats \"\$SRC/\" \"$repo_path/\""
      echo "else"
      echo "  echo \"skip: $label -- not present in the image\""
      echo "fi"
      echo ""
    } >> "$GITIGNORED_CMDS"
  fi

  if [[ "$(numeric_or_zero "$CARRY_FORWARD_ROWS")" -gt 0 ]]; then
    CARRY_FORWARD_TOTAL=$((CARRY_FORWARD_TOTAL + CARRY_FORWARD_ROWS))
  fi

  # ---------------------------------------------------------------
  # Optional: apply staged ignored files with per-repo confirmation
  # ---------------------------------------------------------------
  if [[ "$APPLY_IGNORED_FILES" == "true" \
        && "$PATH_PRESENT" == "yes" \
        && "$IGN_AVAILABLE" == "yes" ]]; then
    printf '\nApply staged ignored files for %s?\n' "$label"
    printf '  source: %s/%s/\n' "$STAGED_LIVE" "$label"
    printf '  target: %s/\n' "$repo_path"
    printf '  proceed? [y/N]: '
    read -r reply < /dev/tty || reply=""
    case "$reply" in
      y|Y|yes|YES)
        if rsync -a --stats "$STAGED_LIVE/$label/" "$repo_path/"; then
          IGN_APPLIED="yes"
          IGN_APPLIED_COUNT=$((IGN_APPLIED_COUNT + 1))
        else
          IGN_APPLIED="failed"
        fi
        ;;
      *)
        IGN_APPLIED="skipped"
        ;;
    esac
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$repo_path" "$label" "$PATH_PRESENT" "$remote_url" \
    "$CLONE_HOST" "$CLONE_TARGET_ROOT" \
    "$IGN_AVAILABLE" "$IGN_APPLIED" "$CARRY_FORWARD_ROWS" >> "$STATUS_TSV"

done < "$REPOS_TSV"

# ---------------------------------------------------------------------------
# Heuristic verdicts for the Phase 11B exit-criteria rows
# ---------------------------------------------------------------------------
status_pass_warn() {
  if [[ "$1" == "true" ]]; then
    printf 'PASS'
  else
    printf 'WARN'
  fi
}

REPOS_INDEX_OK="false"
[[ -f "$STATUS_TSV" && "$TOTAL" -gt 0 ]] && REPOS_INDEX_OK="true"

CLONES_COMPLETE="false"
[[ "$NEEDS_CLONE_COUNT" -eq 0 && "$TOTAL" -gt 0 ]] && CLONES_COMPLETE="true"

IGNORED_FILES_COMPLETE="false"
if [[ "$IGN_AVAILABLE_COUNT" -eq 0 ]]; then
  IGNORED_FILES_COMPLETE="true"
elif [[ "$APPLY_IGNORED_FILES" == "true" && "$IGN_APPLIED_COUNT" -eq "$IGN_AVAILABLE_COUNT" ]]; then
  IGNORED_FILES_COMPLETE="true"
fi

# ---------------------------------------------------------------------------
# Generate the Markdown report
# ---------------------------------------------------------------------------
cat > "$REPORT_MD" <<EOF
# Restore Repositories Status Report

Generated: $(date)
Script: $(basename "$0")
Output directory: $OUT
Source pre-image audit run: $INPUT_RUN
Repositories in inventory: $TOTAL

Use this report as the Phase 11B evidence bundle. The command-verifiable rows
are prefilled with a heuristic PASS/WARN verdict. Complete the remaining
rescue-branch and carry-forward rows by hand after cloning the repos and
verifying each pre-image \`reimage/YYYYMMDD/*\` rescue branch reached its
remote before reimage. See \`restore-repos.md\` for the full runbook.

## Summary

| Category | Count |
|---|---|
| Total repos in pre-image inventory | $TOTAL |
| Already present on disk | $PRESENT_COUNT |
| Needs \`git clone\` | $NEEDS_CLONE_COUNT |
| Staged ignored files available to restore | $IGN_AVAILABLE_COUNT |
| Staged ignored files applied this run | $IGN_APPLIED_COUNT |
| Carry-forward rows across repos (local commits + stashes + tracked changes) | $CARRY_FORWARD_TOTAL |

## Exit Criteria

| Check | Verification mode | How to verify | Status | Notes |
|---|---|---|---|---|
| No duplicate repo basenames | Command | \`cut -f1 repos.tsv | xargs -n1 basename | sort | uniq -d\` is empty | $( [[ "$DUPLICATE_LABEL_COUNT" -eq 0 ]] && echo 'PASS' || echo 'WARN' ) | $( [[ "$DUPLICATE_LABEL_COUNT" -eq 0 ]] && echo 'Bundle labels are unique.' || echo "Shared bundle label(s): $(printf '%s ' $DUPLICATE_LABELS). Reconcile by hand before running the rsync commands." ) |
| Pre-image repo inventory read successfully | Command | \`repos.tsv\` produced status rows | $(status_pass_warn "$REPOS_INDEX_OK") | See \`raw/repos-input.tsv\`. |
| Every tracked repo is present on disk | Mixed | \`git clone\` output from \`clone-commands.sh\` succeeded for each entry | $(status_pass_warn "$CLONES_COMPLETE") | Emitted commands to \`clone-commands.sh\`; run manually and rerun this script to confirm. |
| Every staged ignored bundle applied | Mixed | \`rsync-ignored-files.sh\` executed or \`--apply-ignored-files\` used | $(status_pass_warn "$IGNORED_FILES_COMPLETE") | Emitted commands to \`rsync-ignored-files.sh\`; review before running. |
| Rescue branches (\`reimage/YYYYMMDD/*\`) present on remote for every carry-forward row | Manual | \`git ls-remote origin 'reimage/*'\` per repo | TODO | The pre-image audit recorded $CARRY_FORWARD_TOTAL carry-forward rows across $TOTAL repos; each row must map to a pushed rescue branch or be intentionally discarded. |
| Personal repos route via the personal SSH host alias | Manual | \`git remote -v\` on each personal repo | TODO | Fill after cloning; see the personal-host pitfall in \`restore-git.md\` Step 8. |

## Per-Repo Status

| Label | Path | Present | Ignored bundle | Carry-forward rows | Clone host |
|---|---|---|---|---|---|
EOF

# Append per-repo rows to the report from status.tsv (skip header).
skip=true
while IFS=$'\t' read -r rp lbl present remote_url chost ctarget ign_avail ign_appl carry; do
  if [[ "$skip" == true ]]; then skip=false; continue; fi
  printf '| %s | %s | %s | %s | %s | %s |\n' \
    "$lbl" "$rp" "$present" "$ign_avail" "$carry" "$chost" \
    >> "$REPORT_MD"
done < "$STATUS_TSV"

cat >> "$REPORT_MD" <<EOF

## Emitted Action Files

- \`clone-commands.sh\` — one \`git clone\` per repo not present. Review, then run selectively.
- \`rsync-ignored-files.sh\` — one \`rsync\` per repo with staged ignored files available.
- \`rsync-repos-gitignored.sh\` — one guarded \`rsync\` per repo for the gitignored SECRETS held in \`secrets-encrypted/repos-gitignored/\`. Attach the DMG first; blocks for repos the image does not carry skip themselves.

Neither file is executable by default. Both carry fully resolved paths and URLs,
so they run in a plain shell with no configuration sourced first:

\`\`\`bash
cat "$OUT/clone-commands.sh"
bash "$OUT/clone-commands.sh"
\`\`\`

## Manual Follow-Up

1. Review \`clone-commands.sh\`, adjust any repos whose remote was rewritten
   from the pre-image URL, and run selectively.
2. Review \`rsync-ignored-files.sh\` and run selectively — or rerun this
   script with \`--apply-ignored-files\` to walk repos interactively.
3. For each repo with \`carry-forward rows > 0\`, run
   \`git ls-remote origin 'reimage/*'\` inside the clone to confirm the
   pre-image rescue branch is present, then merge or cherry-pick back into
   the intended branch.
4. Verify personal repos have the personal host alias in their remote URL
   (\`git remote -v\`), not the default \`github.com\`.
5. Rerun this script after cloning to update the exit-criteria table.

## Raw Evidence Files

- \`raw/status.tsv\` — per-repo status table
- \`raw/repos-input.tsv\` — copy of the pre-image \`repos.tsv\` for provenance
- \`raw/local-only-commits-input.tsv\` — pre-image carry-forward checklist rows
- \`raw/stashes-input.tsv\` — pre-image stash rows
- \`raw/tracked-changes-input.tsv\` — pre-image tracked change rows
EOF

cat > "$OUT/MANIFEST.txt" <<EOF
# Restore Repositories Status Manifest
Generated: $(date)
Script: $(basename "$0")
Output directory: $OUT
Source pre-image audit run: $INPUT_RUN

Files:
- restore-status.md
- clone-commands.sh
- rsync-ignored-files.sh
- rsync-repos-gitignored.sh
- raw/status.tsv
- raw/repos-input.tsv
- raw/local-only-commits-input.tsv
- raw/stashes-input.tsv
- raw/tracked-changes-input.tsv
EOF

# Pointer alongside (not replacing) the pre-image latest-run.txt owned by
# Phase 2A. Distinct filename keeps ownership clear.
# Only stamp it for a default-located run: the pointer is resolved relative to
# repo-audit-reports/, so recording runs/post-image-restore-$STAMP after an
# --output run elsewhere would leave Phase 14 pointed at a path that does not
# exist.
if [[ "$OUTPUT_DIR_DEFAULTED" == true ]]; then
  printf '%s\n' "runs/post-image-restore-$STAMP" > "$AUDIT_ROOT/latest-post-image-restore.txt"
else
  echo "NOTE: --output was used; latest-post-image-restore.txt left unchanged." >&2
fi

echo ""
echo "Restore repositories report complete."
echo "  Total repos in inventory: $TOTAL"
echo "  Present on disk:          $PRESENT_COUNT"
echo "  Needs clone:              $NEEDS_CLONE_COUNT"
echo "  Ignored bundles available: $IGN_AVAILABLE_COUNT"
if [[ "$APPLY_IGNORED_FILES" == "true" ]]; then
  echo "  Ignored bundles applied:   $IGN_APPLIED_COUNT"
fi
echo "  Carry-forward rows total: $CARRY_FORWARD_TOTAL"
echo ""
echo "Report → $REPORT_MD"
echo "Clone commands → $OUT/clone-commands.sh"
echo "Rsync commands → $OUT/rsync-ignored-files.sh"
echo "Gitignored secrets → $OUT/rsync-repos-gitignored.sh (needs the DMG attached)"

if [[ "$OPEN_RESULT" == "true" ]]; then
  # Never let a Finder reveal decide the run's exit status: over SSH, or on a
  # host without `open`, a correctly written report would otherwise exit nonzero.
  open -R "$REPORT_MD" 2>/dev/null || true
fi
