#!/usr/bin/env bash
# =============================================================================
# capture-managed-inventory.sh
#
# Company-managed inventory capture (Phase 2C pre-image / Phase 11C post-image):
# a read-only record of company-managed apps, configuration profiles, launch
# agents/daemons, system extensions, and managed preferences. Writes a
# timestamped bundle under managed-inventory/. It observes and records only —
# it does not modify managed state. See capture-managed-inventory.md for the
# full runbook.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/capture-managed-inventory.sh
#
#   # Default -- pre-image bundle under managed-inventory/pre-image-<stamp>/
#   ./bin/capture-managed-inventory.sh
#
#   # Post-image bundle
#   ./bin/capture-managed-inventory.sh --context post-image
#
#   # Override the artifact root for this invocation
#   ./bin/capture-managed-inventory.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Write to an exact output directory (skips the managed-inventory/<context>-<stamp> layout)
#   ./bin/capture-managed-inventory.sh --output /absolute/path/to/output
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --context LABEL       pre-image | post-image | pre-image-<label> | post-image-<label>.
#                         Prefix for the timestamped run directory. Default: pre-image.
#   --output DIR          Exact output directory for generated files.
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

# Validate the run-directory context, consistent with capture-size-audit.sh.
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
  OUTPUT_DIR="$REIMAGE_ARTIFACT_ROOT/managed-inventory/${CONTEXT}-${STAMP}"
fi

OUT="$OUTPUT_DIR"
mkdir -p "$OUT"

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

r() { "$@" >> "$_SECTION_FILE" 2>&1 || true; }
h() { echo "$1" >> "$_SECTION_FILE"; }

# ---------------------------------------------------------------------------
# Shared managed-signal helpers (used by sections 03, 04, and 07)
# ---------------------------------------------------------------------------

# Corporate-tooling name filter for app bundles. Single source shared by the
# section 03 per-app annotation and the section 07 filter pass, so "would this
# app show up in the filter pass?" has exactly one definition.
MANAGED_APP_FILTER='Company Portal|Microsoft|CrowdStrike|Zscaler|Defender|VPN'

# Capture the per-app cross-reference signals once, so each underlying command
# runs a single time. Sections 02/04/06 print these; section 03 matches each
# app's bundle identifier against them to compute one authoritative verdict.
ALL_PROFILES="$(profiles show -type configuration 2>&1 || true)"
ALL_RECEIPTS="$(pkgutil --pkgs 2>/dev/null | sort || true)"
ALL_MANAGED_PREFS="$(find "/Library/Managed Preferences" -maxdepth 2 -type f 2>/dev/null || true)"

annotate_app_line() {
  # Echo "<app path><TAB><verdict>" for one .app bundle. This is the single
  # authoritative managed verdict for the toolkit: the backup-apps candidate
  # review reads it rather than re-deriving its own. Signals, by strength:
  #   strong — configuration profile (02), managed preference (06), or the
  #            corporate-tooling name filter (07). Any one → [managed: ...].
  #   weak   — a package receipt (04) only. A receipt means pkg-installed, which
  #            can be self-installed, so receipt-only → [likely: receipt].
  #   none   → [-].
  # Bundle-id matches use the app's real CFBundleIdentifier (read via PlistBuddy)
  # for precision. Format contract: "<path><TAB>[<verdict>: <evidence>]" or
  # "<path><TAB>[-]"; the candidate review parses the <verdict> keyword.
  local app="$1"
  local bid cats=""
  local has_profile=0 has_mpref=0 has_receipt=0 has_filter=0

  bid="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist" 2>/dev/null || true)"
  if [[ -n "$bid" ]]; then
    if grep -qiF -- "$bid" <<< "$ALL_PROFILES"; then has_profile=1; fi
    if grep -qiF -- "$bid" <<< "$ALL_MANAGED_PREFS"; then has_mpref=1; fi
    if grep -qiF -- "$bid" <<< "$ALL_RECEIPTS"; then has_receipt=1; fi
  fi
  if grep -qiE -- "$MANAGED_APP_FILTER" <<< "$app"; then has_filter=1; fi

  # Evidence list in a stable order (strong signals first).
  [[ $has_profile -eq 1 ]] && cats="${cats:+$cats, }profile"
  [[ $has_mpref   -eq 1 ]] && cats="${cats:+$cats, }managed-pref"
  [[ $has_filter  -eq 1 ]] && cats="${cats:+$cats, }filter"
  [[ $has_receipt -eq 1 ]] && cats="${cats:+$cats, }receipt"

  if [[ $has_profile -eq 1 || $has_mpref -eq 1 || $has_filter -eq 1 ]]; then
    printf '%s\t[managed: %s]\n' "$app" "$cats"
  elif [[ $has_receipt -eq 1 ]]; then
    printf '%s\t[likely: %s]\n' "$app" "$cats"
  else
    printf '%s\t[-]\n' "$app"
  fi
}

