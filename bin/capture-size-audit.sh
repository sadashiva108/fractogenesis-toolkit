#!/usr/bin/env bash
# capture-size-audit.sh
# Audits local backup targets, OneDrive, external drive capacity, and the
# backup root structure. All targets and excludes are read from artifact-config.sh.
#
# Usage:
#   ./capture-size-audit.sh [options]
#
# Options:
#   --drive NAME        External drive partition name (default: Data)
#   --backup-root DIR   Specific backup/capture root to audit (default: BACKUP_ROOT env var or newest reimage-*)
#   --local-only          Skip OneDrive and external drive sections
#   --check-loose-secrets Run a read-only lingering-secret candidate check.
#   --dest DIR           Size-audit-reports root directory.
#                         Default: $REIMAGE_ARTIFACT_ROOT/size-audit-reports.
#                         When neither is available, the report is not saved.
#   --context pre-image|post-image|pre-image-<label>|post-image-<label>
#                         Context prefix for the timestamped run directory.
#                         Default: pre-image. Use a sub-label (e.g.
#                         pre-image-backup-repos) to distinguish multiple
#                         pre-image captures on the same day in
#                         MANIFEST.md; the run directory still starts with
#                         pre-image- or post-image- either way.
#   --help
#
# Output (written beneath --dest, when a destination is available):
#   MANIFEST.md
#       Append-only index of successful size-audit runs.
#   latest-run.txt
#       Relative path to the newest successful run directory.
#   runs/<context>-YYYYMMDD-HHMMSS/size-audit-report.txt
#       Full terminal output of the run, ANSI color codes intact. View with
#       `less -R` or `cat` in a terminal so the severity colors still render.

set -euo pipefail

# ── Locate and source shared reimage config ──────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"
if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

# Display-only fallback. The shared loader does not define a generic CONFIG
# variable; show the effective artifact-config source when available.
CONFIG="${CONFIG:-${ARTIFACT_CONFIG_SOURCE_DIR:-$CONFIG_LOADER}}"

# ── Argument parsing ──────────────────────────────────────────────────────────
DRIVE_NAME="$DEFAULT_DRIVE_NAME"
AUDIT_BACKUP_ROOT="${BACKUP_ROOT:-}"
LOCAL_ONLY=false
CHECK_LOOSE_SECRETS=false
REPORT_DEST="${REIMAGE_ARTIFACT_ROOT:+${REIMAGE_ARTIFACT_ROOT}/size-audit-reports}"
REPORT_CONTEXT="pre-image"

for arg in "$@"; do
  case "$arg" in
    --local-only)          LOCAL_ONLY=true ;;
    --check-loose-secrets) CHECK_LOOSE_SECRETS=true ;;
    --help|-h)
      cat <<'USAGE'
Usage: ./capture-size-audit.sh [--drive NAME_OR_MOUNT_PATH] [--backup-root DIR] [--local-only] [--check-loose-secrets] [--dest DIR] [--context pre-image|post-image|pre-image-<label>|post-image-<label>]

  --drive NAME_OR_MOUNT_PATH
                       External drive partition name or /Volumes/... mount path
                       (default: Data)
  --backup-root DIR   Backup/capture root to audit (default: BACKUP_ROOT env var or newest reimage-* on drive)
  --local-only          Show local targets only — skip OneDrive and external drive
  --check-loose-secrets Run after the secrets phase to identify plaintext secret candidates outside secrets-encrypted/ and loose payloads still under secrets-encrypted/.
  --dest DIR           Size-audit-reports root directory (default: $REIMAGE_ARTIFACT_ROOT/size-audit-reports)
  --context pre-image|post-image|pre-image-<label>|post-image-<label>
                       Context prefix for the timestamped run directory (default: pre-image).
                       A sub-label such as pre-image-backup-repos distinguishes multiple
                       pre-image captures the same day; must start with pre-image- or post-image-.
USAGE
      exit 0 ;;
    --drive)        : ;;   # handled below
    --backup-root)  : ;;
    --dest)         : ;;   # handled below
    --context)      : ;;   # handled below
    *)
      if [[ "${PREV_ARG:-}" == "--drive" ]];         then DRIVE_NAME="$arg"
      elif [[ "${PREV_ARG:-}" == "--backup-root" ]]; then AUDIT_BACKUP_ROOT="$arg"
      elif [[ "${PREV_ARG:-}" == "--dest" ]];        then REPORT_DEST="$arg"
      elif [[ "${PREV_ARG:-}" == "--context" ]];     then REPORT_CONTEXT="$arg"
      fi ;;
  esac
  PREV_ARG="$arg"
done

