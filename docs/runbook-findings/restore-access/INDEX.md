# Runbook findings — `restore-access`

Finding bundles whose ramifications are functionally felt in `restore-access.md`,
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
| `superseded` | A later bundle replaces this reading. The row names which. |

A bundle advances with its first finding and reaches `resolved` only with its
last. Full definitions, the transitions and the write rules:
[`docs/legend.md`](../../legend.md).

## Bundles

| # | Bundle | Subject | Findings | Status | Session | Notes |
|---:|---|---|---:|---|---|---|
| 0021 | [0021-restore-access-exit-predates-its-own-state-walk](0021-restore-access-exit-predates-its-own-state-walk/) | The Phase 10B exit was recorded a week before the evidence it stands on | 1 | `unresolved` | [`run-index-design-20260901-000000`](../../../sessions/run-index-design-20260901-000000/) | — |
