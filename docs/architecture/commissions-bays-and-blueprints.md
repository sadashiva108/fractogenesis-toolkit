# Commissions, bays and blueprints

> **Rank 5 — architecture.** Design that outlives the session that wrote it.
> Where this and an `accepted` decision disagree, the decision wins; where this
> and `metadata.json` or `plan_findings_work.py` disagree, the data and the code
> win. See `.github/copilot-instructions.md` for the precedence order.
>
> **Authoritative for** the shape of a commission that re-architects an existing
> system. **Not** authoritative for the findings lifecycle, which is unchanged.
>
> **Status: not built.** No code reads any field here. Written at Revision 322
> under the owner's section 6 override, by a session that had already closed, so
> that the first commission has something to be built to.

---

## 1. Why the existing commission shape is not enough

`iris/shapes.md` defines a commission as an intent to build: questions `Q1..Qn`,
terminating at `answered`, producing a blueprint under `architecture/`. That
shape assumes one question set and one blueprint.

**It breaks on a real re-architecture in two places.**

**A commission has more than one design in it.** Re-architecting IRIS means
settling a directory structure, a vocabulary register, a disposition record, a
detection layer and several more. Each is a separate design with its own inputs,
its own rulings and its own drawing. One flat question list across all of them
cannot say which question belongs to which design, and one blueprint for all of
them is not a document anybody can build to.

**And the inputs are not questions.** *"We want X, what shape should it take?"*
covers a third of what actually arrives. The rest is constraints, trade-offs
between patterns neither of which exists yet, requirements from outside, and
decisions to scope something for later. A container called `questions.md` gets
those written into it anyway, mislabelled.

**The greenfield/brownfield distinction is the root of it.** A greenfield
commission designs into empty space. A brownfield commission designs against a
system that is already load-bearing, and every ruling it makes displaces
something that exists. Nothing in the current shape can express *what this
replaces*, which is the only question a brownfield design is really answering.

## 2. The chain

```
commission ── bay ──┬── concerns        C1..Cn   what matters
                    ├── specifications  S1..Sn   what shall be
                    └── blueprint.md             what it looks like
```

A commission holds **bays**. A bay holds **concerns** and **specifications** and
produces one **blueprint**. `master-plan.md` indexes the bays.

**`bay` is the building word.** A bay is the structural division a work is broken
into: each designed and built as a unit, composing into the whole. It sits in the
same register as *commission*, *blueprint* and *charter*, which are already the
vocabulary.

**Not `layer`.** A layer is a behaviour of the running system — *delete the file
and ask what breaks*. `docs/ideas/big-picture.md` records that this review's own
first pass got that wrong and had to be corrected, because collapsing the two
hides the gap between *the rule exists* and *something enforces it*. A bay is a
unit of design work; a layer is a thing that runs. One bay may design one layer,
and the words must not be the same.

## 3. Shape and numbering

**The shape, and only the shape.** A commission is a directory holding
`metadata.json`, `master-plan.md`, and one directory per bay. A bay holds
`metadata.json`, `concerns.md`, `specifications.md` and `blueprint.md`.

```
<commission-root>/
└── 0001-<commission-name>/
    ├── metadata.json
    ├── master-plan.md
    └── 0001-<bay-name>/
        ├── metadata.json
        ├── concerns.md
        ├── specifications.md
        └── blueprint.md
```

**Where `<commission-root>` sits is not decided here, deliberately.** The
directory structure is Tier 0's first job and the first bay's subject, and a
document that fixes the root while the bay that rules on it has not opened has
answered its own first question before anyone asked it. Whatever a bootstrap puts
in place is provisional until that blueprint is drawn, and belongs in the bay as
a concern rather than as settled fact.

**Both sequences start at `0001` and neither is global.** Commissions are
numbered within whatever holds them; bays are numbered within their commission. A
bay has no meaning outside the commission that holds it, unlike a dossier, which
is addressable from anywhere in the tree.

**`blueprint.md` is written last**, after every specification is settled. It is
the only document here that outlives the commission, and it is what a charter is
built to.

