# Session responsibilities

Two sessions run concurrently against this tree. This file is the boundary
between them. Written 2026-09-01 by session `01KcZvrKMgfenhrT9DvxW9Jk`.

Where two sessions overlap, the rule is the same one that worked on 2026-09-01:
**one file, one owner.** Read freely, edit only what you own, and flag rather
than edit anything on the other side.

---

## Run-index design and evidence conformance

Session `01KcZvrKMgfenhrT9DvxW9Jk`. Brief:
`docs/sessions/run-index-design-20260901-000000/prompt.md`.

### Owns

- Items 2 through 7 of the brief — the prior-phase evidence gap check, the Time
  Machine conversion design, the run-index coverage audit, the post-image
  evidence inventory, the post-image recapture strategy, and pre-image structural
  conformance.
- `bin/reimage-checklist.sh` and the Phase 6B checks.
- `.internal/artifact-runs.sh` and the shared run-index machinery.
  **`bin/reindex-artifact-runs.sh` moved to the owner's side on 2026-09-03**
  (Revisions 156 and 157). It reads the per-run record by filename to count
  PASS/WARN/FAIL into every `MANIFEST.md`, so both renames had to change it or
  every row of the renamed category would have gone to a bare `—` without
  failing. `bin/record-reimaged-system.sh` moved with it, for F2 and F4.
- Every category **except** `repo-audit-reports/`, `gitignore-superset/` and
  `staged-ignored-files/` — those belong to Phase 11B for the duration of the
  refactor.
- `reimaging-scripts-guide.md` and `references/master-directory-reference.md`.
- `docs/ideas/`, and every `docs/*-findings/` file not assigned below.

### Does not touch

`restore-repos.md`, `bin/restore-repos.sh`, `backup-repos.md`,
`bin/backup-repos.sh`, the `.internal/git/` helpers, and any run under
`repo-audit-reports/`. Item 1 is finished and handed off; reaching back into it
is how the two sessions collide.

`restore-apps.md`, `restore-intellij.md` and `restore-docker.md` are the owner's
fast pass to circle back on. Not contended, but flag rather than edit.

### Completed

- **Revision 132 — `reimaged-system/time-machine/` retired.** The owner settled
  that the root-level `time-machine/` holds both phases, like every `capture-`
  category, so the empty second directory was dropped from
  `record-reimaged-system.sh`'s `mkdir -p` list and from three reference-doc
  paths, and removed from the artifact root. Committed and pushed.
- **Sign-off consolidation** — `docs/architecture/sign-off-consolidation.md`. Six
  owner decisions recorded, 35 mixed-mode artifacts inventoried, the split
  procedure and its backup, the inline-generator conversion list, and the
  capstone run-index design. Two steps are time-sensitive: moving
  `restore-repos.sh`'s sign-off root before Phase 11B first succeeds, and
  indexing the post-image capstone before Phase 14 runs.
- **The evidence conformance ledger** —
  `docs/ledgers/evidence-conformance.md`. Four tables (never run, stale,
  needs refactor, already refactored) across the whole artifact root, plus
  irrecoverable-data callouts, pin candidates, decisions-log coverage, the
  sign-off extraction list, and the sign-offs-versus-checklists decision. This is
  the input to items 4, 5 and 6.
- **Item 2 — prior-phase evidence gap check.** The verified map, and the
  conclusions that are not gaps, in `docs/sessions/run-index-design-20260901-000000/prior-phase-evidence-map.md`;
  seven gaps under `docs/*-findings/`. Design-only, no repository change. Headline:
  `restore-runtime`'s missing state walk is by design and closed, while
  `restore-apps` cannot be exited at all — `record-restore-exit.sh` has no
  `check_restore_apps()` — which, with 10B not checking that 10A finished, leaves
  the boundary chain open at both ends. Phase 12's exit going unrun is separate
  and deliberate: the phase is unfinished.
