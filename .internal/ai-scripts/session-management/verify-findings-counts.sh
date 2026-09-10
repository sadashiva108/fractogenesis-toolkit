#!/usr/bin/env bash
# =============================================================================
# verify-findings-counts.sh
#
# Verifies the counts displayed about findings bundles and sessions against the
# files that own them.
#
# Four numbers are shown in a second place for a reader's benefit, and each is
# a copy of something authoritative elsewhere:
#
#   a findings index row's `Findings`  <- the per-finding table in findings.md
#   a session row's `Bundles`          <- the rows in its findings-manifest.md
#   a session row's `Findings`         <- the sum of those bundles' counts
#   `N bundles · M findings` in prose  <- the table the sentence sits beneath
#
# The fourth was added at Revision 288, carrying out `0041` D6. It is the one a
# reader has always believed this check was making -- the conformant prompt says
# so in as many words -- and until then nothing read it. Section 4 has the
# argument.
#
# Revision 179 decided that a derived fact may be displayed where something
# catches it drifting. This is that something. The rule it enforces is in
# .github/copilot-instructions.md section 4b: a fact has one home, and a copy is
# permitted only where it is generated or where a check fails on drift.
#
# The defect it exists for is subtler than a wrong number. `docs/sessions/INDEX.md`
# carried a column headed `Findings` that held a count of BUNDLES -- an accurate
# count of the wrong thing, which no consistency check would have caught. So each
# figure here is compared against a named source rather than against itself.
#
# This file is intended for bin/. It is an aggregate validator: it records every
# finding and reports all results rather than aborting on the first miss, so it
# deliberately does NOT use `set -e`. It reads the repository only -- it creates
# nothing, and it does not load the shared reimage config, because it inspects
# repo-relative documents and must verify on a fresh checkout.
#
# --- BEGIN USAGE ---
# Usage:
#   ./bin/verify.sh findings-counts
#
#   Runs from any directory: it self-locates. `bin/verify.sh` is the callsite;
#   this script is its implementation and is not invoked directly.
#
# Exit codes:
#   0  every displayed count agrees with its source
#   1  at least one disagrees
#   2  the repository layout could not be read
# --- END USAGE ---
# =============================================================================

# THREE levels up: this sits in .internal/ai-scripts/session-management/, so
# the repo root is three parents away. It was in bin/ and climbed one. Moving a
# script between depths without changing this line is a failure this repository
# has already hit -- the same comment stands in bin/record-restore-prereqs.sh.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT" || exit 2

tmp_rows="${TMPDIR:-/tmp}/verify-findings-counts.$$"
tmp_totals="${TMPDIR:-/tmp}/verify-findings-counts-totals.$$"
trap 'rm -f "$tmp_rows" "$tmp_totals"' EXIT

ok_count=0
fail_count=0

pass() { ok_count=$((ok_count + 1)); }
fail() {
  fail_count=$((fail_count + 1))
  printf '  FAIL  %s\n' "$1"
  printf '        shown %s, source says %s\n' "$2" "$3"
}

# Findings held by one bundle: the rows of its finding table. Rows are numbered
# `F1`, `F2` since the header schema was adopted -- the letter makes a
# cross-reference from decisions.md unambiguous. `Q` for a commission's questions
# and `T` for a charter's or remedy's tasks: the prefix carries the genus, and
# matching only `F` counted a three-question commission as holding one finding.
# 0039 F31. The bare-digit form is still matched, because nothing forces a bundle
# onto the schema until it is next worked.
#
# The table is found by its SHAPE -- the first run of rows beginning `| <n> |`
# -- rather than by the heading above it, because bundles head it either
# `## Findings` or `## Finding status` and neither is settled. A bundle with no
# such table holds one finding.
findings_in_bundle() {
  awk '
    /^\|[ ]*[FQT]?[0-9]+[ ]*\|/ { if (!done) { n++; seen = 1 }; next }
    seen && !/^\|/         { done = 1 }
    END { print (n ? n : 1) }
  ' "$1/findings.md"
}

echo ""
echo "Findings counts"
echo ""

# --- 1. every findings index row against the bundle it names -----------------
#
# The Findings column sits at a different field number in each tree -- the
# runbook index carries an extra Runbook column -- so its position is read from
# the header rather than assumed. Assuming it is what produced the first draft
# of this check reporting the bundle number as the count.
column_of() {
  awk -F'|' -v want="$2" '
    /^\|[ ]*#[ ]*\|/ {
      for (i = 1; i <= NF; i++) { h = $i; gsub(/^[ ]+|[ ]+$/, "", h); if (h == want) { print i; exit } }
    }' "$1"
}

