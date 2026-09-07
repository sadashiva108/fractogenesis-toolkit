# Allocation and inquiry — who works what, and what to ask first

**Written:** 2026-09-06, `allocation-and-inquiry-design-20260906-233205`, from  
two briefs the owner wrote separately and one problem underneath them.  
**Scope:** how `unclaimed` findings bundles are proposed to sessions, and how a  
session decides what to put to the owner next and how much of it to show.  
**Depends on:** `docs/session-management-findings/0043-framework-state-lives-in-documents-not-data/`.  
Written to be readable by someone who has never seen this repository, because  
nothing in it is specific to reimaging a Mac.

---

## 1. The problem

The structure in `findings-and-sessions.md` solved persistence: a reading no
longer evaporates, decisions keep their reasons, and ownership is legible. It
did not solve **throughput**, and two costs have shown up as the tree has grown
past forty bundles.

**Allocation is done by eye.** Eight bundles are `unclaimed` today, holding 26
findings. Which session should get which is answered by whoever is looking, from
whatever they happen to remember. Nothing notices that `0015`, `0036`, `0041`
and `0042` are four readings of one question, and nothing notices that assigning
a bundle whose decisions depend on an unsettled decision elsewhere spends an
irreversible transition on work that cannot proceed.

**Inquiry is done by volume.** A session that has read a bundle presents what it
found: pages of technical detail with several layers of decision folded into one
response. The owner then holds the whole dependency structure in their head
while answering. The failure is not that the detail is wrong — it is that the
detail is *transmitted* rather than *used*, and the cost lands on the one
participant whose attention is scarce.

Both are orderings over the same object. **Allocation partitions a graph of
findings; inquiry traverses it.** One model, two consumers, different objective
functions over identical data. That is the whole architecture.

## 2. Why one model and not two

The two briefs could each be built alone. They would then need the same facts —
which findings depend on which, what a decision costs to get wrong, where a fix
lands — computed twice, by two components, from the same source, and the two
copies would disagree. That is the failure `docs/legend.md` names as *a fact has
one home*, arriving in a new place.

More concretely: the allocator cannot decide what to hold back without knowing
the blocking structure, and the blocking structure is exactly what the
interviewer traverses. Splitting them means the allocator infers dependencies it
does not model, which is what doing it by eye already is.

## 3. The graph

**Nodes are findings, not bundles.** The `F1`/`F2` numbering adopted in Revision
201 is what makes this addressable, and it is the reason this design is possible
now and would not have been six weeks ago.

**Bundles are a hard grouping constraint on the nodes, not the unit of the
model.** This follows the decision recorded in section 12: ownership stays
per-bundle, so the allocator may only emit whole-bundle assignments. Modelling
below that line costs nothing and leaves the option open.

### 3.1 Node attributes

Derived wherever the tree already carries the fact. Asserted only where it
cannot be, because an asserted fact that nothing checks is the defect
`.github/session-management-instructions.md` section 8 warns about.

| Attribute | Source | Values |
|---|---|---|
| `status` | the Findings table | the six finding statuses, `docs/legend.md` |
| `tree` | the bundle's path | `runbook` · `cross-cutting` · `instruction-set` · `session-management` |
| `write_category` | **derived from `Scope:`** | `record` · `toolkit` · `evidence` |
| `blast_radius` | computed | count of documents, scripts and findings a decision here reaches |
| `readiness` | computed, then asserted where it cannot be | `ready` · `needs-check` · `needs-owner-fact` · `blocked` |
| `category` | asserted, closed vocabulary | section 6 |
| `severity` | the `Severity:` field | free text, ranked by the owner |

**`write_category` is the useful one and it already exists.** `docs/legend.md`
grades the three write kinds by how they fail — a record write is edited, a
toolkit write is reverted and re-reviewed, an evidence write *may be
unrecoverable*. That is an irreversibility ranking, already written down, already
agreed. **This architecture introduces no new risk axis; it reads the one the
legend defines.** A decision whose fix is an evidence write is never batched,
never confirm-derived, and always carries its rejected alternatives.

