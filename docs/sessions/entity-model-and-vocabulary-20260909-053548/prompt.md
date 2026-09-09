# Prompt — entity-model-and-vocabulary

## The conformant half

**Read [`.github/session-management-instructions.md`](../../../.github/session-management-instructions.md) before anything else this prompt asks for.**
Section 0 is the working cycle and it is not optional: compose in a scratch copy
outside the owner's checkout, verify there, produce a patch, report a review,
**wait**, and apply only on *write it and provide a commit message*. The owner
stages and commits. This session does not `git add`, `git commit` or `git push`.

Then [`docs/rules/README.md`](../../rules/README.md), and *What nothing else
tells you* in particular — eight facts with no other home, each of which cost a
session real time to learn.

Opened against the set as it stood at **Revision 260**.

**Two things about the conformant prompt, before you follow it.** It declares
itself *current as of Revision 221* and the tree is at 260, so its currency line
is 39 revisions behind; it is rank 4, a copy, and where it disagrees with
`docs/legend.md` or an instruction set the home wins and the copy is the defect.
And its *Create your session bundle first* does not apply to you: **your bundle
already exists** — this file is in it — because ownership is derived from a
manifest row and a prompt saying *you own these* is not ownership
(`docs/rules/README.md` section 5).

## The session half

**You are the entity-model session, and you are the critical path.** Two
campaigns are parked behind you and neither may start until your work is settled.

You own `0037`, `0039`, `0045`, `0048` — 4 bundles, 24 live findings, transferred
from `typed-bundles-architecture-20260908-204724` at Revision 261.

You carry [`docs/architecture/typed-bundles-and-work.md`](../../architecture/typed-bundles-and-work.md),
**a DRAFT, not a design to be built.** Sections 2 and 3 are firm; argue with the
rest.

The model as it stands:

```
findings   — a reading of something that EXISTS. Research belongs here.
             Items F1..Fn. Terminates at `answered`.
commission — an INTENT TO BUILD. Produces a blueprint under docs/architecture/.
             Items Q1..Qn. Terminates at `answered`.
the third  — implement / refactor / retrofit / bugfix / verify. The kind IS
             the type. Items are tasks, T1..Tn. NAME UNDECIDED.

A doing bundle is dispatchable only when every bundle it `serves` is `decided`.
An answer may be followed by nothing, by a doing bundle, or by another
reasoning bundle it `evidences`. The graph is directed, not a pipeline.
```

### The order is fixed, and it is why this session exists first

The owner has ruled: **vocabulary and entities → directory structure → `0039`
D23 → build.** The directory structure is *derived from* the entity model, so it
cannot precede it. What is parked behind you:

- **`0039` D23** — the provenance extraction across the three rule documents,
  carrying **23 retired read-trigger sites** (legend 13, instruction set 4,
  conformant prompt 5, session prompt 1). Decided at Revision 257, deliberately
  not carried out. **Do not start it until jobs 1–4 below are settled**, because
  it rewrites the paragraphs your vocabulary decisions land in.
- **The relocation** proposed in
  [`docs/ideas/the-collection-and-the-project.md`](../../ideas/the-collection-and-the-project.md),
  Revision 260 — one root for the collection, the bundles flattened, the
  classification moved into `metadata.json`. It is a commission, nothing in it is
  decided, and its section 5 is a direct input to job 3 below.

### Your jobs, in order

1. **`0037` is owed one more reading, and it is the first thing to record.**
   `docs/legend.md` never says that **a finding may record a fact established,
   not only a defect** — and that *what it costs to leave it* is severity's
   business, not the statement's. `0037` is where it belongs, as **F8**. The
   bundle currently stands `answered`; adding F8 takes it back to `analyzing`,
   and **that is correct rather than a regression** — say so in the note, because
   the next reader will see a closed bundle reopen and wonder.

2. **`0045` and `0048` against section 4.6.** The session/agent boundary is only
   as good as what a session record can say about itself. `0045` F1 —
   *`available` means two different things* — has now produced **two** live
   instances: `typed-bundles-architecture-20260908-204724`, created owning
   nothing with no way to say *assigned and not yet started*, and **this bundle,
   which was created before its session and derives `active` on day zero**.
   `0048` F1 blocks F3: what to capture cannot be settled before it is agreed
   that nothing is captured.

3. **`metadata.json` shapes for `commission` and for the third genus**, against
   [`docs/architecture/state-as-data.md`](../../architecture/state-as-data.md)
   sections 4.2, 4.3 and 11.1. **`docs/ideas/the-collection-and-the-project.md`
   section 5 is an input, not a competitor**: it proposes `findings.md` →
   `blueprints.md` → `tasks.md`, `decisions.md` and `resolutions.md` common to all
   three, and `findings[]` → `members[]`. Decide whether `members[]` is the shape
   before anyone writes a second genus, because renaming it afterwards is a
   breaking change with no migration plan, which is `0052` F2.

4. **The third genus has no name and section 5.1 of the commission says every
   short word is taken.** `order` 327, `build` 198, `works` 185, `doing` 141,
   `charge` 9 and already meaning a session's brief; `undertaking` and `venture`
   are clean and long. **This is the owner's to settle, not yours** — put the
   choice to them with the count table, and do not adopt a word by using it.
   Note the position the outgoing session held and did not get to test: section
   4.2 says *the kind IS the type*, so **no umbrella word is written into any
   record today** — what would force one is a directory layout partitioned by
   shape, which is the commission's proposal and not the draft's.

5. **Open question 6.4 — what checks breadth.** Section 3 makes breadth the
   load-bearing property of the whole design and nothing verifies it. The
   candidate in the draft is a `check` that fails when a decision has no rejected
   alternatives, which would fail today, on purpose.

6. **`0039`'s remaining fourteen `framing` findings**, and only then D23.

**Do not implement.** Building is a doing bundle and those do not exist yet.

### What is not yours

`0038`, `0047` and `0052` belong to
[`drift-and-the-write-boundary-20260909-053548`](../drift-and-the-write-boundary-20260909-053548/),
opened in the same revision as you. **The boundary between you is the three rule
documents**: `docs/legend.md`, `.github/session-management-instructions.md` and
`.github/ai-prompts/session-management/conformant-prompt.md` are **yours** —
their vocabulary, their history and D23's extraction. That session may write
procedure into sections 0 and 6 of the instruction set and is told to announce it
rather than assume you will notice.

`0040`, `0041`, `0042`, `0044`, `0046`, `0049`, `0050`, `0051` and `0053` belong
to `assurance-coverage-20260908-204724`. Do not read or write those bundles;
route anything you need through the owner.

**`0043` is the one you will want and do not have.** *Framework state lives in
documents, not data* — nine findings, seven live — is the data-model reading job 3
rests on, and it is owned by `session-management-re-evaluation-20260906-110105`,
which stands `handoff` with no successor. It is **deliberately open**: you may
record into it, and you may not decide in it. Its section 11.3 — *who may assert
an edge* — is unresolved and gates the edge work. **Put its ownership to the
owner in your first exchange**; do not assume it.

### One correction the outgoing session made about itself, on the record

It argued the relocation should come before the entity model. That was wrong and
the owner's ordering corrects it. What it had right was only that the relocation
must not come **after** implementation.
