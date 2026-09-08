#!/usr/bin/env bash
# Report which documents may have gone stale because a source they describe
# changed. Every source-to-document edge is asserted in
# .internal/ai-scripts/session-management/doc-currency.json; nothing is inferred.
#
#   ./bin/verify-doc-currency.sh              what has drifted
#   ./bin/verify-doc-currency.sh --all        include what is current
#   ./bin/verify-doc-currency.sh --coverage   what nothing watches
#   ./bin/verify-doc-currency.sh --confirm ID re-stamp after reviewing
#
# Exits non-zero when a `critical` watch has drifted.
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
helper="$repo_root/.internal/ai-scripts/session-management/doc_currency.py"
[ -f "$helper" ] || { printf 'verify-doc-currency: helper not found: %s\n' "$helper" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { printf 'verify-doc-currency: python3 required\n' >&2; exit 2; }
exec python3 "$helper" "$@"
