# Session management — how a session works in this repository

**This file governs sessions, findings bundles and the records under `docs/`.**
It says nothing about what this project does. For the project's own subject — its
work, its scripts, its conventions — read
[`.github/toolkit-instructions.md`](toolkit-instructions.md).

**It is deliberately project-agnostic and is meant to be reusable as-is.** The
only project-specific things in it are the link above, the paths under `docs/`,
and the helper named in section 7. Nothing else should acquire a project detail:
an example that only makes sense here is a defect, because the next project
inherits it and it reads as noise.

**Read this before doing anything else.** The vocabulary it uses —
every status and state — is defined once, in
[`docs/legend.md`](../docs/legend.md), which is required reading alongside this
file. Nothing here restates a definition; a count or a meaning written twice is
a copy nobody maintains.

---

## 1. The two objects

A **findings bundle** is a *reading* of something that already exists: what was
found, where it is felt, what it costs to leave. It holds findings; each finding
carries its own status, and the bundle's status is derived from them.

A **session** is a unit of work with an owner. It creates its own bundle, owns
findings bundles, and its state is derived from what it owns.

Neither directory name carries the other's identifier, so neither has to be
renamed when the relationship changes. The pointer runs both ways: a session's
`findings-manifest.md` is authoritative for what it owns, and each bundle's index
row names the session working it.

### How the two meet

A session owns findings; a finding is worked by a session. The pointer runs both
ways and neither side is derived from the other:

- the session bundle's `findings-manifest.md` lists every finding it owns —
  authoritative for ownership;
- each findings bundle's INDEX.md row names the session working it.

A finding can outlive several sessions, and a session can own several findings.
Neither directory name carries the other's identifier, so neither has to be
renamed when the relationship changes.

## 2. The three findings trees

**`docs/session-management-findings/` is the only tree this file governs.** It
holds findings about **how sessions and findings bundles themselves work** — the
statuses, the states, the rules binding them, and the checks that hold them. Its
fixes land in this file or in `docs/legend.md`.

Every other tree belongs to the project and is described in
[`.github/toolkit-instructions.md`](toolkit-instructions.md), which is where a
project lists its own. **Nothing that is not strictly about session management
goes in this tree.**

**The test is one question: would this finding still exist in a project that did
something else entirely?**

If yes, it belongs here — who may read a finding, when a bundle may be written
to, what a status means, what a check must catch. Those travel to any project
that adopts this structure. If no, it belongs to the project: a defect in one of
its scripts is its own, and so are the rules for writing them. **A defect in the
rule that says when a session may edit that script is session management**,
because that rule is the same wherever this structure is used.

Numbering is ONE sequence across **every** findings tree in the project, so
`finding <NNNN>` names a bundle without needing its tree. Four digits, zero-padded, never reused, never
renumbered — a renumber breaks every prompt already written against the old one.
Take the next free number immediately before writing; another session may have
taken the one you saw:

```text
ls -d docs/*-findings/[0-9]*/ docs/*-findings/*/[0-9]*/ 2>/dev/null
```

`docs/INDEX.md` is the map of `docs/` and owns the list of its directories. This
file does not enumerate them.

## 3. A findings bundle

A numbered directory, because a finding accumulates documents as it is worked and
they are only legible together:

```text
<NNNN>-<slug>/
|-- metadata.json    the data. Status DERIVES from the findings in it
|                    without opening anything. It must agree with the INDEX.md
|                    row, which is authoritative. Spaces become hyphens.
|-- findings.md      the reading, and the per-finding status table
|-- decisions.md     what was decided for each finding, and the alternatives
|                    rejected. A decision without its rejected alternatives is
|                    an assertion.
`-- resolutions.md   what was actually done, with the commit hash and the
                     APPLY-MANIFEST.md revision carrying each one.
