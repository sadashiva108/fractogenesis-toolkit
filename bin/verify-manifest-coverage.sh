#!/usr/bin/env bash
# =============================================================================
# verify-manifest-coverage.sh
#
# Does the commit log agree with APPLY-MANIFEST.md about which revision is
# which?
#
# Every change takes a revision and every revision takes an entry, so a number
# claimed in a commit subject and a number written in the manifest should be the
# same number, written by the same commit. Three ways that can fail, and this
# checker reports each separately because they cost different things.
#
#   MISSING   a commit subject claims revision N and the manifest has no entry
#             for it. This is `0038` F7: a change committed with no manifest
#             entry. Revisions 241-246 are the recorded instance -- six numbers
#             taken in the log, none written, reconstructed at Revision 247.
#             FAILS the run. There are ZERO of these today, which is the whole
#             point of building it now: it guards a state the tree is not in.
#
#   ORPHANED  the entry for N exists, and was introduced by a commit OTHER than
#             the one claiming N. Commit 636eba0 is the instance: it claims
#             "Revision 271" and carries Revision 270's work, and the entry for
#             271 arrived two commits later. WARNS -- see the baseline below.
#
#   DUPLICATE two commits claim the same number. WARNS.
#
# WHY TWO OF THE THREE ONLY WARN, AND THIS IS NOT SOFTNESS. Neither is fixable.
# `APPLY-MANIFEST.md` entries are never retro-edited (section 7) and commits are
# never rewritten (section 0 step 7), so a historical ORPHANED or DUPLICATE row
# can never be cleared by anyone. A check whose number can only rise is not a
# signal -- that is `0047` F9, recorded against two `superseded` bundles whose
# rows nobody is permitted to clear. MISSING is the one a session can still
# avoid causing, so MISSING is the one that fails.
#
# STANDING BASELINE, measured 2026-09-10 against Revision 277 over 229 commits,
# 50 numbers claimed:
#
#   MISSING    0
#   ORPHANED   3   R241 and R246 -- the batch of six taken in the log and never
#                  written, reconstructed at Revision 247 -- and R271, which is
#                  636eba0 claiming 271 while carrying Revision 270's work.
#   DUPLICATE  1   R265, claimed by two commits with identical subjects.
#
# Every one is an incident the record already carries. That is the condition
# `0047` F6 asks for before an instrument is trusted: not zero rows, but zero
# rows that are the instrument's own fault.
#
# A MENTION IS NOT A CLAIM, which is why the subject pattern is anchored.
# "Rename the restart record, and undo Revision 156's over-reach" refers to a
# revision; it does not take one. Anchoring is the difference between 4 rows and
# 6, and the two it removes are both correct prose.
#
# Read a number against that baseline before reading it as a regression, the way
# `verify-session-findings.sh headers` is read against its 11.
#
# WHAT THIS DOES NOT CHECK, deliberately. That every commit names a revision:
# 178 of 229 do not, because the convention is recent, and a checker reporting
# 178 failures against a healthy tree is the sixth instrument in this repository
# to do that -- `0047` F6. And that every entry has a commit: 250 entries against
# 53 claimed numbers, for the same reason.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#
#   ./bin/verify-manifest-coverage.sh
#   ./bin/verify-manifest-coverage.sh --verbose     name every clean number too
#   ./bin/verify-manifest-coverage.sh --since <rev> only commits after <rev>
#
# Options:
#   --since REV   Only examine commits reachable from HEAD but not from REV.
#                 Use it to check one session's work rather than all history.
#   --verbose     List every claimed number, not only the problems.
#   -h, --help    Show this message and exit.
#
# Exit codes:
#   0  no MISSING rows
#   1  at least one MISSING row
#   2  not a git repository, or the manifest could not be read
# --- END USAGE ---
#
# RUN THIS IN A SCRATCH COPY, NOT THE OWNER'S CHECKOUT. It shells out to git,
# and on a mounted connected folder a lock cannot be cleaned up. Every git call
# here passes --no-optional-locks, which suppresses the index write -- but the
# rule stands: in the checkout, `ls` and `cat`.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# The manifest rolls over: when APPLY-MANIFEST.md grows past what a session
# can read, it is timestamped and a fresh one started -- Revision 310 did this
# at 1.25 MB and 468 entries. An entry never moves out of the SET, only out of
# the current file, so coverage reads the set. Reading only the current file
# reported 79 revisions as written nowhere the moment the rollover landed.
MANIFESTS=""
for _m in "$REPO_ROOT"/APPLY-MANIFEST*.md; do
  [ -f "$_m" ] && MANIFESTS="$MANIFESTS $_m"
done
MANIFEST="$REPO_ROOT/APPLY-MANIFEST.md"
SINCE=""
VERBOSE=false

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --since)   SINCE="${2:-}"; [ -n "$SINCE" ] || { echo "ERROR: --since needs a revision" >&2; exit 2; }; shift 2 ;;
    --verbose) VERBOSE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$MANIFESTS" ] || { echo "ERROR: no APPLY-MANIFEST*.md under $REPO_ROOT" >&2; exit 2; }
command -v git >/dev/null 2>&1 || { echo "ERROR: git is required" >&2; exit 2; }
git -C "$REPO_ROOT" --no-optional-locks rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "ERROR: not a git repository: $REPO_ROOT" >&2; exit 2; }

