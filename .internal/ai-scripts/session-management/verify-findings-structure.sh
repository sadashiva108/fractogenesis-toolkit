#!/usr/bin/env bash
# =============================================================================
# verify-findings-structure.sh
#
# Verifies three structural invariants that sections 4c and 4d state and nothing
# else tests:
#
#   1. every data row in a findings/sessions table has its own table's column
#      count -- a row with the wrong number of cells renders shifted and reads
#      as data;
#   2. every findings bundle's DERIVED standing agrees with the bundle's own
#      findings INDEX.md row;
#   3. every OTHER table that displays a derived value agrees with it too -- a
#      session manifest's `Standing` cells, and docs/sessions/INDEX.md's `State`
#      cells. `0041` D7.
#
# The derivation itself is NOT implemented here. It is imported once from
# plan_findings_work, which owns it. The block above section 2 records what this
# file did instead until Revision 308, and what that was measured to cost.
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
#   ./bin/verify.sh findings-structure
#   ./bin/verify.sh findings-structure --verbose   # also list every table found
#
#   Runs from any directory: it self-locates. `bin/verify.sh` is the callsite;
#   this script is its implementation and is not invoked directly.
#
# Exit codes:
#   0  every table is well formed and every displayed derived value agrees
#   1  at least one does not
#   2  the repository layout could not be read, or the derivation would not run
# --- END USAGE ---
# =============================================================================

# THREE levels up: this sits in .internal/ai-scripts/session-management/, so
# the repo root is three parents away. It was in bin/ and had no self-location
# at all -- it tested `-d docs` against whatever the current directory happened
# to be, so running it from anywhere but the root reported "run from the
# repository root", which reads as operator error rather than as the script
# being unable to find itself. Moving a script between depths without changing
# this line is a failure this repository has already hit; the same comment
# stands in bin/record-restore-prereqs.sh.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT" || exit 2

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
  echo "ERROR: $REPO_ROOT does not look like the repository root." >&2
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

# --- the derivations, computed once, by the one thing that owns them ---------
#
# `0041` D7. Until this revision this file carried its OWN copy of the standing
# derivation: fifteen lines of python in a heredoc, reimplementing
# `plan_findings_work.bundle_standing`. It was the fourth such copy. Revision 299
# deleted the third and recorded what it took to find it -- not a run, but a
# deletion.
#
# It was also WRONG, and the size of the wrongness is measurable rather than
# arguable. `bundle_standing` tests lineage before ownership, for the reason its
# own docstring gives: a superseded reading is no longer authoritative whatever
# it concluded. The copy tested ownership first. Enumerated over every
# ownership x lineage x presence-combination of the six finding statuses -- 384
# cases -- the two disagree on 128, and every one of them is a bundle that is
# both released and superseded. Such a bundle carries `superseded` in
# metadata.json, where `stamp` wrote it; the copy would have derived `unclaimed`
# and FAILED THE ROW FOR BEING RIGHT.
#
# No bundle in this tree is currently both. That is the entire reason four
# revisions of clean runs said nothing about it, and it is `0050`'s subject
# turning up inside this file: an instrument that is incorrect, and whose
# incorrectness is invisible because the case has not arisen. Recorded as `0050`
# F11. It was found by building D7 -- by needing the derivation a second time in
# one file and looking at what was already there.
#
# So the derivation is not reimplemented here. It is imported from the module
# that owns it, once, and the answers are read out of a table. What stays in
# shell is the markdown parsing. What leaves is every rule about what a standing
# or a state IS.
#
# A failure to run is fatal rather than skipped. Three sections below compare
# against this table, and a comparison whose right-hand side is missing is not a
# weaker check -- it is silence that reads like assent, which is what `0050` is
# about.

tmp_derived="$(mktemp "${TMPDIR:-/tmp}/fg-derived.XXXXXX")" || exit 2
tmp_proj="$(mktemp "${TMPDIR:-/tmp}/fg-proj.XXXXXX")"       || exit 2
trap 'rm -f "$tmp_derived" "$tmp_proj"' EXIT INT TERM

if ! python3 - "$SCRIPT_DIR" > "$tmp_derived" <<'PYDERIVE'
import os, sys
sys.path.insert(0, sys.argv[1])
import plan_findings_work as P
g = P.Graph(P.root())
for n in sorted(g.bundles):
    print("B\t%s\t%s" % (n, P.bundle_standing(g.bundles[n])))
for name in sorted(g.sessions):
    print("S\t%s\t%s" % (name, P.session_state(g, g.sessions[name])))
PYDERIVE
then
  echo "ERROR: the derivation would not run. Every comparison below depends on" >&2
  echo "       it, and a missing right-hand side is silence, not a pass." >&2
  exit 2
fi

# derived B|S <key> -- the derived value, or nothing and a non-zero status.
derived() {
  awk -F'\t' -v k="$1" -v n="$2" \
    '$1 == k && $2 == n { print $3; hit = 1; exit } END { exit !hit }' "$tmp_derived"
}

