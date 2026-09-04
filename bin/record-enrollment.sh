#!/usr/bin/env bash
# =============================================================================
# record-enrollment.sh
#
# Phase 8 — Enroll and Stabilize evidence recorder. Runs read-only managed-
# baseline queries (MDM enrollment, configuration profiles, FileVault, installed
# applications and managed processes, macOS version, pending software updates,
# Keychain identities),
# writes each result to a raw/NN-*.txt file, compares the installed application
# set against the pre-image managed-inventory capture, then generates a Markdown
# record with the Phase 8 exit-criteria table prefilled for the
# command-verifiable rows.
#
# The expected managed application set is derived from the run named by
# $REIMAGE_ARTIFACT_ROOT/managed-inventory/official/pre-image.txt, never from a
# list of vendor names
# held in this script. A hardcoded list cannot know what this particular Mac was
# assigned, and silently scores PASS on a machine missing an entire app suite.
# When the artifact volume is not mounted the comparison has no source and the
# row is stamped TODO rather than PASS — "could not check" and "checked and
# fine" must not look the same.
#
# An absence is never GRADED here, only counted and matched against the
# decisions log. Deciding whether an absent entry is a superseded management
# stack, an agent still rolling out, a version-pinned receipt, or a genuine gap
# is a judgement a script cannot make -- but it is a judgement someone has often
# already made and written down, and re-deriving it every run is how a wrong
# conclusion gets carried forward as settled. `bin/record-decision.sh` holds
# those answers; this reads them back.
#
# This script records evidence and applies small heuristic PASS/WARN verdicts
# on the command-verifiable rows only. The truly human-judgment rows (Company
# Portal UI state, first stabilization restart completed, whether the managed
# app set matches current company policy) are left as TODO for you to close by
# hand after the restart checkpoint. See enroll-and-stabilize.md for the full
# runbook.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/record-enrollment.sh
#
#   # Default -- writes under $REIMAGE_ARTIFACT_ROOT if it resolves and is
#   # mounted, otherwise falls back to $REIMAGE_WORKSPACE_ROOT, otherwise to
#   # ~/Desktop/reimaged-system-artifacts/enrollment/.
#   ./bin/record-enrollment.sh
#
#   # Reveal the generated Markdown record in Finder after completion.
#   ./bin/record-enrollment.sh --open
#
#   # Override the artifact root for this invocation.
#   ./bin/record-enrollment.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Override the workspace root used for the local fallback path.
#   ./bin/record-enrollment.sh --workspace-root /path/to/reimage-workspace
#
#   # Write to an exact category root (skips the reimaged-system/restarts
#   # layout and the fallback chain entirely; runs/ is still created under it).
#   ./bin/record-enrollment.sh --output /absolute/path/to/output
#
#   # Point the managed-application comparison at a specific inventory capture.
#   ./bin/record-enrollment.sh --managed-inventory /path/to/managed-inventory/runs/pre-image-<stamp>
#
#   # Label the run so the two records around the stabilization restart are
#   # distinguishable on disk without opening them. Matches the --context
#   # convention already used by report-loose-secrets.sh.
#   ./bin/record-enrollment.sh --context pre-restart     # Step 6
#   ./bin/record-enrollment.sh --context post-restart    # Step 8
#
#   # Bookend modes. These capture no evidence: they record what was decided
#   # about it, into reimaged-system/bookends/.
#   ./bin/record-enrollment.sh --context entry           # Step 2
#   ./bin/record-enrollment.sh --context exit            # Step 9
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --workspace-root PATH Override REIMAGE_WORKSPACE_ROOT for the fallback path.
#   --output DIR          Exact output directory for generated files.
#   --managed-inventory DIR
#                         Override the pre-image managed-inventory BUNDLE used to
#                         derive the expected application set — one run directory
#                         holding the numbered section files, not the category
#                         root. Default: the run named by
#                         managed-inventory/official/pre-image.txt.
#   --context LABEL       The run's point. Conventional values are pre-restart
#                         and post-restart; omitted, the run is `initial`.
#                         `entry` and `exit` select the bookend modes instead
#                         of an evidence capture -- see Bookend modes below.
#                         Letters, digits, dot, underscore, and hyphen only.
#   --note TEXT           Free text recorded in the manifest's `Note` column for
#                         this run. Use it when a run is written well after the
#                         phase it records -- a bookend added retrospectively is
#                         well-formed and its timestamp is the recorder's, not
#                         the phase's, and nothing else can say so.
#   --open                Reveal the generated record in Finder on completion.
#   -h, --help            Show this message and exit.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Run naming:
#   runs/enroll-and-stabilize-<point>-YYYYMMDD-HHMMSS/
#     record.md   the rendered record
#     raw/        the twelve numbered evidence files
#
#   The runbook name leads and the point follows it, so one lineage sorts
#   chronologically and `official/enroll-and-stabilize-<point>.txt` answers
#   "which run counts" per point. Nothing needs to rank a mixed set by hand,
#   which is what the old label-first naming forced on every reader.
#
#   There is no per-run MANIFEST.txt: it listed the same twelve files every
#   time and duplicated what `raw/` already shows. The category's MANIFEST.md
#   is the index that matters.
#
# Output location precedence (used only when --output is not supplied):
#   1. $REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts/
#        when REIMAGE_ARTIFACT_ROOT is set and currently mounted.
#   2. $REIMAGE_WORKSPACE_ROOT/restarts/
#        when the artifact root is not yet available and a workspace is set.
#   3. ~/Desktop/reimaged-system-artifacts/restarts/
#        as a final fallback so Phase 8 can complete on a bare Mac before the
#        external artifact volume is reconnected.
#
# Bookend modes:
#   `--context entry` and `--context exit` write a bookend to
#   reimaged-system/bookends/ under enroll-and-stabilize-{entry,exit}, in the
#   same category and grammar the restore phases use. They probe nothing that an
#   evidence run already recorded: the exit bookend reads the official
#   post-restart run's rows.tsv, so it cannot disagree with the record it cites.
#
#   Entry is recorded after Step 2, not at Step 0. Phase 8 starts on a Mac with
#   no toolkit on it -- $FRACTOGENESIS_HOME and reimage.env are what Steps 1 and
#   2 create, and this script is not on the machine before them.
#
# Exit status:
#   0  Evidence recorded successfully, or the bookend has no FAIL row.
#   1  Evidence capture ran but a generated file could not be written; or, in a
#      bookend mode, the bookend was written and carries at least one FAIL.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

# Normal operational entrypoint, not an aggregate validator: each read-only
# probe below is individually guarded with `|| true`, so `set -e` only fires on
# the directory/file writes that must succeed for the record to be usable.
set -euo pipefail

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

# Phase 8 typically runs on a freshly reimaged Mac where the external artifact
# volume may not be mounted yet. Keep loading permissive so the local fallback
# path can still succeed.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

