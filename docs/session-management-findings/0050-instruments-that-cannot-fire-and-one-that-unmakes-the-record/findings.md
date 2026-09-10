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
| F3 | Running `extract-metadata.py` on a healthy tree destroys every asserted edge and every stamped value | `framing` |
| F4 | Four instruments in three days were correct and could not do their job, and no bundle covers that class | `framing` |
| F5 | The coverage sweep keeps a second copy of a directory list `docs/INDEX.md` owns, and 43 files are invisible to it | `framing` |
| F6 | `0050` F3 counted two field families of twenty: one run destroys 429 recorded values, and section 10a routes a session into running it | `framing` |
| F7 | Nothing compares a commit message's assertion against what the commit contains, and a mis-scoped message burns a revision number | `framing` |

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
