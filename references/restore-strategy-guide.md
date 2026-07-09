[[reimaging-guide#Restore Strategy|← Back to Mac Reimaging Guide]]

# Restore Strategy Guide

How to get workflow docs and tooling back in front of you on a freshly reimaged Mac, before Git, SSH, or a full vault checkout is set up.

This document supports `reimaging-guide.md` by keeping the bootstrap problem — reading setup instructions before your setup tooling exists — in one place, separate from the general backup/restore strategy in `backup-strategy-guide.md`.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#The Bootstrap Problem|The Bootstrap Problem]]
- [[#Two Repos, Two Different Solutions|Two Repos, Two Different Solutions]]
- [[#Getting fractogenesis-toolkit (No SSH Needed)|Getting fractogenesis-toolkit (No SSH Needed)]]
  - [[#Why curl Instead of git clone|Why curl Instead of git clone]]
  - [[#Why the Repo Is Public|Why the Repo Is Public]]
  - [[#Why There's a Jump Drive Fallback at All|Why There's a Jump Drive Fallback at All]]
  - [[#Why the Jump Drive Payload Is Checksummed and Versioned|Why the Jump Drive Payload Is Checksummed and Versioned]]
  - [[#Validating This Actually Works|Validating This Actually Works]]
- [[#Getting reference-vault (Still Needs SSH)|Getting reference-vault (Still Needs SSH)]]
  - [[#Recommended Bootstrap Sequence|Recommended Bootstrap Sequence]]
  - [[#Where to Keep the Cheat Sheet|Where to Keep the Cheat Sheet]]
- [[#Important Safety Rules|Important Safety Rules]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

Once the Mac is wiped, more than just your data is gone — Obsidian, the vault checkout, and Git/SSH access all disappear too. Phase 6 onward assumes you can read `reimaging-guide.md` and follow linked runbooks. This guide covers how that's actually possible with nothing restored yet, and why the answer is different depending on which repo you mean.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## The Bootstrap Problem

The circular version of this problem, if everything lived in one private, SSH-only repo:

```text
Need: workflow docs cloned locally, readable
Requires: Git + SSH access configured
Requires: SSH private key restored
Requires: reading restore-git.md
Requires: workflow docs cloned locally  <- circular
```

That circularity is exactly why the reimage workflow was split out of `reference-vault` into its own repo, `fractogenesis-toolkit` — see the repo README's "Why a Separate Repo" section. Splitting the repo didn't just relocate the problem, it structurally broke the cycle for the docs and scripts that matter most in the early post-erase window.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Two Repos, Two Different Solutions

| Repo | Visibility | Needs SSH to fetch? | Solution |
|---|---|---|---|
| `fractogenesis-toolkit` | Public | No | `bootstrap.sh` via curl, or the jump drive fallback — see below |
| `reference-vault` | Private | Yes | SSH key restoration + `git clone` — see [[#Getting reference-vault (Still Needs SSH)|Getting reference-vault (Still Needs SSH)]] |

This matters because it changes what's actually on the critical path. **You do not need `reference-vault`, SSH, or Git to read `reimaging-guide.md` and follow it through Phase 9.** Restoring `reference-vault` is a separate, non-blocking task for getting your personal notes back — it can happen any time after Phase 6, in parallel with the rest of the reimage, not as a prerequisite to it.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Getting fractogenesis-toolkit (No SSH Needed)

### Why curl Instead of git clone

The first time `git` runs on a fresh macOS install, it triggers a GUI popup to install Xcode Command Line Tools — a large, blocking download, at exactly the moment you're least equipped to wait around or troubleshoot. `curl` and `tar`, by contrast, are core BSD userland binaries present on every Mac from first boot, with no install step and no popup.

`python3` carries the same risk as `git` on some macOS versions — before Command Line Tools are installed, running it can trigger the identical popup. This is why `test-guide-access.md` explicitly tests `python3 --version` as a prerequisite check rather than assuming it's safe: if `python3` does trigger the popup on a given macOS version, every Python script in `bin/` (including `prepare-artifact-root.py`) inherits that same blocking dependency.

### Why the Repo Is Public

A public repo needs zero authentication to fetch — which matters because SSH keys and Git credentials are literally what Phase 8B/9 are in the process of restoring. Relying on auth to fetch the tool that restores auth is circular, the same problem described above, just for a different repo. The trade-off: nothing in `fractogenesis-toolkit` can contain secrets or company-identifying details, since anyone can read it. Machine-specific and sensitive values belong in a local, untracked `reimage.env`, never in a committed file.

### Why There's a Jump Drive Fallback at All

Curl still requires network access, and Phase 6's Wi-Fi/Intune enrollment step isn't instant — there can be a real window with no network at all (captive portal, delayed profile push). The jump drive exists specifically for that window: a small, dedicated USB stick (separate from the large encrypted backup drive, which stays disconnected until enrollment settles) carrying `bootstrap.sh` plus a prebuilt tarball of the repo.

### Why the Jump Drive Payload Is Checksummed and Versioned

Two failure modes a jump drive introduces that curl doesn't:

1. **Staleness** — a tarball built weeks ago doesn't reflect the repo's current state. `bin/build-jump-drive-payload.sh` stamps a commit hash and build date into `.toolkit-version`, printed after every install, so staleness is visible at a glance instead of silently assumed.
2. **Corruption** — a copy operation onto a USB stick can fail partway with no obvious symptom. `bootstrap.sh` verifies a SHA-256 checksum before extracting, and refuses to proceed on a mismatch rather than installing something broken.

`bootstrap.sh` supports both paths through one script rather than two that could drift apart: no argument fetches from GitHub via curl, a tarball path installs from that file directly.

### Validating This Actually Works

None of the above is worth anything unassumed. `test-guide-access.md` (Phase 4B) is the runbook that proves both paths actually work — using only tools guaranteed present on a bare Mac, extracting into a throwaway location so a test never risks a real checkout, with explicit pass/fail criteria rather than an eyeballed "looks fine." Run it before trusting either mechanism for a real reimage, and again any time `bootstrap.sh` changes or a new phase is migrated.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Getting reference-vault (Still Needs SSH)

`reference-vault` stays private, so it still needs the traditional SSH-key-restoration path. This is **not** on the critical path for following the reimage workflow itself — `reimaging-guide.md` and every phase through 9 are fully readable and runnable from `fractogenesis-toolkit` alone. Do this whenever you want your personal notes back, not as a blocker.

### Recommended Bootstrap Sequence

```text
1. Confirm network access (Wi-Fi/Ethernet) and sign in to the Mac with your account.
2. Install Xcode Command Line Tools (provides git): xcode-select --install
3. Mount the encrypted secrets DMG from the external drive and unlock it
   with the password from your approved password manager.
   See: backup-dmg-secrets.md (Restore section) for the full procedure.
4. Copy the SSH keys out of the mounted DMG into ~/.ssh and fix permissions.
5. Add a minimal ~/.ssh/config entry (or use the work default identity)
   so `git clone` over SSH authenticates.
6. Clone reference-vault:
     git clone git@<github-host>:<org-or-user>/reference-vault.git
7. Once the repo is cloned, follow restore-git.md for the full dual-identity
   Git/SSH setup (this replaces the minimal step 5 above with the permanent config).
```

Note what's *not* in this sequence anymore: there's no step telling you to open `reimaging-guide.md` from inside `reference-vault` once cloned — that file no longer lives there. If you're following this sequence, you're already reading the guide from your `fractogenesis-toolkit` checkout; this sequence exists purely to get your personal vault back, independently.

Steps 3–4 depend on `reimage.env`'s values (key filenames, host aliases) to fill in placeholders later in `restore-git.md`. Since `reimage.env` itself is not committed to Git, confirm it is captured somewhere reachable during bootstrap — either inside the encrypted secrets DMG alongside the SSH keys, or as a note in your password manager — before you wipe the Mac. Without it, the SSH/Git restore steps still work, but you will need to reconstruct the key names and host aliases by hand.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Where to Keep the Cheat Sheet

If you still want a redundant, low-effort artifact for the `reference-vault` sequence above (separate from `fractogenesis-toolkit`, which no longer needs one), keep it as a plain `.md` (or `.txt`) file, not an Obsidian-specific export — readable in TextEdit, `cat`, or any browser before any tooling is restored.

Store it redundantly in at least two of these locations:

```text
$REIMAGE_ARTIFACT_ROOT/workflow-bootstrap/bootstrap-cheatsheet.md   (external drive, always available, no network needed)
<OneDrive root>/workflow-bootstrap/bootstrap-cheatsheet.md (needs OneDrive re-signed-in, but survives drive loss/damage)
```

Do not rely on OneDrive alone — it typically is not usable until you've signed back into the Mac and OneDrive has finished its own setup, which may itself depend on steps later in the cheat sheet. The external drive copy is the one you actually reach for first.

The source of truth for the cheat sheet's content should still be `templates/bootstrap-cheatsheet.md` in the `reference-vault` repo, so future edits flow the same way as other templates. Copy the rendered file out to the external drive and OneDrive as part of Phase 1 (preparing the artifact root), and refresh the copies if the cheat sheet changes before your next reimage.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Important Safety Rules

### Do not put private key material in the cheat sheet

The cheat sheet should only contain commands and paths, never the actual SSH private key contents, DMG password, or other secrets. Those stay in the encrypted DMG and your password manager.

### Do not skip the DMG password step

Do not create a copy of the SSH keys unencrypted on the external drive "just in case." The encrypted DMG is the one approved place for private keys on the external drive — see `backup-strategy-guide.md` → Important Safety Rules.

### Keep the cheat sheet in sync with restore-git.md

If SSH key filenames, host aliases, or the clone command shape change in `restore-git.md`, update `templates/bootstrap-cheatsheet.md` at the same time so the redundant copies don't go stale.

### fractogenesis-toolkit has no equivalent secret to protect

Unlike the `reference-vault` cheat sheet, nothing about `fractogenesis-toolkit`'s bootstrap mechanism involves secrets — the repo is public by design, and `reimage.env` (the one file that does carry machine-specific values) is never committed. There's no DMG-password-equivalent risk to manage for this half of the bootstrap problem.

[[#Table of Contents|⬆ Back to Table of Contents]]
