# `staged-ignored-files/live/` holds two bundles no lookup can reach

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, while deciding whether
the category should join the run index.
**Severity:** low. Harmless today; misleading to anyone counting bundles.

## What is wrong

`staged-ignored-files/live/` mixes three kinds of entry at one level:

- **Per-repo bundles**, keyed by `basename "$repo_path"` — 24 of them.
- **Run metadata** — `candidates.tsv`, `copied.tsv`, `copy-failed.tsv`,
  `excluded.tsv`, `skipped.tsv`, `secrets-candidates.tsv`, `secrets-copied.tsv`,
  `secrets-copy-failed.tsv`, `parsed-exclude-patterns.txt`,
  `parsed-secrets-patterns.txt`, `summary.txt`.
- **Two entries that are not repo labels** — `IdeaProjects` and `documentation`.

Those last two are the pre-image scan roots
(`/Users/dkittrell/Development/IdeaProjects` and
`/Users/dkittrell/Development/documentation`). Ignored files that matched at
parent level were staged under a directory name that no `<label>` lookup will
ever reach: `bin/restore-repos.sh` resolves `live/$label` where `label` is
`basename "$repo_path"`, and no repository is named `IdeaProjects` or
`documentation`.

## Why it matters

Nothing breaks. But anyone counting `live/` subdirectories to sanity-check
"how many repositories have kept ignored files" gets 26 where the answer is 24,
and the contents of those two bundles were staged and are being carried around
without any restore path.

Phase 6B's `dir_nonempty "$REIMAGE_ARTIFACT_ROOT/staged-ignored-files"` check is
unaffected.

## What to do

No code change proposed. Before anyone trusts a bundle count, look at what is in
those two directories and decide whether the contents belong to a repository
(restore by hand into the right clone) or to the parent directory itself
(nothing restores it, and that is fine).

Record the answer here rather than re-deriving it. If the contents turn out to
matter, the fix belongs in `.internal/git/stage-ignored-files.sh`, invoked
through `bin/backup-repos.sh` from `backup-repos.md` Steps 12–16 — and it is a
pre-image producer, so it can only be fixed forward.
