#!/usr/bin/env bash
# =============================================================================
# compare-restored-state.sh
#
# Compares what a restore phase was supposed to put on the machine against a
# baseline, and writes the classified difference as an indexed run.
#
# ONE baseline, on purpose. This compares the rebuilt machine against the
# captures taken before the erase -- the cross-erase question, "is this the
# machine that was erased". It probes live commands and greps the pre-image
# capture files.
#
# It used to carry a second baseline,, joining a phase's own
# before- and after-state recordings. That shared nothing with this machinery:
# no probes, no capture files, only two state.tsv files that
# record-restore-state.sh produces. It now lives there, emitted as delta.md
# beside the after-capture it describes. A tool that answered two unrelated
# questions through one flag was two tools wearing one name.
#
# WAS bin/compare-runtime-versions.sh, Phase 10A only. Renamed and moved when the
# same comparison was wanted for every restore phase: the old name promised a
# runtime-version diff and the old location promised a phase command, and neither
# was true once restore-access and restore-apps needed it. Per
# `.github/guides/script-types-and-locations.md`, a helper that several phases
# share stays in `.internal/` even though a runbook names it -- the same carve-out
# that keeps the boundary recorders there.
#
# Runbook/phase context: restore-runtime.md (Phase 10A) Step 10, and the
# equivalent step in each later restore runbook. The step it replaced listed
# fourteen version commands to run and eyeball against sixteen captured
# inventory files. Eyeballing finds the tool that changed version; it reliably
# misses the tool that is simply absent, because nothing prints when nothing is
# installed.
#
# WHAT IT JUDGES, AND WHAT IT DOES NOT. An approved-newer version is a normal
# outcome of a rebuild and is reported as INFO, not as a problem. A tool that
# was present pre-image and is missing now is the finding worth surfacing, and
# it is the one a human scanning terminal output is least likely to notice.
# Version-string formats vary too much between tools to compare semantically,
# so this reports what each side says and flags only presence and difference.
#
# This is an aggregate validator: every probe becomes a row rather than
# aborting the run, so one pass produces the whole picture.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#
#   # Compare the rebuilt runtime layer to the pre-image inventory.
#   bash bin/compare-restored-state.sh --runbook restore-runtime
#
#   # Read it without writing anything.
#   bash bin/compare-restored-state.sh --runbook restore-runtime --dry-run
#
#   # Against a specific captured inventory rather than the newest.
#   bash bin/compare-restored-state.sh --runbook restore-runtime \
#     --inventory pre-image-20260816-211456
#
# Options:
#   --runbook NAME        Which phase to compare. Required.
#                         Supported: restore-runtime, restore-access
#   --inventory NAME      Named inventory bundle under system-inventory/.
#                         Default: the newest pre-image-* bundle.
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT.
#   --output-root PATH    Category root for the run. A destination inside the repo
#                         checkout is refused.
#                         Default: <artifact-root>/reimaged-system/comparisons
#   --reprobe             Do not compare or write. Re-run this phase's probes
#                         NOW and diff them against the `live` column already
#                         recorded in the official comparison run, answering
#                         "does that comparison still describe this machine".
#                         See FRESHNESS below.
#   --dry-run             Print the comparison; write nothing.
#   --open                Reveal the generated run in Finder.
#   -h, --help            Show this message and exit.
#
# Output:
#   <artifact-root>/reimaged-system/comparisons/runs/<runbook>-inventory-diff-<stamp>/
#     comparison.md   the rendered note
#     rows.tsv        the joined rows, so a later comparison need not reparse Markdown
#   indexed in that category\'s MANIFEST.md, with official/ naming the newest run.
#
# Exit status:
#   0  Comparison written or printed.
#   2  Usage, configuration, or prerequisite error.
#
# Note it does NOT exit non-zero on a MISSING row. A missing tool is a finding to
# read, not a failure of the comparison, and the boundary recorders are what turn
# findings into a phase verdict.
#
# FRESHNESS (`--reprobe`)
#
# A phase's exit checklist cites a comparison, and until now it only checked that
# one EXISTED. That is not the same question. On this repo a nine-pass sign-off
# cited a comparison recording Node `v24.19.0` against a `v26.0.0` baseline --
# the regression -- while the machine had already been fixed to `v26.7.0`. The
# row was green because a file was present.
#
# Time cannot answer it. The stale comparison was four minutes older than the
# checklist that cited it, well inside any sane age window, and a comparison
# being older than its exit checklist is the NORMAL ordering. What actually went
# stale was the content: the comparison stopped describing the machine.
#
# So `--reprobe` re-runs the probes now and diffs them against what the official
# run recorded. It deliberately uses THIS script's own probe table rather than
# re-executing commands stored in the run, for two reasons: the probe set lives
# in exactly one place, and nothing here evaluates a shell command read out of a
# file on the artifact drive.
#
# A label present in the run but no longer in the probe table is reported rather
# than dropped -- the comparison covered something this script no longer checks,
# which is a real difference and not a match.
#
# Exit status is 0 for no drift, 1 for drift, 2 when the question cannot be
# asked -- no official run, or a run with no `rows.tsv`. The caller is expected
# to treat 2 as "ask a human", not as "fine".
# --- END USAGE ---
# =============================================================================

set -uo pipefail
# Deliberately not -e: every probe below is allowed to fail. A tool that is not
# installed is the single most interesting row this script produces, and -e
# would abort on the first one.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# One level up: this entrypoint sits in bin/, so the repo root is the parent.
# It previously sat at .internal/restore/ and climbed two. Moving a script
# between those depths without changing this line is what broke
# record-restore-exit.sh the last time it changed directories.
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"

if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi

ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../../.internal/artifact-runs.sh
source "$RUNS_LIB"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

