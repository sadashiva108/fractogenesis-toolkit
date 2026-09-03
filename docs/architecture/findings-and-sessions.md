# Findings and sessions — the bundle structure

**Written:** 2026-09-03, restore-apps session, covering the design that shipped
over Revisions 160 through 164.
**Scope:** the two object types under `docs/`, their lifecycles, the conventions
that hold them together, and why each was chosen over the alternatives. Written
to be readable by someone who has never seen this repository, because the
structure is meant to be reused.

---

## 1. The problem

Work on this toolkit is done by AI sessions — several of them, sometimes
concurrently, always across more sittings than one. That produces three failures
that have nothing to do with any particular task:

1. **A reading evaporates.** A session spends an hour reading evidence and
   produces ten findings. They exist in a chat log. The next session starts cold
   and re-derives four of them, misses six, and contradicts one.
2. **Decisions and their reasons separate.** Something gets fixed; why *that*
   fix, and what was rejected, is gone. Six weeks later the rejected option gets
   proposed again, persuasively.
3. **Nobody knows who has what.** Two sessions edit the same file. Or neither
   does, each assuming the other is on it.

Version control solves none of these. A commit records what changed, never what
was considered, and never what somebody looked at and decided not to change.

## 2. The two objects

**A findings bundle** is a *reading*: what was found in something that already
exists, where it is felt, what it costs to leave. It lives under
`docs/runbook-findings/<runbook>/` when its ramifications are functionally felt
in one runbook, or `docs/cross-cutting-findings/` when they are broad and
agnostic to any one runbook.

    <NNNN>-<slug>/
    ├── STATUS-<status>
    ├── findings.md      the reading
    ├── decisions.md     what was decided, and what was rejected
    └── resolutions.md   what was done, with commit and revision

**A session bundle** is a *unit of work with an owner*, under `docs/sessions/`.

    <title>-<stamp>/
    ├── STATE-<state>
    ├── prompt.md              always required
    ├── metadata.md            who and what has owned it
    ├── findings-manifest.md   the bundles this session owns
    ├── handoff-<stamp>.md     one per handover
    └── final-summary.md       at closed or withdrawn

The two lifecycles run in parallel and meet at exactly one place, section 5.

## 3. Why a directory rather than a file

A finding is not one document. It is a reading, then a set of decisions taken on
that reading, then a record of what those decisions produced — written weeks
apart, by different sessions, and only meaningful together. Three loose files
named `<subject>-findings.md`, `<subject>-decisions.md`,
`<subject>-resolutions.md` sort apart in a directory listing and give no answer
to *is this finished*.

The directory is also what makes the status cheap: one tag file inside it, and
`ls` answers the question without opening an index.

**Rejected: one growing file per finding.** Appending decisions to the reading
means editing the reading, and a reading edited to match what was later decided
is no longer evidence of what was found. `findings.md` is written once and
corrected only for accuracy; that constraint needs its own file to hold.

## 4. Identity: numbers on findings, timestamps on sessions

Findings carry a **four-digit number, one sequence across both trees**, so
`finding 0007` names a bundle without needing its scope. Never reused, never
renumbered.

Sessions carry a **title and a timestamp**, no number.

The asymmetry is deliberate and was got wrong first. Revision 161 named session
folders `<NNNN>-<session-name>` after the finding they worked, which reads well
until a session owns three findings — which is the normal case, not the edge one.
One number in a directory name cannot express a many-to-many relationship. The
title earns its place separately: a listing of numbers is unreadable, and scope
is what someone scanning for the right session matches on.

**Renaming either is forbidden.** By the time a bundle has produced anything its
path is cited by prompts, handoffs, index rows and the change log — the same
failure this workflow already documents for artifact lineages, where a rename
left every prior citation naming something that no longer exists.

## 4a. A bundle is not a finding

A findings bundle is a *reading*, and a reading can turn up one problem or
thirty. `0001` holds ten; the twenty-five converted from parked notes hold one
each. Both are bundles, and the number names the bundle.

Indexes and manifests therefore carry a **Subject** — what the reading was of —
and a **Findings** count, rather than a column headed *Finding* that quietly
implies one. The count comes from the per-finding status table inside
`findings.md`, and a bundle with no such table holds one finding by definition.

