# Rule enforcement avenues — where a rule can be held, and where nothing holds it

**Written:** 2026-09-09, `typed-bundles-architecture-20260908-204724`, from the  
owner's question whether hooks could enforce the framework's own rules.  
**Scope:** the four places a rule here can be enforced — a guard at write time, a  
check after the fact, a person, or nowhere — and what decides which one a rule gets.  
**Reads against:** [`typed-bundles-and-work.md`](../architecture/typed-bundles-and-work.md),
[`state-as-data.md`](../architecture/state-as-data.md),
[`allocation-and-inquiry.md`](../architecture/allocation-and-inquiry.md).  
**Status:** **a reading and a proposal. Nothing here is decided.** The findings it
names are its vehicles, and the thing it most wants does not exist yet.

---

## 1. Why this is a record rather than an answer

Three guards exist — `.claude/hooks/runbook-guard.sh`, `session-guard.sh` and
`write-location-guard.sh` — installed one at a time as a rule was broken. One of
them is already a finding: `0050` records that the write-location guard is blind
to `device_bash`, so it covers one of the two ways a session can write into the
owner's checkout.

That is the pattern this record exists to stop. **A guard has been added when a
rule was broken, and nobody has asked which rules a guard can hold at all.** The
answer is not *most of them*, and the rules it cannot hold are the ones the
framework leans on hardest.

## 2. The four avenues

| Avenue | Decides at | Costs when wrong |
|---|---|---|
| **guard** | the moment of the write, before it lands | **blocks work.** A false positive stops a session that was correct |
| **check** | after the fact, on demand or at handover | wastes the reader's time; the tree is already wrong |
| **person** | at review | the owner's attention, which is the constraint the whole allocator exists to ration |
| **nowhere** | — | the rule is obeyed by habit, and is discovered by breaking it |

**The fourth is a real answer and must be written down as one.** A rule with no
avenue is not thereby unimportant; it is a rule whose only instrument is a person
remembering, and saying so is what stops it being quoted as enforced. `0039` D21
took that answer explicitly for the commit-message rule.

## 3. Three tests that decide the avenue

**Is the fact in the data at the moment of the write?** `state-as-data.md` §4 put
status, ownership, kind, scope, dates and edges into `metadata.json`. Anything
derivable from those files is decidable by a guard without parsing prose — which
is the whole reason that migration was worth its cost, and the enforcement
dividend has not been drawn.

**Does the actor identify itself?** A guard sees a tool call and a path. It does
not see which session is writing. Every rule of the form *the owning session may*
therefore has no guard available to it, however clean the data is. Section 5.1.

**Is the failure worth blocking?** A guard that fires wrongly stops correct work.
Section 6 argues that in this repository that bar is higher than it looks.

## 4. What a guard could hold today

Four, each stated with the incident it would have caught.

### 4.1 A change committed with no manifest entry

`.github/session-management-instructions.md` §7: *every change of any kind takes a
revision.* A `Stop` hook comparing tracked files changed against whether
`APPLY-MANIFEST.md` gained an entry decides this from the tree alone.

**Revisions 241 through 246 were composed, verified, applied and committed with no
entry**, and `check-manifest-revision.sh` reported the numbers free the whole
time, because it reads the manifest and not the log. Revision 247 reconstructed
six entries after the fact. This is the highest-value guard on the list, and the
only one whose absence has already cost archaeology rather than attention.

### 4.2 The write-location guard, extended to the bridge

Section 0's whole cycle rests on composing outside the owner's checkout. The
guard covers writes made one way and not the other; `0050` is the reading. Not
new work, and the rule it protects is the one `0049` records seven revisions
skipping.

### 4.3 The §6 gate on a toolkit write

*A toolkit write is gated on a `decided` finding.* Every input is in the data: the
target path, and each bundle's `findings[].status` and `scope`. A guard walks the
`metadata.json` files and refuses a write to a tracked file outside `docs/` unless
a `decided` finding names it.

**This rule is currently held by memory, and it failed twice in two days** — once
where the gate genuinely applied and an override was needed, once where it did not
apply at all and a checker claimed it did.

### 4.4 Stored derivations

`docs/legend.md` says `standing`, `progress` and `state` are written by
`plan-findings-work.sh stamp` **and by nothing else**. That sentence is a rule with
no instrument. A guard refusing any other writer to those three keys makes it true,
and it is the narrowest useful guard here: three key names in one file shape.

## 5. Where enforcement stops

### 5.1 Identity — and this is the important one

**Every load-bearing permission in this framework is keyed on session identity.**
Only the owning session opens a finding. From `decided` onward only the owner
records. `resolved` is frozen. A transfer clears on the target's first write *as
owner*.

**A guard cannot enforce any of them**, because nothing tells a guard which session
is writing. There is no session identifier in the environment it can trust, and
the scratch path is a convention rather than a declaration.

That is `docs/session-management-findings/0045` arriving from a third direction.
`0045` F1 says a session's state cannot describe what the session is doing; this
says a session cannot describe *who it is* to anything but a human reading a
`metadata.md`. **The framework's central permission is unenforceable, and the
reason is the same reason its state vocabulary does not fit.**

Worth stating plainly: this is not an argument for adding an identity mechanism.
It is an argument for knowing that the permission rules are conventions, and for
not writing checks that pretend otherwise.

### 5.2 The conversation surface

The commit message never reaches a tracked file, so no guard, check or generator
can see it. `0039` D21 settled that and named the owner as the only instrument.
Anything else handed over in conversation — a review, a recommendation, a
disclosure of what was not checked — is in the same position.

