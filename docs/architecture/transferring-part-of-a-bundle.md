# Transferring part of a findings bundle

**Recorded:** 2026-09-06, `restore-apps-outstanding-20260903-000000`.
**Status:** options recorded, none chosen. **Not implemented.**
Bundle-level transfer *is* implemented — see
[`.github/session-management-instructions.md`](../../.github/session-management-instructions.md)
section 10. This record is about the finer case only.

---

## The need

A session sometimes needs one or two findings out of a bundle, not the bundle.
It has come up more than once: findings whose subject belongs to another
session's work sit inside a bundle whose remaining findings do not. Moving the
whole bundle drags work its new owner has no business holding; leaving them costs
the session that needs them.

Bundle-level transfer does not meet this. It is deliberately the only thing
implemented, because the finer case breaks four things and the options for
handling that are worth writing down before anyone reaches for it.

## What breaks

Ownership is a property of the **bundle** everywhere in this structure, and the
whole shape follows from that.

**1. The count changes unit.** A `findings-manifest.md` `Findings` column means
*the findings in this bundle*. Under partial ownership it must mean *the findings
in this bundle that I own*, or two manifests count the same findings twice. Same
header, different quantity — which is the defect
`docs/session-management-findings/0037-findings-architecture-conformance/`
finding 3 records, and the reason `bin/verify-findings-counts.sh` exists. It is
not a hypothetical: it is the exact shape of the bug that produced that checker.

**2. "The owning session" stops being a single answer.** Every permission rule
says *only the owning session* — for recording to a `decided` finding, for the
first read that moves a status, for `resolving`. Each becomes *the session owning
**that** finding*, in the legend, in section 4, and in section 9's prohibitions.

**3. No owner can derive the bundle's status alone.** The ladder reads every
finding. With ownership split, neither session sees the whole, and a bundle whose
remaining findings are all inert while transferred ones are live has no row that
fits.

**4. A session's state stops following from its bundles.** `closed` currently
means every bundle it owns is `resolved`. A session holding three resolved
findings in a bundle whose other findings moved away is finished, and the rule
cannot say so.

## The options

### A — split the bundle

The transferred findings become a **new bundle**, owned by the target session,
with `Relates to` in both directions.

Ownership stays per-bundle. No count changes unit. The ladder stays computable.
No permission rule needs qualifying. Nothing in the structure moves.

**Costs.** Findings renumber inside the new bundle, so a citation to `F3` of
`0012` no longer resolves — and since the header schema made finding numbers
`F1`, `F2` and decisions cite them directly (*"Findings: F1, F3"*), a split
breaks those citations inside `decisions.md` as well as outside it. Findings that bear on each other end up in two
places, which is the thing bundles exist to prevent — and `resolving` waits for
every finding in a bundle precisely because a decision taken against one may not
hold against another. Splitting severs that, and `Relates to` obliges nobody.

### B — partial ownership, with the unit renamed

A bundle appears in **both** manifests. A `Finding Ownership` table in
`findings.md` becomes the source of truth for who owns which findings:

    ## Finding Ownership

    | Session | Date | Findings |
    |---|---|---|
    | `<session>` | <date> | F1, F2, F5  — or `all` |

It would sit in the header block of `findings.md`, between `Contributions` and
`Findings`, and it is the only table the schema in section 11 leaves unbuilt —
deliberately, because it exists only if this option is taken.

The `Findings` column in `findings-manifest.md` and `docs/sessions/INDEX.md`
becomes **`Findings owned`**, and `verify-findings-counts.sh` checks it against
that table. Where a bundle has more than one owner its index Session cell reads
`multiple*`, with a footnote pointing at the bundle's own table.

**Session state derives from findings owned, not from bundles** — `active` while
it owns a finding that is not `resolved` or `withdrawn`, `closed` when none is.
Two sessions sharing a bundle then close independently, in either order. That is
the same inversion already made one level down, and it removes problem 4
entirely.

**Costs.** Problems 1 and 3 are managed rather than removed: the count is honest
only because it was renamed, and the bundle's derived status needs a rule for
the split case that does not exist yet. Problem 2 is real work — every
permission rule needs qualifying.

### C — do not support it

A bundle moves whole or not at all. What is implemented today.

**Costs.** The need stays unmet, and the pressure reappears every time it comes
up. The observed workaround is to move the whole bundle and accept that its new
owner holds findings it does not want, which is how a manifest stops describing
what a session is actually working on.

## What the schema already assumes

The header schema adopted in Revision 201 numbers findings `F1`, `F2` and has
`decisions.md` cite them — `| D1 | … | F1, F2 | … |`. **That numbering is what
makes either option workable**: option A can rewrite the citations because they
are mechanical, and option B can name owned findings precisely rather than by
position. Neither would have been tractable against bare digits and prose.

It also fixes what option B costs: one column rename, in two files, plus a
checker rule. That is smaller than it looked before the schema existed.

## Where it stands

**B is the design the owner described**, and its session-state rule is a genuine
improvement that would be worth taking even on its own. **A is the smaller
change** and preserves every invariant, at the price of separating findings that
were read together.

The question that decides it: **is a bundle a unit of ownership, or a unit of
reading?** It is currently both, and partial transfer is the first case where
those two come apart. Answer that and the option follows.

Nothing is decided here. When it is, this record becomes a findings bundle under
`docs/session-management-findings/` and the decision is recorded there.
