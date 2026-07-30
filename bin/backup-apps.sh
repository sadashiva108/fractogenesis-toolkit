#!/usr/bin/env bash
# =============================================================================
# backup-apps.sh
#
# Phase 2D app-backup entrypoint: automates the safe steps that don't require
# app UI exports. Prepares the standard app-settings-backup/ and
# secrets-encrypted/ folders, runs the Docker helper when Docker state is
# detected, runs the IntelliJ helper when IntelliJ state is detected, captures
# the local VS Code fallback, and writes app-settings-backup/MANIFEST.md with
# the remaining manual follow-up items. See backup-apps.md for the full
# runbook, including the manual/app-controlled steps this script cannot do.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/backup-apps.sh
#
#   # Default -- Docker, IntelliJ, VS Code fallback, and manifest
#   ./bin/backup-apps.sh
#
#   # Review-only bundle of app-backup candidates worth checking
#   # (folds in the managed-inventory bundle and partitions managed apps out)
#   ./bin/backup-apps.sh --candidate-review
#
#   # Point candidate review at a specific managed-inventory bundle
#   ./bin/backup-apps.sh --candidate-review --managed-inventory /path/to/managed-inventory/pre-image-<stamp>
#
#   # List the apps this toolkit can back up (info only)
#   ./bin/backup-apps.sh --supported-apps
#
#   # Rerun a single portion through this entrypoint
#   ./bin/backup-apps.sh --docker-only
#   ./bin/backup-apps.sh --intellij-only
#   ./bin/backup-apps.sh --vscode-only
#
#   # Override the artifact root for this invocation
#   ./bin/backup-apps.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Open the primary output after the run
#   ./bin/backup-apps.sh --open
#
# Optional:
#   --candidate-review      Generate a review-only app candidate bundle under:
#                           $REIMAGE_ARTIFACT_ROOT/app-settings-backup/candidate-review/
#                           Consumes the newest managed-inventory bundle (if present)
#                           to enrich raw/ and partition managed apps into their own
#                           table. Runs standalone when no managed bundle exists.
#   --managed-inventory DIR Managed-inventory bundle candidate review should consult.
#                           Default: newest pre-image-* under
#                           $REIMAGE_ARTIFACT_ROOT/managed-inventory/. Only used with
#                           --candidate-review.
#   --supported-apps        List the supported apps (app, group, how backed up) and exit.
#                           Info only; writes nothing and computes no sizes.
#   --docker-only            Rerun only the Docker portion through this entrypoint.
#   --intellij-only          Rerun only the IntelliJ portion through this entrypoint.
#   --vscode-only            Rerun only the VS Code fallback capture through this entrypoint.
#
# IntelliJ options passed through to the internal helper:
#   --intellij-workspace-root PATH
#   --intellij-workspace-max-depth N
#   --intellij-all-config-dirs
#   --intellij-skip-workspaces
#   --intellij-include-shelf
#   --intellij-include-system-cache
#
# Options:
#   --artifact-root PATH   Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --open                  Open the primary output after the run.
#   -h, --help              Show this message and exit.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Exit status:
#   0  Completed successfully.
#   1  Ran but a helper/copy step failed.
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

