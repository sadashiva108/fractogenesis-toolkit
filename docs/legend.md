# Legend — findings statuses and session states

The two vocabularies used across `docs/`. This file is where they are defined;
`.github/copilot-instructions.md` sections 4c and 4d say what each one *requires*
and point here for what each one *means*, so there is one place to change.

Both are recorded twice and the two must agree: in the bundle's row in its
`INDEX.md`, which is authoritative, and in a tag file on the bundle directory —
`STATUS-<status>` for a findings bundle, `STATE-<state>` for a session bundle —
so `ls` answers the question without opening anything. Spaces become hyphens:
`STATUS-in-progress`.

---

## Findings statuses

A findings bundle is a reading of something that already exists. The status says
how far that reading has been taken, never how anyone feels about it.

| Status | Meaning | Produces |
|---|---|---|
| `unresolved` | Recorded. Nothing has been decided or changed. | `findings.md` |
| `in progress` | The findings are being reviewed and decisions being made for resolutions. | `decisions.md` |
| `resolving` | Begins **only** once **every** finding in the bundle has a decision recorded in `decisions.md`. The decided work is being carried out. | `resolutions.md` |
| `resolved` | Every finding in the bundle has a resolution recorded in `resolutions.md`. | — |
| `superseded` | A later findings bundle replaces this reading. The row names which, and the replacement carries `Relates to`. | — |
| `withdrawn` | The reading is dropped and nothing replaces it. The row says why. | — |

    unresolved ──▶ in progress ──▶ resolving ──▶ resolved
                                     │
                                     ├─▶ superseded   a later bundle replaces it
                                     └─▶ withdrawn    nothing replaces it

    └── any session may write ──┘└────── the owner only ──────────┘

`superseded` and `withdrawn` are both terminal and neither is a failure. The
difference is whether a reader following the trail lands somewhere: `superseded`
points onward, `withdrawn` says the trail ends here and gives the reason. A
`withdrawn` findings bundle writes no `resolutions.md` — there are none. Its
`findings.md` stands as the reading it was.

    └── any session may write ──┘└────── the owner only ──────────┘

## Who may write to a findings bundle

**While a bundle is `unresolved`, any session may contribute to it** — add a
finding, add detail to one, correct one, or remove one that does not hold. A
reading is not diminished by a second reader, and a session that spots something
while working elsewhere should be able to put it where it belongs rather than
open a near-duplicate bundle beside it.

**From `in progress` onward, only the owner writes to the bundle.** Deciding is
where a second hand does damage: a finding altered after a decision was taken
against it leaves the decision standing on something that has changed, and
`decisions.md` records reasoning against findings as they were read.

Two consequences worth stating:

- **Recording a bundle and owning one are different acts.** A session may record
  a bundle it will never own; the owner assigns ownership, and an unowned bundle
  sits at `unresolved` with `—` in its index Session column. Contribution does
  not create ownership and never has.
- **Moving a bundle to `in progress` closes it to everyone else.** That is a real
  cost and the reason not to move it early: an owner who takes a bundle in
  progress on day one gets exclusivity and loses every other session's eyes on
  the reading.

**A bundle advances when its first finding advances, and reaches `resolved` only
when its last one does.** `findings.md` carries a per-finding status table: one
row moving to `in progress` moves the bundle, because work has started and a
reader needs to see that; the bundle cannot be `resolved` while any row is not.
Which findings are where goes in the INDEX.md Notes column rather than into a
softened bundle status.

`in progress` and `resolving` are separate on purpose. The first is deciding;
the second is doing. Collapsing them is how work starts before the decision
behind it is settled, and how a resolution ends up with nothing recording why it
was the right one.

**The gate is the whole bundle, not one finding.** `resolving` waits until every
finding has a decision, and nothing outside `docs/` is written before it — no
script, no runbook, no artifact. Findings in one bundle bear on each other: a
reading that turns up ten problems in one mechanism will have fixes that
interact, and building the first before the tenth is decided is how a fix gets
made twice, or made in a shape the later decision would not have chosen.

---