case "$REPORT_CONTEXT" in
  pre-image|post-image|pre-image-?*|post-image-?*)
    case "$REPORT_CONTEXT" in
      *[/\\]*|*..*|.*|*[[:space:]]*)
        echo "ERROR: --context must not contain slashes, '..', a leading dot, or whitespace, got: $REPORT_CONTEXT" >&2
        exit 2
        ;;
    esac
    ;;
  *)
    echo "ERROR: --context must be pre-image, post-image, or start with pre-image- or post-image- (e.g. pre-image-backup-repos), got: $REPORT_CONTEXT" >&2
    exit 2
    ;;
esac

if [[ "$DRIVE_NAME" == /* ]]; then
  EXTERNAL_MOUNT="${DRIVE_NAME%/}"
  DRIVE_DISPLAY="$(basename "$EXTERNAL_MOUNT")"
else
  EXTERNAL_MOUNT="/Volumes/${DRIVE_NAME}"
  DRIVE_DISPLAY="$DRIVE_NAME"
fi
ACTIVE_BACKUP_ROOT="${AUDIT_BACKUP_ROOT:-${BACKUP_ROOT:-}}"
EXTERNAL_LOCAL_FILES_DEST=""
ONEDRIVE_DEST_PATH=""

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYN='\033[0;36m'
BLD='\033[1m'
DIM='\033[2m'
RST='\033[0m'

hr()      { printf '%s\n' "────────────────────────────────────────────────────────" ; }
thin_hr() { printf '%s\n' "  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄" ; }

# Return success for routine macOS metadata that should not be treated as
# backup content or reported as loose files.
is_macos_metadata_name() {
  local name="$1"

  case "$name" in
    .DS_Store|._*|.AppleDouble|.LSOverride|.localized|.VolumeIcon.icns|\
    .DocumentRevisions-V100|.fseventsd|.Spotlight-V100|.TemporaryItems|.Trashes)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Heuristic only: identifies filenames commonly used for plaintext credentials,
# private keys, keystores, and environment-secret files. It deliberately does
# not inspect file contents or delete anything.
is_loose_secret_candidate_name() {
  local name lower
  name="$1"
  lower="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"

  case "$lower" in
    .env|.env.*|.netrc|.npmrc|.pypirc|credentials|credentials.json|id_rsa|id_dsa|id_ecdsa|id_ed25519|*.pem|*.key|*.p12|*.pfx|*.jks|*.keystore|*.kubeconfig|*credential*.json|*token*.json|*password*.csv|*password*.json)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_allowed_secrets_evidence_name() {
  local name lower
  name="$1"
  lower="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"

  case "$lower" in
    *.dmg|*.sha256|*.sha256sum|*.txt|*.tsv|*.md|*.log)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

raw_bytes() {
  local path="$1" kilobytes

  if [[ ! -e "$path" && ! -L "$path" ]]; then
    printf '0\n'
    return 0
  fi

  # `du` can print a valid size and still return non-zero when part of a tree is
  # unreadable. Capture only its first numeric field and always emit exactly
  # one integer so callers can safely use the result in arithmetic expressions.
  kilobytes="$(du -sk "$path" 2>/dev/null | awk 'NR == 1 && $1 ~ /^[0-9]+$/ { print $1; exit }' || true)"
  case "$kilobytes" in
    ''|*[!0-9]*) printf '0\n' ;;
    *) printf '%s\n' "$((10#$kilobytes * 1024))" ;;
  esac
}

bytes_to_human() {
  local b="${1:-0}"

  case "$b" in
    ''|*[!0-9]*) b=0 ;;
  esac

  if (( b >= 1073741824 )); then
    awk -v bytes="$b" 'BEGIN { printf "%.1f GB", bytes / 1073741824 }'
  elif (( b >= 1048576 )); then
    awk -v bytes="$b" 'BEGIN { printf "%.1f MB", bytes / 1048576 }'
  elif (( b >= 1024 )); then
    awk -v bytes="$b" 'BEGIN { printf "%.1f KB", bytes / 1024 }'
  else
    printf "%d B" "$b"
  fi
}

dir_size_human() {
  local path="$1" size

  if [[ ! -e "$path" && ! -L "$path" ]]; then
    printf 'not found\n'
    return 0
  fi

  size="$(du -sh "$path" 2>/dev/null | awk 'NR == 1 { print $1; exit }' || true)"
  printf '%s\n' "${size:-unavailable}"
}

# List immediate children with sizes, flag large and sensitive items
list_dir_contents() {
  local path="$1" max_items="${2:-50}"
  local item name rb sz flag
  local count=0
  local items=()

  [[ -d "$path" ]] || return

  while IFS= read -r item; do
    name="${item##*/}"
    is_macos_metadata_name "$name" && continue
    items+=("$item")
  done < <(
    find "$path" -maxdepth 1 -mindepth 1 -type d  2>/dev/null | sort
    find "$path" -maxdepth 1 -mindepth 1 ! -type d 2>/dev/null | sort
  )

  for item in "${items[@]}"; do
    count=$((count + 1))
    if (( count > max_items )); then
      printf "  ${DIM}  … and %d more items${RST}\n" $(( ${#items[@]} - max_items ))
      break
    fi

    name="${item##*/}"
    rb=$(raw_bytes "$item")
    sz=$(bytes_to_human "$rb")
    flag=""

    if [[ -d "$item" ]]; then
      if   (( rb > 10737418240 )); then printf "  ${YEL}  📁  %-42s  %s ⚠ large${RST}\n" "$name" "$sz"
      elif (( rb >  1073741824 )); then printf "  ${CYN}  📁  %-42s  %s${RST}\n"          "$name" "$sz"
      else                              printf "  ${DIM}  📁  %-42s  %s${RST}\n"          "$name" "$sz"
      fi
    else
      echo "$name" | grep -qiE 'password|passwd|secret|credential|token|key|\.csv$|\.pem$|\.p12$' \
        && flag=" ${RED}⚠ sensitive${RST}"
      printf "  ${DIM}      %-42s  %s${RST}%b\n" "$name" "$sz" "$flag"
    fi
  done
}

# ── Report capture (size-audit-reports) ───────────────────────────────────────
# Mirrors the repo-audit-reports pattern: MANIFEST.md + latest-run.txt +
# self-contained runs/<context>-YYYYMMDD-HHMMSS/ directories, written to a
# .incomplete staging name and atomically renamed on success so a failed or
# interrupted run never lands in the manifest.
SAVE_REPORT=false
if [[ -n "$REPORT_DEST" ]]; then
  mkdir -p "$REPORT_DEST/runs"

  MANIFEST_PATH="$REPORT_DEST/MANIFEST.md"
  LATEST_RUN_PATH="$REPORT_DEST/latest-run.txt"
  STAMP="$(date +%Y%m%d-%H%M%S)"
  RUN_ID="${REPORT_CONTEXT}-${STAMP}"
  RUN_RELATIVE="runs/$RUN_ID"
  FINAL_RUN_DIR="$REPORT_DEST/$RUN_RELATIVE"
  WORK_RUN_DIR="$REPORT_DEST/runs/.${RUN_ID}.incomplete"

  if [[ -e "$FINAL_RUN_DIR" || -e "$WORK_RUN_DIR" ]]; then
    echo "ERROR: size-audit run directory already exists for this timestamp: $FINAL_RUN_DIR" >&2
    exit 1
  fi

  if [[ -e "$MANIFEST_PATH" ]] && ! grep -q '^# Size Audit Runs$' "$MANIFEST_PATH" 2>/dev/null; then
    echo "ERROR: existing manifest is not the canonical append-only size-audit index:" >&2
    echo "  $MANIFEST_PATH" >&2
    echo "Remove that file before running the current size-audit workflow." >&2
    exit 2
  fi

  mkdir "$WORK_RUN_DIR"

  cleanup_incomplete_size_audit_run() {
    if [[ -d "$WORK_RUN_DIR" ]]; then
      rm -rf "$WORK_RUN_DIR"
    fi
  }
  trap cleanup_incomplete_size_audit_run EXIT
  trap 'exit 130' INT TERM

  REPORT="$WORK_RUN_DIR/size-audit-report.txt"
  # ANSI color codes are captured on purpose so the same severity colors read
  # the same way later. View with `less -R` or `cat` in a terminal; a raw
  # dump (e.g. `cat -v`) will show the escape codes literally instead.
  exec > >(tee -a "$REPORT") 2>&1
  SAVE_REPORT=true
fi

# Appends the manifest row, updates the latest-run pointer, and atomically
# promotes the run directory. Called at every exit point that reaches a
# clean end of the report (both the --local-only early exit and normal
# completion) so there is exactly one place that finalizes a successful run.
finalize_size_audit_report() {
  [[ "$SAVE_REPORT" == true ]] || return 0

  mv "$WORK_RUN_DIR" "$FINAL_RUN_DIR"

  if [[ ! -e "$MANIFEST_PATH" ]]; then
    cat > "$MANIFEST_PATH" <<'EOF'
# Size Audit Runs

This file is an append-only index of successful backup-size-audit runs.
Reports keep their original ANSI color codes — use `less -R` or `cat` in a
terminal to view them with the severity colors intact.

| Completed | Context | Run | External total | Skipped total | OneDrive planned | Report |
|---|---|---|---:|---:|---:|---|
EOF
  fi

  COMPLETED_AT="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '| %s | `%s` | `%s` | %s | %s | %s | [Open report](%s/size-audit-report.txt) |\n' \
    "$COMPLETED_AT" "$REPORT_CONTEXT" "$RUN_ID" \
    "$(bytes_to_human "${total_bytes:-0}")" "$(bytes_to_human "${skip_bytes:-0}")" "$(bytes_to_human "${od_total:-0}")" \
    "$RUN_RELATIVE" >> "$MANIFEST_PATH"

  LATEST_TEMP="$REPORT_DEST/.latest-run.$$.tmp"
  printf '%s\n' "$RUN_RELATIVE" > "$LATEST_TEMP"
  mv "$LATEST_TEMP" "$LATEST_RUN_PATH"

  trap - EXIT INT TERM

  echo ""
  echo -e "${DIM}Report saved (ANSI color codes intact):${RST}"
  echo -e "${DIM}  $FINAL_RUN_DIR/size-audit-report.txt${RST}"
  echo -e "${DIM}Manifest:    $MANIFEST_PATH${RST}"
  echo -e "${DIM}Latest-run:  $LATEST_RUN_PATH${RST}"
}

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLD}${CYN}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BLD}${CYN}║        Pre-Image Backup Size Audit                   ║${RST}"
echo -e "${BLD}${CYN}║        $(date '+%Y-%m-%d %H:%M:%S')                        ║${RST}"
echo -e "${BLD}${CYN}╚══════════════════════════════════════════════════════╝${RST}"
echo -e "  ${DIM}Config: ${CONFIG}${RST}"
echo ""
echo -e "  ${BLD}Legend${RST}"
echo -e "  ${GRN}Green${RST}   expected, present, healthy, or enough capacity"
echo -e "  ${CYN}Cyan${RST}    section headings and larger directories (over 1 GB)"
echo -e "  ${YEL}Yellow${RST}  review needed: large items, missing items, loose files, or secret candidates"
echo -e "  ${RED}Red${RST}     critical error or explicit sensitive-data warning"
echo -e "  ${DIM}Dim${RST}     routine detail, small/normal items, or optional item not found"
echo -e "  ${DIM}macOS metadata such as .DS_Store and AppleDouble files is hidden and excluded from loose-file warnings.${RST}"
echo -e "  ${DIM}Configured source secrets are inventory items and are expected before the later secrets phase.${RST}"

total_bytes=0

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 1 — EXTERNAL DRIVE TARGETS (from config)
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BLD}${CYN}━━  EXTERNAL DRIVE TARGETS  ━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "  ${DIM}Sources defined in artifact-config.sh EXTERNAL_TARGETS${RST}"

