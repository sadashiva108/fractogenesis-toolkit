# Session management — start here

> **Role.** The front door. What this framework is, what it is made of, and the
> order to read it in.
>
> **Authoritative for** nothing except the section *What nothing else tells you*,
> which has no other home. Everywhere else it **points**; where it disagrees with
> what it points at, the other wins.
>
> **Rank 4** of 6 — a convenience, like a prompt. Order in
> [`../../.github/copilot-instructions.md`](../../.github/copilot-instructions.md).

---

## 1. What this is

A way of recording work so that it survives the session that did it. It is
**project-agnostic and reusable as-is**: nothing in it is about this repository's
subject.

Three objects and one loop.

| | |
|---|---|
| a **finding** | one reading of one thing. It carries a status and moves through it: `un-started → framing → decided → resolved` |
| a **findings bundle** | a numbered directory of findings that belong together. Its **standing** is *derived* from them — never typed |
| a **session** | a unit of work with an owner. It owns bundles; its **state** derives from what it owns |

**The loop.** A session reads something and records findings. Any session may
sharpen a `framing` finding or write a decision on it. The owning session closes
the deciding — `decided` — then carries the decision out, writes what it did, and
moves the finding to `resolved`. **In that order**: the row is the evidence the
status asserts.

**Why the ceremony.** Two properties, and everything else serves them. A reading
is written once and never rewritten to match what was later decided — so the
record shows what was believed, not only what was concluded. And **a decision
keeps the alternatives it rejected**, because a decision without them is an
assertion.

### What a bundle's standing can be

**Never typed.** `./bin/plan-findings-work.sh stamp` derives it from three things
in this order — lineage, then ownership, then how far the findings have got — and
writes it. The ladder and the definitions are `docs/legend.md`; this is the shape.

| Standing | When |
|---|---|
| `superseded` | a later bundle replaced this reading whole. **Declared**, not derived from findings |
| `unclaimed` | no session owns it. Parked, and closed to everyone until the owner assigns it |
| `transferred` | handed to a named session that has not yet written to it **as owner** |
| `assigned` | owned, and nobody has written to a finding in it yet |
| `answered` | every finding is `resolved` or `withdrawn`, and at least one is `resolved` |
| `revisited` | at least one finding is `reopened` and every other one is finished |
| `retired` | every finding is `withdrawn` |
| `analyzing` | anything else. **It is the fallthrough**, so a derivation bug lands here and looks plausible |

## 2. Where to start

In this order. The line counts are so you can budget, not a warning.

| # | Read | Lines | For |
|---:|---|---:|---|
| 1 | [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md) | 73 | the router: which set governs what, and **the precedence order** |
| 2 | [`docs/legend.md`](../legend.md) | 554 | every status, standing and state. **The vocabulary is not guessable** |
| 3 | [`.github/session-management-instructions.md`](../../.github/session-management-instructions.md) | 979 | the procedure. **Section 0 is the working cycle and is not optional** |
| 4 | [`docs/INDEX.md`](../INDEX.md) | 48 | the map of `docs/`, then the INDEX of whichever tree you work in |

Then the prompt for your kind of work, under
[`.github/ai-prompts/`](../../.github/ai-prompts/). A session is opened by pasting
the conformant prompt and a session-specific one.

**Three vocabularies, three words, no shared values.** A finding has a **status**,
a bundle has a **standing**, a session has a **state**. So a bare value says which
set it came from: `framing` is a finding, `analyzing` is a bundle. `resolved` is a
finding reaching its end; `answered` is the bundle standing derived from that.

## 3. When two documents disagree

The router carries a six-rank precedence order, stated once and nowhere else, and
every rule document's masthead names its own rank. **A document that disagrees
with something above it is a defect, not a rule** — record it rather than follow
it.

## 4. The working cycle, in one breath

Compose in a scratch copy outside the owner's checkout · verify there · produce a
patch · report a review, not a diff · **wait** · apply only on *write it* · the
owner stages and commits. Section 0 has it properly.

## 5. Seeding a new session

**The bundle exists before the session does.** A session cannot create its own,
because ownership is derived by scanning `findings-manifest.md` across
`docs/sessions/` — so a prompt saying *you own these* is not ownership. Whoever
opens the work creates the bundle first; the person pastes the prompts second.

**This paragraph is the only place that says so.** The instruction set's §5 gives
the layout and never says who creates it or when. `0039` F9 is the standing
warning about a rule with no home.

1. **`docs/sessions/<title>-<stamp>/`.** `<stamp>` is `YYYYMMDD-HHMMSS` in
   **America/New_York** — the zone is named because a session almost never runs
   in it, and *local* read as the session's own puts the stamp hours out. **The
   name is fixed at creation**; renaming breaks every prompt, handoff and index
   row written against it.
2. **`prompt.md`** — the conformant half and the session half, together. It names
   the instruction set before anything else it asks for.
