# The framework's own state lives in documents rather than in data

**Recorded:** 2026-09-07, from the owner's proposal that a JSON config become the single source of truth for statuses, states and counts.  
**Session:** `session-management-re-evaluation-20260906-110105` (`session_01FhFbEgG4wmrtJqUCcryNVQ`)  
**Severity:** F1 and F3 are high — both have recorded incidents, and F3's are bugs in the checks the framework is trusted by. The rest are structural and cost attention rather than correctness.  
**Felt at:** every `STATUS-` and `STATE-` tag, all five `INDEX.md` files, every `findings-manifest.md` and `metadata.md`, and `bin/verify-findings-counts.sh`, `-structure.sh`, `-headers.sh`  
**Scope:** session management. The fix lands in the bundle and session file shapes, and in the checkers that read them  
**Relates to:** `0041` — its F1 (a required shape nothing enforces) and F4 (a tag rename is a delete plus a create) are two symptoms of F1 and F2 here  
**Relates to:** `0037` — its D4 answered the same question with *display it, and add a check that catches drift*. This bundle asks whether the answer should have been *compute it, and there is nothing to drift*  
**Relates to:** `0036` — its whole subject is a displayed total that moves for reasons unrelated to the change it is quoted against  

**Read:**

- `docs/legend.md`, the ladder and the three vocabularies
- `.github/session-management-instructions.md` sections 3, 5 and 11
- all five `INDEX.md` files and all six `findings-manifest.md`
- `bin/verify-findings-counts.sh`, `bin/verify-findings-structure.sh`, `bin/verify-findings-headers.sh`
- the owner's two draft config files, 2026-09-07

**This bundle is deliberately open.** It is `analyzing` with every finding
`framing`, which the legend opens to any session, because a second architecture
is being designed in parallel and these files bear on it. **Another session
should record here rather than open a near-duplicate beside it.**

## Contributions

| Session | Date | Contribution |
|---|---|---|
| `allocation-and-inquiry-design-20260906-233205` | 2026-09-06 | Read the two draft config files and `schemas.html`; added F6, the draft review below, and a live instance of F4 in `0039`'s own header |
| `typed-bundles-architecture-20260908-204724` | 2026-09-09 | Added F10, from its own handoff: the `ended` lists are populated on no session, and the prose standing in for them misattributed two revisions in this session's own record |

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | A bundle's status is carried in a filename, so every transition is a delete plus a create | `framing` |
| F2 | 88 count and status cells are typed by hand, and a checker exists only to catch them drifting | `framing` |
| F3 | The framework's own data is parsed back out of rendered markdown, and that parser has been wrong twice | `framing` |
| F4 | Structured fields and free-form prose share a file with nothing marking the boundary | `framing` |
| F5 | Authority is assigned to documents, so every consumer must parse prose to read a fact | `resolved` |
| F6 | A header field that is optional **and repeatable** cannot be represented by either draft, and this bundle carries three of them | `resolved` |
| F7 | The derived bundle status has an else branch that asserts nothing, so a derivation bug always lands there | `framing` |
| F8 | Each vocabulary has exactly one activity-named status, and it is the one a name cannot carry | `framing` |
| F9 | An edge kind is defined by a description and a behaviour, and the two can disagree | `framing` |
| F10 | A terminal session's disposal exists only in prose: the `ended` lists went unpopulated on all eleven sessions across 230 revisions, and the prose standing in for them is unchecked | `framing` |

## F1 — the status is in the filename

`STATUS-<status>` and `STATE-<state>` are empty files whose **name** carries a
mutable value. Changing one is therefore an unlink plus a create, never a write.

That is not a theoretical cost. `0041` finding 4 records four instances of a
bundle left carrying two tags at once, because the connected folder refuses
`unlink` and `git apply` downgrades the failure to a warning and exits 0. This
session met it again on 2026-09-06 and had to request delete permission before
seven tag transitions could be applied at all.

**The contrast that shows the shape.** The artifact volume holds
`office-stability/watcher-history/bundle-watch-start.marker` — also zero bytes,
and correct. It is written once and never renamed; its datum is that it exists
and when. **A zero-byte file is a good record of an event and a bad record of a
state**, and the framework uses the same construct for both.

### One slot, three orthogonal facts — recorded 2026-09-07