current_category=""

for entry in "${EXTERNAL_TARGETS[@]}"; do
  label=$(config_field "$entry" 1)
  src=$(config_field "$entry" 2)
  category=$(config_field "$entry" 4)
  desc=$(config_field "$entry" 5)

  # Print category header when it changes
  if [[ "$category" != "$current_category" ]]; then
    echo ""
    echo -e "  ${BLD}── ${category^^} ──────────────────────────────────────────────${RST}"
    current_category="$category"
  fi

  rb=$(raw_bytes "$src"); sz=$(bytes_to_human "$rb")
  total_bytes=$(( total_bytes + rb ))

  if [[ ! -e "$src" ]]; then
    printf "  ${DIM}▸ %-28s  not found, skipping${RST}\n" "$label"
    continue
  fi

  if (( rb > 10737418240 )); then
    printf "  ${YEL}▸ %-28s  %-10s  %s${RST}\n" "$label" "$sz ⚠" "$desc"
  else
    printf "  ${GRN}▸ %-28s  ${BLD}%-10s${RST}  ${DIM}%s${RST}\n" "$label" "$sz" "$desc"
  fi
  list_dir_contents "$src" 30
done

# ── Dotfiles ──────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BLD}── DOTFILES (individual files at ~/) ──────────────────────${RST}"

