#!/usr/bin/env bash
# =============================================================================
# create-secrets-dmg.sh
#
# Phase 3B entrypoint for the consolidated encrypted secrets DMG. One script
# owns the whole lifecycle through four subcommands:
#
#   build (default)  Stage every credential-bearing category that should survive
#                    the reimage into one temporary tree and encrypt it into
#                    all-secrets-<stamp>.dmg, with a manifest, Java jssecacerts
#                    inventory, and restore README.
#   verify-staging   Before building, report what manual staging is actually
#                    present under secrets-encrypted/ — driven by what exists on
#                    disk, so it never drifts as backup-apps.md's app set grows.
#   validate         Mount the newest DMG and check its contents against what is
#                    staged on disk (drift-proof cross-check), plus foundational
#                    secrets, private-key placement, PEM balance, and manifest
#                    coverage; then detach.
#   cleanup          Remove loose plaintext staging for every category confirmed
#                    present in the newest DMG. Dry-run by default.
#
# verify-staging / validate / cleanup each write a timestamped Markdown report
# to $REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/secrets-dmg/ (never overwritten)
# with automated PASS/WARN/FAIL rows and a short "manual — you confirm" section.
#
# Sources the build collects (each skipped when absent):
#   SSH ~/.ssh · GPG ~/.gnupg (random_seed excluded) · Docker ~/.docker/config.json ·
#   Kube ~/.kube/config · CLI/pkg ~/.netrc ~/.git-credentials ~/.npmrc ~/.yarnrc(.yml)
#   ~/.pypirc ~/.gradle/gradle.properties ~/.m2/settings.xml (AWS/cloud NOT captured) ·
#   Certs ~/.keystore, home-root *.jks, Java jssecacerts, Desktop/Downloads cert
#   bundles, secrets-encrypted/certs/ · Cert review secrets-encrypted/extra-secrets-
#   certs-review/ (state/ excluded) · Chrome Passwords*.csv · plus a generic sweep of
#   every other pre-staged category under secrets-encrypted/ (claude/, intellij/,
#   licenses/, postman/, raycast/, …). cloud/ and the review state/ folder are excluded.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   ./bin/create-secrets-dmg.sh [build] [--skip-cert-review] [--artifact-root PATH]
#   ./bin/create-secrets-dmg.sh verify-staging [--artifact-root PATH]
#   ./bin/create-secrets-dmg.sh validate [--artifact-root PATH]
#   ./bin/create-secrets-dmg.sh cleanup [--force] [--keep CATEGORY]... [--artifact-root PATH]
#
# Subcommands:
#   build (default)  Stage every secret category and build all-secrets-<stamp>.dmg.
#   verify-staging   Report the manual staging present under secrets-encrypted/.
#   validate         Mount the newest DMG, run checks, detach, write a report.
#   cleanup          Remove loose plaintext confirmed inside the newest DMG.
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --skip-cert-review    (build) Do not rerun stage-certs-keychain.sh scan first.
#   --force               (cleanup) Actually delete. Default is a dry-run preview.
#   --keep CATEGORY       (cleanup) Preserve this category even if it is in the DMG.
#                         Repeatable (e.g. --keep postman).
#   -h, --help            Show this message and exit.
#
# Reports:
#   verify-staging / validate / cleanup write a timestamped Markdown report to
#   $REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/secrets-dmg/. Reports are never
#   overwritten — each run adds a new timestamped file.
#
# Configuration precedence:
#   1. Explicit command-line options.  2. Caller/.envrc env.  3. reimage.env.
#   4. Defaults and fragments loaded by artifact-config.sh.
#
# Exit status:
#   0  Subcommand completed with no FAIL.
#   1  Ran but hit a workflow/runtime failure (nothing staged, password mismatch,
#      a validation FAIL).
#   2  Usage, configuration, prerequisite, or dependency error.
#
# Important:
#   Store the DMG password in an approved password manager immediately after the
#   build. Without it the backup cannot be restored.
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

# Keep loading permissive so --artifact-root can override after parsing.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/{
    /^# --- BEGIN USAGE ---$/d
    /^# --- END USAGE ---$/d
    s/^# \{0,1\}//
    p
  }' "$0"
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
# Parse subcommand + options
# ---------------------------------------------------------------------------
SUBCMD="build"
subcmd_set=false
RUN_CERT_REVIEW=true
FORCE=false
KEEP_LIST=":"

while [[ $# -gt 0 ]]; do
  case "$1" in
    build|verify-staging|validate|cleanup)
      if [[ "$subcmd_set" == false ]]; then
        SUBCMD="$1"; subcmd_set=true; shift
      else
        echo "ERROR: unexpected extra argument: $1" >&2; usage >&2; exit 2
      fi
      ;;
    --artifact-root)
      require_option_value "$1" "${2:-}"; REIMAGE_ARTIFACT_ROOT="$2"; shift 2 ;;
    --skip-cert-review)
      RUN_CERT_REVIEW=false; shift ;;
    --force)
      FORCE=true; shift ;;
    --keep)
      require_option_value "$1" "${2:-}"; KEEP_LIST="${KEEP_LIST}${2}:"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve and validate configured paths
# ---------------------------------------------------------------------------
if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set." >&2
  echo "Source reimage.env or pass --artifact-root PATH." >&2
  exit 2
fi
if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: artifact root not found: $REIMAGE_ARTIFACT_ROOT" >&2
  exit 2
fi

STAGE_CERTS_KEYCHAIN_SCRIPT="$SCRIPT_DIR/stage-certs-keychain.sh"

STAMP="$(date +%Y%m%d-%H%M%S)"
SECRETS_DIR="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"
EXTRA_CERTS_REVIEW_DIR="$SECRETS_DIR/extra-secrets-certs-review"
REPORT_DIR="$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/secrets-dmg"

