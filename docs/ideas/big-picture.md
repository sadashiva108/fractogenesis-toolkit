
# Big Picture

I want to step back and see the "Big Picture" this isn't an idea as such but more of clarifying what we have, asking if it's what we want, and saying what needs to change and what's missing.

## Architecture Review (Audit what we know today and what still stands, and decide what we want to change, and document what is missing)

A. Review what IRIS does. What it is purpose and why do we care?
B. Identify named layers in IRIS design (each of these layers may be listed as a focus group below)
   I use layer instead of component because it's about system behavior not what it's comprised of. 
C. Identify the scope of each layer.
D. Identify the responsibilities of each layer.
E. Do any layers overlap? If so how so? Map out these layer interactions.
F. Are there any mutually exclusive layers? Is it independent of changes in the design of another layer?
E. What layers are missing?

---

### What a layer is

**A layer is a behaviour of the running system.** Remove it and the system
behaves differently — a value that was refused is accepted, a figure that was
derived must be typed, a session that was skipped gets work.

**A document is a description of a layer.** Remove it and only a reader is worse
off; nothing the system does changes.

The distinction is not pedantry, and the first pass of this review got it wrong.
It listed `vocabulary.md`, `schema.md` and `lifecycles.md` as layers. They are
documents. The Vocabulary *layer* is the nine closed sets in
`plan_findings_work.py` and the guard that holds them disjoint. Three documents
describe it; one file is it.

**The test that separates them: delete the file and ask what breaks.** Delete
`vocabulary.md` and every check still passes. Delete `VOCABULARIES` and the
disjointness guard stops existing.

### The five categories that are not layers

Everything in the tree that is not a layer falls in one of these. Each has been
mistaken for a layer at least once.

| category | what it is | examples | why it is not a layer |
|---|---|---|---|
| **Law** | normative text — what must be true, who may do what | `iris/rules.md`, `instructions`, `docs/legend.md` definitions | deleting it changes what a person is *obliged* to do, not what any script does |
| **Cartography** | where things are and what they are called | `iris/directory-reference.md`, `docs/INDEX.md` | a map of the territory, not part of it |
| **Measurement** | a reading taken at a moment | `iris/status.md`, `docs/ledgers/*`, `check` output | true when written, never re-derived |
| **Production** | what running the system emits | patches, revisions, `APPLY-MANIFEST.md`, session records, handoffs | output at runtime, input to nothing at runtime |
| **Orientation** | why any of this exists | `iris/README.md`, `iris/why.md` | argument, not mechanism |

**Law is the one worth dwelling on**, because it is the category that keeps
getting promoted. `rules.md` reads exactly like a layer: it is normative, it is
about behaviour, and violating it is a defect. But it is the **input to** two
layers — Permission and Verification — and it is not either of them. The gap
between *the rule exists* and *something enforces it* is where most of this
review's findings live, and collapsing Law into a layer is what hides that gap.

**Production is the home for build artifacts**, which the Versioned Layers group
below is really about. A revision, a manifest entry, a session record and a
handoff are all Production, and that group's question — *what gets versioning* —
is separable from every layer.

### A. What IRIS does, and why we care

IRIS records **why a decision was made, by whom, against what evidence, and what
was done about it** — and then makes that record answer questions no one thought
to ask when it was written.

The reason to care is narrow, and it is not documentation for its own sake.
Design-rationale capture has one famous failure mode, the **capture bottleneck**:
the cost falls on the author and the benefit on a future reader, so nobody pays.
**An assistant inverts that exactly.** It is the author, capture is nearly free,
and the reader who benefits most is another assistant starting with no memory at
all. That inversion is the whole bet, and it is why the record is data rather
than prose wherever it can be.

### B, C, D. The layers — scope, responsibility, and what is behind each

*Measured at `f48a17c`, Revision 313.*

#### 1. Vocabulary — the closed sets, and the rule that no word means two things

- **Scope:** nine named vocabularies in `VOCABULARIES`; `DECLARED_OVERLAPS`
  licenses the two intersections the design intends.
- **Responsibility:** refuse a value that is not in a set; refuse a value in two
  sets that nothing licensed.
- **Behind it:** `VOCABULARIES` (9 entries), `undeclared_overlaps()`, and the
  disjointness test, which has run with nothing excused since Revision 273.
- **Reading: built, and the only layer here that is finished.**

**One gap inside it.** The file holds several named subsets of a vocabulary.
Four of them are **bands** — a band being a named subset of one *disposition's*
values that classifies a **record by its condition**:

| constant | band of | carries the word |
|---|---|---|
| `INERT` = `resolved` · `withdrawn` | `status` | yes |
| `TERMINAL` = `answered` · `retired` · `superseded` | `standing` | yes |
| `ASSIGNABLE` = `available` · `active` | `state` | yes |
| `RE_READING` = `un-started` · `framing` | `status` | **no** |

`RE_READING` is a band and does not carry the word. Its two values share one
property — **no judgement has been recorded for this member yet** — which is the
exact complement of `INERT`, *no work remains*. **Proposed name: `UNJUDGED`**,
after the tree's own phrase at Revision 273: *"moving every member awaiting a
first read in one operation with no judgement formed about any."*

**Two constants are not bands, for two different reasons.**

- `HARD` is a subset of **edge kind**, which is not a disposition. It is a
  *subset*, the generic construct of which a band is one case.
- `DECLARABLE` = `handoff` · `dissolved` · `closed` **is** a subset of `state`'s
  values, so the definition as first written admits it. It should not be a band:
  it classifies a **write by who may make it**, not a record by its condition.
  **And it does not need a name at all.** Once the disposition triple exists it
  is a constraint on `{value, by}` pairs, stated where it belongs:

  ```
  by: declaration  →  value ∈ {handoff, dissolved, closed}
  by: crossing     →  value ∈ {available, active, closed}
  ```

  That is the same fact, in the Act layer, as a rule about provenance rather than
  as a named set in the Vocabulary layer. **It is an argument for the disposition
  triple, not a naming problem.**

#### 2. Record — the stored facts

- **Scope:** 53 `metadata.json` files — 57 dossiers and 12 sessions — plus 94
  markdown files carrying findings, decisions and resolutions.
- **Responsibility:** hold what was found, decided and done, so that nothing
  derivable is typed.
- **Behind it:** `Graph.__init__` reads `docs/*-findings/**/metadata.json` and
  `docs/sessions/*/metadata.json`. **Nothing else.**
- **Reading: built, and split.**

**The split is the finding.** Every derivation in the system runs off 53 JSON
files. **The 94 markdown files feed no derivation at all** — three shell checkers
read them as tables, and that is the extent of it. Half the record is reasoning
that only a reader can use.

#### 3. Units of Work — what sort of thing this is, and what may be dispatched

- **Scope:** the genera, the categories above them, and the rule for when work
  may be handed to an agent.
- **Responsibility:** keep the category out of the record — it is derived from
  genus and never stored — and make the decide/do boundary enforceable rather
  than conventional.
- **Behind it:** `GENERA` (4), `SHAPE`, `MEMBER_PREFIX`, `shape()`, and the three
  checkers corrected at Revision 303 to match `[FQT]` rather than `F`.
- **Reading: the derivation is built; the layer is not.** No `serves` edge exists,
  no actionable unit has ever been created, and the dispatch rule is prose.

This layer has its own focus group below, because it is the largest single body
of design in the tree with no code behind it.

#### 4. Derivation — the values nobody types

- **Scope:** member statuses → dossier `progress` and `standing`; owned dossiers
  → session `state`.
- **Responsibility:** one home per computed value, and a stamp that writes it.
- **Behind it:** `derivation_table()`, `dossier_standing()`, `dossier_progress()`,
  `session_state()`, `dossier_is_terminal()`, `stamp_derived()`.
- **Reading: built, and correct as of Revision 313 — but it runs only when
  someone remembers.**

**`stamp` has no automated caller anywhere in the tree.** Its only invoker is
`bin/plan-findings-work.sh`, which a person runs. Every derived value in the
record is as current as the last time a human thought to refresh it. *Where and
when it should be called is a design decision, listed under Design Strategy
rather than settled here.*

#### 5. Act — a transition happens and something knows

- **Scope:** every change in a `status`, `standing`, `progress` or `state`.
- **Responsibility:** emit the transition, so that a check can bind to it and a
  permission can be tested at it.
- **Behind it:** nothing executes.
- **Reading: specified at Revision 313, unbuilt.**

Before Revision 313 the layer was absent and unnamed. It now has **a vocabulary**
— `crossing` (a derivation produced it, silent) and `declaration` (an actor
produced it, self-announcing) — and **a record shape**, the disposition triple
`{value, by, on}` below.

