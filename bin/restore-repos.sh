#!/usr/bin/env bash
# =============================================================================
# restore-repos.sh
#
# Phase 9B — Restore Repositories status recorder and action emitter.
#
# Reads the most recent pre-image repository audit produced by Phase 2C
# (backup-repos.md), classifies every tracked repo against the current state
# of the reimaged Mac, and emits a per-repo restore-status report along with
# ready-to-run `git clone` and `rsync` commands the operator executes by hand.
#
# This is an aggregate validator: it records evidence and prints action items,
# it does not autonomously clone repositories or overwrite working trees. The
# only mutating operation it performs is an opt-in rsync of pre-image kept
# ignored files back into repos already present on disk, and only when
# --apply-ignored-files is passed and the operator confirms each repo.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#   chmod +x bin/restore-repos.sh
#
#   # Default -- read-only status report. Emits clone and rsync commands but
#   # does not run them. Writes under
#   # $REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/post-image-restore-*.
#   ./bin/restore-repos.sh
#
#   # Apply staged-ignored-files/live/<label>/ back into each repo already
#   # present on disk, prompting Y/n per repo before rsyncing.
#   ./bin/restore-repos.sh --apply-ignored-files
#
#   # Override the artifact root for this invocation.
#   ./bin/restore-repos.sh --artifact-root /path/to/reimage-artifact-root
#
#   # Point at a specific pre-image audit run instead of the latest.
#   ./bin/restore-repos.sh --input-run pre-image-YYYYMMDD-HHMMSS
#
#   # Reveal the generated report in Finder after completion.
#   ./bin/restore-repos.sh --open
#
# Options:
#   --artifact-root PATH   Override REIMAGE_ARTIFACT_ROOT from shared config.
#   --input-run NAME       Basename of a run under repo-audit-reports/runs/
#                          to consume instead of the latest-run.txt pointer.
#   --apply-ignored-files  Rsync staged-ignored-files/live/<label>/ into each
#                          repo present on disk, prompting Y/n per repo.
#   --output DIR           Exact output directory for the generated report.
#   --open                 Reveal the generated report in Finder on completion.
#   -h, --help             Show this message and exit.
#
# Configuration precedence:
#   1. Explicit command-line options for this invocation.
#   2. Environment values already exported by the caller or optional .envrc.
#   3. Values loaded from reimage.env.
#   4. Defaults and reusable fragments loaded by artifact-config.sh.
#
# Output location:
#   $REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/post-image-restore-YYYYMMDD-HHMMSS/
#
# Exit status:
#   0  Status report written; no fatal errors.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

# Aggregate validator: individual command failures become WARN/TODO rows in
# the report rather than aborting the run. Keep -u and pipefail on.
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

# Phase 9B requires the artifact drive to be mounted so the pre-image repo
# audit produced by Phase 2C is reachable. Load strictly.
# shellcheck source=../.internal/load-reimage-config.sh
source "$CONFIG_LOADER"

usage() {
  sed -n '/^# --- BEGIN USAGE ---$/,/^# --- END USAGE ---$/p' "$0" \
    | sed '1d;$d;s/^# //;s/^#$//'
}

# ---------------------------------------------------------------------------
# Defaults and command-line parsing
# ---------------------------------------------------------------------------
STAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_DIR=""
INPUT_RUN=""
APPLY_IGNORED_FILES=false
OPEN_RESULT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact-root)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "ERROR: --artifact-root requires a non-empty value." >&2
        usage >&2
        exit 2
      fi
      REIMAGE_ARTIFACT_ROOT="$2"
      shift 2
      ;;
    --input-run)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "ERROR: --input-run requires a run basename." >&2
        usage >&2
        exit 2
      fi
      INPUT_RUN="$2"
      shift 2
      ;;
    --apply-ignored-files)
      APPLY_IGNORED_FILES=true
      shift
      ;;
    --output)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo "ERROR: --output requires a directory." >&2
        usage >&2
        exit 2
      fi
      OUTPUT_DIR="$2"
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
# Resolve inputs (pre-image audit) and outputs
# ---------------------------------------------------------------------------
if [[ -z "${REIMAGE_ARTIFACT_ROOT:-}" || ! -d "$REIMAGE_ARTIFACT_ROOT" ]]; then
  echo "ERROR: REIMAGE_ARTIFACT_ROOT is not set or not a directory. Reconnect the artifact volume and rerun." >&2
  exit 2
