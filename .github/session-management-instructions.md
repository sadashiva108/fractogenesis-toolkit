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

    ls -d docs/*-findings/[0-9]*/ docs/*-findings/*/[0-9]*/ 2>/dev/null

`docs/INDEX.md` is the map of `docs/` and owns the list of its directories. This
file does not enumerate them.

## 3. A findings bundle

A numbered directory, because a finding accumulates documents as it is worked and
they are only legible together:

    <NNNN>-<slug>/
    |-- STATUS-<status>  the tag. One file, no contents. `ls` answers the status
    |                    without opening anything. It must agree with the INDEX.md
    |                    row, which is authoritative. Spaces become hyphens.
    |-- findings.md      the reading, and the per-finding status table
    |-- decisions.md     what was decided for each finding, and the alternatives
    |                    rejected. A decision without its rejected alternatives is
    |                    an assertion.
    `-- resolutions.md   what was actually done, with the commit hash and the
                         APPLY-MANIFEST.md revision carrying each one.

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
- **`framing` is open to every session** to read and record. A reading is not
  diminished by a second reader.
- **`decided` is read-only to everyone but the owner.**
- **`resolved` is frozen.** `reopened` is the only door, and going through it is
  a declared act.
- **`unclaimed` is closed to everyone.** It is parked until the owner assigns it.

## 5. Sessions

    docs/sessions/<title>-<stamp>/
    |-- STATE-<state>          the tag, as in 3. Required, always.
    |-- prompt.md              what starts the session. Required, always.
    |-- metadata.md            who and what has owned it. Required from the start.
    |-- findings-manifest.md   the bundles this session owns. Required once it
    |                          owns one. AUTHORITATIVE for ownership.
    |-- handoff-<stamp>.md     one per handover; never edited afterwards.
    `-- final-summary.md       written at `closed` or `withdrawn`.

`<title>` is a short readable scope; `<stamp>` is `YYYYMMDD-HHMMSS` local, the
artifact-root format. The name carries no finding number — a session routinely
owns several — and is fixed at creation.

**`metadata.md` is authoritative for who and what.** One row per owner: the
assistant (`Claude` or `Copilot`), its session identifier and transcript link
where the tool exposes one, the model it was configured for, **the environment it
actually ran in**, and the dates it held the bundle. None is edited once the
ownership it records has ended.

The environment field is not decoration. This repository targets macOS stock Bash
3.2; an AI session almost never runs there, and a claim validated on Linux is a
different claim. **Any `not recoverable` names the searches that came back
empty** — three identifiers so recorded have since been found in the
`Claude-Session` commit trailer, which the harness writes, so a session looking
for what it "wrote" finds nothing and concludes wrongly.

`docs/legend.md` carries how a session begins — created, cloned, or handoff — and
exactly what transfers at a handoff. This file does not restate it.

## 6. Writing

Three kinds of write, defined in `docs/legend.md`: **record** (`docs/`),
**toolkit** (anything else tracked), **evidence** (the artifact volume). What
they mean and when each is allowed is there.

Where a write is composed is a separate rule and applies to all three:

- **Compose in a copy of the repository outside the owner's checkout.** Copy the
  checkout to session-local storage, edit there, run the validators there, then
  `git diff` and hand the owner a patch. Two sessions editing one working tree
  produce a diff neither can be committed out of, and validator numbers that
  belong to whoever else was writing.
- **Validate in the copy.** Every checker self-locates and none invokes git, so
  they run in a copy unchanged — and only there do the numbers describe your
  change.
- **`git apply --check` before applying, and say so.** Note that it passes on a
  patch that will under-apply: `git apply` cannot unlink on a connected folder,
  downgrades that to a warning and **exits 0**, so any patch containing a
  deletion lands incomplete. Verify by comparing the two trees, not the exit code
  and not a checksum of the files the patch names.
- **The owner asks before a patch is applied.** Composing is not delivering.
  Report what you composed, show it, and wait.
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

    ./bin/check-manifest-revision.sh

run against the tree being applied to. **Choosing while composing is a guess**,
and two sessions can follow *re-read the header and take the next free number*
exactly and still collide — because an entry that is written but not yet
committed is not in the header the other session reads. The helper scans the
entry headings as well as the header, so it sees what the header misses, and at
apply time only one session is writing.

Entries are never retro-edited. A revert is a new entry naming what was reverted
and the commit it reverted, never an edit to the entry being undone.

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

## 9. Superseding a bundle

**A bundle is replaced whole by a later one. It reaches a bundle at ANY status**
— there is no state in which a reading cannot be replaced. An earlier rule tied
it to a bundle being overtaken mid-work, which left the commonest case unhandled:
a settled bundle whose owning session has ended, with nobody able to perform the
supersession at all.

Never a single finding: correcting one resolution is `reopened`.

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
2.  Create `<NNNN>-<slug>/` with its tag, `findings.md` carrying the reading
    forward, and `decisions.md`. **Cloning the original is the usual way and is
    not required**; a replacement may start from work already begun. What matters
    is that it carries the reading and names what it replaces.
3.  The new `findings.md` header carries `Relates to`, naming what it replaces:

        **Relates to:** `<NNNN>-<slug>` -- **supersedes it.**

4.  Rename the old bundle's tag to `STATUS-superseded`.
5.  In the old bundle's INDEX.md row, THE STATUS CELL BECOMES THE LINK —
    `[`superseded`](<new-bundle>/)` — **always a link, never the bare word** — so one cell answers both what state the
    bundle is in and what replaced it. Notes records that the reading is retained.
6.  Add the new bundle's row, naming the superseding session, or `—` where the
    replacement is not yet owned.
7.  Add it to that session's `findings-manifest.md` and update its counts in
    `docs/sessions/INDEX.md`. **The originating session's bundle count does not
    change** — the superseded bundle is still listed there.
8.  `decisions.md` re-affirms or explicitly drops every decision the superseded
    bundle recorded — decisions do not carry forward by themselves. Where it has
    no `decisions.md` but states a conclusion in prose, name that as the thing
    being superseded rather than departing from it silently.
9.  One `APPLY-MANIFEST.md` revision covers the whole supersession.

Where the originating session is `closed`, its `final-summary.md` is never
edited; the index row and the new bundle's `Relates to` are the record. If its
manifest lists the bundle, only the status cell changes.

`superseded` where another bundle carries the reading forward; `withdrawn` where
the reading is dropped and nothing replaces it. If a replacement is being opened,
it is `superseded`.
