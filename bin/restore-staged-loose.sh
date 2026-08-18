#!/usr/bin/env bash
# =============================================================================
# restore-staged-loose.sh
#
# Puts the credential-shaped files that Phase 3B swept into
# secrets-encrypted/staged-loose/ back where they came from, reading the source
# column of MANIFEST.tsv.
#
# This is the exact inverse of bin/stage-loose-secrets.sh, and it closes a real
# data-loss gap: stage-loose-secrets.sh MOVES files out of home-files-backup/,
# app-settings-backup/ and staged-ignored-files/ into secrets-encrypted/ so the
# Phase 3C DMG can encrypt them. Without this script nothing ever puts them
# back, so every later phase that reads those trees — restore-access (10B),
# restore-apps (12), restore-home (15) — silently sees a tree with holes in it.
#
# Runbook: restore-access.md (Phase 10B), which owns the DMG mount. Run it
# EARLY, while the DMG is attached and before the trees are consumed. The
# manifest's source column is relative to the artifact root, so restoring
# rehydrates the artifact tree; the ordinary restore phases then copy from that
# rehydrated tree into $HOME as they always would.
#
# This file is intended for bin/. It is a normal entrypoint: dry-run by default,
# and it only writes when --apply is given.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/restore-staged-loose.sh
#
#   # Attach the secrets DMG first (restore-access.md Step 1 does this):
#   #   DMG="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-<stamp>.dmg"
#   #   MNT="$(hdiutil attach "$DMG" | awk -F'\t' '/\/Volumes\//{print $NF}' | tail -1)"
#
#   # Show what would be restored (default -- nothing is written)
#   ./bin/restore-staged-loose.sh
#
#   # Actually restore
#   ./bin/restore-staged-loose.sh --apply
#
#   # Point at the mounted staged-loose directory explicitly
#   ./bin/restore-staged-loose.sh --apply --source "$MNT/staged-loose"
#
# Options:
#   --source DIR          The mounted staged-loose directory. Default: found by
#                         scanning /Volumes/*/staged-loose/MANIFEST.tsv, which
#                         is robust to the DMG's volume name differing from its
#                         filename.
#   --manifest PATH       Override the manifest location. Default:
#                         <source>/MANIFEST.tsv
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT (the restore target).
#   --apply               Perform the copies. Without it, nothing is written.
#   --force               Overwrite a destination that already exists. Without
#                         it, an existing destination is reported and skipped.
#   -h, --help            Show this message and exit.
#
# What it does:
#   For each data row of MANIFEST.tsv (tab-separated: staged-at, source-path,
#   staged-path), copies
#     <source>/<source-path>  ->  <artifact-root>/<source-path>
#   preserving mode and timestamps. Parent directories are created as needed.
#
# Safety:
#   - COPIES, never moves. The DMG is left byte-identical, so a failed or
#     partial run can simply be repeated.
#   - Never overwrites without --force.
#   - Idempotent: a second run reports every row as EXISTS and writes nothing.
#
#   This re-introduces plaintext credentials into the artifact tree. That is the
#   point -- the later restore phases need them -- but the drive is no longer
#   clean afterwards. Treat it as sensitive until the reimage is signed off, and
#   re-run ./bin/stage-loose-secrets.sh --apply (or wipe the drive) before the
#   artifact root is retired or handed to anyone.
#
# Exit status:
#   0  Completed. Nothing to restore, or the copies succeeded.
#   1  One or more files could not be restored. Nothing was deleted.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -Eeuo pipefail
trap 'status=$?; echo "" >&2; \
  echo "ERROR: restore-staged-loose.sh failed near line ${LINENO}: ${BASH_COMMAND}" >&2; \
  exit "$status"' ERR

# ---- Locate and source shared reimage config -------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"
if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi

ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER" || {
  echo "ERROR: shared config failed to load (status $?)" >&2
  exit 2
}

# ---- Colors ----------------------------------------------------------------
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

thin_hr()     { printf '%s\n' "  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"; }
log_section() { echo ""; printf "${BLD}${CYN}▸ %s${RST}\n" "$1"; thin_hr; }
err()         { printf "${RED}%s${RST}\n" "$1" >&2; }
warn()        { printf "${YEL}%s${RST}\n" "$1" >&2; }
hint()        { printf "${DIM}%s${RST}\n" "$1" >&2; }

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

# ---- Arguments -------------------------------------------------------------
SOURCE_DIR=""
MANIFEST=""
APPLY=false
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)        SOURCE_DIR="${2:-}"; shift 2 ;;
    --manifest)      MANIFEST="${2:-}"; shift 2 ;;
    --artifact-root) REIMAGE_ARTIFACT_ROOT="${2:-}"; shift 2 ;;
    --apply)         APPLY=true; shift ;;
    --force)         FORCE=true; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) err "Unknown option: $1"; echo "" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  err "REIMAGE_ARTIFACT_ROOT is not set."
  hint "Source reimage.env, or pass --artifact-root."
  exit 2
fi
if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  err "Artifact root does not exist: $REIMAGE_ARTIFACT_ROOT"
  hint "Is the external data volume mounted?"
  exit 2