section "MDM enrollment status" "01-enrollment-status.txt"
  r profiles status -type enrollment
end_section

section "Configuration profiles" "02-profiles-configuration.txt"
  printf '%s\n' "$ALL_PROFILES" >> "$_SECTION_FILE"
end_section

section "Installed app bundles" "03-installed-app-bundles.txt"
  h "# Each line: <app bundle path><TAB>managed verdict. This is the single source"
  h "# the backup-apps candidate review reads for its managed partition."
  h "#   [managed: ...]    strong signal — a configuration profile (02), a managed"
  h "#                     preference (06), or the corporate-tooling filter (07) matches."
  h "#   [likely: receipt] weak signal — only a package receipt (04) matches. A receipt"
  h "#                     means pkg-installed, which can be self-installed, so verify."
  h "#   [-]               no managed signal found here."
  h "# Bundle-id matches use the app's real CFBundleIdentifier (read via PlistBuddy)."
  h "# Heuristic, not proof: MDM/App Store installs may leave no receipt, so [-] does"
  h "# not prove an app is unmanaged. The full list is kept so 03 stays the complete"
  h "# installed-apps baseline for pre-image/post-image comparison."
  h ""
  while IFS= read -r _app; do
    [[ -z "$_app" ]] && continue
    annotate_app_line "$_app" >> "$_SECTION_FILE"
  done < <(find /Applications /System/Applications "$HOME/Applications" -maxdepth 2 -name '*.app' -type d 2>/dev/null | sort)
end_section

section "Installed package receipts" "04-installed-package-receipts.txt"
  printf '%s\n' "$ALL_RECEIPTS" >> "$_SECTION_FILE"
end_section

section "Background managed components" "05-background-managed-components.txt"
  h "--- LaunchAgents and LaunchDaemons ---"
  r ls -1 /Library/LaunchAgents /Library/LaunchDaemons
  h ""
  h "--- System extensions ---"
  r systemextensionsctl list
end_section

section "Managed preference payloads" "06-managed-preference-payloads.txt"
  printf '%s\n' "$ALL_MANAGED_PREFS" >> "$_SECTION_FILE"
end_section

section "GAIG-focused filter pass" "07-gaig-filter-pass.txt"
  h "--- Package receipts ---"
  bash -lc "pkgutil --pkgs | grep -Ei 'microsoft|intune|companyportal|crowdstrike|zscaler|defender|vpn|security|falcon'" >> "$_SECTION_FILE" 2>&1 || true
  h ""
  h "--- Installed app bundles ---"
  bash -lc "find /Applications /System/Applications -maxdepth 2 -name '*.app' -type d 2>/dev/null | grep -Ei '$MANAGED_APP_FILTER'" >> "$_SECTION_FILE" 2>&1 || true
  h ""
  h "--- LaunchAgents and LaunchDaemons ---"
  bash -lc "ls /Library/LaunchAgents /Library/LaunchDaemons 2>/dev/null | grep -Ei 'microsoft|intune|companyportal|crowdstrike|zscaler|defender'" >> "$_SECTION_FILE" 2>&1 || true
  h ""
  h "--- System extensions ---"
  bash -lc "systemextensionsctl list | grep -Ei 'microsoft|crowdstrike|zscaler|defender'" >> "$_SECTION_FILE" 2>&1 || true
end_section

cat > "$OUT/MANIFEST.txt" <<EOF
# Company Managed Inventory Capture
Generated: $(date)
Script: $(basename "$0")
Context: $CONTEXT
Output directory: $OUT

Files:
- 01-enrollment-status.txt
- 02-profiles-configuration.txt
- 03-installed-app-bundles.txt
- 04-installed-package-receipts.txt
- 05-background-managed-components.txt
- 06-managed-preference-payloads.txt
- 07-gaig-filter-pass.txt
EOF

echo ""
echo "Company-managed inventory capture complete."
echo "Output → $OUT"
