# Findings owned — `typed-bundles-architecture-20260909-004724`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than
restating the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Standing | Notes |
|---:|---|---|---|---:|---|---|
| 0037 | [`0037-findings-architecture-conformance`](../../session-management-findings/0037-findings-architecture-conformance/) | `session-management` | The findings-and-sessions architecture disagrees with itself and with the tree | 7 | `analyzing` | The bundle the others are read against. `0037/F1 blocks 0047/F4` and `constrains 0045/F1` |
| 0038 | [`0038-sessions-write-into-the-tree-the-owner-commits-from`](../../session-management-findings/0038-sessions-write-into-the-tree-the-owner-commits-from/) | `session-management` | Sessions write into the tree the owner commits from | 6 | `analyzing` | Sessions write into the tree the owner commits from. `0049/F1 relates-to 0038/F1`, which is Session B's |
| 0045 | [`0045-a-session-whose-output-is-not-a-bundle-has-no-state`](../../session-management-findings/0045-a-session-whose-output-is-not-a-bundle-has-no-state/) | `session-management` | A session whose output is not a findings bundle has no state that fits | 2 | `assigned` | A session whose output is not a bundle has no state that fits. This session bundle is a live instance of F1 on the day it was created |
| 0047 | [`0047-the-tree-carries-drift-no-check-looks-for`](../../session-management-findings/0047-the-tree-carries-drift-no-check-looks-for/) | `session-management` | The tree carries status drift that no check looks for | 5 | `assigned` | The drift inventory. F4 is blocked on `0037/F1`; F5 is the sweep's own false positives |
| 0048 | [`0048-the-session-capacity-limit-has-no-datum`](../../session-management-findings/0048-the-session-capacity-limit-has-no-datum/) | `session-management` | The session capacity limit has no datum, and its only proxy points the wrong way | 3 | `assigned` | Capacity has no datum. F1 blocks F3: what to capture cannot be settled before it is agreed nothing is captured |

**Assigned 2026-09-09 by the owner**, from the allocation run recorded in
`docs/ledgers/allocation-evidence.md`. All 5 were `unclaimed` and are owned
here from today. **They do not all read `assigned`**: `assigned` means every finding
is `un-started`, and in `0037`, `0038`, `0040` and `0041` the findings are
`framing` — recorded, not yet worked — which derives to `analyzing`. Nothing in
this set has been worked by anyone.

The split was made on the graph, not on load: this set is what the blueprint in `docs/architecture/typed-bundles-and-work.md` is built on. Four of the five edges inside it are `blocks` or `constrains`, which is why the reading order is not free.
