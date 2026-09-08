# Resolutions — `verify-doc-paths.sh --all` scans `docs/`, so its OK baseline cannot hold

**Bundle:** `0036-verify-doc-paths-counts-gitignored-docs`  
**Session:** `session-management-re-evaluation-20260906-110105` (`session_01FhFbEgG4wmrtJqUCcryNVQ`)  
**Decisions:** `decisions.md`, one across one finding.

The reasoning is in `decisions.md` and is not repeated; this file records what was
actually done.

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F1 | D1 | `bin/verify-doc-paths.sh` scans `docs/`; the prune is gone and two declarable verdicts replace it | 225 | `44c5289` |

---

## What changed

**`bin/verify-doc-paths.sh`** — the `-path './docs/*' -prune` clause is removed, so
`docs/` is read for the first time. The comment that justified the prune is
replaced with what is true: its first reason holds — a record quoting a path as it
stood is the record working — and **its second expired at Revision 162**, when all
of `docs/` became tracked. The comment went on calling those files *"gitignored
working notes"* that *"never reach a fresh clone"* for six weeks after that
stopped being true, which is F1 in the file itself.

**Two declarable verdicts, not one.** Option (iv) as decided provided `proposed`:
a reading may declare a path that does not exist yet. Scanning `docs/` surfaced
**38 references**, and reading them changed the shape of the answer — almost none
were proposed paths. They were **records citing paths correct at the time**, which
must not be repaired. `proposed` alone would have left the check reporting 38
failures that nobody should act on, and it would have been pruned again inside a
month, for the same reason it was pruned the first time.

So `historical` joins it, per-path and whole-document:

```text
<!-- proposed: bin/verify-session-findings.sh -->
<!-- historical: bin/verify-findings-counts.sh -->
<!-- historical-record -->
```

**That is also `0046`'s remedy**, whose own reading says *"the remedy is a marker
or a check."* One instrument answers both findings.

**Twenty-two documents declare their references.** Historical records — the
`resolutions.md` files, the ledgers, the handoffs — take the whole-document form;
three never-built scripts take `proposed`.

**Two broken anchors repaired**, both retitled headings nothing had noticed:
`restore-docker-teardown-and-test.md`'s TOC entry missing its backticks, and
`time-machine-run-index.md` pointing at *"9. Open decisions"* where the heading
reads *"9. Decisions — both settled"*.

## What the numbers do now, and why the baseline question is settled differently

| | Before | After |
|---|---|---|
| OK | 780 | 1714 |
| PROPOSED | — | 11 |
| HISTORICAL | — | 67 |
| **MISSING** | **0** | **0** |
| ANCHOR BROKEN | 2 | **0** |

**The OK total still moves whenever a session parks a note**, and that is fine:
option (iii) — stop quoting the OK total as a baseline — is what F1 argued for and
this resolution does not resurrect it. `MISSING` and `ANCHOR BROKEN` are the rows
that mean something, and they are the rows the prune was suppressing.

## What was NOT done

**Nothing verified on macOS.** The change is `find` argument handling and shell
string matching, both run on Bash 5.1.16 with GNU coreutils in a Linux VM. The
Bash 3.2 target has not seen it.

**The two stale citations this change was needed to catch were found by grep, not
by the check.** `session-responsibilities.md` and this session's own `prompt.md`
both named `./bin/check-manifest-revision.sh` after it moved, and the checker
could not see them because it did not read `docs/` — F1, biting during F1's own
repair. They are fixed; the ordering is worth recording.