- **Revision 130 — the documentation lint stops counting `docs/`.**
  `verify-doc-paths.sh --all` scanned the gitignored notes as governance
  documentation, so its `OK` total moved whenever any session parked a note —
  713, then 745, then 860, in one day, with no regression among them. `docs/` is
  now pruned and the total is back to 713. `MISSING` and `ANCHOR BROKEN` were
  never affected and stay the rows worth quoting.
  `docs/cross-cutting-findings/0026-verify-doc-paths-counts-gitignored-docs/findings.md` is closed. Uncommitted.
- **Revision 129 — the Phase 6B repository-audit row.** `bin/reimage-checklist.sh`
  was testing a manifest heading Revision 120 retired, so a Phase 6B gate
  recorded `FAIL` against a manifest that was exactly canonical. Fixed by
  deleting the hand-written literal and using
  `ARTIFACT_RUNS_MANIFEST_HEADING` from `.internal/artifact-runs.sh`, which both
  callers now share. `docs/runbook-findings/reimage-prep-checks/0019-reimage-checklist-repo-audit-manifest-header/findings.md`
  is closed. Uncommitted, awaiting the owner.
- **Item 1 — Restore Repositories.** Plan, retrofit analysis and re-run ledger in
  `docs/sessions/restore-repos-refactor-20260902-000000/restore-repos-phase-11b-plan.md`. Handed off to the session
  below via `docs/sessions/restore-repos-refactor-20260902-000000/prompt.md`. Six gaps parked
  under `docs/*-findings/`. No manifest revision — the session wrote only to `docs/`,
  which is gitignored, and that is correct.

### Next, in order

1. **The artifact migration itself.** `docs/ledgers/artifact-migration-2026-09-02.md`
   is the work list; `docs/architecture/sign-off-consolidation.md` §3 covers the
   35 mixed-mode splits and `docs/architecture/time-machine-run-index.md` §5 the
   Time Machine move. Backup first, in both cases.
2. **Item 4 — run-index coverage audit.** Table 3 of
   `docs/ledgers/evidence-conformance.md` is the candidate list, already ranked
   by cost of waiting: `performance-audit/`, `office-stability/`,
   `toolkit-snapshot/`, `loose-secrets-reports/`, `size-audit-reports/`,
   `reimage-prep-checks/`. Three carry their own question —
   `toolkit-snapshot/` is the last category using symlink pointers, the two
   `*-reports/` need the Revision 120 rename treatment before anything can append
   to their manifests, and `office-stability/checklists/` holds evidence bundles
   that are really runs, whose producer's manual rows need extracting in the same
   pass. Read `docs/cross-cutting-findings/0009-dated-artifacts-cite-run-ids-a-rename-breaks/findings.md` first:
   every conversion here is a rename, and a rename breaks the citations already
   written against the old name.
3. **Item 5 — post-image evidence inventory.** Table 1 of the ledger is most of
   it; the work is confirming the `reimaged-system/` side rather than assuming
   it, and saying plainly that the answer is mostly *producers*, not artifacts.
4. **Item 6 — post-image recapture strategy.**
5. **Item 7 — pre-image structural conformance.** Lowest priority, do last.
   Note that D3 has relaxed its hard constraint: structure may move, with a
   backup. Content still may not.

Six parked gaps fold into this work rather than standing alone:
`internal-restore-directory-empty.md` into whatever next touches
`reimaging-scripts-guide.md`;
`office-stability-checklists-are-evidence-bundles.md` into item 4;
`staged-ignored-files-live-parent-root-bundles.md` into item 7;
`orphaned-comparison-lineage-runtime-version-comparison.md` and
`dated-artifacts-cite-run-ids-a-rename-breaks.md` into item 4; and
`boundary-runs-recorded-long-after-their-phase.md` into item 5.

Three gaps stand alone and want a revision of their own rather than a fold-in:
`recorder-usage-strings-understate-supported-runbooks.md` (one revision covers
both scripts), `boundary-recorder-coverage-is-uneven.md` (Decision 1 answered — close the chain
at both ends; Decision 2 waits on `restore-apps.md`), and
`restore-access-exit-predates-its-own-state-walk.md` (a re-run, not an edit).

