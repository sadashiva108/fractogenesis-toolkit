# The instruction set lags the rules it governs

**Recorded:** 2026-09-03, restore-apps session, from its own outstanding items rather than from a fresh reading. Every finding below was noticed by this session while writing Revisions 166 through 173, and deferred in prose at the time.  
**Session:** `session_016EbjB7M527qEFqZFzpv2C9`  
**Severity:** findings F1, F5 and F8 are high. A session that reads only the instruction set does not learn several of the rules it is expected to follow, and one of those rules governs when it may touch the owner's checkout.  
**Scope:** instruction-set. The fix lands in `.github/session-management-instructions.md`, `.claude/CLAUDE.md`, and `docs/architecture/findings-and-sessions.md`. Recorded against `.github/copilot-instructions.md` §§4b–4d, which commit `1c48deb` deleted; D13 re-ruled the address.  
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
| `typed-bundles-architecture-20260908-204724` | 2026-09-09 | Added F21 and F22, from a cold reading of `docs/legend.md` at Revisions 236 and 237 |
| `typed-bundles-architecture-20260908-204724` | 2026-09-09 | Added F23 and took D21, from its own failure to hand the Revision 239 message over as a block |
| `drift-and-the-write-boundary-20260909-053548` | 2026-09-09 | Added F24 and F25, both found while writing decisions into `0047` — a bundle it owns, whose `decisions.md` was begun by another session |
| `drift-and-the-write-boundary-20260909-053548` | 2026-09-09 | Added F27, found by widening the disjointness guard to every pair of closed vocabularies — `0047` F11 |

## Finding status

The bundle advances with its first finding and reaches `resolved` only with its
last. **No finding is resolved until it is `decided`**, and nothing outside
`docs/` is written until then — which for this bundle is the whole of the work,
since every fix is a toolkit write.

Recorded when a `resolving` status existed. It was retired in Revision 198 and
F10 argues against reviving it; `decided` is the gate the sentence was reaching
for.

| # | Finding | Status |
|---:|---|---|
| F1 | Five rules exist only in `docs/legend.md` and not in the instruction set | `framing` |
| F2 | Two rules exist in both, in different words | `framing` |
| F3 | §4b's directory list is now wrong | `framing` |
| F4 | The architecture record describes two findings trees; there are three | `framing` |
| F5 | Nothing tells a session that `docs/legend.md` is normative | `framing` |
| F6 | State names and state requirements live in different files | `framing` |
| F7 | The vocabulary cannot say that one bundle must be decided before another | `resolved` |
| F8 | The rule says where a change is composed, not when it is handed over | `decided` |
| F9 | Six rules live only in a workspace file, outside the repository entirely | `framing` |
| F10 | Nothing distinguishes a standing decision from one reopened for re-examination, and no state locks decisions while the work is in flight | `framing` |
| F11 | The header schema binds `findings.md` only, and six of eight architecture records render their header as one run-on paragraph | `framing` |
| F12 | No status transition names the event that triggers it, so a bulk edit moved twenty-one findings and every checker passed | `resolved` |
| F13 | The vocabulary file is named for a glance and read as a specification, and moving it is a rename with sixty-three citations | `framing` |
| F14 | Nothing in the repository is written for someone arriving cold; the entry point is a 724-line instruction set | `decided` |
| F15 | A check that validates citations cannot detect their absence: ten decisions cited no finding and every checker passed | `resolved` |
| F16 | Every check asks whether a document is well formed; none asks whether it is complete, and 162 contaminated fields passed all of them | `resolved` |
| F17 | Resolving has no procedure: the framework's commonest transition is the only one with no numbered steps, and seven resolutions went unrecorded because of it | `decided` |
| F18 | `accepted` cannot say whether a decision's work was carried out, so a decision that changed nothing reads identically to one that changed the tree | `framing` |
| F19 | Nothing scopes the record to this repository, so work a session does in another connected project has no stated home and no rule keeping it out | `resolved` |
| F20 | Releasing a bundle to `unclaimed` has no procedure, though its sibling `transferred` has five numbered steps and the operation strands a bundle when done wrong | `decided` |
| F21 | Nothing checks that a vocabulary change reached the prose, and five consecutive revisions demonstrate it — the last leaving the legend saying a superseded bundle cannot be read | `framing` |
| F22 | The currency watch that covers the legend was asserted before the defect existed, has never been armed, and cannot report drift while unarmed | `framing` |
| F23 | §7 requires the commit message to be nothing but the message and never requires it to be a block, so a session can obey every word of the rule and still hand over one the owner has to reassemble | `framing` |
| F24 | `decisions.md` carries one `Session:` field and the Decisions table has no column for one, so a decision written by a session that does not own the bundle cannot be attributed — and §4 invites exactly that write | `framing` |
| F25 | *What another session may do* has no row for `transferred`, the one standing under which a non-owner is routinely told to contribute | `framing` |
| F26 | `docs/legend.md` says a status moves on a write and also that reading is the transition, and §10 sides with the minority against five records and the tree | `resolved` |
| F27 | `withdrawn` is a finding `status` and a session `state`, so the rule that no value belongs to more than one vocabulary is broken in the document that states it | `resolved` |
| F28 | `unclaimed` sits in a readability row it does not earn, so releasing a bundle makes 19 `decided` and 7 `framing` members unreadable for a reason about ownership | `resolved` |
| F29 | Nothing says a commit message is valid only for the patch it was handed over with, and three of the last seven commits name a revision the commit does not add | `resolved` |

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

