#!/usr/bin/env bash
# =============================================================================
# backup-app-config.sh
#
# Internal helper for backup-apps.sh (Phase 2D). Registry-driven, generic
# capture of app configuration files and folders. The entrypoint owns the
# single source of truth (supported_apps_registry) and passes each detected
# app's resolved source paths and destinations explicitly; this helper only
# copies what it is told to copy. Non-secret sources land under the app's
# app-settings-backup/<app>/ folder; secret-bearing sources land under
# secrets-encrypted/<app>/ for the later Phase 3B encrypted DMG.
#
# This is the one authoritative capture path for the simple "copy these files"
# apps (Claude, draw.io, Zoom, Mos, Wireshark, ...). Apps whose backup is a
# real app-UI export (Fiddler Everywhere, TNAS PC) are NOT driven through here;
# they stay manual in the runbook. Docker, IntelliJ, and VS Code keep their own
# dedicated helpers/logic and are not routed here either.
#
# This file lives in .internal/apps/ and is normally invoked by
# bin/backup-apps.sh. Shared reimage config is intentionally NOT loaded here;
# the caller passes resolved paths explicitly. It is safe to run standalone
# when --app, --dest, and at least one --path (or --secret-path with
# --secret-dest) are supplied.
#
# --- BEGIN USAGE ---
# Usage:
#   # Normal (through the entrypoint, per detected registry app)
#   ./bin/backup-apps.sh
#   ./bin/backup-apps.sh --apps-only
#
#   # Standalone, non-secret sources only
#   .internal/apps/backup-app-config.sh \
#     --app Wireshark \
#     --dest /path/to/reimage-artifact-root/app-settings-backup/wireshark \
#     --path "$HOME/.config/wireshark"
#
#   # Standalone, with a secret-bearing source staged separately
#   .internal/apps/backup-app-config.sh \
#     --app Claude \
#     --dest /path/to/reimage-artifact-root/app-settings-backup/claude \
#     --secret-dest /path/to/reimage-artifact-root/secrets-encrypted/claude \
#     --secret-path "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
#
# Options:
#   --app LABEL         Human-readable app name (used in output and manifest). Required.
#   --dest PATH         Non-secret destination folder. Required when any --path is given.
#   --secret-dest PATH  Secret-bearing destination folder. Required when any --secret-path is given.
#   --path SRC          Non-secret source file or directory to capture. Repeatable.
#   --secret-path SRC   Secret-bearing source file or directory to stage. Repeatable.
#   -h, --help          Show this message and exit.
#
# A source that does not exist is skipped (recorded), not an error: the same
# registry row is used on every Mac, and not every app is installed everywhere.
#
# Exit status:
#   0  Completed (including when every source was simply absent).
#   1  A copy that should have succeeded failed.
#   2  Usage or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -euo pipefail

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

APP=""
DEST=""
SECRET_DEST=""
PATHS=()
SECRET_PATHS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      require_option_value "$1" "${2:-}"
      APP="$2"; shift 2 ;;
    --dest)
      require_option_value "$1" "${2:-}"
      DEST="$2"; shift 2 ;;
    --secret-dest)
      require_option_value "$1" "${2:-}"
      SECRET_DEST="$2"; shift 2 ;;
    --path)
      require_option_value "$1" "${2:-}"
      PATHS+=("$2"); shift 2 ;;
    --secret-path)
      require_option_value "$1" "${2:-}"
      SECRET_PATHS+=("$2"); shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

if [[ -z "$APP" ]]; then
  echo "ERROR: --app LABEL is required." >&2
  usage >&2
  exit 2
fi

# Guard empty-array expansions for Bash 3.2 under set -u.
if (( ${#PATHS[@]} > 0 )) && [[ -z "$DEST" ]]; then
  echo "ERROR: --dest PATH is required when --path is given." >&2
  usage >&2
  exit 2
fi

if (( ${#SECRET_PATHS[@]} > 0 )) && [[ -z "$SECRET_DEST" ]]; then
  echo "ERROR: --secret-dest PATH is required when --secret-path is given." >&2
  usage >&2
  exit 2
fi

if (( ${#PATHS[@]} == 0 )) && (( ${#SECRET_PATHS[@]} == 0 )); then
  echo "ERROR: nothing to capture — supply at least one --path or --secret-path." >&2
  usage >&2
  exit 2
fi

# copy_one SRC DEST_DIR — copy a file or directory into DEST_DIR under its own
# basename. Idempotent for directories (mirror) and files (cp -p). Missing
# source is a caller-recorded skip, handled before this is called. Returns
# nonzero only on a real copy failure.
copy_one() {
  local src="$1"
  local dest_dir="$2"
  local base target
  base="$(basename "$src")"
  [[ -n "$base" ]] || { echo "ERROR: refusing to copy empty basename from: $src" >&2; return 1; }
  mkdir -p "$dest_dir"
  if [[ -d "$src" ]]; then
    target="$dest_dir/$base"
    # Prefer rsync (present on stock macOS) for a clean metadata-preserving
    # mirror; fall back to cp -R where rsync is unavailable. Both are idempotent:
    # rsync updates in place, the cp path rebuilds the target from scratch.
    # .DS_Store is Finder metadata — never worth capturing.
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --exclude '.DS_Store' "$src/" "$target/"
    else
      rm -rf "$target"
      mkdir -p "$target"
      cp -R "$src/." "$target/"
      find "$target" -name '.DS_Store' -type f -delete 2>/dev/null || true
    fi
  elif [[ "$base" == ".DS_Store" ]]; then
    return 0
  else
    cp -p "$src" "$dest_dir/$base"
  fi
}

COPIED=0
SKIPPED=0
SECRET_COPIED=0
FAILED=0

echo ""
echo "App config capture — $APP  ($(date '+%Y-%m-%d %H:%M:%S'))"

# ── Non-secret sources ────────────────────────────────────────────────────────
if (( ${#PATHS[@]} > 0 )); then
  for src in "${PATHS[@]}"; do
    if [[ -e "$src" ]]; then
      if copy_one "$src" "$DEST"; then
        echo "  copied   $src"
        COPIED=$((COPIED + 1))
      else
        echo "  FAILED   $src" >&2
        FAILED=$((FAILED + 1))
      fi
    else
      echo "  skipped  $src  (not found)"
      SKIPPED=$((SKIPPED + 1))
    fi
  done
fi

# ── Secret-bearing sources ────────────────────────────────────────────────────
if (( ${#SECRET_PATHS[@]} > 0 )); then
  for src in "${SECRET_PATHS[@]}"; do
    if [[ -e "$src" ]]; then
      if copy_one "$src" "$SECRET_DEST"; then
        echo "  staged   $src  -> secrets-encrypted/"
        SECRET_COPIED=$((SECRET_COPIED + 1))
      else
        echo "  FAILED   $src" >&2
        FAILED=$((FAILED + 1))
      fi
    else
      echo "  skipped  $src  (not found)"
      SKIPPED=$((SKIPPED + 1))
    fi
  done
fi

echo "  summary  $APP: $COPIED copied, $SECRET_COPIED staged as secret, $SKIPPED skipped"

if (( FAILED > 0 )); then
  echo "ERROR: $APP: $FAILED source(s) failed to copy." >&2
  exit 1
fi

exit 0
