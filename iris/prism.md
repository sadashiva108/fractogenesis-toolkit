# Prism — the allocator: how work is grouped and put to a session

> **Written before the genus rename, and checked against it at Revision 274.**
> Its measurements were taken against the tree and are current. Its vocabulary
> predates `members[]` and the four genera, so where it says *finding* it means
> what [vocabulary.md](vocabulary.md) now calls a **member**, and where it names
> a *bundle* the unit noun is under review. **No contradiction with the current
> vocabulary was found in it** — the check was for the session state `withdrawn`,
> which is now `dissolved`, and for the retired `findings[]` key. Neither
> appears. `vocabulary.md` is authoritative where the two ever disagree.
> **Role:** the reference for `bin/plan-findings-work.sh allocate` and the graph it
> reasons over. Authoritative for the allocator's *mechanism* — the nodes and edges,
> which edges the running code treats as hard, how a proposal is scored, and what a
> capacity figure is and is not. It is **not** authoritative for design intent;
> `docs/architecture/allocation-and-inquiry.md` owns that, and where the two disagree
> this document names both and follows the code, per the repository's own rule:
> *when the legend, a prompt and the code disagree, the code is what the data was
> stamped from.* Every figure below was measured on 2026-09-09 against the tree.

## Contents

- [1. What it is for](#1-what-it-is-for)
- [2. The graph it runs on](#2-the-graph-it-runs-on)
- [3. How it groups](#3-how-it-groups)
- [4. Cost, load, and capacity](#4-cost-load-and-capacity)
- [5. Running it](#5-running-it)
- [6. What it does not model](#6-what-it-does-not-model)
- [7. Open questions](#7-open-questions)

---

## 1. What it is for

The allocator schedules a human bottleneck. The scarce resource here is not compute —
the whole search finishes in forty milliseconds over fifty-four bundles — it is the
owner's attention. Only the owner assigns work, answers a finding, and commits.

Allocation had been done by eye: whoever was looking picked a bundle for a session
from whatever they happened to remember. That fails twice over. It does not notice
that several bundles are readings of one question, so the owner answers the same thing
repeatedly; and it does not notice that a bundle's decisions wait on a decision nobody
has taken, so an irreversible assignment is spent on work that cannot proceed.

The allocator replaces that with one scored proposal over the whole queue.
**It proposes; it never assigns.** `plan_findings_work.py` opens no file for writing
on any allocation path. Approving a proposal is one decision instead of seventeen.

[&#8593; Contents](#contents)

## 2. The graph it runs on

### 2.1 Nodes

`allocation-and-inquiry.md` section 3 states the intent plainly: **nodes are findings,
not bundles.** The running code does not do this. Every edge endpoint is truncated to
its bundle prefix — `str(e["from"]).split("/")[0]`, in `holds`, `score` and
`cmd_allocate` — and the assignment variables are bundle numbers. Finding-level
addressing survives in the printout and nowhere in the objective. The design record
calls bundle atomicity "a hard grouping constraint on the nodes"; in the
implementation it *is* the node.

Measured today: **54 bundles, 191 findings, 59 edges, 4 live sessions.** The queue —
bundles whose `ownership` reads `unclaimed` — is **17 bundles, 59 findings, 82.0 cost
units.**

Of the eight node attributes the design record tabulates, the code reads three: `kind`
(the record's `tree`), the derived write category, and a blast radius. It reads no
`readiness`, `staleness`, `severity` or `category` — three of which are schema fields
that exist and are empty. The two definitions of blast radius are also different
quantities: the record says "count of documents, scripts and findings a decision here
reaches", while the code serialises each bundle to JSON and counts how many *other*
bundles contain this bundle's four-character number as a substring. Highest: `0041`, 7.

### 2.2 Edge kinds and weights

`W` and `HARD` are literals in the code, reproduced exactly. "Cross-bundle mass" is
weight times the count of edges whose endpoints sit in two different bundles — the
only edges the objective can act on.

| Kind | Weight | Hard | In tree | Cross-bundle | Cross-bundle mass |
|---|---:|:---:|---:|---:|---:|
| `co-decides` | 6 | **HARD** | 4 | 3 | 18 |
| `contradicts` | 6 | **HARD** | 0 | 0 | 0 |
| `duplicates` | 6 | **HARD** | 0 | 0 | 0 |
| `blocks` | 4 | **HARD** | 5 | 2 | 8 |
| `evidences` | 4 | **HARD** | 0 | 0 | 0 |
| `constrains` | 3 | | 3 | 3 | 9 |
| `generalises` | 3 | | 0 | 0 | 0 |
| `successor` | 3 | | 2 | 2 | 6 |
| `carried` | 2 | | 29 | 29 | 58 |
| `shares-surface` | 2 | | 0 | 0 | 0 |
| `relates-to` | 1 | | 16 | 16 | 16 |
| `supersedes` | 1 | | 0 | 0 | 0 |

**Half the vocabulary has no instance in the tree**, so the `evidences` hold rule, the
`shares-surface` split penalty and `generalises` lifting have never run against real
data. **Lineage carries most of the mass**: `carried` and `successor` are 64 of the 115
cross-bundle weight units, produced mechanically by supersession rather than asserted.
Of the 59 edges, 31 record `basis: derived` and 28 `basis: asserted`.

`the-record-and-the-graph.md` has gone stale here. Its section 2.1 states "**0**
decision edges; 29 `carried`, 2 `successor`" over 31 edges, and concludes "the
allocator's cohesion term scores **zero**". Neither holds: there are 12 decision edges
(5 `blocks`, 4 `co-decides`, 3 `constrains`), and the run in section 5 scores `keep 6`.
Its counts of 147 findings and 47 bundles are superseded by 191 and 54. The *argument*
— that adoption, not schema, is the gap — stands; the figures do not.

### 2.3 Which edges are hard, and what "hard" does

The design record contradicts itself before the code enters. Section 3.2 says "**The
four hard ones are `blocks`, `evidences`, `co-decides` and `contradicts`**"; section
4.1 constraint 2 adds `duplicates`. The code sides with 4.1 — `HARD` has five members.
That is the failure `0043` F9 names: an edge kind defined by a description and by a
behaviour, with the two disagreeing.

More consequentially, **`HARD` does one thing in the code, and it is not the thing
either section describes.** It gates `holds()`, which holds a bundle when a hard edge
points *into* it from a bundle **not in the queue**:

```text
if fb == tb or tb not in queue or fb in queue:
    continue
```

1. **A hard edge between two queued bundles produces no hold.** The tree carries
   `blocks 0050/F5 -> 0053/F3` with both bundles unclaimed; the default run reports
   `held 0`. That edge became a cohesion bonus of 4, not a constraint.
2. **`co-decides`, `contradicts` and `duplicates` are never enforced as
   co-allocation.** Section 4.1 constraint 2 says these bundles "go to one session or
   are held together"; no code implements it. The tree carries
   `co-decides 0042/F1 -> 0041/F1`, and the default run below places `0042` on
   `entity-model-and-vocabulary-20260909-053548` and `0041` on
   `pre-image-capture-conformance-20260903-194532`. A stated hard constraint was
   violated silently on the first run, because it is a weight of 6 and nothing more.
3. **The expiry rule has no executable site.** Section 3.3 requires an asserted edge to
   expire "when either endpoint is `resolved` or `withdrawn`", and `holds()` guards
   with `src["_progress"] not in ("resolved", "withdrawn")`. `_progress` comes from
   `derivation_table`, whose only outputs are `untouched`, `analyzing`, `answered`,
   `revisited` and `retired`; measured across all 54 bundles the values present are
   `analyzing` (17), `untouched` (17) and `answered` (20). The guard tests two strings
   the field cannot hold, so it is always true and a settled bundle still blocks. The
   identical dead comparison is in `frontier()`. `0050` F4 opened this class.

[&#8593; Contents](#contents)

## 3. How it groups

There is no clustering pass and no partition step. The allocator searches assignments
of whole bundles to sessions and lets one scalar objective express every preference.
**The queue** is `ownership == "unclaimed"`, narrowed by `--only-kind`,
`--exclude-kind`, `--only` and `--exclude`, minus held bundles. **The destinations**
are the live sessions — no `ended.on`, no `declaredState` of `handoff`, `closed` or
`withdrawn` — plus any `<new-N>` placeholders requested.

**The search.** If `len(names) ** len(free) <= 400000` the code enumerates every
arrangement exhaustively; above that it runs longest-processing-time-first greedy, then
up to 200 rounds of best-improvement local search moving one bundle at a time. Both
paths run below: 4 sessions over 17 bundles is 1.7 × 10¹⁰ and takes the heuristic,
4 over 6 is 4,096 and is exact.

**The objective**, from `score()`, default weight tuple `(1.0, 1.5, 2.0, 1.0, 0.5, 4.0)`:

| Term | Weight | What it sums |
|---|---:|---|
| `keep` | 1.0 | edge weight between two queued bundles landing on the same session |
| `pull` | 1.5 | edge weight from a queued bundle to a bundle the destination session already owns |
| `tree` | 2.0 | queued bundles whose `kind` matches the session's most common owned `kind` |
| `split` | −1.0 | `shares-surface` weight crossing a session boundary |
| `imbalance` | −0.5 | max session load minus min session load |
| `overflow` | −4.0 | `Σ ((load − capacity)² / capacity)` over sessions past capacity |
| `setup` | −3.0 flat | per `<new-N>` placeholder that received any bundle |

Overflow is squared on purpose: past capacity the next bundle onto a loaded session
costs more than the last, which is what makes a new session preferable to a long one.

**One term in the design record is absent from the code.** Section 4.2 lists
`− w_hold · Σ ready findings inside held bundles` and calls it "the interesting one …
it prices the cost of bundle atomicity directly into the objective". `score()` takes
six weights and none is `w_hold`. Held-back ready findings are counted and printed;
they never enter the score. The counter section 8 nominates as "the counter that
decides the revisit" is emitted, and the objective it was said to steer cannot see it.

[&#8593; Contents](#contents)

## 4. Cost, load, and capacity

**Cost** is per bundle: the count of findings whose `status` is not `resolved` or
`withdrawn`, times a write-category factor from `WC` — `record` 1.0, `toolkit` 1.6,
`evidence` 2.2. The category is not a stored field. `write_category()` keyword-matches
the free-text `scope` sentence: "artifact", "evidence" or "volume" gives `evidence`;
`bin/`, `.internal/`, "instruction", "runbook", `.github`, "script", "template",
"lint" or "check" gives `toolkit`; everything else falls through to `record`. That
inference is load-bearing in the objective. Today's queue splits 10 `record`,
5 `toolkit`, 2 `evidence`.

**Load** carries a second cost scale. A session's load is `open_findings × 0.25` for
what it already holds, plus full cost for each bundle proposed onto it — an incumbent
finding priced at a flat quarter unit whatever its write category, a queued finding at
1.0, 1.6 or 2.2. The design record's "load is weighted by decision cost, not by finding
count" is true of the queued half of that sum and false of the incumbent half.

**Capacity is chosen, not measured, and the tool says so on every run.**
`DEFAULT_CAPACITY = 20.0` carries a comment naming it "a CHOSEN number, not a measured
one", and `cmd_allocate` prints `CHOSEN not measured -- 0048` when none is given.

`0048` owns why. Its F1 records that **a session's length is recorded nowhere**:
session metadata carries owners, resources, owned bundles and contributions, and none
of wall-clock span, turns, or context consumed — the three candidate meanings of "too
long". What the record carries is *size*, and size and length are not one quantity. Its
F2 records that the only proxy points the wrong way: `capacity` scores each session's
rework — decisions whose outcome is not `accepted`, findings reopened, bundles
superseded — against its load, and **rework falls as load rises**. `--capacity auto`
would return **54.0 cost units**, higher than any figure proposed by hand, arguing for
longer sessions rather than shorter.

Do not read that as a derived limit. `0048` F2's own figures are stale — it tabulates
four sessions and derives 35.2, the same command today tabulates seven and derives
54.0 — and that is the point: the number moves, the argument does not. Rework
normalises by decisions, so a session that decided more had more chances to be right,
and it counts what came back rather than what should have, so a poor decision nobody
revisited scores clean. **A capacity is a judgement. Set it with `--capacity N` and
say it was chosen.**

[&#8593; Contents](#contents)

## 5. Running it

`bin/plan-findings-work.sh` self-locates, checks for `python3`, and `exec`s the helper.
Run it from the repository root. Every subcommand reads; only `stamp` writes, and no
allocation path does.

### 5.1 `graph`

```text
GRAPH  54 bundles  191 findings  59 edges  4 live sessions
  edge kinds: {'carried': 29, 'relates-to': 16, 'co-decides': 4, 'blocks': 5, 'successor': 2, 'constrains': 3}
  unclaimed:  17 bundles, 59 findings, 82.0 cost units
  ** 33 findings are live inside unclaimed bundles (0047 F1):
       0051/F1 is `decided`
       0051/F2 is `resolved`
       0042/F1 is `decided`
       ... and 25 more
```

Read the last block first: 33 findings are past `un-started` inside bundles closed to
every session — a bundle nobody owns holding work somebody did. `0047` F1 owns the rule
that would say what becomes of them, and it is `un-started`.

### 5.2 `allocate` — the proposal

```text
CAPACITY  20.0 cost units, CHOSEN not measured -- `0048`. Pass --capacity N or --capacity auto.

QUEUE  17 bundles, 59 findings, 82.0 cost units
  held 0, held-back ready findings 0

PROPOSAL  score 20.65  keep 6 pull 10 tree 10 split 0 imbalance 3.00
  OVER CAPACITY (20): allocation-and-inquiry-design-20260906-233205, drift-and-the-write-boundary-20260909-053548, entity-model-and-vocabulary-20260909-053548, pre-image-capture-conformance-20260903-194532
  allocation-and-inquiry-design-20260906-233205    0001, 0010
                                                     holds 0 open, load 23.00
  drift-and-the-write-boundary-20260909-053548     0015, 0033, 0046, 0054
                                                     holds 15 open, load 23.95
  entity-model-and-vocabulary-20260909-053548      0042, 0050, 0051, 0053
                                                     holds 36 open, load 26.00
  pre-image-capture-conformance-20260903-194532    0008, 0011, 0016, 0017, 0024, 0041, 0049
                                                     holds 16 open, load 25.80

  edges kept inside one session:
    relates-to   0051/F2 -> 0042/F5
    relates-to   0053/F2 -> 0050/F4
    blocks       0050/F5 -> 0053/F3
```

`keep 6` is 1 + 1 + 4, the three listed edges. `split 0` is not health: `shares-surface`
has no instances, so the term has nothing to sum. Every session is over the chosen
capacity of 20, which is the honest report — 82 cost units across four sessions cannot
fit under 80, and `0001` alone (ten live findings at the `evidence` factor) costs 22.0
and cannot be split. Note what the "edges kept" list does not contain:
`co-decides 0042/F1 -> 0041/F1`, whose two bundles went to different sessions.

### 5.3 `allocate --new-sessions -1` — size it for me

```text
AUTO-SIZED  1 new session(s) proposed; 8 allowed before the search stopped. Capacity 20.0 cost units.
PROPOSAL  score 32.50  keep 11 pull 11 tree 10 split 0 imbalance 22.00
  <new-1>                                          0010, 0015, 0033, 0054
                                                     holds 0 open, load 18.00
NEW SESSION BUNDLES TO CREATE
  docs/sessions/cross-cutting-0010-20260909-181454/
      4 bundles, 12 findings, load 18.0: 0010, 0015, 0033, 0054
    CREATE cross-cutting-0010-<stamp>
           no edge ties it to an existing session's work, so a clone would inherit context it does not need
```

`keep 11` includes the `co-decides` edge, which this arrangement happens to keep
together — by objective, not by constraint. `CLONE` is chosen over `CREATE` when the
new cluster pulls hard on one existing session's work.

**Read `imbalance 22.00` as an artefact.** The auto-size loop raises `n` until every
load is under capacity or `n >= 8`; nothing here fits under 20, so it runs to eight, and
the arrangement printed is the eight-placeholder one, where seven placeholders received
nothing and sit in the load vector at 0.0 — max minus min is 22.00 − 0.00. At
`--new-sessions 1` the same arrangement scores 4.25. The imbalance term is being paid
against sessions that do not exist.

That header prints "NEW SESSION BUNDLES TO CREATE" and `--new-sessions` is documented
as "how many new session bundles to allow"; section 4.2 of the design record uses the
same compound. A session has a state, a bundle has a standing — different objects, and
the compound conflates them.

### 5.4 `capacity` — size against rework

```text
  session                                          load   bnd   fnd   dec rework
  assurance-coverage-20260908-204724                0.0     2     6     5     0 (0%)
  run-index-design-20260901-000000                  4.6    11    11     9     2 (22%)
  restore-apps-outstanding-20260903-000000         12.8     3    21    17     3 (18%)
  session-management-re-evaluation-20260906-1101   12.8     2    11     3     0 (0%)
  drift-and-the-write-boundary-20260909-053548     28.2     3    19     4     0 (0%)
  pre-image-capture-conformance-20260903-194532    30.4     8    20    31     2 (6%)
  entity-model-and-vocabulary-20260909-053548      54.0     5    50    29     2 (7%)

  DERIVED CAPACITY 54.0 cost units
```

Read the column, not the number. Section 4.

### 5.5 Filters, and the exact search

```text
$ ./bin/plan-findings-work.sh allocate --only-kind runbook --capacity 12
CAPACITY  12.0 cost units, given on the command line.
FILTERED  11 of 17 unclaimed bundles excluded by the selection
QUEUE  6 bundles, 15 findings, 27.0 cost units
PROPOSAL  score -32.46  keep 0 pull 0 tree 5 split 0 imbalance 18.25
  OVER CAPACITY (12): allocation-and-inquiry-design-20260906-233205
  edges kept inside one session:
    none -- no edge joins two queued bundles
```

Six bundles over four sessions is 4,096 arrangements, so this is the exact search. A
negative score carries no meaning alone; the objective is only ever compared against
other arrangements of the same queue.

[&#8593; Contents](#contents)

## 6. What it does not model

| Not modelled | Why, and where it bites |
|---|---|
| **length** | Only size is recorded. Section 4 and `0048` F1 |
| **readiness** | A finding can be `framing` and unanswerable — it needs a check run, or a fact only the owner has. Nothing records that, so the allocator cannot avoid assigning it |
| **staleness** | `updatedAt` exists on the schema and is unpopulated, so a bundle untouched for three weeks and one opened this morning are indistinguishable |
| **severity** | Free prose in every bundle. A ranker gets nothing from it |
| **edge truth** | A wrong `blocks` edge produces a confidently wrong ordering and every check passes. Section 9 of the design record states this rather than leaving it to be found |
| **the topological invariant** | Section 9 claims "every proposed order is a valid topological order of the `blocks` and `evidences` edges". No such check exists in `plan_findings_work.py` |
| **the patch** | Section 4.4 specifies the allocator emitting the assignment patch — tag, index rows, manifest rows. The implementation prints a proposal and a `DRY RUN` notice; the owner creates the sessions, assigns, and commits |
| **anything below the bundle** | Ownership is per-bundle by the decision in section 12, so a bundle whose findings are ready is held whole when one sibling is blocked |

[&#8593; Contents](#contents)

## 7. Open questions

**Capacity has no datum.** `0048` — F1, length is recorded nowhere; F2, the only proxy
inverts; F3, what would have to be captured, which is the turn record designed in
section 8 of the design record and never emitted.

**Findings live inside bundles closed to everyone.** 33 today. `0047` F1, `un-started`.

**An edge kind's description and its behaviour disagree.** The hard set is four in one
section, five in another, five in the code, and `co-decides` is described as a
must-co-allocate constraint and implemented as a weight. `0043` F9.

**An instrument that is correct and cannot fire.** The expiry guard in `holds()` and
`frontier()` compares a progress value against two strings the vocabulary cannot
produce. `0050` F4 opened this class and no bundle covers it.

**Who may assert an edge, and under what permission.** Section 13.1 leaves it open and
carries it to `state-as-data.md` section 11.3 rather than answering twice. The edge
contract itself is `0043` D1.

**Citations to superseded bundles.** `0046` owns supersession moving authority and
leaving citations behind. The conformance sweep reports `EDGE-TO-SUPERSEDED`; the
allocator excludes such edges from neither `keep` nor `pull`.

**Whether per-bundle ownership is costing anything.** Section 12 of the design record
is the decision, section 8 is the counter meant to revisit it, and that counter is not
in the objective.

[&#8593; Contents](#contents)
