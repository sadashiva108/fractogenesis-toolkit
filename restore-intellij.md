[[reimaging-guide#Phase 12 — Restore Apps|← Back to Mac Reimaging Guide]]

# Restore IntelliJ

**Last updated:** 2026-09-02

Restore IntelliJ IDEA and per-project state on the reimaged Mac in a controlled sequence so imported settings, Scratches, project metadata, and HTTP Client environments end up in the right places without dragging stale machine-specific paths forward or leaking secret material into unencrypted storage. This is the dedicated Phase 12 IntelliJ handoff the umbrella app phase hands to; the companion script `bin/restore-intellij.sh` writes a per-run plan-note that surveys the available pre-image sources and provides the sign-off checklist.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Bundle Layout|Bundle Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Generate the IntelliJ Plan-Note|Step 1 — Generate the IntelliJ Plan-Note]]
    - [[#Step 2 — Install IntelliJ IDEA|Step 2 — Install IntelliJ IDEA]]
    - [[#Step 3 — First Launch and Quit|Step 3 — First Launch and Quit]]
    - [[#Step 4 — Import the Manual Settings ZIP|Step 4 — Import the Manual Settings ZIP]]
    - [[#Step 5 — Restore Scratches Consoles and IDE State|Step 5 — Restore Scratches Consoles and IDE State]]
    - [[#Step 6 — Restore Project Idea Metadata Selectively|Step 6 — Restore Project Idea Metadata Selectively]]
    - [[#Step 7 — Restore HTTP Client Request Files|Step 7 — Restore HTTP Client Request Files]]
    - [[#Step 8 — Restore HTTP Client Env Files from the Encrypted DMG|Step 8 — Restore HTTP Client Env Files from the Encrypted DMG]]
    - [[#Step 9 — Validate Project SDKs Gradle and Tests|Step 9 — Validate Project SDKs Gradle and Tests]]
    - [[#Step 10 — Close the Plan-Note Sign-Off|Step 10 — Close the Plan-Note Sign-Off]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Bring IntelliJ IDEA back to a working state for every project that mattered pre-image, without spraying secrets into unsafe paths and without overlaying stale machine-specific metadata onto the clean install. That means installing IntelliJ from the approved channel, importing the manual settings ZIP produced by the Phase 2D IntelliJ backup rather than copying `options/` files by hand, restoring Scratches and Consoles and selected project `.idea` subtrees only from the matching IntelliJ version subtree, and treating HTTP Client environment files (which routinely embed bearer tokens and shared-secret headers) as encrypted-DMG material even when their `.json` extension makes them look ordinary.

**What it sets up**

- **The IntelliJ plan-note** — a timestamped `restore-intellij-plan-*.md` under `reimaged-system/restore-notes/` that surveys which pre-image IntelliJ sources are present. It is regenerable.
- **The IntelliJ sign-off** — `reimaged-system/sign-offs/restore-intellij-YYYYMMDD-HHMMSS.md`, holding the rows you answer. A rerun carries your answers forward and stamps each with the run it was answered against.
- **A working IntelliJ install** — IntelliJ IDEA installed from the approved channel and launched once so it owns its own Application Support paths, with version and install source recorded.
- **Restored IDE-level state** — the manual settings ZIP imported, plus Scratches, Consoles, and per-version `config-copy/` content from the matching version subtree.
- **Restored project state** — the selected `.idea` categories per repo and the non-secret HTTP Client request files that go with them.
- **Restored HTTP Client environments** — `*.env.json` files copied into the correct projects from the encrypted secret store only, with the DMG ejected again immediately.

**What the rest of the workflow relies on it for**

- The Phase 12 umbrella plan-note cannot close its `IntelliJ dedicated restore completed` row until this runbook is done.
- Phase 14 `reimaged-system-checks` reads the newest `restore-intellij-*.md` under `reimaged-system/sign-offs/` and reports any row still on `TODO`, and any row answered against an older run.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| the IntelliJ-specific restore plan-note and its sign-off checklist | the pre-image IntelliJ capture and settings ZIP export — `backup-intellij` (Phase 2D) |
| installing IntelliJ IDEA and recording the version and install source | umbrella daily-apps ordering and the Office / Chrome / VS Code / Raycast steps — `restore-apps` (Phase 12) |
| first-launch handling, so the new install creates its own Application Support paths before restore | Docker Desktop, daemon state, and container rebuild — `restore-docker` (Phase 12) |
| importing the manual settings ZIP as the IDE-level restore path | JetBrains license activation as secret material under `secrets-encrypted/licenses/` — `restore-access` (Phase 10B) |
| restoring Scratches, Consoles, and per-version `config-copy/` content | SSH, GPG, kube, docker, and general credential restore — `restore-access` (Phase 10B) |
| selective project-level `.idea` metadata restore (`runConfigurations/`, `codeStyles/`, `inspectionProfiles/`) | Java trust overrides pinned to a JDK (`jssecacerts`) — `restore-access` (Phase 10B) |
| restoring non-secret HTTP Client request files (`*.http`, `*.rest`) from `project-metadata/` | repository re-clone and staged ignored files — `restore-repos` (Phase 11B) |
| routing HTTP Client environment files (`*.env.json`, `http-client.private.env.json`) from the encrypted DMG only | Git identity and remote routing — `restore-git` (Phase 11A) |
| validating Project SDK, Gradle JVM, run configurations, and test builds | the cross-phase post-image sign-off that reads these plan-notes — `reimaged-system-checks` (Phase 14) |

This runbook can be rerun. Regenerating the plan-note produces a fresh timestamped file under `reimaged-system/restore-notes/` and a new sign-off carrying your existing answers forward, so a rerun costs you nothing already recorded; prior plan-notes are preserved so you can compare a partial re-run against the last full pass.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. IntelliJ restore is deliberately not a "copy the whole Application Support folder back" operation — three different kinds of state overlap in the pre-image IntelliJ tree, and each has to be restored a different way to avoid either losing configuration or leaking secrets.

The first kind is IDE-level settings — keymaps, code style, inspection profiles, plugin list, editor behavior. The Phase 2D IntelliJ backup captures this into a `manual-settings-export/IntelliJ-settings-*.zip` file that IntelliJ can consume directly via `File → Manage IDE Settings → Import Settings`. This is the only IDE-level restore path used here; per-file overlays of `~/Library/Application Support/JetBrains/*/options/` are avoided because they routinely bring forward stale references after a major IntelliJ version bump.

The second kind is IDE-level ephemera worth preserving — Scratches, Consoles, IDE logs, and (per IntelliJ version) the `config-copy/` snapshot. This restores by copying from the matching `IntelliJIdea20YY.N/` subtree in `app-settings-backup/intellij/` into the newly-created Application Support path for the installed version.

The third kind is project-level metadata under each repo's `.idea/`. Some of it is safe and useful (run configurations, code styles); some of it is machine-specific (workspace.xml paths, local data source URLs); and some of it embeds credentials (`dataSources.local.xml`, HTTP Client `*.env.json`). The runbook restores this selectively, and treats the credential-embedding files as encrypted-DMG material — they never touch the ordinary `app-settings-backup/` path.

The Phase 12 order is deliberate: install first, launch once so IntelliJ creates its own paths, import the settings ZIP before restoring per-version content, then per-project metadata, then non-secret HTTP request files, then encrypted HTTP env files, then validate SDK / Gradle JVM / tests. Skipping the "launch once and quit" step is the most common source of import failures because IntelliJ silently ignores an import into a config directory it did not create itself.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later steps refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/restore-intellij.sh            # entrypoint — surveys the pre-image sources and emits the plan-note
```

Related scripts, alphabetical:

```text
hdiutil                                                # external helper — attaches and detaches the IntelliJ installer image in Step 2 and the encrypted secrets image in Step 8
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/                # every artifact this runbook generates lands here
```

Input evidence built by earlier phases:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/   # written by backup-intellij.md — settings ZIP, scratches, project metadata, HTTP Client requests
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-YYYYMMDD-HHMMSS.dmg   # written by create-secrets-dmg.md — attach it to reach the category below
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/intellij/     # written by create-secrets-dmg.md — HTTP Client env files that carry real credentials
```

The complete `app-settings-backup/` and `secrets-encrypted/` layouts are defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Bundle Layout

Everything this runbook writes, under the artifact root named above. The pre-image sources it reads are listed in the block before this one and are not expanded here; this tree is output only.

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── reimaged-system/
│   ├── ...
│   ├── restore-notes/
│   │   └── restore-intellij-plan-YYYYMMDD-HHMMSS.md
│   ├── sign-offs/
│   │   └── restore-intellij-YYYYMMDD-HHMMSS.md
│   └── ...
└── ...
```

Neither category is run-indexed, and that is deliberate. The plan-note is regenerable, so `restore-intellij.sh` replaces it on every run; the sign-off holds the rows you answered and carries them forward, so nothing may replace it. This phase records no bookend, state or comparison run — Phase 12 closes on the plan-note sign-off, which Phase 14 `reimaged-system-checks.md` reads.

Live IntelliJ paths on the reimaged Mac. These are restore targets, not artifact locations, and nothing under `$REIMAGE_ARTIFACT_ROOT` mirrors them:

```text
~/Library/Application Support/JetBrains/IntelliJIdea20YY.N/   # Steps 4-5 — imported settings, Scratches, IDE state
~/Library/Caches/JetBrains/                                   # rebuilt by the IDE; never restored from backup
~/Library/Logs/JetBrains/                                     # rebuilt by the IDE; read only when diagnosing a failed import
~/Library/Preferences/                                        # com.jetbrains.* plists
```

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Mounted external artifact volume that holds every pre-image backup and every post-image record. Required for `bin/restore-intellij.sh`; `--artifact-root PATH` overrides it for one invocation. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. Set by your shell startup / `.envrc`, not stored in `reimage.env`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phases 8, 9, 10A, 10B, 11A, and 11B are complete. In particular, the JDK targeted as Project SDK is installed (Phase 10A), the encrypted secrets DMG is available and its passphrase is known (Phase 3C / 10B), and the repositories whose `.idea/` metadata you plan to restore have already been re-cloned (Phase 11B).
- The external artifact volume is mounted and `$REIMAGE_ARTIFACT_ROOT` resolves; the pre-image `app-settings-backup/intellij/` subtree is reachable.
- You have already generated the Phase 12 umbrella plan-note via `restore-apps` Step 1. Restarting the umbrella plan-note is not required — this dedicated runbook writes its own plan-note — but running IntelliJ restore in isolation is unusual.

> [!bug] Troubleshooting
> If `$REIMAGE_ARTIFACT_ROOT` is unset or unreachable, either mount the artifact volume and re-source `reimage.env`, or pass `--artifact-root PATH` explicitly to `bin/restore-intellij.sh`.

### Confirm Your Intent

- Are you restoring every project that was open pre-image, or a smaller set? Restoring `.idea/` metadata for a project you no longer need drags stale run configurations forward for no benefit.
- Which IntelliJ version are you installing? The scratches / config-copy restore must land in the matching Application Support subtree; a version bump means falling back to the settings ZIP alone.
- Do you want the plan-note under the default `reimaged-system/restore-notes/`, or a scratch location (`--output-root ~/Desktop/…`)? The sign-off has its own `--signoff-root`, defaulting to `reimaged-system/sign-offs/`. Phase 14 `reimaged-system-checks.md` reads the sign-off from that default path.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. Each numbered step corresponds to a row (or row group) in the sign-off checklist emitted by `bin/restore-intellij.sh`.

### Step 1 — Generate the IntelliJ Plan-Note

Emit the plan-note that surveys which pre-image IntelliJ sources are available and provides the sign-off checklist:

```bash
./bin/restore-intellij.sh --open
```

The generated file lives under:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-intellij-plan-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimaged-system/sign-offs/restore-intellij-YYYYMMDD-HHMMSS.md
```

Skim the **Backup Sources**, **Detected IntelliJ Version Subtrees**, and **Secret-Bearing Sources** tables before continuing. If the version subtree table shows no `IntelliJIdea20YY.N/` rows, the Phase 2D IntelliJ backup did not produce per-version content and the scratches restore collapses to "settings ZIP only."

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Install IntelliJ IDEA

Install IntelliJ IDEA from the approved source (JetBrains Toolbox or direct). JetBrains license lookup for reference:

```text
https://account.jetbrains.com/licenses
```

**Verify the download before opening it.** JetBrains publishes a SHA-256 beside
every build; download it alongside the disk image. `shasum -c` reads the checksum
file and reports the result rather than leaving you to compare 64 hex characters
by eye, which is the step people skip and the one that catches a truncated
transfer:

```bash
DMG_FILE="replace-with-the-downloaded-dmg-filename"
( cd ~/Downloads && shasum -a 256 -c "$DMG_FILE.sha256" )
```

The subshell keeps your shell at the repository root; `shasum -c` resolves the
filename recorded inside the checksum file relative to the current directory, so
it has to run beside the image. Expect one line ending `: OK`. `FAILED` means
re-download — a partial transfer is the usual cause, and a `.dmg` that fails here
can still mount and install.

More often the checksum is **copied off the download page** rather than saved as
a file. Compare it directly instead of transcribing it into a file first, and let
the shell do the comparison rather than your eyes — a hash is exactly the kind of
string a person confirms by checking the first and last four characters:

```bash
DMG_FILE="replace-with-the-downloaded-dmg-filename"
EXPECTED="replace-with-the-hash-from-the-download-page"

DMG_PATH="$HOME/Downloads/$DMG_FILE"
ACTUAL="$(shasum -a 256 "$DMG_PATH" 2>/dev/null | awk '{print $1}')"
if [ -z "$ACTUAL" ]; then
  printf 'COULD NOT HASH - check the path\n  %s\n' "$DMG_PATH"
elif [ "$EXPECTED" = "$ACTUAL" ]; then
  echo "OK - checksum matches"
else
  printf 'MISMATCH - re-download\n  expected %s\n  actual   %s\n' "$EXPECTED" "$ACTUAL"
fi
```

Run it as one block. Split across separate pastes it is easy to set the two
values, skip the line that computes `ACTUAL`, and get `MISMATCH` with an empty
`actual` — a wrong answer that looks like a corrupt download rather than a missed
step. The empty-value branch exists for the same reason: an unreadable or
misnamed file and a genuinely different hash are different problems, and only one
of them is fixed by downloading again.

No subshell is needed here because the full path goes to `shasum` directly. Paste
only the hash into `EXPECTED` — JetBrains publishes the line as
`<hash> *<filename>`, and including the trailing filename reports MISMATCH on a
perfectly good image.

**A matching checksum proves transfer integrity, not authenticity.** It comes
from the same server as the image, so anyone able to serve a modified build can
serve a matching hash. Apple's notarization check is the separate question, and
on a managed Mac it is the one that matters. Ask it of the notarization ticket
directly — no mounting required:

```bash
xcrun stapler validate "$DMG_PATH"
```

`The validate action worked!` means Apple notarized this exact image.
**`does not have a ticket stapled to it` is not a failure** — a notarization
ticket can be stapled to a file for offline checking, or left to online lookup
where Gatekeeper asks Apple directly. Vendors commonly staple the application
inside the image and not the container. It only tells you this check cannot be
answered offline; it says nothing about authenticity.

The application is where the answer is. Attach the image:

```bash
hdiutil attach "$DMG_PATH"
```

The attach output is worth reading rather than scrolling past: each
`verified   CRC32` line is the disk image's own internal checksum passing, which
is independent of the SHA-256 comparison above. One says the bytes match what the
vendor published; the other says the image is structurally intact.

Let the volume and the application name themselves. The mounted volume name
carries a space, and the bundle name differs by edition:

```bash
VOL_PATH="$(find /Volumes -maxdepth 1 -type d -name 'IntelliJ*' | head -1)"
APP_PATH="$(find "$VOL_PATH" -maxdepth 1 -name '*.app' | head -1)"
echo "APP_PATH=$APP_PATH"
```

```bash
spctl -a -vvv "$APP_PATH"
xcrun stapler validate "$APP_PATH"
codesign -dv --verbose=2 "$APP_PATH" 2>&1 | grep -E 'Authority|TeamIdentifier'
```

`find` rather than a `*.app` glob, and not because the glob is longer to type: an
unmatched glob is an error in zsh that aborts the line, so a wrong volume name
would fail as a shell parse error rather than leaving `APP_PATH` empty for the
`echo` to reveal.

Three answers, strongest last. `spctl` should say `accepted` with
`source=Notarized Developer ID` — and if it does, it has already performed the
online notarization lookup, so an unstapled ticket has cost nothing but a
round-trip. `codesign` names who actually signed the build in its `Authority=`
line, which is the one fact none of the other checks give you: a hash proves the
bytes arrived intact, notarization proves Apple scanned it, and only the signing
authority tells you *whose* build this is.

A `rejected` from `spctl`, or a signing authority that is not the vendor you
expect, is the stop — whatever the checksum said.

**Copy the verified app into `/Applications`.** Only now, and in this order — the
bundle you keep is then the exact one the three checks above passed, and a
`rejected` build never reaches `/Applications` at all.

A JetBrains `.dmg` is drag-and-drop. There is no installer, no progress window
beyond Finder's copy sheet, and nothing that announces success at the end, which
is why confirming the copy is its own step below rather than something to take on
faith.

In the Finder window that opened when the image attached, drag **IntelliJ
IDEA.app** onto the **Applications** shortcut beside it. The bundle is roughly
4 GB, so the copy takes a moment. If macOS asks for an administrator password,
answer it — a dismissed prompt cancels the copy silently and leaves nothing
behind.

Confirm it landed and finished:

```bash
APP_DEST="$(find /Applications -maxdepth 1 -name 'IntelliJ*.app' | head -1)"
echo "APP_DEST=${APP_DEST:-not copied yet}"
du -sh "$APP_PATH" "$APP_DEST"
```

`find` here for the same reason it is used against `/Volumes` above: an unmatched
glob is an error in zsh that aborts the line, so a missing application would fail
as a shell parse error rather than leaving `APP_DEST` empty for the `echo` to
report.

Equal sizes mean the copy ran to completion. That is a weaker claim than it
looks, so ask the installed copy the same question the volume copy already
answered:

```bash
spctl -a -vvv "$APP_DEST"
```

`accepted` proves every byte of the signed bundle arrived: a truncated or
interrupted copy fails signature validation, where a size comparison alone can
still agree. That is the row worth recording in the plan-note.

> [!bug] Troubleshooting
> If `APP_DEST` prints `not copied yet`, the drag did not take. Open the mounted
> volume in Finder and drag the application icon onto the `Applications` shortcut
> inside that same window, not onto a Dock icon or a Finder sidebar entry.

Detach when done — `VOL_PATH` is still set from above:

```bash
hdiutil detach "$VOL_PATH"
```

> [!warning] Pitfall
> Do **not** reach for `spctl -a -t open --context context:primary-signature` on
> the `.dmg`. It is the most widely copied recipe for this check and it is the
> wrong tool: `-t open` assesses documents, and on a disk image it commonly
> returns `errSecCoreFoundationUnknown` — an error that names nothing, says
> nothing about the file, and reads like a failed verification when no
> verification happened. `spctl` is reliable against an **app bundle**, where its
> default execute context applies. Assess the app, staple-check the image.

Record the version installed, install source, install date, and that both checks
passed in the plan-note.

> [!note]
> Company-managed IntelliJ installs sometimes ship a slightly different version than what was on the pre-image system. Note the delta rather than trying to force a match — a settings ZIP produced by the older version generally imports cleanly into a newer one.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — First Launch and Quit

Launch IntelliJ once, dismiss any onboarding, and then quit. This lets IntelliJ create its own Application Support / Preferences / Caches / Logs paths for the newly-installed version before any restore writes into them:

```bash
ls -la "$HOME/Library/Application Support/JetBrains" 2>/dev/null || true
ls -la "$HOME/Library/Preferences" | grep -i jetbrains || true
ls -la "$HOME/Library/Caches/JetBrains" 2>/dev/null || true
ls -la "$HOME/Library/Logs/JetBrains" 2>/dev/null || true
```

Useful in-IDE menu paths for later verification:

```text
Help → Edit Custom Properties
Help → Edit Custom VM Options
Help → Diagnostic Tools → Debug Log Settings
Help → Show Log in Finder
```

> [!warning] Pitfall
> Skipping this step is the most common cause of "settings ZIP imported but nothing changed." IntelliJ silently ignores an import into a config directory it did not create itself. Always confirm the `IntelliJIdea20YY.N/` directory exists under `~/Library/Application Support/JetBrains/` before importing.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Import the Manual Settings ZIP

In IntelliJ:

```text
File → Manage IDE Settings → Import Settings
```

Point it at the ZIP path shown in the plan-note's **Most Recent Manual Settings Export** section (path under `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manual-settings-export/`).

After import, validate:

```text
keymap
editor settings
code style
plugins
inspection profiles
terminal settings
Gradle settings
HTTP Client settings visibility
```

Do not import or copy secrets from plain-text `.settings.jar` exports — the settings ZIP is IDE-level state only.

> [!bug] Troubleshooting
> If the import reports success but nothing in the IDE changed, see [[#IntelliJ imported the settings ZIP but nothing changed|IntelliJ imported the settings ZIP but nothing changed]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Restore Scratches Consoles and IDE State

Quit IntelliJ completely (Cmd-Q) before anything is copied into `~/Library/Application Support/JetBrains/…`, and confirm nothing is still running:

```bash
pgrep -fl idea || echo "OK: IntelliJ does not appear to be running"
```

IntelliJ holds this configuration in memory and rewrites `options/`, `scratches/`, and `consoles/` from memory when it exits — a copy made underneath a running IDE is silently overwritten the moment you quit, with no error anywhere.

Use the IntelliJ backup subtree as the source of truth:

```bash
open "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij"
```

Review manifests first so you know what the backup actually contains:

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij" -maxdepth 4 -type f \( -name '*manifest*' -o -name '*.tsv' -o -name '*.txt' \) | sort
```

Restore only into the matching IntelliJ version subtree for the new install. For example, if IntelliJ 2024.2 is installed:

```text
Source:  $REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/IntelliJIdea2024.2/scratches-and-consoles/
Target:  ~/Library/Application Support/JetBrains/IntelliJIdea2024.2/scratches/
         ~/Library/Application Support/JetBrains/IntelliJIdea2024.2/consoles/
```

Be careful with full `config-copy/options/` overlays across a major version change. Prefer the settings ZIP first; overlay individual `options/` files only when something specific did not import.

Relaunch IntelliJ afterwards, then confirm:

```text
Scratches are visible
Consoles are visible
plugins are available or reinstallable
custom VM options match intended heap settings
IDE logs do not show migration errors
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 6 — Restore Project Idea Metadata Selectively

Project `.idea` metadata can be helpful, but it can also drag stale paths forward or embed credentials. Review each category before copying:

| Category | Restore guidance |
|---|---|
| `runConfigurations/` | Usually safe and useful. Review absolute paths and env vars. |
| `codeStyles/` | Usually safe. |
| `inspectionProfiles/` | Usually safe. |
| `workspace.xml` | Review carefully. Often machine-specific. |
| `dataSources.xml` | Review carefully. May reference local DBs by absolute path. |
| `dataSources.local.xml` | Sensitive. Restore only if needed from encrypted backup. |
| HTTP Client `*.env.json` | Sensitive. Restore only from the encrypted DMG. |
| Password / Keychain-adjacent files | Do not restore loose. |

Quit IntelliJ completely (Cmd-Q) before copying into any project's `.idea/`, and confirm nothing is still running:

```bash
pgrep -fl idea || echo "OK: IntelliJ does not appear to be running"
```

IntelliJ rewrites `.idea/` — `workspace.xml` above all — when a project closes and again when the IDE exits, so metadata copied in while it is running is overwritten rather than adopted.

Per-project procedure:

```text
1. Open the pre-image project metadata folder under app-settings-backup/intellij/project-metadata/<repo>/.
2. Open the freshly-cloned repo's own .idea/ folder from Phase 11B.
3. Copy only the categories you decided to restore.
4. Relaunch IntelliJ and reopen the project.
5. Check Project Structure, Gradle settings, and run configurations before running anything.
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 7 — Restore HTTP Client Request Files

Non-secret HTTP Client request files can restore directly from the project-metadata bundle:

```text
*.http
*.rest
```

These are ordinary text files — safe to copy from `app-settings-backup/intellij/project-metadata/<repo>/` into the matching cloned repo without unlocking any secret material. Confirm nothing in a request file interpolates a hard-coded secret; if it does, treat it as if it were an `.env.json` and route it through the encrypted-DMG restore below instead.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 8 — Restore HTTP Client Env Files from the Encrypted DMG

HTTP Client environment files routinely embed bearer tokens, shared-secret headers, or client credentials. They come only from the encrypted secret store:

```text
http-client.env.json
http-client.private.env.json
*.env.json
```

Quit IntelliJ completely (Cmd-Q) before the copy — these files land inside a project's `.idea/`, which IntelliJ rewrites on project close and on exit. Confirm nothing is still running:

```bash
pgrep -fl idea || echo "OK: IntelliJ does not appear to be running"
```

Mount the IntelliJ HTTP Client secrets area (either the dedicated `secrets-encrypted/intellij/` folder or the consolidated `all-secrets-*.dmg`, per what the plan-note reported):

```bash
open "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/intellij"
```

Or, for the consolidated DMG:

```bash
DMG=$(ls "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/all-secrets-"*.dmg | tail -1)
hdiutil attach "$DMG"
```

Copy only the correct env file into the correct project, then eject the DMG. Relaunch IntelliJ afterwards and reopen the project, then confirm in the IntelliJ HTTP Client:

```text
environment dropdown appears
expected environment names are present
requests resolve variables
no secrets are accidentally committed
```

Check Git before committing anything in the project — this one runs from the project working tree, not the repo root:

```bash
cd /path/to/project
git status --ignored -s
```

> [!warning] Pitfall
> `*.env.json` files that look "small enough to just paste" have been the single most common source of secret leaks in this workflow. If a file is under `secrets-encrypted/`, it stays behind an unlocked DMG until the moment you copy it into a project, and the DMG ejects again immediately after.

> [!bug] Troubleshooting
> If a request resolves a variable as `null` after the copy, see [[#HTTP Client requests resolve null for a variable|HTTP Client requests resolve null for a variable]]. If `git status` lists an `.env.json` as staged or untracked in the working tree, see [[#git status shows an env.json staged after restore|git status shows an env.json staged after restore]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 9 — Validate Project SDKs Gradle and Tests

For each important project, open it in IntelliJ and confirm:

```text
Project SDK is set to the JDK installed in Phase 10A
Gradle JVM matches the Project SDK
run configurations are present and their paths resolve
HTTP Client environments load without missing-variable errors
no missing local env files
tests compile
```

Run a smoke command per stack:

```bash
./gradlew test
pytest
npm test -- --watchAll=false
```

For IntelliJ Gradle projects, check:

```text
Settings → Build, Execution, Deployment → Build Tools → Gradle → Gradle JVM
Project Structure → SDKs
Project Structure → Project SDK
```

Record per-project state in the plan-note:

| Project | SDK/JDK | Local env restored | Tests/build status | Notes |
|---|---|---|---|---|
| `TODO` | `TODO` | `TODO` | `TODO` |  |

> [!bug] Troubleshooting
> If IntelliJ offers no JDK for Project SDK or Gradle JVM, see [[#IntelliJ cannot find a JDK|IntelliJ cannot find a JDK]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 10 — Close the Plan-Note Sign-Off

Reopen the plan-note and flip every completed row from `TODO` to `Done`. Leave any row still open with a short note explaining why (e.g. `plugin deferred to next sprint`). Phase 14 `reimaged-system-checks.md` reads these plan-notes and will flag outstanding rows.

Return to `restore-apps` Step 8 and mark the `IntelliJ dedicated restore completed` row in the umbrella plan-note before continuing to Docker.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script surveys the available sources and emits the checklist; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Which project `.idea/` categories to restore per repo | The pre-image metadata reflects the previous machine's paths and habits. Some categories are almost always safe (runConfigurations, codeStyles), others depend on how you actually work. |
| Whether to overlay a specific `config-copy/options/` file after the settings ZIP import | The settings ZIP covers the common case; overlays are for the specific behavior a ZIP missed. Copying more than needed reintroduces stale references. |
| Whether an HTTP Client `.env.json` file is safe or must come via the encrypted DMG | Any variable that resolves to a token or password crosses the "must be encrypted" line. When unsure, treat it as encrypted. |
| Whether to accept a slight IntelliJ version delta versus reinstalling to match pre-image | Company-managed installs may not offer the exact prior version. Chasing an exact match is rarely worth the effort. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Four IntelliJ restore failures are common enough, or long enough to fix, that they would break the flow of the step that surfaces them. Each step links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### IntelliJ imported the settings ZIP but nothing changed

The `IntelliJIdea20YY.N/` directory under `~/Library/Application Support/JetBrains/` did not exist when Import Settings ran — IntelliJ silently ignored the write. Launch IntelliJ once, dismiss any onboarding, and quit; confirm the directory now exists; then reimport the ZIP from `app-settings-backup/intellij/manual-settings-export/`.

[[#Step 5 — Restore Scratches Consoles and IDE State|⮕ Continue to Step 5 — Restore Scratches Consoles and IDE State]]

### IntelliJ cannot find a JDK

First confirm the JDKs available to macOS:

```bash
/usr/libexec/java_home -V
java -version
```

Then set the JDK inside IntelliJ:

```text
Project Structure → SDKs
Settings → Build Tools → Gradle → Gradle JVM
```

For Gradle projects, both `Project SDK` and `Gradle JVM` must be set to the intended installed JDK. If the expected JDK is not listed, add it from `Project Structure → SDKs` using the path shown by `/usr/libexec/java_home -V`.

If internal Gradle or Maven downloads still fail after the JDK is set correctly, also confirm the Java trust override (`jssecacerts`) was restored in Phase 10B:

```bash
/usr/libexec/java_home -v 21
ls -la "$JAVA_HOME/lib/security/jssecacerts"
```

[[#Step 10 — Close the Plan-Note Sign-Off|⮕ Continue to Step 10 — Close the Plan-Note Sign-Off]]

### HTTP Client requests resolve null for a variable

The environment file was imported without its secret values, or was imported into the wrong project's `.idea/` folder. Verify:

```bash
find /path/to/project/.idea/httpRequests -maxdepth 2 -type f
find /path/to/project/.idea -maxdepth 2 -name '*.env.json'
```

If nothing is there, or the file is present but empty, mount the encrypted secret store again, copy the correct `*.env.json` into the correct project, and eject the DMG.

[[#Step 9 — Validate Project SDKs Gradle and Tests|⮕ Continue to Step 9 — Validate Project SDKs Gradle and Tests]]

### git status shows an env.json staged after restore

The file landed inside the working tree of a repo whose `.gitignore` does not cover it. Stop before committing — remove the file, add the appropriate ignore rule, and copy the env file into a location that is ignored (per the project's convention). Never resolve this by adding the env file to `git` "for now".

[[#Step 9 — Validate Project SDKs Gradle and Tests|⮕ Continue to Step 9 — Validate Project SDKs Gradle and Tests]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### How the plan-note relates to the Phase 14 sign-off

The plan-note surveys the sources; the sign-off (`reimaged-system/sign-offs/restore-intellij-YYYYMMDD-HHMMSS.md`) is the operator-facing checklist and the input to Phase 14 `reimaged-system-checks.md`. The two are separate files because they have opposite lifetimes: the plan-note is regenerated on every run, while an answered row is the one thing here that cannot be recomputed. Phase 14 reads the newest sign-off for this runbook and reports any row still on `TODO`, plus any row whose `Answered against` names a run older than the newest. That is why leaving a note next to a `TODO` row (e.g. `plugin deferred`) matters — the validator has no other way to distinguish "forgotten" from "intentionally deferred."

### Why the manual settings ZIP is preferred over `options/` overlays

IntelliJ's `options/` directory is per-version and evolves between releases. A ZIP produced by `File → Manage IDE Settings → Export Settings` is a curated set of import-safe files that IntelliJ knows how to migrate across minor version bumps; a wholesale overlay of `options/` files from a different installation frequently brings forward references to plugins, keymaps, or preferences that no longer exist in the newly-installed version, which manifests as spurious "Cannot load setting" popups. Prefer the ZIP; use targeted `options/` copies only when a specific behavior did not survive the import.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link,
  except Troubleshooting, whose back-link sits under its intro and whose routed
  symptom subsections stay out of the Table of Contents;
- the Step 1–10 anchors other runbooks and the plan-note point at are preserved.
-->
