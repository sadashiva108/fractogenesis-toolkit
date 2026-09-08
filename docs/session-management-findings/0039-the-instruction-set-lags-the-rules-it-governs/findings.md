# The instruction set lags the rules it governs

**Recorded:** 2026-09-03, restore-apps session, from its own outstanding items rather than from a fresh reading. Every finding below was noticed by this session while writing Revisions 166 through 173, and deferred in prose at the time.  
**Session:** `session_016EbjB7M527qEFqZFzpv2C9`  
**Severity:** findings F1, F5 and F8 are high. A session that reads only the instruction set does not learn several of the rules it is expected to follow, and one of those rules governs when it may touch the owner's checkout.  
**Scope:** instruction-set. The fix lands in `.github/copilot-instructions.md` §§4b–4d, `.claude/CLAUDE.md`, and `docs/architecture/findings-and-sessions.md`.  
**Relates to:** [`0029`](../../instruction-set-findings/0029-the-instruction-set-lags-the-rules-it-governs/) — **supersedes it.** The original is retained at `docs/instruction-set-findings/0029-the-instruction-set-lags-the-rules-it-governs/`, still listed by the session that held it, its reading unchanged and its files brought onto the schema in Revision 203. Authority for this reading lives here.  
**Relates to:** `0027` — that bundle read the instruction set for conformance and found seven defects. This one collects what this session left owed. They overlap at one point only, named in finding F2.

**Decide after:** `0027`, then `0028`. Findings 1, 2, 5 and 6 below are four
symptoms of one question `0027` finding F1 owns — *where is a rule allowed to
live* — and deciding them first would decide against a surface about to move.
`0028`'s resolution adds to finding F1's list rather than changing it. Finding 7
is about this line existing at all.
**Gate cleared 2026-09-04:** both are `resolved`. `0027` answered the question
finding F1 sits under — a fact has one home — and `0028` added §3 to the surfaces
this bundle must read, along with finding F8, which was found by breaking `0028`'s
own rule the day it was written.

**This bundle is a self-report.** Most of its findings are rules this session
wrote into `docs/legend.md` and did not carry into the instruction set, each time
with a line saying the adoption was owed. That many such lines is not a backlog,
it is a pattern, and finding F5 is about the pattern rather than any one instance.
Finding 8, added a day later, is the pattern's first *observed* cost rather than
its record: a rule that lived only in conversation was broken twice in an
afternoon by the session that had been told it.

---

## Contributions

| Session | Date | Contribution |
|---|---|---|
| `allocation-and-inquiry-design-20260906-233205` | 2026-09-06 | Recorded D5 against F7 and set D4's outcome to `superseded → D5` |

## Finding status

The bundle advances with its first row and reaches `resolved` only with its last.
`resolving` cannot begin until every row reads `yes` under Decided, and nothing
outside `docs/` is written until then — which for this bundle is the whole of the
work, since every fix is a toolkit write.

| # | Finding | Status |
|---:|---|---|
| F1 | Five rules exist only in `docs/legend.md` and not in the instruction set | `framing` |
| F2 | Two rules exist in both, in different words | `framing` |
| F3 | §4b's directory list is now wrong | `framing` |
| F4 | The architecture record describes two findings trees; there are three | `framing` |
| F5 | Nothing tells a session that `docs/legend.md` is normative | `framing` |
| F6 | State names and state requirements live in different files | `framing` |
| F7 | The vocabulary cannot say that one bundle must be decided before another | `decided` |
| F8 | The rule says where a change is composed, not when it is handed over | `framing` |
| F9 | Six rules live only in a workspace file, outside the repository entirely | `framing` |
| F10 | Nothing distinguishes a standing decision from one reopened for re-examination, and no state locks decisions while the work is in flight | `framing` |
| F11 | The header schema binds `findings.md` only, and six of eight architecture records render their header as one run-on paragraph | `framing` |
| F12 | No status transition names the event that triggers it, so a bulk edit moved twenty-one findings and every checker passed | `decided` |

---

## F1 — five rules exist only in `docs/legend.md`

Written there between Revisions 169 and 173, each because the instruction set was
gated at the time, and none carried across since:

| Rule | Revision | Where it lives |
|---|---|---|
| The three write categories — record, toolkit, evidence | 169 | `legend.md` only |
| Contribution: `unresolved` is open to any session, `in progress` is the owner's | 172 | `legend.md` only |
| A bundle overtaken while `in progress` is superseded, not edited | 173 | `legend.md` only |
| `Relates to` as a header pointer | 173 | `legend.md` only |
| The owner's override, and that a revision carrying one says so | 173 | `legend.md` only |