supported_apps_registry() {
  # Single source of truth for Phase 2D app coverage. Consumed by
  # --supported-apps (all rows) and the candidate review (detectable rows only),
  # so the covered-app list lives in exactly one place. Tab-delimited fields:
  #   app  group  how  non_secret_dest  secret_dest
  #   detectable  phase_fit  route  use_when  bundle_paths  state_paths
  # The candidate review's managed partition is keyed off each app's bundle
  # basename (from bundle_paths) against the managed-inventory section 03 verdict,
  # so no per-app managed-match list is kept here.
  local r="${REIMAGE_ARTIFACT_ROOT:-}"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "IntelliJ IDEA" "Common" "Script + manual settings ZIP" "$r/app-settings-backup/intellij/" "$r/secrets-encrypted/" \
    "yes" "Common — dedicated runbook" "backup-intellij.md" "IDE state, Scratches, settings export, plugins, project metadata, or HTTP Client env files matter." "/Applications/IntelliJ IDEA.app;$HOME/Applications/IntelliJ IDEA.app" "$HOME/Library/Application Support/JetBrains;$HOME/Library/Preferences/JetBrains"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Docker Desktop" "Common" "Script" "$r/app-settings-backup/docker/" "$r/secrets-encrypted/docker/" \
    "yes" "Common" "backup-apps.md" "Docker Desktop settings, contexts, image inventory, or container inventory matter." "/Applications/Docker.app;$HOME/Applications/Docker.app" "$HOME/Library/Group Containers/group.com.docker;$HOME/Library/Containers/com.docker.docker"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Chrome" "Common" "Manual" "$r/app-settings-backup/chrome/" "$r/secrets-encrypted/chrome/" \
    "yes" "Common" "backup-apps.md" "Bookmarks export or password export is needed." "/Applications/Google Chrome.app;$HOME/Applications/Google Chrome.app" "$HOME/Library/Application Support/Google/Chrome;$HOME/Library/Preferences/com.google.Chrome.plist"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Postman" "Common" "Manual" "$r/app-settings-backup/postman/" "$r/secrets-encrypted/postman/" \
    "yes" "Common" "backup-apps.md" "Collections, environments, or Vault state matter." "/Applications/Postman.app;$HOME/Applications/Postman.app" "$HOME/Library/Application Support/Postman;$HOME/Library/Preferences/com.postmanlabs.mac.plist"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Raycast" "Optional" "Manual" "$r/app-settings-backup/raycast/" "$r/secrets-encrypted/raycast/" \
    "yes" "Optional" "backup-apps.md" "Quick Links or settings/data export matter." "/Applications/Raycast.app;$HOME/Applications/Raycast.app" "$HOME/Library/Application Support/com.raycast.macos;$HOME/Library/Preferences/com.raycast.macos.plist"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Obsidian" "Optional" "Manual" "$r/app-settings-backup/obsidian/" "usually none from this runbook" \
    "yes" "Optional" "backup-apps.md" "Vault content, vault-local config, or restore-source choice matters." "/Applications/Obsidian.app;$HOME/Applications/Obsidian.app" "$HOME/Library/Application Support/obsidian"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Visual Studio Code" "Common" "Script" "$r/app-settings-backup/vscode/" "usually none from this runbook" \
    "yes" "Optional" "backup-apps.md" "Extensions, settings, snippets, profiles, or a local fallback beyond Settings Sync matter." "/Applications/Visual Studio Code.app;$HOME/Applications/Visual Studio Code.app" "$HOME/Library/Application Support/Code;$HOME/Library/Preferences/com.microsoft.VSCode.plist"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Terminal" "Common" "Manual" "$r/app-settings-backup/terminal/" "none" \
    "no" "Common" "backup-apps.md" "Custom Terminal.app profile (colors, font, window size) worth preserving." "/System/Applications/Utilities/Terminal.app" "$HOME/Library/Preferences/com.apple.Terminal.plist"
}

print_supported_apps() {
  # Info only: writes nothing and computes no sizes (sizing is the sole
  # responsibility of capture-size-audit.sh).
  echo "Apps this toolkit can back up (Phase 2D):"
  echo ""
  printf '  %-20s  %-9s  %s\n' "App" "Group" "How backed up"
  printf '  %-20s  %-9s  %s\n' "--------------------" "---------" "-------------"
  while IFS=$'\t' read -r app group how _; do
    printf '  %-20s  %-9s  %s\n' "$app" "$group" "$how"
  done < <(supported_apps_registry)
  echo ""
  echo "Apps not listed are your responsibility to back up. See backup-apps.md for full detail."
}

OPEN_AFTER=false
RUN_CANDIDATE_REVIEW=false
MANAGED_INVENTORY_DIR=""
DOCKER_ONLY=false
INTELLIJ_ONLY=false
VSCODE_ONLY=false
SHOW_SUPPORTED=false
INTELLIJ_ALL_CONFIG_DIRS=false
INTELLIJ_INCLUDE_SYSTEM_CACHE=false
INTELLIJ_SKIP_WORKSPACES=false
INTELLIJ_INCLUDE_SHELF=false
INTELLIJ_WORKSPACE_ROOT=""
INTELLIJ_WORKSPACE_MAX_DEPTH=""

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
    --candidate-review) RUN_CANDIDATE_REVIEW=true; shift ;;
    --managed-inventory)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "ERROR: --managed-inventory requires a directory." >&2
        usage >&2
        exit 2
      fi
      MANAGED_INVENTORY_DIR="$2"
      shift 2
      ;;
    --docker-only) DOCKER_ONLY=true; shift ;;
    --intellij-only) INTELLIJ_ONLY=true; shift ;;
    --vscode-only) VSCODE_ONLY=true; shift ;;
    --supported-apps) SHOW_SUPPORTED=true; shift ;;
    --intellij-workspace-root) INTELLIJ_WORKSPACE_ROOT="${2:-}"; shift 2 ;;
    --intellij-workspace-max-depth) INTELLIJ_WORKSPACE_MAX_DEPTH="${2:-}"; shift 2 ;;
    --intellij-all-config-dirs) INTELLIJ_ALL_CONFIG_DIRS=true; shift ;;
    --intellij-skip-workspaces) INTELLIJ_SKIP_WORKSPACES=true; shift ;;
    --intellij-include-shelf) INTELLIJ_INCLUDE_SHELF=true; shift ;;
    --intellij-include-system-cache) INTELLIJ_INCLUDE_SYSTEM_CACHE=true; shift ;;
    --open) OPEN_AFTER=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# --supported-apps is info only: it needs no artifact root and writes nothing.
if [[ "$SHOW_SUPPORTED" == true ]]; then
  print_supported_apps
  exit 0
fi

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set." >&2
  echo "Create/source reimage.env or pass --artifact-root PATH." >&2
  exit 2
fi

