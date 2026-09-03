# `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, while validating
Revision 129.
**Severity:** low, but it silently invalidates a number two session briefs quote.
**Status: CLOSED** by Revision 130, 2026-09-01, same session — option (i), with
(iii) adopted alongside it in `docs/sessions/session-responsibilities.md`. With
`docs/` pruned the total returns to 713, the figure recorded before any note was
parked. Kept for the reasoning.

## What is wrong

`bin/verify-doc-paths.sh` line 172 selects documents with:

```bash
find . -name .git -prune -o -name __pycache__ -prune \
     -o -path './.github/ai-templates/*' -prune \
     -o -type f -name '*.md' -print
```

`docs/` is not pruned, so every note parked under `docs/features/`,
`docs/*-findings/` and `docs/sessions/` is scanned as if it were governance
documentation — even though Revision 128 made those contents gitignored working
notes that never reach a fresh clone.

`APPLY-MANIFEST.md` *is* excluded, with a stated reason: it quotes paths as they
were at the time of a revision, so a reference that no longer resolves is the
record working correctly. Session handoffs have exactly that property.

## Why it matters

The `OK` count moves whenever any session parks a note. Observed today:

| Recorded | Source | OK |
|---|---|---|
| 2026-09-01 | `docs/sessions/run-index-design-20260901-000000/handoff-20260901-222913.md` §5 | 713 |
| 2026-09-01 | `docs/sessions/run-index-design-20260901-000000/prompt.md` baseline | 745 |
| 2026-09-01, after this session wrote 9 files under `docs/` | measured | 860 |

None of those differences is a regression, and no session caused one by editing a
tracked document. But a brief that says *"compare against 745 OK"* is asking the
next session to compare against a number that changed for reasons unrelated to
its work — and the honest response, "the count moved and I did not cause it", is
indistinguishable from not having looked.

`MISSING` and `ANCHOR BROKEN` are unaffected and stay meaningful. Both are 0.

## The cheaper half of the finding

Scanning `docs/` is not purely bad: it did verify that every repository path
cited in this session's nine new notes resolves. That is a real check, just not
one that belongs in the same total as the governance docs.

## Options

- **(i)** Prune `docs/` like `.github/ai-templates/`. Restores a stable baseline;
  loses the incidental checking of parked notes.
- **(ii)** Keep scanning but report `docs/` separately, so the governance total is
  stable and the notes are still checked. More code in a lint nobody asked to
  grow.
- **(iii)** Leave it, and stop quoting an `OK` baseline in session briefs — track
  only `MISSING` and `ANCHOR BROKEN`, which are the rows that mean anything.

**(iii) is nearly free and (i) is one line.** Not decided here; both are cheap,
and the choice belongs with whoever next touches the lint.
