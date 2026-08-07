#!/usr/bin/env bash
# =============================================================================
# restore-apps.sh
#
# Phase 10 — Restore Apps umbrella plan-note emitter.
#
# Surveys the pre-image app-settings backups and encrypted-secrets sources that
# feed the Phase 10 restore steps, records which ones are present versus
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
#
# Exit status:
#   0  Plan-note written; no fatal errors.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

# Aggregate validator: individual source lookups become PRESENT/MISSING rows
# in the plan-note rather than aborting the run. Keep -u and pipefail on.
set -uo pipefail

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

# Phase 10 uses the artifact drive when it is mounted, and falls back to the
# workspace root or ~/Desktop only when the operator has explicitly overridden
# --output-root. Load shared config in the default (non-strict) mode so an
# unresolved REIMAGE_ARTIFACT_ROOT doesn't abort the loader.
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

# ---------------------------------------------------------------------------
# Defaults and command-line parsing
# ---------------------------------------------------------------------------
STAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_ROOT=""
OPEN_RESULT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "ERROR: --artifact-root requires a non-empty value." >&2
        usage >&2
        exit 2
      fi
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --output-root)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "ERROR: --output-root requires a directory." >&2
        usage >&2
        exit 2
      fi
      OUTPUT_ROOT="$2"
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

PLAN_FILE="$OUTPUT_ROOT/restore-apps-plan-$STAMP.md"

# ---------------------------------------------------------------------------
# Source enumeration
# ---------------------------------------------------------------------------
APP_BACKUP_ROOT="$REIMAGE_ARTIFACT_ROOT/app-settings-backup"
SECRETS_ROOT="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"
WORKFLOW_SNAPSHOT_ROOT="$REIMAGE_ARTIFACT_ROOT/workflow-snapshot"

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
# lightweight workflow-snapshot copy only when the dedicated backup is absent.
resolve_vscode_source() {
  local dedicated="$APP_BACKUP_ROOT/vscode"
  if [[ -d "$dedicated" ]]; then
    printf '%s\n' "$dedicated"
    return
  fi
  local latest=""
  latest="$(find "$WORKFLOW_SNAPSHOT_ROOT" -maxdepth 1 -type d -name 'pre-image-workflow-snapshot-*' 2>/dev/null | sort | tail -1)"
  if [[ -n "$latest" && -d "$latest/vscode" ]]; then
    printf '%s\n' "$latest/vscode"
    return
  fi
  printf '%s\n' "$dedicated"
}

VSCODE_SOURCE="$(resolve_vscode_source)"

# ---------------------------------------------------------------------------
# Generate the plan-note
# ---------------------------------------------------------------------------
{
  printf '# Restore Apps Plan — %s\n\n' "$STAMP"
  printf 'Generated by `bin/restore-apps.sh` on %s.\n\n' "$(date)"
  printf 'This plan-note pairs with [[restore-apps|restore-apps.md]] (Phase 10). Work each row by hand; the script does not install apps or import settings.\n\n'

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
  printf -- '- Repository re-clone and staged ignored files — [[restore-repos|restore-repos.md]] (Phase 9B).\n'
  printf -- '- Late selective local-file restore — [[restore-home|restore-home.md]] (Phase 13).\n'
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
  printf '13. Close the Phase 10 sign-off table in restore-apps.md before continuing to Phase 11.\n'
  printf '\n'

  printf '## Sign-Off Checklist\n\n'
  printf '| Item | Status | Notes |\n'
  printf '| --- | --- | --- |\n'
  printf '| Office installed from approved channel | TODO |  |\n'
  printf '| Outlook / OneNote / Teams versions recorded | TODO |  |\n'
  printf '| OneDrive signed in and sync settled | TODO |  |\n'
  printf '| Chrome default browser set and profile restored | TODO |  |\n'
  printf '| Obsidian installed and `reference-vault` opened | TODO |  |\n'
  printf '| Postman collections and environments imported securely | TODO |  |\n'
  printf '| VS Code installed with extensions restored | TODO |  |\n'
  printf '| Raycast installed and Quicklinks recreated | TODO |  |\n'
  printf '| IntelliJ dedicated restore completed | TODO |  |\n'
  printf '| Docker dedicated restore completed | TODO |  |\n'
  printf '| Terminal profile restored (if exported) | TODO |  |\n'
  printf '| Oracle SQL Developer decision recorded | TODO |  |\n'
  printf '| Post-image Office stability baseline captured | TODO |  |\n'
} > "$PLAN_FILE"

echo "Plan-note → $PLAN_FILE"

if [[ "$OPEN_RESULT" == true ]]; then
  open -R "$PLAN_FILE" 2>/dev/null || true
fi
