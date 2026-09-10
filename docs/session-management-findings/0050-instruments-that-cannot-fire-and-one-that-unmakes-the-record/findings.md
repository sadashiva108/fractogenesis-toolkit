# Three instruments are correct and cannot fire, and one unmakes the record it reads

**Recorded:** 2026-09-09, while deciding `0049` and `0042` — three of the four were found by trying to use the thing they guard.  
**Session:** `assurance-coverage-20260908-204724`  
**Severity:** F3 is high and is the only one whose damage is partly irrecoverable — one run destroys fifteen asserted edges and a hundred and seven stamped values; the 107 re-derive and the 15 do not, and twelve of those are Revision 234's decisions. F1 and F2 cost nothing today and cost everything on the day they are relied on.  
**Felt at:** `.claude/settings.json`; `.claude/hooks/write-location-guard.sh`; `.internal/ai-scripts/session-management/verify-findings-headers.sh:201`; `.internal/ai-scripts/session-management/extract-metadata.py`; `.internal/ai-scripts/session-management/doc-currency.json`  
**Scope:** session management. Two one-line repairs, one guard on a destructive script, and a class that has no owner.  
**Relates to:** `0049` — F1 here is `0049` F4 recurring one layer out, at the same revision distance  
**Relates to:** `0047` — its F5 reads the family as *the half that reads the tree is wrong, not the half that judges it*. **None of these four fits either half**, which is F4  
**Relates to:** `0043` — F3 here is what happens to the data `0043` is designing, run against the tree it is designed for  
**Relates to:** `0039` — its D17 is the concern F3's existing guard was built for, which is why that guard does not reach the hazard F3 names

**Read:**

- `.claude/settings.json` and all three hooks in `.claude/hooks/`
- `.internal/ai-scripts/session-management/extract-metadata.py`, `doc_currency.py`, `verify-findings-headers.sh`
- `docs/architecture/state-as-data.md` sections 6, 8 and 9
- every `metadata.json` in `docs/`, at `HEAD` and after one extraction run

Recorded by the session that owns `0049`, from the reading that decided it.
**Not owned.** Parked rather than worked: three of the four fixes are toolkit
writes, and the bundle type for those does not exist yet.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | The write-location guard does not cover the tool a bridged session actually writes through, and reads the wrong root | `framing` |
| F2 | A schema exemption guards on a marker file Revision 222 deleted, so the exemption can never apply | `framing` |
| F3 | Running `extract-metadata.py` on a healthy tree destroys every asserted edge and every stamped value | `decided` |
| F4 | Four instruments in three days were correct and could not do their job, and no bundle covers that class | `framing` |
| F5 | The coverage sweep keeps a second copy of a directory list `docs/INDEX.md` owns, and 43 files are invisible to it | `framing` |
| F6 | `0050` F3 counted two field families of twenty: one run destroys 429 recorded values, and section 10a routes a session into running it | `decided` |
| F7 | Nothing compares a commit message's assertion against what the commit contains, and a mis-scoped message burns a revision number | `framing` |
| F8 | The instrument that catches a revision number taken and never written is correct, fires, and is run by nothing | `framing` |
| F9 | When it fires, nothing says who owes the missing entry or how a late one is written | `framing` |
| F10 | Clearing a `MISSING` requires creating a permanent `ORPHANED`, so the count moves the wrong way when someone does the right thing | `framing` |

## F1 — the guard does not run where the writing happens

`.claude/hooks/write-location-guard.sh` was added at Revision 232 to close
`0049` F4. It denies a write whose `file_path` is inside `$CLAUDE_PROJECT_DIR`
and warns on a shell command naming it. `.claude/settings.json` matches it on
`Edit|Write|MultiEdit|Bash`.

**A session bridged to the owner's machine writes through neither.** It writes
through `mcp__remote-devices__device_bash` and
`mcp__remote-devices__device_commit_files`. Neither name matches the matcher, so
the hook does not run at all.

**And it would not fire if it did.** `$CLAUDE_PROJECT_DIR` in a bridged session
names the assistant's own container. The checkout is at
`/Users/dkittrell/workspace/shiva/fractogenesis-toolkit`, so
`case "$path" in "$root"/*)` compares a real write against a root it never
matches.

