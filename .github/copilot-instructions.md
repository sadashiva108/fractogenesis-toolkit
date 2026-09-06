# Instructions for fractogenesis-toolkit

**Two instruction sets, and you read both.** They were one file until Revision
191; splitting them is what makes each answerable on its own, because a session
working the reimaging workflow and a session working the findings architecture
were reading each other's rules to find their own.

| Read | For |
|---|---|
| [`.github/session-management-instructions.md`](session-management-instructions.md) | How work is recorded: sessions, findings bundles, who may write what and when, how a change is composed and handed over, `APPLY-MANIFEST.md`. **Project-agnostic — reusable in any repository as-is** |
| [`.github/toolkit-instructions.md`](toolkit-instructions.md) | The reimaging workflow: the runbooks, the scripts, the artifact volume, the checks, and the conventions they follow |
| [`docs/legend.md`](../docs/legend.md) | **Every finding status, bundle status and session state.** Required alongside the session management set; nothing else defines them |

**Start with the session management set.** It governs how you may touch anything
at all, including this repository's own files, and the toolkit set assumes it.

## The line between the two

One question decides where anything belongs: **would this still be true in a
project that did something else entirely?**

Rules about sessions, findings, statuses, who may write and when, and how a
change reaches the owner are the same everywhere and live in the session
management set. Everything about reimaging a Mac — the phases, the runbooks, the
artifact volume, the recorders, the lints — lives in the toolkit set. A defect in
`bin/reindex-artifact-runs.sh` is the toolkit's; a defect in the rule that says
*when a session may edit it* is session management.

## The findings trees

Four, sharing one numbering sequence. `docs/INDEX.md` is the map and owns the
list; this file names them only to say which set governs which.

| Tree | Governed by |
|---|---|
| `docs/runbook-findings/<runbook>/` | the toolkit set |
| `docs/cross-cutting-findings/` | the toolkit set |
| `docs/instruction-set-findings/` | the toolkit set — findings about `toolkit-instructions.md` itself |
| `docs/session-management-findings/` | the session management set |

## The one rule that belongs in neither

**The repository owner reviews and commits every change.** Never commit, never
push, never rewrite history in the owner's checkout. Compose your changes in a
copy of the repository outside it, hand over a patch, and **wait to be asked
before it is applied.** The mechanics are in the session management set.

## Other AI assistant configs

`.claude/CLAUDE.md` points here as the authority. No `AGENTS.md`,
`.cursorrules` or `.windsurfrules` exists in this repository.
