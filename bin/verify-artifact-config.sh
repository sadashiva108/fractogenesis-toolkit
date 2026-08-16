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
#   --no-references     Skip the informational consumer scan entirely.
#   --references-detail Print every matching file:line instead of the summary.
#   -h, --help          Show this message and exit.
#
# The consumer scan is informational and never affects exit status. It answers
# "if I edit this fragment, what reads it?" — the validator's own source and the
# fragments' own header comments are excluded, since neither is a consumer.
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
# Same palette and section helpers as backup-home.sh and capture-size-audit.sh
# so severity colors mean the same thing across the workflow.
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

thin_hr()     { printf '%s\n' "  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"; }
log_section() { echo ""; echo -e "${BLD}${CYN}▸ $1${RST}"; thin_hr; }

# ---------------------------------------------------------------------------
# Defaults and command-line state
# ---------------------------------------------------------------------------
CONFIG_DIR_OVERRIDE=""
SCAN_REFERENCES=true
REFERENCES_DETAIL=false

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
    --references-detail)
      REFERENCES_DETAIL=true
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
# Optional fragments — sourced by artifact-config.sh only when present.
#
# A workspace copy created before one of these shipped must keep validating
# clean, so absence is reported as a note, never as a failure.
# ---------------------------------------------------------------------------
OPTIONAL_FRAGMENTS=(
  secret-shapes.conf.sh
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

# Record which rule won as well as the path. Knowing a run fell back to the
# committed templates is the difference between verifying this Mac's fragment
# set and verifying the generic one.
if [[ -n "$CONFIG_DIR_OVERRIDE" ]]; then
  ACTIVE_DIR="$CONFIG_DIR_OVERRIDE"
  ACTIVE_SOURCE="--config-dir override"
elif [[ -n "${ARTIFACT_CONFIG_DIR:-}" ]]; then
  ACTIVE_DIR="$ARTIFACT_CONFIG_DIR"
  ACTIVE_SOURCE="ARTIFACT_CONFIG_DIR from the environment or reimage.env"
elif [[ -n "$WORKSPACE_DIR" && -d "$WORKSPACE_DIR" ]]; then
  ACTIVE_DIR="$WORKSPACE_DIR"
  ACTIVE_SOURCE="workspace copy under REIMAGE_WORKSPACE_ROOT"
else
  ACTIVE_DIR="$TEMPLATE_DIR"
  ACTIVE_SOURCE="committed templates (no workspace copy found)"
fi

if [[ ! -d "$ACTIVE_DIR" ]]; then
  echo "ERROR: artifact-config directory not found: $ACTIVE_DIR" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Verify presence + syntax
# ---------------------------------------------------------------------------
log_section "Artifact-config fragment check"
echo -e "  ${DIM}Directory: $ACTIVE_DIR${RST}"
echo -e "  ${DIM}Selected by: $ACTIVE_SOURCE${RST}"
if [[ "$ACTIVE_DIR" == "$TEMPLATE_DIR" ]]; then
  echo -e "  ${YEL}⚠  Verifying the committed templates, not a per-machine copy.${RST}"
  echo -e "  ${DIM}   Create one with: python3 bin/prepare-artifact-root.py init-artifact-config${RST}"
fi
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

# Optional fragments are syntax-checked when present and merely noted when not.
# A missing one is not a failure: the loader supplies a built-in floor, so an
# older workspace copy stays valid.
optional_absent=0
for fragment in "${OPTIONAL_FRAGMENTS[@]}"; do
  path="$ACTIVE_DIR/$fragment"
  if [[ ! -f "$path" ]]; then
    optional_absent=$((optional_absent + 1))
    printf "  ${DIM}ABSENT ${RST}  %s  ${DIM}(optional — built-in defaults apply)${RST}\n" "$fragment"
  elif bash -n "$path" 2>/dev/null; then
    printf "  ${GRN}OK     ${RST}  %s  ${DIM}(optional)${RST}\n" "$fragment"
  else
    printf "  ${RED}SYNTAX ${RST}  %s  ${DIM}(optional)${RST}\n" "$fragment"
    bash -n "$path" 2>&1 | sed 's/^/           /' >&2
    fail_count=$((fail_count + 1))
  fi
done

if (( optional_absent > 0 )); then
  echo ""
  echo -e "  ${DIM}Copy an absent optional fragment in with:${RST}"
  echo -e "  ${DIM}  cp .internal/templates/artifact-config/<fragment> \"\$ACTIVE_DIR\"/${RST}"
fi

# ---------------------------------------------------------------------------
# Informational: where the fragments are referenced
# ---------------------------------------------------------------------------
if [[ "$SCAN_REFERENCES" == true ]]; then
  log_section "Fragment consumers  (informational — does not affect the result)"

  for fragment in "${REQUIRED_FRAGMENTS[@]}"; do
    # A fragment's own header comment and this validator's own source both
    # mention the filename without consuming it. Excluding them is what turns
    # this from a wall of grep output into an answer.
    consumers="$(
      cd "$REPO_ROOT" 2>/dev/null \
        && grep -rlF --exclude-dir=__pycache__ "$fragment" bin .internal 2>/dev/null \
        | grep -v '^bin/verify-artifact-config\.sh$' \
        | grep -v '^\.internal/templates/artifact-config/' \
        | sort
    )"

    consumer_count=$(printf '%s' "$consumers" | grep -c . )

    if (( consumer_count == 0 )); then
      printf "  ${YEL}%-38s  %2s  no consumer found${RST}\n" "$fragment" "0"
      continue
    fi

    consumer_list="$(printf '%s' "$consumers" | tr '\n' '@' | sed 's/@$//;s/@/, /g')"
    printf "  ${DIM}%-38s  %2s  %s${RST}\n" "$fragment" "$consumer_count" "$consumer_list"
  done

  if [[ "$REFERENCES_DETAIL" == true ]]; then
    echo ""
    echo -e "  ${DIM}Every match, including self-references:${RST}"
    (
      cd "$REPO_ROOT" 2>/dev/null && grep -RInE \
        'expected-artifact-folders|external-dotfiles|external-excludes|external-targets|onedrive-extra-excludes|onedrive-targets|secret-flags|secret-shapes|secrets-targets|skip-entries' \
        bin .internal 2>/dev/null
    ) | sed 's/^/    /'
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
