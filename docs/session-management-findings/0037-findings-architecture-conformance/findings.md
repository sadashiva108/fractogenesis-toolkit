# The findings-and-sessions architecture disagrees with itself and with the tree

**Recorded:** 2026-09-03, on the owner's request to review the new architecture.  
**Session:** `session_019yzcjm2QneJ5ymVEQDi1bu`  
**Severity:** one finding is high and governs a rule every future session hits on its first parked note. The rest are small and mechanical.  
**Scope:** cross-cutting. The fix lands in `.github/copilot-instructions.md`, `docs/INDEX.md`, `docs/sessions/INDEX.md`, `docs/legend.md` and four `prompt.md` files — no single runbook owns any of it.  
**Relates to:** [`0027`](../../cross-cutting-findings/0027-findings-architecture-conformance/) — **supersedes it.** The original is retained at `docs/cross-cutting-findings/0027-findings-architecture-conformance/`, still listed by the session that held it, its reading unchanged and its files brought onto the schema in Revision 203. Authority for this reading lives here.

**Read:**

- `docs/architecture/findings-and-sessions.md`
- §§4b–4d, in `.github/copilot-instructions.md`
- `docs/legend.md`
- every bundle and index in `docs/`

## What is conformant

Stated first because the defects below are small against it, and a reader
arriving at this bundle should not mistake the list for a verdict on the design.

- All six directories named in §4b exist and none is empty.
- 26 bundles numbered `0001`–`0026`, four-digit, zero-padded, unique across both
  findings directories, no gaps and no duplicates — one sequence, as specified.
- All 26 `STATUS-<status>` tags agree with their scope's `INDEX.md` row.
- All 5 `STATE-<state>` tags agree with `docs/sessions/INDEX.md`.
- The two-way pointer between a bundle's INDEX row and a session's
  `findings-manifest.md` holds in both directions, except for finding F3 below.
  The four unclaimed bundles correctly show `—` and appear in no manifest.
- `docs/gaps/` is fully retired. No directory, no live citation, and no note
  existing in both the old and new location.
- Every path cited in §§1–6 resolves, including the two bundles cited by name.

**Read again against the tree, 2026-09-09, by `typed-bundles-architecture-20260908-204724`.** All
seven were decided and resolved in `0027` at commit `88aed77`. Revision 224
removed the cloned `decisions.md` and `resolutions.md` from this bundle because
they were byte-identical to `0027`'s and headed with its name — the clean slate
`0039` D12 requires — which is why these rows read `framing` over work that had
been done. **`1c48deb` then split `.github/copilot-instructions.md` and dropped
the rules five of those resolutions had installed.** Five hold again against the
files that replaced it and are resolved under D3; F2 and F5 do not, are `decided`
under D1 and D2, and their carrying out is its own revision. **Nothing detected
the regression** — `0052` F1.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | §4b and §4c contradict each other on whether a findings bundle takes a manifest revision | `resolved` |
| F2 | Four of five `prompt.md` files violate §4d's "always" rule | `resolved` |
| F3 | `docs/sessions/INDEX.md` miscounts a manifest it links to | `resolved` |
| F4 | `docs/INDEX.md` says `ideas/` is empty; it is not | `resolved` |
| F5 | Every `resolved` bundle is missing `decisions.md` | `resolved` |
| F6 | The two session-state diagrams disagree | `resolved` |
| F7 | Two session identifiers recorded as unrecoverable are recoverable | `resolved` |
| F8 | Nothing says a finding may record **a fact established** and not only a defect, and two definitions of the object put *what it costs to leave* inside it rather than in `Severity:` | `framing` |
| F9 | Three architecture records describe machinery that does not match the code, and the currency watch aimed at exactly that pair has never been armed | `framing` |

**F8 was recorded 2026-09-09 by `entity-model-and-vocabulary-20260909-053548`,
and it takes this bundle out of `answered`.** Seven of seven stood `resolved` at
Revision 256 and the bundle derived `answered`; one live finding makes it
`analyzing` again. **That is the derivation working, not a regression** — a
reading is not closed by its bundle's arithmetic, and the arithmetic is all
`answered` reports. The transfer at Revision 261 named this reading as owed and
did not take it.

