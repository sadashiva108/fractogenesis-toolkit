# Decisions — instruments that cannot fire, and one that unmakes the record

**Bundle:** `0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record`  
**Session:** `assurance-coverage-20260908-204724`, and `instruments-and-blind-spots-20260909-220203` for D3  
**Decided:** 2026-09-09, and 2026-09-10 for D3

Assigned by the owner on 2026-09-09 and read on assignment. **F5 was decided on
that day and F3 and F6 on 2026-09-10**, by the session this bundle was assigned
to at Revision 286. F1, F2, F4 and F7 are `framing` and stay there: F1's remedy
is already decided as `0049` D4 and its relationship to `0045` F4 is an edge to
settle rather than a decision to take; F2 is a one-line repair; F4 is a class
whose members are still arriving, and F7 is its newest.

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | The coverage sweep derives its roots from `docs/INDEX.md` instead of keeping a second copy, and reports the repository-root runbooks and `references/` explicitly | F5 | 2026-09-09 | `replaced → D2` |
| D2 | Derive the roots, **default in and explicitly out**: a directory in `docs/INDEX.md` is swept from the moment it appears, and excluding one is a declaration in `doc-currency.json` carrying its reason | F5 | 2026-09-09 | `accepted` |
| D3 | **The extraction half of `extract-metadata.py` is retired and the `--check` half is separated from it.** The parser is not made safe; it is removed, because every way of making it safe is an enumeration of what to protect, and the enumeration is already one schema behind | F3, F6 | 2026-09-10 | `accepted` |

---

## D1 — take the list from the file that owns it

`docs/INDEX.md` is authoritative for the directories under `docs/`. It already
lists `rules/`. `doc_currency.py:104` keeps a parallel list in code and that copy
went stale the day Revision 249 created the directory.

**The fix is to stop keeping the copy**, not to add `docs/rules` to it. Adding
the missing entry repairs today's instance and leaves the mechanism that produced
it, which is the retrofit error `0044` D1 names: a defect class whose only remedy
is attention has been repaired twice and grew both times.

**What the sweep walks, after:** every directory `docs/INDEX.md` lists, plus
`.claude/` and `.github/` — which `docs/INDEX.md` does not govern and which must
stay named explicitly — plus `references/` and the repository-root runbooks,
which are the toolkit's own documents and have no index that owns them.

**The false positive, measured before proposing it.** On the tree at Revision
253 this takes the reported unwatched count from **21 to 64** in one step: 43
files that have never been watched appear at once, and every one is a true
positive by construction — none is watched, which is precisely what the report
says. **It will read as a regression and is not one.** That is `0047` F5's shape
— an instrument whose first honest run looks like a failure — and the mitigation
is not to soften the number but to say in the same revision that the number moved
because the instrument stopped lying, not because the tree got worse.

**Rejected: watching the 43 as part of this decision.** Coverage and watching are
different acts, and F3 of `0053` is the one that decides what gets a watch.
Conflating them would mean choosing 43 watches to make a number look better,
which is how a coverage report becomes decoration.

**Rejected: failing the run on a non-empty coverage list.** `0041` D1 argues that
an undeclared remainder must fail rather than inform, and this is the case where
that rule does not yet apply: with 64 unwatched and no way to declare one out
deliberately, the check would fail permanently from its first run. **The
declaration mechanism has to exist first** — a way to mark a file *watched by
nobody, on purpose* — and it does not. Recorded so the gap is deliberate rather
than an omission, and so `0041` D1 is not quoted as satisfied here.

## D2 — default in, explicitly out, and the records are declared out with a reason

**D1 was under-specified and implementing it found the gap**, which is what
implementing a decision is for. Its prose says *every directory `docs/INDEX.md`
lists*. Taken literally that sweeps `docs/runbook-findings/`,
`docs/cross-cutting-findings/`, `docs/instruction-set-findings/`,
`docs/session-management-findings/` and `docs/sessions/` — **179 files, of which
157 are findings and session records.**

**Those are evidence.** A `findings.md` is a reading taken at a moment; a
handoff records what a session held and when. The standing constraint is that
evidence is never rewritten to match a later rule, and §9 spends three
prohibitions keeping a superseded reading exactly as it was. **A staleness report
over them would be asking for precisely the retrofit that is forbidden**, and it
would bury the 22 documents that can go stale under 157 that cannot.

D1's own false-positive estimate said the count would go 21 → 64, which is the
*correct* reading. **The prose and the measurement in one decision disagreed**,
and the prose was wrong.

