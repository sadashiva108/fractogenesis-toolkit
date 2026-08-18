#!/usr/bin/env bash
#
# scan-archive-contents.sh
#
# Report compressed archives whose *members* look like credentials.
#
# The Phase 3B sweep matches filenames on disk, so a secret sealed inside a
# .zip or .tar.gz passes it silently: the archive's own name says nothing about
# what it holds. This lists archive members without extracting anything and
# matches them against the same SECRET_SHAPES the sweep uses, so a decision can
# be made per archive -- keep it, add it to ARCHIVE_SKIP, or move it into the
# secrets DMG.
#
# Nothing is extracted, moved, or deleted. Read-only by construction.
#
# --- BEGIN USAGE ---
# Usage:
#   .internal/scan-archive-contents.sh [--external-only | --onedrive-only]
#                                      [--root PATH]... [--context LABEL]
#                                      [--dest DIR] [--all]
#
# Options:
#   --external-only Scan only the external drive leg: every source in
#                   EXTERNAL_TARGETS, with the directory-shaped
#                   EXTERNAL_EXCLUDES pruned, so the scan sees what would
#                   actually be copied and nothing else.
#   --onedrive-only Scan only the OneDrive leg: the sources in
#                   ONEDRIVE_TARGETS, pruned by EXTERNAL_EXCLUDES *and*
#                   ONEDRIVE_EXTRA_EXCLUDES. A hit here is an archive that
#                   would be pushed to corporate cloud storage, a different
#                   decision from one that only reaches the artifact drive.
#
#                   With neither flag, BOTH legs run -- the same convention as
#                   bin/backup-home.sh, whose modes these mirror. Each leg gets
#                   its own report and its own MANIFEST row: the prune sets
#                   differ, so a merged result would mean nothing.
#
#                   Archives already named in ARCHIVE_SKIP are still scanned,
#                   and marked as not-copied.
#   --root PATH     Scan this directory, ignoring the target lists entirely.
#                   Repeatable, and it suppresses the both-legs default. Use it
#                   to verify the artifact root after a run
#                   (--root "$REIMAGE_ARTIFACT_ROOT"), or to audit the OneDrive
#                   sync folder for archives already sitting there.
#   --context LABEL Sub-label for this run's directory under the report root.
#                   Default: pre-image. Same convention as the Phase 3B sweep,
#                   so same-day runs stay distinguishable in MANIFEST.md.
#   --dest DIR      Report root. Default:
#                   $REIMAGE_ARTIFACT_ROOT/loose-secrets-reports/content-scans
#   --report FILE   Write to this exact path instead of a run directory. For a
#                   one-off; no MANIFEST row is written.
#   --no-report     Terminal only; write nothing.
#   --all           List every archive scanned, not only the ones with hits.
#   -h, --help      Show this message and exit.
#
# Exit codes:
#   0  scan completed, no archive held a credential-shaped member
#   1  at least one archive held a credential-shaped member (review them)
#   2  usage or configuration error
# --- END USAGE ---

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "${BASH_SOURCE[0]}" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

ROOTS=(); REPORT=""; SHOW_ALL=false; USE_TARGETS=false; USE_ONEDRIVE=false
REPORT_CONTEXT="pre-image"; DEST_ROOT=""; NO_REPORT=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --external-only) USE_TARGETS=true; shift ;;
    --onedrive-only) USE_ONEDRIVE=true; shift ;;
    --root)    [[ -n "${2:-}" ]] || { echo "ERROR: --root requires a value" >&2; exit 2; }
               ROOTS+=( "$2" ); shift 2 ;;
    --context) [[ -n "${2:-}" ]] || { echo "ERROR: --context requires a value" >&2; exit 2; }
               REPORT_CONTEXT="$2"; shift 2 ;;
    --dest)    [[ -n "${2:-}" ]] || { echo "ERROR: --dest requires a value" >&2; exit 2; }
               DEST_ROOT="$2"; shift 2 ;;
    --report)  [[ -n "${2:-}" ]] || { echo "ERROR: --report requires a value" >&2; exit 2; }
               REPORT="$2"; shift 2 ;;
    --no-report) NO_REPORT=true; shift ;;
    --all)     SHOW_ALL=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)         echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -f "$REPO_ROOT/.internal/load-reimage-config.sh" ]]; then
  # shellcheck disable=SC1091
  source "$REPO_ROOT/.internal/load-reimage-config.sh" || exit 2
