# Findings owned — `typed-bundles-architecture-20260908-204724`

**This session owns nothing. The table is empty on purpose**, at Revision 261,
and the file is kept because it is the record of what was owned and where it
went. Ownership is derived by scanning `findings-manifest.md` across
`docs/sessions/` — **the row is the assignment and removing it is the release**,
so an empty table is a statement and not an omission.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Standing | Notes |
|---:|---|---|---|---:|---|---|

## Transferred out — Revision 261

Six bundles, 41 findings, to two successors opened in the same revision. **All
six read `transferred` and clear on the receiving session's first write to them
as owner** — a contribution is not an act of ownership.

| Bundle | Subject | Items | To |
|---|---|---:|---|
| [`0037`](../../session-management-findings/0037-findings-architecture-conformance/) | The findings-and-sessions architecture disagrees with itself and with the tree | 7 | [`entity-model-and-vocabulary-20260909-053548`](../entity-model-and-vocabulary-20260909-053548/) |
| [`0039`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | The instruction set lags the rules it governs | 23 | `entity-model-and-vocabulary-20260909-053548` |
| [`0045`](../../session-management-findings/0045-a-session-whose-output-is-not-a-bundle-has-no-state/) | A session whose output is not a findings bundle has no state that fits | 3 | `entity-model-and-vocabulary-20260909-053548` |
| [`0048`](../../session-management-findings/0048-the-session-capacity-limit-has-no-datum/) | The session capacity limit has no datum, and its only proxy points the wrong way | 3 | `entity-model-and-vocabulary-20260909-053548` |
| [`0038`](../../session-management-findings/0038-sessions-write-into-the-tree-the-owner-commits-from/) | Sessions write into the tree the owner commits from | 7 | [`drift-and-the-write-boundary-20260909-053548`](../drift-and-the-write-boundary-20260909-053548/) |
| [`0047`](../../session-management-findings/0047-the-tree-carries-drift-no-check-looks-for/) | The tree carries status drift that no check looks for | 8 | `drift-and-the-write-boundary-20260909-053548` |

**`0037` is the one that leaves finished and is not done.** Seven of seven
`resolved` and the bundle stood `answered`; the reading it is still owed — that a
finding may record **a fact established**, not only a defect — is why it moved
with the entity model rather than staying here to be closed.

**Nothing was released to `unclaimed`.** §10a permits it and the last handoff
used it deliberately; here both successors exist and every bundle has a named
owner from the moment this revision is committed, which is the condition
`docs/sessions/INDEX.md` states — a session may not end leaving a bundle owned by
a session that has stopped.

## Recorded here, never owned

| Bundle | Subject | Disposal |
|---|---|---|
| [`0052`](../../session-management-findings/0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check/) | A change that invalidates earlier work has neither a plan nor a check | **Assigned** to `drift-and-the-write-boundary-20260909-053548` at Revision 261, at the owner's direction. It stood `unclaimed` from Revision 252 |

## What was owned, and what was done with it

Assigned `0037`, `0038`, `0045`, `0047`, `0048` on 2026-09-09 from the Revision
234 allocation; `0039` transferred in at Revision 248 and cleared at Revision 257.
**Created at Revision 237** by `allocation-and-inquiry-design-20260906-233205`; **wrote Revisions 239, 240, 248, 249, 250, 252, 256, 257, 259, 261, 262 and 263** — twelve revisions across eleven commits, 248 and 249 sharing `8a1b5eb`. **Corrected at Revision 266**: the list written at 261 claimed 247 and 253, which belong to `allocation-and-inquiry-design-20260906-233205` and `assurance-coverage-20260908-204724`, and omitted 249, 250, 262 and 263. `ended.commits` now carries the hashes, each of which names this session in its `Claude-Session` trailer. `0037` reached
`answered` at Revision 256 — the first bundle this session closed, and the first
toolkit write in this campaign gated by a `decided` finding rather than an owner
override.

The handoff record is [`handoff-20260909-053548.md`](handoff-20260909-053548.md).
