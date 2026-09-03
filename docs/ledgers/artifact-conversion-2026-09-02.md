# Artifact conversion pass — what was converted, what was noted, what is owed

**Written:** 2026-09-02, session `01KcZvrKMgfenhrT9DvxW9Jk`.
**Companion to:** `docs/ledgers/artifact-migration-2026-09-02.md` — that ledger
says what needs migrating; this one says what happened to it.
**Volume:** `/Volumes/Data/reimage-CVG-0002160-500-20260816-open`.
**Repository revisions:** 138 (the conversion; committed `bb6d664`) and 139 (the
follow-ups in §4.2 and §4.4).

---

## 0. The backup, first

`_pre-conversion-backup-20260902/` at the artifact root — **201M**, `rsync -a` so
modification times survive, covering all seven pre-image categories touched plus
`reimaged-system/`.

It is **on the same volume**. It protects against a bad conversion. It does not
protect against losing the volume, and it is not an offsite copy.

---

## 1. Pre-image conversions — all seven categories

| Category | Before | After | Runs | Pointers | Sign-offs |
|---|---|---|---|---|---|
| `size-audit-reports/` | 9 runs, `# Size Audit Runs` manifest, no `official/` | manifest → `size-audit-index.md`, library owns `MANIFEST.md` | 9 | 7 | — |
| `loose-secrets-reports/` | 15 runs, `# Loose Secret Checks` manifest, no `official/` | manifest → `loose-secrets-index.md` | 15 | 11 | — |
| `toolkit-snapshot/` | 1 flat bundle, 2 symlinks, `latest-*.txt` | wrapped into `runs/`, pointers deleted | 1 | 1 | — |
| `performance-audit/` | 3 flat bundles, one per scenario | 3 lineages under `runs/` | 3 | 3 | — |
| `office-stability/` | evidence bundle + `.zip` + loose summary at category root; assessment under `checklists/` | one evidence run holding all three; assessment run; `checklists/` removed | 2 | 2 | 1 |
| `time-machine/` | 5 flat files, 1 status bundle, 1 verify file, 1 checklist | 7 lineages, per subcommand | 7 | 7 | 1 |
| `reimage-prep-checks/` | 11 dated capstones, `latest-*.txt` | `runs/pre-image-<stamp>/reimage-checklist.md` ×11 | 11 | 1 | 11 |

`repo-audit-reports/` (5 runs / 2 pointers), `system-inventory/` and
`managed-inventory/` were converted by Revisions 120, 121 and 127 and were not
touched. The E1 pin on `repo-audit-reports/official/pre-image` was left exactly
as it stands.

**Method, per category:** rename the domain manifest first, then reindex, then
verify — never the other way around. The first attempt at `size-audit-reports/`
returned *"Index is already current"* because the old manifest still contained
the run ids in backticks and the reindexer matched them. Renaming the manifest to
`<domain>-index.md` before reindexing (the Revision 120 pattern) is what makes
the reindex see an empty index and rebuild it.

**Run identity survived.** `reindex-artifact-runs.sh` derives the manifest
Completed column from the **run-id stamp**, not the directory mtime. Every
wrapped file kept the stamp it was named with, so a 2026-08-17 capture still reads
as 2026-08-17 after a conversion performed in September. This is what makes your
rule 3 hold structurally rather than by my care.

---

## 2. The one script change

`bin/capture-office-stability.sh` derived its run context from its internal
`PHASE` label — `pre-reimage` / `post-reimage` — where every other category, and
its own sibling `assess-office-stability.sh`, spells the phase `pre-image` /
`post-image`.

Fixed **before** converting that category, because a context is baked into the
run's manifest rows and its `official/` filename: converting first would have
meant migrating `office-stability/` twice.

`PHASE` itself is unchanged — it is the user-facing `--phase` value and appears in
filenames the runbook cites. Only the run context is normalised.

`bash -n` clean. All other lints unchanged from Revision 137, including the one
deliberate `verify-doc-paths.sh --all` MISSING it recorded as owed.

---

## 3. Mixed-mode splits — 24 of the 35

Specified by `docs/architecture/sign-off-consolidation.md` §3. Backup taken,
split performed, answers preserved.

| Group | Count | Destination |
|---|---|---|
| Boundary runs (`boundaries/`) | 16 | `reimaged-system/sign-offs/` |
| Restart runs (`restarts/`) | 6 | `reimaged-system/sign-offs/` |
| Time Machine evidence summary | 1 | `time-machine/sign-offs/` |
| Office-stability assessment | 1 | `office-stability/sign-offs/` |
| Phase 6B capstones | 11 | `reimage-prep-checks/sign-offs/` |

`reimaged-system/sign-offs/` now holds **25 answered files** (plus two
`latest-*.txt` pointers that predate this pass).

**No row was re-verified.** Answers were carried over verbatim — the 2026-08-18
capstone's 14 answered rows came across as `X`, `N/A`, `GitHub` exactly as
written — and each extracted file carries an **Answered against** column naming
the run it came from, plus a note stating that nothing was re-checked.

