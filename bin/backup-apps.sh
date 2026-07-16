#!/usr/bin/env bash
# =============================================================================
# backup-apps.sh
#
# Phase 2C app-backup entrypoint: automates the safe steps that don't require
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
#   ./bin/backup-apps.sh --candidate-review
#
#   # Rerun a single portion through this entrypoint
#   ./bin/backup-apps.sh --docker-only
#   ./bin/backup-apps.sh --intellij-only
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
#   --docker-only            Rerun only the Docker portion through this entrypoint.
#   --intellij-only          Rerun only the IntelliJ portion through this entrypoint.
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

OPEN_AFTER=false
RUN_CANDIDATE_REVIEW=false
DOCKER_ONLY=false
INTELLIJ_ONLY=false
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
    --docker-only) DOCKER_ONLY=true; shift ;;
    --intellij-only) INTELLIJ_ONLY=true; shift ;;
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

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set." >&2
  echo "Create/source reimage.env or pass --artifact-root PATH." >&2
  exit 2
fi

if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: artifact root not found: $REIMAGE_ARTIFACT_ROOT" >&2
  exit 2
fi

if [[ "$DOCKER_ONLY" == true && "$INTELLIJ_ONLY" == true ]]; then
  echo "ERROR: choose only one of --docker-only or --intellij-only" >&2
  exit 2
fi

if [[ ("$DOCKER_ONLY" == true || "$INTELLIJ_ONLY" == true) && "$RUN_CANDIDATE_REVIEW" == true ]]; then
  echo "ERROR: --candidate-review cannot be combined with --docker-only or --intellij-only" >&2
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
elif [[ -f "$DOCKER_HELPER" ]]; then
  if [[ -d "/Applications/Docker.app" ]] || [[ -d "$HOME/Library/Group Containers/group.com.docker" ]] || [[ -f "$HOME/.docker/config.json" ]] || command -v docker >/dev/null 2>&1; then
    bash "$DOCKER_HELPER" "$APP_ROOT/docker"
    DOCKER_STATUS="Captured to app-settings-backup/docker/ and secrets-encrypted/docker/ when available"
  else
    DOCKER_STATUS="Skipped; Docker Desktop state not detected on this Mac"
  fi
else
  DOCKER_STATUS="Skipped; .internal/apps/backup-docker-settings.sh not found"
fi

INTELLIJ_HELPER="$(dirname "$SCRIPT_DIR")/.internal/apps/backup-intellij-scratches-consoles.sh"
INTELLIJ_HELPER_ARGS=(--artifact-root "$REIMAGE_ARTIFACT_ROOT")
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

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$app" \
    "$phase_fit" \
    "$installed" \
    "$installed_path" \
    "$version" \
    "$route" \
    "$use_when" \
    "$non_secret_dest" \
    "$secret_dest" \
    "$state_inline" >> "$file"

  printf '| %s | %s | %s | %s | %s |\n' \
    "$app" \
    "$installed_label" \
    "$phase_fit" \
    "$route" \
    "$state_md" >> "$summary_file"
}

