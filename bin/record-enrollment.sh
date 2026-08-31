#!/usr/bin/env bash
# =============================================================================
# record-enrollment.sh
#
# Phase 8 — Enroll and Stabilize evidence recorder. Runs read-only managed-
# baseline queries (MDM enrollment, configuration profiles, FileVault, installed
# applications and managed processes, macOS version, pending software updates,
# Keychain identities),
# writes each result to a raw/NN-*.txt file, compares the installed application
# set against the pre-image managed-inventory capture, then generates a Markdown
# record with the Phase 8 exit-criteria table prefilled for the
# command-verifiable rows.
#
# The expected managed application set is derived from the pre-image capture at
# $REIMAGE_ARTIFACT_ROOT/managed-inventory/, never from a list of vendor names
# held in this script. A hardcoded list cannot know what this particular Mac was
# assigned, and silently scores PASS on a machine missing an entire app suite.
# When the artifact volume is not mounted the comparison has no source and the
# row is stamped TODO rather than PASS — "could not check" and "checked and
# fine" must not look the same.
#
# This script records evidence and applies small heuristic PASS/WARN verdicts
# on the command-verifiable rows only. The truly human-judgment rows (Company
# Portal UI state, first stabilization restart completed, whether the managed
# app set matches current company policy) are left as TODO for you to close by
# hand after the restart checkpoint. See enroll-and-stabilize.md for the full
# runbook.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/record-enrollment.sh
#
#   # Default -- writes under $REIMAGE_ARTIFACT_ROOT if it resolves and is
#   # mounted, otherwise falls back to $REIMAGE_WORKSPACE_ROOT, otherwise to
#   # ~/Desktop/reimaged-system-artifacts/enrollment/.
#   ./bin/record-enrollment.sh
#
#   # Reveal the generated Markdown record in Finder after completion.
#   ./bin/record-enrollment.sh --open
#
#   # Override the artifact root for this invocation.
#   ./bin/record-enrollment.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Override the workspace root used for the local fallback path.
#   ./bin/record-enrollment.sh --workspace-root /path/to/reimage-workspace
#
#   # Write to an exact category root (skips the reimaged-system/restarts
#   # layout and the fallback chain entirely; runs/ is still created under it).
#   ./bin/record-enrollment.sh --output /absolute/path/to/output
#
#   # Point the managed-application comparison at a specific inventory capture.
#   ./bin/record-enrollment.sh --managed-inventory /path/to/managed-inventory
#
#   # Label the run so the two records around the stabilization restart are
#   # distinguishable on disk without opening them. Matches the --context
#   # convention already used by report-loose-secrets.sh.
#   ./bin/record-enrollment.sh --context pre-restart     # Step 6
#   ./bin/record-enrollment.sh --context post-restart    # Step 8
#
# Options:
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --workspace-root PATH Override REIMAGE_WORKSPACE_ROOT for the fallback path.
#   --output DIR          Exact output directory for generated files.
#   --managed-inventory DIR
#                         Override the pre-image managed-inventory directory
#                         used to derive the expected application set.
#   --context LABEL       The run's point. Conventional values are pre-restart
#                         and post-restart; omitted, the run is `initial`.
#                         Letters, digits, dot, underscore, and hyphen only.
#   --open                Reveal the generated record in Finder on completion.
#   -h, --help            Show this message and exit.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Run naming:
#   runs/enroll-and-stabilize-<point>-YYYYMMDD-HHMMSS/
#     record.md   the rendered record
#     raw/        the twelve numbered evidence files
#
#   The runbook name leads and the point follows it, so one lineage sorts
#   chronologically and `official/enroll-and-stabilize-<point>.txt` answers
#   "which run counts" per point. Nothing needs to rank a mixed set by hand,
#   which is what the old label-first naming forced on every reader.
#
#   There is no per-run MANIFEST.txt: it listed the same twelve files every
#   time and duplicated what `raw/` already shows. The category's MANIFEST.md
#   is the index that matters.
#
# Output location precedence (used only when --output is not supplied):
#   1. $REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts/
#        when REIMAGE_ARTIFACT_ROOT is set and currently mounted.
#   2. $REIMAGE_WORKSPACE_ROOT/restarts/
#        when the artifact root is not yet available and a workspace is set.
#   3. ~/Desktop/reimaged-system-artifacts/restarts/
#        as a final fallback so Phase 8 can complete on a bare Mac before the
#        external artifact volume is reconnected.
#
# Exit status:
#   0  Evidence recorded successfully.
#   1  Evidence capture ran but a generated file could not be written.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

# Normal operational entrypoint, not an aggregate validator: each read-only
# probe below is individually guarded with `|| true`, so `set -e` only fires on
# the directory/file writes that must succeed for the record to be usable.
set -euo pipefail

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

