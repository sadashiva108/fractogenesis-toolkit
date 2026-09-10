# Decisions — sessions write into the tree the owner commits from

**Bundle:** `0038-sessions-write-into-the-tree-the-owner-commits-from`  
**Session:** `drift-and-the-write-boundary-20260909-053548`  
**Decided:** 2026-09-09

**This bundle supersedes `0028`, and `0028` decided all six of these at Revision
181.** So the question here was never *what should be done* — it was **does
`0028`'s answer still hold**, four months of revisions later. That is a
re-verification, and it is `0052` F1's method rather than a fresh reading. Each
decision below records the verification and its result; the results are not
uniform, and three of `0028`'s six resolutions name a home that no longer exists.

**Six findings resolved in one revision is a mass operation only if the
judgements are not separate.** Each has its own verification, its own rejected
alternatives and its own resolution row naming the revision that did the work,
which is the thing `0039` F12 asks for.

## Decisions

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | The shared-tree collision is not prevented and is not meant to be: it moves to the patch, where it is visible. §0 gains the rebase step, and `git --no-optional-locks` for every git read of the checkout | F1 | 2026-09-09 | `accepted` |
| D2 | F2 is answered by §0 step 2 and by the standing rule never to quote an `OK` total; the enforcement half is F7's and is not folded in here | F2 | 2026-09-09 | `accepted` |
| D3 | F3 is answered by §0 steps 3–4 and `bin/review-changes.sh`, both installed at Revision 232 | F3 | 2026-09-09 | `accepted` |
| D4 | F4's remedy holds and has never been stated: declining a patch is free and reverting a commit is not. §0 step 5 now says so | F4 | 2026-09-09 | `accepted` |
| D5 | F5 is answered by §7; **the artifact `0028` named is at a different path** and the citation is corrected rather than the tool moved back | F5 | 2026-09-09 | `accepted` |
| D6 | F6 is answered by §6's four write kinds; **the legend section `0028` created for it no longer exists**, the rule having moved to the instruction set, and the relocation is recorded rather than reversed | F6 | 2026-09-09 | `accepted` |
| D8 | A fourth test goes into `docs/rules/rule-enforcement-avenues.md` §3, **first**, and it asks whether the instrument can observe the act at all. All four candidates in §4 are re-scored against it and **all four fail**, by three routes. The installed set is corrected: one guard, two annotators | F7, F8, F9 | 2026-09-10 | `accepted` |
| D7 | Of the four guards F7 names, the manifest-entry guard is built first, warn-only until a clean pass. **Nothing is built in this revision** and F7 stays `decided` | F7 | 2026-09-09 | `accepted` |

## D1 — the collision is not prevented, it is made visible

F1 is the only finding here whose defect is structural. `APPLY-MANIFEST.md`,
`docs/sessions/INDEX.md` and the findings tree's `INDEX.md` are the three files
**every** session must write, and `git add <path>` takes a whole file. Nothing
about composing in a copy changes that.

What composing in a copy changes is **when** the collision is discovered and
**what it costs**. In the checkout it was two sessions' work in one file, found at
commit time, separable only by `git add -p`. In a patch it is a three-way apply
that names the conflicting hunks before anything is written, and the losing side
is a scratch copy nobody has committed.

**Measured twice by this session, on the same day.** Revision 268 was composed
against Revision 263, and the checkout was at 267 when the owner called for the
apply: twelve files applied clean and **three conflicted, and they were exactly
the three named above.** This revision repeated it. **Two for two is not
anecdote**, and it is the reason the rebase is written into §0 as a step rather
than left to be re-derived by a session that has a write pending and no
procedure.

**Also in §0: `git --no-optional-locks` for every git read of the checkout.**
Step 6 requires `git status --porcelain` there, and this session's own
`Resources` note — and `docs/rules/README.md` §6 — forbid git in the checkout
because `git status` refreshes the index, takes `.git/index.lock`, and cannot
clean it up on the mount, leaving a lock that blocks the owner's next commit.
**The rule and the procedure contradicted each other and both were right.** The
flag resolves it: same answer, no index write. Used for every checkout read in
Revisions 268 and 269, and no lock was left either time.

