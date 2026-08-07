---
title: Restore Home
back_link: "reimaging-guide#Phase 13 — Restore Home"
runbook_version: 0.1.0
verb_first: true
primary_scripts: []
related_scripts: []
artifact_paths:
  - $REIMAGE_ARTIFACT_ROOT/home-files-backup/home/
  - $REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/
  - $REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live/
  - $REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/
author: Orah Kittrell
last_updated: 2026-08-05
---
[[reimaging-guide#Phase 13 — Restore Home|← Back to Mac Reimaging Guide]]

# Restore Home

Restore selected personal-home content from the plain-text `home-files-backup/` bundle produced by Phase 2B, after the rebuilt Mac has already proved itself for normal development and daily use. This is the intentionally-latest phase: nothing about the reimaged system's stability, security posture, or clean-baseline claim should depend on any file restored here. The runbook is manual and does not run a fractogenesis-toolkit entrypoint — every restore is a small, deliberate `rsync` or per-file merge that the operator justifies against a specific need.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
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

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Bring back the specific personal-home content — `Documents`, `Desktop`, personal scripts, curated dotfiles, and any narrow config folders the operator has already decided to keep — from the plain `home-files-backup/` bundle. This is the phase that consumes the bulk local-file backup produced by [[backup-home|backup-home.md]] (Phase 2B), and it deliberately runs after Phase 12 sign-off so nothing here can regress the "the rebuild is trusted" baseline.

This runbook owns:

```text
merging selected home subfolders (Documents, Desktop, scripts, config-files-backups, Movies/Music/Pictures if kept)
selectively merging dotfiles (~/.zshrc, ~/.aliases, ~/.functions, ~/.gitconfig deltas)
copying narrow config trees under home-files-backup/dotfiles/config/, azure/, cf/, copilot/, kube/, etc.
reconnecting OneDrive and waiting for its baseline sync to settle before touching OneDrive-managed paths
recording each restore decision under reimaged-system/restore-notes/
```

It does not own:

```text
the backup itself — Phase 2B (backup-home)
SSH keys, certificates, Java trust, and other credential-bearing dotfiles — Phase 8B (restore-access, via secrets-encrypted/)
Git identity dotfiles that are part of dual-identity plumbing — Phase 9A (restore-git)
per-app support folders under ~/Library/Application Support/ — the app-specific runbooks (restore-apps.md, restore-intellij.md, restore-docker.md)
staged ignored files that live inside a repository — Phase 9B (restore-repos, via staged-ignored-files/live/)
```

This runbook is rerunnable in the sense that each `rsync` is idempotent, but it is not meant to be re-run wholesale — a second pass typically reintroduces the same "should I have restored this?" question. Prefer to run it once, carefully, and record the outcome.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Phase 13 is intentionally last because plain-text home-file restore is where a clean rebuild goes to accumulate old clutter: stale preferences, obsolete scripts, machine-specific config, and duplicated OneDrive content. The rebuilt Mac is already useful — Phase 12 says so — and the goal here is to reintroduce the specific personal-home content that still earns its place, not to reconstruct the pre-image `$HOME` byte-for-byte.

The order matters. OneDrive reconnects first, because half of the interesting content is already in the cloud and the sync client is the supported restore path for anything under `~/Library/CloudStorage/OneDrive-*/`. Copying files into a OneDrive path before OneDrive has settled produces conflict copies at best and silent duplication at worst. Personal home subfolders come next, restored one target at a time so the operator can see the diff and stop if something unexpected shows up. Dotfiles are merged, never overwritten wholesale — the reimaged system's shell startup files have already been touched by Phase 5 (`bootstrap.sh`) and Phase 8A/B (runtime + access), and blindly overlaying a pre-image `~/.zshrc` undoes that. Finally, categories with special rules (Downloads, `~/Library/Application Support/`, secrets) get called out separately so they route through the right runbook or get skipped on purpose.

Every restore decision, including "I decided not to restore X," goes into a note under `reimaged-system/restore-notes/`. Phase 13 has no automated evidence — the note is the artifact.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path this runbook uses is defined here, once. Later steps refer back to these names instead of restating them.

Primary source bundle:

```text
$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/
$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/
```

Optional source for repo-specific ignored files that were never committed:

```text
$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live/
```

Restore notes (this runbook writes here):

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-home-YYYYMMDD.md
```

Directory shape read by this runbook (the full `home-files-backup/` layout, including the complete dotfiles inventory, lives once in [[master-directory-reference|Master Directory Reference]]):

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── home-files-backup/
│   ├── MANIFEST.md
│   ├── dotfiles/
│   │   └── ...
│   └── home/
│       ├── Desktop/
│       ├── Documents/
│       ├── Movies/
│       ├── Music/
│       ├── Pictures/
│       ├── config-files-backups/
│       └── scripts/
├── ...
├── reimaged-system/
│   └── restore-notes/
│       └── restore-home-YYYYMMDD.md
├── ...
└── staged-ignored-files/
    └── live/
        └── <label>/
```

### Environment Variables

The `reimage.env` values this runbook depends on. Resolved and written during [[prepare-artifact-root|prepare-artifact-root.md]].

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Mounted external artifact volume that holds the pre-image `home-files-backup/` bundle and the `reimaged-system/restore-notes/` destination. |
| `FRACTOGENESIS_HOME` | Local checkout of `fractogenesis-toolkit`. Set by the shell session; the runbook assumes you are at this directory. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 12 [[reimaged-system-checks|reimaged-system-checks.md]] is complete and clean. If Phase 12 raised outstanding rows, resolve them before touching bulk home content — you want to know the reimaged system was trusted before Phase 13 started, not after.
- The external artifact volume is mounted and `$REIMAGE_ARTIFACT_ROOT` resolves; `home-files-backup/home/` and `home-files-backup/dotfiles/` are reachable.
- Phase 8B ([[restore-access|restore-access.md]]) has already restored credential-bearing dotfiles (SSH keys, certificates, Java trust). Do not re-copy anything from `dotfiles/` that would conflict with those.
- Phase 9A ([[restore-git|restore-git.md]]) has already written the dual-identity `~/.gitconfig`. Do not restore `home-files-backup/dotfiles/.gitconfig` wholesale on top of it.

> [!bug] Troubleshooting
> If `$REIMAGE_ARTIFACT_ROOT` is unset or unreachable, either mount the artifact volume and re-source `reimage.env`, or pass `--artifact-root PATH` explicitly to any helper that supports it.

### Confirm Your Intent

- Which specific home subfolders and dotfiles justify restore? Draft the shortlist in Step 2 before running any `rsync`; do not restore anything not on the list.
- Are you rebuilding a personal-use Mac (where old `Documents/` clutter is annoying but low-risk) or a shared / regulated device (where any spurious PII carry-forward is a compliance issue)? Bias toward *not* restoring on the second.
- Do you want the restore notes under the default `reimaged-system/restore-notes/`, or a scratch location for a personal machine? The default is what Phase 12 sign-off expects on a work rebuild.

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

### Step 3 — Restore Selected Home Subfolders

Restore one target at a time. Prefer `rsync -av --dry-run` first for anything larger than a folder full of hand-picked files, then rerun without `--dry-run` once the diff looks right:

```bash
# Example — Documents (only if on the shortlist)
rsync -av --dry-run "$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Documents/" "$HOME/Documents/"
rsync -av "$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Documents/" "$HOME/Documents/"

# Example — Desktop
rsync -av "$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/Desktop/" "$HOME/Desktop/"

# Example — personal scripts
rsync -av "$REIMAGE_ARTIFACT_ROOT/home-files-backup/home/scripts/" "$HOME/scripts/"
```

Update the restore note as you go. Any target *not* on the shortlist stays skipped even if it looks harmless.

> [!note]
> `rsync -av` preserves permissions and timestamps but does not delete unmatched files in the target — if the reimaged `~/Desktop/` already has content, the merged result is the union. Add `--delete` only when you actively want the pre-image tree to overwrite the reimaged tree, which is rare here.

### Step 4 — Merge Dotfiles Selectively

Never overlay `home-files-backup/dotfiles/` onto `$HOME` wholesale. The reimaged system's shell startup files have already been touched by Phase 5, 8A, and 8B, and Git identity plumbing has been written by Phase 9A. For each dotfile you plan to merge, diff first and copy only the specific stanzas that still matter:

```bash
# Example — .zshrc diff and selective merge
diff -u ~/.zshrc "$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/.zshrc" | less
# Edit ~/.zshrc by hand, copying only the stanzas you need.
```

Categories to consider:

| Dotfile / subtree | Guidance |
|---|---|
| `.zshrc`, `.zprofile`, `.zshenv` | Merge specific stanzas (custom PATH additions, aliases, prompt tweaks). Do not overwrite. |
| `.bash_profile`, `.bashrc` | Same — merge; overwrite only if you know Phase 5/8 wrote nothing there. |
| `.aliases`, `.exports`, `.functions` | Usually safe to copy across if you author them from scratch, but review first. |
| `.shell_common.sh`, `.shell_aliases.sh`, `.shell_local.sh` | Selective merge; `.shell_local.sh` is the machine-specific layer. |
| `.gitconfig` | Do NOT restore. Phase 9A owns this. |
| `dotfiles/config/`, `dotfiles/copilot/`, `dotfiles/kube/`, `dotfiles/azure/`, `dotfiles/cf/`, `dotfiles/fiddler/`, `dotfiles/dotfiles.falkor.d/` | Restore per-subtree with `rsync -av --dry-run` first. Kube contexts and CF targets in particular can drift. |

### Step 5 — Handle Categories with Special Rules

| Category | Route |
|---|---|
| OneDrive-managed folders (`~/Library/CloudStorage/OneDrive-*/…`) | Prefer cloud resync over manual copy. Restore into these paths only for content OneDrive definitely does not already have. |
| `~/Downloads` | Usually skip. Restore individual files by hand if still needed. |
| `~/Library/Application Support/…` | Routed through the app-specific runbooks (`restore-apps.md`, `restore-intellij.md`, `restore-docker.md`). Never bulk-restore here. |
| Anything credential-shaped (`.env`, `.keystore`, keys, tokens) | Restore only from `secrets-encrypted/` (Phase 8B), never from `home-files-backup/`. |
| Repo-scoped ignored files that never committed | Restored by Phase 9B (`bin/restore-repos.sh --apply-ignored-files`) from `staged-ignored-files/live/`, not here. |
| Old machine-specific tool state you no longer use | Leave behind on purpose. Record the decision in the restore note. |

If a genuinely useful file only shows up under `~/Library/Application Support/…` in the bundle, restore it via the matching app runbook so the app-specific validation catches it.

### Step 6 — Record the Restore and Validate

Fill in the restore note started in Step 2 with what you actually restored, what you deliberately skipped, and any conflict copies or OneDrive-adjacent surprises. Close the Phase 13 validation table below:

| Check | Status |
|---|---|
| Restored folders were selected intentionally | `TODO` |
| No unexpected OneDrive duplication was introduced | `TODO` |
| Dotfile merges were reviewed, not blindly copied | `TODO` |
| Required personal files are back in place | `TODO` |
| Obsolete or risky content was left out on purpose | `TODO` |

If Phase 13 introduced anything that Phase 12 already signed off on, rerun the relevant Phase 12 spot-check before considering the whole reimage complete.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The scripts do X; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Which home subfolders to restore at all | The pre-image bundle contains everything; restore is a curation exercise, not a copy operation. |
| Which dotfile stanzas to merge and which to drop | Reimage is a chance to prune shell configuration that has accumulated over years. Only stanzas you can justify go back. |
| Whether a OneDrive-adjacent file should be restored manually or left to cloud sync | Manual copy wins only when OneDrive definitely does not already have the file; otherwise cloud sync is the supported path. |
| Whether an "early exception restore" during earlier phases justifies a Phase 13 skip | Some content restored during Phase 8B or Phase 10 will look at first glance like it belongs here. Record it in the restore note and move on. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### `rsync` produced conflict copies inside a OneDrive path

OneDrive was still syncing when Step 3 ran. Stop, quarantine the conflict copies (`filename-machinename.ext`), let OneDrive settle, and re-merge by hand.

### Shell startup broke after a `.zshrc` merge

A stanza copied from the pre-image `.zshrc` references a path or command that no longer exists on the reimaged system (e.g. `. "$HOME/.nvm/nvm.sh"` when `nvm` is not installed). Revert to the pre-merge `.zshrc` (if you kept a copy), or comment out the offending line and rerun `exec zsh -l`.

### `.gitconfig` regressed to a single-identity file

`dotfiles/.gitconfig` was restored on top of Phase 9A's dual-identity file. Re-run Phase 9A's identity plumbing steps; they are idempotent.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

### Why this phase does not have a companion script

Every earlier restore phase either produces evidence a script can validate (Phase 6, 7, 9B, 10 plan-notes) or writes into paths a script can verify exist (Phase 8A/8B). Phase 13 does neither: the "right answer" for what to restore is a judgment call, and automating the copy step removes the deliberation the phase depends on. The absence of a script is intentional. If a future rebuild wants a `bin/restore-home.sh` that emits a plan-note like Phase 10's, it should still stop short of running any `rsync` on its own.

### How this phase relates to Phase 9B (restore-repos)

Repo-scoped ignored files (`.env`, local build outputs the operator explicitly kept, IDE-scratch files that are gitignored but valuable) are Phase 9B's problem, not Phase 13's. They flow from `staged-ignored-files/live/<label>/` into the cloned working tree via `bin/restore-repos.sh --apply-ignored-files`. If Phase 13 finds such a file under `home-files-backup/` (misclassified during Phase 2B), route it through Phase 9B by hand rather than copying it into `$HOME` here.

[[#Table of Contents|⬆ Back to Table of Contents]]
