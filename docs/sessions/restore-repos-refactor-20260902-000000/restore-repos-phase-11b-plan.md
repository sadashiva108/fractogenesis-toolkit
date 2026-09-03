# Phase 11B — Restore Repositories: plan and handoff

**Item 1** of `docs/sessions/run-index-design-20260901-000000/prompt.md`. Analysis and
design only. Nothing in the repository was changed to produce this, and no
`APPLY-MANIFEST.md` revision is owed — everything under `docs/` is gitignored.

Written by session `01KcZvrKMgfenhrT9DvxW9Jk` ("Run-index design and evidence
conformance"), 2026-09-01, against the repo and the artifact volume
`/Volumes/Data/reimage-CVG-0002160-500-20260816-open`.

Execution of this plan belongs to a separate session — see
`docs/sessions/restore-repos-refactor-20260902-000000/prompt.md` and
`docs/sessions/session-responsibilities.md`.

---

## Table of Contents

- [[#The finding that reorders item 1|The finding that reorders item 1]]
- [[#Starting facts — confirmed, and two corrections|Starting facts — confirmed, and two corrections]]
- [[#1. Refactor plan — Phase 11B captures and scripts|1. Refactor plan — Phase 11B captures and scripts]]
- [[#2. Retrofit analysis — the two unconverted categories|2. Retrofit analysis — the two unconverted categories]]
- [[#3. Re-run ledger — Phase 11B|3. Re-run ledger — Phase 11B]]
- [[#Gaps parked|Gaps parked]]
- [[#Handoff|Handoff]]
- [[#Decisions required|Decisions required]]

---

## The finding that reorders item 1

**Phase 11B's automated path is dead, and it is not a run-index problem.**

`repo-audit-reports/runs/pre-image-20260816-035617/repos.tsv` is structurally
damaged. `.internal/git/capture-repo-audit.sh` line 429 builds the
`remote_urls` cell with:

```bash
remotes="$(git -C "$repo" remote -v 2>/dev/null | awk '!seen[$0]++' | paste -sd '; ' - || true)"
```

`git remote -v` is itself tab-separated, `paste` does not squash those tabs, and
the `printf` at line 462 writes the cell into a TSV — so every remote line spills
two extra columns and shifts everything to its right.

Verified on disk:

- `remote_urls` (column 4) holds `origin` — the remote *name*. The URL sits in
  the `status_summary` column.
- `extract_remote_url()` in `bin/restore-repos.sh` therefore returns empty for
  **27 of 27** repositories.
- The latest emitted `clone-commands.sh` contains **0** `git clone` lines and
  **27** `# <label> -- no remote URL recorded in pre-image audit` comments.
- `local_only_commit_count`, `stash_count` and `tracked_change_count` are read
  from shifted columns, so every `carry_forward_rows` figure in
  `restore-status.md` is meaningless. `ingestion-related: 38` is column drift,
  not 38 pieces of unpreserved work.
- `record-restore-prereqs.sh` already caught this. The entry run
  `restore-repos-entry-20260825-033849` records
  `Audit remote URLs are URLs — FAIL — 25 row(s) hold a remote NAME where the
  URL belongs`. The phase proceeded anyway; the 9 repositories on disk were
  cloned by hand.

The defect is still present at HEAD. The pre-image machine no longer exists, so
the audit cannot be re-captured — but **every URL is recoverable**:
`capture-repo-audit.sh` line 539 writes `git remote -v` verbatim into
`repo-audit-summary.txt`. 60 URL lines across 27 repositories, all resolvable.

### The second finding, and this one is unsafe to run

Both emitted rsync scripts target the **pre-image** path, not the clone
destination:

```bash
rsync -a --stats \
  ".../staged-ignored-files/live/fractogenesis-toolkit/" \
  "/Users/dkittrell/Development/documentation/fractogenesis-toolkit/"
```

Clones land under `$GIT_WORK_REPO_ROOT` / `$GIT_PERSONAL_REPO_ROOT`
(`workspace/orah`, `workspace/shiva`). `/Users/dkittrell/Development/...` does
not exist on the reimaged Mac, and `rsync -a` **creates it**.
`rsync-repos-gitignored.sh` carries the same target, so running it today writes
decrypted DMG secrets into a resurrected `Development/` tree — in the clear,
outside every repository, where nothing later in the workflow looks.

The same root cause propagates. `classify_repo()` tests `$repo_path/.git` at the
pre-image path, so `PATH_PRESENT` is permanently `no`. Therefore:

- `Needs clone: 0` in Step 9 can never be reached;
- `--apply-ignored-files` is gated on `PATH_PRESENT == yes` and silently does
  nothing for every repository;
- `IGNORED_FILES_COMPLETE` can never become true;
- the Troubleshooting entry *"`clone-commands.sh` stops at the first repo because
  the target directory already exists"* documents a symptom of this defect as
  normal behaviour.

> **Do not run `rsync-repos-gitignored.sh` from any existing bundle.**

---

## Starting facts — confirmed, and two corrections

Confirmed exactly as the brief states:

- The evidence completeness map, all five rows, checked against
  `reimaged-system/{boundaries,state,comparisons,restarts}/official/`.
- `repo-audit-reports/` is converted — 2 pointers, 4 runs, plus the renamed
  domain manifest `repo-audit-index.md` (`# Repository Audit Index`), which is
  correct and stays.
- `restore-repos.sh` resolves `artifact_run_official … pre-image` for input and
  stages `post-image-restore` for output. Re-running it cannot read its own
  output as input.
- The `restore-repos-before` walk is clean and correctly timed: taken
  20260825-034004, four seconds ahead of the first restore run, both clone roots
  recorded `absent`.

**Correction 1 — `staged-ignored-files/` has 3 items, but they are not loose.**
They are `dryrun/`, `dryrun-filtered/` and `live/` — three sibling *modes*
written by `bin/backup-repos.sh` mode flags. Not a run category wearing the
wrong shape.

**Correction 2 — the missing `after` and `delta` were never skipped; the runbook
never called for them.** `restore-repos.md` invokes
`record-restore-prereqs.sh` and `record-restore-state.sh --point before`, and
nothing else. No `--point after`, no `--point delta`, no
`record-restore-exit.sh`. `restore-git.md` and `restore-access.md` invoke all
three. The exit run on disk (`restore-repos-exit-20260825-042214`) was taken by
hand outside the runbook. Step 0b even promises *"the delta against the
after-state is then literally the list of what this phase restored"* — a delta
the runbook never takes.

---

## 1. Refactor plan — Phase 11B captures and scripts

Ordered by what unblocks the phase, not by file. "Runbook step" is where the
change is felt; "Entrypoint" is what the runbook actually invokes, which for an
`.internal/` helper is never the helper itself.

| # | Change | Runbook step | Entrypoint the runbook calls | File edited | Why |
|---|---|---|---|---|---|
| 1 | Squash tabs before joining: `git remote -v \| tr '\t' ' ' \| awk '!seen[$0]++' \| paste -sd '; ' -` | `backup-repos.md` **Step 4 — Run the Repository Audit** (reviewed at Step 5) | `bin/backup-repos.sh` | `.internal/git/capture-repo-audit.sh:429` | One line. `extract_remote_url` already splits on `;` then whitespace, so the corrected format is exactly what the consumer expects. Fixes Phase 2A permanently; does **not** repair the existing pre-image run. |
| 2 | Emit rsync targets at `$CLONE_TARGET_ROOT/$label`, not `$repo_path` | emitted at `restore-repos.md` **Step 1**; consumed at **Step 5** and **Step 6** | `bin/restore-repos.sh` | `bin/restore-repos.sh` — `RSYNC_CMDS` and `GITIGNORED_CMDS` blocks | The secrets-into-a-phantom-tree defect. Highest severity in the phase. |
| 3 | Test `path_present` at the resolved clone destination, not the pre-image path | `restore-repos.md` **Step 1** and **Step 9** | `bin/restore-repos.sh` | `bin/restore-repos.sh` — `classify_repo()` | Makes `Needs clone: 0`, `--apply-ignored-files` and `IGNORED_FILES_COMPLETE` reachable. Retires the Troubleshooting entry that documents the symptom. |
| 4 | Route by **remote host**, not pre-image directory | decided at `restore-repos.md` **Step 1**; surfaces at **Step 2** and **Step 3** | `bin/restore-repos.sh` | `bin/restore-repos.sh` — `classify_repo()` | Step 3's prose already states the rule the script contradicts: *"which root a repo belongs in is decided by its remote host, not by where it lived pre-image."* `record-restore-exit.sh` row 3 grades against the host. On this machine the pre-image roots (`Development/...`) are under neither configured root, so the script routes all 27 to work. |
| 5 | Take the leading SHA only for the `cat-file -e` proof | emitted at `restore-repos.md` **Step 1**; runs at **Step 3** | `bin/restore-repos.sh` | `bin/restore-repos.sh` — clone-command emitter | `head` holds `33264a7 (HEAD -> master, origin/master, origin/HEAD) added gateway-monitoring-assistant to drivers list`. The emitted `git cat-file -e '<all that>^{commit}'` is malformed. |
| 6 | Add `Step 9a — after`, `Step 9b — delta`, `Step 9c — exit` | `restore-repos.md` **Step 9** (new **9a / 9b / 9c**) | `bin/record-restore-state.sh`, `bin/record-restore-exit.sh` | `restore-repos.md` | Closes the structural gap in Correction 2. Mirror `restore-git.md` Steps exactly, `--dry-run` line above each real one. |
| 7 | Reconcile the bundle layout with what the script writes | `restore-repos.md` → **Artifact and Script Locations → Bundle Layout** (not a numbered step) | — | `restore-repos.md` | Layout omits `rsync-repos-gitignored.sh`, which Step 6 uses, and lists `MANIFEST.txt`, which no run on disk has. |
| 8 | `"Neither file is executable by default"` → three files | surfaces in `restore-repos.md` **Step 1** output | `bin/restore-repos.sh` | `bin/restore-repos.sh` — report template | Cosmetic. The count went stale when the DMG script was added. |
| 9 | Reconcile Step 9's exit table against `record-restore-exit.sh`, and reword the transport rows | `restore-repos.md` **Step 9** | `bin/record-restore-exit.sh` | `restore-repos.md` | Two exit-criteria tables exist, they do not agree, and the runbook's is the one never recorded. Convention says the recorder owns the boundary. The SSH-alias row also cannot be answered on this machine — see Handoff. |

**Explicitly out of scope.** `bin/restore-repos.sh` already resolves
`artifact_run_official … pre-image` for input and stages `post-image-restore`
for output. Its run-index integration is correct and needs nothing.
Revision 121 / 127-style conversion work does **not** apply to this phase.

**Two cosmetic notes, not worth a change on their own.** The context
`post-image-restore` has no recognised point suffix, so `_artifact_runs_point_of`
returns `unknown` and every run prints `latest-wins applies` to stderr — correct
behaviour, mildly noisy. And `repo-audit-reports/sign-offs/` does not exist on
disk: no run has yet reached the current `signoff_begin` code, so the three
bundles from 2026-08-25 predate it and were recovered by `reindex`.

---

## 2. Retrofit analysis — the two unconverted categories

### `gitignore-superset/` — do not convert

`references/master-directory-reference.md` already classifies it: *"Per-run
generated files — written to and read from the artifact root."* Three of its
files are **operator-maintained**, seeded once from
`.internal/templates/gitignore-superset/` and never overwritten:
`backup-exclude-list.txt`, `secrets-patterns.txt`,
`gitignore-review-template.direct-nonsecret-recommended.txt`.

What reads it, and what conversion would move:

| Reader | Path shape | Breaks on conversion |
|---|---|---|
| `bin/backup-repos.sh:267` | `$REIMAGE_ARTIFACT_ROOT/gitignore-superset` fixed | yes |
| `bin/stage-certs-keychain.sh:503` | `--gitignore-dir ".../gitignore-superset"` | yes |
| `bin/reimage-checklist.sh:715` | `$GITIGNORE_DIR/gitignore-review-template.txt` fixed | **yes — Phase 6B check** |
| `backup-repos.md` (14 references) | `cp -p` workspace-stash pairs, both directions | yes |

It is a **stable input surface with generated companions**, not a lineage. A run
index answers *"which capture is official"*; nothing here asks that —
`backup-repos.sh` asks *"where are my three input files"*. Converting buys
nothing and costs a Phase 6B gate.

**Recommendation: leave it, and write the exception into
`references/master-directory-reference.md`** so a later coverage audit (item 4)
does not reopen it.

### `staged-ignored-files/` — do not convert; `live/` is a deliberate exception

`live/` is one of three **modes**, not a run:

| Mode flag on `bin/backup-repos.sh` | Writes |
|---|---|
| `--selected-dry-run`, `--direct-ignored-dry-run` | `staged-ignored-files/dryrun/` |
| `--selected-filtered-dry-run` | `staged-ignored-files/dryrun-filtered/` |
| `--selected-copy`, `--direct-ignored-copy` | `staged-ignored-files/live/` |

The workflow is *dry run, filter, then commit*, and the three directories are
that workflow's three states. Readers at fixed paths:
`bin/reimage-checklist.sh` checks `staged-ignored-files/dryrun-filtered` and
`staged-ignored-files/live/summary.txt` — **both Phase 6B rows**;
`bin/restore-repos.sh` resolves `live/<label>/`; `restore-home.md` and
`restore-access.md` cite `live/` in prose.

So the fixed `staged-ignored-files/live` path in `restore-repos.sh` is **a
deliberate exception, not an unconverted remnant** — the answer to the question
posed in the brief. The run-index library has no mode-by-lineage shape, and
inventing one for a category that is finished forever is the wrong trade.

**Sign-off exposure for both categories: none.**
`repo-audit-reports/sign-offs/` is empty and `reimaged-system/sign-offs/` holds
only `enroll-and-stabilize-exit` and two `restore-git-exit` files. No Phase 6B or
Phase 11B sign-off cites a path in either category.

**One oddity recorded separately** — `live/` mixes per-repo bundles with the
run's own metadata at the same level, and carries two entries that are not repo
labels. See `docs/runbook-findings/backup-repos/0025-staged-ignored-files-live-parent-root-bundles/findings.md`.

---

## 3. Re-run ledger — Phase 11B

Every Phase 11B file except `.internal/git/collect-gitignore-superset.sh` has
changed since the 2026-08-25 evidence was written, so "predates its producer" is
true across the board unless noted.

| # | Capture / recorder / script | Has run | Changed under it since | Point rule | Re-run: safe / noisy / forbidden | Advances a pointer | Order |
|---|---|---|---|---|---|---|---|
| 1 | `.internal/git/capture-repo-audit.sh` via `bin/backup-repos.sh` (Phase 2A) | yes, 2026-08-16 | yes, bug unfixed | `pre-image`, unknown → latest | **forbidden — impossible.** The pre-image machine is gone | n/a | — |
| 2 | Re-derived `repos.tsv` from `repo-audit-summary.txt` | no | — | `pre-image`, latest-wins | **decision required** — see Decision A | would advance `official/pre-image.txt` | **1st** |
| 3 | `bin/record-restore-prereqs.sh --runbook restore-repos` | yes — `restore-repos-entry-20260825-033849`, **1 FAIL / 2 WARN** | yes (`c4184dd`) | `entry` → latest | **safe**, cheap, rerunnable at any point | yes | 2nd |
| 4 | `bin/restore-repos.sh` (status bundle) | yes ×3, all with 0 clone commands | yes (`9a55ee7`) | `post-image-restore`, unknown → latest | **safe** — read-only — but worthless until #2 | yes | 3rd |
| 5 | `clone-commands.sh` | emitted, 0 commands | — | n/a | **safe** once regenerated | no | 4th |
| 6 | `rsync-ignored-files.sh` | emitted, wrong target | — | n/a | **noisy** — writes into a phantom tree. Blocked on refactor change 2 | no | 6th |
| 7 | `rsync-repos-gitignored.sh` | emitted, wrong target | — | n/a | **forbidden until refactor change 2.** Writes cleartext secrets outside every repository | no | 7th |
| 8 | `bin/record-restore-state.sh --runbook restore-repos --point before` | yes — `restore-repos-before-20260825-034004`, clean | yes (`bb7e2d5`) | `before` — **first-wins** | **forbidden.** A late `before` indexes as a run that looks like a baseline and is not; the library will refuse to advance the pointer and say so on stderr | no | — |
| 9 | `bin/record-restore-state.sh --runbook restore-repos --point after` | **never** | n/a | `after` → latest | **safe**, and owed | yes — creates `official/restore-repos-after.txt` | 8th |
| 10 | `bin/record-restore-state.sh --runbook restore-repos --point delta` | **never** | n/a | `delta` → latest | **safe**; needs #9 first | yes | 9th |
| 11 | `bin/record-restore-exit.sh --runbook restore-repos` | yes — `restore-repos-exit-20260825-042214`, 3 PASS / 3 manual TODO | `check_restore_repos()` **unchanged** since | `exit` → latest | **safe**; re-run at the true end of the phase | yes | 10th |
| 12 | `bin/reimage-checklist.sh` Git Audit rows | n/a | yes (`c4184dd`) | n/a | **currently records a false FAIL** — see gaps | n/a | — |

Runbook Steps 3 through 8 (clone, repoint the toolkit, reconcile rescue branches
and stashes) sit as manual work between ledger rows 5 and 6.

---

## Gaps parked

One file each under `docs/*-findings/`:

| File | What |
|---|---|
| `repo-audit-tsv-column-shift.md` | The `capture-repo-audit.sh` defect, blast radius, and fix |
| `restore-repos-rsync-targets-pre-image-path.md` | The secrets-to-a-phantom-tree defect. Marked unsafe to run |
| `reimage-checklist-repo-audit-manifest-header.md` | A Phase 6B row that records FAIL against a correct manifest |
| `restore-repos-missing-exit-recorder-steps.md` | The Step 9a/9b/9c gap, if not folded into the refactor |
| `staged-ignored-files-live-parent-root-bundles.md` | `IdeaProjects` and `documentation` bundles no `<label>` lookup reaches |
| `internal-restore-directory-empty.md` | `.internal/restore/` tracked and empty; the scripts guide still describes it |

---

## Handoff

### Must not touch

- `reimaged-system/state/official/restore-repos-before.txt` and its run.
  First-wins, correctly timed, and the only baseline that exists. Do not
  re-record `--point before` under any circumstance.
- `time-machine/sign-offs/` and `reimaged-system/sign-offs/` — out of scope
  entirely. Revision 116 made sign-offs deliberately un-indexed.
- `repo-audit-reports/repo-audit-index.md` — the renamed domain manifest from
  Revision 120. Correct, and it stays.

### Must know, and is not in the plan above

- **The executing session will run on Linux with Bash 5.x.** `/bin/bash -n`
  against real macOS Bash 3.2 is **still owed on Revisions 116–128** and will be
  owed on this work too. Name the environment a check ran in; do not report
  "verified".
- **Only one repository is genuinely personal** — `fractogenesis-toolkit` →
  `github.com/sadashiva108` — and it is already cloned to `workspace/shiva`.
- **The alias-rewriting machinery is inert on this machine.**
  `GIT_PERSONAL_GITHUB_HOST=github.com`, and `rewrite_remote_for_host` is gated
  on `"$host" != "github.com"`. It can never fire.
- **All 27 pre-image remotes are HTTPS.** None is `git@github.com:`, so no
  rewrite path can ever run, and Step 9's exit row *"Personal repos route via the
  personal SSH host alias"* asks a question this machine's evidence cannot answer
  yes to. That row needs rewording against the transport actually in use —
  exactly what Revision 126 did for `restore-git`.
- **Two repositories have no remote at all** — `engagements` and
  `ingestion-related`. Nothing can clone them; their only copies are the backups.
  **Two more span both hosts** — `reference-vault` and `carrier-services-storage`
  — and need a per-repository root decision. All four are already WARN rows in
  the entry check.
- **No duplicate basenames** across the 27. The duplicate-label guard is correct
  and will stay quiet.
- **Neither session can see `/Users/dkittrell/workspace/*`.** Only the repo
  folder and the artifact volume are reachable from a Cowork session. Anything
  about what is actually on disk in the clone roots must be run on the Mac.

### Manifest revisions

`APPLY-MANIFEST.md` is at **Revision 128**. Neither session reserves a number in
advance. Re-read the header immediately before writing an entry and take the
next free number; if the intended number is taken, take the one after it. Two
sessions collided on Revision 123 once already.

---

## Decisions required

### A. How to repair the pre-image audit — gates everything

`repos.tsv` is wrong, the source machine is gone, and `repo-audit-summary.txt`
has every URL.

| Option | Cost |
|---|---|
| **(i)** Repair `repos.tsv` in place | Cheapest; violates the pre-image-evidence-is-immutable rule set for item 7 |
| **(ii)** Write a corrected run as a new indexed `pre-image-*` run with a manifest note saying it is a re-derivation, and pin it | Fits the run-index model, touches nothing existing, costs one new run directory. **Recommended** |
| **(iii)** Teach `restore-repos.sh` to fall back to `repo-audit-summary.txt` when the column is malformed | Rejected — a parser for a human-readable report is a permanent liability for a one-time data defect |
| **(iv)** Skip the tooling; hand-write the remaining 18 clone commands from the summary once | Viable, but leaves `restore-status.md` and the exit criteria permanently unable to report |

### B. Does `after` get taken now, or at the true end of Phase 11B?

`after` is latest-wins, so an early one is free and can be superseded. Taking it
now gives a checkpoint of the fast pass; waiting gives one clean pair.
**Recommendation: take it at the end, skip the checkpoint.**

### C. Fold the Step 9a/9b/9c addition into this refactor, or leave it parked?

It is a runbook change, so it belongs to the Restore Repositories Refactor
session either way. The question is whether it ships with the code fixes or
waits.
