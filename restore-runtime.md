[[reimaging-guide#Phase 10A — Restore Runtime Libraries|← Back to Mac Reimaging Guide]]

# Restore Runtime

**Last updated:** 2026-08-17

Rebuild the non-secret runtime and toolchain layer on the reimaged Mac — Xcode Command Line Tools, Homebrew, Java and the JVM build tools, Node via `nvm`, and the platform CLIs — before any secret material or repository work begins. This runbook is manual by design; every install is `xcode-select`, `brew`, or `nvm` and there is no fractogenesis-toolkit entrypoint to drive it. The captured pre-image and post-image system inventories from Phases 4B and 13B are the reference for what "restored" means here.

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
    - [[#Step 1 — Install Rosetta 2|Step 1 — Install Rosetta 2]]
    - [[#Step 2 — Install Xcode Command Line Tools|Step 2 — Install Xcode Command Line Tools]]
    - [[#Step 3 — Install Homebrew|Step 3 — Install Homebrew]]
    - [[#Step 4 — Update Homebrew and Run Diagnostics|Step 4 — Update Homebrew and Run Diagnostics]]
    - [[#Step 5 — Install direnv and Restore the Repo Environment Hook|Step 5 — Install direnv and Restore the Repo Environment Hook]]
    - [[#Step 6 — Install Java and the JVM Build Tools|Step 6 — Install Java and the JVM Build Tools]]
    - [[#Step 7 — Install and Manage Node Versions|Step 7 — Install and Manage Node Versions]]
    - [[#Step 8 — Install Platform CLIs and Helper Utilities|Step 8 — Install Platform CLIs and Helper Utilities]]
    - [[#Step 9 — Compare Versions Against Captured Inventories|Step 9 — Compare Versions Against Captured Inventories]]
    - [[#Step 10 — Confirm Readiness for Restore Access|Step 10 — Confirm Readiness for Restore Access]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Restore the non-secret runtime layer — the compiler and package-manager stack, JVM tooling, Node, and platform CLIs — that every later restore phase depends on. Get the machine to the point where it can build, install packages, and run the expected local tooling without pulling in secrets, credentials, or repository state too early.

**What it sets up**

- **Rosetta 2** — installed on Apple silicon so Intel-only installers and binaries encountered later in the restore can run at all.
- **Xcode Command Line Tools** — installed and verified, so the compiler and linker later build tooling depends on are present.
- **Homebrew** — installed, brought up to date, and put through a diagnostic pass before packages are added.
- **`direnv` and its zsh hook** — reinstalled so `FRACTOGENESIS_HOME` repopulates on `cd` into this checkout, which every later runbook's command examples assume.
- **The JVM layer** — the JDK baseline plus Gradle, Maven, and Groovy, with the keg-only JDK linked where macOS actually looks for it.
- **Node via `nvm`** — version management and per-project Node installs, kept deliberately outside the Homebrew chain.
- **Platform CLIs and helper utilities** — Cloud Foundry CLI, `fly`, `jq`, `kotlin`, `wget`, `yq`, and similar tools.
- **A version comparison** — the rebuilt runtime checked against the captured pre-image and post-image system inventories, so drift is either an approved-newer version or an investigated finding.

**What the rest of the workflow relies on it for**

- **The Java trust override** — Phase 10B restores `jssecacerts` into the JDK installed here, and that override has to match the JDK actually present.
- **Git, IDE, and application restore** — Phase 11 onward assumes the compiler, package-manager, JVM, and Node layers already exist before repository and app work begins.
- **The post-image inventory comparison** — the Phase 13B capture records this rebuilt runtime layer as the post-image side of the inventory pair.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| Rosetta 2 on Apple silicon, Xcode Command Line Tools install and verification, and the Homebrew install, update, and diagnostic pass | SSH keys, certificates, Java trust overrides (`jssecacerts`), shell/CLI credentials, and licenses — `restore-access` (Phase 10B) |
| the JVM layer — JDK, Gradle, Maven, Groovy, and the `/Library/Java/JavaVirtualMachines` symlink for the keg-only JDK | managed enrollment, MDM baseline, and stabilization restarts — `enroll-and-stabilize` (Phase 8) |
| Node version management via `nvm` and per-project Node installs | day-one usability sign-off and the first post-image Time Machine backup — `verify-reimaged-system` (Phase 9) |
| `direnv` and its zsh hook, plus Cloud Foundry CLI, `fly`, `jq`, `kotlin`, `wget`, `yq`, and similar platform tools | Git identity plumbing, SSH host aliases, and the clone template for re-cloning repositories — `restore-git` (Phase 11A) |
| the version comparison against the captured pre-image and post-image system inventories | the system-inventory captures themselves — `capture-system-inventory` (Phase 4B / 13B) |

This runbook can be rerun. Every step is idempotent (Homebrew and `nvm` skip anything already installed at the requested version), so a partial run can be resumed without a special mode.

> [!warning] Pitfall
> If IT or company policy also provides an official automated workstation-setup project or script, review it before running it *here*. It may reinstall Homebrew, overwrite shell profile changes, or install a different Java or Node version than what this runbook and the captured pre-image evidence expect. Run it deliberately — first or last, not interleaved with this runbook — and reconcile any conflicts rather than running both blindly.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The order is a hard bootstrap chain, not a preference: Rosetta 2 goes first on Apple silicon because an Intel-only installer met later in the chain fails opaquely without it, Xcode Command Line Tools have to be present before Homebrew installs cleanly, Homebrew has to be present before `direnv` and the JVM and Node stacks, and the JVM has to be in place before Phase 10B tries to restore the `jssecacerts` Java trust override — that override has to match the JDK that is actually installed. Node stays out of the Homebrew chain intentionally: it is installed via `nvm` so a project can switch versions per repo without a PATH collision with a `brew install node`.

The runbook is script-free by design. Every step is a small, standard installer command that either succeeds cleanly or fails in a way the reader will investigate; automating around Homebrew and `nvm` here would obscure the diagnostic surface those tools already print. The captured pre-image system inventory under `$REIMAGE_ARTIFACT_ROOT/system-inventory/pre-image-*/` and its post-image sibling are the reference for what "restored" looks like — the final step compares the fresh install against them.

### Terminology

| Term | Meaning |
|---|---|
| Runtime layer | The non-secret toolchain (CLT, Homebrew, JDK, Node, build tools, platform CLIs). Not shell profiles or credentials. |
| Pre-image inventory | The `system-inventory/pre-image-YYYYMMDD-HHMMSS/` bundle captured in Phase 4B. |
| Post-image inventory | The `system-inventory/post-image-YYYYMMDD-HHMMSS/` bundle captured in Phase 13B after restore completes. Not available yet during this phase; used later for the audit. |
| Approved-newer version | A newer tool version than the pre-image had, chosen intentionally because the older one is unsupported or has a known issue. Not a drift. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path this runbook reads or writes is defined here, once.

This runbook is manual and does not run a fractogenesis-toolkit entrypoint:

```text
$FRACTOGENESIS_HOME/bin/    # no primary script — this runbook is executed by hand
```

Input evidence used for comparison in Step 9:

```text
$REIMAGE_ARTIFACT_ROOT/system-inventory/pre-image-YYYYMMDD-HHMMSS/
$REIMAGE_ARTIFACT_ROOT/system-inventory/post-image-YYYYMMDD-HHMMSS/    # only present after Phase 13B
```

The complete `system-inventory/` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Artifact root for this reimage event; used to locate the captured system inventory for version comparison. |
| `FRACTOGENESIS_HOME` | Repository root for this toolkit checkout; used only to keep command examples portable. Set by your shell startup / `.envrc`, not stored in `reimage.env`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 8 (`enroll-and-stabilize.md`) closed out with a clean managed baseline, and Phase 9 (`verify-reimaged-system.md`) signed off day-one usability. If either is still open, close it first.
- The reimaged Mac has internet access. Homebrew, `nvm`, JDK downloads, and every platform CLI install below hit the network.
- The external artifact volume is mounted and `reimage.env` resolves so Step 9 can read the pre-image inventory. If it isn't mounted yet, do Steps 1–8 anyway and reconnect the drive before Step 9.

> [!bug] Troubleshooting
> `xcode-select --install` returning "command line tools are already installed" on a freshly reimaged Mac usually means a leftover receipt from the previous install. Confirm the active path with `xcode-select -p`; if it points to nothing, `sudo rm -rf /Library/Developer/CommandLineTools` and rerun the install.

### Confirm Your Intent

- Are you doing a **greenfield** restore (all steps in order) or a **targeted rerun** of one step (e.g. installing an additional platform CLI that Phase 2 didn't capture)? Both are safe; the difference is whether you also do Step 9's comparison at the end.
- Which **Java baseline** does the machine need? The default here is JDK 21; if a specific project requires 8, 11, or 17, install that in addition — do not replace the baseline.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. Every step is a dependency for at least one later step: Rosetta before any Intel-only installer, CLT before Homebrew, Homebrew before `direnv`, the JVM, and the CLIs, JVM before Phase 10B's Java trust override work.

### Step 1 — Install Rosetta 2

Nothing else in this workflow installs Rosetta 2, and a freshly imaged Apple silicon Mac does not have it. Until it is present, every Intel-only binary you meet later — vendor and IT installers, older JDK and CLI builds, `linux/amd64`-only Docker images run through emulation, and several corporate desktop apps — fails with a "bad CPU type in executable" or a generic "cannot be opened" dialog rather than anything that says *Rosetta*. Install it first so that failure mode never enters the picture.

Install it non-interactively:

```bash
softwareupdate --install-rosetta --agree-to-license
```

Confirm an Intel slice actually executes:

```bash
arch -x86_64 /usr/bin/uname -m
```

That must print `x86_64`. Do not move on until it does.

> [!note]
> On an Intel Mac this step is a harmless no-op — `softwareupdate` reports that Rosetta is not applicable to this architecture and exits, and the `arch` check still prints `x86_64` because it runs natively. Run it unconditionally rather than branching on architecture. No reboot is required on either architecture; translation is available as soon as the install finishes.

### Step 2 — Install Xcode Command Line Tools

Install first because Homebrew and later build tooling may depend on the compiler and linker they provide.

Trigger the installer:

```bash
xcode-select --install
```

Confirm the active developer tools path resolves:

```bash
xcode-select -p
pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null || true
clang --version
git --version 2>/dev/null || true
```

Do not move on until `xcode-select -p` prints a valid path.

### Step 3 — Install Homebrew

Install Homebrew using the official installer:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

On Apple silicon, add the shell bootstrap so `brew` is on `PATH` in new shells:

```bash
(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> "$HOME/.zprofile"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Confirm the install:

```bash
command -v brew
brew --version
```

> [!note]
> A `Brewfile` may exist under the captured system inventory. Review it before considering `brew bundle` — do not blindly reinstall everything from an old Brewfile if some entries are now managed by IT or no longer needed.

### Step 4 — Update Homebrew and Run Diagnostics

Refresh Homebrew and inspect base health before installing many packages:

```bash
brew update
brew doctor
brew list
brew deps --tree --installed
```

Locate any captured `Brewfile` for reference:

```bash
find "$REIMAGE_ARTIFACT_ROOT/system-inventory" -name 'Brewfile*' -print 2>/dev/null
```

If you decide to use one, do it only after reviewing:

```bash
brew bundle --file /path/to/Brewfile
```

> [!bug] Troubleshooting
> If `brew doctor` flags a leftover Intel-path Homebrew prefix on Apple silicon, see [[#`brew doctor` reports a stale `/usr/local` on Apple silicon|`brew doctor` reports a stale `/usr/local` on Apple silicon]].

### Step 5 — Install direnv and Restore the Repo Environment Hook

`direnv` is the mechanism that sets `FRACTOGENESIS_HOME` when you `cd` into this repository checkout — all eight `restore-*` runbooks, this one included, open their Prerequisites assuming it is already doing that. It was installed on the *pre-image* machine back in Phase 1 (`prepare-artifact-root.md`) and no phase reinstalls it after the wipe, so on a reimaged Mac it is simply gone. Homebrew is healthy as of the previous step, so install it now, before any runbook command that spells a path as `$FRACTOGENESIS_HOME/...`.

Install it:

```bash
brew install direnv
```

Add the zsh hook, idempotently, so `.envrc` files load on `cd`:

```bash
grep -qxF 'eval "$(direnv hook zsh)"' "$HOME/.zprofile" || (echo; echo 'eval "$(direnv hook zsh)"') >> "$HOME/.zprofile"
eval "$(direnv hook zsh)"
```

Approve this checkout's `.envrc` and confirm the variable populates:

```bash
direnv --version
direnv allow
echo "$FRACTOGENESIS_HOME"
```

`echo "$FRACTOGENESIS_HOME"` must print a resolved absolute path. `cd` out of the repo and back in — the value should disappear and reappear. That round trip is the proof the hook is live, not just that `direnv` is installed.

> [!warning] Pitfall
> A restored `.envrc` stays blocked until `direnv allow` is run **in that directory**. direnv records approval by content hash on the machine, and a reimaged Mac has no approval record for any checkout you restore onto it — so a perfectly good `.envrc` sits there doing nothing. This is silent from the shell's point of view: nothing errors, `FRACTOGENESIS_HOME` is just the empty string, and every command built from it quietly resolves against `/` or your current directory instead. If a later runbook's paths look wrong, check `echo "$FRACTOGENESIS_HOME"` before you debug anything else.

> [!note]
> This runbook keeps shell bootstrap lines in `~/.zprofile` (Homebrew's `shellenv` in Step 3, `nvm` in Step 7), so the hook goes there too. If your pre-image setup put it in `~/.zshrc` instead, pick one file and keep it there — two copies are not harmful, but they make it needlessly hard to tell which one is actually loading.

### Step 6 — Install Java and the JVM Build Tools

Install the base developer runtimes and build tools:

```bash
brew install git
brew install openjdk@21
brew install gradle
brew install maven
brew install groovy
```

`openjdk@21` is **keg-only**. Homebrew installs it under its own prefix and deliberately does not symlink it into `/Library/Java/JavaVirtualMachines`, which is the only place macOS's Java lookup looks — so the install succeeds and the JDK is still invisible to `java` and `/usr/libexec/java_home`. Create the link Homebrew's caveat text describes (Apple silicon path shown; on an Intel Mac substitute `/usr/local/opt/openjdk@21/libexec/openjdk.jdk`):

```bash
sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk
/usr/libexec/java_home -v 21
```

`/usr/libexec/java_home -v 21` must print a path and exit `0`. Do not move on until it does.

> [!warning] Pitfall
> Skipping the symlink does not look like a failure at this step. `brew install openjdk@21` reports success, and the caveat that tells you to link it scrolls past with the rest of the install output. What you actually get is `java -version` reporting `Unable to locate a Java Runtime` and `/usr/libexec/java_home -v 21` exiting non-zero — and the real damage lands a phase later. [[restore-access|restore-access.md]] Step 6 runs `export JAVA_HOME="$(/usr/libexec/java_home -v 21)"`; command substitution swallows the non-zero exit, so `JAVA_HOME` is silently set to the empty string. The `cp` on the next line then writes `jssecacerts` to `/lib/security/jssecacerts` — an absolute path that is not the JDK, and not even a directory that exists — and the internal-TLS smoke test afterward fails for a reason that has nothing to do with the certificate you just restored. Verify `java_home` here, where it is one command, rather than there, where it is a red herring.

Confirm the toolchain resolves:

```bash
git --version
/usr/libexec/java_home -V
java -version
gradle --version
mvn --version
groovy --version
```

If multiple JDKs are needed later, keep the switch helpers explicit rather than editing `JAVA_HOME` by hand each time:

```bash
alias jdk8='export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)'
alias jdk11='export JAVA_HOME=$(/usr/libexec/java_home -v 11)'
alias jdk17='export JAVA_HOME=$(/usr/libexec/java_home -v 17)'
alias jdk21='export JAVA_HOME=$(/usr/libexec/java_home -v 21)'
```

JDK 21 is the normal baseline unless a project-specific requirement says otherwise.

> [!bug] Troubleshooting
> If `java -version` reports something other than the JDK you just installed, see [[#`java -version` prints a version different from `openjdk@21`|`java -version` prints a version different from `openjdk@21`]].

> [!warning] Pitfall
> Do not `brew install node` here — see the next step for why. Installing both `brew`'s `node` and `nvm`'s `node` creates a PATH collision where it is unclear which binary actually runs.

### Step 7 — Install and Manage Node Versions

Install `nvm` only:

```bash
brew install nvm
```

Source it from your shell profile so `nvm` is available in new shells:

```bash
mkdir -p "$HOME/.nvm"
cat >> "$HOME/.zprofile" <<'EOF'
export NVM_DIR="$HOME/.nvm"
source "$(brew --prefix nvm)/nvm.sh"
EOF
source "$HOME/.zprofile"
```

Check a project's required Node version before installing:

```bash
grep -A2 '"engines"' package.json 2>/dev/null || true
cat .nvmrc 2>/dev/null || true
```

Install and switch versions:

```bash
nvm install "<version>"
nvm use "<version>"
```

Confirm the tooling resolves:

```bash
node --version
npm --version
```

### Step 8 — Install Platform CLIs and Helper Utilities

Install the common platform tools:

```bash
brew install cloudfoundry/tap/cf-cli@7
brew install --cask fly
brew install jq
brew install kotlin
brew install wget
brew install yq
```

Confirm the installs:

```bash
cf --version
fly --version
jq --version
kotlin -version 2>/dev/null || true
wget --version | head -1
yq --version
```

> [!note]
> If a workflow still needs legacy `yq` v3 syntax, install it intentionally and document why in a personal note under the restore evidence, rather than silently replacing the Homebrew version.

### Step 9 — Compare Versions Against Captured Inventories

Compare the rebuilt runtime layer against the captured pre-image inventory. This is a paper trail step, not an automated diff: the point is to notice unexpected drift, not to reproduce every historical version exactly.

Useful evidence sources under the artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/system-inventory/pre-image-YYYYMMDD-HHMMSS/
$REIMAGE_ARTIFACT_ROOT/system-inventory/post-image-YYYYMMDD-HHMMSS/
```

Useful comparison commands on the live machine:

```bash
sw_vers
brew --version
git --version
java -version
/usr/libexec/java_home -V || true
gradle --version | head -20 || true
mvn --version || true
node --version || true
npm --version || true
groovy --version || true
cf --version || true
fly --version || true
jq --version || true
yq --version || true
```

Focus on whether the rebuilt Mac is now ready for the next restore phases, not on matching every older minor version. An approved-newer version is fine; an unexplained-older or missing tool is not.

### Step 10 — Confirm Readiness for Restore Access

Confirm the runtime layer meets its exit criteria before starting `restore-access.md`:

| Area | Expected result |
|---|---|
| Rosetta 2 | `arch -x86_64 /usr/bin/uname -m` prints `x86_64` (installed on Apple silicon; a no-op on Intel). |
| Xcode CLT | `xcode-select -p` resolves to a valid path. |
| Homebrew | `brew doctor` is acceptable for continuing setup (no blocking errors). |
| direnv | `direnv` is installed and hooked into zsh, `.envrc` is allowed, and `FRACTOGENESIS_HOME` populates on `cd` into the repo. |
| Java | JDK 21 baseline is present unless a different project baseline is required. |
| Java lookup | `/usr/libexec/java_home -v 21` prints a path and exits `0`, so `JAVA_HOME` resolves for the Phase 10B trust-override copy. |
| Build tools | Gradle and Maven run. |
| Node tooling | `nvm`, `node`, and `npm` run. |
| Platform CLIs | Cloud Foundry CLI, `fly`, `jq`, `yq`, and the other utilities from Step 8 run. |
| Version comparison | Every drift versus the pre-image inventory is either an approved-newer version or an intentional decision. |

Once every row above is a yes, move to [[restore-access|restore-access.md]] to restore the identity, trust, and credential layer. Completing that runbook is what actually unlocks Git, IDE, and application restore in Phases 11 onward.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The installers do X; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Whether to run IT's official workstation-setup script alongside this runbook. | Only you know whether IT's script overlaps or conflicts with the tools installed here. |
| Which non-baseline JDK versions (8, 11, 17) to install in addition to JDK 21. | Depends on which projects you actively work on; the runbook cannot infer that. |
| Whether a captured `Brewfile` from the pre-image is still relevant. | Some entries may now be IT-managed or discontinued. Reviewing before `brew bundle` is a judgment call. |
| Whether a version drift versus the pre-image inventory is an approved-newer choice or an accidental regression. | Requires context on why the pre-image had that version. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Two install-time failures have fixes long enough to break the flow of the step that surfaces them. Each of those steps links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### `brew doctor` reports a stale `/usr/local` on Apple silicon

Homebrew was previously installed under `/usr/local` (Intel path) and left behind by the reimage. Remove the stale prefix only after confirming nothing under it is needed:

```bash
ls /usr/local
sudo rm -rf /usr/local/Homebrew
```

Rerun `brew doctor` afterward and confirm the stale-prefix warning is gone before installing packages.

[[#Step 5 — Install direnv and Restore the Repo Environment Hook|⮕ Continue to Step 5 — Install direnv and Restore the Repo Environment Hook]]

### `java -version` prints a version different from `openjdk@21`

`/usr/libexec/java_home -V` lists every installed JDK; the default is the first one. Set `JAVA_HOME` explicitly for the current session:

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
java -version
```

Persist that export in `~/.zprofile` only if 21 is your intended default.

[[#Step 7 — Install and Manage Node Versions|⮕ Continue to Step 7 — Install and Manage Node Versions]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link,
  except Troubleshooting, whose back-link sits under its intro and whose routed
  symptom subsections stay out of the Table of Contents.
-->
