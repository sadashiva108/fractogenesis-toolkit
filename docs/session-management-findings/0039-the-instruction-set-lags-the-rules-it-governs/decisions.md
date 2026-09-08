# Decisions — the instruction set lags the rules it governs

**Bundle:** `0039-the-instruction-set-lags-the-rules-it-governs`  
**Session:** `restore-apps-outstanding-20260903-000000`, continued by `session-management-re-evaluation-20260906-110105`

Decisions are recorded per finding as they are made. A finding with no entry here
has not been decided, and no finding is resolved until it has one.
**Ten of the twelve do not yet, so this bundle stays `analyzing`.**

**One decision carries four findings.** D1 answers findings F1, F2 and F6 as well
as 5, because all four are instances of a single question — *where is a rule
allowed to live* — which nothing in the repository had answered. That is `0027`
finding F1's question, and `0027` answered it for facts (*a fact has one home*)
without answering it for rules.

| # | Finding | Decisions |
|---:|---|---|
| F1 | Three rules exist only in `docs/legend.md` | D1 |
| F2 | Rules exist in both files, in different words | D1 |
| F3 | §4b's directory list is wrong | D3 |
| F4 | The architecture record names two findings trees | D3 |
| F5 | Nothing says `docs/legend.md` is normative | D1, D2 |
| F6 | State names and state requirements are in different files | D1 |
| F7 | The vocabulary cannot express decision order | D4 |
| F8 | The rule says where a change is composed, not when it is handed over | — |

---

## Decisions

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | `docs/legend.md` holds VOCABULARY. `.github/copilot-instructions.md` sections 4b–4d hold PROCEDURE. Each points at the other for the kind it does not hold, and the legend is named in §4 as required reading | F1, F2, F5, F6 | 2026-09-04 | `replaced → D13` |
| D2 | the write categories split. The legend keeps three one-line definitions of what a record, toolkit and evidence write IS. §4b takes the gating | F5 | 2026-09-04 | `accepted` |
| D3 | `docs/INDEX.md` owns the enumeration of the `docs/` directories. §4b and `docs/architecture/findings-and-sessions.md` §2 stop listing them and point at it | F3, F4 | 2026-09-04 | `accepted` |
| D4 | a bundle waiting on another's decision says so in prose inside its `Relates to` line, and §4c requires the bundle's INDEX.md Notes cell to say it too. `Decide after:` does not become vocabulary | F7 | 2026-09-04 | `replaced → D5` |
| D5 | ordering between findings is a typed, directed edge — `blocks` or `evidences` — asserted in the bundle whose session states it, validated at both ends, and expiring when either endpoint goes inert | F7 | 2026-09-06 | `accepted` |
| D6 | a hand-over step joins the composition rule in section 6: the session reports what it composed and shows it, and the patch is applied only when the owner asks | F8 | 2026-09-07 | `accepted` |
| D7 | A status moves on a **material change to the record**, never on a reading. `reopened` persists until one occurs: a write to the finding or a contribution moves it to `framing`, an accepted decision to `decided`, an executed resolution to `resolved`, and it may be `withdrawn` from there like any live status | F12 | 2026-09-08 | `accepted` |
| D8 | **Reframing a finding invalidates the decisions under it.** One rule, two visible effects: at `decided` the status rolls back to `framing`; at `framing` there is no status to move, so the effect is confined to the decisions. The rollback is the DEFAULT and a session may decline it in writing, recording in `decisions.md` that the edit was non-material and why. `resolved` and `withdrawn` are frozen and unreachable by it | F12, F10 | 2026-09-08 | `accepted` |
| D9 | A decision's `Outcome` is one of seven — `proposed`, `accepted`, `rejected`, `deferred`, `retracted`, `replaced → DX`, `voided` — and **no word appears in both an Outcome and a status vocabulary**, which a schema check asserts. `refined → DX` and `superseded → DX` collapse into `replaced → DX` | F10, F12 | 2026-09-08 | `accepted` |
| D10 | **Reopening requires a reason** from a nine-value enumeration, an optional note, `reopened_at`, and the commit SHA at reopen time. The reason determines the exit status rather than leaving it to judgement. `reopened.md` is GENERATED from those fields, never hand-written | F12 | 2026-09-08 | `accepted` |
| D11 | **Withdrawing requires a reason**, an optional note and `withdrawn_at`, per finding — a bundle-level withdrawal needs one for every finding in it. A `resolved` finding is reopened first; `withdrawn` reaches every status except `resolved` | F12 | 2026-09-08 | `accepted` |
| D12 | **Supersession carries provenance as typed edges at finding granularity, stored in the new bundle only.** `carried`, `successor`, `split`, `merged` and `dropped`; `new` is derived from the absence of an incoming edge. Coverage and exclusivity gate the `superseded` tag. The new bundle gets no `decisions.md`. A superseded bundle is readable by any session and writable by none | F12 | 2026-09-08 | `accepted` |
| D13 | `docs/legend.md` holds VOCABULARY. **`.github/session-management-instructions.md` holds PROCEDURE** — D1 said §§4b–4d of `copilot-instructions.md`, which commit `1c48deb` deleted. Each points at the other for the kind it does not hold. D2's unfinished half is carried out: the legend keeps three one-line definitions of the write categories and the gating moves to §6 | F1, F2, F5, F6, F13 | 2026-09-08 | `accepted` |