### 3.2 Edges

The tree carries exactly one edge today: `Relates to`, which `docs/legend.md`
defines as *a pointer and nothing more — it creates no ownership, moves no
status, and obliges nobody*. That is correct for what it is and useless for
ordering. Everything below is additive; `Relates to` keeps its meaning and
becomes one kind among ten.

| Kind | Shape | Means | Allocator | Interviewer |
|---|---|---|---|---|
| `blocks` | directed | B cannot be framed sensibly until A is decided | B's bundle is **held** while A is unsettled | B is not askable; A's rank rises by how many it frees |
| `evidences` | directed | A's *resolution* produces the evidence B needs — not merely its decision | B held until A is `resolved` | B not askable; reason given as *awaiting evidence* |
| `generalises` | directed | A is the rule of which B is an instance | prefers co-allocation | **decision lifting** — ask A once, derive B, present as confirm-derived |
| `co-decides` | undirected | one answer settles both | the bundles **must** go to one session | asked once, as a single question, recorded against both |
| `contradicts` | undirected | the two propose incompatible rules | **must** go to one session | asked jointly; the mode forces a choice rather than offering both |
| `duplicates` | undirected | the same finding read twice | never separated | the interviewer proposes withdrawing one instead of asking twice |
| `constrains` | directed | A's answer removes options from B without settling it | prefers co-allocation | drives propagation; B's option set shrinks and may collapse to one |
| `shares-surface` | undirected | both land in the same file or region | cross-session placement carries a **collision cost** | no effect on ordering |
| `relates-to` | undirected | the existing prose pointer | weak preference only | context on request; never ordering |
| `supersedes` | directed | as `docs/legend.md` defines it | terminal, never allocatable | excluded from the queue |

**The four hard ones are `blocks`, `evidences`, `co-decides` and `contradicts`.**
They constrain what is legal. The rest express preference, and a preference that
cannot be satisfied is reported rather than enforced.

**`evidences` is separate from `blocks` on purpose**, and the distinction is the
same one section 6 of `findings-and-sessions.md` calls the most load-bearing in
the design. `blocks` waits for a *decision*; `evidences` waits for the decision
to have been *carried out* and produced something to read. Collapsing them is
how a session asks a question whose answer does not exist yet.

### 3.3 What an edge carries

```text
{
  "kind":        "blocks",
  "from":        "0037/F5",
  "to":          "0041/F1",
  "why":         "one line, in the imperative: why this ordering holds",
  "basis":       "asserted",
  "asserted_by": "<session-bundle-name>",
  "asserted_on": "<YYYY-MM-DD>"
}
```

`basis` is `derived` or `asserted`, and the split matters more than any other
field here. A `derived` edge is recomputed and cannot drift. An **`asserted`
edge is a hand-typed fact, which is the exact category the framework has learned
to distrust**, so three rules apply to it and to nothing else:

- **Both endpoints must resolve**, checked in both directions, the same way
  `verify-findings-headers.sh` already checks that every `F<n>` a decision cites
  exists. An edge to a finding that does not exist is how a graph stops being a
  model and becomes decoration.
- **It names its session and its date.** An assertion nobody signed is an
  assumption.
- **It expires when either endpoint is `resolved` or `withdrawn`**, and the
  expiry is recorded rather than silently dropped, because an edge that outlives
  its reason is worse than no edge.

**Which edges are derivable today**: `shares-surface` from `Scope:` and `Felt
at:`, `relates-to` from the header field, `supersedes` from the status cell,
`duplicates` as a *candidate* from subject similarity — proposed, never
asserted. `blocks`, `evidences`, `generalises`, `co-decides` and `contradicts`
are asserted. That is five of ten, and it is the honest cost of this design.

## 4. The allocator

**It proposes. It never assigns.** `docs/legend.md` is unambiguous — the owner
assigns and a session may not take — so the output is a proposal the owner
approves or edits, and approving it is one decision instead of eight.

### 4.1 Hard constraints

