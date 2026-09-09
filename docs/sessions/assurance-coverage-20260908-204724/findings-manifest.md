# Findings owned — `assurance-coverage-20260908-204724`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than
restating the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Standing | Notes |
|---:|---|---|---|---:|---|---|
| 0040 | [`0040-superseding-a-bundle-whose-session-is-gone`](../../session-management-findings/0040-superseding-a-bundle-whose-session-is-gone/) | `session-management` | Superseding a bundle whose session is gone is instructed but never defined | 4 | `analyzing` | Supersession when the owning session is gone. `0040/F1 relates-to 0046/F1` |
| 0041 | [`0041-index-and-manifest-tables-have-a-shape-nothing-checks`](../../session-management-findings/0041-index-and-manifest-tables-have-a-shape-nothing-checks/) | `session-management` | The index and manifest tables have a shape nothing checks | 5 | `analyzing` | A required shape nothing enforces. `F1 co-decided with 0042/F1`; `F2 co-decides 0044/F1` |
| 0042 | [`0042-no-check-reads-the-rendered-page`](../../session-management-findings/0042-no-check-reads-the-rendered-page/) | `session-management` | No check reads the rendered page, and three revisions shipped defects that only the rendering showed | 4 | `assigned` | No check reads the rendered page. `F3 blocks F1` — a rendering check needs a parser the repository does not have |
| 0044 | [`0044-citations-under-docs-resolve-nowhere-and-nothing-reads-them`](../../session-management-findings/0044-citations-under-docs-resolve-nowhere-and-nothing-reads-them/) | `session-management` | Citations under `docs/` resolve nowhere, and nothing reads them | 2 | `assigned` | Citations that resolve nowhere. `F1 co-decided with 0041/F2`; `F1 relates-to 0047/F3`, which is Session A's |
| 0046 | [`0046-supersession-moves-authority-and-leaves-every-citation-behind`](../../session-management-findings/0046-supersession-moves-authority-and-leaves-every-citation-behind/) | `session-management` | Supersession moves authority and leaves every citation behind | 2 | `assigned` | Supersession leaves every citation behind. `F2 constrains 0044/F2` |
| 0049 | [`0049-the-patch-is-named-as-the-deliverable-and-never-produced`](../../session-management-findings/0049-the-patch-is-named-as-the-deliverable-and-never-produced/) | `session-management` | The patch is named as the deliverable, never defined, and would drop half the work if produced | 4 | `assigned` | The patch never produced. `F2 blocks F1` and `co-decides F3`; `F3 relates-to 0042/F2` |

**Assigned 2026-09-09 by the owner**, from the allocation run recorded in
`docs/ledgers/allocation-evidence.md`. All 6 were `unclaimed` and are owned
here from today. **They do not all read `assigned`**: `assigned` means every finding
is `un-started`, and in `0037`, `0038`, `0040` and `0041` the findings are
`framing` — recorded, not yet worked — which derives to `analyzing`. Nothing in
this set has been worked by anyone.

The split was made on the graph, not on load: every bundle in this set is one event — a check ran, it passed, and it was not looking at the thing that was wrong. Six of the eight non-lineage edges in the queue stay inside this session and none crosses out as `shares-surface`.
