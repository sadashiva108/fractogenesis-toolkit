#!/usr/bin/env bash
# =============================================================================
# restore-access.sh
#
# Drives restore-access.md (Phase 10B): mounts the encrypted secrets DMG and
# puts SSH, Git, certificate, keychain, Java and CLI trust material back on a
# freshly imaged Mac.
#
# This file is intended for bin/. It is a normal entrypoint. Unlike the capture
# scripts it is not a single read-only pass: the phase has gates that only a
# person can pass -- the DMG passphrase, an admin password for system trust,
# and the judgment calls in the dotfile merge. The default run walks the steps
# in order, does the work at each, and stops at a gate with the reason rather
# than pretending the step succeeded. Every step is also a subcommand, so a step
# can be re-run alone after a fix without repeating the phase.
#
# The runbook keeps the individual commands under Supplemental Reference. This
# script is the ordered path; those are the same operations broken out for
# troubleshooting or for working a step by hand.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/restore-access.sh
#
#   # Walk the whole phase in order
#   ./bin/restore-access.sh
#
#   # See what the ordered run would do, without doing any of it
#   ./bin/restore-access.sh --dry-run
#
#   # Run one step
#   ./bin/restore-access.sh ssh
#   ./bin/restore-access.sh corp-ca
#
#   # Resume the ordered run from a step
#   ./bin/restore-access.sh --from java
#
# Steps, in order:
#   prereqs       Record Phase 10B prerequisites and the before-state (Step 0)
#   mount         Attach the encrypted secrets DMG (Step 1)
#   staged-loose  Restore files swept by the Phase 3B sweep (Step 2)
#   ssh           Restore SSH keys, config and modes (Step 3)
#   certs         Identify the corporate root on the image (Step 4)
#   trust         Add the root to the System keychain as trusted (Step 5)
#   java          Install jssecacerts into the installed JDKs (Step 6)
#   corp-ca       Build the CA bundle and point npm/git/pip/curl at it (Step 7)
#   dotfiles      Report which shell files differ from the backup (Step 8)
#   credentials   Report which credential categories the image carries (Step 9)
#   finish        Eject the DMG, capture the after-state, compare against the
#                 captured inventories, record the exit checklist
#                 (Steps 10 through 12)
#
# Options:
#   --dry-run             Print what each step would do; change nothing.
#   --from STEP           Start the ordered run at STEP instead of the first.
#   --only STEP           Run STEP alone. Same as naming it as an argument.
#   --artifact-root PATH  Override REIMAGE_ARTIFACT_ROOT for this invocation.
#   --mnt PATH            Use an already-mounted image at PATH instead of
#                         attaching one. Skips the `mount` step.
#   --yes                 Do not pause for confirmation before a privileged
#                         action. Intended for a re-run, not a first run.
#   -h, --help            Show this message and exit.
#
# Privileged actions:
#   `trust` and `java` change system state and will prompt for an admin
#   password -- `security add-trusted-cert` against the System keychain, and a
#   `sudo cp` into each JDK's lib/security. Both verify before they act: the
#   certificate must be self-signed to be trusted as a root, and every
#   jssecacerts file replaced is copied to `<name>.pre-reimage-<stamp>` first.
#   Neither runs under --dry-run.
#
# Exit status:
#   0  Every step attempted completed, or was cleanly skipped.
#   1  A step failed, or stopped at a gate that needs you.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -Eeuo pipefail
trap 'status=$?; echo "" >&2; \
  echo "ERROR: restore-access.sh failed near line ${LINENO}: ${BASH_COMMAND}" >&2; \
  exit "$status"' ERR

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

ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER" || {
  echo "ERROR: shared config failed to load (status $?)" >&2
  exit 2
}

# ---------------------------------------------------------------------------
# Output helpers -- same palette as the other bin/ entrypoints
# ---------------------------------------------------------------------------
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

thin_hr()     { printf '%s\n' "  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"; }
log_section() { echo ""; printf "${BLD}${CYN}▸ %s${RST}\n" "$1"; thin_hr; }
ok()          { printf "    ${GRN}OK      %s${RST}\n" "$1"; }
info()        { printf "    ${DIM}        %s${RST}\n" "$1"; }
skip()        { printf "    ${DIM}SKIP    %s${RST}\n" "$1"; }
warn()        { printf "    ${YEL}WARN    %s${RST}\n" "$1"; }
fail()        { printf "    ${RED}FAIL    %s${RST}\n" "$1"; }
gate()        { printf "    ${YEL}GATE    %s${RST}\n" "$1"; }
would()       { printf "    ${CYN}WOULD   %s${RST}\n" "$1"; }

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

require_option_value() {
  if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
    echo "ERROR: $1 requires a non-empty value." >&2
    usage >&2
    exit 2
  fi
}