A bundle carries **one** `STATUS-` file, so it has exactly one place to put a
value. Three unrelated facts compete for it, and `docs/legend.md` says so itself
at line 113: *"`unclaimed` and `transferred` are about **ownership** rather than
progress … `superseded` is declared by the session that replaces the bundle."*

| The value | Actually answers | Already recorded in |
|---|---|---|
| `unclaimed` · `transferred` | who owns this | `findings-manifest.md`, authoritative for ownership, and the index Session column |
| `superseded` | is this reading still authoritative | `supersededBy` and the `Relates to` pointer |
| the other five | how far the reading has been taken | the findings themselves |

**That is why the ladder's rows 1, 1b and 2 sit above the derivation and
short-circuit it.** They are not steps in a classification; they are overrides
that suppress one. *"First row that matches wins"* is doing the work of hiding
that three unrelated questions share a slot.

**The cost is that a property cannot be attached to an ambiguous value.** The
permission table lists `superseded` beside `un-started` under *nothing is
readable* — mixing *nobody has looked yet* with *this reading was replaced*
because they share a field, not because they share a property. And `0032` today
is tagged `superseded` with four rows reading `un-started`: both facts are true,
and the tag can only say one.

**What this is not.** It is not an argument that the two status vocabularies
should merge. They should not, and three things in the ladder show why the
bundle set carries judgements no aggregation gives you: `resolved` requires **at
least one** resolved, which has no finding-level analogue; row 4 sits above row 5
so that a bundle of nothing but withdrawals is `withdrawn` rather than
`resolved`, *"because nothing was carried through"*; and `reopened` **dominates
the inert** only when reopening is the whole of the live work. The two sets also
carry different properties on different questions — *A finding* is keyed on who
may read and record, *What another session may do* is keyed on whether opening
the bundle is worth anything at all, and the allocation architecture adds a
third property set again. **The derivation is a bridge between two vocabularies,
not an identity.**

Split into `progress`, `ownership` and `lineage`, the ladder shrinks from eight
rows to five and stops being an override list. Every word keeps its meaning;
they stop sharing a slot.

## F2 — 88 hand-typed cells

Counted 2026-09-07:

| Where | Rows carrying a typed count or status |
|---|---:|
| `docs/sessions/INDEX.md` | 6 |
| the four findings `INDEX.md` | 42 |
| the six `findings-manifest.md` | 30 |
| `docs/runbook-findings/INDEX.md` rollup | 10 |

Every one is derived from something else — a finding table, a manifest, a tag
file — and every one is entered by hand. `bin/verify-findings-counts.sh` exists
for no other purpose than to notice when one of them stops agreeing with its
source, and `0037` D5 records the sharper failure it cannot catch: a column
headed `Findings` that held a count of *bundles*. A wrong number gets noticed;
a wrong unit gets believed.

## F3 — the data is parsed back out of the rendering

All three session-management checkers read the framework's state by parsing
markdown tables with `awk`, `sed` and `grep` — 22, 23 and 43 lines of it
respectively. Markdown is a display format, and parsing a display format to
recover the data behind it is where the failures have been:

- a greedy match ran past a closing backtick and returned a URL where it meant a
  status, so 34 bundles read as unindexed;
- an escaped pipe inside `[[path\|Label]]` was counted as a cell separator, so a
  legitimate row read as malformed.

Both are recorded in `0041`'s `resolutions.md`, and both were in the half of the
script that reads the tree rather than the half that judges it. **The first run
of that lint reported 36 failures against a tree every other validator passed.**

`0042` finding 4 has the same shape one layer out: a rendering audit whose first
run reported 131 failures, of which 128 were bugs in the audit.

## F4 — no boundary between what is authored and what is derived

A `findings.md` holds a reading, which is prose and must never be generated, and
a Findings table, which is entirely structured. A `metadata.md` holds an Owners
table and two paragraphs of environment reasoning. Nothing in either file marks
which is which.

The consequence today is that a status sweep across Revisions 198–203 reached
into a Finding column and changed **what a reading claims** — `0037` F5's row
read `reopened` against its own heading and against `0027`, and the damage was
indistinguishable from an intended edit. The consequence tomorrow is that
nothing can safely regenerate a region of a document it did not write.

### A live instance, found 2026-09-06

