# Prior-phase evidence — the verified map

**Item 2** of `docs/sessions/run-index-design-20260901-000000/prompt.md`. Everything
**before** Phase 11B. Verified 2026-09-01 by session `01KcZvrKMgfenhrT9DvxW9Jk`
against the repo and `/Volumes/Data/reimage-CVG-0002160-500-20260816-open`.

The brief asks for gaps under `docs/*-findings/`, and they are there — seven files,
listed at the end. This file holds the other half: the map itself, and the
conclusions that are **not** gaps. Those are the answers a later session would
otherwise re-derive, and "checked, and it is fine" is not something to file under
`gaps/`.

---

## 1. What each runbook actually invokes

Read from the runbooks, not assumed. This is what decides whether a missing
lineage is a skipped step or a runbook that never called for one.

| Runbook | prereqs | state `before` | state `after` | state `delta` | compare | exit |
|---|---|---|---|---|---|---|
| `enroll-and-stabilize` | — | — | — | — | — | — |
| `verify-reimaged-system` | — | — | — | — | — | — |
| `restore-runtime` | **yes** (Step 0) | — | — | — | **yes** (Step 10) | **yes** (Step 11) |
| `restore-access` | **yes** | **yes** | **yes** | **yes** | **yes** | **yes** |
| `restore-git` | **yes** | **yes** | **yes** | **yes** | **yes** | **yes** |
| `restore-apps` | **yes** | **yes** | — | — | — | — |

`enroll-and-stabilize` and `verify-reimaged-system` do not use this recorder
family at all. They use `record-enrollment.sh` and `record-reimaged-system.sh`
with `--context entry / pre-restart / post-restart / diff / exit`, which write
into `boundaries/` and `restarts/`. Different tools, same index.

## 2. What exists on the volume

| Lineage | `restore-runtime` | `restore-access` | `restore-git` | `restore-apps` |
|---|---|---|---|---|
| entry | 08-19 09:36 | 08-24 06:35 | 09-01 08:35 | 08-25 06:56 |
| exit | 08-20 03:26 | 08-24 17:35 | 09-01 15:36 | **none** |
| before | **none** | 08-24 08:44 | 08-24 17:48 | 08-25 06:55 |
| after | **none** | 08-31 22:09 | 09-01 15:13 | **none** |
| delta | **none** | 08-31 22:10 | 09-01 15:20 | **none** |
| inventory-diff | 08-31 11:50 | 08-31 22:09 | 09-01 15:35 | — |

Plus, under `restarts/`: `enroll-and-stabilize` and `verify-reimaged-system` each
hold `initial`, `pre-restart` and `post-restart`, all from 08-18/08-19. And under
`comparisons/`, `restore-access` additionally holds `cert-diff`,
`jdk-trust-diff` and `jdk-trust-result`, all written directly by
`bin/restore-access.sh` rather than by `compare-restored-state.sh`.

## 3. Missing lineages — skipped, or never called for?

This is the question the brief posed. Answers, in order of how much they matter.

### `restore-runtime` has no state walk — **not a gap, by design**

The brief's guess was right, and the tooling confirms it beyond the runbook.
`bin/record-restore-state.sh` declares:

```bash
SUPPORTED_RUNBOOKS="restore-access restore-git restore-repos restore-apps"
```

There is no `targets_restore_runtime()` and no way to ask for one. Phase 10A
answers a different question — *does this machine's toolchain match the one that
was captured* — and it answers it with `compare-restored-state.sh`, whose
`restore-runtime-inventory-diff` lineage is present and current as of 08-31. A
before/after walk of the same paths would add nothing that comparison does not
already say.

**Nothing to do.** Recorded here so item 5 does not reopen it.

### `restore-apps` has no exit — **not run deliberately; not runnable either**

Two separate facts, and only the second is a gap.

**Not run: intentional.** The owner has confirmed Phase 12 is unfinished, so
there was nothing to close out. A phase that is still in progress should not have
an exit recorded, and none was.

**Not runnable: a gap, but not about Phase 12.** `record-restore-exit.sh` has no
`check_restore_apps()` and rejects `--runbook restore-apps`, so the exit could
not be recorded even once the phase is finished. `restore-apps.md` likewise never
calls for `after` or `delta`, though `targets_restore_apps()` exists.

The real question is the owner's: the boundary-recorder family should be applied
consistently wherever it applies, or not treated as a convention at all. Coverage
today is nearly uniform with holes at both ends of the chain — 10B does not check
that 10A finished, and nothing can check that Phase 12 did.

→ `docs/cross-cutting-findings/0003-boundary-recorder-coverage-is-uneven/findings.md`

### `enroll-and-stabilize` and `verify-reimaged-system` are complete

Both hold entry, exit and all three restart lineages. `verify-reimaged-system`
additionally holds its `restart-diff`. Nothing missing.

