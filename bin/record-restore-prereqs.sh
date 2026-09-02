#!/usr/bin/env bash
# =============================================================================
# record-restore-prereqs.sh
#
# Records whether the prerequisites a restore-phase runbook states in prose are
# actually met, and writes the result as a dated evidence artifact.
#
# Named record-, not check-: it does not only decide pass or fail, it writes a
# checklist under the artifact root that later phases and a future reader can
# consult. That matches record-enrollment.sh and record-reimaged-system.sh,
# where the artifact is the point and the verdict is a summary of it.
#
# CLASSIFICATION: `bin/` entrypoint. It is user-facing: restore-runtime.md and
# restore-access.md both tell the reader to run it directly, which is the
# graduation rule in .github/guides/script-types-and-locations.md verbatim.
#
# It sat under .internal/restore/ on the strength of a carve-out that claimed
# the restore entrypoints called it at startup and that it was shared across
# every restore phase. Measured against the tree, neither held: no bin/restore-*
# script referenced it at all, and two runbooks invoked it out of eleven. The
# carve-out was removed rather than repaired.
#
# It still takes explicit arguments -- --runbook and the root overrides are
# required rather than inferred -- because several phases pass different ones,
# not because it is a helper.
#
# It DOES load .internal/load-reimage-config.sh. Unlike bootstrap-time helpers,
# this one runs well after Phase 8 has restored reimage.env, and it needs
# REIMAGE_ARTIFACT_ROOT resolved to know where to write.
#
# Runbook/phase context: the restore phases from Phase 10 onward. Each of those
# runbooks opens with a Prerequisites list, and until now those were assertions
# the reader was asked to take on trust -- only one of Phase 10A's four had a
# corresponding PASS row anywhere earlier in the workflow. The three that did
# not are precisely the ones that fail quietly: an unset FRACTOGENESIS_HOME
# makes `cd ""` a no-op that returns 0, an unmounted artifact root makes a later
# comparison read an inventory that is not there, and a sign-off with unanswered
# rows is indistinguishable from one that was completed.
#
# Phases are added as their runbooks are reached rather than all at once, so
# each check is written against a runbook someone has actually just followed.
#
# This is an aggregate validator: every check becomes a row rather than aborting
# the run, so one pass produces the whole picture.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#
#   # Record Phase 10A's prerequisites and write the artifact.
#   bash bin/record-restore-prereqs.sh --runbook restore-runtime
#
#   # Print the result without writing anything.
#   bash bin/record-restore-prereqs.sh --runbook restore-runtime --dry-run
#
#   # Reveal the generated artifact in Finder afterwards.
#   bash bin/record-restore-prereqs.sh --runbook restore-runtime --open
#
#   # From a restore entrypoint that has already resolved REPO_ROOT:
#   #   bash "$REPO_ROOT/bin/record-restore-prereqs.sh" \
#   #     --runbook restore-repos --artifact-root "$REIMAGE_ARTIFACT_ROOT"
#
# Options:
#   --runbook NAME         Which phase's prerequisites to check. Required.
#                         Supported: 10A, 10B
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --output-root PATH    Category root for the run. A relative value is
#                         resolved against the current directory, and a
#                         destination inside the repo checkout is refused.
#                         Default: <artifact-root>/reimaged-system/boundaries
#   --dry-run             Print the checklist; write nothing.
#   --open                Reveal the generated checklist in Finder.
#   -h, --help            Show this message and exit.
#
# Output location:
#   <artifact-root>/reimaged-system/boundaries/runs/post-image-<runbook>-entry-<stamp>/
#     checklist.md
#   indexed in that category's MANIFEST.md, with official/ naming the newest run.
#   Entry and exit share one category so a single index answers whether a phase
#   both started and finished.
#
# Exit status:
#   0  All checks passed, or only WARN rows.
#   1  At least one FAIL row. A FAIL means the phase below it cannot proceed
#      correctly, not that something merely needs attention.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -uo pipefail
# Not -e: every check is meant to produce a row. Aborting on the first failure
# would hide the rest, and the value here is seeing all four at once.

# ONE level up: this sits in bin/, so the repo root is the parent. It was
# drafted at .internal/restore/ and climbed two. Moving a script between those
# depths without changing this line is the failure this repo has already hit --
# see the same comment in compare-restored-state.sh.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"

if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi

ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

# Shared run index: staged run directories, append-only MANIFEST.md, and one
# computed official/<context>.txt per lineage. Extracted from the pattern
# report-loose-secrets.sh proved, so every producer under the artifact root
# indexes its runs the same way.
RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../../.internal/artifact-runs.sh
source "$RUNS_LIB"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

require_option_value() {
  if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
    echo "ERROR: $1 requires a non-empty value." >&2
    exit 2
  fi
}

STAMP="$(date +%Y%m%d-%H%M%S)"
RUNBOOK=""
OUTPUT_ROOT=""
DRY_RUN=false
OPEN_RESULT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runbook)         require_option_value "$1" "${2:-}"; RUNBOOK="${2%.md}"; shift 2 ;;
    --artifact-root) require_option_value "$1" "${2:-}"; REIMAGE_ARTIFACT_ROOT="$2"; shift 2 ;;
    --output-root)   require_option_value "$1" "${2:-}"; OUTPUT_ROOT="$2"; shift 2 ;;
    --dry-run)       DRY_RUN=true; shift ;;
    --open)          OPEN_RESULT=true; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "${RUNBOOK:-}" ]]; then
  echo "ERROR: --runbook is required. Supported: restore-runtime, restore-access" >&2
  usage >&2
  exit 2
fi

# One list, used by the required-argument error, the guard and the hint.
#
# Two literals drifted apart here: the case dispatched on five runbooks while the
# hint advertised two, so running it for restore-git, restore-repos or
# restore-apps -- each of which works -- told the operator their own phase was
# unsupported. Revision 126 fixed the same defect in record-restore-exit.sh; this
# is the shape that stops it recurring.
SUPPORTED_RUNBOOKS="restore-runtime restore-access restore-git restore-repos restore-apps restore-home"