1. A bundle is **held**, not assigned, if any finding in it has an unsatisfied
   `blocks` or `evidences` edge from outside the bundle.
2. Bundles joined by `co-decides`, `contradicts` or `duplicates` across the
   bundle boundary go to one session or are held together.
3. No session exceeds its declared capacity.
4. Terminal bundles are excluded. `transferred` is not re-allocated.

### 4.2 The objective

```text
score = w_keep · Σ intra-session edge weight
      + w_pull · Σ edge weight from a queued bundle to a finding already owned
                 by the session it would be assigned to
      + w_tree · Σ bundles whose tree matches the session's subject
      − w_split · Σ cross-session shares-surface weight
      − w_load  · (max session load − min session load)
      − w_hold  · Σ ready findings inside held bundles
```

**The `pull` term was missing from the first version of this record and was found
by running it.** Revision 211 counted only edges between two *queued* bundles, so
an edge from the queue into work a session already holds — the strongest
allocation signal there is — had no effect at all. In the first run over the real
nine, `0044` was placed with the session owning `0036` **by load-balancing
coincidence**, while the `constrains` edge that actually justifies the placement
scored zero. A right answer for no reason is the failure this design is least
able to notice about itself, and it was caught only because the other session had
put a prediction on the record beforehand. Section 9's ablation is what makes
that repeatable rather than lucky.

Load is **weighted by decision cost, not by finding count**. A bundle of seven
findings that a single precedent settles is lighter than one finding needing an
evidence write, and counting rows would get that backwards.

The last term is the interesting one: it prices the cost of bundle atomicity
directly into the objective, so the allocator prefers arrangements that strand
fewer ready findings — and, more importantly, **records the number it could not
avoid**. See section 8.

### 4.3 Why there is no clever algorithm here

Eight `unclaimed` bundles and three `active` sessions is 3⁸ ≈ 6,561 assignments.
**Exhaustive search, scored, in milliseconds.** Graph partitioning, Louvain
modularity, GAP solvers and LPT bin-packing all apply to this problem and all of
them are unnecessary below roughly forty bundles.

This is worth stating plainly because the temptation runs the other way. The
entire difficulty is in specifying the objective honestly; none of it is in
optimising it. A heuristic here would add a failure mode and buy nothing, and
when the tree does pass forty bundles the swap is one function.

### 4.4 The output is a patch

An assignment is already a fixed mechanical sequence — the tag, the index Status
and Session cells, the `findings-manifest.md` rows, the counts in
`docs/sessions/INDEX.md`. Section 10 of the instruction set specifies it
exactly. The allocator emits that patch and the **hold set** beside it, each
held bundle naming its blocking edge and which of its findings were ready
anyway.

**Every assignment is a status transition, and a status transition is an unlink
plus a create.** Delete permission on the connected folder must be requested
*before* the patch is applied, never after it fails — `0043` finding 1 records
four instances of a bundle left carrying two tags, from exactly this.

## 5. The interviewer

Six stages, in order. Each one exists to remove work before the next.

**1 · Feasibility.** Drop everything not `framing`, everything with an
unsatisfied `blocks` or `evidences` edge, and everything whose `readiness` is
not `ready`. What survives is the frontier. Anything a session cannot honestly
ask is now gone, which is the cheapest reduction available and the one most
often skipped.

**2 · Precedent.** Test the frontier against the standing rules the repository
has already written down. If a finding's answer is entailed by one, **it is not
a question** — it is a proposal with the rule cited, presented for confirmation
and open to challenge. Section 7 lists the precedents.

**3 · Lifting.** Where two or more findings share a `generalises` parent, ask the
parent at the level it is actually decided and derive the children. Concretely,
in the tree today: `0015`, `0036`, `0041` and `0042` are four bundles asking one
question — *what is the checker layer responsible for seeing?* That is one
decision reaching fourteen findings.

**4 · Rank.** Among what is left, choose by **information gain**: the question
whose answer eliminates the most option space across the remaining frontier,
counted through `constrains` and `generalises` edges. Ties break on
`write_category` first — an evidence-write decision outranks a record-write one
at equal gain, because getting it wrong costs more — then `blast_radius`, then
`severity`.

