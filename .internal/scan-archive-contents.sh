#!/usr/bin/env bash
#
# scan-archive-contents.sh
#
# Report compressed archives whose *members* look like credentials.
#
# The Phase 3B sweep matches filenames on disk, so a secret sealed inside a
# .zip or .tar.gz passes it silently: the archive's own name says nothing about
# what it holds. This lists archive members without extracting anything and
# matches them against the same SECRET_SHAPES the sweep uses, so a decision can
# be made per archive -- keep it, add it to ARCHIVE_SKIP, or move it into the
# secrets DMG.
#
# Nothing is extracted, moved, or deleted. Read-only by construction.
#
# --- BEGIN USAGE ---
# Usage:
#   .internal/scan-archive-contents.sh [--root PATH]... [--report FILE] [--all]
#
# Options:
#   --root PATH     Directory to scan. Repeatable. Defaults to
#                   REIMAGE_ARTIFACT_ROOT from shared config.
#   --report FILE   Also write a Markdown report to FILE.
#   --all           List every archive scanned, not only the ones with hits.
#   -h, --help      Show this message and exit.
#
# Exit codes:
#   0  scan completed, no archive held a credential-shaped member
#   1  at least one archive held a credential-shaped member (review them)
#   2  usage or configuration error
# --- END USAGE ---

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "${BASH_SOURCE[0]}" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

ROOTS=(); REPORT=""; SHOW_ALL=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)    [[ -n "${2:-}" ]] || { echo "ERROR: --root requires a value" >&2; exit 2; }
               ROOTS+=( "$2" ); shift 2 ;;
    --report)  [[ -n "${2:-}" ]] || { echo "ERROR: --report requires a value" >&2; exit 2; }
               REPORT="$2"; shift 2 ;;
    --all)     SHOW_ALL=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)         echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -f "$REPO_ROOT/.internal/load-reimage-config.sh" ]]; then
  # shellcheck disable=SC1091
  source "$REPO_ROOT/.internal/load-reimage-config.sh" || exit 2
fi

if (( ${#ROOTS[@]} == 0 )); then
  if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    ROOTS=( "$REIMAGE_ARTIFACT_ROOT" )
  else
    echo "ERROR: no --root given and REIMAGE_ARTIFACT_ROOT is not set." >&2; exit 2
  fi
fi

if (( ${#SECRET_SHAPES[@]} == 0 )); then
  echo "ERROR: SECRET_SHAPES is empty; shared config did not load." >&2; exit 2
fi

RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'
[[ -t 1 ]] || { RED=''; YEL=''; GRN=''; CYN=''; BLD=''; DIM=''; RST=''; }

# Glob shapes -> one lowercase ERE, anchored to the member's basename. Matching
# happens in awk rather than a shell `case` per member: an archive can hold
# thousands of entries and a fork-per-entry loop reads as a hang.
PAT=""
for shape in "${SECRET_SHAPES[@]}"; do
  [[ -n "$shape" ]] || continue
  r="$(printf '%s' "$shape" \
       | tr '[:upper:]' '[:lower:]' \
       | sed -e 's/[.[\$()+^{}]/\\&/g' -e 's/\*/.*/g' -e 's/?/./g')"
  if [[ -z "$PAT" ]]; then PAT="^${r}$"; else PAT="${PAT}|^${r}$"; fi
done

list_members() {
  local f="$1"
  case "$f" in
    *.zip|*.ZIP|*.jar|*.war)
      command -v unzip >/dev/null 2>&1 || return 3
      unzip -Z1 -- "$f" 2>/dev/null ;;
    *.tar)          tar -tf  "$f" 2>/dev/null ;;
    *.tar.gz|*.tgz) tar -tzf "$f" 2>/dev/null ;;
    *.tar.bz2)      tar -tjf "$f" 2>/dev/null ;;
    *.tar.xz)       tar -tJf "$f" 2>/dev/null ;;
    *.7z)
      command -v 7z >/dev/null 2>&1 || return 3
      7z l -ba -slt -- "$f" 2>/dev/null | sed -n 's/^Path = //p' ;;
    *) return 3 ;;
  esac
}

human() { awk -v b="${1:-0}" 'BEGIN{
  if(b>=1073741824) printf "%.1fG",b/1073741824;
  else if(b>=1048576) printf "%.1fM",b/1048576;
  else if(b>=1024) printf "%.0fK",b/1024; else printf "%dB",b }'; }

