# Findings owned — `drift-and-the-write-boundary-20260909-053548`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than
restating the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Standing | Notes |
|---:|---|---|---|---:|---|---|
| 0038 | [`0038-sessions-write-into-the-tree-the-owner-commits-from`](../../session-management-findings/0038-sessions-write-into-the-tree-the-owner-commits-from/) | `session-management` | Sessions write into the tree the owner commits from | 9 | `answered` | **F1–F6 `resolved`, F7 `decided`** at Revision 270. Supersedes `0028`, which resolved all six at Revision 181, so this was a **re-verification**: two of the six hold as written, three name a home that is gone, one was never stated, and no remedy was lost. F7's guard is chosen and not built. `0049/F1 relates-to 0038/F1`, which is the assurance session's |
| 0047 | [`0047-the-tree-carries-drift-no-check-looks-for`](../../session-management-findings/0047-the-tree-carries-drift-no-check-looks-for/) | `session-management` | The tree carries status drift that no check looks for | 12 | `analyzing` | The drift inventory. **F7 and F8 are `resolved`** at Revision 268 — both were defects in `plan_findings_work.py`, and the transfer cleared on that write. F4 was resolved at Revision 255. **F5 is answered in the code and unrecorded**: the clone exemption is in `is_clone()` citing this finding, and the finding still reads `un-started`. F1, F2, F3 remain `un-started` |
| 0052 | [`0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check`](../../session-management-findings/0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check/) | `session-management` | A change that invalidates earlier work has neither a plan nor a check | 2 | `answered` | Assigned at Revision 261 at the owner's direction, having been recorded `unclaimed` at Revision 252. **F1 read at Revision 270** and the sweep run on one bundle: the failure mode is not only a resolution reverted but a resolution still true and no longer findable. `resolved` findings number 59, not the 36 the finding was written against. **F2 is `resolved` at Revision 277**: §6 gains the migration-plan gate — the conformance test, the five things a plan names, and one format change per revision |

**3 bundles · 23 findings**, 3 of them live — `0047` F1, F2 and F3, parked behind the entity model. **`0038` and `0052` are `answered`.**

**All three now read what their findings derive.** `0047` cleared its transfer at
Revision 268 and `0038` at Revision 270; `0052` read `assigned` until Revision
270, having been owned but unopened. **Nothing in this set stands `transferred`
any more.**

**`0038` and `0047` transferred in at Revision 261** from
`typed-bundles-architecture-20260908-204724`, which stands `handoff` — **not an
assignment.** Each stands `transferred` until this session's first write to it
**as owner**; a contribution is not an act of ownership and does not clear it.
**`0052` is an assignment**, not a transfer: it was `unclaimed`, and the manifest
row above is the act that gives it an owner.

**The split was made on the graph, not on load.** This set is the tree's own
state and the tree the owner commits from. The other half — `0037`, `0039`,
`0045`, `0048` — is the entity model, and it is
[`entity-model-and-vocabulary-20260909-053548`](../entity-model-and-vocabulary-20260909-053548/)'s.
**No edge crosses between the two sets that carries a dispatch constraint**, so
neither session waits on the other.

**The boundary is the three rule documents.** `docs/legend.md`,
`.github/session-management-instructions.md` and the conformant prompt belong to
the other session, whose `0039` D23 rewrites all three. Sections 0 and 6 of the
instruction set are where `0038`'s findings land and are writable here, announced
in review.
