# Using Copilot on Fractogenesis-toolkit

Ran /init which created .github/copilot-instructions.md but additionally use this prompt for this session objective,
to create a runbook template and prompt.

## global instruction

# Implementation policy

- Prefer one authoritative path over duplicated paths.
- Prefer stable, consistent artifact locations.
- Avoid adding migration layers, aliases, wrappers, fallback logic, legacy code, backward-compatible code paths, backward-compatible documentation, or backward-compatible references unless explicitly requested.

# Working style

- When replacing an old path or workflow, update active references instead of preserving both.
- Do not keep transitional compatibility shims by default.
- If compatibility is required, explain why and keep the scope narrow.
```

## Starter Prompt

Work in the most token-efficient way that still gets the job done correctly.

For this session:
- keep responses concise and action-oriented
- prefer surgical edits over broad rewrites
- read only the files needed for the current step
- avoid re-reading large files when a targeted section or diff is enough
- batch related reads together before editing
- do not expand scope unless I ask
- ask only one clarifying question at a time, and only when the choice materially affects the implementation
- if the work naturally splits into phases, keep the current phase narrow
- if context starts getting heavy, tell me at a natural breakpoint that `/compact` would be a good idea
- if I shift to a different topic, recommend starting a new session with `/new`
- if I ask a quick side question, remind me that `/ask` can keep it out of the main history when appropriate

When you respond:
- lead with the result
- do not restate my request
- mention only the files changed or the decision made
- keep recommendations scoped to the current task

Current task: 
1. Create runbook prompt and template in a similar vein as was done for scripts.
2. Examine the existing runbooks to base the prompt and template on the guides are a bit different than the runbooks.
3. Add rules to prompt like:

- Has a back link to page that linked it
- Has a linked TOC that links to sections below the TOC
- Make the first section "Purpose"
- Make the next section "Artifact and Script Locations"

Artifacts are generated documents or captures written to $REIMAGE_ARTIFACT_ROOT
Backups are in a broader sense also artifacts as well

If you like a directory tree only show the subdirectories related to the steps of that runbook this is so there's a single source of truth and there will be less
to refactor if the directories or names change.

- Make the next section "Before You Run Anything" this will have subsections that should also be linked to TOC
- Make the next section "Sequential Steps" this will have subsections that should also be linked to TOC
- Optional next section "Supplemental Reference" this will have subsections that should also be linked to TOC

This is where lengthier content goes yet isn't essential to the "Before You Run Anything" sections.

- Optional next section "Sequential Steps" this will have subsections that should also be linked to TOC

4. Since I am in the process of migrating over reimage workflow files from another project I am improving them in several ways"
- better file names
- clarification of confusing steps
- improper sequencing gets addressed so dependencies don't follow what uses it
- robustness of scripts
- runbooks and scripts as well as the prose in either have a consistent vernacular
- both runbook names and scripts under /bin are often named the same but there are exceptions
- start with an action verb and then the entity the context is about
- reuse good patterns
- don't hardcode personal references
- Don't repeat the same information everywhere
- If a similar thing comes up then reference it but the thing has a single source of truth

Instructions, Prompts, and Templates: 
global instruction, 
$FRACTOGENESIS_HOME/.github/copilot-prompts/bash-script-authoring-and-review.md
$FRACTOGENESIS_HOME/.internal/templates/scripts/bash-entrypoint.sh.tmpl
$FRACTOGENESIS_HOME/.internal/templates/scripts/bash-helper.sh.tmpl

Guides and Runbooks: 
$FRACTOGENESIS_HOME/reimaging-guide.md
$FRACTOGENESIS_HOME/reimaging-scripts-guide.md
$FRACTOGENESIS_HOME/prepare-artifact-root.md
$FRACTOGENESIS_HOME/backup-repos.md
$FRACTOGENESIS_HOME/backup-home.md
$FRACTOGENESIS_HOME/backup-apps.md

References
$FRACTOGENESIS_HOME/references/backup-file-reference.md
$FRACTOGENESIS_HOME/references/backup-strategy-guide.md
$FRACTOGENESIS_HOME/references/restore-file-reference.md
$FRACTOGENESIS_HOME/references/restore-strategy-guide.md

Internal scripts
$FRACTOGENESIS_HOME/.internal/artifact-config.sh
$FRACTOGENESIS_HOME/.internal/load-reimage-config.sh
$FRACTOGENESIS_HOME/.internal/git/capture-repo-audit.sh
$FRACTOGENESIS_HOME/.internal/git/collect-gitignore-superset.sh
$FRACTOGENESIS_HOME/.internal/git/stage-ignored-files.sh
$FRACTOGENESIS_HOME/.internal/git/stage-selected-patterns.py

Entry point scripts
$FRACTOGENESIS_HOME/
$FRACTOGENESIS_HOME/bin/backup-apps.sh
$FRACTOGENESIS_HOME/bin/backup-docker-settings.sh
$FRACTOGENESIS_HOME/bin/backup-home.sh
$FRACTOGENESIS_HOME/bin/backup-intellij-scratches-consoles.sh
$FRACTOGENESIS_HOME/bin/backup-repos.sh
$FRACTOGENESIS_HOME/bin/capture-size-audit.sh
$FRACTOGENESIS_HOME/bin/prepare-artifact-root.py
$FRACTOGENESIS_HOME/bin/reimage-checklist.sh
$FRACTOGENESIS_HOME/bin/setup-reimage-env.sh

Artifact Config fragments
$REIMAGE_WORKSPACE_ROOT/artifact-config/expected-artifact-folders.conf.sh
$REIMAGE_WORKSPACE_ROOT/artifact-config/external-dotfiles.conf.sh
$REIMAGE_WORKSPACE_ROOT/artifact-config/external-excludes.conf.sh
$REIMAGE_WORKSPACE_ROOT/artifact-config/external-targets.conf.sh
$REIMAGE_WORKSPACE_ROOT/artifact-config/onedrive-extra-excludes.conf.sh
$REIMAGE_WORKSPACE_ROOT/artifact-config/onedrive-targets.conf.sh
$REIMAGE_WORKSPACE_ROOT/artifact-config/secret-flags.conf.sh
$REIMAGE_WORKSPACE_ROOT/artifact-config/secrets-targets.conf.sh
$REIMAGE_WORKSPACE_ROOT/artifact-config/skip-entries.conf.sh



Out of scope: Migration of runbooks, references, or scripts from reference-vault to fractogenesis-toolkit, just creating the runbook template and prompt at this time as well as a prompt or script to update references.

Definition of done: Runbook template and prompt created as well as a prompt or script to update references.

## Script Prompt and Templates in Fractogenesis-toolkit

script prompt: .github/copilot-prompts/bash-script-authoring-and-review.md
script templates:
.internal/templates/scripts/bash-entrypoint.sh.tmpl
.internal/templates/scripts/bash-helper.sh.tmpl

