[[reimaging-guide#Phase 10B — Restore Access|← Back to Mac Reimaging Guide]]

# Restore Access

**Last updated:** 2026-09-01

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
> Two kinds, used sparingly. `[!warning]` **Pitfall** — skipping it costs something you do not get back: state overwritten, a security boundary crossed, or a wrong result that stays quiet until a later phase. `[!bug]` **Troubleshooting** — what to do when a step misbehaves. Everything else is prose, in the paragraph that needed it. A box around an explanation only makes the explanation easier to skip.

---

## Purpose

Restore the access layer that later repo, IDE, application, and project work depend on: SSH identity, TLS trust, JVM trust, shell environment, and credential and license material. Get the Mac to the point where it can authenticate to internal systems and reach services through the expected trust chain before Git restore and application restore start.

**What it sets up**

- **SSH identity** — keys and `~/.ssh/config` copied out of the mounted DMG, with the tight permissions the SSH client insists on, and `known_hosts` rebuilt by probing rather than restored.
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

Every path this runbook reads or writes is defined here, once. Later sections
refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/restore-access.sh              # entrypoint — drives Steps 1–10; every step is also a subcommand
```

Related scripts, alphabetical:

```text
$FRACTOGENESIS_HOME/bin/compare-restored-state.sh      # entrypoint (Step 11 — compares both baselines)
$FRACTOGENESIS_HOME/bin/record-restore-exit.sh         # entrypoint (Step 12 — exit boundary)
$FRACTOGENESIS_HOME/bin/record-restore-prereqs.sh      # entrypoint (Step 0a — entry boundary)
$FRACTOGENESIS_HOME/bin/record-restore-state.sh        # entrypoint (Step 0b before-state, Step 11 after-state)
$FRACTOGENESIS_HOME/bin/restore-staged-loose.sh        # entrypoint (Step 2 — inverse of stage-loose-secrets.sh)
$FRACTOGENESIS_HOME/bin/stage-loose-secrets.sh         # entrypoint (Step 2 — re-sweeps plaintext back behind encryption)
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/                # every artifact this runbook generates lands here
```

Input evidence built by earlier phases:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-*.dmg              # Phase 3C output — mounted read-only
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/                         # certificate staging, mirrored inside the DMG
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/java-security/           # jssecacerts and related JDK trust files
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/keychain-manual-exports/ # manual .cer/.p12 exports for Keychain Access
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/loose-candidates-selected/ # reviewed loose cert/key material staged in Phase 3A
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/cli-credentials/               # per-tool credential exports
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/ssh/                           # SSH keys and config — read by Step 3
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

That list is the image's fourteen categories, and it is authoritative because it
comes from the image itself. Confirm yours without needing the DMG password:

```bash
cat "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/"all-secrets-*-categories.txt
```

What it names is what *this* image happens to carry, not the full scheme. `git/`,
`licenses/` and `package-managers/` are real categories that
`create-secrets-dmg.sh` stages **only when there is applicable material** — no
`~/.git-credentials`, no `.npmrc` worth keeping, no locally-exported license
file, and the category is simply not created. Absent here does not mean
unsupported, and a future image may well carry all three. `cloud/` (AWS) is the
one excluded by design rather than by circumstance: cloud CLIs are
re-authenticated after a reimage rather than restored, so it is never staged. See
[[create-secrets-dmg#What Gets Staged|create-secrets-dmg → What Gets Staged]].

`git/` here means credentials — `~/.git-credentials` and the helper cache.
`~/.gitconfig` is not a credential: it lives in `home-files-backup/dotfiles/` and
Phase 11A restores it. The two are easy to conflate, and they live in different
places.

### Bundle Layout

Everything this runbook writes, under the artifact root named above. Reads are
listed separately in the section before this one; this tree is output only.

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/
boundaries/MANIFEST.md                                           # index of every entry and exit run
boundaries/official/restore-access-entry.txt                     # newest entry run
boundaries/official/restore-access-exit.txt                      # newest exit run
sign-offs/restore-access-exit-YYYYMMDD-HHMMSS.md                 # Step 12 — the rows you answer
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
comparisons/official/restore-access-cert-diff.txt                # newest certificate diff
comparisons/runs/restore-access-cert-diff-YYYYMMDD-HHMMSS/       # Step 4 — comparison.md, deferred.md, rows.tsv
comparisons/official/restore-access-jdk-trust-diff.txt           # newest JDK trust diff
comparisons/runs/restore-access-jdk-trust-diff-YYYYMMDD-HHMMSS/  # Step 6 compare — comparison.md, rows.tsv, pre-existing/
comparisons/official/restore-access-jdk-trust-result.txt         # newest JDK trust install
comparisons/runs/restore-access-jdk-trust-result-YYYYMMDD-HHMMSS/# Step 6 install — result.md, pre-existing/
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
~/.ssh/                              # Step 3 — keys and config from the image; known_hosts seeded by the probe
~/.gitconfig                         # NOT written here — Phase 11A restores it; Step 7 may add http.sslCAInfo
~/.config/git/                       # NOT written here — Phase 11A restores it
~/Library/Keychains/                 # Steps 4-5 — imported certificates, login keychain trust settings
/Library/Keychains/System.keychain   # Step 5 — only if the system-domain trust form is used
$JAVA_HOME/lib/security/             # Step 6 — jssecacerts override, pinned to the Phase 10A JDK
~/.certs/                            # Step 7 — system-and-corp-roots.pem, the CA bundle non-keychain tools read
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

The values this runbook depends on. `REIMAGE_ARTIFACT_ROOT` is resolved and written during `prepare-artifact-root.md`; `REIMAGE_JDK_BASELINE` and `JAVA_HOME` are written during Phase 10A Step 7 and confirmed in Step 0 here.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Artifact root for this reimage event; the mounted DMG, the dotfiles bundle, and `public-certs/` all resolve under it. |
| `REIMAGE_JDK_BASELINE` | The JDK major this machine is pinned to, chosen in Phase 10A Step 7 and recorded in `reimage.env`. Step 6 resolves the trust-store target from it. |
| `JAVA_HOME` | Recorded in `reimage.env` by Phase 10A Step 7, and re-derived from the baseline by Step 6 rather than trusted — a stored absolute path goes stale if the JDK moves. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the toolkit root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 10A (`restore-runtime.md`) is complete: the intended JDK baseline is installed and `java -version` prints it. Its Step 7 records `REIMAGE_JDK_BASELINE` and `JAVA_HOME` in `reimage.env`; the baseline is what decides which JDK Step 6 writes the trust override into when several are present. Step 0 confirms both are set and shows how to set them if they are not.
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

**Every step is safe to re-run, and re-running is how you resume.** If you are
picking this phase back up and cannot recall which steps you finished, run them
again rather than trying to reconstruct it — each one detects the work it already
did and reports that instead of repeating it:

| Step | What a second run reports |
|---|---|
| 1 mount | `already mounted` — the attached image is found, not re-attached |
| 3 ssh | Copies the same content and re-applies the modes; a partial run is completed — **and an identity you deliberately deleted comes back**, see Step 3 |
| 5 trust | `already trusted in the admin domain — nothing to do` |
| 6 java | `already carries the … trust set`, per JDK, computed from the alias set rather than assumed |
| 7 tool-trust | Bundle rebuilt from source, never appended to; `~/.zprofile already carries the block, naming this bundle` |
| 8 dotfiles | Reports only — it never writes |
| 9 credentials | Reports only — it never writes |

The whole phase in order, which is the same thing as resuming it:

```bash
./bin/restore-access.sh
```

Add `--dry-run` to see what the ordered run would do without doing any of it, or
`--from <step>` to start partway. A step that needs you rather than failing —
an admin password, a decision — reports a `GATE` and the run continues; re-run
that step alone once you have passed it.

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

Every block in this runbook shows a `--dry-run` line above the real one; it
prints the table and writes nothing. On **0b** that preview is worth more than
anywhere else. `before` is a first-wins point, so the first capture recorded is
the one that stays official, and a mistimed one cannot be replaced — only
annotated with a pin explaining why it is wrong. Read the target list, confirm it
describes a machine the phase has not touched, then record.

> [!warning] Pitfall
> **0b expires and 0a does not.** The prerequisite check is rerunnable at any
> point and costs nothing to repeat. The before-state cannot be recovered once
> Step 1 mounts the image and Step 3 writes `~/.ssh`: the machine is no longer in
> the state the capture is supposed to describe, and no later run can go back and
> observe it.
>
> `before` is a first-wins point, which compounds it in one specific way. The
> first `before` run you record stays official — so a capture taken late is not
> merely inaccurate, it is the one every comparison uses from then on, and
> rerunning does not replace it. The diff it produces reads "nothing changed",
> which is worse than no diff at all.
>
> If you have already started the phase, still run it — the certificate, JVM
> trust, CA bundle and shell-config targets are untouched until Steps 4-9 — but
> note in the run that Steps 1-3 preceded it, so the comparison is read with that
> in mind rather than at face value.

Most targets will read `absent`. That is correct: this phase is what creates
them, and the point of recording it is so the after-state has something to
differ from. `$JAVA_HOME/lib/security/` reads `unresolved` when this
capture runs before the JDK values are confirmed below — "nothing was checked" is
the honest answer for a target whose path had not resolved yet. Once they are
set it resolves to a real directory, which is the more useful before-state.

| Row | Why it is checked |
|---|---|
| Java resolves via `java_home` | `FAIL`. The only row here that fails **silently** — see below. |
| Toolkit root resolves | `FAIL`. Nothing in this phase works without it. |
| Secrets DMG present | `FAIL`. Step 1 has nothing to mount. |
| direnv hooked, `.envrc` allowed | `WARN`. Recoverable, but later phases assume it. |
| DMG categories sidecar present | `WARN`. Lets you see what the image holds without the password. |
| Build and runtime tooling present | `WARN`. A gap blocks a later phase, not this one. |
| Runtime comparison recorded | `WARN`. Evidence that Phase 10A Step 10 ran. |

The Java row is checked here rather than left to Step 6 because it is the one
that fails invisibly. Step 6 resolves `JAVA_HOME` through
`/usr/libexec/java_home`, and command substitution swallows a non-zero exit — so
`JAVA_HOME` becomes the empty string, the next line writes `jssecacerts` to
`/lib/security/jssecacerts`, which is neither the JDK nor a directory that
exists, and the TLS smoke test afterwards fails for a reason unrelated to the
certificate you just restored. Catching it here costs one command; catching it
there costs an hour.

**Confirm the JDK values this phase reads.** Phase 10A Step 7 chose
`REIMAGE_JDK_BASELINE`, resolved `JAVA_HOME` from it, and wrote both into
`reimage.env`. Neither survives a new terminal on its own, so check them here
rather than discovering an empty one inside Step 6:

```bash
source reimage.env 2>/dev/null || true
printf 'REIMAGE_JDK_BASELINE=%s\n' "${REIMAGE_JDK_BASELINE:-<empty>}"
printf 'JAVA_HOME=%s\n' "${JAVA_HOME:-<empty>}"
```

If both print a value, nothing more is needed — Step 6 re-derives `JAVA_HOME`
from the baseline anyway, and this only confirms the baseline is the one you
expect.

If either is empty, `reimage.env` predates Phase 10A Step 7 or was never written.
Set the baseline to the major Phase 10A installed, resolve `JAVA_HOME` from it,
and record both so the next terminal does not repeat this:

```bash
REIMAGE_JDK_BASELINE="21"
export REIMAGE_JDK_BASELINE
JAVA_HOME="$(/usr/libexec/java_home -v "$REIMAGE_JDK_BASELINE")"
export JAVA_HOME
printf 'JAVA_HOME=%s\n' "${JAVA_HOME:-<empty>}"
```

`/usr/libexec/java_home -V` lists what is actually installed if you are unsure
which major to name. Stop if `JAVA_HOME` printed `<empty>`: the JDK is not linked
into `/Library/Java/JavaVirtualMachines`, which is Phase 10A Step 7's symlink, and
Step 6 has nothing to write into.

Otherwise record both:

```bash
python3 bin/prepare-artifact-root.py \
  upsert-env \
  --env-file reimage.env \
  "REIMAGE_JDK_BASELINE=${REIMAGE_JDK_BASELINE}" \
  "JAVA_HOME=${JAVA_HOME%/}"
```

`upsert-env` writes whatever it is given, including an empty value, and reports
no error when it does — which is why the `<empty>` check above comes first,
rather than trusting the assignment to have worked.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 1 — Mount the Encrypted Secrets DMG

```bash
./bin/restore-access.sh mount
```

It selects the newest `all-secrets-*.dmg` under
`$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/`, prompts for the Phase 3C passphrase,
and prints the mount point it actually got.

**Re-running is safe.** An image already attached is detected and reported rather
than attached a second time, so if you are resuming and cannot recall whether
this ran, run it. That applies to every step in this phase.

Every later step reads from the mounted image; do not copy its contents wholesale
to disk. Steps run through the script find the mount themselves. For a command
you type by hand, ask for the path rather than re-deriving it:

```bash
MNT="$(./bin/restore-access.sh mnt)"
printf 'MNT = %s\n' "$MNT"
```

Ask rather than re-derive, because both obvious ways of working the path out by
hand fail quietly. The mount point is **not** taken from the `.dmg` filename: it
comes from the `-volname` passed to `hdiutil create` back in Phase 3C, and the
two need not match, so `/Volumes/all-secrets-*` can glob to nothing on a
perfectly good image. That is why the script and the `mnt` query both locate the
image by a directory it always carries, `staged-loose/MANIFEST.tsv`, rather than
by name.

A hand-rolled `MNT="$(hdiutil attach …)"` is the same command-substitution
swallow that Step 0's Java row exists to catch. A wrong password, an
already-attached image or a corrupt DMG all exit non-zero, `awk` prints nothing,
and `MNT` becomes the **empty string** — which a bare `echo "$MNT"` renders as a
blank line that looks like output. Every later step then runs against `/`:
copying from `/ssh/*`, reading `/certs/…`, and finally `hdiutil detach ""`. The
one-liner for re-deriving it has the same shape —
`MNT="$(dirname "$(ls -1d /Volumes/*/staged-loose | tail -1)")"` — where no match
means `ls` errors, the inner substitution is empty, and **`dirname ""` returns
`.`**, so `$MNT` silently becomes your current directory and every later
`"$MNT"/ssh/*` reads out of the toolkit checkout. The script fails the step
instead, and the `mnt` query exits non-zero rather than printing nothing.

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

`MISSING` rows are recorded in the manifest but absent from the image, which means the DMG predates the sweep that wrote those rows — check you attached the newest `all-secrets-*.dmg` and not an earlier one.

> [!warning] Pitfall
> This deliberately puts plaintext credentials back onto the artifact drive. That is required for the restore to be complete, but the drive is no longer clean afterwards. Before the artifact root is retired, handed to anyone, or stored long-term, re-run `./bin/stage-loose-secrets.sh --apply` to sweep them back behind the encryption boundary — or wipe the drive.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Restore SSH and Git Access

```bash
./bin/restore-access.sh ssh
```

It copies the image's `ssh/` category into `~/.ssh`, then sets the modes SSH
insists on: `700` on the directory, `600` on every private key, `644` on the
public ones. It reports the counts it applied and lists the host aliases found in
`~/.ssh/config`.

**Re-running is safe.** The copy overwrites with the same content and the modes
are set unconditionally, so a partial earlier run is completed rather than
compounded.

Mode is not cosmetic here. `ssh` refuses a private key that is group- or
world-readable, and the error names permissions rather than the key — which reads
like a missing key on a machine where the key is present and correct. A plain
`cp -R` from a mounted image does not preserve the modes, so the step sets them
itself.

**The step tests each alias itself**, so there is nothing to type. For every
`Host` in `~/.ssh/config` it seeds the host key with `ssh-keyscan`, then probes
non-interactively and reports the greeting, the error, or a stall.

> [!warning] Pitfall
> **Re-running this step reverses a deletion.** It copies the whole `ssh/`
> category every time, so an identity you retired by removing it from `~/.ssh`
> is back the next time Step 3 runs — with the right mode, reported as a
> success, and indistinguishable in the output from one that was supposed to be
> there.
>
> The image cannot be corrected: it is an encrypted, immutable capture of the
> machine before the erase, and the retired key is legitimately part of what that
> machine had. So the retirement lives only on this Mac, and only until the next
> re-run.
>
> **Record it with `./bin/record-decision.sh` when you retire one**, naming the
> comparison it excepts:
> `--runbook restore-access --title "Retired <key>" --excepts comparisons/restore-access-inventory-diff`.
> That appends to `reimaged-system/restore-notes/decisions.md`, and a later run
> that sees the key flagged can ask `--check restore-access-inventory-diff` and
> get the answer instead of re-deciding it. Nothing else in the workflow can tell
> your deletion from an accident: Step 12 counts private keys and checks their
> modes, and passes identically either way.
>
> The same applies to `known_hosts`. Deleting it is a reasonable choice; Step 12
> will `WARN` about it on every close-out, and answering that row is where you
> say so.

**`known_hosts` is rebuilt here, not restored.** Do not assume the image carries
one — Phase 3A stages the `ssh/` category as it finds it, and a machine whose
`known_hosts` was absent or was excluded contributes none. What fills the file is
the probe, one `ssh-keyscan` per `Host` in `~/.ssh/config`.

That has a specific edge, and it is the reason to care: **only the `Host` names
present in the file at probe time get seeded.** A host you reach by its real name
rather than through a `Host` block is not probed and not seeded, so its first
connection prompts. So is a host whose `Host` name changes after this step runs:
[[restore-git#Step 3 — Write `~/.ssh/config` with Dual Host Aliases|restore-git.md]]
rewrites `~/.ssh/config` wholesale in Phase 11A, and a name that differs from the
one the image carried was never probed here. Re-run the probe after that rewrite
rather than assuming this step covered it. That prompt is
harmless at a shell and expensive inside
[[restore-repos#Step 3 — Execute the Clone Commands|Phase 11B's clone loop]], which
is not waiting for an answer. If `git clone` stalls on an unfamiliar host later,
this is why.

Check what landed, and re-run this step alone if the file is empty or missing:

```bash
wc -l < "$HOME/.ssh/known_hosts"
```

```bash
./bin/restore-access.sh ssh
```

Step 12's **SSH host keys seeded** row reports the same thing, counted against
the number of aliases in `~/.ssh/config`.

Leave the testing to the step rather than typing a bare `ssh -T <alias>`. That
command blocks on the host-key prompt — which, in a pasted block, is answered by
whatever line follows it — and it can then hang indefinitely *after* the key is
accepted. `ConnectTimeout` does not save you: it bounds the TCP connect, and that
stall comes later. The probe seeds the host key first and carries its own
watchdog, giving up at 20 seconds.

If you do test by hand, test an alias and never a bare hostname. A bare host has
no `IdentityFile`, so SSH offers no key and the test fails for a reason unrelated
to the keys you just restored.

> [!bug] Troubleshooting
> If an alias stalls with no output after the host key, see [[#An SSH alias hangs after the host key is accepted|An SSH alias hangs after the host key is accepted]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Restore Certificates and Keychain Material

**First ask the machine, not the image.** On a managed Mac, enrollment in Phase 8
usually installs the corporate CA chain through a configuration profile, so some
or all of what this step would import is already present before you start. The
step is scoped to the *gap*, and the gap is invisible from either listing alone.

```bash
./bin/restore-access.sh certs
```

That identifies the corporate root on the image and writes a comparison run under
`reimaged-system/comparisons/`, context `restore-access-cert-diff`, holding
`comparison.md`, `deferred.md` and `rows.tsv`. Open the comparison:

```bash
CMP="$REIMAGE_ARTIFACT_ROOT/reimaged-system/comparisons"
open "$CMP/$(cat "$CMP/official/restore-access-cert-diff.txt")/comparison.md"
```

It opens with **What to install**, and that section is the answer. Nothing else
in the file is an action.

| Section | What to do with it |
|---|---|
| **What to install** | The result. Import these; check `Role` and `CA` on each first. |
| **Deferred — decided against, not lost** | The count and the two reasons. Itemised in `deferred.md`. |
| **The corporate chain** | How the pieces relate. Read this when a row surprises you. |
| **How that number was reached** | The arithmetic, if the count surprises you. |
| **Already installed by enrollment** | Keep. Do not import over them. |
| **In the keychains only** | Context. Nothing here is an action. |

**What to install is narrower than "on the image and not installed."** Two
subtractions produce it, and they answer different questions:

| Subtraction | Question it answers |
|---|---|
| minus what is already in a keychain, minus the built-in public roots | *Is this already trusted?* |
| minus what has expired, minus what chains to no authority this organisation owns | *If it is not, is it something to act on?* |

The second subtraction is why a capture holding 130-odd public CAs does not
produce 130 things to do. Membership of the corporate chain is resolved by
issuer, transitively from the pinned root — the root, whatever it issued,
whatever those issued in turn — and certificates already in a keychain take part
in that walk, so a corporate intermediate that enrollment installed still
vouches for its children on the image.

Each row is one distinct certificate. A certificate staged twice on the image —
once as PEM, once as DER, or once loose and once inside a bundle — is one
decision, so its source paths are joined into a single row rather than repeating
it. A bundle contributes each certificate in it separately, cited as
`<path>#<n>`.

Two things are deliberately left out of the comparison, and both would be
noticeable if the exclusion ever failed. `certs/java-security/` is not compared
at all: those are the per-JDK `jssecacerts` truststores, full of public roots — a
JVM trust store, not something to import into the login keychain. They belong to
[[#Step 6 — Restore Java Trust Overrides|Step 6]], which decides per JDK whether
to take the captured store wholesale or merge only its additions. A public CA
turning up under **What to install** would be this exclusion failing.

The built-in public roots are the other. A capture can carry a whole CA bundle,
and most images do; where it does, nearly everything in it is the public trust
store this Mac already has. Those are counted as public roots and deliberately
not listed — there are typically 130-odd of them, none is an action, and listing
them buries the handful that are. The corporate certificates are what is left
once they are subtracted.

#### Root, intermediate, leaf — only one of them is a trust decision

**What to install** can be non-empty and still require nothing of you, and the
`Role` column is what tells the difference.

| Role | What it is | Is installing it a decision? |
|---|---|---|
| **root** | Self-signed: it vouches for itself. | **Yes.** Installing a root asserts that you believe it. There is normally exactly one. |
| **intermediate** | Signed by the root. | **No.** It is valid because the root is trusted. A correctly configured TLS server sends its intermediates with the leaf, so a client needs its own copy only against a server that fails to send the chain — and the fix for that is normally the server. |
| **leaf** | An endpoint or client identity. | **Never.** Re-enrollment reissues these; see the Pitfall below. |

So a **What to install** list made entirely of intermediates, under a root that is
already in the keychain, is a list of things that are almost certainly
unnecessary. Installing them anyway is harmless. Leaving them out costs nothing
and is easy to revisit. The report says so explicitly when that is the case.

**The corporate chain** section lays out every certificate on either side that
chains to the root, ordered root first, with where each one lives. The buckets
sort by *where* a certificate is; this sorts by *what it is*, which is what makes
the pieces legible as one structure rather than a list of fingerprints. Three
things it exists to settle:

- **Two intermediates with different subjects under one root are siblings, not
  versions of each other.** A two-tier PKI commonly runs one issuing CA per
  network zone or directory namespace — which is what the `DC=` components name,
  so `DC=dmz, DC=certprod` and `DC=com, DC=afginc, DC=ga` are two different
  places, not one place renamed. Neither supersedes the other, and enrollment
  having installed one says nothing about whether you need the other.
- **Two certificates with the same subject and different fingerprints are one CA
  renewed** — the same issuing authority, re-issued with a new validity window.
  That is one decision, not two.
- **An intermediate whose `notAfter` matches the root's exactly is not a
  coincidence, and not evidence that two certificates are the same one.** An
  intermediate cannot outlive its issuer, so a CA that issues with a clamped
  lifetime stamps every intermediate with the root's own expiry. Two unrelated
  intermediates under one root routinely share an expiry to the second.

The chain also shows this Mac's own client identity, if enrollment issued one,
sitting under whichever intermediate signed it — which is the most direct
evidence of which issuing CA is actually in use here.

#### Nothing is discarded silently

Every certificate the phase declines to import is written to **`deferred.md`** in
the same run directory, with its subject, issuer, dates, fingerprint, source path
on the image, and the reason it was left alone. Two reasons exist:

| `Why` | What it means | Could it be the cause of a later failure? |
|---|---|---|
| `expired` | Past `notAfter`. | Almost never. Nothing can chain to it today, so installing it changes nothing; a host that still needs that authority needs the *renewed* one, which arrives through enrollment. |
| `not the corporate chain` | Current, but issued by nobody this organisation owns — a public CA the Phase 3A capture swept up. | Possibly. Most were dropped from the system trust store deliberately, and a distrusted root is one to leave uninstalled — but a partner or vendor endpoint can legitimately depend on one. |

`deferred.md` carries the command to inspect any single one before deciding,
including how to pull one member out of a bundle — `openssl x509` reads only the
*first* certificate in a file, so a source cited `<path>#<n>` has to be split
first.

**You do not have to decide now.** Skipping all of them is the correct default:
the corporate chain is what this phase exists to restore, and the rest are
leftovers of a capture that swept broadly on purpose. Come back only if something
fails in a way that looks like a missing CA — TLS refusing an internal host, a
build unable to verify a repository, a proxy rejecting a certificate.

Even then, the honest test is the failing connection itself rather than the list:

```bash
openssl s_client -connect <host>:443 -showcerts </dev/null 2>/dev/null | grep -E '^ *[0-9] s:|^ *[0-9] i:'
```

The topmost issuer is the authority that has to be trusted. If it is not in
`deferred.md`, nothing skipped here is the problem.

The report is a snapshot, and re-running is how it is refreshed. Each run of
`./bin/restore-access.sh certs` rebuilds the comparison from the live keychains,
so anything installed since drops off the deferred list by itself. The newest run
is always the current answer to *what is still outstanding*, and the older runs
stay in the index as the record of what was outstanding when. That is also the
answer to "which ones did I end up not installing": install what you decide to,
re-run, and the deferred list in the new run is exactly the remainder.

#### Reading the rest of the report

**The root is pinned from a file on the mounted image, and that is correct even
when enrollment already installed it.** A keychain stores certificates, not
files, and both `security add-trusted-cert` in Step 5 and the CA bundle in Step 7
need a file — the image is where one exists. It is not a *different* root:
matching is on SHA-256, so a row appearing under **Already installed by
enrollment** is byte-identical to what enrollment delivered, and Step 5 then
finds it already trusted and does nothing. That is the correct outcome, not a
skipped step.

**Already installed by enrollment** is an intersection, so it can never be larger
than the number of certificates the image carries. If it looks small next to a
keychain listing you ran by hand, that is why — the hand listing is closer to
**In the keychains only**, which is usually the biggest section here. Both counts
also exclude the ~150 built-in public roots, because `security find-certificate`
searches the login and System keychains and not
`SystemRootCertificates.keychain`.

**Import only what is on the image and not installed.** The installed copy is the
one to keep: it arrived through the channel that also carries its trust settings
and that MDM re-delivers, while the file on the image is a snapshot of a chain
that may since have been rotated. Importing a certificate that is already present
is not harmful, but it hides the more useful fact — that enrollment already did
the work, and so a certificate that is *missing* means enrollment did not, which
is a different problem with a different fix.

Matching is on SHA-256 and never on label, which matters more than it sounds: the
same CA is routinely filed under a different name in a keychain than in a file on
the image, and a name-based comparison reports a certificate as missing when it
is installed under another one.

> [!warning] Pitfall
> Read the `CA` column before Step 5. A `CA:FALSE` row in **What to install** is
> a **leaf**, usually the old machine's client identity, swept up by Phase 3A
> because it was credential-shaped. Re-enrollment issues a new one, so restoring
> the old is at best inert and at worst confusing later — two client certs for
> the same subject, one of them dead. Marking one Always Trust is worse: it tells
> the system to trust a single endpoint's certificate as though it were an
> authority.

An empty **What to install** section is a clean result rather than a failed run:
it means enrollment installed everything the image carries, and Step 5 becomes a
verification instead of an action. An empty **Already installed by enrollment**
section is the opposite — on a managed Mac, enrollment not having delivered the
chain is itself the finding.

Presence is not trust, either. A certificate can be installed and carry no trust
settings at all; Step 5 is about the second thing, and these are what it reads:

```bash
security dump-trust-settings 2>/dev/null; echo "--- admin domain ---"; security dump-trust-settings -d 2>/dev/null
```

**See what the image carries, if you need the layout.** Phase 3A stages
certificates into more than one place, and the comparison names each row's source
path — but the tree itself is sometimes worth seeing:

```bash
ls -R "$MNT/certs"
```

`keychain-manual-exports/` holds a `.p12` only when a Keychain identity was **exportable**, and on a managed Mac many are not — the export refuses with *"The contents of this item cannot be retrieved."* Where that happened the directory holds Phase 3A's review notes and no certificate, and the reviewed cert material sits under `loose-candidates-selected/` instead; Phase 3A's notes there record which identities refused and why. Non-exportable identities are re-issued by re-enrollment, and no backup can restore them.

Pin the corporate root once, from whatever the listings above showed, and reuse it in Steps 5 and 7:

```bash
CORP_CERT="$MNT/certs/<subdirectory>/<filename>"
ls -l "$CORP_CERT"
```

Then read it. Most captures are PEM, so try that first:

```bash
openssl x509 -in "$CORP_CERT" -inform PEM -noout -subject -issuer -dates
```

Only if that errors, the file is DER:

```bash
openssl x509 -in "$CORP_CERT" -inform DER -noout -subject -issuer -dates
```

Whichever prints a subject, issuer, and validity window is the format — note it, because Step 7 needs it. If neither prints, the file is not a certificate.

Run them as separate commands rather than chaining them with `&&` and `||`. Chained, the DER attempt fires whenever *anything* to its left failed — including a mistyped path — so a wrong `$CORP_CERT` produces a screen of `OSSL_DECODER` and `STORE routines` errors that read as a corrupt certificate rather than a bad path. Suppressing the first form's errors to keep the chain readable makes it worse: the run that actually needed a diagnostic is the one whose diagnostic was thrown away.

Then import **only what the keychain listing showed was missing** — matched by
`sha256`, and only files that reported `CA:TRUE`. Open the folder in Finder and
drag each one into the target keychain (usually `login`), entering the password
if prompted:

```bash
open "$MNT/certs"
```

Reference the reviewed non-secret material under `$REIMAGE_ARTIFACT_ROOT/public-certs/` if you need to check which cert is which.

`open -a "Keychain Access" <directory>` does not work — Keychain Access opens certificate *files*, not folders — so use plain `open` to reveal the directory in Finder, then drag from there.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Trust the Internal Root Certificate

`jssecacerts` in the next step only covers JVM tools. Non-Java tools (curl, git, browsers) rely on the macOS keychain trust settings instead, so the internal **root** needs its trust set explicitly.

**An intermediate does not, and should not get one.** A root is a *trust anchor*: nothing above it vouches for it, so trust has to be asserted directly. An issuing or intermediate CA is vouched for by the root, and once the root is trusted the chain validates by itself.

Giving an intermediate its own Always Trust makes it a second, independent anchor. If the organisation later revokes or replaces the root, that intermediate stays trusted regardless — and intermediates rotate far more often than roots, so the override goes stale and starts bypassing the chain it was meant to follow.

**Check what is already there before changing anything.** On a managed Mac, enrollment in Phase 8 commonly configures this, and the step becomes a verification:

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

**Confirm the trust change took, against a real endpoint.** macOS `curl` reads the keychain, so an internal HTTPS host that failed before this step should succeed after it — with no `--cacert`, no `CA_BUNDLE`, and nothing from Step 7 in place yet:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' https://<an-internal-https-host>
```

Any HTTP status is a pass: the response code means TLS validated. A `curl: (60) SSL certificate problem` means it did not, and that is the failure the entry below is about. This is also the cleanest demonstration of where Step 5 ends and [[#Step 7 — Trust the Corporate CA Outside the Keychain|Step 7]] begins — `curl`, `git` and the browsers are done once the keychain is right; npm, pip, `requests` and the JVM carry their own trust stores and need Step 7 regardless.

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

Two things make this command fail confusingly if you assemble it by hand. A
wildcard inside double quotes is never expanded by the shell, so
`"$MNT/certs/.../root-ca.cer"` is a real resolved path while
`"/Volumes/all-secrets-*/certs/.../root-ca.cer"` is a literal string that returns
"No such file or directory". And mixing `-d` with
`-k "$HOME/Library/Keychains/login.keychain-db"` asks for the admin domain while
pointing at a user keychain — it errors, or writes trust somewhere you did not
intend. Resolve the path first with the `ls -l` above, then run exactly one of
the two forms.

> [!warning] Pitfall
> **Always Trust belongs to exactly one certificate here: the internal root.** Not an intermediate — see above. Not a leaf, ever: Step 4's `CA:FALSE` check exists to catch those, and marking one Always Trust tells the system to treat a single endpoint's certificate as an authority. And not an unverified certificate of any kind — confirm the `sha256` against something you trust before asserting trust in it. If in doubt, leave it at "Use System Defaults" and revisit; that setting is the safe default precisely because it defers to the chain.

> [!bug] Troubleshooting
> If the `curl` check above still reports an SSL certificate problem, see [[#The trust change did not take — Always Trust is on the wrong certificate|The trust change did not take — Always Trust is on the wrong certificate]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 6 — Restore Java Trust Overrides

**This step is review, then act — two commands.** The first compares and
installs nothing:

```bash
./bin/restore-access.sh java
```

It walks every JDK under `/Library/Java/JavaVirtualMachines`, finds that JDK's
captured store on the image, works out what the capture adds over the JDK's own
`cacerts`, and writes the comparison. Then it stops and tells you what to run
next. Naming a mode is how you say yes:

```bash
./bin/restore-access.sh java --jssecacerts merge
```

```bash
./bin/restore-access.sh java --jssecacerts copy
```

There is no default mode, deliberately. Installing a JVM trust store has real
consequences under either form, and the comparison is what makes the choice
answerable — asking for it at a confirmation prompt asked at the one moment you
had least information, because the report had just been written and not yet read.

**The two passes write two different documents, because they answer different
questions.** Re-running the comparison on the way into an install would produce a
third copy of a decision already made; what an install has to record is what came
of it.

| Pass | Context | Holds |
|---|---|---|
| compare | `restore-access-jdk-trust-diff` | `comparison.md` — the decision: what the capture holds, what it adds over stock, what `copy` would discard. |
| install | `restore-access-jdk-trust-result` | `result.md` — the outcome: what each JVM trusted before, what it trusts now, and every entry that moved either way. |

**The comparison run** is written under
`reimaged-system/comparisons/`, context `restore-access-jdk-trust-diff`, and
prints the path. Read it before choosing a mode. Per JDK it holds:

| Section | What it answers |
|---|---|
| Identity | Which JDK this section is about: its version, its `Contents/Home` path, the `jssecacerts` that would be written, and whether it is the `REIMAGE_JDK_BASELINE` JDK. Every installed JDK gets its own section. |
| Counts | What each form produces, as a number. |
| **Added by the capture** | Exactly what `merge` imports — alias, **role**, subject, issuer, expiry, and whether it has expired. The only entries being decided. |
| **Stock only** | What `copy` would discard: CAs this JDK ships that the old machine's store did not have. |
| **This JDK's stock trust set** | Every CA the JDK trusts today, before anything is installed. |

#### Not every added entry is a CA

The added rows are exported and read individually, so `Role` and `Expires` are
each certificate's own facts rather than the keystore's claim about them. That
matters because a JVM trust store accumulates two very different things.

| Role | What it is | What trusting it means |
|---|---|---|
| `root` / `intermediate` | A certificate authority. | Every host it signs validates, now and after every renewal. |
| **`leaf`** | A **pinned server certificate** — one specific host. | That host validates until its certificate is renewed, at which point it silently stops and has to be re-imported by hand. |

A `leaf` in a trust store is the fingerprint of an earlier workaround: someone
hit a TLS failure against an internal service and imported *that server's own
certificate* rather than the CA that issued it. Java accepts any
`trustedCertEntry` as a trust anchor, so it works — which is why the workaround
survives, and why it keeps having to be redone.

Read the `Issuer` column against the CA rows in the same table. If the issuing
CA is also in the list, trusting **it** covers every host it signs and the pinned
leaves are redundant.

`Expires` earns the same attention. An expired entry in a trust store is inert:
importing it cannot make a connection succeed. If a service depended on a pinned
certificate that has since lapsed, that service is failing right now for a reason
no reimage caused — and the durable fix is the issuing CA, not another pinned
certificate with a new date on it.

```bash
CMP="$REIMAGE_ARTIFACT_ROOT/reimaged-system/comparisons"
open "$CMP/$(cat "$CMP/official/restore-access-jdk-trust-diff.txt")/comparison.md"
```

**`merge` produces a superset of stock, not the additions alone.** The base of
the file is a byte copy of this JDK's own `cacerts`, and the added aliases are
imported on top: 127 stock entries plus 2 additions gives a store of 129. The
confirmation prompt names only the additions because those are the only entries
being *decided*, and it states the resulting size alongside them for exactly this
reason.

The two forms differ in one place, and it is what each **drops**:

| | `merge` | `copy` |
|---|---|---|
| Starts from | this JDK's `cacerts` | the captured file |
| Adds | the added aliases | the added aliases |
| Discards | nothing | every stock-only entry |
| Restores | nothing | every entry the capture held that this JDK has since dropped |

**Re-running is safe.** A JDK whose `jssecacerts` already carries the intended
alias set is reported as done and skipped. That set is computed, not assumed, so
a file left by an interrupted run — or by the other form below — is correctly
seen as *not* done.

**Two forms, and the default is `merge`.**

| Form | What it installs | When it is right |
|---|---|---|
| `merge` *(default)* | This JDK's current `cacerts`, plus only the aliases the capture adds. | Always defensible; necessary once the capture is more than a few months old. |
| `copy` | The captured store, wholesale. | A same-week capture, where the public-root set has not moved. |

```bash
./bin/restore-access.sh java --jssecacerts copy
```

> [!warning] Pitfall
> **`jssecacerts` does not *add* to `cacerts` — the JVM uses it instead of
> `cacerts` when the file exists.** So `copy` replaces the JDK's entire trust set
> with the old machine's, public roots included, frozen at the date of capture;
> vendors distrust public CAs between releases, and an old store keeps trusting
> what the new JDK deliberately dropped.
>
> Read the alias list before confirming, under either form. "Adds over stock"
> means everything the capture has that this JDK does not — the internal CAs
> **and** any public root the JDK vendor has distrusted since the capture. No
> signal in a certificate separates them: a CA is corporate because of who runs
> it. An unfamiliar public root in that list is one this JDK dropped on purpose,
> and importing it puts it back.

#### What the install records

`result.md` is a before-and-after, per JDK, against **the trust store that was
actually there** — the previous `jssecacerts` where one existed, and the JDK's
stock `cacerts` where none did, because that is what the JVM was really using. A
diff against an empty file would report 150 additions that are not additions.

| Section | What it answers |
|---|---|
| Identity | Version, the `jssecacerts` written, what it was compared against, entries before and after, and where the backups are. |
| **Added** | What this JVM trusts now and did not before — read back from the *installed* file, so the role and expiry describe what is actually trusted rather than what was intended. |
| **Removed** | What this JVM trusted before and does not now. |

**Removed is where `copy` becomes legible.** Its cost is not what it adds but
what it drops, and no amount of before-the-fact comparison shows that as
concretely as the list of authorities this JVM no longer trusts. Under `merge`
the section normally reads "Nothing" — which is the claim `merge` makes about
itself, verified against the installed file rather than asserted.

A `copy` that dropped two roots, followed later by a `merge`, shows those two
roots returning under **Added**. The pair of documents is a history of what this
JVM trusted and when.

**Existing trust stores are backed up twice.** The compare pass copies every
`jssecacerts` that already exists into `pre-existing/<jdk-name>-jssecacerts`
inside the comparison run, before anything is installed and whichever mode you
later choose. The install pass separately keeps
`jssecacerts.pre-reimage-<stamp>` beside the JDK.

Two copies because they fail differently: the sibling is the one to reach for
when reverting a bad install, and the one in the run directory is the one that
still exists after the JDK is upgraded or removed, which takes its whole
directory — and the sibling backup with it — along the way. The file being
replaced is not recoverable from the JDK install itself. Under `merge` it builds the new store in `/tmp` and installs it only
once every alias imported — a half-imported store is a JVM trusting an arbitrary
subset of the corporate chain.

Afterwards it reports how many trusted entries the installed store holds. Under
`merge` that should be the JDK's stock count plus the additions — the same number
the prompt named — and a count at or near the additions alone means the public
roots did not come across, which the step says out loud.

Declining is recorded, not lost. The comparison run is written before the prompts
and is not conditional on the answer, so a JDK you decline still has a dated,
indexed record of what it was offered and what it trusts. Re-running writes a
fresh run and re-asks.

A JDK with no counterpart on the image is reported rather than skipped silently.
The image captured one store per JDK **by name**, so a JDK installed after the
capture, or at a different version, has none — and that JVM has no corporate
trust until one is put there.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 7 — Trust the Corporate CA Outside the Keychain

Step 5 taught macOS to trust the internal root. It taught nothing else: `npm`,
`git`, `pip`, `curl`, Node and Python each carry their own trust store and none
of them reads the keychain.

```bash
./bin/restore-access.sh tool-trust
```

It exports the root, builds the bundle, points every store at it, and smoke-tests
each one.

**Re-running is safe.** The bundle is rebuilt from source rather than appended
to, and the `~/.zprofile` block is guarded by a `REIMAGE-CA-BUNDLE` marker — a
second run reports the block is already there instead of adding another.

#### The root is an ingredient; the bundle is the output

The corporate root is an ingredient; the bundle is what Step 7 produces from it.

| Path | What it is | Holds |
|---|---|---|
| `$MNT/certs/loose-candidates-selected/root-gaig-ca.pem` | a **source** — the corporate root as the image captured it | 1 certificate |
| `~/.certs/system-and-corp-roots.pem` | the **output** — the CA bundle this step builds | ~159: every system root, plus that 1 corporate root |

Step 7 does not point your tools at the root. It *builds a trust store* and
points them at that, because `npm`, `git`, `pip`, `curl`, Node and Python all
**replace** their trust store with the file you name rather than adding to it —
so a file holding the corporate root alone would break every host the corporate
CA did not issue, which on a network that intercepts internal traffic only is
most of the internet. The name says what is in it for that reason.

Confirm what actually landed. Ask the script for the path rather than naming it
— `CA_BUNDLE` is a variable *inside* `restore-access.sh` and is not set in your
shell:

```bash
BUNDLE="$(./bin/restore-access.sh bundle)"
printf 'bundle: %s\n' "$BUNDLE"
grep -c 'BEGIN CERTIFICATE' "$BUNDLE"
```

A number in the 150s, not `1`. To count what it holds as certificates rather
than as PEM headers:

```bash
openssl crl2pkcs7 -nocrl -certfile "$BUNDLE" | openssl pkcs7 -print_certs -noout | grep -c 'subject='
```

**There is no `$CA_BUNDLE` in your shell**, and reaching for one fails in a way
that reads like a missing bundle rather than a missing variable. The
`~/.zprofile` block Step 7 writes exports `NODE_EXTRA_CA_CERTS`,
`CURL_CA_BUNDLE`, `REQUESTS_CA_BUNDLE` and `PIP_CERT` — deliberately, because
those are the names the tools themselves read. `CA_BUNDLE` is internal to
`restore-access.sh`. So `grep -c 'BEGIN CERTIFICATE' "$CA_BUNDLE"` expands to
`grep -c 'BEGIN CERTIFICATE' ""` and reports `grep: : No such file or
directory`, and `source ~/.zprofile` does not help because the variable was
never there to load. Resolve the path with `./bin/restore-access.sh bundle`, or
use `$CURL_CA_BUNDLE`, which the block does export.

**It takes the root from wherever it is**, trying three sources in order:

| Order | Source                         | When it applies                                                                       |
| ----- | ------------------------------ | ------------------------------------------------------------------------------------- |
| 1     | `--tool-trust PATH`            | You named the file outright.                                                          |
| 2     | The login and System keychains | Usually. Step 5 put the root there, and this is the copy the machine is really using. |
| 3     | The mounted image              | An ordered run, which has a mount.                                                    |

The keychain is tried before the image on purpose. **Running one step alone has
no mounted image** — `$MNT` lives in the process that mounted it, and
`./bin/restore-access.sh tool-trust` is a new process — so a step that could only
read the image would fail every time it was re-run on its own, which is the
normal way to redo one step. Do not re-mount the image just for this step.

If none of the three yields a root, the step names all three and what each one
found, then stops without touching the bundle. The way out is whichever of these
matches your situation:

```bash
./bin/restore-access.sh certs
```

```bash
./bin/restore-access.sh tool-trust --corp-cert "$MNT/certs/loose-candidates-selected/<file>"
```

```bash
./bin/restore-access.sh --from tool-trust
```

The first re-runs Step 4, which finds and reports the root. The second asserts it.
The third mounts the image and continues the ordered run from here.

The run says which source it used, because "the bundle was built" and "the bundle
was built from the copy you meant" are different claims.

Which source it used does not change what you get. Step 4's comparison matches on
SHA-256, so a root appearing under **Already installed by enrollment** is
byte-identical to the file on the image — the same certificate reached by two
routes. A run reporting `corporate root taken from the login/System keychain`
built the same bundle it would have built from
`certs/loose-candidates-selected/root-gaig-ca.pem`, and did it without needing
the image mounted.

**The bundle is the system roots *plus* the corporate root, not the corporate
root alone.** Every consumer configured here — npm's `cafile`, git's
`sslCAInfo`, `CURL_CA_BUNDLE`, `REQUESTS_CA_BUNDLE`, `PIP_CERT` — **replaces**
its trust store with this file rather than adding to it. A corporate-root-only
bundle therefore breaks every endpoint the corporate CA did not issue, which on a
network that intercepts internal hosts only is most of the internet. The step
warns and continues if it cannot export the system roots, because a bundle of one
root is worth having and worth knowing about.

Three similarly-named things pass through this step, and conflating them is the
confusion it generates most:

| Name | Kind of value |
|---|---|
| `CORP_CERT` | A path to a certificate file on the mounted image. |
| `ROOT_CN` | A certificate common name, as it appears in a keychain listing. |
| `CA_BUNDLE` | The fixed destination path the tools are pointed at. |

**The smoke tests force each tool to use the bundle**, which is not decoration.
Run without forcing, three of the five measure the system keychain instead and
pass while the bundle is broken: macOS `curl` and `git` consult the keychain
regardless of `CURL_CA_BUNDLE` and `http.sslCAInfo`, and `urllib.request` reads
`ssl.get_default_verify_paths()` and never looks at `REQUESTS_CA_BUNDLE` at all.
`npm` is the only one of the five that honours its own setting unprompted —
which is why, in the run that produced this note, npm was the only test to report
a real misconfiguration while the other four reported success.

They hit public endpoints on purpose: a public endpoint is what a
corporate-root-only bundle cannot validate, so it is the case worth testing.

**Expect `SKIP npm` on a first pass.** npm arrives with Node, which Phase 10A
Step 8 installs, so if you are running this phase before that one has finished
the tool is not there to configure. A `SKIP` is the step reporting that honestly
rather than claiming success — re-run the step afterwards, which is safe to
repeat and configures whatever has since appeared.

> [!bug] Troubleshooting
> If a smoke test fails, the step prints the first four lines of that tool's own
> error underneath it. A bare `FAIL` says something is wrong and nothing about
> what, and these five fail for entirely unrelated reasons.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 8 — Restore Shell Environment and CLI Config

```bash
./bin/restore-access.sh dotfiles
```

It compares each shell file against the backup and reports one of `NO BACKUP`,
`BACKUP ONLY`, `SAME` or `DIFFERS`. **It changes nothing** — this step is a
report, and the merging is yours.

**The merge runs one way: backup → `$HOME`.** The backup is the read-only side
of every command in this step. Nothing here writes to it, and nothing later in
the workflow rebuilds it.

Review a differing file, then merge by hand:

```bash
F=".zshrc"
git diff --no-index --color=always "$HOME/$F" "$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/$F" | less -R
```

Left column is `$HOME` — what this machine has now. Right column is the backup —
what the erased machine had. You are building the left one.

> [!warning] Pitfall
> **`home-files-backup/dotfiles/` is the only surviving record of the pre-image
> machine, and editing it is not recoverable.** The DMG holds secrets, not shell
> config; a Time Machine snapshot has it only if Phase 5 ran and you still have
> the disk. Nothing in this workflow rebuilds that capture — `backup-home.md`
> runs before the erase, and the machine it captured is gone.
>
> The danger is not that the risk is obvious and ignored; it is that both paths
> look alike. The diff command opens two files of the same name in one pager,
> and the second one is the irreplaceable one. Editing the wrong pane, or
> saving into the wrong window a few minutes later, produces no error.
>
> **An edited capture keeps reporting, and keeps sounding certain.** After a
> `.zshrc` is edited on the backup side, this step still prints `DIFFERS`, or
> `SAME` — and neither is distinguishable from the honest verdict. The
> comparison quietly becomes your new configuration measured against itself,
> which is the failure mode this whole phase is built to avoid, arriving through
> the one file nobody thought to protect.
>
> If you want to try a merge before committing to it, copy the backup file to
> `/tmp` and edit there. Open the artifact root read-only in your editor if it
> offers that.

`.zprofile` is the one file to never copy over wholesale, in either direction. On
this machine it carries Phase 10A's Homebrew and nvm bootstrap *and* Step 7's
CA-bundle block, none of which exists in a pre-image backup — overwriting it
undoes both, and the failure surfaces later as tools that cannot find their trust
store. In the other direction it is worse: a `.zprofile` copied *onto* the backup
records a CA bundle that did not exist until this phase ran, so the capture
starts asserting something about the old machine that was never true.

`BACKUP ONLY` means the file exists in the backup and not on this machine. There
is nothing here to merge into, so copying it is a decision rather than a merge —
read it first, because a pre-image `.zshrc` can reference paths this machine does
not have yet.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 9 — Restore Credentials and License Material

```bash
./bin/restore-access.sh credentials
```

It reports which credential categories the image carries — `cli-credentials`,
`git`, `package-managers`, `licenses` — as `PRESENT` with a file count or
`ABSENT`. **It restores nothing**, and that is the point: most of what is in
these categories should be re-issued rather than copied.

**Re-authenticate rather than restore.** A stored token was issued to the old
machine's session. Copying it forward can work, silently keeps a credential that
should have been rotated with the rebuild, and leaves you unable to tell which of
the two happened. Where the tool has a login flow, use it:

```bash
gh auth login
```

The step notices whether `gh` is installed. If the image carries `gh/hosts.yml`
and `gh` is not here yet, it says to defer: Phase 12 installs `gh`, and
`gh auth login` afterwards is the whole restore for it.

Licenses come back through each vendor's own flow, not by copying activation
files. An activation record copied from another machine is usually inert, and
occasionally counts against a seat limit.

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

Detach by `"$MNT"` and never by `/Volumes/all-secrets-*`. If the volume name does not match the DMG filename the glob expands to nothing, `hdiutil detach` fails on a literal path, and the mounted plaintext secrets are left sitting on `/Volumes/` — usually unnoticed, because the step "ran". If `$MNT` is no longer set in this shell, re-derive it with the snippet in Step 1.

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
| `**CARRIED FORWARD**` | That value came back. Remove it with `git config --global --unset http.sslverify`, and, if one internal host genuinely needs it, scope it to that host as [[restore-git#An internal Enterprise Server host fails TLS verification|restore-git.md → Troubleshooting]] describes. |
| `**MISSING**` | Recorded pre-image, absent now. On this phase that is trust or identity, not a tool a later phase installs. |
| `— **decided**` | Appended to whatever verdict precedes it. The difference is real and the verdict still says so; the marker adds that it was deliberately accepted and the reason is in `decisions.md`. A retired SSH key is the usual case: the DMG is immutable and legitimately still holds it, so this row would otherwise be flagged on every future run. Record one with `./bin/record-decision.sh --excepts restore-access-inventory-diff:<row>`. |

`Git credential.helper` and `Git init.defaultBranch` reading `**MISSING**` here
is expected: `restore-git.md` (Phase 11A) owns the global Git configuration and
has not run yet. Re-run this comparison after Phase 11A — that is also when
`http.sslverify` could come back, so a `correctly dropped` verdict now is not the
final answer on that row.

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

Expect `~/.certs/system-and-corp-roots.pem` as **added** (Step 7), `System.keychain` as
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

`bin/record-restore-prereqs.sh` and `bin/record-restore-exit.sh` are one pair per
phase boundary, not one per runbook. This phase runs the `10B` entry check at
Step 0 and the `10B` exit check here; it never runs Phase 11A's entry check, and
never re-runs its own entry check at the end.

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

### An SSH alias hangs after the host key is accepted

The symptom is specific: the host key prompt appears and is answered, `Warning:
Permanently added …` prints, and then nothing. No greeting, no error, no prompt
back.

That is not a key problem. The keys are being offered fine — the connection never
gets far enough to use them. TCP completes, the small early packets are exchanged,
and the session stalls at `SSH2_MSG_KEX_ECDH_REPLY`, which is the first **large**
packet. A path along the way is dropping packets above a certain size without
reporting it: a path-MTU black hole, typically through a VPN tunnel.

Confirm it rather than assuming, from the tunnel MTUs and a sized ping:

```bash
ifconfig | grep -A1 '^utun' | grep mtu
ping -c1 -D -s 1472 github.com
ping -c1 -D -s 1300 github.com
```

A large `-s` failing while a smaller one passes is the black hole. `-D` sets
don't-fragment, so the packet is dropped rather than split.

`ConnectTimeout` will not bound this — it covers the TCP connect, which succeeded.
Press Ctrl-C, or use the step's own probe, which carries a watchdog.

**This is a network path, not something to fix on the Mac.** Two things follow
from it:

- Another host on the same protocol may be fine. Internal and public destinations
  routinely take different egress paths, so an internal Git host can work on port
  22 while the public one does not. Test the internal alias before concluding the
  keys are broken.
- Where the public host is genuinely unreachable over SSH, use HTTPS with a
  personal access token for those remotes instead, and record the substitution.
  Port 443 is not automatically an escape: a TLS-inspecting proxy will accept the
  connection and then close it, since SSH-over-443 is not TLS.

Phase 11A ([[restore-git|restore-git.md]]) is where that substitution is made and
recorded; a blocked public host is a legitimate `known-blocked` row there rather
than a failure of this step.

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
that arrived with enrollment.

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

### The trust change did not take — Always Trust is on the wrong certificate

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
BUNDLE="$(./bin/restore-access.sh bundle)"
grep -c 'BEGIN CERTIFICATE' "$BUNDLE"
```

A count of `1` means Step 7's combine did not happen and the bundle carries only
the corporate root. That is enough for an intercepted connection and not enough
for one that reaches the real internet untouched — and `cafile`, like
`CURL_CA_BUNDLE`, **replaces** the trust store rather than adding to it, so
every public endpoint then fails. `node` passes through the same breakage
because `NODE_EXTRA_CA_CERTS` **adds** instead of replacing, which is exactly
why `npm` can fail while `node` succeeds against the same registry. Rebuild:

```bash
BUNDLE="$(./bin/restore-access.sh bundle)"
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain \
  > /tmp/ca-combined.pem
cat "$BUNDLE" >> /tmp/ca-combined.pem
grep -c 'BEGIN CERTIFICATE' /tmp/ca-combined.pem
cp /tmp/ca-combined.pem "$BUNDLE"
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
