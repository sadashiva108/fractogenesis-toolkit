---
title: Create Secrets DMG
back_link: "reimaging-guide#Phase 2F — Create Secrets DMG"
runbook_version: 0.1.0
verb_first: true
primary_scripts:
  - bin/create-secrets-dmg.sh
related_scripts:
  - bin/stage-certs-keychain.sh
artifact_paths:
  - $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/
author: Shiva
last_updated: 2026-08-03
---
[[reimaging-guide#Phase 2F — Create Secrets DMG|← Back to Mac Reimaging Guide]]

# Create Secrets DMG

Package every credential-bearing file that must survive the reimage into one AES-256 encrypted DMG, prove the restore copy is inside the mounted image, and only then remove the loose plaintext staging. Build once, at the end of manual secret collection.

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
    - [[#Load Shared Configuration|Load Shared Configuration]]
    - [[#Confirm Manual Staging Is Present|Confirm Manual Staging Is Present]]
    - [[#Build the Encrypted DMG|Build the Encrypted DMG]]
    - [[#Validate the Mounted DMG|Validate the Mounted DMG]]
    - [[#Clean Up Loose Plaintext After Validation|Clean Up Loose Plaintext After Validation]]
- [[#Decisions|Decisions]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#What Gets Staged|What Gets Staged]]
    - [[#Verification Reports|Verification Reports]]
    - [[#Expected Final Layout|Expected Final Layout]]
    - [[#Post-Image Restore Notes|Post-Image Restore Notes]]
    - [[#Manual Items That Remain Manual|Manual Items That Remain Manual]]
    - [[#Sign-Off Templates|Sign-Off Templates]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Consolidate the reviewed secret material from the earlier Phase 2 backups into a single encrypted restore container: build `all-secrets-*.dmg`, save its password in an approved password manager, mount and verify the intended material is inside, and remove the loose plaintext staging only after that verification succeeds. The validated DMG is the source of truth for secret restore after reimage. This phase can be rerun; each run writes a fresh timestamped DMG, and any new secret staged after a build means building again.

This runbook owns:

```text
consolidated encrypted secrets DMG creation
Java jssecacerts capture from live JDK/JBR locations into the DMG
mounted-DMG validation before any cleanup
loose plaintext staging cleanup after validation
generated manifest, jssecacerts inventory, and RESTORE-README
```

It does not own:

```text
certificate/Keychain discovery, review, and manual export staging into public-certs/ and secrets-encrypted/certs/ — stage-certs-keychain.md (Phase 2E)
routing of ssh/gnupg/docker/kube, IntelliJ HTTP Client env files, and app-secret byproducts into secrets-encrypted/ — backup-home.md, backup-apps.md, backup-intellij.md, backup-repos.md
artifact root and reimage.env preparation — prepare-artifact-root.md
the Phase 4B pre-image sign-off these verifications roll up to — reimage-prep-checks.md
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Phase 2F is the *consolidation and validation* pass. The earlier phases already routed most credential-shaped files into `secrets-encrypted/` — SSH, GPG, Docker, kube, and app-secret exports as a byproduct of backing up home and apps (Phases 2B/2D), and reviewed certificate/Keychain material through the Phase 2E staging runbook. This phase collects all of it, plus a few things it captures live (Java `jssecacerts` from installed JDKs, and loose cert bundles on Desktop/Downloads), into one encrypted image so restore depends on a single password and a single artifact.

The reason for the strict order is that the cleanup step deletes plaintext secrets. That is only safe once the encrypted copy is proven readable, so the flow never lets validation and cleanup swap places:

```text
stage secret material        (Phases 2B–2E, plus this run's live captures)
build the encrypted DMG      (this phase)
save the DMG password        (approved password manager — immediately)
mount and validate           (prove the restore copy is inside)
clean up loose plaintext     (only after validation)
```

The preferred path is a single consolidated `all-secrets-*.dmg` built once after all manual secret exports are staged. Building one image — rather than several partial DMGs — means one password to store, one artifact to validate, and one restore source. Rerun the build only when you add secret material after a prior build.

By default the build first reruns the Phase 2E review scan so the certificate/Keychain review artifacts in the DMG are current; `--skip-cert-review` turns that refresh off when you intentionally want the existing review files frozen.

The phase runs as four subcommands of the same entrypoint. Each check reads what actually exists (on disk and inside the DMG), so it never drifts as the app set grows, and `verify-staging` / `validate` / `cleanup` each write a timestamped report to the drive:

| Subcommand | Command | What it does |
|---|---|---|
| Verify | `create-secrets-dmg.sh verify-staging` | Report what is staged under `secrets-encrypted/`, before building. |
| Build | `create-secrets-dmg.sh` (default) | Stage every category and build `all-secrets-*.dmg`. |
| Validate | `create-secrets-dmg.sh validate` | Mount the newest DMG, check it against what's on disk, detach. |
| Cleanup | `create-secrets-dmg.sh cleanup [--force]` | Remove loose plaintext confirmed inside the DMG (dry-run without `--force`). |

### Terminology

| Term | Meaning |
|---|---|
| DMG | A macOS disk image file. Here, `all-secrets-*.dmg` is the AES-256 encrypted image that packages the staged secret material for restore. |
| Staging tree | The temporary `staging-<stamp>/` folder the build assembles inside `secrets-encrypted/`, then encrypts and wipes. It is not left on disk. |
| Loose plaintext staging | Reviewed secret folders under `secrets-encrypted/` (e.g. `certs/`, `chrome/`) that exist only until the DMG is validated. |
| Mounted DMG | The opened image under `/Volumes/all-secrets-*` used to verify contents before cleanup. |
| Validated | The DMG has been mounted with the saved password *and* the intended material confirmed inside — not merely that the `.dmg` file exists. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script (entrypoint):

```text
$FRACTOGENESIS_HOME/bin/create-secrets-dmg.sh
```

Related script (entrypoint; rerun by the build for the Phase 2E review refresh unless `--skip-cert-review`):

```text
$FRACTOGENESIS_HOME/bin/stage-certs-keychain.sh
```

Artifact locations — everything this phase reads and writes lives under one tree:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/
```

The build writes these outputs there (timestamped unless noted):

```text
all-secrets-YYYYMMDD-HHMMSS.dmg              # the encrypted restore artifact — keep
all-secrets-YYYYMMDD-HHMMSS-manifest.txt     # source paths included — keep
RESTORE-README.md                            # generated restore notes — keep
java-jssecacerts-inventory-YYYYMMDD-HHMMSS.md  # discovered jssecacerts sources — keep
```

The `verify-staging`, `validate`, and `cleanup` subcommands write timestamped reports (never overwritten) to:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/secrets-dmg/
```

The full `secrets-encrypted/` layout — the loose staging subfolders this phase consumes and cleans up (`certs/`, `chrome/`, `postman/`, `raycast/`, `extra-secrets-certs-review/`, and the rest) — is defined once in the Master Directory Reference, not redrawn here:

[[master-directory-reference|Master Directory Reference]]

> [!note]
> Active scripts stay in Git under `$FRACTOGENESIS_HOME/bin/`. Never copy script source to `$REIMAGE_ARTIFACT_ROOT`, and never store the DMG password in the repo, a note, a filename, a script, or the artifact root — only in an approved password manager.

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Artifact root for this reimage event; `secrets-encrypted/` and the DMG are written under it. |
| `REIMAGE_WORKSPACE_ROOT` | Local reusable workspace; optional home for a kept copy of the sign-off notes. |
| `FRACTOGENESIS_HOME` | Repo checkout the scripts run from (a shell/`.envrc` concern, not stored in `reimage.env`). |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do. The conceptual background is in [[#How the Workflow Works|How the Workflow Works]].

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- `reimage.env` is produced and loaded, with `REIMAGE_ARTIFACT_ROOT` resolved (from `prepare-artifact-root.md`), and the external artifact volume mounted.
- Phase 2E certificate/Keychain staging (`stage-certs-keychain.md`) and any manual app secret exports (Chrome, Postman, Raycast, licenses) are already staged under `secrets-encrypted/`.
- macOS with `hdiutil`; `python3` and the `security` CLI only if the review refresh runs. Stock Bash 3.2 is fine.

> [!bug] Troubleshooting
> If `REIMAGE_ARTIFACT_ROOT` is empty, `reimage.env` is not loaded (or the artifact root was never resolved). Source it — see [[#Load Shared Configuration|Load Shared Configuration]] — or run `prepare-artifact-root.md` first.

### Confirm Your Intent

- **Is all manual secret staging done?** Build once, after Chrome, Postman, Raycast, licenses, and Keychain exports are in place — not once per export. Adding a secret later means building again.
- **Refresh the certificate review or freeze it?** The default build reruns the Phase 2E scan to refresh the review artifacts; pass `--skip-cert-review` to leave the existing review files untouched.
- **Was a rebuild flagged?** Phase 2E writes `secrets-encrypted/extra-secrets-certs-review/state/phase2f-rerun-required-*.md` when certificate/Keychain material changed since its last run. If that marker is present — or you staged anything new after a prior DMG — this phase must run again so the newest DMG includes it. This build supersedes the marker.
- **Not cleaning up yet.** Cleanup is a separate, later step. Do not delete any loose staging until the DMG is built, mounted, and verified.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. They map to the flow: load config → confirm inputs → build → validate → clean up. Cleanup is deliberately last and gated on validation, because it deletes plaintext secrets.

### Load Shared Configuration

Source the local environment before running any command below, and re-source it after any edit to `reimage.env` in the same shell:

```bash
set -a
source ./reimage.env
set +a
```

Confirm the artifact root resolved:

```bash
printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
```

### Confirm Manual Staging Is Present

Before building, confirm the manual exports you meant to include are actually staged — the build only packages what is already there. Run:

```bash
./bin/create-secrets-dmg.sh verify-staging
```

It enumerates **every** folder under `secrets-encrypted/` and reports each as STAGED or EMPTY, flags the `cloud/` exclusion and the `phase2f-rerun-required` marker, and writes a timestamped report under `reimage-prep-checks/secrets-dmg/`. Because it reads what is actually on disk, it never drifts as the app set grows.

Act on the report: if an export you intended shows EMPTY, stage it into the matching `secrets-encrypted/<category>/` folder before building. An intentionally skipped category is fine — the report's manual checklist is where you confirm that. Anything you staged **outside** `secrets-encrypted/` (a custom app) is not visible to the script; verify it by hand.

> [!warning] Pitfall
> Do not delete any loose staged export here. Nothing is removed until after the DMG is built, mounted, and verified.

### Build the Encrypted DMG

Build the consolidated DMG. The default run first reruns the Phase 2E review scan so the certificate/Keychain review artifacts are current, then stages and encrypts every category found:

```bash
./bin/create-secrets-dmg.sh
```

To build without refreshing the Phase 2E review artifacts:

```bash
./bin/create-secrets-dmg.sh --skip-cert-review
```

To target a specific artifact root without sourcing `reimage.env` first:

```bash
./bin/create-secrets-dmg.sh --artifact-root "$REIMAGE_ARTIFACT_ROOT"
```

The script prints a staging summary, then prompts twice for an encryption password. It writes the outputs named in [[#Artifact and Script Locations|Artifact and Script Locations]]. What each category contains is in [[#What Gets Staged|What Gets Staged]].

> [!warning] Pitfall
> Save the DMG password in an approved password manager **immediately** after the build. Without it the DMG cannot be opened after the reimage, and the private keys inside (GPG especially) cannot be regenerated.

### Validate the Mounted DMG

Mount the newest DMG, check its contents, and detach — one command:

```bash
./bin/create-secrets-dmg.sh validate
```

Enter the DMG password when prompted. `validate` cross-checks **every** category staged on disk against what is actually inside the mounted image (so the check can't drift), confirms foundational GPG/SSH material, counts private-key-bearing files inside the image, checks public-PEM BEGIN/END balance, and confirms the manifest and `RESTORE-README.md` exist. It writes a PASS/WARN/FAIL report under `reimage-prep-checks/secrets-dmg/` and exits non-zero if any check FAILs.

A FAIL means a category is staged on disk but missing from the image. Do **not** clean up — move the file into the correct `secrets-encrypted/` folder and rerun [[#Build the Encrypted DMG|Build the Encrypted DMG]] so the newest DMG includes it.

Then confirm the few things a script cannot (these roll up to the Phase 4B sign-off in `reimage-prep-checks.md` and appear as the report's manual checklist):

1. The DMG password is saved in an approved password manager.
2. Every category you *intended* to export is present — only you know your intent.
3. Managed/non-exportable Keychain identities are documented, not silently missing.
4. Java trust overrides in the image match the JDKs you actually need.

> [!bug] Troubleshooting
> If `validate` cannot mount the DMG, the password is wrong or the image is damaged. Re-enter it carefully; if it still fails, rebuild.

### Clean Up Loose Plaintext After Validation

Only after `validate` passed and you saved the password, clean up. Preview first — dry-run is the default and deletes nothing:

```bash
./bin/create-secrets-dmg.sh cleanup
```

When the preview matches what you verified, execute:

```bash
./bin/create-secrets-dmg.sh cleanup --force
```

`cleanup` mounts the newest DMG and removes a loose category **only if it is confirmed present inside the image** — so `cloud/` (not backed up) and anything missing from the DMG are kept automatically, no special-casing. The DMG, its manifest, the jssecacerts inventory, `RESTORE-README.md`, and `public-certs/` are never touched, and it writes a cleanup report under `reimage-prep-checks/secrets-dmg/`. Use `--keep <category>` to preserve one you want to leave on disk (for example `--keep postman`).

> [!warning] Pitfall
> Do not move `.p12`, `.pfx`, `.jks`, `.keystore`, `*.key`, PEM exports, or Keychain identity material into `public-certs/`. Those belong only inside the encrypted DMG. Only a confirmed public-only CA certificate may be *copied* (not moved) into `public-certs/certs/` as a convenience, and only after the encrypted copy is verified.

To keep Postman while dropping everything else, run `cleanup --keep postman`; for a finer split (keep only `environments/`), keep the whole folder and prune the rest by hand. Record the outcome in the [[#Sign-Off Templates|Sign-Off Templates]] if you want a durable note.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The scripts stage, encrypt, and (on cleanup) delete; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Whether a kept certificate is public-only or secret-bearing | Only content review decides whether it may have a convenience copy in `public-certs/` or must remain only inside the DMG. |
| How aggressively to clean up loose staging | Full cleanup versus keeping intentional leftovers (e.g. Postman `environments/`) depends on what you want left on disk after validation. |
| Which license/activation exports actually need local staging | Many restore via sign-in/SSO/managed install; stage only the ones that genuinely need a local secret copy. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### What Gets Staged

The build stages and encrypts these categories when present. Each is skipped silently when its source is absent.

| Category | Source | Notes |
|---|---|---|
| `ssh/` | `~/.ssh/` | Private keys and config; permissions locked down in staging. |
| `gnupg/` | `~/.gnupg/` | Private keys in `private-keys-v1.d/` — non-regenerable. `random_seed` excluded. |
| `docker/` | `~/.docker/config.json` | Auth tokens and credential helpers. |
| `kube/` | `~/.kube/config` | Cluster API tokens and certificates. |
| `cli-credentials/`, `git/`, `package-managers/` | `~/.netrc`, `~/.git-credentials`, `~/.npmrc`, `~/.yarnrc(.yml)`, `~/.pypirc`, `~/.gradle/gradle.properties`, `~/.m2/settings.xml`, plus matching pre-staged copies (e.g. `cli-credentials/gh/`) | Byproduct secrets routed in by earlier phases are re-collected here. |
| `certs/` | `~/.keystore`, home-root `*.jks`, Desktop/Downloads cert bundles, and material staged under `secrets-encrypted/certs/` | Includes `keychain-manual-exports/`, `loose-candidates-selected/`, `project-local/`, `tool-local/`. |
| `certs/java-security/` | `jssecacerts` from `JAVA_HOME`, installed JDKs, IntelliJ bundled JBR, and prior staging | Captured broadly pre-image; restore selectively. Inventoried in `java-jssecacerts-inventory-*.md`. |
| `chrome/` | `Chrome Passwords*.csv` from `secrets-encrypted/chrome/`, Downloads, or Desktop | Manual export; delete the plaintext CSV after validation. |
| `claude/`, `intellij/`, `licenses/`, `postman/`, `raycast/`, and any future category | Whatever is pre-staged under `secrets-encrypted/<category>/` | Swept generically (see below): `claude/` (e.g. `claude_desktop_config.json`), `intellij/` (HTTP Client env files routed in by `backup-intellij` after its shared-vs-private split), `licenses/`, and app-secret exports are packaged as-is. |
| `extra-secrets-certs-review/` | `secrets-encrypted/extra-secrets-certs-review/` — `discovery/`, `plan/`, `decisions/` | Phase 2E review reports, normalized plans, and decision drafts. Staged recursively; `state/` excluded. |

Distinction to keep clear: `certs/` is certificate and keystore material in general; `certs/java-security/` is Java-specific `jssecacerts` trust overrides only.

The categories owned by the live-source captures above (`ssh/`, `gnupg/`, `docker/`, `kube/`, `certs/`, `chrome/`, `cli-credentials/`, `git/`, `package-managers/`) are staged explicitly. **Every other** subfolder already present under `secrets-encrypted/` is then swept generically and packaged as-is, so a category added by a later phase is captured without editing this script. Two things are deliberately excluded: **`cloud/` (AWS)** — cloud CLIs are re-authenticated after reimage rather than restored — and the review dir's **`state/`** control folder.

Phase 2E organizes these under by-function subfolders — `discovery/` (scan reports), `plan/` (the normalized plan, filtered feeds, and `plan/proposed-staged-certs/`), and `decisions/` (`keychain-manual-export-checklist-*.md.proposed`, `cert-restore-notes-*.md.proposed`) — alongside a `MANIFEST.md`. The full catalog is maintained in [[stage-certs-keychain#Generated Review Artifacts|Stage Certificates and Keychain → Generated Review Artifacts]]; this phase stages the whole tree recursively rather than re-listing it, so that layout can change without touching this runbook.

The `state/` subfolder is regenerable workflow control — a cross-run staging-state pointer plus the `phase2f-rerun-required-*.md` marker — and is deliberately **not** staged into the DMG; the rerun check reads that marker off the live drive, not the image, so leaving it out is safe. The public decision log `public-certs/certs/keychain-cert-export-inventory-*.md` is also left out: `public-certs/` is reference material, and only `secrets-encrypted/` rides into the encrypted image.

### Verification Reports

`verify-staging`, `validate`, and `cleanup` each write a timestamped Markdown report (never overwritten) to:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/secrets-dmg/
```

Each report has automated PASS / WARN / FAIL rows and a short "manual — you confirm" checklist for the items a script cannot judge. Between them they replace the manual manifest-grep, per-category mounted-DMG spot-checks, and PEM balance checks that used to live here: `validate` cross-checks every on-disk category against the mounted image, counts private-key-bearing files inside it, and balances public PEM blocks; `verify-staging` reports the pre-build staging surface; `cleanup` records exactly what was removed or kept.

These reports are the automated sign-off evidence for the Phase 4B pre-image checks. The fillable templates in [[#Sign-Off Templates|Sign-Off Templates]] carry only the human-judgment items.

### Expected Final Layout

After **full cleanup**, the minimal end state is:

```text
secrets-encrypted/
├── all-secrets-YYYYMMDD-HHMMSS.dmg
├── all-secrets-YYYYMMDD-HHMMSS-manifest.txt
├── java-jssecacerts-inventory-YYYYMMDD-HHMMSS.md
└── RESTORE-README.md
```

`certs/` and `extra-secrets-certs-review/` are expected to be gone after full cleanup because their contents are preserved inside the validated DMG. If you intentionally kept leftovers (for example Postman `environments/`), those specific folders may remain. `public-certs/` lives outside `secrets-encrypted/` and is kept as reference material. The complete layout is in [[master-directory-reference|Master Directory Reference]].

### Post-Image Restore Notes

Use the newest `all-secrets-*.dmg` as the primary restore source after the Mac is rebuilt, the artifact volume is reconnected, and `reimage.env` is available again. The generated `RESTORE-README.md` inside `secrets-encrypted/` carries per-category commands; the recommended order is:

1. Mount the newest consolidated DMG (`hdiutil attach "$DMG"`).
2. Restore foundation credentials first: `ssh/`, then `gnupg/`, then `docker/` and `kube/` if needed.
3. Restore certificate material only after deciding what is still required on the rebuilt machine; import `.p12`/`.pfx` through Keychain Access using the password saved in the approved password manager.
4. Restore Java `jssecacerts` only after the target JDK is installed and confirmed (`/usr/libexec/java_home -V`), then validate against an internal Maven/Gradle/HTTPS call.
5. Detach the DMG when done.

### Manual Items That Remain Manual

These still require human review or app/Keychain interaction even with the Phase 2E and 2F scripts:

| Manual item | Why it stays manual |
|---|---|
| Save the DMG password in an approved password manager | A script cannot confirm the password was stored safely. |
| Decide which Keychain items still matter and export the exportable ones | Keychain Access controls export; some items are policy-restricted or non-exportable. |
| Confirm a certificate is public-only before any `public-certs/` copy | Only content review decides whether it may leave encrypted staging. |
| Export Chrome/Postman/Raycast secrets, if needed and allowed | The apps own the export flow; Vault export may be policy-blocked. |
| Confirm exports are inside the DMG before deleting loose copies | The encrypted copy must exist before any plaintext is removed. |
| Validate internal Java TLS after restore | Only a real internal connection proves the trust material is correct. |

### Sign-Off Templates

The generated reports (see [[#Verification Reports|Verification Reports]]) carry the automated evidence. Two small fillable templates hold only what a script cannot verify — password custody and human judgment:

```text
$FRACTOGENESIS_HOME/templates/manual-export-pass-criteria-template.md
$FRACTOGENESIS_HOME/templates/loose-plaintext-cleanup-signoff-template.md
```

Create a working copy under the Phase 4B manual sign-off folder and tick the manual items after `validate` and before `cleanup --force`:

```bash
mkdir -p "$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual"
cp "$FRACTOGENESIS_HOME/templates/manual-export-pass-criteria-template.md" \
  "$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/manual-export-pass-criteria-$(date +%Y%m%d).md"
cp "$FRACTOGENESIS_HOME/templates/loose-plaintext-cleanup-signoff-template.md" \
  "$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/loose-plaintext-cleanup-signoff-$(date +%Y%m%d).md"
```

Both notes are consumed by the Phase 4B sign-off in `reimage-prep-checks.md`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections (Troubleshooting handled inline) were also removed
  from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link.
-->
