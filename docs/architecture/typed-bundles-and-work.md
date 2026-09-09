# Typed bundles, and work as an object

**Written:** 2026-09-08, `allocation-and-inquiry-design-20260906-233205`, from the  
owner's observation that there is nowhere to put a task.  
**Scope:** the bundle as a genus rather than one thing; the two shapes it takes;  
and why breadth is the property the whole structure exists to protect.  
**Status:** **a draft to be worked, not a design to be built.** Sections 2 and 3  
are firm; 4 onward are sketched and named so a successor can argue with them.

---

## 1. Three origins, one vehicle

Work in this repository starts in three places. Only one of them has somewhere to live.

| Origin | What it is | What it gets today |
|---|---|---|
| an **inquiry** | something exists — what is true about it | a findings bundle, a lifecycle, an owner, an index row, a checker |
| an **intent to build** | something does not exist and should | a markdown file in `docs/ideas/`. No status, no owner, no lifecycle |
| a **blueprint** | what an intent to build settled on | **nothing** — and it is a commission's product, not its own origin |

All three produce the same thing — a change — and two of the three have to
disguise themselves as the first to get a vehicle. The evidence is in the tree:
`state-as-data.md` is a design, and the four revisions that built it were carried
by `0043`, a bundle about a *problem*. `transferring-part-of-a-bundle.md` ends
with *"when it is decided, this record becomes a findings bundle"* — the route
exists, is used once, and is written down nowhere.

**The cost is not tidiness.** A findings bundle's `resolutions.md` is where the
doing goes, so a bundle spans reading, deciding **and** work. That is why its
standing cannot be named cleanly — `concluded` had to be chosen over `answered`
because the object does two jobs. And it is why the allocator costs a session's
load by counting findings and guessing: **work is not modelled, so it cannot be
measured**, which is `0048` arriving from the other direction.

## 2. The bundle is a genus

Everything the structure already knows how to do is generic. A bundle is a
numbered directory that carries:

- **a reason it exists**, written once and never rewritten to match what was later decided;
- **a set of items with individual statuses**, from which the bundle's standing derives;
- **the decisions taken on it, with the alternatives rejected**;
- **a record of what was done**, with the revision and commit that did it;
- **ownership, lineage, and typed edges** to other bundles;
- **one number, from one sequence, never reused.**

None of that is specific to *a reading of something that exists*. The findings
bundle is one **species** of a genus, and the genus is what the checkers,
the allocator, the interviewer, the derivation table and `metadata.json` already implement.

**So the change is smaller than it sounds.** A `kind` field already exists and
already carries four values. What is proposed is that `kind` stops meaning *which
tree* and starts meaning *what sort of bundle this is*, with the tree derived
from it.

## 3. Breadth is the property, and it is already being protected twice

This is the part to build around, because it is why the structure works at all.

**A conversation with an assistant is depth-first.** It plunges, branches,
plunges again. Every turn commits to a path, and the paths not taken evaporate —
not because anyone decided against them, but because nobody wrote them down. What
survives is deep and narrow, and the things lost are exactly the ones a fresh
session most needs: the adjacent problem noticed in passing, the approach
considered and set aside, the reason a scope was drawn where it was.

**The repository already fights this in two places and has never named it.**

- *"A decision without its rejected alternatives is an assertion."* `decisions.md`
  keeps every rejected and refined row **with its section**. That is breadth
  preserved at the moment of choosing.
- *"Finding a second defect while fixing the first is normal; park it as a bundle
  and keep going."* That is breadth preserved at the moment of noticing.

Both are the same rule: **when the work narrows, write down what it narrowed
away from.** Neither is stated as a principle, so neither generalises — and
everything outside a `decisions.md` or a new bundle still evaporates.

**A typed bundle is the general form.** Whatever the type, it carries its
unchosen adjacents: the tasks considered and not taken, the approach rejected,
the scope deliberately excluded, the question raised and deferred. That is what
makes the tree a memory rather than a log — a log records the path taken, and a
memory records the shape of the space the path went through.

**The interviewer makes this urgent rather than optional.** Its whole purpose is
to narrow — one question, the smallest sufficient context, the fastest path to a
decision. Narrowing *is* breadth loss. It is safe only because what it narrows
away is written down as it goes, and that is a property the design asserts and
nothing currently checks.

