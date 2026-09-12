# Sessions write into the tree the owner commits from

**Recorded:** 2026-09-03, on the owner's observation that a session should hold its changes until told to release them.  
**Session:** `session_019yzcjm2QneJ5ymVEQDi1bu`  
**Severity:** two findings are high. Both are silent — nothing fails, and the damage is to what the record can be trusted to mean.  
**Scope:** cross-cutting. Tracked files only; the artifact volume is out of scope and finding F6 says why.  
**Relates to:** [`0028`](../../cross-cutting-findings/0028-sessions-write-into-the-tree-the-owner-commits-from/) — **supersedes it.** The original is retained at `docs/cross-cutting-findings/0028-sessions-write-into-the-tree-the-owner-commits-from/`, still listed by the session that held it, its reading unchanged and its files brought onto the schema in Revision 203. Authority for this reading lives here.

**Read:**

- the day's own working tree
- `git status` and `git log` across the two concurrent sessions
- `docs/ideas/knowing-when-it-is-safe-to-write.md`
- `0026-verify-doc-paths-counts-gitignored-docs`
- `docs/legend.md`
- §§4b–4d, in `.github/copilot-instructions.md`
- all 27 existing findings bundles, checked for overlap

## What is not the problem

Stated first, because the obvious reading of this bundle is "writing is unsafe"
and that is not what was found.

- **No work was lost.** Both revision-number collisions were caught and resolved
  by the existing precedent. The duplicated session bundle was caught and deleted.
- **The re-read-the-header rule works as written.** It was followed exactly, by
  both sessions, and still collided — which is a property of *when* the number is
  taken, not of anyone's compliance.
- **`git status` works.** It is the only mechanism in the current arrangement that
  actually detected a concurrent session's work, and it detected it every time
  someone looked.
- **The artifact volume is already serialised.** A session has no write permission
  to it by default, and the owner grants it to one session at a time.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | Two sessions' uncommitted work interleaves in shared files, so neither can be committed alone | `resolved` |
| F2 | A revision's claimed validator baselines are measured on a tree containing another session's work | `resolved` |
| F3 | A session's work has no diff boundary, so the owner cannot review it as a unit | `resolved` |
| F4 | Backing out one session's change is surgical, because `git checkout` would take the other's too | `resolved` |
| F5 | A session can amend a revision the owner has already committed | `resolved` |
| F6 | The write discipline does not distinguish the write kinds `docs/legend.md` now names | `resolved` |
| F7 | A rule here is enforceable at write time only where the fact is in `metadata.json`, the actor identifies itself, and a false refusal costs less than the rule — and none of the four guards that pass those tests is built | `resolved` |
| F8 | The guard D7 chose cannot fire at the moment that has actually failed: every recorded instance is the owner committing, and no session-side hook observes that | `resolved` |
| F9 | Two of the three hooks are annotators that cannot refuse anything, and both are scoped to the one directory a session must never write in — so they can only speak about a write the third hook refuses | `resolved` |
| F10 | §0 step 1 places no condition on the checkout it copies and keeps no record of its state, so a patch composed from a dirty copy silently includes another session's work and step 2's promise about the numbers is inverted | `resolved` |
| F11 | §0's patch recipe drops a deletion: `git add -N .` stages a removal, and bare `git diff` then compares the working tree against the index and reports nothing, so the patch omits the file silently and `git apply` exits 0 | `resolved` |
| F12 | `verify-doc-paths.sh --all` reads untracked files, so it returns a different verdict in the owner's checkout than in the scratch clone §0 step 2 requires every verification to be run in | `resolved` |

**Read as a re-verification on 2026-09-09, at Revision 269**, by
`drift-and-the-write-boundary-20260909-053548`. `0028`, which this bundle
supersedes, decided and resolved all six of F1–F6 at Revision 181; the question
here was whether those answers still held. **Two of six hold as written, three
name a home that no longer exists, and one — F4's — was never stated anywhere.**
The table is in `resolutions.md`. **No remedy was lost**: every rule `0028`
installed is alive, two of them in better homes than they had. What decayed is
the record's ability to say where.

**F1 recurred twice on the day it was resolved**, which is the reason its
decision is what it is rather than a claim that the collision is gone. Revisions
268 and 270 were both composed against a base that moved before the apply, and
both times the conflicting files were **exactly the three this finding names**
while every other file applied clean.

