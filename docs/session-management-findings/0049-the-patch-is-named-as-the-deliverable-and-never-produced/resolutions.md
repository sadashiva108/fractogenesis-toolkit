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
| F3 | D2 | The same bullet added *"`git add -N` is not optional and its absence is silent"*, with the 9-of-14 measurement and the instruction to read the patch's file list against the change set | 232 | `d0e6d7d` |

**F1 and F4 are `decided` and not resolved.** F4's remainder is `0050`; F1 has no
resolution of its own and closes with it. Both rows are absent from this table on
purpose — `0041` F5 records that a `resolved` status with nothing behind it is
the state nobody can check, and the inverse, a row written ahead of the work, is
the same defect facing the other way.
