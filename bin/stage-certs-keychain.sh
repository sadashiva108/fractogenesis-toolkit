#!/usr/bin/env bash
# =============================================================================
# stage-certs-keychain.sh
#
# Phase 3A certificate/Keychain staging entrypoint: creates the staging
# directories and refreshes the review artifacts, plans/normalizes the discovery
# feeds, or initializes reusable staged-certs config fragments.
#
# --- BEGIN USAGE ---
# Usage:
#   stage-certs-keychain.sh [scan] [--artifact-root ARTIFACT_ROOT] [--open]
#   stage-certs-keychain.sh plan [--artifact-root ARTIFACT_ROOT]
#   stage-certs-keychain.sh normalize [--artifact-root ARTIFACT_ROOT]
#   stage-certs-keychain.sh init-staged-certs-config [--env-file REIMAGE_ENV] [--force]
#   stage-certs-keychain.sh keychain-detail [--open] [-- HELPER_ARGS...]
#
# Modes:
#   scan       Default. Creates staging directories and refreshes review artifacts.
#   plan       Cleans malformed TSV rows, normalizes all available feeds, and writes
#              one deduped planning table. Alias: normalize.
#   init-staged-certs-config
#              Copies staged-certs template fragments into REIMAGE_WORKSPACE_ROOT
#              for reviewed filesystem certificate selections.
#   keychain-detail
#              Enumerate Keychain identities and write a per-identity export
#              checklist (delivery, issuer chain, exportability, restore) as a
#              .proposed review artifact. Auto-fills from `security` + `profiles`;
#              pass helper flags after `--` (e.g. `-- --fingerprint <SHA1>` or
#              `-- --profiles-file <dump>`). Live capture may prompt for sudo.
#
# Creates the standard Phase 3A certificate/Keychain staging directories and
# refreshes the review artifacts under:
#   $REIMAGE_ARTIFACT_ROOT/public-certs/
#   $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/
#   $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/extra-secrets-certs-review/
#
# Options:
#   --artifact-root PATH  Use PATH as REIMAGE_ARTIFACT_ROOT. A sourced reimage.env
#                         or exported REIMAGE_ARTIFACT_ROOT also works.
#   --open                Open the main Phase 3A staging folders after the run.
#
# Initialize reusable staged-certs fragments with:
#   ./bin/stage-certs-keychain.sh init-staged-certs-config
#   # or call the helper directly:
#   python3 .internal/certs/prepare-certs-keychain-staging.py init-staged-certs-config \
#     --env-file "$REPO_ROOT/reimage.env"
#
# Exit status:
#   0  The requested mode completed.
#   1  The requested mode ran but could not complete its work.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

set -euo pipefail

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/{
    /^# --- BEGIN USAGE ---$/d
    /^# --- END USAGE ---$/d
    s/^# \{0,1\}//
    p
  }' "$0"
}

ensure_cert_keychain_stage_dirs() {
  local artifact_root="${1:-${REIMAGE_ARTIFACT_ROOT:-}}"

  if [[ -z "$artifact_root" ]]; then
    echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set for certificate/Keychain staging." >&2
    exit 2
  fi

  mkdir -p \
    "$artifact_root/public-certs" \
    "$artifact_root/secrets-encrypted/certs/keychain-manual-exports" \
    "$artifact_root/secrets-encrypted/certs/loose-candidates-selected" \
    "$artifact_root/secrets-encrypted/certs/project-local" \
    "$artifact_root/secrets-encrypted/certs/tool-local" \
    "$artifact_root/secrets-encrypted/extra-secrets-certs-review"
}

cert_keychain_write_stat_row() {
  local f="$1"

  # Use Python instead of platform-specific stat flags. GNU stat can emit
  # filesystem metadata for the old BSD-style `stat -f` call and then the
  # fallback can emit an additional `unknown` row, creating duplicate malformed
  # TSV rows. This helper always emits exactly one clean TSV row.
  python3 - "$f" <<'PY'
import datetime as dt
import os
import sys

path = sys.argv[1]
try:
    st = os.stat(path)
    modified = dt.datetime.fromtimestamp(st.st_mtime).strftime("%Y-%m-%d %H:%M:%S")
    print(f"{path}\t{st.st_size}\t{modified}")
except OSError:
    print(f"{path}\tunknown\tunknown")
PY
}

source_staged_certs_fragment() {
  local fragment="$1"
  local path="$STAGED_CERTS_SOURCE_DIR/$fragment"
  if [[ ! -f "$path" ]]; then
    echo "Missing staged-certs fragment: $path" >&2
    exit 2
  fi
  # shellcheck disable=SC1090
  source "$path"
}

load_staged_certs_config() {
  STAGED_CERTS_LOOSE_CANDIDATES_SELECTED=()
  STAGED_CERTS_PROJECT_LOCAL=()
  STAGED_CERTS_TOOL_LOCAL=()

  source_staged_certs_fragment "loose-candidates-selected.conf.sh"
  source_staged_certs_fragment "project-local.conf.sh"
  source_staged_certs_fragment "tool-local.conf.sh"
}