`.github/copilot-instructions.md` is the file a session is told to read first,
and `.claude/CLAUDE.md` points at it as the authority. A session that reads both
and stops — which is what they instruct — learns none of the five.

The contribution rule is the sharpest instance: it governs whether a session may
write to a bundle it does not own, which is a question every concurrent session
hits, and it is discoverable only by opening a file neither instruction names as
normative.

## F2 — two rules exist in both, in different words

`resolving`'s gate and the bundle-advance rule are in §4c *and* in `legend.md`,
written twice in different prose by the same session in Revisions 166, 168 and
172. Nothing keeps them in step.

**This is where this bundle touches `0027`.** That bundle's finding F6 records
that the two session-state diagrams disagree; this is the same failure on the
status side. They are separate instances and should be decided together — if the
answer is a rule about where a rule may live, it covers both.

## F3 — §4b's directory list is now wrong

§4b enumerates the directories under `docs/` and gives a count. It said five,
then six, then seven across Revisions 160 to 163, and reads six today.
`docs/session-management-findings/` makes seven, and this bundle is in it.

The count in prose is the defect, not the arithmetic: it has been wrong after
four of the last six revisions that touched `docs/`, because a number in a
sentence has to be maintained by whoever adds a directory and nothing checks it.

## F4 — the architecture record describes two findings trees

`docs/architecture/findings-and-sessions.md` §2 names
`docs/runbook-findings/<runbook>/` and `docs/cross-cutting-findings/` and gives
the test for choosing between them. There are now three, and the test is a
two-way one.

Its §12.3 also asks where a finding whose subject is not the project should go —
an open question that this tree partly answers and partly does not, since an
instruction-set finding is still about this project.

## F5 — nothing says `docs/legend.md` is normative

The instruction set points at `legend.md` for the status and state vocabularies,
and `legend.md` describes itself as where they are defined. Neither says it is a
file a session must read before working, and both indexes present it as a place
to look things up.

That is how five rules ended up somewhere sessions are not told to look. The
question this finding asks is not *where should the rules live* but *what tells a
session where the rules live* — and today the honest answer is that a session
learns it by being told in conversation, which is the failure mode this entire
architecture exists to remove.

## F6 — state names and state requirements are in different files

Revision 162 moved the status and state definitions out of §§4c–4d into
`legend.md` and left the per-state requirements — what `owned` records, what
`handoff` must carry, what `closed` and `withdrawn` owe — in §4d.

So a session reading §4d finds out what `handoff` requires without finding out
what `handoff` means, and a session reading `legend.md` finds the reverse. Both
are correct; neither is sufficient. Smallest of the six, and the one most likely
to be swept up by whatever answers finding F5.

## F7 — the vocabulary cannot express decision order

`Relates to` was added in Revision 173 and says that two bundles bear on each
other. It has no direction and no ordering, and the first three findings bundles
to use it needed both: `0029` must be decided after `0027`, because four of its
findings are downstream of `0027` finding F1, and after `0028`, whose resolution
adds to `0029` finding F1's list.

Nothing in the status vocabulary carries that. A bundle at `unresolved` looks
equally ready whether it is genuinely open or waiting on another bundle's
decision, and an owner picking work off an index cannot tell the two apart.
Supersession, added in the same revision, covers the case where a bundle is
overtaken *after* decisions are taken against it — the reverse situation, and no
help here.

**The `Decide after:` line at the head of this bundle is used provisionally.** It
is not in `docs/legend.md`, nothing else recognises it, and whether it becomes
vocabulary is part of this finding's own decision. Using an undefined pointer to
record that a pointer is undefined is uncomfortable, and the alternative — saying
nothing until the vocabulary exists — would have left the ordering in
conversation, which is what finding F5 is about.

Three shapes, none chosen:

- **A `Decide after:` header line**, as used here. Explicit, and a session picking
  the bundle up sees immediately that it should not start.
- **Nothing in the bundle; the owner sequences the work.** Honest, and it puts the
  knowledge back where finding F5 says it should not be.
- **Carry it in the `Relates to` clause** — *"decide that first, four of these are
  downstream of its finding F1"*. No new vocabulary, weaker guarantee, and it
  overloads a pointer that deliberately obliges nobody.

Whichever is chosen, it should be decided with finding F5: both are about what a
session can learn from the tree without being told.

---

