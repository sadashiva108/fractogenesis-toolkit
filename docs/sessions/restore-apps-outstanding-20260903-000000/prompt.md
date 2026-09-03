# Session prompt — Restore Apps, and the outstanding business behind it

Copy everything below the rule into a new session.

---

Working in **fractogenesis-toolkit**. This session is **Restore Apps and
outstanding business**. Phase 11B (`restore-repos.md`) closed out over Revisions
131–155 and is ready to run for real; this session clears what those revisions
parked and then starts on `restore-apps.md` (Phase 12).

**FIRST: connect two folders.** Do not read, plan, or answer anything until both
are reachable:

- the repo: `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit`
- the artifact root: `/Volumes/Data/reimage-CVG-0002160-500-20260816-open`

If only one arrives, say which is missing and wait. Most items below verify
evidence on the volume, not just code in the repo. Do not work around a missing
folder by reasoning from memory or from this prompt; nothing here substitutes for
reading the files.

Once both are there, read in this order:

1. `.github/copilot-instructions.md` — repo conventions. §4b covers `docs/` and
   when to write to `docs/*-findings/` instead of widening a task.
2. `docs/sessions/session-responsibilities.md` — a second session,
   **Run-index design and evidence conformance**, owns files this work touches.
   Read it before your first edit.
3. the findings indexes and the 25 notes under it. Four are named below and are
   this session's actual agenda.
4. `APPLY-MANIFEST.md` Revisions 143–155 — the clone plan, `--hydrate`, and
   everything the Phase 11B work decided. Do not re-litigate those decisions;
   read them so you don't undo one.
5. `.github/ai-prompts/runbook-prompts/runbook-prompt.md` before editing any
   runbook, and
   `.github/ai-prompts/script-prompts/bash-script-authoring-and-review.md`
   before editing any script.

`.claude/CLAUDE.md` is a pointer to those, not a second copy.

## Standing rules

- **Never commit. I commit.** Leave the work uncommitted in the working tree.
- **Every repository change gets a new `APPLY-MANIFEST.md` revision.** Re-read
  the header immediately before writing your entry and take the next free
  number — I commit between your turns, so the number you saw an hour ago may be
  taken. Never edit a revision that has shipped; if you need to correct one,
  write the correction as a new revision.
- **Park anything found mid-task in `docs/*-findings/`** rather than widening the work.
  That rule has paid for itself repeatedly — four of the items below started as
  parked notes.
- **One file, one owner.** `bin/reimage-checklist.sh`, `.internal/artifact-runs.sh`
  and the shared run-index machinery belong to the other session. If this work
  reaches into them, flag rather than edit.
- **Target is macOS stock Bash 3.2 + BSD userland.** If you are on Linux with
  Bash 5.x, say so and name the environment every check ran in. `/bin/bash -n`
  against real 3.2 is owed for Revisions 116–155 and is item 7 below.
- Validate with `./bin/verify-doc-paths.sh --all`,
  `./bin/verify-runbook-structure.sh`, `./bin/verify-script-portability.sh`,
  and `bash -n`. Current baselines: portability **81 clean / 0 WARN / 0 FAIL**;
  structure **213 PASS / 5 WARN / 25 FAIL** across 27 documents; doc-paths
  **758 OK / 0 MISSING / 0 ANCHOR BROKEN**. A number that moves is either your
  bug or your improvement — say which.
- Anything you run against the artifact root must be read-only unless I have
  said otherwise. `bin/restore-repos.sh --dry-run` writes nothing anywhere and
  is the safe way to exercise Phase 11B against the live volume.

## Where things stand

`git log -1` is `9fea5eb`, tree clean, Revisions through 155 shipped.

The Phase 11B clone plan is filled in and live at
`$REIMAGE_WORKSPACE_ROOT/repo-plan/`: **6 selected, 19 excluded with reasons,
2 unreviewed** — `engagements` and `ingestion-related`, both of which the audit
recorded with **no remote at all**. Nothing can clone them; that decision is a
Time Machine recovery or an accepted loss, and it is item 6 below.

---

# Part A — outstanding business