# Phase 8 typically runs on a freshly reimaged Mac where the external artifact
# volume may not be mounted yet. Keep loading permissive so the local fallback
# path can still succeed.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false

# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

# Shared run index. The enrollment records are indexed runs under
# reimaged-system/restarts/ alongside record-reimaged-system.sh's first-boot
# bundles: both capture the machine on one side of a stabilization restart, so
# they belong to one lineage keyed by point rather than to two categories that
# have to be read together.
RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/artifact-runs.sh
source "$RUNS_LIB"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

# Validate a --context label before it becomes part of a directory name. A label
# carrying a slash, a space, or a quote produces either a nested path or a name
# that later globs and `cp` invocations mishandle, so reject it outright rather
# than silently rewriting what the operator typed. The character class is a
# POSIX `case` glob rather than a regex so this behaves identically on the
# stock macOS Bash 3.2.
validate_context() {
  local value="$1"
  case "$value" in
    "")
      return 0
      ;;
    *[!A-Za-z0-9._-]*)
      echo "ERROR: --context may contain only letters, digits, dot, underscore, and hyphen: $value" >&2
      echo "HINT:  the label becomes part of the bundle directory name." >&2
      exit 2
      ;;
    -*)
      echo "ERROR: --context may not begin with a hyphen: $value" >&2
      exit 2
      ;;
  esac
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
# Defaults and command-line parsing
# ---------------------------------------------------------------------------
STAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_DIR=""
OPEN_RESULT=false
MANAGED_INVENTORY_DIR=""
CONTEXT_LABEL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --workspace-root)
      require_option_value "$1" "${2:-}"
      REIMAGE_WORKSPACE_ROOT="$2"
      shift 2
      ;;
    --output)
      require_option_value "$1" "${2:-}"
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --managed-inventory)
      require_option_value "$1" "${2:-}"
      MANAGED_INVENTORY_DIR="$2"
      shift 2
      ;;
    --context)
      require_option_value "$1" "${2:-}"
      validate_context "$2"
      CONTEXT_LABEL="$2"
      shift 2
      ;;
    --open)
      OPEN_RESULT=true
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

