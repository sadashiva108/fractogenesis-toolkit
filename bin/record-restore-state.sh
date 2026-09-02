#!/usr/bin/env bash
# =============================================================================
# record-restore-state.sh
#
# Records what is on the machine at a restore phase's boundary, so the phase's
# own before and after can be compared. Writes hashes, never contents.
#
# WHY THIS EXISTS. Phase 10A's before-state is permanently gone, which is why
# its version-drift review had to be reconstructed from a cross-erase comparison
# against the Phase 4B inventory instead of a within-phase one. That is a weaker
# question: "does the rebuilt machine match the one that was erased" is not
# "did this runbook put what it promised where it promised". Every later restore
# phase can answer the second one, but only if something captures the before.
#
# It also unlocks `compare-restored-state.sh --against before`, which currently
# refuses with exit 2 rather than diffing against a baseline that does not exist.
#
# FOUR STATES, NOT TWO. present / absent / unresolved / unreadable.
#
#   unresolved is the one that matters and the reason a naive check is wrong.
#   With JAVA_HOME empty, "$JAVA_HOME/lib/security" collapses to
#   "/lib/security" -- a path that genuinely does not exist. Recording `absent`
#   there is a confident wrong answer about something that was never tested,
#   and at a `before` boundary an empty JAVA_HOME is the NORMAL state, because
#   restore-access.md Step 6 is what sets it.
#
#   unreadable separates "this file is not there" from "this file is there and
#   I could not read it". A keychain or a root-owned key can be the second.
#
# HASHES, NOT CONTENTS. Half these paths are SSH private keys and keychains.
# A SHA-256 is what makes a before/after diff work and carries nothing back.
# Filenames ARE recorded in the clear: the DMG's own build manifest already
# lists them, and an obscured name makes the diff unreadable for no gain.
#
# CLASSIFICATION: `bin/` entrypoint. It is user-facing -- restore-access.md
# tells the reader to run it directly -- which is the graduation rule in
# `.github/guides/script-types-and-locations.md` verbatim. It was first drafted
# under `.internal/restore/` on the strength of a carve-out that kept the
# boundary recorders there. That carve-out has since been removed, its two
# factual premises having failed when measured, and the recorders now sit in
# `bin/` beside this file.
#
# It keeps `set -uo pipefail` rather than `set -euo pipefail`, which the guide
# allows for a validator: every target must produce a row, and aborting on the
# first unreadable path would discard the rest of the picture. `bin/` already
# holds several scripts on that footing -- `reimage-checklist.sh`,
# `verify-doc-paths.sh`, `verify-artifact-config.sh`.
#
# It loads shared config because it needs REIMAGE_ARTIFACT_ROOT to know where to
# write.
#
# SHARED SCAFFOLDING, DEFERRED. Its option parsing, `absolute_path`, the
# repo-checkout guard, and the artifact_run_begin / finalize bracket duplicate
# the two boundary recorders now beside it in `bin/`. It does NOT duplicate
# `record` / `record_manual` -- there is no PASS/WARN/FAIL model here at all,
# only rows of observed state. So the extraction candidate is narrower than
# `script-types-and-locations.md` anticipated when it said "extract when a third
# recorder appears": a restore-helper PREAMBLE, not a recorder library. Left for
# the entrypoint review, which will move code between `bin/` and `.internal/`
# and would otherwise force a re-extraction. Named here so it is not
# rediscovered as an oversight.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#
#   # Capture Phase 10B's before-state. Run this BEFORE Step 1 mounts the DMG.
#   ./bin/record-restore-state.sh --runbook restore-access --point before
#
#   # Capture the after-state at the end of the phase.
#   ./bin/record-restore-state.sh --runbook restore-access --point after
#
#   # Print what would be recorded without writing anything.
#   ./bin/record-restore-state.sh --runbook restore-access --point before --dry-run
#
# Options:
#   --runbook NAME         Which phase's target set to capture. Required.
#                         Supported: restore-access, restore-git,
#                         restore-repos, restore-apps.
#   --point POINT         before | after | delta. Default: before.
#
#                         `before` and `after` are captures: they walk the
#                         targets and record what is on disk. `delta` walks
#                         nothing -- it joins the official before and after runs
#                         and records what changed between them. It is a
#                         separate point rather than a side effect of `after`
#                         so it can be re-run when either side is re-pinned,
#                         and so one run directory holds one kind of thing.
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --output-root PATH    Category root for the run. A relative value is
#                         resolved against the current directory, and a
#                         destination inside the repo checkout is refused.
#                         Default: <artifact-root>/reimaged-system/state
#   --dry-run             Print the summary; write nothing.
#   --open                Reveal the generated run in Finder.
#   -h, --help            Show this message and exit.
#
# Output:
#   <artifact-root>/reimaged-system/state/runs/post-image-<runbook>-<point>-<stamp>/
#     state.tsv    one row per observed path, machine-readable
#     state.md     the rendered summary, and every row a human must act on
#   indexed in that category's MANIFEST.md.
#
#   `before` is a FIRST-WINS point: re-running leaves the earliest completed run
#   official, and says so on stderr. That is deliberate. A `before` captured
#   after the runbook has already written is well-formed and wrong, and the diff
#   it produces reads "nothing changed".
#
# state.tsv columns, tab-separated:
#   target  state  kind  mode  size  mtime  sha256  path
#
#   The PATH IS LAST on purpose. A filename may legally contain a tab, and every
#   earlier field is whitespace-squashed, so a pathological name costs the last
#   field rather than shifting every column. `rows.tsv` in
#   compare-restored-state.sh learned this the hard way: a recorded value
#   carrying a tab split one field into two and a consumer reading field 4 got
#   a label instead of a version.
#
#   A row whose state is not `present` carries `-` in mode/size/mtime/sha256.
#   A symlink carries its target in the sha256 column, prefixed `->`.
#
# Exit status:
#   0  Capture written, or printed under --dry-run. Unresolved and unreadable
#      rows are findings to read, not failures of the capture -- they are
#      counted in the summary and listed in state.md.
#   1  The capture could not be written or indexed.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -uo pipefail
# Not -e: every target must produce rows. A path that cannot be read is the most
# interesting thing this script records, and -e would abort on the first one.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ONE level up. This script lives in bin/, so the repo root is the parent. It
# was drafted under .internal/restore/ with `../..`; that resolution moved with
# it, and getting this wrong is the failure this repo has already hit twice --
# once with a script stranded in bin/ still using `../..`, and once with the
# same line needing `..` -> `../..` on the way out.
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"

