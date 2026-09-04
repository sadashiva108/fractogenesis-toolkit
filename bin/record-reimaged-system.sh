#!/usr/bin/env bash
# =============================================================================
# record-reimaged-system.sh
#
# Phase 9 — Verify Reimaged System evidence recorder. Runs read-only day-one
# health checks (identity, MDM/profiles, FileVault, expected managed and
# personal apps, running managed processes, volumes, Time Machine destination,
# software updates, brew/git/xcode presence, optional network reachability),
# stamps PASS/WARN/TODO on the automated rows, and writes a first-boot
# evidence bundle plus companion planning documents (initial record,
# restart checkpoints, Time Machine plan, manual captures).
#
# Meant to run twice: once after Phase 8 completes and the external artifact
# drive is reconnected, and once again after the second stabilization restart
# so the two bundles can be compared for regressions. See
# verify-reimaged-system.md for the full runbook.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/record-reimaged-system.sh
#
#   # Default -- writes under $REIMAGE_ARTIFACT_ROOT when mounted, otherwise
#   # under ~/Desktop/reimaged-system-artifacts/.
#   ./bin/record-reimaged-system.sh
#
#   # Reveal the generated bundle in Finder after completion.
#   ./bin/record-reimaged-system.sh --open
#
#   # Override the artifact root for this invocation.
#   ./bin/record-reimaged-system.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Write to an exact output root (skips the reimaged-system/ layout and the
#   # fallback path entirely).
#   ./bin/record-reimaged-system.sh --output-root /absolute/path/to/output
#
#   # Skip curl/ping reachability probes (offline runs, or when a captive
#   # portal is intercepting HTTP HEAD).
#   ./bin/record-reimaged-system.sh --no-network
#
#   # Label the run so the two bundles around the stabilization restart are
#   # distinguishable on disk without opening them. Matches the --context
#   # convention already used by report-loose-secrets.sh.
#   ./bin/record-reimaged-system.sh --context pre-restart     # Step 2
#   ./bin/record-reimaged-system.sh --context post-restart    # Step 5
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --output-root PATH    Parent directory that will hold the timestamped
#                         first-boot bundle. Overrides the default layout.
#   --context LABEL       The run's point. Conventional values are pre-restart
#                         and post-restart; omitted, the run is `initial`.
#                         `entry` and `exit` select the bookend modes instead
#                         of a first-boot capture -- see Bookend modes below.
#                         Letters, digits, dot, underscore, and hyphen only.
#   --no-network          Skip network reachability probes.
#   --note TEXT           Free text recorded in the manifest's `Note` column for
#                         this run. Use it when a run is written well after the
#                         phase it records -- a bookend added retrospectively is
#                         well-formed and its timestamp is the recorder's, not
#                         the phase's, and nothing else can say so.
#   --open                Reveal the generated bundle in Finder on completion.
#   -h, --help            Show this message and exit.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Bundle naming:
#   runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS
#
#   The label leads, matching post-image-performance-audit-*, post-reimage-*,
#   and the pre-image-* repo-audit runs. bin/reimage-checklist.sh therefore
#   resolves the bundle through official/<context>.txt when validating Phase 9 evidence.
#
#   Because the label precedes the timestamp, directory names no longer sort
#   chronologically once more than one label is in play: post-restart sorts
#   before pre-restart regardless of when each ran. Select a "latest" record
#   by modification time, or glob one label at a time, rather than sorting the
#   mixed set lexically.
#
# Output location precedence (used only when --output-root is not supplied):
#   1. $REIMAGE_ARTIFACT_ROOT/reimaged-system/
#        when REIMAGE_ARTIFACT_ROOT is set and currently mounted. The bundle
#        lands at reimaged-system/restarts/runs/verify-reimaged-system-initial-<stamp>/,
#        matching the layout documented in references/master-directory-reference.md.
#   2. ~/Desktop/reimaged-system-artifacts/
#        as a fallback so the capture can complete on a bare Mac before the
#        external artifact volume is reconnected.
#
# Bookend modes:
#   `--context entry` and `--context exit` write a bookend to
#   reimaged-system/bookends/ under verify-reimaged-system-{entry,exit}, in
#   the same category and grammar the restore phases use, so one index answers
#   "did this phase both start and finish" for every phase in the workflow.
#
#   Entry reads Phase 8's exit bookend rather than re-deriving whether
#   enrollment finished: the pair exists so each phase asks the phase before it
#   whether it closed out, instead of reaching into its evidence.
#
#   Exit resolves both first-boot bundles through the run index and checks that
#   the post-restart one is actually newer than the pre-restart one. A stale
#   post-restart bundle standing in for a run that never happened presents as a
#   complete pair, and is the failure this phase is least able to see by eye.
#
# Exit status:
#   0  Bundle written successfully. Individual failed checks are recorded as
#      WARN/TODO rows rather than changing the exit status; a failed
#      latest-bundle pointer update prints a WARNING and still exits 0.
#   2  Usage, configuration, or prerequisite error, including an output root
#      the bundle directory cannot be created under.
# --- END USAGE ---
# =============================================================================

# Aggregate validator strict mode.
# NOTE: intentionally NOT set -e. Failed individual checks are converted into
# PASS/WARN/TODO records rather than aborting the run, so a single unavailable
# subsystem cannot cost the whole first-boot bundle. Every read-only command
# below is guarded with `|| true` or a checker function.
set -uo pipefail

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

# The external artifact volume may not be mounted yet on the first pre-restart
# run; keep loading permissive so the Desktop fallback path is reachable.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

# Shared run index. The first-boot bundles are indexed runs under
# reimaged-system/restarts/ rather than directories at the reimaged-system/
# root, so this script brackets its work with artifact_run_begin / finalize the
# way the bookend recorders and the comparison do.
RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/artifact-runs.sh
source "$RUNS_LIB"

# Manual rows leave the run directory. `artifact_run_begin` stages a NEW run on
# every invocation, so a row answered inside bookend.md is replaced by a fresh
# `TODO` the next time this script is run -- the failure verify-reimaged-system.md
# warns about. The sign-off carries answers forward instead, and stamps each with
# the run it was answered against. See .internal/sign-offs.sh.
SIGNOFF_LIB="$REPO_ROOT/.internal/sign-offs.sh"
if [[ ! -f "$SIGNOFF_LIB" ]]; then
  echo "ERROR: shared sign-off helper not found: $SIGNOFF_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/sign-offs.sh
source "$SIGNOFF_LIB"

SCRIPT_NAME="${REIMAGE_SCRIPT_DISPLAY_NAME:-record-reimaged-system.sh}"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

# ---------------------------------------------------------------------------
# Defaults and command-line parsing
# ---------------------------------------------------------------------------
OUTPUT_ROOT=""
OPEN_RESULT=false
# Free text for the manifest Note column. Empty unless --note is given, and the
# library writes an em dash for an empty note, so the default is not special.
RUN_NOTE=""
RUN_NETWORK=true
ARTIFACT_ROOT_EXPLICIT=false
CONTEXT_LABEL=""

