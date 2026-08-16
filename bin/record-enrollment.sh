#!/usr/bin/env bash
# =============================================================================
# record-enrollment.sh
#
# Phase 8 — Enroll and Stabilize evidence recorder. Runs read-only managed-
# baseline queries (MDM enrollment, configuration profiles, FileVault, expected
# managed apps and processes, macOS version, pending software updates), writes
# each result to a raw/NN-*.txt file, then generates a Markdown record with the
# Phase 8 exit-criteria table prefilled for the command-verifiable rows.
#
# This script records evidence and applies small heuristic PASS/WARN verdicts
# on the command-verifiable rows only. The truly human-judgment rows (Company
# Portal UI state, first stabilization restart completed, whether the managed
# app set matches current company policy) are left as TODO for you to close by
# hand after the restart checkpoint. See enroll-and-stabilize.md for the full
# runbook.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/record-enrollment.sh
#
#   # Default -- writes under $REIMAGE_ARTIFACT_ROOT if it resolves and is
#   # mounted, otherwise falls back to $REIMAGE_WORKSPACE_ROOT, otherwise to
#   # ~/Desktop/reimaged-system-artifacts/enrollment/.
#   ./bin/record-enrollment.sh
#
#   # Reveal the generated Markdown record in Finder after completion.
#   ./bin/record-enrollment.sh --open
#
#   # Override the artifact root for this invocation.
#   ./bin/record-enrollment.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Override the workspace root used for the local fallback path.
#   ./bin/record-enrollment.sh --workspace-root /path/to/reimage-workspace
#
#   # Write to an exact output directory (skips the reimaged-system/enrollment
#   # layout and the fallback chain entirely).
#   ./bin/record-enrollment.sh --output /absolute/path/to/output
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --workspace-root PATH Override REIMAGE_WORKSPACE_ROOT for the fallback path.
#   --output DIR          Exact output directory for generated files.
#   --open                Reveal the generated record in Finder on completion.
#   -h, --help            Show this message and exit.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Output location precedence (used only when --output is not supplied):
#   1. $REIMAGE_ARTIFACT_ROOT/reimaged-system/enrollment/
#        when REIMAGE_ARTIFACT_ROOT is set and currently mounted.
#   2. $REIMAGE_WORKSPACE_ROOT/enrollment/
#        when the artifact root is not yet available and a workspace is set.
#   3. ~/Desktop/reimaged-system-artifacts/enrollment/
#        as a final fallback so Phase 8 can complete on a bare Mac before the
#        external artifact volume is reconnected.
#
# Exit status:
#   0  Evidence recorded successfully.
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

# Phase 8 typically runs on a freshly reimaged Mac where the external artifact
# volume may not be mounted yet. Keep loading permissive so the local fallback
# path can still succeed.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

# ---------------------------------------------------------------------------
# Defaults and command-line parsing
# ---------------------------------------------------------------------------
STAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_DIR=""
OPEN_RESULT=false

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
    --workspace-root)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "ERROR: --workspace-root requires a non-empty value." >&2
        usage >&2
        exit 2
      fi
      REIMAGE_WORKSPACE_ROOT="$2"
      shift 2
      ;;
    --output)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "ERROR: --output requires a directory." >&2
        usage >&2
        exit 2
      fi
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --open)
      OPEN_RESULT=true
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

# ---------------------------------------------------------------------------
# Resolve output directory (fallback chain when --output is not supplied)
# ---------------------------------------------------------------------------
if [[ -z "$OUTPUT_DIR" ]]; then
  if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
    OUTPUT_DIR="$REIMAGE_ARTIFACT_ROOT/reimaged-system/enrollment/record-enrollment-$STAMP"
  elif [[ -n "${REIMAGE_WORKSPACE_ROOT:-}" && -d "$REIMAGE_WORKSPACE_ROOT" ]]; then
    OUTPUT_DIR="$REIMAGE_WORKSPACE_ROOT/enrollment/record-enrollment-$STAMP"
  else
    OUTPUT_DIR="$HOME/Desktop/reimaged-system-artifacts/enrollment/record-enrollment-$STAMP"
  fi
fi

