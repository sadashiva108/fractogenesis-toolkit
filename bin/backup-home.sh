#!/usr/bin/env bash
# =============================================================================
# backup-home.sh
#
# Copies non-repo local files (selected home-directory targets, dotfiles) and
# secrets-encrypted targets (ssh, gnupg, docker/config.json, Java jssecacerts,
# and other secret staging) into $REIMAGE_ARTIFACT_ROOT, and optionally syncs
# an approved work-safe subset to OneDrive. Invoked by Phase 2B in
# reimaging-guide.md; see backup-home.md for the full
# runbook. Docker settings/contexts/inventories are owned by Phase 2C
# (backup-apps.sh); dev-tool version inventory is owned by Phase 4B
# (capture-system-inventory.sh) — neither is duplicated here.
#
# This file is intended for bin/. All targets, dotfiles, secrets, and excludes
# are read from the artifact-config fragments loaded by
# .internal/load-reimage-config.sh — edit fragments there, not this script.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/backup-home.sh
#
#   # External drive and OneDrive (default)
#   ./bin/backup-home.sh
#
#   # External drive only
#   ./bin/backup-home.sh --external-only
#
#   # OneDrive only (rerun after the external copy already ran)
#   ./bin/backup-home.sh --onedrive-only
#
#   # Preview without copying
#   ./bin/backup-home.sh --dry-run --external-only
#
#   # Override the artifact root for this invocation
#   ./bin/backup-home.sh --artifact-root /Volumes/Data/reimage-<asset>-<date>-open --external-only
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --external-only       External drive only (skip OneDrive).
#   --onedrive-only       OneDrive only (skip external drive).
#   --dry-run             Show what would be copied, copy nothing.
#   -h, --help            Show this message and exit.
#
# Requires:
#   rsync   Every directory copy in this script is an rsync sync.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Exit status:
#   0  Backup completed successfully (or dry run completed).
#   1  Backup ran but a copy/sync operation failed. The failing target, its
#      source and destination, and the underlying rsync exit code are printed.
#   2  Usage, configuration, prerequisite, or dependency error.
# --- END USAGE ---
# =============================================================================

set -Eeuo pipefail
trap 'status=$?; echo "" >&2; echo "ERROR: backup-home.sh failed near line ${LINENO}: ${BASH_COMMAND}" >&2; exit "$status"' ERR

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

ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

# Display-only fallback, matching report-size-audit.sh: the shared loader does
# not define a generic CONFIG variable, so show the effective fragment source.
CONFIG="${CONFIG:-${ARTIFACT_CONFIG_SOURCE_DIR:-$CONFIG_LOADER}}"

RUN_EXTERNAL=true
RUN_ONEDRIVE=true
DRY_RUN=false
RSYNC_WARNINGS=0

# Stock macOS Bash 3.2 errors on "${arr[@]}" for an empty array under `set -u`.
# Two safe forms are used throughout this script: a `(( ${#arr[@]} > 0 ))`
# guard around loops, and the `${arr[@]+"${arr[@]}"}` form when splatting an
# array into an argument list.

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
    --external-only) RUN_ONEDRIVE=false; shift ;;
    --onedrive-only) RUN_EXTERNAL=false; shift ;;
    --dry-run)       DRY_RUN=true; shift ;;
    -h|--help)       usage; exit 0 ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve configured defaults after command-line parsing
# ---------------------------------------------------------------------------
if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set." >&2
  echo "Create/source reimage.env or pass --artifact-root PATH." >&2
  exit 2
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "ERROR: rsync is not installed or not on PATH." >&2
  exit 2
fi

DEST="$REIMAGE_ARTIFACT_ROOT/home-files-backup"
ONEDRIVE_DEST_SUBDIR="${ONEDRIVE_DEST_SUBDIR:-$(basename "${REIMAGE_ARTIFACT_ROOT%/}")}"

# The expected OneDrive root, used in error text so the operator is told which
# path to fix. artifact-config.sh derives ONEDRIVE_PREFERRED_ROOT from
# ONEDRIVE_PARENT_DIR and ONEDRIVE_FOLDER_NAME; no folder name is hardcoded here.
onedrive_expected_root() {
  local cloud="${ONEDRIVE_PARENT_DIR:-$HOME/Library/CloudStorage}"

  if [[ -n "${ONEDRIVE_PREFERRED_ROOT:-}" ]]; then
    printf '%s\n' "$ONEDRIVE_PREFERRED_ROOT"
  elif [[ -n "${ONEDRIVE_FOLDER_NAME:-}" ]]; then
    printf '%s\n' "$cloud/$ONEDRIVE_FOLDER_NAME"
  else
    printf '%s\n' "$cloud/<ONEDRIVE_FOLDER_NAME from reimage.env>"
  fi
}

