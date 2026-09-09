# What a session is given

> **Role.** The complete list of what a session receives, by how it began —
> created, cloned or by handoff.
>
> **Authoritative for** the *inventory*: if a session had to be told something not
> listed here, that is a finding against this file. **Not** authoritative for the
> content of anything it lists.
>
> **Rank 4** of 6. Order in
> [`../../copilot-instructions.md`](../../copilot-instructions.md).

**The complete list, so nothing is assembled by hand.** `docs/legend.md` says a
session begins **created**, **cloned** or by **handoff**; this file says exactly
what it receives in each case. If a session had to be told something that is not
listed here, that is a finding against this file.

---

## Every session, regardless of how it began

**Pasted into the session.** These two are the prompt; nothing else is pasted.

| | |
|---|---|
| `.github/ai-prompts/session-management/conformant-prompt.md` | the half that is the same for every session, kept current as the rules change |
| `.github/ai-prompts/session-management/session-management-prompt.md` | the subject-specific half, where the work is session management |

**Read from the repository, not pasted.** The conformant prompt names these in
its reading order and a session opens them itself.

| | |
|---|---|
| `.claude/CLAUDE.md` | the pointer, for Claude. A pointer and never a second copy |
| `.claude/settings.json`, `.claude/hooks/` | the guards that run on every write |
| `.github/copilot-instructions.md` | the repository's own build, layout and script rules |
| `.github/session-management-instructions.md` | how sessions and findings bundles work |
| `.github/toolkit-instructions.md` | the project's subject, where the work touches it |
| `docs/legend.md` | every finding status, bundle status and session state |
| `docs/sessions/session-responsibilities.md` | the boundary between concurrent sessions |
| `docs/INDEX.md`, then the INDEX.md of the tree being worked | what is parked |
| `docs/architecture/` | design that outlives the session that wrote it |
| `docs/ideas/` | things that do not exist yet |
| `docs/ledgers/` | dated statements of what exists and what is owed |

**The instruction sets live under `.github/` and not under `.claude/`** because
this repository is worked by Copilot at work as well as by Claude, and the rules
are the same for both. `.claude/CLAUDE.md` points at them for exactly that
reason and must never restate them.

**Created in the repository, by the session, before any other work.**

```text
docs/sessions/<title>-<stamp>/
|-- metadata.json     required from the moment the bundle exists
|-- prompt.md         both halves of the prompt it was given
`-- findings-manifest.md   once it owns a bundle
```

`<stamp>` is `YYYYMMDD-HHMMSS` in **America/New_York**. The name is fixed at
creation. There is no `STATE-` tag: state derives from `metadata.json`.

## Created

The list above and nothing else. A created session gets the **conformant**
prompt — current as the rules stand — rather than a copy of somebody's.

## Cloned

Everything a created session gets, **plus the source session's customisations**:
its `prompt.md` in full, including any amendments issued to it in flight, and any
resource or environment particulars in its `metadata.json` that still apply.

**It does not get the source's bundles.** Cloning copies how a session was told
to work; it does not move ownership. The clone's `metadata.json` names the
session it was cloned from.

**Clone rather than create when** the new session's work pulls on what the source
already holds — the allocator reports this as `CLONE ... (pull N)`, naming the
source. **Create when nothing ties them**, because a clone inherits context that
is then dead weight, and dead weight in a prompt is read every turn.

## Handoff

Everything a clone gets, **plus the outgoing session's bundles**, and a
`handoff-<stamp>.md` written by the outgoing session naming what transfers, what
is known broken, and what is owed. `docs/legend.md` carries exactly which bundles
qualify.

---

## What is deliberately not on this list

**A per-session copy of any rule.** Every entry above is either pasted once or
read from one authoritative file. `0039` F9 records what happens otherwise: six
rules accumulated in the conformant prompt while it lived outside the repository,
where they took no revision, reached no clone, and no checker could see them.
They were installed at Revision 217 and the prompt moved into the repository at
Revision 231 so that cannot recur.

**Anything the owner has to remember.** If a session needs something not listed
here, add it here rather than telling the session.