## Findings 1, 2, 5 and 6 — a rule lives where its kind lives

## D1 — `docs/legend.md` holds VOCABULARY. `.github/copilot-instructions.md` sections 4b–4d hold PROCEDURE. Each points at the other for the kind it does not hold, and the legend is named in §4 as required reading

Owner, 2026-09-04.

Vocabulary is what a word means: the six findings statuses, the four session
states, both lifecycle diagrams, `Relates to`, and what each of the three write
categories IS. Procedure is what a session must do: who may write to a bundle at
which status, what happens when one is overtaken, what each state requires, when
each category of write is allowed, where a change is composed, and the owner's
override.

### What this decision does NOT reach

**It governs the findings-and-sessions vocabulary only.** A runbook's own
Terminology section — `capture-office-stability.md` defining *evidence run* and
*assessment run*, and every runbook that carries one — is workflow vocabulary and
stays in the runbook that uses it. Read without this scope, D1 would pull every
defined term in the repository into `docs/legend.md`, which nobody decided and
which would put a phase's terminology two files away from the phase.

The line between the two is what the term is about: `superseded` is about how
this repository tracks work and is the same in any project that adopted this
structure; *assessment run* is about what a Mac's Office installation did and
means nothing outside that phase. The legend is for the first kind.

Recorded because the hole was found by accident. Revision 187 added two runbook
terms to a Terminology section an hour after this decision was made and before
it was written down, and the draft as it then stood would have called that the
wrong file.

### Why a line at all

Findings 1, 2 and 6 look like three defects and are one. Five rules stranded in
the legend, three rules written twice in different prose, and one vocabulary
split across two files are all what happens when **nothing says which file a new
rule belongs in.** Fix them individually and the next rule written lands wherever
its author was editing, which is how all three arose.

`0027` decided that a fact has one home. This extends the same reasoning to
rules, and the extension is not automatic: a fact's home is wherever it is
generated, while a rule's home has to be *chosen*, because a rule is not
generated anywhere.

### Why this line rather than another

The tree drew it before the decision did. §4c's supersession section, written by
another session in Revision 184, opens by pointing at the legend for the case the
legend already owns and then states only the procedure. Nobody instructed that.
It is the shape the material takes when someone writes it carefully, which is the
best evidence available that the line is real rather than imposed.

### What moves

| From the legend to §§4b–4d | Why |
|---|---|
| `## Who may write to a findings bundle` | permission is procedure |
| `## When something overtakes a bundle already in progress` | procedure — and it joins §4c's other supersession case, which is its other half |
| `## The owner's override` | procedure |
| `## Where a write is composed` | procedure, and already duplicated into §3 by Revision 182 |
| the gating half of `## Write categories` | see D2 |

The legend keeps the statuses, the states, both diagrams, `Relates to`, *How the
two meet*, and three one-line definitions of the write categories. It goes from
nine sections to five, and every rule in it today is procedure.

### What each finding gets, specifically

- **1.** The three still-stranded rules — write categories, the contribution
  rule, the owner's override — are all procedure and move. The finding recorded
  five; two have since resolved themselves, `Relates to` by being used in §4c as
  vocabulary correctly, and the overtake rule by §4c referencing it.
- **2.** Each duplicate resolves by kind. *"Decisions do not carry forward by
  themselves"* is procedure and stays in §4c; the legend's copy goes with the
  section it sits in. `resolving`'s gate and the bundle-advance rule are
  procedure and stay in §4c; the legend keeps the status names they refer to.
