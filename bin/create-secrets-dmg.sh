#!/usr/bin/env bash
# =============================================================================
# create-secrets-dmg.sh
#
# Phase 2F entrypoint: build the consolidated AES-256 encrypted secrets DMG.
# Stages every credential-bearing category that should survive the reimage into
# one temporary staging tree, encrypts it into all-secrets-<stamp>.dmg, and
# writes the matching manifest, Java jssecacerts inventory, and restore README.
# Invoked by the runbook create-secrets-dmg.md (Phase 2F — Create Secrets DMG).
#
# Sources collected (each skipped when absent):
#   SSH          — ~/.ssh (private keys + config)
#   GPG          — ~/.gnupg (private keys in private-keys-v1.d/ — PERMANENT LOSS
#                  if not backed up); random_seed excluded (machine-specific)
#   Docker       — ~/.docker/config.json (auth tokens, credential helpers)
#   Kube         — ~/.kube/config (cluster credentials)
#   CLI/pkg      — ~/.netrc, ~/.git-credentials, ~/.npmrc, ~/.yarnrc(.yml),
#                  ~/.pypirc, ~/.gradle/gradle.properties, ~/.m2/settings.xml,
#                  and matching pre-staged copies under secrets-encrypted/
#                  (AWS/cloud is intentionally NOT captured — re-auth after reimage)
#   Certs        — ~/.keystore, home-root *.jks, Java jssecacerts (JAVA_HOME,
#                  installed JDKs, IntelliJ bundled JBR, prior staging), and
#                  *.pem *.p12 *.pfx *.cer *.crt *.keystore *.jks on Desktop and
#                  in Downloads, plus material staged under secrets-encrypted/certs/
#   Cert review  — artifacts written by stage-certs-keychain.sh under
#                  secrets-encrypted/extra-secrets-certs-review/ (organized into
#                  discovery/, plan/, decisions/); the whole tree is staged
#                  recursively, except the state/ control subfolder (regenerable
#                  workflow control: staging-state pointer + phase2f-rerun
#                  marker — no restore value).
#   Chrome       — Chrome Passwords*.csv from secrets-encrypted/chrome/,
#                  Downloads, or Desktop
#   IntelliJ     — HTTP Client env files (http-client.env.json /
#                  http-client.private.env.json) pre-staged into
#                  secrets-encrypted/intellij/ by backup-intellij; swept here
#   Postman      — secret-bearing exports staged under secrets-encrypted/postman/
#   Raycast      — password-protected .rayconfig or sensitive Quicklinks exports
#                  staged under secrets-encrypted/raycast/
#   Claude       — secrets-encrypted/claude/ (e.g. claude_desktop_config.json)
#   Licenses     — secrets-encrypted/licenses/ (manual license/activation staging)
#   Other        — any further pre-staged category under secrets-encrypted/ is
#                  captured by a generic sweep; cloud/ and the review state/
#                  control folder are excluded.
#
# The staging directory is wiped on exit (success or failure).
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#
#   # Default run — uses REIMAGE_ARTIFACT_ROOT from a sourced reimage.env
#   ./bin/create-secrets-dmg.sh
#
#   # Override the artifact root for this invocation
#   ./bin/create-secrets-dmg.sh \
#     --artifact-root /Volumes/<external-data-volume>/reimage-<asset-or-host>-<date>-open
#
#   # Build the DMG without rerunning the certificate/Keychain review scan first
#   ./bin/create-secrets-dmg.sh --skip-cert-review
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --skip-cert-review    Do not rerun stage-certs-keychain.sh scan before building.
#   -h, --help            Show this message and exit.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Exit status:
#   0  DMG created successfully.
#   1  Ran but hit a workflow/runtime failure (nothing staged, password mismatch).
#   2  Usage, configuration, prerequisite, or dependency error.
#
# Important:
#   Store the DMG password in an approved password manager immediately. Without
#   it the backup cannot be restored.
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
# Parse command-line options
# ---------------------------------------------------------------------------
RUN_CERT_REVIEW=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --skip-cert-review)
      RUN_CERT_REVIEW=false
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
# Resolve and validate configured paths after parsing
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
if [[ ! -f "$STAGE_CERTS_KEYCHAIN_SCRIPT" ]]; then
  echo "ERROR: certificate/Keychain staging script not found: $STAGE_CERTS_KEYCHAIN_SCRIPT" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Derived paths