# Phases are added as their runbooks are reached, the same way the boundary
# recorders do it, so each probe set is written against a runbook someone has
# actually just followed rather than all of them guessed at once.
resolve_runbook() {
  case "$1" in
    restore-runtime) PHASE_RUNBOOK="restore-runtime.md" ;;
    restore-access)  PHASE_RUNBOOK="restore-access.md" ;;
    restore-git)     PHASE_RUNBOOK="restore-git.md" ;;
    *) echo "ERROR: no probe set defined for runbook: $1" >&2
       echo "HINT:  supported runbooks: restore-runtime, restore-access." >&2
       return 2 ;;
  esac
  return 0
}

require_option_value() {
  if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
    echo "ERROR: $1 requires a non-empty value." >&2
    exit 2
  fi
}

STAMP="$(date +%Y%m%d-%H%M%S)"
INVENTORY_NAME=""
OUTPUT_ROOT=""
DRY_RUN=false
OPEN_RESULT=false
REPROBE=false
RUNBOOK=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runbook)  require_option_value "$1" "${2:-}"; RUNBOOK="${2%.md}"; shift 2; continue ;;
    --reprobe)  REPROBE=true; shift; continue ;;
    --artifact-root) require_option_value "$1" "${2:-}"; REIMAGE_ARTIFACT_ROOT="$2"; shift 2 ;;
    --inventory)     require_option_value "$1" "${2:-}"; INVENTORY_NAME="$2"; shift 2 ;;
    --output-root)   require_option_value "$1" "${2:-}"; OUTPUT_ROOT="$2"; shift 2 ;;
    --dry-run)       DRY_RUN=true; shift ;;
    --open)          OPEN_RESULT=true; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

absolute_path() {
  local input="$1" resolved="" rest segment
  case "$input" in /*) ;; *) input="$PWD/$input" ;; esac
  rest="$input"
  while [[ -n "$rest" ]]; do
    segment="${rest%%/*}"
    if [[ "$segment" == "$rest" ]]; then rest=""; else rest="${rest#*/}"; fi
    case "$segment" in
      ''|.) ;;
      ..) resolved="${resolved%/*}" ;;
      *) resolved="$resolved/$segment" ;;
    esac
  done
  printf '%s' "${resolved:-/}"
}

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" || ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set or not a directory. Reconnect the artifact volume, source reimage.env, or pass --artifact-root PATH." >&2
  exit 2
fi

INVENTORY_PARENT="$REIMAGE_ARTIFACT_ROOT/system-inventory"

# Newest pre-image bundle by trailing stamp. Bundle names carry a phase prefix
# (pre-image-, post-image-), so a plain lexical sort over a mixed set would rank
# by phase before date; restricting the glob to one phase makes sorting safe.
if [[ -z "${RUNBOOK:-}" ]]; then
  echo "ERROR: --runbook is required. Supported: restore-runtime, restore-access" >&2
  usage >&2
  exit 2
fi
resolve_runbook "$RUNBOOK" || exit 2

if [[ -z "$INVENTORY_NAME" ]]; then
  INVENTORY_DIR="$(find "$INVENTORY_PARENT" -maxdepth 1 -type d -name 'pre-image-*' 2>/dev/null | sort | tail -1)"
else
  INVENTORY_DIR="$INVENTORY_PARENT/$INVENTORY_NAME"
fi

if [[ -z "$INVENTORY_DIR" || ! -d "$INVENTORY_DIR" ]]; then
  echo "ERROR: no pre-image system inventory found under $INVENTORY_PARENT" >&2
  echo "HINT:  \`capture-system-inventory\` (capture-system-inventory) writes it before the erase." >&2
  echo "HINT:  List what is available:  ls -1 \"$INVENTORY_PARENT\"" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Capture sources
#
# The pre-image system inventory is not the only thing captured before the
# erase, and a phase should compare against whatever capture actually covers
# what it rebuilt. A probe names its source with a `root:glob` spec; a bare
# filename means the system inventory, which is what every 10A probe uses.
#
#   inventory:10-java.txt   system-inventory/pre-image-*/
#   managed:02-profiles-*   managed-inventory/pre-image-*/
#   secrets:java-jssecacerts-inventory-*.md
#                           secrets-encrypted/   (readable without the DMG
#                           password -- these are the manifests beside the
#                           image, not its contents)
#
# Resolution is by glob and takes the newest match, so a spec survives the
# timestamp in a capture directory name.
# ---------------------------------------------------------------------------
MANAGED_PARENT="$REIMAGE_ARTIFACT_ROOT/managed-inventory"
SECRETS_PARENT="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"

MANAGED_DIR="$(find "$MANAGED_PARENT" -maxdepth 1 -type d -name 'pre-image-*' 2>/dev/null | sort | tail -1)"

capture_file() {
  # $1 = spec. Prints an absolute path, or nothing when unresolved.
  local spec="$1" root rel base match
  case "$spec" in
    inventory:*) root="$INVENTORY_DIR"; rel="${spec#inventory:}" ;;
    managed:*)   root="$MANAGED_DIR";   rel="${spec#managed:}"   ;;
    secrets:*)   root="$SECRETS_PARENT"; rel="${spec#secrets:}"  ;;
    *)           root="$INVENTORY_DIR"; rel="$spec" ;;
  esac
  [[ -n "$root" && -d "$root" ]] || return 1
  match=""
  for base in "$root"/$rel; do
    [[ -f "$base" ]] && match="$base"
  done
  [[ -n "$match" ]] || return 1
  printf '%s' "$match"
}

# ---------------------------------------------------------------------------
# Probe table
#
# label | live command | inventory file | grep anchor
#
# The anchor is what identifies the tool's line inside the captured file; the
# capture files hold the raw output of many commands, so a bare version number
# would match the wrong line.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Probes
#
# The pre-image capture records two different kinds of fact, and comparing them
# the same way produces noise. 06-homebrew.txt is a package LIST -- bare names,
# no versions -- so for most formulae the only honest question is "was it
# installed then, and is it installed now". Files like 10-java.txt and
# 12-docker.txt do carry versions, and those can be compared properly.
#
# Asking for a version where only a name was recorded yields "no baseline" on
# every row, which reads as a gap in the capture rather than a category
# difference, and trains the reader to skim the column.
# ---------------------------------------------------------------------------

