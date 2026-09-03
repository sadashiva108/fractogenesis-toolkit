# Final summary — Restore Repositories: the declared clone plan

**Completed:** 2026-09-02. **State:** `closed`.

## What it contributed

| Revisions | What |
|---|---|
| 143–150 | The clone plan's declared form, the code that reads it, the Step 0d that sets it up, the run that proposes one, `--hydrate`, a `--dry-run` that writes nothing, and the fields that were stored and never read. |

It also produced `docs/architecture/restore-repos-clone-plan.md`, which is why
`docs/architecture/` exists rather than `docs/design/`.

Commit hashes are not individually attributed — see the note in the sibling
Restore Repositories Refactor summary. `APPLY-MANIFEST.md` Revisions 143 through
150 are the record.

## What it left behind

Finding `0015` — the portability lint cannot see heredoc context — recorded while
reproducing the Revision 142 defect. Still `unresolved`, and cross-cutting.

## Owed

Nothing. The plan it built is live at `$REIMAGE_WORKSPACE_ROOT/repo-plan/` and
Phase 11B has run against it.
