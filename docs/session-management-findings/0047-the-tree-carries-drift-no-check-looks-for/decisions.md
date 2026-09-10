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
| D10 | `CLOSED-BUNDLE-LIVE-FINDING` is removed entirely, both halves having been overtaken; and `unclaimed` joins `superseded` in the counted ordering exemptions, on the ground that nobody may perform the act that would clear the row | F1, F2 | 2026-09-10 | `accepted` |
| D8 | A `superseded` bundle is exempt from both ordering comparisons, and `check` **counts** the suppression and names the bundles rather than asserting it in a footer | F9 | 2026-09-10 | `accepted` |
| D9 | The clone exemption becomes **per member and expires with the re-reading window**, keyed on the member's own status; and `reopened` is exempt from the resolution comparison **in every bundle**, because nothing is reverted when a member is reopened | F10 | 2026-09-10 | `accepted` |
| D7 | The warn-only discipline goes into §6 as a gate on what may **refuse** a write, with the second half F6 did not have: a guard must be shown to fire on a case it should catch, not only to stay quiet on correct work | F6 | 2026-09-10 | `accepted` |
| D6 | The number helper consults the **log as a third place** and takes the highest of the three, because a number is taken if it is taken anywhere. Conformance is a different question and gets its own checker, `bin/verify-manifest-coverage.sh` | F12 | 2026-09-10 | `accepted` |
| D5 | The guard is rebuilt over a declared set of vocabularies rather than a hand-listed set of comparisons, and the one pair nobody here may fix is **excluded by name** rather than absorbed. `SESSION_STATES` is added and a session's stored `state` is checked against it | F11 | 2026-09-09 | `accepted` |
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

## D5 — the guard is driven by the sets it guards, and the exception is named

Three changes, and the first is the one that matters.

**`VOCABULARIES` is a dict of every closed set in the module**, and
`undeclared_overlaps()` compares every pair of it. A vocabulary added to the
module and not to the dict fails `test_every_vocabulary_is_in_the_disjointness_set`,
so the guard cannot silently narrow the way it did when Revision 271 added
`genus` and `shape`.

**`DECLARED_OVERLAPS` licenses the two the design intends** — `standing` ×
`progress` on four values, because standing *is* progress with ownership put
back in, and `standing` × `ownership` on two, because standing takes the
ownership value when one is set. **The exception is data, declared once**,
rather than an argument reconstructed by whoever next reads the sets.

**`SESSION_STATES` exists and `conformance` uses it.** A session's `state` was
the one closed set with no constant, so a word outside the five read as
`STORED-DISAGREES` rather than `VOCAB`.

**Two tests, and the second is the interesting one.**
`test_no_undeclared_overlap_between_vocabularies` runs every pair **except**
`finding.status` × `session.state` and passes.
`test_every_vocabulary_pair_is_disjoint` runs all of them, is marked
`@unittest.expectedFailure`, and fails on that one pair — so the suite reports
**`OK (expected failures=1)`** rather than going red. **When the legend is fixed
the second test passes, and `unittest` reports an *unexpected success*** — a
loud, specific signal to delete it and fold the pair back into the first. The
defect retires the instrument that records it.

**Rejected — add the failing pair and let the suite go red.** A red suite is the
signal every session reads before trusting any number in this repository. Leaving
it red for a defect **nobody in this session may repair** — `docs/legend.md` is
the entity-model session's — trains the next reader to scroll past a failure,
which is `0047` F6's argument arriving one level up: **six instruments here have
reported mass failure against a healthy tree, and the cost each time was that
somebody stopped believing the instrument.**

**Rejected — rename the session value so the test passes.** It is one line and it
would be the inversion `0038` D5 refused: **moving the thing being measured to
make the measurement come out.** A vocabulary change is the entity-model
session's under the Revision 261 boundary, and `0039` F27 is where it is
recorded for them.

**Rejected — skip the pair without naming it.** An exclusion that is not visible
is a guard that quietly narrowed, which is F11 itself. `KNOWN_UNOWNED` is a named
constant in the test class and the docstring says which pair, why, and who owns
the fix.