**The header is not rewritten.** `Recorded:`, `Session:` and `Severity:` describe
the reading of 2026-09-03 and are evidence of it. F8's severity is **low** and is
stated in its own section; nothing above was overlooked.

### F1 — §4b and §4c contradict each other, eighteen lines apart

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

### F2 — four of five prompts omit the reading §4d makes mandatory

`.github/copilot-instructions.md:224`:

> Every `prompt.md` names `.github/copilot-instructions.md` as required reading,
> before anything else it asks the session to read. That holds for every session
> regardless of state, scope or assistant; a prompt that omits it is incomplete.

| Session bundle | Where it appears | Conformant |
|---|---|---|
| `restore-apps-outstanding-20260903-000000` | item 1 of the reading order (`prompt.md:25`) | yes |
| `restore-repos-clone-plan-20260902-000000` (absorbed; now `docs/sessions/phase-11b-hydrate-and-bookends-20260903-141500/prompt-restore-repos-clone-plan.md`) | item 3 of 6 (line 26) | no |
| `restore-repos-refactor-20260902-000000` (absorbed; now `docs/sessions/phase-11b-hydrate-and-bookends-20260903-141500/prompt-restore-repos-refactor.md`) | item 4 of 5 (line 34) | no |
| `run-index-design-20260901-000000` | no reading order; buried in a ground-rules bullet (`prompt.md:33`) | no |
| `restore-git-phase-11a-20260901-155433` | cited only as *why the file exists*; `prompt.md:13` sends the reader to `restore-git.md` first | no |

Only the newest complies. The rule's "regardless of state" gives no exemption for
bundles that predate it, and `run-index-design` is still `handoff` — its prompt can
still be handed to a session as written.

### F3 — an index and the manifest it links to disagree

`docs/sessions/INDEX.md:25` shows `[5]` for `restore-repos-refactor-20260902-000000`.
Its `findings-manifest.md:11-16` lists six: `0006 0008 0011 0016 0017 0020`.

§4d:231 says INDEX "carries the count and points here rather than restating the
list … so the two cannot disagree."

### F4 — `docs/INDEX.md` describes a directory it no longer matches

`docs/INDEX.md:16` says `ideas/` is **"Currently empty."** It holds
`docs/ideas/external-findings.md`, added by Revision 164 — the same revision that
left the description behind.

### F5 — every `resolved` bundle is missing `decisions.md`

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

#### What became of D6, recorded 2026-09-06

**The row said the wrong word until 2026-09-06.** It read *"Every `reopened`
bundle is missing `decisions.md`"*, against a section heading two lines below
that said `resolved` — and against `0027`, which says `resolved`. A status-word
sweep during Revisions 198–203 reached into the Finding column and changed what
the reading claims. Restoring `resolved` returns the row to the original wording
and to its own heading; it is a repair of sweep damage, not an edit to the
reading, and it is recorded here because the two are indistinguishable in a diff.


**The carve-out landed and was then deleted.** `resolutions.md` records F5 as
closed by *"the migrated-bundle carve-out in §4c"*, and it was there: pre-split
`.github/copilot-instructions.md`, section 4c, in the `decisions.md` line of the
bundle-layout block —

```text
A bundle MIGRATED from an already-closed record carries `resolutions.md` and no
`decisions.md`, because the deciding happened before this lifecycle existed; its
`resolutions.md` says so.
```

Commit `1c48deb`, which split that file into
`.github/session-management-instructions.md` and
`.github/toolkit-instructions.md`, did not carry it across. It is in neither
file, nor in `docs/legend.md`, nor in `docs/INDEX.md`.

**This corrects a claim made earlier in this session.** A `git log -S"migrated"`
search returned nothing and was read as *the carve-out was never written*. The
search was case-sensitive and the file spelled it `MIGRATED`. The resolution was
not false; **the split lost it**, which is a different defect with a different
fix — restore the sentence rather than take the decision again.

It is one of fifteen rules the split dropped with no decision recording the
removal. The full list belongs to `0039`, whose subject is exactly this.

### F6 — the two state diagrams disagree

