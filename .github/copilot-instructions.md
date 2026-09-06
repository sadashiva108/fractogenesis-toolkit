# Instructions for fractogenesis-toolkit

**Two instruction sets, and you read both.** They were one file until Revision
191; splitting them is what makes each answerable on its own, because a session
working the reimaging workflow and a session working the findings architecture
were reading each other's rules to find their own.

| Read | For |
|---|---|
| [`.github/session-management-instructions.md`](session-management-instructions.md) | How work is recorded: sessions, findings bundles, who may write what and when, how a change is composed and handed over, `APPLY-MANIFEST.md` |
| [`.github/toolkit-instructions.md`](toolkit-instructions.md) | The reimaging workflow: the runbooks, the scripts, the artifact volume, the checks, and the conventions they follow |
| [`docs/legend.md`](../docs/legend.md) | **Every status and state.** Required alongside the session management set; nothing else defines them |

**Start with the session management set.** It governs how you may touch anything
at all, including this repository's own files, and the toolkit set assumes it.

## The one rule that belongs in neither

**The repository owner reviews and commits every change.** Never commit, never
push, never rewrite history in the owner's checkout. Compose your changes in a
copy of the repository outside it, hand over a patch, and wait to be asked before
it is applied. The mechanics are in the session management set, section 6.

## Where things live

`docs/INDEX.md` is the map of `docs/` and owns the list of its directories.
Neither instruction set enumerates them, because a list in three files has been
wrong in two of them after four of the last six revisions that touched `docs/`.

## Other AI assistant configs

`.claude/CLAUDE.md` points here as the authority. No `AGENTS.md`,
`.cursorrules` or `.windsurfrules` exists in this repository.