cert_keychain_stage_bucket_for_path() {
  local f="$1"

  case "$f" in
    "$HOME/Desktop/"*|"$HOME/Downloads/"*|"$HOME/Documents/"*)
      printf 'loose-candidates-selected'
      ;;
    "$HOME"/Development/*|"$HOME"/Code/*|"$HOME"/src/*|"$HOME"/workspace/*)
      printf 'project-local'
      ;;
    "$HOME"/.m2/*|"$HOME"/.gradle/*|"$HOME"/.npm/*|"$HOME"/.config/*|"$HOME"/.docker/*|"$HOME"/.kube/*|"$HOME"/.aws/*|"$HOME"/.azure/*|"$HOME"/Library/Application\ Support/*)
      printf 'tool-local'
      ;;
    *)
      printf 'loose-candidates-selected'
      ;;
  esac
}

cert_keychain_is_secrets_dmg_captured_path() {
  local f="$1"

  case "$f" in
    "$HOME/.ssh"|"$HOME/.ssh/"*|"$HOME/.gnupg"|"$HOME/.gnupg/"*|"$HOME/.docker"|"$HOME/.docker/"*|"$HOME/.kube"|"$HOME/.kube/"*|"$HOME/.aws"|"$HOME/.aws/"*|"$HOME/.azure"|"$HOME/.azure/"*|"$HOME/.config/gcloud"|"$HOME/.config/gcloud/"*|"$HOME/.config/gh"|"$HOME/.config/gh/"*|"$HOME/.m2"|"$HOME/.m2/"*|"$HOME/.gradle"|"$HOME/.gradle/"*|"$HOME/.npmrc"|"$HOME/.netrc"|"$HOME/.pypirc"|"$HOME/.git-credentials")
      return 0
      ;;
    "$SECRETS_DIR/chrome"|"$SECRETS_DIR/chrome/"*|"$SECRETS_DIR/postman"|"$SECRETS_DIR/postman/"*|"$SECRETS_DIR/raycast"|"$SECRETS_DIR/raycast/"*|"$SECRETS_DIR/cli-credentials"|"$SECRETS_DIR/cli-credentials/"*|"$SECRETS_DIR/git"|"$SECRETS_DIR/git/"*|"$SECRETS_DIR/package-managers"|"$SECRETS_DIR/package-managers/"*|"$SECRETS_DIR/cloud"|"$SECRETS_DIR/cloud/"*)
      return 0
      ;;
    "$HOME/.keystore"|"$HOME"/*.jks)
      return 0
      ;;
    "$HOME/Desktop/"*|"$HOME/Downloads/"*)
      return 0
      ;;
  esac

  if [[ "$(basename "$f")" == "jssecacerts" ]]; then
    case "$f" in
      "${JAVA_HOME:-__unset__}"/lib/security/jssecacerts|/Library/Java/JavaVirtualMachines/*/Contents/Home/lib/security/jssecacerts|/Applications/*.app/Contents/jbr/Contents/Home/lib/security/jssecacerts|/Applications/*.app/Contents/jbr/lib/security/jssecacerts)
        return 0
        ;;
    esac
  fi

  return 1
}

cert_keychain_classify_file() {
  local f="$1"
  local lower base bucket category type action destination note

  lower="$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')"
  base="$(basename "$lower")"
  bucket="$(cert_keychain_stage_bucket_for_path "$f")"

  category="public-certificate"
  type="certificate"
  action="review-public-cert"
  destination="$PUBLIC_CERTS_DIR/"
  note="Review before keeping; public-only certificate material is usually optional."

  case "$base" in
    *.key)
      category="private-key"
      type="key-file"
      action="stage-if-needed"
      destination="$SECRETS_DIR/certs/$bucket/"
      note="Private key material is secret-bearing."
      ;;
    *.p12|*.pfx)
      category="private-key-identity"
      type="pkcs12"
      action="stage-if-needed"
      destination="$SECRETS_DIR/certs/$bucket/"
      note="PKCS#12 files often contain a certificate plus private key."
      ;;
    jssecacerts)
      category="java-trust-override"
      type="jssecacerts"
      action="review-truststore"
      destination="$SECRETS_DIR/certs/$bucket/"
      note="Review whether this is a local Java trust override that is not already auto-captured in Phase 3C."
      ;;
    cacerts)
      category="java-truststore"
      type="cacerts"
      if [[ "$lower" == *"/lib/security/cacerts" || "$lower" == *"/jre/lib/security/cacerts" || "$lower" == *".app/"*"/contents/"*"/cacerts" ]]; then
        action="likely-skip"
        destination="-"
        note="Usually a stock JDK or bundled app truststore that is regenerated by reinstall."
      else
        action="review-truststore"
        destination="$SECRETS_DIR/certs/$bucket/"
        note="Review whether this is a local override or project-specific truststore."
      fi
      ;;
    *.jks|*.keystore)
      if [[ "$base" == *truststore* ]]; then
        category="java-truststore"
        type="truststore-container"
        action="review-truststore"
        destination="$SECRETS_DIR/certs/$bucket/"
        note="Truststore-like Java container; keep only if it is local and still needed."
      else
        category="java-keystore"
        type="keystore-container"
        action="stage-if-needed"
        destination="$SECRETS_DIR/certs/$bucket/"
        note="Java keystore may contain private keys, identities, or passwords."
      fi
      ;;
    *.truststore)
      category="truststore"
      type="truststore-file"
      action="review-truststore"
      destination="$SECRETS_DIR/certs/$bucket/"
      note="Truststore-like file; keep only if it is local and still needed."
      ;;
    *.pem|*.crt|*.cer|*.der)
      category="public-certificate"
      type="certificate-or-chain"
      action="review-public-cert"
      destination="$PUBLIC_CERTS_DIR/"
      note="Likely public certificate material; keep only if it is a useful local trust or restore artifact."
      ;;
  esac

  if [[ "$lower" == *"/.venv/"* || "$lower" == *"/site-packages/certifi/"* || "$lower" == *"/python"*"/certifi/"* || "$lower" == *"/.cache/"* ]]; then
    action="likely-skip"
    destination="-"
    note="Tool- or virtualenv-managed certificate material is usually regenerated."
  elif [[ "$lower" == /applications/* || "$lower" == *".app/contents/"* ]]; then
    case "$action" in
      review-public-cert|review-truststore)
        action="likely-skip"
        destination="-"
        note="Application-bundled certificate material is usually restored by reinstalling the app."
        ;;
    esac
  fi

  case "$f" in
    "$HOME/.ssh/"*|"$HOME/.gnupg/"*|"$HOME/.docker/"*|"$HOME/.kube/"*|"$HOME/.aws/"*|"$HOME/.azure/"*|"$HOME/.config/gcloud/"*|"$HOME/.config/gh/"*|"$HOME/.m2/"*|"$HOME/.gradle/"*|"$HOME/.npmrc"|"$HOME/.netrc"|"$HOME/.pypirc"|"$HOME/.git-credentials")
      action="captured-by-secrets-dmg"
      destination="-"
      note="Phase 3C already captures this credential-bearing path in the consolidated secrets DMG."
      ;;
    "$HOME/.keystore"|"$HOME"/*.jks)
      action="captured-by-secrets-dmg"
      destination="-"
      note="Phase 3C already captures ~/.keystore and home-root .jks files."
      ;;
    "$HOME/Desktop/"*|"$HOME/Downloads/"*)
      action="captured-by-secrets-dmg"
      destination="-"
      note="Phase 3C already captures matching cert and keystore files from Desktop and Downloads."
      ;;
  esac

  if [[ "$base" == "jssecacerts" ]]; then
    case "$f" in
      "${JAVA_HOME:-__unset__}"/lib/security/jssecacerts|/Library/Java/JavaVirtualMachines/*/Contents/Home/lib/security/jssecacerts|/Applications/*.app/Contents/jbr/Contents/Home/lib/security/jssecacerts|/Applications/*.app/Contents/jbr/lib/security/jssecacerts)
        action="captured-by-secrets-dmg"
        destination="-"
        note="Phase 3C already captures Java jssecacerts from JAVA_HOME, installed JDKs, and IntelliJ JBR locations."
        ;;
    esac
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$category" "$type" "$action" "$destination" "$note"
}

cert_keychain_append_tsv_row() {
  local out_file="$1"
  shift
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@" >> "$out_file"
}


cert_keychain_update_secrets_dmg_rebuild_flag() {
  mkdir -p "$EXTRA_CERTS_REVIEW_DIR/state"
  local state_file="$EXTRA_CERTS_REVIEW_DIR/state/certs-staging-state-latest.tsv"
  local flag_file="$EXTRA_CERTS_REVIEW_DIR/state/secrets-dmg-rebuild-required-$STAMP.md"

  python3 - "$SECRETS_DIR/certs" "$state_file" "$flag_file" <<'PY_CERT_STATE'
import datetime as dt
import hashlib
import sys
from pathlib import Path

certs_dir = Path(sys.argv[1])
state_file = Path(sys.argv[2])
flag_file = Path(sys.argv[3])

IGNORE_NAMES = {".DS_Store", "README.md"}
IGNORE_PREFIXES = ("secrets-dmg-rebuild-required-",)


def should_track(path: Path) -> bool:
    name = path.name
    if name in IGNORE_NAMES:
        return False
    if any(name.startswith(prefix) for prefix in IGNORE_PREFIXES):
        return False
    return path.is_file()


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def snapshot() -> dict[str, tuple[str, int, str]]:
    rows: dict[str, tuple[str, int, str]] = {}
    if not certs_dir.exists():
        return rows
    for path in sorted(certs_dir.rglob("*")):
        if not should_track(path):
            continue
        rel = path.relative_to(certs_dir).as_posix()
        try:
            st = path.stat()
            modified = dt.datetime.fromtimestamp(st.st_mtime).strftime("%Y-%m-%d %H:%M:%S")
            rows[rel] = (sha256(path), st.st_size, modified)
        except OSError:
            continue
    return rows


def load_state() -> dict[str, tuple[str, int, str]]:
    rows: dict[str, tuple[str, int, str]] = {}
    if not state_file.exists():
        return rows
    with state_file.open("r", encoding="utf-8", errors="replace") as f:
        _header = f.readline()
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 4:
                continue
            rel, digest, size, modified = parts[:4]
            try:
                size_i = int(size)
            except ValueError:
                size_i = -1
            rows[rel] = (digest, size_i, modified)
    return rows


current = snapshot()
previous = load_state()
changes: list[tuple[str, str, str, int, str]] = []

for rel, (digest, size, modified) in current.items():
    if rel not in previous:
        changes.append(("new", rel, digest, size, modified))
    elif previous[rel][0] != digest:
        changes.append(("changed", rel, digest, size, modified))

state_file.parent.mkdir(parents=True, exist_ok=True)
with state_file.open("w", encoding="utf-8") as f:
    f.write("relative_path\tsha256\tsize_bytes\tmodified\n")
    for rel, (digest, size, modified) in current.items():
        f.write(f"{rel}\t{digest}\t{size}\t{modified}\n")

if not changes:
    raise SystemExit(0)

with flag_file.open("w", encoding="utf-8") as f:
    f.write("# Phase 3B and 3C Rerun Required\n\n")
    f.write(f"Generated: {dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
    f.write("New or changed files were detected under `secrets-encrypted/certs/`. Rerun Phase 3B, then Phase 3C, so the loose-secret sweep runs against the new material and the newest consolidated encrypted `all-secrets-*.dmg` includes it before final validation or plaintext cleanup.\n\n")
    f.write("Tracked files intentionally ignore generated README files and prior rerun-flag notes so this flag is about staged cert material, not documentation churn.\n\n")
    f.write("## New or changed cert-staging files\n\n")
    f.write("| Change | Relative path under `secrets-encrypted/certs/` | SHA-256 | Size bytes | Modified |\n")
    f.write("|---|---|---|---:|---|\n")
    for change, rel, digest, size, modified in changes:
        f.write(f"| {change} | `{rel}` | `{digest}` | {size} | {modified} |\n")
    f.write("\n## Required next step\n\n")
    f.write("```bash\n")
    f.write("cd \"$FRACTOGENESIS_HOME\"\n")
    f.write("set -a\nsource ./reimage.env\nset +a\n\n")
    f.write("./bin/create-secrets-dmg.sh\n")
    f.write("```\n")
PY_CERT_STATE

  if [[ -f "$flag_file" ]]; then
    printf 'Phase 3B/3C rerun flag written: %s\n' "$flag_file"
  fi
}

stage_configured_cert_entries() {
  local bucket="$1"
  local array_name="$2"
  local report_file="$3"
  local dest_dir="$SECRETS_DIR/certs/$bucket"
  local src

  mkdir -p "$dest_dir"

  # Stock macOS Bash 3.2 has no namerefs — `local -n` fails outright there, and
  # `"${arr[@]}"` on an empty array errors under `set -u` even where they work.
  # Expand the named array by index instead, after confirming it has entries:
  # a staged-certs fragment may legitimately select nothing.
  local entry_count entry_index
  eval "entry_count=\${#${array_name}[@]}"
  (( entry_count > 0 )) || return 0

  for (( entry_index = 0; entry_index < entry_count; entry_index++ )); do
    eval "src=\${${array_name}[\$entry_index]}"
    [[ -n "$src" ]] || continue

    if [[ ! -e "$src" ]]; then
      cert_keychain_append_tsv_row "$report_file" \
        "configured-selection" "$bucket" "$src" "selected-path" "configured-selection" "missing" "$dest_dir/" "-" "-" \
        "Configured staged-certs path was not found."
      continue
    fi

    if [[ -d "$src" ]]; then
      cp -Rp "$src" "$dest_dir/"
      cert_keychain_append_tsv_row "$report_file" \
        "configured-selection" "$bucket" "$src" "selected-directory" "configured-selection" "staged" "$dest_dir/" "-" "-" \
        "Copied from staged-certs workspace config."
    else
      cp -p "$src" "$dest_dir/"
      cert_keychain_append_tsv_row "$report_file" \
        "configured-selection" "$bucket" "$src" "selected-file" "configured-selection" "staged" "$dest_dir/" "-" "-" \
        "Copied from staged-certs workspace config."
    fi
  done
}


run_cert_keychain_plan() {
  local planner="$REPO_ROOT/.internal/certs/prepare-certs-keychain-staging.py"

  if [[ ! -f "$planner" ]]; then
    echo "ERROR: cert/Keychain planner not found: $planner" >&2
    echo "Place prepare-certs-keychain-staging.py under .internal/certs/ next to bin/stage-certs-keychain.sh." >&2
    exit 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required for cert/Keychain planning." >&2
    exit 2
  fi

  python3 "$planner" normalize \
    --artifact-root "$REIMAGE_ARTIFACT_ROOT" \
    --review-dir "$EXTRA_CERTS_REVIEW_DIR" \
    --gitignore-dir "$REIMAGE_ARTIFACT_ROOT/gitignore-superset"

  write_review_manifest
}

run_keychain_detail() {
  local helper="$REPO_ROOT/.internal/certs/collect-keychain-export-detail.py"

  if [[ ! -f "$helper" ]]; then
    echo "ERROR: keychain-detail helper not found: $helper" >&2
    echo "Place collect-keychain-export-detail.py under .internal/certs/ next to bin/stage-certs-keychain.sh." >&2
    exit 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required for keychain-detail." >&2
    exit 2
  fi

  local checklist="$EXTRA_CERTS_REVIEW_DIR/decisions/keychain-manual-export-checklist-$STAMP.md.proposed"
  local summary="$SECRETS_DIR/certs/keychain-manual-exports/keychain-export-summary-$STAMP.md"
  local inventory="$PUBLIC_CERTS_DIR/certs/keychain-cert-export-inventory-$STAMP.md"
  mkdir -p "$EXTRA_CERTS_REVIEW_DIR/decisions" "$PUBLIC_CERTS_DIR/certs" "$SECRETS_DIR/certs/keychain-manual-exports"
  # Live capture reads user-level profiles via `profiles show` and computer-level
  # via `sudo profiles show`, so you may be prompted for your admin password.
  # Pass pre-captured dumps after `--` (e.g. -- --profiles-file DUMP) to skip sudo.
  #
  # One run emits all three artifacts from the same classification, so they never
  # drift: the checklist (rides in the encrypted DMG), the export summary (sits
  # with the manual exports), and the generic hostname-free public inventory. The
  # summary/inventory reflect the real export state (they scan the exports dir).
  python3 "$helper" \
    --out "$checklist" \
    --summary-out "$summary" \
    --inventory-out "$inventory" \
    --exports-dir "$SECRETS_DIR/certs/keychain-manual-exports" \
    --staged-loose-dir "$SECRETS_DIR/certs" \
    "$@"
  echo "Wrote:"
  printf '  %s\n' "$checklist" "$summary" "$inventory"

  write_review_manifest
}

run_init_staged_certs_config() {
  local helper="$REPO_ROOT/.internal/certs/prepare-certs-keychain-staging.py"
  local env_file="${ENV_FILE_OVERRIDE:-$DEFAULT_ENV_FILE}"
  local args=("init-staged-certs-config" "--env-file" "$env_file")

  if [[ ! -f "$helper" ]]; then
    echo "ERROR: cert/Keychain staging helper not found: $helper" >&2
    echo "Place prepare-certs-keychain-staging.py under .internal/certs/ next to bin/stage-certs-keychain.sh." >&2
    exit 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required for cert/Keychain staging preparation." >&2
    exit 2
  fi

  if [[ "$FORCE_INIT" == true ]]; then
    args+=("--force")
  fi

  python3 "$helper" "${args[@]}"
}

write_review_manifest() {
  # Regenerate MANIFEST.md as a live snapshot of the review folder. Called at the
  # end of every mode that writes here (scan, plan, keychain-detail) so it never
  # goes stale after a later run or a manual deletion.
  local out="$EXTRA_CERTS_REVIEW_DIR"
  local manifest="$out/MANIFEST.md"
  {
    echo "# Extra Secrets and Certificates Review"
    echo ""
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Host: $(hostname)"
    echo "Artifact root: $REIMAGE_ARTIFACT_ROOT"
    echo ""
    echo "## Purpose"
    echo ""
    echo "This folder is a pre-DMG review area for certificates, private keys, Keychain identities, Java truststores, and credential-bearing config files that may not be covered by the standard secret categories."
    echo ""
    echo "The script inventories macOS Keychain items plus certificate-bearing files in your home directory, installed JDKs, and common application locations. It then writes categorized discovery and staging-candidate reports so you can make faster keep/skip decisions."
    echo ""
    echo "Items that Phase 3C already auto-captures in the consolidated secrets DMG are still visible in discovery reports when useful, but they are excluded from the Phase 3A staging-candidate shortlist."
    echo ""
    echo "Most files here are inventories, not source secrets. If Keychain Access exports a .p12/.pfx/.cer/.pem file, save it under:"
    echo ""
    echo '```text'
    echo '$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/keychain-manual-exports/'
    echo '```'
    echo ""
    echo "Then rerun stage-certs-keychain.sh so the latest review state is on disk before the final DMG validation."
    echo ""
    echo "## Generated files"
    echo ""
  } > "$manifest"
  find "$out" -maxdepth 3 -type f -print 2>/dev/null | sort | while IFS= read -r f; do
    printf -- '- `%s`\n' "${f#$out/}" >> "$manifest"
  done
}

write_extra_certs_review() {
  local out="$EXTRA_CERTS_REVIEW_DIR"
  local keychain_export_dir="$SECRETS_DIR/certs/keychain-manual-exports"
  local cert_candidates="$out/discovery/cert-key-file-candidates-$STAMP.tsv"
  local keychain_certs="$out/discovery/keychain-certificate-inventory-$STAMP.txt"
  local keychain_ids="$out/discovery/keychain-identities-$STAMP.txt"
  local java_candidates="$out/discovery/java-truststore-candidates-$STAMP.txt"
  local credential_candidates="$out/discovery/credential-file-candidates-$STAMP.tsv"
  local discovered_catalog="$out/discovery/all-cert-keychain-discovery-$STAMP.tsv"
  local stage_candidates="$out/discovery/staging-candidates-$STAMP.tsv"
  local keychain_cert_catalog="$out/discovery/keychain-certificate-catalog-$STAMP.tsv"
  local keychain_identity_catalog="$out/discovery/keychain-identity-catalog-$STAMP.tsv"
  local configured_staged_files="$out/discovery/configured-staged-files-$STAMP.tsv"
  local category_rules="$out/discovery/staging-category-rules-$STAMP.md"

  ensure_cert_keychain_stage_dirs "$REIMAGE_ARTIFACT_ROOT"
  mkdir -p "$out" "$out/discovery" "$out/state" "$keychain_export_dir"
  load_staged_certs_config

  {
    printf 'source_kind\tsource_scope\tidentifier\tcategory\ttype\trecommended_action\trecommended_destination\tsize_bytes\tmodified\tnotes\n'
  } > "$keychain_cert_catalog"

  {
    printf 'source_kind\tsource_scope\tidentifier\tcategory\ttype\trecommended_action\trecommended_destination\tsize_bytes\tmodified\tnotes\n'
  } > "$keychain_identity_catalog"

  {
    printf 'source_kind\tsource_scope\tidentifier\tcategory\ttype\trecommended_action\trecommended_destination\tsize_bytes\tmodified\tnotes\n'
  } > "$discovered_catalog"

  {
    printf 'source_kind\tsource_scope\tidentifier\tcategory\ttype\trecommended_action\trecommended_destination\tsize_bytes\tmodified\tnotes\n'
  } > "$stage_candidates"

  {
    printf 'source_kind\tsource_scope\tidentifier\tcategory\ttype\trecommended_action\trecommended_destination\tsize_bytes\tmodified\tnotes\n'
  } > "$configured_staged_files"

  {
    echo "# Keychain Certificate Inventory"
    echo "# Captured: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    if command -v security >/dev/null 2>&1; then
      echo "## login keychain certificates"
      security find-certificate -a -p "$HOME/Library/Keychains/login.keychain-db" 2>&1 || true
      echo ""
      echo "## System keychain certificates"
      security find-certificate -a -p /Library/Keychains/System.keychain 2>&1 || true
    else
      echo "security command not found; Keychain inventory is macOS-only."
    fi
  } > "$keychain_certs"

  {
    echo "# Keychain Identities"
    echo "# Captured: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    if command -v security >/dev/null 2>&1; then
      echo "## All identities"
      security find-identity -v 2>&1 || true
      echo ""
      echo "## Code-signing identities"
      security find-identity -v -p codesigning 2>&1 || true
      echo ""
      echo "## SSL client identities"
      security find-identity -v -p ssl-client 2>&1 || true
    else
      echo "security command not found; Keychain identity inventory is macOS-only."
    fi
  } > "$keychain_ids"

  if command -v security >/dev/null 2>&1; then
    while IFS=$'\t' read -r scope identifier category type action destination note; do
      cert_keychain_append_tsv_row "$keychain_cert_catalog" "keychain-certificate" "$scope" "$identifier" "$category" "$type" "$action" "$destination" "-" "-" "$note"
      cert_keychain_append_tsv_row "$discovered_catalog" "keychain-certificate" "$scope" "$identifier" "$category" "$type" "$action" "$destination" "-" "-" "$note"
    done < <(
      for keychain_path in "$HOME/Library/Keychains/login.keychain-db" "/Library/Keychains/System.keychain"; do
        scope="$(basename "$keychain_path")"
        security find-certificate -a -Z "$keychain_path" 2>/dev/null | awk -v scope="$scope" '
          /^SHA-256 hash:/ { sha=$3; next }
          /"labl"<blob>=/ {
            label=$0
            sub(/^.*=/, "", label)
            gsub(/^"/, "", label)
            gsub(/"$/, "", label)
            gsub(/\t/, " ", label)
            if (sha != "") {
              printf "%s\t%s [%s]\tpublic-certificate\tcertificate\tinventory-only\t-\tPublic keychain certificate evidence.\n", scope, label, sha
            }
            sha=""
          }
        '
      done
    )

    while IFS=$'\t' read -r scope identifier category type action destination note; do
      cert_keychain_append_tsv_row "$keychain_identity_catalog" "keychain-identity" "$scope" "$identifier" "$category" "$type" "$action" "$destination" "-" "-" "$note"
      cert_keychain_append_tsv_row "$discovered_catalog" "keychain-identity" "$scope" "$identifier" "$category" "$type" "$action" "$destination" "-" "-" "$note"
      cert_keychain_append_tsv_row "$stage_candidates" "keychain-identity" "$scope" "$identifier" "$category" "$type" "$action" "$destination" "-" "-" "$note"
    done < <(
      for scope in all codesigning ssl-client; do
        if [[ "$scope" == "all" ]]; then
          security find-identity -v 2>/dev/null
        else
          security find-identity -v -p "$scope" 2>/dev/null
        fi | awk -v scope="$scope" -v dest="$SECRETS_DIR/certs/keychain-manual-exports/" '
          /^[[:space:]]*[0-9]+\)/ {
            sha=$2
            label=$0
            sub(/^[[:space:]]*[0-9]+\)[[:space:]]+[A-F0-9]+[[:space:]]+"/, "", label)
            sub(/"[[:space:]]*$/, "", label)
            gsub(/\t/, " ", label)
            printf "%s\t%s [%s]\tprivate-key-identity\tkeychain-identity\tmanual-export-if-needed\t%s\tReview in Keychain Access and export only if still needed.\n", scope, label, sha, dest
          }
        '
      done
    )
  fi

  {
    printf 'path\tsize_bytes\tmodified\n'
    {
      { find "$HOME" /Applications /Library/Java/JavaVirtualMachines \
        -path "$HOME/Library/Caches" -prune -o \
        -path "$HOME/Library/Containers" -prune -o \
        -path "$HOME/Library/Group Containers" -prune -o \
        -path "$HOME/Library/CloudStorage" -prune -o \
        -path "$HOME/Library/Developer/Xcode/DerivedData" -prune -o \
        -path "$HOME/Library/Application Support/Code/Cache" -prune -o \
        -path "$HOME/Library/Application Support/Google/Chrome/*/Cache" -prune -o \
        -path "$HOME/.Trash" -prune -o \
        -name '.git' -type d -prune -o \
        -type f \( \
          -iname '*.pem' -o \
          -iname '*.crt' -o \
          -iname '*.cer' -o \
          -iname '*.der' -o \
          -iname '*.p12' -o \
          -iname '*.pfx' -o \
          -iname '*.jks' -o \
          -iname '*.keystore' -o \
          -iname '*.truststore' -o \
          -iname 'cacerts' -o \
          -iname 'jssecacerts' -o \
          -iname '*.key' \
        \) -print0 2>/dev/null || true; } |
      while IFS= read -r -d '' f; do
        if cert_keychain_is_secrets_dmg_captured_path "$f"; then
          continue
        fi
        cert_keychain_write_stat_row "$f"
      done
    } | sort
  } > "$cert_candidates"

  {
    printf 'source_kind\tsource_scope\tidentifier\tcategory\ttype\trecommended_action\trecommended_destination\tsize_bytes\tmodified\tnotes\n'
    tail -n +2 "$cert_candidates" | while IFS=$'\t' read -r f size modified; do
      IFS=$'\t' read -r category type action destination note < <(cert_keychain_classify_file "$f")
      cert_keychain_append_tsv_row /dev/stdout "filesystem" "path-scan" "$f" "$category" "$type" "$action" "$destination" "$size" "$modified" "$note"
    done
  } > "$out/filesystem-cert-material-$STAMP.tsv"

  tail -n +2 "$out/filesystem-cert-material-$STAMP.tsv" >> "$discovered_catalog"
  awk -F $'\t' 'NR > 1 && $6 != "likely-skip" && $6 != "captured-by-secrets-dmg" { print }' "$out/filesystem-cert-material-$STAMP.tsv" >> "$stage_candidates"

  {
    echo "# Java Truststore Candidates"
    echo "# Captured: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "JAVA_HOME=${JAVA_HOME:-}"
    echo ""
    if [[ -x /usr/libexec/java_home ]]; then
      /usr/libexec/java_home -V 2>&1 || true
    else
      echo "/usr/libexec/java_home not found"
    fi
    echo ""
    echo "## Truststore-like files"
    find "$HOME" /Library/Java/JavaVirtualMachines /Applications \
      -path "$HOME/Library/Caches" -prune -o \
      -path "$HOME/Library/Containers" -prune -o \
      -path "$HOME/Library/Group Containers" -prune -o \
      -path "$HOME/Library/CloudStorage" -prune -o \
      -path "$HOME/Library/Developer/Xcode/DerivedData" -prune -o \
      -type f \( -name 'cacerts' -o -name 'jssecacerts' -o -name '*.jks' -o -name '*.p12' -o -name '*.pfx' \) \
      -print 2>/dev/null | while IFS= read -r f; do
        if cert_keychain_is_secrets_dmg_captured_path "$f"; then
          continue
        fi
        printf '%s\n' "$f"
      done || true
  } > "$java_candidates"

  {
    printf 'path\tsize_bytes\tmodified\n'
    {
      for f in \
        "$HOME/.ssh" \
        "$HOME/.gnupg" \
        "$HOME/.docker" \
        "$HOME/.kube" \
        "$HOME/.aws" \
        "$HOME/.azure" \
        "$HOME/.config/gcloud" \
        "$HOME/.config/gh" \
        "$HOME/.m2/settings.xml" \
        "$HOME/.gradle/gradle.properties" \
        "$HOME/.npmrc" \
        "$HOME/.netrc" \
        "$HOME/.pypirc" \
        "$HOME/.git-credentials" \
        "$SECRETS_DIR/chrome" \
        "$SECRETS_DIR/postman" \
        "$SECRETS_DIR/raycast" \
        "$SECRETS_DIR/cli-credentials" \
        "$SECRETS_DIR/git" \
        "$SECRETS_DIR/package-managers" \
        "$SECRETS_DIR/cloud"; do
          if [[ -e "$f" ]]; then
            if cert_keychain_is_secrets_dmg_captured_path "$f"; then
              continue
            fi
            cert_keychain_write_stat_row "$f"
          fi
        done
    } | sort
  } > "$credential_candidates"

  cat > "$category_rules" <<'CATEGORY_RULES'
