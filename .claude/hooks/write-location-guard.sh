#!/usr/bin/env bash
# =============================================================================
# write-location-guard.sh
#
# PreToolUse hook. A session composes in a copy outside the owner's checkout and
# hands over a patch; the owner applies it. This refuses a write whose
# destination is inside the owner's checkout, and reports a shell command that
# looks like one.
#
# It restores the signal 0038 removed. Before 0038 a dirty working tree in the
# owner's checkout meant somebody had broken the rule, and someone noticing was
# the only enforcement there has ever been. Since 0038 the tree is clean by
# design -- and dirty in exactly the same way after an unauthorised apply as
# after an authorised one.
#
# 0049 F4: the Revision 231 guard matched Edit|Write|MultiEdit, and every one of
# the writes it was meant to catch was a `cp` inside a Bash call.
#
# CLASSIFICATION: neither bin/ nor .internal/ -- tooling for the agent, never
# sourced. One JSON object in on stdin, one out on stdout.
#
# ESCAPE: export SESSION_APPLY_APPROVED=1 for the one call the owner has asked
# for. Deliberate, per invocation, and it leaves a trace in the transcript.
#
# Bash 3.2 clean.
# =============================================================================
set -uo pipefail

payload=$(cat)
root="${CLAUDE_PROJECT_DIR:-}"
[ -n "$root" ] || { printf '{}\n'; exit 0; }

if [ "${SESSION_APPLY_APPROVED:-0}" = "1" ]; then printf '{}\n'; exit 0; fi

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}
warn() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$1"
  exit 0
}

path=$(printf '%s' "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
if [ -n "$path" ]; then
  case "$path" in
    "$root"/*|"$root")
      deny "Section 6: compose in a copy OUTSIDE the owner's checkout and hand over a patch. This write targets the checkout itself. Edit your session copy instead, then produce the patch with: git add -N . && git diff > <patch>. If the owner has asked for this one apply, re-run it with SESSION_APPLY_APPROVED=1." ;;
  esac
  printf '{}\n'; exit 0
fi

cmd=$(printf '%s' "$payload" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)"[[:space:]]*}.*/\1/p')
if [ -n "$cmd" ]; then
  case "$cmd" in
    *cp\ *|*mv\ *|*rsync*|*tee\ *|*">"*|*install\ *|*patch\ *|*"git apply"*)
      case "$cmd" in
        *"$root"*)
          warn "This command writes into the owner's checkout. Section 6: hand over a patch and let the owner apply it. 0049 records six revisions applied this way by cp. If the owner asked for this apply, say so in your report." ;;
      esac ;;
  esac
fi
printf '{}\n'; exit 0
