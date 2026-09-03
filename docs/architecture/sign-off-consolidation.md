# Sign-off consolidation

**Status:** decided in principle, scoped, not started.
**Decided:** 2026-09-02, owner. Written by session `01KcZvrKMgfenhrT9DvxW9Jk`.
**Depends on:** `docs/ledgers/evidence-conformance.md` §6 and §7, which
is the survey this plan acts on.

One rule, applied everywhere: **a file is automated or it is answered, never
both.** Everything below follows from that plus the owner's decision that closed
pre-image artifacts may be split, with a backup.

---

## Table of Contents

- [[#1. Decisions|1. Decisions]]
- [[#2. Target layout|2. Target layout]]
- [[#3. Splitting the mixed-mode artifacts|3. Splitting the mixed-mode artifacts]]
- [[#4. Retiring inline generation|4. Retiring inline generation]]
- [[#5. Run-indexing the capstone checklists|5. Run-indexing the capstone checklists]]
- [[#6. Order of work|6. Order of work]]
- [[#7. Open questions|7. Open questions]]

---

## 1. Decisions

| # | Decision |
|---|---|
| D1 | **Pre-image uses `<category>/sign-offs/` consistently.** `manual/` and per-category `checklists/` are retired as homes for answered rows |
| D2 | **No mixed-mode artifacts going forward.** Automated output and answered rows are always separate files |
| D3 | **Closed pre-image artifacts may be split** — take a backup first, then move the manual half into `sign-offs/`. This relaxes item 7's "captured data is not to be modified" for *structure*, not content |
| D4 | **Runbook code blocks stop authoring artifact-root notes and inventories.** A script writes them, into a designated `sign-offs/` folder |
| D5 | **The pre-image / post-image structural asymmetry stands for now.** Pre-image keeps a folder per capture category; post-image stays under `reimaged-system/`. Not ideal, and not worth a lift-and-shift today |
| D6 | **Capstone checklists are run-indexed** |
| D7 | **A purely manual artifact inside a run directory moves to `sign-offs/`.** Not a split — there is no automated half to leave behind. Where one phase regenerates the same manual file identically across several runs, one sign-off is extracted, named for the run the phase designates as its sign-off bundle |
| D8 | **`$REIMAGE_ARTIFACT_ROOT` is the scope boundary.** A file that looks like a capture but does not live under the artifact root is out of scope for conversion and re-run, whatever it resembles |

### What D5 means in practice

The two halves name their sign-off roots differently and that is now deliberate:

- **pre-image:** `$REIMAGE_ARTIFACT_ROOT/<category>/sign-offs/`
- **post-image:** `$REIMAGE_ARTIFACT_ROOT/reimaged-system/sign-offs/`

Write that sentence into `references/master-directory-reference.md`. The
asymmetry currently reads as drift; one line makes it a documented choice, and
the next coverage pass stops re-opening it.

### The one exception D5 did not cover — closed

`bin/restore-repos.sh` wrote its sign-off to `repo-audit-reports/sign-offs/`: a
**post-image** sign-off in a category shared with the pre-image audit, so on the
wrong side of D5 rather than an instance of it. **Moved 2026-09-02** to
`reimaged-system/sign-offs/`, while the old directory still did not exist — so
the change was one line and a doc pass rather than a migration.

## 2. Target layout

```text
$REIMAGE_ARTIFACT_ROOT/
├── <pre-image category>/
│   ├── runs/ MANIFEST.md official/     # automated evidence
│   └── sign-offs/                      # answered rows, one file per run id
└── reimaged-system/
    ├── <post-image category>/          # boundaries, state, comparisons, restarts
    ├── checklists/                     # the post-image capstone, run-indexed
    └── sign-offs/                      # every post-image answered row
```

`reimage-prep-checks/` is the pre-image capstone's category and keeps that role;
it gains `runs/`, `MANIFEST.md`, `official/` and `sign-offs/` like any other.

## 3. Splitting the mixed-mode artifacts

### What is mixed, verified on the volume

35 files, in three groups. A file counts as mixed only if its manual section
holds **answerable rows** — a `## Manual` section that merely points at a
sign-off is the correct current shape and is not touched.

| Group | Files | Rows | Why they are mixed |
|---|---|---|---|
| `reimaged-system/restarts/runs/*/checklist.md` | 6 | 13–15 each | Written 2026-08-18/19, before `sign-offs.sh` existed |
| `reimaged-system/boundaries/runs/*/checklist.md` | 17 | 1–5 each | Same, 2026-08-20 to 2026-08-31 |
| `reimage-prep-checks/reimage-checklist-*.md` | 11 | 14 each | Phase 6B capstone, 2026-08-17/18, `## Manual Sign-Off (Pre-Image)` |
| `time-machine/final-time-machine-checklist-*.md` | 1 | 2 | Phase 5, 2026-08-17 |
| `office-stability/checklists/.../pre-image-office-stability-checklist.md` | 1 | — | `### Manual Sign-Off Needed` **rendered as automated `WARN` rows** |

**The current generation is already clean.** `restore-git-exit-20260901-153636`
and `enroll-and-stabilize-exit-20260901-144422` carry a `## Manual` section that
names the sign-off file and holds no rows. The split is temporal, not systemic:
everything written after Revision 116 is right.

**One of the mixed files is an official pointer target** —
`verify-reimaged-system-exit-20260831-160233`, 3 rows. Splitting it changes what
`official/verify-reimaged-system-exit.txt` resolves to the contents of.

### Procedure

1. **Back up first, whole and once.** A dated copy of the artifact root's
   affected categories to a second location, before anything moves. Not a
   per-file `.bak` — those become the clutter the repo conventions reject. One
   archive, named for the date, referenced from the manifest entry.
2. **Extract, do not rewrite.** For each mixed file: lift the manual rows into
   `<category>/sign-offs/<run-id>.md` in the shape `sign-offs.sh` writes
   (`Item`, `Status`, `Answered against`, `Notes`), preserving every answer
   exactly as given. Replace the section in the original with the pointer text
   the current generation uses.
3. **`Answered against` gets the run id the answer came from**, which for these
   is the run the file sits in. That is the honest value and it is what makes the
   carried/answered distinction work afterwards.
4. **A script does this, not hand-editing.** 35 files with a common shape is a
   script — `.internal/` helper, invoked by a one-shot `bin/` entrypoint, dry-run
   first, writing a report of what it moved. Hand-editing 35 artifacts is how one
   answer gets silently dropped.
5. **`office-stability` is the odd one** and should be done by hand or skipped:
   its manual items are `record_check WARN` rows inside the automated table, not
   a separate section, so there is nothing to lift cleanly. Fixing the producer
   matters more than fixing the artifact.

### D7 — the purely manual artifact, which is a move and not a split

A split exists because a mixed-mode artifact has an automated half that must stay
with its run. An artifact that is **only** answered rows has no such half, so the
whole file moves to `sign-offs/` and nothing is left behind.

The test is the presence of an answerable status column, not the word "manual" in
the filename. Two files in the `verify-reimaged-system` restart bundles show the
difference:

| File | Answerable rows | Verdict |
|---|---|---|
| `restart-checkpoints.md` | 6, all `TODO` | **Manual.** Moves under D7 |
| `manual-captures-required.md` | 0 — columns are *Area · Manual Item · Why Manual* | **Not manual content.** Generated rationale that enumerates the manual rows of `checklist.md` and says why each cannot be scripted. It holds no answer, is regenerated identically, and is cited as Phase 14's pre-flight input at its in-run path by six documents. It stays |

**One sign-off per set of answers, not per run.** `restart-checkpoints.md` is
byte-identical across the runs that share a generator version, and its rows are
phase-level rather than run-level — there is one set of answers to carry, so one
sign-off is extracted. `verify-reimaged-system.md` designates the **post-restart**
bundle as the sign-off bundle, and that is the copy that carries.

The copies left in the other runs are generated companions like `README.md` and
`time-machine-plan.md`: regenerated identically on rerun, holding nothing a rerun
could destroy.

### D8 — the artifact root is the boundary

Conversion and re-run apply to `$REIMAGE_ARTIFACT_ROOT` and nowhere else.

`home-files-backup/home/reimage-workspace/` contains a 2026-06-30
office-stability bundle that pattern-matches a convertible artifact exactly. It is
restored home content that happens to hold artifact-shaped files. It is not
evidence, it is not in scope, and the rule is positional rather than a judgement
about what the file looks like — which is what makes it safe to apply without
opening the file.

### What is not touched

Automated content, in any file. Run directory names. Pointers. The
`reimage-prep-checks/manual/` files (`loose-plaintext-cleanup-signoff-20260817.md`,
`manual-export-pass-criteria-20260817.md`) are already separate, already manual,
and already correct in substance — they move to `reimage-prep-checks/sign-offs/`
unchanged, or stay put with a note. That is a rename, not a split.

## 4. Retiring inline generation

### The distinction that decides scope

A runbook code block that writes to **the machine** is the restore action itself
and stays inline: `restore-git.md` writing `~/.ssh/config`, `~/.gitconfig`,
`$GIT_PERSONAL_REPO_ROOT/.gitconfig`, `~/.config/git/config.local`;
`restore-runtime.md` appending to `~/.zprofile`. Six blocks. **Do not convert
these** — a script that writes a user's SSH config is worse than a visible
heredoc the operator reads before running.

A block that writes to **the artifact root** is producing evidence, and evidence
has a producer. Those convert.

### The conversion list

| Runbook | Line | Writes | Becomes |
|---|---|---|---|
| `reimage-prep-checks.md` | 370 | `reimage-prep-checks/manual/pre-image-final-manual-signoff-*.md` | **Highest priority** — a sign-off authored by a heredoc, in the directory D1 retires. `reimage-checklist.sh` already declares the same rows via `signoff_row` (lines 1644–1653). This block is a second, divergent copy of them |
| `backup-apps.md` | 722 | `app-settings-backup/postman/inventory/postman-vault-inventory-*.md` | An inventory → a script |
| `backup-apps.md` | 1101 | `app-settings-backup/raycast/raycast-export-inventory-*.md` | An inventory → a script |
| `backup-apps.md` | 619, 638, 972, 995 | four `README.md` files under `app-settings-backup/` and `secrets-encrypted/` | Static explanatory text → `.internal/templates/`, copied by `backup-apps.sh` |
| `backup-apps.md` | 831, 1248, 1268 | `terminal/window-size-note.txt`, `tnas-pc/connections-note.txt`, `imovie/libraries-note.txt` | Answered rows in note form → sign-off rows |
| `restore-home.md` | 226 | `reimaged-system/restore-notes/restore-home-*.md` | A manual note → a sign-off, post-image root |
| `stage-loose-secrets.md` | 345 | appends to `secrets-encrypted/staged-loose/MANIFEST.tsv` | A manifest append from a runbook block. Belongs in `stage-loose-secrets.sh` |

`stage-certs-keychain.md` 186–191 and `reimage-guide-access.md` 365–366 are
`mkdir -p` and `rsync` inside quoted fallback blocks — scaffolding and copying,
not authoring. Leave them.

### The producer that needs fixing more than its artifact

`bin/office-stability-checklist.sh` emits its manual items as
`record_check WARN "…" "Manual: …"` inside the automated table (lines 655–665).
They are answered rows wearing an automated verdict, so they re-appear as WARN on
every run no matter how many times they are answered — the exact failure
`sign-offs.sh` exists to prevent. Convert to `signoff_row` and adopt
`signoff_begin`. It is the last checklist producer that has not.

## 5. Run-indexing the capstone checklists

Decided (D6). The shape falls out of the existing library:

| | Pre-image | Post-image |
|---|---|---|
| Category root | `reimage-prep-checks/` | `reimaged-system/checklists/` |
| Context | `pre-image` | `post-image` |
| Point | `unknown` → latest-wins | same |
| Sign-offs | `reimage-prep-checks/sign-offs/` | `reimaged-system/sign-offs/` |

Latest-wins is correct and needs no argument: a capstone is regenerated until it
is green, and the newest run is the record. The 11 existing pre-image checklists
become 11 runs under `runs/`, recovered by `reindex-artifact-runs.sh` exactly as
`repo-audit-reports/` was.

**Two things this buys immediately.** `latest-reimage-checklist.txt` — the last
legacy pointer file in the pre-image tree apart from `toolkit-snapshot`'s
symlinks — goes away, replaced by `official/pre-image.txt`. And the post-image
capstone lands indexed from its first run, because **Phase 14 has not run yet**.
That is the same free-window argument that justified Revisions 121 and 127, and
it is open now.

`bin/reimage-checklist.sh` already resolves both roots and already calls
`signoff_begin` for both phases, so this is a bracket around existing work rather
than new machinery.

## 6. Order of work

Strict, and each step is independently reviewable.

1. ~~**Move `restore-repos.sh`'s sign-off root** to `reimaged-system/sign-offs/`.~~
   **Done 2026-09-02**, before Phase 11B first succeeded, so nothing had to be
   migrated. `bin/restore-repos.sh` line 334, plus `restore-repos.md`'s
   *What it sets up* and `references/restore-file-reference.md`'s Phase 11B row.
2. **Convert `office-stability-checklist.sh`** to `signoff_begin` / `signoff_row`.
   Fixes the producer that is still generating mixed output today.
3. **Retire `reimage-prep-checks.md`'s inline sign-off block** (line 370) in
   favour of the `signoff_row` declarations the script already has. Removes a
   divergent second copy of the same rows.
4. **Run-index both capstones** (§5), including reindexing the 11 existing
   pre-image checklists.
5. **Split the 35 mixed artifacts** (§3), backup first, by script, dry-run first.
6. **Convert the remaining inline generators** (§4), lowest priority — they are
   producing correct content in an inconvenient way, which is a smaller problem
   than everything above.
7. **Document D5** in `references/master-directory-reference.md`.

Steps 1–4 are repository changes and each earns a manifest revision. Step 5
changes the artifact root and no repository file except the one-shot splitter;
it earns one too, naming the backup.

## 7. Open questions

- **Where does the backup live?** Not on the same volume, or it is not a backup.
  Time Machine covers the artifact drive only if it is included, and
  `run-time-machine.md` excludes `/Volumes/Data` deliberately.
- **Do the 11 pre-image capstone runs each keep their own sign-off**, or does the
  latest one carry the answers forward? `sign-offs.sh` carry-forward assumes a
  sequence of runs that already existed as runs. Reindexing creates that sequence
  retroactively, and the answers were all given against the flat files. Simplest
  honest answer: one sign-off per recovered run, `Answered against` naming that
  run, and let carry-forward operate from the newest onward.
- **`office-stability/checklists/` — answered 2026-09-02, and not the way this
  document first framed it.** The directory holds evidence bundles, not
  checklists and not sign-offs: system state, process transitions, watcher
  output, a command log, and a rendered report that is a view of the bundle.
  They are runs, and the correct name comes from item 4's conversion of that
  category rather than from an interim rename. D6 does not reach it. →
  `docs/runbook-findings/capture-office-stability/0013-office-stability-checklists-are-evidence-bundles/findings.md`. What *does*
  belong to this plan is §4's conversion of the producer, since its manual items
  are `record_check WARN` rows inside the automated table.
