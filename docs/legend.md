# Legend — findings statuses and session states

The three vocabularies used across `docs/` — finding statuses, bundle standings
and session states. **This file is where they are defined.**
[`.github/session-management-instructions.md`](../.github/session-management-instructions.md)
says what each one *requires* and points here for what each one *means*, so there
is one place to change.

**This file is project-agnostic and is meant to be reusable as-is.** Nothing in
it should acquire an example that only makes sense in one project: the next
project inherits the file, and an example it cannot follow reads as noise.

**Where these values live.** A bundle's `standing` and `progress`, and a
session's `state`, are **derived and then stored** in `metadata.json` — written
by `./bin/plan-findings-work.sh stamp` and by nothing else. They were derived and
*not* stored until Revision 232; the owner reversed that so a reader need not run
a ladder to learn where a bundle stands, and `docs/architecture/state-as-data.md`
section 4.4 carries the reasoning and the condition. **The condition is the one
this file already imposes on any copy of a derived fact**: a copy is permitted
where a check fails when it drifts, and `./bin/plan-findings-work.sh check`
reports `UNSTAMPED` for a null and `STORED-DISAGREES` for a value that has come
adrift from what it derives from.

The bundle's row in its `INDEX.md` carries the same value for a reader scanning
the tree, and the two must agree.

A standing was carried in a marker filename until Revision 222 --
`STATUS-<status>` for a findings bundle, `STATE-<state>` for a session -- which
made every transition an unlink plus a create and put three unrelated facts in
one slot. `0043` F1 is the reading; `0039` D7 is why it mattered. The derivation
was proved against all 54 tags before they were removed, and it reproduced every
one.

---

## Findings statuses

A findings bundle is a reading of something that already exists. **Status is
carried by each finding; the bundle's standing is derived from them.** The status
says how far a reading has been taken, never how anyone feels about it.

### A finding

| Status | Meaning | Who may read | Who may record |
|---|---|---|---|
| `un-started` | Recorded, never read. | the owning session only | — |
| `framing` | Live and open. The reading, the wording of the problem statement, and the decisions are all still being worked. | any session | any session |
| `decided` | Every decision is made. The owning session resolves it from here. | any session | the owning session only |
| `resolved` | Done. Frozen — `reopened` is the only way it may be altered. | any session | nobody |
| `reopened` | A `resolved` finding put back in play. The only door out of `resolved`, and it takes a **reason**. Nothing is reverted, and it persists until the record materially changes. | the owning session only | — |
| `withdrawn` | Shut down. No further work, ever. | any session | nobody |

```text
             first          decisions      resolution      reason
             reading        accepted       executed        recorded
                │              │              │              │
                ▼              ▼              ▼              ▼
un-started ──▶ framing ──▶ decided ──▶ resolved ──▶ reopened ──┐
                  ▲            ▲                               │
                  │            └── decision accepted ──────────┤
                  └── written to, or a contribution ───────────┘

withdrawn ◀── from any status except `resolved`
```

**Every arrow names the event that causes it, and every event is a change to the
record.** A status does not move because someone read the finding. Assignment
does not move it, a vocabulary sweep does not, a rename does not, and a retrofit
does not — each of those touches a status cell without anyone forming a judgement
about the finding underneath it, and each is a mass operation, so a wrong one
damages every finding it passes over. Revision 208 moved twenty-one rows that
way; the reading is `0039` F12.

**`reopened → decided` directly is correct, not a skipped step.** It is the
common case: the framing was sound and the *resolution* was wrong. Routing it
through `framing` would assert the problem statement is being reworked.

### Reasons

**Four transitions take a reason from a closed set**, and the reason is a field
rather than prose so a later reader can group by it and a checker can validate it.
An optional free-form `note` elaborates; the reason is what is reasoned about.

**Reopening a finding** — `resolved ──▶ reopened`. The reason names the layer at
fault, and **the layer determines the exit**, which removes a judgement call at
the moment someone is already annoyed about a bug.

| Reason | What it says | Exits to |
|---|---|---|
| `resolution-defective` | the work was done and is wrong | `decided` |
| `resolution-incomplete` | the work was done and does not cover the finding | `decided` |
| `resolution-had-side-effects` | it worked, and broke something else | `decided` |
| `resolution-not-applied` | the record says resolved; the tree disagrees | `decided` |
| `resolution-regressed` | it was applied, and a later change removed it | `decided` |
| `resolution-unverifiable` | the claim cannot be checked | `decided` |
| `decision-wrong` | the decision it carried out was wrong | `framing` |
| `decision-inapplicable` | the decision's target no longer exists | `framing` |
| `framing-wrong` | the problem statement was wrong | `framing` |

