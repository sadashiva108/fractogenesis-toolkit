# Decisions — superseding a bundle whose session is gone

**Bundle:** `0040-superseding-a-bundle-whose-session-is-gone`  
**Session:** `assurance-coverage-20260908-204724`  
**Decided:** 2026-09-09

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | All four findings are overtaken. Revision 200 restored the supersession procedure as section 9, and it answers each of them in the finding's own terms | F1, F2, F3, F4 | 2026-09-09 | `accepted` |
| D2 | What is left is enforcement, not procedure: section 9's step 5 and both provenance gates are stated and unchecked. Specified here, built elsewhere | F1, F4 | 2026-09-09 | `accepted` |

---

## D1 — section 9 answers all four

`.github/session-management-instructions.md` section 9, installed at Revision
200, commit `4626eb4` — *"the supersession procedure lost in Revision 198 is
restored"*.

| Finding | Where it now lives |
|---|---|
| F1 — the term is an instruction and is defined nowhere | Section 9 in full: nine numbered steps, three prohibitions and the provenance gates |
| F2 — both accounts assume the superseding party owns it | *"An earlier rule tied it to a bundle being overtaken mid-work, which left the commonest case unhandled: a settled bundle whose owning session has ended, with nobody able to perform the supersession at all"* — and *"The session with the new reading does it, and does not take ownership. Superseding is not inheriting."* |
| F3 — the three prohibitions are unwritten | *"Three things it must NOT do"*: the superseded `findings.md` is not edited, the number is never reused and the directory never renamed, the bundle does not move between manifests |
| F4 — the index form exists in the tree and nowhere in a document | Step 5: *"THE STATUS CELL BECOMES THE LINK … always a link, never the bare word"* |

**F2 is the one worth stating plainly.** It asked *"does superseding transfer
ownership?"*, said it must not, and recorded that nothing said so. Section 9 now
says so in one sentence, and answers the ownerless case in the same paragraph
that F2 identified as the gap.

**The `Scope:` line in `findings.md` is stale and is not edited.** It names
*"one subsection in `.github/copilot-instructions.md` §4c"*; Revision 191 split
that file and the content landed in section 9 of the session-management set. A
`findings.md` is the reading as it was taken, and the resolution row is where the
correction belongs.

## D2 — the procedure is written and nothing checks it

This is `0041` F1's shape — *a required shape, unenforced* — applied to section 9,
and it is what the `relates-to` edge from F1 to `0046` F1 is actually about:
**both halves of what supersession does not finish are enforcement, not
procedure.**

Two rules are stated and unchecked:

- **Step 5** — a superseded bundle's index Status cell is a link to its
  replacement, never the bare word. Nothing asserts it.
- **Coverage and exclusivity** — every predecessor finding carries at least one
  disposition edge, and a `dropped` finding carries no other. `docs/legend.md`
  calls these a **gate** on the tag. Nothing enforces the gate;
  `plan_findings_work.py` reads `lineage.supersededBy` to derive standing and
  never asks whether the accounting behind it is complete.

### The check, and the false positive it produces

A `SUPERSESSION-INCOMPLETE` row in `plan-findings-work.sh check`: for a bundle
carrying `lineage.supersedes`, every finding of the predecessor must be the `to`
of at least one edge, and a `dropped` finding must carry no other edge.

**Its first run fails this bundle.** `0040`'s four `carried` edges to `0031` have
`"basis": "derived"` — back-filled by `extract-metadata.py`, not asserted by
anyone — and `0041`'s four to `0032` are the same. A coverage rule written to
require *asserted* edges reports two complete supersessions as incomplete on the
first tree it meets, which would be the seventh instrument in a row to do that.

**So: derived edges count as covering, and the check is run over all seven
existing supersessions before it is turned on.** Not run here — building it is a
toolkit write, and the bundle type for work whose output is a built thing is
`docs/architecture/typed-bundles-and-work.md`, which belongs to
`typed-bundles-architecture-20260908-204724`.

**Revision 249 names why this one is harder than it looks.**
`docs/rules/rule-enforcement-avenues.md` §7 argues that the interesting rules are
properties of a **relationship** rather than of a file, so they are graph queries
and not path tests — and that *"every rule in this section is currently
unenforceable for want of data rather than for want of a guard."* Coverage and
exclusivity are exactly that shape: they ask whether every predecessor finding is
the target of some edge, which no path match can answer.

**That reframes this decision's false positive as the same problem rather than a
separate one.** `0040`'s four edges to `0031` carry `basis: "derived"` because
nobody asserted them; the check fails on them for want of data, which is §7's
sentence arriving as an instance. So the order is: the edges are asserted first,
and the gate is built after — not the reverse.

**Not claimed: that this is the whole of section 9's unchecked surface.** Steps
1, 2, 3, 6, 7 and 8 were not audited for enforceability. Saying which were looked
at is the point of saying it at all.