`docs/legend.md:57` draws `handoff ──▶ unclaimed / owned`.
`docs/architecture/findings-and-sessions.md:128` draws `handoff ──▶ owned` only.

Nothing in the tree exercises the difference, and §4d:238 describes the two as
alternative *starting* states rather than a transition — which reads as agreeing
with the architecture record. Latent, but they are the two documents that both
claim to define the same lifecycle.

### F7 — two identifiers recorded as unrecoverable are recoverable

`docs/sessions/phase-11b-hydrate-and-bookends-20260903-141500/metadata-restore-repos-refactor.md:10` and
`docs/sessions/phase-11b-hydrate-and-bookends-20260903-141500/metadata-restore-repos-clone-plan.md:10` both record
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

### F8 — a finding may record a fact established, and two definitions say otherwise

**Severity: low.** Nothing is broken today. What it costs is a genus: it has
already sent research to the wrong one once, and the record of that is in the
tree.

`docs/legend.md` defines the object and leaves the conclusion open — *"A findings
bundle is a reading of something that already exists"* — and never says what such
a reading may conclude. **Two restatements of that definition close it**, and the
header schema closes it a third time by requiring the cost:

| Where | What it says |
|---|---|
| `.github/session-management-instructions.md` §1 | a reading of something that already exists: *"what was found, where it is felt, what it costs to leave"* |
| `docs/architecture/findings-and-sessions.md` §2 | *"what was found in something that already exists, where it is felt, what it costs to leave"* |
| `.github/session-management-instructions.md` §11 | `Severity:` is required of every header, glossed *"what it costs to leave, and which finding is the high one"* |

**`what it costs to leave` is severity's business, and in two of the three it is
part of what the object is.** A reading whose answer is *and it is sound* has no
cost to leave, so a required field has to be filled with something invented —
which is the placeholder rule broken by the schema that states it.

**Two of the three are also copies.** §1 restates a definition inside a file
whose own opening says *"Nothing here restates a definition"*, and
`findings-and-sessions.md` restates it again. Which of the three keeps the
sentence is the deciding rather than the reading; `0039` D3 has already removed
one copy from that record for the same reason.

#### This bundle is the live instance

Its own **What is conformant** section records seven established facts about the
tree — six directories present, 26 bundles with no gaps or duplicates, 54 tags
agreeing with their rows, the two-way pointer holding in both directions — and
**not one of them is a finding.** They sit in prose above the Findings table
because no row shape fits a reading whose answer is *yes*, and the section opens
by apologising for itself: *"stated first because the defects below are small
against it."*

#### The cost has been paid once already, in the genus

`docs/architecture/typed-bundles-and-work.md` §4.3 records that the first draft
of that record narrowed the legend to *a reading of something that already exists
**and is wrong***, which pushed research out of `findings` and into `commission`
— a reading of what exists filed as an intent to build. The draft names the
remedy and refuses to apply it there: *"That is a change to a rule and is owed a
finding, not a quiet edit here."* **This is that finding.**

#### What the fix is, and what it is not

A sentence in `docs/legend.md` saying a finding may record a fact established as
well as a defect found, and *what it costs to leave* moved out of the two
definitions into `Severity:`, where it already lives.

**Not** a new status, not a new field, not a subtype. A finding that establishes
a fact is `framing`, `decided` and `resolved` like any other and its bundle
terminates at `answered` with the rest; the difference is what the sentence says,
which is content. The admission rule in `typed-bundles-and-work.md` §4.3 disposes
of the alternative directly — a new shape must name a field no existing shape has
— and this names none.

**It is owed to `0039` D23.** That decision moves the history of all three rule
documents into a `Provenance` table, and two of the three sentences above sit in
documents it rewrites, so the wording F8 settles is what D23 then carries. That
is why the owner's ordering parks D23 behind this bundle. Recorded as
`0037/F8 constrains 0039/F14`; the parking is the owner's direction and is not
derived from that edge.

### F9 — three architecture records describe machinery that does not match the code

**This bundle's subject is a record disagreeing with itself and with the tree.**
F1 through F7 were about the instruction set and the indexes. **The same failure
is in the architecture records** — and the instrument that would have caught it
**exists, points the right way, and has never been armed.**

