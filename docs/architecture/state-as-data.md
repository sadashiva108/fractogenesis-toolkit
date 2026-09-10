# State as data — the framework's own records, and the documents derived from them

**Written:** 2026-09-07, `session-management-re-evaluation-20260906-110105`, from  
the owner's proposal that a JSON config become the single source of truth.  
**Scope:** where the framework stores status, ownership, counts, relationships  
**Currency, 2026-09-10, `0037` F9:** eleven statements in §4 have drifted from the
records they specify. §4.3's example carried the retired `findings[]` key until
Revision 271. **The reasoning is retained; the claims about the data are not
current.**  

and dates, and how the markdown that displays them is produced.  
**Depends on:** `docs/session-management-findings/0043-framework-state-lives-in-documents-not-data/`,  
whose nine findings are the reading this design answers.  
**Consumed by:** `docs/architecture/allocation-and-inquiry.md` §10, which needs  
findings addressable and edges first-class and specifies nothing else.  

Written to be readable by someone who has never seen this repository. Nothing in
it is specific to reimaging a Mac.

---

## 1. The problem

`0043` holds nine findings and they have one cause: **the framework stores its
own state in the format it displays it in.**

- A bundle's status is carried in a **filename**, so every transition is an
  unlink plus a create. Four recorded instances of a bundle carrying two tags.
- **88 count and status cells** are typed by hand across the sessions index, the
  four findings indexes, the six manifests and the runbook rollup. A checker
  exists for no other reason than to notice when one stops agreeing.
- The data is **parsed back out of rendered markdown** by three checkers, in 22,
  23 and 43 lines of `awk`, `sed` and `grep`. Two recorded parser bugs, and a
  first run reporting 36 failures against a tree every other validator passed.
- Structured fields and free-form prose **share a file with nothing marking the
  boundary**, which is how a status sweep reached into a Finding column and
  altered what a reading claims.
- Authority is assigned to **documents**, so every consumer parses prose to read
  a fact.

None of those is a mistake anybody made. They are one structural choice seen
five ways, and the remaining four findings are consequences of it.

## 2. What this decides, and what it does not

**Decides:** where each fact lives, what shape it has, which documents are
generated from it, how generation is verified, and how the tree gets there.

**Does not decide:** anything about what the statuses *mean*. Every word keeps
its definition from `docs/legend.md`. This is a change to the container.

**Already decided elsewhere, and carried here unchanged:** the edge contract, as
`0043` D1 — findings addressed `<bundle>/F<n>`, edges typed and stored in the
bundle whose session asserted them, `Relates to` becoming a projection. And
`0043` D2 — the procedures that describe a format change in the revision that
ships it, not before.

## 3. JSON, and not YAML

The portability floor is macOS stock Bash 3.2 with a BSD userland and **no
declared runtime dependency**. `json` is Python's standard library and present
wherever `python3` is. `yaml` is not: it is present in the Linux VM sessions
happen to run in, which proves nothing about the target Mac, and requiring it
would be this repository's first runtime dependency.

`prepare-artifact-root.py` already establishes that Python 3 is available and
that a helper may be written in it. Nothing else is needed.

**The readability YAML buys is not needed**, because these files are not read by
hand. The markdown is what is read; the JSON is what is computed from.

## 4. The two files

One `metadata.json` in each session bundle, one in each findings bundle. Same
name in both, because the directory says which kind it is.

### 4.1 Rules that govern both

**Every repeatable field is an array**, even where it renders as one line today.
`0043` F6: a projection can always flatten a list into prose, and prose cannot be
widened back into a list without inventing the boundaries. `Relates to` was
modelled as a scalar in both drafts by a bundle that carries three of them.

**No presentation in the data.** `null`, never `"—"`. `null`, never `""`. No
markdown backticks inside an **atomic** value.

The atomic/prose line was missing from the first draft and the extraction run of
2026-09-08 is what found it, which is §9 step 3 working as designed. **Atomic
values** — a status, a model, a kind, a reason, a date, an id — carry no ornament
at all: `claude-opus-5`, never ``configured `claude-opus-5` ``, which is a
rendering instruction stored as data. **Prose values** — a finding's statement, a
decision's text, an edge's `why`, a note — are markdown by nature: their inline
code spans name real files and are part of the sentence, and stripping them would
damage the reading to satisfy a rule aimed at something else. The test is whether
a renderer would ever *add* the ornament: it adds backticks around a status, and
it does not rewrite a sentence. No object whose fields are all empty, because
a generator renders it as an empty table row. **The renderer adds the dash and
the backticks**; the data holds the fact or holds nothing.

