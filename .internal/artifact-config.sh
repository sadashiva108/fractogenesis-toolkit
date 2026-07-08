#!/usr/bin/env bash
# artifact-config.sh
# Single source of truth for backup target loading, excludes, metadata, and shared
# reimage path defaults.
# Sourced by reimage helper scripts. Never run directly.
#
# To customize: edit the reusable config fragments copied into
# $REIMAGE_WORKSPACE_ROOT/artifact-config/ when they exist. If no workspace copy is
# present yet, this loader falls back to the templates under .internal/templates/.
# The other scripts read this file and need no changes.

# ══════════════════════════════════════════════════════════════════════════════
#  DESTINATIONS
# ══════════════════════════════════════════════════════════════════════════════
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# This file lives at <repo>/.internal/artifact-config.sh, so the repo root is
# one level up. Self-located directly — REIMAGE_ROOT was retired as an
# externally-overridable variable, matching prepare-artifact-root.py's
# REPO_ROOT self-location pattern.
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REIMAGE_ENV="${REIMAGE_ENV:-$REPO_ROOT/reimage.env}"
# Default to permissive loading so scripts can source config first, then apply
# command-line overrides such as --artifact-root later in their own parsing.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT="${ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT:-false}"

# Preserve values already supplied by the caller. This lets scripts pass an
# explicit --artifact-root or exported override before sourcing this shared config,
# while still allowing reimage.env to provide the normal local defaults.
PRESET_REIMAGE_WORKSPACE_ROOT="${REIMAGE_WORKSPACE_ROOT:-}"
PRESET_EXTERNAL_DATA_VOLUME="${EXTERNAL_DATA_VOLUME:-}"
PRESET_EXTERNAL_APPLE_BACKUPS_VOLUME="${EXTERNAL_APPLE_BACKUPS_VOLUME:-}"
PRESET_REIMAGE_ARTIFACT_ROOT="${REIMAGE_ARTIFACT_ROOT:-}"
PRESET_OFFICE_WATCH="${OFFICE_WATCH:-}"
PRESET_ONEDRIVE_CLOUD_STORAGE_ROOT="${ONEDRIVE_CLOUD_STORAGE_ROOT:-}"
PRESET_ONEDRIVE_FOLDER_NAME="${ONEDRIVE_FOLDER_NAME:-}"
PRESET_ONEDRIVE_PREFERRED_ROOT="${ONEDRIVE_PREFERRED_ROOT:-}"
PRESET_ONEDRIVE_ROOT="${ONEDRIVE_ROOT:-}"
PRESET_ONEDRIVE_DEST_SUBDIR="${ONEDRIVE_DEST_SUBDIR:-}"
PRESET_ARTIFACT_CONFIG_DIR="${ARTIFACT_CONFIG_DIR:-}"