## When something overtakes a bundle already in progress

`in progress` closes a bundle to every session but its owner, which leaves a
second session with something that bears on it — new evidence, an idea that
changes a problem statement — with nowhere to put it.

**Mark the bundle `superseded` and open a new one carrying the merged reading.**
The superseded row names its replacement; the replacement carries a `Relates to`
line naming what it replaces. Nothing is edited inside a bundle whose decisions
have been taken against it as it was read, which is the property `in progress`
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

    **Relates to:** `0028` — its finding 2 is the same baseline problem this
    bundle's finding 6 reaches from the other side.

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
from a finding from one the owner simply directed. Revisions 166 and 168 changed
section 4c on the owner's word with no finding behind them, and did not say so;
they are the reason this is written down.

## Session states

A session is a unit of work with an owner. **A session creates its own bundle**,
so it is `owned` from the moment it exists; nothing waits to be claimed. The
other three states are terminal and say how it ended.

| State | Meaning | Produces |
|---|---|---|
| `owned` | An AI session holds it: `Claude` or `Copilot`, the two approved, with when ownership began. | `metadata.md`; `findings-manifest.md` once it owns a finding |
| `handoff` | Ended by transferring its unresolved findings to a successor. | `handoff-<stamp>.md`, one per handover |
| `closed` | Completed. | `final-summary.md` |
| `withdrawn` | The work is no longer viable — drift, staleness, a sudden pivot. | `final-summary.md` |

    owned ──┬─▶ closed        findings resolved, or disowned to `unresolved`
            ├─▶ handoff       findings carried to the successor
            └─▶ withdrawn     findings marked `withdrawn` or `superseded`

**The three terminal states differ by what happens to the findings**, and that is
the whole distinction:

| Ending | Its findings end |
|---|---|
| `closed` | `resolved`, or **disowned and set back to `unresolved`** — still live, simply unowned and waiting for somebody to pick them up |
| `handoff` | carried to the successor at whatever status they hold |
| `withdrawn` | **`withdrawn` or `superseded`**. The work is dead, so the readings die with it |

A closed session finishes and its unfinished readings live on without an owner. A
withdrawn session takes its readings with it, because what made them worth acting
on has gone.

`final-summary.md` records which disposal happened, by name, for every finding
the session owned. **A session may not end leaving a finding owned by a session
that has stopped.**

`unclaimed` was a state until Revision 179 and is gone: it described a bundle
waiting for a session, and no such bundle exists. A prompt written for a
successor lives in the writing session's `handoff-<stamp>.md`; a findings bundle
with no owner shows `—` in its index Session column, which is a property of the
findings bundle rather than a state of a session that does not exist yet.

## Write categories

Which files a session may touch depends on the bundle's status, so the three
kinds are named rather than left to judgement.

| Category | What | When |
|---|---|---|
| **record write** | anything under `docs/` — readings, decisions, resolutions, indexes, session bundles, this file | any status. It is how deciding gets recorded, so it is never gated |
| **toolkit write** | any other tracked file: `bin/`, `.internal/`, the runbooks, `references/`, `templates/`, `.github/`, `.claude/`, the root scripts and env examples | **only during `resolving`**, after every finding in the bundle has a decision |
| **evidence write** | anything under `$REIMAGE_ARTIFACT_ROOT` or `$REIMAGE_WORKSPACE_ROOT` | never, unless the owner has said so for that specific run. A decision to change a script is not a decision to touch the volume |

`APPLY-MANIFEST.md` sits outside `docs/` but accompanies **both** record and
toolkit writes — every change of either kind takes a revision — so it is not a
toolkit write and is not gated.

The three fail differently, which is why the distinction is worth a name. A
record write that turns out wrong is edited. A toolkit write that turns out wrong
has to be found, reverted and re-reviewed. An evidence write that turns out wrong
may be unrecoverable: the artifact root holds dated records of a machine that no
longer exists in that state.

`.github/copilot-instructions.md` sections 4b through 4d predate this vocabulary
and say the same things at greater length. Adopting these three words there is
itself a toolkit write, and is owed.

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
