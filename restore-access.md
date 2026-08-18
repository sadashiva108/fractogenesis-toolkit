[[reimaging-guide#Phase 10B — Restore Access|← Back to Mac Reimaging Guide]]

# Restore Access

**Last updated:** 2026-08-18

Restore the identity, trust, and credential layer on the reimaged Mac after the runtime toolchain is in place — SSH keys and Git access, certificates and keychains, Java trust overrides pinned to the JDK from Phase 10A, shell and CLI configuration, and license or activation material. Everything here comes out of the encrypted secrets DMG and the reviewed dotfiles bundle built during the pre-image phases; this runbook is manual and does not run a fractogenesis-toolkit entrypoint.

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
    - [[#Step 2 — Restore Files Swept by the Phase 3B Loose-Secret Sweep|Step 2 — Restore Files Swept by the Phase 3B Loose-Secret Sweep]]
    - [[#Step 3 — Restore SSH and Git Access|Step 3 — Restore SSH and Git Access]]
    - [[#Step 4 — Restore Certificates and Keychain Material|Step 4 — Restore Certificates and Keychain Material]]
    - [[#Step 5 — Trust Imported Root and Issuing CA Certificates|Step 5 — Trust Imported Root and Issuing CA Certificates]]
    - [[#Step 6 — Restore Java Trust Overrides|Step 6 — Restore Java Trust Overrides]]
    - [[#Step 7 — Trust the Corporate CA Outside the Keychain|Step 7 — Trust the Corporate CA Outside the Keychain]]
    - [[#Step 8 — Restore Shell Environment and CLI Config|Step 8 — Restore Shell Environment and CLI Config]]
    - [[#Step 9 — Restore Credentials and License Material|Step 9 — Restore Credentials and License Material]]
    - [[#Step 10 — Eject the DMG and Clean Up Plaintext|Step 10 — Eject the DMG and Clean Up Plaintext]]
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

The runbook is script-free by design. Every restore is a small manual copy, `security` command, or Keychain Access GUI action, and each one carries a judgment call — is this key still the current one, should this cert really be Always Trust, does this dotfile still match how the machine is used — that a script cannot make. The encrypted DMG built in Phase 3C is the single source of truth for the secret-bearing material; the reviewed dotfiles bundle from Phase 2B is the single source of truth for shell and CLI config.

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

Every path this runbook reads is defined here, once.

This runbook is manual apart from one entrypoint:

```text
$FRACTOGENESIS_HOME/bin/restore-staged-loose.sh   # entrypoint — Step 2; inverse of bin/stage-loose-secrets.sh
```

Input evidence built by earlier phases:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-*.dmg              # Phase 3C output — mounted read-only
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/                         # certificate staging, mirrored inside the DMG
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/java-security/           # jssecacerts and related JDK trust files
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/keychain-manual-exports/ # manual .cer/.p12 exports for Keychain Access
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/cli-credentials/               # per-tool credential exports
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/git/                           # ~/.gitconfig and ~/.config/git/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/licenses/                      # license keys, offline activation files
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/package-managers/              # npm, cargo, and similar credential stores
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/ssh/                           # SSH keys, config, known_hosts
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/staged-loose/                  # Phase 3B sweep + MANIFEST.tsv — read by Step 2
$REIMAGE_ARTIFACT_ROOT/home-files-backup/dotfiles/                      # reviewed shell/CLI config subset
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
| `JAVA_HOME` | Set explicitly in Step 6 to the JDK installed in Phase 10A before dropping in `jssecacerts`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 10A (`restore-runtime.md`) is complete: JDK 21 (or the intended baseline) is installed and `java -version` prints it.
- The external artifact volume is mounted and `reimage.env` resolves. `ls "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted"` should list at least one `all-secrets-*.dmg`.
- You have the DMG password from your password manager or wherever it was stored in Phase 3C. Do not proceed without it.

> [!bug] Troubleshooting
> `hdiutil attach` failing with "authentication error" almost always means the wrong password. If the password is correct, verify the DMG isn't already mounted (`hdiutil info | grep all-secrets`) — a leftover mount from an earlier attempt will refuse a second attach.

### Confirm Your Intent

- Are you doing a **full first-time restore** (Steps 1 through 10 in order) or a **targeted rerun** of one area (for example, just re-importing a certificate that was missed)? Both are safe; the difference is whether you also do Step 8's selective shell restore.
- Which **shell files** are you willing to overwrite versus merge? The default is *merge* — comparing each file in a diff tool before adopting changes. Blanket overwrites are a common way to lose machine-specific tweaks.
- Which **secret categories** are actually in scope for this restore? If a category is empty on the DMG (say, no Postman exports were taken), skip its step rather than inventing a source.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. The order enforces a trust chain: SSH before Git access, keychain trust before Java trust, JDK trust before shell restore, credentials last of the identity-adjacent material, DMG eject last of all.

### Step 1 — Mount the Encrypted Secrets DMG

Mount the newest DMG read-only-ish; macOS mounts DMGs read-write by default, and that's fine here because the DMG is the source, not a target:

```bash
DMG="$(ls -1 "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/"all-secrets-*.dmg | sort | tail -1)"
MNT="$(hdiutil attach "$DMG" | awk -F'\t' '/\/Volumes\//{print $NF}' | tail -1)"
echo "$MNT"
```

Enter the password when prompted. Confirm the mount:

```bash
hdiutil info | grep -A1 all-secrets
ls "$MNT"/
```

> [!warning] Pitfall
> The mount point is **not** derived from the `.dmg` filename. It comes from the `-volname` passed to `hdiutil create` back in Phase 3C, and the two need not match — so `/Volumes/all-secrets-*` can glob to nothing on a perfectly good image. Capture `$MNT` here and use it in every step below, including the detach in Step 10: if that glob fails, the command silently does nothing and the plaintext secrets stay mounted.

Every subsequent step reads from `"$MNT"`; do not copy the DMG's contents wholesale to disk.

`$MNT` lives only in the shell that ran the attach. If you continue in a new terminal, re-derive it from a directory the image always carries rather than from the filename:

```bash
MNT="$(dirname "$(ls -1d /Volumes/*/staged-loose | tail -1)")"
echo "$MNT"
```

> [!bug] Troubleshooting
> If `hdiutil attach` reports the image as corrupt, see [[#`hdiutil attach` says the DMG is corrupt|`hdiutil attach` says the DMG is corrupt]].

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

### Step 3 — Restore SSH and Git Access

SSH first because everything else that talks to GitHub or an internal Git server needs it.

Copy the SSH material into place:

```bash
mkdir -p ~/.ssh
cp -R "$MNT"/ssh/* ~/.ssh/
cp -R "$MNT"/git/. ~/    # copies ~/.gitconfig and ~/.config/git/
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
> The full Git identity workflow (work vs personal routing, per-repo `.gitconfig`, dual-identity `~/.gitconfig`) belongs to [[restore-git|restore-git.md]] in Phase 11A. This step is only about SSH reachability.

> [!bug] Troubleshooting
> If SSH prompts for the key passphrase in every new shell, see [[#SSH keeps prompting for a passphrase every session|SSH keeps prompting for a passphrase every session]].

### Step 4 — Restore Certificates and Keychain Material

Import certificates from the reviewed manual exports. Do this in Keychain Access rather than by shell copy, so each import goes into the correct keychain and you can inspect the result immediately:

```bash
open -a "Keychain Access" "$MNT/certs/keychain-manual-exports/"
```

For each `.cer` or `.p12` file, drag it into the target keychain (usually `login`) and enter the password if prompted. Reference the reviewed non-secret material under `$REIMAGE_ARTIFACT_ROOT/public-certs/` if you need to double-check which certs are which.

### Step 5 — Trust Imported Root and Issuing CA Certificates

`jssecacerts` in the next step only covers JVM tools. Non-Java tools (curl, git, browsers) rely on the macOS system and login keychain trust settings instead, so any internal root or issuing CA cert imported in Step 4 still needs its trust set explicitly.

Open Keychain Access and adjust trust in the GUI:

```bash
open -a "Keychain Access"
```

1. Search the `login` and `System` keychains for the internal root and issuing CA certificates.
2. Double-click each certificate and expand the **Trust** section.
3. Set **When using this certificate** to **Always Trust**.
4. Close the window and enter your password to save the change.

CLI equivalent, if you prefer to script the trust change instead of using the GUI. Pick **one** of the two forms below — they target different trust domains and must not be combined.

**1. User domain (login keychain, no root needed)** — trusts the CA for your account only. This is the form to use here:

```bash
CERT="$MNT/certs/keychain-manual-exports/root-ca.cer"
ls -l "$CERT"
security add-trusted-cert -r trustRoot -k "$HOME/Library/Keychains/login.keychain-db" "$CERT"
```

**2. System domain (admin trust, all users)** — the alternative, only if the CA must be trusted machine-wide:

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CERT"
```

`-d` selects the admin/system trust domain and requires root; it belongs with `/Library/Keychains/System.keychain` and `sudo`, never with your login keychain.

> [!warning] Pitfall
> Two ways this command fails silently or confusingly. First, a wildcard inside double quotes is never expanded by the shell — `"$MNT/certs/.../root-ca.cer"` is a real resolved path, but `"/Volumes/all-secrets-*/certs/.../root-ca.cer"` is a literal string and returns "No such file or directory". Second, mixing `-d` with `-k "$HOME/Library/Keychains/login.keychain-db"` asks for the admin domain while pointing at a user keychain; it errors or writes trust somewhere you did not intend. Resolve the path first (the `ls -l` above), then run exactly one of the two forms.

> [!warning] Pitfall
> Only mark a certificate as **Always Trust** if it is the company's actual internal root or issuing CA. Doing this for an arbitrary or unverified certificate opens the machine to trust attacks. If in doubt, leave the certificate's trust at "Use System Defaults" and revisit.

> [!bug] Troubleshooting
> If `curl` still fails against an internal endpoint after the trust change, see [[#`curl` still fails against internal endpoints after Step 5|`curl` still fails against internal endpoints after Step 5]].

### Step 6 — Restore Java Trust Overrides

Only restore `jssecacerts` after confirming the target JDK is the one installed in Phase 10A — the file lives inside a specific JDK's `lib/security/` directory and does nothing if it lands next to a different JDK.

Pin `JAVA_HOME` explicitly, and stop if it does not resolve:

```bash
JAVA_HOME="$(/usr/libexec/java_home -v 21 2>/dev/null)"
if [ -n "$JAVA_HOME" ] && [ -d "$JAVA_HOME/lib/security" ]; then
  export JAVA_HOME
  printf 'JAVA_HOME=%s\n' "$JAVA_HOME"
  ls -la "$JAVA_HOME/lib/security"
else
  printf 'JDK 21 did not resolve (JAVA_HOME=%s). Stop here.\n' "${JAVA_HOME:-<empty>}" >&2
  printf 'Go back to Phase 10A (restore-runtime.md) and install/link the JDK before continuing.\n' >&2
fi
```

Copy the reviewed override into place, asserting the target is a real JDK first:

```bash
if [ -d "$JAVA_HOME/lib/security" ]; then
  cp "$MNT/certs/java-security/jssecacerts" "$JAVA_HOME/lib/security/jssecacerts"
  ls -l "$JAVA_HOME/lib/security/jssecacerts"
else
  printf 'Refusing to copy: %s is not a JDK security directory.\n' "${JAVA_HOME:-<empty>}/lib/security" >&2
fi
```

Depending on how the JDK was installed, `$JAVA_HOME` may be root-owned — if the `cp` reports "Permission denied", rerun that one line with `sudo` and then confirm the file is readable by all (`chmod 644`).

> [!warning] Pitfall
> Do not run `export JAVA_HOME="$(/usr/libexec/java_home -v 21)"` unguarded. If JDK 21 is missing, `java_home` prints its error to stderr and exits non-zero, `export` still succeeds, and `JAVA_HOME` ends up **empty**. The next `cp` then expands to the absolute path `/lib/security/jssecacerts`, which is not a JDK — it either fails with "No such file or directory" or, under `sudo`, writes a stray trust store at the filesystem root that no JVM ever reads. You would see a clean-looking command and no working Java trust.

> [!note]
> Homebrew's `openjdk@21` is keg-only, so `/usr/libexec/java_home` will not see it until it is linked into the system JDK directory:
>
> ```bash
> sudo ln -sfn "$(brew --prefix openjdk@21)/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-21.jdk
> /usr/libexec/java_home -V
> ```

Validate an internal TLS use case afterward — the simplest smoke test is a `curl` or `gradle` call against an internal endpoint that requires the corporate root.

### Step 7 — Trust the Corporate CA Outside the Keychain

Steps 4 through 6 covered the macOS keychain and the JVM. That is not everything. With TLS interception on the corporate network, npm, Node, pip, Homebrew's `curl`, and Git over HTTPS each consult their **own** bundled CA file and never read the macOS keychain, so they keep failing with `SELF_SIGNED_CERT_IN_CHAIN` or `unable to get local issuer certificate` long after Keychain Access says the root is trusted. Do this now, not at the first broken `npm install` in Phase 11B or 12.

**1. Export the intercepting root to a stable path:**

The most reliable source is the reviewed export already on the DMG — convert it to PEM:

```bash
mkdir -p ~/.certs
openssl x509 -inform DER -in "$MNT/certs/keychain-manual-exports/root-ca.cer" -out ~/.certs/corp-root.pem
```

If the file is already PEM, `openssl` will say so; just copy it instead. To pull it back out of the keychain rather than the DMG, list the CA labels and export by common name:

```bash
security find-certificate -a /Library/Keychains/System.keychain | grep '"labl"'
security find-certificate -a -c "<Root CA common name>" -p \
  /Library/Keychains/System.keychain "$HOME/Library/Keychains/login.keychain-db" \
  > ~/.certs/corp-root.pem
```

Confirm you got a certificate and not an empty file:

```bash
grep -c 'BEGIN CERTIFICATE' ~/.certs/corp-root.pem
openssl x509 -in ~/.certs/corp-root.pem -noout -subject -issuer -dates
```

**2. Node and npm:**

```bash
printf '\nexport NODE_EXTRA_CA_CERTS="$HOME/.certs/corp-root.pem"\n' >> ~/.zprofile
export NODE_EXTRA_CA_CERTS="$HOME/.certs/corp-root.pem"
npm config set cafile "$HOME/.certs/corp-root.pem"
```

**3. Git over HTTPS and Homebrew's `curl`:**

```bash
git config --global http.sslCAInfo "$HOME/.certs/corp-root.pem"
printf '\nexport CURL_CA_BUNDLE="$HOME/.certs/corp-root.pem"\n' >> ~/.zprofile
export CURL_CA_BUNDLE="$HOME/.certs/corp-root.pem"
```

SSH remotes are unaffected — this only matters for HTTPS remotes, which is what most tooling and CI helpers default to.

**4. Python (pip, requests, and anything built on them):**

```bash
printf '\nexport REQUESTS_CA_BUNDLE="$HOME/.certs/corp-root.pem"\nexport PIP_CERT="$HOME/.certs/corp-root.pem"\n' >> ~/.zprofile
export REQUESTS_CA_BUNDLE="$HOME/.certs/corp-root.pem"
export PIP_CERT="$HOME/.certs/corp-root.pem"
pip config set global.cert "$HOME/.certs/corp-root.pem"   # optional, persists outside the shell
```

**5. Smoke-test each store before moving on:**

```bash
curl -sSI https://registry.npmjs.org/ >/dev/null && echo curl-ok
node -e "require('https').get('https://registry.npmjs.org/', r => console.log('node-ok', r.statusCode))"
npm ping
git ls-remote https://github.com/git/git >/dev/null && echo git-ok
python3 -c "import urllib.request; urllib.request.urlopen('https://pypi.org/simple/'); print('py-ok')"
```

> [!note]
> If the interception uses an intermediate issuing CA as well as a root, the bundle needs both. Concatenate them into the same file — `cat root.pem issuing.pem > ~/.certs/corp-root.pem` — and re-run the smoke tests; a bundle may hold any number of PEM blocks.

> [!warning] Pitfall
> `~/.zprofile` only reaches processes started from a login shell. GUI apps launched from the Dock or Spotlight — IntelliJ, VS Code, Docker Desktop — do not see `NODE_EXTRA_CA_CERTS` or `REQUESTS_CA_BUNDLE` and will still fail. Launch them from a terminal, or set the variable in the app's own run configuration. And never "fix" this with `npm config set strict-ssl false`, `GIT_SSL_NO_VERIFY=1`, or `pip --trusted-host`: those disable verification instead of establishing trust, and they tend to survive into places you did not intend.

> [!bug] Troubleshooting
> `SELF_SIGNED_CERT_IN_CHAIN` after all of the above almost always means the tool is reading a different config than you set. Check what it actually resolved: `npm config get cafile`, `git config --get http.sslCAInfo`, `python3 -c "import ssl; print(ssl.get_default_verify_paths())"`, and `echo "$NODE_EXTRA_CA_CERTS"`. A per-repo `.npmrc` or a project-local `.git/config` overrides the global setting.

### Step 8 — Restore Shell Environment and CLI Config

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
.gitconfig                # already restored in Step 3; skip if unchanged
.shell_common.sh
.shell_local.sh
.config/
.kube/
.cf/
.azure/
```

Prefer selective merge over blind copy for machine-specific files — the `.zprofile` on this Mac already has the Homebrew and `nvm` bootstrap added in Phase 10A, and overwriting it would remove those.

### Step 9 — Restore Credentials and License Material

Credential-bearing material stays inside the DMG until the moment it is needed. Restore only through supported flows:

Typical sources on the mounted volume:

```text
$MNT/cli-credentials/    # per-tool credential exports (aws profile files, kube credentials, etc.)
$MNT/licenses/           # app license keys, serial numbers, activation files
$MNT/package-managers/   # npm, cargo, and similar credential stores
```

For each application license or activation file:

1. Use the application vendor's supported import or reactivation flow — not a manual copy of an activation file unless the vendor explicitly documents that path.
2. Keep copied activation files out of Git and OneDrive unless separately approved.
3. Record only redacted restore notes in plain Markdown, under `$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/`.
4. Remove any temporary plaintext copies after the app is activated and validated.

> [!warning] Pitfall
> Screenshots or PDFs of subscription pages that contain private identifiers still count as secret material. They belong under `secrets-encrypted/licenses/`, not under `public-certs/` or a general notes folder.

### Step 10 — Eject the DMG and Clean Up Plaintext

Eject the DMG once every restore that reads from it is done:

```bash
hdiutil detach "$MNT"
hdiutil info | grep -c all-secrets   # expect 0
```

> [!warning] Pitfall
> Detach by `"$MNT"`, never by `/Volumes/all-secrets-*`. If the volume name does not match the DMG filename the glob expands to nothing, `hdiutil detach` fails on a literal path, and the mounted plaintext secrets are left sitting on `/Volumes/` — usually unnoticed, because the step "ran". If `$MNT` is no longer set in this shell, re-derive it with the snippet in Step 1.

Before you detach, check [[#DMG Categories Restored By Hand|DMG Categories Restored By Hand]] below — several categories on the image have no step anywhere in the toolkit, and once the DMG is ejected and the artifact drive retired they are gone.

Sweep for any temporary plaintext copies you may have made outside the DMG (Downloads, Desktop) and remove them. The DMG is the durable copy; nothing plaintext should remain on disk after this step.

Confirm the exit criteria before moving on to `restore-git.md`:

| Area | Expected result |
|---|---|
| SSH | `ssh -T git@github.com` prints the expected identity line. |
| Git config | `git config --global user.email` returns the intended identity. |
| Keychain trust | Internal root and issuing CAs are marked Always Trust in the login keychain. |
| Java trust | `jssecacerts` is present under `$JAVA_HOME/lib/security/`, and an internal TLS smoke test succeeds. |
| Non-keychain trust | `npm ping`, `git ls-remote` over HTTPS, and a Python HTTPS fetch all succeed with no TLS error. |
| By-hand categories | Every row in [[#DMG Categories Restored By Hand\|DMG Categories Restored By Hand]] is either restored or consciously skipped. |
| Shell config | `.zprofile` retains the Homebrew and `nvm` bootstrap from Phase 10A; adopted files were reviewed, not blindly copied. |
| Credentials and licenses | Each application in scope is activated through its supported flow; no plaintext activation files remain on disk outside the DMG. |
| DMG | Detached from `/Volumes/`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## DMG Categories Restored By Hand

These categories exist on the secrets DMG but have no restore step here and no runbook anywhere else in the toolkit. Walk the list once, while the image is still mounted (`ls "$MNT"`), and restore or consciously skip each one. Nothing downstream will remind you.

| Category on the DMG | Restore by hand |
|---|---|
| `gnupg/` | Copy back to `~/.gnupg`, then `chmod 700 ~/.gnupg` and `chmod 600 ~/.gnupg/*` — `gpg` refuses a world-readable home. Verify with `gpg --list-secret-keys`; re-set `trust` on your own key if signing fails. |
| `cloud/` (AWS) | Copy `credentials` and `config` into `~/.aws/` at mode `600`. Prefer re-running `aws sso login` or re-issuing keys over restoring long-lived access keys; confirm with `aws sts get-caller-identity`. |
| `kube/` | Copy the kubeconfig to `~/.kube/config` at mode `600`. Cluster tokens are usually expired — re-auth through the cluster's exec/OIDC plugin, then `kubectl config get-contexts`. |
| `claude/` | Put `claude_desktop_config.json` back under `~/Library/Application Support/Claude/` and restart Claude Desktop so it re-reads the file. |
| `claude-code/` | Restore `.claude.json` to `~/.claude.json`. It carries MCP server definitions plus account and org identifiers — review it before restoring, drop entries for machines or projects that no longer exist, and re-authenticate rather than trusting any token inside it. |
| `raycast/` | Restore through Raycast's own flow (Settings → Advanced → Import), not by copying files. The `.rayconfig` export is password-protected; you need the password from Phase 3C. |
| `chrome/` (`*Passwords*.csv`) | **Intentionally not restored.** Passwords come back through the password manager, which is the system of record. The CSV exists only as a break-glass copy and must be destroyed along with the DMG — never imported into the new browser profile. |

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

Three failures here have fixes long enough to break the flow of the step that surfaces them. Each step links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### `hdiutil attach` says the DMG is corrupt

Verify the DMG on disk before assuming it is unrecoverable:

```bash
hdiutil verify "$DMG"
```

If verification fails, fall back to the previous timestamped `all-secrets-*.dmg` in the same directory. If both fail, rebuild the image with `create-secrets-dmg.md` on the source machine — this runbook does not repair DMGs. Attach the working DMG the same way, confirm the mount, then carry on.

[[#Step 3 — Restore SSH and Git Access|⮕ Continue to Step 3 — Restore SSH and Git Access]]

### SSH keeps prompting for a passphrase every session

The keys are correct but not added to the ssh-agent. Add them once per session:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

For persistence, add an `AddKeysToAgent` directive to `~/.ssh/config`; that is a shell config change, not an SSH restore fix.

[[#Step 4 — Restore Certificates and Keychain Material|⮕ Continue to Step 4 — Restore Certificates and Keychain Material]]

### `curl` still fails against internal endpoints after Step 5

The certificate was imported but Always Trust was set on the *end-entity* certificate rather than the root or issuing CA. Only root and issuing CAs earn Always Trust; leaf certs should stay at "Use System Defaults" and rely on the chain. Reopen the certificate in Keychain Access, reset the leaf to "Use System Defaults", and set Always Trust on the internal root or issuing CA instead.

[[#Step 6 — Restore Java Trust Overrides|⮕ Continue to Step 6 — Restore Java Trust Overrides]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link,
  except Troubleshooting, whose back-link sits under its intro and whose routed
  symptom subsections stay out of the Table of Contents.
-->
