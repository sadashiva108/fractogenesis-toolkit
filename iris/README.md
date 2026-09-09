# IRIS — Inquiry, Rationale and Implementation System

***The studies are kept.***

> **Role.** The door. What IRIS is, where it comes from, what it is not, and the
> order to read it in.
>
> **Authoritative for** the lineage in section 3, which has no other home.
> Everywhere else it **points**; where it disagrees with what it points at, the
> other wins.

**IRIS records the reasoning behind work so that it survives the session that did
it** — including the options that were rejected, and why. It is
project-agnostic and meant to be lifted into another repository as-is.

The name pays homage to **IBIS**, the Issue-Based Information System that started
this field in 1970. Each word is load-bearing, and the middle one is the homage:

| | |
|---|---|
| **Inquiry** | the reasoning shape. Both reasoning genera pose questions — a findings bundle asks *what is true about this*, a commission asks *what shape should this take*. The repository already called this inquiry, 108 times, before the name existed |
| **Rationale** | decisions **with their rejected alternatives**. This is the word that names the field, and the thing IBIS existed for |
| **Implementation** | the actionable shape — charter and remedy |
| **System** | IBIS's own last word, kept deliberately |

**Three things the name carries that were not designed in.** An iris is the
aperture that controls how much light gets through, which is the interviewer's
job exactly. An iris identifies you. And Iris was the messenger who carried word
between gods and mortals — which is what a record does between sessions that
never meet.

## Contents