**Rejected — a scheduling rule: one session writes the shared files at a time.**
F1 says why in its own words: the three shapes in
`docs/ideas/knowing-when-it-is-safe-to-write.md` all work by keeping two sessions
off one file, these three files cannot be kept off, and the shapes therefore
degrade to *wait your turn*, **which is a schedule and not a mechanism.** It also
serialises the slowest part of two sessions that are otherwise independent.

**Rejected — restructure the three files so sessions do not share them**: a
per-session manifest fragment assembled at commit, an index built from the data
rather than maintained. It is the answer that actually removes the collision, and
it is a **breaking change to a record format** — which has no migration-plan
requirement, which is `0052` F2, and which would be overrun by the entity model
now in flight. **Doing it before either lands means doing it twice.**

**Rejected — leave the rebase unstated because a competent session will work it
out.** It was worked out twice in one day by one session, and the second time was
faster only because the first had happened. That is the definition of a procedure
worth writing down, and §0 is where the working cycle lives.

**What this does not do.** It does not make two sessions' work committable apart.
It makes the collision cost a rebase instead of a commit that attributes two
sessions' work to one, and it makes that rebase a named step. **The residue is
real and recurs on every concurrent sitting.**

## D2 — the baseline question is answered; the enforcement question is F7's

F2 is that a revision's quoted validator baselines were measured on a tree
holding another session's uncommitted work. §0 step 2 answers it directly: every
verification runs in the scratch tree, where the numbers describe this session's
change and nothing else.

**Verified against the tree.** §0 step 2 is present and absolute. Both revisions
this session has produced quote numbers measured on both sides of the change in
the scratch copy, and name the environment they were measured in.

**And the other half arrived from somewhere else.** F2's closing paragraph leaves
`0026`'s undecided option (iii) live — *stop quoting an `OK` baseline, track only
`MISSING` and `ANCHOR BROKEN`*. `docs/rules/README.md` §6 now states it as a
standing rule: **quote `MISSING`, `FAIL`, `WARN`; never quote `OK`**, with the
reason F2 gives, that the `OK` totals move whenever anyone parks a note. So
option (iii) was adopted without `0026` or this bundle being told.

**Rejected — reopen `0026` to record option (iii).** F2 already refuses this and
says why: a closed bundle reopened for an unrelated mechanism stops being a
record of what was decided. The rule has a home in the front door; a second copy
here would be the unchecked duplicate §8 forbids.

**Rejected — resolve F2 only when a check enforces step 2.** Nothing enforces it,
and F7 is the finding about what can be enforced at all. Holding F2 open for
F7's answer would make one finding wait on another inside the same bundle for a
property neither of them owns.

## D3 — the diff boundary exists and has been used

F3 is that a session's work had no reviewable unit. Revision 232 made §0 steps 3
and 4 and added `bin/review-changes.sh`.

**Verified by use.** Revision 268 was handed over as a patch of 15 files with its
file list read against the change set, and as a grouped review naming four areas
and flagging nothing for close reading. The owner reviewed and answered. **The
artifact F3 says does not exist was the thing this bundle's own work was
delivered on.**

**Rejected — hold F3 open until the review is required rather than available.**
§0 step 4 already requires it; what is unenforced is every step of §0, which is
F7.

## D4 — the cheapest thing in the cycle was never written down

F4 is that backing out one session's change was surgical because
`git checkout -- <path>` would take the other session's edits from the same file.
Composing in a copy answers it, and **the answer is not that reversal got easier
— it is that reversal is usually unnecessary.** A patch the owner declines leaves
nothing in the checkout.

**Verified against the tree and found missing.** The word does not appear in §0.
Steps 5 and 6 describe the gate without ever saying what the gate is *for*, and
`0028`'s resolution recorded *"declining a patch replaces reversal"* in a file
that is retained, superseded and read by nobody working today. **Four revisions
of the working cycle have run on a property none of them states.**

§0 step 5 now carries it, with the asymmetry named: free before the apply, a hand
edit per file after it.

