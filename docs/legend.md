# Legend — findings statuses and session states

The three vocabularies used across `docs/` — finding statuses, bundle statuses
and session states. **This file is where they are defined.**
[`.github/session-management-instructions.md`](../.github/session-management-instructions.md)
says what each one *requires* and points here for what each one *means*, so there
is one place to change.

**This file is project-agnostic and is meant to be reusable as-is.** Nothing in
it should acquire an example that only makes sense in one project: the next
project inherits the file, and an example it cannot follow reads as noise.

Both are recorded twice and the two must agree: in the bundle's row in its
`INDEX.md`, which is authoritative, and in a tag file on the bundle directory —
`STATUS-<status>` for a findings bundle, `STATE-<state>` for a session bundle —
so `ls` answers the question without opening anything. Spaces become hyphens:
`STATUS-in-progress`.

---

## Findings statuses

A findings bundle is a reading of something that already exists. **Status is
carried by each finding; the bundle's status is derived from them.** The status
says how far a reading has been taken, never how anyone feels about it.

### A finding

| Status | Meaning | Who may read | Who may record |
|---|---|---|---|
| `un-started` | Recorded, never read. | the owning session only | — |
| `framing` | Live and open. The reading, the wording of the problem statement, and the decisions are all still being worked. | any session | any session |
| `decided` | Every decision is made. The owning session resolves it from here. | any session | the owning session only |
| `resolved` | Done. Frozen — `reopened` is the only way it may be altered. | any session | nobody |
| `reopened` | A `resolved` finding put back in play because its resolution is inconsistent or wrong. Nothing is reverted. | the owning session only | — |
| `withdrawn` | Shut down. No further work, ever. | any session | nobody |

    un-started ──▶ framing ──▶ decided ──▶ resolved ──▶ reopened ──┐
                      ▲                                            │
                      └────────────────────────────────────────────┘
                                  first read by the owner

    withdrawn ◀── from any status except `resolved`

**`un-started` and `reopened` behave identically and that is deliberate.** Both
are invisible to every session but the owner, and the owner's first reading moves
either to `framing`. The difference is only where they came from: one has never
been read, the other has been read, decided, resolved, and called into question.

**`framing` is the long one.** It is not a staging post on the way to a decision;
it is where the work happens, and it runs both ways. Rethinking a decision often
means the problem statement was phrased wrong, so a finding in `framing` may have
its wording refined and its decisions revised as one activity rather than two.
Any session may record here, which is the thing that has repeatedly proved
valuable: a second reader improves a reading.

**`decided` narrows it to one hand.** Every decision is made, so a change now
lands against reasoning already taken. Other sessions may still read it — that
costs nothing and helps — but recording and resolving belong to the owner alone.
`decided` is the enduring fact that decisions are complete; whether the owner is
actively resolving at any given moment is not something a status should try to
say.

**`withdrawn` reaches every status but `resolved`.** Its purpose is to stop work,
and resolved work has already stopped. **Anything the finding contributed while
it was `framing` or `decided` is reverted** — `git revert` against the commit
hash, plus a new `APPLY-MANIFEST.md` entry naming what was reverted and why.
Nothing is retro-edited; the record is additive, and the revert is itself a
recorded change.

### A bundle

Derived from its findings, with two exceptions. **Read the ladder in order and
take the first row that matches** — the cases overlap, and the order is what
makes the answer single-valued.

| # | Status | When |
|---:|---|---|
| 1 | `unclaimed` | no session owns it — never assigned since creation, or released back to the queue. Never applies to a finding |
| 2 | `superseded` | replaced whole by a later bundle, **from any status**. Declared, not derived. Bundles only |
| 3 | `un-started` | every finding is `un-started` |
| 4 | `withdrawn` | every finding is `withdrawn` |
| 5 | `resolved` | every finding is `resolved` or `withdrawn`, and at least one is `resolved` |
| 6 | `reopened` | at least one finding is `reopened`, and every other finding is **inert** — `resolved` or `withdrawn` |
| 7 | `analyzing` | any other combination |

