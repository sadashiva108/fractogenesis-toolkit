[[reimaging-guide#Phase 4B — System Inventory Capture|← Back to Mac Reimaging Guide]]

# Capture System Inventory

**Last updated:** 2026-08-17

A script-first, one-pass record of how this Mac is configured — hardware and macOS, disk and display, installed apps, Homebrew, shell and dotfiles, Git, the language runtimes (Python, Java, Node), Docker, network and SSH, cloud paths, redacted environment clues, and certificate pointers. It observes and records; the only things it writes are into the bundle. Run it pre-image (Phase 4B) to preserve a before-reimage picture, and again post-image (Phase 13B) to compare the rebuilt machine against that record.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#What Gets Captured|What Gets Captured]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Bundle Layout|Bundle Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Prepare and Validate|Step 1 — Prepare and Validate]]
    - [[#Step 2 — Run the Capture|Step 2 — Run the Capture]]
    - [[#Step 3 — Capture the Restore-Relevant State|Step 3 — Capture the Restore-Relevant State]]
    - [[#Step 4 — Verify Outputs|Step 4 — Verify Outputs]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Per-Section Command Reference|Per-Section Command Reference]]
    - [[#Manual context note only when needed|Manual context note only when needed]]
    - [[#How a Single-Section Refresh Works|How a Single-Section Refresh Works]]
    - [[#Interpretation Notes|Interpretation Notes]]
    - [[#Pre-Image vs Post-Image Comparison|Pre-Image vs Post-Image Comparison]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Preserve a precise, timestamped inventory of how this Mac is set up before it is wiped, and produce the same inventory afterward so the two can be compared. The capture is reference evidence you read while rebuilding — it is not a backup you restore from. It exists so that, after reimage, you can tell what came back, what is missing, and what changed, and so the restore runbooks have an authoritative record of versions and configuration to work against.

**What it sets up**

- **The timestamped bundle** — one self-contained run directory under `system-inventory/`, holding the 16 numbered section files and `MANIFEST.txt`.
- **The Brewfile** — the `brew bundle dump` output written into the bundle, the single most valuable restore artifact for reinstalling formulae and casks.
- **The inventory-reference dotfiles snapshot** — a copy of the key dotfiles inside the bundle, so versions and shell config read cleanly beside the section files.
- **The matched pre/post pair** — the same section shape captured at Phase 4B and again at Phase 13B, so the two sides diff cleanly.

**What the rest of the workflow relies on it for**

- The restore runbooks read the bundle as the authoritative record of the versions and configuration the rebuilt machine must match.
- Phase 13B recaptures the same sections on the rebuilt Mac and reads this bundle as the baseline to compare against.
- The Phase 6B readiness sign-off checks the hand-verified items recorded beside the bundle — the System Settings screenshots and any manual context note.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| the system-inventory capture and its timestamped bundle | verifying every repo is pushed to GitHub — `backup-repos` (Phase 2A) |
| the 16 numbered section files, `MANIFEST.txt`, the `Brewfile`, and the inventory-reference `dotfiles/` snapshot | the authoritative home and dotfiles copy — `backup-home` (Phase 2B) |
| the pre-image (Phase 4B) and post-image (Phase 13B) comparison workflow | IntelliJ settings and application config export — `backup-apps` / `backup-intellij` (Phase 2D) |
| the full `system-inventory/` layout | certificate and Keychain staging — `stage-certs-keychain` (Phase 3A) |
| | license keys and secret material — `create-secrets-dmg` (Phase 3C) |
| | cross-phase readiness sign-off — `reimage-prep-checks` (Phase 6B) |

This capture can be rerun at any time: each run writes a fresh timestamped bundle and leaves earlier runs untouched.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. A Mac's configuration is spread across many independent subsystems — Homebrew, the shell, each language toolchain, Docker, the network stack — and no single command reports all of it. This capture runs one query per subsystem, writes each result to its own numbered file, dumps a `Brewfile` for restore, and copies key dotfiles into the bundle so the inventory is self-contained and readable on the external drive without the machine present.

The workflow is script-first. `capture-system-inventory.sh` runs every section in one pass and writes the bundle plus a `MANIFEST.txt`. The same sections are also documented as individual commands under Supplemental Reference, for the rare case where you need to rerun or troubleshoot just one — use the script for the standard run, the individual commands only when isolating a single section.

### What Gets Captured

One numbered file per subsystem, plus a manifest, a Brewfile, and a dotfiles snapshot:

```text
01  hardware      system_profiler SPHardwareDataType, csrutil
02  macos         sw_vers, uname
03  disk          diskutil list / apfs list, df, du
04  display        system_profiler SPDisplaysDataType
05  apps          /Applications, app versions, mas list if present
06  homebrew      brew leaves / list, brew doctor, and the Brewfile dump
07  shell         shell + version, PATH, and the dotfiles/ snapshot
08  git           git config --list, ~/.gitconfig, global gitignore
09  python        python / pyenv / conda / pip inventory
10  java          java -version, JAVA_HOME, JDKs, gradle, SDKMAN
11  node          node / npm / nvm and global packages
12  docker        docker version / info, images, containers, volumes
13  network       hostname, interfaces, ~/.ssh/config
14  cloud         CloudStorage, iCloud, OneDrive paths
15  env           environment variables, secrets redacted
16  certs         keychains and .env file locations (pointers only)
```

The `Brewfile` (section 06) is the single most valuable restore artifact — after reimage, `brew bundle install` reinstalls everything from it. The `dotfiles/` snapshot (section 07) is an inventory-reference copy so the versions and shell config read cleanly beside the section files; the authoritative dotfiles backup is [[backup-home|Backup Home]] (Phase 2B), not this runbook.

### Terminology

| Term | Meaning |
|---|---|
| Context | The `pre-image` / `post-image` label that prefixes the run directory. |
| Bundle | One timestamped run directory under `system-inventory/`, holding the 16 section files, `MANIFEST.txt`, the `Brewfile`, and the `dotfiles/` snapshot. |
| Brewfile | The `brew bundle dump` output — the primary restore artifact for reinstalling formulae and casks. |
| Dotfiles snapshot | The inventory-reference copy of key dotfiles in the bundle, distinct from the authoritative Phase 2B backup. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/capture-system-inventory.sh    # entrypoint
```

The individual commands behind each section file are documented under Supplemental Reference, for rerunning or troubleshooting a single section by hand.

Related scripts, alphabetical:

```text
$FRACTOGENESIS_HOME/bin/report-size-audit.sh          # entrypoint — capacity check for the artifact root
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/system-inventory/               # the run category; all bundles land under its runs/
```

### Bundle Layout

One lineage per context: `pre-image` from Phase 4B and `post-image` from Phase 13B. Both are latest-wins, so a rerun of either supersedes that context's current bundle and leaves the other alone. The `<context>` prefix comes from `--context` (default `pre-image`):

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── system-inventory/
│   ├── MANIFEST.md
│   ├── official/
│   │   ├── post-image.txt
│   │   └── pre-image.txt
│   └── runs/
│       └── <context>-YYYYMMDD-HHMMSS/
│           ├── 01-hardware.txt
│           ├── 02-macos.txt
│           ├── 03-disk.txt
│           ├── 04-display.txt
│           ├── 05-apps.txt
│           ├── 06-homebrew.txt
│           ├── 07-shell.txt
│           ├── 08-git.txt
│           ├── 09-python.txt
│           ├── 10-java.txt
│           ├── 11-node.txt
│           ├── 12-docker.txt
│           ├── 13-network.txt
│           ├── 14-cloud.txt
│           ├── 15-env.txt
│           ├── 16-certs.txt
│           ├── Brewfile
│           ├── MANIFEST.txt
│           └── dotfiles/
└── ...
```

Each file under `official/` holds one line naming the current bundle for that context, as `runs/<context>-YYYYMMDD-HHMMSS`. `MANIFEST.md` is the source of truth and is never edited by hand; the pointers are a derived cache, so regenerate them rather than writing one:

```bash
./bin/reindex-artifact-runs.sh --category "$REIMAGE_ARTIFACT_ROOT/system-inventory"
```

The complete `$REIMAGE_ARTIFACT_ROOT/system-inventory/` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the artifact root where `system-inventory/` lives. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. Set by your shell startup / `.envrc`, not stored in `reimage.env`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- `REIMAGE_ARTIFACT_ROOT` resolves and its destination volume is mounted (`reimage.env` produced by `prepare-artifact-root.md`).
- You are on the Mac being inventoried itself — the capture reports on the host it runs on.

> [!bug] Troubleshooting
> If a command block fails with an unbound `REIMAGE_ARTIFACT_ROOT`, `reimage.env` has not been produced or the volume is not mounted — rerun `prepare-artifact-root.md` and confirm the destination volume is attached before continuing.

### Confirm Your Intent

- Whether this is the **pre-image** run (Phase 4B, before wiping) or the **post-image** run (Phase 13B, after rebuild) — this sets `--context` and the bundle prefix.
- That you want a full system picture here, not app-settings or secret material — those belong to [[backup-apps|Backup Apps]] (Phase 2D) and the Phase 3A/3C secret staging, which are separate phases.
- Whether you will compare this bundle against an earlier one; if so, keep the pre-image bundle so the post-image run has something to diff against.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order: confirm the environment, run the capture, then verify the bundle. The capture is one command; the surrounding steps make sure it landed where you expect.

### Step 1 — Prepare and Validate

Confirm the artifact root resolves and the destination volume is mounted. `capture-system-inventory.sh` self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand:

```bash
./bin/capture-system-inventory.sh --help
```

Confirm the destination has room if you have not already run the size audit for this artifact root:

```bash
./bin/report-size-audit.sh --context pre-image-system-inventory
```

> [!note]
> No admin privileges are required for the read-only queries. Some sections may show fewer results without elevated rights, but the capture still completes and records what it can see.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Run the Capture

If you want section 12 to capture your Docker images, containers, volumes, and networks, start Docker Desktop before you run — with the daemon stopped, `12-docker.txt` records only a "cannot connect to the Docker daemon" error (the client version and `docker compose version` still capture). A `clean-boot` snapshot with Docker intentionally off is fine.

Run the full capture. For the pre-image run, the default context is correct, so no flag is needed:

```bash
./bin/capture-system-inventory.sh
```

For the post-image run (Phase 13B, after the Mac is rebuilt), set the context so the bundle is labelled distinctly:

```bash
./bin/capture-system-inventory.sh --context post-image
```

To point at a different artifact root for one invocation, add `--artifact-root PATH`. To write to an exact directory, use `--output DIR` — that skips the run layout *and* the index, so nothing under `official/` will point at the result. Use it for a scratch capture, never for the Phase 4B or 13B evidence.

The script prints each section as it runs and finishes with the bundle path and its run id. It writes the 16 section files, `MANIFEST.txt`, the `Brewfile`, and the `dotfiles/` snapshot under `system-inventory/runs/<context>-<stamp>/`, then indexes the run and moves `official/<context>.txt` onto it.

Re-capturing a single section is `--section NAME`, and it never edits the bundle you already have — it copies the official bundle of the same `--context` forward into a new run and overwrites just that one file:

```bash
./bin/capture-system-inventory.sh --section docker
```


> [!note]
> A section for a toolchain you do not use (for example `10-java.txt` with no JDK installed) is written with its header intact and no findings. An empty-but-present section is a valid result, not a failure.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Capture the Restore-Relevant State

The inventory above records **command output**: versions, lists, settings, as
text. This step records the other plane — path, mode, size and **SHA-256** for
each of the paths the restore phases have to put back:

```bash
./bin/capture-system-state.sh --phase pre-image --dry-run
./bin/capture-system-state.sh --phase pre-image
```

It writes `system-state/pre-image-<stamp>/state.tsv` and `state.md`.

**This is the step with a deadline.** After Phase 13 re-runs it with
`--phase post-image`, the two join into a cross-erase delta that says which
restored files are byte-identical to the originals, which merely exist, and —
the row nothing else in the workflow can produce — which paths the old machine
had that the rebuilt one does not.

None of that is recoverable later. The comparison needs a recording of a machine
that will not exist after the erase, and a version string is not one: `java`
reporting 21.0.11 on both sides is satisfied equally by a correct restore and by
a fresh install.

> [!warning] Pitfall
> The delta joins rows on absolute path, so the two captures must be taken as the
> same user with the same `$HOME`. `capture-system-state.sh` records both in
> `state.md` and refuses to build a delta when they differ, because joining
> mismatched homes reports every path as simultaneously added and removed — a
> result that looks like catastrophic data loss and means nothing.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Verify Outputs

Confirm the bundle landed and holds all 16 sections plus the manifest, Brewfile, and dotfiles snapshot.

```bash
LATEST="$REIMAGE_ARTIFACT_ROOT/system-inventory/$(cat "$REIMAGE_ARTIFACT_ROOT/system-inventory/official/pre-image.txt")"
echo "$LATEST"
ls -1 "$LATEST"
```

You should see `01-` through `16-`, `MANIFEST.txt`, `Brewfile`, and `dotfiles/`. Spot-check the Brewfile and hardware section, which carry the most restore-relevant evidence:

```bash
sed -n '1,40p' "$LATEST/Brewfile"
sed -n '1,40p' "$LATEST/01-hardware.txt"
```

> [!note]
> A few settings cannot be captured by `system_profiler` and stay a hand-verified item that rolls up to the Phase 6B sign-off: take screenshots of **System Settings → Displays** (arrangement and scaling), **Keyboard → Shortcuts**, **Trackpad**, **Accessibility**, and the **Privacy & Security** panes. Save them beside the generated bundle.

> [!bug] Troubleshooting
> A section file is empty or shows fewer results than you expected — see [[#A section is empty or shows fewer results than expected|A section is empty or shows fewer results than expected]].

> [!bug] Troubleshooting
> The `Brewfile` is empty or missing formulae you know are installed — see [[#The Brewfile is empty or missing formulae|The Brewfile is empty or missing formulae]].

> [!bug] Troubleshooting
> The bundle holds fewer than 16 section files — see [[#Fewer than 16 section files in the bundle|Fewer than 16 section files in the bundle]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script captures uniformly; deciding what is worth preserving beyond the bundle is the judgment call.

| Decision | Why it stays with you |
|---|---|
| Which locally-built Docker images or custom volumes are worth saving? | Official images re-pull from a registry; only you know which images and volumes you built locally and cannot recreate. |
| Is a pre- vs post-image difference expected? | A rebuilt machine legitimately differs (newer versions, reset defaults); deciding whether a delta is normal or worth acting on is yours to make. |
| Do you need the post-image run at all? | If you are not verifying the rebuild against the old machine, the pre-image bundle alone may be enough — the Phase 13B run is for comparison. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Three outcomes surface when you verify the bundle; each looks like a failure, and each needs a different response. The verify step links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### A section is empty or shows fewer results than expected

Some queries return less without elevated rights, and a toolchain you do not use will produce an empty section (for example `09-python.txt` with no pyenv or conda). An empty section file with its header intact means the command ran and found nothing — that is a valid result, not an error.

[[#Step 4 — Verify Outputs|⮕ Continue to Step 4 — Verify Outputs]]

### The Brewfile is empty or missing formulae

`brew bundle dump` only records what Homebrew installed. Formulae or casks installed outside Homebrew will not appear — confirm Homebrew itself is on `PATH` (`06-homebrew.txt` shows `brew doctor` output) and rerun the capture if `brew` was not found on the first pass.

[[#Step 4 — Verify Outputs|⮕ Continue to Step 4 — Verify Outputs]]

### Fewer than 16 section files in the bundle

The run was interrupted before completing. Delete or ignore the partial bundle and rerun `capture-system-inventory.sh` — each run writes a fresh timestamped directory, so a rerun does not overwrite anything.

[[#Step 4 — Verify Outputs|⮕ Continue to Step 4 — Verify Outputs]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Per-Section Command Reference

The individual commands behind each section file. Use these only to rerun or troubleshoot a single section; the script runs all of them in one pass.

**`01`/`02` — Hardware and macOS.** Model, chip, serial, memory, macOS version, kernel, and SIP status.

```bash
system_profiler SPHardwareDataType
sw_vers
uname -a
csrutil status
```

**`03` — Disk layout and volumes.** Disks, APFS containers, and mounted volume usage; confirm no unexpected external volumes are mounted before reimaging.

```bash
diskutil list
diskutil apfs list
df -h
```

**`04` — Display setup.** The display profile; arrangement and scaling are not captured here and need a screenshot.

```bash
system_profiler SPDisplaysDataType
```

**`05` — Installed applications.** Apps present and their versions; `mas list` adds Mac App Store apps when `mas` is installed.

```bash
ls -1 /Applications
system_profiler SPApplicationsDataType | grep -E "Location:|Version:"
mas list
```

**`06` — Homebrew and the Brewfile.** The Brewfile is the primary restore artifact — dump it into the bundle rather than to the Desktop. Restore after reimage with `brew bundle install --file <bundle>/Brewfile`.

```bash
brew bundle dump --file "$LATEST/Brewfile" --force
brew leaves
brew list --formula
brew list --cask
brew doctor
```

**`07` — Shell config and dotfiles.** Shell and version, `PATH`, and the dotfiles the script copies into `dotfiles/` (`.zshrc`, `.zprofile`, `.zshenv`, `.bashrc`, `.bash_profile`, `.gitconfig`, `.gitignore_global`, `.npmrc`, `.pip/pip.conf`, `.ssh/config`).

```bash
echo "$SHELL"
echo "$PATH" | tr ':' '\n'
grep -E 'plugins|ZSH_THEME' ~/.zshrc 2>/dev/null
```

**`08` — Git and SSH routing.** Global identity, default branch, credential helper, the global gitignore path, and `~/.ssh/config` — the two halves of how a Git operation picks an author and a key. The section closes with a normalized `ssh.hosts=` line listing the `Host` names in sorted order, which is what Phase 11A's comparison reads: the raw file is for a person, that line is the value a machine can compare against the restored Mac. Names only, never `HostName`, so an alias and the server behind it stay distinguishable.

```bash
git config --list --show-origin
cat ~/.gitconfig
cat ~/.ssh/config
```

**`09` — Python environment.** Interpreters on `PATH`, pyenv versions, conda environments, and global pip packages. Virtual environments rebuild from `requirements.txt`/`pyproject.toml`, so capture names and locations, not the envs themselves.

```bash
python3 --version
pyenv versions 2>/dev/null
conda env list 2>/dev/null
pip3 list 2>/dev/null
```

**`10` — Java and Gradle.** Active Java version, `JAVA_HOME`, installed JDKs, Gradle, and SDKMAN candidates.

```bash
java -version 2>&1
echo "$JAVA_HOME"
ls /Library/Java/JavaVirtualMachines/ 2>/dev/null
gradle --version 2>/dev/null
```

**`11` — Node.js and npm.** Node and npm versions, nvm-installed versions, and global npm packages (CLI tools like `typescript`, `prettier`, `eslint`).

```bash
node --version 2>/dev/null
npm --version 2>/dev/null
nvm ls 2>/dev/null
npm list -g --depth=0 2>/dev/null
```

**`12` — Docker.** Engine versions, images, containers, volumes, and networks. Official images re-pull from a registry; save only locally-built images — a judgment call that stays with you. Start Docker Desktop first, or these record only daemon-unreachable errors.

```bash
docker version 2>/dev/null
docker images -a 2>/dev/null
docker ps -a 2>/dev/null
docker volume ls 2>/dev/null
```

**`13` — Network and SSH.** Computer name, interfaces, and the SSH client config. SSH keys are secret material — they belong to Phase 3A/3C staging, not this bundle.

```bash
scutil --get ComputerName
ifconfig | grep -E 'inet |flags'
cat ~/.ssh/config 2>/dev/null
```

**`14` — Cloud paths.** Mounted cloud providers, iCloud Drive folders, and the OneDrive location. Confirm OneDrive and iCloud have fully synced before reimaging.

```bash
ls ~/Library/CloudStorage/ 2>/dev/null
ls ~/Library/Mobile\ Documents/com~apple~CloudDocs/ 2>/dev/null
```

**`15` — Environment variables.** Environment clues with secrets filtered out; review the file afterward to confirm nothing sensitive slipped through.

```bash
env | grep -Ev 'SECRET|TOKEN|KEY|PASS|PWD|AWS|CREDENTIAL' | sort
```

**`16` — Certificates and keychains.** Pointers only — keychain list and `.env` file locations, no contents. Actual certificate and Keychain export is Phase 3A staging.

```bash
security list-keychains
find ~ -name '.env' -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | head -30
```

### Manual context note only when needed

Run the script first, review the output under `$REIMAGE_ARTIFACT_ROOT/system-inventory/`, and add a manual note only if a detail that still matters is missing. Do not retype evidence the bundle already captured successfully.

Add a short manual note only when a missing detail still matters, such as:

- a **System Settings** screenshot the script cannot capture — Displays arrangement and scaling, Keyboard shortcuts, Trackpad, Accessibility, and the Privacy & Security panes (Full Disk Access, Developer Tools);
- a restore constraint for a licensed app or installer (the license material itself is staged in Phase 3A/3C, not here);
- a one-off environment quirk that would not be obvious from the generated bundle alone.

Save that note and any screenshots beside the generated bundle under `$REIMAGE_ARTIFACT_ROOT/system-inventory/runs/<context>-<stamp>/`. These hand-verified items roll up to the Phase 6B [[reimage-prep-checks|reimage-prep-checks]] sign-off.

### How a Single-Section Refresh Works

`--section NAME` stages a new run, copies the official bundle of the same `--context` into it, overwrites the one section file being re-captured, and promotes the result. The bundle it copied from is untouched and stays on disk.

This is why the bundle the pointer resolves to is always complete. Editing the section in place would leave a promoted run whose contents no longer match the index row naming it; writing a one-file bundle instead would leave the pointer resolving to a bundle missing fifteen sections. Copying forward is what avoids both, and a bundle is around 120 KB, so it costs little.

Two things record what happened, and they are worth reading together:

- The new bundle's `MANIFEST.txt` names the section captured at its generation date, and the run every other file was carried from.
- The category `MANIFEST.md` row reads `section '<name>' refreshed, rest carried from <run-id>`.

Each carried file keeps its own original `# Generated:` header, so a timestamp inside a section file is the time that section was captured — not the time of the bundle holding it.

`--new-bundle` writes a bundle holding that section alone. Use it when there is no baseline worth carrying; it is the wrong choice when there is, because the pointer would then resolve to an incomplete bundle.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Interpretation Notes

Read each section for what it is best at: `01`/`02` for the machine and OS baseline, `06` for what to reinstall, `07`/`08` for shell and Git configuration, `09`–`12` for the toolchains a rebuilt machine must match, and `13`–`16` for network, cloud, and pointer evidence. The bundle is the evidence — reference the section file rather than retyping versions and paths into a separate note. Add a short written note only when a detail still needs explaining after reviewing the captured files.

### Pre-Image vs Post-Image Comparison

The pre-image bundle (Phase 4B) and the post-image bundle (Phase 13B) share the same section shape, so they diff cleanly. After the rebuild, compare matching section files to see what came back, what is missing, and what changed:

```bash
CATEGORY="$REIMAGE_ARTIFACT_ROOT/system-inventory"
PRE="$CATEGORY/$(cat "$CATEGORY/official/pre-image.txt")"
POST="$CATEGORY/$(cat "$CATEGORY/official/post-image.txt")"
diff "$PRE/06-homebrew.txt" "$POST/06-homebrew.txt"
diff "$PRE/Brewfile"        "$POST/Brewfile"
```

Timestamps and generation dates in the file headers will always differ; focus on the payload lines. Expect some legitimate churn from newer versions and reset defaults — the point is to surface anything unexpected, not to demand an identical match.

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
