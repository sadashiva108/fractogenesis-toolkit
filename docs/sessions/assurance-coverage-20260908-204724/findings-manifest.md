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
| 0049 | [`0049-the-patch-is-named-as-the-deliverable-and-never-produced`](../../session-management-findings/0049-the-patch-is-named-as-the-deliverable-and-never-produced/) | `session-management` | The patch is named as the deliverable, never defined, and would drop half the work if produced | 6 | `analyzing` | F2, F3 resolved against Revision 232. F4's remainder parked as `0050`. F5 and F6 recorded from this session's own two breaches; F6 resolved at Revision 258 |
| 0051 | [`0051-the-target-platform-claim-has-no-run-behind-it`](../../session-management-findings/0051-the-target-platform-claim-has-no-run-behind-it/) | `session-management` | The target-platform claim has no run behind it, nowhere to record one, and no gate that needs one | 3 | `analyzing` | Recorded and owned 2026-09-09 at the owner's direction. F2 resolved — the ledger exists and carries the first target run |
| 0050 | [`0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record`](../../session-management-findings/0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record/) | `session-management` | Three instruments are correct and cannot fire, and one unmakes the record it reads | 5 | `analyzing` | Assigned 2026-09-09. F5 added on the first reading and **resolved at Revision 255** — the coverage sweep derives its roots and reports 62 where it reported 21 |
| 0053 | [`0053-the-rules-are-versioned-and-a-sessions-reading-of-them-is-not`](../../session-management-findings/0053-the-rules-are-versioned-and-a-sessions-reading-of-them-is-not/) | `session-management` | The rules are versioned and a session's reading of them is not | 3 | `analyzing` | Assigned 2026-09-09. Four decisions; the order they are carried out in is the decision. `0050` F5 blocks F3 |

**Read and decided 2026-09-09.** Every finding in all six was opened by this
session — the owner's first reading is what moves `un-started` on — and every one
now carries a decision. `0040` and `0044` are `answered`; the other four hold
findings that are `decided` with work outstanding, or whose decision was that no
further work is owed.

**`0050` and `0053` were assigned on 2026-09-09** and read on assignment, so
every finding in both is `framing`. Both were recorded by this session and not
owned until the owner assigned them — recording a bundle and owning one are
different acts, and the manifest row above is what makes this session the owner.

**Assigned 2026-09-09 by the owner**, from the allocation run recorded in
`docs/ledgers/allocation-evidence.md`. All 6 were `unclaimed` and are owned
here from today. **They do not all read `assigned`**: `assigned` means every finding
is `un-started`, and in `0037`, `0038`, `0040` and `0041` the findings are
`framing` — recorded, not yet worked — which derives to `analyzing`. Nothing in
this set has been worked by anyone.

The split was made on the graph, not on load: every bundle in this set is one event — a check ran, it passed, and it was not looking at the thing that was wrong. Six of the eight non-lineage edges in the queue stay inside this session and none crosses out as `shares-surface`.
