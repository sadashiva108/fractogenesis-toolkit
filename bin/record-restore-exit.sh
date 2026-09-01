#!/usr/bin/env bash
# =============================================================================
# record-restore-exit.sh
#
# Records whether a restore phase met its exit criteria, and writes the result
# as a dated evidence artifact.
#
# Runbook/phase context: the closing step of the restore phases from Phase 10
# onward -- `restore-runtime.md` Step 11 and its equivalents. It is the mirror
# of record-restore-prereqs.sh: that one answers "may this phase start", this
# one answers "did it finish". Phases 8, 9, and 14 already produce a close-out
# artifact; Phases 10A and 10B produced none, because they have no entrypoint to
# generate one, and the reader was left to confirm ten things by eye with nothing
# written down.
#
# WHY A SECOND SCRIPT RATHER THAN EXTENDING THE COMPARISON. Phase 10A already
# writes an indexed comparison run, and the exit checklist could have been
# appended there. Entry and exit are genuinely different questions, though, and a
# file named for a version comparison that also carries a phase sign-off
# understates its own contents -- while renaming it would break the glob that
# Phase 10B's prerequisite check uses to confirm the comparison ran.
#
# CLASSIFICATION: internal helper, not an entrypoint. Same reasoning as
# record-restore-prereqs.sh: it is a shared building block several phases call,
# and a runbook whose phase has no entrypoint invokes it directly.
#
# KNOWN DUPLICATION: the option parsing, path guards, and row recording below
# mirror record-restore-prereqs.sh closely. Two copies is a deliberate choice
# rather than an oversight -- extracting a shared library for a pair invites the
# indirection before the pattern is proven. If a third recorder appears in this
# directory, extract then.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#
#   # Record Phase 10A's exit criteria and write the artifact.
#   bash bin/record-restore-exit.sh --runbook restore-runtime
#
#   # Print the result without writing anything.
#   bash bin/record-restore-exit.sh --runbook restore-runtime --dry-run
#
#   # Reveal the generated artifact in Finder afterwards.
#   bash bin/record-restore-exit.sh --runbook restore-runtime --open
#
# Options:
#   --runbook NAME         Which phase's exit criteria to record. Required.
#                         Supported: 10A, 10B
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --output-root PATH    Category root for the run. A relative value is
#                         resolved against the current directory, and a
#                         destination inside the repo checkout is refused.
#                         Default: <artifact-root>/reimaged-system/boundaries
#   --dry-run             Print the checklist; write nothing.
#   --open                Reveal the generated checklist in Finder.
#   -h, --help            Show this message and exit.
#
# Output location:
#   <artifact-root>/reimaged-system/boundaries/runs/post-image-<runbook>-exit-<stamp>/
#     checklist.md
#   indexed in that category's MANIFEST.md, with official/ naming the newest run.
#   Entry and exit share one category so a single index answers whether a phase
#   both started and finished.
#
# Exit status:
#   0  Every automated row passed, or only WARN rows remain.
#   1  At least one FAIL row. The phase is not finished.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -uo pipefail
# Not -e: every check must produce a row. Aborting on the first failure would
# hide the rest, and the value of a close-out is seeing all of it at once.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"

if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi

ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

# Shared run index: staged run directories, append-only MANIFEST.md, and one
# computed official/<context>.txt per lineage. Extracted from the pattern
# report-loose-secrets.sh proved, so every producer under the artifact root
# indexes its runs the same way.
RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ ! -f "$RUNS_LIB" ]]; then
  echo "ERROR: shared run index not found: $RUNS_LIB" >&2
  exit 2
fi
# shellcheck source=../../.internal/artifact-runs.sh
source "$RUNS_LIB"

# Manual rows leave the run directory. `artifact_run_begin` stages a NEW run on
# every invocation, so a row answered inside checklist.md comes back as a fresh
# `TODO` the next time this runs -- the failure verify-reimaged-system.md warns
# about. The sign-off carries answers forward and stamps each with the run it
# was answered against. See .internal/sign-offs.sh.
SIGNOFF_LIB="$REPO_ROOT/.internal/sign-offs.sh"
if [[ ! -f "$SIGNOFF_LIB" ]]; then
  echo "ERROR: shared sign-off helper not found: $SIGNOFF_LIB" >&2
  exit 2
fi
# shellcheck source=../.internal/sign-offs.sh
source "$SIGNOFF_LIB"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

require_option_value() {
  if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
    echo "ERROR: $1 requires a non-empty value." >&2
    exit 2
  fi
}

STAMP="$(date +%Y%m%d-%H%M%S)"
RUNBOOK=""
OUTPUT_ROOT=""
DRY_RUN=false
OPEN_RESULT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runbook)         require_option_value "$1" "${2:-}"; RUNBOOK="${2%.md}"; shift 2 ;;
    --artifact-root) require_option_value "$1" "${2:-}"; REIMAGE_ARTIFACT_ROOT="$2"; shift 2 ;;
    --output-root)   require_option_value "$1" "${2:-}"; OUTPUT_ROOT="$2"; shift 2 ;;
    --dry-run)       DRY_RUN=true; shift ;;
    --open)          OPEN_RESULT=true; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "${RUNBOOK:-}" ]]; then
  echo "ERROR: --runbook is required. Supported: restore-runtime, restore-access" >&2
  usage >&2
  exit 2
fi

case "$RUNBOOK" in
  restore-runtime) PHASE_RUNBOOK="restore-runtime.md"; PHASE_NEXT="restore-access.md" ;;
  restore-access) PHASE_RUNBOOK="restore-access.md";  PHASE_NEXT="restore-git.md" ;;
  restore-git)    PHASE_RUNBOOK="restore-git.md";     PHASE_NEXT="restore-repos.md" ;;
  restore-repos)  PHASE_RUNBOOK="restore-repos.md";   PHASE_NEXT="restore-apps.md" ;;
  *) echo "ERROR: no exit criteria defined for runbook: $RUNBOOK" >&2
     echo "HINT:  supported runbooks: restore-runtime, restore-access. Others are added as their runbooks are reached." >&2
     exit 2 ;;