```

The tag is a marker file, **not** a suffix on the directory name. The directory
name is what prompts, indexes and other bundles cite by path; renaming it on
every status transition breaks every one of those citations at once, which is why
the status lives in a file inside the directory rather than in its name.

**`findings.md` carries a per-finding status table.** The bundle's status is read
off it by the ladder in `docs/legend.md` — first row that matches wins. A tag or
an index row that disagrees with the findings is a bug in whoever moved it last.

## 4. Permission

Carried by the **finding**, not the bundle. The bundle status is what another
session checks first, to know whether opening it is worth anything. The table in
`docs/legend.md` is the rule; in short:

- **Only the owning session opens a finding.** `un-started` and `reopened` are
  invisible to everyone else, and the owner's first reading moves either to
  `framing`. Writing a bundle up is not a reading — a session may record a bundle
  it never owns.
- **`framing` is open to every session** to read and record — the reading *and*
  the decisions. Any session may sharpen a finding's wording, add detail, correct
  it, take it out if it does not hold, and equally may **write a decision, reject
  one, or refine one**: a row in the Decisions table and its section, or an
  existing row's `Outcome` set to `rejected` or `refined → DX` with the reason.
  **Deciding is not the owner's privilege; closing the deciding is.** A reading is
  not diminished by a second reader, and a second reader who disagrees with a
  decision improves it more. A decision written by a session that does not own
  the finding goes in the bundle's Contributions table like any other.
- **`decided` is read-only to everyone but the owner**, and moving a finding
  there is the owner's act. It marks that the deciding is closed, and that is the
  only thing it marks.
- **`resolved` is frozen.** `reopened` is the only door, and going through it is
  a declared act.
- **`unclaimed` is closed to everyone.** It is parked until the owner assigns it.

## 5. Sessions

```text
docs/sessions/<title>-<stamp>/
|-- metadata.json          the data. State DERIVES from it, as in 3.
|-- prompt.md              what starts the session. Required, always.
|-- metadata.md            who and what has owned it. Required from the start.
|-- findings-manifest.md   the bundles this session owns. Required once it
|                          owns one. AUTHORITATIVE for ownership.
|-- handoff-<stamp>.md     one per handover; never edited afterwards.
`-- final-summary.md       written at `closed` or `withdrawn`.
```

`<title>` is a short readable scope; `<stamp>` is `YYYYMMDD-HHMMSS` in
**America/New_York**, the artifact-root format. **The zone is named rather than
left as *local* because a session almost never runs in it**: an assistant working
in UTC that reads *local* as its own produces a stamp hours ahead of a bundle
created before it, and the sequence a stamp exists to carry stops holding. The
same zone governs every `Recorded:` date. A stamp or date already written is
evidence and is never restamped to match this rule. The name carries no finding number — a session routinely
owns several — and is fixed at creation.

**`metadata.md` is authoritative for who and what.** One row per owner: the
assistant (`Claude` or `Copilot`), its session identifier and transcript link
where the tool exposes one, the model it was configured for, **the environment it
actually ran in**, and the dates it held the bundle. None is edited once the
ownership it records has ended.

**Every value in it is resolved.** Not a placeholder, not an angle-bracketed
name, not a variable — the absolute path, the real identifier, the actual commit.
This file is read years later by someone with no other source and no way to
expand a placeholder, and an unresolved one is indistinguishable from a fact
nobody recorded. The same holds for every document in a bundle. **A placeholder
belongs in a schema or a template, never in a record.**

The environment field is not decoration. This repository targets macOS stock Bash
3.2; an AI session almost never runs there, and a claim validated on Linux is a
different claim. **Any `not recoverable` names the searches that came back
empty** — three identifiers so recorded have since been found in the
`Claude-Session` commit trailer, which the harness writes, so a session looking
for what it "wrote" finds nothing and concludes wrongly.

`docs/legend.md` carries how a session begins — created, cloned, or handoff — and
exactly what transfers at a handoff. This file does not restate it.

## 6. Writing

**The record covers this repository, and the rules governing it live in this
repository.** A session may have several folders connected and may legitimately
work in more than one; only this repository's work is recorded here -- no manifest
entry, no finding, no resource row for a folder that is not this repository's
subject or its evidence. And a rule the framework depends on is not left in a file
outside it. `0039` D19, which closes F19 and F9 with one sentence in each
direction.

**Connection is availability; scope is subject.** The artifact volume is not a
connected folder and is squarely in scope; a folder can be connected for one
lookup and be nobody's business. The session bundle's `prompt.md` states the
subject, and that is what to measure against.

Four kinds of write. Three are defined in `docs/legend.md`: **record** (`docs/`),
**toolkit** (anything else tracked), **evidence** (the artifact volume). The
fourth is **`foreign`** -- a write to any other connected folder. It is ordinary,
it happens when the owner asks for it, it takes no revision, and **it is not
recorded here.** It is named so the case is excluded deliberately rather than by
omission: an unnamed case reads as *not covered* and behaves as *not thought
about*.

**What they mean is in the legend; when each is allowed is here** — `0039` D2 ruled that split
on 2026-09-04 and D13 carried it out. The legend used to hold both, and §6 used
to point at the legend for the gating, so the two files agreed with each other
and both disagreed with the decision.

**A record write is never gated.** Gating it would make deciding impossible: a
decision is a record write, so a rule requiring a decision before a record write
could never be satisfied from a standing start.