This is `0049` F4 in its own words — *"the Revision 231 guard matched
`Edit|Write|MultiEdit`, and every one of the writes it was meant to catch was a
`cp` inside a Bash call"* — one revision later and one tool boundary out. The
fix and the false positive it produces are decided in `0049` D4.

## F2 — an exemption for a file that no longer exists

`.internal/ai-scripts/session-management/verify-findings-headers.sh` line 201
guards its finding-status check with:

```text
if [ ! -f "$dir/STATUS-superseded" ]; then
```

Its comment says *"A `superseded` bundle is exempt: its rows are frozen evidence
of what the tree looked like, and three bundles are retained precisely for
that."*

**Tag files were removed at Revision 222.** No `STATUS-*` or `STATE-*` file
exists anywhere in the tree, so the condition is always true and the exemption
never applies to anything.

**It costs nothing today**, which is why nothing has noticed: all seven
superseded bundles happen to carry Status cells holding valid values, so the
check they are no longer exempt from passes on them anyway. It costs on the day a
superseded bundle's frozen rows carry a word from a retired vocabulary — which is
the case the exemption was written for, and the case section 9 forbids repairing.

**Half of Revision 222's migration was completed.** The sibling check forty lines
below reads `metadata.json` for `"supersededBy"` and is correct. One reader was
migrated and one was not, in one file. That is the standing constraint
*retrofit; never leave half a change behind*, broken inside the revision that
wrote it.

## F3 — the extractor unmakes the record

`extract-metadata.py` rebuilds every `metadata.json` by parsing the markdown.
**It is single-direction by construction**, and that is not a defect in itself:
it was written as a migration parser, *"the third generation of the markdown
parser `0043` F3 is about — and the last one ever written"*.

The defect is that **every field which exists only in the JSON is collateral**,
and nothing addresses that.

### Its guard is aimed at a different event

The script carries a one-way guard. It refuses to run once generated-region
markers exist, because after `state-as-data.md` section 9 step 5 flips authority
the markdown becomes a projection, and re-parsing generated output back into its
own source can only lose.

**That guard is correct and it is watching the wrong hazard.** It protects
against re-parsing generated markdown — `0039` D17's concern, and a migration
that has not happened. It says nothing about the run that is possible *today*, on
the tree as it stands, where the markdown is still the source and the JSON
carries fields the markdown has never held.

So this finding is not *the guard is unarmed*. The `state-schema` watch is
unarmed. **This one is aimed.**

### What one run costs, measured

On a clean tree at Revision 238, commit `52a4376`:

| | at `HEAD` | after one run |
|---|---:|---:|
| asserted provenance and decision edges | **15** | **0** |
| non-null `standing`, `progress` and `state` | **107** | **0** |
| `metadata.json` files rewritten | — | **58** |

### The asymmetry, and why it is the whole argument

**The 107 re-derive. The 15 do not.**

`./bin/plan-findings-work.sh stamp` restores every derived value, because that is
what derived means: `standing`, `progress` and `state` are computed from the
finding rows, and the finding rows are in the markdown.

Nothing restores the edges. An asserted edge is a **judgement somebody made** —
twelve of the fifteen are Revision 234's decision edges, *"the first allocation
this repository has produced with a graph behind it rather than load balancing
alone"* — and no derivation puts a judgement back. They were asserted into the
data directly and appear in the markdown nowhere. Only `git` has them.

The two session bundles Revision 237 created lose `owners`, `resources`,
`createdOn` and `state` in the same run. Three of those four are also judgements.

**That asymmetry decides the remedy.** A tool whose damage is fully recoverable
needs a warning. **A tool whose damage is partly irrecoverable needs a refusal** —
an interlock that counts the JSON-only fields it is about to drop and stops,
naming them, unless it is overridden deliberately. A warning on this tool would
be read by the session that most needs it as noise, because the run reports
success.

`--dry-run` is honest and writes nothing. That was tested before it was written
down, because **the first test of this finding was run against the wrong baseline
and reported no loss at all** — two post-extraction trees compared against each
other, both already stripped. The clean result was the wrong result, and the only
thing that caught it was refusing to trust it.

