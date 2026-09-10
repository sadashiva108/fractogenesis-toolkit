# Prompt — instruments-and-blind-spots

## Read these first, in this order

**Read [`.github/session-management-instructions.md`](../../../.github/session-management-instructions.md)
before anything else this prompt asks for.** Section 0 is the working cycle and it
is not optional: compose in a scratch copy outside the owner's checkout, verify
there, produce a patch, report a review, **wait**, and apply only on *write it and
provide a commit message*. The owner stages and commits. This session does not
`git add`, `git commit` or `git push`.

Then [`docs/rules/README.md`](../../rules/README.md), and *What nothing else tells
you* in particular — eight facts with no other home, each of which cost a session
real time to learn.

**Then `iris/`, which is new and is the manual.** Twelve documents written at
Revisions 274 and 275 — [`vocabulary.md`](../../../iris/vocabulary.md) first,
because nothing else parses without it, then
[`verifications.md`](../../../iris/verifications.md), which is **your subject
stated as a survey**: every check, what it examines, and *what it does not*. It is
one of four written before the genus rename and carries a currency note saying so.

**Read `.github/ai-prompts/session-management/conformant-prompt.md` once and
late**, after the above, as a cross-check rather than an authority. It is rank 4,
declares itself current as of Revision 286, and the manifest head is past 279.
Read it looking for **a rule with no home** and **a rule whose home says something
different**. Its Part 6 is the only part that is not a copy of anything and is
therefore the only part with nothing to correct it: treat it as dated context,
never as state.

---

## You own two bundles, and they are the same subject from two sides

**Assigned at the owner's direction, Revision 286.** Both stood `unclaimed` since
Revision 286, when `assurance-coverage-20260908-204724` closed and released seven.

| | Live | The reading |
|---|---:|---|
| [`0050`](../../session-management-findings/0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record/) | 5 of 6 | **Instruments that are correct and cannot fire**, and one that unmakes the record |
| [`0041`](../../session-management-findings/0041-index-and-manifest-tables-have-a-shape-nothing-checks/) | 5 of 6 | **A required shape nothing checks**, and a check released unbuilt |

**`0050` is about instruments that cannot fire. `0041` is about a shape nothing
looks at.** One is a check that runs and sees nothing; the other is a check that
was decided and never written. **Between them they are the answer to *how do I
know this framework works***, which is the question the owner asked when this
whole effort started.

**`0041` carries five `decided` members and no work done on any of them.** D1
through D6 are accepted; the carrying-out is yours. **That is the reason this
session exists**: nineteen members across six bundles stand `decided` inside
`unclaimed` bundles — decisions taken, work impossible, because an unclaimed
bundle is closed to every session.

## Where to start, and why

**Start with `0041` D6.** *A total is summed from the rows it describes, or it is
not written.* It is decided, it is small, and **it would have caught four separate
mistakes made on 2026-09-09 alone** — three index rows left at stale counts and
standings, and a session's Findings column reading 51 against a source of 57.
Every one was found by a checker that already exists; D6 covers the one class that
still is not covered. Building it is the shortest path from *decided* to *this
framework catches things*.

**Then `0050` F3, and treat it as the emergency it is.**
`extract-metadata.py` regenerates the data from the markdown and on a healthy tree
**unmakes the record**. Measured twice: Revision 286 recorded 62 files and 429
values across 20 fields; a run on a throwaway copy on 2026-09-09 measured **65 of
65 files and 601 values across 38 fields**, taking `edges` 59 → 31, `standing`
54 → 0 and `state` 11 → 0. **It has no safe no-op** — the run that measured it was
an unrecognised `--help` the script treated as live. F6 records that the earlier
count was two field families of twenty. **Nothing in the tree stops anyone running
it**, and §10a's procedure still routes a session toward it as the apparent
remedy for a failure that procedure itself produces.

## Three things that will bite you

**`plan-findings-work.sh check` exits 0.** It printed 43 conformance findings and
returned success while this prompt was written. **It cannot gate anything**, and
every claim that the tree is checked rests on someone reading its output. That is
`0050` F4's class and is not yet recorded as a member of it.

**Your own guard cannot see you.** `write-location-guard.sh` is wired on
`Edit|Write|MultiEdit` and `Edit|Write|MultiEdit|Bash`. **A session reaching the
checkout through a desktop bridge writes with `mcp__remote-devices__device_bash`
and matches neither.** `0050` F1 records this from the instrument's side.
**`0045` F4 records the same guard from the other side** — that a matcher on tool
name cannot be a proxy for a caller — and was written independently on 2026-09-10
by `entity-model-and-vocabulary-20260909-053548`. **Whether those are one finding
or two is yours to settle**, and the honest options are a `duplicates` edge or a
`co-decides` one. Do not silently absorb the other bundle's member; it is not
yours.

**Never quote an `OK` total.** The totals move whenever anyone parks a note.
Quote `MISSING`, `FAIL`, `WARN`, and know the standing baselines before reading a
number as a regression: `headers` **11 FAIL**, all in `0030` and `0035`; runbook
structure **25 FAIL** across 27 documents; doc-paths **MISSING 3**, all of them
one citation of `bin/check-manifest-revision.sh`, a script that does not exist.

## What is not yours

**`0037`, `0039`, `0043`, `0045`, `0048`** belong to
[`entity-model-and-vocabulary-20260909-053548`](../entity-model-and-vocabulary-20260909-053548/) —
the entity model, and **the three rule documents are theirs**: `docs/legend.md`,
`.github/session-management-instructions.md` and the conformant prompt. Their
`0043` F13 records that **edge kinds have no closed set and no reason is validated
anywhere**; that is an instrument gap in their bundle, and it is a place to
contribute rather than to duplicate.

**`0038`, `0047`, `0052`** belong to
[`drift-and-the-write-boundary-20260909-053548`](../drift-and-the-write-boundary-20260909-053548/).
**`0052` F1 is the one to watch** — *nothing re-verifies that a resolution still
holds* — because it and `0037` F9 (a currency watch aimed correctly and never
armed) are the same defect from two directions, and either could answer the other
by accident.

**A `framing` member in any of those is open to you to record into.** Deciding is
not the owner's privilege; closing the deciding is.

## What this session owes

A working check for `0041` D6, a decision on what happens to
`extract-metadata.py`, and — if nothing else is achieved — **a written answer to
which instruments can fire and which cannot**, because that answer currently
exists only in `iris/verifications.md`, which is a survey and not a record.

<!-- historical: bin/check-manifest-revision.sh -->
<!-- The path above is named by this prompt as a CITATION THAT DOES NOT RESOLVE --
     it is the whole of the doc-paths MISSING baseline, and repairing it here
     would delete the warning. `historical` is the marker meaning do not repair
     this. `verify-doc-paths.sh` has no marker for "a path this document reports
     as broken", which is a small gap in the checker and is recorded rather than
     worked around silently. The real helper is
     ./bin/verify-session-findings.sh manifest-revision. -->
