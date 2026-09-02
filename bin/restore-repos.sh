#!/usr/bin/env bash
# =============================================================================
# restore-repos.sh
#
# Phase 11B — Restore Repositories status recorder and action emitter.
#
# Reads the most recent pre-image repository audit produced by Phase 2A
# (backup-repos.md), classifies every tracked repo against the current state
# of the reimaged Mac, and writes a per-repo restore-status report. With
# --hydrate it also acts: clone what the plan selected and is absent, then
# merge each declared rehydration source into the working tree.
#
# This file is intended for bin/. It is the post-image counterpart to
# bin/backup-repos.sh: that script writes repo-audit-reports/runs/pre-image-*,
# this one consumes the latest such run and writes
# repo-audit-reports/runs/post-image-restore-*.
#
# Without --hydrate it is an aggregate validator: it records evidence and
# reports what it would do, and touches nothing. With --hydrate the mutating
# operations are bounded by the clone plan under $REIMAGE_WORKSPACE_ROOT: a
# repository the plan did not select is never cloned, and a working tree whose
# origin disagrees with the plan is reported as a conflict and left alone.
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
#   # Clone what is missing and merge every rehydration source.
#   ./bin/restore-repos.sh --hydrate
#
#   # Show what that would do, writing nothing.
#   ./bin/restore-repos.sh --hydrate --dry-run
#
#   # Just the cloner, or just one source.
#   ./bin/restore-repos.sh --hydrate --stage clone
#   ./bin/restore-repos.sh --hydrate --stage ignored-files
#
#   # Override the artifact root for this invocation.
#   ./bin/restore-repos.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Point at a specific pre-image audit run instead of the latest.
#   ./bin/restore-repos.sh --input-run pre-image-YYYYMMDD-HHMMSS
#
#   # Seed the durable clone plan into $REIMAGE_WORKSPACE_ROOT/repo-plan/.
#   # Existing files are kept; --force overwrites them.
#   ./bin/restore-repos.sh init-repo-plan-config
#
#   # Propose a filled-in plan from the pre-image audit, into the run bundle.
#   # Never writes to the workspace: review it, then copy what you want across.
#   ./bin/restore-repos.sh --emit-plan
#
#   # Reveal the generated report in Finder after completion.
#   ./bin/restore-repos.sh --open
#
# Commands:
#   init-repo-plan-config  Copy the committed clone-plan templates into
#                          $REIMAGE_WORKSPACE_ROOT/repo-plan/ and exit. A file
#                          that is already there is kept, because it holds your
#                          answers; --force overwrites. The workspace copy is
#                          what a run reads, and it survives the reimage.
#
# Options:
#   --artifact-root PATH   Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --input-run NAME       Basename of a run under repo-audit-reports/runs/
#                          to consume instead of the latest-run.txt pointer.
#                          Must name a pre-image-* or post-image-* run; values
#                          containing .. or starting with / are rejected. The
#                          same guards apply to latest-run.txt's contents.
#   --hydrate              Act: clone what is absent, then merge each declared
#                          rehydration source. Without it the run is read-only
#                          and reports what it would do.
#   --dry-run              Write nothing anywhere: no run is staged, no sign-off
#                          is opened, no index moves. The report and hydrated.md
#                          are composed and printed to stdout instead. Composes
#                          with --hydrate to show what hydrating would do.
#                          Refused with --output or --emit-plan, which write.
#   --stage NAME           Repeatable. Run only the named stage: `clone`, or any
#                          ARTIFACT_TYPE from repo-rehydration-sources.conf.sh.
#                          Omitted, every stage runs.
#   --output DIR           Exact output directory for the generated report.
#                          A relative value is resolved against the current
#                          directory, and a destination inside the repo
#                          checkout is refused. Because the run then lives
#                          outside repo-audit-reports/runs/, it is not indexed
#                          and official/post-image-restore.txt is left
#                          unchanged, so Phase 14 keeps reading the previous
#                          default-located run.
#   --emit-plan            Also write a proposed plan under plan-proposed/ in
#                          the run bundle, filled in from the pre-image audit:
#                          one entry per repository, routed the way this run
#                          routed it. It is a proposal, not the plan — the
#                          workspace copy is never written by a run.
#   --force                With init-repo-plan-config only: overwrite plan
#                          fragments that already exist in the workspace.
#   --open                 Reveal the generated report in Finder on completion.
#   -h, --help             Show this message and exit.
#
# Requires:
#   rsync   Used by --hydrate to merge a rehydration source into a working
#           tree. Not needed for a run without --hydrate.
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

# Manual rows leave the generated artifact. This script is rerun freely and each
# run writes a newly stamped file, so a row answered inside one is not carried
# into the next. The sign-off carries answers forward and records the run each
# was answered against, and lands in reimaged-system/sign-offs/ with every other
# post-image answered row. See .internal/sign-offs.sh.
RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/artifact-runs.sh
source "$RUNS_LIB"

SIGNOFF_LIB="$REPO_ROOT/.internal/sign-offs.sh"
if [[ ! -f "$SIGNOFF_LIB" ]]; then
  echo "ERROR: shared sign-off helper not found: $SIGNOFF_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/sign-offs.sh
source "$SIGNOFF_LIB"

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
REPORT_GENERATED="$(date)"
OUTPUT_DIR=""
INPUT_RUN=""
HYDRATE=false
DRY_RUN=false
STAGES=""
OPEN_RESULT=false
INIT_PLAN_CONFIG=false
FORCE_INIT=false
EMIT_PLAN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    init-repo-plan-config|init-repo-plan)
      INIT_PLAN_CONFIG=true
      shift
      ;;
    --force)
      FORCE_INIT=true
      shift
      ;;
    --emit-plan)
      EMIT_PLAN=true
      shift
      ;;
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
    --hydrate)
      HYDRATE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --stage)
      require_option_value "$1" "${2:-}"
      STAGES="${STAGES}${STAGES:+ }$2"
      shift 2
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

# --dry-run means what it means in every other script here: nothing is written
# anywhere. Two options ask for the opposite, so they are refused rather than
# silently ignored -- a flag that appears to have been honoured and was not is
# the failure this phase keeps meeting.
if [[ "$DRY_RUN" == true && -n "$OUTPUT_DIR" ]]; then
  echo "ERROR: --dry-run writes nothing, so --output has nowhere to write to." >&2
  exit 2
fi
if [[ "$DRY_RUN" == true && "$EMIT_PLAN" == true ]]; then
  echo "ERROR: --dry-run writes nothing, and --emit-plan exists to write a file." >&2
  echo "Run --emit-plan on its own; it never touches the workspace plan." >&2
  exit 2
fi

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

