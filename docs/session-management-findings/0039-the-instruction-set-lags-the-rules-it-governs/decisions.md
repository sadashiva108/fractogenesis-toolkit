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
| D14 | The four pre-D12 supersession successors get the clean slate D12 requires. `0037`, `0038`, `0040` keep only `findings.md` and `metadata.json`; `0036` loses the cloned `resolutions.md` and keeps its own `decisions.md`. `0041`'s pair is MOVED to `0032` rather than deleted — sole copies, and both headers name `0032` | F12, F15 | 2026-09-08 | `accepted` |
| D15 | A decision row must cite at least one `F<n>`. The checker validates citations that exist and cannot see their absence, so the rule states the positive condition — the same shape as D12's coverage clause | F15 | 2026-09-08 | `accepted` |
| D16 | A `completeness` check joins the verify group: it asserts that no atomic value carries markdown ornament, that a list in a document is a list of the same length in the data, and that every header field the markdown has reaches a non-empty key. Deliberately NOT a second parser — a second reader shares the first's blind spots | F16 | 2026-09-08 | `accepted` |
| D17 | The extractor is **single-use** and refuses to run once any generated-region marker exists in a file a generator writes. Parsing generated markdown back into the data that generated it can only lose, and it would look like a successful run | F16 | 2026-09-08 | `accepted` |
| D18 | Resolving gets a numbered procedure, §9b: carry out the decision, write the `resolutions.md` row naming the decision and the revision, then move the finding to `resolved` — in that order, because the row is the evidence the status asserts. A `decided` finding whose decisions are all carried out and which has no row is a defect a check can name | F17 | 2026-09-08 | `accepted` |
| D19 | **The record covers this repository; the rules governing it live in this repository.** Work a session does in another project is not recorded here — no manifest entry, no finding, no `metadata.md` resource row — and a rule the framework depends on is not left in a file outside it. A fourth write kind, `foreign`, names the case so it is excluded deliberately rather than by omission | F19, F9 | 2026-09-08 | `accepted` |
| D20 | Releasing to `unclaimed` gets §10a, four steps: remove the row from the session's `findings-manifest.md`, set the bundle's index Session cell to `—` and its Status cell to `unclaimed`, decrement the session's counts, and record the disposal in the session. Ownership derives, so there is no status to set | F20 | 2026-09-08 | `accepted` |
| D22 | **The framework gets a front door of its own, under `docs/rules/`**, and `README.md` gains one pointer line to it. `README.md` stays the project's; the framework claims to be reusable as-is, so its entry travels with it | F14 | 2026-09-09 | `accepted` |
| D23 | **The three rule documents stop telling their own history.** History moves to a `Provenance` table at the foot; a live warning, a currency declaration and the evidence for why a rule exists stay — the last compressed to one clause inline with the dated account at home. Home before copies: instruction set, then `conformant-prompt.md`, then `session-management-prompt.md`, one revision each | F14 | 2026-09-09 | `accepted` |
| D21 | The commit message is handed over as **one fenced block tagged `text`** — the fence §11 already requires of every example, for the reason §11 already gives. §7 states it as the other half of the rule it already had: a `git commit` inside the block is something to delete, a message outside one is something to gather, and both cost the owner the same | F23 | 2026-09-09 | `accepted` |
| D24 | **A status moves on a material change to the record, and a read is not one.** `docs/legend.md` lines 69 and 546 stand; line 199's *reading is the transition* goes, and §10's *the transfer ends when the target session reads the bundle* goes with it. A transfer ends on the target session's **first write to the bundle as owner**, which is what five records have said since Revision 248 | F26 | 2026-09-09 | `accepted` |
| D25 | **`dissolved` replaces `withdrawn` as a session state.** A session's terminal shutdown and a member's carry the same idea and may not carry the same word. The member sense stays: it is the more specified and the more embedded. `dissolved` sits beside `closed`, is adjectival like `available` and `active`, and appeared nowhere in the record | F27 | 2026-09-09 | `accepted` |
| D26 | **Readability is a property of the member, never of the bundle's ownership.** `unclaimed` leaves the *nothing is readable* row and gets its own: read as `analyzing`, and **no session may move a member to `decided` or `resolved`**, those being the owner's acts with no owner to perform them | F28 | 2026-09-10 | `accepted` |
| D27 | **A commit message is valid only for the patch it was handed over with.** The revision named in the subject must be among the entries that patch adds; a message whose patch was not applied, was applied after the tree moved, or was renumbered is void. The corollary: the manifest entry ships in the same commit as the work it explains | F29 | 2026-09-10 | `accepted` |
| D28 | **The patch is made with `git diff HEAD`.** `git add -N .` stages a deletion and plain `git diff` then omits it, so a patch that removes a file carries every addition and no removal. `HEAD` is byte-identical on any change set without a deletion, so it is always correct | F30 | 2026-09-10 | `accepted` |
| D29 | **The checkers match the genus prefix, not the letter `F`.** `verify-findings-headers.sh` and `verify-findings-counts.sh` match `[FQT]`, which is `MEMBER_PREFIX`'s own range. The prefix stays per-genus; the checkers stop assuming one genus | F31 | 2026-09-10 | `accepted` |

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

