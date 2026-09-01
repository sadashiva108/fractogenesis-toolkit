[[reimaging-guide#Phase 10A — Restore Runtime Libraries|← Back to Mac Reimaging Guide]]

# Restore Runtime

**Last updated:** 2026-09-01

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
    - [[#Step 0 — Record Prerequisites|Step 0 — Record Prerequisites]]
    - [[#Step 1 — Install Rosetta 2|Step 1 — Install Rosetta 2]]
    - [[#Step 2 — Install Xcode Command Line Tools|Step 2 — Install Xcode Command Line Tools]]
    - [[#Step 3 — Install Homebrew|Step 3 — Install Homebrew]]
    - [[#Step 4 — Update Homebrew and Run Diagnostics|Step 4 — Update Homebrew and Run Diagnostics]]
    - [[#Step 5 — Install Obsidian and Open the Toolkit|Step 5 — Install Obsidian and Open the Toolkit]]
    - [[#Step 6 — Install direnv and Restore the Repo Environment Hook|Step 6 — Install direnv and Restore the Repo Environment Hook]]
    - [[#Step 7 — Install Java and the JVM Build Tools|Step 7 — Install Java and the JVM Build Tools]]
    - [[#Step 8 — Install and Manage Node Versions|Step 8 — Install and Manage Node Versions]]
    - [[#Step 9 — Install Platform CLIs and Helper Utilities|Step 9 — Install Platform CLIs and Helper Utilities]]
    - [[#Step 10 — Compare Versions Against Captured Inventories|Step 10 — Compare Versions Against Captured Inventories]]
    - [[#Step 11 — Close Out the Exit Criteria|Step 11 — Close Out the Exit Criteria]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> Two kinds, used sparingly. `[!warning]` **Pitfall** — skipping it costs something you do not get back: state overwritten, a security boundary crossed, or a wrong result that stays quiet until a later phase. `[!bug]` **Troubleshooting** — what to do when a step misbehaves. Everything else is prose, in the paragraph that needed it. A box around an explanation only makes the explanation easier to skip.

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

The installs are script-free by design. Every install step is a small, standard command that either succeeds cleanly or fails in a way the reader will investigate; automating around Homebrew and `nvm` would obscure the diagnostic surface those tools already print. The *verification* at the end is scripted, because comparing fifteen version strings against a sixteen-file inventory by eye is exactly the kind of work that misses an absent tool. The captured pre-image system inventory under `$REIMAGE_ARTIFACT_ROOT/system-inventory/pre-image-*/` and its post-image sibling are the reference for what "restored" looks like — the final step compares the fresh install against them.

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

Every path this runbook reads or writes is defined here, once. Later sections
refer back to these names instead of redrawing them.

Primary script:

```text
none — this runbook installs its toolchain by hand; the scripts below record and compare
```

Related scripts, alphabetical:

```text
$FRACTOGENESIS_HOME/bin/compare-restored-state.sh      # entrypoint (Step 10 — version comparison against the captured inventories)
$FRACTOGENESIS_HOME/bin/init-shell-env.sh              # entrypoint (Step 6 — removes the Phase 8 shell bridge)
$FRACTOGENESIS_HOME/bin/prepare-artifact-root.py       # entrypoint (Step 7 — upsert-env, writes the JDK baseline into reimage.env)
$FRACTOGENESIS_HOME/bin/record-restore-exit.sh         # entrypoint (Step 11 — exit boundary)
$FRACTOGENESIS_HOME/bin/record-restore-prereqs.sh      # entrypoint (Step 0 — entry boundary)
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/                # every artifact this runbook generates lands here
```

Input evidence used for comparison in Step 10, read and never written:

```text
$REIMAGE_ARTIFACT_ROOT/system-inventory/pre-image-YYYYMMDD-HHMMSS/
$REIMAGE_ARTIFACT_ROOT/system-inventory/post-image-YYYYMMDD-HHMMSS/    # only present after Phase 13B
```

The complete `system-inventory/` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Bundle Layout

Everything this runbook writes, under the artifact root named above. This tree is
output only; the inputs are the `system-inventory/` captures listed above.

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/
boundaries/MANIFEST.md                                           # index of every entry and exit run
boundaries/official/restore-runtime-entry.txt                    # newest entry run
boundaries/official/restore-runtime-exit.txt                     # newest exit run
boundaries/runs/restore-runtime-entry-YYYYMMDD-HHMMSS/           # Step 0 — checklist.md
boundaries/runs/restore-runtime-exit-YYYYMMDD-HHMMSS/            # Step 11 — checklist.md

comparisons/MANIFEST.md                                          # index of every comparison
comparisons/official/restore-runtime-inventory-diff.txt          # newest inventory diff
comparisons/runs/restore-runtime-inventory-diff-YYYYMMDD-HHMMSS/ # Step 10 — comparison.md, vs the captured inventories
```

Both categories have the same shape: `runs/<context>-YYYYMMDD-HHMMSS/` holding
that run's files, `official/<context>.txt` naming the newest run, and an
append-only `MANIFEST.md` indexing every completed run.

There is no `restore-notes/` or `sign-offs/` entry in this phase. Phase 15
(`restore-home.md`) owns the prose category, where a hand-written note is the
only artifact a step produces; `sign-offs/` belongs to the phases that ask a
person to answer rows, and this one asks none.
Everything this runbook records is generated, so it goes to `boundaries/` and
`comparisons/` where the run index can find it.

### Environment Variables

The `reimage.env` values this runbook depends on. `REIMAGE_ARTIFACT_ROOT` is resolved and written during `prepare-artifact-root.md`; `FRACTOGENESIS_HOME` is a shell-startup value and is never stored in `reimage.env` at all. The last two are exported and written **by this runbook**, in [[#Step 7 — Install Java and the JVM Build Tools|Step 7]] — they are not in `reimage.env.example` and do not exist in `reimage.env` until Step 7 records them, since `upsert-env` appends a key that is not yet present. [[restore-access|restore-access.md]] Step 0 confirms both and re-records them if a `reimage.env` predating Step 7 reaches Phase 10B.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Artifact root for this reimage event; used to locate the captured system inventory for version comparison. |
| `FRACTOGENESIS_HOME` | Repository root for this toolkit checkout; used only to keep command examples portable. Set by your shell startup / `.envrc`, not stored in `reimage.env`. |
| `REIMAGE_JDK_BASELINE` | The JDK major this machine is pinned to. Named once in Step 7 and never retyped: that step's `brew install openjdk@…`, its symlink, and its `java_home -v` verification all read it, and its write guard refuses to record an empty one. Phase 10B writes the `jssecacerts` trust override into whichever JDK resolves through it, so on a multi-JDK machine this is what decides which one gets the corporate trust. Not a version this toolkit hardcodes anywhere — the checks report which path resolved rather than asserting a number, so nothing goes stale when the baseline moves. The boundary recorders tolerate a blank and fall back to the machine's default JDK, which is right on a machine with one installed; Step 7 itself does not. |
| `JAVA_HOME` | Resolved from `REIMAGE_JDK_BASELINE` through `/usr/libexec/java_home` in Step 7, exported there, and written to `reimage.env` in the same block, so a new terminal or a later phase does not rediscover it. The one key here that must never be present-but-empty: unlike the `REIMAGE_*` keys, the shell and every JVM tool already read `JAVA_HOME`, so `export JAVA_HOME=` overwrites a working value with an empty string the moment `reimage.env` is sourced. Step 7's guard is what prevents that — it refuses to write **either** key when **either** one is empty, rather than recording half a pair. A convenience in any case: every step that needs it re-derives it from the baseline rather than trusting the stored path, which goes stale when the JDK is reinstalled. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the toolkit root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 8 (`enroll-and-stabilize.md`) closed out with a clean managed baseline, and Phase 9 (`verify-reimaged-system.md`) signed off day-one usability. If either is still open, close it first.
- The reimaged Mac has internet access. Homebrew, `nvm`, JDK downloads, and every platform CLI install below hit the network.
- The external artifact volume is mounted and `reimage.env` resolves so Step 10 can read the pre-image inventory. If it isn't mounted yet, do Steps 1–9 anyway and reconnect the drive before Step 10.

Each of these is stated here and *verified* in Step 0 — Prerequisites declares,
Step 0 checks and records. Only the third has a PASS row in an earlier phase; the
other three are assertions until Step 0 runs, and each fails quietly rather than
loudly.

> [!bug] Troubleshooting
> `xcode-select --install` returning "command line tools are already installed" on a freshly reimaged Mac usually means a leftover receipt from the previous install. Confirm the active path with `xcode-select -p`; if it points to nothing, `sudo rm -rf /Library/Developer/CommandLineTools` and rerun the install.

### Confirm Your Intent

- Are you doing a **greenfield** restore (all steps in order) or a **targeted rerun** of one step (e.g. installing an additional platform CLI that Phase 2 didn't capture)? Both are safe; the difference is whether you also do Step 10's comparison at the end.
- Which **Java baseline** does the machine need? The default here is JDK 21; if a specific project requires 8, 11, or 17, install that in addition — do not replace the baseline.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. Every step is a dependency for at least one later step: Rosetta before any Intel-only installer, CLT before Homebrew, Homebrew before `direnv`, the JVM, and the CLIs, JVM before Phase 10B's Java trust override work.

### Step 0 — Record Prerequisites

Verify the four preconditions above and write the result. This gates the phase
rather than advancing it, and it is rerunnable at any point — reconnect the
artifact drive mid-phase, run it again, get a fresh artifact.

```bash
bash bin/record-restore-prereqs.sh --runbook restore-runtime --help
bash bin/record-restore-prereqs.sh --runbook restore-runtime
```

It records the result under `reimaged-system/boundaries/` and exits non-zero
only on `FAIL`, writing this phase's entry half under the context
`restore-runtime-entry`.

| Result | Meaning |
|---|---|
| `FAIL` | Toolkit root unresolved, or no network. Nothing below works; stop. |
| `WARN` | Proceed with a known limit — typically the artifact drive not yet mounted, which is fine through Step 9. |
| `PASS` | Verified, not assumed. |

A completed sign-off means every row was *answered*, not that every answer was
`yes`. A row closed as `no` or `known-blocked` is a decision and counts as
answered. Rows an earlier phase recorded and a later one resolves — `Git
available`, `Homebrew available` — are excluded outright: a `TODO` there is the
correct state at the time Phase 9 wrote it, not a question nobody answered.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

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

On an Intel Mac this step is a harmless no-op: `softwareupdate` reports that Rosetta is not applicable to this architecture and exits, and the `arch` check still prints `x86_64` because it runs natively. Run it unconditionally rather than branching on architecture. No reboot is required either way — translation is available as soon as the install finishes.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

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

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Install Homebrew

Install Homebrew using the official installer. Download and run as two steps
rather than piping:

```bash
curl -fL -o /tmp/brew-install.sh https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
test -s /tmp/brew-install.sh && /bin/bash /tmp/brew-install.sh
```

> [!warning] Pitfall
> The piped form `/bin/bash -c "$(curl -fsSL …)"` fails silently. With `-f -s`, a
> 404 or a captive-portal redirect produces empty output, `bash` runs nothing,
> and the command exits **0** — no Homebrew, no error, and the next step fails
> for a reason that looks unrelated. This is the same trap
> [[restore-strategy-guide|restore-strategy-guide.md]] documents for
> `bootstrap.sh`, and it is easy to hit here by mistyping the URL: the installer
> lives in `Homebrew/install`, not `Homebrew/brew`. `-o` plus `test -s` makes a
> failed download impossible to miss.

Prefix with `NONINTERACTIVE=1` to skip the confirmation keystroke, which is
useful when starting the install and stepping away, and run `sudo -v` first so
the installer's single privilege escalation uses an already-cached credential
rather than waiting at a prompt.

On Apple silicon, add the shell bootstrap so `brew` is on `PATH` in new shells:

```bash
(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"') >> "$HOME/.zprofile"
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
```

Homebrew's own post-install message is the authority here: run what it prints
rather than what this runbook says, and tell us if the two differ. Current
versions emit `brew shellenv zsh`, taking the shell as an argument, while older
ones omitted it and auto-detected — both work. Running both, which is easy to do
by following the installer's message *and* this block, leaves two lines in
`~/.zprofile` doing the same job.

Confirm the install:

```bash
command -v brew
brew --version
```

**Close the completion-directory permissions now, before a shell config uses
them.** Homebrew creates `share/` group-writable, and zsh's `compinit` refuses to
load completions from any directory a second account could write to — everything
on `FPATH` is executed in your shell. The result is a prompt at the top of every
new terminal:

```text
zsh compinit: insecure directories, run compaudit for list.
Ignore insecure directories and continue [y] or abort compinit [n]?
```

```bash
compaudit
```

```bash
compaudit | while IFS= read -r d; do chmod g-w,o-w "$d"; done
```

```bash
rm -f "$HOME"/.zcompdump*
```

Open a new terminal to confirm the prompt is gone. Doing it here rather than
when it appears is the cheaper order: the prompt only shows up once a shell
config puts a Homebrew directory on `FPATH`, which is Phase 10B Step 8, by which
point it is competing for attention with a dotfile merge.

`compaudit` printing nothing while the prompt persists means the flagged
directory is one that does not exist yet — `~/.docker/completions` is the usual
one, and Phase 12 creates it. Harmless, and it resolves itself.

> [!bug] Troubleshooting
> If the prompt appears anyway, here or in a later phase, see [[#Every new terminal asks about insecure directories|Every new terminal asks about insecure directories]].

A `Brewfile` may exist under the captured system inventory. Review it before considering `brew bundle` — do not blindly reinstall everything from an old Brewfile when some entries are now managed by IT or no longer needed.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

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

Review it. Both of these read the file and install nothing:

```bash
BF="$(find "$REIMAGE_ARTIFACT_ROOT/system-inventory" -name 'Brewfile' -print 2>/dev/null | sort | tail -1)"
brew bundle list --all --file "$BF"
brew bundle check --verbose --file "$BF"
```

`list` prints every entry, one per line; `check --verbose` prints only the
entries not installed yet.

> [!warning] Pitfall
> **All three review commands mislead if you type them from memory, and two of
> them mislead quietly.**
>
> `brew bundle list` without `--all` prints **formulae only** — a Brewfile's
> casks, taps, and any `mas`/`npm`/`vscode` entries are silently omitted, so a
> review that looks complete hides the entries most worth questioning: a VPN
> client, a packet analyser, a window manager from an untrusted tap. `brew bundle
> check` without `--verbose` reports only that something is unmet, never what.
> And `brew bundle --file`, with no subcommand at all, **installs** — reaching
> for it after a sentence about reviewing is an easy mistake to make. Use `list
> --all` or `check --verbose`, and drop the subcommand only once you have decided
> to install the whole file, which on a rebuild is rarely what you want.

Then install deliberately rather than in bulk. Steps 7 through 9 already cover
Java, Node, and the platform CLIs, so the Brewfile is most useful as a checklist
of what the old machine had — a prompt for "did I forget anything?" once those
steps are done, not a shortcut past them.

Two failures are expected and correct if you do run the whole file. A tap that
has since been deprecated reports as empty, its formulae having migrated into
core, and nothing is lost. And a cask from an untrusted third-party tap is
refused outright by current Homebrew — leave it refused unless you actively want
that cask, then trust the tap explicitly.

A failed run can still leave **taps** behind even when it installs nothing,
because tapping happens before any install. Check with `brew tap`, and `brew
untap` anything you did not mean to add.

> [!bug] Troubleshooting
> If `brew doctor` flags a leftover Intel-path Homebrew prefix on Apple silicon, see [[#`brew doctor` reports a stale `/usr/local` on Apple silicon|`brew doctor` reports a stale `/usr/local` on Apple silicon]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Install Obsidian and Open the Toolkit

Every runbook from here to the end of the reimage is Markdown written for
Obsidian — callouts, wiki-links, collapsible sections. Read in `less` or
TextEdit, a `> [!warning] Pitfall` is a line of punctuation and
`[[restore-git|restore-git.md]]` is not a link. Ten minutes spent here makes the
remaining six phases materially easier to follow.

```bash
brew install --cask obsidian
```

Open the toolkit as a vault: **Open folder as vault** →
`$FRACTOGENESIS_HOME`. Then `reimaging-guide.md` is the index, every phase
back-link works, and the callouts render as intended.

```bash
echo "$FRACTOGENESIS_HOME"
```

This is the toolkit only. The `reference-vault` notes vault is a private repo
needing SSH and a clone, so it waits for
[[restore-apps#Step 4 — Obsidian and Reference Vault|Phase 12 Step 4]]; nothing
here depends on it.

Two things about this vault are worth knowing before you settle into it. Obsidian
writes a `.obsidian/` directory into any folder opened as a vault, and the toolkit
gitignores it, so your workspace layout, open tabs, and pane arrangement live
outside Git and vanish with the checkout — the same class of gap as `reimage.env`:
fine while you know it, surprising when the checkout moves. And the checkout does
move. `$FRACTOGENESIS_HOME` still points at the `curl` or jump-drive install;
Phase 11B clones the toolkit properly and repoints the variable, at which point
this vault is aimed at a directory you are about to delete. Re-open the clone as a
vault then — see
[[restore-repos#Step 4 — Repoint at the Cloned Toolkit|Phase 11B Step 4]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 6 — Install direnv and Restore the Repo Environment Hook

`direnv` is the mechanism that sets `FRACTOGENESIS_HOME` and loads `reimage.env` when you `cd` into the toolkit root. It was installed on the *pre-image* machine back in Phase 1 (`prepare-artifact-root.md`) and no phase reinstalls it after the wipe, so on a reimaged Mac it is simply gone.

Since Phase 8 that job has been done by a temporary block in `~/.zprofile`, written by `bin/init-shell-env.sh` precisely because direnv does not exist yet. **This step is the handoff**: install direnv, retire the bridge, then confirm direnv has taken over. Homebrew is healthy as of the previous step, so do it now, before any runbook command that spells a path as `$FRACTOGENESIS_HOME/...`.

The full picture of how these two mechanisms divide the workflow between them is in [[references/toolkit-environment-reference|Toolkit Environment Reference]].

Install it:

```bash
brew install direnv
```

Add the zsh hook, idempotently, so `.envrc` files load on `cd`:

```bash
grep -qxF 'eval "$(direnv hook zsh)"' "$HOME/.zprofile" || (echo; echo 'eval "$(direnv hook zsh)"') >> "$HOME/.zprofile"
eval "$(direnv hook zsh)"
```

Retire the Phase 8 bridge **before** verifying. `cd` into the toolkit first:
`exec` inherits the working directory, so the replacement shell starts there and
direnv can set `FRACTOGENESIS_HOME` itself — no literal path needed anywhere in
this step.

```bash
cd "$FRACTOGENESIS_HOME"
bash ./bin/init-shell-env.sh --remove
exec zsh -l
```

Do this before the round-trip check below, not after. The Phase 8 block exports
`FRACTOGENESIS_HOME` as a plain login-shell export, which direnv does not manage
and therefore never unloads.

Approve the toolkit's `.envrc` and confirm the variable populates:

The new shell is already in the toolkit directory:

```bash
direnv --version
direnv allow
echo "$FRACTOGENESIS_HOME"
```

`echo "$FRACTOGENESIS_HOME"` must print a resolved absolute path. `cd` out of the toolkit and back in — the value should disappear and reappear. That round trip is the proof the hook is live, not just that `direnv` is installed.

> [!warning] Pitfall
> **You cannot tell direnv's real state by looking, and it misleads in both
> directions.** Nothing errors either way, so each case below is found by
> checking rather than by noticing.
>
> **It can look broken when it is fine.** Leave the Phase 8 `~/.zprofile` block
> in place and `cd` out of the toolkit: `FRACTOGENESIS_HOME` stubbornly persists,
> because a plain login-shell export is not direnv's to unload. The round trip
> appears to fail and you spend twenty minutes debugging a hook that was working
> the whole time. Removing the block first is what makes the check mean anything.
>
> **And it can look fine when it is broken**, in two ways.
>
> A restored `.envrc` stays blocked until `direnv allow` is run **in that
> directory**. direnv records approval by content hash on the machine, and a
> reimaged Mac has no approval record for any checkout you restore onto it, so a
> perfectly good `.envrc` sits there doing nothing — `FRACTOGENESIS_HOME` is just
> the empty string, and every command built from it quietly resolves against `/`
> or your current directory instead.
>
> Separately, `.envrc` only loads `reimage.env` when that file is present in the
> same directory. It is gitignored, so it arrives by no install route: it was
> copied there by hand in Phase 8 Step 2. If `direnv allow` succeeds but
> `echo "$REIMAGE_ARTIFACT_ROOT"` comes back empty, that file is what is missing,
> not the hook.
>
> If a later runbook's paths look wrong, check `echo "$FRACTOGENESIS_HOME"`
> before debugging anything else.

This runbook keeps shell bootstrap lines in `~/.zprofile` — Homebrew's `shellenv`
in Step 3, `nvm` in Step 8 — so the hook goes there too. If your pre-image setup
put it in `~/.zshrc` instead, pick one file and keep it there; two copies are not
harmful, but they make it needlessly hard to tell which one is actually loading.
The Phase 8 bridge block lives in the same file, between its own
`# >>> fractogenesis-toolkit reimage env >>>` markers, and `--remove` above takes
out that block while leaving everything else — including the direnv hook you just
added — untouched.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 7 — Install Java and the JVM Build Tools

Run these one at a time and read each result before the next. The order is
load-bearing, not stylistic: the JDK must be installed, linked, and *verified*
before the build tools go on.

Git first — it depends on nothing here:

```bash
brew install git
```

**Name the JDK major once.** Every command below reads it, `reimage.env` carries
it, and Phase 10B's trust-store step and both boundary recorders read it back —
so it is chosen here and never retyped. Substitute the major your projects need:

```bash
REIMAGE_JDK_BASELINE="21"
export REIMAGE_JDK_BASELINE
```

Then the JDK:

```bash
brew install "openjdk@$REIMAGE_JDK_BASELINE"
```

The `openjdk@<major>` formulae are **keg-only**. Homebrew installs them under
their own prefix and deliberately does not symlink them into
`/Library/Java/JavaVirtualMachines`, which is the only place macOS's Java lookup
looks — so the install succeeds and the JDK is still invisible to `java` and
`/usr/libexec/java_home`.

Create the link Homebrew's caveat text describes. `brew --prefix` resolves the
formula's own location, so this is the same command on Apple silicon and Intel:

```bash
sudo ln -sfn "$(brew --prefix "openjdk@$REIMAGE_JDK_BASELINE")/libexec/openjdk.jdk" \
  "/Library/Java/JavaVirtualMachines/openjdk-$REIMAGE_JDK_BASELINE.jdk"
```

Verify before continuing. This must print a path and exit `0`:

```bash
/usr/libexec/java_home -v "$REIMAGE_JDK_BASELINE"
```

> [!warning] Pitfall
> **Do not install the build tools until that command succeeds, and do not skip
> the symlink to get there faster.** `gradle`, `maven`, and `groovy` each declare
> a dependency on `openjdk` — the versionless, current formula — so Homebrew
> installs **another** JDK alongside the one you just put in. Link and verify the
> baseline first and you know which JDK `java` resolves to and why; install them
> first and you are left with two JDKs, no `java_home` entry for either, and a
> `java -version` answer you cannot account for.
>
> Skipping the symlink does not look like a failure at this step either. The
> `brew install` reports success, and the caveat telling you to link it scrolls
> past with the rest of the output. What you actually get is `java -version`
> reporting `Unable to locate a Java Runtime` and
> `/usr/libexec/java_home -v "$REIMAGE_JDK_BASELINE"` exiting non-zero — and the
> real damage lands a phase later, where [[restore-access|restore-access.md]]
> Step 6 resolves `JAVA_HOME` through command substitution, which swallows a
> non-zero exit and leaves it empty. Verify `java_home` here, where it is one
> command, rather than there, where it is a red herring.

Now the build tools, one at a time:

```bash
brew install gradle
```

```bash
brew install maven
```

```bash
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

**Pin `JAVA_HOME` and record both values.** `JAVA_HOME` is not set by anything so
far — Phase 10B Step 6 needs it, and so does any build run between now and then.
Resolve it from the baseline rather than typing a path:

```bash
JAVA_HOME="$(/usr/libexec/java_home -v "$REIMAGE_JDK_BASELINE")"
export JAVA_HOME
printf 'JAVA_HOME=%s\n' "${JAVA_HOME:-<empty>}"
```

An `<empty>` here means the symlink step above did not take, and every later step
that reads it fails somewhere else instead.

Now write both into `reimage.env`, so a new terminal or a later phase does not
have to rediscover them. `upsert-env` accepts any `KEY=VALUE` it is given,
including an empty `VALUE`, and reports no error when it writes one — so check
both values in the same block that writes them, where the check cannot drift away
from the thing it protects:

```bash
if [ -z "$REIMAGE_JDK_BASELINE" ] || [ -z "$JAVA_HOME" ]; then
  printf 'REFUSING to write: REIMAGE_JDK_BASELINE=%s JAVA_HOME=%s\n' \
    "${REIMAGE_JDK_BASELINE:-<empty>}" "${JAVA_HOME:-<empty>}"
  printf 'Fix the empty one above before running upsert-env.\n'
else
  python3 bin/prepare-artifact-root.py \
    upsert-env \
    --env-file reimage.env \
    "REIMAGE_JDK_BASELINE=${REIMAGE_JDK_BASELINE}" \
    "JAVA_HOME=${JAVA_HOME%/}"
fi
```

Confirm what landed, rather than trusting the write:

```bash
grep -E '^(export )?(REIMAGE_JDK_BASELINE|JAVA_HOME)=' reimage.env
```

`REIMAGE_JDK_BASELINE` is the durable value: it names an intent that survives
reinstalling the JDK. `JAVA_HOME` is a convenience — a resolved absolute path,
so it goes stale if the JDK moves or the baseline changes. Phase 10B re-derives
it from the baseline rather than trusting the stored path, which is why the
baseline is the one that matters.

If several JDKs are needed later, keep the switch helpers explicit rather than
editing `JAVA_HOME` by hand each time. Substitute the majors your projects
actually need:

```bash
JDK_MAJORS="1.8 11 17 21"
for V in $JDK_MAJORS; do
  alias "jdk$(printf '%s' "$V" | tr -d '.')=export JAVA_HOME=\$(/usr/libexec/java_home -v $V)"
done
alias | grep '^jdk'
```

Each alias resolves its JDK at the moment you invoke it, so one that is not
installed fails then rather than at definition time.

> [!bug] Troubleshooting
> If `java -version` reports something other than the JDK you just installed, see [[#`java -version` prints a version different from the baseline|`java -version` prints a version different from the baseline]].

Do not `brew install node` here; the next step explains why. Installing both `brew`'s `node` and `nvm`'s `node` creates a PATH collision where it is unclear which binary actually runs.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 8 — Install and Manage Node Versions

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

There are no projects on this Mac yet. Phase 11B clones the repositories, so at
Phase 10A there is no `package.json` or `.nvmrc` anywhere to read and a
per-project version check has nothing to check. Install one sensible baseline
now, and let each project ask for its own version once it exists.

The pre-image capture recorded what this Mac was running before the erase. That
is the baseline to reinstall:

```bash
cat "$REIMAGE_ARTIFACT_ROOT/system-inventory"/pre-image-*/11-node.txt
```

Install that major version — or the current LTS if the capture is unavailable or
the recorded version is no longer supported:

```bash
nvm install --lts
```

Make it the default for new shells, so a shell that has not entered any project
still has a working `node`:

```bash
nvm alias default "$(nvm current)"
```

Confirm the tooling resolves:

```bash
node --version
```

```bash
npm --version
```

**Per-project versions come later, and mostly take care of themselves.** Once
Phase 11B has cloned the repositories, a project pinning its version carries a
`.nvmrc`, and `nvm use` in that directory reads it with no argument:

```bash
cd <project> && nvm use
```

A project declaring `engines.node` in `package.json` instead states a range
rather than a version; check it when a build complains, not before:

```bash
grep -A2 '"engines"' package.json
```

Installing a second version at that point is one `nvm install` and costs nothing,
which is why guessing at project requirements now is wasted effort.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 9 — Install Platform CLIs and Helper Utilities

Install the common platform tools, one at a time.

The Cloud Foundry CLI is installed from a versioned formula, and the major is a
deployment-compatibility choice rather than "whatever is newest" — a CLI ahead of
the foundation it talks to fails at push time, not install time. Name it once and
substitute the major your foundation expects:

```bash
CF_CLI_MAJOR="7"
brew install "cloudfoundry/tap/cf-cli@$CF_CLI_MAJOR"
```

```bash
brew install --cask fly
```

```bash
brew install jq
```

```bash
brew install kotlin
```

```bash
brew install wget
```

```bash
brew install yq
```

Confirm each resolves:

```bash
cf --version
```

```bash
fly --version
```

```bash
jq --version
```

```bash
kotlin -version
```

```bash
wget --version | head -1
```

```bash
yq --version
```

> [!bug] Troubleshooting
> **`zsh: command not found: cf` after the install reported success.** Three
> separate causes produce this identical symptom, and they stack — resolving one
> leaves the next in place, which is why the command keeps failing after each
> apparent fix. Work them in order.
>
> **1. The tap was added but the formula never was.** Tapping and installing are
> separate operations, and a `Brewfile` listing `tap "cloudfoundry/tap"` with no
> matching `brew "cf-cli@<major>"` line reproduces exactly this state:
>
> ```bash
> brew install "cloudfoundry/tap/cf-cli@$CF_CLI_MAJOR"
> ```
>
> **2. Current Homebrew refuses formulae from untrusted third-party taps.** The
> error names the fix, and `brew trust` does exactly what it says — it records
> trust and nothing else. It does **not** retry the command you were running, so
> the operation that triggered the error still has to be re-run afterwards:
>
> ```bash
> brew trust cloudfoundry/tap
> ```
>
> **3. Versioned formulae install unlinked.** `cf-cli@<major>` is keg-only by design, so
> "already installed" and "on `PATH`" are different facts. `brew install` on an
> already-present keg says *"already installed, it's just not linked"* and stops —
> which reads like success:
>
> ```bash
> brew link "cloudfoundry/tap/cf-cli@$CF_CLI_MAJOR"
> ```
>
> ```bash
> cf --version
> ```
>
> If linking is refused because it would overwrite another version, either
> `brew link --force "cloudfoundry/tap/cf-cli@$CF_CLI_MAJOR"`, or leave it unlinked and put its
> own prefix on `PATH` instead:
>
> ```bash
> printf 'export PATH="%s/bin:$PATH"\n' "$(brew --prefix "cf-cli@$CF_CLI_MAJOR")" >> "$HOME/.zprofile"
> ```

**An unlinked keg is invisible to a casual check.** `brew list --formula` omits
it, so a failed bulk install can look like it installed nothing while having
installed several things unlinked. `brew list --formula --full-name` and
`ls /opt/homebrew/Cellar` show what is actually on disk — worth knowing before
concluding that a `brew bundle` run left no trace.

**A freshly reimaged Mac has no Gatekeeper history, so unsigned casks are blocked
on first launch.** `fly` is the one that bites here: macOS reports *"Apple could
not verify 'fly' is free of malware"* and refuses to run it. The binary is fine —
Concourse ships it unsigned and unnotarized — but this Mac has never approved it
before, and the erase removed whatever approval existed.

Approve it deliberately rather than reflexively. Confirm it came from Homebrew
and not a stray download:

```bash
ls -l "$(which fly)"
```

Then clear the quarantine flag on that path:

```bash
xattr -d com.apple.quarantine "$(readlink -f "$(which fly)")"
```

Or approve it through the UI instead, which is equivalent and leaves an audit
trail: **System Settings → Privacy & Security**, find the blocked item, choose
**Open Anyway**.

On a managed Mac, Gatekeeper policy can be MDM-controlled. If neither route
works, that is policy rather than a broken install, and it is an IT question.

If a workflow still needs legacy `yq` v3 syntax, install it intentionally and document why in a personal note under the restore evidence, rather than silently replacing the Homebrew version.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 10 — Compare Versions Against Captured Inventories

Compare the rebuilt runtime layer against the captured pre-image inventory. Preview the options, then run it:

```bash
bash bin/compare-restored-state.sh --runbook restore-runtime --help
bash bin/compare-restored-state.sh --runbook restore-runtime --dry-run
bash bin/compare-restored-state.sh --runbook restore-runtime
```

`--dry-run` prints the table without writing; the plain form writes a run under
`reimaged-system/comparisons/` and prints a one-line summary. The run directory
holds `comparison.md`, the rendered note, and `rows.tsv`, the joined rows a later
comparison reads instead of reparsing the Markdown. To open the newest run without
reading dates off directory names, take the run name from
`comparisons/official/restore-runtime-inventory-diff.txt`.

**The row that matters is `MISSING`** — a tool recorded pre-image and absent now.
That is the one a human scanning terminal output reliably misses, because
nothing prints when nothing is installed. `differs` is the normal outcome of a
rebuild: an approved-newer version is expected, and only an unexplained *older*
version is worth chasing.

Comparison is on the version number rather than the raw string, so `10.9.7` and
`npm 10.9.7` count as the same; both raw strings are shown so you can see what
each side reported.

The comparison reads the `system-inventory/pre-image-YYYYMMDD-HHMMSS/` bundle
captured before the erase; that is the only inventory that exists at this point.
The matching `post-image-` bundle belongs to Phase 13B, along with the audit that
reads both — nothing here needs it.

The script probes fifteen tools. If you need to check one it does not cover, or
to see full output rather than a first line:

```bash
/usr/libexec/java_home -V || true
gradle --version || true
fly --version || true
```

Focus on whether the rebuilt Mac is now ready for the next restore phases, not on matching every older minor version. An approved-newer version is fine; an unexplained-older or missing tool is not.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 11 — Close Out the Exit Criteria

Confirm what this phase produced. This is a close-out, not a check of the next
phase: Phase 10B verifies its own entry conditions in its Step 0, the same way
this runbook did in Step 0.

Three parts, in this order: record the comparison for real, run the checklist,
then answer by hand the rows the checklist could not.

**First, put the comparison on disk.** `--dry-run` writes nothing, so a Step 10
that ended on the dry run gives the checklist a `FAIL` it cannot resolve on its
own. Running this again when it has already been recorded is harmless:

```bash
bash bin/compare-restored-state.sh --runbook restore-runtime
```

**Then run the checklist.**

```bash
bash bin/record-restore-exit.sh --runbook restore-runtime
```

It writes `checklist.md` under `reimaged-system/boundaries/` and exits non-zero
on any `FAIL`. That file holds the **Automated** rows — what the script probed.
The rows it cannot answer go to a sign-off under `reimaged-system/sign-offs/`,
which the run names at the end, because a rerun replaces the run directory and
would take an answer with it.

This is the exit half of a pair; `record-restore-prereqs.sh` is the entry half,
run at each phase's Step 0. One check per boundary — Phase 10A's exit and Phase
10B's entry are separate questions asked by separate runbooks, rather than one
runbook reaching across into the next.

Route by what the Automated table shows:

- [[#Investigate the Rows That Are Not PASS|Investigate the Rows That Are Not PASS]] — any row is `FAIL` or `WARN`.
- [[#Answer the Manual Rows|Answer the Manual Rows]] — every row is `PASS`.

#### Investigate the Rows That Are Not PASS

Each command below re-runs one row's check and shows the full output the row
summarised, so run only the ones whose rows need it.

*Row: Rosetta 2 available.*

```bash
arch -x86_64 /usr/bin/uname -m
```

Prints `x86_64` when Rosetta 2 is installed. On an Intel Mac it is a no-op that
also prints `x86_64`, so the row is uninformative there.

*Row: Xcode Command Line Tools.*

```bash
xcode-select -p
```

Prints the active developer directory, normally
`/Library/Developer/CommandLineTools`.

*Row: Homebrew installed.*

```bash
brew doctor
```

`Your system is ready to brew.` is the clean result. Warnings are advisory —
Homebrew says so itself — and a deprecated cask is a note to revisit rather than
a blocker.

*Row: Java resolves via java_home.* The major comes from `REIMAGE_JDK_BASELINE`,
the same key the checklist reads, so both ask about the same JDK.

```bash
/usr/libexec/java_home -v "${REIMAGE_JDK_BASELINE:-21}"
```

Prints the JDK path and exits `0`. This is the row that matters most, and the
only one whose failure is invisible until a later phase.

`echo "$JAVA_HOME"` printing nothing here is **expected and correct**. Nothing in
Phase 10A sets it; [[restore-access|restore-access.md]] Step 6 does. What must
work now is `java_home` itself, because Step 6 wraps it in command substitution —
which swallows a non-zero exit, leaves `JAVA_HOME` empty, and writes
`jssecacerts` to a path that is neither the JDK nor a directory that exists, at
which point the TLS smoke test fails for a reason unrelated to the certificate.

*Row: direnv installed and hooked.*

```bash
cd .. && cd "$FRACTOGENESIS_HOME"
```

direnv prints `unloading` then `loading` — the round trip proving the hook is
live rather than merely installed.

*Row: JVM build tools run.*

```bash
gradle --version
```

```bash
mvn --version
```

*Row: Node tooling runs.*

```bash
node --version
```

```bash
npm --version
```

#### Answer the Manual Rows

Nothing re-probes these and no later phase collects them: you answer them by
editing `checklist.md` itself. Replace each `TODO` with the answer and put the reasoning in Notes. `yes` and `accepted`
close a row, and so does `no` when `no` is the considered answer — the check is
for rows nobody looked at.

*Version drift reviewed.* Read the `differs` rows in `comparison.md`, in the run
Step 10 recorded. A newer version is the expected outcome of a
rebuild and closes as `accepted`. An *older* version is the one to explain: say
in Notes why it is older and whether that is deliberate.

*Platform CLI gaps accepted.* If the Platform CLIs row is `WARN` it names what is
missing. Close as `accepted` and name in Notes the ones this machine does not
need. If one turns out to be needed, install it and rerun rather than accepting
the row.

> [!warning] Pitfall
> A rerun carries your answers forward, but does not re-verify them. The new
> sign-off copies each answer along with the run it was answered against, so a
> row still naming an older run is *carried*: durable, but last checked against
> a capture this run has replaced. Clear a row's `Answered against` cell to
> re-affirm it on the next run.

The exit criteria for this phase:

| Area | Expected result |
|---|---|
| Rosetta 2, Xcode CLT, Homebrew | Installed and healthy. |
| direnv | Hooked, `.envrc` allowed, and `FRACTOGENESIS_HOME` populating on `cd`. |
| Java | JDK 21 present and resolving through `java_home`. |
| Build and Node tooling | Gradle, Maven, `node`, and `npm` run. |
| Platform CLIs | The utilities from Step 9 run. |
| Version comparison | Recorded, with every drift either an approved-newer version or an intentional decision. |

Once those hold, move to [[restore-access|restore-access.md]]. Its Step 0 will
re-verify what it needs from its own side — including the `java_home` row above,
which is the one worth catching twice.

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

Three install-time failures have fixes long enough to break the flow of the step that surfaces them. Each of those steps links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Every new terminal asks about insecure directories

```text
zsh compinit: insecure directories, run compaudit for list.
Ignore insecure directories and continue [y] or abort compinit [n]?
```

zsh's `compinit` audits every directory on `FPATH` before loading completions
from it and refuses any that is group- or world-writable, because everything on
`FPATH` is executed in your shell. Homebrew creates its `share/` directories that
way.

Seeing this means the permissions were never closed, or a directory has been
added to `FPATH` since. The fix is three commands and it lives in
[[#Step 3 — Install Homebrew|Step 3]] — run them there, then open a new terminal.

Two things that step does not cover, because they only show up here:

- **`compaudit` still lists something after the `chmod`.** The objection is
  ownership rather than mode: it also refuses anything owned by neither you nor
  root. Read `ls -ld` on it before taking ownership of something MDM placed
  there.
- **The prompt appeared long after Step 3.** Something put a new directory on
  `FPATH` — a shell config merged in Phase 10B Step 8 is the usual cause. Rerun
  the same three commands; nothing about them is one-time.

**Fix it rather than silencing it.** `compinit -u` skips the audit, which is the
common advice and the wrong trade. Beyond what the check is for, that prompt is
an interactive `read` running at shell startup: paste a multi-line block into a
fresh terminal and its first line is consumed as the answer instead of running.
A command block that half-executes is worse than one that fails, and this is the
only way it can happen before the block is even reached.

[[#Step 4 — Update Homebrew and Run Diagnostics|⮕ Continue to Step 4 — Update Homebrew and Run Diagnostics]]

### `brew doctor` reports a stale `/usr/local` on Apple silicon

Homebrew was previously installed under `/usr/local` (Intel path) and left behind by the reimage. Remove the stale prefix only after confirming nothing under it is needed:

```bash
ls /usr/local
sudo rm -rf /usr/local/Homebrew
```

Rerun `brew doctor` afterward and confirm the stale-prefix warning is gone before installing packages.

[[#Step 6 — Install direnv and Restore the Repo Environment Hook|⮕ Continue to Step 6 — Install direnv and Restore the Repo Environment Hook]]

### `java -version` prints a version different from the baseline

`/usr/libexec/java_home -V` lists every installed JDK; the default is the first one, which is not necessarily the one Step 7 installed. Set `JAVA_HOME` explicitly for the current session:

```bash
export JAVA_HOME="$(/usr/libexec/java_home -v "$REIMAGE_JDK_BASELINE")"
java -version
```

If `REIMAGE_JDK_BASELINE` is empty here, this shell never loaded `reimage.env` — `source reimage.env` first rather than substituting a number, so the value stays in one place.

Persist that export in `~/.zprofile` only if the baseline is your intended machine-wide default; Step 7 already recorded it in `reimage.env` either way.

[[#Step 8 — Install and Manage Node Versions|⮕ Continue to Step 8 — Install and Manage Node Versions]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link,
  except Troubleshooting, whose back-link sits under its intro and whose routed
  symptom subsections stay out of the Table of Contents.
-->