if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi

ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

TARGETS_CONF="$REPO_ROOT/.internal/restore-state-targets.conf.sh"
if [[ ! -f "$TARGETS_CONF" ]]; then
  echo "ERROR: target table not found: $TARGETS_CONF" >&2
  exit 2
fi
# shellcheck source=../.internal/restore-state-targets.conf.sh
source "$TARGETS_CONF"

WALK_LIB="$REPO_ROOT/.internal/state-walk.sh"
if [[ ! -f "$WALK_LIB" ]]; then
  echo "ERROR: state walker not found: $WALK_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/state-walk.sh
source "$WALK_LIB"

RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/artifact-runs.sh
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
POINT="before"
OUTPUT_ROOT=""
DRY_RUN=false
OPEN_RESULT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runbook)         require_option_value "$1" "${2:-}"; RUNBOOK="${2%.md}"; shift 2 ;;
    --point)         require_option_value "$1" "${2:-}"; POINT="$2"; shift 2 ;;
    --artifact-root) require_option_value "$1" "${2:-}"; REIMAGE_ARTIFACT_ROOT="$2"; shift 2 ;;
    --output-root)   require_option_value "$1" "${2:-}"; OUTPUT_ROOT="$2"; shift 2 ;;
    --dry-run)       DRY_RUN=true; shift ;;
    --open)          OPEN_RESULT=true; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Runbooks are added to this list as they are reached, the same way the boundary
# recorders and the comparison do it, so each target set is written against a
# runbook someone has actually just followed. One list, checked in one place:
# the runbook name IS the artifact name, so there is no second table to drift.
SUPPORTED_RUNBOOKS="restore-access restore-git restore-repos restore-apps"

