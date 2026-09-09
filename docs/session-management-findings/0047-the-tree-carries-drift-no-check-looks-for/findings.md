# The tree carries status drift that no check looks for

**Recorded:** 2026-09-07, from a conformance sweep run at the owner's direction before any retrofit.  
**Session:** `allocation-and-inquiry-design-20260906-233205` (`session_015FpYVBF7dDoDrHfKDkq8fn`)  
**Severity:** F1 is high — an `unclaimed` bundle is meant to be closed to every session and one is not. F5 is high for a different reason: it is a defect in the instrument, and acting on the instrument's raw output would touch sixty-five records that are correct.  
**Felt at:** `0001` F1; `0030`, `0035`, `0036`; eleven bundles resolved before Revision 162's conversion  
**Scope:** session management. The remedy is a check and a retrofit, and the retrofit waits on `docs/architecture/state-as-data.md`  
**Relates to:** `0043` — its F2 and F7 are why this drift is possible; this is the inventory of what that cost  
**Relates to:** `0045` — the same question one vocabulary over

**Read:**

- every `findings.md`, `decisions.md`, `resolutions.md` and `STATUS-` tag in the four trees — 45 bundles, 131 findings
- `docs/legend.md`, the ladder and the two permission tables
- `docs/architecture/state-as-data.md` sections 4.3 and 4.4

**Transferred to `drift-and-the-write-boundary-20260909-053548` at Revision 261**,
having been assigned to `typed-bundles-architecture-20260908-204724` at Revision
237 and recorded `unclaimed` before that. F7 and F8 are `resolved`; F1, F2, F3
and F5 have not been written to and remain `un-started`, because moving them
without a judgement being formed about each is the mass operation `0039` F12 is
about.

**The retrofit this bundle points at should not begin until the state format
lands** — doing it in markdown first means doing it twice, and
`state-as-data.md` makes two of these classes structurally impossible rather
than checkable. **F7 and F8 are not that retrofit**: they are defects in the
instrument, and an instrument that misreports cannot be quoted while the
retrofit is argued.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | Releasing a bundle to `unclaimed` leaves its findings where they were, so a bundle closed to every session holds a readable finding | `un-started` |
| F2 | Six `accepted` decisions never moved their finding out of `framing` | `un-started` |
| F3 | Three bundles carry resolutions for findings that are not resolved | `un-started` |
| F4 | Eleven `resolved` bundles have no `decisions.md`, and whether they owe one has never been decided | `resolved` |
| F5 | A conformance sweep that does not know about superseding clones reports sixty-five false positives | `resolved` |
| F6 | A guard fails where a checker only reports, and the discipline that exists for checkers — a clean pass before it is trusted — has never been stated for guards | `framing` |
| F7 | `plan_findings_work.py:439` treats `transferred` as `unclaimed` and reports a permitted transfer as a conformance failure, the last executable site of a rule the documents retired | `resolved` |
| F8 | `plan_findings_work.py` validates decision outcomes against a set the legend replaced: it accepts the two the legend retired and rejects five of the seven it defines, one of which three live decisions already use | `resolved` |
| F9 | The two ordering comparisons report eight rows against `superseded` bundles, which no session may write to, so the rows cannot be cleared by anyone | `framing` |
| F10 | The clone exemption is bundle-wide and never expires, so it suppresses the comparisons on a clone whose re-reading has closed — and the `reopened` status, which retains its resolution by design, is reported everywhere else | `framing` |
| F11 | The disjointness guard covered three of the five closed vocabularies, and the pair it did not cover was the broken one — while a session's `state` had no closed set and no vocabulary check at all | `resolved` |
| F12 | A revision number can be taken in a commit message, which the helper that exists to prevent collisions cannot see | `framing` |

## F1 — an `unclaimed` bundle holding a live finding

`0001-restore-repos-evidence` is tagged `STATUS-unclaimed`. Its F1 is `framing`.

`docs/legend.md` puts `unclaimed` in the row where **nothing is readable**, and
says the bundle is *"parked and closed to every session until the owner assigns
it."* A `framing` finding is the opposite: open to every session, to read and to
record.