# ---------------------------------------------------------------------------
# Resolve output directory (fallback chain when --output is not supplied)
# ---------------------------------------------------------------------------
# The context label leads the directory name:
# pre-restart-record-enrollment-YYYYMMDD-HHMMSS. This matches the convention
# already used by post-image-performance-audit-*, post-reimage-*, and the
# pre-image-* repo-audit runs, where the phase or context comes first.
#
# Two consequences for anything that reads these directories back:
#   - the artifact name is no longer at the start, so globs need a leading
#     wildcard: *record-enrollment-* rather than record-enrollment-*;
#   - names group by label before timestamp, so a "latest record" lookup must
#     rank on the trailing stamp (or on modification time) and never on a
#     plain lexical sort of the mixed set.
# The stamp stays at the end of the name, which is what reimage-checklist.sh
# extracts to compare bundle age against the Time Machine backup.
# The context label becomes the run's POINT, so `--context pre-restart` lands in
# the pre-restart lineage with no further mapping. A run with no context gets
# `initial`, which is NOT a known point and indexes as `unknown` -- the honest
# answer, since nothing recorded which side of a restart it was on. This mirrors
# record-reimaged-system.sh exactly; the two scripts share the category.
if [[ -z "$OUTPUT_DIR" ]]; then
  if [[ -n "${REIMAGE_ARTIFACT_ROOT:-}" && -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
    OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system"
  elif [[ -n "${REIMAGE_WORKSPACE_ROOT:-}" && -d "$REIMAGE_WORKSPACE_ROOT" ]]; then
    OUTPUT_ROOT="$REIMAGE_WORKSPACE_ROOT"
  else
    OUTPUT_ROOT="$HOME/Desktop/reimaged-system-artifacts"
  fi
  OUTPUT_DIR="$OUTPUT_ROOT/restarts"
fi

# Resolve a relative --output against the current directory before the guard
# below compares it with the repo root. A relative path can never match
# "$REPO_ROOT"/*, so without this the guard is bypassed by `--output subdir`
# run from the checkout. The directory need not exist yet, so this is a plain
# textual prefix rather than a realpath() call (also keeps Bash 3.2 support).
case "$OUTPUT_DIR" in
  /*) ;;
  *) OUTPUT_DIR="$PWD/$OUTPUT_DIR" ;;
esac

# Safety invariant: refuse to write generated output under the repo checkout.
# A record landing inside the working tree is almost always an unset or
# relative root variable, not a real destination.
if [[ -n "${REPO_ROOT:-}" && ( "$OUTPUT_DIR" == "$REPO_ROOT" || "$OUTPUT_DIR" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $OUTPUT_DIR" >&2
  exit 2
fi

RUN_CATEGORY_ROOT="$OUTPUT_DIR"
RUN_CONTEXT="enroll-and-stabilize-${CONTEXT_LABEL:-initial}"

if ! artifact_run_begin "$RUN_CATEGORY_ROOT" "$RUN_CONTEXT"; then
  echo "ERROR: cannot stage an enrollment run under: $RUN_CATEGORY_ROOT" >&2
  echo "ERROR: no evidence was written. Choose a writable --output (or reconnect the artifact volume) and rerun." >&2
  exit 2
fi
OUT="$ARTIFACT_RUN_DIR"
RAW_DIR="$OUT/raw"
if ! mkdir -p "$RAW_DIR"; then
  echo "ERROR: cannot create the enrollment record directory: $OUT" >&2
  artifact_run_abort
  exit 2
fi

# ---------------------------------------------------------------------------
# Evidence capture helpers
# ---------------------------------------------------------------------------
record_cmd() {
  # Run a direct command and record stdout+stderr to a numbered raw file.
  local title="$1"
  local file="$2"
  shift 2
  echo "▶  $title ..."
  {
    echo "# $title"
    echo "# Generated: $(date)"
    echo "# Command: $*"
    echo ""
    "$@"
  } > "$RAW_DIR/$file" 2>&1 || true
  echo "   ✓ saved → raw/$file"
}

record_pipeline() {
  # Run a shell pipeline (used only for grep-based filters) and record the
  # result. Kept small and readable; avoids a login shell so profile output
  # cannot leak into the recorded evidence.
  local title="$1"
  local file="$2"
  local cmd="$3"
  echo "▶  $title ..."
  {
    echo "# $title"
    echo "# Generated: $(date)"
    echo "# Command: $cmd"
    echo ""
    bash -c "$cmd"
  } > "$RAW_DIR/$file" 2>&1 || true
  echo "   ✓ saved → raw/$file"
}

# ---------------------------------------------------------------------------
# Record raw evidence
# ---------------------------------------------------------------------------
record_cmd      "Enrollment status"              "01-enrollment-status.txt"     profiles status -type enrollment
# `profiles list` unprivileged returns USER-level profiles only. The managed
# baseline lives at _computerlevel, so the number that matters needs root --
# 4 user profiles versus 17 system ones on a typical enrolled Mac.
#
# `sudo -n` never prompts: it succeeds if a sudo credential is already cached
# and fails immediately otherwise. That keeps this script non-interactive, which
# is the whole reason it can be rerun freely, while still capturing the system
# scope whenever the operator has recently used sudo. The fallback records the
# user scope and says which one it got.
record_pipeline "Configuration profiles list"    "02-profiles-list.txt" \
  "if sudo -n profiles list 2>/dev/null; then echo; echo '# scope: system (_computerlevel), via sudo -n'; else profiles list; echo; echo '# scope: user only -- no cached sudo credential. Rerun after any sudo command, or run: sudo profiles list'; fi"
record_cmd      "FileVault status"               "03-filevault-status.txt"      fdesetup status
# Record every application, not a vendor-name filter, and include one level of
# nesting: agents such as Zscaler install as /Applications/Zscaler/Zscaler.app
# and a top-level listing alone is a weaker signal than it appears. The full
# list is also what the managed-inventory comparison below reads.
record_pipeline "Applications present"           "04-managed-apps.txt" \
  "{ ls -1 /Applications 2>/dev/null; ls -1d /Applications/*/*.app 2>/dev/null | sed 's#^/Applications/##'; } | sort -u"
record_pipeline "Managed processes present"      "05-managed-processes.txt" \
  "ps aux | grep -Ei 'Intune|Company Portal|CrowdStrike|falcon|Zscaler|Microsoft AutoUpdate|MAU|mdmclient' | grep -v grep || true"
record_cmd      "macOS version and build"        "06-macos-version.txt"         sw_vers
record_cmd      "Available software updates"     "07-softwareupdate-list.txt"   softwareupdate --list

# Keychain identities: certificate + private key pairs. Captured in both the
# general and the ssl-client scopes because the pair of counts is what tells
# them apart -- an ssl-client identity also appears in the general listing, so
# the two numbers are nested, not additive.
#
# This is the only managed component with no restore path other than
# re-issuance: an identity whose private key refuses export cannot be restored
# from a .p12, from Time Machine, or from a disk image. After an erase the
# count is therefore the only evidence that MDM re-issued what it should have.
# Package receipts. The pre-image managed inventory records expectations as
# receipt identifiers, so matching against these is exact where matching app
# names is not: `com.microsoft.package.Microsoft_Word.app` is unambiguous,
# "Microsoft Word" is not.
record_cmd      "Installed package receipts"     "10-package-receipts.txt"     pkgutil --pkgs

# Launch agents and daemons, as absolute paths. The company-scoped inventory
# records background components this way -- /Library/LaunchDaemons/com.x.y.plist
# -- and no other capture contains that form, so without this every launchd
# entry in the expectation set reads as absent.
record_pipeline "Launchd managed components"     "11-launchd-components.txt" \
  "ls -1 /Library/LaunchAgents/*.plist /Library/LaunchDaemons/*.plist \"$HOME\"/Library/LaunchAgents/*.plist 2>/dev/null | sort -u"

# System extensions. Endpoint security agents ship as these rather than as
# kexts, and the company-scoped inventory records them, so without this capture
# an activated extension reads as absent.
record_pipeline "System extensions"              "12-system-extensions.txt" \
  "systemextensionsctl list 2>/dev/null || echo 'systemextensionsctl unavailable'"

record_pipeline "Keychain identities"            "09-keychain-identities.txt" \
  "echo '## security find-identity -v'; security find-identity -v; echo; echo '## security find-identity -v -p ssl-client'; security find-identity -v -p ssl-client"

# ---------------------------------------------------------------------------
# Managed application expectations, derived from the pre-image capture
# ---------------------------------------------------------------------------
# Resolve the inventory directory: explicit override first, then the artifact
# root. Phase 8 often runs before the external volume is reconnected, so an
# absent source is an ordinary outcome rather than an error.
if [[ -z "$MANAGED_INVENTORY_DIR" && -n "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  if [[ -d "$REIMAGE_ARTIFACT_ROOT/managed-inventory" ]]; then
    MANAGED_INVENTORY_DIR="$REIMAGE_ARTIFACT_ROOT/managed-inventory"
  fi
fi

EXPECT_FILE="$RAW_DIR/08-managed-app-expectations.txt"
MANAGED_APPS_STATUS="TODO"
MANAGED_APPS_MISSING_COUNT="0"
MANAGED_APPS_EXPECTED_COUNT="0"
MANAGED_APPS_SOURCE="none"

# Pick the narrowest usable expectation source. The capture writes several files
# per run; only some of them describe COMPANY-managed software, and reading the
# wrong one produces a large, meaningless miss count rather than an error.
#
# 03-installed-app-bundles.txt is deliberately never used: it lists every
# application the pre-image Mac had, so comparing it at Phase 8 reports the whole
# un-restored application set. That belongs to Phase 13C, after Phase 12 has put
# the applications back.
EXPECT_SOURCE_FILE=""
if [[ -n "$MANAGED_INVENTORY_DIR" && -d "$MANAGED_INVENTORY_DIR" ]]; then
  for _candidate in \
    "$(find "$MANAGED_INVENTORY_DIR" -name '07-company-filter-pass.txt' 2>/dev/null | sort | tail -1)" \
    "$(find "$MANAGED_INVENTORY_DIR" -name '04-installed-package-receipts.txt' 2>/dev/null | sort | tail -1)"
  do
    if [[ -n "$_candidate" && -f "$_candidate" ]]; then
      EXPECT_SOURCE_FILE="$_candidate"
      MANAGED_APPS_SOURCE="$(basename "$_candidate")"
      break
    fi
  done
fi

echo "▶  Managed application expectations ..."

# Gate on the SOURCE FILE, not just the directory. A managed-inventory tree
# that exists but holds no company-scoped file is "could not check", and
# scoring it PASS on an empty expectation set is the same defect this row
# was written to avoid.
if [[ -z "$EXPECT_SOURCE_FILE" || ! -f "$EXPECT_SOURCE_FILE" ]]; then
  {
    echo "# Managed application expectations"
    echo "# Generated: $(date)"
    echo "# Source: unavailable"
    echo ""
    if [[ -z "$MANAGED_INVENTORY_DIR" ]]; then
      echo "No pre-image managed-inventory capture was reachable, so the installed"
      echo "application set could not be compared against what this Mac had before"
      echo "the erase. This is expected when Phase 8 runs before the external"
      echo "artifact volume is reconnected in Phase 9."
    else
      echo "A managed-inventory tree was found at:"
      echo ""
      echo "    $MANAGED_INVENTORY_DIR"
      echo ""
      echo "but it holds no company-scoped expectation file. Expected one of:"
      echo ""
      echo "    */07-company-filter-pass.txt"
      echo "    */04-installed-package-receipts.txt"
      echo ""
      echo "This row is left as TODO rather than PASS: an empty expectation set"
      echo "trivially matches, and reporting that as a pass would mean the check"
      echo "is loudest when it knows least."
    fi
    echo ""
    echo "To close this row, either rerun after reconnecting the drive:"
    echo ""
    echo "    ./bin/record-enrollment.sh --artifact-root \"\$REIMAGE_ARTIFACT_ROOT\""
    echo ""
    echo "or confirm the application set by hand against the Company Portal Apps"
    echo "tab and mark the row accordingly."
  } > "$EXPECT_FILE" 2>&1 || true
  echo "   • no managed-inventory source; row left as TODO"
else
  # Entries are one per line: package receipt identifiers, occasionally an app
  # name. Drop comments, section rules, and blanks; whatever is left is an
  # expectation. Parsing this way is format-agnostic, so a new section heading in
  # a later capture version does not silently change the result.
  EXPECTED_TMP="$RAW_DIR/.expected.$$"
  MISSING_TMP="$RAW_DIR/.missing.$$"
  HAYSTACK_TMP="$RAW_DIR/.haystack.$$"

  # Most sections list one identifier or one absolute path per line, but at least
  # one records command status lines verbatim -- for example
  #   * * X9E956P446 com.vendor.agent (1.0/2.0) Agent Name [activated enabled]
  # A whole line like that matches nothing, so it would always report as absent
  # while the software sits there activated. Reduce such lines to the
  # reverse-DNS identifier they contain; keep everything else as-is.
  #
  # The test for "is this a status line" is: it contains whitespace and does not
  # begin with a slash. Absolute paths keep their spaces, because bundle names
  # legitimately contain them.
  sed -e 's/[[:space:]]*$//' "$EXPECT_SOURCE_FILE" \
    | grep -v '^[[:space:]]*#' \
    | grep -v '^[[:space:]]*---' \
    | grep -v '^[[:space:]]*$' \
    | sed 's/^[[:space:]]*//' \
    | awk '
        /^\// { print; next }                       # absolute path: keep whole
        $0 !~ /[[:space:]]/ { print; next }         # bare identifier: keep whole
        {                                            # status line: pull out IDs
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z0-9_-]+){2,}$/) print $i
          }
        }' \
    | sort -uf > "$EXPECTED_TMP" || true

  # The company-scoped inventory is sectioned: package receipts, application
  # bundles, configuration profiles, background components, preference domains.
  # Matching all of those against receipts alone reports whole sections as
  # absent, so the haystack spans every capture that could contain any of them.
  cat "$RAW_DIR/10-package-receipts.txt" \
      "$RAW_DIR/11-launchd-components.txt" \
      "$RAW_DIR/12-system-extensions.txt" \
      "$RAW_DIR/04-managed-apps.txt" \
      "$RAW_DIR/02-profiles-list.txt" \
      "$RAW_DIR/05-managed-processes.txt" \
    > "$HAYSTACK_TMP" 2>/dev/null || true

  # Expectations arrive in two forms -- bare identifiers and absolute paths --
  # and the captures they must match against use whichever form is natural for
  # that command. `pkgutil` prints bare receipt IDs; `ls /Applications` prints
  # bare bundle names; the inventory records both of those as full paths. So a
  # miss on the literal string is retried against the basename before an entry
  # is called absent: /Applications/Microsoft Word.app is present on a Mac whose
  # application listing says "Microsoft Word.app".
  : > "$MISSING_TMP"
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    if grep -Fqi "$item" "$HAYSTACK_TMP" 2>/dev/null; then
      continue
    fi
    item_base="${item##*/}"
    if [[ "$item_base" != "$item" ]] && grep -Fqi "$item_base" "$HAYSTACK_TMP" 2>/dev/null; then
      continue
    fi
    printf '%s\n' "$item" >> "$MISSING_TMP"
  done < "$EXPECTED_TMP"

  # wc -l rather than `grep -c .`: grep exits 1 on an empty file while still
  # printing 0, so a `|| echo 0` fallback would append a second zero and the
  # count would read "0\n0". Every line here is written with a trailing
  # newline, so wc -l is exact.
  MANAGED_APPS_MISSING_COUNT="$(wc -l < "$MISSING_TMP" | tr -d '[:space:]')"
  MANAGED_APPS_EXPECTED_COUNT="$(wc -l < "$EXPECTED_TMP" | tr -d '[:space:]')"

  {
    echo "# Managed application expectations"
    echo "# Generated: $(date)"
    echo "# Source: $EXPECT_SOURCE_FILE"
    echo "# Source kind: $MANAGED_APPS_SOURCE"
    echo "# Expected bundles found in inventory: $MANAGED_APPS_EXPECTED_COUNT"
    echo "# Not present on this Mac: $MANAGED_APPS_MISSING_COUNT"
    echo ""
    echo "## Present pre-image, absent now"
    echo ""
    if [[ "$MANAGED_APPS_MISSING_COUNT" == "0" ]]; then
      echo "(none)"
    else
      cat "$MISSING_TMP"
      echo ""
      echo "READ THIS BEFORE ACTING ON THE LIST ABOVE."
      echo ""
      echo "Expectations come from the company-scoped inventory, so these are"
      echo "management-stack components rather than ordinary applications."
      echo "Two categories are absent for good reasons and are not findings:"
      echo ""
      echo "  - Components of a management stack this Mac no longer uses. A Mac"
      echo "    previously managed by a different tool carries its receipts;"
      echo "    re-enrolling into the current one will never bring them back, and"
      echo "    should not."
      echo "  - Agents that install later in the rollout. Required pushes are"
      echo "    asynchronous; rerun this record after the Step 7 restart before"
      echo "    treating anything here as missing."
      echo "  - Version-pinned receipts. An identifier carrying a version, such as"
      echo "    a vendor installer receipt, never matches once the vendor ships a"
      echo "    newer build -- the software is present, the receipt name moved."
      echo ""
      echo "Act on absences from the CURRENT stack -- security agents, Company"
      echo "Portal, the MDM agent. Install those from the Company Portal Apps tab,"
      echo "never from a vendor download."
    fi
    echo ""
    echo "## Expected set derived from inventory"
    echo ""
    cat "$EXPECTED_TMP"
  } > "$EXPECT_FILE" 2>&1 || true

  rm -f "$EXPECTED_TMP" "$MISSING_TMP" "$HAYSTACK_TMP"

  if [[ "$MANAGED_APPS_MISSING_COUNT" == "0" ]]; then
    MANAGED_APPS_STATUS="PASS"
  else
    MANAGED_APPS_STATUS="WARN"
  fi
