# Projection conformance

**What this is.** Every sweep of the surface `docs/architecture/state-as-data.md`
§6.1 maps — the tables that display a value the data owns — measured against the
data. Each entry is a dated measurement against a named commit.

**Why it exists.** §6.1 lists eleven classes of output and where each column comes
from. **Nothing generates any of them**, and `0043` D3 ruled at Revision 303 that
this is by design: §6.1 is *"a map, not a plan … not a commitment to build a
generator"*, and §7 declined generation on the ground that *"a bug rewrites forty
files at once, silently, which nothing catches."* **A detectable failure beats an
undetectable one** — which makes the detection worth measuring, and this is where
the measurements are kept.

**Two questions, and only the second is interesting.** *How many rows disagree*
answers how well hand maintenance is going. **Where they sit** answers whether the
instruments are looking in the right places, and that is the one the number cannot
be read off.

**Never a verdict, always a value.** A verdict cannot be compared against a later
run.

**Who runs it.** Any session, in its own copy. Nothing here touches the checkout.

---

## 2026-09-10 — commit `a91b451`, Revision 303

**Method.** Each class parsed from the markdown and compared against the field it
projects in `metadata.json`. **Derived values were not recomputed** —
`plan-findings-work.sh stamp --dry-run` writes 0 records, so the stored data is
current and is the right thing to compare a display against. **Measured in a copy
of the owner's checkout in a Linux VM under Bash 5.1.16, not the macOS Bash 3.2
target** — and see the tree-provenance caveat in `iris-conformance.md`, though no
figure here depends on path resolution.

| §6.1 class | Checked by | Rows | Disagree |
|---|---|---:|---:|
| `<tree>/INDEX.md` Standing | `structure` | 56 | **0** |
| `decisions.md` Outcome | nothing | 163 | **0** |
| `resolutions.md` rows | `completeness`, count only | 110 | **0** |
| `<session>/metadata.md` Owners | nothing | 12 | **0** |
| **`<session>/findings-manifest.md` Standing** | **nothing** | 37 | **2** |
| **`docs/sessions/INDEX.md` State** | **nothing** | 12 | **1** |
| **`findings.md` member status** | **nothing** | 222 | **2** |
| | | **612** | **5** |

### The five

| Row | Shows | Data | Why it stood |
|---|---|---|---|
| `drift-…/findings-manifest.md` `0038` | `answered` | `analyzing` | **unattended** — cleared by its session at Revision 305 |
| `drift-…/findings-manifest.md` `0047` | `analyzing` | `answered` | **unattended** — cleared at Revision 305 |
| `docs/sessions/INDEX.md` `run-index-design-20260901-000000` | `active` | `handoff` | **unattended** — re-derived at Revision 307 |
| `0050/findings.md` F5 | `framing` | `resolved` | **unattended** — repaired at Revision 304 |
| `0049/findings.md` F6 | `decided` | `resolved` | **UNCLEARABLE** — see below |

### Unclearable and unattended are different, and this ledger conflated them

**Corrected at Revision 307, at `drift-and-the-write-boundary-20260909-053548`'s
prompting.** The first version of this table grouped five rows under *repaired by
nobody*, which read as one condition and is two.

**`0049` F6 is UNCLEARABLE.** It sits in an `unclaimed` bundle; moving a member is
the owner's act and there is no owner. That is `0047` F1 and F2's exact shape, and
**it will still be here when every rule in the framework is working correctly** —
the rules are what make it unclearable.

**The other four were merely UNATTENDED**, and all four are now cleared. Nothing
structural held them; nobody had looked.

**The distinction is the one `0047` F9 exists for.** A row that cannot be cleared
and a row that nobody has cleared read identically in a count, and listing them
together is how a number stops being a signal. **This ledger was built to make that
visible and its own first table hid it.**

### The reading that kept the INDEX row standing, and why it was wrong

**This session wrote that the `run-index-design` row *"belongs to a session that
stands `handoff` with no successor, so nobody is positioned to fix it"*, and flagged
it four times on that basis.** Drift put the evidence against it rather than acting
around it, and the evidence holds.

