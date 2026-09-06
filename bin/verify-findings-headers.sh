#!/usr/bin/env bash
# =============================================================================
# verify-findings-headers.sh
#
# Verifies the header schema of every findings.md, and the two header fields the
# other bundle documents carry.
#
# It exists because the schema was arrived at by counting what was already
# there: seventeen distinct field names across forty-one readings, several of
# them the same capture under a different word, and two that actively mislead --
# an `Owner:` whose values were "unassigned" and a file path rather than a
# session, and a `Status:` that sometimes meant a lifecycle status and sometimes
# meant "closed by revision N". A schema nothing checks becomes seventeen names
# again, which is how it got there the first time.
#
# The rules, from .github/session-management-instructions.md section 11:
#
#   findings.md      required: Recorded, Session, Severity
#                    optional: Felt at, Scope, Read, Relates to (repeatable, last)
#                    order: Recorded, Session, Severity, Felt at, Scope, Read,
#                    Relates to
#                    Session is never packed into another field's value, and
#                    holds `--` where none was ever recorded.
#                    NO other field in the header block. That is the rule that
#                    matters: the schema fixes the vocabulary, not the content.
#                    Requiring Scope would mean inventing it for the 26 readings
#                    that never had one, which is not a checker's business.
#   decisions.md     required: Bundle, Session; nothing named `Findings bundle`
#   resolutions.md   required: Bundle, Session
#   no Status field   in decisions.md or resolutions.md -- a third copy of the
#                    bundle status after the tag and the index row, and 17 of
#                    them had gone stale by Revision 202
#   finding table    `| # | Finding | Status |` -- required, no `Decided`
#                    column; that became a status of its own
#   rendering        each field on ONE line, and every line but the last in the
#                    block ends with two spaces. Markdown joins consecutive
#                    lines into one paragraph, so a header without the hard
#                    breaks renders as a single run-on sentence -- which is what
#                    it did until someone read the rendered page.
#   cross-reference  every F-number cited by decisions.md or resolutions.md
#                    exists in findings.md, and every D-number cited by
#                    resolutions.md exists in decisions.md
#   code blocks      fenced with ``` and tagged `text`, never `markdown` -- some
#                    renderers read that tag as "render this as markdown" and
#                    interpret the example instead of showing it. Never indented
#                    four spaces either. Renderers
#                    disagree about the indented form: one rendered section 11's
#                    own schema example as live markdown, processed the backticks
#                    inside it, and swallowed `<where the fix lands>` as an HTML
#                    tag. A spec that renders as the thing it specifies is not a
#                    spec. APPLY-MANIFEST.md is exempt -- its entries are never
#                    retro-edited.
#
# This file is intended for bin/. It is an aggregate validator: it records every
# finding and reports all results rather than aborting on the first miss, so it
# deliberately does NOT use `set -e`. It reads the repository only.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   ./bin/verify-findings-headers.sh            # every bundle
#   ./bin/verify-findings-headers.sh --verbose  # list conforming files too
#
# Exit codes:
#   0  every header conforms
#   1  at least one does not
#   2  the repository layout could not be read
# --- END USAGE ---
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT" || exit 2

VERBOSE=false
case "${1:-}" in
  --verbose) VERBOSE=true ;;
  -h|--help) sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" | sed '1d;$d;s/^# //;s/^#$//'; exit 0 ;;
  '') : ;;
  *) echo "ERROR: unknown option: $1" >&2; exit 2 ;;
esac

ok=0
fail=0

pass() { ok=$((ok + 1)); [ "$VERBOSE" = true ] && printf '  OK    %s\n' "$1"; return 0; }
bad()  { fail=$((fail + 1)); printf '  FAIL  %s\n' "$1"; printf '        %s\n' "$2"; }

# The header block: bold field lines from the title down to the first line that
# is neither a field nor a continuation of one.
header_fields() {
  awk '
    /^# / { seen = 1; next }
    !seen { next }
    /^\*\*[A-Z]/ {
      line = $0
      sub(/^\*\*/, "", line)
      # a field name ends at the first colon, or at the closing ** if the bold
      # runs past it -- `**Status: CLOSED**` is one field named Status
      if (match(line, /[:*]/)) line = substr(line, 1, RSTART - 1)
      gsub(/[ \t]+$/, "", line)
      print line
      infield = 1
      next
    }
    infield && NF && /^[^|#]/ { next }
    infield && !NF { exit }
    seen && NF { exit }
  ' "$1"
}

for doc in docs/*-findings/[0-9][0-9][0-9][0-9]-*/findings.md \
           docs/*-findings/*/[0-9][0-9][0-9][0-9]-*/findings.md; do
  [ -f "$doc" ] || continue
  bundle="$(basename "$(dirname "$doc")")"

  fields="$(header_fields "$doc")"

  for req in Recorded Session Severity; do
    if printf '%s\n' "$fields" | grep -qx "$req"; then pass "$bundle  $req"
    else bad "$bundle" "required header field '$req' is missing"; fi
  done

  # nothing outside the schema, in the header block
  while IFS= read -r fld; do
    [ -n "$fld" ] || continue
    case "$fld" in
      Recorded|Session|Severity|"Felt at"|Scope|Read|"Relates to") ;;
      *) bad "$bundle" "header field '$fld' is not in the schema -- move it below the header" ;;
    esac
  done <<EOF
