#!/usr/bin/env bash
# =============================================================================
# capture-performance-audit.sh
#
# Read-only general performance audit for macOS (Phase 4C pre-image /
# Phase 13D post-image). Captures short-duration, per-scenario bundles under a
# named workload so general workstation performance can be compared like-for-
# like across a reimage: memory pressure, swap, compressed memory, top
# memory/CPU processes, Docker resource settings, IntelliJ heap settings,
# responsiveness probes, workload process context, and optional
# mac_memory_health helper output. Writes one timestamped bundle under
# performance-audit/. It observes and records only — it does not purge memory,
# stop or restart apps, change Docker settings, or change managed app state.
# See capture-performance-audit.md for the full runbook.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/capture-performance-audit.sh
#
#   # Pre-image normal-workload baseline (Phase 4C)
#   ./bin/capture-performance-audit.sh --phase pre-image --scenario normal-workload
#
#   # Longer baseline with more samples
#   ./bin/capture-performance-audit.sh --phase pre-image --scenario normal-workload --sample-count 6 --sample-interval 30
#
#   # Post-image comparison run (Phase 13D), same scenario name
#   ./bin/capture-performance-audit.sh --phase post-image --scenario normal-workload --sample-count 6 --sample-interval 30
#
#   # Override the artifact root for this invocation
#   ./bin/capture-performance-audit.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Stage under a local workspace before the backup drive is mounted
#   ./bin/capture-performance-audit.sh --output /absolute/path/to/performance-audit
#
# Options:
#   --artifact-root PATH   Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --output DIR           Root output directory for the bundle. Overrides the
#                          default REIMAGE_ARTIFACT_ROOT/performance-audit layout
#                          (use it to stage under REIMAGE_WORKSPACE_ROOT).
#   --sample-count N       Number of repeated baseline samples. Default: 3
#   --sample-interval SEC  Seconds between repeated samples. Default: 10
#   --top N                Number of top memory/CPU processes to capture. Default: 40
#   --phase NAME           Capture phase label, e.g. pre-image (Phase 4C) or
#                          post-image (Phase 13D). Default: pre-image
#   --scenario NAME        Workload label, e.g. clean-boot, normal-workload,
#                          active-dev, symptom-capture. Must contain at least one
#                          letter, digit, '.', '-', or '_'. Default: normal-workload
#   --note TEXT            Optional note copied into README and manual-observations.md.
#   --no-helper            Do not run ~/.local/bin/mac_memory_health.sh even if present.
#   --no-docker            Skip docker version/info commands.
#   -h, --help             Show this message and exit.
#
# This capture is read-only. It does not purge memory, kill or restart apps,
# change Docker settings, or change managed app state. The output may include
# local usernames, hostnames, process command lines, and application paths;
# review before sharing externally.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Exit status:
#   0  Capture completed successfully.
#   1  Ran on an unsupported platform or hit a runtime failure.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

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

# Keep loading permissive so --artifact-root / --output can override values
# after parsing. The resolved destination is validated below.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

VERSION="1.0.5"
SCRIPT_NAME="$(basename "$0")"
START_EPOCH="$(date +%s)"

# ---------------------------------------------------------------------------
# Defaults and command-line state
# ---------------------------------------------------------------------------
OUTPUT_ROOT=""
SAMPLE_COUNT=3
PHASE_LABEL="pre-image"
SCENARIO_LABEL="normal-workload"
NOTE_TEXT=""
SAMPLE_INTERVAL=10
TOP_N=40
RUN_HELPER=1
RUN_DOCKER=1
RUN_ID=""
AUDIT_DIR=""

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

# ---------------------------------------------------------------------------
# Parse command-line options
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --output)
      require_option_value "$1" "${2:-}"
      OUTPUT_ROOT="$2"
      shift 2
      ;;
    --sample-count)
      require_option_value "$1" "${2:-}"
      SAMPLE_COUNT="$2"
      if [[ ! "$SAMPLE_COUNT" =~ ^[0-9]+$ || "$SAMPLE_COUNT" -lt 1 ]]; then
        echo "ERROR: --sample-count requires a positive integer, got: $SAMPLE_COUNT" >&2
        usage >&2
        exit 2
      fi
      shift 2
      ;;
    --sample-interval)
      require_option_value "$1" "${2:-}"
      SAMPLE_INTERVAL="$2"
      if [[ ! "$SAMPLE_INTERVAL" =~ ^[0-9]+$ ]]; then
        echo "ERROR: --sample-interval requires an integer, got: $SAMPLE_INTERVAL" >&2
        usage >&2
        exit 2
      fi
      shift 2
      ;;
    --top)
      require_option_value "$1" "${2:-}"
      TOP_N="$2"
      if [[ ! "$TOP_N" =~ ^[0-9]+$ || "$TOP_N" -lt 1 ]]; then
        echo "ERROR: --top requires a positive integer, got: $TOP_N" >&2
        usage >&2
        exit 2
      fi
      shift 2
      ;;
    --phase)
      require_option_value "$1" "${2:-}"
      PHASE_LABEL="$2"
      shift 2
      ;;
    --scenario)
      require_option_value "$1" "${2:-}"
      SCENARIO_LABEL="$2"
      shift 2
      ;;
    --note)
      # Deliberately not require_option_value: an empty note is a valid value,
      # so this only rejects a missing one.
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --note requires a value." >&2
        usage >&2
        exit 2
      fi
      NOTE_TEXT="$2"
      shift 2
      ;;
    --no-helper)
      RUN_HELPER=0
      shift
      ;;
    --no-docker)
      RUN_DOCKER=0
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

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is intended for macOS only." >&2
  exit 1
