# Resolutions — superseding a bundle whose session is gone

**Bundle:** `0031-superseding-a-bundle-whose-session-is-gone` · **Status:** `resolved`
**Recorded:** 2026-09-03, session `session_01PcgHu9kz9Hm5RatLQuFR8H`.

One toolkit write, in `.github/copilot-instructions.md` section 4c: a new
subsection, *Superseding a bundle whose session is gone*, placed after the
handing-one-off convention and before section 4d, which is the section that
instructs the procedure.

| Finding | Resolved by | How |
|---|---|---|
| 1 — the term is instructed in 4d and defined nowhere | 4c subsection, opening paragraph | Names the case 4d creates and points at `docs/legend.md` for the owner-present case rather than restating it |
| 2 — both accounts assume the superseding party owns the bundle | 4c subsection, second paragraph | *The session with the new reading does it, and does not take ownership.* States that the bundle stays in the recording session's manifest and why |
| 3 — the prohibitions are unwritten | 4c subsection, the three-item list | Stated in the procedure rather than cross-referenced, per decision 3 |
| 4 — the index form exists in the tree and nowhere in writing | 4c subsection, step 5 | The Status cell carries the link. Documents the form Revision 183 put in `docs/cross-cutting-findings/INDEX.md`, rather than proposing a new one |

## What the subsection does not do

It does not restate the legend's account of a bundle overtaken while
`in progress`; it points there. It does not touch the numbering rule, the bundle
layout, or anything else in 4c. Nothing in `docs/legend.md` changed, so the
division between *meaning* and *requirement* is unmoved.

`0029` is unaffected. Eight of its findings land in sections 4b through 4d, and
none of them is this one; it reads section 4c as this revision leaves it. The
owner confirmed nothing else would touch section 4c before this landed.

## Validation

Documentation lint: 0 MISSING, 0 ANCHOR BROKEN. Runbook structure and script
portability unchanged — no runbook and no script was touched. Composed in a copy
outside the owner's checkout and handed over as a patch, per `0028`; the manifest
revision number taken at apply time with `./bin/check-manifest-revision.sh`.
Applied by the owner, not by this session.

Validators ran on Linux with Bash 5.1. Nothing here is executable, so the macOS
Bash 3.2 debt is not extended by this revision.