# ---------------------------------------------------------------------------
# init-repo-plan-config
#
# Seeds the durable plan and exits. Deliberately ahead of the artifact-root
# check below: seeding writes to the workspace, not the artifact volume, and
# refusing to seed because a drive is unplugged would be a rule with no reason
# behind it.
# ---------------------------------------------------------------------------
if [[ "$INIT_PLAN_CONFIG" == true ]]; then
  PLAN_LIB="$REPO_ROOT/.internal/git/repo-plan.sh"
  if [[ ! -f "$PLAN_LIB" ]]; then
    echo "ERROR: clone-plan library not found: $PLAN_LIB" >&2
    exit 2
  fi
  # shellcheck source=../.internal/git/repo-plan.sh
  source "$PLAN_LIB"

  if [[ -z "${REIMAGE_WORKSPACE_ROOT:-}" ]]; then
    echo "ERROR: REIMAGE_WORKSPACE_ROOT is not set, so there is nowhere durable to seed." >&2
    echo "The plan is a declaration, not evidence: it lives in the workspace so it survives the reimage." >&2
    echo "Record the workspace root in reimage.env, then rerun." >&2
    exit 2
  fi

  echo "Seeding the clone plan"
  echo "  from: ${REPO_PLAN_TEMPLATE_DIR:-<unresolved>}"
  echo "  into: ${REPO_PLAN_WORKSPACE_DIR:-<unresolved>}"
  echo ""
  if ! repo_plan_init_workspace \
        "${REPO_PLAN_TEMPLATE_DIR:-}" "${REPO_PLAN_WORKSPACE_DIR:-}" "$FORCE_INIT"; then
    exit 2
  fi
  echo ""
  echo "Edit those four files, then rerun this script to read them."
  exit 0
fi

# REPO_PLAN_SOURCE_DIR is resolved by .internal/artifact-config.sh. This is the
# entrypoint where the fallback actually costs something, so it is the one that
# warns about it -- the same division stage-certs-keychain.sh uses.
#
# The fallback does not fail, and that is the problem. Every entry in the
# committed templates is commented out, so a run against them loads clean,
# reports every repository as unreviewed, and clones nothing. That reads as
# "this phase has nothing to do" rather than "you are reading the wrong file".
if [[ "${REPO_PLAN_SOURCE_DIR:-}" == "${REPO_PLAN_TEMPLATE_DIR:-}" && -n "${REPO_PLAN_WORKSPACE_DIR:-}" ]]; then
  echo "WARNING: REIMAGE_WORKSPACE_ROOT is set but $REPO_PLAN_WORKSPACE_DIR does not exist —" >&2
  echo "         falling back to the committed clone-plan templates, which declare nothing." >&2
  echo "         Run: ./bin/restore-repos.sh init-repo-plan-config" >&2
fi

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" || ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set or not a directory. Reconnect the artifact volume and rerun." >&2
  exit 2
fi

AUDIT_ROOT="$REIMAGE_ARTIFACT_ROOT/repo-audit-reports"
RUNS_DIR="$AUDIT_ROOT/runs"

if [[ -z "$INPUT_RUN" ]]; then
  # `pre-image` by name, not "whatever ran last". The pointer this replaced
  # accepted either prefix, so a previous post-image restore run could become
  # the input to the next one -- restoring from a restore.
  INPUT_RUN="$(artifact_run_official "$AUDIT_ROOT" "pre-image" 2>/dev/null || true)"
  if [[ -z "$INPUT_RUN" ]]; then
    echo "ERROR: no official pre-image repository-audit run under: $AUDIT_ROOT" >&2
    echo "Phase 2A (backup-repos.md) must produce a pre-image audit before Phase 11B can restore from it." >&2
    exit 2
  fi
  validate_run_reference "official pre-image pointer" "$INPUT_RUN" || exit 2
  # The pointer stores a path relative to repo-audit-reports/; strip the leading
  # runs/ segment so we can join uniformly below.
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

# A default-located run is staged and indexed through the shared run index; an
# --output run is not, because it lives outside runs/ and the index resolves
# relative to the category root. `post-image-restore` is its own lineage, so
# advancing it never disturbs `official/pre-image.txt`.
OUTPUT_DIR_DEFAULTED=false
DRY_RUN_TMP=""
if [[ "$DRY_RUN" == true ]]; then
  # The report is still composed, because a dry run whose output you cannot read
  # tells you nothing. It is composed somewhere the operator's evidence is not:
  # no run is staged, so no run id is consumed and no pointer moves.
  DRY_RUN_TMP="$(mktemp -d "${TMPDIR:-/tmp}/restore-repos-dryrun.XXXXXX")" || {
    echo "ERROR: could not create a scratch directory for --dry-run." >&2
    exit 2
  }
  trap 'rm -rf "$DRY_RUN_TMP"' EXIT
  OUTPUT_DIR="$DRY_RUN_TMP"
elif [[ -z "$OUTPUT_DIR" ]]; then
  if ! artifact_run_begin "$AUDIT_ROOT" "post-image-restore"; then
    echo "ERROR: could not stage a run under: $AUDIT_ROOT" >&2
    exit 2
  fi
  OUTPUT_DIR="$ARTIFACT_RUN_DIR"
  # The run id owns the stamp from here on, so the sign-off and the run name
  # cannot drift apart by a second.
  STAMP="${ARTIFACT_RUN_ID#post-image-restore-}"
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

# The sign-off is named for this run, which is what lets a carried answer say
# which run it was answered against. It sits outside runs/ rather than inside
# one, because a run directory is replaced and an answered row must not be.
#
# It lives under reimaged-system/ rather than beside the category it reports on.
# Phase 11B is a post-image phase, and every post-image answered row is in
# reimaged-system/sign-offs/ -- the boundary recorders', the first-boot bundles',
# the Phase 12 plan-notes'. repo-audit-reports/ is shared with the PRE-image
# audit, so a sign-off there would be the one post-image answer a reader has to
# know to look for somewhere else.
#
# A dry run does not open one. A sign-off carries answers forward across runs,
# so one opened by a rehearsal would ask the operator to answer for work that
# did not happen.
SIGNOFF_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system/sign-offs"
if [[ "$DRY_RUN" != true ]]; then
  if ! signoff_begin "$SIGNOFF_ROOT" "post-image-restore" "post-image-restore-$STAMP"; then
    echo "ERROR: cannot open a sign-off under: $SIGNOFF_ROOT" >&2
    exit 2
  fi
fi

# Preserve the pre-image inputs alongside the report for provenance.
cp -p "$REPOS_TSV" "$RAW_DIR/repos-input.tsv" 2>/dev/null || true
[[ -f "$COMMITS_TSV" ]] && cp -p "$COMMITS_TSV" "$RAW_DIR/local-only-commits-input.tsv" 2>/dev/null || true
[[ -f "$STASHES_TSV" ]] && cp -p "$STASHES_TSV" "$RAW_DIR/stashes-input.tsv" 2>/dev/null || true
[[ -f "$TRACKED_TSV" ]] && cp -p "$TRACKED_TSV" "$RAW_DIR/tracked-changes-input.tsv" 2>/dev/null || true

STATUS_TSV="$RAW_DIR/status.tsv"
REPORT_MD="$OUT/restore-status.md"

