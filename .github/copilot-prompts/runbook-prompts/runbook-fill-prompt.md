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

---

## Authoring conventions (prose, layout, and sequencing)

These are the house style for every runbook. They take precedence over habit; when a
source runbook violates them during migration, reflow it to match rather than copying
its shape.

### Why before how

- A reader in the runnable sections will run a command the moment they see it, often
  without having read ahead. So the reason for a choice must appear *before* the command
  that acts on it, never after.
- Divide material by intent, not by topic:
    - **Before You Run Anything** — conceptual background: *why* each step exists. Each
      subsection leads with its "why" in the first sentence and hands off to the next.
    - **Sequential Steps** — the runnable *how*, in dependency order.
    - **Supplemental Reference** — longer or uncommon material most runs will not need,
      but a few readers will. Use the name "Supplemental Reference" consistently across
      all runbooks (not "Appendix" / "Appendices").
- Open a runbook with a short **How the Workflow Works** overview that states what the
  whole flow achieves before any location, flag, or file detail. Mention it is the
  preferred path and give the reason in one line; do not front-load mode/file mechanics.

### Sequencing

- Sequential Steps must flow so that every dependency is satisfied before the step that
  needs it. Never present a script whose inputs an earlier step has not yet produced.
- When a flow forks into a preferred path and an alternate/off-ramp:
    - Put the shared steps first as common setup.
    - Add a short **path-index** section that names each path, says which is preferred and
      why, and links into each chain.
    - Chain the steps within each path so they read straight through.
    - Where the paths rejoin, link forward to the shared step; at each divergence point use
      a **Return** callout linking back to the path index (not to the Table of Contents).
- Do not drop an "optional" or off-ramp step inline in the middle of the preferred flow;
  route to it from the path index instead.

### Single source of truth (refactor-friendliness)

- Define each directory tree exactly once, under **Artifact and Script Locations**.
  Elsewhere, refer to it by name or link — never redraw the same tree in two places.
- Do not hard-code a value that could change (paths, folder names, root locations) in
  many spots. Use `$REIMAGE_ARTIFACT_ROOT`, `$REIMAGE_WORKSPACE_ROOT`, `$FRACTOGENESIS_HOME`
  and named references so a future change touches one place.
- If the same fact would otherwise be repeated in slightly different words, state it once
  and link to it.

### Terminology

- Define ambiguous domain terms early, in a short glossary table, before the steps rely
  on them (e.g., distinguish "ignored by Git" from "chosen to keep").
- Do not name a step in a way that implies the opposite of its effect. Prefer names that
  state the action and its direction plainly.

### Callouts (standard, consistent form)

- Use text-tag blockquotes so they render identically in any Markdown viewer:
    - `> **Note —** …` — clarification or easily-missed fact.
    - `> **Pitfall —** …` — a mistake the reader is likely to make here.
    - `> **Troubleshooting —** …` — what to do when a step misbehaves.
    - `> **Return —** [↩ link]` — how to get back after an out-of-sequence detour.
- Keep the tag set small and use it the same way in every runbook, so readers learn to
  scan for it.

### Commands

- Precede every command block with a single one-line sentence saying what it is for.
- Keep command blocks small — ideally one logical action each. Avoid large stacked blocks
  of many commands.
- If a sequence grows long or fiddly, that is a signal to move it into a standalone script
  (or a flag on an existing entrypoint) and call the script from the runbook instead.

### Layout and prose

- Do not jam prose, links, and code together without whitespace. Separate distinct ideas,
  callouts, and code blocks with blank lines so steps are hard to miss.
- Break up walls of text; vary formatting (short prose, a compact table, a callout, a
  small diagram) for clarity and visual interest.
- Use tables only when they genuinely organize the information; do not table prose that
  reads better as sentences.
- Put a single "Back to Table of Contents" link at the end of each top-level section, not
  after every subsection.

### Links

- Keep only links that earn their place: forward links a reader will act on, and return
  links from a place they might land out of sequence (a reference file, a troubleshooting
  detour, a path fork). Drop decorative back-references to earlier phases or steps.
- If a cross-reference to another phase is genuinely needed, add a few words describing
  what it is — readers forget what a bare "Phase 1" points to.

### Worked examples

- For any multi-file or multi-stage flow that is easy to misread, add a **Worked Example**
  under Supplemental Reference: a small concrete setup walked end to end, showing exactly
  what each stage produces. Illustrate the alternate/off-ramp path on the same setup so
  the trade-off is visible in one place.

