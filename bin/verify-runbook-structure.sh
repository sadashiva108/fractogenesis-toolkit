#!/usr/bin/env bash
# =============================================================================
# verify-runbook-structure.sh
#
# Verifies that the runbooks still follow the structural house rules the
# authoring prompt defines. Those rules exist because a reader arrives in the
# middle of a runbook routinely -- from a troubleshooting Continue link, a path
# index, or a cross-runbook link -- and every one of them is about that reader
# knowing where they are and how to get back.
#
# They drift silently. A runbook written before a rule existed keeps passing
# every other check in the repo: its paths resolve, its anchors resolve, its
# scripts are portable. Nothing notices that its steps were never enumerated
# until someone reads it beside a conforming one. This is that check.
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
#   chmod +x bin/verify-runbook-structure.sh
#
#   # Check every runbook
#   ./bin/verify-runbook-structure.sh
#
#   # Check specific documents instead. Repeatable.
#   ./bin/verify-runbook-structure.sh --doc restore-access.md
#
#   # List conforming rules too, not just the problems
#   ./bin/verify-runbook-structure.sh --verbose
#
# Options:
#   --doc PATH    Check PATH instead of every runbook. Repeatable.
#   --verbose     Report PASS rules as well as FAIL and WARN.
#   -h, --help    Show this message and exit.
#
# What is a runbook:
#   A top-level .md carrying a `## Sequential Steps` section. The guides
#   (reimaging-guide.md, reimaging-scripts-guide.md) have none and are skipped,
#   as are README.md and APPLY-MANIFEST.md. A document that should be a runbook
#   and has no Sequential Steps section at all is therefore invisible here --
#   that is a judgment call this script does not make.
#
# Rules checked:
#   SEQ-H2     `Sequential Steps` is an H2. An H3 makes the steps H4s in the
#              document outline, and Obsidian's outline pane is how a reader
#              navigates a thousand-line runbook.
#   STEP-NUM   Every `### ` under Sequential Steps is `### Step N — Title`,
#              numbered consecutively from 1 with an em dash. Unnumbered steps
#              cannot be referred to across runbooks, and a reader cannot tell
#              how far through they are.
#   STEP-BACK  Every step ends with a back-link and a `---`. A step is a
#              section; a reader who finishes one is far from the Table of
#              Contents.
#   TOC-STEP   Every numbered step has a Table of Contents entry.
#   NO-NOTE    No `> [!note]` anywhere. A clarification belongs in the
#              paragraph that needed it -- boxing an explanation makes it
#              easier to skip and spends the attention a real Pitfall needs.
#   PITFALL    At most one `> [!warning]` per step, and a total under the
#              file budget. Reported as WARN, not FAIL: the budget is a
#              sweep trigger, not a hard limit.
#   LEGEND     The callout legend is present under the Table of Contents.
#   FENCE      Code fences balance, and no fence line has prose welded onto it.
#              A bulk edit that eats a newline welds "```" to the sentence after
#              it; the count goes odd and the rest of the document renders as
#              code. Paths and anchors still resolve, so nothing else notices.
#   ORPHAN     No `> ` continuation line whose block never opened with `[!`.
#              This is what folding a multi-paragraph callout into prose leaves
#              behind when only its opening paragraph is replaced, and it can
#              strand a fenced code block inside a quote that no longer exists.
#
# Exit status:
#   0  Every rule passes, or only WARN-level findings.
#   1  One or more FAIL-level findings.
#   2  Usage error, or a document passed to --doc does not exist.
# --- END USAGE ---
# =============================================================================

# Aggregate validator: intentionally NOT `set -e`. Every finding must be
# recorded and reported in a single pass, so a miss cannot abort the run.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

thin_hr()     { printf '%s\n' "  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"; }
log_section() { echo ""; echo -e "${BLD}${CYN}▸ $1${RST}"; thin_hr; }

# Callout budget. Pitfalls only -- `[!bug]` Troubleshooting pointers are
# navigation and `[!info]` is the legend, so neither competes for the reader's
# attention the way a Pitfall does and neither is counted here.
PITFALL_BUDGET=8

