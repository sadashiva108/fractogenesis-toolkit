# Findings owned — `instruments-and-blind-spots-20260909-220203`

Authoritative record of the bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than restating
the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md); the same vocabulary,
rewritten with its closed sets measured, is [`iris/vocabulary.md`](../../../iris/vocabulary.md).

| # | Bundle | Kind | Subject | Findings | Standing | Notes |
|---:|---|---|---|---:|---|---|
| 0041 | [`0041-index-and-manifest-tables-have-a-shape-nothing-checks`](../../session-management-findings/0041-index-and-manifest-tables-have-a-shape-nothing-checks/) | `session-management` | The index and manifest tables have a shape nothing checks | 6 | `analyzing` | **Five members stand `decided` and no work has been done on any of them.** D1 is the coverage answer — *a check is responsible for the artifact as it will be read, not a curated proxy of it*. **D6 is the place to start**: a total is summed from the rows it describes or it is not written, and it would have caught four mistakes made on 2026-09-09 alone |
| 0050 | [`0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record`](../../session-management-findings/0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record/) | `session-management` | Three instruments are correct and cannot fire, and one unmakes the record | 10 | `analyzing` | **F3 and F6 `decided` at Revision 289.** Re-measured: **66 of 66 records, 740 values, 620 of them irrecoverable after `stamp`** — `genus` among them, so a run reverts Revision 271. D3 **retires the extraction half rather than guarding it**, because every way of making it safe is an enumeration and the enumeration is already one schema behind. The build is the next revision. **F8 and F9 at Revision 292**: `verify-manifest-coverage.sh` is correct, fires, names both manifest gaps — and **nothing runs it**; and when it fires nothing says who owes the entry. **F10 at Revision 294**: clearing a `MISSING` can only be done by creating a permanent `ORPHANED`, so the count penalises the repair; **F7 extended** with the template slot and the misattributing trailer in `15069fe`. F1 is the guard a bridged session is invisible to — **and `0045` F4 is the same guard read from the other side**, which is a `duplicates` or `co-decides` edge to settle, not a member to absorb |

**2 bundles · 16 members**, 13 of them live.

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
