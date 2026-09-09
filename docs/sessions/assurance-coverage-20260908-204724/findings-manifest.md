# Findings owned — `assurance-coverage-20260908-204724`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than
restating the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Standing | Notes |
|---:|---|---|---|---:|---|---|
| 0040 | [`0040-superseding-a-bundle-whose-session-is-gone`](../../session-management-findings/0040-superseding-a-bundle-whose-session-is-gone/) | `session-management` | Superseding a bundle whose session is gone is instructed but never defined | 4 | `answered` | All four resolved 2026-09-09 against Revision 200. What is left is enforcement, not procedure — D2 |
| 0041 | [`0041-index-and-manifest-tables-have-a-shape-nothing-checks`](../../session-management-findings/0041-index-and-manifest-tables-have-a-shape-nothing-checks/) | `session-management` | The index and manifest tables have a shape nothing checks | 6 | `analyzing` | **D1 is this session's coverage answer**, and `0042` and `0044` read on it. F1 resolved against Revision 195 |
| 0042 | [`0042-no-check-reads-the-rendered-page`](../../session-management-findings/0042-no-check-reads-the-rendered-page/) | `session-management` | No check reads the rendered page, and three revisions shipped defects that only the rendering showed | 5 | `analyzing` | F3 decided: no parser, no third-party package. F2 resolved against Revisions 202 and 203 |
| 0044 | [`0044-citations-under-docs-resolve-nowhere-and-nothing-reads-them`](../../session-management-findings/0044-citations-under-docs-resolve-nowhere-and-nothing-reads-them/) | `session-management` | Citations under `docs/` resolve nowhere, and nothing reads them | 2 | `answered` | Both resolved 2026-09-09; eight citations repaired. The repair does not hold until the check exists |
| 0046 | [`0046-supersession-moves-authority-and-leaves-every-citation-behind`](../../session-management-findings/0046-supersession-moves-authority-and-leaves-every-citation-behind/) | `session-management` | Supersession moves authority and leaves every citation behind | 2 | `analyzing` | Both `decided`. Nothing repaired — every citation is correct as written |
| 0049 | [`0049-the-patch-is-named-as-the-deliverable-and-never-produced`](../../session-management-findings/0049-the-patch-is-named-as-the-deliverable-and-never-produced/) | `session-management` | The patch is named as the deliverable, never defined, and would drop half the work if produced | 4 | `analyzing` | F2 and F3 resolved against Revision 232. F4's remainder parked as `0050` |
| 0051 | [`0051-the-target-platform-claim-has-no-run-behind-it`](../../session-management-findings/0051-the-target-platform-claim-has-no-run-behind-it/) | `session-management` | The target-platform claim has no run behind it, nowhere to record one, and no gate that needs one | 3 | `analyzing` | Recorded and owned 2026-09-09 at the owner's direction. F2 resolved — the ledger exists and carries the first target run |

**Read and decided 2026-09-09.** Every finding in all six was opened by this
session — the owner's first reading is what moves `un-started` on — and every one
now carries a decision. `0040` and `0044` are `answered`; the other four hold
findings that are `decided` with work outstanding, or whose decision was that no
further work is owed.

**`0050` is recorded and not owned** and does not appear above. It carries the
two defects found while reading `0049` and `0042`, and the class both belong to.
Its fixes are toolkit writes; the bundle type for those is
`docs/architecture/typed-bundles-and-work.md`, which is another session's.

**Assigned 2026-09-09 by the owner**, from the allocation run recorded in
`docs/ledgers/allocation-evidence.md`. All 6 were `unclaimed` and are owned
here from today. **They do not all read `assigned`**: `assigned` means every finding
is `un-started`, and in `0037`, `0038`, `0040` and `0041` the findings are
`framing` — recorded, not yet worked — which derives to `analyzing`. Nothing in
this set has been worked by anyone.

The split was made on the graph, not on load: every bundle in this set is one event — a check ran, it passed, and it was not looking at the thing that was wrong. Six of the eight non-lineage edges in the queue stay inside this session and none crosses out as `shares-surface`.