Rows 1 and 2 are the exceptions: `unclaimed` is about ownership rather than
progress, and `superseded` is declared by the session that replaces the bundle.
Rows 3 to 7 are read off the findings.

**A finding is inert when it is `resolved` or `withdrawn`** — finished, either
way, with nothing outstanding. The other four are live.

**`reopened` dominates the inert.** A bundle of reopened findings, or reopened
findings sitting among resolved and withdrawn ones, is `reopened`: the only work
in it is the reopening, and the index should say so rather than saying `analyzing`
and making a reader open it to find out. But `reopened` alongside anything else
live — a `framing` finding, a `decided` one, an `un-started` one — is a genuinely
mixed bundle, and that is `analyzing`. Row 6 fires only when reopening is the
whole of the live work.

`unclaimed` is the exception because it is about **ownership, not progress**. A
bundle is `unclaimed` when no session owns it — created without an owner
declared, or released back to the queue by one. It is closed to every session,
appears in no `findings-manifest.md`, and is carried only by its index row. The
owner assigns it; that makes the receiving session `active` and moves the bundle
to whatever its findings derive, which for a bundle nobody has read is
`un-started`.

`resolved` counts a `withdrawn` finding as finished. Withdrawing is a deliberate
end, not an omission, so it does not hold a bundle open — but a bundle of nothing
but withdrawals is `withdrawn`, not `resolved`, because nothing was carried
through. That is why row 4 sits above row 5.

`superseded` and `withdrawn` are terminal and neither is a failure. The
difference is whether a reader following the trail lands somewhere.

**`superseded` and `reopened` are not alternatives.** `superseded` applies to a
whole bundle, never a single finding, and **reaches a bundle at any status** —
there is no state in which a reading cannot be replaced. Authority moves to the
new bundle; nothing is reverted or undone. The old bundle stands untouched as the
reading it was, keeps its number, its tree, its session and its place in that
session's `findings-manifest.md`, and only its status changes. Its row names the
replacement, which carries `Relates to`.

Cloning the original is the usual way to build the replacement, and it is not
required. What is required is that the replacement carries the reading forward
and names what it replaces; whether it starts as a copy or as work already begun
is the superseding session's business.

`reopened` alters a finding in place, one at a time, and only reaches what is
`resolved`. **Replacing a reading is superseding; correcting a resolution is
reopening.**

### What another session may do

The owning session reads finding statuses directly — it is already inside. Every
other session checks the bundle first, then the finding.

| Bundle status | Then, inside it |
|---|---|
| `un-started`, `unclaimed`, `withdrawn`, `superseded` | nothing is readable |
| `analyzing`, `reopened`, `resolved` | `framing` — read and record · `decided` — read only · `resolved` — read only · `un-started`, `reopened`, `withdrawn` — not readable |

An `un-started` bundle offers nothing to anyone but its owner, by definition: all
its findings are `un-started`, and the owner's first reading is what opens them.


## Who may write to a findings bundle

Permission is carried by the **finding**, not the bundle; the bundle status is
what another session checks first to know whether opening it is worth anything.
The table at the end of *Findings statuses* is the whole rule. In prose:

**Only the owning session opens a finding.** An `un-started` or `reopened`
finding is invisible until the owner reads it, and that first reading is what
moves it to `framing`. Writing the bundle up in the first place is not a reading
— a session may record a bundle it will never own, and leave it `unclaimed` or
hand it to somebody else.

**While a finding is `framing`, any session may record to it** — sharpen the
wording, add detail, correct it, or take it out if it does not hold. A reading is
not diminished by a second reader, and a session that spots something while
working elsewhere should be able to put it where it belongs rather than open a
near-duplicate beside it. This has repeatedly proved its worth.

**From `decided` onward, only the owner records.** Every decision is made, so a
change now lands against reasoning already taken. Other sessions may read it,
which costs nothing.

**A `resolved` finding is frozen.** It may be read by anyone and altered by
nobody. `reopened` is the only door, and going through it is a declared act
rather than a quiet correction — which is what makes §4c's *"`findings.md` is
written once, never rewritten to match what was later decided"* hold rather than
being broken in passing.