cell() { printf '%s' "$1" | awk -F'|' -v c="$2" '{ v = $c; gsub(/^[ ]+|[ ]+$/, "", v); print v }'; }

for index in docs/*-findings/INDEX.md; do
  [ -f "$index" ] || continue
  tree="$(dirname "$index")"
  col="$(column_of "$index" "Findings")"
  if [ -z "$col" ]; then
    fail "$index  no Findings column in the header" "—" "a Findings column"
    continue
  fi
  grep -E '^\|[ ]*[0-9]{4}[ ]*\|' "$index" > "$tmp_rows"
  while IFS= read -r row; do
    num="$(cell "$row" 2)"
    shown="$(cell "$row" "$col")"
    dir="$(find "$tree" -maxdepth 2 -type d -name "${num}-*" 2>/dev/null | head -1)"
    if [ -z "$dir" ] || [ ! -f "$dir/findings.md" ]; then
      fail "$num  no findings.md under $tree" "$shown" "no source"
      continue
    fi
    actual="$(findings_in_bundle "$dir")"
    if [ "$shown" = "$actual" ]; then pass
    else fail "$num  $index" "$shown" "$actual (findings.md)"; fi
  done < "$tmp_rows"
done

# --- 2 and 3. session rows against their manifests ---------------------------
sessions_index="docs/sessions/INDEX.md"
if [ -f "$sessions_index" ]; then
  bcol="$(awk -F'|' '/^\|[ ]*Bundle[ ]*\|/ { for (i=1;i<=NF;i++) { h=$i; gsub(/^[ ]+|[ ]+$/,"",h); if (h=="Bundles") { print i; exit } } }' "$sessions_index")"
  fcol="$(awk -F'|' '/^\|[ ]*Bundle[ ]*\|/ { for (i=1;i<=NF;i++) { h=$i; gsub(/^[ ]+|[ ]+$/,"",h); if (h=="Findings") { print i; exit } } }' "$sessions_index")"
  for manifest in docs/sessions/*/findings-manifest.md; do
    [ -f "$manifest" ] || continue
    session="$(basename "$(dirname "$manifest")")"
    src_bundles="$(grep -cE '^\|[ ]*[0-9]{4}[ ]*\|' "$manifest")"
    src_findings="$(awk -F'|' -v c="$(column_of "$manifest" "Findings")" '
      $2 ~ /^[ ]*[0-9]{4}[ ]*$/ { v = $c; gsub(/[^0-9]/, "", v); total += v }
      END { print total + 0 }' "$manifest")"
    row="$(grep -F "[\`$session\`]" "$sessions_index" | head -1)"
    if [ -z "$row" ]; then
      fail "$session  no row in $sessions_index" "absent" "$src_bundles bundles / $src_findings findings"
      continue
    fi
    # the Bundles cell is a link: [4](path/findings-manifest.md). Only the label counts.
    shown_bundles="$(cell "$row" "$bcol" | sed -e 's/^\[//' -e 's/\].*$//' | tr -cd '0-9')"
    shown_findings="$(cell "$row" "$fcol" | tr -cd '0-9')"
    if [ "$shown_bundles" = "$src_bundles" ]; then pass
    else fail "$session  Bundles column" "${shown_bundles:-—}" "$src_bundles (findings-manifest.md)"; fi
    if [ "$shown_findings" = "$src_findings" ]; then pass
    else fail "$session  Findings column" "${shown_findings:-—}" "$src_findings (sum of its bundles)"; fi
  done
fi

# --- 4. the prose total against the table it describes ------------------------
#
# `0041` D6. Every findings index and session manifest may close with a sentence
# of the form `N bundles · M findings`. It is prose, not a table cell, and until
# this section nothing read it -- which is what `0041` F6 records: two such
# totals were wrong for days across six instruments, one was corrected by a
# person recounting a column and the other by accident, during a transfer that
# rewrote the manifest for an unrelated reason.
#
# THE SUBJECT IS A DOCUMENT THAT HAS THE TABLE, not a document that has the
# sentence. A total-shaped run of words appears fourteen times in the tree and
# only five of them are a document's own total; the other nine are quotations of
# a wrong number, schema placeholders, and a ledger counting something else. So
# the qualifying condition is read off the TABLE -- a header carrying a
# `Findings` or `Members` column, over data rows numbered by bundle -- and a
# document without one is not making this claim and is not measured for it.
#
# Three exclusions, and each one is a real instance in this tree rather than a
# precaution:
#
#   a fenced block          -- an example is not a claim
#   an inline code span     -- `session-management-re-evaluation-.../
#                              findings-manifest.md` line 40 quotes its own
#                              former, wrong total inside backticks while
#                              recording that it was corrected. Reading it as a
#                              claim would fail the file for saying what it had
#                              once got wrong
#   a table row             -- `0041/findings.md` states both known instances as
#                              rows of the table that records them
#
# The code-context requirement is `0041` D1's third instance of `0015`: an
# extractor that cannot see code context raises on the documentation of the very
# defect it looks for.
#
# `Members` is matched beside `Findings`, and `members` beside `findings`,
# because Revision 271 renamed the array and two manifests have followed it. A
# check that knew only the older word would go quiet on the newer documents,
# which is the failure this whole section exists for.
#
# A document carrying `<!-- historical-record -->` is SKIPPED and counted.
# `0046`'s marker already means *this is a statement about a moment, do not
# repair it*, and a session's own total at the moment it stopped is exactly
# that. Reusing it was D6's instruction; inventing a second marker for one class
# of statement is the copy this repository keeps finding.

total_lines() {
  awk '
    /^[ \t]*```/ { fence = !fence; next }
    fence        { next }
    /^[ \t]*\|/  { next }
    {
      out = ""; n = split($0, seg, "`")
      for (i = 1; i <= n; i += 2) out = out seg[i]
      if (n % 2 == 0) out = out seg[n]
      if (match(out, /[0-9]+ bundles? · [0-9]+ (finding|member)s?/)) {
        printf "%d\t%s\n", NR, substr(out, RSTART, RLENGTH)
      }
    }
  ' "$1"
}