$fields
EOF

  # order: Recorded, Severity, [Felt at], Scope, then Relates to
  order="$(printf '%s\n' "$fields" | awk '
    $0=="Recorded"{print 1} $0=="Session"{print 2} $0=="Severity"{print 3}
    $0=="Felt at"{print 4} $0=="Scope"{print 5} $0=="Read"{print 6}
    $0=="Relates to"{print 7}')"
  if [ -n "$order" ] && ! printf '%s\n' "$order" | sort -nc 2>/dev/null; then
    bad "$bundle" "header fields are out of order -- Recorded, Session, Severity, [Felt at], [Scope], [Read], [Relates to]"
  else
    pass "$bundle  field order"
  fi

  # the finding table carries no `Decided` column
  if awk '/^\|[ ]*#[ ]*\|/ { print tolower($0); exit }' "$doc" | grep -q '| *decided *|'; then
    bad "$bundle" "finding table still has a 'Decided' column -- 'decided' is a status"
  else
    pass "$bundle  finding table shape"
  fi

  # the Findings table exists. A bundle with one finding used to omit it, and
  # `verify-findings-counts.sh` returns 1 when it finds no table -- so a missing
  # table read as "one finding" and agreed with every index. 26 bundles had none.
  if grep -qE '^\|[ ]*F[0-9]+[ ]*\|' "$doc"; then
    pass "$bundle  findings table present"
  else
    bad "$bundle" "no Findings table -- every bundle has one, even with a single finding"
  fi

  # the header renders as separate lines
  hardbreak="$(awk '
    /^# / { seen = 1; next }
    !seen { next }
    NF == 0 { if (started) exit; next }
    /^\*\*[A-Z]/ { started = 1; n = n + 1; last = NR; if ($0 !~ /  $/) { miss = miss " " n } ; next }
    started { print "WRAP"; exit }
    END { if (miss != "") print "MISS" miss; print "LAST" n }
  ' "$doc")"
  if printf '%s\n' "$hardbreak" | grep -q '^WRAP'; then
    bad "$bundle" "a header field wraps onto a second line -- one field, one line"
  elif printf '%s\n' "$hardbreak" | grep -q '^MISS'; then
    nmiss="$(printf '%s\n' "$hardbreak" | grep '^MISS' | sed 's/^MISS //')"
    nlast="$(printf '%s\n' "$hardbreak" | grep '^LAST' | sed 's/^LAST//')"
    stray="$(printf '%s\n' "$nmiss" | tr ' ' '\n' | grep -vx "$nlast" | tr '\n' ' ')"
    if [ -n "$(printf '%s' "$stray" | tr -d ' ')" ]; then
      bad "$bundle" "header field(s) $stray do not end in two spaces -- markdown joins them into one paragraph"
    else
      pass "$bundle  header renders"
    fi
  else
    pass "$bundle  header renders"
  fi

  # every Status cell holds one of the six finding statuses and nothing else.
  # `unclaimed` and `superseded` are bundle statuses and never appear here; a
  # cell carrying the status plus a note about which decision settled it is
  # restating what decisions.md owns. A `superseded` bundle is exempt: its rows
  # are frozen evidence of what the tree looked like, and three bundles are
  # retained precisely for that.
  dir="$(dirname "$doc")"
  if [ ! -f "$dir/STATUS-superseded" ]; then
    strays="$(awk -F'|' '
      /^\|[ ]*#[ ]*\|[ ]*Finding[ ]*\|/ { intbl = 1; next }
      intbl && /^\|[-: |]+\|$/ { next }
      intbl && /^\|[ ]*F?[0-9]+[ ]*\|/ {
        s = $4; gsub(/^[ \t]+|[ \t]+$/, "", s)
        if (s !~ /^`(un-started|framing|decided|resolved|reopened|withdrawn)`$/) print s
        next
      }
      intbl { intbl = 0 }
    ' "$doc" | head -3)"
    if [ -n "$strays" ]; then
      bad "$bundle" "finding Status is not one of the six: $(printf '%s' "$strays" | tr '\n' ';')"
    else
      pass "$bundle  finding statuses"
    fi
  fi

  # cross-reference: what the sibling documents cite must exist here
  have_f="$(grep -oE '^\|[ ]*F[0-9]+' "$doc" | tr -d '| ' | sort -u)"
  for sib in "$dir/decisions.md" "$dir/resolutions.md"; do
    [ -f "$sib" ] || continue
    cited="$(awk -F'|' '/^\|/ { print $2 "\n" $4 }' "$sib" | grep -oE 'F[0-9]+' | sort -u)"
    for fn in $cited; do
      if printf '%s\n' "$have_f" | grep -qx "$fn"; then
        pass "$bundle  $(basename "$sib") cites $fn"
      else
        bad "$bundle" "$(basename "$sib") cites $fn, which findings.md does not have"
      fi
    done
  done
  if [ -f "$dir/decisions.md" ] && [ -f "$dir/resolutions.md" ]; then
    have_d="$(grep -oE '^\|[ ]*D[0-9]+' "$dir/decisions.md" | tr -d '| ' | sort -u)"
    cited_d="$(awk -F'|' '/^\|/ { print $3 }' "$dir/resolutions.md" | grep -oE 'D[0-9]+' | sort -u)"
    for dn in $cited_d; do
      if printf '%s\n' "$have_d" | grep -qx "$dn"; then
        pass "$bundle  resolutions.md cites $dn"
      else
        bad "$bundle" "resolutions.md resolves by $dn, which decisions.md does not have"
      fi
    done
  fi
