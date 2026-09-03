# The portability lint cannot see a defect that needs heredoc context

**Found:** 2026-09-02, Restore Repositories clone-plan session, while reproducing
`post-image-restore-runs-truncated`.
**Severity:** low. One known-dangerous construct is invisible to the check that
exists to catch exactly this class of thing.
**Owner:** unassigned — `bin/verify-script-portability.sh` is in neither current
session's file set.

## What is wrong

`bin/verify-script-portability.sh` evaluates a table of `rule_re` regexes line by
line. That shape catches everything it currently checks — `mapfile`, `declare -A`,
`sed -i`, `stat -c`, GNU-only flags — because each is recognisable from one line
in isolation.

It cannot catch a construct whose danger depends on **where the line sits**. The
case in hand: a nested command substitution is fine in ordinary code and
hazardous inside an unquoted here-document, because Bash 3.2's here-document
parser handles nested `$( )` poorly. The regex would have to know it is between
`<<EOF` and its terminator.

`bin/restore-repos.sh` carried exactly that, in the heredoc that writes
`restore-status.md`, through 0 WARN / 0 FAIL portability runs on every revision
since the rule table was written.

## Why it is worth a rule rather than a note

The lint's stated job is the constructs `bash -n` cannot see:

> On the Mac, `/bin/bash -n` catches parse errors against the real 3.2; the
> portability lint catches the runtime-level constructs `-n` cannot see. The two
> are complements, not substitutes.

A nested `$( )` inside a heredoc is precisely a runtime-level construct that
parses clean. It falls in the gap between the two checks, which is the gap this
lint exists to close.

## Shape of a fix

Track heredoc state while scanning. A single `awk` pass can hold "inside an
unquoted here-document" as a flag — set on `<<[-]?[A-Za-z_]` where the delimiter
is unquoted, cleared on the terminator line — and apply a small second rule set
only while the flag is on. Quoted delimiters (`<<'EOF'`) are inert and should not
be flagged.

Two rules would earn their place today:

| Inside an unquoted heredoc | Why |
|---|---|
| nested `$( … $( … ) … )` | Bash 3.2 here-document parser; the suspected cause of the truncated reports |
| unquoted array/word expansion feeding a substitution | word-splitting differences that only show at expansion time |

Not fixed here: the lint is shared tooling, the change alters its scanning model
rather than adding a row to its table, and this session's file set is Phase 11B
scripts and fragments.
