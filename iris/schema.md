# Schema — the entities, their fields, and what each field is for

> **Role.** Shape. What a record holds, what type each field carries, whether
> anything is obliged to fill it, and — measured — whether anything does.
>
> **Authoritative for** the field list and the population counts. **Not**
> authoritative for what any value *means* — that is
> [vocabulary.md](vocabulary.md), and nothing here restates a definition from it
> — nor for what moves a value, which is [lifecycles.md](lifecycles.md).
>
> **The tiebreak is the code.** Where this file and
> `.internal/ai-scripts/session-management/plan_findings_work.py` disagree, the
> code is what the record was stamped from and this file is the defect. Every
> count below was measured against the tree on 2026-09-09: **54 dossiers, 194
> members, 143 decisions, 59 edges, 11 sessions.** The design record is
> `docs/architecture/state-as-data.md` § 4, and section 8 records where it has
> drifted from what the tree holds.

**Two files, one name.** One `metadata.json` in every dossier directory and one
in every session directory; the directory says which kind it is.

## Contents

- [1. The rules that govern every record](#1-the-rules-that-govern-every-record)
- [2. The dossier record](#2-the-dossier-record)
- [3. Nested shapes](#3-nested-shapes)
- [4. The session record](#4-the-session-record)
- [5. Derived fields, and the one instrument that writes them](#5-derived-fields-and-the-one-instrument-that-writes-them)
- [6. Fields nothing populates](#6-fields-nothing-populates)
- [7. Fields nothing reads](#7-fields-nothing-reads)
- [8. Where the design record has drifted](#8-where-the-design-record-has-drifted)

---

## 1. The rules that govern every record

**Six rules, each measured against the tree rather than asserted.**

**1. Every repeatable field is an array**, because a projection can flatten a list
into prose and prose cannot be widened back without inventing the boundaries.
**One violation:** `resolution.resolvedBy` is an array on 65 of the 85 resolution
objects and a bare string on 20, and `resolution.revision` is a string on 33, an
integer on 15, `null` on 37 — neither caught, because no reader consults the field
at all ([§7](#7-fields-nothing-reads)).

**2. No presentation in the data.** `null`, never `"—"`; `null`, never `""`. This
half **is** enforced: `extract-metadata.py --check` walks every string at every
depth and fails on a dash, an empty string, a bold marker or a leading backtick.
**Measured: 0 problems across all 65 records.** *No object whose fields are all
empty* is the unenforced half, and **16 such objects stand in the tree**: 10 of 54
`recordedBy` objects, 6 of 11 `ended` objects.

**3. Atomic values carry no ornament; prose values are markdown by nature.** The
test is whether a renderer would ever *add* the ornament: it adds backticks around
a status and does not rewrite a sentence. The walker in rule 2 holds an explicit
list of 36 atomic names and inspects nothing else, so every prose field is
unchecked **by design**.

**4. No fact another file owns.** A session records the dossier numbers it owns
and what it owes each one — not their subjects, kinds, member counts or standings.
**One live copy:** `transcript` is `https://claude.ai/code/<sessionId>` on 9 of the
10 sessions carrying one — `owners[].sessionId` with a prefix, stored twice.

**5. Nothing derivable is stored.** `currentOwner` is the row in `owners[]` whose
`until` is null; counts are computed. **Three declared exceptions** — `standing`,
`progress`, `state` — are licensed only because a check fails when they drift
([§5](#5-derived-fields-and-the-one-instrument-that-writes-them)). **One
undeclared one:** `ended.commits` is derivable from the `Claude-Session` trailer
and stored by hand anyway, while **`ended.revisions` is not derivable and is a
different kind of claim entirely** — Revision 266, [§4](#4-the-session-record).

**6. Closed vocabularies are validated.** Which sets actually are, and the two
that are not, is
[vocabulary.md § 13](vocabulary.md#13-what-is-validated-and-what-is-not).

[&#8593; Contents](#contents)

## 2. The dossier record

**24 top-level fields.** A **dossier** is the numbered directory of members that
[vocabulary.md § 2](vocabulary.md#2-genus-and-shape) calls a bundle; the record
below is its `metadata.json`, and the code's own vocabulary keys are
`dossier.genus`, `dossier.standing`, `dossier.progress`, `dossier.ownership`,
`dossier.kind`. **The `required` column is a fact about code, not a wish:**
`load-bearing` — the reader raises without it; `checked` — a named detector fires
on it; `optional` — nothing anywhere obliges it.

| Field | Type | Required | What it is for | Populated |
|---|---|---|---|---:|
| `schemaVersion` | int | optional | the shape's version | 54 of 54 |
| `updatedAt` | string | optional | when the record last changed | 54 of 54 |
| `number` | string | **load-bearing** | the dossier's identity; every citation is by this | 54 of 54 |
| `bundleName` | string | optional | the directory name | 54 of 54 |
| `genus` | string | **checked** | what sort of dossier this is — `VOCAB`, and `MEMBER-PREFIX` against the member ids | 54 of 54 |
| `kind` | string | **checked** | the subject domain — `VOCAB`; the allocator's *tree* term groups by it | 54 of 54 |
| `subKind` | null | optional | nothing states what it would carry | **0 of 54** |
| `subject` | string | optional | the reading in one line | 54 of 54 |
| `recordedOn` | string | **checked** | the date the reading was taken — completeness, against the markdown header | 54 of 54 |
| `recordedOccasion` | string | optional | what was being done when it was noticed | 52 of 54 |
| `recordedBy` | object | **checked** | which session took the reading | 54 of 54 |
| `severity` | string | **checked** | what it costs to leave — completeness, against the header | 54 of 54 |
| `feltAt` | array | **checked** | where the defect shows — length must equal the header's bullet count | 13 of 54 |
| `scope` | string | optional | the surface the work touches; the **only** input to the write category | 28 of 54 |
| `read` | array | **checked** | what was read to take the reading — length checked as `feltAt` is | 16 of 54 |
| `standing` | string | **checked** | where the dossier stands — `UNSTAMPED`, `STORED-DISAGREES` | 54 of 54 |
| `progress` | string | **checked** | the reading alone, ownership aside — same two detectors | 54 of 54 |
| `ownership` | string | **checked** | the two declared ownership exceptions — `VOCAB`, `ORPHAN` | 20 of 54 |
| `lineage` | object | optional | whether this reading is still authoritative | 14 of 54 |
| `members` | array | **load-bearing** | the items; everything derived starts here | 54 of 54 |
| `decisions` | array | **checked** | the rulings — `UNCITED-DECISION`, `DANGLING-CITATION`, `VOCAB` | 27 of 54 |
| `contributions` | array | optional | what a non-owning session wrote here | 6 of 54 |
| `edges` | array | optional | typed relations at member granularity | 18 of 54 |
| `indexNotes` | string | optional | the source of the dossier's `INDEX.md` Notes cell | 6 of 54 |

**`scope` is the highest-leverage optional field here and it is empty on 26 of
54.** `write_category()` matches substrings in it and the allocator multiplies every
live member by that category's weight, so **a null `scope` silently returns
`record`, the cheapest weight** — measured `record` 31, `toolkit` 17, `evidence` 6,
**26 of the 31 `record` verdicts being the fallthrough.** `ownership` at 20 of 54
is by contrast correct: null is the normal case, and the field carries only the
two declared exceptions — 17 `unclaimed`, 3 `transferred`, 34 null.

[&#8593; Contents](#contents)

## 3. Nested shapes

### `members[]` — 194 rows

**`genus` and `members[]` both arrived at Revision 271**, the rename coming
*before* a second genus existed rather than after — an array named for one species
cannot name the genus, and doing it afterwards is a breaking change with no
migration plan (`0052` F2). **The member id carries the genus in its prefix** —
`F`, `Q`, `T` — so a member cited out of context still says what it is, and
**`MEMBER-PREFIX` is the conformance code** where the two disagree. Measured: **0
violations across 194 members**, all 54 dossiers genus `findings`.

| Field | Type | Required | What it is for | Populated |
|---|---|---|---|---:|
| `id` | string | **load-bearing** | `F<n>`, and the prefix is the genus conformance | 194 of 194 |
| `statement` | string | optional | the reading itself; the interviewer prints it | 194 of 194 |
| `status` | string | **checked** | the six of [vocabulary.md § 3](vocabulary.md#3-member-statuses) — `VOCAB` | 194 of 194 |
| `statusReason` | null | optional | the enumerated reason for the transition that produced the status | **0 of 194** |
| `statusNote` | string | optional | the optional prose beside that reason | 1 of 194 |
| `updatedAt` | string | optional | when the statement last changed | **72 of 194** |
| `sectionHeading` | string | optional | the heading in `findings.md` this row renders to | 167 of 194 |
| `reopened` | null | optional | the reopen object — reason, note, `at`, SHA, ids | **0 of 194** |
| `withdrawn` | null | optional | the withdrawal object — reason, note, `at` | **0 of 194** |
| `resolution` | object | **checked** | what closed it — `RESOLUTION-AHEAD-OF-FINDING` if the status is not inert | 85 of 194 |

**`updatedAt` on a member is `0043` F8's remedy, and it is on 72 of 194.**
`framing` names a direction, not a position — framing for an hour and framing for
three weeks are the same value — so **staleness is underivable without this
field.** Measured where it matters most: **18 of the 47 `framing` members carry
it**, leaving 29 live members the tree cannot age; by status, `decided` 21 of 31,
`resolved` 33 of 69, `un-started` 0 of 47, which is right. The field reaches
`frontier()` and is then consulted by nothing ([§7](#7-fields-nothing-reads)).

### `resolution` — 85 objects

| Field | Type | Required | What it is for | Populated |
|---|---|---|---|---:|
| `resolvedBy` | array \| string | optional | the decision ids the work carried out | 69 of 85 |
| `whatWasDone` | string | optional | the prose account of the work | 76 of 85 |
| `revision` | string \| int | optional | the `APPLY-MANIFEST.md` revision that delivered it | 48 of 85 |
| `commit` | string | optional | the commit that delivered it | 38 of 85 |

**A resolution nests inside its member**, so an orphan row is structurally
impossible rather than checked for. Its presence is read; **not one of its four
fields is.**

### `decisions[]` — 143 rows

| Field | Type | Required | What it is for | Populated |
|---|---|---|---|---:|
| `id` | string | **checked** | `D<n>` | 143 of 143 |
| `decision` | string | optional | the ruling | 143 of 143 |
| `members` | array | **checked** | which members it answers — `UNCITED-DECISION`, `DANGLING-CITATION` | 122 of 143 |
| `decided` | string | optional | the date it was ruled | 136 of 143 |
| `outcome` | string | **checked** | the seven of [vocabulary.md § 7](vocabulary.md#7-decision-outcomes) — `VOCAB`, `replaced` by prefix | 143 of 143 |
| `answersAsOf` | string | optional | the member's `updatedAt` when the decision was accepted | **20 of 143** |
| `voidedReason` | null | optional | why an `accepted` decision was voided | **0 of 143** |
| `sectionHeading` | string | optional | the heading in `decisions.md` | 143 of 143 |

**`answersAsOf` is what makes `0039` D8 enforceable, and it is on 20 of 143.** A
decision whose `answersAsOf` is older than its member's `updatedAt` was ruled
against a statement that has since changed. Measured over **149 accepted-decision
× cited-member pairs**: 24 carry both stamps and are checkable, 43 carry the
member's stamp alone, **82 carry neither**, and **3 of the 24 checkable pairs are
stale** with nothing to report them. Four dossiers use it: `0037`, `0038`, `0039`,
`0047`. Outcomes measured `accepted` 139, `replaced → D<n>` 4, and **zero** each
of `voided`, `rejected`, `deferred`, `retracted`, `proposed` — the rejected
alternative, which [README.md](README.md) says the record exists for, is recorded
nowhere here.

### `edges[]` — 59 rows

| Field | Type | Required | What it is for | Populated |
|---|---|---|---|---:|
| `kind` | string | **load-bearing** | the twelve of [vocabulary.md § 8](vocabulary.md#8-edge-kinds) | 59 of 59 |
| `from` | string | **load-bearing** | source, `NNNN/F<n>` or `NNNN` | 59 of 59 |
| `to` | string | **load-bearing** | target — `EDGE-TO-SUPERSEDED` fires on it | 59 of 59 |
| `why` | string | optional | prose: what the relation says | 30 of 59 |
| `reason` | string | optional | the provenance disposition | 2 of 59 |
| `basis` | string | optional | `derived` or `asserted` | 59 of 59 |
| `asserted_by` | string | optional | which session asserted it | 59 of 59 |
| `asserted_on` | string | optional | when | 59 of 59 |

`basis` reads `derived` on 31 rows and `asserted` on 28. **`kind` is the field the
allocator pulls weight from and the one closed set with no closed-set check** — an
unknown kind takes weight 1 and passes.

### `lineage` — 14 objects

| Field | Type | Required | What it is for | Populated |
|---|---|---|---|---:|
| `supersededBy` | string | **checked** | on the predecessor: which dossier replaced it | 7 of 7 |
| `supersedes` | string | optional | on the successor: which dossier it replaced | 7 of 7 |
| `on` | null | optional | the date the supersession landed | **0 of 14** |

**Two disjoint shapes under one field name**, seven predecessors and seven
successors, no object both — and **`on` is null on all fourteen.** `supersededBy`
is the first row of the standing table; `supersedes` is one of two things
`is_clone()` tests.

### `reopened`, `withdrawn` and `contributions[]`

**`reopened` and `withdrawn` are 0 objects each**, their shapes specified and
never written: `reopened` holds `{at, reason, note, sha, decisionId, resolutionId}`
and `reopened.md` is generated from it against that SHA, never hand-written — a
snapshot is a second copy of a fact and will drift, a SHA cannot; `withdrawn` holds
`{at, reason, note}`. Arrows 6, 7a, 7b and 8 of
[lifecycles.md § 2](lifecycles.md#2-the-member-lifecycle) have never fired.

**`contributions[]` is 21 rows on 6 dossiers** in two key shapes —
`{session, date, contribution}` on 18, `{session, date, what}` on 3. **Two key
names for one fact and no reader to notice**; § 4 shows only `contribution`.

[&#8593; Contents](#contents)

## 4. The session record

**14 top-level fields, 11 records.** A **session** is a unit of work with an owner;
a bundle is the thing it owns, never the thing it is, so the field named
`bundleName` here — which holds the session's directory name — is a misnomer the
schema inherited. Terminal shutdown is `dissolved`, not `withdrawn` (Revision 273).

| Field | Type | Required | What it is for | Populated |
|---|---|---|---|---:|
| `schemaVersion` | int | optional | the shape's version | 11 of 11 |
| `updatedAt` | string | optional | when the record last changed | 11 of 11 |
| `bundleName` | string | **load-bearing** | the session's directory name; the graph keys on it | 11 of 11 |
| `createdOn` | string | optional | when the session was opened | 11 of 11 |
| `owners` | array | optional | who held it, and in what environment | 10 of 11 |
| `transcript` | string | optional | the conversation this came from | 10 of 11 |
| `scratchPath` | string | optional | the scratch copy composed in | 4 of 11 |
| `resources` | array | optional | the checkout, the copy, the volume | 9 of 11 |
| `ownedBundles` | array | **checked** | which dossiers it owns; ownership is derived by scanning this | 8 of 11 |
| `contributions` | array | optional | what it wrote into a dossier it does not own | 2 of 11 |
| `declaredState` | string | **checked** | the one state a session declares — it wins over every derivation | 3 of 11 |
| `indexNotes` | string | optional | the source of the session's `INDEX.md` Notes cell | 4 of 11 |
| `ended` | object | **checked** | the closing record; `ended.on` is row 2 of the state table | 11 of 11 |
| `state` | string | **checked** | the five of [vocabulary.md § 6](vocabulary.md#6-session-states) — `UNSTAMPED`, `VOCAB`, `STORED-DISAGREES` | 11 of 11 |

Measured states: `closed` 4, `active` 3, `handoff` 3, `available` 1. All three
`declaredState` values are `handoff`; the other eight are null, correctly — writing
`closed` there is a second copy of a derived fact.

### `owners[]` and `ownedBundles[]`

**`owners[]` — 11 rows** of
`{from, until, assistant, sessionId, model, environment, environmentNotes}`,
populated 11, 5, 11, 11, 11, 11 and 3 of 10. **`until: null` is the currentOwner
derivation**, on 6 rows, which is why no `currentOwner` field exists; one session
carries no owners row and it is the one with no `transcript`.

**`ownedBundles[]` — 36 rows in two shapes**, `{number, notes}` on 26 and
`{number, path, assignedOn, notes}` on 10; only `number` is read. **`owner_of()`
falls back to a key named `bundle`, on 0 of the 36 rows** — a reader with no writer.

### `ended` — 11 objects, three different kinds of claim

| Field | Type | Required | What it is for | Populated |
|---|---|---|---|---:|
| `on` | string | **checked** | the closing date; row 2 of the state table | 5 of 11 |
| `reason` | string | optional | why it closed | 5 of 11 |
| `revisions` | array | optional | the revisions this session delivered | **2 of 11** |
| `commits` | array | optional | the commits this session delivered | **2 of 11** |
| `disposals` | array | optional | what happened to each dossier it held | **2 of 11** |

**Revision 266 established that these are three kinds and not one, and an
instrument treating them alike gets two of the three wrong.**

- **`ended.commits` is derivable** from the `Claude-Session` trailer: 103 of 226
  commits carry it and 9 of 11 sessions are named in one. For the two sessions that
  filled the field **every stored commit is in its trailer set**, and the trailer
  names two more for one and one more for the other — all three later corrective
  writes made after the closing, not drift. **Derivable, not derived, stored by
  hand.**
- **`ended.revisions` is a claim no single source answers.** At least four commits
  deliver more than one revision, and **the trailer names the session that made the
  commit, not the session that composed each revision inside it.** Every revision
  named must exist in the manifest and every commit must carry the trailer; that is
  as far as a check can go.
- **`ended.disposals` is a judgement** and an instrument may do nothing with it.
  Measured **14 rows in two disjoint shapes** — `{number, to, why}` on 7,
  `{bundle, disposal, revision, note, to}` on 7. § 4 shows the array and never says
  what an element looks like, so the first session to fill it invented a shape and
  the second another.

**`resources[]`** is `{what, path, notes}` on 38 rows, `notes` on 25.
**`contributions[]`** is 5 rows — 4 with `contribution`, 1 with `what`, the same
two-key split the dossier record has.

[&#8593; Contents](#contents)

## 5. Derived fields, and the one instrument that writes them

**Three fields are derived and stored, and one instrument writes all three.**
`stamp_derived` writes `standing` and `progress` on every dossier and `state` on
every session; the derivations are
[lifecycles.md § 3](lifecycles.md#3-what-is-derived-and-what-is-declared).
**Nothing derivable is stored — except where a check fails when the copy drifts**,
which is the whole licence, and it is honoured: `check` reports `UNSTAMPED` for a
null and `STORED-DISAGREES` for a value adrift.

```text
$ ./bin/plan-findings-work.sh stamp --dry-run
STAMP  would write 0 record(s)

  Every derived field already agrees with what it derives from.
```

**Read that as agreement, not as health.** Three stamped fields match what the
stamper derives them from; it claims nothing about the 194 member rows underneath,
and `check` on the same tree reports 43 findings — 21 `UNCITED-DECISION`, 11
`RESOLUTION-AHEAD-OF-FINDING`, 8 `CLOSED-BUNDLE-LIVE-FINDING`, 2 `ORPHAN`, 1
`DECISION-AHEAD-OF-FINDING`. **`standing` and `progress` differ on 31 of 54
dossiers**, so they are not the same question. `shape` is derived from `genus` and
never stored; a stored shape is ignored. **No code path writes a member `status`** —
`_rewrite` is reached only from `stamp_derived`, which passes those three keys.

[&#8593; Contents](#contents)

## 6. Fields nothing populates

**Six stored fields are `null` on every record**, plus one key that exists only in
a reader.

| Field | Records | Who owns the gap |
|---|---:|---|
| `subKind` | 0 of 54 | **nobody.** No document says what it would carry and no code reads it |
| `members[].statusReason` | 0 of 194 | `0039` D7–D12 named the four reason fields; **the token `reason` appears nowhere in `plan_findings_work.py`**, and the transitions that would fill it have never fired |
| `members[].reopened` | 0 of 194 | arrow 6 of [lifecycles.md § 2](lifecycles.md#2-the-member-lifecycle) — zero members are `reopened` |
| `members[].withdrawn` | 0 of 194 | arrow 8 — zero members are `withdrawn` |
| `decisions[].voidedReason` | 0 of 143 | rollback voiding is described in the legend and performed by no code; zero decisions carry `voided` |
| `lineage.on` | 0 of 14 | **nobody.** The supersession procedure has nine ordered steps and not one of them sets it |
| `ownedBundles[].bundle` | 0 of 36 | a fallback key inside `owner_of()`; no writer has ever produced it |

**Four of the seven follow from lifecycles and are not schema defects** — the
reason and reopen/withdraw shapes wait on transitions the tree has never taken.
**Three have no owner at all**: `subKind`, `lineage.on` and the `bundle` alias — a
field with no populator, no reader and no bundle saying why is the cheapest drift
to leave and the hardest to notice.

[&#8593; Contents](#contents)

## 7. Fields nothing reads

**A field written and never consulted is a fact with no consumer.** Measured
against `plan_findings_work.py` — the reader that builds the graph, allocates the
work and runs every conformance detector — **the two records carry 107 distinct
field paths and it reads 31.** The other **76** are written and never looked at.

**What it reads.** Dossier: `number`, `genus`, `kind`, `scope`, `standing`,
`progress`, `ownership`, `lineage.supersededBy`, `lineage.supersedes`, `members`
(`id`, `statement`, `status`, and `resolution` and `reopened` **for existence
only**), `decisions` (`id`, `members`, `outcome`), `edges` (`kind`, `from`, `to`).
Session: `bundleName`, `ownedBundles[].number`, `declaredState`, `ended.on`,
`state`.

**What it does not.** The whole provenance apparatus on an edge — `why`, `reason`,
`basis`, `asserted_by`, `asserted_on`. The whole of `resolution` beneath its own
existence. `answersAsOf`, `voidedReason` and the decision's own text. All seven
fields on `owners[]`, all three on `resources[]`, three of four on
`ownedBundles[]`, four of five on `ended`. And on the dossier itself `subject`,
`severity`, `feltAt`, `read`, `recordedOn`, `recordedOccasion`, `recordedBy`,
`contributions`, `indexNotes`, `updatedAt`, and **`schemaVersion`, which is `1` on
all 65 records and gates no migration because nothing consults it.**

**Three qualifications, because the claim would otherwise be too strong.**

1. **A second instrument reads six of them for existence, never for content.**
   `extract-metadata.py --check` asserts `recordedOn`, `recordedBy`, `severity`,
   `feltAt`, `scope` and `read` are non-empty wherever the markdown header carries
   the matching label, and that `feltAt` and `read` hold as many elements as the
   header has bullets — a check on *presence and count*; nothing acts on the value.
2. **`members[].updatedAt` is the sharpest case in the tree.** `frontier()` copies
   it into every row as `updated=`; `rank()` never touches the key and `cmd_ask`
   never prints it. **It is loaded and abandoned in the same function**, so it
   reads as consulted to anyone grepping the name — and staleness, the thing it
   exists to make derivable, is derived by nothing.
3. **Every field participates in `_blast` as text.** Blast radius `json.dumps`-es
   each dossier and counts how many *other* dossiers contain this one's number
   anywhere in the string — a substring scan over the whole record, not a read of
   any field by name. An unread field still moves the ranking if a dossier number
   appears in its prose.

[&#8593; Contents](#contents)

## 8. Where the design record has drifted

**§ 4 is the design record and the tree has moved past it in eleven places.**
Every number below is measured against the tree as it stands.

| # | § 4 says | The data says |
|---:|---|---|
| 1 | § 4.3's dossier example carries `progress`, `ownership`, `lineage` and **no `standing`**; § 4.4 introduces `standing` a page later | all 54 records carry `standing`, stamped, ordered immediately before `progress` |
| 2 | § 4.4 gives `progress` the values `un-started`, `withdrawn`, `resolved`, `reopened`, `analyzing` | those are **member statuses used as dossier progress** — the collision Revision 233 separated. The field carries `answered` 20, `analyzing` 18, `untouched` 16; **`analyzing` is the only word the two lists share** |
| 3 | § 4.4 counts "all 49 bundles", "27 of 49", "absent from all seven sessions" | 54 dossiers and 11 sessions. `standing` and `progress` differ on **31 of 54** |
| 4 | § 4.2's session example carries no `state` key | all 11 sessions carry `state`, stamped and checked |
| 5 | § 4.2 and § 4.4 both name **`withdrawn`** as a session state | Revision 273 replaced it with `dissolved` — [vocabulary.md § 6](vocabulary.md#6-session-states). The code's closed set carries `dissolved` |
| 6 | § 4.3 says a decision "carries a `findings` array" | the field is `members`, on all 143 decisions — and the same section's own opening sentence says so. **The section contradicts itself** |
| 7 | § 4.3 specifies the `reopened` and `withdrawn` object shapes | **0 instances of each.** Both shapes are unexercised, and the first record to use one will discover whether it fits |
| 8 | § 4.4's lineage example is `{supersededBy, on}` | 14 lineage objects and **`on` is null on all 14** |
| 9 | § 4.1 — every repeatable field is an array | `resolution.resolvedBy` is a bare string on **20 of 85** |
| 10 | § 4.1 — no object whose fields are all empty | **16 such objects**: 10 all-null `recordedBy`, 6 all-empty `ended` |
| 11 | § 4.3 — `answersAsOf` is what makes D8 enforceable, and **"`--check` flags it"** | there is no `--check` subcommand, and the token `answersAsOf` appears **nowhere** in `plan_findings_work.py`. 3 of the 24 checkable pairs are stale and no instrument says so |

**Two things § 4 got right and the tree confirms.** The member id prefix is
`F`/`Q`/`T` by genus and `MEMBER-PREFIX` is the conformance code — **0 violations
across 194 members.** And the atomic/prose line, found by the extraction run of
2026-09-08 rather than by the draft, is the one rule in § 4.1 with a working
enforcer: **0 presentation problems across all 65 records.**

**One drift § 4 could not have anticipated, because it names no element shape.**
`ownedBundles[]`, `contributions[]` on both records, and `ended.disposals[]` each
stand in **two disjoint key shapes** today. Where the schema shows an array and
never says what is in it, the first writer invents a shape and the second invents
another — and **nothing reads any of them closely enough to disagree.**

[&#8593; Contents](#contents)
