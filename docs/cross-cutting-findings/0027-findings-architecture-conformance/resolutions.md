# Resolutions — the findings-and-sessions architecture disagrees with itself

**Findings bundle:** `0027` · **Status:** `resolved`, 2026-09-04.
**Owner:** `restore-apps-outstanding-20260903-000000`.
**Decisions:** `decisions.md`, ten across seven findings.

Every finding below is closed by a change in this repository. The reasoning is in
`decisions.md` and is not repeated; this file records what was actually done.

| # | Finding | Resolved by |
|---:|---|---|
| 1 | §4b and §4c contradict on whether recording takes a revision | §4c's sentence deleted; the section now states 4b's rule |
| 2 | Four of five prompts omit the required reading | The rule scoped to prompts that can still start a session; `run-index-design`'s prompt gains a reading order |
| 3 | An index restates a count the manifest owns | The one-home rule in §4b, the two columns, and `bin/verify-findings-counts.sh` |
| 4 | `docs/INDEX.md` describes a directory it no longer matches | *"Currently empty"* removed; the one-home rule covers the class |
| 5 | Every `resolved` bundle is missing `decisions.md` | The migrated-bundle carve-out in §4c |
| 6 | The two session-state diagrams disagree | One diagram, in `docs/legend.md`; four states; `unclaimed` retired |
| 7 | Two identifiers recorded as unrecoverable are recoverable | The searches rule in §4d — **and a third identifier found** |

---

## What changed

**`.github/copilot-instructions.md`** — §4c loses *"Recording one touches no
tracked file and takes no manifest revision"* and states 4b's rule instead (1.1).
§4b gains the one-home rule, including that a copy is permitted where a check
catches it drifting (3.1, 3.2), and names the third findings tree. §4c gains the
migrated-bundle carve-out (5.1). §4d scopes required reading to prompts for
sessions that can still be started (2.1), drops `unclaimed`, states the three
terminal states by what happens to the findings (6.1, 6.2), and requires any
`not recoverable` to name its searches (7.1). §1 registers the new check.

**`docs/legend.md`** — six findings statuses, `withdrawn` added beside
`superseded`; four session states with the disposal table; one diagram of each,
which the architecture record now points at rather than redrawing.

**`docs/sessions/INDEX.md`** — `Bundles` and `Findings` as separate columns
(3.3), and a four-state key.

**`docs/INDEX.md`**, the three findings indexes, and
`docs/architecture/findings-and-sessions.md` — descriptions, status keys and the
retired diagram.

**`docs/sessions/run-index-design-20260901-000000/prompt.md`** — a reading order
with the instruction set first. It is `handoff`, so it will be read.

**`bin/verify-findings-counts.sh`** — new, 37 checks, all passing.

## Two things found while resolving

**The third identifier was recoverable.** `restore-git-phase-11a`'s
`metadata.md` said `not recoverable`; finding 7 flagged it as unchecked and
decision 7.1 required the searches to be named. Running them found
`session_01DQF5y9VQfaoRD9gnw4UcrN` on four commits of 2026-09-01, three of which
touch `restore-git.md` and one of which names Phase 11A. All three assertions of
unrecoverability in this repository have now been disproved by the same search,
which is the argument for 7.1 rather than an illustration of it.

**The finding tables are headed inconsistently.** `0001` and `0029` use
`## Finding status`; `0027` and `0028` use `## Findings`. The new check found it
by failing, and now identifies the table by its shape rather than its heading —
so the check does not impose a convention nobody has decided. The inconsistency
itself is unresolved and belongs with `0029`, which is where headings and
wording live.

## What this does not close

`0028` and `0029`, both `unresolved` and owned by the same session. `0029`
carries `Decide after: 0027, then 0028`, and this bundle answers the question its
findings 1, 2, 5 and 6 were waiting on — *where is a rule allowed to live* — for
the case of the manifest only. The general form is still open.

## Validation

Composed in a scratch copy outside the connected folder, applied as a patch.
Documentation lint **0 MISSING / 0 ANCHOR BROKEN**; runbook structure **213 PASS
/ 5 WARN / 25 FAIL** across 27 documents, unchanged; script portability **81
clean / 0 WARN / 0 FAIL** including the new script; findings counts **37 OK / 0
FAIL**. `bash -n` passes on `bin/verify-findings-counts.sh`.

Linux, Bash 5.x. `/bin/bash -n` against real macOS Bash 3.2 remains owed, and now
covers a script written today.
