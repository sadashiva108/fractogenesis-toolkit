#!/usr/bin/env bash
# Contracts and regressions for the session management framework.
# Runs against fixtures only -- never against the tree.
#
#   ./bin/test-session-management.sh [-v]
#
# Design: docs/architecture/allocation-and-inquiry.md, state-as-data.md
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
suite="$repo_root/.internal/ai-scripts/session-management/tests/test_session_management.py"
[ -f "$suite" ] || { printf 'test-session-management: suite not found: %s\n' "$suite" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { printf 'test-session-management: python3 required\n' >&2; exit 2; }
exec python3 "$suite" "$@"
