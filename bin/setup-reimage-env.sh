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
# The remaining keys THIS phase owns -- OFFICE_WATCH, JUMP_DRIVE_VOLUME,
# TOOLKIT_GITHUB_ACCOUNT -- are captured from the shell when already exported, so
# nothing you set here is dropped. Keys another runbook owns are deliberately not
# captured; see the loop below.

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

# Capture the remaining keys this phase owns, when they are already exported in
# the shell, so a value you deliberately set is not dropped at creation.
#
# The list is deliberately short. It used to carry the two Git repository roots
# and the nine Git identity keys, and reimage.env.example carried them as blanks
# for the same reason -- between them they let reimage.env be handed values three
# and four phases before the runbook that owns them, with nothing checking that
# the values were the ones that machine would actually restore with. Both are
# gone. A key belongs to the runbook that uses it, `upsert-env` appends a key
# that is not yet in the file, and backup-repos.md, restore-git.md and
# restore-repos.md each record their own.
_captured=()
for _k in OFFICE_WATCH JUMP_DRIVE_VOLUME TOOLKIT_GITHUB_ACCOUNT; do
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