### Re-measured at Revision 288, and the asymmetry is forty-one times wider

**F3's argument is right and its numbers were the smallest of three
measurements.** Snapshot, live run, flatten and count: **66 of 66 files
rewritten, 740 recorded values destroyed, 22 distinct fields.** Then
`plan-findings-work.sh stamp` on the stripped tree and count again: **it restores
120 and 620 do not come back.** F3 above says *the 107 re-derive, the 15 do not*.

**`genus` is 54 of the 620 and is the fact that decides D3.** The field arrived
with Revision 271's migration; the parser was written at Revision 224 and has
never heard of it, and `stamp` does not restore it because `genus` is stored
rather than derived. **A run does not re-migrate the tree, it reverts it to a
schema that no longer exists** — silently, because a parser cannot report a field
it does not know about.

**And the suite executes this script.** `check-completeness.sh` line 53 is
`exec python3 "$SCRIPT_DIR/extract-metadata.py" --check`, and `completeness` is in
`verify-session-findings.sh`'s `all`. `DRY` is `"--dry-run" in sys.argv`, so the
safe invocation is the one a session runs several times an hour and **one argv
token separates it from the destructive one.**

**Afterwards the instruments report a nearly clean tree**: `counts` FAIL 0,
`headers` FAIL 11 — the standing baseline, unmoved — `structure` FAIL 1,
completeness 3 problems. **Four rows against 620 destroyed judgements**, and 52
of the 66 files reformatted end to end besides, because this script writes
`ensure_ascii=False` where `plan_findings_work.py` writes the default. That is
`0050` F4's class arriving inside `0050` F3: the record can be unmade and the
assurance layer barely moves.

## F4 — the class, and nothing covers it

Four instruments, three days:

| Instrument | Revision | State |
|---|---|---|
| the `state-schema` currency watch | 232 | edge asserted, tier `critical`, `sourceDigest` never set — it can only report `UNCONFIRMED` and can never reach `DRIFTED` |
| the `STATUS-superseded` exemption | 222 | guards on a file the same revision deleted |
| the write-location guard | 232 | matcher misses the tool that writes; root is the wrong root |
| `extract-metadata.py` | 224 | **guarded, and aimed at the wrong event.** Its one-way guard watches for an authority flip that has not happened; the live hazard is that every JSON-only field is collateral on a run that is possible today |

The first three are **correct, installed, and unable to do their job**. The
fourth breaks the pattern and is worse: it is a **correct instrument aimed at the
wrong target while a live hazard goes unwatched**. It is not unarmed. It fires,
at the wrong thing, and the thing it does not watch takes twelve human judgements
with it and reports success.

`0047` F5 names the family the first three look like they belong to — *the half
that reads the tree is wrong, not the half that judges it*. **None of these four
fits it.** Nothing here misreads the tree. The watch reads correctly and has no
baseline to compare against; the exemption's predicate is well-formed and its
subject was deleted; the guard's logic is right and it is never invoked. **The
defect is in the wiring, not in either half.**

The repository's standing warning is that every check it has shipped failed
loudly against a healthy tree on its first run. **These are the opposite failure
and it is quieter**: a check that passes because it never ran is indistinguishable
in every report from a check that ran and found nothing. Six loud failures were
all caught within a revision. These four were caught between two and sixteen
revisions late, and three of them only because a session tried to rely on them.

## F5 — the instrument that reports the gap has a gap it cannot report

**Recorded 2026-09-09**, on the owner's question whether references, architecture
records, ledgers and rules could be watched for staleness against the instruction
sets and prompts.

`verify-doc-currency.sh --coverage` exists to answer exactly that: *what is not
watched*. It reports **21 unwatched files** and closes with

> *An unwatched file is not protected. Add it to a watch, or accept it
> deliberately — the point is that the gap is visible rather than assumed.*

**The gap is not visible.** `doc_currency.py:104` walks five hard-coded roots:

```text
roots = (".claude", ".github", "docs/architecture", "docs/ledgers", "docs/ideas")
```

plus four named files. It does not walk `docs/rules/`, `references/`, or the
repository-root runbooks. Counted 2026-09-09:

| | files |
|---|---:|
| watched | 30 |
| reported unwatched | 21 |
| **neither watched nor reported** | **43** |

The 43 are `docs/rules/` (1), `references/` (11) and the 31 runbooks at the
repository root. **They are not unwatched; they are invisible**, and the
difference matters because the report's own closing sentence promises the
opposite.

### The sharpest instance is the newest rule document in the repository

`docs/rules/rule-enforcement-avenues.md` was created by **Revision 249**. The
root list predates it, and nothing updated the list when the directory was made.
So the document that argues about where a rule can be enforced is outside the
sweep that would tell anyone it had gone stale.

### Why this is a second copy rather than an oversight

**`docs/INDEX.md` is authoritative for the list of directories under `docs/`** —
the session management set says so, and `docs/INDEX.md` line 13 lists `rules/`
with a description. The correct list exists, is maintained, and is one file away.

`doc_currency.py` keeps its own copy in code. `docs/legend.md` permits a copy
only where it is generated, or where a check fails when it drifts — and **nothing
fails when this one drifts.** It is the same shape as `verify-doc-paths.sh`'s
hard-coded document list, and as `0036`'s prune whose stated reason expired at
Revision 162 and went on being quoted for six weeks.

**This is the fifth member of F4's family and the first that is not merely
unarmed.** The others are correct instruments that cannot fire. This one fires,
reports a number, and the number is wrong by 43 in the direction that reads as
safety.


## F6 — F3 measured two field families out of twenty, and the procedure that needs the extractor has no step for running it

F3 counted what one run of `extract-metadata.py` destroys as *fifteen asserted
edges and a hundred and seven stamped values*. That was two field families. The
same measurement taken at `13b00b3` (Revision 260), by diffing every file the
run rewrites against `HEAD` and counting each scalar that goes from a value to
`null` or absent:

| what the run rewrites | |
|---|---:|
| `metadata.json` files rewritten | 62 |
| distinct fields that lose a value | 20 |
| **recorded values destroyed** | **429** |

The largest groups:

| field | values lost |
|---|---:|
| `standing` | 53 |
| `progress` | 53 |
| `findings[].updatedAt` | 53 |
| the seven fields of each asserted `edges[]` entry | 27 × 7 |
| `state` — every session bundle in the tree | 9 |
| `ownedBundles[].path` and `.assignedOn` | 12 each |
| `indexNotes` | 6 |
| `decisions[].answersAsOf` | 7 |
| `transcript`, `scratchPath`, `owners[].environmentNotes` | 1, 2, 2 |

**The five values of `standing` all go the same way** — 18 `answered`, 13
`analyzing`, 10 `unclaimed`, 7 `superseded`, 5 `assigned` — so the loss is not
confined to bundles in one state, and nothing in the output distinguishes a
bundle whose standing was destroyed from one that never had it.

**`state` is the sharpest of the twenty.** `docs/legend.md` gives a session
exactly three live values, and one run of the regenerator leaves all nine
session bundles in the tree with none. The instrument that exists to make the
data authoritative is the one thing in the repository that can empty it.

### The reason a session runs it anyway

Section 10a releases a bundle in four steps and none of them is *regenerate*.
The steps are correct as written and they are not sufficient: `ownership` is
derived and stored on the bundle, `verify-findings-structure.sh` derives its tag
from `ownership` first, and so a bundle released by the four steps alone has an
index row reading `unclaimed` and a tag still reading `analyzing`.

Measured on this closing: **the seven releases produced seven `structure`
failures**, 65 OK / 0 FAIL to 59 OK / 7 FAIL, each of the form
`tag says 'analyzing', row says 'unclaimed'`.

**Running the extractor clears all seven.** It is the only instrument in the
repository that does. So the procedure leaves the tree failing a check, and the
one action that reconciles it destroys 429 values — a session following section
10a exactly is routed toward the destructive act by the failure the procedure
itself produces.

This closing set the two fields by hand instead, matching `0052` and `0001`,
which carry `standing` and `ownership` as `unclaimed` with `progress` left at
its derived value. That is a repair of this tree, not of the procedure.

### The false positive to expect first

