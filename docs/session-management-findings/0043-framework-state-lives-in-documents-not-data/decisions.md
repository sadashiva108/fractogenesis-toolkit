# Decisions — the framework's own state lives in documents rather than in data

**Bundle:** `0043-framework-state-lives-in-documents-not-data`  
**Session:** `session-management-re-evaluation-20260906-110105` (`session_01FhFbEgG4wmrtJqUCcryNVQ`)  
**Decided:** 2026-09-07, between this session and `allocation-and-inquiry-design-20260906-233205`, with the owner relaying.

Two decisions. Both were reached in conversation across two sessions and existed
only in relayed messages until now, which is the defect this bundle is about,
one level out.

## Decisions

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | Findings are addressed as `<bundle>/F<n>`, relationships are typed edges, an edge is stored in the bundle whose session asserted it, stored edges are assertions, and `Relates to` becomes a projection | F5, F6 | 2026-09-07 | `accepted` |
| D2 | §9 step 3 changes from *write this line* to *assert this edge* in the revision that ships the projection, and not before | F5 | 2026-09-07 | `accepted` |

## D1 — the edge contract

Accepted whole by both sessions. The shape is
`docs/architecture/allocation-and-inquiry.md` §3.3 unchanged: `kind`, `from`,
`to`, `why`, `basis`, `asserted_by`, `asserted_on`. Four points settle what §3.3
left open.

**A finding is addressable as `<bundle>/F<n>`.** The `F1`/`F2` numbering adopted
in Revision 201 to stop `decisions.md` citing bare digits turns out to be the
addressing scheme, which is why this is possible now and was not six weeks ago.

**An edge lives in the bundle whose session asserted it.** Three alternatives
were rejected:

- **The `from` bundle holds it.** Fails on the four undirected kinds —
  `co-decides`, `contradicts`, `duplicates`, `shares-surface` — which have no
  natural owner, so the choice would be arbitrary and unrecoverable later.
- **Both endpoints hold it.** Two copies of one fact, which is F5 and the whole
  subject of this bundle.
- **One `edges.json` for the tree.** A file **every session must write**, which
  is `0038` F1 exactly: the manifest and the sessions index were the two files
  nobody could be kept off, and the mechanisms proposed against them degraded to
  *wait your turn*.

Storing by assertion falls out of `asserted_by`, which §3.3 already requires. The
graph is the union of every bundle's array; the signature becomes structural
rather than a field a reader must trust.

**Stored edges are `asserted` by construction.** A `derived` edge is recomputed
at load and never written. `basis` stays in the model so the emitted graph is
uniform and a session can pin a derivation it disagrees with, but the file holds
assertions only — which halves what the schema carries and makes the split
structural rather than declared.

**`Relates to` stops being a header field** and becomes the projection of
`kind == "relates-to"`. That is what *one kind among ten* means if it means
anything, and it is what answers F6 fully: the field was optional **and
repeatable**, both drafts modelled it as a scalar, and this bundle carries three
of them.

### What it costs

**§11's field list changes**, removing `Relates to:` from the header schema — a
rule edit, and therefore gated. **Every existing `Relates to` line becomes data**
in a migration. And the assertion rules of §3.3 become global checks at load
rather than per-file ones: both endpoints resolving, the signature present, and
expiry when either endpoint goes inert.

## D2 — the procedure changes when the format exists, not before

`docs/legend.md` and §9 step 3 have a superseding bundle write
`**Relates to:** <NNNN> — **supersedes it.**` as a line. Under D1 that becomes a
`supersedes` edge rendering as the same line. The line is identical either way,
so nothing reads differently — but the **instruction** differs, and if §9 changes
first, the next supersession hand-writes a line the generator then overwrites.

**Decided: §9 step 3 is not touched until the revision that ships the
projection.** The reasoning is the other session's and is worth keeping as
stated: *changing a procedure for a format that isn't built is how the
instruction set gets ahead of the tree instead of behind it.*

That is the inverse of this tree's usual failure. `0039` is nine findings about
the instruction set lagging what the tree does; this is the first recorded case
of declining to let it lead, and the condition is explicit rather than a
judgement made twice.

**Rejected: change §9 now and note that the projection is pending.** It would
leave a procedure in force describing a mechanism that does not exist, which is
the shape of `0039` F1 — a rule with no home that works — pointed the other way.

## What is not decided here

**F9's taxonomy defect**, where an edge kind's description and its behaviour
disagree. This session would state that the behaviour wins and record the case;
the fix lands in `allocation-and-inquiry.md` §3.2, not here, and it is the other
session's to take.

**Where the state format goes at all.** D1 settles the edge contract and nothing
else. The two `metadata.json` schemas, the generation map, the marker
convention, `--check`, and the migration are designed in
[`docs/architecture/state-as-data.md`](../../architecture/state-as-data.md) and
are **not decided** by it either — an architecture record sets out the shape and
what it costs; the decisions belong here, and none of them has been taken.
