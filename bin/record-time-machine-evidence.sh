#!/usr/bin/env bash
# =============================================================================
# record-time-machine-evidence.sh
#
# Read-only Time Machine evidence captures for the pre-image backup: a pre-run
# snapshot, focused destination verification, and the final checklist bundle.
#
# Runbook: run-time-machine.md (Phase 5). Paired with bin/run-time-machine.sh,
# which performs the runtime actions; this script only observes. It never
# starts, stops, or mounts a backup.
#
# Evidence is written under $REIMAGE_ARTIFACT_ROOT/time-machine/.
#
# This file is intended for bin/. It is a normal entrypoint: one command per
# invocation, explicit exit codes, and read-only against Time Machine state.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/record-time-machine-evidence.sh
#   ./bin/record-time-machine-evidence.sh [command] [options]
#
# Commands:
#   pre-run          Capture the full pre-backup evidence bundle. Default.
#   verify-volume    Focused diskutil verifyVolume evidence for the destination.
#   final            Generate the final Time Machine checklist under
#                    $REIMAGE_ARTIFACT_ROOT/time-machine/.
#   version          Print this script's version stamp.
#
#   There is deliberately no `status` subcommand — evidence is split across
#   pre-run, verify-volume, and final. Use run-time-machine.sh status for a
#   live status snapshot.
#
# Options:
#   --artifact-root PATH       Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --external-data-root PATH  Manual/evidence volume. Default:
#                              $EXTERNAL_DATA_VOLUME, else the mounted volume
#                              containing the artifact root.
#   --time-machine-dest PATH   Time Machine destination mount.
#                              Default: $EXTERNAL_APPLE_BACKUPS_VOLUME.
#   --open                     Open the generated artifact or bundle.
#   -h, --help                 Show this message and exit.
#
# Examples:
#   ./bin/record-time-machine-evidence.sh pre-run --open
#   ./bin/record-time-machine-evidence.sh verify-volume --open
#   ./bin/record-time-machine-evidence.sh final --open
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Exit status:
#   0    Capture completed.
#   1    The requested capture failed.
#   2    Usage, configuration, or prerequisite error.
#   127  A required external command is not available.
# --- END USAGE ---
# =============================================================================

set -Eeuo pipefail
trap 'status=$?; echo "" >&2; \
  echo "ERROR: record-time-machine-evidence.sh failed near line ${LINENO}: ${BASH_COMMAND}" >&2; \
  exit "$status"' ERR

# Reported by the `version` command, which run-time-machine.md uses to confirm
# which build of this script is installed before relying on the capture output.
SCRIPT_VERSION="20260816-migrated-to-fractogenesis-toolkit"

# ── Locate and source shared reimage config ──────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"
if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi

# --artifact-root may override after parsing, so keep loading permissive.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

# ── Defaults and command-line state ──────────────────────────────────────────
COMMAND="pre-run"
OPEN_AFTER=false

# No hardcoded volume fallback — a baked-in /Volumes/<name> silently targets the
# wrong disk on a Mac where the volume is mounted elsewhere.
TIME_MACHINE_DEST="${EXTERNAL_APPLE_BACKUPS_VOLUME:-}"
EXTERNAL_DATA_VOLUME="${EXTERNAL_DATA_VOLUME:-}"

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

