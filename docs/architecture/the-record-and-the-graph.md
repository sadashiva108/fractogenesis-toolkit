# The record and the graph — what the state format does not yet carry

**Written:** 2026-09-08, `allocation-and-inquiry-design-20260906-233205`, after  
building the allocator and the interviewer against the real `metadata.json`.  
**Scope:** the distance between what
[`state-as-data.md`](state-as-data.md) records and what
[`allocation-and-inquiry.md`](allocation-and-inquiry.md) needs to read.  
**Status:** gaps recorded and measured. **Nothing here is decided.**

---

## 1. Why this is a separate record

`state-as-data.md` answers *how does the framework store its own state*.
`allocation-and-inquiry.md` answers *how is that state ordered and put to the
owner*. Both are right about their own subject, and neither is the place to say
that the first does not yet feed the second.

Every gap below was found by **running** the two consumers over the real tree,
not by reading the schema. That matters, because six of the eight are fields
that exist and are empty rather than fields that are missing — which a schema
review cannot see and a run cannot miss.

## 2. The gaps, measured

| # | What the graph needs | What the record holds | Measured 2026-09-08 |
|---:|---|---|---|
| 1 | edges between findings | the array exists | **0** decision edges; 29 `carried`, 2 `successor` |
| 2 | staleness | `updatedAt` per finding | **0 of 147** populated |
| 3 | a severity rank | `severity` | **47 of 47** free text |
| 4 | the write category | `scope` | free text; the category is **guessed by keyword** |
| 5 | why a finding cannot be decided yet | — | no field at all |
| 6 | how long a session is | — | no field at all |
| 7 | who owns a bundle, from the bundle | `ownership`, null when owned | **2** bundles are null and in no manifest |
| 8 | a controlled outcome vocabulary | `outcome` | **2** decisions read `replaced → DX`, which §11 does not define |

### 2.1 The edges array is empty of the edges it was built for

`0043` D1 settled the contract and `state-as-data.md` §4.3 carries it — including
`0036/F1 constrains 0044/F1` as its worked example. **That edge is not in the
data.** Nothing asserts `blocks`, `evidences`, `constrains`, `co-decides`,
`contradicts` or `relates-to`; the 31 edges present are lineage, produced
mechanically by the migration.

The consequence is exact and visible in every run: the allocator's cohesion term
scores **zero**, so allocation is decided by pull, subject affinity and load
alone, and the interviewer's lifting and propagation stages have nothing to walk.
**This is an adoption gap, not a schema gap** — and it is the largest single
thing between the tooling and the quality it was designed for.

### 2.2 Six fields that exist and are empty

`updatedAt` was designed for `0043` F8 — *`framing` names a direction, not a
position* — and is null on all 147 findings, so *`framing` since when* is still
unanswerable and **noticing silence remains impossible**.

`severity` is prose in all 47 bundles: *"F1 and F3 are high — both have recorded
incidents"*. A reader gets more from that than from a rank; a ranker gets nothing
from it. Both are true and the record should carry both.

`scope` is prose too, and the graph needs the **write category** from it —
record, toolkit or evidence — which `docs/legend.md` already grades by how each
fails. The implementation **guesses it by keyword match** on the scope sentence.
That is inference, it is exactly what this repository distrusts, and it is
currently load bearing in the objective through the cost model.

### 2.3 Two things nothing records at all

**Readiness.** A finding may be `framing` and still unanswerable — it needs a
check run, or a fact only the owner has. Section 5's first stage drops what
cannot honestly be asked, and it can only drop what is not `framing`. Everything
finer is invisible.

**Session length.** This one is worth stating plainly because it defeated a
direct instruction. Asked for a data-driven session limit, the tool reports:

```text
  run-index-design-20260901-000000                   4.6   11   11    9  2 (22%)
  restore-apps-outstanding-20260903-000000          12.8    3   21   17  3 (18%)
  pre-image-capture-conformance-20260903-194532     30.4    8   20   31  2  (6%)
  session-management-re-evaluation-20260906-110105  35.2    3   30   23  2  (9%)
```

**Rework falls as load rises.** The two largest sessions are the two cleanest.
On the only evidence the record holds, decision quality does not degrade with
size at all — so a capacity derived from it would be 35.2, higher than any guess,
and pointed the wrong way.

The resolution is not to distrust the number. It is that **the record cannot see
the thing the limit is about.** A session becomes too long in turns, in context
and in the owner's attention, and none of the three is in any record here. Until
a session logs its own length, a capacity is a judgement — and the honest tool
says so and takes it as an argument rather than deriving it.

### 2.4 Two ambiguities that produced bugs

`ownership` is null both when a bundle is owned per a manifest and when it is
owned by nobody, so **a bundle's own record cannot answer who owns it**; every
consumer scans all seven session files to find out. Two bundles are null and in
no manifest, which is either an orphan or an unrecorded owner and the data does
not say which.

A session's end is carried by `ended.on` **and** `declaredState`, and `ended` is
always present as an object. The allocator's first version tested `if ended:` and
saw zero live sessions out of seven. That is a one-line bug and it is the shape
of bug two homes for one fact will keep producing.

## 3. What follows, and what does not

**None of this blocks the tooling.** `bin/plan-findings-work.sh` runs today and
its output is honest about what it could not use — the empty cohesion term is
printed on every allocation.

The gaps divide by who can close them:

| Gap | Closed by |
|---|---|
| 1, edges | sessions asserting them as they read. No schema change |
| 2, `updatedAt` | the generator stamping it on every status move |
| 3, 4 | a schema addition: a severity rank beside the prose, `writeCategory` beside `scope` |
| 5, readiness | a schema addition, and a decision about what its values are |
| 6, session length | the session recording its own, which nothing does yet |
| 7, 8 | a decision, then a retrofit. `0047` is the inventory |

**The order matters and only one is urgent.** Gap 1 needs no schema change and
unlocks the most; gaps 3 to 6 are schema work that should land together rather
than one field at a time; gaps 7 and 8 are `0047`'s retrofit and wait on it.

## 4. What this record deliberately does not do

It proposes no schema. `state-as-data.md` owns that shape and a second document
proposing fields for it would be two homes for one fact, which is the defect the
whole migration was undertaken to remove. **This record names what is missing and
measures it; the fields belong in the schema, and the decisions belong in
`0043` and `0047`.**
