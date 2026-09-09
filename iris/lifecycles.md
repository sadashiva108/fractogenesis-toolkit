# Lifecycles — how every value moves

> **Role.** Motion. What event moves a `status`, a `standing`, a `progress` and a
> `state`; which are computed and which are declared; and the order the numbered
> procedures impose on the writes.
>
> **Authoritative for** the transitions and the derivation order. **Not**
> authoritative for what any word *means* — that is
> [vocabulary.md](vocabulary.md), and nothing here restates a definition from it
> — nor for when a write is permitted, which is [procedure.md](procedure.md).
>
> **The tiebreak is the code.** Where this file and
> `.internal/ai-scripts/session-management/plan_findings_work.py` disagree, the
> code is what the record was stamped from and this file is the defect. Every
> count below was measured against the tree on 2026-09-09.

**One rule governs the document.** A status moves on a **material change to the
record**, and a read is not one. The owner ruled on 2026-09-09; it is `0039` D24.

## Contents

- [1. What moves a value, and what does not](#1-what-moves-a-value-and-what-does-not)
- [2. The member lifecycle](#2-the-member-lifecycle)
- [3. What is derived and what is declared](#3-what-is-derived-and-what-is-declared)
- [4. The session lifecycle](#4-the-session-lifecycle)
- [5. The procedures](#5-the-procedures)
- [6. Provenance and the two gates](#6-provenance-and-the-two-gates)
- [7. What is not implemented](#7-what-is-not-implemented)

---

## 1. What moves a value, and what does not

D24 put it as a change of position: *"You can't get into a car, boat, or plane
without your location changing… if it's the same, which would be the case for
read-only, how could there be any force of change?"*

Four operations touch a status cell without a judgement being formed about the
member underneath it, and **none of them moves a value**:

| Operation | What it is | Why it does not move a status |
|---|---|---|
| **assignment** | an owner is named for a bundle | it says who *may* act, not that anyone has |
| **a sweep** | a vocabulary pass over the tree | one edit applied everywhere, formed against no member |
| **a rename** | a slug or a path changes | the reading is identical afterwards |
| **a retrofit** | a schema field is backfilled | the record gains shape, not content |

**Each of the four is a mass operation, and that is the whole argument:** a wrong
one damages every member it passes over. Revision 208 moved twenty-one rows that
way with no judgement formed about any — `0039` F12, and why the rule is written.

**A read fails the same test and one worse: nothing records a read.** A trigger
that leaves no trace can be confirmed by no instrument, so a status that moved on
a read is one no check can defend.

### Two documents still say the opposite

1. **`docs/legend.md`, *Awaiting a first read*** — line 199: *"**Reading is the
   transition**; nothing else moves them"*, with line 194 moving `un-started`,
   `reopened` and `transferred` on the owner's first reading. The file
   contradicts itself twice over: line 69 says *"A status does not move because
   someone read the finding"* and line 546 *"A status moves on a write, not a
   read"*. It answers *what moves a status* twice, in opposite directions.

2. **`.github/session-management-instructions.md` §10** — *"The transfer ends
   when the target session reads the bundle. At that point `transferred` stops
   applying…"* D24 replaces this with the target's **first write to the bundle as
   owner**, which four index rows and two manifests have recorded since Revision
   248. `as owner` is load-bearing: a non-owner contribution is a write and does
   not clear the transfer.

**Neither edit has been made.** D24 is `decided` and deliberately unresolved —
sequenced behind `0039` D23, which rewrites the same paragraphs. The tree is
right and the documents are behind it, which is the cheaper direction.

## 2. The member lifecycle

**Six statuses, eight transitions, and every arrow is an event that changed the
record.** The statuses are defined in
[vocabulary.md § 3](vocabulary.md#3-member-statuses).

```text
           (1) recorded in findings.md
                       │
                       ▼
                  un-started
                       │ (2) first write to the member
                       ▼
  (5) rollback  ┌───▶ framing ◀─────────────────────────┐
  with a reason │       │                               │
                │       │ (3) every decision recorded   │ (7a) reopened with
                │       ▼                               │  decision-wrong,
                └──── decided ◀────────────────┐        │  decision-
                        │                      │        │  inapplicable, or
                        │ (4) resolutions.md   │        │  framing-wrong
                        │     row written      │        │
                        ▼                      │ (7b) reopened with a
                    resolved                   │  resolution-* reason
                        │                      │        │
                        │ (6) reason recorded  │        │
                        ▼                      │        │
                    reopened ──────────────────┴────────┘

  withdrawn ◀── (8) a reason, a note and withdrawn_at,
                    from any status except `resolved`
```

| # | Transition | The event that causes it |
|---:|---|---|
| 1 | *(nothing)* → `un-started` | the member's row is recorded in `findings.md` |
| 2 | `un-started` → `framing` | **the first write to the member.** Not the first read |
| 3 | `framing` → `decided` | every decision is recorded, and the owner closes the deciding |
| 4 | `decided` → `resolved` | the `resolutions.md` row is written — [§5.4](#54-resolving--9b) |
| 5 | `decided` → `framing` | a rollback, with one of the five rollback reasons |
| 6 | `resolved` → `reopened` | a reopen reason, `reopened_at` and the commit SHA are recorded |
| 7a | `reopened` → `framing` | the reason named the **decision** or the **framing** at fault |
| 7b | `reopened` → `decided` | the reason named the **work** at fault — the decision stands |
| 8 | any status but `resolved` → `withdrawn` | a reason, an optional note and `withdrawn_at`, **per member** |

**Arrow 7 is one event with two exits, and the reason picks the exit** — removing
a judgement call at the moment someone is already annoyed about a bug; which
reason routes where is [vocabulary.md § 9](vocabulary.md#9-reasons). `reopened →
decided` is the common case, not a skipped step: routing a sound framing back
through `framing` would assert the problem statement is being reworked.

**Measured today: 191 members across 54 bundles** — 66 `resolved`, 47
`un-started`, 46 `framing`, 32 `decided`, and **zero `reopened`, zero
`withdrawn`.** Arrows 6, 7a, 7b and 8 have never fired here.

## 3. What is derived and what is declared

**Two tables, read in order, first match wins.** `bundle_progress` runs first and
answers the reading alone; `bundle_standing` runs second and puts ownership and
lineage back in. Neither is typed by hand — both are written by
`plan-findings-work.sh stamp` and by nothing else.

### 3.1 The first table — `progress`

`derivation_table(sts)` takes member statuses and returns one of five values — a
**translation between two vocabularies**, not a lookup: the sets share no word,
so a bare value says which layer it came from.

| # | `progress` | Matches when |
|---:|---|---|
| 1 | `untouched` | every member is `un-started` — **and when there are no members at all** |
| 2 | `retired` | every member is `withdrawn` |
| 3 | `answered` | every member is inert, and at least one is `resolved` |
| 4 | `revisited` | at least one member is `reopened`, and every other is inert |
| 5 | `analyzing` | anything else |

**Row 5 is the fallthrough, and that is the hazard:** a derivation bug lands in
`analyzing` looking plausible, because `analyzing` asserts nothing. Order makes
the answer single-valued — rows 2 and 3 both match an all-`withdrawn` bundle, and
`retired` wins because nothing in such a bundle was carried through.

**Measured: `analyzing` 18, `answered` 20, `untouched` 16, `revisited` 0,
`retired` 0** — rows 2 and 4 have never matched.

### 3.2 The second table — `standing`

| # | If | Then `standing` is |
|---:|---|---|
| 1 | `lineage.supersededBy` is set | `superseded` |
| 2 | `ownership` is set | that value — `unclaimed` or `transferred` |
| 3 | `progress` is `untouched` and a session owns it | `assigned` |
| 4 | otherwise | whatever `progress` says |

**Ownership and lineage outrank progress because they are not progress at all.**
An `unclaimed` bundle is closed to everyone whatever its members say; a
`superseded` reading is no longer authoritative whatever it concluded.

**Measured: `unclaimed` 17, `answered` 17, `superseded` 7, `analyzing` 6,
`assigned` 4, `transferred` 3.** The seven superseded bundles sit over three
progress values — `answered` (3), `analyzing` (2), `untouched` (2) — which is row
1 working: supersession reaches a bundle at any standing.

### 3.3 The three declared values, and why each is declared

`unclaimed`, `transferred` and `superseded` are the only bundle values not
computed from the members, because **nothing in the member rows could produce
them.** They are facts about ownership and lineage, and the members have no view
on either.

| Value | Stored in | Why it cannot be derived from members |
|---|---|---|
| `unclaimed` | `ownership` | *nobody owns this* is a fact about the session manifests. A bundle of `un-started` members is `untouched` whether or not anyone holds it |
| `transferred` | `ownership` | it records that a **named** target has not yet written as owner. Two bundles with identical member rows differ only in whether a handover is outstanding |
| `superseded` | `lineage.supersededBy` | a **later bundle** replaced this reading. The evidence lives outside the bundle entirely, and the predecessor is never edited |

**`unclaimed` is declared in `plan_findings_work.py` and derived in
`extract-metadata.py`, and the two are one pipeline.** The extractor scans every
manifest and writes `"ownership": "unclaimed"` into any bundle no live one lists;
`bundle_standing` reads that field. So §10a's *removing the row **is** the
release* holds — but only across a re-extraction. In between, `ORPHAN` catches
the shape, and fires on `0002` and `0004` today.

### 3.4 What `stamp` writes, and what it does not

`stamp_derived` writes exactly three fields: `standing` and `progress` on every
bundle, `state` on every session.

```text
$ ./bin/plan-findings-work.sh stamp --dry-run
STAMP  would write 0 record(s)

  Every derived field already agrees with what it derives from.
```

**Read that as agreement, not as health.** Three stamped fields match what the
stamper derives them from; it claims nothing about the member rows underneath,
and `check` on the same tree reports 43 findings.

**No code path writes a member `status`.** `_rewrite` is reached from two sites,
both inside `stamp_derived`, and neither passes a `status` key — so every one of
the eight arrows in [§2](#2-the-member-lifecycle) is performed by hand.

## 4. The session lifecycle

**Five states. One is declared; the rest follow from what the session owns.**

```text
                                    ┌──▶ handoff   declared — the session
                                    │              says it handed on
  available ───▶ active ────────────┤
  owns nothing   owns at least one  └──▶ closed    every owned bundle is
                 non-terminal bundle                terminal, or released
```

`session_state(g, s)` reads in this order:

| # | If | Then `state` is |
|---:|---|---|
| 1 | `declaredState` is set | that value — **the declaration wins over everything** |
| 2 | `ended.on` is set | `closed` |
| 3 | it owns no bundle | `available` |
| 4 | every owned bundle is terminal | `closed` |
| 5 | otherwise | `active` |

A bundle is terminal when its **standing** is `answered`, `retired` or
`superseded` — so a session's state rests on the second derivation table, and a
member write can close a session without anyone touching it.

**Row 1 is why `handoff` is a declaration.** A handover cannot be derived from
what a session holds: one that passed everything on and one that never held
anything look identical from outside.

**Measured: 11 sessions — 4 `closed`, 3 `active`, 3 `handoff`, 1 `available`.**
All three `handoff` values are declared; the other eight carry a null
`declaredState`. `typed-bundles-architecture` carries both a `handoff`
declaration and an `ended.on` of 2026-09-09 and reads `handoff` — row 1 beating
row 2, the order working.

## 5. The procedures

**Five numbered sections, six procedures** — §9a carries both reopening and
withdrawing. Each exists because the **order** of its writes protects something.

### 5.1 Superseding — §9

A bundle is replaced whole by a later one. **Never a single member: correcting
one resolution is reopening.** It reaches a bundle at any standing, and the
session with the new reading performs it without taking ownership.

1. Take the next free number immediately before writing.
2. Create `<NNNN>-<slug>/` with a `findings.md` carrying the reading forward.
3. The new header carries `**Relates to:** … **supersedes it.**`
4. **Set the predecessor's `lineage` — only after coverage and exclusivity pass.**
5. The predecessor's index status cell becomes a **link** to the new bundle.
6. Add the new bundle's row.
7. Add it to the superseding session's manifest and update counts. The
   originating session's bundle count does **not** change.
8. The new bundle gets no `decisions.md`.
9. One `APPLY-MANIFEST.md` revision covers the whole supersession.

**What the order protects: step 4 after the gates.** A `superseded` tag over an
incomplete accounting is the state nothing can recover from, because the
predecessor may not then be edited to fix it.

### 5.2 Reopening — §9a

1. Record the `reason` — one of the nine. Prose is not a reason.
2. Record an optional `note`.
3. Record `reopened_at`.
4. Record **the commit SHA at reopen time**, with the member, decision and
   resolution ids.
5. Let the reason determine the exit — `decided` or `framing`.

**What the order protects: step 4 makes steps 1 to 3 checkable.** `reopened.md`
is *generated* from those fields against that SHA, never hand-written and never a
copy of the member, decision or resolution — a snapshot is a second copy of a
fact and will drift; a SHA cannot.

### 5.3 Withdrawing — §9a

1. Record a `reason`, an optional `note` and `withdrawn_at` — **per member.**
2. To withdraw a whole bundle, do that for every member in it.

**What the order protects: the per-member requirement keeps bundle `retired`
derived rather than declared**, and makes withdrawing a bundle cost as much
thought as the members in it. A `resolved` member is reopened first.

### 5.4 Resolving — §9b

1. **Carry out the decision** — a toolkit write, gated on the member being
   `decided`.
2. **Write the `resolutions.md` row**: the member, the decision that resolves it,
   what was done, the revision, the commit.
3. **Move the member to `resolved`.**

**What the order protects: the row is the evidence the status asserts, so it is
written before the status moves.** Reversing 2 and 3 produces a `resolved` member
with nothing behind it, which nobody can check — `0037` F5 recorded exactly that
state from the other direction. The procedure exists because it did not: seven
resolutions went unwritten across five revisions. `0039` F17 and D18.

### 5.5 Transferring — §10

One bundle moves between sessions. The target must already exist.

1. Set `ownership` to `transferred` and the index status cell to `transferred`,
   naming the target in the Session column.
2. Remove the row from the outgoing manifest; add it to the target's.
3. Update **both** sessions' counts. The member count does not change.
4. Record it in `metadata.md` on **both** sessions.
5. One `APPLY-MANIFEST.md` revision covers the transfer.

**What the order protects: step 1 before step 2.** Ownership is reconstructed by
scanning manifests, so between removing the outgoing row and adding the target's
the bundle belongs to nobody; writing `transferred` first makes that window read
as a handover in flight rather than as a release.

**The transfer ends on the target's first write to the bundle as owner** — D24.
§10 still says a read ends it; see [§1](#1-what-moves-a-value-and-what-does-not).

**Two documents give the permitted standings in two vocabularies.** §10 allows
`un-started`, `reopened` or `analyzing` — two member statuses and one bundle
progress; `docs/legend.md` says `assigned`, `revisited` or `analyzing`, standing
throughout. The three bundles standing `transferred` are `0043`, `0045`, `0048`.

### 5.6 Releasing to `unclaimed` — §10a

**Four steps, and there is no step for setting the status.**

1. **Remove the bundle's row** from the releasing session's manifest.
2. Set the index row: Session cell to `—`, Status cell to `unclaimed`.
3. Decrement the session's counts.
4. **Record the disposal in the session** — `final-summary.md` on closing, the
   handoff document otherwise — naming each bundle and why.

**What the order protects: step 4 is the only history that survives.** A released
bundle leaves no trace in the session that held it — the manifest row is gone and
the index row names nobody — so the disposal record is where the history goes.
Transfer names a target and the bundle stays owned; release names none, and a
session may not end still holding one (`0039` D20).

## 6. Provenance and the two gates

**When a bundle is superseded, every member of the predecessor is accounted for.**
Provenance is a property of the *relationship*, so it is a typed edge at member
granularity stored in the **new** bundle only — the predecessor is never edited,
so it could not live there. The kinds are in
[vocabulary.md § 8](vocabulary.md#8-edge-kinds). Both gates are enforced in
`provenance()` in `extract-metadata.py`, in this order.

**Coverage.** Every predecessor member is named by **at least one** disposition
edge:

```text
missing = set(old) - covered
if missing: raise SystemExit(f"COVERAGE FAIL {old_num}->{new_num}: unaccounted {sorted(missing)}")
```

**Zero is the real failure.** Not *too few edges*, not *the wrong edge* — a
member named by nothing at all, silently lost in the handover, which the
procedure had no guard against whatsoever. Hence a hard stop, not a report. And
*at least one*, not *exactly one*: a split gives one predecessor member several
edges, a merge gives one successor several sources, and both are ordinary.

**Exclusivity.** A predecessor member disposed `dropped` carries that edge and no
other:

```text
if "dropped" in kinds and len(kinds)>1:
    raise SystemExit(f"EXCLUSIVITY FAIL {t}: dropped alongside {kinds}")
```

Dropped-and-also-carried is the contradiction worth catching — the record would
assert both that a reading came forward and that it did not.

**Where the gates run, and where they do not.** They fire inside the one-way
extraction, against edges the extractor **derives for itself** by comparing
statements — identical → `carried`, changed at the same id → `successor`, no
counterpart → `dropped` — so they gate the run that would introduce the loss.
They never audit stored edges, and `plan-findings-work.sh check` contains no
coverage or exclusivity comparison at all. A hand-authored set is ungated.

**Measured: 59 edges** — `carried` 29, `relates-to` 16, `blocks` 5, `co-decides`
4, `constrains` 3, `successor` 2. **`dropped`, `split` and `merged` stand at
zero**, which follows: the extractor emits three of the five kinds and never the
other two.

## 7. What is not implemented

**Every transition below is described in a document and performed by no code.**

| # | The transition | Described in | What code does |
|---:|---|---|---|
| 1 | **every member status transition** — all eight arrows in [§2](#2-the-member-lifecycle) | `docs/legend.md`; §9–§10a | `_rewrite` is reached only from `stamp_derived`, which passes `standing`, `progress`, `state`. **No code path writes a member `status`** |
| 2 | `un-started` / `reopened` → `framing` **on the owner's first read** | `docs/legend.md` lines 194, 199 | nothing. Retired by D24, and never implemented under either rule |
| 3 | `transferred` cleared when the target reads the bundle | §10 | nothing. D24 replaced it with the first write as owner, which no code detects either. 3 bundles stand `transferred` |
| 4 | the **reason → exit status** mapping, nine reasons | `docs/legend.md` *Reasons*; §9a | the token `reason` does not appear in `plan_findings_work.py`. Neither exit is computed |
| 5 | rollback **voiding** — `framing-changed` voids every accepted decision; `decision-wrong` and `decision-inapplicable` void one | `docs/legend.md` *Rolling a finding back* | no code reads a rollback reason or writes a `voided` outcome |
| 6 | session → `withdrawn` when **every bundle it owns is `withdrawn`** | `docs/legend.md` *Session states*; vocabulary § 6 | `session_state` cannot return `withdrawn` except from `declaredState`. `extract-metadata.py` derives it from the text of `ended.reason` — a different rule, from a different field |
| 7 | withdrawal's **revert obligation** — `git revert` plus an `APPLY-MANIFEST.md` entry naming what was reverted | `docs/legend.md` line 224 | nothing performs or checks it |
| 8 | pointer and reason requirements on outcomes — `deferred` and `replaced → DX` require a pointer, `voided` a reason | `docs/legend.md` *Decision outcomes* | `conformance` matches the word only: `replaced` passes by prefix with no pointer, `voided` with no reason |
| 9 | a study as **a commission at `pending`**, in `atelier/` | `README.md` § 6a | `pending` is in no closed set and nowhere in the code; `atelier/` does not exist. All 54 bundles are genus `findings` — `commission`, `charter` and `remedy` have zero instances |
| 10 | `split` and `merged` provenance edges | `docs/legend.md` *Provenance*; §9 | `provenance()` emits `carried`, `successor` and `dropped` only |
| 11 | coverage and exclusivity **against stored edges** | §9 *Provenance, and the gate on the tag* | gated only inside the extraction, on edges the extractor derives. `check` has no such comparison |

### One transition that is coded and cannot fire

**A hold released when its source bundle finishes.** `holds()` and `frontier()`
guard on `src["_progress"] not in ("resolved", "withdrawn")` — but `_progress`
comes from `derivation_table`, whose values are `untouched`, `retired`,
`answered`, `revisited`, `analyzing`. Neither guard word is reachable, so **the
condition can never be false** and a hold is never released by its source.

The cause is two derivation functions with one job and two vocabularies:
`derive_progress` in `extract-metadata.py` still returns `un-started`,
`withdrawn`, `resolved`, `reopened`, `analyzing` — **member statuses used as
bundle progress**, the collision Revision 233 separated. The identical guard in
that file is live; this one is dead. Same two words, opposite behaviour.

### The honest state of this file

```text
$ ./bin/plan-findings-work.sh check
CONFORMANCE  43 finding(s) across 54 bundles
```

Broken out: `UNCITED-DECISION` 21, `RESOLUTION-AHEAD-OF-FINDING` 11,
`CLOSED-BUNDLE-LIVE-FINDING` 8, `ORPHAN` 2, `DECISION-AHEAD-OF-FINDING` 1.

**Eight of those are one undecided question.** 33 members are live inside bundles
standing `unclaimed` — `0047` F1, which nobody has ruled on: what happens to a
member when its bundle is released. The detector says the rule is undecided
rather than asserting one, the right shape for an unanswered question.

**The lifecycle is written down and walked by hand.** One instrument stamps three
derived fields; one gates provenance during extraction. Everything else here is a
procedure a session follows because it read it.
