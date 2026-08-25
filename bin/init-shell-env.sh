#!/usr/bin/env bash
# =============================================================================
# init-shell-env.sh
#
# Wires the toolkit into the login shell after a reimage by appending one
# marked block to the shell profile. The block exports FRACTOGENESIS_HOME and
# sources reimage.env, so every new Terminal starts with the workflow's
# configuration already loaded.
#
# Runbook/phase context: enroll-and-stabilize.md (Phase 8), Step 2 — run once,
# immediately after bootstrap.sh has put the toolkit on disk and reimage.env
# has been copied back from the jump drive or the artifact volume.
#
# WHY THIS EXISTS. Before the erase, `.envrc` (direnv) loaded reimage.env on
# entering the checkout. direnv is installed by restore-runtime.md in Phase 10A
# — two phases too late — so between Phase 8 and Phase 10 every new shell would
# otherwise start with nothing set. That matters most right after the Phase 8
# stabilization restart, when the Terminal that comes back has no memory of the
# exports typed before it.
#
# WHAT IT DELIBERATELY DOES NOT DO. It does not copy values out of reimage.env
# into the profile. reimage.env stays the single source of truth: the block
# sources it, so editing that file changes every new shell without touching the
# profile again. Baking the values in would create a second copy that drifts —
# and REIMAGE_ARTIFACT_ROOT in particular can legitimately change mid-effort,
# for instance when the artifact root is renamed after the final capture.
#
# CLASSIFICATION: entrypoint, but an unusual one. It does NOT source
# .internal/load-reimage-config.sh, because its whole job is to make that
# loading work later; at the moment it runs, nothing has been loaded yet and
# FRACTOGENESIS_HOME may not be set in the calling shell. It self-locates from
# BASH_SOURCE like every other entrypoint, and derives the install root from
# its own position rather than trusting a variable that does not exist yet.
#
# --- BEGIN USAGE ---
# Usage:
#   bash "$FRACTOGENESIS_HOME/bin/init-shell-env.sh"
#   exec zsh -l
#
#   # FRACTOGENESIS_HOME is exported in enroll-and-stabilize.md Step 1, before
#   # bootstrap.sh runs, so it is already set by the time this script is called.
#   # If it is not, give the path directly -- the script derives the toolkit root
#   # from its own location either way:
#   bash "$HOME/fractogenesis-toolkit/bin/init-shell-env.sh"
#
#   # Preview the exact block without writing anything.
#   bash bin/init-shell-env.sh --dry-run
#
#   # Write to a different profile (see the note on login vs interactive below).
#   bash bin/init-shell-env.sh --file ~/.zshrc
#
#   # Take the block back out once the reimage effort is finished.
#   bash bin/init-shell-env.sh --remove
#
# Options:
#   --file PATH   Profile to modify. Default: ~/.zprofile
#   --dry-run     Print the block and the target path; write nothing.
#   --remove      Remove a previously written block and exit.
#   --force       Rewrite the block even if an identical one is already present.
#   -h, --help    Show this message and exit.
#
# Profile choice:
#   The default is ~/.zprofile, which macOS runs for LOGIN shells — which is
#   what Terminal.app and iTerm start by default. Some embedded terminals (VS
#   Code, JetBrains) start non-login interactive shells instead and read
#   ~/.zshrc only. If the values are missing in an IDE terminal but present in
#   Terminal.app, rerun with `--file ~/.zshrc`; the block is idempotent and safe
#   to have in both.
#
# Idempotency:
#   The block is delimited by BEGIN/END marker comments. Re-running replaces the
#   existing block rather than appending a second copy, so it is safe to run
#   after editing reimage.env, after moving the checkout, or by mistake.
#
#   --remove clears ONLY the marked block. Lines added to the profile by any
#   other means are left alone, which is correct -- this script did not write
#   them and cannot know whether they are still wanted. It does mean a profile
#   that accumulated bare `export FRACTOGENESIS_HOME=...` lines before this
#   script existed still carries them after --remove; those predate the markers
#   and have to be removed by hand. Check with:
#
#       grep -n 'FRACTOGENESIS_HOME' ~/.zprofile
#
# Safety:
#   A timestamped backup of the profile is written beside it before any change,
#   matching what restore-home.md does before merging dotfiles.
#
# Exit status:
#   0  Block written, already current, removed, or previewed.
#   2  Usage error, or the toolkit root could not be resolved.
# --- END USAGE ---
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