Measured against the tree: `crossing` and `declaration` appear in **three
docstring lines and one document.** **Zero code branches on either. Zero records
carry a `by` field.**

**And Revision 313 contains the layer's exhibit.** `live_sessions()` tested
`ended.on` and `declaredState` — two of the five inputs `session_state()` uses. A
session that closed **by crossing** — every owned dossier terminal, no latch set,
no declaration made — stayed in the assignment pool while reading `closed`. The
fix computes all five inputs, which is right, and which removes **this instance
and not the class.** Nothing announced the crossing; a reader that sampled the
wrong inputs could not have learned of it; the next reader that samples
differently fails the same way.

#### 6. Permission — who may write what

- **Scope:** the four write categories — `record`, `toolkit`, `evidence`,
  `foreign` — and the gate that a toolkit or evidence write waits on a `decided`
  member.
- **Responsibility:** refuse a write that is not authorized.
- **Behind it:** `.claude/hooks/write-location-guard.sh` (PreToolUse, **denies**);
  `session-guard.sh` and `runbook-guard.sh` (PostToolUse, report). `WC` exists in
  `plan_findings_work.py` and is a **cost weight**, not a gate.
- **Reading: one real gate, bound to the wrong act and to one assistant. The
  category data underneath is weaker than it looks.**

**Act-bound machinery exists and this review previously said it did not.**
`write-location-guard.sh` genuinely refuses a write into the owner's checkout,
and two PostToolUse hooks fire on every Edit/Write and name the governing rule.
**But the act they observe is *an agent edited a file*; the act IRIS needs
observed is *a member's status moved*.** And all three live in `.claude/`, so
they protect one assistant and no other actor.

Three measurements on the category data:

- **`writeCategory` appears in zero records** and in exactly one architecture
  document. No dossier carries an authorization block.
- The category is derived by **substring match against a free-prose `scope`
  field** — `write_category()` looks for `"check"`, `"script"`, `"instruction"`
  and eight more inside a sentence a human wrote.
- **12 of 41 dossiers have `scope: null`, and all 12 land on `record`** — the
  cheapest and least-gated class. Two-thirds of that class is assigned by absence
  of data rather than by a statement.

#### 7. Verification — is the tree still consistent

- **Scope:** five checks in the dispatcher table (four in `all`, one
  report-only), plus `verify-doc-paths.sh`, `verify-doc-currency.sh`,
  `verify-manifest-coverage.sh`, `check-metadata-completeness.py`, and a 77-test
  suite.
- **Responsibility:** report a disagreement between a projection and its source.
- **Reading: built, the broadest layer after Vocabulary, and unable to fail.**

**Every subcommand of `plan_findings_work.py` exits 0** — `check` with 26
findings standing, and `stamp --dry-run` whether it would write 0 records or 50.

#### 8. Allocation — who gets which work, and which question is worth the owner's turn

- **Scope:** the same graph, selected over twice for two different actors.
- **Behind it:** `cost()`, `holds()`, `allocate()`, `assignable_sessions()`,
  `rank()`, `DEFAULT_CAPACITY`, `NEW_SESSION_SETUP`.
- **Two named instruments:**
  - **Prism** — `plan-findings-work.sh allocate`. Groups the queue and proposes
    an assignment to a session. **It proposes; it never assigns** — it opens no
    file for writing on any allocation path, so approving a proposal is one owner
    decision instead of seventeen.
  - **Lumen** — `plan-findings-work.sh ask`. Selects the single question worth the
    owner's turn, from a frontier it filters and says what it dropped.
- **Reading: Prism is built and reading a pool with no clock. Lumen is a frontier
  filter with a score attached, and the parts that would make it an interview are
  absent.**

**The asymmetry is the point, and Prism's own document states it:** *"The scarce
resource here is not compute — the whole search finishes in forty milliseconds
over fifty-four bundles — it is the owner's attention."* Prism schedules
**session capacity**. Lumen schedules **owner attention**. By Prism's own argument
Lumen governs the actual bottleneck, and Lumen is the far less built of the two.

**Prism, measured.** Four assignable sessions today, last writing **2026-09-13,
09-10, 09-09 and 09-08**. Prism would hand new work to a session that has not
written in five days, and **nothing in the data says so**, because `state`
carries no date. That is not an allocator defect; it is the History absence seen
from here.

**Lumen, measured against its own `§6` table: 13 of 14 design elements have no
code.** Three fail on absent schema rather than absent logic — `readiness` is on
**0 of 232** members, `severity` on **0 of 232**, and staleness is captured as
`updatedAt` and never read. A run today shows the consequence:

```
NEXT QUESTION
  0039/F11  score 26.10 (gate 0.5, blast 8, toolkit)
  runners-up: 0039/F18  26.10 · 0039/F21  26.10 · 0039/F22  26.10
```

**Four candidates at an identical score.** The tiebreak Lumen `§5` designs —
write category, then blast, then severity — is unbuilt, and two of its three keys
are fields that do not exist. The run reports a four-way tie in the shape of an
answer.

**And one line of Lumen's table belongs to the Act layer:** *"Interview writes
`decisions.md` as a by-product"* — designed at `§5.2`; `ask` **writes nothing at
all**. The interview is meant to be the moment a decision and its rejected
alternatives get recorded, and it is precisely the moment nothing is emitted.

#### 9. Placement — where a record lives, and whether a citation resolves

- **Scope:** directory shape, citation targets, and which documents go stale when
  which sources change.
- **Responsibility:** make a rename detectable and a dangling citation loud.
- **Behind it:** `verify-doc-paths.sh`, and `doc-currency.json` — **7 watches, 17
  sources, 15 dependents, 4 critical.**
- **Reading: built, narrow, and honest about being narrow.** Every currency edge
  is asserted rather than inferred, which is correct: an entry nobody wrote does
  not exist, and that is the right failure.

### E. Where the layers overlap

**Derivation × Permission — `instructions §9b` is one numbered list that is two
layers.** It says carry out, write the row, move the status, and then refresh the
projections. Steps one to three are Permission; step four is Derivation. Step
four had to be **hand-written into the list** at Revision 302 because nothing
refreshes a projection when a status moves. **A layer boundary that has to be
maintained by prose is a boundary two layers are sharing.**

**Record × Placement — the standing derivation is stated in six live documents.**

- Full numbered tables: `docs/legend.md`, `iris/lifecycles.md`, `iris/vocabulary.md`
- Partial statements: `iris/prism.md`, `iris/schema.md`,
  `.github/ai-prompts/session-management/conformant-prompt.md`

One rule, six places, and `derivation_table()` is the seventh and the only one
that runs. Revision 299 deleted a fourth *code* copy for exactly this reason; the
document copies were left.

**Vocabulary × Act — the transition vocabulary has no layer to be enforced by.**
`crossing` and `declaration` are well-defined words that no closed set contains
and no check tests, because the layer they describe does not execute.

**Verification × Act — every check is *eventually*** because there is no act to
be *during* or *immediately after*.

**Allocation × Units of Work — Prism costs work it cannot see.** It weights a
session's load by counting members and applying a write-category multiplier,
**because work is not modelled.** That is `0048` arriving from the other
direction.

### F. What is independent of what

| layer | depends on | is depended on by | changeable alone? |
|---|---|---|---|
| Vocabulary | nothing | everything | **yes** — change a value, move the sets and their guard, done |
| Record | Vocabulary | Derivation, Verification, Allocation | no |
| Units of Work | Vocabulary, Record, Permission | Allocation | no |
| Derivation | Record, Vocabulary | Allocation, Verification | no |
| **Act** | Record | Permission, Verification, Units of Work | **yes — nothing downstream exists yet** |
| Permission | Act, Law | Units of Work | blocked on Act |
| Verification | all of the above | nothing | no |
| Allocation | Derivation, Record, Units of Work | nothing | **yes — pure consumer** |
| Placement | Cartography | nothing | **yes** |

**Three things fall out of this table.**

**Act is buildable now.** It depends only on Record, and the things that would
depend on it — Permission enforcement, act-bound checks, the dispatch rule — do
not exist to be broken. There is no sequencing argument for waiting.

**Allocation and Placement are pure consumers.** Neither is upstream of anything.
Work in either can proceed in parallel with everything else and cannot block it.

**And one apparent cycle is not one.** `vocabulary.md` and `procedure.md` cite
each other, which reads as circular. It is not: one citation is a disclaimer
saying *the other document owns this*. **A link is not a dependency.** The
document graph has hubs, not cycles — `docs/legend.md` at in-degree 16,
`.github/session-management-instructions.md` and `iris/vocabulary.md` at 12 each.

