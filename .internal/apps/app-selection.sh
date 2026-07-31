#!/usr/bin/env bash
# =============================================================================
# app-selection.sh
#
# Internal helper for backup-apps.sh (Phase 2D). Single authoritative owner of
# the app-backup *selection checklist* — the file the Step 3 candidate review
# generates and the Step 4 backup run reads. Keeping both the format and its
# parsing in one place means the writer and the readers can never drift.
#
# The checklist has four selectable sections:
#   - Automatic backup (supported)    (script fully backs these up)
#   - Both automatic and manual       (scripted capture AND a manual export step)
#   - Manual backup (supported)       (toolkit-supported, but backup is manual)
#   - Unsupported apps on this Mac    (installed, not toolkit-supported; the
#                                      user backs these up by hand)
# Each app is a Markdown checkbox line the user edits: "- [ ] Name" (skip) or
# "- [x] Name" (act on). Machine-readable BEGIN/END markers bound each section
# so parsing never depends on the human-facing prose.
#
# This file lives in .internal/apps/ and is invoked by bin/backup-apps.sh.
# Shared reimage config is intentionally NOT loaded here; the caller passes
# resolved paths explicitly. Safe to run standalone with the arguments below.
#
# --- BEGIN USAGE ---
# Usage:
#   # Generate/refresh the checklist from two name-per-line lists. Existing
#   # checkmarks are preserved; newly-listed apps are added unchecked.
#   .internal/apps/app-selection.sh --generate \
#     --automatic-list /path/to/automatic-present.txt \
#     --both-list /path/to/both-present.txt \
#     --manual-list /path/to/manual-present.txt \
#     --unsupported-list /path/to/unsupported-present.txt \
#     --selection /path/to/app-settings-backup/app-backup-selection.md
#
#   # List the checked apps in one section, one name per line (empty if none).
#   .internal/apps/app-selection.sh --list-selected \
#     --selection /path/to/app-backup-selection.md --section automatic
#   .internal/apps/app-selection.sh --list-selected \
#     --selection /path/to/app-backup-selection.md --section both
#   .internal/apps/app-selection.sh --list-selected \
#     --selection /path/to/app-backup-selection.md --section manual
#   .internal/apps/app-selection.sh --list-selected \
#     --selection /path/to/app-backup-selection.md --section unsupported
#
# Options:
#   --generate                 Write/merge the checklist. Requires --automatic-list,
#                              --both-list, --manual-list, --unsupported-list, --selection.
#   --list-selected            Print checked names in --section. Requires
#                              --selection and --section.
#   --automatic-list FILE      Newline-delimited script-backed app names.
#   --both-list FILE           Newline-delimited names with automatic AND manual backup.
#   --manual-list FILE         Newline-delimited supported-but-manual app names.
#   --unsupported-list FILE    Newline-delimited unsupported-and-present app names.
#   --selection FILE           Path to the stable checklist file.
#   --section automatic|both|manual|unsupported   Which section --list-selected reads.
#   --run-hint STR             Optional command string shown in the checklist's
#                              "how to use" note (cosmetic only).
#   -h, --help                 Show this message and exit.
#
# Exit status:
#   0  Completed (including --list-selected with no checked apps).
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

# Section markers — the machine-readable boundaries parsing relies on.
AUTO_BEGIN='<!-- AUTOMATIC:BEGIN -->'
AUTO_END='<!-- AUTOMATIC:END -->'
BOTH_BEGIN='<!-- BOTH:BEGIN -->'
BOTH_END='<!-- BOTH:END -->'
MANUAL_BEGIN='<!-- MANUAL:BEGIN -->'
MANUAL_END='<!-- MANUAL:END -->'
UNSUP_BEGIN='<!-- UNSUPPORTED:BEGIN -->'
UNSUP_END='<!-- UNSUPPORTED:END -->'

