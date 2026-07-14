# Reimage Toolkit Bash Script Authoring and Review Prompt

Use this prompt when asking an AI to create, refactor, review, or migrate Bash scripts in `fractogenesis-toolkit`.

---

You are maintaining the Mac reimage workflow in `fractogenesis-toolkit`. The workflow is sequential and runbook-driven: Markdown runbooks provide background and execution steps, `bin/` contains user-facing entrypoints, and `.internal/` contains focused helpers and shared configuration.

## Task

Describe the requested work here:

> TODO: State whether the AI should review only, propose changes first, or edit files now. List the target scripts and the associated runbook/phase.

## Files to inspect first

Before proposing or making changes, inspect the target script, its calling runbook, its invoked helpers, and these foundation files when available:

- `.internal/load-reimage-config.sh`
- `.internal/artifact-config.sh`
- `reimage.env.example`
- `.envrc`
- `.internal/templates/scripts/bash-entrypoint.sh.tmpl`
- `.internal/templates/scripts/bash-helper.sh.tmpl`

Also inspect any config fragments, manifests, checklists, or sibling scripts that define the same paths or outputs. Do not infer their behavior from filenames alone.

## Classify the script before editing

Classify each target as one of the following and explain the classification briefly:

1. **`bin/` entrypoint** — user-facing workflow coordination, shared-config loading, argument overrides, validation, helper invocation, summary, and meaningful exit status.
2. **`.internal/` pure helper** — focused implementation receiving required paths/options explicitly; shared config is not loaded by default.
3. **`.internal/` standalone-capable helper** — focused implementation that may load shared config because direct standalone use has a documented need for config-backed defaults.
4. **Foundation/config loader** — sourced code that must not behave like a normal executable.
5. **Aggregate validator/checklist** — records all checks and therefore may intentionally omit `set -e`.
6. **Bootstrap/environment creator** — may be an explicit exception because it creates `reimage.env` or must work before normal config exists.

Do not force every file into the same loading or strict-mode pattern.

## Configuration model

Preserve this architecture unless the task explicitly changes it:

- Scripts self-locate from `BASH_SOURCE`; do not reintroduce a configurable `REIMAGE_ROOT`.
- `reimage.env` contains local, resolved values only.
- `.envrc` is an optional interactive convenience. Scripts must work without `direnv`, without `.envrc` being allowed, and from a fresh shell.
- The shared loader resolves `.internal/artifact-config.sh` relative to itself.
- Effective precedence should be:
  1. Explicit CLI options for the current invocation.
  2. Values already exported by the caller, including optional `.envrc` values.
  3. Values loaded from `reimage.env`.
  4. Defaults in `artifact-config.sh`.
- Reusable artifact-config fragments should come from an explicit `ARTIFACT_CONFIG_DIR`, then the workspace copy under `$REIMAGE_WORKSPACE_ROOT/artifact-config/` when present, then committed templates.
- Use `REIMAGE_ARTIFACT_ROOT`, `EXTERNAL_DATA_VOLUME`, configured Git roots, OneDrive variables, and other shared names instead of hardcoded `/Volumes/Data` or user-specific workspace paths.
- A CLI option such as `--artifact-root` may override the loaded value after config loading.
- If a script needs `--env-file`, handle it as an early bootstrap option before loading shared config, or use `REIMAGE_ENV=/path/to/file command`. Do not pretend an env-file option parsed after loading affects the already-loaded config.

## Foundation/config loader requirements

For a source-only file such as `.internal/load-reimage-config.sh`:

- Do not force it into the normal helper template or executable lifecycle.
- Include a complete source-usage header and document caller controls, loaded outputs, and return status.
- Reject direct execution when the file has no valid standalone behavior.
- Do not call `set -e`, `set -u`, or `set -o pipefail`; a sourced file must not change caller shell options.
- Namespace implementation variables and clean them up before returning.
- Preserve caller variables when downstream sourced files currently reuse generic names such as `SCRIPT_DIR` or `REPO_ROOT`.
- Use `return` for loader-level failures instead of `exit`, because `exit` can terminate an interactive shell or parent entrypoint.
- Resolve sibling foundation files from `BASH_SOURCE[0]`; never depend on the caller's working directory.
- Do not source `.envrc`; it remains an optional interactive convenience.

## Entrypoint requirements

For a normal `bin/*.sh` entrypoint:

- Start with a complete header comment containing purpose, runbook/phase context, usage examples, options, configuration precedence, and exit status.
- Use marker-based usage extraction; do not use fragile `head -40` or similar line counts.
- Use `set -euo pipefail` unless the script is an aggregate validator.
- Self-locate `SCRIPT_DIR` and `REPO_ROOT`.
- Load `.internal/load-reimage-config.sh` and validate that it exists.
- Parse parameterized options with explicit missing-value checks.
- Prefer repeatable options for multiple roots.
- Apply CLI overrides without mutating `reimage.env`.
- Validate required paths and commands before destructive or long-running work.
- Invoke helpers with explicit arguments.
- Do not run `chmod` on helpers during normal execution; invoke with `bash` or rely on committed executable bits.
- Keep detailed discovery/copy logic in `.internal/` when practical.
- Print a concise final summary with primary output paths.
- Return `2` for usage/config/prerequisite errors and a meaningful nonzero status for runtime failure.

## Helper requirements

For a normal `.internal/` helper:

- Include a complete header even when normally called by an entrypoint.
- State whether shared config is intentionally loaded or intentionally not loaded.
- Prefer explicit `--root`, `--dest`, template, exclude-list, and mode arguments over hidden ambient state.
- Keep the helper focused on one implementation concern.
- Allow safe standalone execution when all required arguments are supplied.
- Write durable dry-run evidence when the workflow requires review before copy.
- Do not silently create a different root/default policy from the calling entrypoint.
- Avoid output-opening/UI behavior unless standalone use specifically requires it.

## Strict mode and validator behavior

Use:

```bash
set -euo pipefail
```

for normal operational scripts.

Use:

```bash
set -uo pipefail
# NOTE: intentionally NOT set -e. ...
```

only for aggregate validators/checklists where failed commands must be converted into PASS/WARN/FAIL/SKIP records instead of aborting the run.

A validator should generally observe and report state. It may create its own report destination, but it should not create the directories or artifacts it is supposed to verify.

## macOS and Bash portability

Unless a script explicitly checks for and requires a newer Bash, remain compatible with the stock macOS Bash 3.2:

- Do not use `mapfile` or `readarray`.
- Do not use associative arrays.
- Do not assume GNU `sed`, `find`, `stat`, `date`, `timeout`, or coreutils behavior.
- Use `BASH_SOURCE`, indexed arrays, loops, process substitution, and macOS-compatible command forms.
- Use NUL-delimited traversal when filenames may contain whitespace or unusual characters.
- Validate optional commands before using them.

Run at least:

```bash
bash -n path/to/script.sh
```

Also run `shellcheck` when available, but do not make it an undeclared runtime dependency.

## Safety and behavior preservation

- Preserve existing behavior unless the task explicitly requests a behavior change.
- Point out bugs separately from formatting inconsistencies.
- Never copy secret-bearing ignored files merely because they matched an include pattern; preserve the workflow’s later encrypted-secrets handling and review boundaries.
- Use dry-run-first behavior for copying/staging operations unless the runbook explicitly says otherwise.
- Validate that destination paths are beneath the intended artifact root when that is a safety invariant.
- Do not add live placeholder paths such as `<personal-projects-dir>` to executable checks.
- Do not hardcode a current user, company path, external volume name, or repository checkout path.

## Timestamped outputs, snapshots, and manifests

Do not introduce, rename, consolidate, or normalize any of the following without first presenting specific options and tradeoffs for that workflow step:

- Timestamped run directories
- Timestamped files
- Stable `MANIFEST.md` files
- Per-run manifests
- `latest` files or symlinks
- Snapshot retention or cleanup rules
- Overwrite-versus-append behavior

The reimage workflow uses several different artifact lifecycles. Treat output naming and retention as a deliberate runbook-level design decision, not a generic script-formatting rule.

## Review process

When the user asks for suggestions before changes:

1. Do not edit files yet.
2. Identify behavior bugs, portability problems, hardcoded paths, config-precedence issues, and formatting inconsistencies separately.
3. Recommend the smallest coherent change set.
4. Call out decisions that need discussion, especially output/manifest/timestamp policy.
5. Wait for the user’s direction before generating modified files.

When the user asks for edits now:

1. Make the changes in the requested files.
2. Keep the calling runbook and usage examples synchronized.
3. Run syntax/static checks available in the environment.
4. Report files changed, important behavior changes, checks performed, and unresolved decisions.
5. Provide downloadable files or a patch as requested.

## Expected response format

Provide:

1. **Classification and findings**
2. **Recommended design**
3. **Files to change**
4. **Behavior changes versus formatting-only changes**
5. **Validation performed**
6. **Open decisions deliberately deferred**

Do not spend the response repeating generic Bash advice. Ground every recommendation in the supplied runbook, scripts, shared config, and current artifact layout.
