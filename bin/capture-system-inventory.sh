#!/usr/bin/env bash
# =============================================================================
# capture-system-inventory.sh
#
# Read-only system inventory capture (Phase 4B pre-image / Phase 13B
# post-image): a one-pass record of how this Mac is configured — hardware and
# macOS, disk and display, installed apps, Homebrew (with a Brewfile dump),
# shell and dotfiles, Git, the language runtimes (Python, Java, Node), Docker,
# network and SSH, cloud paths, redacted environment clues, and certificate
# pointers. Writes a timestamped bundle under system-inventory/ holding the 16
# numbered section files, MANIFEST.txt, the Brewfile, and a dotfiles/ snapshot.
# It observes and records — the only things it writes are into the bundle. See
# capture-system-inventory.md for the full runbook.
#
# WHY A --section RUN COPIES THE BUNDLE FORWARD. Refreshing one section used to
# rewrite that file inside the newest bundle. That is the one thing a run index
# forbids: a promoted run's contents must stay fixed, or a manifest row stops
# describing the directory it names. Spawning a one-file bundle instead is worse
# -- the pointer would resolve to a bundle with fifteen sections missing.
#
# So a --section run stages a NEW run, copies the official bundle into it,
# overwrites just that one section, and promotes it. The previous run is
# untouched and still on disk, the official bundle is always complete, and the
# bundle's own MANIFEST.txt records which section was captured now and which run
# the rest was carried from. A bundle is around 120 KB, so the duplication costs
# less than the ambiguity it removes.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/capture-system-inventory.sh
#
#   # Default -- pre-image bundle under system-inventory/runs/pre-image-<stamp>/
#   ./bin/capture-system-inventory.sh
#
#   # Post-image bundle (Phase 13B)
#   ./bin/capture-system-inventory.sh --context post-image
#
#   # Override the artifact root for this invocation
#   ./bin/capture-system-inventory.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Write to an exact output directory (skips the run layout AND the index)
#   ./bin/capture-system-inventory.sh --output /absolute/path/to/output
#
#   # Refresh one section: copies the official bundle forward into a new run
#   ./bin/capture-system-inventory.sh --section docker
#
#   # Capture only one section into a fresh timestamped bundle
#   ./bin/capture-system-inventory.sh --section docker --new-bundle
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --context LABEL       pre-image | post-image | pre-image-<label> | post-image-<label>.
#                         Prefix for the timestamped run directory. Default: pre-image.
#   --output DIR          Exact output directory for generated files. A --section
#                         run into a directory that already holds a MANIFEST.txt
#                         updates that bundle in place and leaves its manifest
#                         untouched, the same as the default layout.
#   --section NAME        Capture only one section. One of: hardware, macos, disk,
#                         display, apps, homebrew, shell, git, python, java, node,
#                         docker, network, cloud, env, certs. Default: all. By
#                         default a single-section run copies the official bundle
#                         of the same --context forward into a new run and
#                         overwrites just that section; pass --new-bundle for a
#                         bundle holding that section alone.
#   --new-bundle          With --section, write a fresh bundle containing only the
#                         named section instead of copying the official one
#                         forward. Default: off.
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
#   1  Capture started but a required step failed (for example the bundle
#      directory could not be created). Individual section commands never fail
#      the run -- a section a machine cannot answer is written empty.
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

# Keep loading permissive: --artifact-root and --output are both parsed after
# the loader returns, and --output makes an artifact root unnecessary entirely.
# The resolved value is validated below, after option parsing.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

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

STAMP="$(date +%Y%m%d-%H%M%S)"
CONTEXT="pre-image"
OUTPUT_DIR=""
SECTION_FILTER=""   # empty = all sections
NEW_BUNDLE=false    # with --section, write a section-only bundle instead of copying forward
UPDATED_EXISTING=false   # set true when a --section run updates a bundle in place (--output only)
CARRIED_FROM=""     # run id a --section run copied its other sections from
INDEXED=false
CATEGORY_ROOT=""

# The system inventory is a run category. Sourcing this is what lets a --section
# run resolve the bundle it copies forward by lineage rather than by taking
# whichever directory sorted last -- which after Phase 13B is a post-image bundle,
# and refreshing the docker section of the wrong context is a silent way to make
# the pre-image baseline describe the restored machine.
RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/artifact-runs.sh
source "$RUNS_LIB"

