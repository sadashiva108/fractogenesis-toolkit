# Decisions — renames break citations, and only a record's values are frozen

**Bundle:** `0030-renames-break-citations-and-which-may-be-repaired` · **Status:** `in progress`
**Decided:** 2026-09-03, session `session_01PcgHu9kz9Hm5RatLQuFR8H`, owner present.
**Supersedes:** `0009-dated-artifacts-cite-run-ids-a-rename-breaks`.

## Decisions carried from `0009`

`0009` has no `decisions.md`. Nothing was formally decided against it, so nothing
carries forward and nothing needs re-affirming.

Its `findings.md` does state a position under *Plan* — *no code change proposed,
and no repair of the 2026-08-20 checklist* — which is a reading's conclusion
rather than a recorded decision. **D2 supersedes it**, and says so rather than
quietly departing from it.

---

## D1 — Supersede `0009`; do not edit it and do not withdraw it

`0009`'s reading holds. What changed is its conclusion, and a reading is not
rewritten to match what was later concluded.

**Rejected — correct `0009` in place.** `findings.md` is written once and
corrected only for accuracy. Narrowing its *Plan* is not an accuracy correction;
it is a different answer to the same reading, which is what a superseding bundle
is for.

**Rejected — `withdrawn`.** The sixth status, added in Revision 177's line of
work, means *the reading is dropped and nothing replaces it*. This reading is not
dropped — it is carried forward almost intact. `superseded` retains the original
and names its replacement, which is what the owner asked for.

**Rejected — leave `0009` `unresolved` and put the rule somewhere else.** The
rule contradicts `0009`'s stated plan. Two live documents disagreeing about
whether a citation may be repaired is worse than either answer alone.

`0009` stays listed in `run-index-design-20260901-000000`'s manifest at status
`superseded`. Superseding a reading does not retroactively change who recorded or
held it.

## D2 — A record's values are frozen; its references are not

**Decided**, in the owner's words:

> A dated record's **values** are never edited — dates, measurements, verdicts,
> counts. A **reference** inside one — a filename, a path, a run id — may be
> repaired when the thing it names still exists, provided any timestamp in the
> name is retained exactly. The stamp is what binds the citation to the same
> evidence; changing it would falsify. Repairing the name around it restores a
> pointer.

**And the edge case is decided with it:** a reference that was *wrong when
written* — naming a file the producer never created — is still a reference and
not a value, and may be repaired. Recorded explicitly because the rule as stated
does not reach it, and finding 5 line 8 is an instance.

**Rejected — `0009`'s blanket prohibition.** It treats a pointer and a
measurement as the same object. Its own instance shows the cost: it declined to
repair a citation whose target it had already found on the volume, unchanged,
under a new name.

**Rejected — permit repair only where a backup preserves the original.** Argued
for, because the backup is what made finding 5's repair safe. Rejected because it
confuses *safe* with *lawful*: the reason a reference may be repaired is that it
is not evidence, and that is true whether or not a copy exists. A backup lowers
the cost of being wrong; it is not the thing that makes the repair legitimate.

**Rejected — require the repair to note itself in the artifact.** A dated record
gaining an editorial footnote is a change to the record. The manifest `rename`
row of finding 3 is the right place for that, which is why finding 3 is held open
rather than answered here.

## D3 — Finding 5's two lines are repaired, and the repair is recorded

Done 2026-09-03, on the owner's direction, in
`office-stability/runs/pre-image-office-stability-assessment-20260817-175050/README.md`:

```text
7  - `pre-image-office-stability-checklist.md`  →  - `office-stability-assessment.md`
8  - `watcher/marker-timestamp.txt`             →  - `watcher/marker-and-current-time.txt`
```

Written in place, no unlink. Every path in that README now resolves. The
pre-conversion copy under `_pre-conversion-backup-20260902/` retains both
original lines, so what the August producer wrote is still on the volume.

**Rejected — repair line 7 only.** Recommended by this session before the backup
was checked, on the reasoning that line 8 was the sole surviving trace of a
producer defect. It was not: the backup holds it, and the current producer no
longer has the defect. The recommendation did not survive its own evidence.