printf "repo_path\tlabel\tpath_present\tremote_url\tclone_host\tclone_target_root\tignored_files_available\tignored_files_applied\tcarry_forward_rows\n" > "$STATUS_TSV"

# ---------------------------------------------------------------------------
# Proposal staging
#
# A proposal is written into the RUN, never into the workspace. The workspace
# copy holds the operator's answers; a run that could overwrite it would make
# every answer provisional.
# ---------------------------------------------------------------------------
PROPOSED_DIR="$OUT/plan-proposed"
PROPOSED_SELECTED="$PROPOSED_DIR/.selected.body"
PROPOSED_EXCLUDED="$PROPOSED_DIR/.excluded.body"
if [[ "$EMIT_PLAN" == true ]]; then
  mkdir -p "$PROPOSED_DIR"
  : > "$PROPOSED_SELECTED"
  : > "$PROPOSED_EXCLUDED"
fi

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
WORK_ROOT="${LOCAL_WORK_REPO_ROOT:-}"
PERSONAL_ROOT="${LOCAL_PERSONAL_REPO_ROOT:-}"
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

extract_remote_name() {
  # The name of the remote extract_remote_url picked, so a proposal can state
  # REMOTE_NAME rather than leaving the reader to infer it. Same order of
  # preference, so the two always agree.
  local remotes="$1"
  local name
  name="$(printf '%s\n' "$remotes" | tr ';' '\n' | awk '/^ *origin[[:space:]]+.*\(fetch\)/{print $1; exit}')"
  if [[ -z "$name" ]]; then
    name="$(printf '%s\n' "$remotes" | tr ';' '\n' | awk 'NF>=2{print $1; exit}')"
  fi
  printf '%s' "$name"
}

numeric_or_zero() {
  case "${1:-}" in
    ''|*[!0-9]*) printf '0' ;;
    *)           printf '%s' "$1" ;;
  esac
}

route_root() {
  # Resolve the configured root for one side of the routing decision. Falls back
  # to the work root, and finally to the pre-image parent directory, which is
  # what this script used before it routed by host.
  local side="$1" repo_path="$2"
  if [[ "$side" == "personal" && -n "$PERSONAL_ROOT" ]]; then
    printf '%s' "$PERSONAL_ROOT"
    return 0
  fi
  if [[ -n "$WORK_ROOT" ]]; then
    printf '%s' "$WORK_ROOT"
    return 0
  fi
  dirname "$repo_path"
}

classify_repo() {
  # Sets globals: PATH_PRESENT, CLONE_HOST, CLONE_TARGET_ROOT, CLONE_DEST,
  # ROUTE_REVIEW, IGN_AVAILABLE, IGN_APPLIED, CARRY_FORWARD_ROWS.
  # Reads: repo_path, label, remote_url, local_commit_count, stash_count,
  # tracked_change_count.
  local repo_path="$1"
  local remote_url="$2"
  local host owner

  host="$(remote_host "$remote_url")"
  owner="$(remote_owner "$remote_url")"
  ROUTE_REVIEW=""

  # Route by the remote HOST, not by the directory the repo occupied on the
  # pre-image machine. restore-repos.md Step 3 already states the rule -- "which
  # root a repo belongs in is decided by its remote host, not by where it lived
  # pre-image" -- and bin/record-restore-exit.sh row 3 grades against it. The
  # pre-image directory says nothing about who owns the remote, and on a
  # reimaged Mac those directories are not under either configured root, so
  # directory routing sent every repository to the work side by accident rather
  # than by decision.
  if [[ -z "$host" ]]; then
    # No remote at all. Nothing can clone it, so it never reaches the clone
    # list; the work root is named only so the report has a column to print.
    CLONE_HOST="<none>"
    CLONE_TARGET_ROOT="$(route_root work "$repo_path")"
    ROUTE_REVIEW="no remote recorded in the pre-image audit -- this repository cannot be cloned"
  elif [[ -n "$PERSONAL_HOST" && "$host" == "$PERSONAL_HOST" && "$host" != "$WORK_HOST" \
          && ( -z "${GIT_PERSONAL_GITHUB_OWNER:-}" || "$owner" == "${GIT_PERSONAL_GITHUB_OWNER}" ) ]]; then
    CLONE_HOST="$PERSONAL_HOST"
    CLONE_TARGET_ROOT="$(route_root personal "$repo_path")"
    if [[ -z "${GIT_PERSONAL_GITHUB_OWNER:-}" ]]; then
      # Routed on the host alone. Step 0c calls a blank owner a decision meaning
      # "never rewrite", and promises the candidates are flagged for review
      # instead -- this is that flag. Without it a blank owner routes silently.
      ROUTE_REVIEW="routed personal on the SSH routing host alone; GIT_PERSONAL_GITHUB_OWNER is unset, so the owner ${owner:-unknown} was not checked"
    fi
  elif [[ -n "$WORK_HOST" && "$host" == "$WORK_HOST" ]]; then
    CLONE_HOST="$WORK_HOST"
    CLONE_TARGET_ROOT="$(route_root work "$repo_path")"
  else
    # An unrecognised host, or the personal host carrying somebody else's owner.
    # Both land on the work root, and both say why: a silent default here is how
    # a repository ends up under the root that authors its commits with the
    # wrong identity.
    CLONE_HOST="$host"
    CLONE_TARGET_ROOT="$(route_root work "$repo_path")"
    if [[ -n "$PERSONAL_HOST" && "$host" == "$PERSONAL_HOST" ]]; then
      ROUTE_REVIEW="remote host is the personal host but the owner is ${owner:-unknown}, not GIT_PERSONAL_GITHUB_OWNER (${GIT_PERSONAL_GITHUB_OWNER:-unset}) -- routed to the work root"
    else
      ROUTE_REVIEW="remote host $host matches neither GIT_WORK_GITHUB_HOST nor GIT_PERSONAL_GITHUB_HOST -- routed to the work root"
    fi
  fi

  # Where this run would put the repository. Every destination below -- the
  # clone, both rsync scripts, and the presence test -- is this one path, so
  # they cannot disagree.
  CLONE_DEST="$CLONE_TARGET_ROOT/$label"

  # Presence is asked at the clone destination, not at the pre-image path. The
  # pre-image path does not exist on a reimaged Mac, so a presence test against
  # it answers "no" for every repository forever, whatever is on disk.
  if [[ -d "$CLONE_DEST/.git" ]]; then
    PATH_PRESENT="yes"
  else
    PATH_PRESENT="no"
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

# Returns the host of a git remote URL, or "" when it cannot be determined.
# Handles scheme://[user@]host[:port]/path and the scp-like user@host:path form.
remote_host() {
  local url="$1" rest=""
  case "$url" in
    *://*)  rest="${url#*://}" ;;
    *@*:*)  rest="${url#*@}"; printf '%s' "${rest%%:*}"; return 0 ;;
    *)      printf ''; return 0 ;;
  esac
  rest="${rest#*@}"     # drop any userinfo
  rest="${rest%%/*}"    # drop the path
  printf '%s' "${rest%%:*}"   # drop any port
}