# --- 2. the DERIVED status agrees with its index row -------------------------
# Until Revision 222 this compared a `STATUS-` FILENAME against the row. The tag
# files are gone: a status is derived from the findings in metadata.json, and a
# derivation cannot drift from itself. What remains checkable -- and what this
# now checks -- is that the DISPLAY agrees with the source.
#
# The row is still authoritative for a reader; the derivation is authoritative
# for the truth. A disagreement now means the index was not regenerated, not
# that somebody moved a bundle and forgot half of it.
#
# 0043 F7: `analyzing` is the else branch and asserts nothing, so a derivation
# bug always lands there looking plausible. That is why derive_status below
# states a positive condition for every row it can, and why the derivation table is
# spelled out here rather than defaulted.
for dir in docs/*-findings/[0-9][0-9][0-9][0-9]-*/ docs/*-findings/*/[0-9][0-9][0-9][0-9]-*/; do
  [ -d "$dir" ] || continue
  num="$(basename "$dir" | cut -c1-4)"
  if [ ! -f "$dir/metadata.json" ]; then
    fail "$num  no metadata.json" "a bundle's status is derived from its data; there is none"
    continue
  fi
  if [ -e "$dir/STATUS-analyzing" ] || ls "$dir"STATUS-* >/dev/null 2>&1; then
    fail "$num  a STATUS- tag survives" "status moved into metadata.json at Revision 222; a tag is now a second copy"
    continue
  fi
  if ! tag="$(derived B "$num")"; then
    fail "$num  not in the derivation" "the bundle directory exists and the derivation does not name it"
    continue
  fi
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
    /^\| *#/ { for (i = 2; i < NF; i++) { c = $i; gsub(/^[ \t]+|[ \t]+$/, "", c); if (c == "Standing") si = i } ; next }
    index($0, "|" n "|") == 1 && si {
      s = $si
      if (match(s, /`[^`]*`/)) s = substr(s, RSTART + 1, RLENGTH - 2)
      else gsub(/^[ \t]+|[ \t]+$/, "", s)
      print s; exit
    }
  ' "$index/INDEX.md")"
  if [ -z "$row" ]; then
    fail "$num  no row in $index/INDEX.md" "the derived status is '$tag' and nothing indexes the bundle"
  elif [ "$row" != "$tag" ]; then
    fail "$num  $index/INDEX.md" "tag says '$tag', row says '$row'   (the row is authoritative)"
  else
    pass
    [ "$VERBOSE" = true ] && printf '  %sOK%s    %s  %s\n' "$GRN" "$RST" "$num" "$tag"
  fi
done

# --- 3. a derived value displayed in a table it does not live in -------------
#
# `0041` D7 -- the report-only checker `0043` D3 ordered built AFTER the fixture
# set, which landed at Revision 306 as an enumeration over all 63
# presence-combinations rather than over chosen bundles.
#
# Section 2 checks one projection of a derived value: a bundle's standing onto
# its own findings index row. `docs/architecture/state-as-data.md` 6.1 declares
# eleven such classes, and Revision 304 measured the surface -- 5 disagreements
# in 612 rows, all five inside the three classes nothing compares, against 0 in
# the 329 rows something checks. D7 takes the two cheapest of the unchecked:
#
#   a. every `docs/sessions/<session>/findings-manifest.md` row's `Standing`,
#      against the derived standing of the bundle it names;
#   b. every `docs/sessions/INDEX.md` row's `State`, against the derived state of
#      the session it names.
#
# THE FIRST RUN REPORTS NOTHING, AND THAT IS NOT EVIDENCE THAT IT WORKS. Both
# classes measure clean today -- 37 manifest rows and 12 index rows, 49
# comparisons, 0 disagreements -- because Revision 307 cleared the last one by
# hand four revisions ago. The reason to build it anyway is that every instance
# found so far was found by a person who happened to look: `0050` F5's display
# stood wrong from Revision 255 to Revision 304, and the run-index row cleared at
# 307 had stood wrong since the session that owned it stopped. Direction B is
# satisfied on constructed input rather than on this tree; the construction and
# its three verdicts are in the revision's review.
#
# THE QUALIFYING CONDITION IS READ OFF THE TABLE HEADER, never off the filename.
# That is D6's rule and this file needs it for the same reason D6 did.
# `docs/sessions/INDEX.md` holds three tables, and one of the other two is a
# STATE KEY whose five rows are `available`, `active`, `closed`, `handoff` and
# `dissolved` -- five vocabulary entries that a file-keyed check reads as five
# sessions that do not exist. A header index taken against the wrong header is a
# mistake this session has already made and shipped. So a session row requires
# BOTH a `Bundle` and a `State` column, and a manifest row BOTH a `#` and a
# `Standing` column. `typed-bundles-architecture-20260908-204724` is the case
# that proves the rule rather than a precaution for one: it carries three tables,
# two of them handoff tables keyed by `Bundle`, and only the one with `#` and
# `Standing` qualifies -- with zero rows, because that session handed everything
# off.
#
# The cell may be a bare value or a value with prose after it: `superseded` by
# `0040` is what a supersede looks like in a manifest. The FIRST backticked
# token is the value, which is already section 2's rule.
#
# NO `historical-record` EXEMPTION, deliberately. A closed session's manifest
# looks like frozen history and is not one: all three closed sessions here carry
# rows that MOVED after they stopped -- `restore-apps-outstanding-20260903-000000`
# shows `0027`, `0028` and `0029` standing `superseded`, which happened on and
# after the day it closed. No manifest in this tree carries the marker. Declaring
# an exemption for a class with no instance is the copy this repository keeps
# finding, and `0046`'s marker is there if one ever appears.
#
# A row naming a bundle or a session that does not exist is reported as itself.
# It is not a disagreement -- there is nothing to disagree with -- and calling it
# one would put a second meaning on a verdict, which is `0047` F9's shape.

# rows_of <file> <key-header> <value-header>
# Emits `lineno<TAB>key<TAB>displayed-value` for each data row of each table
# carrying BOTH headers. Indices are per table and cleared at every blank line.
rows_of() {
  awk -F'|' -v kh="$2" -v vh="$3" '
    function tokval(s) {
      if (match(s, /`[^`]*`/)) return substr(s, RSTART + 1, RLENGTH - 2)
      gsub(/^[ \t]+|[ \t]+$/, "", s); return s
    }
    /^[ \t]*```/ { fence = !fence; next }
    fence        { next }
    /^\|[- :|]+\|[ \t]*$/ { next }
    /^\|/ {
      k = v = 0
      for (i = 2; i < NF; i++) {
        c = $i; gsub(/^[ \t]+|[ \t]+$/, "", c)
        if (c == kh) k = i
        if (c == vh) v = i
      }
      if (k && v) { ki = k; vi = v; next }          # this row is the header
      if (!ki || NF <= ki || NF <= vi) next
      key = tokval($ki)
      if (key == "") next
      printf "%d\t%s\t%s\n", NR, key, tokval($vi)
      next
    }
    { ki = 0; vi = 0 }
  ' "$1"
}

# a. the manifest row against the bundle it names
for man in docs/sessions/*/findings-manifest.md; do
  [ -f "$man" ] || continue
  rows_of "$man" '#' 'Standing' | while IFS="$(printf '\t')" read -r lineno num shown; do
    case "$num" in
      [0-9][0-9][0-9][0-9]) ;;
      *) continue ;;
    esac
    if ! want="$(derived B "$num")"; then
      printf 'FAIL\t%s:%s  names bundle %s\tno bundle by that number exists; the row points at nothing\n' \
        "$man" "$lineno" "$num" >> "$tmp_proj"
    elif [ "$shown" = "$want" ]; then
      printf 'PASS\n' >> "$tmp_proj"
    else
      printf 'FAIL\t%s:%s  bundle %s\tthe row shows `%s`, the record derives `%s`   (the derivation is authoritative)\n' \
        "$man" "$lineno" "$num" "$shown" "$want" >> "$tmp_proj"
    fi
  done
done

# b. the sessions index row against the session it names
if [ -f docs/sessions/INDEX.md ]; then
  rows_of docs/sessions/INDEX.md 'Bundle' 'State' | while IFS="$(printf '\t')" read -r lineno name shown; do
    if ! want="$(derived S "$name")"; then
      printf 'FAIL\tdocs/sessions/INDEX.md:%s  names session %s\tno session bundle by that name exists; the row points at nothing\n' \
        "$lineno" "$name" >> "$tmp_proj"
    elif [ "$shown" = "$want" ]; then
      printf 'PASS\n' >> "$tmp_proj"
    else
      printf 'FAIL\tdocs/sessions/INDEX.md:%s  session %s\tthe row shows `%s`, the record derives `%s`   (the derivation is authoritative)\n' \
        "$lineno" "$name" "$shown" "$want" >> "$tmp_proj"
    fi
  done
fi

# Both loops run in subshells, so their verdicts come back through a file rather
# than through the counters. Bash 3.2 has no lastpipe and this repository targets
# it -- the same reason section 4 of verify-findings-counts.sh does this.
if [ -f "$tmp_proj" ]; then
  while IFS="$(printf '\t')" read -r verdict what detail; do
    if [ "$verdict" = "PASS" ]; then pass; else fail "$what" "$detail"; fi
  done < "$tmp_proj"
fi

printf '\n%sFindings structure%s\n\n' "$BLD" "$RST"
printf "  %-14s %s\n" "OK:"   "$ok_count"
printf "  %-14s %s\n" "FAIL:" "$fail_count"
echo
if [ "$fail_count" -eq 0 ]; then
  printf '  %s%s✓ Every table is well formed and every displayed derived value agrees.%s\n' "$GRN" "$BLD" "$RST"
  exit 0
fi
printf '  %s%s✗ %d structural defect(s).%s\n' "$RED" "$BLD" "$fail_count" "$RST"
printf '  %sA row with the wrong cell count renders as data; a stale display is a%s\n' "$YEL" "$RST"
printf '  %sbundle in two states, and the derivation is the one that is true.%s\n' "$YEL" "$RST"
exit 1