case " $SUPPORTED_RUNBOOKS " in
  *" $RUNBOOK "*) PHASE_RUNBOOK="$RUNBOOK.md" ;;
  *) echo "ERROR: no prerequisite checks defined for runbook: $RUNBOOK" >&2
     echo "HINT:  supported runbooks: $SUPPORTED_RUNBOOKS. Others are added as their runbooks are reached." >&2
     exit 2 ;;
esac

absolute_path() {
  local input="$1" resolved="" rest segment
  case "$input" in /*) ;; *) input="$PWD/$input" ;; esac
  rest="$input"
  while [[ -n "$rest" ]]; do
    segment="${rest%%/*}"
    if [[ "$segment" == "$rest" ]]; then rest=""; else rest="${rest#*/}"; fi
    case "$segment" in
      ''|.) ;;
      ..) resolved="${resolved%/*}" ;;
      *) resolved="$resolved/$segment" ;;
    esac
  done
  printf '%s' "${resolved:-/}"
}

# ---------------------------------------------------------------------------
# Row recording
# ---------------------------------------------------------------------------
ROWS=""
fail_count=0
warn_count=0
pass_count=0

record() {
  # record <status> <check> <detail>
  local status="$1" check="$2" detail="$3"
  case "$status" in
    PASS) pass_count=$(( pass_count + 1 )) ;;
    WARN) warn_count=$(( warn_count + 1 )) ;;
    FAIL) fail_count=$(( fail_count + 1 )) ;;
  esac
  ROWS="${ROWS}| ${check} | \`${status}\` | ${detail} |"$'\n'
  printf '  %-5s %s\n' "$status" "$check" >&2
}

# ---------------------------------------------------------------------------
# Unanswered-row counting
#
# Counts TODO only where it appears as a TABLE CELL. A naive `grep -c TODO`
# also matches instruction prose -- "Update the TODO rows above" -- and reports
# a completed sign-off as incomplete, which trains the reader to ignore the
# check. Handles both the bare `| TODO |` of the enrollment record and the
# backticked `| `TODO` |` of the first-boot checklist.
#
# EXPECTED_ABSENT names rows that read TODO by design in the phase that wrote
# them. Git and Homebrew are recorded by Phase 9 and installed by Phase 10A, so
# a TODO there is the correct state, not an unanswered question.
# ---------------------------------------------------------------------------
EXPECTED_ABSENT='Git available|Homebrew available'

count_todo_rows() {
  awk -F'|' -v skip="$EXPECTED_ABSENT" '
    /^[[:space:]]*\|/ {
      label = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", label)
      if (skip != "" && label ~ skip) next
      for (i = 2; i < NF; i++) {
        cell = $i
        gsub(/[`[:space:]]/, "", cell)
        if (cell == "TODO") { n++; break }
      }
    }
    END { print n + 0 }' "$1"
}

list_todo_rows() {
  awk -F'|' -v skip="$EXPECTED_ABSENT" '
    /^[[:space:]]*\|/ {
      label = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", label)
      if (skip != "" && label ~ skip) next
      for (i = 2; i < NF; i++) {
        cell = $i
        gsub(/[`[:space:]]/, "", cell)
        if (cell == "TODO") { print "    - " label; break }
      }
    }' "$1"
}


# ---------------------------------------------------------------------------
# JDK baseline
#
# The version is NOT hardcoded. `REIMAGE_JDK_BASELINE` in reimage.env pins a
# major when a project needs a specific one; unset, `java_home` returns the
# machine's default JDK. Either way the row reports WHICH path resolved, so the
# evidence carries the answer rather than a version number going stale inside
# the check. An earlier revision asked for `-v 21` in three places across two
# files, which would have started failing the day the baseline moved -- and
# failing for a reason that reads like a missing JDK.
# ---------------------------------------------------------------------------
resolve_java_home() {
  if [[ -n "${REIMAGE_JDK_BASELINE:-}" ]]; then
    /usr/libexec/java_home -v "$REIMAGE_JDK_BASELINE" 2>/dev/null
  else
    /usr/libexec/java_home 2>/dev/null
  fi
}

java_baseline_label() {
  if [[ -n "${REIMAGE_JDK_BASELINE:-}" ]]; then
    printf 'pinned to JDK %s by REIMAGE_JDK_BASELINE' "$REIMAGE_JDK_BASELINE"
  else
    printf 'the machine default; set REIMAGE_JDK_BASELINE in reimage.env to pin one'
  fi
}

# ---------------------------------------------------------------------------
# Phase 10A checks
# ---------------------------------------------------------------------------
UNANSWERED=""

