# Resolutions — the findings-and-sessions architecture disagrees with itself

**Bundle:** `0037-findings-architecture-conformance`  
**Session:** `typed-bundles-architecture-20260908-204724`  
**Resolved:** 2026-09-09

Each row below was resolved once in `0027` at commit `88aed77`, regressed by
`1c48deb`, and holds again against the files that replaced the one that commit
split. `Resolved by` cites D3, which is the decision that reads them that way.

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F1 | D3 | The contradiction has no surface left: `copilot-instructions.md` carries no §4b or §4c, and `.github/session-management-instructions.md` §7 states *"Every change of any kind takes a revision"* with `docs/INDEX.md` agreeing | — | `1c48deb` |
| F3 | D3 | All seven rows of `docs/sessions/INDEX.md` agree with the manifests they link to, verified row by row 2026-09-09 | — | — |
| F4 | D3 | *"Currently empty"* is gone from `docs/INDEX.md`; the directory table is generated against what exists | — | `88aed77` |
| F6 | D3 | There is one session-state diagram, in `docs/legend.md`; `docs/architecture/findings-and-sessions.md` no longer draws one | — | `88aed77` |
| F7 | D3 | `.github/session-management-instructions.md` §5 requires any `not recoverable` to name the searches that came back empty | — | `1c48deb` |

**`Revision` is `—` on every row and that is not a gap.** These were closed by
commits that predate the entries naming them, and `APPLY-MANIFEST.md` is never
retro-edited to claim otherwise. The commit is the reference that cannot drift.

**F2 and F5 are `decided` and not resolved here.** Both need a write to
`.github/session-management-instructions.md`, which §6 gates on the finding being
`decided` — so the carrying out is its own revision, and §9b's order is kept:
carry out, write the row, move the status.
