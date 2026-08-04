#!/usr/bin/env bash
# =============================================================================
# capture-office-stability.sh
#
# Office stability baseline collector (Phase 3D pre-image / Phase 11E
# post-image). At the end of a clean test window it gathers everything the
# Office watcher recorded that is newer than bundle-watch-start.marker into one
# timestamped, self-contained evidence bundle: numbered section files
# 00-baseline-window.txt .. 08-watcher-running-status.txt plus
# office-stability-summary.md, then a matching .zip. The bundle is written to
# the local watcher directory ($OFFICE_WATCH); when --artifact-root is supplied
# the evidence outputs (bundle, zip, and a top-level summary) are also copied to
# $REIMAGE_ARTIFACT_ROOT/office-stability/. Scripts are never copied to the
# artifact root. See capture-office-stability.md for the full runbook.
#
# Renamed during migration: capture-office-stability-baseline.sh ->
# capture-office-stability.sh (runbook<->script name parity).
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/capture-office-stability.sh
#
#   # Full baseline (normal end-of-window capture), also copied to the artifact root
#   ./bin/capture-office-stability.sh --phase pre-reimage --artifact-root "$REIMAGE_ARTIFACT_ROOT"
#
#   # Post-image baseline
#   ./bin/capture-office-stability.sh --phase post-reimage --artifact-root "$REIMAGE_ARTIFACT_ROOT"
#
#   # Fast incident baseline -- skips the slow unified-log pull
#   ./bin/capture-office-stability.sh --phase pre-reimage --artifact-root "$REIMAGE_ARTIFACT_ROOT" --skip-unified-log
#
#   # Local-only run (no copy to the artifact root)
#   ./bin/capture-office-stability.sh --phase pre-reimage
#
# Creates an Office stability evidence directory under:
#   $OFFICE_WATCH/<phase>-office-baseline-YYYYMMDD-HHMMSS
#
# If --artifact-root is supplied, copies evidence outputs only to:
#   $REIMAGE_ARTIFACT_ROOT/office-stability/
# Scripts are not copied to the artifact root.
#
# Options:
#   --phase PHASE         One of: pre-reimage, pre-image, post-reimage, post-image
#                         (pre-image/post-image are normalized to
#                         pre-reimage/post-reimage). Sets the bundle-name prefix.
#                         Default: pre-reimage.
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config. When
#                         set, evidence outputs are copied to
#                         PATH/office-stability/. When unset, the run stays local
#                         to $OFFICE_WATCH.
#   --skip-unified-log    Skip the slow `log show` unified-log pull; file 07 then
#                         records that it was skipped (fast incident baseline).
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
#   1  Capture ran but a required step (e.g. the artifact-root copy) failed.
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

# The artifact root is optional here: without it the bundle stays local under
# $OFFICE_WATCH. Keep loading permissive so --artifact-root can override after
# parsing, and validate the resolved value only when a copy is requested.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

# Normalize --phase to the office workflow's canonical set so the collector and
# office-stability-checklist.sh agree on bundle prefixes (the checklist's `find`
# looks for pre-reimage-*/post-reimage-* bundles). Identical mapping to the
# checklist. Returns 1 for anything outside the accepted set.
normalize_phase() {
  case "${1:-}" in
    pre|pre-image|preimage|pre-reimage)
      echo "pre-reimage"
      ;;
    post|post-image|postimage|post-reimage)
      echo "post-reimage"
      ;;
    *)
      return 1
      ;;
  esac
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

# ---------------------------------------------------------------------------
# Defaults and command-line state
# ---------------------------------------------------------------------------
TS="$(date +%Y%m%d-%H%M%S)"
PHASE="pre-reimage"
SKIP_UNIFIED=0
OUTDIR=""
# Optional: empty means "no copy to the artifact root" (local-only run).
REIMAGE_ARTIFACT_ROOT="${REIMAGE_ARTIFACT_ROOT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)
      require_option_value "$1" "${2:-}"
      if ! PHASE="$(normalize_phase "$2")"; then
        echo "ERROR: --phase must be one of: pre-reimage, pre-image, post-reimage, post-image (got: $2)" >&2
        usage >&2
        exit 2
      fi
      shift 2
      ;;
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --skip-unified-log)
      SKIP_UNIFIED=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve the local watcher directory (marker + evidence home)
# ---------------------------------------------------------------------------
# OFFICE_WATCH is a real reimage.env value; OFFICE_WATCH_DIR is an optional
# per-invocation override kept from the source script.
DIR="${OFFICE_WATCH_DIR:-${OFFICE_WATCH:-}}"
if [[ -z "$DIR" ]]; then
  echo "ERROR: OFFICE_WATCH is not set." >&2
  echo "Create/source reimage.env so the watcher directory and marker have a home." >&2
  exit 2
fi
MARKER="$DIR/bundle-watch-start.marker"

