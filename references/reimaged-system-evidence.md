[[reimaging-guide#Post-Image|← Back to Mac Reimaging Guide]]

# Reimaged System Captures and Checklists Evidence

This is the single comprehensive **post-image** evidence reference for the Mac reimage workflow.

Use it to understand both:

- what Phase 6, Phase 7, Phase 11, and Phase 12 commands generate under `$BACKUP_ROOT`
- which manual sign-off rows, fallback notes, and templates still matter after the generated evidence exists

This file complements [[reimaging-guide|reimaging-guide.md]] for phase order and [restore-file-reference.md](restore-file-reference.md) for restore-source mapping.

---

## Table of Contents

- [[#When This File Is Necessary|When This File Is Necessary]]
- [[#When This File Is Not Necessary|When This File Is Not Necessary]]
- [[#How the Post-Image Evidence Is Organized|How the Post-Image Evidence Is Organized]]
- [[#Reimaged-System Artifact Layout|Reimaged-System Artifact Layout]]
- [[#Phase 6 — Enroll and Stabilize|Phase 6 — Enroll and Stabilize]]
- [[#Phase 7 — Initial Captures and Sanity Checks|Phase 7 — Initial Captures and Sanity Checks]]
- [[#Phase 11A — Capture Workflow Snapshot|Phase 11A — Capture Workflow Snapshot]]
- [[#Phase 11B — Post-Image System Inventory Capture|Phase 11B — Post-Image System Inventory Capture]]
- [[#Phase 11C — Post-Image Company-Managed Inventory Capture|Phase 11C — Post-Image Company-Managed Inventory Capture]]
- [[#Phase 11D — Post-Image Performance Audit Capture|Phase 11D — Post-Image Performance Audit Capture]]
- [[#Phase 11E — Post-Image Office Stability Capture|Phase 11E — Post-Image Office Stability Capture]]
- [[#Phase 12 — Reimaged System Checks|Phase 12 — Reimaged System Checks]]
- [[#Templates|Templates]]

---

## When This File Is Necessary

Use this file when:

```text
a generated post-image checklist leaves a manual row TODO
you need a compact reference for what each post-image phase generated
a script could run but still needs human interpretation before final sign-off
a script could not run and you need a grounded fallback note
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## When This File Is Not Necessary

Do not manually duplicate generated post-image evidence when the scripts already captured it successfully.

Examples:

```text
Do not manually recreate enrollment command output if capture-enrollment.sh generated the bundle.
Do not manually rewrite the initial first-boot checklist if initial-reimaged-system-checklist.sh generated it twice around the restart.
Do not manually rebuild system/managed/performance/Office comparison bundles if the Phase 11 scripts generated them.
Do not manually duplicate the final validation report when reimage-checklist.sh --phase post already generated the final checklist.
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Post-Image Evidence Is Organized

| Phase | Capture | Primary destination | Purpose |
|---|---|---|---|
| Phase 6 | Enrollment and stabilization | `$BACKUP_ROOT/reimaged-system/enrollment/capture-enrollment-*` | Managed enrollment, profiles, security tools, macOS update state, and first stabilization review. |
| Phase 7 | Initial captures and sanity checks | `$BACKUP_ROOT/reimaged-system/initial-reimaged-system-*` | First post-image evidence bundle before deeper restore work, including restart and Time Machine planning notes. |
| Phase 11A | Workflow snapshot | `$BACKUP_ROOT/workflow-snapshot/pre-image-workflow-snapshot-*`, `$BACKUP_ROOT/workflow-snapshot/reimage-workflow-docs/` | Final workflow-doc snapshot showing the workflow state actually used after rebuild. |
| Phase 11B | System inventory | `$BACKUP_ROOT/system-inventory/post-image-*` | Broad rebuilt-system snapshot for comparison against Phase 3B. |
| Phase 11C | Company-managed inventory | `$BACKUP_ROOT/managed-inventory/post-image-*` | Managed apps, profiles, launch items, extensions, receipts, and managed preferences after enrollment. |
| Phase 11D | Performance audit | `$BACKUP_ROOT/performance-audit/post-image-*` | Scenario-based after-state performance bundles that match the pre-image scenarios. |
| Phase 11E | Office stability | `$BACKUP_ROOT/office-stability/post-reimage-*`, `checklists/post-image-office-stability-checklist-*` | Office stability baseline, watcher-derived evidence, and post-image comparison checklist output. |
| Phase 12 | Reimaged system checks | `$BACKUP_ROOT/reimaged-system/checklists/reimage-checklist-*.md` | Final validation report plus the remaining manual sign-off rows before the rebuilt Mac is considered trusted. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Reimaged-System Artifact Layout

```text
$BACKUP_ROOT/
├── reimaged-system/
│   ├── enrollment/
│   │   ├── capture-enrollment-YYYYMMDD-HHMMSS/
│   │   └── latest-enrollment-capture.txt
│   ├── initial-reimaged-system-YYYYMMDD-HHMMSS/
│   ├── latest-initial-reimaged-system-bundle.txt
│   ├── time-machine/
│   ├── restarts/
│   ├── restore-notes/
│   └── checklists/
│       ├── reimage-checklist-YYYYMMDD-HHMMSS.md
│       └── latest-reimage-checklist.txt
├── workflow-snapshot/
│   ├── pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/
│   └── reimage-workflow-docs/
├── system-inventory/
│   └── post-image-YYYYMMDD-HHMMSS/
├── managed-inventory/
│   └── post-image-YYYYMMDD-HHMMSS/
├── performance-audit/
│   ├── post-image-performance-audit-<scenario>-YYYYMMDD-HHMMSS/
│   └── rollup-summary/
│       └── <phase>-YYYYMMDD-HHMMSS/
└── office-stability/
    ├── office-stability-summary-YYYYMMDD-HHMMSS.md
    ├── post-reimage-office-baseline-YYYYMMDD-HHMMSS/
    ├── post-reimage-office-baseline-YYYYMMDD-HHMMSS.zip
    └── checklists/
        └── post-image-office-stability-checklist-YYYYMMDD-HHMMSS/
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 6 — Enroll and Stabilize

Workflow: [[reimaging-guide#Phase 6 — Enroll and Stabilize|reimaging-guide.md — Phase 6]].

Detailed capture runbook: [enroll-and-stabilize.md](../enroll-and-stabilize.md)

Script-generated evidence:

```bash
export REIMAGE_WORKSPACE_ROOT=/path/to/local/reimage-workspace

cd "$REIMAGE_ROOT"
set -a
source ./reimage.env
set +a
chmod +x scripts/capture-enrollment.sh

./scripts/capture-enrollment.sh   --backup-root "$BACKUP_ROOT"   --open
```

Preferred generated output:

```text
$BACKUP_ROOT/reimaged-system/enrollment/capture-enrollment-YYYYMMDD-HHMMSS/
```

Typical contents:

```text
enrollment-capture.md
MANIFEST.txt
raw/
  01-enrollment-status.txt
  02-profiles-list.txt
  03-filevault-status.txt
  04-managed-apps.txt
  05-managed-processes.txt
  06-macos-version.txt
  07-softwareupdate-list.txt
```

Fallback output roots verified by the script:

```text
$REIMAGE_WORKSPACE_ROOT/enrollment/capture-enrollment-YYYYMMDD-HHMMSS/
~/Desktop/reimaged-system-artifacts/enrollment/capture-enrollment-YYYYMMDD-HHMMSS/
```

Manual / fallback notes:

- The generated `enrollment-capture.md` prefills the command-verifiable rows and leaves the mixed/manual rows for you.
- Manual confirmation is still needed for Company Portal UI state, whether the required managed app set looks normal, whether macOS updates were intentionally deferred, and whether the first stabilization restart completed cleanly.
- If `$BACKUP_ROOT` is not available yet, capture Phase 6 locally first, then keep the output path available so it can be copied into the main artifact tree later.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 7 — Initial Captures and Sanity Checks

Workflow: [[reimaging-guide#Phase 7 — Initial Captures and Sanity Checks|reimaging-guide.md — Phase 7]].

Detailed capture runbook: [capture-initial-reimaged-system.md](../capture-initial-reimaged-system.md)

Script-generated evidence:

```bash
cd "$REIMAGE_ROOT"
set -a
source ./reimage.env
set +a
chmod +x scripts/initial-reimaged-system-checklist.sh

./scripts/initial-reimaged-system-checklist.sh   --backup-root "$BACKUP_ROOT"   --open
```

Generated bundle location:

```text
$BACKUP_ROOT/reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/
```

Typical contents verified from `initial-reimaged-system-checklist.sh`:

```text
README.md
initial-checklist.md
restart-checkpoints.md
time-machine-reimaged-system-plan.md
manual-captures-required.md
logs/
raw/
checks/
```

Related `reimaged-system/` paths created or reused by the script:

```text
$BACKUP_ROOT/reimaged-system/time-machine/
$BACKUP_ROOT/reimaged-system/restarts/
$BACKUP_ROOT/reimaged-system/restore-notes/
$BACKUP_ROOT/reimaged-system/latest-initial-reimaged-system-bundle.txt
```

Manual / fallback notes:

- Run the script twice around the planned restart and compare the two generated bundles for regressions.
- The manual checklist still owns first-boot confirmation items such as Company Portal UI state, real internal-site reachability, Chrome/Terminal/display/peripheral usability, and whether the first post-enrollment restart actually happened.
- If the external drive is temporarily unavailable, the runbook documents a local `--output-root` fallback; copy that bundle back under `$BACKUP_ROOT/reimaged-system/` later.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 11A — Capture Workflow Snapshot

Workflow: [[reimaging-guide#Phase 11A — Capture Workflow Snapshot|reimaging-guide.md — Phase 11A]].

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

Manual / fallback notes:

- Phase 11A uses the same current destination family as the workflow snapshot runbook: a fresh timestamped `pre-image-workflow-snapshot-*` bundle plus a refreshed `reimage-workflow-docs/` copy.
- Use this phase when you want the final workflow-doc state that actually reflects the rebuilt system and any runbook refinements made during restore.
- Manual notes are rarely needed unless you want to explain why the post-image workflow-doc snapshot differs from the pre-image one.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 11B — Post-Image System Inventory Capture

Workflow: [[reimaging-guide#Phase 11B — Post-Image System Inventory Capture|reimaging-guide.md — Phase 11B]].

Detailed capture runbook: [capture-system-inventory.md](../capture-system-inventory.md)

Script-generated evidence:

```bash
cd "$REIMAGE_ROOT"
set -a
source ./reimage.env
set +a
mkdir -p "$BACKUP_ROOT/system-inventory"
chmod +x scripts/capture-system-inventory.sh

./scripts/capture-system-inventory.sh   --output "$BACKUP_ROOT/system-inventory/post-image-$(date +%Y%m%d-%H%M%S)"
```

Destination:

```text
$BACKUP_ROOT/system-inventory/post-image-YYYYMMDD-HHMMSS/
```

Typical contents:

| Category | Typical files or folders |
|---|---|
| Inventory manifest | `MANIFEST.txt` |
| Bundle structure | `Brewfile`, `dotfiles/`, `01-hardware.txt` through `16-certs.txt` |
| Hardware/macOS and disk/display | rebuilt-system identity and peripheral/display context |
| Installed software and toolchains | apps, Homebrew, shell, Git, Python, Java, Node, Docker |
| Network/cloud/cert context | hostnames, SSH, cloud paths, environment clues, certificate pointers |

Manual / fallback notes:

- Manual notes are still optional and should be limited to missing context the generated bundle cannot show, such as display arrangement/scaling or a restore constraint that matters for interpretation.
- Use this bundle as the canonical post-image device-identity and workstation-context snapshot before duplicating notes anywhere else.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 11C — Post-Image Company-Managed Inventory Capture

Workflow: [[reimaging-guide#Phase 11C — Post-Image Company-Managed Inventory Capture|reimaging-guide.md — Phase 11C]].

Detailed capture runbook: [capture-managed-inventory.md](../capture-managed-inventory.md)

Script-generated evidence:

```bash
cd "$REIMAGE_ROOT"
set -a
source ./reimage.env
set +a
mkdir -p "$BACKUP_ROOT/managed-inventory"
chmod +x scripts/capture-managed-inventory.sh

./scripts/capture-managed-inventory.sh --phase post-image
```

Destination:

```text
$BACKUP_ROOT/managed-inventory/post-image-YYYYMMDD-HHMMSS/
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

Manual / fallback notes:

- There is no separate fallback checklist for this capture.
- Add a short comparison note only if a managed-state difference still needs explanation after reviewing the generated bundle.
- This is the most precise post-image record of expected MDM profiles, managed apps, receipts, launch items, system extensions, and managed preference payloads.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 11D — Post-Image Performance Audit Capture

Workflow: [[reimaging-guide#Phase 11D — Post-Image Performance Audit Capture|reimaging-guide.md — Phase 11D]].

Detailed capture runbook: [capture-performance-audit.md](../capture-performance-audit.md)

Script-generated evidence:

```bash
cd "$REIMAGE_ROOT"
source ./reimage.env
chmod +x scripts/capture-performance-audit.sh

export PERF_AUDIT_OUTPUT_ROOT="$BACKUP_ROOT/performance-audit"
mkdir -p "$PERF_AUDIT_OUTPUT_ROOT"

./scripts/capture-performance-audit.sh   --output "$PERF_AUDIT_OUTPUT_ROOT"   --phase post-image   --scenario normal-workload   --sample-count 6   --sample-interval 30
```

Destination root:

```text
$BACKUP_ROOT/performance-audit/
```

Scenario bundles normally use names like:

```text
post-image-performance-audit-clean-boot-YYYYMMDD-HHMMSS/
post-image-performance-audit-normal-workload-YYYYMMDD-HHMMSS/
post-image-performance-audit-active-dev-YYYYMMDD-HHMMSS/
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

Manual / fallback notes:

- Use the same scenario names as the pre-image run so the before/after comparison stays meaningful.
- Review the generated `manual-observations.md` and `workload-reproduction-config.md` instead of creating separate duplicate notes first.
- The post-image comparison checklist still needs a human decision about workload match, memory/process deltas, responsiveness, and Docker/IntelliJ resource comparability.
- If you staged results locally, copy the completed audit folders into `$BACKUP_ROOT/performance-audit/` before Phase 12 final validation.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 11E — Post-Image Office Stability Capture

Workflow: [[reimaging-guide#Phase 11E — Post-Image Office Stability Capture|reimaging-guide.md — Phase 11E]].

Detailed capture runbook: [capture-office-stability-audit.md](../capture-office-stability-audit.md)

Script-generated evidence:

```bash
cd "$REIMAGE_ROOT"
source ./reimage.env
chmod +x scripts/capture-office-stability-baseline.sh scripts/office-stability-checklist.sh

./scripts/capture-office-stability-baseline.sh   --phase post-reimage   --backup-root "$BACKUP_ROOT"

./scripts/office-stability-checklist.sh   --phase post-reimage   --backup-root "$BACKUP_ROOT"   --open
```

Destination root:

```text
$BACKUP_ROOT/office-stability/
```

Primary post-image evidence types:

| Evidence type | Typical destination |
|---|---|
| Post-image Office baseline bundle | `post-reimage-office-baseline-YYYYMMDD-HHMMSS/` |
| Zipped copy of the same baseline | `post-reimage-office-baseline-YYYYMMDD-HHMMSS.zip` |
| Office comparison checklist report | `checklists/post-image-office-stability-checklist-YYYYMMDD-HHMMSS/` |
| Summary copy | `office-stability-summary-YYYYMMDD-HHMMSS.md` |
| Optional watcher-derived incident files | `workload-snapshot-*.txt`, `unified-log-office-*.txt`, `install-log-office-*.txt`, `latest-watcher-after-close-*.txt` |

Generated checklist bundle contents:

```text
README.md
post-image-office-stability-checklist.md
logs/
watcher/
processes/
system/
```

Manual / fallback notes:

- Prefer the generated `post-image-office-stability-checklist.md` for actual sign-off; use the manual template only when you still need a compact summary.
- Manual review still matters for whether Outlook and OneNote remain open during normal use, whether update/installer activity truly settled, and whether the rebuilt Mac is ready for IT escalation if the issue recurs.
- If an incident happens again, capture the workload snapshot and latest watcher tail before reopening the apps, then regenerate the post-reimage baseline.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase 12 — Reimaged System Checks

Workflow: [[reimaging-guide#Phase 12 — Reimaged System Checks|reimaging-guide.md — Phase 12]].

Detailed capture runbooks: [capture-validated-reimaged-system.md](../capture-validated-reimaged-system.md) and [scripts/reimage-checklist.sh](../scripts/reimage-checklist.sh)

Script-generated evidence:

```bash
cd "$REIMAGE_ROOT"
set -a
source ./reimage.env
set +a
chmod +x scripts/reimage-checklist.sh

./scripts/reimage-checklist.sh   --phase post   --backup-root "$BACKUP_ROOT"   --open
```

Actual output paths verified from `reimage-checklist.sh`:

```text
$BACKUP_ROOT/reimaged-system/checklists/reimage-checklist-YYYYMMDD-HHMMSS.md
$BACKUP_ROOT/reimaged-system/checklists/latest-reimage-checklist.txt
```

Related `reimaged-system/` directories the script ensures exist:

```text
$BACKUP_ROOT/reimaged-system/time-machine/
$BACKUP_ROOT/reimaged-system/restarts/
$BACKUP_ROOT/reimaged-system/restore-notes/
```

What the automated report covers:

| Area | Examples of automated checks |
|---|---|
| System identity | macOS version, current user, hostname, FileVault |
| MDM and security | enrollment status, Company Portal app, CrowdStrike, Zscaler |
| Office and OneDrive | Outlook, OneNote, Word, Excel, PowerPoint, Teams, OneDrive presence |
| Developer tools | Homebrew, Git, Java, Gradle, Maven, Python, Node, npm, Docker CLI, `jq`, `yq` |
| Daily apps | IntelliJ IDEA, Docker, VS Code, Obsidian, Postman, Chrome, Raycast |
| Git and network | repo discovery in workspace roots, public network, optional internal URL |
| Evidence bundle checks | `reimaged-system/`, performance-audit, office-stability, `/Volumes/Data` Time Machine exclusion |

Manual / fallback notes:

- The generated report is the source of truth; use this section only for the manual rows it cannot prove.
- Manual sign-off still includes Company Portal compliance UI, real internal-site access, OneDrive completion, Office stability under normal use, important project readiness, Git identity checks, SSH fingerprint checks, shell alias restore, display/peripheral correctness, and the second post-image Time Machine backup.
- Review any notes placed under `$BACKUP_ROOT/reimaged-system/restore-notes/` before final sign-off so restore exceptions and deferred items stay attached to the validation evidence.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Templates

### Template — Post-Image Final Manual Sign-Off

```text
Post-Image Final Manual Sign-Off — YYYY-MM-DD

Managed baseline and restart checkpoints:
  [ ] Phase 6 enrollment capture reviewed
  [ ] Phase 7 initial checklist rerun after restart
  [ ] Required managed apps/security tools remained stable after restart
  Notes:

Final validation run:
  [ ] reimage-checklist.sh --phase post completed
  [ ] latest-reimage-checklist.txt points to the intended final report
  [ ] restore-notes reviewed for deferred/manual follow-up items
  Notes:

Access, sync, and daily-use checks:
  [ ] Company Portal shows registered/compliant
  [ ] VPN/Zscaler reaches real internal work sites
  [ ] OneDrive sync completed or backlog is acceptable
  [ ] Outlook remains open during normal use
  [ ] OneNote remains open during normal use
  [ ] Obsidian vault opens and internal links work
  [ ] Postman collections/environments imported if needed
  [ ] Chrome JSON Formatter and important extensions restored
  Notes:

Project readiness:
  [ ] IntelliJ opens important projects successfully
  [ ] Important Git branches/commits/stashes restored
  [ ] Core project tests/validation completed where needed
  [ ] Work and personal Git identities confirmed in the right repos
  [ ] SSH key fingerprints match GitHub Settings
  Notes:

System finish:
  [ ] Display arrangement, scaling, keyboard, mouse, and audio are correct
  [ ] Shell aliases restored and tested
  [ ] Second reimaged-system Time Machine backup completed
  Notes:

Completed by: TODO
Date: YYYY-MM-DD
```

[[#Table of Contents|⬆ Back to Table of Contents]]
