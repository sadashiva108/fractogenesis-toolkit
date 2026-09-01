#!/usr/bin/env bash
# =============================================================================
# artifact-runs.sh
#
# Shared run-index machinery for every producer that writes timestamped evidence
# under the artifact root: staged run directories, an append-only MANIFEST.md,
# and a computed `official/<context>.txt` pointer per lineage.
#
# WHERE THIS CAME FROM. The pattern is not new. `bin/report-loose-secrets.sh`
# already implemented it carefully -- `.incomplete` staging with an atomic
# rename, a manifest header sentinel, a temp-then-mv pointer write, and one
# finalize function called from every clean exit -- and `report-size-audit.sh`
# mirrors it. This file is that implementation extracted so the boundary
# recorders, the first-boot bundles, and any later producer share one contract
# instead of reimplementing it. The hard parts are unchanged; only the callers
# are new.
#
# DO NOT REPEAT THE DIRECTORY IN THE CONTEXT. Everything under
# `reimaged-system/` is post-image by construction, so a context of
# `post-image-restore-access-entry` said it twice and earned nothing. Contexts
# there are `restore-access-entry`, `restore-access-inventory-diff`,
# `verify-reimaged-system-pre-restart`.
#
# This does NOT generalise to every category. `repo-audit-reports/` and
# `performance-audit/` hold pre-image AND post-image runs side by side, and
# there the prefix is the only thing telling them apart. The test is whether the
# containing directory already answers it.
#
# NAME A LINEAGE FOR ITS RUNBOOK, NEVER FOR ITS PHASE ORDINAL. A context is
# <phase>-<what>-<point>, and `what` is the runbook stem -- `restore-access`,
# not `10B`. Phase numbers renumber: this workflow has done it once already, and
# every artifact naming the old ordinal was wrong from that moment with nothing
# to catch it, because a dated artifact is never regenerated. The runbook stem
# is stable, is what an operator remembers, and is what the runbook file is
# actually called.
#
# The same holds INSIDE the documents a run contains, not just in its directory
# name: the boundary recorders, the state recorder and the comparison all title
# their output by runbook and carry the phase only as context sourced from the
# invocation, where it records what was true at run time rather than asserting
# something that can go stale.
#
# WHY A POINTER PER LINEAGE, NOT ONE `latest-run.txt`. A category holds several
# independent lineages -- pre-image and post-image, pre-restart and post-restart,
# one runbook's entry and its exit -- and a single "latest" pointer can only name
# whichever ran last. That is not a hypothetical: `resolve_latest_repo_audit_run`
# in reimage-checklist.sh reads one pointer and accepts either
# `runs/pre-image-*` or `runs/post-image-*`, so it cannot express which one it
# wants; and verify-reimaged-system.md Step 6 hand-rolls prefix-filtered
# selection because the pointer could not answer its question. One pointer per
# context key answers both.
#
# WHY "OFFICIAL" RATHER THAN "LATEST". A pointer named `latest-` encodes a
# policy, and that policy is wrong for at least one point value. For `before` and
# `pre-restart` the meaningful run is the FIRST one: a `before` captured after the
# runbook has already written is well-formed and wrong, and the diff it produces
# reads "nothing changed". So officialness is computed from the point, not from
# recency, and the file is named for what it holds.
#
# ONE SOURCE OF TRUTH. MANIFEST.md is authoritative and append-only. The pointer
# under `official/` is a derived cache that `artifact_runs_rebuild` can
# regenerate at any time, which is why a stale or missing pointer is a repair
# command rather than a diagnosis. A pin additionally drops PINNED-OFFICIAL.txt
# inside the run it promotes, so a run directory copied elsewhere carries its own
# pin, and a manifest rebuilt from `runs/` recovers pins that no longer have a
# manifest row. The marker records a PIN, not officialness -- officialness is
# always computed -- so the two are not copies of each other.
#
# CLASSIFICATION: foundation file, sourced only. It sits at the `.internal/`
# root beside the two config loaders rather than under a domain directory,
# because its callers span `restore/`, `home/`, and the artifact-root reporters,
# and no one domain owns it. Like those loaders it must not set shell options or
# call `exit`; it returns status instead. See
# `.github/guides/script-types-and-locations.md`.
#
# --- BEGIN USAGE ---
# Source it, then bracket the work:
#
#   source "$REPO_ROOT/.internal/artifact-runs.sh"
#
#   artifact_run_begin "$CATEGORY_ROOT" "restore-access-entry" || return
#   #   -> ARTIFACT_RUN_DIR       staging directory; write evidence here
#   #      ARTIFACT_RUN_ID        post-image-restore-access-entry-YYYYMMDD-HHMMSS
#   #      ARTIFACT_RUN_RELATIVE  runs/<id>
#   #      ARTIFACT_RUN_POINT     entry
#
#   ... write files into "$ARTIFACT_RUN_DIR" ...
#
#   artifact_run_finalize "$CATEGORY_ROOT" "6 pass / 1 warn / 0 fail"
#   #   promotes the staging directory, appends the manifest row, refreshes the
#   #   official pointer according to the point's rule, and reports on stderr
#   #   when it declines to advance it.
#
#   artifact_run_abort            # discard staging; nothing is indexed
#
# Query and override:
#
#   artifact_run_official  "$CATEGORY_ROOT" "<context>"      # prints the run id
#   artifact_run_set_official "$CATEGORY_ROOT" "<context>" "<run-id>" "<reason>"
#   artifact_run_clear_official "$CATEGORY_ROOT" "<context>" "<reason>"
#   artifact_runs_rebuild "$CATEGORY_ROOT"                   # regenerate pointers
#
# Points and their rules:
#
#   before, pre-restart                            first completed run wins
#   after, entry, exit, post-restart, final, diff  latest completed run wins
#   (absent or unrecognised)                 latest wins, recorded as `unknown`
#
# A run whose point is first-wins and which is not the first records normally and
# says on stderr that it did not advance the pointer. Silently not advancing is
# the same class of failure as silently advancing.
#
# Return status (every function):
#   0  success
#   1  refused for a stated reason (printed to stderr)
#   2  caller error -- missing or malformed arguments
# --- END USAGE ---
# =============================================================================