A check that refuses to run the extractor unless the tree is clean will fire on
the one occasion the extractor is legitimately needed — a session that has just
composed changes and wants the derived fields to match them. **A guard here is
warn-only or it is the wrong instrument**, and the durable fix is not a guard at
all: the run should preserve every field it does not derive, at which point
there is nothing to guard against.

## F7 — the message asserts, the commit contains, and nothing compares the two

**Recorded 2026-09-10**, from reading a commit whose message described work the
commit did not carry, and sharpened by a relay from
`entity-model-and-vocabulary-20260909-053548` which had two further instances.

`.share/check-manifest-revision.sh` compares the **manifest** against the
revision. Nothing compares the **message** against the diff. So a commit may
assert in prose that it did something it did not do, and every instrument in the
repository passes.

### Three instances, measured at `777f468`

| Commit | Subject names | Manifest entries it actually adds |
|---|---|---|
| `636eba0` | Revision 271 | **Revision 270** — another session's |
| `889b8ac` | Revision 285 | **Revision 284** — another session's |
| `777f468` | Revision 287 | **287 and 286**, both its author's |

**The third is not the defect and separating it is the whole difficulty.**
Revision 266 established that a revision and a commit are not one-to-one, so a
commit carrying two revisions is correct. **A commit carrying someone else's
revision under your subject line is not.** A check that cannot tell those apart
fires on every legitimate multi-revision commit, which is six instruments' worth
of first-run false positives in this repository already.

**The discriminating question is not *how many* but *whose*.** `777f468` adds two
entries and both belong to the session that wrote the message; `889b8ac` adds one
and it belongs to a session that was not the author. That is mechanical: the
entry's own text names what it did, and `git log` names who committed.

### The second-order cost, which is worse than the first

**`check-manifest-revision.sh` has read commit subjects since Revision 278** —
`0047` F12 — so it sees `Revision 285` in the log and will not hand 285 out again.
**A mis-scoped subject therefore consumes a number.** Measured: `APPLY-MANIFEST.md`
contains one occurrence of the string *Revision 285*, and it is Revision 286's
`supersedes Revision 285 and earlier`. **No entry is numbered 285, and none ever
can be.** The manifest reads 287 · 286 · 284, and the gap is permanent.

This is the sharpest kind of instance the bundle has: the instrument that reads
the log is **correct**, and reading the log correctly is what turns a wrong
sentence into an irreversible one. **`.share/check-manifest-revision.sh` says so
in its own header** — lines 27–28 name `636eba0` as the reason it consults the
log at all. **The remedy for the first instance is what made the second
permanent.**

### All three commits are one session's, and the mechanism is renumbering

The three do not show three sessions making one mistake. **Every one carries
`session_01LSgzo7EtPPVJ1gG8s4NVNW`** —
`entity-model-and-vocabulary-20260909-053548`. That changes what is being
described: not a habit spread across the tree, but one session's composing loop.

**`889b8ac`'s own message states the loop.** *"Composed as 280, renumbered to 282,
283 and 285 while in review, and rebuilt by script after the first rebase produced
a patch that would have reverted two of the other session's revisions."* The patch
directory holds the evidence as five files for one composition —
`280-a-third-session.patch` at 17 files, then `282`, `283`, `285` and `286` at
nine files apiece. **One stable composition, renumbered four times.**

**So the subject and the entry come from different moments.** §7 says take the
number at apply time; a number re-taken three times during review is taken at
compose time, three times over. The subject is written from the most recent number
taken, while the entry actually sitting in the tree is the previous apply's — which
is exactly the off-by-one both mismatched commits show: subject 271 over entry 270,
subject 285 over entry 284.

**That makes the check narrower and more buildable than it first looked.** It does
not need to judge a message against a diff in general. It needs one comparison:
**the revision named in the subject must be among the entries the commit adds.**
`777f468` passes — it names 287 and adds 286 and 287. `636eba0` and `889b8ac` fail.
And the *whose-revision* test stays as the second clause, because a commit adding
an entry that names another session remains wrong even when the arithmetic works.

### Why this is in `0050` and how it differs from F4