**A toolkit write is gated on a `decided` finding.** The finding names what
changes and why, and the write carries it out. Without one there is no record of
what the change was for, which is the state every archaeology in this repository
has run into.

**An evidence write is granted by the owner, per run.** Anything run against the
artifact volume is read-only unless the owner has said otherwise for that run.
A bad evidence write may be unrecoverable.

Where a write is composed is a separate rule and applies to all three:

- **Compose in a copy of the repository outside the owner's checkout.** Copy the
  checkout to session-local storage, edit there, run the validators there, then
  `git diff` and hand the owner a patch. Two sessions editing one working tree
  produce a diff neither can be committed out of, and validator numbers that
  belong to whoever else was writing.
- **Validate in the copy.** Every checker self-locates and none invokes git, so
  they run in a copy unchanged — and only there do the numbers describe your
  change.
- **`git apply --check` before applying, and say so.** It passes on a patch that
  will under-apply.
- **The exit status says nothing, and neither does the warning.** Where the
  working copy sits on a mount that refuses `unlink`, `git apply` downgrades the
  failure to a warning and **exits 0**. This is not only about deletions: a file
  is modified by writing a replacement and unlinking the original, so the refusal
  fires on plain modification too. The difference is recovery — a modification
  has a fallback and lands; a deletion has none and the file survives. **So the
  warning appears on patches that applied perfectly**, and cannot separate the
  two cases. Verify by comparing the two trees, or by comparing every path the
  patch touched; not the exit code, and not a checksum of the files the patch
  names, which sees only what the patch carries as content.
- **A tag change WAS invisible to the patch itself.** Tag files were removed
  at Revision 222 and a status is now a value inside `metadata.json`, so a
  status change is an ordinary diff. Retained because it explains four recorded
  incidents and because the same trap applies to any file a patch renames: `STATUS-` and `STATE-` files
  are empty, and `diff` emits no hunks for an empty file — it reports it as
  present on one side only, which is not patch content. A patch derived from your
  copy therefore carries every prose change and **none of the tag renames**, and
  applies successfully having done half the work. Make the renames explicitly
  beside the patch, and verify by comparing the trees rather than the patch's
  file list.
- **The owner asks before a patch is applied.** Composing is not delivering.
  Report what you composed, show it, and wait.
- **Ask for delete permission before applying, not after it fails.** The
  connected folder refuses `unlink` until the owner grants deletion for it, and
  **every status transition is a delete plus a create**, so this reaches every
  `STATUS-` and `STATE-` change. The grant is per folder, for the session, and
  **does not survive a bridge reconnect**. Where it is declined or goes
  unanswered, move the file into a `_to_delete/` subfolder under the same
  connected folder and tell the owner — never leave two tags on one bundle.
- **A copy in session-local storage dies with the session.** Hand over at natural
  stopping points, and say plainly when work exists only there.

**The owner reviews and commits every change. Never commit, never push, never
rewrite history in the owner's checkout.** Staging inside your own copy to get a
baseline to diff against is not a write to the owner's repository; staging in the
owner's checkout is.

## 7. APPLY-MANIFEST.md

Every change of any kind takes a revision — a record write as much as a toolkit
one. A revision covers a **change**, not a file: three notes parked in one
sitting are one entry, the same way a revision editing nine documents is one.

**Take the number at apply time, not while composing**, with

```text
./bin/verify-session-findings.sh manifest-revision
```

run against the tree being applied to. **Choosing while composing is a guess**,
and two sessions can follow *re-read the header and take the next free number*
exactly and still collide — because an entry that is written but not yet
committed is not in the header the other session reads. The helper scans the
entry headings as well as the header, so it sees what the header misses, and at
apply time only one session is writing.

Entries are never retro-edited. A revert is a new entry naming what was reverted
and the commit it reverted, never an edit to the entry being undone.

### The commit message, when the owner asks for one

**Keep it short**: a subject line under about 70 characters, then a body of one or
two short paragraphs saying what changed and why. The manifest entry is where the
reasoning lives; the message names the revision and points at it rather than
restating it. If the first draft runs long, cut it before offering it — the owner
should not have to ask twice.

**The block you hand over is the message and nothing else.** No `git commit`, no
`-m`, no quoting wrapper, no shell around it. The owner commits with a plain
`git commit` and pastes into the editor, so a command in the block is something
they have to delete before using it.

Anything the owner might need to *run* — a command, a flag, a reminder about
staging — goes in the conversation beside the block, not inside it.

End with the `Co-Authored-By` and `Claude-Session` trailers.

