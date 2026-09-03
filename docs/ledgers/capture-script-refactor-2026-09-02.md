# Capture-script refactor — status report

**Run:** 2026-09-02, unattended, session `01KcZvrKMgfenhrT9DvxW9Jk`.
**Scope:** every producer behind Table 3 of
[[evidence-conformance|docs/ledgers/evidence-conformance.md]] — *Needs refactor
to the current structure*. Scripts only. **No artifact or evidence on the volume
was touched or migrated.**

Nine scripts changed, all uncommitted. Manifest **Revision 135**.

---

## Status at a glance

| # | Script | Category | Status |
|---|---|---|---|
| 1 | `bin/run-time-machine.sh` | `time-machine/` | **complete** |
| 2 | `bin/record-time-machine-evidence.sh` | `time-machine/` | **complete** |
| 3 | `bin/capture-toolkit-snapshot.sh` | `toolkit-snapshot/` | **complete** |
| 4 | `bin/capture-performance-audit.sh` | `performance-audit/` | **complete** |
| 5 | `bin/capture-office-stability.sh` | `office-stability/` | **complete** |
| 6 | `bin/office-stability-checklist.sh` | `office-stability/` | **complete** |
| 7 | `bin/report-loose-secrets.sh` | `loose-secrets-reports/` | **complete — needs a one-time manifest rename before it will run** |
| 8 | `bin/report-size-audit.sh` | `size-audit-reports/` | **complete — needs a one-time manifest rename before it will run** |
| 9 | `bin/reimage-checklist.sh` | `reimage-prep-checks/`, `reimaged-system/checklists/` | **complete** — also updated as a *reader* |