## F8 — the rule says where a change is composed, not when it is handed over

**Recorded 2026-09-04**, one revision after the rule it is about, by the session
that broke it. Revision 182 wrote the composition rule into §3: compose in a copy
outside the owner's checkout, validate there, hand the owner a patch. It does not
say WHEN the patch is applied — and this session applied two of them to the
owner's checkout unasked, Revisions 181 and 182, each within minutes of composing
it.

The instruction reads as one motion. *"Hand over a patch"*, followed by *"check
the patch before applying it and say so"*, describes a session that applies its
own work and leaves the owner a role that begins at the commit. That is not the
owner's role. The owner asks to see the content first, asks for it to be written
when it is ready, and until then the work is a draft.

**That rule exists and is followed — in conversation.** It has been stated to
this session more than once. It is not in `.github/copilot-instructions.md`, not
in `docs/legend.md`, and not in any session prompt. It is finding F5 exactly, with
the difference that this one has now been observed failing rather than predicted
to.

### What it costs

Not much, and precisely one thing. An unasked-for apply is not destructive: the
owner reviews the diff before committing and can decline it. What it costs is
**review order.** A patch already in the tree is reviewed as a fait accompli; it
sits between the owner and anything else they wanted to do in that folder; and
declining it becomes an action rather than an omission — which is the property
`0028` finding F4 was pleased to have removed, restored by the same session in the
same revision.

`0028`'s own `resolutions.md` names this without recognising it: *"nothing
enforces the composition rule — the only signal that a session ignored it is a
dirty working tree in the owner's checkout."* That sentence describes the signal
for this finding too. The tree was dirty both times, and it was the owner who
noticed.

### Three shapes, none chosen

- **A hand-over step in §3.** The session reports what it composed and shows the
  content inline; the patch is applied only when the owner asks for it. Smallest,
  and it puts the rule beside the composition rule it completes.
- **A fourth write category.** Rejected on sight, and worth recording as
  rejected: `0028` D4 established one day earlier that composition is
  not a permission question, and applying is not one either. Two rules that vary
  by nothing do not become clearer by being made into three.
- **State it per session, in the prompt.** Where it lives today, minus the
  conversation. It makes the rule a property of a session rather than of the
  repository, which is the shape finding F5 exists to argue against.

**Decide with 5**, and probably in the same sentence: both are about what a
session can learn from the tree without being told, and this one is the case
where not being told had a cost the same day.

---

## F9 — six rules live outside the repository entirely

**Recorded 2026-09-07** by `session-management-re-evaluation-20260906-110105`,
from checking the instruction set against Revisions 208 to 213.

F1 read *five rules exist only in `docs/legend.md`*. This is the same shape with
a worse destination: **six rules exist only in `session-prompts/conformant-prompt.md`,
which lives in the owner's workspace and is not in this repository at all.** Not
merely missing from the instruction set — absent from a fresh clone.

| Rule | Owed to |
|---|---|
| `git apply` exits 0 on **modification** as well as deletion, so the exit status and the warning are both non-diagnostic | §6 — which still says *"any patch containing a deletion"* |
| A tag change is invisible to a patch: `STATUS-` and `STATE-` files are empty, `diff` emits no hunks for them, so a patch carries every prose change and none of the renames | §6 |
| The two trailing spaces the header schema requires make `git apply` warn on every conformant header; stripping them breaks the rendering the schema protects | §11 |
| A record carries no placeholders — absolute paths, real identifiers, actual commits | §5 and §11 |
| Completeness is not conformance: every checker answers whether a document is well formed, none answers whether it is complete, and rendering cannot show content that is not there | §6 and §8 |
| No check covers the prose total at the foot of a `findings-manifest.md` | §8 |

**The gate is working, and that is the point.** Every one is a toolkit write,
allowed only for a `decided` finding; the findings that would carry them —
`0041` F4, this bundle's F1, `0041` F2, `0043` F2 — are all `framing`. Nobody
broke a rule. **The rules accumulated in the one place a session could still
write them.**

That is F5 with the prompt in the role conversation used to play. F5 says a
session learns a rule *by being told*, and the failure is that the tree cannot
tell it. A cloned session is told, because it is handed the prompt. The
repository is not, and neither is any reader of it.

**Two properties make this worse than F1.** A rule in `docs/legend.md` is at
least tracked, reviewed in a diff, and reachable by every checker. A rule in a
workspace file is none of those: it takes no revision, appears in no manifest
entry, and `verify-doc-paths.sh` cannot see it because the file is outside the
repository the script self-locates in.