### E (second). What layers are missing

**Act — one absence behind four separately-recorded symptoms.**

Each of these was recorded as its own problem, and they are one problem:

1. Nothing emits *`0047` F13 moved `framing` → `resolved`*. The change is
   visible; the event is not; the reason is in prose.
2. Projections drift and no instrument finds it. Five projections disagreed with
   their source across 613 rows; **not one was found by an instrument.**
3. Permissions are unenforceable at the record level, because a permission has to
   be tested **at** an act and the only acts observed are file writes.
4. `instructions §9b` needed a hand-written step 4, because nothing refreshes a
   projection when a status moves.

Three focus groups below are faces of this layer:

- **Detection** is the Act layer emitting.
- **Transitions** is the Act layer's vocabulary.
- **Notification** — *who knows when a transition occurs* — is the Act layer's
  fan-out, and it cannot be designed before the emit exists.

Naming them separately makes it look like three programmes of work. It is one.

**History — no disposition records when it moved.**

- 118 of 232 member statuses have no date, and `updatedAt` is the wrong field.
- 0 of 57 dossier standings have one; no field exists.
- 0 of 14 supersessions have one; the field exists and was never written.
- 0 of 12 session states have one; no field exists.

The consequence is not abstract: it is why Prism cannot tell a session that wrote
today from one that last wrote five days ago, and why `iris/prism.md` already
records that *a bundle untouched for three weeks and one opened this morning are
indistinguishable.* The `on` in the disposition triple is this layer; it is
specified below and not built.

**Permission is not missing, it is bound to the wrong act.** Distinguishing those
matters for what to do next. Act needs designing and building. Permission needs
re-binding, and cannot start until Act does.

---

## Focus Groups (May change depending on what comes out of the Design Review)

### Documentation: 

All `IRIS` system layers require documentation.
We need to discuss what is meant by `documentation` and what types exist or need to exist.
How and when to create new documentation or modify existing and by whom or what process?
Adhere to `single source of truth` where possible.
How do we avoid documentation drift?
`System Documentation` shouldn't lag the system.
`Ideation Documentaton` is ahead of the system and is only in potential. Numerous idea candidates may be proposed but many will be rejected or not acted upon. An accepted idea candidate becomes a commission.
`Commission Documentation` is ahead of the system and is eventual but ammendable. 
`Blueprint Documentation` bridges the gap from current state to future state. It is more technical than commission documentation and closes the gap between current IRIS and future IRIS and how to go from current to future. It's the implementation instructions for how to build it.
`Charter Documentation` is the authorization to build and the set of blueprints at that point in time will be capture as a version. 
`Change Request Documentation` realistically there will be changes to the system or even a proposed design or even the blueprints for implementing that design. Change Requests need to be documented, but where, when and how? A vocabulary needs to be established.
- Amendments to Blueprints
- Amendments during the Implementation or Build
- Amendments to the existing system - Is it a commission or something else?

### Units of Work — the third layer, and the one with no code behind it

*Promoted from `docs/architecture/typed-bundles-and-work.md` (2026-09-08,
`allocation-and-inquiry-design`), which marks itself **a draft to be worked, not
a design to be built** and is still the only recorded design. Restated here so
the commission argues with one source.*

**Work in this repository starts in three places, and only one has somewhere to live.**

| origin | what it is | what it gets today |
|---|---|---|
| an **inquiry** | something exists — what is true about it | a dossier, a lifecycle, an owner, an index row, a checker |
| an **intent to build** | something does not exist and should | a markdown file in `docs/ideas/`. No disposition, no owner, no lifecycle |
| a **blueprint** | what an intent to build settled on | **nothing** — it is a commission's product and has no home |

**The cost is not tidiness.** `state-as-data.md` is a blueprint, and the four
revisions that built it were carried by `0043` — a dossier about a *problem* —
because no commission existed to carry them. **Two of the three origins disguise
themselves as the first in order to get a vehicle.**

#### Breadth is the property the whole structure exists to protect

> A conversation with an assistant is depth-first. It plunges, branches, plunges
> again. Every turn commits to a path, and the paths not taken evaporate — not
> because anyone decided against them, but because nobody wrote them down.

The repository fights this in two places and has never named it as one rule:

- *"A decision without its rejected alternatives is an assertion."* — breadth
  preserved at the moment of **choosing**.
- *"Finding a second defect while fixing the first is normal; park it and keep
  going."* — breadth preserved at the moment of **noticing**.

**Both are the same rule: when the work narrows, write down what it narrowed away
from.** Neither is stated as a principle, so neither generalises, and nothing
checks either.

**Lumen makes this urgent rather than optional.** Its whole purpose is to narrow
— one question, the smallest sufficient context, the fastest path to a decision.
**Narrowing is breadth loss.** It is safe only if what it narrows away is written
down as it goes. The interviewer and the breadth rule therefore cannot be built
in either order: an interviewer that narrows without recording what it eliminated
converts a memory into a log, one question at a time.

#### The categories, and the three namings in play

There are **two kinds of work unit** and, by the owner's reading, **a session is
a third**. The name for the category itself is open; `shape` is retired.

| category | genera | members | produces |
|---|---|---|---|
| **Reasonables** | `findings`, `commission` | `F1..Fn`, `Q1..Qn` | decisions — and for a commission, a blueprint |
| **Actionables** | `charter`, `remedy` | `T1..Tn` | changes |
| **Session** | — | — | decisions, and accountability for them |

**Three namings are live for the first two and they disagree:**

| source | names |
|---|---|
| `plan_findings_work.py` `SHAPE` | `reasoning` · `actionable` |
| `typed-bundles-and-work.md §4` | `reasoning` · `doing` |
| owner, current | **`Reasonables` · `Actionables`** |

**And `shape` carries two unrelated senses in the tree** — this category, and the
structure of a JSON object ("the disposition triple's shape"). Both appear on
this page. Settling the category name settles half of that; the other half needs
a different word for record structure.

**The collective name is the harder one.** What all three are *used for*: each is
opened, owned, tracked and closed, and each is what IRIS reports on and allocates
against. They are the units of accountable progress. Candidates, with the tests
each passes:

| candidate | in tree | verdict |
|---|---:|---|
| **`Matter`** | 260, all colloquial | *a thing in hand.* Covers question, work and tenure; legal register, consistent with `dossier`. **Lead candidate.** Cost: unusable as a grep target |
| `Docket` | 2 | reads better as the *collection* than the item |
| `Records` | 2,696 | collides with the write category and with "the record" |
| `Recordables` | 0 | reads as *things that can be recorded* — a decision is recordable and is not one of these |
| `Undertaking` | 0 | accurate, long, and a Reasonable is not quite one |

**Two constraints on the choice.** `member` is already settled for the items
*inside*, so the container name must not read like "item" — that rules out
`unit`, `entry`, `object`. And **Session is the only one of the three that
acts**; the other two are acted upon, so every `-able` form quietly excludes it.
`genus` and the rank above it wait on this decision.

#### The dispatch rule, and why this is a layer

> **An Actionable may be dispatched only when every unit it `serves` is
> `decided` or later.**

That rule is **the boundary between a session and an agent**, made enforceable.
An agent handed anything else would have to decide something to proceed.

**Measured today: none of it exists.** `serves` is not among the tree's edge
kinds — the 79 edges are `relates-to` 31, `carried` 29, `blocks` 7, `constrains`
5, `co-decides` 4, `successor` 2, `evidences` 1. **One commission exists (`0056`)
and is unclaimed. No Actionable has ever been created.** `charter` and `remedy`
are in `GENERA` and have no instances.

**What this layer needs from below.** The dispatch rule is a Permission rule; the
`serves` edge is a Record change; *"every unit it serves is `decided` or later"*
is a Derivation. **It is downstream of Act, Permission and the disposition
triple, and cannot be built first.**

#### The graph is directed, not a pipeline

An answer is not a hand-off to doing. **`answered` means the question was
answered.** Three things can follow:

| what follows | edge | example |
|---|---|---|
| **nothing** | — | the answer was the point. `0025` ends *"the answer is recorded, no code change"* |
| **an Actionable** | it `serves` this one | a defect explained, then repaired |
| **another Reasonable** | this one `evidences` it | research settles what is true, and now there is something worth building |

**A linear pipeline records the path taken. A graph across categories records the
path and the branches off it** — the answer that led nowhere, the question raised
and deferred, the build considered and not commissioned. That is the difference
between a log and a memory.

#### Open, from the source document

