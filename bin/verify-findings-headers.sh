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
#   findings.md      required: Recorded, Severity -- the two every reading has
#                    optional: Felt at, Scope, and Relates to (repeatable, last)
#                    order: Recorded, Severity, Felt at, Scope, Relates to
#                    NO other field in the header block. That is the rule that
#                    matters: the schema fixes the vocabulary, not the content.
#                    Requiring Scope would mean inventing it for the 26 readings
#                    that never had one, which is not a checker's business.
#   decisions.md     required: Bundle, and nothing named `Findings bundle`
#   resolutions.md   required: Bundle, Recorded
#   finding table    `| # | Finding | Status |` -- no `Decided` column; that
#                    became a status of its own
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

  for req in Recorded Severity; do
    if printf '%s\n' "$fields" | grep -qx "$req"; then pass "$bundle  $req"
    else bad "$bundle" "required header field '$req' is missing"; fi
  done

  # nothing outside the schema, in the header block
  while IFS= read -r fld; do
    [ -n "$fld" ] || continue
    case "$fld" in
      Recorded|Severity|"Felt at"|Scope|"Relates to") ;;
      *) bad "$bundle" "header field '$fld' is not in the schema -- move it below the header" ;;
    esac
  done <<EOF
$fields
EOF

  # order: Recorded, Severity, [Felt at], Scope, then Relates to
  order="$(printf '%s\n' "$fields" | awk '
    $0=="Recorded"{print 1} $0=="Severity"{print 2} $0=="Felt at"{print 3}
    $0=="Scope"{print 4} $0=="Relates to"{print 5}')"
  if [ -n "$order" ] && ! printf '%s\n' "$order" | sort -nc 2>/dev/null; then
    bad "$bundle" "header fields are out of order -- Recorded, Severity, [Felt at], Scope, [Relates to]"
  else
    pass "$bundle  field order"
  fi

  # the finding table carries no `Decided` column
  if awk '/^\|[ ]*#[ ]*\|/ { print tolower($0); exit }' "$doc" | grep -q '| *decided *|'; then
    bad "$bundle" "finding table still has a 'Decided' column -- 'decided' is a status"
  else
    pass "$bundle  finding table shape"
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