**Rejected — keep the hand-listed comparisons and add the two missing lines.** It
would close today's gap and nothing else. **F11's cause is not the missing lines,
it is that the check was not derived from the sets** — which is why it went from
covering three pairs of three to three pairs of ten without anyone editing it.

## D6 — the file and the log are two incomplete registers of one sequence

**F12 asks which instrument wins when they disagree. Neither: for choosing a
number they are added.** `.share/check-manifest-revision.sh` already scanned two
places in the file, on the reasoning that an entry written but not yet
summarised in the header is invisible to a reader of the header. **A commit
subject is the same problem one register further out**, so it is scanned too and
the answer is the highest of the three.

**The log scan degrades rather than failing.** No git, no repository, or a
shallow clone falls back to the file's two places and says so under `--verbose`,
because that helper's stated contract is that it must work on a fresh checkout
with no `reimage.env`. Every git call passes `--no-optional-locks`: this runs at
apply time against the owner's checkout, where an index refresh leaves a lock
that cannot be cleaned up on a mounted folder.

**Conformance is a separate instrument because it has a separate contract.**
`bin/verify-manifest-coverage.sh` reports three conditions — a claimed number
with no entry (`MISSING`, which fails the run), an entry introduced by a commit
other than the one claiming the number (`ORPHANED`), and one number claimed
twice (`DUPLICATE`). It shells out to git unconditionally and must run in a
scratch copy. **A helper that must work without git and a checker that cannot
work without it are not the same program.**

**Two of the three only warn, and that is a ruling rather than softness.**
Entries are never retro-edited and commits are never rewritten, so a historical
`ORPHANED` or `DUPLICATE` row **can never be cleared by anyone**. A check whose
number can only rise is not a signal — which is `0047` F9, recorded against two
`superseded` bundles for exactly this. `MISSING` is the one a session can still
avoid causing, so `MISSING` is the one that fails, and it is **0** today.

**The checker found two false positives on its own first run and they were its
own.** An unanchored subject pattern read *"Revision 256: 0037 reaches
answered"* as the range 256 to 0037 and reported a bundle number as a missing
revision. **That is `0047` F6 arriving inside the instrument written to answer
`0047` F12** — the seventh instrument in this repository to fail loudly on first
contact, and the first to be caught before it shipped rather than after.
Anchoring the pattern also settled a question the finding never asked: **a
mention is not a claim.** *"Undo Revision 156's over-reach"* refers to a
revision without taking one, and the unanchored pattern counted two such
mentions as claims.

**Rejected — make the log authoritative and derive the manifest from it.** 250
entries against 50 claimed numbers: **200 revisions predate the convention of
naming the number in the subject**, and deriving the record from the log would
lose every one of them.

**Rejected — leave the manifest authoritative and ignore the log.** That is the
status quo, and the status quo handed out 271 while `git log` already held it.

**Rejected — put the log scan behind a flag.** A safety that must be asked for
is one that is not asked for. Revisions 241–246 and commit `636eba0` both
happened with a helper that could have been asked and was not.

**Rejected — let the coverage checker hand out numbers too.** One instrument,
two contracts: the helper must work on a checkout with no git, the checker
cannot work without it. Merging them would make the number unobtainable exactly
where the helper was written to work.

## D7 — a guard proves two things, and F6's sentence only asked for one

F6 proposes: *a guard is installed warn-only, runs against the whole tree,
produces zero false positives on a clean pass, and only then becomes a
refusal.* **That is right and it is half.**

**An instrument that reports nothing looks exactly like an instrument with
nothing to report.** `.claude/hooks/write-location-guard.sh` has been wired since
Revision 232 and **has never evaluated a single write** — its matchers name
`Bash`, and a session reaching the checkout through a desktop bridge calls
something else. It would have passed F6's test on every run it never made. That
is `0045` F4, recorded three hours before this decision and by another session.

So the rule requires both directions: **run it against the whole tree**, which
shows it is not lying about correct work, **and against a case it is supposed to
catch**, which shows it is looking at all. **Only the second needs a deliberate
violation**, and it is the half nobody thinks to perform.