**5 · Mode.** How to ask is computed, not chosen by feel:

| Mode | When | Shape |
|---|---|---|
| confirm-derived | precedent entails it, or the evidence is decisive | "This follows from X. Confirm or challenge." |
| closed choice | two to four live options with real trade-offs | one clause of cost per option |
| binary gate | high gain, genuinely two-valued | one sentence, one fork |
| fact request | `readiness` is `needs-owner-fact` | a question only the owner can answer |
| batch confirm | several findings mechanically entailed by one answer | one stroke, listed |
| deferral | on the frontier but not worth its turn yet | named, not asked |

**Batch confirm is forbidden for `toolkit` and `evidence` write categories.**
Those fail in ways that are expensive and unrecoverable respectively, and a
batch is where an unnoticed one hides.

**6 · Propagate.** After the answer, walk `constrains`, `generalises` and
`co-decides` outward: recompute the option sets, collapse any that now hold one
value, re-rank the frontier. Then show **two or three lines** saying what closed,
what opened and what is now decidable that was not. That block is the whole
answer to *how does this decision affect the rest of the system* — the engine
explores the tree, the owner reads the delta.

### 5.1 The turn budget

One question — or one `co-decides` cluster, which is one question wearing two
numbers. The minimum context needed to answer it, not the reading it came from.
The consequence block. An escape hatch: *show the full reading* · *why this
first* · *defer*.

**The nuance is not lost, it is relocated.** Today precision is preserved by
printing everything; here it is preserved by computing it and printing the
difference. Those produce the same decisions and cost the owner an order of
magnitude less attention.

### 5.2 The transcript is `decisions.md`

The schema already requires each decision to carry the alternatives that were
rejected — *a decision without its rejected alternatives is an assertion*. A
closed-choice question **is** a decision with its alternatives attached, so the
interview writes the record as a by-product rather than as paperwork afterwards.
The `Outcome` column falls out the same way: an option offered and not taken is
`rejected`, an answer that modifies one is `refined → DX`.

This is the single largest saving in the design and it required no new
structure. It was already the shape of the file.

## 6. The decision categories

The closed vocabulary for `category`, derived from the readings actually in the
tree rather than invented. Each carries a **default posture** — what the engine
does before asking anything.

| Category | Default posture |
|---|---|
| vocabulary and naming | precedent: one name, and retire the other explicitly |
| schema and shape | precedent: the schema fixes the vocabulary, not the content |
| status and state semantics | never batched; the ladder is read in order |
| ownership and routing | proposal; the owner assigns |
| sequencing and lifecycle | closed choice; ordering errors are expensive |
| validation coverage | lift first — these findings are usually instances of one rule |
| script defect | confirm-derived where a check demonstrates it |
| portability | precedent: the floor is macOS stock Bash 3.2 and BSD userland |
| artifact policy | **always closed choice with trade-offs, never a passing decision** |
| retrofit versus point-in-time | precedent: retrofit, unless the datum cannot be recreated |
| render fidelity | confirm-derived from the rendered page, never from the source |
| process and permission | closed choice; these are the rules the rest is judged by |

Artifact policy is singled out because the conformant prompt already singles it
out: naming, timestamping, retention and pointer policy are runbook-level
decisions and must never be settled in passing while fixing something else.

## 7. Precedents

A precedent is a rule the repository has already settled, in a form the engine
can apply. Each is cited, and citing it is what makes it challengeable rather
than silent.

| Precedent | Home |
|---|---|
| A fact has one home; a copy only where generated or drift-checked | instruction set §8 |
| Retrofit when a rule changes — except data captured at a point in time | conformant prompt, standing constraints |
| The owner commits; a session never does | instruction set §6 |
| Composition happens in a copy, always, for all three write categories | `docs/legend.md` |
| A reading is written once and never rewritten to match what was decided | instruction set §4 |
| Numbers are never reused and directories never renamed | `findings-and-sessions.md` §4 |
| Fence examples as `text`, never `markdown`; one field, one line, two spaces | instruction set §11 |
| No placeholder ever appears in a record | conformant prompt |
| The portability floor is macOS stock Bash 3.2 and BSD userland | instruction set, `verify-script-portability.sh` |
| No service is put in front of the filesystem | `findings-and-sessions.md` §11 |

