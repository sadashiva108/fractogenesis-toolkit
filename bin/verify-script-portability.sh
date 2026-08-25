#!/usr/bin/env bash
# =============================================================================
# verify-script-portability.sh
#
# Flags constructs that work on every shell an AI session or a Linux box can
# reach, and fail on the macOS this workflow actually targets: Bash 4+ syntax in
# scripts that declare `#!/usr/bin/env bash`, and GNU userland flags that BSD
# `find`, `sed`, `stat`, `date`, `grep`, and `sort` reject.
#
# WHY THE BASH 3.2 FLOOR IS REAL AND NOT A DOCTRINE. On a machine that has
# finished the workflow, `#!/usr/bin/env bash` resolves to Homebrew's bash 5.x,
# and every rule below looks academic. But Phase 8 and Phase 9 run `bin/`
# scripts BEFORE Phase 10A installs Homebrew -- `record-restore-prereqs.sh` says
# so in code, excluding `Homebrew available` from its unanswered-row count on
# the grounds that Phase 10A installs it. On that machine `env bash` resolves to
# stock `/bin/bash`, which is 3.2.57. The floor is load-bearing exactly where a
# failure is most expensive: on a freshly imaged Mac with no toolchain yet.
#
# WHY THIS IS STATIC, AND NOT A TEST RUN. Bash 3.2 compatibility is a
# feature-PRESENCE question rather than a runtime one. `declare -A` is rejected
# on 3.2 and works silently everywhere else, so a clean run on any modern shell
# proves nothing. No shell available to an AI session can answer this by
# executing -- every one of them is Bash 5.x with GNU coreutils. Inspection is
# not a weaker substitute for running it; it is the only method that answers the
# question from there. `/bin/bash -n` on the target Mac is the complement: it
# catches parse errors on the real interpreter, and misses everything that fails
# at runtime rather than at parse time, which is most of the rules below.
#
# CLASSIFICATION: aggregate validator, and a cross-cutting one -- no runbook
# owns it, the same as `verify-doc-paths.sh`. It records every finding rather
# than aborting on the first, so it deliberately does NOT use `set -e`. It reads
# the repository only: it creates nothing outside `mktemp`, writes nothing back,
# and does not load the shared reimage config, because everything it checks is
# repo-relative and must verify on a fresh checkout with no `reimage.env`.
#
# SCOPE, AND WHAT IS DELIBERATELY OUTSIDE IT
#
# Scanned: executable shell under `bin/` and `.internal/`, `bootstrap.sh`, and
# the script templates that seed new files.
#
# Runbook command blocks are NOT scanned, and that is a decision rather than an
# omission. A `bin/` script runs under `#!/usr/bin/env bash`. A runbook block is
# pasted into the operator's interactive shell, which on this machine is zsh.
# Those are different targets with different incompatibilities, and one rule set
# applied to both would be confidently wrong about half of them. A zsh rule set
# is separate work.
#
# A consequence worth carrying: moving an inline runbook block into a `bin/`
# script moves it from zsh to Bash 3.2. A block that works when pasted may not
# survive the move, so run this after any such extraction.
#
# Also outside scope: unguarded expansion of a possibly-empty array --
# `"${arr[@]}"` errors under `set -u` on 3.2. Whether a given expansion is
# guarded depends on control flow above it, which a line matcher cannot see.
# That one stays a human review item in the authoring prompt.
#
# IT DOES NOT SCAN ITSELF by default. The rule table below holds, as data, every
# pattern the rules search for, so a self-scan reports the rule set as a pile of
# violations. Pass `--file bin/verify-script-portability.sh` to see exactly that.
# The default set skips it by name.
#
# FULL-LINE COMMENTS ARE BLANKED BEFORE MATCHING. Without that, this file finds
# `.github/copilot-instructions.md`'s own rule -- "avoid associative arrays,
# mapfile, GNU-only options" -- quoted in half the script headers in the repo,
# and reports the prose forbidding a construct as a use of it. Comments are
# blanked rather than deleted so reported line numbers still match the file you
# open. A trailing comment after code on the same line is still matched; that is
# rare, and the matched line is printed so you can see it is a comment at a
# glance.
#
# SUPPRESSION, AND WHY IT IS SHAPED LIKE THIS
#
# Some GNU-form calls are correct: a guarded BSD-first fallback tries
# `/usr/bin/stat -f` and only reaches `stat -c` on a machine that lacks it.
# Two such sites exist today, so a line matcher that cannot see the guard needs
# a way to be told.
#
#   # portability-ok: GNU-STATC — guarded fallback; BSD `stat -f` is tried first
#   stat -c '%Y' "$path"
#
# The pragma applies to the LINE IMMEDIATELY BELOW it, names one or more rule
# IDs separated by commas, and carries a reason. It is deliberately not a
# silent escape hatch, because a suppression nobody can see is the same class of
# failure as a check nobody runs:
#
#   - A reason is REQUIRED. An unexplained suppression cannot be reviewed three
#     weeks later, the same argument `artifact_run_set_official` makes for
#     requiring a reason on a pin.
#   - An UNKNOWN rule ID is reported. A typo'd pragma suppresses nothing while
#     looking like it did -- "could not check" scored as "checked and fine".
#   - A pragma that suppresses NOTHING is reported. That is how a suppression
#     outlives the code it excused and quietly starts covering something else.
#   - Suppressed hits are counted in the summary and listed under `--verbose`.
#     They never vanish; they move from FAIL to accounted-for.
#
# --- BEGIN USAGE ---
# Usage:
#   cd <repo-root>
#
#   # Check the default script set
#   ./bin/verify-script-portability.sh
#
#   # Check specific files instead. Repeatable.
#   ./bin/verify-script-portability.sh --file bin/backup-home.sh
#
#   # Show clean files and suppressed hits, not just findings
#   ./bin/verify-script-portability.sh --verbose
#
#   # Print the rule set and exit, without scanning anything
#   ./bin/verify-script-portability.sh --list-rules
#
# Options:
#   --file PATH    Check PATH instead of the default set. Repeatable.
#   --verbose      List clean files and suppressed hits too.
#   --list-rules   Print every rule with its severity and exit.
#   -h, --help     Show this message and exit.
#
# Suppressing a deliberate exception:
#   # portability-ok: RULE-ID[,RULE-ID...] — why this one is correct
#   <the line the rule fires on>
#
# Result records:
#   FAIL    The construct does not work on the macOS target. Bash 3.2 rejects
#           it, or the BSD tool rejects the flag. Fails the run.
#   WARN    The construct behaves differently, depends on a macOS version newer
#           than the workflow's floor, or a pragma is malformed, misspelled, or
#           no longer covering anything. Reported; does not fail the run.
#   SUPPRESSED  A hit covered by a well-formed pragma. Counted, and listed
#           under --verbose.
#
# Severity is a property of each rule, not of its class. GNU-form `sed -i`
# genuinely errors on macOS and is FAIL; `readlink -f` works on macOS 12.3 and
# later and is WARN. A class-level tier would be wrong in both directions.
#
# Exit status:
#   0  No FAIL findings.
#   1  One or more FAIL findings.
#   2  Usage error, or a file passed to --file does not exist.
# --- END USAGE ---
# =============================================================================

