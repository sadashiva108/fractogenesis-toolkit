# Session prompt — run-index design and evidence conformance

Working in **fractogenesis-toolkit**. Continuing from Revisions 116–128.

## Reading order

1. **`.github/copilot-instructions.md`** — the instruction set, before anything
   else and every time. Sections 4b–4d define `docs/`, the findings bundles and
   the sessions; `docs/legend.md` carries the statuses and states they use.
2. The handoffs and design record named below.

Read
`docs/sessions/run-index-design-20260901-000000/handoff-20260901-222913.md` and
`docs/sessions/restore-git-phase-11a-20260901-155433/transcript-20260901-155433.txt` first — two concurrent sessions, one
per file. Then `docs/architecture/time-machine-run-index.md`, which is the
design record item 1 continues from.

**Every item ends in a written plan I approve — not in a conversion.** Item 1
additionally ends in a handoff: once its plan is settled I will open a session
dedicated to executing it against `restore-repos.md`. Do not convert or refactor
anything until I say so.

---

## Ground rules

- **Never commit. I commit.**
- Every change gets a new `APPLY-MANIFEST.md` revision. Check the header for the
  current number before claiming the next — a concurrent session collided on
  Revision 123 once already.
- Validate with `./bin/verify-doc-paths.sh --all`,
  `./bin/verify-runbook-structure.sh`, `./bin/verify-script-portability.sh`.
- **Baselines to compare against, not to zero:** doc-paths 745 OK / 0 MISSING /
  0 ANCHOR BROKEN; runbook-structure **29 FAIL / 5 WARN** across 27 documents
  (every remaining failure is `NO-NOTE` or `LEGEND`); portability 0 FAIL.
- Runbook conventions: `.github/ai-prompts/runbook-prompts/runbook-prompt.md`.
  Script rules: `.github/ai-prompts/script-prompts/bash-script-authoring-and-review.md`.
  Placement: `.github/guides/script-types-and-locations.md`.
- Artifact naming, timestamping, retention and pointer policy are runbook-level
  decisions — present options with tradeoffs before changing any of them.
- Park anything found mid-task in `docs/*-findings/` rather than widening the work.
  See `.github/copilot-instructions.md` §4b.
- Target is macOS stock Bash 3.2 + BSD userland. Everything so far ran on Linux
  with Bash 5.x; `/bin/bash -n` on the real Mac is still owed for Revisions
  116–128.

## Connected folders

- repo: `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit`
- artifact root: `/Volumes/Data/reimage-CVG-0002160-500-20260816-open`

---

## Verified state — do not re-derive

**On the shared run index** (`MANIFEST.md` + `official/` pointers):
`reimaged-system/boundaries` (13 pointers / 32 runs), `comparisons` (8/23),
`state` (8/21), `restarts` (6/15), `repo-audit-reports` (2/4),
`managed-inventory` (1/1), `system-inventory` (1/1).

**Looks converted, is not:** `loose-secrets-reports` (15 runs) and
`size-audit-reports` (9 runs) each have `MANIFEST.md`, `runs/` and
`latest-run.txt` but **no `official/`**. They are the two implementations
`artifact-runs.sh` was extracted *from*. Their manifests are headed `# Loose
Secret Checks` and `# Size Audit Runs`, so `_artifact_runs_ensure_manifest` will
**refuse** to append — they need the Revision 120 treatment (rename the domain
manifest, then `reindex-artifact-runs.sh` builds the standard one beside it).

**Not run categories:** `app-settings-backup`, `home-files-backup` — their
`MANIFEST.md` files are backup manifests, a different kind.

**Flat and unconverted:** `time-machine` (7 loose files), `toolkit-snapshot`,
`office-stability`, `performance-audit`, `gitignore-superset`, `public-certs`,
`reimage-confirmation`, `reimage-prep-checks`, `secrets-encrypted`,
`staged-ignored-files`.

**Phase 13 has not run.** Post-image capture directories on disk:
toolkit-snapshot 0, system-inventory 0, managed-inventory 0, performance-audit 0,
office-stability 1. Pre-image: 1, 1, 1, 3, 16 respectively. **The window to
convert producers before post-image evidence exists is still open**, and that is
the cheapest moment — it is the argument that justified Revisions 121 and 127.

---

---

## Order of work

Strict. Do not start one before the previous is settled.

