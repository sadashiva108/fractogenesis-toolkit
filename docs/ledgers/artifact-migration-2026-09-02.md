# Artifact migration ledger — what cannot be regenerated

**Written:** 2026-09-02, session `01KcZvrKMgfenhrT9DvxW9Jk`.
**Verified against:** `/Volumes/Data/reimage-CVG-0002160-500-20260816-open`.

**Status:** the pre-image half was executed 2026-09-02 under Revision 138. Rows
carrying **CONVERTED** below are done; see
`docs/ledgers/artifact-conversion-2026-09-02.md` for what happened to each, what
was noted, and the re-run commands handed back.

Every producer now writes indexed runs (Revisions 135–137). This ledger is the
other half: **the evidence already on the volume**, and whether the new layout
can be reached by re-running the refactored script or only by converting the
artifact in place with its values retained.

The test for each row is one question: **is the thing this artifact measured still
there to be measured?**

- **Pre-image** — no. The machine was erased 2026-08-17/18. Every pre-image
  artifact describes a system that no longer exists, so re-running a producer
  today captures a *different* machine and answers a different question. Every
  pre-image row is therefore **convert**, whatever the script now does.
- **Post-image** — mostly yes. The machine is live, the producers are read-only,
  and a re-run lands in the new layout for free. What cannot be re-run
  post-image is anything whose *point rule* forbids it, or that recorded a
  moment rather than a state.

Rows are in the order the phases run, and the **Step** column is the runbook step
that invokes the entrypoint — so a row can be walked back to the instruction that
produced it. Where a producer runs at several steps, all of them are listed.
Categories that are **not run categories** are listed after the tables rather
than padding them.

---

## Pre-image — Phases 0 through 6B

| # | Phase | Runbook | Step | Entrypoint | Context / lineage | Artifact directory | Re-run or convert |
|---|---|---|---|---|---|---|---|
| 1 | 2A | `backup-repos.md` | **Step 3** — Run the Size Audit | `bin/report-size-audit.sh` | `pre-image` | `size-audit-reports/` | **CONVERTED** R138 — manifest renamed `size-audit-index.md`, reindexed: 9 runs, 7 pointers |
| 2 | 2A | `backup-repos.md` | **Step 4** — Run the Repository Audit | `bin/backup-repos.sh` | `pre-image` | `repo-audit-reports/` | **DONE** — converted; 5 runs, 2 pointers. See exception E1 |
| 3 | 3B | `stage-loose-secrets.md` | **Step 1** — Find What Is Loose (re-checked at Step 4) | `bin/report-loose-secrets.sh` | `pre-image` | `loose-secrets-reports/` | **CONVERTED** R138 — manifest renamed `loose-secrets-index.md`, reindexed: 15 runs, 11 pointers |
| 4 | 4A | `capture-toolkit-snapshot.md` | **Step 2** — Capture the Toolkit Snapshot | `bin/capture-toolkit-snapshot.sh` | `pre-image-toolkit-snapshot` | `toolkit-snapshot/` | **CONVERTED** R138 — wrapped into `runs/`, symlinks and `latest-*.txt` deleted: 1 run, 1 pointer |
| 5 | 4B | `capture-system-inventory.md` | **Step 2** — Run the Capture | `bin/capture-system-inventory.sh` | `pre-image` | `system-inventory/` | **DONE** — Revision 127; 1 run, 1 pointer |
| 6 | 4C | `capture-performance-audit.md` | **Step 2** — Run the Capture | `bin/capture-performance-audit.sh` | `pre-image-performance-audit-{clean-boot,normal-workload,active-dev}` | `performance-audit/` | **CONVERTED** R138 — three lineages under `runs/`: 3 runs, 3 pointers |
| 7 | 2C | `capture-managed-inventory.md` | **Step 2** — Run the Capture | `bin/capture-managed-inventory.sh` | `pre-image` | `managed-inventory/` | **DONE** — Revision 121; 1 run, 1 pointer |
| 8 | 4D | `capture-office-stability.md` | **Step 3** — Run the Baseline Collector (verified at Step 5) | `bin/capture-office-stability.sh` | `pre-reimage-office-stability-evidence` | `office-stability/` | **CONVERTED** R138 — bundle, `.zip` and summary in one run. Context prefix fixed first (`pre-image-`, not `pre-reimage-`) |
| 9 | 4D | `capture-office-stability.md` | **Step 4** — Generate the Checklist Report | `bin/assess-office-stability.sh` | `pre-image-office-stability-assessment` | `office-stability/checklists/` | **CONVERTED** R138 — moved to `runs/`, `checklists/` removed, assessment sign-off extracted. E5 closed |
| 10 | 5 | `run-time-machine.md` | **Steps 3–5** — Start and Monitor · Confirm Completion and Verify · Capture Post-Run Evidence | `bin/run-time-machine.sh` | `pre-image-{status,logs,completion-check,compare,verifychecksums,diagnose}` | `time-machine/` | **CONVERTED** R138 — wrapped per lineage with original stamps: part of 7 runs / 7 pointers |
| 11 | 5 | `run-time-machine.md` | **Step 2** (`pre-run`) and **Step 5** (`verify-volume`, `final`) | `bin/record-time-machine-evidence.sh` | `pre-image-{status-bundle,diskutil-verify,evidence-summary}` | `time-machine/` | **CONVERTED** R138 — bundle and verify file moved; the checklist split, sign-off in `time-machine/sign-offs/` |
| 12 | 6B | `reimage-prep-checks.md` | **Step 2** — Run the Validation | `bin/reimage-checklist.sh --phase pre` | `pre-image` | `reimage-prep-checks/` | **CONVERTED** R138 — 11 runs + 11 extracted sign-offs, `latest-*.txt` deleted. `manual/` and `secrets-dmg/` untouched |