## 8. Reading before working

- `docs/legend.md` — every status and state. Required.
- The INDEX.md of the tree you are working in, and `docs/sessions/INDEX.md`.
- The bundle itself, not a summary of it.

**Write findings rather than widening the task.** Finding a second defect while
fixing the first is normal; fixing both in one change is how a small edit becomes
an unreviewable one. Park it as a bundle and say so.

**One file per item, named for the thing rather than the date.** A dated filename
sorts by when someone noticed, which is never the question being asked. Findings
bundles are the exception and say why: a finding accumulates documents as it is
worked, and they are only legible together.

**A fact has one home.** A count, a membership, a description of what something
currently holds: write it once and link to it. A copy is permitted only where it
is generated, or where a check fails when it drifts — an unchecked hand-typed
copy is the defect, not the display.

**Completeness is not conformance.** A check answers whether a document is well
formed. **None answers whether it is complete**, and opening the rendered page
does not either, because a rendering cannot show content that is not there. A
file that has lost half of itself keeps a valid header, a well-shaped table and a
clean render, and passes everything. So when you generate or rebuild a document,
verify its content against its source — every line of the input accounted for,
every section that should exist existing. **Never redirect into a file you are
reading from**; write to a temporary file and move it into place.

**Know what each check does not examine, and do not quote it as though it does.**
Two that recur: a check that resolves links says nothing about the shape of the
table they sit in, and a check that verifies the counts a table displays need not
cover a total written as a sentence beneath it. *The checks are clean* is a claim
about the properties they examine and about nothing else.

## 9. Superseding a bundle

**A bundle is replaced whole by a later one. It reaches a bundle at ANY status**
— there is no state in which a reading cannot be replaced. An earlier rule tied
it to a bundle being overtaken mid-work, which left the commonest case unhandled:
a settled bundle whose owning session has ended, with nobody able to perform the
supersession at all.

Never a single finding: correcting one resolution is `reopened`.

**A superseded bundle is readable by any session and writable by none**,
including the session that owns it. It is retained precisely so it can be read --
this is where a reader finds out why something changed, and when.

**The session with the new reading does it, and does not take ownership.**
Superseding is not inheriting.

### Three things it must NOT do

- **The superseded `findings.md` is not edited.** Not to add a pointer to its
  replacement, not to repair a citation inside it, not to soften a conclusion.
  The two pointers below are where the structure puts them. A reading is retained
  by being left alone, and one that shows a diff was not retained.
- **The number is never reused and the directory never renamed.** A number must
  keep naming exactly one bundle; two siblings cannot carry one, so reuse makes
  retaining the original impossible.
- **The bundle does not move between manifests.** It stays listed by the session
  that held it, with only its status changed. That file is authoritative for who
  held a reading, and a supersession changes neither who recorded it nor who held
  it.

### The steps

1.  Take the next free number immediately before writing — another session may
    have taken the one you saw.
2.  Create `<NNNN>-<slug>/` with its tag and `findings.md` carrying the reading
    forward. **Cloning the original is the usual way and is not required**; a
    replacement may start from work already begun. What matters is that it
    carries the reading and names what it replaces.

3.  The new `findings.md` header carries `Relates to`, naming what it replaces:

        **Relates to:** `<NNNN>-<slug>` -- **supersedes it.**

4.  Nothing to rename: `superseded` derives from the predecessor's `lineage`
    field in `metadata.json`, which the new bundle's provenance sets. **Do not
    set it before coverage
    and exclusivity pass**: a tag applied over an incomplete accounting is the
    state nothing can recover from, because the predecessor may not then be
    edited to fix it.
5.  In the old bundle's INDEX.md row, THE STATUS CELL BECOMES THE LINK —
    `[`superseded`](<new-bundle>/)` — **always a link, never the bare word** — so one cell answers both what state the
    bundle is in and what replaced it. Notes records that the reading is retained.
6.  Add the new bundle's row, naming the superseding session, or `—` where the
    replacement is not yet owned.
7.  Add it to that session's `findings-manifest.md` and update its counts in
    `docs/sessions/INDEX.md`. **The originating session's bundle count does not
    change** — the superseded bundle is still listed there.
8.  **The new bundle gets no `decisions.md`.** The predecessor's decisions were
    taken against the predecessor's framing, and it is retained whole, so the
    history is preserved where it was made. An earlier rule required the new
    file to re-affirm or drop each of them; that asked a fresh bundle to answer
    the old bundle's questions. The accounting it protected has moved to the
    finding layer, below, where coverage makes a silent loss impossible.
