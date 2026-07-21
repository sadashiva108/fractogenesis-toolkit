#!/usr/bin/env bash
# =============================================================================
# backup-docker-settings.sh
#
# Internal helper for bin/backup-apps.sh. Backs up Docker Desktop settings,
# daemon config, CLI config, and produces image/container inventories for
# reference after reimage. Does NOT back up Docker.raw -- rebuild images from
# registries/Dockerfiles.
#
# This file is intended for .internal/apps/. Shared config is intentionally
# NOT loaded by default when a destination is passed explicitly -- see below.
#
# Typical usage (through the entrypoint):
#   ./bin/backup-apps.sh
#   ./bin/backup-apps.sh --docker-only
#
# Advanced direct usage:
#   ./.internal/apps/backup-docker-settings.sh
#       # writes to $REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker when
#       # REIMAGE_ARTIFACT_ROOT is set
#   ./.internal/apps/backup-docker-settings.sh /Volumes/Data/mybackup
#       # writes non-secret files to the given directory instead
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Locate repository and load shared reimage config
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_LOADER="$(dirname "$SCRIPT_DIR")/load-reimage-config.sh"
if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi
# shellcheck source=../load-reimage-config.sh
source "$CONFIG_LOADER"
# ─────────────────────────────────────────────────────────────────────────────

# ── Destination ───────────────────────────────────────────────────────────────
_default_dest="${REIMAGE_ARTIFACT_ROOT:+${REIMAGE_ARTIFACT_ROOT}/app-settings-backup/docker}"
DEST="${1:-${_default_dest:-./docker-settings-backup-$(date +%Y%m%d)}}"
SECRET_DEST="${REIMAGE_ARTIFACT_ROOT:+${REIMAGE_ARTIFACT_ROOT}/secrets-encrypted/docker}"
unset _default_dest

# ── Colors ────────────────────────────────────────────────────────────────────
GRN='\033[0;32m'
YEL='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
BLD='\033[1m'
RST='\033[0m'

ok()   { printf "  ${GRN}✓  %-45s${RST}\n" "$1" ; }
skip() { printf "  ${YEL}–  %-45s  (not found, skipping)${RST}\n" "$1" ; }
fail() { printf "  ${RED}✗  %-45s  $2${RST}\n" "$1" ; }
info() { printf "  ${DIM}   %s${RST}\n" "$1" ; }

# ── Setup ─────────────────────────────────────────────────────────────────────
mkdir -p "$DEST"
if [[ -n "$SECRET_DEST" ]]; then
  mkdir -p "$SECRET_DEST"
fi

echo ""
echo -e "${BLD}Docker Settings Backup${RST}  —  $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${DIM}Destination: ${DEST}${RST}"
echo "────────────────────────────────────────────────────────"

# ── 1. Docker Desktop settings (CPU, RAM, disk limits, features, WSL config) ──
echo ""
echo -e "${BLD}Docker Desktop Settings${RST}"

DD_SETTINGS="$HOME/Library/Group Containers/group.com.docker/settings-store.json"
if [[ -f "$DD_SETTINGS" ]]; then
  cp "$DD_SETTINGS" "$DEST/settings-store.json"
  ok "settings-store.json"
  info "Contains: CPU/RAM/disk limits, VirtioFS, WSL2, extensions, feature flags"
else
  skip "settings-store.json"
fi

# ── 2. daemon.json (registry mirrors, log drivers, insecure registries) ───────
echo ""
echo -e "${BLD}Daemon Config${RST}"

DAEMON_JSON="$HOME/.docker/daemon.json"
if [[ -f "$DAEMON_JSON" ]]; then
  cp "$DAEMON_JSON" "$DEST/daemon.json"
  ok "daemon.json"
  info "Contains: registry mirrors, log driver, insecure registries, DNS"
else
  skip "daemon.json"
  info "Default config in use — Docker will recreate on first run"
fi

# ── 3. config.json (credential helpers, default context, HTTP headers) ────────
echo ""
echo -e "${BLD}CLI Config${RST}"

CLI_CONFIG="$HOME/.docker/config.json"
if [[ -f "$CLI_CONFIG" ]]; then
  if [[ -n "$SECRET_DEST" ]]; then
    cp "$CLI_CONFIG" "$SECRET_DEST/config.json"
    ok "secrets-encrypted/docker/config.json"
    info "Contains: credential helpers, auths, default context, HTTP proxy headers"
  else
    cp "$CLI_CONFIG" "$DEST/config.json"
    ok "config.json"
    info "Contains: credential helpers, auths, default context, HTTP proxy headers"
    echo ""
    echo -e "  ${YEL}⚠  config.json may contain auth tokens.${RST}"
    echo -e "  ${YEL}   Prefer a REIMAGE_ARTIFACT_ROOT-based run so it lands under secrets-encrypted/docker/.${RST}"
  fi
  echo ""
  echo -e "  ${YEL}⚠  config.json may contain auth tokens.${RST}"
  echo -e "  ${YEL}   After reimage run: docker login to regenerate credentials as needed.${RST}"