- **6.** **Closes as correct by design, not as a defect.** State names in the
  legend and state requirements in §4d is exactly what D1 prescribes. The
  finding was right that a reader of either file alone is under-served; the
  answer is the pointer and the required reading, not a merge. This is the one
  finding in the bundle that is withdrawn rather than fixed, and it is recorded
  as decided rather than dropped because deciding it was what showed the line was
  already half-drawn.

### The rejected alternatives

**Fold the legend into the instruction set.** One file, no pointer, nothing to go
stale — the strongest version of *a fact has one home*, and it kills findings F1,
F2, F5 and F6 outright. Rejected because the two files serve different readers: a
session reading rules before working, and a person scanning what `superseded`
means while deciding. `.github/copilot-instructions.md` is already 29KB and the
legend is 263 lines; merging makes the scan-while-working case worse to save a
pointer.

**Name the legend in §4 and change nothing else.** The smallest fix, and it
closes finding F5 honestly — a session told to read it does read it. Rejected
because it leaves findings F1, F2 and F6 open with no rule for the next one:
discoverability is not the same as a home, and the next rule written still lands
wherever its author happened to be.

### The cost

A rule now has to be classified before it is written, and the boundary has one
genuinely ambiguous case, which is why D2 exists. Expect more. The mitigation is
that misclassification is cheap to correct — moving a section is a record write —
where writing a rule in both files is what produced findings F1 and F2.

---

## Finding 5, the ambiguous case

## D2 — the write categories split. The legend keeps three one-line definitions of what a record, toolkit and evidence write IS. §4b takes the gating

Owner, 2026-09-04.

This is the same shape the statuses already have and which finding F6 mistook for
a defect: the name in the legend, the requirements in the instruction set. Making
write categories the one exception would have meant the boundary had a carve-out
on the day it was drawn.

**Rejected: move all three entire.** Cleanest cut, and it has a real argument —
the names only ever come up alongside their gating, so splitting them costs two
lookups for one question. Rejected because it is the same argument for merging
the statuses, which nobody makes.

**Rejected: the legend keeps the section entire and §4b points at it.** Smallest
diff, and it makes the new rule ambiguous the first time it is applied — which is
finding F1's failure mode, on day one.

---

## Findings 3 and 4 — the map has one home

## D3 — `docs/INDEX.md` owns the enumeration of the `docs/` directories. §4b and `docs/architecture/findings-and-sessions.md` §2 stop listing them and point at it

Owner, 2026-09-04.

Three files enumerate the directories. Two are wrong: §4b says six where there
are seven, and the architecture record names two findings trees where there are
three. The third is right, and it is right because it sits beside the table it
counts — `docs/INDEX.md` says *"All seven directories"* directly under a
seven-row table.

The wrong count is a symptom. **The list is the copy**, and §4b has been wrong
after four of the last six revisions that touched `docs/`, because a number in a
sentence has to be maintained by whoever adds a directory and nothing checks it.
This is D1 one level up: §4b is procedure, `docs/INDEX.md` is the map. §4b keeps
its rules — write here rather than widening, one file per item, a fact has one
home — and names no directories.

`docs/INDEX.md` has its own drift to fix in the same change: it says *"the two
findings directories arrived in Revision 160"* and *"under the two directories
above"* when there are three. Becoming the single home means being correct.

**Rejected: fix the numbers and keep all three lists.** Smallest diff, and every
file stays readable alone. Rejected on the record above — this list has been
wrong more often than right, and correcting three copies is what produced the
wrong ones.

**Rejected: keep the lists and add a lint** comparing each against `ls docs/`.
Catches drift instead of preventing it, costs a fifth validator, and `0032` is
concurrently arguing that a passing check is what sessions over-trust. Adding a
check to license a copy, while a sibling bundle documents a check that passed on
a defect it did not examine, would be the wrong lesson learned twice.

---

## Finding 7 — ordering is prose, and the index says so

## D4 — a bundle waiting on another's decision says so in prose inside its `Relates to` line, and §4c requires the bundle's INDEX.md Notes cell to say it too. `Decide after:` does not become vocabulary

Owner, 2026-09-04.

The finding sketched three shapes and preferred the header field. The evidence
since says otherwise. **`Decide after:` appears in exactly one place in the
repository — this bundle's own header, where it was invented to record that the
vocabulary lacked it.** `0031` hit the same need days later and wrote prose
inside `Relates to`: *"this bundle should reach `resolving` first so `0029` reads
§4c as it will then stand."* Two sessions, free to choose, and the one that was
not inventing the notation chose not to use it.