3. **`metadata.md`** — `## Owners`, `## Environment`, `## Resources`,
   `## Contributions`. **Leave the Owners row empty and say in the file that it is
   empty on purpose.** Only the session knows its identifier, the model it was
   configured for and the environment it actually ran in; filling those in
   advance is inventing a fact, and a placeholder belongs in a template, never in
   a record. The session fills the row on its first write.
4. **`metadata.json`** — the same facts as data. `ownedBundles` empty unless
   bundles are being assigned at the same time.
5. **A row in `docs/sessions/INDEX.md`.**
6. **Assigning a bundle is adding its row to `findings-manifest.md`.** That row
   *is* the assignment — nothing else sets ownership, and removing it is the
   release. Update the counts on both sides.
7. **One `APPLY-MANIFEST.md` revision covers the whole thing.**

Then open a fresh chat and paste the conformant prompt followed by the session
prompt. A session that has to be told something not in those two files is a
finding against them.

## 6. What nothing else tells you

**Everything above points somewhere. This section does not, because these have no
other home** — each cost a session real time to learn, and none is written down
anywhere else.

**The tiebreak is the code, not a document.**
`.internal/ai-scripts/session-management/plan_findings_work.py` holds the closed
sets and the derivations. When the legend, a prompt and the code disagree, the
code is what the data was stamped from. Documents have trailed it more than once.

**You never type a derived value.** `standing`, `progress` and `state` are written
by `./bin/plan-findings-work.sh stamp` **and by nothing else**. `check` reports
`UNSTAMPED` for a null and `STORED-DISAGREES` for a value that has come adrift. A
hand-edited status is a defect the next `check` names.

**Quote `MISSING`, `FAIL`, `WARN`. Never quote `OK`.** The `OK` totals move
whenever anyone parks a note, which is what made them useless as a signal. And
know the standing baselines before you read a number as a regression — as of
Revision 258, `headers` reports 11 FAIL, all of them in `0030` and `0035`, and
runbook structure reports 25 FAIL across 27 documents.

**Run the checks in your scratch copy, never in the owner's checkout.**
`bin/verify-doc-paths.sh` shells out to git, and git takes a lock to read. On a
mounted connected folder the lock cannot be cleaned up, so a `.git/index.lock` is
left behind that blocks the owner's next commit. In the checkout: `ls` and `cat`.

**More than one session runs at a time, and three files collide.**
`APPLY-MANIFEST.md` and the two `INDEX.md` files are the ones every session must
write, and `git add <path>` takes a whole file. Take a revision number and a
bundle number **immediately before writing**, not while composing — both have
been taken out from under a session mid-compose. Expect to rebase.

**A session closes its own deciding.** In the legend's permission tables *the
owner* means **the owning session**, not the person. A session may read, decide
with its alternatives recorded, carry out and compose. **The person's gate is the
commit**, which is why a session never runs `git add`, `git commit` or `git push`.

**Read the tree before you write the finding.** Findings here are routinely
answered by changes made elsewhere with nothing recording it — on 2026-09-09 that
was true of five findings in `0037`, four in the assurance session's bundles, and
two thirds of `0039` F14. **Check what a finding claims against the tree as it
stands now**, not against the tree it was written against.

## 7. The map

| | |
|---|---|
| `docs/legend.md` | the vocabulary |
| `.github/session-management-instructions.md` | the procedure |
| `docs/rules/` | records **about** the rules — this file, and where a rule can be enforced |
| `docs/*-findings/` | four trees, one numbering sequence, indexed per tree |
| `docs/sessions/` | one directory per session: its prompt, who owned it, what it owns |
| `docs/architecture/` | design that outlives a session. Cited, not obeyed |
| `docs/ledgers/` | dated statements of what exists. Re-derived wholesale, never patched |
| `APPLY-MANIFEST.md` | one entry per change. Point-in-time evidence, never retro-edited |

## Provenance

**This file states what is; why each part is what it is lives in the bundle that
decided it.** Nothing here changes a definition.

| Part | Where the reasoning lives |
|---|---|
| That this file exists at all | `0039` F14 — nothing was written for someone arriving cold, and the entry point was a 724-line instruction set. It is 979 now |
| Under `docs/rules/` rather than in the root `README.md` | `0039` D22. The root README is this project's; the framework claims to be reusable as-is, so its door travels with it. Extending the root README, and declaring the router the door, were both rejected |
| *What nothing else tells you* | The one section authoritative for its own content, because none of it has another home. `0039` F9 is the standing warning about what happens when a rule has no shelf |
| Three vocabularies, three words | Revision 233 |
| The eight standings, given as a derivation rather than definitions | `docs/legend.md` owns the ladder and the meanings; a second set of definitions here would be a copy nothing checks. `0043` F2 is why that matters |
| *Seeding a new session*, step 3 in particular | This session left its own Owners row empty at Revision 237 and filled it at Revision 239, which is the placeholder rule holding under pressure rather than being recited |