# Staging Category Rules

- `inventory-only`: keep as evidence; do not stage by default.
- `manual-export-if-needed`: review in Keychain Access and export only if the identity is still needed.
- `review-public-cert`: usually public certificate material; stage only if it is useful local trust or restore evidence.
- `review-truststore`: keep only when it is a local or project-specific truststore, not a stock bundle.
- `stage-if-needed`: likely secret-bearing or difficult to recreate; preserve if still required.
- `captured-by-secrets-dmg`: already picked up by the consolidated secrets DMG workflow; do not manually re-stage it in Phase 3A.
- `likely-skip`: usually regenerated by reinstalling the tool, JDK, or application.
CATEGORY_RULES

  stage_configured_cert_entries "loose-candidates-selected" "STAGED_CERTS_LOOSE_CANDIDATES_SELECTED" "$configured_staged_files"
  stage_configured_cert_entries "project-local" "STAGED_CERTS_PROJECT_LOCAL" "$configured_staged_files"
  stage_configured_cert_entries "tool-local" "STAGED_CERTS_TOOL_LOCAL" "$configured_staged_files"

  cat > "$keychain_export_dir/README.md" <<'KEYCHAIN_EXPORT_README'
# Manual Keychain Exports

Use this folder only for Keychain Access exports that must be included in the consolidated encrypted secrets DMG.