- **Does an Actionable ever hold a decision?** The likely answer is that it
  **records the question and stops**, opening a Reasonable rather than deciding.
  That needs a name and a status.
- **One number sequence, or one per genus?**
- **Where do ideas land?** An idea is a commission nobody has opened yet. Whether
  `docs/ideas/` becomes commissions at `pending`, or stays a holding area, is
  open. Seven files sit there with no disposition between them.
- **What checks breadth?** A candidate: a `check` that fails when a decision has
  no rejected alternatives — which would fail today, on purpose.

### Transitions: 
`IRIS` is static without them, they drive the systems' movement.
There can't be transitions without state. 

A. Which layers are dynamic and have state?
B. Which components in that layer hold state?
C. What are their stateful properties and the vocabulary surrounding them?

D. Identify The Transitions
Define a components `transition space` by finding the complete mapping of its dynamic properties and their valid successor values.

E. When Do They Change and Why and by Whom
For each layer, for each component, for each transiton in it's `transition space` define when, why, and by whom does the state change.

F. Privileges
For each layer, for each component, for each possible state, what are its privileges?

G. Notification
Who knows when a transition occurs?
What is the mechanism for notification?
Are there gaps?

### Detection and Verification
`IRIS` verifies documents. It has never verified a record transition.
Verification depends on detection: you cannot check a transition that nothing emits.

**The evidence, measured 2026-09-11.** Five projections disagreed with their source
across 613 rows and **not one was found by an instrument** — two by the owner
reading rows by eye, two by sessions rechecking their own work, one by a session
reading its own table back after being questioned.
`verify-findings-structure.sh` **passed 70 of 70 while a session manifest's copy of
a standing was wrong**, because a session manifest is not on the path it walks. The
check was correct, ran, and reported nothing. It was pointed at a file rather than
at the event *a standing moved*.

#### Detection

A. What is an event here? Today a member moves because someone edits
   `metadata.json`. Nothing emits *`0047` F13 moved `framing` → `resolved`*. The
   change is visible; the event is not; the reason is in prose.
B. `state-as-data.md` §6.1 is already the derivation graph — eleven outputs, one
   row per source, each column's origin named — **and nothing executes it.**
   Measured: **zero generated regions exist in the tree.** Making §6.1 data rather
   than documentation is the cheapest first move on this page, because the design
   exists, the population is known, and only the mechanism is absent.
C. Which invalidations can only be known by the actor, and must be **declared** at
   the moment of the act? Which can be **derived** from the graph in B?
D. Is anything genuinely global besides **staleness at read time** — a session
   holding an old version of a rule? That is `0053`, already recorded.

**On an "all-seeing" entity.** Worth stating the objection early, because IRIS
already has one that does not work: `verify-manifest-coverage.sh` is correct, fires
correctly, and **is executed by nothing** — not in the dispatcher, not in `all`, no
caller in the tree (`0050` F8). A global watcher fails the same way: it must be
invoked, it must know every derivation, and the day it misses one nobody finds out.
The actor knows what it changed; a watcher has to infer it. **Prefer declaration at
the act over inference after it** — which is `0038` D9, and the single lesson that
recurred in five different disguises over two days.

#### Verification

Four positions relative to an act. **Corrected 2026-09-13: two rows previously read
as empty and are not.**

| When | Question | Fails how | Today |
|---|---|---|---|
| **before** | may this actor do this at all? | refuses | **one real gate** — `.claude/hooks/write-location-guard.sh` denies a write into the owner's checkout. Bound to a file path, for one assistant. §6's record-level gates remain discipline only |
| **during** | is the act well-formed? | aborts | nothing |
| **immediately after** | are its consequences complete? | reports | **two PostToolUse hooks** — `session-guard.sh`, `runbook-guard.sh` — fire on every Edit/Write and name the governing rule. **Bound to *a file was written*, not to *a status moved*** |
| **eventually** | is the tree still consistent? | reports | every checker we have |

**So act-bound machinery exists and is bound to the wrong act, for one actor.**
That is a different problem from an absence, and a cheaper one: the pattern is
proven in this tree, and what it lacks is a record-level event to bind to and a
home outside `.claude/`.

E. The remaining gap is the third row *for record transitions*, and every projection
   drift lived in it: the act was legal, the act was well-formed, the tree was
   inconsistent, and the sweep that would notice runs when someone remembers.
F. Which verifications are **atomic to one act** and which are **rollups** over
   derived or aggregate state? A total summed from its rows is a rollup; a standing
   derived from members is atomic to a member move.
G. A guard **refuses** and a checker **reports**. Revision 280 requires a guard to
   be shown both not to fire on correct work **and** to fire on a case it should
   catch. Does that bar apply to an immediately-after check, which reports but is
   bound to an act?
H. What happens when detection is unavailable? **A check that cannot observe its
   event must say so rather than pass.** Every silent pass in this system has cost
   more than a loud failure.
I. **Nothing in `plan_findings_work.py` can fail.** Every subcommand exits 0 —
   `check` with 26 findings standing, `stamp --dry-run` whether it would write 0
   records or 50. Until that changes, neither can be a gate, and the dispatcher's
   `verify` group cannot include them.

#### What to be careful of, from the record

- **A count cannot distinguish a row nobody cleared from a row nobody may clear.**
  Those are opposite signals — one means the framework is failing, the other means
  it is working — and they read identically. `0047` F9, which recurred *inside* the
  ledger built to prevent it.
- **A metric can acquire a vote it should not have.** `0050` F10: writing a correct
  late entry moved `ORPHANED` further from its baseline, so the instrument argued
  against its own repair.
- **The population is never what you think.** `0041` D6 predicted a silent first run
  because both known instances were repaired, was built anyway, and fired on a third
  nobody had counted. **Expect the first run of any detection layer to report
  nothing, and do not read that as working.**
- **A defect invisible in the owner's tree stays invisible.** `0012` D2 was accepted
  2026-09-04 and went uncarried-out for **115 revisions** — an empty untracked
  directory that made ten citations resolve for one person and break for everyone.
  It was found because a figure disagreed between a checkout and a clone.
- **Describing a defect can create one.** Citations of that directory grew from 10
  to 17 across four revisions, because every document written *about* it cited it.

### Dispositions — one record shape for the three, and the fields that are missing

*Settled with the owner 2026-09-11 to 09-13. The vocabulary is approved; the
schema change is not built and needs the migration plan §6 requires.*

#### The vocabulary

| term | means |
|---|---|
| **disposition** | the class: `status` (member) · `standing` (dossier) · `state` (session) |
| **transition** | any change in a disposition |
| **crossing** | a transition a **derivation** produced — silent, must be detected |
| **declaration** | a transition an **actor** produced — self-announcing, carries its obligations inline |
| **band** | a named subset of one disposition's values **that classifies a record by its condition** — not a disposition and not a value |
| **subset** | the generic construct. A band is the disposition-and-condition case; `HARD` is a subset of edge kind and is not a band |

Bands in use: **`inert`** = `resolved` · `withdrawn` (of `status`);
**`terminal`** = `answered` · `retired` · `superseded` (of `standing`);
**`assignable`** = `available` · `active` (of `state`); and **`RE_READING`** =
`un-started` · `framing` (of `status`), **proposed `UNJUDGED`**, which is a band
and does not yet carry the word.

**`un-started` is not inert** — `inert` means *no work remains here* and
`un-started` means *all of it does*; including it would price six dossiers at zero
and drop 31 of 116 open members from the allocator's count.

**`DECLARABLE` is not a band.** It classifies a write by who may make it, not a
record by its condition, and under the shape below it stops being a set at all —
see the Vocabulary layer.

#### The shape

```json
"status":   { "value": "resolved", "by": "declaration", "on": "2026-09-12" }
"standing": { "value": "answered", "by": "crossing",    "on": "2026-09-12" }
"progress": { "value": "answered", "by": "crossing",    "on": "2026-09-12" }
"state":    { "value": "closed",   "by": "crossing",    "on": "2026-09-13" }
```

**Why one field and not two.** `state` was a pure output and `declaredState` a
pure input, which works but reads as clutter — `declaredState` is null in **9 of
12** records. Merging them naively breaks `stamp`: **a field that is both input
and output cannot be safely recomputed**, because nothing can tell a declaration
that must be preserved from a stale derivation that must be corrected. `by`
solves it — `stamp` recomputes where `by` is `crossing` and leaves declarations
alone, which is what the two fields do today, stated instead of inferred from a
null.

