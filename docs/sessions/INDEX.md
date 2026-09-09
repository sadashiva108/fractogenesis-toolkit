# Sessions — index

Every session is a bundle: `docs/sessions/<title>-<stamp>/`, holding a
`metadata.json` and `prompt.md` always, `findings-manifest.md` once it owns a
finding, one `handoff-<stamp>.md` per handover, and `final-summary.md` when it
reaches `closed` or `withdrawn`.

The shape and what each state owes are in
`.github/session-management-instructions.md` section 5. **What the states mean is in [`docs/legend.md`](../legend.md)**,
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

A session creates its own bundle. Its state is **derived from the findings
bundles it owns**; the three terminal states differ by what happened to them.

| State | When | Its bundles |
|---|---|---|
| `available` | Created or cloned, owning no findings bundle yet | none |
| `active` | Owns at least one bundle that is not `resolved` or `withdrawn` | live |
| `closed` | Every bundle it owns is terminal — `resolved`, `superseded` or `withdrawn` | terminal, or released to `unclaimed` and waiting to be assigned |
| `handoff` | Its qualifying bundles were passed to a successor | carried across at whatever status they hold |
| `withdrawn` | Every bundle it owns is `withdrawn` | `withdrawn`, or `superseded` where a later bundle replaces them |

`final-summary.md` records which disposal happened, by name, for every bundle the
session owned. **A session may not end leaving a bundle owned by a session that
has stopped** — a closed session's unfinished readings become `unclaimed`, which
is what happened to `phase-11b-hydrate-and-bookends-20260903-141500`'s five on
2026-09-06. Full definitions and what each state requires:
[`docs/legend.md`](../legend.md).

## Session Bundles

| Bundle | State | Owner and when | Bundles | Findings | Notes |
|---|---|---|---:|---:|---|
| [`typed-bundles-architecture-20260908-204724`](typed-bundles-architecture-20260908-204724/) | `active` | Claude · `session_01QvZrvKpoKwCmyLNjzXzCdQ`, since 2026-09-09 | [6](typed-bundles-architecture-20260908-204724/findings-manifest.md) | 51 | **The architecture session.** Assigned `0037`, `0038`, `0045`, `0047`, `0048` on 2026-09-09 from the Revision 234 allocation. Carries `docs/architecture/typed-bundles-and-work.md` as a draft. **`0039` transferred in at Revision 248**, standing `transferred` until this session's first write to it as owner. **The Owner column was empty until Revision 239** — the bundle was created ahead of the session and the session filled its own row on its first write. Revisions 237, 239 |
| [`assurance-coverage-20260908-204724`](assurance-coverage-20260908-204724/) | `active` | Claude · `session_01Wd7US5C5Msr594vNidboLn`, since 2026-09-09 | [9](assurance-coverage-20260908-204724/findings-manifest.md) | 35 | **The assurance session.** Assigned `0040`, `0041`, `0042`, `0044`, `0046`, `0049` on 2026-09-09 from the Revision 234 allocation; `0051` recorded and owned at the owner's direction; **`0050` and `0053` assigned 2026-09-09** after being recorded here unowned. All read and decided on assignment: `0040` and `0044` `answered`, the rest `analyzing`. Its own findings — `0042` F5, `0041` F6, `0049` F5, `0050` F5, `0053` F3 — each came from using an instrument rather than reading it. Carries the first target-platform run. Revisions 237, 251, 253, 254, 255 |
| [`allocation-and-inquiry-design-20260906-233205`](allocation-and-inquiry-design-20260906-233205/) | `available` | Claude · `session_015FpYVBF7dDoDrHfKDkq8fn`, since 2026-09-06 | — | — | Designing one architecture from the owner's two briefs — allocating `unclaimed` bundles to sessions, and ordering what is put to the owner. **Owns nothing, and `available` understates it — see `0045`.** Wrote `docs/architecture/allocation-and-inquiry.md`, ran the allocator (R214) and corrected that record from the run; contributed F6, the draft review and a live instance of F4 to `0043`; took `0039` D5; recorded `0044` and `0045`, neither owned. Revisions 211, 214, 218 |
| [`session-management-re-evaluation-20260906-110105`](session-management-re-evaluation-20260906-110105/) | `handoff` | Claude · `session_01FhFbEgG4wmrtJqUCcryNVQ`, since 2026-09-06 | [2](session-management-re-evaluation-20260906-110105/findings-manifest.md) | 10 | Successor to `restore-apps-outstanding-20260903-000000`, per its `handoff-20260906-003935.md`. Assigned `0036`–`0041` on 2026-09-06 and read them on assignment, so all six are `analyzing`. `0042` is in the same tree and is **not** owned here. **`0039` transferred out at Revision 248** — this session stands `handoff` with no successor and could not close the deciding on it |
| [`pre-image-capture-conformance-20260903-194532`](pre-image-capture-conformance-20260903-194532/) | `active` | Claude · `session_01PcgHu9kz9Hm5RatLQuFR8H`, since 2026-09-03 | [8](pre-image-capture-conformance-20260903-194532/findings-manifest.md) | 20 | Four pre-image runbook findings reassigned from `run-index-design-20260901-000000` on 2026-09-03. A reading session: the report is the output, and nothing outside this bundle is written |
| [`restore-apps-outstanding-20260903-000000`](restore-apps-outstanding-20260903-000000/) | `closed` | Claude · `session_016EbjB7M527qEFqZFzpv2C9`, to 2026-09-06 | [3](restore-apps-outstanding-20260903-000000/findings-manifest.md) | 21 | Eight parked items from Revisions 143–155, then `restore-apps.md`. Produced `0001` and `0029`; assigned `0027` and `0028` on 2026-09-03, both resolved 2026-09-04, all three superseded 2026-09-06. Rebuilt the status model and the file schemas, Revisions 198–204. **`0001` released to `unclaimed` on closing, undecided** — see `final-summary.md`. Revisions 160–166, 168–169, 172, 174, 177–182, 198–204 |
| [`phase-11b-hydrate-and-bookends-20260903-141500`](phase-11b-hydrate-and-bookends-20260903-141500/) | `closed` | Claude · `session_019yzcjm2QneJ5ymVEQDi1bu`, to 2026-09-03 | [2](phase-11b-hydrate-and-bookends-20260903-141500/findings-manifest.md) | 2 | Revisions 131, 142–159, 167, 170, 171, 175, 176. **The whole session** — absorbed its two earlier briefs. Five unresolved findings were unowned at closing; see `final-summary.md` |
| [`run-index-design-20260901-000000`](run-index-design-20260901-000000/) | `active` | Claude · `session_01KcZvrKMgfenhrT9DvxW9Jk`, since 2026-09-04 | [11](run-index-design-20260901-000000/findings-manifest.md) | 10 | Resumed 2026-09-04 by the same session that held it to 2026-09-02; was `handoff`, which it never satisfied — no successor exists and nothing was transferred. Items 1–3 done, **resume at item 4**. Two handoffs; the later one is where to start. Four pre-image findings reassigned to `pre-image-capture-conformance-20260903-194532` on 2026-09-03. Also holds `0030` finding 3, which is not a bundle it owns |
| [`restore-git-phase-11a-20260901-155433`](restore-git-phase-11a-20260901-155433/) | `closed` | Claude, to 2026-09-01 · id not recorded | — | — | Phase 11A, driven interactively. No prompt survives; the transcript is the record |

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