Recommended manual flow:

```text
Keychain Access > login keychain > My Certificates
Keychain Access > System keychain > Certificates
File > Export Items
```

Use `.p12` or `.pfx` when the export includes a private key. Use `.cer` or `.pem` for public certificates only.

Do not store the export password in this folder. Save it in LastPass or another approved password manager.
KEYCHAIN_EXPORT_README

  cert_keychain_update_secrets_dmg_rebuild_flag

  write_review_manifest

  printf 'Refreshed certificate/Keychain review artifacts: %s\n' "$out"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_ENV_FILE="$REPO_ROOT/reimage.env"

OPEN_AFTER=false
ARTIFACT_ROOT_OVERRIDE=""
ENV_FILE_OVERRIDE=""
FORCE_INIT=false
MODE="scan"

require_option_value() {
  local option="$1"
  local value="${2:-}"

  if [[ -z "$value" || "$value" == --* ]]; then
    echo "ERROR: $option requires a non-empty value." >&2
    usage >&2
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    scan)
      MODE="scan"
      shift
      ;;
    plan|normalize)
      MODE="plan"
      shift
      ;;
    init|init-staged-certs-config)
      MODE="init-staged-certs-config"
      shift
      ;;
    keychain-detail)
      MODE="keychain-detail"
      shift
      ;;
    --artifact-root)
      require_option_value "$1" "${2:-}"
      ARTIFACT_ROOT_OVERRIDE="${2:-}"
      shift 2
      ;;
    --env-file)
      require_option_value "$1" "${2:-}"
      ENV_FILE_OVERRIDE="${2:-}"
      shift 2
      ;;
    --force)
      FORCE_INIT=true
      shift
      ;;
    --open)
      OPEN_AFTER=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
    *)
      echo "Unexpected extra argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ "$MODE" == "init-staged-certs-config" ]]; then
  run_init_staged_certs_config
  exit 0