The gate on beginning resolution and the bundle-advance rule were in §4c *and*
in `legend.md`, written twice in different prose by the same session in Revisions
166, 168 and 172. Nothing kept them in step. Both named a `resolving` status,
retired in Revision 198; the duplication is the finding and the word is
incidental to it.

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

Nothing in the status vocabulary carries that. A bundle at `analyzing` looks
equally ready whether it is genuinely open or waiting on another bundle's
decision, and an owner picking work off an index cannot tell the two apart.
Recorded against `unresolved`, the name that row carried before Revision 200.
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
| A tag change is invisible to a patch: `STATUS-` and `STATE-` files were empty, `diff` emitted no hunks for them, so a patch carried every prose change and none of the renames. **Moot since Revision 222** — the tags are gone and a status is a value in `metadata.json` — but the trap applies to any file a patch renames | §6 |
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

## F13 — the vocabulary file is named for a glance and read as a specification

Recorded 2026-09-08, from the owner asking where vocabulary lives.

`docs/legend.md` is 540 lines holding six enumerations: finding statuses, bundle
statuses, session states, transition reasons, decision outcomes and provenance
kinds. **A legend is a key you glance at. This is a specification you look things
up in**, and the name tells a reader to skim what they should be searching.

The shape it wants is `docs/reference/`, which does not exist. That is also the
shape a quick-start would point into, which is F14.

**What makes it a finding rather than a `git mv`: sixty-three files cite it.**
`0030` is the bundle about renames breaking citations, and its whole subject is
that a rename is cheap to perform and expensive in the way this repository keeps
recording. So this is a `0030`-class change and needs that procedure, not a
move.

**It is also not free of the thing it would fix.** Three of the legend's sections
— *Write categories*, *Where a write is composed*, *How the two meet* — are
procedure sitting in the vocabulary file, and `0039` D2 said in 2026-09-04 that
the gating leaves and only the definitions stay. That half of D2 was never
carried out. **Renaming the file before splitting it would carry the defect into
the new name**, so this finding is ordered after D13, not before it.

Undecided deliberately. The reading is that the rename is right and the sequence
matters; whether it is worth sixty-three citations is the owner's call.

## F14 — nothing here is written for someone arriving cold

Recorded 2026-09-08, from the same question.

Every document in this repository is written for a session that is **already
working**: the instruction set tells it what it may write, the legend tells it
what the words mean, the architecture records tell it why. **Nothing tells a
person who has just opened the repository what any of it is for.**

The de facto entry point is `.github/session-management-instructions.md` at 724
lines, which is a reference manual serving as a front door.

That gap has a cost this bundle can measure. **Six rules lived only in a
workspace file outside the repository** — F9 — and three more were added to that
file on 2026-09-08 while this finding was being written. They went there because
there was no obvious place for *how this works* as distinct from *what the rules
are*, and a workspace file is what a person reaches for when the repository
offers no shelf.

**This is new surface and no ruling covers it.** D1 split vocabulary from
procedure; both are written for a session mid-task. A README and a quick-start
answer a third question — *what is this and where do I start* — that neither
half was ever asked.

Recorded unanswered on purpose. It was discussed only in a session transcript,
which is F9's defect one level worse: a transcript is not a file anyone can open,
and this finding exists so the question survives the session that raised it.

### What became of F14, decided 2026-09-09

**Two of its three parts were answered by changes made elsewhere and nothing
recorded it.** Revision 246's router carries the six-rank precedence order and
eleven documents now carry a Role masthead, so *which document wins* is answered;
Revision 249's `docs/rules/` is the shelf whose absence sent six rules to a
workspace file. **The first sentence is still true** — `README.md` is the
project's and a cold reader lands there — and **the number in this finding's own
title is stale in the wrong direction: 724 has become 951.** D22 gives the
framework its own door; D23 shortens what is behind it. Neither is carried out
here.

## F15 — a check that validates citations cannot detect their absence

Recorded 2026-09-08, from the owner noticing accepted decisions with an empty
Findings cell.

`bin/verify-findings-headers.sh` checks that **every `F<n>` a decision cites
exists in `findings.md`**. Line 223 collects the citations with
`grep -oE 'F[0-9]+'` and the loop below iterates over what it finds.

**On a decision that cites nothing, `grep` returns nothing, the loop body never
runs, and the check passes.** The claim *"every citation resolves"* is
vacuously true of a row with no citations. Ten decisions were in that state —
six in `0040`, four in `0041` — and six validators passed over them for four
days.

### Why it matters more since this morning

`0039` D8 voids **"the decisions under a finding"** when the finding is reframed.
**A decision citing no finding is under nothing**, so the rule written today
cannot reach any of those ten. A decision unreachable by the voiding rule keeps
its authority through any amount of reframing, silently.

That is the same shape as `0043` F7 — `analyzing` is the else branch and asserts
nothing, so a bug lands there looking plausible. Here the blind spot is in a
*check* rather than a *derivation*, and it was invisible for the same reason:
**nothing states a positive condition that a missing thing would fail.**

### The fix

One line: a decision row must cite **at least one** `F<n>`. It is the same shape
as D12's coverage rule — the failure worth catching is zero, not a mismatch — and
it belongs beside it.

## F16 — every check asks whether a document is well formed; none asks whether it is complete

Recorded 2026-09-08, from the parallel session reading the migration's output.

The extraction that produced 54 `metadata.json` files wrote **162 contaminated
fields across 47 of them.** Every `recordedOn`, `sessionId` and `severity` began
with two asterisks:

```text
"recordedOn": "** 2026-09-07",
"recordedBy": { "sessionBundle": null,
                "sessionId": "** allocation-and-inquiry-design-… (session_015F…)" }
```

Three defects in one regex. `lstrip(": ")` stripped the colon and the space and
**not the closing `**`**. A field whose value is a bullet list — `Read:` — captured
the empty remainder of its label line and stopped, losing **39 bullets across
nine bundles**. And `Session:` went whole into `sessionId`, leaving
`sessionBundle` null — **the field split the schema exists to enforce, undone by
the thing populating it.**

### What makes it a finding rather than a bug

**All four checkers reported 0 FAIL, and all four were right.** The JSON was
well-formed: valid, every count agreeing, every derived status matching its row.
Nothing was malformed. Things were *missing*, and no check in this repository
asks that question.

- `verify-findings-counts.sh` compares a count to a count.
- `verify-findings-structure.sh` compares a status to a row.
- `verify-findings-headers.sh` compares a citation to a target.

**Every one compares two things that are present.** A field that lost its
contents still has a field; a list that lost its items is still a list. It was
found by a person reading the output.

*"Completeness is not conformance"* has been a written rule since Revision 217,
installed in the instruction set under an owner override. **Nothing implemented
it**, which is this bundle's whole subject arriving at its own instruments.

### And it is `0043` F3 inside the migration away from `0043` F3

`0043` F3 is *the framework's data is parsed back out of rendered markdown, and
that parser has been wrong twice.* This is the third time, in the parser written
to retire the practice, at the moment it was retiring it.

**Fifth instrument in a row to fail against a healthy tree on its first run**,
after `0041`'s lint, `0042` F4's audit at 128-of-131, the parallel session's
sweep at 65-of-77, and — while this finding was being written — the completeness
check itself at 18 false positives and the one-way guard refusing to run because
the design document describing its marker mentions it. **The half that reads is
wrong; the half that judges is fine.** That is now a five-instance pattern and
should be treated as a law of this repository rather than a run of bad luck.

## F17 — resolving has no procedure

Recorded 2026-09-08, from the owner asking why seven resolutions were never
written down.

`.github/session-management-instructions.md` carries a numbered procedure for
every lifecycle event except one:

| Event | Procedure |
|---|---|
| superseding a bundle | §9, nine numbered steps and three prohibitions |
| reopening a finding | §9a |
| withdrawing a finding or bundle | §9a |
| transferring a bundle | §10 |
| **carrying out a decision and resolving a finding** | **none** |

What exists for `resolutions.md` is its **shape**, in §11 beside the header
schema: five columns, what `Resolved by` means, how a pre-schema finding records
an absent revision. **Nothing says when a session writes one.**

That is the commonest transition in the framework and the only lifecycle event
that produces a tracked file, and it is the one with no steps.

### The instance

This session accepted eighteen decisions and carried out the toolkit writes for
seven of them across Revisions 221 through 225 — `verify-doc-paths.sh` scanning
`docs/`, the transition rules in the legend, the citation check, the completeness
check, the one-way guard, the tag removal, the edge contract in the schema.

**Not one `resolutions.md` was written, and not one finding moved to `resolved`**
until the owner asked what had been resolved. The answer at that moment was
*nothing*, over a tree that had absorbed five revisions of the work.

**`docs/legend.md` describes `resolved` as a state and D7 names its trigger.**
Neither is a procedure. A session reading the instruction set learns what
`resolved` means and never learns that closing a finding requires writing a row.

### Why it is worse than a missing section

The three checkers cannot see it. `verify-findings-headers.sh` validates
`resolutions.md` **if the file exists**; a bundle with none is not failing
anything. So the framework's position was: no instruction to write the file, and
no check for its absence. **A finding could stay `decided` forever with its work
long since shipped**, and every validator would pass — which is `0037` F5's shape
(*every `resolved` bundle missing `decisions.md`*) with the two files swapped.

## F18 — `accepted` cannot say whether the work was done

Recorded 2026-09-08, from the owner asking what *uninstalled* meant.

It is not vocabulary. It is a word this session invented mid-conversation because
the framework has none, and inventing one under pressure is the tell.

**`accepted` means the decision is adopted.** It says nothing about whether the
change it authorizes exists in the tree. This bundle carries both states under one
value:

| Decision | State | Renders as |
|---|---|---|
| D5 — ordering as a typed edge | accepted, and 31 edges exist in the data | `accepted` |
| D6 — the hand-over step in §6 | accepted 2026-09-07, **nothing written** | `accepted` |

A reader cannot tell them apart without reading the tree, which is the work the
record exists to save.

**The finding status carries it and cannot carry it alone.** `decided → resolved`
answers *the whole finding*, not each decision under it. A finding with four
decisions where three shipped is `decided`, exactly as if none had — which is what
`0039` looked like all day.

**This is not `voided`, and not `deferred`.** `voided` is a decision invalidated
because its foundation moved; `deferred` is one that cannot be ruled yet. D6 is
ruled, sound, and simply not carried out. The vocabulary has no seat for it.

Left `framing` deliberately. The obvious fix — an eighth Outcome — would put a
*progress* fact into a vocabulary D9 defined as **acts performed on a decision**,
and D9's whole rule is that no word appears in two vocabularies. Whether this
wants a separate field, a derivation from `resolutions.md`, or nothing at all is
the owner's call, and F17's procedure may make it moot: if closing a finding
requires a row per decision, *carried out* becomes derivable.

