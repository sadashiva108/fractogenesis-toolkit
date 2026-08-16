#!/usr/bin/env bash
# =============================================================================
# verify-doc-paths.sh
#
# Verifies that the repository paths named in the governance docs still exist.
# Those docs tell an AI session or a new contributor which files to read and
# which templates to fill; when a file moves, the reference is left pointing at
# nothing and the next session quietly authors against a missing template. This
# script is the check that catches that class before it misdirects anyone.
#
# This file is intended for bin/. It is an aggregate validator: it records every
# reference and reports all results rather than aborting on the first miss, so
# it deliberately does NOT use `set -e`. It reads the repository only — it
# creates nothing, and it does not load the shared reimage config, because the
# paths it checks are repo-relative and must verify on a fresh checkout with no
# reimage.env present.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/verify-doc-paths.sh
#
#   # Check the governance doc set
#   ./bin/verify-doc-paths.sh
#
#   # Check specific documents instead. Repeatable.
#   ./bin/verify-doc-paths.sh --doc README.md --doc reimaging-guide.md
#
#   # Show every reference, not just the problems
#   ./bin/verify-doc-paths.sh --verbose
#
# Options:
#   --doc PATH    Check PATH instead of the default doc set. Repeatable.
#   --verbose     List OK references too, not just MISSING and WARN.
#   -h, --help    Show this message and exit.
#
# What counts as a reference:
#   A directory-qualified path rooted at a known repository directory
#   (bin/, .internal/, .github/, .claude/, .share/, references/, templates/),
#   or a bare top-level filename such as reimaging-guide.md. Tokens holding a
#   placeholder (<phase>, $REIMAGE_ARTIFACT_ROOT, {{TITLE}}) are skipped, since
#   they are patterns rather than paths. A glob passes when it matches at least
#   one file.
#
# Result records:
#   OK       The referenced path exists, or the glob matched something.
#   MISSING  A directory-qualified path that does not exist. Fails the run.
#   WARN     A bare filename matching no file anywhere in the repo. Reported
#            but does not fail the run, because prose legitimately names a doc
#            that lives outside the repo or does not exist yet. A bare filename
#            that resolves to a file in any subdirectory counts as OK.
#   SKIP     A placeholder or pattern, not checkable.
#
# Exit status:
#   0  Every directory-qualified reference resolves.
#   1  One or more references are MISSING.
#   2  Usage error, or a document passed to --doc does not exist.
# --- END USAGE ---
# =============================================================================

# Aggregate validator: intentionally NOT `set -e`. Every reference must be
# recorded and reported in a single pass, so a miss cannot abort the run.
# `-u` and `pipefail` are still wanted.
set -uo pipefail

# ---------------------------------------------------------------------------
# Locate repository
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Colors ──────────────────────────────────────────────────────────────────
# Same palette and section helpers as the other bin/ entrypoints so severity
# colors mean the same thing across the workflow.
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

thin_hr()     { printf '%s\n' "  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"; }
log_section() { echo ""; echo -e "${BLD}${CYN}▸ $1${RST}"; thin_hr; }

# ---------------------------------------------------------------------------
# Defaults and command-line state
# ---------------------------------------------------------------------------
VERBOSE=false
DOCS=()

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

require_option_value() {
  local option="$1"
  local value="${2:-}"

  if [[ -z "$value" || "$value" == --* ]]; then
    echo "ERROR: $option requires a non-empty value." >&2
    usage >&2
    exit 2
  fi
}