**This was an evidence write**, made with the owner's word for that specific run,
and it is the only one this session has made.

## D4 — `0009`'s own stale path is not repaired

Finding 4 shows `0009` citing `boundaries/…/checklist.md`, which Revision 156
moved. Under D2 that is repairable — it is a path, its target exists, and there
is no stamp to preserve.

**Decided: leave it.** The owner asked that the original be retained, and a
superseded bundle is retained as it was written. This bundle records the current
path instead, so a reader following `0009` reaches the evidence through finding 4.

**Rejected — repair it, since D2 permits it.** D2 governs whether a repair
falsifies a record. It does not override the separate property that a superseded
reading is frozen. Two different rules, and the narrower one wins here.

## D5 — The `bookend.md` citation is not repaired by this bundle

`bookends/runs/restore-runtime-exit-20260820-032645/bookend.md` line 19 cites
`post-image-restore-runtime-diff-20260820-032625`; the target exists as
`restore-runtime-inventory-diff-20260820-032625`. D2 permits the repair, stamp
retained, and it is stale twice — the lineage rename and the later dropping of
the `post-image-` prefix.

**Held, not decided.** It is an evidence write in `reimaged-system/`, and the
owner grants those one run at a time. Recorded here so it is a queued decision
rather than a rediscovery.

## D6 — Finding 3 is held open deliberately

The `rename` row belongs in `.internal/artifact-runs.sh` and in every category
manifest that has been through a conversion. That is a toolkit write plus an
evidence write across categories this session does not own, and the next
conversion is the event that should design it — item 4, still held by
`run-index-design-20260901-000000`.

**Rejected — decide it here to unblock the bundle.** `resolving` requires every
finding decided, so holding finding 3 open holds the whole bundle short of any
toolkit write. That is the correct outcome: the alternative is designing a
manifest row for conversions this session is not doing.

**Finding 3 is now decided, in D7 below.** Written 2026-09-04 by
`run-index-design-20260901-000000` under an owner's override; the reasoning above
is unchanged and stands as the reason it waited.

---

## D7 — Category manifests get a `rename` row, filed under the surviving lineage

**Decided by `run-index-design-20260901-000000`, 2026-09-04, under an owner's
override.** `docs/legend.md` holds that from `in progress` onward only the owner
writes to a bundle; the owner set that aside for this one decision, because D6
named a session that does not own this bundle as the right one to make it and the
framework has no vocabulary for a finding owned separately from its bundle. The
override is recorded in the `APPLY-MANIFEST.md` entry that carries this change,
per `docs/legend.md` — *a revision carrying an overridden change says so, and says
what was overridden*. Nothing in D1–D6 is altered beyond the pointer above, and
`findings.md` is untouched.

**Yes. A lineage rename appends one row to the category's `MANIFEST.md`,** with
`rename` in the Kind column, **the surviving context in the Context column, and
the former context key in `Run or target`**:

```text
| 2026-09-04 12:00:00 | rename | `pre-image-office-stability-assessment` | unknown | `pre-image-office-stability-checklist` | — | former lineage name; renamed Revision 137, reindexed Revision 138 |
```

Written by a new `artifact_run_record_rename "$CATEGORY_ROOT" "<surviving-context>"
"<former-context>" "<reason>"`, shaped like the existing
`artifact_run_retire_lineage`. `_artifact_runs_append_row` already takes the kind
as an argument, so the row itself needs no new machinery.

**`artifact_runs_rebuild` needs no change, and that was checked rather than
assumed.** Its context list is `sort -u` over the Context column of every row, so
filing under the surviving name adds nothing new to the loop — that context
already has `run` rows. Selection inside the loop goes through
`_artifact_runs_rows_for` with a kind filter, so `run`, `pin` and `retire`
lookups cannot see a `rename` row. It is inert to the pointer computation by
construction. That inertness belongs in the `artifact-runs.sh` header, where the
next reader will look for it, rather than being rediscovered.