**When the owner overrides a precedent, that is the override `docs/legend.md`
already defines**, and it carries the same obligation: the revision says so, and
says what was overridden. The engine records the override against the precedent,
which over time is how a precedent gets found to be wrong.

## 8. Evidence, collected as a by-product

The instruction to build this in came with two conditions: unintrusive, and as
automated as possible. **Nothing here is ever asked of the owner.** No rating,
no confirmation, no extra field in a turn.

**Tier 1 — already recorded, no new capture at all.** The framework's own schema
already holds most of what a revisit needs:

| Metric | Read from |
|---|---|
| reversal rate | `decisions.md` `Outcome` — `rejected`, `refined → DX` |
| rework rate | findings that went `resolved` → `reopened` |
| supersession rate | bundles reaching `superseded` |
| cost to close | the `Revision` span across a bundle's `resolutions.md` |
| ownership churn | `metadata.md` Owners rows |

Every one exists because the framework already demands it. This is the best kind
of instrumentation: it was already there and nobody was reading it.

**Tier 2 — emitted by the engine, two facts only.**

*The hold journal.* Every bundle the allocator declined to assign: the blocking
edge, and **which of its findings were ready anyway**. That last field is the
entire question of whether bundle atomicity is costing anything, measured rather
than estimated.

*The turn record.* Per interview turn: the finding asked, the mode chosen, the
options offered, the answer taken, and which findings had their option space
narrowed by it. Written by the engine at the moment it acts.

**Where it lands.** Tier 2 is a fact about what a session did, so it lives in
that session's bundle — `journal.jsonl`, append-only, beside `metadata.md`. One
fact, one home, owned by the thing that produced it. Tier 1 and Tier 2 roll up
on demand into `docs/ledgers/allocation-evidence.md`, which fits the ledger
contract exactly: re-derived and replaced wholesale, never fixed in place.

**The counter that decides the revisit.** *Held-back ready findings*,
accumulated across allocations — findings that were ready but held because a
sibling in their bundle was blocked. When that number grows, per-finding
ownership is paying for itself and the ledger says so. The decision in section
12 was taken on limited time and an argument; this is what replaces the argument
with a number, without anybody having to remember to look.

## 9. Verification

**Invariants** — cheap, deterministic, run every time. No session holds a held
bundle. No bundle appears in two manifests. Every proposed order is a valid
topological order of the `blocks` and `evidences` edges. Cross-session
`shares-surface` weight is reported, not hidden. Every asserted edge resolves at
both ends. The emitted patch reconciles tag, index row and manifest — the three
places `0043` finding 2 counts 88 hand-typed cells across.

**Backtest.** The tree carries labelled failures: `0009` superseded by `0030`,
seven bundles superseded on 2026-09-06, the Revision 197 defect where four
`resolved` bundles had rows that never moved, and `0001` released undecided with
one finding fully decided and nine never read. Run the engine over the tree as
it stood before each and ask whether its ordering would have surfaced the
question earlier. **This is illustrative and not statistical** — a corpus of
forty-three bundles supports an argument, not a confidence interval, and
reporting it as the latter would be the same error as quoting an `OK` total.

**Ablation.** Turn off propagation, turn off precedents, shuffle the ranking.
The metrics in section 8 should degrade measurably; if they do not, the stage
that did not matter should be removed.

**What none of this checks.** Whether the asserted edges are *true*. A wrong
`blocks` edge produces a confidently wrong ordering and every invariant passes.
That is this design's equivalent of the gap the conformant prompt names — every
check answers whether something is well formed, none answers whether it is
complete — and it is stated here rather than discovered later.

