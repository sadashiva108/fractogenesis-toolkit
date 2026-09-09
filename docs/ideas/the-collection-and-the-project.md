# The collection and the project

**Written:** 2026-09-09, `assurance-coverage-20260908-204724`, from the owner's  
intent to reorganise so it is visible which files belong to the collection  
management system and which to the reimaging workflow.  
**Scope:** the top-level layout, the bundle genera, and what each genus's members  
are called. **Not** the migration itself.  
**Reads against:** [`typed-bundles-and-work.md`](../architecture/typed-bundles-and-work.md),
[`state-as-data.md`](../architecture/state-as-data.md),
[`rule-enforcement-avenues.md`](../rules/rule-enforcement-avenues.md),
[`0030`](../cross-cutting-findings/0030-renames-break-citations-and-which-may-be-repaired/).  
**Status:** **a commission. Nothing here is decided and nothing is built.**

An intent to build gets a file here, no status and no owner —
`typed-bundles-and-work.md` §1. **This document is the first real test of the
thing it describes**: it is a commission, and there is nowhere to put a
commission, so it sits in `ideas/` like every other one.

---

## 1. The defect the layout already has

Two governing documents state that the framework is **project-agnostic and meant
to be reusable as-is** — `.github/session-management-instructions.md` and
`docs/legend.md`, each in its opening lines.

**Try to lift it and it is a minority in four roots, none of which is its own.**
Counted 2026-09-09 at Revision 259:

| Root | framework files | the project's |
|---|---:|---:|
| `bin/` | 6 | 42 |
| `.internal/` | 16 | 54 |
| `.github/` | 5 | 13 |
| `docs/architecture/` | 6 | 4 |

`.github/copilot-instructions.md` already carries the test that separates them —
**would this still be true in a project that did something else entirely?** It
lives in prose and nowhere in the tree.

**That is not a tidiness complaint; it costs.** On 2026-09-09 a
session-management bundle (`0053` D2) added five currency watches over
`references/`, `bin/backup-*.sh` and the toolkit's architecture records — five
toolkit decisions taken from a session-management bundle. The session could not
see whose `references/` was, **because the layout does not say.** The reading was
correct and the venue was wrong, and nothing in the tree would have caught it.

## 2. What a move costs, measured

`0030` is the standing reason to fear a rename. Measured at Revision 259:

| How a bundle is cited | Count | Survives a move |
|---|---:|---|
| by number — `` `0049` `` | **1891** | **yes** |
| by directory path | 172 | no |
| — of those, inside frozen records | 37 files | **must not be repaired** — `0044` D2 |
| — of those, in live navigation | **7 files** | repaired |

**92% of citations are by number.** The instruction set already says *"`finding
<NNNN>` names a bundle without needing its tree"*, and the measurement bears it
out: the tree is decoration the path is currently forced to carry, and the
repairable surface is seven files.

## 3. Proposal — one root for the collection

```text
collection/               the collection management system
  rules/                  legend.md, the session-management instruction set
  architecture/           state-as-data, the-record-and-the-graph,
                          findings-and-sessions, allocation-and-inquiry,
                          transferring-part-of-a-bundle, typed-bundles-and-work,
                          rule-enforcement-avenues
  ideas/                  commissions with nowhere yet to live
  ledgers/                the collection's own ledgers
  prompts/                conformant prompt, session prompt, what-a-session-is-given
  bin/                    plan-findings-work, verify-session-findings,
                          verify-doc-currency, review-changes, test-session-management
  lib/                    today's .internal/ai-scripts/session-management/
  bundles/                see section 5
  sessions/               see section 4