resolve_onedrive_root() {
  local configured="${ONEDRIVE_ROOT:-}"
  local cloud="${ONEDRIVE_PARENT_DIR:-$HOME/Library/CloudStorage}"
  local preferred="${ONEDRIVE_PREFERRED_ROOT:-}"
  local resolved=""

  if [[ -n "$configured" ]]; then
    if [[ "$configured" == /* ]]; then
      if [[ ! -d "$configured" ]]; then
        echo "ERROR: ONEDRIVE_ROOT is set to an absolute path that does not exist: $configured" >&2
        echo "Open OneDrive/sign in first, or correct ONEDRIVE_ROOT in reimage.env." >&2
        return 2
      fi
      resolved="$configured"
    elif [[ -d "$cloud/$configured" ]]; then
      resolved="$cloud/$configured"
    else
      echo "ERROR: ONEDRIVE_ROOT is not absolute and was not found under CloudStorage." >&2
      echo "Configured: $configured" >&2
      echo "Expected : $cloud/$configured" >&2
      echo "Set ONEDRIVE_ROOT=\"$cloud/$configured\" in reimage.env after OneDrive is signed in." >&2
      return 2
    fi
  elif [[ -n "$preferred" && -d "$preferred" ]]; then
    resolved="$preferred"
  elif [[ -d "$cloud" ]]; then
    resolved=$(find "$cloud" -maxdepth 1 -name 'OneDrive*' -type d 2>/dev/null | head -1 || true)
  elif [[ -d "$HOME/OneDrive" ]]; then
    resolved="$HOME/OneDrive"
  fi

  [[ -n "$resolved" ]] && printf '%s\n' "$resolved"
}

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
log_section() { echo ""; echo -e "${BLD}${CYN}▸ $1${RST}"; thin_hr; }

check_prior() {
  local dst="$1"
  if [[ -d "$dst" ]] && [[ -n "$(ls -A "$dst" 2>/dev/null)" ]]; then
    local prev; prev=$(du -sh "$dst" 2>/dev/null | cut -f1)
    printf "  ${DIM}  ↺ previously backed up (%s) — syncing changes${RST}\n" "$prev"
  fi
}

# Build rsync --exclude=PAT flags from the patterns given as arguments and
# publish them in EXCLUDE_FLAGS. Bash 3.2 has no namerefs, so the caller
# splats the source array in and copies EXCLUDE_FLAGS out.
build_exclude_flags() {
  local pat
  EXCLUDE_FLAGS=()
  for pat in "$@"; do
    [[ -n "$pat" ]] || continue
    EXCLUDE_FLAGS+=( "--exclude=${pat}" )
  done
}

# Run rsync with the ERR trap and `set -e` suspended for the duration, and
# publish its exit status in RSYNC_RC. A command on the left of `||` is exempt
# from both, so no trap save/restore dance is needed.
run_rsync_capture() {
  local errfile="$1"
  shift
  RSYNC_RC=0
  rsync "$@" 2>"$errfile" || RSYNC_RC=$?
}

# Copy corporate Java jssecacerts files into secrets-encrypted/certs/java-security/.
# These are staged as generated backup artifacts, then included in the encrypted
# all-secrets DMG by create-secrets-dmg.sh. Restore only after the target JDK is known.
copy_java_jssecacerts() {
  local backup_root="$1" dry="$2"
  local dest_root="$backup_root/secrets-encrypted/certs/java-security"
  local inventory="$dest_root/java-jssecacerts-inventory.md"
  local count=0
  local seen=":"

  # A dry run must leave the artifact root untouched, so the staging directory
  # and its inventory are only created on a real run.
  if ! $dry; then
    mkdir -p "$dest_root"
    {
      echo "# Java jssecacerts Backup Inventory"
      echo "Generated : $(date '+%Y-%m-%d %H:%M:%S')"
      echo "Host      : $(hostname)"
      echo ""
      echo "| Label | Source | Destination | SHA-256 | Size Bytes |"
      echo "|---|---|---|---:|---:|"
    } > "$inventory"
  fi

  copy_one_jsse() {
    local src="$1" label="$2" safe dest hash size
    [[ -f "$src" ]] || return 0
    case "$seen" in
      *:"$src":*) return 0 ;;
    esac
    seen="${seen}${src}:"
    safe=$(printf '%s' "$label" | sed 's/[^A-Za-z0-9_.-]/_/g')
    dest="$dest_root/$safe/jssecacerts"
    hash=$(shasum -a 256 "$src" 2>/dev/null | awk '{print $1}' || true)
    size=$(wc -c < "$src" 2>/dev/null | tr -d ' ' || true)

    if $dry; then
      printf "  ${YEL}~  %-44s  (dry run)${RST}\n" "$label/jssecacerts"
    else
      mkdir -p "$(dirname "$dest")"
      cp -p "$src" "$dest"
      {
        printf 'source=%s\n' "$src"
        printf 'label=%s\n' "$label"
        printf 'sha256=%s\n' "${hash:-unknown}"
        printf 'size_bytes=%s\n' "${size:-unknown}"
      } > "$(dirname "$dest")/README.txt"
      printf '| `%s` | `%s` | `%s` | `%s` | `%s` |\n' \
        "$label" "$src" "secrets-encrypted/certs/java-security/$safe/jssecacerts" "${hash:-unknown}" "${size:-unknown}" >> "$inventory"
      printf "  ${GRN}✓  %-44s  %s bytes${RST}\n" "$label/jssecacerts" "${size:-unknown}"
    fi
    (( count++ )) || true
  }

  if [[ -n "${JAVA_HOME:-}" ]]; then
    copy_one_jsse "$JAVA_HOME/lib/security/jssecacerts" "JAVA_HOME-$(basename "$JAVA_HOME")"
  fi

  shopt -s nullglob
  for jdk_home in /Library/Java/JavaVirtualMachines/*/Contents/Home; do
    [[ -d "$jdk_home" ]] || continue
    copy_one_jsse "$jdk_home/lib/security/jssecacerts" "$(basename "$(dirname "$(dirname "$jdk_home")")")"
  done
  for intellij_jbr in /Applications/IntelliJ*.app/Contents/jbr/Contents/Home /Applications/IntelliJ*.app/Contents/jbr; do
    [[ -d "$intellij_jbr" ]] || continue
    copy_one_jsse "$intellij_jbr/lib/security/jssecacerts" "$(basename "$(dirname "$(dirname "$intellij_jbr")")")-bundled-jbr"
  done
  shopt -u nullglob

  if (( count == 0 )); then
    printf "  ${DIM}– %-44s  not found, skipping${RST}\n" "Java jssecacerts"
    if ! $dry; then
      # Leave no empty certs/java-security/ scaffolding behind when this Mac
      # has no corporate Java trust override to stage.
      rm -f "$inventory" 2>/dev/null || true
      rmdir "$dest_root" 2>/dev/null || true
      rmdir "$(dirname "$dest_root")" 2>/dev/null || true
    fi
  else
    printf "  ${YEL}  ⚠  Restore only after Java 17 is installed and target JAVA_HOME is confirmed${RST}\n"
    ! $dry && printf "  ${DIM}  Inventory: %s${RST}\n" "$inventory" || true
  fi
}

# Run rsync with prior-run detection and result reporting
# $1=label  $2=src  $3=dst  $4=dry(true/false)  $5+=exclude flags
run_rsync() {
  local label="$1" src="$2" dst="$3" dry="$4"
  shift 4; local extra=("$@")

  if [[ ! -e "$src" ]]; then
    printf "  ${DIM}– %-44s  not found, skipping${RST}\n" "$label"; return
  fi

  check_prior "$dst"

  # A dry run must leave the artifact root untouched, so no mkdir here. But
  # rsync --dry-run still has to chdir into the destination's parent to compute
  # a delta, and fails with code 3 when more than one level is missing (a
  # nested DEST such as copilot/instructions under a fresh artifact root). When
  # the destination does not exist yet there is no delta to compute anyway —
  # everything would be copied — so say that and skip the rsync.
  local dry_flag=()
  if $dry; then
    if [[ ! -d "$dst" ]]; then
      printf "  ${YEL}~  %-44s  (dry run — new, full copy)${RST}\n" "$label"
      return 0
    fi
    dry_flag=( "--dry-run" )
  else
    mkdir -p "$dst"
  fi

  local rsync_err
  rsync_err="$(mktemp)"

  run_rsync_capture "$rsync_err" \
    -a --delete --no-specials --no-devices \
    ${dry_flag[@]+"${dry_flag[@]}"} ${extra[@]+"${extra[@]}"} "$src" "$dst"

  case "$RSYNC_RC" in
    0) ;;
    24)
      # Source changed under us: OneDrive rehydrating, editors saving, caches
      # rotating. The copy is otherwise complete.
      RSYNC_WARNINGS=$(( RSYNC_WARNINGS + 1 ))
      printf "  ${YEL}⚠  %-44s  files vanished during copy (rsync 24)${RST}\n" "$label"
      sed 's/^/       /' "$rsync_err" >&2
      ;;
    23)
      # Partial transfer — usually unreadable sources (TCC, permissions, sockets).
      RSYNC_WARNINGS=$(( RSYNC_WARNINGS + 1 ))
      printf "  ${YEL}⚠  %-44s  partial transfer (rsync 23) — review stderr${RST}\n" "$label"
      sed 's/^/       /' "$rsync_err" >&2
      ;;
    *)
      echo "" >&2
      echo "ERROR: rsync failed for a home-files target" >&2
      echo "  label: $label" >&2
      echo "  src:   $src" >&2
      echo "  dst:   $dst" >&2
      echo "  rsync exit: $RSYNC_RC" >&2
      echo "  rsync stderr:" >&2
      sed 's/^/    /' "$rsync_err" >&2
      rm -f "$rsync_err"
      exit 1
      ;;
  esac

  rm -f "$rsync_err"

  if $dry; then
    printf "  ${YEL}~  %-44s  (dry run)${RST}\n" "$label"
  else
    local size; size=$(du -sh "$dst" 2>/dev/null | cut -f1)
    printf "  ${GRN}✓  %-44s  %s${RST}\n" "$label" "$size"
  fi
}