generate_candidate_review() {
  local out raw app_root_list app_user_list app_all_list known_tsv review_tsv summary_md state_signals root_display

  out="$APP_ROOT/candidate-review/app-backup-candidates-$(date +%Y%m%d-%H%M%S)"
  raw="$out/raw"
  mkdir -p "$raw"
  CANDIDATE_REVIEW_DIR="$out"

  app_root_list="$raw/applications-root.txt"
  app_user_list="$raw/applications-user.txt"
  app_all_list="$raw/applications-all.txt"
  known_tsv="$out/known-app-candidates.tsv"
  review_tsv="$out/related-app-review.tsv"
  summary_md="$out/app-backup-candidates.md"
  state_signals="$raw/state-signal-paths.txt"
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

  cat > "$summary_md" <<EOF
# App Backup Candidates Review

Generated: $(date '+%Y-%m-%d %H:%M:%S')
Script: $(basename "$0") --candidate-review
Output directory: $out

This helper is **review-only**. Use it to narrow the list of apps worth checking in Phase 2C, then apply the decision criteria in \`backup-apps.md\`.

## How to use this artifact

1. Review **known Phase 2C candidates** first.
2. Skip anything not installed or not worth preserving.
3. Use **related apps to review manually** when an app looks important but probably belongs to another workflow or restore source.
4. Use the raw installed-app and state-signal files under \`raw/\` if you want a wider scan than the curated tables.

## Known Phase 2C candidates

| App | Installed | Phase 2C fit | Suggested route | State signals found |
|---|---|---|---|---|
EOF

  printf 'app\tphase2c_fit\tinstalled\tinstalled_path\tversion\tsuggested_route\tuse_when\tnon_secret_destination\tsecret_destination\tstate_signals_found\n' > "$known_tsv"
  emit_candidate_row "$known_tsv" "$summary_md" "IntelliJ IDEA" "Common — dedicated runbook" "backup-intellij.md" "IDE state, Scratches, settings export, plugins, project metadata, or HTTP Client env files matter." "$root_display/app-settings-backup/intellij/" "$root_display/secrets-encrypted/" "/Applications/IntelliJ IDEA.app;$HOME/Applications/IntelliJ IDEA.app" "$HOME/Library/Application Support/JetBrains;$HOME/Library/Preferences/JetBrains"
  emit_candidate_row "$known_tsv" "$summary_md" "Docker Desktop" "Common" "backup-apps.md" "Docker Desktop settings, contexts, image inventory, or container inventory matter." "$root_display/app-settings-backup/docker/" "$root_display/secrets-encrypted/docker/" "/Applications/Docker.app;$HOME/Applications/Docker.app" "$HOME/Library/Group Containers/group.com.docker;$HOME/Library/Containers/com.docker.docker"
  emit_candidate_row "$known_tsv" "$summary_md" "Chrome" "Common" "backup-apps.md" "Bookmarks export or password export is needed." "$root_display/app-settings-backup/chrome/" "$root_display/secrets-encrypted/chrome/" "/Applications/Google Chrome.app;$HOME/Applications/Google Chrome.app" "$HOME/Library/Application Support/Google/Chrome;$HOME/Library/Preferences/com.google.Chrome.plist"
  emit_candidate_row "$known_tsv" "$summary_md" "Postman" "Common" "backup-apps.md" "Collections, environments, or Vault state matter." "$root_display/app-settings-backup/postman/" "$root_display/secrets-encrypted/postman/" "/Applications/Postman.app;$HOME/Applications/Postman.app" "$HOME/Library/Application Support/Postman;$HOME/Library/Preferences/com.postmanlabs.mac.plist"
  emit_candidate_row "$known_tsv" "$summary_md" "Raycast" "Optional" "backup-apps.md" "Quick Links or settings/data export matter." "$root_display/app-settings-backup/raycast/" "$root_display/secrets-encrypted/raycast/" "/Applications/Raycast.app;$HOME/Applications/Raycast.app" "$HOME/Library/Application Support/com.raycast.macos;$HOME/Library/Preferences/com.raycast.macos.plist"
  emit_candidate_row "$known_tsv" "$summary_md" "Obsidian" "Optional" "backup-apps.md" "Vault content, vault-local config, or restore-source choice matters." "$root_display/app-settings-backup/obsidian/" "usually none from this runbook" "/Applications/Obsidian.app;$HOME/Applications/Obsidian.app" "$HOME/Library/Application Support/obsidian"
  emit_candidate_row "$known_tsv" "$summary_md" "Visual Studio Code" "Optional" "backup-apps.md" "Extensions, settings, snippets, profiles, or a local fallback beyond Settings Sync matter." "$root_display/app-settings-backup/vscode/" "usually none from this runbook" "/Applications/Visual Studio Code.app;$HOME/Applications/Visual Studio Code.app" "$HOME/Library/Application Support/Code;$HOME/Library/Preferences/com.microsoft.VSCode.plist"

  cat >> "$summary_md" <<'EOF'

## Related apps to review manually

These apps often matter during a reimage, but they usually belong to another workflow or restore source rather than the main Phase 2C app-backup runbook.

| App | Installed | Phase 2C fit | Suggested route | State signals found |
|---|---|---|---|---|
EOF

  printf 'app\tphase2c_fit\tinstalled\tinstalled_path\tversion\tsuggested_route\tuse_when\tnon_secret_destination\tsecret_destination\tstate_signals_found\n' > "$review_tsv"
  emit_candidate_row "$review_tsv" "$summary_md" "Music" "Review separately" "Usually Phase 2B local files, iCloud, or Time Machine" "Local media, playlists, or manually managed library content matter." "$root_display/home-files-backup/home/Music/" "usually none from this route" "/System/Applications/Music.app" "$HOME/Music"

  cat >> "$summary_md" <<EOF

## Raw review files

- \`raw/applications-root.txt\`
- \`raw/applications-user.txt\`
- \`raw/applications-all.txt\`
- \`raw/state-signal-paths.txt\`
- \`known-app-candidates.tsv\`
- \`related-app-review.tsv\`

## Notes

- This helper does **not** decide whether an app belongs in Phase 2C. It only collects likely candidates and nearby review targets.
- Company-managed apps may reinstall automatically but still leave user-specific state unresolved. Use \`capture-managed-inventory.md\` when you need managed-state evidence.
- Apple/system apps are not exhaustively classified here. Review them manually when local libraries or local-only media matter.
EOF
}

if [[ "$DOCKER_ONLY" == true || "$INTELLIJ_ONLY" == true ]]; then
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

## Primary Phase 2C locations

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

- Treat this manifest as the stable Phase 2C summary.
- Use \`backup-apps.md\` for the manual or app-controlled steps that the script cannot complete.
- Use \`reimage-prep-checks.md\` later in Phase 4 only for the manual rows that remain after reviewing the generated \`reimage-checklist.sh --phase pre\` report.
EOF

echo "Prepared Phase 2C app backup root: $APP_ROOT"
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
