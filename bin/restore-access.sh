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
#   # Print the mounted image's path, for a shell that needs $MNT
#   MNT="$(./bin/restore-access.sh mnt)"
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
#   mnt           Not a step: print the mounted image's path and exit.
#
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
#   --jssecacerts MODE    How Step 6 builds each JDK's trust override.
#                         merge (default) starts from that JDK's current cacerts
#                         and imports only the aliases the capture added, keeping
#                         the JDK's public roots current. copy installs the
#                         captured store wholesale, which also replaces those
#                         public roots with the old machine's. Use copy only for
#                         a same-week capture.
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
PRINT_MNT=false
JSSE_MODE="merge"
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
    --jssecacerts)
      require_option_value "$1" "${2:-}"
      case "$2" in
        copy|merge) JSSE_MODE="$2" ;;
        *) echo "ERROR: --jssecacerts takes 'copy' or 'merge', not: $2" >&2; exit 2 ;;
      esac
      shift 2 ;;
    -h|--help)       usage; exit 0 ;;
    mnt)
      # Query, not a step. Answered after the function definitions below, not
      # here: find_mounted_image does not exist yet at parse time, and calling
      # it here reported "no mounted image" for the wrong reason -- a
      # command-not-found on every run, mounted or not.
      PRINT_MNT=true; shift ;;
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
# Shared run index. Step 4 writes a comparison run under comparisons/, the same
# category and grammar restore-runtime's version diff uses.
RUNS_LIB="$REPO_ROOT/.internal/artifact-runs.sh"
if [[ -f "$RUNS_LIB" ]]; then
  # shellcheck source=../.internal/artifact-runs.sh
  source "$RUNS_LIB"
  RUNS_LIB_OK=true
else
  RUNS_LIB_OK=false
fi

# ---------------------------------------------------------------------------
# Certificate inventory
#
# Both sides are reduced to the same TSV so they can be joined on a fingerprint:
#   sha256 <TAB> ca <TAB> notBefore <TAB> notAfter <TAB> subject <TAB> issuer
#     <TAB> source <TAB> expiry <TAB> role
#
# Matching is on SHA-256 and nothing else. The same CA is routinely filed under
# different labels in a keychain than in a file on the image, and comparing on
# name reports a certificate as missing when it is installed under another name.
# ---------------------------------------------------------------------------
cert_row_from_pem() {
  # <pem-or-der-file> <source-label>
  local f="$1" src="$2" form info bc fp ca nb na subj iss expiry role
  for form in PEM DER; do
    openssl x509 -in "$f" -inform "$form" -noout >/dev/null 2>&1 || continue

    # One openssl call for the five text fields rather than five separate ones.
    # On a 131-certificate bundle that is a few hundred processes saved, and the
    # fields are parsed by prefix so the order openssl chooses does not matter.
    info="$(openssl x509 -in "$f" -inform "$form" -noout \
              -subject -issuer -startdate -enddate -fingerprint -sha256 2>/dev/null)"
    subj="$(printf '%s\n' "$info" | sed -n 's/^subject= *//p'      | head -1)"
    iss="$( printf '%s\n' "$info" | sed -n 's/^issuer= *//p'       | head -1)"
    nb="$(  printf '%s\n' "$info" | sed -n 's/^notBefore=//p'      | head -1)"
    na="$(  printf '%s\n' "$info" | sed -n 's/^notAfter=//p'       | head -1)"
    fp="$(  printf '%s\n' "$info" | sed -n 's/.*Fingerprint=//p'   | head -1 | tr -d ':')"

    bc="$(openssl x509 -in "$f" -inform "$form" -noout -text 2>/dev/null \
            | grep -A1 'Basic Constraints' | grep -o 'CA:[A-Z]*' | head -1)"
    ca="${bc:-CA:unknown}"

    if openssl x509 -in "$f" -inform "$form" -checkend 0 -noout >/dev/null 2>&1; then
      expiry=current
    else
      expiry=expired
    fi

    # root / intermediate / leaf -- the distinction that decides whether a
    # certificate is a TRUST decision or merely chain-completion material.
    #
    # A root is self-signed: it vouches for itself, so installing it is an
    # assertion that you believe it. An intermediate is signed by something
    # else, so trusting its root is what makes it valid -- a client almost never
    # needs its own copy, because a correctly configured TLS server sends the
    # intermediates with the leaf in the handshake.
    if [[ "$ca" == "CA:FALSE" ]]; then
      role=leaf
    elif [[ -n "$subj" && "$subj" == "$iss" ]]; then
      role=root
    elif [[ "$ca" == "CA:TRUE" ]]; then
      role=intermediate
    else
      role=unknown
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$fp" "$ca" "$nb" "$na" "$subj" "$iss" "$src" "$expiry" "$role"
    return 0
  done
  return 1
}

