# Script conformance pass — status report

**Run:** 2026-09-02, unattended, session `01KcZvrKMgfenhrT9DvxW9Jk`.
**Scope:** five items, then two follow-ups you approved. Scripts only.
**No runbook and no artifact was touched.**
Manifest **Revisions 136 and 137**; eleven files, uncommitted.

| # | Item | Status |
|---|---|---|
| 1 | Rename `office-stability-checklist.sh` | **complete** — `assess-office-stability.sh`, per your call |
| 2 | Recorder usage strings + missing boundaries | **complete** |
| 3 | Orphaned comparison lineage | **complete** — needed a library change, not a no-op |
| 4 | Caller-environment precedence | **complete** |
| 5 | Retire the last `toolkit-snapshot` symlink | **complete** |
| 6 | `restore-home` boundaries | **complete** |

---

## 1. Naming — done, Revision 137

`bin/office-stability-checklist.sh` → **`bin/assess-office-stability.sh`**
(`git mv`, so history follows). Contexts:

| | Before | After |
|---|---|---|
| assessor | `<phase>-office-stability-checks` | `<phase>-office-stability-assessment` |
| capture | `<phase>-office-stability` | `<phase>-office-stability-evidence` |

The report inside a run is now `office-stability-assessment.md` — the run id
already carries the phase, so the filename no longer repeats it. `RUN_SLUG` is
gone; it was left over from before the run-index conversion. Script-side
references updated in `reimage-checklist.sh`, `capture-workload-snapshot.sh` and
`capture-office-stability.sh`.

**Nothing had run under either context, so this cost a rename and no migration.**

The proposals that led here are kept below for the reasoning.

### Original proposals

### What the thing actually is

It reads a marker-bounded evidence window and reports on it: watcher output,
Office process transitions, install and AutoUpdate log tails, crash reports after
the marker. It produces a bundle plus a rendered verdict. It is **not** a
checklist under the definition now in force — that word is reserved for the two
capstones — and it is not a sign-off either.

Its sibling `capture-office-stability.sh` gathers the same window's raw evidence.
This one **evaluates** it. That is the distinction a name should carry, and it is
why "capture" is wrong for both if only one of them can have it.

### Script name

| Proposal | Reads as | Against |
|---|---|---|
| **`report-office-stability.sh`** | matches the repo's own taxonomy: `report-` leaves a durable `*-reports/` directory the workflow reads back, which is exactly what this does | the category is `office-stability/`, not `office-stability-reports/` — the convention's wording would need a word |
| `verify-office-stability.sh` | verb-first, and it does render PASS/WARN/FAIL | `verify-` in `bin/` currently means a repo lint (`verify-doc-paths`, `verify-script-portability`), not an evidence check |
| `assess-office-stability.sh` | accurate — it judges a window rather than passing or failing a build | a new verb for one script |
| `capture-office-stability-report.sh` | keeps both scripts in the same family | long, and two `capture-` scripts in one category is the ambiguity being fixed |

**Recommended `report-office-stability.sh`; you chose `assess-`**, which is the
better call: `report-` is defined as leaving a durable `*-reports/` directory,
and this category is not one. `assess-` says what the script does rather than
what shape its output takes, and the pairing with `capture-` is legible without
a convention to look up.

### Phase name

Currently **Phase 4D — Office Stability Capture** (pre) and **13E** (post), which
name the *capture*, not this script. Both scripts sit in the same phase, so the
phase name should cover the pair:

| Proposal | Note |
|---|---|
| **Office Stability Evidence** | covers gathering and evaluating without naming either; parallels "Post-Image Captures" in tone |
| Office Stability Window | accurate — everything here is bounded by the watcher marker — but assumes the reader knows what the window is |
| Office Stability Assessment | leans on the verdict, which is only half the phase |

**Recommended Office Stability Evidence.** Superseded: with the contexts now
`-evidence` and `-assessment`, a phase named *Evidence* would name half its own
contents. The phase name is a runbook change and stays open — **Office Stability
Assessment** now reads better, since assessment is what the phase delivers and
the evidence is how.

### Run contexts — done, above.

---

## 2. Recorders and phase boundaries — complete

