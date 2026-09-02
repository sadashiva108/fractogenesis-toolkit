#!/usr/bin/env bash
# =============================================================================
# artifact-config.sh
#
# Source-only foundation config for the Mac reimage workflow. It loads local,
# resolved values from reimage.env, applies shared defaults, selects the active
# artifact-config fragment directory, sources the required fragments, and
# exposes the shared variables, arrays, and helper functions used by workflow
# entrypoints and internal helpers.
#
# This file is normally sourced through .internal/load-reimage-config.sh. It is
# not a standalone command and does not parse command-line arguments, perform
# workflow work, or change shell options in the caller.
#
# --- BEGIN USAGE ---
# Usage:
#   # Preferred: source the shared loader from an entrypoint or helper.
#   source "$REPO_ROOT/.internal/load-reimage-config.sh"
#
#   # Direct sourcing is supported for foundation/bootstrap code that needs the
#   # artifact config without the wrapper loader.
#   source "/path/to/repo/.internal/artifact-config.sh"
#
# Optional caller controls set before sourcing:
#   REIMAGE_ENV
#       Override the local environment file.
#       Default: <repo-root>/reimage.env
#
#   ARTIFACT_CONFIG_DIR
#       Override the directory containing reusable *.conf.sh fragments.
#
#   ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT
#       Set to true to fail config loading when REIMAGE_ARTIFACT_ROOT is empty.
#       Default: false.
#
# Configuration precedence:
#   1. Values already present in the caller environment.
#   2. Values loaded from reimage.env.
#
#   Rule 1 holds for every key reimage.env sets, by set-ness rather than by
#   non-emptiness: an exported empty value is a value. The exception is the
#   handful of keys this file resolves and defaults by name -- REIMAGE_ARTIFACT_ROOT,
#   the external volumes, the ONEDRIVE_* group and ARTIFACT_CONFIG_DIR -- where a
#   caller value wins only when it is non-empty, so an accidentally-blank export
#   cannot erase a default the whole workflow depends on.
#   3. Defaults defined by this file.
#
# Artifact-config fragment precedence:
#   1. Caller- or reimage.env-provided ARTIFACT_CONFIG_DIR.
#   2. $REIMAGE_WORKSPACE_ROOT/artifact-config when that directory exists.
#   3. Committed templates under .internal/templates/artifact-config.
#
# Staged-certs fragment precedence (same shape, resolved here so the cert
# staging entrypoint and the toolkit snapshot agree on which copy a run reads):
#   1. $REIMAGE_WORKSPACE_ROOT/staged-certs when that directory exists.
#   2. Committed templates under .internal/templates/staged-certs.
#
# Repo-plan fragment precedence (identical shape):
#   1. $REIMAGE_WORKSPACE_ROOT/repo-plan when that directory exists.
#   2. Committed templates under .internal/templates/repo-plan.
# Seed the durable copy with: ./bin/restore-repos.sh init-repo-plan-config
# Resolution only -- this file does not source staged-certs fragments, and
# deliberately does not warn about the fallback, because most callers never read
# them. bin/stage-certs-keychain.sh warns when the fallback actually matters.
#
# IntelliJ review-file precedence (same shape, one difference — there is no
# committed template tier, because both files are generated from the seed lists
# in .internal/apps/backup-intellij-state.sh):
#   1. $REIMAGE_WORKSPACE_ROOT/intellij-review when that directory exists.
#   2. Empty, meaning the artifact root's own secret-review/ directory is both
#      the read source and the seed target.
# Seed the durable copy with: ./bin/backup-apps.sh --init-intellij-review
#
# Public outputs include:
#   REIMAGE_ENV
#   REIMAGE_WORKSPACE_ROOT
#   EXTERNAL_DATA_VOLUME
#   EXTERNAL_APPLE_BACKUPS_VOLUME
#   REIMAGE_ARTIFACT_ROOT
#   OFFICE_WATCH
#   ONEDRIVE_*
#   ARTIFACT_CONFIG_*
#   STAGED_CERTS_*
#   REPO_PLAN_TEMPLATE_DIR, REPO_PLAN_WORKSPACE_DIR, REPO_PLAN_SOURCE_DIR
#   INTELLIJ_REVIEW_WORKSPACE_DIR
#   INTELLIJ_REVIEW_SOURCE_DIR
#   MANUAL_POSTMAN_STAGE
#   MANUAL_RAYCAST_STAGE
#   Arrays and values declared by the required config fragments
#   config_field
#
# Source contract:
#   - Direct execution is rejected.
#   - .envrc is never sourced.
#   - The caller's set -e, set -u, and pipefail state is not changed.
#   - Generic caller variables such as SCRIPT_DIR and REPO_ROOT are not used or
#     overwritten internally.
#   - Private implementation variables and functions are removed before return.
#
# Return status when sourced:
#   0  Configuration loaded successfully.
#   2  A required path, value, environment file, or config fragment failed.
# --- END USAGE ---
# =============================================================================