A fault in the *work* leaves the decision standing, so the finding returns to
`decided` and the work is redone. A fault in the *decision* or the *framing*
returns it to `framing`.

There is no `unable-to-resolve`. Reopening is reachable only from `resolved`, so a
finding nobody can resolve never arrives at this door: it stays `decided`, or it is
`withdrawn`.

**Rolling a finding back** — `decided ──▶ framing`. Reframing a finding
invalidates the decisions under it, and **not every reason voids something**.

| Reason | Means | Effect on decisions |
|---|---|---|
| `framing-changed` | the problem statement materially changed | **every** accepted decision → `voided` |
| `decision-wrong` | a decision is wrong on the merits; the framing is intact | **that** decision → `voided` |
| `decision-inapplicable` | a decision's target no longer exists | **that** decision → `voided` |
| `decided-prematurely` | it was marked `decided` before every decision was made | none — `decided` was the error |
| `new-information` | something was learned that may change the answer | none yet; decisions flagged to re-evaluate |

The rollback is the **default** on any edit to the finding, and a session may
decline it **in writing**: a dated line in `decisions.md` recording that the edit
was non-material and why. A mechanical trigger alone over-fires on typos, and a
rule that fires on trivia gets routed around.

**Withdrawing** — a reason, an optional note and `withdrawn_at`, **per finding**.
A bundle-level withdrawal needs one for every finding in it, which keeps bundle
`withdrawn` derived rather than declared. A `resolved` finding is reopened first.

**Superseding** — a reason per disposition, alongside the provenance edge. See
*Provenance* below.

### Decision outcomes

A decision's `Outcome` is one of seven. **Statuses are adjectives about a
condition** — *where is this?* **Outcomes are past-participle verbs about an act**
— *what was done to this?* **No word appears in both vocabularies**, and a schema
check asserts the two sets are disjoint.

| Outcome | Means | Pointer |
|---|---|---|
| `proposed` | on the table; nobody has ruled | — |
| `accepted` | adopted — this is what will be done | — |
| `rejected` | turned down on the merits; nothing replaces it | — |
| `deferred` | cannot be ruled yet; what it waits on is named | required |
| `retracted` | the proposer withdrew it before a ruling | — |
| `replaced → DX` | a later decision answers the same question instead | required |
| `voided` | was `accepted`, then invalidated because its foundation moved | reason required |

`proposed` is stored rather than left empty, so an unset outcome is a load error
and not a reading. `replaced → DX` covers what `refined → DX` and
`superseded → DX` used to divide between them; the distinction was a judgement
nobody could check, and both told a reader the same thing.

### Provenance

**When a bundle is superseded, every finding of the predecessor is accounted
for.** Provenance is a property of the relationship rather than of either bundle,
so it is a typed edge at finding granularity, **stored in the new bundle only** —
the predecessor is never edited.

| Edge | Means | Reason |
|---|---|---|
| `carried` | comes over unchanged | none — nothing changed |
| `successor` | retained, and substantially changed | `restated`, `narrowed`, `widened` |
| `split` | one predecessor finding becomes several | names each target |
| `merged` | several predecessor findings become one | names each source |
| `dropped` | it no longer applies | `already-resolved`, `no-longer-applies`, `absorbed → F<n>`, `out-of-scope`, `owned-elsewhere → <bundle>/F<n>` |

**`new` is derived, never stored:** a finding in the new bundle with no incoming
provenance edge is new by definition.

Two rules gate the `superseded` tag, so the accounting is a precondition rather
than a follow-up:

- **Coverage** — every predecessor finding is named by **at least one** disposition
  edge. Zero is the real failure: a finding silently lost.
- **Exclusivity** — a predecessor finding disposed `dropped` carries **that edge and
  no other**.

*Exactly one* was the first draft of both and rejects a legitimate split or merge.

### Awaiting a first read

**Three statuses mean the same thing — nobody has looked at this yet — and behave
identically.** They differ only in provenance:

| | Where it came from |
|---|---|
| `un-started` | a finding, never read by anyone |
| `reopened` | a finding, read and decided and resolved, then called into question |
| `transferred` | a bundle, handed to a session that has not opened it |

All three are **invisible to every session but the owner**, and **the owner's
first reading moves them on**. A finding awaiting a first read becomes `framing`.
A bundle that was `transferred` stops being an ownership row and derives from its
findings — which, once the ones awaiting a read are `framing`, is `analyzing`.

They are one idea with three origins, and treating them as three rules is what
makes them look arbitrary. **Reading is the transition**; nothing else moves
them, and no session but the owner can perform it.

