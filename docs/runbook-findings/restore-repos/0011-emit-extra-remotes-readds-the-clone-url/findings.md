# `emit_extra_remotes` re-adds the URL the clone already used

**Found:** 2026-09-01, Restore Repositories Refactor session, while verifying the
regenerated `clone-commands.sh`.
**Severity:** cosmetic. Produces a redundant but harmless command.
**Owner:** the Restore Repositories Refactor session's file set.

## What is wrong

`extract_remote_url()` returns the first `origin` fetch URL, or — when the
repository has no remote named `origin` — the first URL of any remote.
`emit_extra_remotes()` then emits a `git remote add` for every remote whose name
is not `origin`.

For a repository whose only remote is not called `origin`, both fire on the same
URL. `fractogenesis-toolkit` has one remote, `shiva`, so the emitted block is:

```bash
cd ".../workspace/shiva" && git clone "https://github.com/sadashiva108/fractogenesis-toolkit.git"
git -C ".../fractogenesis-toolkit" remote add shiva "https://github.com/sadashiva108/fractogenesis-toolkit.git" 2>/dev/null || \
  git -C ".../fractogenesis-toolkit" remote set-url shiva "https://github.com/sadashiva108/fractogenesis-toolkit.git"
```

The clone creates `origin` pointing at that URL, and then `shiva` is added
pointing at the same URL. Two names for one remote. Nothing breaks; `git fetch
--all` just fetches it twice.

`enterprise-search` (`orah`) and `carrier-services-storage` (`omkara`, `orah`,
`origin`) are the other repositories where the pre-image `origin` is absent or
not first alphabetically.

## Fix

Skip a remote in `emit_extra_remotes` when its URL equals the URL the clone
used. That means passing `$remote_url` in as a third argument rather than
comparing names — the name is what differs, the URL is what matters.

Not fixed in the Phase 11B refactor because it is cosmetic and the change set was
already large; parked so it is not re-derived from the emitted output later.
