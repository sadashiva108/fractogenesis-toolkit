# Update Reference Files

Automate mechanical updates to reference files (Markdown runbooks, guides, and
evidence docs) when you migrate files from one repository to another and their
paths, filenames, or external-artifact folders change.

## Why this exists

It is not uncommon for filenames and paths to diverge across repositories, and
patching every reference by hand is tedious and error-prone. This toolkit lets
you migrate files iteratively — mapping only what you have moved so far — and
regenerate a full report plus safe, reviewable diffs each time. Reasons this
carries its weight:

- **Migrating out of a shared repo.** Extracting a workflow (e.g., the reimage
  workflow out of a lightweight daily reference vault) into a dedicated
  repository is easier when link/path updates are automated. The daily
  reference vault stays lean while the workflow gets its own home.
- **Room to grow.** A dedicated repo can host additional workflows over time
  without polluting an unrelated repo.
- **Toolkit-shaped.** Once the mechanical rewrite pipeline exists, it can be
  reused by other automation (e.g., prompts that migrate a runbook or a
  script — see [What's next?](#whats-next)).
- **Iterative and idempotent.** Only migrated files appear in the mapping, so
  unmigrated references keep their old paths and get updated on a later run.
- **Reviewable.** Every run produces both a categorized report and diffs you
  can inspect (or apply as a single patch) before touching your working tree.

## Scripts in this directory

| Script | Purpose |
|---|---|
| [`update-references.py`](./update-references.py) | Scan reference files, apply mappings, produce a categorized report and optional diffs/patch. |
| [`generate-mapping-template.py`](./generate-mapping-template.py) | Seed a small mapping JSON from a set of source files you're about to migrate. |

## Initial setup — create mappings

Minimal setup: create a mapping of your old repository files to their planned
new locations. This may be the exact subdirectory you plan to seed the new
repo from.

```bash
export SOURCE=/path/to/reference-vault/workflows/mac/reimage
export DEST=/path/to/new/repository
export MAPPINGS=/tmp/mappings
export REFERENCES=/path/to/reference/files

python3 .internal/copilot-scripts/generate-mapping-template.py \
  "$SOURCE/backup-apps.md" \
  "$SOURCE/scripts/backup-apps.sh" \
  --default-md-dir "$REFERENCES" \
  --out "$MAPPINGS/repo-root-mapping-07-18-2026.json"
```

Rerun `generate-mapping-template.py` each time you migrate more files, or
hand-edit the mapping JSON to add entries.

### Mapping file conventions

`update-references.py` auto-discovers mappings in `/tmp/mappings/` by
filename prefix. Newest by filename-sort wins for each prefix, so timestamped
names like `repo-root-mapping-07-18-2026.json` naturally pick up the latest.
You can override either default with `--mapping <path>` or
`--external-mapping <path>`.

| Prefix | Kind | What it renames |
|---|---|---|
| `repo-root-mapping-*.json` | Repo-root | Old repo paths / filenames → new repo paths / filenames. |
| `external-data-root-mapping-*.json` | External data-root | Env-var tokens and folder names under the reimage-prep external drive. |

### Sample: `repo-root-mapping-*.json`

Keys are old paths (relative to the old repo root); values are new paths
(relative to this repo root). Same-basename entries with different paths
signal a location change; different basenames signal a rename.

```json
{
  "backup-local-files.md": "backup-home.md",
  "prepare-backup-root.md": "prepare-artifact-root.md",
  "scripts/backup-apps.sh": "bin/backup-apps.sh",
  "scripts/backup-config.sh": ".internal/artifact-config.sh",
  "scripts/bootstrap.sh": "bootstrap.sh",
  "scripts/templates/backup-config/skip-entries.conf.sh":
    ".internal/templates/artifact-config/skip-entries.conf.sh"
}
```

The updater applies three heuristics per entry:

1. **Literal path** occurrences (e.g., ``scripts/backup-apps.sh``).
2. **Basename** occurrences that aren't embedded in a longer path
   (e.g., ``backup-apps.sh``).
3. **Tokenized derivative** in prose (e.g., ``Backup Apps`` /
   ``backup apps``), with case preserved.

Link path/heuristic rewrites and fenced directory-tree rebuilds are handled
alongside these.

### Sample: `external-data-root-mapping-*.json`

Keys are env-var names (with or without a `$`) or folder segments under the
external artifact root; values are the replacement token or path. When the
value carries a `$` prefix, the updater keeps the `$` shape correct in every
context.

```json
{
  "BACKUP_ROOT": "$REIMAGE_ARTIFACT_ROOT",
  "app-backups": "app-settings-backup",
  "git-audit-reports": "repo-audit-reports",
  "local-files": "home-files-backup",
  "reimage-plan": "reimage-confirmation",
  "selected-ignored-files": "staged-ignored-files/live",
  "selected-ignored-files-dryrun": "staged-ignored-files/dryrun",
  "selected-ignored-files-filtered-dryrun": "staged-ignored-files/dryrun-filtered"
}
```

Special semantics for external tokens:

- `$` normalization: `BACKUP_ROOT` and `$BACKUP_ROOT` both match; the
  output never doubles the sigil.
- Glob repositioning: if the source is followed by `*/` and the replacement
  introduces a new sub-directory (contains `/`), the trailing `*` is
  repositioned as `/*` so a directory glob keeps its "contents of" meaning
  (e.g., ``selected-ignored-files*/`` → ``staged-ignored-files/live/*``).
- Applied to fenced directory trees under an external-artifact root header,
  and to prose occurrences outside links/fences.

### Do new categories of mapping require script changes?

**Usually yes.** The two supported kinds above have different rewrite
semantics baked into `update-references.py`:

- `repo-root-mapping` drives link rewrites, tree rebuilds, and the
  three-heuristic prose rewrite above.
- `external-data-root-mapping` drives the env-token + folder rewrite with
  `$`-normalization and glob repositioning.

A brand-new *kind* of mapping (say, "OS-level path renames" with different
rules) would need a new pass in both the report scan and the rewrite
pipeline. A new *entry* inside either existing kind just needs to be added
to the JSON — no code change.

## Dry run before updating reference files

The dry run prints only the totals + report path to the terminal. Every
category detail is written to the markdown report file.

```bash
python3 .internal/copilot-scripts/update-references.py
```

```
Using repo-root mapping: /tmp/mappings/repo-root-mapping-07-18-2026.json
Using external data-root mapping: /tmp/mappings/external-data-root-mapping-07-18-2026.json

Report summary:
- Mapping entries: 29
- Files scanned: 10

| Category                                              | Count |
|-------------------------------------------------------|------:|
| Total occurrences of stale file references            |    91 |
|   Renamed links or those with missing targets         |     0 |
|   Linked file location or heuristics changes          |    10 |
|   Stale filenames and their derivatives in prose      |    44 |
|   Repo root tree changes                              |    14 |
|   External data root tree changes                     |    23 |

Report directory: /tmp/reports
Report file: /tmp/reports/update-references-report-07-18-2026-101614-EST.md
```

Open the report file to see, per reference file, every link/prose/tree change
the updater would make.

## Getting and testing diffs before applying updates

`--diffs` writes one unified diff per reference file. Each diff can be applied
independently with `git apply -p0`.

```bash
cd /path/to/fractogenesis-toolkit

# 1. Make sure the working tree is clean so the diffs apply against pristine sources.
git status --short         # should be empty (aside from update-references.py itself)
git checkout -- README.md references/ reimaging-guide.md reimaging-scripts-guide.md

# 2. Regenerate the report + diff bundle.
python3 .internal/copilot-scripts/update-references.py --diffs
# Note the "Wrote individual diffs to /tmp/diffs/<TS>" line — copy that path.

DIFFS=/tmp/diffs/<TS>   # replace <TS> with the value just printed

# 3. Dry-run apply (does not touch files). Exits non-zero on any conflict.
git apply -p0 --check "$DIFFS"/*.diff && echo "OK: all patches apply cleanly"

# 4. Preview what would change without touching the tree (optional).
git apply -p0 --stat    "$DIFFS"/*.diff   # summary of hunks per file
git apply -p0 --numstat "$DIFFS"/*.diff   # added/removed line counts

# 5. Actually apply.
git apply -p0 "$DIFFS"/*.diff

# 6. Review the result.
git diff --stat                              # per-file changes
git diff -- reimaging-scripts-guide.md       # spot-check a specific file

# 7. If anything looks wrong, revert everything.
git checkout -- README.md references/ reimaging-guide.md reimaging-scripts-guide.md
```

**Notes**

- `-p0` is required because the diffs use full repo-root-relative paths (no
  `a/`/`b/` prefix).
- Individual files: `git apply -p0 "$DIFFS"/reimaging-guide.md-*.diff` if you
  want to stage one at a time.
- If a single diff fails, `git apply --reject -p0 <file>.diff` writes `.rej`
  sidecars next to conflicts so you can inspect them without aborting.

## Getting and testing a single combined patch

If you'd rather review one file than a bundle, use `--patch` instead of (or
alongside) `--diffs`.

```bash
# 1. Clean working tree.
git checkout -- README.md references/ reimaging-guide.md reimaging-scripts-guide.md

# 2. Generate a single combined patch.
python3 .internal/copilot-scripts/update-references.py \
    --patch /tmp/reports/update-references.patch

# 3. Review + dry-run apply.
less /tmp/reports/update-references.patch
git apply -p0 --stat  /tmp/reports/update-references.patch
git apply -p0 --check /tmp/reports/update-references.patch && echo "OK: patch applies cleanly"

# 4. Apply.
git apply -p0 /tmp/reports/update-references.patch

# 5. Revert if needed.
git checkout -- README.md references/ reimaging-guide.md reimaging-scripts-guide.md
```

`--patch` and `--diffs` are independent — pass both if you want both artifacts.

## What's next?

Some of these capabilities — link rewrites, prose token substitution, and
directory-tree rebuilds — could also plug into the prompts we use to migrate
a runbook or a script. Automating those touch-ups during migration reduces
the odds of shipping half-migrated content and cuts time spent patching
buggy code from a botched migration.