**Usage strings.** `record-restore-prereqs.sh` (dispatched on 5, advertised 2)
and `compare-restored-state.sh` (dispatched on 3, advertised 2 in three places)
now derive every message from one `SUPPORTED_RUNBOOKS` string — the shape
`record-restore-state.sh` already used, and the reason it never drifted.

**Missing boundaries.** Only one post-image runbook in this family lacked one:

| Runbook | Before | Now |
|---|---|---|
| `restore-runtime`, `restore-access`, `restore-git`, `restore-repos` | entry + exit | unchanged |
| `restore-apps` | entry only | **entry + exit** |
| `enroll-and-stabilize`, `verify-reimaged-system` | own recorders, entry + exit | unchanged — not this family |

`check_restore_apps()` added to `record-restore-exit.sh`, plus its `case` entry
and usage. Four automated rows (applications on disk; the core five; the
IntelliJ and Docker plan notes that record those handoffs; secrets DMG
detached) and three manual rows. Modelled on `check_restore_repos()` because
Phase 12 has the same no-fixed-finish-line property.

**Chain closed at the front too.** `check_restore_access()` now gates on
`restore-runtime-exit`. That link was missing while 11A, 11B and 12 all checked
their predecessor.

**Answered, and done in Revision 137 — see item 6.** `restore-home` has a
boundary; `restore-intellij` and `restore-docker` deliberately do not, being
expanded sections of `restore-apps.md` rather than phases.

---

## 3. Orphaned comparison lineage — complete, and it was not a no-op

The gap offered "clear the pointer" or "document it". **Neither works**, and
finding out why is the substance of this item.

`artifact_run_clear_official` clears a **pin**, not a lineage. And officialness
is *computed* from the manifest, so deleting `official/<context>.txt` by hand
lasts until the next `artifact_runs_rebuild` — which is the documented repair
command — puts it straight back. There was no way to retire a lineage at all.

Added to `.internal/artifact-runs.sh`:

- `artifact_run_retire_lineage <root> <context> <reason>` — appends a `retire`
  row, removes the pointer. Runs stay indexed.
- `artifact_run_reopen_lineage <root> <context> <reason>` — the inverse.
- `artifact_runs_rebuild` honours the last `retire` row, so a rebuild leaves a
  retired lineage retired.

Same idiom as pins: a manifest row, a required reason, last row wins.

**Verified** against a scratch category: retire removed the pointer, rebuild left
it removed, the two runs stayed, reopen restored it, a second retire was refused.

> **Artifact follow-up (not done).** Retiring the actual lineage is a one-time
> command against the volume:
> ```bash
> source .internal/artifact-runs.sh
> artifact_run_retire_lineage \
>   "$REIMAGE_ARTIFACT_ROOT/reimaged-system/comparisons" \
>   "restore-runtime-version-comparison" \
>   "one-off migrated from restore-notes/; superseded by restore-runtime-inventory-diff"
> ```

---

## 4. Caller-environment precedence — complete

Caller values for every key `reimage.env` sets are now captured before sourcing
and re-applied after, **by set-ness rather than non-emptiness** — so
`GIT_PERSONAL_GITHUB_OWNER= ./bin/restore-repos.sh` means what it says. That was
the exact case the Phase 11B session had to work around.

The thirteen keys `artifact-config.sh` resolves and defaults by name keep their
existing `:-` semantics, so an accidentally-blank export cannot erase a default
the whole workflow depends on. The header now documents that exception instead of
claiming an unqualified rule.

Bash 3.2: newline-delimited `NAME=VALUE` list, no associative arrays. A caller
value containing a newline is skipped rather than truncated.

**Verified** against a fixture `reimage.env`, five cases:

| Case | Result |
|---|---|
| no override | `reimage.env` value |
| `GIT_PERSONAL_GITHUB_OWNER=caller` | caller wins |
| `GIT_PERSONAL_GITHUB_OWNER=` (empty) | **caller wins** — the gap's case |
| `GIT_WORK_GITHUB_HOST=caller-host` | caller wins |
| `EXTERNAL_DATA_VOLUME=` (named key, empty) | default retained, unchanged |

> **Note.** This changes configuration precedence for every script in the
> repository. It is the one item here I would re-verify on the Mac before
> trusting it, because the fixture cannot reproduce a real `.envrc`.

---

