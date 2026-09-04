# Resolutions — `.internal/restore/` is empty, and is not tracked

**Bundle:** `0012-internal-restore-directory-empty` · **Status:** `resolved`
**Resolved:** 2026-09-04, session `session_01KcZvrKMgfenhrT9DvxW9Jk`.

| Finding | Resolved by | Commit |
|---|---|---|
| `.internal/restore/` is empty, and is not tracked | `APPLY-MANIFEST.md` Revision 193 — D1's sentence rewrite in `.internal/artifact-runs.sh` | pending; the owner commits |

## What was done

`.internal/artifact-runs.sh`'s classification note claimed its callers span
`restore/`, `home/` and the artifact-root reporters. Counted before rewriting:
**29 files source it, none under `.internal/restore/`** — twenty-three in `bin/`,
plus `.internal/git/capture-repo-audit.sh`, two under `.internal/home/`,
`.internal/sign-offs.sh` and `.internal/artifact-run-cli.sh`. The note now names
those, and keeps the point it was making: no one domain owns the file, which is
why it sits at the `.internal/` root.

## What was deliberately not done

**No `.gitkeep`.** Adding one would create the tracked empty directory this
finding was originally written to complain about, on the strength of a claim that
turned out to be the error.

**The empty directory is not removed by this change**, because a patch cannot
remove it — git never tracked it, so there is no diff. `rm -d .internal/restore`
on each checkout that has one, per D2. This file is the record that its absence
is intended.

**`reimaging-scripts-guide.md`'s tree is untouched.** D3 sizes it and sends it to
its own bundle: read against the current tree it shows a nested
`<repo-root>/<repo-root>/`, a `workflows/mac/reimage/scripts/` hierarchy that
does not exist, and ten of sixteen `.internal/` entries missing. That is a
rewrite, not a stale line, and folding it into a trivial bundle would have hidden
it.

## Verification

`bash -n .internal/artifact-runs.sh` clean; script portability 0 WARN / 0 FAIL;
doc paths 0 MISSING / 0 ANCHOR BROKEN. Comment-only change to a sourced library —
no behaviour to test, and the count it now asserts was measured rather than
estimated.

**Linux, Bash 5.x.** `/bin/bash -n` under macOS stock Bash 3.2 is owed, as on
every revision this session has carried.