Recorded by `allocation-and-inquiry-design-20260906-233205` while checking a
claim about `0039` D4.

`0039`'s own `findings.md` carries two bolded, colon-terminated labels below its
header block:

```text
**Decide after:** `0027`, then `0028`. Findings 1, 2, 5 and 6 below are four
symptoms of one question `0027` finding F1 owns …
**Gate cleared 2026-09-04:** both are `resolved`. `0027` answered the question …
```

Neither is in the closed vocabulary. Section 11 names *a gate* as its example of
the thing that must go in prose rather than become an invented field, and these
are below the header block, so whether they are prose or fields is **exactly the
boundary this finding says nothing marks**. `verify-findings-headers.sh` reports
0 FAIL over the file, because the boundary it would need in order to judge does
not exist.

Two things make this the sharpest instance available:

- **The bundle carrying the notation is the one whose D4 declined to make it
  vocabulary.** A decision and its own bundle's header disagree, and nothing
  could notice.
- **`Gate cleared 2026-09-04:` is an expiry, hand-written.** A session tracked
  an ordering constraint and then recorded, by hand, that it had lapsed —
  which is the discipline
  `docs/architecture/allocation-and-inquiry.md` section 3.3 requires of an edge.
  The tree reached for the mechanism and the expiry rule independently, in prose,
  in the one bundle that decided not to have either.

## F5 — authority sits on documents, not on data

The rules name documents: `findings-manifest.md` is authoritative for ownership,
the `INDEX.md` row is authoritative for status, `metadata.md` is authoritative
for who and what. Every one of those facts is structured, and every consumer —
a checker, a session, a person — has to parse a document to reach it.

`metadata.md` is the clearest case and it cuts both ways. Its content is
entirely structured bar two paragraphs, which is why it reads as redundant. But
it is **cited by thirteen documents**, including the instruction set,
`docs/legend.md`, the architecture record and two session prompts, so removing
the file is a rename in `0030`'s sense. What can move is the authority, not the
path.

## F7 — the derivation's else branch asserts nothing

`analyzing` is defined as *"any other combination"*. Every other row of the
ladder states a specific condition — *every finding is `un-started`*, *at least
one is `resolved`*, *`reopened` with the rest inert*. `analyzing` states none.

It earns its place: a set can be heterogeneous where a member cannot, so it is
the one word the derivation genuinely has to invent. **But it is the only row a
derivation bug can land in silently.** Get any of the five conditions slightly
wrong and the bundle falls through to `analyzing`, which looks entirely
plausible on an index row and is what a bundle mid-work is expected to read.

**It cannot be verified the way the others can.** Checking `resolved` means
checking the rows really are all inert with at least one resolved — a positive
claim with a witness. Checking `analyzing` means checking that **none** of the
other four matched, which is a negative and has no witness. The only test is to
enumerate the cases that must *not* produce it.

That is a requirement on whatever verifies the derivation, and it is not the
same requirement as the rest: a fixture set of bundles that must each land on a
named row, plus at least one that must land on `analyzing` **for a stated
reason** rather than by falling through.

`analyzing` is also the only name in the set describing an *activity* rather
than a *composition*. **That is F8's subject and is not a defect** — it is
structural, and F8 records why.

## F8 — one activity-named status per vocabulary, and the thing a name cannot carry

**Recorded 2026-09-07**, from the owner's account of designing the vocabulary:
every status was meant to be a composition, and *"nothing seemed to fit that
window where the expanse between `un-started` and `decided` was another
composition gate that sucked the direction onward — it's pure direction in
activity."*

### The pattern, in both vocabularies

Five of the six finding statuses are past participles — `un-started`, `decided`,
`resolved`, `reopened`, `withdrawn`. **`framing` is the only present
participle.** One level up, `un-started`, `resolved`, `reopened` and `withdrawn`
describe what the findings *are*; **`analyzing` is the only one describing what
someone is doing.** Two vocabularies, one activity-named member each.

### Why grammar could not do otherwise

Every other status is defined by **an act that completed**: no act has occurred;
the deciding finished; the resolving finished; the withdrawing finished; the
reopening finished. That is what a past participle *is* — the grammatical form
of a completed act.

**The interval between `un-started` and `decided` is the only one whose defining
feature is that no act has completed.** A past participle cannot name it without
naming a completion that has not happened. The window resisted naming because
the vocabulary is act-completion-shaped and this member is the absence of a
completion.

