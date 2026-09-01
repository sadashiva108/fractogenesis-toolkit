[[reimaging-guide|← Back to Mac Reimaging Guide]]

# Toolkit Environment Reference

**Last Updated:** 2026-08-19

How `$FRACTOGENESIS_HOME`, `reimage.env`, and `.envrc` behave across the three ways the toolkit can be installed — a Git clone, a `curl` fetch, and a jump drive — and how the shell finds them at each stage of a reimage.

This exists because these three files are touched at three separate points in the workflow: created in Phase 1, restored after the erase in Phase 8, and moved again in Phase 11B when the bootstrap copy is replaced by a real clone. Keeping that in the Phase 1 runbook would bury it in a phase you run once per reimage event.

---

## Table of Contents

- [[#The Three Toolkit Instances|The Three Toolkit Instances]]
- [[#What Travels With the Toolkit and What Does Not|What Travels With the Toolkit and What Does Not]]
    - [[#reimage.env|reimage.env]]
    - [[#Workspace fragments|Workspace fragments]]
    - [[#.envrc|.envrc]]
    - [[#FRACTOGENESIS_HOME|FRACTOGENESIS_HOME]]
- [[#How the Shell Loads Config, By Stage|How the Shell Loads Config, By Stage]]
    - [[#The Bridge and the Handoff|The Bridge and the Handoff]]
- [[#Using a curl or Jump-Drive Install|Using a curl or Jump-Drive Install]]
- [[#Moving Between Instances|Moving Between Instances]]
- [[#Owned Elsewhere|Owned Elsewhere]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## The Three Toolkit Instances

The same runbooks and scripts run from any of these. What changes is where `$FRACTOGENESIS_HOME` points and which of the two config files arrived with it.

| Instance | `$FRACTOGENESIS_HOME` | When it is the active one | Has `.git`? |
|---|---|---|---|
| Git clone | wherever you cloned, e.g. `$GIT_PERSONAL_REPO_ROOT/fractogenesis-toolkit` | Pre-image, and again from Phase 11B onward | Yes |
| `curl` install | whatever `FRACTOGENESIS_HOME` was exported to in Phase 8 Step 1; `$HOME/fractogenesis-toolkit` if that export was skipped | Phase 8 through Phase 11B, when the network is up | No |
| Jump-drive install | same default; set by `bootstrap.sh` | Phase 8 through Phase 11B, when there is no network yet | No |

The curl and jump-drive installs are the *same* tree by different delivery. Both are extracted by `bootstrap.sh`, neither carries `.git`, and both are temporary: they exist to get you from a bare Mac to a working development environment, at which point Phase 11B clones the toolkit properly and you repoint at the clone.

> [!note]
> Two copies exist between Phase 11B and the repoint — the bootstrap copy in `$HOME` and the fresh clone. `$FRACTOGENESIS_HOME` still points at the bootstrap copy until you change it, so it is possible to edit one and commit the other. See [[#Moving Between Instances|Moving Between Instances]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## What Travels With the Toolkit and What Does Not

The two config files behave completely differently, and conflating them is the source of most confusion here.

| File | Tracked in Git? | In the clone? | In the curl tarball? | In the jump-drive tarball? | Needs a separate copy? |
|---|---|---|---|---|---|
| `.envrc` | Yes | Yes | Yes | Yes | **No** |
| `reimage.env` | No — gitignored | No | No | No | **Yes** |
| `artifact-config/`, `staged-certs/` | No — gitignored, and outside the toolkit entirely | No | No | No | **Yes** |

### reimage.env

Machine- and effort-specific: the artifact root, the external volumes, the repo roots, the Git identities. It is gitignored, so no delivery route carries it.

**It lives at the toolkit root**, `$FRACTOGENESIS_HOME/reimage.env`, and that is not a convention you can vary. `.internal/artifact-config.sh` self-locates from its own position and resolves `reimage.env` beside the toolkit root it derives; a copy anywhere else is not read. Move the toolkit, and `reimage.env` has to move with it.

> [!note]
> `$FRACTOGENESIS_HOME` is the toolkit root — where the runbooks and `bin/` live. It is unrelated to `$REIMAGE_ARTIFACT_ROOT`, the external drive that holds backups and generated evidence. The two are never the same directory, and `reimage.env` belongs to the first.

Every `bin/` entrypoint sources `.internal/load-reimage-config.sh`, which sources `artifact-config.sh`, which sources `reimage.env`. **Scripts therefore need no environment set up in your shell** — only that the file sits beside them. What needs values in the shell is the commands *you* type: `ls "$REIMAGE_ARTIFACT_ROOT"`, the Time Machine exclusion gate's `$EXTERNAL_DATA_VOLUME`, and similar.

Because it exists in exactly one place, it needs a deliberate backup before the erase. That copy goes on the jump drive, alongside `bootstrap.sh` and the payload.

> [!warning] Pitfall
> Restore `reimage.env`; never regenerate it. `bin/setup-reimage-env.sh` *recomputes* values rather than restoring them — `REIMAGE_START_DATE` defaults to today, so `REIMAGE_ARTIFACT_ROOT` resolves to a **new, empty** event folder instead of the one holding your backups. Every restore step then reports MISSING for every source while writing its notes into the wrong tree, a failure that looks like a bad backup rather than a bad variable. Regenerating is only correct when starting a genuinely new reimage event.

> [!note]
> `reimage.env` is safe to carry in the clear — it holds no secrets, and the DMG password is deliberately excluded. It does carry asset tag, hostname, GitHub org, internal repo roots, and OneDrive paths. That is company-identifying rather than secret, so a verbatim copy belongs on the jump drive; if you also mail yourself a copy, sanitise it the way the post-reimage cheatsheet is sanitised.

### Workspace fragments

`$REIMAGE_WORKSPACE_ROOT/artifact-config/` and `staged-certs/` hold the shell
fragments that decide what the backup and staging scripts actually act on —
which home targets are captured, which folders are expected, which loose
certificates are staged. They are edited per machine, gitignored, and live
outside the toolkit altogether, so no install route carries them and neither
does a clone.

**Their absence is silent, which is what makes them dangerous.** With
`REIMAGE_WORKSPACE_ROOT` set and the directory missing, `artifact-config.sh`
prints one line to stderr and falls back to the committed templates. Nothing
fails. The run completes, the evidence is written, and it is indistinguishable
from a run against your real configuration unless you happened to read the
warning as it scrolled past.

Two recovery sources, in order: the jump-drive copy made in Phase 6A, and the
`home-files-backup/` capture, since the workspace sits under `$HOME`:

```bash
find "$REIMAGE_ARTIFACT_ROOT/home-files-backup" -type d -name artifact-config
```

### .envrc

Tracked and committed, identical on every Mac and every reimage effort, with nothing machine-specific in it. It arrives with the toolkit by all three routes and never needs copying anywhere.

Its contents:

```bash
export FRACTOGENESIS_HOME="$(pwd)"

if [[ -f "$(pwd)/reimage.env" ]]; then
  dotenv reimage.env
fi

PATH_add bin
```

Three consequences worth knowing:

- It sets `FRACTOGENESIS_HOME` from the directory it sits in, so once direnv is active the variable follows the toolkit automatically.
- It loads whatever `reimage.env` currently exists, with no staleness check. `.envrc` cannot go stale; `reimage.env` can, and direnv will `dotenv` an old one just as happily as a current one.
- It puts `bin/` on `PATH`, so `record-enrollment.sh` works without the `./bin/` prefix once direnv is active. The runbooks use the explicit path anyway, since it works in both states.

**`.envrc` does nothing without direnv**, and direnv is installed in Phase 10A. Between the erase and that point, a `.envrc` sitting in the toolkit is inert.

> [!warning] Pitfall
> A `.envrc` that arrived with a fresh install is present but **unapproved**. direnv approves by content hash and its approval list is machine-local, so an erased Mac has no record of a file it approved before. `direnv allow` in the toolkit root is a required step, not a formality — without it direnv silently loads nothing.

### FRACTOGENESIS_HOME

The toolkit root: the directory holding `bin/`, `.internal/`, the runbooks, and `reimage.env`. It is the one value that cannot come from `reimage.env`, because you need it to find the toolkit that holds `reimage.env`. `reimage.env.example` states this explicitly: it is a shell-startup concern, not a config key.

Every runbook from Phase 8 onward opens with `cd "$FRACTOGENESIS_HOME"`.

> [!warning] Pitfall
> Unset, `cd ""` is a **no-op that returns 0**. You stay in `$HOME`, every `./bin/…` afterward reports "No such file or directory", and nothing points back at the missing variable. This is the single most likely way to lose time in Phase 8, and the reason Step 2 persists the value rather than relying on the current shell.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Shell Loads Config, By Stage

| Stage | `FRACTOGENESIS_HOME` from | `reimage.env` into the shell from | `bin/` scripts work? |
|---|---|---|---|
| Pre-image (Phases 1–6) | `.envrc` via direnv | `.envrc` via direnv | Yes |
| Phase 8 → Phase 10A | `~/.zprofile` block written by `bin/init-shell-env.sh` | same block | Yes |
| Phase 10A onward | `.envrc` via direnv, once `direnv allow` has run | `.envrc` via direnv | Yes |

`bin/` scripts work in every row, including a row where nothing at all is exported, because they load `reimage.env` themselves. The columns describe what *your typed commands* can see.

### The Bridge and the Handoff

direnv is not available until `restore-runtime.md` (Phase 10A) installs it, which leaves Phases 8 and 9 with no automatic loading at all. `bin/init-shell-env.sh` bridges that gap and is then removed.

| Window | Mechanism | Action |
|---|---|---|
| Phase 8 → 10A | `~/.zprofile` block exporting `FRACTOGENESIS_HOME` and sourcing `reimage.env` | `bash "$FRACTOGENESIS_HOME/bin/init-shell-env.sh"` in Phase 8 Step 2 |
| Phase 10A | direnv installed and hooked | `direnv allow` in the toolkit root |
| Phase 10A onward | `.envrc` via direnv | `bash "$FRACTOGENESIS_HOME/bin/init-shell-env.sh" --remove` |

The two mechanisms are deliberately mutually exclusive in time, not layered. The `.zprofile` block writes no values of its own — it sources `reimage.env`, so there is one source of truth throughout and nothing to drift.

> [!note]
> Do not skip the `--remove`. Left in place, the profile block and direnv both load `reimage.env`, which is harmless while they agree — and confusing the first time you point `FRACTOGENESIS_HOME` somewhere new and one of them keeps insisting on the old value.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Using a curl or Jump-Drive Install

Assumes both routes were already built and proven pre-image; see [[#Owned Elsewhere|Owned Elsewhere]].

**Which route to use:** the curl route needs network and the GitHub account from your cheatsheet. The jump drive needs neither. On a freshly enrolled Mac the network is usually up, but a captive portal or a delayed profile push can leave a real window without it — that window is the jump drive's entire reason for existing.

**Either way the result is the same tree**, extracted to whatever `FRACTOGENESIS_HOME` names — Phase 8 Step 1 exports it before running `bootstrap.sh` for exactly that reason — falling back to `$HOME/fractogenesis-toolkit` when it is unset. `bootstrap.sh` `chmod +x`es `bin/` on the way out, so scripts arrive runnable.

Both installs share three properties worth keeping in mind while you use one:

- **No `.git`.** `git status`, `git diff`, and `git checkout -- .envrc` do not work, so the drift checks that Phase 1 uses to validate `.envrc` cannot be run here. The tree is whatever the tarball held.
- **A version stamp, on the jump-drive route only.** `.toolkit-version` is gitignored; `bin/build-jump-drive-payload.sh` forces it into the payload with `git archive --add-file`, so a jump-drive install carries it and `bootstrap.sh` prints it on completion. GitHub's codeload tarball ships only committed files, so a `curl` install has no stamp and `bootstrap.sh` says so. Absent it, the curl route is always current by construction — it fetched `main` a moment ago — while a jump drive can be arbitrarily stale, which is exactly why the stamp exists on that side.
- **No `reimage.env` until you put it there.** Copy it from the jump drive.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Moving Between Instances

Phase 11B clones the toolkit into `$GIT_PERSONAL_REPO_ROOT`, because the toolkit lives under the personal repo root like any other repo. That clone is a *different instance* from the one you have been running since Phase 8, and switching to it is a deliberate act.

```bash
# Capture the current root first: after the repoint below, FRACTOGENESIS_HOME
# names the clone and this is the only handle left on the bootstrap copy.
TOOLKIT_BOOTSTRAP="$FRACTOGENESIS_HOME"

# 1. Carry reimage.env across -- it is gitignored, so the clone does not have it.
cp "$TOOLKIT_BOOTSTRAP/reimage.env" \
   "$GIT_PERSONAL_REPO_ROOT/fractogenesis-toolkit/reimage.env"

# 2. Repoint the shell. init-shell-env.sh self-locates, so running it from the
#    clone rewrites the profile block to point at the clone.
bash "$GIT_PERSONAL_REPO_ROOT/fractogenesis-toolkit/bin/init-shell-env.sh"

# 3. Approve .envrc in the clone, if direnv is already installed.
cd "$GIT_PERSONAL_REPO_ROOT/fractogenesis-toolkit" && direnv allow

# 4. Only once the above is confirmed working, remove the bootstrap copy.
rm -rf "$TOOLKIT_BOOTSTRAP"
```

`.envrc` needs no copying — it is in the clone already. It does need approving: direnv's approval list is machine-local and keyed by content hash and path.

> [!warning] Pitfall
> Repointing without step 1 leaves the clone with no `reimage.env`, and every `bin/` script starts failing to resolve `REIMAGE_ARTIFACT_ROOT` — in the middle of Phase 11B, where it reads as a repo-restore problem rather than a missing file.

> [!warning] Pitfall
> Do step 4 last and only after confirming the clone works. Deleting the bootstrap copy first destroys the only copy of `reimage.env` on the machine if step 1 did not land.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Owned Elsewhere

This reference describes how the environment behaves. It deliberately does not duplicate the procedures that create or prove it.

| Topic | Owned by |
|---|---|
| Which runbook owns each `reimage.env` key, and when each is written | [[environment-variable-reference\|Environment Variable Reference]] |
| Creating `reimage.env` for a new reimage event, and first-time direnv setup | [[prepare-artifact-root|prepare-artifact-root.md]] (Phase 1) |
| Building the jump-drive payload, and **proving** both the curl and jump-drive routes work | [[reimage-guide-access|reimage-guide-access.md]] (Phase 6A) |
| Installing the toolkit after the erase, and restoring the shell environment | [[enroll-and-stabilize|enroll-and-stabilize.md]] (Phase 8, Steps 1–2) |
| Installing direnv on the rebuilt Mac | [[restore-runtime|restore-runtime.md]] (Phase 10A) |
| Cloning the toolkit into the personal repo root, and the repoint that follows | [[restore-repos#Step 4 — Repoint at the Cloned Toolkit|restore-repos.md]] (Phase 11B, Step 4) |
| Why the toolkit is fetched rather than cloned on a bare Mac | [[restore-strategy-guide|restore-strategy-guide.md]] |

[[#Table of Contents|⬆ Back to Table of Contents]]