check_restore_runtime() {
  # 1 -- toolkit root. Unset, `cd ""` is a no-op returning 0: you stay in $HOME,
  # every ./bin/... reports "No such file or directory", and nothing points back
  # at the missing variable.
  if [[ -n "${FRACTOGENESIS_HOME:-}" && -d "${FRACTOGENESIS_HOME:-}/bin" ]]; then
    record PASS "Toolkit root resolves" "\`$FRACTOGENESIS_HOME\`"
  else
    record FAIL "Toolkit root resolves" "\`FRACTOGENESIS_HOME\` unset or has no \`bin/\` — see \`enroll-and-stabilize.md\` Step 2"
  fi

  # 2 -- Phase 8 and Phase 9 sign-offs have no rows nobody looked at.
  #
  # Each source produces a row whether or not its pointer resolves. An earlier
  # revision iterated `for f in "$rec" ...` and skipped empty entries, so a
  # missing or unreadable `latest-*` pointer produced no row at all -- "could
  # not check" rendered as silence, in a checklist whose entire purpose is
  # recording that every question was asked.
  #
  # Both sign-offs are read from `boundaries/`, not from the evidence bundles,
  # and through the run index rather than a `latest-*.txt` pointer. Two separate
  # reasons, both learned here:
  #
  # An evidence run records what the machine reported; the exit checklist
  # records what a person decided about it, and only the second can be
  # "complete". Reading the bundle asked the wrong artifact -- and because
  # rerunning a capture brings its unanswered rows back, a bundle could never
  # stay signed off even once someone had answered it.
  #
  # A single pointer cannot name several lineages, and these categories have
  # several: restarts/ carries initial, pre-restart and post-restart;
  # boundaries/ carries entry and exit per runbook. `official/<context>.txt`
  # answers per lineage, which is what the question actually is.
  local n label src boundaries_root exit_run
  boundaries_root="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/reimaged-system/boundaries"

  for label in "\`enroll-and-stabilize\`" "\`verify-reimaged-system\`"; do
    case "$label" in
      *enroll-and-stabilize*) exit_run="$(artifact_run_official "$boundaries_root" "enroll-and-stabilize-exit" 2>/dev/null)" ;;
      *)                      exit_run="$(artifact_run_official "$boundaries_root" "verify-reimaged-system-exit" 2>/dev/null)" ;;
    esac
    src=""
    [[ -n "$exit_run" ]] && src="$boundaries_root/$exit_run/checklist.md"

    if [[ -z "$src" ]]; then
      record WARN "Sign-off complete: $label" "no official \`-exit\` run under \`boundaries/\` — the close-out has not been recorded, so this row is unchecked rather than clean"
      continue
    fi
    if [[ ! -f "$src" ]]; then
      record WARN "Sign-off complete: $label" "pointer names a file that is not there: \`$src\`"
      continue
    fi
    n="$(count_todo_rows "$src")"
    if [[ "$n" == "0" ]]; then
      record PASS "Sign-off complete: $label" "no unanswered rows"
    else
      record WARN "Sign-off complete: $label" "$n unanswered row(s)"
      UNANSWERED="${UNANSWERED}  \`$src\`"$'\n'"$(list_todo_rows "$src")"$'\n'
    fi
  done

  # 3 -- network. Every install in Phase 10A hits it.
  if curl -fsI -m 10 https://github.com >/dev/null 2>&1; then
    record PASS "Network reachable" "https://github.com responded"
  else
    record FAIL "Network reachable" "no response — Homebrew, nvm, JDK, and every CLI install below need it"
  fi

  # 4 -- artifact root. WARN not FAIL: the runbook explicitly allows Steps 1-9
  # without the drive, reconnecting before the Step 10 comparison.
  if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    record PASS "Artifact root mounted" "\`$REIMAGE_ARTIFACT_ROOT\`"
  else
    record WARN "Artifact root mounted" "unset or unmounted — Steps 1-9 are fine; reconnect before Step 10"
  fi

  # 5 -- the inventory Step 10 compares against. Resolved through the pointer
  # Step 10 itself resolves, so this check answers the question that step will
  # ask rather than a similar-looking one about directory names.
  local inv
  inv="$(artifact_run_official "${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/system-inventory" pre-image 2>/dev/null || true)"
  if [[ -n "$inv" ]]; then
    record PASS "Pre-image system inventory found" "\`${inv#runs/}\`"
  else
    record WARN "Pre-image system inventory found" "no official \`pre-image\` run under \`system-inventory/\` — Step 10's comparison has no baseline"
  fi
}


