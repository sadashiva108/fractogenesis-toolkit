#!/usr/bin/env bash
# build-jump-drive-payload.sh
#
# Builds a versioned, checksummed tarball of the reimage toolkit repo for
# copying onto a jump drive as a no-network fallback for bootstrap.sh.
#
# Usage:
#   build-jump-drive-payload.sh /path/to/reimage-toolkit /path/to/output-dir
#
# Run this shortly before each reimage to keep the jump drive's copy current.
# The version stamp (commit hash + build date) lets you tell at a glance how
# stale a given stick's contents are.

set -euo pipefail

REPO_ROOT="${1:?Usage: build-jump-drive-payload.sh /path/to/reimage-toolkit /path/to/output-dir}"
OUT_DIR="${2:?Usage: build-jump-drive-payload.sh /path/to/reimage-toolkit /path/to/output-dir}"

mkdir -p "$OUT_DIR"
cd "$REPO_ROOT"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "WARNING: working tree has uncommitted changes — the tarball will only include the last commit ($(git rev-parse --short HEAD)), not your current edits." >&2
fi

COMMIT="$(git rev-parse --short HEAD)"
DATE="$(date +%Y-%m-%d)"
echo "${COMMIT} (built ${DATE})" > "$REPO_ROOT/.toolkit-version"

REPO_NAME="$(basename "$REPO_ROOT")"
TARBALL="$OUT_DIR/${REPO_NAME}.tar.gz"
# --add-file includes the untracked version stamp alongside the tracked
# files at HEAD. git archive alone would silently drop it, since it only
# archives what's committed.
git archive --format=tar.gz --add-file=".toolkit-version" -o "$TARBALL" HEAD

rm -f "$REPO_ROOT/.toolkit-version"

# Record the checksum using only the bare filename, computed from inside
# OUT_DIR. If the checksum file instead recorded an absolute build-time
# path, verification later (from a jump drive or a different machine)
# would either silently check a stale file at that old path if it happens
# to still exist, or fail outright once it doesn't — neither of which is
# the actual verification you want.
(cd "$OUT_DIR" && shasum -a 256 "$(basename "$TARBALL")" > "$(basename "$TARBALL").sha256")

echo ""
echo "Built:     $TARBALL"
echo "Version:   ${COMMIT} (${DATE})"
echo "Checksum:  $(cat "${TARBALL}.sha256")"
echo ""
echo "Copy both $TARBALL and ${TARBALL}.sha256 onto the jump drive, alongside bootstrap.sh."
