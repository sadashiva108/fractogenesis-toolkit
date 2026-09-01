# Copilot instructions for fractogenesis-toolkit

Purpose
- Provide concise repository-specific guidance for future Copilot sessions working on fractogenesis-toolkit.

1) Build / test / lint commands
- This repository is documentation + shell/python runbooks; there is no build system, CI config, or automated test suite committed.
- Run a single entrypoint script (from the repo root):
  - ./bin/backup-apps.sh
  - bash -n ./bin/backup-apps.sh  # syntax-only check
  - bash -x ./bin/backup-apps.sh  # debug with tracing
- Python helper: python3 ./bin/prepare-artifact-root.py --help (or run directly)
- Linting guidance (recommended):
  - Use `bash -n` for quick syntax checks on shell scripts.
  - Run `shellcheck` when available (recommended but avoid making it a declared runtime dependency):
    - shellcheck -x bin/*.sh .internal/**/*.sh
  - For Python, use your usual project linter (e.g., ruff/flake8) if desired; none are enforced here.
  - Documentation lint: ./bin/verify-doc-paths.sh checks that the repository paths named in the governance docs still exist. Run it after moving or renaming any file that the docs point at, and after editing the docs themselves — a stale path silently misdirects the next session.
  - Loose-secret sweep (Phase 3B, stage-loose-secrets.md): ./bin/report-loose-secrets.sh reports credential-shaped files sitting in plaintext outside secrets-encrypted/; ./bin/stage-loose-secrets.sh moves them inside it. Run the check, then the stager (dry-run by default, --apply to move), then the check again — all before Phase 3C builds the DMG, since 3C encrypts secrets-encrypted/ and nothing else. The check never modifies what it scans and saves each run to $REIMAGE_ARTIFACT_ROOT/loose-secrets-reports/ (--no-report to suppress).
  - Runbook structure lint: ./bin/verify-runbook-structure.sh checks the structural house rules the authoring prompt defines — Sequential Steps is an H2, every step is `### Step N — Title` numbered consecutively, every step ends with a back-link and divider, every step is in the Table of Contents, no `[!note]` callouts, the Pitfall budget, the callout legend, balanced code fences, and no orphaned quote lines. These drift silently: a runbook written before a rule existed keeps passing every other check in the repo. Run it after editing any runbook.
  - Portability lint: ./bin/verify-script-portability.sh flags Bash 4+ syntax and GNU-only userland flags that the macOS target rejects. Run it after editing any bin/ or .internal/ script, and after moving an inline runbook block into a script — that move changes the target shell from the operator's interactive zsh to the Bash 3.2 that `#!/usr/bin/env bash` resolves to in Phases 8 and 9, before Phase 10A installs Homebrew.
  - An AI session is almost certainly NOT running on macOS. Every shell available to one is Linux with GNU coreutils and Bash 5.x, where `mapfile`, `declare -A`, `sed -i`, and `stat -c` all work silently. Name the environment a check ran in rather than reporting it as verified — "tested on Linux" and "tested on the target Mac" are different claims. On the Mac, `/bin/bash -n` catches parse errors against the real 3.2; the portability lint catches the runtime-level constructs `-n` cannot see. The two are complements, not substitutes.
  - Secret shapes are defined once: SECRET_SHAPES_FLOOR in .internal/artifact-config.sh, extended (never reduced) by the optional secret-shapes.conf.sh fragment. Both scripts above read it via build_secret_shape_predicate. Do not add a private pattern list to a script — that drift is what let credential-shaped files reach home-files-backup/ in the clear.

2) High-level architecture (big picture)
- Runbook-driven workflow: Markdown runbooks (top-level .md files) sequence the reimage phases and document the rationale and manual steps.
- bin/: user-facing entrypoints. Each bin/<name>.sh (or .py) implements the runnable step described by its matching runbook <name>.md.
- .internal/: sourced-only helpers, templates, and config fragments. These are intended to be sourced by entrypoints or other internal helpers and should not be run directly.
- templates/: committed templates and sign-off cheatsheets used by runbooks and scripts.
- reimage.env.example + reimage.env: example/template tracked; reimage.env is local, machine-specific, and must NOT be committed.
- prepare-artifact-root.py self-locates the repo root and centralizes env/artifact-root logic; scripts rely on self-location rather than a REIMAGE_ROOT variable.
- .share/: reserved for genuinely cross-repo shared scripts (empty until needed).

3) Key conventions and patterns
- Naming: runbooks and their executable share the same name (backup-apps.md ↔ bin/backup-apps.sh). Runbook and script filenames are verb-first: prepare-, backup-, capture-, record-, report-, restore-, run-, stage-, enroll-, validate-. Three are easily confused: capture- is a paired pre-image/post-image state inventory with a Phase 13 sibling, record- is one-time evidence of an operation, report- leaves a durable *-reports/ directory the workflow reads back. See .github/guides/script-types-and-locations.md.
- Execution semantics:
  - Always run scripts from the repository root unless a script documents explicit absolute-path invocation.
  - Runbook command examples assume this repo-root working directory — stated once in reimaging-guide.md → Core Assumptions and each runbook's Prerequisites. Do not prefix command blocks with `cd "$FRACTOGENESIS_HOME"`; command blocks start at the command.
  - Phase boundaries are recorded, not just described. `record-restore-prereqs.sh --phase <p>` runs at a phase's Step 0 and answers "may this start"; `record-restore-exit.sh --phase <p>` runs at its final step and answers "did it finish". One check per boundary: a phase never runs the next phase's entry check, and never re-checks its own entry at the end. Both write dated, indexed runs into one category — `reimaged-system/boundaries/` — so a single `MANIFEST.md` answers whether a phase both started and finished, and a question asked three days later has an answer.
  - Prerequisites declares; Step 0 verifies. `### Prerequisites` states preconditions in prose and contains no commands. A phase whose preconditions can fail *silently* opens Sequential Steps with `### Step 0 — Record Prerequisites`, which runs the recorder and writes an artifact. Number it 0 because it gates rather than advances, is rerunnable at any point, and adding one renumbers nothing. Omit it where a phase has no precondition worth checking.
  - Entrypoints should self-locate via BASH_SOURCE and then load .internal/load-reimage-config.sh.
  - reimage.env must contain resolved absolute values only. Do not commit reimage.env. Keep only reimage.env.example committed.