fi
echo "   ✓ saved → raw/08-managed-app-expectations.txt"

# ---------------------------------------------------------------------------
# Heuristic verdicts for the command-verifiable exit-criteria rows
# ---------------------------------------------------------------------------
file_contains() {
  local file="$1"
  local pattern="$2"
  grep -Eiq "$pattern" "$file" 2>/dev/null
}

status_pass_warn() {
  # Print PASS when the heuristic is satisfied, WARN otherwise. WARN is not the
  # same as FAIL — it means the recorded evidence did not obviously match the
  # expected pattern and needs a human look before the row is signed off.
  if [[ "$1" == "true" ]]; then
    printf 'PASS'
  else
    printf 'WARN'
  fi
}

# Match the affirmative answer, not the label. `profiles status -type
# enrollment` always prints the literal strings "MDM enrollment:" and
# "Enrolled via DEP:", including when both answers are No, so a bare
# 'enrolled|yes|mdm' pattern reports PASS on an unenrolled Mac. Same pattern
# used by record-reimaged-system.sh.
ENROLLMENT_OK="false"
if file_contains "$RAW_DIR/01-enrollment-status.txt" 'MDM enrollment: Yes|Enrolled via DEP: Yes|User Approved'; then
  ENROLLMENT_OK="true"
fi