# Shared run index. The enrollment records are indexed runs under
# reimaged-system/restarts/ alongside record-reimaged-system.sh's first-boot
# bundles: both capture the machine on one side of a stabilization restart, so
# they belong to one lineage keyed by point rather than to two categories that
# have to be read together.
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

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

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

# ---------------------------------------------------------------------------
# Defaults and command-line parsing
# ---------------------------------------------------------------------------
STAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_DIR=""
OUTPUT_DIR_EXPLICIT=""
OPEN_RESULT=false
# Free text for the manifest Note column. Empty unless --note is given, and the
# library writes an em dash for an empty note, so the default is not special.
RUN_NOTE=""
MANAGED_INVENTORY_DIR=""
CONTEXT_LABEL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --workspace-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_WORKSPACE_ROOT="$2"
      shift 2
      ;;
    --output)
      require_option_value "$1" "${2:-}"
      OUTPUT_DIR="$2"
      OUTPUT_DIR_EXPLICIT="$2"
      shift 2
      ;;
    --managed-inventory)
      require_option_value "$1" "${2:-}"
      MANAGED_INVENTORY_DIR="$2"
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
# Resolve output directory (fallback chain when --output is not supplied)
# ---------------------------------------------------------------------------
# Run ids are <runbook>-<point>-<stamp>, so one lineage sorts chronologically and
# the stamp trails -- which is what reimage-checklist.sh extracts to compare
# evidence age against the Time Machine backup. Readers do not glob for a run at
# all: official/<context>.txt names the one that counts, per point.
# The context label becomes the run's POINT, so `--context pre-restart` lands in
# the pre-restart lineage with no further mapping. A run with no context gets
# `initial`, which is NOT a known point and indexes as `unknown` -- the honest
# answer, since nothing recorded which side of a restart it was on. This mirrors
# record-reimaged-system.sh exactly; the two scripts share the category.
if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system"
elif [[ -n "${REIMAGE_WORKSPACE_ROOT:-}" && -d "${REIMAGE_WORKSPACE_ROOT:-}" ]]; then
  OUTPUT_ROOT="$REIMAGE_WORKSPACE_ROOT"
else
  OUTPUT_ROOT="$HOME/Desktop/reimaged-system-artifacts"
fi

if [[ -z "$OUTPUT_DIR" ]]; then
  if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
    OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system"
  elif [[ -n "${REIMAGE_WORKSPACE_ROOT:-}" && -d "$REIMAGE_WORKSPACE_ROOT" ]]; then
    OUTPUT_ROOT="$REIMAGE_WORKSPACE_ROOT"
  else
    OUTPUT_ROOT="$HOME/Desktop/reimaged-system-artifacts"
  fi
  OUTPUT_DIR="$OUTPUT_ROOT/restarts"
fi

