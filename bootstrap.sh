#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh
#
# Installs the fractogenesis toolkit into $FRACTOGENESIS_HOME (default:
# $HOME/fractogenesis-toolkit), either by fetching it from GitHub over the
# network or by extracting a pre-built tarball from a jump drive.
#
# Runbook/phase context: reimage-guide-access.md (Phase 6A). That runbook
# proves both routes before the Mac is erased — the curl route in Step 2, the
# no-network jump-drive route in Step 3 — and its pass criteria include that
# bin/ scripts arrive executable.
#
# CLASSIFICATION: bootstrap/environment creator. This file lives at the REPO
# ROOT rather than in bin/ because it must run BEFORE a checkout exists — on a
# bare Mac with no Git, no SSH keys and no toolkit on disk, typically piped
# straight into bash from curl. It is deliberately NOT an entrypoint:
#
#   - It does NOT load .internal/load-reimage-config.sh, and must not. The
#     loader lives inside the very checkout this script is creating; when the
#     curl route runs, nothing of the toolkit is on disk yet.
#   - It does NOT self-locate SCRIPT_DIR/REPO_ROOT from BASH_SOURCE. Under
#     `curl ... | bash` there is no script file on disk to locate from, and the
#     install destination comes from FRACTOGENESIS_HOME, not from where this
#     file happens to sit.
#   - It has no usage() that sed-prints this header for the same reason: "$0"
#     is not a readable file when the script arrives on bash's stdin. The
#     usage block below is documentation only.
#   - It DOES run `chmod +x` on the extracted bin/ scripts. That is the one
#     deliberate exception to the repo's no-chmod-during-execution rule: this
#     script is creating the tree, not running inside an existing checkout, and
#     reimage-guide-access.md's pass criteria test for the executable bit
#     directly (`test -x "$FRACTOGENESIS_HOME/bin/build-jump-drive-payload.sh"`).
#
# --- BEGIN USAGE ---
# Usage:
#   # Network route -- fetch and extract from GitHub. Download and run as two
#   # steps: piped, `-f -s` makes a 404 print nothing, bash reads an empty
#   # stdin, and the pipeline exits 0 -- installing nothing, silently.
#   export TOOLKIT_GITHUB_ACCOUNT=<account>               # required, network route only
#   export FRACTOGENESIS_HOME=/absolute/install/path      # optional
#   curl -fL -o /tmp/bootstrap.sh \\
#     "https://raw.githubusercontent.com/$TOOLKIT_GITHUB_ACCOUNT/fractogenesis-toolkit/main/bootstrap.sh"
#   bash /tmp/bootstrap.sh
#
#   # Same thing from an existing copy of this file:
#   bash bootstrap.sh
#
#   # Jump-drive route -- install from a local tarball, no network required.
#   bash bootstrap.sh "$JUMP_DRIVE_VOLUME/tarball/fractogenesis-toolkit.tar.gz"
#
# Arguments:
#   [TARBALL]   Optional path to a local payload tarball built by
#               bin/build-jump-drive-payload.sh. When omitted, the toolkit is
#               fetched from GitHub over the network instead. When a sibling
#               <TARBALL>.sha256 exists it is verified before extraction; when
#               it does not, a warning is printed and extraction continues.
#
# Configuration:
#   FRACTOGENESIS_HOME
#       Install destination. Default: $HOME/fractogenesis-toolkit.
#       Must be exported on its own line before a piped curl invocation -- a
#       `VAR=val curl ... | bash` prefix sets the variable for curl only, not
#       for the bash on the other side of the pipe.
#
#   TOOLKIT_GITHUB_ACCOUNT
#       GitHub account hosting the toolkit. Required by the network route,
#       ignored by the jump-drive route. No default: hardcoding one would send
#       every other user's bootstrap at the original author's repository.
#
#   Shared reimage config (reimage.env, .internal/artifact-config.sh) is
#   intentionally NOT loaded; see the classification note above. On a machine
#   that still has a checkout, TOOLKIT_GITHUB_ACCOUNT comes from reimage.env;
#   on a bare Mac it is exported by hand from the post-reimage cheatsheet.
#
# Exit status:
#   0  Toolkit installed at the destination.
#   1  Local tarball missing, checksum mismatch, or a fetch/extract failure.
# --- END USAGE ---
#
# The local-tarball path is designed to be run from a USB stick when network
# is unavailable immediately after a Mac reimage. Same install logic either
# way, so there is only one code path to keep correct.
# =============================================================================

set -euo pipefail

DEST="${FRACTOGENESIS_HOME:-$HOME/fractogenesis-toolkit}"
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
  # Network route only. The jump-drive route above needs no account and no
  # network, so this is deliberately not checked before the tarball branch.
  ACCOUNT="${TOOLKIT_GITHUB_ACCOUNT:?TOOLKIT_GITHUB_ACCOUNT is not set. Export the GitHub account that hosts your fractogenesis-toolkit before running the network route, e.g. export TOOLKIT_GITHUB_ACCOUNT=your-account. On a freshly reimaged Mac take it from the post-reimage cheatsheet you emailed yourself.}"
  echo "Fetching from GitHub (account: $ACCOUNT)..."
  curl -fL "https://codeload.github.com/$ACCOUNT/fractogenesis-toolkit/tar.gz/refs/heads/main" \
    | tar -xz -C "$DEST" --strip-components=1
fi

# Deliberate exception to the no-chmod-during-execution rule -- see the
# classification note in the header. This script creates the checkout; it does
# not run inside one, and Phase 6A's pass criteria test the executable bit.
chmod +x "$DEST"/bin/* 2>/dev/null || true

if [[ -f "$DEST/.toolkit-version" ]]; then
  echo "Toolkit ready at $DEST (version: $(cat "$DEST/.toolkit-version"))"
else
  echo "Toolkit ready at $DEST (no version stamp found)"
fi