Items 1 through 4 are the agenda. Do them in order; 5 through 8 are smaller and
can be folded in wherever they fit.

## 1. Rename every capture called `checklist.md` — and notice they are not all the same file

Read `docs/cross-cutting-findings/0004-boundary-runs-name-their-record-a-checklist/findings.md` first. It has the
terminology table and the Revision 116 history that made the name wrong, but it
only covers boundary runs. The problem is wider.

**42 captures on the volume are named `checklist.md`, in two categories:**

| Where | Count | What it actually is |
|---|---|---|
| `reimaged-system/boundaries/runs/<run>/checklist.md` | 36 | Automatic PASS/WARN/FAIL. *May this phase start / did it finish.* No human rows since Revision 116. |
| `reimaged-system/restarts/runs/<run>/checklist.md` | 6 | Automatic checks **plus 3–4 `TODO` rows a person answers**, at `initial`, `pre-restart`, `post-restart`. |

"checklist" is already the workflow's word for the pre- and post-image capstones
(`reimage-checklist.md`, 11 runs) and "sign-off" is its word for rows a person
answers. These 42 files are a third thing wearing the first thing's name.

**The restart records are a phase behind, and that is the real finding.**
Revision 116 moved human-answered rows out of boundary records precisely because
a run directory is replaced on every invocation and an answer written into one is
lost. The restart records never got that migration — they still carry `TODO` rows
inside the run directory. So the order is:

1. Move the restart records' human rows into `reimaged-system/sign-offs/`, the
   way Revision 116 did for boundaries. That is the fix; the rename is cosmetic
   next to it.
2. *Then* rename what is left, which by that point is the same kind of file in
   both categories.

**My recommendation for the name is `checks.md`.** It is the one word true at all
five points — entry, exit, initial, pre-restart, post-restart — plain, and
unclaimed by anything else in the workflow. `gate.md` says what the file *does*
and reads better for boundaries, but a restart capture is not a gate, and I would
rather have one name than two. Come back to me with your own view before renaming
anything; if you think the two categories genuinely want different names, say so.

**Check the consumers before you touch a producer.** Five scripts write the name
and at least four read it back:

- Writers: `bin/record-enrollment.sh`, `bin/record-reimaged-system.sh`,
  `bin/record-restore-exit.sh`, `bin/record-restore-prereqs.sh`,
  `bin/restore-access.sh`
- Readers: `bin/record-reimaged-system.sh:374,450` and
  `bin/record-restore-prereqs.sh:329` read a prior run's file to carry answers
  forward — and **`bin/reindex-artifact-runs.sh:101–104` greps it by name for the
  PASS/WARN/FAIL counts that go into every `MANIFEST.md`.** Miss that one and the
  manifest counts silently become zero, which nothing will fail on.

`bin/reindex-artifact-runs.sh` belongs to the other session. Check
`docs/sessions/session-responsibilities.md` and flag rather than edit anything on
that side.

**And it is entangled with the `boundaries` → `bookends` rename**, which I
approved earlier and which was never executed: 23 tracked files mention
`boundaries`, plus 36 artifact directories, plus a
`_pre-conversion-backup-20260902/` copy of both categories that should be left
alone. Scope all of it together and show me the plan before touching anything — a
rename that lands half-done across two sessions is worse than either state.

Say explicitly what happens to the 42 existing files: renamed in place, left as
they are with only new runs using the new name, or something else. Existing
evidence is not disposable.

## 2. The boundary "How to read this" block is boilerplate that contradicts itself

Found while reading
`reimaged-system/boundaries/runs/restore-access-entry-20260820-015233/checklist.md`.
It ends with:

> **FAIL** means the phase cannot proceed correctly. Both FAIL rows here fail
> quietly rather than loudly, which is why they are checked at all.
> **WARN** means proceed with a known limit. An unmounted artifact root is fine
> through Step 9; a missing inventory only costs you the Step 10 comparison.

That file has **8 pass · 0 warn · 0 fail**. There are no FAIL rows, so "both FAIL
rows here" describes nothing. Four of the 36 boundary records carry this sentence
and **all four have zero FAIL rows** — the block is emitted unconditionally and
was written for one specific phase's row set. "Step 9" and "Step 10" are likewise
hardcoded and belong to whichever runbook the text was drafted against.

