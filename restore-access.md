[[reimaging-guide#Phase 8B — Restore Access|← Back to Mac Reimaging Guide]]

# Restore Access

**Last updated:** 2026-08-04

Restore the identity, trust, and credential layer on the reimaged Mac after the runtime toolchain is in place — SSH keys and Git access, certificates and keychains, Java trust overrides pinned to the JDK from Phase 8A, shell and CLI configuration, and license or activation material. Everything here comes out of the encrypted secrets DMG and the reviewed dotfiles bundle built during the pre-image phases; this runbook is manual and does not run a fractogenesis-toolkit entrypoint.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Mount the Encrypted Secrets DMG|Step 1 — Mount the Encrypted Secrets DMG]]
    - [[#Step 2 — Restore SSH and Git Access|Step 2 — Restore SSH and Git Access]]
    - [[#Step 3 — Restore Certificates and Keychain Material|Step 3 — Restore Certificates and Keychain Material]]
    - [[#Step 4 — Trust Imported Root and Issuing CA Certificates|Step 4 — Trust Imported Root and Issuing CA Certificates]]
    - [[#Step 5 — Restore Java Trust Overrides|Step 5 — Restore Java Trust Overrides]]
    - [[#Step 6 — Restore Shell Environment and CLI Config|Step 6 — Restore Shell Environment and CLI Config]]
    - [[#Step 7 — Restore Credentials and License Material|Step 7 — Restore Credentials and License Material]]
    - [[#Step 8 — Eject the DMG and Clean Up Plaintext|Step 8 — Eject the DMG and Clean Up Plaintext]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Restore the access layer that later repo, IDE, application, and project work depend on: SSH identity, TLS trust, JVM trust, shell environment, and credential and license material. Get the Mac to the point where it can authenticate to internal systems and reach services through the expected trust chain before Git restore (Phase 9) and application restore (Phase 10) start.

This runbook owns:

```text
mounting the encrypted secrets DMG and ejecting it cleanly
SSH keys, ~/.ssh/config, and permissions
certificates and keychain material restored from reviewed sources
Java trust overrides such as jssecacerts, pinned to the installed JDK
selective shell and CLI configuration restore from the dotfiles bundle
credentials, license keys, and activation material
```

It does not own:

```text
runtime tooling install (Xcode CLT, Homebrew, JDK, Node, platform CLIs) — Phase 8A (restore-runtime)
building or validating the encrypted secrets DMG — create-secrets-dmg.md (Phase 2F)
certificate and Keychain discovery, review, and staging — stage-certs-keychain.md (Phase 2E)
Git identity configuration and remote routing — Phase 9 (restore-git)
IntelliJ, Docker, and per-app secret restore — restore-intellij.md, restore-docker.md, and app-specific runbooks (Phase 10+)
```

This runbook can be rerun. Each step is either idempotent (SSH file copies, chmod, `security` imports) or a manual UI action; rerunning is the intended recovery path when a step misbehaves.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The order in this phase is not preference — it enforces a trust chain. SSH has to be in place before anything tries to reach GitHub. Certificates in the login and system keychains have to be trusted before non-Java tools (curl, git, browsers) can reach internal endpoints. The `jssecacerts` Java trust override has to be dropped into the *actual* installed JDK from Phase 8A, not a JDK that isn't there yet, which is why runtime restore precedes access restore at the phase level. Shell and CLI configuration is restored last of the identity-adjacent material because it can reference paths (`JAVA_HOME`, `NVM_DIR`) that the earlier phases just put in place; restoring dotfiles before that would risk sourcing profile files that reference tools not yet installed.

The runbook is script-free by design. Every restore is a small manual copy, `security` command, or Keychain Access GUI action, and each one carries a judgment call — is this key still the current one, should this cert really be Always Trust, does this dotfile still match how the machine is used — that a script cannot make. The encrypted DMG built in Phase 2F is the single source of truth for the secret-bearing material; the reviewed dotfiles bundle from Phase 2B is the single source of truth for shell and CLI config.

### Terminology

| Term | Meaning |
|---|---|
| Secrets DMG | The consolidated encrypted disk image built by `create-secrets-dmg.md` in Phase 2F. Named `all-secrets-*.dmg` and stored under `secrets-encrypted/`. |
| Dotfiles bundle | The reviewed shell and CLI config subset captured by `backup-home.md` and stored under `home-files-backup/dotfiles/`. Not encrypted; contains no secrets by design. |
| `jssecacerts` | A per-JDK Java trust override file. Copied into `$JAVA_HOME/lib/security/` and read by the JVM in addition to the default trust store. Must match the installed JDK. |
| Always Trust | A macOS Keychain trust setting that marks a certificate as valid for every use case. Correct only for genuine internal root or issuing CAs; a mistake for anything else. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path this runbook reads is defined here, once.

This runbook is manual and does not run a fractogenesis-toolkit entrypoint:

```text
$FRACTOGENESIS_HOME/bin/    # no primary script — this runbook is executed by hand
```

Input evidence built by earlier phases:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-*.dmg              # Phase 2F output — mounted read-only
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/                         # certificate staging, mirrored inside the DMG
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/java-security/           # jssecacerts and related JDK trust files
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/keychain-manual-exports/ # manual .cer/.p12 exports for Keychain Access
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/ssh/                           # SSH keys, config, known_hosts
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/git/                           # ~/.gitconfig and ~/.config/git/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/cli-credentials/               # per-tool credential exports
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/package-managers/              # npm, cargo, and similar credential stores
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/licenses/                      # license keys, offline activation files
$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/                            # reviewed shell/CLI config subset
$REIMAGE_ARTIFACT_ROOT/public-certs/                                    # reviewed non-secret CA and trust reference material
```

Live targets this runbook writes on the reimaged Mac:

```text
~/.ssh/                     # keys, config, known_hosts
~/.gitconfig                # global git config
~/.config/git/              # optional includes
$JAVA_HOME/lib/security/    # jssecacerts override for the installed JDK
~/Library/Keychains/        # login keychain trust settings
~/.zshrc, ~/.zprofile, ~/.bash_profile, ~/.bashrc, ~/.shell_common.sh, ~/.shell_local.sh, ~/.config/, ~/.kube/, ~/.cf/, ~/.azure/
```

The complete `secrets-encrypted/` layout is defined once in the Master Directory Reference, not redrawn here:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Artifact root for this reimage event; the mounted DMG, the dotfiles bundle, and `public-certs/` all resolve under it. |
| `JAVA_HOME` | Set explicitly in Step 5 to the JDK installed in Phase 8A before dropping in `jssecacerts`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 8A ([[restore-runtime|restore-runtime.md]]) is complete: JDK 17 (or the intended baseline) is installed and `java -version` prints it.
- The external artifact volume is mounted and `reimage.env` resolves. `ls "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"` should list at least one `all-secrets-*.dmg`.
- You have the DMG password from your password manager or wherever it was stored in Phase 2F. Do not proceed without it.

> [!bug] Troubleshooting
> `hdiutil attach` failing with "authentication error" almost always means the wrong password. If the password is correct, verify the DMG isn't already mounted (`hdiutil info | grep all-secrets`) — a leftover mount from an earlier attempt will refuse a second attach.

### Confirm Your Intent

- Are you doing a **full first-time restore** (Steps 1 through 8 in order) or a **targeted rerun** of one area (for example, just re-importing a certificate that was missed)? Both are safe; the difference is whether you also do Step 6's selective shell restore.
- Which **shell files** are you willing to overwrite versus merge? The default is *merge* — comparing each file in a diff tool before adopting changes. Blanket overwrites are a common way to lose machine-specific tweaks.
- Which **secret categories** are actually in scope for this restore? If a category is empty on the DMG (say, no Postman exports were taken), skip its step rather than inventing a source.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The order enforces a trust chain: SSH before Git access, keychain trust before Java trust, JDK trust before shell restore, credentials last of the identity-adjacent material, DMG eject last of all.

### Step 1 — Mount the Encrypted Secrets DMG

Mount the newest DMG read-only-ish; macOS mounts DMGs read-write by default, and that's fine here because the DMG is the source, not a target:

```bash
DMG="$(ls "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"/all-secrets-*.dmg | sort | tail -1)"
hdiutil attach "$DMG"
```

Enter the password when prompted. Confirm the mount:

```bash
hdiutil info | grep -A1 all-secrets
ls /Volumes/all-secrets*/
```

Every subsequent step reads from `/Volumes/all-secrets-*/`; do not copy the DMG's contents wholesale to disk.

### Step 2 — Restore SSH and Git Access

SSH first because everything else that talks to GitHub or an internal Git server needs it.

Copy the SSH material into place:

```bash
mkdir -p ~/.ssh
cp -R /Volumes/all-secrets-*/ssh/* ~/.ssh/
cp -R /Volumes/all-secrets-*/git/. ~/    # copies ~/.gitconfig and ~/.config/git/
```

Fix permissions — the SSH client refuses to use loose keys:

```bash
chmod 700 ~/.ssh
find ~/.ssh -type f -exec chmod 600 {} \;
```

Confirm the SSH identity works:

```bash
ssh -T git@github.com || true
```

> [!note]
> The full Git identity workflow (work vs personal routing, per-repo `.gitconfig`, dual-identity `~/.gitconfig`) belongs to [[restore-git|restore-git.md]] in Phase 9. This step is only about SSH reachability.

### Step 3 — Restore Certificates and Keychain Material

Import certificates from the reviewed manual exports. Do this in Keychain Access rather than by shell copy, so each import goes into the correct keychain and you can inspect the result immediately:

```bash
open -a "Keychain Access" /Volumes/all-secrets-*/certs/keychain-manual-exports/
```

For each `.cer` or `.p12` file, drag it into the target keychain (usually `login`) and enter the password if prompted. Reference the reviewed non-secret material under `$REIMAGE_ARTIFACT_ROOT/public-certs/` if you need to double-check which certs are which.

### Step 4 — Trust Imported Root and Issuing CA Certificates

`jssecacerts` in the next step only covers JVM tools. Non-Java tools (curl, git, browsers) rely on the macOS system and login keychain trust settings instead, so any internal root or issuing CA cert imported in Step 3 still needs its trust set explicitly.

Open Keychain Access and adjust trust in the GUI:

```bash
open -a "Keychain Access"
```

1. Search the `login` and `System` keychains for the internal root and issuing CA certificates.
2. Double-click each certificate and expand the **Trust** section.
3. Set **When using this certificate** to **Always Trust**.
4. Close the window and enter your password to save the change.

CLI equivalent, if you prefer to script the trust change instead of using the GUI:

```bash
security add-trusted-cert -d -r trustRoot -k "$HOME/Library/Keychains/login.keychain-db" "/Volumes/all-secrets-*/certs/keychain-manual-exports/root-ca.cer"
```

> [!warning] Pitfall
> Only mark a certificate as **Always Trust** if it is the company's actual internal root or issuing CA. Doing this for an arbitrary or unverified certificate opens the machine to trust attacks. If in doubt, leave the certificate's trust at "Use System Defaults" and revisit.

### Step 5 — Restore Java Trust Overrides

Only restore `jssecacerts` after confirming the target JDK is the one installed in Phase 8A — the file lives inside a specific JDK's `lib/security/` directory and does nothing if it lands next to a different JDK.

Pin `JAVA_HOME` explicitly:

```bash
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
ls -la "$JAVA_HOME/lib/security"
```

Copy the reviewed override into place:

```bash
cp /Volumes/all-secrets-*/certs/java-security/jssecacerts "$JAVA_HOME/lib/security/jssecacerts"
```

Validate an internal TLS use case afterward — the simplest smoke test is a `curl` or `gradle` call against an internal endpoint that requires the corporate root.

### Step 6 — Restore Shell Environment and CLI Config

Do not blindly overwrite fresh shell files. Diff first, adopt selectively.

Open a side-by-side comparison:

```bash
DOTFILES_BACKUP="$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles"
printf 'Using dotfiles backup: %s\n' "$DOTFILES_BACKUP"
code "$DOTFILES_BACKUP" "$HOME"
```

Common selective restores:

```text
.zshrc
.zprofile
.bash_profile
.bashrc
.gitconfig                # already restored in Step 2; skip if unchanged
.shell_common.sh
.shell_local.sh
.config/
.kube/
.cf/
.azure/
```

Prefer selective merge over blind copy for machine-specific files — the `.zprofile` on this Mac already has the Homebrew and `nvm` bootstrap added in Phase 8A, and overwriting it would remove those.

### Step 7 — Restore Credentials and License Material

Credential-bearing material stays inside the DMG until the moment it is needed. Restore only through supported flows:

Typical sources on the mounted volume:

```text
/Volumes/all-secrets-*/cli-credentials/    # per-tool credential exports (aws profile files, kube credentials, etc.)
/Volumes/all-secrets-*/package-managers/   # npm, cargo, and similar credential stores
/Volumes/all-secrets-*/licenses/           # app license keys, serial numbers, activation files
```

For each application license or activation file:

1. Use the application vendor's supported import or reactivation flow — not a manual copy of an activation file unless the vendor explicitly documents that path.
2. Keep copied activation files out of Git and OneDrive unless separately approved.
3. Record only redacted restore notes in plain Markdown, under `$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/`.
4. Remove any temporary plaintext copies after the app is activated and validated.

> [!warning] Pitfall
> Screenshots or PDFs of subscription pages that contain private identifiers still count as secret material. They belong under `secrets-encrypted/licenses/`, not under `public-certs/` or a general notes folder.

### Step 8 — Eject the DMG and Clean Up Plaintext

Eject the DMG once every restore that reads from it is done:

```bash
hdiutil detach /Volumes/all-secrets-*
```

Sweep for any temporary plaintext copies you may have made outside the DMG (Downloads, Desktop) and remove them. The DMG is the durable copy; nothing plaintext should remain on disk after this step.

Confirm the exit criteria before moving on to [[restore-git|restore-git.md]]:

| Area | Expected result |
|---|---|
| SSH | `ssh -T git@github.com` prints the expected identity line. |
| Git config | `git config --global user.email` returns the intended identity. |
| Keychain trust | Internal root and issuing CAs are marked Always Trust in the login keychain. |
| Java trust | `jssecacerts` is present under `$JAVA_HOME/lib/security/`, and an internal TLS smoke test succeeds. |
| Shell config | `.zprofile` retains the Homebrew and `nvm` bootstrap from Phase 8A; adopted files were reviewed, not blindly copied. |
| Credentials and licenses | Each application in scope is activated through its supported flow; no plaintext activation files remain on disk outside the DMG. |
| DMG | Detached from `/Volumes/`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The commands do X; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Whether a certificate imported in Step 3 should be marked Always Trust. | Requires knowing whether it is a genuine internal root/issuing CA; incorrect trust weakens the whole TLS story. |
| Whether the SSH keys on the DMG are the current identity or a rotated-out prior identity. | Depends on rotation history that the DMG does not carry. If unsure, generate a new key and register it upstream rather than restoring an old one. |
| Which lines of a captured `.zshrc` or `.zprofile` should be adopted verbatim versus merged with the fresh file. | The fresh file already has Phase 8A's Homebrew and `nvm` bootstrap; the captured file may have machine-specific tweaks that no longer apply. |
| Whether an activation file should be reused, or the vendor's normal sign-in and reactivation flow used instead. | Some vendors invalidate copied activation files on new hardware; only you know per-app policy. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### `hdiutil attach` says the DMG is corrupt

Verify the DMG on disk before assuming it is unrecoverable:

```bash
hdiutil verify "$DMG"
```

If verification fails, fall back to the previous timestamped `all-secrets-*.dmg` in the same directory. If both fail, rebuild via [[create-secrets-dmg|create-secrets-dmg.md]] on the source machine — this runbook does not repair DMGs.

### SSH keeps prompting for a passphrase every session

The keys are correct but not added to the ssh-agent. Add them once per session:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

For persistence, add an `AddKeysToAgent` directive to `~/.ssh/config`; that is a shell config change, not a Step 2 fix.

### `curl` still fails against internal endpoints after Step 4

The certificate was imported but Always Trust was set on the *end-entity* certificate rather than the root or issuing CA. Only root and issuing CAs earn Always Trust; leaf certs should stay at "Use System Defaults" and rely on the chain.

[[#Table of Contents|⬆ Back to Table of Contents]]
