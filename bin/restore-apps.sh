#!/usr/bin/env bash
# =============================================================================
# restore-apps.sh
#
# Phase 12 — Restore Apps umbrella plan-note emitter.
#
# Surveys the pre-image app-settings backups and encrypted-secrets sources that
# feed the Phase 12 restore steps, records which ones are present versus
# missing, and writes a per-run restore-plan note under the reimaged system's
# restore-notes/ area. The plan-note is a working checklist the operator ticks
# through by hand while following restore-apps.md; the script itself installs
# no apps, imports no settings, and touches no secrets.
#
# This is an aggregate validator. Individual app source lookups may report
# MISSING without aborting the run; the operator uses those rows to decide
# whether to re-mount the artifact volume, re-run an earlier backup, or accept
# a missing source and continue.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/restore-apps.sh
#
#   # Default -- generate a restore-apps plan-note under
#   # $REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/.
#   ./bin/restore-apps.sh
#
#   # Override the artifact root for this invocation.
#   ./bin/restore-apps.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Write the plan-note under a specific directory instead of the default.
#   ./bin/restore-apps.sh --output-root ~/Desktop/reimaged-system-artifacts/restore-notes
#
#   # Reveal the generated plan-note in Finder after completion.
#   ./bin/restore-apps.sh --open
#
# Options:
#   --artifact-root PATH   Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --output-root PATH     Override the destination directory for the
#                          generated plan-note.
#                          Default: <artifact-root>/reimaged-system/restore-notes
#   --signoff-root PATH    Directory for the sign-off.
#                          Default: <artifact-root>/reimaged-system/sign-offs
#   --open                 Reveal the generated plan-note in Finder on
#                          completion.
#   -h, --help             Show this message and exit.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Output location:
#   $REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-apps-plan-YYYYMMDD-HHMMSS.md
#   $REIMAGE_ARTIFACT_ROOT/reimaged-system/sign-offs/restore-apps-YYYYMMDD-HHMMSS.md
#
#   The plan-note surveys the sources and is regenerable. The sign-off holds
#   the rows a person answers; answers carry forward between runs and each
#   records the run it was answered against. Phase 14 reads the sign-off.
#
# Exit status:
#   0  Plan-note written; no fatal errors. MISSING source rows do not change
#      the exit status.
#   1  The plan-note could not be written.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

# Aggregate validator: individual source lookups become PRESENT/MISSING rows
# in the plan-note rather than aborting the run. Keep -u and pipefail on.
set -uo pipefail
# NOTE: intentionally NOT set -e. A missing backup source is an expected,
# reportable outcome here, not a fatal one: the operator needs the complete
# PRESENT/MISSING inventory in one pass so they can decide whether to remount
# the artifact volume, rerun an earlier backup, or accept the gap. Aborting on
# the first missing path would hide every row after it.

# ---------------------------------------------------------------------------
# Locate repository and load shared reimage config
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"

if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi

# Phase 12 uses the artifact drive when it is mounted, and falls back to the
# workspace root or ~/Desktop only when the operator has explicitly overridden
# --output-root. Keep loading permissive so --artifact-root can still override
# the value after parsing; the resolved value is validated below instead.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
if ! source "$CONFIG_LOADER"; then
  echo "ERROR: shared reimage configuration could not be loaded." >&2
  exit 2
fi

# The sign-off rows leave the plan-note entirely. A plan-note is regenerable --
# rerunning this script is the documented way to refresh the survey -- and an
# answered row is the one thing in it that cannot be recomputed. Keeping both in
# one file meant a rerun handed Phase 14 a fresh set of TODOs while the answers
# sat in an older file nothing reads. See .internal/sign-offs.sh.
SIGNOFF_LIB="$REPO_ROOT/.internal/sign-offs.sh"
if [[ ! -f "$SIGNOFF_LIB" ]]; then
  echo "ERROR: shared sign-off helper not found: $SIGNOFF_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/sign-offs.sh
