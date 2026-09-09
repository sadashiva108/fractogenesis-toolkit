# Decisions — the tree carries status drift that no check looks for

**Bundle:** `0047-the-tree-carries-drift-no-check-looks-for`  
**Session:** `typed-bundles-architecture-20260908-204724`  
**Decided:** 2026-09-09

## Decisions

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | The migrated-bundle carve-out is restored to `.github/session-management-instructions.md` §3: a bundle migrated from an already-closed record carries `resolutions.md` and no `decisions.md`, and its `resolutions.md` says so. **This is `0037` D2, taken once and recorded in both bundles** | F4 | 2026-09-09 | `accepted` |
| D2 | `transferred` leaves the closed-bundle assertion in `plan_findings_work.py` entirely; `unclaimed` keeps it, and its detail names `0047` F1 as the undecided rule the row rests on. The code name is unchanged | F7 | 2026-09-09 | `accepted` |
| D3 | `OUTCOMES` becomes the legend's six bare outcomes with `replaced` matched by prefix; the two retired prefixes go; and a contract test asserts the disjointness `docs/legend.md` has claimed a schema check performs since Revision 233 | F8 | 2026-09-09 | `accepted` |
| D4 | F5 is recorded `resolved` against the work that already answered it — `is_clone()`, shipped at Revision 231 — rather than re-done; what the remedy did not cover is opened as F9 and F10 instead of being folded into the resolution | F5 | 2026-09-09 | `accepted` |

**D1 was decided by the session in the header. D2 and D3 were decided by
`drift-and-the-write-boundary-20260909-053548`**, which owns this bundle from
Revision 261. The header carries one `Session:` field and the table has no
column for it, so the sentence is where that fact can go — and **the schema has
no place for it at all**, which is recorded as a contribution to `0039`.

## D1 — the ten owe nothing, and the rule says so again

F4 reads the ten bundles as a class whose answer *"is probably that they owe
nothing, and it is not this bundle's to give."* It was this bundle's to give
after all, because the answer is the same sentence `0037` F5 needs and the two
findings are one reading in two bundles.

**Rejected — write a `decisions.md` into each of the ten.** It would invent
deliberation that never happened. F4 says so itself, and the evidence rule it
appeals to is the one the owner's standing retrofit preference stops at: retrofit
older records to the current shape wherever possible, **and this is where it is
not possible**, because what is missing records a deliberation rather than a fact.

**Rejected — decide it in `0037` alone and leave F4 open.** F4 would then be a
finding whose answer had been carried out with nothing in this bundle recording
it, which is F3's defect in this same bundle — a resolution ahead of the status
it implies.

**Rejected — one decision, cited from both.** §11 requires every `D<n>` a
resolution cites to exist in its own bundle, so a row here citing `0037` D2 would
resolve to nothing. The decision is recorded twice and the relationship is the
edge: `0037/F5 co-decides 0047/F4`, asserted at Revision 252.

**What is owed instead**, and it is not this decision's to give: a **migration
plan requirement** for breaking changes, so the next format change states what
happens to what predates it rather than leaving it to be found. `0052` F2.

## D2 — a transfer is a permitted operation, so the check stops calling it a failure

`b.get("ownership") in ("unclaimed", "transferred")` becomes
`b.get("ownership") == "unclaimed"`. Nothing else about the row changes.

**Why the two halves separate.** `docs/legend.md` says a bundle may be
transferred while it stands `assigned`, `revisited` or `analyzing`, and §10 says
the same; an `analyzing` bundle has findings past `un-started` by definition. So
the `transferred` half asserted the negation of a documented rule. The
`unclaimed` half asserts something no document says at all — what happens to a
finding when its bundle is released is `0047` F1, and F1 is `un-started`. The
first is wrong; the second is unfounded. **They are not the same defect and they
do not take the same remedy.**

**What the `unclaimed` half now says.** The detail text names F1 and calls it
undecided, so the report tells the owner what it is looking at rather than
implying a settled rule. `cmd_graph` already prints the same state under an
explicit `0047 F1` citation; the conformance row now matches it.

**Rejected — remove the assertion outright.** F7 says *"whichever way F1 is
decided, this check is asserting it before anyone has"*, and deleting the row
would be a second way of deciding F1 before anyone has: it would stop the tree
reporting a state that is real, on the strength of a rule that has not been
written either way. **A citation costs one clause; a deletion costs the signal.**

**Rejected — rename the code to `UNCLAIMED-LIVE-FINDING`.** The name would be
sharper once `transferred` leaves, and three `APPLY-MANIFEST.md` entries name the
current code — Revisions 248, 257 and 261 — and entries are never retro-edited.
The rename would buy clarity in one report and spend it in the record. `unclaimed`
is the legend's own *closed to every session*, so the name is accurate as it
stands.

