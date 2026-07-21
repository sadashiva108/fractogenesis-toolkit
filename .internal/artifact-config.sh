#!/usr/bin/env bash
# =============================================================================
# artifact-config.sh
#
# Source-only foundation config for the Mac reimage workflow. It loads local,
# resolved values from reimage.env, applies shared defaults, selects the active
# artifact-config fragment directory, sources the required fragments, and
# exposes the shared variables, arrays, and helper functions used by workflow
# entrypoints and internal helpers.
#
# This file is normally sourced through .internal/load-reimage-config.sh. It is
# not a standalone command and does not parse command-line arguments, perform
# workflow work, or change shell options in the caller.
#
# --- BEGIN USAGE ---
# Usage:
#   # Preferred: source the shared loader from an entrypoint or helper.
#   source "$REPO_ROOT/.internal/load-reimage-config.sh"
#
#   # Direct sourcing is supported for foundation/bootstrap code that needs the
#   # artifact config without the wrapper loader.
#   source "/path/to/repo/.internal/artifact-config.sh"
#
# Optional caller controls set before sourcing:
#   REIMAGE_ENV
#       Override the local environment file.
#       Default: <repo-root>/reimage.env
#
#   ARTIFACT_CONFIG_DIR
#       Override the directory containing reusable *.conf.sh fragments.
#
#   ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT
#       Set to true to fail config loading when REIMAGE_ARTIFACT_ROOT is empty.
#       Default: false.
#
# Configuration precedence:
#   1. Values already present in the caller environment.
#   2. Values loaded from reimage.env.
#   3. Defaults defined by this file.
#
# Artifact-config fragment precedence:
#   1. Caller- or reimage.env-provided ARTIFACT_CONFIG_DIR.
#   2. $REIMAGE_WORKSPACE_ROOT/artifact-config when that directory exists.
#   3. Committed templates under .internal/templates/artifact-config.
#
# Public outputs include:
#   REIMAGE_ENV
#   REIMAGE_WORKSPACE_ROOT
#   EXTERNAL_DATA_VOLUME
#   EXTERNAL_APPLE_BACKUPS_VOLUME
#   REIMAGE_ARTIFACT_ROOT
#   OFFICE_WATCH
#   ONEDRIVE_*
#   ARTIFACT_CONFIG_*
#   MANUAL_POSTMAN_STAGE
#   MANUAL_RAYCAST_STAGE
#   Arrays and values declared by the required config fragments
#   config_field
#
# Source contract:
#   - Direct execution is rejected.
#   - .envrc is never sourced.
#   - The caller's set -e, set -u, and pipefail state is not changed.
#   - Generic caller variables such as SCRIPT_DIR and REPO_ROOT are not used or
#     overwritten internally.
#   - Private implementation variables and functions are removed before return.
#
# Return status when sourced:
#   0  Configuration loaded successfully.
#   2  A required path, value, environment file, or config fragment failed.
# --- END USAGE ---
# =============================================================================

# Do not use `set -euo pipefail` here. This file is sourced and must not alter
# shell options in the caller.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "ERROR: artifact-config.sh must be sourced, not executed." >&2
  echo "Use: source /path/to/.internal/artifact-config.sh" >&2
  exit 2
fi

