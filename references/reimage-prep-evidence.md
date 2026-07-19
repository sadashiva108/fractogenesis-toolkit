[[reimaging-guide#Phase 3 — Pre-Image Captures|← Back to Mac Reimaging Guide]]

# Reimage Preparation Captures and Checklists Evidence

This is the single comprehensive **pre-image** evidence reference for the Mac reimage workflow.

Use it to understand both:

- what Phase 3 and Phase 4 commands generate under `$REIMAGE_ARTIFACT_ROOT`
- which manual sign-off rows, fallback notes, and templates still matter after the generated evidence exists

The phase order lives in [[reimaging-guide|reimaging-guide.md]]. The detailed command behavior lives in the phase runbooks and `scripts/`.

---

## Table of Contents

- [[#When This File Is Necessary|When This File Is Necessary]]
- [[#When This File Is Not Necessary|When This File Is Not Necessary]]
- [[#How the Pre-Image Captures Are Organized|How the Pre-Image Captures Are Organized]]
- [[#External Backup and Capture Root Layout|External Backup and Capture Root Layout]]
- [[#Phase 3A — Capture Workflow Snapshot|Phase 3A — Capture Workflow Snapshot]]
- [[#Phase 3B — Pre-Image System Inventory Capture|Phase 3B — Pre-Image System Inventory Capture]]
- [[#Phase 3C — Pre-Image Company-Managed Inventory Capture|Phase 3C — Pre-Image Company-Managed Inventory Capture]]
- [[#Phase 3D — Pre-Image Performance Audit Capture|Phase 3D — Pre-Image Performance Audit Capture]]
- [[#Phase 3E — Pre-Image Office Stability Capture|Phase 3E — Pre-Image Office Stability Capture]]
- [[#Phase 4 — Reimage Preparation Checks|Phase 4 — Reimage Preparation Checks]]
- [[#Templates|Templates]]

---

## When This File Is Necessary

Use this file when:

```text
a generated pre-image checklist leaves a manual row TODO
you need a human-only sign-off record before reimage
a script cannot run and you need a fallback note
you need a compact reference for what evidence each pre-image capture should produce
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## When This File Is Not Necessary

Do not manually duplicate generated pre-image evidence when the scripts already captured it successfully.

Examples:

```text
Do not manually retype system inventory if capture-system-inventory.sh generated a complete folder.
Do not manually recreate managed-app/profile evidence if capture-managed-inventory.sh generated the bundle.
Do not manually recreate performance summaries if capture-performance-audit.sh generated the scenario bundle.
Do not manually recreate Office watcher/baseline evidence if capture-office-stability-baseline.sh and office-stability-checklist.sh --phase pre-reimage generated the reports.
Do not manually recreate the Phase 4 checklist when reimage-checklist.sh already generated the final report.
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Pre-Image Captures Are Organized

| Phase | Capture | Primary destination | Purpose |
|---|---|---|---|
| Phase 3A | Workflow snapshot | `$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/pre-image-workflow-snapshot-*`, `$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/reimage-workflow-docs/` | Current reimage workflow docs and lightweight workflow snapshot context that should travel with the capture set. |
| Phase 3B | System inventory | `$REIMAGE_ARTIFACT_ROOT/system-inventory/pre-image-*` | Broad workstation rebuild context: hardware, macOS, apps, toolchains, shell, Git, network, cloud, and certificates. |
| Phase 3C | Company-managed inventory | `$REIMAGE_ARTIFACT_ROOT/managed-inventory/pre-image-*` | Managed apps, profiles, background services, system extensions, package receipts, and managed preferences. |
| Phase 3D | Performance audit | `$REIMAGE_ARTIFACT_ROOT/performance-audit/pre-image-*` | Scenario-based performance baselines and optional historical trend summaries/charts. |
| Phase 3E | Office stability | `$REIMAGE_ARTIFACT_ROOT/office-stability/` | Office-specific baseline bundles, watcher-derived evidence, incident captures, and Office checklist output. |
| Phase 4 | Reimage preparation checks | `$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/` | Final go / no-go validation, readable checklist output, and remaining manual sign-off rows before erase. |

These captures are **reference snapshots and read-only evidence**, not restore backups.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## External Backup and Capture Root Layout

```text
$REIMAGE_ARTIFACT_ROOT/
├── performance-audit/
│   ├── ...
│   ├── pre-image-performance-audit-<scenario>-YYYYMMDD-HHMMSS/
│   ├── post-image-performance-audit-<scenario>-YYYYMMDD-HHMMSS/
│   └── rollup-summary/
│       └── <phase>-YYYYMMDD-HHMMSS/
├── office-stability/
│   ├── README.md
│   ├── office-stability-summary-YYYYMMDD-HHMMSS.md
│   ├── pre-reimage-office-baseline-YYYYMMDD-HHMMSS.zip
│   ├── post-reimage-office-baseline-YYYYMMDD-HHMMSS.zip
│   ├── workload-snapshot-YYYYMMDD-HHMMSS.txt
│   ├── unified-log-office-YYYYMMDD-HHMMSS.txt
│   ├── install-log-office-YYYYMMDD-HHMMSS.txt
│   ├── latest-watcher-after-close-YYYYMMDD-HHMMSS.txt
│   ├── ms-office-stability-watch-evidence-YYYYMMDD-HHMMSS.zip
│   ├── pre-reimage-office-baseline-YYYYMMDD-HHMMSS/
│   ├── post-reimage-office-baseline-YYYYMMDD-HHMMSS/
│   └── checklists/
│       ├── pre-image-office-stability-checklist-YYYYMMDD-HHMMSS/
│       └── post-image-office-stability-checklist-YYYYMMDD-HHMMSS/
├── time-machine/
│   ├── completion-check-YYYYMMDD-HHMMSS.md
│   ├── final-time-machine-checklist-YYYYMMDD-HHMMSS.md
│   ├── compare-YYYYMMDD-HHMMSS.txt
│   ├── logs-YYYYMMDD-HHMMSS.txt
│   ├── verifychecksums-YYYYMMDD-HHMMSS.txt
│   ├── diskutil-verifyvolume-applebackups-YYYYMMDD-HHMMSS.txt
│   └── pre-image-time-machine-status-YYYYMMDD-HHMMSS/
│       ├── README.md
│       ├── time-machine-pre-run.md
│       ├── time-machine-status.md
│       └── raw/
├── reimage-prep-checks/
│   ├── reimage-checklist-YYYYMMDD-HHMMSS.md
│   └── latest-reimage-checklist.txt
├── workflow-snapshot/
│   ├── pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/
│   └── reimage-workflow-docs/
├── system-inventory/
│   ├── pre-image-YYYYMMDD-HHMMSS/
│   └── post-image-YYYYMMDD-HHMMSS/
└── managed-inventory/
    ├── pre-image-YYYYMMDD-HHMMSS/
    └── post-image-YYYYMMDD-HHMMSS/
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 3A — Capture Workflow Snapshot

Workflow: [[reimaging-guide#Phase 3A — Capture Workflow Snapshot|reimaging-guide.md — Phase 3A]].

Detailed capture runbook: [capture-workflow-snapshot.md](../capture-workflow-snapshot.md)

Script-generated evidence:

```bash
cd "$REIMAGE_ROOT"
chmod +x scripts/capture-workflow-snapshot.sh

./scripts/capture-workflow-snapshot.sh   --backup-root "$BACKUP_ROOT"   --open
```

Destinations:

```text
$BACKUP_ROOT/workflow-snapshot/pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/
$BACKUP_ROOT/workflow-snapshot/reimage-workflow-docs/
```

Typical contents:

| Category | Typical files or folders |
|---|---|
| Workflow snapshot bundle | `README.md`, `logs/`, and workflow-snapshot reference files |
| Workflow documentation copy | `reimage-workflow-docs/` |

Manual / fallback notes:

- This capture is normally script-complete; manual notes are rarely needed.
- If the runbooks changed after the main capture, rerun the doc-copy step from `capture-workflow-snapshot.md` so `reimage-workflow-docs/` matches the workflow you actually used.
- Use the timestamped `pre-image-workflow-snapshot-*` folder as the source of truth for the automated capture.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 3B — Pre-Image System Inventory Capture

Workflow: [[reimaging-guide#Phase 3B — Pre-Image System Inventory Capture|reimaging-guide.md — Phase 3B]].

Detailed capture runbook: [capture-system-inventory.md](../capture-system-inventory.md)

Script-generated evidence:

```bash
cd "$REIMAGE_ROOT"
set -a
source ./reimage.env
set +a
mkdir -p "$BACKUP_ROOT/system-inventory"
chmod +x scripts/capture-system-inventory.sh

./scripts/capture-system-inventory.sh   --output "$BACKUP_ROOT/system-inventory/pre-image-$(date +%Y%m%d-%H%M%S)"
```

Destination:

```text
$BACKUP_ROOT/system-inventory/pre-image-YYYYMMDD-HHMMSS/
```

Typical contents:

| Category | Typical files or folders |
|---|---|
| Inventory manifest | `MANIFEST.txt` |
| Bundle structure | `Brewfile`, `dotfiles/`, `01-hardware.txt` through `16-certs.txt` |
| Hardware and macOS | hardware, macOS, disk, and display reports |
| Installed software | application, Homebrew, and tool inventory reports |
| Shell and Git context | shell-state and global Git config notes |
| Developer tooling | Python, Java, Node, Docker, and related environment summaries |
| Machine context | network, cloud path, environment-variable, and certificate notes |

Use this as the broadest pre-image rebuild snapshot.

Manual / fallback notes:

- Manual rows are usually unnecessary unless the generated inventory is missing a needed context note.
- Add a short note only when a missing detail still matters, such as display arrangement/scaling context, a restore constraint for a licensed app, or a one-off environment quirk that would not be obvious from the generated bundle alone.
- Record any manual note beside the generated inventory bundle or in related setup notes under `$REIMAGE_ARTIFACT_ROOT`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 3C — Pre-Image Company-Managed Inventory Capture

Workflow: [[reimaging-guide#Phase 3C — Pre-Image Company-Managed Inventory Capture|reimaging-guide.md — Phase 3C]].

Detailed capture runbook: [capture-managed-inventory.md](../capture-managed-inventory.md)

Script-generated evidence:

```bash
cd "$REIMAGE_ROOT"
set -a
source ./reimage.env
set +a
mkdir -p "$BACKUP_ROOT/managed-inventory"
chmod +x scripts/capture-managed-inventory.sh

./scripts/capture-managed-inventory.sh
```

Destination:

```text
$BACKUP_ROOT/managed-inventory/pre-image-YYYYMMDD-HHMMSS/
```

Expected outputs:

```text
01-enrollment-status.txt
02-profiles-configuration.txt
03-installed-app-bundles.txt
04-installed-package-receipts.txt
05-background-managed-components.txt
06-managed-preference-payloads.txt
07-gaig-filter-pass.txt
MANIFEST.txt
```

Use this when you want a more precise record of MDM-delivered apps, profiles, background services, system extensions, package receipts, and managed preferences before erase.

Manual / fallback notes:

- There is no separate fallback checklist for this capture.
- Run the script or manual commands first, then review the bundle under `$REIMAGE_ARTIFACT_ROOT/managed-inventory/`.
- Add a short comparison note only if a managed-state difference still needs explanation after reviewing the captured bundle.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 3D — Pre-Image Performance Audit Capture

Workflow: [[reimaging-guide#Phase 3D — Pre-Image Performance Audit Capture|reimaging-guide.md — Phase 3D]].

Detailed capture runbook: [capture-performance-audit.md](../capture-performance-audit.md)

Script-generated evidence:

```bash
cd "$REIMAGE_ROOT"
source ./reimage.env
chmod +x scripts/capture-performance-audit.sh

export PERF_AUDIT_OUTPUT_ROOT="$BACKUP_ROOT/performance-audit"
mkdir -p "$PERF_AUDIT_OUTPUT_ROOT"

./scripts/capture-performance-audit.sh   --output "$PERF_AUDIT_OUTPUT_ROOT"   --phase pre-image   --scenario normal-workload   --sample-count 6   --sample-interval 30
```

Destination root:

```text
$BACKUP_ROOT/performance-audit/
```

Scenario bundles normally use names like:

```text
pre-image-performance-audit-clean-boot-YYYYMMDD-HHMMSS/
pre-image-performance-audit-normal-workload-YYYYMMDD-HHMMSS/
pre-image-performance-audit-active-dev-YYYYMMDD-HHMMSS/
```

Typical scenario-bundle contents:

```text
README.md
manifest.txt
manual-observations.md
workload-reproduction-config.md
docker/
intellij/
logs/
mac-memory-health-output/
memory/
processes/
raw/
responsiveness/
system/
```

Optional companion outputs:

| Output | Destination | Purpose |
|---|---|---|
| Historical trend summary | `performance-history/` inside a scenario bundle | Preserves multi-snapshot memory/process summaries when available. |
| Rollup summary package | `$REIMAGE_ARTIFACT_ROOT/performance-audit/rollup-summary/<phase>-*` | Quantitative summary package built from helper history, diagnostic CSVs, and selected text reports. |

Manual / fallback notes:

- `manual-observations.md` and `workload-reproduction-config.md` are generated automatically; review them instead of creating a separate manual checklist first.
- `manual-observations.md` is the place to record workload context the script cannot prove, especially how closely the capture matched normal work.
- For a `clean-boot` scenario, it is acceptable for Docker Desktop to be stopped. The performance script records that state in `docker/docker-daemon-state.txt` and skips daemon-dependent Docker commands when the daemon is unavailable. Record in `manual-observations.md` whether Docker was intentionally stopped, so the post-image clean-boot comparison uses the same assumption.
- If the external drive was unavailable, stage results locally under `$REIMAGE_WORKSPACE_ROOT/performance-audit/` and copy the completed folders into `$REIMAGE_ARTIFACT_ROOT/performance-audit/` before Phase 4 final validation.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 3E — Pre-Image Office Stability Capture

Workflow: [[reimaging-guide#Phase 3E — Pre-Image Office Stability Capture|reimaging-guide.md — Phase 3E]].

Detailed capture runbook: [capture-office-stability-audit.md](../capture-office-stability-audit.md)

Script-generated evidence:

```bash
cd "$REIMAGE_ROOT"
source ./reimage.env
chmod +x scripts/capture-office-stability-baseline.sh scripts/office-stability-checklist.sh

./scripts/capture-office-stability-baseline.sh   --phase pre-reimage   --backup-root "$BACKUP_ROOT"

./scripts/office-stability-checklist.sh   --phase pre-reimage   --backup-root "$BACKUP_ROOT"   --open
```

Destination root:

```text
$BACKUP_ROOT/office-stability/
```

Primary evidence types:

| Evidence type | Typical destination |
|---|---|
| Pre-image Office baseline bundle | `pre-reimage-office-baseline-YYYYMMDD-HHMMSS/` |
| Zipped copy of the same baseline | `pre-reimage-office-baseline-YYYYMMDD-HHMMSS.zip` |
| Office checklist report | `checklists/pre-image-office-stability-checklist-YYYYMMDD-HHMMSS/` |
| Incident workload snapshot | `workload-snapshot-YYYYMMDD-HHMMSS.txt` |
| Focused log extracts | `unified-log-office-*.txt`, `install-log-office-*.txt`, `latest-watcher-after-close-*.txt` |
| Consolidated watcher evidence ZIP | `ms-office-stability-watch-evidence-YYYYMMDD-HHMMSS.zip` |

Baseline bundle contents normally include:

```text
00-baseline-window.txt
01-crash-reports-newer-than-marker.txt
02-office-bundle-status.txt
03-outlook-onenote-process-transitions.txt
04-watcher-installer-office-signals.txt
05-install-log-office-events-tail.txt
06-autoupdate-office-events-tail.txt
07-unified-log-office-since-marker.txt
08-watcher-running-status.txt
office-stability-summary.md
```

Local live watcher files stay on the Mac under `$OFFICE_WATCH/`; the external backup root is for generated evidence bundles and extracted reports.

Manual / fallback notes:

- Manual rows are needed only for conclusions the scripts cannot prove, such as whether the evidence is ready for IT, whether Outlook/OneNote should be reopened, and the final Office stability conclusion.
- Prefer the generated `pre-image-office-stability-checklist.md` for actual sign-off; use the checklist template from the runbook only when a compact human summary is still useful.
- If Outlook or OneNote closes unexpectedly, capture the workload snapshot, save the latest watcher tail, and then rerun `capture-office-stability-baseline.sh` before reopening the apps.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 4 — Reimage Preparation Checks

Workflow: [[reimaging-guide#Phase 4 — Reimage Preparation Checks|reimaging-guide.md — Phase 4]].

Detailed capture runbook: [capture-validated-reimage-prep.md](../capture-validated-reimage-prep.md)

Script-generated evidence:

```bash
cd "$REIMAGE_ROOT"
set -a
source ./reimage.env
set +a
chmod +x scripts/reimage-checklist.sh

./scripts/reimage-checklist.sh   --phase pre   --backup-root "$BACKUP_ROOT"   --open
```

Generated output:

```text
$BACKUP_ROOT/reimage-prep-checks/reimage-checklist-YYYYMMDD-HHMMSS.md
$BACKUP_ROOT/reimage-prep-checks/latest-reimage-checklist.txt
```

Use the generated report as the actual Phase 4 evidence. This reference exists for the manual sign-off rows and fallback interpretation that remain after reviewing that report.

Common manual rows still requiring human confirmation:

| Manual item | Where to record |
|---|---|
| IT confirmed approved reimage method | generated Phase 4 report and/or `$REIMAGE_ARTIFACT_ROOT/reimage-confirmation/it-reimage-confirmation-YYYYMMDD.md` |
| Loose private-key / keystore / certificate candidates reviewed | generated Phase 4 report manual rows |
| `.p12` / `.pfx` export passwords saved only in approved password manager, if applicable | generated Phase 4 report manual rows |
| Time Machine backup completed and latest backup confirmed | generated Phase 4 report; `backup-time-machine.sh complete` output and `capture-time-machine.sh final --open` final checklist under `$REIMAGE_ARTIFACT_ROOT/time-machine/`; optional `capture-time-machine.sh verify-volume --open` focused APFS volume evidence |
| LastPass vault verified accessible | generated Phase 4 report manual rows |
| DMG password saved and DMG verified | generated Phase 4 report manual rows |
| VS Code Settings Sync state confirmed | generated Phase 4 report manual rows |
| OneDrive / iCloud / Obsidian sync confirmed | generated Phase 4 report manual rows |
| External drive ejected before reimage | generated Phase 4 report manual rows |

Automated rows worth noting -- these were previously manual but `reimage-checklist.sh` now checks them directly:

| Automated item | Evidence source |
|---|---|
| Keychain manual exports staged under `secrets-encrypted/certs/keychain-manual-exports/`, if needed | `reimage-checklist.sh --phase pre` -- "Keychain manual exports staged" |
| Chrome bookmarks exported or Chrome sync intentionally used | `reimage-checklist.sh --phase pre` -- "Chrome bookmarks exported" |
| Chrome password CSV staged under `secrets-encrypted/chrome/`, if exported | `reimage-checklist.sh --phase pre` -- "Chrome password CSV staged" |
| Extra certificate/Keychain review inventory generated | `reimage-checklist.sh --phase pre` -- "Extra certificate/Keychain review inventory" |
| OneDrive backup folder detected in CloudStorage, with upload marker (evidence only, not proof of sync) | `reimage-checklist.sh --phase pre` -- "OneDrive backup folder detected" |
| iCloud Drive available, if used | `reimage-checklist.sh --phase pre` -- "iCloud Drive available" |
| Untracked non-ignored files reviewed | `reimage-checklist.sh --phase pre` -- "Untracked non-ignored files reviewed" |
| No active scripts copied to the external backup drive | `reimage-checklist.sh --phase pre` -- "No active scripts copied to backup drive" |


Readable checklist map for the final manual review:

| Check type | Typical examples |
|---|---|
| Approval and go / no-go | IT confirmation, external drive spot-check, safe-to-proceed decision |
| Secrets and certificate handling | DMG verification, LastPass/password-manager confirmation, keychain/manual export review |
| Cloud/manual sync | OneDrive, iCloud, Obsidian/reference-vault, and other relied-on sync state |
| Backup completion | Time Machine completion, Git/local-file/app backup review, optional capture bundles present |
| Final cleanup | No active scripts copied to the external drive, final eject of backup media |

[[#Table of Contents|⬆ Back to Table of Contents]]

---


### Time Machine Evidence Commands

Time Machine is a Phase 2 backup, but its completion evidence is reviewed during Phase 4 final pre-image validation.

Use the current command model:

```bash
./scripts/capture-time-machine.sh pre-run --open
./scripts/backup-time-machine.sh start
./scripts/backup-time-machine.sh monitor --interval 300
./scripts/backup-time-machine.sh complete --open
./scripts/capture-time-machine.sh final --open
```

Optional evidence and integrity spot checks:

```bash
./scripts/capture-time-machine.sh verify-volume --open
./scripts/backup-time-machine.sh verify-latest --mount-if-needed --open
./scripts/backup-time-machine.sh compare --open
./scripts/backup-time-machine.sh logs --start "YYYY-MM-DD HH:MM:SS" --end "YYYY-MM-DD HH:MM:SS" --open
```

Notes:

- `capture-time-machine.sh pre-run --open` creates the pre-backup evidence bundle under `$REIMAGE_ARTIFACT_ROOT/time-machine/pre-image-time-machine-status-YYYYMMDD-HHMMSS/`.
- `time-machine-pre-run.md` intentionally keeps the older minimal layout: Destination, Latest Backup, Backup List, and Exclusions.
- The pre-run bundle does not include a manual sign-off template.
- `capture-time-machine.sh final --open` writes `$REIMAGE_ARTIFACT_ROOT/time-machine/final-time-machine-checklist-YYYYMMDD-HHMMSS.md`, auto-filling Time Machine checks that the script can prove.
- `capture-time-machine.sh verify-volume --open` creates a standalone focused APFS destination-volume verification file.
- `backup-time-machine.sh complete` records the latest backup timestamp and recommends a separate log command instead of embedding noisy logs.
- `backup-time-machine.sh compare --compare-path /Users/...` resolves APFS Time Machine `Data/Users/...` paths and treats explicit compare paths strictly.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Templates

### Template — Pre-Image Final Manual Sign-Off

```text
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
  [ ] No active scripts under $BACKUP_ROOT/scripts
  [ ] External drive ejected before reimage

Completed by: TODO
Date: YYYY-MM-DD
```

[[#Table of Contents|⬆ Back to Table of Contents]]
