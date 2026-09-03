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
| `superseded` | A later bundle replaces this reading. The row names which. | — |

    unresolved ──▶ in progress ──▶ resolving ──▶ resolved
                                     │
                                     └─▶ superseded (from any status)

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

## Session states

A session bundle is a unit of work with an owner. The state says who has it and
what stage the handover is at.

| State | Meaning | Produces |
|---|---|---|
| `unclaimed` | No AI session owns it. The prompt is written and waiting — either the owner wrote it, or a running session prepared it for work with no scheduled start. | `prompt.md` |
| `owned` | An AI session owns it: `Claude` or `Copilot`, the two approved, with when ownership was established. | `findings-manifest.md`, once it owns a finding |
| `handoff` | The work is passing between sessions. Covers the bundle being handed over **and** a continuation prepared by a running session, until it is owned. | `handoff-<stamp>.md`, one per handover |
| `closed` | The owner has determined the work is complete. | `final-summary.md` |
| `withdrawn` | Work may have been done, but the owner has decided to pivot or to leave findings unresolved rather than finish. | `final-summary.md` |

    unclaimed ──▶ owned ──▶ closed
                    │  ▲
                    │  └── owned (the next session)
                    └─▶ handoff ──▶ unclaimed / owned
                    └─▶ withdrawn

`closed` and `withdrawn` are both terminal and both write `final-summary.md`.
The difference is what it has to say. A closed session lists every commit hash
and `APPLY-MANIFEST.md` revision it contributed. A withdrawn one lists that too,
and then the part that matters more: what the work reached, which findings are
still open and at what status, what was assumed, and why it stopped. A withdrawn
session that recorded nothing is indistinguishable from one that did nothing,
and the findings it leaves behind are the ones somebody picks up cold.

---

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