if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: artifact root not found: $REIMAGE_ARTIFACT_ROOT" >&2
  exit 2
fi

# Only one single-app rerun mode may be active at a time, and none of them
# combine with the scan-only candidate review.
ONLY_COUNT=0
[[ "$DOCKER_ONLY" == true ]] && ONLY_COUNT=$((ONLY_COUNT + 1))
[[ "$INTELLIJ_ONLY" == true ]] && ONLY_COUNT=$((ONLY_COUNT + 1))
[[ "$VSCODE_ONLY" == true ]] && ONLY_COUNT=$((ONLY_COUNT + 1))

if (( ONLY_COUNT > 1 )); then
  echo "ERROR: choose only one of --docker-only, --intellij-only, or --vscode-only" >&2
  exit 2
fi

if (( ONLY_COUNT > 0 )) && [[ "$RUN_CANDIDATE_REVIEW" == true ]]; then
  echo "ERROR: --candidate-review cannot be combined with --docker-only, --intellij-only, or --vscode-only" >&2
  exit 2
fi

APP_ROOT="$REIMAGE_ARTIFACT_ROOT/app-settings-backup"
SECRETS_ROOT="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"
STAMP="$(date '+%Y-%m-%d %H:%M:%S')"
CANDIDATE_REVIEW_DIR=""

mkdir -p \
  "$APP_ROOT" \
  "$APP_ROOT/candidate-review" \
  "$APP_ROOT/chrome" \
  "$APP_ROOT/docker" \
  "$APP_ROOT/obsidian" \
  "$APP_ROOT/postman/collections" \
  "$APP_ROOT/postman/environments-redacted" \
  "$APP_ROOT/postman/inventory" \
  "$APP_ROOT/raycast" \
  "$APP_ROOT/vscode/user" \
  "$SECRETS_ROOT/chrome" \
  "$SECRETS_ROOT/docker" \
  "$SECRETS_ROOT/postman/environments" \
  "$SECRETS_ROOT/postman/vault-if-export-allowed" \
  "$SECRETS_ROOT/raycast/quicklinks-if-sensitive"

DOCKER_STATUS="Not run"
INTELLIJ_STATUS="Not run"
VSCODE_STATUS="Not run"
CANDIDATE_REVIEW_STATUS="Not run"

DOCKER_HELPER="$(dirname "$SCRIPT_DIR")/.internal/apps/backup-docker-settings.sh"
if [[ "$INTELLIJ_ONLY" == true ]]; then
  DOCKER_STATUS="Skipped by --intellij-only"
elif [[ "$VSCODE_ONLY" == true ]]; then
  DOCKER_STATUS="Skipped by --vscode-only"
elif [[ -f "$DOCKER_HELPER" ]]; then
  if [[ -d "/Applications/Docker.app" ]] || [[ -d "$HOME/Library/Group Containers/group.com.docker" ]] || [[ -f "$HOME/.docker/config.json" ]] || command -v docker >/dev/null 2>&1; then
    bash "$DOCKER_HELPER" --artifact-root "$REIMAGE_ARTIFACT_ROOT"
    DOCKER_STATUS="Captured to app-settings-backup/docker/ and secrets-encrypted/docker/ when available"
  else
    DOCKER_STATUS="Skipped; Docker Desktop state not detected on this Mac"
  fi
else
  DOCKER_STATUS="Skipped; .internal/apps/backup-docker-settings.sh not found"
fi

INTELLIJ_HELPER="$(dirname "$SCRIPT_DIR")/.internal/apps/backup-intellij-scratches-consoles.sh"
INTELLIJ_HELPER_ARGS=(--artifact-root "$REIMAGE_ARTIFACT_ROOT")
# Default the IntelliJ workspace root to the configured work-repo root when the
# caller did not pass --intellij-workspace-root, mirroring how backup-repos.sh
# defaults --root to GIT_WORK_REPO_ROOT.
if [[ -z "$INTELLIJ_WORKSPACE_ROOT" && -n "${GIT_WORK_REPO_ROOT:-}" ]]; then
  INTELLIJ_WORKSPACE_ROOT="$GIT_WORK_REPO_ROOT"
fi
if [[ -n "$INTELLIJ_WORKSPACE_ROOT" ]]; then
  INTELLIJ_HELPER_ARGS+=(--workspace-root "$INTELLIJ_WORKSPACE_ROOT")
fi
if [[ -n "$INTELLIJ_WORKSPACE_MAX_DEPTH" ]]; then
  INTELLIJ_HELPER_ARGS+=(--workspace-max-depth "$INTELLIJ_WORKSPACE_MAX_DEPTH")
fi
if [[ "$INTELLIJ_ALL_CONFIG_DIRS" == true ]]; then
  INTELLIJ_HELPER_ARGS+=(--all-config-dirs)
fi
if [[ "$INTELLIJ_SKIP_WORKSPACES" == true ]]; then
  INTELLIJ_HELPER_ARGS+=(--skip-workspaces)
