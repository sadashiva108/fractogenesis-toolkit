# Runbook prompt — guidance for Copilot

Purpose
- Guide Copilot to populate .github/ai-templates/runbook-templates/runbook-template.md.tmpl for a specific runbook in this repo. Use it to create a new runbook, or to bring an existing one up to the current conventions.

When to use
- Use when authoring or reworking a runbook. Supports:
    - Creating a new runbook from scratch using minimal inputs
    - Bringing an existing runbook up to the current structure and conventions

Inputs (provide these as structured key/value data before asking Copilot to fill)
- title (string) — preferred, used as the runbook title heading
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
- LAST_UPDATED (date for the runbook's **Last updated:** line)

Pre-read required files (Copilot MUST inspect these before editing)
- README.md
- reimaging-guide.md and the runbook that referenced this new runbook
- Target bin/<script> and any helper scripts listed in RELATED_SCRIPTS
- .internal/load-reimage-config.sh and .internal/artifact-config.sh
- reimage.env.example

---

## Canonical section order

Every runbook uses this order. Optional sections are marked; keep an optional
section only when it earns its place, and delete its heading and its Table of
Contents entry when it does not.

1. Back-link — an Obsidian wiki-link to the page that linked this runbook. The literal first thing in the file.
2. `# Title`
3. `**Last updated:**` line (see Metadata below).
4. Short intro (1–3 sentences).
5. `## Table of Contents`
6. `## Purpose` — lead sentences + two labelled lists + an ownership table (see below).
7. `## How the Workflow Works` (optional) — the concepts and the *why*: what the flow achieves and why each part exists, plus `### Terminology` (optional) and any run-mode table. Kept shallow; depth goes to Supplemental Reference.
8. `## Artifact and Script Locations` — the single home for every directory tree, with `### Environment Variables`.
9. `## Before You Run Anything` — a lean pre-flight checklist only: `### Prerequisites` and `### Confirm Your Intent`. No conceptual "why" here, and no commands: Prerequisites *declares* what must be true, and the command that *verifies* it is Step 0 under Sequential Steps. Actions belong in steps.
10. `## Sequential Steps`
11. `## Decisions` (optional) — genuine judgment calls only.
12. `## Troubleshooting` (optional)
13. `## Supplemental Reference` (optional) — long-form; a Worked Example only when a concept is hard without one.

There is no bibliography / "see also" / pointers section, and no standalone
"Related Guides" list: the guide (reimaging-guide.md) orchestrates the runbooks,
each runbook is bounded context, and sibling-runbook cross-references live in the
Purpose ownership table. Do not reintroduce a link-list section.

### The Purpose section

Lay Purpose out in parts, not one prose block:

- A one- to three-sentence lead: what carrying out this runbook achieves and where it sits
  in the workflow.
- Two short labelled lists — bold labels, **not** sub-headings, so Purpose stays a single
  section: one for what the runbook produces (e.g. **What it sets up**) and one for how the
  rest of the workflow consumes it (e.g. **What the rest of the workflow relies on it for**).
  Adapt the label wording to the runbook.
- An **Ownership** table, columns *This runbook owns* | *Owned elsewhere*, where the right
  column names the runbook (or a `glob-*.md`) that owns each excluded area. This table is the
  single place sibling-runbook cross-references live — do not also restate them as a separate
  list or a "Related Guides" section.
- Optionally, one compact closing line naming what the produced artifacts are (e.g. "the root
  houses: …") when that inventory helps — a single sentence, never a bulleted catalog.

Purpose is background only: it states what the runbook achieves and who owns what, never step
mechanics.

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
also rolls up to the Phase 6B `reimage-prep-checks` sign-off; and a choice of
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

These are the house style for every runbook. They take precedence over habit; when an
existing runbook violates them, reflow it to match rather than copying its shape.

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
    - Where the paths rejoin, link forward to the shared step; at each divergence point add
      a plain back-link to the path index (not the Table of Contents), using the same
      `[[#Heading|⬆ Back to <label>]]` form as the Table-of-Contents back-link.
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
  and link to it. Sibling-runbook cross-references belong in the Purpose ownership table,
  not in a second list.

### A runbook has no memory of itself

Write what to do now. Never narrate the document's own history — no "an earlier
revision of this step", no "this used to say", no "that was wrong". The reader is
following the runbook, not auditing it, and a correction phrased as a correction
makes them wonder which other steps are mid-repair.

Keep the *substance* that made the fix necessary, stated as present fact. "There
is no `jssecacerts` at the top of `java-security/` — every store sits one level
down under its JDK label" tells the reader everything the archaeology would have,
and stays true after the next rewrite. "An earlier revision read the flat path"
tells them about a document that no longer exists.

The history belongs in `APPLY-MANIFEST.md`, which exists to carry it.

This differs deliberately from the convention in `bin/` and `.internal/` scripts,
where a comment explaining what an earlier revision got wrong is how a fix keeps
from being undone by the next person who finds the code surprising. A code
comment is read by someone changing the code; a runbook step is read by someone
following it. Different audiences, different rules.

### Metadata (Last updated line)

- A runbook carries no YAML frontmatter. The back-link is the literal first thing in the
  file, before the `# Title` heading.
- Its only metadata is a `**Last updated:** YYYY-MM-DD` line directly under the `# Title`
  heading; keep it current when the runbook changes.

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
### Routing indexes, back-links, and nesting

- A **routing index** is a parent section's routing list that sends the reader to one of
  several sub-sections by what they see (console output) or their situation. Each option is
  a single wiki-link whose label is the destination sub-section's heading — keep those
  headings short so the labels stay short and match exactly. Never invent a long description
  as the link label.
- Lay out a routing index by what each option needs (house rule):
    - **Console output to match — console-first (default).** Show the real output in a
      fenced block, then route on the next line: `→ [[#Heading|Heading]]` (add a short note
      only if it helps). Keeps continuity with what the reader is staring at.
    - **Short criterion, no console output — bullet.** `- [[#Heading|Heading]] — short
      criterion.` If the heading already states the branch, drop the criterion.
    - **Error/fail outcomes — callouts.** One Obsidian callout per outcome, colored by
      status (`> [!check]` pass, `> [!fail]` error, `> [!warning]` caution, `> [!note]`
      neutral), each ending in `→ [[#Heading|Heading]]` with any sample inside the callout.
    - Never a table: it can't hold multi-line console output and forces link-pipe escaping.
- **Sequential Steps takes one of two forms; pick by whether the flow forks.**
    - **Default — one back-link at the end of the whole section.** A straight-through
      flow is read top to bottom, so its steps need no individual escape hatch. This
      holds however many steps it has: length alone does not justify the other form.
    - **Per-step back-links, when the flow forks into routed paths.** A fork means
      readers arrive in the middle of the section from a path index or a
      troubleshooting Continue link, with no idea where the section ends, so each
      step ends with its own back-link and `---`. `backup-repos.md` is the reference
      for this form; every other runbook uses the default.
- Every section ends with a back-link, then a `---` divider on the next line — no exceptions:
    - A **parent/main section** links back to the Table of Contents:
      `[[#Table of Contents|⬆ Back to Table of Contents]]`.
    - A **sub-section reached from a routing index** links back to that routing index — the
      section that routed the reader to it: `[[#Routing Heading|⬆ Back to Routing Heading]]`.
      Nested deeper, it links back to its **immediate** parent routing index, not the top of
      the chain. Back-links are plain links, never callouts.
    - **Exception — routing index is the section's last part.** If no straight-through steps
      follow the routing index (its destinations are the tail of the section), a routed
      destination links **forward to the next section** instead of back:
      `[[#Next Section|⮕ Continue to Next Section]]`. This holds only when every destination
      converges on the same next section; if the destinations diverge to different next steps
      (e.g. one resumes and skips ahead while another loops back), keep the back-link to the
      routing index.
- **Routed destinations stay out of the Table of Contents.** The TOC lists top-level
  sections and their first-level steps; it does not list deeper sub-sections. A sub-section
  the reader reaches only by routing (never by reading straight through) has the routing
  index as its sole entry point — mirror how `Set Up direnv` keeps `First-Time Setup` and
  `Already Set Up` out of the TOC.

### Links in prose

- Do not put wiki-links in body prose by default. The Table of Contents, the section and
  routing-index back-links, and routing-index option links are the navigation wiring;
  ordinary sentences stay link-free unless a rule here calls for a link.
- Never link backward to an earlier step or forward to a later one. Runbooks are read in
  order — by the time the reader reaches a step they have already seen everything before it
  and do not need a link back, and they do not need to jump ahead to something they will
  reach anyway. The only exception is a link that documents *where a specific artifact,
  script, or definition lives* when that source location is not obvious from context.
- A troubleshooting reference is the other allowed prose link — format it as a callout, not
  a bare sentence (see the Troubleshooting guidance below).

### Callouts (Obsidian, consistent form)

- Runbooks are read in Obsidian, so use Obsidian callouts, which color and icon each type
  distinctly. Give Pitfall/Troubleshooting a custom title so the vocabulary survives:
    - `> [!note]` — clarification or easily-missed fact.
    - `> [!warning] Pitfall` — a mistake the reader is likely to make here.
    - `> [!bug] Troubleshooting` — what to do when a step misbehaves.

  Out-of-sequence returns are plain back-links, not callouts (see the Links section).
- In a non-Obsidian viewer these degrade to plain blockquotes with the `[!type]` label
  still readable (GitHub styles note/warning natively).
- Keep the type set small and use it the same way in every runbook, so readers learn to
  scan for it. Include a one-line callout legend under the Table of Contents.

### Troubleshooting: inline callout versus section

- A step-local problem with a short fix stays inline as a `> [!bug] Troubleshooting` callout
  next to its step — that is where the reader hits it.
- Format every inline troubleshooting reference as a `> [!bug] Troubleshooting` callout whose
  body states the symptom and links into the fix with `see [[#Section|Section]]` — not a bare
  `jump to [[#Section]]` sentence sitting in the prose. For example:

    ```
    > [!bug] Troubleshooting
    > If the write test fails with `Permission denied`, see [[#Can't Write to the Volume|Can't Write to the Volume]].
    ```
- Promote troubleshooting to the optional top-level **Troubleshooting** section only when a
  problem spans multiple steps, its fix is long enough to break a step's flow, or it is
  common enough that readers will scan for a "Troubleshooting" heading. The step then carries
  a one-line inline callout that links into the section.
- Any given failure's fix lives in exactly one place — inline OR in the Troubleshooting
  section, never both.
- A troubleshooting section the reader lands on to fix an error and then resumes from ends
  with a single `⮕ Continue to <resume step>` link — the step they proceed to once the fix
  succeeds (for example, the artifact-root errors all resume at Load and Confirm the
  Environment). That Continue link is the section's *only* link: strip return links and
  cross-references to other sections. Fall back to a back-link to the `## Troubleshooting`
  index only for a section with no single resume step.
- The `## Troubleshooting` parent itself still carries a
  `[[#Table of Contents|⬆ Back to Table of Contents]]` link, placed directly under its intro
  and *before* the first `###` symptom subsection — not at the end of the section. A reader
  who opened Troubleshooting from the Table of Contents needs a way back without scrolling
  through every symptom, while a reader who lands mid-section from a `> [!bug]` callout
  should still flow forward to their resume step. This is the one place a back-link sits at
  the top of a section rather than at its end; there is no `---` divider after it.

### Commands

- Precede every command block with a single one-line sentence saying what it is for.
- **Never leave a `<placeholder>` bare in a command block.** `<` and `>` are
  redirection operators, so `cmd --url https://<host>/` is parsed as a redirect
  and dies with `no such file or directory: host` — which reads as a broken
  command rather than an unfilled blank. Put the placeholder in quotes, or
  better, assign it on its own line first:

  ```bash
  TARGET="replace-with-the-real-value"
  cmd --url "$TARGET"
  ```

  The assignment form is preferable for anything the reader must supply: it names
  the thing, it survives being re-run, and a reader who pastes the block
  unchanged gets a clear failure about the value rather than a shell parse error.
  Angle brackets in *prose*, in tables, and inside heredoc bodies are fine —
  the rule is about lines the shell will execute.
- **No `#` comments inside a command block — trailing or whole-line.** Interactive
  zsh, which is what the operator is pasting into, does not treat `#` as a comment
  unless `interactivecomments` is set. A trailing `cmd args   # what this does`
  arrives as extra arguments, and a `;` in the note starts a second command, so the
  result looks like a failure when the command succeeded.
  A **whole-line** comment is the worse case: an apostrophe in it opens a quote that
  stays open until the next `'` anywhere in the block, silently consuming the
  commands below. `# print the first lines of the tool's own error` does exactly
  that, and the operator sees a `quote>` prompt and `zsh: unmatched '` rather than
  anything naming the line at fault.
  The one-line sentence above the block is where the explanation belongs, which the
  rule above already requires; a comment inside the block duplicates it into the one
  place it can break. Where a note must sit beside a specific line, put it in a table
  or a callout under the block. This applies only to blocks meant to be pasted —
  comments in `bin/` and `.internal/` scripts are executed by `bash`, never by an
  interactive zsh, and stay.
- **zsh expands before it executes, so a guard placed inside the construct is
  already too late.** An unmatched glob is an *error* in zsh — `zsh: no matches
  found: …` — rather than the literal pattern Bash passes through. The Bash idiom
  for a possibly-empty directory therefore never runs:

  ```bash
  for f in "$DIR"/*.pub; do
    [ -e "$f" ] || continue
  ```

  zsh raises the error during expansion, the loop body is never entered, and the
  guard written precisely for the empty case does not execute. It is worse than
  useless: it reads as though the case is handled. Iterate `find` output instead,
  which prints nothing and exits 0 on no match, in both shells:

  ```bash
  find "$DIR" -maxdepth 1 -name '*.pub' -type f | sort | while IFS= read -r f; do
  ```

  The same evaluation order is why an unquoted `(`, `[`, `?` or `*` anywhere on an
  executed line is a hazard even inside text that reads as prose. A whole-line
  comment ending `… (the secure default).` fails with `zsh: no matches found:
  (the secure default).` — glob expansion, raised *before* the `#` rule above ever
  comes into play, which is why removing the `#` alone would not have saved it.
  Glob metacharacters in a pasted block must be quoted, or produced by something
  that is not globbing.
- **Name a later-phase dependency in the prose above the block, not in the block's
  output.** A runbook step may only use what earlier phases installed. Where a command
  depends on a tool a later phase brings — `gh`, `npm`, `pip3` and `code` are all
  installed in Phase 12, well after the Phase 10B access restore — say so in the
  sentence introducing the block, and say whether deferring is the expected result or
  a problem. A guard that prints `not installed yet` only after the operator has run
  it tells them the same fact one step too late, and reads as a failure they caused.
  Where the phase can proceed without it, say that too, so the reader knows whether to
  stop. Where an alternative exists on the base system, prefer it outright rather than
  reaching for the later-phase tool: the dotfile comparison uses `git diff --no-index`
  because `code --diff` does not exist yet.
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
- Do not prefix command blocks with `cd "$FRACTOGENESIS_HOME"`. The repo-root working directory is stated once in `reimaging-guide.md` → Core Assumptions and restated in the runbook's Prerequisites; command blocks start at the command. Keep a literal `cd` only where a command must run from a different directory, and say why.
- If adding a directory tree, include only subdirectories relevant to the runbook steps.
- Use the RUNBOOK_SHORT_DESC to craft the 1–3 sentence Purpose lead, followed by the two labelled lists and the ownership table (see The Purpose section).
- Populate "Artifact and Script Locations" with PRIMARY_SCRIPT, RELATED_SCRIPTS, ARTIFACT_PATHS, and the Environment Variables subsection, and treat that section as the single home for every directory tree the runbook uses.
- List PRIMARY_SCRIPTS, RELATED_SCRIPTS, and any other enumerated runbook or script references in alphabetical order.
- If adding a directory tree, include only subdirectories relevant to the
  runbook steps, sorted alphabetically at every level. Represent omitted
  siblings with a single `...` entry immediately before the first included
  entry and immediately after the last — except omit the leading `...` when
  the first included entry is alphabetically first among the root's
  top-level directories, and omit the trailing `...` when the last included
  entry is alphabetically last.
- When a runbook's title or script names change, include a "Renaming considerations" bullet that documents the proposed name change and reason.
- If multiple scripts exist, classify each as "entrypoint", "helper", or "deprecated/throwaway" in Artifact and Script Locations.

Auto-detection rules (attempt before asking clarifying questions)
- Scan PRIMARY_SCRIPT(s) for referenced environment variables and auto-list matching reimage.env keys by searching for strings like REIMAGE_, EXTERNAL_DATA_VOLUME, ONEDRIVE, GIT_*.
- Detect dry-run flags by searching script for patterns: --dry-run, -n, DRY_RUN, or usage/help output.
- If PRIMARY_SCRIPT path does not exist, note that the runbook will create or reference a future script and leave a TODO in the runbook.

Step 0 guidance

- A runbook whose prerequisites can fail **silently** should open Sequential Steps
  with `### Step 0 — Record Prerequisites`, invoking the phase's prerequisite
  recorder. Silent failure is the test: an unset variable that makes `cd ""` a
  no-op returning 0, an unmounted volume a later step reads from, a sign-off with
  rows nobody answered. A precondition that fails loudly needs no row.
- Number it 0, not 1. It gates the phase rather than advancing it, and it is
  rerunnable at any point, unlike the sequential steps below. Numbering it 0 also
  means adding one to an existing runbook renumbers nothing.
- Prerequisites and Step 0 are not duplicates. Prerequisites states the
  requirement in prose so a reader knows what is needed even when they cannot yet
  run the check; Step 0 verifies it and writes the artifact. Derive Step 0's rows
  from that list so the two cannot drift.
- Omit Step 0 entirely when a phase has no prerequisite worth checking. Do not add
  an empty one for symmetry.

Sequential Steps guidance
- Break the runbook into small numbered steps that map to the script's phases: prepare -> execute -> verify.
- Order steps so every dependency is produced before the step that consumes it; state the reason for any branching choice before the command that acts on it (see "Why before how" and "Sequencing" above).
- Put manual verification (a fact a person must confirm by hand) in the verify action of the step it belongs to, not in the Decisions section; it rolls up to the Phase 6B sign-off.
- When updating a runbook, prefer to reflow existing prose into the template's sections instead of verbatim copying; preserve essential implementation details, commands, and example output.
- When a runbook contains more than one logical action, consider creating multiple runbooks or documenting sub-commands and mapping them to specific scripts/helpers.

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
  directory name changed.
- Keep collapsible contents alphabetized, consistent with the rule above.

Renaming and file placement rules
- Suggest a canonical new filename using verb-first naming. Provide one recommended filename and up to two alternates.

Validation checklist (run after generating the filled runbook)
- [ ] The back-link is the literal first thing in the file; there is no YAML frontmatter.
- [ ] A `**Last updated:**` line sits directly under the `# Title` heading.
- [ ] All template placeholders replaced.
- [ ] Section order matches the Canonical section order; deleted optional sections are gone from both the body and the TOC.
- [ ] Purpose uses the lead + two labelled lists (what it sets up / what downstream relies on it for) + an ownership table; that table is the only place sibling cross-references live (no separate Related Guides or see-also section).
- [ ] The "why" lives in How the Workflow Works; Before You Run Anything is a lean checklist (Prerequisites + Confirm Your Intent) with no conceptual background.
- [ ] Artifact and Script Locations includes an Environment Variables subsection listing the required reimage.env keys.
- [ ] Decisions, if present, holds genuine judgment calls only; manual verifications live in the relevant verify step, and intent lives in Confirm Your Intent.
- [ ] TOC links resolve to headings present in the file, using Obsidian wiki-link form.
- [ ] The "In Obsidian, these are internal heading links" note and the callout legend are present under the TOC.
- [ ] Callouts use the Obsidian `> [!type]` forms; any Troubleshooting fix lives inline OR in the Troubleshooting section, never both.
- [ ] The `## Troubleshooting` parent carries a Table-of-Contents back-link under its intro, above the first symptom subsection.
- [ ] Sequential Steps uses the default single back-link, unless the flow forks into routed paths — in which case every step carries its own.
- [ ] Section and step intros are link-free; only links that earn their place remain.
- [ ] Routing-index forks follow the layout house rule — console-first when there is output to match, a short bullet when there is not, callouts for error/fail outcomes, never a table — and each option's link label matches its destination heading.
- [ ] PRIMARY_SCRIPT path exists in the repo or a TODO notes creation.
- [ ] Listed reimage.env variables appear in reimage.env.example or artifact-config.sh.
- [ ] No absolute personal paths or secrets introduced.
- [ ] Commands shown are syntactically valid and minimal, each preceded by a one-line purpose.
- [ ] Pasted command blocks are zsh-safe: no `#` comments trailing or whole-line, no bare `<placeholder>` the shell would read as redirection, and no unquoted glob metacharacters or bare `*` patterns whose non-match would abort the line.
- [ ] Every directory tree appears once, under Artifact and Script Locations; no tree is redrawn elsewhere.
- [ ] Reason-before-command holds: no runnable command precedes the rationale a reader needs to run it correctly.
- [ ] A Worked Example appears only when a concept is hard without one.
- [ ] Every section ends with a back-link then a `---` divider: parent/main sections link to the Table of Contents, routed sub-sections to their routing index (immediate parent when nested deeper).
- [ ] Routed destinations are omitted from the Table of Contents; the routing index is their only entry point.
- [ ] Body prose is link-free except routing-index options and troubleshooting callouts, and never links back to an earlier step or forward to a later one.
- [ ] Inline troubleshooting references use the `> [!bug] Troubleshooting` callout with a `see [[#Section]]` link, not a bare sentence.
- [ ] Renaming suggestions documented if applied.
- [ ] master-directory-reference.md checked against this runbook's tree; added, updated, or renamed as needed.

Formatting and style
- Headline: use verb-first title pattern when practical; if the existing title deviates, include a short rationale for preserving it.
- Keep sentences short; prefer lists for steps and checks.
- Use fenced code blocks for commands and examples.
- Apply the Authoring conventions above for prose spacing, callouts, tables, links, and single-source trees.

Deliverables
- A completed runbook Markdown at the destination path provided by the caller (e.g., backup-apps.md) or a preview diff if requested.
- A short summary (≤3 lines) listing the file created/changed, the rename suggestion (if any), and the key assumptions made.

Example invocation (JSON)
{
"title": "Backup apps",
"BACK_LINK": "reimaging-guide#Phase 2D — Backup Apps",
"RUNBOOK_SHORT_DESC": "Collect and stage application settings and installers to the artifact root.",
"PRIMARY_SCRIPTS": ["bin/backup-apps.sh"],
"RELATED_SCRIPTS": [".internal/load-reimage-config.sh"],
"ARTIFACT_PATHS": "app-settings-backup/",
"PREREQS": ["bash","rsync"],
"DRY_RUN_FLAG": "--dry-run",
"ASSET_OR_HOST": "ASSET01",
"LAST_UPDATED": "2026-07-16"
}

If any required input is missing, ask one targeted clarifying question only. Use the repo to infer defaults before asking.
