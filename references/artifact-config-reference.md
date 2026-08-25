[[reimaging-guide#Core Assumptions|← Back to Mac Reimaging Guide]]

# Artifact Config Reference

How this workflow decides *what* gets backed up, *where* it lands, and *which copy is encrypted*.

Every backup and staging script in this repository reads the same set of configuration fragments. This document explains that set: where the fragments live, which one governs which decision, how a row is written, and which values are derived rather than set by hand. It supports `backup-home.md`, `create-secrets-dmg.md`, `stage-loose-secrets.md`, and `prepare-artifact-root.md`.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#Where Configuration Lives|Where Configuration Lives]]
- [[#The Fragment Set|The Fragment Set]]
- [[#The Two Passes|The Two Passes]]
- [[#Anatomy of a SECRETS_TARGETS Row|Anatomy of a SECRETS_TARGETS Row]]
- [[#Manual Staging Categories|Manual Staging Categories]]
- [[#Secret Shapes|Secret Shapes]]
- [[#Archive Policy|Archive Policy]]
- [[#Derived Values You Never Set|Derived Values You Never Set]]
- [[#Editing Fragments Safely|Editing Fragments Safely]]
- [[#Known Limits|Known Limits]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

Read this before editing anything under `artifact-config/`, and when a runbook says "add a row to" one of these fragments.

The single most important idea:

```text
Two independent passes read your home directory. One copies files in the clear.
The other stages files for encryption. A file can be caught by both.
```

Most of the surprises in this workflow come from that sentence. The rest of this document is the detail behind it.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Where Configuration Lives

Three layers, in precedence order. `.internal/artifact-config.sh` resolves them at load time and exports the result as `ARTIFACT_CONFIG_SOURCE_DIR`.

| Order | Layer | Path | When it wins |
|---|---|---|---|
| 1 | Explicit override | `$ARTIFACT_CONFIG_DIR` | Set in the environment, usually only for testing |
| 2 | **Workspace copy** | `$REIMAGE_WORKSPACE_ROOT/artifact-config/` | The normal case. Your machine's real configuration |
| 3 | Committed templates | `.internal/templates/artifact-config/` | Nothing else resolved |

The workspace copy is what governs a real run. The committed templates are **generic on purpose** — they carry no personal paths, employer directory names, or machine-specific patterns, so the repository can be shared or published without leaking anything.

### Seeding and ownership

The workspace copy is created once:

```bash
python3 bin/prepare-artifact-root.py init-artifact-config
```

That copies each template into `$REIMAGE_WORKSPACE_ROOT/artifact-config/` and **refuses to overwrite an existing fragment** unless `--force` is given. After that, no script writes to these files. They are yours to edit by hand, and they survive every rerun.

This is worth stating plainly because other parts of the workflow *do* generate files: Phase 3A writes `.md.proposed` and `.conf.sh.proposed` review artifacts, and `backup-apps.sh --init-intellij-review` seeds review lists. The `artifact-config/` fragments are not in that category. Seeded once, hand-maintained thereafter.

### The silent-fallback trap

If `REIMAGE_WORKSPACE_ROOT` is set but the `artifact-config/` directory under it does not exist, the loader warns and falls back to the committed templates. Every script then runs against **generic targets instead of this Mac's**, which can look like a successful run that backed up almost nothing.

The same trap catches scripts run through a remote bridge or container, where `$HOME` is not `/Users/<you>` and `REIMAGE_WORKSPACE_ROOT` cannot resolve. Never treat such a run as equivalent to a run on the Mac.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## The Fragment Set

Nine required, three optional. A missing *required* fragment aborts the load before anything is sourced, so a partial config can never reach a caller.

| Fragment | Governs | Consumed by |
|---|---|---|
| `external-targets.conf.sh` | Directories copied **in the clear** to `home-files-backup/` | `backup-home.sh` |
| `external-dotfiles.conf.sh` | Individual `~/.<file>` dotfiles and their category | `backup-home.sh` |
| `external-excludes.conf.sh` | Patterns excluded from **every** rsync call, both legs | `backup-home.sh` |
| `onedrive-targets.conf.sh` | Directories copied to the OneDrive sync folder | `backup-home.sh` |
| `onedrive-extra-excludes.conf.sh` | Additional patterns for the OneDrive leg only | `backup-home.sh` |
| `secrets-targets.conf.sh` | Files and directories staged into `secrets-encrypted/` | `backup-home.sh`, `create-secrets-dmg.sh` |
| `secret-flags.conf.sh` | `BACKUP_<KEY>` toggles for optional secrets targets | `backup-home.sh` |
| `skip-entries.conf.sh` | Documented deliberate omissions, for the manifest | manifest writers |
| `expected-artifact-folders.conf.sh` | Folders Phase 1 creates and sign-off expects | `prepare-artifact-root.py`, `reimage-checklist.sh` |
| `secret-shapes.conf.sh` *(optional)* | Extra credential-shaped filename globs | `report-loose-secrets.sh`, `stage-loose-secrets.sh` |
| `loose-secret-exceptions.conf.sh` *(optional)* | Sweep findings confirmed as noise, with a reason | `report-loose-secrets.sh` |
| `archive-policy.conf.sh` *(optional)* | Which compressed archives are copied | `backup-home.sh` |

Optional fragments are sourced only when present, so a workspace copy created before one of them shipped keeps loading.

### A note on exclude scope

`EXTERNAL_EXCLUDES` is passed to **every** rsync call, for both legs, and rsync matches a pattern containing no `/` against the filename at any depth. A generic entry there is therefore far broader than it looks. A pattern such as `cache/` would silently drop cache directories out of `Documents` as well as out of the tool directory you were aiming at.

Entries here must be distinctive. Extension-shaped patterns in particular belong in `archive-policy.conf.sh`, not here.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## The Two Passes

`backup-home.sh` walks your home directory twice, from two different lists, for two different purposes.

| | Clear-text pass | Secrets pass |
|---|---|---|
| Reads | `EXTERNAL_TARGETS`, `ONEDRIVE_TARGETS` | `SECRETS_TARGETS` |
| Writes to | `home-files-backup/`, OneDrive | `secrets-encrypted/` |
| Encrypted? | No | Yes, by Phase 3C into the DMG |
| Granularity | Whole directories | Individual files or directories |

The passes overlap wherever a secrets source sits inside a directory target. `~/.config/gh/hosts.yml` is a `SECRETS_TARGETS` source, and `~/.config` is also an `EXTERNAL_TARGETS` root — so the same file was staged for encryption *and* copied in the clear.

### How overlap is resolved

`backup-home.sh` now derives an exclude for every `SECRETS_TARGETS` source that falls inside the directory it is about to copy, on both legs:

```text
   2 path(s) held back from ~/.config — staged as secrets instead
```

The exclude is **anchored** (`--exclude=/gh/hosts.yml`, not `--exclude=hosts.yml`) so it applies to that path relative to the transfer root, rather than to every file of that name at any depth. An unanchored exclude derived from a row like `kube_config | $HOME/.kube/config` would otherwise strip every file named `config` from every target.

So the rule to remember is:

```text
A SECRETS_TARGETS row means: the DMG, and only the DMG.
```

### Cleaning up an existing double copy

Adding a row does not retroactively remove a clear-text copy made by an earlier run, and rsync's `--delete` deliberately leaves excluded files alone on the destination. A pre-existing loose copy must be deleted by hand once:

```bash
rm "$REIMAGE_ARTIFACT_ROOT/home-files-backup/<path>"
```

Deleting it is safe when the encrypted copy is already in the DMG — verify against the image's `-manifest.txt`, which lists source paths and needs no password.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Anatomy of a SECRETS_TARGETS Row

```text
"KEY | SOURCE | DEST_RELATIVE_TO_secrets-encrypted/ | DESCRIPTION"
```

```bash
"gh_hosts | $HOME/.config/gh/hosts.yml | cli-credentials/gh/hosts.yml | GitHub CLI host/auth config; may contain authentication material"
```

### Field 1 — KEY

A short lowercase identifier. It labels the row in terminal output and the manifest, and it generates a toggle: `gh_hosts` becomes `BACKUP_GH_HOSTS`. Setting that to `false` in `secret-flags.conf.sh` skips the row without deleting it. Keys must be unique.

### Field 2 — SOURCE

**Absolute path, always.** `$HOME/...` is fine; it expands when the fragment is sourced. Relative paths break, because the path is used with no working-directory assumption and is compared against an absolute destination.

**A file or a directory, both supported.** `copy_secret_target` branches on the type: directories go through rsync (with `random_seed` excluded, for `~/.gnupg`), files are copied. Trailing slash on directories by convention:

```bash
"ssh   | $HOME/.ssh/               | ssh              | SSH private keys and config"
"netrc | $HOME/.netrc              | cli-credentials/.netrc | FTP/HTTP credentials"
```

A source that does not exist is reported as `not found, skipping`, not an error — most rows are conditional by nature.

### Field 3 — DEST_RELATIVE_TO_secrets-encrypted/

Appended directly to the artifact root's secrets folder:

```bash
dst="$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/$rel_dest"
```

So `cli-credentials/gh/hosts.yml` resolves to:

```text
/Volumes/<drive>/reimage-<asset>-<date>-open/secrets-encrypted/cli-credentials/gh/hosts.yml
```

**The first segment is load-bearing.** It is the DMG *category*: the top-level folder inside the mounted image, the unit `validate` compares, the unit `cleanup` deletes wholesale once confirmed, and the unit listed in the `-categories.txt` sidecar. Everything after the first segment is structure you choose — keeping the original shape (`gh/hosts.yml`) makes restore an obvious copy-back.

Adding a **new** category needs no code change. `create-secrets-dmg.sh build` has a generic sweep that stages any directory under `secrets-encrypted/` not already handled by a named rule, so a row destined for `archives/mybundle.zip` reaches the DMG on the next build.

### Field 4 — DESCRIPTION

Free text, printed in the manifest. Say *what kind of credential material* the file holds, so a future reader can judge the row without opening the file.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Manual Staging Categories

Some applications hold their secrets somewhere no script can harvest — inside an app database, behind an export dialog, or only in the app's own cloud. Postman and Raycast are the two examples in this workflow.

For these, the row's **source and destination are the same directory**:

```bash
"postman | $MANUAL_POSTMAN_STAGE | postman | Manual Postman secret staging — environments, Vault exports, and unreviewed credential-bearing exports"
"raycast | $MANUAL_RAYCAST_STAGE | raycast | Manual Raycast secret staging — password-protected .rayconfig and sensitive Quick Links exports"
```

`copy_secret_target` detects `source == destination` and reports `already staged at secrets-encrypted/<category>` rather than rsyncing a directory onto itself. The row exists so the category appears in the manifest and completeness checks — not to copy anything.

**The workflow is therefore:** export from the app by hand into `secrets-encrypted/postman/` (or `raycast/`), then run Phase 3C. Nothing prompts you. The row is the reminder.

`$MANUAL_POSTMAN_STAGE` and `$MANUAL_RAYCAST_STAGE` are **derived, not configured** — see the next section. They are deliberately absent from `reimage.env`, and setting them there would be wrong.

To add a manual category of your own, point the source at the same path as the destination:

```bash
"myapp | $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/myapp/ | myapp | Manual MyApp export — API tokens from Settings → Export"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Secret Shapes

`SECRET_SHAPES` is the single definition of "this filename looks like a credential". It drives `report-loose-secrets.sh` (Phase 3B reporting) and `stage-loose-secrets.sh` (moving findings into `secrets-encrypted/staged-loose/`). One list, two consumers, so they cannot disagree.

It is built from two parts:

- **`SECRET_SHAPES_FLOOR`** in `.internal/artifact-config.sh` — a security minimum that lives in code so it cannot go missing from a workspace copy. There is deliberately no way to remove a floor shape.
- **`SECRET_SHAPES_EXTRA`** in `secret-shapes.conf.sh` — your additions. It can only add.

Shapes are shell globs matched against the **filename only**, never the path.

### What makes a good shape

The cost of a false positive is small: the file is staged into `secrets-encrypted/staged-loose/` and encrypted into the DMG, rather than sitting in the clear-text backup. Nothing is deleted. So err toward adding.

The cost that *is* real is noise. A shape matching a common generic filename will flag hundreds of innocent files and train you to ignore the report. `hosts.yml` is the cautionary example: it is a GitHub CLI credential file *and* the conventional name of an Ansible inventory. Adding it as a shape would flag every inventory in every repository you have ever cloned.

The rule of thumb:

```text
Distinctive name, or distinctive extension. If the name is generic, use a
SECRETS_TARGETS row for the specific file instead of a shape for all of them.
```

### Shape versus row

These solve different problems and it is worth being clear about which you want.

| | `SECRET_SHAPES_EXTRA` | `SECRETS_TARGETS` row |
|---|---|---|
| Operates on | Files already on the artifact root | The source in `$HOME` |
| Timing | Detects **after** the clear-text copy | Prevents the clear-text copy |
| Result | Moved to `staged-loose/` by Phase 3B | Staged to a named category by Phase 2 |
| Good for | A *class* of file you cannot enumerate | A specific file you know about |

A shape does eventually get the file out of the clear-text tree — Phase 3B moves it — but only after it has been written there, and it lands in `staged-loose/` rather than a meaningful category. For a file you can name, the row is better.

### Candidates worth considering

None of these are in the floor. Add the ones that match your stack:

```bash
SECRET_SHAPES_EXTRA=(
  # -- cloud and identity --------------------------------------------------
  "msal_token_cache.json"      # Azure MSAL cached tokens — live bearer tokens
  "accessTokens.json"          # older Azure CLI token cache
  ".vault-token"               # HashiCorp Vault
  "service-account*.json"      # GCP service-account keys
  "*-sa.json"
  ".s3cfg"  ".boto"            # s3cmd / boto credentials

  # -- infrastructure as code ----------------------------------------------
  "terraform.tfvars"           # routinely holds provider secrets
  "*.auto.tfvars"
  ".terraformrc"

  # -- databases -----------------------------------------------------------
  ".pgpass"  ".my.cnf"

  # -- java and jvm --------------------------------------------------------
  "*.jceks"  "*.bcfks"         # keystore formats the floor does not cover

  # -- keys and certificates the floor misses ------------------------------
  "*.ppk"                      # PuTTY private key
  "secring.gpg"                # legacy GPG secret keyring
  "*.mobileconfig"             # macOS profiles; can embed certs and payloads
  "*.ovpn"                     # VPN profiles with inline keys

  # -- app exports ---------------------------------------------------------
  "*.rayconfig"                # Raycast export, may be credential-bearing
  "*postman*environment*.json" # Postman environments hold tokens
  "local.settings.json"        # Azure Functions connection strings
  ".dockercfg"                 # legacy Docker auth
)
```

Each addition applies to both the report and the move, so add deliberately and note *why* in a comment.

### Exceptions

When a shape correctly matches something that is genuinely not a secret, record it in `loose-secret-exceptions.conf.sh` with the evidence rather than deleting the file or narrowing the shape:

```bash
"home-files-backup/path/to/*/.npmrc|Plugin registry config. Grepped for _authToken/_password/_auth on <date>: none present."
```

That keeps the sweep quiet without weakening it, and leaves a record of who checked and when.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Archive Policy

`archive-policy.conf.sh` decides which compressed archives the clear-text passes copy. Two lists, and the default is **keep**:

- `ARCHIVE_SKIP` — archives not to copy.
- `ARCHIVE_KEEP` — evaluated **first**, so it wins. Only needed once `ARCHIVE_SKIP` holds a pattern broad enough to catch something wanted.

`build_archive_flags` emits every `--include` before every `--exclude`, because rsync applies the first matching filter rule. The flags are appended to both the external and OneDrive leg.

### Why default-keep

This policy used to be three patterns — `*.dmg`, `*.pkg`, `*.zip` — in `external-excludes.conf.sh` under an "Installers" heading. Because that list applies to every target at any depth, it dropped every archive everywhere: evidence bundles, cert-staging bundles, RCA packages, exported collections. It also excluded installers from nothing, because `~/Downloads` is not a captured target.

A curated keep-list was tried instead and rejected: checked against the archives actually present on one machine, a hand-written list of name shapes still missed a quarter of them. Archives are named by whoever made them.

```text
The cost of a wrong keep is disk. The cost of a wrong skip is data.
```

### What ARCHIVE_KEEP cannot do

`ARCHIVE_KEEP` overrides `ARCHIVE_SKIP`. It does **not** rescue a file from an excluded *directory*: a directory exclude makes rsync not descend at all, so a filename include is never consulted.

For an archive under a pruned directory, the options are to move it somewhere captured, or give it a `SECRETS_TARGETS` row — which copies by absolute path and never passes through rsync's filters.

### Inspecting archives before deciding

`.internal/home/scan-archive-contents.sh` lists archive members without extracting and matches them against `SECRET_SHAPES`. Filename sweeps cannot see inside an archive, so a credential sealed in a `.zip` passes Phase 3B silently.

```bash
.internal/home/scan-archive-contents.sh --targets     # what would reach the artifact root
.internal/home/scan-archive-contents.sh --onedrive    # what would reach corporate cloud
.internal/home/scan-archive-contents.sh               # what already landed (artifact root)
```

`--targets` and `--onedrive` derive their roots from the target fragments and apply the matching excludes, so the scan covers exactly what would be copied. Archives already in `ARCHIVE_SKIP` are still scanned and marked `[ARCHIVE_SKIP - not copied]`.

It reports only. Resolving a hit means editing a fragment: a `SECRETS_TARGETS` row to encrypt it, or an `ARCHIVE_SKIP` entry to leave it behind.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Derived Values You Never Set

`.internal/artifact-config.sh` computes these at load time. They are **not** in `reimage.env`, and adding them there is a mistake:

| Variable | Derived from |
|---|---|
| `MANUAL_POSTMAN_STAGE` | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/postman/` |
| `MANUAL_RAYCAST_STAGE` | `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/raycast/` |
| `ARTIFACT_CONFIG_TEMPLATE_DIR` | the repo's `.internal/templates/artifact-config` |
| `ARTIFACT_CONFIG_WORKSPACE_DIR` | `$REIMAGE_WORKSPACE_ROOT/artifact-config` |
| `ARTIFACT_CONFIG_SOURCE_DIR` | whichever layer won the precedence check |
| `STAGED_CERTS_SOURCE_DIR` | workspace `staged-certs/`, else the committed template |
| `INTELLIJ_REVIEW_SOURCE_DIR` | workspace `intellij-review/`, else empty |
| `ONEDRIVE_DEST_SUBDIR` | the artifact root's basename, unless set |
| `SECRET_SHAPES` | `SECRET_SHAPES_FLOOR` plus `SECRET_SHAPES_EXTRA` |

Each is guarded so it expands to empty when its input is unset, rather than resolving to a filesystem-root path.

What *does* belong in `reimage.env`: `REIMAGE_ARTIFACT_ROOT`, `REIMAGE_WORKSPACE_ROOT`, `ONEDRIVE_ROOT`, `GIT_WORK_REPO_ROOT`, and the other machine-specific absolute paths. `reimage.env` holds **resolved absolute values only**, and is never committed — only `reimage.env.example` is.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Editing Fragments Safely

After any edit:

```bash
bash -n "$REIMAGE_WORKSPACE_ROOT/artifact-config/<fragment>"   # syntax
./bin/verify-artifact-config.sh                                # structure and consumers
```

`verify-artifact-config.sh` validates the active fragment set and, informationally, answers *"if I edit this fragment, what reads it?"* Run it before a phase, not after.

Then preview the effect before committing to it:

```bash
./bin/backup-home.sh --dry-run
```

### Template and workspace both

A change that should apply to future machines belongs in **both** the committed template and your workspace copy. Editing only the template leaves the current run unchanged, because the workspace copy wins.

Keep the committed template **generic**: no personal paths, employer directory names, machine-specific filenames, or one-off skips. Those belong in the workspace copy only.

### Renames

A rename inside the repository has to account for a workspace copy already seeded under the old name. Nothing warns about an orphan — the next run seeds a fresh default and silently ignores your edited file.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Known Limits

Stated so they are not rediscovered as bugs.

**Filename matching only.** Every sweep in this workflow matches names, never contents. A credential pasted into `notes.md`, `config.txt`, or a spreadsheet is invisible to all of it. `scan-archive-contents.sh` extends the same matching one level deeper, into archive member names — it does not read the files inside.

**Secrets that do not look like secrets.** `hosts.yml` and `kube/config` are real credential files with entirely ordinary names. No shape can catch that class without unacceptable noise. They are handled by explicit `SECRETS_TARGETS` rows, which means **someone has to know**. When you discover one, add the row and describe it in field 4 so the next reader does not have to rediscover it.

**Phase 3A stages by copy.** `stage-certs-keychain.sh` uses `cp`, deliberately, so a certificate stays readable in place until the erase. The plaintext original survives and Phase 3B correctly reports it. The full path is two fragments: the staged-certs entry to copy it, plus a `loose-secret-exceptions.conf.sh` entry so the sweep stops flagging the original.

**`cleanup` works at category granularity.** `create-secrets-dmg.sh cleanup` confirms a category has *any* file inside the DMG, then removes the whole on-disk category. A non-secret file added to a category *after* the image was built is deleted with it. Move review documents out of `secrets-encrypted/` before cleanup, or keep them somewhere the category sweep does not reach.

[[#Table of Contents|⬆ Back to Table of Contents]]