# Validate a --context label before it becomes part of a directory name. A label
# carrying a slash, a space, or a quote produces either a nested path or a name
# that later globs and `cp` invocations mishandle, so reject it outright rather
# than silently rewriting what the operator typed. The character class is a
# POSIX `case` glob rather than a regex so this behaves identically on the
# stock macOS Bash 3.2.
validate_context() {
  local value="$1"
  case "$value" in
    "")
      return 0
      ;;
    *[!A-Za-z0-9._-]*)
      echo "ERROR: --context may contain only letters, digits, dot, underscore, and hyphen: $value" >&2
      echo "HINT:  the label becomes part of the bundle directory name." >&2
      exit 2
      ;;
    -*)
      echo "ERROR: --context may not begin with a hyphen: $value" >&2
      exit 2
      ;;
  esac
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      ARTIFACT_ROOT_EXPLICIT=true
      shift 2
      ;;
    --output-root)
      require_option_value "$1" "${2:-}"
      OUTPUT_ROOT="$2"
      shift 2
      ;;
    --note)
      require_option_value "$1" "${2:-}"
      RUN_NOTE="$2"
      shift 2
      ;;
    --context)
      require_option_value "$1" "${2:-}"
      validate_context "$2"
      CONTEXT_LABEL="$2"
      shift 2
      ;;
    --no-network)
      RUN_NETWORK=false
      shift
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
# Resolve output location
# ---------------------------------------------------------------------------
# Both runbooks tell the operator to pass --artifact-root "$REIMAGE_ARTIFACT_ROOT"
# explicitly. If that value does not resolve to a mounted directory the run
# still completes against the fallback location — say so instead of silently
# downgrading. The fallback chain itself is unchanged.
if [[ "$ARTIFACT_ROOT_EXPLICIT" == "true" && ! -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "WARNING: --artifact-root does not resolve to an existing directory: ${REIMAGE_ARTIFACT_ROOT:-<unset>}" >&2
  echo "WARNING: the artifact volume is probably not mounted. This run falls back to the local output location below; reconnect the drive and rerun to file the bundle with the rest of the evidence." >&2
fi

if [[ -z "$OUTPUT_ROOT" ]]; then
  if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system"
  else
    OUTPUT_ROOT="$HOME/Desktop/reimaged-system-artifacts"
  fi
fi

# Resolve a relative --output-root against the current directory before the
# guard below compares it with the repo root; a relative path can never match
# "$REPO_ROOT"/*, so without this `--output-root subdir` run from the checkout
# slips past the guard. The directory need not exist yet, so this is a plain
# textual prefix rather than a realpath() call (also keeps Bash 3.2 support).
case "$OUTPUT_ROOT" in
  /*) ;;
  *) OUTPUT_ROOT="$PWD/$OUTPUT_ROOT" ;;
esac

if [[ -n "${REPO_ROOT:-}" && ( "$OUTPUT_ROOT" == "$REPO_ROOT" || "$OUTPUT_ROOT" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $OUTPUT_ROOT" >&2
  exit 2
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
# Run ids are <runbook>-<point>-<stamp> to match the artifact tree
# documented in references/master-directory-reference.md and the pattern that
# bin/reimage-checklist.sh looks for when validating Phase 9 evidence.
# The context label leads the directory name:
# verify-reimaged-system-pre-restart-YYYYMMDD-HHMMSS. This matches the
# convention already used by post-image-performance-audit-*, post-reimage-*,
# and the pre-image-* repo-audit runs, where the phase or context comes first.
#
# Two consequences for anything that reads these bundles back:
#   - the artifact name is no longer at the start, so globs need a leading
#     the run index rather than a glob;
#   - names group by label before timestamp, so a "latest bundle" lookup must
#     rank on the trailing stamp and never on a plain lexical sort.
# The stamp stays at the end of the name, which is what reimage-checklist.sh
# extracts to compare bundle age against the Time Machine backup.
# The context label becomes the run's POINT. `pre-restart` and `post-restart`
# are both points the run index already knows, so `--context pre-restart` lands
# in the pre-restart lineage with no further mapping. A run with no context gets
# `initial`, which is NOT a known point and therefore indexes as `unknown` --
# the honest answer, since nothing recorded which side of a restart it was on.
# ---------------------------------------------------------------------------
# Bookend modes: --context entry and --context exit
#
# These capture no first-boot evidence. They record what was decided about it,
# into reimaged-system/bookends/ under verify-reimaged-system-{entry,exit} --
# the same category and grammar the restore phases use, so one place answers
# "did this phase both start and finish" for every phase.
#
# The entry mode reads Phase 8's exit bookend. That is the pair doing its job:
# Phase 9 does not re-derive whether enrollment finished, it asks whether the
# phase that owned that question closed it out.
#
# Self-contained helpers: the bundle path's row machinery is template-driven and
# defined further down, so nothing here may use it.
# ---------------------------------------------------------------------------
BOOKEND_ROWS=""
BOOKEND_MANUAL=""
b_pass=0; b_warn=0; b_fail=0

b_record() {
  case "$1" in
    PASS) b_pass=$(( b_pass + 1 )) ;;
    WARN) b_warn=$(( b_warn + 1 )) ;;
    FAIL) b_fail=$(( b_fail + 1 )) ;;
  esac
  BOOKEND_ROWS="${BOOKEND_ROWS}| ${2} | \`${1}\` | ${3} |"$'\n'
  printf '  %-5s %s\n' "$1" "$2" >&2
}

# Collected as item<TAB>note rather than as a rendered markdown row, because
# these are replayed into the sign-off and no longer written into bookend.md.
# `b_manual` runs inside bookend_entry/bookend_exit, which execute before
# `artifact_run_begin` assigns the run id the sign-off is named for, so the rows
# have to be held until then rather than emitted as they are declared.
b_manual() {
  BOOKEND_MANUAL="${BOOKEND_MANUAL}${1}"$'\t'"${2}"$'\n'
}

# Rows a person still owes, counted in the sign-off rather than in the record.
#
# This used to grep `| `TODO` |` across a whole generated file. The Automated
# rows use the same cell shape, so a probe that could not answer -- `Git
# available`, `Network check` -- counted as a person who had not looked, and the
# caller then reported "N unanswered row(s) ... this step is the only one that
# fills them" about rows no step can fill. Against the official post-restart
# capture that was three rows, every one of them automated.
#
# `signoff_outstanding` prints one line per row still at `TODO` in the latest
# sign-off for a context -- the only place answers are kept, and the only place
# the question is answerable. An absent sign-off returns non-zero, which the
# caller reports as absent rather than as zero outstanding.
b_outstanding_count() {
  local root="$1" context="$2" out
  out="$(signoff_outstanding "$root" "$context" 2>/dev/null)" || return 1
  printf '%s' "$out" | grep -c . 2>/dev/null || true
}

bookend_entry() {
  local bookends_root restarts_root run f n

  bookends_root="$OUTPUT_ROOT/bookends"
  restarts_root="$OUTPUT_ROOT/restarts"

  if [[ -n "${FRACTOGENESIS_HOME:-}" && -d "${FRACTOGENESIS_HOME:-}" ]]; then
    b_record PASS "Toolkit root resolved" "\`$FRACTOGENESIS_HOME\`"
  else
    b_record FAIL "Toolkit root resolved" "\`FRACTOGENESIS_HOME\` unset or not a directory — every command in this runbook assumes the shell is at the toolkit root"
  fi

  if /sbin/ping -c 1 -t 5 8.8.8.8 >/dev/null 2>&1; then
    b_record PASS "Network reachable" "ICMP to 8.8.8.8"
  else
    b_record WARN "Network reachable" "no route — the first-boot bundle records a network row, which will read as a failure of the machine rather than of the link"
  fi

  # Phase 8's close-out, not Phase 8's evidence. A recorded exit is the only
  # thing that says a person looked at what Phase 8 produced.
  run="$(artifact_run_official "$bookends_root" "enroll-and-stabilize-exit" 2>/dev/null || true)"
  f=""
  [[ -n "$run" ]] && f="$bookends_root/$run/bookend.md"
  if [[ -z "$f" || ! -f "$f" ]]; then
    b_record FAIL "Phase 8 closed out" "no official \`enroll-and-stabilize-exit\` run under \`bookends/\` — Phase 8 has not signed off, so nothing establishes that enrollment and the managed app set are settled"
  else
    if n="$(b_outstanding_count "$OUTPUT_ROOT/sign-offs" "enroll-and-stabilize-exit")"; then
      if [[ "${n:-0}" -eq 0 ]]; then
        b_record PASS "Phase 8 closed out" "\`$(basename "$run")\`, no outstanding rows in its sign-off"
      else
        b_record WARN "Phase 8 closed out" "$n outstanding row(s) in the \`enroll-and-stabilize-exit\` sign-off — answer them before relying on this phase's baseline"
      fi
    else
      b_record WARN "Phase 8 closed out" "\`$(basename "$run")\` exists but no \`enroll-and-stabilize-exit\` sign-off does — the rows a person answers were never opened"
    fi
  fi

  run="$(artifact_run_official "$restarts_root" "enroll-and-stabilize-post-restart" 2>/dev/null || true)"
  if [[ -n "$run" ]]; then
    b_record PASS "Phase 8 post-restart record present" "\`$(basename "$run")\`"
  else
    b_record WARN "Phase 8 post-restart record present" "none under \`restarts/\` — it may still be on a Phase 8 fallback path; Step 1 relocates it"
  fi

  if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    b_record PASS "Artifact root mounted" "\`$REIMAGE_ARTIFACT_ROOT\`"
  else
    b_record WARN "Artifact root mounted" "not mounted — expected at entry. Step 1 is what reconnects it; this run lands on the Desktop fallback"
  fi

  b_manual "Signed back in after the Phase 8 restart" "This is the session that came back from the first stabilization restart, not a session that never restarted."
  b_manual "Nothing this Mac needs is still installable" "The Company Portal Apps tab shows no Required or Available assignment this machine needs that has not been installed. Phase 8 Step 4 owns finishing that."
}

bookend_exit() {
  local restarts_root comparisons_root pre post f n pre_stamp post_stamp

  restarts_root="$OUTPUT_ROOT/restarts"
  comparisons_root="$OUTPUT_ROOT/comparisons"

  if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    b_record PASS "Artifact root mounted and readable" "\`$REIMAGE_ARTIFACT_ROOT\`"
  else
    b_record FAIL "Artifact root mounted and readable" "not mounted — Step 1 reconnects it, and Phase 10 onward assumes it. Evidence written now lands on a fallback path"
  fi

  pre="$(artifact_run_official "$restarts_root" "verify-reimaged-system-pre-restart" 2>/dev/null || true)"
  post="$(artifact_run_official "$restarts_root" "verify-reimaged-system-post-restart" 2>/dev/null || true)"

  if [[ -n "$pre" ]]; then
    b_record PASS "Pre-restart first-boot bundle recorded" "\`$(basename "$pre")\`"
  else
    b_record FAIL "Pre-restart first-boot bundle recorded" "no official \`verify-reimaged-system-pre-restart\` run — Step 2 has not produced one"
  fi

  if [[ -n "$post" ]]; then
    b_record PASS "Post-restart first-boot bundle recorded" "\`$(basename "$post")\`"
  else
    b_record FAIL "Post-restart first-boot bundle recorded" "no official \`verify-reimaged-system-post-restart\` run — Step 5 has not produced one"
  fi

  # A post-restart bundle older than the pre-restart one means Step 5 never ran
  # after the restart and an earlier run is standing in for it -- which looks
  # like a complete pair and is not one.
  if [[ -n "$pre" && -n "$post" ]]; then
    pre_stamp="$(printf '%s' "$pre" | sed 's/^.*-\([0-9]\{8\}-[0-9]\{6\}\)$/\1/')"
    post_stamp="$(printf '%s' "$post" | sed 's/^.*-\([0-9]\{8\}-[0-9]\{6\}\)$/\1/')"
    if [[ "$post_stamp" > "$pre_stamp" ]]; then
      b_record PASS "The pair brackets the restart" "post-restart $post_stamp is newer than pre-restart $pre_stamp"
    else
      b_record FAIL "The pair brackets the restart" "post-restart $post_stamp is NOT newer than pre-restart $pre_stamp — the post-restart bundle predates the restart it is supposed to follow"
    fi
  fi

  if [[ -n "$(artifact_run_official "$comparisons_root" "verify-reimaged-system-restart-diff" 2>/dev/null || true)" ]]; then
    b_record PASS "The two bundles were compared" "recorded under \`comparisons/\`"
  else
    b_record WARN "The two bundles were compared" "no official comparison run — Step 6 compares them, and without it nothing names what changed across the restart"
  fi

  f=""
  [[ -n "$post" ]] && f="$restarts_root/$post/record.md"
  if [[ -n "$f" && -f "$f" ]]; then
    if n="$(b_outstanding_count "$OUTPUT_ROOT/sign-offs" "verify-reimaged-system-post-restart")"; then
      if [[ "${n:-0}" -eq 0 ]]; then
        b_record PASS "Post-restart rows answered" "no outstanding rows in the \`verify-reimaged-system-post-restart\` sign-off"
      else
        b_record WARN "Post-restart rows answered" "$n outstanding row(s) in the \`verify-reimaged-system-post-restart\` sign-off — this step is the only one that fills them"
      fi
    else
      b_record WARN "Post-restart rows answered" "\`$(basename "$post")\` exists but no \`verify-reimaged-system-post-restart\` sign-off does"
    fi
  fi

  b_manual "No new critical regressions across the two bundles" "Read the Step 6 comparison row by row. A row that flipped because the network changed between runs is not a regression; anything else is, until explained."
  b_manual "Managed app set complete and unchanged since the pre-restart bundle" "Company Portal Apps tab plus \`raw/applications-managed.txt\` in both bundles."
  b_manual "First-boot basics are usable" "Browser, network, terminal, display, keyboard, mouse and audio — the Step 3 review."
}

# ---------------------------------------------------------------------------
# Comparison mode: --context diff
#
# Reads the two official first-boot captures and reports how their recorded rows
# changed across the restart. A raw `diff -u` of two records is technically
# complete and practically unreadable: it interleaves reordered rows, evidence
# paths and timestamps with the handful of verdicts that actually moved.
#
# Writes to comparisons/ under verify-reimaged-system-restart-diff, which is the
# run the exit bookend looks for when it asks whether the pair was compared.
# ---------------------------------------------------------------------------
if [[ "${CONTEXT_LABEL:-}" == "diff" ]]; then
  RESTARTS_ROOT="$OUTPUT_ROOT/restarts"
  CMP_ROOT="$OUTPUT_ROOT/comparisons"

  PRE_RUN="$(artifact_run_official "$RESTARTS_ROOT" "verify-reimaged-system-pre-restart" 2>/dev/null || true)"
  POST_RUN="$(artifact_run_official "$RESTARTS_ROOT" "verify-reimaged-system-post-restart" 2>/dev/null || true)"
  PRE_FILE="${PRE_RUN:+$RESTARTS_ROOT/$PRE_RUN/record.md}"
  POST_FILE="${POST_RUN:+$RESTARTS_ROOT/$POST_RUN/record.md}"

  for _side in "PRE:$PRE_FILE" "POST:$POST_FILE"; do
    if [[ -z "${_side#*:}" || ! -f "${_side#*:}" ]]; then
      echo "ERROR: no official ${_side%%:*}-restart bundle with a record.md under $RESTARTS_ROOT" >&2
      echo "ERROR: record it with: ./bin/record-reimaged-system.sh --context pre-restart|post-restart" >&2
      exit 2
    fi
  done

  # A recorded row is `| <check> | `<STATUS>` | <evidence> |`. The backticked
  # status in field 3 is what separates a check row from the Item/Location and
  # heading tables in the same file, so parse on that rather than on position.
  #
  # The status set is NOT the four the script writes. Manual rows are answered by
  # hand, so a post-restart record carries `yes`, `no`, `accepted` and the like
  # where the generated file had `TODO`. Matching only PASS/WARN/FAIL/TODO made
  # every answered row invisible on one side and reported it as dropped -- the
  # comparison said fifteen rows disappeared across a restart that changed none.
  # Accept any short backticked token instead, and exclude anything holding a
  # dot or slash, which is how an evidence path in that column is told apart.
  _rows_of() {
    awk -F'|' '
      NF >= 4 {
        c = $2; st = $3
        gsub(/^[ \t]+|[ \t]+$/, "", c)
        gsub(/^[ \t`]+|[ \t`]+$/, "", st)
        # Field 3 is the status column in both tables, so no content test is
        # needed -- only the table furniture has to be skipped. A length cap was
        # tried and was wrong: an operator answering a manual row writes prose
        # like `yes, with exception`, and capping the length dropped that row
        # from one side and then reported it as having disappeared.
        if (c != "Check" && c !~ /^-+$/ && st != "" && st !~ /^-+$/)
          printf "%s\t%s\n", c, st
      }' "$1"
  }

  PRE_TMP="$(mktemp)"; POST_TMP="$(mktemp)"
  _rows_of "$PRE_FILE"  > "$PRE_TMP"
  _rows_of "$POST_FILE" > "$POST_TMP"

  ROWS_TMP="$(mktemp)"
  awk -F'\t' '
    NR == FNR { pre[$1] = $2; next }
    {
      post[$1] = $2
      p = ($1 in pre) ? pre[$1] : "-"
      # "good" spans both vocabularies: the script writes PASS, a person writes
      # yes or accepted, and they mean the same thing about the same row.
      # Prefix match, so a qualified answer -- `yes, with exception` -- still
      # reads as good rather than as a change of state.
      good_p = (p ~ /^(PASS|yes|accepted)/)
      good_n = ($2 ~ /^(PASS|yes|accepted)/)
      verdict = "unchanged"
      if (p == "-")                          verdict = "new"
      else if (p == $2)                      verdict = "unchanged"
      else if (good_p && !good_n)            verdict = "REGRESSED"
      else if (!good_p && good_n)            verdict = "improved"
      else if (p == "TODO")                  verdict = "answered"
      else                                   verdict = "changed"
      printf "%s\t%s\t%s\t%s\n", $1, p, $2, verdict
    }
    END { for (k in pre) if (!(k in post)) printf "%s\t%s\t-\tdropped\n", k, pre[k] }
  ' "$PRE_TMP" "$POST_TMP" | sort > "$ROWS_TMP"

  N_REG="$(awk -F'\t' '$4=="REGRESSED"' "$ROWS_TMP" | wc -l | tr -d ' ')"
  N_IMP="$(awk -F'\t' '$4=="improved"'  "$ROWS_TMP" | wc -l | tr -d ' ')"
  N_CHG="$(awk -F'\t' '$4=="changed"'   "$ROWS_TMP" | wc -l | tr -d ' ')"
  N_ANS="$(awk -F'\t' '$4=="answered"' "$ROWS_TMP" | wc -l | tr -d ' ')"
  N_NEW="$(awk -F'\t' '$4=="new"||$4=="dropped"' "$ROWS_TMP" | wc -l | tr -d ' ')"
  N_SAME="$(awk -F'\t' '$4=="unchanged"' "$ROWS_TMP" | wc -l | tr -d ' ')"

  if ! artifact_run_begin "$CMP_ROOT" "verify-reimaged-system-restart-diff"; then
    echo "ERROR: cannot stage a comparison run under: $CMP_ROOT" >&2
    rm -f "$PRE_TMP" "$POST_TMP" "$ROWS_TMP"
    exit 2
  fi

  cp "$ROWS_TMP" "$ARTIFACT_RUN_DIR/rows.tsv"
  {
    printf '# verify-reimaged-system — restart comparison — %s\n\n' "$ARTIFACT_RUN_STAMP"
    printf 'Generated by `bin/record-reimaged-system.sh --context diff` on %s.\n\n' "$(date)"
    printf 'Pre-restart:  `%s`\n\n' "$PRE_RUN"
    printf 'Post-restart: `%s`\n\n' "$POST_RUN"
    printf '**%s regressed · %s improved · %s answered · %s changed · %s added or dropped · %s unchanged**\n\n' \
      "$N_REG" "$N_IMP" "$N_ANS" "$N_CHG" "$N_NEW" "$N_SAME"
    if [[ "${N_REG:-0}" -gt 0 ]]; then
      printf '## Regressed\n\nA row that passed before the restart and does not now. This is the section to read.\n\n'
      printf '| Check | Before | After |\n| --- | --- | --- |\n'
      awk -F'\t' '$4=="REGRESSED" { printf "| %s | `%s` | `%s` |\n", $1, $2, $3 }' "$ROWS_TMP"
      printf '\n'
    else
      printf '## Regressed\n\nNothing. No row that passed before the restart fails after it.\n\n'
    fi
    for _sect in improved answered changed new dropped; do
      if awk -F'\t' -v s="$_sect" '$4==s' "$ROWS_TMP" | grep -q .; then
        printf '## %s\n\n' "$_sect"
        printf '| Check | Before | After |\n| --- | --- | --- |\n'
        awk -F'\t' -v s="$_sect" '$4==s { printf "| %s | `%s` | `%s` |\n", $1, $2, $3 }' "$ROWS_TMP"
        printf '\n'
      fi
    done
    printf '## Unchanged\n\n%s row(s) read the same on both sides; they are in `rows.tsv`.\n' "$N_SAME"
  } > "$ARTIFACT_RUN_DIR/comparison.md"

  rm -f "$PRE_TMP" "$POST_TMP" "$ROWS_TMP"

  if ! artifact_run_finalize "$CMP_ROOT" \
       "$N_REG regressed / $N_IMP improved / $N_CHG changed" "$RUN_NOTE"; then
    echo "ERROR: the comparison was written but could not be indexed." >&2
    exit 2
  fi

  echo "" >&2
  echo "Comparison → $ARTIFACT_RUN_DIR/comparison.md" >&2
  printf '%s regressed · %s improved · %s answered · %s changed · %s added or dropped · %s unchanged\n' \
    "$N_REG" "$N_IMP" "$N_ANS" "$N_CHG" "$N_NEW" "$N_SAME" >&2
  # A regression is a finding to read, not a failure of the comparison -- the
  # same rule compare-restored-state.sh follows for a MISSING row.
  exit 0
fi

if [[ "${CONTEXT_LABEL:-}" == "entry" || "${CONTEXT_LABEL:-}" == "exit" ]]; then
  BOOKEND_ROOT="$OUTPUT_ROOT/bookends"

  echo "Recording the Phase 9 $CONTEXT_LABEL bookend ..." >&2
  if [[ "$CONTEXT_LABEL" == "entry" ]]; then bookend_entry; else bookend_exit; fi

  if ! artifact_run_begin "$BOOKEND_ROOT" "verify-reimaged-system-$CONTEXT_LABEL"; then
    echo "ERROR: cannot stage a bookend run under: $BOOKEND_ROOT" >&2
    exit 2
  fi

  BOOKEND_FILE="$ARTIFACT_RUN_DIR/bookend.md"

  # Opened before the bookend is written so SIGNOFF_FILE resolves for the
  # pointer below. The sign-off is named for this run, which is what lets a
  # carried answer say which run it was given against.
  SIGNOFF_ROOT="$OUTPUT_ROOT/sign-offs"
  if ! signoff_begin "$SIGNOFF_ROOT" "verify-reimaged-system-$CONTEXT_LABEL" "$ARTIFACT_RUN_ID"; then
    artifact_run_abort
    echo "ERROR: cannot open a sign-off under: $SIGNOFF_ROOT" >&2
    exit 2
  fi

  {
    printf '# verify-reimaged-system — %s Criteria — %s\n\n' "$CONTEXT_LABEL" "$ARTIFACT_RUN_STAMP"
    printf 'Generated by `bin/record-reimaged-system.sh --context %s` on %s.\n\n' "$CONTEXT_LABEL" "$(date)"
    printf 'Pairs with [[verify-reimaged-system|verify-reimaged-system.md]].\n\n'
    printf '## Automated\n\n'
    printf '| Check | Result | Detail |\n| --- | --- | --- |\n'
    printf '%s' "$BOOKEND_ROWS"
    printf '\n**%s pass · %s warn · %s fail**\n\n' "$b_pass" "$b_warn" "$b_fail"
    if [[ -n "$BOOKEND_MANUAL" ]]; then
      printf '## Manual\n\n'
      printf 'The rows a person answers are not in this file. Rerunning this script\n'
      printf 'stages a new run directory, so an answer recorded here would come back\n'
      printf 'as a fresh `TODO`. They live in the sign-off, which carries answers\n'
      printf 'forward and records the run each was answered against:\n\n'
      printf '    %s\n\n' "$SIGNOFF_FILE"
      printf 'A row closed as `no` or `accepted` is a decision and counts as answered;\n'
      printf 'the check is for rows nobody looked at.\n\n'
    fi
    printf '## How to read this\n\n'
    printf -- '- **FAIL** (%s here) means the phase is not finished. Resolve before starting the next one.\n' "$b_fail"
    printf -- '- **WARN** (%s here) means proceed with a known limit, named in the row.\n' "$b_warn"
    printf -- '- Every row is resolved through the run index, so a bundle that exists under a fallback path but was never relocated reads as absent — which is what it is, from here.\n'
  } > "$BOOKEND_FILE" || { artifact_run_abort; echo "ERROR: could not write $BOOKEND_FILE" >&2; exit 2; }

  while IFS=$'\t' read -r _signoff_item _signoff_note; do
    [[ -n "$_signoff_item" ]] || continue
    signoff_row "$_signoff_item" "$_signoff_note"
  done <<< "$BOOKEND_MANUAL"
  # ARTIFACT_RUN_FINAL_DIR, not ARTIFACT_RUN_DIR: the run is staged at
  # runs/.<id>.incomplete and promoted afterwards, so a path quoted for a
  # reader has to be the promoted one. Revision 150 settled this in
  # bin/restore-repos.sh; the sign-offs already on the volume carry the
  # staging path because these four did not follow it.
  signoff_finalize "Phase 9" "$ARTIFACT_RUN_FINAL_DIR/bookend.md"

  if ! artifact_run_finalize "$BOOKEND_ROOT" "$b_pass pass / $b_warn warn / $b_fail fail" "$RUN_NOTE"; then
    echo "ERROR: the bookend was written but could not be indexed." >&2
    exit 2
  fi

  echo "" >&2
  echo "Bookend → $ARTIFACT_RUN_DIR/bookend.md" >&2
  printf '%s pass · %s warn · %s fail\n' "$b_pass" "$b_warn" "$b_fail" >&2
  echo "Answer the Manual rows in the sign-off: $SIGNOFF_FILE" >&2
  [[ "$b_fail" -eq 0 ]] || exit 1
  exit 0
fi

RUN_CATEGORY_ROOT="$OUTPUT_ROOT/restarts"
RUN_CONTEXT="verify-reimaged-system-${CONTEXT_LABEL:-initial}"

# Approved exception to the validator's no-abort rule: this is the validator
# creating its own report destination, not observing system state. Without the
# bundle directory every later write fails silently and the run would still
# claim "First-boot evidence bundle written".
if ! artifact_run_begin "$RUN_CATEGORY_ROOT" "$RUN_CONTEXT"; then
  echo "ERROR: cannot stage an evidence run under: $RUN_CATEGORY_ROOT" >&2
  echo "ERROR: no evidence was written. Choose a writable --output-root (or reconnect the artifact volume) and rerun." >&2
  exit 2
fi
OUT="$ARTIFACT_RUN_DIR"

# `checks/` is deliberately absent. All six migrated bundles carried one and
# every one was empty -- nothing has ever written into it. See the
# "Before adding a directory" rule in script-types-and-locations.md.
if ! mkdir -p "$OUT/logs" "$OUT/raw"; then
  echo "ERROR: cannot create the evidence bundle directory: $OUT" >&2
  artifact_run_abort
  exit 2
fi

# Pre-create the sibling reimaged-system subfolders when writing to the
# artifact tree so later phases (Phase 14's checklist, restart notes, restore
# notes) have somewhere to land without extra shell work.
#
# `reimaged-system/time-machine/` is deliberately NOT among them. Post-image
# Time Machine evidence goes in the root-level `time-machine/` category
# alongside the pre-image runs, the same way every `capture-` category holds
# both phases -- which is what makes the phase discriminator in its contexts
# necessary. A second, always-empty directory here only invited the question of
# which one Phase 16 writes to.
if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" \
      && "$OUTPUT_ROOT" == "$REIMAGE_ARTIFACT_ROOT/reimaged-system" ]]; then
  mkdir -p \
    "$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists" \
    "$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts" \
    "$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes" 2>/dev/null || true
fi

COMMAND_LOG="$OUT/logs/commands.log"
ERROR_LOG="$OUT/logs/errors.log"
RECORD="$OUT/record.md"
SUMMARY="$OUT/README.md"

# The rows a person answers go to the sign-off, not into the record. Revision 116
# established the rule for the bookend path in this same script: a run directory
# is replaced on every invocation, so an answer written into one is lost the next
# time the script runs. The capture path kept emitting a 15-row `TODO` table into
# the run directory anyway, under an instruction telling the operator to fill it
# in -- which is why the 2026-09-02 conversion had to lift those rows out of all
# six captures on the volume by hand. Opened here so SIGNOFF_FILE resolves for
# the pointer the record carries in place of the table.
SIGNOFF_ROOT="$OUTPUT_ROOT/sign-offs"
if ! signoff_begin "$SIGNOFF_ROOT" "$RUN_CONTEXT" "$ARTIFACT_RUN_ID"; then
  artifact_run_abort
  echo "ERROR: cannot open a sign-off under: $SIGNOFF_ROOT" >&2
  exit 2
fi

: > "$COMMAND_LOG"
: > "$ERROR_LOG"

# ---------------------------------------------------------------------------
# Evidence-capture helpers
# ---------------------------------------------------------------------------
log_cmd() {
  printf '%s\n' "$*" >> "$COMMAND_LOG"
}

capture() {
  local name="$1"
  shift
  local target="$OUT/raw/$name.txt"
  {
    echo "# $name"
    echo "# captured: $(date)"
    echo "# command: $*"
    echo ""
    "$@"
  } > "$target" 2>> "$ERROR_LOG" || true
  log_cmd "$* > raw/$name.txt"
}

capture_shell() {
  # Wrap grep-based filters without invoking a login shell so profile output
  # (SDKMAN, direnv chatter, etc.) cannot leak into the recorded evidence.
  # Any arguments after the command string are passed to `bash -c` as "$1",
  # "$2", ... so paths never have to be interpolated into the command text.
  local name="$1"
  local cmd="$2"
  shift 2
  local display="$cmd"
  if [[ $# -gt 0 ]]; then
    display="$cmd -- $*"
  fi
  local target="$OUT/raw/$name.txt"
  {
    echo "# $name"
    echo "# captured: $(date)"
    echo "# command: $display"
    echo ""
    bash -c "$cmd" "$name" "$@"
  } > "$target" 2>> "$ERROR_LOG" || true
  log_cmd "$display > raw/$name.txt"
}

write_text() {
  local name="$1"
  shift
  local target="$OUT/raw/$name.txt"
  {
    echo "# $name"
    echo "# captured: $(date)"
    echo ""
    printf '%s\n' "$*"
  } > "$target"
}

# ---------------------------------------------------------------------------
# Row checkers (PASS/WARN/TODO)
# ---------------------------------------------------------------------------
check_contains_file() {
  local file="$1"
  local pattern="$2"
  if [[ -f "$file" ]] && grep -Eiq "$pattern" "$file"; then
    echo "PASS"
  else
    echo "WARN"
  fi
}

check_dir_exists() {
  if [[ -d "$1" ]]; then echo "PASS"; else echo "TODO"; fi
}

# Look one level deep as well as at the top of /Applications. Agents such as
# Zscaler install as /Applications/Zscaler/Zscaler.app, and a top-level listing
# alone matches only the enclosing folder — which an empty leftover directory
# would also satisfy.
check_any_app() {
  local pattern="$1"
  local listing
  # Build the listing first, then match against a here-string. Piping into
  # `grep -q` is unsafe under `set -o pipefail`: grep exits on the first match,
  # the upstream `ls` takes SIGPIPE, and the pipeline reports failure even
  # though the pattern matched. That race is size-dependent, so it surfaces as
  # an intermittent TODO on an app that is plainly installed.
  listing="$( { ls -1 /Applications 2>/dev/null; \
                ls -1d /Applications/*/*.app 2>/dev/null \
                  | sed 's#^/Applications/##'; } || true )"
  if grep -Eiq "$pattern" <<< "$listing"; then
    echo "PASS"
  else
    echo "TODO"
  fi
}

