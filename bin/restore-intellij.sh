#!/usr/bin/env bash
# =============================================================================
# restore-intellij.sh
#
# Phase 12 — Restore IntelliJ IDE state plan-note emitter.
#
# Surveys the pre-image IntelliJ artifacts captured by Phase 2C (backup-apps
# and its intellij subflow) plus the encrypted-secrets sources that hold the
# HTTP Client environment files, and writes a per-run plan-note under the
# reimaged system's restore-notes/ area. The operator uses the plan-note as
# a working checklist while following restore-intellij.md; the script itself
# installs nothing, copies no settings, and touches no secrets.
#
# This is an aggregate validator. Individual source lookups may report MISSING
# without aborting the run so the operator can see the full inventory at a
# glance before deciding whether to re-mount the artifact volume, re-run an
# earlier backup, or continue with a partial restore.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/restore-intellij.sh
#
#   # Default -- generate an IntelliJ restore plan-note under
#   # $REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/.
#   ./bin/restore-intellij.sh
#
#   # Override the artifact root for this invocation.
#   ./bin/restore-intellij.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Write the plan-note under a specific directory instead of the default.
#   ./bin/restore-intellij.sh --output-root ~/Desktop/reimaged-system-artifacts/restore-notes
#
#   # Reveal the generated plan-note in Finder after completion.
#   ./bin/restore-intellij.sh --open
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
#   $REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-intellij-plan-YYYYMMDD-HHMMSS.md
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

PLAN_FILE="$OUTPUT_ROOT/restore-intellij-plan-$STAMP.md"

# ---------------------------------------------------------------------------
# Source enumeration
# ---------------------------------------------------------------------------
INTELLIJ_ROOT="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij"
INTELLIJ_SECRETS_ROOT="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/intellij"
SECRETS_DMG_GLOB="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-*.dmg"

status_row() {
  local label="$1"
  local path="$2"
  if [[ -e "$path" ]]; then
    printf '| %s | `%s` | PRESENT |\n' "$label" "$path"
  else
    printf '| %s | `%s` | MISSING |\n' "$label" "$path"
  fi
}

# Discover per-version subtrees (IntelliJIdea20YY.N/) so the plan-note lists
# which versions actually have backup material.
list_intellij_versions() {
  if [[ ! -d "$INTELLIJ_ROOT" ]]; then
    return 0
  fi
  find "$INTELLIJ_ROOT" -maxdepth 1 -type d -name 'IntelliJIdea*' 2>/dev/null \
    | sort
}

# Find the most recent manual settings ZIP so the operator can point Import
# Settings straight at it.
latest_settings_zip() {
  local dir="$INTELLIJ_ROOT/manual-settings-export"
  if [[ ! -d "$dir" ]]; then
    return 0
  fi
  find "$dir" -maxdepth 1 -type f -name 'IntelliJ-settings-*.zip' 2>/dev/null \
    | sort | tail -1
}

# Find the most recent consolidated encrypted DMG.
latest_secrets_dmg() {
  # shellcheck disable=SC2086
  ls -1 $SECRETS_DMG_GLOB 2>/dev/null | sort | tail -1
}

SETTINGS_ZIP="$(latest_settings_zip)"
SECRETS_DMG="$(latest_secrets_dmg)"

