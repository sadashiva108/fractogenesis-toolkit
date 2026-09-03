# Session prompt — Restore Repositories Refactor

Copy everything below the rule into a new session.

---

Working in **fractogenesis-toolkit**. This session is **Restore Repositories
Refactor**. It executes the plan in
`docs/sessions/restore-repos-refactor-20260902-000000/restore-repos-phase-11b-plan.md`, which a prior session produced
and I approved. A second session, **Run-index design and evidence conformance**,
is running concurrently — the ownership split is in
`docs/sessions/session-responsibilities.md`. Read that before your first edit.

**FIRST: connect two folders.** Do not read, plan, or answer anything until both
are reachable:

- the repo: `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit`
- the artifact root: `/Volumes/Data/reimage-CVG-0002160-500-20260816-open`

If only one arrives, say which is missing and wait. Several items below verify
evidence on the volume, not just code in the repo. Do not work around a missing
folder by reasoning from memory or from this prompt; nothing here substitutes for
reading the files.

Once both are there, read in this order:

1. `docs/sessions/restore-repos-refactor-20260902-000000/restore-repos-phase-11b-plan.md` — the plan. Its §1 table has a
   numbered change per row, the runbook step each is felt at, and the entrypoint
   the runbook actually calls.
2. `docs/runbook-findings/restore-repos/0020-repo-audit-tsv-column-shift/findings.md` and
   `docs/runbook-findings/restore-repos/0023-restore-repos-rsync-targets-pre-image-path/findings.md` — the two defects
   that drive the order below.
3. `docs/runbook-findings/restore-repos/0022-restore-repos-missing-exit-recorder-steps/findings.md` — the runbook half.
4. `.github/copilot-instructions.md` — repo conventions. §4b covers `docs/` and
   when to write to `docs/*-findings/` instead of widening a task.
5. `.github/ai-prompts/script-prompts/bash-script-authoring-and-review.md` before
   editing any script, and
   `.github/ai-prompts/runbook-prompts/runbook-prompt.md` before editing any
   runbook.

`.claude/CLAUDE.md` is a pointer to those, not a second copy.

## Standing rules

- **Never commit. I commit.** Leave the work uncommitted in the working tree.
- Every repository change gets a new `APPLY-MANIFEST.md` revision. It is at
  **Revision 128**. Re-read the header immediately before writing your entry and
  take the next free number — a concurrent session collided on 123 once already,
  and one is running now.
- Validate with `./bin/verify-doc-paths.sh --all`,
  `./bin/verify-runbook-structure.sh`, `./bin/verify-script-portability.sh`, and
  `bash -n` on every edited script.
- **Baselines to compare against, not to zero:** doc-paths 745 OK / 0 MISSING /
  0 ANCHOR BROKEN; runbook-structure **29 FAIL / 5 WARN** across 27 documents
  (every remaining failure is `NO-NOTE` or `LEGEND`); portability 0 FAIL.
- Target is macOS stock Bash 3.2 + BSD userland. You are on Linux with Bash 5.x.
  Name the environment a check ran in — "tested on Linux" and "tested on the
  target Mac" are different claims. `/bin/bash -n` on the real Mac is still owed
  on Revisions 116–128 and will be owed on this work.
- Artifact naming, timestamping, retention and pointer policy are runbook-level
  decisions — present options with tradeoffs before changing any of them.
- Park anything found mid-task in `docs/*-findings/` rather than widening the work.
- **Do not run `rsync-repos-gitignored.sh` from any existing bundle.** It targets
  a path that does not exist and `rsync -a` would create it, putting decrypted
  secrets outside every repository.
- **Never re-record `--point before` for `restore-repos`.** It is first-wins, the
  existing baseline is clean and correctly timed, and a late one indexes as a run
  that looks like a baseline and is not.

## Order of work

Strict. Do not start one before the previous is settled.

### 0 — Decision A, before any code

`repos.tsv` in the one pre-image audit is structurally damaged and the source
machine is gone. Four repair options with costs are in the plan's Decision A.
The prior session recommends **(ii)**: write a corrected run as a new indexed
`pre-image-*` run carrying a manifest note that it is a re-derivation, and pin
it — which touches no existing evidence.

**Ask me which option before writing anything.** Everything below assumes an
answer.