- Loader vs helper rules (important for edits and AI-driven changes):
  - Sourced loaders (.internal/load-*.sh) must not use `exit` and must avoid setting strict shell options that change the caller environment. Use `return` for failures.
  - Entry points (bin/*.sh) should use `set -euo pipefail` (unless intentionally a validator) and print concise summaries and meaningful exit codes.
  - Helpers in .internal/ should prefer explicit CLI args (--root, --dest) and be safe to run standalone when arguments are supplied.
- Portability: remain compatible with macOS stock Bash 3.2 unless a script explicitly opts into newer Bash; avoid associative arrays, mapfile, GNU-only options; prefer NUL-delimited traversal for file lists.
- Safety: Do not introduce hardcoded personal or company paths, secrets, or live placeholder paths. Preserve existing behavior unless a change request explicitly asks to alter workflow-level artifact naming or retention.
- Version control (applies to every AI session):
  - The repository owner reviews and commits every change. Leave your work uncommitted in the working tree.
  - Do not run `git commit`, `git push`, `git add`, or any history-rewriting command. Write the files, report what changed and what you validated, and stop there.
  - Because the owner always commits, the working-tree diff is the review surface. Keep it clean: edit files in place rather than leaving `.bak` copies, timestamped duplicates, `.incoming` staging files, or parallel "new" versions beside the originals.
  - Do not change file modes as a side effect of an edit. When a write drops the executable bit on a `bin/` script, restore it (`chmod 755`) so the diff carries content changes only.

4) Files and docs to read first (AI sessions)
- README.md
- reimaging-guide.md and matching runbook <phase>.md for the area being changed
- bin/<target>.sh and its matching <target>.md
- .internal/load-reimage-config.sh
- .internal/artifact-config.sh and the fragments under .internal/templates/artifact-config/
- .github/ai-templates/script-templates/*.tmpl (bash-entrypoint.sh.tmpl, bash-helper.sh.tmpl)
- reimage.env.example
- .github/ai-prompts/script-prompts/bash-script-authoring-and-review.md (authoring/review rules)

4b) docs/ -- parked work, not repository content

Three directories, tracked but with their contents gitignored. They exist so a
note has an obvious home and does not become a line in a chat log nobody reads
again.

- docs/features/ -- ideas and features to build later.
- docs/gaps/     -- defects and must-dos found while working on something else,
                    parked so the current task stays finished.
- docs/sessions/ -- session handoffs, and the prompts that start the next session.

Rules for an AI session:
- WRITE here rather than widening the task. Finding a second defect while fixing
  the first is normal; fixing both in one change is how a small edit becomes an
  unreviewable one. Note it in docs/gaps/ and say so in the summary.
- READ docs/gaps/ and docs/sessions/ before starting work in an area -- the
  answer to "why is this half-done" is often already written down.
- These files are NOT tracked. Anything that must survive a fresh clone belongs
  in APPLY-MANIFEST.md or the runbook it concerns, not here.
- One file per item, named for the thing rather than the date. A dated filename
  sorts by when someone noticed, which is never the question being asked.

5) Other AI assistant configs
- .claude/CLAUDE.md — pointer only; it routes Claude sessions to this file and to the .github/ai-prompts and .github/ai-templates sets. Keep guidance here, not there.
- No AGENTS.md, .cursorrules, or .windsurfrules. If one is added, make it a pointer to this file rather than a second copy of these rules.

Notes on edits and automation
- Small, surgical changes preferred. When asked to refactor or edit Bash scripts, follow the classification and loader/entrypoint/helper requirements documented in .github/ai-prompts/script-prompts/bash-script-authoring-and-review.md.
- Recommended lightweight validation after edits:
  - bash -n path/to/edited.sh
  - shellcheck -x path/to/edited.sh (if available)
  - For Python edits: python -m pyflakes or ruff if present locally

If anything here should be expanded (e.g., include more runbook summaries or per-script quick usage examples), say which area and a short list of the scripts or runbooks to prioritize.

6) Session prompts & templates (runbooks)
- Runbook template: .github/ai-templates/runbook-templates/runbook-template.md.tmpl — canonical template with YAML header, TOC anchors, and guidance for artifact/script locations.
- Runbook prompt: .github/ai-prompts/runbook-prompts/runbook-prompt.md — structured prompt Copilot should use to populate the template when creating a new runbook or bringing an existing one up to current conventions (auto-detects env keys).
- Script authoring prompt: .github/ai-prompts/script-prompts/bash-script-authoring-and-review.md — rules for editing or creating bin/ entrypoints and .internal helpers.
- Script templates: .github/ai-templates/script-templates/ (bash-entrypoint.sh.tmpl, bash-helper.sh.tmpl)

Quick usage note for Copilot sessions:
- When asked to create or update a runbook, use the runbook prompt and target the template above. Include a short human-review checklist.