The distinction is not pedantry: `resolved` means every finding in the bundle has
a resolution, so a reader who thinks a bundle is a finding will close one that is
nine-tenths open.

## 5. The pointer runs both ways

- A session bundle's `findings-manifest.md` lists every finding it owns, and is
  authoritative for ownership.
- A findings bundle's index row names the session working it.

Neither side is derived from the other, and neither directory name carries the
other's identifier. That is what lets a finding outlive several sessions and a
session own several findings without anything being renamed when the
relationship changes.

**Rejected: deriving one side from the other.** A session number in the finding's
name, or a finding number in the session's, is one identifier doing two jobs; the
moment the relationship stops being one-to-one it has to be broken or renamed.

## 6. The lifecycles

    unresolved ──▶ in progress ──▶ resolving ──▶ resolved
                                     └─▶ superseded (from any status)

    unclaimed ──▶ owned ──▶ closed
                    ├─▶ handoff ──▶ owned (next session)
                    └─▶ withdrawn

Definitions live in `docs/legend.md`; what each state *requires* lives in
`.github/copilot-instructions.md` sections 4c and 4d. This record covers only why
the shape is what it is.

**`in progress` and `resolving` are separate on purpose.** The first is deciding
and produces `decisions.md`; the second is doing and produces `resolutions.md`,
and it may not begin until the decisions are finalized. Collapsing them is how
work starts before the decision behind it is settled, and how a resolution ends
up with nothing recording why it was the right one. It is the single most
load-bearing distinction in the design and the easiest to erode under time
pressure.

**`withdrawn` is terminal and still writes a summary.** Work may well have been
done before the owner pivoted. A withdrawn session that recorded nothing is
indistinguishable from one that did nothing, and the findings it abandons are the
ones somebody picks up cold.

**A bundle holds the earlier status while any finding in it is open.**
`findings.md` carries a per-finding status table; partial progress goes in the
index Notes column rather than into a softened status.

## 7. The tag file

Each bundle carries `STATUS-<status>` or `STATE-<state>` — a marker file,
renamed as the bundle moves.

**Rejected: a suffix on the directory name** (`0001-restore-repos-evidence.unresolved/`).
It would rename the directory on every transition, and the directory name is what
everything else cites. The rule in section 4 forbids it.

**Rejected: status only in the index.** Correct, and invisible. Half of reading a
tree is `ls`, and a structure that requires opening a file to answer *is anyone
on this* will be worked around.

The index row stays authoritative; the tag is a convenience that must agree with
it, and disagreement is a bug in whoever moved the bundle last.

## 8. Why this helps multi-session AI work specifically

Every property above exists because the reader is usually a fresh session with no
memory of the one before it.

- **A prompt is always required, and it always names the instruction set first.**
  A session that has to infer the conventions will invent slightly different
  ones, and two sessions inventing separately is how a tree ends up with two
  shapes for one thing.
- **Handoffs are documents, not status changes.** `handoff-<stamp>.md` carries
  progress, exactly where the work stopped, every assumption the outgoing session
  held, and the resources the next needs — folders to connect, volumes to mount,
  revisions to read. An assumption that stays in a chat log is one the next
  session either re-derives or contradicts.
- **Ownership is explicit and dated**, naming the assistant. Concurrent sessions
  need a boundary they can read before their first edit, not after their first
  collision.
- **A session records its own identity and environment.** `metadata.md` carries
  the assistant, its session identifier and transcript link where the tool
  exposes one, and — the part that matters most here — the environment it
  actually ran in. This workflow targets macOS stock Bash 3.2 and an AI session
  almost never runs there, so *tested* is not a claim until it says where. It
  also makes the chain traceable in both directions: a commit carries the session
  identifier, the identifier names the bundle, the bundle names the findings.
- **A reading is written once.** An AI session asked to update a document will
  cheerfully rewrite it to match the current understanding. Freezing
  `findings.md` and adding `decisions.md` beside it is a structural defence
  against a failure mode specific to this kind of collaborator.
- **Both trees are indexed per scope**, so the question *what is outstanding for
  this runbook* is one file, not a search.