---

## D14 — the clean slate, applied to the bundles that predate the rule

D12 requires a superseding bundle to carry no `decisions.md`. Four bundles predate
it, and **the evidence was a byte comparison rather than an assumption**:

| Bundle | File | Compared against predecessor | Action |
|---|---|---|---|
| `0037` | `decisions.md`, `resolutions.md` | **byte-identical** to `0027`'s, headed `Bundle: 0027` | removed |
| `0038` | `decisions.md`, `resolutions.md` | **byte-identical** to `0028`'s, headed `Bundle: 0028` | removed |
| `0040` | `decisions.md`, `resolutions.md` | **byte-identical** to `0031`'s, headed `Bundle: 0031-…` | removed |
| `0036` | `resolutions.md` | **byte-identical** to `0026`'s, headed `Bundle: 0026-…` | removed |
| `0036` | `decisions.md` | predecessor has **none**; header says `0036` | **retained** — option (iv), Revision 209 |
| `0039` | `decisions.md` | **differs by 497 lines**; header says `0039` | **retained** — D1–D13 |
| `0041` | `decisions.md`, `resolutions.md` | predecessor has **neither**; both headed `Bundle: 0032-…` | **moved to `0032`** |
| `0043` | `decisions.md` | no predecessor at all | **retained** |

**The bundles are retained. Only the borrowed files go.** These four are new
readings of superseded predecessors and the owner opened them deliberately; what
went wrong was not the bundles but files cloned into them before any rule said
not to.

**Why the statuses were never wrong.** All eight removed files named a *different
bundle in their own headers*. Nothing had been decided in `0037`, `0038`, `0040`
or `0041` — those decisions were taken in `0027`, `0028`, `0031` and `0032`,
against those bundles' framing. So `framing` on every finding was **accurate**,
and it was the presence of a `decisions.md` full of accepted rows that made it
look wrong. The status column was telling the truth and the decisions file was
lying.

### `0041` is moved, not deleted, and that distinction is load-bearing

`0032` had only `findings.md`. Its decisions and resolutions were sitting in
`0041`, dated 2026-09-04 — before `0041` existed — and naming `0032` in their own
headers. **Deleting them would have destroyed the only record of what `0032`
decided.** The same operation applied uniformly across all four bundles would
have lost real work in one of them, which is why the comparison came before the
action.

**It writes into a `superseded` bundle**, which `docs/legend.md` now says is
writable by none — a rule installed hours earlier, and this is its first test.
Read narrowly: **placing a file in the bundle its own header names is not a write
to the reading.** It alters no finding, no statement and no conclusion; it
completes a supersession that left two files behind. The rule protects a reading
from revision, not a directory from ever changing. Recorded here rather than
resolved silently, because a rule met on its first day deserves the argument in
writing.

### What the clean slate does NOT remove

The **provenance** — 31 edges across the six successors, in `metadata.json`,
derived by comparing statements. That is the record of what became of each
predecessor finding, and it is what makes removing the borrowed decisions safe:
the relationship is recorded where D12 puts it, so nothing is lost by declining
to restate the predecessor's rulings.

The edges are not yet rendered into `findings.md`. `state-as-data.md` §6.3 has
the generator refreshing marked regions of documents that exist, and it is not
written; until then the edges live in the data only.

---

## D15 — a decision must cite at least one finding

The checker asks whether every citation resolves and cannot ask whether there is
one. Ten decisions cited nothing and passed. **The rule states the positive
condition**, which is the only kind a missing thing can fail.

Deliberately the same shape as D12's coverage clause — *at least one*, because
zero is the failure — so the two read as one idea applied twice rather than two
rules that happen to rhyme.

