# AI authoring prompts

Prompts and templates for AI-assisted authoring in this repo. Use them to
create a new runbook or update an existing one, and to author or review the
bash scripts that back those runbooks. Each prompt points at the template it
fills; the prompt and template are the source of truth for structure and
rules, so this README stays a pointer and does not restate them.

## Create or update a runbook

Feed the runbook fill prompt together with the runbook template. It produces a
new runbook — or reworks an existing one — following the repo's canonical
structure: a backlink to the page that linked it, a linked table of contents,
then `Purpose`, `Artifact and Script Locations`, `Before You Run Anything`,
`Sequential Steps`, and an optional `Supplemental Reference`.

- Prompt: `.github/ai-prompts/runbook-prompts/runbook-prompt.md`
- Template: `.github/ai-templates/runbook-templates/runbook-template.md.tmpl`

## Author or review a script

- Prompt: `.github/ai-prompts/script-prompts/bash-script-authoring-and-review.md`
- Templates: `.github/ai-templates/script-templates/` (`bash-entrypoint.sh.tmpl`, `bash-helper.sh.tmpl`)
- Placement rules: `.github/guides/script-types-and-locations.md`

## Repo conventions

Repository-wide build/lint commands, architecture, naming, and the
implementation and working-style policy live in
`.github/copilot-instructions.md`. Read that first; do not duplicate it here.
