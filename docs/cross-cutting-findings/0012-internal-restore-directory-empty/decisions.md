# Decisions — `.internal/restore/` is empty, and is not tracked

**Bundle:** `0012-internal-restore-directory-empty` · **Status:** `in progress`
**Decided:** 2026-09-04, session `session_01KcZvrKMgfenhrT9DvxW9Jk`, which owns it.

The reading was corrected before deciding, while the bundle was `unresolved` and
`docs/legend.md` still permitted it. The original said the directory was tracked;
it is not. Deciding against the uncorrected text would have produced the wrong
answer — a `.gitkeep`, creating the tracked empty directory the finding was
written to complain about.

## D1 — Fix the sentence, not the directory

`.internal/artifact-runs.sh` line 71 says its callers span `restore/`, `home/`
and the artifact-root reporters. Twenty-nine files source it and **none is under
`.internal/restore/`**. The sentence is rewritten to name where the callers
actually are, which preserves what it exists to say — *no one domain owns this
file, which is why it sits at the `.internal/` root* — while being true.

**Rejected — add a `.gitkeep` with a note.** It would make the untracked
directory tracked, so that a fresh clone gains an empty directory it has never
had, in order to substantiate a sentence that is wrong. The finding's original
plan offered this, and it only looked reasonable while the directory was believed
to be tracked already.

**Rejected — delete the directory and change nothing else.** A patch cannot
express it: the directory is not in the repository. Deleting it locally is worth
doing and is recorded below as an owner action, but it resolves nothing, because
the sentence would still send the next reader looking for `.internal/restore/`.

**Rejected — create the directory properly and move the restore helpers into
it.** The tidiest-looking answer and the most expensive. `state-walk.sh`,
`restore-state-targets.conf.sh` and `sign-offs.sh` are sourced by paths written
across the `bin/record-restore-*` family and the runbooks that cite them; moving
them is a rename, and `0030` is the bundle about what a rename costs. There is no
defect here to justify it — only an empty directory nobody put anything in.

## D2 — The empty directory is removed locally, and that is not a repository change

`rm -d .internal/restore` on each checkout that has one. It produces no diff, no
commit and no revision, and this decision is the only record that it was
deliberate rather than overlooked.

Stated because the alternative is that the next session finds the directory again
on a different checkout, reads a resolved bundle saying it was dealt with, and
cannot tell which of the two is stale.

## D3 — `reimaging-scripts-guide.md`'s tree is a separate finding, and is bigger than this one

`findings.md` notes the guide's `.internal/` tree as stale alongside this. Read
against the tree 2026-09-04, it is worse than stale in one directory: the block
at line 155 shows a nested `<repo-root>/<repo-root>/`, a
`workflows/mac/reimage/scripts/` hierarchy that does not exist, `helpers/apps/`
and `helpers/git/` directories that were never created under those names, and
`backup-docker-settings.sh` / `backup-intellij-scratches-consoles.sh` under
`bin/` when they live in `.internal/apps/` under different names. Ten of the
sixteen `.internal/` entries are missing.

That is not a stale `.internal/` subtree. It is a diagram of a repository layout
that no longer exists, and `./bin/verify-doc-paths.sh` passes because nothing
links into it — which is the observation `findings.md` was reaching for.

**Decided: it gets its own bundle, and this one does not fold it in.** Sizing it
honestly, it is a rewrite of the guide's structural section against the current
tree, and it wants the same *"nothing links into it, so no check sees it"*
question answered rather than just the picture redrawn.

**Rejected — fold it in here, as `findings.md` suggested.** Its plan said to fold
this finding into whichever change next touches the guide. That was the right
instinct when this was one empty directory and one stale subtree. It is the wrong
instinct now: the guide change is the larger of the two by an order of magnitude,
and attaching it to a trivial bundle would hide it.

## What this authorises

One toolkit write: the sentence in `.internal/artifact-runs.sh`. Every finding in
this bundle has a decision, so the `resolving` gate is satisfied.
