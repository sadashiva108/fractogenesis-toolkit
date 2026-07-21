#!/usr/bin/env bash
# =============================================================================
# verify-artifact-config.sh
#
# Verifies the artifact-config fragments the reimage workflow depends on are
# present in the active fragment directory and pass a bash syntax check.
# Invoked by Phase 2B (backup-home.md, "Confirm the Artifact-Config Fragments")
# and usable before any runbook that reads the fragments.
#
# This file is intended for bin/. It is an aggregate validator: it checks every
# fragment and reports all results rather than aborting on the first problem, so
# it deliberately does NOT use `set -e`. It resolves the active fragment
# directory itself instead of sourcing the shared loader, because the loader
# sources the fragments and would abort on the very syntax error this script
# exists to report.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/verify-artifact-config.sh
#
#   # Verify the active fragment set
#   ./bin/verify-artifact-config.sh
#
#   # Verify a specific fragment directory
#   ./bin/verify-artifact-config.sh --config-dir /path/to/artifact-config
#
#   # Skip the informational reference scan
#   ./bin/verify-artifact-config.sh --no-references
#
# Options:
#   --config-dir PATH   Verify fragments in PATH instead of the resolved dir.
#   --no-references     Skip the informational "where referenced" scan.
#   -h, --help          Show this message and exit.
#
# Active-directory resolution (mirrors artifact-config.sh precedence):
#   1. --config-dir, or ARTIFACT_CONFIG_DIR from the environment / reimage.env.
#   2. $REIMAGE_WORKSPACE_ROOT/artifact-config when that directory exists.
#   3. Committed templates under .internal/templates/artifact-config.
#
# Exit status:
#   0  All required fragments are present and pass the syntax check.
#   1  One or more fragments are missing or failed the syntax check.
#   2  Usage error, or the resolved fragment directory does not exist.
# --- END USAGE ---
# =============================================================================

# Aggregate validator: intentionally NOT `set -e`. A failing `bash -n` on one
# fragment must be recorded while the run continues, so every problem is
# reported in a single pass. `-u` and `pipefail` are still wanted.
set -uo pipefail

# ---------------------------------------------------------------------------
# Locate repository
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; DIM='\033[2m'; BLD='\033[1m'; RST='\033[0m'

# ---------------------------------------------------------------------------
# Defaults and command-line state
# ---------------------------------------------------------------------------
CONFIG_DIR_OVERRIDE=""
SCAN_REFERENCES=true

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
    --config-dir)
      require_option_value "$1" "${2:-}"
      CONFIG_DIR_OVERRIDE="$2"
      shift 2
      ;;
    --no-references)
      SCAN_REFERENCES=false
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
# Required fragments — the set artifact-config.sh sources (alphabetical)
# ---------------------------------------------------------------------------
REQUIRED_FRAGMENTS=(
  expected-artifact-folders.conf.sh
  external-dotfiles.conf.sh
  external-excludes.conf.sh
  external-targets.conf.sh
  onedrive-extra-excludes.conf.sh
  onedrive-targets.conf.sh
  secret-flags.conf.sh
  secrets-targets.conf.sh
  skip-entries.conf.sh
)

# ---------------------------------------------------------------------------
# Resolve the active fragment directory
#
# Mirrors artifact-config.sh precedence WITHOUT sourcing the fragments, so a
# broken fragment is reported here rather than aborting a shared-config load.
# reimage.env is sourced (assignments only) solely to pick up ARTIFACT_CONFIG_DIR
# and REIMAGE_WORKSPACE_ROOT when no --config-dir override is given.
# ---------------------------------------------------------------------------
if [[ -z "$CONFIG_DIR_OVERRIDE" ]]; then
  REIMAGE_ENV="${REIMAGE_ENV:-$REPO_ROOT/reimage.env}"
  if [[ -f "$REIMAGE_ENV" ]]; then
    # shellcheck disable=SC1090
    if ! source "$REIMAGE_ENV"; then
      echo "ERROR: failed to source reimage.env: $REIMAGE_ENV" >&2
      exit 2
    fi
  fi
fi

TEMPLATE_DIR="$REPO_ROOT/.internal/templates/artifact-config"
WORKSPACE_DIR="${REIMAGE_WORKSPACE_ROOT:+$REIMAGE_WORKSPACE_ROOT/artifact-config}"

if [[ -n "$CONFIG_DIR_OVERRIDE" ]]; then
  ACTIVE_DIR="$CONFIG_DIR_OVERRIDE"
elif [[ -n "${ARTIFACT_CONFIG_DIR:-}" ]]; then
  ACTIVE_DIR="$ARTIFACT_CONFIG_DIR"
elif [[ -n "$WORKSPACE_DIR" && -d "$WORKSPACE_DIR" ]]; then
  ACTIVE_DIR="$WORKSPACE_DIR"
else
  ACTIVE_DIR="$TEMPLATE_DIR"
fi

if [[ ! -d "$ACTIVE_DIR" ]]; then
  echo "ERROR: artifact-config directory not found: $ACTIVE_DIR" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Verify presence + syntax
# ---------------------------------------------------------------------------
echo ""
echo -e "${BLD}Artifact-config fragment check${RST}"
echo -e "  ${DIM}Directory: $ACTIVE_DIR${RST}"
echo ""

fail_count=0
for fragment in "${REQUIRED_FRAGMENTS[@]}"; do
  path="$ACTIVE_DIR/$fragment"
  if [[ ! -f "$path" ]]; then
    printf "  ${RED}MISSING${RST}  %s\n" "$fragment"
    fail_count=$((fail_count + 1))
  elif bash -n "$path" 2>/dev/null; then
    printf "  ${GRN}OK     ${RST}  %s\n" "$fragment"
  else
    printf "  ${RED}SYNTAX ${RST}  %s\n" "$fragment"
    bash -n "$path" 2>&1 | sed 's/^/           /' >&2
    fail_count=$((fail_count + 1))
  fi
done

# ---------------------------------------------------------------------------
# Informational: where the fragments are referenced
# ---------------------------------------------------------------------------
if [[ "$SCAN_REFERENCES" == true ]]; then
  echo ""
  echo -e "${BLD}Fragment references${RST}  ${DIM}(informational)${RST}"
  references="$(
    cd "$REPO_ROOT" && grep -RInE \
      'expected-artifact-folders|external-dotfiles|external-excludes|external-targets|onedrive-extra-excludes|onedrive-targets|secret-flags|secrets-targets|skip-entries' \
      bin .internal 2>/dev/null
  )"
  if [[ -n "$references" ]]; then
    printf '%s\n' "$references" | sed 's/^/  /'
  else
    echo -e "  ${DIM}none found${RST}"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
if (( fail_count == 0 )); then
  echo -e "  ${GRN}${BLD}✓ All ${#REQUIRED_FRAGMENTS[@]} fragments present and valid.${RST}"
  echo ""
  exit 0
fi

echo -e "  ${RED}${BLD}✗ ${fail_count} fragment(s) missing or invalid.${RST}"
echo -e "  ${YEL}Fix them in $ACTIVE_DIR before running the backup.${RST}"
echo ""
exit 1
