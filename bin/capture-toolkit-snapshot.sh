#!/usr/bin/env bash
# =============================================================================
# capture-toolkit-snapshot.sh
#
# Toolkit snapshot capture (Phase 4A pre-image / Phase 13A post-image).
#
# Every other capture in this workflow records something about the Mac. This one
# records what produced the artifacts: the runbooks followed, the artifact-config
# and staged-certs fragments the scripts actually read, and the reimage.env that
# resolved every path. Without it the drive holds a backup with no account of the
# toolkit state that built it, and a rerun days later cannot be told apart from
# the first pass.
#
# Each run writes a self-contained timestamped bundle under toolkit-snapshot/
# holding docs/ and config/, so a later run never overwrites an earlier run's
# record. A latest-docs symlink at the toolkit-snapshot root gives restore-time
# readers one stable path into the newest docs/ without hunting for a timestamp.
#
# Non-secret reference material only. It does not replace the encrypted secrets
# DMG workflow. See capture-toolkit-snapshot.md for the full runbook.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/capture-toolkit-snapshot.sh
#
#   # Default -- pre-image bundle under
#   #   toolkit-snapshot/pre-image-toolkit-snapshot-<stamp>/
#   ./bin/capture-toolkit-snapshot.sh
#
#   # Post-image bundle (Phase 13A)
#   ./bin/capture-toolkit-snapshot.sh --context post-image
#
#   # Override the artifact root for this invocation
#   ./bin/capture-toolkit-snapshot.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Reveal the bundle in Finder after completion
#   ./bin/capture-toolkit-snapshot.sh --open
#
#   # Re-capture only the config fragments after editing them mid-workflow
#   ./bin/capture-toolkit-snapshot.sh --config-only
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --context LABEL       pre-image | post-image | pre-image-<label> | post-image-<label>.
#                         Prefix for the timestamped bundle, pointer, and alias.
#                         Default: pre-image.
#   --config-only         Capture config/ only, into its own timestamped
#                         <context>-toolkit-config-<stamp>/ directory. Use after
#                         editing artifact-config or staged-certs fragments
#                         partway through a multi-day run. Leaves the docs
#                         snapshot and its latest-docs symlink untouched.
#   --open                Open the snapshot bundle in Finder after completion.
#   -h, --help            Show this message and exit.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Exit status:
#   0  Capture completed successfully.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Locate repository and load shared reimage config
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"

if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi

ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

# ── Colors and section helpers (shared house style) ─────────────────────────
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'
hr()      { printf '%s\n' "────────────────────────────────────────────────────────" ; }
thin_hr() { printf '%s\n' "  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄" ; }
log_section() { echo ""; echo -e "${BLD}${CYN}▸ $1${RST}"; thin_hr; }

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

OPEN_AFTER=false
CONFIG_ONLY=false
CONTEXT="pre-image"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "ERROR: --artifact-root requires a non-empty value." >&2
        usage >&2
        exit 2
      fi
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --context)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "ERROR: --context requires a value." >&2
        usage >&2
        exit 2
      fi
      CONTEXT="$2"
      shift 2
      ;;
    --config-only)
      CONFIG_ONLY=true
      shift
      ;;
    --open)
      OPEN_AFTER=true
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

# Validate the run-directory context, consistent with capture-managed-inventory.sh.
case "$CONTEXT" in
  pre-image|post-image|pre-image-?*|post-image-?*)
    case "$CONTEXT" in
      *[/\\]*|*..*|.*|*[[:space:]]*)
        echo "ERROR: --context must not contain slashes, '..', a leading dot, or whitespace, got: $CONTEXT" >&2
        exit 2
        ;;
    esac
    ;;
  *)
    echo "ERROR: --context must be pre-image, post-image, or start with pre-image- or post-image- (e.g. post-image-recheck), got: $CONTEXT" >&2
    exit 2
    ;;
esac

# Human-readable title derived from the context (e.g. pre-image -> "Pre-Image",
# post-image-recheck -> "Post-Image-Recheck"), used for README headings.
CONTEXT_TITLE=""
_context_ifs_save="$IFS"
IFS='-'
for _context_word in $CONTEXT; do
  _context_first="$(printf '%s' "${_context_word:0:1}" | tr '[:lower:]' '[:upper:]')"
  CONTEXT_TITLE="${CONTEXT_TITLE:+$CONTEXT_TITLE-}${_context_first}${_context_word:1}"
