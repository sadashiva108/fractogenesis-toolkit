#!/usr/bin/env bash
# =============================================================================
# stage-loose-secrets.sh
#
# Moves credential-shaped files that are sitting in plaintext under the artifact
# root into secrets-encrypted/staged-loose/, so the Phase 3C DMG encrypts them.
#
# Phase 3C encrypts exactly one directory: secrets-encrypted/. A credential that
# landed anywhere else — home-files-backup/, app-settings-backup/,
# staged-ignored-files/ — stays in the clear on the drive permanently, survives
# the DMG, survives cleanup, and leaves with the drive. This script is how that
# material is swept across the encryption boundary before the DMG is built.
#
# Runbook: stage-loose-secrets.md (Phase 3B). Paired with
# bin/check-loose-secrets.sh, which reports the same findings read-only; this
# one acts on them. Both read the same SECRET_SHAPES from shared config, so
# they can never disagree about what a credential looks like.
#
# It sweeps the destination rather than filtering at the source, which is what
# makes it phase-agnostic: material left behind by Phase 2A, 2B, 2D, or 3A is
# all caught by the same pass, and no artifact-config exclude list has to change.
#
# This file is intended for bin/. It is a normal entrypoint: dry-run by default,
# and it only moves files when --apply is given.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/stage-loose-secrets.sh
#
#   # Show what would move (default — nothing is touched)
#   ./bin/stage-loose-secrets.sh
#
#   # Actually move them
#   ./bin/stage-loose-secrets.sh --apply
#
#   # Sweep a specific root instead of the configured one
#   ./bin/stage-loose-secrets.sh --artifact-root /Volumes/Data/reimage-<asset>-<date>-open
#
#   # Leave a path alone (repeatable; matched against the path shown in output)
#   ./bin/stage-loose-secrets.sh --apply --keep 'public-certs/*'
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --apply               Perform the moves. Without it, nothing is written.
#   --keep GLOB           Leave matching paths where they are. Repeatable.
#                         Matched against the artifact-root-relative path.
#   --verbose             Also list paths that were skipped by --keep.
#   -h, --help            Show this message and exit.
#
# What it moves:
#   Any file whose NAME matches SECRET_SHAPES (the floor in
#   .internal/artifact-config.sh plus anything secret-shapes.conf.sh adds),
#   located anywhere under the artifact root except secrets-encrypted/ and
#   loose-secrets-reports/.
#
#   Destination preserves the original relative path:
#     home-files-backup/proj/id_rsa
#       -> secrets-encrypted/staged-loose/home-files-backup/proj/id_rsa
#
#   Provenance is the point. A restore phase needs to know where a staged file
#   came from, and one credentials.yml per repo would collapse into a single
#   file if these were keyed by basename.
#
# Output (under secrets-encrypted/staged-loose/, written only with --apply):
#   MANIFEST.tsv
#       Append-only: when, source path, destination path. This is the record a
#       restore phase reads to put a file back where it belongs.
#
# Safety:
#   - Never overwrites. A destination that already exists is reported and the
#     source is left alone.
#   - Never deletes. Every action is a move into secrets-encrypted/.
#   - Matching is by filename only; contents are never read. A false positive
#     costs you a file riding in the encrypted DMG instead of the plaintext
#     backup, which is why staging is safe to be aggressive about.
#
# Exit status:
#   0  Completed. Nothing to move, or the moves succeeded.
#   1  One or more files could not be moved. Nothing was deleted.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -Eeuo pipefail
trap 'status=$?; echo "" >&2; \
  echo "ERROR: stage-loose-secrets.sh failed near line ${LINENO}: ${BASH_COMMAND}" >&2; \
  exit "$status"' ERR

# ── Locate and source shared reimage config ──────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"
if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi

# Keep loading permissive so --artifact-root can override after parsing.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

thin_hr()     { printf '%s\n' "  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"; }
log_section() { echo ""; echo -e "${BLD}${CYN}▸ $1${RST}"; thin_hr; }

# ── Defaults and command-line state ──────────────────────────────────────────
APPLY=false
VERBOSE=false
KEEP_GLOBS=()

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

require_option_value() {
  local option="$1"
  local value="${2:-}"

  if [[ -z "$value" || "$value" == --* ]]; then
    echo "ERROR: $option requires a non-empty value." >&2
    usage >&2
    exit 2
  fi
}

