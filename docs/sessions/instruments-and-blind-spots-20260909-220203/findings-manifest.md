# Findings owned — `instruments-and-blind-spots-20260909-220203`

Authoritative record of the bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than restating
the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md); the same vocabulary,
rewritten with its closed sets measured, is [`iris/vocabulary.md`](../../../iris/vocabulary.md).

| # | Bundle | Kind | Subject | Findings | Standing | Notes |
|---:|---|---|---|---:|---|---|

**0 bundles · 0 members.** **Both were released to `unclaimed` on 2026-09-13 at the owner's direction, with no successor named** — §10a, and the table above is empty because removing the row *is* the release. What they were and where they stand is below.

**Both were assigned, not transferred**, from `unclaimed` at the owner's direction
at Revision 286. Adding these two rows **is** the assignment — nothing else sets
ownership — and the `ownership` field on each bundle moved from `unclaimed` to
null in the same revision.

**Neither arrives `assigned`, and that is not a mistake.** `assigned` means *owned,
and nobody has written to a member yet*, which requires `progress: untouched`.
Both have been worked, so both derive `analyzing` immediately. **The framework has
no standing for *worked, reassigned, and not yet read by its new owner*** —
`transferred` covers that only between two named sessions. A reader will look for
one; there is none.

**Why these two together.** `0050` is a check that runs and sees nothing; `0041`
is a check that was decided and never written. **Between them they are the answer
to *how do I know this framework works*** — and **nineteen members across six
bundles stand `decided` inside `unclaimed` bundles**, which is decisions taken and
work made impossible, because an unclaimed bundle is closed to every session.
These are two of those six.

---

## Released to `unclaimed` — 2026-09-13, Revision 317

**§10a step 4, kept here rather than in a handoff document**, at the owner's
direction and because there is no handoff: **no successor was named.** A released
bundle otherwise leaves no trace in the session that held it — the manifest row is
gone and the index row names nobody — so this is where the history goes.

**Neither reached `answered`, and that is why they moved.** The owner's
instruction was that any bundle this session had not answered goes back to the
queue rather than waiting on a session that has stopped advancing it.

| Bundle | Held | Released standing | Open members at release |
|---|---|---|---:|
| `0041` | 2026-09-09 to 2026-09-13, assigned at Revision 286 | `unclaimed`, progress `analyzing` | **6** — F2–F5 `decided`, F8–F9 `framing` |
| `0050` | 2026-09-09 to 2026-09-13, assigned at Revision 286 | `unclaimed`, progress `analyzing` | **8** — F1, F2, F4, F7, F8, F9, F10, F12 `framing` |

**`0041` — the index and manifest tables have a shape nothing checks.** Answered:
F1 (D2, Revision 195), F6 (D6, Revision 288), F7 (D8, Revision 312). **F2–F5 stand
`decided` with the remedies unbuilt**: F2 is D1's coverage answer, F3 decided the
tree and changed nothing, F4 is closed on the record and open on the check, and
**F5 specifies a checker that does not exist** — nothing compares a resolution's
claim against the tree. **F8** has two of its three projection classes checked by
D7 since Revision 308; the third, per-member status inside `findings.md`, is
deliberately not `structure`'s subject and needs a separate decision against a
separate script. **F9** is the newest and has no decision: nothing asserts that a
bundle can reach a terminal standing, and the detectable half — a disposition
living in prose while `statusReason` is null — measures **0 of 232 populated**
across this tree.

**`0050` — instruments that cannot fire, and one that unmakes the record.**
Answered: F3 and F6 (D3, Revision 299), F5 (D2, Revision 255), F11 (D4, Revision
308). **The eight that remain are the bundle's actual subject** and none is
blocked on measurement — each is measured and waiting on a decision. **F8, F9 and
F10 are one cluster and should be decided together**: `verify-manifest-coverage.sh`
is correct, fires, and is reached by nothing; when it fires nothing says who owes
the entry; and clearing a `MISSING` can only be done by creating a permanent
`ORPHANED`, so the metric argues against its own repair. **F12** is a hand-off that
vanished — recorded at Revision 312 after Revision 301 announced it and no bundle
took it. **F1** is settled against `0045` F4 as two findings joined by
`relates-to`. **F2** is a one-line repair, measured inert. **F4** is the class the
others are instances of, and its members were still arriving when this session
stopped.

**What a taker should know.** Both bundles carry measurements taken between
Revisions 286 and 312 and **every figure in them names the commit it was taken
at**. Re-run rather than quote forward: this session recorded three separate cases
of a figure that had moved under a document still asserting it.

**The release date is in the data, in a field added for it.** §10a requires it
and there was nowhere to put it — `ownership` is a bare string, and
`docs/ideas/big-picture.md` measures the same gap at **0 of 41 dossier standings
and 0 of 14 supersessions**. **`ownershipOn` is new here**: a sibling of
`ownership`, ISO date, written by the act rather than derived, declared in
`docs/architecture/state-as-data.md` §4.3. Both released bundles carry
`"ownershipOn": "2026-09-13"`.

**Additive, not a reshape.** Giving `ownership` `lineage`'s object form would have
been the consistent move and was rejected as breaking — `bundle_standing` returns
the value directly and 24 records carry a bare string, so it is a rename with no
migration plan, which is `0052` F2's own example. The sibling folds into
`standing.on` when §6's disposition retrofit runs.

**Populated here and nowhere else, on purpose.** The other 22 bundles standing
`unclaimed` have no date and this session did not add one: `unclaimed` is closed to
everyone. Their dates are recoverable once, from the commit that introduced each
value, and belong to whoever claims them.
