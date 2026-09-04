# Decisions — `office-stability/checklists/` does not hold checklists

**Bundle:** `0013-office-stability-checklists-are-evidence-bundles` · **Status:** `in progress`
**Decided:** 2026-09-03, session `session_01PcgHu9kz9Hm5RatLQuFR8H`, owner present.
**Read against:** the volume at
`/Volumes/Data/reimage-CVG-0002160-500-20260816-open`, read-only, and the repository at `8f1ce13`.

`findings.md` is unchanged. It records what was found on 2026-09-01 and is not
rewritten to match what is decided here.

---

## D1 — The finding is resolved by work already shipped, not by new work

Verified on the volume rather than inferred from the ledger:

```text
office-stability/
├── MANIFEST.md        # Artifact Runs — two rows, both `recovered by reindex`
├── official/          pre-image-office-stability-assessment.txt
│                      pre-image-office-stability-evidence.txt
├── runs/              pre-image-office-stability-assessment-20260817-175050
│                      pre-image-office-stability-evidence-20260817-174547
├── sign-offs/         pre-image-office-stability-assessment-20260817-175050.md
└── watcher-history/   (E7 — the June incident, outside the index)
```

`checklists/` is gone. `latest-pre-image-office-stability-checklist.txt` survives
only inside `_pre-conversion-backup-20260902/`. Revision 137 renamed the producer
and converted its manual rows; Revision 138 moved the bundles and extracted the
sign-off. Both predate this bundle.

So `0013` closes against Revisions 137 and 138. The finding's own header, which
says the directory move is still owed and cites exception E5 as its authority,
was already wrong when this session inherited it: `artifact-migration-2026-09-02.md`
records **E5 as CLOSED by Revision 138**.

**Rejected — treat the ledger as authoritative and close without looking.** The
ledger and the finding disagreed, and closing on the word of either would have
recorded a decision neither of us had checked. The volume settled it in one
listing.

## D2 — The two lineages stand, and the names are correct

The conversion did not produce the name `findings.md` proposed. The finding asked
for one lineage, `pre-image-office-stability-<stamp>`, with contexts
`pre-image-office-stability` and `post-image-office-stability`. What shipped is
two, carrying Revision 137's contexts, as `capture-office-stability.md` →
Bundle Layout already documents:

> The collector writes `<phase>-office-stability-evidence`, holding the numbered
> section files, the run summary and the evidence ZIP; the assessor writes
> `<phase>-office-stability-assessment`, holding its verdict and the per-check
> evidence behind it.

**Decided: that is right and stays.** `assessment` names the run that holds the
verdict, which is what the word says. The volume agrees — the evidence run is 11
files and 75 MB of numbered sections plus the baseline ZIP; the assessment run is
17 files and 824 KB of verdict plus the excerpts behind each check.

**Rejected — the single lineage the finding proposed.** Two producers write
different artifacts at two runbook steps. One lineage means one `official/`
pointer naming whichever ran last, which is the failure per-lineage pointers
exist to prevent and which `.internal/artifact-runs.sh` states in its header.

**Rejected — swapping the two names.** Considered because the assessment run is
the later of the two and is the one that sorts material into `system/`,
`processes/`, `watcher/` and `logs/`, so it reads as the aggregate. Rejected
because the pair is named for what each run *is*, not for its shape or its clock:
the assessor produces a verdict. A swap would also be a lineage rename against
citations that already exist — two `official/` pointers, the sign-off filename,
both MANIFEST rows, the runbook and `master-directory-reference.md` — which is
`0009`'s hazard with real instances.

**Rejected — a third pair of terms.** Nothing was wrong with the words. What was
missing was a definition, which D3 supplies.

## D3 — Define the two words where a reader looks for them

The distinction lives in one sentence of Bundle Layout. `capture-office-stability.md`
has a `Terminology` table, and it defines Watcher, Marker, Baseline bundle,
Workload snapshot, Phase and Incident — not `evidence` and not `assessment`, the
two words the lineage names turn on.

**Decided: add an `Evidence` row and an `Assessment` row to that table**, saying
which producer writes each and what it holds. One toolkit write, during
`resolving`, in the runbook this bundle belongs to.

**Rejected — leave the definition in Bundle Layout only.** A reader asking which
lineage is which goes to the table that exists to answer exactly that. Leaving
the answer out of it is what made the question hard to settle from the documents.

## D4 — The item 4 dependency is discharged

`findings.md` folds its fix into item 4's conversion of `office-stability/`, and
`sign-off-consolidation.md` §7 says the same. That conversion has happened. This
bundle no longer waits on item 4, on `run-index-design-20260901-000000`, or on
anything else.

## D5 — What is not taken into this bundle

Found while verifying D1. Widening a finding at the moment it closes is how a
small change becomes an unreviewable one, so each was routed rather than folded
in. Three of the four have since been placed:

| Found | Where it went |
|---|---|
| `runs/pre-image-office-stability-assessment-20260817-175050/README.md` cited two files that did not resolve — one renamed by Revision 138, one the August producer never wrote | **`0030` finding 5.** Both repaired 2026-09-03 on the owner's direction, under `0030`'s D2. The pre-conversion backup retains the original lines |
| `office-stability/MANIFEST.md` carries no `rename` row, so the former lineage name is recoverable only from `_pre-conversion-backup-20260902/` | **`0030` finding 3**, held open — the row belongs to whoever does the next conversion |
| The evidence run holds `pre-reimage-office-baseline-….zip` inside a run id spelled `pre-image-…` | **Not a defect.** `capture-office-stability.sh` runs two phase vocabularies deliberately — an internal `pre-reimage`/`post-reimage` label naming the bundle and ZIP, mapped to `pre-image`/`post-image` for the run context, with the mapping commented at line 495 and a reader depending on the old prefix at `reimage-checklist.sh:1609`. `Terminology`'s `--phase` row is accurate. Recorded as an observation, not parked |
| `sign-off-consolidation.md` §4 and §6 and `evidence-conformance.md` Table 3 and line 213 still describe the pre-Revision-138 shape and the renamed producer | **Still unrouted.** Larger than three passages: Table 3's banner reads *"No artifact was migrated"*, false wholesale since Revision 138, and `docs/ledgers/` states that a ledger is re-derived and replaced rather than patched. Wants its own cross-cutting bundle |

**Rejected — fixing the Terminology `--phase` values in D3's edit.** Moot: there
was nothing to fix. Kept here because the rejection was reasoned against a defect
this session had asserted and had not verified, and the correction belongs beside
the claim.

## What this authorises

One toolkit write: the two Terminology rows in `capture-office-stability.md`
(D3). Nothing on the volume. `resolving` may begin — this bundle holds one
finding and it now has a decision.