Every other status is a **position**. That one is a **direction**, and a
direction has no composition to describe, because composition is a property of
where a thing is.

The same cause produces F7's else branch one level up. `analyzing` is *any other
combination*, which is not "the leftovers" but specifically **no uniform
completion has been reached** — the absence, aggregated.

### What follows

**Neither is badly named, and neither should be renamed.** They are the only
members that cannot be named the way the others are, and each vocabulary
produced exactly one. This is a structural fact about the design rather than a
slip, and it is recorded here so that a later reader who counts five past
participles and one gerund does not tidy it. **The earlier argument — not worth
renaming so soon after the rebuild — was the weaker one and expires; this one
does not.**

**The missing information was never going to be in the name.** What is absent is
**duration**: `framing` for an hour and `framing` for three weeks are the same
value because they are the same direction. No noun distinguishes them.

That is the failure `docs/architecture/findings-and-sessions.md` §11.6 names and
does not address — *"the characteristic failure is therefore not a wrong status
but a still one: a bundle `in progress` for three weeks, an `owned` session with
no commits since the day it was claimed, a `handoff` nobody collected."*
Written against a vocabulary since replaced, describing a hole the replacement
still has.

**The instance is in this tree today.** All 38 findings this session owns read
`framing`, because assignment and a first reading moved every one of them there
in a single sitting. The status naming the activity is true of everything, which
is the maximum-entropy case for a field: it discriminates nothing.

**An `updatedAt` per finding closes it without touching the vocabulary** — the
timestamps the owner asked for on 2026-09-07 — because it yields `framing since
<date>`, and therefore staleness, without a scheduled sweep inferring it. It
also tells the allocation architecture where `readiness` cannot come from:
nearly every askable node is `framing`, so the signal is in the duration and the
edges, not the status.

## F9 — an edge kind's description and its behaviour can disagree

**Recorded 2026-09-07**, from using the edge model in
`docs/architecture/allocation-and-inquiry.md` §3.2 rather than reading it. Found
on the first pair either session tried to type.

Each of the ten kinds is defined by **two things at once**: a semantic
description of what the relationship *is*, and a behaviour the allocator and the
interviewer take from it. The table gives both in one row, which reads as one
definition. **On `0036` and `0044` they give different answers.**

| | Says | Because |
|---|---|---|
| The description | **`generalises`** — *A is the rule of which B is an instance* | `0044`'s own header: *"this is what its unverified region actually contains; `0036` is the check that cannot see these, this is the defect it cannot see"* |
| The behaviour | **`constrains`** — *A's answer removes options from B without settling it* | `0044`'s repair proceeds under any of `0036`'s four options; what changes is whether repairing four citations finishes the job or a guard is owed |

`generalises` drives **decision lifting** — ask A once, derive B, present as
confirm-derived. Deciding `0036`'s options derives nothing about `0044`; the
citations get repaired either way. So the description fits and the behaviour does
not, and there is no way to record that both are true.

**A second instance from the same pair**, and it is why this is a definition
problem rather than a judgement call. This session predicted `evidences` before
the run, reasoning *`0044` is evidence for `0036`* — true of the content, and
`0044`'s header says so. But `evidences` is defined as **A's *resolution*
produces the evidence B needs**, and the evidence already existed: Revision 209's
scan of the pruned region produced 10 MISSING and 2 ANCHOR BROKEN. `0044` need
not be resolved for `0036` to be decidable, so the edge holds in neither
direction.

**The kind name is a common English word and the definition is narrower than it.**
That prediction was made with the specification open. The next reader will make
it too.

### Three ways out, none obviously right

- **Let a pair carry two edges of different kinds**, and define how the effects
  compose. The specification does not say whether that is legal, and composition
  rules invented for one instance are a rule nobody needed.
- **Split the kinds** into a semantic pointer and a behavioural one. Doubles the
  vocabulary to fix a case that has arisen once.
- **State that where they disagree the behaviour wins**, and accept that the
  taxonomy under-describes. Cheapest, honest about what the model is for — the
  allocator and the interviewer consume behaviour, not description.

