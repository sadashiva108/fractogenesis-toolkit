# Findings owned — `drift-and-the-write-boundary-20260909-053548`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than
restating the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Standing | Notes |
|---:|---|---|---|---:|---|---|
| 0038 | [`0038-sessions-write-into-the-tree-the-owner-commits-from`](../../session-management-findings/0038-sessions-write-into-the-tree-the-owner-commits-from/) | `session-management` | Sessions write into the tree the owner commits from | 7 | `transferred` | All seven `framing`. F1–F5 are the shared-tree consequences, F6 the write-kind distinction the discipline does not make, F7 the guardability test behind `docs/rules/rule-enforcement-avenues.md`. `0049/F1 relates-to 0038/F1`, which is the assurance session's |
| 0047 | [`0047-the-tree-carries-drift-no-check-looks-for`](../../session-management-findings/0047-the-tree-carries-drift-no-check-looks-for/) | `session-management` | The tree carries status drift that no check looks for | 8 | `transferred` | The drift inventory. F4 is `resolved` — its blocking edge from `0037/F1` is discharged. **F5, F7 and F8 are defects in the instruments themselves**, and F5 must be fixed before any number this bundle quotes can be read |
| 0052 | [`0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check`](../../session-management-findings/0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check/) | `session-management` | A change that invalidates earlier work has neither a plan nor a check | 2 | `assigned` | **Assigned at Revision 261 at the owner's direction**, having been recorded `unclaimed` by `typed-bundles-architecture-20260908-204724` at Revision 252. F1 is the reading behind `0037`'s regression: `1c48deb` reverted seven resolved findings and nothing noticed |

**3 bundles · 17 findings**, 16 of them live.

**`0038` and `0047` read `transferred` above, which is an ownership statement
covering the progress underneath it** — both derive `analyzing`. Each becomes its
own progress the moment this session writes to it as owner. `0052` reads
`assigned` because it was never anyone's.

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
