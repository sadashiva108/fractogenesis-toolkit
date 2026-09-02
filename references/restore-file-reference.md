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
- [[#Home Restore Sources|Home Restore Sources]]
- [[#License Keys and Activation Material|License Keys and Activation Material]]

---

## Phase Guide Reference

Single source of truth for the phase guides used across the post-image stage (Phase 8 through Phase 16), in the order they are typically reached. Linked from [[reimaging-guide#Post-Image|Post-Image]] in Workflow Map and Reference Guides — update this table, not a copy in the guide, when a post-image runbook is added, renamed, or retired.

| File | Purpose |
|---|---|
| `reimaging-guide.md` | Canonical phase map for the full post-image restore and validation flow. |
| `enroll-and-stabilize.md` | Managed enrollment, required apps/security tools, updates, and the first stabilization restart. |
| `verify-reimaged-system.md` | External-drive reconnect, first-boot record twice around a restart, sanity checks, and the first post-image Time Machine timing. |
| `restore-runtime.md` | Xcode CLT, Homebrew, Java, Node, Gradle, Maven, Groovy, and platform CLI restore. |
| `restore-access.md` | SSH, certificates, Java trust overrides, shell/CLI config, secrets, and license/activation restore. |
| `restore-git.md` | Git identities, SSH routing, and work/personal repo configuration restore. |
| `restore-repos.md` | Repository re-clone from the pre-image audit, and rsync of reviewed kept ignored files back into each working tree. |
| `restore-apps.md` | Umbrella app-restore flow for Office, OneDrive, Chrome, Obsidian, Postman, VS Code, Raycast, and other daily apps. |
| `restore-docker.md` | Docker Desktop restore, resource tuning, and local dev container recovery. |
| `restore-intellij.md` | IntelliJ settings, Scratches, Consoles, project metadata, and encrypted IDE secret restore. |
| `capture-system-inventory.md` | Post-image system inventory comparison capture. |
| `capture-managed-inventory.md` | Optional post-image managed-app/profile comparison capture. |
| `capture-performance-audit.md` | Post-image performance audit and before/after comparison workflow. |
| `capture-office-stability.md` | Post-image Office stability comparison and symptom follow-up. |
| `reimaged-system-checks.md` | Final post-image validation workflow and generated sign-off artifacts. |
| `restore-home.md` | Late, selective home-file restore after the clean rebuild is already validated. |
| `run-time-machine.md` | Pre-image (Phase 5) and post-image (Phase 16) Time Machine passes. |
| `references/toolkit-environment-reference.md` | How `$FRACTOGENESIS_HOME`, `reimage.env`, and `.envrc` behave across a clone, a `curl` install, and a jump-drive install, and which mechanism loads them at each stage. |
| `references/environment-variable-reference.md` | Which runbook owns each `reimage.env` key and when it is written; why most keys are absent from `reimage.env.example`; the write guard, the optional and all-or-nothing shapes, and which boundary recorder checks a key. |
| `reimaging-scripts-guide.md` | Supporting command reference for automation used during restore, post-image capture, and validation. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How Restore Sources Are Organized

This file focuses on the **restore inputs and post-image outputs**: which pre-image artifacts feed each restore phase, where those artifacts live under `$REIMAGE_ARTIFACT_ROOT`, and where the rebuilt Mac writes its new post-image evidence.

It complements the broader workflow docs:

| Need | Use |
|---|---|
| Full post-image phase order | `reimaging-guide.md` Phases 8–15 |
| Managed enrollment baseline | `enroll-and-stabilize.md` |
| Early post-image checklist and sanity checks | `verify-reimaged-system.md` |
| Runtime restore | `restore-runtime.md` |
| Access restore | `restore-access.md` |
| Git restore | `restore-git.md` |
| Repository restore | `restore-repos.md` |
| App restore umbrella | `restore-apps.md` |
| IntelliJ-specific restore | `restore-intellij.md` |
| Docker-specific restore | `restore-docker.md` |
| Final validation | `reimaged-system-checks.md` |
| Late home-file restore | `restore-home.md` |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## External Restore Root Layout

The restore-side layout relevant to Phases 8–15 is:

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
│   ├── runs/
│   │   ├── pre-image-YYYYMMDD-HHMMSS/
│   │   └── post-image-restore-YYYYMMDD-HHMMSS/
│   ├── repo-audit-index.md
│   └── official/
│       ├── pre-image.txt
│       └── post-image-restore.txt
├── gitignore-superset/
├── home-files-backup/
│   ├── home/
│   ├── dotfiles/
│   └── MANIFEST.md
├── loose-secrets-reports/
├── managed-inventory/
│   └── runs/
│       ├── pre-image-YYYYMMDD-HHMMSS/
│       └── post-image-YYYYMMDD-HHMMSS/
├── office-stability/
│   ├── pre-reimage-office-baseline-YYYYMMDD-HHMMSS/
│   ├── post-reimage-office-baseline-YYYYMMDD-HHMMSS/
│   └── checklists/
├── performance-audit/
│   ├── pre-image-performance-audit-<scenario>-YYYYMMDD-HHMMSS/
│   ├── post-image-performance-audit-<scenario>-YYYYMMDD-HHMMSS/
│   └── rollup-summary/
├── reimaged-system/
│   ├── restarts/
│   │   ├── MANIFEST.md
│   │   ├── official/
│   │   └── runs/enroll-and-stabilize-<point>-YYYYMMDD-HHMMSS/
│   ├── checklists/
│   │   ├── MANIFEST.md
│   │   ├── official/
│   │   │   └── post-image.txt
│   │   └── runs/
│   │       └── post-image-YYYYMMDD-HHMMSS/
│   │           └── reimage-checklist.md
│   ├── restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/
│   │   ├── README.md
│   │   ├── checklist.md
│   │   ├── manual-captures-required.md
│   │   ├── restart-checkpoints.md
│   │   ├── time-machine-plan.md
│   │   ├── checks/
│   │   ├── logs/
│   │   └── raw/
│   ├── restarts/official/verify-reimaged-system-<point>.txt
│   ├── sign-offs/
│   │   ├── <runbook>-YYYYMMDD-HHMMSS.md
│   │   └── latest-<runbook>.txt
│   ├── restore-notes/
│   ├── restarts/
│   └── time-machine/
├── secrets-encrypted/
│   ├── all-secrets-YYYYMMDD-HHMMSS.dmg
│   ├── all-secrets-YYYYMMDD-HHMMSS-manifest.txt
│   ├── RESTORE-README.md
│   ├── certs/
│   ├── chrome/
│   ├── claude/                          # Claude Desktop config (claude_desktop_config.json)
│   ├── claude-code/                     # Claude Code .claude.json — MCP servers, account/org identifiers
│   ├── cli-credentials/
│   ├── cloud/
│   ├── docker/
│   ├── extra-secrets-certs-review/      # Phase 3A cert/Keychain review area: discovery/, plan/, decisions/, state/
│   ├── git/
│   ├── gnupg/
│   ├── intellij/
│   ├── kube/
│   ├── licenses/
│   ├── package-managers/
│   ├── postman/
│   ├── raycast/
│   ├── repos-gitignored/                # secret-shaped gitignored repo files routed out of staging by Phase 2A
│   ├── ssh/
│   └── staged-loose/                    # loose secrets relocated by Phase 3B, with MANIFEST.tsv recording each original path
├── staged-ignored-files/
│   └── live/
├── system-inventory/
│   └── runs/
│       ├── pre-image-YYYYMMDD-HHMMSS/
│       └── post-image-YYYYMMDD-HHMMSS/
├── toolkit-snapshot/
│   ├── official/
│   │   └── pre-image-toolkit-snapshot.txt
│   └── runs/
│       └── pre-image-toolkit-snapshot-YYYYMMDD-HHMMSS/
└── public-certs/
```

Not every restore uses every category. Treat this as the full restore/capture map, then use the phase sections below to narrow the active inputs for the current step.

Two `secrets-encrypted/` subtrees have dedicated restore consumers rather than a manual copy-back:

- `secrets-encrypted/staged-loose/` is consumed by `bin/restore-staged-loose.sh`, driven from [[restore-access|restore-access.md]] (Phase 10B). It reads `MANIFEST.tsv` and returns each file to the original path it was staged from.
- `secrets-encrypted/repos-gitignored/` is a rehydration source in the Phase 11B clone plan, merged into each cloned working tree by `./bin/restore-repos.sh --hydrate --stage repo-secrets` with the DMG attached — [[restore-repos|restore-repos.md]] Step 6. These files are deliberately *not* under `staged-ignored-files/live/`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Phase-by-Phase Restore Source Map

| Phase | Main sources under `$REIMAGE_ARTIFACT_ROOT` | Main outputs under `$REIMAGE_ARTIFACT_ROOT` |
|---|---|---|
| Phase 8 — Enroll and Stabilize | none required beyond `reimage.env`; optional mounted artifact root | `reimaged-system/restarts/runs/enroll-and-stabilize-<point>-*/`, `reimaged-system/boundaries/runs/enroll-and-stabilize-{entry,exit}-*/`, `reimaged-system/sign-offs/enroll-and-stabilize-{entry,exit}-*.md` |
| Phase 9 — Initial Captures and Sanity Checks | prepared external root, optional `reimaged-system/restore-notes/` | `reimaged-system/restarts/` (runs, `official/`, `MANIFEST.md`), `reimaged-system/boundaries/`, `reimaged-system/restore-notes/` |
| Phase 10A — Restore Runtime Libraries | `system-inventory/runs/pre-image-*/`, `system-inventory/runs/post-image-*/`, `home-files-backup/dotfiles/` | usually notes only; later validated under `reimaged-system/`. Also retires the Phase 8 `~/.zprofile` bridge and hands config loading to direnv — see `references/toolkit-environment-reference.md` |
| Phase 10B — Restore Access | `secrets-encrypted/`, `public-certs/`, `home-files-backup/dotfiles/` | `reimaged-system/restore-notes/`, `reimaged-system/sign-offs/restore-access-exit-*.md` |
| Phase 11A — Restore Git | `secrets-encrypted/ssh/`, `secrets-encrypted/git/`, `toolkit-snapshot/official/pre-image-toolkit-snapshot.txt` | dual `~/.gitconfig` + `~/.ssh/config` in place; validated end-to-end for work and personal identities |
| Phase 11B — Restore Repositories | `repo-audit-reports/runs/pre-image-*/repos.tsv`, `staged-ignored-files/live/<label>/` | `repo-audit-reports/runs/post-image-restore-*/`, `repo-audit-reports/official/post-image-restore.txt`, `reimaged-system/sign-offs/post-image-restore-*.md`, working repo checkouts |
| Phase 12 — Restore Apps | `app-settings-backup/`, `secrets-encrypted/`, `reimaged-system/restore-notes/` | `reimaged-system/restore-notes/restore-{apps,docker,intellij}-plan-*.md`, `reimaged-system/sign-offs/restore-{apps,docker,intellij}-*.md` |
| Phase 13 — Post-Image Captures | matching Phase 4 capture outputs for comparison | `toolkit-snapshot/runs/post-image-toolkit-snapshot-*/`, `system-inventory/runs/post-image-*/`, `managed-inventory/runs/post-image-*/`, `performance-audit/runs/post-image-performance-audit-*/`, `office-stability/runs/post-image-office-stability-*/` |
| Phase 14 — Reimaged System Checks | everything needed for final validation context; every `reimaged-system/sign-offs/` file | `reimaged-system/checklists/runs/post-image-*/reimage-checklist.md`, `reimaged-system/checklists/official/post-image.txt`, `reimaged-system/sign-offs/reimaged-system-checks-*.md`, optional prose follow-up in `reimaged-system/restore-notes/` |
| Phase 15 — Restore Home | `home-files-backup/home/`, `home-files-backup/dotfiles/`, optionally `staged-ignored-files/live/` | `reimaged-system/restore-notes/decisions.md`; optional final notes under `reimaged-system/restore-notes/` |
| Phase 16 — Post-Image Time Machine | the rebuilt Mac itself; `$EXTERNAL_APPLE_BACKUPS_VOLUME` as destination | `time-machine/` completion, verification, and log artifacts |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Managed Baseline and Early Post-Image Evidence

These paths are used before deeper restore work begins.

| Need | Source or destination |
|---|---|
| Enrollment record run | `reimaged-system/restarts/runs/enroll-and-stabilize-<point>-YYYYMMDD-HHMMSS/` |
| Enrollment official-run pointer | `reimaged-system/restarts/official/enroll-and-stabilize-<point>.txt` |
| First post-image checklist bundle root | `reimaged-system/restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/` |
| Official-run pointer per point | `reimaged-system/restarts/official/verify-reimaged-system-<point>.txt` |
| Initial bundle summary and checklist | `reimaged-system/restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/README.md`, `reimaged-system/restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/checklist.md` |
| Initial bundle manual follow-up files | `reimaged-system/restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/manual-captures-required.md`, `reimaged-system/restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/restart-checkpoints.md`, `reimaged-system/restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/time-machine-plan.md` |
| Initial bundle raw evidence folders | `reimaged-system/restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/raw/`, `reimaged-system/restarts/runs/verify-reimaged-system-<point>-YYYYMMDD-HHMMSS/logs/` |
| Rows a person answers, per runbook | `reimaged-system/sign-offs/<runbook>-YYYYMMDD-HHMMSS.md`, `reimaged-system/sign-offs/latest-<runbook>.txt` |
| Decisions no capture can hold, whole event | `reimaged-system/restore-notes/decisions.md` |
| Manual early restore notes | `reimaged-system/restore-notes/` |
| Restart notes or checkpoints | `reimaged-system/restarts/` |
| First post-image backup notes | `time-machine/` — the root-level category, alongside the pre-image runs |

Phase 8 can also stage locally under `REIMAGE_WORKSPACE_ROOT/` when the external drive is not mounted yet. Phase 9 Step 1 copies those runs into `$REIMAGE_ARTIFACT_ROOT/reimaged-system/` and reindexes the destination category, since a copied run carries no index row of its own.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Runtime and Access Sources

Use these during [[restore-runtime|restore-runtime.md]] and [[restore-access|restore-access.md]]:

| Need | Source |
|---|---|
| Brewfile comparison | `system-inventory/runs/pre-image-*/Brewfile` and `system-inventory/runs/post-image-*/Brewfile` when present |
| Pre/post runtime inventory comparison | `system-inventory/runs/pre-image-*/` and `system-inventory/runs/post-image-*/` |
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
| `toolkit-snapshot/official/pre-image-toolkit-snapshot.txt` → `runs/<id>/docs/` | Fallback copy of the workflow docs so `fractogenesis-toolkit` can be restored first |

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

These are the Phase 13 comparison outputs created after the rebuilt Mac is substantially restored:

| Capture | Destination |
|---|---|
| Toolkit snapshot | `toolkit-snapshot/official/pre-image-toolkit-snapshot.txt` and the `toolkit-snapshot/runs/pre-image-toolkit-snapshot-YYYYMMDD-HHMMSS/` it names |
| System inventory | `system-inventory/runs/post-image-YYYYMMDD-HHMMSS/` |
| Company-managed inventory | `managed-inventory/runs/post-image-YYYYMMDD-HHMMSS/` |
| Performance audit | `performance-audit/runs/post-image-performance-audit-<scenario>-YYYYMMDD-HHMMSS/` |
| Office stability | `office-stability/runs/post-image-office-stability-evidence-YYYYMMDD-HHMMSS/` and `office-stability/runs/post-image-office-stability-assessment-YYYYMMDD-HHMMSS/` |

Use these as the **after** side of the comparison against Phase 4, not as replacements for the original pre-image evidence.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Final Validation and Manual Notes

Phase 14 writes the final rebuilt-system sign-off artifacts under:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists/reimage-checklist-YYYYMMDD-HHMMSS.md
$REIMAGE_ARTIFACT_ROOT/reimaged-system/checklists/official/post-image.txt
```

Unlike the initial checklist bundle, Phase 14 does not currently generate a separate root-level `manual-captures-required.md`. Keep unresolved manual follow-up in `reimaged-system/restore-notes/` or `reimaged-system-evidence.md`.

Related manual-note locations:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts/
```

Use `capture-system-inventory.md` as the canonical source for device identity and display/peripheral context. Use `reimaged-system-evidence.md` only when a script-backed workflow leaves a manual row unresolved or you need a compact fallback note.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Home Restore Sources

Use these late in [[restore-home|restore-home.md]]:

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
