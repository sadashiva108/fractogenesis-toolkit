# A change that invalidates earlier work has neither a plan nor a check

**Recorded:** 2026-09-09, while resolving `0037` and finding its seven resolutions had been undone.  
**Session:** `typed-bundles-architecture-20260908-204724` (`session_01QvZrvKpoKwCmyLNjzXzCdQ`)  
**Severity:** F1 is high — one commit reverted seven resolved findings and no instrument noticed, in the tree whose whole purpose is that work is not lost. F2 is the owner's standing preference with nothing behind it.  
**Felt at:** commit `1c48deb`; `0037` F1–F7; the ten migrated bundles under `0037` D2  
**Scope:** session management. F1 wants a check, F2 wants a rule  
**Relates to:** `0037` — its seven findings are F1's evidence, and its D2 is why F2 exists  
**Relates to:** `0047` — F5's family: the instrument that is not there rather than the one that is wrong

**Read:**

- `docs/cross-cutting-findings/0027-findings-architecture-conformance/resolutions.md`
- `docs/session-management-findings/0037-findings-architecture-conformance/findings.md`
- `.github/session-management-instructions.md` §§7, 9, 9b
- commit `1c48deb` and commit `88aed77`

Recorded `unclaimed`. Not owned, and no session should open it until the owner
assigns it. It is recorded by a session that owns six bundles already, and
recording is not owning.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | Nothing re-verifies that a resolution still holds, and one refactor reverted seven without anything noticing | `resolved` |
| F2 | A breaking change to a record format has no migration-plan requirement, so what happens to what predates it is decided per change or not at all | `resolved` |
| F3 | Rolling a record file over to a fresh one is a format change that leaves every instrument reading the old path, and there is no rule requiring the readers to be named before the roll | `resolved` |

## F1 — a resolution is written once and never checked again

`0027` decided and resolved seven findings at commit `88aed77`. Commit
`1c48deb` then split `.github/copilot-instructions.md` into two files and
**dropped fifteen rules with no decision recording the removal** — among them the
rules five of those seven resolutions had installed.

**The seven resolutions became false and the record went on saying `resolved`.**
Nothing detected it. Not the six checkers, which read whether a document is well
formed. Not `verify-doc-currency.sh`, which watches source-to-dependent edges and
has never been armed — `0039` F22. Not a reader, until this session opened
`0027` by hand nineteen revisions later while resolving its successor.

**The general shape.** A resolution asserts *the tree now does X*. It is checked
once, at the moment it is written, by the session that wrote it. **Every later
change to the tree can falsify it and nothing looks.** `resolved` is the one
status the legend calls frozen, and freezing the record does not freeze the thing
it describes.

**Why this is not `0036`.** `0036` is a check whose scope is narrower than its
claim. This is a claim with no check at all, about the status the framework
treats as final.

**What it costs to leave.** The tree currently reads 36 findings `resolved`, and
nothing establishes that any of them still holds. **The number this bundle exists
to produce is how many are false**, and it cannot be produced by reading a
status. It needs each resolution re-read against the tree — which is the sweep
this session has proposed and not run.

### Read 2026-09-09 by `drift-and-the-write-boundary-20260909-053548`

**The count is 59, not 36**, at Revision 269 — the tree gained twenty-three
`resolved` findings in the days between this reading and the next. The number
this finding exists to produce got larger while nobody was producing it.

**The sweep has now been run on one bundle, and the result changes what to look
for.** `0038` supersedes `0028`, and `0028` decided and resolved six findings at
Revision 181. Re-read against Revision 269:

| | What `0028`'s resolution named | At Revision 269 |
|---|---|---|
| `0028` F1 | the composition rule in `.github/copilot-instructions.md` §3 | **the file has no such section** — `1c48deb` split it. The rule was re-installed as §0 at Revision 232 |
| `0028` F2 | validators run in the copy | holds |
| `0028` F3 | the patch is the unit | holds |
| `0028` F4 | declining a patch replaces reversal | **stated nowhere**, then or now |
| `0028` F5 | `bin/check-manifest-revision.sh` | **the path does not exist**; the helper moved to `.share/` |
| `0028` F6 | a new section in `docs/legend.md`, *Where a write is composed* | **the section does not exist**; `0039` D2 and D13 moved the rule to §6 and widened it |

**Two of six hold as written. Three name a home that is gone. One was never
stated.** And here is what the finding did not predict: **no remedy was lost.**
Every rule `0028` installed is alive, and two are in better homes than they had.

**So the failure mode is not the one F1 describes, or not only.** F1 was written
from `1c48deb`, where fifteen rules were deleted and five resolutions became
false — a resolution *reverted*. What one bundle's re-verification actually finds
is a resolution **still true and no longer findable**: five of `0028`'s six cite a
file, a section or a path, and three of those five decayed in four months of
correct, deliberate work by sessions that had no way to know what cited them.

**That is a second reading and it is cheaper to check than the first.** Whether a
rule still holds needs a human re-reading. Whether a resolution's cited path still
resolves is a path test, and `bin/verify-doc-paths.sh` already performs one — it
is the `<!-- historical: -->` marker that exempts a `resolutions.md` from it, on
the correct ground that repairing such a path would falsify the record. **The
exemption is right and the silence it produces is the gap**: a citation that has
decayed is not a defect in the record and *is* a signal that a resolution has
stopped pointing at anything, and nothing distinguishes the two.

**What this does not decide.** Whether the re-verification is a sweep, a check, a
required step when a rule moves, or a `movedTo` field on a resolution. One bundle
is one data point, and the shape of the instrument is what F1 still owes.

## F2 — a breaking change has no migration plan

`0037` D2 restores a carve-out for ten bundles that predate the shape they are
measured against, and it is the second time this class has been handled by
noticing it late. The owner's standing preference is **retrofit and backfill
older evidence to match the current shape wherever that is possible**, and the
exception is narrow: where the missing thing records deliberation or a
measurement that never happened, inventing it is worse than the gap.

**Nothing states that preference and nothing requires the question to be asked.**
A change to a record format — the header schema, the status vocabulary, the
`metadata.json` shape — currently ships without saying what happens to what
predates it, and the answer arrives as a finding months later. Revision 162's
twenty-five converted notes, Revision 203's schema pass, Revision 224's clean
slate and `0037` D2 are four instances.

**What a migration plan would have to name**: what predates the change, whether
it is retrofitted or exempted, why, and where the exemption is written so a
checker does not report it forever. **The retrofit is the default and the
exemption is the thing that needs a reason** — which is the reverse of how all
four instances were handled.

**What this finding does not propose.** That every change carry one. A format
change does; a wording change does not, and where that line falls is what F2
owes.

### Read 2026-09-10, and the line is not where this finding looks for it

**All four instances above were made by authors who did not believe they were
changing a format.** Revision 162 converted parked notes, Revision 203 ran a
schema pass, Revision 224 declared a clean slate, `0037` D2 restored a carve-out.
So *format change versus wording change* asks for the judgement the failures
show is not made — and D1 replaces it with a question about the tree: **would a
checker report existing records as failures after this change?**

**Two format changes have gone right since this was written**, and the rule is
derived from them rather than invented. Revision 271 migrated 54 bundles by an
**idempotent script** that was re-run through **two rebases**, and verified by a
**195-row derivation round trip** taken before and after; it deliberately left
`kind` alone so each rename had a fixed point to be checked against, and it
renamed the members array **before a second genus existed** because doing it
after would have cost every commission as well. Revision 273 renamed a value in
five files after checking the replacement had zero prior uses. **Each of D1's
five clauses names one of these.**

### Read again 2026-09-10, and the sweep is now an instrument

