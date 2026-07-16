[[reimaging-guide#Post-Image|← Back to Mac Reimaging Guide]]

# Restore File Reference

A complete reference for the restore-side files, directories, and generated evidence used across the **post-image** phases.

This document assumes the standard artifact model: workflow source files stay in the fractogenesis-toolkit repo, while restore sources and generated post-image evidence live under `$REIMAGE_ARTIFACT_ROOT`.

---

## Table of Contents

- [[#Phase Guide Reference|Phase Guide Reference]]
- [[#How Restore Sources Are Organized|How Restore Sources Are Organized]]
- [[#External Restore Root Layout|External Restore Root Layout]]
- [[#Phase-by-Phase Restore Source Map|Phase-by-Phase Restore Source Map]]
- [[#Managed Baseline and Early Post-Image Evidence|Managed Baseline and Early Post-Image Evidence]]
- [[#Runtime and Access Sources|Runtime and Access Sources]]
- [[#Git and Repository Sources|Git and Repository Sources]]
- [[#App Restore Sources|App Restore Sources]]
- [[#Post-Image Comparison Captures|Post-Image Comparison Captures]]
- [[#Final Validation and Manual Notes|Final Validation and Manual Notes]]
- [[#Local-File Restore Sources|Local-File Restore Sources]]
- [[#License Keys and Activation Material|License Keys and Activation Material]]

---

## Phase Guide Reference

Single source of truth for the phase guides used across the post-image stage (Phase 6 through Phase 13), in the order they are typically reached. Linked from [[reimaging-guide#Post-Image|Post-Image]] in Workflow Map and Reference Guides — update this table, not a copy in the guide, when a post-image runbook is added, renamed, or retired.

| File | Purpose |
|---|---|
| `reimaging-guide.md` | Canonical phase map for the full post-image restore and validation flow. |
| `enroll-and-stabilize.md` | Managed enrollment, required apps/security tools, updates, and the first stabilization restart. |
| `capture-initial-reimaged-system.md` | External-drive reconnect, initial checklist runs, sanity checks, and the first post-image Time Machine timing. |
| `restore-runtime.md` | Xcode CLT, Homebrew, Java, Node, Gradle, Maven, Groovy, and platform CLI restore. |
| `restore-access.md` | SSH, certificates, Java trust overrides, shell/CLI config, secrets, and license/activation restore. |
| `restore-git.md` | Git identities, SSH routing, and work/personal repo configuration restore. |
| `restore-apps.md` | Umbrella app-restore flow for Office, OneDrive, Chrome, Obsidian, Postman, VS Code, Raycast, and other daily apps. |
| `restore-docker.md` | Docker Desktop restore, resource tuning, and local dev container recovery. |
| `restore-intellij.md` | IntelliJ settings, Scratches, Consoles, project metadata, and encrypted IDE secret restore. |
| `capture-system-inventory.md` | Post-image system inventory comparison capture. |
| `capture-managed-inventory.md` | Optional post-image managed-app/profile comparison capture. |
| `capture-performance-audit.md` | Post-image performance audit and before/after comparison workflow. |
| `capture-office-stability-audit.md` | Post-image Office stability comparison and symptom follow-up. |
| `capture-validated-reimaged-system.md` | Final post-image validation workflow and generated sign-off artifacts. |
| `restore-local-files.md` | Late, selective local-file restore after the clean rebuild is already validated. |
| `reimaging-scripts-guide.md` | Supporting command reference for automation used during restore, post-image capture, and validation. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How Restore Sources Are Organized

This file focuses on the **restore inputs and post-image outputs**: which pre-image artifacts feed each restore phase, where those artifacts live under `$REIMAGE_ARTIFACT_ROOT`, and where the rebuilt Mac writes its new post-image evidence.

It complements the broader workflow docs:

| Need | Use |
|---|---|
| Full post-image phase order | `reimaging-guide.md` Phases 6–13 |
| Managed enrollment baseline | `enroll-and-stabilize.md` |
| Early post-image checklist and sanity checks | `capture-initial-reimaged-system.md` |
| Runtime restore | `restore-runtime.md` |
| Access restore | `restore-access.md` |
| Git restore | `restore-git.md` |
| App restore umbrella | `restore-apps.md` |
| IntelliJ-specific restore | `restore-intellij.md` |
| Docker-specific restore | `restore-docker.md` |
| Final validation | `capture-validated-reimaged-system.md` |
| Late local-file restore | `restore-local-files.md` |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## External Restore Root Layout

The restore-side layout relevant to Phases 6–13 is:

```text
$REIMAGE_ARTIFACT_ROOT/
├── app-settings-backup/
│   ├── chrome/
│   ├── docker/
│   ├── intellij/
│   ├── obsidian/
│   ├── postman/
│   ├── raycast/
│   └── vscode/
├── repo-audit-reports/
├── gitignore-superset/
├── home-files-backup/
│   ├── home/
│   ├── dotfiles/
│   └── MANIFEST.md
├── managed-inventory/
│   ├── pre-image-YYYYMMDD-HHMMSS/
│   └── post-image-YYYYMMDD-HHMMSS/
├── office-stability/
│   ├── pre-reimage-office-baseline-YYYYMMDD-HHMMSS/
│   ├── post-reimage-office-baseline-YYYYMMDD-HHMMSS/
│   └── checklists/
├── performance-audit/
│   ├── pre-image-performance-audit-<scenario>-YYYYMMDD-HHMMSS/
│   ├── post-image-performance-audit-<scenario>-YYYYMMDD-HHMMSS/
│   └── rollup-summary/
├── reimaged-system/
│   ├── enrollment/
│   │   ├── capture-enrollment-YYYYMMDD-HHMMSS/
│   │   └── latest-enrollment-capture.txt
│   ├── checklists/
│   │   ├── reimage-checklist-YYYYMMDD-HHMMSS.md
│   │   └── latest-reimage-checklist.txt
│   ├── initial-reimaged-system-YYYYMMDD-HHMMSS/
│   │   ├── README.md
│   │   ├── initial-checklist.md
│   │   ├── manual-captures-required.md
│   │   ├── restart-checkpoints.md
│   │   ├── time-machine-reimaged-system-plan.md
│   │   ├── checks/
│   │   ├── logs/
│   │   └── raw/
│   ├── latest-initial-reimaged-system-bundle.txt
│   ├── restore-notes/
│   ├── restarts/
│   └── time-machine/
├── secrets-encrypted/
│   ├── all-secrets-YYYYMMDD-HHMMSS.dmg
│   ├── all-secrets-YYYYMMDD-HHMMSS-manifest.txt
│   ├── RESTORE-README.md
│   ├── certs/
│   ├── chrome/
│   ├── cli-credentials/
│   ├── cloud/
│   ├── docker/
│   ├── git/
│   ├── gnupg/
│   ├── intellij/
│   ├── kube/
│   ├── licenses/
│   ├── package-managers/
│   ├── postman/
│   ├── raycast/
│   └── ssh/
├── staged-ignored-files/
│   └── live/
├── system-inventory/
│   ├── pre-image-YYYYMMDD-HHMMSS/
│   └── post-image-YYYYMMDD-HHMMSS/
├── workflow-snapshot/
│   ├── latest-pre-image-workflow-snapshot -> pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/
│   ├── latest-pre-image-workflow-snapshot.txt
│   ├── pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/
│   └── reimage-workflow-docs/
└── public-certs/
```

Not every restore uses every category. Treat this as the full restore/capture map, then use the phase sections below to narrow the active inputs for the current step.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase-by-Phase Restore Source Map

| Phase | Main sources under `$REIMAGE_ARTIFACT_ROOT` | Main outputs under `$REIMAGE_ARTIFACT_ROOT` |
|---|---|---|
| Phase 6 — Enroll and Stabilize | none required beyond `reimage.env`; optional mounted backup root | `reimaged-system/enrollment/capture-enrollment-*/`, `reimaged-system/enrollment/latest-enrollment-capture.txt` |
| Phase 7 — Initial Captures and Sanity Checks | prepared external root, optional `reimaged-system/restore-notes/` | `reimaged-system/initial-reimaged-system-*/`, `reimaged-system/latest-initial-reimaged-system-bundle.txt`, `reimaged-system/restore-notes/`, `reimaged-system/restarts/`, `reimaged-system/time-machine/` |
| Phase 8A — Restore Runtime Libraries | `system-inventory/pre-image-*/`, `system-inventory/post-image-*/`, `home-files-backup/dotfiles/` | usually notes only; later validated under `reimaged-system/` |
| Phase 8B — Restore Access | `secrets-encrypted/`, `public-certs/`, `home-files-backup/dotfiles/` | `reimaged-system/restore-notes/` |
| Phase 9 — Restore Git | `secrets-encrypted/ssh/`, `secrets-encrypted/git/`, `repo-audit-reports/`, `workflow-snapshot/reimage-workflow-docs/` | working repo checkouts; later validated under `reimaged-system/` |
| Phase 10 — Restore Apps | `app-settings-backup/`, `secrets-encrypted/`, `reimaged-system/restore-notes/` | app-specific notes and later validation evidence |
| Phase 11 — Post-Image Captures | matching Phase 3 capture outputs for comparison | `workflow-snapshot/reimage-workflow-docs/`, `workflow-snapshot/pre-image-workflow-snapshot-*/`, `workflow-snapshot/latest-pre-image-workflow-snapshot.txt`, `system-inventory/post-image-*/`, `managed-inventory/post-image-*/`, `performance-audit/post-image-performance-audit-*/`, `office-stability/post-reimage-*/` |
| Phase 12 — Reimaged System Checks | everything needed for final validation context | `reimaged-system/checklists/reimage-checklist-*.md`, `reimaged-system/checklists/latest-reimage-checklist.txt`, optional manual follow-up in `reimaged-system/restore-notes/` |
| Phase 13 — Restore Local Files | `home-files-backup/home/`, `home-files-backup/dotfiles/`, optionally `staged-ignored-files/live/` | optional final notes under `reimaged-system/restore-notes/` |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Managed Baseline and Early Post-Image Evidence

These paths are used before deeper restore work begins.

| Need | Source or destination |
|---|---|
| Enrollment capture bundle | `reimaged-system/enrollment/capture-enrollment-YYYYMMDD-HHMMSS/` |
| Enrollment latest-pointer file | `reimaged-system/enrollment/latest-enrollment-capture.txt` |
| First post-image checklist bundle root | `reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/` |
| Initial checklist latest-pointer file | `reimaged-system/latest-initial-reimaged-system-bundle.txt` |
| Initial bundle summary and checklist | `reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/README.md`, `reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/initial-checklist.md` |
| Initial bundle manual follow-up files | `reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/manual-captures-required.md`, `reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/restart-checkpoints.md`, `reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/time-machine-reimaged-system-plan.md` |
| Initial bundle raw evidence folders | `reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/raw/`, `reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/logs/`, `reimaged-system/initial-reimaged-system-YYYYMMDD-HHMMSS/checks/` |
| Manual early restore notes | `reimaged-system/restore-notes/` |
| Restart notes or checkpoints | `reimaged-system/restarts/` |
| First post-image backup notes | `reimaged-system/time-machine/` |

Phase 6 can also stage locally under `REIMAGE_WORKSPACE_ROOT/enrollment/` when the external drive is not mounted yet, then copy the bundle back into `$REIMAGE_ARTIFACT_ROOT/reimaged-system/enrollment/` later.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Runtime and Access Sources

Use these during [[restore-runtime|restore-runtime.md]] and [[restore-access|restore-access.md]]:

| Need | Source |
|---|---|
| Brewfile comparison | `system-inventory/pre-image-*/Brewfile` and `system-inventory/post-image-*/Brewfile` when present |
| Pre/post runtime inventory comparison | `system-inventory/pre-image-*/` and `system-inventory/post-image-*/` |
| Dotfiles and shell config | `home-files-backup/dotfiles/` |
| SSH keys and SSH config | `secrets-encrypted/ssh/` |
| Git private config | `secrets-encrypted/git/` and `home-files-backup/dotfiles/` |
| Certificates and keychain exports | `secrets-encrypted/certs/` and `public-certs/` |
| Java trust overrides | `secrets-encrypted/certs/java-security/` |
| Cloud and package-manager credentials | `secrets-encrypted/cloud/`, `secrets-encrypted/cli-credentials/`, `secrets-encrypted/package-managers/` |
| Kube and CLI contexts | `secrets-encrypted/kube/`, `home-files-backup/dotfiles/kube/`, `home-files-backup/dotfiles/config/` |
| License or activation material | `secrets-encrypted/licenses/` |

Use `home-files-backup/dotfiles/` as a **selective merge source**, not as a blind overwrite target.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Git and Repository Sources

Use these during [[restore-git|restore-git.md]] and later repository reconstruction:

| Source | Purpose |
|---|---|
| `repo-audit-reports/` | Pre-image repo inventory, branch state, stashes, and audit context |
| `staged-ignored-files/live/` | Local-only project files intentionally preserved outside normal Git history |
| `gitignore-superset/` | Context for what was intentionally excluded or handled separately |
| `secrets-encrypted/ssh/` | Work/personal SSH keys and config inputs |
| `secrets-encrypted/git/` | Private Git config or credential-bearing Git material |
| `workflow-snapshot/reimage-workflow-docs/` | Fallback copy of the workflow docs so `fractogenesis-toolkit` can be restored first |

Restore `fractogenesis-toolkit` early so the active runbooks are available locally for the remaining phases.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## App Restore Sources

Use these during [[restore-apps|restore-apps.md]], [[restore-intellij|restore-intellij.md]], and [[restore-docker|restore-docker.md]]:

| App area | Primary source | Secret-bearing companion |
|---|---|---|
| Chrome | `app-settings-backup/chrome/` | `secrets-encrypted/chrome/` when password exports exist |
| Docker | `app-settings-backup/docker/` | `secrets-encrypted/docker/` |
| IntelliJ | `app-settings-backup/intellij/` | `secrets-encrypted/intellij/` |
| Obsidian | `app-settings-backup/obsidian/` | usually none |
| Postman | `app-settings-backup/postman/` | `secrets-encrypted/postman/` |
| Raycast | `app-settings-backup/raycast/` | `secrets-encrypted/raycast/` when used |
| VS Code | `app-settings-backup/vscode/` | usually none |
| Office / Teams / OneDrive | usually managed install or cloud sync first | license or identity context only when separately needed |

Useful app-specific subpaths:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/chrome/bookmarks_YYYYMMDD-HHMMSS.html
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/settings-store.json
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/daemon.json
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/manual-settings-export/
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/project-metadata/
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/collections/
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/postman/environments-redacted/
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/raycast/
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/vscode/user/
```

Keep secret-bearing app state separate from plain exports whenever both exist.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Post-Image Comparison Captures

These are the Phase 11 comparison outputs created after the rebuilt Mac is substantially restored:

| Capture | Destination |
|---|---|
| Workflow snapshot | `workflow-snapshot/reimage-workflow-docs/`, `workflow-snapshot/pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/`, and `workflow-snapshot/latest-pre-image-workflow-snapshot.txt` |
| System inventory | `system-inventory/post-image-YYYYMMDD-HHMMSS/` |
| Company-managed inventory | `managed-inventory/post-image-YYYYMMDD-HHMMSS/` |
| Performance audit | `performance-audit/post-image-performance-audit-<scenario>-YYYYMMDD-HHMMSS/` |
| Office stability | `office-stability/post-reimage-office-baseline-YYYYMMDD-HHMMSS/` and `office-stability/checklists/` |

Use these as the **after** side of the comparison against Phase 3, not as replacements for the original pre-image evidence.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Final Validation and Manual Notes

Phase 12 writes the final rebuilt-system sign-off artifacts under:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists/reimage-checklist-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists/latest-reimage-checklist.txt
```

Unlike the initial checklist bundle, Phase 12 does not currently generate a separate root-level `manual-captures-required.md`. Keep unresolved manual follow-up in `reimaged-system/restore-notes/` or `reimaged-system-evidence.md`.

Related manual-note locations:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/
$REIMAGE_ARTIFACT_ROOT/reimaged-system/time-machine/
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts/
```

Use `capture-system-inventory.md` as the canonical source for device identity and display/peripheral context. Use `reimaged-system-evidence.md` only when a script-backed workflow leaves a manual row unresolved or you need a compact fallback note.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Local-File Restore Sources

Use these late in [[restore-local-files|restore-local-files.md]]:

| Source | Typical target |
|---|---|
| `home-files-backup/home/Documents/` | `~/Documents/` |
| `home-files-backup/home/Desktop/` | `~/Desktop/` |
| `home-files-backup/home/Music/` | `~/Music/` |
| `home-files-backup/home/Pictures/` | `~/Pictures/` |
| `home-files-backup/home/Movies/` | `~/Movies/` |
| `home-files-backup/home/scripts/` | `~/scripts/` |
| `home-files-backup/home/config-files-backups/` | `~/config-files-backups/` |
| `home-files-backup/home/Development/runConfigurations/` | selective project/tool restore only when still needed |
| `home-files-backup/home/IdeaSnapshots/` | IntelliJ-related restore only when still needed |
| `home-files-backup/dotfiles/` | selective merge into home dotfiles and config dirs |
| `staged-ignored-files/live/` | project-by-project restore of intentionally preserved local-only files |

Prefer cloud resync over manual copy for OneDrive-managed content, and restore app support data through the app-specific runbooks rather than through broad local-file copy-back.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## License Keys and Activation Material

Actual license keys, serials, offline activation files, and activation exports belong under:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/licenses/
```

Use that directory for:

```text
license files
serial-number exports
offline activation bundles
vendor recovery instructions containing private identifiers
subscription screenshots or PDFs that include account-specific details
```

Keep only redacted notes in plain Markdown under:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/
```

Mount the consolidated secrets DMG only when needed, copy the smallest set of activation files required, and remove temporary plaintext copies after validation.

[[#Table of Contents|⬆ Back to Table of Contents]]