## 4. Several deciding shapes, one doing shape

### 4.1 The two shapes are the decide/do split, promoted

`findings-and-sessions.md` section 6 calls the distinction between deciding and
doing **"the single most load-bearing distinction in the design and the easiest
to erode under time pressure."** Today it is a convention *inside* one directory
— `decisions.md`, then `resolutions.md` — held by discipline alone.

**Two bundle shapes make it structural.**

| | Carries | Produces | Owned by | Dispatchable |
|---|---|---|---|---|
| **reasoning** | a question, accumulated options, decisions **with their rejected alternatives** | decisions | a session | **no — it decides** |
| **doing** | a spec, a scope with what is excluded, steps, evidence of done | changes | an agent | yes |

They differ in what they need, which is why one object cannot be both. Reasoning
needs **breadth preservation**, because narrowing is its whole activity — section
3. Doing needs **verification**, because its outcome is known in advance and the
only question is whether it happened.

**The dispatch rule then falls out rather than being invented:**

> A doing bundle may be dispatched only when every bundle it `serves` is
> `decided` or later.

It does not matter which reasoning shape it points at: **every** deciding shape
produces decisions, so the rule is one rule however many shapes there come to be.

An agent handed anything else would have to decide something to proceed. **The
two shapes are the boundary between a session and an agent**, and the check is
the boundary made enforceable.

### 4.2 `kind` is flat; `shape` is derived from it

**A task is an item, not a bundle.** A findings bundle holds findings — `F1`,
`F2`, each with its own status. A doing bundle holds **tasks** — `T1`, `T2`, the
same way. That symmetry is what the genus already implements, and putting `task`
at the bundle level broke it.

So the doing side needs no separate type field: **the kind is the type.**

| `kind` | Shape | Items | Starts from |
|---|---|---|---|
| `findings` | reasoning | findings `F1..Fn` | **something that exists** — *what is true about it* |
| `commission` | reasoning | questions `Q1..Qn` | **an intent to build** — *we want X; what shape should it take* |
| `implement` | doing | tasks `T1..Tn` | a decision — *this was settled; build it* |
| `refactor` | doing | tasks `T1..Tn` | a decision — *same behaviour, different shape* |
| `retrofit` | doing | tasks `T1..Tn` | a rule — *bring existing records onto it* |
| `bugfix` | doing | tasks `T1..Tn` | a finding — *this is wrong; correct it* |
| `verify` | doing | tasks `T1..Tn` | a claim — *show it holds* |

**One flat, extensible list.** A project registers a kind with its shape, its item
noun and — for doing kinds — whether an agent may take it. A kind nobody
registered is a defect the checker names, the same discipline as an asserted edge.

### 4.3 Why deciding shapes multiply and the doing shape does not

**Doing is uniform in structure and varied in content.** `refactor`, `retrofit`
and `verify` differ in *what* they do and need identical things *recorded* — a
spec, a scope with its exclusions, tasks, evidence of done. Different kinds, one
shape.

**Reasoning is varied in structure, and the line is backward against forward.**
A `findings` bundle looks at something that exists: its fields are *where this is
felt* and *what it costs to leave*. A `commission` looks at something that does
not exist yet: its fields are *the goal* and *the constraints it must hold*.
Neither set can be written for the other, which is what the admission rule asks
for.

**Research belongs under `findings`, not `commission`.** An investigation is a
reading of something that exists — the fact that it may conclude *and it is fine*
rather than *and it is wrong* is content, not shape. The tree already works this
way: `0036` F1 was established by testing whether `verify-doc-paths` reads
`docs/`, which is research, recorded as a finding, and it fit. **A commission is
when you want to build something.**

**`docs/legend.md` is already on this side** — *"a findings bundle is a reading of
something that already exists"* — and the first draft of this record narrowed it
to *"and is wrong"*, which is what pushed research into the wrong box. What the
legend may owe is a sentence saying a finding can record a fact established as
well as a defect found, and that *what it costs to leave* is severity's business
and not every finding's. **That is a change to a rule and is owed a finding, not
a quiet edit here.**

**There are two reasoning kinds, and the first draft of this section said
three**, making `blueprint` a kind one paragraph after stating the rule that
excludes it. Corrected: a blueprint is a commission's product.

