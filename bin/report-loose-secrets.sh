#!/usr/bin/env bash
# =============================================================================
# report-loose-secrets.sh
#
# Reports credential-shaped files sitting in plaintext under the artifact root,
# and loose payload files still sitting inside secrets-encrypted/.
#
# Only secrets-encrypted/ is packaged into the Phase 3C encrypted DMG, and only
# its contents are cleaned up afterwards. A credential-shaped file anywhere else
# in the artifact root — home-files-backup/, app-settings-backup/, staged
# ignored files — stays in the clear on the drive permanently. This check is how
# that is found before the drive leaves your hands.
#
# Runbook: stage-loose-secrets.md (Phase 3B). Paired with
# bin/stage-loose-secrets.sh, which acts on the same findings; this one only
# reports. It examines material produced by six earlier phases, but it is
# invoked from that one runbook — it reports before the sweep and again after,
# to confirm the encryption boundary holds before Phase 3C builds the DMG.
#
# This file is intended for bin/. It is an aggregate validator: it records every
# finding and reports all results rather than aborting on the first one, so it
# deliberately does NOT use `set -e`. It never touches the artifacts it checks —
# it creates nothing, moves nothing, and deletes nothing under the directories
# it scans. Its only write is its own report directory. Acting on a finding is
# yours to do.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/report-loose-secrets.sh
#
#   # Check the configured artifact root
#   ./bin/report-loose-secrets.sh
#
#   # Check a specific root instead
#   ./bin/report-loose-secrets.sh --artifact-root /Volumes/Data/reimage-<asset>-<date>-open
#
#   # Label the run so the before/after checks stay distinguishable
#   ./bin/report-loose-secrets.sh --context pre-image-stage-loose-secrets
#   ./bin/report-loose-secrets.sh --context pre-image-stage-loose-secrets-after
#
#   # Re-check during triage without adding a run directory
#   ./bin/report-loose-secrets.sh --no-report
#
#   # List every path checked, not just the findings
#   ./bin/report-loose-secrets.sh --verbose
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --dest DIR            Loose-secrets-reports root directory.
#                         Default: $REIMAGE_ARTIFACT_ROOT/loose-secrets-reports.
#   --context LABEL       Context prefix for the timestamped run directory.
#                         Must be pre-image, post-image, or start with
#                         pre-image- / post-image- (e.g. pre-image-stage-loose-secrets).
#                         Default: pre-image.
#   --no-report           Print to the terminal only; write nothing. Use while
#                         triaging findings, or when the drive is read-only.
#   --verbose             Also print the directories scanned and the counts.
#   -h, --help            Show this message and exit.
#
# Output (written beneath --dest, unless --no-report):
#   open-findings.md
#       The rolling view, and the one to read first. Every candidate ever
#       found, whether it is still open, which run it first appeared in, and
#       how many checks it has survived. A finding ignored across three checks
#       is marked; MANIFEST.md cannot show that because it is per-run.
#   findings-ledger.tsv
#       Authoritative state behind open-findings.md. One row per candidate:
#       kind, path, first-run, last-run, runs-seen, state. Edit nothing here;
#       resolve the file on disk and the next run updates the row.
#   MANIFEST.md
#       Append-only index of completed checks. A run with findings is still a
#       completed run and is still indexed — the findings are the evidence.
#   latest-run.txt
#       Relative path to the newest completed run directory.
#   runs/<context>-YYYYMMDD-HHMMSS/loose-secrets-report.txt
#       Full terminal output of the run, ANSI color codes intact. View with
#       `less -R` or `cat` in a terminal so the severity colors still render.
#   runs/<context>-YYYYMMDD-HHMMSS/findings.tsv
#       That run's candidates alone, as kind + path.
#
#   The report lists candidate *paths*, never file contents, so it is an
#   inventory rather than a secret. It still names where credentials live on
#   the drive — keep it with the drive and dispose of it with the rest of the
#   artifact root.
#
# What counts as a finding:
#   OUTSIDE  A credential-shaped filename anywhere under the artifact root
#            except secrets-encrypted/. Phase 3C never encrypts these, and
#            Phase 3C cleanup never removes them. This is the finding that
#            matters; bin/stage-loose-secrets.sh is what resolves it.
#   INSIDE   A file under secrets-encrypted/ that is not recognisable evidence
#            (a .dmg, checksum, .txt/.tsv/.md/.log) — reported only once a DMG
#            exists in secrets-encrypted/. Loose payload that should have been
#            cleaned up after the DMG was verified.
#   STAGED   The same payload before any DMG exists. Expected: staging is what
#            secrets-encrypted/ is for. Listed with --verbose, never counted,
#            never affects exit status.
#
#   Matching is by filename only — this never reads file contents, so treat
#   every finding as a candidate to inspect, not a proven secret.
#
# Exit status:
#   0  No candidates found.
#   1  One or more candidates found. Review each before the drive leaves.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

