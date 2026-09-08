#!/usr/bin/env bash
# =============================================================================
# verify-session-findings.sh
#
# One callsite for the session-management framework's own checks. Names a
# subcommand, resolves it to a script, runs it from the repository root, and
# prints one summary.
#
# Why it exists: the framework's checks are separate scripts with different
# option sets and different exit conventions, and a session is expected to run
# every one of them before handing over a patch. Three invocations that must
# each be spelled correctly is three chances to skip one silently -- and a
# skipped check looks exactly like a passing one in a handover note.
#
# SCOPE. This dispatches the checks that are ABOUT the session-management
# framework: the findings bundles, the session bundles, and the revision
# ledger. It deliberately does NOT dispatch verify-doc-paths.sh,
# verify-runbook-structure.sh or verify-script-portability.sh. Those are
# cross-cutting toolkit utilities -- .github/guides/script-types-and-locations.md
# names two of them as such -- and they belong to the reimage workflow, which
# is what this framework is being separated FROM. A session still runs them
# before handing over a patch; it just runs them by name.
#
# It also fixes a real dependency. verify-findings-structure.sh tests `-d docs`
# and therefore only works when the current directory IS the repository root.
# Run from anywhere else it exits 2, which reads as a broken repository rather
# than a wrong working directory. This dispatcher cds to the root first, so
# every check runs the same way from anywhere.
#
# CLASSIFICATION: `bin/` entrypoint, cross-cutting utility -- the third
# population in .github/guides/script-types-and-locations.md -> Reading `bin/`.
# No runbook calls it. It enforces repository conventions rather than
# performing a workflow step, which is the same shape as verify-doc-paths.sh
# and verify-script-portability.sh.
#
# WHERE THE CHECKS LIVE. The path column below is the only place any of them
# is spelled, so this is where the reasoning belongs.
#
# Three sit under .internal/ai-scripts/session-management/ and one under
# .share/. They are the session-management framework and nothing else: with
# comments stripped, the only paths their operative code names are
# docs/*-findings/, docs/sessions/ and APPLY-MANIFEST.md. No
# REIMAGE_ARTIFACT_ROOT, no reimage.env, no runbook. They are the set that
# travels to another project, and this dispatcher travels with them.
#
# check-manifest-revision.sh sits in .share/ rather than beside the other three
# because the revision ledger is not specific to findings at all: any repository
# that numbers its changes wants it, session management or not. .share/ is where
# the guide puts a genuinely cross-repo script, and this is the first one to
# earn the directory.
#
# Moving a user-runnable validator under `.internal/` would normally contradict
# that directory's rule -- sourced-only helpers, not run directly. It does not
# here, and this dispatcher is the reason: once there is one callsite, those
# four stop being user-facing and become the implementation behind it. That is
# the guide's graduation rule read in the other direction, and it is the whole
# argument for the move. If this script goes away, they graduate back.
#
# THE ONE LIST. check_table() below is the single point of truth. The usage
# text, the unknown-subcommand error, the `list` subcommand, the group
# expansions and the dispatch all read it. A second literal anywhere would
# advertise a different set than the dispatcher accepts, which is the failure
# record-restore-prereqs.sh documents at SUPPORTED_RUNBOOKS.
#
# --- BEGIN USAGE ---
# Usage:
#   ./bin/verify-session-findings.sh [subcommand] [options...]
#
#   # Every check. This is the one to run before handing over a patch.
#   ./bin/verify-session-findings.sh
#   ./bin/verify-session-findings.sh all
#
#   # One check, with its own options forwarded to it verbatim.
#   ./bin/verify-session-findings.sh headers --verbose
#   ./bin/verify-session-findings.sh structure --verbose
#
#   # The revision ledger. Reports rather than verifies, so `all` skips it.
#   ./bin/verify-session-findings.sh manifest-revision
#   ./bin/verify-session-findings.sh manifest-revision --current
#
#   # What each subcommand resolves to, and whether it is there.
#   ./bin/verify-session-findings.sh list
#
# Subcommands:
#   all                Every check in the `verify` group. The default.
#
#   counts             Does every displayed finding count agree with its source?
#   headers            Does every findings-bundle header conform to the schema?
#   structure          Is every table well formed and every tag agreeing with its row?
#   completeness       Does metadata.json carry everything its markdown holds?
#                      The other three ask whether a document is WELL FORMED.
#                      This is the only one that asks whether it is COMPLETE --
#                      162 contaminated fields and 39 lost `Read:` bullets sat
#                      in 47 files while all three reported 0 FAIL, correctly.
#
#   manifest-revision  The next free APPLY-MANIFEST.md revision. Reports a
#                      number rather than a verdict, so it is not in `all`:
#                      folding a report into a pass/fail run would make the
#                      run's exit status mean two things.
#
#   list               Print the table and exit, running nothing.
#   -h, --help         Show this message and exit.
#
# Options:
#   Anything after a single subcommand is forwarded to that script unchanged.
#   Run `./bin/verify-session-findings.sh <subcommand> --help` for its options.
#
#   `all` takes no options and refuses them rather than dropping them. The
#   checks do not share an option set, so a forwarded flag would fail the ones
#   that do not accept it for a reason unrelated to the tree.
#
# What this does NOT run:
#   verify-doc-paths.sh, verify-runbook-structure.sh and verify-script-portability.sh.
#   Those are toolkit utilities about the reimage workflow, not about this
#   framework. Run them by name; a session handing over a patch runs all of
#   them. Keeping them out is what lets this script and the four it dispatches
#   move to another project as a unit.
#
# Exit status:
#   0  every check invoked returned 0.
#   1  at least one returned non-zero.
#   2  usage error, or a check's script is missing.
#
#   STANDING BASELINE: `headers` reports FAIL rows and `all` therefore exits 1
#   on a clean tree. They are decisions that cite no finding -- 0039 D15's rule
#   firing on rows that predate it -- in `0005`, `0012`, `0013`, `0025`, `0030`
#   and `0035`. Those bundles belong to `run-index-design-20260901-000000` and
#   `pre-image-capture-conformance-20260903-194532`, so the fix is one table
#   cell per row and is not the session-management re-evaluation's to make.
#
#   The BUNDLES are named here and the COUNT is not, deliberately: a number
#   written into a script goes stale the moment one row is fixed, and quoting a
#   stale total as a baseline is 0036 exactly. Run the check to get the count.
#
#   Superseded bundles are exempt by design, not by baseline -- ten further rows
#   in `0031` and `0032` are frozen and must not be repaired.
# --- END USAGE ---
# =============================================================================

