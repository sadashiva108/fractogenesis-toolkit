#!/usr/bin/env bash
# =============================================================================
# watch-office-today.sh
#
# Long-running Office stability watcher (Phase 4D pre-image / Phase 13E
# post-image). Every 15 seconds it appends a timestamped block to a
# bundle-watch-*.log recording Outlook/OneNote bundle status, key Outlook
# frameworks, running Office/dev/management processes, new crash reports newer
# than bundle-watch-start.marker, and recent install.log / AutoUpdate events.
# The baseline collector (capture-office-stability.sh) later summarizes these
# logs into an evidence bundle. Runs until interrupted (Control + C); typically
# started under `caffeinate`. See capture-office-stability.md, Step 1.
#
# Output goes to the local watcher directory ($OFFICE_WATCH), NOT the artifact
# root. Shared config is loaded solely to resolve OFFICE_WATCH.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/watch-office-today.sh
#
#   # Start the watcher for a test window (keep the Mac awake)
#   caffeinate -dimsu ./bin/watch-office-today.sh
#
#   # Stop it with Control + C when the window is complete.
#
# Writes a rolling watcher log to:
#   $OFFICE_WATCH/bundle-watch-YYYYMMDD-HHMMSS.log
# and establishes the marker (if missing):
#   $OFFICE_WATCH/bundle-watch-start.marker
#
# Options:
#   -h, --help            Show this message and exit.
#
# Configuration precedence:
#   1. Environment values already exported by the caller or optional .envrc.
#   2. Values loaded from reimage.env.
#   3. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Exit status:
#   0    Not normally reached; the watcher loops until interrupted.
#   2    Usage, configuration, or prerequisite error.
#   130  Interrupted with Control + C (expected stop).
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

# This watcher writes only to $OFFICE_WATCH; the artifact root is not needed,
# so keep loading permissive.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    echo "ERROR: unknown option: $1" >&2
    usage >&2
    exit 2
    ;;
esac

# ---------------------------------------------------------------------------
# Resolve the local watcher directory
# ---------------------------------------------------------------------------
if [[ -z "${OFFICE_WATCH:-}" ]]; then
  echo "ERROR: OFFICE_WATCH is not set." >&2
  echo "Create/source reimage.env so the watcher and marker have a home." >&2
  exit 2
fi
DIR="$OFFICE_WATCH"
mkdir -p "$DIR"

LOG="$DIR/bundle-watch-$(date +%Y%m%d-%H%M%S).log"
MARKER="$DIR/bundle-watch-start.marker"

if [[ ! -e "$MARKER" ]]; then
  touch "$MARKER"
fi

echo "Writing log to: $LOG"
echo "Marker: $MARKER"
echo

while true; do
  {
    echo
    echo "============================================================"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "============================================================"

    for app in "Microsoft Outlook" "Microsoft OneNote"; do
      APP="/Applications/$app.app"
      echo
      echo "=== $app bundle ==="
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
    echo "=== Outlook frameworks ==="
    for target in \
      "/Applications/Microsoft Outlook.app/Contents/Frameworks/HxPlorer.framework/Versions/A/HxPlorer" \
      "/Applications/Microsoft Outlook.app/Contents/Frameworks/CocoaUI.framework/Versions/A/CocoaUI"
    do
      if [[ -e "$target" ]]; then
        /usr/bin/stat -f "EXISTS modified=%Sm size=%z path=%N" -t "%Y-%m-%d %H:%M:%S" "$target" 2>&1 || true
      else
        echo "MISSING: $target"
      fi
    done

    echo
    echo "=== Outlook/OneNote processes ==="
    pgrep -fl "Microsoft Outlook|Microsoft OneNote" || echo "No Outlook/OneNote processes"

    echo
    echo "=== Current visible macOS apps ==="
    osascript -e 'tell application "System Events" to get name of (application processes where background only is false)' \
      | tr ',' '\n' \
      | sed 's/^ *//' \
      | sort || true

    echo
    echo "=== Dev / daily workload processes ==="
    ps -axo pid,ppid,etime,stat,%cpu,%mem,rss,command \
      | grep -E "Microsoft Teams|MSTeams|Visual Studio Code|Code Helper|IntelliJ|idea|Docker|com.docker|Google Chrome|Chrome Helper|Obsidian|Terminal|watch-office|zsh|bash" \
      | grep -v grep || true

    echo
    echo "=== Microsoft updater/management processes ==="
    pgrep -fl "Microsoft AutoUpdate|Microsoft Update Assistant|msupdate|MAU2\.0|Company Portal|Intune|ManagedClient|mdmclient|jamf|Self Service" || true

    echo
    echo "=== Installer / update / management processes ==="
    ps -axo pid,ppid,etime,stat,%cpu,%mem,command \
      | grep -E "installer|installd|Microsoft AutoUpdate|Microsoft Update Assistant|com.microsoft.autoupdate|appstoreagent|stored|Company Portal|Intune|jamf|Self Service" \
      | grep -v grep || true

    echo
    echo "=== New crash reports since watcher started ==="
    find "$HOME/Library/Logs/DiagnosticReports" "/Library/Logs/DiagnosticReports" \
      -maxdepth 1 -type f -newer "$MARKER" \
      \( -iname "*Outlook*.ips" -o -iname "*OneNote*.ips" -o -iname "*Outlook*.crash" -o -iname "*OneNote*.crash" \) \
      -print 2>/dev/null | sort || true

    echo
    echo "=== Last AutoUpdate lines ==="
    tail -8 "/Library/Logs/Microsoft/autoupdate.log" 2>/dev/null || true

    echo
    echo "=== Recent install.log Microsoft events ==="
    grep -Ei "Microsoft|Office|Outlook|OneNote|Word|Excel|PowerPoint|AutoUpdate|forcibly closing|preinstall|postinstall" \
      /var/log/install.log 2>/dev/null | tail -80 || true

    echo
    echo "=== Recent Microsoft AutoUpdate events ==="
    grep -Ei "Outlook|OneNote|Word|Excel|PowerPoint|AutoUpdate|forcibly closing|preinstall|postinstall|restore|clone|install" \
      /Library/Logs/Microsoft/autoupdate.log 2>/dev/null | tail -120 || true

  } | tee -a "$LOG"

  sleep 15
done