# ---------------------------------------------------------------------------
# Phase 10B checks
#
# Run by `restore-access.md` Step 0, and only there. An earlier revision had
# `restore-runtime.md` Step 11 run this too, on the reasoning that 10A's exit and
# 10B's entry are one question asked from either side. That was corrected: one
# check per boundary, a phase never runs the next phase's entry check. Step 11
# now calls record-restore-exit.sh --runbook restore-runtime instead.
#
# The rows below therefore overlap check_restore_runtime() in record-restore-exit.sh without
# being identical to it -- entry and exit ask about the same tools for different
# reasons, and the severity differs accordingly. Keep the two in step by hand
# when either changes.
# ---------------------------------------------------------------------------
check_restore_access() {
  local out b_root b_run

  # 1 -- did Phase 10A finish? The chain runs 10A -> 10B -> 11A -> 11B -> 12 and
  # this was the one link missing: 11A, 11B and 12 each check their predecessor,
  # 10B did not. Phase 10B depends on the toolchain 10A installs -- the Java
  # lookup below fails outright without it -- so the dependency was already real,
  # just unstated.
  b_root="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/reimaged-system/boundaries"
  b_run="$(artifact_run_official "$b_root" "restore-runtime-exit" 2>/dev/null)"
  if [[ -n "$b_run" ]]; then
    record PASS "\`restore-runtime\` closed out" "\`$(basename "$b_run")\`"
  else
    record FAIL "\`restore-runtime\` closed out" "no official \`restore-runtime-exit\` run under \`boundaries/\` — this phase configures trust for a toolchain Phase 10A installs, and every check below assumes it is there"
  fi

  # 1 -- Java lookup. The single most consequential row here, and the one that
  # fails silently. restore-access.md Step 6 runs
  #   export JAVA_HOME="$(/usr/libexec/java_home ...)"
  # and command substitution swallows a non-zero exit, so JAVA_HOME becomes the
  # empty string. The `cp` on the next line then writes jssecacerts to
  # /lib/security/jssecacerts -- an absolute path that is not the JDK and not a
  # directory that exists -- and the TLS smoke test afterwards fails for a
  # reason unrelated to the certificate. Catch it here, where it is one command.
  if out="$(resolve_java_home)" && [[ -n "$out" && -d "$out" ]]; then
    record PASS "Java resolves via java_home" "\`$out\` — $(java_baseline_label)"
  else
    record FAIL "Java resolves via java_home" "\`java_home\` did not resolve ($(java_baseline_label)) — \`restore-access\` would set an empty \`JAVA_HOME\` and write \`jssecacerts\` outside the JDK. See \`restore-runtime.md\`."
  fi

  # 2 -- direnv actually hooked, not merely installed.
  if command -v direnv >/dev/null 2>&1; then
    if [[ -n "${DIRENV_DIR:-}" ]]; then
      record PASS "direnv hooked and .envrc allowed" "loaded for \`${DIRENV_DIR#-}\`"
    else
      record WARN "direnv hooked and .envrc allowed" "installed, but no \`.envrc\` is loaded in this shell — run \`direnv allow\` in the toolkit root"
    fi
  else
    record WARN "direnv hooked and .envrc allowed" "not installed — see \`restore-runtime.md\` Step 6"
  fi

  # 3 -- toolkit root. Restated here because 10B is often reached in a new shell.
  if [[ -n "${FRACTOGENESIS_HOME:-}" && -d "${FRACTOGENESIS_HOME:-}/bin" ]]; then
    record PASS "Toolkit root resolves" "\`$FRACTOGENESIS_HOME\`"
  else
    record FAIL "Toolkit root resolves" "\`FRACTOGENESIS_HOME\` unset or has no \`bin/\`"
  fi

  # 4 -- the encrypted DMG 10B mounts. Without it the phase cannot start.
  local dmg
  dmg="$(find "${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/secrets-encrypted" -maxdepth 1 -name 'all-secrets-*.dmg' 2>/dev/null | sort | tail -1)"
  if [[ -n "$dmg" ]]; then
    record PASS "Secrets DMG present" "\`$(basename "$dmg")\`"
  else
    record FAIL "Secrets DMG present" "no \`all-secrets-*.dmg\` under \`secrets-encrypted/\` — \`restore-access\` has nothing to mount"
  fi

  # 5 -- the categories sidecar written beside the DMG at build time. It lists
  # what the image holds and is readable WITHOUT the DMG password, which is the
  # only way to answer "is the category I need actually in there" before Step 1
  # mounts anything. WARN, not FAIL: its absence costs visibility, not the phase.
  # `[[ -f ... ]]` does no pathname expansion, so a glob inside it is tested as a
  # literal string containing `*` and can never match. An earlier revision had
  # that test here with an `ls` fallback; the fallback did all the work and the
  # test was dead. Only the `ls` remains.
  if ls "${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/secrets-encrypted/"all-secrets-*-categories.txt >/dev/null 2>&1; then
    record PASS "DMG categories sidecar present" "readable without the DMG password"
  else
    record WARN "DMG categories sidecar present" "no \`*-categories.txt\` — you cannot see what the image holds without mounting it"
  fi

  # 6a -- JVM build tools. WARN is right here: restore-access.md never invokes
  # gradle or mvn, so a gap blocks Phase 11B or 12 rather than this phase.
  local tool missing=""
  for tool in gradle mvn; do
    command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"
  done
  if [[ -z "$missing" ]]; then
    record PASS "JVM build tools present" "gradle, mvn"
  else
    record WARN "JVM build tools present" "missing:$missing — see \`restore-runtime.md\` Step 7; needed by \`restore-repos\`, not by 10B"
  fi

  # 6b -- Node tooling. NOT the same consequence, which is why it is its own row:
  # restore-access.md Step 7 runs `npm config set cafile`, `npm ping`, and
  # `node -e` to establish corporate CA trust outside the keychain, so a gap here
  # breaks part of THIS phase.
  #
  # "not on PATH" is not "not installed". nvm activates a version by prepending to
  # PATH from a shell function, so a shell that never sourced nvm.sh -- or one
  # where no default alias is set -- reports both tools absent on a machine where
  # restore-runtime.md Step 8 completed. Reporting that as missing sends the
  # reader back to reinstall what is already on disk. Checking the nvm install
  # directory separates the two, the same way the direnv row above separates
  # installed from hooked.
  missing=""
  for tool in node npm; do
    command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"
  done
  if [[ -z "$missing" ]]; then
    record PASS "Node tooling present" "node \`$(node --version 2>/dev/null)\` / npm \`$(npm --version 2>/dev/null)\`"
  else
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    local installed=""
    if [[ -d "$nvm_dir/versions/node" ]]; then
      installed="$(ls -1 "$nvm_dir/versions/node" 2>/dev/null | tail -1)"
    fi
    if [[ -n "$installed" ]]; then
      record WARN "Node tooling present" "missing:$missing from \`PATH\`, but nvm has \`$installed\` installed — nvm is not active in this shell, not absent from the machine. Run \`nvm alias default ${installed#v}\`, then \`exec zsh -l\` and rerun. Step 7 needs it."
    else
      record FAIL "Node tooling present" "missing:$missing, and no version under \`$nvm_dir/versions/node\` — Step 7's \`npm config set cafile\` and \`node -e\` cannot run. See \`restore-runtime.md\` Step 8."
    fi
  fi

  # 7 -- evidence that Step 10's comparison was actually run.
  #
  # Ask the run index rather than globbing. `find ... | sort | tail -1` also
  # matches `.<id>.incomplete` staging directories, and it cannot say which
  # lineage it wants -- the two problems artifact-runs.sh was extracted to
  # remove, left in place by the revision that built it.
  local cmp_root cmp_run
  cmp_root="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/reimaged-system/comparisons"
  cmp_run="$(artifact_run_official "$cmp_root" "restore-runtime-inventory-diff" 2>/dev/null)"
  if [[ -n "$cmp_run" && -f "$cmp_root/$cmp_run/comparison.md" ]]; then
    record PASS "Runtime comparison recorded" "\`$(basename "$cmp_run")\`"
  else
    record WARN "Runtime comparison recorded" "no official run for \`post-image-restore-runtime-inventory-diff\` under \`comparisons/\` — run \`bash bin/compare-restored-state.sh --runbook restore-runtime\` without \`--dry-run\`"
  fi

  # NOTE, deliberately not fixed here: this row proves the comparison EXISTS,
  # never that it postdates the state it describes. A 9-pass sign-off has
  # already cited a comparison taken before a Node fix. Adding a freshness rule
  # needs a decision about what "fresh" is measured against, so it stays an
  # open item rather than a guess.
}

echo "Checking ${PHASE_RUNBOOK%.md} prerequisites..." >&2
# ---------------------------------------------------------------------------
# Phase 11A checks -- restore-git
#
# Derived from restore-git.md -> Prerequisites, one row per bullet, so the two
# cannot drift.
#
# The identity values are deliberately NOT checked here. Step 0c of that runbook
# is what records them, so at this boundary they are unset by definition and a
# row over them could only ever FAIL -- a scheduled false alarm, which is the
# mirror of the failure this recorder exists to prevent. They are checked at the
# other end, by check_restore_git() in record-restore-exit.sh, which also
# enforces that the optional GIT_PERSONAL_* set is filled all-or-nothing.
#
# The SSH keys are not checked here either. restore-access's own exit recorder
# already carries `SSH private keys restored and tight`, and row 2 below is what
# makes that verdict reachable -- re-probing it would be this phase answering the
# previous phase's question with worse information, and it cannot even name the
# key files without the identity values Step 0c has not written yet.
# ---------------------------------------------------------------------------
check_restore_git() {
  # 1 -- toolkit root. Phase 11A is commonly reached in a new shell.
  if [[ -n "${FRACTOGENESIS_HOME:-}" && -d "${FRACTOGENESIS_HOME:-}/bin" ]]; then
    record PASS "Toolkit root resolves" "\`$FRACTOGENESIS_HOME\`"
  else
    record FAIL "Toolkit root resolves" "\`FRACTOGENESIS_HOME\` unset or has no \`bin/\`"
  fi

  # 2 -- Phase 10B actually closed out, not merely "was worked on". The boundary
  # index answers this; an entry with no exit is a phase walked and abandoned.
  local b_root b_run
  b_root="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/reimaged-system/boundaries"
  b_run="$(artifact_run_official "$b_root" "restore-access-exit" 2>/dev/null)"
  if [[ -n "$b_run" ]]; then
    record PASS "\`restore-access\` closed out" "\`$(basename "$b_run")\`"
  else
    record FAIL "\`restore-access\` closed out" "no official \`restore-access-exit\` run under \`boundaries/\` — run \`./bin/record-restore-exit.sh --runbook restore-access\` at the end of \`restore-access\`"
  fi

  # 3 -- git itself. Loud if absent, but the row is free and Step 1 assumes it.
  if command -v git >/dev/null 2>&1; then
    record PASS "Git available" "$(git --version 2>/dev/null)"
  else
    record FAIL "Git available" "not on PATH — \`restore-runtime\` installs it"
  fi

  # 6 -- not checkable from here without reaching GitHub as both identities,
  # which is Step 7's job. WARN rather than PASS: this recorder has no MANUAL
  # tier, and recording PASS for something nobody verified is the failure mode
  # this whole step exists to prevent.
  record WARN "Key fingerprints registered on GitHub" "Confirm by hand: both accounts' public keys are registered, or the fingerprints are in a password manager. \`ssh -T\` in Step 7 fails identically for an unregistered key and a wrong key, so this is worth knowing before you get there."
}

# ---------------------------------------------------------------------------
# restore-repos checks
#
# Derived one for one from restore-repos.md -> Prerequisites, plus three rows
# the pre-image audit itself can be wrong in ways nothing downstream notices.
# Every row here fails QUIETLY if unchecked: the script is read-only and always
# produces a status bundle, so a run against a corrupt or empty audit looks
# exactly like a clean one.
# ---------------------------------------------------------------------------
check_restore_repos() {
  local b_root b_run audit_root run_dir tsv n pers_ident pk pv

  # 1 -- toolkit root. Same row as restore-git: this phase is reached in a new
  # shell, and a directory-scoped loader unloads reimage.env outside the repo.
  if [[ -n "${FRACTOGENESIS_HOME:-}" && -d "${FRACTOGENESIS_HOME:-}/bin" ]]; then
    record PASS "Toolkit root resolves" "\`$FRACTOGENESIS_HOME\`"
  else
    record FAIL "Toolkit root resolves" "\`FRACTOGENESIS_HOME\` unset or has no \`bin/\`"
  fi

  # 2 -- restore-git closed out. An entry with no exit is a phase walked and
  # abandoned; the identity plumbing this phase depends on may be half-written.
  b_root="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/reimaged-system/boundaries"
  b_run="$(artifact_run_official "$b_root" "restore-git-exit" 2>/dev/null)"
  if [[ -n "$b_run" ]]; then
    record PASS "\`restore-git\` closed out" "\`$(basename "$b_run")\`"
  else
    record FAIL "\`restore-git\` closed out" "no official \`restore-git-exit\` run under \`boundaries/\` — run \`./bin/record-restore-exit.sh --runbook restore-git\` at the end of \`restore-git\`"
  fi

  # 3 -- clone roots. GIT_WORK_REPO_ROOT is required: unset, every repository
  # falls back to its pre-image parent directory.
  #
  # GIT_PERSONAL_REPO_ROOT is OPTIONAL and all-or-nothing with the personal
  # identity restore-git recorded, matching backup-repos.md and the
  # `Identity values recorded in reimage.env` row in record-restore-exit.sh. A
  # Mac with no personal identity has no personal root, and that is a PASS --
  # this row used to FAIL on it, which made a legitimate single-identity machine
  # unable to start the phase.
  #
  # What is never right is half the pair. A personal root with no identity clones
  # into a directory `includeIf` will not match, so those commits land under the
  # work identity. An identity with no root leaves restore-git Step 5's override
  # at `/.gitconfig`. Both roots equal is its own failure: includeIf then applies
  # the personal identity to every repository.
  pers_ident=""
  for pk in GIT_PERSONAL_NAME GIT_PERSONAL_EMAIL GIT_PERSONAL_SSH_KEY GIT_PERSONAL_GITHUB_HOST; do
    eval "pv=\${$pk:-}"
    [[ -z "$pv" ]] || pers_ident="set"
  done
  if [[ -z "${GIT_WORK_REPO_ROOT:-}" ]]; then
    record FAIL "Clone roots set and distinct" "\`GIT_WORK_REPO_ROOT\` is unset in \`reimage.env\` — every repository would fall back to its pre-image parent directory. \`backup-repos\` Step 1 records it."
  elif [[ -n "${GIT_PERSONAL_REPO_ROOT:-}" && "${GIT_WORK_REPO_ROOT%/}" == "${GIT_PERSONAL_REPO_ROOT%/}" ]]; then
    record FAIL "Clone roots set and distinct" "both roots are \`${GIT_WORK_REPO_ROOT%/}\` — \`includeIf\` would apply the personal identity to every repository"
  elif [[ -n "${GIT_PERSONAL_REPO_ROOT:-}" && -z "$pers_ident" ]]; then
    record FAIL "Clone roots set and distinct" "\`GIT_PERSONAL_REPO_ROOT\` is \`${GIT_PERSONAL_REPO_ROOT%/}\` but no \`GIT_PERSONAL_*\` identity was recorded — repositories would clone into a root \`includeIf\` never matches and commit under the work identity. Either record the identity in \`restore-git\` Step 0c or clear the root."
  elif [[ -z "${GIT_PERSONAL_REPO_ROOT:-}" && -n "$pers_ident" ]]; then
    record FAIL "Clone roots set and distinct" "a personal identity is recorded but \`GIT_PERSONAL_REPO_ROOT\` is empty — \`includeIf\` has no \`gitdir:\` to match and nothing can route to the personal host. \`backup-repos\` Step 1 records that root."
  elif [[ -z "${GIT_PERSONAL_REPO_ROOT:-}" ]]; then
    record PASS "Clone roots set and distinct" "\`${GIT_WORK_REPO_ROOT%/}\`; no personal root and no personal identity — every repository clones under the work root"
  else
    record PASS "Clone roots set and distinct" "\`${GIT_WORK_REPO_ROOT%/}\` and \`${GIT_PERSONAL_REPO_ROOT%/}\`"
  fi

  # 4 -- the audit pointer resolves to a run directory that is actually there.
  audit_root="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/repo-audit-reports"
  run_dir=""
  # `official/pre-image.txt` names the lineage this row is about. The pointer it
  # replaced accepted either prefix and returned whichever ran last, so a
  # post-image restore run could answer a question about the pre-image baseline.
  n="$(artifact_run_official "$audit_root" "pre-image" 2>/dev/null || true)"
  if [[ -n "$n" ]]; then
    run_dir="$audit_root/$n"
  fi
  if [[ -n "$run_dir" && -d "$run_dir" ]]; then
    record PASS "Pre-image repository audit resolves" "\`$(basename "$run_dir")\`"
  else
    record FAIL "Pre-image repository audit resolves" "\`$audit_root/official/pre-image.txt\` is missing or names a run that is not on disk — this phase has nothing to restore from"
    return 0
  fi

  # 5 -- the audit has rows. An empty repos.tsv produces an empty clone script
  # and a status bundle reporting nothing to do, which reads as success.
  tsv="$run_dir/repos.tsv"
  n="$(awk 'NR>1' "$tsv" 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "${n:-0}" -gt 0 ]]; then
    record PASS "Audit has repository rows" "$n repositories inventoried"
  else
    record FAIL "Audit has repository rows" "\`repos.tsv\` has no data rows — nothing was inventoried, and every downstream count would be zero without saying so"
    return 0
  fi

  # 6 -- remote URLs survived the TSV. capture-repo-audit.sh builds this column
  # from `git remote -v`, whose output is itself tab-separated, so the URLs can
  # land in later columns and leave the remote NAME where the URL belongs.
  # restore-repos.sh feeds that field to rewrite_remote_for_host, so the damage
  # surfaces as clone commands that are malformed rather than as an error.
  n="$(awk -F'\t' 'NR>1 && $4 != "<none>" && $4 !~ /:\/\// && $4 !~ /@/ {c++} END{print c+0}' "$tsv" 2>/dev/null)"
  if [[ "${n:-0}" -eq 0 ]]; then
    record PASS "Audit remote URLs are URLs" "column 4 holds URLs on every row"
  else
    record FAIL "Audit remote URLs are URLs" "$n row(s) hold a remote NAME where the URL belongs — \`git remote -v\` output is tab-separated and was written into a TSV unsquashed. Read the URLs from \`repo-audit-summary.txt\` before trusting any emitted clone command."
  fi

  # 7 -- repositories with no remote at all cannot be cloned by anything. They
  # are not a failure of this phase, but they are silently absent from its
  # output, and their only copy is whatever the backup happened to stage.
  n="$(awk -F'\t' 'NR>1 && $4 == "<none>" {c++} END{print c+0}' "$tsv" 2>/dev/null)"
  if [[ "${n:-0}" -eq 0 ]]; then
    record PASS "Every repository has a remote" "all rows carry one"
  else
    record WARN "Every repository has a remote" "$n repository/repositories have no remote recorded — nothing can clone them. Recover from Time Machine or the home backup, or decide to let them go; either is an answer, silence is not."
  fi

  # 8 -- a repository whose remotes span both hosts has no automatic answer to
  # "which root", because the host is what decides it everywhere else.
  n="$(awk 'NR>1 && /\/\/github\.com\//&& /github\.gaig\.com\//{c++} END{print c+0}' "$tsv" 2>/dev/null)"
  if [[ "${n:-0}" -eq 0 ]]; then
    record PASS "No repository spans both hosts" "each is unambiguously work or personal"
  else
    record WARN "No repository spans both hosts" "$n repository/repositories have remotes on BOTH the corporate and the public host — the host cannot decide which root they belong in, so record the choice per repository before cloning."
  fi
}

# ---------------------------------------------------------------------------
# restore-apps checks
#
# Derived from restore-apps.md -> Prerequisites. This phase is an orchestrator:
# its steps hand off to restore-intellij.md and restore-docker.md, whose scripts
# read the pre-image app-settings-backup and emit plan-notes. A missing backup
# category therefore does not error -- the plan-note simply reports every source
# for that app as MISSING, which reads like the app had nothing to restore.
# ---------------------------------------------------------------------------
check_restore_apps() {
  local b_root b_run app_root n missing app

  if [[ -n "${FRACTOGENESIS_HOME:-}" && -d "${FRACTOGENESIS_HOME:-}/bin" ]]; then
    record PASS "Toolkit root resolves" "\`$FRACTOGENESIS_HOME\`"
  else
    record FAIL "Toolkit root resolves" "\`FRACTOGENESIS_HOME\` unset or has no \`bin/\`"
  fi

  b_root="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/reimaged-system/boundaries"
  b_run="$(artifact_run_official "$b_root" "restore-repos-exit" 2>/dev/null)"
  if [[ -n "$b_run" ]]; then
    record PASS "\`restore-repos\` closed out" "\`$(basename "$b_run")\`"
  else
    record FAIL "\`restore-repos\` closed out" "no official \`restore-repos-exit\` run under \`boundaries/\` — several steps here depend on repository checkouts, and IntelliJ project paths resolve to nothing without them"
  fi

  app_root="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/app-settings-backup"
  if [[ -d "$app_root" ]]; then
    n="$(find "$app_root" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
    record PASS "Pre-image app settings reachable" "$n category/categories under \`app-settings-backup/\`"
  else
    record FAIL "Pre-image app settings reachable" "\`$app_root\` is not there — every plan-note would report all sources MISSING, which reads as an app with nothing to restore rather than an unreachable backup"
    return 0
  fi

  # The categories behind the steps most runs reach first. Absent ones are named
  # here rather than discovered one plan-note at a time.
  missing=""
  for app in intellij docker vscode obsidian postman; do
    [[ -d "$app_root/$app" ]] || missing="${missing:+$missing }$app"
  done
  if [[ -z "$missing" ]]; then
    record PASS "Core app categories captured" "intellij, docker, vscode, obsidian, postman all present"
  else
    record WARN "Core app categories captured" "no backup category for: $missing — those steps have nothing to restore from, which is a fact worth knowing before the step rather than inside it"
  fi

  # The DMG is per-step by design: Postman, IntelliJ, Docker and licenses each
  # ask for it and eject after. Absent is normal at phase entry.
  if find /Volumes -maxdepth 1 -type d -name 'all-secrets-*' 2>/dev/null | grep -q .; then
    record WARN "Encrypted secrets DMG" "currently attached — mount only when a step asks, and eject when done; it holds plaintext"
  else
    record PASS "Encrypted secrets DMG" "not attached, which is correct at phase entry — steps mount it as needed"
  fi
}

# ---------------------------------------------------------------------------
# restore-home prerequisites
#
# Derived one for one from restore-home.md -> Prerequisites. Phase 15 is the
# bulk-content phase and the last one that writes to $HOME, so every row here is
# about something that must already be true before anything is copied in volume.
#
# `restore-intellij` and `restore-docker` get no boundary of their own: they are
# expanded sections of restore-apps.md rather than phases, and Phase 12's
# boundary covers them.
# ---------------------------------------------------------------------------
check_restore_home() {
  local b_root c_root b_run n

  if [[ -n "${FRACTOGENESIS_HOME:-}" && -d "${FRACTOGENESIS_HOME:-}/bin" ]]; then
    record PASS "Toolkit root resolves" "\`$FRACTOGENESIS_HOME\`"
  else
    record FAIL "Toolkit root resolves" "\`FRACTOGENESIS_HOME\` unset or has no \`bin/\`"
  fi

  b_root="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/reimaged-system/boundaries"

  # 1 -- Phase 12 closed out. The chain link: 15 is the next phase with a
  # boundary of its own, so without this the chain stops at 12.
  b_run="$(artifact_run_official "$b_root" "restore-apps-exit" 2>/dev/null)"
  if [[ -n "$b_run" ]]; then
    record PASS "\`restore-apps\` closed out" "\`$(basename "$b_run")\`"
  else
    record WARN "\`restore-apps\` closed out" "no official \`restore-apps-exit\` run — Phase 12 has no fixed finish line and returning for more apps later is expected, so this is a WARN; what it should not be is unnoticed"
  fi

  # 2 -- Phase 14 is the row the runbook leads with. Restoring bulk home content
  # onto a system nobody has validated means a later failure cannot be told apart
  # from something Phase 15 brought back with it.
  c_root="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/reimaged-system/checklists"
  b_run="$(artifact_run_official "$c_root" "post-image" 2>/dev/null)"
  if [[ -n "$b_run" ]]; then
    record PASS "Phase 14 checks recorded" "\`$(basename "$b_run")\`"
  else
    record FAIL "Phase 14 checks recorded" "no official \`post-image\` run under \`reimaged-system/checklists/\` — \`restore-home.md\` Prerequisites require Phase 14 complete and clean before bulk home content is touched"
  fi

  # 3 -- the two phases that already own dotfiles this one must not overwrite.
  for c_root in restore-access-exit restore-git-exit; do
    b_run="$(artifact_run_official "$b_root" "$c_root" 2>/dev/null)"
    if [[ -n "$b_run" ]]; then
      record PASS "\`${c_root%-exit}\` closed out" "\`$(basename "$b_run")\` — do not restore over what it wrote"
    else
      record FAIL "\`${c_root%-exit}\` closed out" "no official \`$c_root\` run — that phase owns credential-bearing dotfiles and the Git identity, and Phase 15 must merge around them rather than onto them"
    fi
  done

  # 4 -- the backup this phase reads. Absent, every rsync in it copies nothing
  # and reports success.
  c_root="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/home-files-backup"
  n=0
  for b_run in "$c_root/home" "$c_root/dotfiles"; do
    [[ -d "$b_run" ]] && n=$((n + 1))
  done
  if [[ "$n" -eq 2 ]]; then
    record PASS "Home backup reachable" "\`home/\` and \`dotfiles/\` present under \`home-files-backup/\`"
  else
    record FAIL "Home backup reachable" "$n of 2 present under \`$c_root\` — an rsync from a missing source copies nothing and exits 0"
  fi

  # 5 -- TCC. macOS denies Terminal access to ~/Documents and ~/Desktop until it
  # is granted, and the failure mode is the quiet one the runbook warns about:
  # rsync keeps going, prints "Operation not permitted", and exits 23 with a
  # partial tree. A read probe observes it without creating anything.
  n=0
  for b_run in "$HOME/Documents" "$HOME/Desktop"; do
    ls "$b_run" >/dev/null 2>&1 && n=$((n + 1))
  done
  if [[ "$n" -eq 2 ]]; then
    record PASS "Terminal can reach ~/Documents and ~/Desktop" "both readable — Full Disk Access appears granted"
  else
    record FAIL "Terminal can reach ~/Documents and ~/Desktop" "$n of 2 readable — grant Full Disk Access (System Settings → Privacy & Security) before Step 3, or rsync will report \`Operation not permitted\` and exit 23 with a partial tree"
  fi
}

"check_${RUNBOOK//-/_}"

# ---------------------------------------------------------------------------
# Emit
# ---------------------------------------------------------------------------
emit() {
  # Titled by RUNBOOK, not by phase. Phase ordinals renumber -- this workflow
  # has done it once already -- and a dated artifact that names one is wrong
  # from then on, with nothing to catch it. The runbook name is stable, is what
  # the run directory is keyed on, and is what an operator actually remembers.
  # The phase still appears below as context, sourced from the invocation.
  printf '# %s — Prerequisite Check — %s\n\n' "${PHASE_RUNBOOK%.md}" "$STAMP"
  printf 'Generated by `bin/record-restore-prereqs.sh` on %s.\n\n' "$(date)"
  printf 'Pairs with [[%s|%s]].\n\n' "${PHASE_RUNBOOK%.md}" "$PHASE_RUNBOOK"

  printf '| Check | Result | Detail |\n| --- | --- | --- |\n'
  printf '%s' "$ROWS"
  printf '\n'

  printf '**%s pass · %s warn · %s fail**\n\n' "$pass_count" "$warn_count" "$fail_count"

  if [[ -n "$UNANSWERED" ]]; then
    printf '## Unanswered sign-off rows\n\n'
    printf '%s\n' "$UNANSWERED"
    printf 'Rows recorded by an earlier phase and installed by a later one — `Git available`, `Homebrew available` — are excluded: a `TODO` there is the correct state at the time it was written, not a question nobody answered.\n\n'
  fi

  printf '## How to read this\n\n'
  # Phase-agnostic on purpose. An earlier revision hardcoded "Both FAIL rows here
  # fail quietly" and named Phase 10A's Step 9 and Step 10 -- text that stayed put
  # when --runbook restore-access was added, so a 10B checklist described 10A's rows. Counts
  # and reasons come from the rows themselves now.
  printf -- '- **FAIL** (%s here) means the phase cannot proceed correctly. Every FAIL row in this recorder is a condition that fails *quietly* if unchecked — that is why it is checked at all, rather than left to the step that would trip over it.\n' "$fail_count"
  printf -- '- **WARN** (%s here) means proceed with a known limit, stated in the row itself.\n' "$warn_count"
  printf -- '- A completed sign-off means every row was *answered*, not that every answer was `yes`. A row closed as `no` or `known-blocked` is a decision, and counts as answered.\n\n'
  printf -- 'This is the entry half of a pair. `record-restore-exit.sh --runbook %s` is the exit half, run at the phase final step. Both index into `boundaries/MANIFEST.md`, so one file shows whether a phase both started and finished.\n' "${PHASE_RUNBOOK%.md}"
}

if [[ "$DRY_RUN" == "true" ]]; then
  echo "" >&2
  emit
  echo "(--dry-run: nothing written)" >&2
  [[ "$fail_count" -eq 0 ]] || exit 1
  exit 0
fi

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" || ! -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "" >&2
  echo "NOTE: artifact root unavailable, so no checklist was written." >&2
  echo "      Rerun with --dry-run to see the result, or reconnect the drive." >&2
  [[ "$fail_count" -eq 0 ]] || exit 1
  exit 0
fi

# One category for both boundaries. Entry and exit are the same question asked
# from either side of a phase, so they belong under one index where a runbook's
# pair sits adjacent -- rather than in two sibling directories that have to be
# read together to see whether a phase both started and finished.
if [[ -z "$OUTPUT_ROOT" ]]; then
  OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system/boundaries"
fi
OUTPUT_ROOT="$(absolute_path "$OUTPUT_ROOT")"

if [[ -n "${REPO_ROOT:-}" && ( "$OUTPUT_ROOT" == "$REPO_ROOT" || "$OUTPUT_ROOT" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $OUTPUT_ROOT" >&2
  exit 2
fi

# Context key: <phase>-<runbook>-<point>. The runbook name rather than the phase
# ordinal, because ordinals renumber -- twice in one day, on this repo -- and a
# directory name already written to the drive cannot be renumbered afterwards.
RUN_CONTEXT="${PHASE_RUNBOOK%.md}-entry"

if ! artifact_run_begin "$OUTPUT_ROOT" "$RUN_CONTEXT"; then
  echo "ERROR: could not stage a run under: $OUTPUT_ROOT" >&2
  exit 2
fi

CHECK_FILE="$ARTIFACT_RUN_DIR/checklist.md"

if ! emit > "$CHECK_FILE"; then
  echo "ERROR: could not write the checklist: $CHECK_FILE" >&2
  artifact_run_abort
  exit 2
fi

# The result summary lands in the manifest row, so the index answers "did this
# phase pass" without opening the run.
if ! artifact_run_finalize "$OUTPUT_ROOT" \
     "$pass_count pass / $warn_count warn / $fail_count fail"; then
  echo "ERROR: the run was written but could not be indexed." >&2
  exit 2
fi

CHECK_FILE="$ARTIFACT_RUN_DIR/checklist.md"

echo "" >&2
echo "Checklist → $CHECK_FILE" >&2
printf '%s pass · %s warn · %s fail\n' "$pass_count" "$warn_count" "$fail_count" >&2
echo "Run indexed at: $OUTPUT_ROOT/MANIFEST.md" >&2

if [[ "$OPEN_RESULT" == "true" ]]; then
  open -R "$CHECK_FILE" 2>/dev/null || true
fi

[[ "$fail_count" -eq 0 ]] || exit 1
exit 0