say() { printf '%s\n' "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }

maybe_open() {
  local target="$1"
  if $OPEN_AFTER && command -v open >/dev/null 2>&1; then
    open "$target" >/dev/null 2>&1 || true
  fi
}

resolve_external_data_volume() {
  if [[ -z "${EXTERNAL_DATA_VOLUME:-}" && -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    EXTERNAL_DATA_VOLUME="$(df -P "$REIMAGE_ARTIFACT_ROOT" | awk 'NR==2 {print $6}')"
  fi
}

require_paths() {
  if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    err "REIMAGE_ARTIFACT_ROOT is not set. Source reimage.env or pass --artifact-root PATH."
    exit 2
  fi
  if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
    err "backup root not found: $REIMAGE_ARTIFACT_ROOT"
    exit 2
  fi
  resolve_external_data_volume
  if [[ -z "${EXTERNAL_DATA_VOLUME:-}" ]]; then
    err "EXTERNAL_DATA_VOLUME is not set and could not be derived from REIMAGE_ARTIFACT_ROOT. Source reimage.env or pass --external-data-root PATH."
    exit 2
  fi
  if [[ ! -d "$EXTERNAL_DATA_VOLUME" ]]; then
    err "EXTERNAL_DATA_VOLUME not found: $EXTERNAL_DATA_VOLUME"
    exit 2
  fi
  mkdir -p "$REIMAGE_ARTIFACT_ROOT/time-machine"
}

stamp_now() { date +%Y%m%d-%H%M%S; }

artifact_root_volume() {
  if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    df -P "$REIMAGE_ARTIFACT_ROOT" | awk 'NR==2 {print $6}'
  fi
}

tm_status_text() { tmutil status 2>&1 || true; }

tm_is_running() {
  local status
  status="$(tm_status_text)"
  grep -Eq 'Running[[:space:]]*=[[:space:]]*1' <<< "$status"
}

capture_raw() {
  local out_dir="$1"
  local outfile="$2"
  shift 2
  {
    echo "# Command: $*"
    echo "# Captured: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    "$@" 2>&1 || true
  } > "$out_dir/raw/$outfile"
}

write_resolved_paths_section() {
  :
}

write_common_readonly_sections() {
  cat <<EOF
## Destination

\`\`\`text
$(tmutil destinationinfo 2>&1 || true)
\`\`\`

## Latest Backup

Generic \`tmutil latestbackup\`:

\`\`\`text
$(tmutil latestbackup 2>&1 || true)
\`\`\`

Targeted \`tmutil latestbackup -d "$TIME_MACHINE_DEST" -t\`:

\`\`\`text
$(tmutil latestbackup -d "$TIME_MACHINE_DEST" -t 2>&1 || true)
\`\`\`

## Backup List

Generic \`tmutil listbackups\`:

\`\`\`text
$(tmutil listbackups 2>&1 || true)
\`\`\`

Targeted \`tmutil listbackups -d "$TIME_MACHINE_DEST" -t\`:

\`\`\`text
$(tmutil listbackups -d "$TIME_MACHINE_DEST" -t 2>&1 || true)
\`\`\`

## Exclusions

External data root:

\`\`\`text
$(tmutil isexcluded "$EXTERNAL_DATA_VOLUME" 2>&1 || true)
\`\`\`

Time Machine destination:

\`\`\`text
$(tmutil isexcluded "$TIME_MACHINE_DEST" 2>&1 || true)
\`\`\`

## Current Status

\`\`\`text
$(tmutil status 2>&1 || true)
\`\`\`

## Mounted Volumes

\`\`\`text
$(/bin/ls -la /Volumes 2>&1 || true)
\`\`\`

## External Disk Layout

\`\`\`text
$(diskutil list external 2>&1 || true)
\`\`\`

EOF
}


write_tmutil_destinationinfo_minimal() {
  # tmutil destinationinfo already uses the desired readable layout:
  # ====================================================
  # Name          : ...
  # Kind          : ...
  # Mount Point   : ...
  # ID            : ...
  # Quota         : ...
  if [[ -s "$1" ]]; then
    sed '/^# Command:/d;/^# Captured:/d;/^$/d' "$1"
  else
    echo "No Time Machine destination info captured."
  fi
}

write_raw_command_body() {
  local file="$1"
  if [[ -s "$file" ]]; then
    sed '/^# Command:/d;/^# Captured:/d;/^$/d' "$file"
  else
    echo "No output captured."
  fi
}

write_pre_run_snapshot_markdown() {
  local out_dir="$1"
  local out_file="$out_dir/time-machine-pre-run.md"

  {
    echo "# Time Machine Pre-Run Snapshot"
    echo "Generated: $(date)"
    echo
    echo "## Destination"
    write_tmutil_destinationinfo_minimal "$out_dir/raw/tmutil-destinationinfo.txt"
    echo
    echo "## Latest Backup"
    write_raw_command_body "$out_dir/raw/tmutil-latestbackup.txt"
    echo
    echo "## Backup List"
    write_raw_command_body "$out_dir/raw/tmutil-listbackups.txt"
    echo
    echo "## Exclusions"
    write_raw_command_body "$out_dir/raw/tmutil-isexcluded-data.txt"
    write_raw_command_body "$out_dir/raw/tmutil-isexcluded-applebackups.txt"
  } > "$out_file"
}


write_pre_run_summary() {
  local out_dir="$1"
  local root_volume data_excluded tm_excluded tm_dest_ok latest targeted_latest status_text
  root_volume="$(artifact_root_volume 2>/dev/null || true)"
  status_text="$(tm_status_text)"
  latest="$(tmutil latestbackup 2>/dev/null || true)"
  targeted_latest="$(tmutil latestbackup -d "$TIME_MACHINE_DEST" -t 2>/dev/null || true)"

  data_excluded="CHECK"
  if tmutil isexcluded "$EXTERNAL_DATA_VOLUME" 2>/dev/null | grep -qi '\[Excluded\]'; then
    data_excluded="PASS"
  fi

  tm_excluded="CHECK"
  if tmutil isexcluded "$TIME_MACHINE_DEST" 2>/dev/null | grep -qi '\[Excluded\]'; then
    tm_excluded="PASS"
  fi

  tm_dest_ok="CHECK"
  if [[ -d "$TIME_MACHINE_DEST" ]]; then
    tm_dest_ok="PASS"
  fi

  cat > "$out_dir/time-machine-status.md" <<EOF
# Time Machine Status Evidence Bundle

Generated: $(date)
Host: $(hostname)

## Purpose

This status summary points to the raw evidence captured in this bundle. It is intentionally different from \`time-machine-pre-run.md\`, which keeps the older pre-run snapshot layout.

## Summary

| Check | Status | Evidence |
|---|---:|---|
| Time Machine destination mounted | $tm_dest_ok | \`raw/diskutil-applebackups.txt\` |
| Selected external data volume excluded from Time Machine | $data_excluded | \`raw/tmutil-isexcluded-data.txt\` |
| Time Machine destination excluded from itself | $tm_excluded | \`raw/tmutil-isexcluded-applebackups.txt\` |
| Backup root volume resolved | CHECK | \`raw/backup-root-spot-check.txt\` |
| Targeted latest backup captured | CHECK | \`raw/tmutil-latestbackup-targeted-applebackups.txt\` |
| Backup list captured | CHECK | \`raw/tmutil-listbackups-targeted-applebackups.txt\` |
| APFS snapshot list captured | CHECK | \`raw/diskutil-applebackups-snapshots.txt\` |

## Selected Volumes

| Label | Path |
|---|---|
| Selected external data volume | \`$EXTERNAL_DATA_VOLUME\` |
| Manual backup root | \`$REIMAGE_ARTIFACT_ROOT\` |
| Manual backup root mounted volume | \`$root_volume\` |
| Time Machine destination | \`$TIME_MACHINE_DEST\` |

## Current Time Machine Status

\`\`\`text
$status_text
\`\`\`

## Latest Backup Lookups

Generic latest backup:

\`\`\`text
${latest:-No generic latest backup returned.}
\`\`\`

Targeted latest backup:

\`\`\`text
${targeted_latest:-No targeted latest backup returned.}
\`\`\`

## Follow-Up Commands

Start and monitor Time Machine:

\`\`\`bash
./bin/backup-time-machine.sh start
./bin/backup-time-machine.sh monitor --interval 300
./bin/backup-time-machine.sh complete --open
\`\`\`

Focused APFS destination verification after Time Machine stops:

\`\`\`bash
./bin/record-time-machine-evidence.sh verify-volume --open
\`\`\`

Targeted checksum verification:

\`\`\`bash
./bin/backup-time-machine.sh verify-latest --mount-if-needed --open
\`\`\`
EOF
}


capture_time_machine_raw_bundle() {
  local out="$1"

  mkdir -p "$out/raw"

  capture_raw "$out" volumes.txt /bin/ls -la /Volumes
  capture_raw "$out" tmutil-destinationinfo.txt tmutil destinationinfo
  capture_raw "$out" tmutil-status.txt tmutil status
  capture_raw "$out" tmutil-currentphase.txt tmutil currentphase
  capture_raw "$out" tmutil-latestbackup.txt tmutil latestbackup
  capture_raw "$out" tmutil-listbackups.txt tmutil listbackups
  capture_raw "$out" tmutil-latestbackup-targeted-applebackups.txt tmutil latestbackup -d "$TIME_MACHINE_DEST" -t
  capture_raw "$out" tmutil-listbackups-targeted-applebackups.txt tmutil listbackups -d "$TIME_MACHINE_DEST" -t
  capture_raw "$out" tmutil-isexcluded-data.txt tmutil isexcluded "$EXTERNAL_DATA_VOLUME"
  capture_raw "$out" tmutil-isexcluded-applebackups.txt tmutil isexcluded "$TIME_MACHINE_DEST"
  capture_raw "$out" diskutil-data.txt diskutil info "$EXTERNAL_DATA_VOLUME"

  if [[ -d "$TIME_MACHINE_DEST" ]]; then
    capture_raw "$out" diskutil-applebackups.txt diskutil info "$TIME_MACHINE_DEST"
    capture_raw "$out" diskutil-applebackups-snapshots.txt diskutil apfs listSnapshots "$TIME_MACHINE_DEST"
  else
    echo "Time Machine destination not mounted at capture time: $TIME_MACHINE_DEST" > "$out/raw/diskutil-applebackups.txt"
    echo "Time Machine destination not mounted at capture time: $TIME_MACHINE_DEST" > "$out/raw/diskutil-applebackups-snapshots.txt"
  fi

  {
    echo "Skipped by default."
    echo "Run focused verification after Time Machine is stopped:"
    echo "./bin/record-time-machine-evidence.sh verify-volume --open"
  } > "$out/raw/diskutil-verifyvolume-applebackups.txt"

  {
    echo "# Backup Root Spot Check"
    echo "Captured: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    echo "Selected external data volume: $EXTERNAL_DATA_VOLUME"
    echo "Manual backup root: $REIMAGE_ARTIFACT_ROOT"
    echo "Manual backup root mounted volume: $(artifact_root_volume 2>/dev/null || true)"
    echo
    if [[ "$(artifact_root_volume 2>/dev/null || true)" == "$EXTERNAL_DATA_VOLUME" ]]; then
      echo "PASS: manual backup root is located on the selected external data volume"
    else
      echo "WARN: manual backup root is not located on the selected external data volume"
    fi
    echo
    echo "Top-level folders:"
    find "$REIMAGE_ARTIFACT_ROOT" -maxdepth 1 -mindepth 1 -type d -print | sort
    echo
    echo "Top-level sizes:"
    du -sh "$REIMAGE_ARTIFACT_ROOT"/* 2>/dev/null | sort || true
  } > "$out/raw/backup-root-spot-check.txt"

  {
    echo "# Cloud Sync Process Hints"
    echo "Captured: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    echo "OneDrive processes:"
    pgrep -lf "OneDrive" 2>/dev/null || true
    echo
    echo "Obsidian processes:"
    pgrep -lf "Obsidian" 2>/dev/null || true
  } > "$out/raw/cloud-sync-process-hints.txt"
}


latest_matching_file() {
  local pattern="$1"
  ls -t $pattern 2>/dev/null | head -1 || true
}

status_for_text_file() {
  local file="$1"
  if [[ -z "$file" || ! -f "$file" ]]; then
    echo "TODO"
    return
  fi
  if grep -qiE 'MISMATCH|FAILED|FAIL:|ERROR|Input/output error|No such file|not mounted|SKIPPED' "$file" 2>/dev/null; then
    echo "CHECK"
  else
    echo "PASS"
  fi
}

capture_final_checklist() {
  require_paths
  local stamp out tm_status_text tm_running targeted_latest latest_status backup_completed data_excluded_status data_excluded_text
  local verify_volume_file verify_volume_status checksum_file checksum_status completion_file completion_status
  local pre_run_bundle pre_run_status latest_path

  stamp="$(stamp_now)"
  out="$REIMAGE_ARTIFACT_ROOT/time-machine/final-time-machine-checklist-$stamp.md"
  mkdir -p "$REIMAGE_ARTIFACT_ROOT/time-machine"

  tm_status_text="$(tm_status_text)"
  tm_running="NO"
  if grep -Eq 'Running[[:space:]]*=[[:space:]]*1' <<< "$tm_status_text"; then
    tm_running="YES"
  fi

  targeted_latest="$(tmutil latestbackup -d "$TIME_MACHINE_DEST" -t 2>/dev/null || true)"
  latest_path="$(tmutil latestbackup 2>/dev/null || true)"

  latest_status="TODO"
  if [[ "$targeted_latest" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}$ ]]; then
    latest_status="PASS"
  fi

  backup_completed="TODO"
  if [[ "$tm_running" == "NO" && "$latest_status" == "PASS" ]]; then
    backup_completed="PASS"
  elif [[ "$tm_running" == "YES" ]]; then
    backup_completed="CHECK"
  fi

  data_excluded_text="$(tmutil isexcluded "$EXTERNAL_DATA_VOLUME" 2>/dev/null || true)"
  data_excluded_status="TODO"
  if grep -qi '\[Excluded\]' <<< "$data_excluded_text"; then
    data_excluded_status="PASS"
  elif [[ -n "$data_excluded_text" ]]; then
    data_excluded_status="CHECK"
  fi

  completion_file="$(latest_matching_file "$REIMAGE_ARTIFACT_ROOT/time-machine/completion-check-*.md")"
  completion_status="$(status_for_text_file "$completion_file")"

  verify_volume_file="$(latest_matching_file "$REIMAGE_ARTIFACT_ROOT/time-machine/diskutil-verifyvolume-applebackups-*.txt")"
  verify_volume_status="N/A"
  if [[ -n "$verify_volume_file" ]]; then
    verify_volume_status="$(status_for_text_file "$verify_volume_file")"
  fi

  checksum_file="$(latest_matching_file "$REIMAGE_ARTIFACT_ROOT/time-machine/verifychecksums-*.txt")"
  checksum_status="N/A"
  if [[ -n "$checksum_file" ]]; then
    checksum_status="$(status_for_text_file "$checksum_file")"
  fi

  pre_run_bundle="$(find "$REIMAGE_ARTIFACT_ROOT/time-machine" -maxdepth 1 -type d -name 'pre-image-time-machine-status-*' -print 2>/dev/null | sort | tail -1)"
  pre_run_status="TODO"
  if [[ -n "$pre_run_bundle" && -f "$pre_run_bundle/time-machine-pre-run.md" && -d "$pre_run_bundle/raw" ]]; then
    pre_run_status="PASS"
  fi

  cat > "$out" <<EOF
# Final Time Machine Checklist

Generated: $(date)
Host: $(hostname)

## Scope

Time Machine only. OneDrive, iCloud, Obsidian, app sync, and external-drive eject checks are covered in other runbooks.

## Automated Checks

| Item | Status | Evidence / Notes |
|---|---:|---|
| Time Machine backup completed | $backup_completed | Time Machine running: \`$tm_running\`; targeted latest backup: \`${targeted_latest:-TODO}\`. |
| Latest Time Machine backup confirmed with targeted destination lookup | $latest_status | \`tmutil latestbackup -d "$TIME_MACHINE_DEST" -t\` returned \`${targeted_latest:-TODO}\`. |
| Selected external data volume excluded from Time Machine | $data_excluded_status | \`$EXTERNAL_DATA_VOLUME\`; output: \`${data_excluded_text:-TODO}\`. |
| Pre-run evidence bundle captured | $pre_run_status | \`${pre_run_bundle:-TODO}\`. |
| Completion evidence captured | $completion_status | \`${completion_file:-TODO}\`. |
| Time Machine destination volume verified, if used | $verify_volume_status | \`${verify_volume_file:-Not run; optional.}\`. |
| Targeted checksum verification completed, if used | $checksum_status | \`${checksum_file:-Not run; optional.}\`. |

## Manual Checks Remaining

| Item | Status | Notes |
|---|---|---|
| Time Machine UI spot-check completed | TODO | Browse expected files from the latest backup. |
| Time Machine evidence reviewed before reimage | TODO | Review completion, latest backup, exclusion, optional verification, and optional checksum evidence. |

## Latest Backup

Generic \`tmutil latestbackup\`:

\`\`\`text
${latest_path:-TODO}
\`\`\`

Targeted \`tmutil latestbackup -d "$TIME_MACHINE_DEST" -t\`:

\`\`\`text
${targeted_latest:-TODO}
\`\`\`

## Current Time Machine Status

\`\`\`text
$tm_status_text
\`\`\`

Completed by: TODO
Date: YYYY-MM-DD
EOF

  say "Created: $out"
  maybe_open "$out"
}


capture_pre_run() {
  require_paths
  local stamp out
  stamp="$(stamp_now)"
  out="$REIMAGE_ARTIFACT_ROOT/time-machine/pre-image-time-machine-status-$stamp"
  mkdir -p "$out"

  capture_time_machine_raw_bundle "$out"
  write_pre_run_snapshot_markdown "$out"
  write_pre_run_summary "$out"

  cat > "$out/README.md" <<EOF
# Time Machine Pre-Run / Status Bundle

Open \`time-machine-pre-run.md\` for the minimal pre-run snapshot.
Open \`time-machine-status.md\` for the compact status summary.

This bundle is generated by:

\`\`\`bash
./bin/record-time-machine-evidence.sh pre-run --open
\`\`\`

Runtime actions such as start, monitor, complete, compare, verify latest, logs, and eject belong to \`backup-time-machine.sh\`.
EOF

  say "Created: $out"
  maybe_open "$out"
}

capture_verify_volume() {
  require_paths
  local stamp out tm_running
  stamp="$(stamp_now)"
  out="$REIMAGE_ARTIFACT_ROOT/time-machine/diskutil-verifyvolume-applebackups-$stamp.txt"

  tm_running="NO"
  if tm_is_running; then
    tm_running="YES"
  fi

  {
    echo "# Time Machine Destination Volume Verification"
    echo "Generated   : $(date)"
    echo "Host        : $(hostname)"
    echo "Mount Point : $TIME_MACHINE_DEST"
    echo
    echo "Command     : diskutil verifyVolume $TIME_MACHINE_DEST"
    echo "Time Machine running at capture time: $tm_running"
    echo

    if [[ "$tm_running" == "YES" ]]; then
      echo "SKIPPED: Time Machine is currently running."
      echo "Reason : diskutil verifyVolume can be disruptive during an active Time Machine backup."
      echo "Action : rerun after tmutil status reports Running = 0."
    elif [[ ! -d "$TIME_MACHINE_DEST" ]]; then
      echo "FAILED: Time Machine destination is not mounted at: $TIME_MACHINE_DEST"
    else
      diskutil verifyVolume "$TIME_MACHINE_DEST" 2>&1 || true
    fi
  } > "$out"

  say "Created: $out"
  maybe_open "$out"
}


if [[ $# -gt 0 && "$1" != --* ]]; then
  COMMAND="$1"
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      require_option_value "$1" "${2:-}"; REIMAGE_ARTIFACT_ROOT="$2"; shift 2 ;;
    --external-data-root)
      require_option_value "$1" "${2:-}"; EXTERNAL_DATA_VOLUME="$2"; shift 2 ;;
    --time-machine-dest)
      require_option_value "$1" "${2:-}"; TIME_MACHINE_DEST="$2"; shift 2 ;;
    --open) OPEN_AFTER=true; shift ;;
    --version) echo "$SCRIPT_VERSION"; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown argument: $1"; usage; exit 2 ;;
  esac
done

case "$COMMAND" in
  version) echo "$SCRIPT_VERSION" ;;
  pre-run) capture_pre_run ;;
  verify-volume) capture_verify_volume ;;
  final) capture_final_checklist ;;
  -h|--help|help) usage ;;
  *) err "Unknown command: $COMMAND"; usage; exit 2 ;;
esac
