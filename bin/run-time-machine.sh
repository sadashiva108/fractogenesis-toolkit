#!/usr/bin/env bash
# =============================================================================
# run-time-machine.sh
#
# Runtime Time Machine operations for the pre-image backup: start it, watch it,
# confirm it finished, mount and checksum the resulting snapshot, compare it
# against the previous backup, and eject the destination safely.
#
# Runbook: run-time-machine.md (Phase 5). This does not replace Time Machine —
# it wraps tmutil, diskutil, and log, and writes evidence under
# $REIMAGE_ARTIFACT_ROOT/time-machine/.
#
# Read-only evidence bundles are record-time-machine-evidence.sh's job, not this
# one. That script is the other bin/ entrypoint run-time-machine.md owns.
#
# This file is intended for bin/. It is a normal entrypoint: one command per
# invocation, explicit exit codes, and no writes outside the artifact root and
# the temporary mount point it manages.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/run-time-machine.sh
#   ./bin/run-time-machine.sh "<command>" [options]
#
#   The placeholder is quoted so a copy-paste of this synopsis line reaches the
#   script as an unknown-command error instead of being eaten by the shell as an
#   input redirection.
#
# Commands:
#   start            Start a Time Machine backup.
#   monitor          Print backup progress until Time Machine stops running.
#   status           Status snapshot of the current/most recent backup.
#   complete         Completion evidence for a finished backup.
#   compare          Compare the latest backup against the previous backup.
#   mount-latest     Mount the latest APFS snapshot read-only under /tmp.
#   verify-latest    Run tmutil verifychecksums against the latest backup path.
#   unmount-latest   Unmount the snapshot mounted by mount-latest.
#   logs             Capture recent Time Machine logs.
#   diagnose         Capture sleep state and a short backupd fs_usage sample.
#   eject            Eject the Time Machine and Data volumes, or a whole disk.
#
# Options:
#   --artifact-root PATH       Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --time-machine-dest PATH   Time Machine destination mount.
#                              Default: $EXTERNAL_APPLE_BACKUPS_VOLUME.
#   --external-data-root PATH  Manual/evidence volume to verify as excluded.
#                              Default: $EXTERNAL_DATA_VOLUME, else the mounted
#                              volume containing the artifact root.
#   --interval SECONDS         Monitor polling interval, a positive integer
#                              number of seconds. Default: 300.
#   --last WINDOW              Relative log window for logs. Default: 2h.
#   --start DATETIME           Absolute log start, e.g. "2026-07-06 08:30:00".
#   --end DATETIME             Absolute log end, e.g. "2026-07-06 08:35:00".
#   --auto                     Use tmutil startbackup --auto. Not the pre-image
#                              default.
#   --block                    Use tmutil startbackup --block for start.
#   --compare                  Include tmutil compare in complete output.
#   --compare-path PATH        Compare this exact live or backup-relative path.
#                              /Users/... resolves to Data/Users/...; explicit
#                              paths are not silently broadened.
#   --mount-if-needed          For verify-latest, mount the latest APFS snapshot
#                              when the latestbackup path is not visible.
#   --verify-path PATH         For verify-latest, verify this path inside the
#                              snapshot.
#   --full-snapshot            For verify-latest, verify the whole snapshot.
#                              Noisy; may hit restricted system/app paths.
#   --physical-disk DISK       For eject, eject the whole physical disk, e.g.
#                              disk4. Skips the destination and data-volume
#                              checks so it still works as the retry after a
#                              partially completed eject.
#   --open                     Open the generated artifact or mount point.
#   -h, --help                 Show this message and exit.
#
# Examples:
#   ./bin/run-time-machine.sh start
#   ./bin/run-time-machine.sh monitor --interval 300
#   ./bin/run-time-machine.sh complete --open
#   ./bin/run-time-machine.sh verify-latest --mount-if-needed --open
#   ./bin/run-time-machine.sh compare --open
#   ./bin/run-time-machine.sh eject --physical-disk disk4
#
# Outputs:
#   Written under $REIMAGE_ARTIFACT_ROOT/time-machine/ by the command named:
#     status         status-YYYYMMDD-HHMMSS.txt
#     logs           logs-YYYYMMDD-HHMMSS.txt
#     complete       completion-check-YYYYMMDD-HHMMSS.md
#     compare        compare-YYYYMMDD-HHMMSS.txt
#                    (also written by `complete --compare`)
#     verify-latest  verifychecksums-YYYYMMDD-HHMMSS.txt
#     diagnose       diagnose-YYYYMMDD-HHMMSS.txt
#   start, monitor, mount-latest, unmount-latest, and eject write no artifact.
#   mount-latest and compare additionally create and remove a temporary
#   read-only mount point under /tmp/tm-<backup-stamp>.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Exit status:
#   0    Command completed.
#   1    The requested operation failed.
#   2    Usage, configuration, or prerequisite error.
#   3    verify-latest completed but reported MISMATCH/FAILED checksum entries.
#   127  A required external command is not available.
# --- END USAGE ---
# =============================================================================

set -Eeuo pipefail
trap 'status=$?; echo "" >&2; \
  echo "ERROR: run-time-machine.sh failed near line ${LINENO}: ${BASH_COMMAND}" >&2; \
  exit "$status"' ERR

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
# No hardcoded volume fallback: the destination comes from shared config or
# --time-machine-dest. A baked-in /Volumes/<name> would silently target the
# wrong disk on a Mac where the volume is mounted elsewhere.
TIME_MACHINE_DEST="${EXTERNAL_APPLE_BACKUPS_VOLUME:-}"
EXTERNAL_DATA_VOLUME="${EXTERNAL_DATA_VOLUME:-}"
INTERVAL=300
LOG_WINDOW="2h"
LOG_START=""
LOG_END=""
OPEN_OUTPUT=false
AUTO=false
BLOCK=false
COMPARE=false
COMPARE_PATH=""
VERIFY_PATH=""
FULL_SNAPSHOT=false
MOUNT_IF_NEEDED=false
PHYSICAL_DISK=""
COMMAND=""

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

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "required command not found: $1"; exit 127; }
}

