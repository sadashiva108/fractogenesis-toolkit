# Script types and locations

Where a new script belongs, by what kind of script it is.

This guide answers placement only. The behavior each class must follow —
strict-mode choice, loader contract, option handling, output conventions — lives
in `.github/ai-prompts/script-prompts/bash-script-authoring-and-review.md`, and
the repository-wide conventions live in `.github/copilot-instructions.md`. Read
those for the rules; read this to decide which directory a file goes in.

## Scripts

The six script classes, named exactly as
`.github/ai-prompts/script-prompts/bash-script-authoring-and-review.md` names
them. That prompt says how each class must behave; this table says only where it
goes. Classify once, using its names, and both questions are answered.

| Class | Goes in | Example |
|---|---|---|
| `bin/` entrypoint | `bin/<verb-first-name>.sh` | `bin/backup-home.sh` |
| `.internal/` pure helper | `.internal/<domain>/` | `.internal/git/stage-selected-patterns.py` |
| `.internal/` standalone-capable helper | `.internal/<domain>/` | `.internal/apps/app-selection.sh` |
| Foundation/config loader | `.internal/` root | `.internal/load-reimage-config.sh` |
| Aggregate validator/checklist | `bin/` | `bin/verify-artifact-config.sh` |
| Bootstrap/environment creator | `bin/`, or repo root when it must run pre-clone | `bin/setup-reimage-env.sh`, `bootstrap.sh` |

The two helper classes share a directory on purpose: what separates them is
whether they load shared config, which is a behavior question, not a placement
one. Both live under the domain they serve.

## Everything that is not a script

| Kind | Goes in | Example |
|---|---|---|
| Config fragment or generated-file template | `.internal/templates/<set>/` | `.internal/templates/artifact-config/` |
| Sign-off / document template | `templates/` | `templates/it-reimage-confirmation-template.md` |
| Authoring template for new scripts | `.github/ai-templates/script-templates/` | `bash-entrypoint.sh.tmpl` |
| Genuinely cross-repo script | `.share/` | *(empty — nothing has earned it yet)* |

## Notes on the less obvious rows

**Entrypoints and validators share `bin/`.** A validator is user-invoked, so it
belongs beside the other entrypoints; what distinguishes it is behavior — it
records PASS/WARN/FAIL/SKIP rather than aborting, so it may omit `set -e`. The current validators are `check-reimage-env.sh`,
`reimage-checklist.sh`, `verify-artifact-config.sh`, and `verify-doc-paths.sh`.

**Loaders sit at the `.internal/` root, not in a `loaders/` subdirectory.**
There are two — `load-reimage-config.sh` and `artifact-config.sh` — and a
directory for two files that everything sources buys nothing. They resolve each
other relative to `BASH_SOURCE`, so moving one means editing the other.

**Helpers are grouped by domain, not by the word "helper".** The existing
domains are `ai-scripts/`, `apps/`, `certs/`, `git/`, and `performance/`. Add a
new domain directory when a second helper in that area appears; a lone helper
can wait for a sibling before earning a directory of its own. This holds for
both helper classes — pure and standalone-capable helpers sit side by side.

**A helper graduates to `bin/` only when it becomes user-facing** — that is,
when a runbook tells the reader to run it directly. Until then it stays in
`.internal/` and is invoked with explicit arguments by an entrypoint.

**Runbook and executable share a name.** `bin/backup-home.sh` pairs with
`backup-home.md` at the repo root.

**A runbook may own more than one `bin/` script.** The name pairing identifies
the *primary* entrypoint, not the complete set. `stage-loose-secrets.md` owns
both `stage-loose-secrets.sh` and `report-loose-secrets.sh` — one acts, one
reports read-only, and splitting them is what keeps the reporting side safe to
run at any time. `backup-home.md` likewise owns `verify-artifact-config.sh`.
A second script belongs to the runbook that tells the reader to run it.

**Cross-cutting utilities have no owning runbook at all** and are the deliberate
exception to the pairing — `capture-size-audit.sh` and `verify-doc-paths.sh` are
the current ones. The test is how many runbooks *call* it, not how much ground
it covers: `report-loose-secrets.sh` examines material produced by six earlier
phases but is invoked from exactly one runbook, so it is owned, not
cross-cutting.

**Migration mappings are ephemeral.** Keep them in `/tmp/` for the duration of a
migration. Nothing has needed to outlive one so far, so there is no committed
location for them; add one when something actually does.

## Before adding a directory

Every directory here exists because files are in it. Do not create a directory
in anticipation of files — an empty or single-file directory that a document
promised is worse than no directory, because the next session trusts the
document and puts things somewhere the tooling does not look.

Run `./bin/verify-doc-paths.sh` after moving or renaming anything this guide
names. It fails when a documented path no longer resolves.