## 4. What a bay is, structurally

**A bay is a dossier**, genus `bay`, shape `reasoning`. A commission is then the
first **compound dossier** — one whose members are dossiers rather than items.

The reason is derivation, not tidiness. A dossier's `standing` derives from its
members' statuses. If a bay is a dossier, a commission's standing derives from
its bays through one more turn of the same crank. If a bay is a bespoke third
thing, that crank gets written twice — and Revision 308 deleted the fourth copy
of the first one, after it had disagreed with the original on 128 of 384
enumerated cases without any run ever noticing.

**What it costs, stated plainly.** `members[]` becomes polymorphic, and
`MEMBER_PREFIX` has no entry for a bay, because bays are numbered `0001` and not
`B1`. The rule that replaces it: *a compound dossier's members are numbered as
dossiers; a simple dossier's are numbered as items.* One sentence, and checkable.

## 5. Concerns — the inputs

**`concerns.md`, members `C1..Cn`.**

**A concern is anything that shapes the design**: a requirement, a constraint, a
trade-off, a pattern under consideration, a scope decision, a question. The word
is ISO 42010's, which defines a concern as anything that matters to a stakeholder
and bears on the architecture. One word covers what `questions.md` could only
hold by mislabelling.

**A concern is forward-looking; a finding is backward-looking.** `iris/shapes.md`
already draws that line — a findings dossier is *a reading of what exists*, a
commission is *an intent to build*. The test: **a finding must be measurable
against the tree as it stands, and a concern cannot be**, because its subject
does not exist yet.

**A finding is not a prerequisite for a concern.** Many concerns have no finding
behind them. Some do, and carry an optional pointer:

```json
"origin": { "cites": "0050/F8", "realm": "finding" }
"origin": { "cites": "docs/ideas/big-picture.md §Detection", "realm": "document" }
"origin": null
```

### `stage` — the concern's disposition

| `stage` | means | parallel |
|---|---|---|
| `unscoped` | exists; its boundary is not drawn | — |
| `raised` | stated, nothing done | `un-started` |
| `exploring` | being worked, nothing ruled | `framing` |
| `settled` | **a specification cites it** — whatever that specification's adoption | `decided` |
| `designed` | **every** specification citing it is terminal | `resolved` |
| `descoped` | ruled out of scope | `withdrawn` |
| `reexamined` | reopened after being settled or designed | `reopened` |

**Inert band:** `designed`, `descoped`. **`reexamined` dominates them**, as
`revisited` does.

**`settled` means cited, not adopted.** A declined specification still settles
its concern — the concern was addressed and the answer was no. `designed`
therefore covers *closed by an adopted or a declined specification*, and the
count that matters is that **every** citing specification is terminal, not that
one is.

**Two pre-work values where `status` has one.** `unscoped` and `raised` both mean
no work yet, so any derivation over them must state its positive condition across
both rather than catching the remainder. `0043` F7 is the finding that says an
else branch must assert something; Revision 306 answered it by enumerating all 63
presence-combinations rather than choosing fixtures, and found seven cases its
first attempt got wrong.

**Authored, not derived.** `stage` is typed by a person and checked against the
specifications. Deriving it would make it the first derived member disposition in
the system and would trade a defect that fails loudly on one row for one that can
be wrong in forty places with nothing to notice — which is the argument
`state-as-data.md` section 7 already makes against generation.

## 6. Specifications — the rulings

**`specifications.md`, members `S1..Sn`.**

A specification says what shall be true. It is decision-shaped, not
resolution-shaped: a resolution records a past act on the tree and carries a
revision and a commit, and a specification describes a future state and can carry
neither, because nothing has been built. **The resolution analogue in a
commission is the charter task that builds the specification.**

**A specification carries no disposition.** A decision carries `outcome` and has
no status field anywhere in the schema; a specification carries `adoption` and
the same is true. `drafted` is where it sits before it is ruled, exactly as
`proposed` is for a decision.

### `adoption` — the specification's determination

