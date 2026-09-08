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
| 0036 | [`0036-verify-doc-paths-counts-gitignored-docs`](../../session-management-findings/0036-verify-doc-paths-counts-gitignored-docs/) | `session-management` | `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold | 1 | `resolved` | **Resolved at Revision 225.** Option (iv): `docs/` is scanned, and `proposed` and `historical` are declarable — which is also `0046`'s remedy. 1714 OK / 0 MISSING / 0 broken anchors |
| 0037 | [`0037-findings-architecture-conformance`](../../session-management-findings/0037-findings-architecture-conformance/) | `session-management` | The findings-and-sessions architecture disagrees with itself and with the tree | 7 | `analyzing` | Clean slate at Revision 224: its `decisions.md` and `resolutions.md` were byte-identical clones of `0027`'s and are removed. Seven findings `framing`, seven provenance edges. D2's `Outcome` → `rejected` is still owed |
| 0038 | [`0038-sessions-write-into-the-tree-the-owner-commits-from`](../../session-management-findings/0038-sessions-write-into-the-tree-the-owner-commits-from/) | `session-management` | Sessions compose their changes in the tree the owner commits from | 6 | `analyzing` | Clean slate at Revision 224: byte-identical clones of `0028`'s removed. Six findings `framing`, six provenance edges, nothing decided in this bundle |
| 0039 | [`0039-the-instruction-set-lags-the-rules-it-governs`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | `session-management` | The instruction set lags the rules it governs | 19 | `analyzing` | The keystone, and the most worked. **Four findings resolved** (F7, F12, F15, F16), F8 `decided` and owed. D13 replaced D1, whose destination `1c48deb` had deleted. F13 and F14 recorded unanswered for the owner |
| 0040 | [`0040-superseding-a-bundle-whose-session-is-gone`](../../session-management-findings/0040-superseding-a-bundle-whose-session-is-gone/) | `session-management` | Superseding a bundle whose session is gone is instructed but never defined | 4 | `analyzing` | Clean slate at Revision 224: byte-identical clones of `0031`'s removed. Four findings `framing`, four provenance edges |
| 0041 | [`0041-index-and-manifest-tables-have-a-shape-nothing-checks`](../../session-management-findings/0041-index-and-manifest-tables-have-a-shape-nothing-checks/) | `session-management` | The index and manifest tables have a shape nothing checks | 5 | `analyzing` | Clean slate at Revision 224: its `decisions.md` and `resolutions.md` were the **only** copies of `0032`'s work and were moved there, not deleted. Five findings `framing`, four provenance edges |
| 0043 | [`0043-framework-state-lives-in-documents-not-data`](../../session-management-findings/0043-framework-state-lives-in-documents-not-data/) | `session-management` | The framework's own state lives in documents rather than in data | 9 | `analyzing` | **Two findings resolved** (F5, F6): authority moved to data, 54 `metadata.json` files, all tag files gone. Held open so `allocation-and-inquiry-design` can record to the remaining seven |

**7 bundles · 51 findings.**

`0042-no-check-reads-the-rendered-page` sits in the same tree and is **not owned
by this session.** It is `unclaimed` and stays that way until the owner assigns
it; its F3 is a dependency decision that is the owner's to take.
