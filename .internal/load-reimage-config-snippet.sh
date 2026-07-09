#!/usr/bin/env bash
# load-reimage-config-snippet.sh
# Source this from bin/*.sh scripts in this repo to load the shared artifact
# config plus reimage.env-backed local defaults.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT_CONFIG="$SCRIPT_DIR/artifact-config.sh"

if [[ ! -f "$ARTIFACT_CONFIG" ]]; then
  echo "ERROR: shared artifact config not found: $ARTIFACT_CONFIG" >&2
  exit 2
fi

# Many callers accept --artifact-root later, so keep this loader permissive by
# default. Scripts that need an immediate preflight can set
# ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=true before sourcing this file.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT="${ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT:-false}"

# shellcheck source=artifact-config.sh
source "$ARTIFACT_CONFIG"