# No `set` here. This file is sourced by callers with their own strict-mode
# choice -- validators deliberately omit `set -e` -- and changing the caller's
# shell options from a sourced file is the loader anti-pattern.

# Points for which the FIRST completed run is official. Space-delimited rather
# than an array so a caller that has already used the name is unaffected, and
# because Bash 3.2 has no associative arrays.
ARTIFACT_RUNS_FIRST_WINS_POINTS="before pre-restart"
# `diff` and `delta` are not synonyms here. A diff compares the machine against
# a capture taken before the erase -- divergence from a recorded baseline. A
# delta joins one phase's own before- and after-state recordings -- what that
# phase changed. Different questions, different lineages, and an official
# pointer that flipped between them answered neither.
ARTIFACT_RUNS_KNOWN_POINTS="before after entry exit pre-restart post-restart final diff delta result"

ARTIFACT_RUNS_MANIFEST_HEADING="# Artifact Runs"

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

_artifact_runs_err()  { printf 'artifact-runs: %s\n' "$1" >&2; }
_artifact_runs_note() { printf 'artifact-runs: %s\n' "$1" >&2; }

# The point is the trailing token of the context key, when it is one we know.
# An unrecognised trailing token is NOT guessed at: it reports `unknown` and gets
# the latest-wins rule, because inferring `before` wrongly would pin the wrong
# run under a rule that refuses to correct itself.
_artifact_runs_point_of() {
  local context="$1" tail known
  tail="${context##*-}"
  for known in $ARTIFACT_RUNS_KNOWN_POINTS; do
    if [ "$tail" = "$known" ]; then
      printf '%s' "$known"
      return 0
    fi
  done
  # Two-word points such as pre-restart lose their first half to ##*-, so retry
  # against the last two tokens.
  case "$context" in
    *-pre-restart)  printf 'pre-restart';  return 0 ;;
    *-post-restart) printf 'post-restart'; return 0 ;;
  esac
  printf 'unknown'
}

_artifact_runs_is_first_wins() {
  local point="$1" p
  for p in $ARTIFACT_RUNS_FIRST_WINS_POINTS; do
    [ "$point" = "$p" ] && return 0
  done
  return 1
}

# A context key must be usable as a directory name and as a manifest cell.
_artifact_runs_valid_context() {
  case "$1" in
    ''|*[!a-zA-Z0-9._-]*) return 1 ;;
    *) return 0 ;;
  esac
}

_artifact_runs_manifest_path() { printf '%s/MANIFEST.md' "$1"; }
_artifact_runs_official_path() { printf '%s/official/%s.txt' "$1" "$2"; }