# Safety invariant: refuse to write the artifact-root copy inside the repo
# checkout -- a copy under the working tree is not a real backup.
if [[ -n "$REIMAGE_ARTIFACT_ROOT" ]]; then
  if [[ "$REIMAGE_ARTIFACT_ROOT" == "$REPO_ROOT" || "$REIMAGE_ARTIFACT_ROOT" == "$REPO_ROOT"/* ]]; then
    echo "ERROR: refusing to copy evidence under the repo checkout: $REIMAGE_ARTIFACT_ROOT" >&2
    exit 2
  fi
  if ! command -v rsync >/dev/null 2>&1; then
    echo "ERROR: rsync is required for --artifact-root copy but was not found on PATH." >&2
    exit 2
  fi
fi

safe_name() {
  printf '%s' "$1" | tr '/ :()[]{}' '________' | tr -cd '[:alnum:]_.-'
}

PHASE_SAFE="$(safe_name "$PHASE")"
OUTDIR="$DIR/${PHASE_SAFE}-office-baseline-$TS"

mkdir -p "$OUTDIR"

if [[ ! -e "$MARKER" ]]; then
  echo "Marker missing; creating: $MARKER"
  mkdir -p "$DIR"
  touch "$MARKER"
fi

START="$(/usr/bin/stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$MARKER" 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')"
END="$(date '+%Y-%m-%d %H:%M:%S')"
LATEST_WATCH="$(ls -t "$DIR"/bundle-watch-*.log 2>/dev/null | head -1 || true)"

{
  echo "=== Office stability baseline capture ==="
  date
  echo "Phase: $PHASE"
  echo
  echo "Marker: $MARKER"
  /usr/bin/stat -f "path=%N modified=%Sm size=%z" -t "%Y-%m-%d %H:%M:%S" "$MARKER" 2>&1 || true
  echo
  echo "Window:"
  echo "START=$START"
  echo "END=$END"
  echo
  echo "Latest watcher:"
  echo "$LATEST_WATCH"
} | tee "$OUTDIR/00-baseline-window.txt"

{
  echo "=== Crash reports newer than marker ==="
  find "$HOME/Library/Logs/DiagnosticReports" "/Library/Logs/DiagnosticReports" \
    -maxdepth 1 -type f -newer "$MARKER" \
    \( -iname "*Outlook*.ips" -o -iname "*Outlook*.crash" \
       -o -iname "*OneNote*.ips" -o -iname "*OneNote*.crash" \) \
    -print 2>/dev/null | sort || true
} | tee "$OUTDIR/01-crash-reports-newer-than-marker.txt"

{
  echo "=== Office bundle status ==="
  echo "Marker:"
  /usr/bin/stat -f "marker modified=%Sm path=%N" -t "%Y-%m-%d %H:%M:%S" "$MARKER" 2>&1 || true
  echo

  for app in \
    "Microsoft Outlook" \
    "Microsoft OneNote" \
    "Microsoft Word" \
    "Microsoft Excel" \
    "Microsoft PowerPoint" \
    "Microsoft Teams"
  do
    APP="/Applications/$app.app"
    echo
    echo "===== $app ====="
    if [[ -d "$APP" ]]; then
      if [[ "$APP" -nt "$MARKER" ]]; then
        echo "CHANGED_AFTER_MARKER: YES"
      else
        echo "CHANGED_AFTER_MARKER: NO"
      fi

      /usr/bin/stat -f "modified=%Sm path=%N" -t "%Y-%m-%d %H:%M:%S" "$APP" 2>&1 || true
      /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || true
      /usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Contents/Info.plist" 2>/dev/null || true
    else
      echo "MISSING: $APP"
    fi
  done
} | tee "$OUTDIR/02-office-bundle-status.txt"

if [[ -n "$LATEST_WATCH" && -f "$LATEST_WATCH" ]]; then
  awk '
  function emit() {
    state=(outlook?"Outlook":"") (onenote?(outlook?"+":"")"OneNote":"")
    if (state=="") state="none"
    if (ts != "" && state != last) {
      print ts " | " state
      last=state
    }
  }
  /^Timestamp:/ {
    ts=substr($0,12)
    next
  }
  /^=== Outlook\/OneNote processes ===/ {
    inproc=1
    outlook=0
    onenote=0
    next
  }
  /^=== / && inproc {
    emit()
    inproc=0
    next
  }
  inproc {
    if ($0 ~ /Microsoft Outlook/) outlook=1
    if ($0 ~ /Microsoft OneNote/) onenote=1
    if ($0 ~ /No Outlook\/OneNote processes/) {
      outlook=0
      onenote=0
    }
  }
  END {
    if (inproc) emit()
  }
  ' "$LATEST_WATCH" | tee "$OUTDIR/03-outlook-onenote-process-transitions.txt"

  grep -nEi \
    "Timestamp:|forcibly closing|Microsoft 365|Microsoft_365_and_Office|BusinessPro_Installer|Installed \"Microsoft 365|preinstall|postinstall|Outlook|OneNote|appstored|appstoreagent|installd|system_installd|AutoUpdate|Update Assistant|Intune|Company Portal|mdmclient|ManagedClient|MISSING|CHANGED|modified=" \
    "$LATEST_WATCH" \
    | tail -1200 \
    > "$OUTDIR/04-watcher-installer-office-signals.txt" || true
else
  echo "No watcher log found" | tee "$OUTDIR/03-outlook-onenote-process-transitions.txt"
  echo "No watcher log found" > "$OUTDIR/04-watcher-installer-office-signals.txt"
fi

{
  echo "=== install.log Microsoft/Office events tail ==="
  echo "Marker start: $START"
  echo
  grep -Ei "Microsoft|Office|Outlook|OneNote|Word|Excel|PowerPoint|AutoUpdate|forcibly closing|preinstall|postinstall|Installed|BusinessPro_Installer|Microsoft_365_and_Office" \
    /var/log/install.log 2>/dev/null | tail -500 || true
} | tee "$OUTDIR/05-install-log-office-events-tail.txt"

{
  echo "=== Microsoft AutoUpdate events tail ==="
  echo "Marker start: $START"
  echo
  grep -Ei "Outlook|OneNote|Word|Excel|PowerPoint|Office|Microsoft 365|AutoUpdate|Update Assistant|forcibly closing|preinstall|postinstall|restore|clone|install|BusinessPro_Installer|Microsoft_365_and_Office" \
    "/Library/Logs/Microsoft/autoupdate.log" 2>/dev/null | tail -800 || true
} | tee "$OUTDIR/06-autoupdate-office-events-tail.txt"

if [[ "$SKIP_UNIFIED" -eq 0 ]]; then
  OUT="$OUTDIR/07-unified-log-office-since-marker.txt"
  log show \
    --style compact \
    --start "$START" \
    --end "$END" \
    --predicate 'process == "installd" OR process == "system_installd" OR process == "appstored" OR process == "appstoreagent" OR process CONTAINS[c] "Intune" OR process CONTAINS[c] "mdmclient" OR process CONTAINS[c] "ManagedClient" OR process CONTAINS[c] "Microsoft AutoUpdate" OR process CONTAINS[c] "Microsoft Update Assistant" OR eventMessage CONTAINS[c] "Microsoft 365" OR eventMessage CONTAINS[c] "Office" OR eventMessage CONTAINS[c] "Outlook" OR eventMessage CONTAINS[c] "OneNote" OR eventMessage CONTAINS[c] "forcibly closing" OR eventMessage CONTAINS[c] "preinstall" OR eventMessage CONTAINS[c] "postinstall" OR eventMessage CONTAINS[c] "BusinessPro_Installer" OR eventMessage CONTAINS[c] "Microsoft_365_and_Office"' \
    > "$OUT" 2>&1 || true
else
  echo "Skipped unified log by request" > "$OUTDIR/07-unified-log-office-since-marker.txt"
fi

{
  echo "=== Office watcher process status ==="
  echo "Watcher dir: $DIR"
  echo "Latest watcher: $LATEST_WATCH"
  echo
  pgrep -fl "watch-office-today\.sh|caffeinate .*watch-office-today" \
    || echo "Office watcher is not currently running"
  echo
  echo "=== Latest watcher logs ==="
  ls -lt "$DIR"/bundle-watch-*.log 2>/dev/null | head -5 \
    || echo "No watcher logs found"
} | tee "$OUTDIR/08-watcher-running-status.txt"

SUMMARY="$OUTDIR/office-stability-summary.md"
cat > "$SUMMARY" <<EOF
# Office Stability Baseline Summary

Generated: $(date)
Phase: $PHASE

Marker start: $START
Capture end: $END

## Review Order

1. 00-baseline-window.txt
2. 01-crash-reports-newer-than-marker.txt
3. 02-office-bundle-status.txt
4. 03-outlook-onenote-process-transitions.txt
5. 04-watcher-installer-office-signals.txt
6. 05-install-log-office-events-tail.txt
7. 06-autoupdate-office-events-tail.txt
8. 07-unified-log-office-since-marker.txt
9. 08-watcher-running-status.txt

## Interpretation Hints

- No crash reports + Outlook/OneNote disappear = likely forced close / update / app replacement.
- Office apps modified together after marker = strong evidence of Office suite update/replacement/re-registration.
- DYLD missing-framework crash = likely Outlook launched while Office bundle was incomplete.
EOF

ZIP="$DIR/${PHASE_SAFE}-office-baseline-$TS.zip"
(cd "$DIR" && zip -r "$ZIP" "$(basename "$OUTDIR")" >/dev/null 2>&1) || true

echo

echo "Evidence directory: $OUTDIR"
echo "Evidence zip:       $ZIP"

if [[ -n "$REIMAGE_ARTIFACT_ROOT" ]]; then
  OFFICE_BACKUP="$REIMAGE_ARTIFACT_ROOT/office-stability"
  mkdir -p "$OFFICE_BACKUP"
  rsync -a "$OUTDIR/" "$OFFICE_BACKUP/$(basename "$OUTDIR")/"
  cp "$ZIP" "$OFFICE_BACKUP/" 2>/dev/null || true
  cp "$SUMMARY" "$OFFICE_BACKUP/office-stability-summary-$TS.md" 2>/dev/null || true
  echo "Copied evidence outputs to: $OFFICE_BACKUP"
  echo "Note: scripts were not copied to the artifact root."
fi
