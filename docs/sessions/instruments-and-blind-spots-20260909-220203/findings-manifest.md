# Findings owned — `instruments-and-blind-spots-20260909-220203`

Authoritative record of the bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than restating
the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md); the same vocabulary,
rewritten with its closed sets measured, is [`iris/vocabulary.md`](../../../iris/vocabulary.md).

| # | Bundle | Kind | Subject | Findings | Standing | Notes |
|---:|---|---|---|---:|---|---|
| 0041 | [`0041-index-and-manifest-tables-have-a-shape-nothing-checks`](../../session-management-findings/0041-index-and-manifest-tables-have-a-shape-nothing-checks/) | `session-management` | The index and manifest tables have a shape nothing checks | 8 | `analyzing` | **Five members stand `decided` and no work has been done on any of them.** D1 is the coverage answer — *a check is responsible for the artifact as it will be read, not a curated proxy of it*. **D6 is the place to start**: a total is summed from the rows it describes or it is not written, and it would have caught four mistakes made on 2026-09-09 alone **D7's precondition is built at Revision 306** — the derivation fixture set, an enumeration over all 63 presence-combinations rather than chosen bundles, which **answered `0043` F7** on the way: the else branch does assert something, and this session's first attempt at stating it was wrong on seven of them. Suite 69 → 73. |
| 0050 | [`0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record`](../../session-management-findings/0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record/) | `session-management` | Three instruments are correct and cannot fire, and one unmakes the record | 11 | `analyzing` | **F3 and F6 `decided` at Revision 289.** Re-measured: **66 of 66 records, 740 values, 620 of them irrecoverable after `stamp`** — `genus` among them, so a run reverts Revision 271. D3 **retires the extraction half rather than guarding it**, because every way of making it safe is an enumeration and the enumeration is already one schema behind. **Built at Revision 299**: the extractor is deleted and `check-metadata-completeness.py` is its own file. **F8 and F9 at Revision 292**: `verify-manifest-coverage.sh` is correct, fires, names both manifest gaps — and **nothing runs it**; and when it fires nothing says who owes the entry. **F10 at Revision 294**: clearing a `MISSING` can only be done by creating a permanent `ORPHANED`, so the count penalises the repair; **F7 extended** with the template slot and the misattributing trailer in `15069fe`. F1 is the guard a bridged session is invisible to, and **settled against `0045` F4 at Revision 297**: **two findings, not one**, and **neither of the two edge kinds the prompt named**. F4's answer subsumes F1's and not the reverse, so `duplicates` is false and `co-decides` would bind another session's deciding to this one. The kind that fits is `generalises` and **it could not be asserted** — two rank-4 copies give it opposite directions, `docs/legend.md` does not contain the word, and the code carries no direction — so `relates-to` is asserted and the defect recorded into `0043` F13 **Revision 308 builds `0041` D7** and, in building it, found **F11**: this script carried a **fourth copy** of the standing derivation with the two overrides in the wrong order — **128 disagreements in 384 enumerated cases**, every one a bundle both released and superseded, and **no bundle in the tree reaches the branch**, which is why four revisions of clean runs said nothing. A conformant record built from `0009` fails the Revision 307 script and passes the Revision 308 one. **D4 deletes the copy rather than correcting it**; the derivation is imported from the module that owns it, and `TestLadder` gains the ordering assertion — it tested the two overrides separately and never on one bundle, so no test could observe an ordering. Suite 73 → 74. |

**2 bundles · 19 members**, 13 of them live. **`0050` F3, F6 and F11 `resolved`**, F11 at Revision 308 in the same revision that recorded it.

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