check_process() {
  local pattern="$1"
  if pgrep -fl "$pattern" >/dev/null 2>&1; then
    echo "PASS"
  else
    echo "TODO"
  fi
}

# ---------------------------------------------------------------------------
# Core read-only captures
# ---------------------------------------------------------------------------
capture date            date
capture sw_vers         sw_vers
capture uname           uname -a
capture whoami          whoami
capture hostname        hostname
capture computer-name   scutil --get ComputerName
capture local-host-name scutil --get LocalHostName
capture host-name       scutil --get HostName
capture hardware        system_profiler SPHardwareDataType
capture filevault       fdesetup status
capture profiles-enrollment profiles status -type enrollment
capture profiles-list   profiles list

# Record every application plus one level of nesting rather than a vendor-name
# filter. A filter can only confirm what someone thought to list, so an app this
# Mac was assigned but nobody anticipated is invisible in the evidence. The full
# list is also what makes the pre/post-restart bundle diff meaningful.
capture_shell applications-managed \
  "{ ls -1 /Applications 2>/dev/null; ls -1d /Applications/*/*.app 2>/dev/null | sed 's#^/Applications/##'; } | sort -u"
capture_shell managed-processes \
  "ps aux | grep -Ei 'Intune|Company Portal|CrowdStrike|falcon|Zscaler|Microsoft AutoUpdate|MAU|OneDrive|mdmclient' | grep -v grep || true"