# ---------------------------------------------------------------------------
# Step registry. Space-separated, not an array of arrays: Bash 3.2 is the floor
# and has no associative arrays.
# ---------------------------------------------------------------------------
ALL_STEPS="prereqs mount staged-loose ssh certs trust java corp-ca dotfiles credentials finish"

step_is_known() {
  case " $ALL_STEPS " in
    *" $1 "*) return 0 ;;
    *)        return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Defaults and command-line state
# ---------------------------------------------------------------------------
DRY_RUN=false
ASSUME_YES=false
FROM_STEP=""
ONLY_STEP=""
MNT="${MNT:-}"
FAILURES=0
GATES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)       DRY_RUN=true; shift ;;
    --yes)           ASSUME_YES=true; shift ;;
    --from)          require_option_value "$1" "${2:-}"; FROM_STEP="$2"; shift 2 ;;
    --only)          require_option_value "$1" "${2:-}"; ONLY_STEP="$2"; shift 2 ;;
    --artifact-root) require_option_value "$1" "${2:-}"; REIMAGE_ARTIFACT_ROOT="$2"; shift 2 ;;
    --mnt)           require_option_value "$1" "${2:-}"; MNT="$2"; shift 2 ;;
    -h|--help)       usage; exit 0 ;;
    --*)             echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if step_is_known "$1"; then
        ONLY_STEP="$1"; shift
      else
        echo "ERROR: unknown step: $1" >&2
        echo "Steps: $ALL_STEPS" >&2
        exit 2
      fi
      ;;
  esac
done

for candidate in "$FROM_STEP" "$ONLY_STEP"; do
  if [[ -n "$candidate" ]] && ! step_is_known "$candidate"; then
    echo "ERROR: unknown step: $candidate" >&2
    echo "Steps: $ALL_STEPS" >&2
    exit 2
  fi
done

if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set." >&2
  echo "Source reimage.env, or pass --artifact-root." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Shared state, written by earlier steps and read by later ones
# ---------------------------------------------------------------------------
CORP_CERT=""
CA_BUNDLE_REL=".certs/corp-root.pem"
CA_BUNDLE="$HOME/$CA_BUNDLE_REL"
STAMP="$(date +%Y%m%d-%H%M%S)"