if [[ -f "$REIMAGE_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$REIMAGE_ENV"
fi

REIMAGE_WORKSPACE_ROOT="${PRESET_REIMAGE_WORKSPACE_ROOT:-${REIMAGE_WORKSPACE_ROOT:-}}"
EXTERNAL_DATA_VOLUME="${PRESET_EXTERNAL_DATA_VOLUME:-${EXTERNAL_DATA_VOLUME:-/Volumes/Data}}"
EXTERNAL_APPLE_BACKUPS_VOLUME="${PRESET_EXTERNAL_APPLE_BACKUPS_VOLUME:-${EXTERNAL_APPLE_BACKUPS_VOLUME:-/Volumes/AppleBackups}}"
REIMAGE_ARTIFACT_ROOT="${PRESET_REIMAGE_ARTIFACT_ROOT:-${REIMAGE_ARTIFACT_ROOT:-}}"

# Optional Office stability watcher root.
# Default matches the existing local watcher workflow, but reimage.env or a
# caller-supplied override can still change it.
OFFICE_WATCH="${PRESET_OFFICE_WATCH:-${OFFICE_WATCH:-$HOME/Desktop/ms-office-stability-watch}}"

if [[ -z "$REIMAGE_ARTIFACT_ROOT" && "$ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT" == "true" ]]; then
  echo "REIMAGE_ARTIFACT_ROOT is not set. Create/source reimage.env or pass an explicit output path." >&2
  exit 2
fi

DEFAULT_DRIVE_NAME="Data"

# OneDrive root handling.
#
# Keep OneDrive machine-specific values out of shared scripts. Configure one of
# these in reimage.env when OneDrive backup/sync is used:
#   ONEDRIVE_ROOT=/full/path/to/the/local/OneDrive/folder
#   ONEDRIVE_FOLDER_NAME=<OneDrive-folder-name-under-CloudStorage>
#
# A bare folder name is resolved under ONEDRIVE_CLOUD_STORAGE_ROOT and is never
# used as a relative path under REPO_ROOT.
ONEDRIVE_CLOUD_STORAGE_ROOT="${PRESET_ONEDRIVE_CLOUD_STORAGE_ROOT:-${ONEDRIVE_CLOUD_STORAGE_ROOT:-$HOME/Library/CloudStorage}}"
ONEDRIVE_FOLDER_NAME="${PRESET_ONEDRIVE_FOLDER_NAME:-${ONEDRIVE_FOLDER_NAME:-}}"

if [[ -n "${PRESET_ONEDRIVE_PREFERRED_ROOT:-}" ]]; then
  ONEDRIVE_PREFERRED_ROOT="$PRESET_ONEDRIVE_PREFERRED_ROOT"
elif [[ -n "${ONEDRIVE_PREFERRED_ROOT:-}" ]]; then
  ONEDRIVE_PREFERRED_ROOT="$ONEDRIVE_PREFERRED_ROOT"
elif [[ -n "$ONEDRIVE_FOLDER_NAME" ]]; then
  ONEDRIVE_PREFERRED_ROOT="$ONEDRIVE_CLOUD_STORAGE_ROOT/$ONEDRIVE_FOLDER_NAME"
else
  ONEDRIVE_PREFERRED_ROOT=""
fi

if [[ -n "${PRESET_ONEDRIVE_ROOT:-}" ]]; then
  ONEDRIVE_ROOT="$PRESET_ONEDRIVE_ROOT"
elif [[ -n "${ONEDRIVE_ROOT:-}" ]]; then
  ONEDRIVE_ROOT="$ONEDRIVE_ROOT"
elif [[ -n "$ONEDRIVE_FOLDER_NAME" ]]; then
  ONEDRIVE_ROOT="$ONEDRIVE_CLOUD_STORAGE_ROOT/$ONEDRIVE_FOLDER_NAME"
else
  ONEDRIVE_ROOT=""
fi

# Subdirectory inside OneDrive (avoids cluttering OneDrive root).
# Default to the same directory name as the external backup/capture root so
# the external-drive copy and OneDrive copy are easy to match during restore.
# Override in reimage.env only when you intentionally want a different cloud folder.
if [[ -n "${PRESET_ONEDRIVE_DEST_SUBDIR:-}" ]]; then
  ONEDRIVE_DEST_SUBDIR="$PRESET_ONEDRIVE_DEST_SUBDIR"
elif [[ -n "${ONEDRIVE_DEST_SUBDIR:-}" ]]; then
  ONEDRIVE_DEST_SUBDIR="$ONEDRIVE_DEST_SUBDIR"
elif [[ -n "$REIMAGE_ARTIFACT_ROOT" ]]; then
  ONEDRIVE_DEST_SUBDIR="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"
else
  ONEDRIVE_DEST_SUBDIR=""
fi

# Manual secrets staging folders live under the backup root when one is known.
MANUAL_POSTMAN_STAGE="${REIMAGE_ARTIFACT_ROOT:+$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/}"
MANUAL_RAYCAST_STAGE="${REIMAGE_ARTIFACT_ROOT:+$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/}"

# Reusable config fragment loading.
#
# Shell fragments are used instead of YAML so the existing bash scripts can
# source the arrays directly while still preserving comments and templates.
ARTIFACT_CONFIG_TEMPLATE_DIR="$SCRIPT_DIR/templates/artifact-config"
ARTIFACT_CONFIG_WORKSPACE_DIR="${REIMAGE_WORKSPACE_ROOT:+$REIMAGE_WORKSPACE_ROOT/artifact-config}"

if [[ -n "${PRESET_ARTIFACT_CONFIG_DIR:-}" ]]; then
  ARTIFACT_CONFIG_DIR="$PRESET_ARTIFACT_CONFIG_DIR"
elif [[ -n "${ARTIFACT_CONFIG_DIR:-}" ]]; then
  ARTIFACT_CONFIG_DIR="$ARTIFACT_CONFIG_DIR"
elif [[ -n "$ARTIFACT_CONFIG_WORKSPACE_DIR" && -d "$ARTIFACT_CONFIG_WORKSPACE_DIR" ]]; then
  ARTIFACT_CONFIG_DIR="$ARTIFACT_CONFIG_WORKSPACE_DIR"
else
  ARTIFACT_CONFIG_DIR="$ARTIFACT_CONFIG_TEMPLATE_DIR"
fi

ARTIFACT_CONFIG_SOURCE_DIR="$ARTIFACT_CONFIG_DIR"

source_artifact_config_fragment() {
  local fragment="$1"
  local path="$ARTIFACT_CONFIG_SOURCE_DIR/$fragment"
  if [[ ! -f "$path" ]]; then
    echo "Missing artifact-config fragment: $path" >&2
    exit 2
  fi
  # shellcheck disable=SC1090
  source "$path"
}

for fragment in \
  external-targets.conf.sh \
  external-dotfiles.conf.sh \
  secrets-targets.conf.sh \
  secret-flags.conf.sh \
  external-excludes.conf.sh \
  onedrive-targets.conf.sh \
  onedrive-extra-excludes.conf.sh \
  skip-entries.conf.sh \
  expected-backup-folders.conf.sh
do
  source_artifact_config_fragment "$fragment"
done

# ── End of config ─────────────────────────────────────────────────────────────
# Helper: parse a pipe-delimited config entry by field index (1-based)
# Usage: config_field "entry string" 2
config_field() {
  local entry="$1" idx="$2"
  echo "$entry" | cut -d'|' -f"$idx" | xargs
}
