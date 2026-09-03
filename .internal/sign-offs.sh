#!/usr/bin/env bash
# =============================================================================
# sign-offs.sh
#
# Shared machinery for the rows only a person can answer. Every producer that
# emits a checklist has some: `record_manual` rows in the bookend recorders,
# the `## Manual` blocks in the first-boot bundles, the `## Sign-Off Checklist`
# tail of each Phase 12 plan-note. This file owns where those rows live, how an
# answer survives the next run, and how a reader tells a fresh answer from one
# given three weeks ago.
#
# WHY THEY MOVED OUT OF THE RUN. A capture is regenerable: rerun the script and
# the newest run is the truth. An answered row is the opposite -- it is the one
# thing in the artifact that cannot be recomputed, and the run directory is the
# one place guaranteed to be replaced. `verify-reimaged-system.md` states the
# consequence plainly: "a rerun does not update the file you answered -- it
# produces a new record.md with every Manual row back at TODO". Extracting
# the rows into `reimaged-system/sign-offs/` is what makes rerunning a capture
# safe, which is the same reason `bookends/` keeps entry and exit apart.
#
# WHY NOT RUN-INDEX THIS CATEGORY. `artifact-runs.sh` already solves durable
# selection, and pinning a run with `artifact_run_set_official` would survive a
# rebuild. It was still the wrong shape here. Officialness there is COMPUTED --
# latest-wins for most points -- so an answered sign-off stays authoritative
# only while someone remembers to pin it after every tick. A durability
# mechanism that depends on a remembered manual step is the failure it was
# meant to prevent, wearing a different hat. Carry-forward needs no pin: the
# newest file is a superset of the one before it, so latest-wins is safe by
# construction rather than by discipline.
#
# WHY THE FILE IS NAMED FOR THE RUN. `sign-offs/<run-id>.md` costs nothing and
# buys the tie-back: the `Answered against` column holds a run id that names a
# real run directory and a real plan-note, so "was this considered recently"
# is answerable by reading the row rather than by trusting a file date. A row
# answered against a run older than the current one is CARRIED -- durable, but
# not re-verified against what the newest capture actually found.
#
# WHO OWNS WHICH COLUMN. The operator edits `Status` and `Notes`, never
# `Answered against` -- this file writes that one. On carry-forward a row whose
# status left TODO while its stamp was empty is stamped with the run it was
# answered in, which is the previous generation's file, because that is the
# document the operator was working against. To re-affirm a carried row, clear
# its `Answered against` cell; the next emit re-stamps it. Nothing is ever
# stamped with the run being created, since no one has seen that run's survey
# at the moment it is written.
#
# NOTHING IS DROPPED SILENTLY. Rows are matched between generations by their
# item text, so rewording an item orphans its answer. That is recoverable only
# if it is visible, so a prior row with no match in the current declaration is
# reported on stderr and preserved in a `## Rows no longer emitted` section
# rather than disappearing with the answer inside it.
#
# CLASSIFICATION: foundation file, sourced only. It sits at the `.internal/`
# root beside `artifact-runs.sh` and the config loaders, for the same reason:
# its callers span the bookend recorders, the first-boot bundles, and the
# Phase 12 restore scripts, and no one domain owns it. Like those it must not
# set shell options or call `exit`; it returns status instead. See
# `.github/guides/script-types-and-locations.md`.
#
# --- BEGIN USAGE ---
# Source it, then declare the rows:
#
#   source "$REPO_ROOT/.internal/sign-offs.sh"
#
#   signoff_begin "$SIGNOFF_ROOT" "restore-docker" "$RUN_ID" || return
#   #   -> SIGNOFF_FILE     the file that will be written
#   #      SIGNOFF_PRIOR    the generation being carried forward, or empty
#
#   signoff_row "Docker Desktop installed" "install from Self Service"
#   signoff_row "Docker daemon reachable (\`docker info\`)" ""
#
#   signoff_finalize "Phase 12" "restore-notes/restore-docker-plan-$STAMP.md"
#   #   -> SIGNOFF_TOTAL SIGNOFF_OUTSTANDING SIGNOFF_ANSWERED SIGNOFF_CARRIED
#   #      SIGNOFF_DROPPED
#
#   signoff_abort                 # discard; nothing is written
#
# Query:
#
#   signoff_latest "$SIGNOFF_ROOT" "restore-docker"    # prints the run id
#   signoff_outstanding "$SIGNOFF_ROOT" "restore-docker"  # prints TODO items
#
# Arguments:
#   <signoff-root>  normally "$REIMAGE_ARTIFACT_ROOT/reimaged-system/sign-offs"
#   <context>       the runbook stem -- `restore-docker`, never a phase ordinal
#   <run-id>        the run this sign-off accompanies; becomes the file name
#   <item>          row text. Must not contain `|`; it is the match key
#                   between generations, so treat it as a stable identifier.
#
# Statuses the operator may write: TODO, Done, N/A.
# A row is OUTSTANDING while TODO, ANSWERED when its stamp names the previous
# run, CARRIED when its stamp names anything older.
#
# Return status (every function):
#   0  success
#   1  refused for a stated reason (printed to stderr)
#   2  caller error -- missing or malformed arguments
# --- END USAGE ---
# =============================================================================