_artifact_config_main() {
  local config_dir
  local config_path
  local fragment
  local preset_artifact_config_dir
  local preset_external_apple_backups_volume
  local preset_external_data_volume
  local preset_office_watch
  local preset_onedrive_cloud_storage_root
  local preset_onedrive_dest_subdir
  local preset_onedrive_folder_name
  local preset_onedrive_preferred_root
  local preset_onedrive_root
  local preset_reimage_artifact_root
  local preset_reimage_env
  local preset_reimage_workspace_root
  local preset_require_reimage_artifact_root
  local resolved_reimage_env
  local this_dir
  local repo_root
  local -a required_fragments

  this_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || {
    echo "ERROR: unable to resolve artifact-config.sh directory." >&2
    return 2
  }
  repo_root="$(cd "$this_dir/.." && pwd)" || {
    echo "ERROR: unable to resolve repository root from: $this_dir" >&2
    return 2
  }

  # Preserve non-empty caller values before sourcing reimage.env. This retains
  # the existing precedence contract: caller environment, then reimage.env,
  # then defaults below.
  preset_reimage_env="${REIMAGE_ENV:-}"
  preset_require_reimage_artifact_root="${ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT:-}"
  preset_reimage_workspace_root="${REIMAGE_WORKSPACE_ROOT:-}"
  preset_external_data_volume="${EXTERNAL_DATA_VOLUME:-}"
  preset_external_apple_backups_volume="${EXTERNAL_APPLE_BACKUPS_VOLUME:-}"
  preset_reimage_artifact_root="${REIMAGE_ARTIFACT_ROOT:-}"
  preset_office_watch="${OFFICE_WATCH:-}"
  preset_onedrive_cloud_storage_root="${ONEDRIVE_CLOUD_STORAGE_ROOT:-}"
  preset_onedrive_folder_name="${ONEDRIVE_FOLDER_NAME:-}"
  preset_onedrive_preferred_root="${ONEDRIVE_PREFERRED_ROOT:-}"
  preset_onedrive_root="${ONEDRIVE_ROOT:-}"
  preset_onedrive_dest_subdir="${ONEDRIVE_DEST_SUBDIR:-}"
  preset_artifact_config_dir="${ARTIFACT_CONFIG_DIR:-}"

  resolved_reimage_env="${preset_reimage_env:-$repo_root/reimage.env}"
  REIMAGE_ENV="$resolved_reimage_env"

  if [[ -e "$resolved_reimage_env" && ! -f "$resolved_reimage_env" ]]; then
    echo "ERROR: REIMAGE_ENV is not a regular file: $resolved_reimage_env" >&2
    return 2
  fi

  if [[ -f "$resolved_reimage_env" ]]; then
    # shellcheck disable=SC1090
    if ! source "$resolved_reimage_env"; then
      echo "ERROR: failed to source REIMAGE_ENV: $resolved_reimage_env" >&2
      return 2
    fi
  fi

  # Keep the effective source path stable even if reimage.env contains a stale
  # REIMAGE_ENV assignment. Apply the normal caller > reimage.env > default
  # precedence to the required-artifact-root control.
  REIMAGE_ENV="$resolved_reimage_env"
  ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT="${preset_require_reimage_artifact_root:-${ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT:-false}}"

  REIMAGE_WORKSPACE_ROOT="${preset_reimage_workspace_root:-${REIMAGE_WORKSPACE_ROOT:-}}"
  EXTERNAL_DATA_VOLUME="${preset_external_data_volume:-${EXTERNAL_DATA_VOLUME:-/Volumes/Data}}"
  EXTERNAL_APPLE_BACKUPS_VOLUME="${preset_external_apple_backups_volume:-${EXTERNAL_APPLE_BACKUPS_VOLUME:-/Volumes/AppleBackups}}"
  REIMAGE_ARTIFACT_ROOT="${preset_reimage_artifact_root:-${REIMAGE_ARTIFACT_ROOT:-}}"

  # OFFICE_WATCH is optional. A blank value in reimage.env remains blank rather
  # than silently selecting a machine-specific Desktop path.
  OFFICE_WATCH="${preset_office_watch:-${OFFICE_WATCH:-}}"

  if [[ -z "$REIMAGE_ARTIFACT_ROOT" && "$ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT" == "true" ]]; then
    echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set. Create/source reimage.env or provide an explicit override." >&2
    return 2
  fi

  # Retained for compatibility with older callers, but derive it from the
  # configured external volume instead of hardcoding a separate volume name.
  DEFAULT_DRIVE_NAME="$(basename "${EXTERNAL_DATA_VOLUME%/}")"

  ONEDRIVE_CLOUD_STORAGE_ROOT="${preset_onedrive_cloud_storage_root:-${ONEDRIVE_CLOUD_STORAGE_ROOT:-$HOME/Library/CloudStorage}}"
  ONEDRIVE_FOLDER_NAME="${preset_onedrive_folder_name:-${ONEDRIVE_FOLDER_NAME:-}}"

  if [[ -n "$preset_onedrive_preferred_root" ]]; then
    ONEDRIVE_PREFERRED_ROOT="$preset_onedrive_preferred_root"
  elif [[ -n "${ONEDRIVE_PREFERRED_ROOT:-}" ]]; then
    ONEDRIVE_PREFERRED_ROOT="$ONEDRIVE_PREFERRED_ROOT"
  elif [[ -n "$ONEDRIVE_FOLDER_NAME" ]]; then
    ONEDRIVE_PREFERRED_ROOT="$ONEDRIVE_CLOUD_STORAGE_ROOT/$ONEDRIVE_FOLDER_NAME"
  else
    ONEDRIVE_PREFERRED_ROOT=""
  fi

  if [[ -n "$preset_onedrive_root" ]]; then
    ONEDRIVE_ROOT="$preset_onedrive_root"
  elif [[ -n "${ONEDRIVE_ROOT:-}" ]]; then
    ONEDRIVE_ROOT="$ONEDRIVE_ROOT"
  elif [[ -n "$ONEDRIVE_FOLDER_NAME" ]]; then
    ONEDRIVE_ROOT="$ONEDRIVE_CLOUD_STORAGE_ROOT/$ONEDRIVE_FOLDER_NAME"
  else
    ONEDRIVE_ROOT=""
  fi

  if [[ -n "$preset_onedrive_dest_subdir" ]]; then
    ONEDRIVE_DEST_SUBDIR="$preset_onedrive_dest_subdir"
  elif [[ -n "${ONEDRIVE_DEST_SUBDIR:-}" ]]; then
    ONEDRIVE_DEST_SUBDIR="$ONEDRIVE_DEST_SUBDIR"
  elif [[ -n "$REIMAGE_ARTIFACT_ROOT" ]]; then
    ONEDRIVE_DEST_SUBDIR="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"
  else
    ONEDRIVE_DEST_SUBDIR=""
  fi

  MANUAL_POSTMAN_STAGE="${REIMAGE_ARTIFACT_ROOT:+$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/}"
  MANUAL_RAYCAST_STAGE="${REIMAGE_ARTIFACT_ROOT:+$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/}"

  ARTIFACT_CONFIG_TEMPLATE_DIR="$this_dir/templates/artifact-config"
  ARTIFACT_CONFIG_WORKSPACE_DIR="${REIMAGE_WORKSPACE_ROOT:+$REIMAGE_WORKSPACE_ROOT/artifact-config}"

  if [[ -n "$preset_artifact_config_dir" ]]; then
    config_dir="$preset_artifact_config_dir"
  elif [[ -n "${ARTIFACT_CONFIG_DIR:-}" ]]; then
    config_dir="$ARTIFACT_CONFIG_DIR"
  elif [[ -n "$ARTIFACT_CONFIG_WORKSPACE_DIR" && -d "$ARTIFACT_CONFIG_WORKSPACE_DIR" ]]; then
    config_dir="$ARTIFACT_CONFIG_WORKSPACE_DIR"
  else
    config_dir="$ARTIFACT_CONFIG_TEMPLATE_DIR"
  fi

  ARTIFACT_CONFIG_DIR="$config_dir"
  ARTIFACT_CONFIG_SOURCE_DIR="$config_dir"

  if [[ ! -d "$ARTIFACT_CONFIG_SOURCE_DIR" ]]; then
    echo "ERROR: artifact-config directory not found: $ARTIFACT_CONFIG_SOURCE_DIR" >&2
    return 2
  fi

  required_fragments=(
    external-targets.conf.sh
    external-dotfiles.conf.sh
    secrets-targets.conf.sh
    secret-flags.conf.sh
    external-excludes.conf.sh
    onedrive-targets.conf.sh
    onedrive-extra-excludes.conf.sh
    skip-entries.conf.sh
    expected-artifact-folders.conf.sh
  )

  # Preflight the complete fragment set before sourcing any fragment so a
  # missing file cannot leave the caller with only a partially loaded array set.
  for fragment in "${required_fragments[@]}"; do
    config_path="$ARTIFACT_CONFIG_SOURCE_DIR/$fragment"
    if [[ ! -f "$config_path" ]]; then
      echo "ERROR: required artifact-config fragment not found: $config_path" >&2
      return 2
    fi
  done

  for fragment in "${required_fragments[@]}"; do
    config_path="$ARTIFACT_CONFIG_SOURCE_DIR/$fragment"
    # shellcheck disable=SC1090
    if ! source "$config_path"; then
      echo "ERROR: failed to source artifact-config fragment: $config_path" >&2
      return 2
    fi
  done

  return 0
}

# Public helper: parse a pipe-delimited config entry by 1-based field index and
# trim only leading/trailing whitespace from the selected field.
# Usage: config_field "entry string" 2
config_field() {
  local entry="$1"
  local index="$2"

  case "$index" in
    ''|0|*[!0-9]*)
      echo "ERROR: config_field index must be a positive integer: ${index:-<empty>}" >&2
      return 2
      ;;
  esac

  printf '%s\n' "$entry" \
    | awk -F'|' -v field_index="$index" '
        {
          value = $field_index
          sub(/^[[:space:]]+/, "", value)
          sub(/[[:space:]]+$/, "", value)
          print value
          exit
        }
      '
}

_artifact_config_finish() {
  local status="$1"
  unset -f _artifact_config_main _artifact_config_finish
  return "$status"
}

if _artifact_config_main; then
  _artifact_config_finish 0
else
  _artifact_config_finish $?
fi