**Nothing in this table can be re-run.** Rows 2, 5 and 7 are listed because they
are the same generation of evidence and a reader checking coverage will look for
them; they need no work.

Two producers appear at a step in another runbook as well and are not separate
rows: `report-size-audit.sh` is re-run from `capture-system-inventory.md` Step 1,
`capture-managed-inventory.md` Step 1 and `run-time-machine.md` Step 1 as a
free-space check, and `reimage-checklist.sh` is re-run from `run-time-machine.md`
Step 6. Those invocations write into the same lineages the rows above name.

## Post-image — Phases 8 through 16

| # | Phase | Runbook | Step | Entrypoint | Context / lineage | Artifact directory | Re-run or convert |
|---|---|---|---|---|---|---|---|
| 1 | 8 | `enroll-and-stabilize.md` | **Step 7** (`pre-restart`, and `initial` when the context is omitted) · **Step 9** (`post-restart`) | `bin/record-enrollment.sh` | `enroll-and-stabilize-{initial,pre-restart,post-restart}` | `reimaged-system/restarts/` | **SPLIT DONE** R138 — mixed-mode rows extracted. Pointer untouched; nothing re-run. `manual-captures-required.md` files still inside runs — see N1 |
| 2 | 8 | `enroll-and-stabilize.md` | **Step 3** (`entry`) · **Step 10** (`exit`) | `bin/record-enrollment.sh` | `enroll-and-stabilize-{entry,exit}` | `reimaged-system/boundaries/` | **SPLIT DONE** R138 — mixed-mode rows extracted to `reimaged-system/sign-offs/`. Not re-run, per E4 |
| 3 | 9 | `verify-reimaged-system.md` | **Step 2** (`pre-restart`, and `initial`) · **Step 5** (`post-restart`) | `bin/record-reimaged-system.sh` | `verify-reimaged-system-{initial,pre-restart,post-restart}` | `reimaged-system/restarts/` | **SPLIT DONE** R138 — mixed-mode rows extracted. Pin untouched. See N1 |
| 4 | 9 | `verify-reimaged-system.md` | **Step 0** (`entry`) · **Step 6** (`diff`) · **Step 7** (`exit`) | `bin/record-reimaged-system.sh` | `verify-reimaged-system-{entry,exit,restart-diff}` | `reimaged-system/{boundaries,comparisons}/` | **SPLIT DONE** R138 — including `verify-reimaged-system-exit-20260831-160233`, an official pointer target |
| 5 | 10A | `restore-runtime.md` | **Step 0** (prereqs) · **Steps 10–11** (compare) · **Step 11** (exit) | `record-restore-prereqs.sh` → `compare-restored-state.sh` → `record-restore-exit.sh` | `restore-runtime-{entry,exit}`, `restore-runtime-inventory-diff` | `reimaged-system/{boundaries,comparisons}/` | **OWED — re-run on macOS.** Commands in `artifact-conversion-2026-09-02.md` §5.1. Nothing done here |
| 6 | 10B | `restore-access.md` | **Step 0** (prereqs, `before`) · **Steps 1–9** (`restore-access.sh`) · **Step 11** (`after`, `delta`, compare) · **Step 12** (exit) | `record-restore-prereqs.sh` → `record-restore-state.sh` → `bin/restore-access.sh` → `compare-restored-state.sh` → `record-restore-exit.sh` | `restore-access-{entry,before,after,delta,exit}`, `-inventory-diff`, `-cert-diff`, `-jdk-trust-{diff,result}` | `reimaged-system/{boundaries,state,comparisons}/` | **PARTIAL** — splits done; `after`/`delta`/compare/`exit` **owed, re-run on macOS** (§5.2). `before` untouched |
| 7 | 11A | `restore-git.md` | **Step 0** (prereqs, `before`) · **Step 8** (`after`, compare, `delta`) · **Step 9** (exit) | same family | `restore-git-{entry,before,after,delta,exit}`, `-inventory-diff` | `reimaged-system/{boundaries,state,comparisons}/` | **DONE** — splits done; nothing owed (§5.3) |
| 8 | 11B | `restore-repos.md` | **Step 0** (prereqs, `before`) · **Steps 1, 5, 9** (`restore-repos.sh`) · **Step 10** (`after`, `delta`) · **Step 11** (exit) | `record-restore-prereqs.sh` → `record-restore-state.sh` → `bin/restore-repos.sh` → `record-restore-exit.sh` | `restore-repos-{entry,before,after,delta,exit}`, `post-image-restore` | `reimaged-system/{boundaries,state}/`, `repo-audit-reports/` | **YOURS** — Phase 11B onward is run by the operator. The one exception taken: `restore-repos-exit-20260825-042214` was an existing mixed-mode artifact and was split |
| 9 | 12 | `restore-apps.md` | **Step 0** (prereqs, `before`) · **Step 1** (`restore-apps.sh`) · **Steps 8–9** (IntelliJ, Docker) · **Step 14** (plan-note sign-off) | `record-restore-prereqs.sh` → `record-restore-state.sh` → `bin/restore-apps.sh` (+ `-intellij`, `-docker`) → `record-restore-exit.sh` | `restore-apps-{entry,before}` | `reimaged-system/{boundaries,state}/`, `restore-notes/` | **YOURS** — Phase 12. Untouched; the plan notes are N2 |
| 10 | 15 | `restore-home.md` | **none yet** — the runbook calls no recorder | `record-restore-prereqs.sh` → `record-restore-exit.sh` | `restore-home-{entry,exit}` | `reimaged-system/boundaries/` | **N/A** — nothing produced. Both checks were added in Revision 137; the runbook steps that call them are owed |

