# Boundary runs call their record a `checklist`, and it is not one

**Found:** 2026-09-02, by the owner, on reading
`reimaged-system/boundaries/runs/restore-repos-entry-20260902-083713/checklist.md`.
**Severity:** naming only — nothing misbehaves. It matters because this is the
one word the workflow uses for two other things.
**Owner:** the repository owner. Producers belong to the run-index session's file
set; the runbooks that cite the name are the owner's next pass.

## The terminology, as the workflow actually uses it

| Term | What it names |
|---|---|
| **checklist** | A capstone. `reimage-checklist.sh` is the pre-image one — everything collected before the machine is erased. `verify-reimaged-system.md` is the post-image one — the state after restoring, and confirmation that nothing was missed. |
| **sign-off** | A record with rows a person answers by hand, kept with the phase or group it belongs to. `.internal/sign-offs.sh`, `reimaged-system/sign-offs/`. |

A boundary run is neither. It answers *may this phase start* and *did this phase
finish*, automatically, in PASS / WARN / FAIL rows. It is not a capstone over the
whole workflow, and it is not where a person writes anything.

## And it stopped being one at Revision 116

The name was defensible when the file still held the rows a person answered.
Revision 116 moved those out — *"the rows a person answers move out of the run
directory that replaces them"* — precisely because a run directory is replaced on
every invocation and an answer written into one is lost. Both producers say so in
their own comments:

```
# every invocation, so a row answered inside checklist.md is replaced by a fresh
…
# these are replayed into the sign-off and no longer written into checklist.md.
```

So the file has carried a name for a property it no longer has since Revision
116. The manual rows are in `reimaged-system/sign-offs/`, which is where the
owner's definition says they belong.

## What a rename costs

| Surface | Count |
|---|---|
| Producer scripts writing the name | 5 — `record-restore-prereqs.sh`, `record-restore-exit.sh`, `record-enrollment.sh`, `record-reimaged-system.sh`, `reindex-artifact-runs.sh` |
| Other scripts referencing it | 2 — `reimage-checklist.sh`, `.internal/sign-offs.sh` |
| Documents naming it | 14 — 11 runbooks and references, plus `APPLY-MANIFEST.md` |
| Files on the live volume | 39 — 33 under `boundaries/runs/`, 6 under `restarts/runs/` |
| Files in `_pre-conversion-backup-20260902/` | 38 more |

`APPLY-MANIFEST.md` quotes paths as they were at the time of a revision, so it is
**not** retro-edited — that is the stated reason it is excluded from the doc lint.

This is the failure written up in
[[docs/cross-cutting-findings/0009-dated-artifacts-cite-run-ids-a-rename-breaks/findings|dated-artifacts-cite-run-ids-a-rename-breaks.md]],
one level up: a rename breaks citations already written.

## One wrinkle before choosing a name

`restarts/runs/*/checklist.md` is **not** the same kind of file as
`boundaries/runs/*/checklist.md`. `record-reimaged-system.sh` grades it with:

> `Post-restart checklist answered` — `$n` unanswered row(s) … this step is the
> only one that fills them

That one *does* carry rows a person answers, which by the owner's definition puts
it closer to a sign-off than to either a checklist or a boundary record. A rename
that treats all 39 files as one kind would paper over a real difference.

## Resolved — Revisions 156, 157 and 159

Option **(ii)**, and further than the options above proposed. `boundaries/`
became `bookends/`, its record `bookend.md`, and the concept renamed with them
across 154 path occurrences and 153 more of the singular in prose. The restart
side settled separately: its bundle is a **capture**, and the record inside it is
`record.md` — a name that category already used for nine `enroll-and-stabilize-*`
runs, so the rename finished a convention rather than inventing one.

The three-way distinction now holds in the tree, not only in this note:

| | Is | Name |
|---|---|---|
| a phase's entry and exit pair | two records, one at each end | `bookends/` · `bookend.md` |
| one first-boot observation | a bundle | a **capture** |
| the rows inside one capture | one file | `record.md` |
| the pre- and post-image capstones | unchanged | `reimage-checklist.md` |

### The rule this note got wrong

It closed with:

> Whichever is chosen, existing runs are evidence and are not renamed in place —
> new runs take the new name and the old ones keep theirs, the same rule the run
> index applies everywhere else.

**The owner decided the opposite, and that is what shipped.** Every existing run
was renamed in place: 36 bookend records, 6 capture records, 11 companion
documents inside those captures, and 28 artifacts across `bookends/` and
`sign-offs/` whose text named the old filename.

Leaving old runs under the old name would have meant every reader carrying two
names for one thing indefinitely — `bin/reindex-artifact-runs.sh` reads the
record by filename for the PASS/WARN/FAIL counts in every `MANIFEST.md`, so the
two-name fallback it now holds would have been permanent rather than transitional.
A category with one name for one file is worth a rewrite of evidence that no
longer describes the tree it sits in.

The exception is `_pre-conversion-backup-20260902/`, which keeps both old names
throughout. It exists to preserve the state before the 2026-09-02 sign-off
conversion and is cited as a diff source by
`docs/cross-cutting-findings/0002-bookend-signoffs-cite-the-staging-path/findings.md`; renaming inside a snapshot
is how a snapshot stops being one.

### Still open

`bookends/MANIFEST.md` carries no rename row. Four of its rows already say
`migrated from` in the Note column, so the mechanism exists — one appended line
recording that the category was `boundaries/` and its record `checklist.md` until
2026-09-03 would make every sign-off written before that date traceable rather
than merely wrong. It is a write to the artifact root and needs the owner's word.