### No single-finding exemption, and how one got in anyway

The first implementation exempted a bundle with exactly one finding, on the
reasoning that the citation was derivable because only one finding existed. **The
convention it cited had been retired at Revision 219** — a findings table is
required even for a single finding — and the session that wrote the exemption was
the session that had retired the convention four revisions earlier.

The owner's ruling, 2026-09-08: **always a table, always a citation.** `F1` costs
one cell, and it is the link D8's voiding rule follows. An exemption would have
left twenty rows outside a rule written the same morning.

**What it reports.** Thirty rows across `0005`, `0012`, `0013`, `0025`, `0030` and
`0035` — all owned by `run-index-design-20260901-000000` and
`pre-image-capture-conformance-20260903-194532`, none by this session, so they are
flagged and not edited. Ten further rows in `0031` and `0032` are frozen and
exempt by design. `bin/verify-session-findings.sh --help` names the bundles and
deliberately does not name the count.

**Not applied retroactively to the ten.** They are now in `0032` and `0031`,
whose readings are superseded and frozen. The rule governs what is written from
here; repairing a frozen record to satisfy a rule it predates is the retrofit
error, and `0046` records the same conclusion about citations left behind by a
supersession.

---

## D16 — a check for completeness, and why it is not a second parser

Four checkers reported 0 FAIL over 162 contaminated fields, correctly: the data
was well formed. **The obvious fix — parse the markdown again and compare — is
wrong.** A second reader of the same documents shares the first one's blind
spots, and the bug here was a regex that looked right. Two parsers agreeing
proves they were written by the same mind.

What the check asserts instead are **invariants a parser cannot satisfy by
accident**:

- **No atomic value carries markdown ornament.** One line, and it is the line
  that would have caught all 162 instantly.
- **A list in the document is a list of the same length in the data.** A count
  cannot be faked, and this is exactly what the 39 lost `Read:` bullets failed.
- **Every header field the markdown has reaches a non-empty key**, against an
  explicit field map, so a field nobody wired up fails rather than vanishing.
- **Row counts.** A table row that did not become an object is invisible to
  every well-formedness check there is.

**It lives beside the extractor**, in `extract-metadata.py --check`, with a thin
shell wrapper so `bin/verify-session-findings.sh` dispatches it like the other
three. Two copies of the schema's invariants would be the drift this repository
keeps recording.

### The atomic/prose line, found by running it

The first run reported 89 problems, of which **18 were prose fields** — a `notes`
cell reading *"D1 accepted, **D2 rejected** by the owner"*, where the emphasis is
part of the sentence. `state-as-data.md` §4.1 had already been amended that
morning to draw the atomic/prose line; the check had not read its own schema.
An explicit `ATOMIC` set fixed it, and the remaining 71 were real.

---

## D17 — the extractor is single-use, and refuses to prove it

`state-as-data.md` §9 step 1 calls this *"the third generation of the markdown
parser `0043` F3 is about — and the last one ever written."* Step 5 flips
authority: the markdown becomes a projection generated from the JSON.

**Nothing stopped the extractor running after that flip.** Doing so parses
generated markdown back into the data that generated it, and a round trip through
a lossy renderer can only lose — whatever the generator does not emit is dropped
from the source of truth. **It would look like a successful run**, which makes it
worse than any bug the parser has had.

The generated-region markers of §6.2 are the witness. If any exist in a file a
generator writes, extraction is refused; `--force` exists and the manifest entry
must say why.

**Scoped to the files a generator writes**, not to all of `docs/`. The first
version searched everything and refused because `state-as-data.md` documents the
marker inside a fenced example — a guard declining to run on the strength of the
document describing it. Fifth instance of the pattern in F16, and it happened
inside the decision recording the pattern.

---

## D18 — resolving gets a procedure

Every other lifecycle event has numbered steps. This one had a file schema and no
instructions, and seven resolutions went unwritten across five revisions because
nothing prompted them.

**§9b, three steps, in this order:**

1. **Carry out the decision.** A toolkit write, gated on the finding being
   `decided` — §6 unchanged.
2. **Write the `resolutions.md` row**: the finding, the decision that resolves it,
   what was actually done, the revision, the commit. The revision is taken at
   apply time like any other.
3. **Move the finding to `resolved`.**