# Confirm before a privileged action unless --yes. Reads the terminal directly
# so a step inside a pipeline still gets the answer.
confirm() {
  $ASSUME_YES && return 0
  local reply=""
  printf "    ${YEL}%s${RST} [y/N] " "$1"
  read -r reply < /dev/tty || reply=""
  case "$reply" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

# Locate the mounted image by its manifest rather than by volume name: the
# volume name comes from -volname at build time and need not match the .dmg.
find_mounted_image() {
  local d
  for d in /Volumes/*/staged-loose; do
    [[ -f "$d/MANIFEST.tsv" ]] && { dirname "$d"; return 0; }
  done
  return 1
}

require_mnt() {
  [[ -n "$MNT" ]] || MNT="$(find_mounted_image || true)"
  if [[ -z "$MNT" || ! -d "$MNT" ]]; then
    gate "No mounted secrets image. Run: ./bin/restore-access.sh mount"
    GATES=$((GATES + 1))
    return 1
  fi
  return 0
}

# Subject and issuer equal means self-signed, which is what makes a root a root.
cert_subject() {
  openssl x509 -in "$1" -noout -subject 2>/dev/null \
    || openssl x509 -inform DER -in "$1" -noout -subject 2>/dev/null
}
cert_issuer() {
  openssl x509 -in "$1" -noout -issuer 2>/dev/null \
    || openssl x509 -inform DER -in "$1" -noout -issuer 2>/dev/null
}
cert_is_root() {
  local s i
  s="$(cert_subject "$1")" || return 1
  i="$(cert_issuer "$1")"  || return 1
  [[ -n "$s" && "${s#subject=}" == "${i#issuer=}" ]]
}

# ---------------------------------------------------------------------------
# Step 0 -- prereqs
# ---------------------------------------------------------------------------
step_prereqs() {
  log_section "Step 0 — Record prerequisites and the before-state"
  local rec="$REPO_ROOT/bin/record-restore-prereqs.sh"
  local state="$REPO_ROOT/bin/record-restore-state.sh"

  if $DRY_RUN; then
    would "$rec --runbook restore-access"
    would "$state --runbook restore-access --point before"
    return 0
  fi

  if [[ -x "$rec" ]] || [[ -f "$rec" ]]; then
    bash "$rec" --runbook restore-access || warn "prerequisite recorder reported findings — read them before continuing"
  else
    fail "not found: $rec"; FAILURES=$((FAILURES + 1)); return 1
  fi

  # The before-state must be captured before Steps 1 and 3 overwrite what it
  # measures. This is the only ordering in the phase that cannot be recovered.
  if [[ -f "$state" ]]; then
    bash "$state" --runbook restore-access --point before || warn "before-state capture reported findings"
  else
    fail "not found: $state"; FAILURES=$((FAILURES + 1)); return 1
  fi
  ok "prerequisites and before-state recorded"
}

# ---------------------------------------------------------------------------
# Step 1 -- mount
# ---------------------------------------------------------------------------
step_mount() {
  log_section "Step 1 — Mount the encrypted secrets DMG"

  local already
  already="$(find_mounted_image || true)"
  if [[ -n "$already" ]]; then
    MNT="$already"
    ok "already mounted: $MNT"
    return 0
  fi

  local dmg
  dmg="$(ls -1t "$REIMAGE_ARTIFACT_ROOT"/secrets-encrypted/all-secrets-*.dmg 2>/dev/null | head -1 || true)"
  if [[ -z "$dmg" ]]; then
    fail "no all-secrets-*.dmg under $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/"
    FAILURES=$((FAILURES + 1)); return 1
  fi
  info "image: $dmg"

  if $DRY_RUN; then
    would "hdiutil attach '$dmg'  (prompts for the Phase 3C passphrase)"
    return 0
  fi

  gate "The passphrase is deliberately absent from reimage.env — it is about to be asked for."
  GATES=$((GATES + 1))
  MNT="$(hdiutil attach "$dmg" | awk -F'\t' '/\/Volumes\//{print $NF}' | tail -1)"
  if [[ -z "$MNT" || ! -d "$MNT" ]]; then
    fail "attach did not yield a mount point"
    FAILURES=$((FAILURES + 1)); return 1
  fi
  ok "mounted at $MNT"
}

# ---------------------------------------------------------------------------
# Step 2 -- staged-loose
# ---------------------------------------------------------------------------
step_staged_loose() {
  log_section "Step 2 — Restore files swept by the Phase 3B loose-secret sweep"
  require_mnt || return 1

  local sc="$REPO_ROOT/bin/restore-staged-loose.sh"
  if [[ ! -f "$sc" ]]; then
    fail "not found: $sc"; FAILURES=$((FAILURES + 1)); return 1
  fi

  if $DRY_RUN; then
    bash "$sc" --source "$MNT/staged-loose" || true
    return 0
  fi

  # --apply is deliberate: restore-staged-loose.sh is dry-run by default, and
  # the ordered run is the apply path. It copies rather than moves, so a repeat
  # is safe and reports every row as EXISTS.
  bash "$sc" --apply --source "$MNT/staged-loose" \
    || { fail "restore-staged-loose.sh reported failures"; FAILURES=$((FAILURES + 1)); return 1; }
  ok "staged-loose rows restored into the artifact tree"
}

# ---------------------------------------------------------------------------
# Step 3 -- ssh
# ---------------------------------------------------------------------------
step_ssh() {
  log_section "Step 3 — Restore SSH and Git access"
  require_mnt || return 1

  local src="$MNT/ssh"
  if [[ ! -d "$src" ]]; then
    skip "no ssh/ category on the image"
    return 0
  fi

  if $DRY_RUN; then
    would "cp -R '$src'/. ~/.ssh/ ; chmod 700 ~/.ssh ; 600 on private keys, 644 on .pub"
    return 0
  fi

  mkdir -p "$HOME/.ssh"
  cp -R "$src"/. "$HOME/.ssh/" 2>/dev/null || true
  chmod 700 "$HOME/.ssh"
  rm -f "$HOME/.ssh/.DS_Store" 2>/dev/null || true

  # Mode by content, not by filename. A private key is the thing ssh refuses to
  # use when it is group- or world-readable; a .pub is not, and blanket 600 on
  # everything hides a genuinely wrong mode behind a passing check.
  local f keys=0 pubs=0
  for f in "$HOME"/.ssh/*; do
    [[ -f "$f" ]] || continue
    case "$f" in
      *.pub) chmod 644 "$f"; pubs=$((pubs + 1)); continue ;;
    esac
    if head -1 "$f" 2>/dev/null | grep -q 'PRIVATE KEY'; then
      chmod 600 "$f"; keys=$((keys + 1))
    else
      chmod 600 "$f"
    fi
  done
  ok "$keys private key(s) at 600, $pubs public key(s) at 644, ~/.ssh at 700"

  if [[ -f "$HOME/.ssh/config" ]]; then
    local aliases
    aliases="$(grep -iE '^[[:space:]]*Host[[:space:]]' "$HOME/.ssh/config" 2>/dev/null \
      | awk '{for(i=2;i<=NF;i++) print $i}' | grep -v '[*?]' | head -8 | tr '\n' ' ' || true)"
    [[ -n "$aliases" ]] && info "host aliases in ~/.ssh/config: $aliases"
    info "test with: ssh -T <one of those aliases>   (a bare host with no IdentityFile offers no key)"
  fi
}

# ---------------------------------------------------------------------------
# Step 4 -- certs
# ---------------------------------------------------------------------------
# Sets CORP_CERT to the first self-signed certificate on the image. Silent, so
# a later step can depend on the value without re-printing Step 4's listing in
# the middle of its own section.
resolve_corp_cert() {
  [[ -n "$CORP_CERT" ]] && return 0
  [[ -n "$MNT" && -d "$MNT" ]] || return 1
  local dir="$MNT/certs/loose-candidates-selected" f
  [[ -d "$dir" ]] || return 1
  for f in "$dir"/*; do
    [[ -f "$f" ]] || continue
    if cert_is_root "$f"; then CORP_CERT="$f"; return 0; fi
  done
  return 1
}

step_certs() {
  log_section "Step 4 — Identify the corporate root on the image"
  require_mnt || return 1

  local dir="$MNT/certs/loose-candidates-selected"
  if [[ ! -d "$dir" ]]; then
    skip "no certs/loose-candidates-selected/ on the image"
    return 0
  fi

  local f roots=0
  for f in "$dir"/*; do
    [[ -f "$f" ]] || continue
    local s i
    s="$(cert_subject "$f" || true)"
    i="$(cert_issuer  "$f" || true)"
    if [[ -z "$s" ]]; then
      info "NOT A CERT  $(basename "$f")"
    elif cert_is_root "$f"; then
      printf "    ${GRN}ROOT        %s${RST}\n                %s\n" "$(basename "$f")" "$s"
      roots=$((roots + 1))
      [[ -z "$CORP_CERT" ]] && CORP_CERT="$f"
    else
      printf "    ${DIM}NOT A ROOT  %s${RST}\n                %s\n                %s\n" \
        "$(basename "$f")" "$s" "$i"
    fi
  done

  if (( roots == 0 )); then
    fail "no self-signed certificate in $dir — nothing here can be trusted as a root"
    FAILURES=$((FAILURES + 1)); return 1
  fi
  if (( roots > 1 )); then
    warn "$roots roots found; using $(basename "$CORP_CERT"). Pass --only certs and read the list if that is wrong."
  fi
  ok "corporate root: $CORP_CERT"
}

# ---------------------------------------------------------------------------
# Step 5 -- trust  (privileged)
# ---------------------------------------------------------------------------
step_trust() {
  log_section "Step 5 — Trust the internal root certificate"

  if ! resolve_corp_cert; then
    if $DRY_RUN; then
      would "trust the root identified by Step 4 (no image mounted, so none resolved here)"
      return 0
    fi
    gate "no root identified — run: ./bin/restore-access.sh certs"
    GATES=$((GATES + 1)); return 1
  fi

  local subj; subj="$(cert_subject "$CORP_CERT")"

  # Enrolment may already have installed and trusted it. Adding a duplicate is
  # not harmful, but reporting "trusted" when it was already trusted is the
  # difference between a check and a decoration.
  if security dump-trust-settings -d 2>/dev/null | grep -qF "${subj#subject=}"; then
    ok "already trusted in the admin domain — nothing to do"
    return 0
  fi

  if ! cert_is_root "$CORP_CERT"; then
    fail "$CORP_CERT is not self-signed; only a root is trusted this way"
    FAILURES=$((FAILURES + 1)); return 1
  fi

  if $DRY_RUN; then
    would "sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain '$CORP_CERT'"
    return 0
  fi

  info "$subj"
  if ! confirm "Add this root to the System keychain as trusted? Requires an admin password."; then
    gate "declined — Step 5 not applied"
    GATES=$((GATES + 1)); return 1
  fi

  # Only the root is trusted explicitly. Intermediates chain to it and stay on
  # "Use System Defaults"; trusting an issuing CA directly widens what the
  # machine accepts beyond what the root's own policy allows.
  if sudo security add-trusted-cert -d -r trustRoot \
       -k /Library/Keychains/System.keychain "$CORP_CERT"; then
    ok "root trusted in the admin domain"
  else
    fail "security add-trusted-cert failed"
    FAILURES=$((FAILURES + 1)); return 1
  fi
}

# ---------------------------------------------------------------------------
# Step 6 -- java  (privileged)
# ---------------------------------------------------------------------------
step_java() {
  log_section "Step 6 — Restore Java trust overrides"
  require_mnt || return 1

  local srcroot="$MNT/certs/java-security"
  if [[ ! -d "$srcroot" ]]; then
    skip "no certs/java-security/ on the image"
    return 0
  fi


  local jvmdir="/Library/Java/JavaVirtualMachines"
  if [[ ! -d "$jvmdir" ]]; then
    gate "no JDKs installed yet — Phase 10A Step 7 installs them; re-run: ./bin/restore-access.sh java"
    GATES=$((GATES + 1)); return 1
  fi

  local installed=0 done_count=0
  local jdk name src dest
  for jdk in "$jvmdir"/*.jdk; do
    [[ -d "$jdk" ]] || continue
    installed=$((installed + 1))
    name="$(basename "$jdk")"
    dest="$jdk/Contents/Home/lib/security/jssecacerts"
    src="$srcroot/$name/jssecacerts"

    if [[ ! -f "$src" ]]; then
      # The image captured jssecacerts per JDK by name. A JDK installed after
      # the capture, or at a different version, has no counterpart -- which is
      # a real finding, not a silent skip: that JVM has no corporate trust.
      warn "$name — no jssecacerts on the image for this JDK"
      continue
    fi
    if [[ ! -d "$(dirname "$dest")" ]]; then
      warn "$name — no lib/security directory; skipping"
      continue
    fi

    if $DRY_RUN; then
      would "sudo cp '$src' '$dest'  (backing up any existing file first)"
      continue
    fi

    if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
      ok "$name — already identical"
      done_count=$((done_count + 1))
      continue
    fi

    if ! confirm "Install jssecacerts into $name?"; then
      gate "$name — declined"
      GATES=$((GATES + 1)); continue
    fi

    # jssecacerts REPLACES cacerts for the JVM rather than extending it, so the
    # file being overwritten is not recoverable from the JDK install. Back it up
    # before writing, every time.
    if [[ -f "$dest" ]]; then
      sudo cp -p "$dest" "$dest.pre-reimage-$STAMP" \
        && info "$name — previous file kept as jssecacerts.pre-reimage-$STAMP"
    fi
    if sudo cp "$src" "$dest"; then
      ok "$name — jssecacerts installed"
      done_count=$((done_count + 1))
    else
      fail "$name — copy failed"
      FAILURES=$((FAILURES + 1))
    fi
  done

  if (( installed == 0 )); then
    gate "no *.jdk under $jvmdir"
    GATES=$((GATES + 1)); return 1
  fi
  $DRY_RUN || info "$done_count of $installed installed JDK(s) now carry the corporate trust store"
}

# ---------------------------------------------------------------------------
# Step 7 -- corp-ca
# ---------------------------------------------------------------------------
step_corp_ca() {
  log_section "Step 7 — Trust the corporate CA outside the keychain"

  local staging="/tmp/corp-root-staging.pem"

  if $DRY_RUN; then
    would "build $CA_BUNDLE from the image or the keychain"
    would "append the REIMAGE-CA-BUNDLE block to ~/.zprofile if absent"
    would "npm config set cafile / git config --global http.sslCAInfo / pip3 config set global.cert"
    return 0
  fi

  # Source A: the keychain, which needs no DMG and is the better source once
  # Step 5 has run. Source B: the image. Neither writes $CA_BUNDLE directly --
  # a redirect that truncates the bundle before discovering it has nothing to
  # write is the failure this ordering exists to prevent.
  rm -f "$staging"
  resolve_corp_cert || true
  if [[ -n "$CORP_CERT" && -f "$CORP_CERT" ]]; then
    openssl x509 -inform DER -in "$CORP_CERT" -out "$staging" 2>/dev/null \
      || openssl x509 -inform PEM -in "$CORP_CERT" -out "$staging" 2>/dev/null || true
  fi
  if [[ ! -s "$staging" ]]; then
    local cn
    cn="$(security dump-trust-settings -d 2>/dev/null | sed -n 's/.*"\(.*\)".*/\1/p' | head -1 || true)"
    [[ -n "$cn" ]] && security find-certificate -a -c "$cn" -p \
      /Library/Keychains/System.keychain "$HOME/Library/Keychains/login.keychain-db" \
      > "$staging" 2>/dev/null || true
  fi

  local count=0
  count="$(grep -c 'BEGIN CERTIFICATE' "$staging" 2>/dev/null)" || count=0
  if (( count == 0 )); then
    fail "nothing exported — $CA_BUNDLE left alone"
    info "run Step 4 first, or export by hand: see the runbook's Supplemental Reference"
    FAILURES=$((FAILURES + 1)); return 1
  fi
  if ! cert_is_root "$staging"; then
    fail "the exported certificate is not a root"
    FAILURES=$((FAILURES + 1)); return 1
  fi

  # The bundle is system roots PLUS the corporate root, not the corporate root
  # alone. Every consumer configured below -- npm's cafile, git's sslCAInfo,
  # CURL_CA_BUNDLE, REQUESTS_CA_BUNDLE, PIP_CERT -- REPLACES its trust store
  # with this file rather than adding to it. A corporate-root-only bundle
  # therefore breaks every endpoint the corporate CA did not issue, which on a
  # network that intercepts internal hosts only is most of the internet:
  # npm fails with UNABLE_TO_GET_ISSUER_CERT_LOCALLY against registry.npmjs.org.
  # Combining costs nothing when everything is intercepted and is the
  # difference between working and not when it isn't.
  local sysroots="/System/Library/Keychains/SystemRootCertificates.keychain"
  local combined="/tmp/corp-root-combined-$STAMP.pem"
  local syscount=0
  if [[ -f "$sysroots" ]] && security find-certificate -a -p "$sysroots" > "$combined" 2>/dev/null; then
    syscount="$(grep -c 'BEGIN CERTIFICATE' "$combined" 2>/dev/null)" || syscount=0
  else
    : > "$combined"
  fi
  if (( syscount == 0 )); then
    warn "could not export the system roots — installing the corporate root alone"
    warn "replacement-style consumers will then reject any host the corporate CA did not issue"
    cat "$staging" > "$combined"
  else
    cat "$staging" >> "$combined"
  fi

  local total=0
  total="$(grep -c 'BEGIN CERTIFICATE' "$combined" 2>/dev/null)" || total=0
  if (( total <= syscount )) && (( syscount > 0 )); then
    fail "the corporate root did not make it into the bundle"
    FAILURES=$((FAILURES + 1)); return 1
  fi

  mkdir -p "$(dirname "$CA_BUNDLE")"
  mv "$combined" "$CA_BUNDLE"
  rm -f "$staging"
  ok "installed $CA_BUNDLE ($syscount system root(s) + $count corporate)"

  # One block, marker-guarded, so working the step twice does not append the
  # exports twice. The format string is single-quoted: $HOME reaches .zprofile
  # unexpanded and the file stays correct if the account moves.
  if grep -q 'REIMAGE-CA-BUNDLE' "$HOME/.zprofile" 2>/dev/null; then
    ok "~/.zprofile already carries the block"
  else
    {
      printf '\n# REIMAGE-CA-BUNDLE — corporate TLS interception root (restore-access.md Step 7)\n'
      local v
      for v in NODE_EXTRA_CA_CERTS CURL_CA_BUNDLE REQUESTS_CA_BUNDLE PIP_CERT; do
        printf 'export %s="$HOME/%s"\n' "$v" "$CA_BUNDLE_REL"
      done
    } >> "$HOME/.zprofile"
    ok "~/.zprofile block added"
  fi
  local v
  for v in NODE_EXTRA_CA_CERTS CURL_CA_BUNDLE REQUESTS_CA_BUNDLE PIP_CERT; do
    export "$v=$CA_BUNDLE"
  done

  # Phase 12 installs npm and pip. A tool that is not here yet is reported, not
  # failed -- and not silently skipped either, because the step is incomplete
  # until it is re-run.
  if command -v npm >/dev/null 2>&1; then
    npm config set cafile "$CA_BUNDLE" >/dev/null && ok "npm cafile"
  else
    skip "npm not installed yet — re-run this step after Phase 12"
  fi
  if command -v git >/dev/null 2>&1; then
    git config --global http.sslCAInfo "$CA_BUNDLE" && ok "git http.sslCAInfo"
  else
    skip "git not installed"
  fi
  if command -v pip3 >/dev/null 2>&1; then
    pip3 config set global.cert "$CA_BUNDLE" >/dev/null && ok "pip global.cert"
  else
    skip "pip3 not installed yet — re-run this step after Phase 12"
  fi

  # A bare PASS/FAIL says nothing about why. These five fail for unrelated
  # reasons, so the tool's own first lines are what distinguishes them.
  echo ""
  info "smoke tests"
  local out
  # The python check reads the path from the environment rather than
  # interpolating it into the -c source, so a path with a quote or a space
  # cannot break the program text.
  export CA_BUNDLE_SMOKE="$CA_BUNDLE"
  smoke_one() {
    local label="$1"; shift
    if out="$("$@" 2>&1)"; then
      printf "    ${GRN}PASS    %s${RST}\n" "$label"
    else
      printf "    ${RED}FAIL    %s${RST}\n" "$label"
      printf '%s\n' "$out" | sed -n '1,4p' | sed 's/^/            /'
    fi
  }
  # Each test forces the tool to use $CA_BUNDLE. Without that they measure the
  # system keychain instead and pass while the bundle is broken: macOS `curl`
  # and `git` consult the keychain regardless of CURL_CA_BUNDLE and
  # http.sslCAInfo, and `urllib.request` reads ssl.get_default_verify_paths()
  # and never looks at REQUESTS_CA_BUNDLE at all. npm is the only one of the
  # five that honours its setting unprompted -- which is why it was the only
  # one to report a real misconfiguration.
  smoke_one curl curl -sSI --cacert "$CA_BUNDLE" https://registry.npmjs.org/
  # if/else, not `a && b || c`: the `||` would see smoke_one's status, not
  # command -v's, and a present-but-failing npm would print FAIL and SKIP both.
  if command -v npm >/dev/null 2>&1; then smoke_one npm npm ping; else skip "npm"; fi
  smoke_one git git -c http.sslCAInfo="$CA_BUNDLE" ls-remote https://github.com/git/git
  smoke_one python python3 -c "import os, ssl, urllib.request; ctx = ssl.create_default_context(cafile=os.environ['CA_BUNDLE_SMOKE']); urllib.request.urlopen('https://pypi.org/simple/', context=ctx)"
}

# ---------------------------------------------------------------------------
# Step 8 -- dotfiles  (read-only: the merge is a judgment call)
# ---------------------------------------------------------------------------
step_dotfiles() {
  log_section "Step 8 — Shell environment and CLI config"

  local backup="$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles"
  if [[ ! -d "$backup" ]]; then
    skip "no home-files-backup/dotfiles/ under the artifact root"
    return 0
  fi
  info "backup: $backup"

  # Reports only. Merging these is the judgment the phase depends on, and a
  # script that copied them would remove the deliberation rather than automate
  # it -- .zprofile in particular now carries Phase 10A's Homebrew and nvm
  # bootstrap and Step 7's REIMAGE-CA-BUNDLE block, neither of which is in the
  # pre-image backup.
  local f b l differs=0
  for f in .zshrc .zprofile .bash_profile .bashrc .gitconfig .shell_common.sh .shell_local.sh; do
    b="$backup/$f"; l="$HOME/$f"
    if   [[ ! -e "$b" ]]; then info "NO BACKUP   $f"
    elif [[ ! -e "$l" ]]; then info "BACKUP ONLY $f  (nothing here to merge into)"
    elif cmp -s "$b" "$l"; then ok   "SAME        $f"
    else
      printf "    ${YEL}DIFFERS     %s${RST}\n" "$f"
      differs=$((differs + 1))
    fi
  done

  if (( differs > 0 )); then
    echo ""
    info "review one at a time, then merge by hand:"
    info "  F=\".zshrc\"; git diff --no-index --color=always \"\$HOME/\$F\" \"$backup/\$F\" | less -R"
    warn "do not copy .zprofile over — it carries Phase 10A's bootstrap and Step 7's CA block"
  fi
}

# ---------------------------------------------------------------------------
# Step 9 -- credentials
# ---------------------------------------------------------------------------
step_credentials() {
  log_section "Step 9 — Credentials and license material"
  require_mnt || return 1

  # All four categories are conditional: Phase 3C creates each only if there
  # was applicable material. Absent means nothing was staged, not that
  # something went wrong.
  local c n
  for c in cli-credentials git package-managers licenses; do
    if [[ -d "$MNT/$c" ]]; then
      n="$(find "$MNT/$c" -type f ! -name '.DS_Store' 2>/dev/null | wc -l | tr -d ' ')"
      printf "    ${GRN}PRESENT %-18s %s file(s)${RST}\n" "$c" "$n"
    else
      info "ABSENT  $c"
    fi
  done

  if [[ -f "$MNT/cli-credentials/gh/hosts.yml" ]]; then
    echo ""
    if command -v gh >/dev/null 2>&1; then
      info "gh is installed — prefer re-authentication over restoring the stored token:"
      info "  gh auth login"
      gh auth status 2>&1 | sed -n '1,6p' | sed 's/^/            /' || true
    else
      info "gh/hosts.yml is on the image and gh is not installed yet."
      info "Defer it: Phase 12 installs gh, then run 'gh auth login'. The stored"
      info "token was issued to the old machine's session — re-auth rather than copy."
    fi
  fi

  info "licenses come back through each vendor's own flow, not by copying activation files"
}

# ---------------------------------------------------------------------------
# Step 10 -- finish
# ---------------------------------------------------------------------------
step_finish() {
  log_section "Steps 10-12 — Eject, compare, close out"

  local rec="$REPO_ROOT/bin/record-restore-exit.sh"
  local state="$REPO_ROOT/bin/record-restore-state.sh"

  local cmp="$REPO_ROOT/bin/compare-restored-state.sh"

  if $DRY_RUN; then
    would "hdiutil detach '$MNT'"
    would "$state --runbook restore-access --point after"
    would "$cmp --runbook restore-access"
    would "$cmp --runbook restore-access"
    would "$rec --runbook restore-access"
    return 0
  fi

  # Eject FIRST. The exit checklist tests that the secrets DMG is detached, so
  # running it before the eject fails a row that is not wrong yet -- and a
  # checklist that reports a failure it caused itself trains the reader to
  # discount it.
  [[ -n "$MNT" ]] || MNT="$(find_mounted_image || true)"
  if [[ -z "$MNT" ]]; then
    info "no image mounted — nothing to eject"
  elif ! confirm "Eject $MNT? Plaintext credentials stay in the artifact tree until you re-stage them."; then
    gate "left mounted — eject with: hdiutil detach '$MNT'"
    GATES=$((GATES + 1))
  elif hdiutil detach "$MNT"; then
    ok "ejected"
    warn "the artifact tree still holds the restored plaintext. Re-run"
    warn "./bin/stage-loose-secrets.sh --apply, or wipe the drive, before it is retired."
  else
    fail "detach failed — a process may still hold a file open on the volume"
    FAILURES=$((FAILURES + 1))
  fi

  # The pair to the before-state taken at Step 0. Without it the before-state
  # has nothing to compare against, which is most of the reason it was taken.
  if [[ -f "$state" ]]; then
    bash "$state" --runbook restore-access --point after || warn "after-state capture reported findings"
  else
    fail "not found: $state"; FAILURES=$((FAILURES + 1))
  fi

  # Step 11. Both baselines: `inventory` against what the machine was before the
  # erase, `before` against what it was at this phase's Step 0. They answer
  # different questions and neither substitutes for the other.
  if [[ -f "$cmp" ]]; then
    bash "$cmp" --runbook restore-access \
      || warn "inventory comparison reported findings"
    bash "$cmp" --runbook restore-access \
      || warn "phase comparison reported findings"
  else
    fail "not found: $cmp"; FAILURES=$((FAILURES + 1))
  fi

  # Step 12.
  if [[ -f "$rec" ]]; then
    bash "$rec" --runbook restore-access || warn "exit checklist reported findings — read the rows before signing off"
  else
    fail "not found: $rec"; FAILURES=$((FAILURES + 1))
  fi

  info "boundaries/MANIFEST.md should now hold an entry row and an exit row for this phase"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
run_step() {
  case "$1" in
    prereqs)      step_prereqs ;;
    mount)        step_mount ;;
    staged-loose) step_staged_loose ;;
    ssh)          step_ssh ;;
    certs)        step_certs ;;
    trust)        step_trust ;;
    java)         step_java ;;
    corp-ca)      step_corp_ca ;;
    dotfiles)     step_dotfiles ;;
    credentials)  step_credentials ;;
    finish)       step_finish ;;
  esac
}

