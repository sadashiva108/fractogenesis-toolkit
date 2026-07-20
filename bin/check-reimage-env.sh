#!/usr/bin/env bash
# check-reimage-env.sh
#
# Diagnostic-only: reports whether reimage.env already exists in the current
# directory, and if so, prints its key values next to today's date, this
# Mac's hostname, and the currently chosen EXTERNAL_DATA_VOLUME so you can
# tell whether the file still matches this effort or is left over from an
# earlier, unfinished one.
#
# Never writes, deletes, or archives anything -- see
# "Handle Existing Reimage Environment" (Supplemental Reference) in
# prepare-artifact-root.md for what to do with the result.
#
# Usage: run from inside the repo checkout, with EXTERNAL_DATA_VOLUME
# already exported from "Choose the External Data Volume":
#   bin/check-reimage-env.sh

set -uo pipefail  # deliberately no -e: a missing reimage.env is not a failure

if [[ -f reimage.env ]]; then
  echo "reimage.env already exists:"
  echo
  grep -E '^(export[[:space:]]+)?(REIMAGE_ARTIFACT_ROOT|ASSET_OR_HOST|REIMAGE_START_DATE|EXTERNAL_DATA_VOLUME)=' reimage.env
  echo
  echo "Ground truth to compare against:"
  printf 'Today:         %s\n' "$(date +%Y%m%d)"
  printf 'This Mac:      %s\n' "$(hostname -s)"
  printf 'Chosen volume: %s\n' "${EXTERNAL_DATA_VOLUME:-<not exported yet>}"
else
  echo "No existing reimage.env."
fi
