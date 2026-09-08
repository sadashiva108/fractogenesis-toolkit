# The session capacity limit has no datum, and its only proxy points the wrong way

**Recorded:** 2026-09-08, from the allocator being asked for a data-driven session limit and finding none.  
**Session:** `allocation-and-inquiry-design-20260906-233205` (`session_015FpYVBF7dDoDrHfKDkq8fn`)  
**Severity:** F1 is the blocker — the limit the owner cares about cannot be computed from anything recorded. F2 is worse than a gap: the one available proxy would set a limit that licenses longer sessions, which is the opposite of the intent.  
**Felt at:** `bin/plan-findings-work.sh capacity`; `docs/architecture/allocation-and-inquiry.md` section 4.2; every session's `metadata.json`  
**Scope:** session management. The fix is a field a session writes about itself, then a measurement.  
**Relates to:** `0043` — its F8 is the same shape for a finding: a value that names a direction and cannot carry duration  
**Relates to:** `0047` — the retrofit inventory; nothing here is retrofittable, because the data was never captured

**Read:**

- `docs/architecture/the-record-and-the-graph.md` section 2.3
- `docs/architecture/allocation-and-inquiry.md` sections 4.2 and 8
- every `docs/sessions/*/metadata.json`
- the `capacity` report over all seven sessions, 2026-09-08

Recorded `unclaimed`. Not owned. **A placeholder capacity is in use and is marked
as one**; this bundle is what replaces it with a measurement.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | A session's length is recorded nowhere, so the limit the owner means cannot be derived | `un-started` |
| F2 | The only available proxy says rework falls as load rises, which would license longer sessions | `un-started` |
| F3 | What would have to be captured to measure degradation has never been written down | `un-started` |

## F1 — the limit is about length, and length is not a field

The owner's concern is that a session becomes too long. Every session record
carries owners, resources, owned bundles and contributions. **None carries how
long the session ran, how many turns it took, or how much context it had
consumed** — and those are the three candidate meanings of *too long*.

What the record does carry is **size**: bundles owned, findings held, and the
cost units the allocator derives from them. Size and length are not the same
quantity and the tooling has been treating them as one because size is what
exists.

`bin/plan-findings-work.sh capacity` therefore reports a number derived from
size and says in its own output that the datum for the real limit is missing.
**A capacity is currently a judgement**, and the tool prints that rather than
implying otherwise.

## F2 — the proxy inverts

Measured 2026-09-08 across the four sessions holding two or more decisions.
Rework counts decisions whose outcome was not `accepted`, findings reopened, and
bundles superseded — all already recorded, none newly captured.

| Session | Load | Decisions | Rework |
|---|---:|---:|---:|
| `run-index-design-20260901-000000` | 4.6 | 9 | 2 (22%) |
| `restore-apps-outstanding-20260903-000000` | 12.8 | 17 | 3 (18%) |
| `pre-image-capture-conformance-20260903-194532` | 30.4 | 31 | 2 (6%) |
| `session-management-re-evaluation-20260906-110105` | 35.2 | 23 | 2 (9%) |

**The two largest sessions are the two cleanest.** A capacity derived from this
is 35.2 cost units, higher than any figure anyone has proposed by hand, and it
argues for longer sessions rather than shorter ones.

Three readings of that, none of them settled here. The sample is four. Rework
normalises by decisions, so a session that decided more had more chances to be
right and the rate flatters it. And the metric counts **what came back, not what
should have** — a session that made a poor decision nobody revisited scores
clean.

**The finding is not that the number is wrong.** It is that this proxy cannot
answer the question, and a limit set from it would be a preference wearing a
measurement.

## F3 — what would have to be captured

Recorded because the owner asked where the data comes from, and because deciding
what to measure is cheaper before the measuring than after.

- **Length, in the three senses**: wall-clock span, turns, and context consumed
  at the point each decision was taken. Only the session itself can write these.
- **Position within the session**: which turn a decision was taken at, so quality
  can be plotted against depth rather than against total size. **This is the one
  that would show a curve**; everything else gives one point per session.
- **An outcome that is not self-reported.** Rework is scored by the same lineage
  that produced the work. A defect found later by a checker, by another session,
  or by the owner is a stronger signal and is already distinguishable in the
  record by who recorded it.

The shape this wants is the turn record in
`docs/architecture/allocation-and-inquiry.md` section 8 — already designed, not
yet emitted, and it is Tier 2 there precisely because nothing else can produce
it.

**Until then a capacity is chosen, not derived, and every report that prints one
says which.**
