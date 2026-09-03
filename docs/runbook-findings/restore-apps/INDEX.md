# Runbook findings — `restore-apps`

Finding bundles whose ramifications are functionally felt in `restore-apps.md`,
including its scripts and the artifacts it owns.

A finding whose impact is broad and agnostic to any particular runbook belongs
in `docs/cross-cutting-findings/` instead — not merely because it touches a
shared script.

The bundle layout and the numbering rule are defined once, in
`.github/copilot-instructions.md` section 4c.

Each bundle also carries a `STATUS-<status>` tag file so a directory listing
answers the status without opening anything. The row here is authoritative.

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
[`docs/legend.md`](../../legend.md).

## Bundles

| # | Bundle | Subject | Findings | Status | Session | Notes |
|---:|---|---|---:|---|---|---|
| 0001 | [0001-restore-repos-evidence](0001-restore-repos-evidence/) | Phase 11B evidence review — what `restore-repos` actually left behind | 10 | `in progress` | [`restore-apps-outstanding-20260903-000000`](../../../sessions/restore-apps-outstanding-20260903-000000/) | Recorded 2026-09-03. 10 findings: 1–3 block a truthful Phase 12 entry, 4–5 are shared-machinery defects, 6–7 answer the two unreviewed repositories |