## 5. Toolkit-snapshot symlinks — complete

`latest-docs` is gone; it was the last symlink any category published.
`refresh_latest_alias()` is deleted.

The affordance it provided survives and still needs no tooling:
`official/<context>-toolkit-snapshot.txt` is a one-line text file holding
`runs/<id>`, so `cat` names the run and `<that>/docs` is the docs directory.
Each run now carries `logs/run-location.txt` (was `logs/latest-aliases.txt`)
spelling that out.

`reimage-checklist.sh` resolves the pointer for both toolkit rows. The old rows
followed `latest-*` symlinks, which named whichever run wrote last — and a
`--config-only` refresh is its own lineage, so it could answer a row that is
about the full snapshot.

---

## Runbook and reference follow-ups

None of these were touched. Added to what Revision 135 already owed.

| Document | Owed |
|---|---|
| `capture-office-stability.md` | Phase 4A/13E name if item 1 is taken; both scripts' run layout |
| `restore-apps.md` | a final step calling `record-restore-exit.sh --runbook restore-apps`; the `after`/`delta` steps still missing |
| `restore-access.md` | Step 0 now also reports whether Phase 10A closed out |
| `restore-git.md` | Step 8's `compare-restored-state.sh` call is now advertised as supported |
| `capture-toolkit-snapshot.md` | `latest-docs` retired; how to find the docs directory now |
| `reimage-prep-checks.md` | the two toolkit rows changed name and meaning |
| `references/master-directory-reference.md` | no category publishes symlinks; `retire` rows exist |
| `references/backup-file-reference.md`, `reimaged-system-evidence.md`, `reimaging-guide.md` | `latest-docs` appears in four layout trees |
| `.github/ai-prompts/script-prompts/bash-script-authoring-and-review.md` | states the precedence rule as architecture to preserve; it is now true for all keys, with one documented exception |

## Artifact follow-ups

| Artifact | Owed |
|---|---|
| `comparisons/official/restore-runtime-version-comparison.txt` | the retire command in item 3 |
| `toolkit-snapshot/latest-docs`, `latest-pre-image-toolkit-snapshot`, `latest-*.txt` | stale symlinks and pointer files on the volume; nothing writes them now |
| `loose-secrets-reports/`, `size-audit-reports/` | the manifest renames from the Revision 135 report, still owed |

## Verification

`bash -n` clean on all 43 `bin/*.sh` and every `.internal/` shell file.
`verify-script-portability.sh` 74 clean / 0 WARN / 0 FAIL.
`verify-doc-paths.sh --all` 0 MISSING / 0 ANCHOR BROKEN.
`verify-runbook-structure.sh` 29 FAIL / 5 WARN across 27 documents, unchanged.

The two behavioural changes — the retire mechanism and the precedence fix — were
exercised against scratch fixtures rather than reasoned about, because both
change what every other script sees.

**All on Linux with Bash 5.x**; `shellcheck` unavailable; `/bin/bash -n` on the
target Mac owed here and on Revisions 116–135.

---

## 6. `restore-home` boundaries — complete (Revision 137)

Closes the chain Revision 136 opened at the front: **10A → 10B → 11A → 11B → 12
→ 15**, each phase checking its predecessor finished.

**Entry** — derived one for one from `restore-home.md` → Prerequisites:

| Row | Verdict on failure |
|---|---|
| Toolkit root resolves | FAIL |
| `restore-apps` closed out | **WARN** — Phase 12 has no fixed finish line and returning for more apps is expected; what it should not be is unnoticed |
| Phase 14 checks recorded (`official/post-image` under `reimaged-system/checklists/`) | FAIL |
| `restore-access` and `restore-git` closed out | FAIL — both own dotfiles Phase 15 must merge around, not onto |
| Home backup reachable (`home/` and `dotfiles/`) | FAIL — an rsync from a missing source copies nothing and exits 0 |
| Terminal can read `~/Documents` and `~/Desktop` | FAIL |

That last row is the one worth having. macOS denies access until Full Disk
Access is granted, and the runbook already documents the failure: `rsync` keeps
going, prints `Operation not permitted`, and exits 23 **with a partial tree**. A
read probe observes it without creating anything.