done
IFS="$_context_ifs_save"
unset _context_ifs_save _context_word _context_first

# ---------------------------------------------------------------------------
# Resolve and validate the artifact root after command-line parsing
# ---------------------------------------------------------------------------
if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set." >&2
  echo "Create/source reimage.env or pass --artifact-root PATH." >&2
  exit 2
fi

if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: artifact root not found: $REIMAGE_ARTIFACT_ROOT" >&2
  exit 2
fi

# Safety invariant: the snapshot must not be written inside the repo checkout.
# A copy under the working tree is not a real backup and usually signals an
# unset or relative artifact-root variable.
if [[ "$REIMAGE_ARTIFACT_ROOT" == "$REPO_ROOT" || "$REIMAGE_ARTIFACT_ROOT" == "$REPO_ROOT"/* ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $REIMAGE_ARTIFACT_ROOT" >&2
  exit 2
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
TOOLKIT_SNAPSHOT_ROOT="$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot"

# Two run series share this root. A full snapshot carries docs/ and config/; a
# --config-only run carries config/ alone and is named distinctly so a bundle's
# name always tells you what is inside it. Neither series ever rewrites an
# earlier run -- that immutability is the whole point of the capture.
if [[ "$CONFIG_ONLY" == true ]]; then
  RUN_KIND="config"
  RUN_KIND_TITLE="Config"
  OUT="$TOOLKIT_SNAPSHOT_ROOT/${CONTEXT}-toolkit-config-$STAMP"
  POINTER_FILE="$TOOLKIT_SNAPSHOT_ROOT/latest-${CONTEXT}-toolkit-config.txt"
  ALIAS_NAME="latest-${CONTEXT}-toolkit-config"
else
  RUN_KIND="snapshot"
  RUN_KIND_TITLE="Snapshot"
  OUT="$TOOLKIT_SNAPSHOT_ROOT/${CONTEXT}-toolkit-snapshot-$STAMP"
  POINTER_FILE="$TOOLKIT_SNAPSHOT_ROOT/latest-${CONTEXT}-toolkit-snapshot.txt"
  ALIAS_NAME="latest-${CONTEXT}-toolkit-snapshot"
fi

DOCS_DEST="$OUT/docs"
CONFIG_DEST="$OUT/config"
mkdir -p "$OUT/logs" "$CONFIG_DEST"

refresh_latest_alias() {
  local alias_name="$1"
  local target_rel="$2"
  local alias_path="$TOOLKIT_SNAPSHOT_ROOT/$alias_name"

  if [[ -L "$alias_path" || ! -e "$alias_path" ]]; then
    ln -sfn "$target_rel" "$alias_path" 2>/dev/null || true
  else
    echo "NOTE: leaving existing non-symlink in place: $alias_path" >&2
  fi
}

echo ""
hr
echo -e "${BLD}Toolkit snapshot${RST}  ${DIM}(${CONTEXT}, ${RUN_KIND})${RST}"
echo -e "  Artifact root : ${BLD}$REIMAGE_ARTIFACT_ROOT${RST}"
echo -e "  Bundle        : ${BLD}$OUT${RST}"
hr

# ---------------------------------------------------------------------------
# Documentation snapshot (full runs only)
# ---------------------------------------------------------------------------
DOCS_COUNT=0
if [[ "$CONFIG_ONLY" != true ]]; then
  log_section "Toolkit documentation"
  mkdir -p "$DOCS_DEST/templates"

  # Preserve the workflow Markdown as it stood for this run. Active helper
  # script source is deliberately not copied -- scripts live in the toolkit Git
  # repository. reimaging-scripts-guide.md sits at the repo root, so the
  # repo-root *.md glob already carries it.
  find "$REPO_ROOT" -maxdepth 1 -type f -name '*.md' -exec cp -p {} "$DOCS_DEST/" \;
  cp -p "$REPO_ROOT/templates/"*.md "$DOCS_DEST/templates/" 2>/dev/null || true

  DOCS_COUNT="$(find "$DOCS_DEST" -type f -name '*.md' | wc -l | tr -d ' ')"
  printf "  ${GRN}✓  %-30s  %s file(s)${RST}\n" "docs/" "$DOCS_COUNT"

  # One stable path for restore-time readers, so a bare Mac does not have to
  # resolve the newest timestamp by hand.
  refresh_latest_alias "latest-docs" "$(basename "$OUT")/docs"
  printf "  ${DIM}   latest-docs -> %s/docs${RST}\n" "$(basename "$OUT")"
fi

# ---------------------------------------------------------------------------
# Config fragments -- what the scripts actually read for this run
# ---------------------------------------------------------------------------
log_section "Config fragments"

ARTIFACT_CONFIG_TEMPLATES="$REPO_ROOT/.internal/templates/artifact-config"
ARTIFACT_CONFIG_DIR_USED="${ARTIFACT_CONFIG_SOURCE_DIR:-}"
if [[ "$ARTIFACT_CONFIG_DIR_USED" == "$ARTIFACT_CONFIG_TEMPLATES" ]]; then
  ARTIFACT_CONFIG_ORIGIN="committed-template"
else
  ARTIFACT_CONFIG_ORIGIN="workspace"
fi

# Both fragment directories are resolved once by .internal/artifact-config.sh;
# this capture only records which copy the run resolved to.
STAGED_CERTS_DIR_USED="${STAGED_CERTS_SOURCE_DIR:-}"
if [[ "$STAGED_CERTS_DIR_USED" == "${STAGED_CERTS_TEMPLATE_DIR:-}" ]]; then
  STAGED_CERTS_ORIGIN="committed-template"
else
  STAGED_CERTS_ORIGIN="workspace"
fi

copy_fragment_dir() {
  local label="$1" src="$2" origin="$3"
  local dst="$CONFIG_DEST/$label"

  if [[ -z "$src" || ! -d "$src" ]]; then
    printf "  ${YEL}⚠  %-30s  not resolved, skipping${RST}\n" "$label/"
    return 0
  fi

  mkdir -p "$dst"
  find "$src" -maxdepth 1 -type f -name '*.conf.sh' -exec cp -p {} "$dst/" \;
  local n; n="$(find "$dst" -type f -name '*.conf.sh' | wc -l | tr -d ' ')"
  if [[ "$origin" == "committed-template" ]]; then
    printf "  ${YEL}⚠  %-30s  %s fragment(s) — committed template, not this Mac's${RST}\n" "$label/" "$n"
  else
    printf "  ${GRN}✓  %-30s  %s fragment(s)${RST}\n" "$label/" "$n"
  fi
}

copy_fragment_dir "artifact-config" "$ARTIFACT_CONFIG_DIR_USED" "$ARTIFACT_CONFIG_ORIGIN"
copy_fragment_dir "staged-certs" "$STAGED_CERTS_DIR_USED" "$STAGED_CERTS_ORIGIN"

REIMAGE_ENV_USED="${REIMAGE_ENV:-}"
if [[ -n "$REIMAGE_ENV_USED" && -f "$REIMAGE_ENV_USED" ]]; then
  cp -p "$REIMAGE_ENV_USED" "$CONFIG_DEST/reimage.env"
  printf "  ${GRN}✓  %-30s  %s${RST}\n" "reimage.env" "$REIMAGE_ENV_USED"
else
  printf "  ${YEL}⚠  %-30s  not found, skipping${RST}\n" "reimage.env"
fi

cat > "$CONFIG_DEST/SOURCES.txt" <<EOF
Captured:      $(date '+%Y-%m-%d %H:%M:%S')
Host:          $(hostname)
Context:       $CONTEXT
Run kind:      $RUN_KIND
Artifact root: $REIMAGE_ARTIFACT_ROOT
Repo root:     $REPO_ROOT

Which copy of each config input this run actually read. An origin of
"committed-template" means the workspace copy was missing and the run fell back
to the repo's generic examples -- treat any artifact produced alongside it as
suspect.

artifact-config
  source: ${ARTIFACT_CONFIG_DIR_USED:-<unresolved>}
  origin: $ARTIFACT_CONFIG_ORIGIN

staged-certs
  source: $STAGED_CERTS_DIR_USED
  origin: $STAGED_CERTS_ORIGIN

reimage.env
  source: ${REIMAGE_ENV_USED:-<unresolved>}

Workspace root: ${REIMAGE_WORKSPACE_ROOT:-<unset>}
EOF
printf "  ${GRN}✓  %-30s${RST}\n" "SOURCES.txt"

# ---------------------------------------------------------------------------
# Bundle README, pointer, aliases
# ---------------------------------------------------------------------------
cat > "$TOOLKIT_SNAPSHOT_ROOT/README.md" <<EOF
# Toolkit Snapshot

What produced the artifacts on this drive: the runbooks followed, the config
fragments the scripts read, and the reimage.env that resolved every path.
Every other capture under the artifact root describes the Mac; this one
describes the toolkit.

Full snapshot bundles (docs + config):

- \`<context>-toolkit-snapshot-YYYYMMDD-HHMMSS/\`

Config-only refreshes, written when fragments change partway through a run:

- \`<context>-toolkit-config-YYYYMMDD-HHMMSS/\`

Each bundle is self-contained and is never rewritten by a later run. Latest
pointers and convenience symlinks:

- \`latest-<context>-toolkit-snapshot.txt\` and \`latest-<context>-toolkit-snapshot\`
- \`latest-<context>-toolkit-config.txt\` and \`latest-<context>-toolkit-config\`
- \`latest-docs\` -> the newest full snapshot's \`docs/\`, a stable path to read
  the runbooks from on a freshly reimaged Mac

The timestamped bundle is the source of truth. The aliases exist for validation
compatibility and quick restore review.
EOF

cat > "$OUT/README.md" <<EOF
# ${CONTEXT_TITLE} Toolkit ${RUN_KIND_TITLE}

Generated: $(date '+%Y-%m-%d %H:%M:%S')
Host: $(hostname)
Artifact root: $REIMAGE_ARTIFACT_ROOT
Context: $CONTEXT

## Contents

- \`config/\` — the artifact-config and staged-certs fragments plus the
  reimage.env this run read. \`config/SOURCES.txt\` records where each came
  from and whether it was this Mac's copy or a committed fallback.
$(if [[ "$CONFIG_ONLY" != true ]]; then
    printf '%s\n' "- \`docs/\` — the runbooks and templates as they stood for this run."
  else
    printf '%s\n' "- No \`docs/\` — this was a --config-only refresh. The docs snapshot from the"
    printf '%s\n' "  most recent full run is unchanged and still reachable through latest-docs."
  fi)

## Why this bundle exists

A backup with no record of the toolkit that produced it cannot be audited later.
This bundle answers which runbook text was followed and which config the scripts
resolved, for this run specifically, on a workflow that may span several days.

## Important

This is not the encrypted secrets backup. Credential-bearing files belong in the
consolidated secrets DMG workflow.
EOF

printf '%s\n' "$OUT" > "$POINTER_FILE"
refresh_latest_alias "$ALIAS_NAME" "$(basename "$OUT")"

cat > "$OUT/logs/latest-aliases.txt" <<EOF
Bundle:         $OUT
Pointer file:   $POINTER_FILE
Alias:          $TOOLKIT_SNAPSHOT_ROOT/$ALIAS_NAME
Docs alias:     $TOOLKIT_SNAPSHOT_ROOT/latest-docs
EOF

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
hr
echo -e "${GRN}${BLD}Toolkit ${RUN_KIND} complete.${RST}"
echo ""
printf "  %-22s  %s\n" "Bundle:" "$OUT"
printf "  %-22s  %s\n" "Size:" "$(du -sh "$OUT" 2>/dev/null | cut -f1)"
if [[ "$CONFIG_ONLY" != true ]]; then
  printf "  %-22s  %s file(s)\n" "Docs captured:" "$DOCS_COUNT"
fi
printf "  %-22s  %s / %s\n" "Config origin:" "$ARTIFACT_CONFIG_ORIGIN" "$STAGED_CERTS_ORIGIN"
printf "  %-22s  %s\n" "Latest pointer:" "$POINTER_FILE"
echo ""
if [[ "$ARTIFACT_CONFIG_ORIGIN" == "committed-template" || "$STAGED_CERTS_ORIGIN" == "committed-template" ]]; then
  echo -e "  ${RED}Config fell back to committed templates — this run did not use this Mac's fragments.${RST}"
  echo -e "  ${DIM}See config/SOURCES.txt. Re-run the relevant init step, then rerun with --config-only.${RST}"
  echo ""
fi

if [[ "$OPEN_AFTER" == true ]]; then
  open "$OUT" 2>/dev/null || true
fi
