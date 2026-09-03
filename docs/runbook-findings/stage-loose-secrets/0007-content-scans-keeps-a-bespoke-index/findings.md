# `content-scans/` looks like a run category and is not one

**Found:** 2026-09-02, session `01KcZvrKMgfenhrT9DvxW9Jk`, during the runbook layout pass.
**Status: CLOSED** by Revision 141, 2026-09-02. The runs moved up into
`loose-secrets-reports/runs/`, the category's `official/` now answers for them,
and `latest-run.txt` and `content-scans/` are gone. Kept for the reasoning, and
for what the conversion turned up.
**Severity:** low to hit, moderate to leave — it is the last place in the tree where
`latest-run.txt` is the right answer, which makes the rule "never follow a
`latest-*.txt`" untrue by exactly one exception.

## What is wrong

`loose-secrets-reports/content-scans/` has `MANIFEST.md`, `runs/` and
`latest-run.txt` — the shape the shared run index replaced. Its parent,
`loose-secrets-reports/`, was converted in Revision 138 and has `official/`.
So one category directory now carries both conventions, one level apart:

```text
loose-secrets-reports/
├── MANIFEST.md          shared index
├── official/            computed pointers
├── content-scans/
│   ├── MANIFEST.md      bespoke index
│   ├── latest-run.txt   hand-written pointer
│   └── runs/
└── runs/
```

Two writers produce it, both helpers of `backup-home.md`:

- `.internal/home/scan-archive-contents.sh`
- `.internal/home/scan-postman-collections.py`

Each writes its own manifest row and its own `latest-run.txt`, the way
`report-size-audit.sh` and `report-loose-secrets.sh` did before Revision 138.

## Why it matters

A `latest-*.txt` cannot express a point rule, cannot be pinned, and disagrees
with a computed pointer the moment anyone deletes or copies a run. That is the
reasoning behind the shared index, and it applies here identically — the only
reason this one survived is that the conversion pass worked category by category
at the top level and never descended.

It also costs the documentation a clean rule. Every other runbook can now say
"read the pointer under `official/`"; `backup-home.md` and `backup-apps.md` have
to carve out an exception, which is what they now do in prose.

## What a fix looks like

The same bracket every other producer uses: `artifact_run_begin` on
`loose-secrets-reports/content-scans`, write, `artifact_run_finalize`, and delete
the hand-written `latest-run.txt`. The existing runs keep their stamps and are
picked up by `reindex-artifact-runs.sh`, exactly as the Revision 138 conversions
were.

Two questions to settle first, which is why this is parked rather than done:

1. **Is `content-scans/` a sub-category or its own category?** It is nested under
   `loose-secrets-reports/` because the scans are secret-shaped content checks,
   but the shared library has no notion of a nested category — `official/` and
   `MANIFEST.md` at two levels is legal but has no precedent in this tree.
2. **What is the context?** Today the run names carry the caller
   (`pre-image-backup-home-external`, `pre-image-backup-home-onedrive`), which is
   the same shape `size-audit-reports/` uses, so this is probably already right.

## Where it is documented today

`backup-home.md` Step and `backup-apps.md` Step both state the exception in
prose, and `references/master-directory-reference.md` shows `content-scans/` with
its own `MANIFEST.md` and `latest-run.txt` inside the
`loose-secrets-reports/` collapsible. Those are accurate as things stand and
become wrong the moment this is converted.


## How it was resolved

Both questions in "What a fix looks like" answered themselves once the data was
looked at rather than reasoned about.

**Sub-category or its own category?** Neither — the runs belong in the parent.
The contexts do not collide (`pre-image-backup-home-external` against
`pre-image`, `pre-image-final` and the rest), no reader outside the two writers
named the path, and the parent already spans phases: `pre-image-after-backup-home`
was sitting in it. The nesting was the only thing making this look like two
categories.

**What is the context?** Already right, and now produced rather than typed. The
leg moved out of the report filename and into the run id, so a both-legs
invocation writes `<context>-external` and `<context>-onedrive` as two runs with
two pointers instead of one directory holding two files and appending two
manifest rows for itself. `archive-content-scan-external.md` became
`archive-content-scan.md`: the run id already says which leg it is.

The domain columns did **not** merge into `loose-secrets-index.md`. The sweep
counts files found outside and inside `secrets-encrypted/`; a content scan counts
archives examined and archives with credential-shaped members. One table holding
both would leave four of its columns blank on every row. `content-scan-index.md`
sits beside it instead — the same relationship `repo-audit-index.md` and
`size-audit-index.md` have with their categories' manifests, and the shared
`MANIFEST.md` remains the single run index over all three producers.

## What the conversion turned up

Both scanners were moved into `.internal/home/` at some point without their
repository-root computation being updated, so each resolved
`$REPO_ROOT/.internal/load-reimage-config.sh` to
`<repo>/.internal/.internal/load-reimage-config.sh`.

`scan-archive-contents.sh` guards that load with `[[ -f ]]`, so it silently ran
without the artifact-config fragments. `scan-postman-collections.py` calls
`die()`, so it exited 2 on its documented invocation — which is why the volume
holds two archive runs and no Postman run at all. Both are fixed in Revision 141.