capture_shell volumes \
  "ls -la /Volumes && echo && df -h"

capture time-machine-destination tmutil destinationinfo
capture_shell time-machine-latest "tmutil latestbackup 2>/dev/null || true"
capture softwareupdate-list      softwareupdate --list

capture_shell brew-version   "command -v brew >/dev/null 2>&1 && brew --version || echo 'brew not installed yet'"
capture_shell git-version    "command -v git  >/dev/null 2>&1 && git  --version || echo 'git not installed yet'"
capture_shell xcode-select   "xcode-select -p 2>/dev/null || echo 'xcode-select path not configured yet'"

if [[ "$RUN_NETWORK" == "true" ]]; then
  capture_shell network-ping      "ping -c 3 github.com"
  capture_shell network-github    "curl -I --max-time 10 https://github.com 2>/dev/null | head -20"
  capture_shell network-microsoft "curl -I --max-time 10 https://login.microsoftonline.com 2>/dev/null | head -20"
else
  write_text network-skipped "Network checks skipped with --no-network."
fi

# Optional artifact-root spot check.
if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  # Pass the artifact root as a positional argument: interpolating it into the
  # command string breaks on a path containing an apostrophe.
  capture_shell artifact-root-spotcheck \
    'find "$1" -maxdepth 2 -type f | sort | head -200' \
    "$REIMAGE_ARTIFACT_ROOT"
