# Worker sessions under a managing session

**Raised:** 2026-09-08, by the owner, while looking at an allocation proposal and
observing that he is the bottleneck it does not model.

This is an idea rather than a finding: nothing is broken. The allocator assumes
that a session with work can proceed, and the thing that actually gates
throughput is that **every session's work returns to one person** who has to read
it, check something, look something up, answer work email, or eat.

## The observation

`docs/architecture/allocation-and-inquiry.md` optimises how bundles are
distributed and how much a session puts in one response. Both reduce the owner's
load per exchange. Neither reduces **the number of exchanges**, and the number of
exchanges is the constraint.

Some of what comes back does not need a person at all: a regression run, a
conformance sweep, a retrofit that follows a decided rule, a sync of one document
against another it derives from. Those arrive as things to read because there is
nobody else to read them.

## The shape

**A managing session with autonomy over worker sessions.** Workers take the
mechanical work — checks, regressions, retrofits, syncs. They report to the
manager, not to the owner. The manager decides what to accept, what to re-run,
what to escalate, and **reports to the owner only what needs a person.**

The owner monitors the manager rather than the workers.

## What makes it hard, stated before anyone builds it

- **A decision made by a manager is still a decision**, and the whole record
  exists because decisions and their reasons separate. A manager's judgement has
  to land in `decisions.md` with the same rigour, attributed to it, or the
  structure this repository is built on quietly stops being true.
- **Autonomy over a `toolkit` write is the line.** A record write is cheap to
  undo; a toolkit write is revert-and-re-review; an evidence write may be
  unrecoverable. The obvious first boundary: **workers may propose anything and
  write nothing outside their own scratch.**
- **`0049` happened to a session working under direct supervision.** It composed
  correctly, applied incorrectly, and reported the result in language that read
  as compliance. A layer of delegation does not make that less likely.
- **What the manager filters out is invisible.** The failure will not be a wrong
  answer reaching the owner; it will be a right question that never did. Whatever
  is built needs the manager's filtering to be inspectable after the fact.

## The cheap first version

Nothing above needs new machinery to begin. **A single session already runs
sub-agents**, and the mechanical work is already scripted:
`verify-session-findings.sh`, `test-session-management.sh`,
`plan-findings-work.sh check`, `verify-doc-currency.sh`. A session that fans
those out, merges the reports, and puts one paragraph to the owner is the same
shape at one level of nesting, with none of the ownership questions.

**Start there, and see what the manager filters out.** That is the datum the
design above actually needs, and it is the same argument as `0048`: the limit
cannot be set before the thing it limits is measured.

## Note

This bears on `0048` — a manager that never tires changes what a session's
capacity is *for*. And on `docs/architecture/allocation-and-inquiry.md` section
8, whose turn record is what would show whether a manager reduced the owner's
exchanges or merely moved them.
