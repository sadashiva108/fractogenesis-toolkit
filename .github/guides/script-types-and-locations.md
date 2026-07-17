Script types and recommended locations

This file maps the script classifications used in the authoring prompts to where such files should live in the repository and how they should behave.

1) Foundation / config loader
- Location: .internal/loaders/ or .internal/config/
- Behavior: source-only files meant to be `source`d by other scripts. Must not call `exit` or change caller shell options. Use `return` on error and include a detailed header (usage, outputs, variables set). Example: .internal/load-reimage-config.sh

2) bin/ entrypoint (user-facing)
- Location: bin/
- Behavior: executable entrypoints that coordinate workflows. Use verb-first filenames and `set -euo pipefail`. Self-locate using BASH_SOURCE, load shared config loader, parse options, validate prerequisites, and print concise summaries and exit codes.

3) .internal/ pure helper
- Location: .internal/<domain>/ (e.g., .internal/helpers/ or .internal/git/)
- Behavior: focused implementation, accept explicit --root/--dest args, avoid loading shared config by default.

4) Aggregate validator / checklist
- Location: bin/ (user-invoked validators) or .internal/validators/ (helper pieces)
- Behavior: use `set -uo pipefail` (intentionally omit `-e`), convert failures into PASS/WARN/FAIL/SKIP records rather than aborting. Should not create the artifacts it verifies.

5) Bootstrap / environment creator
- Location (if runnable): bin/ (e.g., bin/setup-reimage-env.sh)
- Location (if sourced-only): .internal/bootstrap/
- Behavior: clearly document whether it is executable or source-only. If it's source-only, follow loader rules (return on error, do not change caller shell options). If executable, document usage and safe defaults; may create reimage.env.

6) Misc / helpers that may become entrypoints
- Placement: prefer .internal/ for helpers; migrate to bin/ only when intended to be user-facing.

Notes
- Prompts and templates: .github/copilot-prompts/ and .github/copilot-templates/ (discoverable to contributors). Script templates are templates (not executables) and belong in .github/copilot-templates/script-templates/.
- Migration mappings: use /tmp/mappings/ for ephemeral per-migration files. Move long-lived mappings to .github/copilot-templates/mappings/ if you decide to keep them.

If you'd like, the next steps I can take now:
- Move any remaining prompt/template files into .github as agreed, and update references in .github/copilot-instructions.md
- Create a short contributor checklist that enforces these placements when creating new scripts/runbooks

Which of those (if any) should I do next?