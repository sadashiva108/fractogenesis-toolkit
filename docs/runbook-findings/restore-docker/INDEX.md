# Runbook findings — `restore-docker`

Finding bundles whose ramifications are functionally felt in `restore-docker.md`,
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
| 0024 | [0024-restore-docker-stack-differs-from-pre-image](0024-restore-docker-stack-differs-from-pre-image/) | The running Docker stack is not the one `restore-docker.md` restores | `unresolved` | — | — |