# Returns the owner segment of a git remote URL, or "" when it has none.
# Host-agnostic: the same shape answers for github.com and an Enterprise host.
remote_owner() {
  local url="$1" rest=""
  case "$url" in
    *://*)  rest="${url#*://}"; rest="${rest#*@}"; rest="${rest#*/}" ;;
    *@*:*)  rest="${url#*:}" ;;
    *)      printf ''; return 0 ;;
  esac
  printf '%s' "${rest%%/*}"
}

rewrite_remote_for_host() {
  local url="$1"
  local host="$2"
  # Routing decides the ROOT; this decides the URL, and they are not the same
  # question. A repository can route personal on its host and still not want its
  # URL rewritten. Swapping only the host while keeping the path produced
  #   git@github-personal:<work-org>/<repo>.git
  # -- a personal key pointed at the work org's repo, which either fails auth or,
  # worse, silently resolves to a different account's repo of the same name.
  # So rewrite ONLY when the URL's owner really is the personal account.
  # GIT_PERSONAL_GITHUB_OWNER unset => never rewrite. classify_repo() prints a
  # REVIEW line naming the owner it saw, so an operator who disagrees with the
  # routing has what they need to move the block by hand.
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
  echo "Reconcile these by hand before hydrating: one bundle cannot serve two." >&2
  echo "" >&2
fi

# ---------------------------------------------------------------------------
# The plan, and the stages this run will run
#
# The plan is read at run time and this script does the work. A bundle holds a
# record of what happened, not a script to be edited and rerun: an emitted
# script is a snapshot of a plan, and the next run overwrites every hand edit
# made to it. The durable, editable copy is the plan itself, in the workspace.
# ---------------------------------------------------------------------------
PLAN_LIB="$REPO_ROOT/.internal/git/repo-plan.sh"
HYDRATE_LIB="$REPO_ROOT/.internal/git/repo-hydrate.sh"
for lib in "$PLAN_LIB" "$HYDRATE_LIB"; do
  if [[ ! -f "$lib" ]]; then
    echo "ERROR: required library not found: $lib" >&2
    exit 2
  fi
done
# shellcheck source=../.internal/git/repo-plan.sh
source "$PLAN_LIB"
# shellcheck source=../.internal/git/repo-hydrate.sh
source "$HYDRATE_LIB"

if ! repo_plan_load "${REPO_PLAN_SOURCE_DIR:-}"; then
  echo "ERROR: the clone plan did not load. Nothing was written." >&2
  exit 2
fi

plan_w=0
while [[ "$plan_w" -lt "${#REPO_PLAN_WARNINGS[@]}" ]]; do
  echo "WARNING: ${REPO_PLAN_WARNINGS[$plan_w]}" >&2
  plan_w=$((plan_w + 1))
done

# `clone` is a stage like any source, so "run only the cloner" and "run only one
# source" are one mechanism rather than two flags.
ALL_STAGES="clone"
stage_i=0
while [[ "$stage_i" -lt "${#REPO_SRC_TYPE[@]}" ]]; do
  ALL_STAGES="$ALL_STAGES ${REPO_SRC_TYPE[$stage_i]}"
  stage_i=$((stage_i + 1))
done
[[ -n "$STAGES" ]] || STAGES="$ALL_STAGES"

for stage_want in $STAGES; do
  stage_found=false
  for stage_have in $ALL_STAGES; do
    [[ "$stage_want" == "$stage_have" ]] && stage_found=true
  done
  if [[ "$stage_found" != true ]]; then
    echo "ERROR: unknown stage: $stage_want" >&2
    echo "Stages available from this plan: $ALL_STAGES" >&2
    exit 2
  fi
done

stage_selected() {
  local want="$1" have
  for have in $STAGES; do
    [[ "$want" == "$have" ]] && return 0
  done
  return 1
}

# Per-repository, per-stage outcomes. A file rather than arrays because both
# hydrated.md and the domain index read it back, and one of them counts.
HYDRATION_TSV="$RAW_DIR/hydration.tsv"
printf 'repo\tstage\toutcome\tdetail\n' > "$HYDRATION_TSV"

if [[ "$HYDRATE" == true && "$DRY_RUN" == true ]]; then
  HYDRATE_MODE_LABEL="hydrate --dry-run"
elif [[ "$HYDRATE" == true ]]; then
  HYDRATE_MODE_LABEL="hydrate"
elif [[ "$DRY_RUN" == true ]]; then
  HYDRATE_MODE_LABEL="report --dry-run"
else
  HYDRATE_MODE_LABEL="report"
fi

PLANNED_COUNT=0
EXCLUDED_COUNT=0
UNREVIEWED_COUNT=0
CLONED_COUNT=0
CONFLICT_COUNT=0

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

  # -----------------------------------------------------------------
  # Join the audit row against the plan
  #
  # The audit says what existed. The plan says what is wanted and where. A
  # repository in neither the selected nor the excluded fragment is UNREVIEWED:
  # reported every run, never cloned, never silently skipped. A default action
  # here is how a repository nobody decided about goes missing.
  # -----------------------------------------------------------------
  plan_idx=""
  plan_state="unreviewed"
  if plan_idx="$(repo_plan_index "$label" 2>/dev/null)"; then
    plan_state="planned"
  else
    plan_idx=""
    excl_i=0
    while [[ "$excl_i" -lt "${#REPO_EXCL_NAME[@]}" ]]; do
      if [[ "${REPO_EXCL_NAME[$excl_i]}" == "$label" ]]; then
        plan_state="excluded"
        break
      fi
      excl_i=$((excl_i + 1))
    done
  fi

  hydrate_url="$clone_url"
  hydrate_dest="$CLONE_DEST"
  if [[ -n "$plan_idx" ]]; then
    PLANNED_COUNT=$((PLANNED_COUNT + 1))
    [[ -n "${REPO_PLAN_URL[$plan_idx]}" ]]  && hydrate_url="${REPO_PLAN_URL[$plan_idx]}"
    [[ -n "${REPO_PLAN_PATH[$plan_idx]}" ]] && hydrate_dest="${REPO_PLAN_PATH[$plan_idx]}"
  elif [[ "$plan_state" == "excluded" ]]; then
    EXCLUDED_COUNT=$((EXCLUDED_COUNT + 1))
  else
    UNREVIEWED_COUNT=$((UNREVIEWED_COUNT + 1))
  fi

  # classify_repo asked whether the repository is present at the ROUTED
  # destination. When the plan names its own LOCAL_REPO_PATH that is a different
  # directory, and presence has to be asked where the repository is actually
  # going -- otherwise `Present on disk` reports on a path this run will never
  # touch, and the clone stage and the count disagree about the same repository.
  if [[ -n "$plan_idx" && "$hydrate_dest" != "$CLONE_DEST" ]]; then
    if [[ -d "$hydrate_dest/.git" ]]; then
      PATH_PRESENT="yes"
    else
      PATH_PRESENT="no"
    fi
  fi

  head_sha="${head_line%% *}"
  case "$head_sha" in
    ''|*[!0-9a-fA-F]*) head_sha="" ;;
  esac

  if [[ "$PATH_PRESENT" == "yes" ]]; then
    PRESENT_COUNT=$((PRESENT_COUNT + 1))
  else
    NEEDS_CLONE_COUNT=$((NEEDS_CLONE_COUNT + 1))
  fi
  if [[ "$IGN_AVAILABLE" == "yes" ]]; then
    IGN_AVAILABLE_COUNT=$((IGN_AVAILABLE_COUNT + 1))
  fi
  if [[ "$(numeric_or_zero "$CARRY_FORWARD_ROWS")" -gt 0 ]]; then
    CARRY_FORWARD_TOTAL=$((CARRY_FORWARD_TOTAL + CARRY_FORWARD_ROWS))
  fi

  # Only a planned repository is acted on. Excluded and unreviewed ones are
  # recorded with the reason and left alone.
  if [[ "$plan_state" != "planned" ]]; then
    if [[ "$plan_state" == "excluded" ]]; then
      hyd_detail="excluded: ${REPO_EXCL_REASON[$excl_i]}"
    else
      hyd_detail="in the audit but in neither plan fragment -- select it or exclude it with a reason"
    fi
    printf '%s\t%s\t%s\t%s\n' "$label" "plan" "$plan_state" "$hyd_detail" >> "$HYDRATION_TSV"
  else
    # A clone-stage conflict quarantines the repository for the rest of the run.
    # The working tree on disk is not the one the plan describes, and a source
    # merged into it would be written into a repository nobody declared. The
    # clone stage refuses to touch it; the source stages have to refuse for the
    # same reason, or the refusal is only half kept.
    repo_conflicted=false
    if stage_selected clone; then
      if [[ "$HYDRATE" == true ]]; then
        repo_hydrate_clone "$label" "$hydrate_url" "$hydrate_dest" \
          "$branch" "$head_sha" "$remotes" "$DRY_RUN"
      else
        # No --hydrate: report the state without acting, using the same
        # resolution the acting path would use.
        repo_hydrate_clone "$label" "$hydrate_url" "$hydrate_dest" \
          "$branch" "$head_sha" "$remotes" "true"
        case "$HYDRATE_OUTCOME" in
          would-clone) HYDRATE_OUTCOME="needs-clone"; HYDRATE_DETAIL="absent at $hydrate_dest" ;;
        esac
      fi
      case "$HYDRATE_OUTCOME" in
        cloned)   CLONED_COUNT=$((CLONED_COUNT + 1)) ;;
        conflict) CONFLICT_COUNT=$((CONFLICT_COUNT + 1)); repo_conflicted=true ;;
      esac
      printf '%s\t%s\t%s\t%s\n' "$label" "clone" "$HYDRATE_OUTCOME" "$HYDRATE_DETAIL" >> "$HYDRATION_TSV"
    fi

    src_i=0
    while [[ "$src_i" -lt "${#REPO_SRC_TYPE[@]}" ]]; do
      if stage_selected "${REPO_SRC_TYPE[$src_i]}"; then
        if [[ "$repo_conflicted" == true ]]; then
          HYDRATE_OUTCOME="skipped"
          HYDRATE_DETAIL="the clone stage reported a conflict; nothing is merged into a tree the plan does not describe"
        elif [[ "$HYDRATE" == true ]]; then
          repo_hydrate_source "$label" "$src_i" "$hydrate_dest" "$repo_path" "$DRY_RUN"
        else
          repo_hydrate_source "$label" "$src_i" "$hydrate_dest" "$repo_path" "true"
        fi
        printf '%s\t%s\t%s\t%s\n' \
          "$label" "${REPO_SRC_TYPE[$src_i]}" "$HYDRATE_OUTCOME" "$HYDRATE_DETAIL" >> "$HYDRATION_TSV"
        [[ "$HYDRATE_OUTCOME" == "applied" ]] && IGN_APPLIED_COUNT=$((IGN_APPLIED_COUNT + 1))
      fi
      src_i=$((src_i + 1))
    done
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$repo_path" "$label" "$PATH_PRESENT" "$remote_url" \
    "$CLONE_HOST" "$CLONE_TARGET_ROOT" \
    "$IGN_AVAILABLE" "$IGN_APPLIED" "$CARRY_FORWARD_ROWS" >> "$STATUS_TSV"

  # Proposal rows, collected here because this is where routing is already
  # decided. A repository with no remote cannot be cloned by anything, so it is
  # proposed commented-out with the reason rather than as a live entry — the
  # decision is the operator's, and a silent live entry would pre-empt it.
  if [[ "$EMIT_PLAN" == true ]]; then
    remote_name="$(extract_remote_name "$remotes")"
    if [[ -n "$remote_url" ]]; then
      {
        printf 'repo_plan_add \\\n'
        printf '  REPO_NAME=%s \\\n' "$label"
        printf '  REMOTE_NAME=%s \\\n' "${remote_name:-origin}"
        printf '  REMOTE_FETCH_URL=%s \\\n' "$remote_url"
        printf '  LOCAL_REPO_PATH="%s"\n\n' "$CLONE_DEST"
      } >> "$PROPOSED_SELECTED"
    else
      {
        printf '# %s -- no remote recorded in the pre-image audit.\n' "$label"
        printf '# Nothing can clone it. Recover it from a backup and adopt it here, or\n'
        printf '# move it to repo-candidates-excluded.conf.sh with a reason.\n'
        printf '# repo_plan_add REPO_NAME=%s LOCAL_REPO_PATH="%s"\n\n' "$label" "$CLONE_DEST"
      } >> "$PROPOSED_SELECTED"
      printf '# repo_plan_exclude REPO_NAME=%s REASON="no remote recorded; only copy is the backup"\n' \
        "$label" >> "$PROPOSED_EXCLUDED"
    fi
  fi