# ---------------------------------------------------------------------------
STAMP="$(date +%Y%m%d-%H%M%S)"
SECRETS_DIR="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"
STAGING="$SECRETS_DIR/staging-$STAMP"
DMG_PATH="$SECRETS_DIR/all-secrets-$STAMP.dmg"
MANIFEST="$SECRETS_DIR/all-secrets-$STAMP-manifest.txt"
JAVA_JSSECACERTS_TABLE="$SECRETS_DIR/java-jssecacerts-inventory-$STAMP.md"
EXTRA_CERTS_REVIEW_DIR="$SECRETS_DIR/extra-secrets-certs-review"
VOLNAME="all-secrets-$STAMP"

# ---------------------------------------------------------------------------
# User-facing output helpers (house palette — see backup-home.sh)
# ---------------------------------------------------------------------------
RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYN='\033[0;36m'
BLD='\033[1m'
DIM='\033[2m'
RST='\033[0m'

ok()    { printf "  ${GRN}✓  %s${RST}\n" "$1" ; }
skip()  { printf "  ${DIM}–  %s  (not found, skipping)${RST}\n" "$1" ; }
warn()  { printf "  ${YEL}⚠  %s${RST}\n" "$1" ; }
err()   { printf "  ${RED}✗  %s${RST}\n" "$1" >&2 ; }
info()  { printf "  ${DIM}   %s${RST}\n" "$1" ; }

hr()      { printf '%s\n' "────────────────────────────────────────────────────────" ; }
thin_hr() { printf '%s\n' "  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄" ; }

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
echo ""
echo -e "${BLD}${CYN}╔══════════════════════════════════════════════════════╗${RST}"
echo -e "${BLD}${CYN}║        Consolidated Secrets DMG                      ║${RST}"
echo -e "${BLD}${CYN}║        $(date '+%Y-%m-%d %H:%M:%S')                        ║${RST}"
echo -e "${BLD}${CYN}╚══════════════════════════════════════════════════════╝${RST}"
echo ""
echo -e "  ${DIM}Artifact root: $REIMAGE_ARTIFACT_ROOT${RST}"
echo ""

mkdir -p "$SECRETS_DIR" "$STAGING"
: > "$MANIFEST"
{
  echo "# Java jssecacerts Inventory"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  echo "| Label | Source | SHA-256 | Size Bytes |"
  echo "|---|---|---:|---:|"
} > "$JAVA_JSSECACERTS_TABLE"

# ---------------------------------------------------------------------------
# Cleanup trap — always wipes staging
# ---------------------------------------------------------------------------
cleanup() {
  rm -rf "$STAGING"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Helper: stage a file preserving relative path under a named category
#   $1 = category dir name inside staging  $2 = source file  $3 = strip prefix
# ---------------------------------------------------------------------------
stage_file() {
  local category="$1" src="$2" strip_prefix="${3:-}"
  local rel dest_dir

  if [[ -n "$strip_prefix" ]]; then
    rel="${src#${strip_prefix}/}"
  else
    rel="$(basename "$src")"
  fi

  dest_dir="$STAGING/$category/$(dirname "$rel")"
  mkdir -p "$dest_dir"
  cp -p "$src" "$dest_dir/$(basename "$src")"
  printf '%s\n' "$src" >> "$MANIFEST"
}

# Stage corporate Java jssecacerts without assuming which JDK will be restored later.
#   $1 = source jssecacerts file  $2 = human-readable label
stage_jssecacerts() {
  local src="$1" label="$2"
  local safe_label dest_dir hash size

  [[ -f "$src" ]] || return 0
  safe_label=$(printf '%s' "$label" | sed 's/[^A-Za-z0-9_.-]/_/g')
  dest_dir="$STAGING/certs/java-security/$safe_label"
  mkdir -p "$dest_dir"
  cp -p "$src" "$dest_dir/jssecacerts"

  hash=$(shasum -a 256 "$src" 2>/dev/null | awk '{print $1}' || true)
  size=$(wc -c < "$src" 2>/dev/null | tr -d ' ' || true)

  {
    printf 'source=%s\n' "$src"
    printf 'label=%s\n' "$label"
    printf 'sha256=%s\n' "${hash:-unknown}"
    printf 'size_bytes=%s\n' "${size:-unknown}"
    printf 'captured_at=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
  } > "$dest_dir/README.txt"

  printf '| `%s` | `%s` | `%s` | `%s` |\n' \
    "$label" "$src" "${hash:-unknown}" "${size:-unknown}" >> "$JAVA_JSSECACERTS_TABLE"

  printf '%s\n' "$src" >> "$MANIFEST"
}

stage_existing_secret_tree() {
  local category="$1" src_root="$2" prune_subdir="${3:-}"
  local found=0

  [[ -d "$src_root" ]] || return 0

  # Optionally prune a direct-child subdirectory. Used for the Phase 2E
  # extra-secrets-certs-review/state/ control folder: a regenerable
  # staging-state pointer plus the phase2f-rerun marker, which are workflow
  # control with no restore value. The rerun check reads the marker off the
  # live drive, not the DMG, so leaving it out of the image is safe.
  local find_cmd
  if [[ -n "$prune_subdir" ]]; then
    find_cmd=(find "$src_root" -type d -path "$src_root/$prune_subdir" -prune -o -type f -print0)
  else
    find_cmd=(find "$src_root" -type f -print0)
  fi

  while IFS= read -r -d '' f; do
    # Avoid recursively staging generated all-secrets DMGs or manifests if someone points at secrets-encrypted itself.
    case "$(basename "$f")" in
      all-secrets-*.dmg|all-secrets-*-manifest.txt) continue ;;
    esac
    stage_file "$category" "$f" "$src_root"
    ok "${category}/$(basename "$f")"
    (( staged_count++ )) || true
    (( found++ )) || true
  done < <("${find_cmd[@]}" 2>/dev/null)

  return 0
}