# Gate for --section: true when no filter is set, or when the filter matches
# this section's keyword. Wraps each section block without altering its body.
want() { [[ -z "$SECTION_FILTER" || "$SECTION_FILTER" == "$1" ]]; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --context)
      require_option_value "$1" "${2:-}"
      CONTEXT="$2"
      shift 2
      ;;
    --output)
      require_option_value "$1" "${2:-}"
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --section)
      require_option_value "$1" "${2:-}"
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

  CATEGORY_ROOT="$REIMAGE_ARTIFACT_ROOT/system-inventory"
  if ! artifact_run_begin "$CATEGORY_ROOT" "$CONTEXT"; then
    echo "ERROR: could not stage a run under: $CATEGORY_ROOT" >&2
    exit 2
  fi
  OUTPUT_DIR="$ARTIFACT_RUN_DIR"
  INDEXED=true

  if [[ -n "$SECTION_FILTER" && "$NEW_BUNDLE" != true ]]; then
    # Copy the official bundle of this context forward, then let the section
    # blocks below overwrite the one file being refreshed. Resolved by lineage,
    # never by recency: `official/<context>.txt` is the only thing that can say
    # "the pre-image bundle" once a post-image one exists beside it.
    _prev_rel="$(artifact_run_official "$CATEGORY_ROOT" "$CONTEXT" 2>/dev/null || true)"
    if [[ -n "$_prev_rel" ]]; then
      if ! cp -R "$CATEGORY_ROOT/$_prev_rel"/. "$OUTPUT_DIR"/; then
        artifact_run_abort
        echo "ERROR: could not copy $_prev_rel forward into the new run." >&2
        exit 1
      fi
      # A pin marker describes ONE run. Carried into a copy it names a run this
      # directory is not, and artifact_runs_rebuild reads markers off disk -- so
      # leaving it here would let a rebuild resurrect a pin from a bundle that
      # only inherited the file.
      rm -f "$OUTPUT_DIR/PINNED-OFFICIAL.txt"
      CARRIED_FROM="${_prev_rel#runs/}"
      echo "Copying forward from ${_prev_rel}; refreshing section '$SECTION_FILTER'." >&2
    else
      echo "Note: no official ${CONTEXT} bundle to copy forward; this run holds section '$SECTION_FILTER' alone." >&2
    fi
  fi
fi

# --output only. A single-section run into an exact directory that already holds
# a bundle would otherwise replace that bundle's full-run MANIFEST.txt with one
# stamped for the partial run, so it keeps the old in-place semantics.
#
# `INDEXED != true` is the load-bearing clause. A copy-forward run has just
# copied a MANIFEST.txt into its own staging directory, so without it every
# --section run would match this test, keep the manifest it inherited -- dated
# for another run, silent about the refresh -- and report that nothing was
# indexed while the pointer had in fact advanced.
if [[ "$INDEXED" != true && -n "$SECTION_FILTER" && "$NEW_BUNDLE" != true \
      && "$UPDATED_EXISTING" != true && -f "$OUTPUT_DIR/MANIFEST.txt" ]]; then
  UPDATED_EXISTING=true
fi

OUT="$OUTPUT_DIR"
mkdir -p "$OUT"

# What the banner and the progress lines call the bundle. $OUT is the
# `.incomplete` staging directory until finalize renames it, and a path printed
# here that stops existing thirty seconds later is worse than no path.
OUT_LABEL="$OUT"
if [[ "$INDEXED" == true ]]; then
  OUT_LABEL="$ARTIFACT_RUN_FINAL_DIR"
fi

# A capture that dies part way through has produced a bundle that answers only
# some of the questions it exists to answer. Discarding it is what makes "every
# directory under runs/ is a complete bundle" true rather than usual.
cleanup_system_inventory_run() {
  if [[ "$INDEXED" == true ]]; then
    artifact_run_abort
  fi
  return 0
}
trap cleanup_system_inventory_run EXIT
trap 'exit 130' INT TERM