else
  write_text artifact-root-missing \
    "REIMAGE_ARTIFACT_ROOT was not provided or does not exist." \
    "Pass --artifact-root PATH after reconnecting the external artifact drive."
fi

# ---------------------------------------------------------------------------
# Compute row verdicts
# ---------------------------------------------------------------------------
MDM_STATUS="$(check_contains_file "$OUT/raw/profiles-enrollment.txt" 'MDM enrollment: Yes|Enrolled via DEP: Yes|User Approved')"
FILEVAULT_STATUS="$(check_contains_file "$OUT/raw/filevault.txt" 'FileVault is On')"
COMPANY_PORTAL_STATUS="$(check_any_app 'Company Portal')"
ZSCALER_STATUS="$(check_any_app 'Zscaler')"
CROWDSTRIKE_APP_STATUS="$(check_any_app 'CrowdStrike|Falcon')"
CROWDSTRIKE_PROC_STATUS="$(check_process 'falcon|CrowdStrike')"
OFFICE_STATUS="$(check_any_app 'Microsoft Outlook|Microsoft Word|Microsoft Excel|Microsoft PowerPoint|Microsoft OneNote')"
ONEDRIVE_STATUS="$(check_any_app 'OneDrive')"
CHROME_STATUS="$(check_any_app 'Google Chrome')"