# Safety invariant: refuse to write generated output under the repo checkout.
# A record landing inside the working tree is almost always an unset or
# relative root variable, not a real destination.
if [[ -n "${REPO_ROOT:-}" && ( "$OUTPUT_DIR" == "$REPO_ROOT" || "$OUTPUT_DIR" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $OUTPUT_DIR" >&2
  exit 2
fi

OUT="$OUTPUT_DIR"
RAW_DIR="$OUT/raw"
PARENT_DIR="$(dirname "$OUT")"
mkdir -p "$RAW_DIR" "$PARENT_DIR"

# ---------------------------------------------------------------------------
# Evidence capture helpers
# ---------------------------------------------------------------------------
record_cmd() {
  # Run a direct command and record stdout+stderr to a numbered raw file.
  local title="$1"
  local file="$2"
  shift 2
  echo "▶  $title ..."
  {
    echo "# $title"
    echo "# Generated: $(date)"
    echo "# Command: $*"
    echo ""
    "$@"
  } > "$RAW_DIR/$file" 2>&1 || true
  echo "   ✓ saved → raw/$file"
}

record_pipeline() {
  # Run a shell pipeline (used only for grep-based filters) and record the
  # result. Kept small and readable; avoids a login shell so profile output
  # cannot leak into the recorded evidence.
  local title="$1"
  local file="$2"
  local cmd="$3"
  echo "▶  $title ..."
  {
    echo "# $title"
    echo "# Generated: $(date)"
    echo "# Command: $cmd"
    echo ""
    bash -c "$cmd"
  } > "$RAW_DIR/$file" 2>&1 || true
  echo "   ✓ saved → raw/$file"
}

# ---------------------------------------------------------------------------
# Record raw evidence
# ---------------------------------------------------------------------------
record_cmd      "Enrollment status"              "01-enrollment-status.txt"     profiles status -type enrollment
record_cmd      "Configuration profiles list"    "02-profiles-list.txt"         profiles list
record_cmd      "FileVault status"               "03-filevault-status.txt"      fdesetup status
record_pipeline "Managed applications present"   "04-managed-apps.txt" \
  "ls -1 /Applications | grep -Ei 'Company Portal|CrowdStrike|Falcon|Zscaler|Microsoft|Teams|Outlook|OneNote' || true"
record_pipeline "Managed processes present"      "05-managed-processes.txt" \
  "ps aux | grep -Ei 'Intune|Company Portal|CrowdStrike|falcon|Zscaler|Microsoft AutoUpdate|MAU|mdmclient' | grep -v grep || true"
record_cmd      "macOS version and build"        "06-macos-version.txt"         sw_vers
record_cmd      "Available software updates"     "07-softwareupdate-list.txt"   softwareupdate --list

# ---------------------------------------------------------------------------
# Heuristic verdicts for the command-verifiable exit-criteria rows
# ---------------------------------------------------------------------------
file_contains() {
  local file="$1"
  local pattern="$2"
  grep -Eiq "$pattern" "$file" 2>/dev/null
}

status_pass_warn() {
  # Print PASS when the heuristic is satisfied, WARN otherwise. WARN is not the
  # same as FAIL — it means the recorded evidence did not obviously match the
  # expected pattern and needs a human look before the row is signed off.
  if [[ "$1" == "true" ]]; then
    printf 'PASS'
  else
    printf 'WARN'
  fi
}

ENROLLMENT_OK="false"
if file_contains "$RAW_DIR/01-enrollment-status.txt" 'enrolled|yes|mdm'; then
  ENROLLMENT_OK="true"
fi

PROFILES_OK="false"
if [[ -s "$RAW_DIR/02-profiles-list.txt" ]] \
  && ! file_contains "$RAW_DIR/02-profiles-list.txt" 'there are no configuration profiles installed|no configuration profiles|error'; then
  PROFILES_OK="true"
fi

CROWDSTRIKE_OK="false"
ZSCALER_OK="false"
if file_contains "$RAW_DIR/04-managed-apps.txt" 'crowdstrike|falcon' \
  || file_contains "$RAW_DIR/05-managed-processes.txt" 'crowdstrike|falcon'; then
  CROWDSTRIKE_OK="true"
fi
if file_contains "$RAW_DIR/04-managed-apps.txt" 'zscaler' \
  || file_contains "$RAW_DIR/05-managed-processes.txt" 'zscaler'; then
  ZSCALER_OK="true"
fi
SECURITY_OK="false"
if [[ "$CROWDSTRIKE_OK" == "true" && "$ZSCALER_OK" == "true" ]]; then
  SECURITY_OK="true"
fi

UPDATES_OK="false"
if file_contains "$RAW_DIR/07-softwareupdate-list.txt" 'No new software available'; then
  UPDATES_OK="true"
fi

POST_RESTART_OK="false"
if [[ "$ENROLLMENT_OK" == "true" && "$PROFILES_OK" == "true" && "$SECURITY_OK" == "true" ]]; then
  POST_RESTART_OK="true"
fi

# ---------------------------------------------------------------------------
# Generate the Markdown record with the Phase 8 exit-criteria table prefilled
# ---------------------------------------------------------------------------
REPORT_FILE="$OUT/enrollment-record.md"

cat > "$REPORT_FILE" <<EOF
# Enrollment Record

Generated: $(date)
Script: $(basename "$0")
Output directory: $OUT

Use this record as the Phase 8 command-evidence bundle. The command-verifiable rows are prefilled below with a heuristic PASS/WARN verdict. Complete the remaining manual or mixed-review rows after the UI review and the first stabilization restart. See \`enroll-and-stabilize.md\` for the full runbook.

## Exit Criteria

| Check | Verification mode | How to verify | Status | Notes |
|---|---|---|---|---|
| Enrollment completed or clearly stabilized | Mixed | \`profiles status -type enrollment\` plus expected company state | $(status_pass_warn "$ENROLLMENT_OK") | See \`raw/01-enrollment-status.txt\`. |
| Required profiles/certificates appear | Mixed | \`profiles list\` plus expected profile/cert presence | $(status_pass_warn "$PROFILES_OK") | See \`raw/02-profiles-list.txt\`. |
| Required security tools are installed or actively installing | Mixed | managed app/process checks plus visual sanity review | $(status_pass_warn "$SECURITY_OK") | See \`raw/04-managed-apps.txt\` and \`raw/05-managed-processes.txt\`. |
| Company Portal opens and shows expected state | Manual | open Company Portal and review the device state | TODO | Fill after UI review. |
| Required macOS updates are complete or intentionally deferred | Mixed | \`sw_vers\`, \`softwareupdate --list\`, and policy/UI review | $(status_pass_warn "$UPDATES_OK") | See \`raw/06-macos-version.txt\` and \`raw/07-softwareupdate-list.txt\`. |
| First stabilization restart completed | Manual | observed restart and successful return to login/session | TODO | Fill after the restart checkpoint is complete. |
| Post-restart baseline still looks healthy | Mixed | rerun the post-restart commands and confirm no regressions | $(status_pass_warn "$POST_RESTART_OK") | Update after post-restart review if this record was written before the final checkpoint. |

## Manual Follow-Up

1. Open Company Portal and review the device state.
2. Confirm whether the first stabilization restart has completed.
3. Update the \`TODO\` rows above.
4. If this record was written before the final post-restart checkpoint, rerun the script and use the newer record for final sign-off.

## Raw Evidence Files

- \`raw/01-enrollment-status.txt\`
- \`raw/02-profiles-list.txt\`
- \`raw/03-filevault-status.txt\`
- \`raw/04-managed-apps.txt\`
- \`raw/05-managed-processes.txt\`
- \`raw/06-macos-version.txt\`
- \`raw/07-softwareupdate-list.txt\`
EOF

cat > "$OUT/MANIFEST.txt" <<EOF
# Enrollment Record Manifest
Generated: $(date)
Script: $(basename "$0")
Output directory: $OUT

Files:
- enrollment-record.md
- raw/01-enrollment-status.txt
- raw/02-profiles-list.txt
- raw/03-filevault-status.txt
- raw/04-managed-apps.txt
- raw/05-managed-processes.txt
- raw/06-macos-version.txt
- raw/07-softwareupdate-list.txt
EOF

printf '%s\n' "$REPORT_FILE" > "$PARENT_DIR/latest-enrollment-record.txt"

echo ""
echo "Enrollment record complete."
echo "Record → $REPORT_FILE"

if [[ "$OPEN_RESULT" == "true" ]]; then
  open -R "$REPORT_FILE"
fi