FOUND="$(mktemp)"; SCANNED=0; HITS=0; UNREADABLE=0

scan_archive() {
  local f="$1" members hit_lines n
  members="$(list_members "$f")" || { UNREADABLE=$((UNREADABLE+1))
    printf "  ${DIM}?  no reader for %s${RST}\n" "${f##*/}"; return; }
  SCANNED=$((SCANNED+1))
  hit_lines="$(printf '%s\n' "$members" | awk -v pat="$PAT" '
      { n=$0; sub(/.*\//,"",n); if (n=="") next
        if (tolower(n) ~ pat) print $0 }')"
  if [[ -z "$hit_lines" ]]; then
    $SHOW_ALL && printf "  ${GRN}OK${RST}  ${DIM}%s${RST}\n" "$f"
    return
  fi
  HITS=$((HITS+1))
  n="$(printf '%s\n' "$hit_lines" | grep -c .)"
  printf "  ${RED}!!${RST}  ${BLD}%s${RST}  ${DIM}(%s, %s credential-shaped member(s))${RST}\n" \
    "$f" "$(human "$(wc -c < "$f" | tr -d ' ')")" "$n"
  printf '%s\n' "$hit_lines" | head -12 | sed 's/^/       /'
  (( n > 12 )) && printf "       ${DIM}... and %d more${RST}\n" "$(( n - 12 ))"
  {
    printf '\n### `%s`\n\n' "$f"
    printf '%d credential-shaped member(s):\n\n```text\n' "$n"
    printf '%s\n' "$hit_lines"
    printf '```\n'
  } >> "$FOUND"
}

echo ""
printf "${BLD}${CYN}> Archive content scan${RST}\n"
printf "  ${DIM}%d shape(s) from the shared SECRET_SHAPES definition${RST}\n" "${#SECRET_SHAPES[@]}"
printf '%s\n' "  ------------------------------------------------"

LIST="$(mktemp)"
for root in "${ROOTS[@]}"; do
  if [[ ! -d "$root" ]]; then
    printf "  ${YEL}!  not a directory, skipping: %s${RST}\n" "$root"; continue
  fi
  find -L "$root" -type f \
    \( -iname '*.zip' -o -iname '*.jar' -o -iname '*.war' -o -iname '*.7z' \
       -o -iname '*.tar' -o -iname '*.tgz' -o -iname '*.tar.gz' \
       -o -iname '*.tar.bz2' -o -iname '*.tar.xz' \) -print 2>/dev/null
done | sort -u > "$LIST"

while IFS= read -r a; do
  [[ -n "$a" ]] || continue
  scan_archive "$a"
done < "$LIST"

echo ""
if (( HITS > 0 )); then
  printf "  ${RED}%d of %d archive(s) hold credential-shaped members.${RST}\n" "$HITS" "$SCANNED"
  printf "  ${DIM}A shape match is a candidate, not proof. Decide per archive: keep it,${RST}\n"
  printf "  ${DIM}add it to ARCHIVE_SKIP in archive-policy.conf.sh, or move it under${RST}\n"
  printf "  ${DIM}secrets-encrypted/ so the DMG covers it.${RST}\n"
else
  printf "  ${GRN}No archive held a credential-shaped member (%d scanned).${RST}\n" "$SCANNED"
fi
(( UNREADABLE > 0 )) && printf "  ${YEL}%d archive(s) had no reader available and were not scanned.${RST}\n" "$UNREADABLE"

if [[ -n "$REPORT" ]]; then
  {
    echo "# Archive Content Scan"
    echo ""
    echo "Roots: ${ROOTS[*]}"
    echo ""
    echo "Archive members matched against the shared SECRET_SHAPES definition."
    echo "A match is a candidate to inspect, not proof of a secret."
    echo ""
    echo "- archives scanned: $SCANNED"
    echo "- archives with credential-shaped members: $HITS"
    echo "- archives with no reader available: $UNREADABLE"
    [[ -s "$FOUND" ]] && cat "$FOUND"
  } > "$REPORT"
  printf "  ${DIM}Report: %s${RST}\n" "$REPORT"
fi

rm -f "$FOUND" "$LIST"
(( HITS > 0 )) && exit 1
exit 0
