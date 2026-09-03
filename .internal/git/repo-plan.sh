#!/usr/bin/env bash
# =============================================================================
# repo-plan.sh
#
# Reads the Phase 11B clone plan: which repositories to clone, where they land,
# and where their post-clone content comes from.
#
# CLASSIFICATION: `.internal/` foundation-style library. Sourced, never executed.
# It defines the four functions the plan fragments call, sources those fragments
# from the resolved plan directory, and validates the result.
#
# The plan is DECLARATION, not evidence: it lives in $REIMAGE_WORKSPACE_ROOT so
# it survives the reimage, seeded once from committed templates and never
# overwritten by a run. The audit on the artifact root says what existed; this
# says what is wanted.
#
# --- BEGIN USAGE ---
# Source it, then load:
#
#   source .internal/git/repo-plan.sh
#   repo_plan_load "$REPO_PLAN_SOURCE_DIR" || exit 2
#
# Caller controls:
#   REPO_PLAN_STRICT   true  -> a plan with no selected repositories is an error
#                      false -> an empty plan loads clean (default)
#
# Public outputs -- parallel indexed arrays, one entry per declaration, in the
# order the fragments declared them. Bash 3.2 has no associative arrays, so the
# index is the join:
#
#   REPO_PLAN_NAME[]   REPO_PLAN_REMOTE[]  REPO_PLAN_URL[]   REPO_PLAN_PATH[]
#   REPO_EXCL_NAME[]   REPO_EXCL_REASON[]
#   REPO_SRC_TYPE[]    REPO_SRC_ROOT[]     REPO_SRC_KEYED[]  REPO_SRC_PATHROOT[]
#   REPO_SRC_REQUIRES[] REPO_SRC_MODE[]    REPO_SRC_DESC[]
#   REPO_MAP_NAME[]    REPO_MAP_TYPE[]     REPO_MAP_SUBPATH[] REPO_MAP_PATH[]
#
#   REPO_PLAN_WARNINGS[]  non-fatal findings, reported by the caller
#
# Helpers:
#   repo_plan_reset            clear every array
#   repo_plan_load <dir>       reset, source the fragments, validate
#   repo_plan_index <name>     print the REPO_PLAN_* index for a repository,
#                              or empty when it is not selected
#   repo_source_index <type>   print the REPO_SRC_* index for an artifact type
#
# Return status:
#   0  loaded and valid
#   1  one or more errors; every error is printed, not just the first
#   2  the plan directory or a required fragment is missing
# --- END USAGE ---
# =============================================================================

# No `set` here. This file is sourced by callers with their own strict-mode
# choice -- restore-repos.sh is an aggregate validator and deliberately omits
# `set -e` -- and changing the caller's shell options from a sourced file is the
# loader anti-pattern.

REPO_PLAN_FRAGMENTS="repo-candidates-selected.conf.sh repo-candidates-excluded.conf.sh repo-rehydration-sources.conf.sh repo-rehydration-map.conf.sh"

REPO_PLAN_KEYED_BY_VALUES="repo-name pre-image-path declared"
REPO_PLAN_REQUIRES_VALUES="artifact-root dmg"
REPO_PLAN_MODE_VALUES="merge report"

_repo_plan_err() { printf 'repo-plan: %s\n' "$1" >&2; }

# Errors accumulate rather than aborting on the first. A plan with three typos
# should cost one run to fix, not three.
_repo_plan_error_count=0
_repo_plan_fail() {
  _repo_plan_err "$1"
  _repo_plan_error_count=$((_repo_plan_error_count + 1))
}

_repo_plan_in_list() {
  # <needle> <space-separated haystack>
  local needle="$1" item
  for item in $2; do
    [ "$needle" = "$item" ] && return 0
  done
  return 1
}

_repo_plan_key_of()   { printf '%s' "${1%%=*}"; }
_repo_plan_value_of() { printf '%s' "${1#*=}"; }

repo_plan_reset() {
  REPO_PLAN_NAME=(); REPO_PLAN_REMOTE=(); REPO_PLAN_URL=(); REPO_PLAN_PATH=()
  REPO_EXCL_NAME=(); REPO_EXCL_REASON=()
  REPO_SRC_TYPE=(); REPO_SRC_ROOT=(); REPO_SRC_KEYED=(); REPO_SRC_PATHROOT=()
  REPO_SRC_REQUIRES=(); REPO_SRC_MODE=(); REPO_SRC_DESC=()
  REPO_MAP_NAME=(); REPO_MAP_TYPE=(); REPO_MAP_SUBPATH=(); REPO_MAP_PATH=()
  REPO_PLAN_WARNINGS=()
  _repo_plan_error_count=0
}