### The rule D2 states

**Roots are derived from `docs/INDEX.md`**, which owns the directory list, plus
what that file does not govern — `.claude/`, `.github/`, `references/` — and the
repository-root runbooks, which belong to no index.

**Exclusion is a declaration, not a rule in code.** `doc-currency.json` gains a
`coverage` block naming the five excluded paths, each with its reason. A
directory added to `docs/INDEX.md` is **swept from the moment it appears**;
keeping it out takes a deliberate line in a file a reader opens.

That inverts the failure direction. Before, a new directory was silently
invisible — which is how `docs/rules/` was missed for four revisions. After, a
new directory is noisy until somebody declares it out. **`0041` D1's rule
exactly: the undeclared remainder is visible, and declaring something out is
deliberate.**

**Rejected: inferring the split from `docs/INDEX.md`'s Index column.** It
correlates perfectly today — the four findings trees and `sessions/` carry an
index link, the four description directories carry `—`. It is still an
inference, and `doc_currency.py`'s own docstring is the argument against it:
*"an inferred edge is how a checker tells one project's game engine that another
project's intake docs need updating."* A correlation that holds today is not a
declaration.

**Rejected: hard-coding the exclusions in the script.** That is the defect being
fixed, moved one line down.

### Measured, after

**21 → 62 unwatched.** Not the 64 D1 predicted, and the two are accounted for:
`README.md` is a dependent in two watches so it was never unwatched, and
`APPLY-MANIFEST.md` was already in the 21 as a named file rather than arriving
with the root sweep. **The estimate was high by two and the difference is
explainable**, which is the only reason to state a prediction before measuring.

`docs/rules/rule-enforcement-avenues.md` and all eleven `references/` documents
now appear. The run prints what it swept and what was declared out, so the
number can be read without opening the config.

## D3 — retire the parser, keep the check, and do not build a guard

**Re-measured first, at Revision 288**, in a throwaway copy: snapshot every
`metadata.json`, run the script with no arguments, flatten both trees and count
every scalar that goes from a value to `null` or absent.

| | Revision 260 (F6) | Revision 274 (`iris`) | **Revision 288** |
|---|---:|---:|---:|
| files rewritten | 62 | 65 of 65 | **66 of 66** |
| recorded values destroyed | 429 | 601 | **740** |
| distinct fields losing a value | 20 | 38 | **22** |

**F3's asymmetry is the right argument and its numbers were out by a factor of
forty-one.** F3 says *the 107 re-derive, the 15 do not*. Measured here by running
`./bin/plan-findings-work.sh stamp` on the stripped tree and counting again:
**`stamp` restores 120. Six hundred and twenty do not come back.**

| field | still lost after `stamp` |
|---|---:|
| `edges` | 210 |
| `members` | 113 |
| **`genus`** | **54** |
| `disposals` | 53 |
| `decisions` | 32 |
| `resources` | 30 |
| `ownedBundles` | 26 |
| `contributions` | 23 |
| `revisions`, `commits` | 19, 18 |
| `feltAt`, `indexNotes`, `owners`, `scratchPath` | 13, 11, 5, 5 |

### Three facts that were not in F3 or F6, and each decides something

**1. `genus` is destroyed, and `genus` is Revision 271's migration.** Fifty-four
values, and `stamp` does not restore them because `genus` is stored rather than
derived. The script was written at Revision 224; the field arrived at 271. **The
parser does not re-migrate the tree — it reverts it to a schema that no longer
exists**, and it does so silently, because a parser cannot report a field it has
never heard of.

**2. The suite runs it.** `.internal/ai-scripts/session-management/check-completeness.sh`
line 53 is `exec python3 "$SCRIPT_DIR/extract-metadata.py" --check`, and
`completeness` is in `verify-session-findings.sh`'s `all`. **So the destructive
script is executed on every routine verification run**, and `DRY` is
`"--dry-run" in sys.argv`, so **anything that is not exactly `--dry-run` or
`--check` is a live run.** F3 says *it has no safe no-op*; the sharper statement
is that its safe invocation is the one a session runs several times an hour, and
one token separates it from the other.

**3. The instruments cannot see the damage.** On the tree with 740 values gone
and `stamp` re-run: `counts` **FAIL 0**, `headers` **FAIL 11** — the standing
baseline, unmoved — `structure` **FAIL 1**, completeness **3 problems**. **Four
rows, against six hundred and twenty destroyed judgements.** That is `0050` F4's
class arriving inside `0050` F3: the record can be unmade and the assurance layer
reports very nearly a clean tree. A fifth fact belongs beside it — the script
writes `ensure_ascii=False` where `plan_findings_work.py` writes the default, so
**52 of 66 files are reformatted end to end**, and whatever the four rows do say
is buried in a whole-tree diff.