fi

# ---- Locate the mounted staged-loose directory ------------------------------
# Scan for the manifest rather than globbing the DMG's filename: the volume name
# comes from -volname at build time and need not match the .dmg file name.
if [[ -z "$SOURCE_DIR" ]]; then
  for candidate in /Volumes/*/staged-loose; do
    if [[ -f "$candidate/MANIFEST.tsv" ]]; then
      SOURCE_DIR="$candidate"
      break
    fi
  done
fi

if [[ -z "$SOURCE_DIR" ]]; then
  err "Could not find a mounted staged-loose directory."
  hint "Attach the secrets DMG first, then re-run. From restore-access.md Step 1:"
  hint "  DMG=\"\$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-<stamp>.dmg\""
  hint "  MNT=\"\$(hdiutil attach \"\$DMG\" | awk -F'\\t' '/\\/Volumes\\//{print \$NF}' | tail -1)\""
  hint "  ./bin/restore-staged-loose.sh --source \"\$MNT/staged-loose\""
  exit 2
fi

[[ -n "$MANIFEST" ]] || MANIFEST="$SOURCE_DIR/MANIFEST.tsv"

if [[ ! -f "$MANIFEST" ]]; then
  err "Manifest not found: $MANIFEST"
  hint "Phase 3B writes it only when stage-loose-secrets.sh --apply actually moved"
  hint "something. No manifest means nothing was staged, and nothing needs restoring."
  exit 2
fi

log_section "Restore staged loose secrets"
printf "  ${DIM}Manifest      : %s${RST}\n" "$MANIFEST"
printf "  ${DIM}Source        : %s${RST}\n" "$SOURCE_DIR"
printf "  ${DIM}Destination   : %s${RST}\n" "$REIMAGE_ARTIFACT_ROOT"
if $APPLY; then
  printf "  ${DIM}Mode          : APPLY%s${RST}\n" "$($FORCE && echo ' (force)' || true)"
else
  printf "  ${CYN}Mode          : dry run — nothing will be written${RST}\n"
fi
echo ""

# ---- Walk the manifest ------------------------------------------------------
restored=0; would=0; existing=0; missing=0; failures=0; rows=0

# `|| [[ -n "$staged_at" ]]` so a manifest with no trailing newline does not
# silently drop its last row.
while IFS=$'\t' read -r staged_at rel staged_rel || [[ -n "$staged_at" ]]; do
  # Skip the comment header and any blank line.
  case "$staged_at" in
    ''|'#'*) continue ;;
  esac
  [[ -n "$rel" ]] || continue
  rows=$(( rows + 1 ))

  src="$SOURCE_DIR/$rel"
  dst="$REIMAGE_ARTIFACT_ROOT/$rel"

  if [[ ! -f "$src" ]]; then
    missing=$(( missing + 1 ))
    printf "    ${RED}MISSING  %s${RST}\n" "$rel"
    printf "             ${DIM}not present in the image at %s${RST}\n" "$src"
    continue
  fi

  if [[ -e "$dst" ]] && ! $FORCE; then
    existing=$(( existing + 1 ))
    printf "    ${YEL}EXISTS   %s${RST}\n" "$rel"
    printf "             ${DIM}destination already present; left alone (use --force to overwrite)${RST}\n"
    continue
  fi

  if ! $APPLY; then
    would=$(( would + 1 ))
    printf "    ${CYN}WOULD    %s${RST}\n" "$rel"
    continue
  fi

  # A failed copy must not abort the walk: the remaining rows still need
  # restoring, and a half-restored tree is the worst outcome.
  if mkdir -p "$(dirname "$dst")" && cp -p "$src" "$dst"; then
    restored=$(( restored + 1 ))
    printf "    ${GRN}RESTORED %s${RST}\n" "$rel"
  else
    failures=$(( failures + 1 ))
    printf "    ${RED}FAILED   %s${RST}\n" "$rel"
  fi
done < "$MANIFEST"

# ---- Summary ----------------------------------------------------------------
log_section "Summary"
printf "  Manifest rows      : %s\n" "$rows"
if $APPLY; then
  printf "  Restored           : %s\n" "$restored"
else
  printf "  Would restore      : %s\n" "$would"
fi
printf "  Already present    : %s\n" "$existing"
printf "  Missing from image : %s\n" "$missing"
printf "  Failed             : %s\n" "$failures"
echo ""

if ! $APPLY && [[ "$would" -gt 0 ]]; then
  hint "Dry run only. Re-run with --apply to restore."
fi
if [[ "$missing" -gt 0 ]]; then
  warn "Rows marked MISSING are recorded in the manifest but absent from the image."
  hint "Check that the DMG is the one built after the Phase 3B sweep that wrote these rows."
fi
if $APPLY && [[ "$restored" -gt 0 ]]; then
  echo ""
  warn "Plaintext credentials are now back in the artifact tree."
  hint "The drive is no longer clean. Re-run ./bin/stage-loose-secrets.sh --apply,"
  hint "or wipe the drive, before the artifact root is retired or handed to anyone."
fi

[[ "$failures" -eq 0 ]] || exit 1
exit 0
