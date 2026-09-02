#!/usr/bin/env bash
# =============================================================================
# repo-hydrate.sh
#
# Does the work the clone plan describes: clones a repository to where the plan
# says, then merges each declared rehydration source into it.
#
# CLASSIFICATION: `.internal/` helper. Sourced by bin/restore-repos.sh, which
# resolves the plan and the audit and calls in here per repository. Every
# function takes explicit arguments and touches no ambient state beyond the
# arrays .internal/git/repo-plan.sh publishes.
#
# --- BEGIN USAGE ---
#   source .internal/git/repo-plan.sh
#   source .internal/git/repo-hydrate.sh
#   repo_plan_load "$REPO_PLAN_SOURCE_DIR" || exit 2
#
#   repo_hydrate_clone <repo> <url> <dest> <branch> <head-sha> <remotes> <dry-run>
#   repo_hydrate_source <repo> <source-index> <dest> <audit-path> <dry-run>
#
# Both set two variables and return 0. The caller records them; nothing here
# aborts a run, because one unreachable repository must not decide the fate of
# the other twenty-six.
#
#   HYDRATE_OUTCOME  one word, from the sets below
#   HYDRATE_DETAIL   one line of prose for the record
#
# Clone outcomes:
#   cloned        it was absent and now is not
#   present       already there, and its origin matches the plan
#   conflict      something else is at that path -- never touched
#   failed        git clone ran and did not succeed
#   would-clone   --dry-run
#   no-url        the plan has no URL and the audit recorded no remote
#
# Source outcomes:
#   applied       bundle found and merged
#   skipped       no bundle for this key, which is normal
#   blocked       the source needs the image and it is not attached
#   pending       the repository is not cloned, so there is nowhere to merge
#   reported      MODE=report -- what exists was listed, nothing was written
#   would-apply   --dry-run
#   failed        rsync ran and did not succeed
# --- END USAGE ---
# =============================================================================

# No `set` here: sourced by an aggregate validator that deliberately omits -e.

HYDRATE_OUTCOME=""
HYDRATE_DETAIL=""

# `$DMG_MOUNT` is stored literal in the plan so it survives being sourced before
# the image is attached. Expanded by substitution rather than eval: the plan is
# hand-edited, and eval on a hand-edited path is a different kind of file.
_hydrate_expand_root() {
  local root="$1" mount="${DMG_MOUNT:-}"
  printf '%s' "${root//\$DMG_MOUNT/$mount}"
}

