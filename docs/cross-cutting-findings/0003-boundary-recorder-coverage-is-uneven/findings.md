# The boundary-recorder family is applied unevenly across the phases it covers

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, item 2.
**Reframed:** 2026-09-02, after the owner confirmed Phase 12 is unfinished and
not running its exit was deliberate.
**Status: CLOSED** by Revisions 136 and 137, 2026-09-02. Decision 1 answered
yes and built: `check_restore_access()` gates on `restore-runtime-exit`, and
`check_restore_apps()` exists so Phase 12 can be closed. Decision 2 was answered
by building it — the rows are modelled on `check_restore_repos()`. Revision 137
added `restore-home` at both ends, so the chain now runs
**10A → 10B → 11A → 11B → 12 → 15**. `restore-intellij` and `restore-docker`
deliberately have none: they are expanded sections of `restore-apps.md`, not
phases. Kept for the reasoning.
**Severity:** not a defect in any one phase. The question was whether the family
is a convention or a set of one-offs.
**Decision 1 answered 2026-09-02: it is a convention, and the chain closes at
both ends.** Decision 2 remains open and is deliberately blocked on
`restore-apps.md` being finished.

## The owner's rule, which is the right one

> If `check_restore_apps()` is being used it should be used consistently or not
> at all wherever applicable.

`.github/copilot-instructions.md` already states the convention:

> `record-restore-prereqs.sh --phase <p>` runs at a phase's Step 0 and answers
> "may this start"; `record-restore-exit.sh --phase <p>` runs at its final step
> and answers "did it finish". **One check per boundary.**

So the intent is a convention. What is on disk is close to one, with two holes.

## Coverage as it stands

| Phase | prereqs `check_` | exit `check_` | state `targets_` | compare `collect_` |
|---|---|---|---|---|
| 10A `restore-runtime` | yes | yes | — *(by design)* | yes |
| 10B `restore-access` | yes | yes | yes | yes |
| 11A `restore-git` | yes | yes | yes | yes |
| 11B `restore-repos` | yes | yes | yes | — |
| 12 `restore-apps` | yes | **no** | yes | — |

The state and compare columns are not holes: `restore-runtime` deliberately has
no state walk (see `docs/sessions/run-index-design-20260901-000000/prior-phase-evidence-map.md` §3), and the
comparison probes exist only where there is a pre-image inventory to compare
against.

The **exit column is the hole**, and it is the one the convention names.

## The chain, which is where unevenness actually costs something

`record-restore-prereqs.sh` gates three phases on the previous phase's exit:

| Phase | Gates on |
|---|---|
| 11A `restore-git` | `restore-access-exit` |
| 11B `restore-repos` | `restore-git-exit` |
| 12 `restore-apps` | `restore-repos-exit` |

Two links are absent, at both ends:

- **10B does not check that 10A finished.** `check_restore_access()` opens on
  Java resolution rather than on `restore-runtime-exit`, even though
  `restore-runtime-exit` exists and is exactly the kind of precondition the other
  three check. `check_restore_runtime()` gates on the Phase 8 and 9 sign-offs
  instead, which is the correct shape for the first restore phase.
- **Nothing can gate on Phase 12 finishing**, because there is no
  `check_restore_apps()` in `record-restore-exit.sh` for a
  `restore-apps-exit` to come from.

So the chain runs 10B → 11A → 11B → 12 and then stops. That the exit was never
*run* for Phase 12 is deliberate — the phase is unfinished. That it could not be
run even when the phase is finished is the gap.

## Plan

Two decisions, then a small amount of work. Both belong with the owner, because
either answer is defensible and the wrong one adds ceremony to a workflow that
does not want it.

**Decision 1 — does the chain close at both ends? — ANSWERED 2026-09-02: yes.**

Two changes follow:

- Add a `restore-runtime` closed-out row to `check_restore_access()` in
  `bin/record-restore-prereqs.sh`, resolving
  `artifact_run_official "$b_root" "restore-runtime-exit"`, in the shape the
  three existing links already use (lines 540, 584, 704). `FAIL` when absent —
  Phase 10B genuinely depends on the toolchain 10A installs, and
  `check_restore_access()` already fails on Java resolution for that reason.
- Add `check_restore_apps()` to `bin/record-restore-exit.sh` plus its `case`
  entry and usage string, so a `restore-apps-exit` can exist. See Decision 2 for
  what it asserts, and the timing note below.

Every restore phase then both starts and finishes on the record, and each one
after the first checks its predecessor. This also settles the convention question
in the affirmative: `.github/copilot-instructions.md` reads as a rule because it
is one.

**Decision 2 — what would `check_restore_apps()` assert?**

Phase 12 has no fixed finish line, the same property `check_restore_repos()`
names explicitly:

> the operator restores the repositories they need now and returns for the rest,
> so "every repository is present" is the wrong question

Restoring apps behaves identically. So model it on `check_restore_repos()`:
automate presence and placement, leave *"what is left unrestored is a decision"*
as manual rows. Concretely, candidates worth considering — not a specification:

- the apps named in `restore-apps.md` that are checkable from the shell exist in
  `/Applications`;
- the two companion runbooks are accounted for — `restore-intellij` and
  `restore-docker` have plan notes under `reimaged-system/restore-notes/`, and
  both were written 2026-08-25;
- manual: apps deliberately not restored are a decision, not an oversight.

**This is not urgent and should not be built before `restore-apps.md` is
finished.** The runbook decides what its exit criteria are; a recorder written
first would guess them. Adding `after` and `delta` steps to the runbook belongs
to the same pass, since `targets_restore_apps()` already exists and only the
runbook is missing.

## Not in scope here

`restore-apps.md`, `restore-intellij.md` and `restore-docker.md` are the owner's
fast pass to circle back on. This write-up does not touch them.