members_column_of() {
  awk -F'|' '
    /^\|/ {
      for (i = 1; i <= NF; i++) {
        h = $i; gsub(/^[ ]+|[ ]+$/, "", h)
        if (h == "Findings" || h == "Members") { print i; exit }
      }
    }' "$1"
}

# The filesystem, not `git ls-files`. A session bundle created in this revision
# is untracked until the owner commits, and the index is the one place its
# manifest is guaranteed absent -- so reading the index would make the check
# blind to precisely the document most likely to carry a fresh total.
find docs \( -name 'INDEX.md' -o -name 'findings-manifest.md' \) -print | sort | while IFS= read -r doc; do
  [ -f "$doc" ] || continue
  col="$(members_column_of "$doc")"
  [ -n "$col" ] || continue
  rows="$(grep -cE '^\|[ ]*[0-9]{4}[ ]*\|' "$doc")"
  [ "$rows" -gt 0 ] || continue

  totals="$(total_lines "$doc")"
  [ -n "$totals" ] || continue

  if grep -q 'historical-record' "$doc"; then
    printf '  SKIP  %s  declared a historical record\n' "$doc"
    continue
  fi

  sum="$(awk -F'|' -v c="$col" '
    $2 ~ /^[ ]*[0-9]{4}[ ]*$/ { v = $c; gsub(/[^0-9]/, "", v); t += v }
    END { print t + 0 }' "$doc")"

  printf '%s\n' "$totals" | while IFS="$(printf '\t')" read -r lineno claim; do
    said_b="$(printf '%s' "$claim" | awk '{print $1}')"
    said_m="$(printf '%s' "$claim" | awk '{print $4}')"
    if [ "$said_b" = "$rows" ] && [ "$said_m" = "$sum" ]; then
      printf 'PASS\n' >> "$tmp_totals"
    else
      printf 'FAIL\t%s:%s  the total beneath the table\t%s\t%s\n' \
        "$doc" "$lineno" "$said_b bundles / $said_m" "$rows rows / $sum summed" >> "$tmp_totals"
    fi
  done
done

# The loop above runs in a subshell, so its verdicts come back through a file
# rather than through the counters. Bash 3.2 has no lastpipe and this repository
# targets it.
if [ -f "$tmp_totals" ]; then
  while IFS="$(printf '\t')" read -r verdict what shown source; do
    if [ "$verdict" = "PASS" ]; then pass
    else fail "$what" "$shown" "$source"; fi
  done < "$tmp_totals"
fi

echo ""
printf "  %-14s %s\n" "OK:"   "$ok_count"
printf "  %-14s %s\n" "FAIL:" "$fail_count"
echo ""

if [ "$fail_count" -eq 0 ]; then
  echo "  Every displayed count agrees with the file that owns it."
  echo ""
  exit 0
fi

echo "  A count and its source disagree. The source is authoritative:"
echo "  findings.md for a bundle, findings-manifest.md for a session."
echo ""
exit 1