`Relates to` already obliges nobody and carries a sentence. Ordering is a
sentence. What it lacked was not expressiveness but **visibility**: an owner
picking work off an index sees a status, not a header, so the requirement lands
on the Notes cell — which already carries exactly this kind of qualifier
elsewhere, *"1 is high — …"*, *"Finding 3 held open — …"*.

**Rejected: make `Decide after:` real vocabulary**, defined in the legend and
required by §4c. Strongest signal and unambiguous. Rejected because it is a new
field to maintain for a case that has arisen twice, one session did not reach for
it, and under D1 it would have to be split across both files — the term in the
legend, the obligation in §4c — which is a lot of structure for one sentence.

**Rejected: nothing formal; the owner sequences the work.** Honest about where
the knowledge is. Rejected as directly against D1, decided an hour earlier: a
rule that lives only in conversation is the failure this architecture exists to
remove.

### The cost, stated

**Nothing enforces the order.** A session can read *"decide that first"* and
start anyway. That was true of `Decide after:` as well — it obliged nobody
either — so this decision does not lose a guarantee, it declines to invent one.
If ordering is ever violated in a way that costs something, that is a finding, and
it will have evidence this one does not.

## D5 — ordering between findings is a typed, directed edge

`allocation-and-inquiry-design-20260906-233205`, 2026-09-06, recorded against a
`framing` finding as section 4 permits. **This supersedes D4**, whose row and
section stand unchanged above as the record of what was considered.

D4 rejected `Decide after:` as vocabulary and put ordering in prose inside
`Relates to`, with §4c to require the INDEX.md Notes cell to repeat it. It stated
its own cost plainly: **nothing enforces the order.**

`docs/architecture/allocation-and-inquiry.md` makes ordering a typed edge —
`blocks` where a decision must come first, `evidences` where a decision must have
been *carried out* first — carrying `kind`, `from`, `to`, `why`, `basis`,
`asserted_by` and `asserted_on`, checked at both ends the way
`verify-findings-headers.sh` already checks that every cited `F<n>` exists.

### Why D4 gives rather than D5

**D4's stated cost is exactly what an edge fixes.** It did not lose a guarantee,
it declined to invent one, and said a violation that cost something would be a
finding with evidence D4 did not have. That evidence now exists.

**D4 was priced against one sentence, not against ten kinds with four hard
constraints.** Its rejection of real vocabulary read *"a lot of structure for one
sentence"* — correct against what was proposed. The edge model is not one field
for one case; it is the input to an allocator and an interviewer, and ordering is
one of ten things it carries. The cost D4 weighed is not the cost now on offer.

**Half of D4 was never applied and the other half is contradicted by its own
bundle.** `git log -S"Decide after"` is empty across the whole history of all
three instruction files, and the Notes-cell obligation appears in none of them —
§4c ceased to exist when Revision 191 split the set, and the requirement went
with it. Meanwhile this bundle's own header still carries `**Decide after:**` and
a hand-written `**Gate cleared 2026-09-04:**`, recorded as a live instance of
`0043` F4. Nothing unwinds, because nothing was ever wound.

### What this does not decide

Where the edge is stored, and in what format. That belongs to `0043`, and the
answer taken there — an edge lives in the bundle whose session asserted it, so
`asserted_by` is structural rather than a field to be trusted — is not this
decision's to make.

**Rejected: reopen `0029` D4 instead.** `0029` is `superseded` and frozen;
`reopened` corrects a resolution, and this is a reading replaced by a better
mechanism. The row stays, which is the record.

**Rejected: record this against the architecture document alone.** The
architecture record says why a shape is what it is; it is not where a decision
against a finding lives. F7 is the finding, this bundle is where it lives, and a
decision recorded elsewhere leaves F7 answered by a document that does not know
it exists.

## D6 — the hand-over step joins the composition rule in section 6

Owner, 2026-09-07, put by `allocation-and-inquiry-design-20260906-233205` and
answered in one move. **Finding 8 has a decision for the first time.**

Section 6 says where a change is composed and says nothing about when it is
handed over, so *"hand the owner a patch"* followed by *"check the patch before
applying it"* reads as one motion ending in the session applying its own work.
The step now states it: **the session reports what it composed and shows the
content; the patch is applied only when the owner asks for it.**

### Why here rather than in a prompt