# The reference-vault original defaulted this to a hardcoded /Volumes/<name>,
# which is why it never needed a check. That default is gone — a baked-in mount
# path silently targets the wrong disk on a Mac where the volume is elsewhere —
# so the commands that pass `-d "$TIME_MACHINE_DEST"` to tmutil must confirm it
# resolved. Without this, an unset destination reaches tmutil as -d "" and the
# surrounding `|| true` swallows the error into empty output.
require_time_machine_dest() {
  if [[ -z "${TIME_MACHINE_DEST:-}" ]]; then
    err "Time Machine destination is not set. Set EXTERNAL_APPLE_BACKUPS_VOLUME in reimage.env or pass --time-machine-dest PATH."
    exit 2
  fi
  if [[ ! -d "$TIME_MACHINE_DEST" ]]; then
    err "Time Machine destination is not mounted: $TIME_MACHINE_DEST"
    exit 2
  fi
}

require_artifact_root() {
  if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    err "REIMAGE_ARTIFACT_ROOT is not set. Source reimage.env or pass --artifact-root PATH."
    exit 2
  fi
  # Without this, an unmounted external volume turns the mkdir -p below into a
  # fresh tree on the boot disk and every artifact silently lands there.
  if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
    err "backup root not found: $REIMAGE_ARTIFACT_ROOT"
    exit 2
  fi
  mkdir -p "$REIMAGE_ARTIFACT_ROOT/time-machine"
}

resolve_external_data_volume() {
  if [[ -z "${EXTERNAL_DATA_VOLUME:-}" && -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    EXTERNAL_DATA_VOLUME="$(df -P "$REIMAGE_ARTIFACT_ROOT" | awk 'NR==2 {print $6}')"
  fi
}

require_external_data_volume() {
  resolve_external_data_volume
  if [[ -z "${EXTERNAL_DATA_VOLUME:-}" ]]; then
    err "EXTERNAL_DATA_VOLUME is not set and could not be derived from REIMAGE_ARTIFACT_ROOT. Source reimage.env or pass --external-data-root PATH."
    exit 2
  fi
  if [[ ! -d "$EXTERNAL_DATA_VOLUME" ]]; then
    err "EXTERNAL_DATA_VOLUME does not exist: $EXTERNAL_DATA_VOLUME"
    exit 2
  fi
}

artifact_path() {
  local prefix="$1" ext="${2:-md}"
  require_artifact_root
  printf '%s/time-machine/%s-%s.%s\n' "$REIMAGE_ARTIFACT_ROOT" "$prefix" "$(date +%Y%m%d-%H%M%S)" "$ext"
}

maybe_open() {
  local target="$1"
  if $OPEN_OUTPUT && command -v open >/dev/null 2>&1; then
    open "$target" >/dev/null 2>&1 || true
  fi
}

latest_backup() {
  tmutil latestbackup 2>/dev/null || true
}

targeted_latest_timestamp() {
  tmutil latestbackup -d "$TIME_MACHINE_DEST" -t 2>/dev/null || true
}

targeted_backup_list() {
  tmutil listbackups -d "$TIME_MACHINE_DEST" -t 2>/dev/null || true
}

backup_stamp_from_value() {
  local value="$1"
  grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}' <<< "$value" | tail -1 || true
}

format_backup_stamp_datetime() {
  local stamp="$1"
  if [[ "$stamp" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})$ ]]; then
    printf '%s-%s-%s %s:%s:%s %s\n' \
      "${BASH_REMATCH[1]}" \
      "${BASH_REMATCH[2]}" \
      "${BASH_REMATCH[3]}" \
      "${BASH_REMATCH[4]}" \
      "${BASH_REMATCH[5]}" \
      "${BASH_REMATCH[6]}" \
      "$(date +%Z)"
  else
    printf '%s\n' "$stamp"
  fi
}

