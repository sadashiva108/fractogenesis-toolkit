
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
`IRIS` verifies documents. It has never verified an event.
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

Four positions relative to an act. `IRIS` has the last one.

| When | Question | Fails how | Today |
|---|---|---|---|
| **before** | may this actor do this at all? | refuses | §6's gates, by discipline only |
| **during** | is the act well-formed? | aborts | nothing |
| **immediately after** | are its consequences complete? | reports | nothing |
| **eventually** | is the tree still consistent? | reports | every checker we have |

E. The gap is the third row, and every projection drift lived in it: the act was
   legal, the act was well-formed, the tree was inconsistent, and the sweep that
   would notice runs when someone remembers.
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

### Dispositions — one shape for the three, and the fields that are missing

*Settled with the owner 2026-09-11 to 09-13. The vocabulary is approved; the
schema change is not built and needs the migration plan §6 requires.*

#### The vocabulary

| term | means |
|---|---|
| **disposition** | the class: `status` (member) · `standing` (dossier) · `state` (session) |
| **transition** | any change in a disposition |
| **crossing** | a transition a **derivation** produced — silent, must be detected |
| **declaration** | a transition an **actor** produced — self-announcing, carries its obligations inline |
| **band** | a named subset of one disposition's values — not a disposition and not a value |

Bands in use: **`inert`** = `resolved` · `withdrawn` (a band of `status`);
**`terminal`** = `answered` · `retired` · `superseded` (of `standing`);
**`assignable`** = `available` · `active` (of `state`). **`un-started` is not
inert** — `inert` means *no work remains here* and `un-started` means *all of it
does*; including it would price six dossiers at zero and drop 31 of 116 open
members from the allocator's count.

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
| member `status` transition date | 114/207 via `updatedAt` | **93 have none**, and the field is wrong anyway |
| dossier `standing` / `progress` date | **0/41** | no field exists |
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

~260 records — 12 sessions, 41 dossiers × 2 dispositions, 207 members — every one
non-conformant the moment the shape changes. **§6's migration-plan gate fires**,
and the plan is a prerequisite rather than a follow-up.

---

### Fields that exist and are never populated

*Measured across the whole tree, 2026-09-13.*

| record | field | n | reading |
|---|---|---:|---|
| MEMBER | `statusReason` | 0/207 | `0041` F9: a member's disposition lives in prose while the field is null, so `stamp` and every checker read a bare status |
| MEMBER | `reopened` | 0/207 | §9a fully specifies it — nine reasons, exit table, required SHA — and it has never run |
| MEMBER | `withdrawn` | 0/207 | the abandonment path at member level, never used |
| DOSSIER | `subKind` | 0/41 | the rollup in `runbook-findings/INDEX.md` groups by it |
| DECISION | `voidedReason` | 0/152 | `voided` is in `OUTCOMES` and has never been used |

### Fields with a value and no date

Covered by the disposition triple above, and listed here because they are the
measurement that motivates it: **93 member statuses undated, 0 of 41 dossier
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
| SESSION | `transcript` | 11/12 | |

**Three of these are already conformance rows rather than unseen gaps.**
`UNCITED-DECISION` *is* the 21 decisions with an empty `members` array — so part
of what reads as missing data is a row nobody has cleared, and part is genuinely
unwatched. Telling those apart is the Detection layer's job and nothing does it
today.

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

### Generated Files
`IRIS` creates many different types of entities and are required to benefit from its capabilities.

A. What are the various file types and/or bundles that get generated?
C. Audit Reports
D. Checker Reports
E. Version Control Files
F. Architecture
G. Ideas
H. Session Bundles
I. Reasonables and Actionables

### Rules, Instruction Sets, Prompts, and Instruments
What are these? How do they differ? Who controls their creation and maintenance?
Which ones are part of `IRIS` itself versus `IRIS` project use?