## F19 — nothing scopes the record to this repository

Recorded 2026-09-08, from the owner noticing that a session had done work in a
second project and observing that nothing would have kept it out of these records.

A session can have several folders connected at once. This one had three by the
end: the toolkit checkout, `reimage-workspace`, and a notes vault belonging to a
different project entirely. **Work was done in all three**, and only one of them
is what this repository records.

**Nothing states that boundary.** §6 defines three write categories — record,
toolkit, evidence — and all three are about writes *inside* this repository or to
its evidence volume. A write to a fourth place has no category, which reads as
*not covered* and behaves as *not thought about*. The manifest, the session
bundle's `metadata.md` Resources table and a `findings-manifest.md` note are all
places a side errand could land, with no rule against it and no check able to see
it.

**It did not happen here**, and that is the finding rather than a reprieve: the
records are clean because the session happened to keep them clean, not because
anything required it. A rule that holds by luck has not been tested.

### It is F9 from the other direction

F9 records **six rules living only in a workspace file, outside the repository**
— three more were added there the same day. That is the framework's material
leaking *out*.

This is unrelated material leaking *in*. One boundary, two failures, and stating
it once answers both:

> **The record covers this repository. The rules governing it live in this
> repository.**

Nothing else is recorded here, and nothing the framework depends on is recorded
anywhere else.

### Why a connected folder is the wrong unit

The obvious rule — *only write about folders in your Resources table* — fails
immediately: the artifact volume is not a connected folder and is squarely in
scope, while a folder can be connected for one lookup and be nobody's business.
**Connection is availability; scope is subject.** The session bundle's `prompt.md`
says what the subject is, and that is the thing to measure against.

## F20 — releasing to `unclaimed` has no procedure

Recorded 2026-09-08, from the owner asking whether instructions existed for it.

`unclaimed` and `transferred` are the two ownership statuses. The legend defines
both in the same sentence — *"`unclaimed` and `transferred` are about **ownership**
rather than progress"* — and the instruction set treats them nothing alike:

| Status | Procedure |
|---|---|
| `transferred` | §10, five numbered steps: the field, both manifests, both sessions' counts, `metadata.md` on both sides, one revision |
| **`unclaimed`** | **none** |

`unclaimed` appears twice in the whole instruction set, and neither mention is a
step: *"closed to everyone… parked until the owner assigns it"*, and a note that
it has no owner to move.

### It is not a small operation

Releasing touches four places — the session's `findings-manifest.md`, the
bundle's index row in two cells, the session's counts in `docs/sessions/INDEX.md`,
and the session's own disposal record. **Getting it wrong strands a bundle**: it
stays listed by a session that has stopped, which is unreachable by definition,
and the legend forbids exactly that at line 409 — a `closed` session must have
every bundle terminal or released.

**That failure is on the record.** Revision 200 found `phase-11b` closed while
still holding five bundles, and `0008`, `0011`, `0015`, `0016` and `0017` had to
be released after the fact.

### The practice exists and was never written down

Commit `80d3482` did it correctly when `restore-apps-outstanding` closed: the row
removed from the manifest, the index Session cell set to `—`, the counts
decremented, and `final-summary.md` recording a disposition per bundle. **A
session that had not read that commit would be inventing the procedure**, which is
this bundle's subject exactly.

### One step of it has already disappeared

Revision 222 made ownership **derived** — computed by scanning the session
manifests rather than stored. So the first step of any pre-222 procedure, *set the
status*, no longer exists: **remove the manifest row and `unclaimed` follows.**
The procedure that was never written is now shorter than it would have been, which
is the design paying for itself.

## F21 — nothing checks that a vocabulary change reached the prose

**Start with what the legend said until Revision 239.** *What another session may
do* is the table every session reads before its first write. Its first row listed
`superseded` under **nothing is readable**. Its second row listed `superseded`
under **readable by any session, writable by none**. The table stated no
tie-break, and the ordering rule stated for the tables above it is *first row that
matches* — so read literally, **the legend said a superseded bundle cannot be
opened**, while `.github/session-management-instructions.md` §9 spends three
prohibitions keeping it readable and says the reading *"is retained precisely so
it can be read."*

That is not a stale word. It is a live contradiction, in the one table whose whole
job is to tell a session what it may open, and it stood for three revisions.

**The same table's third row read `analyzing`, `reopened`, `resolved`** under a
heading that says **Bundle standing**. Two of those three are finding statuses.
Revision 233 gave the bundle set its own words — `analyzing`, `revisited`,
`answered` — precisely so a bare value would say which vocabulary it came from,
and this row is where that property failed.

### Five revisions, one failure

| Revision | Reached | Stopped at |
|---:|---|---|
| 233 | `metadata.json`, `plan_findings_work.py`, every INDEX row | `docs/legend.md`'s ladder |
| 235 | the legend's prose | the ladder table itself |
| 236 | the ladder, rebuilt as two tables | the permission table directly below it, and two sentences citing by row number the ladder it had just deleted |
| 237 | every derived cell in `docs/session-management-findings/INDEX.md` | the paragraph beneath that table, still naming the wrong owners and the wrong counts |
| 238 | the shared subject prompt | all of the above, still standing |

**Three of the five were repairs of the one before.** Revision 236's own entry
names the failure exactly — *"the ladder, the table people actually read, kept the
old shape"* — and two revisions then walked past a second table with the same
defect. The two row-number citations Revision 236 left, at `docs/legend.md:304`
and `:318` as the file stood at Revision 238, pointed into the eight-row ladder
that same revision had deleted.