esac

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

# ---------------------------------------------------------------------------
# Row recording
# ---------------------------------------------------------------------------
ROWS=""
MANUAL_ROWS=""
fail_count=0
warn_count=0
pass_count=0

record() {
  local status="$1" check="$2" detail="$3"
  case "$status" in
    PASS) pass_count=$(( pass_count + 1 )) ;;
    WARN) warn_count=$(( warn_count + 1 )) ;;
    FAIL) fail_count=$(( fail_count + 1 )) ;;
  esac
  ROWS="${ROWS}| ${check} | \`${status}\` | ${detail} |"$'\n'
  printf '  %-5s %s\n' "$status" "$check" >&2
}

# Rows only a person can answer. Collected as item<TAB>note and replayed into
# the sign-off once the run id exists; they are no longer rendered into
# checklist.md, because that file is replaced on every run.
record_manual() {
  MANUAL_ROWS="${MANUAL_ROWS}${1}"$'\t'"${2}"$'\n'
}

# Version output goes to stdout for some tools and stderr for others, so 2>&1 is
# not optional here.
have() { command -v "$1" >/dev/null 2>&1; }

first_line() { eval "$1" 2>&1 | head -1 | tr -d '\r'; }


# ---------------------------------------------------------------------------
# JDK baseline
#
# The version is NOT hardcoded. `REIMAGE_JDK_BASELINE` in reimage.env pins a
# major when a project needs a specific one; unset, `java_home` returns the
# machine's default JDK. Either way the row reports WHICH path resolved, so the
# evidence carries the answer rather than a version number going stale inside
# the check. An earlier revision asked for `-v 21` in three places across two
# files, which would have started failing the day the baseline moved -- and
# failing for a reason that reads like a missing JDK.
# ---------------------------------------------------------------------------
resolve_java_home() {
  if [[ -n "${REIMAGE_JDK_BASELINE:-}" ]]; then
    /usr/libexec/java_home -v "$REIMAGE_JDK_BASELINE" 2>/dev/null
  else
    /usr/libexec/java_home 2>/dev/null
  fi
}

java_baseline_label() {
  if [[ -n "${REIMAGE_JDK_BASELINE:-}" ]]; then
    printf 'pinned to JDK %s by REIMAGE_JDK_BASELINE' "$REIMAGE_JDK_BASELINE"
  else
    printf 'the machine default; set REIMAGE_JDK_BASELINE in reimage.env to pin one'
  fi
}