secret_flag_name() {
  local key="$1"
  printf 'BACKUP_%s\n' "$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]' | sed 's/[^A-Z0-9_]/_/g')"
}

copy_secret_target() {
  local key="$1" src="$2" rel_dest="$3" dry="$4"
  local dst="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/$rel_dest"
  local dst_parent size src_norm dst_norm rsync_err key_count

  # Some SECRETS_TARGETS are manual staging folders that already live under
  # $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/, such as postman/ and raycast/. Keep them
  # listed in secrets-targets.conf.sh for manifest/completeness, but do not rsync a
  # directory onto itself.
  src_norm="${src%/}"
  dst_norm="${dst%/}"

  if [[ ! -e "$src" ]]; then
    printf "  ${DIM}– %-18s  not found, skipping${RST}\n" "$key"
    return 0
  fi

  if [[ "$src_norm" == "$dst_norm" ]]; then
    size=$(du -sh "$src_norm" 2>/dev/null | cut -f1 || echo "unknown")
    if $dry; then
      printf "  ${YEL}~  %-18s  already staged at secrets-encrypted/%s  (dry run)${RST}\n" "$key" "$rel_dest"
    else
      printf "  ${GRN}✓  %-18s  already staged at secrets-encrypted/%s  (%s)${RST}\n" "$key" "$rel_dest" "$size"
    fi
    return 0
  fi

  if $dry; then
    printf "  ${YEL}~  %-18s  →  secrets-encrypted/%s  (dry run)${RST}\n" "$key" "$rel_dest"
    return 0
  fi

  if [[ -d "$src" ]]; then
    check_prior "$dst"
    mkdir -p "$dst"
    rsync_err="$(mktemp)"

    run_rsync_capture "$rsync_err" \
      -a --no-specials --no-devices --exclude="random_seed" "$src" "$dst"

    if [[ "$RSYNC_RC" -ne 0 ]]; then
      echo "ERROR: failed copying directory secret target from secrets-targets.conf.sh SECRETS_TARGETS" >&2
      echo "  key: $key" >&2
      echo "  src: $src" >&2
      echo "  dst: $dst" >&2
      echo "  rel_dest: $rel_dest" >&2
      echo "  rsync exit: $RSYNC_RC" >&2
      echo "  rsync stderr:" >&2
      sed 's/^/    /' "$rsync_err" >&2
      rm -f "$rsync_err"
      exit 1
    fi

    rm -f "$rsync_err"
    chmod 700 "$dst" 2>/dev/null || true
    size=$(du -sh "$dst" 2>/dev/null | cut -f1)
  else
    dst_parent="$(dirname "$dst")"
    mkdir -p "$dst_parent"
    cp -p "$src" "$dst"
    chmod 600 "$dst" 2>/dev/null || true
    size=$(du -sh "$dst" 2>/dev/null | cut -f1)
  fi

  if [[ "$key" == "ssh" ]]; then
    find "$dst" -name "id_*" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
    echo -e "  ${GRN}✓  ssh  →  secrets-encrypted/ssh/  (${size})${RST}"
    echo -e "  ${YEL}  ⚠  Private keys — chmod 700/600 set${RST}"
    find "$dst" -name "id_*" ! -name "*.pub" 2>/dev/null | sort | \
      while read -r k; do printf "  ${DIM}    %s${RST}\n" "$(basename "$k")"; done
  elif [[ "$key" == "gnupg" ]]; then
    find "$dst/private-keys-v1.d" -type f -exec chmod 600 {} \; 2>/dev/null || true
    key_count=$(find "$dst/private-keys-v1.d" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  ${GRN}✓  gnupg  →  secrets-encrypted/gnupg/  (${size}  /  ${key_count} key(s))${RST}"
    echo -e "  ${RED}  ⚠  GPG private keys — permanent loss if not backed up${RST}"
  else
    echo -e "  ${GRN}✓  ${key}  →  secrets-encrypted/${rel_dest}  (${size})${RST}"
  fi
}


write_local_files_manifest() {
  local manifest_stage="${1:-completed}"
  local manifest="$DEST/MANIFEST.md"
  local tmp_manifest="$manifest.tmp"
  local od_subdir="${ONEDRIVE_DEST_SUBDIR:-$(basename "${REIMAGE_ARTIFACT_ROOT%/}")}"

  mkdir -p "$DEST"

  {
    echo "# Local Files Backup Manifest"
    echo "Generated : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Host      : $(hostname)"
    echo "macOS     : $(sw_vers -productVersion 2>/dev/null || echo unknown)"
    echo "Config    : $CONFIG"
    echo "Status    : $manifest_stage"
    echo ""

    echo "## External Drive Targets"
    echo "| Label | Source | Destination | Description |"
    echo "|---|---|---|---|"
    if declare -p EXTERNAL_TARGETS >/dev/null 2>&1; then
      for entry in "${EXTERNAL_TARGETS[@]}"; do
        label=$(config_field "$entry" 1 || true)
        src=$(config_field "$entry" 2 || true)
        rel=$(config_field "$entry" 3 || true)
        desc=$(config_field "$entry" 5 || true)
        echo "| $label | $src | home-files-backup/$rel | $desc |"
      done
    else
      echo "| WARN | EXTERNAL_TARGETS not defined | home-files-backup/ | Review the artifact-config fragments |"
    fi
    echo ""

    echo "## Dotfiles"
    echo "| File | Description |"
    echo "|---|---|"
    if declare -p EXTERNAL_DOTFILES >/dev/null 2>&1; then
      for entry in "${EXTERNAL_DOTFILES[@]}"; do
        df=$(config_field "$entry" 1 || true)
        category=$(config_field "$entry" 2 || true)
        desc=$(config_field "$entry" 3 || true)
        if [[ "$category" == "secrets" ]]; then
          continue
        fi
        if [[ -n "$df" && -f "$HOME/$df" ]]; then
          echo "| $df | $desc |"
        fi
      done
    fi
    echo ""

    echo "## Secrets (secrets-encrypted/)"
    echo "| Key | Source | Description |"
    echo "|---|---|---|"
    if declare -p SECRETS_TARGETS >/dev/null 2>&1; then
      for entry in "${SECRETS_TARGETS[@]}"; do
        key=$(config_field "$entry" 1 || true)
        src=$(config_field "$entry" 2 || true)
        desc=$(config_field "$entry" 4 || true)
        echo "| $key | $src | $desc |"
      done
    fi
    echo "| java-jssecacerts | JAVA_HOME, /Library/Java/JavaVirtualMachines, IntelliJ bundled JBR | Corporate Java trust override staged under secrets-encrypted/certs/java-security/; restore only after target JDK is confirmed |"
    echo "| chrome-passwords | manual export to secrets-encrypted/chrome/Chrome Passwords*.csv | Optional Chrome password CSV; include in consolidated secrets DMG and delete loose CSV after validation |"
    echo "| intellij-http-client | IntelliJ HTTP Client environment files | Credential-bearing HTTP Client environments; included by create-secrets-dmg.sh when present |"
    echo ""

    echo "## OneDrive Targets"
    echo "| Label | Source | Destination | Description |"
    echo "|---|---|---|---|"
    if declare -p ONEDRIVE_TARGETS >/dev/null 2>&1; then
      for entry in "${ONEDRIVE_TARGETS[@]}"; do
        label=$(config_field "$entry" 1 || true)
        src=$(config_field "$entry" 2 || true)
        rel=$(config_field "$entry" 3 || true)
        desc=$(config_field "$entry" 5 || true)
        echo "| $label | $src | OneDrive/$od_subdir/$rel | $desc |"
      done
    else
      echo "| WARN | ONEDRIVE_TARGETS not defined | OneDrive/$od_subdir/ | Review the artifact-config fragments |"
    fi
    echo ""

    echo "## External Excludes"
    if declare -p EXTERNAL_EXCLUDES >/dev/null 2>&1; then
      for p in "${EXTERNAL_EXCLUDES[@]}"; do echo "- \`$p\`"; done
    fi
    echo ""

    echo "## OneDrive Extra Excludes"
    if declare -p ONEDRIVE_EXTRA_EXCLUDES >/dev/null 2>&1; then
      for p in "${ONEDRIVE_EXTRA_EXCLUDES[@]}"; do echo "- \`$p\`"; done
    fi
    echo ""

    echo "## Restore"
    echo "\`\`\`bash"
    echo "REIMAGE_ARTIFACT_ROOT=\"$REIMAGE_ARTIFACT_ROOT\""
    echo "rsync -av \"\$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Documents/\" ~/Documents/"
    echo "rsync -av \"\$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Desktop/\"   ~/Desktop/"
    echo "rsync -av \"\$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/config/\" ~/.config/"
    echo "rsync -av \"\$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/kube/\"   ~/.kube/"
    echo "cp \"\$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/.zshrc\" ~/"
    echo "cp \"\$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/.shell_common.sh\" ~/"
    echo "# SSH — from secrets DMG:"
    echo "cp -r /Volumes/all-secrets-STAMP/ssh/ ~/.ssh/ && chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*"
    echo "# GPG — from secrets DMG:"
    echo "cp -r /Volumes/all-secrets-STAMP/gnupg/ ~/.gnupg/ && chmod 700 ~/.gnupg"
    echo "\`\`\`"
  } > "$tmp_manifest"

  mv "$tmp_manifest" "$manifest"
}

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLD}${CYN}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BLD}${CYN}║        Local Files Backup                            ║${RST}"
echo -e "${BLD}${CYN}║        $(date '+%Y-%m-%d %H:%M:%S')                        ║${RST}"
echo -e "${BLD}${CYN}╚══════════════════════════════════════════════════════╝${RST}"
echo ""