**`framing` is the long one.** It is not a staging post on the way to a decision;
it is where the work happens, and it runs both ways. Rethinking a decision often
means the problem statement was phrased wrong, so a finding in `framing` may have
its wording refined and its decisions revised as one activity rather than two.

**Any session may record here, and that includes the decisions.** Not only
sharpening the reading — a second session may **write a decision, reject one, or
refine one** while the finding is `framing`. Deciding is not the owner's
privilege; *closing* the deciding is. That is what `decided` marks, and it is the
only thing it marks.

This is the thing that has repeatedly proved valuable: a second reader improves a
reading, and a second reader who disagrees with a decision improves it more.

**`decided` narrows it to one hand**, and it is the owner's move to make. Every
decision is made, so a change now lands against reasoning already taken — which
is exactly what was open a moment earlier, while the finding was `framing`. Other sessions may still read it — that
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

Derived from its findings. **Read each table below in order and take the first
row that matches** — the cases overlap, and the order is what makes the answer
single-valued.

**The ladder is five rows, not eight.** `state-as-data.md` section 4.4 split the
one overloaded slot into three fields, and three of the old rows left with it:
`unclaimed` and `transferred` are the `ownership` field, `superseded` is
`lineage`. They were never derivations — they are declared, and they sat in the
ladder as overrides because there was nowhere else to put them.

**`progress` — derived from the finding rows, in order, first match wins:**

| # | `progress` | When |
|---:|---|---|
| 1 | `untouched` | every finding is `un-started` |
| 2 | `retired` | every finding is `withdrawn` |
| 3 | `answered` | every finding is `resolved` or `withdrawn`, and at least one is `resolved` |
| 4 | `revisited` | at least one finding is `reopened`, and every other finding is **inert** — `resolved` or `withdrawn` |
| 5 | `analyzing` | any other combination |

**`standing` — `progress` with ownership and lineage put back in:**

| If | Then `standing` is |
|---|---|
| `lineage.supersededBy` is set | `superseded` |
| `ownership` is set | that value — `unclaimed` or `transferred` |
| `progress` is `untouched` and a session owns it | **`assigned`** |
| otherwise | whatever `progress` says |

`assigned` is the one value `standing` has that `progress` does not, and
`untouched` the one `progress` has that `standing` does not. Neither can be false
where it appears: a bundle nobody owns returns `unclaimed` before the derivation
is reached, so it never reads `assigned`.

**A finding has a status; a bundle has a standing; a session has a state, and no
value belongs to more than one of the three.** So this table is a translation and
not a lookup: finding statuses go in the right-hand column and a bundle standing
comes out of the left. Read a bare `framing` and you know it is a finding; read
`analyzing` and you know it is a bundle. Revision 233.

**`progress` is where this vocabulary will grow.** Separating it from ownership
left it free to say things about the *reading* that ownership has no view on — a
change proposed and awaiting the owner (`pending`), a reading nobody has touched
for weeks (`stalled`), one deliberately stopped (`halted`). Two of those three
fall out of a timestamp the schema already has and does not populate, and the
third needs a marker for a proposal. **None of them belongs in `standing`**,
which answers who owns this and whether the reading still stands. Recorded here
so the room is used deliberately rather than filled by the first thing that needs
a word.

**A bundle carries two derived fields and they answer different questions.**
`progress` is the reading alone — `untouched`, `analyzing`, `answered`,
`revisited`, `retired` — and is true whoever owns the bundle. `standing` is that
with ownership and lineage put back in, which gives it two values `progress` does
not have: **`assigned`**, where the reading is `untouched` and a session owns it,
and the three declared values above. A bundle nobody owns reads `unclaimed` and
never `assigned`. Both are stamped by
`./bin/plan-findings-work.sh stamp` and neither is written by hand.

`unclaimed` and `transferred` are about **ownership** rather than progress — one
has no owner, the other has a new one who has not looked yet — and `superseded`
is declared by the session that replaces the bundle. **Neither `unclaimed` nor
`transferred` ever applies to a single finding.**

**A finding is inert when it is `resolved` or `withdrawn`** — finished, either
way, with nothing outstanding. The other four are live.

**`revisited` dominates the inert.** A bundle of reopened findings, or reopened
findings sitting among resolved and withdrawn ones, is `revisited`: the only work
in it is the reopening, and the index should say so rather than saying `analyzing`
and making a reader open it to find out. But a reopened finding alongside anything else
live — a `framing` finding, a `decided` one, an `un-started` one — is a genuinely
mixed bundle, and that is `analyzing`. **The `revisited` row fires only** when
reopening is the whole of the live work.