**No fact that another file owns.** A session records the bundle numbers it owns
and what it owes each one. It does **not** record their subjects, kinds, finding
counts or statuses. A draft that did had already drifted before the schema
existed: a subject ending `"...not an operation\t3"`, a stray tab and finding
count welded on from an index row, and a `currentOwner` field naming a different
session than the one that owns the bundle.

**Nothing derivable is stored.** `currentOwner` is the entry in `owners[]` whose
`until` is null. Counts are computed. A stored derivation is a second copy.

**Closed vocabularies are validated.** A draft carried `"status": "unresolved"`,
a value the vocabulary retired three days earlier. A schema with an enumerated
set makes that a load error rather than a reading.

### 4.2 Session bundle — `metadata.json`

```text
{
  "schemaVersion": 1,
  "updatedAt": "2026-09-07T09:14:00-04:00",

  "bundleName": "pre-image-capture-conformance-20260903-194532",
  "createdOn": "2026-09-03",

  "owners": [
    { "from": "2026-09-03", "until": null,
      "assistant": "Claude",
      "sessionId": "session_01PcgHu9kz9Hm5RatLQuFR8H",
      "model": "claude-opus-5",
      "environment": "Linux VM on the owner's Mac, Bash 5.1.16, GNU coreutils",
      "environmentNotes": "Not macOS. The Bash 3.2 debt is extended, not paid." }
  ],
  "transcript": "https://claude.ai/code/session_01PcgHu9kz9Hm5RatLQuFR8H",
  "scratchPath": "/sessions/.../scratch/fractogenesis-toolkit",
  "resources": [
    { "what": "Repository", "path": "/Users/…/fractogenesis-toolkit" }
  ],

  "ownedBundles": [
    { "number": "0007", "notes": "Assigned so this bundle answers for the set" }
  ],
  "contributions": [
    { "bundle": "0041", "date": "2026-09-06", "contribution": "Sharpened F4" }
  ],

  "declaredState": null,
  "indexNotes": "A reading session: the report is the output",

  "ended": { "on": null, "reason": null,
             "revisions": [], "commits": [], "disposals": [] }
}
```

`environmentNotes` is where the two paragraphs of `metadata.md` prose go. They
are a **per-owner qualification** — which environment, and what it means for the
Bash 3.2 debt — so they travel with the row they qualify rather than sitting
beneath a table that may have grown since.

`declaredState` is normally `null` and the state derives. It carries a value only
for `handoff`, which is a **declaration**: a session says it handed on, where
`active`, `closed` and `withdrawn` follow from what it owns.

### 4.3 Findings bundle — `metadata.json`

```text
{
  "schemaVersion": 1,
  "updatedAt": "2026-09-07T09:14:00-04:00",

  "number": "0043",
  "bundleName": "0043-framework-state-lives-in-documents-not-data",
  "genus": "findings",
  "kind": "session-management",
  "subKind": null,
  "subject": "The framework's own state lives in documents rather than in data",

  "recordedOn": "2026-09-06",
  "recordedOccasion": "from the owner's proposal that a JSON config become …",
  "recordedBy": { "sessionBundle": "session-management-re-evaluation-…",
                  "sessionId": "session_01FhFbEgG4wmrtJqUCcryNVQ" },
  "severity": "F1 and F3 are high — both have recorded incidents",
  "feltAt": ["every STATUS- and STATE- tag", "all five INDEX.md files"],
  "scope": "session management",
  "read": ["docs/legend.md, the derivation table and the three vocabularies"],

  "progress": null,
  "ownership": null,
  "lineage": null,

  "members": [
    { "id": "F1",
      "statement": "A bundle's status is carried in a filename",
      "status": "framing",
      "statusReason": null,
      "statusNote": null,
      "updatedAt": "2026-09-06T23:41:00-04:00",
      "sectionHeading": "F1 — the status is in the filename",
      "reopened": null,
      "withdrawn": null,
      "resolution": null }
  ],

  "decisions": [
    { "id": "D1", "decision": "…", "members": ["F5", "F6"],
      "decided": "2026-09-07", "outcome": "accepted",
      "answersAsOf": "2026-09-06T23:41:00-04:00",
      "voidedReason": null,
      "sectionHeading": "D1 — the edge contract" }
  ],

  "contributions": [
    { "session": "allocation-and-inquiry-design-…", "date": "2026-09-06",
      "contribution": "Added F6 and the draft review" }
  ],

  "edges": [
    { "kind": "carried", "from": "0041/F1", "to": "0032/F1",
      "why": null, "reason": null,
      "basis": "asserted", "asserted_by": "…", "asserted_on": "…" },
    { "kind": "dropped", "from": "0041", "to": "0032/F5",
      "why": "the section it was about no longer exists",
      "reason": "no-longer-applies",
      "basis": "asserted", "asserted_by": "…", "asserted_on": "…" },
    { "kind": "constrains", "from": "0036/F1", "to": "0044/F1",
      "why": "what the checker is responsible for decides whether repairing four citations finishes the job",
      "basis": "asserted",
      "asserted_by": "allocation-and-inquiry-design-20260906-233205",
      "asserted_on": "2026-09-07" }
  ],

  "indexNotes": "Deliberately open — a parallel architecture is in design"
}
```