for entry in "${EXTERNAL_DOTFILES[@]}"; do
  df=$(config_field "$entry" 1)
  desc=$(config_field "$entry" 3)
  fp="$HOME/$df"
  [[ -e "$fp" ]] || continue
  rb=$(raw_bytes "$fp"); sz=$(bytes_to_human "$rb")
  total_bytes=$(( total_bytes + rb ))
  if echo "$df" | grep -qiE 'netrc|secret|token|key|password'; then
    printf "  ${YEL}  %-28s  %-10s  %s ⚠ sensitive${RST}\n" "$df" "$sz" "$desc"
  else
    printf "  ${GRN}  %-28s  ${BLD}%-10s${RST}  ${DIM}%s${RST}\n" "$df" "$sz" "$desc"
  fi
done

# ── Secrets ───────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BLD}── SECRETS (→ secrets-encrypted/ LATER PHASE) ────────────${RST}"
echo -e "  ${DIM}Inventory only: presence here is expected before the secrets phase; source files should not be deleted by this audit.${RST}"

for entry in "${SECRETS_TARGETS[@]}"; do
  key=$(config_field "$entry" 1)
  src=$(config_field "$entry" 2)
  desc=$(config_field "$entry" 4)
  rb=$(raw_bytes "$src"); sz=$(bytes_to_human "$rb")
  total_bytes=$(( total_bytes + rb ))
  if [[ -e "$src" ]]; then
    printf "  ${CYN}  %-28s  %-10s  %s${RST}\n" "$key" "$sz" "$desc"
  else
    printf "  ${DIM}  %-28s  not found${RST}\n" "$key"
  fi
