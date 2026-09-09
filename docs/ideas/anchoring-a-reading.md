# Anchoring a reading

**Written:** 2026-09-09, `assurance-coverage-20260908-204724`, from the owner  
relaying `typed-bundles-architecture-20260908-204724`'s reading of the same  
question `0053` F1 asks, widened from a session's rules to every bundle.  
**Scope:** one field on a reading — the tree it was taken against. **Not** the  
staleness sweep, and **not** whether a stale reading is wrong.  
**Reads against:** [`0053`](../session-management-findings/0053-the-rules-are-versioned-and-a-sessions-reading-of-them-is-not/),
[`0052`](../session-management-findings/0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check/),
[`0043`](../session-management-findings/0043-framework-state-lives-in-documents-not-data/),
[`state-as-data.md`](../architecture/state-as-data.md) §4.3 and §11.4,
[`knowing-what-you-have-read.md`](knowing-what-you-have-read.md).  
**Status:** **a commission. Nothing here is decided and nothing is built.**

**Revision 263 carried this reading into both successor prompts before this
document existed**, at the other session's word that the commission would land
here with the next revision. **The prompts are the brief and this is the home**:
a prompt is spent when its session opens, and a commission outlives it. Where the
two disagree on a number, this file was measured later and against a named tree —
its decision total is 130 where the prompts say 129, because `0053` D5 landed in
between.

**This is not `knowing-what-you-have-read.md` restated.** That document asks
whether a **session** can be told that a **rule document** it read has moved; its
object is the foundational set and its trigger is a refresh. This one asks what
tree a **bundle's reading** was taken against, for all 54 bundles, whether or not
anything has moved since. One is a notification; the other is a datum. The first
is not buildable without the second, which is the only reason both exist.

---

## The property, and the cost that comes with it

A reading is written once and never rewritten to match what was later decided.
That is the framework's most valuable guarantee: it is what makes the record a
memory rather than a rationalisation, and it is why the sessions whose readings
went stale today **were not wrong** — every one of them was true when written.

The same guarantee is, exactly, a guarantee that readings go stale. The tree
moves; the reading does not. Nothing in it says which tree it was read against.

**Immutability without a datum is how a memory becomes a museum. The exhibits are
authentic and nothing says which century.** That sentence is the other session's
and it is the whole finding.

## Measured on this tree, at `f345f3e` (Revision 263)

| | |
|---|---:|
| `metadata.json` files, bundles and sessions | 65 |
| distinct `schemaVersion` values across all 65 | 1 |
| bundles with a non-empty `read` | 16 of 54 |
| findings carrying `updatedAt` | 54 of 183 |
| decisions carrying `answersAsOf` | 7 of 130 |
| **fields naming the tree a reading was taken against** | **0** |

## Two corrections worth making before this becomes a plan

**`schemaVersion` cannot carry the anchor.** It is `1` on all 65 files, and
`state-as-data.md` §11.4 says what it is for: the migration in §9 "is the first of
at least two and the second will want to know what it is reading." It versions
the shape of the file, not the state of the tree. A reading taken this morning and
one taken thirty revisions from now both say `1` — it cannot separate them, which
is the entire question.

**`recordedOn` is a date, and a date is not an anchor here.** 2026-09-09 alone
produced roughly twenty revisions, so a date places a reading inside a window of
twenty trees.

## The mechanism already exists, on the wrong half of the object

`answersAsOf` is `state-as-data.md` §4.3's answer to this question for
**decisions** — "a decision whose `answersAsOf` is older than its finding's
`updatedAt` was answered against a statement that has since changed, and
`--check` flags it." Designed, correct, and populated on **7 of 130**.

And `resolution.commit` — populated on **33 of 73** resolutions — already anchors
an outcome to a tree. So the schema has the pattern twice.

**Both anchors are on what a bundle did. Neither is on what it saw.** The
framework can say which commit a repair landed at and cannot say which commit the
reading that motivated it was taken against. That asymmetry, not a missing habit,
is why the anchor has never been written.

## The shape of the field

One field, the commit, **written at record time**, in the same discipline as
`answersAsOf`. Then *this was read against a tree 31 revisions ago* becomes
derivable rather than discovered.

It does not violate the property. Nothing is rewritten; the reading stays exactly
as written and only the anchor is added, at the moment of writing.

**What it buys, in the order it pays out:** a session opening a bundle knows
immediately whether to re-read it or trust it; the staleness sweep stops being a
judgement campaign and becomes a report; and the reading that turns out to have
been correct at the time can be shown to have been, instead of argued to have
been.

## The false positive to expect first

**Every one of the 54 bundles is unanchored today, so the first run of any check
reads as 54 failures and none of them is a defect.** An anchor can only be written
at record time, and no reading already in the tree can acquire one honestly. A
check that treats a missing anchor as a failure would begin by condemning the
entire record — and backfilling to silence it would be the one act this whole
document exists to prevent, because a backfilled anchor is a guess presented as a
fact.

So the anchor is required on **new** readings and reported, never failed, on
existing ones — and the report names the count without naming the bundles, because
a list of 54 is a campaign and a number is a datum.

## Where this belongs, and why it is not decided here

`0052` F1 widened — *nothing re-verifies that a resolution still holds* becomes
*nothing anchors a reading at all*. The schema half is `0043`, whose open question
11.1 feeds it.

**Neither bundle was reachable by the session that found this**, and neither is
this one's: `0052` was unclaimed at the time of writing and is being assigned to
`typed-bundles-architecture`'s successor; `0043` is held by a session in `handoff`
with no successor. That is the third thing in one day blocked on a bundle nobody
can open, and it is worth recording as its own fact rather than as an aside.

This document exists so the successor inherits the question and not the wrong
answer.