# Resolve a relative --output against the current directory before the guard
# below compares it with the repo root. A relative path can never match
# "$REPO_ROOT"/*, so without this the guard is bypassed by `--output subdir`
# run from the checkout. The directory need not exist yet, so this is a plain
# textual prefix rather than a realpath() call (also keeps Bash 3.2 support).
case "$OUTPUT_DIR" in
  /*) ;;
  *) OUTPUT_DIR="$PWD/$OUTPUT_DIR" ;;
esac

# Safety invariant: refuse to write generated output under the repo checkout.
# A record landing inside the working tree is almost always an unset or
# relative root variable, not a real destination.
if [[ -n "${REPO_ROOT:-}" && ( "$OUTPUT_DIR" == "$REPO_ROOT" || "$OUTPUT_DIR" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $OUTPUT_DIR" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Bookend modes: --context entry and --context exit
#
# These do not capture evidence. They record what was decided about it, into
# reimaged-system/bookends/ under enroll-and-stabilize-{entry,exit}, the same
# category and grammar the restore phases use. Kept in this script rather than a
# new one because the questions are Phase 8's and the exit bookend is built
# from this script's own rows.tsv -- splitting them would mean two files sharing
# one definition of what a Phase 8 row means.
#
# Entry is recorded after Step 2, not at Step 0. Phase 8 begins on a Mac with no
# toolkit on it: $FRACTOGENESIS_HOME and reimage.env are what Steps 1 and 2
# create, and this script does not exist on the machine before them. Step 2 is
# the first moment there is anything to run.
#
# Self-contained helpers: the evidence path's status_pass_warn and friends are
# defined further down, after this dispatch point, so nothing here may call them.
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

bookend_entry() {
  local out

  if [[ -n "${FRACTOGENESIS_HOME:-}" && -d "${FRACTOGENESIS_HOME:-}" ]]; then
    b_record PASS "Toolkit root resolved" "\`$FRACTOGENESIS_HOME\`"
  else
    b_record FAIL "Toolkit root resolved" "\`FRACTOGENESIS_HOME\` unset or not a directory — Steps 1 and 2 are what set it; do not continue past this row"
  fi

  if [[ -f "${FRACTOGENESIS_HOME:-/nonexistent}/reimage.env" ]]; then
    b_record PASS "reimage.env restored" "present in the toolkit root"
  else
    b_record WARN "reimage.env restored" "not found — the jump-drive copy has not been placed yet; every later root variable falls back to a default"
  fi

  if /sbin/ping -c 1 -t 5 8.8.8.8 >/dev/null 2>&1; then
    b_record PASS "Network reachable" "ICMP to 8.8.8.8"
  else
    b_record FAIL "Network reachable" "no route — enrollment, managed installs and macOS updates all need it"
  fi

  if [[ -d "/Applications/Company Portal.app" ]]; then
    b_record PASS "Company Portal installed" "/Applications/Company Portal.app"
  else
    b_record FAIL "Company Portal installed" "absent — it is the only sanctioned install channel for managed apps, and the Apps tab is where Available assignments are found"
  fi

  out="$(profiles status -type enrollment 2>&1 | head -2 | tr '\n' ' ' || true)"
  b_record PASS "Enrollment status readable" "${out:-no output} — recorded as entry state, not as a requirement"

  out="$( { sw_vers -productVersion 2>/dev/null || true; } | tr -d '\n') ($( { sw_vers -buildVersion 2>/dev/null || true; } | tr -d '\n'))"
  b_record PASS "macOS build at entry" "$out"

  if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    b_record PASS "Artifact root mounted" "\`$REIMAGE_ARTIFACT_ROOT\`"
  else
    b_record WARN "Artifact root mounted" "not mounted — expected here. Phase 8 completes on the workspace or Desktop fallback and Phase 9 Step 1 relocates what it wrote"
  fi

  b_manual "Signed into the company account" "The Microsoft 365 sign-in prompted during Setup Assistant was completed with the company account, not a personal one."
  b_manual "Cheatsheet or jump drive was available" "One of the two is required: the emailed cheatsheet carries \`TOOLKIT_GITHUB_ACCOUNT\` for the network route, the Phase 6A jump drive carries \`bootstrap.sh\` and the \`reimage.env\` copy."
}

bookend_exit() {
  local restarts_root pr_run pr_dir rows check status detail

  restarts_root="$OUTPUT_ROOT/restarts"
  pr_run="$(artifact_run_official "$restarts_root" "enroll-and-stabilize-post-restart" 2>/dev/null || true)"
  pr_dir=""
  [[ -n "$pr_run" ]] && pr_dir="$restarts_root/$pr_run"

  if [[ -n "$pr_dir" && -d "$pr_dir" ]]; then
    b_record PASS "Post-restart baseline recorded" "\`$(basename "$pr_dir")\`"
  else
    b_record FAIL "Post-restart baseline recorded" "no official \`enroll-and-stabilize-post-restart\` run under \`restarts/\` — run \`./bin/record-enrollment.sh --context post-restart\` after the restart, then rerun this"
  fi

  if [[ -n "$(artifact_run_official "$restarts_root" "enroll-and-stabilize-pre-restart" 2>/dev/null || true)" ]]; then
    b_record PASS "Pre-restart baseline recorded" "the pair is complete, so the restart has something to be compared across"
  else
    b_record WARN "Pre-restart baseline recorded" "no official \`enroll-and-stabilize-pre-restart\` run — the post-restart record stands alone and nothing establishes what changed across the restart"
  fi

  # The verdicts come from the post-restart run's rows.tsv rather than being
  # re-probed here: this bookend is a statement about the recorded evidence,
  # and re-probing would let it disagree with the record it cites.
  rows="$pr_dir/rows.tsv"
  if [[ -f "$rows" ]]; then
    while IFS="$(printf '\t')" read -r check status detail; do
      case "$check" in
        check|'') continue ;;
        filevault)
          if [[ "$status" == "PASS" ]]; then
            b_record PASS "FileVault is on" "$detail"
          else
            b_record FAIL "FileVault is on" "recorded \`$status\` — Phase 14 fails sign-off if this stays off"
          fi
          ;;
        enrollment)      b_record "$status" "Enrollment completed" "$detail" ;;
        profiles)        b_record "$status" "Required profiles and certificates present" "$detail" ;;
        macos-updates)   b_record "$status" "macOS updates complete or deferred" "$detail" ;;
        managed-apps)
          # One row name for both outcomes. PASS no longer means "nothing was
          # absent" -- it also covers absences every one of which a decision
          # names -- so a title asserting the set MATCHES would have been false
          # in exactly the case the decisions log exists to produce. The detail
          # says which kind of pass it is.
          if [[ "$status" == "PASS" ]]; then
            b_record PASS "Managed application set is accounted for" "$detail"
          else
            b_manual "Managed application set is accounted for" "$detail — see \`raw/08-managed-app-expectations.txt\` for which. Absences already named by the decisions log are marked \`[decided]\` there and are not being asked about again. For each one still open: it is a superseded management stack, a repackaged component, a version-pinned receipt, an agent still rolling out, an application Phase 12 restores on schedule — or a genuine gap to raise with IT. Record the answer with \`./bin/record-decision.sh --runbook enroll-and-stabilize --excepts enroll-and-stabilize-managed-apps:<entry>\` so this row stops re-asking it."
          fi
          ;;
      esac
    done < "$rows"
  else
    b_record WARN "Recorded verdicts readable" "no \`rows.tsv\` in the post-restart run — it predates the split that produced one, so its verdicts cannot be read without reparsing \`record.md\`"
  fi

  b_manual "Company Portal shows the expected state" "Opened, device listed, and the Apps tab shows nothing this Mac needs still listed as installable."
  b_manual "Required security tools are installed or actively installing" "Managed app and process checks plus a visual sanity review — an agent mid-install looks the same as one that failed."
  b_manual "First stabilization restart completed" "Observed restart and a successful return to the login session."
  b_manual "Keychain identities re-issued" "Count and shape match the pre-image record. Fingerprints will differ — MDM re-issues these rather than restoring them."
}

if [[ "${CONTEXT_LABEL:-}" == "entry" || "${CONTEXT_LABEL:-}" == "exit" ]]; then
  BOOKEND_ROOT="$OUTPUT_ROOT/bookends"
  [[ -n "$OUTPUT_DIR_EXPLICIT" ]] && BOOKEND_ROOT="$OUTPUT_DIR_EXPLICIT"

  echo "Recording the Phase 8 $CONTEXT_LABEL bookend ..." >&2
  if [[ "$CONTEXT_LABEL" == "entry" ]]; then bookend_entry; else bookend_exit; fi

  if ! artifact_run_begin "$BOOKEND_ROOT" "enroll-and-stabilize-$CONTEXT_LABEL"; then
    echo "ERROR: cannot stage a bookend run under: $BOOKEND_ROOT" >&2
    exit 2
  fi

  BOOKEND_FILE="$ARTIFACT_RUN_DIR/bookend.md"

  # Opened before the bookend is written so SIGNOFF_FILE resolves for the
  # pointer below. The sign-off is named for this run, which is what lets a
  # carried answer say which run it was given against.
  SIGNOFF_ROOT="$OUTPUT_ROOT/sign-offs"
  if ! signoff_begin "$SIGNOFF_ROOT" "enroll-and-stabilize-$CONTEXT_LABEL" "$ARTIFACT_RUN_ID"; then
    artifact_run_abort
    echo "ERROR: cannot open a sign-off under: $SIGNOFF_ROOT" >&2
    exit 2
  fi

  {
    printf '# enroll-and-stabilize — %s Criteria — %s\n\n' "$CONTEXT_LABEL" "$ARTIFACT_RUN_STAMP"
    printf 'Generated by `bin/record-enrollment.sh --context %s` on %s.\n\n' "$CONTEXT_LABEL" "$(date)"
    printf 'Pairs with [[enroll-and-stabilize|enroll-and-stabilize.md]].\n\n'
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
    printf -- '- The Automated rows restate what the recorded evidence says; they do not re-probe the machine, so this bookend cannot disagree with the run it cites.\n'
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
  signoff_finalize "Phase 8" "$ARTIFACT_RUN_FINAL_DIR/bookend.md"

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

RUN_CATEGORY_ROOT="$OUTPUT_DIR"
RUN_CONTEXT="enroll-and-stabilize-${CONTEXT_LABEL:-initial}"

if ! artifact_run_begin "$RUN_CATEGORY_ROOT" "$RUN_CONTEXT"; then
  echo "ERROR: cannot stage an enrollment run under: $RUN_CATEGORY_ROOT" >&2
  echo "ERROR: no evidence was written. Choose a writable --output (or reconnect the artifact volume) and rerun." >&2
  exit 2
fi
OUT="$ARTIFACT_RUN_DIR"
RAW_DIR="$OUT/raw"
if ! mkdir -p "$RAW_DIR"; then
  echo "ERROR: cannot create the enrollment record directory: $OUT" >&2
  artifact_run_abort
  exit 2
fi

# ---------------------------------------------------------------------------
# Evidence capture helpers
# ---------------------------------------------------------------------------
record_cmd() {
  # Run a direct command and record stdout+stderr to a numbered raw file.
  local title="$1"
  local file="$2"
  shift 2
  echo "▶  $title ..."
  {
    echo "# $title"
    echo "# Generated: $(date)"
    echo "# Command: $*"
    echo ""
    "$@"
  } > "$RAW_DIR/$file" 2>&1 || true
  echo "   ✓ saved → raw/$file"
}

record_pipeline() {
  # Run a shell pipeline (used only for grep-based filters) and record the
  # result. Kept small and readable; avoids a login shell so profile output
  # cannot leak into the recorded evidence.
  local title="$1"
  local file="$2"
  local cmd="$3"
  echo "▶  $title ..."
  {
    echo "# $title"
    echo "# Generated: $(date)"
    echo "# Command: $cmd"
    echo ""
    bash -c "$cmd"
  } > "$RAW_DIR/$file" 2>&1 || true
  echo "   ✓ saved → raw/$file"
}

# ---------------------------------------------------------------------------
# Record raw evidence
# ---------------------------------------------------------------------------
record_cmd      "Enrollment status"              "01-enrollment-status.txt"     profiles status -type enrollment
# `profiles list` unprivileged returns USER-level profiles only. The managed
# baseline lives at _computerlevel, so the number that matters needs root --
# 4 user profiles versus 17 system ones on a typical enrolled Mac.
#
# `sudo -n` never prompts: it succeeds if a sudo credential is already cached
# and fails immediately otherwise. That keeps this script non-interactive, which
# is the whole reason it can be rerun freely, while still capturing the system
# scope whenever the operator has recently used sudo. The fallback records the
# user scope and says which one it got.
record_pipeline "Configuration profiles list"    "02-profiles-list.txt" \
  "if sudo -n profiles list 2>/dev/null; then echo; echo '# scope: system (_computerlevel), via sudo -n'; else profiles list; echo; echo '# scope: user only -- no cached sudo credential. Rerun after any sudo command, or run: sudo profiles list'; fi"
record_cmd      "FileVault status"               "03-filevault-status.txt"      fdesetup status
# Record every application, not a vendor-name filter, and include one level of
# nesting: agents such as Zscaler install as /Applications/Zscaler/Zscaler.app
# and a top-level listing alone is a weaker signal than it appears. The full
# list is also what the managed-inventory comparison below reads.
record_pipeline "Applications present"           "04-managed-apps.txt" \
  "{ ls -1 /Applications 2>/dev/null; ls -1d /Applications/*/*.app 2>/dev/null | sed 's#^/Applications/##'; } | sort -u"