Findings 1 and 2 are the high ones. The revision-number collision that prompted
the day's investigation is **not** a finding here — it is recorded in
`docs/ideas/knowing-when-it-is-safe-to-write.md`, along with three candidate
shapes for fixing it. This bundle is the reading of what the shared working tree
costs; that idea is one proposal against it. They should be read together and
resolved together.

### F1 — two sessions' work interleaves in files neither owns alone

Observed 2026-09-03. Both sessions edited `APPLY-MANIFEST.md` and
`docs/sessions/INDEX.md` in the same sitting, without conflict and without either
noticing until asked. At the point the owner tried to commit, the working tree
held Revision 167 (this session) and Revisions 166, 168 and 169 (the concurrent
one) in one file, and a row edit from each in the other.

Path-scoped staging cannot separate them: `git add <path>` takes the whole file.
The honest options were one commit covering both sessions, or `git add -p` hunk by
hunk on the two shared files. The owner took the first, and the resulting commit
attributes two sessions' work to one.

Every other file that day split cleanly by path. The two that did not are the two
that every session must write to — the manifest and the session index — so this is
not an unlucky overlap. It is structural, and it recurs on every concurrent
sitting.

That is the part `docs/ideas/knowing-when-it-is-safe-to-write.md` does not reach.
Its three shapes for knowing what is safe to write — a bundle declaring the files
it holds, deriving the answer from `git status`, a hook refusing an edit another
bundle claims — all work by keeping two sessions off the same file. Neither of
these two files can be kept off. Every session writes a manifest entry, and every
session bundle has a row in the index, so on those two the shapes degrade to
*wait your turn*, which is a schedule rather than a mechanism.

### F2 — a revision's validation is measured on somebody else's tree

Every `APPLY-MANIFEST.md` entry ends with a validation block: doc-path counts,
runbook structure counts, portability counts. The convention is that those numbers
belong to that revision.

**`0026` already made this argument**, on 2026-09-01 and about a different cause:
*"the honest response, 'the count moved and I did not cause it', is
indistinguishable from not having looked."* Read it first — the case for why an
unattributable baseline is worthless is made there and is not restated here.

What is new is the cause. `0026` is about the scanner's **scope**: it counted
`docs/`, so any parked note moved the total, and Revision 130 closed it by pruning
`docs/`. This is about **attribution**: the tree being measured also holds another
session's uncommitted work. Pruning a directory does not touch it, because the
concurrent session edits `.github/`, `bin/` and `docs/legend.md` too.

Observed: Revision 170 of this session reports **774 OK / 0 MISSING**,
**213 PASS / 5 WARN / 25 FAIL** and **81 clean**, measured with the concurrent
session's uncommitted edits to `.github/copilot-instructions.md`, `docs/legend.md`,
`docs/runbook-findings/restore-apps/**` and its own bundle in the same tree. True
of the tree, not attributable to the revision, and the entry does not say so.

`0026` is `resolved`, so it cannot carry this; a closed bundle reopened for an
unrelated mechanism stops being a record of what was decided. But its undecided
option **(iii)** — stop quoting an `OK` baseline in session briefs, track only
`MISSING` and `ANCHOR BROKEN` — is live, costs nothing, and would blunt this
finding without addressing it. Whoever decides this bundle should decide that
option with it.

### F3 — no diff boundary, so no unit to review

The owner's review surface for a session's work is `git status` and `git diff` on
a mixed tree. There is no artifact that says *these are the changes this session
is proposing*, so review is either all of it or a file at a time, and the
distinction between "reviewed and accepted" and "committed because it was there"
is not recorded anywhere.

This is what makes the owner's stated preference — draft first, write on the
word — unenforceable today. A session that writes as it goes has already spent
the reviewable moment by the time it reports.

### F4 — backing out is surgical

Revision 156 of this session substituted `bookend` for `checklist` in fourteen
places that should not have changed, one of which — `restore-repos.md:695`,
"Phase 14's checklist" — named the pre-image capstone and was flatly wrong. The
concurrent session found them.

The reversal was fourteen hand edits verified one at a time against
`git show 9fea5eb`, because `git checkout -- <file>` would have discarded the
correct substitutions in the same files, and by then the concurrent session was
also writing. A session's mistake is only cheaply revertible while its changes are
separable from everyone else's.

### F5 — a session can amend what the owner has already committed

Also 2026-09-03: this session amended Revision 150 while the owner was committing,
having read the manifest before their commit landed. It was backed out and written
as Revision 151 instead.

The failure is not the amendment; it is that nothing prevented it. A session
writing into the tree the owner commits from is writing into a moving target, and
the window between reading a file and writing it is exactly the window in which
the owner's commit happens.