VERBOSE=false
DOCS=""

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --doc)
      if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "ERROR: --doc needs a path" >&2; exit 2
      fi
      DOCS="$DOCS$2
"
      shift 2 ;;
    --verbose) VERBOSE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

cd "$REPO_ROOT" || exit 2

if [[ -z "$DOCS" ]]; then
  for f in *.md; do
    [[ -f "$f" ]] || continue
    case "$f" in README.md|APPLY-MANIFEST.md) continue ;; esac
    grep -q '^## Sequential Steps' "$f" 2>/dev/null || continue
    DOCS="$DOCS$f
"
  done
fi

log_section "Runbook structure check"
echo -e "  ${DIM}Repository: $REPO_ROOT${RST}"
echo -e "  ${DIM}Rules     : SEQ-H2 STEP-NUM STEP-BACK TOC-STEP NO-NOTE PITFALL LEGEND ORPHAN${RST}"

fail_count=0
warn_count=0
pass_count=0
doc_count=0

record() {
  # <severity> <rule> <message>
  local sev="$1" rule="$2" msg="$3"
  case "$sev" in
    FAIL) fail_count=$((fail_count + 1))
          FINDINGS="$FINDINGS  $(printf "${RED}%-10s${RST} %s" "$rule" "$msg")
" ;;
    WARN) warn_count=$((warn_count + 1))
          FINDINGS="$FINDINGS  $(printf "${YEL}%-10s${RST} %s" "$rule" "$msg")
" ;;
    PASS) pass_count=$((pass_count + 1))
          $VERBOSE && FINDINGS="$FINDINGS  $(printf "${DIM}%-10s %s${RST}" "$rule" "$msg")
" ;;
  esac
}