F5 is already `accepted` under D1 — a rule lives where its kind lives, and the
instruction set holds procedure. Putting this in a session prompt would make it a
property of a session rather than of the repository, which is the shape F5 exists
to argue against, and two `accepted` decisions in one bundle would then point
opposite ways. It also sits beside the composition rule it completes, which is
the whole of why it is small.

### The cost, stated

An unasked-for apply was never destructive — the owner reviews the diff and can
decline it. What it cost was **review order**: a patch already in the tree is
reviewed as a fait accompli, it sits between the owner and anything else they
wanted in that folder, and declining it becomes an action rather than an
omission. That last property is the one `0028` finding F4 was pleased to have
removed and the same session restored in the same revision.

**Read that citation as `0038` F4.** `0028` was superseded on 2026-09-06 and
authority moved; F8's text was written on 2026-09-04, when the citation was
correct, and it is evidence and is not rewritten. `0046` records that nothing
marks the difference.

### Rejected: a fourth write category

Recorded as rejected rather than dropped. `0028` D4 — read as `0038` D4 —
established one day before F8 was written that composition is not a permission
question, and applying is not one either. Two rules that vary by nothing do not
become clearer as three. **This was rejected on sight in the finding itself**,
and the interviewer offered it as neither a live option nor a silent omission.

### Rejected: state it per session, in the prompt

Where the rule lived until now, minus the conversation. Costs nothing to write
and needs no instruction-set change. Rejected against D1 and F5, above.

### What this decision does not do

**It does not install the rule.** A change to `.github/session-management-instructions.md`
is a toolkit write, gated on a `decided` finding, and F8 is `framing` — any
session may record a decision there, but **closing the deciding is the owning
session's act**. `session-management-re-evaluation-20260906-110105` moves F8 to
`decided`, and the section 6 edit follows in that revision.

That the rule about not applying unasked cannot itself be applied unasked is not
an irony to work around. It is the rule working.

---

## Finding 8 — decided 2026-09-07

Recorded 2026-09-04, one revision after the rule it is about, and left open
deliberately for three days. D6 closes it. Its three shapes are in `findings.md`;
one of them, a fourth write category, was rejected on sight under `0028` D4.

D6 is decided and **not installed**: installing it is a toolkit write, and
closing F8 belongs to the session that owns this bundle.

---

## Finding 12 — the lifecycle names no triggers

Six decisions, taken 2026-09-08 between this session and the owner. They are one
subject seen six ways, and D7 is the one the other five depend on.

---

## D7 — a status moves on a material change to the record, never on a reading

The finding is that `docs/legend.md`'s one labelled arrow reads *"first read by
the owner"*, making reading the trigger. **Reading is the one act that changes
nothing.** A vocabulary whose transitions fire on it cannot tell a sweep from a
glance, and Revision 208 is what that costs: twenty-one rows moved by a session
that believed it had only looked.

**The replacement is a single principle: a status moves when the record changes.**
Assignment does not move a status. A sweep does not. A rename does not. A
retrofit does not. Reading does not.

`reopened` is where this bites hardest, because it is the status most likely to
be flattened by someone tidying: it looks unfinished. Its exits are now events,
not readings:

| Event | Exit |
|---|---|
| the finding is written to, or takes a contribution | `framing` |
| a decision on it is accepted | `decided` |
| its resolution is executed | `resolved` |
| it is shut down | `withdrawn` |

**`reopened → decided` directly, skipping `framing`, is correct and not a skipped
step.** It is the common case: the framing was sound and the *resolution* was
wrong. Forcing it through `framing` would assert the problem statement is being
reworked, which would be false.

### What this does not do

It does not make the transition checkable on its own. A status is still a cell,
and a cell can still be typed over. What makes it checkable is D10's record of
the event — and, past that, `0043`'s move of state out of documents. This
decision is the rule; the enforcement arrives with the data.

---

## D8 — reframing invalidates the decisions under a finding

One rule, not two, because two statements of one rule drift — which is `0037` F1
exactly, and this bundle's own F2.

**At `decided`** the status rolls back to `framing` and every accepted decision
under the finding is `voided`. **At `framing`** there is no status to move, so the
effect is confined to the decisions, which are flagged rather than voided: they
were never accepted, so nothing was relied on.

The ground for it is plain: **if the foundation a ruling was made on changes, the
ruling may no longer apply**, and a decision that silently outlives its premise is
worse than no decision, because it carries authority it has lost.

### The default, and declining it

