#!/usr/bin/env bash
# =============================================================================
# check-manifest-revision.sh
#
# Prints the next free APPLY-MANIFEST.md revision number.
#
# It exists because the rule it replaces could not work. That rule was "re-read
# the header block immediately before writing an entry and take the next free
# number", and it was followed exactly, by two sessions, who both took 167 --
# because AN UNCOMMITTED ENTRY IS NOT IN THE HEADER BLOCK THE OTHER SESSION
# READS. The same collision happened again two revisions later.
#
# So this scans BOTH places a number can be taken:
#
#   **Revision N** -- the header block at the top of the file
#   ## Revision N  -- the entry headings in the body
#
# An entry written but not yet summarised in the header is visible to the second
# scan, which is the whole point. Run it against the tree the patch will be
# APPLIED to, at the moment it is applied -- section 0028's decision 5.1: an
# entry is composed with its number left open and numbered at apply time, when
# the next free number is a fact rather than a guess.
#
# This file is intended for bin/. It reads one file and writes nothing. It does
# not load the shared reimage config: it inspects a repo-relative document and
# must work on a fresh checkout with no reimage.env.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#
#   # The number to write on the entry being applied now
#   ./bin/check-manifest-revision.sh
#
#   # The highest number already taken
#   ./bin/check-manifest-revision.sh --current
#
#   # Is a composed entry's number still free?
#   ./bin/check-manifest-revision.sh --free 181
#
#   # Show where each number was found
#   ./bin/check-manifest-revision.sh --verbose
#
# Options:
#   --current       Print the highest revision number already taken.
#   --free N        Exit 0 if N is free, 1 if it is taken.
#   --manifest PATH Read this manifest instead of ./APPLY-MANIFEST.md.
#   --verbose       Also report the highest number found in each of the two
#                   places, so a header that lags its entries is visible.
#   -h, --help      Show this message and exit.
#
# Exit codes:
#   0  printed a number, or --free found the number free
#   1  --free found the number already taken
#   2  the manifest could not be read, or a bad option was given
# --- END USAGE ---
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MANIFEST="$REPO_ROOT/APPLY-MANIFEST.md"
MODE="next"
CHECK_N=""
VERBOSE=false

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

require_value() {
  if [ -z "${2:-}" ] || case "${2:-}" in --*) true ;; *) false ;; esac; then
    echo "ERROR: $1 requires a value." >&2
    exit 2
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --current)  MODE="current"; shift ;;
    --free)     require_value "$1" "${2:-}"; MODE="free"; CHECK_N="$2"; shift 2 ;;
    --manifest) require_value "$1" "${2:-}"; MANIFEST="$2"; shift 2 ;;
    --verbose)  VERBOSE=true; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ ! -f "$MANIFEST" ]; then
  echo "ERROR: manifest not found: $MANIFEST" >&2
  exit 2
fi

if [ "$MODE" = "free" ]; then
  case "$CHECK_N" in
    ''|*[!0-9]*) echo "ERROR: --free needs a number, got: $CHECK_N" >&2; exit 2 ;;
  esac
fi

# Highest number matching a pattern. sed does the extraction so no GNU-only
# grep option is needed; sort -n rather than a Bash comparison loop so the file
# is walked once.
highest() {
  sed -n "$1" "$MANIFEST" | sort -n | tail -1
}

header_high="$(highest 's/^\*\*Revision \([0-9][0-9]*\)\*\*.*/\1/p')"
entry_high="$(highest  's/^## Revision \([0-9][0-9]*\)[^0-9].*/\1/p')"

header_high="${header_high:-0}"
entry_high="${entry_high:-0}"

if [ "$header_high" -ge "$entry_high" ]; then
  current="$header_high"
else
  current="$entry_high"
fi

if [ "$current" -eq 0 ]; then
  echo "ERROR: no revision numbers found in $MANIFEST" >&2
  exit 2
fi

if [ "$VERBOSE" = true ]; then
  printf 'header block: %s\n' "$header_high" >&2
  printf 'entry bodies: %s\n' "$entry_high" >&2
  if [ "$entry_high" -gt "$header_high" ]; then
    printf 'note: an entry exists that the header block does not summarise.\n' >&2
  fi
fi

case "$MODE" in
  current) echo "$current" ;;
  next)    echo $((current + 1)) ;;
  free)
    if [ "$CHECK_N" -gt "$current" ]; then
      echo "Revision $CHECK_N is free."
      exit 0
    fi
    echo "Revision $CHECK_N is taken. The next free one is $((current + 1))." >&2
    exit 1
    ;;
esac

exit 0
