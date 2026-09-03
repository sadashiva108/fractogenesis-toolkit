# The findings-and-sessions architecture disagrees with itself and with the tree

**Found:** 2026-09-03, session `session_019yzcjm2QneJ5ymVEQDi1bu`, on the owner's
request to review the new architecture. Read: `docs/architecture/findings-and-sessions.md`,
`.github/copilot-instructions.md` §§4b–4d, `docs/legend.md`, and every bundle and
index in `docs/`.
**Severity:** one finding is high and governs a rule every future session hits on
its first parked note. The rest are small and mechanical.
**Scope:** cross-cutting. The fix lands in `.github/copilot-instructions.md`,
`docs/INDEX.md`, `docs/sessions/INDEX.md`, `docs/legend.md` and four `prompt.md`
files — no single runbook owns any of it.

## What is conformant

Stated first because the defects below are small against it, and a reader
arriving at this bundle should not mistake the list for a verdict on the design.

- All six directories named in §4b exist and none is empty.
- 26 bundles numbered `0001`–`0026`, four-digit, zero-padded, unique across both
  findings directories, no gaps and no duplicates — one sequence, as specified.
- All 26 `STATUS-<status>` tags agree with their scope's `INDEX.md` row.
- All 5 `STATE-<state>` tags agree with `docs/sessions/INDEX.md`.
- The two-way pointer between a bundle's INDEX row and a session's
  `findings-manifest.md` holds in both directions, except for finding 3 below.
  The four unclaimed bundles correctly show `—` and appear in no manifest.
- `docs/gaps/` is fully retired. No directory, no live citation, and no note
  existing in both the old and new location.
- Every path cited in §§1–6 resolves, including the two bundles cited by name.

## Findings

| # | Finding | Status |
|---|---|---|
| 1 | §4b and §4c contradict each other on whether a findings bundle takes a manifest revision | `unresolved` |
| 2 | Four of five `prompt.md` files violate §4d's "always" rule | `unresolved` |
| 3 | `docs/sessions/INDEX.md` miscounts a manifest it links to | `unresolved` — count corrected in Revision 167; the rule that let them drift is not |
| 4 | `docs/INDEX.md` says `ideas/` is empty; it is not | `unresolved` |
| 5 | Every `resolved` bundle is missing `decisions.md` | `unresolved` |
| 6 | The two session-state diagrams disagree | `unresolved` |
| 7 | Two session identifiers recorded as unrecoverable are recoverable | `unresolved` — the two instances are corrected in Revision 167; the general property is not |

### 1 — §4b and §4c contradict each other, eighteen lines apart

`.github/copilot-instructions.md:107` (§4b):

> These files ARE tracked and reach a fresh clone, so writing one IS a repository
> change and takes an APPLY-MANIFEST.md revision like any other. Revision 162
> exempted them … The exemption is removed.

`.github/copilot-instructions.md:126` (§4c), same file:

> A findings bundle is a READING of something that already exists … It is not a
> change. Recording one touches no tracked file and takes no manifest revision.

Findings bundles live in two of the six directories §4b governs. There is no
carve-out for them anywhere in §4b, §4c or the architecture record, and
`docs/architecture/findings-and-sessions.md:211` sides with §4b outright: *"Since
Revision 164, every parked note takes a manifest revision."*

§4c is text Revision 164 should have updated and did not. "Touches no tracked
file" was literally true while `docs/` was gitignored; Revision 162 tracked it and
Revision 164 removed the exemption, and this sentence survived both.

**Why this one is high.** It is not an inconsistency a reader notices and routes
around — it is the rule a session meets the first time it parks something, and
both readings are defensible from the instructions. A session that reads §4c parks
a bundle and writes no revision; a session that reads §4b writes one. Both are
obeying the file. The divergence is invisible until someone compares a commit's
manifest entry against its diff and finds tracked files nothing accounts for.

This bundle is itself the first instance: written under §4b, with a revision, and
that choice is defensible only because the architecture record breaks the tie.

### 2 — four of five prompts omit the reading §4d makes mandatory

`.github/copilot-instructions.md:224`:

> Every `prompt.md` names `.github/copilot-instructions.md` as required reading,
> before anything else it asks the session to read. That holds for every session
> regardless of state, scope or assistant; a prompt that omits it is incomplete.

| Session bundle | Where it appears | Conformant |
|---|---|---|
| `restore-apps-outstanding-20260903-000000` | item 1 of the reading order (`prompt.md:25`) | yes |
| `restore-repos-clone-plan-20260902-000000` | item 3 of 6 (`prompt.md:26`) | no |
| `restore-repos-refactor-20260902-000000` | item 4 of 5 (`prompt.md:34`) | no |
| `run-index-design-20260901-000000` | no reading order; buried in a ground-rules bullet (`prompt.md:33`) | no |
| `restore-git-phase-11a-20260901-155433` | cited only as *why the file exists*; `prompt.md:13` sends the reader to `restore-git.md` first | no |