9.  One `APPLY-MANIFEST.md` revision covers the whole supersession.

### Provenance, and the gate on the tag

**Every finding of the predecessor is accounted for**, as provenance edges stored
in the NEW bundle. The predecessor is never edited, so provenance cannot live
there; and it is a property of the relationship rather than of either bundle, so
it is an edge at finding granularity rather than a field on either side.

The five edge kinds and their reasons are defined in `docs/legend.md` ->
Provenance: `carried`, `successor`, `split`, `merged`, `dropped`. **`new` is
derived from the absence of an incoming edge and is never stored.**

Two rules gate the tag in step 4, which makes the accounting a precondition
rather than a follow-up:

**Coverage.** Every predecessor finding is named by at least one disposition
edge. Zero is the real failure -- a finding silently lost, which the procedure
had no guard against at all.

**Exclusivity.** A predecessor finding disposed `dropped` carries that edge and
no other. Dropped-and-also-carried is the contradiction worth catching.

*Exactly one edge per finding* was the first draft of both, and it rejects a
legitimate split or merge: a split gives one predecessor finding several edges,
a merge gives one successor several sources, and both are ordinary.

Where the originating session is `closed`, its `final-summary.md` is never
edited; the index row and the new bundle's `Relates to` are the record. If its
manifest lists the bundle, only the status cell changes.

`superseded` where another bundle carries the reading forward; `withdrawn` where
the reading is dropped and nothing replaces it. If a replacement is being opened,
it is `superseded`.

## 9a. Reopening a finding, and withdrawing one

**`reopened` is the only door out of `resolved`**, and it takes a reason. The
vocabulary is in `docs/legend.md` -> Reasons; this section is the procedure.

### Reopening

Record four things, and the fourth is what makes the other three checkable:

- `reason` -- one of the nine. Free-form prose is not a reason.
- `note` -- optional, and where the elaboration goes.
- `reopened_at` -- when.
- the **commit SHA** at reopen time, alongside the finding, decision and
  resolution ids.

**The reason determines the exit status**, so it is not decoration. A fault in the
*work* -- the six `resolution-*` reasons -- leaves the decision standing, and the
finding returns to `decided` for the work to be redone. A fault in the *decision*
or the *framing* returns it to `framing`. Deciding the exit from the reason
removes a judgement call at the moment someone is already annoyed about a bug.

**`reopened.md` is GENERATED from those fields**, rendering the state as of that
SHA. Do not hand-write it and do not copy the finding, decision or resolution
into it. A snapshot is a second copy of a fact and will drift; the SHA is a
reference that cannot. It is a projection like every other generated document --
`docs/architecture/state-as-data.md` section 6.

**A `reopened` finding persists until the record materially changes.** Reading it
is not a change. Assignment is not, a sweep is not, a rename is not, a retrofit
is not. Its exits are the events in the legend's diagram, and nothing else moves
it.

### Withdrawing

A `reason`, an optional `note` and `withdrawn_at`, **per finding**. Withdrawing a
whole bundle requires one for every finding in it -- which keeps bundle
`withdrawn` derived rather than declared, and makes withdrawing a bundle cost
exactly as much thought as the findings in it.

**A `resolved` finding is reopened first.** `withdrawn` reaches every status
except `resolved`, which is frozen. Stating it here is what stops someone trying
it and reading the refusal as a bug.

## 9b. Resolving a finding

**Three steps, in this order.** The row is the evidence the status asserts, so it
is written before the status moves.

1.  **Carry out the decision.** A toolkit write, gated on the finding being
    `decided` -- section 6 unchanged.
2.  **Write the `resolutions.md` row**: the finding, the decision that resolves
    it, what was actually done, the revision, the commit. The revision is taken
    at apply time like any other. The file's shape is in section 11.
3.  **Move the finding to `resolved`.**

Reversing steps 2 and 3 produces a `resolved` finding with nothing behind it,
which nobody can check. `0037` F5 recorded that state from the other direction:
every `resolved` bundle missing its `decisions.md`.

**A `decided` finding whose decisions have been carried out and which has no row
is a defect.** Not derivable in full -- whether a toolkit write happened is a fact
about the tree rather than about the data -- but a missing row under a decided
finding has the same shape as section 9's coverage clause and D15's citation rule:
the failure worth catching is zero.

**`resolutions.md` is not required.** A bundle that has resolved nothing correctly
has no such file, for the same reason a bundle that has decided nothing has no
`decisions.md`. Requiring it would fail every `framing` bundle in the tree.

