# Time Machine evidence — converting `time-machine/` to the shared run index

**Status:** design settled and approved. Not started.
**Supersedes and replaces:** `time-machine-run-index-conversion.md`, the
2026-09-01 record, now retired. Its option analysis, rejections, scope, migration
options and implementation notes are all carried below; the two paragraphs that
were only in it are in *History* at the end. `APPLY-MANIFEST.md` cites the old
filename in Revisions 128 and 133 — that is a change log quoting paths as they
were, which is the record working correctly, and is why it is excluded from
`verify-doc-paths.sh`.
**Written:** 2026-09-02, session `01KcZvrKMgfenhrT9DvxW9Jk`, item 3.

Two facts settled since the earlier record change its shape, and both narrow the
work rather than widen it:

- **The namespace is decided.** The root-level `time-machine/` holds post-image
  evidence alongside pre-image, the way every `capture-` category does
  (Revision 132). The empty `reimaged-system/time-machine/` that suggested
  otherwise is gone.
- **Closed pre-image artifacts may be moved**, with a backup first
  (`docs/architecture/sign-off-consolidation.md` D3). The migration question was
  written when they could not be, and that assumption drove its answer.

---

## Table of Contents

- [[#1. What is wrong today|1. What is wrong today]]
- [[#2. Options, and why three were rejected|2. Options]]
- [[#3. The C-versus-D question, reopened and answered|3. C versus D]]
- [[#4. Context naming|4. Context naming]]
- [[#5. Migration|5. Migration]]
- [[#6. Scope|6. Scope]]
- [[#7. Implementation notes|7. Implementation notes]]
- [[#8. Verification|8. Verification]]
- [[#9. Open decisions|9. Open decisions]]

---

## 1. What is wrong today

`time-machine/` holds seven flat timestamped files at the category root. No
`runs/`, no `MANIFEST.md`, no `official/`. Every reader globs and takes the
newest match.

The live defect is Phase 16. `reimaging-guide.md` runs *the same*
`bin/run-time-machine.sh` subcommands after Phase 15 that Phase 5 ran before the
erase, into the same flat namespace. After Phase 16 the category holds two
`status-<stamp>.txt`, two `completion-check-<stamp>.md`, two `compare-<stamp>.txt`,
distinguishable only by date — and `record-time-machine-evidence.sh` resolves its
inputs with `latest_matching_file`, which takes the newest.

**Regenerating the Phase 5 `final` checklist after Phase 16 would silently read
Phase 16's completion check and checksum verification.** That is not a missing
answer; it is a wrong one, filed under a run that did not produce it.

`artifact-runs.sh` names this exact failure in its own header:

> A category holds several independent lineages — pre-image and post-image […] —
> and a single "latest" pointer can only name whichever ran last.

The timing argument is the one that justified Revisions 121 and 127: convert
before Phase 16 and the post-image runs land already indexed; convert after and
both lineages need retrofitting, having produced a wrong answer in between.
**Phase 16 has not run. The window is open.**

## 2. Options, and why three were rejected

### A — one run per invocation, subcommand as the lineage

- **For:** no new machinery; exactly what the library already does. Flat files
  become run directories, which also gives each artifact somewhere to keep the
  raw output it currently inlines.
- **Against:** nothing links the ~12 invocations that make up one backup
  operation.

### B — explicit session anchor

`start` writes `time-machine/.session` holding an id; later subcommands read it
and write into `runs/<id>/`; `eject` finalizes.

- **For:** true grouping of an operation.
- **Against:** the library has no concept of a run spanning invocations. The
  failure modes are the bad kind: a session file left by an abandoned backup
  silently absorbs the next operation's artifacts, and a subcommand run before
  `start` or after a crash has no session to join. **A grouping mechanism that is
  sometimes wrong about which operation an artifact belongs to is worse than no
  grouping**, because a reader cannot tell the two cases apart. **Rejected.**

### C — anchor on Time Machine's own backup identity

Use the `tmutil latestbackup` stamp as the run id.

- **For:** the operation already has an identity and macOS assigns it. Two
  artifacts share an id exactly when they describe the same backup.
- **Against:** see §3. **Rejected, on a narrower ground than first stated.**

### D — A now, C's identity as a manifest note — **chosen**

Convert per-invocation as in A, and where `tmutil latestbackup` resolves, record
that stamp in the manifest row's `Note`.

- **For:** grouping stays *recoverable* — someone can reconstruct an operation by
  grouping rows on the note — without anything depending on it being complete,
  and without a second relayout. Every current reader asks "the newest artifact
  of kind X", which A answers exactly. No reader asks for "all artifacts of one
  backup operation", so grouping is a want, not a need.
- **Against:** the note is best-effort and empty for `start`-adjacent and
  failed-backup captures. That is honest rather than misleading, which is the
  distinction B failed.

## 3. The C-versus-D question, reopened and answered

The earlier record rejected C on the grounds that *"`start` and `monitor` run
before that backup exists"*. **That reason is wrong.** Both write no artifact and
never call `artifact_path`, so neither produces a run to name. Only six
subcommands write: `status`, `logs`, `completion-check`, `compare`,
`verifychecksums`, `diagnose` (call sites at lines 608, 618, 652, 802, 1063,
1134).

C's real hazard is narrower, and worse.

**A `logs` or `diagnose` capture taken during or after a failed backup does not
produce an empty id — it produces a wrong one.** `tmutil latestbackup` returns
the *previous successful* backup, so a diagnosis of a failure is filed under a
backup that succeeded. The artifacts most worth reading when something goes wrong
are the ones C misfiles.

**That is the same class of quiet misattribution that disqualified B**, and it
should disqualify C for the same reason. The mitigation available —
`backup_stamp_from_value` and the *"did not return a parseable backup
timestamp"* path already in `complete` (lines 656–669) — detects an *unparseable*
value, not a *stale* one. A previous successful backup's stamp parses perfectly.
There is no check that would catch it, which is precisely the property that makes
a failure mode unacceptable here rather than merely inconvenient.

**Decision: C stays rejected. D stands.** Under D the same stale stamp lands in a
`Note` column, where it is an annotation a reader can weigh rather than the
identity the artifact is filed under.

### Could the `final` roll-up rescue C? — no, and for two reasons

Asked 2026-09-02: the `final` checklist is the one artifact that names the
completion check, the volume verification, the checksum output and the pre-run
bundle in a single table. If that is the strongest grouping in the category,
could it serve as the identity C wanted?

**No, on timing.** Identity is assigned when a run is written; the roll-up is
produced afterwards, by a different script, and only names artifacts that already
exist. It cannot retroactively re-file a run that was created under a wrong id.
By the time the roll-up could speak, C has already misattributed.

**No, on coverage.** The roll-up names four of the nine kinds — completion-check,
diskutil verify-volume, verifychecksums, and the pre-run bundle. It does **not**
name `logs`, `diagnose`, `compare` or `status`. And `logs` and `diagnose` are
precisely the two whose misattribution disqualified C: a failed-backup capture
filed under the previous successful backup. The roll-up cannot fix C's failure
because it does not cover the artifacts C fails on.

What the question does establish is that the roll-up is a **stronger** grouping
than the `Note` column, and that is an argument for indexing it and letting it
cite the run ids it read — which is D plus a better note, not C. See §9.

## 4. Context naming

Settled, and Revision 132 confirmed rather than reopened it.

`artifact-runs.sh` states the rule and its own exception:

> DO NOT REPEAT THE DIRECTORY IN THE CONTEXT. […] This does NOT generalise to
> every category. `repo-audit-reports/` and `performance-audit/` hold pre-image
> AND post-image runs side by side, and there the prefix is the only thing
> telling them apart.

The root-level `time-machine/` is in that second class by decision. So:

```
pre-image-status             post-image-status
pre-image-logs               post-image-logs
pre-image-completion-check   post-image-completion-check
pre-image-compare            post-image-compare
pre-image-verifychecksums    post-image-verifychecksums
pre-image-diagnose           post-image-diagnose
```

Twelve lineages, six per phase. `_artifact_runs_point_of` resolves each to
`unknown` → latest-wins, which is correct: for each kind, the newest capture of
that phase is the one that describes it.

**This needs a `--context` option on `run-time-machine.sh`, which it does not
have.** Default `pre-image`, matching every other capture script in the toolkit.
That is new surface the original approval did not cover.

## 5. Migration

**The earlier record's framing no longer holds.** It weighed three options
against a constraint — signed-off Phase 5 evidence must not move — that the owner
has since relaxed: closed artifacts may be moved, with a backup taken first.

The three options, re-weighed:

| | Approach | Cost under the old constraint | Cost now |
|---|---|---|---|
| **(i)** | Migrate everything. Each `<prefix>-<stamp>.<ext>` becomes `runs/pre-image-<prefix>-<stamp>/<prefix>.<ext>` | Disqualifying — restructures signed-off evidence | **A backup and a script.** One shape, one set of readers, no permanent exception |
| **(ii)** | Leave the seven flat, index only new runs | Two shapes indefinitely, every reader needs both paths | Still the compatibility-shim outcome the conventions reject by default |
| **(iii)** | Convert the code, migrate nothing, let Phase 16 be the first indexed lineage | Looked strongest | Pre-image lineage has no pointer, so `final` still needs its globs for that side |

**Recommendation: (i).** Under the old constraint (iii) was the least-bad
compromise; with the constraint lifted it buys nothing that (i) does not, and
leaves the category half-converted by phase — a boundary that has to be explained
every time someone reads it.

(i) also composes with the sign-off work already planned: the Phase 5
`final-time-machine-checklist-20260817-082122.md` is one of the 35 mixed-mode
artifacts due to be split, and `time-machine/sign-offs/` is a directory the code
already names (line 473) and has never created. Doing the migration and the split
in one pass touches each file once.

**The backup is not optional and not incidental.** Seven files plus one bundle
directory, copied whole and off this volume, before anything moves. The manifest
entry names where it went.

### What migration (i) actually moves

```text
time-machine/
├── status-…            ->  runs/pre-image-status-<stamp>/status.txt
├── logs-…              ->  runs/pre-image-logs-<stamp>/logs.txt
├── completion-check-…  ->  runs/pre-image-completion-check-<stamp>/completion-check.md
├── compare-…           ->  runs/pre-image-compare-<stamp>/compare.txt
├── verifychecksums-…   ->  runs/pre-image-verifychecksums-<stamp>/verifychecksums.txt
├── diskutil-verifyvolume-applebackups-…   -> see below
├── final-time-machine-checklist-…         -> splits; see §9 Decision 2
└── pre-image-time-machine-status-…/       -> runs/pre-image-status-bundle-<stamp>/
```

The run id carries the stamp, so the file inside is named for its kind without
one. State that once in `run-time-machine.md`; several trees currently draw the
flat form.

The two `record-time-machine-evidence.sh` outputs are not `run-time-machine.sh`
kinds and take their own contexts: `pre-image-diskutil-verify` and
`pre-image-evidence-summary` (§9, Decision 2).

**`time-machine/sign-offs/` is not swept into `runs/`.** Per the Revision 116
design, sign-offs are deliberately un-indexed: officialness under `official/` is
computed latest-wins, and keeping an answered file authoritative would depend on
remembering to pin it after every edit — the failure the mechanism exists to
prevent.

## 6. Scope

Two coupled producers, nine artifact kinds, four read-backs, one atomic edit.

| Producer | Writes |
|---|---|
| `bin/run-time-machine.sh` | `status`, `logs`, `completion-check`, `compare`, `verifychecksums`, `diagnose` |
| `bin/record-time-machine-evidence.sh` | `pre-image-time-machine-status-*/` bundle, `diskutil-verifyvolume-applebackups-*.txt`, `final-time-machine-checklist-*.md` |

`record-time-machine-evidence.sh final` reads **four** of the other script's
artifacts back by `-maxdepth 1` glob:

- `latest_matching_file()` — line 441, used at 508 (`completion-check-*.md`),
  511 (`diskutil-verifyvolume-applebackups-*.txt`), 517 (`verifychecksums-*.txt`)
- line 523 — `find … -maxdepth 1 -type d -name 'pre-image-time-machine-status-*'`

All four break the moment files move under `runs/`, so both producers and every
read-back change together. Other readers: `bin/reimage-checklist.sh` (line 994,
non-emptiness of the category) and `bin/record-reimaged-system.sh`.

Docs to update: `run-time-machine.md` (lines ~177–191 draw the flat layout),
`references/master-directory-reference.md` (~695),
`references/backup-file-reference.md` (~217), `reimaging-guide.md` (~550).

## 7. Implementation notes

- **`artifact_path` is called inside a command substitution.** Six sites:
  `out="$(artifact_path status txt)"` and friends. `artifact_run_begin` sets
  shell variables and a subshell discards them, so **the call sites change
  shape**, not just the helper. This is the single largest mechanical change.
- **One EXIT trap covers every command.** The dispatch `case` is the last
  statement in the file and exactly one command runs per invocation, so a single
  trap can finalize or abort without touching any command's early-return paths.
- **Exit status 3 must finalize, not abort.** `verify-latest` exits 3 (line 1124)
  when checksums mismatch. The manifest header states the rule: *a run that
  reported findings is still a completed run — the findings are the evidence.*
  Aborting would discard the only record of the mismatch.
- **`--context` defaults to `pre-image`**, and `record-time-machine-evidence.sh`
  needs the same option so both producers agree on the phase.
- **Bash 3.2 + BSD userland.** No `mapfile`, no associative arrays, NUL-delimited
  traversal where filenames are involved.

## 8. Verification

- Each of the six subcommands run end to end against a scratch artifact root:
  staged, promoted, indexed, pointer advanced, no `.incomplete` left behind.
- `verify-latest` forced to a mismatch, confirming status 3 still finalizes.
- A `record-time-machine-evidence.sh final` run after conversion, confirming it
  resolves all four inputs it used to glob.
- A simulated Phase 16 pass proving the pre-image and post-image lineages stay
  separate — §1's defect, demonstrated fixed. This is the test that justifies the
  whole change and should not be skipped.
- Migration rehearsed against a **copy** of the seven files before the real one.
- `bash -n`, `verify-script-portability.sh`, `verify-doc-paths.sh --all`
  (0 MISSING / 0 ANCHOR BROKEN), `verify-runbook-structure.sh` against its
  then-current baseline.
- `/bin/bash -n` on the target Mac — owed here and on Revisions 116–132.

## 9. Decisions — both settled

**Decision 1 — settled 2026-09-02: (i), migrate everything.**

Every existing flat artifact moves under `runs/`, so the category ends in one
shape with no permanent exception and no reader carrying two paths. This is only
available because closed artifacts may now move with a backup taken first
(`sign-off-consolidation.md` D3); under the old constraint (iii) would have been
the least-bad compromise.

What that commits to, in order:

1. **Back up first**, whole and once, off this volume — the seven flat files and
   the `pre-image-time-machine-status-*/` bundle. Nothing moves before the copy
   exists, and the manifest entry names where it went.
2. **Rehearse against the copy.** The migration is a rename plus a wrap; it is
   also irreversible on a category whose contents cannot be recaptured.
3. **Migrate**, per the layout in §5.
4. **Split** `final-time-machine-checklist-20260817-082122.md` into
   `pre-image-evidence-summary` and its sign-off in the same pass, so the file is
   touched once rather than twice. It is one of the 35 mixed-mode artifacts in
   `sign-off-consolidation.md` §3 and this is where it gets handled.
5. **Convert the producers and all four read-backs** in one atomic edit (§6), and
   only then delete nothing — the backup stays until the verification in §8
   passes.

**No decisions remain open on this design.** What is left is the work.

**Decision 2 — settled 2026-09-02. It splits, and neither half is called a
checklist.**

The file is currently mixed: automated rows plus two answerable rows. Under
`sign-off-consolidation.md` D2 it splits, and the split is what makes the naming
obvious — once the answerable rows leave, **nothing in the remaining file is a
checklist**. There is nothing to tick. It is a roll-up of statuses derived from
five other artifacts.

So it is a run, and it is named for what it holds:

| Half | Lands as | Contains |
|---|---|---|
| automated | `time-machine/runs/<phase>-evidence-summary-<stamp>/evidence-summary.md` | the derived status table and the run ids it read |
| answered | `time-machine/sign-offs/<phase>-evidence-summary-<stamp>.md` | the two rows a person closes |

Contexts `pre-image-evidence-summary` and `post-image-evidence-summary`.
`summary` is the repo's existing word for a derived roll-up —
`repo-audit-summary.txt`, `office-stability-summary-*.md`,
`staged-ignored-files/live/summary.txt` — so it needs no new vocabulary.

**Why not call the automated half a sign-off.** A sign-off is the rows a person
answers; that is the entire definition `sign-offs.sh` is built on. Calling the
automated half a sign-off would re-merge the two things this split exists to
separate, and it would put a regenerable artifact in the one directory whose
whole purpose is holding what cannot be recomputed.

**Why the run half earns its index — the point the roll-up question sharpened.**
Converted, it stops resolving its inputs with `latest_matching_file` — "whichever
sorted last" — and resolves `artifact_run_official … <phase>-completion-check`
and its three siblings instead. That means it can **record the run ids it read**.
The grouping that D leaves implicit in a best-effort `Note` column becomes
explicit in the one artifact whose job is to tie an operation together. The
`Note` stays as the weak, category-wide grouping; the summary is the strong,
per-operation one.

`record-time-machine-evidence.sh` already half-implements the sign-off half — it
calls `signoff_begin` at line 473 and `signoff_row` at 584–585. The 2026-08-17
artifact predates that code, which is why it is still mixed.

### One consequence for §1 worth stating plainly

If the summary is only ever produced once per phase, §1's scenario —
*regenerating the Phase 5 roll-up after Phase 16 reads Phase 16's data* — is
hypothetical rather than live. **The conversion is still required**, on the
narrower ground: Phase 16 runs the summary too, and its `latest_matching_file`
globs the same flat namespace, so the post-image summary would read pre-image
artifacts and vice versa. The collision is the argument; regeneration was only
the most vivid way to describe it.

Both decisions are made. The conversion is cheap now and expensive after
Phase 16, which has not run.

---

## History

The earlier record existed because **the reasoning behind the choice was made in
conversation and was nearly lost**: a first version of the notes carried the
option analysis, and a later rewrite replaced it with a summary of the outcome.
The outcome without the rejected alternatives is not a decision, it is an
assertion. That is why §2 and §3 above are longer than the decision they support,
and why they stay even though the decision is settled.

The original approval was given against *"six artifact kinds from one script"*.
The real shape is nine kinds across two coupled producers with four `-maxdepth 1`
read-backs between them — roughly double — which is why the work was deferred
rather than started at the time. That scope is now written out in §6, so the next
person to pick it up is estimating against the real thing.
