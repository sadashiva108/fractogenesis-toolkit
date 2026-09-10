# Shapes — the four genera and what each is for

> **Role.** The shape book. What sorts of dossier exist, what each is for, how
> they connect, and the rule for admitting a fifth.
>
> **Authoritative for** why the genera are what they are. **Not** authoritative
> for what any word means — that is [vocabulary.md](vocabulary.md) — nor for the
> fields — [schema.md](schema.md).
>
> **Status: two of four genera are exercised.** Every dossier in the record today
> is `findings`. `commission`, `charter` and `remedy` are in the schema, in the
> checks and in the tests, and in nothing else. That is said plainly because a
> capability with no instance is a claim.

## Contents

- [1. The map](#1-the-map)
- [2. Why a shape exists at all](#2-why-a-shape-exists-at-all)
- [3. The reasoning genera](#3-the-reasoning-genera)
- [4. The actionable genera](#4-the-actionable-genera)
- [5. The admission rule](#5-the-admission-rule)
- [6. How they connect](#6-how-they-connect)
- [7. Darts and trials](#7-darts-and-trials)
- [8. Worked examples](#8-worked-examples)
- [9. What is not built](#9-what-is-not-built)

---

## 1. The map

```text
                 ┌──────────── reasoning ────────────┐   ┌──── actionable ────┐
                 │                                   │   │                    │
     findings ───┴── commission ──▶ BLUEPRINT ──▶ charter          remedy
     F1..Fn          Q1..Qn         a design      T1..Tn           T1..Tn
     what is         what shape     under         build it         repair it
     true about      should this    architecture/ to the drawing   no drawing
     what exists     take
```

| Genus | Shape | Members | Terminates at | Produces |
|---|---|---|---|---|
| `findings` | reasoning | findings `F1..Fn` | `answered` | an answer per member — a defect explained, **or a fact established** |
| `commission` | reasoning | questions `Q1..Qn` | `answered` | a **blueprint**, under `architecture/` |
| `charter` | actionable | tasks `T1..Tn` | `answered` | changes, conforming to a blueprint |
| `remedy` | actionable | tasks `T1..Tn` | `answered` | changes, repairing what a reasoning dossier found |

**The genus is stored; the shape is derived from it.** Nothing derivable is
stored, and a shape written into a record is ignored in favour of the map.

[&#8593; Contents](#contents)

## 2. Why a shape exists at all

**The two shapes need different things, and that is the whole justification.**

| | reasoning | actionable |
|---|---|---|
| its activity is | **narrowing** — many options to one | **executing** — the outcome is known in advance |
| so it needs | **breadth preservation**: what it narrowed away, written down | **verification**: did it happen |
| the failure it guards | an assertion — a decision with no rejected alternatives | a claim of done with no evidence |
| may it decide | **yes** | see section 4 |

**Reasoning cannot be handed to an agent.** An agent given a question would have
to decide something to proceed, and deciding is the thing a session is for.
**That boundary is what the shapes make structural** rather than a convention
held by discipline: *a doing dossier may be dispatched only when every dossier it
`serves` is `decided` or later.*

**The genus stays fixed underneath.** Numbering, members carrying statuses,
decisions with their rejected alternatives, ownership, lineage and typed edges
are common to all four. **A shape varies only in its reason document** — which is
why the checks, the derivation table, Prism and Lumen do not multiply with them.
Two `resolved` members derive `answered` whether they are findings or tasks, and
a test asserts exactly that.

[&#8593; Contents](#contents)

## 3. The reasoning genera

### `findings` — a reading of something that exists

Its members ask *what is true about this*. It is the commonest genus and the only
one exercised today.

**A finding may record a fact established, not only a defect.** That is `0037`
F8, and it matters more than it sounds: a first draft of the genus model narrowed
the definition to *and is wrong*, which pushed **research** out of `findings` and
into `commission` — a reading of what exists, filed as an intent to build. An
investigation, an audit, a benchmark and a proof-of-concept are all readings of
something that exists. The fact that one concludes *and it is fine* is content,
not shape.

**What it costs to leave is severity's business**, not part of what a finding is.
A reading whose answer is *it holds* has no cost to leave, and a schema that
demands one forces an invented value.

### `commission` — an intent to build

Its members ask *we want X, what shape should it take*. It produces a
**blueprint**: a design document under `architecture/`, which outlives the
commission and is what a charter is later built to.

**A study is a commission nobody has opened yet** — a subject, a reason it was
raised, and the edge saying what threw it off. It carries no members and owes no
defence until someone opens it. **It is a dossier like any other**, in the same
flat space, carrying `progress: pending`; it does not live in a directory of its
own, because a directory that a dossier leaves when its status changes is
location encoding state.

**By-product is the normal origin, not the exception.** Carrying out a closing
throws off an intent that is not the closing. Without somewhere to put it at the
moment of noticing, the intent evaporates — which is lateral context loss, one
layer up from where it usually bites.

[&#8593; Contents](#contents)

## 4. The actionable genera

**Both hold tasks. They differ on three things, and the third is a permission** —
which is why they are two genera rather than one with a flag, since a nullable
field cannot carry a permission.

| | `charter` | `remedy` |
|---|---|---|
| measured against | a **blueprint that exists outside it** and outlives it | its own reason — the finding *is* the spec |
| authorized by | **a separate act**: someone rules that this may be built | dispatch; nothing further |
| task ordering | a **plan** — the foundation precedes the roof | independent, any order |
| **may amend what it builds from** | **yes**, back through the commission | **no** — it opens a finding and stops |

### `charter` — build it, to that drawing

**A charter is the authorization and the programme at once**, which is how the
word works everywhere else: a corporate charter creates the corporation, a
charter school *is* the school. The instrument that authorizes also enumerates
what it authorizes, and `T1..Tn` is that enumeration.

**The amendment route is what makes it a shape.** Building from a design reliably
discovers the design is wrong at the point where stopping costs more than
amending. A charter may take that decision and record it back against the
commission. **A `remedy` may not** — and its inability to decide is exactly what
makes it safe to hand to an agent end to end.

**Two amendment directions, and they are different.** Hitting a pipe inside a
wall is a **finding** raised against reality. Discovering the drawing is wrong is
an **amendment** raised against the commission. Only the second reopens deciding.

**Descoping is breadth loss, and a charter must keep what it dropped.** Work goes
over budget and tasks are cut. A cut task that simply vanishes leaves a building
that does not match its drawings and no record of why. So a descoped task is
`withdrawn` **with a reason**, kept in place, exactly as a rejected decision keeps
its row. *(The reason vocabulary has no constraint reasons yet — no
`out-of-budget`, no `out-of-time`. Section 9.)*

### `remedy` — repair it

`bugfix`, `refactor`, `retrofit`, tech debt. Its reason document *is* its spec,
its done-ness is local and per task, and it decides nothing.

**`verify` is deliberately not here.** A verification produces **evidence**, not
changes, and actionable dossiers produce changes. Since `0037` F8 makes *a fact
established* a legitimate finding, a verification is a reading of something that
exists whose answer is *and it holds* — so it is a `findings` dossier, and the
actionable side loses a kind it never needed.

[&#8593; Contents](#contents)

## 5. The admission rule

> **A new shape must name a field it needs that no existing shape has.** If it
> can be said in an existing shape's schema, it is a kind under an existing
> shape at best, and probably nothing.

That keeps the cost of a fifth genus bounded, and it disposes of the tempting
near misses: an **audit** and a **research inquiry** are `findings`; an
**incident** is a finding with a date; an **RFC** is a blueprint with fewer
options; a **POC** is a finding whose method is to build something disposable.
None carries a field the others lack.

**`charter` and `remedy` pass it**, and it is worth being precise about how. Three
of their four differences are fields — a blueprint pointer, an authorization, an
intra-dossier task order. **The fourth is a permission**, and permission
differences are already what the framework treats as structural: it is the same
test that separates reasoning from actionable in the first place.

**Two words are unavailable and it is worth saying why.** `operation` and
`procedure` both carry a contested distinction here — `0035` is titled *a lineage
rename is a procedure, not an operation* — so reusing either would collide with a
live reading.

[&#8593; Contents](#contents)

## 6. How they connect

**A directed graph, not a pipeline.** Three things can follow an answer, and the
draft that started this model implied only the second:

| What follows | Edge | Example |
|---|---|---|
| **nothing** | — | the answer was the point |
| **an actionable dossier** | it `serves` this one | a defect explained, then repaired |
| **another reasoning dossier** | this one `evidences` it | research settles what is true, and now there is something worth building |

**`serves` points from the doing to the reason, never the other way**, so a
reason is never edited when work is created against it — the same property that
lets a reading be written once.

**Edges are addressed at member granularity**, so one task can name the exact
finding it discharges and a retrofit can serve three findings at once.

**This is breadth preservation at the level of the whole record.** A linear
pipeline records the path taken. A graph across genera records the path **and the
branches off it** — the answer that led nowhere, the question deferred, the build
considered and not commissioned. That is the difference between a log and a
memory.

[&#8593; Contents](#contents)

## 7. Darts and trials

**Generate wide, then narrow, and keep the misses.** The ceremony belongs to the
decision, not to the option — ten candidates cost ten rows in one dossier, not
ten dossiers.

- **A dart is a `proposed` decision.** Ten options, nine ending `rejected`, each
  addressable as `D1..D10`.
- **A trial is a `findings` dossier** — a reading whose answer is a fact
  established.
- **It held** → an `evidences` edge to that decision. **It broke** →
  `contradicts`.

**So confidence is countable.** *Last one standing* stops being a feeling: the
survivor carries N `evidences` edges, the fallen name what killed them, and a
decision whose alternatives were rejected on argument alone is visibly weaker
than one whose alternatives were killed by a trial. **Two quality bars where
there was one** — breadth, and tested breadth.

**A dossier may be deliberately rough, and nothing says so today.** A commission
whose questions are all `framing` and whose options are one-liners is a
legitimate state, not an unfinished one. `framing` reads as *not there yet*
rather than *deliberately open*, and there is no firmness marker to say which.

[&#8593; Contents](#contents)

## 8. Worked examples

**Charter-shaped** — a blueprint exists, ordering is load-bearing, amendment is
expected:

| | The blueprint | The foundation that cannot come second |
|---|---|---|
| the `metadata.json` migration | `state-as-data.md` §9 | step 2 regenerates and diffs; step 4 commits *before anything depends on the JSON* |
| the tag removal | §11.2 | the derivation was compared against all 54 tags **before** one was deleted, and the comparison forced two corrections mid-pour |
| the relocation | `the-collection-and-the-project.md` | seven live-navigation files must be repaired **in the same revision** as the move, or citations resolve to nothing in between |

**Remedy-shaped** — the finding is the whole spec, done-ness is local:
`0047` F7 (a closed set the documents moved past — done when the check stops
misreporting) · `0049` F7 (`git add -N` against the empty blob — done when a
`find` returns zero) · `0037` F4 (one sentence removed).

**The borderline case, and it sharpens the rule.** `0039` D23 has explicit
ordering — *instruction set, then conformant prompt, then session prompt, one
revision each* — and 23 sites to change. **It is still a remedy.** No blueprint
exists: D23 *is* the spec, and it lives in the dossier. **Ordering alone does not
make a charter; the blueprint does**, because only a document outside the dossier
is a thing that can be amended.

[&#8593; Contents](#contents)

## 9. What is not built

Stated because the rest of this document reads as though it were.

- **No commission, charter or remedy exists.** All 54 dossiers are `findings`.
- **A trial has been recorded once and no more.** The instance counts for
  `evidences` and `contradicts` are in [status.md](status.md) section 2, which
  measures them; **this section deliberately no longer carries the number.** It
  said *both stand at zero* and was overtaken on 2026-09-10 by an `evidences`
  edge asserted at Revision 287 — a hand-carried count in exactly the class
  `status.md` exists to retire. Section 7 still describes machinery that has
  barely run.
- **`serves` is not an edge kind yet.** Section 6 names it; the closed set does
  not contain it, and there is no closed set of edge kinds at all.
- **No authorization field exists**, so *authorized as a separate act* is a rule
  with nothing to record it. `progress: pending` is the candidate marker and is
  not implemented.
- **No task ordering exists.** Edges run between dossiers; there is nothing for
  ordering members within one.
- **No constraint reasons exist** — the reason vocabulary is about correctness,
  and descoping under budget or time has no word.
- **And nothing validates a reason at all**, in any vocabulary. See
  [vocabulary.md](vocabulary.md) section 13.

[&#8593; Contents](#contents)
