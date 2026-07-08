#!/usr/bin/env bash
# bootstrap.sh
#
# Installs the reimage toolkit to $FRACTOGENESIS_HOME (default: $HOME/reimage-toolkit).
#
# Usage:
#   bootstrap.sh                        # fetch from GitHub via curl
#   bootstrap.sh /path/to/tarball.tar.gz  # install from a local tarball (jump-drive fallback)
#
# The local-tarball path is designed to be run from a USB stick when network
# is unavailable immediately after a Mac reimage. Same install logic either
# way, so there is only one code path to keep correct.

set -euo pipefail

DEST="${FRACTOGENESIS_HOME:-$HOME/reimage-toolkit}"
SRC_TARBALL="${1:-}"

mkdir -p "$DEST"

if [[ -n "$SRC_TARBALL" ]]; then
  if [[ ! -f "$SRC_TARBALL" ]]; then
    echo "Local tarball not found: $SRC_TARBALL" >&2
    exit 1
  fi

  CHECKSUM_FILE="${SRC_TARBALL}.sha256"
  if [[ -f "$CHECKSUM_FILE" ]]; then
    echo "Verifying checksum..."
    # Verify by bare filename from inside the tarball's own directory,
    # not by whatever absolute path was recorded at build time — the
    # tarball may now live on a jump drive or a different machine than
    # where it was built, and shasum -c trusts the path stored in the
    # checksum file unless told otherwise.
    TARBALL_DIR="$(cd "$(dirname "$SRC_TARBALL")" && pwd)"
    if ! (cd "$TARBALL_DIR" && shasum -a 256 -c "$(basename "$CHECKSUM_FILE")"); then
      echo "Checksum mismatch — tarball may be corrupted or incomplete." >&2
      exit 1
    fi
  else
    echo "WARNING: no checksum file found next to $SRC_TARBALL — skipping integrity check." >&2
  fi

  echo "Installing from local tarball: $SRC_TARBALL"
  # No --strip-components here: git archive tarballs (used by
  # build-jump-drive-payload.sh) have no top-level wrapping directory,
  # unlike GitHub's codeload tarballs used in the curl path below. Applying
  # --strip-components=1 to a git-archive tarball eats the real first path
  # segment of every entry (e.g. bin/foo.sh -> foo.sh) and drops
  # single-segment files like README.md and .toolkit-version entirely.
  tar -xz -C "$DEST" -f "$SRC_TARBALL"
else
  echo "Fetching from GitHub..."
  curl -fL "https://codeload.github.com/sadashiva108/fractogenesis-toolkit/tar.gz/refs/heads/main" \
    | tar -xz -C "$DEST" --strip-components=1
fi

chmod +x "$DEST"/bin/* 2>/dev/null || true

if [[ -f "$DEST/.toolkit-version" ]]; then
  echo "Toolkit ready at $DEST (version: $(cat "$DEST/.toolkit-version"))"
else
  echo "Toolkit ready at $DEST (no version stamp found)"
fi