**The order is the point.** The row is the evidence the status asserts, so writing
it second and moving the status third means a `resolved` finding always has a row
behind it. Reversing them produces a status nobody can check — which is the state
`0037` F5 recorded from the other direction, where every `resolved` bundle was
missing its `decisions.md`.

### What makes it checkable

**A `decided` finding whose decisions are all carried out and which has no
`resolutions.md` row is nameable.** Not fully derivable — whether a toolkit write
happened is a fact about the tree, not about the data — but the *absence of a row
under a decided finding* is exactly the shape D12's coverage clause and D15's
citation rule already have: **the failure worth catching is zero.**

Deliberately not implemented in this revision. Three checks were written today and
**every one failed against a healthy tree on its first run**; a fourth, written in
the same sitting as its own rule, would be the fifth instance of the pattern F16
records. The rule lands first and the check follows in a revision that can measure
it.

### Rejected: making `resolutions.md` required

It would fail every `framing` bundle in the tree, which is most of them. A bundle
with nothing resolved correctly has no resolutions file — the same reasoning that
makes `decisions.md` absent from a bundle that has decided nothing, which is D12.

---

## D19 — the record covers this repository, and the rules live in it

Two sentences, because the boundary fails in both directions and one rule closes
both.

**The record covers this repository.** A session may have several folders
connected and may legitimately work in more than one. Only this repository's work
is recorded here: no manifest entry, no finding, no `resolutions.md` row, no
`metadata.md` resource row for a folder that is not this repository's subject or
its evidence. F19.

**The rules governing it live in this repository.** A rule the framework depends
on is not left in a workspace file outside it. F9 records six that were, and three
more arrived there on the day this was written.

### `foreign` — a fourth write kind, so the case is excluded on purpose

§6 defines record, toolkit and evidence. All three are inside this repository or
its evidence volume, so a write to a fourth place had **no category** — which
reads as *not covered* and behaves as *not thought about*.

| Kind | Where | Gate |
|---|---|---|
| record | `docs/` | ungated |
| toolkit | any other tracked file | a `decided` finding |
| evidence | the artifact volume | the owner, per run |
| **`foreign`** | **any other connected folder** | **the owner asks for it, and it is not recorded here** |

Naming it is the point. An unnamed case is a gap; a named one is a decision. A
`foreign` write is ordinary and often useful — it is simply not this
repository's business, and it takes no revision.

### Connection is availability; scope is subject

The tempting rule — *write only about folders in your Resources table* — is wrong
in both directions. **The artifact volume is not a connected folder and is
squarely in scope.** A folder can be connected for one lookup and be nobody's
business. What settles it is the session bundle's `prompt.md`, which states the
subject; the Resources table says only what was reachable.

### What this does not do

**It does not forbid the work.** A session asked to write in another project does
it. The rule governs the *record*, not the errand.

**It is not checkable.** No validator can know whether a paragraph is about this
repository. `verify-doc-paths.sh` would flag a path outside the tree as MISSING,
which is a partial signal at best and now declarable as `historical` or
`proposed` anyway. This is a rule a session follows, which is the weakest kind —
and the reason it is written down rather than assumed, since the instance that
prompted it was clean by luck.

---

## D20 — releasing to `unclaimed` gets a procedure

`transferred` has five numbered steps and `unclaimed` had none, though the legend
defines the two in one sentence as the ownership pair. §10a closes that.

**Four steps.** There is no fifth for setting the status, because since Revision
222 **ownership is derived** — computed by scanning the session manifests. Removing
the row *is* the release; `unclaimed` follows from it. A pre-222 procedure would
have opened with *set the tag*, and that step no longer exists.

1. **Remove the bundle's row** from the releasing session's `findings-manifest.md`.
2. **The bundle's index row**: Session cell to `—`, Status cell to `` `unclaimed` ``.
3. **Decrement the session's Bundles and Findings** in `docs/sessions/INDEX.md`.
4. **Record the disposal** in the session — `final-summary.md` on closing, the
   handoff document otherwise — naming each bundle and why it was released.

### Why step 4 is not optional

A released bundle leaves no trace in the session that held it: the row is gone
from the manifest, and the index row names nobody. **Without the disposal record,
the reading's history stops at the moment it was released** and a later reader
cannot find out who held it or what state it was left in.

That is the same property §9 protects for supersession by keeping the superseded
bundle listed by the session that held it. Release cannot do that — the point is
that the session no longer owns it — so the disposal record is where the history
goes instead.

### Release versus transfer, which are chosen by whether a taker exists