PROFILE="$HOME/.zprofile"
DRY_RUN=false
REMOVE=false
FORCE=false

require_option_value() {
  if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
    echo "ERROR: $1 requires a non-empty value." >&2
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)    require_option_value "$1" "${2:-}"; PROFILE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --remove)  REMOVE=true; shift ;;
    --force)   FORCE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Sanity-check that we really are inside a toolkit checkout. Writing a profile
# block that points at a directory with no bin/ would produce a shell that
# looks configured and resolves nothing.
if [[ ! -d "$REPO_ROOT/bin" ]]; then
  echo "ERROR: no bin/ directory under the resolved toolkit root: $REPO_ROOT" >&2
  echo "HINT:  run this script from inside the installed toolkit, e.g." >&2
  echo "       bash \"\$HOME/fractogenesis-toolkit/bin/$(basename "$0")\"" >&2
  exit 2
fi

BEGIN_MARK="# >>> fractogenesis-toolkit reimage env >>>"
END_MARK="# <<< fractogenesis-toolkit reimage env <<<"

read -r -d '' BLOCK <<EOF || true
$BEGIN_MARK
# Added by bin/init-shell-env.sh (enroll-and-stabilize.md, Phase 8 Step 2).
# Remove with: bash "\$FRACTOGENESIS_HOME/bin/init-shell-env.sh" --remove
export FRACTOGENESIS_HOME="$REPO_ROOT"
if [ -f "\$FRACTOGENESIS_HOME/reimage.env" ]; then
  # set +a runs unconditionally, not chained with &&: a reimage.env that fails
  # partway would otherwise leave the interactive shell in allexport mode, where
  # every later assignment silently becomes an exported variable.
  set -a
  . "\$FRACTOGENESIS_HOME/reimage.env"
  set +a
fi
$END_MARK
EOF

strip_block() {
  # Remove any existing marked block from stdin.
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
    $0 == b { skip = 1 }
    skip != 1 { print }
    $0 == e { skip = 0 }
  '
}

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Target profile: $PROFILE"
  echo "Toolkit root:   $REPO_ROOT"
  echo ""
  printf '%s\n' "$BLOCK"
  echo ""
  echo "(--dry-run: nothing written)"
  exit 0
fi

if [[ ! -f "$PROFILE" ]]; then
  if [[ "$REMOVE" == "true" ]]; then
    echo "Nothing to remove: $PROFILE does not exist."
    exit 0
  fi
  touch "$PROFILE"
fi

BACKUP="$PROFILE.pre-reimage-env.$(date +%Y%m%d-%H%M%S).bak"
cp -p "$PROFILE" "$BACKUP"

if [[ "$REMOVE" == "true" ]]; then
  strip_block < "$PROFILE" > "$PROFILE.tmp.$$"
  mv "$PROFILE.tmp.$$" "$PROFILE"
  echo "Removed the toolkit env block from $PROFILE"
  echo "Backup: $BACKUP"
  echo "Open a new login shell (or run: exec zsh -l) for it to take effect."
  exit 0
fi

if grep -Fq "$BEGIN_MARK" "$PROFILE"; then
  if [[ "$FORCE" != "true" ]] && printf '%s\n' "$BLOCK" | diff -q - <(
      awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
        $0 == b { inb = 1 } inb { print } $0 == e { inb = 0 }' "$PROFILE"
    ) >/dev/null 2>&1; then
    echo "Already current in $PROFILE — nothing to do."
    rm -f "$BACKUP"
    exit 0
  fi
  strip_block < "$PROFILE" > "$PROFILE.tmp.$$"
  mv "$PROFILE.tmp.$$" "$PROFILE"
  echo "Replacing the existing toolkit env block in $PROFILE"
fi

printf '\n%s\n' "$BLOCK" >> "$PROFILE"

echo "Wrote the toolkit env block to $PROFILE"
echo "Backup: $BACKUP"
echo ""
if [[ -f "$REPO_ROOT/reimage.env" ]]; then
  echo "reimage.env found — it will be sourced by every new login shell."
else
  echo "NOTE: $REPO_ROOT/reimage.env does not exist yet."
  echo "      The block tolerates that and does nothing until you copy it back"
  echo "      from the jump drive or the artifact volume. Copy it, then open a"
  echo "      new shell; no need to rerun this script."
fi
echo ""
echo "Next: exec zsh -l    (then: cd \"\$FRACTOGENESIS_HOME\" && ./bin/check-reimage-env.sh)"