staged_count=0

if [[ "$RUN_CERT_REVIEW" == "true" ]]; then
  echo ""
  echo -e "${BLD}Extra Certificate and Secrets Review${RST}"
  thin_hr
  bash "$STAGE_CERTS_KEYCHAIN_SCRIPT" scan --artifact-root "$REIMAGE_ARTIFACT_ROOT"
fi

# ════════════════════════════════════════════════════════
# 1. SSH — private keys + config
# ════════════════════════════════════════════════════════
echo -e "${BLD}SSH Keys  (~/.ssh)${RST}"
thin_hr

if [[ -d "$HOME/.ssh" ]]; then
  while IFS= read -r -d '' f; do
    stage_file "ssh" "$f" "$HOME/.ssh"
    ok "$(basename "$f")"
    (( staged_count++ )) || true
  done < <(find "$HOME/.ssh" -maxdepth 1 -type f -print0 2>/dev/null)
  # Preserve permissions in staging
  chmod 700 "$STAGING/ssh" 2>/dev/null || true
  find "$STAGING/ssh" -name "id_*" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
else
  skip "~/.ssh"
fi

# ════════════════════════════════════════════════════════
# 2. GPG keys — private-keys-v1.d/ cannot be regenerated
# ════════════════════════════════════════════════════════
echo ""
echo -e "${BLD}GPG Keys  (~/.gnupg)${RST}"
thin_hr

if [[ -d "$HOME/.gnupg" ]]; then
  gnupg_count=0
  # Stage every file except random_seed (machine-specific, not needed for restore)
  while IFS= read -r -d '' f; do
    stage_file "gnupg" "$f" "$HOME/.gnupg"
    ok "$(basename "$f")"
    (( staged_count++ )) || true
    (( gnupg_count++ )) || true
  done < <(find "$HOME/.gnupg" -type f ! -name "random_seed" -print0 2>/dev/null)

  # Lock down permissions in staging
  chmod 700 "$STAGING/gnupg" 2>/dev/null || true
  find "$STAGING/gnupg/private-keys-v1.d" -type f \
    -exec chmod 600 {} \; 2>/dev/null || true

  priv_count=$(find "$HOME/.gnupg/private-keys-v1.d" -type f 2>/dev/null | wc -l | tr -d ' ')
  info "Staged ${gnupg_count} file(s) — ${priv_count} private key(s) in private-keys-v1.d/"
  info "random_seed excluded (machine-specific; not needed for restore)"
  printf "  ${RED}⚠  GPG private keys cannot be regenerated — verify this DMG after creation${RST}\n"
else
  skip "~/.gnupg"
fi

