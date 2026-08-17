#!/usr/bin/env bash
# =============================================================================
# backup-intellij-state.sh
#
# Internal helper for backup-apps.sh (Phase 2D). Backs up IntelliJ IDEA state:
# Scratches and Consoles, selected global IDE config, project-level .idea
# metadata across the projects root, and diagnostic logs. Keeps secret-shaped
# material out of the clear-text copy and stages the files matching your reviewed
# patterns into secrets-encrypted/intellij/ for the encrypted secrets workflow.
#
# This file lives in .internal/apps/ and is normally invoked by
# bin/backup-apps.sh. Shared reimage config is intentionally NOT loaded here;
# the caller passes --artifact-root (and, from the entrypoint, --projects-root)
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
#   .internal/apps/backup-intellij-state.sh --artifact-root /path/to/reimage-artifact-root --projects-root /path/to/projects
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
#   --review-dir PATH         Directory holding the two review-selection files
#                              (intellij-secret-review-template.txt and
#                              intellij-plaintext-exclude-list.txt). Read AND
#                              seeded here, so selections survive a reimage.
#                              Also honored from an exported
#                              INTELLIJ_REVIEW_SOURCE_DIR. When unset, the
#                              artifact root's own secret-review/ is used for
#                              both. A copy of whatever was used is always
#                              written into the artifact root as evidence.
#
#   --projects-root PATH      Root containing all IntelliJ projects
#                              to scan for project-level .idea metadata. No
#                              baked-in default: the entrypoint supplies it from
#                              GIT_WORK_REPO_ROOT; for standalone use, pass this
#                              flag (or export INTELLIJ_PROJECTS_ROOT). When
#                              unset, the project-level scan is skipped.
#                              This is intentionally broader than IntelliJ's
#                              PROJECT BasePath, which only reflects the
#                              currently open project/window.
#
#   --projects-max-depth N    Max depth used when finding .idea directories
#                              under --projects-root. Default: 6
#
#   --skip-project-scan          Do not scan/copy project-level .idea metadata
#                              from the projects root.
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
#   - Scans the projects root and copies project-level .idea metadata for every
#     project it finds, not just the one currently open in IntelliJ.
#   - Copies IntelliJ logs for diagnostics.
#   - Records app bundle, runtime, lib, preinstalled plugins, system/cache, temp, current
#     Project BasePath concept, and projects root in manifests.
#   - Keeps secret-shaped files out of the clear-text copy, and stages the files
#     matching your reviewed patterns (intellij-secret-review-template.txt) into
#     secrets-encrypted/intellij/{ide-config,projects}/. Nothing is staged unless checked.
#
# Security note:
#   Run create-secrets-dmg.sh (Phase 3C) after this script to encrypt the staged
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
SKIP_PROJECT_SCAN=0
INCLUDE_SHELF=0
PROJECTS_MAX_DEPTH=6
# No baked-in default: the entrypoint passes --projects-root from
# GIT_WORK_REPO_ROOT, and standalone callers pass it (or export
# INTELLIJ_PROJECTS_ROOT). When empty, the project-level scan is skipped.
PROJECTS_ROOT="${INTELLIJ_PROJECTS_ROOT:-}"
# Durable review-selection directory. The entrypoint passes --review-dir from
# INTELLIJ_REVIEW_SOURCE_DIR (workspace-first, resolved in artifact-config.sh).
# Empty means "read and seed inside the artifact root", the historical behavior.
REVIEW_SOURCE_DIR="${INTELLIJ_REVIEW_SOURCE_DIR:-}"
INIT_REVIEW_ONLY=0

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
    -h|--help)
      usage
      exit 0
      ;;
    --artifact-root)
      require_option_value "$1" "${2:-}"
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
    --skip-project-scan)
      SKIP_PROJECT_SCAN=1
      shift
      ;;
    --include-shelf)
      INCLUDE_SHELF=1
      shift
      ;;
    --init-review-only)
      INIT_REVIEW_ONLY=1
      shift
      ;;
    --review-dir)
      require_option_value "$1" "${2:-}"
      REVIEW_SOURCE_DIR="$2"
      shift 2
      ;;
    --review-dir=*)
      REVIEW_SOURCE_DIR="${1#*=}"
      shift
      ;;
    --projects-root)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --projects-root requires a path" >&2
        exit 2
      fi
      PROJECTS_ROOT="$2"
      shift 2
      ;;
    --projects-root=*)
      PROJECTS_ROOT="${1#*=}"
      shift
      ;;
    --projects-max-depth)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --projects-max-depth requires a number" >&2
        exit 2
      fi
      PROJECTS_MAX_DEPTH="$2"
      shift 2
      ;;
    --projects-max-depth=*)
      PROJECTS_MAX_DEPTH="${1#*=}"
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

