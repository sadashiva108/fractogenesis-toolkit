#!/usr/bin/env bash
# =============================================================================
# reindex-artifact-runs.sh
#
# Indexes run directories that exist under a category's runs/ but have no row in
# its MANIFEST.md, then regenerates official/ from the completed index.
#
# Why this exists. `artifact_runs_rebuild` recomputes pointers FROM the manifest;
# it cannot see a run the manifest has never heard of. Runs arrive that way in
# two ways: relocated from a fallback path (verify-reimaged-system.md Step 1
# copies Phase 8's runs across when the artifact volume was not mounted during
# Phase 8), and migrated from a pre-run-category layout. In both cases the
# directories are on disk, correct, and invisible to every reader.
#
# CLASSIFICATION: `bin/` entrypoint. verify-reimaged-system.md Step 1 tells the
# reader to run it directly.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#
#   # Index anything unindexed in a category, then rebuild its pointers.
#   ./bin/reindex-artifact-runs.sh --category "$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts"
#
#   # Report what it would add, and write nothing.
#   ./bin/reindex-artifact-runs.sh --category <path> --dry-run
#
# Options:
#   --category PATH  Category root holding runs/ and MANIFEST.md. Required.
#   --dry-run        Print the rows that would be added; write nothing.
#   -h, --help       Show this message and exit.
#
# On row placement:
#   Rows are inserted in completion order rather than appended. Officialness for
#   a latest-wins point is the LAST matching row in file order, not the newest
#   timestamp -- see artifact_runs_rebuild. Appending a recovered 2026-08-19 run
#   below an existing 2026-08-24 one would therefore make the older run official.
#   Inserting in order preserves the invariant that rule depends on.
#
#   This does not conflict with the manifest being append-only. Append-only means
#   no existing row is ever rewritten or removed, and none is here: every prior
#   row survives verbatim, with its own text and its own relative order.
#
# Exit status:
#   0  Index is current, or was brought current.
#   2  Usage or configuration error.
# --- END USAGE ---
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/artifact-runs.sh
source "$RUNS_LIB"

CATEGORY=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --category)
      [[ -n "${2:-}" ]] || { echo "ERROR: --category needs a value" >&2; exit 2; }
      CATEGORY="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help)
      sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "${BASH_SOURCE[0]}" | sed -e 's/^# \{0,1\}//' -e '/^--- \(BEGIN\|END\) USAGE ---$/d'
      exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$CATEGORY" ]]; then
  echo "ERROR: --category is required." >&2
  exit 2
fi
if [[ ! -d "$CATEGORY/runs" ]]; then
  echo "ERROR: no runs/ under: $CATEGORY" >&2
  exit 2
fi

MANIFEST="$CATEGORY/MANIFEST.md"
if [[ ! -f "$MANIFEST" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "NOTE: $MANIFEST does not exist; it would be created." >&2
  else
    _artifact_runs_ensure_manifest "$MANIFEST" || exit 2
  fi
fi

# A run's result is recoverable from what it wrote. Reading it keeps a recovered
# row as informative as one written at the time, rather than a bare em dash.
result_for() {
  local dir="$1" p w f
  if [[ -f "$dir/checklist.md" ]]; then
    p="$(grep -c '| `PASS` |' "$dir/checklist.md" 2>/dev/null || true)"
    w="$(grep -c '| `WARN` |' "$dir/checklist.md" 2>/dev/null || true)"
    f="$(grep -c '| `FAIL` |' "$dir/checklist.md" 2>/dev/null || true)"
    printf '%s pass / %s warn / %s fail' "${p:-0}" "${w:-0}" "${f:-0}"
    return 0
  fi
  if [[ -f "$dir/rows.tsv" ]]; then
    p="$(grep -c "$(printf '\t')PASS$(printf '\t')" "$dir/rows.tsv" 2>/dev/null || true)"
    w="$(grep -c "$(printf '\t')WARN$(printf '\t')" "$dir/rows.tsv" 2>/dev/null || true)"
    printf '%s pass / %s warn' "${p:-0}" "${w:-0}"
    return 0
  fi
  printf '—'
}

NEW_ROWS=""
added=0

for dir in "$CATEGORY"/runs/*; do
  [[ -d "$dir" ]] || continue
  id="$(basename "$dir")"
  case "$id" in
    .*) continue ;;
  esac

  # Already indexed: the manifest names the run id in its "Run or target" column.
  if grep -q -- "\`$id\`" "$MANIFEST" 2>/dev/null; then
    continue
  fi

  stamp="$(printf '%s' "$id" | sed -n 's/^.*-\([0-9]\{8\}-[0-9]\{6\}\)$/\1/p')"
  if [[ -z "$stamp" ]]; then
    echo "SKIP  $id (no trailing YYYYMMDD-HHMMSS stamp; not a run id)" >&2
    continue
  fi
  context="${id%-$stamp}"
  point="$(_artifact_runs_point_of "$context")"
  completed="$(printf '%s' "$stamp" | sed 's/^\(....\)\(..\)\(..\)-\(..\)\(..\)\(..\)$/\1-\2-\3 \4:\5:\6/')"

  NEW_ROWS="${NEW_ROWS}| ${completed} | run | \`${context}\` | ${point} | \`${id}\` | $(result_for "$dir") | recovered by reindex |"$'\n'
  added=$(( added + 1 ))
  echo "  index $id" >&2
done

if [[ "$added" -eq 0 ]]; then
  echo "Index is already current: $CATEGORY" >&2
else
  if [[ "$DRY_RUN" == true ]]; then
    echo "" >&2
    printf '%s' "$NEW_ROWS"
    echo "(--dry-run: nothing written)" >&2
    exit 0
  fi

  # Merge in completion order. The Completed column is a fixed-width ISO stamp,
  # so a lexical sort is a chronological one; -s keeps rows that share a second
  # in the order they were already in.
  #
  # Fields are whitespace-separated, and the leading `|` is field 1 -- so the
  # date is field 2 and the time field 3. Sorting on -k2,2 alone collapses every
  # run recorded on one day into an arbitrary order, which for a latest-wins
  # point silently changes which run is official.
  HEADER="$(sed -n '1,/^|---|/p' "$MANIFEST")"
  {
    printf '%s\n' "$HEADER"
    {
      sed -n '/^|---|/,$p' "$MANIFEST" | sed '1d'
      printf '%s' "$NEW_ROWS"
    } | grep -v '^[[:space:]]*$' | sort -s -k2,3
  } > "$MANIFEST.reindex.tmp"
  mv "$MANIFEST.reindex.tmp" "$MANIFEST"
  echo "Indexed $added run(s) in $CATEGORY" >&2
fi

if [[ "$DRY_RUN" == true ]]; then
  exit 0
fi

artifact_runs_rebuild "$CATEGORY"
