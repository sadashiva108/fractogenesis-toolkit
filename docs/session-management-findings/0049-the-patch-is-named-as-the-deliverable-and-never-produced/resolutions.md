# Resolutions — the patch is named as the deliverable and never produced

**Bundle:** `0049-the-patch-is-named-as-the-deliverable-and-never-produced`  
**Session:** `assurance-coverage-20260908-204724`  
**Resolved:** 2026-09-09

Two findings were carried out before this bundle was assigned. The rows record
what closed them and where, which is the only thing that makes the status
checkable — `0041` F5.

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F2 | D1 | `.github/session-management-instructions.md` section 6 gained *"A patch is a file, and this is how it is made"*, naming `git add -N .`, `git diff > "$PATCH_DIR/<revision>-<slug>.patch"` and `$PATCH_DIR`; section 0 step 6 named the actor | 232 | `d0e6d7d` |
| F6 | D7, D8 | §0 step 6 rewritten: the ask names a delivered artifact and `do it` is retired; applying is a response, never an initiation; the checkout must be `git status --porcelain` empty **before** applying and the index empty after. The conformant prompt's four-phrase list is brought onto it. `0038` F1 and F4 are cited as the reason | 258 | — |
| F3 | D2 | The same bullet added *"`git add -N` is not optional and its absence is silent"*, with the 9-of-14 measurement and the instruction to read the patch's file list against the change set | 232 | `d0e6d7d` |

**F1, F4 and F5 are `decided` and not resolved.** F4's remainder is `0050`; F1 has no
resolution of its own and closes with it; F5's assertion is written into §0 step 6
by this revision but its finding stays `decided`, because D6's check has not been
run against a tree that violates it. Both rows are absent from this table on
purpose — `0041` F5 records that a `resolved` status with nothing behind it is
the state nobody can check, and the inverse, a row written ahead of the work, is
the same defect facing the other way.