case "$PROJECTS_MAX_DEPTH" in
  ''|*[!0-9]*)
    echo "ERROR: --projects-max-depth must be a positive integer" >&2
    exit 2
    ;;
esac

if [[ "$INIT_REVIEW_ONLY" -eq 1 ]]; then
  # Seeding the durable review copy touches no artifact root and reads no
  # JetBrains state, so it must not demand either. It runs before a drive is
  # even mounted.
  if [[ -z "$REVIEW_SOURCE_DIR" ]]; then
    echo "ERROR: --init-review-only requires --review-dir PATH." >&2
    exit 2
  fi
elif [[ -z "$ARTIFACT_ROOT" ]]; then
  echo "ERROR: artifact root not set. Pass --artifact-root PATH (or export REIMAGE_ARTIFACT_ROOT)." >&2
  exit 2
fi

INTELLIJ_ROOT="$ARTIFACT_ROOT/app-settings-backup/intellij"
DEST="$INTELLIJ_ROOT"
JETBRAINS_ROOT="$HOME/Library/Application Support/JetBrains"

if [[ ! -d "$JETBRAINS_ROOT" && "$INIT_REVIEW_ONLY" -ne 1 ]]; then
  echo "ERROR: JetBrains config root not found: $JETBRAINS_ROOT" >&2
  exit 2
fi

# Encrypted-secrets destination for staged IntelliJ secrets, and the review
# selection files.
#
# Two directories, deliberately:
#   REVIEW_SOURCE_DIR   durable, survives the artifact root. Read AND seeded
#                       here when set, so your selections outlive a reimage.
#   ..._REVIEW_EVIDENCE the artifact root's own secret-review/. Always written,
#                       so the capture carries a copy of exactly what it obeyed.
# When REVIEW_SOURCE_DIR is empty the two collapse into one — the artifact root
# is both, which is the historical behavior.
INTELLIJ_SECRETS_DEST="$ARTIFACT_ROOT/secrets-encrypted/intellij"
INTELLIJ_SECRETS_REVIEW_EVIDENCE_DIR="$ARTIFACT_ROOT/app-settings-backup/intellij/secret-review"
if [[ -n "$REVIEW_SOURCE_DIR" ]]; then
  INTELLIJ_SECRETS_REVIEW_DIR="$REVIEW_SOURCE_DIR"
else
  INTELLIJ_SECRETS_REVIEW_DIR="$INTELLIJ_SECRETS_REVIEW_EVIDENCE_DIR"
fi
INTELLIJ_SECRETS_TEMPLATE="$INTELLIJ_SECRETS_REVIEW_DIR/intellij-secret-review-template.txt"
INTELLIJ_EXCLUDE_LIST="$INTELLIJ_SECRETS_REVIEW_DIR/intellij-plaintext-exclude-list.txt"
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
  # Explicit `return 0`: a trailing `[[ ... ]] && basename` returns 1 when no
  # directory was found, which under `set -e` kills the caller at the
  # IDE_PRODUCT assignment below and makes its "no config dir" error handler
  # unreachable. Printing nothing IS the "none found" signal.
  if [[ -n "$newest" ]]; then
    basename "$newest"
  fi
  return 0
}