**Phases 13, 14 and 16 have no rows: none has produced an artifact yet.**
Phase 15 appears as row 10 with nothing to migrate, because its recorders now
exist and the runbook steps that would call them do not.
Every producer behind them is converted, so their first run lands indexed. That
window is the reason the conversion order mattered.

---

## Exceptions and pins

Documented, not decided. Each needs its own call later.

### E1 — `repo-audit-reports/official/pre-image` is pinned to a re-derivation

`pre-image-20260901-234636` is a **re-derived** inventory, rebuilt from
`repo-audit-summary.txt` after the `repos.tsv` column shift; the original
`pre-image-20260816-035617` is the raw capture and is still indexed. Pinned so a
reindex cannot silently prefer the older, damaged one.

This is the only case in the tree where the official run is not the run the
machine produced, and any later migration of this category must not disturb the
pin. `PINNED-OFFICIAL.txt` inside the run carries it, so a copy carries it too.

### E2 — three first-wins pointers, two of them pinned

| Pointer | Run | Rule |
|---|---|---|
| `restarts/enroll-and-stabilize-pre-restart` | `20260818-235709` | first-wins, **pinned** — the default named `20260818-230958`, whose "Missing: 104" counted raw captures the script had not yet written |
| `restarts/verify-reimaged-system-pre-restart` | `20260819-012631` | first-wins, **pinned**, same class |
| `state/restore-access-before` | `20260824-084427` | first-wins, **pinned** |
| `state/restore-git-before`, `restore-repos-before`, `restore-apps-before` | various | first-wins, not pinned, correct as they stand |

**Do not re-record any of these while the state has moved.** A `before` or
`pre-restart` taken *after* the phase changed what it measures is well-formed and
wrong: the library indexes it and deliberately refuses to advance the pointer,
leaving a run that reads as a baseline and is not one. Conversion must preserve
both the run identity and the pin.

**The exception:** the rule is about state, not the clock. If the state the point
describes is still observable unchanged — the phase has not run against those
targets, or the conditions are provably the same — a new run records the *same*
moment and is legitimate. Where it is better than a defective first run, the pin
moves to it deliberately, with the reason recorded in `PINNED-OFFICIAL.txt`. Both
pinned `pre-restart` runs above are that class: the defaults counted raw captures
the script had not yet written, and a comparable state was still there to record.

### E3 — PARTLY DONE R138 (24 of 35) — artifacts that are mixed-mode and split rather than convert

