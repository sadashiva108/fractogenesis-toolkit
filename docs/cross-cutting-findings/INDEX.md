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
`.github/session-management-instructions.md` section 3, and the numbering rule in section 2.

Each bundle carries `metadata.json`, from which its status derives; until
Revision 222 a `STATUS-<status>` tag file meant a directory listing
answers the status without opening anything. The row here is authoritative; a
tag that disagrees with it is a bug in whoever moved the bundle last.

## Status key

A finding is `un-started`, `framing`, `decided`, `resolved`, `reopened` or
`withdrawn`. A **bundle** takes none of those words: its standing is `assigned`,
`analyzing`, `answered`, `revisited`, `retired`, `unclaimed`, `transferred` or
`superseded`. **A bundle's standing is derived from its findings** by the derivation table in
[`docs/legend.md`](../legend.md) — first row that matches wins.

| Bundle standing | When |
|---|---|
| `unclaimed` | No session owns it. Closed to every session until the owner assigns it |
| `assigned` | Every finding is `un-started`. Only the owning session can open one |
| `transferred` | Handed to a named session that has not read it yet. Ownership has moved; the reading has not been picked up |
| `analyzing` | Findings are in mixed statuses — the working state |
| `revisited` | At least one finding is `reopened` and every other is inert (`resolved` or `withdrawn`) |
| `answered` | Every finding is `resolved` or `withdrawn`, and at least one is `resolved` |
| `superseded` | Replaced whole by a later bundle, from any status. **The Status cell is a link to the replacement**, never the bare word |
| `retired` | Every finding is `withdrawn` |

The status is written in two places and they must agree: the row here, which is
authoritative, and derived from the findings in the bundle's `metadata.json`. Full
definitions, the transitions and the write rules: [`docs/legend.md`](../legend.md).

## Findings Bundles