**`genus` says what sort of bundle this is, and the shape is DERIVED from it** --
Revision 270. Four genera -- `findings`, `commission`, `charter`, `remedy` -- in
two shapes, `reasoning` and `actionable`. **The shape is never stored**, because
nothing derivable is stored; `plan_findings_work.py` holds the map and `shape()`
is its only reader. **`kind` is unchanged and still means the subject domain**,
which is the second thing that field was never asked to carry.

**`findings[]` is `members[]`, and a decision cites `members` too.** Same
revision, and it was done **before** a second genus existed rather than after: a
commission holds questions and an actionable bundle holds tasks, so an array
named for one species cannot name the genus. Doing it afterwards is a breaking
change with no migration plan, which is `0052` F2. **The member id carries the
genus in its prefix** -- `F` a finding, `Q` a question, `T` a task -- and
`MEMBER-PREFIX` is the conformance code for a bundle whose members disagree with
what it says it is. **Verified by deriving `standing`, `progress`, `ownership`
and every member status for all 54 bundles on both sides of the rename and
comparing: 188 rows, byte-identical**, which is §9 step 2's round trip run on a
field rather than on the whole file.

**The four reason fields are `0039` D7 through D12.** `statusReason` carries the
enumerated reason for the transition that produced the current status, and
`statusNote` the optional prose. They are `null` where no transition took a
reason -- a first reading does not.

**`reopened` and `withdrawn` are objects or `null`**, and they hold what
`docs/legend.md` -> Reasons requires:

```text
"reopened": { "at": "2026-09-08T09:31:00-04:00",
              "reason": "resolution-regressed",
              "note": "the carve-out landed and 1c48deb dropped it",
              "sha": "1c48deb…",
              "decisionId": "D6", "resolutionId": "F5" }

"withdrawn": { "at": "…", "reason": "…", "note": null }
```

`reopened.md` is generated from that object. **Nothing is copied into it** -- the
SHA is the reference, and a copy would drift.

**`answersAsOf` is what makes `0039` D8 enforceable.** It records the finding's
`updatedAt` at the moment the decision was accepted. A decision whose
`answersAsOf` is older than its finding's `updatedAt` was answered against a
statement that has since changed, and `--check` flags it. Without it the
reframing rule depends entirely on someone remembering the rule exists; with it,
the case where nobody remembers is exactly the case that gets caught.

**`voidedReason`** is set only where `outcome` is `voided`, and is one of the
five `decided ──▶ framing` reasons.

**A resolution nests inside its finding**, because the resolutions table is one
row per finding. An orphan row becomes structurally impossible rather than
checked for. **A decision does not nest**, because one decision may answer
several findings; it carries a `findings` array, and §11's rule that every
`F<n>` cited exists becomes a schema check rather than a lint.

**`updatedAt` on each finding is `0043` F8's remedy.** `framing` names a
direction, not a position, so `framing` for an hour and `framing` for three weeks
are the same value and no noun separates them. A timestamp yields *`framing`
since 2026-09-06*, and therefore staleness, without a scheduled sweep inferring
it — and it tells the allocator where `readiness` cannot come from.

### 4.4 The three status fields

`0043` F1: a bundle has **one** `STATUS-` file, so three unrelated facts compete
for one slot. The legend already says two of the three are not progress at all.

