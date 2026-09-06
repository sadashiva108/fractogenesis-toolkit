# Decisions — the findings-and-sessions architecture disagrees with itself

**Findings bundle:** `0027` · **Status when opened:** `in progress`, 2026-09-03.
**Owner:** `restore-apps-outstanding-20260903-000000`.

Decisions are recorded per finding as they are made. A finding with no entry here
has not been decided, and `resolving` cannot begin until all seven have one.

**Read this bundle's `findings.md` first.** Five of its seven findings are defects
in the deciding session's own work, which is recorded in that session's
`findings-manifest.md` and repeated here so a later reader weighing these
decisions knows the deciding session is not neutral about them.

| # | Finding | Decided |
|---:|---|---|
| 1 | §4b and §4c contradict each other on whether a findings bundle takes a revision | **yes** |
| 2 | Four of five `prompt.md` files violate §4d's "always" rule | **yes** |
| 3 | `docs/sessions/INDEX.md` restates a count the manifest owns | **yes** |
| 4 | `docs/INDEX.md` describes a directory it no longer matches | **yes** |
| 5 | Every `resolved` findings bundle is missing `decisions.md` | **yes** |
| 6 | The two session-state diagrams disagree | **yes** |
| 7 | Two session identifiers recorded as unrecoverable are recoverable | **yes** |

---

## Finding 1 — recording a findings bundle takes a revision

**Decision 1.1 — §4b stands. §4c's contradicting sentence is deleted.** Owner,
2026-09-03.

Writing a findings bundle is a repository change and takes an `APPLY-MANIFEST.md`
revision like any other tracked change. §4c:132 — *"Recording one touches no
tracked file and takes no manifest revision"* — is removed rather than reworded:
its first clause was literally true while `docs/` was gitignored, Revision 162
tracked it and Revision 164 removed the exemption, and the sentence survived
both. It is text that should have gone with Revision 164.

### Why this and not the alternatives

**Keeping §4c instead** — recording exempt, §4b carved out — was rejected on what
it costs the record. A commit's diff would contain tracked files that nothing in
`APPLY-MANIFEST.md` accounts for, and the manifest's value is that it is a
complete account of what changed. An incomplete one is worse than none, because a
reader cannot tell which omissions are deliberate.

**Splitting it** — a new findings bundle exempt, a decided one not — was rejected
as a third rule to remember and a boundary somebody has to judge on every write.
The failure mode it would produce is the one this finding already describes: two
defensible readings of the same instruction.

### The objection, and why it does not hold

A revision per parked note is friction on the rule that most needs to stay
cheap — *park it rather than widen the task*. That is real, and it is already
answered by the rule Revision 164 wrote alongside the one it is defending: **one
revision covers one change, not one file.** A session that parks three findings
bundles in a sitting writes one entry naming all three, exactly as a revision
editing nine documents is one entry.

Nothing requires an entry to be long. Recent entries are long because the changes
were, not because the rule demands it. A parked note can be recorded in two
sentences and often should be.

### What this decision implies elsewhere

It answers the question `0029` is waiting on — **where is a rule allowed to
live** — for the case of the manifest. `0029` findings 1, 2, 5 and 6 are
downstream of the general form of that question and are not decided here.

### What is not done

The edit itself. §4c is a toolkit write, and `resolving` cannot begin until all
seven findings in this bundle are decided. The sentence stays in the file,
contradicting §4b, until then — which is the gate working as intended rather than
an oversight.

---

## Finding 2 — the required-reading rule binds prompts that can still start a session

**Decision 2.1 — §4d's "always" binds a `prompt.md` for a session that is
`unclaimed`, `owned` or `handoff`. A `closed` or `withdrawn` session's prompt is
a record of what was given and is not retro-edited.** Owner, 2026-09-03.

Same doctrine the workflow already applies to `APPLY-MANIFEST.md` and to dated
artifacts: a document that records what happened is not rewritten to match what
the rules later became.

### The instance list had already changed

The finding names four non-conformant prompts of five. Revision 175 absorbed two
of those sessions, and `phase-11b-hydrate-and-bookends` — which had no
`prompt.md` at all when the finding was written — now has a conformant one, with
the instruction set as item 1 of a *Reading order* section. That is `unresolved`
working as intended: the reading improved while nobody owned it, and it was the
last contribution this findings bundle could take.

What is left is two, and the decision separates them cleanly:

| Session | State | Under 2.1 |
|---|---|---|
| `run-index-design-20260901-000000` | `handoff` | **fix it.** Its prompt will be handed to a session as written, and its only mention of the instruction set is an incidental citation in a ground-rules bullet at line 33 of 373 |
| `restore-git-phase-11a-20260901-155433` | `closed` | leave it. It is a placeholder written in Revision 162 for a session that left no brief, and it says so in its first line |

### Why not the alternative

Binding every prompt regardless of state would rewrite `restore-git-phase-11a` to
instruct a session that will never read it — a document whose own first sentence
explains it is standing in for a prompt that never existed.

An earlier draft of this decision keyed the rule on **when** a prompt was written
— binding those from Revision 161 on. That was rejected: a date ages, and every
future reader has to know it. *Can this prompt still start a session* is a
property the tree already carries in the session's state.

### Considered and not adopted

A clause exempting placeholder prompts. Under 2.1 it is unnecessary — the only
placeholder is `closed` and therefore already out of scope. Should a live session
ever need one, this decision is the place to revisit.

### What is not done

The edit to `run-index-design`'s prompt. `resolving` waits on all seven findings.

---

## Findings 3 and 4 — a fact has one home

**Decision 3.1 — a fact is written down once, and everywhere else links to it.**
Owner, 2026-09-03. Adopted as a rule rather than applied as two fixes, because
findings 3 and 4 are one defect wearing two coats and neither instance is the
last one.

What it means in practice:

- **A description says what something is for, never what it currently holds.**
  `docs/INDEX.md`'s `ideas/` row loses *"Currently empty"* — a sentence that was
  already false when the revision that wrote it added the first file.

**Decision 3.2 — a derived fact may be displayed, if something catches it
drifting.** Owner, 2026-09-04, revising 3.1 on first application.

3.1 as first written said a count is not restated, and would have removed the
number of findings bundles from each session's row in `docs/sessions/INDEX.md`.
The owner wants that count visible, and the rule was wrong rather than the
request: **what failed in finding 3 was not that a count was shown, it was that a
count was typed in a second place and nothing brought it back when the source
changed.** Authorship and checkability are the property that matters; display is
not.

So the count stays, and a check earns it: a validator compares each session's
index count against the rows in its `findings-manifest.md` and fails when they
disagree. Same family as the three existing `verify-*.sh` checks, and the same
argument they rest on — a rule nothing enforces is a rule that holds until
somebody is busy.

The general form: **a fact has one home. A copy of it elsewhere is permitted only
when it is generated, or when a check fails on drift.** An unchecked hand-typed
copy is what finding 3 is about, and what §4b's directory count still is.

**Decision 3.3 — a session's row shows bundles owned *and* findings carried.**
Owner, 2026-09-04.

A count of findings bundles is not a count of work. Measured on the tree the day
this was decided:

| Session | Bundles | Findings |
|---|---:|---:|
| `run-index-design-20260901-000000` | 10 | 10 |
| `restore-apps-outstanding-20260903-000000` | 4 | 30 |

Bundles alone say the first session carries more than twice the second's load.
Findings say the reverse, by a factor of three. The distortion is structural
rather than incidental: 26 of the tree's 29 findings bundles hold exactly one
finding, because they were migrated `docs/gaps/` notes, and the three that were
read rather than migrated hold 10, 7, 6 and 7.

So `docs/sessions/INDEX.md` carries **two columns**, `Bundles` and `Findings`,
and each findings index carries the same pair as a total.

**Two columns rather than one combined figure, because the unit was the actual
defect.** Every findings index has a `Findings` column that holds a count of
findings — `0029` reads 7 and holds seven. `docs/sessions/INDEX.md` has a column
with the same header holding a count of *bundles*: this session's row reads 4
under `Findings` while the session carries 30.

Finding 3 was filed as *"miscounts a manifest it links to"* — a wrong number. It
is a **wrong unit under a right-sounding header**, which is worse, because a
wrong number gets noticed and a wrong unit gets believed. The check decision 3.2
requires would have caught the count drifting and would never have caught this:
`4` was a perfectly accurate count of the wrong thing.

That is also why the check has to compare each figure against a named source
rather than verify internal consistency. A number that agrees with itself proves
nothing about what it is counting. Both are derived from the
`Findings` column each bundle's index row already holds, which is itself derived
from the per-finding table inside `findings.md` — so the chain has one source and
three displays, all covered by the check 3.2 requires.

The check therefore verifies three things, not one: a bundle's stated finding
count against its own `findings.md` table, a session's stated bundle count
against its manifest rows, and a session's stated finding count against the sum
of those bundles.
### Why a rule and not two edits

