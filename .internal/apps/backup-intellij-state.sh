#!/usr/bin/env bash
# =============================================================================
# backup-intellij-state.sh
#
# Internal helper for backup-apps.sh (Phase 2D). Backs up IntelliJ IDEA state:
# Scratches and Consoles, selected global IDE config, project-level .idea
# metadata across the workspace root, and diagnostic logs. Keeps secret-shaped
# material out of the clear-text copy and stages the files matching your reviewed
# patterns into secrets-encrypted/intellij/ for the encrypted secrets workflow.
#
# This file lives in .internal/apps/ and is normally invoked by
# bin/backup-apps.sh. Shared reimage config is intentionally NOT loaded here;
# the caller passes --artifact-root (and, from the entrypoint, --workspace-root)
# explicitly. It is safe to run standalone when --artifact-root PATH (or an
# exported REIMAGE_ARTIFACT_ROOT) is supplied.
#
# The active IntelliJ config directory is auto-detected (the most recently
# modified IntelliJIdea*/IdeaIC* directory under the JetBrains root); set
# IDE_PRODUCT explicitly only when your config directory uses a non-standard
# name.
#
# --- BEGIN USAGE ---
# Usage:
#   # Normal (through the entrypoint)
#   ./bin/backup-apps.sh --intellij-only
#
#   # Standalone
#   .internal/apps/backup-intellij-state.sh --artifact-root /path/to/reimage-artifact-root --workspace-root /path/to/projects
#   .internal/apps/backup-intellij-state.sh --artifact-root <root> --all-config-dirs
#   .internal/apps/backup-intellij-state.sh --artifact-root <root> --include-system-cache
#
# Options:
#   --artifact-root PATH       Artifact root. Also honored from an exported
#                              REIMAGE_ARTIFACT_ROOT. Output goes under
#                              <root>/app-settings-backup/intellij/ and
#                              <root>/secrets-encrypted/intellij/.
#
#   --all-config-dirs          Back up every IntelliJIdea* / IdeaIC* config
#                              directory under the JetBrains root. Default is to
#                              back up the auto-detected active config directory
#                              (the most recently modified one), falling back to
#                              all dirs only if an explicit IDE_PRODUCT is not
#                              found.
#
#   --workspace-root PATH      Root containing all IntelliJ workspaces/projects
#                              to scan for project-level .idea metadata. No
#                              baked-in default: the entrypoint supplies it from
#                              GIT_WORK_REPO_ROOT; for standalone use, pass this
#                              flag (or export INTELLIJ_WORKSPACE_ROOT). When
#                              unset, the project-level scan is skipped.
#                              This is intentionally broader than IntelliJ's
#                              PROJECT BasePath, which only reflects the
#                              currently open project/window.
#
#   --workspace-max-depth N    Max depth used when finding .idea directories
#                              under --workspace-root. Default: 6
#
#   --skip-workspaces          Do not scan/copy project-level .idea metadata
#                              from the workspace root.
#
#   --include-shelf            Include .idea/shelf folders when copying
#                              project-level .idea metadata. Default is to skip
#                              shelves because they can be large/noisy.
#
#   --include-system-cache     Copy the IntelliJ system/cache directory. Not
#                              recommended unless you have a specific diagnostic
#                              need, because it can be large and is not normally
#                              needed for restore.
#
#   -h, --help                 Show this message and exit.
#
# What it does:
#   - Auto-detects the active IntelliJ config directory (newest under the JetBrains root).
#   - Copies Scratches and Consoles from the active IntelliJ config directory.
#   - Copies selected global IDE config folders such as codestyles, keymaps, inspections,
#     colors, templates, options, tools, settingsSync, plugins, jdbc-drivers, and tasks.
#   - Scans the workspace root and copies project-level .idea metadata for every
#     workspace/project it finds, not just the one currently open in IntelliJ.
#   - Copies IntelliJ logs for diagnostics.
#   - Records app bundle, runtime, lib, preinstalled plugins, system/cache, temp, current
#     Project BasePath concept, and workspace root in manifests.
#   - Keeps secret-shaped files out of the clear-text copy, and stages the files
#     matching your reviewed patterns (intellij-secret-review-template.txt) into
#     secrets-encrypted/intellij/by-source/. Nothing is staged unless checked.
#
# Security note:
#   Run create-secrets-dmg.sh (Phase 3B) after this script to encrypt the staged
#   IntelliJ secrets (secrets-encrypted/intellij/) into the consolidated DMG.
#
# Exit status:
#   0  Completed successfully.
#   1  Runtime or copy failure.
#   2  Usage or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -euo pipefail

SCRIPT_VERSION="20260721-artifact-root-autodetect"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

