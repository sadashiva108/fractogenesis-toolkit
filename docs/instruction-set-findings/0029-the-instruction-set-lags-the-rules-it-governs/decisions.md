# Decisions — the instruction set lags the rules it governs

**Findings bundle:** `0029` · **Status when opened:** `in progress`, 2026-09-04.
**Owner:** `restore-apps-outstanding-20260903-000000`.

Decisions are recorded per finding as they are made. A finding with no entry here
has not been decided, and `resolving` cannot begin until all eight have one.
**Finding 8 does not yet, so this bundle stays `in progress`.**

**One decision carries four findings.** 5.1 answers findings 1, 2 and 6 as well
as 5, because all four are instances of a single question — *where is a rule
allowed to live* — which nothing in the repository had answered. That is `0027`
finding 1's question, and `0027` answered it for facts (*a fact has one home*)
without answering it for rules.

| # | Finding | Decided |
|---:|---|---|
| 1 | Three rules exist only in `docs/legend.md` | **yes** — 5.1 |
| 2 | Rules exist in both files, in different words | **yes** — 5.1 |
| 3 | §4b's directory list is wrong | **yes** — 3.1 |
| 4 | The architecture record names two findings trees | **yes** — 3.1 |
| 5 | Nothing says `docs/legend.md` is normative | **yes** — 5.1, 5.2 |
| 6 | State names and state requirements are in different files | **yes** — 5.1 |
| 7 | The vocabulary cannot express decision order | **yes** — 7.1 |
| 8 | The rule says where a change is composed, not when it is handed over | **no** |

---

## Findings 1, 2, 5 and 6 — a rule lives where its kind lives

**Decision 5.1 — `docs/legend.md` holds VOCABULARY. `.github/copilot-instructions.md`
sections 4b–4d hold PROCEDURE. Each points at the other for the kind it does not
hold, and the legend is named in §4 as required reading.** Owner, 2026-09-04.

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
stays in the runbook that uses it. Read without this scope, 5.1 would pull every
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
| the gating half of `## Write categories` | see 5.2 |

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
  legend and state requirements in §4d is exactly what 5.1 prescribes. The
  finding was right that a reader of either file alone is under-served; the
  answer is the pointer and the required reading, not a merge. This is the one
  finding in the bundle that is withdrawn rather than fixed, and it is recorded
  as decided rather than dropped because deciding it was what showed the line was
  already half-drawn.

### The rejected alternatives

**Fold the legend into the instruction set.** One file, no pointer, nothing to go
stale — the strongest version of *a fact has one home*, and it kills findings 1,
2, 5 and 6 outright. Rejected because the two files serve different readers: a
session reading rules before working, and a person scanning what `superseded`
means while deciding. `.github/copilot-instructions.md` is already 29KB and the
legend is 263 lines; merging makes the scan-while-working case worse to save a
pointer.

**Name the legend in §4 and change nothing else.** The smallest fix, and it
closes finding 5 honestly — a session told to read it does read it. Rejected
because it leaves findings 1, 2 and 6 open with no rule for the next one:
discoverability is not the same as a home, and the next rule written still lands
wherever its author happened to be.

### The cost

A rule now has to be classified before it is written, and the boundary has one
genuinely ambiguous case, which is why 5.2 exists. Expect more. The mitigation is
that misclassification is cheap to correct — moving a section is a record write —
where writing a rule in both files is what produced findings 1 and 2.

---

## Finding 5, the ambiguous case

**Decision 5.2 — the write categories split. The legend keeps three one-line
definitions of what a record, toolkit and evidence write IS. §4b takes the
gating.** Owner, 2026-09-04.

This is the same shape the statuses already have and which finding 6 mistook for
a defect: the name in the legend, the requirements in the instruction set. Making
write categories the one exception would have meant the boundary had a carve-out
on the day it was drawn.

**Rejected: move all three entire.** Cleanest cut, and it has a real argument —
the names only ever come up alongside their gating, so splitting them costs two
lookups for one question. Rejected because it is the same argument for merging
the statuses, which nobody makes.

**Rejected: the legend keeps the section entire and §4b points at it.** Smallest
diff, and it makes the new rule ambiguous the first time it is applied — which is
finding 1's failure mode, on day one.

---

## Findings 3 and 4 — the map has one home

**Decision 3.1 — `docs/INDEX.md` owns the enumeration of the `docs/`
directories. §4b and `docs/architecture/findings-and-sessions.md` §2 stop
listing them and point at it.** Owner, 2026-09-04.

Three files enumerate the directories. Two are wrong: §4b says six where there
are seven, and the architecture record names two findings trees where there are
three. The third is right, and it is right because it sits beside the table it
counts — `docs/INDEX.md` says *"All seven directories"* directly under a
seven-row table.

The wrong count is a symptom. **The list is the copy**, and §4b has been wrong
after four of the last six revisions that touched `docs/`, because a number in a
sentence has to be maintained by whoever adds a directory and nothing checks it.
This is 5.1 one level up: §4b is procedure, `docs/INDEX.md` is the map. §4b keeps
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

**Decision 7.1 — a bundle waiting on another's decision says so in prose inside
its `Relates to` line, and §4c requires the bundle's INDEX.md Notes cell to say
it too. `Decide after:` does not become vocabulary.** Owner, 2026-09-04.

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
it, and under 5.1 it would have to be split across both files — the term in the
legend, the obligation in §4c — which is a lot of structure for one sentence.

**Rejected: nothing formal; the owner sequences the work.** Honest about where
the knowledge is. Rejected as directly against 5.1, decided an hour earlier: a
rule that lives only in conversation is the failure this architecture exists to
remove.

### The cost, stated

**Nothing enforces the order.** A session can read *"decide that first"* and
start anyway. That was true of `Decide after:` as well — it obliged nobody
either — so this decision does not lose a guarantee, it declines to invent one.
If ordering is ever violated in a way that costs something, that is a finding, and
it will have evidence this one does not.

---

## Finding 8 — not decided

Recorded 2026-09-04, one revision after the rule it is about, and left open
deliberately. Its three shapes are in `findings.md`; one of them, a fourth write
category, is already rejected on sight under `0028` decision 6.1.

`resolving` cannot begin until it has a decision.