### F6 — the write kinds are named but the discipline is not

Revision 169 gave `docs/legend.md` three categories: a **record write** under
`docs/`, ungated; a **toolkit write** to any other tracked file, gated on
`resolving`; an **evidence write** to the artifact or workspace root, needing the
owner's word for the specific run.

The categories say *when* a write is allowed. They say nothing about *where it is
composed*, and findings F1 through 5 are all about composition. Record writes are
ungated and are precisely the ones that collided today — the manifest and the
indexes are all under `docs/` or accompany it.

Evidence writes are the exception that shows the shape of the answer: they are
already safe, and not because of a rule anyone remembers. A session has no write
permission to the artifact volume by default, and the owner grants it to one
session at a time. Serialisation by permission, decided per run. Tracked files
have no equivalent.

### F7 — the write discipline has no instrument, and four are available

Findings 1 through 6 are about what a session's writing costs. This one is about
what could hold the discipline that answers them, and it is the first finding in
this bundle that is not a defect in the tree: **nothing is wrong; four things do
not exist.**

**The reading is `docs/rules/rule-enforcement-avenues.md` and is not restated here** —
a fact has one home. What belongs in this bundle is the conclusion and its cost.

**Three tests decide whether a rule can be guarded at all**: the fact must be in
`metadata.json` at the moment of the write, the actor must identify itself, and a
false refusal must cost less than the rule is worth. Four rules pass all three,
and each has a recorded incident:

| Guard | Would have caught |
|---|---|
| a change committed with no manifest entry | Revisions 241–246, six numbers taken in the log and none written, reconstructed after the fact at 247 |
| the write-location guard extended to `device_bash` | `0050`; it covers one of the two ways a session can write into the checkout |
| the §6 gate on a toolkit write | two failures in two days — one where the gate applied and needed an override, one where it did not apply and a checker said it did |
| only `stamp` writes `standing`, `progress`, `state` | no incident yet; `docs/legend.md` says *"and nothing else may"* and nothing holds it |

**What it costs to leave.** The three guards that exist were each added after a
rule was broken, which means the set of enforced rules is a record of past
accidents rather than a decision. **The first item above is the one that has
already cost archaeology** rather than attention, and it is the cheapest of the
four.

**What this finding does not claim.** That a guard is the right answer for any of
them — section 6 of the record argues a guard fails harder here than a checker
does, and `0047` F6 carries that. This finding says only that the choice has
never been made deliberately.

## A tested alternative, offered as evidence not as a decision

Measured 2026-09-03 on this machine, so that whoever decides this bundle knows the
cost is not hypothetical.

The three validators self-locate their repository root from `BASH_SOURCE`
(`REPO_ROOT="$SCRIPT_DIR/.."`) and none of them invokes git — `verify-doc-paths.sh`
only prunes `.git` from its `find` traversal. A plain copy of the repository is
therefore a fully working tree for validation.

| | Copy outside the connected folders | Connected folder |
|---|---|---|
| doc paths | 774 OK / 0 MISSING / 0 ANCHOR BROKEN | identical |
| runbook structure | 213 PASS / 5 WARN / 25 FAIL, 27 docs | identical |
| script portability | 81 clean / 0 WARN / 0 FAIL | identical |

The copy is 5.8M without `.git` and 22M with, taking 0.15s and 0.54s. With `.git`
included the copy is a real working tree, so `git diff` there produces a patch;
`git apply --check` accepted that patch against the live repository with the live
working tree left untouched, verified by `git status` immediately after.

That answers findings F2 and F3 directly — validation runs against one session's
changes alone, and the patch is the reviewable unit. It answers 1, 4 and 5 by
removing the shared tree they all depend on. It does not answer the revision
number, which is `docs/ideas/knowing-when-it-is-safe-to-write.md`'s second shape:
take the number at apply time, when only one session is writing.

What it does not solve is worth recording with it. A copy in session-local scratch
dies with the session, so unapplied work is lost if a session ends unexpectedly —
it survives context compaction, which is the larger risk, but not termination.
And it is the same Linux VM with Bash D3 and GNU coreutils: **`/bin/bash -n`
against real macOS Bash 3.2 remains owed for Revisions 116–170** and no scratch
arrangement reaches it.

## What it costs to leave

Findings 1, 4 and 5 cost effort and attention, and were all absorbed today without
loss — that is the argument for treating this as unresolved rather than urgent.

