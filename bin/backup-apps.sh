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
#   # Step 3 -- scan, build the candidate bundle, and generate/refresh the
#   # app-backup selection checklist (writes no backups, no MANIFEST.md)
#   ./bin/backup-apps.sh --candidate-review
#
#   # Step 4 -- back up the apps you checked in the selection checklist
#   # (requires app-settings-backup/app-backup-selection.md; run Step 3 first)
#   ./bin/backup-apps.sh
#
#   # Back up everything detected, bypassing the selection checklist
#   ./bin/backup-apps.sh --all-detected
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
#   ./bin/backup-apps.sh --apps-only     # only the registry-driven app-config captures
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
#   --preflight             Report the resolved config, the artifact root, and
#                           whether the checklist and managed inventory exist,
#                           then exit. Creates nothing — not the artifact root,
#                           not app-settings-backup/. The only mode safe to run
#                           against a root you have not committed to.
#   --docker-only            Rerun only the Docker portion through this entrypoint.
#   --intellij-only          Rerun only the IntelliJ portion through this entrypoint.
#   --vscode-only            Rerun only the VS Code fallback capture through this entrypoint.
#   --apps-only              Rerun only the registry-driven app-config captures
#                            (Claude, draw.io, Zoom, Mos, Wireshark, ...) through
#                            this entrypoint.
#   --all-detected           Full run that backs up every detected supported app,
#                            bypassing the app-backup selection checklist. Without
#                            it, a full run reads the checklist and backs up only
#                            the apps you checked (and errors if it is missing).
#
# Selection checklist:
#   A full run (no --*-only flag) is driven by:
#     $REIMAGE_ARTIFACT_ROOT/app-settings-backup/app-backup-selection.md
#   --candidate-review generates/refreshes it with two selectable sections —
#   supported apps and unsupported apps present on this Mac. Check the apps to
#   act on, then run a full backup. Single-app reruns and --all-detected bypass it.
#
# IntelliJ options passed through to the internal helper:
#   --intellij-projects-root PATH
#   --intellij-projects-max-depth N
#   --intellij-all-config-dirs
#   --intellij-skip-project-scan
#   --intellij-include-shelf
#   --intellij-include-system-cache
#
# Options:
#   --artifact-root PATH   Override the artifact root for this invocation. By
#                          default it is resolved automatically from reimage.env
#                          (via shared config), so you normally omit this.
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
#   1  Ran to completion but a helper or copy step failed. The failing helper
#      and its own exit code are named in the summary and in MANIFEST.md.
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
  # --supported-apps (all rows), the candidate review (detectable rows only),
  # and the registry-driven capture loop, so the covered-app list lives in
  # exactly one place. Tab-delimited fields:
  #   app  group  how  non_secret_dest  secret_dest
  #   detectable  phase_fit  route  use_when  bundle_paths  state_paths
  #   capture_paths  secret_capture_paths
  # The candidate review's managed partition is keyed off each app's bundle
  # basename (from bundle_paths) against the managed-inventory section 03 verdict,
  # so no per-app managed-match list is kept here.
  #
  # capture_paths / secret_capture_paths are ';'-delimited absolute sources the
  # registry-driven helper (backup-app-config.sh) copies when the app is
  # detected: capture_paths -> app-settings-backup/<app>/, secret_capture_paths
  # -> secrets-encrypted/<app>/. Both are "-" (the "none" sentinel) for apps
  # handled another way:
  #   - dedicated helpers/logic: Docker, IntelliJ IDEA, Visual Studio Code
  #   - manual app-UI exports:   Chrome, Postman, Terminal, Raycast, Obsidian,
  #                              Fiddler Everywhere, TNAS PC
  #   - note-only (no state):    4K Live Wallpaper, NexiGo Webcam Settings
  # A missing source is skipped at capture time, so a single registry row is
  # safe on any Mac.
  #
  # IMPORTANT: every field must be non-empty — use "-" for "none", never "".
  # Readers split rows with `IFS=$'\t' read`, and a literal tab is IFS
  # whitespace, so two consecutive tabs (an empty field) collapse into one and
  # shift every later field left. Keeping all fields non-empty avoids that.
  local r="${REIMAGE_ARTIFACT_ROOT:-}"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "IntelliJ IDEA" "Common" "Script + manual settings ZIP" "$r/app-settings-backup/intellij/" "$r/secrets-encrypted/" \
    "yes" "Common — dedicated runbook" "backup-intellij.md" "IDE state, Scratches, settings export, plugins, project metadata, or HTTP Client env files matter." "/Applications/IntelliJ IDEA.app;$HOME/Applications/IntelliJ IDEA.app" "$HOME/Library/Application Support/JetBrains;$HOME/Library/Preferences/JetBrains" \
    "-" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Docker Desktop" "Common" "Script" "$r/app-settings-backup/docker/" "$r/secrets-encrypted/docker/" \
    "yes" "Common" "backup-apps.md" "Docker Desktop settings, contexts, image inventory, or container inventory matter." "/Applications/Docker.app;$HOME/Applications/Docker.app" "$HOME/Library/Group Containers/group.com.docker;$HOME/Library/Containers/com.docker.docker" \
    "-" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Chrome" "Common" "Manual" "$r/app-settings-backup/chrome/" "$r/secrets-encrypted/chrome/" \
    "yes" "Common" "backup-apps.md" "Bookmarks export or password export is needed." "/Applications/Google Chrome.app;$HOME/Applications/Google Chrome.app" "$HOME/Library/Application Support/Google/Chrome;$HOME/Library/Preferences/com.google.Chrome.plist" \
    "-" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Postman" "Common" "Manual" "$r/app-settings-backup/postman/" "$r/secrets-encrypted/postman/" \
    "yes" "Common" "backup-apps.md" "Collections, environments, or Vault state matter." "/Applications/Postman.app;$HOME/Applications/Postman.app" "$HOME/Library/Application Support/Postman;$HOME/Library/Preferences/com.postmanlabs.mac.plist" \
    "-" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Claude" "Common" "Script — MCP config staged as secret; account via sign-in" "$r/app-settings-backup/claude/" "$r/secrets-encrypted/claude/" \
    "yes" "Common" "backup-apps.md" "MCP server config or Claude Desktop developer settings matter." "/Applications/Claude.app;$HOME/Applications/Claude.app" "$HOME/Library/Application Support/Claude;$HOME/Library/Preferences/com.anthropic.claudefordesktop.plist" \
    "-" "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "draw.io" "Common" "Script — app config; diagrams restored as files" "$r/app-settings-backup/drawio/" "usually none from this runbook" \
    "yes" "Common" "backup-apps.md" "App config or custom shape libraries matter; diagrams themselves come back via Phase 2B / Git." "/Applications/draw.io.app;$HOME/Applications/draw.io.app" "$HOME/Library/Application Support/draw.io;$HOME/Library/Preferences/com.jgraph.drawio.desktop.plist" \
    "$HOME/Library/Application Support/draw.io/config.json;$HOME/Library/Application Support/draw.io/Preferences;$HOME/Library/Preferences/com.jgraph.drawio.desktop.plist" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Fiddler Everywhere" "Common" "Manual — session/AutoResponder export; secret-bearing" "$r/app-settings-backup/fiddler-everywhere/" "$r/secrets-encrypted/fiddler-everywhere/" \
    "yes" "Common" "backup-apps.md" "Saved sessions, composed requests, or AutoResponder rules matter; settings sync to your Progress account." "/Applications/Fiddler Everywhere.app;$HOME/Applications/Fiddler Everywhere.app" "$HOME/.fiddler;$HOME/Library/Application Support/Fiddler Everywhere" \
    "-" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Zoom" "Common" "Script — settings plist; restore mainly via sign-in" "$r/app-settings-backup/zoom/" "usually none from this runbook" \
    "yes" "Common" "backup-apps.md" "Local Zoom client settings matter; account and most preferences return on sign-in, recordings belong to Phase 2B." "/Applications/zoom.us.app;$HOME/Applications/zoom.us.app" "$HOME/Library/Application Support/zoom.us;$HOME/Library/Preferences/us.zoom.xos.plist" \
    "$HOME/Library/Preferences/us.zoom.xos.plist" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "BBEdit" "Common" "Script — app config and preferences" "$r/app-settings-backup/bbedit/" "usually none from this runbook" \
    "yes" "Common" "backup-apps.md" "Custom BBEdit scripts, text filters, language modules, clippings, color schemes, or preferences matter." "/Applications/BBEdit.app;$HOME/Applications/BBEdit.app" "$HOME/Library/Application Support/BBEdit;$HOME/Library/Preferences/com.barebones.bbedit.plist" \
    "$HOME/Library/Application Support/BBEdit;$HOME/Library/Preferences/com.barebones.bbedit.plist;$HOME/Library/Containers/com.barebones.bbedit/Data/Library/Application Support/BBEdit" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Raycast" "Optional" "Manual" "$r/app-settings-backup/raycast/" "$r/secrets-encrypted/raycast/" \
    "yes" "Optional" "backup-apps.md" "Quick Links or settings/data export matter." "/Applications/Raycast.app;$HOME/Applications/Raycast.app" "$HOME/Library/Application Support/com.raycast.macos;$HOME/Library/Preferences/com.raycast.macos.plist" \
    "-" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Obsidian" "Optional" "Manual" "$r/app-settings-backup/obsidian/" "usually none from this runbook" \
    "yes" "Optional" "backup-apps.md" "Vault content, vault-local config, or restore-source choice matters." "/Applications/Obsidian.app;$HOME/Applications/Obsidian.app" "$HOME/Library/Application Support/obsidian" \
    "-" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Mos" "Optional" "Script — preferences plist" "$r/app-settings-backup/mos/" "usually none from this runbook" \
    "yes" "Optional" "backup-apps.md" "Custom scroll settings or per-app scroll exceptions matter." "/Applications/Mos.app;$HOME/Applications/Mos.app" "$HOME/Library/Preferences/com.caldis.Mos.plist" \
    "$HOME/Library/Preferences/com.caldis.Mos.plist" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Wireshark" "Optional" "Script — profiles and config" "$r/app-settings-backup/wireshark/" "usually none from this runbook" \
    "yes" "Optional" "backup-apps.md" "Custom profiles, capture/display filters, or coloring rules matter." "/Applications/Wireshark.app;$HOME/Applications/Wireshark.app" "$HOME/.config/wireshark;$HOME/.wireshark" \
    "$HOME/.config/wireshark;$HOME/.wireshark" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "iMovie" "Optional" "Manual — libraries are user files (Phase 2B)" "$r/app-settings-backup/imovie/" "usually none from this runbook" \
    "yes" "Optional" "backup-apps.md" "You keep iMovie projects or libraries and need to confirm they are backed up as local files." "/Applications/iMovie.app;$HOME/Applications/iMovie.app" "$HOME/Movies/iMovie Library.imovielibrary;$HOME/Library/Containers/com.apple.iMovieApp" \
    "-" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "TNAS PC" "Optional" "Manual — reconnect/re-auth; credentials secret-bearing" "$r/app-settings-backup/tnas-pc/" "$r/secrets-encrypted/tnas-pc/" \
    "yes" "Optional" "backup-apps.md" "Saved TNAS connection profiles matter; stored credentials are secret-bearing." "/Applications/TNAS PC.app;$HOME/Applications/TNAS PC.app" "$HOME/Library/Application Support/TNAS PC" \
    "-" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "4K Live Wallpaper" "Optional" "Note only — no meaningful local state; reconfigure after reimage" "none" "none" \
    "yes" "Optional" "backup-apps.md" "Cosmetic only; re-select wallpapers after reimage." "/Applications/4K Live Wallpaper.app;$HOME/Applications/4K Live Wallpaper.app" "-" \
    "-" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "NexiGo Webcam Settings" "Optional" "Note only — no meaningful local state; reconfigure after reimage" "none" "none" \
    "yes" "Optional" "backup-apps.md" "Webcam presets are quick to redo; reconfigure after reimage." "/Applications/NexiGo Webcam Settings.app;$HOME/Applications/NexiGo Webcam Settings.app" "-" \
    "-" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Visual Studio Code" "Common" "Script" "$r/app-settings-backup/vscode/" "usually none from this runbook" \
    "yes" "Optional" "backup-apps.md" "Extensions, settings, snippets, profiles, or a local fallback beyond Settings Sync matter." "/Applications/Visual Studio Code.app;$HOME/Applications/Visual Studio Code.app" "$HOME/Library/Application Support/Code;$HOME/Library/Preferences/com.microsoft.VSCode.plist" \
    "-" "-"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "Terminal" "Common" "Manual" "$r/app-settings-backup/terminal/" "none" \
    "yes" "Common" "backup-apps.md" "Custom Terminal.app profile (colors, font, window size) worth preserving." "/System/Applications/Utilities/Terminal.app;/Applications/Utilities/Terminal.app" "$HOME/Library/Preferences/com.apple.Terminal.plist" \
    "-" "-"
}