fi

AUDIT_ROOT="$REIMAGE_ARTIFACT_ROOT/repo-audit-reports"
RUNS_DIR="$AUDIT_ROOT/runs"
LATEST_POINTER="$AUDIT_ROOT/latest-run.txt"

if [[ -z "$INPUT_RUN" ]]; then
  if [[ ! -f "$LATEST_POINTER" ]]; then
    echo "ERROR: latest-run pointer not found: $LATEST_POINTER" >&2
    echo "Phase 2C (backup-repos.md) must produce a pre-image audit before Phase 9B can restore from it." >&2
    exit 2
  fi
  INPUT_RUN="$(cat "$LATEST_POINTER" 2>/dev/null | tr -d '[:space:]')"
  # latest-run.txt stores a path relative to repo-audit-reports/; strip a
  # leading runs/ segment when present so we can join uniformly below.
  INPUT_RUN="${INPUT_RUN#runs/}"
fi

INPUT_RUN_DIR="$RUNS_DIR/$INPUT_RUN"
if [[ ! -d "$INPUT_RUN_DIR" ]]; then
  echo "ERROR: input run directory not found: $INPUT_RUN_DIR" >&2
  exit 2
fi

REPOS_TSV="$INPUT_RUN_DIR/repos.tsv"
COMMITS_TSV="$INPUT_RUN_DIR/local-only-commits.tsv"
STASHES_TSV="$INPUT_RUN_DIR/stashes.tsv"
TRACKED_TSV="$INPUT_RUN_DIR/tracked-changes.tsv"

if [[ ! -f "$REPOS_TSV" ]]; then
  echo "ERROR: repos.tsv not found in pre-image audit run: $REPOS_TSV" >&2
  exit 2
fi

STAGED_LIVE="$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live"

if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="$RUNS_DIR/post-image-restore-$STAMP"
fi