This procedure exists because it did not. Every other lifecycle event -- superseding,
reopening, withdrawing, transferring -- had numbered steps; the commonest one had a
file schema and no instructions, and seven resolutions went unwritten across five
revisions because nothing prompted them. `0039` F17 and D18.

## 10. Transferring a bundle

**One bundle moves from one session to another.** A `handoff` moves everything a
session holds and is a property of the session; a transfer moves one bundle and
is a property of the bundle.

**The target session must already exist** — created, cloned, or long running.
A handoff creates its destination; a transfer names one.

A bundle may be transferred while it is `un-started`, `reopened` or `analyzing`.
The terminal statuses have nothing to move, and `unclaimed` has no owner to move
it from — assign it instead.

### The steps

1.  Set the bundle's `ownership` to `transferred` in `metadata.json` and its index Status cell to
    `` `transferred` ``, naming the target session in the Session column.
2.  Remove its row from the outgoing session's `findings-manifest.md` and add it
    to the target's.
3.  Update both sessions' counts in `docs/sessions/INDEX.md` — decrement the
    outgoing, increment the target. The bundle's own finding count does not
    change; it moved, it did not split.
4.  Record it in `metadata.md` on **both** sessions: a transfer is a change of
    ownership and that file is authoritative for who held what, and when.
5.  One `APPLY-MANIFEST.md` revision covers the transfer.

**The transfer ends when the target session reads the bundle.** At that point
`transferred` stops applying, the findings awaiting a first read become
`framing`, and the bundle derives its status normally — which is `analyzing`.
Nothing else about the reading changes: no finding is reverted, no decision is
re-opened, and `decisions.md` and `resolutions.md` stand as they were.

**Transferring part of a bundle is not supported.** The need is real and has
arisen more than once; the options and what each costs are in
`docs/architecture/transferring-part-of-a-bundle.md`. Until one is chosen, a
bundle moves whole or not at all.

## 10a. Releasing a bundle to `unclaimed`

**A bundle put back in the queue rather than handed to a named session.** Transfer
names a target and the bundle stays owned; release names none and the bundle is
closed to everyone until the owner assigns it. Choose by whether a taker exists.

**Four steps. There is no step for setting the status.** Since Revision 222
ownership is DERIVED -- computed by scanning the session manifests -- so removing
the row IS the release and `unclaimed` follows from it.

1.  **Remove the bundle's row** from the releasing session's
    `findings-manifest.md`.
2.  **The bundle's index row**: Session cell to `—`, Status cell to
    `` `unclaimed` ``.
3.  **Decrement the session's `Bundles` and `Findings`** in
    `docs/sessions/INDEX.md`.
4.  **Record the disposal in the session** -- `final-summary.md` on closing, the
    handoff document otherwise -- naming each bundle and why it was released.

**Step 4 is not optional.** A released bundle leaves no trace in the session that
held it: the manifest row is gone and the index row names nobody. Without the
disposal record the reading's history stops at the moment of release, and a later
reader cannot find out who held it or in what state it was left. Section 9 keeps
a superseded bundle listed by the session that held it for the same reason;
release cannot do that, so the disposal record is where the history goes instead.

**A session may not end holding a bundle.** `docs/legend.md` requires a `closed`
session's bundles to be terminal or released. Revision 200 found `phase-11b`
closed while still holding five, and `0008`, `0011`, `0015`, `0016` and `0017`
were released after the fact by a session that had to notice the problem first.
`0039` F20 and D20.

## 11. The `findings.md` header

Every `findings.md` opens with the same block, in this order. It is a schema, not
a suggestion: a reader and a checker should both be able to find a field without
reading prose.

```text
# <the finding bundle's title, as a sentence>

**Recorded:** <YYYY-MM-DD>, <the occasion, if there was one>
**Session:** `<session-bundle-name>` (`<session identifier>`)
**Severity:** <what it costs to leave, and which finding is the high one>
**Felt at:** <where the defect shows — files, steps, artifacts>       optional
**Scope:** <where the fix lands>                                     optional
**Relates to:** `<NNNN>` — <how the two bear on each other>  optional, repeatable

## Contributions

| Session | Date | Contribution |
|---|---|---|
| `<session-bundle-name>` | <YYYY-MM-DD> | <what it added or corrected> |

## Findings

| # | Finding | Status |
|---:|---|---|
```

### One field, one line, and a hard break

**Each field occupies exactly one source line, and every line but the last in the
block ends with two spaces.** Markdown joins consecutive lines into a single
paragraph, so a header written without the hard breaks renders as one run-on
sentence with the field names buried in it — five labelled facts collapsing into
prose nobody can scan. Forty-one files did this, and it went unnoticed because
every check read the source rather than the rendering.

