# CLAUDE.md

> **Role.** A pointer, for Claude. It names where the rules live and **must never
> restate them** — the instruction sets are under `.github/` because this
> repository is worked by Copilot as well.
>
> **Authoritative for** nothing. **Rank 4** of 6. Order in
> [`../.github/copilot-instructions.md`](../.github/copilot-instructions.md).

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
- **Session management:** `.github/session-management-instructions.md` and
  `docs/legend.md` — how sessions, findings bundles, statuses and states work.
  **Required reading before any write under `docs/`.** The conformant session
  prompt is `.github/ai-prompts/session-management/conformant-prompt.md`.
- **Parked work:** the findings indexes under `docs/runbook-findings/`,
  `docs/cross-cutting-findings/`, `docs/instruction-set-findings/` and
  `docs/session-management-findings/`, and `docs/sessions/` — read them before
  starting in an unfamiliar area, and park a second defect as a findings bundle
  instead of widening the task. All of `docs/` is tracked.

Do not restate their contents here. When guidance changes, edit the source above
so there is one place to maintain.
