#!/usr/bin/env bash
# setup-reimage-env.sh
#
# One-step wrapper for creating reimage.env, run AFTER the external data
# volume has been chosen/confirmed and the artifact root name computed (see
# "Choose the External Data Volume" through "Artifact Root Naming Convention"
# in prepare-artifact-root.md). Takes those already-confirmed values so
# reimage.env is written correctly on the first pass -- no follow-up edit
# needed.
#
# Usage: run from inside the repo checkout, with the values from the earlier
# steps still exported in the same shell session:
#   bin/setup-reimage-env.sh
#
# Required env vars (set by the earlier steps):
#   EXTERNAL_DATA_VOLUME       e.g. /Volumes/Data
#   REIMAGE_ARTIFACT_ROOT      e.g. /Volumes/Data/reimage-<asset>-<date>-open
# Optional:
#   EXTERNAL_APPLE_BACKUPS_VOLUME

set -euo pipefail

: "${EXTERNAL_DATA_VOLUME:?Set EXTERNAL_DATA_VOLUME first -- see Choose/Confirm External Data Volume steps}"
: "${REIMAGE_ARTIFACT_ROOT:?Set REIMAGE_ARTIFACT_ROOT first -- see Artifact Root Naming Convention step}"
EXTERNAL_APPLE_BACKUPS_VOLUME="${EXTERNAL_APPLE_BACKUPS_VOLUME:-}"

if [[ ! -f reimage.env.example ]]; then
  echo "ERROR: missing template: reimage.env.example" >&2
  echo "Confirm you're in the right repo checkout, then rerun this step." >&2
  exit 2
fi

if [[ -f reimage.env ]]; then
  echo "ERROR: reimage.env already exists: $(pwd)/reimage.env" >&2
  echo "Review the existing file instead of overwriting it." >&2
  exit 2
fi

cp -p reimage.env.example reimage.env

python3 bin/prepare-artifact-root.py \
  init-reimage-env \
  --env-file reimage.env \
  --external-data-volume "$EXTERNAL_DATA_VOLUME" \
  --external-apple-backups-volume "$EXTERNAL_APPLE_BACKUPS_VOLUME"

ONEDRIVE_DEST_SUBDIR="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"

python3 bin/prepare-artifact-root.py \
  upsert-env \
  --env-file reimage.env \
  "REIMAGE_ARTIFACT_ROOT=$REIMAGE_ARTIFACT_ROOT" \
  "ONEDRIVE_DEST_SUBDIR=$ONEDRIVE_DEST_SUBDIR"

chmod 600 reimage.env

echo ""
echo "reimage.env created, fully resolved (including REIMAGE_ARTIFACT_ROOT -- no follow-up edit needed):"
cat reimage.env