# ---------------------------------------------------------------------------
# User-facing output helpers (house palette — see backup-home.sh)
# ---------------------------------------------------------------------------
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

ok()    { printf "  ${GRN}✓  %s${RST}\n" "$1" ; }
skip()  { printf "  ${DIM}–  %s  (not found, skipping)${RST}\n" "$1" ; }
warn()  { printf "  ${YEL}⚠  %s${RST}\n" "$1" ; }
err()   { printf "  ${RED}✗  %s${RST}\n" "$1" >&2 ; }
info()  { printf "  ${DIM}   %s${RST}\n" "$1" ; }
hr()      { printf '%s\n' "────────────────────────────────────────────────────────" ; }
thin_hr() { printf '%s\n' "  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄" ; }

banner() {
  echo ""
  echo -e "${BLD}${CYN}▸ $1${RST}"
  echo -e "  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')  ·  artifact root: $REIMAGE_ARTIFACT_ROOT${RST}"
  thin_hr
}

# ---------------------------------------------------------------------------
# Shared analysis helpers (drift-proof: driven by what actually exists)
# ---------------------------------------------------------------------------

# Print each direct-child category folder under secrets-encrypted/, one per line,
# excluding this run's temp staging trees. New categories added by later phases
# appear automatically.
list_categories() {
  local p n
  for p in "$SECRETS_DIR"/*/; do
    [[ -d "$p" ]] || continue
    n="$(basename "$p")"
    case "$n" in staging-*) continue ;; esac
    printf '%s\n' "$n"
  done
}

# Count real staged files in a category, ignoring folder scaffolding (README.md,
# .DS_Store) and — for the review dir — the regenerable state/ control folder.
category_file_count() {
  local cat="$1" root="$SECRETS_DIR/$1" fc
  [[ -d "$root" ]] || { printf '0'; return; }
  if [[ "$cat" == "extra-secrets-certs-review" ]]; then
    fc=(find "$root" -type d -path "$root/state" -prune -o -type f ! -name 'README.md' ! -name '.DS_Store' -print)
  else
    fc=(find "$root" -type f ! -name 'README.md' ! -name '.DS_Store' -print)
  fi
  "${fc[@]}" 2>/dev/null | wc -l | tr -d ' '
}

# Track a mounted DMG so an EXIT trap can always detach it, even on early exit.
MOUNTED_VOL=""
detach_mounted() {
  [[ -n "${MOUNTED_VOL:-}" ]] && hdiutil detach "$MOUNTED_VOL" >/dev/null 2>&1 || true
}

newest_dmg()      { ls -t "$SECRETS_DIR"/all-secrets-*.dmg 2>/dev/null | head -1 || true ; }
newest_manifest() { ls -t "$SECRETS_DIR"/all-secrets-*-manifest.txt 2>/dev/null | head -1 || true ; }

# Resolve the mount point for a DMG, deterministically from its volume name and
# falling back to the newest all-secrets-* volume actually mounted.
resolve_vol_for_dmg() {
  local dmg="$1" base d v=""
  base="$(basename "$dmg" .dmg)"
  if [[ -d "/Volumes/$base" ]]; then printf '/Volumes/%s' "$base"; return 0; fi
  # Fallback: newest mounted all-secrets-* volume (stamped names sort chronologically).
  for d in /Volumes/all-secrets-*; do
    [[ -d "$d" ]] && v="$d"
  done
  [[ -n "$v" ]] && printf '%s' "$v"
}

# Ensure the DMG is mounted and echo its volume path. Reuses an existing mount so
# a DMG left attached by an earlier validate/cleanup run or open in Finder does
# not cause a spurious failure; only attaches (prompting for the password) when
# the volume is not already present. Echoes nothing and returns non-zero on
# failure. Password prompt and hdiutil errors stay on the terminal.
mount_or_reuse_dmg() {
  local dmg="$1" vol
  vol="$(resolve_vol_for_dmg "$dmg")"
  if [[ -n "$vol" && -d "$vol" ]]; then
    printf '%s' "$vol"; return 0
  fi
  echo "  Mounting $(basename "$dmg") — enter the DMG password when prompted." >&2
  hdiutil attach "$dmg" >/dev/null || return 1
  vol="$(resolve_vol_for_dmg "$dmg")"
  [[ -n "$vol" && -d "$vol" ]] || return 1
  printf '%s' "$vol"
}

# Report accumulation. Each subcommand sets REPORT_FILE, then calls rpt/status.
REPORT_FILE=""
PASS_N=0; WARN_N=0; FAIL_N=0
rpt() { [[ -n "$REPORT_FILE" ]] && printf '%s\n' "$*" >> "$REPORT_FILE"; }

# status LEVEL "label" "detail"  — prints to terminal and records a report row.
status() {
  local level="$1" label="$2" detail="${3:-}"
  case "$level" in
    PASS) (( PASS_N++ )) || true; ok "$label${detail:+  ($detail)}" ;;
    WARN) (( WARN_N++ )) || true; warn "$label${detail:+  ($detail)}" ;;
    FAIL) (( FAIL_N++ )) || true; err "$label${detail:+  ($detail)}" ;;
    INFO) info "$label${detail:+  ($detail)}" ;;
  esac
  rpt "| $level | $label | ${detail:-} |"
}

report_header() {
  local title="$1"
  mkdir -p "$REPORT_DIR"
  {
    echo "# $title"
    echo ""
    echo "- Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- Host: $(hostname 2>/dev/null || echo unknown)"
    echo "- Artifact root: \`$REIMAGE_ARTIFACT_ROOT\`"
    echo ""
  } > "$REPORT_FILE"
}

report_footer_and_path() {
  {
    echo ""
    echo "## Result"
    echo ""
    echo "- PASS: $PASS_N · WARN: $WARN_N · FAIL: $FAIL_N"
  } >> "$REPORT_FILE"
  echo ""
  hr
  printf '  Report: %s\n' "$REPORT_FILE"
}

# =============================================================================
# build
# =============================================================================
cmd_build() {
  # STAGING is global so the EXIT trap below can always wipe it.
  STAGING="$SECRETS_DIR/staging-$STAMP"
  local DMG_PATH="$SECRETS_DIR/all-secrets-$STAMP.dmg"
  local MANIFEST="$SECRETS_DIR/all-secrets-$STAMP-manifest.txt"
  local JAVA_JSSECACERTS_TABLE="$SECRETS_DIR/java-jssecacerts-inventory-$STAMP.md"
  local VOLNAME="all-secrets-$STAMP"

  if [[ ! -f "$STAGE_CERTS_KEYCHAIN_SCRIPT" ]]; then
    echo "ERROR: certificate/Keychain staging script not found: $STAGE_CERTS_KEYCHAIN_SCRIPT" >&2
    exit 2
  fi

  banner "Consolidated Secrets DMG — build"

  mkdir -p "$SECRETS_DIR" "$STAGING"
  : > "$MANIFEST"
  {
    echo "# Java jssecacerts Inventory"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "| Label | Source | SHA-256 | Size Bytes |"
    echo "|---|---|---:|---:|"
  } > "$JAVA_JSSECACERTS_TABLE"

  # Always wipe the temp staging tree.
  trap 'rm -rf "$STAGING"' EXIT

  local staged_count=0

  stage_file() {
    local category="$1" src="$2" strip_prefix="${3:-}" rel dest_dir
    if [[ -n "$strip_prefix" ]]; then rel="${src#"${strip_prefix}"/}"; else rel="$(basename "$src")"; fi
    dest_dir="$STAGING/$category/$(dirname "$rel")"
    mkdir -p "$dest_dir"
    cp -p "$src" "$dest_dir/$(basename "$src")"
    printf '%s\n' "$src" >> "$MANIFEST"
  }

  stage_jssecacerts() {
    local src="$1" label="$2" safe_label dest_dir hash size
    [[ -f "$src" ]] || return 0
    safe_label=$(printf '%s' "$label" | sed 's/[^A-Za-z0-9_.-]/_/g')
    dest_dir="$STAGING/certs/java-security/$safe_label"
    mkdir -p "$dest_dir"
    cp -p "$src" "$dest_dir/jssecacerts"
    hash=$(shasum -a 256 "$src" 2>/dev/null | awk '{print $1}' || true)
    size=$(wc -c < "$src" 2>/dev/null | tr -d ' ' || true)
    {
      printf 'source=%s\n' "$src"; printf 'label=%s\n' "$label"
      printf 'sha256=%s\n' "${hash:-unknown}"; printf 'size_bytes=%s\n' "${size:-unknown}"
      printf 'captured_at=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    } > "$dest_dir/README.txt"
    printf '| `%s` | `%s` | `%s` | `%s` |\n' "$label" "$src" "${hash:-unknown}" "${size:-unknown}" >> "$JAVA_JSSECACERTS_TABLE"
    printf '%s\n' "$src" >> "$MANIFEST"
  }

  stage_existing_secret_tree() {
    local category="$1" src_root="$2" prune_subdir="${3:-}" find_cmd
    [[ -d "$src_root" ]] || return 0
    if [[ -n "$prune_subdir" ]]; then
      find_cmd=(find "$src_root" -type d -path "$src_root/$prune_subdir" -prune -o -type f -print0)
    else
      find_cmd=(find "$src_root" -type f -print0)
    fi
    while IFS= read -r -d '' f; do
      case "$(basename "$f")" in
        all-secrets-*.dmg|all-secrets-*-manifest.txt) continue ;;
      esac
      stage_file "$category" "$f" "$src_root"
      ok "${category}/$(basename "$f")"
      (( staged_count++ )) || true
    done < <("${find_cmd[@]}" 2>/dev/null)
    return 0
  }

  if [[ "$RUN_CERT_REVIEW" == "true" ]]; then
    echo ""; echo -e "${BLD}Extra Certificate and Secrets Review${RST}"; thin_hr
    bash "$STAGE_CERTS_KEYCHAIN_SCRIPT" scan --artifact-root "$REIMAGE_ARTIFACT_ROOT"
  fi

  # 1. SSH
  echo -e "${BLD}SSH Keys  (~/.ssh)${RST}"; thin_hr
  if [[ -d "$HOME/.ssh" ]]; then
    while IFS= read -r -d '' f; do
      stage_file "ssh" "$f" "$HOME/.ssh"; ok "$(basename "$f")"; (( staged_count++ )) || true
    done < <(find "$HOME/.ssh" -maxdepth 1 -type f -print0 2>/dev/null)
    chmod 700 "$STAGING/ssh" 2>/dev/null || true
    find "$STAGING/ssh" -name "id_*" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
  else skip "~/.ssh"; fi

  # 2. GPG
  echo ""; echo -e "${BLD}GPG Keys  (~/.gnupg)${RST}"; thin_hr
  if [[ -d "$HOME/.gnupg" ]]; then
    local gnupg_count=0 priv_count
    while IFS= read -r -d '' f; do
      stage_file "gnupg" "$f" "$HOME/.gnupg"; ok "$(basename "$f")"; (( staged_count++ )) || true; (( gnupg_count++ )) || true
    done < <(find "$HOME/.gnupg" -type f ! -name "random_seed" -print0 2>/dev/null)
    chmod 700 "$STAGING/gnupg" 2>/dev/null || true
    find "$STAGING/gnupg/private-keys-v1.d" -type f -exec chmod 600 {} \; 2>/dev/null || true
    priv_count=$(find "$HOME/.gnupg/private-keys-v1.d" -type f 2>/dev/null | wc -l | tr -d ' ')
    info "Staged ${gnupg_count} file(s) — ${priv_count} private key(s) in private-keys-v1.d/"
    info "random_seed excluded (machine-specific; not needed for restore)"
    printf "  ${RED}⚠  GPG private keys cannot be regenerated — verify this DMG after creation${RST}\n"
  else skip "~/.gnupg"; fi

  # 3. Docker
  echo ""; echo -e "${BLD}Docker  (~/.docker/config.json)${RST}"; thin_hr
  if [[ -f "$HOME/.docker/config.json" ]]; then
    stage_file "docker" "$HOME/.docker/config.json" "$HOME/.docker"; ok "config.json"
    info "Contains credential helpers and auth tokens — run: docker login after reimage"; (( staged_count++ )) || true
  else skip "~/.docker/config.json"; fi

  # 4. Kube
  echo ""; echo -e "${BLD}Kube Config  (~/.kube/config)${RST}"; thin_hr
  if [[ -f "$HOME/.kube/config" ]]; then
    stage_file "kube" "$HOME/.kube/config" "$HOME/.kube"; ok "config"
    info "Contains cluster API tokens and certificates"; (( staged_count++ )) || true
  else skip "~/.kube/config"; fi

  # 5. Common CLI / package-manager credentials (AWS/cloud intentionally excluded)
  echo ""; echo -e "${BLD}Common CLI and Package-Manager Credentials${RST}"; thin_hr
  local common_secret_found=0
  stage_common_secret_file() {
    local category="$1" src="$2" display="$3" strip_prefix="${4:-}"
    [[ -f "$src" ]] || return 0
    stage_file "$category" "$src" "$strip_prefix"; ok "$display"
    (( staged_count++ )) || true; (( common_secret_found++ )) || true
  }
  stage_common_secret_file "cli-credentials" "$HOME/.netrc" ".netrc" "$HOME"
  stage_common_secret_file "git" "$HOME/.git-credentials" ".git-credentials" "$HOME"
  stage_common_secret_file "package-managers" "$HOME/.npmrc" ".npmrc" "$HOME"
  stage_common_secret_file "package-managers" "$HOME/.yarnrc" ".yarnrc" "$HOME"
  stage_common_secret_file "package-managers" "$HOME/.yarnrc.yml" ".yarnrc.yml" "$HOME"
  stage_common_secret_file "package-managers" "$HOME/.pypirc" ".pypirc" "$HOME"
  stage_common_secret_file "package-managers" "$HOME/.gradle/gradle.properties" "gradle.properties" "$HOME/.gradle"
  stage_common_secret_file "package-managers" "$HOME/.m2/settings.xml" "maven settings.xml" "$HOME/.m2"
  local staged_secret_dir category before_count staged_now
  for staged_secret_dir in "$SECRETS_DIR/cli-credentials" "$SECRETS_DIR/git" "$SECRETS_DIR/package-managers"; do
    [[ -d "$staged_secret_dir" ]] || continue
    category="$(basename "$staged_secret_dir")"; before_count="$staged_count"
    stage_existing_secret_tree "$category" "$staged_secret_dir"
    staged_now=$((staged_count - before_count)); (( staged_now > 0 )) && (( common_secret_found += staged_now )) || true
  done
  (( common_secret_found == 0 )) && skip "No .netrc, Git credential cache, or package-manager credential files found"

  # 6. Certificates and keystores
  echo ""; echo -e "${BLD}Certificates and Keystores${RST}"; thin_hr
  local CERT_PATTERN=( -name "*.pem" -o -name "*.p12" -o -name "*.pfx" -o -name "*.cer" -o -name "*.crt" -o -name "*.keystore" -o -name "*.jks" )
  local cert_found=0
  if [[ -f "$HOME/.keystore" ]]; then
    stage_file "certs" "$HOME/.keystore" "$HOME"; ok ".keystore  (from ~/)"
    info "Java KeyStore — store password and key alias in an approved password manager"
    warn ".keystore password and key alias must be in an approved password manager to restore this file"
    (( staged_count++ )) || true; (( cert_found++ )) || true
  else skip "~/.keystore  (not found)"; fi
  while IFS= read -r -d '' f; do
    [[ "$(basename "$f")" == ".keystore" ]] && continue
    stage_file "certs" "$f" "$HOME"; ok "$(basename "$f")  (from ~/)"
    info "Java KeyStore — store password and key alias in an approved password manager"
    (( staged_count++ )) || true; (( cert_found++ )) || true
  done < <(find "$HOME" -maxdepth 1 -type f \( -name "*.jks" \) -print0 2>/dev/null)

  echo ""; echo -e "${BLD}Java jssecacerts${RST}"; thin_hr
  local jsse_found=0 seen_jsse_files=":"
  stage_jsse_if_new() {
    local f="$1" label="$2"
    [[ -f "$f" ]] || return 0
    case "$seen_jsse_files" in *:"$f":*) return 0 ;; esac
    seen_jsse_files="${seen_jsse_files}${f}:"
    stage_jssecacerts "$f" "$label"; ok "$label  →  certs/java-security/"
    (( staged_count++ )) || true; (( cert_found++ )) || true; (( jsse_found++ )) || true
  }
  [[ -n "${JAVA_HOME:-}" ]] && stage_jsse_if_new "$JAVA_HOME/lib/security/jssecacerts" "JAVA_HOME-$(basename "$JAVA_HOME")"
  shopt -s nullglob
  local jdk_home intellij_jbr staged_jsse
  for jdk_home in /Library/Java/JavaVirtualMachines/*/Contents/Home; do
    [[ -d "$jdk_home" ]] || continue
    stage_jsse_if_new "$jdk_home/lib/security/jssecacerts" "$(basename "$(dirname "$(dirname "$jdk_home")")")"
  done
  for intellij_jbr in /Applications/IntelliJ*.app/Contents/jbr/Contents/Home /Applications/IntelliJ*.app/Contents/jbr; do
    [[ -d "$intellij_jbr" ]] || continue
    stage_jsse_if_new "$intellij_jbr/lib/security/jssecacerts" "$(basename "$(dirname "$(dirname "$intellij_jbr")")")-bundled-jbr"
  done
  for staged_jsse in "$SECRETS_DIR"/certs/java-security/*/jssecacerts; do
    [[ -f "$staged_jsse" ]] || continue
    stage_jsse_if_new "$staged_jsse" "existing-secrets-encrypted-$(basename "$(dirname "$staged_jsse")")"
  done
  shopt -u nullglob
  if (( jsse_found == 0 )); then
    skip "No Java jssecacerts files found in JAVA_HOME, installed JDKs, IntelliJ JBR, or secrets-encrypted/certs/java-security"
    warn "If corporate Java TLS requires jssecacerts, locate it before reimage or obtain it from the approved company source post-image"
  else
    info "Inventory: $JAVA_JSSECACERTS_TABLE"
    warn "Restore jssecacerts only after installing Java 17 and confirming the target JAVA_HOME"
  fi

  while IFS= read -r -d '' f; do
    stage_file "certs" "$f" "$HOME/Desktop"; ok "$(basename "$f")  (from Desktop)"
    (( staged_count++ )) || true; (( cert_found++ )) || true
  done < <(find "$HOME/Desktop" -maxdepth 2 -type f \( "${CERT_PATTERN[@]}" \) -print0 2>/dev/null)
  while IFS= read -r -d '' f; do
    stage_file "certs/from-downloads" "$f" "$HOME/Downloads"; ok "$(basename "$f")  (from Downloads)"
    (( staged_count++ )) || true; (( cert_found++ )) || true
  done < <(find "$HOME/Downloads" -maxdepth 1 -type f \( "${CERT_PATTERN[@]}" \) -print0 2>/dev/null)
  if [[ -d "$SECRETS_DIR/certs" ]]; then
    before_count="$staged_count"; stage_existing_secret_tree "certs" "$SECRETS_DIR/certs"
    staged_now=$((staged_count - before_count)); (( staged_now > 0 )) && (( cert_found += staged_now )) || true
  fi
  (( cert_found == 0 )) && skip "No cert or keystore files found"
  (( cert_found > 0 )) && warn "Internal issuing-CA .pem files: after reimage double-click and set trust in Keychain Access"

  # 7. Chrome Passwords CSV
  echo ""; echo -e "${BLD}Chrome Passwords${RST}"; thin_hr
  local chrome_found=0 search_dir
  while IFS= read -r -d '' f; do
    stage_file "chrome" "$f" "$SECRETS_DIR/chrome"; ok "$(basename "$f")  (from secrets-encrypted/chrome/)"
    (( staged_count++ )) || true; (( chrome_found++ )) || true
  done < <(find "$SECRETS_DIR/chrome" -maxdepth 1 -type f -name "Chrome Passwords*.csv" -print0 2>/dev/null)
  for search_dir in "$HOME/Downloads" "$HOME/Desktop"; do
    while IFS= read -r -d '' f; do
      stage_file "chrome" "$f"; ok "$(basename "$f")  (from $(basename "$search_dir")/)"
      (( staged_count++ )) || true; (( chrome_found++ )) || true
    done < <(find "$search_dir" -maxdepth 1 -type f -name "Chrome Passwords*.csv" -print0 2>/dev/null)
  done
  (( chrome_found == 0 )) && skip "Chrome Passwords*.csv not found"
  (( chrome_found > 0 )) && warn "Delete the plaintext CSV from its original location after this DMG is verified"

  # 8. Generic sweep of remaining pre-staged categories
  echo ""; echo -e "${BLD}Additional Pre-Staged Secret Categories${RST}"; thin_hr
  local SWEEP_SKIP=":ssh:gnupg:docker:kube:certs:chrome:cli-credentials:git:package-managers:cloud:"
  local sweep_found=0 cat_path cat_name prune swept
  for cat_path in "$SECRETS_DIR"/*/; do
    [[ -d "$cat_path" ]] || continue
    cat_name="$(basename "$cat_path")"
    case "$cat_name" in staging-*) continue ;; esac
    case "$SWEEP_SKIP" in *":$cat_name:"*) continue ;; esac
    prune=""; [[ "$cat_name" == "extra-secrets-certs-review" ]] && prune="state"
    before_count="$staged_count"; stage_existing_secret_tree "$cat_name" "${cat_path%/}" "$prune"
    swept=$((staged_count - before_count)); (( swept > 0 )) && (( sweep_found += swept )) || true
  done
  (( sweep_found == 0 )) && skip "No additional pre-staged secret categories found"

  # Bail if nothing staged
  echo ""; sort -u "$MANIFEST" -o "$MANIFEST"
  if [[ ! -s "$MANIFEST" ]]; then
    err "Nothing was staged — no secrets found in expected locations."; rm -f "$MANIFEST"; exit 1
  fi

  # Staging summary
  hr; echo ""; echo -e "${BLD}Staged ${staged_count} file(s) across categories:${RST}"; echo ""
  local cat_dir count size
  for cat_dir in "$STAGING"/*/; do
    [[ -d "$cat_dir" ]] || continue
    cat_name=$(basename "$cat_dir")
    count=$(find "$cat_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
    size=$(du -sh "$cat_dir" 2>/dev/null | cut -f1)
    printf "  ${CYN}%-30s${RST}  %s file(s)  %s\n" "$cat_name/" "$count" "$size"
  done
  echo ""

  # Password prompt
  hr; echo ""
  warn "Store this password in an approved password manager before continuing."
  warn "Without it the DMG cannot be opened after the reimage."
  echo ""
  local PASS1 PASS2
  read -r -s -p "  Enter DMG encryption password: " PASS1; echo
  read -r -s -p "  Confirm DMG encryption password: " PASS2; echo; echo ""
  if [[ "$PASS1" != "$PASS2" ]]; then err "Passwords did not match."; exit 1; fi
  if [[ -z "$PASS1" ]]; then err "Empty password is not allowed."; exit 1; fi

  echo -e "${DIM}Creating AES-256 encrypted DMG…${RST}"; echo ""
  printf '%s' "$PASS1" | hdiutil create -volname "$VOLNAME" -srcfolder "$STAGING" -encryption AES-256 -stdinpass "$DMG_PATH"
  unset PASS1 PASS2

  # Restore README
  local README="$SECRETS_DIR/RESTORE-README.md"
  cat > "$README" <<README
# Secrets Restore Guide
Generated: $(date '+%Y-%m-%d %H:%M:%S')

## DMG
  $(basename "$DMG_PATH")

## Opening the DMG
  hdiutil attach -stdinpass "$DMG_PATH"
  (enter password when prompted)  # or double-click in Finder

## Restore by category
### ssh/
  cp -r /Volumes/${VOLNAME}/ssh/ ~/.ssh/ ; chmod 700 ~/.ssh ; chmod 600 ~/.ssh/id_*
### gnupg/
  cp -r /Volumes/${VOLNAME}/gnupg/ ~/.gnupg/ ; chmod 700 ~/.gnupg
  find ~/.gnupg/private-keys-v1.d -type f -exec chmod 600 {} \; ; gpg --list-secret-keys
### docker/
  cp /Volumes/${VOLNAME}/docker/config.json ~/.docker/config.json   # then: docker login
### kube/
  cp /Volumes/${VOLNAME}/kube/config ~/.kube/config ; chmod 600 ~/.kube/config
### cli-credentials/, git/, package-managers/
  Review before restoring — registry tokens, Maven/Gradle server creds, Git helper cache,
  gh config. Prefer reauthentication. (AWS/cloud not backed up — re-authenticate.)
### certs/
  internal issuing-CA .pem/.cer: double-click → Keychain Access → "Always Trust".
  java-security/*/jssecacerts: install Java 17 first, confirm target JDK, then
    sudo cp /Volumes/${VOLNAME}/certs/java-security/<source>/jssecacerts "\$JAVA_HOME/lib/security/jssecacerts"
  .keystore / *.jks: cp back; password + alias must be in an approved password manager.