**`docs/sessions/INDEX.md` is not a one-file-one-owner document.** Measured:
**12 of the last 15 revisions touched it**, by all three live sessions.

**And §6.1 declares that column a *derived state*, one row per session file.** It
is not an authored claim about the session it names; it is a projection of data
that is present, current and unambiguous — `metadata.json` reads `handoff`,
`declaredState` reads `handoff`, and `stamp --dry-run` writes nothing.

**So the absent session was never the blocker.** A session standing `handoff` with
no successor cannot **decide** anything, which is why `0049` F6 genuinely is closed
to everyone. **But nothing here needed deciding** — the cell needed re-deriving
from a source two directories away, which is the same act as recomputing a findings
total, which every session performs in that same file without it being anyone's
property.

> **A projection belongs to its source, not to its subject.** Reading it the other
> way is what orphaned this row for four sweeps.

### Why it was not held as a test case

**It was the last disagreeing row, and `0041` D7's checker has not been built**, so
clearing it costs that build its live failing case — §6 requires a guard be shown
*to fire on a case it should catch*, and the case will now have to be synthetic.
**That is the ordinary way**: Revisions 282 and 288 both did Direction B with
constructed input.

**Holding a true defect in the record so an instrument has something to catch is
using the tree as a test fixture, and the tree is evidence.** `0041` D6 is the
argument from experience: it predicted a silent first run because both known
instances had been repaired, was built anyway, and **fired on a third instance
nobody had counted.** The population is never what you think, and building for the
known instance is the wrong reason to keep one.

**It is also `0041` F10 one turn out** — there, a metric moved the wrong way when
someone did the prescribed thing; here, the instrument's convenience would have
decided whether the tree got repaired. **Same inversion, and the answer is the
same: repair the tree and let the instrument prove itself on constructed input.**

### What the distribution says

**Not one of the 329 rows in a class something checks disagrees.** All five sit in
the three classes nothing compares. The surface is not decaying evenly and being
caught in places — it is **intact wherever an instrument looks and drifting
wherever none does.**

**`verify-findings-structure.sh` is correct and its 70/0 is honest.** It compares a
bundle's derived standing against the `INDEX.md` above it and stops there, which is
what its header says it does. A session manifest displays the same value from the
same derivation and is compared to nothing.

### The sweep's own history, recorded because it bears on the number

| Run | Raised | Real | The sweep's own error |
|---:|---:|---:|---|
| 1 | 18 | 5 | a status cell read as a bare word, where §9 step 5 **requires** `superseded` to be a link — seven conformant rows read as broken |
| 2 | 13 | 5 | a header-index lookup against a header that table does not carry — eight sessions reported as having no state |
| 3 | 6 | 5 | a date-shaped row matched in an Assignment table rather than the Owners section |
| 4 | **5** | **5** | — |

**Every error ran in the direction of making the tree look worse than it is**, and
every one was caught by reading the rows rather than the total. **Eighth instrument
in this repository to fail loudly on first contact and the third caught before
shipping.** The legal link-shaped status cell is `0041` D1's matcher problem
arriving a fourth time, in the sweep that measures the surface D1 is about.

### What this ledger does not answer

**Whether five is a lot.** Five in 612 after weeks of hand maintenance is a low
rate and three of the five were introduced within two days. **The claim is about
where they are.**

**Whether the two remaining unchecked classes should be checked.** `0041` D7 takes
the two cheapest — a session manifest's `Standing` and a session's `State`. The
third, per-member status inside `findings.md`, is deliberately not `structure`'s
subject and is a separate decision against a separate script.

**Whether a row that disagrees means the record is wrong.** It does not. In all
five the data is authoritative and current — `stamp --dry-run` writes nothing — so
**the display is what drifted**, and every row here is clearable by its owner.

---

## 2026-09-11 — commit to be taken, Revision 307

**Re-measured after the clearings.** Revision 305 cleared both session-manifest
rows; Revision 304 repaired `0050` F5; Revision 307 re-derives the
`docs/sessions/INDEX.md` State cell.

