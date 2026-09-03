# Sessions — index

Every session is a bundle: `docs/sessions/<title>-<stamp>/`, holding a
`STATE-<state>` tag and `prompt.md` always, `findings-manifest.md` once it owns a
finding, one `handoff-<stamp>.md` per handover, and `final-summary.md` when it
reaches `closed` or `withdrawn`.

The shape and what each state owes are in `.github/copilot-instructions.md`
section 4d. **What the states mean is in [`docs/legend.md`](../legend.md)**,
alongside the findings statuses. This file carries the rows.

`findings-manifest.md` inside a bundle is authoritative for what that session
owns and `metadata.md` for who and what has owned it — assistant, session
identifier, model and the environment it actually ran in. The table below carries
the state and the counts and points at both rather than restating them.

**The Owner column carries the session identifier as well as the assistant.** The
bundle name already tells one session from another — that is what it is for. The
identifier is here because it is what you actually use: it is the string in the
`Claude-Session` trailer, so a row can be taken straight to
`git log --grep=<id>` and turned into the commits that session made, without
opening `metadata.md` first. `metadata.md` stays authoritative; this is a copy for
reach.

`id not recorded` on the Phase 11A bundle means exactly that, and is not a claim
that the identifier is unrecoverable. That bundle predates the trailer convention
and has never been searched for. Asserting unrecoverability without naming the
searches that came back empty is finding `0027`.

---

## State key

| | |
|---|---|
| `unclaimed` | No AI session owns it. The prompt is written and waiting. |
| `owned` | An AI session owns it — `Claude` or `Copilot`, with when ownership began. `metadata.md` carries the identifier and the environment it ran in. |
| `handoff` | The work is passing between sessions. Covers the bundle being handed over **and** a continuation prepared by a running session, until it is owned. Each handover leaves its own `handoff-<stamp>.md`. |
| `closed` | Complete. `final-summary.md` lists every commit hash and revision the session contributed. |
| `withdrawn` | The owner pivoted, or chose to leave findings unresolved. `final-summary.md` is required here too, and records what the work reached and why it stopped. |

Full definitions, the transitions and what each state requires:
[`docs/legend.md`](../legend.md).

## Session Bundles

| Bundle | State | Owner and when | Findings | Notes |
|---|---|---|---|---|
| [`restore-apps-outstanding-20260903-000000`](restore-apps-outstanding-20260903-000000/) | `owned` | Claude · `session_016EbjB7M527qEFqZFzpv2C9`, since 2026-09-03 | [4](restore-apps-outstanding-20260903-000000/findings-manifest.md) | Eight parked items from Revisions 143–155, then `restore-apps.md`. Produced finding `0001`; assigned `0027` and `0028` on 2026-09-03. Revisions 160–166, 168–169, 172 |
| [`phase-11b-hydrate-and-bookends-20260903-141500`](phase-11b-hydrate-and-bookends-20260903-141500/) | `closed` | Claude · `session_019yzcjm2QneJ5ymVEQDi1bu`, to 2026-09-03 | [2](phase-11b-hydrate-and-bookends-20260903-141500/findings-manifest.md) | Revisions 131, 142–159, 167, 170, 171, 175, 176. **The whole session** — absorbed its two earlier briefs. Five unresolved findings were unowned at closing; see `final-summary.md` |
| [`run-index-design-20260901-000000`](run-index-design-20260901-000000/) | `handoff` | last Claude · `01KcZvrKMgfenhrT9DvxW9Jk`, to 2026-09-02 | [14](run-index-design-20260901-000000/findings-manifest.md) | Items 1–3 done, **resume at item 4**. Two handoffs; the later one is where to start |
| [`restore-git-phase-11a-20260901-155433`](restore-git-phase-11a-20260901-155433/) | `closed` | Claude, to 2026-09-01 · id not recorded | — | Phase 11A, driven interactively. No prompt survives; the transcript is the record |

**`-000000` in a stamp means the start time was not recoverable.** Five bundles
were converted from loose files in Revision 162 and only the Phase 11A transcript
carried a usable timestamp; three of those five remain. A bundle created from now
on stamps the moment it was made.

**One session, one bundle.** `restore-repos-refactor-20260902-000000` and
`restore-repos-clone-plan-20260902-000000` were removed on 2026-09-03. They were
two briefs of the conversation that also produced
`phase-11b-hydrate-and-bookends-20260903-141500` — one session throughout,
`session_019yzcjm2QneJ5ymVEQDi1bu` — and splitting one session across three
bundles put findings under owners that had, by their own `closed` state, stopped.
Their documents were not discarded: the Phase 11B plan, both prompts, both
metadata records, both final summaries and the handoff are in that bundle under
`prompt-`, `metadata-` and `brief-summary-` names. Revision 162 created them from
loose files; this removes the split it introduced.

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

`APPLY-MANIFEST.md` also names the two removed bundles in eight places, by the
paths they had when those revisions were written. Those citations are correct as
history and are not repaired, for the same reason the three below are not.

`APPLY-MANIFEST.md` cites three of these files by the paths they had before the
conversion — `next-session-prompt-run-index.md`, `run-index-2026-09-01.md` and
`restore-git-2026-09-01.txt`. It quotes paths as they were and is never
retro-edited, so those citations name files that have moved. Revision 162 carries
the full old-to-new mapping for exactly that reason.