record_pipeline "Managed processes present"      "05-managed-processes.txt" \
  "ps aux | grep -Ei 'Intune|Company Portal|CrowdStrike|falcon|Zscaler|Microsoft AutoUpdate|MAU|mdmclient' | grep -v grep || true"
record_cmd      "macOS version and build"        "06-macos-version.txt"         sw_vers
record_cmd      "Available software updates"     "07-softwareupdate-list.txt"   softwareupdate --list

# Keychain identities: certificate + private key pairs. Captured in both the
# general and the ssl-client scopes because the pair of counts is what tells
# them apart -- an ssl-client identity also appears in the general listing, so
# the two numbers are nested, not additive.
#
# This is the only managed component with no restore path other than
# re-issuance: an identity whose private key refuses export cannot be restored
# from a .p12, from Time Machine, or from a disk image. After an erase the
# count is therefore the only evidence that MDM re-issued what it should have.
# Package receipts. The pre-image managed inventory records expectations as
# receipt identifiers, so matching against these is exact where matching app
# names is not: `com.microsoft.package.Microsoft_Word.app` is unambiguous,
# "Microsoft Word" is not.
record_cmd      "Installed package receipts"     "10-package-receipts.txt"     pkgutil --pkgs

# Launch agents and daemons, as absolute paths. The company-scoped inventory
# records background components this way -- /Library/LaunchDaemons/com.x.y.plist
# -- and no other capture contains that form, so without this every launchd
# entry in the expectation set reads as absent.
record_pipeline "Launchd managed components"     "11-launchd-components.txt" \
  "ls -1 /Library/LaunchAgents/*.plist /Library/LaunchDaemons/*.plist \"$HOME\"/Library/LaunchAgents/*.plist 2>/dev/null | sort -u"

# System extensions. Endpoint security agents ship as these rather than as
# kexts, and the company-scoped inventory records them, so without this capture
# an activated extension reads as absent.
record_pipeline "System extensions"              "12-system-extensions.txt" \
  "systemextensionsctl list 2>/dev/null || echo 'systemextensionsctl unavailable'"

record_pipeline "Keychain identities"            "09-keychain-identities.txt" \
  "echo '## security find-identity -v'; security find-identity -v; echo; echo '## security find-identity -v -p ssl-client'; security find-identity -v -p ssl-client"