Nothing was left half-done. Four things need your input; they are in
[[#Needs your input|Needs your input]] and none of them blocks a commit.

---

## What each one now does

### 1–2. Time Machine — `run-time-machine.sh`, `record-time-machine-evidence.sh`

Built to [[../architecture/time-machine-run-index|architecture/time-machine-run-index.md]].

- `artifact_path()` is gone. It returned a path from inside a command
  substitution, and `artifact_run_begin` sets shell variables a subshell
  discards. Replaced by `begin_artifact <kind> <ext>`, called outside
  substitution, setting `ARTIFACT_OUT`. Six call sites, each a one-line change.
- **One EXIT trap at the dispatch** finalizes or aborts. The `case` is the last
  statement in the file and exactly one command runs per invocation, so no
  command's early-return paths were touched.
- **Exit status 3 finalizes.** `verify-latest` returns 3 on checksum mismatch,
  and a run that reported findings is a completed run — aborting would discard
  the only record of the mismatch. The trap tests for `0` or `3` explicitly.
- `--context pre-image|post-image` added to both scripts, defaulting to
  `pre-image`. Twelve lineages, six per phase.
- **Option D's grouping is implemented**: `tm_backup_note()` puts the
  `tmutil latestbackup` stamp in the manifest `Note`, best-effort, never in the
  run id. The comment at that function states why C was rejected.
- The four `-maxdepth 1` glob read-backs in `final` are replaced by
  `artifact_run_file <context> <leaf>`, which resolves the official run of a
  named lineage. **This is the fix for the Phase 16 collision** — a glob could
  not express which phase it wanted; a lineage carries it.
- `final-time-machine-checklist-*.md` is now `evidence-summary.md` in a
  `<phase>-evidence-summary` run, with the answered rows in
  `time-machine/sign-offs/<phase>-evidence-summary-<stamp>.md`.

### 3. `capture-toolkit-snapshot.sh`

Four lineages: `<phase>-toolkit-snapshot` and `<phase>-toolkit-config`. A
`--config-only` refresh no longer displaces the full snapshot, which the single
shared pointer could not express.

**The symlinks were not removed wholesale.** `latest-*.txt` and
`latest-<context>-toolkit-*` are gone — stored pointers beside a computed one can
only disagree. **`latest-docs` stays**, retargeted through the official run: it
is a stable filesystem path for readers that have nothing to resolve a pointer
with, which is the situation every phase from 8 onward is in. It is cited by
`reimaging-guide.md`, two references, and `reimage-checklist.sh`.

### 4. `capture-performance-audit.sh`

One lineage per phase **and scenario** — `pre-image-performance-audit-clean-boot`
and its siblings. `artifact-runs.sh` names this category as one where the
pre/post prefix is the only discriminator; the scenario matters as much, because
clean-boot and active-dev answer different questions and one pointer across them
would name whichever ran last.

`--output` runs stay unindexed, guarded by a new `OUTPUT_ROOT_EXPLICIT` flag —
the old code could not tell "user passed `--output`" from "default filled in
later", because both left the variable non-empty.

### 5. `capture-office-stability.sh`

This one stages locally under the watch directory and is **promoted** to the
artifact root, so the run is staged at copy time rather than capture time. The
zip and the rendered summary now go **inside** the run with the evidence they
describe, instead of beside it at the category root where every previous run left
its own pair and nothing said which summary went with which bundle.

### 6. `office-stability-checklist.sh`

Two changes, and the second is the one that mattered.

- Writes to `office-stability/` rather than `office-stability/checklists/`.
  What it produces is an evidence bundle with a rendered report on top; those are
  runs. `checklists/` is now reserved for the two capstones.
- **Its manual rows became sign-off rows.** They were `record_check WARN "…"
  "Manual: …"` inside the automated table — answered rows wearing an automated
  verdict, returning as WARN on every run however many times they had been
  answered. It is the last checklist producer to adopt `sign-offs.sh`.

### 7–8. `report-loose-secrets.sh`, `report-size-audit.sh`

These are the two categories `artifact-runs.sh` was **extracted from**, so each
carried its own copy of the pattern — staging directory, manifest, `latest-run.txt`,
promote-on-finalize. Those copies are gone; the library owns them.

Each keeps the columns the shared schema has no room for, in a domain index
beside the run index — the Revision 120 treatment `repo-audit-reports/` got:

| Category | Domain index | Carries |
|---|---|---|
| `loose-secrets-reports/` | `loose-secrets-index.md` | outside / inside counts |
| `size-audit-reports/` | `size-audit-index.md` | external, skipped, OneDrive byte totals |

### 9. `reimage-checklist.sh`

Run-indexed per **D6**, both halves: context `pre-image` under
`reimage-prep-checks/`, `post-image` under `reimaged-system/checklists/`. Latest-
wins is right by construction — a capstone is regenerated until it is green and
the newest is the record — so `official/<phase>.txt` replaces
`latest-reimage-checklist.txt`.

Also updated **as a reader**: its toolkit-snapshot row resolved a `latest-*`
symlink, which named whichever run wrote last. It now resolves
`official/pre-image-toolkit-snapshot`, so a `--config-only` refresh cannot answer
a row that is about the full snapshot.

**Post-image has never run, so the Phase 14 capstone lands indexed from its first
run.** That was the free window; it is now taken.

---

## Verification

| Check | Result |
|---|---|
| `bash -n` | clean on all 43 `bin/*.sh` |
| `verify-script-portability.sh` | 74 clean / 2 suppressed / **0 WARN / 0 FAIL** against the Bash 3.2 + BSD floor |
| `verify-doc-paths.sh --all` | **0 MISSING / 0 ANCHOR BROKEN** |
| `verify-runbook-structure.sh` | 29 FAIL / 5 WARN across 27 documents — **unchanged**; no runbook was edited |
| Point-rule check | all 16 new contexts resolve to `unknown` → latest-wins, which is correct for every one of them. No context accidentally ends in a reserved point word (`before`, `exit`, `delta`, …) |
| Library bracket, end to end | exercised against a scratch category: three lineages staged and finalized, a second run of one lineage advanced **only** its own pointer, `toolkit-config` did not displace `toolkit-snapshot`, an aborted run left no `.incomplete`, and the `Note` column carried the backup stamp |

**All of it ran on Linux with Bash 5.x.** `shellcheck` was not available. The
scripts themselves could not be executed — they need `tmutil`, `diskutil`,
`log`, `sw_vers` and a mounted artifact volume — so what was verified is syntax,
portability, the point rules, and the library contract they all now depend on.
**`/bin/bash -n` on the target Mac is owed, along with Revisions 116–134.**

---

## Needs your input

### 1. Two categories will refuse to run until their manifest is renamed

`loose-secrets-reports/MANIFEST.md` is headed `# Loose Secret Checks` and
`size-audit-reports/MANIFEST.md` is headed `# Size Audit Runs`.
`_artifact_runs_ensure_manifest` will refuse to append to either, so both scripts
now exit 2 with an explicit message naming the fix. **This is expected** — it is
the Revision 120 migration, and you asked me not to touch the evidence.

When you want it done, per category:

```bash
mv "$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports/MANIFEST.md" \
   "$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports/loose-secrets-index.md"
./bin/reindex-artifact-runs.sh --category "$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports" --dry-run
./bin/reindex-artifact-runs.sh --category "$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports"
```

and the same for `size-audit-reports/` → `size-audit-index.md`. 15 and 9 existing
runs respectively. `latest-run.txt` is left in both; nothing writes it any more.

### 2. Runbooks are now behind their scripts

I did not touch them — you scoped this to capture scripts, and editing a runbook
requires reading `.github/ai-prompts/runbook-prompts/runbook-prompt.md` first,
which is a gate I did not want to cross unattended. What is stale:

| Runbook | What changed under it |
|---|---|
| `run-time-machine.md` | the flat layout diagram (~lines 177–191); `--context`; `final` is now `evidence-summary` |
| `capture-toolkit-snapshot.md` | `latest-*.txt` and two symlinks retired |
| `capture-performance-audit.md` | run naming |
| `capture-office-stability.md` | bundle location; zip and summary now inside the run |
| `reimage-prep-checks.md` | checklist path; `latest-reimage-checklist.txt` retired |
| `references/master-directory-reference.md`, `backup-file-reference.md`, `reimaged-system-evidence.md`, `reimaging-guide.md` | layout trees for all six categories |

`verify-doc-paths.sh` passes because these are prose diagrams, not paths it
resolves — which is exactly the drift that lint cannot see.

### 3. One naming call I made without you

`office-stability-checklist.sh` writes contexts
`<phase>-office-stability-checks`, while `capture-office-stability.sh` writes
`<phase>-office-stability`. Two producers, one category, two lineages — which is
correct, since they capture different things. But the names are close enough to
misread. If you would rather have `-evidence` and `-checks`, or a clearer pair,
say so; it is a one-line change in each while nothing has run.

### 4. `capture-workload-snapshot.sh` was left alone

It is not in Table 3 and does not resolve `REIMAGE_ARTIFACT_ROOT` at all, so it
appears to write only locally. Worth a look before Phase 13, but I did not want
to widen the task on an assumption.

---

## What was deliberately not done

- **No artifact or evidence was migrated.** `time-machine/` still holds its seven
  flat files; no category gained `runs/`, `MANIFEST.md` or `official/` on the
  volume. The scripts will create those on their next run.
- **No runbook was edited** — see input item 2.
- **The Time Machine migration (option i)** — backup, rehearse, migrate, split
  the mixed checklist — is the build step that follows this one and is written
  out in §9 of the design record.
- **`restore-*` and `record-restore-*` scripts** were already converted and were
  not touched.
