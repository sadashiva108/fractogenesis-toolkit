# Prompt — drift-and-the-write-boundary

## The conformant half

**Read [`.github/session-management-instructions.md`](../../../.github/session-management-instructions.md) before anything else this prompt asks for.**
Section 0 is the working cycle and it is not optional: compose in a scratch copy
outside the owner's checkout, verify there, produce a patch, report a review,
**wait**, and apply only on *write it and provide a commit message*. The owner
stages and commits. This session does not `git add`, `git commit` or `git push`.

Then [`docs/rules/README.md`](../../rules/README.md), and *What nothing else
tells you* in particular — eight facts with no other home. **Two of the eight are
your subject matter**, so read them as findings rather than as advice: that
`standing`, `progress` and `state` are written by `stamp` and by nothing else,
and that `bin/verify-doc-paths.sh` shells out to git, so running the checks in
the owner's checkout leaves a `.git/index.lock` that blocks the owner's next
commit.

Opened against the set as it stood at **Revision 261**, and amended at 262.

**Three things about the conformant prompt, and it is not pasted to you.**

**1. Nothing about this framework loads automatically.** What arrives with the
session is the repository's Copilot instructions — build commands, architecture,
runbook and script prompts — and **they do not mention session management at
all.** `.claude/CLAUDE.md` names the framework by path, but that is Claude Code's
auto-load convention in the checkout and is not something to rely on here. **The
two files named above are your orientation, and there is no other.**

**2. It is a copy, and it is behind.**
`.github/ai-prompts/session-management/conformant-prompt.md` is **rank 4** and
declares itself *current as of Revision 221* — read the head of
`APPLY-MANIFEST.md` for how far behind that now is; it was **41 revisions** when
this prompt was written. Where it disagrees with `docs/legend.md` or an
instruction set, **the home wins and the copy is the defect** — report it rather
than follow it. Its *Create your session bundle first* is one such: **your bundle
already exists** — this file is in it.

**3. Read it as a cross-check, not as an authority.** Read it **once and late**,
after the instruction set and the front door rather than before, and read it
looking for two things: **a rule with no home**, and **a rule whose home says
something different.** Its masthead claims every rule in it lives in the legend
or an instruction set, and **nothing verifies that claim** — which is why this is
worth twenty minutes rather than a skim. Its **Part 6, *What is in flight right
now*, is the one part of the file that is not a copy of anything**, and therefore
the one part with nothing to correct it: treat it as dated context, never as
state.

Anything you find with no home belongs in **`0039`, which is not yours.** Record
it as a **contribution** and put the row in your `metadata.md` Contributions
table. A contribution is not an act of ownership and does not let you decide it.


## The session half

**You are the instruments session. Your subject is the tree's own state and the
tree the owner commits from.**

You own `0038`, `0047`, `0052` — 3 bundles, 16 live findings. `0038` and `0047`
were transferred from `typed-bundles-architecture-20260908-204724` at Revision
261; `0052` was recorded by that session, left `unclaimed`, and is **assigned**
to you here at the owner's direction.

The three are one subject seen from three sides:

| | |
|---|---|
| `0038` | **the working tree is a shared resource with no lock on it.** Two sessions' uncommitted work interleaves in `APPLY-MANIFEST.md` and the two `INDEX.md` files, and `git add <path>` takes a whole file. F1–F5 are the consequences; F6 is the write-kind distinction the discipline does not make; F7 is where a rule is guardable at all |
| `0047` | **the drift inventory.** Seven live findings: three states the tree can reach that no check looks for, and three defects in the checker itself. F4 is `resolved`; F5 is the sweep's own false positives, 65 of 77 correct by construction |
| `0052` | **nothing re-verifies a resolution, and a breaking change has no migration plan.** F1 is not an argument — commit `1c48deb` reverted seven resolved findings in `0037` and nothing noticed. 36 findings read `resolved` and nothing establishes that any still does |

### Your jobs, in order

1. **`0047` F7 and F8 first, because they are the shortest path to a tree that
   stops lying.** Both are in
   `.internal/ai-scripts/session-management/plan_findings_work.py`, one function
   apart. Line 439 treats `transferred` as `unclaimed` and reports a **permitted**
   transfer as a conformance failure — it has been firing since Revision 248 and
   will fire again on Revision 261's two transfers. `OUTCOMES` accepts the retired
   `superseded → DX` and rejects `proposed`, `deferred`, `retracted` and `voided`,
   four of the seven the legend defines — **so the default value fails its own
   check**, unnoticed because no decision yet uses one of the four.
   **The tiebreak is this file, not any document**, so a change here changes what
   the tree means. Read `docs/rules/README.md` section 6 before you touch it.

2. **`0047` F1, F2, F3 and F5** — the drift the tree already carries. F5 is the
   instrument's own defect and must be fixed before its output can be quoted, or
   every number after it is argued against 65 false positives.

3. **`0052` F1.** A resolution is checked once, by the session that writes it, and
   every later change can falsify it. This is the finding that would have caught
   `1c48deb`. It pairs with `0047`: a re-verification is a drift check with a
   longer baseline.

4. **`0038` F1–F5**, the working-tree findings, and **F7**, which is the
   guardability test — a rule is enforceable at write time only where the fact is
   in `metadata.json`, the actor identifies itself, and a false refusal costs less
   than the rule. Four rules pass all three and none is built.
   `docs/rules/rule-enforcement-avenues.md` is the record behind it.

5. **`0052` F2** last. A migration-plan requirement is a rule about how other
   work is done, and it should be written after you have watched three of these
   go past rather than before.

**Before any instrument goes in, two disciplines that are already findings.**
`0047` F6: **a guard fails where a checker only reports** — six instruments here
have reported failure against a healthy tree on their first run, and a checker
that does that wastes an hour where a guard stops the work; so a guard is
installed **warn-only until a clean pass**. And quote `MISSING`, `FAIL` and
`WARN`, never `OK`; the standing baselines as of Revision 258 are 11 `headers`
FAIL, all in `0030` and `0035`, and 25 runbook-structure FAIL across 27
documents.

### What is not yours

`0037`, `0039`, `0045` and `0048` belong to
[`entity-model-and-vocabulary-20260909-053548`](../entity-model-and-vocabulary-20260909-053548/),
opened in the same revision as you and **on the critical path**. **The boundary
is the three rule documents**: `docs/legend.md`,
`.github/session-management-instructions.md` and
`.github/ai-prompts/session-management/conformant-prompt.md` are **theirs** —
their vocabulary, their history, and `0039` D23's provenance extraction across
all three, which is parked until the entity model settles.

**You may write procedure into sections 0 and 6 of the instruction set** —
`0038`'s findings land there and nowhere else — and when you do, **say so in your
review**, because D23 will rewrite the paragraphs around it and the other session
will not otherwise know your text is there. Do not touch the vocabulary, the
`Provenance` tables, or any read-trigger prose.

`0040`, `0041`, `0042`, `0044`, `0046`, `0049`, `0050`, `0051` and `0053` belong
to `assurance-coverage-20260908-204724`. Do not read or write those bundles;
route anything you need through the owner. **One edge crosses to them**:
`0049/F1 relates-to 0038/F1`. `relates-to` carries no dispatch constraint, so you
are not blocked.

### Do not wait on the other session

Nothing you own is blocked by anything they own. The one edge that used to
constrain this set — `0037/F1 blocks 0047/F4` — is discharged: F4 is `resolved`.