### Where it lands

**§6.** A guard refuses a write, and §6 is the section that answers whether a
write may happen at all. The *reading* stays in
`docs/rules/rule-enforcement-avenues.md` §6 — F6 says so and a fact has one home
— and what goes into the instruction set is the rule, not the argument.

### The three clauses that came from the tree rather than the finding

**A clean pass is zero rows the instrument is wrong about, not zero rows.**
`bin/verify-manifest-coverage.sh` reports four and every one is an incident
already recorded; zero would have meant it was not looking. F6's phrasing is
*zero false positives*, which is already this — but the distinction is the one
everyone gets wrong, so it is stated rather than implied.

**A class nobody can clear warns rather than fails.** `0047` F9, applied at
Revision 278 when `ORPHANED` and `DUPLICATE` were separated from `MISSING`.

**The baseline lives in the instrument.** *Never quote `OK`* is unreadable
without a number to read against, and a baseline in a session's memory is one
`0026` already showed is worthless.

### Rejected — state it in `docs/rules/rule-enforcement-avenues.md` and nowhere else

That is where the reading is, and a reading is *cited, not obeyed* — rank 5. A
rule a session must follow before switching on a refusal has to be in the
document a session is told to read, which is rank 3.

### Rejected — make it a check rather than a rule

Nothing can measure whether a guard was run warn-only first: the evidence is a
run that happened before the instrument existed in its final form. **It is a rule
about how a thing is built, and those are followed or not.** What can be checked
is the consequence — that is `0045` F4's territory, and it needs a session to be
able to identify itself, which `0045` F3 says it cannot.

### Rejected — require a clean pass and leave the firing half to judgement

The rejected version is F6's own sentence, and this session used it for four
revisions before finding the case it misses. **Two live guards in this repository
have never fired**, and both would have satisfied it.

### Rejected — grandfather the three guards already installed

Tempting because they are installed and nothing has visibly broken. **One of the
three has never fired**, which is the argument against: *nothing has visibly
broken* is exactly what an instrument that is not looking produces. What the rule
asks of them is one pass each, and it is owed rather than done here.

## D8 — a row nobody may clear is not reported, and the silence is counted

§9 and `docs/legend.md` agree without qualification: a `superseded` bundle is
**readable by any session and writable by none, including the session that owns
it**, and §9 spends three prohibitions keeping its `findings.md` unedited. So the
eight rows in `0031` and `0032` name work that must not be done, by anyone,
permanently.

**They go. And the count stays**, which is the half F9 did not ask for.

F5's remedy is the precedent and the warning: it suppressed **65 rows** correctly
and recorded the fact in a footer sentence — *"superseding clones are exempt from
the two ordering comparisons"* — **which could not move whatever the tree did.**
Revision 280 has just ruled that an instrument reporting nothing looks exactly
like an instrument with nothing to report; a suppression stated in prose is the
same defect one level down. Both exemptions now print their count and their
bundles, and the clone exemption's number — **11 rows in `0030` and `0039`** —
had never been seen by anyone.

**Rejected — report them under a separate code that warns rather than fails.**
The shape Revision 278 used for `ORPHANED`, and it does not transfer: `check`
has no exit status and no severity, so a second code would be a second row in the
same list, and the number still could only rise.

**Rejected — leave them and let the reader subtract.** The reader has to know
which bundles are superseded to do it, which is the work the instrument exists to
save. `0036` is the standing lesson about a baseline that has to be argued with
before it can be used.

**Rejected — exempt every terminal standing, not just `superseded`.** An
`answered` or `retired` bundle is still writable by its owner, so a row against
one can be cleared. **The property is not being finished; it is being frozen**,
and only `superseded` is frozen.

## D9 — the exemption belongs to the member, and one half of it belongs to a status

**F10 asked for the clone exemption to expire when the re-reading closes.**
Nothing records that event. **The member's status does**: a clone's members are
reset to `un-started` or `framing` for re-examination, so the exemption applies
exactly while a member sits in that window and lapses the moment it is `decided`.
No new field, no bundle-level flag, no event to record — and it expires **per
member**, which is what F10 identified as the defect: *the status is on the member
and the exemption is on the bundle, one level up from the fact it depends on.*

