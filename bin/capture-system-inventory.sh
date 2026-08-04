#!/usr/bin/env bash
# =============================================================================
# capture-system-inventory.sh
#
# Read-only system inventory capture (Phase 3B pre-image / Phase 11B
# post-image): a one-pass record of how this Mac is configured — hardware and
# macOS, disk and display, installed apps, Homebrew (with a Brewfile dump),
# shell and dotfiles, Git, the language runtimes (Python, Java, Node), Docker,
# network and SSH, cloud paths, redacted environment clues, and certificate
# pointers. Writes a timestamped bundle under system-inventory/ holding the 16
# numbered section files, MANIFEST.txt, the Brewfile, and a dotfiles/ snapshot.
# It observes and records — the only things it writes are into the bundle. See
# capture-system-inventory.md for the full runbook.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/capture-system-inventory.sh
#
#   # Default -- pre-image bundle under system-inventory/pre-image-<stamp>/
#   ./bin/capture-system-inventory.sh
#
#   # Post-image bundle (Phase 11B)
#   ./bin/capture-system-inventory.sh --context post-image
#
#   # Override the artifact root for this invocation
#   ./bin/capture-system-inventory.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Write to an exact output directory (skips the system-inventory/<context>-<stamp> layout)
#   ./bin/capture-system-inventory.sh --output /absolute/path/to/output
#
#   # Capture only one section, updating the latest bundle of this context
#   ./bin/capture-system-inventory.sh --section docker
#
#   # Capture only one section into a fresh timestamped bundle
#   ./bin/capture-system-inventory.sh --section docker --new-bundle
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --context LABEL       pre-image | post-image | pre-image-<label> | post-image-<label>.
#                         Prefix for the timestamped run directory. Default: pre-image.
#   --output DIR          Exact output directory for generated files.
#   --section NAME        Capture only one section. One of: hardware, macos, disk,
#                         display, apps, homebrew, shell, git, python, java, node,
#                         docker, network, cloud, env, certs. Default: all. By
#                         default a single-section run updates the latest existing
#                         bundle of the same --context (overwriting just that one
#                         section file); pass --new-bundle to force a fresh bundle.
#   --new-bundle          With --section, force a fresh timestamped bundle instead
#                         of updating the latest one. Default: off.
#   -h, --help            Show this message and exit.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Exit status:
#   0  Capture completed successfully.
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

ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

STAMP="$(date +%Y%m%d-%H%M%S)"
CONTEXT="pre-image"
OUTPUT_DIR=""
SECTION_FILTER=""   # empty = all sections
NEW_BUNDLE=false    # with --section, force a fresh bundle instead of updating latest
UPDATED_EXISTING=false   # set true when a --section run updates an existing bundle

# Gate for --section: true when no filter is set, or when the filter matches
# this section's keyword. Wraps each section block without altering its body.
want() { [[ -z "$SECTION_FILTER" || "$SECTION_FILTER" == "$1" ]]; }

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
    --context)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "ERROR: --context requires a value." >&2
        usage >&2
        exit 2
      fi
      CONTEXT="$2"
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
    --section)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "ERROR: --section requires a value." >&2
        usage >&2
        exit 2
      fi
      SECTION_FILTER="$2"
      shift 2
      ;;
    --new-bundle)
      NEW_BUNDLE=true
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

# Validate the run-directory context, consistent with capture-managed-inventory.sh.
case "$CONTEXT" in
  pre-image|post-image|pre-image-?*|post-image-?*)
    case "$CONTEXT" in
      *[/\\]*|*..*|.*|*[[:space:]]*)
        echo "ERROR: --context must not contain slashes, '..', a leading dot, or whitespace, got: $CONTEXT" >&2
        exit 2
        ;;
    esac
    ;;
  *)
    echo "ERROR: --context must be pre-image, post-image, or start with pre-image- or post-image- (e.g. post-image-recheck), got: $CONTEXT" >&2
    exit 2
    ;;
esac