fi

# Validate the capture phase, consistent with capture-managed-inventory.sh's
# --context gate. Accept pre-image / post-image and suffixed variants
# (e.g. post-image-recheck); reject slashes, '..', a leading dot, or whitespace.
case "$PHASE_LABEL" in
  pre-image|post-image|pre-image-?*|post-image-?*)
    case "$PHASE_LABEL" in
      *[/\\]*|*..*|.*|*[[:space:]]*)
        echo "ERROR: --phase must not contain slashes, '..', a leading dot, or whitespace, got: $PHASE_LABEL" >&2
        exit 2
        ;;
    esac
    ;;
  *)
    echo "ERROR: --phase must be pre-image, post-image, or start with pre-image- or post-image- (e.g. post-image-recheck), got: $PHASE_LABEL" >&2
    exit 2
    ;;
esac

# ---------------------------------------------------------------------------
# Resolve the output root after parsing.
#   --output overrides the standard layout entirely (e.g. local staging under
#   REIMAGE_WORKSPACE_ROOT). Otherwise default to the artifact-root layout.
# ---------------------------------------------------------------------------
if [[ -z "$OUTPUT_ROOT" ]]; then
  if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set." >&2
    echo "Create/source reimage.env, pass --artifact-root PATH, or pass --output DIR." >&2
    exit 2
  fi
  if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
    echo "ERROR: artifact root not found: $REIMAGE_ARTIFACT_ROOT" >&2
    exit 2
  fi
  OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/performance-audit"
fi