# ---------------------------------------------------------------------------
# The four functions the fragments call
#
# Named keys rather than positional fields, so a missing middle value is not a
# counting exercise and an added key does not rewrite existing entries. An
# unknown key names the declaration it appeared in -- the failure mode a
# delimited row cannot give, and the one this phase spent a revision recovering
# from when a shifted column read as data.
# ---------------------------------------------------------------------------

repo_plan_add() {
  local arg key value
  local name="" remote="" url="" path=""

  for arg in "$@"; do
    case "$arg" in
      *=*) ;;
      *) _repo_plan_fail "repo_plan_add: argument is not KEY=value: '$arg'"; return 0 ;;
    esac
    key="$(_repo_plan_key_of "$arg")"
    value="$(_repo_plan_value_of "$arg")"
    case "$key" in
      REPO_NAME)        name="$value" ;;
      REMOTE_NAME)      remote="$value" ;;
      REMOTE_FETCH_URL) url="$value" ;;
      LOCAL_REPO_PATH)  path="$value" ;;
      *)
        _repo_plan_fail "repo_plan_add: unknown key $key (repository: ${name:-<REPO_NAME not yet given>})"
        return 0
        ;;
    esac
  done

  if [ -z "$name" ]; then
    _repo_plan_fail "repo_plan_add: REPO_NAME is required"
    return 0
  fi

  REPO_PLAN_NAME[${#REPO_PLAN_NAME[@]}]="$name"
  REPO_PLAN_REMOTE[${#REPO_PLAN_REMOTE[@]}]="$remote"
  REPO_PLAN_URL[${#REPO_PLAN_URL[@]}]="$url"
  REPO_PLAN_PATH[${#REPO_PLAN_PATH[@]}]="$path"
}

repo_plan_exclude() {
  local arg key value
  local name="" reason=""

  for arg in "$@"; do
    case "$arg" in
      *=*) ;;
      *) _repo_plan_fail "repo_plan_exclude: argument is not KEY=value: '$arg'"; return 0 ;;
    esac
    key="$(_repo_plan_key_of "$arg")"
    value="$(_repo_plan_value_of "$arg")"
    case "$key" in
      REPO_NAME) name="$value" ;;
      REASON)    reason="$value" ;;
      *)
        _repo_plan_fail "repo_plan_exclude: unknown key $key (repository: ${name:-<REPO_NAME not yet given>})"
        return 0
        ;;
    esac
  done

  if [ -z "$name" ]; then
    _repo_plan_fail "repo_plan_exclude: REPO_NAME is required"
    return 0
  fi
  # A reason is required for the same purpose the file exists: an exclusion
  # nobody explained is indistinguishable from an omission three weeks later.
  if [ -z "$reason" ]; then
    _repo_plan_fail "repo_plan_exclude: REASON is required (repository: $name)"
    return 0
  fi

  REPO_EXCL_NAME[${#REPO_EXCL_NAME[@]}]="$name"
  REPO_EXCL_REASON[${#REPO_EXCL_REASON[@]}]="$reason"
}

repo_source_add() {
  local arg key value
  local type="" root="" keyed="" pathroot="" requires="" mode="" desc=""

  for arg in "$@"; do
    case "$arg" in
      *=*) ;;
      *) _repo_plan_fail "repo_source_add: argument is not KEY=value: '$arg'"; return 0 ;;
    esac
    key="$(_repo_plan_key_of "$arg")"
    value="$(_repo_plan_value_of "$arg")"
    case "$key" in
      ARTIFACT_TYPE) type="$value" ;;
      ARTIFACT_ROOT) root="$value" ;;
      KEYED_BY)      keyed="$value" ;;
      PRE_IMAGE_ROOT) pathroot="$value" ;;
      REQUIRES)      requires="$value" ;;
      MODE)          mode="$value" ;;
      DESCRIPTION)   desc="$value" ;;
      *)
        _repo_plan_fail "repo_source_add: unknown key $key (source: ${type:-<ARTIFACT_TYPE not yet given>})"
        return 0
        ;;
    esac
  done

  if [ -z "$type" ]; then
    _repo_plan_fail "repo_source_add: ARTIFACT_TYPE is required"
    return 0
  fi
  [ -n "$root" ]     || _repo_plan_fail "repo_source_add: ARTIFACT_ROOT is required (source: $type)"
  [ -n "$keyed" ]    || _repo_plan_fail "repo_source_add: KEYED_BY is required (source: $type)"
  [ -n "$requires" ] || _repo_plan_fail "repo_source_add: REQUIRES is required (source: $type)"
  [ -n "$mode" ]     || _repo_plan_fail "repo_source_add: MODE is required (source: $type)"

  if [ -n "$keyed" ] && ! _repo_plan_in_list "$keyed" "$REPO_PLAN_KEYED_BY_VALUES"; then
    _repo_plan_fail "repo_source_add: KEYED_BY=$keyed is not one of: $REPO_PLAN_KEYED_BY_VALUES (source: $type)"
  fi
  if [ -n "$requires" ] && ! _repo_plan_in_list "$requires" "$REPO_PLAN_REQUIRES_VALUES"; then
    _repo_plan_fail "repo_source_add: REQUIRES=$requires is not one of: $REPO_PLAN_REQUIRES_VALUES (source: $type)"
  fi
  if [ -n "$mode" ] && ! _repo_plan_in_list "$mode" "$REPO_PLAN_MODE_VALUES"; then
    _repo_plan_fail "repo_source_add: MODE=$mode is not one of: $REPO_PLAN_MODE_VALUES (source: $type)"
  fi
  # A path-keyed source without the root to subtract cannot derive anything.
  if [ "$keyed" = "pre-image-path" ] && [ -z "$pathroot" ]; then
    _repo_plan_fail "repo_source_add: KEYED_BY=pre-image-path needs PRE_IMAGE_ROOT -- the key is the audit path with that prefix removed (source: $type)"
  fi

  REPO_SRC_TYPE[${#REPO_SRC_TYPE[@]}]="$type"
  REPO_SRC_ROOT[${#REPO_SRC_ROOT[@]}]="$root"
  REPO_SRC_KEYED[${#REPO_SRC_KEYED[@]}]="$keyed"
  REPO_SRC_PATHROOT[${#REPO_SRC_PATHROOT[@]}]="$pathroot"
  REPO_SRC_REQUIRES[${#REPO_SRC_REQUIRES[@]}]="$requires"
  REPO_SRC_MODE[${#REPO_SRC_MODE[@]}]="$mode"
  REPO_SRC_DESC[${#REPO_SRC_DESC[@]}]="$desc"
}

repo_map_add() {
  local arg key value
  local name="" type="" subpath="" path=""

  for arg in "$@"; do
    case "$arg" in
      *=*) ;;
      *) _repo_plan_fail "repo_map_add: argument is not KEY=value: '$arg'"; return 0 ;;
    esac
    key="$(_repo_plan_key_of "$arg")"
    value="$(_repo_plan_value_of "$arg")"
    case "$key" in
      REPO_NAME)        name="$value" ;;
      ARTIFACT_TYPE)    type="$value" ;;
      ARTIFACT_SUBPATH) subpath="$value" ;;
      LOCAL_REPO_PATH)  path="$value" ;;
      *)
        _repo_plan_fail "repo_map_add: unknown key $key (repository: ${name:-<REPO_NAME not yet given>})"
        return 0
        ;;
    esac
  done

  [ -n "$name" ] || { _repo_plan_fail "repo_map_add: REPO_NAME is required"; return 0; }
  [ -n "$type" ] || { _repo_plan_fail "repo_map_add: ARTIFACT_TYPE is required (repository: $name)"; return 0; }

  REPO_MAP_NAME[${#REPO_MAP_NAME[@]}]="$name"
  REPO_MAP_TYPE[${#REPO_MAP_TYPE[@]}]="$type"
  REPO_MAP_SUBPATH[${#REPO_MAP_SUBPATH[@]}]="$subpath"
  REPO_MAP_PATH[${#REPO_MAP_PATH[@]}]="$path"
}

# ---------------------------------------------------------------------------
# Lookup
# ---------------------------------------------------------------------------

repo_plan_index() {
  local want="$1" i=0
  while [ "$i" -lt "${#REPO_PLAN_NAME[@]}" ]; do
    if [ "${REPO_PLAN_NAME[$i]}" = "$want" ]; then printf '%s' "$i"; return 0; fi
    i=$((i + 1))
  done
  return 1
}

repo_source_index() {
  local want="$1" i=0
  while [ "$i" -lt "${#REPO_SRC_TYPE[@]}" ]; do
    if [ "${REPO_SRC_TYPE[$i]}" = "$want" ]; then printf '%s' "$i"; return 0; fi
    i=$((i + 1))
  done
  return 1
}

# ---------------------------------------------------------------------------
# Cross-entry validation
#
# Each function above checks one declaration. These are the checks that need the
# whole plan, and two of them are safety rather than tidiness.
# ---------------------------------------------------------------------------

repo_plan_validate() {
  local i j

  # Duplicate REPO_NAME: the later entry would silently win a lookup.
  i=0
  while [ "$i" -lt "${#REPO_PLAN_NAME[@]}" ]; do
    j=$((i + 1))
    while [ "$j" -lt "${#REPO_PLAN_NAME[@]}" ]; do
      if [ "${REPO_PLAN_NAME[$i]}" = "${REPO_PLAN_NAME[$j]}" ]; then
        _repo_plan_fail "selected twice: ${REPO_PLAN_NAME[$i]} -- one entry per repository"
      fi
      j=$((j + 1))
    done
    i=$((i + 1))
  done

  # Duplicate REPO_NAME in the excluded fragment. Harmless to the run -- the
  # first match wins and the reasons usually agree -- but a repository listed
  # twice is a file that has been edited twice without being read, and the
  # second reason is the one nobody will ever see.
  i=0
  while [ "$i" -lt "${#REPO_EXCL_NAME[@]}" ]; do
    j=$((i + 1))
    while [ "$j" -lt "${#REPO_EXCL_NAME[@]}" ]; do
      if [ "${REPO_EXCL_NAME[$i]}" = "${REPO_EXCL_NAME[$j]}" ]; then
        _repo_plan_fail "excluded twice: ${REPO_EXCL_NAME[$i]} -- one entry per repository"
      fi
      j=$((j + 1))
    done
    i=$((i + 1))
  done

  # Selected AND excluded. Whichever the code happened to consult first would
  # decide, which is the definition of an answer nobody chose.
  i=0
  while [ "$i" -lt "${#REPO_PLAN_NAME[@]}" ]; do
    j=0
    while [ "$j" -lt "${#REPO_EXCL_NAME[@]}" ]; do
      if [ "${REPO_PLAN_NAME[$i]}" = "${REPO_EXCL_NAME[$j]}" ]; then
        _repo_plan_fail "both selected and excluded: ${REPO_PLAN_NAME[$i]}"
      fi
      j=$((j + 1))
    done
    i=$((i + 1))
  done

  # Two repositories into one directory. The second clone fails on a non-empty
  # destination, and if the first is a different repository the failure reads as
  # a conflict rather than as a plan error.
  i=0
  while [ "$i" -lt "${#REPO_PLAN_PATH[@]}" ]; do
    if [ -n "${REPO_PLAN_PATH[$i]}" ]; then
      j=$((i + 1))
      while [ "$j" -lt "${#REPO_PLAN_PATH[@]}" ]; do
        if [ -n "${REPO_PLAN_PATH[$j]}" ] && [ "${REPO_PLAN_PATH[$i]}" = "${REPO_PLAN_PATH[$j]}" ]; then
          _repo_plan_fail "same LOCAL_REPO_PATH for ${REPO_PLAN_NAME[$i]} and ${REPO_PLAN_NAME[$j]}: ${REPO_PLAN_PATH[$i]}"
        fi
        j=$((j + 1))
      done
    fi
    i=$((i + 1))
  done

  # Duplicate ARTIFACT_TYPE: sources apply in order, so two of a name means one
  # of them is unreachable and nothing says which.
  i=0
  while [ "$i" -lt "${#REPO_SRC_TYPE[@]}" ]; do
    j=$((i + 1))
    while [ "$j" -lt "${#REPO_SRC_TYPE[@]}" ]; do
      if [ "${REPO_SRC_TYPE[$i]}" = "${REPO_SRC_TYPE[$j]}" ]; then
        _repo_plan_fail "declared twice as a source: ${REPO_SRC_TYPE[$i]}"
      fi
      j=$((j + 1))
    done
    i=$((i + 1))
  done

  # A map entry naming a source that does not exist restores nothing, silently.
  i=0
  while [ "$i" -lt "${#REPO_MAP_TYPE[@]}" ]; do
    if ! repo_source_index "${REPO_MAP_TYPE[$i]}" >/dev/null; then
      _repo_plan_fail "map entry for ${REPO_MAP_NAME[$i]} names an unknown ARTIFACT_TYPE: ${REPO_MAP_TYPE[$i]}"
    fi
    i=$((i + 1))
  done

  # A map entry for a repository nobody selected is dead configuration. It is a
  # warning rather than an error: a repository can be mapped ahead of being
  # selected, and saying so is more useful than refusing to run.
  i=0
  while [ "$i" -lt "${#REPO_MAP_NAME[@]}" ]; do
    if ! repo_plan_index "${REPO_MAP_NAME[$i]}" >/dev/null; then
      REPO_PLAN_WARNINGS[${#REPO_PLAN_WARNINGS[@]}]="map entry for ${REPO_MAP_NAME[$i]} (${REPO_MAP_TYPE[$i]}) but that repository is not selected"
    fi
    i=$((i + 1))
  done

  [ "$_repo_plan_error_count" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Load
# ---------------------------------------------------------------------------

repo_plan_load() {
  local dir="${1:-}" fragment path

  if [ -z "$dir" ]; then
    _repo_plan_err "repo_plan_load <plan-directory>"
    return 2
  fi
  if [ ! -d "$dir" ]; then
    _repo_plan_err "plan directory not found: $dir"
    _repo_plan_err "seed it with: ./bin/restore-repos.sh init-repo-plan-config"
    return 2
  fi

  repo_plan_reset

  for fragment in $REPO_PLAN_FRAGMENTS; do
    path="$dir/$fragment"
    if [ ! -f "$path" ]; then
      _repo_plan_err "missing plan fragment: $path"
      _repo_plan_err "seed the missing files with: ./bin/restore-repos.sh init-repo-plan-config"
      return 2
    fi
    # shellcheck source=/dev/null
    if ! . "$path"; then
      _repo_plan_err "fragment failed to load: $path"
      return 2
    fi
  done

  if ! repo_plan_validate; then
    _repo_plan_err "$_repo_plan_error_count problem(s) in $dir -- fix and rerun"
    return 1
  fi

  if [ "${REPO_PLAN_STRICT:-false}" = "true" ] && [ "${#REPO_PLAN_NAME[@]}" -eq 0 ]; then
    _repo_plan_err "no repositories selected in $dir/repo-candidates-selected.conf.sh"
    return 1
  fi

  return 0
}

# ---------------------------------------------------------------------------
# Seeding
#
# Copies the committed templates into the workspace copy, refusing to overwrite
# an existing file without --force. Same semantics as
# `stage-certs-keychain.sh init-staged-certs-config`: the workspace copy is the
# operator's, and a run never writes over an answer they gave.
# ---------------------------------------------------------------------------

repo_plan_init_workspace() {
  local template_dir="${1:-}" workspace_dir="${2:-}" force="${3:-false}"
  local fragment src dest copied=0 kept=0

  if [ -z "$template_dir" ] || [ -z "$workspace_dir" ]; then
    _repo_plan_err "repo_plan_init_workspace <template-dir> <workspace-dir> [force]"
    return 2
  fi
  if [ ! -d "$template_dir" ]; then
    _repo_plan_err "template directory not found: $template_dir"
    return 2
  fi
  if ! mkdir -p "$workspace_dir"; then
    _repo_plan_err "cannot create: $workspace_dir"
    return 1
  fi

  for fragment in $REPO_PLAN_FRAGMENTS; do
    src="$template_dir/$fragment"
    dest="$workspace_dir/$fragment"
    if [ ! -f "$src" ]; then
      _repo_plan_err "template missing: $src"
      return 1
    fi
    if [ -f "$dest" ] && [ "$force" != "true" ]; then
      printf '  kept    %s\n' "$dest"
      kept=$((kept + 1))
      continue
    fi
    if cp "$src" "$dest"; then
      printf '  written %s\n' "$dest"
      copied=$((copied + 1))
    else
      _repo_plan_err "could not write: $dest"
      return 1
    fi
  done

  printf '\n%s written, %s kept.\n' "$copied" "$kept"
  if [ "$kept" -gt 0 ] && [ "$force" != "true" ]; then
    printf 'Existing files were left alone. Pass --force to overwrite them.\n'
  fi
  return 0
}
