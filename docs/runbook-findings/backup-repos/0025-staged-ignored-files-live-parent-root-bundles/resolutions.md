# Resolutions — `staged-ignored-files/live/` holds two bundles no lookup can reach

**Bundle:** `0025-staged-ignored-files-live-parent-root-bundles` · **Status:** `resolved`
**Recorded:** 2026-09-03, session `session_01PcgHu9kz9Hm5RatLQuFR8H`.

`findings.md` asked for one thing — *record the answer here rather than
re-deriving it* — and proposed no code change. The answer is recorded in
`decisions.md` and nothing was changed anywhere.

| Finding | Resolved by | What was done |
|---|---|---|
| `staged-ignored-files/live/` holds two bundles no lookup can reach | `decisions.md` D1–D4 | Both directories opened on the volume and classified; decided that nothing in either is restored, that the labelling is correct by design, and that no producer change is owed |

## The count, for whoever asks it next

`live/` holds **24 directories: 22 repository bundles and 2 scan roots**
(`IdeaProjects`, `documentation`), plus 11 run-metadata files. Anyone counting
subdirectories to answer *how many repositories kept ignored files* wants 22.
`findings.md` said 26 and 24; its dated correction records that.

## Changed on the volume

Nothing. No evidence write was made or requested for this bundle.

## Validation

Documentation lint: 0 MISSING, 0 ANCHOR BROKEN. Runbook structure and script
portability unchanged — no runbook and no script was touched. Composed in a copy
outside the owner's checkout, per `0028`; manifest revision taken at apply time
with `./bin/check-manifest-revision.sh`.
