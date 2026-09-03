# `restore-repos.md` opens its boundary but never closes it

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, while confirming the
evidence completeness map.
**Severity:** the phase has no recorded finish line, and its promised delta is
never taken.
**Owner:** the Restore Repositories Refactor session.
**Status: CLOSED** by Revision 131, 2026-09-02, same session — but not as 9a/9b/9c.
`verify-runbook-structure.sh` parses `### Step N` with `$3 + 0`, so a lettered
step heading reads as its number and breaks STEP-NUM. The recorders became
**Step 10 — Record the After-State and Delta** and **Step 11 — Close Out the
Exit Criteria**, following `restore-access.md` and `restore-runtime.md`. Step 9
lost the duplicate exit table in the same change. Kept for the reasoning.

## What is wrong

`restore-repos.md` invokes exactly two recorders:

| Step | Command |
|---|---|
| Step 0a | `./bin/record-restore-prereqs.sh --runbook restore-repos` |
| Step 0b | `./bin/record-restore-state.sh --runbook restore-repos --point before` |

It never invokes `--point after`, never `--point delta`, and never
`bin/record-restore-exit.sh`. `restore-git.md` and `restore-access.md` invoke all
three.

This is why the completeness map reads:

| Runbook | entry | exit | before | after | delta |
|---|---|---|---|---|---|
| `restore-repos` | yes | yes | yes | **no** | **no** |

The missing pair is **not a skipped step** — the runbook never called for one.
The `exit` run that does exist (`restore-repos-exit-20260825-042214`) was taken
by hand outside the runbook.

Step 0b makes the omission sharper by promising the result:

> The before-state is normally two empty roots; the delta against the
> after-state is then literally the list of what this phase restored.

A delta the runbook never takes.

## Fix

Add three steps after Step 9, mirroring `restore-git.md` (its Steps at lines
809, 848 and 868), each with a `--dry-run` line above the real one:

- **Step 9a** — `./bin/record-restore-state.sh --runbook restore-repos --point after`
- **Step 9b** — `./bin/record-restore-state.sh --runbook restore-repos --point delta`
- **Step 9c** — `./bin/record-restore-exit.sh --runbook restore-repos`

All three points are latest-wins, so all three are safe to take and safe to
retake. `--point before` is first-wins and must never be re-recorded — the
existing baseline is clean and correctly timed.

Adding steps after Step 9 renumbers nothing. Update the Table of Contents and
the back-links per `.github/ai-prompts/runbook-prompts/runbook-prompt.md`, and
re-run `./bin/verify-runbook-structure.sh` against its current baseline
(29 FAIL / 5 WARN across 27 documents, every remaining failure `NO-NOTE` or
`LEGEND`).

## Related

Step 9 also carries its own exit-criteria table that does not agree with
`check_restore_repos()` in `bin/record-restore-exit.sh`, and whose
*"Personal repos route via the personal SSH host alias"* row cannot be answered
yes on this machine — all 27 pre-image remotes are HTTPS. Reconcile the two in
the same change; the recorder owns the boundary.