# ════════════════════════════════════════════════════════
# 3. Docker config.json (auth tokens)
# ════════════════════════════════════════════════════════
echo ""
echo -e "${BLD}Docker  (~/.docker/config.json)${RST}"
thin_hr

DOCKER_CONFIG="$HOME/.docker/config.json"
if [[ -f "$DOCKER_CONFIG" ]]; then
  stage_file "docker" "$DOCKER_CONFIG" "$HOME/.docker"
  ok "config.json"
  info "Contains credential helpers and auth tokens — run: docker login after reimage"
  (( staged_count++ )) || true
else
  skip "~/.docker/config.json"
fi

# Also pick up any existing docker/config.json already copied to secrets-encrypted
EXISTING_DOCKER="$SECRETS_DIR/docker/config.json"
if [[ -f "$EXISTING_DOCKER" ]]; then
  # Already staged above from source; skip to avoid duplicate
  info "Note: existing secrets-encrypted/docker/config.json superseded by live source"
fi

# ════════════════════════════════════════════════════════
# 4. Kube config (cluster credentials + tokens)
# ════════════════════════════════════════════════════════
echo ""
echo -e "${BLD}Kube Config  (~/.kube/config)${RST}"
thin_hr

KUBE_CONFIG="$HOME/.kube/config"
if [[ -f "$KUBE_CONFIG" ]]; then
  stage_file "kube" "$KUBE_CONFIG" "$HOME/.kube"
  ok "config"
  info "Contains cluster API tokens and certificates"
  (( staged_count++ )) || true
else
  skip "~/.kube/config"
fi


# ════════════════════════════════════════════════════════
# 5. Common CLI, Git, package-manager, and cloud credentials
# ════════════════════════════════════════════════════════
echo ""
echo -e "${BLD}Common CLI and Package-Manager Credentials${RST}"
thin_hr

common_secret_found=0

stage_common_secret_file() {
  local category="$1" src="$2" display="$3" strip_prefix="${4:-}"
  [[ -f "$src" ]] || return 0
  stage_file "$category" "$src" "$strip_prefix"
  ok "$display"
  (( staged_count++ )) || true
  (( common_secret_found++ )) || true
}

stage_common_secret_file "cli-credentials" "$HOME/.netrc" ".netrc" "$HOME"
stage_common_secret_file "git" "$HOME/.git-credentials" ".git-credentials" "$HOME"
stage_common_secret_file "package-managers" "$HOME/.npmrc" ".npmrc" "$HOME"
stage_common_secret_file "package-managers" "$HOME/.yarnrc" ".yarnrc" "$HOME"
stage_common_secret_file "package-managers" "$HOME/.yarnrc.yml" ".yarnrc.yml" "$HOME"
stage_common_secret_file "package-managers" "$HOME/.pypirc" ".pypirc" "$HOME"
stage_common_secret_file "package-managers" "$HOME/.gradle/gradle.properties" "gradle.properties" "$HOME/.gradle"
stage_common_secret_file "package-managers" "$HOME/.m2/settings.xml" "maven settings.xml" "$HOME/.m2"

# AWS/cloud credentials are intentionally not captured — the reimage workflow
# re-authenticates cloud CLIs after rebuild rather than restoring ~/.aws.

# Also include pre-staged copies written by backup-home.sh (e.g. cli-credentials/gh/).
for staged_secret_dir in \
  "$SECRETS_DIR/cli-credentials" \
  "$SECRETS_DIR/git" \
  "$SECRETS_DIR/package-managers"; do
  [[ -d "$staged_secret_dir" ]] || continue
  category="$(basename "$staged_secret_dir")"
  before_count="$staged_count"
  stage_existing_secret_tree "$category" "$staged_secret_dir"
  staged_now=$((staged_count - before_count))
  (( staged_now > 0 )) && (( common_secret_found += staged_now )) || true
done

(( common_secret_found == 0 )) && skip "No .netrc, Git credential cache, or package-manager credential files found"

# ════════════════════════════════════════════════════════
# 6. Certificates and keystores
#    Sources checked in order:
#      a) ~/.keystore           — personal Java KeyStore at home root
#      b) Java jssecacerts      — JAVA_HOME, installed JDKs, IntelliJ bundled JBR, prior staging
#      c) ~/Desktop             — cert files dropped here for backup
#      d) ~/Downloads           — stray certs from downloads
# ════════════════════════════════════════════════════════
echo ""
echo -e "${BLD}Certificates and Keystores${RST}"
thin_hr