# ---------------------------------------------------------------------------
# Phase 10A exit criteria
# ---------------------------------------------------------------------------
check_restore_runtime() {
  local out tool missing=""

  # Rosetta. On Intel this command succeeds trivially, so the row is
  # uninformative there rather than wrong -- say so instead of claiming a pass.
  if [[ "$(uname -m)" != "arm64" ]]; then
    record PASS "Rosetta 2 available" "not applicable on Intel"
  elif /usr/bin/pgrep -q oahd 2>/dev/null; then
    record PASS "Rosetta 2 available" "\`oahd\` running"
  else
    record WARN "Rosetta 2 available" "not installed — needed only for x86-only binaries"
  fi

  out="$(xcode-select -p 2>/dev/null)"
  if [[ -n "$out" && -d "$out" ]]; then
    record PASS "Xcode Command Line Tools" "\`$out\`"
  else
    record FAIL "Xcode Command Line Tools" "\`xcode-select -p\` does not resolve"
  fi

  if have brew; then
    record PASS "Homebrew installed" "\`$(first_line 'brew --version')\`"
  else
    record FAIL "Homebrew installed" "\`brew\` not on PATH"
  fi

  # direnv: installed is not the same as hooked. DIRENV_DIR is only set when the
  # hook has actually loaded an .envrc in this shell.
  if ! have direnv; then
    record FAIL "direnv installed and hooked" "not installed — see Step 6"
  elif [[ -n "${DIRENV_DIR:-}" ]]; then
    record PASS "direnv installed and hooked" "loaded for \`${DIRENV_DIR#-}\`"
  else
    record WARN "direnv installed and hooked" "installed, but no \`.envrc\` loaded in this shell — run \`direnv allow\` in the toolkit root"
  fi

  # The row that fails silently, and the reason this phase has a close-out.
  if out="$(resolve_java_home)" && [[ -n "$out" && -d "$out" ]]; then
    record PASS "Java resolves via java_home" "\`$out\` — $(java_baseline_label)"
  else
    record FAIL "Java resolves via java_home" "\`restore-access\` would set an empty \`JAVA_HOME\` and write \`jssecacerts\` outside the JDK ($(java_baseline_label))"
  fi

  for tool in gradle mvn; do
    have "$tool" || missing="$missing $tool"
  done
  if [[ -z "$missing" ]]; then
    record PASS "JVM build tools run" "gradle, mvn"
  else
    record FAIL "JVM build tools run" "missing:$missing — see Step 7"
  fi

  missing=""
  for tool in node npm; do
    have "$tool" || missing="$missing $tool"
  done
  if [[ -z "$missing" ]]; then
    record PASS "Node tooling runs" "\`$(first_line 'node --version')\` / npm \`$(first_line 'npm --version')\`"
  else
    record FAIL "Node tooling runs" "missing:$missing — see Step 8"
  fi

  # Platform CLIs are WARN: which of these a given machine needs is site
  # specific, and a missing one blocks a project rather than the phase.
  missing=""
  for tool in cf fly jq yq; do
    have "$tool" || missing="$missing $tool"
  done
  if [[ -z "$missing" ]]; then
    record PASS "Platform CLIs run" "cf, fly, jq, yq"
  else
    record WARN "Platform CLIs run" "missing:$missing — see Step 9; only chase the ones this machine needs"
  fi

  # The phase's own evidence. A dry run writes nothing, so this row catches the
  # case where the comparison was read on screen and never recorded.
  #
  # Ask the run index rather than globbing, for the reasons given at the
  # matching row in record-restore-prereqs.sh.
  local cmp_root cmp_run
  cmp_root="${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/reimaged-system/comparisons"
  cmp_run="$(artifact_run_official "$cmp_root" "restore-runtime-inventory-diff" 2>/dev/null)"
  if [[ -n "$cmp_run" && -f "$cmp_root/$cmp_run/comparison.md" ]]; then
    record PASS "Runtime comparison recorded" "\`$(basename "$cmp_run")\`"
  else
    record FAIL "Runtime comparison recorded" "no official run for \`restore-runtime-inventory-diff\` under \`comparisons/\` — \`--dry-run\` writes nothing; rerun \`bash bin/compare-restored-state.sh --runbook restore-runtime\` without it"
  fi

  # Freshness. "A comparison exists" and "that comparison still describes this
  # machine" are different questions, and only the first was ever asked. A
  # nine-pass sign-off on this repo cited a comparison recording Node at
  # v24.19.0 -- the regression -- while the machine had already been fixed to
  # v26.7.0. The row was green because a file was present.
  #
  # Time cannot answer it: that stale comparison was four minutes older than the
  # checklist citing it, and a comparison being older than its exit checklist is
  # the normal ordering. What went stale was the content.
  #
  # Delegated to compare-restored-state.sh --reprobe rather than re-probing
  # here. The probe table must live in exactly one place; copying it into this
  # file would be the two-implementations-of-one-contract failure that this row
  # exists to catch, reintroduced by the fix for it.
  local rp_out rp_status rp_n
  if [[ -n "$cmp_run" ]]; then
    rp_out="$(bash "$SCRIPT_DIR/compare-restored-state.sh" --runbook restore-runtime --reprobe 2>&1)"
    rp_status=$?
    case "$rp_status" in
      0)
        record PASS "Runtime comparison still current" "re-probed just now; every tool matches what \`$(basename "$cmp_run")\` recorded"
        ;;
      1)
        rp_n="$(printf '%s' "$rp_out" | grep -c 'DRIFTED')"
        record FAIL "Runtime comparison still current" "$rp_n tool(s) changed since \`$(basename "$cmp_run")\` was taken — it no longer describes this machine. Rerun \`bash bin/compare-restored-state.sh --runbook restore-runtime\` before signing off."
        ;;
      *)
        # Could not ask the question -- no rows.tsv, or the probe set refused.
        # A manual row rather than a pass or a fail: scoring "could not check"
        # as either is how a checklist starts lying.
        record_manual "Runtime comparison still current" "Freshness could not be computed automatically ($(printf '%s' "$rp_out" | grep -m1 ERROR | sed 's/^ERROR: //')). Confirm by eye that \`$(basename "$cmp_run")\` still describes this machine before accepting it."
        ;;
    esac
  else
    record_manual "Runtime comparison still current" "No comparison to check. Once one exists, this row re-probes automatically."
  fi

  record_manual "Version drift reviewed" "Every \`differs\` row in the comparison is an approved-newer version or a deliberate decision. An *older* version is the one to explain."
  record_manual "Platform CLI gaps accepted" "Any CLI missing above is one this machine genuinely does not need."
}

