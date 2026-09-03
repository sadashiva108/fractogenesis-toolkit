# Phase 11B evidence review — what `restore-repos` actually left behind

**Recorded:** 2026-09-03 11:36:54 EDT, restore-apps session.
**Scope:** the `restore-repos.md` evidence and captures on the live artifact
root, read before starting `restore-apps.md` (Phase 12).
**Finding:** `0001` — scope `restore-apps`.
**Bundle status:** `unresolved`. The row in the parent `INDEX.md` is
authoritative; this line is a copy for anyone reading the document alone.
Findings only — no repository file and no artifact was modified by this review.
**Environment:** every command ran in an AI session's Linux VM (GNU coreutils,
Bash 5.x) against the mounted repository and artifact volume. Reads only: `ls`,
`find`, `cat`, `grep`, `diff`, `stat`. No `bin/` script was executed, on either
platform.

**Artifact root:** `/Volumes/Data/reimage-CVG-0002160-500-20260816-open`
**Repository HEAD at review time:** `9fea5eb`, then `de7aa8e` (Revision 156)
during the session.

---

## Where the phase actually stands

Phase 11B ran for real, and further than a first read of the official run
suggests. `repo-audit-reports/repo-restore-index.md` records it:

| Run | Mode | Planned | Cloned | Present | Stages |
|---|---|---:|---:|---:|---|
| `post-image-restore-20260902-212601` | report | 6 | 0 | 1 | clone ignored-files repo-secrets project-metadata |
| `post-image-restore-20260902-214918` | hydrate | 6 | **6** | 1 | clone |
| `post-image-restore-20260903-002650` | hydrate | 6 | 0 | 7 | repo-secrets |
| `post-image-restore-20260903-002904` | hydrate | 6 | 0 | 7 | repo-secrets |
| `post-image-restore-20260903-004131` | report | 6 | 0 | 7 | clone ignored-files repo-secrets project-metadata |
| `post-image-restore-20260903-004412` | report | 6 | 0 | 7 | clone ignored-files repo-secrets project-metadata |

So: the clone stage completed 6 of 6 on 2026-09-02 at 21:49, and `repo-secrets`
applied to all six at 00:26. "7 present" is one repository that was already
there plus the six clones. What has **not** run is `ignored-files` (Step 5) and
`project-metadata`. The exit bookend was recorded at 00:53 regardless.

---

## Finding status

The bundle advances when its first row advances and reaches `resolved` only when
its last one does, and a row moves to `resolved` when its resolution is recorded
in `resolutions.md` — not when the work feels done.

**`resolving` cannot begin until every row reads `yes` under Decided.** Findings
in one bundle bear on each other, and nothing outside `docs/` is written until
the last of them is settled. A row reads `yes` only when nothing about that
finding is still open. Finding 1 reads `yes`: six decisions, 1.1 through 1.6,
with nothing outstanding. `decisions.md` carries the detail.

| # | Finding | Decided | Status |
|---:|---|---|---|
| 1 | The official run reports `repo-secrets` as blocked, although it succeeded | yes | `in progress` |
| 2 | Step 5 and the `project-metadata` stage were never applied | — | `unresolved` |
| 3 | The exit bookend reads clean on a phase with two WARN exit criteria | — | `unresolved` |
| 4 | Four sign-offs on the volume were written by scratch runs | — | `unresolved` |
| 5 | Every bookend sign-off written since 2026-09-01 cites a staging path | — | `unresolved` |
| 6 | The status report blanks the carry-forward count for two repositories | — | `unresolved` |
| 7 | The two unreviewed repositories are Time Machine or nothing | — | `unresolved` |
| 8 | `reference-vault` cloned with a warning nobody has acted on | — | `unresolved` |
| 9 | All six clones came back on HTTPS | — | `unresolved` |
| 10 | All three exit sign-off rows are outstanding | — | `unresolved` |

---

## Findings

### 1 — The official run reports `repo-secrets` as blocked, although it succeeded

Runs `post-image-restore-20260903-002650` and `-002904` record
`applied — merged repo-secrets/<repo>` for all six repositories. The official
run `-004412`, a later read-only report taken after the secrets image was
detached, records for the same six:

```
blocked | repo-secrets root is not reachable: /Volumes/all-secrets-20260816-210625/repos-gitignored
```

`repo-audit-reports/official/post-image-restore.txt` names `-004412`, so the
pointer the workflow follows presents a completed stage as blocked. The evidence
that it worked survives only in two run directories nothing points at.

`hydrated.md` is honestly documented as *what this run did* — but combined with
a latest-wins pointer, a read-only rerun overwrites the narrative of the work.
Nothing carries a completed stage forward.

**Felt at:** `restore-repos.md` Step 6 and Step 9;
`repo-audit-reports/runs/post-image-restore-20260903-004412/hydrated.md`.

### 2 — Step 5 and the `project-metadata` stage were never applied