live_first_line() {
  local out
  out="$(eval "$1" 2>&1 | head -1 | tr -d '\r')"
  case "$out" in
    *"command not found"*|*"No such file"*|'') printf 'MISSING' ;;
    *) printf '%s' "$out" ;;
  esac
}

# Captured values can themselves contain tabs, and one does: the Phase 4B
# capture records `ProductVersion:<TAB>26.6.2` in 02-macos.txt, so carrying a
# recorded value straight into a tab-delimited row splits it across two fields.
# A consumer reading field 4 gets `ProductVersion:` instead of the version. The
# rendered comparison.md survived this because Markdown does not care; rows.tsv,
# added specifically for machine consumption, did not.
squash_ws() {
  printf '%s' "$1" | tr '\t\n\r' '   ' | sed 's/  */ /g; s/^ //; s/ $//'
}

# Emits: <kind>\t<label>\t<live>\t<recorded>
probe_version() {
  local label="$1" live_cmd="$2" inv_file="$3" anchor="$4"
  local live inv=""
  local src; src="$(capture_file "$inv_file" || true)"
  live="$(live_first_line "$live_cmd")"
  if [[ -n "$src" ]]; then
    inv="$(grep -iE "$anchor" "$src" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//')"
  fi
  [[ -n "$inv" ]] || inv="not recorded"
  printf 'version\t%s\t%s\t%s\n' "$label" "$(squash_ws "$live")" "$(squash_ws "$inv")"
}

# For tools the capture lists by name only. Compares presence, not version.
probe_presence() {
  local label="$1" live_cmd="$2" inv_file="$3" anchor="$4"
  local live inv="absent"
  local src; src="$(capture_file "$inv_file" || true)"
  live="$(live_first_line "$live_cmd")"
  if [[ -n "$src" ]] && grep -qiE "$anchor" "$src" 2>/dev/null; then
    inv="recorded"
  fi
  printf 'presence\t%s\t%s\t%s\n' "$label" "$(squash_ws "$live")" "$(squash_ws "$inv")"
}

# For tools a LATER phase installs. Absence now is the expected state, not a
# finding -- the same reasoning that makes Git and Homebrew INFO rather than
# TODO in the Phase 9 first-boot checklist.
# An exact-value comparison. probe_version exists because tool versions are
# written differently on each side and only the number matters; a config value
# is the opposite -- `osxkeychain` is either what was recorded or it is not.
probe_value() {
  # $5 is optional: the runbook that owns this value when it is not here yet.
  # Without it a value Phase 11A has not restored counts as a Phase 10B gap and
  # the summary tells the operator to resolve it before closing out 10B --
  # advice that cannot be followed, because the phase that sets it has not run.
  local label="$1" live_cmd="$2" spec="$3" anchor="$4" owner="${5:-}"
  local live rec="" src
  src="$(capture_file "$spec" || true)"
  live="$(live_first_line "$live_cmd")"
  if [[ -n "$src" ]]; then
    rec="$(grep -iE "$anchor" "$src" 2>/dev/null | head -1 | sed 's/^.*=//; s/^[[:space:]]*//')"
  fi
  [[ -n "$rec" ]] || rec="not recorded"
  if [[ -n "$owner" && "$live" == "MISSING" ]]; then
    printf 'owned\t%s\t%s\t%s\n' "$label" "not set yet" \
      "$(squash_ws "recorded $rec — $owner owns it")"
    return
  fi
  printf 'value\t%s\t%s\t%s\n' "$label" "$(squash_ws "$live")" "$(squash_ws "$rec")"
}

# Some pre-image state must NOT come back. `http.sslverify=false` is the case
# that motivated this: it is recorded in the capture, it is in the dotfiles
# backup, and carrying it forward silently disables TLS verification for every
# Git HTTPS remote. A same/differs verdict would mark the CORRECT outcome as a
# difference, which is how a comparison trains its reader to ignore it.
probe_absent() {
  local label="$1" live_cmd="$2" spec="$3" anchor="$4"
  local live rec="not recorded" src
  src="$(capture_file "$spec" || true)"
  live="$(live_first_line "$live_cmd")"
  if [[ -n "$src" ]] && grep -qiE "$anchor" "$src" 2>/dev/null; then
    rec="recorded pre-image"
  fi
  printf 'absent\t%s\t%s\t%s\n' "$label" "$(squash_ws "$live")" "$(squash_ws "$rec")"
}

# A byte-exact check. The capture records a SHA-256 next to a label; this
# hashes the live file and asks whether the recorded hash appears. Stronger
# than any version string, and the only honest way to say a restored binary
# file is the file that was captured.
probe_hash() {
  local label="$1" live_path="$2" spec="$3" anchor="$4"
  local live="MISSING" rec="not recorded" src line
  if [[ -f "$live_path" ]]; then
    live="$(shasum -a 256 "$live_path" 2>/dev/null | awk '{print $1}')"
    [[ -n "$live" ]] || live="unreadable"
  fi
  src="$(capture_file "$spec" || true)"
  if [[ -n "$src" ]]; then
    line="$(grep -iE "$anchor" "$src" 2>/dev/null | head -1)"
    if [[ -n "$line" ]]; then
      rec="$(printf '%s' "$line" | grep -oE '[0-9a-f]{64}' | head -1)"
      [[ -n "$rec" ]] || rec="no hash on that row"
    fi
  fi
  printf 'hash\t%s\t%s\t%s\n' "$label" "$live" "$rec"
}