The history explains it without excusing it. `0001` was worked by
`restore-apps-outstanding-20260903-000000`, and released to `unclaimed` on
closing at Revision 205 — *"undecided"*, in its own `final-summary.md`. **The
release changed the bundle's tag and left the ten findings exactly as they
were.** Nine are `un-started`; F1, which had been read and decided against, stayed
`framing`.

Nothing in section 9, section 10 or the legend says what happens to a finding
when its bundle is released, which is why nothing happened to it.

## F2 — six decisions that moved nothing

`0001`'s `decisions.md` carries D1 through D6, every one `accepted`, every one
naming F1. F1 is `framing`.

`docs/legend.md` defines `decided` as *"every decision is made"*. Six accepted
decisions and no seventh outstanding is that condition met, and the index row
says so in prose — *"F1 has six decisions recorded against it and nothing
outstanding"*. The status never moved.

This is F1's defect and this one arriving together, and they are separable: a
bundle could be released correctly and still leave this, or move this correctly
and still be released wrong.

## F3 — resolutions for findings that are not resolved

| Bundle | Tag | Findings | Resolution rows |
|---|---|---|---:|
| `0030` | `analyzing` | 5 × `framing` | 5 |
| `0035` | `un-started` | 3 × `un-started` | 3 |
| `0036` | `analyzing` | 1 × `decided` | 1 |

`0035` is the plainest: a bundle nobody has opened, by its own tag, with three
resolutions recorded in it. Its index Notes say *"closed 2026-09-04; recorded and
resolved in one sitting"*, so the work was done and only the statuses stayed
still.

`0036` is the mildest and may not be a defect at all — a finding that is
`decided` is one its owner resolves from there, and a resolution row written
during that work is ahead of the status by minutes rather than by a policy.
**Whether a resolution may precede the status it implies is the question F3
owes**, and the answer decides all three rows.

## F4 — eleven resolved bundles with no `decisions.md`

`0002`, `0003`, `0004`, `0006`, `0007`, `0018`, `0019`, `0020`, `0022`, `0023`
and `0026`. All eleven are among the twenty-five parked notes converted to
bundles in Revision 162, one finding each.

`.github/session-management-instructions.md` section 3 lists `decisions.md` as
part of a bundle and says a decision without its rejected alternatives is an
assertion. These have neither document nor alternatives.

**The answer is probably that they owe nothing**, and it is not this bundle's to
give. A note parked before the shape existed recorded a conclusion and no
deliberation, and section 11 already provides for exactly that: a finding closed
before the shape existed carries `—` in `Resolved by`. **Writing decisions into
them now would be inventing deliberation that never happened**, which is the
rule about evidence, breached in the direction of tidiness. One decision covers
all eleven.

## F5 — the sweep is wrong before it is right

The sweep that produced this reading reported **77 instances across 45 bundles**
on its first run. **Sixty-five are `0037` through `0041` and are correct by
construction.**

Those five are superseding clones opened on 2026-09-06 for the ground-up
re-evaluation. Their findings were reset to `framing` for re-examination while
they carry the originals' `decisions.md` and `resolutions.md` forward. A decision
ahead of its finding and a resolution ahead of its finding are exactly what that
looks like from outside, and both are intended.

**This is the third instrument in this repository to report mass failure against
a healthy tree on its first run.** `0041`'s lint reported 36 failures where every
other validator passed; `0042` F4's rendering audit reported 131 of which 128
were bugs in the audit. The pattern is the same each time: the half that reads
the tree is wrong, not the half that judges it.

So the rule belongs in the check before the check is trusted: **a bundle whose
`Relates to` declares it supersedes another is exempt from the ordering
comparisons** until its re-reading closes. Without it the sweep would direct a
retrofit at sixty-five records that are already right.

