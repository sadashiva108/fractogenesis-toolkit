# Session prompt — session management

**Last updated:** 2026-09-08 20:47 EST  
**Current as of:** `APPLY-MANIFEST.md` Revision 238

If the repository is past that revision, this file may have fallen behind — say so
rather than following it where it disagrees with `docs/legend.md` or the
instruction sets.

Paste **after** `conformant-prompt.md`. That one says how any session works; this
one says what *this* session is for.

---

## Table of Contents

- [[#Your subject|Your subject]]
- [[#What is waiting for you|What is waiting for you]]
- [[#Read, in this order|Read, in this order]]
- [[#The owner's brief|The owner's brief]]
- [[#Report before you change anything|Report before you change anything]]
- [[#What is already known to be wrong|What is already known to be wrong]]
- [[#What is settled and should not be re-litigated without cause|What is settled and should not be re-litigated without cause]]
- [[#What you own, and what you must not touch|What you own, and what you must not touch]]
- [[#What this session owes when it ends|What this session owes when it ends]]

---

## Your subject

**How sessions and findings bundles themselves work** — the statuses, the states,
the rules binding them, the instruction set that carries those rules, and the
checks that hold them. Not the project's own subject; that belongs to sessions
working from `.github/toolkit-instructions.md`.

Your findings tree is `docs/session-management-findings/`. Nothing that is not
strictly about session management goes in it, and the test is one question:
**would this finding still exist in a project that did something else entirely?**

## What is waiting for you

**This file does not say which bundles are yours.** It cannot: more than one
session-management session runs at a time, each with a different charge, and a
shared prompt that named bundles would hand the same work to both. It listed
seven `unclaimed` bundles until Revision 238, by which time two of them belonged
to one session and three to another.

**Your bundles are in your own session bundle**, in two files that are
authoritative where this one is not:

| | |
|---|---|
| `docs/sessions/<yours>/findings-manifest.md` | what you own, and its standing |
| `docs/sessions/<yours>/prompt.md` | your charge, your reading order, what is not yours |

**Read the originals behind whatever you are given.** Each session-management
bundle supersedes one with the same number minus ten, which stays where it was,
still listed by the session that held it, `superseded`. The originals carry the
reasoning, and where the superseded reading was fully resolved, those resolutions
are the thing in question.

**Their readings are unchanged; their files are not.** Revision 203 brought them
onto the header schema after they had been held back from three revisions of
reformatting on a rule that turned out to be wrong in its reach — `0041` states
the defect it rests on in its own findings table, so the evidence never depended
on the original staying misshapen. Reformatting is not an edit to the reading.
Editing what one of them *says* still is, and still needs `reopened`.

## Read, in this order

1. `docs/legend.md` again, closely — you are about to re-evaluate it
2. `.github/session-management-instructions.md` end to end
3. `docs/architecture/findings-and-sessions.md` — why the shape is what it is,
   and its section 12, which is a list of open questions nobody has answered
4. `docs/architecture/transferring-part-of-a-bundle.md` — three options, none chosen
5. The bundles your `findings-manifest.md` lists, in the order your
   `prompt.md` gives
6. `docs/sessions/session-responsibilities.md` — **a dated record, not rules.**
   It opens with a table of what has superseded each of its claims

## The owner's brief

The architecture carries inconsistencies and contradictions, **including among
the resolved bundles**. Re-evaluate from the ground up. The vocabulary was
rebuilt in Revisions 198–203 and is current; what has not been re-read is whether
the decisions underneath it still hold.

## Report before you change anything

The owner reads findings before edits. For each bundle, in the conversation:

- **One paragraph**: what it says, its status, and what resolving it would take —
  described, not decided.
- **Where it touches the others.** Several of these were filed apart while being
  the same subject, which is why they are now in one tree.
- **Anything in it the tree no longer matches.** These readings are from
  2026-09-01 onward and the vocabulary changed under them in Revisions 198–201.
  A reading that describes `in progress` or `resolving` is describing a status
  that no longer exists — say so rather than translating silently.
- **What you would need from the owner** before any of it could be worked.

## What is already known to be wrong

Not a survey. These came up in the course of other work and were recorded rather
than fixed — expect more.

- **`verify-doc-paths.sh`'s OK total cannot be a baseline.** With `--all` it
  reaches `docs/` — 778 paths, 1108 anchors — and that figure moves whenever
  anyone parks a note. Without the flag it covers the `.github` surface only: 98
  paths and no anchors at all, on an exclusion whose stated reason —
  *"gitignored working notes … they never reach a fresh clone"* — has been false
  since Revision 162. That is `0036`. Quote `MISSING` and `ANCHOR BROKEN`, never
  `OK`.
- **No check reads the rendered page.** Every checker in `bin/` reads the source,
  and Revisions 201, 202 and 203 each shipped a defect visible only once the page
  was rendered — each found by the owner opening the file, none by a session.
  **This is `0042`**, recorded in Revision 204. Its F3 is the live question:
  a rendering check needs a CommonMark parser, which is a dependency this
  repository does not have, and four options are set out with none costed. The
  decision is the owner's. Read F4 before proposing one — the audit that did find
  these reported 131 failures on its first run, of which **128 were bugs in the
  audit**.
- **No check compares a bundle's derived status against its own finding rows.**
  Revision 197 found four `resolved` bundles whose rows had never moved. Two were
  corrected in Revision 200; the check still does not exist.
- **The rollup in `docs/runbook-findings/INDEX.md` has 27 unchecked derived
  figures** — nine runbooks × bundles, findings, resolved. Added in Revision 190,
  reconciled by hand, and `verify-findings-counts.sh` still has no rule for them.
  **This is an unpaid debt from the session that wrote it.**
- **`0039` finding 8 is undecided** — the composition rule says *where* a change
  is composed and never said *when* it is handed over. It is the reason `0039`
  never closed.
- **`0041` finding 3 and `0039` D3 disagree** on how a bundle is classified:
  *classify by subject* against §4c's *where the fix lands*.
- **`transferred` and the per-finding case.** Bundle-level transfer is
  implemented; transferring part of a bundle is not, and the options are in
  `docs/architecture/transferring-part-of-a-bundle.md`. It ends on the question
  that decides it: **is a bundle a unit of ownership, or a unit of reading?**

## What is settled and should not be re-litigated without cause

Recorded so you know what is load-bearing rather than accidental.

- **Status is carried by the finding; the bundle derives it** by an ordered
  ladder. That inversion is what removed the hand-maintained statuses.
- **Three statuses mean *nobody has looked yet*** and behave identically:
  `un-started`, `reopened`, `transferred`. Reading is the transition.
- **`resolved` is frozen and `reopened` is the only door** — revising settled
  work is a declared act, not a quiet correction.
- **Reformatting is not a change**, and does not need `reopened`. Bringing a file
  onto the header schema — renaming a field, reordering, moving an off-schema
  field into prose, building a table from what is already there — is not an edit
  to the reading. What is frozen is the content.
- **The header schema**, section 11: `Recorded`, `Session` and `Severity`
  required, `Felt at`, `Scope`, `Read` and `Relates to` optional, **no other
  field in the header**. `Session` is never packed into another field's value.
  Findings are `F1`, `F2`; decisions are `D1`, `D2` and cite the findings they
  answer; resolutions point at the decision, with `Revision` and `Commit` as
  separate fields. **Neither `decisions.md` nor `resolutions.md` carries a
  `Status:` field** — the tag and the index row own the status.
- **A field and its value own a rendered line.** One field per source line, two
  trailing spaces on every line but the last, examples fenced with ` ``` ` and
  tagged `text` rather than `markdown`. This is the rule three consecutive
  revisions broke, each in a different way, and each time it was the owner
  opening the page that caught it.
- **The session management set and `docs/legend.md` are project-agnostic** and
  measure zero project-specific references. Keep them that way; a template for
  the third file is in `../instructions-templates/`.

## What you own, and what you must not touch

Your tree is `docs/session-management-findings/`. The rules live in
`.github/session-management-instructions.md` and `docs/legend.md`, and those two
are **project-agnostic by design** — they measure zero project-specific
references and a checker is not what holds that, you are. If a change would put
this project's name, paths, revision numbers or finding numbers into either file,
it belongs in `.github/toolkit-instructions.md` instead.

**One file, one owner.** Other sessions are working the project's own trees. The
runbooks, `bin/`, `.internal/` and `.github/toolkit-instructions.md` are theirs;
flag rather than edit. The boundary is the manifests, not the diff — everyone
composes in their own copy, so the owner's checkout is clean even when three
sessions are mid-change.

## What this session owes when it ends

Every bundle it owns, disposed by name in `final-summary.md`. A session may not
end leaving a bundle owned by a session that has stopped — the unfinished ones
become `unclaimed` and go back to the queue, which is what happened to
`phase-11b-hydrate-and-bookends`'s five in Revision 200 and to `0001` in
Revision 205.

**`closed` means every bundle it owns is terminal** — `resolved`, `superseded` or
`withdrawn` — **and any that is not has been released to `unclaimed`.** The
legend required them all to be `resolved` until Revision 205, which no session
whose work had been superseded could ever satisfy.

Releasing a bundle is not a way of finishing it. Say in the summary what was
answered and what was never read, and leave any status the owner alone may set —
moving a finding to `decided` is the owner's act — for whoever takes it next.