backup_stamp_offset_datetime() {
  local stamp="$1" offset="$2"
  if [[ ! "$stamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}$ ]]; then
    return 1
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$stamp" "$offset" <<'PY' 2>/dev/null && return 0
import datetime as dt
import re
import sys

stamp = sys.argv[1]
offset = sys.argv[2]
match = re.match(r"([+-])(\d+)([HMS])$", offset)
base = dt.datetime.strptime(stamp, "%Y-%m-%d-%H%M%S")
if not match:
    print(base.strftime("%Y-%m-%d %H:%M:%S"))
    raise SystemExit(0)

sign, amount_text, unit = match.groups()
amount = int(amount_text)
if sign == "-":
    amount = -amount
delta = {"H": dt.timedelta(hours=amount), "M": dt.timedelta(minutes=amount), "S": dt.timedelta(seconds=amount)}[unit]
print((base + delta).strftime("%Y-%m-%d %H:%M:%S"))
PY
  fi

  date -j -f "%Y-%m-%d-%H%M%S" "$stamp" -v"$offset" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || true
}

run_time_machine_log() {
  if ! command -v log >/dev/null 2>&1; then
    echo "macOS log command not available."
    return 0
  fi

  if [[ -n "${LOG_START:-}" ]]; then
    if [[ -n "${LOG_END:-}" ]]; then
      command log show --predicate 'subsystem == "com.apple.TimeMachine"' --start "$LOG_START" --end "$LOG_END" 2>&1 || true
    else
      command log show --predicate 'subsystem == "com.apple.TimeMachine"' --start "$LOG_START" 2>&1 || true
    fi
  else
    command log show --predicate 'subsystem == "com.apple.TimeMachine"' --last "$LOG_WINDOW" 2>&1 || true
  fi
}

latest_stamp() {
  local latest="$1"
  [[ -n "$latest" ]] || return 1
  if [[ "$latest" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}$ ]]; then
    printf '%s.backup\n' "$latest"
  else
    basename "$latest"
  fi
}

helper_mount_point_for_stamp() {
  local stamp="$1"
  printf '/tmp/tm-%s\n' "${stamp%.backup}"
}

resolve_tm_device() {
  diskutil info "$TIME_MACHINE_DEST" 2>/dev/null | awk -F': *' '/Device Node/ {print $2; exit}'
}

snapshot_name_for_stamp() {
  local stamp="$1"
  printf 'com.apple.TimeMachine.%s\n' "$stamp"
}

is_helper_mount_active() {
  local mount_point="$1"
  mount | grep -q "on ${mount_point} "
}

ensure_snapshot_mounted() {
  local stamp="$1" tm_device="$2" mount_point="$3"
  local snapshot_name mounted_backup_path mount_status
  snapshot_name="$(snapshot_name_for_stamp "$stamp")"
  mounted_backup_path="$mount_point/$stamp"

  mkdir -p "$mount_point"

  if [[ -e "$mounted_backup_path" ]]; then
    say "Snapshot path already visible: $mounted_backup_path"
    return 0
  fi

  if is_helper_mount_active "$mount_point"; then
    say "Mount point is already mounted: $mount_point"
  else
    say "Mounting read-only APFS snapshot $snapshot_name at $mount_point..."
    set +e
    sudo /sbin/mount_apfs -o nobrowse,ro -s "$snapshot_name" "$tm_device" "$mount_point"
    mount_status=$?
    set -e

    if [[ "$mount_status" -ne 0 ]]; then
      if [[ -e "$mounted_backup_path" ]]; then
        say "mount_apfs returned status $mount_status, but the backup path is visible. Continuing."
      else
        err "mount_apfs failed with status $mount_status and backup path is not visible: $mounted_backup_path"
        return "$mount_status"
      fi
    fi
  fi

  if [[ -e "$mounted_backup_path" ]]; then
    return 0
  fi

  err "snapshot mount point exists, but expected backup folder is not visible: $mounted_backup_path"
  ls -la "$mount_point" 2>/dev/null | head -40 || true
  return 2
}

normalize_compare_path() {
  local path="$1"
  path="${path%/}"

  # Convert live macOS paths to paths relative to an APFS Time Machine backup root.
  case "$path" in
    /System/Volumes/Data/*) path="${path#/System/Volumes/Data/}" ;;
    /Volumes/*/*.backup/*) path="${path#*.backup/}" ;;
    /Volumes/*/*.previous/*) path="${path#*.previous/}" ;;
    /Volumes/*/*.interrupted/*) path="${path#*.interrupted/}" ;;
    /*) path="${path#/}" ;;
  esac

  path="${path%/}"
  printf '%s\n' "$path"
}

print_compare_path_candidates() {
  local requested="$1" normalized without_data
  normalized="$(normalize_compare_path "$requested")"

  [[ -n "$normalized" ]] && printf '%s\n' "$normalized"

  case "$normalized" in
    Data/*)
      without_data="${normalized#Data/}"
      [[ -n "$without_data" ]] && printf '%s\n' "$without_data"
      ;;
    Users/*|Applications/*|Library/*|private/*|opt/*|usr/local/*)
      printf 'Data/%s\n' "$normalized"
      ;;
    System/Volumes/Data/*)
      printf '%s\n' "${normalized#System/Volumes/Data/}"
      printf 'Data/%s\n' "${normalized#System/Volumes/Data/}"
      ;;
  esac
}

first_compare_candidate() {
  local requested="$1" candidate
  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] || continue
    printf '%s\n' "$candidate"
    return 0
  done < <(print_compare_path_candidates "$requested")
}

resolve_compare_path_strict() {
  local previous_root="$1" latest_root="$2" requested="$3" candidate seen first_candidate
  seen=""
  first_candidate="$(first_compare_candidate "$requested")"

  while IFS= read -r candidate; do
    [[ -z "$candidate" ]] && continue
    case "|$seen|" in
      *"|$candidate|"*) continue ;;
    esac
    seen="${seen}|${candidate}"
    if [[ -e "$previous_root/$candidate" && -e "$latest_root/$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(print_compare_path_candidates "$requested")

  # For explicit compare paths, do not broaden to a parent/default path.
  # Return the most useful candidate for reporting, preferring a candidate that exists on either side.
  while IFS= read -r candidate; do
    [[ -z "$candidate" ]] && continue
    if [[ -e "$previous_root/$candidate" || -e "$latest_root/$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 1
    fi
  done < <(print_compare_path_candidates "$requested")

  printf '%s\n' "$first_candidate"
  return 1
}

print_compare_candidate_report() {
  local previous_root="$1" latest_root="$2" requested="$3" candidate seen prev_status latest_status
  seen=""
  echo '## Candidate Path Probe'
  echo
  printf 'Requested path : %s\n' "$requested"
  echo
  printf '%-90s  %-8s  %-8s\n' 'Candidate relative path' 'Previous' 'Latest'
  printf '%-90s  %-8s  %-8s\n' '-----------------------' '--------' '------'
  while IFS= read -r candidate; do
    [[ -z "$candidate" ]] && continue
    case "|$seen|" in
      *"|$candidate|"*) continue ;;
    esac
    seen="${seen}|${candidate}"
    prev_status="MISSING"
    latest_status="MISSING"
    [[ -e "$previous_root/$candidate" ]] && prev_status="FOUND"
    [[ -e "$latest_root/$candidate" ]] && latest_status="FOUND"
    printf '%-90s  %-8s  %-8s\n' "$candidate" "$prev_status" "$latest_status"
  done < <(print_compare_path_candidates "$requested")
  echo
}

compare_missing_interpretation() {
  local previous_item="$1" latest_item="$2"
  if [[ ! -e "$previous_item" && -e "$latest_item" ]]; then
    echo 'Interpretation: target exists in the latest snapshot only.'
    echo 'This usually means the directory was created, renamed, moved, or first backed up after the previous snapshot.'
  elif [[ -e "$previous_item" && ! -e "$latest_item" ]]; then
    echo 'Interpretation: target exists in the previous snapshot only.'
    echo 'This usually means the directory was removed, renamed, moved, or excluded before the latest snapshot.'
  else
    echo 'Interpretation: target was not found in either snapshot under the probed candidate paths.'
  fi
}

cleanup_compare_mounts() {
  local previous_mount="$1" latest_mount="$2" previous_was_mounted="$3" latest_was_mounted="$4" out="$5"
  {
    echo
    echo '## Cleanup'
  } | tee -a "$out"

  if ! $previous_was_mounted; then
    diskutil unmount "$previous_mount" 2>&1 | tee -a "$out" || true
    rmdir "$previous_mount" 2>/dev/null || true
  else
    echo "Left previously mounted snapshot in place: $previous_mount" | tee -a "$out"
  fi

  if ! $latest_was_mounted; then
    diskutil unmount "$latest_mount" 2>&1 | tee -a "$out" || true
    rmdir "$latest_mount" 2>/dev/null || true
  else
    echo "Left previously mounted snapshot in place: $latest_mount" | tee -a "$out"
  fi
}

choose_compare_path() {
  local previous_root="$1" latest_root="$2"
  local candidate user_name
  user_name="$(whoami)"

  if [[ -n "$COMPARE_PATH" ]]; then
    resolve_compare_path_strict "$previous_root" "$latest_root" "$COMPARE_PATH"
    return 0
  fi

  for candidate in \
    "Data/Users/${user_name}/Development" \
    "Data/Users/${user_name}" \
    "Data"; do
    if [[ -e "$previous_root/$candidate" && -e "$latest_root/$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  printf 'Data\n'
}


tm_status() {
  tmutil status 2>&1 || true
}

tm_is_running_from_status() {
  # tmutil status prints `Running = 1;` on current macOS. Older runbook snippets
  # sometimes looked for `"Running" = 1`, which is too brittle and can make an
  # active backup look stopped.
  grep -Eq 'Running[[:space:]]*=[[:space:]]*1' <<< "$1"
}


print_common_header() {
  local title="$1"
  local backup_completed="${2:-}"
  local backup_stamp="${3:-}"
  cat <<EOF
# Time Machine $title
Generated        : $(date)
${backup_completed:+Backup Completed : $backup_completed
}${backup_stamp:+Backup Stamp     : $backup_stamp
}Host             : $(hostname)
Mount Point      : ${TIME_MACHINE_DEST:-}

EOF
}


start_backup() {
  need_cmd tmutil
  local args=(startbackup)
  $AUTO && args+=(--auto)
  $BLOCK && args+=(--block)
  say "Running: tmutil ${args[*]}"
  tmutil "${args[@]}"
}

monitor_backup() {
  need_cmd tmutil
  local status
  say "Monitoring Time Machine every ${INTERVAL}s. Press Ctrl+C to stop monitoring."
  while true; do
    status="$(tm_status)"
    if ! tm_is_running_from_status "$status"; then
      echo "Time Machine is not running. Current status:"
      printf '%s\n' "$status"
      return 0
    fi

    date
    printf '%s\n' "$status" | grep -E 'BackupPhase|ChangedItemCount|Percent|TimeRemaining|bytes|files|totalBytes|totalFiles|Running|attemptOptions' || true
    echo
    sleep "$INTERVAL"
  done
}

capture_status() {
  need_cmd tmutil
  local out; out="$(artifact_path status txt)"
  {
    date
    tmutil status 2>&1 || true
  } > "$out"
  cat "$out"
  say "Wrote: $out"
}

capture_logs() {
  local out; out="$(artifact_path logs txt)"
  if ! command -v log >/dev/null 2>&1; then
    err "macOS log command not found"
    exit 127
  fi
  {
    echo "# Time Machine Logs"
    echo "Generated   : $(date)"
    echo "Host        : $(hostname)"
    echo "Mount Point : $TIME_MACHINE_DEST"
    echo
    if [[ -n "${LOG_START:-}" ]]; then
      echo "Log query   : --start $LOG_START${LOG_END:+ --end $LOG_END}"
      if [[ -n "${LOG_END:-}" ]]; then
        printf 'Command     : /usr/bin/log show --predicate %q --start %q --end %q\n' 'subsystem == "com.apple.TimeMachine"' "$LOG_START" "$LOG_END"
      else
        printf 'Command     : /usr/bin/log show --predicate %q --start %q\n' 'subsystem == "com.apple.TimeMachine"' "$LOG_START"
      fi
    else
      echo "Log query   : --last $LOG_WINDOW"
      printf 'Command     : /usr/bin/log show --predicate %q --last %q\n' 'subsystem == "com.apple.TimeMachine"' "$LOG_WINDOW"
    fi
    echo
    run_time_machine_log
  } > "$out"
  say "Wrote: $out"
  maybe_open "$out"
}

capture_complete() {
  need_cmd tmutil
  need_cmd diskutil
  require_external_data_volume
  local out latest targeted_latest completion_stamp completion_datetime completion_source completion_log_start completion_log_end list_count
  out="$(artifact_path completion-check md)"
  latest="$(latest_backup)"
  targeted_latest="$(targeted_latest_timestamp)"

  completion_stamp="$(backup_stamp_from_value "$targeted_latest")"
  completion_source="targeted tmutil latestbackup"
  if [[ -z "$completion_stamp" ]]; then
    completion_stamp="$(backup_stamp_from_value "$latest")"
    completion_source="generic tmutil latestbackup"
  fi

  if [[ -n "$completion_stamp" ]]; then
    completion_datetime="$(format_backup_stamp_datetime "$completion_stamp")"
    completion_log_start="$(backup_stamp_offset_datetime "$completion_stamp" "-5M")"
    completion_log_end="$(backup_stamp_offset_datetime "$completion_stamp" "+5M")"
  else
    completion_datetime=""
    completion_source="latest backup lookup did not return a parseable backup timestamp"
    completion_log_start=""
    completion_log_end=""
  fi

  list_count="$(tmutil listbackups 2>/dev/null | wc -l | tr -d ' ' || true)"
  {
    print_common_header "Completion Check" "$completion_datetime" "$completion_stamp"

    echo "## Current Status"
    tmutil status 2>&1 || true
    echo
    echo "## Destination"
    tmutil destinationinfo 2>&1 || true
    echo
    echo "## Latest Backup"
    if [[ -n "$latest" ]]; then
      echo "$latest"
      if [[ -e "$latest" ]]; then
        echo
        echo "Latest path is directly visible to the shell."
        ls -ld "$latest" 2>&1 || true
      else
        echo
        echo "Latest path is recorded by Time Machine but is not directly visible as a mounted filesystem path."
      fi
    else
      echo "No generic latest backup returned."
    fi
    echo
    echo "## Targeted Latest Backup"
    if [[ -n "$targeted_latest" ]]; then
      echo "$targeted_latest"
    else
      tmutil latestbackup -d "$TIME_MACHINE_DEST" -t 2>&1 || true
    fi
    echo
    echo "## Backup Completion Timestamp Source"
    echo "$completion_source"
    echo
    echo "## Backup List"
    tmutil listbackups 2>&1 || true
    echo
    echo "## Targeted Backup List"
    tmutil listbackups -d "$TIME_MACHINE_DEST" -t 2>&1 || true
    echo
    echo "## APFS Time Machine Snapshots"
    diskutil apfs listSnapshots "$TIME_MACHINE_DEST" 2>&1 || true
    echo
    echo "## Backup Count"
    echo "${list_count:-unknown}"
    echo
    echo "## Exclusions"
    tmutil isexcluded "$EXTERNAL_DATA_VOLUME" 2>&1 || true
    tmutil isexcluded "$TIME_MACHINE_DEST" 2>&1 || true
    echo
    echo "## Destination Disk Info"
    diskutil info "$TIME_MACHINE_DEST" 2>&1 || true
    echo
    echo "## Recommended Time Machine Log Capture"
    if [[ -n "$completion_log_start" && -n "$completion_log_end" ]]; then
      echo "The completion log window is not embedded here because Time Machine logs are noisy."
      echo "Run this separately when you need log evidence around the completed backup timestamp:"
      echo
      echo '```bash'
      printf './bin/run-time-machine.sh logs --start %q --end %q --open\n' "$completion_log_start" "$completion_log_end"
      echo '```'
    else
      echo "The latest backup completion timestamp could not be derived."
      echo "Run a manual log capture with a chosen range:"
      echo
      echo '```bash'
      echo './bin/run-time-machine.sh logs --start "YYYY-MM-DD HH:MM:SS" --end "YYYY-MM-DD HH:MM:SS" --open'
      echo '```'
    fi
  } > "$out"

  if $COMPARE; then
    run_compare || true
  fi

  say "Wrote: $out"
  maybe_open "$out"
}

run_compare() {
  need_cmd tmutil
  need_cmd diskutil
  local -a stamps
  local line count previous_stamp latest_stamp tm_device
  local previous_mount latest_mount previous_root latest_root relative_path
  local previous_item latest_item out compare_status
  local previous_was_mounted latest_was_mounted

  stamps=()
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    stamps+=("$(latest_stamp "$line")")
  done < <(targeted_backup_list)

  if [[ "${#stamps[@]}" -lt 2 ]]; then
    stamps=()
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      stamps+=("$(latest_stamp "$line")")
    done < <(tmutil listbackups 2>/dev/null || true)
  fi

  count="${#stamps[@]}"
  if [[ -z "$count" || "$count" -lt 2 ]]; then
    say "Not enough backups to compare. Need at least 2 completed backups."
    return 0
  fi

  previous_stamp="${stamps[$((count - 2))]}"
  latest_stamp="${stamps[$((count - 1))]}"
  tm_device="$(resolve_tm_device)"

  if [[ -z "$tm_device" ]]; then
    err "could not resolve the device node for $TIME_MACHINE_DEST. Confirm the Time Machine destination is mounted."
    exit 2
  fi

  previous_mount="$(helper_mount_point_for_stamp "$previous_stamp")"
  latest_mount="$(helper_mount_point_for_stamp "$latest_stamp")"
  previous_root="$previous_mount/$previous_stamp"
  latest_root="$latest_mount/$latest_stamp"
  previous_was_mounted=false
  latest_was_mounted=false

  is_helper_mount_active "$previous_mount" && previous_was_mounted=true
  is_helper_mount_active "$latest_mount" && latest_was_mounted=true

  out="$(artifact_path compare txt)"
  {
    printf 'Previous stamp: %s\n' "$previous_stamp"
    printf 'Latest stamp  : %s\n' "$latest_stamp"
    printf 'Time Machine  : %s\n' "$TIME_MACHINE_DEST"
    printf 'Device node   : %s\n' "$tm_device"
    echo
    echo '## Backup List Used'
    printf '%s\n' "${stamps[@]}"
    echo
    echo '## Mount Previous Snapshot'
  } | tee "$out"

  if ! ensure_snapshot_mounted "$previous_stamp" "$tm_device" "$previous_mount" 2>&1 | tee -a "$out"; then
    err "could not mount previous snapshot for compare. Review $out"
    maybe_open "$out"
    return 2
  fi

  {
    echo
    echo '## Mount Latest Snapshot'
  } | tee -a "$out"

  if ! ensure_snapshot_mounted "$latest_stamp" "$tm_device" "$latest_mount" 2>&1 | tee -a "$out"; then
    err "could not mount latest snapshot for compare. Review $out"
    maybe_open "$out"
    return 2
  fi

  relative_path="$(choose_compare_path "$previous_root" "$latest_root")"
  previous_item="$previous_root/$relative_path"
  latest_item="$latest_root/$relative_path"

  {
    echo
    echo '## Compare Target'
    if [[ -n "$COMPARE_PATH" ]]; then
      printf 'Requested path: %s\n' "$COMPARE_PATH"
    fi
    printf 'Relative path : %s\n' "$relative_path"
    printf 'Previous item : %s\n' "$previous_item"
    printf 'Latest item   : %s\n' "$latest_item"
    echo
  } | tee -a "$out"

  if [[ ! -e "$previous_item" || ! -e "$latest_item" ]]; then
    {
      echo 'ERROR: compare target cannot be compared because it is not present in both snapshots.'
      echo
      compare_missing_interpretation "$previous_item" "$latest_item"
      echo
      if [[ -n "$COMPARE_PATH" ]]; then
        print_compare_candidate_report "$previous_root" "$latest_root" "$COMPARE_PATH"
      fi
      echo 'For a broader spot check, run one of these:'
      # Single-quoted on purpose: $(whoami) must reach the reader's terminal
      # literally so the suggestion works for whoever pastes it, rather than
      # baking this run's user name into the evidence file.
      # shellcheck disable=SC2016
      echo '  ./bin/run-time-machine.sh compare --compare-path Data/Users/$(whoami) --open'
      echo '  ./bin/run-time-machine.sh compare --compare-path Data --open'
    } | tee -a "$out"
    cleanup_compare_mounts "$previous_mount" "$latest_mount" "$previous_was_mounted" "$latest_was_mounted" "$out"
    maybe_open "$out"
    return 2
  fi

  {
    echo '## tmutil compare Output'
    echo 'Command:'
    printf 'sudo tmutil compare %q %q\n' "$previous_item" "$latest_item"
    echo
  } | tee -a "$out"

  set +e
  sudo tmutil compare "$previous_item" "$latest_item" 2>&1 | tee -a "$out"
  compare_status=${PIPESTATUS[0]}
  set -e

  {
    echo
    printf 'tmutil compare exit status: %s\n' "$compare_status"
  } | tee -a "$out"

  cleanup_compare_mounts "$previous_mount" "$latest_mount" "$previous_was_mounted" "$latest_was_mounted" "$out"

  say "Wrote: $out"
  maybe_open "$out"

  if [[ "$compare_status" -ne 0 ]]; then
    say "tmutil compare exited with status $compare_status. Review output in $out."
  fi
}

mount_latest_snapshot() {
  need_cmd tmutil
  need_cmd diskutil
  local latest targeted stamp snapshot_name tm_device mount_point mounted_backup_path
  latest="$(latest_backup)"
  targeted="$(targeted_latest_timestamp)"

  if [[ -n "$latest" ]]; then
    stamp="$(latest_stamp "$latest")"
  elif [[ -n "$targeted" ]]; then
    stamp="$(latest_stamp "$targeted")"
  else
    err "Neither generic tmutil latestbackup nor targeted latestbackup -d $TIME_MACHINE_DEST -t returned a backup."
    exit 2
  fi

  snapshot_name="$(snapshot_name_for_stamp "$stamp")"
  tm_device="$(resolve_tm_device)"
  mount_point="$(helper_mount_point_for_stamp "$stamp")"
  mounted_backup_path="$mount_point/$stamp"

  if [[ -z "$tm_device" ]]; then
    err "could not resolve the device node for $TIME_MACHINE_DEST. Confirm the Time Machine destination is mounted."
    exit 2
  fi

  say "Latest backup        : ${latest:-<generic latestbackup failed>}"
  say "Targeted latest stamp: ${targeted:-<targeted latestbackup failed>}"
  say "Snapshot name        : $snapshot_name"
  say "Time Machine         : $TIME_MACHINE_DEST"
  say "Device node          : $tm_device"
  say "Mount point          : $mount_point"

  if [[ -n "$latest" && -e "$latest" ]]; then
    say "Latest backup path is already directly visible: $latest"
    maybe_open "$latest"
    return 0
  fi

  mkdir -p "$mount_point"

  say "Checking whether snapshot name appears in diskutil apfs listSnapshots output..."
  diskutil apfs listSnapshots "$TIME_MACHINE_DEST" 2>/dev/null | grep -F "$snapshot_name" || true

  if ensure_snapshot_mounted "$stamp" "$tm_device" "$mount_point"; then
    if [[ -e "$mounted_backup_path" ]]; then
      say "OK: mounted backup path is visible: $mounted_backup_path"
      ls -ld "$mounted_backup_path" || true
      maybe_open "$mounted_backup_path"
    else
      say "INFO: nested backup path was not found; mounted snapshot root is visible: $mount_point"
      ls -la "$mount_point" | head -40 || true
      maybe_open "$mount_point"
    fi
  fi
}
unmount_latest_snapshot() {
  need_cmd tmutil
  need_cmd diskutil
  local latest targeted stamp mount_point
  latest="$(latest_backup)"
  targeted="$(targeted_latest_timestamp)"

  if [[ -n "$latest" ]]; then
    stamp="$(latest_stamp "$latest")"
  elif [[ -n "$targeted" ]]; then
    stamp="$(latest_stamp "$targeted")"
  else
    err "Neither generic nor targeted latestbackup returned a backup timestamp."
    exit 2
  fi

  mount_point="$(helper_mount_point_for_stamp "$stamp")"

  if [[ -d "$mount_point" ]]; then
    diskutil unmount "$mount_point" || true
    rmdir "$mount_point" 2>/dev/null || true
    say "Unmounted helper mount point: $mount_point"
  else
    say "No helper mount point found: $mount_point"
  fi
}
choose_verify_target() {
  local backup_root_path="$1"
  local user_name rel candidate

  if $FULL_SNAPSHOT; then
    printf '%s\n' "$backup_root_path"
    return 0
  fi

  if [[ -n "${VERIFY_PATH:-}" ]]; then
    rel="$(normalize_compare_path "$VERIFY_PATH")"
    if [[ -e "$backup_root_path/$rel" ]]; then
      printf '%s\n' "$backup_root_path/$rel"
      return 0
    fi
    err "verify path is not present in latest backup: $backup_root_path/$rel"
    return 2
  fi

  user_name="$(whoami)"
  for candidate in \
    "Data/Users/${user_name}/Development" \
    "Data/Users/${user_name}/Documents" \
    "Data/Users/${user_name}/Desktop" \
    "Data/Users/${user_name}"; do
    if [[ -e "$backup_root_path/$candidate" ]]; then
      printf '%s\n' "$backup_root_path/$candidate"
      return 0
    fi
  done

  printf '%s\n' "$backup_root_path"
}

verify_latest() {
  need_cmd tmutil
  local latest targeted stamp manual_mount_point manual_backup_path backup_root_path target out status
  local mismatch_failed_count error257_count question_count posix22_count
  latest="$(latest_backup)"
  targeted="$(targeted_latest_timestamp)"

  if [[ -n "$latest" ]]; then
    stamp="$(latest_stamp "$latest")"
  elif [[ -n "$targeted" ]]; then
    stamp="$(latest_stamp "$targeted")"
  else
    err "Neither generic nor targeted latestbackup returned a backup timestamp."
    exit 2
  fi

  manual_mount_point="$(helper_mount_point_for_stamp "$stamp")"
  manual_backup_path="$manual_mount_point/$stamp"
  backup_root_path=""

  if [[ -n "$latest" && -e "$latest" ]]; then
    backup_root_path="$latest"
  elif [[ -e "$manual_backup_path" ]]; then
    backup_root_path="$manual_backup_path"
  elif [[ -d "$manual_mount_point" ]]; then
    backup_root_path="$manual_mount_point"
  elif $MOUNT_IF_NEEDED; then
    mount_latest_snapshot
    if [[ -e "$manual_backup_path" ]]; then
      backup_root_path="$manual_backup_path"
    elif [[ -d "$manual_mount_point" ]]; then
      backup_root_path="$manual_mount_point"
    fi
  fi

  if [[ -z "$backup_root_path" ]]; then
    err "No readable latest backup path is available. Run mount-latest or use --mount-if-needed. Generic latestbackup may fail while targeted -d succeeds; check completion evidence."
    exit 2
  fi

  # Plain assignment would inherit choose_verify_target's exit 2 under set -e and
  # fire the ERR trap, printing a crash message ahead of the intended clean exit.
  if ! target="$(choose_verify_target "$backup_root_path")"; then
    exit 2
  fi
  if [[ -z "$target" || ! -e "$target" ]]; then
    err "No readable verification target is available under latest backup path: $backup_root_path"
    exit 2
  fi

  out="$(artifact_path verifychecksums txt)"
  {
    echo "# Time Machine Checksum Verification"
    echo "Generated   : $(date)"
    echo "Host        : $(hostname)"
    echo "Mount Point : $TIME_MACHINE_DEST"
    echo
    echo "Latest backup stamp : $stamp"
    echo "Backup root path    : $backup_root_path"
    echo "Verification target : $target"
    if $FULL_SNAPSHOT; then
      echo "Verification scope  : full snapshot"
    elif [[ -n "${VERIFY_PATH:-}" ]]; then
      echo "Verification scope  : explicit path inside snapshot"
    else
      echo "Verification scope  : targeted user-data path"
    fi
    echo
    if ! $FULL_SNAPSHOT; then
      echo "Note: targeted verification avoids known restricted system and endpoint-security paths that can make full-snapshot verification noisy."
      echo "Use --full-snapshot only when you intentionally want the broad, noisy verification."
      echo
    fi
    echo "## tmutil verifychecksums output"
  } > "$out"

  say "Verifying: $target"
  set +e
  tmutil verifychecksums "$target" 2>&1 | tee -a "$out"
  status=${PIPESTATUS[0]}
  set -e

  # BSD grep does not implement the GNU \b word boundary, so '^(MISMATCH|FAILED)\b'
  # silently matches nothing on macOS and a corrupt backup reports PASS. Anchor on
  # whitespace or end of line instead, which both BSD and GNU ERE support.
  mismatch_failed_count="$(grep -Ec '^(MISMATCH|FAILED)([[:space:]]|$)' "$out" 2>/dev/null || true)"
  error257_count="$(grep -c 'error 257 enumerating path' "$out" 2>/dev/null || true)"
  question_count="$(grep -Ec '^\?[[:space:]]+' "$out" 2>/dev/null || true)"
  posix22_count="$(grep -c 'POSIXError.*Code=22' "$out" 2>/dev/null || true)"

  {
    echo
    echo "## Verification Summary"
    printf 'tmutil verifychecksums exit status: %s\n' "$status"
    printf 'MISMATCH/FAILED lines: %s\n' "$mismatch_failed_count"
    printf 'error 257 enumerating path lines: %s\n' "$error257_count"
    printf 'question-mark no-checksum lines: %s\n' "$question_count"
    printf 'POSIXError Code=22 lines: %s\n' "$posix22_count"
    echo
    if [[ "$mismatch_failed_count" -gt 0 ]]; then
      echo "Interpretation: FAILED. Review MISMATCH/FAILED lines."
    elif [[ "$status" -eq 0 ]]; then
      echo "Interpretation: PASS. No checksum mismatches or failed reads were reported for the selected verification target."
    else
      echo "Interpretation: REVIEW. No MISMATCH/FAILED lines were reported for the selected target. If this was a full-snapshot verification, rerun without --full-snapshot or use --verify-path to avoid restricted system/app paths."
    fi
  } >> "$out"

  say "Wrote: $out"
  if [[ "$mismatch_failed_count" -gt 0 ]]; then
    err "verifychecksums reported MISMATCH or FAILED entries. Review $out"
    exit 3
  fi
  if [[ "$status" -ne 0 ]]; then
    say "verifychecksums exited with status $status. No MISMATCH/FAILED lines were found; review the summary in $out."
  fi
  maybe_open "$out"
}

capture_diagnose() {
  local out
  out="$(artifact_path diagnose txt)"
  {
    echo "# Time Machine Diagnostics"
    echo "Generated: $(date)"
    echo
    echo "## tmutil status"
    tmutil status 2>&1 || true
    echo
    echo "## pmset sleep state"
    pmset -g 2>&1 | grep -E 'sleep|displaysleep|powernap|standby' || pmset -g 2>&1 || true
    echo
    echo "## Recent Time Machine logs"
    if command -v log >/dev/null 2>&1; then
      command log show --predicate 'subsystem == "com.apple.TimeMachine"' --last "$LOG_WINDOW" 2>&1 | tail -120 || true
    else
      echo "macOS log command not available."
    fi
    echo
    echo "## backupd fs_usage sample"
    echo "The following command may require sudo and may not run unattended:"
    echo "sudo fs_usage -f filesys backupd 2>/dev/null | head -30"
    if command -v fs_usage >/dev/null 2>&1; then
      sudo fs_usage -f filesys backupd 2>/dev/null | head -30 || true
    else
      echo "fs_usage not found."
    fi
  } > "$out"
  say "Wrote: $out"
  maybe_open "$out"
}

eject_volumes() {
  need_cmd diskutil
  # --physical-disk is the documented recovery path for a partially completed
  # eject: one volume is already unmounted by then, so requiring the destination
  # and data volumes here would block the retry it exists for. Both requirements
  # therefore sit after this branch, not before it.
  if [[ -n "$PHYSICAL_DISK" ]]; then
    say "Ejecting physical disk: $PHYSICAL_DISK"
    diskutil eject "$PHYSICAL_DISK"
    return
  fi
  require_time_machine_dest
  require_external_data_volume
  say "Ejecting data volume: $EXTERNAL_DATA_VOLUME"
  diskutil eject "$EXTERNAL_DATA_VOLUME" || true
  say "Ejecting Time Machine volume: $TIME_MACHINE_DEST"
  diskutil eject "$TIME_MACHINE_DEST" || true
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

COMMAND="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    # Every parameterized option checks its value. The reference-vault original
    # read "$2" bare, so `--physical-disk` with nothing after it expanded to an
    # empty disk identifier and reached diskutil.
    --artifact-root)
      require_option_value "$1" "${2:-}"; REIMAGE_ARTIFACT_ROOT="$2"; shift 2 ;;
    --time-machine-dest)
      require_option_value "$1" "${2:-}"; TIME_MACHINE_DEST="$2"; shift 2 ;;
    --external-data-root)
      require_option_value "$1" "${2:-}"; EXTERNAL_DATA_VOLUME="$2"; shift 2 ;;
    --interval)
      require_option_value "$1" "${2:-}"
      # `--interval 0` (or any non-numeric value) turns monitor into a busy loop
      # around tmutil status. Same positive-integer rule as backup-repos.sh
      # --status-interval.
      case "$2" in
        ''|*[!0-9]*|0*)
          err "--interval requires a positive integer, got: $2"
          usage >&2
          exit 2
          ;;
      esac
      INTERVAL="$2"; shift 2 ;;
    --last)
      require_option_value "$1" "${2:-}"; LOG_WINDOW="$2"; shift 2 ;;
    --start)
      require_option_value "$1" "${2:-}"; LOG_START="$2"; shift 2 ;;
    --end)
      require_option_value "$1" "${2:-}"; LOG_END="$2"; shift 2 ;;
    --auto) AUTO=true; shift ;;
    --block) BLOCK=true; shift ;;
    --compare) COMPARE=true; shift ;;
    --compare-path)
      require_option_value "$1" "${2:-}"; COMPARE_PATH="$2"; shift 2 ;;
    --mount-if-needed) MOUNT_IF_NEEDED=true; shift ;;
    --verify-path)
      require_option_value "$1" "${2:-}"; VERIFY_PATH="$2"; shift 2 ;;
    --full-snapshot) FULL_SNAPSHOT=true; shift ;;
    --physical-disk)
      require_option_value "$1" "${2:-}"; PHYSICAL_DISK="$2"; shift 2 ;;
    --open) OPEN_OUTPUT=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option for ${COMMAND}: $1"; usage; exit 2 ;;
  esac
done

resolve_external_data_volume

case "$COMMAND" in
  # start/monitor/logs/diagnose talk to the running Time Machine service and
  # never pass -d, so they work with no destination resolved. Everything else
  # addresses the destination volume directly and must have it. eject checks it
  # internally, after the --physical-disk recovery branch.
  start) start_backup ;;
  monitor) monitor_backup ;;
  logs) capture_logs ;;
  diagnose) capture_diagnose ;;
  status) require_time_machine_dest; capture_status ;;
  complete) require_time_machine_dest; capture_complete ;;
  compare) require_time_machine_dest; run_compare ;;
  mount-latest) require_time_machine_dest; mount_latest_snapshot ;;
  verify-latest) require_time_machine_dest; verify_latest ;;
  unmount-latest) require_time_machine_dest; unmount_latest_snapshot ;;
  eject) eject_volumes ;;
  -h|--help|help) usage ;;
  *) err "Unknown command: $COMMAND"; usage; exit 2 ;;
esac