fi
if [[ "$INTELLIJ_INCLUDE_SHELF" == true ]]; then
  INTELLIJ_HELPER_ARGS+=(--include-shelf)
fi
if [[ "$INTELLIJ_INCLUDE_SYSTEM_CACHE" == true ]]; then
  INTELLIJ_HELPER_ARGS+=(--include-system-cache)
fi

if [[ "$DOCKER_ONLY" == true ]]; then
  INTELLIJ_STATUS="Skipped by --docker-only"
elif [[ "$VSCODE_ONLY" == true ]]; then
  INTELLIJ_STATUS="Skipped by --vscode-only"
elif [[ -f "$INTELLIJ_HELPER" ]]; then
  if [[ -d "/Applications/IntelliJ IDEA.app" ]] || [[ -d "$HOME/Applications/IntelliJ IDEA.app" ]] || [[ -d "$HOME/Library/Application Support/JetBrains" ]]; then
    bash "$INTELLIJ_HELPER" "${INTELLIJ_HELPER_ARGS[@]}"
    INTELLIJ_STATUS="Captured under app-settings-backup/intellij/ when IntelliJ state was found"
  else
    INTELLIJ_STATUS="Skipped; IntelliJ IDEA state not detected on this Mac"
  fi
else
  INTELLIJ_STATUS="Skipped; .internal/apps/backup-intellij-scratches-consoles.sh not found"
fi

if [[ "$DOCKER_ONLY" == true || "$INTELLIJ_ONLY" == true ]]; then
  VSCODE_STATUS="Skipped by single-app rerun mode"