A mechanical trigger — *any edit to the finding* — over-fires. A typo fix, a
tightened sentence, a corrected citation would each void every decision beneath
it. **A rule that fires on trivia gets routed around, and a routed-around rule
still reads as live**, which is this bundle's whole subject.

So the rollback is the **default**, and a session may **decline it in writing**:
a dated line in `decisions.md` recording that the edit was non-material and why.

That shape is not invented here. `bin/verify-script-portability.sh` runs it
already — a rule fires mechanically, a deliberate exception is declared at the
site with a reason, and the declaration is itself checked, since the script warns
on a pragma that no longer covers anything. Judgement alone cannot be audited;
a recorded judgement can.

### The boundary

`resolved` and `withdrawn` are frozen — `docs/legend.md` line 34 and
`docs/architecture/findings-and-sessions.md` §8. This rule therefore fires at
`framing`, `decided` and `reopened` only. Reframing a `resolved` finding is not
permitted at all: it goes through `reopened` first, and D10 governs that door.

### The reasons, and which of them void

Not every reason voids something. That distinction is the rule's whole precision.

| Reason | Means | Effect on decisions |
|---|---|---|
| `framing-changed` | the problem statement materially changed | **every** accepted decision → `voided` |
| `decision-wrong` | a decision is wrong on the merits; the framing is intact | **that** decision → `voided` |
| `decision-inapplicable` | a decision's target no longer exists | **that** decision → `voided` |
| `decided-prematurely` | it was marked `decided` before every decision was made | none — `decided` was the error |
| `new-information` | something was learned that may change the answer | none yet; decisions flagged to re-evaluate |

`decided-prematurely` will be used. `decided` claims *every decision is made*, and
that is a claim someone makes in a hurry.

### Rejected: a `reframing` status

Proposed by the owner and rejected on the owner's own findings. Three reasons.

**`framing` already covers it.** `docs/legend.md` line 32 defines it as *"Live and
open. The reading, the wording of the problem statement, **and the decisions** are
all still being worked."* A `reframing` status would carve out a subset of
something the definition already contains.

**It is a second activity-named status**, which is `0043` F8 — each vocabulary has
exactly one, and it is the one a name cannot carry. A second doubles that.

**It would mean the finding, or the decision, or both.** One name, three
orthogonal facts, which is `0043` F1 reappearing before the ink is dry — and the
next request would be `re-deciding`. **Names do not scale; a reason field does.**
The index renders `framing (decision-wrong)`, so the distinction is visible
without opening the file, which was the real thing wanted from a separate status.

---

## D9 — the Outcome vocabulary, and no word in two vocabularies

`superseded → DX` was a decision Outcome and `superseded` is a bundle status.
A reader who learns one meaning reads the other wrong. The rule that prevents the
next collision is structural rather than a matter of taste:

> **Statuses are adjectives about a condition** — *where is this?*
> **Outcomes are past-participle verbs about an act** — *what was done to this?*
> **No word appears in both**, and a schema check asserts the enums are disjoint.

| Outcome | Means | Pointer |
|---|---|---|
| `proposed` | on the table; nobody has ruled | — |
| `accepted` | adopted — this is what will be done | — |
| `rejected` | turned down on the merits; nothing replaces it | — |
| `deferred` | cannot be ruled yet; what it waits on is named | required |
| `retracted` | the proposer withdrew it before a ruling | — |
| `replaced → DX` | a later decision answers the same question instead | required |
| `voided` | was `accepted`, then invalidated because its foundation moved | reason required |

Checked disjoint against all three status vocabularies — finding, bundle and
session — at the time of writing.

**`refined → DX` and `superseded → DX` collapse into `replaced → DX`.** The
distinction between them was *same answer better stated* versus *different
answer*, which is a judgement nobody can check, and both tell a reader to go and
read DX. Where the nuance matters it belongs in the decision's prose, not in a
value an index renders.

**`proposed` is stored, not left empty.** `docs/architecture/state-as-data.md`
§4.1 requires closed vocabularies to validate, and a draft config in this
repository already carried `"status": "unresolved"` — a value the vocabulary had
retired three days earlier. An explicit `proposed` makes an unset outcome a load
error rather than a reading.

**`deferred` earns its place from an instance**, not from symmetry: this bundle's
own `findings.md` invented `Decide after:` and `Gate cleared:` labels because
there was no word for a decision that cannot be ruled yet.

**D4 of this bundle is retrofitted** from `superseded → D5` to `replaced → D5` in
the revision that ships this, rather than left as a half-change.