# Creates the manifest with its sentinel heading if absent. Refuses to append to
# a file that is not one of ours -- the same guard report-loose-secrets.sh uses,
# and the reason a foreign MANIFEST.md cannot be silently corrupted.
_artifact_runs_ensure_manifest() {
  local manifest="$1"
  if [ -e "$manifest" ]; then
    if ! grep -q "^${ARTIFACT_RUNS_MANIFEST_HEADING}\$" "$manifest" 2>/dev/null; then
      _artifact_runs_err "existing manifest is not an artifact-runs index: $manifest"
      _artifact_runs_err "move or remove that file before writing runs here."
      return 1
    fi
    return 0
  fi
  {
    printf '%s\n\n' "$ARTIFACT_RUNS_MANIFEST_HEADING"
    printf 'Append-only index of completed runs in this category. A run that reported\n'
    printf 'findings is still a completed run — the findings are the evidence. Only an\n'
    printf 'aborted run is discarded and never indexed.\n\n'
    printf 'Officialness is **computed**, not stored: default rule by point, then any\n'
    printf '`pin` row on top, last pin winning. Regenerate `official/` with\n'
    printf '`artifact_runs_rebuild`. Nothing in this file is ever edited in place.\n\n'
    printf '| Completed | Kind | Context | Point | Run or target | Result | Note |\n'
    printf '|---|---|---|---|---|---|---|\n'
  } > "$manifest" || {
    _artifact_runs_err "cannot create manifest: $manifest"
    return 1
  }
  return 0
}

_artifact_runs_append_row() {
  # <manifest> <kind> <context> <point> <run> <result> <note>
  printf '| %s | %s | `%s` | %s | `%s` | %s | %s |\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$2" "$3" "$4" "$5" "${6:-—}" "${7:-—}" \
    >> "$1"
}

# Writes the pointer through a temp file so an interrupted write cannot leave a
# truncated pointer naming a run that does not exist.
_artifact_runs_write_pointer() {
  local category_root="$1" context="$2" run_id="$3"
  local pointer tmp
  pointer="$(_artifact_runs_official_path "$category_root" "$context")"
  mkdir -p "$(dirname "$pointer")" || return 1
  tmp="$(dirname "$pointer")/.${context}.$$.tmp"
  printf 'runs/%s\n' "$run_id" > "$tmp" || return 1
  mv "$tmp" "$pointer" || return 1
  return 0
}

# Manifest rows in file order, oldest first. Kind and context are fixed columns,
# so awk on `|` is exact rather than a regex guess at the shape.
_artifact_runs_rows_for() {
  # <manifest> <context> <kind-filter or empty>
  local manifest="$1" context="$2" kind="$3"
  [ -f "$manifest" ] || return 0
  # `[0-9][0-9][0-9][0-9]` rather than `[0-9]{4}`: interval expressions are a
  # late addition to the one-true-awk that macOS ships, and a literal class is
  # free. See also artifact_runs_rebuild, which parses the same rows.
  awk -F'|' -v want_ctx="$context" -v want_kind="$kind" '
    /^\| [0-9][0-9][0-9][0-9]-/ {
      k = $3; c = $4; r = $6
      gsub(/^[ \t]+|[ \t]+$/, "", k)
      gsub(/^[ \t`]+|[ \t`]+$/, "", c)
      gsub(/^[ \t`]+|[ \t`]+$/, "", r)
      if (c != want_ctx) next
      if (want_kind != "" && k != want_kind) next
      print r
    }' "$manifest"
}

# ---------------------------------------------------------------------------
# Public: run lifecycle
# ---------------------------------------------------------------------------