Quote only `MISSING` and `ANCHOR BROKEN` from `verify-doc-paths.sh` in a session
brief, never the `OK` count. Revision 130 stopped that count drifting, but it is
still a figure that changes legitimately whenever a runbook gains a reference.

---

## Restore Repositories Refactor

Prompt: `docs/sessions/restore-repos-refactor-20260902-000000/prompt.md`.
Plan: `docs/sessions/restore-repos-refactor-20260902-000000/restore-repos-phase-11b-plan.md`.

### Owns

- `restore-repos.md` and `bin/restore-repos.sh`.
- `backup-repos.md` and `bin/backup-repos.sh`.
- `.internal/git/capture-repo-audit.sh`, `stage-ignored-files.sh`,
  `collect-gitignore-superset.sh`, and the rest of `.internal/git/`.
- The `repo-audit-reports/`, `gitignore-superset/` and `staged-ignored-files/`
  structure on the artifact volume, including whatever Decision A produces.
- These parked gaps: `repo-audit-tsv-column-shift.md`,
  `restore-repos-rsync-targets-pre-image-path.md`,
  `restore-repos-missing-exit-recorder-steps.md`, and the five that session
  filed itself — `caller-environment-precedence-covers-only-listed-keys.md`,
  `carrier-services-storage-foreign-remote.md`,
  `emit-extra-remotes-readds-the-clone-url.md`,
  `post-image-restore-per-run-manifest.md`,
  `post-image-restore-runs-truncated.md`.
- `docs/architecture/restore-repos-clone-plan.md`, which that session wrote and
  which is why `docs/architecture/` exists rather than `docs/design/`.

### Handed back — done

`bin/restore-repos.sh` wrote its sign-off to `repo-audit-reports/sign-offs/`; it
is a **post-image** sign-off and belongs under `reimaged-system/sign-offs/` with
every other one (`docs/architecture/sign-off-consolidation.md` D5). **Moved
2026-09-02** by the run-index session, while the old directory still did not
exist — one line at `bin/restore-repos.sh:334`, plus `restore-repos.md`'s
*What it sets up* bullet and the Phase 11B row in
`references/restore-file-reference.md`.

If the refactor session has an uncommitted `bin/restore-repos.sh` in flight, this
is a three-line region near `signoff_begin` and should merge cleanly — but check
it rather than assuming.

### Does not touch

`bin/reimage-checklist.sh` — the other session is fixing a Phase 6B row in it.
Flag rather than edit. Also `time-machine/`, `reimaged-system/sign-offs/`, and
every category outside the three named above.

### Must not do

- Re-record `--point before` for `restore-repos`. First-wins, clean, correctly
  timed, and irreplaceable.
- Run `rsync-repos-gitignored.sh` from any existing bundle.
- Re-open `gitignore-superset/` or `staged-ignored-files/live` for conversion.
  Both are settled in the plan's §2 with reasons.

---

## Shared rules

- **Never commit. The owner commits.** Leave work uncommitted in the working
  tree.
- `APPLY-MANIFEST.md` is at **Revision 130** — this session took 129 and 130. **Neither session reserves a number
  in advance.** Re-read the header immediately before writing an entry and take
  the next free one; if the intended number is taken, take the one after it. Two
  sessions collided on Revision 123 once already, and the resolution — renumber
  the later-committed entry forward — is the precedent.
- `docs/` is gitignored. A design-only session may correctly end with no
  revision at all.
- Both sessions run on Linux with Bash 5.x. `/bin/bash -n` against real macOS
  Bash 3.2 is owed on Revisions 116–128 and on everything either session writes.
  Name the environment a check ran in.
- Neither session can see `/Users/dkittrell/workspace/*`. Only the repo folder
  and the artifact volume are reachable. Anything about what is actually on disk
  in the clone roots has to be run on the Mac.