done

for doc in docs/*-findings/[0-9][0-9][0-9][0-9]-*/decisions.md \
           docs/*-findings/*/[0-9][0-9][0-9][0-9]-*/decisions.md \
           docs/*-findings/[0-9][0-9][0-9][0-9]-*/resolutions.md \
           docs/*-findings/*/[0-9][0-9][0-9][0-9]-*/resolutions.md; do
  [ -f "$doc" ] || continue
  bundle="$(basename "$(dirname "$doc")")/$(basename "$doc")"
  if grep -q '^\*\*Findings bundle:' "$doc"; then
    bad "$bundle" "uses 'Findings bundle:' -- the field is named 'Bundle:'"
  else
    pass "$bundle  bundle field name"
  fi
  if grep -qE '^\*\*Status( when opened| now)?:\*\*' "$doc"; then
    bad "$bundle" "carries a Status field -- the STATUS- tag and the index row own the status"
  else
    pass "$bundle  no status copy"
  fi
  if grep -q '^\*\*Session:' "$doc"; then
    pass "$bundle  session field"
  else
    bad "$bundle" "no Session field -- it is required, and holds an em dash where none was recorded"
  fi
  if grep -q '^\*\*Read against:' "$doc"; then
    bad "$bundle" "uses 'Read against:' -- the field is named 'Read:'"
  else
    pass "$bundle  read field name"
  fi
done

# --- code blocks are fenced, never indented ------------------------------------
for doc in docs/legend.md .github/session-management-instructions.md \
           .github/toolkit-instructions.md .github/copilot-instructions.md \
           docs/*-findings/[0-9][0-9][0-9][0-9]-*/*.md \
           docs/*-findings/*/[0-9][0-9][0-9][0-9]-*/*.md \
           docs/architecture/*.md docs/sessions/*/*.md; do
  [ -f "$doc" ] || continue
  hits="$(awk '
    /^```/            { fence = !fence; next }
    fence             { next }
    /^[ \t]*$/        { blank = 1; next }
    blank && /^    [^ ]/ && $0 !~ /^[ \t]*[-*+] / { print NR; blank = 0; next }
    { blank = 0 }
  ' "$doc" | head -3)"
  if [ -n "$hits" ]; then
    bad "$doc" "indented code block at line(s) $(printf '%s' "$hits" | tr '\n' ' ')-- fence it with \`\`\`"
  else
    pass "$doc  code blocks fenced"
  fi
  if grep -q '^```markdown$' "$doc"; then
    bad "$doc" "a fence is tagged \`markdown\` -- some renderers interpret it instead of showing it; tag it \`text\`"
  else
    pass "$doc  fences are inert"
  fi
done

echo ""
printf "  %-14s %s\n" "OK:"   "$ok"
printf "  %-14s %s\n" "FAIL:" "$fail"
echo ""

if [ "$fail" -eq 0 ]; then
  echo "  Every findings header matches the schema."
  echo ""
  exit 0
fi

echo "  The schema is section 11 of .github/session-management-instructions.md."
echo ""
exit 1