# ---------------------------------------------------------------------------
# Managed application expectations, derived from the pre-image capture
# ---------------------------------------------------------------------------
# Resolve the inventory directory: explicit override first, then the artifact
# root. Phase 8 often runs before the external volume is reconnected, so an
# absent source is an ordinary outcome rather than an error.
#
# Resolve the PRE-IMAGE lineage by name. Phase 13C writes a post-image bundle
# into the same category, and this row asks what the Mac had BEFORE the erase --
# so searching the category for whichever section file sorted last would, once
# that bundle exists, compare the restored machine against itself and report a
# clean match on a machine missing an entire app suite.
if [[ -z "$MANAGED_INVENTORY_DIR" && -n "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  _mi_root="$REIMAGE_ARTIFACT_ROOT/managed-inventory"
  _mi_run="$(artifact_run_official "$_mi_root" pre-image 2>/dev/null || true)"
  if [[ -n "$_mi_run" ]]; then
    MANAGED_INVENTORY_DIR="$_mi_root/$_mi_run"
  fi
fi

EXPECT_FILE="$RAW_DIR/08-managed-app-expectations.txt"
MANAGED_APPS_STATUS="TODO"
MANAGED_APPS_MISSING_COUNT="0"
MANAGED_APPS_EXPECTED_COUNT="0"
MANAGED_APPS_DECIDED_COUNT="0"
MANAGED_APPS_OPEN_COUNT="0"
MANAGED_APPS_SOURCE="none"
# Set alongside the verdict once a comparison runs. The TODO wording is the one
# case where the counts mean nothing, so it does not quote them.
MANAGED_APPS_DETAIL="no pre-image source was reachable, so nothing was compared"

# The lineage `--excepts` references name for this comparison. It is deliberately
# NOT the run context: a decision is about an application, not about the run that
# happened to notice it, so one recorded during the post-restart run must still
# answer for the exit record. Using $RUN_CONTEXT here would have made every
# decision invisible to every other run of the same phase.
MANAGED_APPS_LINEAGE="enroll-and-stabilize-managed-apps"
MANAGED_APPS_DECIDED_LABELS=""

# Read the labels this lineage excepts out of the reimage event's decisions log.
# The shape mirrors compare-restored-state.sh, which reads the same file for the
# same reason: refs are rendered as `code spans`, so odd-indexed backtick fields
# are the references and even-indexed ones the separators between them.
#
# A missing or unreadable log is not an error. Decisions are optional, and a
# record that refused to run without one would be worse than the problem.
load_managed_app_decisions() {
  local log="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/reimaged-system/restore-notes/decisions.md"
  [[ -f "$log" ]] || return 0
  MANAGED_APPS_DECIDED_LABELS="$(awk -v ctx="$MANAGED_APPS_LINEAGE" '
    /^- \*\*Excepts:\*\*/ {
      n = split($0, part, "`")
      for (i = 2; i <= n; i += 2) {
        ref = part[i]
        c = index(ref, ":")
        if (c > 0 && substr(ref, 1, c - 1) == ctx) print substr(ref, c + 1)
      }
    }
  ' "$log" 2>/dev/null || true)"
  return 0
}

managed_app_is_decided() {
  [[ -n "$MANAGED_APPS_DECIDED_LABELS" ]] || return 1
  # Exact match only. An approximate one would quietly excuse the wrong entry,
  # which is strictly worse than excusing none -- `com.microsoft.MSTeams` must
  # not answer for `com.microsoft.MSTeamsAudioDevice`.
  printf '%s\n' "$MANAGED_APPS_DECIDED_LABELS" | grep -qxF -- "$1"
}

# Pick the narrowest usable expectation source. The capture writes several files
# per run; only some of them describe COMPANY-managed software, and reading the
# wrong one produces a large, meaningless miss count rather than an error.
#
# 03-installed-app-bundles.txt is deliberately never used: it lists every
# application the pre-image Mac had, so comparing it at Phase 8 reports the whole
# un-restored application set. That belongs to Phase 13C, after Phase 12 has put
# the applications back.
EXPECT_SOURCE_FILE=""
if [[ -n "$MANAGED_INVENTORY_DIR" && -d "$MANAGED_INVENTORY_DIR" ]]; then
  # Named directly in the resolved bundle rather than searched for. The bundle is
  # one run directory, so a search could only ever widen the answer beyond the
  # lineage that was just resolved.
  for _candidate in \
    "$MANAGED_INVENTORY_DIR/07-company-filter-pass.txt" \
    "$MANAGED_INVENTORY_DIR/04-installed-package-receipts.txt"
  do
    if [[ -f "$_candidate" ]]; then
      EXPECT_SOURCE_FILE="$_candidate"
      # The artifact-root-relative path, not the basename. The expectation file
      # lives in the pre-image managed-inventory bundle, NOT in this run's raw/ --
      # citing `07-company-filter-pass.txt` alone sends a reader looking for it
      # beside the twelve files that are here, where it has never been. An
      # explicit --managed-inventory can point outside the artifact root, and
      # there the absolute path is the only one that resolves.
      case "$_candidate" in
        "${REIMAGE_ARTIFACT_ROOT:-/dev/null}"/*) MANAGED_APPS_SOURCE="${_candidate#"${REIMAGE_ARTIFACT_ROOT:-}"/}" ;;
        *) MANAGED_APPS_SOURCE="$_candidate" ;;
      esac
      break
    fi
  done
fi

echo "▶  Managed application expectations ..."

# Gate on the SOURCE FILE, not just the directory. A managed-inventory tree
# that exists but holds no company-scoped file is "could not check", and
# scoring it PASS on an empty expectation set is the same defect this row
# was written to avoid.
if [[ -z "$EXPECT_SOURCE_FILE" || ! -f "$EXPECT_SOURCE_FILE" ]]; then
  {
    echo "# Managed application expectations"
    echo "# Generated: $(date)"
    echo "# Source: unavailable"
    echo ""
    if [[ -z "$MANAGED_INVENTORY_DIR" ]]; then
      echo "No official pre-image managed-inventory run was reachable, so the installed"
      echo "application set could not be compared against what this Mac had before"
      echo "the erase. This is expected when Phase 8 runs before the external"
      echo "artifact volume is reconnected in Phase 9."
      echo ""
      echo "When the volume is mounted, the pointer to resolve is:"
      echo ""
      echo "    managed-inventory/official/pre-image.txt"
    else
      echo "A managed-inventory bundle was found at:"
      echo ""
      echo "    $MANAGED_INVENTORY_DIR"
      echo ""
      echo "but it holds no company-scoped expectation file. Expected one of:"
      echo ""
      echo "    07-company-filter-pass.txt"
      echo "    04-installed-package-receipts.txt"
      echo ""
      echo "This row is left as TODO rather than PASS: an empty expectation set"
      echo "trivially matches, and reporting that as a pass would mean the check"
      echo "is loudest when it knows least."
    fi
    echo ""
    echo "To close this row, either rerun after reconnecting the drive:"
    echo ""
    echo "    ./bin/record-enrollment.sh --artifact-root \"\$REIMAGE_ARTIFACT_ROOT\""
    echo ""
    echo "or confirm the application set by hand against the Company Portal Apps"
    echo "tab and mark the row accordingly."
  } > "$EXPECT_FILE" 2>&1 || true
  echo "   • no managed-inventory source; row left as TODO"
else
  # Entries are one per line: package receipt identifiers, occasionally an app
  # name. Drop comments, section rules, and blanks; whatever is left is an
  # expectation. Parsing this way is format-agnostic, so a new section heading in
  # a later capture version does not silently change the result.
  EXPECTED_TMP="$RAW_DIR/.expected.$$"
  MISSING_TMP="$RAW_DIR/.missing.$$"
  HAYSTACK_TMP="$RAW_DIR/.haystack.$$"
  DECIDED_TMP="$RAW_DIR/.decided.$$"
  OPEN_TMP="$RAW_DIR/.open.$$"

  # Most sections list one identifier or one absolute path per line, but at least
  # one records command status lines verbatim -- for example
  #   * * X9E956P446 com.vendor.agent (1.0/2.0) Agent Name [activated enabled]
  # A whole line like that matches nothing, so it would always report as absent
  # while the software sits there activated. Reduce such lines to the
  # reverse-DNS identifier they contain; keep everything else as-is.
  #
  # The test for "is this a status line" is: it contains whitespace and does not
  # begin with a slash. Absolute paths keep their spaces, because bundle names
  # legitimately contain them.
  sed -e 's/[[:space:]]*$//' "$EXPECT_SOURCE_FILE" \
    | grep -v '^[[:space:]]*#' \
    | grep -v '^[[:space:]]*---' \
    | grep -v '^[[:space:]]*$' \
    | sed 's/^[[:space:]]*//' \
    | awk '
        /^\// { print; next }                       # absolute path: keep whole
        $0 !~ /[[:space:]]/ { print; next }         # bare identifier: keep whole
        {                                            # status line: pull out IDs
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z0-9_-]+){2,}$/) print $i
          }
        }' \
    | sort -uf > "$EXPECTED_TMP" || true

  # The company-scoped inventory is sectioned: package receipts, application
  # bundles, configuration profiles, background components, preference domains.
  # Matching all of those against receipts alone reports whole sections as
  # absent, so the haystack spans every capture that could contain any of them.
  cat "$RAW_DIR/10-package-receipts.txt" \
      "$RAW_DIR/11-launchd-components.txt" \
      "$RAW_DIR/12-system-extensions.txt" \
      "$RAW_DIR/04-managed-apps.txt" \
      "$RAW_DIR/02-profiles-list.txt" \
      "$RAW_DIR/05-managed-processes.txt" \
    > "$HAYSTACK_TMP" 2>/dev/null || true

  # Expectations arrive in two forms -- bare identifiers and absolute paths --
  # and the captures they must match against use whichever form is natural for
  # that command. `pkgutil` prints bare receipt IDs; `ls /Applications` prints
  # bare bundle names; the inventory records both of those as full paths. So a
  # miss on the literal string is retried against the basename before an entry
  # is called absent: /Applications/Microsoft Word.app is present on a Mac whose
  # application listing says "Microsoft Word.app".
  load_managed_app_decisions

  : > "$MISSING_TMP"
  : > "$DECIDED_TMP"
  : > "$OPEN_TMP"
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    if grep -Fqi "$item" "$HAYSTACK_TMP" 2>/dev/null; then
      continue
    fi
    item_base="${item##*/}"
    if [[ "$item_base" != "$item" ]] && grep -Fqi "$item_base" "$HAYSTACK_TMP" 2>/dev/null; then
      continue
    fi
    printf '%s\n' "$item" >> "$MISSING_TMP"
    if managed_app_is_decided "$item"; then
      printf '%s\n' "$item" >> "$DECIDED_TMP"
    else
      printf '%s\n' "$item" >> "$OPEN_TMP"
    fi
  done < "$EXPECTED_TMP"

  # wc -l rather than `grep -c .`: grep exits 1 on an empty file while still
  # printing 0, so a `|| echo 0` fallback would append a second zero and the
  # count would read "0\n0". Every line here is written with a trailing
  # newline, so wc -l is exact.
  MANAGED_APPS_MISSING_COUNT="$(wc -l < "$MISSING_TMP" | tr -d '[:space:]')"
  MANAGED_APPS_EXPECTED_COUNT="$(wc -l < "$EXPECTED_TMP" | tr -d '[:space:]')"
  MANAGED_APPS_DECIDED_COUNT="$(wc -l < "$DECIDED_TMP" | tr -d '[:space:]')"
  MANAGED_APPS_OPEN_COUNT="$(wc -l < "$OPEN_TMP" | tr -d '[:space:]')"

  {
    echo "# Managed application expectations"
    echo "# Generated: $(date)"
    echo "# Source: $EXPECT_SOURCE_FILE"
    echo "# Cited as: $MANAGED_APPS_SOURCE"
    echo "# Expected bundles found in inventory: $MANAGED_APPS_EXPECTED_COUNT"
    echo "# Not present on this Mac: $MANAGED_APPS_MISSING_COUNT"
    echo "# Of those, already accounted for in the decisions log: $MANAGED_APPS_DECIDED_COUNT"
    echo "# Still to account for: $MANAGED_APPS_OPEN_COUNT"
    echo ""
    echo "## Present pre-image, absent now"
    echo ""
    if [[ "$MANAGED_APPS_MISSING_COUNT" == "0" ]]; then
      echo "(none)"
    else
      # `decided` is appended, never substituted, and the entry stays in the
      # list: the machine still does not have it. What the marker adds is that
      # someone already weighed it and wrote down why.
      while IFS= read -r _absent; do
        [[ -z "$_absent" ]] && continue
        if managed_app_is_decided "$_absent"; then
          printf '%s  [decided]\n' "$_absent"
        else
          printf '%s\n' "$_absent"
        fi
      done < "$MISSING_TMP"
      echo ""
      if [[ "$MANAGED_APPS_DECIDED_COUNT" != "0" ]]; then
        echo "Entries marked [decided] are named by an entry in:"
        echo ""
        echo "    reimaged-system/restore-notes/decisions.md"
        echo ""
        echo "Read the reason with:"
        echo ""
        echo "    ./bin/record-decision.sh --check $MANAGED_APPS_LINEAGE"
        echo ""
      fi
      if [[ "$MANAGED_APPS_OPEN_COUNT" == "0" ]]; then
        echo "Every absence above is accounted for. Nothing here needs deciding again."
        echo ""
      fi
      echo ""
      echo "READ THIS BEFORE ACTING ON THE LIST ABOVE."
      echo ""
      echo "Expectations come from the company-scoped inventory, so these are"
      echo "management-stack components rather than ordinary applications."
      echo "These categories are absent for good reasons and are not findings:"
      echo ""
      echo "  - Components of a management stack this Mac no longer uses. A Mac"
      echo "    previously managed by a different tool carries its receipts;"
      echo "    re-enrolling into the current one will never bring them back, and"
      echo "    should not."
      echo "  - Agents that install later in the rollout. Required pushes are"
      echo "    asynchronous; rerun this record after the Step 7 restart before"
      echo "    treating anything here as missing."
      echo "  - Version-pinned receipts. An identifier carrying a version, such as"
      echo "    a vendor installer receipt, never matches once the vendor ships a"
      echo "    newer build -- the software is present, the receipt name moved."
      echo ""
      echo "Act on absences from the CURRENT stack -- security agents, Company"
      echo "Portal, the MDM agent. Install those from the Company Portal Apps tab,"
      echo "never from a vendor download."
      echo ""
      echo "Once you have decided what an absence is, record it so the next run"
      echo "does not ask again -- and so the reasoning survives being remembered"
      echo "wrong:"
      echo ""
      echo "    ./bin/record-decision.sh \\"
      echo "      --runbook enroll-and-stabilize \\"
      echo "      --title '<what this group of absences is>' \\"
      echo "      --excepts '$MANAGED_APPS_LINEAGE:<absent entry, exactly as listed above>' \\"
      echo "      --reason '<why it is absent, and why that is correct>'"
    fi
    echo ""
    echo "## Expected set derived from inventory"
    echo ""
    cat "$EXPECTED_TMP"
  } > "$EXPECT_FILE" 2>&1 || true

  rm -f "$EXPECTED_TMP" "$MISSING_TMP" "$HAYSTACK_TMP" "$DECIDED_TMP" "$OPEN_TMP"

  # A count, not a verdict. The expectation set is the pre-image COMPANY-scoped
  # inventory, which mixes two populations: software Intune pushes during this
  # phase, and company-scoped applications that Phase 12 restores. An absence in
  # the second is on schedule at Phase 8, so grading any absence as WARN reports
  # the normal case as a problem.
  #
  # It also cannot be graded here even for the first population. Deciding whether
  # an absent entry is deliberate -- a superseded management stack, a repackaged
  # component, a version-pinned receipt -- or a genuine gap needing a ticket is
  # exactly the judgement `record_manual` exists for. This run supplies the
  # evidence; the exit bookend asks the question.
  #
  # What CAN be answered here is whether the question has already been answered.
  # This row asks "is the managed application set accounted for", and an absence
  # named by a decision is accounted for by definition -- that is the whole claim
  # the decision makes. So a fully-decided set passes, and the detail says so
  # rather than reporting a bare zero, because "no absences" and "seven absences
  # someone has explained" are different facts and must not read the same.
  #
  # This is a weaker rule than compare-restored-state.sh's, deliberately. There a
  # decision cannot change the verdict, because the question is whether the
  # machine matches the image -- a fact about the machine. Here the question is
  # whether someone has accounted for the difference, which is exactly what the
  # decision records.
  if [[ "$MANAGED_APPS_MISSING_COUNT" == "0" ]]; then
    MANAGED_APPS_STATUS="PASS"
    MANAGED_APPS_DETAIL="0 absent of $MANAGED_APPS_EXPECTED_COUNT expected"
  elif [[ "$MANAGED_APPS_OPEN_COUNT" == "0" ]]; then
    MANAGED_APPS_STATUS="PASS"
    MANAGED_APPS_DETAIL="$MANAGED_APPS_MISSING_COUNT absent of $MANAGED_APPS_EXPECTED_COUNT expected, all accounted for in the decisions log"
  else
    MANAGED_APPS_STATUS="REVIEW"
    MANAGED_APPS_DETAIL="$MANAGED_APPS_MISSING_COUNT absent of $MANAGED_APPS_EXPECTED_COUNT expected, $MANAGED_APPS_OPEN_COUNT still to account for"
  fi