# Shared find pattern — used for Desktop and Downloads certificate scans
CERT_PATTERN=( \
  -name "*.pem" \
  -o -name "*.p12" \
  -o -name "*.pfx" \
  -o -name "*.cer" \
  -o -name "*.crt" \
  -o -name "*.keystore" \
  -o -name "*.jks" \
)

cert_found=0

# ── a) ~/.keystore at home root ───────────────────────────────────────────────
if [[ -f "$HOME/.keystore" ]]; then
  stage_file "certs" "$HOME/.keystore" "$HOME"
  ok ".keystore  (from ~/)"
  info "Java KeyStore — store password and key alias in an approved password manager"
  warn ".keystore password and key alias must be in an approved password manager to restore this file"
  (( staged_count++ )) || true
  (( cert_found++ )) || true
else
  skip "~/.keystore  (not found)"
fi

# Also check for any other *.keystore or *.jks at home root (not in subdirs)
while IFS= read -r -d '' f; do
  [[ "$(basename "$f")" == ".keystore" ]] && continue   # already handled above
  stage_file "certs" "$f" "$HOME"
  ok "$(basename "$f")  (from ~/)"
  info "Java KeyStore — store password and key alias in an approved password manager"
  (( staged_count++ )) || true
  (( cert_found++ )) || true
done < <(find "$HOME" -maxdepth 1 -type f \
    \( -name "*.jks" \) \
    -print0 2>/dev/null)

# ── b) Java jssecacerts from active and installed JDKs ──────────────────────────
echo ""
echo -e "${BLD}Java jssecacerts${RST}"
thin_hr

jsse_found=0
seen_jsse_files=":"

stage_jsse_if_new() {
  local f="$1" label="$2"
  [[ -f "$f" ]] || return 0
  case "$seen_jsse_files" in
    *:"$f":*) return 0 ;;
  esac
  seen_jsse_files="${seen_jsse_files}${f}:"
  stage_jssecacerts "$f" "$label"
  ok "$label  →  certs/java-security/"
  (( staged_count++ )) || true
  (( cert_found++ )) || true
  (( jsse_found++ )) || true
}

if [[ -n "${JAVA_HOME:-}" ]]; then
  stage_jsse_if_new "$JAVA_HOME/lib/security/jssecacerts" "JAVA_HOME-$(basename "$JAVA_HOME")"
fi

