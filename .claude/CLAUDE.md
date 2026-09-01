# CLAUDE.md

Guidance for Claude Code working in **fractogenesis-toolkit**. This file is a
pointer, not a second copy — the repository-specific instructions live in one
authoritative place and apply to Claude exactly as they do to Copilot.

## Read these first

- **Repo instructions:** `.github/copilot-instructions.md` — build/lint commands,
  architecture, conventions, and the loader/entrypoint/helper rules. (Named for
  Copilot's auto-load convention; the content is tool-agnostic.)
- **Runbook authoring:** `.github/ai-prompts/runbook-prompts/runbook-prompt.md`
  with `.github/ai-templates/runbook-templates/runbook-template.md.tmpl`.
- **Script authoring:** `.github/ai-prompts/script-prompts/bash-script-authoring-and-review.md`
  with `.github/ai-templates/script-templates/`.
- **Script placement:** `.github/guides/script-types-and-locations.md`.
- **Parked work:** `docs/gaps/` and `docs/sessions/` — read both before starting
  in an unfamiliar area, and write to `docs/gaps/` instead of widening the task
  when you find a second defect. Contents are gitignored; the rules are in
  `.github/copilot-instructions.md` section 4b.

Do not restate their contents here. When guidance changes, edit the source above
so there is one place to maintain.