## 10. What this requires of the state format

**This architecture does not specify how the framework stores its state.** That
is `0043`'s subject and the schema belongs with it. What it needs is one thing,
and asking for it now is cheaper than migrating to it later:

**Findings must be addressable and edges must be first-class.** A finding needs
a stable identifier — `<bundle>/F<n>` — and edges need to be typed, directed,
signed and dated records rather than a prose line. The current `Relates to` is a
single field holding a sentence; it cannot express ten kinds, cannot be
validated at both ends, and in at least one bundle it already appears three
times, which the drafts reviewed in `0043` cannot represent at all.

Everything else this design needs, the framework already has.

## 11. Alternatives rejected

| Alternative | Why not |
|---|---|
| Two systems, one per brief | The dependency structure would be computed twice from one source and the copies would disagree. Section 2. |
| Bundles as the graph's nodes | Loses every within-bundle ordering, which is where `0001`'s ten findings actually differ. Costs nothing to model finer. |
| A solver or heuristic partitioner | Unnecessary below ~40 bundles, and adds a failure mode. Section 4.3. |
| Weighting by finding count | A count is not a cost. Seven findings under one precedent are lighter than one evidence write. |
| A service, database or MCP server fronting the tree | Rejected already in `findings-and-sessions.md` §11 and the rejection stands: a session without it could not read the structure at all. |
| Asking the owner to rate answers | Instrumentation that costs attention defeats the thing being instrumented. Section 8 takes only what is already recorded or engine-emitted. |
| Inferring `blocks` edges from text similarity | Produces confident false orderings. Similarity may *propose* a `duplicates` candidate; nothing asserts an ordering edge but a session that signs it. |
| Letting the engine assign | The owner assigns. `docs/legend.md` is unambiguous and the proposal shape costs nothing. |

## 12. The decision this rests on

**Ownership stays per-bundle. The allocator emits whole-bundle assignments
only.** Taken by the owner on 2026-09-06.

The alternative — per-finding ownership, option B of
`docs/architecture/transferring-part-of-a-bundle.md` — has real advantages the
owner has already felt: bundles that will not close because one finding in them
is open, and no way to hand part of a reading to a session better placed for it.
It was not taken now for three reasons, recorded so the revisit is against
reasoning rather than memory:

- **It does not improve detection.** Both options build the same graph over the
  same edges. Per-finding ownership acts more finely on what is found; it does
  not find more. The rework the owner was worried about is governed by edge
  quality, which is identical either way.
- **Its cost is documentation, not code**, and documentation is the expensive
  kind of change here — rule rewrites across `docs/legend.md` and instruction set
  §§4, 9 and 10, a column rename, a checker rule, and a retrofit across every
  existing bundle. All of it must land and be reviewed *before* the allocator
  could use it, where the atomic version can be built while the tree is worked.
- **One piece of it is undesigned.** `transferring-part-of-a-bundle.md` records
  that a bundle whose remaining findings are inert while transferred ones are
  live *has no row that fits* in the ladder. Taking option B now means designing
  that now.

**Nothing here forecloses it.** The graph is finding-level under both; what
changes is one relaxed constraint in section 4.1, the `Finding Ownership` table
the schema already leaves deliberately unbuilt, one column rename in two files,
and a checker rule. Section 8's held-back counter is what says when.

## 13. Open questions

**13.1 Who asserts an edge, and under what permission?** Recording to a
`framing` finding is open to any session, and an edge is a record write, so the
permissive answer follows from the existing rules. But an edge changes what
other sessions are *shown*, which no other record write does. Unresolved.

**13.2 Does the interviewer belong to a session or to the framework?** As
described it is a way of working that any session follows. As implemented it is
a script. The portability test in `findings-and-sessions.md` §11 applies: the
tree must stay readable and workable by a session that has none of this.

**13.3 What happens when the owner answers outside the offered options?** The
common case, and the right one — the option set was incomplete. It should be
recorded as a new decision row rather than forced into an existing one, and the
precedent that generated the options should be marked as having missed.