### chrome/   Password Manager → Import, then delete the CSV.
### postman/  Import only after reviewing the target workspace; treat as secret-bearing.
### raycast/  Import the .rayconfig after reinstalling Raycast (password from the manager).
### intellij/ cp -r /Volumes/${VOLNAME}/intellij/ ~/Library/Application\ Support/JetBrains/ ; restart IntelliJ.
### claude/   Restore claude_desktop_config.json only if still needed; treat as secret-bearing.
### licenses/ Restore license keys/serials per each vendor's process.
### extra-secrets-certs-review/  Review inventories; import Keychain exports only when still needed.

## After restore
  hdiutil detach /Volumes/${VOLNAME}
README

  local DMG_SIZE; DMG_SIZE=$(du -sh "$DMG_PATH" 2>/dev/null | cut -f1)
  echo ""; hr; echo -e "${GRN}${BLD}Encrypted DMG created successfully.${RST}"; echo ""
  printf "  %-14s  %s\n" "DMG:" "$DMG_PATH"
  printf "  %-14s  %s\n" "Size:" "$DMG_SIZE"
  printf "  %-14s  %s\n" "Manifest:" "$MANIFEST"
  printf "  %-14s  %s\n" "README:" "$README"
  echo ""
  echo -e "${YEL}  Next: save the DMG password to an approved password manager now, then:${RST}"
  echo -e "${YEL}    ./bin/create-secrets-dmg.sh validate      # mount + check the DMG${RST}"
  echo -e "${YEL}    ./bin/create-secrets-dmg.sh cleanup       # dry-run the loose-plaintext cleanup${RST}"
  echo ""
}