ARTIFACT_ROOT_STATUS="TODO"
if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  ARTIFACT_ROOT_STATUS="PASS"
fi

# Time Machine destination. The volume label is taken from the configured
# EXTERNAL_APPLE_BACKUPS_VOLUME instead of a hardcoded volume name; artifact-
# config.sh defaults that variable to /Volumes/AppleBackups, so the default
# configuration evaluates exactly the same 'AppleBackups|Name' union this check
# has always used, while a Mac whose backup volume is named something else now
# matches its own volume. The volume name is compared as a fixed string so a
# label containing regex metacharacters cannot corrupt the pattern.
TM_DEST_FILE="$OUT/raw/time-machine-destination.txt"
TM_DEST_STATUS="$(check_contains_file "$TM_DEST_FILE" 'Name')"
if [[ "$TM_DEST_STATUS" != "PASS" && -n "${EXTERNAL_APPLE_BACKUPS_VOLUME:-}" && -f "$TM_DEST_FILE" ]]; then
  if grep -Fiq "$(basename "${EXTERNAL_APPLE_BACKUPS_VOLUME%/}")" "$TM_DEST_FILE"; then
    TM_DEST_STATUS="PASS"
  fi
fi

# Not TODO: Phase 10A installs these, so their absence here is the expected
# state rather than operator action, and a TODO row that no step in this phase
# can clear teaches the reader to ignore TODO. Presence is still worth
# recording -- Xcode Command Line Tools supplies git, so it can legitimately
# appear before Phase 10A runs.
GIT_STATUS="INFO"
if grep -q "git version" "$OUT/raw/git-version.txt" 2>/dev/null; then
  GIT_STATUS="PASS"
fi

BREW_STATUS="INFO"
if grep -q "Homebrew" "$OUT/raw/brew-version.txt" 2>/dev/null; then
  BREW_STATUS="PASS"
fi

NETWORK_STATUS="INFO"
if [[ "$RUN_NETWORK" == "true" ]]; then
  NETWORK_STATUS="$(check_contains_file "$OUT/raw/network-github.txt" '^HTTP/|HTTP/[0-9]')"
fi

# ---------------------------------------------------------------------------
# Companion planning documents
# ---------------------------------------------------------------------------
cat > "$OUT/restart-checkpoints.md" <<'EOF_RESTART'
# Reimaged System Restart Checkpoints

Use restarts as deliberate stabilization points, not as random troubleshooting.

| Checkpoint | Recommended Action | Status | Notes |
|---|---|---|---|
| After Intune / Company Portal enrollment **and** the managed app set is installed from the Company Portal Apps tab (Phase 8 Step 4) | Restart once, then rerun record-reimaged-system.sh | `TODO` | Helps confirm MDM profiles, login items, network filters, security agents, and managed app registration survive reboot. Managed apps belong here, not later — installing them after the first bundle fills the Phase 9 diff with spurious rows. |
| After macOS updates | Restart when prompted, then rerun record-reimaged-system.sh | `TODO` | Required for OS/security updates. |
| After Homebrew, shell, Git, Java, Node, Python, Gradle, Maven, Docker CLI basics | Restart once before heavy repo restore | `TODO` | Helps catch path, shell, Rosetta, Java, and developer-tool setup issues. |
| After Docker Desktop, VPN/Zscaler, certificates, and corporate network access are restored | Restart once before project validation | `TODO` | Helps stabilize network extensions, Docker helpers, and cert trust. |
| After the non-managed apps are installed/configured — Obsidian, Postman, VS Code, Raycast, Docker Desktop | Restart once before reimaged-system validation | `TODO` | Helps confirm login items and background services. Managed apps (Office, Teams, OneDrive, Chrome) are **not** installed here; they arrive in Phase 8 via Company Portal. |
| After Phase 12 validation passes | Final restart, then capture reimaged-system performance/Office baseline | `TODO` | Produces a cleaner comparison point against the pre-image baseline. |