The one that changes a pointer's contents:
`verify-reimaged-system-exit-20260831-160233` is an official pointer target, so
splitting it changed what that pointer resolves to the contents of. Flagged in
the migration ledger as E3 and carried out knowingly.

---

## 4. Not converted, deliberately

### 4.1 Out of scope by your correction

**Phase 11B onward.** `restore-repos.md` and everything after it is yours to run.
The only thing taken from that range was `restore-repos-exit-20260825-042214`,
an existing artifact that needed a split — the exception you named.

### 4.2 Noted under rule 4 — all four answered 2026-09-02

| # | Item | Outcome |
|---|---|---|
| N1 | Six `manual-captures-required.md` inside `verify-reimaged-system` restart runs | **Closed — and my premise was wrong.** See below |
| N2 | `restore-docker-plan-*`, `restore-intellij-plan-*` in `restore-notes/` | Phase 12, yours to run. No change |
| N3 | June 2026 office-stability bundle under `home-files-backup/` | **Closed by D8** — the artifact root is the scope boundary. Positional, not a judgement about what a file looks like |
| N4 | Stray `Supported: 10A, 10B` in `record-restore-exit.sh` | **Closed**, and it was not alone. See §4.4 |

#### N1 — the file I called manual holds no answers, and the one beside it does

`manual-captures-required.md` has columns *Area · Manual Item · Why Manual* and
**no status column**. Nothing can be answered in it. It is generated rationale —
it enumerates the manual rows of `checklist.md` and gives a one-line reason each
cannot be scripted — regenerated identically on every run, and cited at its
in-run path by six documents as Phase 14's pre-flight input. It stays where it is.

Checking that turned up the file that does qualify. **`restart-checkpoints.md`**,
in the same six bundles, has a *Status* column with **6 rows, all `TODO`**, and
nothing automated ever writes to it. It is the purely manual artifact sitting in a
replaceable run directory.

Moved under the new **D7**, to
`reimaged-system/sign-offs/verify-reimaged-system-restart-checkpoints-20260819-013423.md`.

**One sign-off, not six.** The file is byte-identical across the five runs sharing
a generator version, and its rows are phase-level rather than run-level — there is
one set of answers to carry. `verify-reimaged-system.md` names the post-restart
bundle as the sign-off bundle, so that copy carries. Statuses were moved
untouched; all six are still `TODO`.

D7 and D8 are now in `docs/architecture/sign-off-consolidation.md` §1 and Revision 139, with the
answerable-status-column test written out so the next reader does not repeat my
mistake of trusting the filename.

### 4.4 N4 — the stray line, and the live defect under it

Three usage blocks still advertised **phase ordinals** where the code dispatches
on runbook names, contradicting the correct line directly above:

| File | Was | Now |
|---|---|---|
| `record-restore-exit.sh` | `Supported: 10A, 10B` under the real list | line removed; `restore-home` added, which R137 had left out |
| `record-restore-prereqs.sh` | `Supported: 10A, 10B` | the six real runbook names |
| `record-restore-state.sh` | `Supported: 10B` | the four real runbook names |

**And the defect R136 was supposed to have ended was still live.**
`record-restore-prereqs.sh` hardcoded `Supported: restore-runtime, restore-access`
in its required-argument error while `SUPPORTED_RUNBOOKS` listed six. Running it
with no `--runbook` told an operator that four of their phases do not exist. Now
`$SUPPORTED_RUNBOOKS`, like every other message in that script — and the
declaration moved above the check, because under `set -u` the fix as first
written died on an unbound variable before printing. Found by running all three
with no arguments; `bash -n` cannot see it.

The changelog sentence naming Revision 126 was removed from the same file. What
replaced it states the failure mode the shape prevents, without dating itself.

#### The broader sweep — scoped, not done

Roughly **40 comments** across `bin/` use the form *"it used to X"* / *"an earlier
revision Y"*. Those are rationale-by-contrast, not changelog: they explain why the
current code is shaped as it is by naming the shape that failed, and they stay
true as the code stands. Stripping them would remove design reasoning, so I fixed
only what is **stale** — a line contradicting the line above it, and a revision
number cited as a change record. Say the word if you want the rationale comments
gone too; that is a real pass, not a cleanup.

### 4.3 Held for the review pass, per rule 5

None of **E1–E7** was applied: no pin was set or moved, no exception was resolved,
and `artifact_run_retire_lineage` was **not** run against
`comparisons/official/restore-runtime-version-comparison` (E6). The one
retirement performed was `office-stability/checklists/`, which was part of the
conversion of that category rather than an E-row decision.

---

## 5. Re-runs — none were possible from here, all handed back

Every **RE-RUN** row in the migration ledger needs macOS: `tmutil`, `diskutil`,
`log`, `system_profiler`, and the volume mounted at its real path. This session
runs on Linux. Nothing was re-run, and nothing was faked.

Run these from the repository root on the Mac, in this order:

### 5.1 Phase 10A — `restore-runtime` (ledger row 5)

```
bash bin/compare-restored-state.sh --runbook restore-runtime --dry-run
bash bin/compare-restored-state.sh --runbook restore-runtime
bash bin/record-restore-exit.sh --runbook restore-runtime --dry-run
bash bin/record-restore-exit.sh --runbook restore-runtime
```

