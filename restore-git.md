[[reimaging-guide#Phase 11A — Restore Git|← Back to Mac Reimaging Guide]]

# Restore Git

**Last updated:** 2026-09-02

Restore the Git identity plumbing on the reimaged Mac so both work and personal GitHub accounts route automatically based on where a repository lives on disk. This runbook wires up the dual-identity `~/.gitconfig` (work as default, `includeIf` override under the personal repo root), lays down the matching `~/.ssh/config` host aliases, validates both identities, and leaves you with a `git clone` template that Phase 11B then applies at scale against the pre-image repository audit. It does not enumerate a repo list, drive a clone loop, or restore preserved local branches or stashes — that carry-forward work belongs to Phase 11B.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#Identity Design|Identity Design]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Bundle Layout|Bundle Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
    - [[#Account Access — Tokens, 2FA, and Key Rotation|Account Access — Tokens, 2FA, and Key Rotation]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 0 — Record Prerequisites and the Before-State|Step 0 — Record Prerequisites and the Before-State]]
    - [[#Step 1 — Install Git and Confirm the Environment|Step 1 — Install Git and Confirm the Environment]]
    - [[#Step 2 — Set Correct Permissions on Restored SSH Keys|Step 2 — Set Correct Permissions on Restored SSH Keys]]
    - [[#Step 3 — Write `~/.ssh/config` with Dual Host Aliases|Step 3 — Write `~/.ssh/config` with Dual Host Aliases]]
    - [[#Step 4 — Write the Global `~/.gitconfig`|Step 4 — Write the Global `~/.gitconfig`]]
    - [[#Step 5 — Write the Personal-Root .gitconfig Override|Step 5 — Write the Personal-Root .gitconfig Override]]
    - [[#Step 6 — Seed the Local Preferences Overlay|Step 6 — Seed the Local Preferences Overlay]]
    - [[#Step 7 — Validate Both Identities|Step 7 — Validate Both Identities]]
    - [[#Step 8 — Compare Restored State Against Captured Inventories|Step 8 — Compare Restored State Against Captured Inventories]]
    - [[#Step 9 — Close Out the Exit Criteria|Step 9 — Close Out the Exit Criteria]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#One Repository, Two Remotes|One Repository, Two Remotes]]
    - [[#Optional Maintenance — Update All Local Repos|Optional Maintenance — Update All Local Repos]]
    - [[#Optional — git-together Legacy Notes|Optional — git-together Legacy Notes]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!warning]` Pitfall, a mistake whose cost you do not get back · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Restore the identity and routing plumbing that lets both work and personal Git operations succeed on the reimaged Mac without manual profile switching. Get the machine to the point where a `git clone` command uses the right SSH key and stamps commits with the right author automatically, based only on which directory the clone lands in.

**What it sets up**

- **The dual-identity `~/.gitconfig`** — the work identity as the global default, with an `includeIf "gitdir:…"` directive that pulls in the personal override only for repos under the personal repo root.
- **The personal-root `.gitconfig` override** — the personal name and email plus `core.sshCommand` pinning the personal SSH key, so personal repos send the right key even if `~/.ssh/config` is wrong.
- **The `~/.ssh/config` host aliases** — one `Host` entry per identity, each forcing its own `IdentityFile` with `IdentitiesOnly yes`, so key selection follows the clone URL.
- **Correct permissions on the restored SSH keys** — `~/.ssh` at `700`, private keys and `~/.ssh/config` at `600`, public keys at `644`, so the SSH client will actually use them.
- **The optional XDG local config** — `~/.config/git/config.local` wired in through an `[include]` block, for workflows that make the XDG path canonical instead of `~/.gitconfig`.
- **The validated clone pattern** — both identities proven end-to-end, plus the `git clone` command template for each side.

**What the rest of the workflow relies on it for**

- Phase 11B reads the pre-image repository audit and emits `git clone` commands that depend on this identity plumbing already routing correctly.
- The re-cloned working trees that Phase 11B lays preserved branches, stashes, and kept ignored files back into only exist once cloning works with the right key.
- Every later `git push`, `git pull`, and `git fetch` picks up its author and key from these files, with no manual profile switching.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| the global `~/.gitconfig` with work identity as default and `includeIf` for the personal repo root | restoring SSH key files from the encrypted secrets DMG — `restore-access` (Phase 10B) |
| the personal-root `.gitconfig` override with `core.sshCommand` pinning the personal key | capturing branches, uncommitted work, stashes, local-only commits, and chosen kept ignored files pre-image — `backup-repos` (Phase 2A) |
| the optional `~/.config/git/config.local` XDG include | laying that carry-forward material back into re-cloned repos — `restore-repos` (Phase 11B) |
| `~/.ssh/config` with dual host aliases (work and personal), `IdentitiesOnly yes` | enumerating which repositories to re-clone or driving a clone loop — `restore-repos` (Phase 11B) |
| permissions on restored SSH keys and `~/.ssh/config` | the fractogenesis-toolkit checkout itself, installed by `bootstrap.sh` and not re-cloned here — `enroll-and-stabilize` (Phase 8) |
| validating that both identities route correctly end-to-end | IDE-specific repo state (IntelliJ project files, VS Code workspace) — `restore-intellij` / `restore-apps` (Phase 12) |
| the `git clone` command template used for re-cloning repositories | Docker container and image restore — `restore-docker` (Phase 12) |

This runbook can be rerun. Every write is a file replacement or `chmod`, so re-running is the intended way to recover from a mis-typed identity or a stale `~/.ssh/config`. Nothing here builds on prior local state.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The goal is two identities that activate automatically based on where a repo lives — no manual switching. Git's `includeIf "gitdir:..."` directive handles the identity switch; a separate `~/.ssh/config` handles the SSH key routing; the two work together so both the commit author and the SSH key are correct without you having to think about it after the initial clone.

The order matters. `~/.ssh/config` is written *before* the Git configs because Git's `core.sshCommand` in the personal-root override references the personal key path, and it is easier to verify SSH reachability once before layering identity logic on top of it. Global `.gitconfig` is written before the personal-root override so that `includeIf` has something to override. Validation runs from both a work repo and a fresh directory under the personal root because the two paths of the trust chain — identity and key — can fail independently.

Almost every write in this runbook uses values from `reimage.env`. Git config files do not reliably expand shell variables after they are written, so the writes are done via heredocs in the current shell where `reimage.env` values are already sourced — the resulting files contain resolved absolute paths, not `$GIT_WORK_EMAIL` placeholders.

### Identity Design

| Context | Email | SSH Key | GitHub Host Alias |
|---|---|---|---|
| Default work repos | `$GIT_WORK_EMAIL` | `$GIT_WORK_SSH_KEY` | `$GIT_WORK_GITHUB_HOST` |
| Personal repos under `$GIT_PERSONAL_REPO_ROOT` | `$GIT_PERSONAL_EMAIL` | `$GIT_PERSONAL_SSH_KEY` | `$GIT_PERSONAL_GITHUB_HOST` |

Work is the global default because most repos live outside the personal repo root; setting work as the default means `includeIf` only has to fire for the exception, not the rule.

### Terminology

| Term | Meaning |
|---|---|
| Work identity | The default identity: `$GIT_WORK_NAME` / `$GIT_WORK_EMAIL`, using `$GIT_WORK_SSH_KEY`, cloned via `$GIT_WORK_GITHUB_HOST`. Applies to any repo not under `$GIT_PERSONAL_REPO_ROOT`. |
| Personal identity | The override: `$GIT_PERSONAL_NAME` / `$GIT_PERSONAL_EMAIL`, using `$GIT_PERSONAL_SSH_KEY`, cloned via `$GIT_PERSONAL_GITHUB_HOST`. Applies only inside `$GIT_PERSONAL_REPO_ROOT`. |
| `includeIf gitdir:...` | A Git config directive that pulls in another config file only when the current repo's `.git` directory lives under a specific path. How the personal identity activates without manual switching. |
| Host entry | An `~/.ssh/config` `Host` block that forces a specific `IdentityFile` for one server. `Host` is the name you type; `HostName` is where SSH actually connects. When the two identities live on different servers — a GitHub Enterprise instance and public GitHub — each block names its own real host, and the two values must match or SSH connects to the wrong server. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path this runbook reads or writes is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
none — this runbook writes its identity files by hand; the scripts below record and compare
```

Related scripts, alphabetical:

```text
$FRACTOGENESIS_HOME/bin/compare-restored-state.sh      # entrypoint (Step 8 — comparison against the pre-image inventory)
$FRACTOGENESIS_HOME/bin/prepare-artifact-root.py       # entrypoint (Step 0c — upsert-env, writes the identity keys into reimage.env)
$FRACTOGENESIS_HOME/bin/record-restore-exit.sh         # entrypoint (Step 9 — exit boundary)
$FRACTOGENESIS_HOME/bin/record-restore-prereqs.sh      # entrypoint (Step 0a — entry boundary)
$FRACTOGENESIS_HOME/bin/record-restore-state.sh        # entrypoint (Step 0b before-state, Step 8 after-state and delta)
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/                # every artifact this runbook generates lands here
```

Input evidence built by earlier phases:

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/git/          # written by create-secrets-dmg.md — pre-image ~/.gitconfig and ~/.config/git/, read for reference and not copied forward
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/ssh/          # written by create-secrets-dmg.md — the keys restore-access.md put on disk; Step 2 only fixes their modes
$REIMAGE_ARTIFACT_ROOT/system-inventory/runs/pre-image-YYYYMMDD-HHMMSS/   # written by capture-system-inventory.md — its 08-git.txt is what Step 8 compares against
```

The complete `secrets-encrypted/` and `system-inventory/` layouts are defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

### Bundle Layout

Everything this runbook writes, under the artifact root named above. The bundles it reads are listed in the block before this one and are not expanded here; this tree is output only.

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── reimaged-system/
│   ├── boundaries/
│   │   ├── MANIFEST.md
│   │   ├── official/
│   │   │   ├── restore-git-entry.txt
│   │   │   └── restore-git-exit.txt
│   │   └── runs/
│   │       ├── restore-git-entry-YYYYMMDD-HHMMSS/
│   │       │   └── checklist.md
│   │       └── restore-git-exit-YYYYMMDD-HHMMSS/
│   │           └── checklist.md
│   ├── ...
│   ├── comparisons/
│   │   ├── MANIFEST.md
│   │   ├── official/
│   │   │   └── restore-git-inventory-diff.txt
│   │   └── runs/
│   │       └── restore-git-inventory-diff-YYYYMMDD-HHMMSS/
│   │           ├── comparison.md
│   │           └── rows.tsv
│   ├── ...
│   ├── sign-offs/
│   │   └── restore-git-exit-YYYYMMDD-HHMMSS.md
│   └── state/
│       ├── MANIFEST.md
│       ├── official/
│       │   ├── restore-git-after.txt
│       │   ├── restore-git-before.txt
│       │   └── restore-git-delta.txt
│       └── runs/
│           ├── restore-git-after-YYYYMMDD-HHMMSS/
│           │   ├── state.md
│           │   └── state.tsv
│           ├── restore-git-before-YYYYMMDD-HHMMSS/
│           │   ├── state.md
│           │   └── state.tsv
│           └── restore-git-delta-YYYYMMDD-HHMMSS/
│               └── delta.md
└── ...
```

`boundaries/`, `comparisons/` and `state/` share one shape: `runs/<context>-YYYYMMDD-HHMMSS/` holds a single run's files, `official/<context>.txt` names the run that counts, and an append-only `MANIFEST.md` indexes every completed run. To find a run, read the pointer under `official/` — there is no newest-directory rule and no `latest-*.txt`.

Which run a pointer names is decided per point rather than per category. `before` is first-wins, because the earliest observation is the one that caught the untouched machine; `after`, `delta`, `entry`, `exit` and the inventory diff are latest-wins, so re-running any of them replaces the earlier answer.

`sign-offs/` is outside that shape on purpose. It holds the rows you answered at the exit boundary and carries them forward into the next run, so a latest-wins pointer must never be able to supersede it.

Live targets this runbook writes on the reimaged Mac. Each names the step that writes it, because the `state/` captures above are only interpretable against this list — and `bin/record-restore-state.sh` walks exactly these paths:

```text
~/.ssh/config                             # Step 3 — dual host aliases, rewritten wholesale rather than appended to
~/.gitconfig                              # Step 4 — work-default with includeIf for personal
$GIT_PERSONAL_REPO_ROOT/.gitconfig        # Step 5 — personal identity override and core.sshCommand
~/.config/git/config.local                # Step 6 — preferences overlay, loaded by the [include] in ~/.gitconfig
$GIT_WORK_SSH_KEY, $GIT_PERSONAL_SSH_KEY  # Step 2 — permission-fixed only; restore-access.md put them on disk
```

### Environment Variables

The `reimage.env` values this runbook depends on. `REIMAGE_ARTIFACT_ROOT` is resolved during `prepare-artifact-root.md` and the repository roots during `backup-repos.md`. The identity keys, host aliases and default branch are written **by this runbook**, in Step 0c — they are not in `reimage.env.example` and do not exist in `reimage.env` until 0c records them, since `upsert-env` appends a key that is not yet present.

The five work-and-default keys are required. The four `GIT_PERSONAL_*` identity keys are optional and all-or-nothing: fill every one or leave every one blank. `GIT_PERSONAL_GITHUB_HOSTNAME` is written by the same step but stands outside that group — blank is its normal value and means `HostName` inherits the `Host` value, so requiring it would fail every Mac whose two identities sit on different servers. Step 9 checks it whether or not it is set, by reading the written `Host` block back out of `~/.ssh/config`.

| Variable | Meaning |
|---|---|
| `FRACTOGENESIS_HOME` | Repository root for this toolkit checkout; where `reimage.env` lives. Set by your shell startup / `.envrc`, not stored in `reimage.env`. |
| `REIMAGE_ARTIFACT_ROOT` | Artifact root for this reimage event; used only for the input paths above. |
| `GIT_WORK_NAME` | Author name for the default work identity. |
| `GIT_WORK_EMAIL` | Author email for the default work identity. |
| `GIT_PERSONAL_NAME` | Optional. Author name for the personal identity override. |
| `GIT_PERSONAL_EMAIL` | Optional. Author email for the personal identity override. |
| `GIT_WORK_REPO_ROOT` | Directory holding work repos. Repos here inherit the global work identity. |
| `GIT_PERSONAL_REPO_ROOT` | Directory holding personal repos. `includeIf` fires only for repos under this path. |
| `GIT_WORK_GITHUB_HOST` | Host SSH connects to for work clones — a GitHub Enterprise instance such as `github.example.com`, or `github.com` when there is no Enterprise instance. Written as both `Host` and `HostName` in `~/.ssh/config`, so it must resolve. |
| `GIT_PERSONAL_GITHUB_HOST` | Optional. The name written as `Host` in `~/.ssh/config` and typed in personal clone URLs, usually `github.com`. When both accounts live on one server, set this to an alias such as `github.com-personal` and put the real server in `GIT_PERSONAL_GITHUB_HOSTNAME`. |
| `GIT_PERSONAL_GITHUB_HOSTNAME` | Optional. The server SSH actually connects to for personal clones, written as `HostName`. Leave blank unless `GIT_PERSONAL_GITHUB_HOST` is an alias; blank means `HostName` takes the `Host` value. Whatever is in effect must resolve. |
| `GIT_WORK_SSH_KEY` | Absolute path to the work private key on disk (already restored in Phase 10B). |
| `GIT_PERSONAL_SSH_KEY` | Optional. Absolute path to the personal private key on disk (already restored in Phase 10B). |
| `GIT_DEFAULT_BRANCH` | Default branch name for `git init` (defaults to `main` when unset). |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 10B ([[restore-access|restore-access.md]]) is complete: the SSH keys referenced by `$GIT_WORK_SSH_KEY` and `$GIT_PERSONAL_SSH_KEY` exist on disk, the internal-CA trust is in the login keychain, and `hdiutil detach` cleaned up any mounted DMG.
- `reimage.env` is present, and you know your Git identity values (name, email, SSH key paths, host aliases). Step 0c records them into `reimage.env`. The work values are required. The personal set is optional — a Mac with no separate personal identity leaves all four blank — but it is all-or-nothing: a half-filled personal identity silently produces an override `.gitconfig` with an empty email, which Git accepts without complaint.
- You know the SSH key fingerprints registered on GitHub for both accounts, or can look them up in a password manager. You will compare them in Step 2.

> [!bug] Troubleshooting
> `source ./reimage.env` failing with "no such file" almost always means you are not at the repository root. `pwd` should print `$FRACTOGENESIS_HOME`; `cd` there and try again.

### Confirm Your Intent

- Are you doing a **full first-time restore** (Steps 1 through 8 in order) or a **targeted rerun** of one file (e.g. re-writing `~/.ssh/config` after adding a third identity)? Both are safe; the difference is whether you also do Step 7's validation at the end.
- Do you have **Git preferences to carry forward** — aliases, a pager, a diff tool, signing keys? They go in `~/.config/git/config.local` in Step 6, never in `~/.gitconfig`, which this runbook rewrites in full. Skip Step 6 if you have none.
- Which **default branch name** does your workflow use? The runbook defaults to `main`, matching GitHub's default and `fractogenesis-toolkit`'s own branch. Set `GIT_DEFAULT_BRANCH=master` in Step 1 if your remotes still use the older name — this only affects `init.defaultBranch` for repos you create later, never an existing clone.

> [!warning] Pitfall
> Do not commit `reimage.env` itself, restored `.gitconfig` files with real email addresses, or restored SSH keys. `.gitignore` should already exclude these; verify before your first commit after restore.

### Account Access — Tokens, 2FA, and Key Rotation

Restoring keys and config gets Git *configured*; it does not get you *authenticated*. The erase took the login keychain with it, so nothing on this Mac remembers a credential, and GitHub has not accepted account passwords over HTTPS for years. Any remote still on an `https://` URL will prompt for a **personal access token** the first time you push or pull, and a token you cannot reach is indistinguishable from a lost account.

- **Have the tokens off-machine before the erase.** Store any personal access token you rely on in a password manager or another device — not in a file on the Mac being wiped, and not in the browser profile that goes with it. The same goes for the account passwords themselves.
- **Have your 2FA recovery codes off-machine before the erase.** Print them, or keep them in a password manager that syncs elsewhere. They are the only path back in when the second factor is unavailable.
- **Prefer SSH remotes.** With Steps 2–4 done, `git@…` remotes authenticate from the restored key and never prompt for a token. Reserve HTTPS for the cases that genuinely need it.

If the restored key turns out to be stale — rotated out upstream, or you simply cannot confirm the fingerprint from Step 2 — generate a fresh one and register it rather than fighting the old one:

```bash
ssh-keygen -t ed25519 -C "<email>"
pbcopy < ~/.ssh/id_ed25519.pub
```

Then paste it at `github.com/settings/keys` (repeat per account, using the key path each identity expects — `$GIT_WORK_SSH_KEY` or `$GIT_PERSONAL_SSH_KEY`). Adding a key requires being signed in, which requires the second factor — so do this only after account access is confirmed.

> [!warning] Pitfall
> An authenticator app whose only enrollment lived on the Mac you just erased is a lockout risk, not an inconvenience. The app is gone, the codes are gone, and adding a new SSH key or minting a replacement token both require signing in. Before the erase, either move the authenticator to a phone or second device, or confirm you hold current recovery codes for **every** account this runbook touches — work GitHub, personal GitHub, and any Enterprise Server host.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. `~/.ssh/config` goes down before the Git configs so `core.sshCommand` in Step 5 has a routing environment to reference; validation runs after both are written because the two paths of the trust chain can fail independently.

Every step begins with `source ./reimage.env` — Git config files do not reliably expand shell variables after they are written, so the heredocs below rely on values being resolved *in the current shell* at write time.

### Step 0 — Record Prerequisites and the Before-State

Two recordings, both taken before anything is written. They answer different
questions and only one of them can be taken late.

**0a — may this phase start?** Writes a checklist under
`reimaged-system/boundaries/` and exits non-zero only on `FAIL`:

```bash
./bin/record-restore-prereqs.sh --runbook restore-git --dry-run
./bin/record-restore-prereqs.sh --runbook restore-git
```

Its rows are derived from *Prerequisites* above, so the two cannot drift. The
row worth reading twice is **Identity SSH keys restored and tight**: an unset
`$GIT_WORK_SSH_KEY`, a key Phase 10B did not restore, or a key at the wrong mode
does not produce an error. `ssh` skips a key it cannot use and authenticates as
whichever identity answers next — so the first symptom is a commit pushed under
the wrong account, found by someone else, later.

**0b — what is on disk right now?** Writes a run under `reimaged-system/state/`
recording every path this phase will write, as it stands before the phase
touches it:

```bash
./bin/record-restore-state.sh --runbook restore-git --point before --dry-run
./bin/record-restore-state.sh --runbook restore-git --point before
```

Four targets: `~/.gitconfig`, `~/.config/git/`, `~/.ssh/config`, and the
personal-root `.gitconfig` reached by `includeIf`.

Every block in this runbook shows a `--dry-run` line above the real one. It
prints the table and writes nothing. On **0b** that preview is worth more than
anywhere else: `before` is a first-wins point, so the first capture recorded is
the one that stays official, and a mistimed one cannot be replaced — only
annotated with a pin explaining why it is wrong. Read the target list, confirm
it describes a machine this phase has not touched, then record.

> [!warning] Pitfall
> **0b expires and 0a does not.** The prerequisite check is rerunnable at any
> point and costs nothing to repeat. The before-state is gone the moment Step 3
> rewrites `~/.ssh/config` — Step 3 replaces that file wholesale rather than
> appending to it — and Step 4 writes `~/.gitconfig`. Take 0b before Step 0c.

**0c — confirm the values this phase writes.** Steps 3 through 6 write your
identity into `~/.ssh/config`, `~/.gitconfig`, and the personal-root override.
They read it from `reimage.env`, and no earlier phase sets it: the repository
roots carry over from the pre-image backup, the identity does not. Record it
here, before the first write, rather than discovering an empty value inside a
heredoc that accepts it silently.

`reimage.env` is not one of 0b's four targets, so recording it here does not
disturb the capture you just took.

Fill in the real values. The five work-and-default keys are required. The four
`GIT_PERSONAL_*` keys are optional — leave all four blank if this Mac has no
separate personal identity — but fill all four or none:

```bash
export GIT_WORK_NAME="Your Name"
export GIT_WORK_EMAIL="you@company.example"
export GIT_WORK_SSH_KEY="$HOME/.ssh/id_work"
export GIT_WORK_GITHUB_HOST="github.example.com"
export GIT_DEFAULT_BRANCH="main"

export GIT_PERSONAL_NAME=""
export GIT_PERSONAL_EMAIL=""
export GIT_PERSONAL_SSH_KEY=""
export GIT_PERSONAL_GITHUB_HOST=""
export GIT_PERSONAL_GITHUB_HOSTNAME=""
```

`GIT_PERSONAL_GITHUB_HOSTNAME` is deliberately outside the all-or-nothing personal
set. Blank is its normal value and means `HostName` takes whatever
`GIT_PERSONAL_GITHUB_HOST` holds; it is filled only when that host is an alias, so
requiring it alongside the other four would demand a value most Macs must leave
empty.

`upsert-env` accepts any `KEY=VALUE` it is given, including an empty `VALUE`, and
reports no error when it writes one — so check the values in the same block that
writes them, where the check cannot drift away from the thing it protects:

```bash
_empty=""
for _k in GIT_WORK_NAME GIT_WORK_EMAIL GIT_WORK_SSH_KEY \
          GIT_WORK_GITHUB_HOST GIT_DEFAULT_BRANCH; do
  eval "_v=\${$_k:-}"
  [ -n "$_v" ] || _empty="${_empty:+$_empty }$_k"
done

_pers_set=""; _pers_blank=""
for _k in GIT_PERSONAL_NAME GIT_PERSONAL_EMAIL GIT_PERSONAL_SSH_KEY \
          GIT_PERSONAL_GITHUB_HOST; do
  eval "_v=\${$_k:-}"
  if [ -n "$_v" ]; then _pers_set="${_pers_set:+$_pers_set }$_k"
  else                 _pers_blank="${_pers_blank:+$_pers_blank }$_k"; fi
done

if [ -n "$_empty" ]; then
  printf 'REFUSING to write. Required and empty: %s\n' "$_empty"
elif [ -n "$_pers_set" ] && [ -n "$_pers_blank" ]; then
  printf 'REFUSING to write. The personal identity is half-filled.\n'
  printf '  set:   %s\n' "$_pers_set"
  printf '  blank: %s\n' "$_pers_blank"
  printf 'Fill the blanks, or clear all four to skip the personal identity.\n'
elif [ -n "$_pers_set" ] && [ -z "${GIT_PERSONAL_REPO_ROOT:-}" ]; then
  printf 'REFUSING to write. A personal identity is set but GIT_PERSONAL_REPO_ROOT is empty.\n'
  printf 'includeIf would have no gitdir: to match and Step 5 would write to /.gitconfig.\n'
  printf 'That value comes from backup-repos; set it there and source reimage.env again.\n'
else
  python3 bin/prepare-artifact-root.py \
    upsert-env \
    --env-file reimage.env \
    "GIT_WORK_NAME=$GIT_WORK_NAME" \
    "GIT_WORK_EMAIL=$GIT_WORK_EMAIL" \
    "GIT_WORK_SSH_KEY=$GIT_WORK_SSH_KEY" \
    "GIT_WORK_GITHUB_HOST=$GIT_WORK_GITHUB_HOST" \
    "GIT_DEFAULT_BRANCH=$GIT_DEFAULT_BRANCH" \
    "GIT_PERSONAL_NAME=$GIT_PERSONAL_NAME" \
    "GIT_PERSONAL_EMAIL=$GIT_PERSONAL_EMAIL" \
    "GIT_PERSONAL_SSH_KEY=$GIT_PERSONAL_SSH_KEY" \
    "GIT_PERSONAL_GITHUB_HOST=$GIT_PERSONAL_GITHUB_HOST" \
    "GIT_PERSONAL_GITHUB_HOSTNAME=$GIT_PERSONAL_GITHUB_HOSTNAME"
fi
```

Confirm what landed, rather than trusting the write:

```bash
grep -E '^(export )?GIT_(WORK|PERSONAL|DEFAULT)' reimage.env
```

Nothing checks these at 0a, and that is deliberate. The prerequisite recorder
asks what must be true *before* the phase starts; these are values the phase
itself records, so a row over them could only ever fail at entry — a scheduled
false alarm rather than a check. They are verified at the other end instead, by
`record-restore-exit.sh --runbook restore-git` in Step 9, which is also where the
all-or-nothing rule on the personal set is enforced against what actually landed
in the file.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 1 — Install Git and Confirm the Environment

Homebrew from Phase 10A is the install path. Confirm Git is available and no stale config is in the way:

```bash
brew install git
git --version
git config --global --list
```

Source the reimage environment for the rest of this runbook — Step 0c has just written the identity values into it:

```bash
source ./reimage.env
printf 'WORK: %s <%s>\n' "$GIT_WORK_NAME" "$GIT_WORK_EMAIL"
printf 'PERS: %s <%s>\n' "${GIT_PERSONAL_NAME:-<none>}" "${GIT_PERSONAL_EMAIL:-<none>}"
```

This is the read-back of what 0c wrote, from the file rather than from the shell that wrote it. A blank `WORK` field means the upsert did not land even though 0c's guard passed — check `reimage.env` directly before continuing. `PERS` printing `<none>` is correct on a Mac with no separate personal identity; the personal halves of Steps 3, 5 and 6 then do not apply.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Set Correct Permissions on Restored SSH Keys

The keys themselves were laid down by [[restore-access|restore-access.md]] in Phase 10B; this step only fixes permissions and verifies fingerprints. The SSH client refuses to use loose private keys.

```bash
source ./reimage.env

chmod 700 ~/.ssh
chmod 600 "$GIT_WORK_SSH_KEY"
chmod 644 "$GIT_WORK_SSH_KEY.pub"
chmod 600 "$GIT_PERSONAL_SSH_KEY"
chmod 644 "$GIT_PERSONAL_SSH_KEY.pub"
```

Verify the fingerprints match what GitHub has registered on each account:

```bash
ssh-keygen -lf "$GIT_WORK_SSH_KEY.pub"
ssh-keygen -lf "$GIT_PERSONAL_SSH_KEY.pub"
```

Compare each against the account it belongs to, signed in as that account. A browser holds one GitHub session per profile, so open the second account in a separate profile or a private window rather than assuming the settings page in front of you belongs to the account you mean. The work fingerprint is checked on `$GIT_WORK_GITHUB_HOST` and the personal one on `$GIT_PERSONAL_GITHUB_HOST`; nothing in the output above says which is which.

Getting that wrong is not a filing error. A public key can be registered on only one account per GitHub installation, so a personal key added to a work account on the same installation makes the personal account reject it with `Key is already in use` until it is removed from the other one — which reads as a broken key rather than a misplaced one, and sends people to a personal access token for a problem a token does not solve. Across separate installations, an Enterprise Server instance and `github.com`, the namespaces do not overlap and the same key can sit on both. Avoid that too: one private key that opens both your personal account and your employer's systems is a boundary worth keeping.

> [!warning] Pitfall
> Do not record the real expected fingerprints in this runbook or any committed markdown. Keep them in an approved encrypted backup or password manager and compare against the live output above.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Write `~/.ssh/config` with Dual Host Aliases

This step replaces `~/.ssh/config` wholesale. Phase 10B restored the pre-image file from the secrets DMG, so what sits on disk right now is the config from the erased Mac. Read it before it goes, and copy out by hand any `Host` block that is not one of the two identities below — a jump host, an internal GitLab, a second Enterprise instance, a standing `AddKeysToAgent` directive:

```bash
if [ -f ~/.ssh/config ]; then
  cat ~/.ssh/config
else
  printf 'No ~/.ssh/config on this Mac yet.\n'
fi
```

> [!warning] Pitfall
> The write below truncates the file. Any `Host` block it does not name is gone, and SSH reports nothing when it happens. The next connection to that host silently falls back to default key selection and fails, or authenticates as the wrong account — days later, far from this step, with nothing pointing back here.

`Host` is the name you type in a clone URL; `HostName` is where SSH actually connects. When the two identities live on different servers — a GitHub Enterprise instance and public GitHub — each `Host` names its own real server and neither needs an alias. When both accounts live on `github.com`, one `Host` name cannot carry two keys, so the non-default identity takes an alias: `Host` holds the alias, `HostName` holds the real server.

| | Direct host | Alias |
|---|---|---|
| `GIT_PERSONAL_GITHUB_HOST` | `github.com` | `github.com-personal` |
| `GIT_PERSONAL_GITHUB_HOSTNAME` | leave blank | `github.com` |
| Clone URL | `git@github.com:owner/repo.git` | `git@github.com-personal:owner/repo.git` |
| Key chosen by | where the repository sits on disk | the remote URL, independently per remote |
| What it costs | one repository with both a personal and a work remote sends the same key to both | every clone URL is non-canonical, and `gh repo clone` plus absolute submodule URLs emit the real host and bypass the alias |

Direct is the default, and is right whenever the two identities sit on different servers — different hostnames route themselves, and that includes a single repository holding a remote on each. The alias is for the one case direct cannot cover: both accounts on the *same* server, where one `Host` block can only carry one `IdentityFile`. Switching later costs one value here, a re-run of this step, and one `git remote set-url` per affected repository.

Write both blocks whatever you expect to use. Whether SSH is reachable at all is a property of the network rather than of this configuration, it can differ between the two identities, and it is not knowable until validation probes it. A `Host` block for an identity that turns out to need HTTPS costs nothing and is in place the moment the network changes.

Write the file:

```bash
source ./reimage.env

mkdir -p ~/.ssh

cat > ~/.ssh/config <<EOF
# Personal GitHub — used for repos under the personal repo root.
# Clone personal repos as: git@${GIT_PERSONAL_GITHUB_HOST}:username/repo.git
Host ${GIT_PERSONAL_GITHUB_HOST}
    HostName ${GIT_PERSONAL_GITHUB_HOSTNAME:-$GIT_PERSONAL_GITHUB_HOST}
    User git
    IdentityFile ${GIT_PERSONAL_SSH_KEY}
    IdentitiesOnly yes

# Work GitHub — default for all other repos.
Host ${GIT_WORK_GITHUB_HOST}
    HostName ${GIT_WORK_GITHUB_HOST}
    User git
    IdentityFile ${GIT_WORK_SSH_KEY}
    IdentitiesOnly yes
EOF

chmod 600 ~/.ssh/config
```

Confirm the file resolves the way SSH will actually read it. `ssh -G` prints the *effective* configuration after parsing, so it catches a value that looks right in the file but is not — an unexpanded `${GIT_WORK_GITHUB_HOST}` reads fine to the eye and is a literal hostname to SSH:

```bash
source ./reimage.env

ssh -G "git@${GIT_WORK_GITHUB_HOST}" | grep -iE '^(hostname|user|identityfile) '
ssh -G "git@${GIT_PERSONAL_GITHUB_HOST}" | grep -iE '^(hostname|user|identityfile) '
```

Each `hostname` must be the server you expect SSH to reach — the same name you asked for under the direct scheme, the real server under the alias scheme — and each `identityfile` must name that side's key. A `hostname` still reading `${...}` means the block was pasted as text rather than run, and the variables were never substituted — SSH lowercases the value, so it appears as `${git_work_github_host}` rather than the spelling in the file. Two different hosts resolving to the *same* `hostname` means both identities point at one server, which authenticates as whichever account owns the first key offered.

`IdentitiesOnly yes` is what makes the choice stick. Without it `ssh-agent` offers every loaded key in turn and the server accepts the first one it recognises, which may be the other account's.

Two things the parse above cannot tell you: whether anything you meant to carry across is still in the file, and whether SSH will read it at all. Check both:

```bash
grep -cE '^[[:space:]]*[Hh]ost[[:space:]]' ~/.ssh/config

stat -f '%Sp %N' ~/.ssh/config
```

The count is 2 with no extra hosts, and higher by exactly the number you copied back in from the file printed at the start of this step — a count of 2 after you saw four blocks means two were lost to the rewrite. The mode must read `-rw-------`; SSH refuses a config file any wider with `Bad owner or permissions` and falls back to defaults for every host in it.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Write the Global `~/.gitconfig`

Work identity is the global default; `includeIf` overrides it only inside the personal repo root.

This file is authored from `reimage.env`, not restored from the pre-image copy in `secrets-encrypted/git/`. Read that copy for reference, never as a source. A pre-image `~/.gitconfig` might have a debugging surface that accumulates: `http.sslverify = false` set during one afternoon's TLS problem disables verification for every HTTPS remote on the new Mac; a `gitdir:` path that moved makes `includeIf` match nothing, which Git reports as silence rather than an error; and a second `[user]` block overrides `email` while leaving the `name` above it in force, so commits go out under one account's name and the other's address. Authoring the file means each of those is a value you choose now rather than one you inherit.

The `[include]` at the top of the heredoc is what keeps this rewrite safe to repeat. Aliases, pager, signing keys, `git lfs install`'s filter block and every other preference belong in `~/.config/git/config.local`, which nothing in this runbook writes. Git ignores a missing include file silently, so the line is harmless before that file exists. Its position matters: first in the file means the identity below always wins over anything the overlay sets, and the `includeIf` further down still wins over both.

`cat >` truncates `~/.gitconfig`, and [[restore-access|restore-access.md]] Step 7 may have written `http.sslCAInfo` into it pointing at the combined corporate CA bundle. The block below reads that value before the rewrite and puts it back after, so writing the identity cannot silently undo the trust configuration every HTTPS remote depends on. Nothing here needs to know the bundle path — `restore-access` stays its only owner.

```bash
source ./reimage.env

SAVED_CA_INFO="$(git config --global --get http.sslCAInfo 2>/dev/null || true)"

cat > ~/.gitconfig <<EOF
[include]
    path = ~/.config/git/config.local

[credential]
    helper = osxkeychain

[user]
    name = ${GIT_WORK_NAME}
    email = ${GIT_WORK_EMAIL}

[includeIf "gitdir:${GIT_PERSONAL_REPO_ROOT%/}/"]
    path = ${GIT_PERSONAL_REPO_ROOT%/}/.gitconfig

[init]
    defaultBranch = ${GIT_DEFAULT_BRANCH:-main}
EOF

if [ -n "$SAVED_CA_INFO" ]; then
  git config --global http.sslCAInfo "$SAVED_CA_INFO"
fi
```

Validate the global identity resolves, and that the CA bundle survived the rewrite:

```bash
git config --global user.email
git config --global --get http.sslCAInfo
```

The first returns `$GIT_WORK_EMAIL`. The second returns the bundle path if Step 7 of `restore-access` set one, and nothing at all if it did not — an empty result is only correct on a Mac with no corporate TLS interception.

Git ignores an `include` or `includeIf` whose file is missing and reports nothing, so a path typed wrong here surfaces later as the wrong author address rather than as an error. Confirm both directives carry the paths they should:

```bash
source ./reimage.env

git config --global --get-all include.path

git config --global --get-regexp '^includeif\.'
```

The first prints `~/.config/git/config.local`. The second prints one `includeif.gitdir:...` key whose path is `$GIT_PERSONAL_REPO_ROOT` with a trailing slash, and whose value is the override file under that root. Neither file exists yet, and that is correct — the overlay is seeded in Step 6 and the override written in Step 5. What is being checked here is that the directives point where they were meant to, while the values are still in the shell that wrote them.

> [!bug] Troubleshooting
> If that check comes back empty on a Mac that *does* sit behind corporate TLS interception, or an internal Enterprise Server host later refuses to verify, see [[#An internal Enterprise Server host fails TLS verification|An internal Enterprise Server host fails TLS verification]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Write the Personal-Root .gitconfig Override

This file activates only for repositories under `$GIT_PERSONAL_REPO_ROOT`. It changes the identity *and* pins the personal SSH key via `core.sshCommand`, so even if `~/.ssh/config` were misconfigured, personal repos would still send the right key. That pin is per repository, not per remote: `-F /dev/null` also stops SSH reading `~/.ssh/config` at all, so a repository under this root that gains a second remote on the work host sends the personal key there too. Which is a judgment call rather than a fault; the mechanics, and what it takes to make one repository serve both accounts properly, are in [[#One Repository, Two Remotes|One Repository, Two Remotes]].

The pin governs SSH only. A remote on an `https://` URL never invokes `ssh`, so `core.sshCommand` is inert for it and the key it names is never offered — those remotes authenticate from the credential helper instead. Identity is unaffected either way, because `includeIf` matches on the repository's path and knows nothing about protocol.

The trailing `cat` is not decoration. Git ignores a missing include file silently, so if this write does not happen the only symptom is the wrong author address surfacing two steps later in Step 7 — reading the file back here is what turns that into an immediate failure:

```bash
source ./reimage.env

mkdir -p "$GIT_PERSONAL_REPO_ROOT"

cat > "$GIT_PERSONAL_REPO_ROOT/.gitconfig" <<EOF
[user]
    name = ${GIT_PERSONAL_NAME}
    email = ${GIT_PERSONAL_EMAIL}
[core]
    sshCommand = ssh -i ${GIT_PERSONAL_SSH_KEY} -F /dev/null
EOF

cat "$GIT_PERSONAL_REPO_ROOT/.gitconfig"
```

The `cat` must echo real values. An empty name or email means `reimage.env` did not load — the block was run from somewhere other than the repository root — and the file was written with the identity blank rather than not written at all, which Git will happily include.

`-F /dev/null` prevents `core.sshCommand` from loading any other SSH config, keeping the override clean and predictable.

Validate the conditional include fires from inside a personal repo:

```bash
source ./reimage.env

if [ -z "${GIT_PERSONAL_REPO_ROOT:-}" ]; then
  printf 'ERROR: GIT_PERSONAL_REPO_ROOT is not set in reimage.env. backup-repos.md Step 1 records it.\n'
elif [ ! -d "$GIT_PERSONAL_REPO_ROOT" ]; then
  printf 'ERROR: GIT_PERSONAL_REPO_ROOT is %s, which does not exist.\n' "$GIT_PERSONAL_REPO_ROOT"
else
  scratch="$(mktemp -d "$GIT_PERSONAL_REPO_ROOT/.identity-check.XXXXXX")"
  ( cd "$scratch" && git init -q && git config --show-origin user.email )
  rm -rf "$scratch"
fi
```

`--show-origin` names the file the value came from, which is the whole question here. Expect `file:$GIT_PERSONAL_REPO_ROOT/.gitconfig` followed by `$GIT_PERSONAL_EMAIL`. An origin of `~/.gitconfig` with a work address means the include did not fire — either the override file is missing, or the `gitdir:` pattern does not match this path. Without `--show-origin` those two causes look identical.

The `cd` is inside a subshell and there is no `cd ~`, so the shell you are typing in never leaves the repository root. That matters for more than tidiness: a directory-scoped environment loader such as `direnv` unloads `reimage.env` the moment you leave, which empties `$GIT_PERSONAL_REPO_ROOT` and makes the cleanup on the next line silently skip. `direnv: unloading` printed by this block is that unload happening inside the subshell, and is expected. The guards exist for the same reason — with no root set, a scratch directory would be created at the filesystem root, and `git init` would otherwise run in whatever directory you happened to be standing in.

`mktemp -d` names the scratch repository rather than a fixed path. A fixed name cannot be removed safely: `mkdir -p` succeeds silently on a directory that already exists, so a real repository of that name would be written into and then deleted by a step that only reads a value. If a run is interrupted before the `rm`, a `.identity-check.*` directory is left under the personal root — remove it, because the Phase 11B audit counts any `.git` under a clone root as a repository.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 6 — Seed the Local Preferences Overlay

`~/.gitconfig` holds identity and routing, and this runbook rewrites it in full every time it runs. Everything else you care about — aliases, pager, `pull.rebase`, `fetch.prune`, diff and merge tools, `user.signingkey` and `commit.gpgsign`, `url.insteadOf` rewrites, and the `[filter "lfs"]` block `git lfs install` writes — lives in `~/.config/git/config.local` instead, which nothing here writes or truncates. Step 4 already wired the `[include]` that loads it, so this step only creates the file and puts your preferences back.

Never put `user.name`, `user.email` or `includeIf` in this file. Identity has one owner, and a second copy of it here is how a stale address outlives the runbook that was supposed to replace it.

Create the directory and the file:

```bash
mkdir -p ~/.config/git

touch ~/.config/git/config.local
```

The pre-image `~/.gitconfig` in `secrets-encrypted/git/` is the reference for what to carry over. Read it, take the preference sections, and leave the identity sections behind. A minimal starting point:

```bash
cat > ~/.config/git/config.local <<'EOF'
[alias]
    st = status -sb
    lg = log --oneline --graph --decorate

[pull]
    rebase = true

[fetch]
    prune = true
EOF
```

Confirm the include resolves and that identity did not follow the preferences across:

```bash
git config --show-origin --get-regexp '^(alias|pull|fetch)\.'

git config --show-origin user.email
```

The first lists your preferences with `~/.config/git/config.local` as their origin; nothing listed means the file is empty or the include is missing. The second must still report `~/.gitconfig` or the personal-root override, never `config.local`.

If you use `git lfs`, re-run `git lfs install` after this step rather than hand-copying its filter block — it writes the block itself and knows which paths this Git build expects.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 7 — Validate Both Identities

Test each host directly. Expect both to ask about host authenticity before they greet you. `known_hosts` was seeded in Phase 10B from the `~/.ssh/config` restored off the image, and this runbook has since replaced that file with different `Host` names, so the names being connected to now were never probed. An authenticity prompt is not an authentication failure — it is the first of two questions, and the greeting answers the second.

Answer it deliberately rather than typing `yes`. Each host has its own source of truth:

- **An internal Enterprise Server host** verifies against the pre-image `known_hosts` staged under `secrets-encrypted/ssh/` on the artifact drive. Mount the image and run `ssh-keygen -lf` against that file — a match means the key survived the reimage unchanged. The `known_hosts` on this Mac proves nothing once a prompt has been accepted, because it returns the value that acceptance just stored.
- **`github.com`** verifies against the fingerprints GitHub publishes in its own documentation. Paste the fingerprint at the prompt instead of typing `yes`: SSH compares what you paste against what the server offered and refuses on mismatch, so the answer carries the check. Typing back the value the prompt displayed carries none.

Where neither source is to hand, answer `no`. Nothing is lost — the command is re-runnable, and an unverified `yes` is the one thing here that cannot be undone by re-running it.

Run one identity at a time. Each command can stop on an authenticity prompt or stall on a blocked port, and stacking them means the line below becomes the answer typed into the prompt above it — so they are separate blocks, and each output belongs to one host.

Which block to use is per identity, and one of each is a normal configuration: use the SSH block for an identity whose remotes are `git@` URLs, and the HTTPS block for one that had to move to HTTPS.

Validate the work identity over SSH:

```bash
source ./reimage.env

ssh -T "git@${GIT_WORK_GITHUB_HOST}"
```

Validate the personal identity over SSH:

```bash
source ./reimage.env

ssh -T "git@${GIT_PERSONAL_GITHUB_HOST}"
```

Past the prompt, each greets you as the matching GitHub account — the work host as the work account, the personal host as the personal one. A greeting naming the *wrong* account means the two `Host` blocks are routing to the same server or the same key. `ssh_dispatch_run_fatal: Operation timed out` is a third outcome and a different problem entirely: the TCP connection was made and the SSH session then stalled, which is a network device interfering rather than anything about keys or identity.

**Where an identity is on HTTPS, use the two blocks below in place of that identity's `ssh -T`.** An `https://` remote never invokes `ssh`, so `ssh -T` reports on a path those remotes do not take — it can fail while every push works, or succeed while none of them do. The equivalent questions are which credential is stored for the host, and whether it reaches a repository only that account can read.

Read the stored credential:

```bash
source ./reimage.env

printf 'protocol=https\nhost=%s\n' "${GIT_PERSONAL_GITHUB_HOSTNAME:-$GIT_PERSONAL_GITHUB_HOST}" \
  | git credential-osxkeychain get \
  | grep '^username='
```

No output means nothing is stored yet and the first push will prompt for a username and a token. A `username=` line naming the personal account means a credential is present, which is not the same as it being the right one: GitHub authenticates the token and ignores the username sent alongside it, so a token belonging to another account authenticates as that account whatever this line says.

Confirm what the credential actually reaches. Name a **private** repository only the intended account can read — a public one proves nothing, because it answers without any credential at all:

```bash
PRIVATE_REPO="https://replace-with-host/replace-with-owner/replace-with-private-repo.git"

if GIT_TERMINAL_PROMPT=0 git ls-remote "$PRIVATE_REPO" >/dev/null 2>&1; then
  printf 'reachable — the stored credential has access\n'
else
  printf 'not reachable — no credential, the wrong account, or the token lacks access to this repository\n'
fi
```

`GIT_TERMINAL_PROMPT=0` is what keeps this from hanging: without it, a missing credential turns the check into an interactive username prompt rather than a result.

That pair proves access rather than naming the account, which is as far as the base system reaches — `gh` arrives in Phase 12. The account name itself is confirmed from the other end, by the token's *Last used* timestamp on its settings page, or by the author line on a pushed commit once one exists.

> [!bug] Troubleshooting
> If either host stalls or the connection is closed without a greeting, see [[#SSH is blocked on this network|SSH is blocked on this network]].

> [!bug] Troubleshooting
> If one host authenticates and the other returns `Permission denied (publickey)`, see [[#`ssh -T` returns "Permission denied (publickey)" for one host but not the other|`ssh -T` returns "Permission denied (publickey)" for one host but not the other]].

Spot-check the work root. Run this from the repository root like every other block here — the block enters `$GIT_WORK_REPO_ROOT` itself, so your working directory does not need to be there and should not be, because `source ./reimage.env` resolves against this checkout. No work repository is cloned yet, since Phase 11B does that after this phase, so the block makes a scratch repository under the root and reads the identity from inside it. The value it prints is the one that applies at `$GIT_WORK_REPO_ROOT`, not the one that applies where your shell is standing:

```bash
source ./reimage.env

if [ -z "${GIT_WORK_REPO_ROOT:-}" ]; then
  printf 'ERROR: GIT_WORK_REPO_ROOT is not set in reimage.env. backup-repos.md Step 1 records it.\n'
elif [ ! -d "$GIT_WORK_REPO_ROOT" ]; then
  printf 'ERROR: GIT_WORK_REPO_ROOT is %s, which does not exist.\n' "$GIT_WORK_REPO_ROOT"
else
  scratch="$(mktemp -d "$GIT_WORK_REPO_ROOT/.identity-check.XXXXXX")"
  ( cd "$scratch" && git init -q && git config --show-origin user.email )
  rm -rf "$scratch"
fi
```

Expect one line: an origin of `~/.gitconfig` and `$GIT_WORK_EMAIL`. This path is outside the personal root, so the global default applies and `includeIf` must not fire — an origin pointing at the personal-root file here means the `gitdir:` pattern is too broad.

> [!warning] Pitfall
> `mktemp -d` is what keeps this safe to run. A fixed scratch name such as `$GIT_WORK_REPO_ROOT/test` cannot be created safely: `mkdir -p` succeeds silently when the directory already exists, so a real repository of that name would be written into and then deleted by a step whose only job is to read a value. `mktemp -d` cannot collide with anything you own, so the `rm -rf` only ever removes what the block just made.

Spot-check the personal root the same way. Where a real repository already sits under `$GIT_PERSONAL_REPO_ROOT`, `git config --show-origin user.email` inside it answers this without a scratch repository at all; the block covers the case where nothing is cloned there yet:

```bash
source ./reimage.env

if [ -z "${GIT_PERSONAL_REPO_ROOT:-}" ]; then
  printf 'ERROR: GIT_PERSONAL_REPO_ROOT is not set in reimage.env. backup-repos.md Step 1 records it.\n'
elif [ ! -d "$GIT_PERSONAL_REPO_ROOT" ]; then
  printf 'ERROR: GIT_PERSONAL_REPO_ROOT is %s, which does not exist.\n' "$GIT_PERSONAL_REPO_ROOT"
else
  scratch="$(mktemp -d "$GIT_PERSONAL_REPO_ROOT/.identity-check.XXXXXX")"
  ( cd "$scratch" && git init -q && git config --show-origin user.email )
  rm -rf "$scratch"
fi
```

Expect an origin of `$GIT_PERSONAL_REPO_ROOT/.gitconfig` and `$GIT_PERSONAL_EMAIL`. A work address means the override is missing or the `includeIf` path does not match — Git ignores a missing include file silently, so this check is what catches it.

Both blocks print `direnv: unloading` on a Mac using direnv. That is the subshell leaving this checkout, and it is expected. It does mean nothing inside the parentheses can reference a `reimage.env` value, so keep the subshell to `git` calls that read configuration already on disk.

Do not move on until every spot-check prints the expected value. A silent mismatch here lands in commit history later.

Each block removes its own scratch repository. If one is interrupted between `mktemp` and `rm`, a `.identity-check.*` directory survives — remove it. The Phase 11B repository audit discovers repositories with `find <root> -type d -name .git`, so an abandoned scratch repo in a clone root is counted as a real one by that audit and by every comparison built on it. The name is deliberately self-identifying for exactly that reason.

> [!bug] Troubleshooting
> If the personal spot-check prints the work identity, see [[#`git config user.email` returns the wrong identity inside `$GIT_PERSONAL_REPO_ROOT`|`git config user.email` returns the wrong identity inside `$GIT_PERSONAL_REPO_ROOT`]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 8 — Compare Restored State Against Captured Inventories

Step 0b recorded what the machine looked like before this phase wrote anything,
and the pre-image captures recorded what it looked like before the erase. This
step is where both earn their keep.

**1. Capture the after-state.** The pair to Step 0b — same script, same runbook,
the other point:

```bash
./bin/record-restore-state.sh --runbook restore-git --point after --dry-run
./bin/record-restore-state.sh --runbook restore-git --point after
```

`after` is latest-wins, so re-running it after a late fix replaces the earlier
capture rather than being ignored — the opposite of `before`, which is
first-wins because the earliest observation is the one that caught the untouched
machine.

**2. Compare against the captured inventories.** This reads `08-git.txt` from
the pre-image system inventory, which recorded the Git configuration of the
machine that was erased:

```bash
./bin/compare-restored-state.sh --runbook restore-git --dry-run
./bin/compare-restored-state.sh --runbook restore-git
```

> [!warning] Pitfall
> **`http.sslverify` is the row to read here, and this is the first time it
> means anything.** Under `restore-access` it reported `correctly dropped`
> because `~/.gitconfig` did not exist yet — nothing was reviewed and left out,
> the file was simply absent. This phase writes that file, so the verdict is now
> real. `**CARRIED FORWARD**` means the pre-image `sslverify = false` came back
> and TLS verification is off for every Git HTTPS remote. Remove it with
> `git config --global --unset http.sslverify`, and scope any genuine exemption
> to one host rather than all of them.

`Git identity email set` is a presence row, not a value comparison: the capture
holds two `user.email` lines because this is a dual-identity setup, so comparing
the live global address against one of them would report a confident mismatch on
a correctly configured machine. Which identity applies where is what Step 7
validated.

**3. Join the two recordings.** `delta` is a third point on the state recorder.
It walks nothing — it joins the official before-state and after-state and records
what this phase changed on disk:

```bash
./bin/record-restore-state.sh --runbook restore-git --point delta --dry-run
./bin/record-restore-state.sh --runbook restore-git --point delta
```

Expect `~/.gitconfig` as **added** or **content changed**, `~/.ssh/config` as
**content changed** — Step 3 rewrites it wholesale — and the personal-root
override as **added**. **removed** is the verdict to read twice: this phase
writes configuration, and should not be deleting anything.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 9 — Close Out the Exit Criteria

Step 0a recorded whether this phase was allowed to start. This step records
whether it finished. Skip it and nothing anywhere says so — a question that gets
asked days later, when the answer is no longer reconstructable.

```bash
./bin/record-restore-exit.sh --runbook restore-git --dry-run
./bin/record-restore-exit.sh --runbook restore-git
```

Read the rows rather than the exit status. It records `PASS`, `WARN`, `FAIL` and
`TODO`, and a `TODO` row is a question only you can answer — not a failure, and
not a pass either. **Both identities validated** is the one that stays open until
you close it, and it asks about each identity on the transport its remotes
actually use. Neither transport can be graded from here: `ssh -T` fails
identically for an unregistered key and for the wrong key, and an HTTPS
credential authenticates as the token's owner whatever username is stored beside
it.

Confirm both boundary records landed. One file answers whether the phase both
started and finished:

```bash
sed -n '1,40p' "$REIMAGE_ARTIFACT_ROOT/reimaged-system/boundaries/MANIFEST.md"
```

You are looking for a `restore-git-entry-*` row and a `restore-git-exit-*` row.
An entry with no exit is the signature of a phase that was walked but never
closed out.

With both recorded, continue to `restore-repos.md`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---


## Decisions

The commands do X; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Whether the restored SSH keys are still the current identity or a rotated-out prior key. | Depends on rotation history the artifact drive does not carry. If unsure, generate a new key and register it upstream rather than restoring an old one. |
| Which protocol each identity uses. | SSH keeps identity routing in this runbook's hands and is unaffected by TLS interception, so it is preferred where it works. Whether it works is a property of the network, can differ between the two identities, and can change when you move between networks. Where SSH is blocked, that identity's remotes use HTTPS with a personal access token; `includeIf` still supplies the right author either way. Troubleshooting carries the switch. |
| Whether a repository under `$GIT_PERSONAL_REPO_ROOT` should also carry a work remote. | Keys can be routed per remote; authorship cannot — one commit carries one name and email to both. Either one address is verified on both accounts, or one side's commits arrive unattributed, or the two are really two repositories. Supplemental Reference walks the configuration for each. |
| Whether to reinstate `git-together` and `alias git=git-together`. | Legacy workaround; only worth it if the workflow still uses paired commits. See Supplemental Reference. |
| Which repositories are worth re-cloning right now versus later. | Depends on immediate work priorities; this runbook is deliberately silent about the list. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Five failures here either span more than one step or have a fix long enough to break a step's flow. Each is reached from a callout in the step that surfaces it.

[[#Table of Contents|⬆ Back to Table of Contents]]

### `ssh -T` returns "Permission denied (publickey)" for one host but not the other

The failing side's key is either missing, has the wrong permissions, or the fingerprint no longer matches what GitHub has registered. Check each in order:

```bash
source ./reimage.env
test -f "$GIT_WORK_SSH_KEY" && ls -l "$GIT_WORK_SSH_KEY"
test -f "$GIT_PERSONAL_SSH_KEY" && ls -l "$GIT_PERSONAL_SSH_KEY"
ssh-keygen -lf "$GIT_WORK_SSH_KEY.pub"
ssh-keygen -lf "$GIT_PERSONAL_SSH_KEY.pub"
```

If the file is missing, restore it from the encrypted secrets DMG the way Phase 10B does, then redo the `chmod` fixes in Step 2. If the fingerprint no longer matches GitHub, rotate: generate a new key, register it, and update `reimage.env`.

[[#Step 7 — Validate Both Identities|⮕ Continue to Step 7 — Validate Both Identities]]

### `git config user.email` returns the wrong identity inside `$GIT_PERSONAL_REPO_ROOT`

Almost always the `includeIf` path is missing the trailing slash. Re-read `~/.gitconfig` and confirm the line reads exactly:

```ini
[includeIf "gitdir:${GIT_PERSONAL_REPO_ROOT%/}/"]
```

Without the trailing slash, the include may not fire for nested repos. Re-run Step 4.

[[#Step 7 — Validate Both Identities|⮕ Continue to Step 7 — Validate Both Identities]]

### `config.local` is being silently ignored

Git does not read `config.local` automatically — it is loaded by the `[include]` block at the top of `~/.gitconfig`, which Step 4 writes. Confirm the block is there and that its `path` matches where the file actually is:

```bash
git config --get-all include.path

ls -l ~/.config/git/config.local
```

An `[include]` naming a file that does not exist is ignored in silence, which is the same symptom as a file whose settings are being overridden. Check the file exists before assuming precedence is the problem.

[[#Step 7 — Validate Both Identities|⮕ Continue to Step 7 — Validate Both Identities]]

### SSH is blocked on this network

Two symptoms, one cause. `ssh_dispatch_run_fatal: Connection to <address> port 22: Operation timed out` means TCP connected and the SSH session then stalled mid-handshake. `Connection closed by <address> port 443` against GitHub's alternate endpoint means an inspecting proxy expecting TLS saw an SSH banner and dropped the connection. Both are a network device between you and the host, and neither is fixable from `~/.ssh/config`.

This is per-identity. A corporate network commonly permits SSH to an internal Enterprise Server over its own tunnel while blocking it to the public internet, so the work host greets you and the personal one times out. Confirm which side is affected before changing anything — one working host proves the keys and the config are sound.

Where SSH is genuinely unavailable for an identity, that identity's remotes use HTTPS with a personal access token. Identity itself does not change: `includeIf` matches on the repository's path and is indifferent to protocol, so commits still carry the right name and address.

Point the remote at HTTPS and let the credential helper store the token:

```bash
git remote set-url origin https://github.com/OWNER/REPO.git

git config --global credential.helper

git push
```

The middle command must print `osxkeychain`. The push then prompts once for a username and a password — the password is the **token**, not the account password, which GitHub no longer accepts for Git operations. macOS stores it after that and does not ask again.

Never put the token in the remote URL. A `https://user:token@host/...` remote works and writes the token in plaintext into `.git/config`, where it survives into backups and into the next artifact capture.

If the push fails on certificate verification rather than credentials, the problem is the CA bundle and not the token:

```bash
git config --global --get http.sslCAInfo
```

An empty result on a Mac behind a TLS-inspecting proxy means the trust work in Phase 10B did not finish. Fix that rather than reaching for `http.sslverify=false`, which disables verification for every HTTPS remote on the machine.

To confirm which credential was actually used, and that it is a token rather than something a browser flow left behind:

```bash
printf 'protocol=https\nhost=github.com\n' | git credential-osxkeychain get | grep '^username='
```

The account name it prints is the one the push authenticated as. The token's own *Last used* timestamp on the account's settings page is the only confirmation that comes from the server rather than from this Mac.

[[#Step 8 — Compare Restored State Against Captured Inventories|⮕ Continue to Step 8 — Compare Restored State Against Captured Inventories]]

### An internal Enterprise Server host fails TLS verification

`git` over HTTPS to an internal Enterprise Server reports a certificate problem — `SSL certificate problem: unable to get local issuer certificate`, or a `server certificate verification failed`. This is a debugging path, not a configuration option: no `reimage.env` key turns it on, and none of the steps above write it.

**Check whether the exemption is still needed before reaching for one.** [[restore-access|restore-access.md]] Step 7 puts the corporate root into the CA bundle and points Git at it, so a host that failed to verify pre-image often verifies now. Confirm the bundle is actually wired up first:

```bash
git config --global --get http.sslCAInfo
git ls-remote "https://<internal-host>/<org>/<repo>.git" >/dev/null && echo verified
```

An empty first line on a Mac behind corporate TLS interception is the real fault — Step 7 of `restore-access` never ran, or ran and did not write. Fix that rather than exempting the host.

**If the host genuinely does not verify**, scope the exemption to that one host and nothing else:

```bash
git config --global "http.https://<internal-host>/.sslVerify" false
```

Never `git config --global http.sslverify false`. That disables verification for every HTTPS remote, it is what the pre-image machine had set, and `record-restore-exit.sh --runbook restore-git` records a `FAIL` on *TLS verification left on* when it finds it — the row exists because this phase is the one that could carry it forward. Remove a global one with `git config --global --unset http.sslverify`.

The skip is a workaround, not the goal. The durable fix is to trust the internal CA — `security add-trusted-cert` into the login keychain, or an MDM trust profile — and then drop the per-host exemption so verification is on everywhere again.

[[#Step 5 — Write the Personal-Root .gitconfig Override|⮕ Continue to Step 5 — Write the Personal-Root .gitconfig Override]]

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### One Repository, Two Remotes

A repository under `$GIT_PERSONAL_REPO_ROOT` that also pushes to the work host crosses both identities at once. Two things decide what happens, they are decided at different moments, and only one of them is per-remote.

| | Decided | Per-remote? |
|---|---|---|
| **Authentication** — which key is offered, which account you are | at push time, from the remote URL's host | yes |
| **Authorship** — the name and email inside the commit | at `git commit`, before any remote is involved | no |

Push transfers objects that already exist. A commit pushed to both remotes is the same object with the same SHA and the same author line, so no remote configuration can give it a different author on one side.

**Fixing the authentication half.** The personal-root override pins one key for the whole repository, and `-F /dev/null` stops SSH consulting `~/.ssh/config` at all, so the work remote is offered the personal key with no `Host` block able to correct it. Drop the pin in that one repository and hostname routing comes back:

```bash
git config --unset core.sshCommand

git config --get core.sshCommand
```

The second command printing nothing is the confirmation. Each remote is then matched to its `Host` block by the hostname in its URL, and each gets its own key. This is local to the repository — the override still applies to every other repository under the personal root.

An alias is needed here only when both remotes live on the *same* server. Different hostnames route themselves; two accounts on one hostname cannot, because a single `Host` block carries a single `IdentityFile`. That is the case the `GIT_PERSONAL_GITHUB_HOST` / `GIT_PERSONAL_GITHUB_HOSTNAME` pair exists for, and it is set once in Step 0c rather than per repository.

**Why a verified email is the whole of the authorship half.** GitHub decides who a commit belongs to by matching its author email against the verified emails on an account. Nothing else is consulted — not the SSH key that pushed it, not the account that owns the repository.

| | Author email verified on that account | Not verified there |
|---|---|---|
| Push | succeeds | succeeds |
| Commit page shows | your avatar, linked to your profile | the raw name and email, no link |
| Contribution graph | counts | does not count |
| Blame and pull-request authorship | attributed to you | shows as an outside author |

So the failure is attribution, not rejection — unless the server enables an author-email push rule, which is opt-in and uncommon. That is why the symptom is usually noticed socially rather than technically: commits keep landing, and colleagues start using the name on them.

Three ways to resolve it, in order of how well they hold up:

- **Verify one address on both accounts.** Add the address you commit with as a second verified email on the other account. One authorship then satisfies both, and nothing in this runbook changes. Best where policy allows it.
- **Pin the repository to one identity.** Where only one side's attribution matters, set it locally and accept that the other side sees an outside author:

    ```bash
    git config user.email "the-address-that-should-own-these-commits"

    git config user.name "The matching name"

    git config --show-origin user.email
    ```

    The origin must read `.git/config` for the pin to be in effect; a repository-local value beats both the global file and the `includeIf` override.
- **Split the repository.** Two accounts that must each own their own commits are two repositories with a shared upstream. Configuration cannot make one commit carry two authors, and arrangements that appear to are rewriting history on one side.

Set both `user.name` and `user.email` together when you pin. Setting only the email leaves the name from the layer above in force, which produces commits carrying one account's name and the other's address — correct enough to pass every check and wrong in the one place people read.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Optional Maintenance — Update All Local Repos

Once several repos are cloned back under `$GIT_WORK_REPO_ROOT` and `$GIT_PERSONAL_REPO_ROOT`, use this to rebase-pull all of them at once instead of doing it repo by repo. This is a maintenance helper, not a one-time restore requirement.

```bash
source ./reimage.env

for repo_root in "$GIT_WORK_REPO_ROOT" "$GIT_PERSONAL_REPO_ROOT"; do
  [[ -d "$repo_root" ]] || continue
  find "$repo_root" -maxdepth 3 -type d -name ".git" | while read -r gitdir; do
    repo="$(dirname "$gitdir")"
    printf '\n== %s ==\n' "$repo"
    git -C "$repo" pull -r || echo "  -> pull failed, check manually"
  done
done
```

Review failures manually — do not force-push or discard local changes to make this loop succeed.

### Optional — git-together Legacy Notes

The pre-image environment used `git-together` with:

```bash
alias git=git-together
```

Plus an Apple silicon workaround using an x86 Homebrew under `/usr/local`:

```bash
alias ibrew='arch -x86_64 /usr/local/bin/brew'
ibrew install pivotal/tap/git-together
```

Treat this as legacy. Prefer a current install path via the normal Apple silicon Homebrew if the tool is still needed at all. Do not re-enable `alias git=git-together` until confirming `git-together` installs and works correctly on the reimaged Mac.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- anchors linked from other files were preserved; no heading was renamed;
- each top-level section ends with a single "Back to Table of Contents" link,
  except Troubleshooting, whose back-link sits under its intro and whose routed
  symptom subsections stay out of the Table of Contents.
-->