probe_later() {
  local label="$1" live_cmd="$2" phase="$3"
  printf 'later\t%s\t%s\t%s\n' "$label" "$(squash_ws "$(live_first_line "$live_cmd")")" "$phase"
}

collect() {
  case "$RUNBOOK" in
    restore-runtime) collect_restore_runtime ;;
    restore-access)  collect_restore_access ;;
    restore-git)     collect_restore_git ;;
  esac
}

collect_restore_runtime() {
  # --- versions actually recorded in the capture --------------------------
  probe_version  "macOS"     "sw_vers -productVersion"     "02-macos.txt"    'ProductVersion|^[0-9]+\.'
  probe_version  "Homebrew"  "brew --version"              "06-homebrew.txt" 'Homebrew [0-9]'
  probe_version  "Java"      "java -version 2>&1"          "10-java.txt"     'version "|openjdk'
  probe_version  "Gradle"    "gradle --version 2>/dev/null | grep -i '^Gradle'" "10-java.txt" '^Gradle [0-9]'
  probe_version  "Groovy"    "groovy --version 2>/dev/null" "10-java.txt"    '^Groovy:[[:space:]]+[0-9]'
  probe_version  "Node"      "node --version"              "11-node.txt"     '^v[0-9]+\.'
  probe_version  "npm"       "npm --version"               "11-node.txt"     'npm@[0-9]|npm .*[0-9]+\.'
  probe_version  "Python 3"  "python3 --version 2>&1"      "09-python.txt"   'Python 3'

  # --- recorded by name only: presence is the only honest comparison ------
  probe_presence "Git"       "git --version"               "06-homebrew.txt" '^git$'
  probe_presence "Maven"     "mvn --version 2>/dev/null"   "06-homebrew.txt" '^maven$'
  probe_presence "jq"        "jq --version"                "06-homebrew.txt" '^jq$'
  probe_presence "yq"        "yq --version"                "06-homebrew.txt" '^yq$'
  probe_presence "direnv"    "direnv --version"            "06-homebrew.txt" '^direnv$'
  probe_presence "cf CLI"    "cf --version"                "06-homebrew.txt" '^cf-cli'

  # --- installed by a later phase -----------------------------------------
  probe_later    "Docker"    "docker --version"            "restore-docker"
}

# ---------------------------------------------------------------------------
# Phase 10B -- restore-access
#
# What this phase rebuilds is trust and identity, not tool versions, so almost
# none of it is a probe_version. The captures that cover it are spread across
# three roots: the system inventory recorded the Git and shell configuration,
# the managed inventory recorded which CA profiles enrollment pushed, and the
# jssecacerts manifest beside the encrypted image recorded a SHA-256 per JDK.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Phase 11A -- restore-git
#
# This is where the `http.sslverify` row finally means something. Under
# restore-access it passes because `~/.gitconfig` does not exist yet: nothing was
# reviewed and dropped, it was never restored. This phase writes that file, so a
# `correctly dropped` here is the real verdict and a `**CARRIED FORWARD**` is a
# regression to act on.
# ---------------------------------------------------------------------------
collect_restore_git() {
  # Presence, not value. The capture holds TWO user.email lines -- this is a
  # dual-identity setup -- so a value comparison would compare the live global
  # address against whichever of the two the anchor matched first, and report a
  # confident mismatch on a correctly configured machine. Which identity applies
  # where is what Step 7 validates.
  probe_presence "Git identity email set" \
    "git config --global user.email" \
    "inventory:08-git.txt" 'user\.email=.*@'
  probe_value  "Git credential.helper" \
    "git config --global credential.helper" \
    "inventory:08-git.txt" 'credential\.helper='
  probe_value  "Git init.defaultBranch" \
    "git config --global init.defaultBranch" \
    "inventory:08-git.txt" 'init\.defaultbranch='

  probe_absent "Git http.sslverify" \
    "git config --global --get http.sslverify" \
    "inventory:08-git.txt" 'http\.sslverify[[:space:]]*=[[:space:]]*false'

  # The dual-identity routing is the whole point of the phase: one global config
  # with an includeIf that switches identity by repository root. Presence of the
  # directive is checkable; whether it routes correctly is Step 7's job.
  probe_presence "Dual-identity includeIf present" \
    "git config --global --get-regexp '^includeif' | head -1" \
    "inventory:08-git.txt" 'includeif'

  probe_presence "SSH host aliases configured" \
    "grep -ciE '^[[:space:]]*Host[[:space:]]' \"$HOME/.ssh/config\" 2>/dev/null" \
    "inventory:08-git.txt" 'user\.name='
}