fi
echo "   ✓ saved → raw/08-managed-app-expectations.txt"

# ---------------------------------------------------------------------------
# Heuristic verdicts for the command-verifiable exit-criteria rows
# ---------------------------------------------------------------------------
file_contains() {
  local file="$1"
  local pattern="$2"
  grep -Eiq "$pattern" "$file" 2>/dev/null
}

status_pass_warn() {
  # Print PASS when the heuristic is satisfied, WARN otherwise. WARN is not the
  # same as FAIL — it means the recorded evidence did not obviously match the
  # expected pattern and needs a human look before the row is signed off.
  if [[ "$1" == "true" ]]; then
    printf 'PASS'
  else
    printf 'WARN'
  fi
}

# Match the affirmative answer, not the label. `profiles status -type
# enrollment` always prints the literal strings "MDM enrollment:" and
# "Enrolled via DEP:", including when both answers are No, so a bare
# 'enrolled|yes|mdm' pattern reports PASS on an unenrolled Mac. Same pattern
# used by record-reimaged-system.sh.
ENROLLMENT_OK="false"
if file_contains "$RAW_DIR/01-enrollment-status.txt" 'MDM enrollment: Yes|Enrolled via DEP: Yes|User Approved'; then
  ENROLLMENT_OK="true"
fi

