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
| D2 | The instrument is the resolver that already exists, corrected — `HISTORICAL` moves below the resolution fallbacks and becomes `DECAYED`, meaning *cited by a record and no longer there*. No second checker, and the reading half is declared irreducible rather than implied covered | F1 | 2026-09-10 | `accepted` |
| D3 | Coverage reads the manifest SET, `APPLY-MANIFEST*.md`, rather than the current file; and a rollover owes the same naming of readers that a format change owes of records | F3 | 2026-09-12 | `accepted` |
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

## D2 — the signal was already being computed and half of it was mislabelled

`bin/verify-doc-paths.sh` resolves every citation in the repository. In a
document carrying `<!-- historical-record -->` its `HISTORICAL` branch sat
**above** the fallbacks that resolve a bare filename, so **any** cited name in
such a document was counted historical — whether or not it still resolved.

**Measured: 70 HISTORICAL, of which 34 resolve.** `verify-doc-paths.sh` is one of
them: the checker was counting its own name as a citation of a file that no
longer exists.

**One reordering.** Resolution is tried first; `PROPOSED` and the historical
marker are consulted only when nothing resolves. The count then means *cited by a
record **and no longer there***, which is a property of the tree rather than of
the document, and it is renamed **`DECAYED`** because it now says something a
reader can act on.

**Round trip, before and after, `--all` over 271 documents** — Revision 277's
clause applied to the revision that follows it:

```text
OK        2271 -> 2305      (+34, the mislabelled ones)
HISTORICAL  70 -> 36 DECAYED
PROPOSED    13 -> 13        unchanged
MISSING      3 ->  3        identical rows, verified line by line
WARN / SKIP / ANCHOR        unchanged
```

**36 decayed citations, and six relocations account for nearly all of them.**
Three checkers into `.internal/`, one into `.share/`, two `.github/` directories
renamed, one script into `bin/`. **Every rule those resolutions installed is
alive.** This is `0038`'s re-verification at Revision 270 measured across the
whole tree instead of one bundle, and it says the same thing: **the commoner
failure is not a resolution reverted but a resolution still true and no longer
findable.**

**What the instrument does not answer, stated rather than implied.** Whether the
rule a resolution installed still holds. That took a session reading six
resolutions against the tree at Revision 270 and judging each — two held, three
named a moved home, one had never been written down. **Only the middle three are
mechanical.** The rest is a reading and there is no instrument for it; F1's
question *how many are false* stays a question a session answers, and this
decision narrows what it has to read rather than replacing it.

**Rejected — a new checker over `resolutions.md`.** Written first, as a
prototype, before this decision. It reported **63 unresolved citations of 156**,
and most were its own fault: `APPLY-MANIFEST.md` treated as relative to the
bundle, bare script names not looked up in `bin/`. **The eighth instrument in this
repository to fail loudly on first contact, and the second caught before it
shipped** — Revision 280's rule, obeyed. The resolver has one home and writing a
second one produced a worse one in ten minutes.

**Rejected — fail the run on `DECAYED`.** It is not a defect in the record.
Repairing the citation would falsify what the record says was true at the time,
which is what the marker exists to prevent, and §7 and §9 are explicit that
records are not retro-edited. A count that can only rise and can never be cleared
is `0047` F9, ruled on twice already.

**Rejected — leave `HISTORICAL` as it was and add a second count beside it.** Two
labels for one condition, one of them wrong. The old count was not a coarser
version of the new one; it was measuring the document instead of the tree.

**Rejected — repair the 36.** The one act the marker exists to prevent. A
resolution names the path as it stood; that is the record of what was done, and
`0038` D5 refused the same move for the same reason — **moving a working tool to
make a retained document accurate inverts which of the two is authoritative.**

## D3 — read the set, and name the readers before the roll

**The instrument half is a glob.** `bin/verify-manifest-coverage.sh` collects every
`APPLY-MANIFEST*.md` under the repository root, greps the set rather than one file,
and passes the same pattern to the `git log` pathspec that finds which commit
introduced an entry. **An entry never leaves the set, only the current file**, which
is the sentence the script now carries at the top of the change.

**Verified in both directions, as §6 requires of anything that can fail loudly.**
Against the whole tree it reports **MISSING 0, ORPHANED 6, DUPLICATE 1** — not
merely fewer than 79 but **identical to the last figures taken before the roll**,
which is the stronger claim and the one that distinguishes a fix from a
suppression. Against a case it should catch — one entry removed from the archive in
a throwaway copy — **MISSING goes to 1**.

**Rejected: pointing the script at the archive by name.** It would work today and
fail at the second rollover, which is the same defect with a later date on it.
**Rejected: keeping a pointer file naming the current manifest**, which is a second
copy of a fact the filesystem already holds. **Rejected: treating this as `0050`'s**
— that bundle is about instruments that cannot fire; this one fired correctly on a
subject that had been halved underneath it.

**The rule half is recorded and not built.** A format change is gated on a
migration plan naming what happens to existing records. **A rollover needs the
complementary question — who reads this path — and nothing asks it.** The two are
not the same: the gate protects records, and what broke here was a reader. Naming
it is §6's and §7's, and neither is decided here.