collect_restore_access() {
  # --- Java trust: byte-exact, per installed JDK --------------------------
  # Walks what is installed now rather than what was installed then: a JDK
  # added since the capture has no recorded hash, and saying so is the finding.
  local jdk name
  for jdk in /Library/Java/JavaVirtualMachines/*.jdk; do
    [[ -d "$jdk" ]] || continue
    name="$(basename "$jdk")"
    probe_hash "jssecacerts ($name)" \
      "$jdk/Contents/Home/lib/security/jssecacerts" \
      "secrets:java-jssecacerts-inventory-*.md" \
      "^\\| .$name."
  done

  # --- Git configuration --------------------------------------------------
  probe_value  "Git credential.helper" \
    "git config --global credential.helper" \
    "inventory:08-git.txt" 'credential\.helper=' \
    "restore-git.md"
  probe_value  "Git init.defaultBranch" \
    "git config --global init.defaultBranch" \
    "inventory:08-git.txt" 'init\.defaultbranch=' \
    "restore-git.md"

  # Recorded pre-image and deliberately not restored -- see probe_absent.
  probe_absent "Git http.sslverify" \
    "git config --global --get http.sslverify" \
    "inventory:08-git.txt" 'http\.sslverify[[:space:]]*=[[:space:]]*false'

  # --- Shell ---------------------------------------------------------------
  probe_value  "Login shell" "echo \"\$SHELL\"" \
    "inventory:07-shell.txt" '^/(bin|opt|usr)/.*sh$'

  # --- Trust ---------------------------------------------------------------
  # Enrollment pushes the corporate root through a configuration profile, so the
  # managed inventory is the record of what SHOULD be trusted. The live side
  # asks the trust store rather than the keychain file list, because a
  # certificate being present is not the same as it being trusted.
  probe_presence "Corporate root trusted" \
    "security dump-trust-settings -d 2>/dev/null | head -1" \
    "managed:02-profiles-configuration.txt" 'Credential Profile for installing root certificate'

  probe_presence "CA bundle for non-keychain tools" \
    "grep -c 'BEGIN CERTIFICATE' \"\$HOME/.certs/system-and-corp-roots.pem\" 2>/dev/null" \
    "managed:02-profiles-configuration.txt" 'Credential Profile for installing root certificate'
}

RESULTS="$(collect)"

# ---------------------------------------------------------------------------
# Freshness mode
# ---------------------------------------------------------------------------
if [[ "$REPROBE" == "true" ]]; then
  RP_ROOT="${OUTPUT_ROOT:-$REIMAGE_ARTIFACT_ROOT/reimaged-system/comparisons}"
  # Freshness re-probes live tools against a recorded comparison, which only the
  # inventory lineage holds. A phase-delta joins two recordings and has no live
  # side to go stale.
  RP_CONTEXT="${PHASE_RUNBOOK%.md}-inventory-diff"
  RP_RUN="$(artifact_run_official "$RP_ROOT" "$RP_CONTEXT" 2>/dev/null)"

  if [[ -z "$RP_RUN" ]]; then
    echo "ERROR: no official comparison run for '$RP_CONTEXT' under $RP_ROOT" >&2
    echo "HINT:  run this script without --reprobe first." >&2
    exit 2
  fi
  RP_ROWS="$RP_ROOT/$RP_RUN/rows.tsv"
  if [[ ! -f "$RP_ROWS" ]]; then
    echo "ERROR: the official run has no rows.tsv: $RP_RUN" >&2
    echo "HINT:  it predates machine-readable rows. Freshness cannot be computed;" >&2
    echo "HINT:  confirm by eye that the comparison still describes this machine." >&2
    exit 2
  fi

  rp_drift=0; rp_same=0; rp_gone=0
  printf '# Freshness of %s\n' "$RP_RUN"
  printf '# Re-probed %s\n\n' "$(date)"
  printf '| Tool | Recorded then | Live now | Verdict |\n| --- | --- | --- | --- |\n'
  while IFS=$'\t' read -r rp_kind rp_label rp_then _rp_rec; do
    [[ -n "$rp_label" ]] || continue
    rp_now="$(printf '%s\n' "$RESULTS" | awk -F'\t' -v l="$rp_label" '$2 == l { print $3; exit }')"
    if [[ -z "$rp_now" ]]; then
      rp_gone=$(( rp_gone + 1 ))
      printf '| %s | `%s` | — | **no longer probed** |\n' "$rp_label" "$rp_then"
    elif [[ "$rp_now" == "$rp_then" ]]; then
      rp_same=$(( rp_same + 1 ))
      printf '| %s | `%s` | `%s` | same |\n' "$rp_label" "$rp_then" "$rp_now"
    else
      rp_drift=$(( rp_drift + 1 ))
      printf '| %s | `%s` | `%s` | **DRIFTED** |\n' "$rp_label" "$rp_then" "$rp_now"
    fi
  done < "$RP_ROWS"

  printf '\n**%s same · %s drifted · %s no longer probed**\n' "$rp_same" "$rp_drift" "$rp_gone"
  if (( rp_drift > 0 || rp_gone > 0 )); then
    printf '\nThe comparison no longer describes this machine. Rerun it before citing it in a sign-off.\n'
    exit 1
  fi
  printf '\nThe comparison still describes this machine.\n'
  exit 0
fi

# ---------------------------------------------------------------------------
# Verdicts
# ---------------------------------------------------------------------------
missing_count=0
changed_count=0
match_count=0
unrecorded_count=0

version_token() {
  printf '%s' "$1" | grep -oE '[0-9]+(\.[0-9]+)+' | head -1
}

# Compare on the version NUMBER, display the raw strings. The two sides come
# from different commands and label their output differently -- `npm --version`
# prints "11.17.0" while the inventory recorded "npm@11.16.0". Comparing raw
# text makes every such pair read "differs", which trains the reader to ignore
# the only column that matters.
verdict_for() {
  local kind="$1" live="$2" rec="$3" lv iv
  case "$kind" in
    later)
      if [[ "$live" == "MISSING" ]]; then printf 'expected later'; else printf 'present early'; fi
      return ;;
    hash)
      if   [[ "$live" == "MISSING" ]]; then printf '**MISSING**'
      elif [[ "$live" == "unreadable" ]]; then printf '**unreadable**'
      elif [[ "$rec" == "not recorded" ]]; then printf 'no baseline'
      elif [[ "$rec" == "no hash on that row" ]]; then printf 'no baseline'
      elif [[ "$live" == "$rec" ]]; then printf 'identical'
      else printf '**differs**'; fi
      return ;;
    owned)
      printf 'expected later'
      return ;;
    value)
      if   [[ "$live" == "MISSING" && "$rec" != "not recorded" ]]; then printf '**MISSING**'
      elif [[ "$live" == "MISSING" ]]; then printf 'unset both'
      elif [[ "$rec" == "not recorded" ]]; then printf 'no baseline'
      elif [[ "$live" == "$rec" ]]; then printf 'same'
      else printf 'differs'; fi
      return ;;
    absent)
      # Inverted on purpose: MISSING on the live side is the PASS.
      if   [[ "$rec" == "not recorded" ]]; then printf 'n/a'
      elif [[ "$live" == "MISSING" ]]; then printf 'correctly dropped'
      else printf '**CARRIED FORWARD**'; fi
      return ;;
    presence)
      if [[ "$live" == "MISSING" && "$rec" == "recorded" ]]; then printf '**MISSING**'
      elif [[ "$live" == "MISSING" ]]; then printf 'absent both'
      elif [[ "$rec" == "recorded" ]]; then printf 'present'
      else printf 'new'; fi
      return ;;
  esac

  if [[ "$live" == "MISSING" && "$rec" != "not recorded" ]]; then
    printf '**MISSING**'; return
  elif [[ "$live" == "MISSING" ]]; then
    printf 'absent both'; return
  elif [[ "$rec" == "not recorded" ]]; then
    printf 'no baseline'; return
  fi
  lv="$(version_token "$live")"
  iv="$(version_token "$rec")"
  if [[ -n "$lv" && -n "$iv" && "$lv" == "$iv" ]]; then printf 'same'
  elif [[ "$live" == "$rec" ]]; then printf 'same'
  else printf 'differs'; fi
}

# Which verdicts this run actually produced. The legend is gated on this: a
# static list of every possible verdict reads as instructions, and an operator
# whose row said `correctly dropped` twice acted on the `**CARRIED FORWARD**`
# line because it was sitting there under a heading that looked like findings.
# Explain what happened, not what could have.
verdicts_seen() {
  while IFS=$'\t' read -r kind label live rec; do
    [[ -z "$label" ]] && continue
    verdict_for "$kind" "$live" "$rec"
    printf '\n'
  done <<< "$RESULTS" | sort -u
}

saw() {
  printf '%s\n' "$VERDICTS_SEEN" | grep -qxF "$1"
}

# ---------------------------------------------------------------------------
# Recorded decisions
#
# A comparison that keeps reporting a difference someone already accepted trains
# the reader to skim it, and skimming is how the one real finding gets missed.
# `bin/record-decision.sh` writes the other half of that ledger -- an expired SSH
# key deleted on purpose, against an immutable image that legitimately still
# holds it. This reads it back, so an accepted difference says so in its own row
# instead of waiting to be asked.
#
# Two shapes of reference are honoured. `--excepts <lineage>` explains the
# comparison as a whole and is listed under its own heading; `--excepts
# <lineage>:<label>` names one row and marks it. The label must match the row
# exactly -- an approximate match would quietly excuse the wrong row, which is
# strictly worse than excusing none.
#
# A missing or unreadable log is not an error. Decisions are optional, and a
# comparison that refused to run without one would be worse than the problem.
# ---------------------------------------------------------------------------
DECIDED_LABELS=""
DECISION_ENTRIES=""

load_decisions() {
  local log="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/reimaged-system/restore-notes/decisions.md"
  [[ -f "$log" ]] || return 0

  DECISION_ENTRIES="$(awk -v ctx="$RUN_CONTEXT" '
    /^## / { heading = substr($0, 4) }
    /^- \*\*Excepts:\*\*/ { if (index($0, ctx) > 0 && heading != "") print heading }
  ' "$log" 2>/dev/null || true)"

  # Refs are rendered as `code spans`, so odd-indexed backtick fields are the
  # references themselves and even-indexed ones are the separators between them.
  DECIDED_LABELS="$(awk -v ctx="$RUN_CONTEXT" '
    /^- \*\*Excepts:\*\*/ {
      n = split($0, part, "`")
      for (i = 2; i <= n; i += 2) {
        ref = part[i]
        c = index(ref, ":")
        if (c > 0 && substr(ref, 1, c - 1) == ctx) print substr(ref, c + 1)
      }
    }
  ' "$log" 2>/dev/null || true)"
  return 0
}

