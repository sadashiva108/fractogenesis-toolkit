# Evidence conformance ledger

**Status:** survey complete, decisions open.
**Written:** 2026-09-02, session `01KcZvrKMgfenhrT9DvxW9Jk`.
**Verified against:** the repo at HEAD and
`/Volumes/Data/reimage-CVG-0002160-500-20260816-open`.

Four tables answering four different questions, then the exceptions that do not
fit a table, then the sign-off extraction and the one design decision it forces.

This supersedes nothing. `docs/sessions/run-index-design-20260901-000000/prior-phase-evidence-map.md` remains the
detail for Phases 8–11A; this is the whole artifact root at one altitude, and it
is the input to items 4, 5 and 6.

---

## Table of Contents

- [[#1. Never run — the evidence does not exist|1. Never run]]
- [[#2. Ran, now stale — re-run needed|2. Ran, now stale]]
- [[#3. Needs refactor to the current structure|3. Needs refactor]]
- [[#4. Already refactored|4. Already refactored]]
- [[#5. Exceptions and callouts|5. Exceptions and callouts]]
- [[#6. Manual sign-offs still living inside automated captures|6. Manual sign-offs]]
- [[#7. Sign-offs versus checklists — the open decision|7. Sign-offs versus checklists]]

---

## 1. Never run — the evidence does not exist

Distinguish **not yet due** (the phase has not been reached — no action) from
**due and absent** (the phase ran and this was not produced).

| Evidence | Producer | Runbook step | Why absent | Action |
|---|---|---|---|---|
| `restore-repos` `after`, `delta` | `record-restore-state.sh` | none — `restore-repos.md` never calls them | **Due and absent.** Runbook gap | Restore Repositories Refactor session |
| `restore-apps` `after`, `delta` | `record-restore-state.sh` | none — `restore-apps.md` never calls them | Not yet due; Phase 12 unfinished | With the Phase 12 pass |
| `restore-apps-exit` | `record-restore-exit.sh` | none — and **no `check_restore_apps()` exists** | Not yet due *and* not runnable | Build after `restore-apps.md` is finished |
| `restore-runtime-exit` link into 10B | `record-restore-prereqs.sh` | `restore-access.md` Step 0 | **Due and absent.** `check_restore_access()` gates on Java, not on the previous phase | Decision taken: close the chain |
| `system-state-delta` | `bin/capture-system-state.sh` | — | **Never run at all.** No pointer, no run | Investigate before item 5 |
| `toolkit-snapshot` post-image | `capture-toolkit-snapshot.sh` | Phase 13A | Not yet due | Phase 13 |
| `system-inventory` post-image | `capture-system-inventory.sh` | Phase 13B | Not yet due — category **is** converted, so it will land indexed | Phase 13 |
| `managed-inventory` post-image | `capture-managed-inventory.sh` | Phase 13C | Not yet due — converted, will land indexed | Phase 13 |
| `performance-audit` post-image | `capture-performance-audit.sh` | Phase 13 | Not yet due — **will land unindexed** | Convert first |
| `office-stability` post-image | `capture-office-stability.sh` | Phase 13 | 1 present, 16 pre-image — **will land unindexed** | Convert first |
| Phase 14 checklist | `reimage-checklist.sh --phase post` | Phase 14 | Not yet due. `reimaged-system/checklists/` is empty for this reason and is correctly claimed | Phase 14 |
| `time-machine` post-image | `run-time-machine.sh`, `record-time-machine-evidence.sh` | Phase 16 | Not yet due — **will land unindexed and collide with Phase 5** | Item 3, convert first |
| `repo-audit-reports/sign-offs/` | `restore-repos.sh` | Phase 11B Step 1 | Never written — the three 2026-08-25 bundles predate `signoff_begin` | Refactor session |
| `time-machine/sign-offs/` | `record-time-machine-evidence.sh` | Phase 5 | Never written — the manual rows stayed in the flat checklist. See §6 | Item 3 |
| `reimage-prep-checks/sign-offs/` | `reimage-checklist.sh --phase pre` | Phase 6B | Never written — manual rows live in `reimage-prep-checks/manual/` instead. See §6 | Item 7 |

**The window named in the brief is the load-bearing row set here.** Four
categories are about to receive post-image evidence and three of them will land
unindexed. Converting after Phase 13 means retrofitting two lineages instead of
none, having produced a wrong answer in between.

## 2. Ran, now stale — re-run needed

Stale means the recorded evidence would say something different if taken again,
because its producer changed underneath it. Everything here is a **latest-wins**
point, so every re-run is safe and the old run stays indexed.

| Evidence | Run on disk | What changed under it | Re-run | Priority |
|---|---|---|---|---|
| `restore-runtime-exit` | `20260820-032645` | Its `Runtime comparison recorded` row cites `post-image-restore-runtime-diff-20260820-032625` — a run id that no longer exists after the lineage rename. The comparison it grades has been superseded twice. Its `Runtime comparison still current` row re-probes live tools | safe | **high** |
| `restore-access-exit` | `20260824-173543` | One row added since: `SSH host keys seeded`. Also recorded seven days *before* its own `after`, `delta` and comparison | safe | **high** |
| `restore-runtime-entry` | `20260819-093632` | `record-restore-prereqs.sh` changed 2026-09-01 | safe, low value | low |
| `restore-access-entry` | `20260824-063529` | same | safe, low value | low |
| `restore-apps-entry` | `20260825-065638` | same | safe — but retake at the real Phase 12 start | defer |
| `restore-repos` entry / exit / status bundles | 2026-08-25 | Every Phase 11B file changed since | Refactor session owns | n/a here |
| `enroll-and-stabilize` / `verify-reimaged-system` boundaries | 2026-08-31, 2026-09-01 | Recorded 13 days after the phases ran | **do not re-run** — a later retake moves further from the phase | see §5 |

**Explicitly not stale:** `restore-access-inventory-diff`, `after` and `delta`
(2026-08-31). The 2026-09-01 change to `compare-restored-state.sh` added the
`SSH routing hosts` probe inside `collect_restore_git()` only — verified at line
538, within lines 501–542. `restore-git`'s whole set was recorded after its
producers settled and needs nothing.

## 3. Needs refactor to the current structure

> **Producers converted 2026-09-02 (Revision 135).** Every script in this table
> now stages an indexed run. **No artifact was migrated** — the table below still
> describes what is on the volume, which is what the conversion has yet to be
> applied to. Per-script account and open items:
> [[capture-script-refactor-2026-09-02|capture-script-refactor-2026-09-02.md]].


Ranked by **cost of waiting**, not by effort — a category Phase 13 or 16 is about
to write into is urgent; one that is finished forever is not.

| Category | Shape today | Why it is not conformant | Cost of waiting | Owner |
|---|---|---|---|---|
| `time-machine/` | 7 flat files + a `sign-offs/` that was never created | No `runs/`, no `MANIFEST.md`, no `official/`. Phase 16 writes the same six subcommands into the same flat namespace, and `latest_matching_file` takes the newest match | **Highest.** Phase 16 produces a *wrong* answer, not a missing one | Item 3 |
| `performance-audit/` | 3 flat pre-image bundles, discriminated only by workload (`clean-boot`, `normal-workload`, `active-dev`) | `artifact-runs.sh` names this category by name as one where the pre/post prefix is the only discriminator | High — Phase 13 is next | Item 4 |
| `office-stability/` | 1 summary + 1 baseline dir + 1 zip + `checklists/` + `watcher-history/` (76 entries) | Flat, and carries a second `checklists/` convention of its own (see §7) | High — Phase 13 | Item 4 |
| `toolkit-snapshot/` | 1 bundle + `latest-docs` and `latest-pre-image-toolkit-snapshot` **symlinks** + a `latest-*.txt` | The only category still using symlink pointers. A symlink cannot express first-wins, cannot be pinned, and does not survive a copy | High — Phase 13A | Item 4 |
| `loose-secrets-reports/` | `MANIFEST.md` headed `# Loose Secret Checks`, `runs/` (15), `latest-run.txt`, plus `content-scans/`, `findings-ledger.tsv`, `open-findings.md` | Looks converted, is not — **no `official/`**. `_artifact_runs_ensure_manifest` will refuse to append. Needs the Revision 120 treatment. The three extra files are domain state the shared schema has no room for | Medium — pre-image, finished | Item 4 |
| `size-audit-reports/` | `MANIFEST.md` headed `# Size Audit Runs`, `runs/` (9), `latest-run.txt` | Same, minus the extra domain state | Medium | Item 4 |
| `reimage-prep-checks/` | 11 flat dated checklists + `latest-reimage-checklist.txt` + `manual/` | Flat, legacy pointer, and its manual rows are in a sibling directory rather than a sign-off. Phase 14 writes the *post* half to `reimaged-system/checklists/` — two shapes for one producer | Medium — Phase 14 will expose the asymmetry | Item 7 / §7 |

**Not run categories — decided, no conversion:** `gitignore-superset/` (stable
input surface), `staged-ignored-files/` (three sibling modes),
`app-settings-backup/` and `home-files-backup/` (backup manifests — `# App Backup
Manifest`, `# Local Files Backup Manifest`), `secrets-encrypted/` (a DMG and its
manifests), `public-certs/`, `reimage-confirmation/`,
`reimaged-system/enrollment/` (8 screenshots), `reimaged-system/restore-notes/`
(the decisions log and Phase 12 plan notes).

## 4. Already refactored

| Category | Pointers / runs | Landed in | Notes |
|---|---|---|---|
| `reimaged-system/boundaries` | 13 / 32 | — | Both halves of every phase pair |
| `reimaged-system/comparisons` | 8 / 23 | — | Includes one orphaned lineage — §5 |
| `reimaged-system/state` | 8 / 21 | — | |
| `reimaged-system/restarts` | 6 / 15 | — | Carries the one live pin — §5 |
| `repo-audit-reports` | 2 / 4 | Revision 120 | Domain manifest renamed to `repo-audit-index.md`; the pattern every later conversion follows |
| `managed-inventory` | 1 / 1 | Revision 121 | Three readers stopped globbing |
| `system-inventory` | 1 / 1 | Revision 127 | `--section` copies the bundle forward |

Seven categories converted; seven still to go. The four under `reimaged-system/`
were converted before the numbered revisions above and are the reference
implementation.

## 5. Exceptions and callouts

### Data that cannot be made up — the pre-image machine is gone

| What | Why it cannot be recovered | What to do instead |
|---|---|---|
| `repos.tsv` remote/count columns | `capture-repo-audit.sh` wrote tabs into a TSV. The machine it audited no longer exists | Re-derive from `repo-audit-summary.txt`, which holds every URL verbatim. Owner decision pending in the refactor session |
| Every pre-image capture's *content* | One machine, one moment, erased | Structural changes only — relayout, indexing, pointers. This is item 7's hard constraint and it applies to every row in §3 marked pre-image |
| `restore-repos` `before` beyond what it recorded | First-wins, and correctly timed at `20260825-034004` | Nothing. It is right |
| The true phase timestamps for Phases 8 and 9 boundaries | The recorders did not exist in that form when the phases ran | Read `restarts/` as the honest clock for those phases; never the boundary stamps |
| `restore-access-exit`'s `SSH host keys seeded` answer as of Phase 10B | The row was added later, and Phase 11A has since rewritten `~/.ssh/config` | A re-run answers the *post-11A* question. Record which question was answered rather than implying they are the same |

### Pin candidates

A pin overrides computed officialness and drops `PINNED-OFFICIAL.txt` inside the
run, so it survives a manifest rebuild and a copy.

| Run | Pinned? | Rationale |
|---|---|---|
| `restarts/official/enroll-and-stabilize-pre-restart` → `20260818-235709` | **yes, live** | The first-wins default had named `20260818-230958`, whose "Missing: 104" counted raw captures the script had not yet written rather than software the Mac lacked |
| `restarts/official/verify-reimaged-system-pre-restart` | **yes, live** (2026-08-24) | Same class |
| A re-derived `pre-image` repo audit, if Decision A takes option (ii) | **candidate** | A corrected re-derivation is newer than the original but is not a new capture. Pinning states that deliberately |
| Nothing else | — | No first-wins pointer in the pre-11B set is wrong. Do not pin to paper over a stale latest-wins run — re-run it instead |

### Decisions-log entries

`reimaged-system/restore-notes/decisions.md`, written by `record-decision.sh`,
holds what no capture can: 5 entries, all verified present — the SSH-key
retirement, the Phase 8 Step 4 exception, and three covering all seven standing
managed-app absences. `compare-restored-state.sh` reads it so a deliberately
accepted difference renders as `— **decided**` rather than being re-flagged every
run.

**This is the mechanism for every row in the "cannot be made up" table above.**
Where evidence is irrecoverable, the answer is a decision entry naming why, not a
fabricated capture. Two rows above have no entry yet and should get one: the
`repos.tsv` re-derivation, and the `SSH host keys seeded` question change.

### Other exceptions

- **Orphaned lineage.** `comparisons/official/restore-runtime-version-comparison.txt`
  points at a run nothing writes — a one-off migrated out of `restore-notes/`.
  Its pointer will never advance. → `docs/runbook-findings/restore-runtime/0014-orphaned-comparison-lineage-runtime-version-comparison/findings.md`
- **Dangling citations.** A dated artifact holds run ids as literal text, so a
  lineage rename breaks every citation already written and nothing can catch it.
  → `docs/cross-cutting-findings/0009-dated-artifacts-cite-run-ids-a-rename-breaks/findings.md`
- **`post-image-restore` has no recognised point suffix**, so every Phase 11B run
  prints `latest-wins applies` to stderr. Correct, mildly noisy.
- **`restore-runtime` has no state walk by design** — no `targets_restore_runtime()`
  and none wanted. Closed; do not reopen in item 5.

## 6. Manual sign-offs still living inside automated captures

`.internal/sign-offs.sh` already owns this problem and states the rule:

> A capture is regenerable: rerun the script and the newest run is the truth. An
> answered row is the opposite — it is the one thing in the artifact that cannot
> be recomputed, and the run directory is the one place guaranteed to be
> replaced.

Nine producers have adopted it. The table is which have not, and where their
answered rows sit today.

### Post-image — the target is `reimaged-system/sign-offs/`

| Producer | Sign-off root | Adopted? |
|---|---|---|
| `record-restore-exit.sh` | `reimaged-system/sign-offs/` | yes |
| `record-enrollment.sh` | `reimaged-system/sign-offs/` | yes |
| `record-reimaged-system.sh` | `reimaged-system/sign-offs/` | yes |
| `restore-apps.sh`, `restore-docker.sh`, `restore-intellij.sh` | `reimaged-system/sign-offs/` | yes — not yet exercised |
| `reimage-checklist.sh --phase post` | `reimaged-system/sign-offs/` | yes — not yet exercised |
| `restore-repos.sh` | `reimaged-system/sign-offs/` | yes — **corrected 2026-09-02**; it wrote to `repo-audit-reports/sign-offs/` until then |

`restore-repos.sh` was a post-image producer writing its sign-off into
`repo-audit-reports/`, a category shared with the pre-image audit. Its own
comment defended sitting outside `runs/` rather than inside one — which is right
— but not why it was not under `reimaged-system/sign-offs/` with every other
post-image sign-off. **Corrected 2026-09-02**, while
`repo-audit-reports/sign-offs/` still did not exist, so no answered row had to
move.

### Pre-image — document now, decide later

| Producer | Answered rows today | Conformant? |
|---|---|---|
| `record-time-machine-evidence.sh` | `time-machine/final-time-machine-checklist-20260817-082122.md` — automated rows and manual rows **in one flat file**, and a `sign-offs/` root the code names at line 473 but never created | **no** — the worst case in the tree |
| `reimage-checklist.sh --phase pre` | `reimage-prep-checks/manual/` — two hand-written files (`loose-plaintext-cleanup-signoff-20260817.md`, `manual-export-pass-criteria-20260817.md`), not the `sign-offs/` root the code names | **no** — a third convention |
| `office-stability-checklist.sh` | nowhere — its manual items are `record_check WARN` rows **inside the automated table** (lines 655–665), so they return as WARN on every run however often they are answered | **no** — the only producer with no sign-off at all |
| `backup-repos.sh` and the other Phase 2 producers | none — no manual rows | n/a |

So the workflow currently has **three** places an answered row can live —
`reimaged-system/sign-offs/`, `<category>/sign-offs/`, `<category>/manual/` —
plus one producer that has nowhere to put them and renders them as automated
warnings instead. Two of the three hold exactly one producer's output.

**Pre-image sign-offs cannot be migrated** — moving a signed-off file is the
thing item 7 forbids. What can change is where *new* ones land, and Phase 16 is
the next chance to prove the target before it is needed at scale.

## 7. Sign-offs versus checklists — the open decision

The owner's reading, which the evidence supports:

> checklists are more capstone lists at the end, sometimes only after all
> pre-image phases or post-image phases, as the final check list that all major
> artifacts have been captured and the state is satisfactory or as expected.

That is exactly what `reimage-checklist.sh` produces — Phase 6B for pre-image,
Phase 14 for post-image, one capstone each — and it is *not* what
`record-restore-exit.sh` produces, which is one phase's own finish line.

### The distinction worth encoding

| | Sign-off | Checklist |
|---|---|---|
| Scope | one phase, or one capture | a whole half of the workflow |
| Question | did *this* step's rows get answered | is the machine's state satisfactory overall |
| Cardinality | many per phase | one capstone per half, re-run until green |
| Lifecycle | answers carry forward run to run | each run supersedes; the last one is the record |
| Lives in | `reimaged-system/sign-offs/` | `reimage-prep-checks/` (pre), `reimaged-system/checklists/` (post) |

Under that split the current layout is *nearly* right and reads as accidental
only because the names collide. Two things break it:

1. `reimage-prep-checks/manual/` is a sign-off directory that avoided the word.
2. `office-stability/checklists/` is **neither** — and this took a second look.
   It is not a capstone, and it is not a sign-off either: the directory holds
   evidence bundles (system state, process transitions, watcher output, a
   command log) with a rendered report on top that is a *view* of the bundle
   rather than the artifact. Those are **runs**, the same shape as
   `time-machine/pre-image-time-machine-status-*/` and
   `performance-audit/pre-image-performance-audit-*/`. Confirmed by the owner
   2026-09-02. →
   `docs/runbook-findings/capture-office-stability/0013-office-stability-checklists-are-evidence-bundles/findings.md`

   Its *manual* rows are a separate problem: `office-stability-checklist.sh`
   emits them as `record_check WARN` inside the automated table, so they are
   answered rows wearing an automated verdict. That is §4 of the consolidation
   plan, not a naming question.

### Decided, 2026-09-02

The owner settled it, and further than option A went:

| # | Decision |
|---|---|
| D1 | Pre-image uses `<category>/sign-offs/` consistently — `manual/` and per-category `checklists/` retired as homes for answered rows |
| D2 | No mixed-mode artifacts going forward: automated output and answered rows are always separate files |
| D3 | Closed pre-image artifacts **may** be split — back up first, then move the manual half. This relaxes item 7's constraint for *structure*, not content |
| D4 | Runbook code blocks stop authoring artifact-root notes and inventories; a script writes them into a designated `sign-offs/` folder |
| D5 | The pre-image / post-image structural asymmetry stands for now — per-category folders pre-image, `reimaged-system/` post-image. Documented rather than changed |
| D6 | Capstone checklists are run-indexed |

Option (B) — one directory everywhere — is rejected: the capstone is genuinely a
different document, and D6 keeps `checklists/` meaningful by giving it a
lifecycle of its own. Option (C) is rejected outright.

The plan is in **`docs/architecture/sign-off-consolidation.md`**: 35 mixed artifacts
identified and grouped, the split procedure and its backup, the inline-generator
conversion list with the six machine-writing blocks explicitly excluded, the
capstone run-index design, and a seven-step order.

Two things in it are time-sensitive rather than merely queued:

- ~~**`restore-repos.sh`'s sign-off root**~~ — done 2026-09-02, before Phase 11B
  first succeeded.
- **The post-image capstone** lands indexed from its first run only if Phase 14
  has not run — which it has not. Same free window that justified Revisions 121
  and 127.