# =============================================================================
# verify-staging
# =============================================================================
cmd_verify_staging() {
  REPORT_FILE="$REPORT_DIR/staging-verification-$STAMP.md"
  banner "Verify Manual Staging"

  if [[ ! -d "$SECRETS_DIR" ]]; then
    echo "ERROR: secrets-encrypted/ not found: $SECRETS_DIR" >&2
    echo "Run the earlier Phase 2 backups first." >&2
    exit 2
  fi

  report_header "Secrets Staging Verification"
  rpt "Every folder under \`secrets-encrypted/\` is reported below. \`STAGED\` means"
  rpt "real files are present; \`EMPTY\` means the folder exists (created by an earlier"
  rpt "phase) but nothing is staged — confirm you meant to skip it. Anything you staged"
  rpt "**outside** \`secrets-encrypted/\` is not visible here and must be checked by hand."
  rpt ""
  rpt "| Status | Category | Files |"
  rpt "|---|---|---|"

  local cat n empty=0 staged=0
  while IFS= read -r cat; do
    [[ -n "$cat" ]] || continue
    n="$(category_file_count "$cat")"
    if [[ "$cat" == "cloud" ]]; then
      status INFO "cloud/ present — NOT included in the DMG" "$n file(s); AWS re-auth after reimage"
      continue
    fi
    if (( n > 0 )); then
      status PASS "$cat/" "STAGED · $n file(s)"; (( staged++ )) || true
    else
      status WARN "$cat/" "EMPTY — confirm intentionally skipped"; (( empty++ )) || true
    fi
  done < <(list_categories)

  # phase2f rerun marker
  echo ""
  if find "$EXTRA_CERTS_REVIEW_DIR/state" -maxdepth 1 -type f -name 'phase2f-rerun-required-*.md' 2>/dev/null | grep -q .; then
    status INFO "phase2f-rerun-required marker present" "Phase 3A staged new cert material — a go signal for this build"
  fi

  echo ""
  info "Categories staged: $staged · empty: $empty"
  info "Custom apps you staged outside secrets-encrypted/ must be verified manually."
  {
    echo ""
    echo "## Manual — you confirm"
    echo "- [ ] Every EMPTY category above was intentionally skipped."
    echo "- [ ] Anything staged outside \`secrets-encrypted/\` (custom apps) is accounted for."
  } >> "$REPORT_FILE"
  report_footer_and_path
}