| `adoption` | means |
|---|---|
| `drafted` | written, not yet ruled |
| `adopted` | in force; the blueprint may rest on it |
| `declined` | considered and refused — kept, not deleted |
| `amended → Sn` | replaced by a later specification; pointer required |
| `rescinded` | was adopted, withdrawn after the fact |

`amended → Sn` follows `replaced → Dn`, so `POINTER_OUTCOMES` already has the
shape.

### `supersedes` — the brownfield field

**Every specification names what it displaces.**

```json
"supersedes": [
  { "what": "docs/architecture/state-as-data.md §6.1", "realm": "document" },
  { "what": "plan_findings_work.VOCABULARIES",         "realm": "code" }
]
```

Greenfield does not need this; brownfield is almost nothing else. It answers, at
no extra cost: what current state this bay touches, what current state no
specification has claimed, and — when a charter later builds it — whether the
thing that was supposed to be removed actually was.

**A concern does not carry it.** `C3` displaces nothing; it is a worry. Only a
ruling changes anything, so the pointer hangs off the ruling.

### `cites` — and what it was ruled against

```json
"cites": [ { "member": "C3", "asWorded": "sha256:9f2a…" } ]
```

**A ruling is made against a wording, and the wording moves.** If a concern is
reworded after a specification cites it, that specification now answers a
question nobody asked. This is true of findings and decisions too — `answersAsOf`
exists for exactly this and is populated in **39 of 152** decisions, and nothing
reads it.

It matters more here, because rewording concerns is not drift: it is what
designing *is*. A concern gets sharper every time a specification fails to settle
it.

**A digest rather than a commit.** A commit pointer says the tree moved; a digest
says *this concern* moved, and is checkable without a diff. On mismatch the
concern goes `reexamined`, the specification keeps its `adoption`, and a person
decides whether the ruling survives the new wording. **The check reports; it does
not re-rule.**

## 7. `course` — the bay's disposition

Derived from the bay's members — its concerns — the way `standing` derives from
a dossier's. Specifications reach it through the concerns; the concern is the
integrator.

| `course` | holds when | parallel |
|---|---|---|
| `folded` | `lineage.supersededBy` is set — **tested first** | `superseded` |
| `parked` | **declared** — tested second, overrides the rest | — |
| `outlined` | no concerns, or all `unscoped` | `untouched` |
| `dropped` | all `descoped` | `retired` |
| `drawn` | all terminal, **at least one `designed`** | `answered` |
| `reexamined` | a `reexamined` concern beside only terminal ones | `revisited` |
| `specifying` | any `settled` | — |
| `gathering` | any `exploring`, none `settled` | — |

**Terminal band:** `drawn`, `dropped`, `folded`.

**Why not derive it from the specifications.** A bay could have every
specification `adopted` while one concern sits with nothing citing it. Deriving
from specifications alone reads that bay as `drawn` over a concern nobody
answered. Concern stages close that hole, because a concern with no specification
can never reach `designed`.

**`parked` is a declaration.** Nothing in the data derives *we chose not to design
this now*. It is `big-picture.md`'s `by: declaration` case and overrides the
derivation as `declaredState` does.

**`folded` is read off lineage**, the way `superseded` is, and must be tested
before anything else. Revision 308 records what happens when a copy of that
ordering is written with the two tests the other way round: 128 disagreements in
384 enumerated cases, none of them reachable in the tree, so four revisions of
clean runs said nothing.

**`drafting` is deliberately absent.** *The blueprint is being written* cannot be
derived and is not declared, so nothing could ever set it correctly.

**The blueprint check sits outside the derivation.** `drawn` derives from
concerns alone; a separate check asserts that a `drawn` bay has a `blueprint.md`.
Inside the derivation a missing blueprint makes the bay silently not-drawn and
nothing reports it. Outside, it is a failure with a name — which is `0037` F5's
shape, every bundle standing `answered` with no `decisions.md`, invisible until
somebody looked.

## 8. The register

| level | disposition | determination |
|---|---|---|
| session | `state` | — |
| dossier | `standing` · `progress` | — |
| **bay** | **`course`** | — |
| finding | `status` | `outcome` on its decisions |
| **concern** | **`stage`** | — |
| **specification** | — | **`adoption`** |