# A root-required refusal from `profiles list` is non-empty output that names
# no profiles; without these patterns it scored as PASS.
PROFILES_OK="false"
if [[ -s "$RAW_DIR/02-profiles-list.txt" ]] \
  && ! file_contains "$RAW_DIR/02-profiles-list.txt" 'there are no configuration profiles installed|no configuration profiles|error|requires root|require root|need to be root|must be root|root privileges|not permitted|permission denied'; then
  PROFILES_OK="true"
fi

CROWDSTRIKE_OK="false"
ZSCALER_OK="false"
if file_contains "$RAW_DIR/04-managed-apps.txt" 'crowdstrike|falcon' \
  || file_contains "$RAW_DIR/05-managed-processes.txt" 'crowdstrike|falcon'; then
  CROWDSTRIKE_OK="true"
fi
if file_contains "$RAW_DIR/04-managed-apps.txt" 'zscaler' \
  || file_contains "$RAW_DIR/05-managed-processes.txt" 'zscaler'; then
  ZSCALER_OK="true"
fi
SECURITY_OK="false"
if [[ "$CROWDSTRIKE_OK" == "true" && "$ZSCALER_OK" == "true" ]]; then
  SECURITY_OK="true"
fi

# FileVault was already captured but had no row of its own, so the answer lived
# only in the raw file. reimage-checklist.sh --phase post FAILs sign-off when
# FileVault is off, and this is the first phase that could have said so.
FILEVAULT_OK="false"
if file_contains "$RAW_DIR/03-filevault-status.txt" 'FileVault is On'; then
  FILEVAULT_OK="true"