### The mechanism

Every instance is one object: **prose that restates a fact a table derives.** A
row-number citation restates the ladder's ordering. A permission table restates
the standing vocabulary. An index footer restates counts and ownership. A manifest
entry restates what the tree contains.

`docs/legend.md` already forbids this in one sentence — *a fact has one home; a
copy is permitted only where it is generated, or where a check fails when it
drifts* — and `docs/architecture/state-as-data.md` §6 carries it out **for tables
and only for tables**: the generated-region markers stop at the table's last row.
§5 called the Findings table "the hard case." The hard case was the paragraph
beneath it, which restates the same facts in a form nothing generates and nothing
checks.

**Measured in a copy, 2026-09-09, on Linux.** With the pre-repair legend restored
over the repaired file, every check in the repository returns byte-identical
output — `counts ok`, `structure ok`, `completeness ok`, `headers` at its standing
baseline, and doc paths clean. **The repair moves no number.** F16's completeness
check does not reach it either: it asserts that no atomic value carries ornament,
that a list in a document is a list of the same length in the data, and that every
header field reaches a non-empty key. The permission table was not incomplete. It
was wrong, and nothing in `bin/` has an opinion about what a table means.

### What it costs to leave

Not a stale document — an authoritative one that is wrong, in the file every
session is told to read first. Five consecutive revisions shipped one, and in
three of them the revision's own subject was the previous failure. **The only
thing that has ever caught it is somebody opening the file cold**, which has now
happened at every one of the five, each time late, and each time by a session
other than the one that wrote it.

### What this finding owes

Whether prose that restates a derived fact should be generated like the table it
sits under, prohibited, or accepted deliberately and said so in writing. The
current position is not a decision; it is five revisions of the same accident.

**A check is plausible and is not obviously the answer.** Six instruments in this
repository have failed against a healthy tree on their first run, and a
prose-coherence check would be the seventh. The cheapest candidate that is not a
new parser: **assert that no word from one vocabulary appears in a table headed by
another** — a closed-set membership test over three known sets, which would have
caught the third row on the day it was written and would have caught nothing else.

**Two cells in that table are left as they stand and this finding owns the
question.** *A finding* makes a `withdrawn` finding readable by any session; the
bundle table puts `retired` — every finding `withdrawn` — under *nothing is
readable*, and its third row's cell ends `withdrawn` — not readable. Both came
over from the eight-row ladder, where one word served a finding and a bundle at
once. Which side is right is a reading, and Revision 239 declined to decide it in
a repair.

## F22 — an assertion is not a subscription

`.internal/ai-scripts/session-management/doc-currency.json` carries a
`state-schema` watch, tier `critical`: source
`docs/architecture/state-as-data.md`, dependents including **`docs/legend.md`**.
The edge exists, it is correct, it is aimed at exactly the pair F21's third
revision broke, and it was written in **Revision 232 — the same revision that took
the decision the legend then contradicted.** `git log` on that file returns
exactly one commit, `d0e6d7d`; Revisions 235 through 238 did not touch it.

**It has never fired and it cannot.** All seven watches carry
`"sourceDigest": null` and `"confirmedAt": null`, and `doc_currency.py:evaluate()`
tests the null before it compares:

```text
if w.get("sourceDigest") is None:
    state = "UNCONFIRMED"
elif cur != w["sourceDigest"]:
    state = "DRIFTED"
```

so a watch with no baseline cannot reach `DRIFTED` however far its sources move.
`--confirm` is the only thing that writes a digest, it is `manual` on all four
critical watches, and no revision has run it. **A watch is born unarmed and
nothing arms it.**

**Measured in a copy, 2026-09-09, on Linux.** `--confirm state-schema` wrote
digest `b0f3485a7ca2f517`; one line appended to `state-as-data.md` then produced
`** state-schema DRIFTED`, listing `docs/legend.md` among the dependents to
review. The instrument works. It has never been switched on, and switching it on
is one command no procedure asks for.

**Its failure cannot be told from its success at the exit code.** `cmd_check`
returns 1 when any *critical* watch is not `current`, which since Revision 232 has
meant *not armed* — so the tool has exited non-zero on every run it has ever had.
The usage block at `bin/verify-doc-currency.sh:11` states a different contract:
*"Exits non-zero when a `critical` watch has drifted."* A reader who trusts the
usage string reads that exit as drift, against a headline reading `0 drifted`.

### The family, which `0047` F5 does not cover

`0047` F5 reads the repository's instrument failures as *the half that reads the
tree is wrong, not the half that judges it*. **This is a different family and now
has three members in two days**: an instrument that is correct about the tree and
structurally unable to say so. This watch is one. The other two are `0050`, owned
by `assurance-coverage-20260908-204724` — a dead `STATUS-superseded` exemption in
`verify-findings-headers.sh:201`, and a write-location guard blind to
`device_bash`. **They are named here and not folded in**; they are that session's
reading, and this finding claims only the family and this member of it.

The distinction matters because the two families have opposite remedies. A wrong
reader is fixed by fixing the reader, and its first run tells you it is wrong. A
correct instrument that cannot fire **passes every test anybody would think to
run**, and the only evidence of the fault is that it has never said anything.

### What this finding owes

Three candidates, none costed here: that `--confirm` becomes part of applying a
revision, so a watch cannot stay unarmed across one; that a null digest gets its
own exit code and its own word rather than sharing one with drift; or that a watch
is armed at the moment it is written, on the grounds that whoever asserts an edge
has just read both ends. **The failure worth catching is zero** — a watch that has
never been confirmed — which is the shape §9's coverage clause and §9b already
use, and the one shape in this repository that has not yet produced a false
positive.

