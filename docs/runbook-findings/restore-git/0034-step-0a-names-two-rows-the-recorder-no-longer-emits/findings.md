# `restore-git.md` Step 0a names two rows the recorder no longer emits

**Found:** 2026-09-04, session `session_01KcZvrKMgfenhrT9DvxW9Jk`, while deciding
`0005` — the pointer for `restore-git-entry` was moving to a run whose FAIL
turned out to be the expected state rather than a defect.
**Severity:** the runbook tells the reader to read a row twice that will never
appear, and the hazard it describes is now unchecked at Step 0a.
**Scope:** runbook. Felt in `restore-git.md` Step 0a and in
`check_restore_git()` in `bin/record-restore-prereqs.sh`.

## What is wrong

`restore-git.md` Step 0a says:

> Its rows are derived from *Prerequisites* above, so the two cannot drift. The
> row worth reading twice is **Identity SSH keys restored and tight**: an unset
> `$GIT_WORK_SSH_KEY`, a key Phase 10B did not restore, or a key at the wrong
> mode does not produce an error.

`check_restore_git()` emits four rows and neither of these is among them:

| Row | State |
|---|---|
| `Identity SSH keys restored and tight` | **removed** |
| `Git identity values set` | **removed** |

Both were removed by commit `bb7e2d5`, *"Give every reimage.env key one owning
runbook and stop the template asking for values it does not own"*. Nothing in
`bin/` or `.internal/` emits either string today.

**The sentence that broke is the one asserting it could not.** *"Its rows are
derived from Prerequisites above, so the two cannot drift"* is a claim about a
guarantee that does not exist: the rows are hand-written in
`check_restore_git()`, and removing two of them left the runbook describing a
report that no longer exists.

## Why they were removed, and why removing them was right

They gated on `$GIT_WORK_SSH_KEY` and `$GIT_PERSONAL_SSH_KEY` being set in
`reimage.env`. **Step 0c is what sets them**, and it runs after Step 0a. So Step
0a could never pass on a first traversal of the runbook.

The volume holds the proof.
`bookends/runs/restore-git-entry-20260824-174717/bookend.md`, the first entry run:

```text
| Identity SSH keys restored and tight | `FAIL` | `GIT_WORK_SSH_KEY` unset; `GIT_PERSONAL_SSH_KEY` unset … |
| Git identity values set              | `FAIL` | unset in `reimage.env`: `GIT_WORK_NAME GIT_WORK_EMAIL …` |
```

Two FAILs recording that a later step had not run yet. `record-restore-prereqs.sh`
exits non-zero on FAIL, so Step 0a stopped the phase over its own ordering.

The conflation is precise and worth naming. *Prerequisites* requires that the
**key files exist on disk**, restored by Phase 10B — which is a true precondition.
The check tested that the **variables naming them are set**, which is Step 0c's
output. A file and the pointer to it are different objects, and only one of them
was Phase 10B's to produce.

## What it costs

**The runbook is wrong about its own output.** A reader following Step 0a looks
for a row to read twice and finds four rows, none of them it. There is no error;
there is nothing.

**The hazard is now unguarded at Step 0a.** The paragraph describes a real and
quiet failure — `ssh` skips a key it cannot use, authenticates as whichever
identity answers next, and the first symptom is a commit pushed under the wrong
account, found by somebody else, later. Nothing at Step 0a checks for it now. The
`Key fingerprints registered on GitHub` WARN and the Step 2 comparison are what
remain, and both are later and manual.

**It cost a pointer.** Under `0005`'s corrected first-wins rule for `entry`, the
official `restore-git-entry` run becomes `20260824-174717` — the run carrying
these two FAILs. It is pinned back to `20260901-083539` on the owner's
instruction, which is a pin spent on an artefact of this defect.

## The shape of the question, not the answer

Whether the rows come back at 0c, move to a later step, or stay gone is a
decision. What cannot stand is the current state: a runbook naming rows its
recorder does not emit.

Two things a decision will have to settle:

- **Where a check on `$GIT_WORK_SSH_KEY` belongs**, given that Step 0c writes it.
  A bookend recorded after 0c would be an `entry` recorded after the phase began
  writing, which `0005`'s first-wins rule now refuses to make official.
- **What replaces the guarantee.** *"Its rows are derived from Prerequisites, so
  the two cannot drift"* was never enforced by anything. Either something checks
  it, or the runbook stops claiming it.
