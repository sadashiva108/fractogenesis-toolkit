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

The bundle layout and the numbering rule are defined once, in
`.github/copilot-instructions.md` section 4c.

Each bundle also carries a `STATUS-<status>` tag file so a directory listing
answers the status without opening anything. The row here is authoritative; a
tag that disagrees with it is a bug in whoever moved the bundle last.

## Status key

| | |
|---|---|
| `unresolved` | Recorded. No decisions yet. **Any session may add, correct or remove findings here.** |
| `in progress` | The owner is reviewing and deciding. Produces `decisions.md`. **Only the owner writes from here on.** |
| `resolving` | Every finding decided; the decided work is being carried out. Produces `resolutions.md`. |
| `resolved` | Every finding has a resolution recorded. |
| `superseded` | A later bundle replaces this reading — including a bundle overtaken while `in progress`. The row names which; the replacement carries `Relates to`. |

A bundle advances with its first finding and reaches `resolved` only with its
last. The owner may override any rule; a revision carrying an overridden change
says so. Full definitions, the transitions and the write rules:
[`docs/legend.md`](../legend.md).

## Bundles

| # | Bundle | Subject | Findings | Status | Session | Notes |
|---:|---|---|---:|---|---|---|
| 0002 | [0002-bookend-signoffs-cite-the-staging-path](0002-bookend-signoffs-cite-the-staging-path/) | Bookend sign-offs cite the `.incomplete` staging path | 1 | `resolved` | — | closed by Revision 159 |
| 0003 | [0003-boundary-recorder-coverage-is-uneven](0003-boundary-recorder-coverage-is-uneven/) | The boundary-recorder family is applied unevenly across the phases it covers | 1 | `resolved` | [`run-index-design-20260901-000000`](../../sessions/run-index-design-20260901-000000/) | closed by Revisions 136 and 137 |
| 0004 | [0004-boundary-runs-name-their-record-a-checklist](0004-boundary-runs-name-their-record-a-checklist/) | Boundary runs call their record a `checklist`, and it is not one | 1 | `resolved` | — | closed by Revisions 156 through 159 |
| 0005 | [0005-boundary-runs-recorded-long-after-their-phase](0005-boundary-runs-recorded-long-after-their-phase/) | Four boundary runs are dated the day the recorder was extended, not the day the phase ran | 1 | `unresolved` | [`run-index-design-20260901-000000`](../../sessions/run-index-design-20260901-000000/) | — |
| 0006 | [0006-caller-environment-precedence-covers-only-listed-keys](0006-caller-environment-precedence-covers-only-listed-keys/) | Caller-environment precedence holds only for the keys `artifact-config.sh` lists | 1 | `resolved` | [`phase-11b-hydrate-and-bookends-20260903-141500`](../../sessions/phase-11b-hydrate-and-bookends-20260903-141500/) | closed by Revision 136 |
| 0009 | [0009-dated-artifacts-cite-run-ids-a-rename-breaks](0009-dated-artifacts-cite-run-ids-a-rename-breaks/) | Renaming a lineage silently breaks every citation already written | 1 | `unresolved` | [`run-index-design-20260901-000000`](../../sessions/run-index-design-20260901-000000/) | — |
| 0010 | [0010-docker-capture-empty-section-passes-unnoticed](0010-docker-capture-empty-section-passes-unnoticed/) | An empty Docker section captures cleanly and nothing downstream notices | 1 | `unresolved` | — | — |
| 0012 | [0012-internal-restore-directory-empty](0012-internal-restore-directory-empty/) | `.internal/restore/` is tracked and empty | 1 | `unresolved` | [`run-index-design-20260901-000000`](../../sessions/run-index-design-20260901-000000/) | — |
| 0015 | [0015-portability-lint-cannot-see-heredoc-context](0015-portability-lint-cannot-see-heredoc-context/) | The portability lint cannot see a defect that needs heredoc context | 1 | `unresolved` | [`phase-11b-hydrate-and-bookends-20260903-141500`](../../sessions/phase-11b-hydrate-and-bookends-20260903-141500/) | — |
| 0018 | [0018-recorder-usage-strings-understate-supported-runbooks](0018-recorder-usage-strings-understate-supported-runbooks/) | Two recorders still tell you your own phase is unsupported | 1 | `resolved` | [`run-index-design-20260901-000000`](../../sessions/run-index-design-20260901-000000/) | closed by Revision 136 |
| 0026 | [0026-verify-doc-paths-counts-gitignored-docs](0026-verify-doc-paths-counts-gitignored-docs/) | `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold | 1 | `resolved` | [`run-index-design-20260901-000000`](../../sessions/run-index-design-20260901-000000/) | closed by Revision 130 |
| 0027 | [0027-findings-architecture-conformance](0027-findings-architecture-conformance/) | The findings-and-sessions architecture disagrees with itself and with the tree | 7 | `unresolved` | [`restore-apps-outstanding-20260903-000000`](../sessions/restore-apps-outstanding-20260903-000000/) | 1 is high — §4b and §4c contradict each other on whether a bundle takes a manifest revision |
| 0028 | [0028-sessions-write-into-the-tree-the-owner-commits-from](0028-sessions-write-into-the-tree-the-owner-commits-from/) | Sessions compose their changes in the tree the owner commits from | 6 | `unresolved` | [`restore-apps-outstanding-20260903-000000`](../sessions/restore-apps-outstanding-20260903-000000/) | 1 and 2 are high — two sessions' work cannot be committed separately, and a revision's baselines are measured on the other session's tree |
