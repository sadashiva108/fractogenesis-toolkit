# Runbook findings — `capture-office-stability`

Finding bundles whose ramifications are functionally felt in `capture-office-stability.md`,
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
| 0013 | [0013-office-stability-checklists-are-evidence-bundles](0013-office-stability-checklists-are-evidence-bundles/) | `office-stability/checklists/` does not hold checklists | 1 | `unresolved` | [`run-index-design-20260901-000000`](../../../sessions/run-index-design-20260901-000000/) | — |