MODE=""
AUTOMATIC_LIST=""
BOTH_LIST=""
MANUAL_LIST=""
UNSUPPORTED_LIST=""
SELECTION=""
SECTION=""
RUN_HINT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --generate) MODE="generate"; shift ;;
    --list-selected) MODE="list"; shift ;;
    --automatic-list) require_option_value "$1" "${2:-}"; AUTOMATIC_LIST="$2"; shift 2 ;;
    --both-list) require_option_value "$1" "${2:-}"; BOTH_LIST="$2"; shift 2 ;;
    --manual-list) require_option_value "$1" "${2:-}"; MANUAL_LIST="$2"; shift 2 ;;
    --unsupported-list) require_option_value "$1" "${2:-}"; UNSUPPORTED_LIST="$2"; shift 2 ;;
    --selection) require_option_value "$1" "${2:-}"; SELECTION="$2"; shift 2 ;;
    --section) require_option_value "$1" "${2:-}"; SECTION="$2"; shift 2 ;;
    --run-hint) require_option_value "$1" "${2:-}"; RUN_HINT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$MODE" ]]; then
  echo "ERROR: choose --generate or --list-selected." >&2
  usage >&2
  exit 2
fi
if [[ -z "$SELECTION" ]]; then
  echo "ERROR: --selection FILE is required." >&2
  exit 2
fi

# section_markers SECTION -> sets _BEGIN/_END for a section name; exit 2 if bad.
section_markers() {
  case "$1" in
    automatic)   _BEGIN="$AUTO_BEGIN";   _END="$AUTO_END" ;;
    both)        _BEGIN="$BOTH_BEGIN";   _END="$BOTH_END" ;;
    manual)      _BEGIN="$MANUAL_BEGIN"; _END="$MANUAL_END" ;;
    unsupported) _BEGIN="$UNSUP_BEGIN";  _END="$UNSUP_END" ;;
    *) echo "ERROR: --section must be 'automatic', 'both', 'manual', or 'unsupported'." >&2; exit 2 ;;
  esac
}

# was_checked SECTION NAME -> 0 if the app is checked in the existing file.
was_checked() {
  local section="$1" name="$2" slice
  _BEGIN=""; _END=""; section_markers "$section"
  [[ -f "$SELECTION" ]] || return 1
  slice="$(sed -n "/$_BEGIN/,/$_END/p" "$SELECTION")"
  if printf '%s\n' "$slice" | grep -Fxq -- "- [x] $name"; then return 0; fi
  if printf '%s\n' "$slice" | grep -Fxq -- "- [X] $name"; then return 0; fi
  return 1
}

# was_present SECTION NAME -> 0 if the app already has a line (checked OR not).
# Lets us tell a deliberately-unchecked app apart from a brand-new one.
was_present() {
  local section="$1" name="$2" slice
  _BEGIN=""; _END=""; section_markers "$section"
  [[ -f "$SELECTION" ]] || return 1
  slice="$(sed -n "/$_BEGIN/,/$_END/p" "$SELECTION")"
  if printf '%s\n' "$slice" | grep -Fxq -- "- [ ] $name"; then return 0; fi
  if printf '%s\n' "$slice" | grep -Fxq -- "- [x] $name"; then return 0; fi
  if printf '%s\n' "$slice" | grep -Fxq -- "- [X] $name"; then return 0; fi
  return 1
}

# emit_section SECTION LIST_FILE DEFAULT_STATE -> print checkbox lines. Prior
# choices win: a previously-checked app stays checked, a previously-unchecked app
# stays unchecked. A brand-new app takes DEFAULT_STATE ("x" checked, " " unchecked).
emit_section() {
  local section="$1" list="$2" default_state="$3" name
  [[ -f "$list" ]] || return 0
  # sort -u for stable, de-duplicated ordering.
  sort -u "$list" | while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    if was_checked "$section" "$name"; then
      printf -- '- [x] %s\n' "$name"
    elif was_present "$section" "$name"; then
      printf -- '- [ ] %s\n' "$name"
    else
      printf -- '- [%s] %s\n' "$default_state" "$name"
    fi
  done
}

