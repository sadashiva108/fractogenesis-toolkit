# Decisions — renames break citations, and only a record's values are frozen

**Bundle:** `0030-renames-break-citations-and-which-may-be-repaired` · **Status:** `in progress`
**Decided:** 2026-09-03, session `session_01PcgHu9kz9Hm5RatLQuFR8H`, owner present.
**Supersedes:** `0009-dated-artifacts-cite-run-ids-a-rename-breaks`.

## Decisions carried from `0009`

`0009` has no `decisions.md`. Nothing was formally decided against it, so nothing
carries forward and nothing needs re-affirming.

Its `findings.md` does state a position under *Plan* — *no code change proposed,
and no repair of the 2026-08-20 checklist* — which is a reading's conclusion
rather than a recorded decision. **D2 supersedes it**, and says so rather than
quietly departing from it.

---

## D1 — Supersede `0009`; do not edit it and do not withdraw it

`0009`'s reading holds. What changed is its conclusion, and a reading is not
rewritten to match what was later concluded.

**Rejected — correct `0009` in place.** `findings.md` is written once and
corrected only for accuracy. Narrowing its *Plan* is not an accuracy correction;
it is a different answer to the same reading, which is what a superseding bundle
is for.

**Rejected — `withdrawn`.** The sixth status, added in Revision 177's line of
work, means *the reading is dropped and nothing replaces it*. This reading is not
dropped — it is carried forward almost intact. `superseded` retains the original
and names its replacement, which is what the owner asked for.

**Rejected — leave `0009` `unresolved` and put the rule somewhere else.** The
rule contradicts `0009`'s stated plan. Two live documents disagreeing about
whether a citation may be repaired is worse than either answer alone.

`0009` stays listed in `run-index-design-20260901-000000`'s manifest at status
`superseded`. Superseding a reading does not retroactively change who recorded or
held it.

## D2 — A record's values are frozen; its references are not

**Decided**, in the owner's words:

> A dated record's **values** are never edited — dates, measurements, verdicts,
> counts. A **reference** inside one — a filename, a path, a run id — may be
> repaired when the thing it names still exists, provided any timestamp in the
> name is retained exactly. The stamp is what binds the citation to the same
> evidence; changing it would falsify. Repairing the name around it restores a
> pointer.

**And the edge case is decided with it:** a reference that was *wrong when
written* — naming a file the producer never created — is still a reference and
not a value, and may be repaired. Recorded explicitly because the rule as stated
does not reach it, and finding 5 line 8 is an instance.

**Rejected — `0009`'s blanket prohibition.** It treats a pointer and a
measurement as the same object. Its own instance shows the cost: it declined to
repair a citation whose target it had already found on the volume, unchanged,
under a new name.

**Rejected — permit repair only where a backup preserves the original.** Argued
for, because the backup is what made finding 5's repair safe. Rejected because it
confuses *safe* with *lawful*: the reason a reference may be repaired is that it
is not evidence, and that is true whether or not a copy exists. A backup lowers
the cost of being wrong; it is not the thing that makes the repair legitimate.

**Rejected — require the repair to note itself in the artifact.** A dated record
gaining an editorial footnote is a change to the record. The manifest `rename`
row of finding 3 is the right place for that, which is why finding 3 is held open
rather than answered here.

## D3 — Finding 5's two lines are repaired, and the repair is recorded

Done 2026-09-03, on the owner's direction, in
`office-stability/runs/pre-image-office-stability-assessment-20260817-175050/README.md`:

```text
7  - `pre-image-office-stability-checklist.md`  →  - `office-stability-assessment.md`
8  - `watcher/marker-timestamp.txt`             →  - `watcher/marker-and-current-time.txt`
```

Written in place, no unlink. Every path in that README now resolves. The
pre-conversion copy under `_pre-conversion-backup-20260902/` retains both
original lines, so what the August producer wrote is still on the volume.

**Rejected — repair line 7 only.** Recommended by this session before the backup
was checked, on the reasoning that line 8 was the sole surviving trace of a
producer defect. It was not: the backup holds it, and the current producer no
longer has the defect. The recommendation did not survive its own evidence.

**This was an evidence write**, made with the owner's word for that specific run,
and it is the only one this session has made.

## D4 — `0009`'s own stale path is not repaired

Finding 4 shows `0009` citing `boundaries/…/checklist.md`, which Revision 156
moved. Under D2 that is repairable — it is a path, its target exists, and there
is no stamp to preserve.

**Decided: leave it.** The owner asked that the original be retained, and a
superseded bundle is retained as it was written. This bundle records the current
path instead, so a reader following `0009` reaches the evidence through finding 4.

**Rejected — repair it, since D2 permits it.** D2 governs whether a repair
falsifies a record. It does not override the separate property that a superseded
reading is frozen. Two different rules, and the narrower one wins here.

## D5 — The `bookend.md` citation is not repaired by this bundle

`bookends/runs/restore-runtime-exit-20260820-032645/bookend.md` line 19 cites
`post-image-restore-runtime-diff-20260820-032625`; the target exists as
`restore-runtime-inventory-diff-20260820-032625`. D2 permits the repair, stamp
retained, and it is stale twice — the lineage rename and the later dropping of
the `post-image-` prefix.

**Held, not decided.** It is an evidence write in `reimaged-system/`, and the
owner grants those one run at a time. Recorded here so it is a queued decision
rather than a rediscovery.

## D6 — Finding 3 is held open deliberately

The `rename` row belongs in `.internal/artifact-runs.sh` and in every category
manifest that has been through a conversion. That is a toolkit write plus an
evidence write across categories this session does not own, and the next
conversion is the event that should design it — item 4, still held by
`run-index-design-20260901-000000`.

**Rejected — decide it here to unblock the bundle.** `resolving` requires every
finding decided, so holding finding 3 open holds the whole bundle short of any
toolkit write. That is the correct outcome: the alternative is designing a
manifest row for conversions this session is not doing.

---

## What this authorises

**Nothing outside `docs/`.** Finding 3 has no decision, so the bundle cannot
reach `resolving` and no toolkit write is permitted. The one evidence write D3
records was made before this bundle existed, on the owner's direct instruction
for that run, and is recorded here rather than authorised by here.