# ---------------------------------------------------------------------------
# Phase 10B exit criteria
#
# From restore-access.md Step 10's table. Four of its eight rows are judgement
# calls a script cannot make and are recorded as Manual TODOs rather than being
# approximated -- an approximated PASS on "is this cert really an internal root"
# is worse than no row.
#
# One row from that table is deliberately absent: `git config --global user.email`.
# The runbook's own Ownership table assigns Git identity to restore-git.md
# (Phase 11A), so gating 10B on it would make this phase depend on the next one.
# ---------------------------------------------------------------------------
check_restore_access() {
  local out mnt java_home

  # 1 -- the DMG must be detached. An attached image leaves every credential in
  # it readable, and reimage-checklist.sh --phase post FAILs on it at Phase 14 --
  # far from the phase that mounted it.
  if hdiutil info 2>/dev/null | grep -q 'all-secrets'; then
    record FAIL "Secrets DMG detached" "still attached — \`hdiutil detach\` it; see Step 10"
  else
    record PASS "Secrets DMG detached" "no \`all-secrets\` image attached"
  fi

  # 2 -- SSH material in place with the permissions the client insists on.
  #
  # Judge only the PRIVATE KEYS. An earlier revision tested every file under
  # ~/.ssh against mode 600, which FAILs a correctly restored directory:
  # `known_hosts` and `config` are conventionally 644 and ssh does not care.
  # The row said "keys" and the test said "every file" -- a vocabulary mismatch
  # that would have fired the first time this phase closed out.
  #
  # Count the keys BEFORE judging their modes. "no key is loose" is trivially
  # true of a directory holding none, and ~/.ssh exists on a fresh macOS
  # account, so neither its presence nor a clean mode sweep proves Step 3 ran.
  # 400 is accepted alongside 600: a read-only key is tighter, not looser.
  if [[ ! -d "$HOME/.ssh" ]]; then
    record FAIL "SSH private keys restored and tight" "\`~/.ssh\` does not exist — Step 3 did not run"
  else
    local ssh_total ssh_keys ssh_loose ssh_file ssh_mode
    ssh_total=0; ssh_keys=0; ssh_loose=""
    while IFS= read -r ssh_file; do
      [[ -n "$ssh_file" ]] || continue
      ssh_total=$(( ssh_total + 1 ))
      head -1 "$ssh_file" 2>/dev/null | grep -q 'PRIVATE KEY' || continue
      ssh_keys=$(( ssh_keys + 1 ))
      ssh_mode="$(/usr/bin/stat -f '%Lp' "$ssh_file" 2>/dev/null)"
      case "$ssh_mode" in
        400|600) ;;
        *) ssh_loose="$ssh_loose \`$(basename "$ssh_file")\` (${ssh_mode:-unreadable})" ;;
      esac
    done < <(find "$HOME/.ssh" -type f 2>/dev/null)

    if [[ "$ssh_keys" == "0" ]]; then
      record FAIL "SSH private keys restored and tight" "$ssh_total file(s) under \`~/.ssh\` and no private key among them — the directory is created by macOS, so this is Step 3 not having run rather than a permissions problem"
    elif [[ -z "$ssh_loose" ]]; then
      record PASS "SSH private keys restored and tight" "$ssh_keys private key(s) among $ssh_total file(s), all mode 600 or 400"
    else
      record FAIL "SSH private keys restored and tight" "loose private key(s):$ssh_loose — ssh refuses a key readable by anyone else; see Step 3"
    fi
  fi

  # 2b -- host keys, which are the half of ~/.ssh that no key check covers.
  #
  # A private key with the right mode proves Step 3 copied identities. It says
  # nothing about `known_hosts`, and the two fail differently: a missing key
  # fails loudly at connect time, while a missing known_hosts succeeds after an
  # interactive prompt. Phase 11B clones repositories in a loop, so that prompt
  # arrives mid-run.
  #
  # WARN rather than FAIL: a machine with no SSH remotes to reach legitimately
  # has no host keys, and `ssh` will still work once someone answers yes.
  if [[ ! -s "$HOME/.ssh/known_hosts" ]]; then
    record WARN "SSH host keys seeded" "no \`~/.ssh/known_hosts\` — every host prompts on first connect, including inside Phase 11B's clone loop; re-run \`./bin/restore-access.sh ssh\` to seed the aliases in \`~/.ssh/config\`"
  else
    local kh_lines kh_aliases
    kh_lines="$(grep -c . "$HOME/.ssh/known_hosts" 2>/dev/null || echo 0)"
    kh_aliases="$(awk '/^[Hh]ost /{for(i=2;i<=NF;i++) if($i !~ /[*?]/) n++} END{print n+0}' "$HOME/.ssh/config" 2>/dev/null || echo 0)"
    record PASS "SSH host keys seeded" "$kh_lines host key(s) known, against $kh_aliases alias(es) in \`~/.ssh/config\`"
  fi

  # 3 -- jssecacerts in the JDK that Phase 10A actually installed. Checked
  # against java_home rather than $JAVA_HOME: the variable is set inside Step 6's
  # shell and need not survive into this one, so its absence here means nothing.
  java_home="$(resolve_java_home)"
  if [[ -z "$java_home" ]]; then
    record FAIL "Java trust override in place" "\`java_home\` does not resolve ($(java_baseline_label)) — Step 6 had no JDK to write into"
  elif [[ -f "$java_home/lib/security/jssecacerts" ]]; then
    record PASS "Java trust override in place" "\`$java_home/lib/security/jssecacerts\`"
  else
    record WARN "Java trust override in place" "no \`jssecacerts\` under \`$java_home/lib/security/\` — correct only if this machine needs no JVM trust override; see Step 6"
  fi

  # 4 -- the CA bundle non-keychain tools read. Emptiness matters more than
  # existence: `openssl x509 -inform DER` against a PEM input fails and still
  # creates the output file, so a zero-byte bundle looks staged and trusts
  # nothing.
  if [[ ! -f "$HOME/.certs/system-and-corp-roots.pem" ]]; then
    record WARN "Corporate CA bundle present" "no \`~/.certs/system-and-corp-roots.pem\` — correct only if this network does no TLS interception; see Step 7"
  elif grep -q 'BEGIN CERTIFICATE' "$HOME/.certs/system-and-corp-roots.pem" 2>/dev/null; then
    local n
    n="$(grep -c 'BEGIN CERTIFICATE' "$HOME/.certs/system-and-corp-roots.pem" 2>/dev/null)"
    record PASS "Corporate CA bundle present" "$n certificate(s) in \`~/.certs/system-and-corp-roots.pem\`"
  else
    record FAIL "Corporate CA bundle present" "\`~/.certs/system-and-corp-roots.pem\` holds no certificate — the DER/PEM conversion in Step 7 failed and left an empty file"
  fi

  # 5 -- the three stores Step 7 configures, tested against PUBLIC hosts on
  # purpose. Five of Step 7's six settings REPLACE a tool's CA bundle rather than
  # adding to it, so pointing them at a corporate-root-only file breaks public
  # TLS. A public host is the test that catches it.
  if have npm; then
    if npm ping >/dev/null 2>&1; then
      record PASS "npm reaches the registry over TLS" "\`npm ping\` succeeded"
    else
      record FAIL "npm reaches the registry over TLS" "\`npm ping\` failed — check \`npm config get cafile\`; see Step 7"
    fi
  else
    record WARN "npm reaches the registry over TLS" "\`npm\` not on PATH — cannot test; see restore-runtime.md Step 8"
  fi

  if git ls-remote https://github.com/git/git >/dev/null 2>&1; then
    record PASS "Git reaches HTTPS remotes" "\`git ls-remote\` over HTTPS succeeded"
  else
    record FAIL "Git reaches HTTPS remotes" "\`git ls-remote\` failed — check \`git config --get http.sslCAInfo\`; see Step 7"
  fi

  if python3 -c "import urllib.request; urllib.request.urlopen('https://pypi.org/simple/')" >/dev/null 2>&1; then
    record PASS "Python reaches HTTPS over TLS" "\`urllib\` fetch succeeded"
  else
    record FAIL "Python reaches HTTPS over TLS" "fetch failed — check \`REQUESTS_CA_BUNDLE\` and \`PIP_CERT\`; see Step 7"
  fi

  # 6 -- Phase 3B's sweep put credential-shaped files inside the DMG and Step 2
  # puts them back. Skipping it leaves holes in the trees Phases 12 and 15 read,
  # and nothing downstream notices.
  #
  # An earlier revision PASSed when no plaintext `staged-loose/MANIFEST.tsv`
  # existed outside the image. That is evidence of nothing: the manifest lives
  # ON the DMG, so its absence from the plaintext tree is the normal state
  # whether Step 2 ran or not. The row named a restore and tested a filename.
  #
  # The DMG's own build manifest sits beside the image and is readable WITHOUT
  # the password. Filtering it to the `staged-loose/` rows yields the exact
  # destination list Step 2 is responsible for -- checkable after the image is
  # detached, which is when this checklist runs.
  #
  # Presence is necessary, not sufficient: a destination can exist because it
  # was never swept, or because something else recreated it. The Manual row
  # below carries the half this cannot answer.
  local dmg_manifest sl_line sl_rel sl_total sl_absent sl_missing
  dmg_manifest="$(ls -1 "${REIMAGE_ARTIFACT_ROOT:-/nonexistent}/secrets-encrypted/"all-secrets-*-manifest.txt 2>/dev/null | sort | tail -1)"
  if [[ -z "$dmg_manifest" || ! -f "$dmg_manifest" ]]; then
    record WARN "Staged-loose destinations present" "no \`all-secrets-*-manifest.txt\` beside the image — the destination list cannot be read, so this is unchecked rather than clean"
  else
    sl_total=0; sl_absent=0; sl_missing=""
    while IFS= read -r sl_line; do
      case "$sl_line" in *"/staged-loose/"*) ;; *) continue ;; esac
      sl_rel="${sl_line#*/staged-loose/}"
      [[ "$sl_rel" == "MANIFEST.tsv" ]] && continue
      sl_total=$(( sl_total + 1 ))
      [[ -e "$REIMAGE_ARTIFACT_ROOT/$sl_rel" ]] && continue
      sl_absent=$(( sl_absent + 1 ))
      if [[ "$sl_absent" -le 4 ]]; then
        sl_missing="$sl_missing \`$sl_rel\`"
      elif [[ "$sl_absent" == "5" ]]; then
        sl_missing="$sl_missing and more"
      fi
    done < "$dmg_manifest"

    if [[ "$sl_total" == "0" ]]; then
      record PASS "Staged-loose destinations present" "the image carries no \`staged-loose/\` rows — \`stage-loose-secrets\` swept nothing, so Step 2 has nothing to restore"
    elif [[ "$sl_absent" == "0" ]]; then
      record PASS "Staged-loose destinations present" "all $sl_total destination(s) named in \`$(basename "$dmg_manifest")\` exist under the artifact root"
    else
      record FAIL "Staged-loose destinations present" "$sl_absent of $sl_total destination(s) absent:$sl_missing — run \`./bin/restore-staged-loose.sh --apply\` with the image attached; see Step 2"
    fi
  fi

  record_manual "Step 2 was actually run" "\`./bin/restore-staged-loose.sh --apply\` ran with the image attached and reported every row \`RESTORED\` or \`EXISTS\`. The automated row above proves the destinations exist, not that this phase is why."
  record_manual "Internal root trusted; intermediates left on system defaults" "Always Trust belongs to the internal ROOT only. An intermediate should read \`Use System Defaults\` and \`This certificate is valid\` -- trusting it directly creates a second anchor that survives the root being revoked. Never a leaf. Answering \`none needed\` is a decision and counts."
  # The by-hand categories have no script to check them, but most leave a
  # destination behind. Listing which of those exist turns this row from an
  # answer given by memory into one given against a listing -- without claiming
  # the presence of a directory proves its contents were restored.
  local bh_dest bh_have="" bh_miss=""
  for bh_dest in "$HOME/.gnupg" "$HOME/.kube" "$HOME/.claude" "$HOME/.claude.json" \
                 "$HOME/Library/Application Support/com.raycast.macos"; do
    if [[ -e "$bh_dest" ]]; then
      bh_have="$bh_have \`${bh_dest/#$HOME/~}\`"
    else
      bh_miss="$bh_miss \`${bh_dest/#$HOME/~}\`"
    fi
  done
  record_manual "By-hand DMG categories walked" "Every row of restore-access.md's *DMG Categories Restored By Hand* is restored or consciously skipped. Once the image is detached and the drive retired they are gone. Destinations present:${bh_have:- none}. Absent:${bh_miss:- none} — absence is not proof one was skipped, and presence is not proof one was restored; both are here so this row is answered against a listing rather than from memory."
  record_manual "Shell config merged, not overwritten" "\`.zprofile\` still carries \`restore-runtime\`'s Homebrew and nvm bootstrap *and* Step 7's CA exports."
  record_manual "Licenses activated through supported flows" "No plaintext activation material left on disk outside the DMG."
}