| # | Item | Ends in |
|---|---|---|
| 1 | **Restore Repositories** — Phase 11B captures and scripts | a plan, a handoff note, gaps → `docs/*-findings/` |
| 2 | **Prior-phase evidence gap check** — everything before Phase 11B | `docs/*-findings/` |
| 3 | **Time Machine Evidence Conversion** | `docs/architecture/` |
| 4 | **Run-Index Coverage Audit** | `docs/architecture/` |
| 5 | **Post-Image Evidence Inventory** | `docs/architecture/` |
| 6 | **Post-Image Recapture Strategy** | `docs/*-findings/` |
| 7 | **Pre-Image Structural Conformance** | `docs/*-findings/` — **lowest priority, do last** |

Items 3–5 describe work to build, so they are features. Items 6 and 7 are
must-dos I am deferring rather than new capability, which is what `docs/*-findings/` is
for. Item 1's handoff note is the exception: it goes to `docs/sessions/`, because
it is what starts the next session.

Items 3–7 are the five features previously numbered 1–5; only the numbering moved.
Items 5 and 6 bear on the post-image half I have already worked through
thoroughly, which is why they sit below 3 and 4 despite being closer to my
day-to-day concern.

---

## 1. Restore Repositories — plan, then hand off

**Why first: it is what unblocks me, and it gates a second session.** I will not
open the session that executes this plan until the plan is settled and handed
off. Meanwhile I am working through `restore-repos.md` myself — so this item is
analysis and design, with my input as I break away to review it.

### What is contended, and for how long

`restore-repos.md` — because I am working through it right now. That is a
**timing** constraint, not a permanent ownership split: I expect to be done with
it by the time this item moves from analysing to writing.

So:

- **Read it freely.** Analysis and design need it, and reading collides with
  nothing.
- **Do not edit it while I am still in it.** Every change it needs goes into the
  plan, not into the file.
- **Ask before the first edit** rather than assuming the restriction has lifted
  or that it still stands. One line in the summary — "ready to edit
  `restore-repos.md`?" — is enough.

Everything else in the phase is yours throughout: `bin/restore-repos.sh`,
`bin/backup-repos.sh`, the three `.internal/git/` helpers, and the
`repo-audit-reports/`, `gitignore-superset/` and `staged-ignored-files/`
structure. `backup-repos.md` is the pre-image sibling and is not contended.

`restore-apps.md`, `restore-intellij.md` and `restore-docker.md` are the fast
pass I am circling back to. Not contended now, but flag rather than edit if this
item reaches into them.

### Context

The **restore work itself is finished** for Phases 8 through 11A. Nothing below
asks me to redo a restore. What is uncertain is whether the *recorded evidence*
for those phases is still current, given the captures and scripts have changed
underneath it since.

I did a fast pass through Phase 11B and the `restore-apps.md` /
`restore-intellij.md` / `restore-docker.md` siblings to get a working dev
environment. I am circling back to finish what I skipped. **Unblock Phase 11B
first**; the other phases' refreshes can wait for a later pass, and the ledger
should say which those are rather than pulling them into this one.

I believe the captures are current for `enroll-and-stabilize`, probably
`verify-reimaged-system`, possibly `restore-runtime` and `restore-access`, and
most likely `restore-git` — but all warrant a check, especially against changes
made since they last ran.

### The distinction the ledger turns on

**Re-running a recorder is not re-running a restore.** `record-restore-state.sh`,
`record-restore-exit.sh`, `record-restore-prereqs.sh`, `record-enrollment.sh`,
`record-reimaged-system.sh` and `compare-restored-state.sh` observe and write
evidence; they do not touch restored state. That is what makes a refresh cheap.

What makes it *unsafe* is the point rule, not the machine:

- **Latest-wins lineages** (`entry`, `exit`, `after`, `delta`, `diff`, `result`,
  `post-restart`, `initial`) — refreshing is safe and the pointer advances to the
  new run.
- **First-wins lineages** (`before`, `pre-restart`) — the library will index a
  late re-run but deliberately **not** advance the pointer, and will say so on
  stderr. It cannot corrupt the pointer, but it adds a run to the index that
  looks like a baseline and is not one. `artifact-runs.sh` states the reason: a
  `before` captured after the runbook has already written is well-formed and
  wrong.

Classify every recorder in the ledger on that axis, and say plainly which ones
must never be re-recorded at all.

### Starting facts, verified on disk