Two consequences worth stating:

- **Recording a bundle and owning one are different acts.** A session may record
  a bundle it never owns; the repository owner assigns ownership. Contribution
  does not create ownership and never has.
- **Assignment is what starts things.** An `unclaimed` bundle sits outside every
  session until assigned; assigning it makes the receiving session `active`.


## When something overtakes a finding that is already decided

`decided` closes a finding to every session but its owner, which leaves a
second session with something that bears on it — new evidence, an idea that
changes a problem statement — with nowhere to put it.

**Mark the bundle `superseded` and open a new one carrying the merged reading.**
The original stands untouched. The procedure is in
`.github/session-management-instructions.md` section 9.
The superseded row names its replacement; the replacement carries a `Relates to`
line naming what it replaces. Nothing is edited inside a bundle whose decisions
have been taken against it as it was read, which is the property `decided`
exists to protect.

The cost is real and belongs in the new bundle's `decisions.md`: **decisions do
not carry forward by themselves.** Every decision taken in the superseded bundle
is re-affirmed against the merged reading or explicitly dropped, because a
decision reached against seven findings may not hold against nine.

This is expected to be rare. By the time an owner starts a bundle they are
usually satisfied with its problem statements, and a contribution that genuinely
changes one after that is the exception rather than the working case.

## `Relates to`

A bundle may name another it bears on, without either replacing the other, as a
line in `findings.md`'s header beside `Found`, `Severity` and `Scope`:

    **Relates to:** `<NNNN>` — a one-line statement of how the two bear on
    each other, and from which direction.

It is a pointer and nothing more: it creates no ownership, moves no status, and
obliges nobody. It exists because two readings of one mechanism from different
angles are common, and a reader who finds one should be able to find the other.
`superseded` uses the same line to name what it replaced.

## The owner's override

**The owner may override any rule here, at their discretion.** A session may not
invoke this on its own behalf and may not infer it; it acts on an override only
when the owner gives one.

The case it exists for is the one that has already occurred: a change the owner
has already decided, with no finding behind it and nothing to discuss, which the
lifecycle would delay without adding anything. Routing a settled decision through
a bundle, a reading and a decisions document produces paperwork, not judgement.

**A revision carrying an overridden change says so, and says what was
overridden.** That is the whole discipline: the override is not a loophole
because it is never silent, and a reader can always tell a change that followed
from a finding from one the owner simply directed. An override that goes
unrecorded is indistinguishable from a rule nobody agreed to.

## Session states

A session is a unit of work. It creates its own bundle, and its state is derived
from the findings bundles it owns.

| State | When | Produces |
|---|---|---|
| `available` | Created or cloned, owning no findings bundle yet. | `metadata.md` |
| `active` | Owns at least one bundle that is not `resolved` or `withdrawn`. | `findings-manifest.md` |
| `handoff` | It has passed its qualifying bundles to a successor. No longer working. | `handoff-<stamp>.md`, one per handover |
| `closed` | Every bundle it owns is `resolved`. | `final-summary.md` |
| `withdrawn` | Every bundle it owns is `withdrawn`. | `final-summary.md` |

    available ──▶ active ──┬─▶ closed       every bundle resolved
                           ├─▶ handoff      bundles carried to a successor
                           └─▶ withdrawn    every bundle withdrawn

### How a session begins

| | |
|---|---|
| **created** | given the conformant instruction set and prompt, plus instructions and a prompt specific to it |
| **cloned** | given an existing session's exact instruction set and prompt, including its customisations |
| **handoff** | given the outgoing session's instruction set, prompt and customisations, **and its bundles** |

The conformant instruction set and prompt are kept current as the rules change;
that is what "conformant" means and why a created session gets those rather than
a copy of somebody's.

A session bundle is created when the repository owner opens a new chat and pastes
the instruction set and prompt. Until it owns a bundle it is `available`.

### What transfers at handoff

Every bundle the outgoing session owns **except** those that are `resolved`,
`unclaimed` (unowned by definition), `superseded`, or `withdrawn`. For each one
that transfers: ownership changes to the new session, it is recorded in the new
session's `findings-manifest.md`, and every INDEX.md listing it has its Session
column updated.