Finding 3 costs the owner the review they asked for: the preference is stated, and
the arrangement makes it unenforceable.

Finding 2 is the one that compounds. Every revision written under a shared tree
records a baseline that cannot be attributed to it, and those baselines are what
the next reader compares against. Nothing detects it, nothing fails, and the
record quietly stops meaning what it says.

## F8 — the first guard cannot guard the half that has failed

D7 chose *a change committed with no manifest entry* as the first of F7's four
to build, on the ground that it is the only one that has already cost
archaeology. Building the instrument for it at Revision 278 found something D7
could not have known and F7's list does not carry.

**The rule has two halves and only one of them is a session's.**

| Who | What they do | Can a session-side guard see it? |
|---|---|---|
| the **session** | composes a patch, and may apply it on the owner's word | **yes** — a `PreToolUse` guard already refuses a write into the checkout, and could as easily refuse a patch carrying no manifest entry |
| the **owner** | runs `git add`, `git commit`, `git push` — §0 step 7 | **no.** It happens outside every session, in a terminal no hook is installed in |

**Every recorded instance is the owner's half.** Revisions 241–246 are six
numbers taken in the log and never written, reconstructed at Revision 247.
Commit `636eba0` claims Revision 271 and carries Revision 270's work. Revision
265 is claimed by two commits. **In each, a patch was composed correctly and the
commit is where the record and the tree parted company.**

So `docs/rules/rule-enforcement-avenues.md` §4.1 lists this rule as a guard that
passes all three tests, and it passes them **against a session**. Against the
owner it fails the second outright: *the actor must identify itself*, and the
actor is a person at a shell this framework has no presence in.

**What that leaves, and it is not nothing.** A checker — built at Revision 278 —
which the owner or a session runs and which reports the divergence after the
fact. **`0047` F6's distinction is the whole of the difference**: a guard fails
where a checker only reports, and here the only available instrument is the one
that reports. **F7 therefore stays `decided` rather than resolving on this
work**: a checker is not write-time enforcement, and F7's claim is about write
time.

**What it costs to leave.** F7's four are the deliberate set this repository
would enforce, and one of the four is not enforceable in the direction that has
failed. **Left unrecorded, the next session to read §4.1 builds the guard, finds
it green on every session-side write, and concludes the rule is held.** It is
not; the half that breaks is the half nobody is watching.

**What this finding does not claim.** That the session-side half is worthless.
A patch that carries no manifest entry is a real defect and refusing it is
cheap. It claims only that catching it does not catch what has actually gone
wrong, and that the record should say so before anyone builds against it.

## F9 — the two annotators can only speak about a write that does not happen

**Measured 2026-09-10 against Revision 281**, in the pass Revision 280 requires;
the run is `docs/ledgers/guard-conformance.md`.

**Three hooks, and only one of them can refuse.** `write-location-guard.sh` is a
`PreToolUse` hook and emits `permissionDecision: deny`. `session-guard.sh` and
`runbook-guard.sh` are `PostToolUse`, and each says so in its own header: *"It
always exits 0. PostToolUse runs AFTER the edit; there is nothing left to block,
so a rule is reported as context, not as a failure."* **They are annotators.**
`0038` F7 counts three guards and `docs/rules/rule-enforcement-avenues.md` §4
reads the same way; **the set is one guard and two annotators**, which matters
because Revision 280's promotion rule governs one of the three and there is
nothing in the other two to promote.

**All three key off `CLAUDE_PROJECT_DIR` and they disagree about what it means.**

| Hook | What it takes `CLAUDE_PROJECT_DIR` to be |
|---|---|
| `write-location-guard.sh` | **the forbidden zone.** Any write inside it is denied |
| `session-guard.sh` | **the working area.** `rel=${path#"$root"/}`, then `case "$rel" in docs/*-findings/*)` — a path outside it never matches |
| `runbook-guard.sh` | the same |

**So for any write, at most one of the three can say anything, and which one is
decided by the same variable read two opposite ways.** A write **inside**
`CLAUDE_PROJECT_DIR` is denied by the first and annotated by the other two — but
it does not happen, because it is denied. A write **outside** it — the session
copy, where all composing happens under §0 step 1 — is allowed by the first and
**invisible to the other two.**

**Measured: 473 tracked files fed as writes in a session copy produced zero
notes from either annotator.** Both fire on the same paths when those paths sit
inside `CLAUDE_PROJECT_DIR` — `session-guard` on a findings document,
`runbook-guard` on `bin/backup-repos.sh` — so **they work, and they are aimed at
the one place nothing may be written.**