# Aggregate validator: intentionally NOT `set -e`. Every finding must be
# recorded and reported in one pass. `-u` and `pipefail` are still wanted.
set -uo pipefail

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

# Keep loading permissive so --artifact-root can override after parsing.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

# ── Colors ──────────────────────────────────────────────────────────────────
# Same palette and section helpers as the other bin/ entrypoints so severity
# colors mean the same thing across the workflow.
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

thin_hr()     { printf '%s\n' "  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"; }
log_section() { echo ""; echo -e "${BLD}${CYN}▸ $1${RST}"; thin_hr; }

# ---------------------------------------------------------------------------
# Defaults and command-line state
# ---------------------------------------------------------------------------
VERBOSE=false
REPORT_DEST=""
REPORT_DEST_EXPLICIT=false
REPORT_CONTEXT="pre-image"
NO_REPORT=false

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

require_option_value() {
  local option="$1"
  local value="${2:-}"

  if [[ -z "$value" || "$value" == --* ]]; then
    echo "ERROR: $option requires a non-empty value." >&2
    usage >&2
    exit 2
  fi
}

# ---------------------------------------------------------------------------
# Parse command-line options
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --dest)
      require_option_value "$1" "${2:-}"
      REPORT_DEST="${2%/}"
      REPORT_DEST_EXPLICIT=true
      shift 2
      ;;
    --context)
      require_option_value "$1" "${2:-}"
      REPORT_CONTEXT="$2"
      shift 2
      ;;
    --no-report)
      NO_REPORT=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
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

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set." >&2
  echo "Create/source reimage.env or pass --artifact-root PATH." >&2
  exit 2
fi

if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: artifact root not found: $REIMAGE_ARTIFACT_ROOT" >&2
  echo "Mount the volume or correct reimage.env." >&2
  exit 2
fi

REIMAGE_ARTIFACT_ROOT="${REIMAGE_ARTIFACT_ROOT%/}"

# Same context grammar as report-size-audit.sh so both checks label their runs
# identically and sort the same way in their manifests.
case "$REPORT_CONTEXT" in
  pre-image|post-image|pre-image-?*|post-image-?*)
    case "$REPORT_CONTEXT" in
      *[/\\]*|*..*|.*|*[[:space:]]*)
        echo "ERROR: --context must not contain slashes, '..', a leading dot, or whitespace, got: $REPORT_CONTEXT" >&2
        exit 2
        ;;
    esac
    ;;
  *)
    echo "ERROR: --context must be pre-image, post-image, or start with pre-image- or post-image- (e.g. post-image-signoff), got: $REPORT_CONTEXT" >&2
    exit 2
    ;;
esac

# Resolve the report destination only after --artifact-root has been applied,
# so an overridden root reports beneath itself rather than beneath the
# configured one.
if [[ "$NO_REPORT" == true ]]; then
  if [[ "$REPORT_DEST_EXPLICIT" == true ]]; then
    echo "ERROR: --no-report and --dest are mutually exclusive." >&2
    exit 2
  fi
  REPORT_DEST=""
elif [[ "$REPORT_DEST_EXPLICIT" != true ]]; then
  REPORT_DEST="$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports"
fi

