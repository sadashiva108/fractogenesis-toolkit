[[reimaging-guide#Phase 6B — Reimage Preparation Checks|← Back to Mac Reimaging Guide]]

# Reimage Preparation Checks

**Last updated:** 2026-08-04

The Phase 6B go / no-go gate before you erase the Mac. `reimage-checklist.sh --phase pre` proves as many prep items as automation can — backup roots, Git audit, secrets DMG, captures, cloud-folder evidence — and writes a timestamped report. You then complete the handful of rows automation cannot prove: IT approval, Time Machine, DMG password storage, and whether OneDrive/iCloud uploads have actually settled. Proceed to Phase 7 only when the report has zero FAILs and every manual row is signed off.

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
    - [[#Step 1 — Prepare and Validate|Step 1 — Prepare and Validate]]
    - [[#Step 2 — Run the Validation|Step 2 — Run the Validation]]
    - [[#Step 3 — Resolve Findings and Sign Off Manual Rows|Step 3 — Resolve Findings and Sign Off Manual Rows]]
    - [[#Step 4 — Verify and Final Spot Checks|Step 4 — Verify and Final Spot Checks]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Go / No-Go Checklist Map|Go / No-Go Checklist Map]]
    - [[#Manual Sign-Off Notes|Manual Sign-Off Notes]]
    - [[#Manual Sync Confirmation Reference|Manual Sync Confirmation Reference]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Give yourself confidence, in one place, that the Mac's reimage preparation will reliably and safely restore the environment afterward. This is the pre-image gate: run the validator, read the report, close out the manual rows, and only then move to erase.

`reimage-checklist.sh --phase pre` is the authoritative validation path. It proves as many items as automation reasonably can and records each as PASS, WARN, FAIL, or SKIP. The rows that stay manual are the ones automation cannot prove by itself — a UI state, a human decision, or whether a cloud upload has actually finished.

This runbook owns:

```text
the Phase 6B pre-image go / no-go validation run and its generated report
the pre-image manual sign-off note and the manual sync-confirmation checks
the decision to proceed to Phase 7 (erase) or hold
```

It does not own:

```text
producing the artifacts it checks — each owning runbook creates them:
  Git audit and staged ignored files — backup-repos.md (Phase 2A)
  home and dotfiles copy, and the OneDrive sync procedure — backup-home.md (Phase 2B)
  app settings, VS Code, Chrome, Docker, Postman, Obsidian — backup-apps.md / backup-intellij.md (Phase 2C/2D)
  certificate and Keychain staging — stage-certs-keychain.md (Phase 3A)
  consolidated secrets DMG — create-secrets-dmg.md (Phase 3C)
  system, performance, and Office captures — the capture-*.md runbooks (Phase 4)
the post-image Phase 14 validation — the same script under --phase post, driven by reimaged-system-checks.md
```

This runbook is a validator: it reports on artifacts but never creates them. Rerun it as often as you like — each run writes a fresh timestamped report and refreshes `latest-reimage-checklist.txt`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Reimage prep is spread across many independent phases — Git, home files, apps, certs, the secrets DMG, and the captures — and no single phase can confirm the others are done. Phase 6B is the one place that inspects all of them at once and turns "I think everything is backed up" into an evidenced go / no-go decision.

The flow is script-first and one-directional. `reimage-checklist.sh --phase pre` walks every prep area, writes a PASS/WARN/FAIL/SKIP row per check into a Markdown report, and exits non-zero if any **FAIL** is present. You read that report, fix any FAIL by rerunning the phase that owns it, then hand-confirm the rows automation cannot reach. The preferred path is the single script run — reach for the individual sync commands in [[#Manual Sync Confirmation Reference|Manual Sync Confirmation Reference]] only for the cloud checks the script can evidence but not prove.

One boundary matters throughout: for cloud folders the script confirms a local folder and an upload marker exist — that is *evidence*, not *proof* that the cloud copy is current. Proof is a manual row.

The same script serves Phase 14 with `--phase post`; that run belongs to a different runbook. This runbook is `--phase pre` only.

### Terminology

| Term | Meaning |
|---|---|
| Go / no-go | The pre-image gate: proceed to erase only when there are zero FAILs and every manual row is signed off. |
| PASS / WARN / FAIL / SKIP | The per-check results. A FAIL blocks; a WARN is a review-before-proceeding; a SKIP is a check that did not apply. |
| Automated row | A check the script proves and fills in the report. |
| Manual row | A row the script leaves as `TODO` because it depends on a UI state, a human decision, or a settled cloud upload. |
| Evidence vs proof | A detected local folder and upload marker are evidence a backup was attempted; only a manual web/UI check proves the cloud copy is current. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/reimage-checklist.sh    # entrypoint — aggregate validator (--phase pre)
```

Generated report bundle:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/
├── reimage-checklist-YYYYMMDD-HHMMSS.md
├── latest-reimage-checklist.txt
└── manual/
    └── manual-app-export-and-sync-signoff-YYYYMMDD.md
```

Template for the fuller manual sign-off note:

```text
$FRACTOGENESIS_HOME/templates/app-backup-and-cloud-sync-signoff-template.md
```

The complete `$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

The `reimage.env` values this run depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the artifact root; the report is written under `reimage-prep-checks/` here. |
| `EXTERNAL_DATA_VOLUME` | The mounted external volume the artifact root must live under; the run fails fast if it is unset or not mounted. |
| `ONEDRIVE_ROOT` | Optional. Local CloudStorage OneDrive root; when set, the OneDrive folder/marker evidence check runs, otherwise it SKIPs. |
| `ONEDRIVE_DEST_SUBDIR` | Optional. OneDrive subfolder name to look under; defaults to the artifact root's basename. |
| `EXTERNAL_APPLE_BACKUPS_VOLUME` | Optional. Named in the eject-before-reimage sign-off row when a dedicated Time Machine volume is configured. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what this run is meant to gate. The concepts are in [[#How the Workflow Works|How the Workflow Works]]; this is just the checklist.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- `REIMAGE_ARTIFACT_ROOT` and `EXTERNAL_DATA_VOLUME` resolve and the external volume is mounted (`reimage.env` produced by `prepare-artifact-root.md`).
- The Phase 2 and Phase 4 backups and captures you intend to rely on have already run — this validator checks their output, it does not create it.

> [!bug] Troubleshooting
> If the run aborts with `EXTERNAL_DATA_VOLUME is not set` or `REIMAGE_ARTIFACT_ROOT is not set`, `reimage.env` was not produced or the drive is not mounted — rerun `prepare-artifact-root.md` and confirm the volume is attached before continuing.

### Confirm Your Intent

- That this is the **pre-image** gate (`--phase pre`), run once your backups and captures are complete — not the post-image Phase 14 run.
- Which cloud services are part of your restore plan. Only files you will actually restore from OneDrive or iCloud need their uploads to have settled; anything not relied on can be marked not applicable. The evidence table is in [[#Go / No-Go Checklist Map|Go / No-Go Checklist Map]].
- Whether `ONEDRIVE_ROOT` should be set for this run so the OneDrive evidence check runs instead of SKIPping.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order: validate the environment, run the checklist, resolve what it finds and sign off the manual rows, then confirm the report is clean before you erase. The script is one command; the surrounding steps are about acting on its output honestly.

### Step 1 — Prepare and Validate

Confirm the script parses and the environment resolves. `reimage-checklist.sh` self-locates and loads shared config through `.internal/load-reimage-config.sh`, so you do not source `reimage.env` by hand.

Syntax-check the entrypoint:

```bash
bash -n bin/reimage-checklist.sh
```

Confirm the options and that config loads without error:

```bash
./bin/reimage-checklist.sh --help
```

> [!note]
> This is an aggregate validator: it runs with `set -uo pipefail` and intentionally does **not** abort on the first failing check. Every area still produces a PASS/WARN/FAIL/SKIP row, so one missing artifact never hides the state of the others.

### Step 2 — Run the Validation

Run the pre-image checklist and open the results in Finder when it finishes:

```bash
./bin/reimage-checklist.sh --phase pre --open
```

To point at a different artifact root or volume for one invocation, add `--artifact-root PATH` or `--external-data-volume PATH`. To force the OneDrive evidence check against a specific root, add `--onedrive-root PATH`.

> [!warning] Pitfall
> `--workspace-root`, `--onedrive-root` git-status scanning, and `--internal-url` are post-image (`--phase post`) concerns. For the pre-image gate, the flags above are all you need — don't copy the Phase 14 invocation.

The run writes the report and refreshes the latest-pointer (names defined in [[#Artifact and Script Locations|Artifact and Script Locations]]):

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/reimage-checklist-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/latest-reimage-checklist.txt
```

It exits `0` with no FAILs, `1` when one or more FAIL rows were recorded, and `2` on bad arguments or unloadable config.

### Step 3 — Resolve Findings and Sign Off Manual Rows

Open the report and work it top to bottom. Every **FAIL** is a hard block: fix it by rerunning the phase that owns the artifact (see the ownership map in [[#Purpose|Purpose]]), then rerun this checklist. Review each **WARN** and either resolve it or record why it is acceptable.

Then complete the rows the script leaves as `TODO` — these are the manual verifications this runbook is responsible for, and they roll up to the go / no-go decision:

- IT has confirmed the approved reimage method in writing.
- Time Machine backup completed and `tmutil latestbackup` confirms it.
- The secrets DMG password is saved in the approved password manager, and the DMG mounts and verifies.
- OneDrive and (if relied on) iCloud uploads have actually settled — see [[#Manual Sync Confirmation Reference|Manual Sync Confirmation Reference]].
- VS Code Settings Sync state is recorded, or the local `app-settings-backup/vscode/` capture is chosen as the restore source.
- The Obsidian vault is synced or manually copied, and loose private-key / keystore / certificate candidates have been reviewed.
- The external drive will be ejected before the erase begins.

Capture these in the sign-off note so the decision is written down, not just remembered — the note template and the copy-from-template command are in [[#Manual Sign-Off Notes|Manual Sign-Off Notes]].

> [!note]
> Obsidian restore-*source* decisions themselves belong to [[backup-apps|Backup Apps]]; here you only confirm the vault is synced or copied.

### Step 4 — Verify and Final Spot Checks

Confirm the latest report is clean before you treat the gate as passed:

```bash
tail -n 20 "$(cat "$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/latest-reimage-checklist.txt")"
```

The summary block must show `FAIL : 0`. Spot-check that the artifact root holds the major areas and the secrets staging looks right:

```bash
du -sh "$REIMAGE_ARTIFACT_ROOT"/* 2>/dev/null | sort -k2
```

```bash
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted" -maxdepth 2 -print 2>/dev/null | sed "s|$REIMAGE_ARTIFACT_ROOT/||" | sort | head -40
```

> [!warning] Pitfall
> A clean report is necessary, not sufficient. The manual rows in Step 3 are part of the gate — do not proceed to Phase 7 on a zero-FAIL report while any `TODO` row is still open.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script reports uniformly; these judgment calls stay with you because there is no single right answer.

| Decision | Why it stays with you |
|---|---|
| Is OneDrive / iCloud part of the restore plan for a given file? | Only you know which files you will actually restore from the cloud; a service you do not rely on can be marked not applicable rather than chased to a settled state. |
| Is VS Code Settings Sync or the local capture the restore source? | Both can rebuild the editor; which one you trust as authoritative determines whether the Sync state or `app-settings-backup/vscode/` is the thing that must be in good shape. |
| Is a loose private-key / keystore / certificate candidate really a secret to include? | Automation flags candidates but cannot decide intent — you decide whether each belongs in the secrets DMG or is safe to leave. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### A FAIL row is for an area you intentionally skipped

The validator does not know your restore plan. If a FAIL is for a subsystem you deliberately are not backing up (for example a toolchain you do not use), that is a decision to record in the sign-off note, not a reason to edit the script — but confirm it is genuinely intentional before overriding a FAIL, since FAIL is reserved for missing artifacts the workflow expects.

### An "accidental OneDrive folder" appeared under `$FRACTOGENESIS_HOME`

If an older run wrote to a relative path under the repo root instead of the real OneDrive CloudStorage folder, see the "Confirm OneDrive Sync" section of [[backup-home|Backup Home]] for the fix; it owns the OneDrive target resolution and cleanup.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Go / No-Go Checklist Map

A readable map of the rows the report contains. The generated report is the actual evidence; use this to see at a glance which rows the script proves and which stay manual. Do not proceed until every critical item is complete.

| Check | Automated | Status |
|---|---|---|
| IT confirmed approved reimage method | Manual | `TODO` |
| External data volume mounted and artifact root exists under it | ✅ Script | — |
| Git audit report reviewed | ✅ Script | — |
| Local-only commits pushed or backed up | ✅ Script | — |
| Stashes converted to branches or intentionally ignored | ✅ Script | — |
| Untracked non-ignored files reviewed | ✅ Script | — |
| Selected ignored files staged | ✅ Script | — |
| Secrets encrypted or stored safely | ✅ Script | — |
| IntelliJ backup completed and settings ZIP exported | ✅ Script | — |
| Consolidated secrets DMG created and manifest present | ✅ Script | — |
| Extra certificate/Keychain review inventory generated | ✅ Script | — |
| Keychain manual exports staged under `secrets-encrypted/certs/keychain-manual-exports/`, if needed | ✅ Script | — |
| Loose private-key/keystore/certificate candidates reviewed | Manual | `TODO` |
| `.p12` / `.pfx` export passwords saved only in approved password manager, if applicable | Manual | `TODO` |
| System inventory captured | ✅ Script | — |
| Performance baseline captured | ✅ Script | — |
| Office stability evidence and checklist present, if applicable | ✅ Script | — |
| Confirmed no active scripts were copied to the external drive | ✅ Script | — |
| Postman exports saved, if applicable | ✅ Script / Manual review | — |
| Chrome bookmarks exported or Chrome sync intentionally used | ✅ Script | — |
| Chrome password CSV staged under `secrets-encrypted/chrome/`, if exported | ✅ Script | — |
| App settings manifest generated | ✅ Script | — |
| VS Code settings/extensions captured | ✅ Script | — |
| Home files and dotfiles captured | ✅ Script | — |
| Time Machine status bundle generated | ✅ Script | — |
| Time Machine backup completed and `tmutil latestbackup` confirmed | Manual | `TODO` |
| External backup root opened and spot-checked | ✅ Script | — |
| Secrets DMG password saved to approved password manager immediately after creation | Manual | `TODO` |
| DMG verified — opens in Finder, expected `gnupg/`, `ssh/`, `certs/` contents present | Manual | `TODO` |
| User/client public certificate PEM verified with balanced BEGIN/END blocks, if exported | Manual | `TODO` |
| VS Code Settings Sync state confirmed | Manual | `TODO` |
| OneDrive backup folder detected with an upload marker (evidence only, not proof of sync) | ✅ Script | — |
| OneDrive — no pending uploads (menu bar + web spot-check) | Manual | `TODO` |
| iCloud Drive available, if used | ✅ Script / SKIP | — |
| iCloud Drive — no pending uploads for relied-on files, if used | Manual | `TODO` |
| Obsidian vault synced or manually copied | Manual | `TODO` |
| App backup and cloud sync manual sign-off note completed | Manual | `TODO` |
| External drive ejected before reimage starts | Manual | `TODO` |

### Manual Sign-Off Notes

Save a working note before you start checking items off, so the decision is captured even if you step away.

Create the concise pre-image sign-off note:

```bash
mkdir -p "$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual"
FINAL_SIGNOFF_NOTE="$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/pre-image-final-manual-signoff-$(date +%Y%m%d).md"

if [[ ! -e "$FINAL_SIGNOFF_NOTE" ]]; then
cat > "$FINAL_SIGNOFF_NOTE" <<'EOF'
Pre-Image Final Manual Sign-Off — YYYY-MM-DD

IT approval:
  [ ] Approved method confirmed
  Method:
  Notes:

Time Machine:
  [ ] Backup completed
  Latest backup path:

Secrets:
  [ ] DMG password saved in approved password manager
  [ ] DMG mounted and verified
  Notes:

Cloud/manual sync:
  [ ] OneDrive sync complete
  [ ] Obsidian/reference-vault sync or backup complete
  Notes:

External backup root:
  [ ] Spot-checked
  [ ] No active scripts under the artifact root
  [ ] External drive ejected before reimage

Completed by: TODO
Date: YYYY-MM-DD
EOF
fi

open "$FINAL_SIGNOFF_NOTE"
```

For the fuller app-backup and cloud-sync note (Chrome, Postman, Keychain, VS Code Settings Sync, OneDrive/iCloud), copy the committed template into the manual folder:

```bash
SYNC_NOTE="$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/manual-app-export-and-sync-signoff-$(date +%Y%m%d).md"
mkdir -p "$(dirname "$SYNC_NOTE")"

cp "$FRACTOGENESIS_HOME/templates/app-backup-and-cloud-sync-signoff-template.md" "$SYNC_NOTE"

open "$SYNC_NOTE"
```

### Manual Sync Confirmation Reference

The manual checks behind the cloud rows. The script can evidence a local folder and a marker; these are how you prove the cloud copy is current.

**Capture local cloud folder paths as reference.** Record the CloudStorage roots and the expected OneDrive folder name so the sign-off note has concrete paths to review:

```bash
CLOUD_ROOT="$HOME/Library/CloudStorage"
printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
printf 'Expected OneDrive folder basename=%s\n' "$(basename "$REIMAGE_ARTIFACT_ROOT")"
find "$CLOUD_ROOT" -maxdepth 1 -type d -print 2>/dev/null | sort || true
```

**Confirm VS Code Settings Sync state.** The local capture collects `settings.json`, `keybindings.json`, snippets, and the extension list; it does not prove Settings Sync is enabled and settled. In VS Code, open the Accounts/Manage gear → Settings Sync, and the Command Palette → *Settings Sync: Show Synced Data*. Record the signed-in account, on/off, whether synced data is visible, and whether Settings Sync or the local `app-settings-backup/vscode/` capture is the restore source.

**Confirm OneDrive sync.** The detailed procedure — identifying the expected target, dropping a current-run marker, and the web spot-check — lives in the "Confirm OneDrive Sync" section of [[backup-home|Backup Home]]. Run it, then record here:

```text
[ ] OneDrive menu bar shows fully synced, no pending uploads or errors
[ ] expected backup folder and current-run marker file are both visible in OneDrive web
```

**Confirm iCloud Drive sync.** Only for files where iCloud is part of the restore plan. In System Settings → Apple Account → iCloud → iCloud Drive and Finder → iCloud Drive, confirm it is enabled, no pending-upload or waiting/error icons remain, and the file is visible from another Apple device or icloud.com if that is your restore proof:

```bash
ICLOUD_DRIVE="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
test -d "$ICLOUD_DRIVE" && open "$ICLOUD_DRIVE"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link.
-->