echo "Recording ${PHASE_RUNBOOK%.md} exit criteria..." >&2
# ---------------------------------------------------------------------------
# Phase 11A exit -- restore-git
# ---------------------------------------------------------------------------
check_restore_git() {
  local out helper ev missing_env pers_set pers_blank

  if [[ -f "$HOME/.gitconfig" ]]; then
    record PASS "Global .gitconfig written" "\`~/.gitconfig\` present"
  else
    record FAIL "Global .gitconfig written" "\`~/.gitconfig\` is not on disk — Step 4 writes it"
  fi

  # The dual-identity routing. A global config with no includeIf means every
  # repository gets one identity, which is the failure this phase exists to
  # prevent -- and it looks completely healthy until a commit lands under the
  # wrong name.
  if git config --global --get-regexp '^includeif' >/dev/null 2>&1; then
    record PASS "Dual-identity routing in place" "\`includeIf\` directive present"
  else
    record FAIL "Dual-identity routing in place" "no \`includeIf\` in \`~/.gitconfig\` — every repository would use one identity; Step 5 writes the override"
  fi

  # Verification ON is the secure default, and the pre-image machine had it OFF
  # globally. This is the phase that could carry it forward.
  out="$(git config --global --get http.sslverify 2>/dev/null)"
  if [[ -z "$out" ]]; then
    record PASS "TLS verification left on" "\`http.sslverify\` unset globally"
  elif [[ "$out" == "false" ]]; then
    record FAIL "TLS verification left on" "\`http.sslverify=false\` is set globally — this disables TLS verification for every Git HTTPS remote. Remove it with \`git config --global --unset http.sslverify\` and scope any genuine exemption per host."
  else
    record PASS "TLS verification left on" "\`http.sslverify=$out\`"
  fi

  helper="$(git config --global credential.helper 2>/dev/null)"
  if [[ -n "$helper" ]]; then
    record PASS "Credential helper configured" "\`$helper\`"
  else
    record WARN "Credential helper configured" "unset — HTTPS remotes will prompt every time"
  fi

  if [[ -f "$HOME/.ssh/config" ]] && grep -qiE '^[[:space:]]*Host[[:space:]]' "$HOME/.ssh/config" 2>/dev/null; then
    record PASS "SSH host aliases written" "\`~/.ssh/config\` carries Host entries"
  else
    record FAIL "SSH host aliases written" "no Host entries in \`~/.ssh/config\` — Step 3 writes them"
  fi

  # The values Step 0c wrote into reimage.env. An exit row and not an entry row
  # on purpose: at entry they are unset by definition -- 0c is what sets them --
  # and a row that can only FAIL at the boundary it is checked at is a scheduled
  # false alarm, not a check. `upsert-env` writes an empty value without
  # complaining, so "the key is present in reimage.env" is not the question;
  # "it carries a value" is.
  #
  # The GIT_PERSONAL_* set is OPTIONAL and all-or-nothing. A Mac with no separate
  # personal identity leaves all four blank and that is a PASS. A half-filled set
  # is the failure worth the row: Step 5 writes the override unquoted, Git accepts
  # an empty name or email without complaint, and the first symptom is a commit
  # authored by nobody.
  missing_env=""
  for ev in GIT_WORK_NAME GIT_WORK_EMAIL GIT_WORK_SSH_KEY \
            GIT_WORK_GITHUB_HOST GIT_DEFAULT_BRANCH; do
    eval "out=\${$ev:-}"
    [[ -n "$out" ]] || missing_env="${missing_env:+$missing_env }$ev"
  done
  pers_set=""; pers_blank=""
  for ev in GIT_PERSONAL_NAME GIT_PERSONAL_EMAIL GIT_PERSONAL_SSH_KEY \
            GIT_PERSONAL_GITHUB_HOST; do
    eval "out=\${$ev:-}"
    if [[ -n "$out" ]]; then
      pers_set="${pers_set:+$pers_set }$ev"
    else
      pers_blank="${pers_blank:+$pers_blank }$ev"
    fi
  done
  if [[ -n "$missing_env" ]]; then
    record FAIL "Identity values recorded in \`reimage.env\`" "required and empty: \`$missing_env\` — Step 0c writes these. \`restore-repos\` reads the host alias from here rather than re-deriving it, so an empty one surfaces a phase later as a clone routed to the wrong identity."
  elif [[ -n "$pers_set" && -n "$pers_blank" ]]; then
    record FAIL "Identity values recorded in \`reimage.env\`" "the personal identity is half-filled — set: \`$pers_set\`; blank: \`$pers_blank\`. Fill all four or clear all four; Step 5 writes an override with an empty field otherwise and Git accepts it without complaint."
  elif [[ -n "$pers_set" && -z "${GIT_PERSONAL_REPO_ROOT:-}" ]]; then
    record FAIL "Identity values recorded in \`reimage.env\`" "a personal identity is set but \`GIT_PERSONAL_REPO_ROOT\` is empty — \`includeIf\` has no \`gitdir:\` to match and Step 5 would write to \`/.gitconfig\`. That value comes from \`backup-repos\`."
  elif [[ -z "$pers_set" ]]; then
    record PASS "Identity values recorded in \`reimage.env\`" "work identity complete; no personal identity configured — the personal halves of Steps 3, 5 and 6 do not apply"
  else
    record PASS "Identity values recorded in \`reimage.env\`" "work and personal identities complete"
  fi

  # `GIT_PERSONAL_GITHUB_HOSTNAME` sits outside the all-or-nothing set above on
  # purpose: blank is its normal value and means `HostName` inherits whatever
  # `GIT_PERSONAL_GITHUB_HOST` holds. It is filled only when that host is an
  # alias -- two accounts on one server, where a single `Host` name cannot carry
  # two keys. The failure this row catches is an alias with nothing real behind
  # it: `Host github.com-personal` / `HostName github.com-personal` writes a name
  # DNS cannot resolve, and ssh reports it as an unreachable host rather than as
  # a configuration mistake.
  if [[ -n "${GIT_PERSONAL_GITHUB_HOST:-}" ]]; then
    want_alias="$GIT_PERSONAL_GITHUB_HOST"
    want_real="${GIT_PERSONAL_GITHUB_HOSTNAME:-$GIT_PERSONAL_GITHUB_HOST}"
    if [[ ! -f "$HOME/.ssh/config" ]]; then
      record FAIL "Personal SSH host resolves to a real server" "\`~/.ssh/config\` does not exist -- Step 3 writes it"
    else
      got_real="$(awk -v want="$want_alias" '
        BEGIN { inblock = 0 }
        {
          line = $0
          sub(/^[ \t]+/, "", line)
          if (tolower(line) ~ /^host[ \t]/) {
            sub(/^[^ \t]+[ \t]+/, "", line)
            inblock = (line == want) ? 1 : 0
            next
          }
          if (inblock && tolower(line) ~ /^hostname[ \t]/) {
            sub(/^[^ \t]+[ \t]+/, "", line)
            print line
            exit
          }
        }' "$HOME/.ssh/config" 2>/dev/null)"
      if [[ -z "$got_real" ]]; then
        record FAIL "Personal SSH host resolves to a real server" "no \`Host $want_alias\` block with a \`HostName\` in \`~/.ssh/config\` -- re-run Step 3"
      elif [[ "$got_real" != "$want_real" ]]; then
        record FAIL "Personal SSH host resolves to a real server" "\`Host $want_alias\` points at \`$got_real\`, but \`reimage.env\` expects \`$want_real\` -- \`~/.ssh/config\` and \`reimage.env\` disagree, and \`restore-repos\` trusts \`reimage.env\`"
      elif [[ "$want_alias" == "$want_real" ]]; then
        record PASS "Personal SSH host resolves to a real server" "\`$want_alias\` is a real host; no alias in use"
      else
        record PASS "Personal SSH host resolves to a real server" "alias \`$want_alias\` resolves to \`$want_real\`"
      fi
    fi
  fi

  record_manual "Both identities validated" "Step 7 ran \`ssh -T\` against both hosts and each returned the expected account. An unregistered key and a wrong key fail identically, so this is the row only you can close."
}