**This session would take the third and record the case**, which is what this
finding is. The fix, whichever is chosen, lands in
`docs/architecture/allocation-and-inquiry.md` §3.2 rather than here — this bundle
records that the defect exists and how it was found, because it was found by the
state format's first real use.

## What it costs to leave

F1 costs a permission prompt and an unlink failure on every status change, and
has produced four recorded instances of a bundle in two states at once. F3 costs
trust in the checks: a lint that reports 36 failures on its first run against a
clean tree teaches a session to discount it. F2, F4 and F5 cost attention —
every count re-typed, every sweep re-read, every fact re-parsed.

None of them is a mistake anybody made. They are one structural choice seen five
ways: **the framework's state is stored in the format it is displayed in.**

## What a fix looks like, sketched rather than decided

The owner's proposal, 2026-09-07: one `metadata.json` per session bundle and one
per findings bundle, holding the structured fields and the table rows; the
markdown becomes a projection generated from it, with the prose regions marked
and never touched.

Four things that proposal has to settle, recorded here so they are argued rather
than assumed:

- **JSON, not YAML.** The portability floor is macOS stock Bash 3.2 with no
  declared dependency. `json` is Python stdlib; `yaml` is not, and adding it
  would be this repository's first runtime dependency.
- **One fact, one file.** A draft of the session config copied `subject`, `kind`
  and finding counts from each bundle it owns — and had already drifted in the
  draft, carrying a stray tab and digit into one subject. A session should hold
  the bundle number and what it owes that bundle, and nothing the bundle owns.
- **The ladder is not bypassed.** Three bundle statuses are *declared* —
  `unclaimed`, `transferred`, `superseded` — and the rest are derived from the
  finding rows. The schema needs a declared field that is normally null, or the
  generator will assert a status the ladder disagrees with.
- **The generator becomes the new single point of failure.** Drift becomes
  impossible; a bug that rewrites forty files at once becomes possible, and
  nothing catches it. A `--check` mode that regenerates into a scratch tree and
  diffs against what is committed is the only honest answer, and it is the same
  verification this session has used on every patch today.

**The full schema belongs in `docs/architecture/`, not here.** A findings bundle
is a reading; the design is a design. It was written on 2026-09-07 as
[`docs/architecture/state-as-data.md`](../../architecture/state-as-data.md),
which answers all nine findings and records what it does not decide.

## F6 — a repeatable field the data cannot hold

`Relates to:` is defined in `.github/session-management-instructions.md` section
11 as **optional and repeatable, one line each**. Both drafts model it as a
single scalar: `findings-metadata-0032.json` carries `"relatesTo": "0031 — …"`,
one string.

**This bundle carries three `Relates to` lines** — `0041`, `0037` and `0036` —
so the draft schema cannot represent the very file it was drafted alongside.
`0035` carries the same shape from the other direction.

The general form of the defect: a projection can always flatten a list into
prose, and prose cannot be widened back into a list without inventing the
boundaries. **Every repeatable field must be an array in the data even where it
renders as one line today**, or the first record needing two is a migration.

`Read:` has the same shape — the instruction set already records that it *was*
prose inside `Recorded:`, "a list flattened into a sentence, which is a list
nobody can scan or add to", and was made a bulleted list for exactly this
reason. Neither draft carries it at all.

## What a second session found in the two drafts

Recorded 2026-09-06 by `allocation-and-inquiry-design-20260906-233205`, against
`sesssion-metadata.json` and `findings-metadata-0032.json` as they stood. **None
of these is a new finding**; each is evidence for one already here, and they are
gathered so the schema work has them in one place.

**F2, and it has already happened in the draft.** `sesssion-metadata.json`
describes `pre-image-capture-conformance-20260903-194532`, whose owner is
`session_01PcgHu9kz9Hm5RatLQuFR8H` — and its `currentOwner` string reads
`session_01FhFbEgG4wmrtJqUCcryNVQ`, which is a different session entirely.
`currentOwner` is derivable from `owners[]` by taking the row whose `until` is
open, and in a sixty-line draft the derived copy is **already wrong**. The
finding predicted this; the draft demonstrates it before the schema exists.

The same file carries `"subject": "A lineage rename is a procedure, not an
operation\t3"` — a stray tab and the finding count welded onto a subject copied
out of an index row.

