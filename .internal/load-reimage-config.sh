#!/usr/bin/env bash
# =============================================================================
# load-reimage-config.sh
#
# Source-only foundation loader for the shared Mac reimage configuration.
# It resolves artifact-config.sh relative to this file, then loads reimage.env,
# configuration-backed defaults, reusable artifact-config fragments, and shared
# helper functions through artifact-config.sh.
#
# This is a foundation/config loader, not a normal executable helper. It does
# not parse command-line arguments, perform workflow work, print a completion
# summary, or set shell options in the caller.
#
# --- BEGIN USAGE ---
# Usage:
#   # From a bin/ entrypoint that has already resolved REPO_ROOT:
#   CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"
#   if [[ ! -f "$CONFIG_LOADER" ]]; then
#     echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
#     exit 2
#   fi
#   # shellcheck source=../.internal/load-reimage-config.sh
#   source "$CONFIG_LOADER"
#
#   # From a helper under .internal/<domain>/:
#   CONFIG_LOADER="$(dirname "$SCRIPT_DIR")/load-reimage-config.sh"
#   # shellcheck source=../load-reimage-config.sh
#   source "$CONFIG_LOADER"
#
# Optional caller controls set before sourcing:
#   REIMAGE_ENV
#       Override the reimage.env path used by artifact-config.sh.
#   ARTIFACT_CONFIG_DIR
#       Override the reusable artifact-config fragment directory.
#   ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT
#       Set to true when the caller must fail during config loading if
#       REIMAGE_ARTIFACT_ROOT is empty. Default: false.
#
# Configuration precedence is implemented by artifact-config.sh:
#   1. Values already exported by the caller, including optional .envrc values.
#   2. Values loaded from reimage.env.
#   3. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Explicit command-line options remain the entrypoint's responsibility and may
# override loaded values after this file returns.
#
# Source contract:
#   - Must be sourced; direct execution is rejected.
#   - Does not source .envrc.
#   - Does not enable or disable set -e, set -u, or pipefail in the caller.
#   - Preserves the caller's SCRIPT_DIR and REPO_ROOT values even though the
#     current artifact-config.sh uses those names internally while loading.
#
# Return status when sourced:
#   0  Shared configuration loaded successfully.
#   2  Required foundation file or configuration prerequisite was unavailable.
# --- END USAGE ---
# =============================================================================

# Do not use `set -euo pipefail` here. This file is sourced and must not change
# the caller's shell-option state.

# Reject direct execution. A sourced foundation loader must return control and
# variables to its caller rather than act as a standalone command.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "ERROR: load-reimage-config.sh must be sourced, not executed." >&2
  echo "Use: source /path/to/.internal/load-reimage-config.sh" >&2
  exit 2
fi

# Namespace loader implementation variables because sourcing occurs in the
# caller's shell. Generic names would leak into or overwrite caller state.
_REIMAGE_CONFIG_LOADER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_REIMAGE_CONFIG_ARTIFACT_CONFIG="$_REIMAGE_CONFIG_LOADER_DIR/artifact-config.sh"

if [[ ! -f "$_REIMAGE_CONFIG_ARTIFACT_CONFIG" ]]; then
  echo "ERROR: shared artifact config not found: $_REIMAGE_CONFIG_ARTIFACT_CONFIG" >&2
  unset _REIMAGE_CONFIG_LOADER_DIR _REIMAGE_CONFIG_ARTIFACT_CONFIG
  return 2
fi

# Preserve common caller context currently reused as internal variable names by
# artifact-config.sh. This prevents config loading from silently changing how a
# caller later resolves its own helpers or repository-relative paths.
_REIMAGE_CONFIG_HAD_SCRIPT_DIR=false
_REIMAGE_CONFIG_CALLER_SCRIPT_DIR=""
if [[ ${SCRIPT_DIR+x} ]]; then
  _REIMAGE_CONFIG_HAD_SCRIPT_DIR=true
  _REIMAGE_CONFIG_CALLER_SCRIPT_DIR="$SCRIPT_DIR"
fi

_REIMAGE_CONFIG_HAD_REPO_ROOT=false
_REIMAGE_CONFIG_CALLER_REPO_ROOT=""
if [[ ${REPO_ROOT+x} ]]; then
  _REIMAGE_CONFIG_HAD_REPO_ROOT=true
  _REIMAGE_CONFIG_CALLER_REPO_ROOT="$REPO_ROOT"
fi

# Keep loading permissive by default so entrypoints may parse options such as
# --artifact-root after configuration is available.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT="${ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT:-false}"

_REIMAGE_CONFIG_LOAD_STATUS=0
# shellcheck source=artifact-config.sh
if source "$_REIMAGE_CONFIG_ARTIFACT_CONFIG"; then
  _REIMAGE_CONFIG_LOAD_STATUS=0
else
  _REIMAGE_CONFIG_LOAD_STATUS=$?
fi

if [[ "$_REIMAGE_CONFIG_HAD_SCRIPT_DIR" == true ]]; then
  SCRIPT_DIR="$_REIMAGE_CONFIG_CALLER_SCRIPT_DIR"
else
  unset SCRIPT_DIR
fi

if [[ "$_REIMAGE_CONFIG_HAD_REPO_ROOT" == true ]]; then
  REPO_ROOT="$_REIMAGE_CONFIG_CALLER_REPO_ROOT"
else
  unset REPO_ROOT
fi

if [[ "$_REIMAGE_CONFIG_LOAD_STATUS" -eq 0 ]]; then
  unset \
    _REIMAGE_CONFIG_LOADER_DIR \
    _REIMAGE_CONFIG_ARTIFACT_CONFIG \
    _REIMAGE_CONFIG_HAD_SCRIPT_DIR \
    _REIMAGE_CONFIG_CALLER_SCRIPT_DIR \
    _REIMAGE_CONFIG_HAD_REPO_ROOT \
    _REIMAGE_CONFIG_CALLER_REPO_ROOT \
    _REIMAGE_CONFIG_LOAD_STATUS
  return 0
fi

unset \
  _REIMAGE_CONFIG_LOADER_DIR \
  _REIMAGE_CONFIG_ARTIFACT_CONFIG \
  _REIMAGE_CONFIG_HAD_SCRIPT_DIR \
  _REIMAGE_CONFIG_CALLER_SCRIPT_DIR \
  _REIMAGE_CONFIG_HAD_REPO_ROOT \
  _REIMAGE_CONFIG_CALLER_REPO_ROOT \
  _REIMAGE_CONFIG_LOAD_STATUS
return 2