# ---------------------------------------------------------------------------
# restore-repos exit criteria
#
# This phase does not have a fixed finish line. The operator restores the
# repositories they need now and returns for the rest, so "every repository is
# present" is the wrong question -- the right one is whether what IS on disk is
# correctly placed, and whether what is NOT has been decided rather than
# forgotten. The automated rows check placement; the manual rows carry the
# decisions.
# ---------------------------------------------------------------------------
check_restore_repos() {
  local root label want_host n present bad repo rurl

  # 1 -- both clone roots exist. mkdir -p in the generated clone script creates
  # them, so an absent root means no clone from this phase has ever run.
  bad=""
  for root in "${GIT_WORK_REPO_ROOT:-}" "${GIT_PERSONAL_REPO_ROOT:-}"; do
    [[ -n "$root" && -d "$root" ]] || bad="${bad:+$bad; }\`${root:-<unset>}\`"
  done
  if [[ -z "$bad" ]]; then
    record PASS "Clone roots present" "both roots exist on disk"
  else
    record FAIL "Clone roots present" "missing: $bad — no clone has run, or \`reimage.env\` names a root that was never created"
  fi

  # 2 -- how many repositories are actually here. Reported, not graded: the
  # count that is "right" is a decision this recorder cannot make.
  n=0
  for root in "${GIT_WORK_REPO_ROOT:-}" "${GIT_PERSONAL_REPO_ROOT:-}"; do
    [[ -n "$root" && -d "$root" ]] || continue
    while IFS= read -r repo; do
      [[ -n "$repo" ]] && n=$((n + 1))
    done <<EOF
$(find "$root" -maxdepth 2 -type d -name .git 2>/dev/null)
EOF
  done
  record PASS "Repositories on disk" "$n restored across both roots"

  # 3 -- placement. A repository's root decides its identity through includeIf,
  # so a work repository under the personal root commits with the personal
  # address and offers the personal key. This is the row that catches it, and
  # nothing else in the workflow does.
  bad=""
  for root in "${GIT_WORK_REPO_ROOT:-}" "${GIT_PERSONAL_REPO_ROOT:-}"; do
    [[ -n "$root" && -d "$root" ]] || continue
    if [[ "$root" == "${GIT_PERSONAL_REPO_ROOT:-}" ]]; then
      want_host="${GIT_PERSONAL_GITHUB_HOST:-}"; label="personal"
    else
      want_host="${GIT_WORK_GITHUB_HOST:-}"; label="work"
    fi
    [[ -n "$want_host" ]] || continue
    while IFS= read -r repo; do
      [[ -n "$repo" ]] || continue
      repo="$(dirname "$repo")"
      rurl="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
      [[ -n "$rurl" ]] || continue
      case "$rurl" in
        *"$want_host"*) ;;
        *) bad="${bad:+$bad; }\`$(basename "$repo")\` under the $label root points at \`$(printf '%s' "$rurl" | sed 's#.*//##; s#[:/].*##; s#.*@##')\`" ;;
      esac
    done <<EOF
