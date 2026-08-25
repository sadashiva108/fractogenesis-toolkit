#!/usr/bin/env bash
# =============================================================================
# capture-system-state.sh
#
# Walks the restore-relevant paths and records what is on disk: path, kind,
# mode, size, mtime and SHA-256, one row each. Run once BEFORE the erase and
# once after the machine is rebuilt, so the two can be compared.
#
# WHY THIS EXISTS. Evidence in this workflow sits on two planes. The probe plane
# -- command output captured as text -- has both a pre-image and a post-image
# side, which is what `compare-restored-state.sh` joins. The state plane had a
# post-image side only, because nothing hashed those paths before the erase. So
# the cross-erase question was answered by version strings, when it could be
# answered by hashes: not "java reports 21.0.11 as recorded", but "this SSH key
# is byte-for-byte the key that was on the old machine".
#
# `capture-` and not `record-`: this is a paired pre-image/post-image inventory
# of system state, re-run after the reimage so the two can be compared, which is
# what that prefix means in .github/guides/script-types-and-locations.md.
# `bin/record-restore-state.sh` is a different thing -- it captures the same
# paths WITHIN one restore phase, before and after that phase runs, and its
# output belongs to the phase rather than to the machine.
#
# Both read the target list from .internal/restore-state-targets.conf.sh and
# observe paths through .internal/state-walk.sh, because a delta joins two walks
# row for row: any difference in how a path is observed shows up as a change the
# machine never made.
#
# This file is intended for bin/. It is a normal entrypoint.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/capture-system-state.sh
#
#   # BEFORE the erase, on the machine being replaced
#   ./bin/capture-system-state.sh --phase pre-image
#
#   # After the rebuild, once the restore phases have run
#   ./bin/capture-system-state.sh --phase post-image
#
#   # Preview without writing
#   ./bin/capture-system-state.sh --phase pre-image --dry-run
#
# Options:
#   --phase PHASE         pre-image | post-image. Required.
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --dry-run             Print the summary; write nothing.
#   --no-delta            Skip the cross-erase delta on a post-image run.
#   -h, --help            Show this message and exit.
#
# Where it writes:
#   $REIMAGE_ARTIFACT_ROOT/system-state/<phase>-<stamp>/state.tsv
#   $REIMAGE_ARTIFACT_ROOT/system-state/<phase>-<stamp>/state.md
#
#   Its own top-level category, exactly like system-inventory/, because it holds
#   both sides of the erase. It does NOT belong under reimaged-system/, which is
#   post-image by construction -- a pre-image bundle there would contradict the
#   rule that let those lineages drop their `post-image-` prefix.
#
#   A post-image run additionally writes the cross-erase delta beside the other
#   comparison, under
#   $REIMAGE_ARTIFACT_ROOT/reimaged-system/comparisons/runs/system-state-delta-<stamp>/
#
# Exit status:
#   0  Capture written (and delta, where one was possible).
#   1  Capture written but rows need attention, or the delta could not be built.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

# Deliberately NOT `set -e`, and no ERR trap. Every observation in the walk is
# allowed to fail: an absent path, an unreadable keychain and a `stat` that does
# not support the requested format all have to produce a ROW saying so. That is
# the whole output. Aborting on the first one would discard the rest of the
# picture and report a capture as broken when it is doing its job. Same footing
# as the validators in bin/ -- `-u` and `pipefail` are still wanted.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"
[[ -f "$CONFIG_LOADER" ]] || { echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2; exit 2; }

ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER" || { echo "ERROR: shared config failed to load (status $?)" >&2; exit 2; }

for lib in restore-state-targets.conf.sh state-walk.sh artifact-runs.sh; do
  [[ -f "$REPO_ROOT/.internal/$lib" ]] || { echo "ERROR: not found: .internal/$lib" >&2; exit 2; }
  # shellcheck source=/dev/null
  source "$REPO_ROOT/.internal/$lib"
done

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" | sed '1d;$d;s/^# //;s/^#$//'
}
require_option_value() {
  if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
    echo "ERROR: $1 requires a non-empty value." >&2; usage >&2; exit 2
  fi
}