**Carried out at Revision 231, and nothing recorded it here.** `is_clone()` in
`plan_findings_work.py` exempts a bundle carrying a `carried` or `successor`
edge, or a `lineage.supersedes`, from `DECISION-AHEAD-OF-FINDING` and
`RESOLUTION-AHEAD-OF-FINDING`; its docstring cites this finding by number, and
two regressions in the suite name it. **The finding stood `un-started` for
thirty-three revisions after its remedy shipped.** Revision 231's manifest entry
records the test suite and the capacity and does not mention the exemption, so
there was nothing to find but the code. **This is `0052` F1's subject arriving in
the bundle `0052` F1 cites**, and it is the reason `docs/rules/README.md` §6
says to read the tree before writing the finding.

**Measured 2026-09-09 against Revision 267.** The sweep reports **12** ordering
rows, not 77: one `DECISION-AHEAD-OF-FINDING` and eleven
`RESOLUTION-AHEAD-OF-FINDING`. The 65 are gone, and `0030` — one of the three
bundles F3 lists — went with them, because `0030` supersedes `0009` and is
precisely the correct-by-construction case this finding describes. **F3's table
is one row shorter than it was and neither F3 nor this finding said so**, and
`0036`, a second of its three, has since reached `answered`. F3's one surviving
row is `0035`.

**What the remedy did not do is F9 and F10**, recorded below rather than folded
in here: the exemption is per bundle and permanent where this finding asked for
*until its re-reading closes*, and the comparisons still report bundles nobody
may write to.

## F6 — the discipline exists for checkers and has never been stated for guards

F5 is the third instrument in this repository to report mass failure against a
healthy tree on its first run. The list is now six: `0041`'s lint at 36; `0042`
F4's rendering audit at 131, of which 128 were its own bugs; the completeness
check at 18; the one-way guard; F5's own sweep at 65 of 77; and the check F7
below records.

**Six is a rate, not a run of bad luck.** F5 reads the pattern as *the half that
reads the tree is wrong, not the half that judges it*, and that holds for all six.
What F5 does not reach is the consequence for a different kind of instrument.

**A checker that fires wrongly wastes an hour. A guard that fires wrongly stops
the work.** Three guards live in `.claude/hooks/` and every one was installed
after a rule was broken; none was run against the whole tree first, because
nothing said to. The rule that follows is one sentence and it does not exist:

> A guard is installed **warn-only**. It runs against the whole tree, produces
> zero false positives on a clean pass, and only then becomes a refusal.

**What it costs to leave.** On this tree's own rate, an unproven guard is more
likely to block correct work than to catch anything — and it blocks it in the one
place a session cannot route around, which is the moment of the write. The
reading is `docs/rules/rule-enforcement-avenues.md` §6.

**One thing this finding must not do**: become the argument against guards. The
same section names four that are worth building. This is the discipline for
building them, not a case against them.

## F7 — a check refuses an operation the instruction set permits

`.internal/ai-scripts/session-management/plan_findings_work.py:439` treats
`unclaimed` and `transferred` as one case and asserts that neither may hold a
finding past `un-started`:

```text
if b.get("ownership") in ("unclaimed", "transferred"):
    live = [x["id"] for x in fs if x.get("status") != "un-started"]
    if live:
        out.append(("CLOSED-BUNDLE-LIVE-FINDING", n, ...))
```

**§10 permits transferring a bundle that stands `analyzing`**, and an `analyzing`
bundle has findings past `un-started` by definition. So the check reports a
documented, permitted operation as a conformance failure. **Observed live**: the
transfer of `0039` at Revision 248 moved the count from 38 to 39, and the row
names all twenty-three of its findings.

The half about `unclaimed` is F1's subject from the other side — F1 records the
tree holding an `unclaimed` bundle with a `framing` finding, and Revision 228
then released four more with twenty-two between them, deliberately. **Whichever
way F1 is decided, this check is asserting it before anyone has.**

**Where it came from.** `docs/legend.md` used to gloss `transferred` as *handed to
a session that has not opened it*. That gloss was retired when the owner ruled
that a write and not a read moves a status. Fourteen prose sites carried it;
`0039` F21 is the reading. **This is the fifteenth and the only executable one**,
which is why it is here rather than there: prose that lags is read wrongly, and
code that lags refuses.

