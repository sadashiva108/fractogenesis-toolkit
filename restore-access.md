[[reimaging-guide#Phase 10B — Restore Access|← Back to Mac Reimaging Guide]]

# Restore Access

**Last updated:** 2026-08-31

Restore the identity, trust, and credential layer on the reimaged Mac after the runtime toolchain is in place — SSH keys and Git access, certificates and keychains, Java trust overrides pinned to the JDK from Phase 10A, shell and CLI configuration, and license or activation material. Everything here comes out of the encrypted secrets DMG and the reviewed dotfiles bundle built during the pre-image phases. Most of it is manual — small copies, `security` commands, and Keychain Access actions — but four steps are scripted: Step 0 and the closing step run the boundary recorders in `bin/`, Step 2 runs `bin/restore-staged-loose.sh`, and `bin/restore-access.sh` can drive the whole phase.

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
    - [[#Step 0 — Record Prerequisites and the Before-State|Step 0 — Record Prerequisites and the Before-State]]
    - [[#Step 1 — Mount the Encrypted Secrets DMG|Step 1 — Mount the Encrypted Secrets DMG]]
    - [[#Step 2 — Restore Files Swept by the Phase 3B Loose-Secret Sweep|Step 2 — Restore Files Swept by the Phase 3B Loose-Secret Sweep]]
    - [[#Step 3 — Restore SSH and Git Access|Step 3 — Restore SSH and Git Access]]
    - [[#Step 4 — Restore Certificates and Keychain Material|Step 4 — Restore Certificates and Keychain Material]]
    - [[#Step 5 — Trust the Internal Root Certificate|Step 5 — Trust the Internal Root Certificate]]
    - [[#Step 6 — Restore Java Trust Overrides|Step 6 — Restore Java Trust Overrides]]
    - [[#Step 7 — Trust the Corporate CA Outside the Keychain|Step 7 — Trust the Corporate CA Outside the Keychain]]
    - [[#Step 8 — Restore Shell Environment and CLI Config|Step 8 — Restore Shell Environment and CLI Config]]
    - [[#Step 9 — Restore Credentials and License Material|Step 9 — Restore Credentials and License Material]]
    - [[#Step 10 — Eject the DMG and Clean Up Plaintext|Step 10 — Eject the DMG and Clean Up Plaintext]]
    - [[#Step 11 — Compare Restored State Against Captured Inventories|Step 11 — Compare Restored State Against Captured Inventories]]
    - [[#Step 12 — Close Out the Exit Criteria|Step 12 — Close Out the Exit Criteria]]
- [[#DMG Categories Restored By Hand|DMG Categories Restored By Hand]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Restore the access layer that later repo, IDE, application, and project work depend on: SSH identity, TLS trust, JVM trust, shell environment, and credential and license material. Get the Mac to the point where it can authenticate to internal systems and reach services through the expected trust chain before Git restore and application restore start.

**What it sets up**

- **SSH identity** — keys, `~/.ssh/config`, and `known_hosts` copied out of the mounted DMG, with the tight permissions the SSH client insists on.
- **Keychain trust** — certificates imported from the reviewed manual exports, with genuine internal root and issuing CAs explicitly marked Always Trust so non-Java tools reach internal endpoints.
- **JVM trust** — the `jssecacerts` override dropped into the `lib/security/` directory of the JDK actually installed in Phase 10A.
- **Shell and CLI configuration** — a reviewed, selectively merged restore from the dotfiles bundle, rather than a blanket overwrite of the fresh files.
- **Credentials and license material** — per-tool credential exports, package-manager credential stores, and license or activation material brought back through each vendor's supported flow.

**What the rest of the workflow relies on it for**

- Phase 11A builds the Git identity plumbing on top of the SSH keys and permissions laid down here.
- Phase 11B and later repo, IDE, and project work reach internal systems through the keychain and JVM trust this phase establishes.
- Phase 12 application restore assumes the license and activation material is already in hand and the machine can authenticate.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| mounting the encrypted secrets DMG and ejecting it cleanly | building and validating that DMG — `create-secrets-dmg` (Phase 3C) |
| SSH keys, `~/.ssh/config`, and their permissions | Git identity configuration and remote routing — `restore-git` (Phase 11A) |
| certificates and keychain material restored from reviewed sources | certificate and Keychain discovery, review, and staging — `stage-certs-keychain` (Phase 3A) |
| Java trust overrides such as `jssecacerts`, pinned to the installed JDK | runtime tooling install — Xcode CLT, Homebrew, JDK, Node, platform CLIs — `restore-runtime` (Phase 10A) |
| selective shell and CLI configuration restore from the dotfiles bundle | capturing that reviewed dotfiles bundle — `backup-home` (Phase 2B) |
| credentials, license keys, and activation material | IntelliJ, Docker, and per-app secret restore — `restore-intellij`, `restore-docker`, and the app-specific runbooks (Phase 12) |

This runbook can be rerun. Each step is either idempotent (SSH file copies, chmod, `security` imports) or a manual UI action; rerunning is the intended recovery path when a step misbehaves.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The order in this phase is not preference — it enforces a trust chain. SSH has to be in place before anything tries to reach GitHub. Certificates in the login and system keychains have to be trusted before non-Java tools (curl, git, browsers) can reach internal endpoints. The `jssecacerts` Java trust override has to be dropped into the *actual* installed JDK from Phase 10A, not a JDK that isn't there yet, which is why runtime restore precedes access restore at the phase level. Shell and CLI configuration is restored last of the identity-adjacent material because it can reference paths (`JAVA_HOME`, `NVM_DIR`) that the earlier phases just put in place; restoring dotfiles before that would risk sourcing profile files that reference tools not yet installed.

The restores themselves are manual by design. Every one is a small copy, `security` command, or Keychain Access GUI action, and each carries a judgment call — is this key still the current one, should this cert really be Always Trust, does this dotfile still match how the machine is used — that a script cannot make. The encrypted DMG built in Phase 3C is the single source of truth for the secret-bearing material; the reviewed dotfiles bundle from Phase 2B is the single source of truth for shell and CLI config.

### Terminology

| Term | Meaning |
|---|---|
| Secrets DMG | The consolidated encrypted disk image built by `create-secrets-dmg.md` in Phase 3C. Named `all-secrets-*.dmg` and stored under `secrets-encrypted/`. |
| Dotfiles bundle | The reviewed shell and CLI config subset captured by `backup-home.md` and stored under `home-files-backup/dotfiles/`. Not encrypted; contains no secrets by design. |
| `jssecacerts` | A per-JDK Java trust override file. Copied into `$JAVA_HOME/lib/security/` and read by the JVM in addition to the default trust store. Must match the installed JDK. |
| Always Trust | A macOS Keychain trust setting that marks a certificate as valid for every use case. Correct only for genuine internal root or issuing CAs; a mistake for anything else. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path this runbook reads or writes is defined here, once.

Scripts this runbook runs:

```text
$FRACTOGENESIS_HOME/bin/restore-access.sh          # entrypoint — drives Steps 0–12; every step is also a subcommand
$FRACTOGENESIS_HOME/bin/record-restore-prereqs.sh  # entrypoint — Step 0a, entry boundary
$FRACTOGENESIS_HOME/bin/record-restore-state.sh    # entrypoint — Step 0b before-state, Step 11 after-state
$FRACTOGENESIS_HOME/bin/restore-staged-loose.sh    # entrypoint — Step 2, inverse of bin/stage-loose-secrets.sh
$FRACTOGENESIS_HOME/bin/compare-restored-state.sh  # entrypoint — Step 11, both baselines
$FRACTOGENESIS_HOME/bin/record-restore-exit.sh     # entrypoint — Step 12, exit boundary
```

Input evidence built by earlier phases:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-*.dmg              # Phase 3C output — mounted read-only
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/                         # certificate staging, mirrored inside the DMG
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/java-security/           # jssecacerts and related JDK trust files
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/keychain-manual-exports/ # manual .cer/.p12 exports for Keychain Access
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/loose-candidates-selected/ # reviewed loose cert/key material staged in Phase 3A
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/cli-credentials/               # per-tool credential exports
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/ssh/                           # SSH keys, config, known_hosts — read by Step 3
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/staged-loose/                  # Phase 3B sweep + MANIFEST.tsv — read by Step 2
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/chrome/                        # break-glass password CSV — see DMG Categories Restored By Hand
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/claude/                        # restored by hand
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/claude-code/                   # restored by hand
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker/                        # restored by restore-docker.md (Phase 12)
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/extra-secrets-certs-review/    # Phase 3A review leftovers
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/gnupg/                         # restored by hand
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/intellij/                      # restored by restore-intellij.md (Phase 12)
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/kube/                          # restored by hand
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/                       # restored by hand, through Raycast's own import
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/repos-gitignored/              # restored by restore-repos.md (Phase 11B)
$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/                      # reviewed shell/CLI config subset
$REIMAGE_ARTIFACT_ROOT/public-certs/                                    # reviewed non-secret CA and trust reference material
```

> [!note]
> That list is the image's fourteen categories, and it is authoritative because
> it comes from the image itself. Confirm yours without the DMG password:
>
> ```bash
> cat "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/"all-secrets-*-categories.txt
> ```
>
> The list is what *this* image happens to carry, not the full scheme.
> `git/`, `licenses/` and `package-managers/` are real categories that
> `create-secrets-dmg.sh` stages **only when there is applicable material** — no
> `~/.git-credentials`, no `.npmrc` worth keeping, no locally-exported license
> file, and the category simply is not created. Absent here does not mean
> unsupported, and a future image may well carry all three.
>
> `cloud/` (AWS) is the one that is excluded by design rather than by
> circumstance: cloud CLIs are re-authenticated after a reimage rather than
> restored, so the category is never staged. See
> [[create-secrets-dmg#What Gets Staged|create-secrets-dmg → What Gets Staged]].
>
> Note that `git/` is about credentials — `~/.git-credentials` and helper cache.
> `~/.gitconfig` is not a credential; it is in `home-files-backup/dotfiles/` and
> Phase 11A restores it. The two are easy to conflate and live in different
> places.

Artifacts this phase generates, all under `$REIMAGE_ARTIFACT_ROOT/reimaged-system/`:

```text
boundaries/MANIFEST.md                                           # index of every entry and exit run
boundaries/official/restore-access-entry.txt                     # newest entry run
boundaries/official/restore-access-exit.txt                      # newest exit run
boundaries/runs/restore-access-entry-YYYYMMDD-HHMMSS/            # Step 0a — checklist.md
boundaries/runs/restore-access-exit-YYYYMMDD-HHMMSS/             # Step 12 — checklist.md

state/MANIFEST.md                                                # index of every state capture
state/official/restore-access-before.txt                         # FIRST before run — first-wins
state/official/restore-access-after.txt                          # newest after run — latest-wins
state/runs/restore-access-before-YYYYMMDD-HHMMSS/                # Step 0b — state.tsv, state.md
state/runs/restore-access-after-YYYYMMDD-HHMMSS/                 # Step 11 — state.tsv, state.md
state/official/restore-access-delta.txt                          # newest delta
state/runs/restore-access-delta-YYYYMMDD-HHMMSS/                 # Step 11 — delta.md, before vs after

comparisons/MANIFEST.md                                          # index of every comparison
comparisons/official/restore-access-inventory-diff.txt           # newest inventory diff
comparisons/runs/restore-access-inventory-diff-YYYYMMDD-HHMMSS/  # Step 11 — comparison.md, vs the pre-image captures

restore-notes/                                                   # Step 9 — redacted activation notes, written by hand
```

There are no `latest-*.txt` pointers and no `prereq-checks/`, `exit-checks/` or
`restore-targets/` directories. Each category carries an append-only
`MANIFEST.md` and one computed `official/<context>.txt` per lineage, because a
single "latest" pointer cannot name several lineages at once — entry and exit,
or before and after, are different questions and each needs its own answer.

Step 2 also writes back into the plaintext artifact tree — `home-files-backup/`, `app-settings-backup/`, and `staged-ignored-files/` — restoring the files Phase 3B moved out. Those are not new artifacts; they are holes being refilled at their original paths.

Live targets this runbook writes on the reimaged Mac. Each names the step that writes it, because the `state/` captures above are only interpretable against this list — and `bin/record-restore-state.sh` walks exactly these paths:

```text
~/.ssh/                              # Step 3 — keys, config, known_hosts
~/.gitconfig                         # NOT written here — Phase 11A restores it; Step 7 may add http.sslCAInfo
~/.config/git/                       # NOT written here — Phase 11A restores it
~/Library/Keychains/                 # Steps 4-5 — imported certificates, login keychain trust settings
/Library/Keychains/System.keychain   # Step 5 — only if the system-domain trust form is used
$JAVA_HOME/lib/security/             # Step 6 — jssecacerts override, pinned to the Phase 10A JDK
~/.certs/                            # Step 7 — corp-root.pem, the CA bundle non-keychain tools read
~/.npmrc                             # Step 7 — npm config set cafile
~/.config/pip/pip.conf               # Step 7 — pip config set global.cert
~/.zprofile                          # Step 7 appends five CA exports; Step 8 may then merge over it
~/.zshrc, ~/.bash_profile, ~/.bashrc, ~/.shell_common.sh, ~/.shell_local.sh   # Step 8 — selective merge
~/.config/, ~/.kube/, ~/.cf/, ~/.azure/                                       # Step 8 — selective merge
```

The complete `secrets-encrypted/` layout is defined once in the Master Directory Reference, not redrawn here:

[[master-directory-reference|Master Directory Reference]]

---
### Environment Variables

The values this runbook depends on. `REIMAGE_ARTIFACT_ROOT` is resolved and written during `prepare-artifact-root.md`; `JAVA_HOME` is not a `reimage.env` value and is set by Step 6 from `/usr/libexec/java_home`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Artifact root for this reimage event; the mounted DMG, the dotfiles bundle, and `public-certs/` all resolve under it. |
| `JAVA_HOME` | Set explicitly in Step 6 to the JDK installed in Phase 10A before dropping in `jssecacerts`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the toolkit root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 10A (`restore-runtime.md`) is complete: the intended JDK baseline is installed and `java -version` prints it. If several JDKs are present, `REIMAGE_JDK_BASELINE` in `reimage.env` decides which one Step 6 writes the trust override into.
- The external artifact volume is mounted and `reimage.env` resolves. `ls "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"` should list at least one `all-secrets-*.dmg`.
- You have the DMG password from your password manager or wherever it was stored in Phase 3C. Do not proceed without it.

> [!bug] Troubleshooting
> `hdiutil attach` failing with "authentication error" almost always means the wrong password. If the password is correct, verify the DMG isn't already mounted (`hdiutil info | grep all-secrets`) — a leftover mount from an earlier attempt will refuse a second attach.

### Confirm Your Intent

- Are you doing a **full first-time restore** (Steps 1 through 10 in order) or a **targeted rerun** of one area (for example, just re-importing a certificate that was missed)? Both are safe; the difference is whether you also do Step 8's selective shell restore.
- Which **shell files** are you willing to overwrite versus merge? The default is *merge* — comparing each file in a diff tool before adopting changes. Blanket overwrites are a common way to lose machine-specific tweaks.
- Which **secret categories** are actually in scope for this restore? If a category is empty on the DMG (say, no Postman exports were taken), skip its step rather than inventing a source.
- **How will Step 6 restore the JVM trust store?** `jssecacerts` replaces `cacerts` rather than adding to it, so this is a decision about the JDK's whole trust set and not just the corporate CA. Two forms, decided by how old the capture is:

| | What it does | Choose it when |
|---|---|---|
| **A — copy the captured store** | Drops the old machine's `jssecacerts` into the new JDK wholesale. One command. | The capture is recent — same week, same month. The public-root set has not moved meaningfully. |
| **B — fresh `cacerts` + only the additions** | Copies this JDK's current `cacerts`, then imports just the aliases the capture added. Several commands. | The capture is months old, or you do not know how old. Keeps the new JDK's public roots current. |

  Step 6 prints exactly what the capture adds over the fresh store, so you can
  decide there if you would rather see the list first. The reason to think about
  it now: **A is one command and B is several**, and discovering that halfway
  through Step 6 is how A gets chosen by momentum rather than on the merits.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The order enforces a trust chain: SSH before Git access, keychain trust before Java trust, JDK trust before shell restore, credentials last of the identity-adjacent material, DMG eject last of all.

### Step 0 — Record Prerequisites and the Before-State

Two recordings, both taken before anything is mounted or written. They answer
different questions and only one of them can be taken late.

**0a — may this phase start?** Writes a checklist under
`reimaged-system/boundaries/` and exits non-zero only on `FAIL`.

```bash
bash bin/record-restore-prereqs.sh --runbook restore-access --dry-run
bash bin/record-restore-prereqs.sh --runbook restore-access
```

**0b — what is on disk right now?** Writes a run under
`reimaged-system/state/` recording every path this phase will touch, as it
stands before the phase touches it.

```bash
./bin/record-restore-state.sh --runbook restore-access --point before --dry-run
./bin/record-restore-state.sh --runbook restore-access --point before
```

> [!note]
> Every block in this runbook shows a `--dry-run` line above the real one. It
> prints the table and writes nothing. On **0b** that preview is worth more than
> anywhere else: `before` is a first-wins point, so the first capture recorded is
> the one that stays official, and a mistimed one cannot be replaced — only
> annotated with a pin explaining why it is wrong. Read the target list, confirm
> it describes a machine the phase has not touched, then record.

> [!warning] Pitfall
> **0b expires and 0a does not.** The prerequisite check is rerunnable at any
> point and costs nothing to repeat. The before-state is gone the moment Step 1
> mounts the image and Step 3 writes `~/.ssh` — and because `before` is a
> first-wins point, a capture taken afterwards becomes permanently official
> while describing a machine the phase has already changed. The diff it produces
> reads "nothing changed", which is worse than no diff at all.
>
> Phase 10A has no before-state for exactly this reason, which is why its
> version-drift review had to be reconstructed from a cross-erase comparison
> instead of a within-phase one.
>
> If you have already started the phase, still run it — the certificate, JVM
> trust, CA bundle and shell-config targets are untouched until Steps 4-9 — but
> note in the run that Steps 1-3 preceded it, or pin it with a reason.

Most targets will read `absent`. That is correct: this phase is what creates
them, and the point of recording it is so the after-state has something to
differ from. `$JAVA_HOME/lib/security/` should read `unresolved` rather than
`absent` — `JAVA_HOME` is set by Step 6, so an empty one here is the expected
state and "nothing was checked" is the honest answer.

| Row | Why it is checked |
|---|---|
| Java resolves via `java_home` | `FAIL`. The only row here that fails **silently** — see below. |
| Toolkit root resolves | `FAIL`. Nothing in this phase works without it. |
| Secrets DMG present | `FAIL`. Step 1 has nothing to mount. |
| direnv hooked, `.envrc` allowed | `WARN`. Recoverable, but later phases assume it. |
| DMG categories sidecar present | `WARN`. Lets you see what the image holds without the password. |
| Build and runtime tooling present | `WARN`. A gap blocks a later phase, not this one. |
| Runtime comparison recorded | `WARN`. Evidence that Phase 10A Step 10 ran. |

> [!warning] Pitfall
> The Java row is checked here rather than left to Step 6 because it fails
> invisibly. Step 6 resolves `JAVA_HOME` through `/usr/libexec/java_home`,
> and command substitution swallows a non-zero exit — so `JAVA_HOME` becomes the
> empty string, the next line writes `jssecacerts` to `/lib/security/jssecacerts`,
> which is neither the JDK nor a directory that exists, and the TLS smoke test
> afterwards fails for a reason unrelated to the certificate you just restored.
> Catching it here costs one command; catching it there costs an hour.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 1 — Mount the Encrypted Secrets DMG

Mount the newest DMG read-only-ish; macOS mounts DMGs read-write by default, and that's fine here because the DMG is the source, not a target:

```bash
DMG="$(ls -1 "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/"all-secrets-*.dmg 2>/dev/null | sort | tail -1)"
MNT="$(hdiutil attach "$DMG" | awk -F'\t' '/\/Volumes\//{print $NF}' | tail -1)"
if [ -n "$MNT" ] && [ -d "$MNT" ]; then
  printf 'Mounted at: %s\n' "$MNT"
else
  printf 'MOUNT FAILED. MNT=%s — stop here; do not run any step below.\n' "${MNT:-<empty>}" >&2
fi
```

Enter the password when prompted. Confirm the mount:

```bash
hdiutil info | grep -A1 all-secrets
ls "$MNT"/
```

> [!warning] Pitfall
> The mount point is **not** derived from the `.dmg` filename. It comes from the `-volname` passed to `hdiutil create` back in Phase 3C, and the two need not match — so `/Volumes/all-secrets-*` can glob to nothing on a perfectly good image. Capture `$MNT` here and use it in every step below, including the detach in Step 10: if that glob fails, the command silently does nothing and the plaintext secrets stay mounted.

> [!warning] Pitfall
> `MNT="$(hdiutil attach …)"` is the same command-substitution swallow that Step 0's Java row exists to catch. A wrong password, an already-attached image, or a corrupt DMG all exit non-zero, `awk` prints nothing, and `MNT` becomes the **empty string** — which a bare `echo "$MNT"` renders as a blank line that looks like output. Every step below then runs against `/`: Step 3 copies from `/ssh/*`, Step 5 reads `/certs/…`, and Step 10 runs `hdiutil detach ""`. The guard above is why the mount prints a labelled path rather than a bare one.

Every subsequent step reads from `"$MNT"`; do not copy the DMG's contents wholesale to disk.

`$MNT` lives only in the shell that ran the attach. If you continue in a new terminal, re-derive it from a directory the image always carries rather than from the filename:

```bash
MNT=""
for d in /Volumes/*/staged-loose; do
  [ -f "$d/MANIFEST.tsv" ] && MNT="$(dirname "$d")"
done
if [ -n "$MNT" ] && [ -d "$MNT" ]; then
  printf 'Re-derived mount: %s\n' "$MNT"
else
  printf 'No mounted secrets image found. Re-attach with the block above.\n' >&2
fi
```

> [!warning] Pitfall
> The obvious one-liner for this — `MNT="$(dirname "$(ls -1d /Volumes/*/staged-loose | tail -1)")"` — fails into a value that looks valid. No match means `ls` errors, the inner substitution is empty, and **`dirname ""` returns `.`**, so `$MNT` silently becomes your current directory and every later `"$MNT"/ssh/*` reads out of the toolkit checkout. The loop above also tests for `MANIFEST.tsv` rather than the bare directory, matching how `bin/restore-staged-loose.sh` finds the same image.

> [!bug] Troubleshooting
> If `hdiutil attach` reports the image as corrupt, see [[#`hdiutil attach` says the DMG is corrupt|`hdiutil attach` says the DMG is corrupt]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Restore Files Swept by the Phase 3B Loose-Secret Sweep

Phase 3B **moved** every credential-shaped file out of the plaintext artifact tree into `secrets-encrypted/staged-loose/` so the DMG could encrypt it. Nothing puts those files back automatically. Until this step runs, `home-files-backup/`, `app-settings-backup/`, and `staged-ignored-files/` all have holes in them — and the later phases that read those trees (Step 8 below, `restore-apps.md` in Phase 12, `restore-home.md` in Phase 15) will silently restore an incomplete set.

Run it now, while the DMG from Step 1 is still attached and before anything reads those trees.

**1. Dry run first — nothing is written:**

```bash
./bin/restore-staged-loose.sh
```

The script finds the mounted image by looking for `/Volumes/*/staged-loose/MANIFEST.tsv` rather than globbing the DMG's filename, because the volume name comes from `-volname` at build time and need not match. If Step 1 gave you an explicit mount point, pass it:

```bash
./bin/restore-staged-loose.sh --source "$MNT/staged-loose"
```

**2. Read the `WOULD` list, then apply:**

```bash
./bin/restore-staged-loose.sh --apply
```

Each row is copied back to the artifact-root-relative path recorded in the manifest's source column — so the artifact tree is rehydrated, and the ordinary restore phases then copy from it into `$HOME` exactly as they always would.

**3. Confirm the count:**

```bash
./bin/restore-staged-loose.sh
```

A second run should report every row as `EXISTS` and `Would restore: 0`. The script copies rather than moves, so it is safe to repeat.

> [!note]
> `MISSING` rows are recorded in the manifest but absent from the image. That means the DMG predates the sweep that wrote those rows — check you attached the newest `all-secrets-*.dmg`, not an earlier one.

> [!warning] Pitfall
> This deliberately puts plaintext credentials back onto the artifact drive. That is required for the restore to be complete, but the drive is no longer clean afterwards. Before the artifact root is retired, handed to anyone, or stored long-term, re-run `./bin/stage-loose-secrets.sh --apply` to sweep them back behind the encryption boundary — or wipe the drive.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Restore SSH and Git Access

SSH first because everything else that talks to GitHub or an internal Git server needs it.

Copy the SSH material into place:

```bash
mkdir -p ~/.ssh
cp -R "$MNT"/ssh/* ~/.ssh/
```

> [!note]
> Only SSH material comes out of the image here. `~/.gitconfig` and
> `~/.config/git/` are **not** in it — they are not credentials, so Phase 3A
> never staged them. They live in the reviewed dotfiles bundle at
> `$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/`, and restoring them is
> Phase 11A's job per the Ownership table above. The image carries no `git/`
> category and never has, so copying one out of it fails with *"No such file or
> directory"* — which reads like a missing capture rather than a category that
> was never built. Confirm what yours holds without the password:
>
> ```bash
> cat "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/"all-secrets-*-categories.txt
> ```

Fix permissions — the SSH client refuses to use loose keys:

```bash
chmod 700 ~/.ssh
find ~/.ssh -type f -exec chmod 600 {} \;
```

Confirm the SSH identity works — against the **host alias you actually use**,
not against `github.com`. The dual-identity routing `restore-git.md` sets up in
Phase 11A works through aliases, so on a machine that follows that convention
there may be no `Host github.com` block at all, and a bare `github.com` test
offers no key.

List what the restored config defines, then test each alias you rely on:

```bash
grep -E '^Host ' ~/.ssh/config
```

The image restores more keys than the machine still uses. Nothing deletes a key
that was rotated out, so what comes back is every key you have ever had rather
than the set that still authenticates. Three facts separate them: the
**fingerprint**, which is what you compare against each account's registered
keys; whether `~/.ssh/config` **names** it, which is the best evidence of what
the previous machine actually used; and whether it carries a **passphrase**.

```bash
find "$HOME/.ssh" -maxdepth 1 -name '*.pub' -type f | sort | while IFS= read -r pub; do
  key="${pub%.pub}"
  ref="not in config"
  grep -qF "$(basename "$key")" "$HOME/.ssh/config" 2>/dev/null && ref="in config"
  pass="passphrase required"
  ssh-keygen -y -f "$key" </dev/null >/dev/null 2>&1 && pass="no passphrase"
  printf '%s  [%s, %s]\n  %s\n' "$(basename "$key")" "$ref" "$pass" "$(ssh-keygen -lf "$pub")"
done
```

Two details in that block are load-bearing. It iterates `find` output rather than
a `*.pub` glob because an unmatched glob in **zsh** is an error that aborts the
line — the `[ -e "$f" ] || continue` idiom is a Bash habit that never gets to run
here, and this runbook is pasted into interactive zsh. And the `</dev/null` is
what makes the passphrase test non-interactive: `ssh-keygen -y` prompts when a
key is encrypted, so with no stdin it fails immediately instead of stopping the
loop at the first protected key. A key reported as needing a passphrase you no
longer have is replaceable without the old one — see
[[#`ssh -T` fails after the keys are restored|`ssh -T` fails after the keys are restored]].

A key marked `not in config` is a candidate for retirement, not a defect. It may
still be authorized on an account, a server, or an `authorized_keys` file
somewhere, so check its fingerprint against everything it might reach before
deleting anything — unreferenced locally and unregistered remotely are different
claims. For the keys that *are* referenced, compare each fingerprint against what
that account has registered. [[restore-git|restore-git.md]] Step 2 repeats that
comparison for the two keys `reimage.env` names; this is the wider inventory that
tells you which two those should be.

```bash
GIT_ALIAS="paste-an-alias-from-the-list-above"
ssh -T "git@$GIT_ALIAS" || true
```

> [!bug] Troubleshooting
> `ssh -T` failing here has three unrelated causes that look alike — an absent
> key, a host with no `IdentityFile`, and a network that cannot carry the
> protocol. See [[#`ssh -T` fails after the keys are restored|`ssh -T` fails after the keys are restored]].

> [!note]
> The full Git identity workflow (work vs personal routing, per-repo `.gitconfig`, dual-identity `~/.gitconfig`) belongs to [[restore-git|restore-git.md]] in Phase 11A. This step is only about SSH reachability.

> [!bug] Troubleshooting
> If SSH prompts for the key passphrase in every new shell, see [[#SSH keeps prompting for a passphrase every session|SSH keeps prompting for a passphrase every session]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Restore Certificates and Keychain Material

**First ask the machine, not the image.** On a managed Mac, enrolment in Phase 8
usually installs the corporate CA chain through a configuration profile, so some
or all of what this step would import is already present before you start. The
step is scoped to the *gap*, and you cannot see the gap without looking at both
sides.

```bash
security find-certificate -a -Z 2>/dev/null | grep -E '^SHA-256 hash:|"(labl|alis)"'
```

That prints every certificate in your keychains as a hash followed by its label.
Read it against the listing below and import only what is genuinely missing.
Importing a certificate that is already installed is not harmful, but it hides
the more useful fact — that enrolment already did the work, and a missing cert
therefore means enrolment did *not*, which is a different problem with a
different fix.

> [!note]
> Presence is not trust. A certificate can be installed and carry no trust
> settings at all. Step 5 is about the second thing, and these are what it reads:
>
> ```bash
> security dump-trust-settings 2>/dev/null; echo "--- admin domain ---"; security dump-trust-settings -d 2>/dev/null
> ```
>
> If enrolment delivered the chain through a profile, trust may already be set
> and Step 5 becomes a verification rather than an action.

**Then see what the image carries.** Phase 3A stages certificates into more than one place, and which of them holds the corporate root depends on how it was captured:

```bash
ls -R "$MNT/certs"
```

> [!warning] Pitfall
> `keychain-manual-exports/` holds a `.p12` only when a Keychain identity was **exportable**, and on a managed Mac many are not — the export refuses with *"The contents of this item cannot be retrieved."* Where that happened, the directory holds Phase 3A's review notes and no certificate, and the reviewed cert material sits under `loose-candidates-selected/` instead. This is why the listing above decides where to look rather than the step naming a file: an assumed `root-ca.cer` fails with "No such file or directory" and reads like a missing file rather than a wrong assumption. Phase 3A's notes in that directory record which identities refused and why. Non-exportable identities are re-issued by re-enrolment; no backup can restore them.

**Identify every candidate before importing any of them.** A directory of
`.pem` and `.cer` files tells you nothing about which are certificate
authorities and which are leaf certificates, and the names actively mislead —
`<org>-cert.pem` sitting beside `<org>-issuing-ca.pem` and `root-<org>-ca.pem`
is a leaf in CA company.

```bash
for f in "$MNT"/certs/loose-candidates-selected/*; do b=$(basename "$f"); for form in PEM DER; do if openssl x509 -in "$f" -inform $form -noout >/dev/null 2>&1; then printf '\n%s\n' "$b"; openssl x509 -in "$f" -inform $form -noout -subject -issuer | sed 's/^/   /'; printf '   sha256=%s\n' "$(openssl x509 -in "$f" -inform $form -noout -fingerprint -sha256 | sed 's/.*=//')"; printf '   %s\n' "$(openssl x509 -in "$f" -inform $form -noout -text | grep -A1 'Basic Constraints' | tail -1 | sed 's/^ *//')"; break; fi; done; done
```

Three things come out of that, and each decides something:

| Field | What it settles |
|---|---|
| `CA:TRUE` / `CA:FALSE` | Whether it is an authority at all. `CA:FALSE` is a **leaf** — never mark it Always Trust in Step 5. |
| `subject` = `issuer` | Self-signed, so it is a **root**. Differing means it is an issuing/intermediate CA. |
| `sha256` | Its identity. Compare against the keychain listing above — **match on this, never on the label**, since the same CA is routinely filed under different names in different places. |

> [!warning] Pitfall
> A leaf certificate in this directory is usually the *old machine's* client
> identity, swept up by Phase 3A because it was credential-shaped. Re-enrolment
> issues a new one, so restoring the old is at best inert and at worst confusing
> later — two client certs for the same subject, one of them dead. Marking one
> Always Trust is worse: it tells the system to trust a single endpoint's
> certificate as though it were an authority. The exit checklist asks you to
> confirm you did not, which is too late to be the only place it is said.

Pin the corporate root once, from whatever the listings above showed, and reuse it in Steps 5 and 7:

```bash
CORP_CERT="$MNT/certs/<subdirectory>/<filename>"
ls -l "$CORP_CERT" && openssl x509 -in "$CORP_CERT" -inform PEM -noout -subject -issuer -dates 2>/dev/null \
  || openssl x509 -in "$CORP_CERT" -inform DER -noout -subject -issuer -dates
```

One of the two `openssl` forms prints a subject, issuer, and validity window; the other errors. Note which one worked — Step 7 needs the format. If neither prints, the file is not a certificate.

Then import **only what the keychain listing showed was missing** — matched by
`sha256`, and only files that reported `CA:TRUE`. Open the folder in Finder and
drag each one into the target keychain (usually `login`), entering the password
if prompted:

```bash
open "$MNT/certs"
```

Reference the reviewed non-secret material under `$REIMAGE_ARTIFACT_ROOT/public-certs/` if you need to check which cert is which.

> [!note]
> `open -a "Keychain Access" <directory>` does not work — Keychain Access opens certificate *files*, not folders. Use plain `open` to reveal the directory in Finder, then drag.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Trust the Internal Root Certificate

`jssecacerts` in the next step only covers JVM tools. Non-Java tools (curl, git, browsers) rely on the macOS keychain trust settings instead, so the internal **root** needs its trust set explicitly.

**An intermediate does not, and should not get one.** A root is a *trust anchor*: nothing above it vouches for it, so trust has to be asserted directly. An issuing or intermediate CA is vouched for by the root, and once the root is trusted the chain validates by itself.

Giving an intermediate its own Always Trust makes it a second, independent anchor. If the organisation later revokes or replaces the root, that intermediate stays trusted regardless — and intermediates rotate far more often than roots, so the override goes stale and starts bypassing the chain it was meant to follow.

**Check what is already there before changing anything.** On a managed Mac, enrolment in Phase 8 commonly configures this, and the step becomes a verification:

```bash
security dump-trust-settings 2>/dev/null; echo "--- admin domain ---"; security dump-trust-settings -d 2>/dev/null
```

Then open each certificate in Keychain Access and expand **Trust**. This is the end state to confirm:

| Certificate | *When using this certificate* | Header line |
|---|---|---|
| internal **root** (subject = issuer) | `Always Trust` | "marked as trusted for this account" |
| internal **intermediate** (subject ≠ issuer) | `Use System Defaults`, no per-policy values | "This certificate is valid" |

If both already read that way, **this step is done.** Record it and move on — there is nothing to change and changing it makes things worse.

```bash
open -a "Keychain Access"
```

Only if the root is *not* yet trusted:

1. Find the internal **root** in the `login` or `System` keychain.
2. Double-click it and expand the **Trust** section.
3. Set **When using this certificate** to **Always Trust**.
4. Close the window and enter your password to save.

Leave every intermediate at `Use System Defaults`.

> [!bug] Troubleshooting
> If an intermediate reads anything other than *"This certificate is valid"*, the problem is **above** it — the root is missing, or is present but not trusted. Fix the root and re-open the intermediate; it should go valid on its own. Do not resolve it by trusting the intermediate, which hides a broken chain rather than repairing one.

CLI equivalent, if you prefer to script the trust change instead of using the GUI. Pick **one** of the two forms below — they target different trust domains and must not be combined.

**1. User domain (login keychain, no root needed)** — trusts the CA for your account only. This is the form to use here:

```bash
ls -l "$CORP_CERT"
security add-trusted-cert -r trustRoot -k "$HOME/Library/Keychains/login.keychain-db" "$CORP_CERT"
```

**2. System domain (admin trust, all users)** — the alternative, only if the CA must be trusted machine-wide:

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CORP_CERT"
```

`-d` selects the admin/system trust domain and requires root; it belongs with `/Library/Keychains/System.keychain` and `sudo`, never with your login keychain.

> [!warning] Pitfall
> Two ways this command fails silently or confusingly. First, a wildcard inside double quotes is never expanded by the shell — `"$MNT/certs/.../root-ca.cer"` is a real resolved path, but `"/Volumes/all-secrets-*/certs/.../root-ca.cer"` is a literal string and returns "No such file or directory". Second, mixing `-d` with `-k "$HOME/Library/Keychains/login.keychain-db"` asks for the admin domain while pointing at a user keychain; it errors or writes trust somewhere you did not intend. Resolve the path first (the `ls -l` above), then run exactly one of the two forms.

> [!warning] Pitfall
> **Always Trust belongs to exactly one certificate here: the internal root.** Not an intermediate — see above. Not a leaf, ever: Step 4's `CA:FALSE` check exists to catch those, and marking one Always Trust tells the system to treat a single endpoint's certificate as an authority. And not an unverified certificate of any kind — confirm the `sha256` against something you trust before asserting trust in it. If in doubt, leave it at "Use System Defaults" and revisit; that setting is the safe default precisely because it defers to the chain.

> [!bug] Troubleshooting
> If `curl` still fails against an internal endpoint after the trust change, see [[#`curl` still fails against internal endpoints after Step 5|`curl` still fails against internal endpoints after Step 5]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 6 — Restore Java Trust Overrides

Only restore `jssecacerts` after confirming the target JDK is the one installed in Phase 10A — the file lives inside a specific JDK's `lib/security/` directory and does nothing if it lands next to a different JDK.

Pin `JAVA_HOME` explicitly, and stop if it does not resolve:

```bash
if [ -n "${REIMAGE_JDK_BASELINE:-}" ]; then
  JAVA_HOME="$(/usr/libexec/java_home -v "$REIMAGE_JDK_BASELINE" 2>/dev/null)"
else
  JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null)"
fi
if [ -n "$JAVA_HOME" ] && [ -d "$JAVA_HOME/lib/security" ]; then
  export JAVA_HOME
  printf 'JAVA_HOME=%s\n' "$JAVA_HOME"
  ls -la "$JAVA_HOME/lib/security"
else
  printf 'No JDK resolved (JAVA_HOME=%s). Stop here.\n' "${JAVA_HOME:-<empty>}" >&2
  printf 'Go back to Phase 10A (restore-runtime.md) and install/link the JDK before continuing.\n' >&2
fi
```

**The image holds one `jssecacerts` per JDK, not one file.** Phase 3A captured
every JDK on the old machine, each under its own label:

```bash
ls -R "$MNT/certs/java-security/"
```

There is no `jssecacerts` at the top of `java-security/` — every store sits one
level down, under the label of the JDK it came from. A path without the label
fails with "No such file or directory", which reads as a missing capture rather
than a wrong path.

Pick the label matching the JDK you just pinned, and verify it against the
inventory sidecar. That sidecar sits beside the image and is readable **without
the DMG password**, so you can confirm the file before trusting it:

```bash
SRC="$MNT/certs/java-security/<label>.jdk/jssecacerts"
shasum -a 256 "$SRC"; grep -F "$(basename "$(dirname "$SRC")")" "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/"java-jssecacerts-inventory-*.md
```

> [!warning] Pitfall
> `jssecacerts` does not *add* to `cacerts` — the JVM uses it **instead of**
> `cacerts` when it exists. Copying a captured file therefore replaces the new
> JDK's entire trust set with the old machine's, public roots included, frozen at
> the date of capture. Over a long enough gap that matters: vendors distrust
> public CAs between releases, and an old store keeps trusting what the new JDK
> deliberately dropped.

Which form to use turns on what the capture actually adds over stock, so list that
first. The two `keytool` runs dump the alias set of each store; `comm -23` prints
the aliases present in the capture but absent from this JDK's `cacerts` — the
certificates the corporate build put there, usually a handful of internal CAs. The
`tee` keeps that list on disk as `/tmp/jss-added.txt`, which form B reads.

```bash
keytool -list -keystore "$SRC" -storepass changeit 2>/dev/null | awk '/trustedCertEntry/{print $1}' | sed 's/,$//' | sort > /tmp/jss-captured.txt
keytool -list -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit 2>/dev/null | awk '/trustedCertEntry/{print $1}' | sed 's/,$//' | sort > /tmp/jss-fresh.txt
comm -23 /tmp/jss-captured.txt /tmp/jss-fresh.txt | tee /tmp/jss-added.txt
```

Then choose one of two forms.

**A — copy the captured store wholesale.** Simplest, and what Phase 3A captured
for. Accepts the old public-root set.

```bash
if [ -d "$JAVA_HOME/lib/security" ] && [ -f "$SRC" ]; then
  cp "$SRC" "$JAVA_HOME/lib/security/jssecacerts"
  ls -l "$JAVA_HOME/lib/security/jssecacerts"
else
  printf 'Refusing to copy: JAVA_HOME=%s / SRC=%s\n' "${JAVA_HOME:-<empty>}" "${SRC:-<empty>}" >&2
fi
```

**B — build a fresh store from this JDK's current `cacerts`, plus only the
additions.** More work, and it keeps the new JDK's public roots current. It starts
from a copy of the stock store and imports one alias per line of
`/tmp/jss-added.txt`:

```bash
cp "$JAVA_HOME/lib/security/cacerts" "$JAVA_HOME/lib/security/jssecacerts"
while IFS= read -r JSS_ALIAS <&3; do
  [ -n "$JSS_ALIAS" ] || continue
  keytool -importkeystore -srckeystore "$SRC" -srcstorepass changeit \
    -destkeystore "$JAVA_HOME/lib/security/jssecacerts" -deststorepass changeit \
    -srcalias "$JSS_ALIAS" -noprompt
done 3< /tmp/jss-added.txt
```

> [!note]
> The loop reads the alias list on file descriptor 3 rather than standard input, so
> a `keytool` run that decides to prompt cannot swallow the remaining aliases and
> end the loop after the first import.

Prefer **B** when the capture is more than a few months old; **A** is fine for a
same-week rebuild.

Depending on how the JDK was installed, `$JAVA_HOME` may be root-owned — if the `cp` reports "Permission denied", rerun that one line with `sudo` and then confirm the file is readable by all (`chmod 644`).

> [!warning] Pitfall
> Do not run `export JAVA_HOME="$(/usr/libexec/java_home ...)"` unguarded. If no matching JDK is installed, `java_home` prints its error to stderr and exits non-zero, `export` still succeeds, and `JAVA_HOME` ends up **empty**. The next `cp` then expands to the absolute path `/lib/security/jssecacerts`, which is not a JDK — it either fails with "No such file or directory" or, under `sudo`, writes a stray trust store at the filesystem root that no JVM ever reads. You would see a clean-looking command and no working Java trust.

> [!note]
> Homebrew's `openjdk@<major>` formulae are keg-only, so `/usr/libexec/java_home` will not see one until it is linked into the system JDK directory. Substitute the major you installed in Phase 10A:
>
> ```bash
> JDK_FORMULA="openjdk@${REIMAGE_JDK_BASELINE:-<major>}"
> sudo ln -sfn "$(brew --prefix "$JDK_FORMULA")/libexec/openjdk.jdk" "/Library/Java/JavaVirtualMachines/${JDK_FORMULA/@/-}.jdk"
> /usr/libexec/java_home -V
> ```

**Validate it.** Two checks, and they answer different things.

First, confirm the JVM can read the store and see how many anchors it holds. A
count near the fresh `cacerts` count plus a handful is right; a count of zero or
a `keytool` error means the file is not a keystore:

```bash
keytool -list -keystore "$JAVA_HOME/lib/security/jssecacerts" -storepass changeit 2>/dev/null | grep -c 'trustedCertEntry'
```

Second, make the JVM actually complete a TLS handshake through it. `curl` will
not do — it reads its own CA bundle, not the JVM's, so it can pass while Java
still fails. This is a single-file Java program, which JDK 11 and later run
directly:

```bash
cat > /tmp/JvmTlsCheck.java <<'EOF'
import java.net.*;
public class JvmTlsCheck {
  public static void main(String[] args) throws Exception {
    URL u = URI.create(args[0]).toURL();
    HttpURLConnection c = (HttpURLConnection) u.openConnection();
    c.setConnectTimeout(10000); c.setReadTimeout(10000); c.setRequestMethod("HEAD");
    System.out.println(u.getHost() + " -> HTTP " + c.getResponseCode());
  }
}
EOF
```

**Choose the host by its issuer, not by its name.** An internal-looking host that
serves a publicly-trusted certificate will pass this test without ever
exercising the corporate root, which is the one thing it is meant to prove.
Three shell variables carry this through, and they are set at different points.
Knowing which is which up front saves a wrong paste:

| Variable | Holds | Example |
|---|---|---|
| `DOMAIN` | Your organisation's **two-label** domain. Optional — only used to narrow a long host list. | `example.com` |
| `CANDIDATE` | **One full hostname** you are checking the issuer of. Reset it and re-run to check the next. | `api.example.com` |
| `INTERNAL_URL` | Derived from the `CANDIDATE` that turned out to be internal. You do not type this one. | `https://api.example.com/` |

Candidates are wherever your tooling already points, and you do not have to
remember where that is. Harvest every HTTPS host named in the reviewed dotfiles
bundle:

```bash
DOTFILES="$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles"
find "$DOTFILES" -maxdepth 5 -type f -size -2M \
  \( -name '*.json' -o -name '*.xml' -o -name '*.properties' -o -name '*.conf' \
     -o -name '*.cfg' -o -name '*.yaml' -o -name '*.yml' -o -name '*.toml' \
     -o -name '.npmrc' -o -name 'config' -o -name '.gitconfig' \) -print0 2>/dev/null \
| xargs -0 grep -ohE 'https://[A-Za-z0-9][A-Za-z0-9.-]+' 2>/dev/null \
| sed 's|https://||' | sort -u > /tmp/tls-hosts.txt
sort -t. -k2 /tmp/tls-hosts.txt
```

That is usually under a dozen hostnames, sorted so related ones sit together —
read it and pick the ones on your organisation's domain. There is deliberately
no filter for "public" hosts: a denylist of well-known vendors goes stale, and it
cannot know that an organisation's internal services live on an ordinary `.com`.
Recognition is the operator's job and takes a second.

If the list is long enough to be awkward, roll it up by registrable domain first
and then narrow. `DOMAIN` is the two-label form — `example.com`, not a URL and
not a full hostname:

```bash
awk -F. 'NF>=2 {print tolower($(NF-1)"."$NF)}' /tmp/tls-hosts.txt | sort | uniq -c | sort -rn | head -15
```

```bash
DOMAIN="example.com"
grep -E "(^|\.)$DOMAIN\$" /tmp/tls-hosts.txt
```

> [!note]
> This searches the **backup**, not the live machine, and that is deliberate:
> at this point in the phase most of the config that names these hosts has not
> been restored yet. Step 8 is what puts `~/.npmrc`, `~/.kube/` and `~/.config/`
> back. The Phase 10B before-state capture will confirm it — those paths read
> `absent` there.

**Now check the issuer.** Take one hostname from the list above — a full
hostname, not the two-label `DOMAIN` — put it in `CANDIDATE`, and ask its server
which CA signed its certificate:

```bash
CANDIDATE="api.example.com"
if CANDIDATE_ISSUER="$(echo | openssl s_client -connect "$CANDIDATE:443" -servername "$CANDIDATE" 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null)"; then
  printf 'RESPONDED  %s\n           %s\n' "$CANDIDATE" "$CANDIDATE_ISSUER"
else
  printf 'NO TLS     %s\n' "$CANDIDATE"
fi
```

Both outcomes are labelled and both name the host. An earlier form printed a
sentence on failure and a bare `issuer=` line on success, which made a working
host look like nothing had happened — the failure was louder than the success,
so silence read as a problem.

Reset `CANDIDATE` to the next hostname and run it again for each one you want to
weigh. Read the issuer, not the hostname:

| Issuer looks like | Verdict |
|---|---|
| `C=US, O=DigiCert Inc, CN=…`, `Let's Encrypt`, `O=Google Trust Services` | A **public** CA. The host may be internal and still be useless here — a handshake against it succeeds through the JDK's stock roots and never touches yours. |
| `DC=com, DC=<org>, CN=Issuing-<something>` | Your **internal** CA. This is the target. |

An internally-hosted service on a public certificate is common — Git servers and
anything with an externally-resolvable name often have one — so expect to check
more than one candidate.

If every candidate reports a public issuer, this test cannot prove anything about
the corporate root. Say so and defer the question to the first real build against
your internal artifact repository, rather than recording a pass that measured
nothing.

Once `CANDIDATE` holds a host with an **internal** issuer, leave it set — the
target is derived from it, so there is nothing to retype and no chance of
testing a different host than the one you vetted:

```bash
INTERNAL_URL="https://$CANDIDATE/"
"$JAVA_HOME/bin/java" /tmp/JvmTlsCheck.java "$INTERNAL_URL"
```

Read the outcome by its failure, not just its success:

| Result | Meaning |
|---|---|
| `-> HTTP 200` (or 302, 401, 403) | The handshake completed. Trust works — the status code itself does not matter. |
| `SSLHandshakeException: PKIX path building failed` | The corporate root is **not** in the store this JVM is using. The copy went to the wrong JDK, or the store does not contain it. |
| `UnknownHostException`, connect timeout | Network or VPN, not trust. Nothing to fix here. |

If you have no internal HTTPS endpoint to hand, run it against a public one
instead. That will not prove the corporate root is present, but it does catch a
badly built store — which is the more likely mistake with form **A**, where an
old public-root set comes along with the copy.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 7 — Trust the Corporate CA Outside the Keychain

Steps 4 through 6 covered the macOS keychain and the JVM. That is not everything. With TLS interception on the corporate network, npm, Node, pip, Homebrew's `curl`, and Git over HTTPS each consult their **own** bundled CA file and never read the macOS keychain, so they keep failing with `SELF_SIGNED_CERT_IN_CHAIN` or `unable to get local issuer certificate` long after Keychain Access says the root is trusted. Do this now, not at the first broken `npm install` in Phase 11B or 12.

**0. Re-establish `$MNT` and `$CORP_CERT` first.**

Step 4 pinned `$CORP_CERT`, and it lives only in the shell that set it. Steps 4
and 5 are GUI work, so a new terminal by now is the normal case rather than the
exception. Find the image, then let the certificates on it identify themselves:

```bash
MNT=""
for d in /Volumes/*/staged-loose; do
  [ -f "$d/MANIFEST.tsv" ] && MNT="$(dirname "$d")"
done
if [ -z "$MNT" ]; then
  printf 'NO IMAGE    nothing mounted — use the keychain export in step 1 instead\n' >&2
else
  printf 'MNT=%s\n\n' "$MNT"
  for f in "$MNT"/certs/loose-candidates-selected/*; do
    [ -f "$f" ] || continue
    subj="$(openssl x509 -in "$f" -noout -subject 2>/dev/null \
         || openssl x509 -inform DER -in "$f" -noout -subject 2>/dev/null)"
    iss="$(openssl x509 -in "$f" -noout -issuer 2>/dev/null \
        || openssl x509 -inform DER -in "$f" -noout -issuer 2>/dev/null)"
    if [ -z "$subj" ]; then
      printf 'NOT A CERT  %s\n' "$(basename "$f")"
    elif [ "${subj#subject=}" = "${iss#issuer=}" ]; then
      printf 'ROOT        %s\n            %s\n' "$(basename "$f")" "$subj"
    else
      printf 'NOT A ROOT  %s\n            %s\n            %s\n' "$(basename "$f")" "$subj" "$iss"
    fi
  done
fi
```

A root is self-signed — its subject and its issuer are the same string, which is
what the listing tests. Rely on that rather than on the filenames: the names in
`loose-candidates-selected/` were chosen by whoever exported them and routinely
label an issuing CA or a leaf as though it were the root. Anything printed as
`NOT A ROOT` is one of those; read the note at the end of this step before
putting one in the bundle.

Now pin the file the listing marked `ROOT`, substituting its name for the
example one:

```bash
CORP_CERT_FILE="root-ca.pem"
CORP_CERT="$MNT/certs/loose-candidates-selected/$CORP_CERT_FILE"
if [ ! -f "$CORP_CERT" ]; then
  printf 'NO SUCH FILE  %s\n' "$CORP_CERT" >&2
  printf '              set CORP_CERT_FILE to a name the listing marked ROOT\n' >&2
elif ! openssl x509 -in "$CORP_CERT" -noout -subject 2>/dev/null \
  && ! openssl x509 -inform DER -in "$CORP_CERT" -noout -subject; then
  printf 'NOT A CERT    %s\n' "$CORP_CERT" >&2
else
  printf 'CORP_CERT=%s\n' "$CORP_CERT"
  openssl x509 -in "$CORP_CERT" -noout -subject -issuer -dates 2>/dev/null \
    || openssl x509 -inform DER -in "$CORP_CERT" -noout -subject -issuer -dates
fi
```

> [!warning] Pitfall
> `CORP_CERT_FILE` starts as an example name, not yours. Left alone or mistyped,
> `$CORP_CERT` names a path that does not exist — and every `openssl` form in
> step 1 fails **after** truncating `~/.certs/corp-root.pem` to zero bytes. Five
> tools then trust a bundle containing nothing, and each of them fails later with
> a TLS error that points at the network instead of at the bundle. The check
> above is what stops that; the `grep -c` in step 1 is the second net.

**If the image is already detached**, do not re-mount it for this. The root is in
your keychain by now, and the export-from-keychain form at the end of step 1
needs no DMG at all — it is the better source at this point in the phase.

**1. Export the intercepting root to a stable path.**

Name the destination first. Everything below — the gate, both `.zprofile`
forms, and every per-tool config write in step 2 — reads these two variables,
so the bundle path is written down exactly once:

```bash
CA_BUNDLE_REL=".certs/corp-root.pem"
CA_BUNDLE="$HOME/$CA_BUNDLE_REL"
```

This is a fixed location, not a copy of whatever the source file was called.
`$CORP_CERT_FILE` names a file *on the image*; this names the file *five tools
will be pointed at for the life of the machine*, and those two must not be the
same string. The bundle may end up holding the intermediate as well as the root
(see the note at the end of this step), which would make a name inherited from
the root file wrong; and a future image whose export is called something else
would otherwise silently move the path every tool's config points at.

Two sources produce the same bundle; pick either. Both write to a staging file,
and neither touches `$CA_BUNDLE` — the verification gate at the end installs it,
and only if there is something worth installing. That ordering is deliberate: a
redirect that truncates the bundle before discovering it has nothing to write is
the failure this step exists to prevent.

*Source A — the keychain.* The better source once Step 5 has trusted the root,
and it needs no DMG. List the CA labels first:

```bash
security find-certificate -a /Library/Keychains/System.keychain | grep '"labl"'
```

Each line of that output is a certificate's label — `"labl"<blob>="..."` —
which for a CA is its common name. `ROOT_CN` takes **that string, not a
filename**: it is matched against certificates already in the keychain, so
nothing on the DMG and nothing named `.pem` or `.cer` belongs in it. Look for
the label that describes a root; the intermediates beside it are usually
labelled `Issuing-...` and are not what this bundle wants.

| Variable | Kind of value | Example |
|---|---|---|
| `CORP_CERT_FILE` (step 0) | A filename on the mounted image | `root-ca.pem` |
| `ROOT_CN` (here) | A certificate common name from the keychain listing | `Root Example CA` |
| `CA_BUNDLE` (above) | The fixed destination path | `$HOME/.certs/corp-root.pem` |

```bash
ROOT_CN="Root Example CA"
security find-certificate -a -c "$ROOT_CN" -p \
  /Library/Keychains/System.keychain "$HOME/Library/Keychains/login.keychain-db" \
  > /tmp/corp-root-staging.pem
```

*Source B — the mounted image.* Uses `$CORP_CERT` from step 0. Both encodings
are tried because the export on the image may be either:

```bash
openssl x509 -inform DER -in "$CORP_CERT" -out /tmp/corp-root-staging.pem 2>/dev/null \
  || openssl x509 -inform PEM -in "$CORP_CERT" -out /tmp/corp-root-staging.pem
```

*Combine with the system roots.* The corporate root alone is **not** the right
bundle. Every consumer configured in step 2 — npm's `cafile`, Git's
`http.sslCAInfo`, `CURL_CA_BUNDLE`, `REQUESTS_CA_BUNDLE`, `PIP_CERT` —
**replaces** its trust store with this file rather than adding to it. On a
network that intercepts internal hosts and lets public traffic through
untouched, a corporate-root-only bundle then rejects most of the internet:

```text
npm error code UNABLE_TO_GET_ISSUER_CERT_LOCALLY
npm error request to https://registry.npmjs.org/-/ping failed,
          reason: unable to get local issuer certificate
```

The issuer of a *public* endpoint tells you which kind of network you are on:

```bash
echo | openssl s_client -connect registry.npmjs.org:443 -servername registry.npmjs.org 2>/dev/null \
  | openssl x509 -noout -issuer
```

A public CA — `Google Trust Services`, `DigiCert`, `ISRG` — means public traffic
is **not** intercepted and the bundle must carry the system roots as well. Your
corporate root as the issuer means everything is intercepted. Combine
unconditionally: it costs nothing in the second case and is the difference
between working and not in the first.

```bash
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain \
  > /tmp/corp-root-combined.pem
cat /tmp/corp-root-staging.pem >> /tmp/corp-root-combined.pem
grep -c 'BEGIN CERTIFICATE' /tmp/corp-root-combined.pem
```

Expect a count in the low hundreds. A count of `1` means the system-root export
produced nothing, and the bundle would work for internal hosts and fail for
everything else.

*Verify, then install:*

```bash
count="$(grep -c 'BEGIN CERTIFICATE' /tmp/corp-root-staging.pem 2>/dev/null)" || count=0
subj="$(openssl x509 -in /tmp/corp-root-staging.pem -noout -subject 2>/dev/null)"
iss="$(openssl x509 -in /tmp/corp-root-staging.pem -noout -issuer 2>/dev/null)"
if [ "$count" -eq 0 ] || [ -z "$subj" ]; then
  printf 'EMPTY       nothing was exported; %s left alone\n' "$CA_BUNDLE" >&2
  printf '            source A: ROOT_CN matched no certificate — check it against the labels\n' >&2
  printf '            source B: $CORP_CERT did not parse — re-run step 0\n' >&2
elif [ "${subj#subject=}" != "${iss#issuer=}" ]; then
  printf 'NOT A ROOT  %s\n            %s\n' "$subj" "$iss" >&2
  printf '            an issuing CA or a leaf; see the note at the end of this step\n' >&2
else
  mkdir -p "$(dirname "$CA_BUNDLE")"
  mv /tmp/corp-root-combined.pem "$CA_BUNDLE"
  rm -f /tmp/corp-root-staging.pem
  printf 'INSTALLED   %s (%s certificate(s))\n' "$CA_BUNDLE" \
    "$(grep -c 'BEGIN CERTIFICATE' "$CA_BUNDLE")"
  printf '            corporate root: %s\n' "$subj"
fi
```

`ROOT_CN` starts as an example, exactly as `CORP_CERT_FILE` does in step 0 — the
`EMPTY` branch is what tells you it was left that way. `openssl x509` reads only
the first block of a multi-certificate file, so with more than one match the
root test judges the first; a count above 1 from source A is normally the same
certificate found in both keychains.

**2. Point every store at the bundle.**

In a fresh terminal, re-run the two `CA_BUNDLE_REL` / `CA_BUNDLE` lines from the
top of step 1 — they are the one definition, and they need no DMG and no
`$CORP_CERT`. Then confirm step 1 actually left something there:

```bash
[ -s "$CA_BUNDLE" ] \
  && printf 'READY     %s\n' "$CA_BUNDLE" \
  || printf 'MISSING   %s — run step 1 first\n' "$CA_BUNDLE" >&2
```

Two mechanisms are needed, because the tools split on which one they read.
Environment variables cover `curl`, Node and the Python `requests` stack;
per-tool config files cover npm, Git and pip, and are read by invocations that
never see your profile — a launchd job, an IDE's embedded terminal, a CI runner
on this machine.

*Persist the environment variables.* One block, written once. The heredoc is
quoted, so `$HOME` reaches `.zprofile` unexpanded and stays correct if the
account is ever moved:

```bash
if grep -q 'REIMAGE-CA-BUNDLE' ~/.zprofile 2>/dev/null; then
  printf 'PRESENT   ~/.zprofile already carries the block; left alone\n'
else
  {
    printf '\n# REIMAGE-CA-BUNDLE — corporate TLS interception root (restore-access.md Step 7)\n'
    for v in NODE_EXTRA_CA_CERTS CURL_CA_BUNDLE REQUESTS_CA_BUNDLE PIP_CERT; do
      printf 'export %s="$HOME/%s"\n' "$v" "$CA_BUNDLE_REL"
    done
  } >> ~/.zprofile
  printf 'ADDED     ~/.zprofile\n'
fi
for v in NODE_EXTRA_CA_CERTS CURL_CA_BUNDLE REQUESTS_CA_BUNDLE PIP_CERT; do
  export "$v=$CA_BUNDLE"
done
```

The format string is single-quoted, so `$HOME` reaches `.zprofile` unexpanded
and the file stays correct if the account ever moves; `%s` is where
`$CA_BUNDLE_REL` lands. That is the reason the path is split into a relative
half and an absolute one rather than written out here — the literal `$HOME` and
the substituted filename have to coexist on the same line.

The `REIMAGE-CA-BUNDLE` marker is what makes this safe to re-run. Without it,
working the step twice appends the exports twice; the shell tolerates that, but
the next person reading `.zprofile` cannot tell a deliberate override from an
accidental repeat.

*Write the per-tool config files.* Step 7 runs in Phase 10B, before Phase 12
restores applications, so some of these tools legitimately are not installed
yet. Each reports rather than failing silently — re-run this block after the
apps are back:

```bash
if command -v npm >/dev/null 2>&1; then
  npm config set cafile "$CA_BUNDLE" && printf 'SET       npm cafile\n'
else
  printf 'SKIP      npm not installed yet — re-run this block after Phase 12\n'
fi
if command -v git >/dev/null 2>&1; then
  git config --global http.sslCAInfo "$CA_BUNDLE" && printf 'SET       git http.sslCAInfo\n'
else
  printf 'SKIP      git not installed yet\n'
fi
if command -v pip3 >/dev/null 2>&1; then
  pip3 config set global.cert "$CA_BUNDLE" >/dev/null && printf 'SET       pip global.cert\n'
else
  printf 'SKIP      pip3 not installed yet — re-run this block after Phase 12\n'
fi
```

SSH remotes are unaffected by any of this — it reaches HTTPS remotes only, which
is what most tooling and CI helpers default to.

**3. Smoke-test each store before moving on.**

Each test **forces** the tool to use `$CA_BUNDLE`. That is not decoration: run
without it, three of the five measure the system keychain instead and pass while
the bundle is broken. macOS `curl` and `git` consult the keychain regardless of
`CURL_CA_BUNDLE` and `http.sslCAInfo`, and `urllib.request` reads
`ssl.get_default_verify_paths()` and never looks at `REQUESTS_CA_BUNDLE` at all.
`npm` is the only one of the five that honours its own setting unprompted —
which is why, in the run that produced this note, npm was the only test to
report a real misconfiguration while the other four reported success.

They hit public endpoints on purpose: a public endpoint is what a
corporate-root-only bundle cannot validate, so it is the case worth testing.

`smoke` takes a label and a command. On failure it prints the first four lines
of the tool's own error under the `FAIL`, because a bare `FAIL` says something
is wrong and nothing about what — and these five fail for entirely unrelated
reasons.

**Expect `SKIP node` and `SKIP npm` on a first pass.** Node and npm arrive with
`restore-apps` (Phase 12); `curl`, `git` and `python3` are on the base system or
came with Phase 10A, so those three are the ones that report here. A `SKIP` is
not a pass — it means the test did not run — so note which skipped and come back
after Phase 12.

```bash
smoke() {
  label="$1"; shift
  if out="$("$@" 2>&1)"; then
    printf 'PASS  %s\n' "$label"
  else
    printf 'FAIL  %s\n' "$label"
    printf '%s\n' "$out" | sed -n '1,4p' | sed 's/^/      /'
  fi
}

export CA_BUNDLE_SMOKE="$CA_BUNDLE"

smoke curl curl -sSI --cacert "$CA_BUNDLE" https://registry.npmjs.org/

if command -v node >/dev/null 2>&1; then
  smoke node node -e "require('https').get('https://registry.npmjs.org/', r => process.exit(r.statusCode < 400 ? 0 : 1)).on('error', e => { console.error(e.message); process.exit(1); })"
else printf 'SKIP  node\n'; fi

if command -v npm >/dev/null 2>&1; then smoke npm npm ping
else printf 'SKIP  npm\n'; fi

smoke git git -c http.sslCAInfo="$CA_BUNDLE" ls-remote https://github.com/git/git

smoke python python3 -c "import os, ssl, urllib.request; ctx = ssl.create_default_context(cafile=os.environ['CA_BUNDLE_SMOKE']); urllib.request.urlopen('https://pypi.org/simple/', context=ctx)"
```

When you do come back after Phase 12, re-run both blocks of step 2 as well as
this one: the config writes for `npm` and `pip3` skipped for the same reason the
tests did.

> [!note]
> If the interception uses an intermediate issuing CA as well as a root, the
> bundle needs both — a bundle may hold any number of PEM blocks. Reach for this
> only when the smoke tests fail with `unable to get local issuer certificate`
> after a clean `INSTALLED`; a server that sends its own intermediate, as most
> do, needs the root alone.
>
> ```bash
> ISSUING_CERT="$MNT/certs/loose-candidates-selected/issuing-ca.pem"
> cat "$ISSUING_CERT" >> "$CA_BUNDLE"
> grep -c 'BEGIN CERTIFICATE' "$CA_BUNDLE"
> ```
>
> Append, never rebuild. `cat root.pem issuing.pem > "$CA_BUNDLE"` truncates its
> own input the moment `root.pem` *is* `$CA_BUNDLE`, which after step 1 it is —
> the redirection empties the file before `cat` reads it, and you lose every
> certificate already there. Expect the count to rise by exactly one.

> [!warning] Pitfall
> `~/.zprofile` only reaches processes started from a login shell. GUI apps launched from the Dock or Spotlight — IntelliJ, VS Code, Docker Desktop — do not see `NODE_EXTRA_CA_CERTS` or `REQUESTS_CA_BUNDLE` and will still fail. Launch them from a terminal, or set the variable in the app's own run configuration. And never "fix" this with `npm config set strict-ssl false`, `GIT_SSL_NO_VERIFY=1`, or `pip --trusted-host`: those disable verification instead of establishing trust, and they tend to survive into places you did not intend.

> [!bug] Troubleshooting
> If one tool fails while the others pass — most often `npm` — see
> [[#One smoke test fails while the others pass|One smoke test fails while the others pass]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 8 — Restore Shell Environment and CLI Config

Do not blindly overwrite fresh shell files. Diff first, adopt selectively.

**VS Code is not installed yet** — `restore-apps` (Phase 12) Step 6 installs it,
two phases from here, so `code` is not on `PATH` and cannot open the comparison.
Everything below uses tools the machine already has: `cmp` and `diff` from the
base system, and `git` from the Command Line Tools that Phase 10A installed.

First, see which files actually differ. Comparing the whole of `$HOME` against
the backup would recurse through every file you own, so the candidate list is
walked by name instead:

```bash
DOTFILES_BACKUP="$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles"
printf 'Using dotfiles backup: %s\n\n' "$DOTFILES_BACKUP"
for f in .zshrc .zprofile .bash_profile .bashrc .gitconfig \
         .shell_common.sh .shell_local.sh; do
  b="$DOTFILES_BACKUP/$f"; l="$HOME/$f"
  if   [ ! -e "$b" ]; then printf 'NO BACKUP   %s\n' "$f"
  elif [ ! -e "$l" ]; then printf 'BACKUP ONLY %s  (nothing here to merge into)\n' "$f"
  elif cmp -s "$b" "$l"; then printf 'SAME        %s\n' "$f"
  else                       printf 'DIFFERS     %s  <- review this one\n' "$f"
  fi
done
```

Then review one file at a time. Set `F` to a name the listing marked `DIFFERS`
and re-run; left is what you have now, right is the backup:

```bash
F=".zshrc"
git diff --no-index --color=always "$HOME/$F" "$DOTFILES_BACKUP/$F" | less -R
```

`git diff --no-index` exits 1 when the files differ, which is the normal case
here and not an error. For an editor rather than a pager, `vimdiff "$HOME/$F"
"$DOTFILES_BACKUP/$F"` works on the base system; `code --diff` becomes available
after Phase 12 if you would rather leave the shell files until then.

The directory-shaped entries in the list below — `.config/`, `.kube/`, `.cf/`,
`.azure/` — are restored per-subtree by `restore-home` (Phase 15), not here.
This step is the flat shell files.

Common selective restores:

```text
.zshrc
.zprofile
.bash_profile
.bashrc
.gitconfig                (Phase 11A owns Git identity — see the note below)
.shell_common.sh
.shell_local.sh
.config/
.kube/
.cf/
.azure/
```

> [!warning] Pitfall
> The pre-image `.gitconfig` in that backup carries `[http] sslverify = false` —
> **global**, not per-host. Adopting the file whole turns off TLS verification
> for every Git HTTPS remote, which defeats the Git half of Step 7 while `npm`,
> `pip`, `curl` and Node keep verifying normally. That asymmetry is what makes it
> survive: nothing else looks broken.
>
> Take `user.name`, the `includeif` routing and `credential.helper` if you want
> them; leave the `[http]` block. Then confirm:
>
> ```bash
> git config --global --get http.sslverify
> ```
>
> Empty is correct. If it returns `false`, remove it with
> `git config --global --unset http.sslverify`. `restore-git.md` (Phase 11A) has
> the per-host form for the one case that genuinely needs an exemption — and
> check first, because Step 7 put the corporate root in the CA bundle, so a host
> that failed to verify before may verify now.

Prefer selective merge over blind copy for machine-specific files. `.zprofile`
is the one that will bite: it already carries the Homebrew and `nvm` bootstrap
added in Phase 10A **and** the `REIMAGE-CA-BUNDLE` block Step 7 wrote a few
minutes ago. Copying the backup over it silently removes both, and the CA
symptom will not appear until the first `npm install` two phases later. If you
do overwrite it, re-run Step 7's `.zprofile` block afterwards — it is idempotent
and reports `ADDED` or `PRESENT`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 9 — Restore Credentials and License Material

Credential-bearing material stays inside the DMG until the moment it is needed. Restore only through supported flows:

Typical sources on the mounted volume:

```text
$MNT/cli-credentials/    ~/.netrc, gh config, and per-tool credential exports
$MNT/git/                ~/.git-credentials and Git helper cache
$MNT/package-managers/   .npmrc, .yarnrc(.yml), .pypirc, gradle.properties,
                         Maven settings.xml
$MNT/licenses/           Vendor license keys, serials, activation exports
```

All four are **conditional**. Phase 3C creates each only if there was applicable
material to stage, so a missing directory means nothing was captured, not that
something went wrong. Check which ones you actually have rather than working
from the list:

```bash
for c in cli-credentials git package-managers licenses; do
  if [ -d "$MNT/$c" ]; then
    printf 'PRESENT   %-18s %s file(s)\n' "$c" \
      "$(find "$MNT/$c" -type f ! -name '.DS_Store' | wc -l | tr -d ' ')"
  else
    printf 'ABSENT    %-18s nothing was staged for this category\n' "$c"
  fi
done
```

There is no `cloud/`: AWS and other cloud CLIs are deliberately not backed up,
and are re-authenticated instead. Prefer re-authentication for everything in
`git/` and `package-managers/` too — a registry token or a Git helper cache
restored from a three-week-old image is as likely to be stale as valid, and
re-issuing it costs less than debugging it.

`cli-credentials/` most often holds `gh/hosts.yml`, the GitHub CLI's stored
OAuth token.

**Expect to defer this one.** `gh` is installed by `restore-apps` (Phase 12), so
on a first pass through this phase it is not on `PATH` and there is nothing to
check — the block below will say so rather than fail, and that is the normal
result here, not a problem to chase. Run it to confirm which case you are in:

```bash
if command -v gh >/dev/null 2>&1; then
  gh auth status 2>&1 | sed -n '1,6p'
else
  printf 'gh is not installed yet — Phase 12 installs it; defer this row.\n'
fi
```

Once `gh` exists, `gh auth login` is the restore. It re-issues the token against
the account you are actually signed into now, which a copied `hosts.yml` cannot
do — the file may name an account, host, or scope set that no longer applies.
Restore the file only if re-authentication is unavailable, and then to
`~/.config/gh/hosts.yml` at mode `600`.

Nothing later in this phase depends on it, so deferring costs nothing. Note it
on the exit checklist so Phase 12 picks it up.

For each application license or activation file:

1. Use the application vendor's supported import or reactivation flow — not a manual copy of an activation file unless the vendor explicitly documents that path.
2. Keep copied activation files out of Git and OneDrive unless separately approved.
3. Record only redacted restore notes in plain Markdown, under `$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/`.
4. Remove any temporary plaintext copies after the app is activated and validated.

> [!warning] Pitfall
> Screenshots or PDFs of subscription pages that contain private identifiers still count as secret material. They belong under `secrets-encrypted/licenses/` — not under `public-certs/`, not in `reimaged-system/restore-notes/`, and not in a general notes folder. Staging them there *before* the Phase 3C build is what causes the `licenses/` category to exist on the next image; nothing is added to a DMG after it is built.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 10 — Eject the DMG and Clean Up Plaintext

**Walk the by-hand categories first.** Several categories on the image have no restore step anywhere in the toolkit, and once the DMG is detached and the artifact drive retired they are gone:

```bash
ls "$MNT"
```

Check each one against [[#DMG Categories Restored By Hand|DMG Categories Restored By Hand]] below and restore or consciously skip it. Only then eject:

```bash
hdiutil detach "$MNT"
```

```bash
hdiutil info | grep -c all-secrets
```

Expect `0`. Judge this by the printed number, not by an exit status: `grep -c` prints `0` **and exits 1** when nothing matches.

> [!warning] Pitfall
> Detach by `"$MNT"`, never by `/Volumes/all-secrets-*`. If the volume name does not match the DMG filename the glob expands to nothing, `hdiutil detach` fails on a literal path, and the mounted plaintext secrets are left sitting on `/Volumes/` — usually unnoticed, because the step "ran". If `$MNT` is no longer set in this shell, re-derive it with the snippet in Step 1.

Sweep for any temporary plaintext copies you may have made outside the DMG (Downloads, Desktop) and remove them. The DMG is the durable copy; nothing plaintext should remain on disk after this step.

The phase is not finished here — Step 11 records that it finished.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 11 — Compare Restored State Against Captured Inventories

Step 0b recorded what the machine looked like before this phase touched it, and
Phase 4B and 2C recorded what it looked like before the erase. This step is
where those recordings earn their keep. It is the same script `restore-runtime`
runs at its Step 10, but what Phase 10B rebuilds is trust and identity rather
than tool versions, so the probes and the vocabulary differ.

**1. Capture the after-state.** This is the pair to Step 0b, and the comparison
in step 2 cannot run without it. Same script, same phase, the other point:

```bash
./bin/record-restore-state.sh --runbook restore-access --point after --dry-run
./bin/record-restore-state.sh --runbook restore-access --point after
```

`after` is a latest-wins point, so re-running it after a late fix replaces the
earlier capture rather than being ignored — the opposite of `before`, which is
first-wins because the earliest observation is the one that captured the
untouched machine.

**2. Compare against the captured inventories.** Preview the options, then run
it. This baseline reads the pre-image system inventory, the managed inventory,
and the `jssecacerts` manifest beside the encrypted image — three captures, not
one, because what this phase rebuilds is spread across all three:

```bash
./bin/compare-restored-state.sh --runbook restore-access --help
./bin/compare-restored-state.sh --runbook restore-access --dry-run
./bin/compare-restored-state.sh --runbook restore-access
```

Rows worth understanding, because they are not the version comparison that
`restore-runtime` produces:

| Verdict | Means |
|---|---|
| `identical` | A `jssecacerts` SHA-256 match — the installed file is byte-for-byte the captured one. This is the strongest row the toolkit produces. |
| `no baseline` on a `jssecacerts` row | That JDK was installed after the pre-image capture, so no hash was recorded. That JVM has no corporate trust unless you put it there. A JDK that is *not* installed produces no row at all. |
| `correctly dropped` | An inverted row, and a **pass**. `http.sslverify = false` was recorded pre-image; carrying it forward would disable TLS verification for every Git HTTPS remote and undo Step 7. |
| `**CARRIED FORWARD**` | That value came back. Remove it with `git config --global --unset http.sslverify`, and scope it per host with `GIT_INTERNAL_TLS_SKIP_HOST` in `restore-git.md` if one internal host genuinely needs it. |
| `**MISSING**` | Recorded pre-image, absent now. On this phase that is trust or identity, not a tool a later phase installs. |

> [!note]
> `Git credential.helper` and `Git init.defaultBranch` reading `**MISSING**` here
> is expected: `restore-git.md` (Phase 11A) owns the global Git configuration and
> has not run yet. Re-run this comparison after Phase 11A — that is also when
> `http.sslverify` could come back, so a `correctly dropped` verdict now is not
> the final answer on that row.

**3. Join the two recordings.** `delta` is a third point on the same script. It
walks nothing — it joins the official before-state and after-state and records
what changed between them:

```bash
./bin/record-restore-state.sh --runbook restore-access --point delta --dry-run
./bin/record-restore-state.sh --runbook restore-access --point delta
```

It answers what this phase changed on disk, which no live check can — by now the
before-state is gone. It is a **delta**, not a diff: both sides are recordings of
the same paths at two moments, so nothing in it can go stale.

It is its own point rather than a side effect of `--point after` for two
reasons. A run directory should hold one kind of thing, and re-running it is how
you rebuild the delta when either side is re-recorded or re-pinned — which
happens, because `after` is latest-wins and `before` can be pinned with a
caveat.

Expect `~/.certs/corp-root.pem` as **added** (Step 7), `System.keychain` as
**content changed** (Step 5), and the restored SSH keys as **mode changed**
(Step 3). **removed** is the verdict to read twice — this phase restores, and
should rarely delete.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 12 — Close Out the Exit Criteria

Step 0a recorded whether this phase was allowed to start. This step records
whether it finished. Skip it and nothing anywhere says so — a question that gets
asked days later, when the answer is no longer reconstructable.

It runs **after** Step 10, not before it: the exit checklist tests that the
secrets DMG is detached, so running it earlier fails a row that is not actually
wrong yet.

**1. Run the exit checklist.** It answers "did this phase finish", against the
same boundary index that Step 0a wrote its entry record into:

```bash
./bin/record-restore-exit.sh --runbook restore-access --dry-run
./bin/record-restore-exit.sh --runbook restore-access
```

Read the rows rather than the exit status. It records `PASS`, `WARN`, `FAIL` and
`MANUAL`, and a `MANUAL` row is a question only you can answer — it is not a
failure, and it is not a pass either. Every `FAIL` names what to re-run.

The checklist covers what this phase's steps produced: SSH key modes, the
corporate CA bundle, Git and Node and Python over HTTPS, the Java trust
override, the shell-config merge, the by-hand DMG categories, licenses, the
staged-loose destinations, and the DMG being detached. There is no separate
table to tick here — the checklist is the table, and keeping a second copy in
the runbook is how the two drift apart.

> [!note]
> `bin/record-restore-prereqs.sh` and `bin/record-restore-exit.sh` are one pair
> per phase boundary, not one per runbook. This phase runs the `10B` entry check
> at Step 0 and the `10B` exit check here. It never runs Phase 11A's entry check,
> and never re-runs its own entry check at the end.

**2. Confirm both boundary records landed.** One file answers whether the phase
both started and finished:

```bash
sed -n '1,40p' "$REIMAGE_ARTIFACT_ROOT/reimaged-system/boundaries/MANIFEST.md"
```

You are looking for a `restore-access-entry-*` row and a
`restore-access-exit-*` row. An entry with no exit is the signature of
a phase that was walked but never closed out.

With both recorded, continue to `restore-git.md` (Phase 11A).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## DMG Categories Restored By Hand

These categories exist on the secrets DMG and have no restore step in this
runbook. Most have no owner anywhere in the toolkit — walk those once, while the
image is still mounted (`ls "$MNT"`), and restore or consciously skip each.
Nothing downstream will remind you.

Two rows are the exception and say so: they are owned by a later phase, and the
work belongs there, not here. Doing it now means doing it against a machine that
does not yet have the application installed. The **Owner** column is the whole
decision — `by hand, now` or a runbook name. The full category-to-owner map is
in *Artifact and Script Locations* above.

| Category on the DMG | Owner | What to do |
|---|---|---|
| `gnupg/` | by hand, now | Copy back to `~/.gnupg`, then `chmod 700 ~/.gnupg` and `chmod 600 ~/.gnupg/*` — `gpg` refuses a world-readable home. Verify with `gpg --list-secret-keys`; re-set `trust` on your own key if signing fails. |
| `kube/` | by hand, now | Copy the kubeconfig to `~/.kube/config` at mode `600`. Cluster tokens are usually expired — re-auth through the cluster's exec/OIDC plugin, then `kubectl config get-contexts`. Distinct from `home-files-backup/dotfiles/kube/`, which `restore-home` (Phase 15) restores separately: that subtree holds the non-credential remainder, this one holds the file the Phase 3B sweep pulled out of it. Restore this one last so Phase 15 does not overwrite it. |
| `claude/` | by hand, now | Put `claude_desktop_config.json` back under `~/Library/Application Support/Claude/` and restart Claude Desktop so it re-reads the file. |
| `claude-code/` | by hand, now | Restore `.claude.json` to `~/.claude.json`. It carries MCP server definitions plus account and org identifiers — review it before restoring, drop entries for machines or projects that no longer exist, and re-authenticate rather than trusting any token inside it. |
| `raycast/` | `restore-apps` (Phase 12) | **Do not do this here.** Raycast is not installed yet. Phase 12 Step 7 owns the import; the only thing this phase owes it is the password — the `.rayconfig` export is password-protected with the Phase 3C password, which is not in `reimage.env` and which you will need again after the DMG is ejected. Record where you keep it before Step 10. |
| `chrome/` (`*Passwords*.csv`) | never | **Intentionally not restored.** Passwords come back through the password manager, which is the system of record. The CSV exists only as a break-glass copy and must be destroyed along with the DMG — never imported into the new browser profile. Chrome profiles, extensions and bookmarks are a separate matter and belong to `restore-apps` (Phase 12) Step 3; nothing on this row feeds that. |

> [!warning] Pitfall
> The `chrome/*Passwords*.csv` file is plaintext credentials for every site you have ever saved. Do not copy it out of the DMG "just to check", and do not let it survive the DMG. If you already extracted a copy, remove it now and confirm nothing is left: `ls ~/Downloads ~/Desktop | grep -i password`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The commands do X; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Whether a certificate imported in Step 4 should be marked Always Trust. | Requires knowing whether it is a genuine internal root/issuing CA; incorrect trust weakens the whole TLS story. |
| Whether the SSH keys on the DMG are the current identity or a rotated-out prior identity. | Depends on rotation history that the DMG does not carry. If unsure, generate a new key and register it upstream rather than restoring an old one. |
| Which lines of a captured `.zshrc` or `.zprofile` should be adopted verbatim versus merged with the fresh file. | The fresh file already has Phase 10A's Homebrew and `nvm` bootstrap; the captured file may have machine-specific tweaks that no longer apply. |
| Whether an activation file should be reused, or the vendor's normal sign-in and reactivation flow used instead. | Some vendors invalidate copied activation files on new hardware; only you know per-app policy. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Five failures here have fixes long enough to break the flow of the step that surfaces them. Each step links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### `hdiutil attach` says the DMG is corrupt

Verify the DMG on disk before assuming it is unrecoverable:

```bash
hdiutil verify "$DMG"
```

If verification fails, fall back to the previous timestamped `all-secrets-*.dmg` in the same directory. If both fail, rebuild the image with `create-secrets-dmg.md` on the source machine — this runbook does not repair DMGs. Attach the working DMG the same way, confirm the mount, then carry on.

[[#Step 3 — Restore SSH and Git Access|⮕ Continue to Step 3 — Restore SSH and Git Access]]

### `ssh -T` fails after the keys are restored

Three failures look alike here and have nothing to do with each other.

`Permission denied (publickey)` is an **identity** problem: the key is absent,
is the wrong key, or is not registered with the host. That is this step's
business.

`Connection closed by <host>` means the transport worked and **no key was
offered** — which is what testing a host that has no `IdentityFile` looks like.
It reads like a failed key restore and is not one. Check what the host you
tested actually resolves to:

```bash
ALIAS="github.com-example"
ssh -G "$ALIAS" | grep -iE 'hostname|port|identityfile|identitiesonly'
```

If no `identityfile` line names one of the keys you just restored, you tested
the wrong host, not a broken key.

`Operation timed out` is a **network** problem, and the key is untested rather
than broken. Reading a timeout as a failed key restore sends you back to redo a
Step 3 that was correct.

There are two different network failures behind that one message, and a port
probe alone cannot tell them apart:

```bash
nc -z -G 5 github.com 22 && echo "TCP 22 reachable" || echo "TCP 22 blocked or filtered"
```

**If the probe fails**, outbound 22 is blocked — common on corporate networks,
and a freshly enrolled Mac may also be waiting on a VPN or a firewall profile
that arrived with enrolment.

**If the probe SUCCEEDS and `ssh` still times out**, which is the more
confusing case, the TCP handshake completes and the SSH protocol does not.
`nc -z` only proves a socket opened; it sends no SSH traffic, so it reports a
green result on a path that cannot carry a session. The usual cause is path
MTU: key exchange sends packets far larger than a bare handshake, and a tunnel
or VPN advertising the wrong MTU silently drops them. A protocol-inspecting
middlebox produces the same signature. Note the message — `ssh_dispatch_run_fatal`
means it died *inside* the protocol loop, after connecting.

Confirm where it dies before changing anything:

```bash
ssh -vvv -T git@github.com 2>&1 | tail -25
```

Hanging right after `SSH2_MSG_KEXINIT sent` is the MTU signature. Compare
`ifconfig | grep -w mtu` against 1500; a tunnel interface below that on the
active route is the thing to raise with whoever runs the network.

Either way, GitHub also answers SSH on 443, which is a different path and
usually survives both. Add two lines to the alias block that already carries
your key — **do not** add a bare `Host github.com` block, which would route to
443 with no identity and fail with `Connection closed`:

```text
Host github.com-<label>          # the alias you already use
  HostName ssh.github.com        # was github.com
  Port 443                       # added
  User git
  IdentityFile ~/.ssh/<key>      # unchanged
  IdentitiesOnly yes             # unchanged
```

and re-run the test.

**Do not generalise from one host to another.** An internal Git server and
public GitHub usually take different egress paths — the internal one often
bypasses the corporate egress agent entirely — so one authenticating says
nothing about the other, in either direction. Observed on this workflow: an
internal GitHub Enterprise host authenticated on port 22 while public
`github.com` timed out and then closed, on the same machine, minutes apart.

Where an egress agent terminates outbound SSH to the internet, 443 will not
help either, because the agent is ending the session rather than the path
dropping packets. That is a network policy rather than a restore defect, and
the answer is HTTPS remotes for that host. Nothing else in this phase depends
on it — Steps 4 through 9 reach no remote at all.

Neither failure blocks the rest of this phase. Steps 4 through 9 touch no
remote, and the exit checklist tests HTTPS reachability separately.

[[#Step 4 — Restore Certificates and Keychain Material|⮕ Continue to Step 4 — Restore Certificates and Keychain Material]]

### SSH keeps prompting for a passphrase every session

The keys are correct but not added to the ssh-agent. Add them once per session:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

For persistence, add an `AddKeysToAgent` directive to `~/.ssh/config`; that is a shell config change, not an SSH restore fix.

[[#Step 4 — Restore Certificates and Keychain Material|⮕ Continue to Step 4 — Restore Certificates and Keychain Material]]

### `curl` still fails against internal endpoints after Step 5

Always Trust was set on the wrong certificate. **Only the root earns an explicit trust setting.** An issuing CA and a leaf both chain to it and stay on "Use System Defaults" — trusting an issuing CA directly widens what the machine accepts beyond what the root's own policy allows, and this environment has more than one issuing CA under the same root, so trusting the one you happen to have imported does not cover the others.

Reopen each certificate in Keychain Access. Reset anything that is not self-signed to "Use System Defaults", and set Always Trust on the root alone. Self-signed means subject and issuer match:

```bash
CERT="$MNT/certs/loose-candidates-selected/root-ca.pem"
openssl x509 -in "$CERT" -noout -subject -issuer
```

Equal subject and issuer is the root. Anything else belongs on defaults.

[[#Step 6 — Restore Java Trust Overrides|⮕ Continue to Step 6 — Restore Java Trust Overrides]]

### One smoke test fails while the others pass

**`npm` fails while `curl`, `node`, `git` and `python` all pass.** This is the
common shape, and it is usually *not* a trust failure — the four that passed
prove the bundle is good. `npm` is the only one of the five with its own
registry, proxy and auth configuration, so start there rather than with
certificates:

```bash
npm ping 2>&1 | head -20
npm config get registry
npm config get proxy
npm config get https-proxy
npm config get cafile
```

A `registry` that is not `https://registry.npmjs.org/` means an internal
mirror is configured and unreachable or unauthenticated — a different problem
from this step. An empty `cafile` means step 2's write did not take; re-run it.

**If the failure is `UNABLE_TO_GET_ISSUER_CERT_LOCALLY` or
`unable to get local issuer certificate`, the bundle is short.** Check what it
holds:

```bash
grep -c 'BEGIN CERTIFICATE' "$CA_BUNDLE"
```

A count of `1` means Step 7's combine did not happen and the bundle carries only
the corporate root. That is enough for an intercepted connection and not enough
for one that reaches the real internet untouched — and `cafile`, like
`CURL_CA_BUNDLE`, **replaces** the trust store rather than adding to it, so
every public endpoint then fails. `node` passes through the same breakage
because `NODE_EXTRA_CA_CERTS` **adds** instead of replacing, which is exactly
why `npm` can fail while `node` succeeds against the same registry. Rebuild:

```bash
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain \
  > /tmp/ca-combined.pem
cat "$CA_BUNDLE" >> /tmp/ca-combined.pem
grep -c 'BEGIN CERTIFICATE' /tmp/ca-combined.pem
cp /tmp/ca-combined.pem "$CA_BUNDLE"
```

Expect a count in the low hundreds, then re-run the smoke tests.

`SELF_SIGNED_CERT_IN_CHAIN` after all of the above almost always means the tool is reading a different config than you set. Check what it actually resolved: `npm config get cafile`, `git config --get http.sslCAInfo`, `python3 -c "import ssl; print(ssl.get_default_verify_paths())"`, and `echo "$NODE_EXTRA_CA_CERTS"`. A per-repo `.npmrc` or a project-local `.git/config` overrides the global setting.

[[#Step 8 — Restore Shell Environment and CLI Config|⮕ Continue to Step 8 — Restore Shell Environment and CLI Config]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link,
  except Troubleshooting, whose back-link sits under its intro and whose routed
  symptom subsections stay out of the Table of Contents.
-->