$(find "$root" -maxdepth 2 -type d -name .git 2>/dev/null)
EOF
  done
  if [[ -z "$bad" ]]; then
    record PASS "Each repository sits under the root matching its remote" "no misplaced clones"
  else
    record FAIL "Each repository sits under the root matching its remote" "$bad — the root decides identity through \`includeIf\`, so a misplaced clone commits under the wrong address and offers the wrong key"
  fi

  record_manual "Repositories left unrestored are a decision" "The pre-image audit inventoried more repositories than are on disk. Every one not restored is deliberate — needed later, obsolete, or unreachable — rather than overlooked. Returning for more later is expected; leaving without deciding is what this row prevents."
  record_manual "Carry-forward reconciled for what was restored" "Stashes, local-only commits, and kept ignored files recorded in the pre-image audit are restored into each cloned repository, or consciously dropped. This applies only to the repositories actually present."
  record_manual "Repositories with no remote are resolved" "Any repository the audit recorded with no remote cannot be cloned by anything. Each is recovered from Time Machine or the home backup, or deliberately let go."
}

"check_${RUNBOOK//-/_}"

# ---------------------------------------------------------------------------
# Emit
# ---------------------------------------------------------------------------
emit() {
  # Titled by runbook -- see record-restore-prereqs.sh for why.
  printf '# %s — Exit Criteria — %s\n\n' "${PHASE_RUNBOOK%.md}" "$STAMP"
  printf 'Generated by `bin/record-restore-exit.sh` on %s.\n\n' "$(date)"
  printf 'Pairs with [[%s|%s]].\n\n' "${PHASE_RUNBOOK%.md}" "$PHASE_RUNBOOK"

  printf '## Automated\n\n'
  printf '| Check | Result | Detail |\n| --- | --- | --- |\n'
  printf '%s' "$ROWS"
  printf '\n**%s pass · %s warn · %s fail**\n\n' "$pass_count" "$warn_count" "$fail_count"

  if [[ -n "$MANUAL_ROWS" ]]; then
    printf '## Manual\n\n'
    printf 'The rows a person answers are not in this file. Rerunning this script\n'
    printf 'stages a new run directory, so an answer recorded here would come back as\n'
    printf 'a fresh `TODO`. They live in the sign-off, which carries answers forward\n'
    printf 'and records the run each was answered against:\n\n'
    if [[ -n "${SIGNOFF_FILE:-}" ]]; then
      printf '    %s\n\n' "$SIGNOFF_FILE"
    else
      printf '    <artifact-root>/reimaged-system/sign-offs/%s-YYYYMMDD-HHMMSS.md\n\n' "$RUN_CONTEXT"
    fi
    printf 'A row closed as `no` or `accepted` is a decision and counts as answered;\n'
    printf 'the check is for rows nobody looked at.\n\n'
  fi

  printf '## How to read this\n\n'
  printf -- '- **FAIL** (%s here) means the phase is not finished. Resolve before starting %s.\n' "$fail_count" "$PHASE_NEXT"
  printf -- '- **WARN** (%s here) means proceed with a known limit, named in the row.\n' "$warn_count"
  printf -- '- This is the exit half of a pair. The entry half is `record-restore-prereqs.sh --runbook %s`, run at the phase Step 0. One check per boundary, not one per runbook.\n' "${PHASE_RUNBOOK%.md}"
  printf -- '- Both halves index into `boundaries/MANIFEST.md`, so one file shows whether a phase both started and finished.\n'
}