## F23 — the commit message rule is half a rule

§7 says **"The block you hand over is the message and nothing else"** and spends a
paragraph on what must not be inside it — no `git commit`, no `-m`, no quoting
wrapper — because a command in the block is something the owner has to delete
before using it.

**It never says the message is a block.** Every requirement in the section is
about what the block excludes, and nothing in it establishes that there is one. A
session can therefore satisfy the rule completely — no command, no wrapper,
nothing but the message, both trailers at the end — and still hand over something
the owner cannot use as handed.

**Observed at Revision 239.** The message was handed over as ordinary prose in the
reply, with commentary before and after it. Every word of §7 was obeyed. The owner
asked for it a second time as a block, and that is the cost: not a wrong message,
a message that has to be gathered by hand before it reaches `git commit`.

**The two failures are one failure from opposite sides.** A `git commit` inside the
block is something the owner deletes. A message outside a block is something the
owner gathers. §7 named the first and had no word for the second, so the rule read
as complete while covering half its own subject.

**The fence is already required elsewhere in this file, for this reason.** §11
requires every example to be fenced and tagged `text` — never four-space indented,
never tagged `markdown` — because renderers disagree about the first and interpret
the second. A commit message is an example in exactly that sense: inert text that
must survive rendering unchanged and be copied whole. §7 is the one place the file
asks for such a block without saying it is one.

**What it costs to leave.** One round trip per commit message — small, recurring,
and paid by the owner rather than by the session. It also has the shape this bundle
exists to record: **a rule whose stated half is enforced by habit and whose unstated
half is found by breaking it.** Nothing checks either half. The only instrument is
the owner asking twice.

## What this bundle does not cover

`0027`'s seven findings, which are a separate reading of the same surface by a
different session and are owned separately by this one. Where the two meet is
named in finding F2 and nowhere else.

<!-- historical: bin/verify-findings-headers.sh -->

## F24 — a decision has no author, and the schema invites one

§4 and `docs/legend.md` both say it plainly: while a finding is `framing`, **any
session may write a decision, reject one, or refine one**, and *"a second reader
who disagrees with a decision improves it more."* It is one of the framework's
load-bearing claims about why the ceremony is worth it.

§11 gives `decisions.md` three header fields — `Bundle:`, `Session:` and a date —
and a five-column table: `#`, `Decision`, `Findings`, `Decided`, `Outcome`.
**There is no column for who decided**, and `Session:` is one field for a file
that may hold several sessions' work. The header is explicitly closed: *"no other
field appears in the header"*, and two field names are named as retired, so
adding one is not a session's call.

**Observed 2026-09-09.** `0047`'s `decisions.md` was opened by
`typed-bundles-architecture-20260908-204724`, which took D1. This session, which
owns the bundle from Revision 261, took D2, D3 and D4 into the same file. The
`Session:` field can name one or the other. It names the first, because that is
who wrote the file, and a sentence beneath the table carries the rest — **prose,
because prose is the only place the schema leaves.**

The mirror of it is already solved one document over: `findings.md` has a
**Contributions** table for exactly this, listing every session other than the
owner that added a finding **or contributed to a decision**. So the framework
records that a contribution to a decision happened and cannot record which
decision it was.

**What it costs to leave.** The Contributions table's third column is free text,
so today the fact survives where someone thought to write it and vanishes where
they did not — `0039`'s own first row says *"Recorded D5 against F7"* and its
second says only *"Added F21 and F22"*. **A decision's author is what a rejected
alternative is read against**, and it is the field the schema does not have.

**Not proposed here.** A sixth column, a per-section marker, or a `decidedBy`
field in `metadata.json` are three shapes and this bundle owns the choice. The
`metadata.json` decision objects have no author field either, so whatever is
chosen lands in both.

## F25 — the permission table has no row for `transferred`

*What another session may do* is the table a session reads before its first
write. It has three rows: `superseded`; `assigned`, `unclaimed`, `retired`; and
`analyzing`, `revisited`, `answered`. **Revision 239 made the three rows disjoint
so that no tie-break is needed**, and `docs/rules/README.md` lists eight
standings. Seven are in the table.

The missing one is `transferred`, and elsewhere the legend does answer it:
*Awaiting a first read* groups `un-started`, `reopened` and `transferred` and
says all three are **invisible to every session but the owner**. So the answer
exists, in a section about finding statuses, for the one value in that group that
is a bundle standing rather than a finding status — and the table a session is
told to read before writing does not carry it.

**The practice is the other way.** Revision 248 records this session's
predecessor writing F21, F22, F23 and D21 into `0039` **while `0039` stood
`transferred`**, deliberately and as contributions, and Revision 262 directs the
session that does not own `0039` to record an orphan rule in it — again while it
stands `transferred`. **This finding is that instruction being carried out**, by
a session reading a table that does not say it may.

Either the practice is wrong or the invisibility claim is too wide, and **the
table is the document that has to say which.** The likely shape is that
`transferred` gates the *owner's* first read and the transitions that depend on
it, and does not close the bundle to contribution — which is what `analyzing`
allows, and what a transferred bundle derives the moment its transfer clears. But
that is a reading, and this bundle owns it.