else
  VSCODE_DEST="$APP_ROOT/vscode"
  VSCODE_USER="$HOME/Library/Application Support/Code/User"
  VSCODE_FOUND=false
  CODE_BIN=""

  if command -v code >/dev/null 2>&1; then
    CODE_BIN="$(command -v code)"
  elif [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
    CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  fi

  if [[ -n "$CODE_BIN" ]]; then
    "$CODE_BIN" --list-extensions > "$VSCODE_DEST/extensions.txt" 2>/dev/null || true
    VSCODE_FOUND=true
  fi

  for f in settings.json keybindings.json; do
    if [[ -f "$VSCODE_USER/$f" ]]; then
      cp -p "$VSCODE_USER/$f" "$VSCODE_DEST/user/$f"
      VSCODE_FOUND=true
    fi
  done

  for d in snippets profiles; do
    if [[ -d "$VSCODE_USER/$d" ]]; then
      rsync -a "$VSCODE_USER/$d/" "$VSCODE_DEST/user/$d/" 2>/dev/null || true
      VSCODE_FOUND=true
    fi
  done

  if [[ "$VSCODE_FOUND" == true ]]; then
    VSCODE_STATUS="Captured local VS Code fallback under app-settings-backup/vscode/"
  else
    VSCODE_STATUS="Skipped; VS Code CLI or local user state not detected"
  fi
fi

first_existing_path() {
  local list="$1"
  local item
  IFS=';' read -r -a items <<< "$list"
  for item in "${items[@]}"; do
    if [[ -e "$item" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

existing_paths_markdown() {
  local list="$1"
  local item
  local found=()
  IFS=';' read -r -a items <<< "$list"
  for item in "${items[@]}"; do
    [[ -e "$item" ]] && found+=("$item")
  done
  if [[ ${#found[@]} -eq 0 ]]; then
    printf '%s' 'none found'
    return 0
  fi
  printf '%s' "${found[0]}"
  local i
  for (( i=1; i<${#found[@]}; i++ )); do
    printf '<br>%s' "${found[i]}"
  done
}

existing_paths_inline() {
  local list="$1"
  local item
  local found=()
  IFS=';' read -r -a items <<< "$list"
  for item in "${items[@]}"; do
    [[ -e "$item" ]] && found+=("$item")
  done
  if [[ ${#found[@]} -eq 0 ]]; then
    printf '%s' 'none found'
    return 0
  fi
  printf '%s' "${found[0]}"
  local i
  for (( i=1; i<${#found[@]}; i++ )); do
    printf ' | %s' "${found[i]}"
  done
}

app_version() {
  local app_path="$1"
  if [[ -f "$app_path/Contents/Info.plist" ]]; then
    /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Contents/Info.plist" 2>/dev/null || echo ""
  fi
}

emit_candidate_row() {
  local file="$1"
  local summary_file="$2"
  local app="$3"
  local phase_fit="$4"
  local route="$5"
  local use_when="$6"
  local non_secret_dest="$7"
  local secret_dest="$8"
  local bundle_paths="$9"
  local state_paths="${10}"
  local managed_evidence="${11:-}"

  local installed_path installed version installed_label state_inline state_md
  installed_path="$(first_existing_path "$bundle_paths" || true)"
  if [[ -n "$installed_path" ]]; then
    installed="yes"
    version="$(app_version "$installed_path")"
    installed_label="yes${version:+ ($version)}"
  else
    installed="no"
    version=""
    installed_label="no"
  fi
  state_inline="$(existing_paths_inline "$state_paths")"
  state_md="$(existing_paths_markdown "$state_paths")"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$app" \
    "$phase_fit" \
    "$installed" \
    "$installed_path" \
    "$version" \
    "$route" \
    "$use_when" \
    "$non_secret_dest" \
    "$secret_dest" \
    "$state_inline" \
    "$managed_evidence" >> "$file"

  # A non-empty managed_evidence routes the row to the Managed table, which
  # carries an extra evidence column; otherwise the standard five-column row.
  if [[ -n "$managed_evidence" ]]; then
    printf '| %s | %s | %s | %s | %s | %s |\n' \
      "$app" \
      "$installed_label" \
      "$managed_evidence" \
      "$phase_fit" \
      "$route" \
      "$state_md" >> "$summary_file"
  else
    printf '| %s | %s | %s | %s | %s |\n' \
      "$app" \
      "$installed_label" \
      "$phase_fit" \
      "$route" \
      "$state_md" >> "$summary_file"
  fi
}

find_managed_inventory_bundle() {
  # Echo the managed-inventory bundle candidate review should consult, or nothing.
  # Honors --managed-inventory; otherwise picks the newest pre-image-* bundle
  # (falling back to the newest bundle of any context). Never fails the review.
  if [[ -n "$MANAGED_INVENTORY_DIR" ]]; then
    [[ -d "$MANAGED_INVENTORY_DIR" ]] && printf '%s\n' "$MANAGED_INVENTORY_DIR"
    return 0
  fi
  local base="$REIMAGE_ARTIFACT_ROOT/managed-inventory"
  [[ -d "$base" ]] || return 0
  local d
  d="$(find "$base" -maxdepth 1 -mindepth 1 -type d -name 'pre-image-*' 2>/dev/null | sort | tail -1)"
  if [[ -z "$d" ]]; then
    d="$(find "$base" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)"
  fi
  [[ -n "$d" ]] && printf '%s\n' "$d"
  return 0
}

managed_verdict_from_03() {
  # Read the single authoritative managed verdict for one app from the
  # managed-inventory section 03 file (capture-managed-inventory.sh owns the
  # verdict logic; this only consumes it). Args: 03 file path, app bundle
  # basename (e.g. "Docker.app"). Echoes "<verdict><TAB><evidence>" where
  # verdict is "managed" or "likely"; echoes nothing when the app is absent,
  # tagged "[-]", or the file predates the tagged format.
  local file="$1" base="$2"
  [[ -f "$file" ]] || return 0
  local tab; tab="$(printf '\t')"
  local line tag
  # Match the app's own line: path ending in "/<basename><TAB>", comments skipped.
  line="$(grep -v '^#' "$file" 2>/dev/null | grep -F -- "/$base$tab" 2>/dev/null | head -1 || true)"
  [[ -n "$line" ]] || return 0
  tag="${line#*"$tab"}"          # everything after the first tab: "[verdict: ev]" or "[-]"
  tag="${tag#\[}"; tag="${tag%\]}"
  case "$tag" in
    managed:*) printf 'managed%s%s\n' "$tab" "$(printf '%s' "${tag#managed:}" | sed 's/^ *//')" ;;
    likely:*)  printf 'likely%s%s\n'  "$tab" "$(printf '%s' "${tag#likely:}"  | sed 's/^ *//')" ;;
    *) return 0 ;;
  esac
}

generate_candidate_review() {
  local out raw app_root_list app_user_list app_all_list known_tsv supported_tsv review_tsv summary_md state_signals root_display
  local managed_bundle managed_03 managed_index managed_source known_md_tmp managed_md_tmp related_md_tmp supported_lookup
  local TAB; TAB="$(printf '\t')"

  out="$APP_ROOT/candidate-review/app-backup-candidates-$(date +%Y%m%d-%H%M%S)"
  raw="$out/raw"
  mkdir -p "$raw"
  CANDIDATE_REVIEW_DIR="$out"

  app_root_list="$raw/applications-root.txt"
  app_user_list="$raw/applications-user.txt"
  app_all_list="$raw/applications-all.txt"
  known_tsv="$out/known-app-candidates.tsv"
  supported_tsv="$out/toolkit-supported-candidates.tsv"
  review_tsv="$out/related-app-review.tsv"
  summary_md="$out/app-backup-candidates.md"
  state_signals="$raw/state-signal-paths.txt"
  managed_index="$raw/managed-apps-detected.txt"
  managed_source="$raw/managed-inventory-source.txt"
  supported_lookup="$out/.supported-lookup.tmp"
  known_md_tmp="$out/.known-md.tmp"
  managed_md_tmp="$out/.managed-md.tmp"
  related_md_tmp="$out/.related-md.tmp"
  root_display="$REIMAGE_ARTIFACT_ROOT"

  find /Applications -maxdepth 1 -type d -name '*.app' 2>/dev/null | sort > "$app_root_list"
  if [[ -d "$HOME/Applications" ]]; then
    find "$HOME/Applications" -maxdepth 1 -type d -name '*.app' 2>/dev/null | sort > "$app_user_list"
  else
    : > "$app_user_list"
  fi
  cat "$app_root_list" "$app_user_list" | sed '/^$/d' | sort -u > "$app_all_list"

  find \
    "$HOME/Library/Application Support" \
    "$HOME/Library/Preferences" \
    "$HOME/Library/Containers" \
    "$HOME/Library/Group Containers" \
    "$HOME/Library/Application Scripts" \
    "$HOME/Library/Saved Application State" \
    -maxdepth 2 2>/dev/null \
    \( -iname '*chrome*' -o -iname '*postman*' -o -iname '*raycast*' -o -iname '*obsidian*' -o -iname '*docker*' -o -iname '*jetbrains*' -o -iname '*code*' -o -iname '*music*' \) \
    | sort -u > "$state_signals" || true

  # Fold the managed-inventory bundle into the raw results. The managed verdict
  # is read from that bundle's section 03 (its single authoritative per-app
  # verdict) — this review does not re-derive it. When no bundle is found the
  # review still runs; every detected app then stays a Known candidate.
  managed_bundle="$(find_managed_inventory_bundle)"
  managed_03=""
  if [[ -n "$managed_bundle" ]]; then
    managed_03="$managed_bundle/03-installed-app-bundles.txt"
    {
      echo "Managed-inventory bundle consulted by this candidate review:"
      echo "$managed_bundle"
      echo ""
      echo "Managed verdicts are read from that bundle's 03-installed-app-bundles.txt,"
      echo "the single authoritative per-app verdict written by capture-managed-inventory.sh."
    } > "$managed_source"
    # The distilled managed set is section 03's own tagged lines (managed + likely).
    {
      echo "# Managed and likely-managed apps, read from:"
      echo "# $managed_03"
      grep -v '^#' "$managed_03" 2>/dev/null | grep -E "\\[(managed|likely):" 2>/dev/null || true
    } > "$managed_index"
  else
    : > "$managed_index"
    {
      echo "No managed-inventory bundle was found under:"
      echo "$REIMAGE_ARTIFACT_ROOT/managed-inventory/"
      echo ""
      echo "Managed-app partitioning was skipped, so every detected app is listed as a"
      echo "Known Phase 2D candidate. Run capture-managed-inventory.md first, or pass"
      echo "--managed-inventory DIR, to partition managed apps out."
    } > "$managed_source"
  fi

  : > "$known_md_tmp"
  : > "$managed_md_tmp"
  : > "$related_md_tmp"
  : > "$supported_lookup"

  # toolkit-supported-candidates.tsv is the subset of installed apps this toolkit
  # can back up (script or runbook). related-app-review.tsv holds curated
  # cross-workflow callouts (e.g. Music). Both keep the rich registry schema.
  printf 'app\tphase2d_fit\tinstalled\tinstalled_path\tversion\tsuggested_route\tuse_when\tnon_secret_destination\tsecret_destination\tstate_signals_found\tmanaged_evidence\n' > "$supported_tsv"
  printf 'app\tphase2d_fit\tinstalled\tinstalled_path\tversion\tsuggested_route\tuse_when\tnon_secret_destination\tsecret_destination\tstate_signals_found\tmanaged_evidence\n' > "$review_tsv"

  # Partition detectable registry apps into Known vs Managed, preserving registry
  # order. Each app's managed verdict is looked up in section 03 by bundle
  # basename. Only a strong verdict (managed) is subtracted into the Managed
  # table; a weak verdict (likely: receipt-only) stays a Known candidate, since a
  # lone receipt does not prove management owns it. Terminal (detectable=no) is
  # skipped here. The same pass records a bundle-basename → route lookup so the
  # all-apps candidate list below can mark which installed apps have toolkit support.
  local verdict evidence bpaths bp base res
  while IFS=$'\t' read -r app group how non_secret_dest secret_dest detectable phase_fit route use_when bundle_paths state_paths; do
    IFS=';' read -r -a bpaths <<< "$bundle_paths"
    for bp in "${bpaths[@]}"; do
      printf '%s\t%s\t%s\n' "${bp##*/}" "$app" "$route" >> "$supported_lookup"
    done
    [[ "$detectable" == "yes" ]] || continue
    verdict=""
    evidence=""
    if [[ -n "$managed_03" && -f "$managed_03" ]]; then
      for bp in "${bpaths[@]}"; do
        base="${bp##*/}"
        res="$(managed_verdict_from_03 "$managed_03" "$base")"
        if [[ -n "$res" ]]; then
          verdict="${res%%"$TAB"*}"
          evidence="${res#*"$TAB"}"
          break
        fi
      done
    fi
    if [[ "$verdict" == "managed" ]]; then
      emit_candidate_row "$supported_tsv" "$managed_md_tmp" "$app" "$phase_fit" "$route" "$use_when" "$non_secret_dest" "$secret_dest" "$bundle_paths" "$state_paths" "$evidence"
    else
      emit_candidate_row "$supported_tsv" "$known_md_tmp" "$app" "$phase_fit" "$route" "$use_when" "$non_secret_dest" "$secret_dest" "$bundle_paths" "$state_paths" ""
    fi
  done < <(supported_apps_registry)

  # Related apps belong to other workflows or restore sources.
  emit_candidate_row "$review_tsv" "$related_md_tmp" "Music" "Review separately" "Usually Phase 2B local files, iCloud, or Time Machine" "Local media, playlists, or manually managed library content matter." "$root_display/home-files-backup/home/Music/" "usually none from this route" "/System/Applications/Music.app" "$HOME/Music" ""

  # known-app-candidates.tsv is the full candidate inventory: every installed app
  # under /Applications and ~/Applications, regardless of toolkit support. Each
  # row carries the section 03 managed verdict and whether the toolkit covers it.
  local cand_path cand_base cand_name cand_verdict cand_evidence cand_route cand_supported cand_res
  printf 'app\tinstalled_path\tmanaged_verdict\tmanaged_evidence\ttoolkit_supported\tsuggested_route\n' > "$known_tsv"
  while IFS= read -r cand_path; do
    [[ -z "$cand_path" ]] && continue
    cand_base="${cand_path##*/}"
    cand_name="${cand_base%.app}"
    cand_verdict="none"
    cand_evidence=""
    if [[ -n "$managed_03" && -f "$managed_03" ]]; then
      cand_res="$(managed_verdict_from_03 "$managed_03" "$cand_base")"
      if [[ -n "$cand_res" ]]; then
        cand_verdict="${cand_res%%"$TAB"*}"
        cand_evidence="${cand_res#*"$TAB"}"
      fi
    fi
    cand_route="$(grep -F -- "$cand_base$TAB" "$supported_lookup" 2>/dev/null | head -1 | cut -d"$TAB" -f3 || true)"
    if [[ -n "$cand_route" ]]; then cand_supported="yes"; else cand_supported="no"; fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$cand_name" "$cand_path" "$cand_verdict" "$cand_evidence" "$cand_supported" "$cand_route" >> "$known_tsv"
  done < "$app_all_list"

  rm -f "$supported_lookup"

  cat > "$summary_md" <<EOF
# App Backup Candidates Review

Generated: $(date '+%Y-%m-%d %H:%M:%S')
Script: $(basename "$0") --candidate-review
Output directory: $out
Managed-inventory bundle: ${managed_bundle:-none found (see raw/managed-inventory-source.txt)}

This helper is **review-only**. Use it to narrow the list of apps worth checking in Phase 2D, then apply the decision criteria in \`backup-apps.md\`.

The curated tables below cover only apps this **toolkit supports** (has a script or runbook for). The **complete** installed-app inventory — every app regardless of toolkit support, with its managed verdict — is in \`known-app-candidates.tsv\`; the toolkit-supported subset is in \`toolkit-supported-candidates.tsv\`.

## How to use this artifact

1. Work the **Known Phase 2D candidates** — the toolkit-supported apps to decide on. Apps with only a weak, receipt-only signal stay here on purpose.
2. Skim **Managed — likely restored by IT**: management almost certainly brings these back, so review them only for local-only user state it will not restore.
3. Skip anything not installed or not worth preserving.
4. Use **related apps to review manually** when an app looks important but probably belongs to another workflow or restore source.
5. Open \`known-app-candidates.tsv\` to sweep **every** installed app (not just toolkit-supported ones) — sort by \`toolkit_supported\` to find apps you may need to back up by hand.

## Known Phase 2D candidates

| App | Installed | Phase 2D fit | Suggested route | State signals found |
|---|---|---|---|---|
EOF
  if [[ -s "$known_md_tmp" ]]; then
    cat "$known_md_tmp" >> "$summary_md"
  else
    echo "| _none — every detected candidate matched the managed inventory_ | | | | |" >> "$summary_md"
  fi

  cat >> "$summary_md" <<EOF

## Managed — likely restored by IT

These apps carry a **strong** managed signal in the managed-inventory section 03 verdict — a configuration profile, a managed preference, or the corporate-tooling filter — so management will almost certainly reinstall them. They are moved out of the candidate list above. Apps with only a weak, receipt-only signal are **not** listed here; they stay in the candidate list, because a lone package receipt (pkg-installed) does not prove management owns the app. The Managed evidence column shows which signals matched. **Still review each for local-only user state** management will not restore — a managed reinstall brings back the app, not necessarily your settings.

| App | Installed | Managed evidence | Phase 2D fit | Suggested route | State signals found |
|---|---|---|---|---|---|
EOF
  if [[ -s "$managed_md_tmp" ]]; then
    cat "$managed_md_tmp" >> "$summary_md"
  elif [[ -n "$managed_bundle" ]]; then
    echo "| _none — no covered app matched the managed inventory_ | | | | | |" >> "$summary_md"
  else
    echo "| _managed inventory not consulted — see raw/managed-inventory-source.txt_ | | | | | |" >> "$summary_md"
  fi

  cat >> "$summary_md" <<'EOF'

## Related apps to review manually

These apps often matter during a reimage, but they usually belong to another workflow or restore source rather than the main Phase 2D app-backup runbook.

| App | Installed | Phase 2D fit | Suggested route | State signals found |
|---|---|---|---|---|
EOF
  cat "$related_md_tmp" >> "$summary_md"

  cat >> "$summary_md" <<EOF

## Data files

Candidate tables (curated):

- \`known-app-candidates.tsv\` — **every** installed app under /Applications and ~/Applications, regardless of toolkit support. Columns: app, installed_path, managed_verdict, managed_evidence, toolkit_supported, suggested_route.
- \`toolkit-supported-candidates.tsv\` — the subset above that this toolkit can back up (script or runbook), with full Phase 2D detail.
- \`related-app-review.tsv\` — apps that usually belong to another workflow or restore source (e.g. Music).

Raw scan files:

- \`raw/applications-root.txt\`
- \`raw/applications-user.txt\`
- \`raw/applications-all.txt\`
- \`raw/state-signal-paths.txt\`
- \`raw/managed-apps-detected.txt\`
- \`raw/managed-inventory-source.txt\`

## Notes

- This helper does **not** decide whether an app belongs in Phase 2D. It inventories every installed app, marks which the toolkit supports, partitions out apps company management already owns, and lists nearby review targets.
- \`known-app-candidates.tsv\` is the full candidate universe; the curated tables and \`toolkit-supported-candidates.tsv\` are the toolkit-supported slice of it. An app with \`toolkit_supported=no\` is yours to back up by hand.
- The managed partition is **read from** the managed-inventory bundle's section 03 verdict (\`03-installed-app-bundles.txt\`) — the single authoritative per-app managed call written by \`capture-managed-inventory.sh\`. This review does not compute its own; the two never disagree.
- Only a strong verdict (profile, managed preference, or corporate-tooling filter) is subtracted. A weak, receipt-only verdict is left in the candidate list, since "installed via a package" is not "managed".
- Company-managed apps may reinstall automatically but still leave user-specific state unresolved. Review the managed table for local-only state, and see \`capture-managed-inventory.md\` for the underlying evidence.
- Apple/system apps are not exhaustively classified here. Review them manually when local libraries or local-only media matter.
EOF

  rm -f "$known_md_tmp" "$managed_md_tmp" "$related_md_tmp"
}

if [[ "$DOCKER_ONLY" == true || "$INTELLIJ_ONLY" == true || "$VSCODE_ONLY" == true ]]; then
  CANDIDATE_REVIEW_STATUS="Skipped by single-app rerun mode"
elif [[ "$RUN_CANDIDATE_REVIEW" == true ]]; then
  generate_candidate_review
  CANDIDATE_REVIEW_STATUS="Generated candidate-review bundle under app-settings-backup/candidate-review/"
fi

cat > "$APP_ROOT/MANIFEST.md" <<EOF
# App Backup Manifest

Generated: $STAMP
Artifact root: $REIMAGE_ARTIFACT_ROOT

## Scripted work completed

| Item | Status |
|---|---|
| Standard app-backup directories prepared | Complete |
| Docker helper | $DOCKER_STATUS |
| IntelliJ helper | $INTELLIJ_STATUS |
| VS Code local fallback capture | $VSCODE_STATUS |
| Candidate review helper | $CANDIDATE_REVIEW_STATUS |

## Primary Phase 2D locations

\`\`\`text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/
\`\`\`

## Manual or app-controlled follow-up still required when applicable

- Chrome bookmarks export and optional password CSV staging
- Postman collections, environment exports, and optional vault export handling
- Raycast export review and any secret-bearing quicklinks handling
- Obsidian restore-source decision and any manual vault copy
- IntelliJ settings ZIP export from the dedicated IntelliJ companion runbook when applicable

## Notes

- Treat this manifest as the stable Phase 2D summary.
- Use \`backup-apps.md\` for the manual or app-controlled steps that the script cannot complete.
- Use \`reimage-prep-checks.md\` later in Phase 4 only for the manual rows that remain after reviewing the generated \`reimage-checklist.sh --phase pre\` report.
EOF

echo "Prepared Phase 2D app backup root: $APP_ROOT"
echo "Wrote manifest: $APP_ROOT/MANIFEST.md"
echo "Docker helper: $DOCKER_STATUS"
echo "IntelliJ helper: $INTELLIJ_STATUS"
echo "VS Code capture: $VSCODE_STATUS"
if [[ "$RUN_CANDIDATE_REVIEW" == true ]]; then
  echo "Candidate review: $CANDIDATE_REVIEW_STATUS"
  echo "Candidate review output: $CANDIDATE_REVIEW_DIR"
fi

if $OPEN_AFTER; then
  [[ -n "$CANDIDATE_REVIEW_DIR" ]] && open "$CANDIDATE_REVIEW_DIR" 2>/dev/null || true
  open "$APP_ROOT" 2>/dev/null || true
fi