# ---------------------------------------------------------------------------
# Match predicates
#
# Matching happens inside find, not in the shell. Testing each filename in bash
# forks two subshells per file, which over a full home-directory backup
# (hundreds of thousands of files) takes many minutes and reads as a hang.
# ---------------------------------------------------------------------------
# The shapes come from shared config — SECRET_SHAPES_FLOOR in artifact-config.sh
# plus anything secret-shapes.conf.sh adds — so this script and
# bin/stage-loose-secrets.sh can never disagree about what a credential looks
# like. Keeping a private copy here is what let the external and OneDrive
# exclude lists drift twenty-two shapes apart.
if ! declare -f build_secret_shape_predicate >/dev/null 2>&1; then
  echo "ERROR: shared config did not provide build_secret_shape_predicate." >&2
  echo "Update .internal/artifact-config.sh — it defines the secret-shape floor." >&2
  exit 2
fi

if ! declare -f loose_secret_exception_reason >/dev/null 2>&1; then
  echo "ERROR: shared config did not provide loose_secret_exception_reason." >&2
  echo "Update .internal/artifact-config.sh." >&2
  exit 2
fi

build_secret_shape_predicate SECRET_SHAPE_PRED

if (( ${#SECRET_SHAPE_PRED[@]} == 0 )); then
  echo "ERROR: the secret-shape list resolved to nothing; refusing to report a" >&2
  echo "clean drive on an empty pattern set." >&2
  exit 2
fi

# Files that legitimately live under secrets-encrypted/ without being payload:
# the DMG itself, its checksum, and the manifests/reports around it.
ALLOWED_EVIDENCE_PRED=(
  -iname '*.dmg'    -o -iname '*.sha256' -o -iname '*.sha256sum'
  -o -iname '*.txt' -o -iname '*.tsv'    -o -iname '*.md'
  -o -iname '*.log'
)

SECRETS_DIR="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"

# ---------------------------------------------------------------------------
# Report capture (loose-secrets-reports)
#
# Mirrors the size-audit-reports pattern: MANIFEST.md + latest-run.txt +
# self-contained runs/<context>-YYYYMMDD-HHMMSS/ directories, written to a
# .incomplete staging name and atomically renamed once the check has actually
# finished, so an interrupted run never lands in the manifest as evidence.
#
# A run that finds candidates is still a completed run and is still indexed —
# the findings ARE the evidence. Only an aborted or errored run is discarded.
# ---------------------------------------------------------------------------

# Findings are collected here first so the same list feeds the terminal output,
# the per-run findings.tsv, and the rolling ledger merge.
FINDINGS_TSV="$(mktemp "${TMPDIR:-/tmp}/loose-secrets-findings.XXXXXX")"
if [[ -z "$FINDINGS_TSV" || ! -f "$FINDINGS_TSV" ]]; then
  echo "ERROR: could not create a temporary findings file." >&2
  exit 2
fi

# One EXIT trap for the whole script. A bare `[[ ]] && cmd` as the last
# statement of a function returns 1, so each guard is a full `if` and the
# function ends with an explicit `return 0`.
cleanup_loose_secrets_run() {
  if [[ -n "${FINDINGS_TSV:-}" && -f "$FINDINGS_TSV" ]]; then
    rm -f "$FINDINGS_TSV"
  fi
  if [[ -n "${WORK_RUN_DIR:-}" && -d "$WORK_RUN_DIR" ]]; then
    rm -rf "$WORK_RUN_DIR"
  fi
  return 0
}
trap cleanup_loose_secrets_run EXIT
trap 'exit 130' INT TERM

SAVE_REPORT=false
if [[ -n "$REPORT_DEST" ]]; then
  if ! mkdir -p "$REPORT_DEST/runs"; then
    echo "ERROR: cannot create report directory: $REPORT_DEST/runs" >&2
    echo "Fix the destination, pass --dest DIR, or run with --no-report." >&2
    exit 2
  fi

  MANIFEST_PATH="$REPORT_DEST/MANIFEST.md"
  LATEST_RUN_PATH="$REPORT_DEST/latest-run.txt"
  STAMP="$(date +%Y%m%d-%H%M%S)"
  RUN_ID="${REPORT_CONTEXT}-${STAMP}"
  RUN_RELATIVE="runs/$RUN_ID"
  FINAL_RUN_DIR="$REPORT_DEST/$RUN_RELATIVE"
  WORK_RUN_DIR="$REPORT_DEST/runs/.${RUN_ID}.incomplete"

  if [[ -e "$FINAL_RUN_DIR" || -e "$WORK_RUN_DIR" ]]; then
    echo "ERROR: loose-secrets run directory already exists for this timestamp: $FINAL_RUN_DIR" >&2
    exit 2
  fi

  if [[ -e "$MANIFEST_PATH" ]] && ! grep -q '^# Loose Secret Checks$' "$MANIFEST_PATH" 2>/dev/null; then
    echo "ERROR: existing manifest is not the canonical append-only loose-secrets index:" >&2
    echo "  $MANIFEST_PATH" >&2
    echo "Remove that file before running the current loose-secrets check." >&2
    exit 2
  fi

  if ! mkdir "$WORK_RUN_DIR"; then
    echo "ERROR: cannot create run directory: $WORK_RUN_DIR" >&2
    exit 2
  fi

  LEDGER_PATH="$REPORT_DEST/findings-ledger.tsv"
  OPEN_FINDINGS_PATH="$REPORT_DEST/open-findings.md"

  REPORT="$WORK_RUN_DIR/loose-secrets-report.txt"
  # ANSI color codes are captured on purpose so the same severity colors read
  # the same way later. View with `less -R` or `cat` in a terminal; a raw
  # dump (e.g. `cat -v`) will show the escape codes literally instead.
  exec > >(tee -a "$REPORT") 2>&1
  SAVE_REPORT=true
fi

# Appends the manifest row, updates the latest-run pointer, and atomically
# promotes the run directory. Called at both clean end-of-check exits (findings
# and no findings) so there is exactly one place that finalizes a run.
finalize_loose_secrets_report() {
  local result="$1"

  [[ "$SAVE_REPORT" == true ]] || return 0

  if ! mv "$WORK_RUN_DIR" "$FINAL_RUN_DIR"; then
    echo "WARNING: could not promote the run directory; this run was not indexed." >&2
    echo "  $WORK_RUN_DIR -> $FINAL_RUN_DIR" >&2
    return 0
  fi

  if [[ ! -e "$MANIFEST_PATH" ]]; then
    cat > "$MANIFEST_PATH" <<'EOF'
# Loose Secret Checks

This file is an append-only index of completed loose-plaintext-secret checks.
A run with findings is still a completed run — the findings are the evidence.
Reports keep their original ANSI color codes — use `less -R` or `cat` in a
terminal to view them with the severity colors intact.

| Completed | Context | Run | Outside | Inside | Result | Report |
|---|---|---|---:|---:|---|---|
EOF
  fi

  printf '| %s | `%s` | `%s` | %s | %s | %s | [Open report](%s/loose-secrets-report.txt) |\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$REPORT_CONTEXT" "$RUN_ID" \
    "$outside_count" "$inside_count" "$result" \
    "$RUN_RELATIVE" >> "$MANIFEST_PATH"

  LATEST_TEMP="$REPORT_DEST/.latest-run.$$.tmp"
  printf '%s\n' "$RUN_RELATIVE" > "$LATEST_TEMP"
  mv "$LATEST_TEMP" "$LATEST_RUN_PATH"

  cp "$FINDINGS_TSV" "$FINAL_RUN_DIR/findings.tsv"

  update_findings_ledger

  trap - EXIT INT TERM
  cleanup_loose_secrets_run

  echo -e "${DIM}Report saved (ANSI color codes intact):${RST}"
  echo -e "${DIM}  $FINAL_RUN_DIR/loose-secrets-report.txt${RST}"
  echo -e "${DIM}Manifest:      $MANIFEST_PATH${RST}"
  echo -e "${DIM}Latest-run:    $LATEST_RUN_PATH${RST}"
  echo -e "${DIM}Open findings: $OPEN_FINDINGS_PATH${RST}"
  echo ""
}

# ---------------------------------------------------------------------------
# Rolling findings ledger
#
# MANIFEST.md answers "what did that run find". This answers the question the
# manifest cannot: "what did we find and never deal with". Each candidate path
# is carried across runs with the run it was first seen in and how many runs it
# has survived, so a finding that is ignored three checks in a row is louder
# than one that showed up once, not quieter.
#
# findings-ledger.tsv is the authoritative state; open-findings.md is a
# regenerated human view of it. Columns:
#   kind  path  first-run  last-run  runs-seen  state(open|resolved)
# ---------------------------------------------------------------------------
update_findings_ledger() {
  local ledger_temp="$REPORT_DEST/.findings-ledger.$$.tmp"
  local open_temp="$REPORT_DEST/.open-findings.$$.tmp"
  local tab
  tab="$(printf '\t')"

  [[ -e "$LEDGER_PATH" ]] || : > "$LEDGER_PATH"

  # Merge previous ledger (file 1) with this run's findings (file 2). A path
  # present in both stays open and increments; a path only in the ledger is
  # resolved; a path only in this run is new.
  # Split the two inputs by FILENAME, not by the usual `NR == FNR`: on the very
  # first check the ledger is empty, awk never advances FNR for it, and every
  # findings line would be misread as a ledger row.
  awk -F"$tab" -v OFS="$tab" -v run="$RUN_ID" -v ledgerfile="$LEDGER_PATH" '
    FILENAME == ledgerfile {
      key = $2
      lkind[key] = $1; lfirst[key] = $3; llast[key] = $4
      ltimes[key] = $5; lstate[key] = $6
      lorder[++n] = key
      next
    }
    {
      key = $2
      if (!(key in cur)) { corder[++m] = key }
      cur[key] = 1; ckind[key] = $1
    }
    END {
      for (i = 1; i <= n; i++) {
        key = lorder[i]
        if (key in cur) {
          print ckind[key], key, lfirst[key], run, ltimes[key] + 1, "open"
        } else {
          print lkind[key], key, lfirst[key], llast[key], ltimes[key], "resolved"
        }
        seen[key] = 1
      }
      for (j = 1; j <= m; j++) {
        key = corder[j]
        if (!(key in seen)) { print ckind[key], key, run, run, 1, "open" }
      }
    }
  ' "$LEDGER_PATH" "$FINDINGS_TSV" > "$ledger_temp" || {
    echo "WARNING: could not update $LEDGER_PATH; previous ledger left intact." >&2
    rm -f "$ledger_temp"
    return 0
  }
  mv "$ledger_temp" "$LEDGER_PATH"

  # Open first, then most-persistent first inside each group.
  sort -t "$tab" -k6,6 -k5,5nr -k2,2 "$LEDGER_PATH" \
    | awk -F"$tab" -v run="$RUN_ID" -v when="$(date '+%Y-%m-%d %H:%M:%S')" '
      $6 == "open" {
        oc++
        if ($5 + 0 > 1) { carried++ }
        mark = ($5 + 0 >= 3) ? " ⚠" : ""
        orows = orows sprintf("| %s | `%s` | `%s` | %s%s |\n", $1, $2, $3, $5, mark)
        next
      }
      { rc++; rrows = rrows sprintf("| %s | `%s` | `%s` | `%s` |\n", $1, $2, $3, $4) }
      END {
        print "# Open Loose-Secret Findings"
        print ""
        print "Regenerated on every saved run of `bin/report-loose-secrets.sh`."
        print "MANIFEST.md records what each run found. This file records what is"
        print "still **unaddressed**, and how many checks each candidate has survived."
        print ""
        printf "Last updated: %s (run `%s`)\n", when, run
        print ""
        print "Paths are relative to the artifact root. Matching is by filename shape,"
        print "so a row is a candidate to inspect, not a proven secret — resolve a row"
        print "by moving the file into `secrets-encrypted/` or by confirming it holds no"
        print "secret and leaving it. Either way it drops off this list once it no longer"
        print "matches, or once it lives inside `secrets-encrypted/`."
        print ""
        printf "## Open — %d\n", oc + 0
        print ""
        if (oc + 0 > 0) {
          printf "%d of these were already open before the latest run. ", carried + 0
          print "A ⚠ marks a candidate that has now survived three or more checks."
          print ""
          print "| Kind | Path | First seen | Runs seen |"
          print "|---|---|---|---:|"
          printf "%s", orows
        } else {
          print "None. Every candidate ever found has been resolved."
        }
        print ""
        printf "## Resolved — %d\n", rc + 0
        print ""
        if (rc + 0 > 0) {
          print "Seen in an earlier check, absent from the latest one."
          print ""
          print "| Kind | Path | First seen | Last seen |"
          print "|---|---|---|---|"
          printf "%s", rrows
        } else {
          print "None yet."
        }
      }
    ' > "$open_temp" || {
      echo "WARNING: could not regenerate $OPEN_FINDINGS_PATH." >&2
      rm -f "$open_temp"
      return 0
    }
  mv "$open_temp" "$OPEN_FINDINGS_PATH"

  # Rolling counts belong in the terminal output too — the whole point is that
  # an ignored finding gets louder, and nobody opens the markdown to learn that.
  local agg open_now carried_now resolved_now
  agg="$(awk -F"$tab" '
    $6 == "open"     { o++; if ($5 + 0 > 1) { c++ } }
    $6 == "resolved" { r++ }
    END { printf "%d %d %d", o + 0, c + 0, r + 0 }
  ' "$LEDGER_PATH")"
  read -r open_now carried_now resolved_now <<EOF
$agg
EOF

  echo -e "  ${BLD}Across all checks of this artifact root${RST}"
  if (( open_now == 0 )); then
    printf "    ${GRN}%-24s %s${RST}\n" "open findings:" "0"
  else
    printf "    ${YEL}%-24s %s${RST}\n" "open findings:" "$open_now"
    if (( carried_now > 0 )); then
      printf "    ${RED}%-24s %s${RST}\n" "carried from earlier:" "$carried_now"
    fi
  fi
  printf "    ${DIM}%-24s %s${RST}\n" "resolved so far:" "$resolved_now"
  echo ""
  return 0
}

# ---------------------------------------------------------------------------
# Scan
# ---------------------------------------------------------------------------
log_section "Loose plaintext secret check"
echo -e "  ${DIM}Artifact root: $REIMAGE_ARTIFACT_ROOT${RST}"
if [[ "$SAVE_REPORT" == true ]]; then
  echo -e "  ${DIM}Report run   : $REPORT_DEST/$RUN_RELATIVE${RST}"
else
  echo -e "  ${DIM}Report run   : not saved (--no-report)${RST}"
fi
echo -e "  ${DIM}Filename heuristics only — contents are never read.${RST}"

# Never let the check's own reports become findings of the check. They are
# .txt/.md today and cannot match a secret shape, but excluding the directory
# keeps that true if the shape list ever widens.
OUTSIDE_EXCLUDE_PRED=( ! -path "$SECRETS_DIR/*" )
if [[ -n "$REPORT_DEST" ]]; then
  OUTSIDE_EXCLUDE_PRED=( "${OUTSIDE_EXCLUDE_PRED[@]}" ! -path "$REPORT_DEST/*" )
fi

outside_count=0
inside_count=0
accepted_count=0

echo ""
echo -e "  ${BLD}Credential-shaped files outside secrets-encrypted/${RST}"
echo -e "  ${DIM}These are never encrypted by Phase 3C and never cleaned up.${RST}"

while IFS= read -r -d '' candidate; do
  rel="${candidate#"$REIMAGE_ARTIFACT_ROOT"/}"

  # An accepted path is a decision you recorded, not a finding. It is still
  # listed — silently dropping it would make the exceptions file invisible —
  # but it does not count toward OUTSIDE and does not affect exit status.
  if accept_reason="$(loose_secret_exception_reason "$rel")"; then
    accepted_count=$((accepted_count + 1))
    printf "    ${DIM}ACCEPTED${RST} %s\n" "$rel"
    printf "             ${DIM}%s${RST}\n" "$accept_reason"
    continue
  fi

  outside_count=$((outside_count + 1))
  printf "    ${YEL}OUTSIDE${RST}  %s\n" "$rel"
  printf 'OUTSIDE\t%s\n' "$rel" >> "$FINDINGS_TSV"
done < <(
  find "$REIMAGE_ARTIFACT_ROOT" -type f \
    "${OUTSIDE_EXCLUDE_PRED[@]}" \
    ! -name '.DS_Store' ! -name '._*' \
    \( "${SECRET_SHAPE_PRED[@]}" \) \
    -print0 2>/dev/null | sort -z
)

if (( outside_count == 0 )); then
  echo -e "    ${GRN}none${RST}"
fi
if (( accepted_count > 0 )); then
  echo -e "    ${DIM}$accepted_count accepted by loose-secret-exceptions.conf.sh${RST}"
fi

# Payload inside secrets-encrypted/ is only a finding once the DMG exists.
# Before Phase 3C builds it, that directory is *supposed* to hold loose payload
# — that is what staging means. Counting it as a finding at every pre-image
# phase would make this check cry wolf on every run, which is the fastest way
# to teach someone to ignore it.
DMG_PRESENT=false
if [[ -d "$SECRETS_DIR" ]] \
  && [[ -n "$(find "$SECRETS_DIR" -maxdepth 1 -type f -iname '*.dmg' 2>/dev/null | head -1)" ]]; then
  DMG_PRESENT=true
fi

staged_count=0

echo ""
if [[ "$DMG_PRESENT" == true ]]; then
  echo -e "  ${BLD}Loose payload still inside secrets-encrypted/${RST}"
  echo -e "  ${DIM}The DMG exists, so this should be empty — verify it, then clean up.${RST}"
else
  echo -e "  ${BLD}Staged payload inside secrets-encrypted/${RST}"
  echo -e "  ${DIM}No DMG yet, so payload here is expected. Listed, not counted.${RST}"
fi

if [[ -d "$SECRETS_DIR" ]]; then
  while IFS= read -r -d '' candidate; do
    rel="secrets-encrypted/${candidate#"$SECRETS_DIR"/}"
    if [[ "$DMG_PRESENT" == true ]]; then
      inside_count=$((inside_count + 1))
      printf "    ${YEL}INSIDE ${RST}  %s\n" "${candidate#"$SECRETS_DIR"/}"
      printf 'INSIDE\t%s\n' "$rel" >> "$FINDINGS_TSV"
    else
      staged_count=$((staged_count + 1))
      if [[ "$VERBOSE" == true ]]; then
        printf "    ${DIM}STAGED   %s${RST}\n" "${candidate#"$SECRETS_DIR"/}"
      fi
    fi
  done < <(
    find "$SECRETS_DIR" -type f \
      ! -name '.DS_Store' ! -name '._*' \
      ! \( "${ALLOWED_EVIDENCE_PRED[@]}" \) \
      -print0 2>/dev/null | sort -z
  )

  if [[ "$DMG_PRESENT" == true ]]; then
    if (( inside_count == 0 )); then
      echo -e "    ${GRN}none${RST}"
    fi
  elif (( staged_count == 0 )); then
    echo -e "    ${DIM}nothing staged yet${RST}"
  elif [[ "$VERBOSE" != true ]]; then
    echo -e "    ${DIM}$staged_count staged file(s) — pass --verbose to list them${RST}"
  fi
else
  echo -e "    ${DIM}secrets-encrypted/ does not exist yet${RST}"
fi

if [[ "$VERBOSE" == true ]]; then
  echo ""
  echo -e "  ${DIM}Scanned: $REIMAGE_ARTIFACT_ROOT (excluding secrets-encrypted/)${RST}"
  echo -e "  ${DIM}Scanned: $SECRETS_DIR${RST}"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
printf "  %-9s %s\n" "OUTSIDE:" "$outside_count"
if (( accepted_count > 0 )); then
  printf "  %-9s %s ${DIM}(recorded decisions — not counted)${RST}\n" "ACCEPTED:" "$accepted_count"
fi
if [[ "$DMG_PRESENT" == true ]]; then
  printf "  %-9s %s\n" "INSIDE:" "$inside_count"
else
  printf "  %-9s %s ${DIM}(expected — no DMG yet, not counted)${RST}\n" "STAGED:" "$staged_count"
fi
echo ""

if (( outside_count == 0 && inside_count == 0 )); then
  echo -e "  ${GRN}${BLD}✓ No loose plaintext secret candidates found.${RST}"
  echo ""
  finalize_loose_secrets_report "clean"
  exit 0
fi

echo -e "  ${RED}${BLD}✗ $((outside_count + inside_count)) candidate(s) need review.${RST}"
echo -e "  ${YEL}OUTSIDE: move into secrets-encrypted/ so Phase 3C encrypts it, or confirm it holds no secret.${RST}"
echo -e "  ${YEL}INSIDE:  confirm it is inside the verified DMG, then run: ./bin/create-secrets-dmg.sh cleanup${RST}"
echo ""
finalize_loose_secrets_report "**review**"
exit 1