The two spaces are invisible in the file, so here they are marked with `·`:

```text
**Recorded:** 2026-09-04, `restore-apps-outstanding-20260903-000000`··
**Severity:** finding 5 is high — 48 evidence artifacts carry raw escape codes··
**Scope:** `.internal/`, the authoring template, the two report producers
                                                                        ↑↑
                                          every line but the last, and only those
```

A long value stays on its one line. Wrapping it is what breaks the block.

`./bin/verify-session-findings.sh headers` checks both halves — the wrap and the two
spaces.

**Expect a trailing-whitespace warning from your tools, and do not act on it.**
The two spaces are trailing whitespace, so `git apply` warns on every conformant
header block it carries, and an editor set to strip it on save will break the
rendering this rule exists to protect. The warning is the schema being obeyed.

**Fence every example as `text`, never as `markdown`.** A block tagged
` ```markdown ` is read by some renderers as *render this as markdown*: the
example is interpreted rather than shown, the hard breaks are joined back into
paragraphs, and the specification displays as the defect it exists to prevent.
That happened to this section twice — once as a four-space indented block, once
as a `markdown`-tagged fence. `text` is inert everywhere.

### `Session:` is its own field

**The session is never packed into another field's value.** It was written as
*"2026-09-01, session `01KcZ…`, item 2"* — a date, a session and a circumstance
in one sentence, with the one machine-readable part in the middle. Now
`Recorded:` carries the date and the occasion, and `Session:` carries the
session, on its own line, bolded like every other field.

It holds the session-bundle name, the identifier, or both:
`` `restore-apps-outstanding-20260903-000000` (`session_016Ebj…`) ``.
**Where no session was ever recorded it holds `—`.** Twenty-three headers do.
That is a gap in the record, and writing it as a dash says so; inventing a
session to fill the field would not.

**Required: `Recorded:`, `Session:` and `Severity:`** — the fields every reading
in the repository has once the session is separated out. **Optional: `Felt at:`, `Scope:`, `Read:`, `Relates to:`.** `Read:` is the one
field whose value is a bulleted list beneath it rather than text on the field's
own line; the two-space rule governs the fields around it, not its bullets. The
rule that matters is the last one in the block above: **no other field appears in
the header.** The schema fixes the vocabulary, not the content — requiring
`Scope:` would mean inventing one for the readings that never had it.

**`Recorded:`** is the date the reading was written down, not the date the defect
began. Always this word; `Found:` meant the same thing and is not used.

**`Felt at:` and `Scope:` are different questions** and the tree test turns on the
difference. `Felt at:` is where the defect shows — the file, the step, the
artifact. `Scope:` is where the fix lands. A defect in shared machinery felt in
one runbook is the case that needs both.

**`Read:`** is optional: what the reading was taken against, as a bulleted list
under the field. It was prose inside `Recorded:` — *"Read: A, B, C, and every
bundle in `docs/`"* — a list flattened into a sentence, which is a list nobody
can scan or add to. `decisions.md` called the same thing `Read against:`; one
name, and it is `Read:`.

```text
**Read:**

- `docs/architecture/findings-and-sessions.md`
- §§4b–4d, in `.github/copilot-instructions.md`
- every bundle and index in `docs/`
```

**`Relates to:`** is optional and repeatable, one line each. `superseded` uses
the same field to name what it replaced.

**`Contributions`** lists every session other than the owner that added a
finding, corrected one, or contributed to a decision — the thing a
`framing` finding invites. **Omit the table when there are none**; an empty table
is noise. Ownership is not a contribution and does not appear here: it is in the
index row and in `findings-manifest.md`.

Anything else — a gate, a status note, an owner's direction — goes in prose below
the header, not as an invented field. **Two field names are retired and must not
come back:** `Owner:`, whose values were *"unassigned"* and file paths rather
than a session, and `Status:`, which meant a lifecycle status in some bundles and
*"closed by revision N"* in others. Both duplicated facts the index row and the
tag already own, and both misled.

`./bin/verify-session-findings.sh headers` enforces this. Fields that appear in one bundle
and nowhere else are how a schema stops being one — seventeen distinct names
across forty-one readings is what it looked like before there was one.

### The Findings table

**Required — including when the bundle holds a single finding.** Twenty-six
bundles had none, and nothing caught it: `./bin/verify-session-findings.sh counts` returns
1 when it finds no table, so a missing table read as *"one finding"* and agreed
with every index that counted it.

Finding numbers are **`F1`, `F2`** rather than bare digits, so a citation from
`decisions.md` — *"Findings: F1, F3"* — means one thing.

```text
## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | <the finding, as a sentence> | `framing` |
```

Then one free-form section per finding, heading matching the row:
`## F1 — <the finding>`.