`repo-audit-reports/` **is** converted (Revision 120): 2 pointers, 4 runs, plus a
loose `repo-audit-index.md` — the renamed domain manifest, which is correct and
stays. `restore-repos.sh` resolves `artifact_run_official … pre-image` for input
and stages `post-image-restore` runs for output, so **re-running it is safe** and
cannot read its own output as input the way the old `latest-run.txt` allowed.

`gitignore-superset/` — not converted, 16 loose items.
`staged-ignored-files/` — not converted, 3 loose items, and `restore-repos.sh`
reads a **fixed** `staged-ignored-files/live` path rather than a timestamped one.
Determine whether that fixed path is a deliberate exception to the run pattern or
an unconverted remnant; those need opposite treatment.

**Evidence completeness across the finished restore phases**, from `official/`
pointers under `reimaged-system/`:

| Runbook | entry | exit | before | after | delta |
|---|---|---|---|---|---|
| `restore-access` | yes | yes | yes | yes | yes |
| `restore-git` | yes | yes | yes | yes | yes |
| `restore-repos` | yes | yes | yes | **no** | **no** |
| `restore-apps` | yes | **no** | yes | **no** | **no** |
| `restore-runtime` | yes | yes | **no** | **no** | **no** |

That answers my uncertainty for me: `restore-git` and `restore-access` are
complete. `restore-runtime` has its boundaries but **no state walk at all**.
`restore-apps` is the fast-pass phase — entered, never formally exited.
**`restore-repos` is bracketed but its state walk never closed**, which is the
one that matters for Phase 11B and should be treated as part of unblocking it.

Confirm this map before relying on it, and check whether a missing pair means the
step was skipped or the runbook never called for one.

### What I want out of it

A **plan**, not the work. Specifically:

1. **A refactor plan** for the Phase 11B captures and their scripts — what should
   change to bring them to current conventions, at the standard of Revisions 121
   and 127, with the reasoning for each change.
2. **Retrofitting analysis** for `gitignore-superset/` and
   `staged-ignored-files/`: what converting each would move, what reads them, and
   whether any Phase 6B or 11B sign-off cites a path that would change. Include
   the `staged-ignored-files/live` question above.
3. **A re-run ledger for Phase 11B**, as a table I can act on directly. One row
   per capture, recorder and script in scope. Columns: has it run; has anything
   changed underneath it since; is a re-run safe, noisy, or forbidden by its
   point rule; does re-running advance a pointer; and the order to run them in.
   The missing `restore-repos` `after` and `delta` belong here.

Then **stop and hand off.** Say plainly what the executing session needs to know
that is not already in the plan, and what it must not touch.

---

## 2. Prior-phase evidence gap check

Everything **before** Phase 11B — `enroll-and-stabilize`,
`verify-reimaged-system`, `restore-runtime`, `restore-access`, `restore-git`, and
the `restore-apps` fast pass. The restores are done; this is a double-check of
the **evidence**, and secondarily of anything I skipped.

Work from the completeness map above and confirm it. For each phase:

- Which lineages exist, which are missing, and whether a missing one means a
  skipped step or a runbook that never called for it. `restore-runtime` having no
  `before` at all looks like the latter — check.
- Whether the recorded evidence predates changes made to its producer since, and
  therefore whether a refresh would say something different.
- Whether a refresh is safe, noisy or forbidden by the point rule.
- Anything else I missed in the fast pass — `restore-apps` has an `entry` and no
  `exit`, which is the obvious one; look for the less obvious.

**Write each gap up under `docs/*-findings/`**, one file per gap, named for the thing
rather than the date. Where rework is needed, the write-up carries the plan. Do
not do the rework.

This is a deliberate second pass, not a blocker for item 1 — if it turns up
something that changes the Phase 11B plan, say so and I will decide.

## 3. Time Machine Evidence Conversion

*Handle: `time-machine-run-index`.*

Decide the design and produce a plan. The record in `docs/architecture/` has the four
options; **the choice between C and D is reopened** and I have not settled on D.

**A correction that matters, found after that record was written.** Its statement
of Option C's weakness is partly wrong. It says `start` and `monitor` run before
a backup exists — true, but **irrelevant**: both write no artifact and never call
`artifact_path`, so neither produces a run to name. Only six subcommands write.

So C's real and only hazard is narrower: a `logs` or `diagnose` capture taken
during or after a **failed** backup, where `tmutil latestbackup` returns the
*previous successful* backup. That does not produce an empty id — it produces a
**wrong** one, silently filing a failure diagnosis under a backup that succeeded.
Weigh whether that is containable (the script already has
`backup_stamp_from_value` and a "did not return a parseable backup timestamp"
path in `complete`) or whether it is the same class of quiet misattribution that
disqualified B.