**Scope: lineage renames only.** A run id never contains its category's directory
name, so a category rename — `boundaries` → `bookends`, Revision 156 — breaks
*paths*, not run ids, and cannot be expressed in a Context column that holds
lineage keys. Paths inside the repository are already covered by
`verify-doc-paths.sh`; paths inside dated artifacts are findings 4 and 5 of this
bundle. **A category rename therefore has no record in the index and this decision
does not give it one.** Stated rather than quietly folded in, because finding 3
cites both events and only one of them is answered here.

**Retroactively, for both lineage renames that have already happened**, because
the mechanism otherwise begins with a hole in exactly the categories that
motivated it:

| Category | Surviving context | Former context | Recoverable from |
|---|---|---|---|
| `office-stability/` | `pre-image-office-stability-assessment` | `pre-image-office-stability-checklist` | `_pre-conversion-backup-20260902/` |
| `office-stability/` | `pre-image-office-stability-evidence` | `pre-image-office-stability` | Revision 137's rename record |
| `reimaged-system/comparisons/` | `restore-runtime-inventory-diff` | `post-image-restore-runtime-diff` | the citation in `bookends/runs/restore-runtime-exit-20260820-032645/bookend.md` line 19 |

The third is the one that proves the point: `post-image-` appears **zero** times
in that manifest, so the only surviving evidence of the former name is the broken
citation itself. A reader today cannot tell that citation from one that was always
wrong, which is finding 3 stated as a measurement.

Each retroactive row is an **evidence write** and needs the owner's word for that
category. They are not authorised by this decision.

### What it costs, and what it does not buy

Every future lineage rename becomes two acts, the second needing per-run owner
permission. Two categories owe retroactive rows.

**It makes a former name recoverable within a category; it does not make it
findable across the root.** A reader holding a stale run id still has to guess
which category to grep. And **it detects nothing** — no validator will tell anyone
a citation broke. The row only lets a suspicion be resolved. Detection is finding
1's subject and is not decided here.

### Rejected alternatives

**Rejected — do nothing; the backup is the record.** `_pre-conversion-backup-20260902/`
does hold the office-stability former name, and that is why finding 3 could be
written at all. But a backup directory is dated, disposable, and outside the index
a reader consults; the manifest is append-only and permanent. The comparisons
rename settles it — no backup exists for it, and the former name survives nowhere
in the index.

**Rejected — former name in Context, surviving name in `Run or target`.** It reads
more naturally and is worse in both directions. It puts a dead context into
`artifact_runs_rebuild`'s loop, where it survives only because
`[ -n "$runs" ] || continue` happens to skip it — correct by accident. And it makes
*"what was this lineage called before?"* unanswerable through
`_artifact_runs_rows_for "$manifest" "<live-context>" rename`, which is the query
a reader with the current name would write. The chosen shape answers both
directions; this one answers one.

**Rejected — a `renames.md` domain index beside `MANIFEST.md`.** The precedent
runs the other way. `repo-audit-index.md`, `size-audit-index.md`,
`loose-secrets-index.md` and `content-scan-index.md` all exist because their
*columns* do not fit the shared seven-column schema. A rename row fits it exactly,
and the manifest already carries two non-`run` kinds. A second file would be a
second thing to keep in sync for no gain.

**Rejected — rewrite the stale rows in place to the surviving name.** The
manifest's own header says nothing in it is ever edited in place, and the edit
would destroy the fact being recorded. It also cannot work where the rows were
replaced by a reindex, which is what actually happened to `office-stability/`.

**Rejected — a validator that checks artifact run ids against the manifests.**
Argued for, because a row nobody reads helps nobody. Rejected as the answer to
*this* finding: the artifact root is not in the repository, is read-only to
sessions by default, and is absent wherever a validator would run. Finding 3 asks
for recoverability, not detection, and answering a different question would leave
this one open.

**Rejected — gate the rename on the row being written first.** A gate on an act
that needs per-run owner permission would stop a rename on paperwork. Both renames
so far show the row is worth having *after* the fact, which a gate would have
prevented from ever being written.

## D8 — Detection is deferred, and it is downstream of D7 rather than parallel to it

Finding 1 says a rename leaves every prior citation naming something gone and
nothing detects it. D7 answers recoverability and says in its own words that the
row *"detects nothing"*, leaving finding 1 open. This decides it.

