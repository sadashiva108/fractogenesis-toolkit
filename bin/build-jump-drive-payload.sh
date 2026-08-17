#!/usr/bin/env bash
# =============================================================================
# build-jump-drive-payload.sh
#
# Builds a versioned, checksummed tarball of a fractogenesis-toolkit checkout
# for copying onto a jump drive, as the no-network fallback payload that
# bootstrap.sh installs from.
#
# Runbook/phase context: reimage-guide-access.md (Phase 6A), Step 3 — the jump
# drive route. Run it shortly before each reimage to keep the jump drive's copy
# current. The version stamp (commit hash + build date) lets you tell at a
# glance how stale a given stick's contents are.
#
# This file is intended for bin/. Unlike the other bin/ entrypoints it takes
# its target repository as an explicit POSITIONAL argument rather than
# self-locating from BASH_SOURCE, and that is deliberate: Phase 6A packages a
# real checkout while running from a throwaway one, so "the repo to archive" is
# not the same thing as "the repo this script was launched from". The argument
# is therefore named SOURCE_REPO_ROOT, leaving the repo-wide REPO_ROOT name to
# mean what it means everywhere else.
#
# Shared reimage config (.internal/load-reimage-config.sh) is intentionally NOT
# loaded. Every path this script touches arrives as an argument, and the jump
# drive is built from a checkout that may have no reimage.env at all.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/build-jump-drive-payload.sh
#
#   ./bin/build-jump-drive-payload.sh /path/to/fractogenesis-toolkit /path/to/output-dir
#
#   # Phase 6A form -- package a real checkout onto the jump drive
#   ./bin/build-jump-drive-payload.sh \
#     "$FRACTOGENESIS_PARENT/fractogenesis-toolkit" \
#     "$JUMP_DRIVE_VOLUME/tarball"
#
# Arguments (both required, positional, in this order):
#   SOURCE_REPO_ROOT  Absolute path to the fractogenesis-toolkit checkout to
#                     archive. Pass the real path, not "." -- the tarball name
#                     is derived from `basename` of this argument, so "." would
#                     produce a tarball literally named "..tar.gz".
#   OUTPUT_DIR        Directory the tarball and its .sha256 are written to.
#                     Created if missing. A relative path is resolved against
#                     the current directory before the script changes into
#                     SOURCE_REPO_ROOT, so it lands where you typed it.
#
# Options:
#   -h, --help        Show this message and exit.
#
# Requires:
#   git      `git archive --add-file` is used to include the untracked version
#            stamp; that flag needs Git 2.38 or newer.
#   shasum   Records the payload checksum bootstrap.sh verifies.
#
# Outputs (beneath OUTPUT_DIR):
#   <repo-name>.tar.gz         The payload bootstrap.sh extracts.
#   <repo-name>.tar.gz.sha256  Checksum recorded by bare filename, so it stays
#                              verifiable from the jump drive or another Mac.
#
# Configuration:
#   No shared config is read and no environment variable is consulted; both
#   paths come from the command line.
#
# Exit status:
#   0  Payload and checksum written.
#   1  Missing required argument (bash prints the usage line above and stops),
#      or a git/tar/shasum step failed.
#
#   Note: running this with NO arguments is how reimage-guide-access.md proves
#   the script executes at all on a freshly bootstrapped Mac. The resulting
#   usage error is a PASS signal there; `command not found`, `Permission
#   denied`, or a traceback is the real failure. That path is left exactly as
#   it is rather than normalized to the repo's usual exit 2.
# --- END USAGE ---
# =============================================================================

set -euo pipefail

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

# Deliberately kept as bash's own `${var:?message}` form. reimage-guide-access.md
# documents the exact "line N: 1: Usage: ..." output this produces as the proof
# that the script parsed and ran; do not convert it to a usage()/exit 2 block.
SOURCE_REPO_ROOT="${1:?Usage: build-jump-drive-payload.sh /path/to/fractogenesis-toolkit /path/to/output-dir}"
OUT_DIR="${2:?Usage: build-jump-drive-payload.sh /path/to/fractogenesis-toolkit /path/to/output-dir}"

mkdir -p "$OUT_DIR"
# Resolve OUT_DIR before the cd below. `git archive -o` and the shasum subshell
# both run with the checkout as the working directory, so a relative OUT_DIR
# would be re-interpreted there and write the payload into the very repo being
# archived, while the directory just created in the caller's cwd stayed empty.
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
cd "$SOURCE_REPO_ROOT"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "WARNING: working tree has uncommitted changes — the tarball will only include the last commit ($(git rev-parse --short HEAD)), not your current edits." >&2
fi

COMMIT="$(git rev-parse --short HEAD)"
DATE="$(date +%Y-%m-%d)"
echo "${COMMIT} (built ${DATE})" > "$SOURCE_REPO_ROOT/.toolkit-version"

REPO_NAME="$(basename "$SOURCE_REPO_ROOT")"
TARBALL="$OUT_DIR/${REPO_NAME}.tar.gz"
# --add-file includes the untracked version stamp alongside the tracked
# files at HEAD. git archive alone would silently drop it, since it only
# archives what's committed.
git archive --format=tar.gz --add-file=".toolkit-version" -o "$TARBALL" HEAD

rm -f "$SOURCE_REPO_ROOT/.toolkit-version"

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