done < "$REPOS_TSV"

# ---------------------------------------------------------------------------
# Write the proposal
#
# Four files mirroring the four fragments, so a reviewer can diff a proposal
# against their own copy file by file rather than reading a single blob.
# ---------------------------------------------------------------------------
emit_plan_proposal() {
  local sel="$PROPOSED_DIR/repo-candidates-selected.proposed.conf.sh"
  local exc="$PROPOSED_DIR/repo-candidates-excluded.proposed.conf.sh"
  local src="$PROPOSED_DIR/repo-rehydration-sources.proposed.conf.sh"
  local map="$PROPOSED_DIR/repo-rehydration-map.proposed.conf.sh"
  local banner projects_root ij_readme

  banner="# PROPOSED -- generated by restore-repos.sh on $REPORT_GENERATED
# Source pre-image audit run: $INPUT_RUN
#
# This is a proposal, not the plan. The plan is
#   \$REIMAGE_WORKSPACE_ROOT/repo-plan/
# and no run ever writes there. Review this, copy across what you agree with,
# and edit the rest -- the point of the plan is the decisions it records, and a
# generated file has made none of them."

  {
    printf '%s\n#\n' "$banner"
    printf '# One entry per repository the audit inventoried, routed the way this run\n'
    printf '# routed it: LOCAL_REPO_PATH is the destination that routing produced, not a\n'
    printf '# preference. Change it where a repository belongs somewhere else.\n\n'
    cat "$PROPOSED_SELECTED"
  } > "$sel"

  {
    printf '%s\n#\n' "$banner"
    printf '# Nothing is proposed for exclusion outright -- leaving a repository out is a\n'
    printf '# decision, and this file is where the reason lives.\n'
    printf '#\n# The entries below are the repositories the audit recorded with NO REMOTE.\n'
    printf '# They are commented out because "cannot be cloned" and "should not be\n'
    printf '# restored" are different findings, and only you can turn one into the other.\n\n'
    if [[ -s "$PROPOSED_EXCLUDED" ]]; then
      cat "$PROPOSED_EXCLUDED"
    else
      printf '# (every repository in this audit has a remote)\n'
    fi
  } > "$exc"

  # Sources are proposed only where the root is actually on this artifact root,
  # so a proposal cannot invent a source that has nothing behind it.
  ij_readme="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/README.md"
  projects_root=""
  if [[ -f "$ij_readme" ]]; then
    projects_root="$(awk '/Projects root scanned/{f=1;next} f&&/^\//{print;exit}' "$ij_readme" 2>/dev/null || true)"
  fi

  {
    printf '%s\n\n' "$banner"
    if [[ -d "$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live" ]]; then
      printf 'repo_source_add \\\n  ARTIFACT_TYPE=ignored-files \\\n'
      printf '  ARTIFACT_ROOT="$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live" \\\n'
      printf '  KEYED_BY=repo-name \\\n  REQUIRES=artifact-root \\\n  MODE=merge \\\n'
      printf '  DESCRIPTION="Reviewed kept ignored files from the backup phase"\n\n'
    fi
    if [[ -d "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/project-metadata" ]]; then
      if [[ -n "$projects_root" ]]; then
        printf 'repo_source_add \\\n  ARTIFACT_TYPE=project-metadata \\\n'
        printf '  ARTIFACT_ROOT="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/project-metadata" \\\n'
        printf '  KEYED_BY=pre-image-path \\\n  PATH_ROOT=%s \\\n' "$projects_root"
        printf '  REQUIRES=artifact-root \\\n  MODE=merge \\\n'
        printf '  DESCRIPTION="Per-project IDE metadata, keyed by path under the projects root"\n\n'
      else
        printf '# project-metadata is present but the projects root it was captured from\n'
        printf '# could not be read from app-settings-backup/intellij/README.md.\n'
        printf '# KEYED_BY=pre-image-path needs it: the key is each audit path with that\n'
        printf '# prefix removed. Fill PATH_ROOT in and uncomment.\n'
        printf '# repo_source_add ARTIFACT_TYPE=project-metadata \\\n'
        printf '#   ARTIFACT_ROOT="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/project-metadata" \\\n'
        printf '#   KEYED_BY=pre-image-path PATH_ROOT=<projects root> \\\n'
        printf '#   REQUIRES=artifact-root MODE=merge\n\n'
      fi
    fi
    printf '# Sources inside the encrypted image cannot be probed from here -- it is not\n'
    printf '# attached. ARTIFACT_ROOT is single-quoted so $DMG_MOUNT stays literal and is\n'
    printf '# substituted when the image is mounted.\n'
    printf 'repo_source_add \\\n  ARTIFACT_TYPE=repo-secrets \\\n'
    printf "  ARTIFACT_ROOT='\$DMG_MOUNT/repos-gitignored' \\\\\n"
    printf '  KEYED_BY=repo-name \\\n  REQUIRES=dmg \\\n  MODE=merge \\\n'
    printf '  DESCRIPTION="Gitignored secret-shaped files from the secrets image"\n\n'
    printf '# Proposed as MODE=report: its layout has not been inspected, and a source\n'
    printf '# that merges an unknown shape into a working tree is worse than one that\n'
    printf '# lists what it found.\n'
    printf 'repo_source_add \\\n  ARTIFACT_TYPE=intellij-secrets \\\n'
    printf "  ARTIFACT_ROOT='\$DMG_MOUNT/intellij' \\\\\n"
    printf '  KEYED_BY=declared \\\n  REQUIRES=dmg \\\n  MODE=report \\\n'
    printf '  DESCRIPTION="IntelliJ HTTP Client environment files from the secrets image"\n'
  } > "$src"

  {
    printf '%s\n#\n' "$banner"
    printf '# Empty on purpose. Keys are derived: a repo-name source finds its bundle by\n'
    printf '# REPO_NAME, and a pre-image-path source by the audit path minus PATH_ROOT.\n'
    printf '# Add an entry only where the derivation is wrong -- a bundle belonging to a\n'
    printf '# grouping project rather than one repository, a repository whose path moved\n'
    printf '# since the audit, or a source with no derivation at all.\n'
  } > "$map"

  rm -f "$PROPOSED_SELECTED" "$PROPOSED_EXCLUDED"
}