**And it makes provenance visible.** Today `state: closed` says nothing about how
it got there. That is exactly why a crossing produced a terminal state with an
empty `ended` block and nothing looked wrong. Under this shape it reads
`by: crossing` and the missing latch is a question anyone would ask.

**`updatedAt` cannot serve as `on`.** It answers *when was this record last
written* and moves when prose is edited. One field cannot answer both questions.

#### Every transition records a date

Including `lineage.on` for supersession and a date for transfer. Measured, the
gap is not confined to supersession:

| | populated | missing |
|---|---:|---|
| member `status` transition date | 114/232 via `updatedAt` | **118 have none**, and the field is wrong anyway |
| dossier `standing` / `progress` date | **0/57** | no field exists |
| `lineage.on` | **0/14** | field exists, never written, both directions |
| session `state` date | **0/12** | no field exists |

**Historical values are recoverable once.** The commit that introduced each value
is findable with `git log -S` over the record, so `on` can be reconstructed at
migration rather than left null or guessed — and recorded, not recomputed on
every read. Where the log is genuinely ambiguous the honest value is null with
the reason beside it.

#### One open question, for the review rather than for here

**`by: declaration` may become the rare case at member level.** Nothing derives a
member status today, but `un-started → framing` looks derivable from a reading
existing, `framing → decided` from an `accepted` decision citing the member, and
`decided → resolved` from a resolution row. If that holds, member status is
mostly crossings and the uniform shape earns itself twice over.

#### Migration

**The full population is 12 sessions + (57 dossiers × 2 dispositions) + 232
members = 358 records**, every one non-conformant the moment the shape changes.
**§6's migration-plan gate fires**, and the plan is a prerequisite rather than a
follow-up. *Corrected 2026-09-13: this paragraph read "~260 records — 12 sessions,
41 dossiers × 2 dispositions, 207 members." Those terms give 301, not 260, and the
population silently excluded `docs/runbook-findings/` — 16 dossiers and 25 members.*

---

### Fields that exist and are never populated

*Measured 2026-09-13 over the **41 non-runbook dossiers and their 207 members**.
`docs/runbook-findings/` — 16 dossiers, 25 members — is excluded, and the
exclusion is a judgement worth ratifying rather than inheriting: a runbook finding
may be a different kind of object, and if it is not, every denominator below rises.*

| record | field | n | reading |
|---|---|---:|---|
| MEMBER | `statusReason` | 0/207 | `0041` F9: a member's disposition lives in prose while the field is null, so `stamp` and every checker read a bare status |
| MEMBER | `reopened` | 0/207 | §9a fully specifies it — nine reasons, exit table, required SHA — and it has never run |
| MEMBER | `withdrawn` | 0/207 | the abandonment path at member level, never used |
| MEMBER | `readiness` | **0/232** | Lumen `§5` stage 1 filters on it. Measured over the whole tree |
| MEMBER | `severity` | **0/232** | Lumen `§5` stage 4's last tiebreak. Measured over the whole tree |
| DOSSIER | `subKind` | 0/41 | the rollup in `runbook-findings/INDEX.md` groups by it |
| DECISION | `voidedReason` | 0/152 | `voided` is in `OUTCOMES` and has never been used |

### Fields with a value and no date

Covered by the disposition triple above, and listed here because they are the
measurement that motivates it: **118 member statuses undated, 0 of 57 dossier
standings, 0 of 14 supersessions, 0 of 12 session states.**

### Partial, where the gap looks like a defect rather than an option

| record | field | filled | note |
|---|---|---:|---|
| RESOLUTION | `commit` | 33/107 | **74 resolutions name no commit**, which §9b requires |
| RESOLUTION | `revision` | 71/107 | 36 name no revision |
| RESOLUTION | `resolvedBy` | 97/107 | 10 resolve against nothing — `0041` D8's dangling-citation rule |
| DECISION | `members` | 131/152 | **21 cite no member** — this is `check`'s standing `UNCITED-DECISION (21)`; the row and the null are one fact |
| DECISION | `answersAsOf` | 39/152 | |
| EDGE | `why` | 50/79 | **29 edges assert a relation and do not say why**; `basis` splits 48 asserted / 31 derived |
| OWNER ROW | `until` | 5/12 | seven open, some of which should be closed |
| OWNER ROW | `environmentNotes` | 4/11 | §8 calls the environment field *not decoration* |
| SESSION | `transcript` | 11/12 | a session URL, not a file. **A saved transcript file exists for 1 of 12** — a different fact, and neither field nor rule asks for one |

**Three of these are already conformance rows rather than unseen gaps.**
`UNCITED-DECISION` *is* the 21 decisions with an empty `members` array — so part
of what reads as missing data is a row nobody has cleared, and part is genuinely
unwatched. Telling those apart is the Detection layer's job and nothing does it
today.

### Provenance — linking a member to what it wrote

**The question this answers, in both directions.** Given `0047` F1, name every
file it changed and where in them. Given a line in a file, name the member that
put it there. **Neither is answerable today.**

#### What exists, measured

A member carries a **singular** `resolution` object with four fields:

```json
"resolution": {
  "resolvedBy": "D10",
  "whatWasDone": "`CLOSED-BUNDLE-LIVE-FINDING` removed; `unclaimed` joins the counted ordering exemptions …",
  "revision": 295,
  "commit": null
}
```

**No path. No line. No realm.** `whatWasDone` is free prose, and `commit` is null
in **74 of 107** resolutions. The link from a member to the world it changed
exists only as a sentence a person has to read and then go looking.

**The nearest existing thing is `contributions`, and it is unshaped.** 24 entries
across 8 of 57 dossiers, carrying **two different key sets** — `session`/`date`/
`contribution` in 21 of them and `from`/`on`/`what` in the rest — and one `date`
field holds *"item 1 of the reading order (`prompt.md:25`)"*, which is not a date.
Nothing checks it. It is the right instinct with no schema under it, and it is the
argument for putting one there.

#### Where it lives: a data file, not a ledger and not prose

**It is a schema-backed JSON file in the dossier directory, beside
`metadata.json`.** Named here `imprints.json`, pending the naming decision below.

**Not `docs/ledgers/`.** A ledger in this tree is **a dated measurement of one
class, repeated** — *"never a verdict, always a value."* This records **one act**,
not a series. Reusing the word would collide the way `charter` and `shape` already
have, and this document's whole argument is that a word meaning two things is a
defect.

**Not prose.** `whatWasDone` is the prose version and it is why nothing can query
provenance today.

**Beside `metadata.json` rather than inside it**, on three measured differences:

| | `metadata.json` | `imprints.json` |
|---|---|---|
| **growth** | bounded by members and decisions | grows with **every act, forever** |
| **read** | loaded for every graph build — 57 dossiers on every `check`, `allocate` and `ask` | read only by provenance queries and audits |
| **write** | rewritten by `stamp` and by hand | **append-only**, written at the act, never edited |

The third is the load-bearing one. **An imprint is evidence of an act; editing one
is falsifying a record** — the same property `findings.md` has, and the reason it
must not share a file with something `stamp` rewrites.

#### The object

One entry per act of writing, naming the member it discharges.

```json
{
  "schemaVersion": 1,
  "dossier": "0043",
  "imprints": [
    {
      "member":       "F7",
      "authorizedBy": "D3",
      "revision":     306,
      "commit":       "c9f586b",
      "recordedBy":   "instruments-and-blind-spots-20260909-220203",
      "writes": [
        { "path":    ".internal/ai-scripts/session-management/tests/test_session_management.py",
          "realm":   "iris",
          "version": "0.4.0",
          "verb":    "modified",
          "range":   [412, 468],
          "anchor":  "class TestDerivationPartition",
          "blob":    "e3f1a9c" }
      ]
    }
  ]
}
```

#### It must be backed by a schema — and it would be the first

**Measured: the tree has no machine-readable schema at all.** `git ls-files` finds
no JSON Schema, no validator, nothing. **All 69 records carry `schemaVersion: 1`**
— a version number for a schema that exists only as prose in `iris/schema.md`,
whose own header says *"the tiebreak is the code."* So `schemaVersion` versions
nothing that can be checked, and `contributions` drifting into two key sets across
eight dossiers is what that costs.

**So this object arrives with a real schema, and that is a precedent rather than a
detail:**

- **a JSON Schema file, committed**, that a validator runs against every
  `imprints.json`
- **`schemaVersion` that actually gates** — a reader that meets a version it does
  not know **refuses rather than guesses**, which is this tree's rule everywhere
  else and is not implemented anywhere
- **closed sets referenced, not restated** — `realm` and `verb` are vocabularies,
  and a schema that re-lists their values becomes the seventh copy of a closed set