# A root-required refusal from `profiles list` is non-empty output that names
# no profiles; without these patterns it scored as PASS.
PROFILES_OK="false"
if [[ -s "$RAW_DIR/02-profiles-list.txt" ]] \
  && ! file_contains "$RAW_DIR/02-profiles-list.txt" 'there are no configuration profiles installed|no configuration profiles|error|requires root|require root|need to be root|must be root|root privileges|not permitted|permission denied'; then
  PROFILES_OK="true"
fi

CROWDSTRIKE_OK="false"
ZSCALER_OK="false"
if file_contains "$RAW_DIR/04-managed-apps.txt" 'crowdstrike|falcon' \
  || file_contains "$RAW_DIR/05-managed-processes.txt" 'crowdstrike|falcon'; then
  CROWDSTRIKE_OK="true"
fi
if file_contains "$RAW_DIR/04-managed-apps.txt" 'zscaler' \
  || file_contains "$RAW_DIR/05-managed-processes.txt" 'zscaler'; then
  ZSCALER_OK="true"
fi
SECURITY_OK="false"
if [[ "$CROWDSTRIKE_OK" == "true" && "$ZSCALER_OK" == "true" ]]; then
  SECURITY_OK="true"
fi

# FileVault was already captured but had no row of its own, so the answer lived
# only in the raw file. reimage-checklist.sh --phase post FAILs sign-off when
# FileVault is off, and this is the first phase that could have said so.
FILEVAULT_OK="false"
if file_contains "$RAW_DIR/03-filevault-status.txt" 'FileVault is On'; then
  FILEVAULT_OK="true"
fi

# Configuration profile count. `profiles list` prints a trailing summary line
# only when run with sufficient privilege; unprivileged it prints little and no
# total, so an empty count here means "not readable", not "no profiles".
PROFILE_COUNT="$(grep -oE 'There (are|is) [0-9]+' "$RAW_DIR/02-profiles-list.txt" 2>/dev/null \
  | grep -oE '[0-9]+' | head -1 || true)"
PROFILE_COUNT="${PROFILE_COUNT:-unknown}"

# Say which scope the number describes. A user-scope count is not comparable to
# a system-scope one and reporting them identically invites exactly the wrong
# conclusion.
# Detect scope from the OUTPUT, never from the marker. record_pipeline writes a
# "# Command: ..." header quoting the whole pipeline -- which contains the literal
# words "scope: system" -- so any marker string is present in the file whether or
# not that branch ran. `_computerlevel` appears only in genuine system-scope
# output and cannot be echoed by the command line itself.
PROFILE_SCOPE="user"
if grep -q '^_computerlevel' "$RAW_DIR/02-profiles-list.txt" 2>/dev/null; then
  PROFILE_SCOPE="system"
fi

# Say something different depending on which scope was obtained. A note that
# tells you to rerun with sudo, printed on a run that already had sudo, teaches
# the reader to skip the notes.
if [[ "$PROFILE_SCOPE" == "system" ]]; then
  PROFILE_NOTE="System scope: the managed baseline. This is the number to record and to compare against on a later run."
else
  PROFILE_NOTE="User scope only -- no cached sudo credential when this ran, so the count covers your own profiles rather than the managed baseline, which is normally several times larger. Run \`sudo -v\` and rerun to capture it. \`unknown\` means not readable, not none."
fi

# Keychain identity counts, parsed from the trailing summary of each listing
# rather than by counting numbered lines -- the file holds two listings, so
# counting entries would silently add them together. Singular and plural forms
# both appear depending on the count.
IDENTITY_TOTAL="$(grep -oE '[0-9]+ valid identit(y|ies) found' "$RAW_DIR/09-keychain-identities.txt" 2>/dev/null \
  | head -1 | grep -oE '^[0-9]+' || true)"
IDENTITY_SSL="$(grep -oE '[0-9]+ valid identit(y|ies) found' "$RAW_DIR/09-keychain-identities.txt" 2>/dev/null \
  | tail -1 | grep -oE '^[0-9]+' || true)"
IDENTITY_TOTAL="${IDENTITY_TOTAL:-unknown}"
IDENTITY_SSL="${IDENTITY_SSL:-unknown}"