if [[ -z "${RUNBOOK:-}" ]]; then
  echo "ERROR: --runbook is required. Supported: $SUPPORTED_RUNBOOKS" >&2
  usage >&2
  exit 2
fi

case " $SUPPORTED_RUNBOOKS " in
  *" $RUNBOOK "*) PHASE_RUNBOOK="$RUNBOOK.md" ;;
  *) echo "ERROR: no target set defined for runbook: $RUNBOOK" >&2
     echo "HINT:  supported runbooks: $SUPPORTED_RUNBOOKS. Others are added as their runbooks are reached." >&2
     exit 2 ;;
esac

case "$POINT" in
  before|after) ;;
  delta) ;;
  *) echo "ERROR: --point must be 'before', 'after' or 'delta', not: $POINT" >&2; exit 2 ;;
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
# Target table
#
#   mode @@ spec @@ what this path is for in the phase
#
# `@@` rather than a single character because a spec contains `/`, `$`, `.` and
# `~`, and the note contains most punctuation. Parsed with parameter expansion,
# which is the only thing that handles a multi-character separator on Bash 3.2.
#
# Modes:
#   file     one path. Hash it.
#   tree     recurse. One row for the directory itself, then one per file,
#            symlink, AND subdirectory beneath it. Subdirectories are included
#            for the same reason the root is: an empty one must be visibly
#            empty rather than absent from the record.
#   shallow  one row for the directory itself, then one per entry at depth 1
#            only. For directories like ~/.config whose subtrees are enormous
#            and mostly irrelevant to this phase -- recursing there buries the
#            fifteen paths that matter under thousands that do not.
#
# The directory itself always gets a row, in both tree and shallow. Without it,
# a present-but-empty ~/.ssh produces no rows at all and reads exactly like a
# path that was never checked -- the empty-expectation-set trap this workflow
# keeps falling into.
# ---------------------------------------------------------------------------
# The target table lives in .internal/restore-state-targets.conf.sh so the
# pre-image walker reads the same list; see the header there for why.
# Phase 11A -- restore-git. Every path this phase writes, so the before-state
# says what was there first. `~/.ssh/config` is included because Step 3 rewrites
# it wholesale rather than appending, and the personal-root override is resolved
# from the environment because its location is per-operator.
# Clone destinations, depth 1. `shallow` and not `tree` on purpose: this phase
# restores 27 repositories, and a recursive walk would hash every file in all of
# them -- tens of thousands of rows to answer a question that is one row per
# repository. At depth 1 the before-state is "these roots are empty", the
# after-state is one row per restored repository, and the delta between them is
# literally the list of what this phase put back.
# Live application config, not the backup those steps read from. `shallow` on
# the big roots: IntelliJ keeps a subtree per version and Code/User holds every
# extension's state, and the question a before-state answers here is which of
# these existed before Phase 12 ran -- not a hash of every file inside them.
targets_restore_apps() {
  cat <<'TARGETS'
shallow@@~/Library/Application Support/JetBrains/@@Step 8 — IntelliJ per-version config roots
tree@@~/.docker/@@Step 9 — Docker CLI config, contexts, daemon.json
shallow@@~/Library/Application Support/Code/User/@@Step 6 — VS Code settings and keybindings
shallow@@~/Library/Application Support/obsidian/@@Step 4 — Obsidian vault registry
shallow@@~/Library/Application Support/Postman/@@Step 5 — Postman collections and environments
shallow@@~/Library/Application Support/com.raycast.macos/@@Step 7 — Raycast config
file@@~/Library/Preferences/com.apple.Terminal.plist@@Step 11 — Terminal profile
TARGETS
}

targets_restore_repos() {
  cat <<'TARGETS'
shallow@@$LOCAL_WORK_REPO_ROOT/@@Clone destination for work repositories — one row each
shallow@@$LOCAL_PERSONAL_REPO_ROOT/@@Clone destination for personal repositories — one row each
TARGETS
}

targets_restore_git() {
  cat <<'TARGETS'
file@@~/.gitconfig@@Step 4 — the global identity, written wholesale
tree@@~/.config/git/@@Step 6 — XDG config and config.local
file@@~/.ssh/config@@Step 3 — rewritten wholesale, not appended
file@@$LOCAL_PERSONAL_REPO_ROOT/.gitconfig@@Step 5 — personal-root override reached by includeIf
TARGETS
}