**What it costs to leave.** A number that moves on a correct operation, in the
one report an allocator run puts in front of the owner. `0036` is the standing
lesson about a baseline that cannot be trusted; this is that, in the conformance
column.

**Measured 2026-09-09 by the owning session, against Revision 267.** `check`
reported **52** conformance findings, **thirteen** of them this row. Five are the
`transferred` half — `0037`, `0038`, `0039`, `0045` and `0047`, the transfers
Revision 261 made — and **one of the five is this bundle**, so the check reported
its own transfer to the session that owns the finding against it. Removing that
half takes the row from thirteen to eight and `check` from 52 to 43.

**The other eight are the `unclaimed` half, and seven of them arrived at Revision
264.** `0001` stood alone until the assurance session closed and released seven
bundles, every one holding findings past `un-started` — `0041`, `0042`, `0046`,
`0049`, `0050`, `0051` and `0053`. **So `0047` F1 went from one live instance to
eight in a single revision, by a documented and correct operation**, and the half
of this check that survives is now most of the column. That is the argument for
keeping the row and naming F1 in it rather than deleting either.

## F8 — the outcome check enforces a vocabulary the legend replaced

`.internal/ai-scripts/session-management/plan_findings_work.py`:

```text
OUTCOMES = ("accepted", "rejected")          # plus `refined -> DX`, `superseded -> DX`
if o not in OUTCOMES and not o.startswith(("refined", "superseded")):
```

`docs/legend.md` -> *Decision outcomes* defines **seven**: `proposed`,
`accepted`, `rejected`, `deferred`, `retracted`, `replaced → DX` and `voided`.
The check accepts two of them, plus `refined → DX` and `superseded → DX`, and
**both of those were retired.** `replaced → DX` covers what they divided between
them, and the legend gives the reason in a sentence this check breaks: *"No
Outcome value is ever also a status value — `superseded → DX` was, and a reader
who learned one meaning read the other wrong."*

**So a decision written to the legend fails and a decision written to the retired
vocabulary passes.** `deferred`, `retracted`, `voided` and `proposed` are all
rejected by the instrument that exists to validate them, and `proposed` is the
one the legend says is *stored rather than left empty, so an unset outcome is a
load error and not a reading* — the default value fails its own check.

**Corrected 2026-09-09 by the owning session: it rejects five of the seven, not
four, and the fifth is in use.** `replaced → DX` is the legend's seventh outcome
and the check has no prefix for it — the two prefixes it carries are the two the
legend retired. `check` reports it now, on four live decisions: `0039` D1
(`replaced → D13`), `0039` D4 (`replaced → D5`), `0050` D1 (`replaced → D2`) and
`0053` D2 (`replaced → D5`), the fourth having appeared at Revision 264 — **the
count rises with every session that writes a conformant decision.** The
correction matters because it moves this finding from a
latent defect to a firing one, and **`0039` D4 is the decision that retrofitted
itself** from `superseded → D5` to `replaced → D5` — conforming to the legend
is what made it fail.

**This is F7's defect in the same file, one function apart**, and the same shape:
a closed set in code that the documents moved on from. F7 is `transferred` read
as `unclaimed`; this is the outcome vocabulary read as it stood before Revision
233. **Two instances make it a property of the file rather than a slip**, which is
why it is recorded here rather than folded into F7.

**And the tests held both in place.** `tests/test_session_management.py` carried
`test_the_four_legal_outcomes_pass`, asserting that `refined → D2` and
`superseded → D2` produce no `VOCAB` row, and
`test_an_outcome_outside_the_vocabulary_is_caught`, asserting that
`replaced → D5` **does** — the legend's outcome pinned as the failure and the
two retired ones pinned as correct. `test_transferred_is_treated_the_same` did
the same for F7, in a class whose docstring cites `docs/legend.md`. The file
separates **contracts**, which assert what the documents say, from
**regressions**, which assert that a defect cannot return, and all three were
contracts. **So the check and its suite moved together and stayed wrong
together**: a contract is written from the same understanding the code was
written under, and nothing compares either to the legend. That is the third
instance of the property, and it is the one that made the first two durable.