And the accumulation is **recent and fast** — all six landed between Revisions
206 and 213, which is one day.

**What this finding is not.** It is not an argument to ungate toolkit writes.
The gate exists because a rule written before its finding is decided is a rule
nobody agreed to. It is an argument that **the overflow needs a destination
inside the repository** — a tracked, revisioned place a session may write a rule
it has learned but may not yet install, so that the rule is reviewable and
countable rather than resident in a file the repository has never heard of.

## F10 — a decision cannot say it is under re-examination, and nothing locks one

**Recorded 2026-09-07**, from the owner asking why `0040` carries four `framing`
findings above six `accepted` decisions.

**The observation.** Six bundles in this tree carry accepted decisions. In
`0037`, `0038`, `0040` and `0041` those decisions are dated 2026-09-03 and
2026-09-04 and are **being re-evaluated**, because assignment reset every finding
to `framing` on the owner's instruction. In `0043` they are dated 2026-09-07 and
are **live and standing**. The two sets are **indistinguishable in the data.**

`Outcome` offers `accepted`, `rejected`, `refined → DX` and `superseded → DX`.
None of them says *under re-examination*. And the finding status reads `framing`,
which a reader takes as *not yet decided* where the truth is *decided once, being
decided again*. The only way to tell the two apart today is to compare a
decision's date against a session brief, which is a fact that lives in a prompt.

**The second half, and the owner's proposal.** There is no state in which the
decisions are **locked** while the work is in flight. `decided` narrows recording
to the owner but does not freeze anything — `0040` is the proof, its decisions
accepted and then reset. `resolved` is frozen and is the wrong end: by then the
work is done. The gap between them is exactly where a toolkit write happens, and
**changing a decision while its resolution is being carried out makes work in
flight retroactively unauthorised.**

The owner's proposal is a status filling that gap, functioning as a gate: once it
is entered, the decisions are pinned.

### Two cautions, recorded so they are argued rather than met later

**Do not call it `resolving`.** That word named a status retired in Revision 198,
and the job proposed here is different — the old `resolving` meant *the doing is
under way*, this means *the decisions are locked*. Reusing a retired word for a
new meaning is what happened to `unclaimed`: retired as a session state by `0037`
D7, returned as a bundle status meaning something else, and the 2026-09-06
handoff recorded it as a loose end still open. **One word naming two things, one
of them retired, is a defect this tree has already paid for once.**

**And an activity name would repeat F8.** `resolving` is a present participle. F8
records that each vocabulary already has exactly one activity-named member and
that it is structural rather than chosen — a second one would be chosen, and
would name an activity where the fact being recorded is a **composition**: the
decisions are complete and closed. A composition-shaped name is what this needs.

**Both halves are one question**: whether the vocabulary should distinguish
*decided* from *decided and locked*, and if so what the locked state is called
and who may leave it. Not decided here.

## F11 — the header schema binds one file type, and the records break it

**Recorded 2026-09-07**, while bringing
`docs/architecture/findings-and-sessions.md` current.

Section 11's rule — one field per source line, two trailing spaces on every line
but the last — exists because without it a header block renders as a single
run-on sentence with the field names buried in it. `bin/verify-findings-headers.sh`
enforces it, and enforces it on `findings.md`, `decisions.md` and
`resolutions.md`.

**The architecture records use the same header shape and are bound by neither.**
Measured by rendering all eight:

| | |
|---|---|
| Correct | `allocation-and-inquiry.md`, `state-as-data.md` — the two written after the rule existed |
| **Renders as one run-on paragraph** | `findings-and-sessions.md`, `transferring-part-of-a-bundle.md`, `restore-docker-teardown-and-test.md`, `restore-repos-clone-plan.md`, `sign-off-consolidation.md`, `time-machine-run-index.md` |

**Six of eight.** The two correct ones are correct because their authors had just
read the rule, not because anything held them to it.

`findings-and-sessions.md` is the sharper instance: it is cited as the authority
by `allocation-and-inquiry.md` four times, and **its own header has never
rendered as it was written.** Nobody noticed for four days, because every checker
reads the source and the rule that would catch it stops at a file-name boundary
nothing states as deliberate.

The two session-management records were corrected in the revision that recorded
this. **The four toolkit records were not** — one file, one owner — and are
flagged rather than edited.

## F12 — a status transition names no trigger, and a sweep is indistinguishable from a reading

Recorded 2026-09-08, from this session doing it.