fi

# ── Load shared reimage config ────────────────────────────────────────────────
# The --artifact-root override is applied AFTER load, so keep config loading
# permissive about REIMAGE_ARTIFACT_ROOT being empty during load.
ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false
CONFIG_LOADER="$REPO_ROOT/.internal/load-reimage-config.sh"
if [[ ! -f "$CONFIG_LOADER" ]]; then
  echo "ERROR: shared config loader not found: $CONFIG_LOADER" >&2
  exit 2
fi
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"
# ─────────────────────────────────────────────────────────────────────────────

REIMAGE_ARTIFACT_ROOT="${ARTIFACT_ROOT_OVERRIDE:-${REIMAGE_ARTIFACT_ROOT:-}}"

STAMP="$(date +%Y%m%d-%H%M%S)"
PUBLIC_CERTS_DIR="$REIMAGE_ARTIFACT_ROOT/public-certs"
SECRETS_DIR="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"
EXTRA_CERTS_REVIEW_DIR="$SECRETS_DIR/extra-secrets-certs-review"
# STAGED_CERTS_TEMPLATE_DIR, STAGED_CERTS_WORKSPACE_DIR, and
# STAGED_CERTS_SOURCE_DIR are resolved by .internal/artifact-config.sh. This
# entrypoint is where the fallback actually costs something, so it is the one
# that warns about it.
if [[ "$STAGED_CERTS_SOURCE_DIR" == "$STAGED_CERTS_TEMPLATE_DIR" && -n "${STAGED_CERTS_WORKSPACE_DIR:-}" ]]; then
  echo "WARNING: REIMAGE_WORKSPACE_ROOT is set but $STAGED_CERTS_WORKSPACE_DIR does not exist —" >&2
  echo "         falling back to committed templates. Run: ./bin/stage-certs-keychain.sh init-staged-certs-config" >&2