**F5, on the ladder.** `ownedFindingsBundles` stores a `status` per bundle, but
`docs/legend.md` derives all but three of them from the finding rows. The draft
stores `0035` as `un-started` beside a note reading *"Closed 2026-09-04.
Recorded and resolved in one sitting"*, and `0030` as `analyzing` beside
*"Closed 2026-09-04"*. Both contradict themselves inside one object. **The three
declared statuses — `unclaimed`, `transferred`, `superseded` — are the only ones
that may be stored**, and they need a field of their own that is normally null,
exactly as this bundle's sketch already says.

**Two encodings for one fact.** The session draft writes `"status": "superseded
by 0040"`; the findings draft writes `"status": "superseded"` with
`"supersededBy": "0041"` beside it. The second is right. A status field that
sometimes carries a pointer is the string-parsing problem this bundle exists to
end, moved into the data.

**Presentation leaking into data.** `"model": "configured \`claude-opus-5\`"`
carries markdown backticks; `"until": "—"` uses an em-dash where the answer is
`null`; `releasedTo`, `releasedOn`, `ownedBy`, `revisions` and `completed` use
`""` for the same thing. And `finalContributions` holds one object whose every
value is empty — a phantom row that a generator renders as an empty table row.
**The renderer adds the dash. The data says null.**

**F4, in the findings draft.** `findingsSectionHeaders` is a parallel array to
`findings`, ordered, with nothing binding the two together — the same
correspondence-by-position that `verify-findings-counts.sh` exists to police one
level up. A heading belongs to its finding, as a field on it.

**Retired vocabulary already back.** `contributedTo[0].status` reads
`"unresolved"`, which `docs/legend.md` does not define; the vocabulary it belongs
to was replaced. A closed vocabulary in the schema, validated, is the cheapest
fix available and it is the one thing JSON gives for free that markdown never
did.

**One name, and it is misspelled.** `sesssion-metadata.json`, three `s`.
Worth saying only because the file is the proposal for the thing that ends
hand-typed facts.

**`schemas.html` has drifted from the instruction set.** It shows `findings.md`
as *"two required fields, three optional"* and omits `Session:`, which section 11
now requires; and it shows `**Bundle:** … · **Status:**` on `decisions.md` and
`resolutions.md`, where section 11 says plainly **there is no `Status:` field
here**. It is a mockup of the schema as it was proposed, not as it was adopted.
Whatever the JSON projects to must be generated from the instruction set's
shape, not from that page.

**What the parallel architecture needs from this schema**, stated once so it can
be argued rather than assumed: a finding must be addressable as `<bundle>/F<n>`,
and the relationships between findings must be typed, directed, signed and dated
records rather than a prose line. `docs/architecture/allocation-and-inquiry.md`
section 10 states it in full. It is one array; asking now is cheaper than
migrating later.

<!-- historical: bin/verify-findings-counts.sh -->
<!-- historical: bin/verify-findings-headers.sh -->
<!-- historical: bin/verify-findings-structure.sh -->

## F10 — a terminal session's disposal exists only in prose

**Recorded 2026-09-09** by `typed-bundles-architecture-20260908-204724` as a
contribution, **from writing its own handoff** — the field was found empty
because the owner opened the file and asked.

`docs/architecture/state-as-data.md` §4.2 gives every session an `ended` object
with `on`, `reason`, **`revisions`, `commits` and `disposals`**. Measured on
2026-09-09, and the measurement moved while this finding was being written:

| | |
|---|---:|
| session bundles | 11 |
| with any of the three lists populated, **across all 230 manifest entries** | **0** |
| populated at Revision 264, by `assurance-coverage-20260908-204724` on closing | 1 |
| populated at Revision 266, by this session on handing off | 1 |
| terminal — four `closed`, three `handoff` | 7 |
| of those, carrying `on` | 5 |
| of those five, whose `on` reads `"unknown"` | 2 |
| of the seven, carrying nothing at all | 2 |

**The two that populated it did so one revision apart, on the same day, and
neither did it because the schema said to.** Both did it because the owner opened
a `metadata.json`, saw five empty fields and asked. **Nothing in the schema, the
instruction set or any checker had asked across 230 revisions** — which is the
finding, and the fact that it was answered twice within an hour of being noticed
is the evidence that it was never hard, only invisible.