**What it costs to leave.** Recorded as costing nothing today, on the reading
that no decision in the tree uses a rejected value. **That was wrong by one
value.** Four decisions use `replaced → DX` and `check` reports every one of
them as a vocabulary failure, so the instrument is telling the owner that four
conformant decisions are malformed. The original point stands for the other four
— nothing has yet been written `deferred`, `retracted`, `voided` or `proposed`,
so **the first one will look like the author's mistake** — and the finding now
has an instance rather than an argument.

## F9 — the sweep reports rows that nobody is permitted to clear

Eight of the eleven `RESOLUTION-AHEAD-OF-FINDING` rows standing at Revision 267
are in `0031` and `0032`. Both are **`superseded`**, replaced whole by `0040` and
`0041` at the ground-up re-evaluation.

`docs/legend.md` and §9 are unambiguous about what that means: a superseded
bundle is **readable by any session and writable by none, including the session
that owns it**, and §9 spends three prohibitions keeping it that way. Its
`findings.md` is not edited — not to add a pointer, not to repair a citation, not
to soften a conclusion.

**So the sweep is reporting a state that the rules forbid anyone from changing.**
The rows are permanent by construction. They are not false in the way F5's
sixty-five were false — `0031` F1 really is `framing` and really does carry a
resolution — but they are unactionable, which costs a reader the same thing: a
number that cannot go down is not a signal, and eight of eleven is most of the
column.

`is_clone()` exempts the **successor** and says why. Nothing exempts the
**predecessor**, and the predecessor is the one nobody may touch. The two halves
of a supersession are treated as one case by a check that knows about the
relationship, which is what makes this a defect in the instrument rather than a
reading of the tree.

**What it costs to leave.** The same as F5, one step further on: the retrofit
this bundle points at cannot use the column, because eight of its eleven rows
name work that must not be done. And a reader who does not know the rule will
try — editing a superseded `findings.md` is a plausible reading of the row, and
it is the one act §9 exists to prevent.

**What this finding does not claim.** That the rows should be deleted. A
superseded bundle's drift is worth seeing once; what it is not is a conformance
failure against a live tree. Whether that is a separate report, a suppressed
class or a counted-and-excluded line is what F9 owes.

## F10 — the exemption has no expiry, and one status is exempted nowhere

F5 asked for an exemption **until the clone's re-reading closes**. `is_clone()`
tests for a `carried` or `successor` edge, or a `lineage.supersedes` — three
facts that are true of a clone for as long as it exists. **The exemption is
permanent.**

While the clone's findings are still awaiting re-reading the two comparisons are
the ones being suppressed, and correctly. Afterwards they are suppressed anyway:
a clone that closes its re-reading, is later reopened, and acquires a genuine
decision ahead of a genuine finding is the one bundle in the tree where nothing
will say so. Seven bundles are clones today — `0030`, `0036`, `0037` through
`0041` — and five of the seven are the re-evaluation, so this is not a corner.

**The mirror of it is `reopened`.** `RESOLUTION-AHEAD-OF-FINDING` fires on any
finding carrying a resolution whose status is not `resolved` or `withdrawn`, and
`reopened` is neither. But §9a is explicit that reopening is the door out of
`resolved` and that `decisions.md` and `resolutions.md` stand as they were, so a
`reopened` finding **retains its resolution by design**. The check would report
every one of them. **No finding in the tree is `reopened` today**, which is why
nothing has noticed — the same shape as F8, whose four rejected outcomes had
never been written either.

So the exemption is too broad in one direction and absent in the other, and both
halves have the same cause: the comparison asks *is this bundle a clone* where
the question is *is this finding awaiting a re-reading*. **The status is on the
finding and the exemption is on the bundle**, one level up from the fact it
depends on.

**What it costs to leave.** Nothing measurable today — no clone has closed a
re-reading and no finding is `reopened` — which is exactly what F8 costs and what
F8 says about that: a check that has never been exercised against the case it
governs fails silently, and the first person to hit it reads the failure as their
own mistake. **The first reopening in this repository will produce a conformance
failure for doing the thing §9a prescribes.**