| Field | Answers | Values |
|---|---|---|
| `standing` | where this bundle stands — the one value a reader wants | **derived and STORED** — the three fields below, in that precedence |
| `progress` | how far the reading has been taken, ownership aside | **derived and STORED** — `un-started`, `withdrawn`, `resolved`, `reopened`, `analyzing` |
| `ownership` | who owns this | `null` when owned per the manifest, else `unclaimed` or `transferred` |
| `lineage` | is this reading still authoritative | `null`, or `{ "supersededBy": "0041", "on": "2026-09-06" }` on the predecessor; `{ "supersedes": "0032", "on": "…" }` on the successor, whose provenance edges carry the per-finding accounting |

**Derived, and written down anyway.** This table read *derived, never stored*
until Revision 232. The owner reversed it on 2026-09-08: a reader should not have
to run a derivation table to learn a bundle's status, and `progress` being null on all 49
bundles meant the field existed and answered nothing.

That reintroduces what `0043` F2 is about — a derived value written down is a
second copy that can drift — so **the legend's condition applies rather than
being waived**: a copy is permitted *where a check fails when it drifts*.
`plan-findings-work.sh stamp` writes both fields and **nothing else may**;
`check` reports `UNSTAMPED` for a null and `STORED-DISAGREES` for a value that
does not match what it derives from, and both are tested. A hand-edited status is
a defect the next `check` names.

**`standing` and `progress` are not the same question and differ on 27 of 49
bundles.** `standing` layers ownership and lineage over the derivation, because
neither is progress: an `unclaimed` bundle is closed to every session whatever
its findings say, and a `superseded` reading is no longer authoritative whatever
it concluded. `progress` is the derivation alone — which is how `0001` reads
`standing: unclaimed` and `progress: analyzing` at once, and that pair is exactly
the drift `0047` F1 records.

**A session carries `state` on the same terms.** `declaredState` keeps its name
and its prefix: it is what the **owner declared**, and a `handoff` or a
`withdrawn` cannot be derived from what a session holds. `state` is the effective
value — the declaration where there is one, the derivation where there is not.
It was absent from all seven sessions and is now stamped and checked.

**The derivation table shrinks from eight rows to five** and stops being an override list.
Rows 1, 1b and 2 leave because they were never derivations — they are the two
non-progress fields, which had nowhere else to go.

**This does not merge the two vocabularies**, and must not. The bundle set
carries judgements no aggregation gives you: `resolved` requires *at least one*
resolved, which has no finding-level analogue; row 4 sits above row 5 so a bundle
of nothing but withdrawals is `withdrawn` rather than `resolved`; `reopened`
dominates the inert only when reopening is the whole of the live work. The two
sets also answer different questions — *A finding* is keyed on who may read and
record, *What another session may do* on whether opening the bundle is worth
anything at all. **The derivation is a bridge between two vocabularies, not an
identity.**

The `STATUS-` and `STATE-` tag files are then redundant. **They went, at
Revision 222** -- see §11.2, which asked the question and now records the answer.
A transition stops being an unlink because it stops being a file at all.

## 5. The line between data and prose

**The data holds metadata. The markdown holds the reading.**

Status, counts, dates, ownership, kind, relationships, revisions and commits
compute. The finding's sentence, the rejected alternatives, the reasoning — that
is what a bundle is *for* and it never moves. `docs/architecture/findings-and-sessions.md`
§8 states why: an AI session asked to update a document will rewrite it to match
the current understanding, and freezing `findings.md` is a structural defence
against that.

**The hard case is the Findings table**, which carries a number, a sentence and a
status — half computed, half authored. Two ways, and this is the real decision:

- **Generate the whole table**, with the sentence in the data. Clean, and it puts
  a finding's text in JSON where nobody reads it in context.
- **Keep the table authored**, and let the data carry only the bundle rollup.
  Then the per-finding status has two homes again, which is what this is escaping.

**Recommended: generate it**, and accept the sentence living in the data,
*provided* the generated region is fenced (§6.2) so a reader sees at a glance
which half of `findings.md` is authored and which is projected. That fencing is
`0043` F4's answer, and F4 is the finding that says nothing marks the boundary
today.

## 6. Generation

### 6.1 The map

Every table in the tree, its row source, and where each column comes from.

