# Resolutions — a change that invalidates earlier work has neither a plan nor a check

**Bundle:** `0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check`  
**Session:** `drift-and-the-write-boundary-20260909-053548`  
**Resolved:** 2026-09-10

## Resolutions

| Member | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F1 | D2 | `bin/verify-doc-paths.sh` moves its historical branch below the resolution fallbacks and renames the count `DECAYED`, so it means *cited by a record and no longer there*. Round trip over 271 documents: OK 2271 → 2305, HISTORICAL 70 → DECAYED 36, PROPOSED and MISSING identical. **36 decayed citations, six relocations accounting for nearly all** | 284 | — |
| F2 | D1 | `.github/session-management-instructions.md` §6 gains the migration-plan gate: the conformance test with its six-row table of what needs a plan and what does not, the five things a plan names, and the one-format-change-per-revision rule. Each clause names the revision that already did it | 277 | — |
| F3 | D3 | `bin/verify-manifest-coverage.sh` reads every `APPLY-MANIFEST*.md` rather than the current file, and the `git log` pathspec matches the set. Verified both directions: MISSING 0 against the tree, identical to the pre-rollover figures, and MISSING 1 with one archived entry removed | 311 | — |

**Both members are `resolved` and the bundle derives `answered`.** F2 at
Revision 277, F1 here.

**F1 is resolved on the shape of the instrument, which is what it owed** — not on
the number it said it wanted. It asks how many resolutions are false; that is a
reading and stays one. What it gets is the mechanical half, exactly: **36
citations that point at nothing**, and the reading half declared irreducible in
D2 rather than implied covered.

**What this resolution does not do.** It writes a rule and builds nothing. The
check that would hold the rule is rejected in D1 as premature — it would have to
recognise a format change before the change is made, which is the judgement the
rule exists to make — and it is owed alongside `0038` F7's four guards, under
`0047` F6's discipline of warn-only until a clean pass.

**Six things were waiting on this and none of them is done here.** The
`APPLY-MANIFEST.md` split, one file per revision, the `bundle` genus rename, the
directory flattening, the manifest's two entry formats, and any further
vocabulary change. **What changes is that each of them now has a form to arrive
in**, and the first to use it will be the first test of whether the five things
are the right five.