**The genus stays fixed underneath.** A shape varies **only in its reason
document**. Numbering, items carrying statuses, decisions with their rejected
alternatives, ownership, lineage and typed edges are common to every kind, which
is why the checkers, the derivation table and the allocator do not multiply with them.

**A blueprint is what a commission produces**, the way an answer is what a
findings bundle produces. Each reasoning kind terminates at `answered` — the
question was answered — and they differ in the artifact that answer takes:

| Reasoning kind | Terminates at | Produces |
|---|---|---|
| `findings` | `answered` | an answer per finding — a defect explained, or a fact established |
| `commission` | `answered` | a **blueprint**, under `docs/architecture/` |

`state-as-data.md` is a blueprint whose four revisions of work were carried by
`0043`, a findings bundle about a problem, because no commission existed to carry
them. **`charter` is a blueprint subtype** — one that authorizes a programme of
work rather than specifying an artifact, which matters because a charter is what
a run of doing bundles is measured against and a spec is what one is.

**An idea is a commission nobody has opened yet** — open question 6.3.

#### The admission rule, before there is a fourth deciding shape

> **A new reasoning shape must name a field it needs that no existing shape has.**
> If it can be said in an existing shape's schema, it is a `kind` under an
> existing shape at best, and probably nothing.

That keeps section 5's ceremony cost bounded, and disposes of the tempting near
misses: an **audit** and a **research inquiry** are both `findings` — readings of what
exists; an **incident** is a finding with a date; an **RFC** is a blueprint with
fewer options. None carries a
field the others lack.

**Two words are unavailable and it is worth saying why.** `operation` and
`procedure` both carry a specific contested distinction here: `0035` is titled
*"A lineage rename is a procedure, not an operation."* Reusing either as a kind
would collide with a live finding.

### 4.4 How a doing bundle joins its reason

**By an edge, not by nesting.** A retrofit can serve three findings at once and a
single finding can need four tasks — many-to-many, which a nested field cannot
hold and the edge model already can.

The edge is addressed at **item** granularity, like every other edge here, so a
single task can name the exact finding it discharges:

```text
{ "kind": "serves", "from": "0061/T1", "to": "0047/F3",
  "why": "F3 names the three bundles; this task carries the repair",
  "basis": "asserted", "asserted_by": "...", "asserted_on": "..." }
```

One new edge kind. **`serves` points from the doing to the reason**, never the
other way, so a reason is never edited when work is created against it — the same
property that lets a `findings.md` be written once.

### 4.5 An answer is not a hand-off to doing

**`answered` means the question was answered. It does not mean *now build it*.**
Three things can follow, and the draft's first version implied only the second:

| What follows | Edge | Example |
|---|---|---|
| **nothing** | — | the answer was the point. `0025` ends *"the answer is recorded, no code change"* |
| **a doing bundle** | it `serves` this one | a defect explained, then repaired |
| **another reasoning bundle** | this one `evidences` it | research settles what is true, and now there is something worth building |

**The third needs no new edge kind.** `evidences` already means *A's resolution
produces the evidence B needs to be decided*, which is exactly what a research
answer does for a commission:

```text
{ "kind": "evidences", "from": "0052/F3", "to": "0061/Q1",
  "why": "F3 establishes that the parser is the failure point; Q1 asks what replaces it",
  "basis": "asserted", "asserted_by": "...", "asserted_on": "..." }
```

So the graph across kinds is **a directed graph, not a pipeline**. A findings
bundle can evidence a commission; a commission's blueprint can raise findings
against what already exists; a doing bundle's tasks can turn up something that
becomes a finding — which is the park-it rule, already in the instruction set,
now with an edge to record where the parked thing came from.

**This is section 3 arriving at the level of the whole tree.** A linear pipeline
records the path taken. A graph across kinds records the path **and the branches
off it** — the answer that led nowhere, the question raised and deferred, the
build considered and not commissioned. That is the difference between a log and a
memory, and it is why the chain is edges rather than a status that advances.

**One consequence for the allocator.** It currently reasons about findings
bundles. With kinds it reasons about a graph whose nodes have different shapes
and whose `serves` and `evidences` edges cross between them — which changes
nothing about the objective function and everything about what is in the queue.

### 4.6 Where sessions end and agents begin

