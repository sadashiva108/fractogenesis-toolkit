#!/usr/bin/env bash
# =============================================================================
# record-decision.sh
#
# Append one decision to the reimage event's decisions log: a deliberate "not
# restored", a retirement, an accepted difference -- the things no capture can
# hold and no checklist row has room for.
#
# WHY THIS EXISTS. `restore-access.md` states the problem exactly, about a
# retired SSH key: "the retirement lives only on this Mac, and only until the
# next re-run [...] Nothing else in the workflow can tell your deletion from an
# accident." The pre-image image is immutable and legitimately still holds the
# key, so every future comparison flags it, forever, with nothing on the other
# side of the ledger saying the deletion was deliberate. This is that other side.
#
# WHY ONE APPEND-ONLY FILE AND NOT DATED ONES. A capture is superseded by a
# later capture, which is why the run categories are dated. A decision is not
# superseded by a later decision -- both remain true, and the older one is
# usually the one you need six months on. Dated files would scatter a single
# narrative across the drive and leave the reader guessing which file holds the
# answer. One file per reimage event, and the artifact root already IS the event.
#
# WHY `--excepts`. A decision that only a human can find is one a comparison
# will re-flag every time it runs. Naming the lineage a decision excepts --
# `restore-access-inventory-diff` -- turns "why is this still flagged?" into a
# lookup: `--check restore-access-inventory-diff`. Adding a row label after a
# colon goes further, and `compare-restored-state.sh` marks that row **decided**
# in the comparison itself, which is where the question actually gets asked. The
# field is free text on purpose; it records intent, and nothing here enforces
# that the lineage exists, because a decision may well outlive the artifact it
# explains.
#
# NOTHING IS EVER REWRITTEN. Entries are appended and never edited by this
# script. Correcting a decision means appending the correction, the same rule
# the run manifests follow, for the same reason: the record of what you believed
# at the time is the part with evidentiary value.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#
#   # Record a decision, with the reason given inline.
#   ./bin/record-decision.sh \
#     --runbook restore-access \
#     --title "Retired id_rsa_shiva and id_rsa_work" \
#     --excepts restore-access-inventory-diff:id_rsa_shiva \
#     --excepts restore-access-inventory-diff:id_rsa_work \
#     --reason "Both keys were expired and unused. The DMG is immutable and
#               still carries them, so the inventory diff will report them
#               missing on every future run."
#
#   # Record a decision, composing the reason on stdin (end with Ctrl-D).
#   ./bin/record-decision.sh --runbook restore-home --title "OneDrive not restored"
#
#   # Read the log, or ask whether a flagged lineage is already explained.
#   ./bin/record-decision.sh --list
#   ./bin/record-decision.sh --check restore-access-inventory-diff
#
# Options:
#   --runbook NAME      Runbook stem the decision belongs to (`restore-access`),
#                       never a phase ordinal -- ordinals renumber.
#   --title TEXT        One-line summary. Becomes the entry heading.
#   --excepts REF       An artifact or lineage this decision explains away.
#                       Repeatable. Optional. Two shapes:
#                         <lineage>          explains the whole comparison
#                         <lineage>:<label>  explains one row, matched exactly
#                       `compare-restored-state.sh` reads both: the first lists
#                       the entry under Recorded Decisions, the second also marks
#                       that row **decided**. The label must match the row text
#                       exactly -- a near miss would excuse the wrong row, which
#                       is worse than excusing none.
#   --reason TEXT       The body. Omit to compose it on stdin.
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT for this invocation.
#   --notes-root PATH   Directory holding decisions.md.
#                       Default: <artifact-root>/reimaged-system/restore-notes
#   --list              Print the whole log and exit.
#   --check REF         Print entries whose `Excepts` mentions REF, and exit.
#                       Exit 1 when none match, so it is usable in a test.
#   -h, --help          Show this message and exit.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Output location:
#   $REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/decisions.md
#
# Exit status:
#   0  Entry appended, or the requested read succeeded.
#   1  --check found no matching entry.
#   2  Usage, configuration, or prerequisite error -- including an artifact root
#      that is unset or not a mounted directory, and a notes root that resolves
#      inside the repo checkout.
# --- END USAGE ---
# =============================================================================

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

# Keep loading permissive: --artifact-root is applied after parsing, so the
# resolved value is validated here rather than during config load.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

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
RUNBOOK=""
TITLE=""
REASON=""
NOTES_ROOT=""
MODE="append"
CHECK_REF=""
EXCEPTS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runbook)       require_option_value "$1" "${2:-}"; RUNBOOK="$2"; shift 2 ;;
    --title)         require_option_value "$1" "${2:-}"; TITLE="$2"; shift 2 ;;
    --reason)        require_option_value "$1" "${2:-}"; REASON="$2"; shift 2 ;;
    --excepts)       require_option_value "$1" "${2:-}"; EXCEPTS[${#EXCEPTS[@]}]="$2"; shift 2 ;;
    --notes-root)    require_option_value "$1" "${2:-}"; NOTES_ROOT="$2"; shift 2 ;;
    --artifact-root) require_option_value "$1" "${2:-}"; REIMAGE_ARTIFACT_ROOT="$2"; shift 2 ;;
    --list)          MODE="list"; shift ;;
    --check)         require_option_value "$1" "${2:-}"; MODE="check"; CHECK_REF="$2"; shift 2 ;;
    -h|--help)       usage; exit 0 ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve the destination
