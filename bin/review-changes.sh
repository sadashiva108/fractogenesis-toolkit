#!/usr/bin/env bash
# What this session changed, as a review rather than a diff.
#
# A raw diff of a session's work runs to thousands of lines and reading it is
# not the owner's job. This groups the change set by area, counts it, flags what
# carries risk, and names the patch for anything the owner wants to open.
#
#   ./bin/review-changes.sh                 grouped summary
#   ./bin/review-changes.sh --files         one line per file
#   ./bin/review-changes.sh --patch PATH    also name the patch in the report
#
# Run it in the SESSION COPY, never the owner's checkout.
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
cd "$repo_root"

show_files=false
patch_path=""
while [ $# -gt 0 ]; do
  case "$1" in
    --files) show_files=true ;;
    --patch) shift; patch_path="${1:-}" ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
  esac
  shift || true
done

git rev-parse --git-dir >/dev/null 2>&1 || { printf 'review-changes: not a git tree\n' >&2; exit 2; }
git add -N . >/dev/null 2>&1 || true

tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
git diff --numstat > "$tmp" || true

if [ ! -s "$tmp" ]; then printf 'No changes in this copy.\n'; exit 0; fi

printf 'REVIEW  %s\n' "$(git rev-parse --short HEAD) + this session's work"
printf '        %s files, +%s / -%s lines\n\n' \
  "$(wc -l < "$tmp" | tr -d ' ')" \
  "$(awk '{a+=$1} END{print a+0}' "$tmp")" \
  "$(awk '{d+=$2} END{print d+0}' "$tmp")"

area() {
  case "$1" in
    .github/session-management-instructions.md|docs/legend.md) echo "RULES        the rules a session follows" ;;
    .github/copilot-instructions.md|.github/toolkit-instructions.md) echo "RULES        the project's conventions" ;;
    .claude/*|.github/ai-prompts/*) echo "AGENT        prompts, hooks and settings" ;;
    docs/architecture/*) echo "ARCHITECTURE design that outlives a session" ;;
    docs/ledgers/*) echo "LEDGER       re-derived statements" ;;
    docs/ideas/*) echo "IDEA         things that do not exist yet" ;;
    docs/*-findings/*) echo "FINDINGS     readings, decisions, resolutions" ;;
    docs/sessions/*) echo "SESSIONS     session records" ;;
    APPLY-MANIFEST.md) echo "MANIFEST     the revision entry" ;;
    bin/*|.internal/*|.share/*) echo "CODE         scripts and helpers" ;;
    *) echo "OTHER        uncategorised" ;;
  esac
}

# group
awk '{print $3"\t"$1"\t"$2}' "$tmp" | while IFS=$(printf '\t') read -r f add del; do
  printf '%s\t%s\t%s\t%s\n' "$(area "$f")" "$f" "$add" "$del"
done | sort > "$tmp.g"

last=""
while IFS=$(printf '\t') read -r a f add del; do
  if [ "$a" != "$last" ]; then printf '  %s\n' "$a"; last="$a"; fi
  if [ "$show_files" = true ]; then printf '      %-64s +%-5s -%s\n' "$f" "$add" "$del"; fi
done < "$tmp.g"

if [ "$show_files" = false ]; then
  printf '\n'
  awk -F'\t' '{c[$1]++; a[$1]+=$3; d[$1]+=$4} END{for(k in c) printf "      %-46s %2d files  +%-6d -%d\n", k, c[k], a[k], d[k]}' "$tmp.g" | sort
fi

printf '\n  FLAGGED FOR CLOSE READING\n'
flagged=false
while IFS=$(printf '\t') read -r a f add del; do
  case "$a" in
    RULES*) printf '      %s  -- a rule changed. Gated on a decided finding or an owner override.\n' "$f"; flagged=true ;;
    AGENT*) printf '      %s  -- changes what a session may do.\n' "$f"; flagged=true ;;
  esac
  if [ "$del" != "-" ] && [ "$del" -gt 0 ] 2>/dev/null && [ "$add" -eq 0 ] 2>/dev/null; then
    printf '      %s  -- deletions only.\n' "$f"; flagged=true
  fi
done < "$tmp.g"
[ "$flagged" = true ] || printf '      Nothing. No rule, hook or prompt changed.\n'

printf '\n  Open one file:   git diff -- <path>\n'
[ -n "$patch_path" ] && printf '  Full patch:      %s\n' "$patch_path"
printf '  Apply on your word: the session applies, then you git add / commit / push.\n'