### 1 — Change 1: stop the audit writing tabs into a TSV

`.internal/git/capture-repo-audit.sh:429`. One line. Called through
`bin/backup-repos.sh` from `backup-repos.md` **Step 4**. Fixes Phase 2A forever;
does not repair the existing run.

### 2 — Changes 2, 3 and 4: one atomic edit to `bin/restore-repos.sh`

They interlock — routing decides `CLONE_TARGET_ROOT`, which the other two need.

- **Change 2** — emit both rsync destinations at `$CLONE_TARGET_ROOT/$label`.
  Felt at `restore-repos.md` **Step 5** and **Step 6**; emitted at **Step 1**.
- **Change 3** — test `PATH_PRESENT` at the resolved clone destination. Felt at
  **Step 1** and **Step 9**.
- **Change 4** — route by remote host, not pre-image directory. Decided at
  **Step 1**, surfaces at **Step 2** and **Step 3**.

Retire the Troubleshooting entry *"`clone-commands.sh` stops at the first repo
because the target directory already exists"* in the same change — it documents a
symptom of Change 3.

### 3 — Change 5: emit a usable SHA

`head` holds the full decorated log line, so the emitted
`git cat-file -e '<...>^{commit}'` is malformed. Take the leading SHA only.
Emitted at **Step 1**, runs at **Step 3**.

### 4 — Execute Decision A

Build the corrected pre-image data by whichever option I chose. All URLs are
recoverable from `repo-audit-summary.txt` — 60 URL lines, 27 repositories,
including the two with no remote (`engagements`, `ingestion-related`) and the two
spanning both hosts (`reference-vault`, `carrier-services-storage`).

Then regenerate a status bundle and confirm `clone-commands.sh` is no longer
empty. It currently holds 0 clone lines and 27 "no remote URL recorded" comments.

### 5 — Change 6: add Steps 9a, 9b, 9c to `restore-repos.md`

`--point after`, `--point delta`, then `record-restore-exit.sh`. Mirror
`restore-git.md` exactly, `--dry-run` line above each real one. Adding after
Step 9 renumbers nothing; update the Table of Contents and back-links.

### 6 — Change 9: reconcile Step 9's exit table with the recorder

Two exit-criteria tables exist and disagree; the runbook's is the one never
recorded. The recorder owns the boundary. Also reword the transport rows: **all
27 pre-image remotes are HTTPS**, `GIT_PERSONAL_GITHUB_HOST` is `github.com`, and
`rewrite_remote_for_host` is gated on `"$host" != "github.com"` so it can never
fire. *"Personal repos route via the personal SSH host alias"* asks a question
this machine's evidence cannot answer yes to. Revision 126 did this for
`restore-git`; do the same here.

### 7 — Change 7: reconcile the Bundle Layout

`restore-repos.md` → **Artifact and Script Locations → Bundle Layout**
omits `rsync-repos-gitignored.sh`, which Step 6 uses, and lists `MANIFEST.txt`,
which no run on disk has.

### 8 — Change 8: the stale file count

`bin/restore-repos.sh` report template still says *"Neither file is executable by
default"*. There are three.

### 9 — Validation and the manifest entry

Run the four checks against their baselines, write one `APPLY-MANIFEST.md`
revision describing the whole change set, and stop. Do not commit.

## What is contended

`bin/reimage-checklist.sh` belongs to the other session — it is fixing a Phase 6B
row there. If this work reaches into it, **flag rather than edit**.

Everything else in the phase is yours: `restore-repos.md`, `bin/restore-repos.sh`,
`bin/backup-repos.sh`, `backup-repos.md`, the `.internal/git/` helpers, and the
`repo-audit-reports/`, `gitignore-superset/` and `staged-ignored-files/`
structure.

**Two settled conclusions, not open questions.** `gitignore-superset/` is a
stable input surface and does not join the run index.
`staged-ignored-files/live` is one of three sibling modes and its fixed path in
`restore-repos.sh` is a deliberate exception. The reasoning is in the plan's §2.
Say so only if you disagree.

## Deliverables

- The changes above, uncommitted.
- One `APPLY-MANIFEST.md` revision.
- Anything found and not fixed under `docs/*-findings/`, one file per item, named for
  the thing rather than the date.
- A short summary of what needs my decision, separated from what does not.