The generalisable claim: **an AI session's memory is the filesystem.** Anything
not written to it did not happen, and anything written ambiguously will be
interpreted differently by the next one. The bundle shape is a filesystem layout
designed to be read cold.

## 9. What it costs

- Ceremony. Three documents and a tag for what might be one paragraph. Mitigated
  by the bundle only existing when there is a reading worth keeping — a passing
  observation belongs in the finding it was noticed in.
- Two places for status, which can disagree.
- Since Revision 164, every parked note takes a manifest revision. That is the
  cost of the notes being under version control and reviewed; one revision covers
  one sitting's notes rather than one note.

## 10. Alternatives rejected, gathered

| Alternative | Why not |
|---|---|
| A flat `docs/gaps/` directory of notes | Held 25 notes with no status, no owner, and no record of what came of any of them. Superseded in Revision 162. |
| Bundles under `.github/` or `.claude/` | `.github/` is normative — it tells an assistant how to work; a finding is an observation. `.claude/` is assistant-specific, and sessions here may be Claude or Copilot. |
| Classify by which file the fix touches | Files a runbook's ramifications land in are incidental. Classification is by where the impact is functionally felt; scripts and artifacts belong to their owning runbook. |
| Per-tree numbering | `finding 0007` becomes ambiguous, which is what a single sequence exists to prevent. |
| Session folders numbered by finding | A session owns several findings. Revision 161's first draft; corrected in 162. |
| Keeping `docs/` gitignored | A reading nobody else can see is a chat log with a filename. |
| Leaving loose session files unmigrated | Two shapes for one thing, and an index explaining which is which forever. |

---

## 11. Assistant capabilities that could carry this

**The constraint first.** The structure must stay assistant-agnostic. Sessions
here are Claude or Copilot, the instruction set lives in one tool-neutral file,
and `.claude/CLAUDE.md` is a pointer rather than a second copy for exactly that
reason. So everything below is an *accelerator*: it makes the conventions cheaper
to follow correctly, and every one of them must degrade to *a session reads
sections 4b through 4d and does it by hand*. An accelerator that becomes load
bearing has turned a portable structure into a Claude-only one.

Ordered by what they would actually buy.

### 11.1 Enforcement at write time

Every invariant in this record is currently discipline. The tag must agree with
the index row. `resolutions.md` must not exist while a bundle is `unresolved`.
`findings.md` must not be edited once the bundle leaves `unresolved`. A new
number must actually be free. Section 7 admits a tag and a row can disagree and
names no way to catch it — the honest answer today is *whoever moved it last*.

This repository already runs a hook on every write. Four checks like the above
cost milliseconds and refuse the write rather than reporting it afterwards, which
is the difference between a rule and a habit. It is the highest-value addition on
this list because it removes the one failure the design cannot otherwise prevent:
a bundle whose recorded state is not its real one.

Portable: the same checks run from a pre-commit hook for any assistant, or none.

### 11.2 Packaging the mechanical part

Creating a bundle is a fixed sequence — take the next free number, make the
directory, write the tag, write the reading, add the index row, add the row to
the owning session's manifest. A session performing that from prose gets it
slightly different each time. This session already proved it: finding `0020`
landed in two manifests because *found by* and *owned by* were reconstructed by
hand and the distinction was noticed afterwards rather than enforced.

A packaged procedure — a skill, a custom command — makes the mechanical half
identical every time and leaves the judgement where it belongs: which tree, what
the finding actually says. Copilot has prompt files that serve the same purpose,
so the *idea* is portable even where the mechanism is not.

### 11.3 The decide/do split already exists as a tool behaviour

`in progress` → `decisions.md` → `resolving` is plan, approve, then execute. A
session that plans, has the plan approved, and only then acts produces those two
documents as a by-product of how it was already working, rather than as
paperwork bolted on afterwards.

This is the one place where the tool's natural shape matches the architecture
instead of being made to fit it, and it is worth saying because section 6 calls
that split the most load-bearing distinction in the design and the easiest to
erode under time pressure. Anything that makes the correct order the path of
least resistance is worth more than a rule saying so.

### 11.4 Parallel reading, with a merge that is real work

