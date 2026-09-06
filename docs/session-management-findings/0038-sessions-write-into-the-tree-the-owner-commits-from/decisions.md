# Decisions — sessions write into the tree the owner commits from

**Findings bundle:** `0028` · **Status when opened:** `in progress`, 2026-09-04.
**Status now:** `resolved` — what was done is in `resolutions.md`.
**Owner:** `restore-apps-outstanding-20260903-000000`.

Decisions are recorded per finding as they are made. A finding with no entry here
has not been decided, and `resolving` cannot begin until all six have one.

**This bundle is unusual: its proposed fix was already running when it was
decided.** Revisions 178, 179 and 180 were composed in a scratch copy and handed
over as patches, before finding 1 was put to the owner. The evidence below is
from those three, not from reasoning about them.

| # | Finding | Decided |
|---:|---|---|
| 1 | Two sessions' uncommitted work interleaves in shared files | **yes** — 1.1 |
| 2 | A revision's validator baselines are measured on another session's tree | **yes** — 2.1 |
| 3 | A session's work has no diff boundary | **yes** — 2.1 |
| 4 | Backing out one session's change is surgical | **yes** — 2.1 |
| 5 | A session can amend a revision the owner has already committed | **yes** — 5.1 |
| 6 | The write discipline does not distinguish where a write is composed | **yes** — 6.1 |

---

## Finding 1 — compose outside the tree, hand over a patch

**Decision 1.1 — a session composes its changes in a copy of the repository
outside the connected folder, runs the validators there against its own change
alone, and hands the owner a patch.** Owner, 2026-09-04.

### The evidence, from three revisions run this way

| | |
|---|---|
| Patches applied cleanly to a tree that had moved under them | 3 of 3 |
| Validator runs attributable to one session's change | 3 of 3 — previously 0 |
| Patches abandoned because the revision number had been taken | 2 |
| Work lost | none |

The copy is 24MB with `.git` and takes about a second. The three validators
self-locate from `BASH_SOURCE` and none of them invokes git, so they run against
the copy unchanged and report identical numbers — which `0028` measured before
this decision and which held for all three revisions since.

### What it answers

Findings 2, 3 and 4 are not separately fixable; they are consequences of the
shared tree and they go with it. Validation becomes attributable because the tree
being measured contains one session's change. The patch is the diff boundary the
owner had no way to see. And backing a change out becomes *not applying it*
rather than surgery against a file two sessions have touched.

Those three are decided by this decision and their entries below record only what
is specific to each.

### What it makes worse, and the honest record of it

**Two patches were abandoned in one afternoon because the revision number was
taken.** A number chosen at compose time is a guess, and a scratch copy widens
the window between the guess and the apply. Neither loss was expensive — three
small edits re-derived against a fresh baseline both times, which is safer than
replaying a stale diff — but the method as adopted here does not solve finding 5
and slightly aggravates it.

The answer is to take the number at apply time, which is finding 5's decision and
is not made here.

### What it does not solve

A scratch copy in session-local storage **dies with the session**. It survives
context compaction, which is the larger risk; it does not survive termination.
Unapplied work is lost, and the owner has already seen this: at one point in this
session ten decisions existed only in scratch and would have gone with it.

The mitigation is to hand over a patch at a natural stopping point rather than
holding a long-lived scratch, and to say plainly when work exists only there. It
is a real cost of the decision, recorded rather than argued away.

---

## Findings 2, 3 and 4 — carried by decision 1.1

**Decision 2.1 — no separate decision.** These three are consequences of the
shared working tree rather than defects with fixes of their own, and decision 1.1
removes the tree they depend on.

- **2, validation attribution.** The validators run in the copy, which contains
  one session's change. Three revisions have now reported numbers that belong to
  them. `0026`'s undecided option (iii) — stop quoting an `OK` baseline in
  session briefs and track only `MISSING` and `ANCHOR BROKEN` — is still live and
  still worth doing; it is not decided here because `0026` is `resolved` and
  cannot carry it, and it belongs in a new bundle if anyone wants it.
