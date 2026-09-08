# Resolutions — the framework's own state lives in documents rather than in data

**Bundle:** `0043-framework-state-lives-in-documents-not-data`  
**Session:** `session-management-re-evaluation-20260906-110105` (`session_01FhFbEgG4wmrtJqUCcryNVQ`)  
**Decisions:** `decisions.md`, two across two findings.

Two findings are closed. The reasoning is in `decisions.md` and in
`docs/architecture/state-as-data.md`; this file records what was done.

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F5 | D1 | Authority moved from documents to data: 54 `metadata.json` files, and the `STATUS-`/`STATE-` tag files deleted | 222 | `42d08a4` |
| F6 | D1 | Every repeatable field is an array, and `Relates to` became a projection over typed edges | 222 | `42d08a4` |

---

## What changed

**54 `metadata.json` files** — one per findings bundle and one per session,
extracted one way from the markdown: 47 bundles, 7 sessions, 142 findings, 81
decisions, 31 provenance edges.

**All 54 tag files deleted.** A bundle's status and a session's state now derive
from the findings in `metadata.json` and are stored nowhere. `verify-findings-structure.sh`
derives instead of reading a filename, and **fails a bundle that still carries a
tag**, so the door does not reopen.

**The three status fields replaced one slot.** `progress` is derived and never
stored; `ownership` is computed by scanning the session manifests, which §6.1
always specified; `lineage` carries supersession. That is F1's *one slot, three
orthogonal facts* answered — and F1 itself is not closed here, because the
generator that would make the tags rendered artefacts was never written; they were
removed instead.

**F6 specifically:** `feltAt`, `read`, `owners`, `resources`, `ownedBundles`,
`contributions` and `edges` are arrays in the schema. `Relates to` is a projection
over `relates-to` edges rather than a header field. **This bundle was the instance
that proved it** — it carries three `Relates to` lines, and both draft configs
modelled the field as a scalar.

## The round trip, which is what makes this a resolution rather than a claim

§9 step 2 was run before a single tag was deleted: the derivation was computed for
all 47 bundles and 7 sessions and compared against **every tag in the tree**. **54
of 54 agreed.**

Getting there forced two corrections, and neither was an extraction bug:

**Ownership is computed, not read off a tag** — the first extraction stored
`unclaimed` from the filename, which is the same second copy in a different file.

**`unclaimed` means live work nobody holds**, not merely *no owner*. Six bundles
came out `unclaimed` over rows reading `resolved`; a finished reading is in no
queue. That precision had never been written down because a human applying the
ladder by hand never needed it.

And one defect in the tree: `0010` and `0024` were indexed `un-started` while
listed by no session at all. Ladder row 1 sits above row 3, so both are
`unclaimed`. **The old checker could not have caught it** — it compared a tag
against a row, and both held the same wrong value.

## What was NOT done

**The generator does not exist.** `state-as-data.md` §6 specifies it and §9 step 5
defers it. The markdown is still authored, not projected, and the edges live in
the data only — no `findings.md` renders them. **§9 step 2 in its full form —
regenerate every document from the JSON and diff against the tree — has not been
run.** It was run for the status field alone. That is the extraction's only real
outstanding proof and it belongs to whoever writes the generator.

**F1, F2, F3, F4, F7, F8 and F9 remain `framing`**, deliberately: this bundle is
held open so `allocation-and-inquiry-design-20260906-233205` can record to it.

**The extractor's own parser was wrong, twice, while retiring the practice of
parsing markdown.** 162 contaminated fields and 39 lost `Read:` bullets, found by
a person reading the output while four checkers reported 0 FAIL correctly. That is
recorded as `0039` F16 rather than here, because the defect was in the instrument
and not in this reading.