In the official run all six repositories read `would-apply` for
`ignored-files`. Four read `would-apply` for `project-metadata`; `indigo` and
`reference-vault` read `skipped — no key for <repo> in project-metadata`. The
status report's exit criterion *"Every staged ignored bundle applied"* is `WARN`
for exactly this reason.

**This also settles a `restore-apps.md` question.** Phase 11B has not
rehydrated IntelliJ project metadata, so `restore-apps.md` Step 8 is not
currently doing that work twice — but it will be, as soon as this stage runs.
Decide which phase owns it before running either.

**Felt at:** `restore-repos.md` Step 5, Step 9; `restore-apps.md` Step 8.

### 3 — The exit bookend reads clean on a phase with two WARN exit criteria

`reimaged-system/bookends/runs/restore-repos-exit-20260903-005335/bookend.md`
records **3 pass · 0 warn · 0 fail**:

| Check | Result | Detail |
|---|---|---|
| Clone roots present | `PASS` | both roots exist on disk |
| Repositories on disk | `PASS` | 7 restored across both roots |
| Each repository sits under the root matching its remote | `PASS` | no misplaced clones |

"7 restored" counts what is *present*, not what this phase restored, and any
non-zero count passes. Nothing in the exit bookend reads `restore-status.md`'s
exit-criteria table or `hydrated.md`, so a phase with two unapplied stages
closes as cleanly as a finished one.

**Consequence for Phase 12.** `bin/record-restore-prereqs.sh:721–726` records
`FAIL` only when there is *no* official `restore-repos-exit` run. There is one.
So `restore-apps.md` Step 0 will read green no matter how much of Phase 11B was
left undone.

**Felt at:** `bin/record-restore-exit.sh`; `restore-repos.md` Step 11;
`restore-apps.md` Step 0.

### 4 — Four sign-offs on the volume were written by scratch runs

`reimaged-system/sign-offs/` holds four `post-image-restore` sign-offs with no
corresponding run in `repo-audit-reports/runs/`:

| Sign-off | `Plan` value |
|---|---|
| `post-image-restore-20260903-004626.md` | `/tmp/emitcheck/restore-status.md` |
| `post-image-restore-20260903-005539.md` | `/tmp/ep/restore-status.md` |
| `post-image-restore-20260903-005604.md` | `/tmp/ep2/restore-status.md` |
| `post-image-restore-20260903-005642.md` | `/tmp/ep3/restore-status.md` |

`--dry-run` correctly opens no sign-off — `bin/restore-repos.sh:488` guards it.
But `--output` does not redirect the sign-off root, which is hardcoded one line
earlier:

```
487: SIGNOFF_ROOT="$REIMAGE_ARTIFACT_ROOT/reimaged-system/sign-offs"
488: if [[ "$DRY_RUN" != true ]]; then
```

So four `--emit-plan` test runs against `/tmp` each left a durable sign-off in
the permanent record, naming a plan path that no longer exists. By mtime they
are the four **oldest** post-image-restore sign-offs; their run-id stamps look
later only because they were generated under a UTC clock rather than the Mac's
EDT.

**The carry-forward chain is correct today only because of the pointer.**
`latest-post-image-restore.txt` names `post-image-restore-20260903-004412`, and
`signoff_latest` in `.internal/sign-offs.sh` prefers the pointer. Its documented
fallback is the last glob match — which lexicographically is
`post-image-restore-20260903-005642`, an orphan carrying
*"Carried from: first run"* and two outstanding rows. Lose or corrupt the
pointer and the next run silently restarts the chain from a `/tmp` test.

**Felt at:** `bin/restore-repos.sh:487–489`; `.internal/sign-offs.sh`
(`signoff_latest`).

### 5 — Every bookend sign-off written since 2026-09-01 cites a staging path

`reimaged-system/sign-offs/restore-repos-exit-20260903-005335.md`:

```
| Plan | `.../bookends/runs/.restore-repos-exit-20260903-005335.incomplete/checklist.md` |
```

The `.incomplete` staging directory is promoted by `artifact_run_finalize`, so
the path is dead the moment the run ends. Three others share the defect —
`restore-git-exit-20260901-150202`, `restore-git-exit-20260901-153636`, and
`enroll-and-stabilize-exit-20260901-144422`. Every sign-off written before
2026-09-01 cites the promoted directory correctly.

The cause is ordering: the recorders open the sign-off before the run is
finalized, deliberately, so `SIGNOFF_FILE` resolves while the record is being
written. The value captured is the pre-promotion path.

This is the second half of the outstanding `Plan`-label question. The label is
the wrong word for what it names, *and* on these four the value does not
resolve.

**Felt at:** `bin/record-restore-exit.sh`; `.internal/sign-offs.sh`
(`signoff_begin` / `signoff_finalize`).

### 6 — The status report blanks the carry-forward count for the two repositories that need a decision