fi

# A context becomes a directory name, so keep it path-safe. Unlike the size
# audit this imposes no prefix -- these scans are run at several points, not
# only side by side with a phase.
case "$REPORT_CONTEXT" in
  *[/\\]*|*..*|.*|*[[:space:]]*|"")
    echo "ERROR: --context must not be empty or contain slashes, '..', a leading dot, or whitespace: $REPORT_CONTEXT" >&2
    exit 2 ;;
esac

if $USE_TARGETS && $USE_ONEDRIVE; then
  echo "ERROR: --external-only and --onedrive-only are alternatives; omit both to run both legs." >&2
  exit 2
fi

# No leg flag and no --root means BOTH legs, mirroring bin/backup-home.sh. Run
# them as two child invocations sharing one run directory rather than
# restructuring the single-leg scan: each leg has its own roots, its own prune
# set and its own counters, so two clean passes are more trustworthy than one
# pass juggling two sets of state.
if ! $USE_TARGETS && ! $USE_ONEDRIVE && (( ${#ROOTS[@]} == 0 )) && [[ -z "${_SCAN_RUN_DIR:-}" ]]; then
  SHARED_DIR=""
  if ! $NO_REPORT && [[ -z "$REPORT" ]]; then
    if [[ -z "$DEST_ROOT" && -n "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
      DEST_ROOT="$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports/content-scans"
    fi
    if [[ -n "$DEST_ROOT" ]]; then
      SHARED_DIR="$DEST_ROOT/runs/${REPORT_CONTEXT}-$(date '+%Y%m%d-%H%M%S')"
      mkdir -p "$SHARED_DIR" || { echo "ERROR: cannot create $SHARED_DIR" >&2; exit 2; }
    fi
  fi
  child=( --context "$REPORT_CONTEXT" )
  [[ -n "$DEST_ROOT" ]] && child+=( --dest "$DEST_ROOT" )
  $NO_REPORT && child+=( --no-report )
  $SHOW_ALL  && child+=( --all )
  rc_a=0; rc_b=0
  _SCAN_RUN_DIR="$SHARED_DIR" bash "${BASH_SOURCE[0]}" --external-only "${child[@]}" || rc_a=$?
  _SCAN_RUN_DIR="$SHARED_DIR" bash "${BASH_SOURCE[0]}" --onedrive-only "${child[@]}" || rc_b=$?
  (( rc_b > rc_a )) && rc_a="$rc_b"
  exit "$rc_a"
fi

LEG=""
if $USE_TARGETS || $USE_ONEDRIVE; then
  if $USE_ONEDRIVE; then
    LEG="OneDrive leg (ONEDRIVE_TARGETS)"
    _tvar=ONEDRIVE_TARGETS
  else
    LEG="external drive leg (EXTERNAL_TARGETS)"
    _tvar=EXTERNAL_TARGETS
  fi
  if ! declare -p "$_tvar" >/dev/null 2>&1; then
    echo "ERROR: $_tvar is not defined; check the artifact-config fragments." >&2
    exit 2
  fi
  # Bash 3.2 has no namerefs; expand the chosen array through eval into a temp.
  eval '_rows=( ${'"$_tvar"'[@]+"${'"$_tvar"'[@]}"} )'
  if (( ${#_rows[@]} == 0 )); then
    echo "ERROR: $_tvar is empty; nothing to scan." >&2; exit 2
  fi
  while IFS='|' read -r _label _src _rest; do
    _src="$(printf '%s' "$_src" | sed 's/^ *//; s/ *$//')"
    [[ -n "$_src" && -d "$_src" ]] || continue
    ROOTS+=( "$_src" )
  done < <(printf '%s\n' "${_rows[@]}")
fi

if (( ${#ROOTS[@]} == 0 )); then
  if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    ROOTS=( "$REIMAGE_ARTIFACT_ROOT" )
  else
    echo "ERROR: no leg flag or --root given and REIMAGE_ARTIFACT_ROOT is not set." >&2
    exit 2
  fi
fi

if (( ${#SECRET_SHAPES[@]} == 0 )); then
  echo "ERROR: SECRET_SHAPES is empty; shared config did not load." >&2; exit 2
fi

RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'
[[ -t 1 ]] || { RED=''; YEL=''; GRN=''; CYN=''; BLD=''; DIM=''; RST=''; }

# Glob shapes -> one lowercase ERE, anchored to the member's basename. Matching
# happens in awk rather than a shell `case` per member: an archive can hold
# thousands of entries and a fork-per-entry loop reads as a hang.
PAT=""
for shape in "${SECRET_SHAPES[@]}"; do
  [[ -n "$shape" ]] || continue
  r="$(printf '%s' "$shape" \
       | tr '[:upper:]' '[:lower:]' \
       | sed -e 's/[.[\$()+^{}]/\\&/g' -e 's/\*/.*/g' -e 's/?/./g')"
  if [[ -z "$PAT" ]]; then PAT="^${r}$"; else PAT="${PAT}|^${r}$"; fi
done

list_members() {
  local f="$1"
  case "$f" in
    *.zip|*.ZIP|*.jar|*.war)
      command -v unzip >/dev/null 2>&1 || return 3
      unzip -Z1 -- "$f" 2>/dev/null ;;
    *.tar)          tar -tf  "$f" 2>/dev/null ;;
    *.tar.gz|*.tgz) tar -tzf "$f" 2>/dev/null ;;
    *.tar.bz2)      tar -tjf "$f" 2>/dev/null ;;
    *.tar.xz)       tar -tJf "$f" 2>/dev/null ;;
    *.7z)
      command -v 7z >/dev/null 2>&1 || return 3
      7z l -ba -slt -- "$f" 2>/dev/null | sed -n 's/^Path = //p' ;;
    *) return 3 ;;
  esac
}

human() { awk -v b="${1:-0}" 'BEGIN{
  if(b>=1073741824) printf "%.1fG",b/1073741824;
  else if(b>=1048576) printf "%.1fM",b/1048576;
  else if(b>=1024) printf "%.0fK",b/1024; else printf "%dB",b }'; }

FOUND="$(mktemp)"; SCANNED=0; HITS=0; UNREADABLE=0; SKIPPED_HITS=0

scan_archive() {
  local f="$1" members hit_lines n
  members="$(list_members "$f")" || { UNREADABLE=$((UNREADABLE+1))
    printf "  ${DIM}?  no reader for %s${RST}\n" "${f##*/}"; return; }
  SCANNED=$((SCANNED+1))
  # PAT arrives through the environment, not -v. gawk applies escape-sequence
  # processing to a -v assignment, so "\." in the pattern reaches the program as
  # a bare "." -- every escaped dot silently becomes "any character". That turned
  # "^\.env\..*$" into "^.env..*$", which matches "Denver", and "^.*\.key$" into
  # "^.*.key$", which matches "pubKey". ENVIRON[] is not escape-processed.
  hit_lines="$(printf '%s\n' "$members" | SHAPE_PAT="$PAT" awk '
      BEGIN { pat = ENVIRON["SHAPE_PAT"] }
      { n=$0; sub(/.*\//,"",n); if (n=="") next
        if (tolower(n) ~ pat) print $0 }')"
  if [[ -z "$hit_lines" ]]; then
    $SHOW_ALL && printf "  ${GRN}OK${RST}  ${DIM}%s${RST}\n" "$f"
    return
  fi
  HITS=$((HITS+1))
  n="$(printf '%s\n' "$hit_lines" | grep -c .)"
  # An archive already in ARCHIVE_SKIP will not be copied anywhere, so its
  # members are informational rather than a decision to make. Say so here
  # instead of leaving the reader to cross-reference the policy fragment.
  local note="" b="${f##*/}" sk
  if declare -p ARCHIVE_SKIP >/dev/null 2>&1 && (( ${#ARCHIVE_SKIP[@]} > 0 )); then
    for sk in "${ARCHIVE_SKIP[@]}"; do
      [[ -n "$sk" ]] || continue
      case "$b" in $sk) note="  [ARCHIVE_SKIP - not copied]"
                        SKIPPED_HITS=$((SKIPPED_HITS+1)); break ;; esac
    done
  fi
  printf "  ${RED}!!${RST}  ${BLD}%s${RST}  ${DIM}(%s, %s credential-shaped member(s))${RST}${YEL}%s${RST}\n" \
    "$f" "$(human "$(wc -c < "$f" | tr -d ' ')")" "$n" "$note"
  printf '%s\n' "$hit_lines" | head -12 | sed 's/^/       /'
  (( n > 12 )) && printf "       ${DIM}... and %d more${RST}\n" "$(( n - 12 ))"
  {
    printf '\n### `%s`\n\n' "$f"
    printf '%d credential-shaped member(s):\n\n```text\n' "$n"
    printf '%s\n' "$hit_lines"
    printf '```\n'
  } >> "$FOUND"
}

echo ""
printf "${BLD}${CYN}> Archive content scan${RST}\n"
printf "  ${DIM}%d shape(s) from the shared SECRET_SHAPES definition${RST}\n" "${#SECRET_SHAPES[@]}"
[[ -n "$LEG" ]] && printf "  ${DIM}Leg: %s${RST}\n" "$LEG"
printf '%s\n' "  ------------------------------------------------"

# Under a leg flag, prune the same directories backup-home prunes. Without it the
# scan reports archives from trees that can never reach the artifact root:
# StuffFromOldComputer/ and github-copilot-intellij/ alone accounted for three
# of the first four findings on this machine.
PRUNE=(); PRUNED_NAMES=""
if $USE_TARGETS || $USE_ONEDRIVE; then
  _excl=( ${EXTERNAL_EXCLUDES[@]+"${EXTERNAL_EXCLUDES[@]}"} )
  # The OneDrive leg runs both lists, so an archive under a directory kept off
  # corporate cloud (Personal/, Benefits/, ...) is correctly not reported here
  # even though the external leg does carry it.
  $USE_ONEDRIVE && _excl=( "${_excl[@]}" ${ONEDRIVE_EXTRA_EXCLUDES[@]+"${ONEDRIVE_EXTRA_EXCLUDES[@]}"} )
  _first=1
  for _p in ${_excl[@]+"${_excl[@]}"}; do
    case "$_p" in
      */) _n="${_p%/}"
          case "$_n" in
            */*) _expr=( -path "*/$_n" ) ;;
            *)   _expr=( -name "$_n" ) ;;
          esac
          # The two exclude lists overlap by design, so dedupe for display --
          # github-copilot-intellij/ alone appears three times across them.
          case ", ${PRUNED_NAMES}," in
            *", ${_n},"*) ;;
            *) PRUNED_NAMES="${PRUNED_NAMES}${PRUNED_NAMES:+, }${_n}" ;;
          esac
          if (( _first )); then PRUNE=( "${_expr[@]}" ); _first=0
          else PRUNE=( "${PRUNE[@]}" -o "${_expr[@]}" ); fi ;;
    esac
  done
fi

# Drop unusable roots first. This check used to live inside the loop below,
# whose stdout is redirected into $LIST -- so the warning text was captured as a
# list entry and then scanned as though it were an archive.
VALID_ROOTS=()
for root in "${ROOTS[@]}"; do
  if [[ -d "$root" ]]; then
    VALID_ROOTS+=( "$root" )
  else
    printf "  ${YEL}!  not a directory, skipping: %s${RST}\n" "$root" >&2
  fi
done
ROOTS=( ${VALID_ROOTS[@]+"${VALID_ROOTS[@]}"} )
if (( ${#ROOTS[@]} == 0 )); then
  echo "ERROR: no scannable directory among the roots given." >&2; exit 2
fi

LIST="$(mktemp)"
for root in "${ROOTS[@]}"; do
  if (( ${#PRUNE[@]} > 0 )); then
    find -L "$root" \( "${PRUNE[@]}" \) -prune -o -type f \
      \( -iname '*.zip' -o -iname '*.jar' -o -iname '*.war' -o -iname '*.7z' \
         -o -iname '*.tar' -o -iname '*.tgz' -o -iname '*.tar.gz' \
         -o -iname '*.tar.bz2' -o -iname '*.tar.xz' \) -print 2>/dev/null
  else
    find -L "$root" -type f \
      \( -iname '*.zip' -o -iname '*.jar' -o -iname '*.war' -o -iname '*.7z' \
         -o -iname '*.tar' -o -iname '*.tgz' -o -iname '*.tar.gz' \
         -o -iname '*.tar.bz2' -o -iname '*.tar.xz' \) -print 2>/dev/null
  fi
done | sort -u > "$LIST"

# Say what was actually scanned. Without this the reader cannot tell whether a
# quiet result means "nothing found" or "nothing looked at" -- and under
# a leg flag the root list comes from config, so it is not visible on the
# command line either.
ROOT_LINES=""
printf "  ${DIM}Scanned %d archive(s) under %d director%s:${RST}\n" \
  "$(grep -c . "$LIST")" "${#ROOTS[@]}" "$( (( ${#ROOTS[@]} == 1 )) && echo y || echo ies )"
for root in "${ROOTS[@]}"; do
  _c="$(grep -c "^${root%/}/" "$LIST")"
  printf "    ${DIM}%6s  %s${RST}\n" "$_c" "$root"
  ROOT_LINES="${ROOT_LINES}- \`$root\` — $_c archive(s)"$'\n'
done
if [[ -n "$PRUNED_NAMES" ]]; then
  if $USE_ONEDRIVE; then
    printf "  ${DIM}Pruned (EXTERNAL_EXCLUDES + ONEDRIVE_EXTRA_EXCLUDES): %s${RST}\n" "$PRUNED_NAMES"
  else
    printf "  ${DIM}Pruned (EXTERNAL_EXCLUDES): %s${RST}\n" "$PRUNED_NAMES"
  fi
fi
echo ""

while IFS= read -r a; do
  [[ -n "$a" ]] || continue
  scan_archive "$a"
done < "$LIST"

echo ""
if (( HITS > 0 )); then
  printf "  ${RED}%d of %d archive(s) hold credential-shaped members.${RST}\n" "$HITS" "$SCANNED"
  (( SKIPPED_HITS > 0 )) && printf "  ${DIM}%d of those is already in ARCHIVE_SKIP and will not be copied.${RST}\n" "$SKIPPED_HITS"
  printf "  ${DIM}A shape match is a candidate, not proof. Decide per archive: keep it,${RST}\n"
  printf "  ${DIM}add it to ARCHIVE_SKIP in archive-policy.conf.sh, or move it under${RST}\n"
  printf "  ${DIM}secrets-encrypted/ so the DMG covers it.${RST}\n"
else
  printf "  ${GRN}No archive held a credential-shaped member (%d scanned).${RST}\n" "$SCANNED"
fi
(( UNREADABLE > 0 )) && printf "  ${YEL}%d archive(s) had no reader available and were not scanned.${RST}\n" "$UNREADABLE"

# Resolve where the report goes. Default is a run directory beside the Phase 3B
# sweep's own reports: both answer "is credential material sitting in the
# clear?", so keeping them under one artifact folder means one place to look,
# and loose-secrets-reports/ is already an expected artifact folder.
RUN_DIR=""
if ! $NO_REPORT && [[ -z "$REPORT" ]]; then
  if [[ -z "$DEST_ROOT" ]]; then
    if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
      DEST_ROOT="$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports/content-scans"
    else
      printf "  ${YEL}!  REIMAGE_ARTIFACT_ROOT unset and no --dest given; no report written.${RST}\n" >&2
    fi
  fi
  if [[ -n "${_SCAN_RUN_DIR:-}" ]]; then
    RUN_DIR="$_SCAN_RUN_DIR"
  elif [[ -n "$DEST_ROOT" ]]; then
    RUN_DIR="$DEST_ROOT/runs/${REPORT_CONTEXT}-$(date '+%Y%m%d-%H%M%S')"
    mkdir -p "$RUN_DIR" || { echo "ERROR: cannot create $RUN_DIR" >&2; exit 2; }
  fi
  if [[ -n "$RUN_DIR" ]]; then
    # One file per leg, so a both-legs run writes two into the same directory.
    case "$LEG" in
      *ONEDRIVE*) REPORT="$RUN_DIR/archive-content-scan-onedrive.md" ;;
      *EXTERNAL*) REPORT="$RUN_DIR/archive-content-scan-external.md" ;;
      *)          REPORT="$RUN_DIR/archive-content-scan.md" ;;
    esac
  fi
fi

if [[ -n "$REPORT" ]]; then
  {
    echo "# Archive Content Scan"
    echo ""
    [[ -n "$LEG" ]] && { echo "Leg: $LEG"; echo ""; }
    echo "## Directories scanned"
    echo ""
    printf '%s' "$ROOT_LINES"
    if [[ -n "$PRUNED_NAMES" ]]; then
      echo ""
      echo "Pruned, per the directory-shaped entries in EXTERNAL_EXCLUDES:"
      echo ""
      echo "$PRUNED_NAMES"
    fi
    echo ""
    echo "Archive members matched against the shared SECRET_SHAPES definition."
    echo "A match is a candidate to inspect, not proof of a secret."
    echo ""
    echo "- archives scanned: $SCANNED"
    echo "- archives with credential-shaped members: $HITS"
    echo "- archives with no reader available: $UNREADABLE"
    [[ -s "$FOUND" ]] && cat "$FOUND"
  } > "$REPORT"
  printf "  ${DIM}Report: %s${RST}\n" "$REPORT"

  # MANIFEST + latest-run pointer, mirroring the Phase 3B sweep's convention.
  # Only for a run directory: --report is an explicit one-off and should not
  # append history.
  if [[ -n "$RUN_DIR" ]]; then
    [[ -n "$DEST_ROOT" ]] || DEST_ROOT="$(dirname "$(dirname "$RUN_DIR")")"
    MANIFEST="$DEST_ROOT/MANIFEST.md"
    if [[ ! -f "$MANIFEST" ]]; then
      {
        echo "# Content Scan Runs"
        echo ""
        echo "Scans that read *inside* files rather than matching filenames:"
        echo "archives (\`scan-archive-contents.sh\`) and Postman exports"
        echo "(\`scan-postman-collections.py\`). The filename sweep that produced"
        echo "\`../open-findings.md\` cannot see either."
        echo ""
        echo "| Finished | Context | Scan | Leg | Scanned | With findings | Run |"
        echo "|---|---|---|---|---:|---:|---|"
      } > "$MANIFEST"
    fi
    printf '| %s | %s | archives | %s | %d | %d | `%s` |\n' \
      "$(date '+%Y-%m-%d %H:%M:%S')" "$REPORT_CONTEXT" "${LEG:-artifact root}" \
      "$SCANNED" "$HITS" "$(basename "$RUN_DIR")" >> "$MANIFEST"
    printf '%s\n' "$RUN_DIR" > "$DEST_ROOT/latest-run.txt"
  fi
fi

rm -f "$FOUND" "$LIST"
(( HITS > 0 )) && exit 1
exit 0