# A machine with zero identities after enrollment has not finished re-issuing
# them. Any non-zero count is reported rather than judged: how many this Mac
# should have is a site fact the script cannot know.
IDENTITIES_OK="false"
if [[ "$IDENTITY_TOTAL" != "unknown" && "$IDENTITY_TOTAL" != "0" ]]; then
  IDENTITIES_OK="true"
fi

UPDATES_OK="false"
if file_contains "$RAW_DIR/07-softwareupdate-list.txt" 'No new software available'; then
  UPDATES_OK="true"
fi

POST_RESTART_OK="false"
if [[ "$ENROLLMENT_OK" == "true" && "$PROFILES_OK" == "true" && "$SECURITY_OK" == "true" ]]; then
  POST_RESTART_OK="true"
fi

# ---------------------------------------------------------------------------
# Generate the Markdown record with the Phase 8 exit-criteria table prefilled
# ---------------------------------------------------------------------------
REPORT_FILE="$OUT/record.md"

cat > "$REPORT_FILE" <<EOF
# Enrollment Record

Generated: $(date)
Script: $(basename "$0")
Context: ${CONTEXT_LABEL:-(none supplied)}
Output directory: $OUT

This is the Phase 8 evidence bundle for one side of the stabilization restart. It records what the machine reported, not whether the phase passed: the verdict is the exit bookend under \`reimaged-system/bookends/\`, built by \`record-enrollment.sh --context exit\` from the official post-restart run. Keeping them apart means rerunning a capture never silently discards an answered row, and an answered row never has to be copied forward into a newer record. See \`enroll-and-stabilize.md\` for the full runbook.

## What This Run Observed

| Observation | Result | Evidence |
|---|---|---|
| Enrollment status | $(status_pass_warn "$ENROLLMENT_OK") | \`raw/01-enrollment-status.txt\` |
| Configuration profiles present | $(status_pass_warn "$PROFILES_OK") | \`raw/02-profiles-list.txt\` |
| Profile count | $PROFILE_COUNT ($PROFILE_SCOPE scope) | $PROFILE_NOTE |
| Security tooling installed or installing | $(status_pass_warn "$SECURITY_OK") | \`raw/04-managed-apps.txt\`, \`raw/05-managed-processes.txt\` |
| macOS updates | $(status_pass_warn "$UPDATES_OK") | \`raw/06-macos-version.txt\`, \`raw/07-softwareupdate-list.txt\` |
| Managed application set vs pre-image inventory | $MANAGED_APPS_STATUS | $MANAGED_APPS_DETAIL, from \`$MANAGED_APPS_SOURCE\`. See \`raw/08-managed-app-expectations.txt\`, which marks each absence already named by the decisions log and names the categories that are not findings: a superseded management stack, an agent still rolling out, a version-pinned receipt. |
| FileVault | $(status_pass_warn "$FILEVAULT_OK") | \`raw/03-filevault-status.txt\` |
| Keychain identities | $(status_pass_warn "$IDENTITIES_OK") | $IDENTITY_TOTAL valid, $IDENTITY_SSL ssl-client. See \`raw/09-keychain-identities.txt\`. Fingerprints differ from the pre-image set — MDM re-issues these rather than restoring them. |
| Post-restart health | $(status_pass_warn "$POST_RESTART_OK") | Meaningful only on a \`--context post-restart\` run. |

\`rows.tsv\` beside this file carries the same verdicts tab-separated, which is what the exit bookend reads rather than reparsing this table.

## Review While the Evidence Is Fresh

1. Open Company Portal and review the device state, including the **Apps** tab.
2. Review \`raw/08-managed-app-expectations.txt\` and install anything genuinely
   missing from the Company Portal **Apps** tab.
3. Compare the identity count against the pre-image record. Expect the same
   number and shape with different fingerprints.

Anything that needs a decision rather than a look is asked once, in the exit bookend.

## Raw Evidence Files

- \`raw/01-enrollment-status.txt\`
- \`raw/02-profiles-list.txt\`
- \`raw/03-filevault-status.txt\`
- \`raw/04-managed-apps.txt\`
- \`raw/05-managed-processes.txt\`
- \`raw/06-macos-version.txt\`
- \`raw/07-softwareupdate-list.txt\`
- \`raw/08-managed-app-expectations.txt\`
- \`raw/09-keychain-identities.txt\`
- \`raw/10-package-receipts.txt\`
- \`raw/11-launchd-components.txt\`
- \`raw/12-system-extensions.txt\`
EOF

# The verdicts, tab-separated, so the exit bookend reads a table rather than
# reparsing Markdown -- the same split comparison.md / rows.tsv already uses.
ROWS_FILE="$OUT/rows.tsv"
{
  printf 'check\tstatus\tdetail\n'
  printf 'enrollment\t%s\t%s\n'        "$(status_pass_warn "$ENROLLMENT_OK")" "raw/01-enrollment-status.txt"
  printf 'profiles\t%s\t%s\n'          "$(status_pass_warn "$PROFILES_OK")" "$PROFILE_COUNT profiles, $PROFILE_SCOPE scope"
  printf 'security-tools\t%s\t%s\n'    "$(status_pass_warn "$SECURITY_OK")" "raw/04-managed-apps.txt"
  printf 'macos-updates\t%s\t%s\n'     "$(status_pass_warn "$UPDATES_OK")" "raw/07-softwareupdate-list.txt"
  printf 'managed-apps\t%s\t%s\n'      "$MANAGED_APPS_STATUS" "$MANAGED_APPS_DETAIL"
  printf 'filevault\t%s\t%s\n'         "$(status_pass_warn "$FILEVAULT_OK")" "raw/03-filevault-status.txt"
  printf 'keychain-identities\t%s\t%s\n' "$(status_pass_warn "$IDENTITIES_OK")" "$IDENTITY_TOTAL valid, $IDENTITY_SSL ssl-client"
  printf 'post-restart-health\t%s\t%s\n' "$(status_pass_warn "$POST_RESTART_OK")" "meaningful only on a post-restart run"
} > "$ROWS_FILE"

RUN_PASS="$(grep -c '	PASS	' "$ROWS_FILE" 2>/dev/null || true)"
RUN_WARN="$(grep -c '	WARN	' "$ROWS_FILE" 2>/dev/null || true)"

if ! artifact_run_finalize "$RUN_CATEGORY_ROOT" \
     "${RUN_PASS:-0} pass / ${RUN_WARN:-0} warn" "$RUN_NOTE"; then
  echo "ERROR: the record was written but artifact-runs reported a problem indexing it — see above." >&2
  exit 2
fi
# finalize promotes the staging directory, so the paths must be re-derived.
OUT="$ARTIFACT_RUN_DIR"
REPORT_FILE="$OUT/record.md"

echo ""
echo "Enrollment record complete."
echo "Record → $REPORT_FILE"
echo "Run indexed at: $RUN_CATEGORY_ROOT/MANIFEST.md"

if [[ "$OPEN_RESULT" == "true" ]]; then
  open -R "$REPORT_FILE" 2>/dev/null || true
fi
