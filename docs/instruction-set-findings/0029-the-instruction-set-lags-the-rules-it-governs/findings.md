# The instruction set lags the rules it governs

**Recorded:** 2026-09-03, restore-apps session
(`session_016EbjB7M527qEFqZFzpv2C9`), from its own outstanding items rather than
from a fresh reading. Every finding below was noticed by this session while
writing Revisions 166 through 173, and deferred in prose at the time.
**Relates to:** `0027` — that bundle read the instruction set for conformance and
found seven defects. This one collects what this session left owed. They overlap
at one point only, named in finding 2.
**Decide after:** `0027`, then `0028`. Findings 1, 2, 5 and 6 below are four
symptoms of one question `0027` finding 1 owns — *where is a rule allowed to
live* — and deciding them first would decide against a surface about to move.
`0028`'s resolution adds to finding 1's list rather than changing it. Finding 7
is about this line existing at all.
**Severity:** findings 1 and 5 are high. A session that reads only the
instruction set does not learn five of the rules it is expected to follow.
**Scope:** instruction-set. The fix lands in `.github/copilot-instructions.md`
§§4b–4d, `.claude/CLAUDE.md`, and `docs/architecture/findings-and-sessions.md`.

**This bundle is a self-report.** Five of its six findings are rules this session
wrote into `docs/legend.md` and did not carry into the instruction set, each time
with a line saying the adoption was owed. Six such lines is not a backlog, it is
a pattern, and finding 5 is about the pattern rather than any one instance.

---

## Finding status

The bundle advances with its first row and reaches `resolved` only with its last.
`resolving` cannot begin until every row reads `yes` under Decided, and nothing
outside `docs/` is written until then — which for this bundle is the whole of the
work, since every fix is a toolkit write.

| # | Finding | Decided | Status |
|---:|---|---|---|
| 1 | Five rules exist only in `docs/legend.md` and not in the instruction set | — | `unresolved` |
| 2 | Two rules exist in both, in different words | — | `unresolved` |
| 3 | §4b's directory list is now wrong | — | `unresolved` |
| 4 | The architecture record describes two findings trees; there are three | — | `unresolved` |
| 5 | Nothing tells a session that `docs/legend.md` is normative | — | `unresolved` |
| 6 | State names and state requirements live in different files | — | `unresolved` |
| 7 | The vocabulary cannot say that one bundle must be decided before another | — | `unresolved` |

---

## 1 — five rules exist only in `docs/legend.md`

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

## 2 — two rules exist in both, in different words

`resolving`'s gate and the bundle-advance rule are in §4c *and* in `legend.md`,
written twice in different prose by the same session in Revisions 166, 168 and
172. Nothing keeps them in step.

**This is where this bundle touches `0027`.** That bundle's finding 6 records
that the two session-state diagrams disagree; this is the same failure on the
status side. They are separate instances and should be decided together — if the
answer is a rule about where a rule may live, it covers both.

## 3 — §4b's directory list is now wrong

§4b enumerates the directories under `docs/` and gives a count. It said five,
then six, then seven across Revisions 160 to 163, and reads six today.
`docs/instruction-set-findings/` makes seven, and this bundle is in it.

The count in prose is the defect, not the arithmetic: it has been wrong after
four of the last six revisions that touched `docs/`, because a number in a
sentence has to be maintained by whoever adds a directory and nothing checks it.

## 4 — the architecture record describes two findings trees

`docs/architecture/findings-and-sessions.md` §2 names
`docs/runbook-findings/<runbook>/` and `docs/cross-cutting-findings/` and gives
the test for choosing between them. There are now three, and the test is a
two-way one.

Its §12.3 also asks where a finding whose subject is not the project should go —
an open question that this tree partly answers and partly does not, since an
instruction-set finding is still about this project.

## 5 — nothing says `docs/legend.md` is normative

The instruction set points at `legend.md` for the status and state vocabularies,
and `legend.md` describes itself as where they are defined. Neither says it is a
file a session must read before working, and both indexes present it as a place
to look things up.

That is how five rules ended up somewhere sessions are not told to look. The
question this finding asks is not *where should the rules live* but *what tells a
session where the rules live* — and today the honest answer is that a session
learns it by being told in conversation, which is the failure mode this entire
architecture exists to remove.

## 6 — state names and state requirements are in different files

Revision 162 moved the status and state definitions out of §§4c–4d into
`legend.md` and left the per-state requirements — what `owned` records, what
`handoff` must carry, what `closed` and `withdrawn` owe — in §4d.

So a session reading §4d finds out what `handoff` requires without finding out
what `handoff` means, and a session reading `legend.md` finds the reverse. Both
are correct; neither is sufficient. Smallest of the six, and the one most likely
to be swept up by whatever answers finding 5.

## 7 — the vocabulary cannot express decision order

`Relates to` was added in Revision 173 and says that two bundles bear on each
other. It has no direction and no ordering, and the first three findings bundles
to use it needed both: `0029` must be decided after `0027`, because four of its
findings are downstream of `0027` finding 1, and after `0028`, whose resolution
adds to `0029` finding 1's list.

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
conversation, which is what finding 5 is about.

Three shapes, none chosen:

- **A `Decide after:` header line**, as used here. Explicit, and a session picking
  the bundle up sees immediately that it should not start.
- **Nothing in the bundle; the owner sequences the work.** Honest, and it puts the
  knowledge back where finding 5 says it should not be.
- **Carry it in the `Relates to` clause** — *"decide that first, four of these are
  downstream of its finding 1"*. No new vocabulary, weaker guarantee, and it
  overloads a pointer that deliberately obliges nobody.

Whichever is chosen, it should be decided with finding 5: both are about what a
session can learn from the tree without being told.

---

## What this bundle does not cover

`0027`'s seven findings, which are a separate reading of the same surface by a
different session and are owned separately by this one. Where the two meet is
named in finding 2 and nowhere else.