**Exit** — Phase 15 is doubly open-ended: no fixed finish line, and a deliberate
shortlist only the operator knows. So the automated rows check what is visible
from outside that decision — the restore note exists (the only record of what was
deliberately *skipped*), access was not denied at any point, and no OneDrive
conflict copies came back with the content. The four rows from Step 6's own
validation table are manual and live in the sign-off, where a rerun cannot reset
them.

`PHASE_NEXT` for `restore-home` is `run-time-machine.md` — Phase 16.

---

## Lint regression — one, deliberate

`verify-doc-paths.sh --all` now reports **1 MISSING**, where it has been 0 all
session: `reimaging-guide.md` cites `bin/office-stability-checklist.sh` by path.

The fix is one filename in that guide. It is left because runbooks and references
were out of scope, and it is recorded here **so the next session reads it as owed
work rather than as a new defect**.

Six further documents name the old script or its old bundle names in prose —
`references/reimaged-system-evidence.md`, `references/master-directory-reference.md`,
`references/reimage-prep-evidence.md`, `reimaging-scripts-guide.md`,
`restore-apps.md`, `capture-office-stability.md`.

## Added to the runbook follow-ups

| Document | Owed |
|---|---|
| `reimaging-guide.md` | the `bin/` path above (the MISSING row); Phase 4D / 13E name |
| `capture-office-stability.md` | the assessor is renamed; both contexts changed. This runbook covers both scripts and by convention `assess-office-stability.sh` may want a runbook of its own |
| `restore-home.md` | a Step 0 calling `record-restore-prereqs.sh --runbook restore-home`, and a final step calling `record-restore-exit.sh --runbook restore-home`. Step 6's validation table moves to the sign-off |
| the four references above | old script name and old bundle names in layout trees |

## The `restore-home` state walk — answered, not built

**What it would use.** `record-restore-state.sh` takes no context of its own: the
lineage is `<runbook>-<point>`, so Phase 15 would write
`restore-home-before`, `restore-home-after` and `restore-home-delta` into
`reimaged-system/state/`. Its inputs are a `targets_restore_home()` function
returning `mode@@spec@@note` lines, in the same shape as the other four.

**What the targets would be.** The paths Step 3 and Step 4 actually write, and
nothing else:

```text
shallow@@~/Documents/@@Step 3 — restored home subfolder, depth 1
shallow@@~/Desktop/@@Step 3 — restored home subfolder, depth 1
file@@~/.zshrc@@Step 4 — selective dotfile merge
file@@~/.zprofile@@Step 4 — selective merge; Phase 10A/10B wrote here first
file@@~/.bash_profile@@Step 4 — selective merge
file@@~/.bashrc@@Step 4 — selective merge
file@@~/.shell_common.sh@@Step 4 — selective merge
file@@~/.shell_local.sh@@Step 4 — selective merge
```

Depth 1 for the two content roots for the reason `restore-repos` uses it: the
question is *which folders came back*, not what is inside them, and a recursive
walk of a restored `Documents/` would hash tens of thousands of files to answer a
question that is one row per folder.

**What boundary it captures — and it is not the same one as the entry/exit pair.**
The boundary recorders answer *may this phase start* and *did it finish*. A state
walk answers a third question the boundaries cannot: **what did this phase
change.** `before` and `after` are two recordings of the same paths, and `delta`
joins them — so for Phase 15 the delta is literally the list of what was restored
and what was merged, which is the one thing the runbook asks the operator to
write down by hand in Step 6 and in the restore note.

That makes it the phase where a state walk is worth the most, not the least: the
shortlist is a human decision, and the delta is the only mechanical record of
what the decision came to.

**Two cautions if it is built.**

- `before` is **first-wins**. On a machine where Phase 15 has already run, a
  `before` taken now is well-formed and wrong. Phase 15 has not run on this
  machine, so the window is open — but it closes the moment Step 3 does.
- The dotfile rows overlap `targets_restore_access()`, which already walks
  `~/.zprofile`, `~/.zshrc` and the rest. That is not a conflict — they are
  separate lineages answering about separate phases — but a reader comparing the
  two deltas should know the same file appears in both.

**Not built.** You asked for boundaries, and this is a different mechanism. Say
the word and it is a `targets_restore_home()` function plus one entry in
`SUPPORTED_RUNBOOKS`.
