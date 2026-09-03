# Sessions — index

Every session is a bundle: `docs/sessions/<title>-<stamp>/`, holding a
`STATE-<state>` tag and `prompt.md` always, `findings-manifest.md` once it owns a
finding, one `handoff-<stamp>.md` per handover, and `final-summary.md` when it
reaches `closed` or `withdrawn`.

The shape and what each state owes are in `.github/copilot-instructions.md`
section 4d. **What the states mean is in [`docs/legend.md`](../legend.md)**,
alongside the findings statuses. This file carries the rows.

`findings-manifest.md` inside a bundle is authoritative for what that session
owns; the table below carries the count and points at it rather than restating
the list.

---

## Bundles

| Bundle | State | Owner and when | Findings | Notes |
|---|---|---|---|---|
| [`restore-apps-outstanding-20260903-000000`](restore-apps-outstanding-20260903-000000/) | `owned` | Claude, 2026-09-03 | [1](restore-apps-outstanding-20260903-000000/findings-manifest.md) | Eight parked items from Revisions 143–155, then `restore-apps.md`. Produced finding `0001` and Revisions 160–162 |
| [`run-index-design-20260901-000000`](run-index-design-20260901-000000/) | `handoff` | last owned 2026-09-02 | [14](run-index-design-20260901-000000/findings-manifest.md) | Items 1–3 done, **resume at item 4**. Two handoffs; the later one is where to start |
| [`restore-repos-refactor-20260902-000000`](restore-repos-refactor-20260902-000000/) | `closed` | — | [5](restore-repos-refactor-20260902-000000/findings-manifest.md) | Revision 131. Carries the Phase 11B plan it executed |
| [`restore-repos-clone-plan-20260902-000000`](restore-repos-clone-plan-20260902-000000/) | `closed` | — | [1](restore-repos-clone-plan-20260902-000000/findings-manifest.md) | Revisions 143–150, and `docs/architecture/restore-repos-clone-plan.md` |
| [`restore-git-phase-11a-20260901-155433`](restore-git-phase-11a-20260901-155433/) | `closed` | — | — | Phase 11A, driven interactively. No prompt survives; the transcript is the record |

**`-000000` in a stamp means the start time was not recoverable.** These five
bundles were converted from loose files in Revision 162, and only the Phase 11A
transcript carried a usable timestamp. A bundle created from now on stamps the
moment it was made.

---

## Not a bundle

| File | What it is |
|---|---|
| [[docs/sessions/session-responsibilities\|Session responsibilities]] | **The boundary between concurrent sessions.** One file, one owner. Read before your first edit; update it when work changes hands. It describes the relationship *between* bundles, so it belongs to none of them. |

---

## Where the other kinds live

Findings go to `docs/runbook-findings/<runbook>/` or
`docs/cross-cutting-findings/`, indexed per scope and keyed to sessions through
each bundle's `findings-manifest.md`. Design that outlives a session moves to
`docs/architecture/`; recurring tallies to `docs/ledgers/`.

## A note on the old paths

`APPLY-MANIFEST.md` cites three of these files by the paths they had before the
conversion — `next-session-prompt-run-index.md`, `run-index-2026-09-01.md` and
`restore-git-2026-09-01.txt`. It quotes paths as they were and is never
retro-edited, so those citations name files that have moved. Revision 162 carries
the full old-to-new mapping for exactly that reason.