```

Everything else stays where it is and is thereby visibly the project's: the
runbooks at the repository root, `references/`, `bin/backup-*` and the rest,
`.internal/artifact-config.sh`, and the project's own architecture records and
ledgers.

**The argument is that the reusability claim becomes checkable.** Copy one
directory into another project and either the framework works or it does not.
Today the claim cannot be tested at all.

**A visible name, not a dotted one.** `.collection/` hides the first thing a
session is required to read. `collection/` or `framework/`; the word matters less
than that `ls` shows it.

## 4. The vocabulary, and a collision in it

The owner's ruling, 2026-09-09:

- **session** — say *session*, never *session bundle*. A session is the actor; it
  owns work rather than being a unit of it.
- **bundle** — already the short form of **findings bundle**, and used that way
  152 times against 71 for *session bundle*.

**That creates a problem `typed-bundles-and-work.md` does not yet have a word
for.** Its draft calls the family *"the bundle as a genus taking two shapes"*.
**If `bundle` is the short form of one species, it cannot also name the genus** —
which is Revision 243's tier-1 rule exactly: *no value shared between the sets,
so a bare value says which set it came from*.

**So the genus needs a name that is not `bundle`, and this document does not pick
one.** What is certain is that *bundle*, unqualified, means a findings bundle.

## 5. The genera, and what their members are

| Genus | Members | Poses | Produces |
|---|---|---|---|
| **findings bundle** (*bundle*) | findings | what is true about something that exists | an answer per finding |
| **commission** | blueprints | we want X — what shape should it take | a design under `architecture/` |
| **the third** — *name undecided* | tasks | nothing; it executes | changes |

**The file shape generalises with one rename.** The member document is named for
its genus — `findings.md`, `blueprints.md`, `tasks.md` — and `decisions.md` and
`resolutions.md` stay common to all three, because each genus decides about its
members and records what was done. In `metadata.json`, `findings[]` becomes
`members[]`.

### 5.1 The third genus needs a name and every short one is taken

*Doing bundle* is the draft's word and the owner is not sold on it. Counting uses
against the whole tree, 2026-09-09 — the Revision 244 discipline, because a term
that already means something else arrives pre-broken:

| Candidate | Existing uses | Verdict |
|---|---:|---|
| `order` | 327 | unusable — *topological order*, *review order*, *the order is the decision* |
| `build` | 198 | unusable |
| `works` | 185 | unusable |
| `doing` | 141 | heavily used as the plain verb |
| `detail` | 78 | unusable |
| `assignment` | 65 | collides with the owner's act of assigning |
| `job` | 47 | 47, and generic |
| `dispatch` | 16 | already the word for handing work to an agent |
| `charge` | 9 | **collides** — Revision 238 uses *a per-session charge* for a session's brief |
| `warrant`, `campaign` | 3 each | nearly clean |
| `undertaking`, `venture`, `mandate`, `remit`, `docket`, `writ`, `tasking`, `consignment` | **0** | clean |

**The finding is that no short, natural English word is free.** Of the clean set,
`remit` and `mandate` read as *what someone is permitted to do* rather than *the
work itself*; `docket` and `writ` are legal register the rest of the vocabulary
does not use; `tasking` is a gerund where the others are nouns. **`undertaking`
and `venture` are the two that survive on meaning**, and both are longer than
anything else in the vocabulary.

**A fourth option is to stop naming it after the work and name it after the
member**, as *findings bundle* is: a **task bundle** — except *bundle* is now the
findings bundle's short form, which is the collision in section 4 arriving from
the other side.

**This is the owner's to settle.** The table is here so the choice is made
against what the words already mean in this repository rather than against how
they sound.

## 6. Flatten the bundles; put the classification in the data

```text
collection/bundles/0049-the-patch-is-named-as-the-deliverable-and-never-produced/
```

`metadata.json` carries `genus` and `kind`; the path carries neither.

**It resolves two live findings rather than only tidying.** `0041` F3 records
that its own bundle *"may be in the wrong tree"* and could not be settled,
because moving it meant a rename — with `kind` as a field it is a one-line edit.
`0037` and `0041` supersede bundles in a different tree, which stops being a
special case. And `state-as-data.md` §8 already rules that the indexes *"stop
being the source, not that they stop existing"*: one flat directory makes them
one generated view instead of four maintained by hand.

**Kind never appears in a path.** The third genus is said to come in kinds; if a
kind is ever a directory name it re-creates the problem this section removes.

## 7. Sessions are not bundles, and stay separate

A session is identified by `<title>-<stamp>` while the three genera share one
`<NNNN>` sequence. It **owns** work rather than being a unit of it, and its
`metadata.json` has a different shape.

`collection/sessions/` keeps that distinction visible. **The alternative —
folding sessions into `bundles/` — means giving them numbers from the shared
sequence**, which would make *bundle* cover both the work and the worker, the
thing section 4 has just ruled against.

## 8. What this does not settle

**The migration order.** Fifty-three numbered bundles, nine sessions and four
roots move. The seven live-navigation files must be repaired in the same revision
as the move or citations resolve to nothing in between; the 37 frozen records
must **not** be repaired, and `0044` D2 is the rule for telling them apart.
Nothing here sequences that.

**Whether `references/` is the project's.** This document assumes it is — every
one of the eleven is cited by a runbook and describes the reimaging workflow —
but that is the toolkit set's ruling to make, and `0053` D2 is the live example
of a session-management bundle making it by accident.

**What `.github/` keeps.** `copilot-instructions.md` is the router for both sets
and belongs to neither. It may be the one file that stays at the top.

**Whether the collection should be a separate repository eventually.** A single
directory is the step that makes the question answerable; it is not the answer.

<!-- proposed: blueprints.md -->
<!-- proposed: tasks.md -->