# Active paths from IntelliJ IDEA -> Help -> Diagnostic Tools -> Special Files and Folders.
# Override any of these with environment variables if the active IDE version/path changes.
# IDE_PRODUCT defaults to the auto-detected active (most recently modified) config directory.
IDE_PRODUCT="${IDE_PRODUCT:-$(detect_newest_config_dir)}"
if [[ -z "$IDE_PRODUCT" && "$INIT_REVIEW_ONLY" -ne 1 ]]; then
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
# For backup coverage, use the broader projects root by default.
IDE_PROJECT_BASEPATH="${IDE_PROJECT_BASEPATH:-$PROJECTS_ROOT}"
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

make_relative_to_projects_root() {
  local path="$1"
  if [[ "$path" == "$PROJECTS_ROOT" ]]; then
    printf '.'
  elif [[ "$path" == "$PROJECTS_ROOT"/* ]]; then
    printf '%s' "${path#"$PROJECTS_ROOT"/}"
  else
    basename "$path"
  fi
}

sanitize_for_manifest_label() {
  # Keep the real relative path in manifests. This helper is only used where a label cannot be empty.
  local value="$1"
  if [[ -z "$value" || "$value" == "." ]]; then
    basename "$PROJECTS_ROOT"
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
    echo "# projects root are copied into the encrypted-secrets tree so Phase 3C"
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
# The patterns that describe IntelliJ's OWN files. Used for the project scan,
# which walks $PROJECTS_ROOT -- the same tree backup-repos.sh walks, since the
# entrypoint defaults it to $GIT_WORK_REPO_ROOT.
#
# The generic half of the seed list (*credential*, *secret*, *.pem, *.key, ...)
# matches ordinary repo files. Those are gitignored, so Phase 2A stages them
# into secrets-encrypted/repos-gitignored/ after a review this scan does not
# perform -- capturing them here put the same file in the Phase 3C DMG twice,
# from two staging areas, only one of them reviewed. Inside the JetBrains config
# directory the generic patterns still apply in full: everything there is
# IntelliJ's.
INTELLIJ_OWNED_PATTERNS=(
  'http-client.env.json'
  'http-client.private.env.json'
  '*.env.json'
  '*.private.env.json'
  'dataSources.local.xml'
  'dataSourcesLocal.xml'
)

FIND_PRED_IDE=()

# Build FIND_PRED_IDE from the reviewed selections, intersected with the
# IDE-owned set. The operator still opts in per pattern; this only bounds which
# of their selections reach outside IntelliJ's own directories.
build_find_predicate_ide_owned() {
  local p owned first=true
  FIND_PRED_IDE=()
  (( ${#SELECTED_PATTERNS[@]} > 0 )) || return 0
  for p in "${SELECTED_PATTERNS[@]}"; do
    for owned in "${INTELLIJ_OWNED_PATTERNS[@]}"; do
      if [[ "$p" == "$owned" ]]; then
        if [[ "$first" == true ]]; then
          FIND_PRED_IDE+=(-name "$p"); first=false
        else
          FIND_PRED_IDE+=(-o -name "$p")
        fi
        break
      fi
    done
  done
  return 0
}


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
# a bucket named for the root it came from, keeping provenance and uniqueness.
# $1 = source file, $2 = bucket ("ide-config" or "projects").
#
# Each bucket is named for the root it mirrors, and the path under it is
# relative to THAT root, not to $HOME. A JetBrains options file lands at
# ide-config/<product>/options/... rather than
# the old flat by-root mirror rooted at $HOME.
#
# Path mirroring itself is load-bearing: one credentials.yml per repo would
# collapse into a single file if these were keyed by basename.
stage_one_intellij_secret() {
  local src="$1"
  local bucket="${2:-projects}"
  local rel dst root=""
  [[ -f "$src" ]] || return 0

  # Finder metadata is not a secret and has no business in the encrypted DMG.
  [[ "$(basename "$src")" == ".DS_Store" ]] && return 0

  printf '%s\n' "$src" >> "$INTELLIJ_SECRET_CANDIDATES"

  case "$bucket" in
    ide-config) root="$JETBRAINS_ROOT" ;;
    projects)   root="$PROJECTS_ROOT" ;;
  esac

  if [[ -n "$root" && "$src" == "$root"/* ]]; then
    rel="${src#"$root"/}"
  else
    # Neither root matched: keep the file, but somewhere obviously unusual
    # rather than silently misfiled under a bucket it did not come from.
    bucket="other"
    rel="${src#"$HOME"/}"
  fi
  rel="${rel#/}"
  dst="$INTELLIJ_SECRETS_DEST/$bucket/$rel"
  mkdir -p "$(dirname "$dst")"
  if cp -p "$src" "$dst" 2>/dev/null; then
    printf '%s\t%s\n' "$src" "$dst" >> "$INTELLIJ_SECRET_STAGED"
    INTELLIJ_STAGED_COUNT=$((INTELLIJ_STAGED_COUNT + 1))
  else
    printf '%s\t%s\n' "$src" "COPY-FAILED" >> "$INTELLIJ_SECRET_STAGED"
  fi
}

# Operator-maintained noise excludes for the clear-text IntelliJ copy, seeded on
# first use. Same file format as gitignore-superset/backup-exclude-list.txt — one
# pattern per line, '#' comments and blank lines ignored — but a separate file
# with a separate purpose, hence the distinct name. Secrets are handled by the
# review template, not here.
INTELLIJ_EXCLUDE_SEED=(
  'httpRequests/'
  'httpRequests/**'
  'shelf/'
  'shelf/**'
  '.DS_Store'
)

# Secret-shape floor: always excluded from the clear-text copy even when no
# review template exists, so credential-shaped files never leak into plaintext.
#
# This is the SEED LIST ITSELF, not a subset of it. The floor only applies on a
# first run, before a review template exists to populate ALL_PATTERNS — which is
# exactly the run that has had no human review, so it is the run that most needs
# the full set. A narrower floor silently copied *.pem, *.key, *credential* and
# the rest into app-settings-backup/, which Phase 3C never encrypts.
INTELLIJ_SECRET_EXCLUDE_FLOOR=( "${INTELLIJ_SECRET_SEED_PATTERNS[@]}" )

RSYNC_EXCLUDE_ARGS=()

write_intellij_exclude_list() {
  local dest="$1" p
  mkdir -p "$(dirname "$dest")"
  {
    echo "# intellij-plaintext-exclude-list.txt  (Exclude — drop noise from the clear-text IntelliJ copy)"
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

# Seed the durable review directory and stop. Placed here because it is the
# first point where BOTH writers exist; putting it next to the argument parser
# would mean duplicating the seed lists, which is the whole thing this file is
# the single source of.
if [[ "$INIT_REVIEW_ONLY" -eq 1 ]]; then
  mkdir -p "$INTELLIJ_SECRETS_REVIEW_DIR"
  init_wrote=0
  if [[ -f "$INTELLIJ_SECRETS_TEMPLATE" ]]; then
    echo "Kept existing: $INTELLIJ_SECRETS_TEMPLATE"
  else
    write_intellij_secret_template "$INTELLIJ_SECRETS_TEMPLATE"
    echo "Wrote: $INTELLIJ_SECRETS_TEMPLATE"
    init_wrote=$((init_wrote + 1))
  fi
  if [[ -f "$INTELLIJ_EXCLUDE_LIST" ]]; then
    echo "Kept existing: $INTELLIJ_EXCLUDE_LIST"
  else
    write_intellij_exclude_list "$INTELLIJ_EXCLUDE_LIST"
    echo "Wrote: $INTELLIJ_EXCLUDE_LIST"
    init_wrote=$((init_wrote + 1))
  fi
  echo ""
  if [[ "$init_wrote" -gt 0 ]]; then
    echo "Every pattern is UNCHECKED. Nothing is staged as a secret until you"
    echo "change '[ ]' to '[x]' in the review template above."
  fi
  echo "These files now survive the artifact root. Future runs read them from here."
  exit 0
fi

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

# A running IDE flushes and rewrites config while the copy is in progress, so a
# capture taken then can be partial in ways nothing downstream can detect. The
# runbook has always said to quit IntelliJ first; this makes the script say it
# too, and — more importantly — records it in the artifact so a partial capture
# cannot later be mistaken for a complete one.
INTELLIJ_WAS_RUNNING=false
# Match the process NAME exactly. IntelliJ's executable is Contents/MacOS/idea,
# so a name match is both reliable and immune to the false positives a
# command-line match invites — this script's own path contains "intellij", and
# the capture writes an IntelliJIdea<version>/ directory.
# Same form as the OneDrive check in backup-home.sh.
if pgrep -qx "idea" 2>/dev/null; then
  INTELLIJ_WAS_RUNNING=true
  echo "" >&2
  echo "WARNING: IntelliJ appears to be RUNNING." >&2
  echo "         A live IDE rewrites config mid-copy, so this capture may be" >&2
  echo "         partial — and a partial config-copy looks exactly like a" >&2
  echo "         complete one on disk." >&2
  echo "         Quit IntelliJ and rerun: ./bin/backup-apps.sh --intellij-only" >&2
  echo "         Continuing anyway; the capture will be marked as taken with the" >&2
  echo "         IDE running." >&2
  echo "" >&2
fi

mkdir -p "$DEST" "$DEST/manual-settings-export" "$DEST/restore-notes"

# These two are drop targets for material this script cannot produce: the
# settings ZIP you export from IntelliJ's UI, and the restore notes you write.
# They are created empty, and backup-apps.sh prunes empty directories at the end
# of a full run — which deleted both before this README existed. A README keeps
# them alive and says what belongs in them.
if [[ ! -f "$DEST/manual-settings-export/README.txt" ]]; then
  {
    echo "Manual IntelliJ settings export"
    echo ""
    echo "Export from IntelliJ: File > Manage IDE Settings > Export Settings."
    echo "Save the ZIP here as IntelliJ-settings-YYYYMMDD-HHMMSS.zip."
    echo ""
    echo "This is a second restore path, independent of the scripted capture in"
    echo "config-copy/. It is usually the easier one to import after a reimage."
    echo "The scripted capture does not produce it — see backup-intellij.md."
  } > "$DEST/manual-settings-export/README.txt"
fi

if [[ ! -f "$DEST/restore-notes/README.txt" ]]; then
  {
    echo "IntelliJ restore notes"
    echo ""
    echo "Write down anything the captured files will not tell you after the"
    echo "reimage: licence/account sign-in details, plugins that need manual"
    echo "reinstall, per-project SDK or JDK paths to re-point, and any setting"
    echo "you deliberately chose not to carry forward."
    echo ""
    echo "Nothing here is generated. An empty folder means no notes were taken."
  } > "$DEST/restore-notes/README.txt"
fi
mkdir -p "$ARTIFACT_ROOT/secrets-encrypted/intellij"

rm -rf "$DEST/project-metadata" "$DEST/manifests" "$DEST/logs"
shopt -s nullglob
generated_product_dirs=("$DEST"/IntelliJIdea* "$DEST"/IdeaIC*)
if [[ ${#generated_product_dirs[@]} -gt 0 ]]; then
  rm -rf "${generated_product_dirs[@]}"
fi
shopt -u nullglob

mkdir -p "$DEST/manifests" "$DEST/logs" "$DEST/project-metadata"

if [[ "$INTELLIJ_WAS_RUNNING" == true ]]; then
  {
    echo "IntelliJ was RUNNING when this capture was taken."
    echo ""
    echo "Captured at: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "A live IDE flushes and rewrites files under its config directory while"
    echo "the copy runs, so config-copy/ may hold a partial or inconsistent"
    echo "snapshot. Nothing downstream can detect that from the files alone,"
    echo "which is why this marker exists."
    echo ""
    echo "To resolve: quit IntelliJ and rerun"
    echo "  ./bin/backup-apps.sh --intellij-only"
    echo "The rerun refreshes the generated content and removes this file."
  } > "$DEST/manifests/ide-was-running-during-capture.txt"
fi

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

Projects root scanned for project-level IntelliJ metadata:

\`\`\`text
$PROJECTS_ROOT
\`\`\`

Generated: $(date '+%Y-%m-%d %H:%M:%S')
Script version: $SCRIPT_VERSION

## Layout

\`\`\`text
$ARTIFACT_ROOT/app-settings-backup/intellij/
├── $IDE_PRODUCT/
│   ├── config-copy/
│   └── scratches-and-consoles/
├── manifests/
├── manual-settings-export/
├── project-metadata/
├── restore-notes/
├── secret-review/
├── logs/
└── README.md
\`\`\`

## Notes

- Project-level .idea metadata is copied under project-metadata/.
- IntelliJ diagnostic logs are copied under logs/.
- Secret files matching your reviewed patterns are staged into secrets-encrypted/intellij/{ide-config,projects}/ and listed in manifests/intellij-secrets-staged.tsv; the consolidated secrets DMG workflow encrypts them.
EOF_README

CONFIG_DIRS_FILE="$DEST/manifests/intellij-config-dirs.tsv"
SPECIAL_PATHS_FILE="$DEST/manifests/special-files-and-folders.tsv"
SPECIAL_STATUS_FILE="$DEST/manifests/special-paths-status.tsv"
SPECIAL_LISTING_FILE="$DEST/manifests/special-paths-listing.txt"
PROJECTS_DIRS_FILE="$DEST/manifests/projects.tsv"
PROJECTS_STATUS_FILE="$DEST/manifests/projects-root-status.tsv"
INTELLIJ_SECRET_CANDIDATES="$DEST/manifests/intellij-secret-candidates.txt"
INTELLIJ_SECRET_STAGED="$DEST/manifests/intellij-secrets-staged.tsv"
FILES_FILE="$DEST/manifests/files-backed-up.txt"
SUMMARY_FILE="$DEST/manifests/summary.txt"
SORT_FILE="$DEST/manifests/intellij-config-dirs-sort.tmp"
PROJECTS_SORT_FILE="$DEST/manifests/projects-sort.tmp"

: > "$CONFIG_DIRS_FILE"
: > "$INTELLIJ_SECRET_CANDIDATES"
printf 'source_path\tstaged_path\n' > "$INTELLIJ_SECRET_STAGED"
: > "$SORT_FILE"
: > "$PROJECTS_SORT_FILE"
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
Projects root scanned for all projects	$PROJECTS_ROOT
System directory	$IDE_SYSTEM_DIR
EOF_SPECIAL

printf 'Description\tPath\tType\tSize\n' > "$SPECIAL_STATUS_FILE"
while IFS=$'\t' read -r desc path; do
  [[ "$desc" == "Description" ]] && continue
  printf '%s\t%s\t%s\t%s\n' "$desc" "$path" "$(path_type "$path")" "$(path_size "$path")" >> "$SPECIAL_STATUS_FILE"
done < "$SPECIAL_PATHS_FILE"

printf 'Projects root\t%s\n' "$PROJECTS_ROOT" > "$PROJECTS_STATUS_FILE"
printf 'Projects root type\t%s\n' "$(path_type "$PROJECTS_ROOT")" >> "$PROJECTS_STATUS_FILE"
printf 'Projects root size\t%s\n' "$(path_size "$PROJECTS_ROOT")" >> "$PROJECTS_STATUS_FILE"
printf 'Workspace max depth\t%s\n' "$PROJECTS_MAX_DEPTH" >> "$PROJECTS_STATUS_FILE"
printf 'Skip project scan\t%s\n' "$SKIP_PROJECT_SCAN" >> "$PROJECTS_STATUS_FILE"

safe_find_one_level "$IDE_BIN_DIR" "Bin directory" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_CONFIG_DIR" "Config directory" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_LOGS_DIR" "LOGS folder" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_LIB_DIR" "Lib directory" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_OPTIONS_DIR" "Options directory" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_PLUGINS_MAIN_DIR" "PLUGINS Main directory" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_PLUGINS_PREINSTALLED_DIR" "PLUGINS PreInstalled directory" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$IDE_PROJECT_BASEPATH" "PROJECT BasePath used for backup" "$SPECIAL_LISTING_FILE"
safe_find_one_level "$PROJECTS_ROOT" "Projects root scanned for all projects" "$SPECIAL_LISTING_FILE"
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
  rel="$(make_relative_to_projects_root "$project_dir")"
  label="$(sanitize_for_manifest_label "$rel")"
  project_dest="$DEST/project-metadata/$rel"

  mkdir -p "$project_dest"
  echo "Copying project-level IntelliJ metadata: $label/.idea"

  rsync -aE ${RSYNC_EXCLUDE_ARGS[@]+"${RSYNC_EXCLUDE_ARGS[@]}"} "$idea_dir/" "$project_dest/.idea/"

  printf '%s\t%s\t%s\n' "$rel" "$project_dir" "$idea_dir" >> "$PROJECTS_DIRS_FILE"
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

# Record what this capture actually obeyed. When the selections live in the
# workspace the artifact root would otherwise carry no evidence of them, and a
# restore six months from now cannot tell which patterns were checked. Copying
# rather than symlinking is deliberate: the artifact root must stay readable on
# its own, detached from the machine that produced it.
if [[ "$INTELLIJ_SECRETS_REVIEW_DIR" != "$INTELLIJ_SECRETS_REVIEW_EVIDENCE_DIR" ]]; then
  mkdir -p "$INTELLIJ_SECRETS_REVIEW_EVIDENCE_DIR"
  for review_file in "$INTELLIJ_SECRETS_TEMPLATE" "$INTELLIJ_EXCLUDE_LIST"; do
    [[ -f "$review_file" ]] || continue
    cp -p "$review_file" "$INTELLIJ_SECRETS_REVIEW_EVIDENCE_DIR/" 2>/dev/null || true
  done
  {
    echo "# Review selections used by this capture"
    echo "#"
    echo "# These are COPIES. The editable originals live in:"
    echo "#   $INTELLIJ_SECRETS_REVIEW_DIR"
    echo "# Editing the copies here changes nothing — the next run rereads the"
    echo "# originals and overwrites these again."
    echo "#"
    echo "# Captured: $(date '+%Y-%m-%d %H:%M:%S')"
  } > "$INTELLIJ_SECRETS_REVIEW_EVIDENCE_DIR/README.md"
  echo "Review selections read from: $INTELLIJ_SECRETS_REVIEW_DIR"
  echo "  Copy recorded in artifact root: $INTELLIJ_SECRETS_REVIEW_EVIDENCE_DIR"
fi

while IFS=$'\t' read -r _mtime config_dir; do
  [[ -n "${config_dir:-}" && -d "$config_dir" ]] || continue

  product="$(basename "$config_dir")"
  product_dest="$DEST/$product"
  # Manifests are written once at the intellij/ root, not per product — do not
  # create an empty per-product manifests/ here.
  mkdir -p "$product_dest/config-copy" "$product_dest/scratches-and-consoles"

  echo "Backing up IntelliJ config: $config_dir"

  copy_dir_if_exists "$config_dir/scratches" "$product_dest/scratches-and-consoles/scratches" "$product scratches"
  copy_dir_if_exists "$config_dir/consoles" "$product_dest/scratches-and-consoles/consoles" "$product consoles"

  for d in codestyles colors fileTemplates filetypes inspection inspectionProfiles keymaps options templates tools settingsSync plugins jdbc-drivers tasks; do
    copy_dir_if_exists "$config_dir/$d" "$product_dest/config-copy/$d" "$product $d"
  done

  if [[ ${#FIND_PRED[@]} -gt 0 ]]; then
    while IFS= read -r secret_file; do
      stage_one_intellij_secret "$secret_file" ide-config
    done < <(find "$config_dir" -type f \( "${FIND_PRED[@]}" \) -print 2>/dev/null)
  fi

done < <(sort -rn "$SORT_FILE")

# Copy project-level IntelliJ metadata for every project under the projects root.
# IntelliJ's Special Files and Folders PROJECT BasePath only reflects the currently open project,
# so this separate scan is what ensures all projects are represented.
printf 'relative_project_path\tproject_path\tidea_dir\n' > "$PROJECTS_DIRS_FILE"
PROJECTS_COUNT=0
if [[ "$SKIP_PROJECT_SCAN" -eq 0 ]]; then
  if [[ -n "$PROJECTS_ROOT" && -d "$PROJECTS_ROOT" ]]; then
    while IFS= read -r idea_dir; do
      [[ -d "$idea_dir" ]] || continue
      project_dir="$(dirname "$idea_dir")"
      printf '%s\t%s\n' "$(mtime_epoch "$project_dir")" "$idea_dir" >> "$PROJECTS_SORT_FILE"
    done < <(
      find "$PROJECTS_ROOT" \
        -maxdepth "$PROJECTS_MAX_DEPTH" \
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

    if [[ -s "$PROJECTS_SORT_FILE" ]]; then
      while IFS=$'\t' read -r _mtime idea_dir; do
        [[ -d "$idea_dir" ]] || continue
        copy_project_idea_if_exists "$idea_dir"
        PROJECTS_COUNT=$((PROJECTS_COUNT + 1))
      done < <(sort -rn "$PROJECTS_SORT_FILE")
    fi

    # Stage project-level secrets found under the projects root.
      build_find_predicate_ide_owned
    if [[ ${#FIND_PRED_IDE[@]} -gt 0 ]]; then
      while IFS= read -r secret_file; do
        stage_one_intellij_secret "$secret_file" projects
      done < <(
        find "$PROJECTS_ROOT" \
          -maxdepth "$PROJECTS_MAX_DEPTH" \
          -type f \( "${FIND_PRED_IDE[@]}" \) \
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
  elif [[ -z "$PROJECTS_ROOT" ]]; then
    echo "NOTE: No projects root set, skipping the project-level scan. Pass --projects-root or export INTELLIJ_PROJECTS_ROOT." >&2
  else
    echo "WARNING: Projects root not found, skipping the project-level scan: $PROJECTS_ROOT" >&2
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

rm -f "$SORT_FILE" "$PROJECTS_SORT_FILE"
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
Projects root scanned: $PROJECTS_ROOT
Workspace max depth: $PROJECTS_MAX_DEPTH
Project-level .idea directories backed up: $PROJECTS_COUNT
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
  $PROJECTS_STATUS_FILE
  $PROJECTS_DIRS_FILE

Coverage check:
  awk -F '\t' 'FNR > 1 {print \$1}' "$PROJECTS_DIRS_FILE" | sort

Project BasePath note:
  IntelliJ's Special Files and Folders PROJECT BasePath changes depending on which project/window
  is active. This script uses the broader projects root for coverage by default:
    $PROJECTS_ROOT

Next step:
  Review ${INTELLIJ_SECRETS_TEMPLATE:-the IntelliJ secret review template} and check the patterns
  you want staged, then rerun to stage the matches into secrets-encrypted/intellij/.
  Run create-secrets-dmg.sh (Phase 3C) afterward to encrypt them into the DMG.

Manual step:
  Export IntelliJ settings ZIP from IntelliJ IDEA -> File -> Manage IDE Settings -> Export Settings
  Save it under:
    $ARTIFACT_ROOT/app-settings-backup/intellij/manual-settings-export/
EOF_SUMMARY

cat "$SUMMARY_FILE"

if [[ "$INTELLIJ_STAGED_COUNT" -gt 0 ]]; then
  echo
  echo "Staged $INTELLIJ_STAGED_COUNT IntelliJ secret file(s) into:"
  echo "  $INTELLIJ_SECRETS_DEST/{ide-config,projects}/"
  echo "Manifest: $INTELLIJ_SECRET_STAGED"
elif [[ -n "$INTELLIJ_SECRETS_TEMPLATE" && -f "$INTELLIJ_SECRETS_TEMPLATE" ]]; then
  echo
  echo "No IntelliJ secrets staged. Check patterns in the review template and rerun:"
  echo "  $INTELLIJ_SECRETS_TEMPLATE"
fi