# Safety invariant: refuse to write generated output under the repo checkout.
if [[ -n "${REPO_ROOT:-}" && ( "$OUTPUT_DIR" == "$REPO_ROOT" || "$OUTPUT_DIR" == "$REPO_ROOT"/* ) ]]; then
  echo "ERROR: refusing to write output under the repo checkout: $OUTPUT_DIR" >&2
  exit 2
fi

OUT="$OUTPUT_DIR"
RAW_DIR="$OUT/raw"
mkdir -p "$RAW_DIR"

# Preserve the pre-image inputs alongside the report for provenance.
cp -p "$REPOS_TSV" "$RAW_DIR/repos-input.tsv" 2>/dev/null || true
[[ -f "$COMMITS_TSV" ]] && cp -p "$COMMITS_TSV" "$RAW_DIR/local-only-commits-input.tsv" 2>/dev/null || true
[[ -f "$STASHES_TSV" ]] && cp -p "$STASHES_TSV" "$RAW_DIR/stashes-input.tsv" 2>/dev/null || true
[[ -f "$TRACKED_TSV" ]] && cp -p "$TRACKED_TSV" "$RAW_DIR/tracked-changes-input.tsv" 2>/dev/null || true

STATUS_TSV="$RAW_DIR/status.tsv"
REPORT_MD="$OUT/restore-status.md"

printf "repo_path\tlabel\tpath_present\tremote_url\tclone_host\tclone_target_root\tignored_files_available\tignored_files_applied\tcarry_forward_rows\n" > "$STATUS_TSV"

# ---------------------------------------------------------------------------
# Per-repo classification
# ---------------------------------------------------------------------------
# repos.tsv columns:
#   1 repo         (absolute path on the pre-image machine)
#   2 branch
#   3 head
#   4 remote_urls  (semicolon-joined `name url (fetch|push)` lines)
#   5 status_summary
#   6 local_only_commit_count
#   7 stash_count
#   8 tracked_change_count
#   9 untracked_nonignored_count
#  10 ignored_count

# Derived Git roots from reimage.env (may be empty if not set).
WORK_ROOT="${GIT_WORK_REPO_ROOT:-}"
PERSONAL_ROOT="${GIT_PERSONAL_REPO_ROOT:-}"
WORK_HOST="${GIT_WORK_GITHUB_HOST:-github.com}"
PERSONAL_HOST="${GIT_PERSONAL_GITHUB_HOST:-github-personal}"

# Strip trailing slashes so prefix checks are consistent.
WORK_ROOT="${WORK_ROOT%/}"
PERSONAL_ROOT="${PERSONAL_ROOT%/}"

extract_remote_url() {
  # Given the raw remote_urls field, return the first origin fetch URL, or
  # any URL if origin fetch is not present.
  local remotes="$1"
  local url
  url="$(printf '%s\n' "$remotes" | tr ';' '\n' | awk '/^ *origin[[:space:]]+.*\(fetch\)/{print $2; exit}')"
  if [[ -z "$url" ]]; then
    url="$(printf '%s\n' "$remotes" | tr ';' '\n' | awk 'NF>=2{print $2; exit}')"
  fi
  printf '%s' "$url"
}

classify_repo() {
  # Sets globals: PATH_PRESENT, CLONE_HOST, CLONE_TARGET_ROOT, IGN_AVAILABLE,
  # IGN_APPLIED, CARRY_FORWARD_ROWS. Reads: repo_path, label, remote_url,
  # local_commit_count, stash_count, tracked_change_count.
  local repo_path="$1"
  local remote_url="$2"

  if [[ -d "$repo_path/.git" ]]; then
    PATH_PRESENT="yes"
  else
    PATH_PRESENT="no"
  fi

  # Route by original repo location on the pre-image machine.
  if [[ -n "$PERSONAL_ROOT" && "$repo_path" == "$PERSONAL_ROOT"/* ]]; then
    CLONE_HOST="$PERSONAL_HOST"
    CLONE_TARGET_ROOT="$PERSONAL_ROOT"
  else
    CLONE_HOST="$WORK_HOST"
    if [[ -n "$WORK_ROOT" ]]; then
      CLONE_TARGET_ROOT="$WORK_ROOT"
    else
      # Fall back to the pre-image parent directory when GIT_WORK_REPO_ROOT
      # is unset.
      CLONE_TARGET_ROOT="$(dirname "$repo_path")"
    fi
  fi

  # staged-ignored-files/live/<basename(repo)>/
  if [[ -n "$label" && -d "$STAGED_LIVE/$label" ]]; then
    IGN_AVAILABLE="yes"
  else
    IGN_AVAILABLE="no"
  fi

  IGN_APPLIED="unknown"

  local carry=0
  [[ "$local_commit_count" -gt 0 ]] 2>/dev/null && carry=$((carry + local_commit_count))
  [[ "$stash_count" -gt 0 ]] 2>/dev/null && carry=$((carry + stash_count))
  [[ "$tracked_change_count" -gt 0 ]] 2>/dev/null && carry=$((carry + tracked_change_count))
  CARRY_FORWARD_ROWS="$carry"
}

# Rewrite remote_url with the personal host alias when routing to personal.
rewrite_remote_for_host() {
  local url="$1"
  local host="$2"
  # Only rewrite SSH URLs of the form git@github.com:owner/repo.git.
  # Leave HTTPS and non-github URLs alone; the operator can adjust manually.
  if [[ "$url" == git@github.com:* && "$host" != "github.com" ]]; then
    printf 'git@%s:%s' "$host" "${url#git@github.com:}"
  else
    printf '%s' "$url"
  fi
}

# ---------------------------------------------------------------------------
# Iterate repos.tsv and build the per-repo status report
# ---------------------------------------------------------------------------
TOTAL=0
PRESENT_COUNT=0
NEEDS_CLONE_COUNT=0
IGN_AVAILABLE_COUNT=0
IGN_APPLIED_COUNT=0
CARRY_FORWARD_TOTAL=0

# Build clone-commands and rsync-commands as here-doc-friendly text lines
# collected in temporary files (avoids Bash 3.2 array-under-set-u pitfalls).
CLONE_CMDS="$OUT/clone-commands.sh"
RSYNC_CMDS="$OUT/rsync-ignored-files.sh"
{
  echo "#!/usr/bin/env bash"
  echo "# Generated by restore-repos.sh on $(date)"
  echo "# Source repo-audit run: $INPUT_RUN"
  echo "# Review each command before running. This script does NOT autorun."
  echo "set -euo pipefail"
  echo ""
  echo 'source "$FRACTOGENESIS_HOME/reimage.env"'
  echo ""
} > "$CLONE_CMDS"
{
  echo "#!/usr/bin/env bash"
  echo "# Generated by restore-repos.sh on $(date)"
  echo "# Rsync pre-image kept ignored files back into cloned repos."
  echo "# Review each command before running. This script does NOT autorun."
  echo "set -euo pipefail"
  echo ""
} > "$RSYNC_CMDS"

# Read repos.tsv, skipping the header row.
first=true
while IFS=$'\t' read -r repo_path branch head_line remotes status_summary \
  local_commit_count stash_count tracked_change_count untracked_count ignored_count
do
  if $first; then
    first=false
    continue
  fi
  [[ -n "$repo_path" ]] || continue

  TOTAL=$((TOTAL + 1))
  label="$(basename "$repo_path")"
  remote_url="$(extract_remote_url "$remotes")"

  classify_repo "$repo_path" "$remote_url"

  clone_url="$(rewrite_remote_for_host "$remote_url" "$CLONE_HOST")"

  if [[ "$PATH_PRESENT" == "yes" ]]; then
    PRESENT_COUNT=$((PRESENT_COUNT + 1))
  else
    NEEDS_CLONE_COUNT=$((NEEDS_CLONE_COUNT + 1))
    if [[ -n "$clone_url" ]]; then
      {
        echo "# $label"
        echo "cd \"$CLONE_TARGET_ROOT\" && git clone \"$clone_url\""
        echo ""
      } >> "$CLONE_CMDS"
    else
      {
        echo "# $label -- no remote URL recorded in pre-image audit; clone manually."
        echo ""
      } >> "$CLONE_CMDS"
    fi
  fi

  if [[ "$IGN_AVAILABLE" == "yes" ]]; then
    IGN_AVAILABLE_COUNT=$((IGN_AVAILABLE_COUNT + 1))
    {
      echo "# $label"
      echo "rsync -a --info=stats1,progress2 \\"
      echo "  \"$STAGED_LIVE/$label/\" \\"
      echo "  \"$repo_path/\""
      echo ""
    } >> "$RSYNC_CMDS"
  fi

  if [[ "$CARRY_FORWARD_ROWS" -gt 0 ]] 2>/dev/null; then
    CARRY_FORWARD_TOTAL=$((CARRY_FORWARD_TOTAL + CARRY_FORWARD_ROWS))
  fi

  # ---------------------------------------------------------------
  # Optional: apply staged ignored files with per-repo confirmation
  # ---------------------------------------------------------------
  if [[ "$APPLY_IGNORED_FILES" == "true" \
        && "$PATH_PRESENT" == "yes" \
        && "$IGN_AVAILABLE" == "yes" ]]; then
    printf '\nApply staged ignored files for %s?\n' "$label"
    printf '  source: %s/%s/\n' "$STAGED_LIVE" "$label"
    printf '  target: %s/\n' "$repo_path"
    printf '  proceed? [y/N]: '
    read -r reply < /dev/tty || reply=""
    case "$reply" in
      y|Y|yes|YES)
        if rsync -a --info=stats1 "$STAGED_LIVE/$label/" "$repo_path/"; then
          IGN_APPLIED="yes"
          IGN_APPLIED_COUNT=$((IGN_APPLIED_COUNT + 1))
        else
          IGN_APPLIED="failed"
        fi
        ;;
      *)
        IGN_APPLIED="skipped"
        ;;
    esac
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$repo_path" "$label" "$PATH_PRESENT" "$remote_url" \
    "$CLONE_HOST" "$CLONE_TARGET_ROOT" \
    "$IGN_AVAILABLE" "$IGN_APPLIED" "$CARRY_FORWARD_ROWS" >> "$STATUS_TSV"

done < "$REPOS_TSV"

# ---------------------------------------------------------------------------
# Heuristic verdicts for the Phase 9B exit-criteria rows
# ---------------------------------------------------------------------------
status_pass_warn() {
  if [[ "$1" == "true" ]]; then
    printf 'PASS'
  else
    printf 'WARN'
  fi
}

REPOS_INDEX_OK="false"
[[ -f "$STATUS_TSV" && "$TOTAL" -gt 0 ]] && REPOS_INDEX_OK="true"

CLONES_COMPLETE="false"
[[ "$NEEDS_CLONE_COUNT" -eq 0 && "$TOTAL" -gt 0 ]] && CLONES_COMPLETE="true"

IGNORED_FILES_COMPLETE="false"
if [[ "$IGN_AVAILABLE_COUNT" -eq 0 ]]; then
  IGNORED_FILES_COMPLETE="true"
elif [[ "$APPLY_IGNORED_FILES" == "true" && "$IGN_APPLIED_COUNT" -eq "$IGN_AVAILABLE_COUNT" ]]; then
  IGNORED_FILES_COMPLETE="true"
fi

# ---------------------------------------------------------------------------
# Generate the Markdown report
# ---------------------------------------------------------------------------
cat > "$REPORT_MD" <<EOF
# Restore Repositories Status Report

Generated: $(date)
Script: $(basename "$0")
Output directory: $OUT
Source pre-image audit run: $INPUT_RUN
Repositories in inventory: $TOTAL

Use this report as the Phase 9B evidence bundle. The command-verifiable rows
are prefilled with a heuristic PASS/WARN verdict. Complete the remaining
rescue-branch and carry-forward rows by hand after cloning the repos and
verifying each pre-image \`reimage/YYYYMMDD/*\` rescue branch reached its
remote before reimage. See \`restore-repos.md\` for the full runbook.

## Summary

| Category | Count |
|---|---|
| Total repos in pre-image inventory | $TOTAL |
| Already present on disk | $PRESENT_COUNT |
| Needs \`git clone\` | $NEEDS_CLONE_COUNT |
| Staged ignored files available to restore | $IGN_AVAILABLE_COUNT |
| Staged ignored files applied this run | $IGN_APPLIED_COUNT |
| Carry-forward rows across repos (local commits + stashes + tracked changes) | $CARRY_FORWARD_TOTAL |

## Exit Criteria

| Check | Verification mode | How to verify | Status | Notes |
|---|---|---|---|---|
| Pre-image repo inventory read successfully | Command | \`repos.tsv\` produced status rows | $(status_pass_warn "$REPOS_INDEX_OK") | See \`raw/repos-input.tsv\`. |
| Every tracked repo is present on disk | Mixed | \`git clone\` output from \`clone-commands.sh\` succeeded for each entry | $(status_pass_warn "$CLONES_COMPLETE") | Emitted commands to \`clone-commands.sh\`; run manually and rerun this script to confirm. |
| Every staged ignored bundle applied | Mixed | \`rsync-ignored-files.sh\` executed or \`--apply-ignored-files\` used | $(status_pass_warn "$IGNORED_FILES_COMPLETE") | Emitted commands to \`rsync-ignored-files.sh\`; review before running. |
| Rescue branches (\`reimage/YYYYMMDD/*\`) present on remote for every carry-forward row | Manual | \`git ls-remote origin 'reimage/*'\` per repo | TODO | The pre-image audit recorded $CARRY_FORWARD_TOTAL carry-forward rows across $TOTAL repos; each row must map to a pushed rescue branch or be intentionally discarded. |
| Personal repos route via the personal SSH host alias | Manual | \`git remote -v\` on each personal repo | TODO | Fill after cloning; see the personal-host pitfall in \`restore-git.md\` Step 8. |

## Per-Repo Status

| Label | Path | Present | Ignored bundle | Carry-forward rows | Clone host |
|---|---|---|---|---|---|
EOF

# Append per-repo rows to the report from status.tsv (skip header).
skip=true
while IFS=$'\t' read -r rp lbl present remote_url chost ctarget ign_avail ign_appl carry; do
  if $skip; then skip=false; continue; fi
  printf '| %s | %s | %s | %s | %s | %s |\n' \
    "$lbl" "$rp" "$present" "$ign_avail" "$carry" "$chost" \
    >> "$REPORT_MD"
done < "$STATUS_TSV"

cat >> "$REPORT_MD" <<EOF

## Emitted Action Files

- \`clone-commands.sh\` — one \`git clone\` per repo not present. Review, then run selectively.
- \`rsync-ignored-files.sh\` — one \`rsync\` per repo with staged ignored files available.

Neither file is executable by default. Source \`\$FRACTOGENESIS_HOME/reimage.env\`
first, then run the commands you want:

\`\`\`bash
cat "$OUT/clone-commands.sh"
bash "$OUT/clone-commands.sh"
\`\`\`

## Manual Follow-Up

1. Review \`clone-commands.sh\`, adjust any repos whose remote was rewritten
   from the pre-image URL, and run selectively.
2. Review \`rsync-ignored-files.sh\` and run selectively — or rerun this
   script with \`--apply-ignored-files\` to walk repos interactively.
3. For each repo with \`carry-forward rows > 0\`, run
   \`git ls-remote origin 'reimage/*'\` inside the clone to confirm the
   pre-image rescue branch is present, then merge or cherry-pick back into
   the intended branch.
4. Verify personal repos have the personal host alias in their remote URL
   (\`git remote -v\`), not the default \`github.com\`.
5. Rerun this script after cloning to update the exit-criteria table.

## Raw Evidence Files

- \`raw/status.tsv\` — per-repo status table
- \`raw/repos-input.tsv\` — copy of the pre-image \`repos.tsv\` for provenance
- \`raw/local-only-commits-input.tsv\` — pre-image carry-forward checklist rows
- \`raw/stashes-input.tsv\` — pre-image stash rows
- \`raw/tracked-changes-input.tsv\` — pre-image tracked change rows
EOF

cat > "$OUT/MANIFEST.txt" <<EOF
# Restore Repositories Status Manifest
Generated: $(date)
Script: $(basename "$0")
Output directory: $OUT
Source pre-image audit run: $INPUT_RUN

Files:
- restore-status.md
- clone-commands.sh
- rsync-ignored-files.sh
- raw/status.tsv
- raw/repos-input.tsv
- raw/local-only-commits-input.tsv
- raw/stashes-input.tsv
- raw/tracked-changes-input.tsv
EOF

# Pointer alongside (not replacing) the pre-image latest-run.txt owned by
# Phase 2C. Distinct filename keeps ownership clear.
printf '%s\n' "runs/post-image-restore-$STAMP" > "$AUDIT_ROOT/latest-post-image-restore.txt"

echo ""
echo "Restore repositories report complete."
echo "  Total repos in inventory: $TOTAL"
echo "  Present on disk:          $PRESENT_COUNT"
echo "  Needs clone:              $NEEDS_CLONE_COUNT"
echo "  Ignored bundles available: $IGN_AVAILABLE_COUNT"
if [[ "$APPLY_IGNORED_FILES" == "true" ]]; then
  echo "  Ignored bundles applied:   $IGN_APPLIED_COUNT"
fi
echo "  Carry-forward rows total: $CARRY_FORWARD_TOTAL"
echo ""
echo "Report → $REPORT_MD"
echo "Clone commands → $OUT/clone-commands.sh"
echo "Rsync commands → $OUT/rsync-ignored-files.sh"

if [[ "$OPEN_RESULT" == "true" ]]; then
  open -R "$REPORT_MD"
fi