**What it costs to leave.** Two sessions have now written into a `transferred`
bundle on an instruction, with the rules as written saying they may not, and
neither wrote down the discrepancy. **A rule broken twice at the owner's own
direction is not a rule**, and the third session will either stop and ask or not
notice — and not noticing is worse.

---

## F26 — the legend says a status moves on a write, and also that reading is the transition

**`docs/legend.md` carries both rules, and they cannot both hold.** Three
statements in one file:

| Line | What it says |
|---:|---|
| 69 | *"Every arrow names the event that causes it, and every event is a change to the record. **A status does not move because someone read the finding.**"* |
| 199 | *"**Reading is the transition**; nothing else moves them"* — of `un-started`, `reopened` and `transferred` |
| 546 | *"A status moves on a write, not a read"*, in the Provenance table, citing this bundle's F12 |

`.github/session-management-instructions.md:680` sides with the minority:
*"The transfer ends when the target session reads the bundle."*

**Two rank-3 documents, three statements, and the tree follows the other one.**
Four index rows and two manifests written at Revisions 248 and 261 all say a
transfer clears on the target session's **first write as owner** — the phrase is
repository-wide, not one session's slip — and this session followed them rather
than §10 when it read all four of its bundles and cleared none.

**Line 199 is unverifiable by construction, and that is the second argument
against it.** `0045` F3 establishes that no instrument in this framework can see
which session is acting: a guard sees a tool call and a path, a checker sees the
tree, and neither sees a session. A read leaves nothing behind, so *the target
read it* can never be checked by anything. A write is a diff. **A rule that no
instrument could ever evaluate is `0039` F15's shape** — a check asserting
something it cannot see, passing vacuously.

**And line 199 has a live cost, not a theoretical one.** `0048` stands
`transferred` with all three findings `un-started`. Under line 199 this session's
reading of that bundle moved all three to `framing` in one operation, with no
judgement formed about any of them. **That is F12 exactly** — the mass edit that
moved twenty-one rows while every checker passed — reached by obeying the legend
rather than by neglecting it.

**Relates to F25**, which found the same table incomplete from the other side:
*What another session may do* has no row for `transferred` at all. F25 asks who
may write to a transferred bundle; this asks what ends the transfer. Neither
answers the other.

**What it costs to leave.** A session arriving at a transferred bundle reads §10,
reads the legend, and gets two answers — then reads five records that give a
third. It resolves the conflict by guessing, and the guess moves statuses.

## F27 — the rule is broken in the document that states it

`docs/legend.md`: *"No word appears in both vocabularies, and a schema check
asserts the two sets are disjoint."* And, of finding statuses and session
states, the same file lists **`withdrawn` in both.**

| | Where | Means |
|---|---|---|
| finding `status` | the six of *A finding* | work stopped; **anything the finding contributed while `framing` or `decided` is reverted**, by `git revert` against the commit, with an `APPLY-MANIFEST.md` entry naming what was reverted and why — §9a |
| session `state` | the five of *A session* | *"Shut down. No further work, ever."* |

They are not the same act. One reverts contributions and takes a reason from a
closed list of nine; the other ends a session and touches nothing it produced.
**A reader who learns one meaning reads the other wrong**, which is the exact
sentence the legend uses to explain why `superseded → DX` was retired as an
outcome.

**Nothing caught it, and the reason is `0047` F11.** The disjointness check built
at Revision 268 compares decision outcomes against three other vocabularies by
hand. Five exist, which is ten pairs; it made three, and **`session.state`
appeared in none of them.** Revision 272 rebuilds the guard over every pair, and
this is the one it finds.

**The guard now records it rather than repairing it.**
`test_every_vocabulary_pair_is_disjoint` asserts the rule with nothing excused
and is marked `expectedFailure`, so the suite reports
`OK (expected failures=1)` instead of going red for a defect no instruments
session may fix. **When this finding is resolved that test passes and `unittest`
reports an *unexpected success***, which is the signal to delete it.

### Which side moves

**The session side**, on three grounds, and this is a reading rather than a
decision — `docs/legend.md` is this bundle's session's.

1. **The finding sense is the more embedded and the more specified.** It has a
   procedure in §9a, a closed list of reasons, a revert requirement and a
   manifest entry. The session sense is one row and one sentence.
2. **The finding sense is load-bearing in the derivation.** `withdrawn` appears
   in `INERT`, in the `retired` and `answered` rows of the progress table, and in
   `derivation_table`. Moving it touches the ladder; moving the session value
   touches five files.
3. **`closed` already carries the orderly ending**, so the session vocabulary
   needs a word for *shut down, no further work, ever* that is not a synonym of
   a finding's.

**`dissolved`** is the suggestion: adjectival like `available`, `active` and
`closed`, terminal beside `closed` without being its synonym, and unused
anywhere in `docs/`. `terminated` is the runner-up and reads as a system event
rather than a decision; `lapsed` is too soft for *no further work, ever*;
`abandoned` implies neglect where the legend describes a deliberate act.

**One more thing about the same table, noticed while reading it.** The five
session states are `available`, `active`, `closed`, `handoff`, `withdrawn` —
four adjectives and **one noun**. `handoff` is the event, not the state the
session is in after it. It is the same class of defect and it is a smaller one,
so it is recorded here rather than given its own finding.

## F28 — `unclaimed` answers two questions, and one of them freezes 52 members

`docs/legend.md` says two things about `unclaimed` and they are not the same
thing.

| Line | What it says | Which question |
|---:|---|---|
| 319 | *"a bundle is `unclaimed` when **no session owns it**"* | **who owns this** |
| 367 | `assigned`, `unclaimed`, `retired` → **"nothing is readable"** | **what may be read** |