PHASE=""
DRY_RUN=false
WANT_DELTA=true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)         require_option_value "$1" "${2:-}"; PHASE="$2"; shift 2 ;;
    --artifact-root) require_option_value "$1" "${2:-}"; REIMAGE_ARTIFACT_ROOT="$2"; shift 2 ;;
    --dry-run)       DRY_RUN=true; shift ;;
    --no-delta)      WANT_DELTA=false; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$PHASE" in
  pre-image|post-image) ;;
  "") echo "ERROR: --phase is required. Supported: pre-image, post-image" >&2; usage >&2; exit 2 ;;
  *)  echo "ERROR: --phase must be 'pre-image' or 'post-image', not: $PHASE" >&2; exit 2 ;;
esac

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" || ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set or not a directory." >&2
  exit 2
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
CATEGORY="$REIMAGE_ARTIFACT_ROOT/system-state"
BUNDLE="$CATEGORY/$PHASE-$STAMP"
ROWS_FILE="$(mktemp)"
NOTES_FILE="$(mktemp)"
cleanup() { rm -f "$ROWS_FILE" "$NOTES_FILE"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Walk
# ---------------------------------------------------------------------------
echo "Capturing $PHASE system state..." >&2
TARGET_COUNT=0
while IFS= read -r spec_line; do
  [[ -n "$spec_line" ]] || continue
  t_mode="${spec_line%%@@*}"
  t_rest="${spec_line#*@@}"
  t_spec="${t_rest%%@@*}"
  t_note="${t_rest#*@@}"
  printf '%s\t%s\n' "$t_spec" "$t_note" >> "$NOTES_FILE"
  capture_target "$t_mode" "$t_spec"
  TARGET_COUNT=$(( TARGET_COUNT + 1 ))
done < <(restore_state_targets)

ROW_COUNT="$(wc -l < "$ROWS_FILE" | tr -d ' ')"
PRESENT="$(awk -F'\t' '$2 == "present"' "$ROWS_FILE" | wc -l | tr -d ' ')"
ABSENT="$(awk -F'\t' '$2 == "absent"' "$ROWS_FILE" | wc -l | tr -d ' ')"
UNRESOLVED="$(awk -F'\t' '$2 == "unresolved"' "$ROWS_FILE" | wc -l | tr -d ' ')"
UNREADABLE="$(awk -F'\t' '$2 == "unreadable"' "$ROWS_FILE" | wc -l | tr -d ' ')"

emit_note() {
  printf '# System State — %s — %s\n\n' "$PHASE" "$STAMP"
  printf 'Generated by `bin/capture-system-state.sh` on %s.\n\n' "$(date)"
  printf 'Recorded on `%s` as user `%s`, with `HOME=%s`.\n\n' \
    "$(hostname -s 2>/dev/null || echo unknown)" "$(id -un)" "$HOME"
  printf '%s targets, %s rows: %s present, %s absent, %s unresolved, %s unreadable.\n\n' \
    "$TARGET_COUNT" "$ROW_COUNT" "$PRESENT" "$ABSENT" "$UNRESOLVED" "$UNREADABLE"
  printf 'Full detail is in `state.tsv` beside this file. Columns:\n'
  printf '`target state kind mode size mtime sha256 path`, tab-separated, path last.\n\n'
  printf 'A pre-image bundle is only comparable to a post-image one taken as the\n'
  printf 'same user with the same `HOME`: rows are keyed on absolute path, so a\n'
  printf 'different home turns every row into an add and a remove.\n'
}

if $DRY_RUN; then
  emit_note
  echo "(--dry-run: nothing written)" >&2
  exit 0
fi

mkdir -p "$BUNDLE"
cp "$ROWS_FILE" "$BUNDLE/state.tsv"
emit_note > "$BUNDLE/state.md"
echo "State → $BUNDLE/state.md" >&2

# ---------------------------------------------------------------------------
# Cross-erase delta -- post-image only
#
# Goes under reimaged-system/comparisons/ beside the inventory diff, because it
# IS a comparison and that is where comparisons are indexed. The captures it
# reads live in system-state/, because those are captures.
# ---------------------------------------------------------------------------
if [[ "$PHASE" != "post-image" ]] || ! $WANT_DELTA; then
  exit 0
fi

PRE_BUNDLE="$(find "$CATEGORY" -maxdepth 1 -type d -name 'pre-image-*' 2>/dev/null | sort | tail -1)"
if [[ -z "$PRE_BUNDLE" || ! -f "$PRE_BUNDLE/state.tsv" ]]; then
  echo "" >&2
  echo "NOTE: no pre-image system-state bundle under $CATEGORY — delta not built." >&2
  echo "      It has to be captured before the erase, on the machine being replaced." >&2
  exit 1
fi

PRE_HOME="$(sed -n 's/.*with `HOME=\(.*\)`\./\1/p' "$PRE_BUNDLE/state.md" 2>/dev/null | head -1)"
if [[ -n "$PRE_HOME" && "$PRE_HOME" != "$HOME" ]]; then
  echo "" >&2
  echo "ERROR: the pre-image bundle was taken with HOME=$PRE_HOME, this run has HOME=$HOME." >&2
  echo "HINT:  rows are keyed on absolute path, so joining these would report every" >&2
  echo "HINT:  row as both added and removed. Refusing rather than emitting that." >&2
  exit 1
fi

COMPARISONS="$REIMAGE_ARTIFACT_ROOT/reimaged-system/comparisons"
if ! artifact_run_begin "$COMPARISONS" "system-state-delta"; then
  echo "ERROR: could not stage the delta run under $COMPARISONS" >&2
  exit 1
fi

{
  printf '# System State — Cross-Erase Delta — %s\n\n' "$STAMP"
  printf 'Generated by `bin/capture-system-state.sh` on %s.\n\n' "$(date)"
  printf 'What the reimage changed on disk, path by path. Both sides are recordings\n'
  printf 'of the same target list, so nothing here can go stale.\n\n'
  printf -- '- before the erase: `system-state/%s`\n' "$(basename "$PRE_BUNDLE")"
  printf -- '- after the rebuild: `system-state/%s`\n\n' "$(basename "$BUNDLE")"
  printf '| Path | After | Before | Verdict |\n| --- | --- | --- | --- |\n'
  awk -F'\t' '
    FNR == NR { b[$8] = $2 " " $4 " " $7; next }
    { a = $2 " " $4 " " $7
      if ($8 in b) { print $8 "\t" a "\t" b[$8]; delete b[$8] }
      else         { print $8 "\t" a "\tABSENT" } }
    END { for (path in b) print path "\tABSENT\t" b[path] }
  ' "$PRE_BUNDLE/state.tsv" "$BUNDLE/state.tsv" | sort | while IFS=$'\t' read -r path after before; do
    [[ -n "$path" ]] || continue
    sa="${after%% *}"; sb="${before%% *}"
    if   [[ "$after"  == "ABSENT" ]]; then verdict="**lost in the reimage**"
    elif [[ "$before" == "ABSENT" ]]; then verdict="new"
    elif [[ "$sa" == "absent" && "$sb" == "absent" ]]; then verdict="absent both"
    elif [[ "$sa" != "absent" && "$sb" == "absent" ]]; then verdict="new"
    elif [[ "$sa" == "absent" && "$sb" != "absent" ]]; then verdict="**not restored**"
    elif [[ "$after" == "$before" ]]; then verdict="identical"
    else
      ha="${after##* }"; hb="${before##* }"
      ma="$(printf '%s' "$after"  | awk '{print $2}')"
      mb="$(printf '%s' "$before" | awk '{print $2}')"
      if   [[ "$ha" != "$hb" && "$ha" != "-" && "$hb" != "-" ]]; then verdict="**content differs**"
      elif [[ "$ma" != "$mb" ]]; then verdict="mode differs"
      else verdict="differs"; fi
    fi
    printf '| %s | `%s` | `%s` | %s |\n' "$path" "$after" "$before" "$verdict"
  done
  printf '\n'
  printf -- '- **identical** is the strongest row this workflow produces: same path, same mode, same SHA-256 across the erase.\n'
  printf -- '- **not restored** is a path that existed before and does not now. Read every one.\n'
  printf -- '- **content differs** on a key or a config is worth explaining. On a keychain it is expected — they churn on every access.\n'
  printf -- '- **new** is a path this machine has and the old one did not, which a restore should rarely produce.\n'
  printf -- '- Each column is `<state> <mode> <sha256>`. A `-` means the field does not apply.\n'
} > "$ARTIFACT_RUN_DIR/comparison.md"

if ! artifact_run_finalize "$COMPARISONS" "system-state-delta" "$ARTIFACT_RUN_ID" \
     "$(grep -c 'not restored\|content differs' "$ARTIFACT_RUN_DIR/comparison.md" || true) row(s) to read" ""; then
  echo "ERROR: could not finalize the delta run" >&2
  exit 1
fi

echo "Delta → $ARTIFACT_RUN_DIR/comparison.md" >&2
echo "Indexed at: $COMPARISONS/MANIFEST.md" >&2
exit 0