print_supported_apps() {
  # Info only: writes nothing and computes no sizes (sizing is the sole
  # responsibility of report-size-audit.sh).
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
APPS_ONLY=false
ALL_DETECTED=false
SHOW_SUPPORTED=false
SHOW_PREFLIGHT=false
INTELLIJ_ALL_CONFIG_DIRS=false
INTELLIJ_INCLUDE_SYSTEM_CACHE=false
INTELLIJ_SKIP_WORKSPACES=false
INTELLIJ_INCLUDE_SHELF=false
INTELLIJ_PROJECTS_ROOT=""
INTELLIJ_WORKSPACE_MAX_DEPTH=""

require_option_value() {
  local option="$1"
  local value="${2:-}"

  if [[ -z "$value" || "$value" == --* ]]; then
    echo "ERROR: $option requires a non-empty value." >&2
    exit 2
  fi
}

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
    --apps-only) APPS_ONLY=true; shift ;;
    --all-detected) ALL_DETECTED=true; shift ;;
    --supported-apps) SHOW_SUPPORTED=true; shift ;;
    --preflight) SHOW_PREFLIGHT=true; shift ;;
    --intellij-projects-root)
      require_option_value "$1" "${2:-}"
      INTELLIJ_PROJECTS_ROOT="$2"; shift 2 ;;
    --intellij-projects-max-depth)
      require_option_value "$1" "${2:-}"
      INTELLIJ_WORKSPACE_MAX_DEPTH="$2"; shift 2 ;;
    --intellij-all-config-dirs) INTELLIJ_ALL_CONFIG_DIRS=true; shift ;;
    --intellij-skip-project-scan) INTELLIJ_SKIP_WORKSPACES=true; shift ;;
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