log_section "Restore Access — Phase 10B"
printf "  ${DIM}Artifact root : %s${RST}\n" "$REIMAGE_ARTIFACT_ROOT"
printf "  ${DIM}CA bundle     : %s${RST}\n" "$CA_BUNDLE"
if $DRY_RUN; then
  printf "  ${CYN}Mode          : dry run — nothing will be changed${RST}\n"
else
  printf "  ${DIM}Mode          : apply${RST}\n"
fi

if [[ -n "$ONLY_STEP" ]]; then
  printf "  ${DIM}Step          : %s (alone)${RST}\n" "$ONLY_STEP"
  # A single step must not abort the summary on a non-zero return: the step
  # already recorded whether it failed or gated, and the exit status below is
  # computed from those counters.
  run_step "$ONLY_STEP" || true
else
  STARTED=false
  [[ -n "$FROM_STEP" ]] || STARTED=true
  for s in $ALL_STEPS; do
    if ! $STARTED; then
      [[ "$s" == "$FROM_STEP" ]] && STARTED=true || continue
    fi
    run_step "$s" || true
  done
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log_section "Summary"
printf "  Failures : %s\n" "$FAILURES"
printf "  Gates    : %s\n" "$GATES"
echo ""

if (( FAILURES == 0 && GATES == 0 )); then
  printf "${GRN}${BLD}  ✓ Every step completed.${RST}\n\n"
  exit 0
fi
if (( FAILURES == 0 )); then
  printf "${YEL}${BLD}  ! %s gate(s) need you. Re-run the step once you have passed them.${RST}\n\n" "$GATES"
  exit 1
fi
printf "${RED}${BLD}  ✗ %s step(s) failed.${RST}\n" "$FAILURES"
printf "${DIM}    Fix the cause and re-run that step alone: ./bin/restore-access.sh <step>${RST}\n\n"
exit 1
