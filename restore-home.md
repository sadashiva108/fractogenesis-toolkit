[[reimaging-guide#Phase 15 — Restore Home|← Back to Mac Reimaging Guide]]

# Restore Home

**Last updated:** 2026-09-02

Restore selected personal-home content from the plain-text `home-files-backup/` bundle produced by Phase 2B, after the rebuilt Mac has already proved itself for normal development and daily use. This is the intentionally-latest phase: nothing about the reimaged system's stability, security posture, or clean-baseline claim should depend on any file restored here. The runbook is manual and does not run a fractogenesis-toolkit entrypoint — every restore is a small, deliberate `rsync` or per-file merge that the operator justifies against a specific need.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Bundle Layout|Bundle Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Reconnect OneDrive and Wait for Sync|Step 1 — Reconnect OneDrive and Wait for Sync]]
    - [[#Step 2 — Draw the Explicit Restore Shortlist|Step 2 — Draw the Explicit Restore Shortlist]]
    - [[#Step 3 — Restore Selected Home Subfolders|Step 3 — Restore Selected Home Subfolders]]
    - [[#Step 4 — Merge Dotfiles Selectively|Step 4 — Merge Dotfiles Selectively]]
    - [[#Step 5 — Handle Categories with Special Rules|Step 5 — Handle Categories with Special Rules]]
    - [[#Step 6 — Record the Restore and Validate|Step 6 — Record the Restore and Validate]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Why This Phase Has No Companion Script|Why This Phase Has No Companion Script]]
    - [[#Relationship to Phase 11B — Restore Repositories|Relationship to Phase 11B — Restore Repositories]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Bring back the specific personal-home content — `Documents`, `Desktop`, personal scripts, curated dotfiles, and any narrow config folders the operator has already decided to keep — from the plain `home-files-backup/` bundle. This is the phase that consumes the bulk local-file backup produced by `backup-home` (Phase 2B), and it deliberately runs after Phase 14 sign-off so nothing here can regress the "the rebuild is trusted" baseline.

**What it sets up**

- **Merged home subfolders** — `Documents`, `Desktop`, `scripts`, `config-files-backups`, and `Movies` / `Music` / `Pictures` when they are kept, restored one target at a time from `home-files-backup/home/`.
- **Selectively merged dotfiles** — `~/.zshrc`, `~/.aliases`, `~/.functions`, and the other shell startup files, merged stanza by stanza rather than overwritten, with `~/.gitconfig` deltas reviewed rather than adopted wholesale.
- **Restored narrow config trees** — the per-tool subtrees under `home-files-backup/dotfiles/` (`config/`, `azure/`, `cf/`, `copilot/`, `kube/`, and siblings), copied per subtree.
- **A settled OneDrive** — the client reconnected and given a full sync baseline before any OneDrive-managed path is touched.
- **The restore shortlist** — the working note under `reimaged-system/restore-notes/` where you draft what earns a restore before any `rsync` runs.
- **The decisions** — each deliberate "not restored", appended to the event's `reimaged-system/restore-notes/decisions.md` by `bin/record-decision.sh`.

**What the rest of the workflow relies on it for**

- The restore note is this phase's only evidence — nothing here is script-validated, so the note is what shows later which content was carried forward and which was left behind on purpose.
- Closing the Phase 15 validation table, and rerunning any Phase 14 spot-check this phase disturbed, is what marks the whole reimage complete.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| merging selected home subfolders from `home-files-backup/home/` | the backup itself — `backup-home` (Phase 2B) |
| selective dotfile merges into the reimaged shell startup files | SSH keys, certificates, Java trust, and other credential-bearing dotfiles — `restore-access` (Phase 10B), via `secrets-encrypted/` |
| per-subtree restore of the `home-files-backup/dotfiles/` config trees | Git identity dotfiles that are part of dual-identity plumbing — `restore-git` (Phase 11A) |
| reconnecting OneDrive and waiting for its baseline sync to settle | per-app support folders under `~/Library/Application Support/` — `restore-apps`, `restore-docker`, `restore-intellij` (Phase 12) |
| recording each restore decision under `reimaged-system/restore-notes/` | staged ignored files that live inside a repository — `restore-repos` (Phase 11B), via `staged-ignored-files/live/` |
| | the post-image Time Machine backup that follows this phase — `run-time-machine` (Phase 16) |

This runbook is rerunnable in the sense that each `rsync` is idempotent, but it is not meant to be re-run wholesale — a second pass typically reintroduces the same "should I have restored this?" question. Prefer to run it once, carefully, and record the outcome.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Phase 15 is intentionally last because plain-text home-file restore is where a clean rebuild goes to accumulate old clutter: stale preferences, obsolete scripts, machine-specific config, and duplicated OneDrive content. The rebuilt Mac is already useful — Phase 14 says so — and the goal here is to reintroduce the specific personal-home content that still earns its place, not to reconstruct the pre-image `$HOME` byte-for-byte.

The order matters. OneDrive reconnects first, because half of the interesting content is already in the cloud and the sync client is the supported restore path for anything under `~/Library/CloudStorage/OneDrive-*/`. Copying files into a OneDrive path before OneDrive has settled produces conflict copies at best and silent duplication at worst. Personal home subfolders come next, restored one target at a time so the operator can see the diff and stop if something unexpected shows up. Dotfiles are merged, never overwritten wholesale — the reimaged system's shell startup files have already been touched by Phase 8 (`bootstrap.sh`) and Phase 10A/10B (runtime + access), and blindly overlaying a pre-image `~/.zshrc` undoes that. Finally, categories with special rules (Downloads, `~/Library/Application Support/`, secrets) get called out separately so they route through the right runbook or get skipped on purpose.

Every restore decision, including "I decided not to restore X," is appended to `reimaged-system/restore-notes/decisions.md` with `bin/record-decision.sh`. Phase 15 has no automated evidence — the record is the artifact. It is one append-only file for the whole reimage event rather than a dated file per pass, because a decision is not superseded by a later decision the way a capture is superseded by a later capture: both stay true, and the older one is usually the one you need later.

The dated shortlist note is a different thing and stays a different file. It is a worksheet for this pass — what you intend to restore, and why — and it is finished when the pass is.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path this runbook uses is defined here, once. Later steps refer back to these names instead of restating them.

Primary script:

```text
none — this phase runs no toolkit entrypoint; every restore is a plain shell command you run by hand
```

Related scripts, alphabetical:

```text
$FRACTOGENESIS_HOME/bin/record-decision.sh             # entrypoint — appends each deliberate "not restored" to decisions.md
diff                                                   # external helper — Step 4 compares a backed-up dotfile against the live one before merging
rsync                                                  # external helper — Steps 3 and 4 copy with an explicit flag set, never rsync -a
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/                # every artifact this runbook generates lands here
```

Input evidence built by earlier phases:

```text
$REIMAGE_ARTIFACT_ROOT/home-files-backup/MANIFEST.md   # written by backup-home.md — what the bundle actually holds, read in Step 2
$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/     # written by backup-home.md — shell and CLI config, merged file by file in Step 4
$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/         # written by backup-home.md — the personal-home subfolders Step 3 restores from
```

The complete `home-files-backup/` layout, including the full dotfiles inventory, is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Bundle Layout

Everything this runbook writes, under the artifact root named above. The bundle it restores from is listed in the block before this one and is not expanded here — `backup-home.md` owns that layout.

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── reimaged-system/
│   ├── ...
│   ├── restore-notes/
│   │   ├── decisions.md
│   │   └── restore-home-YYYYMMDD.md
│   └── ...
└── ...
```

Two files, and they hold different kinds of record. `restore-home-YYYYMMDD.md` is this pass's worksheet: the shortlist you drew in Step 2, and what you actually restored against it. `decisions.md` is one append-only file for the whole reimage event, carrying each deliberate "not restored" — a decision is not superseded by a later decision the way a capture is superseded by a later capture, so there is nothing to date and nothing to point an `official/` pointer at.

Neither is run-indexed, so this phase writes no `MANIFEST.md`, no `official/` pointer and no `runs/` directory. Phase 15 has no automated evidence: the notes are the artifact.

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Mounted external artifact volume that holds the pre-image `home-files-backup/` bundle and the `reimaged-system/restore-notes/` destination. |
| `FRACTOGENESIS_HOME` | Local checkout of `fractogenesis-toolkit`; the runbook assumes your shell is at this directory. Set by your shell startup / `.envrc`, not stored in `reimage.env`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the toolkit root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 14 (`reimaged-system-checks.md`) is complete and clean. If Phase 14 raised outstanding rows, resolve them before touching bulk home content — you want to know the reimaged system was trusted before Phase 15 started, not after.
- The external artifact volume is mounted and `$REIMAGE_ARTIFACT_ROOT` resolves; `home-files-backup/home/` and `home-files-backup/dotfiles/` are reachable.
- Phase 10B (`restore-access.md`) has already restored credential-bearing dotfiles (SSH keys, certificates, Java trust). Do not re-copy anything from `dotfiles/` that would conflict with those.
- Phase 11A (`restore-git.md`) has already written the dual-identity `~/.gitconfig`. Do not restore `home-files-backup/dotfiles/.gitconfig` wholesale on top of it.
- Terminal can read and write `~/Documents` and `~/Desktop`. On a fresh macOS install, the first time Terminal touches either one macOS raises a Files-and-Folders (TCC) consent dialog. Grant Terminal Full Disk Access up front — **System Settings → Privacy & Security → Full Disk Access** → add / enable Terminal (or iTerm), then quit and reopen it — or accept each prompt as it appears during Step 3. Denying the prompt does not stop the copy: `rsync` keeps going, prints `Operation not permitted` for the paths it was refused, and exits `23` with a partial tree. Re-run any `rsync` that reported `Operation not permitted` after access is granted.

> [!bug] Troubleshooting
> If `$REIMAGE_ARTIFACT_ROOT` is unset or unreachable, either mount the artifact volume and re-source `reimage.env`, or pass `--artifact-root PATH` explicitly to any helper that supports it.

### Confirm Your Intent

- Which specific home subfolders and dotfiles justify restore? Draft the shortlist in Step 2 before running any `rsync`; do not restore anything not on the list.
- Are you rebuilding a personal-use Mac (where old `Documents/` clutter is annoying but low-risk) or a shared / regulated device (where any spurious PII carry-forward is a compliance issue)? Bias toward *not* restoring on the second.
- Do you want the restore notes under the default `reimaged-system/restore-notes/`, or a scratch location for a personal machine? The default is what Phase 14 sign-off expects on a work rebuild; `bin/record-decision.sh --notes-root PATH` redirects the decisions log the same way.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. Each restore is deliberate — do not batch multiple targets into a single `rsync` invocation.

### Step 1 — Reconnect OneDrive and Wait for Sync

Reconnect OneDrive and let it establish a full sync baseline before touching any OneDrive-managed path.

Confirm before continuing:

```text
OneDrive signed in
company account selected
sync folders available
no large pending sync backlog before continuing
important work folders are present
files needed offline are marked "Always Keep on This Device"
```

> [!warning] Pitfall
> Restoring into a OneDrive-managed folder before OneDrive has settled produces conflict copies (`filename-machinename.ext`) or silent duplication. Wait until the OneDrive menu-bar icon shows "Up to date" before Step 3.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Draw the Explicit Restore Shortlist

Before any `rsync`, write down which categories you are actually restoring and why. Skim `home-files-backup/MANIFEST.md` to know what's actually in the bundle:

```bash
open "$REIMAGE_ARTIFACT_ROOT/home-files-backup/MANIFEST.md"
```

Draft the shortlist in a fresh restore note (Step 6 owns this file; touching it now gives you a place to record the "why"):

```bash
mkdir -p "$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes"
NOTE="$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-home-$(date +%Y%m%d).md"
[[ -e "$NOTE" ]] || cat > "$NOTE" <<'EOF'
Restore Home — YYYY-MM-DD

Restore shortlist (fill in before running rsync):
  home/Documents         — [ ] restore   why:
  home/Desktop           — [ ] restore   why:
  home/scripts           — [ ] restore   why:
  home/config-files-backups — [ ] restore   why:
  home/Movies            — [ ] restore   why:
  home/Music             — [ ] restore   why:
  home/Pictures          — [ ] restore   why:

Dotfile merges (selective; note per file):
  .zshrc                 — [ ] merge     notes:
  .aliases               — [ ] merge     notes:
  .functions             — [ ] merge     notes:
  .exports               — [ ] merge     notes:
  .shell_common.sh       — [ ] merge     notes:
  .shell_aliases.sh      — [ ] merge     notes:
  .shell_local.sh        — [ ] merge     notes:
  dotfiles/config/       — [ ] restore   notes:
  dotfiles/copilot/      — [ ] restore   notes:
  dotfiles/kube/         — [ ] restore   notes:
  dotfiles/azure/        — [ ] restore   notes:
  dotfiles/cf/           — [ ] restore   notes:

Categories intentionally NOT restored:
  home/Downloads         — reason:
  ~/Library/Application Support/* — routed through app-specific runbook

Completed by: TODO
EOF
open "$NOTE"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Restore Selected Home Subfolders

Restore one target at a time. Prefer a `--dry-run` pass first for anything larger than a folder full of hand-picked files, then rerun without `--dry-run` once the diff looks right. Do not reach for `rsync -a` here — the flag set below is deliberate, and the note underneath explains why:

Documents, only if it is on the shortlist — dry run first, then the real pass:

```bash
rsync -rltv -E --no-perms --no-owner --no-group --exclude .DS_Store --dry-run \
  "$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Documents/" "$HOME/Documents/"
rsync -rltv -E --no-perms --no-owner --no-group --exclude .DS_Store \
  "$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Documents/" "$HOME/Documents/"
```

Desktop:

```bash
rsync -rltv -E --no-perms --no-owner --no-group --exclude .DS_Store \
  "$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Desktop/" "$HOME/Desktop/"
```

Personal scripts:

```bash
rsync -rltv -E --no-perms --no-owner --no-group --exclude .DS_Store \
  "$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/scripts/" "$HOME/scripts/"
```

Update the restore note as you go. Any target *not* on the shortlist stays skipped even if it looks harmless.

> [!note]
> None of these `rsync` invocations delete unmatched files in the target — if the reimaged `~/Desktop/` already has content, the merged result is the union. Add `--delete` only when you actively want the pre-image tree to overwrite the reimaged tree, which is rare here.

> [!warning] Pitfall
> Do not substitute `rsync -av`. `-a` implies `-p -o -g`, so it copies the *source volume's* permission and ownership bits. An artifact drive that has to be readable from more than one machine is usually exFAT, which has no real POSIX modes — the driver synthesises them, and `-a` faithfully reproduces the synthetic result, landing every restored file world-writable `0777` (and owned by whoever mounted the volume). `-a` also does not carry macOS extended attributes or resource forks. `-rltv` copies content, timestamps, and symlinks; `-E` keeps extended attributes and resource forks; `--no-perms --no-owner --no-group` lets your own umask set sane modes on the reimaged Mac.

> [!note]
> Where Finder-visible metadata matters more than `rsync`'s incremental behaviour — ACLs, Finder tags, colour labels, resource forks on older files — use `ditto` instead for that one target: `ditto "$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Documents" "$HOME/Documents"`. `ditto` merges into an existing directory and preserves that metadata in one pass, but it has no `--dry-run` and no per-file progress, so preview with `rsync --dry-run` first when the tree is large.

> [!note]
> `--no-perms` means the executable bit does not come across if the source volume never carried one — exFAT does not. After restoring `home/scripts/`, re-apply it to anything meant to be run directly:
>
> ```bash
> ls -l "$HOME"/scripts/*.sh
> chmod +x "$HOME"/scripts/*.sh
> ```

> [!bug] Troubleshooting
> If files show up in a OneDrive-managed folder with a machine-name suffix, see [[#Conflict copies appeared inside a OneDrive path|Conflict copies appeared inside a OneDrive path]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Merge Dotfiles Selectively

Never overlay `home-files-backup/dotfiles/` onto `$HOME` wholesale. The reimaged system's shell startup files have already been touched by Phase 8, 10A, and 10B, and Git identity plumbing has been written by Phase 11A. For each dotfile you plan to merge, diff first and copy only the specific stanzas that still matter.

Before any diff or merge, snapshot every shell startup file this step can touch. A bad merge here is not a cosmetic problem — a `.zshrc` that references a missing path gives you a login shell that will not start, and the Troubleshooting fix below assumes a pre-merge copy exists. This is the first command of the step:

```bash
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.pre-restore-home-$STAMP"
mkdir -p "$BACKUP"
for f in .zshrc .zprofile .zshenv .bash_profile .bashrc \
         .aliases .exports .functions \
         .shell_common.sh .shell_aliases.sh .shell_local.sh; do
  [ -f "$HOME/$f" ] && cp -p "$HOME/$f" "$BACKUP/$f"
done
ls -la "$BACKUP"
```

Record `$BACKUP` in the restore note — the Troubleshooting entry below restores from it.

Then diff and merge, one file at a time:

`.zshrc`, as the worked example — read the difference first:

```bash
diff -u ~/.zshrc "$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/.zshrc" | less
```

Then edit `~/.zshrc` by hand, copying across only the stanzas you need. There is
no command for this half on purpose: a whole-file copy is what overwrites the
shell configuration Phase 10A just built.

Categories to consider:

| Dotfile / subtree | Guidance |
|---|---|
| `.zshrc`, `.zprofile`, `.zshenv` | Merge specific stanzas (custom PATH additions, aliases, prompt tweaks). Do not overwrite. |
| `.bash_profile`, `.bashrc` | Same — merge; overwrite only if you know Phase 8/10 wrote nothing there. |
| `.aliases`, `.exports`, `.functions` | Usually safe to copy across if you author them from scratch, but review first. |
| `.shell_common.sh`, `.shell_aliases.sh`, `.shell_local.sh` | Selective merge; `.shell_local.sh` is the machine-specific layer. |
| `.gitconfig` | Do NOT restore. Phase 11A owns this. |
| `dotfiles/config/`, `dotfiles/copilot/`, `dotfiles/kube/`, `dotfiles/azure/`, `dotfiles/cf/`, `dotfiles/fiddler/`, `dotfiles/dotfiles.falkor.d/` | Restore per-subtree with the Step 3 flag set (`rsync -rltv -E --no-perms --no-owner --no-group --exclude .DS_Store`) and `--dry-run` first. Kube contexts and CF targets in particular can drift. |

> [!bug] Troubleshooting
> If a new shell fails to start or floods the terminal with errors after a merge, see [[#Shell startup broke after a dotfile merge|Shell startup broke after a dotfile merge]].

> [!bug] Troubleshooting
> If `git` starts stamping the wrong author, or work and personal repos share one identity, see [[#Git identity regressed to a single identity|Git identity regressed to a single identity]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Handle Categories with Special Rules

| Category | Route |
|---|---|
| OneDrive-managed folders (`~/Library/CloudStorage/OneDrive-*/…`) | Prefer cloud resync over manual copy. Restore into these paths only for content OneDrive definitely does not already have. |
| `~/Downloads` | Usually skip. Restore individual files by hand if still needed. |
| `~/Library/Application Support/…` | Routed through the app-specific runbooks (`restore-apps.md`, `restore-docker.md`, `restore-intellij.md`). Never bulk-restore here. |
| Anything credential-shaped (`.env`, `.keystore`, keys, tokens) | Restore only from `secrets-encrypted/` (Phase 10B), never from `home-files-backup/`. |
| Repo-scoped ignored files that never committed | Restored by Phase 11B (`bin/restore-repos.sh --hydrate --stage ignored-files`) from `staged-ignored-files/live/`, not here. |
| Old machine-specific tool state you no longer use | Leave behind on purpose. Record the decision in the restore note. |

If a genuinely useful file only shows up under `~/Library/Application Support/…` in the bundle, restore it via the matching app runbook so the app-specific validation catches it.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 6 — Record the Restore and Validate

Fill in the restore note started in Step 2 with what you actually restored, what you deliberately skipped, and any conflict copies or OneDrive-adjacent surprises. Close the Phase 15 validation table below:

| Check | Status |
|---|---|
| Restored folders were selected intentionally | `TODO` |
| No unexpected OneDrive duplication was introduced | `TODO` |
| Dotfile merges were reviewed, not blindly copied | `TODO` |
| Required personal files are back in place | `TODO` |
| Obsolete or risky content was left out on purpose | `TODO` |

If Phase 15 introduced anything that Phase 14 already signed off on, rerun the relevant Phase 14 spot-check before considering the whole reimage complete.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

This phase runs no script, so every call here is yours; these are the ones that recur.

| Decision | Why it stays with you |
|---|---|
| Which home subfolders to restore at all | The pre-image bundle contains everything; restore is a curation exercise, not a copy operation. |
| Which dotfile stanzas to merge and which to drop | Reimage is a chance to prune shell configuration that has accumulated over years. Only stanzas you can justify go back. |
| Whether a OneDrive-adjacent file should be restored manually or left to cloud sync | Manual copy wins only when OneDrive definitely does not already have the file; otherwise cloud sync is the supported path. |
| Whether an "early exception restore" during earlier phases justifies a Phase 15 skip | Some content restored during Phase 10B or Phase 12 will look at first glance like it belongs here. Record it in the restore note and move on. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Three failures here either span more than one step or have a fix long enough to break a step's flow. The step that surfaces each one links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Conflict copies appeared inside a OneDrive path

OneDrive was still syncing when Step 3 ran. Stop, quarantine the conflict copies (`filename-machinename.ext`), let OneDrive settle until its menu-bar icon shows "Up to date", and re-merge by hand.

[[#Step 3 — Restore Selected Home Subfolders|⮕ Continue to Step 3 — Restore Selected Home Subfolders]]

### Shell startup broke after a dotfile merge

A stanza copied from the pre-image `.zshrc` references a path or command that no longer exists on the reimaged system (e.g. `. "$HOME/.nvm/nvm.sh"` when `nvm` is not installed). Restore the pre-merge copy Step 4 saved under `~/.pre-restore-home-<timestamp>/`, or comment out the offending line, then rerun `exec zsh -l`. If no shell will start at all, open a session that skips startup files first — `zsh -f`, or `bash --noprofile --norc` from Terminal's **Shell → New Command** — and repair from there:

```bash
ls -d "$HOME"/.pre-restore-home-*
PRE_RESTORE="replace-with-the-directory-listed-above"
cp "$PRE_RESTORE/.zshrc" "$HOME/.zshrc"
exec zsh -l
```

[[#Step 4 — Merge Dotfiles Selectively|⮕ Continue to Step 4 — Merge Dotfiles Selectively]]

### Git identity regressed to a single identity

`dotfiles/.gitconfig` was restored on top of Phase 11A's dual-identity file. Re-run Phase 11A's identity plumbing steps; they are idempotent. Leave `home-files-backup/dotfiles/.gitconfig` out of the merge from here on.

[[#Step 4 — Merge Dotfiles Selectively|⮕ Continue to Step 4 — Merge Dotfiles Selectively]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Why This Phase Has No Companion Script

Every earlier restore phase either produces evidence a script can validate (Phase 8, 9, 11B, 12 plan-notes) or writes into paths a script can verify exist (Phase 10A/10B). Phase 15 does neither: the "right answer" for what to restore is a judgment call, and automating the copy step removes the deliberation the phase depends on. The absence of a script is intentional. If a future rebuild wants an entrypoint for this phase — it would be named `restore-home.sh`, by the pairing convention — it should emit a plan-note like Phase 12's and still stop short of running any `rsync` on its own. No such script exists, and its absence is the design, not a gap.

### Relationship to Phase 11B — Restore Repositories

Repo-scoped ignored files (`.env`, local build outputs the operator explicitly kept, IDE-scratch files that are gitignored but valuable) are Phase 11B's problem, not Phase 15's. They flow from `staged-ignored-files/live/<label>/` into the cloned working tree via `bin/restore-repos.sh --hydrate --stage ignored-files`. If Phase 15 finds such a file under `home-files-backup/` (misclassified during Phase 2B), route it through Phase 11B by hand rather than copying it into `$HOME` here.

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