# --preflight reports what a real run would resolve and use, and creates
# nothing -- not the artifact root, not app-settings-backup/, not
# candidate-review/. It runs before every other mode's mkdir for that reason.
# Every other mode, --candidate-review included, creates app-settings-backup/
# as its first act, so this is the only safe way to inspect an artifact root
# you have not committed to yet.
if [[ "$SHOW_PREFLIGHT" == true ]]; then
  preflight_rc=0
  printf 'Config       : %s\n' "${ARTIFACT_CONFIG_SOURCE_DIR:-<not resolved>}"

  if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    printf 'Artifact root: %s\n' "<not set>"
    printf '\nERROR: REIMAGE_ARTIFACT_ROOT is not set.\n' >&2
    printf 'Create/source reimage.env or pass --artifact-root PATH.\n' >&2
    exit 2
  fi

  printf 'Artifact root: %s\n' "$REIMAGE_ARTIFACT_ROOT"
  if [[ -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
    printf '  exists              : yes\n'
  else
    printf '  exists              : NO — mount the volume or correct reimage.env\n'
    preflight_rc=2
  fi

  # app-settings-backup/ is created by prepare-artifact-root (Phase 1) along
  # with every other expected top-level folder, so its existence says nothing
  # about whether this phase has run. Report on artifacts THIS phase produces.
  if declare -p EXPECTED_ARTIFACT_FOLDERS >/dev/null 2>&1 && (( ${#EXPECTED_ARTIFACT_FOLDERS[@]} > 0 )); then
    _pf_have=0
    for _pf_folder in "${EXPECTED_ARTIFACT_FOLDERS[@]}"; do
      [[ -d "$REIMAGE_ARTIFACT_ROOT/$_pf_folder" ]] && _pf_have=$((_pf_have + 1))
    done
    if (( _pf_have == ${#EXPECTED_ARTIFACT_FOLDERS[@]} )); then
      printf '  prepared (Phase 1)  : yes — %s of %s expected folders present\n' \
        "$_pf_have" "${#EXPECTED_ARTIFACT_FOLDERS[@]}"
    else
      printf '  prepared (Phase 1)  : INCOMPLETE — %s of %s expected folders present\n' \
        "$_pf_have" "${#EXPECTED_ARTIFACT_FOLDERS[@]}"
      printf '                        run prepare-artifact-root before this phase\n'
      preflight_rc=2
    fi
  fi

  _pf_app_root="$REIMAGE_ARTIFACT_ROOT/app-settings-backup"

  if [[ -d "$_pf_app_root/candidate-review" ]] \
     && [[ -n "$(ls -A "$_pf_app_root/candidate-review" 2>/dev/null)" ]]; then
    printf '  candidate review    : present — Step 3 has run\n'
  else
    printf '  candidate review    : none — Step 3 generates it\n'
  fi

  if [[ -f "$_pf_app_root/app-backup-selection.md" ]]; then
    printf '  selection checklist : present\n'
  else
    printf '  selection checklist : none — Step 3 generates it\n'
  fi

  if [[ -f "$_pf_app_root/MANIFEST.md" ]]; then
    printf '  app backup manifest : present — a full run has completed\n'
  else
    printf '  app backup manifest : none — Step 4 writes it\n'
  fi

  if [[ -d "$REIMAGE_ARTIFACT_ROOT/managed-inventory" ]] \
     && [[ -n "$(ls -A "$REIMAGE_ARTIFACT_ROOT/managed-inventory" 2>/dev/null)" ]]; then
    printf '  managed inventory   : present — Phase 2C has run\n'
  else
    printf '  managed inventory   : empty — run Phase 2C first for managed-app partitioning\n'
  fi

  printf '\nNothing was created by this check.\n'
  exit "$preflight_rc"
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
[[ "$APPS_ONLY" == true ]] && ONLY_COUNT=$((ONLY_COUNT + 1))

if (( ONLY_COUNT > 1 )); then
  echo "ERROR: choose only one of --docker-only, --intellij-only, --vscode-only, or --apps-only" >&2
  exit 2
fi

if (( ONLY_COUNT > 0 )) && [[ "$RUN_CANDIDATE_REVIEW" == true ]]; then
  echo "ERROR: --candidate-review cannot be combined with --docker-only, --intellij-only, --vscode-only, or --apps-only" >&2
  exit 2
fi

APP_ROOT="$REIMAGE_ARTIFACT_ROOT/app-settings-backup"
STAMP="$(date '+%Y-%m-%d %H:%M:%S')"
CANDIDATE_REVIEW_DIR=""

# The app-backup selection checklist is the authoritative input for a full run:
# Step 3 (--candidate-review) generates it, the user checks apps, and Step 4
# reads it here. See .internal/apps/app-selection.sh.
SELECTION_HELPER="$(dirname "$SCRIPT_DIR")/.internal/apps/app-selection.sh"
SELECTION_FILE="$APP_ROOT/app-backup-selection.md"

# Classify this invocation. A "full run" is the real backup with no single-app
# rerun flag and not the scan-only candidate review. Selection gating is active
# on a full run unless --all-detected explicitly bypasses the checklist.
FULL_RUN=false
if [[ "$RUN_CANDIDATE_REVIEW" != true && "$DOCKER_ONLY" != true \
      && "$INTELLIJ_ONLY" != true && "$VSCODE_ONLY" != true && "$APPS_ONLY" != true ]]; then
  FULL_RUN=true
fi
SELECTION_ACTIVE=false
if [[ "$FULL_RUN" == true && "$ALL_DETECTED" != true ]]; then
  SELECTION_ACTIVE=true
fi

# A full, checklist-driven run needs the checklist. Fail early with guidance
# rather than silently backing up everything (or nothing).
if [[ "$SELECTION_ACTIVE" == true && ! -f "$SELECTION_FILE" ]]; then
  echo "ERROR: no app-backup selection checklist found:" >&2
  echo "  $SELECTION_FILE" >&2
  echo "Generate it first (Step 3 — Determine Which Apps to Back Up):" >&2
  echo "  ./bin/backup-apps.sh --candidate-review" >&2
  echo "Then check the apps to back up in that file and re-run, or pass" >&2
  echo "--all-detected to back up everything detected without a checklist." >&2
  exit 2
fi

# Load the current selections once. Empty when not a checklist-driven run. The
# three supported sections — automatic, both (automatic+manual), and manual — are
# all supported apps for backup purposes; they are separated in the checklist only
# to show the mechanism. Unsupported is a distinct category (drop-folders).
SELECTED_AUTOMATIC=""
SELECTED_BOTH=""
SELECTED_MANUAL=""
# Set by prune_empty_app_dirs, which only runs on a full run. Declared here
# because the summary reads it unconditionally and `set -u` would abort a
# candidate-review or --*-only run otherwise.
PRUNED_APP_DIRS=""
SELECTED_UNSUPPORTED=""
if [[ "$SELECTION_ACTIVE" == true ]]; then
  SELECTED_AUTOMATIC="$(bash "$SELECTION_HELPER" --list-selected --selection "$SELECTION_FILE" --section automatic || true)"
  SELECTED_BOTH="$(bash "$SELECTION_HELPER" --list-selected --selection "$SELECTION_FILE" --section both || true)"
  SELECTED_MANUAL="$(bash "$SELECTION_HELPER" --list-selected --selection "$SELECTION_FILE" --section manual || true)"
  SELECTED_UNSUPPORTED="$(bash "$SELECTION_HELPER" --list-selected --selection "$SELECTION_FILE" --section unsupported || true)"
fi

# is_selected_supported NAME — is a supported app (by registry name) chosen for
# backup? Checks all three supported sections (automatic, both, manual).
# Selection gates only the checklist-driven run; single-app reruns and
# --all-detected bypass it, so every detected app is eligible there.
is_selected_supported() {
  [[ "$SELECTION_ACTIVE" == true ]] || return 0
  local name="$1" line
  while IFS= read -r line; do
    [[ "$line" == "$name" ]] && return 0
  done <<< "$SELECTED_AUTOMATIC"
  while IFS= read -r line; do
    [[ "$line" == "$name" ]] && return 0
  done <<< "$SELECTED_BOTH"
  while IFS= read -r line; do
    [[ "$line" == "$name" ]] && return 0
  done <<< "$SELECTED_MANUAL"
  return 1
}

# classify_backup_kind HOW — derive the checklist category from the registry
# "how" text (the single source of truth for mechanism). "both" when it names a
# script AND a manual step; otherwise "auto" (script), "manual", or "note".
classify_backup_kind() {
  local h
  h="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$h" in
    note\ only*|*note-only*) printf 'note' ;;
    *script*manual*|*manual*script*) printf 'both' ;;
    *script*) printf 'auto' ;;
    *manual*) printf 'manual' ;;
    *) printf 'auto' ;;
  esac
}

# app_slug NAME — lowercase, non-alphanumeric collapsed to single hyphens.
app_slug() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//'
}

# Always-present roots. Per-app folders are created only for what a run will
# actually back up (see create_selected_app_dirs and the per-app helpers).
mkdir -p "$APP_ROOT"
# candidate-review/ belongs to the candidate review alone. Creating it on every
# invocation left an empty directory behind after --docker-only / --intellij-only
# / --vscode-only / --apps-only runs.
if [[ "$RUN_CANDIDATE_REVIEW" == true ]]; then
  mkdir -p "$APP_ROOT/candidate-review"
fi

# Counts helper invocations that failed, so a run that lost a source can exit 1
# instead of reporting success. Declared here: it is read in the Docker and
# IntelliJ blocks well before the registry captures.
HELPER_FAILURES=0
DOCKER_STATUS="Not run"
INTELLIJ_STATUS="Not run"
VSCODE_STATUS="Not run"
CANDIDATE_REVIEW_STATUS="Not run"

DOCKER_HELPER="$(dirname "$SCRIPT_DIR")/.internal/apps/backup-docker-settings.sh"
if [[ "$INTELLIJ_ONLY" == true ]]; then
  DOCKER_STATUS="Skipped by --intellij-only"
elif [[ "$VSCODE_ONLY" == true ]]; then
  DOCKER_STATUS="Skipped by --vscode-only"
elif [[ "$APPS_ONLY" == true ]]; then
  DOCKER_STATUS="Skipped by --apps-only"
elif [[ "$RUN_CANDIDATE_REVIEW" == true ]]; then
  DOCKER_STATUS="Skipped; candidate-review is scan-only"
elif [[ ! -f "$DOCKER_HELPER" ]]; then
  DOCKER_STATUS="Skipped; .internal/apps/backup-docker-settings.sh not found"
elif ! is_selected_supported "Docker Desktop"; then
  DOCKER_STATUS="Skipped; Docker Desktop not selected in the app-backup checklist"
elif [[ -d "/Applications/Docker.app" ]] || [[ -d "$HOME/Library/Group Containers/group.com.docker" ]] || [[ -f "$HOME/.docker/config.json" ]] || command -v docker >/dev/null 2>&1; then
  # A bare invocation under `set -e` aborted the whole run with the HELPER's
  # exit code, so a Docker prerequisite error (2) surfaced as this script's
  # documented usage error -- and MANIFEST.md was never written.
  if bash "$DOCKER_HELPER" --artifact-root "$REIMAGE_ARTIFACT_ROOT"; then
    DOCKER_STATUS="Captured to app-settings-backup/docker/ and secrets-encrypted/docker/ when available"
  else
    _helper_rc=$?
    DOCKER_STATUS="FAILED -- backup-docker-settings.sh exited $_helper_rc; review the output above"
    HELPER_FAILURES=$((HELPER_FAILURES + 1))
  fi
else
  DOCKER_STATUS="Skipped; Docker Desktop state not detected on this Mac"
fi

INTELLIJ_HELPER="$(dirname "$SCRIPT_DIR")/.internal/apps/backup-intellij-state.sh"
INTELLIJ_HELPER_ARGS=(--artifact-root "$REIMAGE_ARTIFACT_ROOT")
# Default the IntelliJ projects root to the configured work-repo root when the
# caller did not pass --intellij-projects-root, mirroring how backup-repos.sh
# defaults --root to GIT_WORK_REPO_ROOT.
if [[ -z "$INTELLIJ_PROJECTS_ROOT" && -n "${GIT_WORK_REPO_ROOT:-}" ]]; then
  INTELLIJ_PROJECTS_ROOT="$GIT_WORK_REPO_ROOT"
fi
if [[ -n "$INTELLIJ_PROJECTS_ROOT" ]]; then
  INTELLIJ_HELPER_ARGS+=(--projects-root "$INTELLIJ_PROJECTS_ROOT")
fi
if [[ -n "$INTELLIJ_WORKSPACE_MAX_DEPTH" ]]; then
  INTELLIJ_HELPER_ARGS+=(--projects-max-depth "$INTELLIJ_WORKSPACE_MAX_DEPTH")
fi
if [[ "$INTELLIJ_ALL_CONFIG_DIRS" == true ]]; then
  INTELLIJ_HELPER_ARGS+=(--all-config-dirs)
fi
if [[ "$INTELLIJ_SKIP_WORKSPACES" == true ]]; then
  INTELLIJ_HELPER_ARGS+=(--skip-project-scan)
fi
if [[ "$INTELLIJ_INCLUDE_SHELF" == true ]]; then
  INTELLIJ_HELPER_ARGS+=(--include-shelf)
fi
if [[ "$INTELLIJ_INCLUDE_SYSTEM_CACHE" == true ]]; then
  INTELLIJ_HELPER_ARGS+=(--include-system-cache)
fi

if [[ "$INTELLIJ_ONLY" != true ]]; then
  # IntelliJ is deliberately NOT part of the default Phase 2D run. It has
  # prerequisites the umbrella run cannot present in time: a secret-review
  # template and an exclude list that are seeded on first use and may already
  # exist in your workspace from a prior reimage. Capturing it here produced a
  # half-reviewed result with no signal that review had been skipped, so it is
  # opt-in via --intellij-only and owned by backup-intellij.md.
  INTELLIJ_STATUS="Deferred to backup-intellij.md — run ./bin/backup-apps.sh --intellij-only"
elif [[ "$DOCKER_ONLY" == true ]]; then
  INTELLIJ_STATUS="Skipped by --docker-only"
elif [[ "$VSCODE_ONLY" == true ]]; then
  INTELLIJ_STATUS="Skipped by --vscode-only"
elif [[ "$APPS_ONLY" == true ]]; then
  INTELLIJ_STATUS="Skipped by --apps-only"
elif [[ "$RUN_CANDIDATE_REVIEW" == true ]]; then
  INTELLIJ_STATUS="Skipped; candidate-review is scan-only"
elif [[ ! -f "$INTELLIJ_HELPER" ]]; then
  INTELLIJ_STATUS="Skipped; .internal/apps/backup-intellij-state.sh not found"
elif ! is_selected_supported "IntelliJ IDEA"; then
  INTELLIJ_STATUS="Skipped; IntelliJ IDEA not selected in the app-backup checklist"
elif [[ -d "/Applications/IntelliJ IDEA.app" ]] || [[ -d "$HOME/Applications/IntelliJ IDEA.app" ]] || [[ -d "$HOME/Library/Application Support/JetBrains" ]]; then
  if bash "$INTELLIJ_HELPER" "${INTELLIJ_HELPER_ARGS[@]}"; then
    INTELLIJ_STATUS="Captured under app-settings-backup/intellij/ when IntelliJ state was found"
  else
    _helper_rc=$?
    INTELLIJ_STATUS="FAILED -- backup-intellij-state.sh exited $_helper_rc; review the output above"
    HELPER_FAILURES=$((HELPER_FAILURES + 1))
  fi
else
  INTELLIJ_STATUS="Skipped; IntelliJ IDEA state not detected on this Mac"
fi

if [[ "$DOCKER_ONLY" == true || "$INTELLIJ_ONLY" == true || "$APPS_ONLY" == true ]]; then
  VSCODE_STATUS="Skipped by single-app rerun mode"
elif [[ "$RUN_CANDIDATE_REVIEW" == true ]]; then
  VSCODE_STATUS="Skipped; candidate-review is scan-only"
elif ! is_selected_supported "Visual Studio Code"; then
  VSCODE_STATUS="Skipped; Visual Studio Code not selected in the app-backup checklist"
else
  VSCODE_DEST="$APP_ROOT/vscode"
  VSCODE_USER="$HOME/Library/Application Support/Code/User"
  VSCODE_FOUND=false
  mkdir -p "$VSCODE_DEST/user"

  # Extensions list. Read it straight from the on-disk extensions folder rather
  # than `code --list-extensions`: the CLI frequently writes nothing when its
  # stdout is redirected in a non-interactive run. Standard and Insiders builds
  # keep each extension as a publisher.name-version folder under
  # ~/.vscode[-insiders]/extensions, with a manifest at extensions.json.
  EXT_FOUND=false
  for EXT_DIR in "$HOME/.vscode/extensions" "$HOME/.vscode-insiders/extensions"; do
    [[ -d "$EXT_DIR" ]] || continue
    # Primary: folder names -> strip the trailing -version(-platform) suffix.
    # `|| true`: grep exits non-zero when nothing matches (empty/extension-less
    # dir); without it, set -o pipefail + set -e would abort the whole run here.
    find "$EXT_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
      | sed 's#.*/##' \
      | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+.*$//' \
      | grep -E '\.' \
      | sort -u > "$VSCODE_DEST/extensions.txt" || true
    # Fallback: parse publisher.name ids from the manifest (dot-bearing values;
    # GUID-style ids have no dot and are dropped). No jq dependency.
    if [[ ! -s "$VSCODE_DEST/extensions.txt" && -f "$EXT_DIR/extensions.json" ]]; then
      grep -oE '"id"[[:space:]]*:[[:space:]]*"[^"]+"' "$EXT_DIR/extensions.json" 2>/dev/null \
        | sed -E 's/.*:[[:space:]]*"([^"]+)".*/\1/' \
        | grep -E '\.' \
        | sort -u > "$VSCODE_DEST/extensions.txt" || true
    fi
    if [[ -s "$VSCODE_DEST/extensions.txt" ]]; then
      EXT_FOUND=true
      VSCODE_FOUND=true
      break
    fi
  done

  # Last resort: the CLI, only if the on-disk read found nothing.
  if [[ "$EXT_FOUND" != true ]]; then
    CODE_BIN=""
    if command -v code >/dev/null 2>&1; then
      CODE_BIN="$(command -v code)"
    elif [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
      CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    elif [[ -x "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
      CODE_BIN="$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    fi
    if [[ -n "$CODE_BIN" ]]; then
      "$CODE_BIN" --list-extensions > "$VSCODE_DEST/extensions.txt" 2>/dev/null || true
      [[ -s "$VSCODE_DEST/extensions.txt" ]] && VSCODE_FOUND=true
    fi
  fi

  # Do not leave a misleading empty extensions.txt behind.
  if [[ -f "$VSCODE_DEST/extensions.txt" && ! -s "$VSCODE_DEST/extensions.txt" ]]; then
    rm -f "$VSCODE_DEST/extensions.txt"
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
  local -a items=()
  # A registry row may carry the "-" sentinel for this field, normalised to "".
  # On stock macOS Bash 3.2 "${items[@]}" on an empty array errors under set -u.
  # An empty list means "none found", which this function signals with 1.
  [[ -n "$list" ]] || return 1
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
  local -a items=()
  # A registry row may carry the "-" sentinel for this field, normalised to "".
  # On stock macOS Bash 3.2 "${items[@]}" on an empty array errors under set -u.
  # An empty list renders the same as "listed, but nothing exists on disk".
  if [[ -z "$list" ]]; then
    printf '%s' 'none found'
    return 0
  fi
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
  local -a items=()
  # A registry row may carry the "-" sentinel for this field, normalised to "".
  # On stock macOS Bash 3.2 "${items[@]}" on an empty array errors under set -u.
  # An empty list renders the same as "listed, but nothing exists on disk".
  if [[ -z "$list" ]]; then
    printf '%s' 'none found'
    return 0
  fi
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
  local capture_paths secret_capture_paths
  while IFS=$'\t' read -r app group how non_secret_dest secret_dest detectable phase_fit route use_when bundle_paths state_paths capture_paths secret_capture_paths; do
    # Normalize the "none" sentinel so empty-state apps read as "none found".
    [[ "$state_paths" == "-" ]] && state_paths=""
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

  # Generate/refresh the app-backup selection checklist from this scan. Supported
  # present apps come from the toolkit-supported subset (installed==yes); the
  # unsupported-and-present apps are the full-inventory rows the toolkit does not
  # cover. The helper preserves any checks already made and adds new apps unchecked.
  #
  # Company-managed apps are dropped from the unsupported list: a *strong* managed
  # verdict ($3=="managed" in known-app-candidates.tsv) means IT restores the app,
  # so it is not a manual-backup candidate. A weak "likely" (receipt-only) or
  # "none" verdict stays, matching the supported-side Known/Managed partition,
  # since "installed via a package" is not proof of management. The excluded set
  # is recorded under raw/ so nothing is dropped silently. When no managed
  # inventory was consulted, every verdict is "none" and nothing is excluded here.
  # Toolkit-supported installed apps are split into three checklist sections by
  # backup mechanism, derived from each app's registry "how" text (the single
  # source of truth): the script covers it -> automatic; script + a manual step
  # -> both; a manual step but no scripted capture -> manual. Note-only apps have
  # neither and are left off the checklist. This mirrors the runbook: an app is
  # "both" only when it is script-backed AND has a Step 5 manual-export section.
  local sel_automatic="$raw/selection-automatic.txt"
  local sel_both="$raw/selection-both.txt"
  local sel_manual="$raw/selection-manual.txt"
  local sel_unsupported="$raw/selection-unsupported.txt"
  : > "$sel_automatic"; : > "$sel_both"; : > "$sel_manual"
  local _app _grp _how _nsd _sd _det _pf _rt _uw _bp _sp _cp _scp _kind
  while IFS=$'\t' read -r _app _grp _how _nsd _sd _det _pf _rt _uw _bp _sp _cp _scp; do
    [[ "$_det" == "yes" ]] || continue
    [[ -n "$(first_existing_path "$_bp" || true)" ]] || continue
    _kind="$(classify_backup_kind "$_how")"
    case "$_kind" in
      auto)   printf '%s\n' "$_app" >> "$sel_automatic" ;;
      both)   printf '%s\n' "$_app" >> "$sel_both" ;;
      manual) printf '%s\n' "$_app" >> "$sel_manual" ;;
      note)   : ;;  # note-only: no backup and no manual step; left off the checklist
    esac
  done < <(supported_apps_registry)
  sort -u "$sel_automatic" -o "$sel_automatic"
  sort -u "$sel_both" -o "$sel_both"
  sort -u "$sel_manual" -o "$sel_manual"
  awk -F'\t' 'NR>1 && $5=="no" && $3!="managed"{print $1}' "$known_tsv" | sort -u > "$sel_unsupported"
  awk -F'\t' 'NR>1 && $5=="no" && $3=="managed"{print $1"\t"$4}' "$known_tsv" | sort -u \
    > "$raw/unsupported-managed-excluded.txt"
  if [[ -f "$SELECTION_HELPER" ]]; then
    bash "$SELECTION_HELPER" --generate \
      --automatic-list "$sel_automatic" \
      --both-list "$sel_both" \
      --manual-list "$sel_manual" \
      --unsupported-list "$sel_unsupported" \
      --selection "$SELECTION_FILE" \
      --run-hint "./bin/backup-apps.sh" \
      || echo "WARNING: could not generate selection checklist: $SELECTION_FILE" >&2
  else
    echo "WARNING: selection helper not found: $SELECTION_HELPER" >&2
  fi

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
- \`raw/unsupported-managed-excluded.txt\` — unsupported apps left off the selection checklist because they are company-managed (app + evidence)

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

if [[ "$DOCKER_ONLY" == true || "$INTELLIJ_ONLY" == true || "$VSCODE_ONLY" == true || "$APPS_ONLY" == true ]]; then
  CANDIDATE_REVIEW_STATUS="Skipped by single-app rerun mode"
elif [[ "$RUN_CANDIDATE_REVIEW" == true ]]; then
  generate_candidate_review
  CANDIDATE_REVIEW_STATUS="Generated candidate-review bundle under app-settings-backup/candidate-review/"
fi

# ---------------------------------------------------------------------------
# Registry-driven app-config captures
# ---------------------------------------------------------------------------
APP_CONFIG_HELPER="$(dirname "$SCRIPT_DIR")/.internal/apps/backup-app-config.sh"
APP_CONFIG_STATUS="Not run"
APP_CONFIG_FAILURES=0

run_registry_app_captures() {
  # For each registry app that declares capture_paths and/or secret_capture_paths
  # and is detected on this Mac, hand its resolved sources and destinations to
  # backup-app-config.sh. Apps handled by dedicated helpers (Docker/IntelliJ/VS
  # Code), manual app-UI exports, and note-only apps have empty capture columns
  # and are skipped here. Returns 0 if at least one app was captured, else 1.
  local any=false
  local app group how non_secret_dest secret_dest detectable phase_fit route use_when bundle_paths state_paths capture_paths secret_capture_paths
  local present args caps secs p
  while IFS=$'\t' read -r app group how non_secret_dest secret_dest detectable phase_fit route use_when bundle_paths state_paths capture_paths secret_capture_paths; do
    # Normalize the "none" sentinel back to empty.
    [[ "$capture_paths" == "-" ]] && capture_paths=""
    [[ "$secret_capture_paths" == "-" ]] && secret_capture_paths=""
    [[ -z "$capture_paths" && -z "$secret_capture_paths" ]] && continue
    is_selected_supported "$app" || continue
    present="$(first_existing_path "$bundle_paths" || true)"
    [[ -n "$present" ]] || continue
    args=(--app "$app" --dest "$non_secret_dest")
    if [[ -n "$secret_capture_paths" ]]; then
      args+=(--secret-dest "$secret_dest")
    fi
    if [[ -n "$capture_paths" ]]; then
      IFS=';' read -r -a caps <<< "$capture_paths"
      for p in "${caps[@]}"; do
        [[ -n "$p" ]] && args+=(--path "$p")
      done
    fi
    if [[ -n "$secret_capture_paths" ]]; then
      IFS=';' read -r -a secs <<< "$secret_capture_paths"
      for p in "${secs[@]}"; do
        [[ -n "$p" ]] && args+=(--secret-path "$p")
      done
    fi
    if bash "$APP_CONFIG_HELPER" "${args[@]}"; then
      any=true
    else
      any=true
      APP_CONFIG_FAILURES=$((APP_CONFIG_FAILURES + 1))
    fi
  done < <(supported_apps_registry)
  [[ "$any" == true ]]
}

# create_selected_app_dirs — on a full run, create the destination/drop folders
# for exactly what will be backed up: the top-level folder for each selected +
# detected supported app, and a drop-folder plus manual-TODO README for each
# selected unsupported app. Per-app helpers still create their own subfolders.
UNSUPPORTED_DROP_ROOT="$APP_ROOT/manual-unsupported"
create_selected_app_dirs() {
  local app group how non_secret_dest secret_dest detectable phase_fit route use_when bundle_paths state_paths capture_paths secret_capture_paths
  while IFS=$'\t' read -r app group how non_secret_dest secret_dest detectable phase_fit route use_when bundle_paths state_paths capture_paths secret_capture_paths; do
    [[ "$detectable" == "yes" ]] || continue
    is_selected_supported "$app" || continue
    [[ -n "$(first_existing_path "$bundle_paths" || true)" ]] || continue
    [[ "$non_secret_dest" == none ]] || mkdir -p "$non_secret_dest"
    case "$secret_dest" in
      "$REIMAGE_ARTIFACT_ROOT"/*) mkdir -p "$secret_dest" ;;
    esac
  done < <(supported_apps_registry)

  # Unsupported apps the user chose to back up by hand: give each a drop-folder.
  [[ "$SELECTION_ACTIVE" == true ]] || return 0
  local uname slug dropdir
  while IFS= read -r uname; do
    [[ -n "$uname" ]] || continue
    slug="$(app_slug "$uname")"
    [[ -n "$slug" ]] || continue
    dropdir="$UNSUPPORTED_DROP_ROOT/$slug"
    mkdir -p "$dropdir"
    if [[ ! -f "$dropdir/README.txt" ]]; then
      {
        echo "Manual backup drop-folder for: $uname"
        echo ""
        echo "This app is not automatically supported by the reimage toolkit."
        echo "Export or copy its state into this folder before the erase, then"
        echo "restore it yourself after reimage. If any export is secret-bearing,"
        echo "stage it under secrets-encrypted/ instead of here."
      } > "$dropdir/README.txt"
    fi
  done <<< "$SELECTED_UNSUPPORTED"
}

# ensure_manual_drop_folders — a toolkit-supported app whose only mechanism is a
# manual export got nothing at all: no folder, no note. That made it strictly
# less visible than an *unsupported* app, which has had a drop folder and a
# README all along. Same treatment now, and the README keeps the folder out of
# the prune so it is still there when you come to do the export.
ensure_manual_drop_folders() {
  local mname slug dropdir
  while IFS= read -r mname; do
    [[ -n "$mname" ]] || continue
    slug="$(app_slug "$mname")"
    [[ -n "$slug" ]] || continue
    dropdir="$APP_ROOT/$slug"
    mkdir -p "$dropdir"
    if [[ ! -f "$dropdir/README.txt" ]]; then
      {
        echo "$mname — manual export"
        echo ""
        echo "This app is supported by the toolkit, but its state cannot be copied"
        echo "by script. Nothing was captured automatically."
        echo ""
        echo "Export it into this folder before the erase. backup-apps.md, Step 5"
        echo "(Complete Manual Exports) names what to export and where each piece"
        echo "goes — some apps split non-secret material here and secret-bearing"
        echo "material into secrets-encrypted/."
        echo ""
        echo "An empty folder with only this README means the export was not done."
      } > "$dropdir/README.txt"
    fi
  done <<< "$SELECTED_MANUAL"

  # A "both" app produces script output, so its folder exists and looks handled.
  # It is not: a manual piece is still owed, and a non-empty folder is exactly
  # the signal that hides that. Name the outstanding half.
  local bname bslug bdir
  while IFS= read -r bname; do
    [[ -n "$bname" ]] || continue
    bslug="$(app_slug "$bname")"
    [[ -n "$bslug" ]] || continue
    bdir="$APP_ROOT/$bslug"
    [[ -d "$bdir" ]] || continue
    if [[ ! -f "$bdir/MANUAL-STEP-STILL-REQUIRED.txt" ]]; then
      {
        echo "$bname — scripted capture done, manual step still required"
        echo ""
        echo "The files beside this note were captured automatically. They are not"
        echo "the whole backup: this app also has a manual export that no script"
        echo "can produce."
        echo ""
        echo "backup-apps.md, Step 5 (Complete Manual Exports) names the missing"
        echo "piece. A folder with content in it does not mean this app is done."
      } > "$bdir/MANUAL-STEP-STILL-REQUIRED.txt"
    fi
  done <<< "$SELECTED_BOTH"
}

# prune_empty_app_dirs — after all captures, remove directories left empty:
# rsync-mirrored app support subfolders that held no user content (e.g. the
# BBEdit "Language Modules", "Scripts", ... subtree), a VS Code user/snippets
# with nothing in it, or a dest folder for an app that matched nothing. The
# A deliberate drop target must carry a README.txt so it is never empty and so
# this prune cannot reach it — that is the invariant, and both the manual-app
# folders here and the IntelliJ helper's manual-settings-export/ and
# restore-notes/ rely on it. The previous premise, that no folder here is a
# required pre-existing drop target, was false and cost exactly those folders. Scoped to APP_ROOT
# (app-settings-backup); secrets-encrypted drop-folders are left untouched.
# -mindepth 1 keeps APP_ROOT itself; -depth removes nested empties bottom-up.
prune_empty_app_dirs() {
  PRUNED_APP_DIRS=""
  [[ -d "$APP_ROOT" ]] || return 0

  # Snapshot the top-level app folders around the prune. Without this an app
  # that WAS detected and processed, but whose sources held nothing, vanishes
  # without trace — indistinguishable from one that was never selected. That
  # ambiguity is the whole reason "I selected it and got no folder" is hard to
  # diagnose. Compare before/after rather than pre-scanning for empties: a
  # parent only becomes empty once its children are pruned.
  local before after
  before="$(find "$APP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)"
  find "$APP_ROOT" -mindepth 1 -depth -type d -empty -exec rmdir {} \; 2>/dev/null || true
  after="$(find "$APP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)"

  PRUNED_APP_DIRS="$(comm -23 <(printf '%s\n' "$before") <(printf '%s\n' "$after") \
    | sed 's|.*/||' | tr '\n' ' ')"
  return 0
}

if [[ "$FULL_RUN" == true ]]; then
  create_selected_app_dirs
  ensure_manual_drop_folders
fi

if [[ "$DOCKER_ONLY" == true || "$INTELLIJ_ONLY" == true || "$VSCODE_ONLY" == true ]]; then
  APP_CONFIG_STATUS="Skipped by single-app rerun mode"
elif [[ "$RUN_CANDIDATE_REVIEW" == true ]]; then
  APP_CONFIG_STATUS="Skipped; candidate-review is scan-only"
elif [[ ! -f "$APP_CONFIG_HELPER" ]]; then
  APP_CONFIG_STATUS="Skipped; .internal/apps/backup-app-config.sh not found"
elif run_registry_app_captures; then
  if (( APP_CONFIG_FAILURES > 0 )); then
    APP_CONFIG_STATUS="Captured registry-driven app configs, but $APP_CONFIG_FAILURES source(s) failed — review output"
  else
    APP_CONFIG_STATUS="Captured registry-driven app configs to app-settings-backup/<app>/ (and secrets-encrypted/<app>/ where applicable)"
  fi
else
  APP_CONFIG_STATUS="Skipped; no registry-driven apps detected on this Mac"
fi

# Selection summary for the manifest and run output.
if [[ "$SELECTION_ACTIVE" == true ]]; then
  SELECTION_STATUS="Checklist: $SELECTION_FILE"
elif [[ "$ALL_DETECTED" == true ]]; then
  SELECTION_STATUS="Bypassed with --all-detected (all detected apps eligible)"
else
  SELECTION_STATUS="Not applicable for this run mode"
fi

UNSUPPORTED_TODO_MD="- none selected"
if [[ "$SELECTION_ACTIVE" == true ]]; then
  _unsup_md="$(while IFS= read -r u; do
    [[ -n "$u" ]] || continue
    printf -- '- %s  (drop-folder: app-settings-backup/manual-unsupported/%s/)\n' "$u" "$(app_slug "$u")"
  done <<< "$SELECTED_UNSUPPORTED")"
  [[ -n "$_unsup_md" ]] && UNSUPPORTED_TODO_MD="$_unsup_md"
fi

# Manual-only supported apps belong in the manifest for the same reason the
# unsupported ones do: MANIFEST.md is where you look to find out whether an app
# was handled, and "absent" previously meant both "not selected" and "selected
# but yours to export".
MANUAL_TODO_MD="- none selected"
if [[ "$SELECTION_ACTIVE" == true ]]; then
  _man_md="$(while IFS= read -r m; do
    [[ -n "$m" ]] || continue
    printf -- '- %s  (drop-folder: app-settings-backup/%s/)\n' "$m" "$(app_slug "$m")"
  done <<< "$SELECTED_MANUAL")"
  [[ -n "$_man_md" ]] && MANUAL_TODO_MD="$_man_md"
fi

# The scan-only candidate review writes no MANIFEST.md — it only produces the
# review bundle and refreshes the selection checklist.
if [[ "$RUN_CANDIDATE_REVIEW" != true ]]; then
cat > "$APP_ROOT/MANIFEST.md" <<EOF
# App Backup Manifest

Generated: $STAMP
Artifact root: $REIMAGE_ARTIFACT_ROOT

## Scripted work completed

| Item | Status |
|---|---|
| App-backup selection | $SELECTION_STATUS |
| Standard app-backup directories prepared | Complete |
| Docker helper | $DOCKER_STATUS |
| IntelliJ helper | $INTELLIJ_STATUS |
| VS Code local fallback capture | $VSCODE_STATUS |
| Registry-driven app configs | $APP_CONFIG_STATUS |
| Candidate review helper | $CANDIDATE_REVIEW_STATUS |

## Primary Phase 2D locations

\`\`\`text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/
\`\`\`

## Manual backup — supported apps with no scripted capture

$MANUAL_TODO_MD

## Manual backup — unsupported apps you selected

$UNSUPPORTED_TODO_MD

## Manual or app-controlled follow-up still required when applicable

- Chrome bookmarks export and optional password CSV staging
- Postman collections, environment exports, and optional vault export handling
- Fiddler Everywhere session/AutoResponder export and secret-bearing staging
- TNAS PC connection re-add and any secret-bearing credential staging
- Raycast export review and any secret-bearing quicklinks handling
- Obsidian restore-source decision and any manual vault copy
- iMovie libraries confirmed backed up as local files (Phase 2B), not copied into the artifact root
- IntelliJ settings ZIP export from the dedicated IntelliJ companion runbook when applicable
- Claude MCP config reviewed after scripted staging to secrets-encrypted/claude/ when applicable

## Notes

- Treat this manifest as the stable Phase 2D summary.
- Only the apps checked in \`app-backup-selection.md\` were acted on (unless run with --all-detected).
- Use \`backup-apps.md\` for the manual or app-controlled steps that the script cannot complete.
- Use \`reimage-prep-checks.md\` later in Phase 6 only for the manual rows that remain after reviewing the generated \`reimage-checklist.sh --phase pre\` report.
EOF
fi

# Remove capture folders that ended up empty (rsync-mirrored subfolders with no
# content, or dest folders for apps that matched nothing). Full runs only.
if [[ "$FULL_RUN" == true ]]; then
  prune_empty_app_dirs
fi

if [[ "$RUN_CANDIDATE_REVIEW" == true ]]; then
  echo "Candidate review: $CANDIDATE_REVIEW_STATUS"
  echo "Candidate review output: $CANDIDATE_REVIEW_DIR"
  echo "Selection checklist: $SELECTION_FILE"
  echo "Next: check the apps to back up in that checklist, then run the Step 4 backup."
else
  echo "Prepared Phase 2D app backup root: $APP_ROOT"
  echo "Wrote manifest: $APP_ROOT/MANIFEST.md"
  echo "App-backup selection: $SELECTION_STATUS"
  echo "Docker helper: $DOCKER_STATUS"
  echo "IntelliJ helper: $INTELLIJ_STATUS"
  echo "VS Code capture: $VSCODE_STATUS"
  echo "App configs: $APP_CONFIG_STATUS"

  # Manual-only apps produce no folder by design. Saying so is the difference
  # between "the script skipped my selection" and "this one is yours to export".
  # Unsupported apps already get a folder and a README; supported-but-manual
  # apps got neither, which made them the least visible of the three.
  if [[ -n "${SELECTED_MANUAL//[[:space:]]/}" ]]; then
    echo ""
    echo "Manual-only apps you selected — no folder is created for these:"
    while IFS= read -r _m; do
      [[ -n "$_m" ]] && echo "  - $_m"
    done <<< "$SELECTED_MANUAL"
    echo "  Complete their exports in backup-apps.md -> Step 5 (Complete Manual Exports)."
    echo "  That step names the destination for each; create it as you export."
  fi

  # An app processed with nothing to copy leaves no folder either, for a very
  # different reason. Distinguish the two so neither reads as a silent skip.
  if [[ -n "${PRUNED_APP_DIRS//[[:space:]]/}" ]]; then
    echo ""
    echo "Removed as empty — detected and processed, but the sources held nothing:"
    for _p in $PRUNED_APP_DIRS; do
      echo "  - $_p"
    done
    echo "  If you expected content, confirm the app is installed and its state exists."
  fi
fi

if $OPEN_AFTER; then
  [[ -n "$CANDIDATE_REVIEW_DIR" ]] && open "$CANDIDATE_REVIEW_DIR" 2>/dev/null || true
  [[ "$RUN_CANDIDATE_REVIEW" == true && -f "$SELECTION_FILE" ]] && open "$SELECTION_FILE" 2>/dev/null || true
  open "$APP_ROOT" 2>/dev/null || true
fi


# A backup that lost a source is not a success. Both counters are reported in
# the summary above and recorded in MANIFEST.md; this makes the documented
# exit 1 reachable so a caller, or a later phase, can tell the difference.
if (( HELPER_FAILURES + APP_CONFIG_FAILURES > 0 )); then
  echo ""
  echo "INCOMPLETE: $HELPER_FAILURES helper failure(s), $APP_CONFIG_FAILURES config-source failure(s)." >&2
  echo "Review the output above and re-run before treating this phase as done." >&2
  exit 1
fi