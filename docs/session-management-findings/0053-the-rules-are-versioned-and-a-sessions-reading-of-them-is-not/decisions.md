# Decisions — the rules are versioned and a session's reading of them is not

**Bundle:** `0053-the-rules-are-versioned-and-a-sessions-reading-of-them-is-not`  
**Session:** `assurance-coverage-20260908-204724`  
**Decided:** 2026-09-09

Assigned by the owner on 2026-09-09 and read on assignment. The three findings
are one mechanism in three parts, and **the order they are carried out in is the
decision that matters**: coverage, then watches, then arming, then notification.
Any other order produces an instrument that reports nothing and looks correct.

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | Every watch is armed, and a watch that has never been armed is reported as a defect rather than as a state | F2 | 2026-09-09 | `accepted` |
| D2 | `references/`, `docs/rules/` and the unwatched architecture records and ledgers get watches, against the instruction sets, prompts and configs they describe | F3 | 2026-09-09 | `accepted` |
| D3 | A session records the blob it read each foundational document at, and *refresh* becomes a comparison rather than a re-read | F1 | 2026-09-09 | `accepted` |
| D4 | The notification is a hook that injects and never blocks, and it is built **last** | F1, F2, F3 | 2026-09-09 | `accepted` |

---

## D1 — arm them, and make an unarmed watch a defect

Seven watches, `sourceDigest: null` on all seven since Revision 232.
`doc_currency.py`'s `evaluate()` tests the null before it compares, so an unarmed
watch reports `UNCONFIRMED` and **can never reach `DRIFTED`**.

Arming is one command per watch. That is the whole of the work:

```text
./bin/verify-doc-currency.sh --confirm session-rules
```

**What must change beyond running it seven times.** Today `UNCONFIRMED` is
reported as a *state*, alongside `DRIFTED` and `current`, and the run's summary
line counts it separately — so seven never-armed watches read as a tidy
inventory rather than as an instrument that has never worked. **`UNCONFIRMED` is
not a state of the document; it is a defect in the watch**, and the report should
say so in those words.

**Rejected: arming them silently as part of another revision.** A digest is a
claim that a person read the dependents and found them current. `--confirm`'s own
output says so. Stamping seven of them to make a report green would make the
claim false at the moment it was recorded, which is `0041` F5 exactly — a status
asserting something nobody checked.

**So arming is a person's act, per watch, and D4 does not wait for it.** The
notification can report *this watch has never been armed* without the arming
having happened, and that is a more useful first message than silence.

## D2 — watch the categories that describe something else

F3's table is the scope: `references/` (11 files, none watched), `docs/rules/`
(1, none), `docs/architecture/` (11, 4 watched), `docs/ledgers/` (6, 1).

**The rule for what earns a watch is not *is it important*.** It is **does this
document describe something that changes without it** — which is the question
`doc-currency.json`'s own note asks, and the reason its edges are asserted rather
than inferred. `references/environment-variable-reference.md` describes
`reimage.env.example`; that file is already a **source** in the `environment`
watch and no edge reaches the reference. Three references are in that position.

**Not decided: the full edge list.** Each edge is an assertion that one document
describes another, and asserting eleven of them from a directory listing is
exactly the inference `doc_currency.py`'s docstring warns against — *"an inferred
edge is how a checker tells one project's game engine that another project's
intake docs need updating."* They are read one at a time, by someone who opens
both files. This decision fixes the scope and the rule; it does not manufacture
the edges.

**Sequencing: D2 waits on `0050` D1.** Until the coverage sweep can see
`references/` and `docs/rules/`, adding watches there cannot be checked for
completeness — the report would not list what remained uncovered.

## D3 — the missing operand is the baseline, not the hash

`git rev-parse HEAD:<path>` returns the blob any tracked file is at. That is
authoritative, free, and cannot go stale. **A manifest of those hashes,
refreshed by a commit hook, would be a second copy of a fact git owns** — the
same defect `0050` D1 removes from the coverage sweep, installed deliberately.

What has no home is the other operand: **which version this session read**. A
session's `metadata.json` gains `readAt`, path to blob and date, written when the
session reads. *Refresh* then names the files that moved instead of meaning
*read everything again*.

`docs/ideas/knowing-what-you-have-read.md` carries the shape, the first-run false
positive and what it cannot do. **It is a commission and this decision does not
build it** — `typed-bundles-and-work.md` §1 is where an intent to build goes, and
the bundle type that would hold the build does not exist.

**Rejected: inferring the baseline from the session's start commit.** A session
bundle records the commit it copied from, and the read could be assumed to be
that version. It is wrong in the case that matters: this session read the
instruction set at a commit, the file changed four revisions later, and the
session re-read *other* files. An assumed baseline would have reported no drift.

## D4 — a hook that injects, never blocks, and comes last

**Staleness is not a write-time property.** A document goes stale because a
different file changed, possibly commits earlier. A guard refusing a write
because some ledger is stale would block correct work constantly, and
`rule-enforcement-avenues.md` §6 sets the bar: warn-only, a clean pass, and only
then a refusal. This never reaches a refusal, because there is no write to refuse.

**Shape:** `SessionStart` injects the drift list and the never-armed list —
that is when a session establishes what it has read. `UserPromptSubmit` repeats
it and injects only when non-empty. Measured cost of the underlying check:
**0.029s**, so per-prompt is affordable.

**It must not key on the word *refresh*.** In the instance F1 records, the owner
did say refresh and the session re-read the wrong subset. A hook that fires every
turn and names what moved catches that whatever the owner types. **Keying on a
word makes the instrument depend on the phrasing of the person it protects.**

**Built last, and this is the decision, not a preference.** A hook over an
unarmed, under-covering watch reports nothing, forever, and looks like it is
working — which would make it the fifth member of `0050` F4, installed by the
session documenting that family. Order: `0050` D1, then D2, then D1, then this.

**What it cannot do.** It injects text. A session that skims the injection fails
identically to one that never received it. The avenue is `guard` for the
notification and `person` for the reading, and claiming more would be `0041` F2.
