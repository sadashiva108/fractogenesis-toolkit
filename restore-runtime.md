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
    - [[#Step 1 — Install Xcode Command Line Tools|Step 1 — Install Xcode Command Line Tools]]
    - [[#Step 2 — Install Homebrew|Step 2 — Install Homebrew]]
    - [[#Step 3 — Update Homebrew and Run Diagnostics|Step 3 — Update Homebrew and Run Diagnostics]]
    - [[#Step 4 — Install Java and the JVM Build Tools|Step 4 — Install Java and the JVM Build Tools]]
    - [[#Step 5 — Install and Manage Node Versions|Step 5 — Install and Manage Node Versions]]
    - [[#Step 6 — Install Platform CLIs and Helper Utilities|Step 6 — Install Platform CLIs and Helper Utilities]]
    - [[#Step 7 — Compare Versions Against Captured Inventories|Step 7 — Compare Versions Against Captured Inventories]]
    - [[#Step 8 — Confirm Readiness for Restore Access|Step 8 — Confirm Readiness for Restore Access]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Restore the non-secret runtime layer — the compiler and package-manager stack, JVM tooling, Node, and platform CLIs — that every later restore phase depends on. Get the machine to the point where it can build, install packages, and run the expected local tooling without pulling in secrets, credentials, or repository state too early.

**What it sets up**

- **Xcode Command Line Tools** — installed and verified, so the compiler and linker later build tooling depends on are present.
- **Homebrew** — installed, brought up to date, and put through a diagnostic pass before packages are added.
- **The JVM layer** — the JDK baseline plus Gradle, Maven, and Groovy.
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
| Xcode Command Line Tools install and verification, and the Homebrew install, update, and diagnostic pass | SSH keys, certificates, Java trust overrides (`jssecacerts`), shell/CLI credentials, and licenses — `restore-access` (Phase 10B) |
| the JVM layer — JDK, Gradle, Maven, and Groovy | managed enrollment, MDM baseline, and stabilization restarts — `enroll-and-stabilize` (Phase 8) |
| Node version management via `nvm` and per-project Node installs | day-one usability sign-off and the first post-image Time Machine backup — `verify-reimaged-system` (Phase 9) |
| Cloud Foundry CLI, `fly`, `jq`, `kotlin`, `wget`, `yq`, and similar platform tools | Git identity plumbing, SSH host aliases, and the clone template for re-cloning repositories — `restore-git` (Phase 11A) |
| the version comparison against the captured pre-image and post-image system inventories | the system-inventory captures themselves — `capture-system-inventory` (Phase 4B / 13B) |

This runbook can be rerun. Every step is idempotent (Homebrew and `nvm` skip anything already installed at the requested version), so a partial run can be resumed without a special mode.

> [!warning] Pitfall
> If IT or company policy also provides an official automated workstation-setup project or script, review it before running it *here*. It may reinstall Homebrew, overwrite shell profile changes, or install a different Java or Node version than what this runbook and the captured pre-image evidence expect. Run it deliberately — first or last, not interleaved with this runbook — and reconcile any conflicts rather than running both blindly.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The order is a hard bootstrap chain, not a preference: Xcode Command Line Tools have to be present before Homebrew installs cleanly, Homebrew has to be present before the JVM and Node stacks, and the JVM has to be in place before Phase 10B tries to restore the `jssecacerts` Java trust override — that override has to match the JDK that is actually installed. Node stays out of the Homebrew chain intentionally: it is installed via `nvm` so a project can switch versions per repo without a PATH collision with a `brew install node`.

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

Input evidence used for comparison in Step 7:

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
- The external artifact volume is mounted and `reimage.env` resolves so Step 7 can read the pre-image inventory. If it isn't mounted yet, do Steps 1–6 anyway and reconnect the drive before Step 7.

> [!bug] Troubleshooting
> `xcode-select --install` returning "command line tools are already installed" on a freshly reimaged Mac usually means a leftover receipt from the previous install. Confirm the active path with `xcode-select -p`; if it points to nothing, `sudo rm -rf /Library/Developer/CommandLineTools` and rerun the install.

### Confirm Your Intent

- Are you doing a **greenfield** restore (all steps in order) or a **targeted rerun** of one step (e.g. installing an additional platform CLI that Phase 2 didn't capture)? Both are safe; the difference is whether you also do Step 7's comparison at the end.
- Which **Java baseline** does the machine need? The default here is JDK 17; if a specific project requires 8 or 11, install that in addition — do not replace the baseline.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. Every step is a dependency for at least one later step: CLT before Homebrew, Homebrew before the JVM and CLIs, JVM before Phase 10B's Java trust override work.

### Step 1 — Install Xcode Command Line Tools

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

### Step 2 — Install Homebrew

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

### Step 3 — Update Homebrew and Run Diagnostics

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

### Step 4 — Install Java and the JVM Build Tools

Install the base developer runtimes and build tools:

```bash
brew install git
brew install openjdk@17
brew install gradle
brew install maven
brew install groovy
```

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
```

JDK 17 is the normal baseline unless a project-specific requirement says otherwise.

> [!bug] Troubleshooting
> If `java -version` reports something other than the JDK you just installed, see [[#`java -version` prints a version different from `openjdk@17`|`java -version` prints a version different from `openjdk@17`]].

> [!warning] Pitfall
> Do not `brew install node` here — see the next step for why. Installing both `brew`'s `node` and `nvm`'s `node` creates a PATH collision where it is unclear which binary actually runs.

### Step 5 — Install and Manage Node Versions

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

### Step 6 — Install Platform CLIs and Helper Utilities

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

### Step 7 — Compare Versions Against Captured Inventories

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

### Step 8 — Confirm Readiness for Restore Access

Confirm the runtime layer meets its exit criteria before starting `restore-access.md`:

| Area | Expected result |
|---|---|
| Xcode CLT | `xcode-select -p` resolves to a valid path. |
| Homebrew | `brew doctor` is acceptable for continuing setup (no blocking errors). |
| Java | JDK 17 baseline is present unless a different project baseline is required. |
| Build tools | Gradle and Maven run. |
| Node tooling | `nvm`, `node`, and `npm` run. |
| Platform CLIs | Cloud Foundry CLI, `fly`, `jq`, `yq`, and the other utilities from Step 6 run. |
| Version comparison | Every drift versus the pre-image inventory is either an approved-newer version or an intentional decision. |

Once every row above is a yes, move to [[restore-access|restore-access.md]] to restore the identity, trust, and credential layer. Completing that runbook is what actually unlocks Git, IDE, and application restore in Phases 11 onward.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The installers do X; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Whether to run IT's official workstation-setup script alongside this runbook. | Only you know whether IT's script overlaps or conflicts with the tools installed here. |
| Which non-baseline JDK versions (8, 11, 21) to install in addition to JDK 17. | Depends on which projects you actively work on; the runbook cannot infer that. |
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

[[#Step 4 — Install Java and the JVM Build Tools|⮕ Continue to Step 4 — Install Java and the JVM Build Tools]]

### `java -version` prints a version different from `openjdk@17`

`/usr/libexec/java_home -V` lists every installed JDK; the default is the first one. Set `JAVA_HOME` explicitly for the current session:

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
java -version
```

Persist that export in `~/.zprofile` only if 17 is your intended default.

[[#Step 5 — Install and Manage Node Versions|⮕ Continue to Step 5 — Install and Manage Node Versions]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link,
  except Troubleshooting, whose back-link sits under its intro and whose routed
  symptom subsections stay out of the Table of Contents.
-->