Only the newest complies. The rule's "regardless of state" gives no exemption for
bundles that predate it, and `run-index-design` is still `handoff` — its prompt can
still be handed to a session as written.

### 3 — an index and the manifest it links to disagree

`docs/sessions/INDEX.md:25` shows `[5]` for `restore-repos-refactor-20260902-000000`.
Its `findings-manifest.md:11-16` lists six: `0006 0008 0011 0016 0017 0020`.

§4d:231 says INDEX "carries the count and points here rather than restating the
list … so the two cannot disagree."

### 4 — `docs/INDEX.md` describes a directory it no longer matches

`docs/INDEX.md:16` says `ideas/` is **"Currently empty."** It holds
`docs/ideas/external-findings.md`, added by Revision 164 — the same revision that
left the description behind.

### 5 — every `resolved` bundle is missing `decisions.md`

Ten of ten. `docs/legend.md:23` and §4c:150 both require `decisions.md` from
`in progress`, and `resolving` "begins **only** once the decisions … are made and
finalized in `decisions.md`."

Each `resolutions.md` explains why — the bundles were backfilled from already-closed
`docs/gaps/` notes during the Revision 162 migration and never passed through a
live `in progress`. The reason is sound. Neither the legend nor §4c carves out an
exception for migrated bundles, so read strictly, every `resolved` bundle in the
repository is non-conforming. That is a defect in the rules rather than in the
bundles, and the fix is a sentence, not ten files.

Revision 166 produced the first `decisions.md` written under the live lifecycle,
in `docs/runbook-findings/restore-apps/0001-restore-repos-evidence/`, which
confirms the mechanism works when a bundle is opened normally. It does not touch
the ten backfilled ones, and the missing carve-out is what this finding is about.

### 6 — the two state diagrams disagree

`docs/legend.md:57` draws `handoff ──▶ unclaimed / owned`.
`docs/architecture/findings-and-sessions.md:128` draws `handoff ──▶ owned` only.

Nothing in the tree exercises the difference, and §4d:238 describes the two as
alternative *starting* states rather than a transition — which reads as agreeing
with the architecture record. Latent, but they are the two documents that both
claim to define the same lifecycle.

### 7 — two identifiers recorded as unrecoverable are recoverable

`docs/sessions/restore-repos-refactor-20260902-000000/metadata.md:10` and
`docs/sessions/restore-repos-clone-plan-20260902-000000/metadata.md:10` both record
the session id as **not recoverable**, on the reasoning that the session "left none
in anything it wrote."

It left ten. The `Claude-Session` trailer carries `session_019yzcjm2QneJ5ymVEQDi1bu`
on every commit from `e879a8d` through `a2342d1`:

```
git log --format='%h %s' --grep='019yzcjm2QneJ5ymVEQDi1bu'
```

Both bundles are that session's prompts — the same conversation, two briefs, which
is why neither can be told apart by id alone. `restore-git-phase-11a-20260901-155433`
carries the same "not recoverable" wording and may or may not be the same case; it
predates the trailer convention and was not checked here.

Both instances were corrected in Revision 167, and the session bundle that had
been missing for this session's later work was created then too. The finding
stays `unresolved` because neither correction touches the rule: `metadata.md` may
still assert unrecoverability without naming what was searched, and §4d still has
no state for a session that outlives the brief that started it. That bundle was
given a `prompt.md` on 2026-09-03 at the owner's request, written forward-looking
rather than as a reconstruction — which conforms to the letter of §4d without
closing the gap, since the span it was written after still had no brief.

The general property is worth more than the two instances: **`metadata.md` asserts
unrecoverability without recording what was searched.** A trailer written by the
harness into every commit is not something a session "wrote" in the sense the note
means, which is how a mechanical record went unexamined. Any future
`not recoverable` should name the searches that came back empty, so the next reader
knows whether to try again.

## What it costs to leave

Finding 1 costs the manifest its completeness, quietly and repeatedly, and every
session hits it. Findings 3, 4 and 7 are records that misdescribe the tree — the
specific failure `docs/cross-cutting-findings/0009-dated-artifacts-cite-run-ids-a-rename-breaks/findings.md`
was written about, in the machinery built to prevent it. Finding 2 costs each new
session its ground rules until someone notices. Findings 5 and 6 cost nothing today
and become wrong answers the first time anyone works a bundle through the full
lifecycle.