**This is `0045` F4's shape and not its cause.** F4 records a hook that cannot
see the caller because it matches on a tool name. This is two hooks that see the
caller perfectly and are pointed at the wrong directory. **Both reduce to a hook
whose wiring encodes an assumption about where a session works**, and §0 step 1
moved that somewhere the wiring was never told about.

**What it costs to leave.** Not a missed refusal — neither can refuse. What is
lost is the whole of their purpose: `session-guard` exists to name the rule
governing a session-management record **at the moment one is edited**, and every
such edit this session made — nine revisions of them — was made in a copy, where
it said nothing. **A rule stated only where the write is forbidden is a rule
nobody is told at the moment they need it.**

**What this finding does not propose.** Pointing them at the session copy. The
hook is not told where that is, and cannot be: `0045` F3 records that a session
cannot declare who or where it is to any instrument. **The fix is not available
at this layer**, which is the same wall F7's four guards meet and the reason this
is recorded rather than repaired.

### F7, F8 and F9, on resolving them together at Revision 283

**They are three instances of one missing test.** F7 says four rules pass the
three guardability tests and none is built. F8 says the one D7 chose cannot fire
where the failure happens. F9 says two of the three installed hooks are pointed
at the directory nothing may be written in. **Each was read as a defect in a
particular instrument, and each is the same question never asked: can the
instrument observe the act at all?**

`docs/rules/rule-enforcement-avenues.md` §3 now asks it first, as **test 3.0**,
and §4 re-scores all four candidates against it. **All four fail**, by three
routes:

| Route | The act | Instances |
|---|---|---|
| outside the harness | the owner's `git commit` | Revisions 241–246; commit `636eba0` |
| a call the matcher does not name | a bridge session's write | `0045` F4, `0050` F1 — **never evaluated a single write** |
| a tree the instrument cannot locate | composing in a scratch copy | F9's annotators — **0 notes across 473 files** |

**Routes two and three are one cause and it is not this framework's to fix**: a
session cannot declare who it is or where it is working, to any instrument —
`0045` F3. **Route one is not that at all.** It is a person at a shell, outside
the system, and no amount of self-declaration reaches them.

**So F7's answer is not the one it expected.** It asks for the choice to be made
deliberately; it has been, twice — D7 chose, and building revealed the choice was
not a guard. What the re-scoring establishes is that **the enforcement dividend
§3.1 says *has not been drawn* cannot be drawn at this layer**, and that the
avenue actually available is the checker: two were built, at Revisions 278 and
282, and both report after the fact and refuse nothing.

**One thing this must not be read as.** Not an argument that the four rules do
not matter — §4 states each with the incident it would have caught, and those
incidents are real. **The rules are worth holding and the layer cannot hold
them**, which is a different sentence and the one the record now carries.

## F10 — the copy is taken without a condition and without a record

**§0 step 1 said *copy the checkout and edit there*, and nothing more.** No
condition on what the checkout held at that moment, and no record of it. **From
the instant the copy is taken, `git diff` inside it cannot separate this
session's work from whatever was already uncommitted** — the two are the same
difference against the same base.

**Step 2 then made a promise that is exactly inverted for such a copy.** *"Only
there do the numbers describe your change rather than whoever else is writing"*
is true of a clean copy and false of a dirty one, where the numbers describe this
change **plus theirs** — and the contamination reaches the verification figures in
the review, which is the evidence the owner decides on.

**Two instances, neither landed, both caught by hand.** This session's first patch
for `0047` carried **five files of another session's uncommitted work** — `0050`,
its session bundle and both `INDEX.md`s — and was caught by reading the patch's
file list against the change set. `instruments-and-blind-spots-20260909-220203`
produced one that would have reverted Revisions 280 and 281 from a stale overlay.
**`git apply --check` passes in both**: it tests whether hunks apply, not whose
work they are.

**Section 6's comparison is the remedy and points the wrong way.** It is
documented as *"what catches a dropped file"*, so a session that created no new
files reads it, correctly concludes it has none to drop, and skips it — and the
failure it skipped is the opposite one. **Both instances were caught by running
that comparison in the direction its own rationale does not name.**

**Recorded by `assurance-coverage-20260908-204724` as `0049` F8** at Revision
293, which named §0 as the owner of the fix and left it. §0 is this session's, so
the fix is written here rather than there, and F10 exists so the write has the
finding §6 requires.

## F11 — the patch recipe drops a deletion, silently