shopt -s nullglob
for jdk_home in /Library/Java/JavaVirtualMachines/*/Contents/Home; do
  [[ -d "$jdk_home" ]] || continue
  stage_jsse_if_new "$jdk_home/lib/security/jssecacerts" "$(basename "$(dirname "$(dirname "$jdk_home")")")"
done

for intellij_jbr in /Applications/IntelliJ*.app/Contents/jbr/Contents/Home /Applications/IntelliJ*.app/Contents/jbr; do
  [[ -d "$intellij_jbr" ]] || continue
  stage_jsse_if_new "$intellij_jbr/lib/security/jssecacerts" "$(basename "$(dirname "$(dirname "$intellij_jbr")")")-bundled-jbr"
done

for staged_jsse in "$SECRETS_DIR"/certs/java-security/*/jssecacerts "$SECRETS_DIR"/java-security/*/jssecacerts; do
  [[ -f "$staged_jsse" ]] || continue
  if [[ "$staged_jsse" == "$SECRETS_DIR"/java-security/* ]]; then
    stage_jsse_if_new "$staged_jsse" "legacy-secrets-encrypted-$(basename "$(dirname "$staged_jsse")")"
  else
    stage_jsse_if_new "$staged_jsse" "existing-secrets-encrypted-$(basename "$(dirname "$staged_jsse")")"
  fi
done
shopt -u nullglob

if (( jsse_found == 0 )); then
  skip "No Java jssecacerts files found in JAVA_HOME, /Library/Java/JavaVirtualMachines, IntelliJ JBR, secrets-encrypted/certs/java-security, or legacy secrets-encrypted/java-security"
  warn "If corporate Java TLS requires jssecacerts, locate it before reimage or obtain it from the approved company source post-image"
else
  info "Inventory: $JAVA_JSSECACERTS_TABLE"
  warn "Restore jssecacerts only after installing Java 17 and confirming the target JAVA_HOME"
fi

# ── c) Desktop cert files ─────────────────────────────────────────────────────
while IFS= read -r -d '' f; do
  stage_file "certs" "$f" "$HOME/Desktop"
  ok "$(basename "$f")  (from Desktop)"
  (( staged_count++ )) || true
  (( cert_found++ )) || true
done < <(find "$HOME/Desktop" -maxdepth 2 -type f \
    \( "${CERT_PATTERN[@]}" \) \
    -print0 2>/dev/null)

# ── d) Downloads stray certs ──────────────────────────────────────────────────
while IFS= read -r -d '' f; do
  stage_file "certs/from-downloads" "$f" "$HOME/Downloads"
  ok "$(basename "$f")  (from Downloads)"
  (( staged_count++ )) || true
  (( cert_found++ )) || true
done < <(find "$HOME/Downloads" -maxdepth 1 -type f \
    \( "${CERT_PATTERN[@]}" \) \
    -print0 2>/dev/null)

# ── e) Existing cert material manually staged under secrets-encrypted/certs ───
if [[ -d "$SECRETS_DIR/certs" ]]; then
  before_count="$staged_count"
  stage_existing_secret_tree "certs" "$SECRETS_DIR/certs"
  staged_now=$((staged_count - before_count))
  if (( staged_now > 0 )); then
    (( cert_found += staged_now )) || true
  fi
fi

(( cert_found == 0 )) && skip "No cert or keystore files found"

if (( cert_found > 0 )); then
  warn "Internal issuing-CA .pem files: after reimage double-click and set trust in Keychain Access"
fi

# ════════════════════════════════════════════════════════
# 7. Chrome Passwords CSV
# ════════════════════════════════════════════════════════
echo ""
echo -e "${BLD}Chrome Passwords${RST}"
thin_hr

chrome_found=0

# Pick up an already-staged export under secrets-encrypted/chrome/ first
while IFS= read -r -d '' f; do
  stage_file "chrome" "$f" "$SECRETS_DIR/chrome"
  ok "$(basename "$f")  (from secrets-encrypted/chrome/)"
  (( staged_count++ )) || true
  (( chrome_found++ )) || true
done < <(find "$SECRETS_DIR/chrome" -maxdepth 1 -type f -name "Chrome Passwords*.csv" -print0 2>/dev/null)

# Also check Downloads and Desktop in case export was done there
for search_dir in "$HOME/Downloads" "$HOME/Desktop"; do
  while IFS= read -r -d '' f; do
    stage_file "chrome" "$f"
    ok "$(basename "$f")  (from $(basename "$search_dir")/)"
    (( staged_count++ )) || true
    (( chrome_found++ )) || true
  done < <(find "$search_dir" -maxdepth 1 -type f -name "Chrome Passwords*.csv" -print0 2>/dev/null)
done

(( chrome_found == 0 )) && skip "Chrome Passwords*.csv not found"

if (( chrome_found > 0 )); then
  warn "Delete the plaintext CSV from its original location after this DMG is verified"
fi

# ════════════════════════════════════════════════════════
# 8. Generic sweep of remaining pre-staged secret categories
#    Packages every subfolder already staged under secrets-encrypted/ that the
#    live-source sections above do not own — claude/, intellij/, licenses/,
#    postman/, raycast/, extra-secrets-certs-review/, and any category added
#    later — so a new category is captured without editing this script. IntelliJ
#    HTTP Client env files are routed here by backup-intellij (after its
#    shared-vs-private split review); this step only packages them. cloud/ is
#    excluded (AWS re-auth after reimage); the review dir's state/ control folder
#    and this run's staging-* tree are excluded too.
# ════════════════════════════════════════════════════════
echo ""
echo -e "${BLD}Additional Pre-Staged Secret Categories${RST}"
thin_hr

# Categories captured by the live-source sections above, or intentionally dropped.
SWEEP_SKIP=":ssh:gnupg:docker:kube:certs:chrome:cli-credentials:git:package-managers:cloud:"

sweep_found=0
for cat_path in "$SECRETS_DIR"/*/; do
  [[ -d "$cat_path" ]] || continue
  cat_name="$(basename "$cat_path")"
  case "$cat_name" in
    staging-*) continue ;;                       # this run's temp staging tree
  esac
  case "$SWEEP_SKIP" in
    *":$cat_name:"*) continue ;;
  esac
  prune=""
  # Exclude the review dir's regenerable state/ control folder from the DMG.
  [[ "$cat_name" == "extra-secrets-certs-review" ]] && prune="state"
  before_count="$staged_count"
  stage_existing_secret_tree "$cat_name" "${cat_path%/}" "$prune"
  swept=$((staged_count - before_count))
  (( swept > 0 )) && (( sweep_found += swept )) || true