F4's four members are **instruments that exist, are correct, and cannot fire.**
F7 is the other side of the same reading: **a region with no instrument at all.**
`docs/rules/rule-enforcement-avenues.md` §2 calls that `nowhere` and says it has
to be written down as one, *"because a rule with no instrument is otherwise quoted
as enforced"* — and `iris/verifications.md` §8 already names this exact region
**the highest-value guard not built**, on the strength of Revisions 241–246, which
were composed, verified, applied and committed with no entry at all. Those are the
inverse of these three: a change with no entry, against an entry with no change.

### What this finding does not decide

**The rule is not this bundle's to write.** A commit message is valid only for the
patch it was handed over with, and that sentence belongs in
`.github/session-management-instructions.md` §7, which is
`entity-model-and-vocabulary-20260909-053548`'s, the three rule documents being
that session's. It has said it will take it. **The instrument is this bundle's**, and it is not built here either —
building it before the rule exists would mean inventing the rule inside a checker,
which is the move `0041` D1 and `0050` D2 both refuse.

**So F7 is recorded `framing` and stays there**, with a `blocks` edge from the
rule to the check rather than a decision taken ahead of it.

### The subject is not the only half, and `15069fe` proves it twice

**Recorded 2026-09-10** from reading the commit that carried this session's own
Revision 289. Everything above is about the **subject line**. The body and the
trailers fail in ways the subject test cannot reach, and one commit demonstrates
both.

**A literal unfilled template slot reached the log and cannot be removed.**
`15069fe`'s message reads:

```text
Revision 291: a check outlived its question, and 0050's decisions land

<0050 half — one paragraph, written by whoever did that work>

0047 F1 and F2 resolve against one decision. …
```

The angle-bracketed line is a placeholder. `.github/session-management-instructions.md`
§5 states the rule it breaks — *"a placeholder belongs in a schema or a template,
never in a record"* — and a commit message is the one record in this repository
that **cannot be corrected**, because history is never rewritten. **Twenty-three
`Session: —` headers are gaps a later session can fill; this is a gap nobody can.**
Unlike the subject mismatch, this needs no comparison against anything: it is
decidable from the message alone, which makes it the cheapest check in the family
and the only one here that could be a `PreToolUse` refusal rather than a report.

**And the trailer attributes the work to the wrong session.** `15069fe`'s
`Claude-Session` is `session_01H9nWPECCmRoZDipJSYA2iS` —
`drift-and-the-write-boundary-20260909-053548` — on a commit whose eight files are
`instruments-and-blind-spots-20260909-220203`'s Revision 289. The message was
composed by the first session for a different ten-file change set and applied to a
commit containing none of it.

**That inverts a mechanism the repository already relies on.**
`iris/verifications.md` §5 records three session identifiers recovered *from this
trailer* when nothing else held them, and warns that a session looking for what it
wrote "finds nothing and concludes wrongly". Here the failure runs the other way:
the log asserts a session wrote work it did not write, and the trailer is the only
machine-readable field in the message. **`metadata.md` is authoritative for who
did what**, and for this commit the two disagree, permanently.

**Neither is a fifth instance.** Both are the same commit as the fourth, read
below the subject line — which is the point: the subject test F7 proposes would
have passed the body and the trailer without looking at them.

## F8 — the instrument is correct, it fires, and nothing runs it

**Recorded 2026-09-10**, after this session told the owner that two manifest gaps
were undetected and permanent. **Both halves of that were wrong**, and finding out
how they were wrong is the finding.

`bin/verify-manifest-coverage.sh` compares the commit log against
`APPLY-MANIFEST.md` and reports three conditions. Run against `15069fe`:

```text
MISSING    Revision 285  claimed by 889b8ac — no entry in the manifest
MISSING    Revision 291  claimed by 15069fe — no entry in the manifest
ORPHANED   Revision 271  claimed by 636eba0 — entry introduced by 30b0c36
ORPHANED   Revision 290  claimed by eb8b6de — entry introduced by 15069fe
DUPLICATE  Revision 265  claimed by 3fa5416 a8867ef

MISSING: 2   ORPHANED: 4   DUPLICATE: 1
Baseline at Revision 277: MISSING 0, ORPHANED 3, DUPLICATE 1.
```