The same defect is live in a third place this bundle does not name: §4b states
the number of directories under `docs/`, and that number has been wrong after
four of the last six revisions that touched `docs/`. It is recorded separately as
`0029` finding 3, and this decision answers it too — which is worth saying here,
because a rule adopted in one findings bundle and applied in another is exactly
the kind of connection that gets lost.

Diligence was the alternative and it has already been tried. Every one of these
was written by someone who knew the fact at the time; what failed was that
nothing brought them back when the fact changed.

### The limit of the rule

It applies to facts *about the tree* — counts, contents, membership. It does not
mean a document may never restate a rule for the reader's convenience: the status
keys added to the indexes in Revision 173 are deliberate duplication, and finding
2 of `0029` is about a case where that duplication has already drifted. Where the
line falls between a useful restatement and a drifting copy is not settled here.

### What is not done

Both edits, and the §4b count. `resolving` waits on all seven findings.

---

## Finding 5 — a migrated findings bundle owes no `decisions.md`

**Decision 5.1 — a findings bundle migrated into this shape from an
already-closed record carries `resolutions.md` and no `decisions.md`, and its
`resolutions.md` says so.** Owner, 2026-09-03. One sentence in the rules; no file
is created or changed in any of the ten.

All ten were `docs/gaps/` notes whose `**Status: CLOSED**` line already named the
revision that closed them when Revision 162 converted them. There were no
decisions to record because the deciding happened before the lifecycle existed,
and each `resolutions.md` already states that.

### Why not the alternatives

**Backfilling ten stub `decisions.md` files** would produce ten documents whose
entire content is an explanation of their own emptiness. That is conformance
theatre: it satisfies a checker and tells a reader nothing, and it puts ten files
in the tree that a future reader has to open to discover are empty.

**Leaving them non-conforming** was the honest option and was rejected on what it
costs later. Every future conformance read — this bundle is the first of what
will be several — finds ten failures and has to learn to ignore them, which is
how a real failure gets ignored alongside them.

### The general shape, worth stating

The defect is in the rules, not in the bundles. A lifecycle written for work done
under it will always be violated by work that predates it, and the choice is
whether to rewrite the history or to say the history is exempt. This workflow
already answers that consistently — `APPLY-MANIFEST.md` is not retro-edited,
dated artifacts keep their names, a `closed` session's prompt is a record under
decision 2.1 — and this is the same answer in a fourth place.

### What is not done

The sentence itself, which lands in `docs/legend.md` and §4c. `resolving` waits
on all seven findings.

---

## Finding 6 — both diagrams were wrong, and the state set changes

**Decision 6.1 — four session states: `owned`, `handoff`, `closed`,
`withdrawn`. `unclaimed` is dropped.** Owner, 2026-09-04.

The finding asked which of two diagrams was right about one arrow —
`handoff ──▶ unclaimed / owned` in `docs/legend.md` against `handoff ──▶ owned`
in the architecture record. Neither. The arrow describes a transition that cannot
happen, and asking which drawing was correct is how the underlying error stayed
invisible.

### What the mechanic actually is

In the owner's words: an existing session writes the instructions, the prompt and
a title; the owner pastes those into a new session; **the new session creates its
own bundle**; after the commit, the new session is a thing.

So there is never a continuation bundle waiting to be picked up. A session bundle
is created by the session it belongs to and is `owned` from the moment it exists.
Nothing transitions between the outgoing bundle and the incoming one, because
they are two bundles belonging to two sessions.

Revision 161 defined `handoff` as covering *"the continuation bundle prepared for
the next one, until it is owned"*. That sentence invented an object the workflow
does not have, and both diagrams then drew arrows out of it.

### The four states

| State | Means |
|---|---|
| `owned` | A session holds it. Every bundle starts here. |
| `handoff` | Ended by transferring its unresolved findings to a successor. The prompt naming them is in its `handoff-<stamp>.md`. |
| `closed` | Ended having finished the work. |
| `withdrawn` | Ended without finishing, and nobody is continuing it. |

**The three terminal states say how a session ended** — finished, handed on, or
abandoned. `handoff` is terminal rather than a waiting room: the record reads
*this session handed its work on*, not *this session is mid-handover*.

### Why `unclaimed` goes

It existed only to describe a bundle waiting for a session, and no such bundle
exists. Two cases were hiding under it, and neither needs a state:

- **A session writes a brief for a continuation.** That is `handoff`, and it is
  defined by what transfers: ownership of that session's unresolved findings.
- **A session writes a brief for new material.** Nothing about the writing session
  changes — it produced a document and carried on. The successor will own findings
  bundles that currently have no owner, or record new ones.