# ---------------------------------------------------------------------------
absolute_path() {
  # Lexically resolve a possibly-relative path against $PWD without requiring it
  # to exist, so the checkout guard below cannot be defeated by relativity.
  local input="$1" resolved="" rest segment
  case "$input" in
    /*) ;;
    *) input="$PWD/$input" ;;
  esac
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

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" || ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set or not a directory. Reconnect the artifact volume, source reimage.env, or pass --artifact-root PATH." >&2
  exit 2
fi

if [[ -z "$NOTES_ROOT" ]]; then
  NOTES_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes"
fi
NOTES_ROOT="$(absolute_path "$NOTES_ROOT")"

# Safety invariant: refuse to write generated output under the repo checkout.
if [[ -n "${REPO_ROOT:-}" && ( "$NOTES_ROOT" == "$REPO_ROOT" || "$NOTES_ROOT" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $NOTES_ROOT" >&2
  exit 2
fi

LOG="$NOTES_ROOT/decisions.md"

# ---------------------------------------------------------------------------
# Read modes
# ---------------------------------------------------------------------------
if [[ "$MODE" == "list" ]]; then
  if [[ ! -f "$LOG" ]]; then
    echo "No decisions recorded yet: $LOG" >&2
    exit 0
  fi
  cat "$LOG"
  exit 0
fi

if [[ "$MODE" == "check" ]]; then
  if [[ ! -f "$LOG" ]]; then
    echo "No decisions recorded yet: $LOG" >&2
    exit 1
  fi
  # Print the heading of every entry whose Excepts line mentions the reference,
  # so a flagged comparison can be answered without reading the whole log.
  if awk -v ref="$CHECK_REF" '
      /^## / { heading = $0 }
      /^- \*\*Excepts:\*\*/ {
        if (index($0, ref) > 0) { print heading; found = 1 }
      }
      END { exit(found ? 0 : 1) }
    ' "$LOG"; then
    exit 0
  fi
  echo "No decision recorded that excepts: $CHECK_REF" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Append mode
# ---------------------------------------------------------------------------
if [[ -z "$RUNBOOK" ]]; then
  echo "ERROR: --runbook NAME is required." >&2
  usage >&2
  exit 2
fi
if [[ -z "$TITLE" ]]; then
  echo "ERROR: --title TEXT is required." >&2
  usage >&2
  exit 2
fi

# A runbook stem, never a phase ordinal: this workflow has renumbered its phases
# once already, and a decision naming the old number is wrong from that moment
# with nothing to catch it.
case "$RUNBOOK" in
  ""|*[!a-zA-Z0-9-]*) echo "ERROR: --runbook must be a runbook stem, not a phase ordinal: $RUNBOOK" >&2; exit 2 ;;
  [0-9]*)             echo "ERROR: --runbook must be a runbook stem, not a phase ordinal: $RUNBOOK" >&2; exit 2 ;;
esac

if ! mkdir -p "$NOTES_ROOT" 2>/dev/null; then
  echo "ERROR: cannot create notes root: $NOTES_ROOT" >&2
  exit 2
fi

if [[ -z "$REASON" ]]; then
  if [[ -t 0 ]]; then
    echo "Type the reason. End with Ctrl-D on a blank line." >&2
  fi
  REASON="$(cat)"
fi
if [[ -z "${REASON//[[:space:]]/}" ]]; then
  echo "ERROR: a decision with no reason is a note nobody can act on; supply --reason or type one." >&2
  exit 2
fi

if [[ ! -f "$LOG" ]]; then
  {
    printf '# Decisions — %s\n\n' "$(basename "$REIMAGE_ARTIFACT_ROOT")"
    printf 'Append-only. One entry per decision that no capture can hold: a deliberate\n'
    printf '"not restored", a retirement, an accepted difference.\n\n'
    printf 'Entries are never edited or removed. Correct one by appending the correction —\n'
    printf 'what was believed at the time is the part with evidentiary value.\n\n'
    printf 'An `Excepts` reference names an artifact or lineage the decision explains, so a\n'
    printf 'comparison that keeps flagging something has an answer on this side of the\n'
    printf 'ledger. Ask with `./bin/record-decision.sh --check <reference>`.\n'
  } > "$LOG"
fi

{
  printf '\n---\n\n'
  printf '## %s — %s\n\n' "$(date +%Y-%m-%d)" "$TITLE"
  printf -- '- **Runbook:** `%s`\n' "$RUNBOOK"
  if [[ ${#EXCEPTS[@]} -gt 0 ]]; then
    printf -- '- **Excepts:**'
    for ref in "${EXCEPTS[@]}"; do
      printf ' `%s`' "$ref"
    done
    printf '\n'
  else
    printf -- '- **Excepts:** nothing — this decision does not explain away a flagged artifact\n'
  fi
  printf -- '- **Recorded:** %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf '%s\n' "$REASON"
} >> "$LOG"

echo "Decision recorded → $LOG" >&2
if [[ ${#EXCEPTS[@]} -gt 0 ]]; then
  echo "  A future run can find it with: ./bin/record-decision.sh --check ${EXCEPTS[0]}" >&2
fi