# Validate the section filter against the fixed 01-16 keyword set.
if [[ -n "$SECTION_FILTER" ]]; then
  case "$SECTION_FILTER" in
    hardware|macos|disk|display|apps|homebrew|shell|git|python|java|node|docker|network|cloud|env|certs)
      ;;
    *)
      echo "ERROR: --section must be one of: hardware, macos, disk, display, apps, homebrew, shell, git, python, java, node, docker, network, cloud, env, certs (got: $SECTION_FILTER)" >&2
      exit 2
      ;;
  esac
fi

# Resolve the output directory. --output overrides the standard layout entirely.
if [[ -z "$OUTPUT_DIR" ]]; then
  if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set." >&2
    echo "Create/source reimage.env or pass --artifact-root PATH (or --output DIR)." >&2
    exit 2
  fi
  if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
    echo "ERROR: artifact root not found: $REIMAGE_ARTIFACT_ROOT" >&2
    exit 2
  fi

  if [[ -n "$SECTION_FILTER" && "$NEW_BUNDLE" != true ]]; then
    # Default single-section behavior: update the latest bundle of this context
    # rather than spawning a new one. The `|| true` and `head -1` keep the glob
    # safe under set -euo pipefail when no bundle matches.
    LATEST_BUNDLE="$(ls -dt "$REIMAGE_ARTIFACT_ROOT/system-inventory/${CONTEXT}-"*/ 2>/dev/null | head -1 || true)"
    if [[ -n "$LATEST_BUNDLE" ]]; then
      OUTPUT_DIR="${LATEST_BUNDLE%/}"
      UPDATED_EXISTING=true
    else
      echo "Note: no existing ${CONTEXT} bundle found; creating a new one." >&2
      OUTPUT_DIR="$REIMAGE_ARTIFACT_ROOT/system-inventory/${CONTEXT}-${STAMP}"
    fi
  else
    OUTPUT_DIR="$REIMAGE_ARTIFACT_ROOT/system-inventory/${CONTEXT}-${STAMP}"
  fi
fi

OUT="$OUTPUT_DIR"
mkdir -p "$OUT"

echo ""
echo "============================================="
echo " Mac System Inventory Capture"
echo " Output → $OUT"
echo "============================================="
echo ""

# ---------------------------------------------------------------------------
# safe_run <seconds> <command...>
# Runs a command with a wall-clock timeout using a background job.
# macOS ships 'timeout' only if GNU coreutils is installed via Homebrew.
# This avoids that dependency entirely.
# ---------------------------------------------------------------------------
safe_run() {
  local secs="$1"
  shift
  "$@" &
  local pid=$!
  local elapsed=0
  while kill -0 "$pid" 2>/dev/null; do
    sleep 1
    elapsed=$((elapsed + 1))
    if [[ $elapsed -ge $secs ]]; then
      kill "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
      echo "(timed out after ${secs}s: $*)"
      return 1
    fi
  done
  wait "$pid"
}

# ---------------------------------------------------------------------------
# section <display-name> <output-file>
# Call immediately before the section body. Output (stdout + stderr) is
# redirected to the file. Never aborts on error.
# ---------------------------------------------------------------------------
section() {
  local name="$1"
  local file="$2"
  echo "▶  $name ..."
  _SECTION_NAME="$name"
  _SECTION_FILE="$OUT/$file"
  {
    echo "# $name"
    echo "# Generated: $(date)"
    echo "# ============================================="
    echo ""
  } > "$_SECTION_FILE"
}

end_section() {
  echo "" >> "$_SECTION_FILE"
  echo "   ✓ saved → $(basename "$OUT")/$(basename "$_SECTION_FILE")"
}

# Append stdout+stderr of a command to the current section file
r() { "$@" >> "$_SECTION_FILE" 2>&1 || true; }
# Print a header line into the current section file
h() { echo "$1" >> "$_SECTION_FILE"; }

# ---------------------------------------------------------------------------
# 01 — Hardware
# ---------------------------------------------------------------------------
if want hardware; then
section "Hardware — Mac model, chip, serial" "01-hardware.txt"
  r system_profiler SPHardwareDataType
end_section
fi

# ---------------------------------------------------------------------------
# 02 — macOS version
# ---------------------------------------------------------------------------
if want macos; then
section "macOS version" "02-macos.txt"
  r sw_vers
  h ""
  r uname -a
  h ""
  r csrutil status