- **3, the diff boundary.** The patch is the unit. It is what the owner reviews,
  and *reviewed and accepted* becomes distinguishable from *committed because it
  was there* — the distinction the owner's stated preference depended on and
  which the arrangement could not express.
- **4, backing out.** Dropping a change becomes declining to apply a patch. No
  `git checkout` against a file two sessions have touched, and no fourteen hand
  edits verified one at a time, which is what Revision 156's reversal cost.

---

## Finding 5 — the revision number is taken at apply time

**Decision 5.1 — an entry is composed with its number left open and numbered when
the patch is applied.** Owner, 2026-09-04.

The collision has a precise cause: **an uncommitted entry is not in the header
the other session reads.** Both sessions followed *re-read the header and take
the next free number* exactly, and both took 167. It happened again two revisions
later. The rule cannot work while entries are uncommitted, and a scratch copy
widens the window between choosing and applying.

Numbering at apply time closes the window rather than narrowing it: at the moment
a patch is applied, one session is writing, and the next free number is a fact
rather than a guess.

### Why not the alternatives

**Renumber on collision** is what happens today — the Revision 123 precedent. It
works, and it cost two abandoned patches in one afternoon. Both were re-derived
rather than rebased, which is cheap but not free, and the cost scales with how
long a session holds its scratch.

**A helper that scans `## Revision` headings** rather than the header block would
have seen the uncommitted entry and prevented both collisions. It narrows the
window without closing it: two sessions composing simultaneously still pick the
same number. Worth building anyway, as the mechanism that fills the number in at
apply time.

### The cost, stated

An entry cannot cite its own number in its own prose, and the manifest's header
line has to be written at the same moment as the entry. Both are small. This
session wrote *"Revision 179"* into its own entry and each such guess happened to
hold only because nobody took it first.

### The other half of finding 5

The finding also records a session amending a revision the owner had already
committed, having read the manifest before their commit landed. Decision 1.1
answers that: a session composing in a copy amends its own copy, and the patch
either applies to what the owner has or does not. It can no longer reach into the
file the owner is committing from.

---

## Finding 6 — composition is a separate rule from permission

**Decision 6.1 — the three write categories continue to answer *when* a write is
allowed. *Where* it is composed becomes its own rule, applying to all three.**
Owner, 2026-09-04.

Every write — record, toolkit or evidence — is composed in a copy of the
repository outside the connected folder and handed over as a patch. The
categories themselves are unchanged.

### Why they stay separate

They answer different questions and the answers do not line up. Permission varies
by category and by a findings bundle's status: a record write is never gated, a
toolkit write waits for `resolving`, an evidence write needs the owner's word for
that run. Composition does not vary at all — it is the same for every write, by
every session, at every status.

Folding composition into the categories would write one sentence three times, in
three places that then have to be kept in step. That is `0029` finding 2 exactly,
and adding a fourth instance of it while `0029` waits would be perverse.

### The observation the finding rests on, and why it decides this

**Record writes are ungated and were exactly the ones that collided.** The
manifest and the indexes are under `docs/` or accompany it; every session writes
them; they were never gated because gating them would make deciding impossible.

So the category that needed the composition discipline most was the one the
permission rules deliberately left alone. That is not a flaw in the categories —
they were answering the other question correctly — and it is the clearest
demonstration that the two are orthogonal. A rule keyed to permission would have
exempted precisely the writes that caused the problem.

### The one category where composition was already solved

Evidence writes. A session has no write permission to the artifact volume by
default and the owner grants it one session at a time — serialisation by
permission, decided per run. `0028` names this as the exception that shows the
shape of the answer, and the fix adopted here is the same shape reached by a
different route: one writer at a time, decided by the owner, at the moment of the
write.
