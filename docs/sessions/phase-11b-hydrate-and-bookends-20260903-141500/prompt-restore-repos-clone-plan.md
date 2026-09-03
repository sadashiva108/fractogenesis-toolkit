# Session prompt — Restore Repositories: the declared clone plan

You are continuing the **Restore Repositories Refactor** line of work in
`fractogenesis-toolkit`. The previous sitting shipped Revision 131 and handed off
cleanly; this sitting builds the thing that handoff parked under *Open design work*.

**Scope: scripts and fragments only.** Do not edit `restore-repos.md` or any other
runbook. The owner takes the runbooks next, starting with that one, and wants the
executor settled first so the runbook is written against something real.

**Never commit.** The owner reviews and commits.

**Every repository change gets a new `APPLY-MANIFEST.md` revision.** Read the header
for the current number immediately before writing — a concurrent session collided on
123 once already. Everything under `docs/` is gitignored, so a design-only sitting may
correctly end with no revision at all.

---

## Reading order

1. `docs/sessions/phase-11b-hydrate-and-bookends-20260903-141500/handoff-20260902-000000.md` — the handoff you are resuming.
2. `docs/architecture/restore-repos-clone-plan.md` — **the design you are building.**
   It is complete enough to implement from. Its *Open decisions* section is your
   first agenda item.
3. `.github/copilot-instructions.md`, then
   `.github/ai-prompts/script-prompts/bash-script-authoring-and-review.md` and
   `.github/guides/script-types-and-locations.md` — classify before you touch anything.
4. `bin/restore-repos.sh` and `.internal/git/capture-repo-audit.sh`.
5. `.internal/artifact-config.sh`, `.internal/artifact-runs.sh`,
   `.internal/artifact-run-cli.sh`.
6. `bin/stage-certs-keychain.sh` — its `init-staged-certs-config` subcommand is the
   seeding pattern to copy.
7. These gap notes, all of which land inside this work:
   `post-image-restore-runs-truncated`, `emit-extra-remotes-readds-the-clone-url`,
   `carrier-services-storage-foreign-remote`, `post-image-restore-per-run-manifest`,
   `staged-ignored-files-live-parent-root-bundles`, `repo-audit-tsv-column-shift`.

---

## What changed underneath since Revision 131

Revisions 132–141 landed from the run-index session. Six of them touch this work,
and three of them are patterns you should build **on** rather than beside.

| Revision | What it means here |
|---|---|
| 135 | Every capture producer writes through the shared run index. `repo-audit-reports/` resolves via `artifact_run_official <root> pre-image`, which already picks up the re-derived, pinned run — no change needed. |
| 136 | Caller environment now beats `reimage.env` for **every** key, by set-ness. Your fragments are *sourced*, so an executor that assigns `GIT_WORK_REPO_ROOT` rather than defaulting it will now silently override the operator. Default, never assign. |
| 138 | The pre-image evidence was converted to indexed runs, and **D8** was written down: `$REIMAGE_ARTIFACT_ROOT` is the scope boundary. The plan fragments living in `$REIMAGE_WORKSPACE_ROOT` is now a stated rule, not an accident — they are declaration, not evidence. `staged-ignored-files/` was confirmed **not** a run category: three sibling modes, not three runs. |
| 139 | `record-restore-exit.sh`, `record-restore-prereqs.sh` and `record-restore-state.sh` all derive their messages from one `SUPPORTED_RUNBOOKS`; `restore-repos` is in all three. Their usage blocks are now accurate. |
| 140 | Every runbook was redrawn in the run-index layout. `restore-repos.md`'s `### Status Bundle Layout` is now `### Bundle Layout`, and its Artifact and Script Locations section carries the four fixed labelled lines. **This is the current-state baseline your Open decision 1 diffs against.** |
| 141 | Two new patterns, both directly reusable: `.internal/artifact-run-cli.sh` puts the run library behind a command line for producers that are not Bash; and `content-scan-index.md` established that when the shared manifest schema cannot carry a category's columns, a **domain index** goes beside `MANIFEST.md` rather than widening it. |

That last row matters. Your executor will want per-run counts — planned, cloned,
present, conflict, unreviewed, and per-source applied/skipped/blocked/pending. Those
do not fit the shared schema. `repo-audit-index.md` already exists in that category;
extend it or add a sibling, and do not invent a third mechanism.

Also: `.internal/templates/` currently holds `artifact-config/`, `gitignore-superset/`
and `staged-certs/`. `repo-plan/` joins them as a fourth, with the same seeding
semantics.

---

## Start here, before writing any executor

**Reproduce `post-image-restore-runs-truncated` first.**

All three Phase 11B bundles on the volume have a **0-byte `restore-status.md`** and
no `MANIFEST.txt`, while `status.tsv` and all three command files are complete. The
same script produces both correctly on Linux, so the suspicion is Bash 3.2 in the
report heredoc.

`restore-status.md` is the *primary output of the thing you are about to build*. An
executor written on top of an unreproduced truncation bug ships that bug in a
component with more to say. Run the existing script under `bash -x` against a scratch
artifact root, find the line, and record it in the gap note before moving on.

