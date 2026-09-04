#!/usr/bin/env bash
# =============================================================================
# verify-findings-structure.sh
#
# Verifies two structural invariants that sections 4c and 4d state and nothing
# else tests:
#
#   1. every data row in a findings/sessions table has its own table's column
#      count -- a row with the wrong number of cells renders shifted and reads
#      as data;
#   2. every findings bundle carries exactly one `STATUS-` tag, and it agrees
#      with the bundle's INDEX.md row, which is authoritative.
#
# Why this is separate from verify-findings-counts.sh. That script exists for
# DERIVED FACTS displayed twice -- its own header states the rule, "a fact has
# one home, and a copy is permitted only where a check fails on drift". A tag
# and its index row are such a pair and would fit there; a table's column count
# is not a copy of anything. Widening that script to cover shape would make the
# clearest sentence in its header untrue. See
# `docs/instruction-set-findings/0032-index-and-manifest-tables-have-a-shape-nothing-checks/`.
#
# Two shapes in the tree this must handle, both real:
#   - A FILE MAY HOLD MORE THAN ONE TABLE. docs/runbook-findings/INDEX.md has a
#     rollup above the detail table with different columns. The column count is
#     therefore taken per table, from the header that opens it, never per file.
#   - A BLANK CELL IS LEGAL. That detail table leaves the `Runbook` cell empty on
#     continuation rows, meaning "same as above". Emptiness is not checked; only
#     how many cells there are.
#
# This file is intended for bin/. It is an aggregate validator: it records every
# finding and reports all results rather than aborting on the first miss, so it
# deliberately does NOT use `set -e`. It reads the repository only -- it creates
# nothing, and it does not load the shared reimage config, because it inspects
# repo-relative documents and must verify on a fresh checkout.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   ./bin/verify-findings-structure.sh
#   ./bin/verify-findings-structure.sh --verbose   # also list every table found
#
# Exit codes:
#   0  every table is well formed and every tag agrees with its row
#   1  at least one does not
#   2  the repository layout could not be read
# --- END USAGE ---
# =============================================================================

VERBOSE=false
while [ $# -gt 0 ]; do
  case "$1" in
    --verbose) VERBOSE=true ;;
    -h|--help) sed -n '/--- BEGIN USAGE ---/,/--- END USAGE ---/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ ! -d docs ] || [ ! -d .github ]; then
  echo "ERROR: run from the repository root." >&2
  exit 2
fi

RED=''; GRN=''; YEL=''; BLD=''; RST=''
if [ -t 1 ]; then
  RED=$(printf '\033[0;31m'); GRN=$(printf '\033[0;32m'); YEL=$(printf '\033[1;33m')
  BLD=$(printf '\033[1m'); RST=$(printf '\033[0m')
fi

ok_count=0
fail_count=0
pass() { ok_count=$((ok_count + 1)); }
fail() {
  fail_count=$((fail_count + 1))
  printf '  %sFAIL%s  %s\n' "$RED" "$RST" "$1"
  [ -n "${2:-}" ] && printf '        %s\n' "$2"
  return 0
}

# --- 1. table shape, per table ----------------------------------------------
# A header is any row whose cells are all non-empty and which is followed by a
# separator row of dashes. Everything until the next blank line or next header
# belongs to it. Bash 3.2: no arrays needed, awk does the walk.
for doc in docs/*-findings/INDEX.md docs/sessions/INDEX.md docs/sessions/*/findings-manifest.md; do
  [ -f "$doc" ] || continue
  report="$(awk '
    # An escaped pipe is cell CONTENT, not a separator: wikilinks such as
    # [[path\|Label]] are legal and appear in docs/sessions/INDEX.md. Remove them
    # before counting, or every such row reads as one cell too many.
    function cells(line,  n) { gsub(/\\\|/, "", line); n = gsub(/\|/, "|", line); return n - 1 }
    /^\|[- :|]+\|$/ { if (pending != "") { want = pcells; tbl = pending; pending = "" }; next }
    /^\|/ {
      if (want == 0) { pending = $0; pcells = cells($0); next }
      got = cells($0)
      if (got != want) { c = $0; sub(/^\| */, "", c); sub(/ *\|.*$/, "", c); printf "%d\t%d\t%d\t%s\n", NR, got, want, substr(c, 1, 30) }
      next
    }
    { want = 0; pending = "" }
  ' "$doc")"
  if [ -n "$report" ]; then
    echo "$report" | while IFS="$(printf '\t')" read -r line got want cell; do
      fail "$doc line $line" "row has $got cells, its table header has $want   (first cell:$cell)"
    done
    fail_count=$((fail_count + $(echo "$report" | wc -l | tr -d ' ')))
  else
    pass
    [ "$VERBOSE" = true ] && printf '  %sOK%s    %s\n' "$GRN" "$RST" "$doc"
  fi