set -uo pipefail
# Not -e: every check is meant to produce a summary row. Aborting on the first
# non-zero would hide the other five, and seeing all six at once is the point.

# ONE level up: this sits in bin/, so the repo root is the parent. Three of the
# checks it dispatches sit two levels deeper and have their own copy of this
# line at a different depth -- moving any script between depths without editing
# it is a failure this repository has already hit; see the same comment in
# record-restore-prereqs.sh and compare-restored-state.sh.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT" || exit 2

if [ ! -d docs ] || [ ! -d .github ]; then
  echo "ERROR: $REPO_ROOT does not look like the repository root." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# The one list: subcommand, path relative to the repository root, group.
#
# Columns are whitespace-separated and no field contains a space, so awk reads
# it with the default field splitting. Adding a check is one line here and
# nothing else; moving one is one edit to its second column.
# ---------------------------------------------------------------------------
check_table() {
  cat <<'TABLE'
counts .internal/ai-scripts/session-management/verify-findings-counts.sh verify
headers .internal/ai-scripts/session-management/verify-findings-headers.sh verify
structure .internal/ai-scripts/session-management/verify-findings-structure.sh verify
completeness .internal/ai-scripts/session-management/check-completeness.sh verify
manifest-revision .share/check-manifest-revision.sh report
TABLE
}

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

check_path() {
  check_table | awk -v want="$1" '$1 == want { print $2; found = 1 } END { exit !found }'
}

group_members() {
  check_table | awk -v want="$1" '$3 == want { print $1 }'
}

# Both derived from the table so neither can advertise a set the dispatch does
# not accept.
SINGLE_SUBCOMMANDS="$(check_table | awk '{ printf "%s ", $1 }')"
GROUP_SUBCOMMANDS="all"

