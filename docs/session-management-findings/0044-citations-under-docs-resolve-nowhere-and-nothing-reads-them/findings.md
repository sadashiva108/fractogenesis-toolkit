# Citations under `docs/` resolve nowhere, and nothing reads them

**Recorded:** 2026-09-06, while reading the tree to design the allocation architecture.  
**Session:** `allocation-and-inquiry-design-20260906-233205` (`session_015FpYVBF7dDoDrHfKDkq8fn`)  
**Severity:** low each, and F1 is the first demonstrated instance of `0036` — a broken link inside `docs/` that every validator passes.  
**Felt at:** `docs/cross-cutting-findings/INDEX.md` rows 0003, 0005, 0006 and 0030; line 15 of the same file; `docs/sessions/INDEX.md` line 8  
**Scope:** the two index files. No script changes.  
**Relates to:** `0036` — this is what its unverified region actually contains; `0036` is the check that cannot see these, this is the defect it cannot see

**Read:**

- `docs/cross-cutting-findings/INDEX.md` and `docs/sessions/INDEX.md`
- `bin/verify-doc-paths.sh`, and its `--all` run over 778 paths and 1108 anchors
- `.github/session-management-instructions.md` sections 2 and 3

Recorded `unclaimed`. It is not owned, and no session should open it until the
owner assigns it.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | Four session citations in one index point one directory too high and resolve to nothing | `resolved` |
| F2 | Two indexes cite an instruction file section that moved when the set was split | `resolved` |

## F1 — four citations resolve one directory too high

`docs/cross-cutting-findings/INDEX.md` cites session bundles two ways. Rows
0027, 0028 and 0035 use `../sessions/<bundle>/`, which resolves to
`docs/sessions/<bundle>/` and is correct. Rows 0003, 0005, 0006 and 0030 use
`../../sessions/<bundle>/`, which resolves to `sessions/<bundle>/` at the
repository root, where nothing exists.

Tested 2026-09-06 by resolving each target against the tree: three distinct
paths missing, four rows carrying them.

**The majority form is the broken one**, which is why reading the file teaches
the wrong pattern — and is a live instance of the instruction set's own warning
not to infer a convention from the file being edited.

`bin/verify-doc-paths.sh --all` reports 0 MISSING and 0 ANCHOR BROKEN over this
tree. It prunes `docs/` unconditionally, which is `0036` finding 1. **This is
the first recorded instance of something actually broken inside the region that
check cannot see.** The value of `0036` stops being hypothetical here.

## F2 — two indexes cite a file section that moved

`docs/cross-cutting-findings/INDEX.md` line 15 says the bundle layout and the
numbering rule are defined in `.github/copilot-instructions.md` section 4c.
`docs/sessions/INDEX.md` line 8 says the session shape and what each state owes
are in section 4d of the same file.

Revision 191 split that file into `.github/session-management-instructions.md`
and `.github/toolkit-instructions.md`. The bundle layout and numbering are now
section 3 of the session management set; the session shape is section 5. Neither
citation names a section that exists.

Both are `.github/copilot-instructions.md`, which still exists as a pointer, so
`verify-doc-paths.sh` sees a resolving path and a reader following it finds no
section 4c. **A citation to a file that exists and a section that does not is
worse than a broken link**, because the check passes and the reader concludes
the rule was withdrawn.
