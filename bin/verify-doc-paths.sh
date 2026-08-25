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
#   --all         Check every Markdown document in the repository: the runbooks
#                 and references as well as the governance set. This is where
#                 the wikilink anchors live, so it is the mode that exercises
#                 the anchor check. Not yet the default -- see below.
#   --verbose     List OK references too, not just MISSING and WARN.
#   -h, --help    Show this message and exit.
#
# Wikilink anchors:
#   A [[doc#Heading|label]] or [[#Heading|label]] link is checked as well: the
#   target document must exist and must carry a heading whose text matches the
#   anchor exactly. Obsidian matches heading text, so a retitled heading breaks
#   every link into it silently — the links still render, they just land at the
#   top of the document. Anchor results are recorded as ANCHOR-OK or
#   ANCHOR-MISSING and share the MISSING exit status.
#
#   Escaped pipes are handled: inside a table an anchor is written
#   [[#Heading\|label]], and the trailing backslash is not part of the heading.
#
# What counts as a reference:
#   A wikilink target written without its extension --
#   [[references/toolkit-environment-reference|...]] -- resolves against
#   <token>.md, which is what Obsidian does. Only extensionless tokens get that
#   treatment, so a genuinely absent bin/foo.sh is still MISSING.
#
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
#   SKIP     A placeholder or pattern, not checkable. Also an anchor whose
#            target is itself a placeholder (`[[doc#anchor]]`, `[[#Heading]]`)
#            as written in the prompt templates, which document the syntax
#            rather than link with it.
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
ALL_DOCS=false
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
    --all)
      ALL_DOCS=true
      shift
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
if $ALL_DOCS && (( ${#DOCS[@]} == 0 )); then
  while IFS= read -r found_doc; do
    [[ -n "$found_doc" ]] && DOCS+=("$found_doc")
  done < <(
    cd "$REPO_ROOT" || exit 0
    # APPLY-MANIFEST.md is excluded: it is a change log that quotes paths and
    # links as they were at the time of a revision, so a reference that no
    # longer resolves is the record working correctly.
    find . -name .git -prune -o -name __pycache__ -prune \
         -o -path './.github/ai-templates/*' -prune \
         -o -type f -name '*.md' -print 2>/dev/null \
      | sed 's|^\./||' \
      | grep -v '^APPLY-MANIFEST\.md$' \
      | sort
  )
fi

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
# Wikilink anchor extraction
#
# Emits one TAB-separated row per anchored wikilink: target<TAB>anchor. An empty
# target means the link is to a heading in the same document.
#
# The anchor ends at the first unescaped `|` or at `]]`. `\|` is Obsidian's
# escaped pipe, used when a link sits inside a table cell; the backslash belongs
# to the table syntax, not to the heading, so it is stripped.
# ---------------------------------------------------------------------------
extract_anchors() {
  # One awk pass, not grep piped to sed: BSD sed has no \? and does not expand
  # \t in a replacement, and line context is needed to skip fenced blocks.
  #
  # A wikilink inside a fence is a worked example of runbook prose, not a link
  # into this document -- the runbook prompt shows authors what a cross-
  # reference looks like. Fences opened inside a blockquote count.
  awk '
    /^[ \t>]*```/ { fence = !fence; next }
    fence         { next }
    {
      line = $0
      # A code span that IS a wikilink documents the syntax rather than
      # linking: runbook-prompt.md writes `[[#Table of Contents|...]]` in
      # backticks to show authors the form. Only spans that OPEN with `[[`
      # qualify -- headings here routinely contain inline code of their own
      # (`ssh -T` fails after the keys are restored), and blanking every span
      # mangles the anchor instead of the example.
      gsub(/`\[\[[^`]*`/, " ", line)
      while (match(line, /\[\[[^]|#]*#[^]|]+(\\?\|[^]]*)?\]\]/)) {
        s    = substr(line, RSTART + 2, RLENGTH - 4)
        line = substr(line, RSTART + RLENGTH)
        gsub(/\\\|/, "|", s)
        i = index(s, "|"); if (i > 0) s = substr(s, 1, i - 1)
        j = index(s, "#"); if (j == 0) continue
        target = substr(s, 1, j - 1)
        anchor = substr(s, j + 1)
        sub(/[ \t]+$/, "", anchor)
        sub(/^[ \t]+/, "", anchor)
        if (anchor == "") continue
        printf "%s\t%s\n", target, anchor
      }
    }
  ' "$1" 2>/dev/null | sort -u
}

# Heading text of a document, one per line, with the leading #s and any
# trailing whitespace removed.
doc_headings() {
  sed -n 's/^#\{1,6\}[[:space:]]\{1,\}\(.*[^[:space:]]\)[[:space:]]*$/\1/p' "$1" 2>/dev/null
}

# A target that is itself a placeholder is documentation of the syntax, not a
# link: the prompt templates say [[#Heading]] and [[other-runbook#Heading]] to
# show authors the shape.
# `Table of Contents` is deliberately NOT in this list. It is a real heading in
# 40 documents and the target of the single most common link in the repository,
# so listing it here skipped ~39 back-links -- a check that could not fail. The
# runbook-prompt syntax examples that motivated it are inside fences, which
# extract_anchors already skips.
ANCHOR_PLACEHOLDERS='^(Heading|Section|Next Section|Routing Heading|anchor)$'

resolve_anchor_target() {
  # $1 = link target ("" means this document), $2 = the document being scanned
  if [[ -z "$1" ]]; then printf '%s\n' "$2"; return 0; fi
  local candidate="$1"
  [[ "$candidate" == *.md ]] || candidate="${candidate}.md"
  if [[ -f "$candidate" ]]; then printf '%s\n' "$candidate"; return 0; fi
  local found
  found="$(find . -name .git -prune -o -type f -name "$(basename "$candidate")" -print 2>/dev/null | head -1)"
  [[ -n "$found" ]] && { printf '%s\n' "$found"; return 0; }
  return 1
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
anchor_ok_count=0
anchor_missing_count=0

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
    elif [[ "$reference" != *.* && -f "${reference}.md" ]]; then
      # A wikilink names its target without the extension --
      # [[references/toolkit-environment-reference|...]] -- which is correct
      # Obsidian syntax, not a missing file. Only extensionless tokens qualify,
      # so a genuinely absent bin/foo.sh is still MISSING.
      ok_count=$((ok_count + 1))
      $VERBOSE && doc_findings="${doc_findings}$(printf "\n  ${GRN}OK       %s  (wikilink target, resolves as %s.md)${RST}" "$reference" "$reference")"
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

  # Split on the first tab by hand. `IFS=$'\t' read -r a b` cannot be used here:
  # a tab is IFS whitespace, so a leading one is stripped and a same-document
  # link ("<tab>Heading") lands its anchor in the target variable with the
  # anchor empty — which silently skipped every [[#Heading]] in the repository.
  while IFS= read -r anchor_row; do
    [[ -n "$anchor_row" ]] || continue
    link_target="${anchor_row%%$'\t'*}"
    link_anchor="${anchor_row#*$'\t'}"
    [[ -n "$link_anchor" ]] || continue

    if printf '%s' "$link_anchor" | grep -qE "$ANCHOR_PLACEHOLDERS"; then
      skip_count=$((skip_count + 1))
      $VERBOSE && doc_findings="${doc_findings}$(printf "\n  ${DIM}SKIP     [[%s#%s]]  (syntax example)${RST}" "$link_target" "$link_anchor")"
      continue
    fi

    anchor_file="$(resolve_anchor_target "$link_target" "$doc")" || {
      anchor_missing_count=$((anchor_missing_count + 1))
      doc_findings="${doc_findings}$(printf "\n  ${RED}ANCHOR   [[%s#%s]]  (no such document)${RST}" "$link_target" "$link_anchor")"
      continue
    }

    if doc_headings "$anchor_file" | grep -qxF "$link_anchor"; then
      anchor_ok_count=$((anchor_ok_count + 1))
      $VERBOSE && doc_findings="${doc_findings}$(printf "\n  ${GRN}ANCHOR   [[%s#%s]]${RST}" "$link_target" "$link_anchor")"
    else
      anchor_missing_count=$((anchor_missing_count + 1))
      doc_findings="${doc_findings}$(printf "\n  ${RED}ANCHOR   [[%s#%s]]  (no such heading in %s)${RST}" "$link_target" "$link_anchor" "$anchor_file")"
    fi
  done < <(extract_anchors "$doc")

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
printf "  %-14s %s\n" "OK:"             "$ok_count"
printf "  %-14s %s\n" "WARN:"           "$warn_count"
printf "  %-14s %s\n" "SKIP:"           "$skip_count"
printf "  %-14s %s\n" "MISSING:"        "$missing_count"
printf "  %-14s %s\n" "ANCHOR OK:"      "$anchor_ok_count"
printf "  %-14s %s\n" "ANCHOR BROKEN:"  "$anchor_missing_count"
echo ""

missing_count=$((missing_count + anchor_missing_count))

if (( missing_count == 0 )); then
  echo -e "  ${GRN}${BLD}✓ Every documented path and wikilink anchor resolves.${RST}"
  if (( warn_count > 0 )); then
    echo -e "  ${DIM}  Review the WARN entries — a bare filename may be prose, or may be a doc that moved.${RST}"
  fi
  echo ""
  exit 0
fi

echo -e "  ${RED}${BLD}✗ ${missing_count} documented reference(s) do not resolve.${RST}"
echo -e "  ${YEL}Update the reference, or restore the file, before the next session reads it.${RST}"
if (( anchor_missing_count > 0 )); then
  echo -e "  ${YEL}A broken ANCHOR still renders as a link — it just lands at the top of the${RST}"
  echo -e "  ${YEL}document. Retitling a heading is the usual cause.${RST}"
fi
echo ""
exit 1
