# Superseding a bundle whose session is gone is instructed but never defined

**Recorded:** 2026-09-03, session `session_01PcgHu9kz9Hm5RatLQuFR8H`, from
performing the procedure in Revision 183 with nothing in the instruction set to
follow.
**Relates to:** `0029` — that bundle collects what the restore-apps session left
owed in §§4b–4d, eight of its findings landing there. This one is a single
missing subsection in §4c, found from the other direction: by needing it. The two
do not overlap in content, and this bundle should reach `resolving` first so
`0029` reads §4c as it will then stand.
**Severity:** low until it is needed, and then total — a session with no
procedure invents one, and every invented variant is a different tree shape for
the same event.
**Scope:** instruction set. The fix is one subsection in
`.github/copilot-instructions.md` §4c.

## Findings

| # | Finding | Status |
|---:|---|---|
| 1 | §4d instructs a session to mark bundles `superseded`; §4c never defines what that means or requires | `in progress` |
| 2 | Both existing accounts assume the superseding party owns the bundle. §4d itself creates the case where nobody does | `in progress` |
| 3 | Nothing states what a supersession must **not** touch, and all three prohibitions are load-bearing | `in progress` |
| 4 | The form that carries the pointer now exists in the tree and is written down nowhere | `in progress` |

---

### 1 — the term is used as an instruction and defined nowhere

`.github/copilot-instructions.md` §4d, on a `withdrawn` session:

> **THE FINDINGS GO WITH IT** — every findings bundle the session owned is marked
> `superseded` where another bundle replaces it and `withdrawn` where nothing
> does.

That is an instruction to perform a procedure. §4c — which defines the bundle
shape, the status vocabulary's location, the numbering rule and the handoff
convention — does not mention supersede at all. A session told to do the thing
has nowhere in the instruction set to learn what doing it involves.

`docs/legend.md` defines the *status* (*"A later findings bundle replaces this
reading. The row names which, and the replacement carries `Relates to`"*) and
carries a section on the case that motivated it. Definitions are not procedure,
and the legend says so itself: what each state *requires* lives in §§4c–4d.

### 2 — both accounts assume the superseding party is the owner

The legend's section is titled *When something overtakes a bundle already in
progress*, and its subject throughout is the bundle's own owner deciding to
supersede. That is one case.

§4d creates the other, in the same paragraph that uses the term:

> A `closed` session finishes and its **unfinished readings live on without an
> owner**, waiting to be picked up.

So the instruction set describes a population of ownerless readings and provides
no route by which a later session may supersede one. The same holds for a
session in `handoff` whose successor has not arrived — which is what Revision 183
met: `0009`'s owning session, `run-index-design-20260901-000000`, was in
`handoff` and could not supersede its own bundle.

The consequential question that follows is unanswered anywhere: **does
superseding transfer ownership?** It must not — a superseded reading was recorded
and held by whoever recorded and held it — but nothing says so, and the opposite
is the more natural guess for a session tidying up.

### 3 — the prohibitions are unwritten, and each is load-bearing

Three things a supersession must not do. None appears in §4c, the legend, or the
architecture record, and each was reasoned out from first principles during
Revision 183 rather than followed:

- **The superseded `findings.md` is not edited** — not to add a pointer to its
  replacement, not to repair a citation it contains. Revision 183 added a
  `Superseded by` header line to `0009`, then removed it: the structure specifies
  a row and a pointer, and a reading that shows a diff was not retained. The
  temptation is strong precisely because the edit looks helpful.
- **The number is never reused.** Reuse was proposed and declined during
  Revision 183. `0009` is cited in 16 markdown documents plus `APPLY-MANIFEST.md`;
  a second `0009` makes every one of those citations ambiguous, and two sibling
  directories cannot both carry the number, so retaining the original becomes
  impossible. §4c states *never reused, never renumbered* under numbering, but
  not where a session doing a supersession will read it.
- **The bundle does not move between manifests.** It stays listed by the session
  that recorded it, with only its status cell changed. Moving it would rewrite
  who held a reading, and `findings-manifest.md` is authoritative for exactly
  that.

### 4 — the index form exists in the tree and in no document

Revision 183 put the pointer in the superseded row's **Status** cell as a link —
`` [`superseded`](0030-…/) `` — so one cell answers both what state the bundle is
in and what replaced it. It is in `docs/cross-cutting-findings/INDEX.md` now, on
the owner's instruction, and it is the form the next supersession should copy.

Nothing records that. The legend says only *"the row names which"*, which a
session could satisfy with a Notes entry, a Subject aside, or a bare number — three
tree shapes for one event, which is the failure §4c's other conventions exist to
prevent.

---

## What it costs to leave

Nothing, until the next session supersedes something — and then it costs the
thing this whole structure is for. A session that invents the procedure will
plausibly edit the superseded reading to be helpful, or move it into its own
manifest to look tidy, or record the pointer in a fourth place. Each is
individually reasonable and each is unrecoverable in the same way: the record
stops meaning what it says, and the next reader cannot tell an original reading
from an amended one.