If Outlook or OneNote closes unexpectedly, capture evidence before restarting or reopening the app.

Do not restart while a Company Portal install, a Microsoft AutoUpdate download,
or a large OneDrive initial sync is in flight. A restart taken mid-install
produces a bundle that reads as a regression when nothing regressed.
EOF_RESTART

cat > "$OUT/time-machine-plan.md" <<'EOF_TM'
# Reimaged System Time Machine Plan

Nothing in this file runs during Phase 9. The post-image Time Machine backup is
Phase 16, taken after Phase 15 — Restore Home, and owned by `run-time-machine.md`.
These are the notes to carry into it.

Keep Time Machine backups on the dedicated Apple backups partition ($EXTERNAL_APPLE_BACKUPS_VOLUME when defined). Keep workflow evidence and generated captures under the artifact-root partition ($EXTERNAL_DATA_VOLUME / $REIMAGE_ARTIFACT_ROOT).

Recommended reimaged-system Time Machine checkpoints:

1. **First post-image backup (Phase 16)** — after Phase 15 — Restore Home
   completes. This is the first backup of the rebuilt Mac and the one that
   matters; everything before it would capture a machine holding nothing that
   re-enrolling could not reproduce.
2. **Normal ongoing backups** — after the machine is back to daily use.

Until Phase 16 runs, the pre-image Time Machine chain is still the fallback.
Check free space before starting: Time Machine thins oldest-first, so a rebuilt
system added to the same destination can silently delete that chain.

Before starting reimaged-system Time Machine, the artifact volume MUST be confirmed
excluded. This is a gate, not a note: if the exclusion did not take, Time Machine
backs the entire manual backup directory into the Time Machine partition. The block
below refuses to start a backup unless `tmutil isexcluded` reports `[Excluded]`.

EOF_TM

# The exclusion gate is appended separately from the quoted heredoc above so the
# artifact volume resolved at capture time is baked into the generated plan. A
# quoted heredoc emits "$EXTERNAL_DATA_VOLUME" literally, and pasting that into a
# shell that has not sourced reimage.env hands `addexclusion` an empty argument --
# a silent no-op immediately followed by a full backup of the artifact drive. The
# resolved value is written as a defaulted assignment, and the gate still refuses
# to run if that value is empty or the exclusion does not verify.
{
  echo '```bash'
  printf 'EXTERNAL_DATA_VOLUME="${EXTERNAL_DATA_VOLUME:-%s}"\n' "${EXTERNAL_DATA_VOLUME:-}"
  cat <<'EOF_TM_GATE'
if [ -z "$EXTERNAL_DATA_VOLUME" ]; then
  echo "REFUSING: EXTERNAL_DATA_VOLUME is empty; set it before starting Time Machine." >&2
else
  sudo tmutil addexclusion -v "$EXTERNAL_DATA_VOLUME"
  if tmutil isexcluded "$EXTERNAL_DATA_VOLUME" | grep -q '\[Excluded\]'; then
    tmutil destinationinfo
    tmutil startbackup
  else
    echo "REFUSING: $EXTERNAL_DATA_VOLUME is not excluded from Time Machine." >&2
    echo "REFUSING: not starting a backup that would include the artifact drive." >&2
  fi
fi
EOF_TM_GATE
  echo '```'
} >> "$OUT/time-machine-plan.md"

cat >> "$OUT/time-machine-plan.md" <<'EOF_TM_TAIL'

Avoid starting a Time Machine backup while OneDrive is still doing a large initial sync, while Docker images are being restored, or while Company Portal / Intune is actively installing large apps.
EOF_TM_TAIL

cat > "$OUT/manual-captures-required.md" <<'EOF_MANUAL_FIRST_BOOT'
# Manual Captures Required After First Boot

The record-reimaged-system script captures command output and app/process evidence, but these items still require human confirmation.

**This file enumerates; it does not collect.** The rows are answered in the
sign-off under `reimaged-system/sign-offs/`, which carries an answer forward
across runs and records the run it was given against. Nothing is written back
into this bundle — a rerun stages a new run directory, so an answer left here
would be discarded by the next one.

Answer them in the **post-restart** sign-off. The restart row in particular
cannot be answered truthfully before the restart has happened.
`verify-reimaged-system.md` Step 7 is where that is done.

| Area | Manual Item | Why Manual |
|---|---|---|
| Microsoft 365 / O365 sign-in | Confirm sign-in completed during setup | CLI cannot prove the setup prompt was completed correctly. |
| Company Portal | Confirm device shows registered/compliant in UI | CLI can show enrollment evidence but not the full compliance state. |
| VPN / Zscaler | Confirm real internal sites load | Process/app presence does not prove internal access. |
| Managed app set | Confirm everything installed in Phase 8 Step 4 is still present, including nested bundles | Presence is scripted; whether the set is *complete for this Mac* is a Company Portal judgment. |
| OneDrive | Confirm the app is present. Sign-in and initial sync are deliberately deferred | Starting a large sync here collides with the Phase 9 restart, and the ordering against the Phase 15 home-file restore is not settled. |
| Chrome | Confirm default browser and JSON Formatter/important extensions | Browser settings/extensions are best verified in UI. |
| Terminal | Confirm Ocean profile/window size or chosen profile | CLI cannot prove the UI preference is visually correct. |
| Displays and peripherals | Confirm arrangement, scaling, keyboard, mouse, audio | System information does not prove physical usability. |
| Restart checkpoint | Confirm the second stabilization restart happened | Script can be rerun after restart, but cannot know user intent. |
EOF_MANUAL_FIRST_BOOT

# ---------------------------------------------------------------------------
# Generate the initial record and README summary
# ---------------------------------------------------------------------------
sed_escape() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

replace_token() {
  local file="$1"
  local token="$2"
  local value="$3"
  local escaped
  escaped="$(sed_escape "$value")"
  sed -i.bak "s|$token|$escaped|g" "$file" && rm -f "$file.bak"
}

cat > "$RECORD" <<'EOF_RECORD'
# Reimaged System Initial Record

Generated: __GENERATED_DATE__

Source script: `__SCRIPT_NAME__`

Context: `__CONTEXT__`

Output bundle:

~~~text
__OUT__
~~~

## Artifact Policy

| Item | Location |
|---|---|
| Capture runbook | `verify-reimaged-system.md` |
| Script | `bin/record-reimaged-system.sh` |
| Generated evidence bundle | `__OUTPUT_ROOT__/restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/` |
| Preferred generated-artifact root | `__ARTIFACT_ROOT__/reimaged-system/` when the artifact drive is mounted |
| Local fallback if the artifact drive is unavailable | `~/Desktop/reimaged-system-artifacts/` |

Keep active scripts in the toolkit checkout. Store generated evidence, capture records, and reimaged-system comparison outputs under the artifact root.

## Automated Checks

| Check | Result | Evidence |
|---|---|---|
| MDM / Intune enrollment appears active | `__MDM_STATUS__` | `raw/profiles-enrollment.txt` |
| FileVault status captured and appears on | `__FILEVAULT_STATUS__` | `raw/filevault.txt` |
| Company Portal app present | `__COMPANY_PORTAL_STATUS__` | `raw/applications-managed.txt` |
| Zscaler app present | `__ZSCALER_STATUS__` | `raw/applications-managed.txt` |
| CrowdStrike/Falcon app present | `__CROWDSTRIKE_APP_STATUS__` | `raw/applications-managed.txt` |
| CrowdStrike/Falcon process present | `__CROWDSTRIKE_PROC_STATUS__` | `raw/managed-processes.txt` |
| Microsoft Office apps present (Phase 8 Step 5) | `__OFFICE_STATUS__` | `raw/applications-managed.txt` |
| OneDrive app present (sign-in deliberately deferred) | `__ONEDRIVE_STATUS__` | `raw/applications-managed.txt` |
| Chrome app present | `__CHROME_STATUS__` | `raw/applications-managed.txt` |
| External artifact root visible | `__ARTIFACT_ROOT_STATUS__` | `raw/artifact-root-spotcheck.txt` |
| Time Machine destination captured | `__TM_DEST_STATUS__` | `raw/time-machine-destination.txt` |
| Git available (installed in Phase 10A) | `__GIT_STATUS__` | `raw/git-version.txt` |
| Homebrew available (installed in Phase 10A) | `__BREW_STATUS__` | `raw/brew-version.txt` |
| Network check | `__NETWORK_STATUS__` | `raw/network-github.txt` |