done

# --- 2. one tag per bundle, agreeing with its index row ----------------------
# The row is authoritative; section 4c says a disagreement is a bug in whoever
# moved the bundle last. Both halves are checked because the four instances this
# exists for left the OLD tag in place beside the new one.
for dir in docs/*-findings/[0-9][0-9][0-9][0-9]-*/ docs/*-findings/*/[0-9][0-9][0-9][0-9]-*/; do
  [ -d "$dir" ] || continue
  num="$(basename "$dir" | cut -c1-4)"
  tags="$(ls "$dir" 2>/dev/null | grep '^STATUS-' || true)"
  count="$(printf '%s\n' "$tags" | grep -c '^STATUS-' || true)"
  if [ "${count:-0}" -ne 1 ]; then
    fail "$num  $(printf '%s' "$tags" | tr '\n' ' ')" "expected exactly one STATUS- tag, found ${count:-0}"
    continue
  fi
  tag="$(printf '%s' "$tags" | sed 's/^STATUS-//; s/-/ /g')"
  index="$(dirname "${dir%/}")"
  while [ ! -f "$index/INDEX.md" ] && [ "$index" != "." ] && [ "$index" != "/" ]; do
    index="$(dirname "$index")"
  done
  if [ ! -f "$index/INDEX.md" ]; then
    fail "$num  no INDEX.md above $dir" "a bundle must be indexed where a reader looks for it"
    continue
  fi
  # The Status cell may be a bare `status` or a link whose text is the status --
  # [`superseded`](0030-.../) is the form a supersede takes. Take the FIRST
  # backticked token; a greedy strip runs past the closing backtick and returns
  # the URL, or nothing at all on a plain cell.
  row="$(awk -F'|' -v n=" $num " '
    /^\| *#/ { for (i = 2; i < NF; i++) { c = $i; gsub(/^[ \t]+|[ \t]+$/, "", c); if (c == "Status") si = i } ; next }
    index($0, "|" n "|") == 1 && si {
      s = $si
      if (match(s, /`[^`]*`/)) s = substr(s, RSTART + 1, RLENGTH - 2)
      else gsub(/^[ \t]+|[ \t]+$/, "", s)
      print s; exit
    }
  ' "$index/INDEX.md")"
  if [ -z "$row" ]; then
    fail "$num  no row in $index/INDEX.md" "the tag says '$tag' and nothing indexes the bundle"
  elif [ "$row" != "$tag" ]; then
    fail "$num  $index/INDEX.md" "tag says '$tag', row says '$row'   (the row is authoritative)"
  else
    pass
    [ "$VERBOSE" = true ] && printf '  %sOK%s    %s  %s\n' "$GRN" "$RST" "$num" "$tag"
  fi
done

printf '\n%sFindings structure%s\n\n' "$BLD" "$RST"
printf "  %-14s %s\n" "OK:"   "$ok_count"
printf "  %-14s %s\n" "FAIL:" "$fail_count"
echo
if [ "$fail_count" -eq 0 ]; then
  printf '  %s%s✓ Every table is well formed and every tag agrees with its row.%s\n' "$GRN" "$BLD" "$RST"
  exit 0
fi
printf '  %s%s✗ %d structural defect(s).%s\n' "$RED" "$BLD" "$fail_count" "$RST"
printf '  %sA row with the wrong cell count renders as data; two tags is a bundle in two states.%s\n' "$YEL" "$RST"
exit 1
