# Lumen — the interviewer: how the next question is chosen

> **Written before the genus rename, and checked against it at Revision 274.**
> Its measurements were taken against the tree and are current. Its vocabulary
> predates `members[]` and the four genera, so where it says *finding* it means
> what [vocabulary.md](vocabulary.md) now calls a **member**, and where it names
> a *bundle* the unit noun is under review. **No contradiction with the current
> vocabulary was found in it** — the check was for the session state `withdrawn`,
> which is now `dissolved`, and for the retired `findings[]` key. Neither
> appears. `vocabulary.md` is authoritative where the two ever disagree.
> **Role:** the reference for `bin/plan-findings-work.sh ask` and the selection it
> performs. Authoritative for the interviewer's *mechanism* — what reaches the
> frontier, what is dropped and under what test, how a candidate is scored, and
> what the run does when the score does not separate two candidates. It is **not**
> authoritative for design intent; `docs/architecture/allocation-and-inquiry.md`
> section 5 owns that, and where the two disagree this document names both and
> follows the code, per the repository's own rule: *when the legend, a prompt and
> the code disagree, the code is what the data was stamped from.* Every figure
> below was measured on 2026-09-09 against the tree.

## Contents

- [1. What it is for](#1-what-it-is-for)
- [2. The frontier](#2-the-frontier)
- [3. The six stages](#3-the-six-stages)
- [4. Ties](#4-ties)
- [5. Running it](#5-running-it)
- [6. What is designed and not built](#6-what-is-designed-and-not-built)
- [7. Open questions](#7-open-questions)

---

## 1. What it is for

The owner's complaint is worth quoting first: *my instructions seem ignored or
incomplete, lots of wasted cycles to get something half decent.* That reads like
an obedience problem and it is not one. An instruction is ignored when it was
never specific enough to obey, and it was never specific enough because the
exchange that would have made it so never happened. Fourteen vague turns produce
a half-decent thing; one precise turn produces the thing. **The interviewer
exists to convert the first into the second by deciding which single question is
worth the owner's turn.**

That is a selection problem. At any moment the tree holds many things that could
be asked, and most cannot honestly be asked yet — the work they sit on is
unfinished, nobody owns them, or a rule written down elsewhere already settles
them. Asking one of those spends a turn and returns nothing.

**Narrowing is only safe when what it narrowed away is written down.** That is
why `cmd_ask` prints a drop line before it prints a question. A selector that
shows its answer and hides its rejects is indistinguishable from a broken one:
you cannot tell a frontier of one from a frontier of a hundred, nor "nothing else
was eligible" from "everything else was silently lost". Section 2 shows the drop
line as printed is partly wrong — exactly the failure this discipline exists to
expose, and it exposed it. The tool proposes and never assigns; no `ask` path
opens a file for writing.

[&#8593; Contents](#contents)

## 2. The frontier

`frontier(g)` builds the candidate set. It applies two tests, in this order:

1. **Status.** A finding reaches the frontier only if its `status` is `framing`.
2. **Blocked.** A finding is marked blocked if a `blocks` or `evidences` edge
   points at it *from* a bundle whose progress is not `resolved` or `withdrawn`.
   Blocked findings stay on the frontier and score zero.

Ownership is recorded but is not a frontier test — `owned = b.get("ownership") is
None`, and in `OWNERSHIP = (None, "unclaimed", "transferred")` the `None` means a
session's manifest claims it. `cmd_ask` then takes
`askable = [r for r in ranked if r["owned"] and not r["blocked"]]`.

The default run, quoted verbatim:

```text
FRONTIER  191 findings in the tree, 52 `framing`, 29 askable
  dropped: 139 not `framing`, 23 in unclaimed bundles, 0 blocked
```

| Population | Count | What the code actually tested |
|---|---:|---|
| Findings in the tree | 191 | — |
| On the frontier (`framing`) | 52 | `status == "framing"` |
| Dropped: not `framing` | 139 | everything else |
| Dropped as not owned | 23 | `ownership is not None` — 16 `transferred`, 7 `unclaimed` |
| Dropped: blocked | 0 | see below |
| **Askable** | **29** | `owned and not blocked` |

**The drop line misnames its largest class.** It reads `23 in unclaimed
bundles`, but **16 of those 23 sit in `transferred` bundles and only 7 in
`unclaimed` ones.** The code tests `ownership is None`; the printout names one of
the two values that test excludes. A reader who trusts the line concludes that
allocating the unclaimed queue would free 23 findings. It would free 7.

**The blocked count of 0 is not evidence that nothing is blocked.** The tree
carries five `blocks` edges and zero `evidences` edges, and all five point at a
finding that is not `framing` and therefore not on the frontier — the targets are
`0042/F1`, `0048/F3`, `0053/F3`, `0049/F1` and `0047/F4`. The blocked set and
the frontier do not intersect, so this test has never removed a candidate on real
data — the class `0050` F4 names, *four instruments in three days were correct
and could not do their job.* A zero here means the instrument did not fire, and
reading it as health is the mistake the drop line prevents.

[&#8593; Contents](#contents)

## 3. The six stages

The design record names six stages "in order. Each one exists to remove work
before the next." Two reach the code — Feasibility as `frontier()`, partial, and
Rank as `rank()`, built to a different specification than the one written down.
Precedent, Lifting, Mode and Propagate have no implementation. Section 6
tabulates that; this section says what each stage does and does not do.

### 3.1 Feasibility

The design specifies three filters: drop everything not `framing`, everything
with an unsatisfied `blocks` or `evidences` edge, and **everything whose
`readiness` is not `ready`**. The first works; the second is inert, above; the
third does not exist. `readiness` is read nowhere in `plan_findings_work.py` and
is a key on none of the 191 findings. The design's node-attribute table (§3.1)
lists
`readiness` with the values `ready · needs-check · needs-owner-fact · blocked`.
No finding carries it. **This is not an empty field but an absent one**, which
also strands Mode's `fact request` row, triggered by `readiness` being
`needs-owner-fact`.

`frontier()` also records `updated=x.get("updatedAt")` on every candidate. The
design calls staleness the input "the interviewer needs to rank a finding nobody
has touched above one being actively worked"; `rank()` never reads it, and only 17
of the 52 frontier findings carry an `updatedAt` at all. Staleness is collected
and discarded.

### 3.2 Precedent

Not implemented. Section 7 of the design record tabulates ten precedents — *a
fact has one home*, *the owner commits; a session never does*, *no placeholder
ever appears in a record*, and seven more, each with a cited home. The claim is
that a finding entailed by one "**is not a question** — it is a proposal with the
rule cited". Nothing reads that table, which is prose with no machine-readable
form; no candidate can be marked entailed, and no run has presented a
proposal-with-citation. This is the only stage that can remove a question *by
answering it*, and it is the one with no implementation at all.

### 3.3 Lifting

Not implemented, and it would have no data to run on if it were. The design says:
where findings share a `generalises` parent, ask the parent and derive the
children, citing `0015`, `0036`, `0041` and `0042` as "four bundles asking one
question … one decision reaching fourteen findings."

`generalises` appears in exactly one place in the code — the weight table `W`,
at weight 3. `rank()` and `frontier()` never mention it. The tree carries **zero
`generalises` edges**; its 59 are `carried` 29, `relates-to` 16, `blocks` 5,
`co-decides` 4, `constrains` 3, `successor` 2. The lifting the design describes
in the present tense was never asserted in the data, so even a correct
implementation would lift nothing today. This is `0043` F9 exactly: *an edge kind
is defined by a description and a behaviour, and the two can disagree* — here the
description exists and the behaviour does not.

### 3.4 Rank

Implemented, and this is where code and design part company most sharply. The
design says: choose by **information gain** — "the question whose answer
eliminates the most option space across the remaining frontier, counted through
`constrains` and `generalises` edges" — then break ties on `write_category`, then
`blast_radius`, then `severity`. The code computes:

```text
r["gain"]  = r["gate"] * len(sib) * 2 + b["_blast"] * 0.5 + (len(sib) - 1) * 0.3
r["score"] = 0 if r["blocked"] else r["gain"] + WC[r["wc"]]
```

`sib` is the framing findings in the *same bundle*; `_blast` counts how many
other bundles name this one anywhere in their JSON; `gate` is 1.0 when the
finding is the last uncited one in a bundle that has decisions, 0.5 when merely
uncited, 0.0 otherwise.

Four departures, each verifiable:

- **`rank()` reads no edge.** Neither `constrains` nor `generalises` nor any
  other kind is consulted; the design's definition of information gain is not
  computed by any expression in the function.
- **`write_category` is an additive term, not a tiebreak.** `WC[r["wc"]]` adds
  1.0, 1.6 or 2.2 to every score, so it cannot separate two findings of the same
  category — the only case a tiebreak is for.
- **`blast_radius` is inside the gain, not after it**, so it is not the second
  tiebreak either.
- **`severity` does not exist** on any of the 191 findings.

The consequence is structural, and it is the defect the allocator carries too.
**The dominant term, `gate * len(sib) * 2`, is a property of the bundle, not the
finding.** So is `_blast`, and so is `(len(sib) - 1) * 0.3`. Only `gate` varies
within a bundle, over three values. Across the 29 askable findings:

| Score | Findings | Bundles |
|---:|---:|---|
| 25.10 | 6 | `0039` |
| 9.90 | 5 | `0030` |
| 9.10 | 10 | `0039` |
| 7.70 | 3 | `0047` |
| 7.00 | 4 | `0031` |
| 6.10 | 1 | `0037` |

**29 candidates resolve to six distinct scores.** In four of the five bundles
represented, every askable finding scores identically — `0030`'s five all 9.90,
`0031`'s four all 7.00, `0047`'s three all 7.70. Only `0039` separates, into the
two values its `gate` allows. A ranker addressed to findings that cannot order
two findings in one bundle is a bundle ranker wearing a finding's name. The top
score checks out by hand: `0039` has 26 findings, 16 `framing`, blast 6, category
`toolkit`, so `0039/F11` at gate 0.5 scores
`0.5*16*2 + 6*0.5 + 15*0.3 = 23.5`, plus `WC["toolkit"] = 1.6` — **25.10**.

### 3.5 Mode

Not implemented. The design tabulates six ways to put a question —
`confirm-derived`, `closed choice`, `binary gate`, `fact request`, `batch
confirm`, `deferral` — and states a hard rule: "**Batch confirm is forbidden for
`toolkit` and `evidence` write categories.**" None of the six strings occurs in
`plan_findings_work.py`; `ask` prints one shape only, id and score and statement
and three runners-up, and never says how to ask.

The forbidden-batch rule is worth flagging. It is a safety rule about
irreversible writes, and **24 of the 29 askable findings are `toolkit`, 5 are
`evidence`**: every askable finding today falls under the prohibition. It is
unenforced only because the thing it prohibits is also unbuilt, which stops
being safe the moment Mode is implemented without it.

### 3.6 Propagate

Not implemented. The design asks that after an answer the engine walk
`constrains`, `generalises` and `co-decides` outward, recompute option sets,
re-rank, and print "two or three lines saying what closed, what opened and what
is now decidable that was not" — "the whole answer to *how does this decision
affect the rest of the system*". No code runs after an answer, because no code
takes an answer: `ask` is a single-shot read that prints a question and exits.
The propagation block is the design's stated payoff for the whole model — the
reason narrowing is claimed not to lose nuance but to "relocate" it — and it is
entirely unbuilt.

[&#8593; Contents](#contents)

## 4. Ties

The default run ends like this:

```text
NEXT QUESTION
  0039/F11  score 25.10 (gate 0.5, blast 6, toolkit)
  The header schema binds `findings.md` only, and six of eight architecture records render their header as one run-on paragraph

  why this one, against the runners-up:
    0039/F18   25.10  `accepted` cannot say whether a decision's work was carried out,
    0039/F21   25.10  Nothing checks that a vocabulary change reached the prose, and f
    0039/F22   25.10  The currency watch that covers the legend was asserted before th

  ** TIE -- the ranker did not settle this. Say so rather than presenting an order.
```

The warning is real code, at `plan_findings_work.py` line 738:

```text
if len(askable) > 1 and abs(askable[0]["score"] - askable[1]["score"]) < 0.01:
    print("\n  ** TIE -- the ranker did not settle this. Say so rather than presenting an order.")
```

**This is the most valuable line in the tool and it should be defended.** A
ranker that always emits a winner teaches its reader that a winner exists. When
both scores are 25.10, presenting one first is a fabrication dressed as a
computation, and the owner spends a turn on a question chosen by dictionary
order. Refusing costs one run; the fabrication costs trust in every run after,
because nothing in the output distinguishes an earned ordering from an invented
one. Declining to rank is the tool reporting the true state of its evidence.

Two measurable defects in how it does this:

- **The tie is six-way; the check is two-way.** `abs(askable[0] - askable[1])`
  compares only the top pair, but six findings — `0039/F11`, `F18`, `F21`, `F22`,
  `F24`, `F25` — share 25.10. The printout shows the top plus three runners-up,
  so a reader sees four of six and no sign the other two exist.
- **The warning prints after the order it warns against.** "Say so rather than
  presenting an order" appears below a presented order.

Neither the tie detector nor the ranking formula is covered by a test. The suite
runs 54 tests, all passing; `TestInterviewer` holds three and all three test
Feasibility. Nothing tests `gate`, the gain formula, the drop-line arithmetic, or
the tie.

[&#8593; Contents](#contents)

## 5. Running it

```text
./bin/plan-findings-work.sh ask
```

**`ask` takes no options.** `main()` declares `--new-sessions`, `--capacity`,
`--dry-run`, `--only-new`, `--only-kind`, `--exclude-kind`, `--only` and
`--exclude` on the top-level parser, so `ask` accepts every one and acts on none.
Run seven ways — bare, `--capacity 5`, `--only-kind runbook`, `--exclude 0039`,
`--new-sessions 3`, `--only-new`, `--dry-run` — it produced seven byte-identical
outputs, md5 `39f3d065b84a6d8a6b02b8a546a8d651`. An unrecognised flag is refused:
`--mode binary` exits with `error: unrecognized arguments`.

The tool accepts a filter, says nothing about ignoring it, and returns the same
answer. There is no way to ask *what would you ask if `0039` were off the table*
— which, since `0039` supplies 16 of the 29 askable findings and both top scores,
is what a reader of the tie output most wants next.

`graph` is the companion for the surrounding population — `54 bundles  191
findings  59 edges  4 live sessions`, an unclaimed queue of `17 bundles, 59
findings, 82.0 cost units`, and a warning that `33 findings are live inside
unclaimed bundles (0047 F1)`. Those 33 are part of the population the drop line
mislabels, and `0047` F1 records that the rule governing them is undecided.

[&#8593; Contents](#contents)

## 6. What is designed and not built

| Design element | Home | Status in code |
|---|---|---|
| `readiness` filter | §5 stage 1, §3.1 | field absent from all 191 findings |
| `blocks`/`evidences` feasibility | §5 stage 1 | coded; 0 of 5 edges reach the frontier |
| Precedent entailment | §5 stage 2, §7 | no code; table is prose only |
| Lifting via `generalises` | §5 stage 3 | no code; 0 edges in tree |
| Gain through `constrains`/`generalises` | §5 stage 4 | `rank()` reads no edge |
| Tiebreak `write_category` → `blast` → `severity` | §5 stage 4 | none is a tiebreak; `severity` absent |
| `staleness` in the ranking | §3.1 | captured as `updated`, never read |
| Six question modes | §5 stage 5 | none of the six strings in the code |
| Batch confirm forbidden for toolkit/evidence | §5 stage 5 | unenforced; all 29 askable are toolkit or evidence |
| Propagation delta block | §5 stage 6 | no code |
| One question, or one `co-decides` cluster | §5.1 | prints top + 3; never clusters |
| Escape hatches (*full reading* · *why first* · *defer*) | §5.1 | no code |
| Interview writes `decisions.md` as a by-product | §5.2 | `ask` writes nothing at all |

Plainly: **`ask` today is a frontier filter with a bundle-level score attached,
and the parts that would make it an interview — precedent, mode, propagation —
are absent.** It remains useful, because the filter alone takes 191 findings to
29 and says what it dropped.

[&#8593; Contents](#contents)

## 7. Open questions

**7.1 What does a zero mean when the instrument cannot fire?** — `0050`. The
blocked count is 0 because no `blocks` edge targets a `framing` finding and
`evidences` has no instance. `0050` F4 names the class: *four instruments in
three days were correct and could not do their job, and no bundle covers that
class.* Until an instrument distinguishes "found nothing" from "could not look",
the drop line's third column is unreadable.

**7.2 Should the drop line name the test it actually applied?** — `0047`. The
line says `unclaimed`, the code says `ownership is None`, and 16 of the 23
dropped findings are in `transferred` bundles. `0047` owns the drift-nothing-
checks class, and `0047` F1 owns the undecided rule about findings in released
bundles that produces the mislabelled population.

**7.3 Where should `readiness`, `severity` and `category` live?** — `0043`.
Three attributes in the design's node table are absent from the data, and two of
them gate stages of the interviewer. `0043` argues that framework state lives in
documents rather than data; these fields are the case in point — specified in
prose, never given a home a parser could reach.

**7.4 Is an edge kind with a weight and no behaviour an edge kind?** — `0043`
F9, *an edge kind is defined by a description and a behaviour, and the two can
disagree.* `generalises` and `evidences` carry weights in `W`, have no instance
in the tree, and have no branch in `rank()`. Lifting is specified entirely in
terms of one of them.

**7.5 What datum would justify the gain formula?** — `0048`. The capacity
constant has no datum and `cmd_capacity` says so in its output; the gain
coefficients `2`, `0.5`, `0.3` and the gate's `1.0 / 0.5 / 0.0` have the same
problem and make no such disclosure. `0048` F3 — *what would have to be captured
to measure degradation has never been written down* — is that question asked of
the ranker.

**7.6 Does the interviewer belong to a session or to the framework?** — `0053`,
and design record §13.2. The rules are versioned and a session's reading of them
is not; if the interview is a way of working rather than a script, what a session
was shown when it answered is itself unrecorded state.

[&#8593; Contents](#contents)