end_section
fi

# ---------------------------------------------------------------------------
# 03 — Disk layout
# ---------------------------------------------------------------------------
if want disk; then
section "Disk layout and volumes" "03-disk.txt"
  r diskutil list
  h ""
  h "--- APFS containers ---"
  safe_run 15 diskutil apfs list >> "$_SECTION_FILE" 2>&1 || true
  h ""
  h "--- Disk usage (mounted volumes) ---"
  r df -h
  h ""
  h "--- Home directory top level ---"
  r ls -lh "$HOME"
end_section
fi

# ---------------------------------------------------------------------------
# 04 — Display
# ---------------------------------------------------------------------------
if want display; then
section "Display setup" "04-display.txt"
  safe_run 20 system_profiler SPDisplaysDataType >> "$_SECTION_FILE" 2>&1 || true
end_section
fi

# ---------------------------------------------------------------------------
# 05 — Installed apps
# ---------------------------------------------------------------------------
if want apps; then
section "Installed applications" "05-apps.txt"
  h "--- /Applications ---"
  r ls -1 /Applications
  h ""
  h "--- Mac App Store apps (mas) ---"
  r mas list
end_section
fi

# ---------------------------------------------------------------------------
# 06 — Homebrew
# ---------------------------------------------------------------------------
if want homebrew; then
section "Homebrew formulae and casks" "06-homebrew.txt"
  h "--- Homebrew version ---"
  r brew --version
  h ""
  h "--- Formulae (leaves — top-level only) ---"
  r brew leaves
  h ""
  h "--- Formulae (all installed) ---"
  r brew list --formula
  h ""
  h "--- Casks ---"
  r brew list --cask
  h ""
  h "--- Brewfile export ---"
  brew bundle dump --file="$OUT/Brewfile" --force >> "$_SECTION_FILE" 2>&1 \
    && echo "Brewfile saved → $(basename "$OUT")/Brewfile" >> "$_SECTION_FILE" \
    || echo "brew bundle dump failed" >> "$_SECTION_FILE"
end_section
fi

# ---------------------------------------------------------------------------
# 07 — Shell config
# ---------------------------------------------------------------------------
if want shell; then
section "Shell config and PATH" "07-shell.txt"
  h "--- Current shell ---"
  r echo "$SHELL"
  r "$SHELL" --version
  h ""
  h "--- PATH (one per line) ---"
  echo "$PATH" | tr ':' '\n' >> "$_SECTION_FILE" || true
  h ""
  h "--- Dotfiles in home ---"
  ls -la "$HOME" | grep '^\.' >> "$_SECTION_FILE" 2>&1 || true
  h ""
  h "--- Aliases ---"
  r alias
  h ""
  h "--- oh-my-zsh plugins and theme ---"
  grep -E 'plugins=|ZSH_THEME=' "$HOME/.zshrc" >> "$_SECTION_FILE" 2>&1 || true
  h ""
  h "--- .zshrc ---"
  r cat "$HOME/.zshrc"
  h ""
  h "--- .zprofile ---"
  r cat "$HOME/.zprofile"
  h ""
  h "--- .zshenv ---"
  r cat "$HOME/.zshenv"
end_section
fi

# ---------------------------------------------------------------------------
# 08 — Git
# ---------------------------------------------------------------------------
if want git; then
section "Git global config" "08-git.txt"
  r git config --list --show-origin
  h ""
  h "--- .gitconfig ---"
  r cat "$HOME/.gitconfig"
  h ""
  h "--- .gitignore_global ---"
  r cat "$HOME/.gitignore_global"
end_section
fi

# ---------------------------------------------------------------------------
# 09 — Python
# ---------------------------------------------------------------------------
if want python; then
section "Python environment" "09-python.txt"
  h "--- python3 ---"
  r python3 --version
  r which python3
  h ""
  h "--- pyenv ---"
  r pyenv versions
  h ""
  h "--- conda environments ---"
  r conda env list
  h ""
  h "--- pip3 global packages ---"
  r pip3 list
  h ""
  h "--- venv locations (pyvenv.cfg) ---"
  find "$HOME" -name 'pyvenv.cfg' -not -path '*/.*' 2>/dev/null \
    | head -30 >> "$_SECTION_FILE" || true