**Rejected — put it in §6 with the composition rules.** §6 answers *where a write
is composed*; this is a property of the review gate, and the gate is §0's.

**Rejected — treat it as already covered by *composing is not delivering*.** That
sentence tells a session not to over-claim. This tells the owner that saying no
is cheap, which is a fact about **their** side of the exchange and the reason the
wait is worth its cost.

## D5 — the rule holds and the artifact moved

F5 is that a session could amend a revision the owner had already committed,
having read the manifest before the commit landed. §7 answers it: the number is
taken at apply time, against the tree being applied to, and entries are never
retro-edited.

**Verified, with one correction.** The rule is in §7 and works — this session took
264 while composing, found 268 free at apply time, and renumbered. But `0028`'s
resolution names **`bin/check-manifest-revision.sh`**, and **that path does not
exist.** The helper is `.share/check-manifest-revision.sh`, invoked as
`./bin/verify-session-findings.sh manifest-revision`, and §7 already cites the
current form.

So the resolution is sound and its **citation is stale**. This bundle's
`resolutions.md` records the current path; `0028` is superseded and is not edited
— §9 spends three prohibitions on that.

**Rejected — restore `bin/check-manifest-revision.sh` so the older record reads
true.** Moving a working tool to make a retained document accurate inverts which
of the two is authoritative. The tree is what is; the record says what was.

**Rejected — treat the stale path as a defect in `0028`.** `0028` was right when
written. **A resolution that names a path is a claim about a moment**, and the
claim was true at Revision 181. That every such claim decays is not `0028`'s
defect and is exactly `0052` F1.

## D6 — the rule survived; the section it lived in did not

F6 is that `docs/legend.md` named three write kinds and said nothing about where
a write is composed. `0028` D4 answered it with **a new section in
`docs/legend.md`, *Where a write is composed***.

**Verified against the tree and the section is gone.** `docs/legend.md` contains
no such heading. The rule is alive in §6 of the instruction set — four kinds now,
`record`, `toolkit`, `evidence` and `foreign`, with the gating per kind and the
composition rule stated once as applying to all three tracked kinds — moved there
by `0039` D2 and carried out by D13, which ruled that the legend says what words
mean and the instruction set says when a write is allowed.

**So F6's remedy is better than it was and lives somewhere else, and nothing
connected the two.** `0028`'s resolution still points at a section that was
deleted by a decision in a different bundle, taken for a good reason, which never
looked to see what cited it.

**Rejected — record F6 as reopened because its resolution's target was
deleted.** `reopened` takes one of nine reasons and every one of them describes a
fault. Nothing here is faulty: the rule moved to a better home and got wider. A
relocation that improves the rule is not a defect in the resolution, and
`reopened` would say it was.

**Rejected — leave the relocation unrecorded because the rule holds.** That is
how it went unnoticed for the revisions between. The resolution row names where
the rule lives **now** and says where it lived then.

## D7 — the order is decided and nothing is built

F7 says four rules pass all three guardability tests and none of the four is
built, and that **the choice has never been made deliberately.** It is right, and
this decision is the choice rather than the build.

**First: a change committed with no manifest entry.** It is the cheapest of the
four, the fact is in the tree rather than in `metadata.json`, and it is the only
one that has already cost archaeology — Revisions 241 to 246, six numbers taken
in the log and none written, reconstructed after the fact at Revision 247.

**Warn-only until a clean pass**, which is `0047` F6 and is not optional here.
Six instruments in this repository have reported mass failure against a healthy
tree on first contact, and a guard that does that stops the work at the one
moment a session cannot route around it.

**Nothing is built in this revision**, so F7 is `decided` and not `resolved`. A
guard is a toolkit write and it needs its own composing, its own warn-only run
across the whole tree, and its own review.

**Rejected — build the write-location guard extension first.** It is the one
`0050` names and it covers the second of two ways a session can write into the
checkout, so it looks the most urgent. It is also the one whose false refusal is
most expensive: it fires at the moment of a write, on a session that may be
mid-apply, and `0050` is not this session's to read.