targets_restore_access() {
  restore_state_targets
}

# ---------------------------------------------------------------------------
# Resolution
#
# Returns 1 and sets UNRESOLVED_VAR when a variable in the spec expands empty.
# That distinction is the entire reason this function exists rather than a bare
# expansion: with JAVA_HOME unset, "$JAVA_HOME/lib/security" becomes
# "/lib/security", which does not exist -- so a naive test records `absent`,
# which is a confident wrong answer about a path nothing ever looked at.
#
# Every $NAME a spec carries is substituted, not one hardcoded variable. The
# table above uses $JAVA_HOME, $LOCAL_WORK_REPO_ROOT and $LOCAL_PERSONAL_REPO_ROOT;
# the original single-variable form resolved the latter two to their own literal
# text and then reported `absent` for a path nobody had looked at -- a wrong
# answer that reads exactly like a correct one. The expansion loop itself lives
# in .internal/state-walk.sh, which is where a third caller would find it.
#
# It reports through GLOBALS rather than stdout, and that is not a style choice.
# The obvious form -- `if ! resolved="$(resolve_target "$spec")"` -- runs the
# function in a SUBSHELL, so the UNRESOLVED_VAR it sets is set in a child and
# lost. The first fixture run printed "($ is empty)" with no variable name for
# exactly that reason. Two outputs, one of them on failure, means no command
# substitution.
# ---------------------------------------------------------------------------
# The walker lives in .internal/state-walk.sh so the pre-image capture observes
# paths identically; see the header there for why that matters to the join.

# Resolved before the delta branch below: a delta reads the category root to
# find the official before and after runs, so it cannot wait for the capture
# path to compute it.
if [[ -z "$OUTPUT_ROOT" ]]; then
  OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system/state"
fi
OUTPUT_ROOT="$(absolute_path "$OUTPUT_ROOT")"