# Do not use `set -euo pipefail` here. This file is sourced and must not alter
# shell options in the caller.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "ERROR: artifact-config.sh must be sourced, not executed." >&2
  echo "Use: source /path/to/.internal/artifact-config.sh" >&2
  exit 2
fi

_artifact_config_main() {
  local config_dir
  local config_path
  local fragment
  local preset_artifact_config_dir
  local _ac_named_presets _ac_preserved _ac_name _ac_value _ac_isset _ac_line

  # The keys resolved by name below. Excluded from the generic preservation so
  # their existing `:-` semantics -- caller, then reimage.env, then a default --
  # are not changed by this.
  _ac_named_presets="REIMAGE_ENV ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT REIMAGE_WORKSPACE_ROOT EXTERNAL_DATA_VOLUME EXTERNAL_APPLE_BACKUPS_VOLUME REIMAGE_ARTIFACT_ROOT OFFICE_WATCH ONEDRIVE_PARENT_DIR ONEDRIVE_FOLDER_NAME ONEDRIVE_PREFERRED_ROOT ONEDRIVE_ROOT ONEDRIVE_DEST_SUBDIR ARTIFACT_CONFIG_DIR"
  local preset_external_apple_backups_volume
  local preset_external_data_volume
  local preset_office_watch
  local preset_onedrive_parent_dir
  local preset_onedrive_dest_subdir
  local preset_onedrive_folder_name
  local preset_onedrive_preferred_root
  local preset_onedrive_root
  local preset_reimage_artifact_root
  local preset_reimage_env
  local preset_reimage_workspace_root
  local preset_require_reimage_artifact_root
  local resolved_reimage_env
  local this_dir
  local repo_root
  local -a required_fragments

  this_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || {
    echo "ERROR: unable to resolve artifact-config.sh directory." >&2
    return 2
  }
  repo_root="$(cd "$this_dir/.." && pwd)" || {
    echo "ERROR: unable to resolve repository root from: $this_dir" >&2
    return 2
  }

  # Preserve non-empty caller values before sourcing reimage.env. This retains
  # the existing precedence contract: caller environment, then reimage.env,
  # then defaults below.
  preset_reimage_env="${REIMAGE_ENV:-}"
  preset_require_reimage_artifact_root="${ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT:-}"
  preset_reimage_workspace_root="${REIMAGE_WORKSPACE_ROOT:-}"
  preset_external_data_volume="${EXTERNAL_DATA_VOLUME:-}"
  preset_external_apple_backups_volume="${EXTERNAL_APPLE_BACKUPS_VOLUME:-}"
  preset_reimage_artifact_root="${REIMAGE_ARTIFACT_ROOT:-}"
  preset_office_watch="${OFFICE_WATCH:-}"
  preset_onedrive_parent_dir="${ONEDRIVE_PARENT_DIR:-}"
  preset_onedrive_folder_name="${ONEDRIVE_FOLDER_NAME:-}"
  preset_onedrive_preferred_root="${ONEDRIVE_PREFERRED_ROOT:-}"
  preset_onedrive_root="${ONEDRIVE_ROOT:-}"
  preset_onedrive_dest_subdir="${ONEDRIVE_DEST_SUBDIR:-}"
  preset_artifact_config_dir="${ARTIFACT_CONFIG_DIR:-}"

  # Caller values for every OTHER key reimage.env sets.
  #
  # The named presets above cover the keys this file resolves and default. Every
  # other key -- GIT_*, and anything an operator adds -- was simply overwritten
  # by sourcing, because reimage.env assigns with a plain `export NAME=value`.
  # So the documented rule "values already present in the caller environment win"
  # held only for the listed names, and the keys people override for one
  # invocation are mostly not on that list.
  #
  # Set-ness, not non-emptiness: an exported empty value IS present in the
  # caller environment, and `GIT_PERSONAL_GITHUB_OWNER= ./bin/restore-repos.sh`
  # means "no personal owner for this run", which the `:-` idiom above cannot
  # express.
  #
  # Bash 3.2: no associative arrays, so the saved values are a newline-delimited
  # NAME=VALUE list. A caller value containing a newline is not preserved --
  # reimage.env holds resolved single-line paths and identifiers by convention,
  # and silently truncating one would be worse than leaving it to reimage.env.
  _ac_preserved=""
  if [ -f "${REIMAGE_ENV:-$repo_root/reimage.env}" ]; then
    while IFS= read -r _ac_name; do
      [ -n "$_ac_name" ] || continue
      case " $_ac_named_presets " in
        *" $_ac_name "*) continue ;;
      esac
      eval "_ac_isset=\${$_ac_name+set}"
      [ "$_ac_isset" = set ] || continue
      eval "_ac_value=\$$_ac_name"
      # A literal newline in the pattern. `$(printf '\n')` would strip it and
      # leave an empty pattern, which matches every value -- so the guard would
      # skip every key instead of only multi-line ones.
      case "$_ac_value" in
        *'