if [[ "$EMIT_PLAN" == true ]]; then
  emit_plan_proposal
fi

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
elif [[ "$HYDRATE" == true && "$IGN_APPLIED_COUNT" -ge "$IGN_AVAILABLE_COUNT" ]]; then
  IGNORED_FILES_COMPLETE="true"
fi

# ---------------------------------------------------------------------------
# Generate the Markdown report
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Report cells, computed BEFORE the here-document
#
# Nothing below may contain a command substitution once it reaches the
# here-document. A nested `$( ... $( ... ) ... )` inside an unquoted heredoc is
# the one construct that separates this script's report from its command files,
# and all three post-image-restore runs on the artifact volume have a 0-byte
# `restore-status.md` beside three complete command files. Bash 3.2's
# here-document parser handles nested substitution poorly, and under `set -u`
# an expansion error in a non-interactive shell is fatal: the redirect creates
# and truncates the file, the expansion dies, and nothing after it runs. That is
# exactly the state on disk.
#
# `bash -n` cannot see it and the portability lint cannot see it -- its rules are
# per-line regexes and this one needs heredoc context. So the rule is structural:
# compute the cell, then interpolate the variable.
# ---------------------------------------------------------------------------
REPORT_GENERATED="${REPORT_GENERATED:-$(date)}"
REPORT_SCRIPT="$(basename "$0")"
# A default-located run is composed in a staging directory and promoted after
# the report is written, so every path the report quotes is the promoted one --
# a reader who copies a path out of the report must get one that exists.
if [[ "$OUTPUT_DIR_DEFAULTED" == true ]]; then
  REPORT_OUT="$ARTIFACT_RUN_FINAL_DIR"
else
  REPORT_OUT="$OUT"