All latest-wins, all read-only. The existing 2026-08-20 exit is stale regardless
— it cites `post-image-restore-runtime-diff-20260820-032625`, a run id that no
longer exists (E6). **Do not edit that citation**; a fresh exit supersedes it.

### 5.2 Phase 10B — `restore-access` (ledger row 6)

```
bash bin/record-restore-state.sh --runbook restore-access --point after --dry-run
bash bin/record-restore-state.sh --runbook restore-access --point after
bash bin/record-restore-state.sh --runbook restore-access --point delta
bash bin/compare-restored-state.sh --runbook restore-access
bash bin/record-restore-exit.sh --runbook restore-access
```

**Do not re-run `--point before`.** `state/restore-access-before` is first-wins
and pinned to `20260824-084427` (E2). A late `before` is well-formed and wrong:
the library will index it and correctly refuse to advance the pointer, leaving a
misleading run in the manifest.

### 5.3 Phase 11A — `restore-git` (ledger row 7)

Nothing owed. `after`, `delta` and `exit` were recorded 2026-09-01 after their
producers settled. `before` is first-wins — leave it.

### 5.4 Phase 11B and later

Yours. The three `post-image-restore` bundles in `repo-audit-reports/runs/`
predate the sign-off and `MANIFEST.txt` and want a re-run, but that falls inside
the range you are running yourself.

---

## 6. Verification performed

- Each category converted **one at a time**, verified before the next was begun:
  run count, pointer count, and that every `official/` pointer names a run that
  exists on disk.
- Closing sweep for answerable manual rows still inside run directories: **none
  remain** except N1, N2 and N3 above.
- Library bracket exercised end-to-end on scratch categories before any real
  evidence was touched.
- `bash -n` on the one edited script.
- Lints at Revision 137 baseline: portability 74 clean / 0 WARN / 0 FAIL,
  runbook structure 29 FAIL / 5 WARN across 27 documents, doc-paths 1 MISSING
  (the deliberate one).

**Not performed:** `shellcheck` (unavailable here) and `/bin/bash -n` under macOS
Bash 3.2. Both are owed on the Mac, here and on Revisions 116–137.

---

## 7. Rule 6 — the rules I adopted that you did not name

You asked what you were missing. These are the ones this pass needed:

1. **Do not re-record a first-wins point unless the state it describes is still
   observable.** `before` and `pre-restart` pointers do not advance, so a routine
   re-run produces a well-formed run that is silently not the official one.

   **The exception, which you are right about:** the rule is about *state*, not
   about the clock. If the state the point describes has not yet been altered —
   the phase has not run against those targets, or the capture is provably of the
   same conditions — then a new run records the same moment, not a later one, and
   is a legitimate recording. Where that new run is better than a defective first
   one (the two pinned `pre-restart` runs are exactly this class), the pin moves
   to it **deliberately and with a reason recorded**, which is what a pin is for.

   What stays forbidden is the silent case: recording a `before` *after* the phase
   has changed the thing being measured, which produces a run that reads as a
   baseline and is not one.
2. **Preserve the run-id stamp, always.** The manifest's Completed column comes
   from the stamp, not the file's mtime. This is the mechanism behind your rule 3
   — as long as stamps are preserved, the data's time survives regardless of when
   the conversion ran.
3. **Move, never copy-and-delete.** A copy resets birth times and invites a
   half-finished state where both forms exist — which your own preferences rule
   out for code and which is worse for evidence.
4. **Rename a domain manifest before reindexing, never after.** Otherwise the
   reindexer sees the old run ids and reports the index already current.
5. **Fix the producer before converting what it produces.** A context is baked
   into run rows and pointer filenames; a rename after conversion means migrating
   twice.
6. **One category at a time, verified before the next.** A conversion error found
   after six categories is six categories to unpick.
7. **`$REIMAGE_ARTIFACT_ROOT` is the scope boundary** — now **D8**. A file
   outside it is out of scope whatever it resembles. Positional, so it can be
   applied without opening the file.
8. **A backup on the same volume is a conversion backup, not a disaster backup.**
   Stated so nobody later reads `_pre-conversion-backup-20260902/` as more
   protection than it is.

---

## 8. Status

| Area | Status |
|---|---|
| Pre-image conversions (7 categories) | **Complete** |
| Mixed-mode splits (24 artifacts) | **Complete** |
| Script alignment (`capture-office-stability.sh`) | **Complete**, Revision 138 |
| Usage blocks + the live `record-restore-prereqs.sh` defect | **Complete**, Revision 139 |
| Post-image re-runs | **Handed back** — §5, macOS required |
| Phase 11B onward | **Yours**, by your correction |
| N1–N4 | **Closed** 2026-09-02 — D7, D8, and the usage-block fixes |
| D7 purely-manual move | **Applied** — `restart-checkpoints.md` → `sign-offs/` |
| Rationale-comment sweep (~40 sites) | **Not done** — scoped in §4.4, needs your word |
| E1–E7 pins/exceptions | **Held** for the review pass, per rule 5 |
