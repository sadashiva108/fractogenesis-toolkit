# The Phase 10B exit was recorded a week before the evidence it stands on

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, item 2.
**Severity:** the phase is finished; its recorded finish is stale and understates
what was checked.

## What is wrong

`restore-access` lineage timestamps, read from `official/`:

| Lineage | Run | Date |
|---|---|---|
| `restore-access-entry` | `restore-access-entry-20260824-063529` | 08-24 06:35 |
| `restore-access-before` | `restore-access-before-20260824-084427` | 08-24 08:44 |
| **`restore-access-exit`** | `restore-access-exit-20260824-173543` | **08-24 17:35** |
| `restore-access-after` | `restore-access-after-20260831-220947` | 08-31 22:09 |
| `restore-access-delta` | `restore-access-delta-20260831-221008` | 08-31 22:10 |
| `restore-access-inventory-diff` | `…-20260831-220957` | 08-31 22:09 |

The exit answers *"did this phase finish"* — and it was recorded seven days
before the after-state, the delta and the comparison that demonstrate it did.
Nothing is wrong with the evidence; the ordering just means the exit graded a
machine that had not yet been walked.

## It is also missing a row

`check_restore_access()` in `bin/record-restore-exit.sh` today emits **nine**
automated rows. The recorded exit holds **eight**. The one added since is:

- **SSH host keys seeded**

which the Phase 11A session already flagged as carrying its own limitation:

> Step 12's `SSH host keys seeded` row still counts against the aliases present
> when it ran

— and Phase 11A rewrites `~/.ssh/config` afterwards, so a re-run taken now
measures the post-11A alias set rather than the post-10B one. That is a more
useful answer than the one currently recorded, but it is a different question,
and the write-up should say so rather than pretending the two are the same row.

## Plan

Re-run the exit. `exit` is latest-wins, so this is **safe**: the pointer advances
and the 08-24 run stays indexed as the record of what was true that day.

```bash
./bin/record-restore-exit.sh --runbook restore-access --dry-run
./bin/record-restore-exit.sh --runbook restore-access
```

Expect nine rows rather than eight. Read the new **SSH host keys seeded** row
against the caveat above before accepting it.

Do **not** re-record `--point before`: first-wins, and the 08-24 baseline is
correct. `after` and `delta` are current as of 08-31 and need nothing unless the
machine has moved since.

## Related, not the same

`restore-runtime` has the same shape and worse: exit 08-20, but the comparison
its exit row grades has been superseded twice since (08-20, then 08-31). Its
`Runtime comparison still current` row re-probes live tools, so a re-run there
answers a genuinely current question. Same command, `--runbook restore-runtime`.