### 5.3 Readings

Whether a decision's rejected alternatives are real, whether a finding's severity
is honest, whether prose restates a fact a table derives: none is decidable.
`typed-bundles-and-work.md` §6.4 asks what checks that breadth was preserved and
`0039` F21 answers that a presence check would manufacture what it looks for.

**One slice is tractable and worth naming**: assert that no word from one
vocabulary appears in a table headed by another. Three closed sets — finding
statuses, bundle standings, session states — and a membership test. It would have
caught `docs/legend.md`'s permission table on the day it was written and would have
caught nothing else, which is the property that makes it safe.

## 6. A guard fails differently from a check

**Six instruments in this repository have reported failure against a healthy tree
on their first run.** `0041`'s lint at 36; `0042` F4's rendering audit at 131, of
which 128 were its own bugs; the completeness check at 18; the one-way guard;
`0047` F5's sweep at 65 of 77; and `plan_findings_work.py:439`, which reports a
documented, permitted transfer as a conformance failure.

A checker that does this wastes an hour. **A guard that does it stops the work.**

So the discipline that exists for checkers has to be stated for guards, because it
never has been:

> **A guard is installed warn-only.** It runs against the whole tree, produces
> zero false positives on a clean pass, and only then becomes a refusal.

And `.claude/` is covered by the `agent-config` currency watch, which **has never
been armed** — `0039` F22. Adding guards without arming it repeats F22 in the one
directory where a stale description of the rules is worse than none.

## 7. Enforcement is a graph query, not a file test

The interesting rules are not properties of a file. They are properties of a
relationship, and `state-as-data.md` §4.3 already stores those as typed edges.

- **§6's gate** is *is there a `decided` finding whose scope covers this path* — a
  query over findings, not a path match.
- **`typed-bundles-and-work.md` §4.1's dispatch rule** — *a doing bundle may be
  dispatched only when every bundle it `serves` is `decided`* — is **the first rule
  in this framework stated as a graph query and nothing else.** It is also the
  session/agent boundary, which makes it the highest-stakes guard the design has,
  and it cannot be written as a path rule at all.
- **`allocation-and-inquiry.md` §9's invariants** are the same shape: no session
  holds a held bundle, every proposed order is a valid topological order of the
  `blocks` and `evidences` edges, every asserted edge resolves at both ends. Those
  are enforcement conditions that happen to be written as verification.

**So the enforcement surface and the allocation surface are the same graph**, and
that is the argument for asserting edges rather than a nicety. `the-record-and-the-graph.md`
§2.1 measures the gap: the edges array holds lineage and almost nothing else, so
the cohesion term scores zero and **every rule in this section is currently
unenforceable for want of data rather than for want of a guard.**

`allocation-and-inquiry.md` predates typed bundles and its vocabulary shows it.
The objective, the hold journal and the invariants survive the change; what moves
is that the queue holds nodes of several shapes and the edges cross between them.

## 8. This is a commission, and there is nowhere to put it

Nothing above is wrong with the tree. Four things do not exist and should.

`typed-bundles-and-work.md` §1 names exactly this: an **intent to build** gets *"a
markdown file in `docs/ideas/`. No status, no owner, no lifecycle."* This document
is that file, one directory over.

Under the model the draft proposes, the shape would be:

| | Poses | Produces | Feeds |
|---|---|---|---|
| `findings` | what is true about something that exists | an answer per finding | a doing bundle, by `serves` |
| `commission` | we want X; what shape should it take | a **blueprint** under `docs/architecture/` | a doing bundle, by `serves` |
| doing | — | changes | — |

**A session resolves findings into answers and commissions into blueprints. Neither
is a build.** The build is a doing bundle holding tasks `T1..Tn`, dispatched to an
agent once every bundle it `serves` is `decided` — which is §4.1's rule and §7's
first graph query, and the same sentence in both readings.

So this record is a blueprint written without its commission. **The four guards in
section 4 are tasks with no bundle to hold them**, which is the draft's thesis
arriving as a live instance on the day the draft was asked to defend itself.

## 9. Where the readings belong

| Reading | Home | Why |
|---|---|---|
| A rule can be enforced at write time, and which ones | `0038` | its subject is what a session's writing costs and what would make the discipline hold |
| A guard cannot enforce a permission keyed on session identity | `0045` | the same hole as F1, from the enforcement side |
| A guard is installed warn-only, and why | `0047` | F5's family — the instrument that is wrong before it is right |
| `plan_findings_work.py:439` refuses a permitted transfer | `0047` | F5's family exactly, and the last executable site of a retired rule |

None of these is recorded. This document is the reading; the findings are the vehicles.

## 10. Open questions

**10.1 Does `docs/rules/` earn a directory?** `docs/INDEX.md` gives
`architecture/` as *design that outlives the session that wrote it*, which
describes this file. A separate `rules/` makes sense only if it becomes the home
for the rule documents themselves — `docs/legend.md` and the instruction sets —
and that is `0039` F13, a rename with sixty-three citations. **Created here at the
owner's direction and named as a question rather than settled.**

**10.2 Which of the four guards is first?** 4.1 has the largest recorded cost and
4.4 is the narrowest. They are not the same answer and the order is a decision.

**10.3 Does an identity mechanism belong in the framework at all?** Section 5.1
argues the permissions are conventions. Whether that is a defect to fix or a
property to document is `0045`'s to take, and this record does not take it.