row_is_decided() {
  [[ -n "$DECIDED_LABELS" ]] || return 1
  printf '%s\n' "$DECIDED_LABELS" | grep -qxF -- "$1"
}

render_rows() {
  local shown verdict
  while IFS=$'\t' read -r kind label live rec; do
    [[ -z "$label" ]] && continue
    # Presentation only. The verdict reads the raw value, because MISSING is the
    # sentinel every probe emits and rewriting it in the data made an inverted
    # row report **CARRIED FORWARD** on a machine where the value was absent --
    # a false alarm in the worst direction.
    shown="$live"
    if [[ "$kind" == "absent" && "$live" == "MISSING" ]]; then shown="not set"; fi
    verdict="$(verdict_for "$kind" "$live" "$rec")"
    # The marker is appended, never substituted. The verdict still says what the
    # machine reports -- the row IS missing -- and `decided` only says someone
    # already answered for it. Replacing the verdict would hide a finding behind
    # a decision that may have been made about a different run.
    if row_is_decided "$label"; then
      verdict="$verdict — **decided**"
    fi
    printf '| %s | `%s` | `%s` | %s |\n' "$label" "$shown" "$rec" "$verdict"
  done <<< "$RESULTS"
}

# Counted by the same function that renders, so the summary cannot disagree
# with the table beneath it.
count_verdicts() {
  while IFS=$'\t' read -r kind label live rec; do
    [[ -z "$label" ]] && continue
    # Every verdict string this script can emit is bucketed explicitly. The
    # default arm is a catch-all, and a new verdict falling into it silently
    # counted 29 'unchanged' rows as changes -- a summary that disagreed with
    # the table underneath it.
    case "$(verdict_for "$kind" "$live" "$rec")" in
      '**MISSING**'|'**removed**')
                                        missing_count=$(( missing_count + 1 )) ;;
      'same'|'present'|'unchanged'|'identical'|'correctly dropped')
                                        match_count=$(( match_count + 1 )) ;;
      'no baseline'|'absent both'|'new'|'expected later'|'present early'|'unset both'|'n/a'|'**unreadable**'|'owned')
                                        unrecorded_count=$(( unrecorded_count + 1 )) ;;
      'differs'|'**differs**'|'added'|'content changed'|'mode changed'|'changed'|'**CARRIED FORWARD**')
                                        changed_count=$(( changed_count + 1 )) ;;
      *)                                changed_count=$(( changed_count + 1 )) ;;
    esac
  done <<< "$RESULTS"
}
count_verdicts