# =============================================================================
# validate
# =============================================================================
cmd_validate() {
  REPORT_FILE="$REPORT_DIR/dmg-validation-$STAMP.md"
  banner "Validate the Mounted DMG"

  local DMG MANIFEST README VOL
  DMG="$(newest_dmg)"
  if [[ -z "$DMG" || ! -f "$DMG" ]]; then
    echo "ERROR: no all-secrets-*.dmg found under $SECRETS_DIR. Build first." >&2
    exit 2
  fi
  MANIFEST="$(newest_manifest)"
  README="$SECRETS_DIR/RESTORE-README.md"

  report_header "Secrets DMG Validation"
  rpt "DMG: \`$DMG\`"
  rpt ""
  rpt "| Status | Check | Detail |"
  rpt "|---|---|---|"

  VOL="$(mount_or_reuse_dmg "$DMG")"
  if [[ -z "$VOL" || ! -d "$VOL" ]]; then
    status FAIL "DMG mounts with the saved password" "could not mount or locate /Volumes/all-secrets-*"
    report_footer_and_path
    exit 1
  fi
  status PASS "DMG mounts with the saved password" "$(basename "$VOL")"
  # Always detach on the way out, even on early exit.
  MOUNTED_VOL="$VOL"
  trap detach_mounted EXIT

  # Manifest + README presence
  [[ -n "$MANIFEST" && -s "$MANIFEST" ]] && status PASS "Manifest exists and is non-empty" "$(basename "$MANIFEST")" \
    || status WARN "Manifest missing or empty" "${MANIFEST:-none}"
  [[ -f "$README" ]] && status PASS "RESTORE-README.md exists" || status WARN "RESTORE-README.md missing"

  # Drift-proof cross-check: every loose on-disk category is inside the DMG, so
  # cleanup can safely remove it. cloud/ is expected to be absent (not backed up).
  local cat n indmg
  while IFS= read -r cat; do
    [[ -n "$cat" ]] || continue
    n="$(category_file_count "$cat")"
    (( n > 0 )) || continue
    indmg=0
    [[ -d "$VOL/$cat" ]] && indmg="$(find "$VOL/$cat" -type f ! -name '.DS_Store' 2>/dev/null | wc -l | tr -d ' ')"
    if [[ "$cat" == "cloud" ]]; then
      status INFO "cloud/ not in DMG (expected)" "kept on disk; AWS re-auth after reimage"
    elif (( indmg > 0 )); then
      status PASS "$cat/ present in DMG" "disk $n · dmg $indmg file(s)"
    else
      status FAIL "$cat/ staged on disk but NOT in DMG" "$n file(s) on disk, 0 in image — rebuild before cleanup"
    fi
  done < <(list_categories)

  # Foundational live-captured secrets (present only if this machine had them).
  if [[ -d "$VOL/gnupg/private-keys-v1.d" ]] && find "$VOL/gnupg/private-keys-v1.d" -type f 2>/dev/null | grep -q .; then
    status PASS "GPG private keys present in DMG" "gnupg/private-keys-v1.d/"
  else
    status WARN "No GPG private keys in DMG" "expected only if this machine has none"
  fi
  if [[ -d "$VOL/ssh" ]] && find "$VOL/ssh" -type f 2>/dev/null | grep -q .; then
    status PASS "SSH material present in DMG" "ssh/"
  else
    status WARN "No SSH material in DMG" "expected only if this machine has none"
  fi

  # Private-key-bearing files must live inside the image.
  local keycount
  keycount="$(find "$VOL" -type f \( -name '*.p12' -o -name '*.pfx' -o -name '*.jks' -o -name '*.keystore' -o -name '*.key' \) 2>/dev/null | wc -l | tr -d ' ')"
  status INFO "Private-key-bearing files inside the DMG" "$keycount (.p12/.pfx/.jks/.keystore/.key)"

  # PEM BEGIN/END balance for any public-certificate exports.
  local pem b e any_pem=0
  while IFS= read -r pem; do
    [[ -f "$pem" ]] || continue
    any_pem=1
    b="$(grep -c 'BEGIN CERTIFICATE' "$pem" 2>/dev/null || true)"
    e="$(grep -c 'END CERTIFICATE' "$pem" 2>/dev/null || true)"
    if [[ "$b" -gt 0 && "$b" == "$e" ]]; then
      status PASS "PEM blocks balanced" "$(basename "$pem"): $b"
    else
      status WARN "PEM blocks unbalanced" "$(basename "$pem"): begin $b / end $e"
    fi
  done < <(find "$VOL/certs/keychain-manual-exports" -type f -name 'user-public-certificates-*.pem' 2>/dev/null)
  (( any_pem == 0 )) && status INFO "No public-certificate PEM exports to check" ""

  {
    echo ""
    echo "## Manual — you confirm (a script cannot verify these)"
    echo "- [ ] The DMG password is saved in an approved password manager."
    echo "- [ ] Every category you *intended* to export is present above (intent is yours to judge)."
    echo "- [ ] Managed/non-exportable Keychain identities are documented, not silently missing."
    echo "- [ ] Java trust overrides in the DMG match the JDKs you actually need."
  } >> "$REPORT_FILE"

  report_footer_and_path
  (( FAIL_N > 0 )) && exit 1 || exit 0
}