fi

if [[ -z "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set. Source reimage.env or pass --artifact-root PATH." >&2
  exit 2
fi

if [[ ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: artifact root not found: $REIMAGE_ARTIFACT_ROOT" >&2
  exit 2
fi

ensure_cert_keychain_stage_dirs "$REIMAGE_ARTIFACT_ROOT"

case "$MODE" in
  scan)
    write_extra_certs_review
    echo "Prepared Phase 3A certificate/Keychain staging folders:"
    printf '  %s\n' \
      "$REIMAGE_ARTIFACT_ROOT/public-certs" \
      "$SECRETS_DIR/certs" \
      "$EXTRA_CERTS_REVIEW_DIR"
    ;;
  plan)
    run_cert_keychain_plan
    ;;
  keychain-detail)
    run_keychain_detail "$@"
    ;;
  *)
    echo "ERROR: unsupported mode: $MODE" >&2
    exit 2
    ;;
esac

if [[ "$OPEN_AFTER" == true ]]; then
  open "$REIMAGE_ARTIFACT_ROOT/public-certs" 2>/dev/null || true
  open "$SECRETS_DIR/certs/keychain-manual-exports" 2>/dev/null || true
  open "$EXTRA_CERTS_REVIEW_DIR" 2>/dev/null || true
fi
