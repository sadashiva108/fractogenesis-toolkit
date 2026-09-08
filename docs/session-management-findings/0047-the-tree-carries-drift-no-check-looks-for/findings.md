# The tree carries status drift that no check looks for

**Recorded:** 2026-09-07, from a conformance sweep run at the owner's direction before any retrofit.  
**Session:** `allocation-and-inquiry-design-20260906-233205` (`session_015FpYVBF7dDoDrHfKDkq8fn`)  
**Severity:** F1 is high — an `unclaimed` bundle is meant to be closed to every session and one is not. F5 is high for a different reason: it is a defect in the instrument, and acting on the instrument's raw output would touch sixty-five records that are correct.  
**Felt at:** `0001` F1; `0030`, `0035`, `0036`; eleven bundles resolved before Revision 162's conversion  
**Scope:** session management. The remedy is a check and a retrofit, and the retrofit waits on `docs/architecture/state-as-data.md`  
**Relates to:** `0043` — its F2 and F7 are why this drift is possible; this is the inventory of what that cost  
**Relates to:** `0045` — the same question one vocabulary over

**Read:**

- every `findings.md`, `decisions.md`, `resolutions.md` and `STATUS-` tag in the four trees — 45 bundles, 131 findings
- `docs/legend.md`, the ladder and the two permission tables
- `docs/architecture/state-as-data.md` sections 4.3 and 4.4

Recorded `unclaimed`. Not owned. **The retrofit it points at should not begin
until the state format lands** — doing it in markdown first means doing it twice,
and `state-as-data.md` makes two of these classes structurally impossible rather
than checkable.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | Releasing a bundle to `unclaimed` leaves its findings where they were, so a bundle closed to every session holds a readable finding | `un-started` |
| F2 | Six `accepted` decisions never moved their finding out of `framing` | `un-started` |
| F3 | Three bundles carry resolutions for findings that are not resolved | `un-started` |
| F4 | Eleven `resolved` bundles have no `decisions.md`, and whether they owe one has never been decided | `un-started` |
| F5 | A conformance sweep that does not know about superseding clones reports sixty-five false positives | `un-started` |

## F1 — an `unclaimed` bundle holding a live finding

`0001-restore-repos-evidence` is tagged `STATUS-unclaimed`. Its F1 is `framing`.

`docs/legend.md` puts `unclaimed` in the row where **nothing is readable**, and
says the bundle is *"parked and closed to every session until the owner assigns
it."* A `framing` finding is the opposite: open to every session, to read and to
record.

The history explains it without excusing it. `0001` was worked by
`restore-apps-outstanding-20260903-000000`, and released to `unclaimed` on
closing at Revision 205 — *"undecided"*, in its own `final-summary.md`. **The
release changed the bundle's tag and left the ten findings exactly as they
were.** Nine are `un-started`; F1, which had been read and decided against, stayed
`framing`.

Nothing in section 9, section 10 or the legend says what happens to a finding
when its bundle is released, which is why nothing happened to it.

## F2 — six decisions that moved nothing

`0001`'s `decisions.md` carries D1 through D6, every one `accepted`, every one
naming F1. F1 is `framing`.

`docs/legend.md` defines `decided` as *"every decision is made"*. Six accepted
decisions and no seventh outstanding is that condition met, and the index row
says so in prose — *"F1 has six decisions recorded against it and nothing
outstanding"*. The status never moved.

This is F1's defect and this one arriving together, and they are separable: a
bundle could be released correctly and still leave this, or move this correctly
and still be released wrong.

## F3 — resolutions for findings that are not resolved

| Bundle | Tag | Findings | Resolution rows |
|---|---|---|---:|
| `0030` | `analyzing` | 5 × `framing` | 5 |
| `0035` | `un-started` | 3 × `un-started` | 3 |
| `0036` | `analyzing` | 1 × `decided` | 1 |

`0035` is the plainest: a bundle nobody has opened, by its own tag, with three
resolutions recorded in it. Its index Notes say *"closed 2026-09-04; recorded and
resolved in one sitting"*, so the work was done and only the statuses stayed
still.

`0036` is the mildest and may not be a defect at all — a finding that is
`decided` is one its owner resolves from there, and a resolution row written
during that work is ahead of the status by minutes rather than by a policy.
**Whether a resolution may precede the status it implies is the question F3
owes**, and the answer decides all three rows.

## F4 — eleven resolved bundles with no `decisions.md`

`0002`, `0003`, `0004`, `0006`, `0007`, `0018`, `0019`, `0020`, `0022`, `0023`
and `0026`. All eleven are among the twenty-five parked notes converted to
bundles in Revision 162, one finding each.

`.github/session-management-instructions.md` section 3 lists `decisions.md` as
part of a bundle and says a decision without its rejected alternatives is an
assertion. These have neither document nor alternatives.

**The answer is probably that they owe nothing**, and it is not this bundle's to
give. A note parked before the shape existed recorded a conclusion and no
deliberation, and section 11 already provides for exactly that: a finding closed
before the shape existed carries `—` in `Resolved by`. **Writing decisions into
them now would be inventing deliberation that never happened**, which is the
rule about evidence, breached in the direction of tidiness. One decision covers
all eleven.

## F5 — the sweep is wrong before it is right

The sweep that produced this reading reported **77 instances across 45 bundles**
on its first run. **Sixty-five are `0037` through `0041` and are correct by
construction.**

Those five are superseding clones opened on 2026-09-06 for the ground-up
re-evaluation. Their findings were reset to `framing` for re-examination while
they carry the originals' `decisions.md` and `resolutions.md` forward. A decision
ahead of its finding and a resolution ahead of its finding are exactly what that
looks like from outside, and both are intended.

**This is the third instrument in this repository to report mass failure against
a healthy tree on its first run.** `0041`'s lint reported 36 failures where every
other validator passed; `0042` F4's rendering audit reported 131 of which 128
were bugs in the audit. The pattern is the same each time: the half that reads
the tree is wrong, not the half that judges it.

So the rule belongs in the check before the check is trusted: **a bundle whose
`Relates to` declares it supersedes another is exempt from the ordering
comparisons** until its re-reading closes. Without it the sweep would direct a
retrofit at sixty-five records that are already right.