## Manual First-Boot Rows

The rows a person answers are not in this file. Rerunning this script stages a
new run directory, so an answer recorded here would come back as a fresh `TODO`.
They live in the sign-off, which carries answers forward and records the run each
was answered against:

    __SIGNOFF_FILE__

A row closed as `no` or `accepted` is a decision and counts as answered; the
check is for rows nobody looked at.

## Recommended Next Actions

1. Review `raw/profiles-enrollment.txt`, `raw/filevault.txt`, and `raw/applications-managed.txt`.
2. If any automated row above reads `TODO` for a managed app, finish
   `enroll-and-stabilize.md` Step 4 and rerun this script **before** restarting —
   this bundle is the pre-restart baseline the comparison depends on.
3. Restart once after managed enrollment, the managed app set, and security tools are all stable.
4. Rerun this script after the restart, compare results, and complete the manual rows in that newer capture.
5. Do **not** take a Time Machine backup here. The post-image backup is Phase 16,
   after Phase 15 restores your home directory — a backup taken now would capture
   a machine holding nothing that re-enrolling could not reproduce, and would miss
   the home files entirely. Until then the pre-image Time Machine chain is the
   fallback.

EOF_RECORD

replace_token "$RECORD" "__SIGNOFF_FILE__" "$SIGNOFF_FILE"
replace_token "$RECORD" "__GENERATED_DATE__" "$(date)"
replace_token "$RECORD" "__SCRIPT_NAME__" "$SCRIPT_NAME"
replace_token "$RECORD" "__CONTEXT__" "${CONTEXT_LABEL:-(none supplied)}"
replace_token "$RECORD" "__OUT__" "$OUT"
replace_token "$RECORD" "__OUTPUT_ROOT__" "$OUTPUT_ROOT"
replace_token "$RECORD" "__ARTIFACT_ROOT__" "${REIMAGE_ARTIFACT_ROOT:-<unset>}"
replace_token "$RECORD" "__MDM_STATUS__" "$MDM_STATUS"
replace_token "$RECORD" "__FILEVAULT_STATUS__" "$FILEVAULT_STATUS"
replace_token "$RECORD" "__COMPANY_PORTAL_STATUS__" "$COMPANY_PORTAL_STATUS"
replace_token "$RECORD" "__ZSCALER_STATUS__" "$ZSCALER_STATUS"
replace_token "$RECORD" "__CROWDSTRIKE_APP_STATUS__" "$CROWDSTRIKE_APP_STATUS"
replace_token "$RECORD" "__CROWDSTRIKE_PROC_STATUS__" "$CROWDSTRIKE_PROC_STATUS"
replace_token "$RECORD" "__OFFICE_STATUS__" "$OFFICE_STATUS"
replace_token "$RECORD" "__ONEDRIVE_STATUS__" "$ONEDRIVE_STATUS"
replace_token "$RECORD" "__CHROME_STATUS__" "$CHROME_STATUS"
replace_token "$RECORD" "__ARTIFACT_ROOT_STATUS__" "$ARTIFACT_ROOT_STATUS"
replace_token "$RECORD" "__TM_DEST_STATUS__" "$TM_DEST_STATUS"
replace_token "$RECORD" "__GIT_STATUS__" "$GIT_STATUS"
replace_token "$RECORD" "__BREW_STATUS__" "$BREW_STATUS"
replace_token "$RECORD" "__NETWORK_STATUS__" "$NETWORK_STATUS"

cat > "$SUMMARY" <<'EOF_SUMMARY'
# Reimaged System First-Boot Evidence Bundle

Generated: __GENERATED_DATE__

Open first:

- `record.md`
- `restart-checkpoints.md`
- `time-machine-plan.md`
- `manual-captures-required.md`

Raw captures are under `raw/`. Command and error logs are under `logs/`.

This bundle is generated evidence. The runbook source of truth is `verify-reimaged-system.md`; the script source of truth is `bin/record-reimaged-system.sh`.
EOF_SUMMARY

replace_token "$SUMMARY" "__GENERATED_DATE__" "$(date)"

# Index the run. The single `latest-*.txt` pointer this
# script used to write is gone: one pointer cannot name three lineages --
# initial, pre-restart, post-restart -- and naming whichever ran last is
# precisely the bug that made verify-reimaged-system.md Step 6 hand-roll its own
# prefix-filtered selection. `official/<context>.txt` answers per lineage.
# The fifteen rows a person answers. They were a table inside the record until
# this revision; the wording is unchanged so a carried answer still matches its
# item. `signoff_begin` copies the previous run's file forward, so an answer
# given against an earlier capture survives this one.
signoff_row "Mac restarted after erase" ""
signoff_row "Wi-Fi connected" ""
signoff_row "Microsoft 365 / O365 sign-in completed" ""
signoff_row "Company Portal signed in" ""
signoff_row "Device shows registered / compliant" ""
signoff_row "Required profiles/certificates visible" ""
signoff_row "VPN or Zscaler works for internal sites" ""
signoff_row "Managed app set installed from the Company Portal Apps tab (Phase 8 Step 5)" ""
signoff_row "macOS updates checked/applied" ""
signoff_row "Second stabilization restart completed" ""
signoff_row "External artifact drive reconnected after enrollment stabilized" ""
signoff_row "Chrome opens and can reach an internal site" "Bookmarks, profiles and saved passwords arrive in restore-apps.md (Phase 12), not here."
signoff_row "Terminal opens and the login shell is the expected one" "Profile, font and window size arrive in restore-apps.md (Phase 12), not here."
signoff_row "Display/keyboard/mouse basics work" ""
signoff_row "Ready to move to Phase 10 runtime environment restore" ""
# ARTIFACT_RUN_FINAL_DIR, not ARTIFACT_RUN_DIR: the run is staged at
# runs/.<id>.incomplete and promoted afterwards, so a path quoted for a
# reader has to be the promoted one. Revision 150 settled this in
# bin/restore-repos.sh; the sign-offs already on the volume carry the
# staging path because these four did not follow it.
signoff_finalize "Phase 9" "$ARTIFACT_RUN_FINAL_DIR/record.md"

RUN_PASS="$(grep -c '`PASS`' "$RECORD" 2>/dev/null || true)"
RUN_WARN="$(grep -c '`WARN`' "$RECORD" 2>/dev/null || true)"
# Automated rows only now -- the manual ones are in the sign-off. A `TODO` here
# is a probe that could not answer, not a person who has not looked.
RUN_TODO="$(grep -c '`TODO`' "$RECORD" 2>/dev/null || true)"

if ! artifact_run_finalize "$RUN_CATEGORY_ROOT" \
     "${RUN_PASS:-0} pass / ${RUN_WARN:-0} warn / ${RUN_TODO:-0} todo" "$RUN_NOTE"; then
  echo "ERROR: the bundle was written but artifact-runs reported a problem indexing it — see above." >&2
  exit 2
fi
# finalize promotes the staging directory, so the paths must be re-derived.
OUT="$ARTIFACT_RUN_DIR"
RECORD="$OUT/record.md"

echo ""
echo "First-boot evidence bundle written: $OUT"
echo "Open record: $RECORD"
echo "Run indexed at: $RUN_CATEGORY_ROOT/MANIFEST.md"

if [[ "$OPEN_RESULT" == "true" ]]; then
  open "$OUT" 2>/dev/null || true
fi