`unclaimed` is the exception because it is about **ownership, not progress**. A
bundle is `unclaimed` when no session owns it — created without an owner
declared, or released back to the queue by one. It is closed to every session,
appears in no `findings-manifest.md`, and is carried only by its index row. The
owner assigns it; that makes the receiving session `active` and moves the bundle
to whatever its findings derive, which for a bundle nobody has read is
`assigned`.

`answered` counts a `withdrawn` finding as finished. Withdrawing is a deliberate
end, not an omission, so it does not hold a bundle open — but a bundle of nothing
but withdrawals is `retired`, not `answered`, because nothing was carried
through. That is why `retired` sits above `answered`.

`superseded` and `retired` are terminal and neither is a failure. The
difference is whether a reader following the trail lands somewhere.

**`superseded` and `reopened` are not alternatives.** `superseded` applies to a
whole bundle, never a single finding, and **reaches a bundle at any standing** —
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

**`transferred` is neither: it moves a bundle between sessions and changes
nothing about the reading.** Unlike a session `handoff`, which moves everything a
session holds and is a property of the session, a transfer moves **one bundle**
and is a property of that bundle. The target session must already exist —
created, cloned, or long running — because a transfer names a destination where a
handoff creates one. A bundle may be transferred while it stands `assigned`, `revisited` or
`analyzing`; the terminal standings have nothing to move.

### What another session may do

The owning session reads finding statuses directly — it is already inside. Every
other session checks the bundle first, then the finding.

| Bundle standing | Then, inside it |
|---|---|
| `superseded` | **readable by any session, writable by none** — including the session that owns it. The reading is retained precisely so it can be read; §9 spends three prohibitions keeping it that way |
| `assigned`, `unclaimed`, `retired` | nothing is readable |
| `analyzing`, `revisited`, `answered` | `framing` — read and record · `decided` — read only · `resolved` — read only · `un-started`, `reopened`, `withdrawn` — not readable |

An `assigned` bundle offers nothing to anyone but its owner, by definition: all
its findings are `un-started`, and the owner's first reading is what opens them.

**The three rows are disjoint, so no tie-break is needed.** Until Revision 239
`superseded` appeared in two of them under opposite rules — *nothing is readable*
and *readable by any session* — which, read by the stated first-match rule, made
the legend say a superseded bundle cannot be opened while
`.github/session-management-instructions.md` §9 spends three prohibitions keeping
it readable. The third row also carried `reopened` and `resolved`, which are
finding statuses, under a heading that says *Bundle standing*. Both came over
from the eight-row ladder Revision 236 replaced. `0039` F21.

**Two cells here disagree with *A finding* and are deliberately left alone.** A
`retired` bundle holds nothing but `withdrawn` findings, and *A finding* makes a
`withdrawn` finding readable by any session — so *nothing is readable* cannot be
right for it, and the third row's cell says the same thing again where it ends
`withdrawn` — not readable. **Which side is right is a reading, not a repair**,
and a repair revision is the wrong place to decide it. `0039` F21 owns the
question.

## Who may write to a findings bundle

Permission is carried by the **finding**, not the bundle; the bundle standing is
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
line in `findings.md`'s header beside `Recorded`, `Severity` and `Scope`:

```text
**Relates to:** `<NNNN>` — a one-line statement of how the two bear on
each other, and from which direction.
```

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
| `closed` | Every bundle it owns is terminal — `resolved`, `superseded` or `withdrawn` — and any that is not has been released to `unclaimed`. | `final-summary.md` |
| `withdrawn` | Every bundle it owns is `withdrawn`. | `final-summary.md` |

```text
available ──▶ active ──┬─▶ closed       every bundle resolved
                       ├─▶ handoff      bundles carried to a successor
                       └─▶ withdrawn    every bundle withdrawn
```

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

Three kinds, told apart by what is being written. **These are the definitions.
When each is allowed, and where each is composed, are procedure** —
`.github/session-management-instructions.md` §6. `0039` D2 and D13.

| Category | What it is |
|---|---|
| **record** | a write under `docs/` — a finding, a decision, a session file |
| **toolkit** | a write to any other tracked file |
| **evidence** | a write to the artifact volume |
| **`foreign`** | a write to any other connected folder — another project entirely. Ordinary, and **not recorded here**: `0039` D19 |

**The three fail differently, which is why the distinction is worth a name.** A
bad record write is corrected by writing again. A bad toolkit write is reverted.
**A bad evidence write may be unrecoverable**, because evidence records a state
of the world that no longer exists to be recaptured.