fi
# A dry run opens no sign-off, so the report says so rather than printing the
# blank line an unset path would leave behind.
if [[ "$DRY_RUN" == true ]]; then
  SIGNOFF_LOCATION="(none — --dry-run opens no sign-off)"
else
  SIGNOFF_LOCATION="$SIGNOFF_FILE"
fi

if [[ "$DUPLICATE_LABEL_COUNT" -eq 0 ]]; then
  DUP_STATUS="PASS"
  DUP_NOTE="Bundle labels are unique."
else
  DUP_STATUS="WARN"
  # Deliberately unquoted: the guard's value is a newline-separated list and the
  # note wants it space-separated on one line.
  # shellcheck disable=SC2086
  DUP_NOTE="Shared bundle label(s): $(printf '%s ' $DUPLICATE_LABELS). Reconcile by hand before running the rsync commands."
fi

REPOS_INDEX_STATUS="$(status_pass_warn "$REPOS_INDEX_OK")"
CLONES_STATUS="$(status_pass_warn "$CLONES_COMPLETE")"
IGNORED_STATUS="$(status_pass_warn "$IGNORED_FILES_COMPLETE")"

cat > "$REPORT_MD" <<EOF
# Restore Repositories Status Report

Generated: $REPORT_GENERATED
Script: $REPORT_SCRIPT
Output directory: $REPORT_OUT
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
| No duplicate repo basenames | Command | \`cut -f1 repos.tsv | xargs -n1 basename | sort | uniq -d\` is empty | $DUP_STATUS | $DUP_NOTE |
| Pre-image repo inventory read successfully | Command | \`repos.tsv\` produced status rows | $REPOS_INDEX_STATUS | See \`raw/repos-input.tsv\`. |
| Every tracked repo is present on disk | Command | \`Present\` in the per-repo table below is \`yes\` for every row | $CLONES_STATUS | Run \`--hydrate\` to clone what the plan selected, then rerun to confirm. |
| Every staged ignored bundle applied | Command | \`hydrated.md\` records an outcome for every repository with a bundle available | $IGNORED_STATUS | Run \`--hydrate --stage ignored-files\`. |

## Manual Sign-Off

The rows a person answers are not in this report. Each run writes a new run
directory, so an answer recorded here would not reach the next one. They live in
the sign-off, which carries answers forward and records the run each was
answered against:

    $SIGNOFF_LOCATION

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

## What This Run Did

Cloning and rehydration are this script's own work, driven by the clone plan in
\`$REPO_PLAN_SOURCE_DIR\`. The record is \`hydrated.md\` beside this file: one
row per repository per stage, naming the stages this run was not asked to run.

\`\`\`bash
cat "$REPORT_OUT/hydrated.md"
\`\`\`

## Manual Follow-Up

1. Resolve every \`conflict\` row in \`hydrated.md\` by hand. A conflict means the
   working tree on disk disagrees with the plan; nothing was written to it.
2. Select or exclude every \`unreviewed\` repository in the plan, then rerun —
   an unreviewed repository is in the audit and in neither fragment, so it was
   not cloned.
3. For each repo with \`carry-forward rows > 0\`, run
   \`git ls-remote origin 'reimage/*'\` inside the clone to confirm the
   pre-image rescue branch is present, then merge or cherry-pick back into
   the intended branch.
4. Confirm each clone sits under the root matching its remote host — the root is
   what \`includeIf\` uses to decide which identity authors a commit, so a
   misplaced clone commits under the wrong address and offers the wrong key.
   Rows whose \`Clone host\` and root disagree are the ones to check first.
5. Rerun this script after cloning to update the exit-criteria table.

## Raw Evidence Files

- \`raw/status.tsv\` — per-repo status table
- \`raw/repos-input.tsv\` — copy of the pre-image \`repos.tsv\` for provenance
- \`raw/local-only-commits-input.tsv\` — pre-image carry-forward checklist rows
- \`raw/stashes-input.tsv\` — pre-image stash rows
- \`raw/tracked-changes-input.tsv\` — pre-image tracked change rows
- \`raw/hydration.tsv\` — one row per repository per stage, read back by \`hydrated.md\`
EOF

# Index this run in the shared category manifest. `post-image-restore` is its own
# lineage, so `official/post-image-restore.txt` advances without disturbing
# `official/pre-image.txt` -- the two questions no longer share one pointer.
#
# Only for a default-located run: an --output run lives outside runs/, and the
# index resolves relative to repo-audit-reports/, so indexing it would leave a
# pointer naming a path that is not there.
if [[ "$OUTPUT_DIR_DEFAULTED" == true ]]; then
  if ! artifact_run_finalize "$AUDIT_ROOT" \
       "$PRESENT_COUNT present / $NEEDS_CLONE_COUNT need clone / $CARRY_FORWARD_TOTAL carry-forward"; then
    echo "ERROR: the report was written but could not be indexed." >&2
    exit 2
  fi
  # Promoted: the staging path this script wrote into is now the run directory.
  OUT="$AUDIT_ROOT/$ARTIFACT_RUN_RELATIVE"
  REPORT_MD="$OUT/restore-status.md"
  # Everything still to be written or read has to follow the run to its promoted
  # path. hydrated.md is composed after this point and reads hydration.tsv back;
  # left pointing at the staging directory it produced a report with an empty
  # table and no error, which is the failure mode this phase keeps meeting.
  RAW_DIR="$OUT/raw"
  HYDRATION_TSV="$RAW_DIR/hydration.tsv"
elif [[ "$DRY_RUN" != true ]]; then
  echo "NOTE: --output was used; the run was not indexed under $AUDIT_ROOT." >&2
fi

if [[ "$DRY_RUN" != true ]]; then
signoff_row "Rescue branches (\`reimage/YYYYMMDD/*\`) present on remote for every carry-forward row" "The pre-image audit recorded $CARRY_FORWARD_TOTAL carry-forward rows across $TOTAL repos; each must map to a pushed rescue branch or be intentionally discarded. Verify with \`git ls-remote origin 'reimage/*'\` per repo."
signoff_row "Every clone sits under the root matching its SSH routing host" "Fill after cloning. The root decides identity through \`includeIf\`, so a repository under the wrong one commits with the wrong address and offers the wrong key. Verify with \`git -C <repo> remote get-url origin\` against the root it sits in, and against the routing hosts \`restore-git\` wrote into \`~/.ssh/config\`. Transport is a separate question and not this row's: this run restores the transport the pre-image audit recorded, and a URL is rewritten onto \`GIT_PERSONAL_GITHUB_HOST\` only when that routing host is an alias — a name other than \`github.com\` — and the URL is already \`git@github.com:\`."
fi
# ---------------------------------------------------------------------------
# hydrated.md -- what this run did
#
# Written on every run, including one that hydrated nothing. "Nothing happened"
# and "nothing needed to happen" are different answers, and a file that appears
# only when work was done cannot tell them apart. The stages this run was not
# asked to run are named for the same reason: a partial run should read as
# partial rather than as a run that found nothing to do.
# ---------------------------------------------------------------------------
HYDRATED_MD="$OUT/hydrated.md"
{
  printf '# Repositories Hydrated\n\n'
  printf 'Generated: %s\n' "$REPORT_GENERATED"
  printf 'Source pre-image audit run: %s\n' "$INPUT_RUN"
  printf 'Clone plan: %s\n' "${REPO_PLAN_SOURCE_DIR:-<unresolved>}"
  printf 'Mode: %s\n\n' "$HYDRATE_MODE_LABEL"
  printf 'Stages run: %s\n' "$STAGES"
  if [[ "$STAGES" != "$ALL_STAGES" ]]; then
    printf 'Stages NOT run this time: ' 
    for stage_have in $ALL_STAGES; do
      stage_selected "$stage_have" || printf '%s ' "$stage_have"
    done
    printf '\n'
  fi
  printf '\n## Summary\n\n| | Count |\n|---|---:|\n'
  printf '| Repositories in the audit | %s |\n' "$TOTAL"
  printf '| Planned | %s |\n' "$PLANNED_COUNT"
  printf '| Excluded, with a reason | %s |\n' "$EXCLUDED_COUNT"
  printf '| **Unreviewed** | **%s** |\n' "$UNREVIEWED_COUNT"
  printf '| Cloned this run | %s |\n' "$CLONED_COUNT"
  printf '| Already present | %s |\n' "$PRESENT_COUNT"
  printf '| **Conflicts, untouched** | **%s** |\n' "$CONFLICT_COUNT"
  printf '\n## Per repository\n\n| Repository | Stage | Outcome | Detail |\n|---|---|---|---|\n'
  tail -n +2 "$HYDRATION_TSV" | while IFS=$'\t' read -r h_repo h_stage h_out h_detail; do
    printf '| %s | %s | `%s` | %s |\n' "$h_repo" "$h_stage" "$h_out" "$h_detail"
  done
} > "$HYDRATED_MD"

# ---------------------------------------------------------------------------
# MANIFEST.txt -- what is in this bundle
#
# Written last, and the file list is read off the bundle rather than declared:
# four of the inputs are copied only when the pre-image run carried them, and
# hydrated.md is composed after promotion. A declared list names files that are
# not there, and a manifest that misdescribes its own bundle is worse than none.
# ---------------------------------------------------------------------------
{
  printf '# Restore Repositories Status Manifest\n'
  printf 'Generated: %s\n' "$REPORT_GENERATED"
  printf 'Script: %s\n' "$REPORT_SCRIPT"
  printf 'Output directory: %s\n' "$REPORT_OUT"
  printf 'Source pre-image audit run: %s\n\n' "$INPUT_RUN"
  printf 'Files:\n'
  # find, not a glob: raw/ is a level down, and MANIFEST.txt does not list
  # itself. Sorted so two runs of the same shape produce the same manifest.
  find "$OUT" -type f ! -name 'MANIFEST.txt' | sed "s|^$OUT/|- |" | LC_ALL=C sort
} > "$OUT/MANIFEST.txt"

# ---------------------------------------------------------------------------
# repo-restore-index.md -- the domain index
#
# One row per run, beside MANIFEST.md and repo-audit-index.md. The shared
# manifest schema has no columns for these counts, and Revision 141 settled what
# to do about that: a domain index beside the manifest rather than a widened one.
# Its value is across runs -- a phase walked over several sittings needs "am I
# getting closer" answered without opening each bundle in turn.
# ---------------------------------------------------------------------------
if [[ "$OUTPUT_DIR_DEFAULTED" == true && "$DRY_RUN" != true ]]; then
  RESTORE_INDEX="$AUDIT_ROOT/repo-restore-index.md"
  if [[ ! -e "$RESTORE_INDEX" ]]; then
    {
      printf '# Repository Restore Index\n\n'
      printf 'Append-only, and specific to this category: the per-run restore counts the\n'
      printf 'shared seven-column `MANIFEST.md` has no room for. `MANIFEST.md` is the\n'
      printf 'authority on which runs exist and which is official; this file exists so\n'
      printf 'progress across sittings stays scannable rather than buried in each bundle.\n\n'
      printf '| Completed | Run | Mode | Planned | Cloned | Present | Conflict | Unreviewed | Stages |\n'
      printf '|---|---|---|---:|---:|---:|---:|---:|---|\n'
    } > "$RESTORE_INDEX"
  fi
  if grep -q '^# Repository Restore Index$' "$RESTORE_INDEX" 2>/dev/null; then
    printf '| %s | `%s` | %s | %d | %d | %d | %d | %d | %s |\n' \
      "$(date '+%Y-%m-%d %H:%M:%S')" "post-image-restore-$STAMP" "$HYDRATE_MODE_LABEL" \
      "$PLANNED_COUNT" "$CLONED_COUNT" "$PRESENT_COUNT" "$CONFLICT_COUNT" "$UNREVIEWED_COUNT" \
      "$STAGES" >> "$RESTORE_INDEX"
  else
    echo "WARNING: $RESTORE_INDEX is not a restore index; leaving it alone." >&2
  fi
fi

if [[ "$DRY_RUN" != true ]]; then
  signoff_finalize "Phase 11B" "$REPORT_MD"
fi

echo ""
echo "Restore repositories report complete."
echo "  Total repos in inventory: $TOTAL"
echo "  Present on disk:          $PRESENT_COUNT"
echo "  Needs clone:              $NEEDS_CLONE_COUNT"
echo "  Planned / excluded / unreviewed: $PLANNED_COUNT / $EXCLUDED_COUNT / $UNREVIEWED_COUNT"
echo "  Cloned this run:          $CLONED_COUNT"
echo "  Conflicts (untouched):    $CONFLICT_COUNT"
echo "  Carry-forward rows total: $CARRY_FORWARD_TOTAL"
echo "  Mode:                     $HYDRATE_MODE_LABEL"
echo "  Stages:                   $STAGES"
if [[ "$UNREVIEWED_COUNT" -gt 0 ]]; then
  echo ""
  echo "  $UNREVIEWED_COUNT repository/repositories are in the audit and in neither plan fragment."
  echo "  They were not cloned. Select them, or exclude them with a reason:"
  echo "    ${REPO_PLAN_SOURCE_DIR:-<unresolved>}"
fi
echo ""
if [[ "$DRY_RUN" == true ]]; then
  echo "----- restore-status.md -----"
  cat "$REPORT_MD"
  echo ""
  echo "----- hydrated.md -----"
  cat "$HYDRATED_MD"
  echo ""
  echo "(--dry-run: nothing written)"
else
  echo "Report → $REPORT_MD"
  echo "What happened → $HYDRATED_MD"
fi

if [[ "$OPEN_RESULT" == "true" ]]; then
  # Never let a Finder reveal decide the run's exit status: over SSH, or on a
  # host without `open`, a correctly written report would otherwise exit nonzero.
  open -R "$REPORT_MD" 2>/dev/null || true
fi
