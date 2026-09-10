# Decisions — a change that invalidates earlier work has neither a plan nor a check

**Bundle:** `0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check`  
**Session:** `drift-and-the-write-boundary-20260909-053548`  
**Decided:** 2026-09-10

**The rule below is derived rather than invented.** F2 was written from four
instances where a format change went unplanned. **Two have gone right since it
was written** — Revision 271's genus migration and Revision 273's value rename —
and every clause here names the revision that already did it. That is the same
method `0038` used: read what the tree does before writing what it should.

## Decisions

| # | Decision | Members | Decided | Outcome |
|---|---|---|---|---|
| D1 | A write that makes existing records non-conformant is gated on a **migration plan** as well as on the finding. The test is whether a checker would report existing records as failures — not whether the author calls it a format change. A plan names five things, and one format change goes per revision | F2 | 2026-09-10 | `accepted` |

## D1 — the gate, the test, and the five things

The rule lands in **§6** of `.github/session-management-instructions.md`, beside
the three gates already there, because it is a further condition on one class of
toolkit write rather than a new kind of ceremony.

### The test is about the tree, not about the author

F2 reaches for *"a format change does; a wording change does not"* and says where
that line falls is what it owes. **The line is not there.** All four instances it
records were made by authors who did not believe they were changing a format —
Revision 162 converted parked notes, Revision 203 ran a schema pass, Revision 224
declared a clean slate, and `0037` D2 restored a carve-out. **A test that asks
the author to classify their own change fails exactly when it is needed.**

So the test is: **would a checker report existing records as failures after this
change?** It is a question about the tree, it is answered by running the checks
against a copy, and it does not depend on what the change is called.

**Its cheapest half is counting.** Revision 268 retired two decision outcomes and
added four, having first read all 129 decisions in the tree and found two values
in use — `accepted` and `replaced → DX`. **That measurement is what turned *no
plan needed* from an assumption into a fact**, and it cost one query. A change
claiming no plan says what it counted.

### The five things, each with the revision that already did it

1. **What predates the change**, counted from the data.
2. **Retrofitted or exempted per class, retrofit as the default.** An exemption
   needs a reason, and the accepted reason is narrow: where what is missing
   records a **deliberation or a measurement that never happened**. `0037` D2 and
   `0047` D1 are that reason applied to ten bundles. **F2's own sentence is the
   ruling** — *the retrofit is the default and the exemption is the thing that
   needs a reason, which is the reverse of how all four instances were handled.*
3. **Where the exemption is written**, so the exempt class is not reported
   forever. `0047` F9 is that failure from the other end: eight rows in two
   `superseded` bundles nobody may write to, permanent by construction.
4. **A script, self-locating and idempotent — not a hand edit.** Revision 271's
   migration was **rebased twice while in review** and re-run rather than redone;
   its second pass reported `migrated 0 of 54; 54 already conformant`. **`0038`
   F1 is why this is not a nicety**: the tree moves under a composition, and a
   migration that cannot be re-run decays while it waits for the owner.
5. **A round trip, before and after, compared.** Revision 271 derived `standing`,
   `progress`, `ownership`, every member id with its status and every decision's
   outcome and citations across all 54 bundles — **195 rows, identical.** A
   checker answers whether the tree is well formed; **only the round trip answers
   whether it still says the same thing.**

### One format change per revision, and as early as possible

Revision 271 added `genus`, renamed `findings[]`, and **deliberately left `kind`
alone** though the same design changes its meaning too — because moving `kind` in
the same revision would leave no fixed point to verify either rename against. And
it renamed the members array *"before a second genus existed, and that is the
entire reason it was done today"*: **a change known to be coming goes before the
thing that would multiply it**, and the revision says so.

### Rejected — require a plan for every change

F2 refuses this in its own last paragraph and it is right to. Most revisions
change no record's shape. A gate that fires on all of them is one sessions learn
to satisfy formally and stop reading, which is `0047` F6's argument about guards
arriving in the write-gating column.

### Rejected — classify changes as *format* or *wording*

The phrasing F2 reaches for, and the reason it stopped there. It asks the author
for the judgement the four failures show authors do not make. **The conformance
test replaces a judgement with a run.**

### Rejected — put it in §7, with the revision procedure

A migration plan accompanies a revision, so §7 is the obvious home. Two reasons
against. **§7 is not this session's to write** under the Revision 261 boundary,
which grants §§0 and 6. And the rule is a **gate on a write** — the same shape as
*a toolkit write is gated on a `decided` finding* — so §6 is where a reader
already looks for whether a write may happen at all.

### Rejected — build a check instead of writing a rule

The attractive answer and the premature one. A check would have to know which
changes make records non-conformant **before the change is made**, which is the
judgement being decided here. `0047` F6 requires a guard to be installed
warn-only until a clean pass, and there is nothing yet to pass against: **the
rule has to exist and be followed a few times before an instrument can be
measured against it.** Owed, not built, and it belongs with `0038` F7's four.

### Rejected — require only the round trip

It is the strongest single clause and it is not enough. A round trip proves the
tree still says the same thing about **records the migration touched**. The four
instances F2 records are the opposite failure: **a class that predates the change
and is never touched at all**, which a before-and-after comparison finds
identical and correct.
