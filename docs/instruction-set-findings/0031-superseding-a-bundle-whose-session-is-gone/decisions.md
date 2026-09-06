# Decisions — superseding a bundle whose session is gone

**Bundle:** `0031-superseding-a-bundle-whose-session-is-gone` · **Status:** `in progress`
**Decided:** 2026-09-03, session `session_01PcgHu9kz9Hm5RatLQuFR8H`, owner
present and routing confirmed by the owner.

## D1 — The procedure goes in §4c, as a new subsection

`docs/legend.md` defines what `superseded` *means* and says explicitly that what
each state *requires* lives in `.github/copilot-instructions.md` §§4c–4d. §4d
already instructs a session to perform the procedure. So §4c is where the
instruction belongs, and putting it there costs no new convention.

**Rejected — the legend.** It would put a nine-step procedure inside the file
that exists to hold two vocabularies, and would contradict its own statement
about where requirements live. `0027` finding 1 is already the question *where is
a rule allowed to live*; adding a procedure to the legend answers it in the
direction that bundle may well reject.

**Rejected — `docs/architecture/findings-and-sessions.md`.** That record covers
why the shape is what it is, and says so in its closing section: the
per-state requirements and the naming rules are instructions and live in §§4b–4d.
A procedure there would be found by nobody following an instruction.

**Rejected — park it in `0029` and let that bundle write §4c.** Offered as the
cheapest route. Declined by the owner: `0029` is `unresolved`, owned by another
session, and eight of its findings already land in §§4b–4d — adding a ninth from
outside would enlarge a bundle whose owner has not started deciding. This bundle
reaches `resolving` first and `0029` then reads §4c as it stands.

## D2 — The superseding session performs it and does not take ownership

The session with the new reading marks the old bundle `superseded`, updates its
row, and creates the replacement. The superseded bundle stays listed in the
`findings-manifest.md` of the session that recorded it, with only its status
changed.

**Rejected — ownership transfers with the supersession.** The natural guess, and
wrong: `findings-manifest.md` is authoritative for who recorded and held a
reading, and a supersession changes neither. Transfer would also mean a closed
session's manifest silently losing entries after it closed, which is the same
class of defect Revision 175 removed when it stopped splitting one session across
three bundles.

**Rejected — require the originating session to be reopened to do it itself.**
A `closed` session is terminal; a `handoff` may wait indefinitely for a successor.
§4d creates the ownerless population deliberately, so requiring an owner would
make those readings permanently unsupersedable.

## D3 — The three prohibitions are stated in the procedure, not cross-referenced

Do not edit the superseded `findings.md`. Do not reuse the number. Do not move the
bundle between manifests.

**Rejected — cross-reference the numbering rule where it already stands.** §4c
does say *never reused, never renumbered* under numbering. It is four hundred
words away from where a session doing a supersession is reading, and reuse was
proposed anyway during Revision 183 by an owner who had that rule in the tree. A
prohibition that has already been reached for once belongs where the reaching
happens.

**Rejected — leave the edit prohibition implicit in "a reading is written once".**
That sentence is about the reading's *content*. The tempting edit here is
navigational — a `Superseded by` pointer, which looks like metadata rather than
content. Revision 183 made exactly that edit and reverted it. Implicit was not
enough for the session that had just written the rule.

## D4 — The pointer goes in the Status cell, as a link

The superseded row's **Status** cell becomes `` [`superseded`](<new-bundle>/) ``,
so one cell answers both what state the bundle is in and what replaced it.

**Rejected — the Notes column alone**, which is what the legend's *"the row names
which"* would minimally permit. Notes is prose and is where a row's exceptions
live; a reader scanning the Status column for `superseded` would find the status
and not the successor, and would have to read the row to finish the question.

**Rejected — both cells carrying the link.** Two links to one target in one row is
the duplication the owner's standing preference rules out, and the second would
drift.

This form is already in the tree — the `0009` row carries it as of Revision 183 —
so §4c documents a form that exists rather than proposing one.

## D5 — The subsection covers the ownerless case and defers the other

The legend already covers a bundle overtaken while `in progress` and superseded by
its own owner. The new subsection covers the case §4d creates — the owning session
`closed`, `withdrawn`, or in `handoff` — and points at the legend for the first
rather than restating it.

**Rejected — one unified account covering both.** It would duplicate the legend's
section, and duplicated conventions drift. The two documents already divide as
*meaning* and *requirement*; this keeps that line.

## D6 — `0032` is not decided here

The table-shape lint gap recorded as `0032` is a separate bundle at `unresolved`,
including its own open question about which tree it belongs in. It is named in
this bundle's `Relates to` and nothing here decides it.

**Rejected — fold it in because both touch §4c.** One is a missing rule and one is
an unenforced rule. Their fixes are a documentation subsection and a shell script,
and a bundle whose findings need two different kinds of write reaches `resolving`
only when both are decided — which would hold the procedure hostage to a lint.

---

## What this authorises

One toolkit write: a new subsection in `.github/copilot-instructions.md` §4c.
Every finding in this bundle now has a decision, so `resolving` may begin. Nothing
on the artifact volume, and nothing in `0029` or `0032`.
