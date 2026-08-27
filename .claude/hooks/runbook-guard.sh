#!/usr/bin/env bash
# =============================================================================
# runbook-guard.sh
#
# PostToolUse hook. Classifies the file an Edit/Write just touched, runs the
# checks this repo already owns against it, and names the authoring skill once
# per class per session.
#
# CLASSIFICATION: neither bin/ nor .internal/ -- this is tooling for the agent,
# not for the workflow, and it is never sourced. One JSON object in on stdin,
# one out on stdout.
#
# It always exits 0. PostToolUse runs AFTER the edit, so there is nothing left
# to block; a finding is reported as context, not as a failure.
#
# Bash 3.2 clean, same as everything else here.
# =============================================================================
set -uo pipefail

SKILL="runbook-conventions"        # <-- your skill's directory name

payload="$(cat)"

field() {
  printf '%s' "$payload" | python3 -c '
import json, sys
cur = json.load(sys.stdin)
for k in sys.argv[1].split("."):
    if not isinstance(cur, dict): sys.exit(0)
    cur = cur.get(k)
    if cur is None: sys.exit(0)
print(cur)
' "$1" 2>/dev/null
}

file="$(field tool_input.file_path)"
session="$(field session_id)"
[ -n "$file" ] || exit 0

repo="${CLAUDE_PROJECT_DIR:-$PWD}"
case "$file" in
  "$repo"/*) rel="${file#"$repo"/}" ;;
  *)         exit 0 ;;
esac

# Runbooks are TOP-LEVEL .md only. references/ and .github/ hold prose the
# runbook template does not govern, and sweeping them in is how a formatter
# ends up rewriting its own instructions.
case "$rel" in
  bin/*|.internal/*)
    case "$rel" in
      *.sh|*.py) kind="script" ;;
      *)         exit 0 ;;
    esac
    ;;
  */*)  exit 0 ;;
  *.md) kind="runbook" ;;
  *)    exit 0 ;;
esac

findings=""
add() { findings="${findings}${findings:+
}- $1"; }

if [ "$kind" = "script" ]; then
  case "$rel" in
    *.sh)
      if ! out="$(bash -n "$file" 2>&1)"; then
        add "\`bash -n $rel\` FAILED: $out"
      elif command -v shellcheck >/dev/null 2>&1; then
        out="$(cd "$repo" && shellcheck -x "$rel" 2>&1)" || \
          add "\`shellcheck -x $rel\`: $(printf '%s' "$out" | head -20)"
      fi
      ;;
  esac
fi

if [ "$kind" = "runbook" ] && [ -x "$repo/bin/verify-doc-paths.sh" ]; then
  out="$(cd "$repo" && ./bin/verify-doc-paths.sh 2>&1)" || \
    add "\`bin/verify-doc-paths.sh\` FAILED after this edit: $(printf '%s' "$out" | head -20)"
fi

# Debounced per session per class. Without this a twenty-edit runbook pass
# prints the same reminder twenty times and it stops being read.
mark="${TMPDIR:-/tmp}/fractogenesis-guard.${session:-none}.$kind"
remind="false"
if [ ! -e "$mark" ]; then : > "$mark"; remind="true"; fi

[ -n "$findings" ] || [ "$remind" = "true" ] || exit 0

msg="Edited \`$rel\` ($kind)."
if [ "$remind" = "true" ]; then
  msg="$msg Apply the \`/$SKILL\` skill before this turn ends — it reconciles the file against .github/ai-templates/ and .github/ai-prompts/. Invoke it once; this reminder will not repeat for $kind files in this session."
fi
if [ -n "$findings" ]; then
  msg="$msg

Checks that ran:
$findings"
fi

printf '%s' "$msg" | python3 -c '
import json, sys
print(json.dumps({"hookSpecificOutput": {
  "hookEventName": "PostToolUse",
  "additionalContext": sys.stdin.read()}}))
'
exit 0