**The other two values in that row earn their place; `unclaimed` does not.** An
`assigned` bundle is unreadable because **every member is `un-started`** — the
row is derived from member status. A `retired` bundle is unreadable because every
member is `withdrawn`. **`unclaimed` is in that row for a reason about
ownership**, which says nothing about any member's status, and is therefore the
one cell in the table that does not follow from what is inside the bundle.

**Measured 2026-09-10.** Seventeen bundles stand `unclaimed`, holding **52 live
members**:

| Status | Count | What the table does to them |
|---|---:|---|
| `un-started` | 26 | correctly closed — nobody has read them |
| **`decided`** | **19** | **the deciding is closed and the reasoning is unreadable** |
| `framing` | 7 | open to every session by rule, and closed by this cell |

**Nineteen members carry accepted decisions that no session may read.** The
thinking was done, the alternatives were recorded, and releasing the bundle put
all of it behind a cell that was written about ownership. `0041` has five,
`0042` four, `0053` three, `0049` three, `0046` two, `0051` two.

**Releasing is a normal, correct operation and this is its cost.** Revision 264
released seven bundles when `assurance-coverage-20260908-204724` closed — §10a
followed exactly — and in one revision the tree went from one bundle in this
state to eight. **A procedure carried out correctly should not make a reading
unreadable.**

**The seven `framing` members are the sharpest case.** `framing` is defined as
*live and open, any session may read and record* — that is the property the
framework is proudest of, and the one that stops a near-duplicate being opened
beside an existing reading. **This cell revokes it for a reason that has nothing
to do with the finding.**

**What it costs to leave.** Two things, and the second is worse. A session that
needs what is in `0050` cannot read it, so it re-derives it or opens a
near-duplicate — which is the exact failure `framing`'s openness exists to
prevent. And **`0043`'s standing note is now unenforceable in general**: it says
the bundle is *deliberately open so another session can record rather than open a
near-duplicate beside it*, which is a property any bundle should be able to have
and which release silently removes.

**Relates to `0039` F21 and F25.** F21 records that this table carries rows under
contradictory rules and that the `retired`/`withdrawn` cells disagree with
section 3; F25 that it has no row for `transferred` at all. **This is the third
defect in one four-row table**, and the pattern is that the table mixes
*ownership* rows with *member-status* rows and does not say which it is doing.

**Relates to `0047` F1**, which is `un-started` and belongs to
`drift-and-the-write-boundary-20260909-053548`. That finding reads the same
defect from the instrument's side — `plan_findings_work.py:614` emits
`CLOSED-BUNDLE-LIVE-FINDING` with the detail *"0047 F1, which is undecided"*,
deferring to a ruling nobody had made. **This finding is the vocabulary half and
is not a decision on F1**, which is not this session's to take.

## F29 — a commit message outlives the patch it was written for, and nothing says it should not

§7 says take the revision number at apply time. It does not say what happens to a
message already handed over when the patch it named is not the patch that lands.
**Measured over the nine commits through Revision 295: six pass, three fail.**

| commit | subject | entries it adds | |
|---|---|---|---|
| `aea2006` | 295 | 295, 291 | pass |
| `c929a00` | 294 | 294 | pass |
| `c9f586b` | 293 | 293, 285 | pass |
| `905beed` | 292 | 292 | pass |
| `15069fe` | 291 | 290, 289 | **fail** |
| `eb8b6de` | 290 | *(none)* | **fail** |
| `8b45285` | 288 | 288 | pass |
| `777f468` | 287 | 287, 286 | pass |
| `889b8ac` | 285 | 284 | **fail** |

`636eba0` is the same failure earlier — titled *Revision 271*, carrying Revision
270's work.

**A commit may legitimately carry several revisions.** Revision 266 settled that,
so the test is **membership, not count**: `777f468` adds 287 and 286 under the
subject *Revision 287* and is correct. The discriminator is whether the subject's
own number is among them.

### Why a wrong subject cannot be taken back

`.share/check-manifest-revision.sh` has read commit subjects since Revision 278 —
`0047` F12, the third place a number is taken. **The subject consumes the number
whether or not any entry uses it**, and history is not rewritten by a session, so
the number is gone. `bin/verify-manifest-coverage.sh` names the two resulting
states, and `0050` F8, F9 and F10 record what happens next: the tool is correct,
nothing runs it, nothing says who repairs it, and **the only exit from `MISSING`
creates a permanent `ORPHANED`**.

So this finding sits upstream of that whole chain. Every row in
`verify-manifest-coverage.sh`'s report except `DUPLICATE` traces to a subject
line written against a patch other than the one committed.

### The two failure shapes are different acts

**`889b8ac` and `636eba0` are a message reused.** A block was handed over for one
patch and pasted onto another — the message outlived its subject.

**`eb8b6de` and `15069fe` are a change set split.** The message was right about
its own revision; the manifest entry simply was not in the commit. `eb8b6de` is
this session's, and its entry rode out two commits later in `15069fe`, which is
how one mistake produced two failing rows and one permanent `ORPHANED`.

Both are caught by the same one-line test, which is the argument for stating it
once rather than as two rules.

### What this does not decide

**The instrument is `0050` F7's** and is not built here. Writing the checker
first would mean inventing the rule inside it, which `0041` D1 and `0050` D2 both
refuse — and `0050` F7 says so explicitly, naming this section and this session
as where the rule belongs. This records the rule. Arming it is theirs.
