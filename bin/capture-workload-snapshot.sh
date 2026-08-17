#!/usr/bin/env bash
# =============================================================================
# capture-workload-snapshot.sh
#
# Point-in-time Office workload snapshot (Phase 4D pre-image / Phase 13E
# post-image). Writes one timestamped text file capturing visible apps, main
# workload processes, top CPU/memory users, installer/update/management
# processes, Office app bundle status, crash reports newer than the current
# watcher marker, and the latest watcher logs. It observes and records only.
# Run it at each stage of the exercise window (see capture-office-stability.md,
# Step 2), and immediately after any unexpected Outlook/OneNote close.
#
# Output goes to the local watcher directory ($OFFICE_WATCH); this script does
# not read or require REIMAGE_ARTIFACT_ROOT. Shared config is loaded solely to
# resolve OFFICE_WATCH.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/capture-workload-snapshot.sh
#
#   # Capture a snapshot now
#   ./bin/capture-workload-snapshot.sh
#
#   # Capture a snapshot and open it afterwards
#   ./bin/capture-workload-snapshot.sh --open
#
# Writes a point-in-time Office workload snapshot to:
#   $OFFICE_WATCH/workload-snapshot-YYYYMMDD-HHMMSS.txt
#
# Options:
#   --office-watch-dir PATH
#                         Local watcher directory for this invocation; overrides
#                         OFFICE_WATCH. Parity with office-stability-checklist.sh.
#   --open                Open the snapshot when it is written. Off by default:
#                         this runs repeatedly during the measured window, and
#                         opening a window changes what the next snapshot sees.
#   -h, --help            Show this message and exit.
#
# Required configuration:
#   OFFICE_WATCH          Local watcher directory the snapshot is written to.
#                         Required; comes from reimage.env. Created if missing.
#   OFFICE_WATCH_DIR      Optional per-invocation override of OFFICE_WATCH,
#                         resolved the same way in watch-office-today.sh and
#                         capture-office-stability.sh. Takes precedence over
#                         OFFICE_WATCH when set; --office-watch-dir overrides it
#                         for this invocation.
#
# REIMAGE_ARTIFACT_ROOT is never read; nothing is copied to the artifact root.
#
# Configuration precedence:
#   1. Environment values already exported by the caller or optional .envrc.
#   2. Values loaded from reimage.env.
#   3. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Exit status:
#   0  Snapshot written successfully.
#   1  Snapshot run failed (for example the output file could not be written).
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

# This snapshot writes only to $OFFICE_WATCH; the artifact root is not needed,
# so keep loading permissive.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

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

# Opening the snapshot is off by default: this runs at every workload stage and
# after every unexpected close, and each `open` puts a new window inside the
# very window being measured.
OPEN_RESULT=false
# Resolved identically in watch-office-today.sh and capture-office-stability.sh
# so the snapshot lands where the collector reads.
OFFICE_WATCH_DIR="${OFFICE_WATCH_DIR:-${OFFICE_WATCH:-}}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --office-watch-dir)
      require_option_value "$1" "${2:-}"
      OFFICE_WATCH_DIR="$2"
      shift 2
      ;;
    --open)
      OPEN_RESULT=true
      shift
      ;;
    --help|-h)
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

# ---------------------------------------------------------------------------
# Resolve the local watcher directory
# ---------------------------------------------------------------------------
# OFFICE_WATCH is a real reimage.env value; OFFICE_WATCH_DIR is an optional
# per-invocation override, also settable with --office-watch-dir.
DIR="$OFFICE_WATCH_DIR"
if [[ -z "$DIR" ]]; then
  echo "ERROR: OFFICE_WATCH is not set." >&2
  echo "Create/source reimage.env so the snapshot has a home." >&2
  exit 2
fi
mkdir -p "$DIR"

OUT="$DIR/workload-snapshot-$(date +%Y%m%d-%H%M%S).txt"

# Best-effort capture: individual probes are allowed to fail without aborting
# the snapshot (`|| true`), preserving the source's set -u behavior under the
# stricter set -euo pipefail of an operational entrypoint.
{
  echo "=== Timestamp ==="
  date

  echo
  echo "=== Visible macOS apps ==="
  osascript -e 'tell application "System Events" to get name of (application processes where background only is false)' \
    | tr ',' '\n' \
    | sed 's/^ *//' \
    | sort || true

  echo
  echo "=== Main workload processes ==="
  ps -axo pid,ppid,etime,stat,%cpu,%mem,rss,command \
    | grep -E "Microsoft Outlook|Microsoft OneNote|Microsoft Teams|Visual Studio Code|Code Helper|IntelliJ|idea|Docker|com.docker|Google Chrome|Chrome Helper|Obsidian|Terminal|zsh|bash|watch-office" \
    | grep -v grep || true

  echo
  echo "=== Top memory users ==="
  ps -axo pid,ppid,etime,stat,%cpu,%mem,rss,command \
    | sort -k7 -nr \
    | head -40 || true

  echo
  echo "=== Top CPU users ==="
  ps -axo pid,ppid,etime,stat,%cpu,%mem,rss,command \
    | sort -k5 -nr \
    | head -40 || true

  echo
  echo "=== Installer/update/management processes ==="
  ps -axo pid,ppid,etime,stat,%cpu,%mem,command \
    | grep -E "installer|installd|Microsoft AutoUpdate|Microsoft Update Assistant|com.microsoft.autoupdate|appstoreagent|stored|Company Portal|Intune|jamf|Self Service|ManagedClient|mdmclient" \
    | grep -v grep || true

  echo
  echo "=== Office app bundle status ==="
  for app in "Microsoft Outlook" "Microsoft OneNote" "Microsoft Word" "Microsoft Excel" "Microsoft PowerPoint" "Microsoft Teams"; do
    APP="/Applications/$app.app"
    echo
    echo "===== $app ====="
    if [[ -d "$APP" ]]; then
      echo "EXISTS: $APP"
      /usr/bin/stat -f "modified=%Sm path=%N" -t "%Y-%m-%d %H:%M:%S" "$APP" 2>&1 || true
      /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || true
      /usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Contents/Info.plist" 2>/dev/null || true
    else
      echo "MISSING: $APP"
    fi
  done

  echo
  echo "=== Crash reports newer than current watcher marker ==="
  MARKER="$DIR/bundle-watch-start.marker"
  if [[ -e "$MARKER" ]]; then
    /usr/bin/stat -f "marker=%N modified=%Sm" -t "%Y-%m-%d %H:%M:%S" "$MARKER" 2>&1 || true
    find "$HOME/Library/Logs/DiagnosticReports" "/Library/Logs/DiagnosticReports" \
      -maxdepth 1 -type f -newer "$MARKER" \
      \( -iname "*Outlook*.ips" -o -iname "*Outlook*.crash" \
         -o -iname "*OneNote*.ips" -o -iname "*OneNote*.crash" \) \
      -print 2>/dev/null | sort || true
  else
    echo "Marker missing: $MARKER"
  fi

  echo
  echo "=== Latest watcher logs ==="
  ls -lt "$DIR"/bundle-watch-*.log 2>/dev/null | head -5 || true

} > "$OUT"

echo "Wrote: $OUT"
if [[ "$OPEN_RESULT" == "true" ]]; then
  open "$OUT" 2>/dev/null || true
fi
