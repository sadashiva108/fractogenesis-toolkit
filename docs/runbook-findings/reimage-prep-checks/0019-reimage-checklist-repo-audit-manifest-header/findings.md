# Phase 6B records FAIL against a correct repository-audit manifest

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, while checking what
reads `repo-audit-reports/`.
**Severity:** a Phase 6B gate reports the opposite of the truth.
**Origin:** a Revision 120 loose end, not a new regression.
**Status: CLOSED** by Revision 129, 2026-09-01, same session. Kept for the
reasoning; the fix and its validation are in `APPLY-MANIFEST.md`.

## What is wrong

`bin/reimage-checklist.sh` line 660:

```bash
if [[ -f "$REPO_AUDIT_MANIFEST" ]] && grep -q '^# Repository Audit Runs$' "$REPO_AUDIT_MANIFEST" 2>/dev/null; then
  record_check PASS "Repository audit manifest" "$REPO_AUDIT_MANIFEST"
elif [[ -f "$REPO_AUDIT_MANIFEST" ]]; then
  record_check FAIL "Repository audit manifest" "Existing MANIFEST.md is not the canonical append-only run index"
```

Revision 120 moved the `# Repository Audit Runs` heading into the renamed domain
manifest `repo-audit-index.md` (now headed `# Repository Audit Index`) and let
`reindex-artifact-runs.sh` build the standard `MANIFEST.md` beside it, headed
`# Artifact Runs`.

Verified on the volume:

- `repo-audit-reports/MANIFEST.md` → `# Artifact Runs`
- `repo-audit-reports/repo-audit-index.md` → `# Repository Audit Index`

So the check falls to the `elif`, and Phase 6B records
`FAIL — Existing MANIFEST.md is not the canonical append-only run index`
against a manifest that is exactly canonical.

The neighbouring `resolve_latest_repo_audit_run()` (line 403) **was** updated in
Revision 120 — it calls `artifact_run_official "$audit_root" "pre-image"`
correctly. Only the header sentinel was missed.

## Fix — as applied in Revision 129

Not a corrected literal. `.internal/artifact-runs.sh` already exports
`ARTIFACT_RUNS_MANIFEST_HEADING`, `_artifact_runs_ensure_manifest` tests against
it, and `bin/reimage-checklist.sh` sources that library at line 102 before
hand-writing the same string at line 660. The literal was deleted and the
library's constant used in its place, so a future rename moves both callers or
neither.

The `FAIL` branch keeps its job — `loose-secrets-reports/` and
`size-audit-reports/` still carry their own domain headings and would correctly
fail this test — and now names the heading it expected and gives the Revision 120
treatment as a command instead of leaving it to be reconstructed.

The original one-line framing below is left as written.

Grep for `^# Artifact Runs$` instead. Consider whether the sentinel belongs in
`.internal/artifact-runs.sh` as a named constant, since
`_artifact_runs_ensure_manifest` already tests the same string to decide whether
a manifest is an artifact-runs index — two copies of one sentinel is what let
this drift.

Not owned by the Restore Repositories Refactor session; `bin/reimage-checklist.sh`
is a Phase 6B reader and is not contended.
