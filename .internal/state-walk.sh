#!/usr/bin/env bash
# =============================================================================
# state-walk.sh
#
# The observation half of a state capture: resolve a target spec to a path, walk
# it, and emit one TSV row per observed path. Sourced -- never run.
#
# TWO CALLERS. bin/record-restore-state.sh walks within a restore phase
# (before/after); bin/capture-system-state.sh walks either side of the erase.
# They differ in where the result is written and what it is compared against,
# not in how a path is observed -- and a delta joins two walks row for row, so
# the observation has to be identical or the join reports differences the
# machine never had.
#
# Callers must set, before calling capture_target:
#   ROWS_FILE   destination for the TSV rows
#   NOTES_FILE  destination for target->note pairs
#
# Row columns, tab-separated:
#   target  state  kind  mode  size  mtime  sha256  path
#
# `path` is last on purpose: a path can contain almost anything, so a trailing
# field cannot corrupt the columns before it.
# =============================================================================

UNRESOLVED_VAR=""
RESOLVED_PATH=""
resolve_target() {
  local spec="$1" out
  UNRESOLVED_VAR=""
  RESOLVED_PATH=""
  # The tilde here is being pattern-MATCHED against the literal text of a table
  # entry, not expanded — expansion is exactly what the next line does by hand.
  # shellcheck disable=SC2088
  case "$spec" in
    '~/'*) out="$HOME/${spec#\~/}" ;;
    '~')   out="$HOME" ;;
    *)     out="$spec" ;;
  esac
  case "$out" in
    *'$JAVA_HOME'*)
      if [[ -z "${JAVA_HOME:-}" ]]; then
        UNRESOLVED_VAR="JAVA_HOME"
        return 1
      fi
      out="${out//\$JAVA_HOME/$JAVA_HOME}"
      ;;
  esac
  RESOLVED_PATH="$out"
  return 0
}

# ---------------------------------------------------------------------------
# Observation
# ---------------------------------------------------------------------------
ROWS_FILE="$(mktemp)"
NOTES_FILE="$(mktemp)"
cleanup_state_capture() { rm -f "$ROWS_FILE" "$NOTES_FILE"; }
trap cleanup_state_capture EXIT

n_present=0; n_absent=0; n_unresolved=0; n_unreadable=0; n_rows=0

# Every field except the path is squashed, so a stray tab or newline in a value
# cannot shift a column. The path is last and therefore survives its own oddity.
squash_ws() {
  printf '%s' "$1" | tr '\t\n\r' '   ' | sed 's/  */ /g; s/^ //; s/ $//'
}

emit_row() {
  # <target> <state> <kind> <mode> <size> <mtime> <sha> <path>
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$(squash_ws "$1")" "$2" "$3" "${4:--}" "${5:--}" "${6:--}" "${7:--}" "$8" \
    >> "$ROWS_FILE"
  n_rows=$(( n_rows + 1 ))
  case "$2" in
    present)    n_present=$(( n_present + 1 )) ;;
    absent)     n_absent=$(( n_absent + 1 )) ;;
    unresolved) n_unresolved=$(( n_unresolved + 1 )) ;;
    unreadable) n_unreadable=$(( n_unreadable + 1 )) ;;
  esac
}

# BSD stat. This script is macOS-only by nature -- the paths it watches are
# macOS keychains and a macOS JDK layout -- so the BSD format string is correct
# rather than a portability lapse.
stat_field() {
  # Squashed on the way out. BSD `stat -f` returns one field; anything that does
  # not -- a format this stat does not support, or GNU stat, where -f means
  # --file-system and prints a multi-line block -- would otherwise embed newlines
  # and tabs in a TSV column and silently corrupt every row after it. A row that
  # reads wrong is worse than one that reads empty, because the file still parses.
  /usr/bin/stat -f "$1" "$2" 2>/dev/null | tr '\t\n\r' '   ' | sed 's/  */ /g; s/^ //; s/ $//'
}

observe() {
  # <target-spec> <resolved-path>
  local target="$1" p="$2" kind mode size mtime sha

  if [[ -L "$p" ]]; then
    kind=symlink
    mode="$(stat_field '%Lp' "$p")"
    sha="-> $(readlink "$p" 2>/dev/null)"
    emit_row "$target" present "$kind" "$mode" "-" "$(stat_field '%m' "$p")" "$sha" "$p"
    return
  fi

  if [[ -d "$p" ]]; then
    emit_row "$target" present dir "$(stat_field '%Lp' "$p")" "-" "$(stat_field '%m' "$p")" "-" "$p"
    return
  fi

  if [[ ! -f "$p" ]]; then
    emit_row "$target" present other "$(stat_field '%Lp' "$p")" "-" "$(stat_field '%m' "$p")" "-" "$p"
    return
  fi

  mode="$(stat_field '%Lp' "$p")"
  size="$(stat_field '%z' "$p")"
  mtime="$(stat_field '%m' "$p")"

  # Readability is tested before hashing rather than inferred from a failed
  # hash: `shasum` prints nothing and exits non-zero for several reasons, and
  # "I was not allowed to read this" is a different fact from "this is not a
  # file I could hash".
  if [[ ! -r "$p" ]]; then
    emit_row "$target" unreadable file "$mode" "$size" "$mtime" "-" "$p"
    return
  fi

  sha="$(shasum -a 256 "$p" 2>/dev/null | awk '{print $1}')"
  case "$sha" in
    [0-9a-f][0-9a-f]*) emit_row "$target" present file "$mode" "$size" "$mtime" "$sha" "$p" ;;
    *)                 emit_row "$target" unreadable file "$mode" "$size" "$mtime" "-" "$p" ;;
  esac
}

capture_target() {
  # <mode> <spec>
  local mode="$1" spec="$2" resolved child

  if ! resolve_target "$spec"; then
    emit_row "$spec" unresolved "-" "-" "-" "-" "-" "$spec  (\$$UNRESOLVED_VAR is empty — nothing was checked)"
    return
  fi
  resolved="$RESOLVED_PATH"

  if [[ ! -e "$resolved" && ! -L "$resolved" ]]; then
    emit_row "$spec" absent "-" "-" "-" "-" "-" "$resolved"
    return
  fi

  case "$mode" in
    file)
      observe "$spec" "$resolved"
      ;;
    tree)
      observe "$spec" "$resolved"
      if [[ -d "$resolved" ]]; then
        while IFS= read -r -d '' child; do
          observe "$spec" "$child"
        done < <(find "$resolved" -mindepth 1 \( -type f -o -type l -o -type d \) -print0 2>/dev/null)
      fi
      ;;
    shallow)
      observe "$spec" "$resolved"
      if [[ -d "$resolved" ]]; then
        while IFS= read -r -d '' child; do
          observe "$spec" "$child"
        done < <(find "$resolved" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
      fi
      ;;
    *)
      echo "ERROR: unknown traversal mode '$mode' for target '$spec'" >&2
      exit 2
      ;;
  esac
}
