#!/usr/bin/env bash
# Propose an allocation of unclaimed findings bundles to sessions, and decide
# what to ask next. Reads the tree; writes nothing. The owner assigns.
#
#   ./bin/plan-findings-work.sh graph
#   ./bin/plan-findings-work.sh allocate [--new-sessions N]
#   ./bin/plan-findings-work.sh ask
#
# Design: docs/architecture/allocation-and-inquiry.md
# State:  docs/architecture/state-as-data.md
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
helper="$repo_root/.internal/ai-scripts/session-management/plan_findings_work.py"

if [ ! -f "$helper" ]; then
  printf 'plan-findings-work: helper not found: %s\n' "$helper" >&2
  exit 2
fi
if ! command -v python3 >/dev/null 2>&1; then
  printf 'plan-findings-work: python3 is required\n' >&2
  exit 2
fi

exec python3 "$helper" "$@"
