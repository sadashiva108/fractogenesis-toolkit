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

| Row | Shows | Data | Whose |
|---|---|---|---|
| `drift-…/findings-manifest.md` `0038` | `answered` | `analyzing` | Drift's, reported by them |
| `drift-…/findings-manifest.md` `0047` | `analyzing` | `answered` | Drift's, reported by them |
| `docs/sessions/INDEX.md` `run-index-design-20260901-000000` | `active` | `handoff` | nobody's attention |
| `0050/findings.md` F5 | `framing` | `resolved` | this session's — **repaired** |
| `0049/findings.md` F6 | `decided` | `resolved` | `unclaimed`, closed to everyone |

**Three of the five are repaired by nobody at this revision.** Drift's two are
theirs; `0049` is `unclaimed` and an unclaimed bundle is closed to every session;
the `run-index-design` row belongs to a session that stands `handoff` with no
successor. **Each is flagged rather than edited**, which is §6's *one file, one
owner*.

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
