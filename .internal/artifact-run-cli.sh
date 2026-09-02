#!/usr/bin/env bash
# =============================================================================
# artifact-run-cli.sh
#
# Command-line access to the shared run index for producers that are not Bash.
#
# `.internal/artifact-runs.sh` is a sourced library: `artifact_run_begin` sets
# shell variables in the caller, which a command substitution or another
# language cannot receive. A Python producer that wants an indexed run therefore
# has two options -- reimplement the point rules, the manifest format and the
# pointer computation in its own language, or call this. The second keeps one
# implementation of the rules, which is the entire value of the library.
#
# CLASSIFICATION: `.internal/` helper. Parameter-driven and safe to run
# standalone. Not a loader: it is executed, never sourced.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#
#   # Stage a run. Prints the staging directory to write into.
#   ./.internal/artifact-run-cli.sh begin \
#     --category /path/to/category --context pre-image-backup-home-external
#
#   # Promote and index it once the files are written.
#   ./.internal/artifact-run-cli.sh finalize \
#     --category /path/to/category --run-dir /path/printed/by/begin \
#     --result "47 scanned / 0 with findings"
#
#   # Discard it instead, leaving nothing indexed.
#   ./.internal/artifact-run-cli.sh abort --run-dir /path/printed/by/begin
#
#   # Read the current official run of a context. Prints runs/<id>.
#   ./.internal/artifact-run-cli.sh official \
#     --category /path/to/category --context pre-image-backup-home-external
#
# Commands:
#   begin     Stage a run and print its staging directory.
#   finalize  Promote a staged run, append its manifest row, refresh official/.
#   abort     Delete a staged run. Nothing is indexed.
#   official  Print the relative path of a context's official run.
#
# Options:
#   --category PATH  Category root holding runs/, official/ and MANIFEST.md.
#                    Required for begin, finalize and official.
#   --context NAME   Run context, <phase>-<what>-<point>. Required for begin
#                    and official.
#   --run-dir PATH   Staging directory as printed by begin. Required for
#                    finalize and abort.
#   --result TEXT    Short outcome recorded in the manifest Result column.
#   --note TEXT      Free text recorded in the manifest Note column.
#   -h, --help       Show this message and exit.
#
# Exit status:
#   0  Command completed.
#   1  Runtime failure (could not promote, no official run, and so on).
#   2  Usage error.
# --- END USAGE ---
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

# shellcheck source=/dev/null
. "$SCRIPT_DIR/artifact-runs.sh" || {
  echo "ERROR: cannot load $SCRIPT_DIR/artifact-runs.sh" >&2
  exit 2
}

require_value() {
  if [ -z "${2:-}" ] || case "${2:-}" in --*) true ;; *) false ;; esac; then
    echo "ERROR: $1 requires a non-empty value." >&2
    exit 2
  fi
}

COMMAND="${1:-}"
case "$COMMAND" in
  begin|finalize|abort|official) shift ;;
  -h|--help) usage; exit 0 ;;
  "") echo "ERROR: a command is required." >&2; usage >&2; exit 2 ;;
  *) echo "ERROR: unknown command: $COMMAND" >&2; usage >&2; exit 2 ;;
esac

CATEGORY=""; CONTEXT=""; RUN_DIR=""; RESULT=""; NOTE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --category) require_value "$1" "${2:-}"; CATEGORY="$2"; shift 2 ;;
    --context)  require_value "$1" "${2:-}"; CONTEXT="$2";  shift 2 ;;
    --run-dir)  require_value "$1" "${2:-}"; RUN_DIR="$2";  shift 2 ;;
    --result)   require_value "$1" "${2:-}"; RESULT="$2";   shift 2 ;;
    --note)     require_value "$1" "${2:-}"; NOTE="$2";     shift 2 ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$COMMAND" in
  begin)
    [ -n "$CATEGORY" ] && [ -n "$CONTEXT" ] || {
      echo "ERROR: begin requires --category and --context." >&2; exit 2; }
    artifact_run_begin "$CATEGORY" "$CONTEXT" || exit $?
    printf '%s\n' "$ARTIFACT_RUN_DIR"
    ;;

  # The library keeps a staged run in shell variables, so a separate invocation
  # has to rebuild them. Everything needed is in the staging directory's own
  # name -- `.<context>-<stamp>.incomplete` -- which is why finalize takes the
  # path begin printed rather than a run id.
  finalize)
    [ -n "$CATEGORY" ] && [ -n "$RUN_DIR" ] || {
      echo "ERROR: finalize requires --category and --run-dir." >&2; exit 2; }
    [ -d "$RUN_DIR" ] || {
      echo "ERROR: not a staged run directory: $RUN_DIR" >&2; exit 1; }
    _base="$(basename "$RUN_DIR")"
    case "$_base" in
      .*.incomplete) ;;
      *) echo "ERROR: not a staging directory name: $_base" >&2; exit 2 ;;
    esac
    ARTIFACT_RUN_ID="${_base#.}"; ARTIFACT_RUN_ID="${ARTIFACT_RUN_ID%.incomplete}"
    ARTIFACT_RUN_CONTEXT="${ARTIFACT_RUN_ID%-*-*}"
    ARTIFACT_RUN_STAMP="${ARTIFACT_RUN_ID#"$ARTIFACT_RUN_CONTEXT"-}"
    ARTIFACT_RUN_POINT="$(_artifact_runs_point_of "$ARTIFACT_RUN_CONTEXT")"
    ARTIFACT_RUN_RELATIVE="runs/$ARTIFACT_RUN_ID"
    ARTIFACT_RUN_CATEGORY_ROOT="$CATEGORY"
    ARTIFACT_RUN_DIR="$RUN_DIR"
    ARTIFACT_RUN_FINAL_DIR="$CATEGORY/$ARTIFACT_RUN_RELATIVE"
    artifact_run_finalize "$CATEGORY" "$RESULT" "$NOTE" || exit $?
    printf '%s\n' "$ARTIFACT_RUN_RELATIVE"
    ;;

  abort)
    [ -n "$RUN_DIR" ] || { echo "ERROR: abort requires --run-dir." >&2; exit 2; }
    ARTIFACT_RUN_DIR="$RUN_DIR"
    artifact_run_abort
    ;;

  official)
    [ -n "$CATEGORY" ] && [ -n "$CONTEXT" ] || {
      echo "ERROR: official requires --category and --context." >&2; exit 2; }
    artifact_run_official "$CATEGORY" "$CONTEXT" || exit $?
    ;;
esac