while IFS= read -r doc; do
  [[ -n "$doc" ]] || continue
  if [[ ! -f "$doc" ]]; then
    echo -e "  ${RED}ERROR${RST}      no such document: $doc" >&2
    exit 2
  fi
  doc_count=$((doc_count + 1))
  FINDINGS=""

  # --- SEQ-H2 -------------------------------------------------------------
  if grep -q '^## Sequential Steps' "$doc"; then
    record PASS SEQ-H2 "Sequential Steps is an H2"
  elif grep -q '^### Sequential Steps' "$doc"; then
    record FAIL SEQ-H2 "Sequential Steps is an H3; it must be an H2"
  else
    record FAIL SEQ-H2 "no Sequential Steps section"
  fi

  # --- a fence-stripped copy, which every check below reads -------------
  #
  # Fenced blocks are blanked rather than removed, so line numbers still line
  # up with the file. Without this, a runbook that shows a Markdown template in
  # a ```text block -- backup-apps.md quotes one containing `## Restore plan` --
  # ends the Sequential Steps extraction early, and its later steps become
  # invisible to every rule here. The check reported a real-looking failure
  # against a conforming file, which is worse than not checking at all.
  body_tmp="$(mktemp)"
  awk '
    /^```/ { fence = !fence; print ""; next }
    fence  { print ""; next }
    { print }
  ' "$doc" > "$body_tmp"

  # --- the step block: H3s between Sequential Steps and the next H2 -------
  steps_tmp="$(mktemp)"
  awk '
    /^#{2,3} Sequential Steps[[:space:]]*$/ { inseq = 1; next }
    inseq && /^## / { inseq = 0 }
    inseq { print }
  ' "$body_tmp" > "$steps_tmp"

  n_h3="$(grep -c '^### ' "$steps_tmp")"
  n_num="$(grep -c '^### Step [0-9]' "$steps_tmp")"

  # --- STEP-NUM -----------------------------------------------------------
  if [[ "$n_h3" -eq 0 ]]; then
    record FAIL STEP-NUM "Sequential Steps contains no ### step headings"
  elif [[ "$n_num" -ne "$n_h3" ]]; then
    record FAIL STEP-NUM "$((n_h3 - n_num)) of $n_h3 step heading(s) are not 'Step N — Title'"
  else
    # consecutive from 1, and an em dash rather than a hyphen
    # A runbook may open at Step 0 -- the ones that record a prerequisite and
    # before-state boundary do -- so the first number sets the start and the
    # rest must follow it consecutively.
    bad_seq="$(grep '^### Step ' "$steps_tmp" \
      | awk 'NR == 1 { want = $3 + 0
                       if (want != 0 && want != 1) { print "0 or 1"; exit } }
             { n = $3 + 0; if (n != want) { print want; exit } want++ }')"
    bad_dash="$(grep -c '^### Step [0-9][0-9]* -' "$steps_tmp")"
    if [[ -n "$bad_seq" ]]; then
      record FAIL STEP-NUM "step numbering is not consecutive; expected Step $bad_seq"
    elif [[ "$bad_dash" -gt 0 ]]; then
      record FAIL STEP-NUM "$bad_dash step heading(s) use a hyphen where an em dash is required"
    else
      record PASS STEP-NUM "$n_num step(s), numbered consecutively"
    fi
  fi

  # --- STEP-BACK ----------------------------------------------------------
  missing_back="$(awk '
    /^### / { if (name != "" && !(back && rule)) print name; name = $0; back = 0; rule = 0; next }
    /Back to Table of Contents/ { back = 1 }
    /^---[[:space:]]*$/ { if (back) rule = 1 }
    END { if (name != "" && !(back && rule)) print name }
  ' "$steps_tmp" | sed 's/^### //')"
  if [[ -n "$missing_back" ]]; then
    n_mb="$(printf '%s\n' "$missing_back" | grep -c .)"
    record FAIL STEP-BACK "$n_mb step(s) do not end with a back-link and divider"
    if $VERBOSE; then
      printf '%s\n' "$missing_back" | while IFS= read -r m; do
        [[ -n "$m" ]] && echo "                  · $m"
      done
    fi
  elif [[ "$n_h3" -gt 0 ]]; then
    record PASS STEP-BACK "every step ends with a back-link and divider"
  fi

  # --- TOC-STEP -----------------------------------------------------------
  toc_tmp="$(mktemp)"
  awk '/^## Table of Contents/ { intoc = 1; next } intoc && /^## / { intoc = 0 } intoc { print }' \
    "$body_tmp" > "$toc_tmp"
  missing_toc=0
  grep '^### Step ' "$steps_tmp" | sed 's/^### //' | while IFS= read -r title; do
    grep -Fq "$title" "$toc_tmp" || echo x
  done > "${toc_tmp}.miss"
  missing_toc="$(grep -c . "${toc_tmp}.miss")"
  if [[ "$missing_toc" -gt 0 ]]; then
    record FAIL TOC-STEP "$missing_toc step(s) have no Table of Contents entry"
  elif [[ "$n_num" -gt 0 ]]; then
    record PASS TOC-STEP "every step is in the Table of Contents"
  fi
  rm -f "$toc_tmp" "${toc_tmp}.miss"

  # --- NO-NOTE ------------------------------------------------------------
  n_note="$(grep -c '^> \[!note\]' "$body_tmp")"
  if [[ "$n_note" -gt 0 ]]; then
    record FAIL NO-NOTE "$n_note [!note] callout(s); a clarification belongs in prose"
  else
    record PASS NO-NOTE "no [!note] callouts"
  fi

  # --- PITFALL ------------------------------------------------------------
  n_pit="$(grep -c '^> \[!warning\]' "$body_tmp")"
  worst="$(awk '
    /^### / { s = $0; c = 0; next }
    /^> \[!warning\]/ { if (++c > m) { m = c; w = s } }
    END { if (m > 1) printf "%d\t%s", m, w }
  ' "$steps_tmp")"
  if [[ -n "$worst" ]]; then
    record WARN PITFALL "$(printf '%s' "$worst" | cut -f1) Pitfalls in one step: $(printf '%s' "$worst" | cut -f2 | sed 's/^### //')"
  fi
  if [[ "$n_pit" -gt "$PITFALL_BUDGET" ]]; then
    record WARN PITFALL "$n_pit Pitfalls in the file, over the budget of $PITFALL_BUDGET"
  elif [[ -z "$worst" ]]; then
    record PASS PITFALL "$n_pit Pitfall(s), within budget"
  fi

  # --- LEGEND -------------------------------------------------------------
  if grep -q '^> \[!info\] Callout legend' "$body_tmp"; then
    record PASS LEGEND "callout legend present"
  else
    record FAIL LEGEND "no '[!info] Callout legend' under the Table of Contents"
  fi

  # --- FENCE --------------------------------------------------------------
  # An odd number of ``` fences, or a fence line with prose welded to it.
  #
  # This is the damage a careless bulk edit does: a substitution that eats a
  # newline turns "```" and the sentence after it into one line, the count goes
  # odd, and from there to the end of the document Obsidian renders prose as
  # code. Nothing else in the repo notices -- paths still resolve, anchors still
  # resolve, the file still opens -- which is exactly how one sat committed
  # through several revisions. It also silently defeats every fence-aware check
  # in this script, so it is worth reporting on its own rather than as the
  # confusing downstream failures it causes.
  n_fence="$(grep -c '^```' "$doc")"
  n_glued="$(grep -c '^```..*[A-Za-z*].*[^`]$' "$doc")"
  n_short="$(grep -c '^``[^`]' "$doc")"
  fence_bad=0
  if [[ $((n_fence % 2)) -ne 0 ]]; then
    record FAIL FENCE "$n_fence code fences: an odd count, so the document renders as code from the unclosed one onward"
    fence_bad=1
  fi
  if [[ "$n_short" -gt 0 ]]; then
    record FAIL FENCE "$n_short line(s) open with two backticks where a fence needs three"
    fence_bad=1
  fi
  if [[ "$fence_bad" -eq 0 ]]; then
    record PASS FENCE "$n_fence code fences, balanced"
  fi

  # --- ORPHAN -------------------------------------------------------------
  # A quote block whose FIRST line is an empty `>`.
  #
  # That is the exact signature of folding a multi-paragraph callout into prose
  # by replacing only its opening paragraph: the paragraphs inside a callout are
  # separated by bare `>` lines, so what survives begins with one. A blockquote
  # a human wrote never opens on an empty line, which is what makes this
  # precise -- checking merely for "a quote block with no `[!` opener" flags the
  # legitimate standalone blockquotes several runbooks carry under their title.
  n_orphan="$(awk '
    /^>[[:space:]]*$/ { if (!inq) print NR; inq = 1; next }
    /^>/              { inq = 1; next }
    { inq = 0 }
  ' "$body_tmp" | grep -c .)"
  if [[ "$n_orphan" -gt 0 ]]; then
    record FAIL ORPHAN "$n_orphan orphaned '>' line(s): a callout was folded into prose without converting the whole block"
  else
    record PASS ORPHAN "no orphaned quote lines"
  fi

  rm -f "$steps_tmp" "$body_tmp"

  if [[ -n "$FINDINGS" ]]; then
    echo ""
    echo -e "  ${BLD}${doc}${RST}"
    printf '%b' "$FINDINGS"
  fi
done <<EOF
$DOCS
EOF

echo ""
printf "  %-14s %s\n" "DOCUMENTS:" "$doc_count"
printf "  %-14s %s\n" "PASS:"      "$pass_count"
printf "  %-14s %s\n" "WARN:"      "$warn_count"
printf "  %-14s %s\n" "FAIL:"      "$fail_count"
echo ""

if (( fail_count == 0 )); then
  echo -e "  ${GRN}${BLD}✓ Every runbook follows the structural house rules.${RST}"
  if (( warn_count > 0 )); then
    echo -e "  ${DIM}  Review the WARN entries — the callout budget is a sweep trigger, not a limit.${RST}"
  fi
  echo ""
  exit 0
fi

echo -e "  ${RED}${BLD}✗ ${fail_count} structural rule(s) do not hold.${RST}"
echo -e "  ${YEL}The rules are documented in .github/ai-prompts/runbook-prompts/runbook-prompt.md.${RST}"
echo ""
exit 1