**Decided: no detector is built by this bundle, and the reason is that one cannot
work until `rename` rows exist.** Both candidate designs were prototyped read-only
against the volume on 2026-09-04 rather than argued about.

| Design | Result over 6,907 text artifacts |
|---|---|
| flag any `<words>-YYYYMMDD-HHMMSS` that resolves to no run | 329 id-shaped strings, **167 unresolved** — and essentially all false: `bundle-watch-20260608-013002`, `all-cert-keychain-discovery-*`, `cert-key-file-candidates-*` are dated **filenames**, not citations |
| flag only `<known-context>-STAMP` that resolves to no run | one citation matched, **zero unresolved** — it found nothing, including the citation known to be broken |

**Why the second design finds nothing is the finding restated as a measurement.**
The broken citation is `post-image-restore-runtime-diff-20260820-032625`. Its
context appears in **zero** live manifests, because the rename removed it; the
surviving context `restore-runtime-inventory-diff` appears in one. A detector
keyed on currently-known contexts is structurally blind to exactly the citations a
rename breaks, because the rename deletes the key it would need to look them up.

**So D7's row is the missing input, not a consolation prize.** Filter by known
contexts **plus the former contexts recorded in `rename` rows**, and design B finds
the citation. Detection is therefore downstream of D7: it becomes tractable when
the rows exist and cannot work before, which is why it is deferred rather than
rejected.

**A correction to D7's rejected alternatives, recorded here rather than by editing
another session's decision.** D7 rejects a validator partly on the ground that the
artifact root *"is not in the repository, is read-only to sessions by default, and
is absent wherever a validator would run."* The tree contradicts two thirds of
that. Thirty-eight scripts under `bin/` read `$REIMAGE_ARTIFACT_ROOT`; seventeen
of them report PASS/FAIL against it; `bin/reimage-checklist.sh` **is** a validator
over the artifact root, and exits 2 when the root is unset rather than pretending
otherwise. Read-only argues the other way: a detector only reads.

What survives is a real distinction, and it is where such a check belongs. This
repository has two validator families: **repo lints** — `verify-doc-paths.sh`,
`verify-runbook-structure.sh`, `verify-script-portability.sh`,
`verify-findings-counts.sh` — which run anywhere including a fresh clone with no
volume attached and whose baselines every manifest entry quotes; and
**artifact-root checks**, which need the volume and are run by the operator at a
phase. A citation detector is the second kind. It must never join the first, or
every revision's baseline becomes conditional on a mounted drive.

**Rejected — build it now, with design A.** It reports 167 non-problems against
two real ones. A check with that ratio is not read twice.

**Rejected — build it now, with design B.** Measured at zero true positives. It
would ship as evidence that nothing is broken while the thing it was built for sits
in two files.

**Rejected — declare detection out of scope for the workflow.** It is buildable,
the precedent for its family exists, and `0009` recorded the hazard as structural
for exactly this reason. Closing the question would lose that.

### What the probe turned up that the bundle did not know

The citation appears in **two** bookends, not one:
`bookends/runs/restore-runtime-exit-20260820-032645/bookend.md` line 19 and
`bookends/runs/restore-access-entry-20260824-063529/bookend.md` line 16. D5 and
D7's retroactive table each name only the first. The surviving run exists, so both
are repairable under D2 with the stamp retained, and both remain queued rather than
taken.

---

---

## What this authorises

**Nothing outside `docs/`.** The one evidence write D3 records was made before
this bundle existed, on the owner's direct instruction for that run, and is
recorded here rather than authorised by here.

Every finding now carries a decision, so the gate `resolving` waits on is
satisfied. **Moving the bundle there is its owner's act, not this decision's** —
`pre-image-capture-conformance-20260903-194532` holds `0030`, and the override
that permitted D7 did not extend to the `STATUS-` tag or the index row. The
toolkit write D7 implies — `artifact_run_record_rename` in
`.internal/artifact-runs.sh` — and the three retroactive evidence writes are
authorised only once that owner moves the bundle and, for the evidence writes, the
owner grants each category in turn.
