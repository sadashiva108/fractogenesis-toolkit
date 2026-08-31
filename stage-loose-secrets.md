[[reimaging-guide#Phase 3B — Stage Loose Secrets|← Back to Mac Reimaging Guide]]

# Stage Loose Secrets

**Last updated:** 2026-08-16

This runbook sweeps credential-shaped files that earlier phases left sitting in plaintext under `$REIMAGE_ARTIFACT_ROOT`, and moves them across the encryption boundary into `secrets-encrypted/` before Phase 3C builds the DMG.

It is the last gate before packaging. Everything staged deliberately by Phases 2A through 3A is already inside `secrets-encrypted/`; this phase exists for everything that got there by accident.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#Why a Loose Secret Survives Everything Else|Why a Loose Secret Survives Everything Else]]
    - [[#What Counts as Credential-Shaped|What Counts as Credential-Shaped]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Find What Is Loose|Step 1 — Find What Is Loose]]
    - [[#Step 2 — Review the Proposed Moves|Step 2 — Review the Proposed Moves]]
    - [[#Step 3 — Stage Them|Step 3 — Stage Them]]
    - [[#Step 4 — Confirm the Tree Is Clean|Step 4 — Confirm the Tree Is Clean]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
    - [[#A Candidate Is Not Actually a Secret|A Candidate Is Not Actually a Secret]]
    - [[#A File Is Already Staged and the Source Remains|A File Is Already Staged and the Source Remains]]
    - [[#The Same Finding Keeps Coming Back|The Same Finding Keeps Coming Back]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Identify What a File Actually Is|Identify What a File Actually Is]]
    - [[#Stage Something by Hand|Stage Something by Hand]]
    - [[#Reading the Rolling Reports|Reading the Rolling Reports]]
    - [[#Add a Shape the Floor Does Not Cover|Add a Shape the Floor Does Not Cover]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

`stage-loose-secrets` (Phase 3B) sweeps the artifact root for credential-shaped files sitting outside `secrets-encrypted/` and moves them inside it, so the Phase 3C DMG encrypts material that would otherwise leave on the drive in the clear.

**What it sets up**

- **A swept artifact tree** — no credential-shaped filename anywhere under `$REIMAGE_ARTIFACT_ROOT` except inside `secrets-encrypted/`.
- **A provenance manifest** — `secrets-encrypted/staged-loose/MANIFEST.tsv`, recording where each swept file came from so a restore phase can put it back.
- **A rolling findings record** — `loose-secrets-reports/`, carrying each candidate across runs with the run it was first seen in and how many checks it has survived.

**What the rest of the workflow relies on it for**

- Phase 3C encrypts `secrets-encrypted/` and nothing else; this phase is what guarantees there is nothing left worth encrypting outside it.
- The Phase 6B readiness sign-off assumes the encryption boundary already holds.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| finding credential-shaped files anywhere under the artifact root | deliberate secret targets and their destinations — `backup-home` (Phase 2B) |
| moving them into `secrets-encrypted/staged-loose/` with provenance preserved | certificate and Keychain review and staging — `stage-certs-keychain` (Phase 3A) |
| the `SECRET_SHAPES` floor and the optional `secret-shapes.conf.sh` extension | building, validating, and cleaning up after the DMG — `create-secrets-dmg` (Phase 3C) |
| the `loose-secrets-reports/` rolling record | gitignored-file staging from repositories — `backup-repos` (Phase 2A) |

This phase is safe to re-run at any time and is idempotent — a file already staged is reported and left alone rather than moved twice.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Two scripts do the work and they deliberately split responsibility: `report-loose-secrets.sh` reports and never writes to what it scans, `stage-loose-secrets.sh` acts and is dry-run by default. Both read the same shape list from shared config, so they cannot disagree about what a credential looks like.

The sweep works on the *destination* — the artifact root — rather than filtering at each source. That is what makes it phase-agnostic: material left behind by Phase 2A, 2B, 2D, or 3A is caught by one pass, and no artifact-config exclude list has to change to make it work.

### Why a Loose Secret Survives Everything Else

Phase 3C encrypts exactly one directory: `secrets-encrypted/`. Its cleanup step removes plaintext from exactly that same directory.

A credential-shaped file that landed anywhere else — `home-files-backup/`, `app-settings-backup/`, `staged-ignored-files/` — is untouched by both. It is not encrypted, it is not cleaned up, and it leaves with the drive in the clear. Nothing later in the workflow looks for it.

> [!note]
> This is a placement problem, not a copying bug. The file was backed up correctly. It was backed up to the wrong side of the encryption boundary.

### What Counts as Credential-Shaped

Matching is by **filename only** — contents are never read. The list lives in one place, `SECRET_SHAPES_FLOOR` in `.internal/artifact-config.sh`, and the optional `secret-shapes.conf.sh` fragment can add to it but never remove from it.

For what makes a good shape, when to prefer a `SECRETS_TARGETS` row over a shape, and candidate shapes worth adding, see [[artifact-config-reference|Artifact Config Reference]] — Secret Shapes.

> [!warning] Pitfall
> A clean run means "no obvious leak", not "no leak". A secret in a file with an innocent name will not appear at all. Filename shape is a net with known holes, not a proof.

Public certificate formats — `.cer`, `.crt`, `.der` — are deliberately *not* shapes. They carry no private key, and including them would flag every trusted root on the drive. `.p12` and `.pfx` are shapes, because PKCS#12 bundles a private key by definition.

Being aggressive about shapes is safe here precisely because a match is *staged*, not deleted. The cost of a false positive is that a file rides inside the encrypted DMG instead of the plaintext backup.

### Terminology

| Term | Meaning |
|---|---|
| Loose secret | A credential-shaped file under the artifact root but outside `secrets-encrypted/`. |
| Encryption boundary | The edge of `secrets-encrypted/`. Inside it, Phase 3C encrypts; outside it, nothing does. |
| Shape | A filename glob such as `*.p12` or `.netrc`. Never a path, never file contents. |
| Staging | Moving a loose secret into `secrets-encrypted/staged-loose/`, keeping its original relative path. |
| OUTSIDE / INSIDE / STAGED | The three states `report-loose-secrets.sh` reports. See [[#Reading the Rolling Reports\|Reading the Rolling Reports]]. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

```text
$FRACTOGENESIS_HOME/bin/report-loose-secrets.sh    # entrypoint — reports, never writes to what it scans
$FRACTOGENESIS_HOME/bin/stage-loose-secrets.sh    # entrypoint — moves, dry-run by default
$FRACTOGENESIS_HOME/.internal/artifact-config.sh  # SECRET_SHAPES_FLOOR and the predicate builder
```

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/staged-loose/
├── MANIFEST.tsv                       # when, source path, staged path
└── <original-relative-path>           # e.g. home-files-backup/proj/id_rsa

$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports/
├── open-findings.md                   # what is still unresolved, and for how many runs
├── findings-ledger.tsv                # authoritative state behind open-findings.md
├── MANIFEST.md                        # append-only index of completed checks
├── latest-run.txt
└── runs/<context>-YYYYMMDD-HHMMSS/
    ├── loose-secrets-report.txt
    └── findings.tsv
```

The complete artifact-root layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Environment Variables

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | The artifact root to sweep. Overridable per run with `--artifact-root`. |
| `SECRET_SHAPES` | The effective shape list — floor plus fragment extras. Composed by shared config; not set by hand. |
| `ARTIFACT_CONFIG_DIR` | The active artifact-config fragment directory, when `secret-shapes.conf.sh` is being used. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

### Prerequisites

Command examples assume the repository root as the working directory.

```text
Phase 3A is complete — certificate and Keychain staging has already run
$REIMAGE_ARTIFACT_ROOT is set and the external volume is mounted
Phase 3C has NOT yet built the DMG for this pass
```

> [!note]
> Run this after Phase 3A, not before. Cert staging writes into `secrets-encrypted/` and can itself leave candidates behind; sweeping first would just mean sweeping again.

### Confirm Your Intent

This phase moves files. It does not copy them, and it does not delete them. Before running `--apply`, be clear that you are changing where backed-up material lives — a file staged from `home-files-backup/proj/id_rsa` is no longer at that path, it is at `secrets-encrypted/staged-loose/home-files-backup/proj/id_rsa`, and the restore path for it is the DMG rather than the plaintext tree.

That is the intended outcome. `MANIFEST.tsv` is what makes it reversible.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

### Step 1 — Find What Is Loose

```bash
./bin/report-loose-secrets.sh --context pre-image-stage-loose-secrets
```

Read the `OUTSIDE` list. That is the finding that matters: credential-shaped files that Phase 3C will never encrypt.

> [!note]
> A `STAGED` count is expected here and is not a finding. No DMG exists yet, so payload inside `secrets-encrypted/` is exactly what staging means. It is listed with `--verbose`, never counted, and never affects the exit status.

Exit `0` means nothing is loose and you can go straight to Phase 3C. Exit `1` means there are candidates; continue.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Review the Proposed Moves

```bash
./bin/stage-loose-secrets.sh
```

Without `--apply` this writes nothing. It prints one `WOULD` line per file, showing the artifact-root-relative path that will be preserved under `staged-loose/`.

Read the list before staging it. The question to ask about each row is not *is this a secret* — a false positive is cheap — but *does a restore path expect to find this at its original location*. If one does, note it now; the manifest records the move, but you are the one who knows the restore expectation.

> [!warning] Pitfall
> `settings.xml` and `gradle.properties` are shapes because they routinely hold server passwords and signing keys. If yours do not, they will still be staged. That is not a malfunction — see [[#A Candidate Is Not Actually a Secret|A Candidate Is Not Actually a Secret]] for the `--keep` route.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Stage Them

```bash
./bin/stage-loose-secrets.sh --apply
```

Each file is moved into `secrets-encrypted/staged-loose/` with its original relative path, `chmod 600`, and appended to `MANIFEST.tsv`.

Nothing is ever overwritten. A destination that already exists is reported as `EXISTS` and the source is left where it is — see [[#A File Is Already Staged and the Source Remains|A File Is Already Staged and the Source Remains]].

> [!warning] Pitfall
> Staging by hand with `cp` instead of letting this script `mv` leaves the plaintext original exactly where it was. You then have the secret in two places, one of them unencrypted, and the check still reports it.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Confirm the Tree Is Clean

```bash
./bin/report-loose-secrets.sh --context pre-image-stage-loose-secrets-after
```

`OUTSIDE` must be `0` before Phase 3C. A nonzero count here means something was kept, collided, or failed to move — resolve it now rather than at the sign-off, because once the DMG is built the plaintext you missed is still plaintext.

Then continue to Phase 3C:

[[create-secrets-dmg|Create Secrets DMG]]

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The scripts match shapes and move files; these judgment calls stay with you.

| Decision | Why it is yours |
|---|---|
| Whether a staged file breaks a restore expectation | Only you know which post-image step reaches for that path. |
| Whether to `--keep` a candidate in place | Requires knowing the file's contents, which the scripts never read. |
| Whether a persistent finding is accepted or deferred | The record cannot tell a decision from an oversight. |
| Whether a new shape belongs in the shared fragment | A shape added here changes what every future run sweeps. |

Record a "not a secret, leaving it" decision here in this table when you make one. The alternative is re-triaging the same row at every sign-off.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

[[#Table of Contents|⬆ Back to Table of Contents]]

### A Candidate Is Not Actually a Secret

A public certificate, a template with placeholder values, an empty file, or a sample committed to a repository will still match on filename.

Leaving it staged is usually the cheaper outcome — it rides in the DMG and nothing is lost. If you specifically need it to stay in the plaintext tree, keep it in place:

```bash
./bin/stage-loose-secrets.sh --apply --keep 'public-certs/*'
```

`--keep` is repeatable and matches the artifact-root-relative path shown in the output. Note that `report-loose-secrets.sh` will keep reporting it — that is the intended trade, and the reason to record the decision in [[#Decisions|Decisions]].

### A File Is Already Staged and the Source Remains

`EXISTS` means a re-run of an earlier phase recreated a file you already staged. The script refuses to overwrite, so the plaintext source is still on the drive.

Compare them, then remove whichever is redundant:

```bash
diff "$REIMAGE_ARTIFACT_ROOT/<path>" \
     "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/staged-loose/<path>"
```

Identical: delete the plaintext source. Source is newer: delete the staged copy and re-run `--apply`. Until one of them is gone, `report-loose-secrets.sh` keeps reporting it, and it is right to.

### The Same Finding Keeps Coming Back

`open-findings.md` tracks how many checks each candidate has survived and marks anything at three or more with a ⚠.

A persistent row means one of two things, and they need opposite responses. Either you decided it is not a secret and moved on — correct outcome, and it belongs in [[#Decisions|Decisions]] so it is not re-triaged forever. Or you have been deferring it, in which case the count is the point: a candidate that has survived three checks is closer to leaving on the drive than one found today.

> [!bug] Troubleshooting
> A row that stays open after you staged the file usually means it was kept, or collided. Check the `Path` column against `MANIFEST.tsv`. A row that vanished without you doing anything means the phase that produced it was re-run and no longer does — confirm that is deliberate rather than a target you silently dropped.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

### Identify What a File Actually Is

```bash
file "$REIMAGE_ARTIFACT_ROOT/<path-from-the-report>"
```

For a PEM, the block header settles it without reading the key:

```bash
grep -l 'PRIVATE KEY' "$REIMAGE_ARTIFACT_ROOT/<path-from-the-report>"
```

A match means a private key. No match means a public certificate or chain.

> [!note]
> `.p12` and `.pfx` need no inspection. PKCS#12 is a key-and-certificate bundle by definition — if it held certificates alone it would not be in that format.

For `.env`, `credentials`, and `*.json` candidates there is no shortcut. Open it and look.

### Stage Something by Hand

The script is the supported path. When you need to place a file that does not match any shape — a credential with an innocent filename — put it under the same tree so Phase 3C picks it up and the restore side finds it where it expects:

```bash
REL="<path relative to the artifact root>"
DEST="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/staged-loose/$REL"

mkdir -p "$(dirname "$DEST")"
mv "$REIMAGE_ARTIFACT_ROOT/$REL" "$DEST"
chmod 600 "$DEST"
printf '%s\t%s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$REL" \
  "secrets-encrypted/staged-loose/$REL" \
  >> "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/staged-loose/MANIFEST.tsv"
```

Appending the manifest row by hand matters. A staged file with no row is one a restore phase cannot place.

### Reading the Rolling Reports

Three files at the top of `loose-secrets-reports/` answer three different questions:

- `open-findings.md` — what is still unresolved and how many checks each candidate has survived. Read this first.
- `MANIFEST.md` — what each individual run found, append-only. A run with findings is still a completed run.
- `findings-ledger.tsv` — the authoritative state behind `open-findings.md`. Do not hand-edit it; resolve the file on disk and the next run updates the row.

The reports name *paths*, never contents, so they are an inventory rather than a secret. They still say where credentials live on the drive — keep them with the drive.

> [!note]
> Saved reports keep their ANSI color codes on purpose. View them in a terminal: `less -R "$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports/runs/<run>/loose-secrets-report.txt"`.

### Add a Shape the Floor Does Not Cover

Copy the optional fragment into the active config directory and add to it:

```bash
cp .internal/templates/artifact-config/secret-shapes.conf.sh \
   "$REIMAGE_WORKSPACE_ROOT/artifact-config/"
```

```bash
SECRET_SHAPES_EXTRA=(
  "*.acme-token"
)
```

One line there changes both scripts. The fragment can only add — there is deliberately no way to remove a floor shape, because a workspace copy that silently dropped one would weaken protection with no signal.

Confirm it loaded:

```bash
./bin/verify-artifact-config.sh
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---
