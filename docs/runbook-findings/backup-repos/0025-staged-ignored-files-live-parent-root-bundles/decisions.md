# Decisions — `staged-ignored-files/live/` holds two bundles no lookup can reach

**Bundle:** `0025-staged-ignored-files-live-parent-root-bundles` · **Status:** `in progress`
**Decided:** 2026-09-03, session `session_01PcgHu9kz9Hm5RatLQuFR8H`, owner
present.
**Read against:** `/Volumes/Data/reimage-CVG-0002160-500-20260816-open`,
read-only, on the owner's grant.

`findings.md` carries a dated correction to the producer it named, made while the
bundle was still `unresolved` and before any decision was taken against it. The
reading is otherwise unchanged.

## D1 — The question the finding asks is answered, and the answer is *no restore path is needed*

`findings.md` proposes no code change and asks one thing: look at what is in the
two directories and decide whether the contents belong to a repository or to the
parent. Both were opened.

**`live/documentation/`** — 4 files, the directory's own `.idea/` (`vcs.xml`,
`workspace.xml`, `modules.xml`, `misc.xml`). Parent-level configuration for a
scan root. Nothing restores it, and the finding already says that is fine.

**`live/IdeaProjects/`** — 24 files in three classes:

| Class | Files | What it is |
|---|---:|---|
| `IdeaProjects/.idea/` | 5 | the scan root's own IntelliJ workspace config |
| `apicoe/`, `tools/`, `data-cache-related/`, `transformation-tool/` `.idea/` | 17 | project config for four directories under the root that are **not git repositories** |
| `module-selector-plugin*.zip` | 2 | see D3 |

**Decided: none of it is restored.** The parent-level config describes a machine
that no longer exists. The 17 nested files are project metadata for directories
with no clone to restore into — decided by the owner, 2026-09-03.

**Rejected — restore the 17 by hand through Phase 12.** A real option, and the
reason this needed the owner rather than a rule: `restore-intellij.md` does
restore selective project-level `.idea/` metadata per repository, so the material
has a consumer. It was declined because those four directories are not being
recreated, and `restore-intellij.md` says in its own Confirm Your Intent that
restoring metadata for a project you no longer need drags stale run
configurations forward for no benefit.

## D2 — The finding's "no restore path" is true of `restore-repos.sh` and not of the workflow

Worth recording, because the next reader will hit the same wording.
`bin/restore-repos.sh` resolves `live/$label` where `label` is the repository
basename, so these bundles are genuinely unreachable *there*. But `.idea/`
metadata is `restore-intellij.md`'s material, not `restore-repos.md`'s, and that
runbook restores it per cloned repository. The bundles are unreachable because
their sources were never repositories — not because the workflow has no consumer
for what is in them.

## D3 — The two zips are not restored either, and are not the same case

`module-selector-plugin-1.3.1.zip` is a built IntelliJ plugin distribution —
`lib/gson-2.10.1.jar`, `lib/module-selector-plugin-1.3.1.jar` and its
searchable-options jar, 324,640 bytes at source. It is **build output of a
repository that Phase 11B clones**, and `live/module-selector-plugin/` exists as
its own reachable bundle. Rebuildable from source; nothing is lost by leaving it.

`module-selector-plugin.zip` was **0 bytes at source**.

Both were matched by the include pattern `*.zip` rather than chosen. Neither is
restored.

**Rejected — move the 1.3.1 zip somewhere reachable.** It would be the only
artifact in `staged-ignored-files/` placed by hand, in a category the ledgers
have settled as three sibling modes rather than a run index, to preserve
something a `./gradlew buildPlugin` reproduces.

## D4 — No code change, and the producer is not fixed

`findings.md` proposes none, and this confirms it.

The labelling is **correct by design**: `make_label_map()` gives a scan root its
own label so that files matched outside any repository are staged with their
provenance intact rather than dropped or misattributed. The defect is only that
`restore-repos.sh` has no lookup for such a label — and it should not, because
what lands there is by definition not a repository's.

**Rejected — teach `restore-repos.sh` to read scan-root bundles.** It would give
the restore path a case that resolves to *"restore this into no clone"*.

**Rejected — exclude scan roots from labelling in `stage-selected-patterns.py`.**
That would silently drop files that matched the operator's own include patterns,
which is worse than staging them somewhere unreachable. It is also a pre-image
producer: the machine it read no longer exists, so any change is forward-only and
cannot improve this evidence.

**Rejected — count the two directories in a bundle count.** The finding's real
cost was that someone counting `live/` subdirectories gets the wrong number of
repositories. That is now answered here in writing, which is what the finding
asked for, rather than by changing what the producer writes.

## D5 — What this bundle does not take

The `.idea/` material under the four non-repository directories may still matter
to `restore-intellij.md` if any of those projects is ever recreated. That is a
Phase 12 question, not a `backup-repos` one, and no bundle is opened for it: the
owner has decided the projects are not being recreated, so there is nothing to
track.

---

## What this authorises

Nothing. No toolkit write, no evidence write, no change on the volume. The
resolution is the answer, recorded where the finding asked for it.
