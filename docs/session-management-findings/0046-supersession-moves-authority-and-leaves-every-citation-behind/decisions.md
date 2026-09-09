# Decisions — supersession moves authority and leaves every citation behind

**Bundle:** `0046-supersession-moves-authority-and-leaves-every-citation-behind`  
**Session:** `assurance-coverage-20260908-204724`  
**Decided:** 2026-09-09

F2 asked whether the remedy is a marker, a check, or both. **Half of it is
already in the tree**, which this bundle was not in a position to know when it
was recorded.

**And half of F1's stated cost has since been removed.** F1 says `0028` is
*"superseded and closed to every session"* and that `docs/legend.md` *"puts it in
the row where nothing is readable"*. That was true when it was written on
2026-09-07 and stopped being true at **Revision 239**, which found `superseded`
appearing in two rows of that table under opposite rules and settled it as
**readable by any session, writable by none** — `0039` F21. The reading is not
edited; it was correct at its moment. But the decisions below are taken against
the tree as it now stands, so the cost has to be restated: **a citation to a
superseded bundle no longer sends a reader somewhere they may not look. It sends
them somewhere that is no longer authoritative and does not say so.**

That narrows the finding and does not dissolve it. F1 counted twelve documents;
counted again on 2026-09-09 there are **31 files outside `0028`'s own directory
naming it**. What each of them asserts is still invisible at the point of
citation.

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | The marker is chosen and exists: `<!-- historical: -->` in `bin/verify-doc-paths.sh`, named there as this bundle's. It covers a path; it does not cover a bundle number cited in prose | F2 | 2026-09-09 | `accepted` |
| D2 | A check is also needed, over prose citations of a bundle number. The one that exists reads asserted edges only and cannot see the twelve documents F1 counts | F1, F2 | 2026-09-09 | `accepted` |
| D3 | The twelve citations are **not** repaired, marked, or annotated. Every one is correct as written | F1 | 2026-09-09 | `accepted` |

---

## D1 — the marker exists and is narrower than the finding

`bin/verify-doc-paths.sh` documents two forms in its own header —
`<!-- historical: <path> -->` and a whole-document `<!-- historical-record -->` —
and says *"Repairing such a path would falsify the record, so HISTORICAL never
fails the run. This is `0046`'s marker."* 62 paths in the tree carry it.

**It answers a different question than F2 asks.** The marker declares that a
**path** was cited as it stood. F2 is about a **bundle number** cited in prose:
`` `0028` `` in a sentence looks identical whether the bundle is live,
superseded or withdrawn, and no path is involved at all. The marker is the right
mechanism for the case it covers and does not reach this one.

That is why D2 is not redundant with D1.

## D2 — the check that exists reads the declared set

`.internal/ai-scripts/session-management/plan_findings_work.py` reports
`EDGE-TO-SUPERSEDED` for an edge whose target bundle carries
`lineage.supersededBy`, excluding the lineage kinds. That is this finding's check,
already built — **over `metadata.json` `edges[]` only.**

F1's twelve documents cite `0028` in prose. None of those citations is an edge,
so the check passes over all of them. Counted 2026-09-09: **31 files outside
`0028`'s own directory name it**, against the twelve F1 recorded.

This is the same shape as `0041` F2 and the reason those two bundles are held by
one session: *the check that runs gives the wrong assurance*, because it covers
the set somebody declared rather than the set that exists. `0041` D1 states the
rule once and this decision is its third instance.

**The shape, and the false positive first.** A prose-citation check would read
every `` `<NNNN>` `` in a markdown document, resolve it to a bundle, and report
one whose `lineage.supersededBy` is set. **Its first run reports 31 hits on
`0028` alone and almost all of them are correct as written** — that is D3 — so a
check that reports them all is a check nobody will run twice. It has to
distinguish a citation that asserts current authority from one that records
history, and **that distinction is not in the text.** Two ways out, and neither
is free: require a marker at the citation, which is `0030`'s cost paid again by
hand; or scope the check to documents that are not themselves records, which
means every `findings.md` is exempt and most of the twelve are inside one.

**Not decided here: which.** This is where the finding stops being resolvable by
reading, and the measurement that would settle it is a run of the check that does
not exist. Recorded so the next session does not mistake the gap for an oversight.

## D3 — nothing is repaired

`0039` F8's citation of `0028` F4 was written 2026-09-04, two days before the
supersession. It was correct. Under the standing rule that evidence is never
rewritten to match a later state, it must not be edited — and section 9 spends
three prohibitions keeping a superseded reading exactly as it was.

**So the fix cannot be a repair, and this decision records that as a ruling
rather than leaving it as the finding's observation.** A later session reading
F1's count of twelve will be tempted to go and fix them. It must not.
