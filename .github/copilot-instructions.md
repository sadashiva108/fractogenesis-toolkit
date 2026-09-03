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
  - Phase bookends are recorded, not just described. `record-restore-prereqs.sh --phase <p>` runs at a phase's Step 0 and answers "may this start"; `record-restore-exit.sh --phase <p>` runs at its final step and answers "did it finish". One check per bookend: a phase never runs the next phase's entry check, and never re-checks its own entry at the end. Both write dated, indexed runs into one category — `reimaged-system/bookends/` — so a single `MANIFEST.md` answers whether a phase both started and finished, and a question asked three days later has an answer.
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

4b) docs/ -- parked work, tracked

Six directories, tracked in full. They exist so a note has an obvious home and
does not become a line in a chat log nobody reads again.

- docs/architecture/ -- design records: how one mechanism works and why it was
                    built that way. Options, the alternatives rejected and the
                    reason, the decision, the scope, the plan. A record without
                    its rejected alternatives is an assertion, not a decision.
- docs/cross-cutting-findings/ -- findings bundles whose fix lands in shared
                    machinery rather than in one runbook. See 4c.
- docs/ideas/    -- things that do not exist yet. A new script or a new
                    sub-command on one, a new runbook, a new reference, a new
                    artifact pattern or layout. What to build, not how.
- docs/ledgers/  -- dated statements of what exists, what is stale and what is
                    owed. A ledger is read to decide what to do next and is
                    replaced wholesale when it is re-derived; a gap is read once
                    and closed.
- docs/runbook-findings/ -- findings bundles for one runbook, one directory per
                    runbook stem. See 4c.
- docs/sessions/ -- session handoffs, and the prompts that start the next session.

The line between ideas and findings is whether the thing exists. An idea is a
NEW capability. Anything about work already here -- a fix, a refactor, a rename,
a layout reorganisation, prose that needs correcting, a script that needs
improving -- is a finding, however large, and belongs in a bundle (4c). "The
toolkit should have a command that reconciles rescue branches" is an idea; "the
rescue-branch step names the wrong path" is a finding, and so is "these six
scripts should be restructured".

The line between ideas and architecture is what the document answers. "We should
index the time-machine category" is an idea; "here are the four ways to index it,
why three were rejected, and what the chosen one touches" is architecture. An
idea that has been designed becomes an architecture record; it does not stay in
both.

Rules for an AI session:
- WRITE here rather than widening the task. Finding a second defect while fixing
  the first is normal; fixing both in one change is how a small edit becomes an
  unreviewable one. Park it as a findings bundle (4c) and say so in the summary.
- READ the findings indexes and docs/sessions/ before starting work in an area --
  the answer to "why is this half-done" is often already written down.
- These files ARE tracked and reach a fresh clone, so writing one IS a
  repository change and takes an APPLY-MANIFEST.md revision like any other.
  Revision 162 exempted them, on the reasoning that a note about the workflow is
  not a change to the workflow. That reasoning was load-bearing only while the
  contents were gitignored and invisible to the diff; once they are under version
  control the owner reviews them, and anything the owner reviews belongs in the
  record of what changed.
  A revision covers a CHANGE, not a file: a session that parks three notes in one
  sitting writes one entry naming all three, the same way a revision that edits
  nine documents is one entry. Parking stays cheap; it stops being invisible.
  Anything that must be true for the workflow to work still belongs in the
  runbook it concerns, not in a note.
- One file per item, named for the thing rather than the date. A dated filename
  sorts by when someone noticed, which is never the question being asked. The
  findings bundles in 4c are the exception and say why.

4c) Findings bundles -- docs/runbook-findings/ and docs/cross-cutting-findings/

A findings bundle is a READING of something that already exists: what was found,
where it is felt, and what it costs to leave. It is not a change. Recording one
touches no tracked file and takes no manifest revision.

Which of the two:

- docs/runbook-findings/<runbook>/ -- felt in one runbook. The directory is named
                    for the runbook stem, without `.md`.