---

## D10 — reopening takes a reason, and the reason decides the exit

`reopened` is the only door out of `resolved`, and until now it took no account
of why it was opened. Nine reasons, in three families named for the layer at
fault:

| Reason | What it says | Exits to |
|---|---|---|
| `resolution-defective` | the work was done and is wrong | `decided` |
| `resolution-incomplete` | the work was done and does not cover the finding | `decided` |
| `resolution-had-side-effects` | it worked, and broke something else | `decided` |
| `resolution-not-applied` | the record says resolved; the tree disagrees | `decided` |
| `resolution-regressed` | it was applied, and a later change removed it | `decided` |
| `resolution-unverifiable` | the claim cannot be checked | `decided` |
| `decision-wrong` | the decision it carried out was wrong | `framing` |
| `decision-inapplicable` | the decision's target no longer exists | `framing` |
| `framing-wrong` | the problem statement was wrong | `framing` |

**The reason determines the exit**, which removes a judgement call at the moment
someone is already annoyed about a bug. A fault in the work leaves the decision
standing, so the finding returns to `decided` and the work is redone. A fault in
the decision or the framing returns it to `framing`.

**Two of these are here because this tree has them.** `0037` F5's carve-out *was*
written — its `findings.md` shows it pre-split, spelled `MIGRATED` — and commit
`1c48deb` dropped it in the instruction-set split. `resolution-regressed` and
`resolution-not-applied` are the commonest way a resolution fails here and had no
name.

**`unable to resolve` was proposed and rejected.** Reopening is reachable only
from `resolved`, so a finding nobody can resolve never arrives at this door. It
stays `decided` or it is `withdrawn`. Admitting the value would invite reopening a
finding that was never resolved, and nothing would catch it.

### What is recorded, and what is generated

Stored: `reopened_at`, `reason`, optional `note`, the finding, decision and
resolution ids, and **the commit SHA at reopen time**.

`reopened.md` is **generated** from those fields, rendering the state as of that
SHA. It is not a snapshot. A snapshot is a second copy of a fact and would drift,
against the rule that a fact is written down once and everywhere else links to it;
the SHA is a reference that cannot. The readable file survives; what goes is
anyone's obligation to maintain it. It is a projection like every other document
in `docs/architecture/state-as-data.md` §6.

### The twenty-one carry no reason, and none is invented

They were swept to `reopened` at Revision 200 with the rest of the tree, before
this rule existed. **The reasons are owed, not lost.** Filling them retroactively
would be inventing a reading nobody performed, which is the failure the retrofit
rule exists to prevent: what must be preserved is data captured at the time.

---

## D11 — withdrawing takes a reason too

Reason, optional note, and `withdrawn_at`, **per finding**. A bundle-level
withdrawal requires one for every finding in it, which keeps bundle `withdrawn`
derived — ladder row 4 — rather than declared, and makes withdrawing a bundle cost
exactly as much thought as the findings in it.

**A `resolved` finding is reopened first.** `docs/legend.md` line 44 already says
`withdrawn` reaches every status except `resolved`; stating it in the procedure is
what stops someone trying it and reading the refusal as a bug.

---

## D12 — supersession carries provenance, at finding granularity

§9 requires the superseded bundle to be left alone and the new one to carry the
reading forward, and says nothing about **which** finding became which. A reader
asking *what happened to F3* has to compare two documents by eye.

**Provenance goes on the new bundle only.** Not a preference — §9's *"three things
it must NOT do"* forbids the alternative: *"the superseded `findings.md` is not
edited … a reading is retained by being left alone, and one that shows a diff was
not retained."* Writing provenance into the predecessor would be the diff that
proves it was not retained. `new` has no home there in any case.

**It is a property of the relationship, not of either bundle**, so it is an edge —
the machinery `0043` D1 already built: typed edges, findings addressed
`<bundle>/F<n>`, and an edge stored in the bundle whose session asserted it, which
is the new one, since its session performs the supersession.

| Edge | Means | Reason enumeration |
|---|---|---|
| `carried` | the finding comes over unchanged | none — nothing changed |
| `successor` | retained, and substantially changed | `restated`, `narrowed`, `widened` |
| `split` | one predecessor finding becomes several | names each target |
| `merged` | several predecessor findings become one | names each source |
| `dropped` | it no longer applies | `already-resolved`, `no-longer-applies`, `absorbed → F<n>`, `out-of-scope`, `owned-elsewhere → <bundle>/F<n>` |

