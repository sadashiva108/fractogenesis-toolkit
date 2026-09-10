# Directory reference — what lives where, and why

> **Role.** The layout. What is machinery and what is record, where each file
> goes, and what a project keeps when IRIS moves out.
>
> **Authoritative for** the layout. **Not** for what any word means —
> [vocabulary.md](vocabulary.md).
>
> **Status: the target layout is not the current one.** Section 5 says exactly
> how far apart they are, because a reference that describes an intention as
> though it were a fact is the drift this framework exists to catch.

## Contents

- [1. The principle](#1-the-principle)
- [2. The layout](#2-the-layout)
- [3. What stays with the project](#3-what-stays-with-the-project)
- [4. Two repositories, later](#4-two-repositories-later)
- [5. Where the tree actually is](#5-where-the-tree-actually-is)

---

## 1. The principle

**The machinery is reusable. The record is not.**

A dossier about `backup-repos.md` has to be committed alongside `backup-repos.md`
or it rots — the reading and the thing it reads move together or the citation
dies. So **the record always stays with the project.** What travels is the code
and the manual.

**This is not the same split as framework-versus-project**, and getting that
wrong is the mistake worth naming. Of the 54 dossiers here, **33 are the
project's** — readings of runbooks and the artifact layout — and 21 are about
IRIS itself. Put all 54 under the framework directory and copying it into another
project carries someone else's reimaging findings along.

**The test it makes possible:** copy one directory into a new project, point it at
an empty record, run the checks. Either it works or it does not. Under any layout
that mixes them, the reusability claim cannot be tested at all — which is the
state it was in when this was written.

[&#8593; Contents](#contents)

## 2. The layout

```text
<project>/
├── iris/                       ← MACHINERY AND MANUAL. Liftable, no project data
│   ├── README.md               the door
│   ├── atelier                 the CLI — one entrypoint
│   ├── vocabulary.md           every closed set
│   ├── lifecycles.md           what moves what
│   ├── schema.md               entities and fields
│   ├── shapes.md               the four genera
│   ├── procedure.md            when a write is allowed, and in what order
│   ├── rules.md                the layers, and what wins
│   ├── verifications.md        every check, and what it does NOT examine
│   ├── prism.md                the allocator
│   ├── lumen.md                the interviewer
│   ├── why.md                  the argument
│   ├── directory-reference.md  this file
│   ├── coverage-procedure.md   what the procedure.md rewrite accounted for
│   ├── lib/                    plan_findings_work.py, the checks, the migrations
│   ├── templates/              dossier/ and session/ skeletons
│   ├── prompts/                what a session is given
│   └── tests/
│
├── .iris/config.json           ← the seam. Record root, kinds, pinned version
│
├── record/                     ← THE PROJECT'S MEMORY
│   ├── REVISIONS.md            one entry per change, never retro-edited
│   ├── dossiers/               <NNNN>-<slug>/  FLAT. Every genus, every kind
│   ├── sessions/               <title>-<stamp>/
│   ├── ledgers/                dated statements, re-derived wholesale
│   └── architecture/           the project's blueprints
│
└── …                           the project: its runbooks, bin/, references/, env
```

**`dossiers/` is flat, and that is a decision rather than an omission.** A dossier
carries **two** classifications — `genus` and `kind` — and a filesystem hierarchy
expresses one. Partition by either and you lose the other; nest both and you get
sixteen possible directories, twelve of them empty today. **The data holds both,
so the tree should hold neither**, and every view — by genus, by kind, by
standing, by session, by edge — is generated.

**A classification in a path is a rename when the classification changes**, and
classifications change even when the object does not: `0041` F3 records a dossier
that *may be in the wrong tree* and could not be settled, because settling it
meant a rename. Measured on this tree, **2,446 citations are by number and 440 by
path** — the tree is decoration the path is forced to carry.

**And nothing moves on a status change.** A study — a commission nobody has opened
— sits in `dossiers/` with `progress: pending`, not in a directory of its own,
because a directory a dossier leaves when its status changes is location encoding
state. That is the defect Revision 222 removed when it deleted the `STATUS-` tag
files.

**`sessions/` is separate, and that is a different kind of split.** A session is a
different **object**: a different id scheme, a different schema, and it *owns*
dossiers rather than being one. Splitting on object type is right; splitting on a
property of an object is what costs.

[&#8593; Contents](#contents)

## 3. What stays with the project

| Stays | Why |
|---|---|
| **the record** — dossiers, sessions, revisions, ledgers | it is *about* the project's subject and must be committed with the code it describes |
| **`.iris/config.json`** | the record root, the project's `kind` vocabulary, its currency watches, and the **pinned IRIS version** |
| **the project's blueprints** | they describe the project, not the framework |
| **project-specific prompts** — how to write a runbook, how to author a script | conventions of *this* project; IRIS has no opinion on runbooks |
| **the router** — `AGENTS.md` / `CLAUDE.md` / equivalent | it routes between the project's rules and IRIS's, so it belongs to neither and lives with the one that needs routing |
| **everything else the project owns** — its scripts, helpers, references, env | never IRIS's |

**The test for any file is the one the router already carries:** *would this still
be true in a project that did something else entirely?* Yes → IRIS. No → the
project.

[&#8593; Contents](#contents)

## 4. Two repositories, later

The layout above works as one repository today and is **also** the two-repository
layout minus a `git init`. That is deliberate: the extraction should be a
`git subtree split`, a new remote and a deleted directory — not a redesign.

```text
~/…/iris/                 its own repo
  … as section 2, plus:
  VERSION                 what a project pins against
  record/                 ← IRIS USES ITSELF: its own dossiers and sessions

~/…/<project>/
  .iris/config.json       names the pinned IRIS version
  record/                 the project's own
```

**`iris/record/` is the point.** Every decision about IRIS — the genus rename,
D24, F27, the naming — is a decision about IRIS, and in a single repository they
are filed under whatever project happens to host it. Separate, they are IRIS's
own record, and the reusability claim stops being a claim: **if IRIS can hold its
own reasoning, it works.**

```text
// .iris/config.json
{
  "irisVersion": "1",
  "irisCommit": "94afe37",
  "record": "record/",
  "kinds": ["runbook", "cross-cutting", "instruction-set", "session-management"],
  "patchDir": "…/patches"
}
```

`atelier` self-locates its own repository, then finds the project by walking up
from the working directory for `.iris/config.json`.

**And this is what makes `0053` solvable rather than harder.** *The rules are
versioned and a session's reading of them is not* — in one repository there is no
version to pin, because the rules and the record are one commit. **`irisCommit` is
that version**: `atelier` can warn when the running IRIS is ahead of what the
record was written against, and a dossier can record which IRIS it was read
under. Splitting the repositories is what gives the anchor something to point at.

[&#8593; Contents](#contents)

## 5. Where the tree actually is

**None of section 2's record layout exists yet.** As of Revision 273:

| Section 2 says | The tree has |
|---|---|
| `record/dossiers/` flat | **four trees** — `docs/runbook-findings/` (three levels deep), `docs/cross-cutting-findings/`, `docs/instruction-set-findings/`, `docs/session-management-findings/` |
| `record/sessions/` | `docs/sessions/` — correct but for the parent |
| `record/REVISIONS.md` | `APPLY-MANIFEST.md` at the repository root |
| `iris/lib/` | `.internal/ai-scripts/session-management/` |
| `iris/bin` or `atelier` | six entrypoints in `bin/`, among 42 that belong to the project |
| `iris/prompts/`, `iris/templates/` | under `.github/` |
| `.iris/config.json` | does not exist |
| `dossier` as the unit noun | `bundle`, **3,518 occurrences** |

**What does exist is `iris/` itself** — twelve documents and one coverage map,
written into the new home because a new file has no incoming citations and is
therefore free.

**`coverage-procedure.md` is kept rather than discarded**, and it is the reason
the rewrite can be trusted: it maps every section of the 979-line source to where
its content landed. **A rewrite that loses a rule passes every check** — a file
that has lost half of itself keeps a valid header, a well-shaped table and a
clean render — so the map is the only evidence that nothing went missing. The
same exercise against `docs/legend.md` caught three sections about to be dropped,
one of which was the owner's override.

**Everything in that table is gated behind one thing.** `0052` F2 is the
requirement that a breaking change to a record format arrive with a migration
plan, and it is unwritten. Seven changes are queued behind it, and moving any one
of them first is how a record ends up half-migrated with no statement of what
happens to the half that predates it.

[&#8593; Contents](#contents)
