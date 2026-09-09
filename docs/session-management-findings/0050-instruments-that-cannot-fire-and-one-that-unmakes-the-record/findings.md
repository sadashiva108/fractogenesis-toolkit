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
| F1 | The write-location guard does not cover the tool a bridged session actually writes through, and reads the wrong root | `un-started` |
| F2 | A schema exemption guards on a marker file Revision 222 deleted, so the exemption can never apply | `un-started` |
| F3 | Running `extract-metadata.py` on a healthy tree destroys every asserted edge and every stamped value | `un-started` |
| F4 | Four instruments in three days were correct and could not do their job, and no bundle covers that class | `un-started` |

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
