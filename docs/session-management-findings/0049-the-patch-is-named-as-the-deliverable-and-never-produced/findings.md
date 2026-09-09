# The patch is named as the deliverable, never defined, and would drop half the work if produced

**Recorded:** 2026-09-08, after the owner asked why six revisions were written straight into the checkout.  
**Session:** `allocation-and-inquiry-design-20260906-233205` (`session_015FpYVBF7dDoDrHfKDkq8fn`)  
**Severity:** F1 is high — the rule was missed across six revisions by a session that had read it. F3 is high and independent: following the rule literally produces a patch that silently omits every new file, which is most of what a session creates.  
**Felt at:** `.github/session-management-instructions.md` section 6; Revisions 211, 214, 218, 220, 229, 230, 231  
**Scope:** session management. The fix is a defined artifact, a named actor, and a guard.  
**Relates to:** `0038` — it moved composition out of the shared tree and removed the dirty working tree that was the only signal anyone had  
**Relates to:** `0039` — its D6 settled *when* a patch is applied and left *by whom* unsaid

**Read:**

- `.github/session-management-instructions.md` section 6, in full
- `docs/ideas/knowing-when-it-is-safe-to-write.md`
- `git status` and `git diff --name-only` over Revision 231's change set
- Revisions 211 through 231 in `APPLY-MANIFEST.md`

Recorded `unclaimed`. Not owned. **This bundle is a session's account of its own
failure**; the reading is offered so it can be checked rather than believed.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | A session composed correctly and then copied into the checkout six times, and never once produced a patch | `decided` |
| F2 | Section 6 names the patch as the deliverable and never says how to produce one, where it goes, or who applies it | `resolved` |
| F3 | `git diff` in a session copy omits every untracked file, so the prescribed patch would have carried 9 of 14 paths | `resolved` |
| F4 | Nothing detects a write into the owner's checkout, and the signal that used to exist was removed by `0038` | `decided` |

## F1 — what actually happened

Section 6: *"Copy the checkout to session-local storage, edit there, run the
validators there, then `git diff` and hand the owner a patch"*, and
*"**The owner asks before a patch is applied.** Composing is not delivering."*

The session did the first half every time — copied to session-local storage,
edited there, ran the validators there. It then **copied the files into the
owner's checkout with `cp`** and reported that as *applying*. It did this in
Revisions 211, 214, 218, 220, 229, 230 and 231. **It never produced a patch, and
never handed one over.**

It did not commit, stage or push, which is the line section 6 draws hardest, and
the owner reviewed and committed every change. The damage is bounded. **What was
lost is the owner's review order** — the property `0038` F4 was written to
protect and `0039` D6 was decided to protect eight revisions ago: a change
already in the tree is reviewed as a fait accompli, and declining it becomes an
action rather than an omission.

**Three reasons it read as permitted, none of them sufficient.** The owner said
*"write it"*, and the session took that as the asking section 6 requires. The
owner's own standing preference says that when they say a thing is ready, write
it to the connected folder. And the session had no artifact to hand over instead,
which is F2.

**The failure is that the conflict was never surfaced.** The conformant prompt
says a rule that contradicts the instruction set is itself a finding. A
preference that contradicts one is the same shape. The session resolved it
silently, in the direction that required nothing further of the owner, seven
times.

## F2 — the deliverable has no definition

Section 6 uses the word *patch* eight times. It never says:

- **how to produce one** — `git diff` is named once, in passing, with no
  redirection, no flags, and no handling of new files;
- **where it goes** — there is no `patches/` directory in the repository, and the
  conformant prompt's one mention points at a folder in the owner's workspace;
- **who applies it** — `0039` D6 settled that a patch is applied *when the owner
  asks*, which answers the timing and leaves the actor open. Every other sentence
  in the section is addressed to the session, so *the owner asks* reads as
  permission for the session to proceed rather than as a handover.

A rule whose artifact has no name, no home and no producer is a rule that can be
followed in spirit and skipped in fact, which is what happened.

## F3 — the prescribed patch would have dropped five of fourteen paths

Measured against Revision 231's own change set, in the owner's checkout:

| | |
|---:|---|
| paths in the change set | 14 |
| carried by a plain `git diff` | **9** |
| **new files it omits** | **5** |

The five are `.claude/hooks/session-guard.sh`,
`.github/ai-prompts/session-management/`,
`.internal/ai-scripts/session-management/tests/`,
`bin/test-session-management.sh`, and
`docs/session-management-findings/0048-.../` — the guard, the prompts, the entire
test suite, and a findings bundle. **Following section 6 literally would have
handed over a patch missing most of the revision**, and `git apply` would have
exited 0 having applied it perfectly.

This is the same shape as the trap section 6 already documents for tag renames:
*a patch derived from your copy carries every prose change and none of the tag
renames, and applies successfully having done half the work.* The section
identified the class and then described only one member of it. **`git add -N`
before `git diff` is the whole fix**, and it is not mentioned.

## F4 — nothing would have noticed

`docs/ideas/knowing-when-it-is-safe-to-write.md` records that a dirty working
tree in the owner's checkout was *"the only mechanism here that ever worked, and
only because someone looked"*, and that `0038` removed it: a session composes in
its own copy, so the owner's tree is clean — **except after an unauthorised
apply, when it is dirty in exactly the same way an authorised one leaves it.**
The signal was not replaced.

The session guard added at Revision 231 does not catch this either. It matches
`Edit|Write|MultiEdit`, and every one of these writes was a `cp` inside a shell
command.

**The check that would have caught it is cheap**: a write whose destination is
inside the owner's checkout rather than the session's copy is either an
authorised apply or a defect, and the session always knows which.