**Rejected — build the §6 toolkit-write gate first.** It has had two failures in
two days, which argues for it, and it is the one of the four that needs the
finding graph rather than the file system — `docs/rules/rule-enforcement-avenues.md`
§7 records that enforcement here is a graph query, unenforceable for want of
asserted edges rather than for want of a guard. **It waits on the entity model**,
which is the other session's and is the critical path.

**Rejected — build none and leave F7 `framing`.** The finding's complaint is that
the enforced set is a record of past accidents rather than a decision. Leaving it
undecided is the complaint continuing.

## D8 — the test that disqualifies before the other three are worth applying

**One decision for three findings, and that is the ruling rather than a
shortcut.** F7, F8 and F9 were each read as a defect in a particular instrument.
They are one question never asked, and answering it three times in three places
would be the copy §8 forbids — **a fact has one home, and this one's home is
§3.**

### What the test says

> **Can the instrument observe the act at all?** Ask it first. The other three
> tests assume an instrument that runs at the moment of the write; whether one
> does is a separate question.

**It disqualifies cheaply.** Sections 3.1 to 3.3 ask about data, actor and cost —
all of which take reading to answer. This one takes looking at where the act
happens, and it removes candidates before the expensive questions are put.

### The three routes, each measured rather than reasoned

**Outside the harness.** The owner's `git add`, `git commit`, `git push` — §0 step
7 makes them the owner's, and there is no hook at a person's shell. **Every
recorded instance of a change committed with no entry is this route**: Revisions
241–246, and `636eba0`.

**A call the matcher does not name.** `write-location-guard.sh` matches
`Edit|Write|MultiEdit|Bash`; a session on a desktop bridge writes with
`mcp__remote-devices__device_bash`. It has never evaluated a single write —
`0045` F4. **And extending it does not pass the test**: naming that tool fixes one
harness and re-creates the defect for the next, *which is the shape of every
enumeration of callers ever written.*

**A tree the instrument cannot locate.** `session-guard.sh` and
`runbook-guard.sh` are scoped to `CLAUDE_PROJECT_DIR` and produced **0 notes
across 473 tracked files** in a session copy — Revision 282's pass. §4.1's
proposed `Stop` hook meets the same wall from the other side: it compares the
tree, and nothing tells it **which** tree.

**Routes two and three reduce to `0045` F3** — a session cannot declare who it is
or where it works. **Route one does not**, and that distinction is why the test
lists three routes rather than one: two are a gap in what the framework can say
about itself, and one is a person standing outside it.

### The installed set is corrected

Three hooks, **one guard and two annotators**. `session-guard.sh` and
`runbook-guard.sh` are `PostToolUse` and each says in its own header that it
always exits 0. §4 and `0038` F7 both counted three. **Revision 280's promotion
rule governs one of them**, and there is nothing in the other two to promote.

### Rejected — record it as a fourth avenue in §2 rather than a test in §3

§2's four avenues are *where* a rule can be held — guard, check, review, nowhere.
This is not a place; it is **a precondition on one of them**, and putting it in
§2 would create a fifth avenue named *cannot be observed*, which is `nowhere`
under another name.

### Rejected — resolve F8 and F9 and leave F7 open until a guard is built

The reading F7 asks for is a deliberate choice, and it has been made twice —
D7 chose, and building revealed the choice was not a guard. **Holding F7 open
until something is built would make it a work item rather than a reading**, and
the thing that would close it is not available at this layer.

### Rejected — propose the harness change that would fix routes two and three

A session declaring its identity and its working directory to a hook is the fix,
and it is **not this repository's to make**. `0045` F3 owns the reading and it is
another session's. Naming a remedy in someone else's bundle from inside a
decision is the boundary breach the Revision 261 split exists to prevent.

### Rejected — delete §4 now that all four fail

**The rules are worth holding and the layer cannot hold them**, which is two
statements and the second does not retire the first. §4 states each candidate
with the incident it would have caught, and those incidents happened. Deleting it
would lose the reason anyone would build the avenue if one appeared.