g() { git -C "$REPO_ROOT" --no-optional-locks "$@" 2>/dev/null; }

RANGE="HEAD"
[ -n "$SINCE" ] && RANGE="$SINCE..HEAD"

work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

# One line per (number, commit) a subject claims.
#
# ANCHORED AT THE START OF THE SUBJECT, and that is not tidiness. An unanchored
# pattern read "Revision 256: 0037 reaches answered" as the range 256 to 0037 and
# reported a bundle number as a missing revision. Two of these appeared on this
# checker's own first run, which is `0047` F6 arriving in the instrument written
# to answer `0047` F12 -- caught before it shipped rather than after.
#
# A range is "Revisions N-M" with a hyphen or en dash and nothing else between,
# so both numbers are claimed by that one commit. Anything after the colon is
# prose and is not a claim.
g log --format='%h%x09%s' "$RANGE" | while IFS="$(printf '\t')" read -r sha subj; do
  printf '%s\n' "$subj" \
    | sed -n -e 's/^[Rr]evisions[[:space:]]\{1,\}\([0-9][0-9]*\)[[:space:]]*[-–][[:space:]]*\([0-9][0-9]*\).*/\1\
\2/p' \
           -e 's/^[Rr]evisions\{0,1\}[[:space:]]\{1,\}\([0-9][0-9]*\)\([^0-9-].*\)\{0,1\}$/\1/p' \
    | sed '/^$/d' | sort -u \
    | while read -r n; do printf '%s\t%s\n' "$n" "$sha"; done
done | sort -u > "$work/claimed"

miss=0; orph=0; dup=0; clean=0
: > "$work/report"

# Unique numbers, in order.
cut -f1 "$work/claimed" | sort -n -u | while read -r n; do
  shas="$(awk -v k="$n" -F'\t' '$1==k {print $2}' "$work/claimed" | tr '\n' ' ')"
  shas="${shas% }"
  count="$(printf '%s\n' "$shas" | wc -w | tr -d ' ')"

  if ! grep -q "^\*\*Revision $n\*\*" $MANIFESTS \
     && ! grep -q "^## Revisions\{0,1\} $n\([^0-9]\|$\)" $MANIFESTS; then
    printf 'MISSING\t%s\t%s\t-\n' "$n" "$shas" >> "$work/report"
    continue
  fi

  intro="$(g log --format=%h -S "**Revision $n**" -- "APPLY-MANIFEST*.md" | tail -1)"
  if [ -n "$intro" ] && ! printf ' %s ' "$shas" | grep -q " $intro "; then
    printf 'ORPHANED\t%s\t%s\t%s\n' "$n" "$shas" "$intro" >> "$work/report"
  elif [ "$count" -gt 1 ]; then
    printf 'DUPLICATE\t%s\t%s\t-\n' "$n" "$shas" >> "$work/report"
  else
    printf 'CLEAN\t%s\t%s\t-\n' "$n" "$shas" >> "$work/report"
  fi
done

miss="$(grep -c '^MISSING' "$work/report" 2>/dev/null || true)";     miss="${miss:-0}"
orph="$(grep -c '^ORPHANED' "$work/report" 2>/dev/null || true)";    orph="${orph:-0}"
dup="$(grep -c '^DUPLICATE' "$work/report" 2>/dev/null || true)";    dup="${dup:-0}"
clean="$(grep -c '^CLEAN' "$work/report" 2>/dev/null || true)";      clean="${clean:-0}"
total=$((miss + orph + dup + clean))

printf '\n  Manifest coverage — the commit log against APPLY-MANIFEST*.md\n'
printf '  %s\n' "----------------------------------------------------------"
printf '  Repository: %s\n' "$REPO_ROOT"
printf '  Commits   : %s over %s\n' "$(g rev-list --count "$RANGE")" "$RANGE"
printf '  Numbers claimed in a commit subject: %s\n\n' "$total"

while IFS="$(printf '\t')" read -r code n shas intro; do
  case "$code" in
    MISSING)   printf '  MISSING    Revision %-4s claimed by %s — no entry in the manifest\n' "$n" "$shas" ;;
    ORPHANED)  printf '  ORPHANED   Revision %-4s claimed by %s — entry introduced by %s\n' "$n" "$shas" "$intro" ;;
    DUPLICATE) printf '  DUPLICATE  Revision %-4s claimed by %s\n' "$n" "$shas" ;;
    CLEAN)     [ "$VERBOSE" = true ] && printf '  ok         Revision %-4s %s\n' "$n" "$shas" ;;
  esac
done < "$work/report"

printf '\n  MISSING:   %s\n  ORPHANED:  %s\n  DUPLICATE: %s\n' "$miss" "$orph" "$dup"
printf '\n  Baseline at Revision 277: MISSING 0, ORPHANED 3, DUPLICATE 1.\n'
printf '  ORPHANED and DUPLICATE cannot be cleared — entries are never\n'
printf '  retro-edited and commits are never rewritten — so they warn.\n'

if [ "$miss" -gt 0 ]; then
  printf '\n  %s revision number(s) taken in the log and written nowhere.\n' "$miss"
  printf '  That is 0038 F7. Write the entry; do not renumber the commit.\n\n'
  exit 1
fi
printf '\n  No revision number is taken in the log and missing from the manifest.\n\n'
exit 0