Fix the producer so the explanation is derived from the rows actually present, or
reduce it to something true of every run. The same file also cites
`.internal/restore/record-restore-prereqs.sh`, which has since moved to `bin/` —
old artifacts keep the stale path, which is correct, but confirm no live script
still writes it.

## 3. Decide the Docker target, and capture the versions that actually work

Read `docs/runbook-findings/restore-docker/0024-restore-docker-stack-differs-from-pre-image/findings.md` in full. It is
the most consequential item here because `restore-docker.md` Steps 6–10 describe
a stack that is not on this machine.

The short version: the reimaged Mac was brought back up in a hurry from whichever
compose file was to hand. Elasticsearch is `8.9.0` where the backup recorded
`8.13.0`; Redis is `7-alpine` where it recorded `latest`; RabbitMQ is
`3.12-management` where it recorded `3-management`; Kibana is running and was
not; MarkLogic — which Steps 9 and 10 spend the most words on — **is not present
at all**. The compose file is in a different repository (`ese-policy-listener`
rather than `carrier-services-storage`) and the compose project name changed from
`elastic` to `docker`.

**My intent is to record the versions that are actually working**, because the
current stack is the one I have been running successfully and the pre-image
versions are the ones I would be reverting to. Take that as the starting
position, not as a settled decision — the gap note lists three options and I want
to see the consequences of mine spelled out before I commit to it:

| Option | Consequence |
|---|---|
| Restore the pre-image stack | Steps 6–10 as written. Reverts working versions to older ones |
| **Adopt the current stack** | Steps 6–10 rewritten against `ese-policy-listener`'s compose file; MarkLogic becomes optional |
| Treat the runbook as version-agnostic | Steps name the *services*, and the compose file comes from the plan rather than being hardcoded |

Two things to settle alongside it:

- A capture of the running stack is at
  `$REIMAGE_WORKSPACE_ROOT/docker-before-20260902-143519/` — images, containers,
  volumes, networks, compose projects, disk usage. It is in the workspace root so
  it survives a reimage, and it is the only record of the volumes and networks
  that exists on either side. Work out where that belongs permanently: it is
  evidence, and evidence lives under the artifact root in an indexed run
  everywhere else in this workflow.
- Both compose files live in repositories Phase 11B clones, so **no Docker step
  can run before `restore-repos` has brought its repository back**. The phase
  order already satisfies that; `restore-docker.md` Prerequisites does not say
  so. It should.

I also lost my Docker session by logging out of my enterprise account, so I
cannot re-probe the running stack right now — work from the capture, and say
plainly when an answer needs a live daemon.

## 4. Start on `restore-apps.md`

`restore-apps.md` is 715 lines, last updated 2026-09-02, with 14 steps and a
`## Supplemental Reference`. It is the next phase I will actually walk.

Do **not** rewrite it. Do what Phase 11B's first session did: read it against the
current conventions and the machine, and tell me the rough spots before changing
anything. Specifically:

- Which steps still describe artifacts, scripts or flags that have since moved or
  been retired. Phase 11B removed three emitted scripts and a flag over Revisions
  147–148; check `restore-apps.md` for the same class of staleness.
- Step 8 is an IntelliJ handoff and Step 9 a Docker handoff. Item 3 above governs
  Step 9. Step 8 should be read against the `project-metadata` rehydration source
  the clone plan now declares — Phase 11B may already be restoring what Step 8
  describes, in which case one of them is doing it twice.
- Whether its Step 0 and close-out match the boundary/state/sign-off shape that
  `restore-repos.md` Steps 0, 10 and 11 settled on.
- Whether the plan-note mechanism in Steps 1 and 14 still matches what
  `bin/restore-apps.sh` writes.

Give me a numbered list of findings with the file and step each is felt at, the
way `docs/sessions/restore-repos-refactor-20260902-000000/restore-repos-phase-11b-plan.md` is laid out, and let me pick
what gets done. Park anything out of scope in `docs/*-findings/`.

## 5. Review `.github/` and `.claude/` against what they describe