# After verdict_for and verdicts_seen exist: a function definition takes effect
# when its definition runs, so computing this beside RESULTS -- 150 lines
# earlier -- called a function that did not exist yet.
VERDICTS_SEEN="$(verdicts_seen)"

emit_note() {
  # Titled by runbook -- see record-restore-prereqs.sh for why.
  printf '# %s — Restored-State Comparison — %s\n\n' "${PHASE_RUNBOOK%.md}" "$STAMP"
  printf 'Generated by `bin/compare-restored-state.sh` on %s.\n\n' "$(date)"
  printf 'Pairs with [[%s|%s]].\n\n' "${PHASE_RUNBOOK%.md}" "$PHASE_RUNBOOK"
  printf 'Capture sources read:\n\n'
  printf -- '- system inventory: `%s`\n' "${INVENTORY_DIR:-<none>}"
  if [[ "$RUNBOOK" != "restore-runtime" ]]; then
    printf -- '- managed inventory: `%s`\n' "${MANAGED_DIR:-<none>}"
    printf -- '- secrets manifests: `%s`\n' "${SECRETS_PARENT:-<none>}"
  fi
  printf '\n'

  printf '## Summary\n\n'
  printf '| Outcome | Count |\n| --- | --- |\n'
  printf '| Present pre-image, **missing now** | %s |\n' "$missing_count"
  if [[ "$RUNBOOK" != "restore-runtime" ]]; then
    printf '| Differs from the capture | %s |\n' "$changed_count"
    printf '| Matches the capture | %s |\n' "$match_count"
  else
    printf '| Version differs | %s |\n' "$changed_count"
    printf '| Version matches | %s |\n' "$match_count"
  fi
  printf '| No pre-image baseline recorded | %s |\n' "$unrecorded_count"
  printf '\n'

  printf '## Detail\n\n'
  if [[ "$RUNBOOK" != "restore-runtime" ]]; then
    printf '| Check | Now | Captured pre-image | Verdict |\n| --- | --- | --- | --- |\n'
  else
    printf '| Tool | Now | Pre-image | Verdict |\n| --- | --- | --- | --- |\n'
  fi
  render_rows
  printf '\n'

  if [[ -n "$DECISION_ENTRIES" ]]; then
    printf '## Recorded Decisions\n\n'
    printf 'These entries in `reimaged-system/restore-notes/decisions.md` name this\n'
    printf 'comparison. A row marked **decided** above is covered by one of them.\n\n'
    while IFS= read -r _entry; do
      [[ -n "$_entry" ]] || continue
      printf -- '- %s\n' "$_entry"
    done <<< "$DECISION_ENTRIES"
    printf '\nRead them in full with `./bin/record-decision.sh --check %s`.\n\n' "$RUN_CONTEXT"
  fi

  printf '## How to read this\n\n'
  if [[ "$RUNBOOK" != "restore-runtime" ]]; then
    if saw '**MISSING**'; then printf -- '- **MISSING** means the capture recorded it and it is not here now — a step not yet run, or one that failed quietly.\n'; fi
    if saw 'identical'; then printf -- '- **identical** on a `jssecacerts` row is a SHA-256 match: the installed file is byte-for-byte the captured one. **differs** there means the JVM trust store is not the file Step 6 was meant to install.\n'; fi
    if saw 'no baseline'; then printf -- '- **no baseline** on a `jssecacerts` row means that JDK was installed after the pre-image capture, so nothing recorded a hash for it. That JVM has no corporate trust unless you put it there.\n'; fi
    if saw 'expected later'; then printf -- '- **expected later** means the value is real but a later runbook sets it. `restore-git.md` owns the global Git configuration, so `credential.helper` and `init.defaultBranch` reading `not set yet` here is the sequence working. Re-run this comparison after that runbook.\n'; fi
    if saw 'correctly dropped'; then printf -- '- **correctly dropped** is a PASS, and the row is inverted on purpose. `http.sslverify = false` was recorded pre-image and is in the dotfiles backup; carrying it forward disables TLS verification for every Git HTTPS remote. That defeats the Git half of Step 7 — `npm`, `pip`, `curl` and Node read their own settings and are unaffected, which is what makes it easy to miss: everything else still verifies.\n'; fi
    if saw 'correctly dropped'; then printf -- '- That row passes right now for a weaker reason than it looks. While `~/.gitconfig` is absent there is no file to hold the value, so nothing was reviewed and dropped — it was never restored. It can come back twice: at Step 8 of this runbook, which lists `.gitconfig` among the selective restores, and again at `restore-git.md`. Re-check after each.\n'; fi
    if saw '**CARRIED FORWARD**'; then printf -- '- **CARRIED FORWARD** on that row means the pre-image value came back. Remove it: `git config --global --unset http.sslverify`. Before reaching for a per-host exemption, check whether one is still needed: Step 7 puts the corporate root in the CA bundle, so an internal host that failed to verify before may verify now. If one genuinely does not, `restore-git.md` -> Troubleshooting -> *An internal Enterprise Server host fails TLS verification* scopes the exemption to that single host instead of every remote.\n'; fi
    if saw 'same'; then printf -- '- **same** means the live value is exactly what the capture recorded. Unlike the version rows \`restore-runtime\` produces, these are compared as literal strings — a config value either is what it was or is not.\n'; fi
    if saw 'differs'; then printf -- '- **differs** on a value row is worth reading rather than dismissing. A rebuild is expected to bring newer *versions*; a login shell or a config value that changed is a decision someone made, or one made for them.\n'; fi
    if saw 'present'; then printf -- '- **present** means the capture recorded that this should exist and it does. The capture holds no comparable value — a configuration profile records that a root was pushed, not which trust store it landed in — so presence is the only honest comparison.\n'; fi
    printf -- '- **Corporate root trusted** reads the trust store, not the keychain file list. A certificate being present is not the same as it being trusted, and only the former shows up in `16-certs.txt`.\n'
  else
    if saw '**MISSING**'; then printf -- '- **MISSING** is the row that matters. A tool recorded pre-image and absent now is either a step not yet run or one that failed quietly. Everything downstream that needs it will fail later and less clearly.\n'; fi
    if saw 'differs'; then printf -- '- **differs** is normal. A rebuild installs current versions; an approved-newer tool is the expected outcome, not drift to correct. Investigate only an unexplained *older* version.\n'; fi
    if saw 'present'; then printf -- '- **present** means the capture listed it and it is here now. `06-homebrew.txt` records package names without versions, so presence is the only comparison it can support — a version column for those rows would read `no baseline` on every one.\n'; fi
    if saw 'expected later'; then printf -- '- **expected later** means a subsequent phase installs it. Docker Desktop arrives with \`restore-apps\`; its absence here is the sequence working, not a gap.\n'; fi
  fi
  # Outside the branch: both comparison shapes can carry decided rows.
  if [[ -n "$DECIDED_LABELS" ]]; then
    printf -- '- **decided** means a row was deliberately accepted and the reason is recorded. The verdict beside it is unchanged and still true — the difference is real; what the marker adds is that someone already weighed it. Re-read the decision rather than the row if you are about to act on it.\n'
  fi
  if [[ "$RUNBOOK" == "restore-runtime" ]]; then
    printf -- '- Comparison is on the version number, not the raw string, so `10.9.7` and `npm 10.9.7` count as the same. Both raw strings are shown so you can see what each side actually reported.\n'
  fi
  printf '\n'

  if [[ "$missing_count" -gt 0 ]]; then
    if [[ "$RUNBOOK" != "restore-runtime" ]]; then
      printf '> [!warning] %s check(s) recorded pre-image are missing now\n' "$missing_count"
      printf '> Resolve these before closing out this phase. A missing row here is trust or identity that a later phase assumes is already in place.\n\n'
    else
      printf '> [!warning] %s tool(s) present pre-image are missing now\n' "$missing_count"
      printf '> Resolve these before the restore phases that depend on them. Each one is a dependency some later phase assumes.\n\n'
    fi
  fi
}