fi

# Configuration profile count. `profiles list` prints a trailing summary line
# only when run with sufficient privilege; unprivileged it prints little and no
# total, so an empty count here means "not readable", not "no profiles".
PROFILE_COUNT="$(grep -oE 'There (are|is) [0-9]+' "$RAW_DIR/02-profiles-list.txt" 2>/dev/null \
  | grep -oE '[0-9]+' | head -1 || true)"
PROFILE_COUNT="${PROFILE_COUNT:-unknown}"

# Say which scope the number describes. A user-scope count is not comparable to
# a system-scope one and reporting them identically invites exactly the wrong
# conclusion.
# Detect scope from the OUTPUT, never from the marker. record_pipeline writes a
# "# Command: ..." header quoting the whole pipeline -- which contains the literal
# words "scope: system" -- so any marker string is present in the file whether or
# not that branch ran. `_computerlevel` appears only in genuine system-scope
# output and cannot be echoed by the command line itself.
PROFILE_SCOPE="user"
if grep -q '^_computerlevel' "$RAW_DIR/02-profiles-list.txt" 2>/dev/null; then
  PROFILE_SCOPE="system"
fi

# Say something different depending on which scope was obtained. A note that
# tells you to rerun with sudo, printed on a run that already had sudo, teaches
# the reader to skip the notes.
if [[ "$PROFILE_SCOPE" == "system" ]]; then
  PROFILE_NOTE="System scope: the managed baseline. This is the number to record and to compare against on a later run."
