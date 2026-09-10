# Decisions — the findings-and-sessions architecture disagrees with itself

**Bundle:** `0037-findings-architecture-conformance`  
**Session:** `typed-bundles-architecture-20260908-204724`  
**Decided:** 2026-09-09

**This bundle had no `decisions.md` until now, and that is not an oversight.** Its
predecessor `0027` decided all seven findings and resolved them at commit
`88aed77`; Revision 224 removed the cloned copies from this bundle because they
were byte-identical to `0027`'s and headed with `0027`'s name, which is the clean
slate `0039` D12 requires. What the clone could not carry was that **`1c48deb`
then dropped the rules those resolutions had installed.** The three decisions
below are taken against the tree as it stands, not against `0027`'s.

## Decisions

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | The required-reading rule survives its home being deleted: it is restated in `.github/session-management-instructions.md` and binds every `prompt.md` written from now. **Existing prompts are evidence and are not rewritten** | F2 | 2026-09-09 | `accepted` |
| D2 | The migrated-bundle carve-out is restored: a bundle migrated from an already-closed record carries `resolutions.md` and no `decisions.md`, and its `resolutions.md` says so. **One decision answers this bundle's F5 and `0047` F4**, which are the same reading in two bundles | F5 | 2026-09-09 | `accepted` |
| D3 | F1, F3, F4, F6 and F7 were resolved in `0027`, regressed by `1c48deb`, and hold again against the files that replaced it. Each is resolved here against where its rule now lives, and the regression is named rather than smoothed over | F1, F3, F4, F6, F7 | 2026-09-09 | `accepted` |
| D4 | **A reading may conclude that the thing is sound.** `docs/legend.md` says a finding records a fact established as readily as a defect found, and *what it costs to leave* moves out of the definition of the object into `Severity:`. The two restatements drop the clause and defer to the legend | F8 | 2026-09-10 | `accepted` |
| D5 | **The architecture records are marked current-as-of, not repaired.** Each of the three gains a currency line naming the measured drift and stating the reasoning is retained. The watch is deliberately left unarmed, and the code is not corrected | F9 | 2026-09-10 | `accepted` |

## D1 — the required-reading rule survives, forward only

`0027` D2 scoped the rule to prompts that can still start a session and gave
`run-index-design` a reading order. `1c48deb` deleted §4d, so the rule has no
home and nine prompts now name the instruction set at lines 44, 37, 37, 25, 12
and 6.

**Rejected — let the rule die with §4d.** Defensible, and it nearly won: Revision
241 gave both prompts a table of contents, which does the same job better than a
mandatory first item. It loses the property the rule exists for, which is that a
session cannot begin without being told where the rules are.

**Rejected — retrofit all nine prompts.** Five belong to sessions that are
`closed` or `handoff`. A closed session's prompt records what that session was
told, and rewriting it is what §9 spends three prohibitions preventing.

**Not decided here**: where in the instruction set it lands, and whether the
table of contents Revision 241 added satisfies it. That is the carrying out.

## D2 — the carve-out is restored, and it answers two bundles

The sentence `1c48deb` dropped read:

```text
A bundle MIGRATED from an already-closed record carries `resolutions.md` and no
`decisions.md`, because the deciding happened before this lifecycle existed; its
`resolutions.md` says so.
```

Ten bundles are in that class today and read as non-conforming against a rule
nobody intends.

**Rejected — write `decisions.md` into the ten.** It would invent deliberation
that never happened, which is the evidence rule broken in the direction of
tidiness. `0047` F4 reaches the same conclusion independently.

**Rejected — leave it undecided.** It is the reason ten bundles fail a rule by
accident, and it has been undecided since Revision 203.

**The owner's standing preference is the opposite of this decision and is
recorded deliberately.** Retrofitting older evidence to match the current shape
is preferred wherever it is possible; here it is not, because the missing
document records deliberation that did not occur. **What is owed instead is a
migration plan requirement for breaking changes**, so that the next format change
states what happens to what predates it. Parked as `0052` F2.

**Edge asserted**: `0037/F5 co-decides 0047/F4`.

