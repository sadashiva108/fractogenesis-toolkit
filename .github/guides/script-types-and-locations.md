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
`reimage-checklist.sh`, `verify-artifact-config.sh`, `verify-doc-paths.sh`, and
`verify-script-portability.sh`.

**Loaders sit at the `.internal/` root, not in a `loaders/` subdirectory.**
There are two — `load-reimage-config.sh` and `artifact-config.sh` — and a
directory for two files that everything sources buys nothing. They resolve each
other relative to `BASH_SOURCE`, so moving one means editing the other.

**Helpers are grouped by domain, not by the word "helper".** The existing
domains are `ai-scripts/`, `apps/`, `certs/`, `git/`, `home/`, and
`performance/`. Add a new domain directory when a second helper in that area
appears; a lone helper can wait for a sibling before earning a directory of its
own. This holds for both helper classes — pure and standalone-capable helpers
sit side by side.

A domain is named for the material a helper works on, not always for the runbook
that calls it. `home/` holds both content scanners — `scan-archive-contents.sh`
and `scan-postman-collections.py` — because they scan the artifact root the same
way and co-own one output, even though `backup-apps.md` invokes the second one.
Splitting a pair like that across two domains to match their callers would put a
shared output contract on either side of a directory bookend.

**A helper graduates to `bin/` only when it becomes user-facing** — that is,
when a runbook tells the reader to run it directly. Until then it stays in
`.internal/` and is invoked with explicit arguments by an entrypoint.

**Runbook and executable share a name.** `bin/backup-home.sh` pairs with
`backup-home.md` at the repo root.

**Bookend recorders come in pairs.** `bin/record-restore-prereqs.sh` and
`bin/record-restore-exit.sh` are entry and exit for the same phase. They share
option parsing, path guards, and row recording.

That duplication was deliberate while there were two — extracting a shared
library for a pair invites indirection before the pattern is proven — and the
stated trigger was a third recorder appearing. **It has.** Four scripts now share
the shape: those two, `bin/compare-restored-state.sh`, and
`bin/record-restore-state.sh`. `usage`, `require_option_value` and
`absolute_path` are byte-identical across all four, and `resolve_java_home` and
`squash_ws` have already drifted — same name, different bodies, with nothing
detecting it. Drift is the argument for extraction stated more sharply than any
principle. The extraction is agreed and pending; until it lands, a fix to any of
those functions belongs in all four copies.

**The prerequisite-recorder carve-out is gone.** An earlier version of this
guide exempted `record-restore-prereqs.sh` from the graduation rule, on the
grounds that it was "one implementation shared across every restore phase" and
that "the restore entrypoints call it at startup too". Measured against the
tree, neither was true: no `bin/restore-*.sh` referenced it at all, and two of
eleven post-image runbooks invoked it. An exception resting on two false
statements was removed rather than repaired, and the graduation rule now applies
unamended — which puts all three restore recorders in `bin/`, where the runbooks
were already telling readers to run them.

The general lesson outlives the specific case: an exception to a rule states
facts, and facts can be checked. Check them before writing one, and again when
the exception is cited.

**`capture-`, `record-` and `report-` are not synonyms.** All three write
evidence, and the prefix is the only thing that says which kind:

- `capture-` — a paired pre-image / post-image inventory of *system state*, re-run
  after the reimage so the two can be compared. Every `capture-*` script has a
  Phase 13 sibling; there are no exceptions.
- `record-` — one-time evidence that a specific *operation* succeeded, with no
  later counterpart to compare against: `record-enrollment.sh`,
  `record-reimaged-system.sh`, `record-time-machine-evidence.sh`.
- `report-` — leaves a durable, timestamped `*-reports/` directory under the
  artifact root that later steps and the Phase 6B sign-off read back:
  `report-size-audit.sh` → `size-audit-reports/`, `report-loose-secrets.sh` →
  `loose-secrets-reports/`. The prefix names the output, not the caller count —
  one of these is cross-cutting and the other is owned by a single runbook.
- `verify-` / `check-` — validators that produce no artifact at all.

Reach for `capture-` only when a post-image run of the same script is part of the
workflow. If there is nothing to compare against, it is a `record-`. If it leaves
a reports directory behind, it is a `report-`.

**A runbook may own more than one `bin/` script.** The name pairing identifies
the *primary* entrypoint, not the complete set. `restore-access.md` is the widest
case: `bin/restore-access.sh` drives the phase, and `restore-staged-loose.sh`,
`record-restore-state.sh`, `record-restore-prereqs.sh` and
`record-restore-exit.sh` are all named by its steps. The last two are shared with
`restore-runtime.md`, which is what `--phase` is for — a script called by more
than one runbook is owned by neither in the naming sense, and its name says what
it does rather than which phase runs it. `stage-loose-secrets.md` owns
both `stage-loose-secrets.sh` and `report-loose-secrets.sh` — one acts, one
reports read-only, and splitting them is what keeps the reporting side safe to
run at any time. `backup-home.md` likewise owns `verify-artifact-config.sh`.
A second script belongs to the runbook that tells the reader to run it.

