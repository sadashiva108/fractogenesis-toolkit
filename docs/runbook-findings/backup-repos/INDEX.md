# Runbook findings — `backup-repos`

Finding bundles whose ramifications are functionally felt in `backup-repos.md`,
including its scripts and the artifacts it owns.

A finding whose impact is broad and agnostic to any particular runbook belongs
in `docs/cross-cutting-findings/` instead — not merely because it touches a
shared script.

**The bundle layout, the status vocabulary and the numbering rule are defined
once**, in `.github/copilot-instructions.md` section 4c. This file carries the
rows and nothing else.

Each bundle also carries a `STATUS-<status>` tag file so a directory listing
answers the status without opening anything. The row here is authoritative.

## Bundles

| # | Bundle | Subject | Findings | Status | Session | Notes |
|---:|---|---|---:|---|---|---|
| 0025 | [0025-staged-ignored-files-live-parent-root-bundles](0025-staged-ignored-files-live-parent-root-bundles/) | `staged-ignored-files/live/` holds two bundles no lookup can reach | 1 | `unresolved` | [`run-index-design-20260901-000000`](../../../sessions/run-index-design-20260901-000000/) | — |