**`new` is derived, never stored.** A finding in the new bundle with no incoming
provenance edge is new by definition. That satisfies
`docs/architecture/state-as-data.md` §4.1 — nothing derivable is stored — and
removes the one value that could be set wrong.

### The gate: coverage and exclusivity

The rule as first drafted was *every finding of the predecessor carries exactly
one disposition edge*, and it broke on the first case anyone would hit. A **split**
gives one predecessor finding several edges; a **merge** gives one successor
several sources. *Exactly one* rejects both, and both are legitimate.

Two clauses instead of one, and both are checkable:

- **Coverage** — every predecessor finding is named by **at least one** disposition
  edge. Zero is the real failure: a finding silently lost, which is what §9 had no
  guard against at all.
- **Exclusivity** — a predecessor finding disposed `dropped` carries **that edge and
  no other**. Dropped-and-also-carried is the contradiction worth catching.

**Both gate the `superseded` tag.** The tag cannot be applied until the accounting
is complete, which makes the spec a precondition rather than a follow-up. Today
§9 step 4 renames the tag with nothing verifying that the new bundle accounts for
anything.

### The new bundle gets no `decisions.md`

§9 **step 8** currently requires the new `decisions.md` to *"re-affirm or explicitly
drop every decision the superseded bundle recorded."* That requirement is
withdrawn.

Supersession usually happens because a reading has drifted too far to work with,
or was resolved and needs a fresh start. **The predecessor's decisions were taken
against the predecessor's framing**, so re-litigating them in the new bundle asks
it to answer the old bundle's questions. The history is preserved where it was
made and nothing is lost, because the predecessor is retained whole — which is
the property §9 spends three prohibitions defending.

The accounting step 8 was protecting has not disappeared; it has moved to the
finding layer, where coverage makes a silent loss impossible. That is the better
layer: findings are what carry forward, decisions are not.

### A superseded bundle is readable by any session and writable by none

`docs/legend.md` line 178 currently puts `superseded` among the statuses where
*"nothing is readable."* That is the opposite of the truth and of the practice:
this session has read superseded bundles repeatedly, and §9 exists to keep them
readable — *"the old bundle stands untouched as the reading it was."* A retained
reading nobody may read is a contradiction.

**Readable by any session. Writable by none, including the session that owns it.**
Terminal, and valuable precisely because it is frozen: the record of why something
changed, and when.

---

## D13 — the split survives, the address does not

D1 was accepted on 2026-09-04 and **has never been applicable.** It named
`.github/copilot-instructions.md` sections 4b–4d as the home for procedure, and
commit `1c48deb` split that file into `session-management-instructions.md` and
`toolkit-instructions.md` before anyone acted on it. What remains at
`copilot-instructions.md` is 51 lines with no §4b, §4c or §4d at all.

**The principle was never in question. Only the address was**, which is why this
replaces D1 rather than rejecting it: `replaced → D13` says read D13 instead, and
D1's reasoning is untouched and still worth reading.

**Procedure lives in `.github/session-management-instructions.md`.** It is where
the procedure already went, it is the file the split created for exactly this,
and it is the half meant to be copied into another project unchanged.

### D2's unfinished half, carried out here

D2 ruled on 2026-09-04 that *"the legend keeps three one-line definitions of what
a record, toolkit and evidence write IS. §4b takes the gating."* The definitions
stayed. **The gating never left**, and §6 of the instruction set currently reads
*"What they mean and when each is allowed is there"* — pointing at the legend for
the gating that D2 assigned to procedure. The two files agree with each other and
both disagree with the decision.

Three sections move or go:

| Section | Where it belongs | Why |
|---|---|---|
| *Write categories* | definitions stay; **gating to §6** | D2, four days late |
| *Where a write is composed* | **§6, which already has it** | Pure procedure, and duplicated verbatim — the legend even says "the categories above answer WHEN; where it is composed is a separate question", which is the file arguing against its own contents |
| *How the two meet* | **§1, The two objects** | Structure, not vocabulary. It describes a pointer between two directories |

### What this does not decide

**Whether the legend is renamed**, which is F13 and is the owner's call: sixty-three
files cite it and `0030` is the bundle about what that costs. The order matters
and is the reason F13 is recorded after this rather than folded into it —
**renaming the file before splitting it would carry the procedure into the new
name**, and a reference document containing procedure is the same defect with a
better title.

**Whether a README and a quick-start exist**, which is F14 and is new surface no
ruling covers.