else
  PROFILE_NOTE="User scope only -- no cached sudo credential when this ran, so the count covers your own profiles rather than the managed baseline, which is normally several times larger. Run \`sudo -v\` and rerun to capture it. \`unknown\` means not readable, not none."
fi

# Keychain identity counts, parsed from the trailing summary of each listing
# rather than by counting numbered lines -- the file holds two listings, so
# counting entries would silently add them together. Singular and plural forms
# both appear depending on the count.
IDENTITY_TOTAL="$(grep -oE '[0-9]+ valid identit(y|ies) found' "$RAW_DIR/09-keychain-identities.txt" 2>/dev/null \
  | head -1 | grep -oE '^[0-9]+' || true)"
IDENTITY_SSL="$(grep -oE '[0-9]+ valid identit(y|ies) found' "$RAW_DIR/09-keychain-identities.txt" 2>/dev/null \
  | tail -1 | grep -oE '^[0-9]+' || true)"
IDENTITY_TOTAL="${IDENTITY_TOTAL:-unknown}"
IDENTITY_SSL="${IDENTITY_SSL:-unknown}"

# A machine with zero identities after enrollment has not finished re-issuing
# them. Any non-zero count is reported rather than judged: how many this Mac
# should have is a site fact the script cannot know.
IDENTITIES_OK="false"
if [[ "$IDENTITY_TOTAL" != "unknown" && "$IDENTITY_TOTAL" != "0" ]]; then
  IDENTITIES_OK="true"
fi

UPDATES_OK="false"
if file_contains "$RAW_DIR/07-softwareupdate-list.txt" 'No new software available'; then
  UPDATES_OK="true"
fi

POST_RESTART_OK="false"
if [[ "$ENROLLMENT_OK" == "true" && "$PROFILES_OK" == "true" && "$SECURITY_OK" == "true" ]]; then
  POST_RESTART_OK="true"
fi

# ---------------------------------------------------------------------------
# Generate the Markdown record with the Phase 8 exit-criteria table prefilled
# ---------------------------------------------------------------------------
REPORT_FILE="$OUT/record.md"

cat > "$REPORT_FILE" <<EOF
# Enrollment Record

Generated: $(date)
Script: $(basename "$0")
Context: ${CONTEXT_LABEL:-(none supplied)}
Output directory: $OUT