| Output | One row per | Columns |
|---|---|---|
| `docs/sessions/INDEX.md` | session file | `bundleName` · derived state · last `owners[]` entry · `len(ownedBundles)` · Σ findings across those bundles · `indexNotes` |
| `<session>/findings-manifest.md` | `ownedBundles[]` | `number` · link from the bundle's `bundleName` and `kind` · `kind` · `subject` · finding count · derived status · the session-side `notes` |
| `<session>/metadata.md` — Owners | `owners[]` | the six columns verbatim; `environmentNotes` renders below the table |
| `<tree>/INDEX.md` | every bundle file whose `kind` matches | `number` · `bundleName` · `subject` · count · derived status · owning session · `indexNotes` |
| `runbook-findings/INDEX.md` — rollup | grouped by `subKind` | subKind · bundles · Σ findings · count where derived status is `resolved` |
| `runbook-findings/INDEX.md` — detail | as the other trees, plus `subKind` | |
| `findings.md` — header | the bundle file | the schema fields, `Relates to` projected from `relates-to` edges |
| `findings.md` — Contributions | `contributions[]` | three columns |
| `findings.md` — Findings | `findings[]` | `id` · `statement` · `status` |
| `decisions.md` | `decisions[]` | five columns verbatim |
| `resolutions.md` | `findings[]` where `resolution` is not null | `id` · `resolvedBy` · `whatWasDone` · `revision` · `commit` |

Generalising `runbook` to `kind`/`subKind` makes the rollup one grouping rule
rather than a special case for one tree.

**The owning session is computed by scanning session files**, never stored on the
bundle. That preserves the existing rule — `findings-manifest.md` is
authoritative for ownership — and makes the two sides unable to disagree.

### 6.2 Markers

Every generated region is fenced so a reader can see what is authored and a
generator can replace a region without touching the prose around it:

```text
<!-- generated:findings-table -->
| # | Finding | Status |
…
<!-- /generated:findings-table -->
```

### 6.3 Additive only

**The generator never creates a document.** It refreshes the marked regions of
one that exists. A bundle written from scratch has prose the data does not carry,
and a generator that could create files would produce a document with the tables
right and nothing else in it.

## 7. Verification

**This design's own risk is the generator.** Today drift is possible and the
checkers catch it. Under generation drift is impossible — and a bug rewrites
forty files at once, silently, which nothing catches.

That is not hypothetical in this tree. `0043` F3 records two parser bugs and a
first run reporting 36 failures against a clean tree; `0042` F4 records a
rendering audit whose first run reported 131 failures of which **128 were bugs in
the audit**.

**`--check` is the answer, and it is the verification this session has used on
every patch today.** Regenerate into a scratch tree, diff against what is
committed, exit non-zero on any difference. If the only differences are the ones
the change intended, the generator is sound.

It replaces the `findings-counts` check entirely and is stronger: that script
detects drift after the fact, where `--check` makes drift impossible unless the
generator is wrong, and catches that too. It also closes the gap found at
Revision 212 — the **prose total at the foot of a manifest**, which the script
never covered, and which read *36* where its bundles held *37*.

**The derivation needs a fixture set, and `analyzing` is why.** `0043` F7: every
row of the derivation table states a positive condition with a witness except `analyzing`,
which is *any other combination*. A derivation bug always lands there and looks
entirely plausible. Checking it means proving a negative, so the fixtures must be
bundles that each land on a **named** row, plus at least one that lands on
`analyzing` **for a stated reason** rather than by falling through.

## 8. `metadata.md` survives, and stops being authoritative

Its content is entirely structured bar two paragraphs, which is why it reads as
redundant. But it is **cited by thirteen documents** — the instruction set,
`docs/legend.md`, the architecture record, `docs/sessions/INDEX.md`, two
`prompt.md` files and both copies of `0027`/`0037`. Removing the file is a rename
in `0030`'s sense and breaks all thirteen.

**Keep the path; move the authority.** `metadata.json` becomes authoritative and
`metadata.md` becomes a rendered view like every other table. The two prose
paragraphs become `environmentNotes` on the owner row they qualify.

The same reasoning governs `findings-manifest.md` and every `INDEX.md`: they are
navigated to, linked from, and read. **What changes is that they stop being the
source, not that they stop existing.**

## 9. Migration

One revision, mechanical, in this order.

1. **Generate the JSON from the tree**, one way, by parsing what exists. This is
   the third generation of the markdown parser `0043` F3 is about — and the last
   one ever written, which is what makes it worth writing.