## F11 — the guard covered three vocabularies of five, and missed the broken pair

`docs/legend.md` has said since Revision 233 that *"no word appears in both
vocabularies, and a schema check asserts the two sets are disjoint."* F8 found
that no such check existed and built one at Revision 268:

```text
words = set(OUTCOMES) | set(POINTER_OUTCOMES)
self.assertEqual(words & set(FINDING_STATUSES), set())
self.assertEqual(words & set(BUNDLE_STANDINGS), set())
self.assertEqual(words & set(BUNDLE_PROGRESS), set())
```

**Three comparisons, hand-listed, all of them outcomes against something else.**
Five closed vocabularies exist — finding `status`, dossier `standing`, dossier
`progress`, session `state`, decision `outcome` — which is ten pairs. The check
made three of them, and **`session.state` appeared in none.**

**The pair it did not cover is the pair that is broken.** `withdrawn` is a
finding `status` and a session `state`. The rule the legend states is violated in
the legend itself, and has been since both vocabularies were written.

**A hand-listed set of comparisons is the defect, not the missing line.** Nothing
tied the check to the sets it was checking, so adding a vocabulary — which
Revision 271 did, twice, with `genus` and `shape` — narrowed the guard's coverage
without changing a line of it. **The guard silently stopped covering more of the
surface every time the surface grew.**

**And `session.state` had no closed set at all.** `FINDING_STATUSES`,
`BUNDLE_STANDINGS`, `BUNDLE_PROGRESS`, `OWNERSHIP`, `OUTCOMES`, `KINDS` and now
`GENERA` are constants that `conformance` validates against. A session's `state`
was compared only against its own derivation, so a value outside the five would
have been reported as `STORED-DISAGREES` — *the record derives something else* —
rather than as a word that does not exist. **The two failures read very
differently to whoever gets the report**, and the retired state `owned`, which
survived in four tag files as late as `1c48deb`, is exactly the case that would
have produced the wrong one.

**What it costs to leave.** The same as F8, and F8 is the precedent that makes it
predictable rather than unlucky: a check that has never been exercised against
the case it governs fails silently. Here it did more than fail silently — **it
reported a clean pass on a rule the tree breaks**, which is worse than no check,
because a clean pass is the thing every session reads before quoting a number.

## F12 — a revision number can be taken where the helper cannot look

`.share/check-manifest-revision.sh` exists because *"re-read the header block and
take the next free number"* could be followed exactly by two sessions who both
took 167. It scans **both** places a number can be taken in the file — the
`**Revision N**` header block and the `## Revision N` entry headings — and its
own comments say the second is the whole point.

**There is a third place, and it is not in the file.** A commit message.

**Observed 2026-09-09.** Commit `636eba0` is titled *"Revision 271: the bundle
becomes a genus"*. Its contents are Revision 270 — this session's work, ten
files — committed under the message another session handed over for its own
revision. `APPLY-MANIFEST.md` gained no 271 entry, so the helper reported 271
free while `git log` reported it taken. **Two instruments, two answers, and the
one a session is told to trust is the one that cannot see the commit.**

**This is not new and the manifest records the earlier instance.** Revisions 241
to 246 are *"six numbers taken in the log and none written here"*, reconstructed
after the fact at Revision 247. The helper was written before that happened and
was never widened afterwards.

**It is also `0038` D7's guard arriving from the other side.** That decision
chose *a change committed with no manifest entry* as the first guard to build,
on the grounds that it is the only one of the four that has already cost
archaeology. **It cost archaeology again the same day it was chosen**, which is
the strongest argument the decision could have had and arrived six hours too late
to be in it.

**Why this is not simply fixed here.** Reading the log means shelling out to git,
and `docs/rules/README.md` §6 and this session's own `Resources` note both forbid
git in the owner's checkout because the lock cannot be cleaned up on the mount.
Revision 270 established that `git --no-optional-locks` answers that for reads,
so the route exists — but a helper that reads the log is a different instrument
from one that reads a file, with a different failure mode when the two disagree,
and **which one wins is a decision this finding owes rather than assumes.**