'*) continue ;;
      esac
      _ac_preserved="${_ac_preserved}${_ac_name}=${_ac_value}
"
    done <<EOF
$(sed -n 's/^[[:space:]]*\(export[[:space:]][[:space:]]*\)\{0,1\}\([A-Za-z_][A-Za-z0-9_]*\)=.*/\2/p' \
    "${REIMAGE_ENV:-$repo_root/reimage.env}" 2>/dev/null | sort -u)
EOF
  fi

  resolved_reimage_env="${preset_reimage_env:-$repo_root/reimage.env}"
  REIMAGE_ENV="$resolved_reimage_env"

  if [[ -e "$resolved_reimage_env" && ! -f "$resolved_reimage_env" ]]; then
    echo "ERROR: REIMAGE_ENV is not a regular file: $resolved_reimage_env" >&2
    return 2
  fi

  if [[ -f "$resolved_reimage_env" ]]; then
    # shellcheck disable=SC1090
    if ! source "$resolved_reimage_env"; then
      echo "ERROR: failed to source REIMAGE_ENV: $resolved_reimage_env" >&2
      return 2
    fi
  fi

  # Re-apply the caller values captured above. Immediately after sourcing, so a
  # key restored here is what the resolution below sees.
  if [ -n "$_ac_preserved" ]; then
    while IFS= read -r _ac_line; do
      [ -n "$_ac_line" ] || continue
      _ac_name="${_ac_line%%=*}"
      _ac_value="${_ac_line#*=}"
      eval "$_ac_name=\$_ac_value"
      export "${_ac_name?}"
    done <<EOF