`.internal/ai-scripts/session-management/doc-currency.json` carries a watch named
`allocation-tooling`. Its sources are `plan_findings_work.py` and
`bin/plan-findings-work.sh`; its dependents are
`docs/architecture/allocation-and-inquiry.md` and
`docs/ledgers/allocation-evidence.md`; and its stated reason is:

```text
"why": "The allocator and interviewer. Their architecture record describes
        what the code does."
```

**That is this finding, written in advance, by someone who saw it coming.** All
seven watches carry `"sourceDigest": null`, and `doc_currency.py:evaluate()`
tests the null before it compares, so every watch reports `UNCONFIRMED` and
`DRIFTED` is unreachable — `0039` F22.

**So the correct reading is not that nothing watches.** It is that **the drift
below is drift the framework predicted, aimed an instrument at, and could not
report** — which is worse, and is a different finding from one nobody anticipated.
An earlier draft of this section claimed no architecture record was watched at
all; that was checked against the file and was wrong, and the correction is
recorded rather than quietly made because it changes what the finding says.

Measured 2026-09-09 and re-verified 2026-09-10 against `plan_findings_work.py`,
which Revisions 276 to 278 did not change.

**`allocation-and-inquiry.md` against the allocator.** §4.2 lists a `− w_hold`
term in the objective; `score()` has six weights and **no hold term** — held-back
findings are printed and never scored. §4.1 constraint 2 requires
`co-decides`/`contradicts`/`duplicates` dossiers to go to one session; **no code
enforces it**, and the default run split `co-decides 0042/F1 → 0041/F1` across
two sessions. §3.2 names four hard kinds and the code has five. §9's
topological-order invariant and §4.4's patch emission are **not implemented**.
`blast_radius` is defined as document-and-script reach and implemented as a JSON
substring count.

**The same record against the interviewer.** Of the six stages the design names,
**only two exist**: `frontier()` and `rank()`. **Precedent, Lifting, Mode and
Propagate have no code at all.** `rank()` consults **no edge**, though the design
defines its gain through `constrains` and `generalises`. And **`ask` ignores every
flag it accepts** — four invocations with `--only`, `--capacity` and `--only-kind`
produced byte-identical output, md5 `fc1ec40ddaa9`.

**`state-as-data.md` against the data.** Eleven statements in §4 have drifted from
the records they specify, and §4.3's example still showed `findings[]` until
Revision 271 moved it.

**Why one finding and not twenty.** Each instance is a symptom; **the reading is
that an architecture record is written once and then diverges with nothing
watching.** Opening twenty findings would file the symptoms and lose the shape.
The instances are listed so the reading can be checked, not so they can be fixed
one at a time.

**What it costs to leave.** These records are cited as specifications — this
session read all three as though they described the code, and had to re-derive the
code's actual behaviour to write `prism.md` and `lumen.md`. **A record that is
trusted and wrong costs more than one nobody reads.**

**And the remedy is one field, not a project.** Arming `allocation-tooling` is
writing a digest into a JSON file. The watch, its sources, its dependents and its
reason are already correct. **What is missing is the act of confirming it once**,
and nothing in any procedure says whose job that is or when it happens — which is
the gap `0039` F22 names and this finding is the first measured cost of.

**Relates to `0039` F22** — the unarmed watch — and to `0043` F11, which is the
same divergence at field granularity.

## What it costs to leave

Finding 1 costs the manifest its completeness, quietly and repeatedly, and every
session hits it. Findings 3, 4 and 7 are records that misdescribe the tree — the
specific failure `docs/cross-cutting-findings/0009-dated-artifacts-cite-run-ids-a-rename-breaks/findings.md`
was written about, in the machinery built to prevent it. Finding 2 costs each new
session its ground rules until someone notices. Findings 5 and 6 cost nothing today
and become wrong answers the first time anyone works a bundle through the full
lifecycle.

**Finding 8 costs nothing today and has already cost once.** The genus draft
narrowed the definition to *and is wrong* and filed research under `commission`
before anything caught it; the correction is in that record and the rule it
corrects is still unwritten.
