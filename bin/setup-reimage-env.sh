#!/usr/bin/env bash
# setup-reimage-env.sh
#
# One-step wrapper for creating reimage.env, run AFTER the external data
# volume has been chosen/confirmed (see "Choose the External Data Volume"
# through "Confirm External Data Volume Readiness" in prepare-artifact-root.md).
# Computes ASSET_OR_HOST, REIMAGE_START_DATE, and REIMAGE_ARTIFACT_ROOT itself
# (sensible defaults, overridable via env vars) and writes reimage.env fully
# resolved in a single pass -- no follow-up edit needed. When ONEDRIVE_FOLDER_NAME
# is set, prepare-artifact-root.py also resolves ONEDRIVE_ROOT under CloudStorage
# and pre-creates the per-reimage OneDrive destination.
#
# Usage: run from inside the repo checkout, with EXTERNAL_DATA_VOLUME already
# exported from "Choose the External Data Volume":
#   bin/setup-reimage-env.sh
#
# Required env vars (set by the earlier steps):
#   EXTERNAL_DATA_VOLUME       e.g. /Volumes/Data
# Optional overrides (sensible defaults computed if unset):
#   ASSET_OR_HOST              default: hostname
#   REIMAGE_START_DATE         default: today (YYYYMMDD)
#   EXTERNAL_APPLE_BACKUPS_VOLUME
#   ONEDRIVE_FOLDER_NAME       CloudStorage OneDrive folder name (for example
#                              OneDrive-AcmeGroup). When set, ONEDRIVE_ROOT is
#                              resolved and the per-reimage OneDrive destination
#                              is created. Leave unset to skip OneDrive entirely.
# Any other reimage.env variable already exported in this shell (for example
# OFFICE_WATCH, PERFORMANCE_HISTORY_SOURCE, REIMAGE_WORKSPACE_ROOT, or the GIT_*
# values) is also captured into reimage.env, so nothing you set is dropped.

set -euo pipefail

: "${EXTERNAL_DATA_VOLUME:?Set EXTERNAL_DATA_VOLUME first -- see Choose/Confirm External Data Volume steps}"
: "${REIMAGE_WORKSPACE_ROOT:?Set REIMAGE_WORKSPACE_ROOT first -- the workspace holds artifact-config and staged-certs fragments, and a wrong value silently falls back to the repo templates}"
EXTERNAL_APPLE_BACKUPS_VOLUME="${EXTERNAL_APPLE_BACKUPS_VOLUME:-}"

if [[ ! -f reimage.env.example ]]; then
  echo "ERROR: missing template: reimage.env.example" >&2
  echo "Confirm you're in the right repo checkout, then rerun this step." >&2
  exit 2
fi

if [[ -f reimage.env ]]; then
  echo "ERROR: reimage.env already exists: $(pwd)/reimage.env" >&2
  echo "Run bin/check-reimage-env.sh, then see 'Handle Existing Reimage Environment' before continuing." >&2
  exit 2
fi

cp -p reimage.env.example reimage.env

python3 bin/prepare-artifact-root.py \
  init-reimage-env \
  --env-file reimage.env \
  --external-data-volume "$EXTERNAL_DATA_VOLUME" \
  --external-apple-backups-volume "$EXTERNAL_APPLE_BACKUPS_VOLUME" \
  --asset-or-host "${ASSET_OR_HOST:-}" \
  --reimage-start-date "${REIMAGE_START_DATE:-}" \
  --onedrive-folder-name "${ONEDRIVE_FOLDER_NAME:-}" \
  --onedrive-parent-dir "${ONEDRIVE_PARENT_DIR:-}" \
  --workspace-root "${REIMAGE_WORKSPACE_ROOT:-}" \
  --performance-history-source "${PERFORMANCE_HISTORY_SOURCE:-}"

# Capture any other optional reimage.env variables already exported in this
# shell, so a value you deliberately set is not silently dropped at creation.
# These are normally set later by the runbook that uses them; exporting one
# first is simply honored here.
_captured=()
for _k in OFFICE_WATCH JUMP_DRIVE_VOLUME \
          GIT_WORK_REPO_ROOT GIT_PERSONAL_REPO_ROOT \
          GIT_WORK_NAME GIT_WORK_EMAIL GIT_PERSONAL_NAME GIT_PERSONAL_EMAIL \
          GIT_WORK_GITHUB_HOST GIT_PERSONAL_GITHUB_HOST \
          GIT_WORK_SSH_KEY GIT_PERSONAL_SSH_KEY GIT_DEFAULT_BRANCH; do
  _v="${!_k:-}"
  [ -n "$_v" ] && _captured+=("${_k}=${_v}")
done
if [ "${#_captured[@]}" -gt 0 ]; then
  python3 bin/prepare-artifact-root.py upsert-env --env-file reimage.env "${_captured[@]}"
  printf 'Captured %d exported optional var(s) into reimage.env.\n' "${#_captured[@]}"
fi

chmod 600 reimage.env

echo ""
echo "reimage.env created, fully resolved (including REIMAGE_ARTIFACT_ROOT -- no follow-up edit needed):"
cat reimage.env
