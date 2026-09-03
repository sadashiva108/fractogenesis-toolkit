# A home for findings whose subject is not this toolkit

**Raised:** 2026-09-03, restore-apps session, after an ad-hoc investigation
arrived from a colleague in Team chat — an ingestion app's call volumes dropping
away in Humio — and there was nowhere in `docs/` it could go.

This is an idea, not a finding: nothing here is broken. The structure simply has
no shape for a case it will keep meeting.

## What is missing

Both findings trees are scoped to the reimage workflow.
`docs/runbook-findings/<runbook>/` is keyed to a runbook stem, and
`docs/cross-cutting-findings/` is defined as *broad and agnostic to any
particular runbook* — which still means the workflow's own shared machinery. A
question about an employer application's log volumes is neither, and filing it in
either tree makes both indexes lie about their scope.

Two things arrive together and should not be confused:

- **The session.** Real work, worth tracking here while several threads are in
  flight — which is why it came up at all.
- **The subject.** Somebody else's system, in somebody else's estate.

The session shape already handles the first: a bundle with `prompt.md`, a state,
and an empty `findings-manifest.md` tracks the work without pulling the subject
in. What has no answer is where the reading goes when there is one worth keeping.

## The constraint that decides most of this

**This repository pushes to a personal GitHub account.** Employer material —
application names, call volumes, internal hostnames, colleague names, verbatim
chat — does not belong in it, whatever the directory structure says. That is not
a preference to be weighed against convenience; it is the boundary the answer has
to respect, and it rules out the most convenient option.

So the useful question is not *where does an external finding go* but *how much
of one may exist here at all*.

## Shapes worth considering

Sketched, not chosen. Whichever is picked will want its rejected alternatives
written down, at which point this becomes an architecture record and leaves this
directory.

- **A separate private repository, same bundle shape.** The lifecycle in
  `docs/legend.md` is not specific to this workflow: a reading, decisions, then
  resolutions is how any investigation goes. The shape is the reusable part.
- **A pointer-only tree here.** The bundle exists so the work is visible and the
  session has something to own, but it holds no substance — only that an
  investigation happened, its status, and where the real material lives.
- **A scrubbed tree here.** Technical substance without identifiers: no names, no
  verbatim messages, no internal hostnames. Useful for a genuinely general
  lesson; risky as a habit, because scrubbing is a judgement made once per note
  and wrong once is enough.
- **Session-only.** No third tree. The bundle's `findings-manifest.md` stays
  empty and the reading, if any, lives outside.

## Two consequences to settle either way

**The number sequence.** Findings share one sequence across both trees so
`finding 0007` names a bundle without needing its scope. A third tree either
joins that sequence — leaking numbers into and out of a repository the toolkit
cannot see, so gaps appear here with no explanation — or starts its own, and
`finding 0007` becomes ambiguous, which is exactly what the shared sequence
exists to prevent. Neither is free.

**What makes a finding external is its subject, not its origin.** A defect in
`restore-repos.md` noticed during a work conversation is a toolkit finding.
Anything else invites filing by where it was noticed, which is the mistake
Revision 162 corrected for runbook-versus-cross-cutting.

## What is not proposed

Gitignoring a tree inside a tracked `docs/`. Revision 162 removed exactly that
ambiguity, and a directory that exists locally but reaches no clone is the
condition where nobody can tell whether a note is missing or was never written.