# ── Parse command-line options ───────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --keep)
      require_option_value "$1" "${2:-}"
      KEEP_GLOBS=( ${KEEP_GLOBS[@]+"${KEEP_GLOBS[@]}"} "$2" )
      shift 2
      ;;
    --apply)
      APPLY=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set." >&2
  echo "Create/source reimage.env or pass --artifact-root PATH." >&2
  exit 2
fi

REIMAGE_ARTIFACT_ROOT="${REIMAGE_ARTIFACT_ROOT%/}"

if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: artifact root not found: $REIMAGE_ARTIFACT_ROOT" >&2
  echo "Mount the volume or correct reimage.env." >&2
  exit 2
fi

# Refuse to operate on the repository checkout. A sweep rooted at the working
# tree would move the repo's own fixtures and templates into a staged-loose
# directory inside the checkout, which is never what an unset or relative root
# was meant to do.
if [[ "$REIMAGE_ARTIFACT_ROOT" == "$REPO_ROOT" || "$REIMAGE_ARTIFACT_ROOT" == "$REPO_ROOT"/* ]]; then
  echo "ERROR: refusing to sweep inside the repository checkout." >&2
  echo "  artifact root: $REIMAGE_ARTIFACT_ROOT" >&2
  echo "  repo root:     $REPO_ROOT" >&2
  echo "REIMAGE_ARTIFACT_ROOT is probably unset or relative." >&2
  exit 2
fi

SECRETS_DIR="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"
STAGED_DIR="$SECRETS_DIR/staged-loose"
REPORTS_DIR="$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports"
MANIFEST="$STAGED_DIR/MANIFEST.tsv"

# ── Secret shapes ────────────────────────────────────────────────────────────
if ! declare -f build_secret_shape_predicate >/dev/null 2>&1; then
  echo "ERROR: shared config did not provide build_secret_shape_predicate." >&2
  echo "Update .internal/artifact-config.sh — it defines the secret-shape floor." >&2
  exit 2
fi

build_secret_shape_predicate SECRET_SHAPE_PRED

if (( ${#SECRET_SHAPE_PRED[@]} == 0 )); then
  echo "ERROR: the secret-shape list resolved to nothing; refusing to sweep on an" >&2
  echo "empty pattern set." >&2
  exit 2
fi

# ── Sweep ────────────────────────────────────────────────────────────────────
log_section "Loose secret staging"
echo -e "  ${DIM}Artifact root: $REIMAGE_ARTIFACT_ROOT${RST}"
echo -e "  ${DIM}Destination  : secrets-encrypted/staged-loose/${RST}"
if $APPLY; then
  echo -e "  ${YEL}Mode         : APPLY — files will be moved${RST}"
else
  echo -e "  ${GRN}Mode         : dry run — nothing will be touched${RST}"
fi
echo ""

moved=0
would_move=0
kept=0
collisions=0
failures=0

keep_matches() {
  local rel="$1" glob
  for glob in ${KEEP_GLOBS[@]+"${KEEP_GLOBS[@]}"}; do
    # shellcheck disable=SC2053
    [[ "$rel" == $glob ]] && return 0
  done
  return 1
}

while IFS= read -r -d '' src; do
  rel="${src#"$REIMAGE_ARTIFACT_ROOT"/}"

  if keep_matches "$rel"; then
    kept=$(( kept + 1 ))
    if $VERBOSE; then
      printf "    ${DIM}KEEP     %s${RST}\n" "$rel"
    fi
    continue
  fi

  dst="$STAGED_DIR/$rel"

  if [[ -e "$dst" ]]; then
    collisions=$(( collisions + 1 ))
    printf "    ${YEL}EXISTS   %s${RST}\n" "$rel"
    printf "             ${DIM}already staged; source left in place${RST}\n"
    continue
  fi

  if ! $APPLY; then
    would_move=$(( would_move + 1 ))
    printf "    ${CYN}WOULD    %s${RST}\n" "$rel"
    continue
  fi

  # A failed move must not abort the sweep: the remaining files still need
  # staging, and a half-swept root before the DMG is the worst outcome.
  if mkdir -p "$(dirname "$dst")" && mv "$src" "$dst"; then
    chmod 600 "$dst" 2>/dev/null || true
    moved=$(( moved + 1 ))
    printf "    ${GRN}STAGED   %s${RST}\n" "$rel"
    printf '%s\t%s\t%s\n' \
      "$(date '+%Y-%m-%d %H:%M:%S')" "$rel" "secrets-encrypted/staged-loose/$rel" >> "$MANIFEST"
  else
    failures=$(( failures + 1 ))
    printf "    ${RED}FAILED   %s${RST}\n" "$rel"
  fi
done < <(
  find "$REIMAGE_ARTIFACT_ROOT" -type f \
    ! -path "$SECRETS_DIR/*" \
    ! -path "$REPORTS_DIR/*" \
    ! -name '.DS_Store' ! -name '._*' \
    \( "${SECRET_SHAPE_PRED[@]}" \) \
    -print0 2>/dev/null | sort -z
)

# The manifest header is written on first use only, and after the first row
# exists so an --apply that stages nothing does not create an empty file.
if [[ -f "$MANIFEST" ]] && ! head -1 "$MANIFEST" | grep -q '^# staged-loose'; then
  tmp="$MANIFEST.$$.tmp"
  {
    echo "# staged-loose manifest — appended by bin/stage-loose-secrets.sh"
    echo "# Credential-shaped files swept out of the plaintext artifact tree so"
    echo "# the Phase 3C DMG encrypts them. Restore reads the source column to"
    echo "# put each file back where it came from."
    printf '# staged-at\tsource-path\tstaged-path\n'
    cat "$MANIFEST"
  } > "$tmp"
  mv "$tmp" "$MANIFEST"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
if $APPLY; then
  printf "  %-22s %s\n" "staged:" "$moved"
else
  printf "  %-22s %s\n" "would stage:" "$would_move"
fi
(( collisions > 0 )) && printf "  %-22s %s\n" "already staged:" "$collisions"
(( kept > 0 ))       && printf "  %-22s %s\n" "kept by --keep:" "$kept"
(( failures > 0 ))   && printf "  %-22s %s\n" "failed:" "$failures"
echo ""

if (( failures > 0 )); then
  echo -e "  ${RED}${BLD}✗ $failures file(s) could not be staged. Nothing was deleted.${RST}"
  echo -e "  ${YEL}Resolve the cause and re-run; staging is idempotent.${RST}"
  echo ""
  exit 1
fi

# A collision is not benign: the source is still sitting in the clear, and
# refusing to overwrite is what keeps it that way. Say how to resolve it, or the
# run reads as "handled" when the plaintext copy is still on the drive.
if (( collisions > 0 )); then
  echo -e "  ${YEL}${BLD}$collisions file(s) are still in plaintext because a staged copy already exists.${RST}"
  echo -e "  ${DIM}This is what a re-run of an earlier phase looks like. Compare the two:${RST}"
  echo -e "  ${DIM}  diff \"\$REIMAGE_ARTIFACT_ROOT/<path>\" \\\\${RST}"
  echo -e "  ${DIM}       \"\$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/staged-loose/<path>\"${RST}"
  echo -e "  ${DIM}Identical: delete the plaintext source. Source is newer: delete the staged${RST}"
  echo -e "  ${DIM}copy and re-run this script. Either way check-loose-secrets.sh still${RST}"
  echo -e "  ${DIM}reports the source until one of them is gone.${RST}"
  echo ""
fi

if $APPLY; then
  if (( moved > 0 )); then
    echo -e "  ${GRN}${BLD}✓ $moved file(s) staged for encryption.${RST}"
    echo -e "  ${DIM}Manifest: $MANIFEST${RST}"
    echo -e "  ${DIM}Confirm the tree is clean:  ./bin/check-loose-secrets.sh${RST}"
  else
    echo -e "  ${GRN}${BLD}✓ Nothing to stage — no loose credential-shaped files found.${RST}"
  fi
else
  if (( would_move > 0 )); then
    echo -e "  ${CYN}${BLD}Review the list above, then stage it:${RST}"
    echo -e "  ${CYN}  ./bin/stage-loose-secrets.sh --apply${RST}"
    echo -e "  ${DIM}Keep something where it is with: --keep '<path-glob>'${RST}"
  else
    echo -e "  ${GRN}${BLD}✓ Nothing to stage — no loose credential-shaped files found.${RST}"
  fi
fi
echo ""
exit 0
