# Findings owned — `drift-and-the-write-boundary-20260909-053548`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than
restating the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Standing | Notes |
|---:|---|---|---|---:|---|---|
| 0038 | [`0038-sessions-write-into-the-tree-the-owner-commits-from`](../../session-management-findings/0038-sessions-write-into-the-tree-the-owner-commits-from/) | `session-management` | Sessions write into the tree the owner commits from | 12 | `answered` | The write boundary, and every member is `resolved`. **F1–F6** across Revisions 181 to 270, this bundle superseding `0028` and re-verifying it. **F7, F8 and F9 at 283** against `rule-enforcement-avenues.md`, whose test 3.0 asks whether an instrument can observe the act at all. **F10 and F11 at 300**: §0 step 1 kept no record of what the checkout held when copied, and step 3's recipe dropped a deletion. **F12 at Revision 311** — its remedy was `0012` D2, accepted 2026-09-04 and carried out by the owner at Revision 310; the checkout and a clone now both read `MISSING: 24` where they read 10 against 20. D11 adopts that decision rather than citing it, because a resolution naming another bundle's decision is a citation dressed as ownership |
| 0047 | [`0047-the-tree-carries-drift-no-check-looks-for`](../../session-management-findings/0047-the-tree-carries-drift-no-check-looks-for/) | `session-management` | The tree carries status drift that no check looks for | 13 | `answered` | The drift inventory, and every member is `resolved`. **F7 and F8 at Revision 268** — both defects in `plan_findings_work.py`, and the transfer cleared on that write. **F11 at 272, F4 at 255, F5 at 231** — F5 against a remedy that had shipped in `is_clone()` with nothing recording it. **F6 at 280**, the warn-only rule for anything that refuses a write. **F9 and F10 at 281**, the counted ordering exemptions. **F12 at 278**, the third place a revision number can be taken. **F1 and F2 at 295**: Revision 287 dissolved F1's premise rather than repairing it, so `CLOSED-BUNDLE-LIVE-FINDING` was removed, and F2 had found the rules working and called it drift. **F3 at 298 and F13 at 300** — F3's question answered without an instrument change, and F13 recording why: closing a bundle has no single act, so `0035` is finished where people read it and live where the instrument reads it. **Its three rows keep firing**, being a true positive with a live owner. |
| 0052 | [`0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check`](../../session-management-findings/0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check/) | `session-management` | A change that invalidates earlier work has neither a plan nor a check | 3 | `answered` | Assigned at Revision 261 at the owner's direction, having been recorded `unclaimed` at 252. **F2 at 277**: §6 gains the migration-plan gate. **F1 at 284** — nothing re-verified that a resolution still held, and the instrument it needed already existed. **F3 recorded and resolved at Revision 311**: Revision 310 rolled `APPLY-MANIFEST.md` over at 1.25 MB, and `verify-manifest-coverage.sh` read one half of a split subject — MISSING 0 to 79. It now reads every `APPLY-MANIFEST*.md`. **A rollover makes no record non-conformant, so §6's gate does not fire; what breaks is a reader, and nothing asks who reads this path** |

**3 bundles · 28 findings**, none live. All three bundles are `answered` and the session derives to `closed`. **`0038` and `0052` are `answered`**; F1 and F2 were resolved at Revision 295 once Revision 287 supplied the ruling they were parked behind.

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