## D3 — resolved once, regressed, and resolved again

Five findings hold again, each against a different file from the one `0027`
closed them in. The regression is one commit — `1c48deb`, which split
`.github/copilot-instructions.md` and dropped fifteen rules with no decision
recording the removal, `0039` being the bundle for that.

**Rejected — reopen instead of resolve.** `reopened` reaches only what is
`resolved`, and these read `framing`: the clean slate put them there. The
vocabulary has no move for *resolved by a predecessor, regressed, and true
again*, and inventing one for five rows is not worth it.

**Rejected — resolve with `—` in `Resolved by`.** The citation would resolve to
nothing and §11 requires every `D<n>` cited to exist in this bundle. This
decision exists so the five rows can cite something real.

**What this decision does not claim**: that the regression was detected. It was
not. Nothing re-verifies a resolution once written, and that is parked as `0052`
F1.

## D4 — a reading may conclude that the thing is sound

**Accepted.** `docs/legend.md` gains the sentence: **a finding records a fact
established as readily as a defect found**, and **what it costs to leave** moves
out of the definition of the object into `Severity:`, where §11 already puts it.
The two restatements — §1 of the instruction set and §2 of
`findings-and-sessions.md` — drop the clause and defer to the legend rather than
repeating it, which also removes a copy from a file whose own opening says
*"Nothing here restates a definition."*

**Not a new status, field or subtype.** A finding that establishes a fact is
`framing`, `decided` and `resolved` like any other. `typed-bundles-and-work.md`
§4.3's admission rule disposes of the alternative directly — a new shape must
name a field no existing shape has, and this names none.

**Two rejections.** **Leave it and treat the seven conformant facts as prose**, as
this bundle already does — rejected because the prose apologises for itself
(*"stated first because the defects below are small against it"*) and because the
cost has already been paid once: `typed-bundles-and-work.md` §4.3 records a draft
narrowing the legend to *a reading of something that already exists and is wrong*,
which pushed research out of `findings` into `commission`. **A `conformance` genus
for readings whose answer is yes** — rejected on the same admission rule, and
because it would split one object by its conclusion, which is the property
`Severity:` records.

**The wording is what `0039` D23 carries.** D23 moves the history of all three
rule documents into a `Provenance` table and two of the three sentences sit in
documents it rewrites, which is why the owner parked D23 behind this bundle.
`0037/F8 constrains 0039/F14` is asserted and the parking is the owner's
direction, not derived from it.

## D5 — the architecture records are marked current-as-of rather than repaired

**Accepted.** Each of the three records named in F9 gains a **currency line** in
its header block, naming the measured drift and stating that the reasoning is
retained and the claims about the code are not current.
`findings-and-sessions.md` already carried a `Brought current:` line, so this
reuses a convention rather than inventing one.

**Why marking and not repairing.** F9's reading is that **an architecture record
is written once and then diverges with nothing watching** — not that any
particular sentence is wrong. Repairing the twenty-odd instances would file the
symptoms and lose the shape, which F9 says in its own last paragraph. A record
that says *this is what we decided and here is where the code has since gone* is
worth more than one silently corrected to match today's code, because the second
destroys the evidence that drift happened.

**What this decision does not do.** **It does not arm the watch.** The
`allocation-tooling` watch in `doc-currency.json` exists, points at exactly this
pair, and reports `UNCONFIRMED` because all seven watches carry
`"sourceDigest": null` and `doc_currency.py:evaluate()` tests the null before it
compares. That is **`0039` F22** and is a toolkit write gated on that finding
being decided. **Naming what an instrument should do is not doing it** — the same
boundary D26 kept at Revision 287.

**And it does not correct the code.** §4.2's missing `− w_hold`, the unenforced
`co-decides` constraint, the unimplemented topological invariant and `ask`
ignoring every flag are `0050`'s and `0045`'s territory. F9 measured them so the
reading can be checked; fixing them one at a time is what it warns against.

**One rejection.** **Rewriting the three records to match the code** — rejected
above, and rejected a second time on `0038` D5's ground: moving a working record
to match today's tree inverts which of the two is authoritative.