# ---------------------------------------------------------------------------
# Phase delta -- emitted with the after-capture, not by a separate tool
#
# The delta is a join of this run's state.tsv against the official before-run's.
# Both are produced here, it reads nothing else, and it is only meaningful for
# the pair -- so it belongs beside the capture it describes rather than as an
# invocation of the comparison tool, which probes live commands against
# pre-image captures and shares none of this machinery.
#
# Writing it here also means it cannot go stale: a delta exists only inside the
# after-run it was computed from, and re-capturing produces a new one.
# ---------------------------------------------------------------------------
emit_delta() {
  local before_rel before_dir after_rel after_dir
  before_rel="$(artifact_run_official "$OUTPUT_ROOT" "${PHASE_RUNBOOK%.md}-before" 2>/dev/null)" || return 1
  [ -n "$before_rel" ] || return 1
  before_dir="$OUTPUT_ROOT/$before_rel"
  [ -f "$before_dir/state.tsv" ] || return 1

  after_rel="$(artifact_run_official "$OUTPUT_ROOT" "${PHASE_RUNBOOK%.md}-after" 2>/dev/null)" || return 1
  [ -n "$after_rel" ] || return 1
  after_dir="$OUTPUT_ROOT/$after_rel"
  [ -f "$after_dir/state.tsv" ] || return 1

  printf '# %s — Phase Delta — %s\n\n' "${PHASE_RUNBOOK%.md}" "$STAMP"
  printf 'What this phase changed on disk: the official before-state joined against\n'
  printf 'the official after-state. Both sides are recordings, so nothing here can go\n'
  printf 'stale; re-run this point if either side is re-recorded or re-pinned.\n\n'
  printf -- '- before: `%s`\n' "$before_rel"
  printf -- '- after:  `%s`\n\n' "$after_rel"
  printf '| Path | After | Before | Verdict |\n| --- | --- | --- | --- |\n'

  awk -F'\t' '
    FNR == NR { b[$8] = $2 " " $4 " " $7; next }
    {
      a = $2 " " $4 " " $7
      if ($8 in b) { print $8 "\t" a "\t" b[$8]; delete b[$8] }
      else         { print $8 "\t" a "\tABSENT" }
    }
    END { for (path in b) print path "\tABSENT\t" b[path] }
  ' "$before_dir/state.tsv" "$after_dir/state.tsv" | sort | while IFS=$'\t' read -r path after before; do
    # An absolute path is the join key. A row without one is a corrupted line --
    # a `stat` that returned multi-line output, a truncated write -- and joining
    # on it produces phantom adds and removes. Skip rather than report fiction.
    case "$path" in /*) ;; *) continue ;; esac
    verdict=""
    sa="${after%% *}"; sb="${before%% *}"
    if   [ "$after" = "ABSENT" ]; then verdict="**removed**"
    elif [ "$before" = "ABSENT" ]; then verdict="added"
    elif [ "$sa" = "absent" ] && [ "$sb" = "absent" ]; then verdict="unchanged"
    elif [ "$sa" != "absent" ] && [ "$sb" = "absent" ]; then verdict="added"
    elif [ "$sa" = "absent" ] && [ "$sb" != "absent" ]; then verdict="**removed**"
    elif [ "$after" = "$before" ]; then verdict="unchanged"
    else
      ha="${after##* }"; hb="${before##* }"
      ma="$(printf '%s' "$after"  | awk '{print $2}')"
      mb="$(printf '%s' "$before" | awk '{print $2}')"
      if   [ "$ha" != "$hb" ] && [ "$ha" != "-" ] && [ "$hb" != "-" ]; then verdict="content changed"
      elif [ "$ma" != "$mb" ]; then verdict="mode changed"
      else verdict="changed"; fi
    fi
    printf '| %s | `%s` | `%s` | %s |\n' "$path" "$after" "$before" "$verdict"
  done

  printf '\n'
  printf -- '- **added** and **content changed** are the phase working.\n'
  printf -- '- **removed** is the verdict to read twice: this phase restores, and should rarely delete.\n'
  printf -- '- **mode changed** on a key file is intended tightening; on anything else it is worth a look.\n'
  printf -- '- Each column is `<state> <mode> <sha256>`. A `-` means the field does not apply.\n'
}

# `delta` walks nothing: it joins two runs that already exist. The whole
# observation section below is skipped, and the run it writes holds delta.md
# instead of state.tsv, because a run directory should hold one kind of thing.
if [ "$POINT" = "delta" ]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    if emit_delta; then
      echo "" >&2
      echo "(--dry-run: nothing written)" >&2
      exit 0
    fi
    echo "ERROR: cannot build a delta for ${PHASE_RUNBOOK%.md}." >&2
    echo "HINT:  it needs an official before-state AND an official after-state." >&2
    echo "HINT:    ./bin/record-restore-state.sh --runbook ${PHASE_RUNBOOK%.md} --point before" >&2
    echo "HINT:    ./bin/record-restore-state.sh --runbook ${PHASE_RUNBOOK%.md} --point after" >&2
    exit 2
  fi

  DELTA_CONTEXT="${PHASE_RUNBOOK%.md}-delta"
  if ! artifact_run_begin "$OUTPUT_ROOT" "$DELTA_CONTEXT"; then
    echo "ERROR: could not stage a delta run under $OUTPUT_ROOT" >&2
    exit 1
  fi
  if ! emit_delta > "$ARTIFACT_RUN_DIR/delta.md" 2>/dev/null; then
    echo "ERROR: cannot build a delta for ${PHASE_RUNBOOK%.md}." >&2
    echo "HINT:  it needs an official before-state AND an official after-state." >&2
    exit 2
  fi
  DELTA_ROWS="$(grep -c '^| /' "$ARTIFACT_RUN_DIR/delta.md" 2>/dev/null || true)"
  if ! artifact_run_finalize "$OUTPUT_ROOT" "$DELTA_CONTEXT" "$ARTIFACT_RUN_ID" \
       "${DELTA_ROWS:-0} path(s) compared" ""; then
    echo "ERROR: could not finalize the delta run" >&2
    exit 1
  fi
  echo "Delta → $ARTIFACT_RUN_DIR/delta.md" >&2
  echo "Indexed at: $OUTPUT_ROOT/MANIFEST.md" >&2
  exit 0
fi

echo "Capturing ${PHASE_RUNBOOK%.md} $POINT-state..." >&2

TARGET_COUNT=0
while IFS= read -r spec_line; do
  [[ -n "$spec_line" ]] || continue
  t_mode="${spec_line%%@@*}"
  t_rest="${spec_line#*@@}"
  t_spec="${t_rest%%@@*}"
  t_note="${t_rest#*@@}"
  TARGET_COUNT=$(( TARGET_COUNT + 1 ))
  printf '%s\t%s\n' "$t_spec" "$t_note" >> "$NOTES_FILE"
  printf '  %-9s %s\n' "$t_mode" "$t_spec" >&2
  capture_target "$t_mode" "$t_spec"
done < <("targets_${RUNBOOK//-/_}")

# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------
list_rows_with_state() {
  awk -F'\t' -v want="$1" '$2 == want { printf "| `%s` | `%s` |\n", $1, $8 }' "$ROWS_FILE"
}

# Joined against the note column from the target table, so the summary says what
# each path is FOR rather than only how many rows it produced. NR==FNR is the
# standard two-file awk join and needs no sort on either side.
per_target_counts() {
  awk -F'\t' '
    NR == FNR { note[$1] = $2; next }
    { total[$1]++; state[$1"\t"$2]++ }
    END {
      for (t in total) {
        printf "| `%s` | %d | %d | %d | %d | %d | %s |\n", t, total[t],
          state[t"\tpresent"] + 0, state[t"\tabsent"] + 0,
          state[t"\tunresolved"] + 0, state[t"\tunreadable"] + 0, note[t]
      }
    }' "$NOTES_FILE" "$ROWS_FILE" | sort
}

emit_note() {
  # Titled by runbook -- see record-restore-prereqs.sh for why.
  printf '# %s — %s-State — %s\n\n' "${PHASE_RUNBOOK%.md}" "$POINT" "$STAMP"
  printf 'Generated by `bin/record-restore-state.sh` on %s.\n\n' "$(date)"
  printf 'Pairs with [[%s|%s]].\n\n' "${PHASE_RUNBOOK%.md}" "$PHASE_RUNBOOK"

  printf '## Summary\n\n'
  printf '| Outcome | Rows |\n| --- | --- |\n'
  printf '| present | %s |\n' "$n_present"
  printf '| absent | %s |\n' "$n_absent"
  printf '| unresolved | %s |\n' "$n_unresolved"
  printf '| unreadable | %s |\n' "$n_unreadable"
  printf '\n%s target(s), %s row(s).\n\n' "$TARGET_COUNT" "$n_rows"

  if [[ "$n_unresolved" -gt 0 ]]; then
    printf '## Unresolved — nothing was checked here\n\n'
    printf 'A variable in the target expanded empty, so the path was never tested.\n'
    printf 'This is **not** the same as absent, and at a `before` boundary it is often\n'
    printf 'the correct state: `JAVA_HOME` is set by `restore-access.md` Step 6, so an\n'
    printf 'empty one here means Step 6 has not run yet.\n\n'
    printf '| Target | Detail |\n| --- | --- |\n'
    list_rows_with_state unresolved
    printf '\n'
  fi

  if [[ "$n_unreadable" -gt 0 ]]; then
    printf '## Unreadable — present, but not hashed\n\n'
    printf 'These exist and could not be read, so they carry no hash and a later diff\n'
    printf 'cannot say whether they changed. Usually ownership or a locked keychain.\n\n'
    printf '| Target | Path |\n| --- | --- |\n'
    list_rows_with_state unreadable
    printf '\n'
  fi

  printf '## Per target\n\n'
  printf '| Target | Rows | present | absent | unresolved | unreadable | What it is for |\n'
  printf '| --- | --- | --- | --- | --- | --- | --- |\n'
  per_target_counts
  printf '\n'

  printf '## How to read this\n\n'
  printf -- '- A directory always gets its own row, before the rows for what is inside it. A present-but-EMPTY directory therefore shows one row and no children — which is a different fact from a directory nobody looked at, and the reason the distinction is drawn.\n'
  printf -- '- **absent** at a `before` boundary is the expected state for most of these. The phase is what creates them; the point of recording it is so the after-state has something to differ from.\n'
  printf -- '- `~/Library/Keychains/` churns on every keychain access, so its hashes differing between before and after proves nothing on its own. Read the file list rather than the hashes there.\n'
  printf -- '- Full detail is in `state.tsv` beside this file. Columns: `target state kind mode size mtime sha256 path`, tab-separated, path last.\n'
  printf -- '- Contents are never recorded. A SHA-256 is enough to tell whether a key changed and carries nothing back.\n'
}

# ---------------------------------------------------------------------------
# Write
# ---------------------------------------------------------------------------
if [[ "$DRY_RUN" == "true" ]]; then
  echo "" >&2
  emit_note
  echo "(--dry-run: nothing written)" >&2
  exit 0
fi

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" || ! -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "" >&2
  echo "ERROR: artifact root unavailable, so nothing was written." >&2
  echo "HINT:  rerun with --dry-run to see the result, or reconnect the drive." >&2
  echo "HINT:  a before-state that was not written is a before-state you do not have." >&2
  exit 2
fi


if [[ -n "${REPO_ROOT:-}" && ( "$OUTPUT_ROOT" == "$REPO_ROOT" || "$OUTPUT_ROOT" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $OUTPUT_ROOT" >&2
  exit 2
fi

# Context key: <phase>-<runbook>-<point>. The runbook name rather than the phase
# ordinal, because ordinals renumber and a directory already written to the
# drive cannot be renumbered afterwards.
RUN_CONTEXT="${PHASE_RUNBOOK%.md}-${POINT}"

if ! artifact_run_begin "$OUTPUT_ROOT" "$RUN_CONTEXT"; then
  echo "ERROR: could not stage a run under: $OUTPUT_ROOT" >&2
  exit 1
fi

if ! cp "$ROWS_FILE" "$ARTIFACT_RUN_DIR/state.tsv"; then
  echo "ERROR: could not write state.tsv" >&2
  artifact_run_abort
  exit 1
fi

if ! emit_note > "$ARTIFACT_RUN_DIR/state.md"; then
  echo "ERROR: could not write state.md" >&2
  artifact_run_abort
  exit 1
fi


if [ "$POINT" = "after" ]; then
  if artifact_run_official "$OUTPUT_ROOT" "${PHASE_RUNBOOK%.md}-before" >/dev/null 2>&1; then
    echo "" >&2
    echo "NEXT: both halves are recorded. Join them with" >&2
    echo "      ./bin/record-restore-state.sh --runbook ${PHASE_RUNBOOK%.md} --point delta" >&2
  else
    echo "" >&2
    echo "NOTE: no official before-state run for ${PHASE_RUNBOOK%.md}, so there is" >&2
    echo "      nothing to join this against. A before-state has to be recorded at" >&2
    echo "      the phase Step 0b, before the phase changes anything." >&2
  fi
fi

if ! artifact_run_finalize "$OUTPUT_ROOT" \
     "$n_present present / $n_absent absent / $n_unresolved unresolved / $n_unreadable unreadable"; then
  echo "ERROR: artifact-runs reported a problem finalizing the run — see the message above." >&2
  exit 1
fi

echo "" >&2
echo "State → $ARTIFACT_RUN_DIR/state.md" >&2
printf '%s present · %s absent · %s unresolved · %s unreadable  (%s rows, %s targets)\n' \
  "$n_present" "$n_absent" "$n_unresolved" "$n_unreadable" "$n_rows" "$TARGET_COUNT" >&2
echo "Run indexed at: $OUTPUT_ROOT/MANIFEST.md" >&2

if [[ "$n_unresolved" -gt 0 || "$n_unreadable" -gt 0 ]]; then
  echo "" >&2
  echo "NOTE: $n_unresolved unresolved and $n_unreadable unreadable row(s) — these were NOT checked." >&2
  echo "      They are listed in state.md. At a 'before' point an unresolved JAVA_HOME is normal." >&2
fi

if [[ "$OPEN_RESULT" == "true" ]]; then
  open -R "$ARTIFACT_RUN_DIR/state.md" 2>/dev/null || true
fi

exit 0