# ---------------------------------------------------------------------------
# Parse command-line options
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --doc)
      require_option_value "$1" "${2:-}"
      DOCS+=("$2")
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Default document set — the docs that tell a session where to look.
#
# Templates under .github/ai-templates/ are deliberately excluded: they are
# mostly {{PLACEHOLDER}} and illustrative paths, so scanning them would produce
# noise rather than findings. Pass one with --doc to check it deliberately.
# ---------------------------------------------------------------------------
if (( ${#DOCS[@]} == 0 )); then
  while IFS= read -r found_doc; do
    [[ -n "$found_doc" ]] && DOCS+=("$found_doc")
  done < <(
    cd "$REPO_ROOT" || exit 0
    for candidate in \
      README.md \
      .claude/CLAUDE.md \
      .github/copilot-instructions.md \
      .github/ai-prompts/README.md
    do
      [[ -f "$candidate" ]] && printf '%s\n' "$candidate"
    done
    find .github/guides .github/ai-prompts -type f -name '*.md' 2>/dev/null | sort
  )
fi

# The explicit names above overlap the find, so collapse duplicates rather than
# reporting the same document twice.
DEDUPED_DOCS=()
while IFS= read -r unique_doc; do
  [[ -n "$unique_doc" ]] && DEDUPED_DOCS+=("$unique_doc")
done < <(printf '%s\n' "${DOCS[@]}" | awk '!seen[$0]++')
DOCS=( ${DEDUPED_DOCS[@]+"${DEDUPED_DOCS[@]}"} )

if (( ${#DOCS[@]} == 0 )); then
  echo "ERROR: no documents to check." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Reference extraction
#
# Two shapes are recognised. Directory-qualified paths are the ones that go
# stale when a file moves, so those are authoritative. Bare top-level filenames
# are reported as WARN only, because prose names documents freely.
# ---------------------------------------------------------------------------
REPO_DIRS='bin|\.internal|\.github|\.claude|\.share|references|templates'

# Index every filename in the repo once, so a bare token such as
# `bash-entrypoint.sh.tmpl` resolves to the copy under
# .github/ai-templates/script-templates/ instead of being reported as absent
# from the repo root. Without this the WARN tier is all noise.
REPO_FILE_INDEX="$(mktemp)"
cleanup_doc_path_index() { rm -f "$REPO_FILE_INDEX"; }
trap cleanup_doc_path_index EXIT

find "$REPO_ROOT" -name .git -prune -o -name __pycache__ -prune -o -type f -print 2>/dev/null \
  | sed 's|.*/||' \
  | sort -u > "$REPO_FILE_INDEX"

filename_exists_in_repo() {
  grep -qxF "$1" "$REPO_FILE_INDEX"
}

extract_references() {
  local doc="$1"

  {
    grep -oE "(^|[^A-Za-z0-9_./-])(${REPO_DIRS})/[A-Za-z0-9._*/{}<>\$-]+" "$doc" 2>/dev/null \
      | grep -oE "(${REPO_DIRS})/[A-Za-z0-9._*/{}<>\$-]+"
    grep -oE '(^|[^A-Za-z0-9_./-])[a-z][a-z0-9.-]*\.(md|sh|py|tmpl)([^A-Za-z0-9]|$)' "$doc" 2>/dev/null \
      | grep -oE '[a-z][a-z0-9.-]*\.(md|sh|py|tmpl)'
  } \
    | sed 's/[.,;:)]*$//' \
    | grep -v '^$' \
    | sort -u
}

# A token carrying a placeholder is a pattern, not a path.
is_placeholder() {
  case "$1" in
    *'<'*|*'>'*|*'$'*|*'{'*|*'}'*) return 0 ;;
    *) return 1 ;;
  esac
}

# Glob tokens pass when at least one file matches.
glob_matches() {
  local pattern="$1" match_count=0 candidate

  # shellcheck disable=SC2231
  for candidate in $pattern; do
    [[ -e "$candidate" ]] && match_count=$((match_count + 1))
  done

  (( match_count > 0 ))
}

# ---------------------------------------------------------------------------
# Check every reference in every document
# ---------------------------------------------------------------------------
log_section "Documented path check"
echo -e "  ${DIM}Repository: $REPO_ROOT${RST}"
echo -e "  ${DIM}Documents : ${#DOCS[@]}${RST}"

missing_count=0
warn_count=0
skip_count=0
ok_count=0

cd "$REPO_ROOT" || { echo "ERROR: cannot enter repository root: $REPO_ROOT" >&2; exit 2; }

for doc in "${DOCS[@]}"; do
  if [[ ! -f "$doc" ]]; then
    echo ""
    printf "  ${RED}%-7s${RST}  %s  ${DIM}(document not found)${RST}\n" "ERROR" "$doc"
    exit 2
  fi

  doc_findings=""

  while IFS= read -r reference; do
    [[ -n "$reference" ]] || continue

    if is_placeholder "$reference"; then
      skip_count=$((skip_count + 1))
      $VERBOSE && doc_findings="${doc_findings}$(printf "\n  ${DIM}SKIP     %s  (placeholder)${RST}" "$reference")"
      continue
    fi

    if [[ "$reference" == *"*"* ]]; then
      if glob_matches "$reference"; then
        ok_count=$((ok_count + 1))
        $VERBOSE && doc_findings="${doc_findings}$(printf "\n  ${GRN}OK       %s${RST}" "$reference")"
      else
        missing_count=$((missing_count + 1))
        doc_findings="${doc_findings}$(printf "\n  ${RED}MISSING  %s  (glob matches nothing)${RST}" "$reference")"
      fi
      continue
    fi

    if [[ -e "$reference" ]]; then
      ok_count=$((ok_count + 1))
      $VERBOSE && doc_findings="${doc_findings}$(printf "\n  ${GRN}OK       %s${RST}" "$reference")"
    elif [[ "$reference" == */* ]]; then
      missing_count=$((missing_count + 1))
      doc_findings="${doc_findings}$(printf "\n  ${RED}MISSING  %s${RST}" "$reference")"
    elif filename_exists_in_repo "$reference"; then
      # Prose naming a real file that lives in a subdirectory.
      ok_count=$((ok_count + 1))
      $VERBOSE && doc_findings="${doc_findings}$(printf "\n  ${GRN}OK       %s  (resolves elsewhere in the repo)${RST}" "$reference")"
    else
      warn_count=$((warn_count + 1))
      doc_findings="${doc_findings}$(printf "\n  ${YEL}WARN     %s  (no file by this name anywhere in the repo)${RST}" "$reference")"
    fi
  done < <(extract_references "$doc")

  if [[ -n "$doc_findings" ]]; then
    echo ""
    echo -e "  ${BLD}${doc}${RST}"
    printf '%b\n' "${doc_findings#?}"
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
printf "  %-9s %s\n" "OK:"      "$ok_count"
printf "  %-9s %s\n" "WARN:"    "$warn_count"
printf "  %-9s %s\n" "SKIP:"    "$skip_count"
printf "  %-9s %s\n" "MISSING:" "$missing_count"
echo ""

if (( missing_count == 0 )); then
  echo -e "  ${GRN}${BLD}✓ Every documented path resolves.${RST}"
  if (( warn_count > 0 )); then
    echo -e "  ${DIM}  Review the WARN entries — a bare filename may be prose, or may be a doc that moved.${RST}"
  fi
  echo ""
  exit 0
fi

echo -e "  ${RED}${BLD}✗ ${missing_count} documented path(s) do not exist.${RST}"
echo -e "  ${YEL}Update the reference, or restore the file, before the next session reads it.${RST}"
echo ""
exit 1