done

echo ""
hr
echo -e "  ${BLD}External targets total:  $(bytes_to_human $total_bytes)${RST}"

# ── What's being skipped ──────────────────────────────────────────────────────
echo ""
echo -e "${BLD}${CYN}━━  INTENTIONALLY SKIPPED  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "  ${DIM}Defined in artifact-config.sh SKIP_ENTRIES${RST}"
echo ""

skip_bytes=0
for entry in "${SKIP_ENTRIES[@]}"; do
  path_raw=$(config_field "$entry" 1)
  reason=$(config_field "$entry" 2)
  # Expand ~ to check actual size
  actual_path="${path_raw/\~/$HOME}"
  # Only check paths without wildcards
  if [[ "$actual_path" != *"*"* ]] && [[ -e "$actual_path" ]]; then
    rb=$(raw_bytes "$actual_path"); sz=$(bytes_to_human "$rb")
    skip_bytes=$(( skip_bytes + rb ))
    if (( rb > 1073741824 )); then
      printf "  ${DIM}✗  %-42s  ${YEL}%-10s${RST}  ${DIM}%s${RST}\n" "$path_raw" "$sz" "$reason"
    else
      printf "  ${DIM}✗  %-42s  %-10s  %s${RST}\n" "$path_raw" "$sz" "$reason"
    fi
  else
    printf "  ${DIM}✗  %-42s             %s${RST}\n" "$path_raw" "$reason"
  fi
done

echo ""
echo -e "  ${DIM}Skipped total (not backed up):  $(bytes_to_human $skip_bytes)${RST}"

if $LOCAL_ONLY; then
  echo ""
  hr
  echo -e "${DIM}--local-only: OneDrive and external drive sections skipped.${RST}"
  echo ""
  finalize_size_audit_report
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2 — ONEDRIVE
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo ""
echo -e "${BLD}${CYN}━━  ONEDRIVE  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "  ${DIM}Targets defined in artifact-config.sh ONEDRIVE_TARGETS${RST}"
echo ""

# Auto-detect OneDrive
if [[ -z "$ONEDRIVE_ROOT" ]]; then
  CLOUD="$HOME/Library/CloudStorage"
  if [[ -d "$CLOUD/OneDrive-AcmeGroup" ]]; then
    ONEDRIVE_ROOT="$CLOUD/OneDrive-AcmeGroup"
  elif [[ -d "$CLOUD" ]]; then
    ONEDRIVE_ROOT=$(find "$CLOUD" -maxdepth 1 -name 'OneDrive*' -type d 2>/dev/null | head -1)
  fi
  [[ -z "$ONEDRIVE_ROOT" ]] && [[ -d "$HOME/OneDrive" ]] && ONEDRIVE_ROOT="$HOME/OneDrive"
fi

od_total=0
onedrive_avail_bytes=0
if [[ -n "$ONEDRIVE_ROOT" ]] && [[ -d "$ONEDRIVE_ROOT" ]]; then
  if [[ -n "${ONEDRIVE_DEST_SUBDIR:-}" ]]; then
    ONEDRIVE_DEST_PATH="${ONEDRIVE_ROOT%/}/${ONEDRIVE_DEST_SUBDIR}"
  fi
  od_rb=$(raw_bytes "$ONEDRIVE_ROOT"); od_sz=$(bytes_to_human "$od_rb")
  echo -e "  ${GRN}Found: ${ONEDRIVE_ROOT}${RST}"
  echo -e "  Local on-disk size: ${BLD}${od_sz}${RST}  ${DIM}(cloud-only stubs show 0 B)${RST}"
  od_df_line=$(df -k "$ONEDRIVE_ROOT" | tail -1)
  od_avail_kb=$(echo "$od_df_line" | awk '{print $4}')
  od_used_kb=$(echo "$od_df_line" | awk '{print $3}')
  od_total_kb=$(echo "$od_df_line" | awk '{print $2}')
  od_capacity=$(echo "$od_df_line" | awk '{print $5}')
  onedrive_avail_bytes=$(( od_avail_kb * 1024 ))
  od_used_bytes=$(( od_used_kb * 1024 ))
  od_total_bytes=$(( od_total_kb * 1024 ))
  echo -e "  Local filesystem capacity:"
  printf "  %-24s  %s\n" "Total capacity:"  "$(bytes_to_human $od_total_bytes)"
  printf "  %-24s  %s\n" "Used:"            "$(bytes_to_human $od_used_bytes) (${od_capacity})"
  printf "  ${GRN}%-24s  ${BLD}%s${RST}\n" "Available:" "$(bytes_to_human $onedrive_avail_bytes)"
  echo ""

  # Show what WOULD be synced per config
  echo -e "  ${BLD}Planned OneDrive sync targets:${RST}"
  for entry in "${ONEDRIVE_TARGETS[@]}"; do
    label=$(config_field "$entry" 1)
    src=$(config_field "$entry" 2)
    desc=$(config_field "$entry" 5)
    rb=$(raw_bytes "$src"); sz=$(bytes_to_human "$rb")
    od_total=$(( od_total + rb ))
    if [[ -e "$src" ]]; then
      printf "  ${GRN}  ▸ %-20s  ${BLD}%-10s${RST}  ${DIM}%s${RST}\n" "$label" "$sz" "$desc"
    else
      printf "  ${DIM}  ▸ %-20s  not found${RST}\n" "$label"
    fi
  done
  echo ""
  echo -e "  ${BLD}Planned OneDrive sync size: $(bytes_to_human $od_total)${RST}"
  echo -e "  ${DIM}(After OneDrive extra excludes are applied — actual upload will be smaller)${RST}"
  if [[ -n "$ONEDRIVE_DEST_PATH" ]]; then
    echo -e "  Target OneDrive destination: ${BLD}${ONEDRIVE_DEST_PATH}${RST}"
    if [[ -e "$ONEDRIVE_DEST_PATH" ]]; then
      printf "  %-30s  %s\n" "Current destination size:" "$(dir_size_human "$ONEDRIVE_DEST_PATH")"
    else
      echo -e "  ${DIM}Current destination size: not created yet${RST}"
    fi
  fi
  echo ""

  # Show current OneDrive contents
  echo -e "  ${BLD}Current OneDrive contents:${RST}"
  list_dir_contents "$ONEDRIVE_ROOT" 25
