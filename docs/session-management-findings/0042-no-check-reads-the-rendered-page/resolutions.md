# Resolutions — no check reads the rendered page

**Bundle:** `0042-no-check-reads-the-rendered-page`  
**Session:** `assurance-coverage-20260908-204724`  
**Resolved:** 2026-09-09

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F2 | D3 | `.internal/ai-scripts/session-management/verify-findings-headers.sh` gained the two-space and hard-break assertions on the header block, and the fence rules: a four-space indented example fails, and `^\`\`\`markdown$` fails. The three defects F2 tabulates are each caught by one of them | 202 | `b5a78e5` |
| F2 | D3 | The same script gained one field per source line and the `Session:`/`Read:` separation, which is the construct Revision 201's defect was in | 203 | `74e5790` |

**F1, F3 and F4 are `decided` and not resolved.** F1 is accepted as a permanent
property and has no work behind it; F3 states a floor rather than changing
anything; F4's remedy is one paragraph in the conformant prompt, deliberately
left to the owner — `0042` D2.
