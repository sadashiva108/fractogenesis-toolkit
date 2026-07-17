# Runbook fill prompt — guidance for Copilot

Purpose
- Guide Copilot to populate .github/copilot-templates/runbook-template.md.tmpl for a specific runbook in this repo. Designed for both migration and new-runbook creation.

When to use
- Use when authoring, migrating, or reformatting a runbook. Supports:
  - Migrating content from a source repo (e.g., reference-vault) into this template
  - Creating a new runbook from scratch using minimal inputs
  - Reflowing existing runbook prose to match fractogenesis-toolkit conventions

Migration source (recommended scan path)
- If migrating, pre-read files under: /Users/dkittrell/Development/documentation/reference-vault/workflows/mac/reimage
  - Use source files as content candidates; prefer single authoritative source for each topic.

Inputs (provide these as structured key/value data before asking Copilot to fill)
- title (string) — preferred, used in YAML header
- RUNBOOK_TITLE (fallback)
- BACK_LINK (relative link back to the page that linked this runbook)
- RUNBOOK_SHORT_DESC (1–2 sentence summary)
- PRIMARY_SCRIPT or PRIMARY_SCRIPTS (path(s) under bin/ or .py entrypoint)
- RELATED_SCRIPTS (list of other bin/ or .internal helpers)
- ARTIFACT_PATHS (one-line example under $REIMAGE_ARTIFACT_ROOT)
- PREREQS (optional list of installed commands/tools)
- DRY_RUN_FLAG (option name if the primary script supports --dry-run)
- SAMPLE_COMMANDS (optional runnable examples)
- ASSET_OR_HOST (token for use in example paths)
- AUTHOR and LAST_UPDATED (metadata)
- rename_suggestion (optional: new filename if migrating and a rename is desired)

Pre-read required files (Copilot MUST inspect these before editing)
- README.md
- reimaging-guide.md and the runbook that referenced this new runbook
- Target bin/<script> and any helper scripts listed in RELATED_SCRIPTS
- .internal/load-reimage-config.sh and .internal/artifact-config.sh
- reimage.env.example
- When migrating, the candidate source runbook(s) from the reference-vault path above.

Filling rules and constraints
- Keep language concise, imperative, and action-oriented.
- Preserve the template's anchors and TOC structure; every subsection referenced in the TOC must exist and have a matching heading.
- Do not invent or commit secrets, personal paths, or company-specific values.
- Do not add legacy/compatibility shims — prefer a single authoritative path. If compatibility is required, add an explicit short rationale and keep scope narrow.
- Ensure all paths are shown relative to the repository root and use $REIMAGE_ARTIFACT_ROOT or $REIMAGE_WORKSPACE_ROOT placeholders for artifact locations.
- If adding a directory tree, include only subdirectories relevant to the runbook steps.
- Use the RUNBOOK_SHORT_DESC to craft a 1–3 sentence Purpose section.
- Populate "Artifact and Script Locations" with PRIMARY_SCRIPT, RELATED_SCRIPTS, and ARTIFACT_PATHS.
- Support migrations where the source runbook's title or script names differ: include a "Renaming considerations" bullet that documents the proposed name change and reason.
- If multiple scripts exist, classify each as "entrypoint", "helper", or "deprecated/throwaway" in Artifact and Script Locations.

Auto-detection rules (attempt before asking clarifying questions)
- Scan PRIMARY_SCRIPT(s) for referenced environment variables and auto-list matching reimage.env keys by searching for strings like REIMAGE_, EXTERNAL_DATA_VOLUME, ONEDRIVE, GIT_*.
- Detect dry-run flags by searching script for patterns: --dry-run, -n, DRY_RUN, or usage/help output.
- If PRIMARY_SCRIPT path does not exist, note that the runbook will create or reference a future script and leave a TODO in the runbook.

Sequential Steps guidance
- Break the runbook into small numbered steps that map to the script's phases: prepare -> execute -> verify.
- For migrations, prefer to reflow original prose into the template's sections instead of verbatim copying; preserve essential implementation details, commands, and example output.
- When a source runbook contains more than one logical action, consider creating multiple runbooks or documenting sub-commands and mapping them to specific scripts/helpers.

TOC and anchors
- Generate the TOC and ensure all anchors link to existing headings. Add a small "TOC verification" instruction in the runbook footer that lists the check performed.

Renaming and file placement rules
- Suggest a canonical new filename using verb-first naming. Provide one recommended filename and up to two alternates.
- If rename_suggestion provided, include the old path and the new path in a short changelog note at the top of the generated runbook.

Validation checklist (run after generating the filled runbook)
- [ ] YAML header populated and valid.
- [ ] All template placeholders replaced.
- [ ] TOC links resolve to headings present in the file.
- [ ] PRIMARY_SCRIPT path exists in the repo or a TODO notes creation.
- [ ] Listed reimage.env variables appear in reimage.env.example or artifact-config.sh.
- [ ] No absolute personal paths or secrets introduced.
- [ ] Commands shown are syntactically valid and minimal.
- [ ] Renaming suggestions documented if applied.

Formatting and style
- Headline: use verb-first title pattern when practical; if source title deviates, include a short rationale for preserving it.
- Keep sentences short; prefer lists for steps and checks.
- Use fenced code blocks for commands and examples.

Deliverables
- A completed runbook Markdown at the destination path provided by the caller (e.g., backup-apps.md) or a preview diff if requested.
- A short summary (≤3 lines) listing the file created/changed, the rename suggestion (if any), and the key assumptions made.

Example invocation (JSON)
{
  "title": "Backup apps",
  "BACK_LINK": "reimaging-guide.md#phase-2",
  "RUNBOOK_SHORT_DESC": "Collect and stage application settings and installers to the artifact root.",
  "PRIMARY_SCRIPTS": ["bin/backup-apps.sh"],
  "RELATED_SCRIPTS": [".internal/load-reimage-config.sh"],
  "ARTIFACT_PATHS": "backups/apps/",
  "PREREQS": ["bash","rsync"],
  "DRY_RUN_FLAG": "--dry-run",
  "ASSET_OR_HOST": "ASSET01",
  "AUTHOR": "Your Name",
  "LAST_UPDATED": "2026-07-16",
  "rename_suggestion": "backup-apps.md"
}

If any required input is missing, ask one targeted clarifying question only. Use the repo to infer defaults before asking.
