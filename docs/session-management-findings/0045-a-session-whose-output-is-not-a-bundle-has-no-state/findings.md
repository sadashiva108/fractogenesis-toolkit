# A session whose output is not a findings bundle has no state that fits

**Recorded:** 2026-09-07, from this session's own state after four revisions of work.  
**Session:** `allocation-and-inquiry-design-20260906-233205` (`session_015FpYVBF7dDoDrHfKDkq8fn`)  
**Severity:** low, and it misleads the one reader it is written for. `docs/sessions/INDEX.md` is what an owner scans to see who is doing what, and it currently shows a session that produced two architecture records and a decision as indistinguishable from one created a minute ago.  
**Felt at:** `docs/legend.md` *Session states*; `docs/sessions/INDEX.md` Bundles and Findings columns  
**Scope:** session management. The fix lands in `docs/legend.md` and the sessions index.  
**Relates to:** `0043` — F8 there is the same shape one vocabulary over: a status name that cannot carry what a reader needs from it

**Read:**

- `docs/legend.md`, *Session states* and *How the two meet*
- `docs/sessions/INDEX.md`, all seven rows
- `.github/session-management-instructions.md` section 5

Recorded `unclaimed`. Not owned, and no session should open it until the owner
assigns it.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | Session state derives only from owned bundles, so a session that contributes and designs but owns nothing stays `available` | `un-started` |
| F2 | The sessions index shows such a session as empty, next to sessions holding thirty findings | `un-started` |

## F1 — `available` means two different things

`docs/legend.md` defines `available` as *"created or cloned, owning no findings
bundle yet"* and derives every other state from what a session owns. `active`
requires owning a bundle that is not `resolved` or `withdrawn`.

This session has, at Revision 217: written
`docs/architecture/allocation-and-inquiry.md`, run the allocator and corrected
that record from the run, recorded `0044` and this bundle, contributed F6 and a
review to `0043`, contributed a live instance of `0043` F4, and taken `0039` D5.
**It owns no findings bundle, so it is `available`** — the same value as a
session opened five minutes ago that has read nothing.

The vocabulary is not wrong; it answers *what does this session own*. What it
cannot answer is *is anyone doing anything here*, which is the question the state
is read for. `findings-and-sessions.md` section 11.6 names the failure it leads
to — **the characteristic failure is not a wrong status but a still one** — and
this is that failure available by construction rather than by neglect.

**Not every session's output is a bundle.** An architecture record, a decision
recorded against another session's finding, and a review of a draft are all real
work that the ownership model does not touch. `pre-image-capture-conformance` is
described in its own row as *"a reading session: the report is the output"* and
reads `active` only because it happens to own bundles as well.

## F2 — the index shows the work as absent

`docs/sessions/INDEX.md` carries Bundles and Findings columns, both derived from
ownership. This session's row reads `—` and `—` beside rows reading 7 and 37.

An owner scanning that table to decide where work should go sees an idle session.
The Notes cell carries the truth in prose, which is the thing the columns exist
to save a reader from having to read.

`docs/architecture/state-as-data.md` section 4.4 solved the same problem for
bundles by splitting one overloaded slot into three fields that answer three
questions. Whether the session vocabulary needs the same treatment, a new state,
or only a derived *contributions* count in the index is the decision this bundle
owes and does not take.