end_section
fi

# ---------------------------------------------------------------------------
# 10 — Java and Gradle
# ---------------------------------------------------------------------------
if want java; then
section "Java and Gradle" "10-java.txt"
  h "--- java version ---"
  java -version >> "$_SECTION_FILE" 2>&1 || echo "java not found" >> "$_SECTION_FILE"
  h ""
  h "--- JAVA_HOME ---"
  echo "${JAVA_HOME:-(not set)}" >> "$_SECTION_FILE"
  h ""
  h "--- Installed JDKs ---"
  r ls /Library/Java/JavaVirtualMachines/
  h ""
  h "--- gradle ---"
  r gradle --version
  h ""
  h "--- SDKMAN candidates ---"
  sdk list 2>/dev/null | head -40 >> "$_SECTION_FILE" || echo "SDKMAN not installed" >> "$_SECTION_FILE"
  h ""
  h "--- Gradle wrapper versions in projects ---"
  find "$HOME" -name 'gradle-wrapper.properties' -not -path '*/\.*' 2>/dev/null \
    | head -20 \
    | while IFS= read -r f; do
        echo "$f:" >> "$_SECTION_FILE"
        grep 'distributionUrl' "$f" >> "$_SECTION_FILE" 2>/dev/null || true
      done || true
end_section
fi

# ---------------------------------------------------------------------------
# 11 — Node
# ---------------------------------------------------------------------------
if want node; then
section "Node.js and npm" "11-node.txt"
  h "--- node ---"
  r node --version
  h "--- npm ---"
  r npm --version
  h ""
  h "--- nvm versions ---"
  r nvm ls
  h ""
  h "--- Global npm packages ---"
  r npm list -g --depth=0
  h ""
  h "--- yarn ---"
  r yarn --version
end_section
fi

# ---------------------------------------------------------------------------
# 12 — Docker
# ---------------------------------------------------------------------------
if want docker; then
section "Docker" "12-docker.txt"
  if ! command -v docker >/dev/null 2>&1; then
    h "Docker CLI: not found on PATH."
  elif docker info >/dev/null 2>&1; then
    h "Docker daemon: reachable"
  else
    h "Docker daemon: NOT reachable — start Docker Desktop to capture images/containers/volumes."
  fi
  h ""
  h "--- Docker version ---"
  r docker version
  h ""
  h "--- Docker images ---"
  r docker images
  h ""
  h "--- Containers (all) ---"
  r docker ps -a
  h ""
  h "--- Volumes ---"
  r docker volume ls
  h ""
  h "--- Networks ---"
  r docker network ls
  h ""
  h "--- Compose version ---"
  r docker compose version
end_section
fi

# ---------------------------------------------------------------------------
# 13 — Network and SSH
# ---------------------------------------------------------------------------
if want network; then
section "Network and SSH" "13-network.txt"
  h "--- Hostname ---"
  r hostname
  r scutil --get ComputerName
  h ""
  h "--- Network interfaces ---"
  ifconfig | grep -E 'inet |flags' >> "$_SECTION_FILE" 2>&1 || true
  h ""
  h "--- SSH key files ---"
  r ls -la "$HOME/.ssh/"
  h ""
  h "--- SSH config ---"
  r cat "$HOME/.ssh/config"
  h ""
  h "--- known_hosts line count ---"
  wc -l "$HOME/.ssh/known_hosts" >> "$_SECTION_FILE" 2>&1 || echo "no known_hosts" >> "$_SECTION_FILE"
end_section
fi

# ---------------------------------------------------------------------------
# 14 — Cloud paths
# ---------------------------------------------------------------------------
if want cloud; then
section "OneDrive and iCloud paths" "14-cloud.txt"
  h "--- CloudStorage directory ---"
  r ls "$HOME/Library/CloudStorage/"
  h ""
  h "--- iCloud Drive root ---"
  ls "$HOME/Library/Mobile Documents/com~apple~CloudDocs/" 2>/dev/null \
    | head -40 >> "$_SECTION_FILE" || echo "iCloud Drive not found" >> "$_SECTION_FILE"
  h ""
  h "--- OneDrive plist ---"
  defaults read "$HOME/Library/Preferences/com.microsoft.OneDrive.plist" 2>/dev/null \
    | grep -i folder >> "$_SECTION_FILE" || echo "OneDrive plist not found" >> "$_SECTION_FILE"