# Shared reimage config is intentionally NOT sourced here. The artifact root
# arrives via --artifact-root (from the entrypoint) or an exported
# REIMAGE_ARTIFACT_ROOT for standalone use.
ARTIFACT_ROOT="${REIMAGE_ARTIFACT_ROOT:-}"
ALL_CONFIG_DIRS=0
INCLUDE_SYSTEM_CACHE=0
SKIP_WORKSPACES=0
INCLUDE_SHELF=0
WORKSPACE_MAX_DEPTH=6
# No baked-in default: the entrypoint passes --workspace-root from
# GIT_WORK_REPO_ROOT, and standalone callers pass it (or export
# INTELLIJ_WORKSPACE_ROOT). When empty, the project-level scan is skipped.
WORKSPACE_ROOT="${INTELLIJ_WORKSPACE_ROOT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --artifact-root)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --artifact-root requires a path" >&2
        exit 2
      fi
      ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --artifact-root=*)
      ARTIFACT_ROOT="${1#*=}"
      shift
      ;;
    --all-config-dirs)
      ALL_CONFIG_DIRS=1
      shift
      ;;
    --include-system-cache)
      INCLUDE_SYSTEM_CACHE=1
      shift
      ;;
    --skip-workspaces)
      SKIP_WORKSPACES=1
      shift
      ;;
    --include-shelf)
      INCLUDE_SHELF=1
      shift
      ;;
    --workspace-root)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --workspace-root requires a path" >&2
        exit 2
      fi
      WORKSPACE_ROOT="$2"
      shift 2
      ;;
    --workspace-root=*)
      WORKSPACE_ROOT="${1#*=}"
      shift
      ;;
    --workspace-max-depth)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --workspace-max-depth requires a number" >&2
        exit 2
      fi
      WORKSPACE_MAX_DEPTH="$2"
      shift 2
      ;;
    --workspace-max-depth=*)
      WORKSPACE_MAX_DEPTH="${1#*=}"
      shift
      ;;
    --*)
      echo "ERROR: Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -z "$ARTIFACT_ROOT" ]]; then
        ARTIFACT_ROOT="$1"
        shift
      else
        echo "ERROR: Unexpected positional argument: $1" >&2
        usage >&2
        exit 2
      fi
      ;;
  esac
done

case "$WORKSPACE_MAX_DEPTH" in
  ''|*[!0-9]*)
    echo "ERROR: --workspace-max-depth must be a positive integer" >&2
    exit 2
    ;;
esac

if [[ -z "$ARTIFACT_ROOT" ]]; then
  echo "ERROR: artifact root not set. Pass --artifact-root PATH (or export REIMAGE_ARTIFACT_ROOT)." >&2
  exit 2
fi

INTELLIJ_ROOT="$ARTIFACT_ROOT/app-settings-backup/intellij"
DEST="$INTELLIJ_ROOT"
JETBRAINS_ROOT="$HOME/Library/Application Support/JetBrains"

if [[ ! -d "$JETBRAINS_ROOT" ]]; then
  echo "ERROR: JetBrains config root not found: $JETBRAINS_ROOT" >&2
  exit 2
fi

# Encrypted-secrets destination for staged IntelliJ secrets, and the review
# selection files. Like gitignore-superset, these are written to the external
# artifact root; persist them to your local workspace by hand if you want the
# selections to survive between reimages, and copy them back before a rerun.
INTELLIJ_SECRETS_DEST="$ARTIFACT_ROOT/secrets-encrypted/intellij"
INTELLIJ_SECRETS_REVIEW_DIR="$ARTIFACT_ROOT/app-settings-backup/intellij/secret-review"
INTELLIJ_SECRETS_TEMPLATE="$INTELLIJ_SECRETS_REVIEW_DIR/intellij-secret-review-template.txt"
INTELLIJ_EXCLUDE_LIST="$INTELLIJ_SECRETS_REVIEW_DIR/backup-exclude-list.txt"
INTELLIJ_STAGED_COUNT=0

# Prefer macOS/BSD stat even if GNU coreutils stat appears earlier in PATH.
# GNU stat treats "-f" as filesystem mode, which creates noisy errors like:
#   stat: cannot read file system information for '%m': No such file or directory
mtime_epoch() {
  local path="$1"
  if [[ -x /usr/bin/stat ]]; then
    /usr/bin/stat -f '%m' "$path"
  else
    stat -c '%Y' "$path"
  fi
}

# Print the basename of the most recently modified IntelliJIdea*/IdeaIC* config
# directory under JETBRAINS_ROOT, or nothing when none exist. This is how the
# active IDE product is chosen when IDE_PRODUCT is not set explicitly.
detect_newest_config_dir() {
  local dir m newest="" newest_mtime=0
  shopt -s nullglob
  for dir in "$JETBRAINS_ROOT"/IntelliJIdea* "$JETBRAINS_ROOT"/IdeaIC*; do
    [[ -d "$dir" ]] || continue
    m="$(mtime_epoch "$dir" 2>/dev/null || true)"
    case "$m" in ''|*[!0-9]*) continue ;; esac
    if (( m > newest_mtime )); then
      newest_mtime="$m"
      newest="$dir"
    fi
  done
  shopt -u nullglob
  [[ -n "$newest" ]] && basename "$newest"
}

# Active paths from IntelliJ IDEA -> Help -> Diagnostic Tools -> Special Files and Folders.
# Override any of these with environment variables if the active IDE version/path changes.
# IDE_PRODUCT defaults to the auto-detected active (most recently modified) config directory.
IDE_PRODUCT="${IDE_PRODUCT:-$(detect_newest_config_dir)}"
if [[ -z "$IDE_PRODUCT" ]]; then
  echo "ERROR: No IntelliJIdea* or IdeaIC* config directory found under: $JETBRAINS_ROOT" >&2
  echo "Set IDE_PRODUCT explicitly if the config directory uses a non-standard name." >&2
  exit 2
fi