if [[ "$DRY_RUN" == "true" ]]; then
  echo "" >&2
  emit
  echo "(--dry-run: nothing written)" >&2
  [[ "$fail_count" -eq 0 ]] || exit 1
  exit 0
fi

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" || ! -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "" >&2
  echo "NOTE: artifact root unavailable, so no checklist was written." >&2
  echo "      Rerun with --dry-run to see the result, or reconnect the drive." >&2
  [[ "$fail_count" -eq 0 ]] || exit 1
  exit 0
fi

# One category for both boundaries. Entry and exit are the same question asked
# from either side of a phase, so they belong under one index where a runbook's
# pair sits adjacent -- rather than in two sibling directories that have to be
# read together to see whether a phase both started and finished.
if [[ -z "$OUTPUT_ROOT" ]]; then
  OUTPUT_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system/boundaries"
fi
OUTPUT_ROOT="$(absolute_path "$OUTPUT_ROOT")"

if [[ -n "${REPO_ROOT:-}" && ( "$OUTPUT_ROOT" == "$REPO_ROOT" || "$OUTPUT_ROOT" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $OUTPUT_ROOT" >&2
  exit 2
fi

# Context key: <phase>-<runbook>-<point>. The runbook name rather than the phase
# ordinal, because ordinals renumber -- twice in one day, on this repo -- and a
# directory name already written to the drive cannot be renumbered afterwards.
RUN_CONTEXT="${PHASE_RUNBOOK%.md}-exit"

if ! artifact_run_begin "$OUTPUT_ROOT" "$RUN_CONTEXT"; then
  echo "ERROR: could not stage a run under: $OUTPUT_ROOT" >&2
  exit 2
fi

CHECK_FILE="$ARTIFACT_RUN_DIR/checklist.md"

# Sibling of the boundaries category, not inside it: a sign-off outlives the run
# it was opened for, so it must not sit in a directory a later run replaces.
# Opened before `emit` so SIGNOFF_FILE resolves for the pointer in the Manual
# section, and named for this run so a carried answer says which run it answered.
SIGNOFF_ROOT="$(dirname "$OUTPUT_ROOT")/sign-offs"
if ! signoff_begin "$SIGNOFF_ROOT" "$RUN_CONTEXT" "$ARTIFACT_RUN_ID"; then
  echo "ERROR: cannot open a sign-off under: $SIGNOFF_ROOT" >&2
  artifact_run_abort
  exit 2
fi

if ! emit > "$CHECK_FILE"; then
  echo "ERROR: could not write the checklist: $CHECK_FILE" >&2
  artifact_run_abort
  exit 2
fi

while IFS=$'\t' read -r _signoff_item _signoff_note; do
  [[ -n "$_signoff_item" ]] || continue
  signoff_row "$_signoff_item" "$_signoff_note"
done <<< "$MANUAL_ROWS"
signoff_finalize "" "$CHECK_FILE"

# The result summary lands in the manifest row, so the index answers "did this
# phase pass" without opening the run.
if ! artifact_run_finalize "$OUTPUT_ROOT" \
     "$pass_count pass / $warn_count warn / $fail_count fail"; then
  echo "ERROR: the run was written but could not be indexed." >&2
  exit 2
fi

CHECK_FILE="$ARTIFACT_RUN_DIR/checklist.md"

echo "" >&2
echo "Checklist → $CHECK_FILE" >&2
printf '%s pass · %s warn · %s fail\n' "$pass_count" "$warn_count" "$fail_count" >&2
echo "Answer the Manual rows in the sign-off before starting $PHASE_NEXT:" >&2
echo "  $SIGNOFF_FILE" >&2

if [[ "$OPEN_RESULT" == "true" ]]; then
  open -R "$CHECK_FILE" 2>/dev/null || true
fi

[[ "$fail_count" -eq 0 ]] || exit 1
exit 0