**And the schema is the argument for doing `metadata.json` next.** If a validator
exists for one file it costs little to point it at the other, and `schemaVersion:
1` stops being decoration on 69 records.

#### Accessible to verification and audit scripts

The point of a data file is that something other than a person can read it. Three
things the design owes a future checker, none of which is free:

- **A stable location and one loader.** `docs/*-findings/**/imprints.json`, read
  the way `Graph.__init__` reads `metadata.json` — **one home for the read**, so a
  second implementation cannot drift from the first. That is `0050` F11 exactly: a
  fourth copy of `bundle_standing` disagreed with the module for four revisions
  and every run said `FAIL 0`.
- **Queryable both ways from the same store.** *Which files did `0043` F7 write*
  is a lookup. *Which member wrote line 430 of this file* is the reverse index —
  **derived, never stored**, because a stored copy of a derivable fact is `0047`
  F11 arriving in a new place.
- **Checks it makes possible, which is the test of whether the shape is right:**
  a member `resolved` with **no imprint**; an imprint naming a **path that no
  longer exists**; an **anchor that no longer resolves** at its recorded path; a
  `realm: iris` write **from a project session**; a decision `accepted` whose
  members resolved with **nothing written anywhere** — which is `0012` D2's failure
  mode, 115 revisions long, as a query.

#### Line numbers rot, and what makes them survive anyway

**A line range on its own is wrong at the next edit**, and a stale citation is
worse than none because it reads as precise.

**So a range is never stored alone.** Two fields answer two different questions and
neither substitutes for the other:

| field | answers | lifetime |
|---|---|---|
| `range` **+ `commit`** | *what exactly was written, then* | **permanent.** `git show <commit>:<path>` and slice reproduces it forever |
| `anchor` | *where is it now* | resolvable today, may drift — **and the drift is detectable**, which is the point |

**The prerequisite is already measured and already missing.** `commit` is null in
74 of 107 resolutions. **A line number without the commit that pins it is not a
citation, it is a guess.** Filling `commit` is not a nicety attached to this
design; it is what makes the design possible at all.

#### Realm — and the first permission rule with a test behind it

Every write records **`realm`: `project` or `iris`**. Stored, not inferred, for
two reasons.

**One: the same path means different things in two places.** Once IRIS is its own
repository consumed as a versioned release, a relative path resolves against
whichever of the two the session is standing in.

**Two: it makes a rule checkable that is currently a sentence.** *Only work on
IRIS if you are in the IRIS project.* Under this field, a write with
`realm: iris` produced by a session whose checkout is a project is **refused** —
and that would be **the first permission rule in this system with an actual test
behind it.** Every other one is convention, or a hook matching a file path for one
assistant.

**An `iris` write also carries `version`**, because it belongs to a release rather
than to whichever project happened to be open when it was made.

#### What it buys, in this tree's own terms

- **`0012` D2 was accepted and went uncarried-out for 115 revisions**, invisible
  because nothing linked a decision to a file that should have changed. An imprint
  makes ***decided, and nothing was ever written*** a query rather than a thing
  someone eventually notices.
- **`0049` — the patch is named as the deliverable and never defined.** An imprint
  is what a patch *produces*, stated as data instead of as a name.
- **Lumen's `blast` score estimates impact from edges.** With imprints it can read
  what comparable work actually touched.
- **An imprint is a declaration** — produced by the actor, at the moment of the
  act, self-announcing, carrying its obligations inline. That is `0038` D9 exactly:
  *prefer declaration at the act over inference after it.* It belongs to the Act
  layer and is the cheapest first instance of one.

#### Granularity

**One imprint per act; the per-dossier view is the file itself; a per-member view
is derived.** That satisfies *a record for each finding and commission* without a
second store to keep honest.

#### Naming, open

**`imprint`** leads — *what the work left behind*. Alternates: `landing`, `works`,
and the plain `writes`. **Not `ledger`**, for the reason above. Placeholder here,
not a decision.

#### Open

- **An evidence write has no commit to pin to.** The artifact volume is outside
  git. The likely answer is that it pins to the run id and stamp the artifact run
  index already provides — a different permanence guarantee, and it should be named
  as one rather than blurred.
- **A move: one imprint with `verb: moved`, or two?**
- **A deletion's range** is the range in the parent commit, which the design
  supports and should say out loud.
- **What is *not* an imprint.** A decision recorded, an index row moved, a status
  stamped — those are writes *inside* the record, and the record already is that.
  An imprint records a write to something the record does not own. **That line
  needs drawing precisely or the field becomes a changelog.**

### Versioned Layers
APPLY-MANIFEST.md is growing too large and not maintainable in its current state.
Instead, adapt to a rolling manifest that is timestamped with older ones compressed similar to logs.

A. What Gets Versioning and Why
B. What kind of Versions Control for Each Versioned Layer
C. Who Controls Versions
D. Who Detects a Version and for What Purpose?
E. Explore Using Versioning for Drift Prevention

### Where Is Home
`IRIS` is built to be project agnostic so it's system files need to live outside the project that uses it.
However, `IRIS` is not stateless in conjuction with project use, it develops project memory.

A. Where does `IRIS` live?
B. Where does the `memory space` generated by `IRIS` live?
C. Which files in the project need to be added or changed when using `IRIS`?
D. Where does the versioning live?

#### Decided, and what it settles


**The owner's decision, recorded 2026-09-13.** IRIS becomes **its own project**,
started fresh, with some files ported. It is **released under a version**, and a
stable release is what a project consumes. **Work on IRIS happens only in the IRIS
project.**

**That makes the commission's first job the two directory structures** — one for a
freestanding IRIS, one for IRIS resident in a project — because every later
artifact is written into one or the other, and a structure decided late is a
structure everything already written has to be moved into.

#### The census is the port manifest

The four divisions above already sort all 493 files:

| division | files | disposition under the split |
|---|---:|---|
| **IRIS System** | 38 | the candidate set for the new repository |
| **IRIS Workspace** | 288 | stays here, as this project's memory |
| **IRIS AI Files** | 18 | **the ones that need deciding** — assistant-specific, and IRIS's rules currently reach a session only through them |
| **Not IRIS** | 149 | the reimage workflow, untouched |

**That sort is a judgement, not a measurement, and the commission should ratify it
rather than inherit it.** A different reading of *is `bin/record-decision.sh` IRIS
or project* moves files between piles, and this page's own warning applies —
**the population is never what you think.**

#### What the split settles that nothing else could

- **`0053` becomes answerable.** *The rules are versioned and a session's reading
  of them is not.* A project pins an IRIS version; a session's reading is of that
  version. Staleness stops being a global unknowable and becomes a comparison.
- **`0057` largely dissolves.** *The manual measures a tree that has moved* —
  mechanism and measurement separate **by construction** when they live in
  different repositories.
- **`docs/legend.md` in the Workspace is solved by the move, not by a rename.** It
  goes to the IRIS repository because it is System, and the most-cited document in
  the tree stops living in the records directory.
- **`prism.md`, `lumen.md` and `status.md` must split** — mechanism to IRIS,
  figures to the project. Today both instrument manuals carry stale project counts
  inside the System directory.
- **An IRIS upgrade inside a project is itself work**, with its own record and
  possibly a retrofit behind it. **That is an Actionable, and it would be the first
  real use of the category.**

### Generated Files
`IRIS` creates many different types of entities and are required to benefit from its capabilities.

A. What are the various file types and/or bundles that get generated?
C. Audit Reports
D. Checker Reports
E. Version Control Files
F. Architecture
G. Ideas
H. Session Records
I. Reasonables and Actionables

### Rules, Instruction Sets, Prompts, and Instruments
What are these? How do they differ? Who controls their creation and maintenance?
Which ones are part of `IRIS` itself versus `IRIS` project use?

---

## Current-State Census

*Every tracked file under `docs/`, `iris/`, `.github/`, `.claude/`, `.internal/`
and `bin/`. Measured at `f48a17c`, Revision 313. **493 tracked files.** This
section is the commission's starting inventory: it says what exists, where it
belongs, and what does not exist.*

> **Pending: the release patch.** A composed and unapplied patch releases `0041` and
> `0050` to `unclaimed`. Measured by applying it to a scratch checkout of
> `f48a17c`, it moves exactly four figures on this page and nothing else:
> **unclaimed dossiers 18 → 20**, **live members inside them 27 → 48**, unclaimed
> cost **81.2 → 103.6 units**, and session states from *`active` 3 · `available`
> 1* to *`active` 2 · `available` 2*. The **assignable set is the same four
> sessions** either way, `check` holds at 26, and the double-ownership and
> claimed-but-unclaimed counts below are unchanged. The figures here are as at
> Revision 313; that is stated rather than smoothed, because a census whose scope
> is not stated is what the two corrections above were about.