- docs/cross-cutting-findings/ -- felt in shared machinery. The test is where the
                    FIX lands, not where it was noticed: a defect in
                    `.internal/sign-offs.sh` found while reading
                    `restore-repos.md` is cross-cutting, because six phases share
                    the file.

A bundle is a NUMBERED DIRECTORY rather than a file -- the exception to the
one-file rule in 4b, because a finding accumulates two more documents as it is
worked, and they are only legible together:

    <NNNN>-<slug>/
    |-- STATUS-<status>  the tag. One file, no contents required; renamed as the
    |                   bundle moves. `ls` answers the status without opening
    |                   anything, and a bundle whose tag disagrees with its
    |                   INDEX.md row is a bug in whoever moved it last.
    |-- findings.md     the reading. Written once; corrected only for accuracy,
    |                   never rewritten to match what was later decided.
    |-- decisions.md    written during `in progress`: what was decided for each
    |                   finding, and the alternatives rejected. A decision
    |                   without its rejected alternatives is an assertion.
    `-- resolutions.md  written during `resolving`: what was actually done, with
                        the commit hash and the APPLY-MANIFEST.md revision that
                        carries each one.

Numbers are ONE sequence across both directories, so `finding 0007` names a
bundle without needing its scope. Four digits, zero-padded, never reused, never
renumbered -- a renumber breaks every session prompt already written against the
old one. Take the next free number immediately before writing; another session
may have taken the one you saw:

    ls -d docs/runbook-findings/*/[0-9]*/ docs/cross-cutting-findings/[0-9]*/ 2>/dev/null

Status lives in the scope's INDEX.md for the bundle, and in findings.md for each
finding inside it. THE FIVE STATUSES AND WHAT EACH MEANS ARE DEFINED IN
`docs/legend.md`, which is also where the session states live -- one place for
both vocabularies, so a reader sees the two lifecycles side by side. Do not
restate them here or in an index.

A bundle holds the earlier status while any finding in it is still open. Partial
progress belongs in the INDEX.md Notes column, not in a softened status.

Each bundle's INDEX.md row also names the session bundle working it, when one
is; the other half of that pointer is the session's own `findings-manifest.md`
(4d), which is authoritative for what a session owns.

The status is written in two places and they must agree: the INDEX.md row, which
is authoritative, and the `STATUS-<status>` tag file in the bundle, which exists
so the state is visible in a directory listing. Spaces become hyphens:
`STATUS-in-progress`. The tag is a marker file and NOT a suffix on the directory
name -- the directory name is what session prompts and other documents cite, and
renaming it on every transition is the failure
`docs/cross-cutting-findings/0009-dated-artifacts-cite-run-ids-a-rename-breaks/findings.md` describes.

Handing one off: when a bundle needs another session -- because its files are
contended, because it is larger than the current session, or because it belongs
to a different owner -- write the prompt in docs/sessions/ and name the finding
number and its path in the opening lines, so the session that picks it up reads
the bundle itself rather than a summary of it:

    Finding 0001 -- docs/runbook-findings/restore-apps/0001-restore-repos-evidence/
    (runbook: restore-apps.md)

    Finding 0007 -- docs/cross-cutting-findings/0007-<slug>/
    (cross-cutting: no single runbook owns it)

4d) Session bundles -- docs/sessions/<title>-<stamp>/

A session that needs more than a prompt gets a directory. A prompt, the handoffs
it leaves, the findings it owns and its final summary belong together, and a
session almost always ends up with more than one document.

    docs/sessions/<title>-<stamp>/
    |-- STATE-<state>            the tag, as in 4c. Required, always.
    |-- prompt.md                what starts the session. Required, always.
    |-- metadata.md              who and what has owned it. Required from
    |                            `owned` onward.
    |-- findings-manifest.md     the bundles this session owns. Required once it
    |                            owns one.
    |-- handoff-<stamp>.md       one per handover; never edited afterwards.
    `-- final-summary.md         written when the session reaches `closed` or
                                 `withdrawn`.