| §6.1 class | Checked by | Rows | Disagree |
|---|---|---:|---:|
| `<session>/findings-manifest.md` Standing | nothing | 37 | **0** — was 2 |
| `docs/sessions/INDEX.md` State | nothing | 12 | **0** — was 1 |
| `findings.md` member status | nothing | 223 | **1** — was 2 |
| the four classes already at zero | `structure`, `completeness`, nothing | 341 | **0** |
| | | **613** | **1** |

**One row left in the whole surface, and it is the unclearable one.** `0049` F6,
in an `unclaimed` bundle, which no session may move.

**That is a better result than it looks and a worse one.** Better: four of five
disagreements were cleared in three revisions once they were named, by the sessions
that owned them, which is the record working. **Worse: none of the four was found
by an instrument.** Two were found by the owner reading rows by eye, one by this
sweep, and one by a session rechecking its own manifest. **The surface is now clean
and still unwatched**, which is exactly the state it was in before any of this —
`0041` D7's checker is what changes that, and it is not built.

**Nothing here is a baseline to quote forward.** Re-run the sweep.

---

## 2026-09-11 — commit to be taken, Revision 308

**This entry is not a re-measurement.** Revision 307's figures stand and should be
re-run rather than quoted. What changed is **who is watching**, and two of this
ledger's own row counts, because this revision added a finding, a decision and a
resolution of its own.

### `0041` D7 is built

| §6.1 class | Checked by, before | Checked by, now | Rows |
|---|---|---|---:|
| `<tree>/INDEX.md` Standing | `structure` | `structure` | 56 |
| **`<session>/findings-manifest.md` Standing** | **nothing** | **`structure`** | **37** |
| **`docs/sessions/INDEX.md` State** | **nothing** | **`structure`** | **12** |
| `<session>/metadata.md` Owners | nothing | nothing | 12 |
| `findings.md` member status | nothing | nothing | — |

**`structure` compares 105 rows of §6.1 where it compared 56.** Its own total goes
71 → 120: the 49 new comparisons, all passing.

**Three of the four classes this ledger found drift in are now watched.** The
fourth — per-member status inside `findings.md` — is not `structure`'s subject and
is a separate decision against a separate script, per D7's Rejected section. It is
also the class holding the one row left standing.

### The first run is silent, and that is the weaker outcome

**0 raised.** Revision 307 cleared the last disagreement in both classes by hand
four revisions ago, so the check arrives after its own evidence. **A silent first
run is not evidence that a check works** — it is the same output a check that does
nothing produces.

**What was held to instead**: 49 comparisons passing on this tree (Direction A),
and 4 raised / 4 real / 0 false on constructed input (Direction B). D7's original
criterion, *3 / 3 / 0 on this tree*, expired when the rows it named were cleared.
The construction is recorded in D7.

### How to read these counts when the sweep is re-run

**The distinction Revision 307 drew is the one that makes the numbers mean
something, and it cuts in opposite directions.** Stated here because this ledger
grouped the two classes in its first table and the grouping is what made the
reading wrong.

| If the count that stays flat is | Then | Because |
|---|---|---|
| **UNCLEARABLE** | **the framework is working** | Nobody may move the row. `0049` F6 sits in an `unclaimed` bundle and moving a member to `resolved` is the owner's act, so a flat count is the rule holding, not a defect ageing |
| **UNATTENDED** | **the framework is failing** | Somebody may move the row and has not. A flat count means the display drifted, the drift is clearable, and nothing and no one reached it |

**The two numbers must be reported separately or neither is readable.** A single
total conflates a rule being obeyed with a rule going unenforced, and this ledger
made exactly that mistake for four revisions — which is `0047` F9's shape
appearing inside the ledger built to watch for it.

**The test applies to this entry too.** The unattended count in the two newly
watched classes is now **structurally** zero rather than **incidentally** zero:
before, a disagreement waited for a person; now it fails a check a session runs.
**That is the whole of what D7 bought**, and it bought nothing at all for the two
classes still compared to nothing.

### Row counts moved by this revision's own writing

`0050` gained F11 and D4, and F11 a resolution row. **A ledger that measures the
tree is part of the tree**, so the arithmetic in the entries above is not carried
forward here; re-run the sweep rather than adjusting it.
