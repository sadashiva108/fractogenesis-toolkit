# Resolutions — the target-platform claim has no run behind it

**Bundle:** `0051-the-target-platform-claim-has-no-run-behind-it`  
**Session:** `assurance-coverage-20260908-204724`  
**Resolved:** 2026-09-09

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F2 | D2 | `docs/ledgers/target-platform-verification.md` created, carrying the 2026-09-09 run of `verify-script-portability.sh`, `verify-doc-paths.sh --all` and `verify-session-findings.sh headers` under `/bin/bash` 3.2.57(1) on `arm64-apple-darwin25` against commit `4b721e7`, with all eighteen values and the Linux run beside them | 251 | — |

**F1 and F3 are `decided` and not resolved.** Both are carried out by an edit to
`.github/session-management-instructions.md`, which is a toolkit write; the
finding is `decided`, so §6's gate is satisfied whenever the owner or a doing
bundle takes it.

**`Commit` is `—` because the commit does not exist yet.** The revision is taken
at apply time and the owner commits.