artifact_run_begin() {
  local category_root="$1" context="$2"

  if [ -z "${category_root:-}" ] || [ -z "${context:-}" ]; then
    _artifact_runs_err "artifact_run_begin <category-root> <context>"
    return 2
  fi
  if ! _artifact_runs_valid_context "$context"; then
    _artifact_runs_err "context must match [A-Za-z0-9._-]: '$context'"
    return 2
  fi

  ARTIFACT_RUN_CATEGORY_ROOT="$category_root"
  ARTIFACT_RUN_CONTEXT="$context"
  ARTIFACT_RUN_POINT="$(_artifact_runs_point_of "$context")"
  ARTIFACT_RUN_STAMP="$(date +%Y%m%d-%H%M%S)"
  ARTIFACT_RUN_ID="${context}-${ARTIFACT_RUN_STAMP}"
  ARTIFACT_RUN_RELATIVE="runs/${ARTIFACT_RUN_ID}"
  ARTIFACT_RUN_DIR="${category_root}/runs/.${ARTIFACT_RUN_ID}.incomplete"
  ARTIFACT_RUN_FINAL_DIR="${category_root}/${ARTIFACT_RUN_RELATIVE}"

  if [ "$ARTIFACT_RUN_POINT" = "unknown" ]; then
    _artifact_runs_note "context '$context' has no recognised point suffix; latest-wins applies"
  fi

  if ! mkdir -p "${category_root}/runs"; then
    _artifact_runs_err "cannot create runs directory under: $category_root"
    return 1
  fi
  if [ -e "$ARTIFACT_RUN_FINAL_DIR" ] || [ -e "$ARTIFACT_RUN_DIR" ]; then
    _artifact_runs_err "a run already exists for this timestamp: $ARTIFACT_RUN_ID"
    return 1
  fi
  if ! mkdir "$ARTIFACT_RUN_DIR"; then
    _artifact_runs_err "cannot create staging directory: $ARTIFACT_RUN_DIR"
    return 1
  fi
  return 0
}

artifact_run_abort() {
  if [ -n "${ARTIFACT_RUN_DIR:-}" ] && [ -d "${ARTIFACT_RUN_DIR:-}" ]; then
    rm -rf "$ARTIFACT_RUN_DIR"
  fi
  unset ARTIFACT_RUN_DIR ARTIFACT_RUN_FINAL_DIR
  return 0
}

