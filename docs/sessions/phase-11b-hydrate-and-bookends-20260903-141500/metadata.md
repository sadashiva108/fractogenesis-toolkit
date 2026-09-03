# Session metadata — phase-11b-hydrate-and-bookends

Authoritative for who and what has owned this bundle. `docs/sessions/INDEX.md`
carries the state and points here.

## Owners

| From | Until | Assistant | Session id | Model | Environment |
|---|---|---|---|---|---|
| 2026-09-02 | — | Claude | `session_019yzcjm2QneJ5ymVEQDi1bu` | configured `claude-opus-5` | Linux VM, Bash 5.1, GNU coreutils |

Transcript: `https://claude.ai/code/session_019yzcjm2QneJ5ymVEQDi1bu`

## Why this bundle exists

The same session owns two earlier bundles —
`restore-repos-refactor-20260902-000000` and
`restore-repos-clone-plan-20260902-000000` — and both are correctly `closed`:
their briefs finished. The session did not. Everything from Revision 147 onward
was done under directions given turn by turn rather than under either prompt, and
had no bundle at all until this one.

That gap is worth naming rather than papering over. The bundle-per-brief shape
assumes a session ends when its brief does. This one outlived two, and the
architecture has no state for *still running, past the prompt that started it* —
so the work was invisible to `docs/sessions/` while it was happening.

`prompt.md` was written on 2026-09-03, at the owner's request, part-way through
the session it briefs. It is **forward-looking, not a reconstruction**: it covers
the seven findings merged into this bundle the same day and the two debts the
session carries, and says so in its first paragraph. No prompt started the span
from Revision 147 to 167, and writing one after the fact would have satisfied
§4d by inventing the artifact it asks for.

So the file exists and conforms — it opens with `.github/copilot-instructions.md`
as item 1 of the reading order, which finding 2 of `0027` says four of five
prompts fail to do — but the gap it was written around is unchanged: §4d assumes a
bundle begins with a brief, and this one began in the middle of a conversation.
That remains folded into `0027` as the case the rule does not cover.

## Environment

Every command ran in a Linux VM on the owner's machine with the repository and
the artifact volume mounted into it — **not** on macOS. Bash 5.1 with GNU
coreutils, where `mapfile`, `declare -A`, `sed -i` and `stat -c` all work
silently.

**`/bin/bash -n` against real macOS Bash 3.2 is owed for every revision this
session wrote — 131, 142–159 and 167 — and for Revisions 116–130 before it.**
Nothing this session validated was validated on the target platform. The
portability lint catches the runtime constructs `-n` cannot see; the two are
complements, and only one of them has been run.

## Resources it worked against

| What | Path |
|---|---|
| Repository | `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit` |
| Artifact root | `/Volumes/Data/reimage-CVG-0002160-500-20260816-open` |
| Workspace root | `/Users/dkittrell/reimage-workspace` — the clone plan fragments |

The artifact root was **written to**, unlike the sibling session's read-only
pass: the `bookends/` rename moved 36 records and a category directory, the
restart rename moved 6 more, and 39 artifacts had stale references repointed.
Every functional test of `bin/restore-repos.sh` and `bin/record-reimaged-system.sh`
ran against a scratch root, and every check against the live volume used
`--dry-run`.

## Contributions

| Revisions | What |
|---|---|
| 147–150 | `--hydrate`, `--stage`, `hydrated.md`, `repo-restore-index.md`; the runbook and five references brought in line; `REMOTE_NAME`, `ROUTE_REVIEW` and the excluded-twice check made to work; `PATH_ROOT` → `PRE_IMAGE_ROOT` |
| 151–155 | `reimage.env.example` completeness; Step 1's real summary; the status report stops restating the sign-off; the carry-forward row scoped to what the plan restores; the toolkit repoint deduplicated |
| 156–159 | `boundaries/` → `bookends/`; the restart record → `record.md`; the first-boot capture's manual rows routed to `sign-offs/`; `b_todo_count` → `b_outstanding_count`; prose reserved `checklist` for the capstones |
| 167 | The findings-and-sessions architecture read against the tree; identity recovered for two bundles; this bundle created. Recorded finding `0027` — recorded, not owned |
| 170 | The seven findings of the two closed sibling bundles merged into this one; both closed manifests become pointers; this bundle's `prompt.md` written |

Commits `e879a8d`, `7c6dc1a`, `e2b6012`, `d77f5b6`, `da3850e`, `e4ac5d3`,
`8132d93`, `9fea5eb`, `de7aa8e`, `a2342d1` — every one carrying this session's
`Claude-Session` trailer. Revisions 131 and 142–146 predate the trailer
convention and are attributed to the two closed bundles above.

Revisions 167 and 170 are uncommitted at the time of writing.