**The second half is not a clone rule at all.** `reopened` keeps its resolution
row **by design** — *"nothing is reverted"* — so the comparison must not fire on
it in **any** bundle. It was written as a clone exemption in the finding because
that is where the finding found it; it belongs to the status.

**It changes no number today and that is the point.** No member in the tree is
`reopened`. **The first reopening in this repository would have produced a
conformance failure for doing exactly what §9a prescribes**, and the author would
have read it as their own mistake — which is F8's sentence, and F8 is why this
one was looked for.

**Rejected — keep the exemption bundle-wide and add an expiry field.** A field
recording that a re-reading has closed is a second copy of what the member
statuses already say, and `docs/legend.md` is explicit that nothing derivable is
stored.

**Rejected — exempt `reopened` only in clones.** It is the reading F10 states,
and following it would leave the comparison firing on every reopened member in
every ordinary bundle, which is the commoner case by far and the one §9a
describes.

**Rejected — leave `reopened` alone until a member is actually reopened.** That
is the argument for every one of F8's four never-written outcomes, and F8 records
what it costs: the first person to write the conforming thing reads the failure
as their own.

## D10 — the check outlived its question by one revision, and was written not to

**One decision for F1 and F2 because Revision 287 answered both with one
sentence**, and recording it twice would be the copy §8 forbids.

### The removal

`CLOSED-BUNDLE-LIVE-FINDING` asserted that a bundle closed to every session
holds nothing open to one. **Neither half of that survives.** `transferred` left
at Revision 268 — §10 permits transferring a bundle that stands `analyzing`.
`unclaimed` leaves here, and this time **the rule moved rather than the reading
of it**: `docs/legend.md` no longer says an unclaimed bundle is unreadable, so
there is nothing left for the check to assert.

**The detail text was written for this.** At Revision 268 the surviving half was
kept with *"0047 F1, which is undecided"* printed beside every row, so the check
would announce the open question it rested on rather than imply a settled rule.
**It rested on F1 for twenty-one revisions and named it the whole time.** That is
the only reason this removal is a two-line change instead of an archaeology.

### The exemption

`0001` F1 is `framing` with six accepted decisions, and **no session may move
it** — `decided` is the owner's act and `0001` has no owner. The row
`DECISION-AHEAD-OF-FINDING` produced is therefore one nobody may clear, which is
`0047` F9's ground exactly, so `unclaimed` joins `superseded` in the counted
exemptions. **The clone exemption sits beside them on a different ground** and
the counter says so: a clone's state is *correct while it is re-read*, not
*unfixable*.

`DECISION-AHEAD-OF-FINDING` falls to **zero across the tree.** `check` goes
**33 → 26**.

### Rejected — narrow the check instead of removing it

There is a true statement nearby: an `unclaimed` bundle may not have a member
moved to `decided`. But **nothing in the data records when a member moved**, so
the check could only compare a state, and every state it could compare is now
legitimate. A check that cannot fail is `0038` F9's annotators one layer up.

### Rejected — keep it and exempt `unclaimed`, as was done for `superseded`

That is what the ordering exemptions do, and it is right *there* because those
comparisons still say something true about owned bundles. **This check said only
one thing and that thing is now false.** Exempting the only case it reported
leaves a comparison that cannot fire — Revision 280's rule names an instrument
that reports nothing as the failure a clean pass cannot distinguish.

### Rejected — resolve F1 and leave F2 open

F2 reads *six accepted decisions never moved their finding* as drift, and one
sentence of Revision 287 makes it the only permitted state. **Leaving it open
would leave the tree carrying a finding that describes the rules being obeyed.**

### Rejected — move `0001` F1 to `decided` and clear the state at source

The tempting repair, and it is the one act the ruling forbids. `0001` is
unclaimed; **this session is not its owner and neither is any other.** Doing it
would be a session performing the owner's act, in the bundle whose finding says
that is exactly what may not happen.