**It names both gaps, by number and by commit, and it prescribes the repair** —
*"Write the entry; do not renumber the commit."* So the numbers are not burned
and the condition is not invisible. **Everything this session said was missing was
already built.**

**What is true is worse and quieter: nothing runs it.**

| | |
|---|---|
| in `bin/verify-session-findings.sh`'s subcommand table | **no** |
| in `all` | **no**, and therefore in nothing a session runs routinely |
| executed by any script, hook or config in the tree | **no** — `grep` over `*.sh`, `*.json`, `*.yml` finds no caller |
| named anywhere a session reads | prose only: the instruction set, `rule-enforcement-avenues.md`, `0047`'s record |

**The one runtime pointer to it is itself unreachable by default.**
`.share/check-manifest-revision.sh` prints *"a number is taken in the log and
written nowhere in the manifest … `bin/verify-manifest-coverage.sh` names which"*
— **on stderr, under `--verbose` only**. §7 tells a session to run the plain form,
which prints one integer. And `manifest-revision` is itself excluded from `all`,
`iris/verifications.md` giving the reason: *a report, not a verdict*. So the chain
is **`all` → excludes the helper → `--verbose` → a note → a script nothing runs.**

### This is F4's class in a form none of its four members has

F1 through F4 are instruments wired to the wrong tool, guarding a deleted file, or
never armed. **This one is built correctly, reports correctly, and is simply never
invoked.** `iris/verifications.md` §7 opens by saying its subject is *"instruments
that report success because they cannot report anything else"*; F8 is an
instrument that reports the truth to nobody.

**Tonight is the measurement.** Across four commits — `eb8b6de`, `15069fe` and
the two before them — `MISSING` went **0 → 2** and `ORPHANED` **3 → 4**, while
every check a session actually runs held its baseline exactly: `counts` FAIL 0,
`headers` FAIL 11, `structure` FAIL 0, completeness 0. **The tree acquired three
new conformance failures and the assurance layer did not move**, because the one
instrument watching that surface was not asked.

### One trap found on the way, and it is why the first reading was wrong

**The manifest has two entry formats.** 257 entries are `**Revision N**` bold
headers and 202 are `## Revision N` headings. A scan reading only the first form
reports **Revision 33 as a gap**; it is not one, its entry is at line 17082 in the
older form. `check-manifest-revision.sh` reads both and says so in its header.
**So a person or a session hand-scanning the manifest gets a different answer from
the instrument**, in the direction of inventing a defect — which is what happened
here, and it is worth naming because the fix for it is *run the instrument*, which
is F8.

## F9 — it fires, and nothing says who repairs it or how

`verify-manifest-coverage.sh` says **write the entry**. It does not say **who**,
and the two outstanding cases have different answers: **285** was claimed by
`889b8ac`, which is `entity-model-and-vocabulary-20260909-053548`'s; **291** was
claimed by `15069fe`, a commit that carried this session's Revision 289 record and
another session's stranded Revision 290 entry under a third number. **The commit
that produced the gap is not owned by the session whose work is in it.**

**And §7 has no shape for a late entry.** It says entries are never retro-edited
and that a revert is a new entry naming what it reverted. A number claimed in the
log and never written is neither: nothing was reverted and nothing is being
retro-edited, because there is no entry to edit. **Revision 247 did this once**,
reconstructing six entries for Revisions 241 to 246 after the fact — the precedent
exists and the procedure does not, so the next session to face it re-derives what
that one worked out.

**Three questions have no home**: who owes the entry when the commit's author and
the work's author differ; whether a late entry is written at its own number or
declared as one; and whether it says, in itself, that it was written late. The
last matters most — **an entry that does not say it arrived after its commit is
indistinguishable from one that arrived with it**, which is the property
`APPLY-MANIFEST.md` exists to have.

**Not decided here.** The procedure is `.github/session-management-instructions.md`
§7's and belongs to `entity-model-and-vocabulary-20260909-053548`. F9 records the
gap and names the owner; it does not write the rule, for the reason F7 gives.

**And the repair itself is not this finding.** Two entries are owed and that is
`0038` F7's class — the tool says so in its own output. Recording F9 does not
discharge them, and `MISSING` stays at 2 until someone writes them.

