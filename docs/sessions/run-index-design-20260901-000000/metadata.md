# Session metadata — run-index-design

Authoritative for who and what has owned this bundle. `docs/sessions/INDEX.md`
carries the state and points here.

## Owners

| From | Until | Assistant | Session id | Model | Environment |
|---|---|---|---|---|---|
| 2026-09-01 | 2026-09-02 | Claude | `01KcZvrKMgfenhrT9DvxW9Jk` | not recorded | Linux, Bash 5.x |
| 2026-09-04 | — | Claude | `session_01KcZvrKMgfenhrT9DvxW9Jk` | `claude-opus-5` | Linux, Bash 5.x, cloud container; the repository and the artifact volume reached through the desktop bridge |

**The two rows carry the same identifier**, and that is not a transcription
error. This is the 2026-09-01 session resuming, not a successor taking over —
the harness reports it as `session_01KcZvrKMgfenhrT9DvxW9Jk`, and the earlier
row records the same string without the `session_` prefix the trailer convention
later settled on. It is written as two rows because they are two periods of
ownership separated by two days in which the bundle was owned by nobody, and
because the first row is closed and is not edited.

That identity is also the plainest evidence for the state correction below: a
`handoff` transfers unresolved findings to a successor, and the session on the
second row is the session on the first.

No transcript link: this session predates the bundle shape, and the identifier
survives only because the session wrote it into
`docs/sessions/session-responsibilities.md` and into the `**Found:**` line of
every note it parked. That is also how its findings were attributed during the
Revision 162 conversion.

## Environment

Linux with Bash 5.x, per its own handoffs. Nothing it validated was validated on
macOS stock Bash 3.2 — its handoff says `/bin/bash -n` is owed for Revisions
116–128 and for everything the session wrote.

The 2026-09-04 period runs in the same shape: a cloud Linux container with Bash
5.x, reaching `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit` and
`/Volumes/Data/reimage-CVG-0002160-500-20260816-open` through the desktop
bridge. `mapfile`, `declare -A`, `sed -i` and `stat -c` all work here and none of
them works on the target, so the Bash 3.2 debt is unchanged and grows with
anything this period writes.

## Resources

Reconstructed rather than recorded: the repository and the artifact volume. The
session's own note says it could not see `/Users/dkittrell/workspace/*`.

## State

`owned`, from 2026-09-04. Items 1 through 3 are done and item 4 is where the
work restarts; `handoff-20260902-000000.md` beside this file is the later of two
handoffs and is the one to read.

It was `STATE-handoff` until 2026-09-04, and that tag did not describe this
bundle under the definition Revision 179 gave it — *ended by transferring its
unresolved findings to a successor*. No successor exists and nothing was
transferred: four findings were reassigned away on the owner's instruction under
Revision 178, which is somebody else moving them rather than this session handing
them on, and ten remain here with four unresolved. `docs/legend.md` also holds
that a session may not end leaving a finding owned by a session that has stopped,
which the old tag breached outright. `unclaimed` would once have fitted and was
abolished in the same revision, so `owned` is the only non-terminal state left.

The tag was wrong because the vocabulary moved twice under a stationary bundle,
not because anything was done incorrectly. That is finding `0029`'s subject.
