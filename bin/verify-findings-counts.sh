#!/usr/bin/env bash
# =============================================================================
# verify-findings-counts.sh
#
# Verifies the counts displayed about findings bundles and sessions against the
# files that own them.
#
# Three numbers are shown in a second place for a reader's benefit, and each is
# a copy of something authoritative elsewhere:
#
#   a findings index row's `Findings`  <- the per-finding table in findings.md
#   a session row's `Bundles`          <- the rows in its findings-manifest.md
#   a session row's `Findings`         <- the sum of those bundles' counts
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
#   cd <repo-root>
#   ./bin/verify-findings-counts.sh
#
# Exit codes:
#   0  every displayed count agrees with its source
#   1  at least one disagrees
#   2  the repository layout could not be read
# --- END USAGE ---
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT" || exit 2

tmp_rows="${TMPDIR:-/tmp}/verify-findings-counts.$$"
trap 'rm -f "$tmp_rows"' EXIT

ok_count=0
fail_count=0

pass() { ok_count=$((ok_count + 1)); }
fail() {
  fail_count=$((fail_count + 1))
  printf '  FAIL  %s\n' "$1"
  printf '        shown %s, source says %s\n' "$2" "$3"
}

# Findings held by one bundle: the rows of its finding table.
#
# The table is found by its SHAPE -- the first run of rows beginning `| <n> |`
# -- rather than by the heading above it, because bundles head it either
# `## Findings` or `## Finding status` and neither is settled. A bundle with no
# such table holds one finding.
findings_in_bundle() {
  awk '
    /^\|[ ]*[0-9]+[ ]*\|/ { if (!done) { n++; seen = 1 }; next }
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