# ---------------------------------------------------------------------------
# Generate the plan-note
# ---------------------------------------------------------------------------
{
  printf '# Restore IntelliJ Plan — %s\n\n' "$STAMP"
  printf 'Generated by `bin/restore-intellij.sh` on %s.\n\n' "$(date)"
  printf 'This plan-note pairs with [[restore-intellij|restore-intellij.md]] (Phase 12). Work each row by hand; the script does not install IntelliJ, copy settings, or unlock encrypted secret material.\n\n'

  printf '## Backup Sources\n\n'
  printf '| Area | Path | Status |\n'
  printf '| --- | --- | --- |\n'
  status_row "IntelliJ backup root"      "$INTELLIJ_ROOT"
  status_row "Manual settings ZIP dir"   "$INTELLIJ_ROOT/manual-settings-export"
  status_row "Project metadata bundle"   "$INTELLIJ_ROOT/project-metadata"
  status_row "Restore-notes directory"   "$INTELLIJ_ROOT/restore-notes"
  status_row "IntelliJ logs snapshot"    "$INTELLIJ_ROOT/logs"
  printf '\n'

  printf '### Detected IntelliJ Version Subtrees\n\n'
  VERSIONS="$(list_intellij_versions)"
  if [[ -z "$VERSIONS" ]]; then
    printf 'No `IntelliJIdea*/` subdirectories found under `%s`.\n\n' "$INTELLIJ_ROOT"
  else
    printf '| Version subtree | config-copy | scratches-and-consoles | manifests |\n'
    printf '| --- | --- | --- | --- |\n'
    while IFS= read -r vdir; do
      [[ -z "$vdir" ]] && continue
      vname="$(basename "$vdir")"
      cfg="MISSING"
      sc="MISSING"
      mf="MISSING"
      [[ -d "$vdir/config-copy" ]] && cfg="PRESENT"
      [[ -d "$vdir/scratches-and-consoles" ]] && sc="PRESENT"
      [[ -d "$vdir/manifests" ]] && mf="PRESENT"
      printf '| `%s` | %s | %s | %s |\n' "$vname" "$cfg" "$sc" "$mf"
    done <<< "$VERSIONS"
    printf '\n'
  fi

  printf '### Most Recent Manual Settings Export\n\n'
  if [[ -n "$SETTINGS_ZIP" ]]; then
    printf 'Import target for `File → Manage IDE Settings → Import Settings`:\n\n'
    printf '```text\n%s\n```\n\n' "$SETTINGS_ZIP"
  else
    printf 'No `IntelliJ-settings-*.zip` found under `%s/manual-settings-export/`. Fall back to per-file restore from `config-copy/` if needed.\n\n' "$INTELLIJ_ROOT"
  fi

  printf '## Secret-Bearing Sources (mount the encrypted DMG before use)\n\n'
  printf '| Area | Path | Status |\n'
  printf '| --- | --- | --- |\n'
  status_row "IntelliJ HTTP Client secrets" "$INTELLIJ_SECRETS_ROOT"
  if [[ -n "$SECRETS_DMG" ]]; then
    status_row "Consolidated secrets DMG (latest)" "$SECRETS_DMG"
  else
    printf '| Consolidated secrets DMG (latest) | `%s` | MISSING |\n' "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-*.dmg"
  fi
  printf '\n'

  printf '## Suggested Restore Order\n\n'
  printf '1. Install IntelliJ IDEA from the approved source (JetBrains Toolbox or direct).\n'
  printf '2. Launch IntelliJ once so it creates its Application Support paths, then quit.\n'
  printf '3. Import the manual settings ZIP: `File → Manage IDE Settings → Import Settings`.\n'
  printf '4. Restore Scratches and Consoles from the matching version subtree above.\n'
  printf '5. Restore selected project `.idea` metadata per repo (runConfigurations, codeStyles, inspectionProfiles).\n'
  printf '6. Restore HTTP Client `*.http` request files (non-secret) directly from `project-metadata/`.\n'
  printf '7. Mount the encrypted secrets DMG, copy HTTP Client `.env.json` files into the correct project, then eject.\n'
  printf '8. Validate Project SDK, Gradle JVM, run configs, HTTP Client environments, and tests per key project.\n'
  printf '\n'

  printf '## Sign-Off Checklist\n\n'
  printf '| Item | Status | Notes |\n'
  printf '| --- | --- | --- |\n'
  printf '| IntelliJ installed | TODO |  |\n'
  printf '| Install source recorded (Toolbox / direct / version) | TODO |  |\n'
  printf '| First launch completed and quit | TODO |  |\n'
  printf '| Settings ZIP imported | TODO |  |\n'
  printf '| Scratches and Consoles restored | TODO |  |\n'
  printf '| Project SDK configured on key projects | TODO |  |\n'
  printf '| Gradle JVM configured on key projects | TODO |  |\n'
  printf '| Run configurations present | TODO |  |\n'
  printf '| Plugins reinstalled or confirmed | TODO |  |\n'
  printf '| HTTP Client env files restored from encrypted source only | TODO |  |\n'
  printf '| Key projects open cleanly and tests build | TODO |  |\n'
  printf '| No secrets committed accidentally (`git status --ignored -s` clean) | TODO |  |\n'
} > "$PLAN_FILE"

echo "Plan-note → $PLAN_FILE"

if [[ "$OPEN_RESULT" == true ]]; then
  open -R "$PLAN_FILE" 2>/dev/null || true
fi