IDE_APP="${IDE_APP:-/Applications/IntelliJ IDEA.app}"
IDE_BIN_DIR="${IDE_BIN_DIR:-$IDE_APP/Contents/bin}"
IDE_CONFIG_DIR="${IDE_CONFIG_DIR:-$JETBRAINS_ROOT/$IDE_PRODUCT}"
IDE_INSTALLATION_HOME="${IDE_INSTALLATION_HOME:-$IDE_APP/Contents}"
IDE_RUNTIME_HOME="${IDE_RUNTIME_HOME:-$IDE_APP/Contents/jbr/Contents/Home}"
IDE_LOGS_DIR="${IDE_LOGS_DIR:-$HOME/Library/Logs/JetBrains/$IDE_PRODUCT}"
IDE_FRONTEND_LOG="${IDE_FRONTEND_LOG:-$IDE_LOGS_DIR/idea.log}"
IDE_LIB_DIR="${IDE_LIB_DIR:-$IDE_APP/Contents/lib}"
IDE_MISC_SCRATCH_DIR="${IDE_MISC_SCRATCH_DIR:-$IDE_CONFIG_DIR}"
IDE_MISC_TEMP_DIR="${IDE_MISC_TEMP_DIR:-$HOME/Library/Caches/JetBrains/$IDE_PRODUCT/tmp}"
IDE_OPTIONS_DIR="${IDE_OPTIONS_DIR:-$IDE_CONFIG_DIR/options}"
IDE_PLUGINS_MAIN_DIR="${IDE_PLUGINS_MAIN_DIR:-$IDE_CONFIG_DIR/plugins}"
IDE_PLUGINS_PREINSTALLED_DIR="${IDE_PLUGINS_PREINSTALLED_DIR:-$IDE_APP/Contents/plugins}"

# IntelliJ's PROJECT BasePath in Special Files and Folders is only the currently open project.
# For backup coverage, use the broader workspace root by default.
IDE_PROJECT_BASEPATH="${IDE_PROJECT_BASEPATH:-$WORKSPACE_ROOT}"
IDE_SYSTEM_DIR="${IDE_SYSTEM_DIR:-$HOME/Library/Caches/JetBrains/$IDE_PRODUCT}"

path_type() {
  local path="$1"
  if [[ -d "$path" ]]; then
    printf 'directory'
  elif [[ -f "$path" ]]; then
    printf 'file'
  elif [[ -L "$path" ]]; then
    printf 'symlink'
  else
    printf 'missing'
  fi
}

path_size() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    du -sh "$path" 2>/dev/null | awk '{print $1}'
  else
    printf 'n/a'
  fi
}

safe_find_one_level() {
  local path="$1"
  local label="$2"
  local out="$3"
  {
    echo "## $label"
    echo "$path"
    if [[ -d "$path" ]]; then
      find "$path" -maxdepth 2 -mindepth 1 -print 2>/dev/null | sort | sed 's/^/  /'
    elif [[ -f "$path" ]]; then
      ls -lh "$path" 2>/dev/null | sed 's/^/  /'
    else
      echo "  MISSING"
    fi
    echo
  } >> "$out"
}