else
  echo -e "  ${YEL}OneDrive not found. Open the OneDrive app and sign in.${RST}"
  od_total=0
fi

echo ""
if pgrep -xq "OneDrive" 2>/dev/null; then
  echo -e "  ${GRN}OneDrive process: running ✓${RST}"
else
  echo -e "  ${YEL}OneDrive process: NOT running — sync is not active${RST}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 3 — EXTERNAL DRIVE CAPACITY
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo ""
echo -e "${BLD}${CYN}━━  EXTERNAL DRIVE — ${EXTERNAL_MOUNT}  ━━━━━━━━━━━━━━━━${RST}"

avail_bytes=0
if [[ ! -d "$EXTERNAL_MOUNT" ]]; then
  echo -e "  ${RED}✗ Drive not found at ${EXTERNAL_MOUNT}${RST}"
  echo -e "  ${DIM}  Use --drive NAME to override. Check the drive is connected.${RST}"
else
  df_line=$(df -k "$EXTERNAL_MOUNT" | tail -1)
  avail_kb=$(echo "$df_line" | awk '{print $4}')
  used_kb=$(echo  "$df_line" | awk '{print $3}')
  total_kb=$(echo "$df_line" | awk '{print $2}')
  capacity=$(echo "$df_line" | awk '{print $5}')
  avail_bytes=$(( avail_kb * 1024 ))
  used_bytes=$(( used_kb * 1024 ))
  total_drive=$(( total_kb * 1024 ))

  thin_hr
  printf "  %-24s  %s\n" "Total capacity:"  "$(bytes_to_human $total_drive)"
  printf "  %-24s  %s\n" "Used:"            "$(bytes_to_human $used_bytes) (${capacity})"
  printf "  ${GRN}%-24s  ${BLD}%s${RST}\n" "Available:" "$(bytes_to_human $avail_bytes)"
fi

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 4 — BACKUP ROOT AUDIT
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo ""
echo -e "${BLD}${CYN}━━  BACKUP ROOT CONTENTS  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"

