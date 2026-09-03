# Every post-image-restore run on disk stops before its report

**Found:** 2026-09-01, Restore Repositories Refactor session, while confirming
Change 7 against what `bin/restore-repos.sh` actually writes.
**Severity:** all three existing Phase 11B bundles are unusable as evidence.
**Owner:** unassigned — needs a run on the Mac to reproduce.

## What is wrong

All three runs under `repo-audit-reports/runs/post-image-restore-*` end early:

| File | State in all three runs |
|---|---|
| `raw/status.tsv` | complete, 27 rows |
| `clone-commands.sh` | complete |
| `rsync-ignored-files.sh` | complete |
| `rsync-repos-gitignored.sh` | complete |
| `restore-status.md` | **0 bytes** |
| `MANIFEST.txt` | **absent** |

The classification loop finished — `status.tsv` proves it — and then the
`cat > "$REPORT_MD" <<EOF` heredoc produced nothing and `MANIFEST.txt`, written
after it, never appeared. This is why the plan recorded that "no run on disk
has" a `MANIFEST.txt`: the script does write one, on a run that reaches it.

## Why it is not reproducible from a Cowork session

The same script, at the current HEAD, run on Linux with Bash 5.x against a
scratch artifact root, produced a 7,648-byte `restore-status.md` and a
`MANIFEST.txt` — both correct. So whatever kills the heredoc does not happen
here.

That points at the target shell rather than the code: macOS stock Bash 3.2 and a
BSD userland. The report heredoc is the one place in the script that runs
command substitutions inside an unquoted `EOF` under `set -u` — including
`$(printf '%s ' $DUPLICATE_LABELS)` with an unquoted expansion. `bash -n` cannot
see any of it, and neither can the portability lint.

## Reproduced, 2026-09-02 — and the divergence point is exact

The version that produced those bundles is `72f9f92` (2026-08-17); the run-index
conversion landed later. It was extracted and run against a scratch artifact root
carrying the *damaged* audit run and a `latest-run.txt` pointer, reproducing the
2026-08-25 inputs.

Under **Linux, Bash 5.1.16**, it ran to completion:

| File | Reproduced | On the volume |
|---|---|---|
| `raw/status.tsv` | 4182 | 4182 |
| `clone-commands.sh` | 2797 | 2797 |
| `rsync-repos-gitignored.sh` | 7933 | 7933 |
| `rsync-ignored-files.sh` | 5019 | 4887 |
| `restore-status.md` | **8175** | **0** |
| `MANIFEST.txt` | **524** | **absent** |

Three files are byte-identical. The fourth differs by exactly **132 bytes** —
22 rsync blocks times the 6-character difference between the scratch
`staged-ignored-files/live` path and the volume's. That is not a near miss; it is
the same output with one path substituted.

So **the code is not defective as Bash 5.x executes it**, and the divergence
begins at exactly one command:

```bash
cat > "$REPORT_MD" <<EOF
```

`restore-status.md` exists at 0 bytes, so the redirect was performed and the file
truncated. The failure is therefore during heredoc **expansion**, not parsing —
a parse failure would have left no file at all.

## The one construct unique to that heredoc

The three command files are written with plain `{ echo …; } > file` and contain
no command substitution. The report heredoc is the only place in the script with
a **nested command substitution inside an unquoted here-document**:

```bash
$( [[ "$DUPLICATE_LABEL_COUNT" -eq 0 ]] && echo 'Bundle labels are unique.' \
   || echo "Shared bundle label(s): $(printf '%s ' $DUPLICATE_LABELS). Reconcile by hand…" )
```

Bash 3.2's here-document parser is weak on nested `$( )`; the handling was
reworked in 4.x. Under `set -u` with no `set -e`, an expansion error in a
non-interactive shell is fatal and exits immediately — which is precisely the
observed state: file created, nothing written, nothing after it executed.

**This is a suspect identified by elimination, not a confirmed cause.** Egress
in this environment blocks `ftp.gnu.org`, so a real Bash 3.2 could not be built
to run the construct under. What *is* established: identical inputs, identical
output up to that command, and one construct in it that no other output path
uses.

## Still live at HEAD

`bin/restore-repos.sh` **still carries that construct** in its report heredoc.
Whatever killed the report on 2026-08-25 is still in the code path the next
`restore-repos.md` Step 1 run will take on the Mac.

`bin/verify-script-portability.sh` has no rule for it — its rule table is
regex-per-line, and this needs heredoc context.

## What to do

**Do not put a nested command substitution inside a here-document.** Compute the
cell into a variable first and interpolate the variable. That is a one-line
change per cell, it costs nothing, and it removes the only construct the evidence
points at.

If a run on the Mac still truncates after that, run it under `bash -x` and find
the line — but the construct above should be removed either way, because it is
unnecessary regardless of whether it is guilty.

A candidate lint rule is parked separately: the portability check cannot see this
class of defect, because its rules are per-line regexes and this one needs
heredoc context.

Until then, treat the three 2026-08-25 bundles as emitted-commands-only: their
command files are readable, their report is not.