**`determination` is the class name**, standing to `outcome` and `adoption` as
`disposition` stands to `status`, `standing`, `state` and `stage`.

**Every value in `stage`, `course` and `adoption` is unused in every closed set
today**, so `VOCABULARIES` gains three entries and the disjointness guard needs
no declared overlap. That was a constraint on the naming, not an accident of it.

## 9. Current state and future state

**Current state is a commit, not a copy.**

```json
"baseline": {
  "repo": "fractogenesis-toolkit",
  "commit": "<hash>",
  "revision": 321,
  "census": "docs/ideas/big-picture.md §Current-State Census"
}
```

A hash is exact, retrievable forever, and already exists. A copied tree is a
second thing that drifts and that nothing checks.

**Per bay, taken late.** Each bay records its own baseline **when it enters
`drafting`**, not when the commission opens. A bay designed in week three should
be designed against week-three reality. The commission keeps an opening baseline
for orientation only, explicitly authoritative for nothing.

**This is not optional caution.** The census in `big-picture.md` was measured at
`f48a17c`, Revision 313, and carries its own *Pending* note about a patch that
moved four of its figures before it was committed. The tree is now at 321. **A
measurement names the commit it was taken at, and the commit it names can never
be the one that carries it.**

**Future state is not a document.** It is the union of adopted specifications —
derived, queryable, and unable to drift from itself. The blueprint narrates it;
the specifications are the source. Writing future state as prose creates a copy,
and a copy nobody re-derives goes stale silently: `iris/status.md` published 55
dossiers, 217 members and 73 edges for eight revisions under markers telling the
reader the numbers were machine-derived.

**So current-versus-future is not two documents.** It is a pointer on every
ruling, from the thing that exists to the thing that replaces it. That is the
only form that cannot come apart.

## 10. `master-plan.md`

One row per bay: number, name, `kind`, `course`, and a link to `blueprint.md`
once the bay is `drawn`.

**It is a projection**, and belongs in `state-as-data.md` section 6.1 as a new
class the day this is built — a `course` and a blueprint link displayed in a
table that is not their source. Revision 304 measured what happens to projections
nothing compares: five disagreements in 612 rows, all five in the three classes
nothing checked, none in the 329 rows something did.

## 11. `kind`, and the commission's mode

**`kind` distinguishes what bounds a bay**, not what it holds:

| `kind` | bounded by |
|---|---|
| `layer` | a runtime behaviour |
| `component` | an artifact or file set |
| `workflow` | an act a person or session performs |

**`phase` is deliberately excluded.** Ordering is not scope. A `phase` bay would
let one bay mean a thing and another mean a when. Where ordering must be data, it
is `after: ["0001"]` on the bay.

**The commission carries a `mode`:** `brownfield` or `greenfield`. It is an axis
orthogonal to `kind`, which is the subject domain. The distinction is
enforceable, which is the test of whether it is worth storing: **a `brownfield`
commission's specifications must carry `supersedes` or say why not**, and a
`greenfield` one has nothing to point at.

## 12. What this does not decide

**Whether a bay may be superseded as a dossier can.** `lineage` comes free with
the dossier decision and `folded` overlaps it. Stated as one mechanism above;
not tested.

**The migration.** Three new closed sets and a polymorphic `members[]` land in a
schema that is **mid-retrofit** — the `{value, by, on}` disposition triple is
designed, unbuilt, and gated on a migration plan over 358 records. Adding
`stage`, `course` and `adoption` before that retrofit means they convert with
everything else; after, they are two more record types to convert. **Cheaper
before, and worth deciding deliberately rather than by timing.**

**Any checker.** `0043` D3's ruling stands: *the fixture set first, because it is
what makes either a checker or a generator trustworthy, then a report-only
checker.* Nothing here proposes one.

<!-- proposed: master-plan.md -->
<!-- proposed: concerns.md -->
<!-- proposed: specifications.md -->
<!-- proposed: blueprint.md -->
<!-- proposed: questions.md -->