**Findings bundles without an owner were the real need**, and they are already
served on the other side: `—` in the Session column of a findings index, which is
how `0027` and `0028` sat until the owner assigned them. That is a property of a
findings bundle, not a state of a session that does not exist yet.

### What this supersedes

Revision 161's definition of `handoff`, the five-state table in `docs/legend.md`,
the state key added to `docs/sessions/INDEX.md` in Revision 173, §4d's per-state
requirements for `unclaimed`, and both diagrams. No session in the tree is
currently `unclaimed`, so no bundle needs restating — the change is to the rules
and the two drawings.

**Decision 6.2 — the three terminal states differ by what happens to the
findings.** Owner, 2026-09-04, revising 6.1 on its first real case.

6.1 defined `closed` as *ended having finished the work*, and within the hour a
session ended `closed` with five unresolved findings handed back to unowned.
That reading was too narrow: `closed` **is** completion — of the session, not of
every finding it recorded.

| State | The session | Its findings end |
|---|---|---|
| `closed` | completed | `resolved`, or **disowned and set back to `unresolved`** — still live, simply unowned |
| `handoff` | ended by transferring | carried to the successor at whatever status they hold |
| `withdrawn` | no longer viable — drift, staleness, a sudden pivot | **`withdrawn` or `superseded`**. They die with it |

**The distinction is whether the findings survive the session.** A closed session
finishes and its unfinished readings live on without an owner, waiting for
somebody to pick them up. A withdrawn session takes its readings with it, because
what made them worth acting on has gone.

`final-summary.md` records which disposal happened, by name, for every finding
the session owned. A session may not end leaving a finding owned by a session
that has stopped — the defect Revision 175 removed, now a rule.

An earlier draft of this decision put "handed to a named successor" under
`closed`. That was wrong: transferring is what `handoff` is, and a state that
covered both would make the record unable to say which happened.

### A sixth findings status: `withdrawn`

Owner, 2026-09-04. `superseded` names a replacement; a dropped reading often has
none. A finding can simply stop being worth acting on — the code it describes was
rewritten, the question it asks was answered elsewhere, the machine it observed
is gone — and nothing takes its place.

| Findings status | Means |
|---|---|
| `superseded` | A later bundle replaces this reading. The row names which. |
| `withdrawn` | The reading is dropped and nothing replaces it. The row says why. |

Both are terminal and neither is a failure. The difference is whether a reader
following the trail lands somewhere: `superseded` points onward, `withdrawn` says
the trail ends here and gives the reason — more useful than a bundle quietly left
at `unresolved` forever.

A `withdrawn` findings bundle writes no `resolutions.md`; there are no
resolutions. Its `findings.md` stands as the reading it was, the same treatment
every terminal state in this workflow gives a record.

It also gives `withdrawn` a job on both sides. A withdrawn session must mark
every finding it owned `withdrawn` or `superseded`, and before this status
existed there was nowhere to put a reading that was simply dead.

### What is not done

All of it. `resolving` waits on nothing now — all seven findings are decided.

---

## Finding 7 — a negative must name what was searched

**Decision 7.1 — any `not recoverable` in a `metadata.md` lists the searches that
came back empty.** Owner, 2026-09-04.

The two wrong instances asserted the identifier was unrecoverable because the
session *"left none in anything it wrote"*. That was reasoning, not searching, and
it was wrong on a technicality that matters: the `Claude-Session` trailer is
written by the harness into every commit, so it is not something a session
"wrote" in the sense the note meant — which is exactly how a mechanical record
went unexamined across ten commits.

Naming the searches turns an assertion into a claim a later reader can test.
*"Not found in `git log --grep`, not found in the session's own documents"* tells
the next person where to look next; *"not recoverable"* tells them to stop.

### Why not the stronger version

Banning the assertion outright — always *"not recorded"*, never *"not
recoverable"* — was considered and rejected. Some things genuinely are gone, and
a record that cannot say so forces every reader to re-run searches that have
already failed. The weaker rule keeps the strong statement available and makes it
earn itself.

### The instance still open

`restore-git-phase-11a-20260901-155433/metadata.md` carries the same *"not
recoverable"* wording and was never checked. `0027`'s own text flags it as
possibly a different case: that session predates the trailer convention. Under
7.1 it is checked during `resolving`, and whatever the answer, the file records
what was searched.

### The general property

A `metadata.md` is written once and read years later by someone with no other
source. A negative in it is the one kind of statement a reader cannot verify
without redoing the work — so it is the one kind that has to carry its evidence.