2. **Verify by regenerating the markdown from the JSON and diffing against the
   committed tree.** A clean diff means the extraction lost nothing. This is
   `--check` doing its first job before it has a second.
3. **Reconcile what the diff shows.** Every difference is either an extraction
   bug or a fact that was wrong in the tree — and the second kind is a finding,
   not a fix to paper over.
4. **Commit the JSON alongside the markdown**, both correct, before anything
   depends on the JSON.
5. **Then, in later revisions**: the tag files, the checkers, §9 step 3 per
   `0043` D2, and §11's removal of `Relates to` from the header schema.

**Scope:** roughly 40 findings bundles, 6 session bundles and 5 index files.

**The extraction will fail on some bundles and that is the point.** Twenty-three
headers hold `Session: —`. Four bundles carry finding rows that never moved.
Ten `decisions.md` and `resolutions.md` name the wrong bundle. Every one is a
recorded finding, and each will surface as an extraction that cannot produce a
clean round trip. **A migration that reported no problems would be the thing to
distrust.**

## 10. Alternatives rejected

| Alternative | Why not |
|---|---|
| YAML | Requires a package outside the standard library, on a repository with no declared runtime dependency. §3 |
| A database, service or MCP server fronting the tree | Rejected in `findings-and-sessions.md` §11 and again in `allocation-and-inquiry.md` §11; the rejection stands. A session without it could not read the structure at all |
| Keep the markdown authoritative and add more checkers | It is what exists. Three checkers, 88 hand-typed cells, two parser bugs, and a defect the checkers passed on at Revision 212 |
| One `edges.json` for the tree | A file every session must write, which is `0038` F1 exactly. `0043` D1 |
| Store the derived status | A stored derivation is a second copy, and `0032` is the live instance: tagged `superseded` with four rows reading `un-started`, both true, one sayable |
| Retire `metadata.md` | Thirteen citations. §8 |
| Generate a document that does not exist | Produces a file with the tables right and nothing else. §6.3 |

## 11. Open questions

**11.1 Does the Findings table's sentence live in the data?** §5 recommends yes
and fences the region. The cost is a finding's text sitting in JSON, read out of
context by anyone who opens the file rather than the page.

**11.2 What happens to the tag files? — ANSWERED, Revision 222: gone.**

Rendering them would have kept `ls` answering the question, and kept the unlink
problem for the generator rather than the session. Removing them makes `ls`
uninformative, which is a real loss and the reason the question was open.

What settled it: a rendered tag is **a second copy of a derived fact**, which
§10 rejects by name, and the whole of `0043` is the cost of copies. The `ls`
convenience did not survive being weighed against re-creating the defect the
change exists to remove.

**The round trip is what made it safe.** §9 step 2 was run for this field first:
the derivation was computed for all 47 bundles and 7 sessions and compared
against every tag in the tree. **54 of 54 agreed** -- after two corrections the
comparison itself forced, both recorded below. Only then were the tags deleted.

Two things the run found, and neither was an extraction bug:

**Ownership is computed from the session manifests, never stored.** §6.1 already
said so; the first extraction ignored it and read `unclaimed` off the tag, which
is the same second copy in a different file. `findings-manifest.md` is
authoritative for ownership, so deriving from it makes the two sides unable to
disagree.

**`unclaimed` means live work nobody holds, not merely "no owner".** Six bundles
came out `unclaimed` over rows reading `resolved`. A finished reading is in no
queue and needs no owner, so the rule excludes bundles whose progress is
`resolved` or `withdrawn`. That precision had never been written down, because a
human applying the derivation table by hand never needed it.

And one thing it found in the tree: `0010` and `0024` were indexed `un-started`
while listed by no session at all. Derivation table row 1 sits above row 3, so both are
`unclaimed`. **The old checker could not have caught it** -- it compared a tag
against a row, and both held the same wrong value. The replacement compares a
display against the source.

**11.3 Who may assert an edge?** Carried from `allocation-and-inquiry.md` §13.1
unresolved: recording to a `framing` finding is open to any session and an edge
is a record write, so the permissive answer follows — but an edge changes what
other sessions are *shown*, which no other record write does.

**11.4 Does `schemaVersion` earn its place before there is a version 2?** Kept,
because the migration in §9 is the first of at least two and the second will want
to know what it is reading. Cheap to carry, impossible to add retroactively.