BACKUP_ROOTS=()
if [[ -d "$EXTERNAL_MOUNT" ]]; then
  # Use specified root or find newest on drive
  if [[ -n "$AUDIT_BACKUP_ROOT" ]]; then
    BACKUP_ROOTS=( "$AUDIT_BACKUP_ROOT" )
  else
    BACKUP_ROOTS=()
    while IFS= read -r discovered_root; do
      [[ -n "$discovered_root" ]] && BACKUP_ROOTS+=("$discovered_root")
    done < <(
      find "$EXTERNAL_MOUNT" -maxdepth 1 -type d \( -name 'reimage-*' -o -name 'reimage-preimage-*' -o -name 'reimage-postimage-*' \) 2>/dev/null | sort -r
    )
  fi

  if (( ${#BACKUP_ROOTS[@]} == 0 )); then
    echo -e "  ${YEL}No reimage-* backup/capture roots found on ${EXTERNAL_MOUNT}${RST}"
  else
    for backup_root in "${BACKUP_ROOTS[@]}"; do
      bname=$(basename "$backup_root")
      braw=$(raw_bytes "$backup_root")
      echo ""
      echo -e "  ${BLD}${bname}${RST}  ${DIM}($(bytes_to_human $braw) total)${RST}"
      thin_hr

      metadata_ignored=0
      while IFS= read -r item; do
        name="${item##*/}"
        if is_macos_metadata_name "$name"; then
          metadata_ignored=$((metadata_ignored + 1))
          continue
        fi

        rb=$(raw_bytes "$item"); sz=$(bytes_to_human "$rb")
        if [[ -d "$item" ]]; then
          is_expected=0
          for ef in "${EXPECTED_ARTIFACT_FOLDERS[@]}"; do
            [[ "$name" == "$ef" ]] && is_expected=1 && break
          done
          (( is_expected )) \
            && printf "  ${GRN}  📁  %-38s  %s ✓${RST}\n" "$name" "$sz" \
            || printf "  ${DIM}  📁  %-38s  %s${RST}\n"   "$name" "$sz"
        else
          local_flag=""
          echo "$name" | grep -qiE 'password|passwd|secret|credential|token|\.csv$|\.pem$|\.p12$' \
            && local_flag=" ${RED}⚠ sensitive — move to secrets-encrypted/${RST}"
          printf "  ${YEL}      %-38s  %s${RST}%b\n" "$name" "$sz" "$local_flag"
        fi
      done < <(
        find "$backup_root" -maxdepth 1 -mindepth 1 -type d  2>/dev/null | sort
        find "$backup_root" -maxdepth 1 -mindepth 1 ! -type d 2>/dev/null | sort
      )

      echo ""
      missing=()
      for ef in "${EXPECTED_ARTIFACT_FOLDERS[@]}"; do
        [[ -d "$backup_root/$ef" ]] || missing+=("$ef")
      done
      if (( ${#missing[@]} > 0 )); then
        echo -e "  ${YEL}  Missing expected folders:${RST}"
        for mf in "${missing[@]}"; do printf "  ${YEL}    ✗ %s${RST}\n" "$mf"; done
      else
        echo -e "  ${GRN}  All expected folders present ✓${RST}"
      fi

      loose=0
      while IFS= read -r loose_item; do
        loose_name="${loose_item##*/}"
        is_macos_metadata_name "$loose_name" && continue
        loose=$((loose + 1))
      done < <(find "$backup_root" -maxdepth 1 -mindepth 1 ! -type d 2>/dev/null)

      if (( loose > 0 )); then
        echo -e "  ${YEL}  ⚠ ${loose} loose file(s) at backup root — organize into subfolders${RST}"
      fi
      if (( metadata_ignored > 0 )); then
        echo -e "  ${DIM}  Ignored ${metadata_ignored} routine macOS metadata item(s).${RST}"
      fi
    done
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL — POST-SECRETS LINGERING CANDIDATE CHECK
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$CHECK_LOOSE_SECRETS" == true ]]; then
  echo ""
  echo ""
  echo -e "${BLD}${CYN}━━  POST-SECRETS LINGERING CANDIDATE CHECK  ━━━━━━━━━━━${RST}"
  echo -e "  ${DIM}Read-only heuristic. It does not inspect contents or delete files.${RST}"
  echo -e "  ${DIM}Run after the encrypted secrets artifact has been created and loose staging has been cleaned up.${RST}"

  roots_to_check=()
  if [[ -n "$AUDIT_BACKUP_ROOT" ]]; then
    roots_to_check+=("$AUDIT_BACKUP_ROOT")
  elif (( ${#BACKUP_ROOTS[@]} > 0 )); then
    roots_to_check=("${BACKUP_ROOTS[@]}")
  elif [[ -n "$ACTIVE_BACKUP_ROOT" ]]; then
    roots_to_check+=("$ACTIVE_BACKUP_ROOT")
  fi

  if (( ${#roots_to_check[@]} == 0 )); then
    echo -e "  ${YEL}No backup root was available for the lingering-secret check.${RST}"
  else
    for check_root in "${roots_to_check[@]}"; do
      [[ -d "$check_root" ]] || continue
      outside_count=0
      staging_count=0
      echo ""
      echo -e "  ${BLD}Root: $check_root${RST}"

      while IFS= read -r candidate; do
        candidate_name="${candidate##*/}"
        is_macos_metadata_name "$candidate_name" && continue
        if is_loose_secret_candidate_name "$candidate_name"; then
          outside_count=$((outside_count + 1))
          printf "  ${YEL}  ⚠ outside secrets-encrypted/: %s${RST}\n" "${candidate#"$check_root/"}"
        fi
      done < <(find "$check_root" -type f ! -path "$check_root/secrets-encrypted/*" 2>/dev/null | sort)

      secrets_root="$check_root/secrets-encrypted"
      if [[ -d "$secrets_root" ]]; then
        while IFS= read -r candidate; do
          candidate_name="${candidate##*/}"
          is_macos_metadata_name "$candidate_name" && continue
          is_allowed_secrets_evidence_name "$candidate_name" && continue
          staging_count=$((staging_count + 1))
          printf "  ${YEL}  ⚠ loose payload under secrets-encrypted/: %s${RST}\n" "${candidate#"$secrets_root/"}"
        done < <(find "$secrets_root" -type f 2>/dev/null | sort)
      fi

      if (( outside_count == 0 && staging_count == 0 )); then
        echo -e "  ${GRN}  ✓ No lingering plaintext secret candidates found.${RST}"
      else
        echo -e "  ${YEL}  Review: ${outside_count} candidate(s) outside secrets-encrypted/; ${staging_count} loose payload file(s) inside secrets-encrypted/.${RST}"
      fi
    done
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 5 — FIT CHECK
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo ""
echo -e "${BLD}${CYN}━━  FIT CHECK  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
thin_hr
echo ""

if [[ -n "$ACTIVE_BACKUP_ROOT" ]]; then
  EXTERNAL_LOCAL_FILES_DEST="${ACTIVE_BACKUP_ROOT%/}/local-files"
fi

# External drive fit
printf "  %-38s  %s\n" "Estimated external backup size:"  "$(bytes_to_human $total_bytes)"
if [[ -n "$ACTIVE_BACKUP_ROOT" ]]; then
  printf "  %-38s  %s\n" "Target backup root:" "$ACTIVE_BACKUP_ROOT"
  printf "  %-38s  %s\n" "Target local-files destination:" "$EXTERNAL_LOCAL_FILES_DEST"
  if [[ -e "$EXTERNAL_LOCAL_FILES_DEST" ]]; then
    printf "  %-38s  %s\n" "Current local-files destination size:" "$(dir_size_human "$EXTERNAL_LOCAL_FILES_DEST")"
  else
    printf "  %-38s  %s\n" "Current local-files destination size:" "not created yet"
  fi
fi
if (( avail_bytes > 0 )); then
  printf "  %-38s  %s\n" "Available on ${EXTERNAL_MOUNT}:" "$(bytes_to_human $avail_bytes)"
  echo ""
  if (( avail_bytes > total_bytes )); then
    headroom=$(( avail_bytes - total_bytes ))
    echo -e "  ${GRN}${BLD}✓ External drive: enough space.  Headroom: $(bytes_to_human $headroom)${RST}"
  else
    shortfall=$(( total_bytes - avail_bytes ))
    echo -e "  ${RED}${BLD}✗ External drive: NOT ENOUGH SPACE.  Short by: $(bytes_to_human $shortfall)${RST}"
  fi
else
  echo -e "  ${DIM}  External drive not mounted — skipping fit check${RST}"
fi

# OneDrive fit (informational only — OneDrive quota varies)
if (( od_total > 0 )); then
  echo ""
  printf "  %-38s  %s\n" "Planned OneDrive sync size:" "$(bytes_to_human $od_total)"
  if [[ -n "$ONEDRIVE_DEST_PATH" ]]; then
    printf "  %-38s  %s\n" "Target OneDrive destination:" "$ONEDRIVE_DEST_PATH"
    if [[ -e "$ONEDRIVE_DEST_PATH" ]]; then
      printf "  %-38s  %s\n" "Current OneDrive destination size:" "$(dir_size_human "$ONEDRIVE_DEST_PATH")"
    else
      printf "  %-38s  %s\n" "Current OneDrive destination size:" "not created yet"
    fi
  fi
  if (( onedrive_avail_bytes > 0 )); then
    printf "  %-38s  %s\n" "Available on OneDrive local volume:" "$(bytes_to_human $onedrive_avail_bytes)"
    if (( onedrive_avail_bytes > od_total )); then
      od_headroom=$(( onedrive_avail_bytes - od_total ))
      echo -e "  ${GRN}${BLD}✓ OneDrive local volume: enough space.  Headroom: $(bytes_to_human $od_headroom)${RST}"
    else
      od_shortfall=$(( od_total - onedrive_avail_bytes ))
      echo -e "  ${RED}${BLD}✗ OneDrive local volume: NOT ENOUGH SPACE.  Short by: $(bytes_to_human $od_shortfall)${RST}"
    fi
  else
    echo -e "  ${DIM}  OneDrive local volume not available — skipping local fit check${RST}"
  fi
  echo -e "  ${DIM}  Check OneDrive storage quota at portal.office.com if needed.${RST}"
fi

echo ""
hr
echo -e "${DIM}⚠  Sizes are on-disk. Cloud-only OneDrive stubs are not counted.${RST}"
echo -e "${DIM}⚠  Skipped items (Gradle, Docker.raw, caches) save $(bytes_to_human $skip_bytes).${RST}"
echo -e "${DIM}⚠  Sensitive items flagged ⚠ should live in secrets-encrypted/.${RST}"
echo -e "${DIM}   Config: ${CONFIG}${RST}"
echo ""

finalize_size_audit_report