make_relative_to_workspace_root() {
  local path="$1"
  if [[ "$path" == "$WORKSPACE_ROOT" ]]; then
    printf '.'
  elif [[ "$path" == "$WORKSPACE_ROOT"/* ]]; then
    printf '%s' "${path#"$WORKSPACE_ROOT"/}"
  else
    basename "$path"
  fi
}

sanitize_for_manifest_label() {
  # Keep the real relative path in manifests. This helper is only used where a label cannot be empty.
  local value="$1"
  if [[ -z "$value" || "$value" == "." ]]; then
    basename "$WORKSPACE_ROOT"
  else
    printf '%s' "$value"
  fi
}

# --- IntelliJ secret pattern selection (mirrors gitignore-review-template.txt) ---
# The reviewed selections are written to the external artifact root (persist them
# to your local workspace by hand to survive between reimages). Nothing is
# auto-selected: on first use an all-unchecked template is written and staging is
# skipped until the user checks patterns and reruns. A default seed is emitted on
# first generation; edit the
# workspace copy to add or remove patterns.
INTELLIJ_SECRET_SEED_PATTERNS=(
  'http-client.env.json'
  'http-client.private.env.json'
  '*.env.json'
  '*.secrets.json'
  '*.private.env.json'
  'dataSources.local.xml'
  'dataSourcesLocal.xml'
  '*.pem'
  '*.key'
  '*.p12'
  '*.pfx'
  '*.jks'
  '*.keystore'
  '*credential*'
  '*secret*'
)

SELECTED_PATTERNS=()
ALL_PATTERNS=()
FIND_PRED=()

write_intellij_secret_template() {
  local dest="$1"
  local p
  mkdir -p "$(dirname "$dest")"
  {
    echo "# IntelliJ Secret Review Template"
    echo "#"
    echo "# Mark patterns whose matching files should be staged into"
    echo "# secrets-encrypted/intellij/ by changing:"
    echo "#   [ ] pattern"
    echo "# to:"
    echo "#   [x] pattern"
    echo "#"
    echo "# Files matching a checked pattern under the JetBrains config dirs and the"
    echo "# workspace root are copied into the encrypted-secrets tree so Phase 3B"
    echo "# sweeps them. Nothing is staged unless you check it."
    echo "#"
    echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    for p in "${INTELLIJ_SECRET_SEED_PATTERNS[@]}"; do
      echo "[ ] $p"
    done
  } > "$dest"
}

# Read a review template into SELECTED_PATTERNS ([x]-checked) and ALL_PATTERNS
# (every listed pattern). Tolerant of CRLF and surrounding whitespace.
load_intellij_secret_patterns() {
  local file="$1"
  local line marker pat
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    case "$line" in
      '#'*|'') continue ;;
    esac
    marker="${line:0:4}"
    pat="${line:4}"
    # trim leading and trailing whitespace from the pattern
    pat="${pat#"${pat%%[![:space:]]*}"}"
    pat="${pat%"${pat##*[![:space:]]}"}"
    [[ -n "$pat" ]] || continue
    case "$marker" in
      '[x] '|'[X] ')
        SELECTED_PATTERNS+=("$pat")
        ALL_PATTERNS+=("$pat")
        ;;
      '[ ] ')
        ALL_PATTERNS+=("$pat")
        ;;
    esac
  done < "$file"
}

# Build a find name/path predicate (FIND_PRED) from SELECTED_PATTERNS. A pattern
# containing "/" is matched as a path suffix; everything else as a basename.
build_find_predicate() {
  FIND_PRED=()
  local first=1 p flag
  [[ ${#SELECTED_PATTERNS[@]} -gt 0 ]] || return 0
  for p in "${SELECTED_PATTERNS[@]}"; do
    flag="-name"
    case "$p" in
      */*) flag="-path"; p="*/$p" ;;
    esac
    if [[ $first -eq 1 ]]; then
      FIND_PRED+=("$flag" "$p")
      first=0
    else
      FIND_PRED+=(-o "$flag" "$p")
    fi
  done
}

# Record and copy one matched secret file into the encrypted-secrets tree.
# Identical filenames recur across products/modules, so each file is placed under
# by-source/<path-below-home> to stay unique and keep provenance.
stage_one_intellij_secret() {
  local src="$1"
  local rel dst
  [[ -f "$src" ]] || return 0
  printf '%s\n' "$src" >> "$INTELLIJ_SECRET_CANDIDATES"
  rel="${src#"$HOME"/}"
  rel="${rel#/}"
  dst="$INTELLIJ_SECRETS_DEST/by-source/$rel"
  mkdir -p "$(dirname "$dst")"
  if cp -p "$src" "$dst" 2>/dev/null; then
    printf '%s\t%s\n' "$src" "$dst" >> "$INTELLIJ_SECRET_STAGED"
    INTELLIJ_STAGED_COUNT=$((INTELLIJ_STAGED_COUNT + 1))
  else
    printf '%s\t%s\n' "$src" "COPY-FAILED" >> "$INTELLIJ_SECRET_STAGED"
  fi
}

# Operator-maintained noise excludes for the clear-text IntelliJ copy, seeded on
# first use. Mirrors gitignore-superset/backup-exclude-list.txt: one pattern per
# line, '#' comments and blank lines ignored. Secrets are handled by the review
# template, not here.
INTELLIJ_EXCLUDE_SEED=(
  'httpRequests/'
  'httpRequests/**'
  'shelf/'
  'shelf/**'
  '.DS_Store'
)

# Secret-shape floor: always excluded from the clear-text copy even when no
# review template exists, so credential-shaped files never leak into plaintext.
INTELLIJ_SECRET_EXCLUDE_FLOOR=(
  'http-client.env.json'
  'http-client.private.env.json'
  '*.env.json'
  'dataSources.local.xml'
  'dataSourcesLocal.xml'
)

RSYNC_EXCLUDE_ARGS=()

write_intellij_exclude_list() {
  local dest="$1" p
  mkdir -p "$(dirname "$dest")"
  {
    echo "# backup-exclude-list.txt  (Exclude — drop noise from the clear-text IntelliJ copy)"
    echo "#"
    echo "# One pattern per line; '#' comments and blank lines are ignored."
    echo "# Secret handling lives in intellij-secret-review-template.txt, not here."
    echo "# Do not list secrets here; this only drops files from the plaintext copy."
    echo "# 'shelf/' is honored unless you pass --include-shelf."
    echo ""
    for p in "${INTELLIJ_EXCLUDE_SEED[@]}"; do
      echo "$p"
    done
  } > "$dest"
}

# Build the effective rsync exclude set for the clear-text copy: secret-shape
# floor + every review-template pattern (checked or not) + the operator exclude
# list. 'shelf/' entries are dropped from the set when --include-shelf is passed.
build_rsync_exclude_args() {
  RSYNC_EXCLUDE_ARGS=()
  local p
  for p in "${INTELLIJ_SECRET_EXCLUDE_FLOOR[@]}"; do
    RSYNC_EXCLUDE_ARGS+=(--exclude "$p")
  done
  if [[ ${#ALL_PATTERNS[@]} -gt 0 ]]; then
    for p in "${ALL_PATTERNS[@]}"; do
      RSYNC_EXCLUDE_ARGS+=(--exclude "$p")
    done
  fi
  if [[ -n "$INTELLIJ_EXCLUDE_LIST" && -f "$INTELLIJ_EXCLUDE_LIST" ]]; then
    while IFS= read -r p || [[ -n "$p" ]]; do
      p="${p%$'\r'}"
      case "$p" in '#'*|'') continue ;; esac
      p="${p#"${p%%[![:space:]]*}"}"
      p="${p%"${p##*[![:space:]]}"}"
      [[ -n "$p" ]] || continue
      case "$p" in
        'shelf/'|'shelf/**') [[ "$INCLUDE_SHELF" -eq 1 ]] && continue ;;
      esac
      RSYNC_EXCLUDE_ARGS+=(--exclude "$p")
    done < "$INTELLIJ_EXCLUDE_LIST"
  fi
}

mkdir -p "$DEST" "$DEST/manual-settings-export" "$DEST/restore-notes"
mkdir -p "$ARTIFACT_ROOT/secrets-encrypted/intellij"

rm -rf "$DEST/project-metadata" "$DEST/manifests" "$DEST/logs"
shopt -s nullglob
generated_product_dirs=("$DEST"/IntelliJIdea* "$DEST"/IdeaIC*)
if [[ ${#generated_product_dirs[@]} -gt 0 ]]; then
  rm -rf "${generated_product_dirs[@]}"
fi
shopt -u nullglob

mkdir -p "$DEST/manifests" "$DEST/logs" "$DEST/project-metadata"

README="$DEST/README.md"
cat > "$README" <<EOF_README
# IntelliJ Backup

This directory is refreshed in place by \`backup-intellij-state.sh\`.

\`\`\`text
$ARTIFACT_ROOT/app-settings-backup/intellij/
\`\`\`

HTTP Client environment files that may contain credentials should be encrypted under:

\`\`\`text
$ARTIFACT_ROOT/secrets-encrypted/intellij/
\`\`\`

Active IDE product (auto-detected as the most recently modified config directory):

\`\`\`text
$IDE_PRODUCT
\`\`\`

Workspace root scanned for project-level IntelliJ metadata:

\`\`\`text
$WORKSPACE_ROOT
\`\`\`

Generated: $(date '+%Y-%m-%d %H:%M:%S')
Script version: $SCRIPT_VERSION

## Layout

\`\`\`text
$ARTIFACT_ROOT/app-settings-backup/intellij/
├── $IDE_PRODUCT/
│   ├── config-copy/
│   ├── scratches-and-consoles/
│   └── manifests/
├── project-metadata/
├── manifests/
├── logs/
└── README.md
\`\`\`

## Notes

- Project-level .idea metadata is copied under project-metadata/.
- IntelliJ diagnostic logs are copied under logs/.
- Secret files matching your reviewed patterns are staged into secrets-encrypted/intellij/by-source/ and listed in manifests/intellij-secrets-staged.tsv; the consolidated secrets DMG workflow encrypts them.
EOF_README

CONFIG_DIRS_FILE="$DEST/manifests/intellij-config-dirs.tsv"
SPECIAL_PATHS_FILE="$DEST/manifests/special-files-and-folders.tsv"
SPECIAL_STATUS_FILE="$DEST/manifests/special-paths-status.tsv"
SPECIAL_LISTING_FILE="$DEST/manifests/special-paths-listing.txt"
WORKSPACE_DIRS_FILE="$DEST/manifests/workspace-projects.tsv"
WORKSPACE_STATUS_FILE="$DEST/manifests/workspace-root-status.tsv"
INTELLIJ_SECRET_CANDIDATES="$DEST/manifests/intellij-secret-candidates.txt"
INTELLIJ_SECRET_STAGED="$DEST/manifests/intellij-secrets-staged.tsv"
FILES_FILE="$DEST/manifests/files-backed-up.txt"
SUMMARY_FILE="$DEST/manifests/summary.txt"
SORT_FILE="$DEST/manifests/intellij-config-dirs-sort.tmp"
WORKSPACE_SORT_FILE="$DEST/manifests/workspace-projects-sort.tmp"

: > "$CONFIG_DIRS_FILE"
: > "$INTELLIJ_SECRET_CANDIDATES"
printf 'source_path\tstaged_path\n' > "$INTELLIJ_SECRET_STAGED"
: > "$SORT_FILE"
: > "$WORKSPACE_SORT_FILE"
: > "$SPECIAL_LISTING_FILE"

cat > "$SPECIAL_PATHS_FILE" <<EOF_SPECIAL
Description	Path
Bin directory	$IDE_BIN_DIR
Config directory	$IDE_CONFIG_DIR
IDE installation home	$IDE_INSTALLATION_HOME
IDE Runtime	$IDE_RUNTIME_HOME
LOGS folder	$IDE_LOGS_DIR
LOGS frontend log	$IDE_FRONTEND_LOG
Lib directory	$IDE_LIB_DIR
MISC Scratch directory	$IDE_MISC_SCRATCH_DIR
MISC Temp directory	$IDE_MISC_TEMP_DIR
Options directory	$IDE_OPTIONS_DIR
PLUGINS Main directory	$IDE_PLUGINS_MAIN_DIR
PLUGINS PreInstalled directory	$IDE_PLUGINS_PREINSTALLED_DIR
PROJECT BasePath used for backup	$IDE_PROJECT_BASEPATH
Workspace root scanned for all projects	$WORKSPACE_ROOT
System directory	$IDE_SYSTEM_DIR
EOF_SPECIAL

printf 'Description\tPath\tType\tSize\n' > "$SPECIAL_STATUS_FILE"
while IFS=$'\t' read -r desc path; do
  [[ "$desc" == "Description" ]] && continue
  printf '%s\t%s\t%s\t%s\n' "$desc" "$path" "$(path_type "$path")" "$(path_size "$path")" >> "$SPECIAL_STATUS_FILE"
done < "$SPECIAL_PATHS_FILE"

printf 'Workspace root\t%s\n' "$WORKSPACE_ROOT" > "$WORKSPACE_STATUS_FILE"
printf 'Workspace root type\t%s\n' "$(path_type "$WORKSPACE_ROOT")" >> "$WORKSPACE_STATUS_FILE"
printf 'Workspace root size\t%s\n' "$(path_size "$WORKSPACE_ROOT")" >> "$WORKSPACE_STATUS_FILE"
printf 'Workspace max depth\t%s\n' "$WORKSPACE_MAX_DEPTH" >> "$WORKSPACE_STATUS_FILE"
printf 'Skip workspaces\t%s\n' "$SKIP_WORKSPACES" >> "$WORKSPACE_STATUS_FILE"

safe_find_one_level "$IDE_BIN_DIR" "Bin directory" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_CONFIG_DIR" "Config directory" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_LOGS_DIR" "LOGS folder" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_LIB_DIR" "Lib directory" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_OPTIONS_DIR" "Options directory" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_PLUGINS_MAIN_DIR" "PLUGINS Main directory" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_PLUGINS_PREINSTALLED_DIR" "PLUGINS PreInstalled directory" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_PROJECT_BASEPATH" "PROJECT BasePath used for backup" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$WORKSPACE_ROOT" "Workspace root scanned for all projects" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_SYSTEM_DIR" "System directory" "$SPECIAL_LISTING_FILE"

# Choose config directories to back up.
# Default: active config directory (auto-detected or explicit IDE_PRODUCT).
# Optional: all IntelliJIdea* and IdeaIC* directories.
if [[ "$ALL_CONFIG_DIRS" -eq 1 ]]; then
  shopt -s nullglob
  CONFIG_DIRS=(
    "$JETBRAINS_ROOT"/IntelliJIdea*
    "$JETBRAINS_ROOT"/IdeaIC*
  )
  shopt -u nullglob
else
  CONFIG_DIRS=("$IDE_CONFIG_DIR")
fi

if [[ ${#CONFIG_DIRS[@]} -eq 0 || ! -d "${CONFIG_DIRS[0]}" ]]; then
  echo "WARNING: Active config directory not found: $IDE_CONFIG_DIR" >&2
  echo "Falling back to all IntelliJIdea* / IdeaIC* config directories under: $JETBRAINS_ROOT" >&2
  shopt -s nullglob
  CONFIG_DIRS=(
    "$JETBRAINS_ROOT"/IntelliJIdea*
    "$JETBRAINS_ROOT"/IdeaIC*
  )
  shopt -u nullglob
fi

if [[ ${#CONFIG_DIRS[@]} -eq 0 ]]; then
  echo "ERROR: No IntelliJIdea* or IdeaIC* config directories found under: $JETBRAINS_ROOT" >&2
  exit 2
fi

for dir in "${CONFIG_DIRS[@]}"; do
  [[ -d "$dir" ]] || continue
  printf '%s\t%s\n' "$(mtime_epoch "$dir")" "$dir" >> "$SORT_FILE"
done

SORTED_COUNT="$(wc -l < "$SORT_FILE" | tr -d ' ')"
if [[ "$SORTED_COUNT" -eq 0 ]]; then
  echo "ERROR: No usable IntelliJ config directories found under: $JETBRAINS_ROOT" >&2
  exit 2
fi

printf 'mtime_epoch\tconfig_dir\n' > "$CONFIG_DIRS_FILE"
sort -rn "$SORT_FILE" >> "$CONFIG_DIRS_FILE"

copy_dir_if_exists() {
  local src="$1"
  local dst="$2"
  local label="$3"

  if [[ -d "$src" ]]; then
    mkdir -p "$dst"
    echo "Copying $label"
    rsync -aE ${RSYNC_EXCLUDE_ARGS[@]+"${RSYNC_EXCLUDE_ARGS[@]}"} "$src/" "$dst/"
  fi
}

copy_file_if_exists() {
  local src="$1"
  local dst_dir="$2"
  local label="$3"

  if [[ -f "$src" ]]; then
    mkdir -p "$dst_dir"
    echo "Copying $label"
    cp -p "$src" "$dst_dir/"
  fi
}

copy_project_idea_if_exists() {
  local idea_dir="$1"
  local project_dir
  local rel
  local label
  local project_dest

  project_dir="$(dirname "$idea_dir")"
  rel="$(make_relative_to_workspace_root "$project_dir")"
  label="$(sanitize_for_manifest_label "$rel")"
  project_dest="$DEST/project-metadata/$rel"

  mkdir -p "$project_dest"
  echo "Copying project-level IntelliJ metadata: $label/.idea"

  rsync -aE ${RSYNC_EXCLUDE_ARGS[@]+"${RSYNC_EXCLUDE_ARGS[@]}"} "$idea_dir/" "$project_dest/.idea/"

  printf '%s\t%s\t%s\n' "$rel" "$project_dir" "$idea_dir" >> "$WORKSPACE_DIRS_FILE"
}

# Resolve the reviewed IntelliJ secret patterns before scanning. Mirrors
# gitignore-review-template.txt: nothing is pre-selected; the review file's [x]
# marks drive staging. On first use it is written to the external artifact root
# (all unchecked) and nothing is staged until you check patterns and rerun.
if [[ -f "$INTELLIJ_SECRETS_TEMPLATE" ]]; then
  load_intellij_secret_patterns "$INTELLIJ_SECRETS_TEMPLATE"
  build_find_predicate
  echo "Using IntelliJ secret selections: $INTELLIJ_SECRETS_TEMPLATE"
  echo "  Checked patterns: ${#SELECTED_PATTERNS[@]}"
else
  write_intellij_secret_template "$INTELLIJ_SECRETS_TEMPLATE"
  echo "NOTE: No IntelliJ secret review template found; wrote a fresh one (all unchecked):" >&2
  echo "  $INTELLIJ_SECRETS_TEMPLATE" >&2
  echo "  Check the patterns you want staged, then rerun to stage them." >&2
fi

# Seed the operator-maintained plaintext-exclude list on first use, then build
# the effective rsync exclude set applied to every clear-text copy below.
if [[ -n "$INTELLIJ_EXCLUDE_LIST" && ! -f "$INTELLIJ_EXCLUDE_LIST" ]]; then
  write_intellij_exclude_list "$INTELLIJ_EXCLUDE_LIST"
  echo "NOTE: Wrote a starter IntelliJ plaintext-exclude list (edit to taste):" >&2
  echo "  $INTELLIJ_EXCLUDE_LIST" >&2
fi
build_rsync_exclude_args

while IFS=$'\t' read -r _mtime config_dir; do
  [[ -n "${config_dir:-}" && -d "$config_dir" ]] || continue

  product="$(basename "$config_dir")"
  product_dest="$DEST/$product"
  mkdir -p "$product_dest/config-copy" "$product_dest/scratches-and-consoles" "$product_dest/manifests"

  echo "Backing up IntelliJ config: $config_dir"

  copy_dir_if_exists "$config_dir/scratches" "$product_dest/scratches-and-consoles/scratches" "$product scratches"
  copy_dir_if_exists "$config_dir/consoles" "$product_dest/scratches-and-consoles/consoles" "$product consoles"

  for d in codestyles colors fileTemplates filetypes inspection inspectionProfiles keymaps options templates tools settingsSync plugins jdbc-drivers tasks; do
    copy_dir_if_exists "$config_dir/$d" "$product_dest/config-copy/$d" "$product $d"
  done

  if [[ ${#FIND_PRED[@]} -gt 0 ]]; then
    while IFS= read -r secret_file; do
      stage_one_intellij_secret "$secret_file"
    done < <(find "$config_dir" -type f \( "${FIND_PRED[@]}" \) -print 2>/dev/null)
  fi

done < <(sort -rn "$SORT_FILE")

# Copy project-level IntelliJ metadata for every workspace/project under the workspace root.
# IntelliJ's Special Files and Folders PROJECT BasePath only reflects the currently open project,
# so this separate scan is what ensures all workspaces are represented.
printf 'relative_project_path\tproject_path\tidea_dir\n' > "$WORKSPACE_DIRS_FILE"
WORKSPACE_COUNT=0
if [[ "$SKIP_WORKSPACES" -eq 0 ]]; then
  if [[ -n "$WORKSPACE_ROOT" && -d "$WORKSPACE_ROOT" ]]; then
    while IFS= read -r idea_dir; do
      [[ -d "$idea_dir" ]] || continue
      project_dir="$(dirname "$idea_dir")"
      printf '%s\t%s\n' "$(mtime_epoch "$project_dir")" "$idea_dir" >> "$WORKSPACE_SORT_FILE"
    done < <(
      find "$WORKSPACE_ROOT" \
        -maxdepth "$WORKSPACE_MAX_DEPTH" \
        -type d \
        -name '.idea' \
        -not -path '*/.git/*' \
        -not -path '*/node_modules/*' \
        -not -path '*/.gradle/*' \
        -not -path '*/build/*' \
        -not -path '*/target/*' \
        -not -path '*/dist/*' \
        -not -path '*/out/*' \
        -not -path '*/.venv/*' \
        -not -path '*/venv/*' \
        -print 2>/dev/null
    )

    if [[ -s "$WORKSPACE_SORT_FILE" ]]; then
      while IFS=$'\t' read -r _mtime idea_dir; do
        [[ -d "$idea_dir" ]] || continue
        copy_project_idea_if_exists "$idea_dir"
        WORKSPACE_COUNT=$((WORKSPACE_COUNT + 1))
      done < <(sort -rn "$WORKSPACE_SORT_FILE")
    fi

    # Stage project-level secrets matching the reviewed patterns under workspaces.
    if [[ ${#FIND_PRED[@]} -gt 0 ]]; then
      while IFS= read -r secret_file; do
        stage_one_intellij_secret "$secret_file"
      done < <(
        find "$WORKSPACE_ROOT" \
          -maxdepth "$WORKSPACE_MAX_DEPTH" \
          -type f \( "${FIND_PRED[@]}" \) \
          -not -path '*/.git/*' \
          -not -path '*/node_modules/*' \
          -not -path '*/.gradle/*' \
          -not -path '*/build/*' \
          -not -path '*/target/*' \
          -not -path '*/dist/*' \
          -not -path '*/out/*' \
          -not -path '*/.venv/*' \
          -not -path '*/venv/*' \
          -print 2>/dev/null
      )
    fi
  elif [[ -z "$WORKSPACE_ROOT" ]]; then
    echo "NOTE: No workspace root set, skipping project-level workspace scan. Pass --workspace-root or export INTELLIJ_WORKSPACE_ROOT." >&2
  else
    echo "WARNING: Workspace root not found, skipping project-level workspace scan: $WORKSPACE_ROOT" >&2
  fi
fi

# Diagnostic logs are useful to preserve before a reimage and are generally not needed for restore.
copy_dir_if_exists "$IDE_LOGS_DIR" "$DEST/logs/$IDE_PRODUCT" "$IDE_PRODUCT logs"
copy_file_if_exists "$IDE_FRONTEND_LOG" "$DEST/logs/$IDE_PRODUCT" "$IDE_PRODUCT frontend idea.log"

# System/cache directory is recorded by default, but not copied unless explicitly requested.
if [[ "$INCLUDE_SYSTEM_CACHE" -eq 1 ]]; then
  copy_dir_if_exists "$IDE_SYSTEM_DIR" "$DEST/logs/system-cache/$IDE_PRODUCT" "$IDE_PRODUCT system/cache directory"
else
  {
    echo "System/cache directory was not copied by default."
    echo "Path: $IDE_SYSTEM_DIR"
    echo "Reason: Caches are usually large and are not normally needed for restore."
    echo "To copy it for diagnostics, rerun with --include-system-cache."
  } > "$DEST/logs/system-cache-not-copied.txt"
fi

rm -f "$SORT_FILE" "$WORKSPACE_SORT_FILE"
sort -u "$INTELLIJ_SECRET_CANDIDATES" -o "$INTELLIJ_SECRET_CANDIDATES"
find "$DEST" -type f | sort > "$FILES_FILE"

cat > "$SUMMARY_FILE" <<EOF_SUMMARY
IntelliJ backup created: $DEST
Script version: $SCRIPT_VERSION
Artifact root: $ARTIFACT_ROOT
JetBrains root: $JETBRAINS_ROOT
Active IDE product (auto-detected): $IDE_PRODUCT
Active config directory: $IDE_CONFIG_DIR
Config directories backed up: $SORTED_COUNT
Workspace root scanned: $WORKSPACE_ROOT
Workspace max depth: $WORKSPACE_MAX_DEPTH
Project-level .idea workspaces backed up: $WORKSPACE_COUNT
Include .idea/shelf: $INCLUDE_SHELF
Files copied: $(wc -l < "$FILES_FILE" | tr -d ' ')
IntelliJ secret candidates matched: $(wc -l < "$INTELLIJ_SECRET_CANDIDATES" | tr -d ' ')
IntelliJ secrets staged to secrets-encrypted/intellij/: $INTELLIJ_STAGED_COUNT
Secret pattern selections: $INTELLIJ_SECRETS_TEMPLATE
Plaintext exclude list: $INTELLIJ_EXCLUDE_LIST
System/cache copied: $INCLUDE_SYSTEM_CACHE

Special Files and Folders manifests:
  $SPECIAL_PATHS_FILE
  $SPECIAL_STATUS_FILE
  $SPECIAL_LISTING_FILE

Project metadata manifests:
  $WORKSPACE_STATUS_FILE
  $WORKSPACE_DIRS_FILE

Coverage check:
  awk -F '\t' 'FNR > 1 {print \$1}' "$WORKSPACE_DIRS_FILE" | sort

Project BasePath note:
  IntelliJ's Special Files and Folders PROJECT BasePath changes depending on which project/window
  is active. This script uses the broader workspace root for coverage by default:
    $WORKSPACE_ROOT

Next step:
  Review ${INTELLIJ_SECRETS_TEMPLATE:-the IntelliJ secret review template} and check the patterns
  you want staged, then rerun to stage the matches into secrets-encrypted/intellij/.
  Run create-secrets-dmg.sh (Phase 3B) afterward to encrypt them into the DMG.

Manual step:
  Export IntelliJ settings ZIP from IntelliJ IDEA -> File -> Manage IDE Settings -> Export Settings
  Save it under:
    $ARTIFACT_ROOT/app-settings-backup/intellij/manual-settings-export/
EOF_SUMMARY

cat "$SUMMARY_FILE"

if [[ "$INTELLIJ_STAGED_COUNT" -gt 0 ]]; then
  echo
  echo "Staged $INTELLIJ_STAGED_COUNT IntelliJ secret file(s) into:"
  echo "  $INTELLIJ_SECRETS_DEST/by-source/"
  echo "Manifest: $INTELLIJ_SECRET_STAGED"
elif [[ -n "$INTELLIJ_SECRETS_TEMPLATE" && -f "$INTELLIJ_SECRETS_TEMPLATE" ]]; then
  echo
  echo "No IntelliJ secrets staged. Check patterns in the review template and rerun:"
  echo "  $INTELLIJ_SECRETS_TEMPLATE"
fi