This is the Phase 8 evidence bundle for one side of the stabilization restart. It records what the machine reported, not whether the phase passed: the verdict is the exit checklist under \`reimaged-system/boundaries/\`, built by \`record-enrollment.sh --context exit\` from the official post-restart run. Keeping them apart means rerunning a capture never silently discards an answered row, and an answered row never has to be copied forward into a newer record. See \`enroll-and-stabilize.md\` for the full runbook.

## What This Run Observed

| Observation | Result | Evidence |
|---|---|---|
| Enrollment status | $(status_pass_warn "$ENROLLMENT_OK") | \`raw/01-enrollment-status.txt\` |
| Configuration profiles present | $(status_pass_warn "$PROFILES_OK") | \`raw/02-profiles-list.txt\` |
| Profile count | $PROFILE_COUNT ($PROFILE_SCOPE scope) | $PROFILE_NOTE |
| Security tooling installed or installing | $(status_pass_warn "$SECURITY_OK") | \`raw/04-managed-apps.txt\`, \`raw/05-managed-processes.txt\` |
| macOS updates | $(status_pass_warn "$UPDATES_OK") | \`raw/06-macos-version.txt\`, \`raw/07-softwareupdate-list.txt\` |
| Managed application set vs pre-image inventory | $MANAGED_APPS_STATUS | $MANAGED_APPS_MISSING_COUNT absent of $MANAGED_APPS_EXPECTED_COUNT expected, from \`$MANAGED_APPS_SOURCE\`. See \`raw/08-managed-app-expectations.txt\`. Components of a superseded management stack stay absent by design. |
| FileVault | $(status_pass_warn "$FILEVAULT_OK") | \`raw/03-filevault-status.txt\` |
| Keychain identities | $(status_pass_warn "$IDENTITIES_OK") | $IDENTITY_TOTAL valid, $IDENTITY_SSL ssl-client. See \`raw/09-keychain-identities.txt\`. Fingerprints differ from the pre-image set — MDM re-issues these rather than restoring them. |
| Post-restart health | $(status_pass_warn "$POST_RESTART_OK") | Meaningful only on a \`--context post-restart\` run. |

\`rows.tsv\` beside this file carries the same verdicts tab-separated, which is what the exit checklist reads rather than reparsing this table.

## Review While the Evidence Is Fresh

1. Open Company Portal and review the device state, including the **Apps** tab.
2. Review \`raw/08-managed-app-expectations.txt\` and install anything genuinely
   missing from the Company Portal **Apps** tab.
3. Compare the identity count against the pre-image record. Expect the same
   number and shape with different fingerprints.

Anything that needs a decision rather than a look is asked once, in the exit checklist.

## Raw Evidence Files

- \`raw/01-enrollment-status.txt\`
- \`raw/02-profiles-list.txt\`
- \`raw/03-filevault-status.txt\`
- \`raw/04-managed-apps.txt\`
- \`raw/05-managed-processes.txt\`
- \`raw/06-macos-version.txt\`
- \`raw/07-softwareupdate-list.txt\`
- \`raw/08-managed-app-expectations.txt\`
- \`raw/09-keychain-identities.txt\`
- \`raw/10-package-receipts.txt\`
- \`raw/11-launchd-components.txt\`
- \`raw/12-system-extensions.txt\`
EOF

# The verdicts, tab-separated, so the exit checklist reads a table rather than
# reparsing Markdown -- the same split comparison.md / rows.tsv already uses.
ROWS_FILE="$OUT/rows.tsv"
{
  printf 'check\tstatus\tdetail\n'
  printf 'enrollment\t%s\t%s\n'        "$(status_pass_warn "$ENROLLMENT_OK")" "raw/01-enrollment-status.txt"
  printf 'profiles\t%s\t%s\n'          "$(status_pass_warn "$PROFILES_OK")" "$PROFILE_COUNT profiles, $PROFILE_SCOPE scope"
  printf 'security-tools\t%s\t%s\n'    "$(status_pass_warn "$SECURITY_OK")" "raw/04-managed-apps.txt"
  printf 'macos-updates\t%s\t%s\n'     "$(status_pass_warn "$UPDATES_OK")" "raw/07-softwareupdate-list.txt"
  printf 'managed-apps\t%s\t%s\n'      "$MANAGED_APPS_STATUS" "$MANAGED_APPS_MISSING_COUNT absent of $MANAGED_APPS_EXPECTED_COUNT expected"
  printf 'filevault\t%s\t%s\n'         "$(status_pass_warn "$FILEVAULT_OK")" "raw/03-filevault-status.txt"
  printf 'keychain-identities\t%s\t%s\n' "$(status_pass_warn "$IDENTITIES_OK")" "$IDENTITY_TOTAL valid, $IDENTITY_SSL ssl-client"
  printf 'post-restart-health\t%s\t%s\n' "$(status_pass_warn "$POST_RESTART_OK")" "meaningful only on a post-restart run"
} > "$ROWS_FILE"

RUN_PASS="$(grep -c '	PASS	' "$ROWS_FILE" 2>/dev/null || true)"
RUN_WARN="$(grep -c '	WARN	' "$ROWS_FILE" 2>/dev/null || true)"

if ! artifact_run_finalize "$RUN_CATEGORY_ROOT" \
     "${RUN_PASS:-0} pass / ${RUN_WARN:-0} warn"; then
  echo "ERROR: the record was written but artifact-runs reported a problem indexing it — see above." >&2
  exit 2
fi
# finalize promotes the staging directory, so the paths must be re-derived.
OUT="$ARTIFACT_RUN_DIR"
REPORT_FILE="$OUT/record.md"

echo ""
echo "Enrollment record complete."
echo "Record → $REPORT_FILE"
echo "Run indexed at: $RUN_CATEGORY_ROOT/MANIFEST.md"

if [[ "$OPEN_RESULT" == "true" ]]; then
  open -R "$REPORT_FILE" 2>/dev/null || true
fi