Bundle `0001`'s ten findings came from one session reading serially for an hour.
Fanning out — one reader per dimension, then an adversarial pass that tries to
disprove each finding before it is written down — produces readings that survive
review, and the per-finding status table is already the right shape to receive
them.

The caution belongs in the same breath: parallel readers duplicate each other and
contradict each other, and reconciling them is the work, not a formality. A
bundle assembled without that merge is ten findings of which three are the same
finding.

### 11.5 Conventions that travel with the person, not the repository

A workspace-level project can hold documents that persist across sessions and
surfaces. That is a third answer to the question in 12.1: not in the project
repository, not in a second repository, but attached to the workspace, so a
session has the conventions in context whichever repository it opens.

It trades one problem for another and the trade should be explicit: those
documents are outside version control, so they can drift from the repository's
own copy — and drift in the conventions is worse than drift in any note, because
two sessions then build two structures while both believe they are following the
rules.

### 11.6 Noticing silence

The premise of this whole structure is that work spans sittings and owners. The
characteristic failure is therefore not a wrong status but a still one: a bundle
`in progress` for three weeks, an `owned` session with no commits since the day
it was claimed, a `handoff` nobody collected.

A scheduled sweep that lists those costs nothing and is the only mechanism here
that would notice. Nothing in the current design does.

### What is deliberately not proposed

A service fronting the indexes — an MCP server, an API, a database. Section 8's
claim is that an AI session's memory is the filesystem; putting a service in
front of it means a session without that service cannot read the structure at
all, which fails the portability test at the top of this section and would make
the most important property of the design conditional on tooling.

The test for any of the above: **the tree stays readable and writable by a
session that has none of them.**

## 12. Open questions

Recorded rather than answered. None blocks the structure as it stands here.

### 12.1 Does this belong inside a project repository at all?

Here it lives in the repository it describes, which gives it three things: it
travels with a clone, it is reviewed in the same diff as the work it concerns,
and an AI session working in the repo has it in context without being pointed at
it.

Against that: **it is a general mechanism, not a fractogenesis one.** Nothing in
sections 2 through 8 is specific to reimaging a Mac. Reusing it in a second
project means either copying the structure — two copies of a convention, drifting
— or extracting it.

The obvious extraction is a small repository holding the conventions, the legend
and the templates, referenced by each project. That trades one problem for
another: a session working in project A now needs two repositories in context to
know the rules, and the rules are the thing it must read *first*.

### 12.2 If it stays in-repo, what is gitignored?

Currently nothing: all of `docs/` is tracked, deliberately. Two pressures could
change that:

- **Volume.** Every reading, every handoff and every summary, forever, in the
  same history as the workflow. Fine now; a question at a hundred bundles.
- **Content.** See 12.3.

The failure to avoid is the one Revision 162 removed: a directory that exists
locally and reaches no clone, where nobody can tell whether a note is missing or
was never written. If anything is ever gitignored again it should be an entire
tree with a stated reason, never a mixture inside one.

### 12.3 Where do findings whose subject is not the project go?

`docs/ideas/external-findings.md` raises this in full. In short: an investigation
can arrive that is real work worth tracking here while several threads are in
flight, but whose subject belongs to somebody else's estate — and this repository
pushes to a personal account. The session shape already handles the tracking
half with an empty `findings-manifest.md`. Where the *reading* goes, and how much
of one may exist here at all, is open.

### 12.4 The Cowork context question

The practical reason to keep this inside the project: a session working in the
repository has the conventions in context automatically. Moving them out means
attaching a second folder to every session that needs them, which is one more
thing to forget and one more way for two sessions to be working from different
copies.

This is a tooling constraint rather than an architectural one, but it is the
constraint most likely to decide 12.1 in practice, so it is recorded here rather
than discovered later. Section 11.5 sketches a third answer — conventions
attached to the workspace rather than to either repository — and names what that
trades away.

---

## 13. What this record does not cover

The per-state document requirements, the exact naming rules, and the numbering
mechanics — those are instructions and live in
`.github/copilot-instructions.md` sections 4b through 4d, with the vocabulary in
`docs/legend.md`. This record covers why the shape is what it is; if the two ever
disagree, the instructions are what a session follows and this record is what
needs correcting.
