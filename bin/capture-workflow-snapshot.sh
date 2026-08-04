#!/usr/bin/env bash
# =============================================================================
# capture-workflow-snapshot.sh
#
# Workflow snapshot capture (Phase 3A pre-image / Phase 11A post-image): a
# lightweight, non-secret capture that preserves the reimage workflow's own
# documentation and templates alongside a timestamped snapshot bundle, so the
# state of the runbooks that drove this reimage travels with the artifact drive.
# Writes a timestamped bundle under workflow-snapshot/ and refreshes the
# reimage-workflow-docs/ documentation copy in the same pass. It copies
# non-secret workflow reference material only — it does not replace the
# encrypted secrets DMG workflow. See capture-workflow-snapshot.md for the full
# runbook.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/capture-workflow-snapshot.sh
#
#   # Default -- pre-image bundle under
#   #   workflow-snapshot/pre-image-workflow-snapshot-<stamp>/
#   ./bin/capture-workflow-snapshot.sh
#
#   # Post-image bundle (Phase 11A)
#   ./bin/capture-workflow-snapshot.sh --context post-image
#
#   # Override the artifact root for this invocation
#   ./bin/capture-workflow-snapshot.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Reveal the bundle in Finder after completion
#   ./bin/capture-workflow-snapshot.sh --open
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --context LABEL       pre-image | post-image | pre-image-<label> | post-image-<label>.
#                         Prefix for the timestamped bundle, pointer, and alias.
#                         Default: pre-image.
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

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

OPEN_AFTER=false
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
WORKFLOW_SNAPSHOT_ROOT="$REIMAGE_ARTIFACT_ROOT/workflow-snapshot"
OUT="$WORKFLOW_SNAPSHOT_ROOT/${CONTEXT}-workflow-snapshot-$STAMP"
POINTER_FILE="$WORKFLOW_SNAPSHOT_ROOT/latest-${CONTEXT}-workflow-snapshot.txt"
ALIAS_NAME="latest-${CONTEXT}-workflow-snapshot"
mkdir -p "$OUT/logs"

WORKFLOW_DOCS_DEST="$WORKFLOW_SNAPSHOT_ROOT/reimage-workflow-docs"
mkdir -p "$WORKFLOW_DOCS_DEST" "$WORKFLOW_DOCS_DEST/templates"

# Preserve the workflow Markdown available at the time of the reimage. Do not
# copy active helper script source into the artifact root; scripts remain in the
# toolkit Git repository. In this repo the reimaging-scripts-guide.md lives at
# the repo root, so the repo-root *.md glob already carries it.
find "$REPO_ROOT" -maxdepth 1 -type f -name '*.md' -exec cp -p {} "$WORKFLOW_DOCS_DEST/" \;
cp -p "$REPO_ROOT/templates/"*.md "$WORKFLOW_DOCS_DEST/templates/" 2>/dev/null || true

refresh_latest_alias() {
  local alias_name="$1"
  local target_rel="$2"
  local alias_path="$WORKFLOW_SNAPSHOT_ROOT/$alias_name"

  if [[ -L "$alias_path" || ! -e "$alias_path" ]]; then
    ln -sfn "$target_rel" "$alias_path" 2>/dev/null || true
  else
    echo "NOTE: leaving existing non-symlink in place: $alias_path" >&2
  fi
}

cat > "$WORKFLOW_SNAPSHOT_ROOT/README.md" <<EOF
# Workflow Snapshot

Generated workflow snapshot bundles live under:

- ${CONTEXT}-workflow-snapshot-YYYYMMDD-HHMMSS/

The workflow documentation snapshot lives under:

- reimage-workflow-docs/

The latest bundle path for the ${CONTEXT} context is recorded in:

- latest-${CONTEXT}-workflow-snapshot.txt

Convenience symlink may point at the latest bundle:

- latest-${CONTEXT}-workflow-snapshot -> ${CONTEXT}-workflow-snapshot-YYYYMMDD-HHMMSS

The timestamped ${CONTEXT} bundle is the source of truth. The short aliases are for validation compatibility and quick restore review.
EOF

cat > "$OUT/README.md" <<EOF
# ${CONTEXT_TITLE} Workflow Snapshot

Generated: $(date '+%Y-%m-%d %H:%M:%S')
Host: $(hostname)
Artifact root: $REIMAGE_ARTIFACT_ROOT
Context: $CONTEXT

## Purpose

This bundle captures workflow snapshot material that is useful during and after reimage:

- workflow Markdown snapshot under \`workflow-snapshot/reimage-workflow-docs/\`

## Latest bundle aliases

The timestamped bundle is the source of truth. After the run completes, the workflow-snapshot root also contains a latest pointer and convenience symlink for validation compatibility:

- latest-${CONTEXT}-workflow-snapshot.txt
- latest-${CONTEXT}-workflow-snapshot

## Important

This is not the encrypted secrets backup.
Credential-bearing files belong in the consolidated secrets DMG workflow.
EOF

printf '%s\n' "$OUT" > "$POINTER_FILE"
refresh_latest_alias "$ALIAS_NAME" "$(basename "$OUT")"

cat > "$OUT/logs/latest-aliases.txt" <<EOF
Latest workflow-snapshot bundle: $OUT
Pointer file: $POINTER_FILE
Workflow docs snapshot: $WORKFLOW_DOCS_DEST
Alias refreshed when safe:
- $WORKFLOW_SNAPSHOT_ROOT/$ALIAS_NAME
EOF

echo "Created: $OUT"
echo "Workflow docs: $WORKFLOW_DOCS_DEST"
echo "Latest pointer: $POINTER_FILE"
echo "Latest alias:   $WORKFLOW_SNAPSHOT_ROOT/$ALIAS_NAME"

if [[ "$OPEN_AFTER" == true ]]; then
  open "$OUT" 2>/dev/null || true
fi