**§0 step 3 said `git add -N .` then `git diff`.** `git add -N` records
intent-to-add for an **untracked** file, which is why the recipe has it — a new
file is invisible to `git diff` without it. But for a **deleted tracked** file it
stages the removal, and bare `git diff` compares the working tree against the
**index**, where the file is already gone. **There is nothing left to report, so
the deletion is not in the patch.**

**Measured by `instruments-and-blind-spots-20260909-220203` at Revision 299**, on
the patch that revision existed to produce: **a 17-file change set produced a
16-file patch with 0 deletions**, and the 673-line file being retired was absent
from it. **`git apply` exits 0 and nothing warns**, because a patch that omits a
file is a valid patch.

**Reproduced here before the rule was written.** In a throwaway repository with
one edit, one addition and one deletion: `git add -N . && git diff` yields two
files and **zero** deletions; `git diff HEAD` yields three files and one. **And on
a change set with no deletion the two are byte-identical** — 345 bytes each, same
bytes — so the correct form is never worse and there is no case for the shorter
one.

**This session's own patches were unaffected and that is luck, not care.** Every
one used `git diff HEAD`, and every one had zero deletions, so the recipe's defect
could not have shown itself here either way.

**Recorded as `0041` F7 by the session that found it**, which named §6 and §7 as
the sections that would carry a rule and left it. **The recipe itself is §0 step
3**, which is this session's, so the one-word fix is written here and F11 exists
to satisfy §6's gate.

## F12 — an instrument answers differently in the checkout and in the clone

**§0 step 2 requires every verification to run in the scratch tree.**
`bin/verify-doc-paths.sh --all` does not give the same answer there.

**Measured at Revision 299**, same commit, two trees:

| tree | `MISSING` |
|---|---:|
| the owner's checkout | **10** |
| a fresh clone of it | **20** |

**The difference is `.internal/restore/`, which exists in the checkout and is in
no commit.** Ten citations resolve against an untracked directory. A session
verifying where §0 tells it to sees ten failures that the owner, looking at the
same commit, does not — and the owner's number is the one that gets quoted.

**This is `0038`'s subject turned around.** The bundle records that a session's
view of the tree is contaminated by what the owner has uncommitted; F12 records
that the **owner's** view is contaminated the same way, and that an instrument
reading the filesystem rather than the index cannot tell a tracked file from a
leftover.

**Not decided and nothing built.** Whether a doc-path check should read the index,
the filesystem, or both is a question about what a citation means, and
`verify-doc-paths.sh` is not this session's to change. **The measurement is
recorded so that two sessions quoting different baselines can find out why**, which
is what happened on 2026-09-10: one session reported `MISSING 10` against a
baseline of 8 while this one measured 20 for the same commit.

### F12, read and resolved 2026-09-12 at Revision 311

**The remedy was accepted 115 revisions before the finding was written.** `0012`
D2, 2026-09-04: *"The empty directory is removed locally, and that is not a
repository change."* `0012` F1 resolved against D1, the bundle went `answered`,
and **D2 was never carried out** — invisible for 115 revisions, because the only
tree in which it mattered was one person's.

**`.internal/restore/` was empty, untracked and not gitignored.** Ten citations
resolved for the owner and broke for everyone who cloned, which is what made the
two trees disagree. **The owner removed it at Revision 310**, and the trees now
agree: `verify-doc-paths.sh --all` reads **`MISSING: 24` in the checkout and 24 in
a clone**, where it read 10 against 20 when F12 was recorded.

**The disagreement was compounding while it stood.** Citations of that path went
from **10 rows when F12 was written to 17 four revisions later**, across five
documents — `time-machine-run-index.md`, `iris-conformance.md`,
`IRIS-COORDINATION.md` and two indexes. **Every document written about the defect
added citations to the path that did not exist**, this session's §6 rule among
them, which is `0041` D1's matcher problem in its sixth form: describing an
unresolvable path creates one.

**Removing it repaired nothing and revealed everything, which is the correct
outcome.** The citations were already broken; the leftover directory hid that from
the one person who could see it. `MISSING` rose in the checkout because the
checkout stopped being exceptional.

**D11 exists so this can resolve at all.** F12's answer is another bundle's
decision, and §9b requires `Resolved by` to name a decision in the finding's own
bundle. **A resolution row pointing at another bundle's decision is a citation
dressed as ownership**, so `0038` adopts `0012` D2 as its own answer rather than
borrowing it — the same disposal this session recommended to `0041` for F7, now
with a worked instance.

