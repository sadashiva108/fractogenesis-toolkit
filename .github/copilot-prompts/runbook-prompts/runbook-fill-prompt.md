# Runbook fill prompt — guidance for Copilot

Purpose
- Guide Copilot to populate .github/copilot-templates/runbook-templates/runbook-template.md.tmpl for a specific runbook in this repo. Designed for both migration and new-runbook creation.

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
- BACK_LINK (target the back-link points to, e.g. reimaging-guide#Phase 2B — Backup Home)
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

## Canonical section order

Every runbook uses this order. Optional sections are marked; keep an optional
section only when it earns its place, and delete its heading and its Table of
Contents entry when it does not.

1. YAML frontmatter (see Metadata below) — the literal first thing in the file.
2. Back-link — an Obsidian wiki-link to the page that linked this runbook.
3. `# Title`
4. Short intro (1–3 sentences).
5. `## Table of Contents`
6. `## Purpose` — includes the ownership map (see below).
7. `## How the Workflow Works` (optional) — the concepts and the *why*: what the flow achieves and why each part exists, plus `### Terminology` (optional) and any run-mode table. Kept shallow; depth goes to Supplemental Reference.
8. `## Artifact and Script Locations` — the single home for every directory tree, with `### Environment Variables`.
9. `## Before You Run Anything` — a lean pre-flight checklist only: `### Prerequisites` and `### Confirm Your Intent`. No conceptual "why" here.
10. `## Sequential Steps`
11. `## Decisions` (optional) — genuine judgment calls only.
12. `## Troubleshooting` (optional)
13. `## Supplemental Reference` (optional) — long-form; a Worked Example only when a concept is hard without one.

There is no bibliography / "see also" / pointers section, and no standalone
"Related Guides" list: the guide (reimaging-guide.md) orchestrates the runbooks,
each runbook is bounded context, and sibling-runbook cross-references live in the
Purpose ownership map. Do not reintroduce a link-list section.

### The Purpose ownership map

Purpose is the single place cross-references to sibling runbooks live. State what
the runbook *owns* and, briefly, what it *does not own* — naming the runbook that
owns each excluded area. Do not also restate those mappings as a separate list.

### How the Workflow Works holds the "why"

The conceptual background and the reason each part of the flow exists live here,
not in Before You Run Anything. Say what the flow achieves, then why the steps are
ordered as they are, in a sentence or two each. Keep it shallow — detailed
mechanics (a tricky rsync flag, a long edge case) go to Supplemental Reference and
are linked from here.

### Before You Run Anything is a lean checklist

Before You Run Anything is a short pre-flight, not a place for concepts. It has two
subsections: `### Prerequisites` (is the reader set up — mounted volume, resolved
env, tools) and `### Confirm Your Intent` (what the reader means this run to do —
which mode/path, which options, whether to dry-run first). Keep it brief enough
that someone in a hurry still reads it.

### The Decisions section is judgment calls only

`## Decisions` holds only genuine judgment calls with no single right answer that
do not attach to a single step (e.g. whether a kept file is really a secret). Two
things that look similar do NOT belong here: a fact the reader verifies by hand is
a *verification* — put it in the relevant Sequential Steps verify action, where it
also rolls up to the Phase 4B `reimage-prep-checks` sign-off; and a choice of
mode/path is *intent* — put it in Confirm Your Intent. Delete the section when the
runbook has no standing judgment calls.

### Supplemental Reference is long-form

Supplemental Reference holds detailed mechanics, generated-file references, and
known gaps — content most runs will not need. It is not a list of pointers to other
files. Use the name "Supplemental Reference" consistently (not "Appendix").

When a runbook's scope is driven by config fragments (or a similar file set) the
operator edits, cover how to customize them here — format, fields, and a one-line
tip per fragment — and link to that subsection from the Sequential Steps step that
lists them, rather than swelling the step itself.

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
    - **How the Workflow Works** — the concepts and the *why*: what the flow achieves and
      why each part exists, plus terminology and run modes. Kept shallow; deep mechanics
      go to Supplemental Reference.
    - **Before You Run Anything** — a lean pre-flight checklist: Prerequisites (are you set
      up) and Confirm Your Intent (what you mean this run to do). No conceptual "why" here.
    - **Sequential Steps** — the runnable *how*, in dependency order.
    - **Supplemental Reference** — longer or uncommon material most runs will not need,
      but a few readers will. Use the name "Supplemental Reference" consistently across
      all runbooks (not "Appendix" / "Appendices").
- Open a runbook with a short **How the Workflow Works** overview that states what the
  whole flow achieves before any location, flag, or file detail, then gives the reason each
  part exists so the reader finishes knowing *why*. Mention the preferred path and its
  reason in one line; do not front-load mode/file mechanics.

### Sequencing

- Sequential Steps must flow so that every dependency is satisfied before the step that
  needs it. Never present a script whose inputs an earlier step has not yet produced.
- When a flow forks into a preferred path and an alternate/off-ramp:
    - Put the shared steps first as common setup.
    - Add a short **path-index** section that names each path, says which is preferred and
      why, and links into each chain.
    - Chain the steps within each path so they read straight through.
    - Where the paths rejoin, link forward to the shared step; at each divergence point use
      a `> [!info] Return` callout linking back to the path index (not to the Table of Contents).
- Do not drop an "optional" or off-ramp step inline in the middle of the preferred flow;
  route to it from the path index instead.

### Single source of truth (refactor-friendliness)

- Define each directory tree exactly once, under **Artifact and Script Locations**.
  Elsewhere, refer to it by name or link — never redraw the same tree in two places. When
  another runbook owns the full layout, link to it on its own line rather than redrawing it.
- Do not hard-code a value that could change (paths, folder names, root locations) in
  many spots. Use `$REIMAGE_ARTIFACT_ROOT`, `$REIMAGE_WORKSPACE_ROOT`, `$FRACTOGENESIS_HOME`
  and named references so a future change touches one place.
- If the same fact would otherwise be repeated in slightly different words, state it once
  and link to it. Sibling-runbook cross-references belong in the Purpose ownership map,
  not in a second list.

### Metadata (YAML frontmatter)

- Every runbook begins with a YAML frontmatter block. It MUST be the literal first thing
  in the file — before the back-link line — or Obsidian will not parse it as frontmatter.
- Keep metadata in the frontmatter only: `title`, `back_link`, `runbook_version`,
  `verb_first`, `primary_scripts`, `related_scripts`, `artifact_paths`, `author`,
  `last_updated`. Do not add a second metadata block elsewhere in the document.

### Environment variables

- Under **Artifact and Script Locations**, add an `### Environment Variables` subsection
  listing the exact `reimage.env` keys the scripts require, each with a one-line meaning.
- Auto-detect by scanning PRIMARY_SCRIPT(s) for `REIMAGE_*`, `EXTERNAL_DATA_VOLUME`,
  `ONEDRIVE*`, and `GIT_*_REPO_ROOT` references. Note that these values are resolved and
  written during prepare-artifact-root.md.

### Terminology

- Define ambiguous domain terms early, in a short glossary table under **How the Workflow
  Works**, before the steps rely on them (e.g., distinguish "ignored by Git" from "chosen
  to keep").
- Do not name a step in a way that implies the opposite of its effect. Prefer names that
  state the action and its direction plainly.

### Links (Obsidian)

- Runbooks are read primarily in Obsidian. Use Obsidian wiki-links for the back-link, the
  Table of Contents, and cross-references: `[[#Heading|Label]]` within a file and
  `[[other-runbook#Heading|Label]]` across files.
- Include the standard note under the Table of Contents: "In Obsidian, these are internal
  heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode."
- Keep section and step intros link-free. Describe the shape of the flow in a sentence
  rather than wiring up every subsection; too many navigation links pull the reader off
  the path. Keep only links that earn their place: a forward link a reader will act on, or
  a return link from a place they might land out of sequence (a troubleshooting detour, a
  path fork). Drop decorative back-references to earlier phases or steps.
- If broad Markdown-anchor compatibility is needed later, the TOC, back-link, and
  cross-references are the only elements that convert — keeping other prose link-free keeps
  that change small.
- Put a single "Back to Table of Contents" link at the end of each top-level section, not
  after every subsection. The one exception is a `> [!info] Return` callout, which links
  back to a path index rather than the Table of Contents.

### Callouts (Obsidian, consistent form)

- Runbooks are read in Obsidian, so use Obsidian callouts, which color and icon each type
  distinctly. Give Pitfall/Troubleshooting/Return a custom title so the vocabulary survives:
    - `> [!note]` — clarification or easily-missed fact.
    - `> [!warning] Pitfall` — a mistake the reader is likely to make here.
    - `> [!bug] Troubleshooting` — what to do when a step misbehaves.
    - `> [!info] Return` — how to get back after an out-of-sequence detour.
- In a non-Obsidian viewer these degrade to plain blockquotes with the `[!type]` label
  still readable (GitHub styles note/warning natively).
- Keep the type set small and use it the same way in every runbook, so readers learn to
  scan for it. Include a one-line callout legend under the Table of Contents.

### Troubleshooting: inline callout versus section

- A step-local problem with a short fix stays inline as a `> [!bug] Troubleshooting` callout
  next to its step — that is where the reader hits it.
- Promote troubleshooting to the optional top-level **Troubleshooting** section only when a
  problem spans multiple steps, its fix is long enough to break a step's flow, or it is
  common enough that readers will scan for a "Troubleshooting" heading. The step then carries
  a one-line inline callout that links into the section.
- Any given failure's fix lives in exactly one place — inline OR in the Troubleshooting
  section, never both.

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
- When a short label introduces a value or path, put the label on its own line and the
  value in its own block rather than jamming both into one sentence.

### Worked examples

- Add a **Worked Example** only when a concept is hard to grasp without one — a multi-file
  or multi-stage flow that is easy to misread. Do not add one by default. When you do, walk
  a small concrete setup end to end under Supplemental Reference, showing exactly what each
  stage produces, and illustrate the alternate/off-ramp path on the same setup so the
  trade-off is visible in one place.

---

Filling rules and constraints
- Keep language concise, imperative, and action-oriented.
- Preserve the template's anchors and TOC structure; every subsection referenced in the TOC must exist and have a matching heading, and every deleted optional section must also be removed from the TOC.
- Do not invent or commit secrets, personal paths, or company-specific values.
- Do not add legacy/compatibility shims — prefer a single authoritative path. If compatibility is required, add an explicit short rationale and keep scope narrow.
- Ensure all paths are shown relative to the repository root and use $REIMAGE_ARTIFACT_ROOT or $REIMAGE_WORKSPACE_ROOT placeholders for artifact locations.
- If adding a directory tree, include only subdirectories relevant to the runbook steps.
- Use the RUNBOOK_SHORT_DESC to craft a 1–3 sentence Purpose section, followed by the ownership map.
- Populate "Artifact and Script Locations" with PRIMARY_SCRIPT, RELATED_SCRIPTS, ARTIFACT_PATHS, and the Environment Variables subsection, and treat that section as the single home for every directory tree the runbook uses.
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
- Put manual verification (a fact a person must confirm by hand) in the verify action of the step it belongs to, not in the Decisions section; it rolls up to the Phase 4B sign-off.
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
- [ ] YAML frontmatter is the literal first thing in the file, populated and valid.
- [ ] Metadata lives only in the frontmatter; no second metadata block exists.
- [ ] All template placeholders replaced.
- [ ] Section order matches the Canonical section order; deleted optional sections are gone from both the body and the TOC.
- [ ] Purpose contains the ownership map; there is no separate Related Guides or pointers/see-also section.
- [ ] The "why" lives in How the Workflow Works; Before You Run Anything is a lean checklist (Prerequisites + Confirm Your Intent) with no conceptual background.
- [ ] Artifact and Script Locations includes an Environment Variables subsection listing the required reimage.env keys.
- [ ] Decisions, if present, holds genuine judgment calls only; manual verifications live in the relevant verify step, and intent lives in Confirm Your Intent.
- [ ] TOC links resolve to headings present in the file, using Obsidian wiki-link form.
- [ ] The "In Obsidian, these are internal heading links" note and the callout legend are present under the TOC.
- [ ] Callouts use the Obsidian `> [!type]` forms; any Troubleshooting fix lives inline OR in the Troubleshooting section, never both.
- [ ] Section and step intros are link-free; only links that earn their place remain.
- [ ] PRIMARY_SCRIPT path exists in the repo or a TODO notes creation.
- [ ] Listed reimage.env variables appear in reimage.env.example or artifact-config.sh.
- [ ] No absolute personal paths or secrets introduced.
- [ ] Commands shown are syntactically valid and minimal, each preceded by a one-line purpose.
- [ ] Every directory tree appears once, under Artifact and Script Locations; no tree is redrawn elsewhere.
- [ ] Reason-before-command holds: no runnable command precedes the rationale a reader needs to run it correctly.
- [ ] A Worked Example appears only when a concept is hard without one.
- [ ] Each top-level section ends with one "Back to Table of Contents" link, except Return callouts that link to a path index.
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
"BACK_LINK": "reimaging-guide#Phase 2C — Backup Apps",
"RUNBOOK_SHORT_DESC": "Collect and stage application settings and installers to the artifact root.",
"PRIMARY_SCRIPTS": ["bin/backup-apps.sh"],
"RELATED_SCRIPTS": [".internal/load-reimage-config.sh"],
"ARTIFACT_PATHS": "app-settings-backup/",
"PREREQS": ["bash","rsync"],
"DRY_RUN_FLAG": "--dry-run",
"ASSET_OR_HOST": "ASSET01",
"AUTHOR": "Your Name",
"LAST_UPDATED": "2026-07-16",
"rename_suggestion": "backup-apps.md"
}

If any required input is missing, ask one targeted clarifying question only. Use the repo to infer defaults before asking.
