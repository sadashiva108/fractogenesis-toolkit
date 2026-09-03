# Caller-environment precedence holds only for the keys `artifact-config.sh` lists

**Found:** 2026-09-02, Restore Repositories Refactor session, while smoke-testing
the blank-`GIT_PERSONAL_GITHUB_OWNER` path in `bin/restore-repos.sh`.
**Status: CLOSED** by Revision 136, 2026-09-02 — option three, scoped. Caller
values for every key `reimage.env` sets are captured before sourcing and
re-applied after, by **set-ness** rather than non-emptiness, so
`GIT_PERSONAL_GITHUB_OWNER=` now means what it says. The thirteen keys
`artifact-config.sh` resolves by name keep their `:-` semantics so a blank export
cannot erase a default, and the header documents that exception instead of
claiming an unqualified rule. Verified across five cases against a fixture.
**Severity:** low, but it made a documented rule untrue for most keys.
**Owner:** unassigned — `.internal/artifact-config.sh` belongs to neither current
session's file set.

## What is documented

`.internal/artifact-config.sh` and `.internal/load-reimage-config.sh` both state
the same precedence, unqualified:

> 1. Values already present in the caller environment.
> 2. Values loaded from `reimage.env`.
> 3. Defaults defined by this file.

`.github/ai-prompts/script-prompts/bash-script-authoring-and-review.md` repeats
it as the architecture to preserve.

## What happens

`artifact-config.sh` captures a **fixed list** of caller values into `preset_*`
locals before sourcing `reimage.env`, and re-applies them afterwards:
`REIMAGE_ENV`, `REIMAGE_WORKSPACE_ROOT`, `EXTERNAL_DATA_VOLUME`,
`EXTERNAL_APPLE_BACKUPS_VOLUME`, `REIMAGE_ARTIFACT_ROOT`, and the other names in
its header's "loaded outputs" list.

`reimage.env` sets its keys with a plain `export NAME=value`, so any key *not* in
that list is overwritten by sourcing. Every `GIT_*` key is in that category.

Observed:

```bash
GIT_PERSONAL_GITHUB_OWNER="" ./bin/restore-repos.sh --artifact-root <root>
# still runs with GIT_PERSONAL_GITHUB_OWNER=sadashiva108, from reimage.env
```

The documented rule says the empty caller value wins. It does not.
`REIMAGE_ENV=<file>` pointing at an edited copy is the working way to override a
`GIT_*` key for one invocation, and that is what the test above had to fall back
to.

## Why it is easy to miss

The keys people actually override by hand — the artifact root and the external
volumes — are all on the preserved list, so the rule appears to hold whenever
anyone checks it. `--artifact-root` works for a different reason again: entry
points apply CLI options *after* loading, which the header correctly describes as
the entrypoint's responsibility.

## Options

| Option | Cost |
|---|---|
| Narrow the documentation to say which keys are preserved | Honest, zero risk, and leaves a rule with an arbitrary-looking list |
| Have `reimage.env` assign with `: "${NAME:=value}"` | Makes the rule true for every key at once; changes the semantics of a file the owner edits by hand, and an intentionally-empty value in `reimage.env` would stop being assignable |
| Capture and restore every key `reimage.env` sets, generically | Truest to the documented rule; means parsing `reimage.env` for names before sourcing it, in Bash 3.2, without associative arrays |

Not fixed here: `.internal/artifact-config.sh` is shared foundation, the change
touches configuration precedence for every script in the repository, and the
authoring prompt requires that architecture to be preserved unless a task
explicitly asks to change it.