### The precedent, measured, and the practice that now exists once

**`d1e5f96` is Revision 247** — *"six revision numbers taken in the log and none
written here"* — and it wrote entries for 241 through 246 in one commit. **All six
were checked here and every one is silent about being late.** They are today
indistinguishable from contemporaneous entries, which answers F9's third question
by demonstration rather than by argument: when nothing requires the statement,
nobody makes it, and the record loses the distinction permanently.

**Revision 293's entry for 285 is the counter-instance and it is one.** It opens
*"This entry was written late, at Revision 293, and Revision 285 contains no
work"* — the fact stated in the first sentence, where a reader cannot miss it.

**So the practice stands at one instance in seven, with no rule either way**, which
is the state `0039` F9 names: a rule with no home is quoted as though it were
enforced. And Revision 293's entry declines to install a machine-readable marker
for the reason that matters here — *"adding the marker alone would install exactly
what `0050` F8 records"* — so the prose statement is a deliberate choice against a
worse alternative, not a shortcut. **F9 owns whether it becomes procedure**, and
that is `.github/session-management-instructions.md` §7's to write.

## F10 — clearing a `MISSING` can only be done by creating a permanent `ORPHANED`

**Recorded 2026-09-10**, from `entity-model-and-vocabulary-20260909-053548` and
`drift-and-the-write-boundary-20260909-053548` independently reaching it, and
measured here against `bin/verify-manifest-coverage.sh` itself.

**The test is structural and has no notion of why.** The script's own header,
line 20: *"`ORPHANED` — the entry for N exists, and was introduced by a commit
OTHER than the one claiming N."*

**So repair is the only exit from `MISSING`, and it is a one-way conversion into a
row the tool says can never be cleared.** Writing a late entry necessarily
introduces it from a commit other than the claimant — that is what *late* means —
so the condition moves rather than clearing. The script states the second half in
its own output: *"`ORPHANED` and `DUPLICATE` cannot be cleared."*

**Measured across Revisions 292 and 293:**

| | R292 | R293 |
|---|---:|---:|
| `MISSING` | 2 | **1** |
| `ORPHANED` | 4 | **5** |

`MISSING Revision 285` became `ORPHANED Revision 285 — entry introduced by
c9f586b`. **Nothing went wrong. Somebody did the prescribed thing and both numbers
moved the way a regression moves.**

### One label, two histories, and the baseline already mixes them

At five, `ORPHANED` holds:

| Revision | How it arrived |
|---:|---|
| 241, 246 | **repair** — `d1e5f96`, Revision 247, six late entries in one commit |
| 285 | **repair** — `c9f586b`, Revision 293 |
| 271, 290 | **split** — the entry was never missing and rode out in a later, differently-numbered commit |

**The published baseline is `ORPHANED 3` and two of those three are repairs.** So
the number a session compares against has never meant one thing, and the
comparison it invites — *five against three* — is between two quantities that are
not the same quantity.

### Why this is not F8, and why it is worse than ambiguity

F8 is about **invocation**: a correct instrument nobody runs. F10 is about what the
output **means** once it is run. They compound — the instrument nobody runs also
cannot be gated on, and F10 is the reason it cannot: *"a row nobody can clear is
not a signal"* is §6's rule, and `ORPHANED` honours it by warning rather than
failing.

**The failure is one turn further out.** A metric that rises when the prescribed
repair is performed does not merely fail to inform — **it argues against the
repair**, to the one reader positioned to make it. `0038` F4's asymmetry is the
same shape from the other side: declining a patch is free before the apply and
expensive after, and the procedure was built around that asymmetry once it was
named. This one has not been named until now.

### Not decided, and the obvious fix is F8's defect

Splitting the label — `REPAIRED` beside `ORPHANED`, or a marker on a late entry —
is derivable, since the entry that repairs a `MISSING` is written by a known commit
at a known revision. **But a marker with no reader is a correct thing nothing
runs**, which is F8, and Revision 293's entry for 285 says exactly that in
rejecting the same idea: *"adding the marker alone would install exactly what
`0050` F8 records."* **F10 is recorded and left open** because its remedy sits
behind F8's, and F8's sits behind F9's.
