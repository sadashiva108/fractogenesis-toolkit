# Cross-cutting findings

Finding bundles that are not specific to one runbook — shared helpers under
`.internal/`, the run-index and sign-off machinery, the repo-wide lints, the
instruction set itself.

A finding felt in one runbook belongs under `docs/runbook-findings/<runbook>/`.
The test is where the ramifications are **functionally** impactful, not where
they are incidentally impactful because a shared script needs refactoring:
scripts and artifacts are covered by their owning runbook. A bundle lands here
only when the change is broad and agnostic to any particular runbook, and may
affect more than one.

**The bundle layout, the status vocabulary and the numbering rule are defined
once**, in `.github/copilot-instructions.md` section 4c. This file carries the
rows and nothing else.

Each bundle also carries a `STATUS-<status>` tag file so a directory listing
answers the status without opening anything. The row here is authoritative; a
tag that disagrees with it is a bug in whoever moved the bundle last.

## Bundles

| # | Bundle | Subject | Findings | Status | Session | Notes |
|---:|---|---|---:|---|---|---|
| 0002 | [0002-bookend-signoffs-cite-the-staging-path](0002-bookend-signoffs-cite-the-staging-path/) | Bookend sign-offs cite the `.incomplete` staging path | 1 | `resolved` | — | closed by Revision 159 |
| 0003 | [0003-boundary-recorder-coverage-is-uneven](0003-boundary-recorder-coverage-is-uneven/) | The boundary-recorder family is applied unevenly across the phases it covers | 1 | `resolved` | [`run-index-design-20260901-000000`](../../sessions/run-index-design-20260901-000000/) | closed by Revisions 136 and 137 |
| 0004 | [0004-boundary-runs-name-their-record-a-checklist](0004-boundary-runs-name-their-record-a-checklist/) | Boundary runs call their record a `checklist`, and it is not one | 1 | `resolved` | — | closed by Revisions 156 through 159 |
| 0005 | [0005-boundary-runs-recorded-long-after-their-phase](0005-boundary-runs-recorded-long-after-their-phase/) | Four boundary runs are dated the day the recorder was extended, not the day the phase ran | 1 | `unresolved` | [`run-index-design-20260901-000000`](../../sessions/run-index-design-20260901-000000/) | — |
| 0006 | [0006-caller-environment-precedence-covers-only-listed-keys](0006-caller-environment-precedence-covers-only-listed-keys/) | Caller-environment precedence holds only for the keys `artifact-config.sh` lists | 1 | `resolved` | [`restore-repos-refactor-20260902-000000`](../../sessions/restore-repos-refactor-20260902-000000/) | closed by Revision 136 |
| 0009 | [0009-dated-artifacts-cite-run-ids-a-rename-breaks](0009-dated-artifacts-cite-run-ids-a-rename-breaks/) | Renaming a lineage silently breaks every citation already written | 1 | `unresolved` | [`run-index-design-20260901-000000`](../../sessions/run-index-design-20260901-000000/) | — |
| 0010 | [0010-docker-capture-empty-section-passes-unnoticed](0010-docker-capture-empty-section-passes-unnoticed/) | An empty Docker section captures cleanly and nothing downstream notices | 1 | `unresolved` | — | — |
| 0012 | [0012-internal-restore-directory-empty](0012-internal-restore-directory-empty/) | `.internal/restore/` is tracked and empty | 1 | `unresolved` | [`run-index-design-20260901-000000`](../../sessions/run-index-design-20260901-000000/) | — |
| 0015 | [0015-portability-lint-cannot-see-heredoc-context](0015-portability-lint-cannot-see-heredoc-context/) | The portability lint cannot see a defect that needs heredoc context | 1 | `unresolved` | [`restore-repos-clone-plan-20260902-000000`](../../sessions/restore-repos-clone-plan-20260902-000000/) | — |
| 0018 | [0018-recorder-usage-strings-understate-supported-runbooks](0018-recorder-usage-strings-understate-supported-runbooks/) | Two recorders still tell you your own phase is unsupported | 1 | `resolved` | [`run-index-design-20260901-000000`](../../sessions/run-index-design-20260901-000000/) | closed by Revision 136 |
| 0026 | [0026-verify-doc-paths-counts-gitignored-docs](0026-verify-doc-paths-counts-gitignored-docs/) | `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold | 1 | `resolved` | [`run-index-design-20260901-000000`](../../sessions/run-index-design-20260901-000000/) | closed by Revision 130 |