In `restore-status.md` → *Per-Repo Status*, `engagements` and
`ingestion-related` show an empty *Carry-forward rows* cell and `unknown` under
*Ignored bundle*, while every other row carries a number. The pre-image audit
`pre-image-20260901-234636` has the figures:

| Repository | local-only commits | tracked changes | stashes | total |
|---|---:|---:|---:|---:|
| `engagements` | 1 | 1 | 0 | **2** |
| `ingestion-related` | 2 | 36 | 0 | **38** |

And `staged-ignored-files/live/` does hold a bundle for both. The no-remote path
skips the count, so the report understates precisely the two rows that most need
attention. Their *Clone host* cell also prints a filesystem path,
`/Users/dkittrell/workspace/orah`, where every other row prints a host.

**Felt at:** `bin/restore-repos.sh` (per-repo table); `restore-repos.md` Step 1,
Step 2.

### 7 — The two unreviewed repositories are Time Machine or nothing

Both are recorded `<none>` for `remote_urls` in the pre-image `repos.tsv`, so
nothing can clone them. What exists on the artifact volume:

| Source | `engagements` | `ingestion-related` |
|---|---|---|
| `staged-ignored-files/live/<repo>/` | 5 files, `.idea/` XML only | 4 files, `.idea/` XML only |
| `app-settings-backup/intellij/project-metadata/<repo>/` | present | present |
| `home-files-backup/home/` | **no `Development/` at all** | **no `Development/` at all** |

Neither staged bundle holds source. The home backup never covered
`~/Development/IdeaProjects`, so the working trees were not captured there.
Nothing on this volume can reconstruct 38 tracked changes in
`ingestion-related`.

**Time Machine on `/Volumes/AppleBackups` is the only possible source.** The
`time-machine/` category on the artifact root holds pre-image verification
evidence, not content. If the working trees are not in the Time Machine chain,
the honest exclusion reason is accepted loss, and it should be written as that
rather than left unreviewed.

**Felt at:** `restore-repos.md` Step 2; the exit sign-off row *"Repositories
with no remote are resolved"*.

### 8 — `reference-vault` cloned with a warning nobody has acted on

`post-image-restore-20260902-214918` recorded:

```
cloned from https://github.gaig.com/dkittrell/reference-vault.git;
pre-image HEAD a42049b absent -- wrong remote, or unpushed work
```

It is the only one of the six clones whose pre-image HEAD is not present on the
remote it was cloned from. Either the audit recorded a different remote than the
one that holds the work, or that commit was never pushed.

**Felt at:** `restore-repos.md` Step 3, Step 7.

### 9 — All six clones came back on HTTPS

Every `cloned from` URL in the hydrate run is `https://github.gaig.com/...`.
That is the runbook working as documented — the transport recorded by the
pre-image audit is what gets restored, and Troubleshooting covers the case
explicitly. It is recorded here because `restore-git.md` established SSH keys
and routing hosts beforehand, and the exit sign-off row about clone roots is
still `TODO`. Worth a deliberate answer rather than a default.

**Felt at:** `restore-repos.md` Step 3, Troubleshooting.

### 10 — All three exit sign-off rows are outstanding

`restore-repos-exit-20260903-005335.md` carries `TODO` on all three, carried
from the 2026-08-25 run:

- Repositories left unrestored are a decision
- Carry-forward reconciled for what was restored
- Repositories with no remote are resolved

Findings 6 and 7 answer the third; finding 2 bears on the second.

---

## Minor, recorded rather than raised

- Three `post-image-restore-20260825-*` runs remain in the category with no
  sign-off — the known truncated-bundle gap, already parked separately.
- `reimaged-system/state/runs/restore-repos-delta-20260903-005126/delta.md`
  captured `.DS_Store` in both new clone roots as `added`. Correct, and noise.
- The delta also records `/Users/dkittrell/workspace/shiva/.gitconfig` as added,
  which is the `includeIf` identity file arriving as intended.

---

## Suggested order before Phase 12

Findings 1, 2 and 3 compound: the phase is not finished, the record says it is,
and Phase 12's entry gate believes the record. The cheaper fix is to finish the
phase rather than to weaken the gate.

1. Rerun `--hydrate --stage ignored-files`, and `--stage project-metadata` once
   its ownership is settled against `restore-apps.md` Step 8.
2. Rerun with the secrets image attached so `repo-secrets` re-records as
   `applied` rather than `blocked` in the run the pointer names.
3. Rerun Steps 9, 10 and 11 so the official run, the delta and the exit bookend
   describe what actually happened.
4. Answer the three exit sign-off rows, using findings 6 and 7.
5. Decide `engagements` and `ingestion-related` against the Time Machine chain.

Findings 4 and 5 are defects in shared machinery rather than in this evidence.
Neither blocks Phase 12. Finding 4 is worth closing before the next
`--emit-plan` run adds a fifth orphan.