# No `set` here. This file is sourced by callers with their own strict-mode
# policy, including aggregate validators that deliberately run without `-e`.
# Changing shell options from inside a sourced file changes the caller.

_signoffs_err()  { printf 'sign-offs: %s\n' "$1" >&2; }
_signoffs_note() { printf 'sign-offs: %s\n' "$1" >&2; }

_SIGNOFFS_ROWS_TMP=""
SIGNOFF_FILE=""
SIGNOFF_PRIOR=""
SIGNOFF_ROOT=""
SIGNOFF_CONTEXT=""
SIGNOFF_RUN_ID=""
SIGNOFF_PRIOR_RUN_ID=""
SIGNOFF_TOTAL=0
SIGNOFF_OUTSTANDING=0
SIGNOFF_ANSWERED=0
SIGNOFF_CARRIED=0
SIGNOFF_DROPPED=0

_signoffs_pointer_path() { printf '%s/latest-%s.txt' "$1" "$2"; }

# A context names a runbook stem. Reject a phase ordinal outright: this
# workflow has renumbered its phases once already, and every artifact naming
# the old ordinal was wrong from that moment with nothing to catch it.
_signoffs_valid_context() {
  case "$1" in
    ""|*[!a-zA-Z0-9-]*) return 1 ;;
    [0-9]*)             return 1 ;;
  esac
  return 0
}

# Resolve the newest sign-off for a context. The pointer is a derived cache, so
# a missing or stale one falls back to the glob rather than failing -- the
# files on disk are the source of truth, as in artifact-runs.sh.
signoff_latest() {
  local root="$1" context="$2" pointer value newest f
  if [ -z "${root:-}" ] || [ -z "${context:-}" ]; then
    _signoffs_err "signoff_latest <signoff-root> <context>"
    return 2
  fi
  pointer="$(_signoffs_pointer_path "$root" "$context")"
  if [ -f "$pointer" ]; then
    IFS= read -r value < "$pointer"
    if [ -n "${value:-}" ] && [ -f "$root/$value.md" ]; then
      printf '%s\n' "$value"
      return 0
    fi
  fi
  newest=""
  for f in "$root/$context"-*.md; do
    [ -f "$f" ] || continue
    newest="$f"
  done
  [ -n "$newest" ] || return 1
  f="$(basename "$newest")"
  printf '%s\n' "${f%.md}"
  return 0
}

# A DATA ROW is a four-cell row of either table: a leading `|`, four cells, and
# a trailing `|` give awk six fields. The two-cell metadata table at the top of
# the file yields four, which is how it stays out of every scan below without
# needing to know where it ends.
#
# Item text is compared RAW -- trimmed of whitespace and nothing else. An
# earlier revision stripped backticks here, which silently broke every item
# that contains code spans (`Docker daemon reachable (\`docker info\`)`): the
# stored row kept its backticks, the lookup key lost them, and the row could
# never match itself, so a carried answer reverted to TODO with nothing said.
_signoffs_data_rows() {
  awk -F'|' '
    /^\|/ && NF >= 6 {
      it = $2
      gsub(/^[ \t]+/, "", it); gsub(/[ \t]+$/, "", it)
      if (it == "" || it == "Item" || it ~ /^-+$/) next
      print
    }
  ' "$1"
}