Their boundary runs are dated 13 days after the phases ran, which is a reading
hazard rather than a hole → `docs/cross-cutting-findings/0005-boundary-runs-recorded-long-after-their-phase/findings.md`

### `restore-access` and `restore-git` are complete

Confirmed as the brief stated. `restore-git` is the only phase whose runbook
calls every recorder in the family, and it is the model the two gap write-ups
point at.

## 4. Does the recorded evidence predate its producer?

Every recorder in this family was last changed on 2026-09-01. So the honest
answer for almost everything is *yes* — but "changed" only matters where the
change altered what the recorder would say.

| Evidence | Predates producer | Would a re-run differ? |
|---|---|---|
| `restore-runtime-exit` 08-20 | yes | **Yes.** Its `Runtime comparison recorded` row cites a run that has been superseded twice, under a name that no longer exists. Its `Runtime comparison still current` row re-probes live tools |
| `restore-access-exit` 08-24 | yes | **Yes.** One row added since — `SSH host keys seeded` |
| `restore-access` after/delta/inventory-diff 08-31 | marginally | No. The 09-01 change to `compare-restored-state.sh` added the `SSH routing hosts` probe inside `collect_restore_git()` only — verified at line 538, within lines 501–542 |
| `restore-git` everything, 09-01 | no | No. Recorded after its producers settled |
| `restore-apps-before` 08-25 | yes | Immaterial — `targets_restore_apps()` is unchanged since |
| `enroll` / `verify` restarts 08-18/19 | yes | Out of scope here; both phases are closed and their restart points are first-wins |

The two that would differ are both worth re-running, and both are safe —
`exit` is latest-wins.

→ `docs/runbook-findings/restore-access/0021-restore-access-exit-predates-its-own-state-walk/findings.md`, which carries
the commands and the caveat on the new row, and names the `restore-runtime` case
as the same shape.

## 5. Point rules — what is safe to refresh here

| Point | Rule | Applies to |
|---|---|---|
| `before`, `pre-restart` | **first-wins — forbidden to re-record** | every `*-before` in §2, and both phases' `pre-restart` |
| `after`, `delta`, `entry`, `exit`, `diff`, `post-restart`, `initial`, `result` | latest-wins — safe | everything else |

No first-wins pointer in the pre-11B set is wrong, so none needs a pin. The one
existing pin — `restarts/official/enroll-and-stabilize-pre-restart.txt` →
`20260818-235709` — is correct and stays.

## 6. Gaps filed from this pass

| File | Rework needed? |
|---|---|
| `boundary-recorder-coverage-is-uneven.md` | two decisions first; build after `restore-apps.md` is finished |
| `restore-access-exit-predates-its-own-state-walk.md` | yes — commands included |
| `recorder-usage-strings-understate-supported-runbooks.md` | yes — one revision covers both scripts |
| `dated-artifacts-cite-run-ids-a-rename-breaks.md` | no code change; a rule for items 3 and 4 |
| `orphaned-comparison-lineage-runtime-version-comparison.md` | optional — two options |
| `boundary-runs-recorded-long-after-their-phase.md` | no re-run; two cheap adoptions |
| `reimaged-system-checklists-directory-is-unclaimed.md` | trivial; fold into the next scaffolding change |

## 7. Does any of this change the Phase 11B plan?

**No.** Nothing here alters item 1's findings, its ledger, or its handoff. Two
things touch it sideways and neither is blocking:

- `recorder-usage-strings-understate-supported-runbooks.md` names
  `record-restore-prereqs.sh`, which has a `restore-repos` case. The change is to
  a usage string, not to Phase 11B behaviour.
- `boundary-recorder-coverage-is-uneven.md` observes that
  `check_restore_apps()` in `record-restore-prereqs.sh` gates Phase 12 entry on
  an official `restore-repos-exit`. That pointer exists and is current, so
  Phase 11B's refactor does not need to produce anything new for it.

## 8. Settled by the owner, and one thing flagged

**`reimaged-system/time-machine/` is intentionally empty** — Phase 16 has not
been reached, the same reason `toolkit-snapshot` and `managed-inventory` hold no
post-image bundles yet. The root-level `time-machine/` holds post-image evidence
alongside pre-image, the way every `capture-` category does.

This session had raised the empty directory as a possible fifth option for item 3
— post-image Time Machine evidence landing under `reimaged-system/`, where the
phase discriminator would be unnecessary. **That option is closed.** The decision
confirms the design record rather than disturbing it: the category holds both
phases side by side, so it is squarely the exception `artifact-runs.sh` names,
and `pre-image-status` / `post-image-status` contexts are correct.

- **The 2026-08-19 Microsoft 365 Copilot ticket** is still outstanding in both
  prior handoffs — likely raised against expected behaviour, conclusion never
  read back. It is a Phase 12 app question rather than an evidence question, so
  it stays where it is rather than becoming a gap file here.