if [[ "$MODE" == "generate" ]]; then
  if [[ -z "$AUTOMATIC_LIST" || -z "$BOTH_LIST" || -z "$MANUAL_LIST" || -z "$UNSUPPORTED_LIST" ]]; then
    echo "ERROR: --generate requires --automatic-list, --both-list, --manual-list, and --unsupported-list." >&2
    exit 2
  fi
  hint="${RUN_HINT:-./bin/backup-apps.sh}"
  dest_dir="$(dirname "$SELECTION")"
  mkdir -p "$dest_dir"
  tmp="$SELECTION.tmp.$$"
  {
    echo "# Phase 2D — App Backup Selection"
    echo ""
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "How to use: put an \"x\" between the brackets for each app to act on,"
    echo "save this file, then run the Step 4 backup:"
    echo ""
    echo "    $hint"
    echo ""
    echo "Unchecked apps are skipped. The three supported sections (automatic, both,"
    echo "and manual) start CHECKED (uncheck any you do not want); unsupported apps"
    echo "start UNCHECKED (check any you will back up by hand). Re-running the Step 3"
    echo "review preserves the choices you have made and adds newly-installed apps at"
    echo "their section default."
    echo ""
    echo "## Automatic backup (supported)"
    echo ""
    echo "The toolkit's script fully backs these up — no manual step needed. They"
    echo "start **checked**; uncheck any you do not want backed up."
    echo ""
    echo "$AUTO_BEGIN"
    emit_section automatic "$AUTOMATIC_LIST" "x"
    echo "$AUTO_END"
    echo ""
    echo "## Both automatic and manual backup (supported)"
    echo ""
    echo "The script captures part of these automatically **and** each also needs a"
    echo "manual export step (see the runbook's Step 5 / companion runbook). They"
    echo "start **checked** for the automatic capture — do not forget the manual half."
    echo ""
    echo "$BOTH_BEGIN"
    emit_section both "$BOTH_LIST" "x"
    echo "$BOTH_END"
    echo ""
    echo "## Manual backup (supported)"
    echo ""
    echo "The toolkit supports these but the backup is entirely manual — Step 4 makes"
    echo "a ready folder, you perform the export from the app's UI (see the runbook)."
    echo "They start **checked**; the folder is created for the ones you keep."
    echo ""
    echo "$MANUAL_BEGIN"
    emit_section manual "$MANUAL_LIST" "x"
    echo "$MANUAL_END"
    echo ""
    echo "## Unsupported apps on this Mac (manual backup)"
    echo ""
    echo "Installed apps the toolkit does not support, excluding company-managed"
    echo "apps (IT restores those, so they are not manual-backup candidates). Check"
    echo "the ones you will back up by hand; the toolkit creates a drop-folder under"
    echo "app-settings-backup/manual-unsupported/<app>/ and lists them as manual TODOs."
    echo ""
    echo "$UNSUP_BEGIN"
    emit_section unsupported "$UNSUPPORTED_LIST" " "
    echo "$UNSUP_END"
    echo ""
  } > "$tmp"
  mv "$tmp" "$SELECTION"
  echo "Wrote app-backup selection: $SELECTION"
  exit 0
fi

if [[ "$MODE" == "list" ]]; then
  if [[ -z "$SECTION" ]]; then
    echo "ERROR: --list-selected requires --section automatic|both|manual|unsupported." >&2
    exit 2
  fi
  _BEGIN=""; _END=""; section_markers "$SECTION"
  # No file yet -> no selections. Never fail the caller on an empty result.
  [[ -f "$SELECTION" ]] || exit 0
  sed -n "/$_BEGIN/,/$_END/p" "$SELECTION" \
    | grep -E '^- \[[xX]\] ' \
    | sed -E 's/^- \[[xX]\] //' || true
  exit 0
fi