# Every certificate the keychains currently hold. `security find-certificate -a -p`
# streams concatenated PEMs; awk splits them so each can be read on its own.
cert_rows_installed() {
  local tmp d n f
  tmp="$(mktemp -d)"
  {
    security find-certificate -a -p 2>/dev/null || true
    security find-certificate -a -p /Library/Keychains/System.keychain 2>/dev/null || true
  } | awk -v d="$tmp" '
      /BEGIN CERTIFICATE/ { if (out) close(out); n++; out = sprintf("%s/c%04d.pem", d, n) }
      n > 0 { print > out }
      END { if (out) close(out) }
    '
  for f in "$tmp"/*.pem; do
    [[ -f "$f" ]] || continue
    cert_row_from_pem "$f" "keychain" || true
  done
  rm -rf "$tmp"
}

# Every certificate the image carries under certs/, EXCLUDING certs/java-security/.
#
# Two things this has to get right, both learned from a real image.
#
# A file is not a certificate. `gaig-cert.pem` and the captured truststores are
# BUNDLES, and `openssl x509 -in <bundle>` reads only the first certificate in
# them -- so a bundle was being represented in the comparison by one arbitrary
# member while the rest were invisible. Every PEM is split first, and each
# certificate is compared on its own, cited as `<path>#<n>`.
#
# certs/java-security/ is deliberately skipped. Those are per-JDK `jssecacerts`
# truststores full of PUBLIC roots, and they are Step 6's business, not Step 5's.
# Including them put certificates like "Actalis Authentication Root CA" under
# "what to install" -- public CAs that belong in a JVM trust store and have no
# business being imported into the login keychain.
cert_rows_image() {
  local f rel tmp n g
  [[ -d "$MNT/certs" ]] || return 0
  tmp="$(mktemp -d)"
  find "$MNT/certs" -type f -print 2>/dev/null \
    | grep -v '/java-security/' | sort | while IFS= read -r f; do
      rel="${f#"$MNT/"}"
      if grep -q 'BEGIN CERTIFICATE' "$f" 2>/dev/null; then
        rm -f "$tmp"/split-*.pem
        awk -v d="$tmp" '
          /BEGIN CERTIFICATE/ { if (out) close(out); n++; out = sprintf("%s/split-%04d.pem", d, n) }
          n > 0 { print > out }
          END { if (out) close(out) }
        ' "$f"
        n=0
        for g in "$tmp"/split-*.pem; do
          [[ -f "$g" ]] || continue
          n=$((n + 1))
          if [[ "$n" -eq 1 ]] && [[ "$(ls -1 "$tmp"/split-*.pem 2>/dev/null | wc -l | tr -d ' ')" -eq 1 ]]; then
            cert_row_from_pem "$g" "$rel" || true
          else
            cert_row_from_pem "$g" "$rel#$n" || true
          fi
        done
      else
        cert_row_from_pem "$f" "$rel" || true
      fi
    done
  rm -rf "$tmp"
}

# Fingerprints of the built-in public roots.
#
# These are NOT in the login or System keychain -- macOS keeps them in
# SystemRootCertificates.keychain -- but they ARE trusted by this Mac. Leaving
# them out of the comparison made every public root on the image look missing:
# on a real image, `gaig-cert.pem` turned out to be a 131-certificate CA bundle
# (the public trust store plus one corporate root), and the report offered all
# 130 public ones for import.
cert_public_root_fingerprints() {
  local store="/System/Library/Keychains/SystemRootCertificates.keychain" tmp f
  [[ -f "$store" ]] || return 0
  tmp="$(mktemp -d)"
  security find-certificate -a -p "$store" 2>/dev/null | awk -v d="$tmp" '
      /BEGIN CERTIFICATE/ { if (out) close(out); n++; out = sprintf("%s/r%04d.pem", d, n) }
      n > 0 { print > out }
      END { if (out) close(out) }
    '
  for f in "$tmp"/*.pem; do
    [[ -f "$f" ]] || continue
    openssl x509 -in "$f" -noout -fingerprint -sha256 2>/dev/null | sed 's/.*=//' | tr -d ':'
  done
  rm -rf "$tmp"
}

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
# A bounded, non-interactive SSH reachability probe.
#
# Two things make the obvious `ssh -T <alias>` a bad test in a runbook.
#
# It can block on the host-key prompt, which a pasted block answers with whatever
# line follows it. `BatchMode=yes` turns an unknown host into an error instead,
# and the key is seeded deliberately with ssh-keyscan beforehand.
#
# It can also hang indefinitely AFTER the host key is accepted. `ConnectTimeout`
# does not help: it bounds the TCP connect, and this stall is later, in the key
# exchange. Observed on this network against github.com -- TCP completes, the
# host key is exchanged, and the session stalls at SSH2_MSG_KEX_ECDH_REPLY,
# which is the first large packet. That is a path-MTU black hole through the VPN
# tunnel, not a problem with any key. So the probe carries its own watchdog.
ssh_probe() {
  local alias_name="$1" host out rc pid watchdog
  host="$(awk -v a="$alias_name" '
      $1 == "Host" && $2 == a { inb = 1; next }
      $1 == "Host" { inb = 0 }
      inb && $1 == "HostName" { print $2; exit }
    ' "$HOME/.ssh/config" 2>/dev/null)"
  host="${host:-$alias_name}"

  # Seed the host key deliberately rather than letting the probe prompt for it.
  if ! ssh-keygen -F "$host" >/dev/null 2>&1; then
    ssh-keyscan -T 5 "$host" >> "$HOME/.ssh/known_hosts" 2>/dev/null \
      && info "$alias_name — host key for $host added to known_hosts"
  fi

  out="$(mktemp)"
  ssh -o BatchMode=yes -o ConnectTimeout=8 -T "$alias_name" >"$out" 2>&1 &
  pid=$!
  ( sleep 20; kill -TERM "$pid" 2>/dev/null ) >/dev/null 2>&1 &
  watchdog=$!
  wait "$pid" 2>/dev/null; rc=$?
  kill "$watchdog" 2>/dev/null || true

  if grep -qi 'successfully authenticated\|Hi \|You.ve successfully' "$out"; then
    ok "$alias_name — $(head -1 "$out")"
  elif (( rc == 143 )) || (( rc == 124 )); then
    warn "$alias_name — no response within 20s; the connection stalled after the host key"
    warn "$alias_name — see Troubleshooting: an SSH alias hangs after the host key is accepted"
  elif [[ -s "$out" ]]; then
    warn "$alias_name — $(head -1 "$out")"
  else
    warn "$alias_name — no output, exit $rc"
  fi
  rm -f "$out"
}

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
    local a
    for a in $aliases; do ssh_probe "$a"; done
  fi
}

# ---------------------------------------------------------------------------
# Step 4 -- certs
# ---------------------------------------------------------------------------
# Sets CORP_CERT to the first self-signed certificate on the image. Silent, so
# a later step can depend on the value without re-printing Step 4's listing in
# the middle of its own section.
# The corporate root is the self-signed certificate on the image that the public
# trust store does NOT already contain. Nothing else distinguishes it: it is a
# root like any other, and its name is whatever the organisation chose.
#
# Selecting "the first file that parses as self-signed" was wrong twice over on a
# real image. `openssl x509` reads only the FIRST certificate in a file, and
# `gaig-cert.pem` turned out to be a 131-certificate CA bundle whose first entry
# is a public root -- so the check passed on a public CA, and the phase pinned it
# as the corporate root.
#
# Single-certificate files are preferred over bundle members. A capture that
# holds the root both on its own and inside a bundle should cite the standalone
# file, which is the one a person would recognise.
resolve_corp_cert() {
  [[ -n "$CORP_CERT" ]] && return 0
  [[ -n "$MNT" && -d "$MNT" ]] || return 1
  local dir="$MNT/certs/loose-candidates-selected"
  [[ -d "$dir" ]] || return 1

  local sys_tmp f fp n
  sys_tmp="$(mktemp)"
  cert_public_root_fingerprints | sort -u > "$sys_tmp"

  # Standalone files first, then anything else.
  for f in "$dir"/*; do
    [[ -f "$f" ]] || continue
    n="$(grep -c 'BEGIN CERTIFICATE' "$f" 2>/dev/null || echo 1)"
    [[ "${n:-1}" -le 1 ]] || continue
    cert_is_root "$f" || continue
    fp="$(openssl x509 -in "$f" -noout -fingerprint -sha256 2>/dev/null | sed 's/.*=//' | tr -d ':')"
    [[ -z "$fp" ]] && fp="$(openssl x509 -inform DER -in "$f" -noout -fingerprint -sha256 2>/dev/null | sed 's/.*=//' | tr -d ':')"
    if [[ -n "$fp" ]] && ! grep -qx "$fp" "$sys_tmp"; then
      CORP_CERT="$f"; rm -f "$sys_tmp"; return 0
    fi
  done
  rm -f "$sys_tmp"
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

  local sys_tmp; sys_tmp="$(mktemp)"
  cert_public_root_fingerprints | sort -u > "$sys_tmp"

  local f b n fp roots=0
  for f in "$dir"/*; do
    [[ -f "$f" ]] || continue
    b="$(basename "$f")"
    n="$(grep -c 'BEGIN CERTIFICATE' "$f" 2>/dev/null || echo 1)"
    if [[ "${n:-1}" -gt 1 ]]; then
      info "BUNDLE      $b — $n certificates; a truststore, not a certificate to import"
      continue
    fi
    local s_ i_
    s_="$(cert_subject "$f" || true)"
    i_="$(cert_issuer  "$f" || true)"
    if [[ -z "$s_" ]]; then
      info "NOT A CERT  $b"
      continue
    fi
    fp="$(openssl x509 -in "$f" -noout -fingerprint -sha256 2>/dev/null | sed 's/.*=//' | tr -d ':')"
    [[ -z "$fp" ]] && fp="$(openssl x509 -inform DER -in "$f" -noout -fingerprint -sha256 2>/dev/null | sed 's/.*=//' | tr -d ':')"
    if cert_is_root "$f"; then
      if [[ -n "$fp" ]] && grep -qx "$fp" "$sys_tmp"; then
        printf "    ${DIM}PUBLIC ROOT %s${RST}\n                %s\n" "$b" "${s_#subject=}"
      else
        printf "    ${GRN}ROOT        %s${RST}\n                %s\n" "$b" "${s_#subject=}"
        roots=$((roots + 1))
        [[ -z "$CORP_CERT" ]] && CORP_CERT="$f"
      fi
    else
      printf "    ${DIM}NOT A ROOT  %s${RST}\n                %s\n                %s\n" \
        "$b" "${s_#subject=}" "${i_#issuer=}"
    fi
  done
  rm -f "$sys_tmp"

  if (( roots == 0 )); then
    fail "no self-signed certificate in $dir that is not already a public root"
    FAILURES=$((FAILURES + 1)); return 1
  fi
  if (( roots > 1 )); then
    warn "$roots corporate root(s) found; using $(basename "$CORP_CERT"). Pass --only certs and read the list if that is wrong."
  fi
  ok "corporate root: $CORP_CERT"

  cert_comparison
}

# ---------------------------------------------------------------------------
# Step 4 -- the comparison artifact
#
# Enrollment installs the corporate chain through a configuration profile, so on a
# managed Mac most of what the image carries is already present before this phase
# starts. What the operator needs is the GAP, and the gap is invisible from
# either listing alone.
#
# The installed copy is the one to keep: it arrived through the channel that also
# carries its trust settings and that MDM will re-deliver, whereas a file on the
# image is a snapshot of a chain that may since have been rotated. So the image
# side is a candidate list, not a source of truth, and only "image only" rows are
# ever imported.
# ---------------------------------------------------------------------------
cert_comparison() {
  local cmp_root inst_tmp img_tmp rows_tmp n_both n_inst n_img

  if [[ "$RUNS_LIB_OK" != true ]]; then
    warn "shared run index not available; skipping the certificate comparison artifact"
    return 0
  fi
  if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" || ! -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    warn "artifact root not mounted; skipping the certificate comparison artifact"
    return 0
  fi
  if $DRY_RUN; then
    would "compare the installed keychain certificates against the image and write a comparison run"
    return 0
  fi

  cmp_root="$REIMAGE_ARTIFACT_ROOT/reimaged-system/comparisons"
  inst_tmp="$(mktemp)"; img_tmp="$(mktemp)"; rows_tmp="$(mktemp)"

  cert_rows_installed | sort -u > "$inst_tmp"
  cert_rows_image     | sort -u > "$img_tmp"
  local sys_tmp; sys_tmp="$(mktemp)"
  cert_public_root_fingerprints | sort -u > "$sys_tmp"
  local n_sys; n_sys="$(wc -l < "$sys_tmp" | tr -d ' ')"

  # The corporate root's subject, used below to decide which of the leftovers
  # actually belong to this organisation. Taken through cert_row_from_pem so the
  # DN is normalised exactly as it is in the rows it will be matched against.
  local corp_subject=""
  if resolve_corp_cert; then
    corp_subject="$(cert_row_from_pem "$CORP_CERT" corp 2>/dev/null | cut -f5 || true)"
  fi

  # Six buckets. The first three answer "is this already trusted, and how"; the
  # last three answer "if not, is it something I should do anything about" --
  # which is a separate question, and the one an operator actually has.
  #
  # `image-corporate` is the only action. A certificate qualifies by CHAINING to
  # the corporate root, transitively: the root itself, anything the root issued,
  # anything those issued, and so on. Both sides feed the closure, so a corporate
  # intermediate that enrollment already installed still vouches for its own
  # children on the image.
  #
  # Everything else on the image that is neither installed nor a built-in public
  # root is a leftover from whatever the capture swept up, and the two reasons it
  # is a leftover need different handling, so they are separated:
  #   image-expired    -- already past notAfter. Installing it cannot help.
  #   image-unmatched  -- current, but chains to nothing this organisation owns.
  #                       Usually a public root that has since been rotated out of
  #                       the system store, or one deliberately distrusted.
  # Neither is thrown away: both are listed in deferred.md with their reason.
  awk -F'\t' -v sysf="$sys_tmp" -v instf="$inst_tmp" -v corp="$corp_subject" '
    FILENAME == sysf  { sys[$1] = 1; next }
    FILENAME == instf { inst[$1] = $0; Isubof[$1] = $5; Iissof[$1] = $6
                        nI++; Isub[nI] = $5; Iiss[nI] = $6; next }
    { nM++; Mrow[nM] = $0; Msha[nM] = $1; Msub[nM] = $5; Miss[nM] = $6; Mexp[nM] = $8
      imgsha[$1] = 1 }
    END {
      if (corp != "") {
        corpsub[corp] = 1
        changed = 1
        while (changed) {
          changed = 0
          for (i = 1; i <= nI; i++)
            if ((Iiss[i] in corpsub) && !(Isub[i] in corpsub)) { corpsub[Isub[i]] = 1; changed = 1 }
          for (i = 1; i <= nM; i++)
            if ((Miss[i] in corpsub) && !(Msub[i] in corpsub)) { corpsub[Msub[i]] = 1; changed = 1 }
        }
      }
      for (i = 1; i <= nM; i++) {
        member = ((Msub[i] in corpsub) || (Miss[i] in corpsub))
        if (Msha[i] in inst)           side = "both"
        else if (Msha[i] in sys)       side = "public-root"
        else if (Mexp[i] == "expired") side = "image-expired"
        else if (member)               side = "image-corporate"
        else                           side = "image-unmatched"
        printf "%s\t%s\t%s\n", side, Mrow[i], (member ? "corp" : "-")
      }
      # The chain marker is carried on the installed rows too. Without it the
      # chain picture below would show only the half that is on the image, which
      # is exactly the half that does not explain how the pieces relate.
      for (k in inst)
        if (!(k in imgsha))
          printf "installed-only\t%s\t%s\n", inst[k],
                 (((Isubof[k] in corpsub) || (Iissof[k] in corpsub)) ? "corp" : "-")
    }
  ' "$sys_tmp" "$inst_tmp" "$img_tmp" \
    | sort -t"$(printf '\t')" -k1,1 -k6,6 > "$rows_tmp"
  rm -f "$sys_tmp"

  # Counted by DISTINCT certificate, not by row. The image stages the same
  # certificate more than once -- a PEM and a DER of one root -- so counting rows
  # overstates how many certificates are involved.
  _distinct() { awk -F'\t' -v w="$1" '$1==w{print $2}' "$rows_tmp" | sort -u | wc -l | tr -d ' '; }
  n_both="$(_distinct both)"
  n_inst="$(_distinct installed-only)"
  n_pub="$(_distinct public-root)"
  n_corp="$(_distinct image-corporate)"
  n_exp="$(_distinct image-expired)"
  n_unk="$(_distinct image-unmatched)"
  # `n_img` is what Step 5 will actually import; the deferred count is everything
  # else the image carries that is not already trusted.
  n_img="$n_corp"
  n_defer="$(awk -F'\t' '$1=="image-expired" || $1=="image-unmatched"{print $2}' "$rows_tmp" | sort -u | wc -l | tr -d ' ')"
  n_imgonly="$(awk -F'\t' '$1 ~ /^image-/{print $2}' "$rows_tmp" | sort -u | wc -l | tr -d ' ')"
  n_inst_total="$(cut -f1 "$inst_tmp" | sort -u | wc -l | tr -d ' ')"
  n_img_files="$(wc -l < "$img_tmp" | tr -d ' ')"
  n_img_srcfiles="$(cut -f7 "$img_tmp" | sed 's/#[0-9]*$//' | sort -u | wc -l | tr -d ' ')"
  n_img_distinct="$(cut -f1 "$img_tmp" | sort -u | wc -l | tr -d ' ')"

  if ! artifact_run_begin "$cmp_root" "restore-access-cert-diff"; then
    warn "could not stage a comparison run under $cmp_root"
    rm -f "$inst_tmp" "$img_tmp" "$rows_tmp"
    return 0
  fi

  { printf 'side\tsha256\tca\tnot_before\tnot_after\tsubject\tissuer\tsource\texpiry\trole\tchain\n'
    cat "$rows_tmp"; } > "$ARTIFACT_RUN_DIR/rows.tsv"

  # One row per DISTINCT certificate. A certificate staged twice on the image --
  # once as PEM, once as DER -- is one thing to decide about, not two, so the
  # source paths are collapsed into the row rather than repeating it.
  _cert_table() {
    printf '| Subject | Issuer | CA | Expires | SHA-256 | Source |\n'
    printf '| --- | --- | --- | --- | --- | --- |\n'
    awk -F'\t' -v want="$1" '
      $1 == want {
        key = $2
        if (!(key in seen)) { seen[key] = 1; order[++k] = key
          # `exp` is an awk built-in (exponential) and cannot be an array name;
          # using it made the whole table a syntax error and printed nothing.
          subj[key] = $6; iss[key] = $7; ca[key] = $3; expiry[key] = $5 }
        src[key] = (key in src && src[key] != "") ? src[key] "; " $8 : $8
      }
      END {
        for (i = 1; i <= k; i++) { key = order[i]
          printf "| %s | %s | %s | %s | `%s…` | `%s` |\n",
            subj[key], iss[key], ca[key], expiry[key], substr(key, 1, 16), src[key] }
      }' "$rows_tmp"
    printf '\n'
  }

  # Every corporate-chain certificate on either side, one row per distinct
  # certificate, root first. This is the section that answers "how do these
  # relate to each other" -- a question the four buckets cannot answer, because
  # they sort by WHERE a certificate is and this sorts by WHAT it is.
  #
  # Sorting is done by piping a rank prefix through sort: one-true-awk has no
  # asort, and roots must come before intermediates for the table to read as a
  # chain rather than a list.
  _chain_table() {
    printf '| Role | Subject | Issuer | Where | Valid until | SHA-256 |\n'
    printf '| --- | --- | --- | --- | --- | --- |\n'
    awk -F'\t' '
      $11 == "corp" {
        if ($2 in seen) next
        seen[$2] = 1
        where = ($1 == "both")            ? "keychain + image" :
                ($1 == "installed-only")  ? "keychain only (enrollment)" :
                ($1 == "image-corporate") ? "**image only**" :
                ($1 == "image-expired")   ? "image only, expired" :
                ($1 == "public-root")     ? "system roots" : "image only"
        rank = ($10 == "root") ? 1 : ($10 == "intermediate") ? 2 : 3
        printf "%d\t| %s | %s | %s | %s | %s | `%s…` |\n",
          rank, $10, $6, $7, where, $5, substr($2, 1, 16)
      }' "$rows_tmp" | sort -n -k1,1 | cut -f2-
    printf '\n'
  }

  n_chain="$(awk -F'\t' '$11=="corp"{print $2}' "$rows_tmp" | sort -u | wc -l | tr -d ' ')"
  n_corp_int="$(awk -F'\t' '$1=="image-corporate" && $10=="intermediate"{print $2}' "$rows_tmp" | sort -u | wc -l | tr -d ' ')"
  n_corp_root="$(awk -F'\t' '$1=="image-corporate" && $10=="root"{print $2}' "$rows_tmp" | sort -u | wc -l | tr -d ' ')"

  { printf '# restore-access — certificate comparison — %s\n\n' "$ARTIFACT_RUN_STAMP"
    printf 'Generated by `bin/restore-access.sh certs` on %s.\n\n' "$(date)"

    printf '## What to install\n\n'
    if [[ "${n_img:-0}" -eq 0 ]]; then
      printf '**Nothing.** Of the %s certificate(s) the image carries, none is both\n' "$n_img_distinct"
      printf 'missing from this Mac and part of the corporate chain. Step 5 becomes a\n'
      printf 'verification rather than an action.\n\n'
      if [[ "${n_defer:-0}" -gt 0 ]]; then
        printf 'That is not the same as "nothing was left behind": %s certificate(s) were\n' "$n_defer"
        printf 'deliberately not installed, and they are listed in `deferred.md` beside this\n'
        printf 'file with the reason for each.\n\n'
      fi
    else
      printf '**%s certificate(s).** Each one chains to the corporate root\n' "$n_img"
      printf '(`%s`), is not in a keychain, is not a built-in public\n' "${corp_subject:-unresolved}"
      printf 'root, and has not expired. Nothing else in this file is an action.\n\n'
      _cert_table image-corporate
      printf 'Check `CA` before Step 5. A `CA:FALSE` row is a **leaf**, usually the old\n'
      printf 'machine'"'"'s client identity, which re-enrollment reissues — never mark one\n'
      printf 'Always Trust.\n\n'

      # An intermediate is not a trust decision, and saying so here is the
      # difference between a list of two actions and a list of none. Servers
      # send their intermediates in the handshake; the client needs the root.
      if [[ "${n_corp_root:-0}" -eq 0 && "${n_corp_int:-0}" -gt 0 ]]; then
        printf '> **All %s are intermediates, and the root above them is already\n' "$n_corp_int"
        printf '> installed — so none of this is likely to be necessary.** An\n'
        printf '> intermediate is not a trust anchor: it is valid because the root\n'
        printf '> signed it, and a correctly configured TLS server sends its\n'
        printf '> intermediates along with the leaf in the handshake. A client needs its\n'
        printf '> own copy only against a server that fails to send the chain, and the\n'
        printf '> fix for that is normally the server.\n'
        printf '>\n'
        printf '> Installing them anyway is harmless, and it costs nothing to leave them\n'
        printf '> out and come back if an internal host fails to verify. See **The\n'
        printf '> corporate chain** below for how these fit with what enrollment\n'
        printf '> already delivered.\n\n'
      fi
    fi

    printf '## Deferred — decided against, not lost\n\n'
    if [[ "${n_defer:-0}" -eq 0 ]]; then
      printf 'Nothing. Every certificate on the image is accounted for above.\n\n'
    else
      printf '%s certificate(s) the image carries are missing from this Mac and were **not**\n' "$n_defer"
      printf 'put under **What to install**, for one of two reasons:\n\n'
      printf '| | Certificates | Why it is not an action |\n| --- | --- | --- |\n'
      printf '| Expired | %s | Past `notAfter`. Installing it cannot make anything work. |\n' "$n_exp"
      printf '| Not the corporate chain | %s | Current, but issued by nobody this organisation owns — a public CA the capture swept up, often one since rotated out of the system store or deliberately distrusted. |\n' "$n_unk"
      printf '\n'
      printf 'They are itemised, with subject, issuer, dates, fingerprint, source path and\n'
      printf 'the command to inspect each one, in **`deferred.md`** next to this file.\n'
      printf 'Read that before installing any of them.\n\n'
      printf 'This is a snapshot, not a verdict. Re-running `./bin/restore-access.sh certs`\n'
      printf 'rebuilds the comparison from the live keychains, so anything installed since\n'
      printf 'leaves the deferred list on its own and a new dated run records what is still\n'
      printf 'outstanding.\n\n'
    fi

    if [[ "${n_chain:-0}" -gt 0 ]]; then
      printf '## The corporate chain\n\n'
      printf 'Every certificate on either side that chains to `%s`,\n' "${corp_subject:-the corporate root}"
      printf 'root first. The buckets above sort by *where* a certificate is; this sorts\n'
      printf 'by *what it is*, which is what makes the pieces legible as one structure.\n\n'
      _chain_table
      printf 'Reading it:\n\n'
      printf '- A **root** is self-signed — it vouches for itself, so installing one is an\n'
      printf '  assertion that you believe it. That is the trust decision, and there is\n'
      printf '  normally exactly one.\n'
      printf '- An **intermediate** is signed by the root. It is valid because the root is\n'
      printf '  trusted, so it is not a separate trust decision; it is chain-completion\n'
      printf '  material, and a TLS server normally supplies it in the handshake.\n'
      printf '- A **leaf** is an endpoint or client identity. Never mark one Always Trust.\n\n'
      printf 'Two intermediates with **different subjects** under one root are *sibling*\n'
      printf 'issuing CAs, not versions of each other — a two-tier PKI commonly runs one\n'
      printf 'per network zone or directory namespace, which the `DC=` components name.\n'
      printf 'Neither supersedes the other, and enrollment installing one says nothing\n'
      printf 'about whether you need the other.\n\n'
      printf 'Two certificates with the **same subject** and different fingerprints are one\n'
      printf 'CA renewed: the same issuing authority, re-issued with a new validity window.\n'
      printf 'They are one decision, not two.\n\n'
      printf 'An intermediate whose `notAfter` matches the root'"'"'s exactly is not a\n'
      printf 'coincidence and not evidence that two certificates are the same one — an\n'
      printf 'intermediate cannot outlive its issuer, so a CA that issues with a clamped\n'
      printf 'lifetime stamps every one of them with the root'"'"'s own expiry.\n\n'
    fi

    printf '## How that number was reached\n\n'
    printf '| | Distinct certificates |\n| --- | --- |\n'
    printf '| On the image (`%s/certs`, %s certificate(s) in %s file(s)) | %s |\n' \
      "$MNT" "$n_img_files" "$n_img_srcfiles" "$n_img_distinct"
    printf '| — of those, already a built-in public root | %s |\n' "$n_pub"
    printf '| — of those, already in the login or System keychain | %s |\n' "$n_both"
    printf '| — of those, on the image and on neither list | %s |\n' "$n_imgonly"
    printf '| — — of those, **still to install** (corporate chain, current) | %s |\n' "$n_img"
    printf '| — — of those, deferred: expired | %s |\n' "$n_exp"
    printf '| — — of those, deferred: not the corporate chain | %s |\n' "$n_unk"
    printf '| In the login and System keychains | %s |\n' "$n_inst_total"
    printf '| — of those, not on the image | %s |\n' "$n_inst"
    printf '\n'
    printf 'The corporate chain is resolved by issuer, transitively from the root pinned\n'
    printf 'above — the root, whatever it issued, whatever those issued. Certificates\n'
    printf 'already in a keychain take part in that walk, so a corporate intermediate\n'
    printf 'enrollment installed still vouches for its children on the image.\n\n'
    printf 'Matched on SHA-256, never on label: the same CA is routinely filed under a\n'
    printf 'different name in a keychain than in a file, and matching on name reports a\n'
    printf 'certificate as missing when it is installed under another one.\n\n'
    printf 'Bundles are split: a file holding several certificates contributes each of\n'
    printf 'them separately, cited as `<path>#<n>`. A count of certificates is therefore\n'
    printf 'higher than a count of files, and that is the honest number here.\n\n'
    printf '`certs/java-security/` is **not** included. Those are per-JDK `jssecacerts`\n'
    printf 'truststores, full of public roots, and they belong to Step 6 — a JVM trust\n'
    printf 'store is not something to import into the login keychain.\n\n'
    printf 'A capture can carry a whole CA bundle. Where it does, most of what it holds\n'
    printf 'is the public trust store this Mac already has — those are counted as public\n'
    printf 'roots above and are not an action. The corporate certificates are the few that\n'
    printf 'remain once they are subtracted.\n\n'
    printf 'The **keychain** rows below cover the login and System keychains only.\n'
    printf 'Built-in public roots live in SystemRootCertificates.keychain and are used for\n'
    printf 'matching but not listed, because there are roughly 150 of them and none is\n'
    printf 'ever an action.\n\n'

    printf '## Already installed by enrollment\n\n'
    if [[ "${n_both:-0}" -eq 0 ]]; then
      printf 'None of the image'"'"'s certificates is installed. On a managed Mac that is\n'
      printf 'itself the finding: enrollment did not deliver the chain, which is a different\n'
      printf 'problem from a missing file and has a different fix.\n\n'
    else
      printf 'Keep these. They arrived through the channel that also carries their trust\n'
      printf 'settings and that MDM re-delivers; the copy on the image is a snapshot of a\n'
      printf 'chain that may since have been rotated. Do not import over them.\n\n'
      _cert_table both
    fi

    if [[ "${n_pub:-0}" -gt 0 ]]; then
      printf '## Already trusted as public roots\n\n'
      printf '%s certificate(s) the image carries are built-in public roots this Mac\n' "$n_pub"
      printf 'already trusts — almost always because the capture included a CA bundle\n'
      printf 'rather than individual certificates. Not listed: none is an action, and\n'
      printf 'listing them is what made this report unreadable. They are in `rows.tsv`\n'
      printf 'under `public-root` if you want them.\n\n'
    fi

    printf '## In the keychains only\n\n'
    printf 'Present in the login or System keychain and not on the image — what enrollment\n'
    printf 'delivered that Phase 3A never captured, plus this machine'"'"'s reissued\n'
    printf 'identities. Listed for completeness; nothing here is an action.\n\n'
    _cert_table installed-only
  } > "$ARTIFACT_RUN_DIR/comparison.md"

  # -------------------------------------------------------------------------
  # deferred.md -- the record of what was NOT installed.
  #
  # Every certificate the phase declines to import is a decision, and a decision
  # with no record is indistinguishable later from an oversight. Six months on,
  # an internal host failing TLS is exactly the symptom of a missing CA, and the
  # only useful question is "was one of these it?" -- which needs the list, the
  # reason, and the source path, not a recollection.
  #
  # It is written even when it is empty, so its absence always means an old run
  # rather than a clean one.
  # -------------------------------------------------------------------------
  _deferred_table() {
    printf '| Why | Subject | Issuer | CA | Expires | SHA-256 | Source |\n'
    printf '| --- | --- | --- | --- | --- | --- | --- |\n'
    awk -F'\t' '
      $1 == "image-expired" || $1 == "image-unmatched" {
        key = $2
        if (!(key in seen)) { seen[key] = 1; order[++k] = key
          why[key]  = ($1 == "image-expired") ? "expired" : "not the corporate chain"
          subj[key] = $6; iss[key] = $7; ca[key] = $3; expiry[key] = $5 }
        src[key] = (key in src && src[key] != "") ? src[key] "; " $8 : $8
      }
      END {
        for (i = 1; i <= k; i++) { key = order[i]
          printf "| %s | %s | %s | %s | %s | `%s…` | `%s` |\n",
            why[key], subj[key], iss[key], ca[key], expiry[key], substr(key, 1, 16), src[key] }
      }' "$rows_tmp"
    printf '\n'
  }

  { printf '# restore-access — certificates NOT installed — %s\n\n' "$ARTIFACT_RUN_STAMP"
    printf 'Written by `bin/restore-access.sh certs` on %s.\n' "$(date)"
    printf 'Companion to `comparison.md` in this directory.\n\n'

    if [[ "${n_defer:-0}" -eq 0 ]]; then
      printf 'Nothing was deferred. Every certificate on the image is either already in a\n'
      printf 'keychain, already a built-in public root, or listed under **What to install**\n'
      printf 'in `comparison.md`.\n\n'
    else
      printf '%s certificate(s) are on the image, absent from this Mac'"'"'s login and System\n' "$n_defer"
      printf 'keychains, and not built-in public roots — and Step 5 does **not** install\n'
      printf 'them. This file says which ones and why, so the decision can be revisited\n'
      printf 'later instead of re-derived.\n\n'

      printf '## If something breaks later, start here\n\n'
      printf 'A missing CA has a recognisable shape: TLS failing against an internal host,\n'
      printf 'a build that cannot verify a repository or artifact server, a proxy or VPN\n'
      printf 'client rejecting a certificate it should accept. If a missing CA is the\n'
      printf 'cause, it is on the list below.\n\n'
      printf 'Read the `Why` column first.\n\n'
      printf '- **`expired`** is rarely the cause. The certificate is past `notAfter`, so\n'
      printf '  nothing can chain to it today; installing it changes nothing. If a host\n'
      printf '  still needs that authority, what it needs is the *renewed* one, which\n'
      printf '  arrives through enrollment rather than from this image.\n'
      printf '- **`not the corporate chain`** can be the cause. The certificate is current\n'
      printf '  but was issued by nobody this organisation owns — typically a public CA the\n'
      printf '  Phase 3A capture swept up. Most were dropped from the system trust store on\n'
      printf '  purpose (Apple and Mozilla distrust CAs from time to time, and a distrusted\n'
      printf '  root is one you want to leave uninstalled). But a niche vendor or partner\n'
      printf '  endpoint can legitimately depend on one, and that is the case worth\n'
      printf '  checking against the failing hostname.\n\n'

      printf '## Deferred certificates\n\n'
      _deferred_table

      printf '## Inspect one before deciding\n\n'
      printf 'Mount the image (`./bin/restore-access.sh mnt` prints the path), then read the\n'
      printf 'certificate named in the `Source` column:\n\n'
      printf '```bash\n'
      printf 'MNT="$(./bin/restore-access.sh mnt)"\n'
      printf 'openssl x509 -in "$MNT/<source>" -noout -text\n'
      printf '```\n\n'
      printf 'A source written `<path>#<n>` is the n-th certificate inside a bundle, and\n'
      printf '`openssl x509` reads only the first one in a file. Pull that member out first:\n\n'
      printf '```bash\n'
      printf 'awk -v n=<n> '"'"'/BEGIN CERTIFICATE/{i++} i==n'"'"' "$MNT/<path>" | openssl x509 -noout -text\n'
      printf '```\n\n'
      printf 'What decides it:\n\n'
      printf '- **Issuer.** Self-signed (issuer equals subject) means it is claiming to be a\n'
      printf '  root, and installing a root is a trust decision, not a convenience.\n'
      printf '- **Validity window.** Anything already past `notAfter` is inert.\n'
      printf '- **Whether anything actually asks for it.** The honest test is a failing\n'
      printf '  connection: `openssl s_client -connect <host>:443 -showcerts </dev/null`\n'
      printf '  prints the chain the host offers, and its top certificate is the authority\n'
      printf '  that has to be trusted. If that certificate is not on this list, nothing\n'
      printf '  here is your problem.\n\n'

      printf '## If you decide one is needed\n\n'
      printf 'Import it, then mark trust only if it is a root the connection requires:\n\n'
      printf '```bash\n'
      printf 'security import "$MNT/<source>" -k ~/Library/Keychains/login.keychain-db\n'
      printf '```\n\n'
      printf 'Record why in the phase'"'"'s notes. A root installed by hand carries no MDM\n'
      printf 'trail, so the next person to look — including you after the next reimage —\n'
      printf 'has only what you write down.\n\n'
    fi

    printf '## Refresh this list\n\n'
    printf 'This is a snapshot taken at %s. It is not maintained.\n\n' "$ARTIFACT_RUN_STAMP"
    printf '```bash\n'
    printf './bin/restore-access.sh certs\n'
    printf '```\n\n'
    printf 'That rebuilds the comparison from the live keychains and writes a new dated run\n'
    printf 'under `comparisons/`. Anything installed since drops off the deferred list by\n'
    printf 'itself, so the newest run is always the current answer to "what is still\n'
    printf 'outstanding" — and the older runs stay as the record of what was outstanding\n'
    printf 'when.\n'
  } > "$ARTIFACT_RUN_DIR/deferred.md"

  rm -f "$inst_tmp" "$img_tmp" "$rows_tmp"

  if ! artifact_run_finalize "$cmp_root" \
       "$n_img to install / $n_defer deferred / $n_both already installed / $n_inst keychain-only"; then
    warn "the comparison was written but could not be indexed"
    return 0
  fi

  ok "certificate comparison: $ARTIFACT_RUN_DIR/comparison.md"
  if [[ "${n_img:-0}" -eq 0 ]]; then
    ok "nothing to install — no certificate on the image is both missing and part of the corporate chain"
  else
    info "$n_img certificate(s) to install (of $n_img_distinct on the image: $n_pub public roots, $n_both already in a keychain)"
  fi
  if [[ "${n_defer:-0}" -gt 0 ]]; then
    info "$n_defer deferred ($n_exp expired, $n_unk outside the corporate chain) — see $ARTIFACT_RUN_DIR/deferred.md"
  fi
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

  # Enrollment may already have installed and trusted it. Adding a duplicate is
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
# ---------------------------------------------------------------------------
# Step 6 -- Java trust overrides
#
# jssecacerts does not ADD to cacerts: the JVM uses it INSTEAD of cacerts when it
# exists. So installing the captured file replaces the JDK's entire trust set
# with the old machine's, public roots included, frozen at the date of capture.
# Over a long enough gap that matters -- vendors distrust public CAs between
# releases, and an old store keeps trusting what the new JDK deliberately
# dropped.
#
# Hence two forms, and the choice is the operator's:
#
#   copy    Install the captured store wholesale. One file operation. Correct
#           when the capture is recent -- same week, same month.
#
#   merge   Start from THIS JDK's current cacerts and import only the aliases the
#           capture added on top of stock. Keeps the new JDK's public roots
#           current. Correct when the capture is months old, or of unknown age.
#
# `merge` is the default: it is right in both cases and only costs time.
#
# What `merge` PRODUCES is a superset of stock, not the added aliases alone. The
# base of the file is a byte copy of this JDK's own cacerts; the added aliases are
# imported on top. A JDK whose cacerts holds 150 entries and a capture that adds 3
# yields a store of 153. That is worth stating plainly, because the confirmation
# prompt names only the 3 -- they are the only entries being DECIDED about -- and
# a prompt that says "importing 3 aliases" reads as though the JVM is about to be
# left trusting three CAs and nothing else.
#
# The two forms differ in exactly one place, and it is what each DROPS:
#
#   merge  drops nothing from stock; ignores whatever the capture held that this
#          JDK's cacerts no longer does -- which is the point, since those are
#          public roots the vendor distrusted between the capture and now.
#   copy   drops every stock entry the capture does not hold, and restores every
#          entry the capture held that stock has since dropped.
#
# `stock-only` in the comparison artifact is exactly the set `copy` would discard.
# ---------------------------------------------------------------------------

# Alias set of a keystore, sorted. Empty output means keytool could not read it.
jks_aliases() {
  keytool -list -keystore "$1" -storepass "${2:-changeit}" 2>/dev/null \
    | awk '/trustedCertEntry/{print $1}' | sed 's/,$//' | sort
}

# One row per trusted entry: alias, owner, issuer, expiry.
#
# `keytool -list -v` is one invocation per keystore and prints all four; the
# alternative -- `-list -rfc` piped into openssl per certificate -- is ~150
# openssl processes per store and tells you nothing more.
jks_rows() {
  keytool -list -v -keystore "$1" -storepass "${2:-changeit}" 2>/dev/null | awk '
    /^Alias name: / { a = substr($0, 13); next }
    /^Entry type: / { t = substr($0, 13); next }
    /^Owner: /      { o = substr($0, 8);  next }
    /^Issuer: /     { i = substr($0, 9);  next }
    /^Valid from: / {
      v = substr($0, 13); p = index(v, " until: ")
      na = (p > 0) ? substr(v, p + 8) : ""
      if (t ~ /trustedCertEntry/ && a != "")
        printf "%s\t%s\t%s\t%s\n", a, o, i, na
      a = ""; o = ""; i = ""; t = ""
    }'
}

# ---------------------------------------------------------------------------
# Step 6 -- the trust-store comparison artifact
#
# The confirmation prompt can only name the aliases being added, and that is a
# fair summary of the DECISION but a poor picture of the OUTCOME. Three questions
# are reasonable to ask before answering it and none can be answered from the
# prompt: what does this JDK already trust, what exactly are the additions, and
# what would `copy` throw away. So they are answered in a file, written before
# the first prompt, and the path is printed.
#
# Written for every JDK, including ones the operator then declines -- a decision
# to install nothing is worth the same record as a decision to install.
# ---------------------------------------------------------------------------
jdk_trust_comparison() {
  local srcroot="$1" jvmdir="$2"
  local cmp_root jdk name src cacerts stock_tmp cap_tmp rows md
  local n_stock n_cap n_added n_common n_stockonly

  if [[ "$RUNS_LIB_OK" != true ]]; then
    warn "shared run index not available; skipping the JDK trust comparison"
    return 0
  fi
  if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" || ! -d "${REIMAGE_ARTIFACT_ROOT:-}" ]]; then
    warn "artifact root not mounted; skipping the JDK trust comparison"
    return 0
  fi
  if $DRY_RUN; then
    would "compare each JDK's stock cacerts against the captured jssecacerts and write a comparison run"
    return 0
  fi

  cmp_root="$REIMAGE_ARTIFACT_ROOT/reimaged-system/comparisons"
  if ! artifact_run_begin "$cmp_root" "restore-access-jdk-trust-diff"; then
    warn "could not stage a JDK trust comparison under $cmp_root"
    return 0
  fi
  rows="$ARTIFACT_RUN_DIR/rows.tsv"
  md="$ARTIFACT_RUN_DIR/comparison.md"

  printf 'jdk\tside\talias\towner\tissuer\tvalid_until\n' > "$rows"

  { printf '# restore-access — JDK trust stores — %s\n\n' "$ARTIFACT_RUN_STAMP"
    printf 'Generated by `bin/restore-access.sh java` on %s.\n\n' "$(date)"
    printf 'For each installed JDK: what it trusts today, what the captured\n'
    printf '`jssecacerts` adds on top, and what it holds that the capture does not.\n\n'
    printf '## The two forms, in terms of these tables\n\n'
    printf '| | `merge` (default) | `copy` |\n| --- | --- | --- |\n'
    printf '| Starts from | this JDK'"'"'s `cacerts` | the captured file |\n'
    printf '| Result contains | **stock + added** | **the capture, exactly** |\n'
    printf '| Adds | the `added` rows | the `added` rows |\n'
    printf '| Discards | nothing | every `stock-only` row |\n'
    printf '| Restores | nothing | every entry the capture held that this JDK has since dropped |\n'
    printf '\n'
    printf '`merge` is a **superset of stock**. A JDK trusting 150 entries plus 3\n'
    printf 'additions produces a store of 153, not 3 — the base is a byte copy of\n'
    printf '`cacerts` and the additions are imported on top of it. The prompt names only\n'
    printf 'the additions because those are the only entries being decided.\n\n'
    printf 'A `stock-only` row is a CA this JDK ships and the old machine'"'"'s store did\n'
    printf 'not. Most are public roots added by the JDK vendor since the capture.\n'
    printf 'Choosing `copy` gives them up.\n\n'
    printf '> `jssecacerts` does not extend `cacerts`. When the file exists the JVM uses\n'
    printf '> it **instead of** `cacerts`, which is why "what the result contains" is the\n'
    printf '> whole question here.\n\n'
  } > "$md"

  _jdk_table() {
    printf '| Alias | Owner | Issuer | Valid until |\n'
    printf '| --- | --- | --- | --- |\n'
    awk -F'\t' -v j="$1" -v w="$2" '
      $1 == j && $2 == w { printf "| `%s` | %s | %s | %s |\n", $3, $4, $5, $6 }' "$rows"
    printf '\n'
  }

  stock_tmp="$(mktemp)"; cap_tmp="$(mktemp)"

  for jdk in "$jvmdir"/*.jdk; do
    [[ -d "$jdk" ]] || continue
    name="$(basename "$jdk")"
    cacerts="$jdk/Contents/Home/lib/security/cacerts"
    src="$srcroot/$name/jssecacerts"

    printf -- '---\n\n## %s\n\n' "$name" >> "$md"
    if [[ ! -f "$cacerts" ]]; then
      printf 'No `cacerts` in this JDK — nothing to compare.\n\n' >> "$md"
      continue
    fi
    jks_rows "$cacerts" | sort > "$stock_tmp"
    : > "$cap_tmp"
    if [[ -f "$src" ]]; then
      jks_rows "$src" | sort > "$cap_tmp"
    fi

    n_stock="$(wc -l < "$stock_tmp" | tr -d ' ')"
    n_cap="$(wc -l < "$cap_tmp" | tr -d ' ')"

    if [[ ! -f "$src" ]]; then
      printf 'The image carries no `jssecacerts` for this JDK, so there is nothing to\n' >> "$md"
      printf 'install and nothing to compare against. This JDK trusts its stock set of\n' >> "$md"
      printf '**%s** entries and no corporate CA — a real finding, not a skip: anything\n' "$n_stock" >> "$md"
      printf 'this JVM builds or fetches over TLS from an internal host will fail.\n\n' >> "$md"
      awk -F'\t' -v j="$name" '{ printf "%s\tstock-only\t%s\n", j, $0 }' "$stock_tmp" >> "$rows"
      continue
    fi

    awk -F'\t' -v j="$name" -v capf="$cap_tmp" '
      FILENAME == capf { cap[$1] = $0; next }
      { stock[$1] = $0 }
      END {
        for (a in cap)   printf "%s\t%s\t%s\n", j, ((a in stock) ? "common" : "added"), cap[a]
        for (a in stock) if (!(a in cap)) printf "%s\tstock-only\t%s\n", j, stock[a]
      }' "$cap_tmp" "$stock_tmp" | sort -t"$(printf '\t')" -k2,2 -k3,3 >> "$rows"

    n_added="$(awk -F'\t'     -v j="$name" '$1==j && $2=="added"{c++}      END{print c+0}' "$rows")"
    n_common="$(awk -F'\t'    -v j="$name" '$1==j && $2=="common"{c++}     END{print c+0}' "$rows")"
    n_stockonly="$(awk -F'\t' -v j="$name" '$1==j && $2=="stock-only"{c++} END{print c+0}' "$rows")"

    { printf '| | Entries |\n| --- | --- |\n'
      printf '| This JDK'"'"'s stock `cacerts` | %s |\n' "$n_stock"
      printf '| The captured `jssecacerts` | %s |\n' "$n_cap"
      printf '| — in both | %s |\n' "$n_common"
      printf '| — **added** by the capture over stock | %s |\n' "$n_added"
      printf '| — **stock only**, absent from the capture | %s |\n' "$n_stockonly"
      printf '| Result of `merge` | %s |\n' "$((n_stock + n_added))"
      printf '| Result of `copy` | %s |\n' "$n_cap"
      printf '\n'
    } >> "$md"

    printf '### Added by the capture — what `merge` imports\n\n' >> "$md"
    if [[ "${n_added:-0}" -eq 0 ]]; then
      printf 'None. The capture adds nothing this JDK does not already trust, so there is\n' >> "$md"
      printf 'no corporate CA to install here.\n\n' >> "$md"
    else
      printf 'These are the only entries the prompt decides about. Expect internal CAs.\n' >> "$md"
      printf 'An unfamiliar **public** root in this table is one the JDK vendor dropped\n' >> "$md"
      printf 'between the capture and now — importing it puts it back, which is what\n' >> "$md"
      printf '`merge` exists to avoid doing by accident.\n\n' >> "$md"
      _jdk_table "$name" added >> "$md"
    fi

    printf '### Stock only — what `copy` would discard\n\n' >> "$md"
    if [[ "${n_stockonly:-0}" -eq 0 ]]; then
      printf 'None. The capture holds everything this JDK does.\n\n' >> "$md"
    else
      printf '%s entr(ies) this JDK trusts and the captured store does not. `merge` keeps\n' "$n_stockonly" >> "$md"
      printf 'them; `copy` gives them up.\n\n' >> "$md"
      _jdk_table "$name" stock-only >> "$md"
    fi

    printf '### This JDK'"'"'s stock trust set\n\n' >> "$md"
    printf 'All %s entries in `cacerts` as it stands now, before anything is installed.\n' "$n_stock" >> "$md"
    printf 'This is the base `merge` builds on.\n\n' >> "$md"
    { printf '| Alias | Owner | Issuer | Valid until |\n'
      printf '| --- | --- | --- | --- |\n'
      awk -F'\t' '{ printf "| `%s` | %s | %s | %s |\n", $1, $2, $3, $4 }' "$stock_tmp"
      printf '\n'; } >> "$md"
  done

  rm -f "$stock_tmp" "$cap_tmp"

  if ! artifact_run_finalize "$cmp_root" "stock vs captured jssecacerts, per installed JDK"; then
    warn "the JDK trust comparison was written but could not be indexed"
    return 0
  fi
  ok "JDK trust comparison: $ARTIFACT_RUN_DIR/comparison.md"
  info "read it before answering the prompts below — it lists each JDK's stock trust set, the additions, and what 'copy' would discard"
}

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
  if ! command -v keytool >/dev/null 2>&1; then
    gate "keytool not on PATH — a JDK is installed but not resolvable; see Phase 10A Step 7"
    GATES=$((GATES + 1)); return 1
  fi

  jdk_trust_comparison "$srcroot" "$jvmdir"

  local installed=0 done_count=0
  local jdk name src dest cacerts added_file want_file have_file n_added n_stock n_result
  for jdk in "$jvmdir"/*.jdk; do
    [[ -d "$jdk" ]] || continue
    installed=$((installed + 1))
    name="$(basename "$jdk")"
    dest="$jdk/Contents/Home/lib/security/jssecacerts"
    cacerts="$jdk/Contents/Home/lib/security/cacerts"
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

    # What the capture adds over this JDK's stock trust set. This is the whole
    # decision: usually a handful of internal CAs, and it is what `merge`
    # installs and what `copy` brings along with the old public roots.
    added_file="$(mktemp)"
    comm -23 <(jks_aliases "$src") <(jks_aliases "$cacerts") > "$added_file"
    n_added="$(wc -l < "$added_file" | tr -d ' ')"
    if [[ "${n_added:-0}" -eq 0 ]]; then
      warn "$name — the captured store adds nothing over this JDK's cacerts; nothing to install"
      rm -f "$added_file"; continue
    fi
    # "Added over stock" is NOT the same as "corporate". It is everything the
    # capture holds that this JDK's cacerts does not, which is the corporate CAs
    # PLUS any public root the JDK vendor has distrusted since the capture. The
    # second kind is exactly what `merge` exists to stop inheriting, and no
    # reliable signal separates them -- a CA is corporate because of who runs it,
    # not because of anything in the certificate. So the list is printed and the
    # operator confirms it; the script does not guess.
    n_stock="$(jks_aliases "$cacerts" | wc -l | tr -d ' ')"
    if [[ "$JSSE_MODE" == "merge" ]]; then
      n_result="$((n_stock + n_added))"
    else
      n_result="$(jks_aliases "$src" | wc -l | tr -d ' ')"
    fi
    info "$name — capture adds $n_added alias(es) over stock: $(tr '\n' ' ' < "$added_file")"
    info "$name — expect internal CAs here. An unfamiliar public root is one this JDK dropped; importing it puts it back."
    # The prompt names the additions because they are the decision, but the file
    # it produces is not three certificates -- under `merge` it is this JDK's
    # whole cacerts with the additions on top. Say so before asking.
    info "$name — stock cacerts holds $n_stock entr(ies); '$JSSE_MODE' produces $n_result"

    # Idempotency, and the reason it is computed rather than assumed: an
    # existing jssecacerts is only "done" if it already carries every added
    # alias. A file left by an interrupted run, or by the other form, does not.
    if [[ -f "$dest" ]]; then
      want_file="$(mktemp)"; have_file="$(mktemp)"
      if [[ "$JSSE_MODE" == "copy" ]]; then
        jks_aliases "$src" > "$want_file"
      else
        cat <(jks_aliases "$cacerts") "$added_file" | sort -u > "$want_file"
      fi
      jks_aliases "$dest" > "$have_file"
      if [[ -s "$have_file" ]] && cmp -s "$want_file" "$have_file"; then
        ok "$name — already carries the $JSSE_MODE trust set"
        done_count=$((done_count + 1))
        rm -f "$added_file" "$want_file" "$have_file"; continue
      fi
      rm -f "$want_file" "$have_file"
    fi

    if $DRY_RUN; then
      would "$name — install jssecacerts by '$JSSE_MODE' ($n_added corporate alias(es))"
      rm -f "$added_file"; continue
    fi
    if ! confirm "Install jssecacerts into $name by '$JSSE_MODE' — $n_result entr(ies): $n_stock from stock plus the $n_added listed above?"; then
      gate "$name — declined"
      GATES=$((GATES + 1)); rm -f "$added_file"; continue
    fi

    # jssecacerts REPLACES cacerts for the JVM rather than extending it, so the
    # file being overwritten is not recoverable from the JDK install. Back it up
    # before writing, every time.
    if [[ -f "$dest" ]]; then
      sudo cp -p "$dest" "$dest.pre-reimage-$STAMP" \
        && info "$name — previous file kept as jssecacerts.pre-reimage-$STAMP"
    fi

    if [[ "$JSSE_MODE" == "copy" ]]; then
      if sudo cp "$src" "$dest"; then
        ok "$name — captured store installed wholesale"
        done_count=$((done_count + 1))
      else
        fail "$name — copy failed"; FAILURES=$((FAILURES + 1))
      fi
    else
      # Build beside the JDK, install once. A half-imported store left in place
      # is a JVM that trusts an arbitrary subset of the corporate chain.
      local staging="/tmp/jssecacerts-$name-$STAMP"
      rm -f "$staging"
      if ! cp "$cacerts" "$staging"; then
        fail "$name — could not copy cacerts as the base"; FAILURES=$((FAILURES + 1))
        rm -f "$added_file"; continue
      fi
      local alias_name imported=0 failed=0
      while IFS= read -r alias_name <&3; do
        [[ -n "$alias_name" ]] || continue
        if keytool -importkeystore -srckeystore "$src" -srcstorepass changeit \
             -destkeystore "$staging" -deststorepass changeit \
             -srcalias "$alias_name" -noprompt >/dev/null 2>&1; then
          imported=$((imported + 1))
        else
          warn "$name — could not import alias: $alias_name"
          failed=$((failed + 1))
        fi
      done 3< "$added_file"

      if (( failed > 0 )); then
        fail "$name — $failed of $n_added alias(es) failed to import; not installing a partial store"
        FAILURES=$((FAILURES + 1)); rm -f "$staging" "$added_file"; continue
      fi
      if sudo cp "$staging" "$dest" && sudo chmod 644 "$dest"; then
        ok "$name — built from this JDK's cacerts plus $imported corporate alias(es)"
        done_count=$((done_count + 1))
      else
        fail "$name — install failed"; FAILURES=$((FAILURES + 1))
      fi
      rm -f "$staging"
    fi

    # Validate what landed, rather than trusting the copy. A count at or below
    # the corporate additions alone means the public roots did not come with it.
    local n_dest
    n_dest="$(jks_aliases "$dest" | wc -l | tr -d ' ')"
    if [[ "${n_dest:-0}" -le "${n_added:-0}" ]] && [[ "$JSSE_MODE" == "merge" ]]; then
      warn "$name — installed store holds only $n_dest alias(es); the public roots are missing"
    else
      info "$name — installed store holds $n_dest trusted entries"
    fi
    rm -f "$added_file"
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

if $PRINT_MNT; then
  _m="$(find_mounted_image || true)"
  if [[ -n "$_m" ]]; then printf '%s\n' "$_m"; exit 0; fi
  echo "ERROR: no mounted secrets image. Run: ./bin/restore-access.sh mount" >&2
  exit 1
fi

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
