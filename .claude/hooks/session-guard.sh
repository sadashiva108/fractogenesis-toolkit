#!/usr/bin/env bash
# =============================================================================
# session-guard.sh
#
# PostToolUse hook. When an Edit/Write touches a session-management record, name
# the rule that governs it. Companion to runbook-guard.sh, which does the same
# for runbooks and scripts.
#
# CLASSIFICATION: neither bin/ nor .internal/ -- tooling for the agent, never
# sourced. One JSON object in on stdin, one out on stdout.
#
# It always exits 0. PostToolUse runs AFTER the edit; there is nothing left to
# block, so a rule is reported as context, not as a failure.
#
# Bash 3.2 clean.
# =============================================================================
set -uo pipefail

payload=$(cat)
path=$(printf '%s' "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
[ -n "$path" ] || { printf '{}\n'; exit 0; }

root="${CLAUDE_PROJECT_DIR:-.}"
rel=${path#"$root"/}
note=""

say() { note="${note}${note:+ }$1"; }

case "$rel" in
  docs/*-findings/*)
    dir=$(dirname "$path")
    while [ "$dir" != "/" ] && [ ! -f "$dir/metadata.json" ]; do dir=$(dirname "$dir"); done
    if [ -f "$dir/metadata.json" ]; then
      own=$(sed -n 's/.*"ownership"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$dir/metadata.json" | head -1)
      sup=$(grep -c '"supersededBy"' "$dir/metadata.json" 2>/dev/null || true)
      case "$own" in
        unclaimed)
          say "This bundle is UNCLAIMED: closed to every session until the owner assigns it (docs/legend.md)." ;;
        transferred)
          say "This bundle is TRANSFERRED: the target session's first read is what opens it." ;;
      esac
      [ "${sup:-0}" -gt 0 ] && say "This bundle is SUPERSEDED. Its reading is retained and is never edited (section 9)."
      grep -q '"status"[[:space:]]*:[[:space:]]*"resolved"' "$dir/metadata.json" 2>/dev/null &&
        say "A resolved finding is frozen; reopened is the only door, and it is a declared act."
    fi
    case "$rel" in
      */findings.md) say "findings.md is written once. Correct it for accuracy, never to match what was later decided." ;;
      */metadata.json) say "metadata.json is authoritative. progress is DERIVED and is never stored (state-as-data.md 4.4)." ;;
    esac
    ;;
  .github/session-management-instructions.md|docs/legend.md)
    say "TOOLKIT WRITE. Gated on a decided finding owned by this session, or an owner override that the revision names (docs/legend.md)." ;;
  docs/sessions/*/metadata.json)
    say "Authoritative for who owns what. A session's state derives from it; ended.on is what says a session has stopped." ;;
  docs/sessions/*/prompt.md)
    say "A prompt TRACKS. When the conformant prompt changes, refresh this copy and say which revision it holds." ;;
  .github/ai-prompts/session-management/*)
    say "This is the prompt every session is pasted. It lives in the repository as of Revision 231; do not restate a rule that has a home." ;;
esac

[ -n "$note" ] || { printf '{}\n'; exit 0; }
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$note"
exit 0