| # | Bundle | Subject | Findings | Standing | Session | Notes |
|---:|---|---|---:|---|---|---|
| 0002 | [0002-bookend-signoffs-cite-the-staging-path](0002-bookend-signoffs-cite-the-staging-path/) | Bookend sign-offs cite the `.incomplete` staging path | 1 | `answered` | — | closed by Revision 159 |
| 0003 | [0003-boundary-recorder-coverage-is-uneven](0003-boundary-recorder-coverage-is-uneven/) | The boundary-recorder family is applied unevenly across the phases it covers | 1 | `answered` | [`run-index-design-20260901-000000`](../sessions/run-index-design-20260901-000000/) | closed by Revisions 136 and 137 |
| 0004 | [0004-boundary-runs-name-their-record-a-checklist](0004-boundary-runs-name-their-record-a-checklist/) | Boundary runs call their record a `checklist`, and it is not one | 1 | `answered` | — | closed by Revisions 156 through 159 |
| 0005 | [0005-boundary-runs-recorded-long-after-their-phase](0005-boundary-runs-recorded-long-after-their-phase/) | Four boundary runs are dated the day the recorder was extended, not the day the phase ran | 1 | `answered` | [`run-index-design-20260901-000000`](../sessions/run-index-design-20260901-000000/) | No re-run — it would widen the gap. `entry` and `initial` became first-wins, which is what catches a late bookend; five pointers move and `restore-repos-entry` is owed a pin |
| 0006 | [0006-caller-environment-precedence-covers-only-listed-keys](0006-caller-environment-precedence-covers-only-listed-keys/) | Caller-environment precedence holds only for the keys `artifact-config.sh` lists | 1 | `answered` | [`phase-11b-hydrate-and-bookends-20260903-141500`](../sessions/phase-11b-hydrate-and-bookends-20260903-141500/) | closed by Revision 136 |
| 0009 | [0009-dated-artifacts-cite-run-ids-a-rename-breaks](0009-dated-artifacts-cite-run-ids-a-rename-breaks/) | Renaming a lineage silently breaks every citation already written | 1 | [`superseded`](0030-renames-break-citations-and-which-may-be-repaired/) | [`run-index-design-20260901-000000`](../sessions/run-index-design-20260901-000000/) | Reading retained and unedited; replaced by `0030` |
| 0010 | [0010-docker-capture-empty-section-passes-unnoticed](0010-docker-capture-empty-section-passes-unnoticed/) | An empty Docker section captures cleanly and nothing downstream notices | 1 | `unclaimed` | — | — |
| 0012 | [0012-internal-restore-directory-empty](0012-internal-restore-directory-empty/) | `.internal/restore/` is empty, and is not tracked | 1 | `answered` | [`run-index-design-20260901-000000`](../sessions/run-index-design-20260901-000000/) | Reading corrected while `unresolved`: git never tracked it. One sentence in `artifact-runs.sh` was the repairable part; the guide's tree is sized for its own bundle |
| 0015 | [0015-portability-lint-cannot-see-heredoc-context](0015-portability-lint-cannot-see-heredoc-context/) | The portability lint cannot see a defect that needs heredoc context | 1 | `unclaimed` | — | — |
| 0018 | [0018-recorder-usage-strings-understate-supported-runbooks](0018-recorder-usage-strings-understate-supported-runbooks/) | Two recorders still tell you your own phase is unsupported | 1 | `answered` | [`run-index-design-20260901-000000`](../sessions/run-index-design-20260901-000000/) | closed by Revision 136 |
| 0026 | [0026-verify-doc-paths-counts-gitignored-docs](0026-verify-doc-paths-counts-gitignored-docs/) | `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold | 1 | [`superseded`](../session-management-findings/0036-verify-doc-paths-counts-gitignored-docs/) | [`run-index-design-20260901-000000`](../sessions/run-index-design-20260901-000000/) | Superseded 2026-09-06 by `0036` for the ground-up re-evaluation. Reading retained here unchanged, brought onto the schema in Revision 203; still held by this session |
| 0027 | [0027-findings-architecture-conformance](0027-findings-architecture-conformance/) | The findings-and-sessions architecture disagrees with itself and with the tree | 7 | [`superseded`](../session-management-findings/0037-findings-architecture-conformance/) | [`restore-apps-outstanding-20260903-000000`](../sessions/restore-apps-outstanding-20260903-000000/) | Superseded 2026-09-06 by `0037` for the ground-up re-evaluation. Reading retained here unchanged, brought onto the schema in Revision 203; still held by this session |
| 0028 | [0028-sessions-write-into-the-tree-the-owner-commits-from](0028-sessions-write-into-the-tree-the-owner-commits-from/) | Sessions compose their changes in the tree the owner commits from | 6 | [`superseded`](../session-management-findings/0038-sessions-write-into-the-tree-the-owner-commits-from/) | [`restore-apps-outstanding-20260903-000000`](../sessions/restore-apps-outstanding-20260903-000000/) | Superseded 2026-09-06 by `0038` for the ground-up re-evaluation. Reading retained here unchanged, brought onto the schema in Revision 203; still held by this session |
| 0030 | [0030-renames-break-citations-and-which-may-be-repaired](0030-renames-break-citations-and-which-may-be-repaired/) | Renames break citations, and only a record's values are frozen | 5 | `analyzing` | [`pre-image-capture-conformance-20260903-194532`](../sessions/pre-image-capture-conformance-20260903-194532/) | Supersedes `0009`. D7 by `run-index-design-20260901-000000` under an owner override; closed by this revision |
| 0033 | [0033-styling-is-copied-into-every-script-and-lands-in-evidence](0033-styling-is-copied-into-every-script-and-lands-in-evidence/) | Styling is copied into every script, and it lands in the evidence | 7 | `unclaimed` | — | Parked at the owner's direction 2026-09-04. Closed to every session until assigned. Recorded by `restore-apps-outstanding`, finding 7 contributed by `pre-image-capture-conformance` |
| 0035 | [0035-a-lineage-rename-is-a-procedure-not-an-operation](0035-a-lineage-rename-is-a-procedure-not-an-operation/) | A lineage rename is a procedure, not an operation | 3 | `assigned` | [`pre-image-capture-conformance-20260903-194532`](../sessions/pre-image-capture-conformance-20260903-194532/) | closed 2026-09-04; `artifact_run_rename_lineage` |
| 0054 | [0054-the-toolkits-own-documents-have-no-currency-watches](0054-the-toolkits-own-documents-have-no-currency-watches/) | The toolkit's own documents have no currency watches | 3 | `unclaimed` | — | Recorded 2026-09-09 by [`assurance-coverage-20260908-204724`](../sessions/assurance-coverage-20260908-204724/), which does **not** own it. Eleven references and five architecture records describe machinery that changes without them; `master-directory-reference.md` is cited by 31 documents. Carries the 24-document reading done under `0053` D2, whose scope crossed the tree line. Parked until the owner assigns it |