Settle also:

- **Context naming.** Phase 16 runs the same subcommands into the same namespace
  as Phase 5, so contexts need a phase discriminator (`pre-image-status`,
  `post-image-status`, …) — the exception `artifact-runs.sh` names for categories
  holding both phases. This implies a `--context` option `run-time-machine.sh`
  does not have. Confirm or overturn.
- **Migration.** No path avoids moving signed-off Phase 5 evidence, because the
  artifacts are flat *files* — the escape that made Revision 120 safe (run
  directories never moved) does not exist here. Three options are written up;
  option (iii), convert the code and migrate nothing, has never been put to me.
  Put it to me.
- **Scope.** Two producers, nine artifact kinds, four `-maxdepth 1` read-backs in
  `record-time-machine-evidence.sh` (line 441, used 508/511/517, plus 523). One
  atomic edit. Leave `time-machine/sign-offs/` out — Revision 116 made sign-offs
  deliberately un-indexed.
- **Implementation gotchas** are in the record: the command-substitution subshell
  problem, the single EXIT trap at the dispatch, and exit status 3 finalizing
  rather than aborting.

## 4. Run-Index Coverage Audit

*Handle: `run-index-coverage-audit`.*

Every remaining category, surveyed and classified, with a design and plan for
each candidate — not a conversion.

For each: is it a run category at all, or something else wearing a `MANIFEST.md`?
Does it hold one lineage or several? Are there readers that glob, and what breaks
if it relayouts? Is the evidence signed off and therefore expensive to move?

Cover at minimum `loose-secrets-reports`, `size-audit-reports`, `toolkit-snapshot`,
`office-stability`, `performance-audit`, and state plainly which of the remaining
flat directories are **not** worth converting and why. `artifact-runs.sh` already
names `performance-audit/` as a category where the pre/post prefix is the only
discriminator — start there.

Rank the candidates by *cost of waiting*, not by effort. A category that Phase 13
is about to write into is urgent; one that is finished forever is not.

## 5. Post-Image Evidence Inventory

Produce the definitive list of post-image evidence: what exists, what will exist,
what is already converted, and what will land unindexed if nothing changes before
Phase 13.

Given Phase 13 has not run, expect the answer to be mostly *producers*, not
artifacts. Say so plainly rather than presenting an empty table — the finding is
that the conversion window is open, and which producers are inside it.

Include Phase 16 (post-image Time Machine) and Phase 14/15 outputs under
`reimaged-system/`, which is already converted and should be confirmed rather
than assumed.

## 6. Post-Image Recapture Strategy

A comprehensive plan for re-running post-image captures so the evidence is as
current as possible, in one deliberate pass rather than piecemeal.

Address: which captures are safe to re-run and which are one-shot; ordering and
dependencies (several read each other); which need the artifact volume mounted;
what a re-run costs in time; how re-running interacts with first-wins pointers
and pins; and which rows in the Phase 14 checklist close as a result.

Where a capture would land unindexed today, say whether to convert first or
capture first, and why.

## 7. Pre-Image Structural Conformance

Repeat 5 and 6 for pre-image evidence, with one hard constraint: **the captured
data is not to be modified.** Pre-image evidence is the record of a machine that
no longer exists. Structural changes only — relayout, indexing, pointers — so it
conforms to the current structure and compares cleanly against post-image runs.

State explicitly, per category, what would move and what would not, and whether
any Phase 6B sign-off cites a path that would change. Where a category cannot be
made conformant without rewriting content, say so and leave it.

---

## Deliverables

- **Item 1:** the plan and handoff note under `docs/sessions/`; anything it turns
  up and does not fix under `docs/*-findings/`.
- **Item 2:** one file per gap under `docs/*-findings/`, each carrying its own plan
  where rework is needed.
- **Items 3–5:** one design record each under `docs/architecture/`, in the shape of
  `time-machine-run-index.md` — options, rejected alternatives with
  reasons, the decision, scope, and a plan.
- **Items 6–7:** the same shape, under `docs/*-findings/` — deferred must-dos rather
  than new capability.
- Anything else found and not fixed goes to `docs/*-findings/` too.
- A manifest revision only for changes actually made to the repository. If this
  session writes only design records, it may end with no revision at all —
  `docs/` is gitignored, and that is correct.
- A short summary of what needs my decision, separated from what does not.