**36 decayed citations across 271 documents.** Every `resolutions.md`, handoff and
ledger cites paths, and 36 of those paths no longer resolve.

**Almost all of them are one class.** `bin/verify-findings-counts.sh`,
`bin/verify-findings-headers.sh` and `bin/verify-findings-structure.sh` moved into
`.internal/ai-scripts/session-management/` and are reached through
`./bin/verify-session-findings.sh`; `bin/check-manifest-revision.sh` moved to
`.share/`; `.github/copilot-prompts/` and `copilot-templates/` became
`ai-prompts/` and `ai-templates/`; `.internal/restore/record-restore-prereqs.sh`
moved to `bin/`. **Six relocations account for nearly all 36**, and **every rule
those resolutions installed is still alive.**

**So the number this finding said it existed to produce is not the number it
gets.** It asks how many resolutions are **false**. Mechanically that is
unanswerable — whether a rule still holds is a reading. What is answerable
exactly, and now is: **how many have stopped pointing at anything.**

**The same relocation is loud in one place and silent in another.** The identical
path, `bin/check-manifest-revision.sh`, is reported **MISSING three times** in
live documents that carry no historical marker, and was **silent in every record
that cited it** — because the marker exempting records from repair also exempted
them from being counted. One move, two signals, and only the records said
nothing.

**And the instrument was already there.** `bin/verify-doc-paths.sh` resolves
every citation in the repository and has done since long before this finding. Its
`HISTORICAL` branch sat **above** the resolution fallbacks, so in a
`historical-record` document every bare filename was counted historical whether
or not it resolved — **70 of them, of which 34 resolved perfectly well**,
`verify-doc-paths.sh` itself among them. The count meant *cited by a record*, a
property of the document. **One reordering makes it mean *cited by a record and
no longer there*, a property of the tree**, which is the signal.

**What it still does not do, and cannot.** Tell you whether the rule a resolution
installed still holds. `0038`'s re-verification at Revision 270 needed a session
to read six resolutions against the tree and judge each; **two held as written,
three named a home that had moved, one had never been written down at all.** Only
the middle three are mechanical. The rest is a reading, and D2 says so rather
than implying the checker covers it.

## F3 — a rollover is a format change, and its readers are not named

**Revision 310 rolled `APPLY-MANIFEST.md` over**: 1,312,633 bytes and 468 entries
timestamped to `APPLY-MANIFEST-09-11-2026.md`, a fresh file started in its place.
The reason was sound — `0055` F1 measured the file growing 8,162 bytes a revision
on every session's read path — and **the roll is not the defect.**

**The defect is that two instruments read that filename and only one survived.**

| | reads | after the roll |
|---|---|---|
| `.share/check-manifest-revision.sh` | the manifest, the log, **and** the working tree | **correct** — returned 311 |
| `bin/verify-manifest-coverage.sh` | `APPLY-MANIFEST.md` only | **MISSING 0 → 79** |

Every entry that moved to the archive read as *a revision number taken in the log
and written nowhere*. **The instrument was not wrong about anything it could see**;
its subject had been split in two and it was told about neither half.

**`check-manifest-revision.sh` survived by accident of an earlier widening.**
Revision 278 gave it the commit log as a third place, for `0047` F12 — a number
taken in a commit message. That widening had nothing to do with rollovers and is
the only reason numbering still worked five minutes after the roll.

**This is F2's own subject with the plan missing rather than the rule.** F2 built
§6's migration-plan gate: a write that makes existing records non-conformant is
gated on a plan naming five things. A rollover makes no record non-conformant —
every entry is still valid, still in the tree, still where it was written — **so
the gate does not fire, and the thing that breaks is not a record but a reader.**
The gate asks *what happens to what predates this*; it does not ask *who reads
this path*.

**Measured, and the repair reproduces the prior figures rather than merely lowering
them**: `MISSING 0, ORPHANED 6, DUPLICATE 1` after the fix, identical to the last
measurement before the roll.