done

(( sweep_found == 0 )) && skip "No additional pre-staged secret categories found"

# ════════════════════════════════════════════════════════
# Bail if nothing was staged
# ════════════════════════════════════════════════════════
echo ""
sort -u "$MANIFEST" -o "$MANIFEST"

if [[ ! -s "$MANIFEST" ]]; then
  err "Nothing was staged — no secrets found in expected locations."
  rm -f "$MANIFEST"
  exit 1
fi

# ════════════════════════════════════════════════════════
# Staging summary before password prompt
# ════════════════════════════════════════════════════════
hr
echo ""
echo -e "${BLD}Staged ${staged_count} file(s) across categories:${RST}"
echo ""
for cat_dir in "$STAGING"/*/; do
  [[ -d "$cat_dir" ]] || continue
  cat_name=$(basename "$cat_dir")
  count=$(find "$cat_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  size=$(du -sh "$cat_dir" 2>/dev/null | cut -f1)
  printf "  ${CYN}%-30s${RST}  %s file(s)  %s\n" "$cat_name/" "$count" "$size"
done
echo ""
echo -e "${DIM}Staging tree:${RST}"
find "$STAGING" -not -name '.DS_Store' 2>/dev/null | sort | \
  sed "s|$STAGING||" | \
  awk 'NF>0 {
    n=split($0,a,"/"); indent=""
    for(i=2;i<n;i++) indent=indent"  "
    print "  " indent "├── " a[n]
  }'
echo ""

# ════════════════════════════════════════════════════════
# Password prompt
# ════════════════════════════════════════════════════════
hr
echo ""
warn "Store this password in an approved password manager before continuing."
warn "Without it the DMG cannot be opened after the reimage."
echo ""

read -r -s -p "  Enter DMG encryption password: " PASS1
echo
read -r -s -p "  Confirm DMG encryption password: " PASS2
echo
echo ""

if [[ "$PASS1" != "$PASS2" ]]; then
  err "Passwords did not match."
  exit 1
fi

if [[ -z "$PASS1" ]]; then
  err "Empty password is not allowed."
  exit 1
fi

# ════════════════════════════════════════════════════════
# Create encrypted DMG
# ════════════════════════════════════════════════════════
echo -e "${DIM}Creating AES-256 encrypted DMG…${RST}"
echo ""

printf '%s' "$PASS1" | hdiutil create \
  -volname "$VOLNAME" \
  -srcfolder "$STAGING" \
  -encryption AES-256 \
  -stdinpass \
  "$DMG_PATH"

unset PASS1 PASS2

# ════════════════════════════════════════════════════════
# Write restore README inside secrets-encrypted/
# ════════════════════════════════════════════════════════
README="$SECRETS_DIR/RESTORE-README.md"
cat > "$README" <<README
# Secrets Restore Guide
Generated: $(date '+%Y-%m-%d %H:%M:%S')

## DMG
  $(basename "$DMG_PATH")

## Opening the DMG
  hdiutil attach -stdinpass "$DMG_PATH"
  (enter password when prompted)
  # or double-click in Finder

## Restore by category

### ssh/
  cp -r /Volumes/${VOLNAME}/ssh/ ~/.ssh/
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_*

### gnupg/
  cp -r /Volumes/${VOLNAME}/gnupg/ ~/.gnupg/
  chmod 700 ~/.gnupg
  find ~/.gnupg/private-keys-v1.d -type f -exec chmod 600 {} \;
  # Verify keys imported correctly:
  gpg --list-secret-keys

### docker/
  cp /Volumes/${VOLNAME}/docker/config.json ~/.docker/config.json
  # Then run: docker login   to refresh auth tokens

### kube/
  cp /Volumes/${VOLNAME}/kube/config ~/.kube/config
  chmod 600 ~/.kube/config

### cli-credentials/, git/, package-managers/
  Review these files before restoring. They may contain package registry tokens, Maven/Gradle server credentials, Git credential-helper cache entries, GitHub CLI (gh) config, or other machine-specific authentication state. Prefer reauthentication after reimage when possible. (AWS/cloud CLI credentials are not backed up here — re-authenticate after reimage.)

### certs/
  internal issuing-CA .pem/.cer:
    Double-click → Keychain Access → set trust to "Always Trust"
  java-security/*/jssecacerts:
    # Install Java 17 first, then confirm the target JDK before restoring.
    /usr/libexec/java_home -V
    export JAVA_HOME="\$(/usr/libexec/java_home -v 17)"
    ls -la "\$JAVA_HOME/lib/security"
    sudo cp /Volumes/${VOLNAME}/certs/java-security/<chosen-source>/jssecacerts "\$JAVA_HOME/lib/security/jssecacerts"
    sudo chmod 644 "\$JAVA_HOME/lib/security/jssecacerts"
    # Validate with internal Maven/Gradle/HTTPS calls.
  .keystore / *.jks:
    cp /Volumes/${VOLNAME}/certs/.keystore ~/
    # Password and key alias must be in an approved password manager — run: keytool -list -keystore ~/.keystore
  Other certs: install per issuer instructions

