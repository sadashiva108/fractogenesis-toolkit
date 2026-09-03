[[reimaging-guide#Phase 11B — Restore Repositories|← Back to Mac Reimaging Guide]]

# Restore Repositories

**Last updated:** 2026-09-02

Consume the pre-image repository audit produced by Phase 2A to re-clone the tracked repositories onto the reimaged Mac, rsync the reviewed kept ignored files back into each working tree, and reconcile every pre-image carry-forward row (local-only commits, stashes, tracked changes) against the state of the freshly cloned repos. Runs after Phase 11A has wired up the dual-identity `~/.gitconfig` and `~/.ssh/config`, so every clone this phase performs already routes through the correct SSH key.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#Carry-Forward Model|Carry-Forward Model]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Bundle Layout|Bundle Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 0 — Record Prerequisites and the Before-State|Step 0 — Record Prerequisites and the Before-State]]
    - [[#Step 1 — Produce the Initial Status Report|Step 1 — Produce the Initial Status Report]]
    - [[#Step 2 — Review the Plan Against the Report|Step 2 — Review the Plan Against the Report]]
    - [[#Step 3 — Clone the Selected Repositories|Step 3 — Clone the Selected Repositories]]
    - [[#Step 4 — Repoint at the Cloned Toolkit|Step 4 — Repoint at the Cloned Toolkit]]
    - [[#Step 5 — Restore Staged Ignored Files|Step 5 — Restore Staged Ignored Files]]
    - [[#Step 6 — Restore Per-Repo Gitignored Secrets from the DMG|Step 6 — Restore Per-Repo Gitignored Secrets from the DMG]]
    - [[#Step 7 — Reconcile Rescue Branches|Step 7 — Reconcile Rescue Branches]]
    - [[#Step 8 — Reconcile Stashes and Tracked Changes|Step 8 — Reconcile Stashes and Tracked Changes]]
    - [[#Step 9 — Rerun the Status Report|Step 9 — Rerun the Status Report]]
    - [[#Step 10 — Record the After-State and Delta|Step 10 — Record the After-State and Delta]]
    - [[#Step 11 — Close Out the Exit Criteria|Step 11 — Close Out the Exit Criteria]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Per-Repo Status Categories|Per-Repo Status Categories]]
    - [[#Hydration Outcomes|Hydration Outcomes]]
    - [[#Reading the Pre-Image TSVs|Reading the Pre-Image TSVs]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Restore the *content* side of the Git story: get every repository that existed on the pre-image machine back onto the reimaged Mac with its kept ignored files in place and its pre-image carry-forward material (rescue branches, stashes, uncommitted work) either merged in or explicitly discarded with a note. Phase 11A restored the identity plumbing; this phase uses that plumbing to bring the repositories themselves back.

**What it sets up**

- **The clone plan** — four fragments in `$REIMAGE_WORKSPACE_ROOT/repo-plan/` saying which repositories come back, where each goes, and what is merged into it after cloning. You write it once in Step 0d; every run reads it. It is the only durable, editable thing here — a run bundle is replaced, the plan is not.
- **The restore-status bundle** — a timestamped `post-image-restore-*` run under `repo-audit-reports/runs/` holding `restore-status.md`, the machine-readable `raw/status.tsv`, and copies of the pre-image inputs it classified against.
- **The Phase 11B sign-off** — `reimaged-system/sign-offs/post-image-restore-YYYYMMDD-HHMMSS.md`, holding the two rows only you can answer. It sits outside the run directory because a run is replaced on every rerun and an answered row must not be, and under `reimaged-system/` because that is where every post-image answered row lives — `repo-audit-reports/` is shared with the pre-image audit.
- **The record of what each run did** — `hydrated.md` in the bundle, one row per repository per stage, plus a row in `repo-audit-reports/repo-restore-index.md` so progress across several sittings is scannable without opening each bundle.
- **The restored working trees** — every tracked repository back on disk under the correct Git root, with its `staged-ignored-files/live/<label>/` bundle rsynced into place.
- **A closed carry-forward ledger** — every pre-image rescue branch, stash, and tracked change either merged, cherry-picked, left as a branch with a note, or explicitly discarded.

**What the rest of the workflow relies on it for**

- Phase 12 restores app and IDE state on top of the repositories this phase puts back on disk.
- The exit-criteria table inside `restore-status.md` is the Phase 11B sign-off evidence that every tracked repo and its kept ignored files are accounted for.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| reading the pre-image `repo-audit-reports/runs/pre-image-*/repos.tsv` inventory and classifying each repo (present / needs clone / ignored bundle available / carry-forward pending) | the pre-image push of rescue branches, stash preservation, and the reviewed kept ignored files — `backup-repos` (Phase 2A) |
| routing each repository to the root that matches its remote host, and cloning it there | dual-identity `~/.gitconfig`, `~/.ssh/config`, and the SSH routing hosts the clones authenticate through — `restore-git` (Phase 11A) |
| rsyncing `$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live/<label>/` back into each cloned working tree | the encrypted secret ignored files under `secrets-encrypted/repos-gitignored/`, which come back with the DMG — `restore-access` (Phase 10B) |
| the timestamped restore-status bundle under `repo-audit-reports/runs/post-image-restore-*/`, its exit-criteria table, and the Phase 11B sign-off | IDE-specific repo state such as IntelliJ project files and the VS Code workspace — `restore-intellij` and `restore-apps` (Phase 12) |

This runbook can be rerun. Each run writes a fresh timestamped bundle under `repo-audit-reports/runs/post-image-restore-*/`; earlier runs stay untouched, so an early "before any clones" run and a later "everything cloned" run can be diffed to prove progress. A rerun also writes a new sign-off carrying your answers forward, so rerunning never costs you a row you already closed.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The phase is script-driven for the loop (repo enumeration, status classification, action-command emission) and human-driven for the judgment calls (which repos are actually still needed, whether a rescue branch should be merged or discarded, whether the reviewed kept ignored files still apply on the reimaged machine).

`bin/restore-repos.sh` opens `repo-audit-reports/official/pre-image.txt`, walks the `repos.tsv` inside that pre-image run, and for each row it computes four things:

1. which root the repo belongs in, decided by its `origin` remote's **host**: `$GIT_PERSONAL_GITHUB_HOST` with an owner matching `$GIT_PERSONAL_GITHUB_OWNER` routes personal, `$GIT_WORK_GITHUB_HOST` routes work, and anything else routes work with the reason printed above its clone command;
2. whether the repo is already on disk at that routed destination — `$LOCAL_WORK_REPO_ROOT/<label>` or `$LOCAL_PERSONAL_REPO_ROOT/<label>` — which is what decides whether a clone command is emitted for it;
3. whether a `staged-ignored-files/live/<label>/` directory exists for this repo (kept ignored files ready to rsync back);
4. how many carry-forward rows the pre-image audit recorded (local-only commits + stashes + tracked changes).

The script writes those results into a `restore-status.md` report plus a machine-readable `raw/status.tsv`. Whether it also *acts* on them is `--hydrate`. Without it the run is read-only: it reports what it would do and touches nothing.

What it may act on is not the inventory — it is the clone plan you wrote in Step 0d. The audit says what existed; the plan says what comes back. A repository in the audit and in neither plan fragment is `unreviewed`: it is reported, and it is not cloned. That is deliberate, because a stale pre-image inventory acted on verbatim would silently repopulate repositories you no longer want.

A run has **stages**. `clone` is one; each rehydration source in the plan — the reviewed kept ignored files, the gitignored secrets in the encrypted image, IDE project metadata — is another. `--stage NAME` repeats and restricts the run to what you name; omitted, every stage runs. Cloning restores what Git tracked, and each stage puts back one class of thing Git ignored.

Every destination is the same routed clone path, computed once, and every stage guards on it: a source whose repository is not cloned yet reports `pending` rather than letting `rsync -a` create the directory and drop the bundle outside any repository. A repository already on disk whose `origin` disagrees with the plan is a `conflict` — nothing is written into it by any stage.

### Carry-Forward Model

The pre-image machine has three things that can be lost across a reimage that plain `git clone` won't recover: (a) commits that were only on a local branch and never pushed, (b) stashes, and (c) modifications to tracked files that were neither committed nor stashed. `backup-repos.md` handles this by asking the operator, *before the reimage*, to push a `reimage/YYYYMMDD/*` rescue branch that includes those changes.

Restoring is then a two-step reconciliation: `git clone` gets the mainline back, and `git fetch origin 'reimage/*'` picks up the rescue branch. The rescue-branch reconciliation gets its own step, run once per repo. If a pre-image row shows carry-forward count > 0 but no matching rescue branch exists on the remote, that is a real gap in Phase 2A's execution, not something Phase 11B can silently fix.

### Terminology

| Term | Meaning |
|---|---|
| Pre-image audit run | A timestamped `repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/` bundle produced by Phase 2A. Contains `repos.tsv` and the carry-forward TSVs. |
| Post-image restore run | A timestamped `repo-audit-reports/runs/post-image-restore-YYYYMMDD-HHMMSS/` bundle produced by this runbook. Contains the status report, `hydrated.md`, and copies of the pre-image rows it classified against. |
| Clone plan | The four fragments under `$REIMAGE_WORKSPACE_ROOT/repo-plan/`: which repositories are selected, which are excluded and why, where content comes back from after cloning, and per-repository overrides. Seeded by `init-repo-plan-config` in Step 0d and read by every run. It lives in the workspace, not in a bundle, because it survives the reimage and no run may write over your answers. |
| Stage | One unit of restoring work, named by `--hydrate --stage`. `clone` is a stage; so is each `ARTIFACT_TYPE` in the plan's rehydration sources — `ignored-files`, `repo-secrets`, `project-metadata`. |
| Hydration | Cloning a repository and merging each declared source into its working tree. Recorded in `hydrated.md`, one row per repository per stage. |
| Label | The basename of a repo path — `basename $REPO_PATH` — used by `backup-repos.md` as the directory name under `staged-ignored-files/live/`. |
| Carry-forward row | A row in `local-only-commits.tsv`, `stashes.tsv`, or `tracked-changes.tsv` from the pre-image run. Each row represents a change the remote does not carry and that must be preserved via a rescue branch or explicitly discarded. |
| Rescue branch | A `reimage/YYYYMMDD/*` branch created and pushed pre-image by Phase 2A to preserve carry-forward material. Restored by fetching `refs/heads/reimage/*` after clone. |
| Staged ignored bundle | A `staged-ignored-files/live/<label>/` directory containing the reviewed kept ignored files for one repo, rsynced back into the cloned working tree. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/restore-repos.sh               # entrypoint — classifies every pre-image repo and emits the status bundle
```

Related scripts, alphabetical:

```text
$FRACTOGENESIS_HOME/bin/init-shell-env.sh              # entrypoint (Step 4 — repoints the shell at the cloned toolkit)
$FRACTOGENESIS_HOME/bin/prepare-artifact-root.py       # entrypoint (Step 0c — upsert-env, writes GIT_PERSONAL_GITHUB_OWNER into reimage.env)
$FRACTOGENESIS_HOME/bin/record-restore-exit.sh         # entrypoint (Step 11 — exit boundary)
$FRACTOGENESIS_HOME/bin/record-restore-prereqs.sh      # entrypoint (Step 0a — entry boundary)
$FRACTOGENESIS_HOME/bin/record-restore-state.sh        # entrypoint (Step 0b before-state, Step 10 after-state and delta)
direnv                                                 # external helper — Step 6 trusts each restored .envrc
hdiutil                                                # external helper — Step 6 attaches and detaches the encrypted image
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/                # boundary, state and sign-off records for this phase
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/             # the status bundle each run produces
```

Input evidence built by earlier phases:

```text
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/pre-image.txt            # written by backup-repos.md — names the pre-image run to read
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/pre-image-YYYYMMDD-HHMMSS/   # written by backup-repos.md — the audit this phase consumes
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/repos-gitignored/                  # written by create-secrets-dmg.md — per-repo gitignored secrets, reachable only inside the attached image
$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live/                           # written by backup-repos.md — one reviewed bundle of kept ignored files per repo label
```

Six files sit in that pre-image run. `repos.tsv` is the inventory the script iterates. `local-only-commits.tsv`, `stashes.tsv` and `tracked-changes.tsv` are the carry-forward rows Steps 7 and 8 reconcile. `untracked-nonignored.tsv` and `ignored-files.tsv` are informational — the reviewed subset of the latter is what became `staged-ignored-files/live/`.

The complete `repo-audit-reports/`, `secrets-encrypted/` and `staged-ignored-files/` layouts are defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Bundle Layout

Everything this runbook writes, under the two roots named above. The pre-image audit it reads shares the `repo-audit-reports/` category but is a separate lineage, listed in the block before this one and not expanded here.

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── reimaged-system/
│   ├── boundaries/
│   │   ├── MANIFEST.md
│   │   ├── official/
│   │   │   ├── restore-repos-entry.txt
│   │   │   └── restore-repos-exit.txt
│   │   └── runs/
│   │       ├── restore-repos-entry-YYYYMMDD-HHMMSS/
│   │       │   └── checklist.md
│   │       └── restore-repos-exit-YYYYMMDD-HHMMSS/
│   │           └── checklist.md
│   ├── ...
│   ├── sign-offs/
│   │   └── restore-repos-exit-YYYYMMDD-HHMMSS.md
│   └── state/
│       ├── MANIFEST.md
│       ├── official/
│       │   ├── restore-repos-after.txt
│       │   ├── restore-repos-before.txt
│       │   └── restore-repos-delta.txt
│       └── runs/
│           ├── restore-repos-after-YYYYMMDD-HHMMSS/
│           │   ├── state.md
│           │   └── state.tsv
│           ├── restore-repos-before-YYYYMMDD-HHMMSS/
│           │   ├── state.md
│           │   └── state.tsv
│           └── restore-repos-delta-YYYYMMDD-HHMMSS/
│               └── delta.md
├── repo-audit-reports/
│   ├── MANIFEST.md
│   ├── official/
│   │   └── post-image-restore.txt
│   ├── repo-restore-index.md
│   ├── ...
│   └── runs/
│       └── post-image-restore-YYYYMMDD-HHMMSS/
│           ├── MANIFEST.txt
│           ├── hydrated.md
│           ├── plan-proposed/
│           │   ├── repo-candidates-excluded.proposed.conf.sh
│           │   ├── repo-candidates-selected.proposed.conf.sh
│           │   ├── repo-rehydration-map.proposed.conf.sh
│           │   └── repo-rehydration-sources.proposed.conf.sh
│           ├── raw/
│           │   ├── hydration.tsv
│           │   ├── local-only-commits-input.tsv
│           │   ├── repos-input.tsv
│           │   ├── stashes-input.tsv
│           │   ├── status.tsv
│           │   └── tracked-changes-input.tsv
│           └── restore-status.md
└── ...
```

The clone plan is not in that tree. It lives in the workspace, outside the artifact root:

```text
$REIMAGE_WORKSPACE_ROOT/repo-plan/
├── repo-candidates-excluded.conf.sh
├── repo-candidates-selected.conf.sh
├── repo-rehydration-map.conf.sh
└── repo-rehydration-sources.conf.sh
```

`boundaries/`, `repo-audit-reports/` and `state/` share one shape: `runs/<context>-YYYYMMDD-HHMMSS/` holds a single run's files, `official/<context>.txt` names the run that counts, and an append-only `MANIFEST.md` indexes every completed run. To find a run, read the pointer under `official/` — there is no newest-directory rule and no `latest-*.txt`. Steps 1 and 9 do exactly that, reading `official/post-image-restore.txt` to locate the run they just wrote.

Which run a pointer names is decided per point. `before` is first-wins, because the earliest observation is the one that caught the empty clone roots; `after`, `delta`, `entry`, `exit` and `post-image-restore` are latest-wins, so re-running any of them replaces the earlier answer.

`sign-offs/` is outside that shape on purpose. It holds the rows you answered at the exit boundary and carries them forward into the next run, so a latest-wins pointer must never be able to supersede it.

Each `post-image-restore-*` run is self-contained and its filenames are stable across runs. `restore-status.md` is the human-readable report carrying the exit-criteria table. `hydrated.md` is what that run *did*: one row per repository per stage, with the stages it was not asked to run named explicitly, so a partial run reads as partial rather than as a run that found nothing to do. It is written on every run, including one that hydrated nothing — *nothing happened* and *nothing needed to happen* are different answers. `MANIFEST.txt` lists that run's files, and is not the category run index — that is `repo-audit-reports/MANIFEST.md`.

`repo-restore-index.md` sits beside `MANIFEST.md` rather than inside any run: one append-only row per run carrying the counts the shared seven-column manifest has no room for — mode, planned, cloned, present, conflict, unreviewed, stages. `MANIFEST.md` stays the authority on which runs exist and which one counts; this file exists so a phase walked over several sittings answers *am I getting closer* without opening each bundle in turn.

`plan-proposed/` appears only when `--emit-plan` was passed: four files mirroring the clone-plan fragments, filled in from the audit and routed the way that run routed. It is a proposal to review and copy across, never the plan itself — the plan lives in the workspace and no run writes there. Under `raw/`, `status.tsv` is the machine-readable per-repo classification, `hydration.tsv` is the row-per-stage record `hydrated.md` is composed from, and the `*-input.tsv` files are copies of the pre-image rows, kept beside the output so a run can be read back without the audit that produced it.

This runbook also writes into each cloned working tree — the clone itself in Step 3, the kept ignored files in Step 5, and the per-repo secrets in Step 6. Those are not artifacts; they are the repositories being made whole at their original paths.

### Environment Variables

The `reimage.env` values this runbook depends on. `REIMAGE_ARTIFACT_ROOT` is resolved during `prepare-artifact-root.md`, the repository roots during [[backup-repos|backup-repos.md]] Step 1, and the SSH routing hosts during [[restore-git|restore-git.md]] Step 0c. `GIT_PERSONAL_GITHUB_OWNER` is written **by this runbook**, in Step 0c. Who owns which key, across every phase: [[references/environment-variable-reference|Environment Variable Reference]].

| Variable | Meaning |
|---|---|
| `FRACTOGENESIS_HOME` | Toolkit root; where `reimage.env` lives. Until this phase it points at the `curl` or jump-drive install from Phase 8, not a clone — see [[#Step 4 — Repoint at the Cloned Toolkit|Step 4 — Repoint at the Cloned Toolkit]]. |
| `REIMAGE_ARTIFACT_ROOT` | Artifact root where Phase 2A wrote the pre-image audit and where this runbook writes its status bundle. Must be mounted; the script fails fast if it is not. |
| `REIMAGE_WORKSPACE_ROOT` | Where the clone plan lives, in `repo-plan/`. Set during `prepare-artifact-root.md`. If it resolves to nothing the run falls back to the committed templates, whose entries are all commented out — a run against those loads clean, reports every repository `unreviewed`, and clones nothing. The script warns on stderr when that happens; Step 0d is what prevents it. |
| `PRE_IMAGE_PROJECTS_ROOT` | The projects root the IntelliJ capture walked **on the pre-image machine** — the prefix the `project-metadata` source subtracts from each audit path to get its key. Written **by this runbook**, in Step 0d. It is a pre-image path and will not exist on the reimaged Mac; that is expected, because nothing resolves it against this disk. `app-settings-backup/intellij/README.md` records the value the capture actually used, under *Projects root scanned for project-level IntelliJ metadata*. |
| `DMG_MOUNT` | Not from `reimage.env`. Set in the shell for Step 6 only, naming the attached secrets image. A rehydration source that needs the image and does not find it is recorded `blocked`, not failed — attach it later and rerun that stage. |
| `LOCAL_WORK_REPO_ROOT` | Directory holding work repos. A repository whose `origin` host is `$GIT_WORK_GITHUB_HOST` clones into here, and so does one whose host matches neither routing host — with the reason printed above its clone command. |
| `LOCAL_PERSONAL_REPO_ROOT` | Directory holding personal repos. A repository clones into here only when its `origin` host is `$GIT_PERSONAL_GITHUB_HOST` *and* its owner matches `$GIT_PERSONAL_GITHUB_OWNER`. The pre-image directory is not consulted: it says nothing about who owns the remote, and the root a repository sits under is what `includeIf` uses to decide its commit identity. |
| `GIT_WORK_GITHUB_HOST` | Host of the work Git server. A repository whose `origin` URL names this host routes to `$LOCAL_WORK_REPO_ROOT`. |
| `GIT_PERSONAL_GITHUB_HOST` | The personal **SSH routing host** — the `Host` name written in `~/.ssh/config` by [[restore-git|restore-git.md]] Step 3 and typed in personal clone URLs. It is a real server name under the direct scheme and an alias only when both accounts live on one server, which is the case `GIT_PERSONAL_GITHUB_HOSTNAME` exists for. This runbook rewrites a URL onto it only when all three hold: the URL is `git@github.com:`, this value is *not* `github.com`, and the owner matches `$GIT_PERSONAL_GITHUB_OWNER`. Set to `github.com` it routes directly and no rewrite can fire — which is the scheme working, not a fault. |
| `GIT_PERSONAL_GITHUB_OWNER` | Optional. The GitHub account that owns your personal repositories. `bin/restore-repos.sh` rewrites a clone URL onto `$GIT_PERSONAL_GITHUB_HOST` **only** when the URL's owner matches this, so a work-org repository is never routed onto the personal SSH routing host and handed the personal key. Blank means never rewrite — every candidate is flagged for review in Step 2 instead. Written **by this runbook**, in Step 0c; it is not in `reimage.env.example` and no earlier phase sets it. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the toolkit root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 11A ([[restore-git|restore-git.md]]) closed out with both `ssh -T` identity checks passing. Repositories need the dual-identity `~/.gitconfig` and `~/.ssh/config` in place before any emitted clone command will authenticate correctly.
- The external artifact volume is mounted and `reimage.env` resolves. `ls "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/pre-image.txt"` should print the pointer file.
- The pre-image `repos.tsv` has non-empty rows — this runbook cannot restore repositories that were never inventoried.

> [!bug] Troubleshooting
> If `bin/restore-repos.sh` exits with "latest-run pointer not found", the pre-image audit from Phase 2A either never ran or was written under a different artifact root. Reconnect the correct drive or point at a specific pre-image run with `--input-run pre-image-YYYYMMDD-HHMMSS`.

### Confirm Your Intent

- Are you doing a **full first-time restore** (Steps 1 through 8 in order) or a **rerun** to update the status table after cloning some repos by hand? Both are safe; a rerun writes a fresh timestamped bundle and shows fewer `Needs clone` rows.
- Which **subset of repositories** do you actually want back? That question is the clone plan, and Step 0d is where you answer it. A repository in the audit and in neither plan fragment is `unreviewed` and is not cloned, so "I have not decided yet" is a state the run reports rather than one it acts on.
- Do you want to do the whole restore in **one pass** (`--hydrate`) or **one stage at a time** (`--hydrate --stage clone`, then a stage per source)? One pass is fewer commands; stage-at-a-time lets you confirm the clones landed under the right roots before anything is merged into them, and is the safer order the first time through.
- Do you want to **see what a run would do before it does it**? `--dry-run` composes the report and `hydrated.md`, prints both, and writes nothing anywhere — no run, no sign-off, no pointer moved.

> [!warning] Pitfall
> The script's classification depends on the pre-image `repos.tsv` reflecting reality *at that moment*. If you moved or deleted repos between the pre-image audit and the reimage, the routing and the destinations still assume the old layout — review the report before hydrating.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The plan has to exist before a run can act on it, the report has to exist before you can review the plan against it, the clones have to land before anything can be merged into them, and the exit criteria can only be closed after a rerun confirms the state.

### Step 0 — Record Prerequisites and the Before-State

Two recordings, both taken before anything is cloned. They answer different
questions and only one of them can be taken late.

**0a — may this phase start?** Writes a checklist under
`reimaged-system/boundaries/` and exits non-zero only on `FAIL`:

```bash
./bin/record-restore-prereqs.sh --runbook restore-repos --dry-run
./bin/record-restore-prereqs.sh --runbook restore-repos
```

The first four rows are derived from *Prerequisites* above, so the two cannot
drift. The last three read the pre-image audit itself, and they exist because
`bin/restore-repos.sh` always produces a status bundle — a run against an empty
or damaged audit looks exactly like a clean one.

**Audit remote URLs are URLs** is the row to read twice, and it exists because
this exact damage happened. `capture-repo-audit.sh` built that column from
`git remote -v`, whose output is *itself* tab-separated, and wrote it into a TSV
unsquashed — so the URL landed in a later column and left the remote *name* where
the URL belongs. `restore-repos.sh` feeds that field to `extract_remote_url`, so
a damaged column surfaces as clone URLs that are missing or malformed rather than
as an error. The capture is fixed forward, but a run captured before the fix
carries the damage forever. When this row FAILs, read the real URLs out of that
run's `repo-audit-summary.txt`, which records `git remote -v` verbatim, and put
them in the plan's `REMOTE_FETCH_URL` before hydrating anything.

The two WARN rows name repositories that need a decision rather than a fix. A
repository with **no remote** cannot be cloned by anything — its only copy is
whatever the backup staged, so it is a Time Machine recovery or a deliberate
loss. A repository whose remotes span **both hosts** has no automatic answer to
which root it belongs in, because the host is what decides that everywhere else.
Both are recorded in *Decisions*.

**0b — what is on disk right now?** Writes a run under `reimaged-system/state/`
recording the clone destinations as they stand before this phase fills them:

```bash
./bin/record-restore-state.sh --runbook restore-repos --point before --dry-run
./bin/record-restore-state.sh --runbook restore-repos --point before
```

Two targets, both walked at depth 1: `$LOCAL_WORK_REPO_ROOT/` and
`$LOCAL_PERSONAL_REPO_ROOT/`. Depth 1 rather than a full walk because the question
is *which repositories exist*, not what is inside them — a recursive capture of
27 checkouts would hash tens of thousands of files to answer a question that is
one row per repository. The before-state is normally two empty roots; the delta
against the after-state is then literally the list of what this phase restored.

> [!note]
> Every block in this runbook shows a `--dry-run` line above the real one. It
> prints the table and writes nothing. On **0b** that preview matters most:
> `before` is a first-wins point, so the first capture recorded is the one that
> stays official, and a mistimed one cannot be replaced — only annotated with a
> pin explaining why it is wrong.

> [!warning] Pitfall
> **0b expires and 0a does not.** The prerequisite check is rerunnable at any
> point and costs nothing to repeat. The before-state is gone the moment the
> first clone lands in either root, so take 0b before Step 0c — and confirm no
> scratch repository is sitting in a clone root, since one left behind by
> `restore-git` Step 7 records as restored content.

**0c — record the personal-repo owner.** `bin/restore-repos.sh` rewrites a clone
URL onto `$GIT_PERSONAL_GITHUB_OWNER`'s SSH routing host only when the URL's
owner matches `GIT_PERSONAL_GITHUB_OWNER`. That match is what keeps a work-org
repository from being routed onto the personal routing host and offered the
personal key. It is the only `reimage.env` key this phase owns, no earlier phase
sets it, and Step 1 is the first thing that reads it.

Blank is a valid answer and means *never rewrite*: a repository still routes on
its remote host, but every one that routes personal on the host alone carries a
`REVIEW:` note on its clone row in `hydrated.md` saying the owner was not
checked, for you to read in Step 2. Skip this on a Mac
with no personal identity — 0a's *Clone roots set and distinct* row has already
established there is no personal root, and an owner without a root routes
nothing.

```bash
export GIT_PERSONAL_GITHUB_OWNER="your-personal-github-account"

if [ -n "$GIT_PERSONAL_GITHUB_OWNER" ] && [ -z "${LOCAL_PERSONAL_REPO_ROOT:-}" ]; then
  printf 'REFUSING to write. An owner is set but LOCAL_PERSONAL_REPO_ROOT is empty,\n'
  printf 'so no repository can route to the personal host regardless of the owner.\n'
  printf 'Leave the owner blank, or record the root in backup-repos and source\n'
  printf 'reimage.env again.\n'
else
  python3 bin/prepare-artifact-root.py \
    upsert-env \
    --env-file reimage.env \
    "GIT_PERSONAL_GITHUB_OWNER=$GIT_PERSONAL_GITHUB_OWNER"
fi
```

Confirm what landed, rather than trusting the write:

```bash
grep -E '^(export )?GIT_PERSONAL_GITHUB_OWNER=' reimage.env
```

`upsert-env` writes an empty value without complaint, which is correct here — a
blank owner is a decision, not an omission. What it cannot tell you is whether
the account you typed is the right one; Step 2 is where that shows up, as a clone
command routed to the wrong host.

**0d — initialize the clone plan.** First run or new workspace only — copy the
fragments that say which repositories to clone, where each lands, and where its
post-clone content comes from:

```bash
./bin/restore-repos.sh init-repo-plan-config
```

This writes `repo-candidates-selected.conf.sh`,
`repo-candidates-excluded.conf.sh`, `repo-rehydration-sources.conf.sh` and
`repo-rehydration-map.conf.sh` into `$REIMAGE_WORKSPACE_ROOT/repo-plan/`.

Init skips files that already exist and will not overwrite your entries unless
you pass `--force`. If the fragments are already there from a prior reimage, skip
this step — Step 1 proposes a filled-in plan from the audit for you to copy
across, and the workspace copy is never written by a run.

A freshly seeded plan declares nothing, and a run reads it without complaint:
every repository comes back `unreviewed` and nothing is cloned. The script warns
on stderr when it falls back to the committed templates, which is the case worth
noticing — it means the workspace directory is missing, not that the phase has
nothing to do.

**Record the projects root the fragments expand.**
`repo-rehydration-sources.conf.sh` is sourced, so `$PRE_IMAGE_PROJECTS_ROOT`
inside it expands from the environment. Unset, it expands to nothing, and a
source that subtracts an empty prefix matches no repository and restores no IDE
metadata — silently, because every row simply reads `skipped`.

It is a **pre-image** path: it names a directory that does not exist on this Mac,
and nothing resolves it against this disk. Read the value the capture actually
used rather than reconstructing it, then record it:

```bash
grep -A 2 'Projects root scanned' \
  "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/README.md"
```

```bash
export PRE_IMAGE_PROJECTS_ROOT="paste-the-path-printed-above"

python3 bin/prepare-artifact-root.py \
  upsert-env \
  --env-file reimage.env \
  "PRE_IMAGE_PROJECTS_ROOT=$PRE_IMAGE_PROJECTS_ROOT"
```

Confirm what landed, rather than trusting the write:

```bash
grep -E '^(export )?PRE_IMAGE_PROJECTS_ROOT=' reimage.env
```

Set it to the projects root itself, never to a directory inside it. Everything
below the root becomes the key, so a repository at
`<root>/apicoe/enterprise-search` keys as `apicoe/enterprise-search` and its
bundle is found at that path. A deeper value looks like it narrows the source to
the repositories you care about and instead removes them: the ones in other
subtrees stop matching the prefix entirely, and the ones under it get a key with
the group segment missing, which matches nothing.

Skip this only if the plan declares no `KEYED_BY=pre-image-path` source. The
reader refuses a source that needs `PRE_IMAGE_ROOT` and has none, so a plan that
needs the value and lacks it fails loudly rather than restoring nothing.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 1 — Produce the Initial Status Report

Run the script with no extra flags to write the first status bundle. This is a read-only pass — no clones happen, nothing is merged into any working tree. What it produces is the report you review the plan against in Step 2.

Preview the flags first:

```bash
bash -n bin/restore-repos.sh
./bin/restore-repos.sh --help
```

Then run:

```bash
./bin/restore-repos.sh
```

The script prints a summary — total repos, present on disk, needs clone, staged ignored bundles available, carry-forward rows total — and points at the newly written report:

```text
$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/runs/post-image-restore-YYYYMMDD-HHMMSS/restore-status.md
```

Open it — the pointer file already carries the `runs/` segment, so it joins straight onto `repo-audit-reports/`:

```bash
LATEST_RUN="$(cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/post-image-restore.txt")"
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/restore-status.md"
```

Open `hydrated.md` beside it. On a read-only run every row is what *would* happen — `needs-clone`, `would-apply`, `pending` — which is the same list Step 3 will act on:

```bash
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/hydrated.md"
```

The pre-image inventory is what the script classifies against. A repository created after Phase 2A ran does not appear here at all — clone it by hand later. One deleted after Phase 2A ran is still in the TSV and will be proposed for cloning, which is what the plan's excluded fragment is for.

> [!bug] Troubleshooting
> If the run stops with `REIMAGE_ARTIFACT_ROOT is not set or not a directory`, see [[#`bin/restore-repos.sh` exits with "REIMAGE_ARTIFACT_ROOT is not set or not a directory"|`bin/restore-repos.sh` exits with "REIMAGE_ARTIFACT_ROOT is not set or not a directory"]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Review the Plan Against the Report

Step 0d wrote the plan; Step 1 has just reported what a run against it would do. This step reconciles the two, and the number to read first is **unreviewed**. It counts repositories the audit found and the plan does not mention, and every one of them will be skipped until you say otherwise:

```bash
LATEST_RUN="$(cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/post-image-restore.txt")"
grep -A 12 '^## Summary' "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/hydrated.md"
```

Then open the plan itself and resolve them:

```bash
open "$REIMAGE_WORKSPACE_ROOT/repo-plan/"
```

For each repository, decide:

- **Select** — it is still relevant. `repo_plan_add` in `repo-candidates-selected.conf.sh`, with `REMOTE_FETCH_URL` and, when the routed default is wrong, `LOCAL_REPO_PATH`.
- **Exclude** — archived, superseded, or deliberately not coming back. `repo_plan_exclude` in `repo-candidates-excluded.conf.sh`, **with a reason**. The reason is the point: an excluded repository with no reason is indistinguishable next year from one nobody looked at.
- **Reroute** — the report's `Clone host` is a host that matched neither routing host, or matched the personal routing host under somebody else's owner. Decide the root by hand and set `LOCAL_REPO_PATH` on the selected entry.

`--emit-plan` fills a proposal in from the audit rather than leaving you to type it — see Step 0d. A proposal is written into the run bundle under `plan-proposed/` and never into the workspace, so adopting one is a copy you perform deliberately.

> [!warning] Pitfall
> The script only rewrites `git@github.com:` when routing to the personal host. It leaves HTTPS URLs and non-github remotes alone, so a pre-image HTTPS clone URL produces a clone that authenticates from the OS keychain rather than your restored SSH key.
>
> Which protocol is correct here is a decision, not a default. The audit records the protocol the *pre-image* machine used, on whatever network it was on. If SSH to that host is blocked from where you are now — a corporate network commonly permits it to an internal Enterprise Server while blocking it to the public internet — an `ssh` URL restored faithfully produces a clone that cannot fetch or push, and the failure arrives one repository at a time. Confirm SSH reaches each host before converting toward it, and leave HTTPS in place where it does not. `REMOTE_FETCH_URL` in the plan is where you record the answer, so it is made once rather than per run.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Clone the Selected Repositories

Rehearse first. `--dry-run` composes the same report and `hydrated.md`, prints both, and writes nothing anywhere:

```bash
./bin/restore-repos.sh --hydrate --stage clone --dry-run
```

Then run it for real:

```bash
./bin/restore-repos.sh --hydrate --stage clone
```

`--stage clone` restricts the run to the cloner, so the clones land and nothing is merged into them yet. `hydrated.md` names the stages that did *not* run, so a partial run reads as partial rather than as one that found nothing to do. Steps 5 and 6 are the remaining stages; run them once you have confirmed the clones sit where you meant.

A repository already present at its destination is `present`, not re-cloned: the run asks whether that path already contains a `.git` directory. So a rerun after a partial pass acts only on what is still missing, and rerunning is always safe.

A repository present at its destination whose `origin` is *not* the planned URL is a `conflict`. Nothing is cloned over it and — since a working tree that disagrees with the plan is not the one the plan describes — no later stage merges anything into it either. Resolve those by hand before rerunning.

A clone that fails is recorded `failed` with the git error and the run continues to the next repository, so one bad remote does not strand the rest. Fix it and rerun; the repositories already cloned come back as `present`.

**Cloning one repository by hand.** The batch is the normal path, but a single repo clones directly — proving the identity plumbing end to end, or picking up one you need before the rest are ready. Naming the destination rather than `cd`-ing into the root keeps the shell where it started, so a directory-scoped `direnv` does not unload `reimage.env` mid-block:

```bash
source ./reimage.env

REPO_PATH="replace-with-owner/repo"
git clone "git@${GIT_WORK_GITHUB_HOST}:${REPO_PATH}.git" "$LOCAL_WORK_REPO_ROOT/${REPO_PATH##*/}"
```

For a personal repo, both variables change:

```bash
source ./reimage.env

REPO_PATH="replace-with-owner/repo"
git clone "git@${GIT_PERSONAL_GITHUB_HOST}:${REPO_PATH}.git" "$LOCAL_PERSONAL_REPO_ROOT/${REPO_PATH##*/}"
```

**Which root a repo belongs in is decided by its remote host, not by where it lived pre-image.** A repository on the corporate Enterprise server belongs under `$LOCAL_WORK_REPO_ROOT` even if it sat in the personal directory before — an old directory named for its contents rather than an identity will have collected both. Clone one of those under the personal root and `includeIf` authors its commits with the personal address and `core.sshCommand` offers the personal key, which the Enterprise host rejects.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Repoint at the Cloned Toolkit

Step 3 clones every repository the plan selected, and the toolkit is one of them
— it lives under `$LOCAL_PERSONAL_REPO_ROOT` like any other personal repo. So the
previous step has just produced a **second** copy of the toolkit, and
`$FRACTOGENESIS_HOME` still points at the first.

Left alone, that is a quiet trap: you read a runbook from one copy, edit it, and
commit from the other. Only the clone has `.git`, so only the clone can commit —
and only the bootstrap copy has `reimage.env`, so only the bootstrap copy can
run scripts. Neither is complete until you merge the two facts.

Capture the current root before anything repoints it. After the shell is
repointed the variable names the clone, and this is the only handle on the old
copy:

```bash
TOOLKIT_BOOTSTRAP="$FRACTOGENESIS_HOME"
TOOLKIT_CLONE="$LOCAL_PERSONAL_REPO_ROOT/fractogenesis-toolkit"
```

**1. Carry `reimage.env` across.** It is gitignored, so the clone does not have it:

```bash
cp "$TOOLKIT_BOOTSTRAP/reimage.env" "$TOOLKIT_CLONE/reimage.env"
```

**2. Repoint the shell.** `init-shell-env.sh` self-locates, so running it from the
clone rewrites the profile block to point there:

```bash
bash "$TOOLKIT_CLONE/bin/init-shell-env.sh"
```

**3. Approve `.envrc` in the clone.** direnv approval is per-path and per-content,
so the clone needs its own:

```bash
cd "$TOOLKIT_CLONE" && direnv allow
```

**4. Start a fresh login shell**, then confirm before removing the old copy:

```bash
exec zsh -l
```

After the new shell starts, confirm both facts before deleting anything:

```bash
echo "$FRACTOGENESIS_HOME"
echo "$REIMAGE_ARTIFACT_ROOT"
git -C "$FRACTOGENESIS_HOME" status --short
```

Only once all three hold:

```bash
rm -rf "$TOOLKIT_BOOTSTRAP"
```

> [!note]
> `TOOLKIT_BOOTSTRAP` was set in the block above and does not survive
> `exec zsh -l`. Set it again in the new shell — or just confirm the path by eye
> before removing anything, which is the safer habit for an `rm -rf` either way.

> [!warning] Pitfall
> Do the deletion last, and only after the checks pass. `reimage.env` exists in
> exactly one place on this Mac until step 1 lands — delete the bootstrap copy
> first and you have destroyed it, with the jump drive as your only remaining
> source.

> [!note]
> If direnv is already active from
> [[restore-runtime#Step 6 — Install direnv and Restore the Repo Environment Hook|Phase 10A Step 6]],
> the `~/.zprofile` bridge block has already been removed and step 2 above is
> unnecessary — `.envrc` in the clone sets `FRACTOGENESIS_HOME` on `cd`. Running
> it anyway is harmless but reintroduces a block you would then remove again.
> Full picture: [[references/toolkit-environment-reference|Toolkit Environment Reference]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Restore Staged Ignored Files

`ignored-files` is a stage. It merges `staged-ignored-files/live/<label>/` into each cloned working tree, for every repository the plan selected.

See what it would do first:

```bash
./bin/restore-repos.sh --hydrate --stage ignored-files --dry-run
```

Then run it:

```bash
./bin/restore-repos.sh --hydrate --stage ignored-files
```

Read the per-repository table in `hydrated.md` afterwards. `applied` is the merge; `pending` means that repository is not cloned yet, so there was nowhere to merge into; `skipped` means no bundle exists for it, or the clone stage reported a conflict for it.

```bash
LATEST_RUN="$(cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/post-image-restore.txt")"
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/hydrated.md"
```

> [!note]
> Kept ignored files that were routed to `secrets-encrypted/repos-gitignored/` by Phase 2A are *not* under `staged-ignored-files/live/` — they are inside the encrypted DMG and are restored by Step 6 below, which needs the image attached.

> [!bug] Troubleshooting
> If a repository is recorded `applied` but the files are not in the working tree, see [[#A repository is recorded `applied` but no files appear in the working tree|A repository is recorded `applied` but no files appear in the working tree]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 6 — Restore Per-Repo Gitignored Secrets from the DMG

Phase 2A routed secret-shaped gitignored files — `.env`, `secrets/`, `gradle.properties` with real passwords — to `secrets-encrypted/repos-gitignored/<label>/` rather than to `staged-ignored-files/live/`, so the Phase 3C DMG would encrypt them. Step 5 does not touch those: they are inside the image, and until this step runs, every cloned repo is missing exactly the files it cannot start without.

`repo-secrets` is a stage like `ignored-files`, with one difference: its source root is inside the encrypted image, so the plan stores it as the literal `$DMG_MOUNT/repos-gitignored` and the run substitutes the mount point you give it. A run that cannot find the image records every repository `blocked` rather than failing — attach it later and rerun this stage.

**1. Attach the secrets DMG** if it is not still mounted from Phase 10B. Capture the real mount point rather than globbing the filename — the volume name comes from `-volname` at build time:

```bash
DMG="$(ls -1 "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/"all-secrets-*.dmg | sort | tail -1)"
export DMG_MOUNT="$(hdiutil attach "$DMG" | awk -F'\t' '/\/Volumes\//{print $NF}' | tail -1)"
echo "$DMG_MOUNT"
```

The variable is exported because the run reads it from the environment; confirm the path printed is the image and not some other mounted volume before continuing.

**2. See what it would restore, without restoring it:**

```bash
./bin/restore-repos.sh --hydrate --stage repo-secrets --dry-run
```

**3. Run it:**

```bash
./bin/restore-repos.sh --hydrate --stage repo-secrets
```

**4. Detach the image as soon as the copy finishes** — these are live credentials on a mounted volume:

```bash
hdiutil detach "$DMG_MOUNT"
```

**5. Trust any restored `.envrc`.** `direnv` blocks an `.envrc` it has not been told to trust, and does so silently as far as the shell is concerned:

```bash
cd "$LOCAL_WORK_REPO_ROOT/<repo>" && direnv allow
```

> [!warning] Pitfall
> The bundle label is `basename` of the repo path. Two repos sharing a basename across the work and personal roots collapse to one bundle, and a `repo-name`-keyed source would merge it into both — potentially putting work credentials into a repo you push publicly. The run warns when it sees a shared label. Check before running:
>
> ```bash
> cut -f1 "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/raw/repos-input.tsv" \
>   | xargs -n1 basename | sort | uniq -d
> ```
>
> Anything printed needs reconciling by hand before this stage runs — give one of the two an explicit entry in `repo-rehydration-map.conf.sh`, or exclude it.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 7 — Reconcile Rescue Branches

For each repo with `carry-forward rows > 0` in the status report, confirm the pre-image rescue branch made it onto the remote before reimage:

```bash
cd "$LOCAL_WORK_REPO_ROOT/<repo>"
git fetch origin 'refs/heads/reimage/*:refs/remotes/origin/reimage/*'
git branch -r | grep reimage/ || echo "no rescue branches found on remote"
```

For each rescue branch that shows up, choose one:

- **Merge back** into the intended branch:

  ```bash
  git checkout "<target-branch>"
  git merge "origin/reimage/YYYYMMDD/<name>"
  ```

- **Cherry-pick specific commits** when only some of the rescue-branch commits should land:

  ```bash
  git cherry-pick "<first-sha>..<last-sha>"
  ```

- **Leave as a branch** for later triage. Track that decision in the restore notes so it isn't forgotten.

> [!bug] Troubleshooting
> `no rescue branches found on remote` for a repo whose pre-image row shows carry-forward > 0 means Phase 2A's push step was skipped or failed for that repo. This is a real gap. Reconstruct from local backups if any exist; otherwise the carry-forward material is lost, and the row must be closed as "intentionally discarded" in the exit criteria.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 8 — Reconcile Stashes and Tracked Changes

Cross-check `raw/stashes-input.tsv` and `raw/tracked-changes-input.tsv` against the current state of each cloned repo. The pre-image push of a rescue branch typically covered these too, so they usually clear during the rescue-branch reconciliation. Anything still outstanding here is either:

- Material that was neither committed nor pushed to a rescue branch (real loss);
- A stash the operator intentionally decided not to preserve.

Note the intentional-discard cases in the restore notes.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 9 — Rerun the Status Report

Run the script one more time to write a fresh bundle that reflects the post-clone reality:

```bash
./bin/restore-repos.sh
```

No `--hydrate`: this is a read-only pass whose job is to observe, not to act.

The rerun is what turns the restoring work back into evidence. `Needs clone` counts repositories still missing from their routed root, and `Ignored bundles applied` against `Ignored bundles available` says whether the reviewed kept files landed. Both are prefilled into the report's own Exit Criteria table with a heuristic verdict, so read that table rather than keeping a second copy here — the boundary itself is recorded in Step 11, and a table maintained in two places is how the two come to disagree.

`repo-restore-index.md` is the other thing to read here, because it is the only view across sittings — every run this phase has made, with what each one cloned and what each one left `unreviewed`:

```bash
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/repo-restore-index.md"
```

```bash
LATEST_RUN="$(cat "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/official/post-image-restore.txt")"
open "$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/$LATEST_RUN/restore-status.md"
```

The rows a person answers are not in the report. They live in the sign-off beside `runs/`, which carries an answer forward and records the run it was answered against — a report is replaced by the next run, an answer written into one is not.

> [!bug] Troubleshooting
> If a clone's `git remote -v` does not show the transport you expected, see [[#A clone kept the pre-image HTTPS remote where you expected SSH|A clone kept the pre-image HTTPS remote where you expected SSH]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 10 — Record the After-State and Delta

Step 0b recorded the clone roots before this phase filled them. This step records them as they now stand, and joins the two.

There is no `compare-restored-state.sh` pass for this phase. The comparison this runbook needs is against the pre-image repository audit, not against a system inventory, and Step 9 has just made it — `restore-status.md` *is* the comparison.

**1. Capture the after-state.** The pair to Step 0b — same script, same runbook, the other point:

```bash
./bin/record-restore-state.sh --runbook restore-repos --point after --dry-run
./bin/record-restore-state.sh --runbook restore-repos --point after
```

`after` is latest-wins, so re-running it after a late clone replaces the earlier capture rather than being ignored — the opposite of `before`, which is first-wins because the earliest observation is the one that caught the empty roots.

**2. Join the two recordings.** `delta` is a third point on the same script. It walks nothing — it joins the official before-state and after-state and records what this phase changed on disk:

```bash
./bin/record-restore-state.sh --runbook restore-repos --point delta --dry-run
./bin/record-restore-state.sh --runbook restore-repos --point delta
```

Step 0b promised this: the before-state is two empty roots, so the delta against the after-state is literally the list of repositories this phase restored. Expect every clone as **added**. **removed** is the verdict to read twice — this phase restores, and should not be deleting anything from either root.

It is its own point rather than a side effect of `--point after` because a run directory should hold one kind of thing, and re-running it is how you rebuild the delta when either side is re-recorded.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 11 — Close Out the Exit Criteria

Step 0a recorded whether this phase was allowed to start. This step records whether it finished. Skip it and nothing anywhere says so — a question that gets asked days later, when the answer is no longer reconstructable.

**1. Run the exit checklist.** It answers "did this phase finish", against the same boundary index Step 0a wrote its entry record into:

```bash
./bin/record-restore-exit.sh --runbook restore-repos --dry-run
./bin/record-restore-exit.sh --runbook restore-repos
```

Read the rows rather than the exit status. It records `PASS`, `WARN`, `FAIL` and `MANUAL`, and a `MANUAL` row is a question only you can answer — not a failure, and not a pass either.

The checklist covers what this phase produced: both clone roots exist, how many repositories are on disk, and whether each one sits under the root matching its remote host — the row nothing else in the workflow catches, because the root is what `includeIf` uses to decide which identity authors a commit. Its manual rows ask whether the repositories left unrestored were a decision, whether carry-forward was reconciled for what *was* restored, and what became of the repositories with no remote. There is no second table to tick in this runbook: the checklist is the table, and keeping a copy here is how the two drift apart.

`bin/record-restore-prereqs.sh` and `bin/record-restore-exit.sh` are one pair per phase boundary, not one per runbook. This phase runs the `11B` entry check at Step 0 and the `11B` exit check here; it never runs Phase 12's entry check, and never re-runs its own entry check at the end.

**2. Confirm both boundary records landed.** One file answers whether the phase both started and finished:

```bash
sed -n '1,40p' "$REIMAGE_ARTIFACT_ROOT/reimaged-system/boundaries/MANIFEST.md"
```

You are looking for a `restore-repos-entry-*` row and a `restore-repos-exit-*` row. An entry with no exit is the signature of a phase that was walked but never closed out.

With both recorded, Phase 11B is complete and the workflow moves on to Phase 12.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script classifies and emits uniformly; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Which repositories in the pre-image inventory are still needed. | The script trusts the inventory verbatim; only you know which repos are archived, stale, or moved elsewhere. |
| Whether a rescue branch should be merged, cherry-picked, or left as a branch. | Depends on how much of the pre-image work is still relevant on the target branch — a call this runbook cannot make. |
| Whether a kept ignored file from the pre-image is still safe on the reimaged Mac. | Machine-specific paths, IDE settings, and env files may reference tooling that changed in Phase 10A. Review before blindly rsyncing every bundle. |
| Whether a carry-forward row with no matching rescue branch is a real loss or an intentional discard. | Only the operator knows which pre-image work was worth preserving; the script only reports the gap. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Four failures land here rather than inline: each either spans more than one step or has a fix long enough to break the flow of the step that surfaces it. The step that surfaces each one links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### `bin/restore-repos.sh` exits with "REIMAGE_ARTIFACT_ROOT is not set or not a directory"

The artifact volume is not mounted, or the environment was not loaded. `ls "$REIMAGE_ARTIFACT_ROOT"` and reconnect the drive.

[[#Step 1 — Produce the Initial Status Report|⮕ Continue to Step 1 — Produce the Initial Status Report]]

### Every repository is reported `unreviewed` and nothing clones

The run loaded the committed templates instead of your plan. Every entry in the
templates is commented out, so the plan parses cleanly, selects nothing, and the
run reports each repository as in-the-audit-and-in-neither-fragment. It looks
exactly like a phase with nothing to do.

The script warns on stderr when it falls back — `REIMAGE_WORKSPACE_ROOT is set
but .../repo-plan does not exist`. Confirm which directory it read, and seed it
if that is the templates directory:

```bash
./bin/restore-repos.sh --hydrate --dry-run 2>&1 | head -3
./bin/restore-repos.sh init-repo-plan-config
```

If the workspace copy exists and repositories are still `unreviewed`, they are
genuinely unreviewed — go back to Step 2 and select or exclude each one.

[[#Step 2 — Review the Plan Against the Report|⮕ Continue to Step 2 — Review the Plan Against the Report]]

### A clone kept the pre-image HTTPS remote where you expected SSH

This is the normal outcome, not a fault. The script restores the transport the pre-image audit recorded, and it rewrites a URL onto `$GIT_PERSONAL_GITHUB_HOST` only when the URL is already `git@github.com:`, that routing host is an alias — a name other than `github.com` — and the owner matches `$GIT_PERSONAL_GITHUB_OWNER`. Where the recorded remotes are HTTPS, or the personal routing host routes directly at `github.com`, there is no rewrite path to take. Both are true here.

Whether to convert is a decision, not a repair — see the Pitfall in Step 2 on SSH reachability before converting toward it. If you do convert:

```bash
git remote set-url origin "git@${GIT_PERSONAL_GITHUB_HOST}:<owner>/<repo>.git"
```

Confirm SSH actually reaches that host first; an unreachable SSH remote produces a clone that can neither fetch nor push, and the failure arrives one repository at a time.

[[#Step 9 — Rerun the Status Report|⮕ Continue to Step 9 — Rerun the Status Report]]

### A repository is recorded `applied` but no files appear in the working tree

`rsync -a` respects existing files with newer mtimes. If a clean clone already carries the file with a newer timestamp than the pre-image copy, rsync leaves it alone. Verify with `rsync --dry-run -av` before assuming loss.

[[#Step 5 — Restore Staged Ignored Files|⮕ Continue to Step 5 — Restore Staged Ignored Files]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Per-Repo Status Categories

| Column | Values | Meaning |
|---|---|---|
| `path_present` | `yes` / `no` | Whether the routed clone destination — `<clone_target_root>/<label>` — currently exists as a `.git`-containing directory. Not the pre-image path, which does not exist on a reimaged Mac. |
| `ignored_files_available` | `yes` / `no` | Whether `staged-ignored-files/live/<label>/` exists for this repo. |
| `ignored_files_applied` | `unknown` / `applied` / `skipped` / `pending` / `failed` | Outcome of the `ignored-files` stage for this repository. `unknown` when that stage did not run — which is different from it running and restoring nothing. |
| `carry_forward_rows` | integer | Sum of `local_only_commit_count + stash_count + tracked_change_count` from the pre-image row. Rows requiring rescue-branch reconciliation. |
| `clone_host` | host name | The `origin` remote's host, which is what routed this repository to `clone_target_root`. `<none>` for a repository the audit recorded with no remote. |

### Hydration Outcomes

The `Outcome` column in `hydrated.md`, and the vocabulary the exit-criteria rows are read against. Every outcome is recorded per repository per stage, so one repository can be `present` for `clone` and `blocked` for `repo-secrets` in the same run.

| Outcome | Stage | Meaning |
|---|---|---|
| `cloned` | clone | The repository was not there and now is. |
| `present` | clone | Already at the planned destination with a matching `origin`. Nothing was done, and nothing needed to be. |
| `would-clone` | clone | `--dry-run`, or a run without `--hydrate`. The clone command that would have run is in the detail column. |
| `needs-clone` | clone | A run without `--hydrate`: absent at the destination. The read-only wording of `would-clone`. |
| `conflict` | clone | Something is at the destination whose `origin` is not the planned URL. Nothing was written, and every later stage skips this repository for the rest of the run. |
| `no-url` | clone | The plan selected it but gave no `REMOTE_FETCH_URL`, and the audit recorded no remote. Nothing can clone it; it is a backup-recovery question, not a restore one. |
| `applied` | source | The source was merged into the working tree. |
| `would-apply` | source | `--dry-run`, or a run without `--hydrate`. The `rsync` that would have run is in the detail column. |
| `reported` | source | `MODE=report`: what exists was listed and nothing was restored. The honest setting for a source whose layout has not been inspected. |
| `pending` | source | The repository is not cloned yet, so there is nowhere to merge into. Run the `clone` stage first. |
| `blocked` | source | The source needs the secrets image and `DMG_MOUNT` is not set, or its root does not exist. Attach it and rerun this stage. |
| `skipped` | source | No bundle exists for this repository under the source root, or the clone stage reported a conflict for it. |
| `failed` | either | The `git` or `rsync` command returned non-zero. The error is in the detail column; the run continued to the next repository. |
| `excluded` | plan | The plan excludes it, with the reason in the detail column. |
| `unreviewed` | plan | In the audit and in neither plan fragment. Not cloned. Select it or exclude it with a reason. |

### Reading the Pre-Image TSVs

Each pre-image TSV serves a different reconciliation step. The columns come from `.internal/git/capture-repo-audit.sh` and are stable across runs.

| File | Purpose in Phase 11B |
|---|---|
| `repos.tsv` | Master inventory. One row per repo; drives the classification loop. |
| `local-only-commits.tsv` | One row per unpushed commit. Cross-check after fetching rescue branches — every row should now be reachable from a `reimage/*` ref. |
| `stashes.tsv` | One row per stash. Same reconciliation as above; stashes typically ride along in the rescue branch as separate commits or a `WIP` note. |
| `tracked-changes.tsv` | One row per modified tracked file. Usually cleared by the rescue branch; anything remaining after that reconciliation is a real loss or an intentional discard. |
| `untracked-nonignored.tsv` | Informational. New files never `git add`-ed. Rarely worth preserving; handle case-by-case if the count is nonzero. |
| `ignored-files.tsv` | Informational. The full list of ignored files; the reviewed subset lives under `staged-ignored-files/live/`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link,
  except Troubleshooting, whose back-link sits under its intro and whose routed
  symptom subsections stay out of the Table of Contents.
-->