**`superseded` is the special case.** The superseded bundle itself does not
transfer — it is terminal and preserved. The bundle that **supersedes** it is
created against the new session once that session's bundle exists, and is what
the index lists. So a session holding a superseded bundle at handoff is not
thereby finished: its successor picks up the replacement.

The outgoing session stays `handoff` and is understood to be no longer working.


## Write categories

Which files a session may touch depends on the bundle's status, so the three
kinds are named rather than left to judgement.

| Category | What | When |
|---|---|---|
| **record write** | anything under `docs/` — readings, decisions, resolutions, indexes, session bundles, this file | any status. It is how deciding gets recorded, so it is never gated |
| **toolkit write** | any other tracked file — everything the project *is*, and the rules for working on it | **only for a finding that is `decided`**, and only by the owning session |
| **evidence write** | anything outside the repository that the project treats as a record: `<EVIDENCE_ROOT>` | never, unless the owner has said so for that specific run |

A project names its own `<EVIDENCE_ROOT>` in
[`.github/toolkit-instructions.md`](../.github/toolkit-instructions.md) — the
volume, directory or store where its dated records live. A project with no such
store has two categories and not three; nothing else changes.

The manifest that records revisions sits outside `docs/` but accompanies **both**
record and toolkit writes — every change of either kind takes a revision — so it
is not a toolkit write and is not gated.

**The three fail differently, which is why the distinction is worth a name.** A
record write that turns out wrong is edited. A toolkit write that turns out wrong
has to be found, reverted and re-reviewed. An evidence write that turns out wrong
**may be unrecoverable**, because evidence records a state of the world that no
longer exists — which is why it is the one category the owner grants a run at a
time, and why a decision to change a script is never a decision to touch it.

These three words are used throughout
[`.github/session-management-instructions.md`](../.github/session-management-instructions.md),
which states the permission rules; this file defines what each category *is*.

---

## Where a write is composed

The categories above answer WHEN a write is allowed. Where it is composed is a
separate question, and the answer is the same for all three:

**Every write — record, toolkit or evidence — is composed in a copy of the
repository outside the owner's checkout, validated there, and handed over as a
patch.** The owner applies it, reviews the diff, and commits.

The two rules are kept apart because they do not line up. Permission varies by
category and by a findings bundle's status; composition varies not at all. And
the category needing the discipline most was the ungated one: record writes are
never gated — gating them would make deciding impossible — and record writes are
exactly what collided. A rule keyed to permission would have exempted precisely
the writes that caused the problem.

| | Varies by | Answers |
|---|---|---|
| **category** | what is being written, and the bundle's status | may I write this now |
| **composition** | nothing | where do I write it |

What it buys, measured over the revisions that ran this way before it was
decided: a patch is a diff boundary the owner can review as a unit; validator
numbers describe one session's change rather than whatever else is in the tree;
and declining a change becomes not applying a patch rather than surgery against
a file two sessions have touched.

What it costs, stated rather than argued away: **a copy in session-local storage
dies with the session.** It survives context compaction, which is the larger
risk; it does not survive termination. Hand over at natural stopping points, and
say when work exists only in the copy.

The revision number is the one thing NOT taken while composing. An entry is
written with its number left open and numbered when the patch is applied — see
the project's next-revision helper, and the session management set for why
choosing early cannot work.

Evidence writes were already solved this way by another route: a session has no
write permission to the artifact volume, and the owner grants it one run at a
time. One writer, decided by the owner, at the moment of the write.

The mechanics — what to run, what to check, and in what order — are in
[`.github/session-management-instructions.md`](../.github/session-management-instructions.md)
section 6.

---

## How the two meet

A session owns findings; a finding is worked by a session. The pointer runs both
ways and neither side is derived from the other:

- the session bundle's `findings-manifest.md` lists every finding it owns —
  authoritative for ownership;
- each findings bundle's INDEX.md row names the session working it.

A finding can outlive several sessions, and a session can own several findings.
Neither directory name carries the other's identifier, so neither has to be
renamed when the relationship changes.