echo ""
echo "============================================="
echo " Mac System Inventory Capture"
echo " Output → $OUT_LABEL"
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
  echo "   ✓ saved → $(basename "$OUT_LABEL")/$(basename "$_SECTION_FILE")"
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
    && echo "Brewfile saved → $(basename "$OUT_LABEL")/Brewfile" >> "$_SECTION_FILE" \
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
  # 'ls -la' lines start with permission bits, so filtering that output on '^\.'
  # never matches and the block came out empty. Glob the dotfile entries instead.
  ls -lad "$HOME"/.[!.]* >> "$_SECTION_FILE" 2>/dev/null || true
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
  # 'sdk' is a shell function defined by sdkman-init.sh, so it does not exist in
  # a non-interactive script; the old 'sdk list | head' pipeline reported head's
  # status, so the "not installed" fallback never ran and this block was blank.
  SDKMAN_HOME="${SDKMAN_DIR:-$HOME/.sdkman}"
  if command -v sdk >/dev/null 2>&1; then
    sdk list 2>/dev/null | head -40 >> "$_SECTION_FILE" || true
  elif [[ -r "$SDKMAN_HOME/bin/sdkman-init.sh" ]]; then
    {
      echo "SDKMAN installed at $SDKMAN_HOME"
      echo "('sdk' is an interactive shell function and is not callable here; listing the candidates directory instead.)"
      find "$SDKMAN_HOME/candidates" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | head -40 || true
    } >> "$_SECTION_FILE"
  else
    echo "SDKMAN not installed" >> "$_SECTION_FILE"
  fi
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
  # Case-insensitive: lowercase/mixed-case names such as github_token or
  # npm_config_authToken passed the old case-sensitive filter and landed in
  # plaintext on the artifact drive. The filter matches the whole NAME=value
  # line, so this also drops benign entries that merely contain one of these
  # words (e.g. a PATH holding an ".../aws-cli/..." or ".../keychain/..."
  # component). Over-redacting an inventory file is the accepted trade.
  env | grep -Evi 'SECRET|TOKEN|KEY|PASS|PWD|AWS|CREDENTIAL' \
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
echo " Copying dotfiles → $(basename "$OUT_LABEL")/dotfiles/"
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
# A copied-forward bundle gets its OWN manifest, overwriting the one it
# inherited. Keeping the copied manifest would leave a bundle describing itself
# by another run's generation date, and would say nothing about the section that
# is the only reason this run exists. The provenance lines below are what let a
# reader tell a captured section from a carried one -- which is the single thing
# the old in-place update did not have to explain, and the single thing
# copy-forward must.
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
    [[ "$INDEXED" == true ]] && echo "# Run: $ARTIFACT_RUN_ID"
    if [[ -n "$SECTION_FILTER" ]]; then
      echo "# Section filter: $SECTION_FILTER"
      if [[ -n "$CARRIED_FROM" ]]; then
        echo "#"
        echo "# Only '$SECTION_FILTER' was captured at the generation date above."
        echo "# Every other file was copied forward from run: $CARRIED_FROM"
        echo "# and still carries its own '# Generated:' header from that capture."
      else
        echo "#"
        echo "# This bundle holds section '$SECTION_FILTER' alone."
      fi
    fi
    echo ""
    echo "## Files captured"
    ls -lh "$OUT"
  } > "$OUT/MANIFEST.txt"
fi

if [[ "$INDEXED" == true ]]; then
  if [[ -n "$SECTION_FILTER" && -n "$CARRIED_FROM" ]]; then
    RESULT_SUMMARY="section '$SECTION_FILTER' refreshed, rest carried from $CARRIED_FROM"
  elif [[ -n "$SECTION_FILTER" ]]; then
    RESULT_SUMMARY="section '$SECTION_FILTER' only"
  else
    RESULT_SUMMARY="full capture, 16 sections"
  fi
  trap - EXIT INT TERM
  if ! artifact_run_finalize "$CATEGORY_ROOT" "$RESULT_SUMMARY"; then
    echo "ERROR: the bundle was written but could not be indexed under: $CATEGORY_ROOT" >&2
    echo "Repair the index with: ./bin/reindex-artifact-runs.sh --category \"$CATEGORY_ROOT\"" >&2
    exit 1
  fi
  OUT="$ARTIFACT_RUN_DIR"
fi

if [[ "$UPDATED_EXISTING" == true ]]; then
  echo ""
  echo "Updated section '$SECTION_FILTER' in place at an exact --output path:"
  echo "   $OUT"
  echo "Other sections and MANIFEST.txt were left unchanged, and nothing was indexed."
elif [[ -n "$SECTION_FILTER" && -n "$CARRIED_FROM" ]]; then
  echo ""
  echo "============================================="
  echo " ✅ Section '$SECTION_FILTER' refreshed"
  echo "    $OUT"
  echo ""
  echo "    Carried forward from: $CARRIED_FROM"
  echo "    That run is untouched and still on disk."
  echo "============================================="
  echo ""
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
