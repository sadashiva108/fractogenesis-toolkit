#!/usr/bin/env bash
# =============================================================================
# restore-docker.sh
#
# Phase 10 — Restore Docker Desktop and local containers plan-note emitter.
#
# Surveys the pre-image Docker artifacts captured by Phase 2C (backup-apps
# docker subflow) plus the encrypted-secrets Docker config that holds registry
# credentials, checks whether Docker Desktop is installed and whether the
# daemon is currently reachable on the reimaged Mac, and writes a per-run
# plan-note under the reimaged system's restore-notes/ area.
#
# This is an aggregate validator. Individual source lookups may report MISSING
# or Docker daemon checks may fail without aborting the run so the operator
# sees the full inventory at a glance and can decide whether to launch Docker
# Desktop, remount the artifact volume, or continue.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/restore-docker.sh
#
#   # Default -- generate a Docker restore plan-note under
#   # $REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/.
#   ./bin/restore-docker.sh
#
#   # Override the artifact root for this invocation.
#   ./bin/restore-docker.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Write the plan-note under a specific directory instead of the default.
#   ./bin/restore-docker.sh --output-root ~/Desktop/reimaged-system-artifacts/restore-notes
#
#   # Reveal the generated plan-note in Finder after completion.
#   ./bin/restore-docker.sh --open
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
#   $REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-docker-plan-YYYYMMDD-HHMMSS.md
#
# Exit status:
#   0  Plan-note written; no fatal errors.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

# Aggregate validator: individual source lookups become PRESENT/MISSING rows
# and the daemon check becomes a REACHABLE/UNREACHABLE row rather than
# aborting the run. Keep -u and pipefail on.
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

PLAN_FILE="$OUTPUT_ROOT/restore-docker-plan-$STAMP.md"

# ---------------------------------------------------------------------------
# Source enumeration
# ---------------------------------------------------------------------------
DOCKER_BACKUP_ROOT="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker"
DOCKER_SECRETS_ROOT="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker"

status_row() {
  local label="$1"
  local path="$2"
  if [[ -e "$path" ]]; then
    printf '| %s | `%s` | PRESENT |\n' "$label" "$path"
  else
    printf '| %s | `%s` | MISSING |\n' "$label" "$path"
  fi
}

docker_desktop_status() {
  if [[ -d "/Applications/Docker.app" ]]; then
    printf 'INSTALLED'
  else
    printf 'MISSING'
  fi
}

docker_daemon_status() {
  if ! command -v docker >/dev/null 2>&1; then
    printf 'CLI-MISSING'
    return
  fi
  if docker info >/dev/null 2>&1; then
    printf 'REACHABLE'
  else
    printf 'UNREACHABLE'
  fi
}

DESKTOP="$(docker_desktop_status)"
DAEMON="$(docker_daemon_status)"

# ---------------------------------------------------------------------------
# Generate the plan-note
# ---------------------------------------------------------------------------
{
  printf '# Restore Docker Plan — %s\n\n' "$STAMP"
  printf 'Generated by `bin/restore-docker.sh` on %s.\n\n' "$(date)"
  printf 'This plan-note pairs with [[restore-docker|restore-docker.md]] (Phase 10). Work each row by hand; the script does not install Docker Desktop, start containers, or import credentials.\n\n'

  printf '## Local Docker State\n\n'
  printf '| Item | Status |\n'
  printf '| --- | --- |\n'
  printf '| Docker Desktop app | %s |\n' "$DESKTOP"
  printf '| Docker daemon reachable | %s |\n' "$DAEMON"
  printf '\n'

  printf '## Backup Sources\n\n'
  printf '| Area | Path | Status |\n'
  printf '| --- | --- | --- |\n'
  status_row "Docker backup root"     "$DOCKER_BACKUP_ROOT"
  status_row "settings-store.json"    "$DOCKER_BACKUP_ROOT/settings-store.json"
  status_row "daemon.json"            "$DOCKER_BACKUP_ROOT/daemon.json"
  status_row "contexts/"              "$DOCKER_BACKUP_ROOT/contexts"
  status_row "image-inventory.txt"    "$DOCKER_BACKUP_ROOT/image-inventory.txt"
  status_row "container-inventory.txt" "$DOCKER_BACKUP_ROOT/container-inventory.txt"
  status_row "compose-projects.txt"   "$DOCKER_BACKUP_ROOT/compose-projects.txt"
  printf '\n'

  printf '## Secret-Bearing Sources (mount the encrypted DMG before use)\n\n'
  printf '| Area | Path | Status |\n'
  printf '| --- | --- | --- |\n'
  status_row "Docker registry config (config.json)" "$DOCKER_SECRETS_ROOT/config.json"
  printf '\n'

  printf '## Suggested Restore Order\n\n'
  printf '1. Install Docker Desktop from the approved source (Self Service / Company Portal if available, else docker.com).\n'
  printf '2. Complete Docker Desktop onboarding and confirm the daemon starts.\n'
  printf '3. Apply Resources settings (CPUs, Memory, Swap, Disk image size, File sharing) from the pre-image performance-audit notes.\n'
  printf '4. Validate the Docker CLI (`docker version`, `docker info`, `docker system df`).\n'
  printf '5. Restore `~/.docker/config.json` from the encrypted secrets area, then `docker login` per registry as needed.\n'
  printf '6. Restart each low-touch container (Redis, RabbitMQ) using the recipes in restore-docker.md.\n'
  printf '7. Restart Elasticsearch (and Kibana if used) from the project docker-compose.yml.\n'
  printf '8. Restart MarkLogic from docker-compose.marklogic.yml and run the sanity-check script before Gradle deploys.\n'
  printf '9. Run project Gradle deploys (mlDeploySecurity, mlDeploy, mlLoadModules) as needed.\n'
  printf '10. Confirm image and container inventories match the pre-image record (spot-check).\n'
  printf '\n'

  printf '## Sign-Off Checklist\n\n'
  printf '| Item | Status | Notes |\n'
  printf '| --- | --- | --- |\n'
  printf '| Docker Desktop installed | TODO |  |\n'
  printf '| Docker daemon reachable (`docker info`) | TODO |  |\n'
  printf '| Resources settings (CPU/Memory/Swap/Disk) restored | TODO |  |\n'
  printf '| File sharing includes project roots | TODO |  |\n'
  printf '| `~/.docker/config.json` restored and `docker login` verified per registry | TODO |  |\n'
  printf '| Redis container running | TODO |  |\n'
  printf '| RabbitMQ container running (management UI reachable) | TODO |  |\n'
  printf '| Elasticsearch reachable on `:9200` | TODO |  |\n'
  printf '| Kibana reachable on `:5601` (if used) | TODO |  |\n'
  printf '| MarkLogic single-node running (`:7997` health `200`) | TODO |  |\n'
  printf '| MarkLogic security deployed (`mlDeploySecurity`) | TODO |  |\n'
  printf '| MarkLogic app deployed (`mlDeploy`) | TODO |  |\n'
  printf '| Image / container inventory spot-check vs pre-image | TODO |  |\n'
} > "$PLAN_FILE"

echo "Plan-note → $PLAN_FILE"

if [[ "$OPEN_RESULT" == true ]]; then
  open -R "$PLAN_FILE" 2>/dev/null || true
fi