list_checks() {
  printf '%-20s %-18s %-70s %s\n' "SUBCOMMAND" "GROUP" "SCRIPT" "PRESENT"
  check_table | while read -r sub path group; do
    if [ -f "$REPO_ROOT/$path" ]; then present="yes"; else present="NO"; fi
    printf '%-20s %-18s %-70s %s\n' "$sub" "$group" "$path" "$present"
  done
}

# ---------------------------------------------------------------------------
# Running one check
#
# Invoked with `bash <path>` rather than executed, so the executable bit is not
# a prerequisite. The runbooks already invoke scripts this way, and a check that
# silently does not run because a mode bit was lost in a patch is the failure
# mode this dispatcher exists to remove.
# ---------------------------------------------------------------------------
ROWS=""
worst=0
missing=0

run_one() {
  sub="$1"
  shift
  path="$(check_path "$sub")"

  if [ ! -f "$REPO_ROOT/$path" ]; then
    printf '\n=== %s ===\n' "$sub"
    printf 'ERROR: not found: %s\n' "$path" >&2
    ROWS="${ROWS}$(printf '  %-20s %-9s %s' "$sub" "MISSING" "$path")"$'\n'
    missing=1
    return 0
  fi

  printf '\n=== %s (%s) ===\n' "$sub" "$path"
  bash "$REPO_ROOT/$path" "$@"
  status=$?

  case "$status" in
    0) verdict="ok" ;;
    1) verdict="FAILED" ;;
    *) verdict="ERROR $status" ;;
  esac
  ROWS="${ROWS}$(printf '  %-20s %-9s %s' "$sub" "$verdict" "$path")"$'\n'
  [ "$status" -gt "$worst" ] && worst="$status"
  return 0
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
SUBCOMMAND="${1:-all}"
[ $# -gt 0 ] && shift

case "$SUBCOMMAND" in
  -h|--help) usage; exit 0 ;;
  list)
    if [ $# -gt 0 ]; then
      echo "ERROR: list takes no arguments." >&2
      exit 2
    fi
    list_checks
    exit 0
    ;;
esac

# A group takes no options: see the Options note in the usage block.
case " $GROUP_SUBCOMMANDS " in
  *" $SUBCOMMAND "*)
    if [ $# -gt 0 ]; then
      echo "ERROR: '$SUBCOMMAND' runs several checks and takes no options; got: $*" >&2
      echo "HINT:  the checks do not share an option set. Name one check to pass it options:" >&2
      echo "       ./bin/verify-session-findings.sh <check> $*" >&2
      exit 2
    fi
    # `all` is the verify group by definition, not the whole table: a report
    # subcommand has no verdict to fold into a pass/fail exit status.
    if [ "$SUBCOMMAND" = "all" ]; then
      members="$(group_members verify)"
    else
      members="$(group_members "$SUBCOMMAND")"
    fi
    for member in $members; do
      run_one "$member"
    done
    ;;
  *)
    case " $SINGLE_SUBCOMMANDS " in
      *" $SUBCOMMAND "*)
        run_one "$SUBCOMMAND" "$@"
        ;;
      *)
        echo "ERROR: unknown subcommand: $SUBCOMMAND" >&2
        echo "Groups: $GROUP_SUBCOMMANDS" >&2
        echo "Checks: $SINGLE_SUBCOMMANDS" >&2
        echo "Run './bin/verify-session-findings.sh list' to see where each resolves." >&2
        exit 2
        ;;
    esac
    ;;
esac

# ---------------------------------------------------------------------------
# Summary
#
# Printed even for a single check, so a handover note can be pasted from one
# place whichever way the script was called.
# ---------------------------------------------------------------------------
printf '\n=== summary ===\n'
printf '%s' "$ROWS"

if [ "$missing" -ne 0 ]; then
  printf '\nAt least one check is missing from the tree. That is not a clean run.\n' >&2
  exit 2
fi

case "$worst" in
  0) printf '\nEvery check returned 0.\n' ;;
  1) printf '\nAt least one check returned 1. `headers` carries a standing baseline in six\nbundles owned by other sessions -- see --help before reading it as a regression.\n' ;;
  *) printf '\nA check returned %s, which is a configuration or layout error rather than\na finding. Read its output above.\n' "$worst" ;;
esac

exit "$worst"