The instruction set has drifted from the tree it documents, and everything above
depends on it being right.

- `.github/copilot-instructions.md` is the authority. Confirm every path it cites
  resolves, that the build/lint commands still work, and that the loader /
  entrypoint / helper rules still match what `bin/` and `.internal/` actually do
  after Revisions 143–155 added `.internal/git/repo-plan.sh` and
  `.internal/git/repo-hydrate.sh` — both sourced-only libraries, which the
  classification in `.github/guides/script-types-and-locations.md` should cover.
- The **project instructions attached to my Claude sessions are stale** and I
  cannot see them from inside the repo. They still describe
  `.github/copilot-prompts/` and `.github/copilot-templates/`, which are now
  `.github/ai-prompts/` and `.github/ai-templates/`, and they cite a
  `runbook-fill-prompt.md` that no longer exists. Draft me a corrected version I
  can paste into the project settings — that file is not in the repo, so you
  cannot fix it directly.
- `.claude/CLAUDE.md` is a pointer by design. Confirm each of its five targets
  exists and that it has not quietly acquired a second copy of anything.
- `.claude/hooks/runbook-guard.sh` runs on every Edit/Write. Read it and tell me
  what it enforces and whether it still matches the runbook rules.
- There are `.DS_Store` files tracked under `.github/`. Say whether they are in
  `.gitignore` and should be removed.

## 6. Close the last two unreviewed repositories

`engagements` and `ingestion-related` are in the pre-image audit with **no
remote**. `bin/restore-repos.sh` reports them `no-url` — nothing can clone them,
so the only copy is whatever the backup staged. Both have carry-forward rows
(2 and 38). Work out what evidence exists for each — staged ignored files, Time
Machine, the home backup — and give me an exclusion reason I can write, or tell
me they are recoverable and how.

## 7. `/bin/bash -n` on real macOS Bash 3.2

Owed for Revisions 116–155. Every check in those revisions ran on Linux with Bash
5.x, where `mapfile`, `declare -A`, `sed -i` and `stat -c` all work silently.
`verify-script-portability.sh` catches those by regex but cannot see heredoc
context — Revision 142 is the proof, where a nested `$()` inside an unquoted
heredoc produced three empty report files that no linter caught. Run
`/bin/bash -n` against every script on this Mac and report what it finds.

## 8. Two naming decisions I have not made

Both are flagged in shipped revisions and neither is urgent. Bring them back to
me with a recommendation; do not change either on your own.

- **The sign-off header says `Plan`.** `signoff_finalize` labels its second
  argument `Plan` and all six calling phases pass their own evidence file — so
  Phase 11B's sign-off reads `Plan: .../restore-status.md`. That is the report,
  not a plan, and now that Phase 11B has a real clone plan in
  `$REIMAGE_WORKSPACE_ROOT/repo-plan/` the word points at the wrong one of two
  things. It is what sent me from the sign-off to `restore-status.md` looking for
  a row that was not there. `.internal/sign-offs.sh` is shared by six phases and
  the label is in every sign-off already written. (Revision 154.)
- **`reimaged-system/checklists/` was removed and I think that was premature.**
  It is the post-image capstone's output root — `bin/reimage-checklist.sh
  --phase post` creates it, and `bin/record-restore-prereqs.sh` reads it. Both
  references still draw it. Confirm whether removing it breaks Phase 14, and if
  so say what restores it.

Also outstanding from earlier: `manual-captures-required.md` — a purely manual
artifact still generated inside a run directory — belongs in a sign-offs folder.
Fold it into item 1, which is already moving the restart records' human rows to
the same place for the same reason.

---

# Part B — how I want this session to run

- Show me findings before edits. Phase 11B went well because the first session
  produced a numbered plan and I approved it before anything changed.
- One deliverable at a time. Do not batch four items into one turn.
- When you find a second defect while fixing the first, write it to `docs/*-findings/`
  and keep going. Say at the end what you parked.
- Name the environment every check ran in. "Tested on Linux" and "tested on the
  target Mac" are different claims.
- Every commit message: a short subject and at most a few lines of body. End with
  the `Co-Authored-By` and `Claude-Session` trailers.