# ── Pre-flight: OneDrive ──────────────────────────────────────────────────────
# Resolved before the config block below so a run states every destination it
# will write to up front, rather than revealing the OneDrive path further down.
# A resolution failure downgrades the run to external-only here, so the
# "OneDrive:" line the operator reads is the decision actually taken.
ONEDRIVE_DEST=""
ONEDRIVE_PREFLIGHT_ERRORS=""
if $RUN_ONEDRIVE; then
  ONEDRIVE_EXPECTED_ROOT="$(onedrive_expected_root)"

  # resolve_onedrive_root explains precisely which value is wrong on stderr.
  # Hold that detail aside rather than discarding it, so it prints with the
  # summary line below instead of ahead of the config block.
  ONEDRIVE_RESOLVE_ERR="$(mktemp)"
  if ! RESOLVED_ONEDRIVE_ROOT="$(resolve_onedrive_root 2>"$ONEDRIVE_RESOLVE_ERR")"; then
    ONEDRIVE_PREFLIGHT_ERRORS="$(printf '  %b✗ OneDrive root is misconfigured.%b\n  %b  Expected root: %s%b' \
      "$RED" "$RST" "$DIM" "$ONEDRIVE_EXPECTED_ROOT" "$RST")"
    if [[ -s "$ONEDRIVE_RESOLVE_ERR" ]]; then
      while IFS= read -r resolve_line; do
        ONEDRIVE_PREFLIGHT_ERRORS="$ONEDRIVE_PREFLIGHT_ERRORS