end_section
fi

# ---------------------------------------------------------------------------
# 15 — Environment variables (redacted)
# ---------------------------------------------------------------------------
if want env; then
section "Environment variables (redacted)" "15-env.txt"
  env | grep -Ev 'SECRET|TOKEN|KEY|PASS|PWD|AWS|CREDENTIAL' \
    | sort >> "$_SECTION_FILE" 2>&1 || true
end_section
fi

# ---------------------------------------------------------------------------
# 16 — Certs and keychains
# ---------------------------------------------------------------------------
if want certs; then
section "Certificates and keychains" "16-certs.txt"
  h "--- Keychains ---"
  r security list-keychains
  h ""
  h "--- .env file locations (names only, no contents) ---"
  find "$HOME" -name '.env' \
    -not -path '*/node_modules/*' \
    -not -path '*/.git/*' \
    2>/dev/null | head -30 >> "$_SECTION_FILE" || true
end_section
fi

# ---------------------------------------------------------------------------
# Dotfiles (pairs with section 07 — shell)
# ---------------------------------------------------------------------------
if [[ -z "$SECTION_FILTER" || "$SECTION_FILTER" == "shell" ]]; then
echo ""
echo "============================================="
echo " Copying dotfiles → $(basename "$OUT")/dotfiles/"
echo "============================================="

DOTDIR="$OUT/dotfiles"
mkdir -p "$DOTDIR"

for f in \
  "$HOME/.zshrc" \
  "$HOME/.zprofile" \
  "$HOME/.zshenv" \
  "$HOME/.bashrc" \
  "$HOME/.bash_profile" \
  "$HOME/.gitconfig" \
  "$HOME/.gitignore_global" \
  "$HOME/.npmrc" \
  "$HOME/.pip/pip.conf" \
  "$HOME/.ssh/config"; do
  if [[ -f "$f" ]]; then
    cp "$f" "$DOTDIR/$(basename "$f")" \
      && echo "   ✓ copied $(basename "$f")" \
      || echo "   ! could not copy $(basename "$f")" >&2
  fi
done
fi

# ---------------------------------------------------------------------------
# Manifest
# ---------------------------------------------------------------------------
# When updating an existing bundle (single-section default), leave its original
# full-run MANIFEST.txt untouched so the manifest and its generation date still
# describe the complete bundle. The re-captured section file keeps its own fresh
# "# Generated:" header from the section helper.
if [[ "$UPDATED_EXISTING" != true ]]; then
  echo ""
  echo "============================================="
  echo " Generating manifest"
  echo "============================================="

  {
    echo "# System Inventory Manifest"
    echo "# Generated: $(date)"
    echo "# Host: $(hostname)"
    echo "# Artifact root: ${REIMAGE_ARTIFACT_ROOT:-(not set)}"
    echo "# Context: $CONTEXT"
    [[ -n "$SECTION_FILTER" ]] && echo "# Section filter: $SECTION_FILTER"
    echo ""
    echo "## Files captured"
    ls -lh "$OUT"
  } > "$OUT/MANIFEST.txt"
fi

if [[ "$UPDATED_EXISTING" == true ]]; then
  echo ""
  echo "Updated section '$SECTION_FILTER' in existing bundle:"
  echo "   $OUT"
  echo "Other sections and MANIFEST.txt were left unchanged."
else
  echo ""
  echo "============================================="
  echo " ✅ Done!"
  echo "    $OUT"
  echo ""
  echo " Next steps:"
  echo "   1. Verify Brewfile: $OUT/Brewfile"
  echo "   2. Review 15-env.txt for anything sensitive"
  echo "   3. Store SSH keys encrypted in secrets-encrypted/"
  echo "============================================="
  echo ""
fi