- [1. The problem it is for](#1-the-problem-it-is-for)
- [2. Three objects and one loop](#2-three-objects-and-one-loop)
- [3. Where this comes from](#3-where-this-comes-from)
- [4. The capture bottleneck, and why it is different now](#4-the-capture-bottleneck-and-why-it-is-different-now)
- [5. What engineers will already recognise](#5-what-engineers-will-already-recognise)
- [6. What IRIS is not](#6-what-iris-is-not)
- [6a. The atelier](#6a-the-atelier)
- [7. The documents](#7-the-documents)
- [8. Reading order](#8-reading-order)
- [9. Status](#9-status)
- [10. Provenance — how it got its name](#10-provenance--how-it-got-its-name)

---

## 1. The problem it is for

Working with an assistant on anything larger than one sitting produces a specific
set of failures, and they are the reason this exists.

| The failure | What IRIS does about it |
|---|---|
| **Lateral context is lost.** The path taken survives in the transcript; everything considered and set aside evaporates | A decision keeps its rejected alternatives, and a bundle keeps what it narrowed away from |
| **A rename leaves a broken mess.** Not every reference gets updated, and nothing says which ones were meant to stay | Citation by number rather than by path, plus checks that resolve every documented path and anchor |
| **Instructions are followed halfway, again and again** | The rules have one home each, a stated precedence order, and a check that fails when a document disagrees with the code |
| **"How did I get here?" is not a question version control answers** | Git records what changed. IRIS records what was considered, what was rejected, and why |
| **Several sessions collide** | Compose in a scratch copy, take numbers at apply time, hand over a patch; the person commits |
| **The output is a pile of paper nobody can read later** | A typed, checkable record whose most valuable content — the rejected options — is exactly what nothing else captures |

**The last row is the endgame.** The record is a corpus, not documentation. What
lost, and why, is the highest-value signal in it, and no other artifact in a
working life keeps it.

## 2. Three objects and one loop

| | |
|---|---|
| a **member** | one item — a finding, a question, a task. It carries a `status` |
| a **bundle** | a numbered directory of members that belong together. It carries a `standing`, **derived** from its members and never typed |
| a **session** | a unit of work with an owner. It owns bundles; its `state` derives from what it owns |

**Four genera in two shapes.** `findings` and `commission` are **reasoning** —
they decide. `charter` and `remedy` are **actionable** — they do. The shape is
derived from the genus and never stored.

**The loop.** A session reads something and records members. Any session may
sharpen a `framing` member or write a decision on it. The owning session closes
the deciding, carries it out, records what it did, and only then marks it
resolved — **in that order**, because the record is the evidence the status
asserts.

Full vocabulary in [vocabulary.md](vocabulary.md); the derivations in
[lifecycles.md](lifecycles.md).

## 3. Where this comes from

**The field is called design rationale capture, and it is fifty years old.** Most
people rebuilding it do not know it exists, which is why they rebuild it.

| Work | What it was |
|---|---|
| **IBIS** — Issue-Based Information System | Rittel & Kunz, **1970**. Issues, Positions, Arguments. Built for what Rittel named **wicked problems**, where the reasoning outlives the answer because the answer keeps moving |
| **gIBIS**, **Compendium**, **Dialogue Mapping** | Conklin, 1988 onward. Graphical IBIS; Compendium came out of the Open University and is the closest thing the field produced to a working tool |
| **QOC** — Questions, Options, Criteria | MacLean, Young, Bellotti & Moran, ~1991. **Options are assessed against Criteria.** That is stand-up-candidates-and-test-them, thirty-five years early |
| **DRL** — Decision Representation Language | Lee & Lai. More formal, less used |

**What IRIS takes from each.** From IBIS, that the unit is a question and not a
task. From QOC, that an option is only as good as what it was tested against —
which is why a trial is recorded as a member that `evidences` or `contradicts` a
proposed decision, rather than as a footnote. From the whole tradition, the one
rule none of them enforced: **a decision without its rejected alternatives is an
assertion.**

## 4. The capture bottleneck, and why it is different now

**Design rationale has a famous failure mode and a name for it.** The cost of
capture falls on the author; the benefit falls on a future reader. So nobody
pays, the record thins out, and the field stalled in the 1990s with good models
and no adoption.

**An assistant inverts the economics exactly.**

| | Then | Now |
|---|---|---|
| who writes it | the engineer, by hand, after deciding | the assistant, as it goes |
| what it costs | the thing you do instead of working | close to nothing |
| who reads it | a colleague who may never arrive | **another assistant, with no memory at all** |

The reader who benefits most from design rationale is one that starts every
session knowing nothing. That reader now exists, and turns up several times a
day. **IRIS is design rationale capture at the moment its economics finally
work** — that is the one sentence.

## 5. What engineers will already recognise

| | |
|---|---|
| **ADRs** — Architecture Decision Records | Nygard, 2011; `adr-tools`, MADR, Log4brains. A bundle's decisions are ADRs **with the rejected alternatives made mandatory** — the part ADRs permit and almost nobody writes |
| **RFDs** at Oxide, **RFCs** at Rust, **PEPs** | Oxide is the instructive one: they publish the rejected ones on purpose |
| **Requirements traceability** — DOORS, ReqIF, DO-178C, ISO 26262 | The formal analogue of the edges. *Every requirement covered by at least one test, and zero coverage is the failure* is the same accounting as the supersession gate |
| **W3C PROV** | `carried`, `successor`, `split`, `merged`, `dropped` is a provenance model in the standard sense |
| **Issue trackers** — Jira, Linear, GitHub Issues | They model **work**. They do not model reasoning, and that gap is the hole this fell into |
| **PKM** — Zettelkasten, Obsidian, Roam, Logseq | Networked notes: no lifecycle, no typed edges, no gates, nothing derived |
| **Agent memory and context engineering** | MemGPT/Letta, RAG corpora, the `CLAUDE.md` / `AGENTS.md` convention, editor rules files, and **spec-driven development** — where the spec is durable and code is generated from it. A commission producing a blueprint that a charter builds to **is** spec-driven development with the reasoning kept |

**A currency warning on the last row.** It was written against knowledge current
to **May 2026** and that category moves monthly. Anything in it may have been
superseded; treat it as a pointer to a space, not a survey of it. The four rows
above it are historical and will not move.

## 6. What IRIS is not

- **Not an issue tracker.** Nothing here is assigned to a person with a due date.
  The unit is a question, not a ticket.
- **Not documentation.** Documentation says what is true now. This says what was
  believed, what was decided, and what was rejected — and it is never rewritten
  to match what was later concluded.
- **Not a wiki or a notes graph.** Every value comes from a closed set, every
  derived field is computed and stamped, and a check names it when a display
  drifts from its source.
- **Not a replacement for version control.** Git answers *what did this look like
  before*. IRIS answers *how did we get here, and what did we decide not to do*.
  They are different questions and only one of them has a tool.

## 6a. The atelier

**`atelier/` holds the studies — intents to build that nobody has commissioned
yet.** A file there is a **commission at `pending`**: it has a subject and a
reason it was raised, and it has no owner, no members and no decisions until
someone opens it.

It is named rather than called `ideas/` because *idea* describes everything in
this system and distinguishes nothing. **An atelier keeps its studies** — the
sketches, the approaches set aside, the drawings that were never built — and that
is precisely the class of thing in that directory: work that was thought about,
written down, and deliberately not started. Some of it never will be, and it is
kept anyway.

**The rule that makes it cheap.** A study costs a number, a subject and the edge
saying what raised it. It owes no members, no `decisions.md`, and no defence. It
is `withdrawn` with a reason when it dies, like anything else, and nothing about
it is a backlog item waiting to shame someone.

**It is where a by-product lands.** Work routinely throws off an intent that is
not the work — carrying out a closing produces a commission for something noticed
on the way. Without a home at the moment of noticing, that intent evaporates,
which is section 1's first failure arriving one layer up.

## 7. The documents

| Document | For |
|---|---|
| [vocabulary.md](vocabulary.md) | every status, standing, state, genus, shape, outcome and edge kind. **The vocabulary is not guessable** |
| [lifecycles.md](lifecycles.md) | how each of those moves, what event causes it, and what is derived from what |
| [schema.md](schema.md) | the entities, their fields, and what each field is for |
| [shapes.md](shapes.md) | the shape book — the four genera, what each is for, and the rule for admitting a fifth |
| [procedure.md](procedure.md) | when a write is allowed and in what order. **Section 0 is the working cycle and is not optional** |
| [rules.md](rules.md) | the types and layers of rules, where each lives, and what wins when two disagree |
| [verifications.md](verifications.md) | every check, what it examines, and **what it does not** |
| [prism.md](prism.md) | **Prism**, the allocator — how work is grouped and assigned. A scheduler for the owner's attention |
| [lumen.md](lumen.md) | **Lumen**, the interviewer — how the next question is chosen, and how much context comes with it |
| [why.md](why.md) | the longer answer to *why not just use the assistant directly* |
| [directory-reference.md](directory-reference.md) | what lives where, and why the machinery and the record are separate directories |

## 8. Reading order

1. This file.
2. [vocabulary.md](vocabulary.md) — nothing else parses without it.
3. [procedure.md](procedure.md), section 0 first.
4. The index of the record you are working in.

Then the prompt for your kind of work. A session that has to be told something
not in those files is a finding against them.

## 9. Status

**IRIS is in use and is not finished.** It was extracted from a working
repository rather than designed in advance, so parts of it are load-bearing and
parts are drafts arguing with each other. The documents above say which is which,
and where they do not, that is a defect worth recording.

**The honest summary as of Revision 271:** the reasoning side is real and
running — four genera in the schema, derivations stamped by one instrument,
checks with published baselines. The actionable side exists in data and not yet
in practice, and the two words for it were chosen the day this was written.
IRIS is a working system with an unfinished half, and saying so is cheaper than
discovering it.

## 10. Provenance — how it got its name

**This section exists because the document would otherwise be hypocritical.** It
says a decision without its rejected alternatives is an assertion, and then
asserts a name. So the name carries its own rejected alternatives, and the
strongest of them is recorded in full rather than mentioned.

### Why it gets a name at all

Rationale capture exists (IBIS, QOC, ADRs). Work scheduling exists (trackers).
Question selection exists nowhere in particular. **No system found combines all
three**, and a thing with no category name has to supply its own.

### The counting discipline

A candidate is counted against the tree before it is adopted, because **a term
that already means something here arrives pre-broken.** Measured 2026-09-09:

| Candidate | Existing uses | Verdict |
|---|---:|---|
| `vault` | 280 | unusable |
| `archive` | 130 | unusable |
| `memory` | 119 | unusable — and the word one reaches for first |
| `ledger` | 89 | unusable; already a directory of dated statements |
| `foundry` | 7 | near-clean |
| `iris` | **0** | clean |
| `atelier`, `cartulary`, `muniment`, `loom`, `crucible`, `chantier`, `assay` | **0** each | clean |

`inquiry` stands at 108 uses and that is **reinforcement, not collision**: the
repository already used the word for exactly the thing the acronym's first letter
names.

### The two acronyms not taken

| Considered | Why not |
|---|---|
| **Intent**, Rationale and Implementation System | swaps inquiry for intent. A commission's members are **questions**, so *inquiry* covers both reasoning genera and *intent* covers only one of them |
| **Inquiry-Rooted Information System** | the closest structural echo of *Issue-Based Information System* — and it drops the work side of the model entirely, which is half of what distinguishes this from IBIS |

### The runner-up, and its case

**`atelier` — an architect's studio — was the strongest alternative and lost on
one axis only.**

- It is **register-coherent with the model**, which is drawn from building:
  blueprint, charter, foreman, foundation before roof.
- The Beaux-Arts atelier is **a master with assistants working under one roof on
  commissions** — the owner, sessions and agents, without straining the metaphor.
- **An atelier keeps the studies.** Not only the finished drawing: the sketches,
  the abandoned approaches, the ones that did not work. **That is breadth
  preservation, and no other candidate carried it in its literal meaning.**
- Zero uses. Distinctive. Sat well beside `Indigo`.

**What it lost on.** It names the *place where work happens* rather than the
*record kept there*, and it claims no lineage. `IRIS` pays open homage to
**IBIS** — the system this one descends from and improves in exactly one respect
— and it sits in the same family as `Indigo`, the repository beside it. A name
that cites its ancestor is worth more here than a name that describes its room.

**The argument from `atelier` survived its rejection and then took two jobs.**
*The studies are kept* is the epigraph at the head of this file — the best
one-line statement of what the system is for, and better than anything written
for the purpose. And `atelier/` is the directory holding intents nobody has
commissioned yet, replacing a directory called `ideas/` whose name described
everything and distinguished nothing. **A rejected candidate that turns out to
name two real things is the argument for keeping rejected candidates**, made by
this document about itself.

### The two instruments, and why they are named for optics

**`Prism` disperses; `Lumen` admits.** The allocator takes one body of work and
splits it into separated streams. The interviewer does the **inverse** — many
candidate questions collapsed to one, with the least context that will serve.
Dispersion and convergence are the two things that can be done to a beam, so the
pair is physically the inverse of each other rather than merely themed, and it
explains itself the first time anyone asks.

**A lumen is the open channel through a vessel, and also a unit of light** — both
the opening and what passes through it, which is what the interviewer decides.

**They are instruments, not actors, and the name says so.** This repository calls
its tools *instruments* 165 times; `0050` is titled *instruments that cannot
fire*. A prism does not disperse as an act it performs — it is what dispersion
happens through. **The session is the agent.** An agentive name — `Lumenator`,
`Prismacator`, `Illuminator` — promotes an instrument to an actor and contradicts
the register 165 uses established. It was considered and rejected on exactly that
ground; `Illuminator` is additionally the wrong meaning, since a lumen restricts
what passes rather than adding to it.

**The role travels with the name, in every title.** `# Prism — the allocator`, so
a reader who has never met the word still lands, and a reader who has says
*Prism*. Keeping the role out of the **name** matters for a second reason: a
function-name goes stale when the function grows, and the allocator already
builds the graph, weights the edges, costs load and computes hold sets.

**`Pupil` was the first choice and lost on sound.** Its case was the strongest on
meaning — the pupil is the opening the iris makes, so it is anatomically inside
the whole, and *a pupil* is also one who asks in order to learn. It is recorded
because a candidate that is right on meaning and wrong on sound is a thing a
later reader will otherwise re-propose. Also considered: `Oculus`, architectural
and register-coherent but three syllables against Prism's one; `Fovea`, precise
and too obscure; `Facet`, which a prism has, but a facet does not choose.

### Also rejected

| | Why not |
|---|---|
| `cartulary` — the register in which **charters** are recorded | almost too exact, given `charter` is a genus here. Unsayable in a standup |
| `muniment` — documents kept as evidence of rights | same virtue, same obscurity |
| `crucible`, `assay` | about testing, which is one activity and not the whole |
| `loom` | threads held in tension; says nothing about keeping |
| `foundry` | a foundry casts from a mould and keeps no studies |
| `framework`, `collection` | honest and generic; `collection` never answered *a collection of what* |

### Two things kept separate

**The directory name and the product name.** `iris/` is both today, and need not
stay both: the directory has zero incoming citations and is cheap to rename, and
a product name is not.

**`record` was unavailable and it is worth saying why.** It is already a write
category, and no value may belong to two vocabularies at once — the rule this
system applies to its own statuses, applied to its own name.

<!-- proposed: iris/vocabulary.md -->
<!-- proposed: iris/lifecycles.md -->
<!-- proposed: iris/schema.md -->
<!-- proposed: iris/shapes.md -->
<!-- proposed: iris/procedure.md -->
<!-- proposed: iris/why.md -->
<!-- proposed: iris/directory-reference.md -->