`<title>` is a short readable scope, chosen by the owner or by the session
writing the prompt -- what someone scanning the directory is matching on.
`<stamp>` is `YYYYMMDD-HHMMSS` in local time, the artifact-root format, and makes
the name unique without a counter. The name carries no finding number: a session
routinely owns several bundles, and one number in a directory name could never
say so. The name is fixed at creation. Renaming it breaks every prompt, handoff
and index row already written against it -- the failure in
`docs/cross-cutting-findings/0009-dated-artifacts-cite-run-ids-a-rename-breaks/findings.md`.

Every `prompt.md` names `.github/copilot-instructions.md` as required reading,
before anything else it asks the session to read. That holds for every session
regardless of state, scope or assistant; a prompt that omits it is incomplete.

`findings-manifest.md` is where the session's ownership of findings is recorded:
one row per bundle, with its number, its path, whether it is a runbook or
cross-cutting bundle, its status when the row was last touched, and what this
session owes it. It is authoritative. `docs/sessions/INDEX.md` carries the count
and points here rather than restating the list, so the two cannot disagree. Each
bundle's own INDEX.md row names the session folder working it, which is the other
half of the pointer.

Where a prompt comes from:

- **Hand-written by the owner.** The bundle starts `unclaimed`.
- **Written inside a running session for use by a new one.** The bundle starts
  `unclaimed` when it is preparation for work with no scheduled start, and
  `handoff` when it is a continuation of what the writing session is doing now.
  In both cases the prompt is complete before it is needed: the owner may pick it
  up hours or days later, and the session that wrote it will not be there to
  explain it.

State is recorded in `docs/sessions/INDEX.md` and in the tag. THE FIVE STATES
AND WHAT EACH MEANS ARE DEFINED IN `docs/legend.md`, beside the findings
statuses. What each state REQUIRES is here:

- `unclaimed` -- `prompt.md` and the tag. Nothing else.
- `owned` -- `metadata.md`, and the assistant and date in the INDEX.md row.
  `metadata.md` is authoritative for WHO and WHAT: one row per owner, with the
  assistant (`Claude` or `Copilot`; those are the two approved), its session
  identifier and transcript link where the tool exposes one, the model it was
  configured for, the environment it actually ran in, and the dates it held the
  bundle. A bundle handed on has several rows; none is ever edited once the
  ownership it records has ended.
  The environment field is not decoration. This workflow targets macOS stock Bash
  3.2, an AI session almost never runs there, and a claim validated on Linux is a
  different claim -- `metadata.md` is where that is on the record rather than
  remembered. An unidentifiable session is still `owned`: write what is known and
  say what is not.
- `handoff` -- `handoff-<stamp>.md`, plus the date and time the owner decided to
  hand off and, once known, the incoming assistant. The document carries:
  progress so far, exactly where the work stopped, every assumption the outgoing
  session was working under, and the resources the next one needs -- files,
  folders to connect, volumes to mount, prior revisions to read. There may be
  several; each records one handover and is never edited afterwards. The outgoing
  bundle and the continuation bundle each name the other.
- `closed` -- `final-summary.md`, naming the date and time the work completed and
  listing EVERY commit hash and APPLY-MANIFEST.md revision the session
  contributed, across all of its owners. A closed session's contribution should
  be readable from that one file without reconstructing it from git.
- `withdrawn` -- `final-summary.md` as well, and this is the state where it
  matters most. Write down what the work reached before it stopped: what was
  contributed, which findings are still open and at what status, what was
  assumed, and why the owner pivoted. A withdrawn session that recorded nothing
  is indistinguishable from one that did nothing, and the findings it leaves
  behind are the ones somebody picks up cold.

Everything under `docs/sessions/` is a bundle. Two files are not, and are not
meant to be: `INDEX.md`, and `session-responsibilities.md`, which describes the
relationship BETWEEN concurrent sessions and so belongs to none of them.

A converted bundle whose start time could not be recovered is stamped `-000000`.
That is a visible marker of *date known, time not*, and applies only to the five
bundles Revision 162 converted from loose files. A bundle created from now on
stamps the moment it was made.


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