### `decisions.md`

Header: **`Bundle:`**, **`Session:`**, and the date the work was done —
`Recorded:`, `Decided:` or `Resolved:` as the file warrants. Then the table.
`Findings bundle:` meant the same as `Bundle:` in some files and is retired.

**There is no `Status:` field here.** It was a third copy of the bundle's status,
after the `STATUS-` tag and the index row, and by Revision 202 seventeen of them
had gone stale — `0005`'s said `in progress` on a bundle that was `resolved`, in
a vocabulary that no longer existed. `Status when opened:` and `Status now:` were
the same copy wearing a date. The tag and the index row own the status; a
document that restates it is a document that will contradict it.

```text
## Decisions

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | <the decision, as a statement> | F1, F2 | <date> | `accepted` |
| D2 | <…> | F3 | <date> | `refined → D4` |
```

**`Outcome`** is one of the seven in `docs/legend.md` -> Decision outcomes:
`proposed`, `accepted`, `rejected`, `deferred`, `retracted`, `replaced → DX` or
`voided`. **No Outcome value is ever also a status value** -- `superseded → DX`
was, and a reader who learned one meaning read the other wrong.
**Any session may add a row or change an `Outcome` while the finding is
`framing`**; from `decided` onward only the owner does.
**A rejected or refined decision keeps its row and its section.** That is the
record of what was considered, and deleting it leaves an assertion — a decision
without its rejected alternatives is exactly what this document exists to
prevent.

**`Findings`** names the findings the decision answers. **Always — there is no
`—` here.** Revision 219 retired the exemption that let a one-finding bundle
leave it blank on the reasoning that the citation was derivable, and
`verify-findings-headers.sh` D15 enforces the ruling: always a table, always a
citation. `F1` costs one cell.

This paragraph read *"or `—` where the source never said, it is not inferred"*
until Revision 230, which is the rule the check was written to replace. Thirty
decisions in six bundles still carried `—` because the schema said they could.
**Where a citation genuinely is not derivable it is a reading, not a formatting
gap**: the decision is read against its findings and cited, by a session that may
open that bundle.

Then one section per decision: `## D1 — <the decision>`, free form beneath.
`Decided:` and `Rejected:` stay inside those sections as markers, not header
fields.

### `resolutions.md`

Same two header fields, then:

```text
## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F1 | D1 | <what was actually done> | 198 | `4626eb4` |
```

**`Resolved by` is the decision**, not the revision. **`Revision` and `Commit`
are separate fields** because one can exist without the other: revisions before
141 have no commit derivable from the log, since those messages describe the
change rather than naming its number.

A finding closed before this shape existed carries `—` in `Resolved by`; a
withdrawn finding carries `—` throughout and owes no resolution.

**`Finding` holds the number alone**, not the number and the sentence. The
sentence has one home, which is the Findings table.

**The three files must agree.** Every `F<n>` cited by `decisions.md` or
`resolutions.md` exists in `findings.md`, and every `D<n>` a resolution resolves
by exists in `decisions.md`. `./bin/verify-session-findings.sh headers` checks this in both
directions — a citation that resolves to nothing is how a table stops being a
record and becomes decoration.

### `findings-manifest.md` and `metadata.md`

```text
| # | Bundle | Kind | Subject | Findings | Status | Notes |
```

`Bundle` is a link. `Kind` is one of `runbook`, `cross-cutting`,
`instruction-set`, `session-management`, written in the cell as code. `Notes` is
what this session owes the bundle.

`metadata.md` carries `## Owners`, `## Environment`, `## Resources` and
`## Contributions`, and its Owners table is
`| From | Until | Assistant | Session id | Model | Environment |`.

### The narrative files

`prompt.md`, `handoff-<stamp>.md` and `final-summary.md` have **no schema** —
they are narrative, and a rigid one produces empty headings. A required minimum
only: a prompt names its reading order and its task; a handoff names what
transfers, what is known broken, and what is owed; a final summary names every
bundle the session owned and that bundle's disposal, by name.

### Reformatting is not a change

Bringing a file onto these shapes — renaming a field, reordering the header,
moving an off-schema field into prose, adding a table built from what is already
there — **is not an edit to the reading** and does not need `reopened`, even on a
`resolved` or `superseded` bundle. What is frozen is the content. A revision that
reformats says so, and says that nothing beneath the schema was touched.