else
  skip "config.json"
fi

# ── 4. contexts (named Docker contexts for remote hosts, k8s, etc.) ───────────
echo ""
echo -e "${BLD}Docker Contexts${RST}"

CONTEXTS_DIR="$HOME/.docker/contexts"
if [[ -d "$CONTEXTS_DIR" ]]; then
  cp -r "$CONTEXTS_DIR" "$DEST/contexts"
  ctx_count=$(find "$DEST/contexts" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')
  ok "contexts/  (${ctx_count} context file(s))"
  info "Contains: named contexts for remote Docker hosts, Kubernetes endpoints"
else
  skip "contexts/"
  info "Only default context in use"
fi

# ── 5. Image inventory ────────────────────────────────────────────────────────
echo ""
echo -e "${BLD}Image & Container Inventory${RST}"

if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
  docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}" \
    > "$DEST/image-inventory.txt"
  img_count=$(docker images -q | wc -l | tr -d ' ')
  ok "image-inventory.txt  (${img_count} image(s))"

  docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" \
    > "$DEST/container-inventory.txt"
  ctr_count=$(docker ps -aq | wc -l | tr -d ' ')
  ok "container-inventory.txt  (${ctr_count} container(s))"

  # Compose projects if available
  if docker compose version &>/dev/null 2>&1; then
    docker compose ls 2>/dev/null > "$DEST/compose-projects.txt" || true
    ok "compose-projects.txt"
  fi
else
  skip "image-inventory.txt  (Docker not running)"
  skip "container-inventory.txt  (Docker not running)"
  info "Start Docker Desktop and re-run to capture inventories"
fi

# ── 6. Summary manifest ───────────────────────────────────────────────────────
echo ""
echo -e "${BLD}Writing manifest…${RST}"

{
  echo "# Docker Settings Backup Manifest"
  echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "# Host: $(hostname)"
  echo "# macOS: $(sw_vers -productVersion 2>/dev/null || echo unknown)"
  if command -v docker &>/dev/null; then
    echo "# Docker Desktop: $(docker version --format '{{.Server.Version}}' 2>/dev/null || echo 'not running')"
  fi
  echo ""
  echo "## Files"
  find "$DEST" -maxdepth 2 ! -name 'MANIFEST.md' | sort | while read -r f; do
    [[ -f "$f" ]] && echo "- $(basename "$f")  ($(du -sh "$f" 2>/dev/null | cut -f1))"
  done
  echo ""
  echo "## Restore Notes"
  echo "1. Install Docker Desktop via Company Portal or docker.com"
  echo "2. Copy settings-store.json -> ~/Library/Group Containers/group.com.docker/"
  echo "3. Copy daemon.json -> ~/.docker/daemon.json"
  if [[ -n "$SECRET_DEST" ]]; then
    echo "4. Restore config.json from $SECRET_DEST/config.json -> ~/.docker/config.json  (then run: docker login as needed)"
  else
    echo "4. Copy config.json -> ~/.docker/config.json  (then run: docker login as needed)"
  fi
  echo "5. Copy contexts/ -> ~/.docker/contexts/"
  echo "6. Start Docker Desktop — settings will be applied on launch"
  echo "7. Re-pull images from registries using image-inventory.txt as reference"
  echo ""
  echo "## What Was NOT Backed Up (intentionally)"
  echo "- Docker.raw  — virtual disk with images/containers (rebuild from registries)"
  echo "- Volumes     — rebuild from your docker-compose files or repos"
} > "$DEST/MANIFEST.md"
ok "MANIFEST.md"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────"
total_size=$(du -sh "$DEST" 2>/dev/null | cut -f1)
echo -e "${GRN}${BLD}Done.${RST}  Backup written to: ${BLD}${DEST}${RST}  (${total_size})"
if [[ -n "$SECRET_DEST" && -f "$SECRET_DEST/config.json" ]]; then
  echo -e "${DIM}Secret staging: ${SECRET_DEST}/config.json${RST}"
fi
echo ""
if [[ -n "$SECRET_DEST" ]]; then
  echo -e "${YEL}Next step: rerun the consolidated secrets DMG workflow after reviewing staged Docker credentials.${RST}"
else
  echo -e "${YEL}Next step: move config.json into secrets-encrypted/docker/ on your external drive.${RST}"
fi
echo ""