### 1. What division each file belongs to

| division | files | where |
|---:|---:|---|
| **IRIS System** — the framework, project-agnostic | **38** | `iris/` 14 · `.internal/ai-scripts/session-management/` 12 · `bin/` 8 · `docs/rules/` 2 + `docs/legend.md` · `.share/check-manifest-revision.sh` |
| **IRIS Workspace** — this project's records and memory | **288** | `docs/` 286 (findings 183, sessions 71, ledgers 12, architecture 11, ideas 8, INDEX) + 2 `APPLY-MANIFEST` files |
| **IRIS AI Files** — instructions, prompts, templates, hooks | **18** | `.github/` 13 · `.claude/` 5 |
| **Not IRIS** — the Mac reimage workflow | **149** | `bin/` 41 · `.internal/` 56 · runbooks 23 · `references/` 11 · `templates/` 4 · other |

**Five observations that bear on the re-architecture.**

**The System is 38 files — 7.7% of the repository.** Everything else is either
this project's memory or a different system sharing the repo. A project-agnostic
IRIS is a smaller extraction than it looks.

**`docs/legend.md` is System living in Workspace.** It defines the vocabulary —
it is the most-cited document in the tree at in-degree 16 — and it sits in the
records directory. **This is the single worst placement in the census**, and it
is a large part of why the derivation rule ended up restated in six places: the
authority had no obvious home.

**`iris/` is not purely System.** `status.md`, `prism.md` and `lumen.md` carry
this project's measured numbers inside the manual. Both instrument manuals are
dated 2026-09-09 and now stale: Prism states 54 dossiers / 191 members / 59 edges
against today's **57 / 232 / 79**; Lumen states 191 members / 29 askable against
**232 / 47**. Each carries a header saying its figures were measured on a date,
which is honest and does not make them extractable. **Splitting mechanism from
measurement is a precondition of IRIS serving a second project.**

**The AI Files are assistant-specific.** `.claude/hooks/` works for one
assistant; `.github/copilot-instructions.md` for another. Neither is IRIS, and
**IRIS's rules currently reach a session only through them** — including the one
real permission gate the system has.

**The Workspace is 96% of what IRIS holds and 58% of the repository.** Whatever
the re-architecture decides about where IRIS lives, the memory it generates is
the bulk of it, and its shape is the thing most worth getting right.

### 2. Files grouped by layer

| layer | System files behind it | reading |
|---|---|---|
| **Vocabulary** | `plan_findings_work.py` — `VOCABULARIES`, `DECLARED_OVERLAPS`, `undeclared_overlaps` | built. Documented in `legend.md`, `vocabulary.md`, `lifecycles.md`, `schema.md` |
| **Record** | `plan_findings_work.py` `Graph.__init__` | reads **53 `metadata.json`**; the 94 markdown record files feed no derivation |
| **Units of Work** | `GENERA`, `SHAPE`, `MEMBER_PREFIX`, `shape()` · `docs/architecture/typed-bundles-and-work.md` · `iris/shapes.md` | derivation built; layer not. **Two documents, one self-marked a draft. No `serves` edge, no Actionable ever created** |
| **Derivation** | `derivation_table`, `dossier_standing`, `dossier_progress`, `session_state`, `dossier_is_terminal`, `stamp_derived` · `docs/architecture/state-as-data.md` · `iris/lifecycles.md` | built; **no automated caller** |
| **Act** | — | `crossing`/`declaration` in 3 docstring lines and 1 document. **0 code branches, 0 records carry `by`** |
| **Permission** | `.claude/hooks/write-location-guard.sh` (denies) · `session-guard.sh`, `runbook-guard.sh` (report) · `WC` (a cost weight) | one gate, on file location, for one assistant. **`writeCategory` in 0 records** |
| **Verification** | 5 in `bin/verify-session-findings.sh` · `verify-doc-paths.sh` · `verify-doc-currency.sh` · `verify-manifest-coverage.sh` · `check-metadata-completeness.py` · 77-test suite · `iris/verifications.md` | built and broad. **Nothing in `plan_findings_work.py` can fail** |
| **Allocation** | `cost`, `holds`, `allocate`, `assignable_sessions`, `rank` · **`iris/prism.md`** · **`iris/lumen.md`** · `docs/architecture/allocation-and-inquiry.md` (design intent, authoritative over both) | Prism built, no clock. **Lumen 13 of 14 elements unbuilt** |
| **Placement** | `verify-doc-paths.sh` · `doc-currency.json` — 7 watches, 17 sources, 15 dependents · `iris/directory-reference.md` | built, narrow, honest |

### 3. Findings by topic, and what must change for future state

**57 dossiers, 232 members.** Grouped by subject rather than by tree. `ˢ` marks a
superseded dossier retained as evidence.

| topic | dossiers | members | bearing on the re-architecture |
|---|---|---:|---|
| **Framework state as data** | `0043` `0047` `0041` `0050` | 48 | **the core.** Projections, drift, instruments that cannot fire. Tiers 1 and 2 come from here |
| **Instruction set lags its rules** | `0039` `0037` `0053` `0055` `0029ˢ` `0027ˢ` | 49 | the Law category with no currency mechanism |
| **Write boundary & session conduct** | `0038` `0049` `0045` `0051` `0028ˢ` | 28 | Permission, and what a session may declare about itself |
| **Supersession, lineage, citations** | `0030` `0044` `0046` `0052` `0040` `0009ˢ` `0031ˢ` `0032ˢ` | 20 | `lineage.on` is 0/14 in both directions |
| **Reimage-project evidence & run index** | 19 dossiers, `0002`–`0026` range | 19 | **Workspace, not architecture.** Conformance targets for the retrofit, nothing more |
| **Toolkit & script hygiene** | `0006` `0015` `0033` `0054` `0012` `0018` | 14 | mostly Not-IRIS |
| **Allocation & capacity** | `0048` (`transferred`) | 3 | blocked on a clock |
| **Rendering / display** | `0042` | 5 | unclaimed |
| **IRIS manual currency** | `0057`, `0056` (commission, unclaimed) | 8 | the manual measures a tree that has moved |

**Current-state defects the retrofit must clear.** None is reported by any check:

- **`0043` is owned by two sessions at once** — `entity-model-and-vocabulary` and
  `session-management-re-evaluation` (in `handoff`). The handoff never cleared the
  source's `ownedBundles`.
- **8 dossiers are claimed by a session while their standing says `unclaimed`,
  `superseded` or `transferred`** — `0009` `0026` `0027` `0028` `0029` `0031`
  `0032` `0048`.
- **2 dossiers stand `answered` with no session claiming them**; 18 stand
  `unclaimed`, holding 27 live members.
- **21 decisions cite no member**; **74 of 107 resolutions name no commit**;
  **0 of 57 dossier standings carry a date**.
- **26 conformance findings stand, and `check` exits 0.**

### 4. Sessions — current state, and what must change

**12 sessions.** Computed states: `closed` 5, `handoff` 3, `active` 3,
`available` 1.

| defect | measured | future state |
|---|---|---|
| `ended.on` holds the literal string **`"unknown"`** | `restore-apps-outstanding`, `restore-git-phase-11a` | a date, or null with a reason — not a word in a date field |
| a `handoff` with **no successor**, holding **11 dossiers** | `run-index-design-20260901-000000` — flagged four times, never repaired | a declared `handoff` must name its successor |
| a `handoff` that also carries `ended.on` | `typed-bundles-architecture` | declaration and latch both set, and nothing says which wins |
| **no state carries a date** | 0 of 12 | the disposition triple's `on` |
| assignable sessions have no clock | last writes **09-13, 09-10, 09-09, 09-08** | `on` makes staleness derivable, and Prism reads it |
| **the record shape is not a shape** | 4 files to 13; `phase-11b-hydrate-and-bookends` carries per-topic `metadata`/`prompt`/`brief` triples | one declared file set, checked |
| `final-summary.md` present in **5 of 12** | — | required at close, or explicitly optional and recorded as such |
| the `transcript` field holds a **URL**, and a saved transcript file exists for **1 of 12** | field 11/12; `run-index-design` is the null | decide whether the artifact or the pointer is what is owed, and say which in one place |
| an `available` session with no `findings-manifest.md` | `allocation-and-inquiry-design` | the manifest is a projection and should exist from the start |

### 5. Gaps — what does not exist and needs to

**Blueprints.** None of these has a home today:

- **the Act layer** — no blueprint anywhere; the design lives in an `ideas/` file
- **the disposition triple** — same
- **the Units of Work layer** — `typed-bundles-and-work.md` marks itself a draft
  to be worked, and `iris/shapes.md` is a second home for the same material
- **IRIS extraction** — what is System, what is Workspace, and where each lives
  when IRIS serves a second project

**Records:**

- **no commission has ever been worked.** `0056` is the only one and is unclaimed.
  The genus exists in code and has no worked instance
- **no Actionable has ever been created.** `charter` and `remedy` are in `GENERA`
  and unused
- **no `serves` edge exists** — the edge kind the dispatch rule depends on

**Code:**

- a **detector that executes `state-as-data §6.1`** — the derivation graph is
  written and nothing runs it
- **exit codes for `plan_findings_work.py`**, without which `check` and
  `stamp --dry-run` cannot be gates
- a **transition emitter** — the Act layer's first executable
- **permission enforcement bound to a record act** rather than to a file write,
  and living outside `.claude/` so it protects more than one assistant
- **a caller for `verify-manifest-coverage.sh`**, which is correct, fires
  correctly, and is invoked by nothing
- **the three fields Lumen's ranking is designed on and cannot read** —
  `readiness` (0/232), `severity` (0/232), and a staleness input that is not
  `updatedAt`. Two of them are the tiebreak, which is why `ask` returns ties
- **a writing interview.** Lumen `§5.2` designs the interview as the thing that
  produces `decisions.md` with its rejected alternatives; `ask` writes nothing.
  This is the Act layer at the one moment the design most depends on it
- **Prism's `blocked` progress value**, which the units design says the graph
  computes today and throws away

**Documentation and register:**

- **a single machine-readable vocabulary register** — every closed set, its
  values, every document that states them, and every code site that enforces
  them. Today the derivation rule alone is stated in six live documents and no
  index knows it
- **a measurement split for `prism.md`, `lumen.md` and `status.md`** — mechanism
  in the System, figures in the Workspace, so the manual stops going stale as a
  side effect of the tree moving
- **currency watches for `iris/`** — `0054` records that the toolkit's own
  documents have none
- **a definition of what the units collectively are**, and of the rank names
  above `member`

---

## Design Strategy

*The order in which the commission should establish things, and why each tier
waits on the one above. The governing rule throughout: **a thing that later
documents restate must be settled before they are written**, because the cost of
settling late is paid once per restatement. Six copies of one derivation rule is
what not doing this looks like.*

**Migration cost is not a criterion anywhere in this plan.** The changes are
substantial by design; ordering follows dependency, not effort.

### What kind of commission this is

Not a greenfield commission. It starts from a system that is far along, with much
of its design already in place and load-bearing, and re-architects it from the
ground up. **Its inputs are a current-state census and a vocabulary register; its
outputs are blueprints.** That is a distinct commission kind and the vocabulary
has no word for it — worth naming in Tier 0, since `0056` and this one are both
of it.

### Tier 0 — the two structures, then the words. Nothing else may start.

**First job: the directory structure**, both for a freestanding IRIS and for IRIS
resident in a project — the owner's ruling, and the right one, because every later
artifact is written into one of the two and a structure decided late is a structure
everything already written has to be moved into. With it come the **realm boundary**
(`project` versus `iris`, and the rule that IRIS is worked on only in the IRIS
project) and the **release and versioning model**, since a project consumes a
version and a `realm: iris` write belongs to a release rather than to a checkout.
**The census above is the port manifest and is a judgement to ratify, not inherit.**

**Second job: an exhaustive review of every word, not a shortlist.** Including the ones that
will almost certainly hold — `findings`, `status`, `standing`, `state` and their
values. Everything is on the table because the register is the point: the
deliverable is a **current-state vocabulary register** giving, for every closed
set, its values, every document that states it, and every code site that enforces
it.

That register is what makes the future state decidable. It is also what would
have prevented six copies of one derivation rule.

Known undecided, feeding into it:

- the **collective name** for Reasonables, Actionables and Session — `shape` is
  retired, `Matter` leads, and the constraint is that Session *acts* while the
  other two are acted upon
- the **rank names** above `member` — `genus` may hold; `family` is untested and
  depends on the collective name
- **`shape` carries two senses** — the category, and the structure of a JSON
  object. The second needs a different word
- **three live namings** for the two work categories: `reasoning`/`actionable` in
  code, `reasoning`/`doing` in the architecture record, `Reasonables`/`Actionables`
  from the owner
- **`band`** — the second clause is agreed; `RE_READING` needs its name (`UNJUDGED`
  proposed); `subset` proposed as the generic
- **a name for this commission kind**

**And a machine-readable schema, which the tree has never had.** Measured: no JSON
Schema exists anywhere, and **all 69 records carry `schemaVersion: 1`** for a schema
that lives only as prose in `iris/schema.md`, whose own header says the code is the
tiebreak. **`schemaVersion` currently versions nothing checkable**, and
`contributions` drifting into two key sets across eight dossiers is what that costs.
The provenance file arrives with a real one; pointing the same validator at
`metadata.json` is the cheap second step.

Three mechanical items belong here because they unblock instruments that already
exist:

- **rename `bundle_standing()` → `dossier_standing()` and `bundle_progress()` →
  `dossier_progress()`.** `bundle` does not go forward
- **give `plan_findings_work.py` exit codes.** A commission that starts with a
  green suite it cannot trust starts blind
- **fill `resolution.commit`** — null in 74 of 107. It is the pin every line
  reference in the provenance design depends on, and nothing downstream of it can
  be built while it is empty

### Tier 1 — the disposition triple, verifications first

`{value, by, on}` on all four dispositions. **Everything below waits on it:** you
cannot emit a transition you cannot record, enforce a permission you cannot
attribute, or date a history that has no field.

**The order inside this tier is not negotiable, and it inverts the obvious one:**

1. **the shape is decided**
2. **the verifications are written, and shown to fire on a case they should
   catch** — Revision 280's bar, both halves
3. **the retrofit runs**, reconstructing `on` from `git log -S`, and determining
   the missing values as it goes
4. **the verifications run against the result**

The retrofit is where most of the missing values get determined, and that is safe
**only** if something can say when one was determined wrongly. A retrofit of 358
records with nothing to check it against produces a second population of
unverified data.

**§6's migration-plan gate fires here** and the plan is a prerequisite rather
than a follow-up.

### Tier 2 — make `state-as-data §6.1` execute

**The Act layer's first build.** The derivation graph is written, the population
is known, and only the mechanism is absent — the cheapest first move on this
page. Two properties it must have from the start, both learned the hard way here:

- **Expect the first run to report nothing, and do not read that as working.**
  `0041` D6 is the precedent.
- **A check that cannot observe its event must say so rather than pass.**

Also in this tier, because both are emits: **`stamp`'s caller** — the design
question of where and when a derived value is refreshed, now that the detector
half and the writer half are known to be different things — and **Lumen's
interview write**, the decision-and-alternatives record that `§5.2` designs and
`ask` does not produce.

### Tier 3 — two programmes, unblocked, parallel to each other

- **Permission, re-bound.** The hook pattern is proven in this tree; what it lacks
  is a record-level event to bind to and a home outside `.claude/`. Also needs
  `writeCategory` to stop being a substring match against free prose — today 12 of
  41 dossiers reach the least-gated class by having no `scope` at all.
- **Act-bound verification.** The *immediately after* row for record transitions,
  which is where every projection drift lived.

### Tier 4 — Units of Work, and then the consumers

**Units of Work** comes first in this tier because Allocation depends on it: the
dispatch rule is a Permission rule (Tier 3), the `serves` edge is a Record change
(Tier 1), and *"every unit it serves is `decided` or later"* is a Derivation.

Then:

- **Prism gains a clock.** Needs `on`.
- **Prism stops guessing.** Needs work modelled as an object.
- **Lumen gains the fields its ranking is designed on** — `readiness`, `severity`,
  and a real staleness input. All three are Tier 1 schema; the logic is designed
  and the data does not exist.
- **Notification.** Needs the emit.

### Deliberately not in the order

- **A global watcher.** `verify-manifest-coverage.sh` is correct, fires correctly,
  and is invoked by nothing — the failure mode is already in the tree. **Prefer
  declaration at the act over inference after it.**
- **Lumen's precedent entailment and propagation stages.** Both reason over edge
  kinds that are barely populated — `generalises` has **0 edges**, `constrains`
  has 5. They are blocked on a populated graph rather than on a layer, and
  populating that graph is ordinary work no tier gates.
