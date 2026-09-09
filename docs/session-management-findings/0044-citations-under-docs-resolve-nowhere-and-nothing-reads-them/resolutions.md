# Resolutions — citations under `docs/` resolve nowhere, and nothing reads them

**Bundle:** `0044-citations-under-docs-resolve-nowhere-and-nothing-reads-them`  
**Session:** `assurance-coverage-20260908-204724`  
**Resolved:** 2026-09-09

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F1 | D1 | Eight rows in `docs/cross-cutting-findings/INDEX.md` — bundles 0003, 0005, 0006, 0009, 0012, 0018, 0026 and 0030 — had `../../sessions/` in the Session cell changed to `../sessions/`. Each target was resolved against the tree after the edit; `grep -c` for the broken spelling in that file returns 0 | 251 | — |
| F2 | D2 | `docs/cross-cutting-findings/INDEX.md` line 15 and `docs/sessions/INDEX.md` line 9 stopped citing `.github/copilot-instructions.md` sections 4c and 4d, and now cite `.github/session-management-instructions.md` sections 2, 3 and 5, which is where Revision 191 put that content | 251 | — |

**`Commit` is `—` on both rows because the commit does not exist yet.** The
revision is taken at apply time and the owner commits; a hash written while
composing would be a guess. Section 11 admits the two fields separately for
exactly this reason.