# =============================================================================
# cleanup
# =============================================================================
cmd_cleanup() {
  REPORT_FILE="$REPORT_DIR/cleanup-$STAMP.md"
  banner "Clean Up Loose Plaintext"

  local SECRETS_ROOT="$SECRETS_DIR"
  # Safety guard: only ever operate on an absolute .../secrets-encrypted path.
  case "$SECRETS_ROOT" in
    /*/secrets-encrypted) ;;
    *) echo "ERROR: refusing cleanup, path looks unsafe: $SECRETS_ROOT" >&2; exit 2 ;;
  esac

  local DMG VOL
  DMG="$(newest_dmg)"
  if [[ -z "$DMG" || ! -f "$DMG" ]]; then
    echo "ERROR: no all-secrets-*.dmg found. Build and validate before cleanup." >&2
    exit 2
  fi

  report_header "Secrets Loose-Plaintext Cleanup"
  rpt "DMG: \`$DMG\`"
  rpt "Mode: $([[ "$FORCE" == true ]] && echo 'EXECUTE (--force)' || echo 'DRY RUN (no --force)')"
  rpt ""
  rpt "| Action | Category | Detail |"
  rpt "|---|---|---|"

  # Determine what is inside the newest DMG. Executing a delete requires the
  # password (a deliberate final gate); a dry run previews without mounting.
  local have_dmg_contents=false
  if [[ "$FORCE" == true ]]; then
    VOL="$(mount_or_reuse_dmg "$DMG")"
    if [[ -n "$VOL" && -d "$VOL" ]]; then
      have_dmg_contents=true
      MOUNTED_VOL="$VOL"
      trap detach_mounted EXIT
    else
      status FAIL "DMG mount" "could not mount or locate the volume for $(basename "$DMG") — nothing deleted"
      rpt ""
      rpt "> Mount the DMG (or eject any stale copy) and re-run \`cleanup --force\`."
      report_footer_and_path
      echo "ERROR: could not mount the DMG to confirm contents; refusing to delete." >&2
      exit 1
    fi
  fi

  dmg_has_category() {
    local cat="$1"
    [[ "$have_dmg_contents" == true ]] || return 1
    [[ -d "$VOL/$cat" ]] && find "$VOL/$cat" -type f ! -name '.DS_Store' 2>/dev/null | grep -q .
  }

  local cat n removed=0 kept=0
  while IFS= read -r cat; do
    [[ -n "$cat" ]] || continue
    n="$(category_file_count "$cat")"
    # Never touch: cloud (not backed up) or an explicit --keep.
    if [[ "$cat" == "cloud" ]]; then
      status INFO "KEEP $cat/" "not in the DMG (AWS re-auth after reimage)"; (( kept++ )) || true; continue
    fi
    case "$KEEP_LIST" in *":$cat:"*)
      status INFO "KEEP $cat/" "--keep requested"; (( kept++ )) || true; continue ;;
    esac

    # An empty category holds no secrets, so there is nothing to confirm inside
    # the DMG; remove the leftover folder rather than warn it is "not in the DMG".
    if [[ "$n" -eq 0 ]]; then
      if [[ "$FORCE" == true ]]; then
        rm -rf -- "${SECRETS_ROOT:?}/$cat"
        status PASS "REMOVED $cat/" "empty — no secrets to preserve"; (( removed++ )) || true
      else
        status INFO "WOULD REMOVE $cat/" "empty — no secrets to preserve"
      fi
      continue
    fi

    if [[ "$FORCE" != true ]]; then
      status INFO "WOULD REMOVE $cat/" "$n file(s) — pending DMG confirmation at --force"
      continue
    fi
    if dmg_has_category "$cat"; then
      rm -rf -- "${SECRETS_ROOT:?}/$cat"
      status PASS "REMOVED $cat/" "$n file(s); confirmed inside the DMG"; (( removed++ )) || true
    else
      status WARN "KEPT $cat/" "not found inside the DMG — not safe to delete"; (( kept++ )) || true
    fi
  done < <(list_categories)

  # Sweep away any leftover temp staging trees (never restore material).
  local st
  for st in "$SECRETS_ROOT"/staging-*/; do
    [[ -d "$st" ]] || continue
    if [[ "$FORCE" == true ]]; then rm -rf -- "$st"; status PASS "REMOVED $(basename "$st")/" "temp staging tree"; fi
  done

  echo ""
  if [[ "$FORCE" == true ]]; then
    info "Removed: $removed category(ies) · kept: $kept"
    echo ""; echo -e "${DIM}Remaining under secrets-encrypted/:${RST}"
    find "$SECRETS_ROOT" -maxdepth 1 -mindepth 1 2>/dev/null | sort | sed "s|$SECRETS_ROOT/|  |"
  else
    info "Dry run only — nothing deleted. Re-run with --force to mount the DMG, confirm each category, and delete."
  fi
  {
    echo ""
    echo "## Manual — you confirm"
    echo "- [ ] The DMG password is saved in an approved password manager."
    echo "- [ ] You reviewed the validation report before deleting."
    echo "- [ ] Any KEPT category (not in the DMG) is intentional."
  } >> "$REPORT_FILE"
  report_footer_and_path
}

# =============================================================================
# Dispatch
# =============================================================================
case "$SUBCMD" in
  build)          cmd_build ;;
  verify-staging) cmd_verify_staging ;;
  validate)       cmd_validate ;;
  cleanup)        cmd_cleanup ;;
  *)              echo "ERROR: unknown subcommand: $SUBCMD" >&2; usage >&2; exit 2 ;;
esac
