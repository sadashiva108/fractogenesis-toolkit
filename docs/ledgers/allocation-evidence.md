# Allocation evidence — run 1

**Re-derived and replaced wholesale**, like every ledger here. Do not edit a row;
re-run and replace the file. Produced by the prototype described in
[`docs/architecture/allocation-and-inquiry.md`](../architecture/allocation-and-inquiry.md)
section 8, from a hand-populated graph — **not yet from the tree**, because the
reader waits on `0043`.

**Run 1** — 2026-09-06, `allocation-and-inquiry-design-20260906-233205`, against
the nine `unclaimed` bundles as they stood at commit `8204516`. Linux VM, Bash
5.1.16, GNU coreutils. **Not macOS.**

## The queue

9 bundles · 28 findings · 43.0 cost units, where cost is the write category from
`docs/legend.md` weighted by severity, never a count of rows.

## Held back

**None.** No `blocks` or `evidences` edge points into the queue from outside it,
so no bundle was held and **no ready finding was stranded by bundle atomicity.**

| Metric | Run 1 |
|---|---:|
| bundles held | 0 |
| **held-back ready findings** | **0** |

That second number is the one that decides whether per-finding ownership is worth
taking — `docs/architecture/allocation-and-inquiry.md` section 12. One run is not
a trend. It is the first entry against a decision that was taken on an argument.

## The proposal

| Session | Bundles | Load / capacity |
|---|---|---|
| `session-management-re-evaluation-20260906-110105` | `0015`, `0044` | 11.4 / 12.0 |
| `pre-image-capture-conformance-20260903-194532` | `0033`, `0042` | 19.6 / 20.0 |
| `run-index-design-20260901-000000` | `0001`, `0008`, `0011`, `0016`, `0017` | 23.7 / 26.0 |

Edges kept inside one session: `evidences` `0017/F1` → `0001/F1`, `F2`, `F3` ·
`shares-surface` `0011/F1` → `0001/F6` · `relates-to` `0008/F1` → `0011/F1` and
`0016/F1` → `0017/F1`.

## Ablation — the ranking off, load balance only

| | Full objective | Edges off |
|---|---:|---:|
| edge weight kept in-session | 16 | 3 |
| cross-session split weight | 4 | 6 |

**The failure is nameable, not numeric.** With the ranking off, `0001` and
`0017` land on different sessions, severing three `evidences` edges — so the
session deciding `0001`'s Phase 12 entry would be reading evidence a *different*
session is still deciding whether to re-run.

## Adversarial arm — recorded as less useful than the ablation

Minimising the objective assigns all nine to one session: score −421, driven
entirely by the capacity penalty, with **perfect cohesion and zero splits**. It
demonstrates that a single-term objective is gameable and nothing about
allocation. Kept here because an arm that taught little is worth saying so about.

## The prediction, and what it caught

`session-management-re-evaluation-20260906-110105` put a prediction on the record
before this run: `0044` should land with `0036`, for `evidences` or `co-decides`.

**Destination met. Reason different, and the first attempt was luck.** `0044`
does land with `0036`'s owner, but by `constrains` plus subject affinity rather
than either predicted kind — and in the *first* run it landed there by
load-balancing coincidence, because the objective as committed in Revision 211
scored zero for any edge reaching a finding already owned. The prediction is the
only reason that was noticed rather than read as a success.

The correction is in section 4.2. **Pre-registering the expected placement and
the expected reason should be standard for every run**, because the failure this
design cannot otherwise see is a right answer arrived at for no reason.