$(printf '  %b  %s%b' "$DIM" "$resolve_line" "$RST")"
      done < "$ONEDRIVE_RESOLVE_ERR"
    fi
    RUN_ONEDRIVE=false
  elif [[ -z "$RESOLVED_ONEDRIVE_ROOT" ]]; then
    ONEDRIVE_PREFLIGHT_ERRORS="$(printf '  %b✗ OneDrive not found. Open OneDrive and sign in, or set ONEDRIVE_ROOT in reimage.env.%b' \
      "$RED" "$RST")"
    RUN_ONEDRIVE=false
  else
    ONEDRIVE_ROOT="$RESOLVED_ONEDRIVE_ROOT"

    if [[ -n "${REPO_ROOT:-}" && ( "$ONEDRIVE_ROOT" == "$REPO_ROOT" || "$ONEDRIVE_ROOT" == "$REPO_ROOT"/* ) ]]; then
      ONEDRIVE_PREFLIGHT_ERRORS="$(printf '  %b✗ Refusing to write OneDrive backup under REPO_ROOT.%b\n  %b  Bad root : %s%b\n  %b  Expected : %s%b' \
        "$RED" "$RST" "$DIM" "$ONEDRIVE_ROOT" "$RST" "$DIM" "$ONEDRIVE_EXPECTED_ROOT" "$RST")"
      RUN_ONEDRIVE=false
    else
      ONEDRIVE_DEST="${ONEDRIVE_ROOT}/${ONEDRIVE_DEST_SUBDIR}"
    fi
  fi
  rm -f "$ONEDRIVE_RESOLVE_ERR"
fi

# ── Config block ──────────────────────────────────────────────────────────────
echo -e "  Config       : ${DIM}${CONFIG}${RST}"
echo -e "  Artifact root: ${BLD}${REIMAGE_ARTIFACT_ROOT}${RST}"
if $RUN_ONEDRIVE; then
  echo -e "  OneDrive root: ${BLD}${ONEDRIVE_ROOT}${RST}"
  echo -e "  OneDrive dest: ${BLD}${ONEDRIVE_DEST}${RST}"
fi
if $RUN_ONEDRIVE; then
  ONEDRIVE_STATUS="yes"
elif [[ -n "$ONEDRIVE_PREFLIGHT_ERRORS" ]]; then
  ONEDRIVE_STATUS="unavailable"
else
  ONEDRIVE_STATUS="skipped"
fi

echo -e "  External     : ${BLD}$( $RUN_EXTERNAL && echo yes || echo skipped )${RST}"
echo -e "  OneDrive     : ${BLD}${ONEDRIVE_STATUS}${RST}"

if [[ -n "$ONEDRIVE_PREFLIGHT_ERRORS" ]]; then
  echo ""
  printf '%b\n' "$ONEDRIVE_PREFLIGHT_ERRORS"
  # Nothing left to do when OneDrive was the only requested destination.
  $RUN_EXTERNAL || exit 2
fi

if $RUN_ONEDRIVE; then
  pgrep -xq "OneDrive" 2>/dev/null \
    || echo -e "  ${YEL}⚠  OneDrive not running — files will copy but won't upload until OneDrive starts${RST}"
fi

$DRY_RUN && echo "" && echo -e "  ${YEL}DRY RUN — no files will be copied${RST}"
echo ""

# ── Pre-flight: external ──────────────────────────────────────────────────────
if $RUN_EXTERNAL; then
  if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
    echo -e "${RED}✗ Artifact root not found: ${REIMAGE_ARTIFACT_ROOT}${RST}"
    echo -e "${DIM}  Pass --artifact-root PATH or check the drive is mounted.${RST}"
    exit 2
  fi
  if [[ -d "$DEST" ]] && [[ -n "$(ls -A "$DEST" 2>/dev/null)" ]]; then
    PRIOR=$(du -sh "$DEST" 2>/dev/null | cut -f1)
    echo -e "  ${YEL}⚠  home-files-backup/ already exists (${PRIOR}) — re-run syncs changes.${RST}\n"
  fi
  # A dry run previews only; it must not create home-files-backup/ or write a
  # started-manifest into an artifact root the operator has not committed to.
  if ! $DRY_RUN; then
    mkdir -p "$DEST"
    write_local_files_manifest "started - backup still running"
  fi
fi

START_TIME=$SECONDS

# Build exclude flag arrays once from config
build_exclude_flags ${EXTERNAL_EXCLUDES[@]+"${EXTERNAL_EXCLUDES[@]}"}
EXT_EXCL_FLAGS=( ${EXCLUDE_FLAGS[@]+"${EXCLUDE_FLAGS[@]}"} )

# ══════════════════════════════════════════════════════════════════════════════
# EXTERNAL DRIVE
# ══════════════════════════════════════════════════════════════════════════════
if $RUN_EXTERNAL; then

  # ── Directory targets (from config) ─────────────────────────────────────────
  log_section "External drive — directory targets"
  echo -e "  ${DIM}Defined in external-targets.conf.sh${RST}"

  current_category=""
  if declare -p EXTERNAL_TARGETS >/dev/null 2>&1 && (( ${#EXTERNAL_TARGETS[@]} > 0 )); then
    for entry in "${EXTERNAL_TARGETS[@]}"; do
      label=$(config_field "$entry" 1)
      src=$(config_field "$entry" 2)
      rel_dest=$(config_field "$entry" 3)
      category=$(config_field "$entry" 4)
      dst="$DEST/$rel_dest"

      if [[ "$category" != "$current_category" ]]; then
        # `tr` rather than ${var^^}: uppercase expansion is Bash 4 only.
        echo ""
        echo -e "  ${DIM}── $(printf '%s' "$category" | tr '[:lower:]' '[:upper:]') ──${RST}"
        current_category="$category"
      fi

      run_rsync "$label" "$src" "$dst" "$DRY_RUN" ${EXT_EXCL_FLAGS[@]+"${EXT_EXCL_FLAGS[@]}"}
    done
  else
    echo -e "  ${YEL}⚠  EXTERNAL_TARGETS is empty or undefined — no directory targets copied.${RST}"
  fi

  # ── Dotfiles ─────────────────────────────────────────────────────────────────
  log_section "External drive — dotfiles"
  echo -e "  ${DIM}Defined in external-dotfiles.conf.sh${RST}"

  DOTS_DEST="$DEST/dotfiles"
  $DRY_RUN || mkdir -p "$DOTS_DEST"
  dot_count=0

  if declare -p EXTERNAL_DOTFILES >/dev/null 2>&1 && (( ${#EXTERNAL_DOTFILES[@]} > 0 )); then
    for entry in "${EXTERNAL_DOTFILES[@]}"; do
      df=$(config_field "$entry" 1)
      category=$(config_field "$entry" 2)
      fp="$HOME/$df"
      if [[ "$category" == "secrets" ]]; then
        printf "  ${DIM}– %-38s  handled by SECRETS_TARGETS${RST}\n" "$df"
        continue
      fi
      [[ -f "$fp" ]] || continue
      prior_note=""; [[ -f "$DOTS_DEST/$df" ]] && prior_note=" (updated)"
      if $DRY_RUN; then
        printf "  ${YEL}~  %-38s  (dry run)${RST}\n" "$df"
      else
        cp -p "$fp" "$DOTS_DEST/$df"
        sz=$(du -sh "$fp" 2>/dev/null | cut -f1)
        printf "  ${GRN}✓  %-38s  %s%s${RST}\n" "$df" "$sz" "$prior_note"
      fi
      (( dot_count++ )) || true
    done
  fi
  (( dot_count == 0 )) && echo -e "  ${DIM}  No dotfiles found${RST}"

  # ── Secrets ──────────────────────────────────────────────────────────────────
  log_section "External drive — secrets  →  secrets-encrypted/"
  echo -e "  ${DIM}Defined in secrets-targets.conf.sh${RST}"

  if declare -p SECRETS_TARGETS >/dev/null 2>&1 && (( ${#SECRETS_TARGETS[@]} > 0 )); then
    for entry in "${SECRETS_TARGETS[@]}"; do
      key=$(config_field "$entry" 1)
      src=$(config_field "$entry" 2)
      rel_dest=$(config_field "$entry" 3)

      flag_var=$(secret_flag_name "$key")
      enabled="${!flag_var:-true}"
      if [[ "$enabled" != "true" ]]; then
        printf "  ${DIM}– %-18s  disabled in config (%s=false)${RST}\n" "$key" "$flag_var"
        continue
      fi

      copy_secret_target "$key" "$src" "$rel_dest" "$DRY_RUN"
    done
  else
    echo -e "  ${YEL}⚠  SECRETS_TARGETS is empty or undefined — no secrets staged.${RST}"
  fi

  # ── Java jssecacerts ───────────────────────────────────────────────────────────
  if [[ "${BACKUP_JAVA_JSSECACERTS:-true}" == "true" ]]; then
    log_section "External drive — Java jssecacerts  →  secrets-encrypted/certs/java-security"
    copy_java_jssecacerts "$REIMAGE_ARTIFACT_ROOT" "$DRY_RUN"
  fi

  # Docker settings/contexts/inventories are owned by Phase 2C (backup-apps.sh);
  # dev-tool version inventory is owned by Phase 4B (capture-system-inventory.sh).
  # Neither is duplicated here.

fi  # end RUN_EXTERNAL

# ══════════════════════════════════════════════════════════════════════════════
# MANIFEST
# Written before OneDrive sync so an upload error cannot suppress the external manifest.
# Also written once at preflight as a started manifest, then refreshed here.
# ══════════════════════════════════════════════════════════════════════════════
if $RUN_EXTERNAL && ! $DRY_RUN; then

  log_section "Writing manifest  →  home-files-backup/MANIFEST.md"
  write_local_files_manifest "completed external backup before OneDrive sync"
  echo -e "  ${GRN}✓  MANIFEST.md written${RST}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# ONEDRIVE SYNC
# ══════════════════════════════════════════════════════════════════════════════
if $RUN_ONEDRIVE; then

  log_section "OneDrive sync  →  ${ONEDRIVE_DEST}"
  echo -e "  ${DIM}Targets defined in onedrive-targets.conf.sh${RST}"
  echo -e "  ${DIM}Extra excludes in onedrive-extra-excludes.conf.sh${RST}"

  build_exclude_flags \
    ${EXTERNAL_EXCLUDES[@]+"${EXTERNAL_EXCLUDES[@]}"} \
    ${ONEDRIVE_EXTRA_EXCLUDES[@]+"${ONEDRIVE_EXTRA_EXCLUDES[@]}"}
  ALL_OD_FLAGS=( ${EXCLUDE_FLAGS[@]+"${EXCLUDE_FLAGS[@]}"} )

  $DRY_RUN || mkdir -p "$ONEDRIVE_DEST"

  if declare -p ONEDRIVE_TARGETS >/dev/null 2>&1 && (( ${#ONEDRIVE_TARGETS[@]} > 0 )); then
    for entry in "${ONEDRIVE_TARGETS[@]}"; do
      label=$(config_field "$entry" 1)
      src=$(config_field "$entry" 2)
      rel_dest=$(config_field "$entry" 3)
      dst="$ONEDRIVE_DEST/$rel_dest"
      run_rsync "OneDrive/$rel_dest" "$src" "$dst" "$DRY_RUN" ${ALL_OD_FLAGS[@]+"${ALL_OD_FLAGS[@]}"}
    done
  else
    echo -e "  ${YEL}⚠  ONEDRIVE_TARGETS is empty or undefined — nothing to sync.${RST}"
  fi

  if ! $DRY_RUN; then
    echo ""
    echo -e "  ${DIM}Files written. Upload happens in the background.${RST}"
    echo -e "  ${DIM}Watch the OneDrive menu bar icon — checkmark = fully synced.${RST}"
    pgrep -xq "OneDrive" 2>/dev/null \
      && echo -e "  ${GRN}  OneDrive process: running ✓${RST}" \
      || echo -e "  ${YEL}  OneDrive process: not running — open OneDrive to start upload${RST}"
  fi

fi  # end RUN_ONEDRIVE

# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════
ELAPSED=$(( SECONDS - START_TIME ))
echo ""
hr
$DRY_RUN \
  && echo -e "${YEL}${BLD}Dry run complete — no files were copied.${RST}" \
  || echo -e "${GRN}${BLD}Backup complete.${RST}"
echo ""
$RUN_EXTERNAL && ! $DRY_RUN && \
  printf "  %-30s  %s\n" "home-files-backup/ size:" "$(du -sh "$DEST" 2>/dev/null | cut -f1)"
$RUN_EXTERNAL && ! $DRY_RUN && [[ -d "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted" ]] && \
  printf "  %-30s  %s\n" "secrets-encrypted/ size:" "$(du -sh "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted" 2>/dev/null | cut -f1)"
$RUN_ONEDRIVE && ! $DRY_RUN && [[ -d "${ONEDRIVE_DEST:-/dev/null}" ]] && \
  printf "  %-30s  %s\n" "OneDrive dest size:" "$(du -sh "$ONEDRIVE_DEST" 2>/dev/null | cut -f1)"
printf "  %-30s  %s\n" "Elapsed:" "${ELAPSED}s"
if (( RSYNC_WARNINGS > 0 )); then
  echo ""
  echo -e "  ${YEL}⚠  ${RSYNC_WARNINGS} target(s) reported an rsync warning (23/24) — review the stderr above.${RST}"
fi
! $DRY_RUN && echo "" && \
  echo -e "  ${YEL}Next: export any manual Chrome/Postman secrets if needed, then run create-secrets-dmg.sh to encrypt ssh/, gnupg/, docker/config.json, Java jssecacerts under certs/java-security, Chrome password CSVs, Postman/Raycast secret exports, package-manager credentials, and other secrets into AES-256 DMG.${RST}"
echo ""
