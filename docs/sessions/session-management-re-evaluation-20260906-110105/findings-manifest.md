# Findings owned — `session-management-re-evaluation-20260906-110105`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the counts and points here rather than
restating the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

All six were `unclaimed` — released by `restore-apps-outstanding-20260903-000000`
when it closed on 2026-09-06 — and were assigned together on the owner's word.
Assignment set each to `un-started`; the first reading, performed the same
sitting, moved each to `analyzing` with every finding in it `framing`.

| # | Bundle | Kind | Subject | Findings | Status | Notes |
|---:|---|---|---|---:|---|---|
| 0036 | [`0036-verify-doc-paths-counts-gitignored-docs`](../../session-management-findings/0036-verify-doc-paths-counts-gitignored-docs/) | `session-management` | `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold | 1 | `analyzing` | The Revision 130 prune landed; its premise expired at Revision 162. Option (iii) — stop quoting the OK baseline — is still undecided |
| 0037 | [`0037-findings-architecture-conformance`](../../session-management-findings/0037-findings-architecture-conformance/) | `session-management` | The findings-and-sessions architecture disagrees with itself and with the tree | 7 | `analyzing` | D1 accepted, **D2 rejected** by the owner on 2026-09-06 — retrofit rather than leave half a change behind. D6's carve-out and F2's rule were both lost in the instruction-set split and must be restored |
| 0038 | [`0038-sessions-write-into-the-tree-the-owner-commits-from`](../../session-management-findings/0038-sessions-write-into-the-tree-the-owner-commits-from/) | `session-management` | Sessions compose their changes in the tree the owner commits from | 6 | `analyzing` | All six resolutions verified present and holding. What it removed — `git status` as the only signal of a concurrent session — is recorded and unreplaced |
| 0039 | [`0039-the-instruction-set-lags-the-rules-it-governs`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | `session-management` | The instruction set lags the rules it governs | 11 | `analyzing` | The keystone. D1's destination no longer exists, so it cannot be applied as written. Seven rows were `decided`; reset to `framing` on the owner's instruction to re-evaluate from the ground up — `decisions.md` retains every decision |
| 0040 | [`0040-superseding-a-bundle-whose-session-is-gone`](../../session-management-findings/0040-superseding-a-bundle-whose-session-is-gone/) | `session-management` | Superseding a bundle whose session is gone is instructed but never defined | 4 | `analyzing` | All four resolutions verified present in §9 and expanded since. Only the address is stale: every row cites §4c, which no longer exists |
| 0041 | [`0041-index-and-manifest-tables-have-a-shape-nothing-checks`](../../session-management-findings/0041-index-and-manifest-tables-have-a-shape-nothing-checks/) | `session-management` | The index and manifest tables have a shape nothing checks | 5 | `analyzing` | F4 sharpened by this session on 2026-09-06. F3's classification question is open and reaches four other bundles |

| 0043 | [`0043-framework-state-lives-in-documents-not-data`](../../session-management-findings/0043-framework-state-lives-in-documents-not-data/) | `session-management` | The framework's own state lives in documents rather than in data | 9 | `analyzing` | Recorded and owned by this session on 2026-09-07, the only one of the seven not released by `restore-apps-outstanding`. Held open at `analyzing`/`framing` so the parallel architecture session can record to it |

**7 bundles · 43 findings.**

`0042-no-check-reads-the-rendered-page` sits in the same tree and is **not owned
by this session.** It is `unclaimed` and stays that way until the owner assigns
it; its F3 is a dependency decision that is the owner's to take.