$_ac_preserved
EOF
  fi

  # Keep the effective source path stable even if reimage.env contains a stale
  # REIMAGE_ENV assignment. Apply the normal caller > reimage.env > default
  # precedence to the required-artifact-root control.
  REIMAGE_ENV="$resolved_reimage_env"
  ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT="${preset_require_reimage_artifact_root:-${ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT:-false}}"

  REIMAGE_WORKSPACE_ROOT="${preset_reimage_workspace_root:-${REIMAGE_WORKSPACE_ROOT:-}}"
  EXTERNAL_DATA_VOLUME="${preset_external_data_volume:-${EXTERNAL_DATA_VOLUME:-/Volumes/Data}}"
  EXTERNAL_APPLE_BACKUPS_VOLUME="${preset_external_apple_backups_volume:-${EXTERNAL_APPLE_BACKUPS_VOLUME:-/Volumes/AppleBackups}}"
  REIMAGE_ARTIFACT_ROOT="${preset_reimage_artifact_root:-${REIMAGE_ARTIFACT_ROOT:-}}"

  # OFFICE_WATCH is optional. A blank value in reimage.env remains blank rather
  # than silently selecting a machine-specific Desktop path.
  OFFICE_WATCH="${preset_office_watch:-${OFFICE_WATCH:-}}"

  if [[ -z "$REIMAGE_ARTIFACT_ROOT" && "$ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT" == "true" ]]; then
    echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set. Create/source reimage.env or provide an explicit override." >&2
    return 2
  fi

  # Retained for compatibility with older callers, but derive it from the
  # configured external volume instead of hardcoding a separate volume name.
  DEFAULT_DRIVE_NAME="$(basename "${EXTERNAL_DATA_VOLUME%/}")"

  ONEDRIVE_PARENT_DIR="${preset_onedrive_parent_dir:-${ONEDRIVE_PARENT_DIR:-$HOME/Library/CloudStorage}}"
  ONEDRIVE_FOLDER_NAME="${preset_onedrive_folder_name:-${ONEDRIVE_FOLDER_NAME:-}}"

  if [[ -n "$preset_onedrive_preferred_root" ]]; then
    ONEDRIVE_PREFERRED_ROOT="$preset_onedrive_preferred_root"
  elif [[ -n "${ONEDRIVE_PREFERRED_ROOT:-}" ]]; then
    ONEDRIVE_PREFERRED_ROOT="$ONEDRIVE_PREFERRED_ROOT"
  elif [[ -n "$ONEDRIVE_FOLDER_NAME" ]]; then
    ONEDRIVE_PREFERRED_ROOT="$ONEDRIVE_PARENT_DIR/$ONEDRIVE_FOLDER_NAME"
  else
    ONEDRIVE_PREFERRED_ROOT=""
  fi

  if [[ -n "$preset_onedrive_root" ]]; then
    ONEDRIVE_ROOT="$preset_onedrive_root"
  elif [[ -n "${ONEDRIVE_ROOT:-}" ]]; then
    ONEDRIVE_ROOT="$ONEDRIVE_ROOT"
  elif [[ -n "$ONEDRIVE_FOLDER_NAME" ]]; then
    ONEDRIVE_ROOT="$ONEDRIVE_PARENT_DIR/$ONEDRIVE_FOLDER_NAME"
  else
    ONEDRIVE_ROOT=""
  fi

  if [[ -n "$preset_onedrive_dest_subdir" ]]; then
    ONEDRIVE_DEST_SUBDIR="$preset_onedrive_dest_subdir"
  elif [[ -n "${ONEDRIVE_DEST_SUBDIR:-}" ]]; then
    ONEDRIVE_DEST_SUBDIR="$ONEDRIVE_DEST_SUBDIR"
  elif [[ -n "$REIMAGE_ARTIFACT_ROOT" ]]; then
    ONEDRIVE_DEST_SUBDIR="$(basename "${REIMAGE_ARTIFACT_ROOT%/}")"
  else
    ONEDRIVE_DEST_SUBDIR=""
  fi

  MANUAL_POSTMAN_STAGE="${REIMAGE_ARTIFACT_ROOT:+$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/}"
  MANUAL_RAYCAST_STAGE="${REIMAGE_ARTIFACT_ROOT:+$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/}"

  ARTIFACT_CONFIG_TEMPLATE_DIR="$this_dir/templates/artifact-config"
  ARTIFACT_CONFIG_WORKSPACE_DIR="${REIMAGE_WORKSPACE_ROOT:+$REIMAGE_WORKSPACE_ROOT/artifact-config}"

  if [[ -n "$preset_artifact_config_dir" ]]; then
    config_dir="$preset_artifact_config_dir"
  elif [[ -n "${ARTIFACT_CONFIG_DIR:-}" ]]; then
    config_dir="$ARTIFACT_CONFIG_DIR"
  elif [[ -n "$ARTIFACT_CONFIG_WORKSPACE_DIR" && -d "$ARTIFACT_CONFIG_WORKSPACE_DIR" ]]; then
    config_dir="$ARTIFACT_CONFIG_WORKSPACE_DIR"
  else
    # REIMAGE_WORKSPACE_ROOT is set but carries no artifact-config directory. The
    # committed templates still load, so every caller runs with generic targets
    # instead of this Mac's. Say so rather than falling through silently.
    if [[ -n "$ARTIFACT_CONFIG_WORKSPACE_DIR" ]]; then
      echo "WARNING: REIMAGE_WORKSPACE_ROOT is set but $ARTIFACT_CONFIG_WORKSPACE_DIR does not exist —" >&2
      echo "         falling back to committed templates. Run: python3 bin/prepare-artifact-root.py init-artifact-config" >&2
    fi
    config_dir="$ARTIFACT_CONFIG_TEMPLATE_DIR"
  fi

  ARTIFACT_CONFIG_DIR="$config_dir"
  ARTIFACT_CONFIG_SOURCE_DIR="$config_dir"

  STAGED_CERTS_TEMPLATE_DIR="$this_dir/templates/staged-certs"
  STAGED_CERTS_WORKSPACE_DIR="${REIMAGE_WORKSPACE_ROOT:+$REIMAGE_WORKSPACE_ROOT/staged-certs}"
  if [[ -n "$STAGED_CERTS_WORKSPACE_DIR" && -d "$STAGED_CERTS_WORKSPACE_DIR" ]]; then
    STAGED_CERTS_SOURCE_DIR="$STAGED_CERTS_WORKSPACE_DIR"
  else
    STAGED_CERTS_SOURCE_DIR="$STAGED_CERTS_TEMPLATE_DIR"
  fi

  # IntelliJ review selections. Unlike staged-certs there is no committed
  # template to fall back to: both files are GENERATED from the seed lists in
  # .internal/apps/backup-intellij-state.sh, so the script stays the single
  # source of the patterns. An empty INTELLIJ_REVIEW_SOURCE_DIR therefore means
  # "no durable copy — read and seed inside the artifact root", which is the
  # historical behavior. Seed the workspace copy with:
  #   ./bin/backup-apps.sh --init-intellij-review
  INTELLIJ_REVIEW_WORKSPACE_DIR="${REIMAGE_WORKSPACE_ROOT:+$REIMAGE_WORKSPACE_ROOT/intellij-review}"
  if [[ -n "$INTELLIJ_REVIEW_WORKSPACE_DIR" && -d "$INTELLIJ_REVIEW_WORKSPACE_DIR" ]]; then
    INTELLIJ_REVIEW_SOURCE_DIR="$INTELLIJ_REVIEW_WORKSPACE_DIR"
  else
    INTELLIJ_REVIEW_SOURCE_DIR=""
  fi

  # Repo-plan fragments. Same shape as staged-certs, and resolved here for the
  # same reason: more than one caller needs to agree on which copy a run reads.
  # Resolution only -- this file does not source them. .internal/git/repo-plan.sh
  # defines the functions they call and loads them.
  REPO_PLAN_TEMPLATE_DIR="$this_dir/templates/repo-plan"
  REPO_PLAN_WORKSPACE_DIR="${REIMAGE_WORKSPACE_ROOT:+$REIMAGE_WORKSPACE_ROOT/repo-plan}"
  if [[ -n "$REPO_PLAN_WORKSPACE_DIR" && -d "$REPO_PLAN_WORKSPACE_DIR" ]]; then
    REPO_PLAN_SOURCE_DIR="$REPO_PLAN_WORKSPACE_DIR"
  else
    REPO_PLAN_SOURCE_DIR="$REPO_PLAN_TEMPLATE_DIR"
  fi

  if [[ ! -d "$ARTIFACT_CONFIG_SOURCE_DIR" ]]; then
    echo "ERROR: artifact-config directory not found: $ARTIFACT_CONFIG_SOURCE_DIR" >&2
    return 2
  fi

  required_fragments=(
    external-targets.conf.sh
    external-dotfiles.conf.sh
    secrets-targets.conf.sh
    secret-flags.conf.sh
    external-excludes.conf.sh
    onedrive-targets.conf.sh
    onedrive-extra-excludes.conf.sh
    skip-entries.conf.sh
    expected-artifact-folders.conf.sh
  )

  # Preflight the complete fragment set before sourcing any fragment so a
  # missing file cannot leave the caller with only a partially loaded array set.
  for fragment in "${required_fragments[@]}"; do
    config_path="$ARTIFACT_CONFIG_SOURCE_DIR/$fragment"
    if [[ ! -f "$config_path" ]]; then
      echo "ERROR: required artifact-config fragment not found: $config_path" >&2
      return 2
    fi
  done

  for fragment in "${required_fragments[@]}"; do
    config_path="$ARTIFACT_CONFIG_SOURCE_DIR/$fragment"
    # shellcheck disable=SC1090
    if ! source "$config_path"; then
      echo "ERROR: failed to source artifact-config fragment: $config_path" >&2
      return 2
    fi
  done

  # ── Secret shapes ──────────────────────────────────────────────────────────
  # The single definition of "this filename looks like a credential", shared by
  # bin/report-loose-secrets.sh and bin/stage-loose-secrets.sh. Before this
  # existed the answer was spelled out separately in onedrive-extra-excludes
  # (22 shapes), external-excludes (none at all), the IntelliJ helper, and the
  # repo backup — and they disagreed, which is how credential-shaped files
  # reached home-files-backup/ in the clear.
  #
  # The floor lives here rather than in a fragment so it cannot go missing from
  # a workspace copy. secret-shapes.conf.sh is optional and can only ADD.
  #
  # Public certificate formats (.cer, .crt, .der) are deliberately NOT here.
  # They carry no private key, and including them would report every trusted
  # root on the drive. .p12/.pfx are present because PKCS#12 bundles a key by
  # definition.
  SECRET_SHAPES_FLOOR=(
    '.env'        '.env.*'      '.netrc'      '.npmrc'
    '.pypirc'     '.yarnrc'     '.yarnrc.yml' '.git-credentials'
    'credentials' 'credentials.json'
    'id_rsa'      'id_dsa'      'id_ecdsa'    'id_ed25519'
    '*.pem'       '*.key'       '*.p12'       '*.pfx'
    '*.jks'       '*.keystore'  '*.kubeconfig' '*.p8'
    '*credential*.json'  '*token*.json'
    '*password*.csv'     '*password*.json'
    'http-client.private.env.json'
    'settings.xml'       'gradle.properties'
    # Claude Code's live config and its rolling backups. The backups are named
    # .claude.json.backup.<epoch>, so no generic shape matches them: the 2026-08-16
    # run had five sitting in the plaintext tree while the sweep reported clean.
    '.claude.json'       '.claude.json.*'
  )

  # Optional fragments: sourced only when present, so an existing workspace copy
  # created before one of them shipped keeps loading without error.
  for fragment in secret-shapes.conf.sh loose-secret-exceptions.conf.sh archive-policy.conf.sh; do
    config_path="$ARTIFACT_CONFIG_SOURCE_DIR/$fragment"
    [[ -f "$config_path" ]] || continue
    # shellcheck disable=SC1090
    if ! source "$config_path"; then
      echo "ERROR: failed to source artifact-config fragment: $config_path" >&2
      return 2
    fi
  done

  # Effective set = floor plus whatever the fragment added. Guarded because the
  # fragment may be absent, or present with an empty array — on Bash 3.2,
  # expanding an empty array under `set -u` is an error.
  SECRET_SHAPES=( "${SECRET_SHAPES_FLOOR[@]}" )
  if declare -p SECRET_SHAPES_EXTRA >/dev/null 2>&1 \
    && (( ${#SECRET_SHAPES_EXTRA[@]} > 0 )); then
    SECRET_SHAPES=( "${SECRET_SHAPES[@]}" "${SECRET_SHAPES_EXTRA[@]}" )
  fi

  return 0
}

# Public helper: is this artifact-root-relative path an accepted exception?
# Prints the recorded reason on stdout and returns 0 when it matches, else
# returns 1. Both bin/report-loose-secrets.sh and bin/stage-loose-secrets.sh
# call this, so an exception can never mean one thing to one of them and
# something else to the other.
#
# Usage: if reason="$(loose_secret_exception_reason "$rel")"; then ... fi
loose_secret_exception_reason() {
  local rel="$1" entry glob reason

  for entry in ${LOOSE_SECRET_EXCEPTIONS[@]+"${LOOSE_SECRET_EXCEPTIONS[@]}"}; do
    [[ -n "$entry" ]] || continue
    glob="$(config_field "$entry" 1)"
    reason="$(config_field "$entry" 2)"
    [[ -n "$glob" ]] || continue
    # shellcheck disable=SC2053
    if [[ "$rel" == $glob ]]; then
      printf '%s' "${reason:-no reason recorded}"
      return 0
    fi
  done
  return 1
}

# Public helper: turn SECRET_SHAPES into a find(1) predicate group in the array
# named by $1, as `-iname A -o -iname B ...`. Matching belongs inside find:
# testing each filename in the shell forks two subshells per file, which over a
# full home-directory backup takes minutes and reads as a hang.
#
# Usage: build_secret_shape_predicate MY_PRED   # then: find . \( "${MY_PRED[@]}" \)
build_secret_shape_predicate() {
  local target="$1" shape first=1
  local build=""

  for shape in ${SECRET_SHAPES[@]+"${SECRET_SHAPES[@]}"}; do
    [[ -n "$shape" ]] || continue
    if (( first )); then
      build="-iname|$shape"
      first=0
    else
      build="$build|-o|-iname|$shape"
    fi
  done

  # Bash 3.2 has no namerefs, so publish through eval with IFS-split on a
  # character that cannot appear in a glob shape. Pathname expansion must be
  # off for the duration: the shapes ARE globs, and an unquoted expansion run
  # in a directory that happens to contain a match would replace '*.p12' with
  # that filename and silently narrow the predicate to one file.
  local IFS='|' reset_glob=0
  case "$-" in
    *f*) ;;
    *)   reset_glob=1; set -f ;;
  esac

  eval "$target=( \$build )"

  if (( reset_glob )); then
    set +f
  fi
  return 0
}

# Public helper: parse a pipe-delimited config entry by 1-based field index and
# trim only leading/trailing whitespace from the selected field.
# Usage: config_field "entry string" 2
config_field() {
  local entry="$1"
  local index="$2"

  case "$index" in
    ''|0|*[!0-9]*)
      echo "ERROR: config_field index must be a positive integer: ${index:-<empty>}" >&2
      return 2
      ;;
  esac

  printf '%s\n' "$entry" \
    | awk -F'|' -v field_index="$index" '
        {
          value = $field_index
          sub(/^[[:space:]]+/, "", value)
          sub(/[[:space:]]+$/, "", value)
          print value
          exit
        }
      '
}

_artifact_config_finish() {
  local status="$1"
  unset -f _artifact_config_main _artifact_config_finish
  return "$status"
}

if _artifact_config_main; then
  _artifact_config_finish 0
else
  _artifact_config_finish $?
fi