If it turns out to be environmental rather than a code defect, say so and proceed —
but say which.

---

## The task

Build the declared clone plan from `docs/architecture/restore-repos-clone-plan.md`:

1. **`.internal/templates/repo-plan/`** — the four fragments, seeded and commented
   the way `.internal/templates/artifact-config/*.conf.sh` are:
   `repo-candidates-selected.conf.sh`, `repo-candidates-excluded.conf.sh`,
   `repo-rehydration-sources.conf.sh`, `repo-rehydration-map.conf.sh`.
   The architecture document specifies each one's format and the reason for it.
2. **Seeding** — `./bin/restore-repos.sh init-repo-plan-config`, copying into
   `$REIMAGE_WORKSPACE_ROOT/repo-plan/` and refusing to overwrite without `--force`.
   Mirror `stage-certs-keychain.sh init-staged-certs-config` exactly.
3. **`--emit-plan`** — a pass that writes pre-filled `*.proposed.conf.sh` **into the
   run bundle**, never into the workspace, from the pinned pre-image audit. 27 rows
   are not worth typing by hand; the workspace copy stays the operator's.
4. **The executor** — `bin/restore-repos.sh` joins audit + plan + disk and reports or
   applies. The per-repository state machine and the four per-source outcomes are
   specified in the architecture document; implement them as written.
5. **Loading** — resolve the fragments through the same path
   `.internal/artifact-config.sh` uses, so `$GIT_WORK_REPO_ROOT/ingestion/x` expands
   and caller environment still wins.

Hold to what the design already decided and do not relitigate: `Present` requires
`git remote get-url origin` to match, not `[ -d .git ]`; post-clone actions run only
on the branch that just cloned; there is **no state ledger**; unreviewed is a third
state and never gets a default action.

---

## Decisions to settle before building

Open decisions 1–4 in the architecture document are still open. Two are yours to
recommend and the owner's to approve — **present options with tradeoffs, do not just
pick**, per the repo's own rule about artifact naming, retention and manifest policy.

- **1 — do run bundles still emit runnable scripts?** The document recommends
  dropping them. That is a retention decision *and* it changes `restore-repos.md`'s
  Bundle Layout, which Revision 140 just redrew. Note the coupling.
- **2 — `record-restore-exit.sh` row 3** grades "each repository sits under the root
  matching its remote", so a deliberate `DEST` outside the work root fails it. Either
  the recorder reads the plan, or a deliberate placement becomes a recorded decision.
  That file is outside this file set — flag, do not quietly extend.
- **3 — Step 4's hardcoded `$GIT_PERSONAL_REPO_ROOT/fractogenesis-toolkit`.** Once
  the plan can move the toolkit, this comes from the plan. Runbook-side, so record it
  for the owner's runbook pass rather than editing it.
- **4 — seeding and `--emit-plan`** is specified; build it as written unless you find
  a reason not to.

Also decide, and it is not in the document: **does the executor need its own domain
index**, and if so does it extend `repo-audit-index.md` or sit beside it? Revision
141's `content-scan-index.md` is the precedent either way.

---

## Standing constraints

- **Bash 3.2 / BSD floor.** No `mapfile`, no `declare -A`, no `sed -i`, no `stat -c`,
  no `grep -P`. Phase 11B runs before Homebrew on a rebuilt Mac.
- **`bin/restore-repos.sh` stays an aggregate validator** — read-only by default,
  `--apply` to act, PASS/WARN/FAIL rows rather than aborting on first failure. It
  already has that shape and that strict-mode choice; keep both.
- **Do not touch the artifact volume's evidence.** The pin on
  `repo-audit-reports/official/pre-image` protects a re-derived run; a reindex must
  not disturb it. Test against a scratch artifact root, as the previous sitting did.
- **No compatibility shims.** When the plan replaces the emitted scripts, update the
  active path rather than keeping both.

## Verify, and be honest about where

```
bash -n bin/restore-repos.sh
./bin/verify-script-portability.sh --file bin/restore-repos.sh
./bin/verify-doc-paths.sh --all
shellcheck -x bin/restore-repos.sh        # if available
```

Baselines to hold: portability 0 WARN / 0 FAIL, doc-paths 0 MISSING / 0 ANCHOR
BROKEN, runbook structure 25 FAIL (pre-existing `[!note]` / `PITFALL` / `LEGEND`
findings — do not let it rise).

Your shell is Linux with Bash 5.x, where `mapfile`, `declare -A` and `sed -i` all
work silently. "Tested on Linux" and "tested on the target Mac" are different claims.
Say which one you are making, and name what still needs a run on the Mac —
`/bin/bash -n` under real Bash 3.2 is owed on Revisions 116–141.

## Deliverables

- The fragments, the seeding subcommand, `--emit-plan`, and the executor.
- A new `APPLY-MANIFEST.md` revision — check the header first.
- A status document under `docs/sessions/`, dated, saying what shipped, what you
  deviated from and why, which of the open decisions are now closed and which the
  owner still has to answer, and where the next sitting resumes.
- A row in the findings indexes for anything you park, and an update to
  `docs/sessions/INDEX.md` for your status document.
