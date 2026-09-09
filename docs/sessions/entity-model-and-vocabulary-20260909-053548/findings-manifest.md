# Findings owned — `entity-model-and-vocabulary-20260909-053548`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than
restating the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Standing | Notes |
|---:|---|---|---|---:|---|---|
| 0037 | [`0037-findings-architecture-conformance`](../../session-management-findings/0037-findings-architecture-conformance/) | `session-management` | The findings-and-sessions architecture disagrees with itself and with the tree | 7 | `transferred` | **Arrived `answered` and is owed one more reading.** All seven are `resolved`; the legend still never says a finding may record a fact established rather than a defect. Recording that as F8 takes the bundle back to `analyzing`, which is correct and not a regression |
| 0039 | [`0039-the-instruction-set-lags-the-rules-it-governs`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | `session-management` | The instruction set lags the rules it governs | 25 | `transferred` | The keystone and the most worked: F7, F12, F15, F16, F14 decided or resolved; fourteen still `framing`. **D23 is decided and deliberately not carried out** — the provenance extraction across the three rule documents, 23 retired read-trigger sites, parked until the entity model settles |
| 0045 | [`0045-a-session-whose-output-is-not-a-bundle-has-no-state`](../../session-management-findings/0045-a-session-whose-output-is-not-a-bundle-has-no-state/) | `session-management` | A session whose output is not a findings bundle has no state that fits | 3 | `transferred` | **This bundle is F1's second live instance.** It was created before its session and derives `active` on day zero, owning four bundles nobody has opened; the first was `typed-bundles-architecture-20260908-204724`, created `available` owning nothing |
| 0048 | [`0048-the-session-capacity-limit-has-no-datum`](../../session-management-findings/0048-the-session-capacity-limit-has-no-datum/) | `session-management` | The session capacity limit has no datum, and its only proxy points the wrong way | 3 | `transferred` | Capacity has no datum. F1 blocks F3: what to capture cannot be settled before it is agreed nothing is captured. Section 4.7 of the draft answers it from the side that can |

**4 bundles · 38 findings**, 26 of them live.

**F24 and F25 of `0039` were contributed at Revision 268** by
[`drift-and-the-write-boundary-20260909-053548`](../drift-and-the-write-boundary-20260909-053548/),
which does not own the bundle. A contribution is not an act of ownership and
**does not clear the transfer**; the row above still reads `transferred`. Both
are recorded in `0039`'s Contributions table, and **F25 is a finding about the
act of writing them** — the permission table has no row for the standing this
bundle is in.

**Every Standing cell above reads `transferred`, and that is the whole set's
state, not a copy of one.** Standing is read lineage first, ownership second,
progress third, so an ownership statement covers the progress underneath it. What
is underneath: `0037` `answered`, `0039` and `0045` `analyzing`, `0048`
`untouched`. Each cell becomes its own progress the moment this session writes to
that bundle as owner.

**Transferred in at Revision 261**, all four, from
`typed-bundles-architecture-20260908-204724`, which stands `handoff`. **Not an
assignment.** Each stands `transferred` until this session's first write to it
**as owner** — and *as owner* is load bearing: a contribution to a bundle is not
an act of ownership and does not clear a transfer.

**The split was made on the graph, not on load.** This set is the entity model:
what a session, a bundle and a finding are, and what a record of one may say.
The other half — `0038`, `0047`, `0052` — is the tree's own state and the tree the
owner commits from, and it is
[`drift-and-the-write-boundary-20260909-053548`](../drift-and-the-write-boundary-20260909-053548/)'s.
**No edge crosses between the two sets that carries a dispatch constraint.** The
one that did — `0037/F1 blocks 0047/F4` — is discharged, F4 being `resolved`.

**`0043` is not here and is wanted.** *Framework state lives in documents, not
data* is the data-model reading this session's third job rests on. It is owned by
`session-management-re-evaluation-20260906-110105`, which stands `handoff` with no
successor, and it is deliberately open for recording. Its ownership is an open
question for the owner and is not assumed here.