**Transfer names a target session; release does not.** A bundle handed to a named
session is `transferred` and stays owned. A bundle put back in the queue is
`unclaimed` and is closed to everyone until the owner assigns it. The mistake to
avoid is releasing when a taker is known, which turns a two-party handover into an
owner decision nobody asked for.

### The failure it prevents

The legend at line 409 requires a `closed` session's bundles to be terminal or
released. **Revision 200 found `phase-11b` closed while still holding five**, and
`0008`, `0011`, `0015`, `0016` and `0017` were released after the fact by a session
that had to notice the problem first. A written procedure is what makes that a
step rather than an archaeology.

## D21 — the commit message is one fenced block

**Decided:** 2026-09-09, at the owner's direction, immediately after Revision 239
demonstrated the gap. **Recorded by `typed-bundles-architecture-20260908-204724`,
which does not own this bundle** — permitted while F23 is `framing`, and closing
the deciding stays the owner's act.

§7 gains one paragraph: the message is one fenced block, tagged `text`, and a
message set as prose or split across paragraphs has to be reassembled before it
can be pasted.

**Rejected — leave it to convention.** It *was* convention, it held for every
message before Revision 239, and it failed there without anything noticing. A rule
obeyed by habit and stated only by half is indistinguishable from a rule nobody
wrote, which is this bundle's subject.

**Rejected — state it in `conformant-prompt.md` instead.** The prompt is the copy
and the instruction set is the home, per D19, and adding a rule to the copy is
exactly how the six rules F9 records came to live outside the repository. The copy
is deliberately not extended by this decision.

**Rejected — a check.** There is nothing in the tree to check. The message is
handed over in conversation and never written to a tracked file, so no validator
can see it. The only instrument is the owner, and saying so is the honest
position: it is the same class as `0042`, where the instruction to open the
rendered page exists *because* nothing reads it.

**Not decided here — whether §7's other requirements have the same shape.** The
section names four things the block must not contain and two it must end with.
Whether any of the others is one-sided in the same way is a re-reading of §7 that
this decision does not perform.

### What this decision leaves owed, deliberately

**F23 is `framing` and the work is carried out in the same revision.** That is a
live instance of F18 in this bundle — `accepted` cannot say whether a decision's
work was done — and it is created knowingly rather than stumbled into. No
`resolutions.md` row is owed yet, because §9b's procedure begins at `decided` and
only the owner closes the deciding. **When F23 moves to `decided`, a resolution
row naming D21, Revision 240 and its commit is owed immediately**; forgetting it
is F17 exactly, in the bundle that recorded F17.

## D22 — the front door is the framework's, not the project's

F14 says nothing tells a person who has opened the repository what any of it is
for. **Two of its three parts have been answered since it was written and this
one has not.** Revision 246 installed the router — `.github/copilot-instructions.md`,
73 lines, carrying the six-rank precedence order stated once and nowhere else —
and eleven documents now carry a `Role / Authoritative for / Rank` masthead, so
*which document wins* is answered per file. Revision 249 created `docs/rules/`,
which is the shelf F14 says was missing when six rules went to a workspace file.

**What is still true is F14's first sentence.** `README.md` is 67 lines about
reimaging a Mac, last updated 2026-08-13, and mentions none of this. It is where
a cold reader lands.

**Rejected — extend `README.md` with a framework section.** It is the cheapest
option and it is where the reader already is. It welds two subjects into the one
file the framework is most careful to keep separable: the session management set
says of itself *"deliberately project-agnostic and meant to be reusable as-is."*
A front door written into this project's README does not travel, and the next
project inherits a framework with no entry.

**Rejected — declare the router the front door and close F14.** The router
answers *what governs what*. It does not answer *what is this and where do I
start*, and nobody arrives at it. Recorded as rejected rather than left unsaid,
because it is the option that looks like progress and is not.

**Not decided here**: what the door says. A first line, a diagram, or the three
objects and the loop between them are different documents, and that is the
carrying out.

## D23 — the room behind the door gets shorter

The instruction set was **724 lines when F14 was written and is 951 now** — the
cost F14 measured grew by 227 while the finding sat unanswered. A front door onto
a 951-line reference answers half a question.

Much of that length is the file telling its own history inline. The owner's rule,
taken on `docs/legend.md` at Revision 246 and extended here, cuts four ways rather
than two:

| Passage | Where it goes |
|---|---|
| what this used to be, and why it changed | a `Provenance` table at the foot |
| this is not settled, and here is who is settling it | **stays**, at the point of use |
| what this file is current as of | **stays** — it is a staleness declaration, not history |
| the evidence for why the rule exists | **stays inline, compressed to one clause**; the dated account lives at home |

**The fourth line is the one that matters and it is not reference-versus-prompt.**
The test is *will this reader ever return to this file?* The legend is consulted,
so a pointer to the foot works. A prompt is read once, top to bottom, by a session
with no context; it will never come back, and **a prohibition stripped of its
mechanism is one a session talks itself out of.**

**Rejected — one pass over all three files.** 61 passages of judgement in one
revision, and the two that matter most are the two a session is actually pasted.
Home before copies: the instruction set first, because the prompts are its copies
and trimming a copy before the home is settled is `0039` F9 in reverse.

**Rejected — leave the length alone and only add the door.** It answers F14's
first sentence and not its second, and the second is the one with a number
attached that is still rising.

**This decision carries the fourteen retired read-trigger sites**, which live in
the same three files: the owner ruled that a write and not a read moves a status,
`docs/legend.md:67` and §9a already say so, and fourteen prose sites still say the
opposite. Fixing them in a separate pass over the same paragraphs would be two
edits where one will do.

---

## D24 — a status moves on a material change to the record, and reading is not one

**The owner's ruling, 2026-09-09**, given when this session put the conflict to
them rather than acting on it:

> It was originally a read, but since reads aren't recorded it wasn't very
> effective. What is really required to transfer, along with other directional
> state changes, is for the state to be materially different. You can't get into
> a car, boat, or plane without your location changing… if it's the same, which
> would be the case for read-only, how could there be any force of change — then
> there would be nothing to transfer to.

**So the rule is one rule and it already exists**: line 69 and line 546 stand,
line 199 goes, and §10's sentence goes with it. A transfer ends on the target
session's **first write to the bundle as owner** — which is what the four index
rows and two manifests have said since Revision 248, so the tree needs no repair
and the documents come to it.

**`as owner` is load-bearing and is kept.** A contribution to a transferred
bundle is a write and does not clear the transfer; Revisions 248, 262 and 268
each record a non-owner contributing to `0039` while it stood `transferred`, and
none of them cleared it. That is the distinction F25 is about, and this decision
does not settle F25.

**The generalisation is the owner's and is wider than the transfer**: *other
directional state changes* take a material change too. This decision does not
carry it out — it names it, and the three statuses that awaited a first read
(`un-started`, `reopened`, `transferred`) are where the carrying out lands.

### Rejected — reading clears it, and the records are what get repaired

The reading of §10 as written. It has one real argument: `un-started` and
`reopened` are invisible to every session but the owner, so *the owner has now
seen it* is a genuine change in what the world knows.

It loses on three counts. **Nothing records a read**, so the change it names
leaves no trace and no instrument can confirm it — `0045` F3. **It fires in
bulk**: one reading of a bundle moves every finding awaiting a first read at
once, with no judgement formed about any, which is F12's incident reached by
following the rule instead of breaking it. And **it contradicts two other
statements in its own file**, so adopting it means editing lines 69 and 546 and
the Provenance row that cites F12 — repairing the majority to keep the minority.

### Rejected — leave both and let §10 govern transfers only

That is the state today: line 199 for transfers, lines 69 and 546 for everything
else. It survives only while nobody reads both, and this session read both on its
first morning. A vocabulary file that answers *what moves a status* twice is the
defect F21 is the standing warning about.

### What this decision does not do

**It does not carry itself out.** The edit to `docs/legend.md` and to §10 is a
toolkit write, gated by §6 on the finding being `decided` — which it now is — and
it lands in the same paragraphs `0039` D23 rewrites. So F26 is `decided` and not
resolved: the carrying out is sequenced behind D23 on the owner's ordering, and
§9b's row is owed when it happens.

**F26 goes to `decided` in the sitting that recorded it, and that is deliberate.**
A finding left `framing` under an accepted decision is `0047` F2's shape — four
of them were found in `0053` at Revision 264 — and the deciding here genuinely is
closed: the owner ruled, and what remains is the write.

---

## D25 — the cheap one moves

**`withdrawn` was a member `status` and a session `state`**, which breaks the
rule `docs/legend.md` states before anything else: no value belongs to two sets.
A bare word must say which vocabulary it came from, and this one could not.