# Context: <phase>-<runbook>-diff. Latest-wins, because a rerun after fixing a
# MISSING row is the newer truth -- unlike a `before` capture, where the first
# run is the only honest one.
# One lineage per baseline. Both wrote `-diff` until now, so the official
# pointer named whichever ran last regardless of which question it answered.
#
# Derived here rather than beside artifact_run_begin because --dry-run renders
# the note without ever staging a run, and the decisions lookup below needs the
# lineage name in both paths.
RUN_CONTEXT="${PHASE_RUNBOOK%.md}-inventory-diff"

load_decisions

if [[ "$DRY_RUN" == "true" ]]; then
  emit_note
  echo "(--dry-run: nothing written)"
  exit 0
fi

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" || ! -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "ERROR: artifact root unavailable; nothing written." >&2
  echo "HINT:  rerun with --dry-run to see the result, or reconnect the drive." >&2
  exit 2
fi

if [[ -z "$OUTPUT_ROOT" ]]; then
  OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system/comparisons"
fi
OUTPUT_ROOT="$(absolute_path "$OUTPUT_ROOT")"

if [[ -n "${REPO_ROOT:-}" && ( "$OUTPUT_ROOT" == "$REPO_ROOT" || "$OUTPUT_ROOT" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $OUTPUT_ROOT" >&2
  exit 2
fi

if ! artifact_run_begin "$OUTPUT_ROOT" "$RUN_CONTEXT"; then
  echo "ERROR: could not stage a run under: $OUTPUT_ROOT" >&2
  exit 2
fi

NOTE_FILE="$ARTIFACT_RUN_DIR/comparison.md"

if ! emit_note > "$NOTE_FILE"; then
  echo "ERROR: could not write the comparison: $NOTE_FILE" >&2
  artifact_run_abort
  exit 2
fi

# The raw joined rows beside the rendered note, so a later phase can diff two
# comparisons without reparsing Markdown.
printf '%s\n' "$RESULTS" > "$ARTIFACT_RUN_DIR/rows.tsv"

if ! artifact_run_finalize "$OUTPUT_ROOT" \
     "$missing_count missing / $changed_count differs / $match_count same"; then
  echo "ERROR: the comparison was written but could not be indexed." >&2
  exit 2
fi
NOTE_FILE="$ARTIFACT_RUN_DIR/comparison.md"

echo "Comparison → $NOTE_FILE"
printf 'Missing: %s · Differs: %s · Same: %s · No baseline: %s\n' \
  "$missing_count" "$changed_count" "$match_count" "$unrecorded_count"
echo "Indexed at: $OUTPUT_ROOT/MANIFEST.md"

if [[ "$missing_count" -gt 0 ]]; then
  echo "" >&2
  if [[ "$RUNBOOK" != "restore-runtime" ]]; then
    echo "WARNING: $missing_count check(s) recorded pre-image are missing now — see the note." >&2
  else
    echo "WARNING: $missing_count tool(s) recorded pre-image are missing now — see the note." >&2
  fi
fi

if [[ "$OPEN_RESULT" == "true" ]]; then
  open -R "$NOTE_FILE" 2>/dev/null || true
fi
