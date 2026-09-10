# Procedure — when a write is allowed, and in what order

> **Role.** Permission and sequence. What a session may write, at what moment, in
> what order, and what it owes when it stops. **Section 0 is the working cycle
> and is not optional.**
>
> **Authoritative for** *when* something is allowed and *in what order*. **Not**
> authoritative for what any word means — that is
> [vocabulary.md](vocabulary.md), and nothing here restates a definition from it
> — nor for what event moves a value ([lifecycles.md](lifecycles.md)), the fields
> a record carries ([schema.md](schema.md)), or what sorts of dossier exist
> ([shapes.md](shapes.md)).
>
> **Where two documents answer one question, the precedence order decides**; the
> map is [rules.md](rules.md). A document disagreeing with something above it is
> a defect to record, not a rule to follow.
>
> **Project-agnostic and reusable as-is.** An example that only makes sense in one
> repository is a defect here: the next project inherits it and reads it as noise.

**Read the vocabulary first, then this.** Nothing below parses without it and
nothing below restates it. A session that has to be told something not in these
files is a finding against them.

## Contents

- [0. The working cycle](#0-the-working-cycle)
- [1. Reading before working](#1-reading-before-working)
- [2. The four write categories, and when each is allowed](#2-the-four-write-categories-and-when-each-is-allowed)
- [3. Where a write is composed](#3-where-a-write-is-composed)
- [4. Numbering](#4-numbering)
- [5. The revision manifest, and the commit message](#5-the-revision-manifest-and-the-commit-message)
- [5a. The shapes a write must land in](#5a-the-shapes-a-write-must-land-in)
- [6. The owner's override](#6-the-owners-override)
- [7. Concurrency](#7-concurrency)
- [8. What a session owes at each transition](#8-what-a-session-owes-at-each-transition)
- [Provenance](#provenance)

---

## 0. The working cycle

**This is the loop everything else serves**, and what makes several sessions at
once work where earlier attempts did not. **Steps 1 and 2 are absolute; step 6 is
the only exception to step 1, and it requires the owner's words.**

1. **Compose in a scratch copy outside the owner's checkout.** Copy the checkout
   to session-local storage and edit there. **Never edit the checkout directly** —
   not once, not for a one-line fix.
2. **Run every verification and test in the scratch copy.** Only there do the
   numbers describe your change rather than whoever else is writing.
3. **Produce the patch.** It is the reviewable artifact and the record of what you
   did.
4. **Report a review, not a diff** — a grouped summary the owner can read in a
   minute: what changed, by area, with risk flagged. A raw diff runs to thousands
   of lines and reading it is not the owner's job.
5. **Wait.** The owner may ask for the full diff, one file, or a rationale.
   **Composing is not delivering, and neither is copying.**
6. **On *write it and provide a commit message*, apply the patch — if and only if
   the checkout is clean.**
7. **The owner stages and commits.** A session never runs `git add`, never
   commits, never pushes, never rewrites history in the checkout.

**Step 5 exists because declining is free and reverting is not.** Before the apply
there is nothing in the checkout to reverse — the owner says no and the change dies
with the scratch copy. After it, backing out is a hand edit per file, because
`git checkout -- <path>` takes whatever else is uncommitted with it.

### Applying is a response, never an initiation

The instruction refers to **a patch already handed over**; *write it*, *apply it*
and *land it* name that artifact. An instruction naming work **not yet composed** —
*do step 1*, *proceed with X*, *go ahead* — is an instruction to compose and ends
at step 5. **`do it` is not the ask**: it names a task as readily as a deliverable.

**Where an instruction could be either, compose and ask.** Composing when an apply
was wanted costs one exchange; applying when a review was wanted writes into the
checkout without consent.

### The four assertions around an apply

**First, assert the checkout is clean, and refuse if it is not.**

```text
git --no-optional-locks status --porcelain    # in the owner's checkout; must be empty
```

**`--no-optional-locks` is not optional.** `git status` refreshes the index as it
reads, which takes `.git/index.lock`; on a mounted connected folder the lock
cannot be cleaned up and what is left behind **blocks the owner's next commit**.
The flag suppresses the index write and nothing else; the answer is the same.
**Use it for every git read of the checkout.** Step 6 is the one place a session
must read git state there at all — elsewhere, use `ls` and `cat`.

**Not empty means another party's uncommitted work is there: refuse, name what you
found, and wait.** **Do not let `git apply --check` decide it.** That compares the
patch against file contents and passes whenever the hunks happen not to collide —
a fact about what the two changes touch, not about whether it is safe to write.
**Between an apply and the owner's commit the checkout is a shared resource with
no lock on it**, and two sets of uncommitted work in the files every session
touches cannot be committed apart.

**Second, verify the apply by comparing trees — not by reading the exit code.**
Where the working copy sits on a mount that refuses `unlink`, `git apply`
downgrades the failure to a warning and **exits 0**. This is not only about
deletions: a file is modified by writing a replacement and unlinking the original,
so the refusal fires on plain modification too, and the difference is recovery — a
modification has a fallback and lands, a deletion has none and the file survives.
**So the warning appears on patches that applied perfectly** and cannot separate
the two cases. Compare the two trees, or every path the patch touched. Not the
exit code, and **not a checksum of the files the patch names**, which sees only
what the patch carries as content.

**Third, after applying, assert the index is still empty.**

```text
git --no-optional-locks diff --cached --name-only    # must be empty
```

An index write leaves the working tree byte-identical, so the tree comparison
cannot see it. `git apply` without `--index` or `--cached` writes the working tree
and never the index, which is why the assertion can pass. **Do not add either flag
to make the apply tidy**: that stages the work, which is step 7's and not a
session's.

**Fourth, the report says which you did** — *handed over*, with the patch path; or
**applied at your direction**, with what was compared to verify it landed whole.
Those are different claims and a reader six weeks out cannot tell them apart
otherwise.

### `git add -N` is not optional and its absence is silent

```text
git add -N .
git diff > "$PATCH_DIR/<revision>-<slug>.patch"
```

`git diff` carries no untracked file, so a patch made without `git add -N` drops
**every file the session created** — new dossiers, new scripts, whole directories —
and `git apply` exits 0 having applied what was left. Measured once at **9 of 14
paths**, the five dropped being a test suite, the prompts, a dossier and a guard.

**Read the patch's file list against your own change set before handing it over.**
Nothing else catches a dropped file. The same trap reaches any file a patch
renames: an **empty** file emits no hunks, so `diff` reports it as present on one
side only, which is not patch content, and the patch applies having done half the
work.

### The patch goes stale between step 5 and step 6

Other sessions commit while the owner reviews, so **a patch composed against one
commit and applied to another is the ordinary case**, and `git apply --check`
passing says nothing about it. **Step 6 therefore begins by comparing the base**;
if HEAD has moved, rebase before applying, and rebase in the scratch copy.

```text
git --no-optional-locks log --oneline -1    # in the checkout: the base to rebase onto
cp -a <checkout> <fresh scratch copy>        # a new copy at that commit
git apply -3 <patch>                         # three-way, in the new copy
```

**Resolve every conflict to the checkout's content and re-make this session's
edits on top. Never merge the two** — a conflict here is two records of different
things sharing a table, so combining them line by line is the one wrong outcome.
**Recompute every count from the data**: arithmetic on two figures neither of
which is current is how a total goes wrong in both directions at once.

**Then take the revision number again** ([§4](#4-numbering)) against the tree being
applied to, and **correct every place the composed number appears** — the manifest
entry, the `Revision` cell of any resolution row, any prose naming it. **Re-measure
every figure the entry quotes against the new base**: a number carried over is a
claim about a commit nobody is applying to. **The rebase is routine, not an
incident**, and the conflicts are always the three files named in
[§7](#7-concurrency).

[&#8593; Contents](#contents)

---

## 1. Reading before working

**Read, in order: the vocabulary; this file; the index of the record you are
working in and the session index; then the dossier itself, not a summary of it.**

**Where a reading belongs is one question: would this still exist in a project that
did something else entirely?** If yes it is about the framework — who may read a
member, when a dossier may be written to, what a status means, what a check must
catch — and belongs to the framework's record; if no it belongs to the project.
**A defect in the rule saying when a session may edit a project's script is a
framework reading**, because that rule is the same wherever this structure is used.

**Write findings rather than widening the task.** Finding a second defect while
fixing the first is normal; fixing both in one change is how a small edit becomes
unreviewable. Park it and say so.

**One file per item, named for the thing rather than the date** — a dated filename
sorts by when someone noticed, which is never the question being asked. **A
dossier is the exception and says why**: it accumulates documents as it is worked
and they are only legible together.

**A fact has one home.** Write a count, a membership or a description of what
something holds **once**, and point at it. A copy is permitted **only** where it is
generated or where a check fails when it drifts; an unchecked hand-typed copy is
the defect, not the display. The map of `docs/` owns the list of its directories,
and this file does not enumerate them.

**Completeness is not conformance.** A check answers whether a document is well
formed; **none answers whether it is complete**, and neither does opening the
rendered page, because a rendering cannot show content that is not there. **A file
that has lost half of itself keeps a valid header, a well-shaped table and a clean
render, and passes everything.** So when you generate or rebuild a document,
**verify its content against its source** — every line of the input accounted for,
every section that should exist existing. **Never redirect into a file you are
reading from**: write to a temporary file and move it into place.

**Know what each check does not examine, and do not quote it as though it does.** A
check that resolves links says nothing about the shape of the table they sit in; one
that verifies displayed counts need not cover a total written as a sentence beneath
it. *The checks are clean* is a claim about the properties they examine and nothing
else. The roster is [verifications.md](verifications.md).

[&#8593; Contents](#contents)

---

## 2. The four write categories, and when each is allowed

**What the four categories are is
[vocabulary.md § 10](vocabulary.md#10-write-categories); when each is allowed is
here.** The split is deliberate — both halves once lived in one file, and it
disagreed with itself.

| Category | Gate |
|---|---|
| **record** | **never gated** |
| **toolkit** | **a `decided` member**, which names what changes and why |
| **evidence** | **granted by the owner, per run** |
| **`foreign`** | ungated, unrecorded, takes no revision |

**A record write is never gated**, and could not be: a decision *is* a record write,
so a rule requiring a decision before a record write could never be satisfied from a
standing start. **A toolkit write is gated on a `decided` member** — without one
there is no record of what the change was for, which is the state every archaeology
runs into. **An evidence write is granted by the owner, per run**: anything run
against the artifact volume is read-only unless the owner has said otherwise **for
that run**, and a bad evidence write may be unrecoverable. **A `foreign` write is
ordinary, happens when the owner asks, and is not recorded** — named so the case is
excluded deliberately rather than by omission, since an unnamed case reads as *not
covered* and behaves as *not thought about*.

**Connection is availability; scope is subject.** A session may have several
folders connected and may legitimately work in more than one: the artifact volume
is not a connected folder and is squarely in scope, while a folder can be connected
for one lookup and be nobody's business. **The session's `prompt.md` states the
subject, and that is what to measure against** — no manifest entry, no member, no
resource row for a folder that is not this record's subject or its evidence. And
**a rule the framework depends on is not left in a file outside it.**

### Who may write to a dossier

**Permission is carried by the member, not the dossier**; the dossier's standing
is only what another session checks first, to know whether opening it is worth
anything. The per-status table is
[vocabulary.md § 11](vocabulary.md#11-what-another-session-may-do). Four
consequences are procedural:

- **Deciding is not the owner's privilege; closing the deciding is.** While a member
  is `framing`, **any** session may write a decision on it, reject one, or refine
  one — a row in the decisions table with its section, or an existing row's outcome
  changed with the reason. From `decided` onward only the owner records. A reading is
  not diminished by a second reader, and one who disagrees with a decision improves
  it more. **A non-owner's decision goes in the dossier's Contributions table**,
  like any other contribution.
- **Recording a dossier and owning one are different acts.** A session may record a
  dossier it will never own and leave it `unclaimed` or hand it to someone else.
  **Contribution does not create ownership and never has**; the owner assigns it,
  and **assignment is what starts things** — an `unclaimed` dossier sits outside
  every session until assigned, and assigning it makes the receiver `active`.

[&#8593; Contents](#contents)

---

## 3. Where a write is composed

**One rule, and it covers record, toolkit and evidence alike: compose in a copy of
the repository outside the owner's checkout.** Two sessions editing one working
tree produce a diff neither can be committed out of, and validator numbers that
belong to whoever else was writing.

- **Validate in the copy.** Every checker self-locates and none invokes git, so they
  run in a copy unchanged — and only there do the numbers describe your change.
- **Run `git apply --check` before applying, and say so.** It is not a verdict: it
  passes on a patch that will under-apply, and it does not decide whether the
  checkout is clean. **Verify by comparing trees** — exit code and warning both lie
  on a mount that refuses `unlink` ([§0](#0-the-working-cycle)).
- **Ask for delete permission before applying, not after it fails.** A connected
  folder refuses `unlink` until the owner grants deletion for it. **The grant is
  per folder, for the session, and does not survive a bridge reconnect.** Where it
  is declined or unanswered, move the file into a `_to_delete/` subfolder under
  the same connected folder and tell the owner.
- **Staging inside your own copy to get a baseline to diff against is not a write to
  the owner's repository.** Staging in the owner's checkout is.
- **A copy in session-local storage dies with the session.** Hand over at natural
  stopping points, and **say plainly when work exists only there.**

[&#8593; Contents](#contents)

---

## 4. Numbering

**Two numbers are taken, and both are taken immediately before writing — never
while composing.** A number chosen while composing is a guess: another session may
take the one you saw, and an entry written but not yet committed is invisible to
whoever reads the header next.

**Dossier numbers are one sequence across every record tree**, so a number names a
dossier without needing its tree. **Four digits, zero-padded, never reused, never
renumbered** — a renumber breaks every prompt written against the old number, and
reuse makes retaining a superseded reading impossible, since two siblings cannot
carry one number.

```text
ls -d docs/*-findings/[0-9]*/ docs/*-findings/*/[0-9]*/ 2>/dev/null
```

**A revision number is taken at apply time, against the tree being applied to.**

```text
./bin/verify-session-findings.sh manifest-revision
```

The helper scans the entry headings as well as the header, so it sees what the
header misses; and at apply time only one session is writing. **On a rebase, take
it again** and correct every place the composed number appears
([§0](#0-the-working-cycle)).

### Names, and what is never renamed

- **A status is a value inside a record, never a suffix on a directory name.** The
  directory name is what prompts, indexes and other dossiers cite by path;
  renaming it on every transition breaks all of those citations at once.
- **A dossier's directory is never renamed and its number never reused**, even
  when it is superseded.
- **A session's directory is `<title>-<stamp>`** — a short readable scope and
  `YYYYMMDD-HHMMSS` in **America/New_York**. It carries no dossier number, since a
  session routinely owns several, and it is fixed at creation.
- **The zone is named rather than left as *local*, because a session almost never
  runs in it.** An assistant working in UTC that reads *local* as its own produces a
  stamp hours ahead of a dossier created before it, and the sequence the stamp exists
  to carry stops holding. The same zone governs every recorded date. **A stamp or
  date already written is evidence and is never restamped to match this rule.**
- **Neither directory name carries the other's identifier**, so neither has to be
  renamed when the relationship changes.

[&#8593; Contents](#contents)

---

## 5. The revision manifest, and the commit message

**Every change of any kind takes a revision — a record write as much as a toolkit
one.** A revision covers a **change, not a file**: three notes parked in one
sitting are one entry, the same way a revision editing nine documents is one.

**Entries are never retro-edited.** A revert is a **new entry** naming what was
reverted and the commit it reverted, never an edit to the entry being undone.

### The commit message, when the owner asks for one

**Keep it short**: a subject line under about 70 characters, then one or two short
paragraphs saying what changed and why. **The manifest entry is where the reasoning
lives**; the message names the revision and points at it rather than restating it.
If the first draft runs long, cut it before offering it — the owner should not have
to ask twice.

**The block you hand over is the message and nothing else.** No `git commit`, no
`-m`, no quoting wrapper, no shell around it: the owner commits with a plain
`git commit` and pastes into the editor, so a command in the block is something they
must delete before using it.

**It is one fenced `text` block.** A message set as prose, or split across paragraphs
with commentary between them, has to be reassembled by hand before it can be pasted —
**which costs the owner exactly what a `git commit` inside the block costs them, from
the other direction.** One is something to delete, the other something to gather, and
the rule above is half a rule without this one.

**Anything the owner might need to *run* goes in the conversation beside the block,
not inside it** — a command, a flag, a reminder about staging. **End with the
trailers.**

[&#8593; Contents](#contents)

---

## 5a. The shapes a write must land in

**The record's prose documents have fixed shapes.** The `metadata.json` fields are
[schema.md](schema.md); what follows is what lives in the markdown, stated as
obligations rather than as a template.

### The reading document

- **The header block is a schema, not a suggestion, and no other field appears in
  it.** Required: the date recorded, the session, the severity. Optional: where it is
  felt, the scope, what was read, what it relates to. **The schema fixes the
  vocabulary, not the content** — requiring an optional field would mean inventing a
  value for the readings that never had one.
- **Each field occupies exactly one source line, and every line but the last ends
  with two trailing spaces.** Markdown joins consecutive lines into one paragraph,
  so a header without the hard breaks renders as a run-on sentence with the field
  names buried in it. **A long value stays on its one line; wrapping it is what
  breaks the block.**
- **Expect a trailing-whitespace warning and do not act on it.** `git apply` warns
  on every conformant header it carries, and an editor set to strip it on save
  breaks the rendering the rule protects. **The warning is the schema being
  obeyed.**
- **The session is its own field and is never packed into another field's value.**
  Where none was ever recorded it holds `—`: that is a gap in the record and the dash
  says so, where **inventing a session to fill the field would not.** **The recorded
  date is the date the reading was written down**, not the date the defect began.
- **Where it is felt and where the fix lands are different questions** — a defect in
  shared machinery felt in one runbook needs both. What it relates to is optional and
  repeatable, one line each ([vocabulary.md § 12](vocabulary.md#12-relates-to)). What
  was read is the one field whose value is a bulleted list beneath it; the two-space
  rule governs the fields around it, not its bullets.
- **Contributions lists every session other than the owner** that added a member,
  corrected one, or contributed to a decision. **Omit the table when there are
  none** — an empty table is noise. **Ownership is not a contribution** and does
  not appear there.
- **Two field names are retired and must not come back**: an owner field, whose
  values were *unassigned* and file paths rather than sessions, and a status field,
  which meant a lifecycle status in some dossiers and *closed by revision N* in
  others. Both duplicated facts the index row owns, and both misled.
- **The members table is required, including when the dossier holds one member** —
  a missing table read as *one member* and agreed with every index that counted it.
  Members are cited by prefixed id, never a bare digit, so a citation means one
  thing; then one free-form section per member, its heading matching the row.
- **Anything else — a gate, a note, an owner's direction — goes in prose below the
  header, not as an invented field.** Fields appearing in one dossier and nowhere
  else are how a schema stops being one.

### The decisions document

- **There is no status field here.** It was a third copy of the dossier's standing
  and it went stale. The index row owns the standing, and a document that restates it
  is a document that will contradict it.
- **A decision always cites the members it answers. There is no `—`.** Where a
  citation is genuinely not derivable it is **a reading, not a formatting gap**,
  taken by a session that may open that dossier.
- **A rejected or refined decision keeps its row and its section.** That is the
  record of what was considered, and deleting it leaves an assertion — exactly
  what the record exists to prevent.
- **No outcome value is ever also a status value**; the outcomes are
  [vocabulary.md § 7](vocabulary.md#7-decision-outcomes).

### The resolutions document

- **A resolution names the decision it was resolved by, not the revision**; the
  revision and the commit are **separate fields**, because one can exist without the
  other. **The member column holds the id alone**, not the id and the sentence — the
  sentence has one home, which is the members table.
- **A resolutions document is not required.** A dossier that has correctly resolved
  nothing has no such file, for the same reason a dossier that has decided nothing has
  no decisions document.
- **A dossier migrated from an already-closed record carries a resolutions document
  and no decisions document**, because the deciding happened before this lifecycle
  existed, and its resolutions say so. **Writing a decisions document into one would
  invent deliberation that never happened** — the evidence rule broken in the
  direction of tidiness.

### Across the three, and everywhere

- **The three documents must agree, in both directions.** Every member cited by a
  decision or a resolution exists in the reading, and every decision a resolution
  resolves by exists in the decisions document. **A citation that resolves to
  nothing is how a table stops being a record and becomes decoration.**
- **The index row is authoritative for the dossier's standing** and the record must
  agree with it; a row that disagrees is a bug in whoever moved it last.
- **Fence every example as `text`, never as `markdown`.** A `markdown`-tagged fence
  is read by some renderers as *render this*: the example is interpreted rather
  than shown, hard breaks are joined back into paragraphs, and the specification
  displays as the defect it exists to prevent. **`text` is inert everywhere.**
- **The narrative documents have no schema** — a prompt, a handoff, a final summary;
  a rigid one produces empty headings. **A required minimum only:** a prompt names
  its reading order and its task, a handoff names what transfers, what is known
  broken and what is owed, a final summary names every dossier the session owned and
  that dossier's disposal, by name.
- **Reformatting is not a change.** Renaming a field, reordering the header, moving
  an off-schema field into prose, adding a table built from what is already there —
  none is an edit to the reading, and none needs a reopen, even on a `resolved` or
  `superseded` dossier. **What is frozen is the content.** A revision that reformats
  says so, and says nothing beneath the schema was touched.

[&#8593; Contents](#contents)

---

## 6. The owner's override

**The owner may override any rule here, at their discretion.**

**A session may not invoke this on its own behalf and may not infer it.** It acts
on an override only when the owner gives one.

The case it exists for is the one that has already occurred: a change the owner
has already decided, with no member behind it and nothing to discuss, which the
lifecycle would delay without adding anything. **Routing a settled decision
through a dossier, a reading and a decisions document produces paperwork, not
judgement.**

**A revision carrying an overridden change says so, and says what was
overridden.** That is the whole discipline. **The override is not a loophole
because it is never silent**: a reader can always tell a change that followed from
a member from one the owner simply directed. **An override that goes unrecorded is
indistinguishable from a rule nobody agreed to.**

[&#8593; Contents](#contents)

---

## 7. Concurrency

**Several sessions run against one checkout, and the checkout has no lock.**
Between an apply and the owner's commit it is a shared resource — which is why
[§0](#0-the-working-cycle) refuses an apply into a dirty tree and why
[§4](#4-numbering) forbids taking a number early.

**What collides is not content.** Two sessions adding different rows to one table
do not conflict as text, so `git apply --check` passes and the merge is still
wrong.

| What collides | Why | What to do |
|---|---|---|
| **the revision manifest** | every change takes a revision, so every session writes it | take the number at apply time; on a rebase take it again and correct every place it appears |
| **the session index** | counts and standing cells move on every transition | recompute from the data; never carry a figure across |
| **the record index** | every new or moved dossier adds or edits a row | resolve to the checkout's content, then re-make this session's row on top |
| **a dossier number** | another session may take the one you saw | take it immediately before writing, never while composing |
| **an uncommitted manifest entry** | it is not in the header the next session reads | use the helper, which scans the entry headings too |
| **delete permission** | per folder, for the session, and dies on a bridge reconnect | ask before applying; on refusal use `_to_delete/` and tell the owner |

**The first three are the files every session must write, and the three that
conflict every time.** Resolving them is routine: take the checkout's content,
re-make this session's edits on top, **never merge the two**, recompute every count
from the data. **A dossier is worked concurrently by design** — any session may
sharpen or decide on a `framing` member; what is never allowed is two sessions
writing one working tree ([§3](#3-where-a-write-is-composed)).

[&#8593; Contents](#contents)

---

## 8. What a session owes at each transition

**The steps of every transition are
[lifecycles.md § 5](lifecycles.md#5-the-procedures).** This section states only
what is *owed* — the obligations and prohibitions that decide whether a transition
may happen at all.

**Opening a member.** **Only the owning session opens a member.** Writing a
dossier up in the first place is not a reading: a session may record a dossier it
will never own.

**Resolving.** The toolkit write comes first and is **gated on the member being
`decided`** ([§2](#2-the-four-write-categories-and-when-each-is-allowed)); the
resolution row's revision is taken at apply time like any other. **The row is the
evidence the status asserts, so it is written before the status moves.** **A
`decided` member whose decisions were carried out and which has no row is a
defect** — not fully derivable, since whether a toolkit write happened is a fact
about the tree rather than the record, but the failure worth catching is **zero**,
the same shape as the coverage gate below.

### Superseding — owed: a complete accounting before the tag, and nothing else touched

- **It reaches a dossier at any standing** — there is no state in which a reading
  cannot be replaced, a settled dossier whose owning session has ended included.
  **Never a single member**: correcting one resolution is a reopen. **The session
  with the new reading performs it and does not take ownership** — superseding is not
  inheriting.
- **The predecessor's reading is not edited** — not to add a pointer to its
  replacement, not to repair a citation inside it, not to soften a conclusion. **A
  reading is retained by being left alone, and one that shows a diff was not
  retained.**
- **The number is never reused and the directory never renamed**
  ([§4](#4-numbering)).
- **The dossier does not move between manifests.** It stays listed by the session
  that held it with only its standing changed: that file is authoritative for who
  held a reading, and a supersession changes neither who recorded it nor who held
  it. **The originating session's dossier count does not change.**
- **Coverage and exclusivity gate the tag, not the follow-up.** Every predecessor
  member is named by **at least one** disposition edge — *at least*, not *exactly*,
  because a split gives one predecessor member several edges and a merge gives one
  successor several sources, and both are ordinary. A member disposed `dropped`
  carries that edge and no other. **Do not set the predecessor's lineage until both
  pass**: a tag over an incomplete accounting is the state nothing can recover
  from, because the predecessor may not then be edited to fix it. The gates are
  [lifecycles.md § 6](lifecycles.md#6-provenance-and-the-two-gates).
- **Where the originating session is `closed`, its final summary is never edited.**
  The index row and the new dossier's pointer are the record; if its manifest lists the
  dossier, only the standing cell changes.
- **Choose `superseded` where another dossier carries the reading forward and
  `withdrawn` where the reading is dropped and nothing replaces it.** If a
  replacement is being opened, it is `superseded`.

### Reopening — owed: a reason from the closed set, and the SHA that makes it checkable

- **Prose is not a reason.** The reason is one of the nine and **it determines the
  exit** ([vocabulary.md § 9](vocabulary.md#9-reasons)); it is not decoration.
- **The reopen document is generated from those fields against that SHA.** Do not
  hand-write it and do not copy the member, decision or resolution into it. **A
  snapshot is a second copy of a fact and will drift; a SHA cannot.**
- **A `reopened` member persists until the record materially changes.** Reading it
  is not a change, and neither is an assignment, a sweep, a rename or a retrofit —
  [lifecycles.md § 1](lifecycles.md#1-what-moves-a-value-and-what-does-not).

### Withdrawing — owed: a reason, an optional note and a timestamp, per member

Withdrawing a whole dossier requires one for **every** member in it, which keeps
the dossier's `retired` derived rather than declared and makes withdrawing cost
exactly as much thought as the members in it.

**A `resolved` member is reopened first.** Withdrawal reaches every status except
`resolved`, which is frozen. Stating it is what stops someone trying it and reading
the refusal as a bug.

### Transferring — owed: an existing target, and a record on both sides

- **The target session must already exist** — created, cloned or long-running. A
  handoff creates its destination; a transfer names one.
- **Only the live standings may be transferred**: the terminal ones have nothing to
  move, and `unclaimed` has no owner to move it from, so assign it instead. **Two
  documents give the permitted set in two vocabularies and have not been reconciled**
  — [lifecycles.md § 5.5](lifecycles.md#55-transferring--10).
- **The transfer ends on the target's first write to the dossier as owner.** *As
  owner* is load-bearing: **a contribution is a write and does not clear the
  transfer.** Nothing else about the reading changes — no member is reverted, no
  decision re-opened.
- **Both sessions record it**, because the ownership record is authoritative for who
  held what and when. **Transferring part of a dossier is not supported**: the need is
  real and has arisen more than once, but until an option is chosen a dossier moves
  whole or not at all.

### Releasing — owed: the disposal record

- **Choose between transfer and release by whether a taker exists.** A transfer
  names a target and the dossier stays owned; a release names none and the dossier
  is closed to everyone until the owner assigns it.
- **Recording the disposal in the session is not optional** — the final summary on
  closing, the handoff document otherwise, naming each dossier and why. **A released
  dossier leaves no trace in the session that held it**: the manifest row is gone and
  the index row names nobody, so without the disposal record the reading's history
  stops at the moment of release. Supersession keeps the dossier listed for the same
  reason; release cannot, so this is where the history goes.
- **A session may not end holding a dossier.** Every dossier it owns is terminal or
  released first.

### Closing and handing off

- **The ownership record is authoritative for who and what.** One row per owner:
  the assistant, its identifier and transcript where the tool exposes one, the
  model, **the environment it actually ran in**, and the dates it held the dossier.
  **None is edited once the ownership it records has ended.**
- **Every value in a record is resolved** — not a placeholder, not an
  angle-bracketed name, not a variable, but the absolute path, the real identifier,
  the actual commit. A record is read years later by someone with no other source
  and no way to expand a placeholder, so an unresolved one is indistinguishable from
  a fact nobody recorded. **A placeholder belongs in a schema or a template, never
  in a record.**
- **The environment field is not decoration**: a claim validated in one environment
  is a different claim from the same one validated in the target's. **Any *not
  recoverable* names the searches that came back empty** — identifiers so recorded
  have since been found in a commit trailer, so a session looking for what it wrote
  finds nothing and concludes wrongly if the searches are not on the record.
- **Every prompt names this file as required reading, before anything else it asks
  the session to read** — regardless of state, scope or assistant. A session that
  begins without being told where the rules are is the one failure the reading order
  exists to prevent. **It binds prompts written from now**; a closed session's prompt
  records what that session was told, and **editing it is what supersession spends
  three prohibitions preventing.**
- **How a session begins and exactly what transfers at a handoff is
  [lifecycles.md § 4](lifecycles.md#4-the-session-lifecycle).** A session that hands
  off declares it; every other state follows from what it owns. **Terminal shutdown
  is `dissolved`.**

[&#8593; Contents](#contents)

---

## Provenance

**One row per rule: what decided it, and nothing about how it got there.** Where a
row names a revision rather than a dossier, the ruling was made in the manifest and
no dossier owns it.

| § | Rule | Decided by |
|---|---|---|
| 0 | Composing is not delivering; step 5 exists because declining is free | `0038` F4 |
| 0 | Applying is a response, never an initiation; `do it` is not the ask | `0049` F6, D7 |
| 0 | `--no-optional-locks` on every git read of the checkout | `0038` F1 |
| 0 | Assert the checkout clean; `git apply --check` does not decide it | `0038` F1, F4 · `0049` F6, D8 |
| 0 | Assert the index still empty after applying | `0049` F5, D6 |
| 0 | Steps 1 and 2 are absolute — seven revisions skipped 3 to 5 | `0049` |
| 0, 7 | The three files that collide on every rebase | `0038` F1 |
| 0, 3 | `git add -N` is not optional and its absence is silent | Revision 231 |
| 1 | A rule the framework depends on lives in the record it governs | `0039` D19, F19, F9 |
| 2 | Meaning belongs to the vocabulary; gating belongs here | `0039` D2, D13 |
| 2 | Deciding is not the owner's privilege; closing it is | `docs/legend.md` — *Who may write to a findings bundle* |
| 4 | A status is a value in a record, not a suffix on a directory | Revision 222 |
| 4 | A member status, a dossier standing and a session state share no value | Revision 233 |
| 5 | The commit-message block is one fenced `text` block, message only | `0039` F23, D21 |
| 5a | A migrated dossier carries resolutions and no decisions | `0037` D2, answering `0047` F4 |
| 5a | A decision always cites its members; the `—` exemption is retired | D15 · Revisions 219, 230 |
| 5a | No status field in the decisions document | Revision 202 |
| **6** | **The owner may override any rule, and the revision carrying it says so** | `docs/legend.md` — *The owner's override* |
| 8 | Resolving has numbered steps, and the row precedes the status | `0037` F5 · `0039` F17, D18 |
| 8 | Every prompt names the rules first; closed prompts are not rewritten | `0037` D1 |
| 8 | A transfer ends on the first write as owner, not on a read | `0039` D24 · Revisions 248, 262, 268, 273 |
| 8 | A session may not end holding a dossier | `0039` F20, D20 · Revision 200 |
| 8 | Session terminal shutdown is `dissolved`, not `withdrawn` | Revision 273 |
| — | Two cells of the readability table disagree and are left alone | `0039` F21 |
| — | There is no row for `transferred` in the readability table | `0039` F25 |

[&#8593; Contents](#contents)
