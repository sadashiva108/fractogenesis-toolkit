# Vocabulary — every closed set IRIS uses

> **Role.** What each word *means*. Every genus, shape, status, standing,
> progress value, state, outcome, edge kind and reason, in one place.
>
> **Authoritative for** meaning. **Not** authoritative for when something is
> allowed — that is [procedure.md](procedure.md) — nor for what any value
> currently *is*, which is the record itself.
>
> **The tiebreak is the code.** Where this file and
> `lib/plan_findings_work.py` disagree, the code is what the data was stamped
> from, and this file is the defect. Every set below was read out of the code on
> 2026-09-09.

**The vocabulary is not guessable.** Nothing else in IRIS parses without this
file, which is why it is second in the reading order and why nothing else
restates a definition from it.

## Contents

- [1. The rule that governs all of it](#1-the-rule-that-governs-all-of-it)
- [2. Genus and shape](#2-genus-and-shape)
- [3. Member statuses](#3-member-statuses)
- [4. Progress and standing](#4-progress-and-standing)
- [5. Ownership and lineage](#5-ownership-and-lineage)
- [6. Session states](#6-session-states)
- [7. Decision outcomes](#7-decision-outcomes)
- [8. Edge kinds](#8-edge-kinds)
- [9. Reasons](#9-reasons)
- [10. Write categories](#10-write-categories)
- [11. What another session may do](#11-what-another-session-may-do)
- [12. `Relates to`](#12-relates-to)
- [13. What is validated, and what is not](#13-what-is-validated-and-what-is-not)

---

## 1. The rule that governs all of it

**No value belongs to two sets.** A bare word says which vocabulary it came
from: `framing` is a member, `analyzing` is a bundle, `handoff` is a session,
`accepted` is a decision, `carried` is an edge.

That is why `resolved` and `answered` are different words for what looks like the
same idea. A **member** reaching its end is `resolved`. A **bundle** whose
members have all reached theirs is `answered`. One word for both would make every
sentence ambiguous about which layer it is describing, and the tree spent three
revisions in that state before the rule was written.

**A member has a `status`. A bundle has a `standing` and a `progress`. A session
has a `state`.** Four nouns, four sets, and a check asserts the sets stay
disjoint.

**Derived values are never typed.** `standing`, `progress` and `state` are
written by `plan-findings-work.sh stamp` and by nothing else; `check` reports
`UNSTAMPED` for a null and `STORED-DISAGREES` for a value that has come adrift. A
hand-edited standing is a defect the next `check` names.

[&#8593; Contents](#contents)

## 2. Genus and shape

**A bundle is a numbered directory of members.** The `genus` says what sort of
bundle it is. **Four genera, and the genus is stored.**

| Genus | Members are | Poses | Produces |
|---|---|---|---|
| `findings` | findings, `F1..Fn` | *what is true about something that exists* | an answer per finding — a defect explained, or a fact established |
| `commission` | questions, `Q1..Qn` | *we want X — what shape should it take* | a **blueprint**, under `architecture/` |
| `charter` | tasks, `T1..Tn` | nothing; it builds to a blueprint | changes |
| `remedy` | tasks, `T1..Tn` | nothing; it repairs | changes |

**Two shapes, and the shape is DERIVED, never stored.**

| Shape | Genera | Needs | May decide |
|---|---|---|---|
| `reasoning` | `findings`, `commission` | **breadth preservation** — narrowing is its whole activity | yes |
| `actionable` | `charter`, `remedy` | **verification** — the outcome is known in advance | see below |

**The member id carries the genus in its prefix** — `F`, `Q`, `T` — so a member
cited out of context still says what it is. A bundle whose members disagree with
its genus raises `MEMBER-PREFIX`.

**`charter` and `remedy` differ on three things**, and the third is a permission
rather than a field, which is why they are two genera and not one with a flag:

| | `charter` | `remedy` |
|---|---|---|
| measured against | a **blueprint that exists outside it** and outlives it | its own reason — the finding is the spec |
| item ordering | tasks are a plan; the foundation precedes the roof | independent, any order |
| **may amend what it builds from** | **yes** — building reliably discovers the design is wrong | **no** — it opens a finding and stops |

**`kind` is a different field and means the subject domain**, not the shape. It
carries `runbook`, `cross-cutting`, `instruction-set`, `session-management`. It
is not the genus and never has been.

[&#8593; Contents](#contents)

## 3. Member statuses

**Six, and the status says how far a reading has been taken — never how anyone
feels about it.**

| Status | Meaning | Who may read | Who may record |
|---|---|---|---|
| `un-started` | Recorded, never read. | the owning session only | — |
| `framing` | Live and open. The reading, the wording, and the decisions are all still being worked. | any session | **any session** |
| `decided` | Every decision is made. The owner resolves it from here. | any session | the owning session only |
| `resolved` | Done. Frozen. | any session | nobody |
| `reopened` | A `resolved` member put back in play. **Takes a reason.** | the owning session only | — |
| `withdrawn` | Shut down. No further work, ever. | any session | nobody |

**A member is `inert` when it is `resolved` or `withdrawn`** — finished either
way. The other four are live.

**`framing` is the long one and it runs both ways.** It is not a staging post; it
is where the work happens. Any session may sharpen a `framing` member, correct
it, remove it if it does not hold, **and write, reject or refine a decision on
it.** Deciding is not the owner's privilege; *closing* the deciding is, and that
is the only thing `decided` marks.

**A status moves on a material change to the record, and a read is not one.**
Assignment does not move it. A sweep does not. A rename does not. Each of those
touches a status without a judgement being formed, and each is a mass operation,
so a wrong one damages every member it passes over.

[&#8593; Contents](#contents)

## 4. Progress and standing

**Both derived from the members, and they answer different questions.**
`progress` is the reading alone and is true whoever owns the bundle. `standing`
is that with ownership and lineage put back in.

**`progress` — first row that matches wins:**

| # | `progress` | When |
|---:|---|---|
| 1 | `untouched` | every member is `un-started` |
| 2 | `retired` | every member is `withdrawn` |
| 3 | `answered` | every member is inert, and at least one is `resolved` |
| 4 | `revisited` | at least one member is `reopened`, and every other is inert |
| 5 | `analyzing` | anything else. **It is the fallthrough**, so a derivation bug lands here looking plausible |

**`standing` — read in this order:**

| If | Then `standing` is |
|---|---|
| `lineage.supersededBy` is set | `superseded` |
| `ownership` is set | that value — `unclaimed` or `transferred` |
| `progress` is `untouched` and a session owns it | **`assigned`** |
| otherwise | whatever `progress` says |

`assigned` is the one value `standing` has that `progress` does not; `untouched`
the one `progress` has that `standing` does not.

**`revisited` fires only when reopening is the whole of the live work.** A
reopened member beside a `framing` one is a genuinely mixed bundle, and that is
`analyzing`.

[&#8593; Contents](#contents)

## 5. Ownership and lineage

**Ownership is derived by scanning the session manifests** — adding the row *is*
the assignment, removing it *is* the release. The `ownership` field carries only
the two declared exceptions:

| | |
|---|---|
| `unclaimed` | no session owns it. Closed to everyone until the owner assigns it |
| `transferred` | handed to a named session that has not yet written to it **as owner** |
| *(null)* | owned normally, or finished |

**`superseded` is declared**, not derived from members: a later bundle replaced
this reading whole. It reaches a bundle at any standing, and the superseded
bundle is **readable by any session and writable by none**, including its owner.

[&#8593; Contents](#contents)

## 6. Session states

| State | When | Produces |
|---|---|---|
| `available` | Created, owning no bundle yet | `metadata.md` |
| `active` | Owns at least one bundle that is not finished | `manifest.md` |
| `handoff` | Passed its qualifying bundles to a successor. **Declared** | `handoff-<stamp>.md` |
| `closed` | Every bundle it owns is terminal or released | `final-summary.md` |
| `dissolved` | Every bundle it owns is `withdrawn` | `final-summary.md` |

`handoff` is the only state a session declares; the rest follow from what it
owns.

**`dissolved` and not `withdrawn`.** A session's terminal shutdown and a member's
carry the same idea and may not carry the same word. The member sense stayed
because it is the more specified and the more embedded — a procedure, nine
reasons, a revert requirement, and a place in `INERT` and in two rows of the
progress ladder. The session sense was one table row. **When two words collide,
move the cheap one.**

[&#8593; Contents](#contents)

## 7. Decision outcomes

**Statuses are adjectives about a condition — *where is this?* Outcomes are
past-participle verbs about an act — *what was done to this?*** No word appears
in both sets, and a test asserts it.

| Outcome | Means | Pointer |
|---|---|---|
| `proposed` | on the table; nobody has ruled. **This is a dart** | — |
| `accepted` | adopted — this is what will be done | — |
| `rejected` | turned down on the merits | — |
| `deferred` | cannot be ruled yet; what it waits on is named | required |
| `retracted` | the proposer withdrew it before a ruling | — |
| `replaced → DX` | a later decision answers the same question instead | required |
| `voided` | was `accepted`, then invalidated because its foundation moved | reason required |

**`proposed` is stored rather than left empty**, so an unset outcome is a load
error and not a reading. **A rejected decision keeps its row and its section** —
that is the record of what was considered, and deleting it leaves an assertion.

[&#8593; Contents](#contents)

## 8. Edge kinds

**An edge is addressed at member granularity** — `0037/F8`, not `0037` — and is
stored in one bundle only. Twelve kinds carry a weight; the weight is what the
allocator pulls on.

| Kind | Means | Weight | In the tree |
|---|---|---:|---:|
| `co-decides` | one decision answers both | 6 | 4 |
| `contradicts` | A's answer denies B's. **A failed trial** | 6 | 0 |
| `duplicates` | the same reading twice | 6 | 0 |
| `blocks` | B cannot be decided until A is | 4 | 5 |
| `evidences` | A's resolution produces what B needs. **A passed trial** | 4 | 0 |
| `constrains` | A's answer bounds B's | 3 | 3 |
| `generalises` | A is the general case of B | 3 | 0 |
| `successor` | retained, and substantially changed | 3 | 2 |
| `carried` | comes over unchanged | 2 | 29 |
| `shares-surface` | both touch the same file | 2 | 0 |
| `relates-to` | bears on, and obliges nothing | 1 | 16 |
| `supersedes` | replaced whole | 1 | 0 |

**Five are `hard`** — `blocks`, `evidences`, `co-decides`, `contradicts`,
`duplicates` — meaning the allocator treats them as constraints rather than
preferences.

**Three provenance kinds carry no weight and appear nowhere**: `split`, `merged`
and `dropped`, used when a bundle is superseded. `new` is **derived from the
absence of an incoming edge** and is never stored.

**Trials use `evidences` and `contradicts`.** A candidate that survives a test
gains an `evidences` edge; one that fails gains `contradicts`. Confidence in a
surviving option is therefore countable, and a decision whose alternatives were
rejected on argument alone is visibly weaker than one whose alternatives were
killed by a trial. **Both are at zero today**, so nothing in the tree has yet
been tested this way.

[&#8593; Contents](#contents)

## 9. Reasons

**Four transitions take a reason from a closed set.** The reason is a field
rather than prose so a later reader can group by it — see section 11 for how far
that is true today.

**Reopening** — `resolved ──▶ reopened`. **The reason determines the exit**,
which removes a judgement call at the moment someone is already annoyed.

| Reason | What it says | Exits to |
|---|---|---|
| `resolution-defective` | the work was done and is wrong | `decided` |
| `resolution-incomplete` | done, and does not cover the member | `decided` |
| `resolution-had-side-effects` | it worked, and broke something else | `decided` |
| `resolution-not-applied` | the record says resolved; the tree disagrees | `decided` |
| `resolution-regressed` | applied, and a later change removed it | `decided` |
| `resolution-unverifiable` | the claim cannot be checked | `decided` |
| `decision-wrong` | the decision it carried out was wrong | `framing` |
| `decision-inapplicable` | the decision's target no longer exists | `framing` |
| `framing-wrong` | the problem statement was wrong | `framing` |

A fault in the **work** leaves the decision standing. A fault in the **decision**
or the **framing** returns it to `framing`.

**Rolling back** — `decided ──▶ framing`. Not every reason voids something.

| Reason | Effect on decisions |
|---|---|
| `framing-changed` | **every** accepted decision → `voided` |
| `decision-wrong` | **that** decision → `voided` |
| `decision-inapplicable` | **that** decision → `voided` |
| `decided-prematurely` | none — `decided` was the error |
| `new-information` | none yet; decisions flagged to re-evaluate |

**Provenance dispositions**, when a bundle is superseded: `already-resolved`,
`no-longer-applies`, `absorbed → F<n>`, `out-of-scope`,
`owned-elsewhere → <bundle>/<id>`; and for `successor`, one of `restated`,
`narrowed`, `widened`.

**There is no `unable-to-resolve`.** Reopening is reachable only from `resolved`,
so a member nobody can resolve never arrives at that door: it stays `decided`, or
it is `withdrawn`.

[&#8593; Contents](#contents)

## 10. Write categories

Four kinds, told apart by what is being written.

| Category | What it is | Fails by |
|---|---|---|
| **record** | a write under the record root | writing again |
| **toolkit** | a write to any other tracked file | being reverted |
| **evidence** | a write to the artifact volume | **possibly not at all** — evidence records a state of the world that no longer exists |
| **`foreign`** | a write to any other connected folder | not IRIS's business, and **not recorded** |

`foreign` is named so the case is excluded deliberately rather than by omission:
an unnamed case reads as *not covered* and behaves as *not thought about*.

[&#8593; Contents](#contents)

## 11. What another session may do

**The owning session reads member statuses directly — it is already inside.**
Every other session checks the bundle's standing first, then the member.

| Bundle standing | Then, inside it |
|---|---|
| `superseded` | **readable by any session, writable by none** — including the session that owns it. The reading is retained precisely so it can be read |
| `assigned`, `unclaimed`, `retired` | nothing is readable |
| `analyzing`, `revisited`, `answered` | `framing` — read and record · `decided` — read only · `resolved` — read only · `un-started`, `reopened`, `withdrawn` — not readable |

An `assigned` bundle offers nothing to anyone but its owner by definition: every
member is `un-started`, and the owner's first reading is what opens them.

**Three rows, no tie-break needed — and the table is incomplete.** There is **no
row for `transferred`**, which is the standing under which a non-owner has been
directed to contribute at least three times. The answer exists elsewhere — the
three statuses awaiting a first read are invisible to every session but the owner
— but it is stated in a section about member statuses, for the one value in that
group that is a bundle standing. `0039` F25 owns it.

**Two cells disagree with section 3 and are deliberately left alone.** A
`retired` bundle holds nothing but `withdrawn` members, and section 3 makes a
`withdrawn` member readable by any session — so *nothing is readable* cannot be
right for it, and the third row says the same thing again where it ends
`withdrawn — not readable`. **Which side is right is a reading, not a repair.**
`0039` F21 owns it.

[&#8593; Contents](#contents)

## 12. `Relates to`

A bundle may name another it bears on without either replacing the other.

**It is a pointer and nothing more: it creates no ownership, moves no status, and
obliges nobody.** It exists because two readings of one mechanism from different
angles are common, and a reader who finds one should be able to find the other.
`superseded` uses the same field to name what it replaced.

[&#8593; Contents](#contents)

## 13. What is validated, and what is not

**A closed set is only closed if something closes it.** Measured 2026-09-09:

| Set | Validated | By what |
|---|---|---|
| member statuses | **yes** | `VOCAB` in `check`, plus the suite |
| genus | **yes** | `VOCAB`, added with the genus itself |
| member prefix against genus | **yes** | `MEMBER-PREFIX` |
| progress, standing, state | **yes** | `stamp` writes them; `check` reports `STORED-DISAGREES` |
| ownership | **yes** | `VOCAB` |
| decision outcomes | **yes** | `VOCAB`, with `replaced` matched by prefix |
| **edge kinds** | **NO** | there is no closed set. `W.get(kind, 1)` gives an unknown kind weight 1 and it passes silently |
| **every reason** | **NO** | **not one of the nine reopen reasons, five rollback reasons or eight provenance reasons is enumerated anywhere in code** |
| shape | n/a | derived from genus; a stored shape is ignored |

**Those two rows are the honest state of this file.** Section 9 says a reason is
a field *so a checker can validate it*, and no checker does. Section 8 lists
twelve edge kinds and a thirteenth would be accepted without complaint. Both are
recorded here rather than quietly omitted, because a vocabulary that claims to be
closed and is not is worse than one that admits where it is open.

**Six of the twelve edge kinds have zero instances**, and two of those six —
`evidences` and `contradicts` — are the pair that makes a trial recordable. The
machinery is present and unexercised.

[&#8593; Contents](#contents)