**The member sense stays, and the asymmetry is the reason.** It carries a
procedure in §9a, a closed list of nine reasons and a revert requirement; it sits
in `INERT`, in the `retired` row and the `answered` row of the progress ladder,
and in `derivation_table`. Moving it means touching the ladder and every test
over it. **The session sense was one table row and one sentence.** Moving it
touches five files and no logic. **When two words collide, move the cheap one.**

**`dissolved`** sits beside `closed` as the other terminal, is adjectival like
`available` and `active`, and had zero uses in the record. A session is closer to
an institution than a member is, and institutions dissolve.

**Rejected — rename the member sense instead.** It is the more precise word for
what a withdrawn member is, and it is load-bearing in the derivation. Renaming it
means editing the ladder, `INERT`, two rows of the progress table and every test
that reads them, to spare five files.

**Rejected — `disbanded`, `lapsed`, `abandoned`.** `disbanded` is clunkier for no
gain. `lapsed` and `abandoned` both imply **neglect**, where this is a decision
taken deliberately — the same reason `withdrawn` was chosen for a member in the
first place.

**Rejected — leave it and widen the rule.** The rule is what makes a bare value
legible, and it has already paid for itself twice: `standing` answering three
questions produced `transferred` read as `unclaimed`, and `superseded` appearing
in two rows under opposite permissions. An exception costs more than the rename.

**Recorded by `drift-and-the-write-boundary-20260909-053548` as F27 and decided
here**, because `0039` and `docs/legend.md` belong to this session. That is the
`framing` rule working as designed: a session that does not own a bundle recorded
into it, and the owner closed the deciding.

---

## D26 — readability is a property of the member, never of the bundle's ownership

**`unclaimed` says nobody owns this. It does not say nobody may read it.**

The ruling, in one sentence: **an `unclaimed` bundle is read exactly as an
`analyzing` one, and what `unclaimed` withholds is the owner's acts** — closing
the deciding, and resolving — **because there is no owner to perform them.**

So the row `assigned`, `unclaimed`, `retired` → *nothing is readable* loses
`unclaimed`, and `unclaimed` gets its own row:

```text
| `unclaimed` | as `analyzing` — `framing` read and record · `decided` read only ·
|             | `resolved` read only. NO session may move a member to `decided`
|             | or `resolved`: those are the owner's acts and there is no owner
```

**Why this and not the reverse.** The other two values in the old row are
**derived from member status** — every member `un-started`, every member
`withdrawn`. Readability follows from what is inside the bundle. **Ownership is
the one input in that row that says nothing about any member**, so it is the one
that does not belong there. Removing it makes the row mean one thing.

**What it unlocks, stated as a number.** 19 `decided` members become readable and
7 `framing` members become readable **and recordable**, which is what `framing`
already promises everywhere else. The 26 `un-started` members stay closed, because
those are closed by their own status and always were.

**Rejected — leave it, because an unowned bundle should not accumulate work
nobody will finish.** The real risk, and it is not what the cell protects
against. Recording to a `framing` member is open to every session *by design*,
in every other bundle, precisely so that work accumulates where it belongs rather
than beside it. **An unowned bundle is the case where that matters most**, because
there is no owner to notice a near-duplicate opening next door. And the risk is
bounded by what ownership actually gates: nothing can be **closed** without an
owner, so no unowned bundle can quietly declare itself finished.

**Rejected — readable but not recordable.** A half-measure that keeps the 19 and
drops the 7. It splits `framing` into two behaviours depending on a property of
the bundle, which is the defect this decision removes, re-introduced one level
down.

**Rejected — rule that a release must first move live members somewhere.** This
was considered because it fixes the cause rather than the symptom. It fails on
`0001`, released with ten live members and no destination, and it would make
releasing more expensive than closing — which inverts §10a's purpose, since
release exists so a session that must stop can stop.

### What this decision does NOT do

**It does not decide `0047` F1.** That finding is `un-started` and belongs to
`drift-and-the-write-boundary-20260909-053548`. This is the **vocabulary** half —
what `unclaimed` means, in `docs/legend.md`, which is this session's document.
F1 is the **instrument** half: whether `CLOSED-BUNDLE-LIVE-FINDING` should fire
at all, and what a release owes its live members. **This decision is an input to
that one and is recorded as an edge**, `0039/F28 evidences 0047/F1`, not as an
answer to it.