**The schema shows the fields and never says what an element of `disposals`
looks like.** `"disposals": []` is the whole specification, so the first session
to populate it invents the shape — this one did, at Revision 266, and the shape
it chose is not authority for anything.

**What stands in for the data is prose, and the prose is wrong.** §10a step 4
sends the disposal to `final-summary.md` on closing and to the handoff document
otherwise, and both are narrative. Nothing checks either. **The instance is this
session's own revision list**, written at Revision 261 and corrected at 266: it
claimed **247 and 253**, which belong to `allocation-and-inquiry-design-20260906-233205`
and `assurance-coverage-20260908-204724`, and omitted **249, 250, 262 and 263**,
which are its own. Every one of those commits carries a `Claude-Session` trailer,
and `docs/sessions/INDEX.md` states in terms that the identifier in its Owner
column is there so a row can be taken to `git log --grep=<id>`. **One command
answers it and nothing runs it.**

**Why this is F5's shape and not `0047`'s.** It is not drift between a stored
value and a derived one — nothing derives these fields, so there is nothing for
`stamp` to write or `check` to compare. F5 is *authority* assigned to documents;
this is *history* assigned to documents, and it fails the same way: the fact is
readable only by a human reading a paragraph, so nobody notices when it stops
being true.

### A revision and a commit are not one-to-one, and the trailer only names the commit

**Written into this finding an hour after it was drafted, because the draft was
wrong.** It said `revisions` and `commits` were both derivable from the
`Claude-Session` trailers. **`commits` is. `revisions` is not.**

`APPLY-MANIFEST.md` carries **230 entries** and at least four commits deliver
more than one: `8a1b5eb` carries 248 and 249, `25e8e8d` carries **235, 236 and
237**, `55e753e` carries 226 and 227, `44c5289` carries 224 and 225. **The
trailer names the session that made the commit, not the session that composed
each revision inside it** — and Revision 247 is the case that breaks the mapping
outright: it wrote **six** manifest entries for revisions another session had
already committed with no entry at all.

**Both sessions corrected their revision lists on the same day, from the
trailers, and both produced a wrong statement — in opposite directions.** This
one would have shipped the claim that the trailers settle authorship.
`assurance-coverage-20260908-204724`'s Revision 266 searched the log for a
commit whose subject named Revision 237, found none, and recorded that **237 "is
not a revision that exists"**. It exists: it is in `APPLY-MANIFEST.md`, and it
was delivered inside `25e8e8d`, whose trailer names
`allocation-and-inquiry-design-20260906-233205` — a third session again. **A
revision is a manifest entry; a commit is a delivery vehicle; the two are
many-to-one and nothing states it.**

That correction stands as a record of what the finding said before it was
checked, which is the point of writing findings once and not rewriting them to
match what was later learned.

**The rule this sits inside, and the owner supplied the other half of it.**
`assurance-coverage-20260908-204724` left `declaredState` null on closing and
said why: §4.2 line 153 gives `declaredState` a value **only** for `handoff`,
because that alone is a declaration, while `active`, `closed` and `withdrawn`
follow from what a session owns — so writing `closed` there would be **a second
copy of a derived fact**, which is this bundle's whole subject. Put beside F10
the pair states one rule with two halves: **a derived fact must never be copied,
and a judgement must never be generated.** The `ended` block straddles it, and
takes **three** kinds rather than two:

| Field | Kind | What an instrument may do |
|---|---|---|
| `commits` | **derivable** — the `Claude-Session` trailer names the committing session exactly | derive it, and fail when the stored list disagrees |
| `revisions` | **a claim no single source answers** — many-to-one against commits, and the trailer names the commit | written by hand, and only *partly* checkable: every revision named must exist in `APPLY-MANIFEST.md`, every commit named must carry the trailer |
| `disposals` | **a judgement** — what happened to each bundle and why | nothing. It is written by the session that made the decisions |

**A single instrument treating the block as one kind of thing gets two of the
three wrong whichever kind it picks**, and the middle row is the one that looks
derivable and is not — which is how both attempts at it went wrong on the same
day.

**What this is not.** It is not an argument for generating the block from the
log. `commits` and `revisions` are mechanically checkable and should be checked;
**`disposals` is a judgement** — what happened to each bundle and why it was
disposed of that way — and belongs to the session that made it. A generator would
produce the two that are checkable and silently assert the one that is not.
