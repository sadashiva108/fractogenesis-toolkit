# Decisions — the index and manifest tables have a shape nothing checks

**Bundle:** `0032-index-and-manifest-tables-have-a-shape-nothing-checks` · **Status:** `in progress`
**Decided:** 2026-09-04, session `session_01PcgHu9kz9Hm5RatLQuFR8H`, owner
present. Held at the owner's word until `0029`'s decisions landed, because
`0029` decision 3.1 names this bundle.

## D1 — One new validator, `bin/verify-findings-structure.sh`

Two properties, one script: **every data row carries its table's column count**,
and **every findings bundle carries exactly one `STATUS-` tag that matches its
index row**. Findings 1 and 4 are the same defect seen from two surfaces — a
structural invariant that §§4c–4d state and nothing tests.

**Rejected — extend `bin/verify-findings-counts.sh`.** The obvious move, and it
already opens every index, every manifest and every bundle directory. Rejected on
that script's own charter, stated in its header: *"a fact has one home, and a copy
is permitted only where it is generated or where a check fails on drift."* It
exists for **derived facts displayed twice**. A tag-versus-row disagreement is
exactly that and would fit; **a table's column count is not a copy of anything**.
Widening it to cover shape would make the clearest sentence in its own header
untrue, and that sentence is why the script is trusted.

**Rejected — two scripts, one per property.** Six validators to run and six
baselines to quote, for two checks that walk the same three surfaces and would
have to agree about what a table is.

**The cost is real and is accepted.** A fifth repo lint is a fifth line in every
manifest entry's validation block, and `0029` named that cost when it rejected a
lint of its own. **This is not that case.** `0029` rejected a check whose purpose
was to *license a duplicate that could be deleted instead* — its decision 3.1
removes the copies and needs no check. Here there is nothing to remove: the tables
must exist, their shape is load-bearing, and the only alternatives are a check or
a habit. A habit has now failed six times.

## D2 — `verify-doc-paths.sh` is not changed, and the reason is finding 2's point

Finding 2 says that lint gave false assurance on both malformed rows. It did, and
it was correct to: every link in them resolved. Existence and shape are different
properties and it only claims the first.

**Decided: no change to it.** The defect was never in that script; it was in
reading *"the lints are clean"* as a claim about well-formedness. D1's check makes
that reading true rather than making an existing check apologise for its scope.

**Rejected — widen `verify-doc-paths.sh` to cover table shape.** It is the lint
sessions run most, so the temptation is to put everything there. Its subject is
paths and anchors across all of `docs/`; findings-table shape applies to five
files. A validator that checks two unrelated properties reports one number for
both, which is how a session learns to read a total instead of a result.

## D3 — The bundle stays in `docs/instruction-set-findings/`, and the two tests disagree

Finding 3 asks whether a bundle whose fix is a lint belongs in the instruction-set
tree. It stays, on the owner's routing of 2026-09-03, and the disagreement is
recorded rather than resolved:

- **§4c's classification test** is *where the fix lands*. The fix is
  `bin/verify-findings-structure.sh` — shared machinery, which is
  `docs/cross-cutting-findings/`.
- **`0029`'s decision** — *a rule lives where its kind lives* — points the other
  way. The subject is a rule stated in §§4c–4d and unenforced; the lint is the
  enforcement of that rule, not a separate concern.

Both readings are defensible and they give different answers, which means §4c's
test is incomplete for a finding whose subject and fix live in different kinds.
**That is an instruction-set defect in its own right and is not opened here** —
`0029` is `in progress` and owns §§4b–4d, so it is theirs to take or leave.

**Rejected — move it to `docs/cross-cutting-findings/` on the strength of §4c's
test.** It would be a bundle rename, which `0030` establishes breaks every
citation already written against it, for a classification that is genuinely
arguable rather than wrong.

## D4 — Finding 4 cannot be fixed in this repository, and D1 catches its residue

The deletion defect is `git apply` meeting a mount that refuses `unlink`: git
downgrades the failure to a warning, applies everything else, and exits 0. Nothing
in the repository can change that behaviour — it is a property of the owner's
machine and of git, met four times.

**Decided, in two parts.**

**D1's tag check catches the residue.** Every one of the four instances left a
bundle carrying two `STATUS-` tags, and the check fails on exactly that. It is
detection after the fact, not prevention, and that is the honest limit.

**Prevention is procedural and is owed elsewhere.** *Verify a deletion actually
happened with `git diff --summary` after applying any patch that contains one* is
a rule about how a session applies work, which is where `0028`'s compose-in-a-copy
rule lives — `docs/legend.md` and §§4c–4d. Both are held by another session and
this bundle does not write them. **Recorded as owed, and named here so it is not
rediscovered a fifth time.**

**Rejected — a wrapper script that applies patches and checks deletions.** It
would be a fifth thing to remember to use, replacing a rule that is already
written down and simply was not followed.

---

## What this authorises

One toolkit write: `bin/verify-findings-structure.sh`. Every finding now carries a
decision, so `resolving` may begin. Nothing on the artifact volume, nothing in
`0029`, and no change to any existing validator.