**It does not touch `plan_findings_work.py:614`.** That check exists because of
the rule this decision changes, and its own detail string defers to `0047` F1. A
toolkit write against it is gated on **that** finding being `decided`, by a
session that owns it. **Naming what an instrument should now do is not the same as
doing it**, and the boundary is the point.

## D27 — a message is valid only for the patch it was handed over with

**Accepted.** §7's commit-message subsection gains the rule and one test: **the
revision named in the subject must be among the entries the patch adds.** A
message whose patch was not applied, was applied after the tree moved, or was
renumbered between the offer and the commit is **void**, and the session says so
and offers a new one. The corollary is stated because two of the four instances
are that shape: **the manifest entry ships in the same commit as the work it
explains.**

**Three alternatives are recorded rejected.**

**Build the check first**, which is where this started. Rejected because `0050`
F7 asks for exactly the opposite and gives the reason: a rule invented inside a
checker is a rule nobody agreed, and `0041` D1 and `0050` D2 both refused the same
move. There is a second reason here — the checker would have to distinguish a
legitimate multi-revision commit from a mis-scoped one, and **that discriminator
is the rule**. It cannot be derived from the log.

**Forbid multi-revision commits**, which would make the test trivial. Rejected:
Revision 266 settled that a commit may carry several, four of the nine measured
commits do, and every one of those four is correct. The defect is never the
count.

**Say it in §0 step 6 instead**, beside the apply. Rejected because the failure
is not in applying — it is in a block of text outliving the thing it described,
and §7 is where the message is defined. Step 6 already says the report ends with
*applied at your direction*; what it lacked was a statement that the message is
part of that report and not a detachable artifact.

**What this decision does not do.** It does not arm anything. `0050` F7 owns the
instrument, and its own reading is that the rule had to exist first.

## D28 — the patch is made with `git diff HEAD`

**Accepted.** **§6's recipe block** changes `git diff` to `git diff HEAD`, and §6 gains the
measurement and the mechanism. **§0 step 3 is not touched here**: the write-boundary
session wrote the same rule into it independently and §0 is theirs. The conformant
prompt carries the short form.

**Why one word and not a check.** `HEAD` produces byte-identical output on any
change set with no deletion, so it is free and cannot regress anything. **A
check would have to be written against a rule that did not exist** — which is
`0041` D1's and `0050` D2's refusal, and the reason `0041` F7 was handed here
rather than built there.

**Two rejections.** **Drop `git add -N .` and use `git diff HEAD` alone** —
rejected: `HEAD` compares against the commit, so an untracked file is still
invisible to it. **Both steps are needed**, and that is worth stating because the
two look redundant. **Warn when a change set contains a deletion** — rejected as
a guard on a hazard the one-word fix removes entirely, and §6 requires a guard be
shown to fire on a case it should catch, which this one would never see again.

**What this does not decide.** Whether anything should verify a patch's file list
against the session's change set mechanically. That is `0041` F7's and `0049`
F8's, and both are `framing` in bundles this session does not own.

## D29 — the checkers match the genus prefix, not the letter `F`

**Accepted.** Five sites across two files change `F` to `[FQT]`, which is exactly
the range `MEMBER_PREFIX` already defines. **The schema is not changed** — it was
right; the checkers had simply never been told about it.

**Gated correctly.** This is a toolkit write and section 6 requires a `decided`
member. F31 is that member, decided here, in the bundle whose subject it is.
`0056`'s Q3 records the same collision from the commission's side and **is
deliberately not decided**: `0056` is `unclaimed`, and Revision 287's D26 says no
session may move a member of an unowned bundle to `decided`.

**Two rejections.** **Write `0056`'s members as `F1`–`F3` and move on** —
rejected: it passes two checkers by violating the schema the third enforces, and
it would put the first commission in the tree on record as mislabelling its own
members, which is the defect rather than a workaround for it. **Widen the match to
`[A-Z]`** — rejected: `MEMBER_PREFIX` is a closed set of three letters and a
checker matching more than the schema allows would accept an id the schema
forbids, which is `0038` F7's shape — an enumeration that drifts from the thing it
enumerates. `[FQT]` is copied from the map and is wrong the moment the map
changes, **which is the correct failure**: a fifth genus should break the checkers
loudly rather than be silently uncounted.

**What this does not do.** It does not settle whether a commission's table should
be headed `Findings` or `Questions`, or whether its column should read `Finding`.
That is `0056` Q3's, and it is a vocabulary question for the bundle that owns it.
This decision only makes the checkers see what is there.
