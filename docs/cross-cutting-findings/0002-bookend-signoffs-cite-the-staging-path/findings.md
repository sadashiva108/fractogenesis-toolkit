# Bookend sign-offs cite the `.incomplete` staging path

**Found:** 2026-09-03, while renaming `boundaries/` to `bookends/` — 20 of the
sign-offs on the volume named the category, and every one of them named it
through a path that never existed after the run finished.
**Severity:** cosmetic per file, but it is the same defect Revision 150 fixed in
`bin/restore-repos.sh`, in four more scripts.
**Owner:** the repository owner. Three of the four producers are shared with the
run-index session.

## What the sign-offs say

    | Plan | `…/reimaged-system/bookends/runs/.restore-repos-exit-20260903-005335.incomplete` |

`artifact_run_begin` stages a run at `runs/.<id>.incomplete` and
`artifact_run_finalize` promotes it to `runs/<id>`. These recorders call
`signoff_finalize` with `$ARTIFACT_RUN_DIR` **before** the promotion, so the
path written into the sign-off is the staging directory — which does not exist
by the time anyone reads it.

    bin/record-restore-exit.sh:1031   signoff_finalize "" "$CHECK_FILE"
    bin/record-enrollment.sh:534      signoff_finalize "Phase 8" "$BOOKEND_FILE"
    bin/record-reimaged-system.sh:656 signoff_finalize "Phase 9" "$BOOKEND_FILE"

`bin/record-restore-prereqs.sh` sets `CHECK_FILE` the same way and should be
checked with them.

## The fix is already written down

Revision 150 hit this in `bin/restore-repos.sh` and settled the rule:
`artifact_run_begin` sets `ARTIFACT_RUN_FINAL_DIR` at staging time, so anything
quoted for a reader uses that rather than `ARTIFACT_RUN_DIR`. A reader who
copies a path out of a record must get one that exists.

## Fixed — Revision 159

All four call sites take `ARTIFACT_RUN_FINAL_DIR`, which `artifact_run_begin`
sets at staging time, instead of `ARTIFACT_RUN_DIR`:

    bin/record-restore-exit.sh        signoff_finalize "" "$ARTIFACT_RUN_FINAL_DIR/bookend.md"
    bin/record-enrollment.sh          signoff_finalize "Phase 8" "$ARTIFACT_RUN_FINAL_DIR/bookend.md"
    bin/record-reimaged-system.sh     signoff_finalize "Phase 9" "$ARTIFACT_RUN_FINAL_DIR/bookend.md"
    bin/record-reimaged-system.sh     signoff_finalize "Phase 9" "$ARTIFACT_RUN_FINAL_DIR/record.md"

`bin/record-restore-prereqs.sh` turned out not to call `signoff_finalize` at all,
so the original note over-counted at four producers; it is three files.

The fourth was found after this note was written: the capture path in
`record-reimaged-system.sh` had the same defect, and Revision 158 gave it a
sign-off of its own, which would have inherited it.

Verified by running the capture against a scratch artifact root — the `Plan`
field names a path that exists, with no `.incomplete` segment in it.

## The 20 sign-offs already on the volume keep the stale path

They are records of runs that happened. The run id inside each is correct and the
directory it names was real while the run was in flight; only the segment naming
it is wrong. Rewriting them would edit evidence to match code written afterwards,
which is a worse trade than a path that is merely historical.