### chrome/
  - Open Chrome → Settings → Autofill → Password Manager → Import
  - Delete the CSV immediately after import

### postman/
  - Import collections/environments only after reviewing the target workspace.
  - Treat environment exports and vault exports as secret-bearing.

### raycast/
  - Import the .rayconfig from Raycast after reinstalling Raycast.
  - Use the export password saved in an approved password manager.

### extra-secrets-certs-review/
  - Review inventories for missed cert/key/truststore files.
  - Import any manual Keychain .p12/.pfx/.cer/.pem exports only when still needed.

### intellij/
  cp -r /Volumes/${VOLNAME}/intellij/ \
    ~/Library/Application\ Support/JetBrains/
  Restart IntelliJ — HTTP Client will pick up env files automatically

### claude/
  - Restore claude_desktop_config.json to its app config location only if still needed.
  - Treat it as secret-bearing (may hold API keys / MCP server credentials); prefer re-adding secrets fresh.

### licenses/
  - Manual license keys, serials, and activation exports. Restore per each vendor's process.

## After restore
  hdiutil detach /Volumes/${VOLNAME}
README

# ════════════════════════════════════════════════════════
# Summary
# ════════════════════════════════════════════════════════
DMG_SIZE=$(du -sh "$DMG_PATH" 2>/dev/null | cut -f1)

echo ""
hr
echo -e "${GRN}${BLD}Encrypted DMG created successfully.${RST}"
echo ""
printf "  %-20s  %s\n"  "DMG:"       "$DMG_PATH"
printf "  %-20s  %s\n"  "Size:"      "$DMG_SIZE"
printf "  %-20s  %s\n"  "Manifest:"  "$MANIFEST"
printf "  %-20s  %s\n"  "README:"    "$README"
echo ""
echo -e "${YEL}  Next steps:${RST}"
echo -e "${YEL}  1. Save the DMG password to an approved password manager right now.${RST}"
echo -e "${YEL}  2. Verify the DMG opens and gnupg/private-keys-v1.d/ is present: double-click in Finder.${RST}"
echo -e "${YEL}     If Java jssecacerts was captured, verify certs/java-security/*/jssecacerts is present.${RST}"
echo -e "${YEL}     If manual Keychain exports were staged, verify certs/keychain-manual-exports/ is present.${RST}"
echo -e "${YEL}     If Postman or Raycast secret exports were staged, verify postman/ and raycast/ are present.${RST}"
echo -e "${YEL}  3. Delete loose plaintext files that are now inside the DMG:${RST}"
echo -e "${YEL}     - Internal issuing-CA .pem on ~/Desktop  (backed up in certs/)${RST}"
echo -e "${YEL}     - Any Chrome Passwords*.csv on Desktop or Downloads${RST}"
echo -e "${YEL}     - secrets-encrypted/docker/  (if it existed before this run)${RST}"
echo -e "${YEL}     - secrets-encrypted/ssh/      (if it existed before this run)${RST}"
echo -e "${YEL}     - secrets-encrypted/gnupg/    (if it existed before this run)${RST}"
echo -e "${YEL}  4. Verify the DMG opens: double-click it in Finder.${RST}"
echo ""
