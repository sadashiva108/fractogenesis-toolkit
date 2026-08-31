[[reimaging-guide#Phase 3A — Certificate and Keychain Staging|← Back to Mac Reimaging Guide]]

# Stage Certificates and Keychain

**Last updated:** 2026-07-31

Discover, review, and stage the certificate and macOS Keychain material worth preserving — into the temporary staging folders that Phase 3C packages into the encrypted secrets DMG. Inventory broadly; stage narrowly.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Artifact Locations|Artifact Locations]]
    - [[#Workspace Layout|Workspace Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Load Shared Configuration|Load Shared Configuration]]
    - [[#Initialize the Staged-Certs Config|Initialize the Staged-Certs Config]]
    - [[#Run the Scan|Run the Scan]]
    - [[#Generate the Normalized Plan|Generate the Normalized Plan]]
    - [[#Review the Generated Artifacts|Review the Generated Artifacts]]
    - [[#Export Selected Keychain Items|Export Selected Keychain Items]]
    - [[#Stage Selected Loose Files|Stage Selected Loose Files]]
    - [[#Record Decisions and Restore Notes|Record Decisions and Restore Notes]]
    - [[#Verify Before Phase 3B|Verify Before Phase 3B]]
- [[#Decisions|Decisions]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#What to Keep and What Phase 3C Already Covers|What to Keep and What Phase 3C Already Covers]]
    - [[#Generated Review Artifacts|Generated Review Artifacts]]
    - [[#Keychain Export Password Prompts|Keychain Export Password Prompts]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

`stage-certs-keychain` (Phase 3A) decides which certificate and Keychain material survives the reimage, and puts it where Phase 3C can encrypt it. An automated scan does the inventory and the categorising; what is left for you is the judgment — what to keep, what to export by hand, and how each item comes back.

**What it sets up**

- **A reviewed staging area** — `secrets-encrypted/certs/`, holding only the loose cert, key, and truststore files you intentionally selected, split into `loose-candidates-selected/`, `project-local/`, and `tool-local/`.
- **Manual Keychain exports** — the identities that cannot be copied off disk, exported through Keychain Access into `certs/keychain-manual-exports/`, with a summary recording what succeeded and what could not be exported.
- **A review and decision record** — the discovery inventories, normalized plan, proposed fragments, and restore notes under `secrets-encrypted/extra-secrets-certs-review/`, plus the non-secret material in `public-certs/`.

**What the rest of the workflow relies on it for**

- Phase 3C encrypts everything staged here into the consolidated secrets DMG.
- The post-image restore phases read the restore notes to know how each identity comes back — reinstalled by a configuration profile, re-enrolled, or restored from the DMG.
- The Phase 6B sign-off checks the staging and export records exist.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| creating the certificate staging directories | building, validating, and cleaning up after the encrypted DMG — `create-secrets-dmg` (Phase 3C) |
| generating the certificate and Keychain review artifacts | sweeping credential-shaped files the earlier phases left loose — `stage-loose-secrets` (Phase 3B) |
| the manual Keychain Access export decisions | Java `jssecacerts` auto-capture into `secrets-encrypted/certs/java-security/` — `backup-home` (Phase 2B) |
| staging the loose cert, key, and truststore files you select | byproduct secret routing for ssh, gnupg, docker, and app exports — `backup-home` (2B), `backup-apps` (2D), `backup-repos` (2A) |
| the certificate inventory and restore notes | saved web and app passwords from the Passwords app and login keychain — `backup-apps` (2D); this phase owns certificates and identities, not passwords |

This phase can be rerun independently. Staging anything new after a DMG has been built invalidates it — rerun Phase 3B and then Phase 3C so the newest DMG contains the complete set.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. This phase is the deliberate pass for the certificate surface the other backup phases cannot reach on their own. Phases 2A–2D route credential-shaped files into `secrets-encrypted/` as a *byproduct* of backing up repos, home, and apps. Certificates and Keychain items are different: much of the material lives inside the macOS **Keychain**, which no other phase opens, and preserving it needs discovery, human review, and *manual* Keychain Access exports — not a file copy. That is why it stands alone as Phase 3A, immediately before the Phase 3C DMG build.

The intended flow:

```text
discover broadly            (scan the Keychain and the filesystem cert surface)
review and normalize        (categorize, dedupe, produce a primary plan)
stage only intentional keeps (manual Keychain exports + selected loose files)
create the encrypted DMG    (Phase 3C)
validate the mounted DMG    (Phase 3C)
clean up loose plaintext    (Phase 3C, only after validation)
```

The distinction that matters: the generated TSV and text reports are **evidence and review inputs, not automatic copy lists**. Real certificate material is staged only when one of these happens:

1. You manually export a selected Keychain certificate or identity into `secrets-encrypted/certs/keychain-manual-exports/`.
2. You add reviewed filesystem paths to the workspace `staged-certs` fragments and rerun the scan.
3. A later Phase 3C DMG run packages those staged files and review artifacts into `all-secrets-*.dmg`.

The phase is meant to be **as automated as possible**: the scan creates the folders, inventories the login and System keychains, scans the filesystem for cert-bearing file types, categorizes what it finds, and — importantly — subtracts what Phases 2B/2D already auto-capture, so what remains is a short list for human decisions. What is left for you is deciding what to keep, exporting the Keychain items that cannot be copied from disk, and staging only the chosen files. The criteria for those decisions are in [[#What to Keep and What Phase 3C Already Covers|What to Keep and What Phase 3C Already Covers]].

The entrypoint has three subcommands:

| Subcommand | Command | What it does |
|---|---|---|
| Initialize | `stage-certs-keychain.sh init-staged-certs-config` | Copies the reusable staged-certs fragments into `$REIMAGE_WORKSPACE_ROOT/staged-certs/` (first run only; skips existing files unless `--force`). |
| Scan | `stage-certs-keychain.sh scan --open` | Creates folders, inventories Keychain + filesystem cert material, writes categorized review reports, and copies any files listed in the staged-certs fragments. |
| Plan | `stage-certs-keychain.sh plan` | Cleans and normalizes the raw reports into one deduped primary plan plus `.proposed` review artifacts. Stages and deletes nothing. |

### Terminology

| Term | Meaning |
|---|---|
| Staging | Placing reviewed files, manual exports, notes, and generated review artifacts into the correct temporary backup folders so they are ready for the encrypted secrets container. It is the controlled handoff between discovery and the Phase 3C DMG — where you prepare and verify what to preserve, not where you bulk-copy every candidate. |
| DMG | A macOS disk image file. In this workflow, the Phase 3C `all-secrets-*.dmg` is the encrypted image that packages the staged secret material for restore. This phase only defines the handoff to it. |
| Loose file | A standalone cert/key/keystore/truststore file found on the filesystem, rather than an item stored inside the Keychain — and not one of the standard secret folders handled elsewhere in the workflow. |
| Evidence, not a copy list | The generated `.tsv`/`.txt` reports are review inputs. They record what exists; they do not themselves stage anything. |
| Secret-bearing | Anything that can authenticate as you or your device (private keys, `.p12`/`.pfx`, keystores). It belongs under encrypted staging. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script (entrypoint):

```text
$FRACTOGENESIS_HOME/bin/stage-certs-keychain.sh
```

Supporting helper (called by the entrypoint for staged-certs config init, normalized planning, TSV cleanup, hashing, and dedupe — do not run directly):

```text
$FRACTOGENESIS_HOME/.internal/certs/prepare-certs-keychain-staging.py
```

### Artifact Locations

Two destinations, applied consistently:

| Location | Put this here | Do not put this here |
|---|---|---|
| `$REIMAGE_ARTIFACT_ROOT/public-certs/` | Sanitized notes, inventories, decision logs, public-only convenience copies | Private keys, `.p12`, `.pfx`, `.jks`, `.keystore`, `*.key`, or unreviewed cert material |
| `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/` | Anything secret-bearing, possibly secret-bearing, local-only, or hard to recreate | Passwords written in notes, filenames, or plaintext helper docs |

License keys and activation exports are not certificate material; stage them under `secrets-encrypted/licenses/`, owned by the broader secrets workflow.

The certs staging subtree this runbook's steps create and fill (the scan creates these automatically; the full `secrets-encrypted/` layout is defined once in the Master Directory Reference, not redrawn here):

```text
$REIMAGE_ARTIFACT_ROOT/
├── public-certs/
│   └── certs/                          # keychain-detail → public export inventory
└── secrets-encrypted/
    ├── certs/
    │   ├── keychain-manual-exports/     # your manual exports + keychain-detail export summary
    │   ├── loose-candidates-selected/   # scan → staged loose selections
    │   ├── project-local/               # scan → staged project-local selections
    │   └── tool-local/                  # scan → staged tool-local selections
    └── extra-secrets-certs-review/
        ├── discovery/                   # scan → inventories + discovery reports
        ├── plan/                        # plan → normalized plan, cleaned-inputs-*/, proposed-staged-certs/
        ├── decisions/                   # plan + keychain-detail → checklist, cert restore notes
        ├── state/                       # scan → staging-state pointer + secrets-dmg-rebuild marker
        └── MANIFEST.md                  # live index, regenerated by scan/plan/keychain-detail
```

Which subcommand writes where:

| Subcommand | Artifacts and destination |
|---|---|
| `scan` | Inventories → `extra-secrets-certs-review/discovery/`; staging-state pointer and `secrets-dmg-rebuild-required` marker → `.../state/`; copies your configured selections into `secrets-encrypted/certs/{loose-candidates-selected,project-local,tool-local}/`. |
| `plan` | Normalized plan, `cleaned-inputs-*/`, and `proposed-staged-certs/` → `extra-secrets-certs-review/plan/`; its proposed checklist and cert restore notes → `.../decisions/`. |
| `keychain-detail` | Checklist → `.../decisions/`; export summary → `secrets-encrypted/certs/keychain-manual-exports/`; public inventory → `public-certs/certs/`. |
| any of the above | Rewrites `extra-secrets-certs-review/MANIFEST.md` as a live index of the folder. |

The complete `secrets-encrypted/` layout — including `certs/java-security/` (populated by `backup-home.md` / Phase 3C, not here) and the sibling app-secret folders — lives in:

[[master-directory-reference|Master Directory Reference]]

> [!bug] Troubleshooting
> If the scan is unavailable and you need the folders now, create them by hand:
> ```bash
> mkdir -p \
>   "$REIMAGE_ARTIFACT_ROOT/public-certs/certs" \
>   "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/keychain-manual-exports" \
>   "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/loose-candidates-selected" \
>   "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/project-local" \
>   "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/tool-local" \
>   "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/extra-secrets-certs-review"/{discovery,plan,decisions,state}
> ```

### Workspace Layout

Your reviewed selections live under `$REIMAGE_WORKSPACE_ROOT` so they survive between reimages and reruns, outside both the repo and the external artifact root:

```text
$REIMAGE_WORKSPACE_ROOT/staged-certs/
├── loose-candidates-selected.conf.sh
├── project-local.conf.sh
└── tool-local.conf.sh
```

The committed defaults these are copied from live at `$FRACTOGENESIS_HOME/.internal/templates/staged-certs/`. The scan sources the workspace fragments directly every run (falling back to the committed templates when the workspace copy is absent); only the real files they point to are copied into `secrets-encrypted/certs/`. Nothing is copied back to the artifact root, so there is no generated copy to overwrite.

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Artifact root for this reimage event; `public-certs/` and `secrets-encrypted/` are written under it. |
| `REIMAGE_WORKSPACE_ROOT` | Local reusable workspace holding your `staged-certs/` selection fragments. |
| `FRACTOGENESIS_HOME` | Repo checkout the scripts run from (a shell/`.envrc` concern, not stored in `reimage.env`). |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- `reimage.env` is produced and loaded, with `REIMAGE_ARTIFACT_ROOT` and `REIMAGE_WORKSPACE_ROOT` resolved (from `prepare-artifact-root.md`).
- macOS with Keychain Access and the `security` CLI available; `python3` for the planning helper. Stock Bash 3.2 is fine.

> [!bug] Troubleshooting
> If `REIMAGE_ARTIFACT_ROOT` is empty, `reimage.env` is not loaded, or the artifact root was never resolved. The first step below sources it; if that does not resolve it, run `prepare-artifact-root.md` first.

### Confirm Your Intent

- **First run or reused workspace?** On a first run or a new workspace, initialize the staged-certs fragments; if `$REIMAGE_WORKSPACE_ROOT/staged-certs/` already holds reviewed fragments from a prior reimage, skip init and edit them in place.
- **Do you have Keychain items to export this run?** The scan and plan are safe to run repeatedly; manual exports are the part that needs your attention at the keyboard.
- **Scan, then plan.** Always run `scan` before `plan` so the plan normalizes fresh reports. Rerun both after any manual export or fragment edit.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. Steps map to the script's phases — prepare (load config, initialize) → execute (scan, plan, export, stage) → verify — and any file you add later means rerunning `scan` then `plan` so the latest review state is on disk before Phase 3C.

### Load Shared Configuration

Source the local environment before running any command below, and re-source it after any edit to `reimage.env` in the same shell:

```bash
set -a
source ./reimage.env
set +a
```

Confirm the paths resolved:

```bash
printf 'REIMAGE_ARTIFACT_ROOT=%s\n' "$REIMAGE_ARTIFACT_ROOT"
printf 'REIMAGE_WORKSPACE_ROOT=%s\n' "${REIMAGE_WORKSPACE_ROOT:-}"
```

### Initialize the Staged-Certs Config

First run or new workspace only — copy the reusable fragments into your workspace:

```bash
./bin/stage-certs-keychain.sh init-staged-certs-config
```

This writes `loose-candidates-selected.conf.sh`, `project-local.conf.sh`, and `tool-local.conf.sh` into `$REIMAGE_WORKSPACE_ROOT/staged-certs/`.

> [!note]
> Init skips files that already exist and will not overwrite reviewed selections unless you pass `--force`. If the workspace fragments are already there from a prior reimage, skip this step — the staging step later edits them in place.

### Run the Scan

Inventory the Keychain and filesystem cert surface, and write the review reports:

```bash
./bin/stage-certs-keychain.sh scan --open
```

The scan creates the staging folders, captures certificate and identity inventories from the **login** (`~/Library/Keychains/login.keychain-db`) and **System** (`/Library/Keychains/System.keychain`) keychains, scans the filesystem for public certs, private keys, PKCS#12 bundles, Java keystores/truststores, `cacerts`, and `jssecacerts`, categorizes what it finds, filters out what Phase 3C already auto-captures, and copies any files listed in your staged-certs fragments. It writes categorized reports under `secrets-encrypted/extra-secrets-certs-review/`.

> [!note]
> The scan does not export Keychain items, decide what to keep, build the DMG, or delete anything. Those are your calls (export, stage) or Phase 3C's (DMG, cleanup).

### Generate the Normalized Plan

Turn the raw reports into one deduped working queue:

```bash
./bin/stage-certs-keychain.sh plan
```

The plan (via `prepare-certs-keychain-staging.py`) cleans malformed TSV rows, normalizes the Keychain, filesystem, Java-truststore, and gitignored-candidate feeds into one table, dedupes by identity fingerprint / file path / file hash, marks primary versus duplicate rows, and writes a primary-only plan plus `.proposed` review artifacts (a manual-export checklist, cert restore notes, and a proposed project-local fragment). It stages and deletes nothing.

Use `cert-keychain-normalized-plan-primary-*.tsv` as your working queue — a review plan, not an approval list. The full output catalog is in [[#Generated Review Artifacts|Generated Review Artifacts]].

### Review the Generated Artifacts

Treat every file under `extra-secrets-certs-review/` as a review clue, not a bulk-copy list. Start with the highest-signal reports:

| Start here | Why |
|---|---|
| `all-cert-keychain-discovery-*.tsv` | Master inventory of discovered Keychain + filesystem cert material, with category/type and recommendation columns. |
| `staging-candidates-*.tsv` | Opinionated shortlist of items more likely to need review, export, or staging. |
| `cert-keychain-normalized-plan-primary-*.tsv` | The cleaned, deduped working queue (after `plan`). |
| `staging-category-rules-*.md` | What the recommendation labels mean — read once, then use while scanning the TSVs. |

Decide, per row, using What to Keep and What Phase 3C Already Covers. Keychain items you decide to keep go to Export Selected Keychain Items; filesystem paths you decide to keep go to Stage Selected Loose Files. The complete catalog of generated files is in Generated Review Artifacts.

### Export Selected Keychain Items

Only Keychain items you intentionally keep **and can actually export** need a manual export. Most corporate identities on a managed Mac are non-exportable and re-provision automatically after reimage — so export is the exception, and "document + re-enroll" is the common outcome.

**1. Triage before touching anything.** From the plan's identity catalog (`keychain-identity-catalog-*.tsv`) and the checklist, split identities into *client identities you actively use and that look self-issued/exportable* (candidate EXPORT) versus *managed/MDM/SCEP identities* (DOCUMENT). When unsure, treat it as DOCUMENT until step 5 tells you otherwise.

**2. Attempt the export.** Open Keychain Access (`open -a "Keychain Access"`) and select the identity — the row with the ▸ triangle, meaning cert plus private key — then `File > Export Items`. Save **only** under `secrets-encrypted/certs/keychain-manual-exports/`, using generic names (no usernames, hostnames, serials, asset IDs, or internal domains):

```text
internal-root-ca-YYYYMMDD.cer
internal-issuing-ca-YYYYMMDD.cer
user-public-certificates-YYYYMMDD-HHMMSS.pem
selected-exportable-client-identity-YYYYMMDD.p12
mdm-or-device-public-cert-YYYYMMDD.cer
```

Use `.cer`/`.pem` for public certificate material only, and `.p12`/`.pfx` for a cert plus private key only if export is allowed and needed.

> [!warning] Pitfall
> If macOS asks for a `.p12`/`.pfx` export password, create a strong one and store it **only** in the approved password manager. Never paste it into this file, a note, a script, a filename, `public-certs/`, `secrets-encrypted/`, OneDrive, iCloud, email, or a repo. Record only the entry name: `Export password stored in approved password manager entry: TODO_ENTRY_NAME`. Which prompt is which is in [[#Keychain Export Password Prompts|Keychain Export Password Prompts]].

**3. If the export succeeds.** Confirm the file landed under `keychain-manual-exports/`, set the identity's block in the checklist to `Status: EXPORT`, fill `Export target` and (for a `.p12`) the password-manager entry **name**, and move on.

**4. If the export fails.** A failure like **"Unable to export an item. The contents of this item cannot be retrieved."** means the private key is non-exportable — managed, policy-protected, or generated on-device by SCEP. This is expected for corporate identities.

> [!bug] Troubleshooting
> A dimmed Export item, or "Unable to export," is the same signal: the key cannot leave the device. Do not try to bypass it. Set the identity to `Status: DOCUMENT`, `Exportable: No`, record the exact error and date under `Export attempt`, and continue to step 5 to capture the restore path.

**5. Trace how the certificate is delivered (this fills the restore fields).** A non-exportable identity is installed by a configuration profile, and that profile tells you how it comes back. The full reference — payload types, Intune-native vs internal-PKI, and a restore decision tree — is in [[certificate-types-guide#Managed Identity Decision Tree|Certificate Types Guide → Managed Identity Decision Tree]].

- GUI: System Settings → General → **Device Management**. Open each profile and read its payloads. Match a profile to your identity by **Subject/CN + Issuer + Expiry** against the Keychain item.
- Read the payload type: a **Trusted/CA certificate** payload installs a CA for trust; a **SCEP Enrollment** payload shows the enrollment **server URL** and issuer (the device generates the key locally, so it is non-exportable); a **PKCS/Credential** payload is connector-delivered.
- A profile signed by `*.manage.microsoft.com` is delivered through **Microsoft Intune**.
- CLI — check **both** levels, because user certs and device certs live in different scopes:

```bash
profiles status -type enrollment
profiles show
sudo profiles show
```

The first says whether the Mac is MDM/DEP enrolled. The second lists **user**-level
profiles, which is where your own client certificates live. The third, under
`sudo`, lists **computer**-level profiles — the device and agent certificates. The
two scopes hold different material, which is why both are here.

Then search for your issuer or subject, e.g. `grep -i -B2 -A6 'scep\|<issuer-CA-name>\|<cert-CN>'`. Note that `profiles show` lists payload *types and identifiers* but not the SCEP server URL — read the URL from the profile in the Device Management GUI.

- Decide the restore source: in an Intune-signed profile → re-enroll via Intune (note if the SCEP server is an **internal** host — reissue needs the corporate network/VPN); an internal-only CA with no matching profile → corporate PKI/IT; a native Intune device/agent identity → re-provisions automatically on re-enrollment.

**6. Record each decision.** Run `./bin/stage-certs-keychain.sh keychain-detail` to generate the checklist, export summary, and public inventory in one pass — all pre-filled from your Keychain and profiles, and accurate to the real export state (it scans the exports dir). Then confirm each block by hand — fill the flagged `Enrollment server`, record any export failure, and tick the sign-off.

> [!warning] Pitfall
> Internal hostnames (for example a SCEP/NDES server) belong only in this checklist and the export summary — both live under `secrets-encrypted/` and ride into the encrypted DMG. Keep them **out** of the public `public-certs/` export inventory; describe the source generically there.

### Stage Selected Loose Files

For filesystem items you keep, list their absolute paths in the matching workspace fragment; the next scan copies the real files into `secrets-encrypted/certs/`. Each fragment maps to one destination so staged material stays easy to audit:

| Fragment | Use for |
|---|---|
| `loose-candidates-selected.conf.sh` | Reviewed loose files that are not project-local or tool-local. |
| `project-local.conf.sh` | Local-only certs, truststores, or key bundles tied to a specific project or repo workspace. |
| `tool-local.conf.sh` | Local tool, proxy, SDK, or CLI certificate material not already auto-captured by Phase 3C. |

Open and edit the active workspace copy:

```bash
open "$REIMAGE_WORKSPACE_ROOT/staged-certs/loose-candidates-selected.conf.sh"
```

Example fragment shape (absolute paths only):

```bash
STAGED_CERTS_PROJECT_LOCAL=(
  "$HOME/Development/example-project/local-dev-certs/dev-client-cert.pem"
)
```

If `plan` produced a proposed fragment, review it before copying approved entries into the active fragment — the `.proposed` file is a review artifact, never sourced directly:

```bash
open "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/extra-secrets-certs-review/plan/proposed-staged-certs/project-local.conf.sh.proposed"
```

Once the fragments reflect what you want, rerun the scan (which copies the configured paths) and the plan (which refreshes the review state):

```bash
./bin/stage-certs-keychain.sh scan
./bin/stage-certs-keychain.sh plan
```

Then confirm in `configured-staged-files-*.tsv` that the configured paths were copied and not reported missing.

> [!warning] Pitfall
> Do not list items Phase 3C already auto-captures — `~/.keystore`, home-root `*.jks`, Desktop/Downloads cert bundles, JDK/IntelliJ JBR `jssecacerts`, or ssh/gnupg/docker/kube/Chrome/IntelliJ-HTTP/Postman/Raycast secret material. Re-listing them duplicates staging work. See [[#What to Keep and What Phase 3C Already Covers|What to Keep and What Phase 3C Already Covers]].

### Record Decisions and Restore Notes

`keychain-detail` writes all three records from one classification, so they stay consistent and reflect the real export state (it scans the exports dir). Re-run it after any manual export so the counts update:

```bash
./bin/stage-certs-keychain.sh keychain-detail
```

That emits, each timestamped:

- `extra-secrets-certs-review/decisions/keychain-manual-export-checklist-*.md.proposed` — the per-identity working record (rides into the encrypted DMG).
- `secrets-encrypted/certs/keychain-manual-exports/keychain-export-summary-*.md` — the export-result summary, kept *with* the staged exports.
- `public-certs/certs/keychain-cert-export-inventory-*.md` — the generic, hostname-free public decision log, readable without unlocking the DMG.

Then confirm by hand — the helper fills what it can and leaves the rest for you:

- Set each identity's `Enrollment server` in the checklist (the helper flags it; read the SCEP URL from Device Management — see [[#Export Selected Keychain Items|step 5]]).
- If you attempted an export that failed, record the exact error under `Export attempt` in the checklist and tick "Private-key export failure documented" in the summary.
- Tick the remaining sign-off boxes once each view is reviewed.

> [!warning] Pitfall
> Keep internal hostnames (a SCEP/NDES server) out of the **public** inventory — the helper already omits them; do not paste them back in. Hostnames belong only in the checklist and summary under `secrets-encrypted/`, which ride into the encrypted DMG.

### Verify Before Phase 3B

List what is staged and confirm it is all intentional:

```bash
find "$REIMAGE_ARTIFACT_ROOT/public-certs" -maxdepth 3 -type f -print 2>/dev/null | sort || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs" -maxdepth 5 -type f -print 2>/dev/null | sort || true
find "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/extra-secrets-certs-review" -maxdepth 3 -type f -print 2>/dev/null | sort || true
```

Before you consider this phase complete, confirm by hand — these roll up to the Phase 6B sign-off in `reimage-prep-checks.md`:

1. `keychain-manual-exports/` contains only intentional exports.
2. `loose-candidates-selected/`, `project-local/`, and `tool-local/` contain only intentional keeps.
3. Notes explain any non-exportable or managed identities.
4. The latest normalized primary plan was reviewed, or the plan was intentionally skipped with a reason.
5. If `secrets-dmg-rebuild-required-*.md` exists under `extra-secrets-certs-review/state/`, or you staged anything new after a prior DMG build, Phase 3B and then Phase 3C must run again.

Then hand off to Phase 3B:

```bash
./bin/stage-loose-secrets.sh
```

Phase 3B sweeps the whole artifact root for credential-shaped files that this phase and the Phase 2 backups left outside `secrets-encrypted/`, and moves them inside it. Cert staging can leave candidates of its own behind, which is why the sweep runs after this phase rather than before it.

Phase 3C then builds a new `all-secrets-*.dmg`, mounts it, and confirms the staged certificate and Keychain material is inside before any loose plaintext staging is removed.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The scripts inventory, categorize, and stage; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Whether a kept file is really a secret | Only content review decides whether an item must live under encrypted staging rather than `public-certs/`. |
| Whether to export a managed/corporate identity or rely on re-enrollment | The private key is often intentionally non-exportable; the right path depends on IT policy, not the file. |
| Whether a local trust override is still needed | Keeping a `jssecacerts`/truststore override is worth it only if it is local-only and still required. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow. For the underlying certificate concepts — types, chains, formats, truststores vs keystores, and how managed/Intune identities are delivered, inspected, and traced — see [[certificate-types-guide|Certificate Types Guide]].

### What to Keep and What Phase 3C Already Covers

This phase is inventory-first: inventory broadly, stage narrowly, and preserve only what is local-only, secret-bearing, or hard to recreate. Exclude anything Phase 3C already auto-captures in the consolidated secrets DMG.

| Already handled by Phase 3C | Typical examples |
|---|---|
| SSH, GPG, Docker, and kube secrets | `~/.ssh/`, `~/.gnupg/`, `~/.docker/config.json`, `~/.kube/config` |
| Home-root Java keystores | `~/.keystore`, home-root `*.jks` |
| Auto-discovered Java trust overrides | JDK/JBR `jssecacerts` from `JAVA_HOME`, installed JDKs, or IntelliJ JBR |
| Keychain reports and manual exports | `extra-secrets-certs-review/`, `certs/keychain-manual-exports/` |
| Desktop/Downloads cert bundles | `*.pem`, `*.p12`, `*.pfx`, `*.cer`, `*.crt`, `*.keystore`, `*.jks` already found there |
| Other secret-bearing local config | Chrome password CSV, IntelliJ HTTP client env files, Postman/Raycast exports, package-manager and cloud credential configs |

Quick decision guide:

| Item type | Default action | Stage where | Why |
|---|---|---|---|
| Internal root/issuing CA that may restore internal TLS trust | Export public `.cer`/`.pem` if useful | `keychain-manual-exports/` or document only | Useful restore evidence even without a private key |
| Keychain identity under **My Certificates** or an exportable `.p12`/`.pfx` | Export only if needed | `keychain-manual-exports/` | May be required for VPN, client auth, or device identity |
| Private key, `.p12`, `.pfx`, `.jks`, `.keystore`, `*.key` outside Keychain | Stage only if intentionally preserved | `loose-candidates-selected/`, `project-local/`, or `tool-local/` | Secret-bearing or difficult to recreate |
| `jssecacerts` under `JAVA_HOME`, installed JDKs, or IntelliJ JBR | Do not re-stage | Phase 3C auto-captures it | Avoid duplicate staging |
| Local trust override not covered by Phase 3C | Stage only if intentionally preserved | `loose-candidates-selected/`, `project-local/`, or `tool-local/` | Keep only if local-only and still required |
| Managed or non-exportable corporate identity | Document it; expect re-enrollment | Notes plus optional public cert export | Private key is often intentionally non-exportable |
| Stock `cacerts`, app-bundle certs, browser bundles, virtualenv `certifi/cacert.pem`, IDE/cache certs | Usually skip | Do not stage | Regenerated by reinstalling tools |

Important rules: compare by SHA-256 fingerprint (duplicate display names are common — dedupe only on a fingerprint match); treat any identity material as secret-bearing; use placeholders for names/domains/serials/hostnames in reusable notes; and never store export passwords in notes — they belong only in the approved password manager.

### Generated Review Artifacts

What the scan and plan write under `secrets-encrypted/extra-secrets-certs-review/` (and the certs staging folders). Each lands in a `discovery/`, `plan/`, `decisions/`, or `state/` subfolder — see [[#Artifact Locations|Artifact Locations]] for the routing. All are review inputs unless noted.

| Artifact | What it tells you | Default action |
|---|---|---|
| `all-cert-keychain-discovery-*.tsv` | Consolidated inventory of Keychain certs, Keychain identities, and filesystem cert material with category/type and recommendation | Master inventory |
| `staging-candidates-*.tsv` | Opinionated shortlist more likely to need review, export, or staging | Raw candidate source |
| `cert-keychain-normalized-plan-primary-*.tsv` | Cleaned, deduped working queue from Keychain/filesystem/Java/gitignored inputs | Primary working queue (after `plan`) |
| `cert-keychain-normalized-plan-summary-*.md` | Summary of cleaned inputs, dropped rows, dedupe results, source-feed counts, and derived artifacts | Review before editing fragments |
| `plan/proposed-staged-certs/project-local.conf.sh.proposed` | Proposed project-local fragment from refined gitignored cert/key candidates | Review; copy approved entries into the active fragment (never source the `.proposed`) |
| `keychain-manual-export-checklist-*.md.proposed` | Worklist generated from deduped primary Keychain identity rows | Fill in during export; keep as proposed until reviewed |
| `cert-restore-notes-*.md.proposed` | Draft restore guidance from primary plan rows | Edit into final notes after plan review and Phase 3C validation |
| `out-of-cert-scope-secret-material-*.tsv` | Secret-bearing env/config files that are not certificate material | Cross-reference with Phase 3C; do not copy into cert staging by default |
| `gitignored-secret-generated-noise-filtered-*.tsv` | Raw gitignored matches filtered as noise (`__pycache__`, `.pyc`, venv, `pyvenv.cfg`) | Keep as evidence; do not stage |
| `staging-category-rules-*.md` | Meaning of labels (`inventory-only`, `manual-export-if-needed`, `review-public-cert`, `captured-by-secrets-dmg`, `stage-if-needed`) | Read once |
| `configured-staged-files-*.tsv` | Which configured fragment paths were copied or missing | Confirm configured selections were staged |
| `keychain-certificate-catalog-*.tsv` / `keychain-identity-catalog-*.tsv` | Keychain certificate and identity entries with classification/recommendations | Review identities first for private-key-backed items |
| `filesystem-cert-material-*.tsv` / `cert-key-file-candidates-*.tsv` | Filesystem-discovered cert/key/keystore/truststore material, cache/cloud/git paths pruned | Decide what to copy and where |
| `keychain-certificate-inventory-*.txt` | PEM-style **public** certificate content from login/System keychains (from `security find-certificate -a -p`) | Keep as evidence — public data, not staged keys |
| `keychain-identities-*.txt` | Private-key-backed identities (code-signing, SSL-client) | Keep as evidence; review closely |
| `java-truststore-candidates-*.txt` | JDK/app-bundle/home truststore candidates such as `jssecacerts` | Review for local trust overrides |
| `credential-file-candidates-*.tsv` | Credential-bearing config still relevant after Phase 3C auto-captures are filtered; may be empty | Review only if rows remain |

### Keychain Export Password Prompts

Three different prompts can appear during export; they are not the same:

| Prompt | What it means | What to do |
|---|---|---|
| macOS login/admin password | Permission to access or export the item | Enter it only if expected; do not record it |
| New export password for `.p12`/`.pfx` | You are creating the password needed to import the identity later | Generate a strong one; save it only in the approved password manager; record only the entry name or a non-secret hint |
| Existing `.p12` inspection/import password | The file is already password-protected | Use the approved password manager or source owner; if unknown, record that inspection/import could not be completed |

Safe reminder format for any note:

```text
Export password stored in approved password manager entry: TODO_ENTRY_NAME
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---