# Aggregate validator: intentionally NOT `set -e`. Every finding must be
# recorded and reported in one pass, so a hit cannot abort the run.
set -uo pipefail

# ---------------------------------------------------------------------------
# Locate repository
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SELF_NAME="$(basename "${BASH_SOURCE[0]}")"

# ── Colors ──────────────────────────────────────────────────────────────────
# Same palette and section helpers as the other bin/ entrypoints so severity
# colors mean the same thing across the workflow.
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

thin_hr()     { printf '%s\n' "  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"; }
log_section() { echo ""; echo -e "${BLD}${CYN}▸ $1${RST}"; thin_hr; }

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
# Rule table
#
# Fields are separated by `@@` rather than a single character, because every
# single-character candidate -- `|`, `:`, `~`, `^` -- appears inside at least
# one of the regexes below. Parsed with parameter expansion rather than `IFS`,
# which cannot hold a multi-character separator.
#
#   ID @@ SEVERITY @@ EXTENDED-REGEX @@ MESSAGE
#
# Regexes are matched with `grep -nE` against a comment-blanked copy of the
# file. `[^;|&#]*` inside a command rule keeps the match from wandering across a
# pipe or a statement boundary into an unrelated command's flags.
# ---------------------------------------------------------------------------
read_rules() {
  cat <<'RULES'
B32-MAPFILE@@FAIL@@(^|[^[:alnum:]_])(mapfile|readarray)[[:space:]]@@`mapfile`/`readarray` is Bash 4.0. Read with `while IFS= read -r` into an array instead.
B32-ASSOC@@FAIL@@(declare|local|typeset)[[:space:]]+-[A-Za-z]*A([[:space:]]|$)@@Associative arrays are Bash 4.0. Use two indexed arrays, or a delimited string scanned with a loop.
B32-NAMEREF@@FAIL@@(declare|local|typeset)[[:space:]]+-[A-Za-z]*n([[:space:]]|$)@@`declare -n` namerefs are Bash 4.3. Pass the value, or print and capture it.
B32-CASEMOD@@FAIL@@\$\{[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?(\^\^?|,,?)\}@@`${var^^}` / `${var,,}` case modification is Bash 4.0. Use `tr` or `awk`.
B32-NEGIDX@@FAIL@@\$\{[A-Za-z_][A-Za-z0-9_]*\[-[0-9]@@A negative array index is Bash 4.3. Compute the index from `${#arr[@]}`.
B32-CASEFALL@@FAIL@@;;&@@`;;&` case fall-through is Bash 4.0. Restructure the `case`, or use an `if` chain.
B32-COPROC@@FAIL@@(^|[^[:alnum:]_])coproc([[:space:]]|$)@@`coproc` is Bash 4.0. Use a named pipe or a temp file.
B32-GLOBSTAR@@FAIL@@shopt[[:space:]]+-s[[:space:]]+globstar@@`globstar` (`**`) is Bash 4.0. Use `find` with `-print0` and a NUL-delimited read.
B32-PIPEERR@@FAIL@@\|&@@`\|&` is Bash 4.0 shorthand. Write `2>&1 \|` explicitly.
B32-TESTV@@FAIL@@\[\[[[:space:]]+-v[[:space:]]@@`[[ -v var ]]` is Bash 4.2. Use `[[ -n "${var+x}" ]]`.
B32-LASTPIPE@@FAIL@@shopt[[:space:]]+-s[[:space:]]+lastpipe@@`lastpipe` is Bash 4.2. Restructure so the loop is not the right-hand side of a pipe.
B32-PRINTFT@@FAIL@@printf[^;|&#]*%\([^)]*\)T@@`printf '%(fmt)T'` is Bash 4.2. Call `date` instead.
B32-WAITN@@FAIL@@(^|[^[:alnum:]_])wait[[:space:]]+-n([[:space:]]|$)@@`wait -n` is Bash 4.3. Collect PIDs and wait on each.
B32-EPOCH@@FAIL@@(EPOCHSECONDS|EPOCHREALTIME)@@`EPOCHSECONDS`/`EPOCHREALTIME` are Bash 5.0. Use `date +%s`.
B32-PARAMTRANS@@FAIL@@\$\{[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?@[QEPAKaLU]\}@@`${var@Q}`-style parameter transformation is Bash 4.4.
GNU-SEDI@@FAIL@@sed[^;|&#]*[[:space:]]-i[[:space:]]+(-e|['"'"'"]?[sy]/)@@GNU-form `sed -i`. BSD sed requires an explicit backup suffix: `sed -i '"''"' ...`.
GNU-STATC@@FAIL@@(^|[^[:alnum:]_/])stat[^;|&#]*[[:space:]]-c([[:space:]]|$)@@`stat -c` is GNU. BSD stat uses `-f` with a different format language.
GNU-DATED@@FAIL@@(^|[^[:alnum:]_/])date[^;|&#]*[[:space:]](-d[[:space:]]|--date)@@`date -d` is GNU. BSD date parses with `-j -f`.
GNU-FINDPRINTF@@FAIL@@find[^;|&#]*[[:space:]]-printf([[:space:]]|$)@@`find -printf` is GNU-only. Use `-print0` and format in the reading loop.
GNU-FINDREGEXTYPE@@FAIL@@find[^;|&#]*[[:space:]]-regextype([[:space:]]|$)@@`find -regextype` is GNU-only.
GNU-GREPP@@FAIL@@(^|[^[:alnum:]_/])grep[^;|&#]*[[:space:]]-[A-Za-z]*P([[:space:]]|$)@@`grep -P` is GNU-only. BSD grep has no PCRE mode; use `-E`.
GNU-SORTV@@FAIL@@(^|[^[:alnum:]_/])sort[^;|&#]*[[:space:]]-[A-Za-z]*V([[:space:]]|$)@@`sort -V` is GNU-only. Zero-pad the field, or sort on a normalised key.
GNU-SUMS@@FAIL@@(^|[^[:alnum:]_/])(md5sum|sha1sum|sha256sum|sha512sum)([[:space:]]|$)@@GNU checksum tools are absent on macOS. Use `shasum -a 256` or `md5`.
GNU-TAC@@FAIL@@(^|[^[:alnum:]_/])tac([[:space:]]|$)@@`tac` is GNU-only. Use `tail -r` on macOS, or `awk` reversal.
GNU-HEADNEG@@FAIL@@head[[:space:]]+-n[[:space:]]+-[0-9]@@`head -n -N` (drop last N) is GNU-only.
GNU-LONGOPT@@FAIL@@(^|[^[:alnum:]_/])(cp|du|ls|rm|wc)[^;|&#]*[[:space:]]--(parents|max-depth|color|reflink|preserve|time-style)@@GNU long option with no BSD equivalent.
BSD-READLINKF@@WARN@@(^|[^[:alnum:]_/])readlink[[:space:]]+-f([[:space:]]|$)@@`readlink -f` needs macOS 12.3+. Prefer the `cd`/`pwd` self-location idiom used elsewhere in this repo.
BSD-REALPATH@@WARN@@(^|[^[:alnum:]_/])realpath([[:space:]]|$)@@`realpath` needs macOS 12.3+. The repo has a portable `absolute_path` helper in the `bin/` boundary recorders.
BSD-TIMEOUT@@WARN@@(^|[^[:alnum:]_/])timeout[[:space:]]@@`timeout` is not on stock macOS (it is `gtimeout` from coreutils). Use a per-command timeout flag such as `curl -m`.
BSD-XARGSR@@WARN@@(^|[^[:alnum:]_/])xargs[^;|&#]*[[:space:]]-[A-Za-z]*r([[:space:]]|$)@@`xargs -r` is GNU. BSD xargs already skips empty input, so the flag is unrecognised rather than needed.
BSD-NEWERMT@@WARN@@find[^;|&#]*[[:space:]]-newermt([[:space:]]|$)@@`find -newermt` support varies on BSD find. Compare against a reference file with `-newer`.
BSD-GETOPT@@WARN@@(^|[^[:alnum:]_/])getopt([[:space:]]|$)@@GNU enhanced `getopt` is absent on macOS. The `getopts` builtin is fine; a bare `getopt` is not.
RULES
}

known_rule_ids() {
  read_rules | sed 's/@@.*$//'
}

# ---------------------------------------------------------------------------
# Parse command-line options
# ---------------------------------------------------------------------------
VERBOSE=false
LIST_RULES=false
FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      require_option_value "$1" "${2:-}"
      FILES+=("$2")
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --list-rules)
      LIST_RULES=true
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

if [[ "$LIST_RULES" == "true" ]]; then
  log_section "Portability rule set"
  while IFS= read -r rule_line; do
    [[ -n "$rule_line" ]] || continue
    rule_id="${rule_line%%@@*}"
    rule_rest="${rule_line#*@@}"
    rule_sev="${rule_rest%%@@*}"
    rule_rest="${rule_rest#*@@}"
    rule_msg="${rule_rest#*@@}"
    if [[ "$rule_sev" == "FAIL" ]]; then
      printf "  ${RED}%-6s${RST} ${BLD}%-22s${RST} %s\n" "$rule_sev" "$rule_id" "$rule_msg"
    else
      printf "  ${YEL}%-6s${RST} ${BLD}%-22s${RST} %s\n" "$rule_sev" "$rule_id" "$rule_msg"
    fi
  done < <(read_rules)
  echo ""
  echo -e "  ${DIM}Suppress a deliberate exception with, on the line above it:${RST}"
  echo -e "  ${DIM}  # portability-ok: RULE-ID — why this one is correct${RST}"
  echo ""
  exit 0
fi

# ---------------------------------------------------------------------------
# Default file set — executable shell, plus the templates that seed new files.
#
# This script is excluded by name: its rule table contains, as data, every
# pattern it searches for. Pass it with --file to scan it deliberately.
# ---------------------------------------------------------------------------
if (( ${#FILES[@]} == 0 )); then
  while IFS= read -r found_file; do
    [[ -n "$found_file" ]] && FILES+=("$found_file")
  done < <(
    cd "$REPO_ROOT" || exit 0
    {
      [[ -f bootstrap.sh ]] && printf '%s\n' bootstrap.sh
      find bin .internal -type f -name '*.sh' 2>/dev/null
      find .github/ai-templates/script-templates -type f -name '*.tmpl' 2>/dev/null
    } | grep -v "/${SELF_NAME}\$" | sort
  )
fi

if (( ${#FILES[@]} == 0 )); then
  echo "ERROR: no files to check." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Working files
# ---------------------------------------------------------------------------
STRIPPED="$(mktemp)"
PRAGMAS="$(mktemp)"
USED_PRAGMAS="$(mktemp)"
KNOWN_IDS="$(mktemp)"
cleanup_portability_scan() { rm -f "$STRIPPED" "$PRAGMAS" "$USED_PRAGMAS" "$KNOWN_IDS"; }
trap cleanup_portability_scan EXIT

known_rule_ids > "$KNOWN_IDS"

# ---------------------------------------------------------------------------
# Pragma parsing
#
# Read from the ORIGINAL file, not the comment-blanked copy -- the blanking that
# keeps rule matching honest would erase every pragma. A pragma governs the line
# immediately below itself.
# ---------------------------------------------------------------------------
PRAGMA_MATCH='^[[:space:]]*#[[:space:]]*portability-ok:'

pragma_ids() {
  printf '%s' "$1" \
    | sed -n 's/^[[:space:]]*#[[:space:]]*portability-ok:[[:space:]]*\([A-Za-z0-9,_-]*\).*$/\1/p'
}

pragma_reason() {
  printf '%s' "$1" \
    | sed -n 's/^[[:space:]]*#[[:space:]]*portability-ok:[[:space:]]*[A-Za-z0-9,_-]*//p'
}

# A reason is any remainder carrying a real word. Testing for "at least one
# three-letter run" rather than stripping a leading separator keeps this
# byte-safe: the separator people actually type is an em dash, and a multibyte
# character inside a bracket expression is not portable.
pragma_has_reason() {
  printf '%s' "$1" | grep -qE '[A-Za-z]{3,}'
}

# Does a well-formed pragma on the line above <hit-line> name <rule-id>?
pragma_covers() {
  local want_line=$(( $1 - 1 )) rule="$2" entry ids
  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    [[ "${entry%%:*}" == "$want_line" ]] || continue
    ids="$(pragma_ids "${entry#*:}")"
    case ",${ids}," in
      *",${rule},"*) return 0 ;;
    esac
  done < "$PRAGMAS"
  return 1
}

# ---------------------------------------------------------------------------
# Scan
# ---------------------------------------------------------------------------
log_section "Script portability check"
echo -e "  ${DIM}Repository: $REPO_ROOT${RST}"
echo -e "  ${DIM}Files     : ${#FILES[@]}${RST}"
echo -e "  ${DIM}Target    : macOS stock Bash 3.2 + BSD userland${RST}"

cd "$REPO_ROOT" || { echo "ERROR: cannot enter repository root: $REPO_ROOT" >&2; exit 2; }

fail_count=0
warn_count=0
suppressed_count=0
clean_count=0

for target in "${FILES[@]}"; do
  if [[ ! -f "$target" ]]; then
    echo ""
    printf "  ${RED}%-7s${RST}  %s  ${DIM}(file not found)${RST}\n" "ERROR" "$target"
    exit 2
  fi

  # Blank full-line comments rather than deleting them, so reported line
  # numbers still match the file you open. This `sed` is the BSD-safe form:
  # no -i, no GNU-only expression.
  sed 's/^[[:space:]]*#.*$//' "$target" > "$STRIPPED"

  grep -nE "$PRAGMA_MATCH" "$target" > "$PRAGMAS" 2>/dev/null || : > "$PRAGMAS"
  : > "$USED_PRAGMAS"

  file_findings=""

  while IFS= read -r rule_line; do
    [[ -n "$rule_line" ]] || continue
    rule_id="${rule_line%%@@*}"
    rule_rest="${rule_line#*@@}"
    rule_sev="${rule_rest%%@@*}"
    rule_rest="${rule_rest#*@@}"
    rule_re="${rule_rest%%@@*}"
    rule_msg="${rule_rest#*@@}"

    while IFS= read -r hit; do
      [[ -n "$hit" ]] || continue
      hit_line="${hit%%:*}"
      hit_text="${hit#*:}"
      # Trim leading whitespace from the shown source line.
      hit_text="${hit_text#"${hit_text%%[![:space:]]*}"}"

      if pragma_covers "$hit_line" "$rule_id"; then
        suppressed_count=$((suppressed_count + 1))
        printf '%s\n' "$(( hit_line - 1 ))" >> "$USED_PRAGMAS"
        if [[ "$VERBOSE" == "true" ]]; then
          file_findings="${file_findings}$(printf "\n  ${DIM}SUPP${RST}  ${BLD}%-22s${RST} line %s\n        ${DIM}%s${RST}" \
            "$rule_id" "$hit_line" "$hit_text")"
        fi
        continue
      fi

      if [[ "$rule_sev" == "FAIL" ]]; then
        fail_count=$((fail_count + 1))
        file_findings="${file_findings}$(printf "\n  ${RED}FAIL${RST}  ${BLD}%-22s${RST} line %s\n        %s\n        ${DIM}%s${RST}" \
          "$rule_id" "$hit_line" "$hit_text" "$rule_msg")"
      else
        warn_count=$((warn_count + 1))
        file_findings="${file_findings}$(printf "\n  ${YEL}WARN${RST}  ${BLD}%-22s${RST} line %s\n        %s\n        ${DIM}%s${RST}" \
          "$rule_id" "$hit_line" "$hit_text" "$rule_msg")"
      fi
    done < <(grep -nE "$rule_re" "$STRIPPED" 2>/dev/null)
  done < <(read_rules)

  # -------------------------------------------------------------------------
  # Pragma hygiene. A suppression mechanism that cannot report on its own
  # suppressions decays into one nobody audits.
  # -------------------------------------------------------------------------
  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    p_line="${entry%%:*}"
    p_text="${entry#*:}"
    p_ids="$(pragma_ids "$p_text")"
    p_reason="$(pragma_reason "$p_text")"

    if [[ -z "$p_ids" ]]; then
      warn_count=$((warn_count + 1))
      file_findings="${file_findings}$(printf "\n  ${YEL}WARN${RST}  ${BLD}%-22s${RST} line %s\n        %s\n        ${DIM}%s${RST}" \
        "PRAGMA-NO-RULE" "$p_line" "$p_text" "Pragma names no rule ID. Expected: # portability-ok: RULE-ID — reason")"
      continue
    fi

    if ! pragma_has_reason "$p_reason"; then
      warn_count=$((warn_count + 1))
      file_findings="${file_findings}$(printf "\n  ${YEL}WARN${RST}  ${BLD}%-22s${RST} line %s\n        %s\n        ${DIM}%s${RST}" \
        "PRAGMA-NO-REASON" "$p_line" "$p_text" "A reason is required. An unexplained suppression cannot be reviewed later.")"
    fi

    # Each named ID must exist, or the pragma quietly covers nothing.
    p_rest="$p_ids"
    while [[ -n "$p_rest" ]]; do
      p_one="${p_rest%%,*}"
      if [[ "$p_one" == "$p_rest" ]]; then p_rest=""; else p_rest="${p_rest#*,}"; fi
      [[ -n "$p_one" ]] || continue
      if ! grep -qxF "$p_one" "$KNOWN_IDS"; then
        warn_count=$((warn_count + 1))
        file_findings="${file_findings}$(printf "\n  ${YEL}WARN${RST}  ${BLD}%-22s${RST} line %s\n        %s\n        ${DIM}%s${RST}" \
          "PRAGMA-UNKNOWN-RULE" "$p_line" "$p_text" "No rule named '$p_one'. It suppresses nothing — see --list-rules.")"
      fi
    done

    if ! grep -qxF "$p_line" "$USED_PRAGMAS"; then
      warn_count=$((warn_count + 1))
      file_findings="${file_findings}$(printf "\n  ${YEL}WARN${RST}  ${BLD}%-22s${RST} line %s\n        %s\n        ${DIM}%s${RST}" \
        "PRAGMA-UNUSED" "$p_line" "$p_text" "This pragma suppresses nothing. The line below it no longer trips that rule — remove the pragma.")"
    fi
  done < "$PRAGMAS"

  if [[ -n "$file_findings" ]]; then
    echo ""
    echo -e "  ${BLD}${target}${RST}"
    printf '%b\n' "${file_findings#?}"
  else
    clean_count=$((clean_count + 1))
    if [[ "$VERBOSE" == "true" ]]; then
      echo ""
      printf "  ${GRN}%-7s${RST}  %s\n" "CLEAN" "$target"
    fi
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
printf "  %-13s %s\n" "CLEAN:"      "$clean_count"
printf "  %-13s %s\n" "SUPPRESSED:" "$suppressed_count"
printf "  %-13s %s\n" "WARN:"       "$warn_count"
printf "  %-13s %s\n" "FAIL:"       "$fail_count"
echo ""

if (( fail_count == 0 )); then
  echo -e "  ${GRN}${BLD}✓ Nothing here needs a shell newer than Bash 3.2 or a GNU userland.${RST}"
  if (( suppressed_count > 0 )); then
    echo -e "  ${DIM}  ${suppressed_count} hit(s) suppressed by pragma — list them with --verbose.${RST}"
  fi
  if (( warn_count > 0 )); then
    echo -e "  ${DIM}  Review the WARN entries — each names a macOS version floor, a behavior difference, or a stale pragma.${RST}"
  fi
  echo ""
  exit 0
fi

echo -e "  ${RED}${BLD}✗ ${fail_count} construct(s) will not work on the macOS target.${RST}"
echo -e "  ${YEL}These pass on every shell an AI session can reach. Only this check sees them.${RST}"
echo ""
exit 1