| | Owns | Answers to | Produces |
|---|---|---|---|
| **owner** | everything | — | direction |
| **session** | reasons — `findings` and `commission` | the owner | decisions |
| **agent** | doing bundles — `implement`, `refactor`, `retrofit`, `bugfix`, `verify` | the session that dispatched it | changes |

**Reporting runs up, and each level filters.** An agent reports to its session;
the session decides what the owner needs to see. `0049` is the caution: a session
under direct supervision composed correctly, applied wrongly, and reported it in
language that read as compliance. A layer of delegation does not reduce that
risk, so **what a session filters out must itself be recorded** — section 3
again, arriving where it matters most.

### 4.7 What this buys the bottleneck

The owner is the constraint and the allocator does not model that. Tasks are what
an agent can actually be handed: `retrofit`, `verify` and `implement` have a
definition of done that a person does not supply per instance.

`docs/ideas/worker-sessions-under-a-managing-session.md` sketches the layer
above. **It cannot be built before a task is an object**, because a manager with
nothing to hand out is a manager of conversations.

**And the allocator stops guessing.** It currently costs a session's load by
counting findings and weighting by write category, because work is not modelled.
With tasks it can cost the actual work — which is `0048` answered from the side
that can actually answer it.

### 4.8 Where `progress` grows

Splitting `progress` from `standing` left the first free to describe the
**reading** while the second describes ownership and lineage. That room is the
point, and three words are already waiting for it:

| Candidate | Says | What it needs first |
|---|---|---|
| **`blocked`** | a `blocks` or `evidences` edge into it is unsatisfied | **nothing — the graph computes this today** |
| `pending` | a change is proposed and awaits the owner | a marker on the proposal — the interviewer's turn, which nothing records |
| `stalled` | nobody has touched this for weeks | `updatedAt`, which the schema has and does not populate — `0043` F8 |
| `halted` | deliberately stopped short of withdrawn | a reason field, and a rule for what resumes it |

**`blocked` is available now and the other three are not.** The allocator's hold
set and the interviewer's feasibility stage both already compute it from
`blocks` and `evidences` edges — twelve of which were asserted at Revision 234 —
and it is currently reported in a run and thrown away rather than written down.
Writing it into `progress` costs one line and makes a bundle say for itself what
the allocator would otherwise have to be run to discover.

**It needs the precedence rule `revisited` has.** A five-finding bundle with one
blocked finding is not blocked; it is being worked. `blocked` fires only when
**every live finding is blocked** — when being blocked is the whole of the live
work — or a reader learns nothing from the word.

**Two of the remaining three become derivable** the day `updatedAt` is stamped,
which makes *noticing silence* — open since `findings-and-sessions.md` section
11.6 — a derivation rather than a scheduled sweep.

**None of them belongs in `standing`.** Standing answers *who owns this and does
the reading still stand*; a stalled reading is still owned and still authoritative.
Keeping them apart is what the split was for.

## 5. What it costs, stated

- **A second lifecycle to keep honest.** The findings lifecycle took thirty
  revisions and four instruments that failed loudly on healthy trees before it
  settled. A second one will not be free because the first exists.
- **`kind` changes meaning**, and every index, manifest and checker reads it.
- **Two numbering questions**: one sequence for all bundles, or one per genus.
  One sequence keeps *bundle 0051* unambiguous, which is the property the single
  sequence was created for.
- **The temptation to route everything through work items**, so that findings
  become tickets and the reading — the thing this repository is *for* — thins out.

## 6. Open questions

**6.1 Does a doing bundle ever hold a decision?** Section 4.1 says no — deciding is the
reasoning shape's job. But a retrofit meets a case its spec did not anticipate,
and something must happen. The likely answer is that it **records the question
and stops**, opening a finding rather than deciding; that needs a name and a
status, and it is the first thing to settle.

**6.2 One sequence or one per genus?** See section 5.

**6.3 Where do ideas land?** An idea is a **commission nobody has opened yet** —
an intent to build, put down and not yet worked. Whether `docs/ideas/` becomes commissions at
`pending`, or stays a holding area for questions not yet worth a number, is the
open part. Four files sit there with no status between them.

**6.4 What checks breadth?** Section 3 makes it the load-bearing property and
nothing verifies it. A candidate: an interviewer turn that narrowed the option
space must have written down what it eliminated, and a `check` that fails when a
decision has no rejected alternatives — which would fail today, on purpose.