Automated rows and answered rows in one file: 6 restart bundles, 17 boundary
checklists, 11 Phase 6B capstones, 1 Time Machine checklist. Their migration is a
**split**, not a relayout, and it is specified separately in
`docs/architecture/sign-off-consolidation.md` §3 — backup first, extract by
script, dry-run first.

One of them, `verify-reimaged-system-exit-20260831-160233`, is an **official
pointer target**, so splitting it changes what that pointer resolves to the
contents of.

### E4 — four boundary runs are dated the day the recorder was extended

`enroll-and-stabilize` and `verify-reimaged-system` boundaries are stamped
2026-08-31 / 09-01; both phases actually ran 08-18/19. Re-running them would move
the timestamps *further* from the phase, so they are convert-only in practice
even though their point rule allows a re-run.

Read `restarts/` as the honest clock for those two phases.

### E5 — CLOSED R138 — `office-stability/checklists/` is the wrong name, and the bundle predates the rename

Revision 137 renamed the producer and its contexts. The existing bundle sits
under `checklists/` — a name now reserved for the two capstones — with a
`latest-*.txt` beside it. Converting it means moving it to
`office-stability/runs/` under the new `pre-image-office-stability-assessment`
lineage, so the directory rename and the run conversion are one operation.

### E6 — OPEN — one orphaned lineage, and one dangling citation. The retire command was **not** run, per rule 5

`comparisons/official/restore-runtime-version-comparison` names a lineage nothing
writes: a one-off note migrated in by an early revision.
`artifact_run_retire_lineage` was added in Revision 136 for exactly this; the
command against the volume is still owed.

Separately, `boundaries/runs/restore-runtime-exit-20260820-032645/checklist.md`
cites `post-image-restore-runtime-diff-20260820-032625`, a run id that no longer
exists — the run survived a lineage rename, the citation did not. **Do not
"fix" it**: it is a dated record, and correcting it would be worse than leaving
it. See `docs/cross-cutting-findings/0009-dated-artifacts-cite-run-ids-a-rename-breaks/findings.md`.

### E7 — an artifact from a previous event

`office-stability/watcher-history/post-reimage-office-baseline-20260630-050905`
and its `.zip` are dated **2026-06-30**, six weeks before this artifact root was
created. They are history from an earlier Office incident, carried forward
deliberately.

They are not part of this reimage's evidence and should not be swept into a
`post-image-*` lineage by a conversion that matches on the `post-` prefix. Decide
whether `watcher-history/` stays outside the run index entirely — the likely
answer — before converting that category.

---

## Not run categories — no conversion, listed so the question is closed

| Directory | What it is | Why not |
|---|---|---|
| `gitignore-superset/` | stable input surface + generated companions | `backup-repos.sh` resolves three operator-maintained files from a fixed path; three readers depend on it, one a Phase 6B gate |
| `staged-ignored-files/` | three sibling **modes** — `dryrun/`, `dryrun-filtered/`, `live/` | a workflow's three states, not three runs. Two Phase 6B rows read fixed paths |
| `app-settings-backup/`, `home-files-backup/` | backup manifests (`# App Backup Manifest`, `# Local Files Backup Manifest`) | a different kind of manifest; no lineage question |
| `secrets-encrypted/` | the DMG and its manifests | one encrypted image, not a series |
| `public-certs/`, `reimage-confirmation/` | staged material and one IT confirmation | single artifacts with no lineage |
| `reimaged-system/enrollment/` | 8 screenshots from 2026-08-18 | manual evidence |
| `reimaged-system/restore-notes/` | `decisions.md` and the Phase 12 plan notes | the decisions log is deliberately outside the index |
| `reimaged-system/sign-offs/` | answered rows | Revision 116 made sign-offs deliberately un-indexed: officialness is computed, and keeping an answered file authoritative would depend on remembering to pin it |
| `office-stability/watcher-history/` | see E7 | |

---

## Summary

**Post-pass tally (2026-09-02):** all 9 pre-image convert rows are **done**;
24 of 35 mixed-mode artifacts are **split**; 0 re-runs performed — all owed on
macOS; E1–E4, E6, E7 **held** for the review pass; E5 **closed**.

| | Convert | Re-run | Already done | No conversion |
|---|---|---|---|---|
| Pre-image | **9** | 0 | 3 | 6 categories |
| Post-image | 6 lineage groups (all first-wins pointers, plus every mixed-mode run) | 5 lineage groups | 4 categories structurally | 3 categories |
| | | | | Phase 15: nothing produced |

The pre-image side is the whole job: nine categories holding evidence of a
machine that no longer exists, none of which a re-run can reproduce. The
post-image side is mostly a re-run away, with the first-wins pointers and the
35 mixed-mode artifacts as the parts that are not.