---

Filling rules and constraints
- Keep language concise, imperative, and action-oriented.
- Preserve the template's anchors and TOC structure; every subsection referenced in the TOC must exist and have a matching heading.
- Do not invent or commit secrets, personal paths, or company-specific values.
- Do not add legacy/compatibility shims — prefer a single authoritative path. If compatibility is required, add an explicit short rationale and keep scope narrow.
- Ensure all paths are shown relative to the repository root and use $REIMAGE_ARTIFACT_ROOT or $REIMAGE_WORKSPACE_ROOT placeholders for artifact locations.
- If adding a directory tree, include only subdirectories relevant to the runbook steps.
- Use the RUNBOOK_SHORT_DESC to craft a 1–3 sentence Purpose section.
- Populate "Artifact and Script Locations" with PRIMARY_SCRIPT, RELATED_SCRIPTS, and ARTIFACT_PATHS, and treat that section as the single home for every directory tree the runbook uses.
- List PRIMARY_SCRIPTS, RELATED_SCRIPTS, and any other enumerated runbook or script references in alphabetical order.
- If adding a directory tree, include only subdirectories relevant to the
  runbook steps, sorted alphabetically at every level. Represent omitted
  siblings with a single `...` entry immediately before the first included
  entry and immediately after the last — except omit the leading `...` when
  the first included entry is alphabetically first among the root's
  top-level directories, and omit the trailing `...` when the last included
  entry is alphabetically last.
- Support migrations where the source runbook's title or script names differ: include a "Renaming considerations" bullet that documents the proposed name change and reason.
- If multiple scripts exist, classify each as "entrypoint", "helper", or "deprecated/throwaway" in Artifact and Script Locations.

Auto-detection rules (attempt before asking clarifying questions)
- Scan PRIMARY_SCRIPT(s) for referenced environment variables and auto-list matching reimage.env keys by searching for strings like REIMAGE_, EXTERNAL_DATA_VOLUME, ONEDRIVE, GIT_*.
- Detect dry-run flags by searching script for patterns: --dry-run, -n, DRY_RUN, or usage/help output.
- If PRIMARY_SCRIPT path does not exist, note that the runbook will create or reference a future script and leave a TODO in the runbook.

Sequential Steps guidance
- Break the runbook into small numbered steps that map to the script's phases: prepare -> execute -> verify.
- Order steps so every dependency is produced before the step that consumes it; state the reason for any branching choice before the command that acts on it (see "Why before how" and "Sequencing" above).
- For migrations, prefer to reflow original prose into the template's sections instead of verbatim copying; preserve essential implementation details, commands, and example output.
- When a source runbook contains more than one logical action, consider creating multiple runbooks or documenting sub-commands and mapping them to specific scripts/helpers.

TOC and anchors
- Generate the TOC and ensure all anchors link to existing headings. Add a small "TOC verification" instruction in the runbook footer that lists the check performed.

Cross-reference master-directory-reference.md
- After finalizing this runbook's "Artifact and Script Locations" tree,
  compare each directory it touches against master-directory-reference.md's
  Master Root Layout and Collapsible Directory Sections.
- Add a new collapsible section if the directory is missing there.
- Update the existing collapsible if its contents diverge from what this
  runbook's tree now shows.
- Rename the collapsible's heading and Master Root Layout entry if the
  directory name changed during migration.
- Keep collapsible contents alphabetized, consistent with the rule above.

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
- [ ] Commands shown are syntactically valid and minimal, each preceded by a one-line purpose.
- [ ] Every directory tree appears once, under Artifact and Script Locations; no tree is redrawn elsewhere.
- [ ] Reason-before-command holds: no runnable command precedes the rationale a reader needs to run it correctly.
- [ ] Callouts use the standard `> **Tag —**` forms; Supplemental Reference (not "Appendix") is the name used.
- [ ] Renaming suggestions documented if applied.
- [ ] master-directory-reference.md checked against this runbook's tree; added, updated, or renamed as needed.

Formatting and style
- Headline: use verb-first title pattern when practical; if source title deviates, include a short rationale for preserving it.
- Keep sentences short; prefer lists for steps and checks.
- Use fenced code blocks for commands and examples.
- Apply the Authoring conventions above for prose spacing, callouts, tables, links, and single-source trees.

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