**Cross-cutting utilities have no owning runbook at all** — the third population
in *Reading `bin/`* below — and are the deliberate exception to the pairing — `report-size-audit.sh` (called by six runbooks),
`verify-doc-paths.sh`, and `verify-script-portability.sh` are the current ones.
The test is how many runbooks *call* it, not how much ground
it covers: `report-loose-secrets.sh` examines material produced by six earlier
phases but is invoked from exactly one runbook, so it is owned, not
cross-cutting.

The last two are called by no runbook at all, which is a second shape of
cross-cutting: they enforce conventions the repository depends on rather than
performing a workflow step, so they run after an edit rather than at a phase.
`verify-doc-paths.sh` catches a documented path that stopped resolving;
`verify-script-portability.sh` catches a construct that works on the shell the
author had and not on the Bash 3.2 the workflow reaches in Phases 8 and 9.

**Migration mappings are ephemeral.** Keep them in `/tmp/` for the duration of a
migration. Nothing has needed to outlive one so far, so there is no committed
location for them; add one when something actually does.

## Reading `bin/`

`bin/` holds more scripts than the repo has runbooks — 39 against 26 at the time
of writing — and that ratio is the intended one, not drift. Three things drive
it: a runbook may own more than one script, a script may serve several runbooks,
and two enforce conventions rather than perform a workflow step. Expect the gap
to widen, not close.

The flat listing hides that, so here is how to read it.

**Three populations, told apart by how many runbooks call the script.**

| Population | Runbooks that call it | What it is | Examples |
|---|---|---|---|
| Owned entrypoint | exactly 1 | A command belonging to one phase. Name-paired with its runbook where the runbook has a primary entrypoint. | `capture-managed-inventory.sh`, `restore-access.sh`, `restore-staged-loose.sh` |
| Shared | 2 or more | One implementation several phases parameterise, usually by `--phase` or `--context`. Owned by no runbook in the naming sense; its name says what it does, not which phase runs it. | `report-size-audit.sh` (8), `prepare-artifact-root.py` (5), `record-restore-prereqs.sh` (2) |
| Cross-cutting utility | 0 | Enforces a repository convention rather than performing a workflow step. Run after an edit, not at a phase. | `verify-doc-paths.sh`, `verify-script-portability.sh` |

Shared is the **majority** — 22 of 39. That is worth stating plainly, because the
name-pairing convention reads like the norm and is not: only eight scripts are
name-paired with a runbook. Pairing identifies a primary entrypoint where one
exists; it was never a claim about the whole directory. A script being called by
a second runbook is ordinary and is not a signal that it belongs somewhere else —
`backup-home.sh` is called by three runbooks and is still `backup-home.md`'s
entrypoint.

**The verb prefix is the at-a-glance grouping.** `ls bin/` sorts alphabetically,
which sorts by prefix, which groups by kind of work: `backup-`, `capture-`,
`check-`, `compare-`, `create-`, `init-`, `prepare-`, `record-`, `reimage-`,
`report-`, `restore-`, `run-`, `setup-`, `stage-`, `verify-`, `watch-`. The
three largest families are `restore-`, `record-` and `capture-`, at six each.
That ordering is the reason the naming rules above are worth following: they are
what makes a flat directory scannable.

**Do not paste an inventory of `bin/` into a document.** A frozen list drifts
from the directory the first time a script is added, and a stale list is worse
than none because it is believed. Compute the current classification instead:

```bash
for script in bin/*; do
  name="$(basename "$script")"
  callers="$(grep -lF "bin/$name" ./*.md 2>/dev/null \
    | grep -vE '(APPLY-MANIFEST|reimaging-guide|reimaging-scripts-guide|reimage-guide-access|README)\.md$' \
    | wc -l | tr -d ' ')"
  case "$callers" in
    0) kind="utility" ;;
    1) kind="owned  " ;;
    *) kind="shared " ;;
  esac
  printf '%s  %-32s %s\n' "$kind" "$name" "$callers"
done | sort
```

The guides are excluded because they reference nearly every script by design;
counting them would classify everything as shared.

**A script does not move because it is shared.** `.internal/` means sourced-only
and not run directly. Every script in `bin/` is one a runbook tells the reader to
run, whether one runbook or eight, so sharing is not grounds for relocating it —
that was the reasoning behind the prerequisite-recorder carve-out, and it did not
survive being measured.

## Before adding a directory

Every directory here exists because files are in it. Do not create a directory
in anticipation of files — an empty or single-file directory that a document
promised is worse than no directory, because the next session trusts the
document and puts things somewhere the tooling does not look.

Run `./bin/verify-doc-paths.sh` after moving or renaming anything this guide
names. It fails when a documented path no longer resolves.