# Make the destination absolute before the repo-write guard below. A relative
# --output / --artifact-root would otherwise never match "$REPO_ROOT"/* even
# when it resolves inside the checkout. The path does not exist yet, so resolve
# the deepest existing ancestor and re-append the missing components.
resolve_output_path() {
  local path="$1"
  local suffix=""

  if [[ "$path" != /* ]]; then
    path="$PWD/$path"
  fi
  while [[ ! -d "$path" && "$path" != "/" ]]; do
    suffix="/$(basename "$path")$suffix"
    path="$(dirname "$path")"
  done
  path="$(cd "$path" && pwd)"
  printf '%s%s' "${path%/}" "$suffix"
}

OUTPUT_ROOT="$(resolve_output_path "$OUTPUT_ROOT")"

# Safety invariant: never write a bundle inside the repo checkout. A copy under
# the working tree is not a real artifact and usually signals an unset root.
if [[ -n "${REPO_ROOT:-}" && ( "$OUTPUT_ROOT" == "$REPO_ROOT" || "$OUTPUT_ROOT" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $OUTPUT_ROOT" >&2
  exit 2
fi

sanitize_label() {
  printf '%s' "$1" | tr '/ :()[]{}' '________' | tr -cd '[:alnum:]_.-'
}

PHASE_SAFE="$(sanitize_label "$PHASE_LABEL")"
SCENARIO_SAFE="$(sanitize_label "$SCENARIO_LABEL")"

# A scenario that sanitizes away entirely (e.g. "///") would silently produce a
# run directory with an empty scenario component, so reject it like --phase.
if [[ -z "$SCENARIO_SAFE" ]]; then
  echo "ERROR: --scenario must contain at least one letter, digit, '.', '-', or '_', got: $SCENARIO_LABEL" >&2
  exit 2
fi

RUN_ID="${PHASE_SAFE}-performance-audit-${SCENARIO_SAFE}-$(date +%Y%m%d-%H%M%S)"
AUDIT_DIR="$OUTPUT_ROOT/$RUN_ID"
LOG_DIR="$AUDIT_DIR/logs"
RAW_DIR="$AUDIT_DIR/raw"
SYSTEM_DIR="$AUDIT_DIR/system"
MEMORY_DIR="$AUDIT_DIR/memory"
PROCESS_DIR="$AUDIT_DIR/processes"
DOCKER_DIR="$AUDIT_DIR/docker"
INTELLIJ_DIR="$AUDIT_DIR/intellij"
RESPONSIVENESS_DIR="$AUDIT_DIR/responsiveness"
HELPER_DIR="$AUDIT_DIR/mac-memory-health-output"
SUMMARY="$AUDIT_DIR/README.md"
COMMAND_LOG="$LOG_DIR/commands.log"
ERROR_LOG="$LOG_DIR/errors.log"

mkdir -p "$LOG_DIR" "$RAW_DIR" "$SYSTEM_DIR" "$MEMORY_DIR" "$PROCESS_DIR" "$DOCKER_DIR" "$INTELLIJ_DIR" "$RESPONSIVENESS_DIR" "$HELPER_DIR"

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'WARNING: %s\n' "$*" | tee -a "$ERROR_LOG" >&2
}

section_file() {
  local file="$1"
  local title="$2"
  {
    echo "# $title"
    echo
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo
  } > "$file"
}

run_cmd() {
  local outfile="$1"
  local title="$2"
  shift 2
  {
    echo "================================================================================"
    echo "$title"
    echo "================================================================================"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    printf 'Command:'
    printf ' %q' "$@"
    echo
    echo
  } >> "$outfile"
  {
    printf '[%s] ' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    printf '%q ' "$@"
    echo "-> $outfile"
  } >> "$COMMAND_LOG"
  "$@" >> "$outfile" 2>> "$ERROR_LOG" || {
    local rc=$?
    echo "[command exited with code $rc]" >> "$outfile"
    printf '[%s] command exited with code %s: ' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$rc" >> "$ERROR_LOG"
    printf '%q ' "$@" >> "$ERROR_LOG"
    echo >> "$ERROR_LOG"
  }
  echo >> "$outfile"
}

append_cmd() {
  local outfile="$1"
  local title="$2"
  shift 2
  run_cmd "$outfile" "$title" "$@"
}

capture_ps_csv() {
  local outfile="$1"
  local sort_field="$2"
  local limit="$3"
  {
    echo 'pid,ppid,elapsed,state,cpu_pct,mem_pct,rss_mb,command'
    ps -axo pid=,ppid=,etime=,stat=,%cpu=,%mem=,rss=,command= 2>> "$ERROR_LOG" \
      | sort -k"${sort_field},${sort_field}nr" \
      | head -n "$limit" \
      | awk '
          function csv(v) { gsub(/"/, "\"\"", v); return "\"" v "\"" }
          {
            pid=$1; ppid=$2; etime=$3; stat=$4; cpu=$5; mem=$6; rss=$7;
            cmd=$8; for (i=9; i<=NF; i++) cmd=cmd " " $i;
            printf "%s,%s,%s,%s,%s,%s,%.2f,%s\n", pid, ppid, etime, stat, cpu, mem, rss/1024, csv(cmd)
          }' || true
  } > "$outfile"
}

capture_matching_processes() {
  local outfile="$1"
  local pattern="$2"
  {
    echo 'pid,ppid,elapsed,state,cpu_pct,mem_pct,rss_mb,command'
    ps -axo pid=,ppid=,etime=,stat=,%cpu=,%mem=,rss=,command= 2>> "$ERROR_LOG" \
      | awk -v pat="$pattern" '
          function csv(v) { gsub(/"/, "\"\"", v); return "\"" v "\"" }
          {
            pid=$1; ppid=$2; etime=$3; stat=$4; cpu=$5; mem=$6; rss=$7;
            cmd=$8; for (i=9; i<=NF; i++) cmd=cmd " " $i;
            if (cmd ~ pat && cmd !~ /capture-performance-audit/) {
              printf "%s,%s,%s,%s,%s,%s,%.2f,%s\n", pid, ppid, etime, stat, cpu, mem, rss/1024, csv(cmd)
            }
          }' || true
  } > "$outfile"
}

capture_app_rollup() {
  local outfile="$1"
  {
    echo 'app,rss_mb,cpu_pct,process_count,top_pid,top_rss_mb,sample_command'
    ps -axo pid=,rss=,%cpu=,command= 2>> "$ERROR_LOG" \
      | awk '
          function classify(cmd) {
            if (cmd ~ /Microsoft Outlook/) return "Microsoft Outlook";
            if (cmd ~ /Microsoft OneNote/) return "Microsoft OneNote";
            if (cmd ~ /Microsoft Teams|MSTeams/) return "Microsoft Teams";
            if (cmd ~ /IntelliJ IDEA|JetBrains|idea/) return "IntelliJ IDEA";
            if (cmd ~ /Google Chrome|Chrome Helper/) return "Google Chrome";
            if (cmd ~ /Visual Studio Code|Code Helper/) return "VS Code";
            if (cmd ~ /Postman/) return "Postman";
            if (cmd ~ /Obsidian/) return "Obsidian";
            if (cmd ~ /Docker|com\.docker/) return "Docker";
            if (cmd ~ /Virtualization\.framework|VirtualMachine/) return "Apple Virtualization";
            if (cmd ~ /\/opt\/homebrew\/bin\/copilot|node .*copilot|copilot --allow-tool/) return "Copilot CLI";
            if (cmd ~ /gradle|GradleDaemon|org\.gradle/) return "Gradle";
            if (cmd ~ /java/) return "Java";
            if (cmd ~ /node/) return "node";
            if (cmd ~ /Terminal\.app|iTerm|zsh|bash/) return "Shell/Terminal";
            return "Other";
          }
          function csv(v) { gsub(/"/, "\"\"", v); return "\"" v "\"" }
          {
            pid=$1; rss=$2; cpu=$3; cmd=$4; for (i=5; i<=NF; i++) cmd=cmd " " $i;
            app=classify(cmd); rss_mb=rss/1024;
            rss_sum[app]+=rss_mb; cpu_sum[app]+=cpu; count[app]++;
            if (rss_mb > top_rss[app]) { top_rss[app]=rss_mb; top_pid[app]=pid; sample[app]=cmd; }
          }
          END {
            for (app in rss_sum) {
              printf "%s,%.2f,%.1f,%d,%s,%.2f,%s\n", csv(app), rss_sum[app], cpu_sum[app], count[app], top_pid[app], top_rss[app], csv(sample[app]);
            }
          }' \
      | sort -t, -k2,2nr || true
  } > "$outfile"
}

capture_parent_chain_for_pid() {
  local pid="$1"
  local outfile="$2"
  local current="$pid"
  local seen=""
  while [[ -n "$current" && "$current" != "1" ]]; do
    if [[ "$seen" == *" $current "* ]]; then
      echo "  stopped: detected process loop at PID $current" >> "$outfile"
      break
    fi
    seen="$seen $current "
    local row
    row="$(ps -p "$current" -o pid=,ppid=,etime=,command= 2>/dev/null || true)"
    [[ -z "$row" ]] && break
    printf '  %s\n' "$row" >> "$outfile"
    current="$(ps -p "$current" -o ppid= 2>/dev/null | tr -d ' ' || true)"
  done
}

capture_dev_agent_parent_chains() {
  local outfile="$1"
  section_file "$outfile" "Development Agent Parent Chains"
  echo "Read-only capture of copilot/codex/claude/aider/cursor-agent parent processes." >> "$outfile"
  echo >> "$outfile"
  local pids
  pids="$(ps -axo pid=,command= 2>/dev/null | awk '
    {
      pid=$1; cmd=$2; for (i=3; i<=NF; i++) cmd=cmd " " $i;
      if (cmd ~ /(\/opt\/homebrew\/bin\/copilot|node .*copilot|copilot --allow-tool|codex|claude|aider|cursor-agent)/ && cmd !~ /capture-performance-audit/) print pid;
    }' | sort -n | uniq || true)"
  if [[ -z "$pids" ]]; then
    echo "No matching development agent processes found." >> "$outfile"
  else
    while IFS= read -r pid; do
      [[ -z "$pid" ]] && continue
      echo >> "$outfile"
      echo "## Agent PID: $pid" >> "$outfile"
      capture_parent_chain_for_pid "$pid" "$outfile"
    done <<< "$pids"
  fi
}

capture_memory_sample() {
  local sample_num="$1"
  local prefix="$MEMORY_DIR/sample_${sample_num}"
  local memory_txt="${prefix}_memory.txt"
  local top_mem_csv="${prefix}_top_memory.csv"
  local top_cpu_csv="${prefix}_top_cpu.csv"
  local app_rollup_csv="${prefix}_app_rollup.csv"

  section_file "$memory_txt" "Memory Baseline Sample $sample_num"
  append_cmd "$memory_txt" "date" date
  append_cmd "$memory_txt" "uptime" uptime
  append_cmd "$memory_txt" "vm_stat" vm_stat
  append_cmd "$memory_txt" "memory_pressure" memory_pressure
  append_cmd "$memory_txt" "sysctl vm.swapusage" sysctl vm.swapusage
  append_cmd "$memory_txt" "top one-shot memory overview" top -l 1 -s 0 -n 20 -o mem

  capture_ps_csv "$top_mem_csv" "7" "$TOP_N"
  capture_ps_csv "$top_cpu_csv" "5" "$TOP_N"
  capture_app_rollup "$app_rollup_csv"
}

capture_system() {
  local file="$SYSTEM_DIR/system-overview.txt"
  section_file "$file" "System Overview"
  append_cmd "$file" "date" date
  append_cmd "$file" "hostname" hostname
  append_cmd "$file" "scutil ComputerName" scutil --get ComputerName
  append_cmd "$file" "macOS version" sw_vers
  append_cmd "$file" "uname" uname -a
  append_cmd "$file" "architecture" arch
  append_cmd "$file" "uptime" uptime
  append_cmd "$file" "boot time" sysctl kern.boottime
  append_cmd "$file" "hardware memory" sysctl hw.memsize
  append_cmd "$file" "CPU brand" sysctl machdep.cpu.brand_string
  append_cmd "$file" "CPU core counts" sysctl hw.physicalcpu hw.logicalcpu
  append_cmd "$file" "load average" sysctl vm.loadavg
  append_cmd "$file" "disk free" df -h
  append_cmd "$file" "APFS volumes" diskutil apfs list
  append_cmd "$file" "power / thermal" pmset -g therm
  append_cmd "$file" "battery" pmset -g batt
  append_cmd "$file" "active network interfaces" scutil --nwi
  append_cmd "$file" "VPN services" scutil --nc list
  append_cmd "$file" "login items visible apps" osascript -e 'tell application "System Events" to get name of (application processes where background only is false)'

  local profiler="$SYSTEM_DIR/system-profiler-hardware-software.txt"
  section_file "$profiler" "System Profiler Hardware and Software"
  append_cmd "$profiler" "system_profiler SPHardwareDataType SPSoftwareDataType SPPowerDataType SPDisplaysDataType" system_profiler SPHardwareDataType SPSoftwareDataType SPPowerDataType SPDisplaysDataType
}

capture_processes() {
  capture_ps_csv "$PROCESS_DIR/top_memory_processes.csv" "7" "$TOP_N"
  capture_ps_csv "$PROCESS_DIR/top_cpu_processes.csv" "5" "$TOP_N"
  capture_app_rollup "$PROCESS_DIR/app_rollup.csv"
  capture_matching_processes "$PROCESS_DIR/dev_daily_workload_processes.csv" 'Microsoft Outlook|Microsoft OneNote|Microsoft Teams|MSTeams|Visual Studio Code|Code Helper|IntelliJ|JetBrains|idea|Docker|com\.docker|Google Chrome|Chrome Helper|Obsidian|Terminal|zsh|bash|Postman|node|copilot|gradle|java'
  capture_matching_processes "$PROCESS_DIR/updater_management_processes.csv" 'installer|installd|Microsoft AutoUpdate|Microsoft Update Assistant|com\.microsoft\.autoupdate|appstoreagent|stored|Company Portal|Intune|jamf|Self Service|ManagedClient|mdmclient|softwareupdated'
  capture_dev_agent_parent_chains "$PROCESS_DIR/dev_agent_parent_chains.md"
}

capture_responsiveness() {
  local file="$RESPONSIVENESS_DIR/responsiveness-probes.txt"
  section_file "$file" "Responsiveness Probes"
  {
    echo "These are simple repeatable probes. They are not a benchmark suite; they are useful as same-machine before/after reimage comparison points."
    echo
  } >> "$file"

  append_cmd "$file" "uptime/load average" uptime
  append_cmd "$file" "memory_pressure quick read" memory_pressure

  {
    echo "================================================================================"
    echo "Timing: osascript System Events visible app query"
    echo "================================================================================"
    for i in $(seq 1 5); do
      echo "Run $i"
      /usr/bin/time -p osascript -e 'tell application "System Events" to count application processes' >/dev/null 2>> "$file" || true
    done
    echo
    echo "================================================================================"
    echo "Timing: Python interpreter cold-ish startup, if python3 exists"
    echo "================================================================================"
    if command -v python3 >/dev/null 2>&1; then
      for i in $(seq 1 5); do
        echo "Run $i"
        /usr/bin/time -p python3 - <<'PY' >/dev/null 2>> "$file" || true
print("ok")
PY
      done
    else
      echo "python3 not found"
    fi
    echo
    echo "================================================================================"
    echo "Timing: shell process listing"
    echo "================================================================================"
    for i in $(seq 1 5); do
      echo "Run $i"
      /usr/bin/time -p sh -c 'ps -axo pid,ppid,%cpu,%mem,rss,command >/dev/null' >/dev/null 2>> "$file" || true
    done
  } >> "$file"
}

docker_cli_plugin_inventory() {
  local outfile="$1"
  local plugin_dirs=(
    "$HOME/.docker/cli-plugins"
    "/usr/local/lib/docker/cli-plugins"
    "/opt/homebrew/lib/docker/cli-plugins"
    "/Applications/Docker.app/Contents/Resources/cli-plugins"
  )

  {
    echo "## Docker CLI plugin inventory"
    echo
    echo "This records plugin file state only. Missing stale plugin references are Docker installation state,"
    echo "not performance audit failures."
    echo
  } >> "$outfile"

  local dir
  for dir in "${plugin_dirs[@]}"; do
    {
      echo "Directory: $dir"
      if [[ -d "$dir" ]]; then
        find "$dir" -maxdepth 1 \( -type f -o -type l \) -print 2>/dev/null | sort | while IFS= read -r plugin; do
          if [[ -L "$plugin" ]]; then
            local target
            target="$(readlink "$plugin" 2>/dev/null || true)"
            if [[ -e "$plugin" ]]; then
              /usr/bin/stat -f "  SYMLINK OK modified=%Sm size=%z path=%N -> $target" -t "%Y-%m-%d %H:%M:%S" "$plugin" 2>/dev/null || true
            else
              echo "  BROKEN SYMLINK path=$plugin -> $target"
            fi
          else
            /usr/bin/stat -f "  FILE modified=%Sm size=%z executable=%Sp path=%N" -t "%Y-%m-%d %H:%M:%S" "$plugin" 2>/dev/null || true
          fi
        done
      else
        echo "  MISSING"
      fi
      echo
    } >> "$outfile"
  done
}

run_docker_cmd() {
  local outfile="$1"
  local title="$2"
  shift 2
  {
    echo "================================================================================"
    echo "$title"
    echo "================================================================================"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    printf 'Command:'
    printf ' %q' "$@"
    echo
    echo
  } >> "$outfile"
  {
    printf '[%s] docker-context command: ' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    printf '%q ' "$@"
    echo "-> $outfile"
  } >> "$COMMAND_LOG"

  "$@" >> "$outfile" 2>&1 || {
    local rc=$?
    echo "[docker command exited with code $rc]" >> "$outfile"
    echo "Docker command failures are captured here as Docker state and are not written to logs/errors.log." >> "$outfile"
  }
  echo >> "$outfile"
}

capture_docker() {
  local file="$DOCKER_DIR/docker-baseline.txt"
  local daemon_state="$DOCKER_DIR/docker-daemon-state.txt"
  section_file "$file" "Docker Baseline"
  section_file "$daemon_state" "Docker Daemon State"

  local settings_candidates=(
    "$HOME/Library/Group Containers/group.com.docker/settings-store.json"
    "$HOME/Library/Group Containers/group.com.docker/settings.json"
    "$HOME/Library/Preferences/com.docker.docker.plist"
    "$HOME/Library/Application Support/Docker Desktop/settings.json"
  )

  {
    echo "## Docker settings file candidates"
    echo
    for candidate in "${settings_candidates[@]}"; do
      if [[ -e "$candidate" ]]; then
        echo "EXISTS: $candidate"
        /usr/bin/stat -f "modified=%Sm size=%z path=%N" -t "%Y-%m-%d %H:%M:%S" "$candidate" || true
      else
        echo "MISSING: $candidate"
      fi
    done
    echo
  } >> "$file"

  docker_cli_plugin_inventory "$file"

  if [[ "$RUN_DOCKER" -ne 1 ]]; then
    {
      echo "Docker capture was skipped because --no-docker was provided."
      echo "Docker settings file candidates were still inventoried in docker-baseline.txt."
    } >> "$daemon_state"
  elif ! command -v docker >/dev/null 2>&1; then
    {
      echo "Docker CLI was not found on PATH."
      echo "Docker settings file candidates were still inventoried in docker-baseline.txt."
    } >> "$daemon_state"
  else
    run_docker_cmd "$file" "docker client version" docker --version
    run_docker_cmd "$file" "docker context ls" docker context ls

    local probe="$DOCKER_DIR/docker-info-probe.txt"
    {
      echo "# docker info daemon-readiness probe"
      echo
      echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
      echo
      echo "Command: docker info"
      echo
    } > "$probe"

    if docker info >> "$probe" 2>&1; then
      {
        echo "Docker CLI found: yes"
        echo "Docker daemon reachable: yes"
        echo "Daemon-dependent Docker commands were captured in docker-baseline.txt."
      } >> "$daemon_state"

      run_docker_cmd "$file" "docker version" docker version
      run_docker_cmd "$file" "docker info" docker info
      run_docker_cmd "$file" "docker system df" docker system df
    else
      {
        echo "Docker CLI found: yes"
        echo "Docker daemon reachable: no"
        echo
        echo "Interpretation:"
        echo "- This is expected for a clean-boot / quiet-baseline scenario when Docker Desktop was intentionally not started."
        echo "- Daemon-dependent commands were skipped so logs/errors.log does not report expected clean-boot Docker failures."
        echo "- The suppressed probe output is saved in docker-info-probe.txt for context."
        echo
        echo "Skipped daemon-dependent commands:"
        echo "- docker version"
        echo "- docker info"
        echo "- docker system df"
      } >> "$daemon_state"
    fi
  fi

  local extracted="$DOCKER_DIR/docker-settings-resource-extract.txt"
  section_file "$extracted" "Docker Settings Resource Extract"
  for candidate in "${settings_candidates[@]}"; do
    [[ -e "$candidate" ]] || continue
    {
      echo "================================================================================"
      echo "Candidate: $candidate"
      echo "================================================================================"
    } >> "$extracted"

    if [[ "$candidate" == *.plist ]]; then
      plutil -p "$candidate" 2>> "$ERROR_LOG" | grep -Ei 'memory|mem|cpu|swap|disk|resource|virtualization|vm' >> "$extracted" || true
    elif command -v python3 >/dev/null 2>&1; then
      python3 - "$candidate" >> "$extracted" 2>> "$ERROR_LOG" <<'PY' || true
import json, sys
path = sys.argv[1]
keys = ("memory", "mem", "cpu", "swap", "disk", "resource", "virtual", "vm", "filesharing", "kubernetes")
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception as exc:
    print(f"Could not parse JSON: {exc}")
    sys.exit(0)

def walk(obj, prefix=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            p = f"{prefix}.{k}" if prefix else str(k)
            if any(token in str(k).lower() for token in keys):
                if isinstance(v, (dict, list)):
                    print(f"{p} = {json.dumps(v, sort_keys=True)[:1000]}")
                else:
                    print(f"{p} = {v}")
            walk(v, p)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            walk(v, f"{prefix}[{i}]")
walk(data)
PY
    else
      grep -Ei 'memory|mem|cpu|swap|disk|resource|virtual|vm|kubernetes' "$candidate" >> "$extracted" || true
    fi
    echo >> "$extracted"
  done
}

capture_intellij() {
  local file="$INTELLIJ_DIR/intellij-baseline.txt"
  section_file "$file" "IntelliJ Baseline"

  {
    echo "## IntelliJ application candidates"
    echo
    find /Applications "$HOME/Applications" -maxdepth 4 -iname '*IntelliJ*.app' -print 2>/dev/null | sort || true
    echo
    echo "## Running IntelliJ / Java / Gradle process heap flags"
    echo
    ps -axo pid,ppid,etime,%cpu,%mem,rss,command 2>/dev/null \
      | grep -E 'IntelliJ|JetBrains|idea|java|gradle|GradleDaemon' \
      | grep -v grep || true
    echo
  } >> "$file"

  local vmoptions_list="$INTELLIJ_DIR/intellij-vmoptions-files.txt"
  section_file "$vmoptions_list" "IntelliJ VM Options Files"
  {
    echo "Search locations include /Applications, JetBrains application support, and older preference paths."
    echo
    find \
      /Applications \
      "$HOME/Applications" \
      "$HOME/Library/Application Support/JetBrains" \
      "$HOME/Library/Preferences" \
      -maxdepth 8 \
      \( -name 'idea.vmoptions' -o -name '*idea*.vmoptions' -o -name '*IntelliJ*.vmoptions' \) \
      -print 2>/dev/null | sort || true
  } >> "$vmoptions_list"

  local vmoptions_contents="$INTELLIJ_DIR/intellij-vmoptions-contents.txt"
  section_file "$vmoptions_contents" "IntelliJ VM Options Contents"
  while IFS= read -r vmfile; do
    [[ -f "$vmfile" ]] || continue
    {
      echo "================================================================================"
      echo "$vmfile"
      echo "================================================================================"
      /usr/bin/stat -f "modified=%Sm size=%z path=%N" -t "%Y-%m-%d %H:%M:%S" "$vmfile" || true
      echo
      cat "$vmfile"
      echo
    } >> "$vmoptions_contents"
  done < <(find \
      /Applications \
      "$HOME/Applications" \
      "$HOME/Library/Application Support/JetBrains" \
      "$HOME/Library/Preferences" \
      -maxdepth 8 \
      \( -name 'idea.vmoptions' -o -name '*idea*.vmoptions' -o -name '*IntelliJ*.vmoptions' \) \
      -print 2>/dev/null | sort || true)
}

run_mac_memory_health_helper() {
  # mac_memory_health.sh is a separate, optional workstation helper that lives
  # outside this toolkit (documented location: ~/.local/bin/). It is not part
  # of this repo. When absent the built-in memory/process captures still stand
  # on their own, so this degrades gracefully.
  local helper=""
  if [[ -x "$HOME/.local/bin/mac_memory_health.sh" ]]; then
    helper="$HOME/.local/bin/mac_memory_health.sh"
  fi

  local file="$HELPER_DIR/mac-memory-health-helper-run.txt"
  section_file "$file" "mac_memory_health.sh Helper Run"

  if [[ "$RUN_HELPER" -ne 1 ]]; then
    echo "Helper skipped because --no-helper was provided." >> "$file"
    return 0
  fi

  if [[ -z "$helper" ]]; then
    echo "mac_memory_health.sh was not found in expected locations." >> "$file"
    echo "Built-in memory/process captures were still collected under memory/ and processes/." >> "$file"
    return 0
  fi

  echo "Using helper: $helper" >> "$file"
  MAC_MEMORY_HEALTH_DIR="$HELPER_DIR" "$helper" --diagnostics >> "$file" 2>> "$ERROR_LOG" || true
  MAC_MEMORY_HEALTH_DIR="$HELPER_DIR" "$helper" --apps >> "$HELPER_DIR/app-rollup-live.txt" 2>> "$ERROR_LOG" || true
  MAC_MEMORY_HEALTH_DIR="$HELPER_DIR" "$helper" --trend 25 >> "$HELPER_DIR/recent-trend.txt" 2>> "$ERROR_LOG" || true
}

create_manual_notes_template() {
  cat > "$AUDIT_DIR/manual-observations.md" <<NOTES
# Manual Observations

Use this file to add subjective details that scripts cannot reliably measure.

## Capture context

- Phase: $PHASE_LABEL
- Scenario: $SCENARIO_LABEL
- Note: $NOTE_TEXT
- Date/time:
- Power state: plugged in / battery
- External displays connected:
- Network/VPN state:
- Dock/desktop responsiveness:
- Fan/thermal symptoms:

## Workload state

- Apps intentionally open:
- IntelliJ projects open:
- Docker daemon running: yes / no / intentionally not started for clean boot
- Docker containers running:
- Chrome windows/tabs approximate count:
- Messaging / collaboration apps open:

## Responsiveness notes

- App switching delay:
- Typing lag:
- Mission Control delay:
- Window dragging delay:
- IntelliJ indexing/building:
- Docker/VM activity:

## Post-reimage comparison notes

- Same workload reproduced after reimage:
- Memory pressure comparison:
- Swap comparison:
- Compressed memory comparison:
- Top process comparison:
- Docker settings comparison:
- IntelliJ heap comparison:
NOTES
}

create_manual_context_files() {
  local generator="$REPO_ROOT/.internal/performance/generate-performance-manual-observations.py"
  if command -v python3 >/dev/null 2>&1 && [[ -f "$generator" ]]; then
    {
      printf '[%s] generating manual observations -> %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S %Z')" \
        "$generator --audit-dir $AUDIT_DIR --phase $PHASE_LABEL --scenario $SCENARIO_LABEL --note $NOTE_TEXT"
    } >> "$COMMAND_LOG"
    if python3 "$generator" \
      --audit-dir "$AUDIT_DIR" \
      --phase "$PHASE_LABEL" \
      --scenario "$SCENARIO_LABEL" \
      --note "$NOTE_TEXT" \
      2>> "$ERROR_LOG"; then
      return 0
    fi
  fi

  create_manual_notes_template
}

create_summary() {
  local end_epoch elapsed
  end_epoch="$(date +%s)"
  elapsed=$((end_epoch - START_EPOCH))

  cat > "$SUMMARY" <<SUMMARY_EOF
# Performance Audit Bundle

Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')  
Phase: $PHASE_LABEL  
Scenario: $SCENARIO_LABEL  
Note: $NOTE_TEXT  
Host: $(hostname 2>/dev/null || true)  
Script: $SCRIPT_NAME v$VERSION  
Elapsed seconds: $elapsed

## Purpose

This bundle captures a read-only performance baseline for comparing Mac behavior across reimage phases or workload scenarios.

Primary focus areas:

- memory pressure
- swap usage
- compressed memory
- top memory-consuming processes
- CPU-heavy processes
- Docker resource settings
- IntelliJ heap settings
- general responsiveness
- workload context for apps that were running during the sample

## Important output locations

| Area | Path |
|---|---|
| System overview | \`system/\` |
| Built-in memory samples | \`memory/\` |
| Top processes and app rollups | \`processes/\` |
| Responsiveness probes | \`responsiveness/\` |
| Docker baseline | \`docker/\` |
| Docker daemon state | \`docker/docker-daemon-state.txt\` |
| IntelliJ baseline | \`intellij/\` |
| mac_memory_health helper output | \`mac-memory-health-output/\` |
| Command log | \`logs/commands.log\` |
| Error log | \`logs/errors.log\` |
| Auto-filled manual notes | \`manual-observations.md\` |
SUMMARY_EOF

  # workload-reproduction-config.md is only written by
  # generate-performance-manual-observations.py. When python3 or the generator
  # is absent the fallback writes manual-observations.md alone, so listing the
  # row unconditionally would point at a file that is not in the bundle.
  if [[ -f "$AUDIT_DIR/workload-reproduction-config.md" ]]; then
    echo "| Workload reproduction config | \`workload-reproduction-config.md\` |" >> "$SUMMARY"
  fi

  cat >> "$SUMMARY" <<SUMMARY_EOF

## Suggested general performance comparison after reimage

Run this same script under the same approximate workload when creating a comparison capture:

1. Clean boot / idle for a few minutes.
2. Normal development workload: IntelliJ, Chrome, Teams, Obsidian, Docker, VS Code/Postman as applicable.
3. Compare these files first:
   - \`memory/sample_*_memory.txt\`
   - \`memory/sample_*_top_memory.csv\`
   - \`memory/sample_*_top_cpu.csv\`
   - \`processes/app_rollup.csv\`
   - \`docker/docker-daemon-state.txt\`
   - \`docker/docker-settings-resource-extract.txt\`
   - \`intellij/intellij-vmoptions-contents.txt\`

## Interpretation notes

High memory usage alone is not necessarily bad on macOS. The stronger warning signs are sustained memory pressure, growing swap usage, increasing swapout/pageout deltas, and a repeatable pattern where the same app group dominates memory or CPU under the same workload.

SUMMARY_EOF
}

create_manifest() {
  local manifest="$AUDIT_DIR/manifest.txt"
  {
    echo "Performance audit manifest"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Audit directory: $AUDIT_DIR"
    echo
    find "$AUDIT_DIR" -type f -print | sort
  } > "$manifest"
}

main() {
  log "Writing performance audit to: $AUDIT_DIR"
  log "This is read-only; it will not stop apps or change settings."

  # Do not copy this script into the backup/audit bundle.

  capture_system
  capture_processes
  capture_responsiveness
  capture_docker
  capture_intellij
  local i
  for i in $(seq 1 "$SAMPLE_COUNT"); do
    log "Capturing memory/process sample $i of $SAMPLE_COUNT..."
    capture_memory_sample "$i"
    if [[ "$i" -lt "$SAMPLE_COUNT" && "$SAMPLE_INTERVAL" -gt 0 ]]; then
      sleep "$SAMPLE_INTERVAL"
    fi
  done

  run_mac_memory_health_helper
  create_manual_context_files
  create_summary
  create_manifest

  log "Done. Audit bundle: $AUDIT_DIR"
  log "Start here: $SUMMARY"
  if [[ -s "$ERROR_LOG" ]]; then
    log "Some commands reported errors or unavailable data. Review: $ERROR_LOG"
  fi
}

main "$@"