**Rejected — keep `transferred` and exempt a bundle whose transfer is recorded in
`metadata.md`.** It makes a permitted operation conditional on a document the
check does not read, and §10 gates the transfer on nothing. It also converts a
wrong assertion into a slow one.

**Rejected — wait for F1 and fix both halves in one decision.** F7 is not F1. The
`transferred` half is wrong however F1 goes, and the tree is reporting five
permitted operations as failures now, one of them the transfer of this very
bundle to the session holding this finding.

**What this does not do.** It does not decide whether an `unclaimed` bundle may
hold a live finding. That is F1's, it is `un-started`, and this decision is
careful to leave it exactly as open as it was.

## D3 — the outcome vocabulary becomes the legend's, and something asserts it

```text
OUTCOMES = ("proposed", "accepted", "rejected", "deferred", "retracted", "voided")
POINTER_OUTCOMES = ("replaced",)             # `replaced -> DX`, pointer required
...
if o not in OUTCOMES and not o.startswith(POINTER_OUTCOMES):
```

Six bare words listed, the seventh matched by prefix because it carries a
pointer. `refined` and `superseded` go, being the two Revision 233 retired.

**Safe against the tree, and checked before it was written.** Across 53 bundles
there are 129 decisions carrying two distinct outcome values: `accepted` (126)
and `replaced → DX` (3). **No decision anywhere uses `refined → DX` or
`superseded → DX`**, so removing them refuses nothing that exists. The one
literal `superseded → D5` in the tree is prose inside `0039`'s D9 section
recording the retirement, not a table cell.

**The third change is the one that stops this recurring.** `docs/legend.md` has
said since Revision 233 that *"no word appears in both vocabularies, and a schema
check asserts the two sets are disjoint."* **No such check existed.** The suite
already carries `test_the_two_vocabularies_share_no_word` for statuses against
standings; `test_outcomes_and_statuses_share_no_word` is the same assertion for
the third set, and it is what would have caught `superseded → DX` — a value that
was simultaneously an outcome and a bundle standing — at the moment it was
written.

**Rejected — add the four missing values and keep the retired prefixes.** It
would leave the executable site of a vocabulary the documents retired, which is
F7's defect exactly, one function further down the same file. Compatibility is
the argument for it and there is nothing to be compatible with: no decision in
the tree uses either.

**Rejected — validate the pointer's shape with a regular expression.** `replaced
→ D13` would become `^replaced → D\d+$`. It is a widening — F8 is about the
closed set, not the pointer — and the arrow is a character an author can get
wrong three ways, so a shape check would refuse conformant decisions before it
caught a malformed one, on this tree's own record of instruments that fail
loudly on first contact. **That an outcome's pointer is never validated at all is
worth a finding**, and this session is not opening one inside a decision.

**Rejected — assert the disjointness at import time.** It is the cheapest place
and the worst: an import-time assertion is a guard, it fires in every subcommand
including the ones that would tell you what is wrong, and `0047` F6 requires a
guard to be installed warn-only until it has passed the whole tree clean. The
property is static — it is about six constants in one file — so a contract test
is where it belongs and the suite already has the class for it.

## D4 — a finding answered by work nobody recorded is resolved against that work

`is_clone()` and its two regressions have been in
`.internal/ai-scripts/session-management/plan_findings_work.py` since Revision
231. The docstring cites `0047` F5 by number. **The finding has read `un-started`
for thirty-three revisions since**, and the sweep's 77 hits are 15.

So the resolution row names **Revision 231** and not this one. That is what the
`Revision` and `Commit` columns are for, and §11 already says the two can exist
apart.

**Rejected — re-derive the exemption and ship it as this revision's work.** It
exists, it is tested, and its behaviour is what F5 asked for. Rewriting it to
make the record tidy would put this session's name on Revision 231's change and
lose the one fact worth keeping: that the answer arrived without the finding
hearing about it.

**Rejected — leave F5 `un-started` because this session did not do the work.**
A status describes the reading, not who moved it. `un-started` says nobody has
looked; somebody has, and the tree has changed underneath it. Leaving it is how
`0052` F1 happens in the other direction.

**Rejected — fold F9 and F10 into F5's resolution as caveats.** A resolution row
that ends *"except for two cases"* is a resolution nobody can check, and both
cases are latent rather than observed — the class F8 records, where a defect
waits for the first person to write the conforming thing. They are findings, and
they get statuses of their own.

**Rejected — open F9 and F10 as a new bundle.** They are defects in the same
instrument as F5, F7 and F8, in the same two comparisons F5 governs. A fourth
bundle for the same file would split one reading across two numbers, which is
what §8's *a fact has one home* is about.

**What this decision establishes, and it is not only about F5.** A finding may be
resolved by a revision that predates the resolution, and the row says which. That
is `0052` F1 seen from the recording end: F1 is about a resolution silently
becoming false, and this is the same gap in the other direction — work silently
answering a finding. **Both are the record and the tree drifting apart, and only
one of them has ever been called a defect.**
