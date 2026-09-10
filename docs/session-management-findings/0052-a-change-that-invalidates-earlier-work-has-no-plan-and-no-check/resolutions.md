# Resolutions — a change that invalidates earlier work has neither a plan nor a check

**Bundle:** `0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check`  
**Session:** `drift-and-the-write-boundary-20260909-053548`  
**Resolved:** 2026-09-10

## Resolutions

| Member | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F2 | D1 | `.github/session-management-instructions.md` §6 gains the migration-plan gate: the conformance test with its six-row table of what needs a plan and what does not, the five things a plan names, and the one-format-change-per-revision rule. Each clause names the revision that already did it | 277 | — |

**F1 is untouched by this revision and remains `framing`.** It was read at
Revision 270 and the sweep run on one bundle; what it still owes is the shape of
the instrument, and that is not what F2 decided.

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
