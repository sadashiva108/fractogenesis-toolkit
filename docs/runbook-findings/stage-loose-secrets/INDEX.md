# Runbook findings — `stage-loose-secrets`

Finding bundles whose ramifications are functionally felt in `stage-loose-secrets.md`,
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

| # | Bundle | Finding | Status | Session | Notes |
|---:|---|---|---|---|---|
| 0007 | [0007-content-scans-keeps-a-bespoke-index](0007-content-scans-keeps-a-bespoke-index/) | `content-scans/` looks like a run category and is not one | `resolved` | [`run-index-design-20260901-000000`](../../../sessions/run-index-design-20260901-000000/) | closed by Revision 141 |