`docs/legend.md` line 39 draws the finding lifecycle as arrows between statuses.
Every arrow says what the *next* status is. **Not one says what event causes the
move.** The one arrow that carries a label carries the wrong kind of one:

```text
un-started ──▶ framing ──▶ decided ──▶ resolved ──▶ reopened ──┐
                  ▲                                            │
                  └────────────────────────────────────────────┘
                              first read by the owner
```

*"First read by the owner"* makes **reading** the trigger. Reading is the one
thing that changes nothing, and a vocabulary whose transitions fire on reading
cannot tell a sweep from a glance.

### What it cost, measured

Revision 208 assigned six bundles and read them. Immediately before it, at
`80d3482`:

| Bundle | Before | After Revision 208 |
|---|---|---|
| `0037` | 7 `reopened` | 7 `framing` |
| `0038` | 6 `reopened` | 6 `framing` |
| `0039` | 7 `decided`, 1 `un-started` | 8 `framing` |
| `0040` | 4 `reopened` | 4 `framing` |
| `0041` | 4 `reopened` | 4 `framing` |

**Twenty-one `reopened` rows became `framing` in one commit, and its message
accounted for eight of them** — `0039`'s, which the owner had asked for. The
other twenty-one are not mentioned, because the session did not notice it was
making a claim. Under the labelled arrow it had not: it had read them.

The transition is *legal*. That is the finding. `reopened ──▶ framing` is the
diagram's own loop, so no rule was broken, and all six validators passed on the
result — `verify-findings-structure.sh` compares a tag against a row and both
had moved together, which is exactly what a sweep produces.

### What was destroyed, and what was not

`reopened` says *this was decided, resolved, and its resolution was called into
question.* `framing` says *live and open.* Flattening the first into the second
loses the entire history and reads as though the reading had never been
completed. Nothing recovers it from the row; it was recovered here from
`git show 80d3482`.

Two smaller facts fall out of the same reading:

**The twenty-one carry no reason for having been `reopened` either.** They were
swept there at Revision 200 (`4626eb4`, *"eighteen further rows and two tags
swept"*) when the tree was brought onto the current vocabulary. A sweep is not a
reading of any individual finding, so no reason was recorded for any of them, and
none is invented here — the reasons are owed, not lost.

**A reading is not the only thing mistaken for a change.** Assignment, a
vocabulary sweep, a rename and a retrofit are all edits that touch a status cell
without anyone forming a judgement about the finding underneath it. Each is a
mass operation, which is why each is dangerous: a wrong judgement damages one
finding, a wrong sweep damages every finding it passes over.

### The correction, recorded 2026-09-08

The first repair proposed for this was to restore the twenty-one rows to
`reopened`, and **it was wrong for the same reason Revision 200 was wrong.**

`reopened` requires the finding to have been `resolved`. `0038/F1` never was —
`0028/F1` was, and `0028` is a different bundle. `0043` D1 is what makes that
sayable: a finding is addressed `<bundle>/F<n>`, so `0028/F1` and `0038/F1` are
two addresses and only one of them was ever resolved.

**These six bundles are supersession successors, not reopened readings.** Each
carries `Relates to … supersedes it`, each predecessor is tagged `superseded`,
and `superseded` reaches a bundle from any status — which is exactly why it fits
here and `reopened` does not. What the successors' findings needed was never a
status at all: it was **provenance**, and there was no way to record it until
`0039` D12.

So the rows stay `framing`, which is what they are, and the relationship they
were trying to express is now six sets of provenance edges — 31 of them,
extracted by comparing statements rather than asserted by hand, with coverage
and exclusivity passing on every pair.

**Twice now a sweep has put a status on these findings that the findings did not
support**, and the second time was by a session that had just written the rule
against it. That is the strongest evidence for D7 in the bundle: a status a human
or a session *reasons* their way to is exactly as wrong as one swept in, unless
the event that justifies it is recorded.

### Why no check catches it

Every existing checker compares two *displays* of the same fact — a tag against a
row, a count against a table. A sweep moves both, so agreement is preserved and
the check passes. **Nothing compares a status against the event that should have
produced it**, because no event is recorded. That is `0043` F2 and F3 arriving
from a third direction: the framework can only check its displays against each
other, never against what happened.

---

## What this bundle does not cover

`0027`'s seven findings, which are a separate reading of the same surface by a
different session and are owned separately by this one. Where the two meet is
named in finding F2 and nowhere else.

<!-- historical: bin/verify-findings-headers.sh -->
