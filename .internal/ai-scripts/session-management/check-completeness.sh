#!/usr/bin/env bash
# =============================================================================
# check-completeness.sh
#
# Is metadata.json COMPLETE against the markdown it was extracted from?
#
# The other three checkers ask whether a document is well formed: a table has
# the right columns, a count agrees with another count, a status agrees with a
# row. None of them asks whether anything is MISSING. 162 contaminated fields
# and 39 lost `Read:` bullets sat in 47 files while all three reported 0 FAIL --
# correctly, because the JSON was well formed. A person reading the output found
# it.
#
# "Completeness is not conformance" was already a written rule. This is the
# first thing that enforces it.
#
# CLASSIFICATION: .internal/ai-scripts/session-management/ helper. A thin shell
# wrapper so bin/verify-session-findings.sh can dispatch it like the other
# three; the checks themselves live in extract-metadata.py --check, beside the
# extractor whose output they audit. Two copies of the schema's invariants would
# be exactly the drift this repository keeps recording.
#
# --- BEGIN USAGE ---
# Usage:
#   ./bin/verify-session-findings.sh completeness
#
# Exit codes:
#   0  every metadata.json carries what its markdown holds
#   1  at least one does not
#   2  the repository layout could not be read
# --- END USAGE ---
# =============================================================================

set -uo pipefail

# THREE levels up: this sits in .internal/ai-scripts/session-management/.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT" || exit 2

case "${1:-}" in
  -h|--help) sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" | sed '1d;$d;s/^# //;s/^#$//'; exit 0 ;;
  '') : ;;
  *) echo "ERROR: unknown option: $1" >&2; exit 2 ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required." >&2
  exit 2
fi

printf '\nCompleteness — data against the markdown it came from\n\n'
exec python3 "$SCRIPT_DIR/extract-metadata.py" --check