artifact_run_finalize() {
  local category_root="${1:-${ARTIFACT_RUN_CATEGORY_ROOT:-}}"
  local result="${2:-}"
  local note="${3:-}"
  local manifest existing first_wins_blocked=false pinned=""

  if [ -z "${ARTIFACT_RUN_DIR:-}" ] || [ ! -d "${ARTIFACT_RUN_DIR:-}" ]; then
    _artifact_runs_err "no staged run to finalize (call artifact_run_begin first)"
    return 2
  fi
  # Without this, an empty root makes the manifest path "/MANIFEST.md" and the
  # failure names a location nobody recognises.
  if [ -z "${category_root:-}" ]; then
    _artifact_runs_err "artifact_run_finalize: no category root given and none remembered"
    return 2
  fi

  manifest="$(_artifact_runs_manifest_path "$category_root")"
  _artifact_runs_ensure_manifest "$manifest" || { artifact_run_abort; return 1; }

  if ! mv "$ARTIFACT_RUN_DIR" "$ARTIFACT_RUN_FINAL_DIR"; then
    _artifact_runs_err "could not promote the run; it is NOT indexed: $ARTIFACT_RUN_DIR"
    return 1
  fi
  ARTIFACT_RUN_DIR="$ARTIFACT_RUN_FINAL_DIR"

  # First-wins: does this lineage already have a completed run?
  if _artifact_runs_is_first_wins "$ARTIFACT_RUN_POINT"; then
    existing="$(_artifact_runs_rows_for "$manifest" "$ARTIFACT_RUN_CONTEXT" run | head -1)"
    if [ -n "$existing" ]; then
      first_wins_blocked=true
      note="${note:+$note; }first-wins point: pointer left at \`$existing\`"
    fi
  fi

  _artifact_runs_append_row "$manifest" run "$ARTIFACT_RUN_CONTEXT" \
    "$ARTIFACT_RUN_POINT" "$ARTIFACT_RUN_ID" "$result" "$note"

  # A pin outranks the default rule in either direction.
  pinned="$(_artifact_runs_rows_for "$manifest" "$ARTIFACT_RUN_CONTEXT" pin | tail -1)"
  if [ -n "$pinned" ] && [ "$pinned" != "(cleared)" ]; then
    _artifact_runs_note "lineage '$ARTIFACT_RUN_CONTEXT' is pinned to $pinned; pointer not advanced"
    return 0
  fi

  if [ "$first_wins_blocked" = true ]; then
    _artifact_runs_note "point '$ARTIFACT_RUN_POINT' is first-wins; official stays $existing"
    _artifact_runs_note "this run is recorded but not official. To promote it deliberately:"
    _artifact_runs_note "  artifact_run_set_official <root> $ARTIFACT_RUN_CONTEXT $ARTIFACT_RUN_ID '<reason>'"
    return 0
  fi

  # A pointer that could not be written is a real failure, and it used to be
  # reported on stderr while returning 0 -- so `if ! artifact_run_finalize`
  # could not see it. The run IS indexed either way; what is broken is the
  # derived pointer, which artifact_runs_rebuild repairs.
  if ! _artifact_runs_write_pointer "$category_root" "$ARTIFACT_RUN_CONTEXT" "$ARTIFACT_RUN_ID"; then
    _artifact_runs_err "run is indexed in the manifest, but the official pointer could not be written"
    _artifact_runs_err "repair it with: artifact_runs_rebuild '$category_root'"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Public: query and override
# ---------------------------------------------------------------------------

artifact_run_official() {
  local category_root="$1" context="$2" pointer value
  if [ -z "${category_root:-}" ] || [ -z "${context:-}" ]; then
    _artifact_runs_err "artifact_run_official <category-root> <context>"
    return 2
  fi
  pointer="$(_artifact_runs_official_path "$category_root" "$context")"
  if [ ! -f "$pointer" ]; then
    _artifact_runs_err "no official run for '$context' (try artifact_runs_rebuild)"
    return 1
  fi
  IFS= read -r value < "$pointer"
  case "$value" in
    runs/*) ;;
    *) _artifact_runs_err "pointer is malformed: $pointer"; return 1 ;;
  esac
  if [ ! -d "$category_root/$value" ]; then
    _artifact_runs_err "pointer names a run that is not on disk: $value"
    return 1
  fi
  printf '%s\n' "$value"
  return 0
}

artifact_run_set_official() {
  local category_root="$1" context="$2" run_id="$3" reason="$4"
  local manifest point

  if [ -z "${category_root:-}" ] || [ -z "${context:-}" ] || [ -z "${run_id:-}" ]; then
    _artifact_runs_err "artifact_run_set_official <category-root> <context> <run-id> <reason>"
    return 2
  fi
  # A pin with no reason is indistinguishable from a mistake three weeks later.
  if [ -z "${reason:-}" ]; then
    _artifact_runs_err "a reason is required: an unexplained pin cannot be reviewed"
    return 2
  fi
  # The run must belong to the lineage being pinned. This is the check that must
  # never pass by accident -- it is how a pre-image run would become official for
  # a post-image context.
  case "$run_id" in
    "$context"-*) ;;
    *) _artifact_runs_err "run '$run_id' does not belong to context '$context'"; return 1 ;;
  esac
  case "$run_id" in
    .*|*.incomplete) _artifact_runs_err "refusing to pin an incomplete run: $run_id"; return 1 ;;
  esac
  if [ ! -d "$category_root/runs/$run_id" ]; then
    _artifact_runs_err "run directory is not on disk: runs/$run_id"
    return 1
  fi

  manifest="$(_artifact_runs_manifest_path "$category_root")"
  _artifact_runs_ensure_manifest "$manifest" || return 1
  if ! _artifact_runs_rows_for "$manifest" "$context" run | grep -qxF "$run_id"; then
    _artifact_runs_err "run is not indexed in the manifest: $run_id"
    return 1
  fi

  point="$(_artifact_runs_point_of "$context")"

  # Marker first, then the row, then the pointer. Each step leaves a state the
  # next run reconciles forward: a crash after the marker leaves a pin that
  # rebuild picks up; a crash after the row leaves a stale pointer, which is one
  # command to repair. The reverse order loses the pin with nothing to detect it.
  {
    printf 'PINNED OFFICIAL\n\n'
    printf 'context: %s\n' "$context"
    printf 'run:     %s\n' "$run_id"
    printf 'point:   %s\n' "$point"
    printf 'pinned:  %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
    printf 'reason:  %s\n\n' "$reason"
    printf 'This file records a PIN, not officialness. Officialness is computed:\n'
    printf 'default rule by point, then pins on top. Written by\n'
    printf '.internal/artifact-runs.sh; remove it with artifact_run_clear_official\n'
    printf 'rather than by hand, so the manifest records that it went.\n'
  } > "$category_root/runs/$run_id/PINNED-OFFICIAL.txt" || {
    _artifact_runs_err "could not write the pin marker into runs/$run_id"
    return 1
  }

  _artifact_runs_append_row "$manifest" pin "$context" "$point" "$run_id" "—" "$reason"
  _artifact_runs_write_pointer "$category_root" "$context" "$run_id" || return 1
  _artifact_runs_note "pinned '$context' to $run_id"
  return 0
}

artifact_run_clear_official() {
  local category_root="$1" context="$2" reason="$3"
  local manifest point pinned

  if [ -z "${category_root:-}" ] || [ -z "${context:-}" ]; then
    _artifact_runs_err "artifact_run_clear_official <category-root> <context> <reason>"
    return 2
  fi
  if [ -z "${reason:-}" ]; then
    _artifact_runs_err "a reason is required, the same as for setting a pin"
    return 2
  fi

  manifest="$(_artifact_runs_manifest_path "$category_root")"
  point="$(_artifact_runs_point_of "$context")"
  pinned="$(_artifact_runs_rows_for "$manifest" "$context" pin | tail -1)"

  if [ -z "$pinned" ] || [ "$pinned" = "(cleared)" ]; then
    _artifact_runs_err "'$context' is not pinned; nothing to clear"
    return 1
  fi
  rm -f "$category_root/runs/$pinned/PINNED-OFFICIAL.txt"
  _artifact_runs_append_row "$manifest" pin "$context" "$point" "(cleared)" "—" "$reason"
  _artifact_runs_note "cleared the pin on '$context'; default rule applies again"
  artifact_runs_rebuild "$category_root" >/dev/null
  return 0
}

# ---------------------------------------------------------------------------
# Public: rebuild
#
# Recomputes every pointer from the manifest, then applies pin markers found on
# disk that the manifest does not know about -- which is how a pin survives a
# manifest that was regenerated from `runs/`.
# ---------------------------------------------------------------------------

artifact_runs_rebuild() {
  local category_root="$1" manifest contexts context runs official pinned marker rebuilt=0

  if [ -z "${category_root:-}" ] || [ ! -d "${category_root:-}" ]; then
    _artifact_runs_err "artifact_runs_rebuild <category-root>"
    return 2
  fi
  manifest="$(_artifact_runs_manifest_path "$category_root")"
  if [ ! -f "$manifest" ]; then
    _artifact_runs_err "no manifest in $category_root; nothing to rebuild from"
    return 1
  fi

  contexts="$(awk -F'|' '
    /^\| [0-9][0-9][0-9][0-9]-/ { c = $4; gsub(/^[ \t`]+|[ \t`]+$/, "", c); print c }' "$manifest" \
    | sort -u)"

  for context in $contexts; do
    runs="$(_artifact_runs_rows_for "$manifest" "$context" run)"
    [ -n "$runs" ] || continue

    pinned="$(_artifact_runs_rows_for "$manifest" "$context" pin | tail -1)"
    if [ -n "$pinned" ] && [ "$pinned" != "(cleared)" ]; then
      official="$pinned"
    elif _artifact_runs_is_first_wins "$(_artifact_runs_point_of "$context")"; then
      official="$(printf '%s\n' "$runs" | head -1)"
    else
      official="$(printf '%s\n' "$runs" | tail -1)"
    fi

    if [ ! -d "$category_root/runs/$official" ]; then
      _artifact_runs_err "'$context': computed official run is not on disk: $official"
      continue
    fi
    _artifact_runs_write_pointer "$category_root" "$context" "$official" && rebuilt=$((rebuilt + 1))
  done

  # Pins the manifest does not carry, recovered from the run directories.
  for marker in "$category_root"/runs/*/PINNED-OFFICIAL.txt; do
    [ -f "$marker" ] || continue
    context="$(awk -F': *' '/^context:/ { print $2; exit }' "$marker")"
    official="$(awk -F': *' '/^run:/ { print $2; exit }' "$marker")"
    [ -n "$context" ] && [ -n "$official" ] || continue
    pinned="$(_artifact_runs_rows_for "$manifest" "$context" pin | tail -1)"
    if [ "$pinned" != "$official" ]; then
      _artifact_runs_note "recovered an unindexed pin from runs/$official"
      _artifact_runs_append_row "$manifest" pin "$context" \
        "$(_artifact_runs_point_of "$context")" "$official" "—" \
        "recovered from PINNED-OFFICIAL.txt during rebuild"
      _artifact_runs_write_pointer "$category_root" "$context" "$official"
    fi
  done

  _artifact_runs_note "rebuilt $rebuilt pointer(s) in $category_root"
  return 0
}