source "$SIGNOFF_LIB"

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
# Defaults and command-line parsing
# ---------------------------------------------------------------------------
STAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_ROOT=""
SIGNOFF_ROOT=""
OPEN_RESULT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --output-root)
      require_option_value "$1" "${2:-}"
      OUTPUT_ROOT="$2"
      shift 2
      ;;
    --signoff-root)
      require_option_value "$1" "${2:-}"
      SIGNOFF_ROOT="$2"
      shift 2
      ;;
    --open)
      OPEN_RESULT=true
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
# Resolve output destination
# ---------------------------------------------------------------------------
if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set. Reconnect the artifact volume, source reimage.env, or pass --artifact-root PATH." >&2
  exit 2
fi

if [[ -z "$OUTPUT_ROOT" ]]; then
  OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes"
fi

if ! mkdir -p "$OUTPUT_ROOT" 2>/dev/null; then
  echo "ERROR: cannot create output root: $OUTPUT_ROOT" >&2
  exit 2
fi

if [[ -z "$SIGNOFF_ROOT" ]]; then
  SIGNOFF_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system/sign-offs"
fi

SIGNOFF_ROOT="$(absolute_path "$SIGNOFF_ROOT")"

if [[ -n "${REPO_ROOT:-}" && ( "$SIGNOFF_ROOT" == "$REPO_ROOT" || "$SIGNOFF_ROOT" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $SIGNOFF_ROOT" >&2
  exit 2
fi

PLAN_FILE="$OUTPUT_ROOT/restore-apps-plan-$STAMP.md"

# Open the sign-off before the plan is written: it resolves SIGNOFF_FILE, which
# the plan-note points at, and carries forward any answers from the last run.
RUN_ID="restore-apps-$STAMP"
if ! signoff_begin "$SIGNOFF_ROOT" "restore-apps" "$RUN_ID"; then
  echo "ERROR: could not open the sign-off under $SIGNOFF_ROOT" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Source enumeration
# ---------------------------------------------------------------------------
APP_BACKUP_ROOT="$REIMAGE_ARTIFACT_ROOT/app-settings-backup"
SECRETS_ROOT="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"

status_row() {
  local label="$1"
  local path="$2"
  if [[ -e "$path" ]]; then
    printf '| %s | `%s` | PRESENT |\n' "$label" "$path"
  else
    printf '| %s | `%s` | MISSING |\n' "$label" "$path"
  fi
}

# Prefer the Phase 2C app-settings capture for VS Code; fall back to the
# lightweight toolkit-snapshot copy only when the dedicated backup is absent.
# VS Code state comes from the Phase 2D dedicated capture only. The
# toolkit snapshot does not contain a vscode/ directory.
resolve_vscode_source() {
  printf '%s\n' "$APP_BACKUP_ROOT/vscode"
}

VSCODE_SOURCE="$(resolve_vscode_source)"

# ---------------------------------------------------------------------------
# Generate the plan-note
# ---------------------------------------------------------------------------
{
  printf '# Restore Apps Plan — %s\n\n' "$STAMP"
  printf 'Generated by `bin/restore-apps.sh` on %s.\n\n' "$(date)"
  printf 'This plan-note pairs with [[restore-apps|restore-apps.md]] (Phase 12). Work each row by hand; the script does not install apps or import settings.\n\n'

  printf '## Backup Sources\n\n'
  printf '| App area | Backup source | Status |\n'
  printf '| --- | --- | --- |\n'
  status_row "Chrome"     "$APP_BACKUP_ROOT/chrome"
  status_row "Docker"     "$APP_BACKUP_ROOT/docker"
  status_row "IntelliJ"   "$APP_BACKUP_ROOT/intellij"
  status_row "Obsidian"   "$APP_BACKUP_ROOT/obsidian"
  status_row "Postman"    "$APP_BACKUP_ROOT/postman"
  status_row "Raycast"    "$APP_BACKUP_ROOT/raycast"
  status_row "Terminal"   "$APP_BACKUP_ROOT/terminal"
  status_row "VS Code"    "$VSCODE_SOURCE"
  printf '\n'

  printf '## Secret-Bearing Sources (mount the encrypted DMG before use)\n\n'
  printf '| Area | Encrypted source | Status |\n'
  printf '| --- | --- | --- |\n'
  status_row "Docker config"        "$SECRETS_ROOT/docker/config.json"
  status_row "IntelliJ HTTP Client" "$SECRETS_ROOT/intellij"
  status_row "Postman vault"        "$SECRETS_ROOT/postman"
  status_row "Licenses / activation" "$SECRETS_ROOT/licenses"
  printf '\n'

  printf '## Sibling Runbooks Owning Their Own Restore\n\n'
  printf -- '- IntelliJ IDEA — [[restore-intellij|restore-intellij.md]] (`bin/restore-intellij.sh`).\n'
  printf -- '- Docker Desktop and local containers — [[restore-docker|restore-docker.md]] (`bin/restore-docker.sh`).\n'
  printf -- '- Repository re-clone and staged ignored files — [[restore-repos|restore-repos.md]] (Phase 11B).\n'
  printf -- '- Late selective local-file restore — [[restore-home|restore-home.md]] (Phase 15).\n'
  printf '\n'

  printf '## Suggested Restore Order\n\n'
  printf '1. Let the managed channel install Office and Teams. Record versions.\n'
  printf '2. Restore Chrome default browser, sync, and extensions.\n'
  printf '3. Install Obsidian and open `reference-vault`.\n'
  printf '4. Import Postman collections, then environments.\n'
  printf '5. Restore VS Code settings and extensions after diffing against the backup.\n'
  printf '6. Install Raycast and recreate the priority Quicklinks.\n'
  printf '7. Restore IntelliJ via `bin/restore-intellij.sh` and `restore-intellij.md`.\n'
  printf '8. Restore Docker Desktop via `bin/restore-docker.sh` and `restore-docker.md`.\n'
  printf '9. Install the remaining daily apps intentionally.\n'
  printf '10. Restore the exported Terminal.app profile if one is present.\n'
  printf '11. Install Oracle SQL Developer only if still approved and needed.\n'
  printf '12. Rerun the post-image Office stability baseline and update capture-office-stability.md.\n'
  printf '13. Close the Phase 12 sign-off table in restore-apps.md before continuing to Phase 13.\n'
  printf '\n'

  printf '## Sign-Off Checklist\n\n'
  printf 'The rows a person answers live in their own file, so regenerating\n'
  printf 'this plan never discards an answer:\n\n'
  printf '    %s\n\n' "$SIGNOFF_FILE"
  printf 'Answers carry forward between runs and each row records the run it\n'
  printf 'was answered against. Phase 14 reads that file, not this one.\n'
} > "$PLAN_FILE" || {
  # Without -e a failed redirect would still fall through to the success line
  # below, and Phase 14 reads the newest plan-note — a phantom hand-off.
  echo "ERROR: could not write the plan-note: $PLAN_FILE" >&2
  exit 1
}

echo "Plan-note → $PLAN_FILE"

# Row text is the key that carries an answer between runs, so rewording one
# orphans its answer. sign-offs.sh reports that rather than dropping it, but
# treat these strings as identifiers, not as prose.
signoff_row 'Office installed from approved channel' ''
signoff_row 'Outlook / OneNote / Teams versions recorded' ''
signoff_row 'OneDrive signed in and sync settled' ''
signoff_row 'Chrome default browser set and profile restored' ''
signoff_row 'Obsidian installed and `reference-vault` opened' ''
signoff_row 'Postman collections and environments imported securely' ''
signoff_row 'VS Code installed with extensions restored' ''
signoff_row 'Raycast installed and Quicklinks recreated' ''
signoff_row 'IntelliJ dedicated restore completed' ''
signoff_row 'Docker dedicated restore completed' ''
signoff_row 'Terminal profile restored (if exported)' ''
signoff_row 'Oracle SQL Developer decision recorded' ''
signoff_row 'Post-image Office stability baseline captured' ''

signoff_finalize "Phase 12" "$PLAN_FILE"

if [[ "$OPEN_RESULT" == true ]]; then
  open -R "$PLAN_FILE" 2>/dev/null || true
fi