# Cell `col` of the row whose item is `want`. Column 5 is Notes, which is the
# last cell and may itself contain `|`, so it is rejoined from field 5 through
# NF-1 rather than read as a single field. Backticks are stripped from Status
# only -- they are house style there, and content anywhere else.
_signoffs_field() {
  awk -F'|' -v want="$2" -v col="$3" '
    /^\|/ && NF >= 6 {
      it = $2
      gsub(/^[ \t]+/, "", it); gsub(/[ \t]+$/, "", it)
      if (it != want) next
      if (col >= 5) {
        v = $5
        for (i = 6; i < NF; i++) v = v "|" $(i)
      } else {
        v = $(col)
      }
      gsub(/^[ \t]+/, "", v); gsub(/[ \t]+$/, "", v)
      if (col == 3) gsub(/`/, "", v)
      print v
      exit
    }
  ' "$1"
}

_signoffs_item_of() {
  printf '%s\n' "$1" | awk -F'|' '{ v=$2; gsub(/^[ \t]+/,"",v); gsub(/[ \t]+$/,"",v); print v }'
}

signoff_begin() {
  local root="$1" context="$2" run_id="$3"

  if [ -z "${root:-}" ] || [ -z "${context:-}" ] || [ -z "${run_id:-}" ]; then
    _signoffs_err "signoff_begin <signoff-root> <context> <run-id>"
    return 2
  fi
  if ! _signoffs_valid_context "$context"; then
    _signoffs_err "context must be a runbook stem, not a phase ordinal: $context"
    return 2
  fi
  case "$run_id" in
    "$context"-*) ;;
    *) _signoffs_err "run id '$run_id' does not belong to context '$context'"; return 1 ;;
  esac

  if ! mkdir -p "$root" 2>/dev/null; then
    _signoffs_err "cannot create sign-off root: $root"
    return 1
  fi

  SIGNOFF_ROOT="$root"
  SIGNOFF_CONTEXT="$context"
  SIGNOFF_RUN_ID="$run_id"
  SIGNOFF_FILE="$root/$run_id.md"
  SIGNOFF_TOTAL=0; SIGNOFF_OUTSTANDING=0; SIGNOFF_ANSWERED=0
  SIGNOFF_CARRIED=0; SIGNOFF_DROPPED=0

  SIGNOFF_PRIOR_RUN_ID="$(signoff_latest "$root" "$context" 2>/dev/null || true)"
  if [ -n "${SIGNOFF_PRIOR_RUN_ID:-}" ] && [ "$SIGNOFF_PRIOR_RUN_ID" != "$run_id" ]; then
    SIGNOFF_PRIOR="$root/$SIGNOFF_PRIOR_RUN_ID.md"
  else
    SIGNOFF_PRIOR=""
    SIGNOFF_PRIOR_RUN_ID=""
  fi

  _SIGNOFFS_ROWS_TMP="$(mktemp "${TMPDIR:-/tmp}/signoff-rows.XXXXXX")" || {
    _signoffs_err "cannot create a temporary file for the declared rows"
    return 1
  }
  return 0
}

# Declare a row. The note is the DEFAULT note used on a first appearance; a note
# the operator has already written in a previous generation wins over it, since
# theirs records what happened and this one only describes the check.
signoff_row() {
  local item="$1" note="${2:-}"
  if [ -z "${_SIGNOFFS_ROWS_TMP:-}" ]; then
    _signoffs_err "signoff_row called before signoff_begin"
    return 2
  fi
  if [ -z "${item:-}" ]; then
    _signoffs_err "signoff_row <item> [note] -- item is required"
    return 2
  fi
  # `|` would split the row; a tab would split the declaration file that
  # dropped-row detection reads back with `cut -f1`.
  case "$item" in
    *"|"*)   _signoffs_err "item may not contain '|': $item"; return 2 ;;
    *"	"*) _signoffs_err "item may not contain a tab: $item"; return 2 ;;
  esac
  printf '%s\t%s\n' "$item" "$note" >> "$_SIGNOFFS_ROWS_TMP"
  return 0
}

signoff_abort() {
  [ -n "${_SIGNOFFS_ROWS_TMP:-}" ] && rm -f "$_SIGNOFFS_ROWS_TMP"
  _SIGNOFFS_ROWS_TMP=""
  SIGNOFF_FILE=""; SIGNOFF_PRIOR=""
  return 0
}

signoff_finalize() {
  local phase="${1:-}" plan="${2:-}"
  local item note status answered notes line tmp pointer prior_item
  local dropped_rows="" body=""

  if [ -z "${_SIGNOFFS_ROWS_TMP:-}" ] || [ ! -f "$_SIGNOFFS_ROWS_TMP" ]; then
    _signoffs_err "signoff_finalize called before signoff_begin"
    return 2
  fi

  while IFS=$'\t' read -r item note; do
    [ -n "${item:-}" ] || continue
    status=""; answered=""; notes=""
    if [ -n "$SIGNOFF_PRIOR" ] && [ -f "$SIGNOFF_PRIOR" ]; then
      status="$(_signoffs_field   "$SIGNOFF_PRIOR" "$item" 3)"
      answered="$(_signoffs_field "$SIGNOFF_PRIOR" "$item" 4)"
      notes="$(_signoffs_field    "$SIGNOFF_PRIOR" "$item" 5)"
    fi
    [ -n "${status:-}" ] || status="TODO"
    [ -n "${notes:-}"  ] || notes="$note"

    if [ "$status" = "TODO" ]; then
      # An answer is not carried, so neither is a stamp that would imply one.
      answered=""
      SIGNOFF_OUTSTANDING=$(( SIGNOFF_OUTSTANDING + 1 ))
    elif [ -z "${answered:-}" ]; then
      # Answered (or re-affirmed by clearing the cell) in the generation being
      # carried forward. That run is what the operator had in front of them.
      answered="$SIGNOFF_PRIOR_RUN_ID"
      SIGNOFF_ANSWERED=$(( SIGNOFF_ANSWERED + 1 ))
    else
      SIGNOFF_CARRIED=$(( SIGNOFF_CARRIED + 1 ))
    fi

    SIGNOFF_TOTAL=$(( SIGNOFF_TOTAL + 1 ))
    body="${body}| ${item} | \`${status}\` | ${answered:-—} | ${notes} |"$'\n'
  done < "$_SIGNOFFS_ROWS_TMP"

  # Rows the producer no longer emits. Their answers are preserved verbatim:
  # an orphaned answer that vanishes is indistinguishable from one never given.
  # Scanning DATA ROWS means the previous generation's own dropped section is
  # picked up too, so an answer survives every later run rather than only the
  # one that dropped it -- and if the item is ever declared again, the lookup
  # above finds it there and restores the answer.
  if [ -n "$SIGNOFF_PRIOR" ] && [ -f "$SIGNOFF_PRIOR" ]; then
    while IFS= read -r line; do
      prior_item="$(_signoffs_item_of "$line")"
      [ -n "${prior_item:-}" ] || continue
      if ! cut -f1 "$_SIGNOFFS_ROWS_TMP" | grep -qxF -- "$prior_item"; then
        dropped_rows="${dropped_rows}${line}"$'\n'
        SIGNOFF_DROPPED=$(( SIGNOFF_DROPPED + 1 ))
      fi
    done < <(_signoffs_data_rows "$SIGNOFF_PRIOR")
  fi

  tmp="$SIGNOFF_FILE.incomplete"
  {
    printf '# Sign-Off — %s%s\n\n' "$SIGNOFF_CONTEXT" "${phase:+ ($phase)}"
    printf '| Field | Value |\n| --- | --- |\n'
    printf '| Run | `%s` |\n' "$SIGNOFF_RUN_ID"
    if [ -n "$SIGNOFF_PRIOR_RUN_ID" ]; then
      printf '| Carried from | `%s` |\n' "$SIGNOFF_PRIOR_RUN_ID"
    else
      printf '| Carried from | first run — every row starts outstanding |\n'
    fi
    [ -n "$plan" ] && printf '| Plan | `%s` |\n' "$plan"
    printf '| Rows | %d total — %d outstanding, %d answered, %d carried |\n\n' \
      "$SIGNOFF_TOTAL" "$SIGNOFF_OUTSTANDING" "$SIGNOFF_ANSWERED" "$SIGNOFF_CARRIED"

    printf 'Edit `Status` and `Notes` only. `Answered against` is written by\n'
    printf '`bin/` scripts and names the run an answer was given against.\n\n'
    printf -- '- **outstanding** — still `TODO`.\n'
    if [ -n "$SIGNOFF_PRIOR_RUN_ID" ]; then
      printf -- '- **answered** — given against `%s`.\n' "$SIGNOFF_PRIOR_RUN_ID"
      printf -- '- **carried** — given against an older run and NOT re-verified\n'
      printf '  against this one. Re-read the plan, then either change the status or\n'
      printf '  clear the `Answered against` cell to re-affirm it.\n\n'
    else
      printf -- '- **answered** / **carried** — appear once a later run carries these\n'
      printf '  rows forward. Nothing is carried into a first run.\n\n'
    fi
    printf '| Item | Status | Answered against | Notes |\n| --- | --- | --- | --- |\n'
    printf '%s' "$body"

    if [ -n "$dropped_rows" ]; then
      printf '\n## Rows no longer emitted\n\n'
      printf 'The producer stopped emitting these, most often because an item was\n'
      printf 'reworded. Their answers are kept here rather than discarded.\n\n'
      printf '| Item | Status | Answered against | Notes |\n| --- | --- | --- | --- |\n'
      printf '%s' "$dropped_rows"
    fi
  } > "$tmp" || {
    _signoffs_err "could not write the sign-off: $SIGNOFF_FILE"
    rm -f "$tmp"
    signoff_abort
    return 1
  }

  mv "$tmp" "$SIGNOFF_FILE" || {
    _signoffs_err "could not promote the sign-off: $SIGNOFF_FILE"
    rm -f "$tmp"
    signoff_abort
    return 1
  }

  # Pointer last, and via a temp, so a crash leaves a stale pointer that the
  # glob fallback in signoff_latest still reads correctly.
  pointer="$(_signoffs_pointer_path "$SIGNOFF_ROOT" "$SIGNOFF_CONTEXT")"
  printf '%s\n' "$SIGNOFF_RUN_ID" > "$pointer.tmp" && mv "$pointer.tmp" "$pointer"

  rm -f "$_SIGNOFFS_ROWS_TMP"
  _SIGNOFFS_ROWS_TMP=""

  _signoffs_note "sign-off: $SIGNOFF_FILE"
  _signoffs_note "  $SIGNOFF_TOTAL rows — $SIGNOFF_OUTSTANDING outstanding, $SIGNOFF_ANSWERED answered, $SIGNOFF_CARRIED carried"
  if [ "$SIGNOFF_CARRIED" -gt 0 ]; then
    _signoffs_note "  carried rows were answered against an earlier run — re-read them before sign-off"
  fi
  if [ "$SIGNOFF_DROPPED" -gt 0 ]; then
    _signoffs_note "  $SIGNOFF_DROPPED prior row(s) are no longer emitted; their answers are kept under 'Rows no longer emitted'"
  fi
  return 0
}

# Outstanding items for a context, one per line. This is what Phase 14 reads.
signoff_outstanding() {
  local root="$1" context="$2" latest
  if [ -z "${root:-}" ] || [ -z "${context:-}" ]; then
    _signoffs_err "signoff_outstanding <signoff-root> <context>"
    return 2
  fi
  latest="$(signoff_latest "$root" "$context" 2>/dev/null || true)"
  [ -n "${latest:-}" ] || return 1
  awk -F'|' '
    /^\|/ && NF >= 6 {
      it = $2; st = $3
      gsub(/^[ \t]+/, "", it); gsub(/[ \t]+$/, "", it)
      gsub(/^[ \t]+/, "", st); gsub(/[ \t]+$/, "", st); gsub(/`/, "", st)
      if (it == "" || it == "Item" || it ~ /^-+$/) next
      if (st == "TODO") print it
    }
  ' "$root/$latest.md"
  return 0
}