### The decision

**The extraction half is retired. The `--check` half becomes its own file, which
is what `check-completeness.sh` calls.**

`docs/architecture/state-as-data.md` §9 is the authority for why this is a
retirement rather than a repair. Steps 1 to 4 are the migration and they are
done: the JSON is committed alongside the markdown and everything since reads
JSON. Step 2 describes `--check` as *"`--check` doing its first job before it has
a second"* — **the second job is the completeness check, and it is the only half
of this file that is still live.** The script's own docstring says the rest:
*"Written ONCE and thrown away is the point."* It was not thrown away, and four
revisions of findings are what that cost.

**The migration did not complete cleanly, and that is the argument.** §9 step 5's
authority flip has not happened — the guard greps for `<!-- generated:` markers
and there are none — so the markdown is still authoritative for what it holds.
But `genus`, `edges`, `standing`, `ownership` and six hundred more values live in
the JSON and have never been in the markdown. **The tree is in a mixed state the
parser has no model of**, and re-running it does not move the migration forward
by one step; it discards the half that got ahead.

### Rejected, and the second one is F6's own proposal

**An interlock that counts the JSON-only fields and refuses** — F3's remedy.
Rejected on two grounds. It is a guard on a destructive act rather than the
removal of the destruction, and §6 requires a guard be installed warn-only first
and shown both not to fire on what is correct and to fire on what is not — a pass
this one cannot have, because the case it must catch destroys the tree it is run
against. And **the count is an enumeration of what to protect**, which is the
shape `0038` F7 rejected in the write-location guard and `0050` F1 records: it is
right on the day it is written and wrong the next time a field is added. `genus`
is that having already happened once.

**Preserve every field the parser does not derive — merge rather than replace.**
This is F6's own durable fix — *"the run should preserve every field it does not
derive, at which point there is nothing to guard against"* — and it is the
strongest alternative. **Rejected, and it needs the argument.** *Derive* is doing
work the parser cannot do: the parser does not derive anything, it parses, so the
preserve set is not computed but listed, and it is the same enumeration one
paragraph up wearing a friendlier name. It also keeps a parser of authoritative
markdown alive after the markdown stopped being authoritative for six hundred
values, and it leaves the file wired into `all` by an `exec`, so the argv distance
between the routine run and the destructive one stays exactly one token. **A
preserve-list would have preserved nothing about `genus`, because nobody would
have added it.**

**A warning rather than a refusal.** Rejected on F3's own reasoning, which
stands: the run reports success, so a warning is read as noise by the session that
most needs it.

**Delete the file entirely.** Rejected. `check-completeness.sh` execs it, and that
check is live and works — at Revision 288 it caught a data error in this
session's own write, `—` written into `resolution.commit` where `null` belongs,
which no other instrument looks for. Removing a working instrument to retire a
spent one trades the wrong way.

**Leave it, and rely on the record saying it must never be run.** Rejected.
`docs/rules/rule-enforcement-avenues.md` §2: `nowhere` is a real answer and has to
be written down as one, *"because a rule with no instrument is otherwise quoted as
enforced"* — and F6 records that §10a still routes a session toward running it.
A prohibition that lives only in prose, against a script the suite already
executes, is the weakest arrangement available.

### What D3 does not decide

**§10a's missing fifth step is not this bundle's.** F6 records that a release
leaves `structure` failing and that the extractor is the only thing that clears
it. With the extraction half retired, the safe act F6 already names — set
`ownership` by hand, run `stamp`, run `check` — becomes the only act, so the
hazard goes even though the procedure gap stays. **The gap is
`.github/session-management-instructions.md` §10a's**, which belongs to
`entity-model-and-vocabulary-20260909-053548`, and it is named here rather than
answered.

**The build is not done in this revision.** §6 gates a toolkit write on a
`decided` finding; this decision is what creates that gate, and carrying it out
is the next one.

<!-- historical: .internal/ai-scripts/session-management/extract-metadata.py -->
<!-- Deleted at Revision 299, carrying out D3. This document is the record of
     that decision and its carrying-out, so the citation is evidence and is not
     repaired. The check half is now check-metadata-completeness.py. -->
