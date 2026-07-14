#!/usr/bin/env bash
# capture-size-audit.sh
# Audits local backup targets, OneDrive, external drive capacity, and the
# backup root structure. All targets and excludes are read from backup-config.sh.
#
# Usage:
#   ./capture-size-audit.sh [options]
#
# Options:
#   --drive NAME       External drive partition name (default: Data)
#   --backup-root DIR  Specific backup/capture root to audit (default: BACKUP_ROOT env var or newest reimage-*)
#   --local-only       Skip OneDrive and external drive sections
#   --help

set -euo pipefail

# ── Locate and source config ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SNIPPET="${SCRIPT_DIR}/load-reimage-config-snippet.sh"
if [[ ! -f "$CONFIG_SNIPPET" ]]; then
  echo "ERROR: shared config loader not found: ${CONFIG_SNIPPET}" >&2
  exit 1
fi
# shellcheck source=load-reimage-config-snippet.sh
source "$CONFIG_SNIPPET"

# Display-only fallback. The shared loader does not always set CONFIG.
CONFIG="${CONFIG:-${BACKUP_CONFIG_SOURCE_DIR:-${BACKUP_CONFIG_SOURCE:-${BACKUP_CONFIG_FILE:-$CONFIG_SNIPPET}}}}"

# ── Argument parsing ──────────────────────────────────────────────────────────
DRIVE_NAME="$DEFAULT_DRIVE_NAME"
AUDIT_BACKUP_ROOT="${BACKUP_ROOT:-}"
LOCAL_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --local-only)   LOCAL_ONLY=true ;;
    --help|-h)
      cat <<'USAGE'
Usage: ./capture-size-audit.sh [--drive NAME_OR_MOUNT_PATH] [--backup-root DIR] [--local-only]

  --drive NAME_OR_MOUNT_PATH
                       External drive partition name or /Volumes/... mount path
                       (default: Data)
  --backup-root DIR   Backup/capture root to audit (default: BACKUP_ROOT env var or newest reimage-* on drive)
  --local-only        Show local targets only — skip OneDrive and external drive
USAGE
      exit 0 ;;
    --drive)        : ;;   # handled below
    --backup-root)  : ;;
    *)
      if [[ "${PREV_ARG:-}" == "--drive" ]];       then DRIVE_NAME="$arg"
      elif [[ "${PREV_ARG:-}" == "--backup-root" ]]; then AUDIT_BACKUP_ROOT="$arg"
      fi ;;
  esac
  PREV_ARG="$arg"
done

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

raw_bytes() {
  [[ -e "$1" ]] && du -sk "$1" 2>/dev/null | cut -f1 | awk '{print $1*1024}' || echo 0
}

bytes_to_human() {
  local b="$1"
  if   (( b >= 1073741824 )); then printf "%.1f GB" "$(echo "scale=1; $b/1073741824" | bc)"
  elif (( b >= 1048576    )); then printf "%.1f MB" "$(echo "scale=1; $b/1048576"    | bc)"
  elif (( b >= 1024       )); then printf "%.1f KB" "$(echo "scale=1; $b/1024"       | bc)"
  else printf "%d B" "$b"; fi
}

dir_size_human() {
  [[ -e "$1" ]] && du -sh "$1" 2>/dev/null | cut -f1 || echo "not found"
}

# List immediate children with sizes, flag large and sensitive items
list_dir_contents() {
  local path="$1" max_items="${2:-50}"
  local count=0
  [[ -d "$path" ]] || return
  while IFS= read -r item; do
    (( count++ )) || true
    if (( count > max_items )); then
      local total; total=$(find "$path" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l | tr -d ' ')
      printf "  ${DIM}  … and %d more items${RST}\n" $(( total - max_items ))
      break
    fi
    local name rb sz flag=""
    name=$(basename "$item"); rb=$(raw_bytes "$item"); sz=$(bytes_to_human "$rb")
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
  done < <(
    find "$path" -maxdepth 1 -mindepth 1 -type d  2>/dev/null | sort
    find "$path" -maxdepth 1 -mindepth 1 ! -type d 2>/dev/null | sort
  )
}

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLD}${CYN}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BLD}${CYN}║        Pre-Reimage Backup Size Audit                 ║${RST}"
echo -e "${BLD}${CYN}║        $(date '+%Y-%m-%d %H:%M:%S')                        ║${RST}"
echo -e "${BLD}${CYN}╚══════════════════════════════════════════════════════╝${RST}"
echo -e "  ${DIM}Config: ${CONFIG}${RST}"

total_bytes=0

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 1 — EXTERNAL DRIVE TARGETS (from config)
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BLD}${CYN}━━  EXTERNAL DRIVE TARGETS  ━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "  ${DIM}Sources defined in backup-config.sh EXTERNAL_TARGETS${RST}"

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
echo -e "  ${BLD}── SECRETS (→ secrets-encrypted/) ─────────────────────────${RST}"

for entry in "${SECRETS_TARGETS[@]}"; do
  key=$(config_field "$entry" 1)
  src=$(config_field "$entry" 2)
  desc=$(config_field "$entry" 4)
  rb=$(raw_bytes "$src"); sz=$(bytes_to_human "$rb")
  total_bytes=$(( total_bytes + rb ))
  if [[ -e "$src" ]]; then
    printf "  ${YEL}  %-28s  %-10s  %s${RST}\n" "$key" "$sz" "$desc"
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
echo -e "  ${DIM}Defined in backup-config.sh SKIP_ENTRIES${RST}"
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
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2 — ONEDRIVE
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo ""
echo -e "${BLD}${CYN}━━  ONEDRIVE  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "  ${DIM}Targets defined in backup-config.sh ONEDRIVE_TARGETS${RST}"
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

if [[ -d "$EXTERNAL_MOUNT" ]]; then
  # Use specified root or find newest on drive
  if [[ -n "$AUDIT_BACKUP_ROOT" ]]; then
    BACKUP_ROOTS=( "$AUDIT_BACKUP_ROOT" )
  else
    mapfile -t BACKUP_ROOTS < <(
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

      while IFS= read -r item; do
        name=$(basename "$item")
        rb=$(raw_bytes "$item"); sz=$(bytes_to_human "$rb")
        if [[ -d "$item" ]]; then
          is_expected=0
          for ef in "${EXPECTED_BACKUP_FOLDERS[@]}"; do
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
      for ef in "${EXPECTED_BACKUP_FOLDERS[@]}"; do
        [[ -d "$backup_root/$ef" ]] || missing+=("$ef")
      done
      if (( ${#missing[@]} > 0 )); then
        echo -e "  ${YEL}  Missing expected folders:${RST}"
        for mf in "${missing[@]}"; do printf "  ${YEL}    ✗ %s${RST}\n" "$mf"; done
      else
        echo -e "  ${GRN}  All expected folders present ✓${RST}"
      fi

      loose=$(find "$backup_root" -maxdepth 1 -mindepth 1 ! -type d 2>/dev/null | wc -l | tr -d ' ')
      (( loose > 0 )) && \
        echo -e "  ${YEL}  ⚠ ${loose} loose file(s) at backup root — organize into subfolders${RST}"
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
