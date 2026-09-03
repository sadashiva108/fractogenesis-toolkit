# Final summary — `phase-11b-hydrate-and-bookends-20260903-141500`

**Closed 2026-09-03** by the owner. Assistant Claude, session
`session_019yzcjm2QneJ5ymVEQDi1bu`, running 2026-09-02 to 2026-09-03 in a Linux VM
with Bash 5.1 and GNU coreutils.

One conversation, three briefs. Revision 162 had made the first two into their own
session bundles; Revision 175 absorbed them here, so this bundle is the whole
session and this summary covers all of it.

## Revisions

| Revision | What |
|---:|---|
| 131 | Phase 11B refactor of `bin/restore-repos.sh`, executed from the plan in `restore-repos-phase-11b-plan.md` |
| 142–146 | The declared clone plan: four sourced fragments, `docs/architecture/restore-repos-clone-plan.md` |
| 147–150 | `--hydrate`, `--stage`, `hydrated.md`, `repo-restore-index.md`; `REMOTE_NAME` and `ROUTE_REVIEW` made to work; `PATH_ROOT` → `PRE_IMAGE_ROOT` |
| 151–155 | `reimage.env.example` completeness; Step 1's real summary; the status report stops restating the sign-off; the carry-forward row scoped to what the plan restores; the toolkit repoint deduplicated |
| 156–159 | `boundaries/` → `bookends/`; the restart record → `record.md`; the first-boot capture's manual rows routed to `sign-offs/`; prose reserved `checklist` for the capstones |
| 167 | The findings-and-sessions architecture read against the tree; finding `0027` recorded; identity recovered for two bundles; this bundle created |
| 170 | Seven findings merged here from the two closed briefs |
| 171 | Finding `0028` — what a shared working tree costs |
| 175 | One session, one bundle: the two brief bundles absorbed and removed |
| 176 | Commit messages: short, and written so the shell cannot break them |

Revision 177 was written and rolled back by the owner before it was committed.

## Commits

Fifteen. Thirteen carry a usable `Claude-Session` trailer:

`e879a8d`, `7c6dc1a`, `e2b6012`, `d77f5b6`, `da3850e`, `e4ac5d3`, `8132d93`,
`9fea5eb`, `de7aa8e`, `a2342d1`, `f5ede36`, `5fcb7d8`, `46dab58`

Two do not, and this is worth more than the two commits:

- **`a1c2f33`** has no `Claude-Session` trailer at all.
- **`0a3da17`** has one that is **truncated** — `session_019yzcjm2QneJ5ymVEQDi1`,
  missing the final `bu` — so `git log --grep=<full id>` does not match it.

`0027` finding 7 asserts that a session's identity is recoverable because the
harness writes the trailer into every commit. That holds for finding *a* session.
It does **not** hold for enumerating one's commits: the trailer can be absent, and
it can be silently truncated by a paste. Any future recovery should grep a prefix
and then verify, not grep the full identifier and trust the count.

`5fcb7d8` and `46dab58` also carry the terminal's own prompt, timestamp and git's
`error: pathspec` output inside their messages, from a commit message that broke
shell quoting. Revision 176 wrote the rule that prevents it. Both are pushed and
were left as they are.

## Findings

Seven were owned here. Two are `resolved` and stay listed in
`findings-manifest.md`: `0006` (closed by Revision 136) and `0020` (Revision 131).

Five are `unresolved` and were **unowned** at closing — `0008`, `0011`, `0015`,
`0016`, `0017`. Their INDEX rows read `—`. That is deliberate: a `closed` bundle
has stopped, and leaving open findings under it is precisely the defect Revision
175 removed from the two `restore-repos` bundles. They are unassigned, not
abandoned, and they are all `restore-repos` or portability-lint readings.

`0027` and `0028` were **recorded** by this session and never owned by it; both
belong to `restore-apps-outstanding-20260903-000000`.

## What this session owes, and did not do

**`/bin/bash -n` against real macOS Bash 3.2 is owed for Revisions 116–176.**
Every command this session ran was in a Linux VM with Bash 5.1 and GNU coreutils,
where `mapfile`, `declare -A`, `sed -i` and `stat -c` all work silently. The
portability lint catches the runtime constructs `-n` cannot see; the two are
complements and only one has ever been run. This is the largest single thing left
undone.

**`bookends/MANIFEST.md` has no rename row.** Four rows carry `migrated from`; the
`boundaries` → `bookends` rename added none. An evidence write, needing the owner's
word for a specific run.

**`_pre-conversion-backup-20260902/` keeps the pre-rename `boundaries/` and
`checklist.md` names.** Left deliberately as a backup of the prior state; the owner
may still want it renamed.

**The scratch-and-refresh discipline is not in the instruction set.** Revision 177
would have put it in `.github/copilot-instructions.md` section 3 and was rolled
back. It survives only in the prompt written for the incoming session. Whoever
resolves `0028` should land it.

## Evidence writes

Unlike its sibling sessions, this one **wrote to the artifact volume**: the
`bookends/` rename moved 36 records and a category directory, the restart rename
moved 6 more, and 39 artifacts had stale references repointed. Every functional
test of `bin/restore-repos.sh` and `bin/record-reimaged-system.sh` ran against a
scratch root, and every check against the live volume used `--dry-run`. Those
writes predate the three-write vocabulary Revision 169 introduced.
