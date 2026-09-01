[[reimaging-guide#Phase 12 — Restore Apps|← Back to Mac Reimaging Guide]]

# Restore Apps

**Last updated:** 2026-09-01

Restore the day-to-day application layer on the reimaged Mac after the managed baseline, runtime, access, Git, and repository foundations are in place. This is the umbrella runbook for Phase 12: it walks the operator through the ordered install-and-restore sequence for Office, OneDrive, Chrome, Obsidian, Postman, VS Code, Raycast, Terminal, and the remaining daily tools, and hands off to dedicated runbooks for IntelliJ, Docker, and the late local-file restore. `bin/restore-apps.sh` writes a per-run plan-note that surveys the available pre-image backup sources and provides the sign-off checklist the operator ticks through by hand.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 0 — Record Prerequisites and the Before-State|Step 0 — Record Prerequisites and the Before-State]]
    - [[#Step 1 — Generate the Restore-Apps Plan-Note|Step 1 — Generate the Restore-Apps Plan-Note]]
    - [[#Step 2 — Microsoft Office and Teams|Step 2 — Microsoft Office and Teams]]
    - [[#Step 3 — Chrome and Browser Setup|Step 3 — Chrome and Browser Setup]]
    - [[#Step 4 — Obsidian and Reference Vault|Step 4 — Obsidian and Reference Vault]]
    - [[#Step 5 — Postman Collections and Environments|Step 5 — Postman Collections and Environments]]
    - [[#Step 6 — VS Code|Step 6 — VS Code]]
    - [[#Step 7 — Raycast and Quicklinks|Step 7 — Raycast and Quicklinks]]
    - [[#Step 8 — IntelliJ IDEA Handoff|Step 8 — IntelliJ IDEA Handoff]]
    - [[#Step 9 — Docker Desktop Handoff|Step 9 — Docker Desktop Handoff]]
    - [[#Step 10 — Additional Daily Apps|Step 10 — Additional Daily Apps]]
    - [[#Step 11 — Terminal Profile|Step 11 — Terminal Profile]]
    - [[#Step 12 — Oracle SQL Developer|Step 12 — Oracle SQL Developer]]
    - [[#Step 13 — Office Stability Follow-Up|Step 13 — Office Stability Follow-Up]]
    - [[#Step 14 — Close the Plan-Note Sign-Off|Step 14 — Close the Plan-Note Sign-Off]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#How the plan-note relates to the Phase 14 sign-off|How the plan-note relates to the Phase 14 sign-off]]
    - [[#Why VS Code Can Be Missing from the Backup|Why VS Code Can Be Missing from the Backup]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

`restore-apps` (Phase 12) brings the day-to-day applications back online in a deliberate order so the reimaged Mac is usable for normal work without dragging forward stale state, broken authentication material, or unreviewed secrets. Each app either syncs from an approved cloud account (Chrome, OneDrive, Obsidian remote-vault sync), imports a small reviewed export (Postman collections, VS Code settings, Raycast Quicklinks), or hands off to a dedicated companion runbook (IntelliJ, Docker). The Phase 12 goal is that Office, Teams, OneDrive, Chrome, Obsidian, Postman, VS Code, Raycast, IntelliJ, Docker, and the priority daily tools all pass their sign-off checklist before Phase 13 post-image evidence captures start.

**What it sets up**

- **The Phase 12 plan-note** — a timestamped restore-plan under `reimaged-system/restore-notes/` that surveys which pre-image backup and secret-bearing sources are present and names the sibling runbooks that own IntelliJ and Docker. It is regenerable.
- **The Phase 12 sign-off** — `reimaged-system/sign-offs/restore-apps-YYYYMMDD-HHMMSS.md`, holding the rows you answer. A rerun carries your answers forward and stamps each with the run it was answered against.
- **The ordered app-restore sequence** — Office, Teams, and OneDrive install and sign-in ordering; Chrome default browser and per-profile restore; Obsidian and the reference vault; Postman import ordering; VS Code settings and extensions; Raycast Quicklinks; Terminal.app profile; Oracle SQL Developer; and the remaining daily apps installed intentionally rather than by bulk copy.
- **The closed sign-off** — every checklist row flipped to `Done` or annotated with why it is still open, with the post-image Office stability follow-up rolled into it.

**What the rest of the workflow relies on it for**

- Phase 13 post-image captures run against a Mac whose daily apps are back in service, so the evidence reflects a working system rather than a half-restored one.
- Phase 14 `reimaged-system-checks` reads the newest `restore-apps-plan-*.md` and flags any row still on `TODO`.
- Phase 15 picks up the local-file restore this phase deliberately defers.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| the Phase 12 restore-plan note that surveys backup sources and drives sign-off | IntelliJ IDEA settings, scratches, project metadata, and HTTP Client secrets — `restore-intellij` (Phase 12) |
| Microsoft Office, Teams, and OneDrive install and sign-in ordering | Docker Desktop settings, daemon state, and local container rebuild — `restore-docker` (Phase 12) |
| Chrome default browser, per-profile sync, extensions, and bookmark restore | repository re-clone and staged ignored files — `restore-repos` (Phase 11B) |
| Obsidian install and reference-vault open | Git identity and SSH routing — `restore-git` (Phase 11A) |
| Postman collection and environment import ordering | SSH keys, certificates, Java trust, shell/CLI config, and license material — `restore-access` (Phase 10B) |
| VS Code install, settings diff, and extension restore | runtime toolchain install (Xcode CLT, Homebrew, JDK, Node, platform CLIs) — `restore-runtime` (Phase 10A) |
| Raycast install and Quicklink recreation | late selective local-file restore — `restore-home` (Phase 15) |
| Terminal.app profile restore from the Phase 2D export | the Office stability baseline capture itself and its evidence bundles — `capture-office-stability` (Phase 4D / 13E) |
| Oracle SQL Developer install and connection restore decisions | |
| remaining daily apps that install intentionally rather than by bulk copy | |
| triggering the post-image Office stability follow-up and rolling its result into the sign-off | |

This runbook can be rerun. Regenerating the plan-note produces a fresh timestamped file under `reimaged-system/restore-notes/` and a new sign-off carrying your existing answers forward, so a rerun costs you nothing already recorded; prior plan-notes are preserved so you can compare a partial re-run against the last full pass.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Phase 12 is intentionally not a single "restore-everything" script — Mac application state is a mix of cloud-synced accounts, per-app import UIs, and secret-bearing material that must not be bulk-copied. `bin/restore-apps.sh` writes a plan-note that catalogs which pre-image backups are present, names the sibling runbooks that own IntelliJ and Docker, and provides the sign-off checklist; the operator then follows the ordered steps below by hand, ticking rows in the plan-note as each app comes up.

The order matters: Office and Teams install from the managed channel first because the same channel drives updates, licenses, and stability posture for the whole session. Chrome comes next because most subsequent app installs pass through a browser (downloads, OAuth logins, Obsidian remote-vault URLs). Obsidian is early so the vault (this runbook included) is available while the rest of the phase runs. Postman, VS Code, and Raycast are ordered from lightest-touch to highest-touch on local state. IntelliJ and Docker sit late in the phase because each has its own multi-step runbook and does not benefit from being sandwiched between short tasks. Terminal, Oracle SQL Developer, and the Office stability follow-up are trailing tasks that are easy to forget once the "main" apps look ready.

Secrets never enter this runbook directly. Any app that needs an environment token, a license key, or a keyring password reaches into `secrets-encrypted/` via the mounted DMG (Phase 10B territory); this runbook only points at the source path and expects the operator to unlock and import selectively.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later steps refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/restore-apps.sh                # entrypoint
```

Related scripts, alphabetical:

```text
$FRACTOGENESIS_HOME/bin/capture-office-stability.sh    # entrypoint — owned by capture-office-stability.md; invoked in Step 13
$FRACTOGENESIS_HOME/bin/office-stability-checklist.sh  # entrypoint — owned by capture-office-stability.md; invoked in Step 13
$FRACTOGENESIS_HOME/bin/restore-docker.sh              # entrypoint — owned by restore-docker.md; invoked in Step 9
$FRACTOGENESIS_HOME/bin/restore-intellij.sh            # entrypoint — owned by restore-intellij.md; invoked in Step 8
```

Artifact locations:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/                                # Phase 2D outputs (per-app backups)
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/                                  # Phase 3A/3C outputs (mount before use)
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-apps-plan-*.md
$REIMAGE_ARTIFACT_ROOT/reimaged-system/sign-offs/restore-apps-*.md
$REIMAGE_ARTIFACT_ROOT/office-stability/post-reimage-*/                    # produced in Step 13
```

Directories this runbook's steps read and write, alphabetized at every level. Omitted siblings are shown as `...`:

```text
$REIMAGE_ARTIFACT_ROOT/
├── app-settings-backup/
│   ├── ...
│   ├── chrome/
│   ├── docker/
│   ├── intellij/
│   ├── obsidian/
│   ├── postman/
│   ├── raycast/
│   ├── terminal/
│   ├── vscode/
│   └── ...
├── ...
├── office-stability/
│   └── post-reimage-office-baseline-YYYYMMDD-HHMMSS/
├── ...
├── reimaged-system/
│   ├── restore-notes/
│   │   └── restore-apps-plan-YYYYMMDD-HHMMSS.md
│   └── sign-offs/
│       └── restore-apps-YYYYMMDD-HHMMSS.md
├── ...
├── secrets-encrypted/
│   ├── ...
│   ├── docker/
│   ├── intellij/
│   ├── licenses/
│   ├── postman/
│   └── ...
└── ...
```

The complete `app-settings-backup/` layout and the full artifact-root map are defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Mounted external artifact volume that holds every pre-image backup and every post-image record. Required for `bin/restore-apps.sh`; `--artifact-root PATH` overrides it for one invocation. |
| `FRACTOGENESIS_HOME` | Local checkout of the toolkit repository holding the scripts and this runbook. Set by your shell startup / `.envrc`, not stored in `reimage.env`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phases 8, 9, 10A, 10B, 11A, and 11B are complete. In particular, `~/.gitconfig`, `~/.ssh/config`, the encrypted secrets DMG contents (SSH keys, certificates, Java trust), and the repository checkouts must already be restored — several Phase 12 steps rely on GitHub sign-ins, Postman vault decryption, or IntelliJ project paths that only work once those layers are in place.
- The external artifact volume is mounted and `$REIMAGE_ARTIFACT_ROOT` resolves; the pre-image `app-settings-backup/` subtree is reachable.
- The encrypted secrets DMG is mounted (or ready to mount) for the Postman, IntelliJ, Docker, and licenses steps. Mount only when the corresponding step asks for it, and eject when done.

> [!bug] Troubleshooting
> If `$REIMAGE_ARTIFACT_ROOT` is unset or unreachable, the plan-note reports every source as missing — see [[#The plan-note reports MISSING for every source|The plan-note reports MISSING for every source]].

### Confirm Your Intent

- Are you running the full Phase 12 sweep, or resuming mid-phase after a partial pass? A resumed run should still regenerate the plan-note so `PRESENT`/`MISSING` reflect current disk state, but the sign-off checklist you carry forward is the same one — copy the outstanding `TODO` rows into the new file so nothing is lost.
- Do you want the plan-note under the default `reimaged-system/restore-notes/`, or a scratch location (`--output-root ~/Desktop/…`)? The sign-off has its own `--signoff-root`, defaulting to `reimaged-system/sign-offs/`. Those defaults are what Phase 13 post-image captures and Phase 14 sign-off expect.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. Each numbered step corresponds to a row (or row group) in the sign-off checklist emitted by `bin/restore-apps.sh`.

### Step 0 — Record Prerequisites and the Before-State

Two recordings, both taken before any application is installed or configured.
They answer different questions and only one of them can be taken late.

**0a — may this phase start?** Writes a checklist under
`reimaged-system/boundaries/` and exits non-zero only on `FAIL`:

```bash
./bin/record-restore-prereqs.sh --runbook restore-apps --dry-run
./bin/record-restore-prereqs.sh --runbook restore-apps
```

Its rows are derived from *Prerequisites* above, so the two cannot drift. The one
worth reading twice is **Pre-image app settings reachable**. This phase is an
orchestrator: its steps hand off to `restore-intellij.md` and `restore-docker.md`,
whose scripts read `app-settings-backup/` and emit plan-notes. An unreachable
backup does not error — every source in every plan-note reports `MISSING`, which
reads exactly like an application that had nothing worth restoring.

**0b — what is on disk right now?** Writes a run under `reimaged-system/state/`
recording the live application config paths this phase will populate:

```bash
./bin/record-restore-state.sh --runbook restore-apps --point before --dry-run
./bin/record-restore-state.sh --runbook restore-apps --point before
```

Seven targets, the large ones walked at depth 1 rather than recursively: IntelliJ
keeps a subtree per version and `Code/User/` holds every extension's state, and
the question here is which of these existed before Phase 12 ran — not a hash of
everything inside them.

> [!warning] Pitfall
> **0b expires the first time you open an application, not the first time you
> restore one.** Step 8 says in as many words: *launch IntelliJ once so it creates
> its Application Support paths, then quit.* That launch is what ends the
> before-state — from then on, `~/Library/Application Support/JetBrains/` holds
> config this phase created rather than config it inherited, and the two are
> indistinguishable afterwards. Take 0b before Step 1.

> [!note]
> `before` is a first-wins point: the first capture recorded stays official, and
> a mistimed one cannot be replaced, only annotated with a pin explaining why it
> is wrong. The `--dry-run` line prints the target table and writes nothing —
> read it, confirm it describes a machine this phase has not touched, then record.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 1 — Generate the Restore-Apps Plan-Note

Emit the plan-note that surveys which pre-image backups are available and provides the sign-off checklist:

```bash
./bin/restore-apps.sh --open
```

The generated file lives under:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-apps-plan-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimaged-system/sign-offs/restore-apps-YYYYMMDD-HHMMSS.md
```

Skim the **Backup Sources** and **Secret-Bearing Sources** tables and note any `MISSING` rows before continuing. `MISSING` is not automatically a blocker (e.g. no Postman export means you'll rebuild environments manually), but each row should be an intentional decision, not a surprise.

> [!note]
> The script writes no plan-note when `--output-root` points at an unwritable directory. Fix the destination and rerun; nothing was created.

> [!bug] Troubleshooting
> If every row in both tables reads `MISSING`, see [[#The plan-note reports MISSING for every source|The plan-note reports MISSING for every source]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Microsoft Office and Teams

Let the approved company-managed channel install Office and Teams. Do not manually install a second copy from another channel unless IT explicitly asks. Sign in only after the install appears complete and Company Portal / Intune enrollment is stable.

Record the installed versions and install source:

```bash
for app in "Microsoft Outlook" "Microsoft OneNote" "Microsoft Word" "Microsoft Excel" "Microsoft PowerPoint" "Microsoft Teams"; do
  APP="/Applications/$app.app"
  echo "--- $app"
  if [[ -d "$APP" ]]; then
    /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Contents/Info.plist" 2>/dev/null || true
    /usr/bin/stat -f "modified=%Sm path=%N" -t "%Y-%m-%d %H:%M:%S" "$APP"
  else
    echo "MISSING"
  fi
done
```

Paste the versions into the plan-note's `Outlook / OneNote / Teams versions recorded` row.

> [!warning] Pitfall
> Opening Outlook or OneNote before Company Portal has settled is the most common source of the "Office quits at launch" symptom carried over from the pre-image system. Wait for the managed install indicators to settle first.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Chrome and Browser Setup

Set Chrome as the default browser, then restore **each profile separately** — Chrome state is per-profile, so recreate every profile the pre-image machine had and sign each into its own account. Use `app-settings-backup/chrome/profiles-inventory.md` (from the backup) as the map of profiles, accounts, and sync state.

For each profile in the inventory:

1. Create the profile: Chrome → profile avatar (top-right) → **Add**, name it to match the inventory, and sign into that profile's account (personal Google, work Google, or account-free per the inventory).
2. Let **Chrome sync** restore that profile's bookmarks, settings, extensions, and — where password sync was on — passwords. Sync is the supported path.
3. Where a profile had **password sync off**, passwords were not synced: restore them from your approved password manager, not from a raw copy.
4. Reinstall any work-approved extensions (e.g. JSON Formatter) the profile's sync did not carry.

Fallback only if a profile's bookmark sync didn't carry — switch into that profile first, then import its exported HTML:

```bash
open "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome"
```

Manual import path in Chrome (per profile): `Bookmark Manager → Organize → Import Bookmarks` → pick `bookmarks_<profile>_*.html`.

> [!warning] Pitfall
> Don't copy raw Chrome profile folders over the new ones — profile sync is the supported path and avoids dragging stale device metadata forward. And never cross accounts between profiles (work account only in the work profile, personal only in personal), or sessions blend.

> [!note]
> On a managed Mac, Chrome's "Managed by <company>" enrollment, enterprise policies, and force-installed extensions come back automatically via MDM after reimage — you don't restore those; they return with device management.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Obsidian and Reference Vault

Install Obsidian from the approved source. Open the restored (or freshly cloned in Phase 11B) reference vault:

```text
~/Development/documentation/reference-vault
```

Confirm the vault opens cleanly:

```text
Mac Reimaging Guide (reimaging-guide.md) opens
internal wiki-links resolve in Reading View
Cmd-click navigates in Live Preview / editing mode
external links open in Chrome
```

> [!bug] Troubleshooting
> If Obsidian complains about an unrecognized plugin, decline the install and check the pre-image `app-settings-backup/obsidian/` inventory before enabling anything.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Postman Collections and Environments

Install Postman Desktop. Import in this order:

```text
1. Collections   (Postman Desktop → Import → drag from app-settings-backup/postman/collections/)
2. Environments  (Postman Desktop → Import → drag from secrets-encrypted/postman/ after mounting the DMG)
```

Expected sources:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/               # non-secret collections and inventory
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/                 # environments that carry secrets
```

After import: select each environment, confirm every variable is present, confirm secret values were populated only from the encrypted vault, and run a harmless health-check request first before running anything that touches production.

> [!warning] Pitfall
> Environments imported without their secret values look fine in the UI (variables show as empty strings) but will silently 401/403 against real APIs. Diff `secrets-encrypted/postman/` against what's loaded before you assume the import "worked."

> [!bug] Troubleshooting
> If imported variables show as empty strings, see [[#Postman variables show as empty strings after import|Postman variables show as empty strings after import]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 6 — VS Code

Install VS Code from the approved source. The backup is the Phase 2D capture under `app-settings-backup/vscode/`, holding `extensions.txt` beside a `user/` tree of `settings.json`, `keybindings.json`, `snippets/`, and `profiles/`. Point a shell variable at it and confirm it is there:

```bash
VSCODE_BACKUP_DIR="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/vscode"

[[ -d "$VSCODE_BACKUP_DIR" ]] || {
  echo "ERROR: no VS Code backup directory found at $VSCODE_BACKUP_DIR" >&2
  exit 2
}

printf 'Using VS Code backup directory: %s\n' "$VSCODE_BACKUP_DIR"
```

> [!note]
> If this directory is absent, VS Code was skipped during Phase 2D — some operators skip it because Settings Sync already carries extensions and settings. Sign in to Settings Sync instead of hunting for another copy.

Restore extensions if the `code` CLI is on `PATH` and an extension list was captured:

```bash
if command -v code >/dev/null 2>&1 && [[ -f "$VSCODE_BACKUP_DIR/extensions.txt" ]]; then
  while IFS= read -r ext; do
    [[ -n "$ext" ]] && code --install-extension "$ext"
  done < "$VSCODE_BACKUP_DIR/extensions.txt"
fi
```

Diff before overwriting settings:

```bash
code "$VSCODE_BACKUP_DIR" "$HOME/Library/Application Support/Code/User"
```

Copy across only after review:

```text
settings.json
keybindings.json
snippets/          (only if captured)
```

Recommended file associations from prior workflow context:

```text
.json → VS Code
.xml  → VS Code
.log  → VS Code
.txt  → VS Code
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 7 — Raycast and Quicklinks

Install Raycast from the approved source and recreate the priority Quicklinks:

```text
reference-vault
Mac Reimaging Guide
Git cheatsheet
Falcon LogScale
Dynatrace
Elasticsearch
Enterprise Search
Data Gateway
UAA Manager
common internal portals
```

> [!warning] Pitfall
> Do not store bearer tokens, client secrets, passwords, private keys, or production credentials in Raycast Quicklinks or snippets. Raycast state is not covered by the encrypted secrets model.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 8 — IntelliJ IDEA Handoff

IntelliJ mixes IDE state, project metadata, and secret-bearing HTTP Client data, so it lives in its own runbook. Start the companion helper, then follow the dedicated guide:

```bash
./bin/restore-intellij.sh --open
```

Then follow: [[restore-intellij|restore-intellij.md]].

The high-level order there remains: install → launch once and quit → import settings ZIP → restore scratches/consoles and selected project metadata → restore secret-bearing HTTP Client environments only from encrypted storage.

When that runbook is complete, come back here and mark the `IntelliJ dedicated restore completed` row in the plan-note before moving on to Docker.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 9 — Docker Desktop Handoff

Docker mixes Desktop settings, local daemon state, and container/service rebuild. Start the companion helper, then follow the dedicated guide:

```bash
./bin/restore-docker.sh --open
```

Then follow: [[restore-docker|restore-docker.md]].

Typical sources the Docker runbook consumes:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker/config.json
```

When that runbook is complete, come back here and mark the `Docker dedicated restore completed` row in the plan-note.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 10 — Additional Daily Apps

Install the remaining apps intentionally rather than bulk-copying app state. Candidates from prior workflow context:

```text
LastPass
Draw.io
Notable
BBEdit
Oracle SQL Developer   (defer to Step 12)
Slack
TablePlus or another DB client
Figma
Zoom
other approved app-specific tools
```

For each one:

1. Confirm the approved install source.
2. Confirm whether cloud sign-in / sync is sufficient.
3. Restore only the settings or exports that still matter.
4. Record license or activation handling under `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/licenses/` when applicable.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 11 — Terminal Profile

If a custom Terminal.app profile was exported in Phase 2D, restore it now:

```bash
find "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/terminal" -maxdepth 1 -name '*.terminal' -print 2>/dev/null
open "$REIMAGE_ARTIFACT_ROOT/app-settings-backup/terminal/"*.terminal
```

Opening the `.terminal` file installs it as a profile in `Terminal → Settings → Profiles`. Set it as the default there if desired, then check `window-size-note.txt` in the same folder if you also want to reapply the default window size.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 12 — Oracle SQL Developer

Install Oracle SQL Developer only if it is still approved and needed:

```text
Install from the approved Oracle / company source.
Confirm required JDK compatibility against the JDK installed in Phase 10A.
Restore database connection definitions only from approved backup locations.
Do not restore connection passwords loose; use the approved secret store.
```

Record the decision (install vs. skip), install source, JDK version, and connection restore path in the plan-note's `Oracle SQL Developer decision recorded` row.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 13 — Office Stability Follow-Up

Because Outlook and OneNote had pre-image closure and update issues, validate Office stability after reimage. Open Outlook and OneNote only after:

```text
Company Portal / Intune enrollment is stable
Office install appears complete
Microsoft AutoUpdate is not actively replacing bundles (if visible)
OneDrive sign-in is stable
```

Capture the post-image Office stability baseline:

```bash
./bin/capture-office-stability.sh --phase post-reimage
./bin/office-stability-checklist.sh --phase post-reimage
```

Update [[capture-office-stability|capture-office-stability.md]] with the post-image result and mark the plan-note row.

> [!bug] Troubleshooting
> If Outlook or OneNote closes unexpectedly while you are validating, see [[#Office quits unexpectedly on first launch|Office quits unexpectedly on first launch]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 14 — Close the Plan-Note Sign-Off

Reopen the plan-note and flip every row that is now complete from `TODO` to `Done`. Leave any row still open with a short note explaining why (e.g. `deferred to Phase 15 restore-home`). Phase 14 (`reimaged-system-checks.md`) reads these plan-notes and will flag outstanding rows.

Confirm the summary matrix before leaving Phase 12:

| Area | Expected result |
|---|---|
| Office | Managed install completed and sign-in is usable. |
| OneDrive | Sync is healthy enough for normal work. |
| Chrome | Each profile is recreated, signed in, and synced; passwords restored for sync-off profiles; default browser set. |
| Obsidian | `reference-vault` opens cleanly. |
| Postman | Collections and environments imported with secrets populated. |
| VS Code | Settings and extensions restored as intended. |
| Raycast | Priority Quicklinks recreated. |
| IntelliJ | Dedicated restore runbook completed. |
| Docker | Dedicated restore runbook completed. |
| Terminal | Custom profile restored (if one was exported). |
| Office stability | Post-image baseline captured and compared. |

Continue to the Phase 13 capture runbooks (`capture-system-inventory.md`, `capture-managed-inventory.md`, `capture-performance-audit.md`, `capture-office-stability.md`), then to Phase 14 `reimaged-system-checks.md`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The plan-note reports which sources exist and the steps sequence the installs; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Which "additional daily apps" from Step 10 actually still belong on this machine | The pre-image inventory reflects what was installed, not what you still need. Every reinstall is an opportunity to prune stale tools. |
| Whether a Postman environment is safe to import from `app-settings-backup/postman/` or must come from `secrets-encrypted/postman/` | The classification depends on what the environment stores (a bearer token vs. a base URL); mis-classifying leaks secrets into unencrypted storage. |
| Whether Oracle SQL Developer is still approved and needed | Managed-app policy shifts. Prior installation is not evidence of current approval. |
| Whether the Terminal profile is worth restoring | Some operators prefer a clean default; the pre-image export exists only as an option, not a requirement. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Three failures here either span more than one step or have a fix long enough to break a step's flow. Each is reached from a callout in the step that surfaces it.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Office quits unexpectedly on first launch

Capture evidence before reopening the app: crash reports under `~/Library/Logs/DiagnosticReports/`, the current state of Microsoft AutoUpdate, and any Intune / installer processes still running. Compare Office bundle versions and modified timestamps against the pre-image evidence in `system-inventory/pre-image-*/`. Do not re-launch the app until the update or installer that overlapped the crash has finished.

[[#Step 13 — Office Stability Follow-Up|⮕ Continue to Step 13 — Office Stability Follow-Up]]

### Postman variables show as empty strings after import

The collection or environment was imported from `app-settings-backup/postman/` (the non-secret path) instead of `secrets-encrypted/postman/`. Delete the imported environment, mount the encrypted DMG, and re-import from the secrets path.

[[#Step 6 — VS Code|⮕ Continue to Step 6 — VS Code]]

### The plan-note reports MISSING for every source

`$REIMAGE_ARTIFACT_ROOT` is either unset or pointing at an unmounted volume path. Mount the artifact volume, re-source `reimage.env`, and rerun `./bin/restore-apps.sh`; or pass `--artifact-root PATH` explicitly to it and to any later helper that needs it.

[[#Step 2 — Microsoft Office and Teams|⮕ Continue to Step 2 — Microsoft Office and Teams]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### How the plan-note relates to the Phase 14 sign-off

The plan-note surveys the sources; the sign-off (`reimaged-system/sign-offs/restore-apps-YYYYMMDD-HHMMSS.md`) is the operator-facing checklist and the input to Phase 14 `reimaged-system-checks.md`. The two are separate files because they have opposite lifetimes: the plan-note is regenerated on every run, while an answered row is the one thing here that cannot be recomputed. Phase 14 reads the newest sign-off for this runbook and reports any row still on `TODO`, plus any row whose `Answered against` names a run older than the newest. That is why leaving a note next to a `TODO` row (e.g. `deferred to Phase 15`) matters — the validator has no other way to distinguish "forgotten" from "intentionally deferred."

### Why VS Code Can Be Missing from the Backup

Phase 2D `backup-apps.md` treats VS Code as an optional dedicated capture; some operators skip it because Settings Sync already covers extensions and settings. There is no second source to fall back to — the toolkit snapshot captures no VS Code state — so an absent `app-settings-backup/vscode/` means the restore path for this app is Settings Sync, not a file copy.

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