# The key a source uses to find this repository's bundle. An explicit map entry
# beats the derivation; nothing else does, so a wrong key is fixed in one place.
_hydrate_key_for() {
  local repo="$1" idx="$2" audit_path="$3"
  local keyed="${REPO_SRC_KEYED[$idx]}" path_root="${REPO_SRC_PATHROOT[$idx]}"
  local type="${REPO_SRC_TYPE[$idx]}" i=0 rel

  while [ "$i" -lt "${#REPO_MAP_NAME[@]}" ]; do
    if [ "${REPO_MAP_NAME[$i]}" = "$repo" ] && [ "${REPO_MAP_TYPE[$i]}" = "$type" ]; then
      if [ -n "${REPO_MAP_SUBPATH[$i]}" ]; then
        printf '%s' "${REPO_MAP_SUBPATH[$i]}"
        return 0
      fi
    fi
    i=$((i + 1))
  done

  case "$keyed" in
    repo-name) printf '%s' "$repo" ;;
    pre-image-path)
      # The audit path with the captured projects root removed. A path that is
      # not under that root has no key here, and saying so beats guessing.
      case "$audit_path" in
        "$path_root"/*) rel="${audit_path#"$path_root"/}"; printf '%s' "$rel" ;;
        *) printf '' ;;
      esac
      ;;
    declared) printf '' ;;
    *) printf '' ;;
  esac
}

repo_hydrate_clone() {
  local repo="$1" url="$2" dest="$3" branch="$4" head_sha="$5" remotes="$6" dry="$7"
  local have parent name

  HYDRATE_OUTCOME=""; HYDRATE_DETAIL=""

  if [ -z "$url" ]; then
    HYDRATE_OUTCOME="no-url"
    HYDRATE_DETAIL="no remote recorded; nothing can clone it"
    return 0
  fi

  if [ -d "$dest/.git" ]; then
    have="$(git -C "$dest" remote get-url origin 2>/dev/null || true)"
    if [ "$have" = "$url" ]; then
      HYDRATE_OUTCOME="present"
      HYDRATE_DETAIL="already cloned, origin matches"
    else
      HYDRATE_OUTCOME="conflict"
      HYDRATE_DETAIL="a repository is there whose origin is ${have:-<none>}, not the planned URL"
    fi
    return 0
  fi

  if [ -e "$dest" ]; then
    HYDRATE_OUTCOME="conflict"
    HYDRATE_DETAIL="$dest exists and is not a git repository"
    return 0
  fi

  if [ "$dry" = "true" ]; then
    HYDRATE_OUTCOME="would-clone"
    HYDRATE_DETAIL="git clone $url $dest"
    return 0
  fi

  parent="$(dirname "$dest")"
  if ! mkdir -p "$parent"; then
    HYDRATE_OUTCOME="failed"
    HYDRATE_DETAIL="could not create $parent"
    return 0
  fi

  if ! git clone "$url" "$dest"; then
    HYDRATE_OUTCOME="failed"
    HYDRATE_DETAIL="git clone exited non-zero"
    return 0
  fi

  HYDRATE_OUTCOME="cloned"
  HYDRATE_DETAIL="cloned from $url"

  # Post-clone work runs ONLY here, on the branch that just cloned. `git checkout`
  # is safe on a fresh clone and destructive on a working tree someone has been
  # in for three days -- it would move them off their branch. The remote-adds are
  # idempotent and could run either way; the checkout decides the rule, so all of
  # it stays inside the clone.
  printf '%s\n' "$remotes" | tr ';' '\n' | while IFS= read -r line; do
    case "$line" in
      *"(fetch)"*) ;;
      *) continue ;;
    esac
    name="$(printf '%s' "$line" | awk '{print $1}')"
    [ -n "$name" ] || continue
    [ "$name" = "origin" ] && continue
    set -- $line
    [ "$#" -ge 2 ] || continue
    git -C "$dest" remote add "$name" "$2" 2>/dev/null \
      || git -C "$dest" remote set-url "$name" "$2" 2>/dev/null || true
  done

  if [ -n "$branch" ] && [ "$branch" != "-" ] && [ "$branch" != "<detached-or-unknown>" ]; then
    if ! git -C "$dest" checkout "$branch" >/dev/null 2>&1; then
      HYDRATE_DETAIL="$HYDRATE_DETAIL; pre-image branch '$branch' not found in the clone"
    fi
  fi

  # The cheapest possible proof the right remote was cloned: a repository whose
  # other remote was ahead clones "successfully" from the stale one and looks
  # fine until much later.
  if [ -n "$head_sha" ]; then
    if ! git -C "$dest" cat-file -e "${head_sha}^{commit}" 2>/dev/null; then
      HYDRATE_DETAIL="$HYDRATE_DETAIL; pre-image HEAD $head_sha absent -- wrong remote, or unpushed work"
    fi
  fi
  return 0
}

repo_hydrate_source() {
  local repo="$1" idx="$2" dest="$3" audit_path="$4" dry="$5"
  local type root key src n

  HYDRATE_OUTCOME=""; HYDRATE_DETAIL=""
  type="${REPO_SRC_TYPE[$idx]}"

  if [ ! -d "$dest/.git" ]; then
    HYDRATE_OUTCOME="pending"
    HYDRATE_DETAIL="$repo is not cloned yet, so there is nowhere to merge into"
    return 0
  fi

  if [ "${REPO_SRC_REQUIRES[$idx]}" = "dmg" ] && [ -z "${DMG_MOUNT:-}" ]; then
    HYDRATE_OUTCOME="blocked"
    HYDRATE_DETAIL="$type needs the secrets image; DMG_MOUNT is not set"
    return 0
  fi

  root="$(_hydrate_expand_root "${REPO_SRC_ROOT[$idx]}")"
  if [ ! -d "$root" ]; then
    HYDRATE_OUTCOME="blocked"
    HYDRATE_DETAIL="$type root is not reachable: $root"
    return 0
  fi

  key="$(_hydrate_key_for "$repo" "$idx" "$audit_path")"
  if [ -z "$key" ]; then
    HYDRATE_OUTCOME="skipped"
    HYDRATE_DETAIL="no key for $repo in $type -- add a repo_map_add entry if it should have one"
    return 0
  fi

  src="$root/$key"
  if [ ! -d "$src" ]; then
    HYDRATE_OUTCOME="skipped"
    HYDRATE_DETAIL="no bundle at $type/$key"
    return 0
  fi

  if [ "${REPO_SRC_MODE[$idx]}" = "report" ]; then
    n="$(find "$src" -type f 2>/dev/null | wc -l | tr -d ' ')"
    HYDRATE_OUTCOME="reported"
    HYDRATE_DETAIL="$n file(s) at $type/$key -- MODE=report, nothing written"
    return 0
  fi

  if [ "$dry" = "true" ]; then
    HYDRATE_OUTCOME="would-apply"
    HYDRATE_DETAIL="rsync -a $src/ $dest/"
    return 0
  fi

  if rsync -a "$src/" "$dest/"; then
    HYDRATE_OUTCOME="applied"
    HYDRATE_DETAIL="merged $type/$key"
  else
    HYDRATE_OUTCOME="failed"
    HYDRATE_DETAIL="rsync exited non-zero for $type/$key"
  fi
  return 0
}
