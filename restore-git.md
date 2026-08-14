[[reimaging-guide#Phase 9 — Restore Git|← Back to Mac Reimaging Guide]]

# Restore Git

**Last updated:** 2026-08-13

Restore the Git identity plumbing on the reimaged Mac so both work and personal GitHub accounts route automatically based on where a repository lives on disk. This runbook wires up the dual-identity `~/.gitconfig` (work as default, `includeIf` override under the personal repo root), lays down the matching `~/.ssh/config` host aliases, validates both identities, and leaves you with a `git clone` template that Phase 9B ([[restore-repos|restore-repos.md]]) then applies at scale against the pre-image repository audit. It does not enumerate a repo list, drive a clone loop, or restore preserved local branches or stashes — that carry-forward work belongs to [[restore-repos|restore-repos.md]].

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#Identity Design|Identity Design]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Install Git and Confirm the Environment|Step 1 — Install Git and Confirm the Environment]]
    - [[#Step 2 — Set Correct Permissions on Restored SSH Keys|Step 2 — Set Correct Permissions on Restored SSH Keys]]
    - [[#Step 3 — Write ~/.ssh/config with Dual Host Aliases|Step 3 — Write ~/.ssh/config with Dual Host Aliases]]
    - [[#Step 4 — Write the Global ~/.gitconfig|Step 4 — Write the Global ~/.gitconfig]]
    - [[#Step 5 — Write the Personal-Root .gitconfig Override|Step 5 — Write the Personal-Root .gitconfig Override]]
    - [[#Step 6 — Optionally Wire the XDG Local Config|Step 6 — Optionally Wire the XDG Local Config]]
    - [[#Step 7 — Validate Both Identities|Step 7 — Validate Both Identities]]
    - [[#Step 8 — Apply the Clone Pattern to Re-Clone Repositories|Step 8 — Apply the Clone Pattern to Re-Clone Repositories]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Optional Maintenance — Update All Local Repos|Optional Maintenance — Update All Local Repos]]
    - [[#Optional — git-together Legacy Notes|Optional — git-together Legacy Notes]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Restore the identity and routing plumbing that lets both work and personal Git operations succeed on the reimaged Mac without manual profile switching. Get the machine to the point where a `git clone` command uses the right SSH key and stamps commits with the right author automatically, based only on which directory the clone lands in.

This runbook owns:

```text
the global ~/.gitconfig with work identity as default and includeIf for the personal repo root
the personal-root .gitconfig override with core.sshCommand pinning the personal key
the optional ~/.config/git/config.local XDG include
~/.ssh/config with dual host aliases (work and personal), IdentitiesOnly yes
permissions on restored SSH keys and ~/.ssh/config
validating that both identities route correctly end-to-end
the git clone command template used for re-cloning repositories
```

It does not own:

```text
restoring SSH key files from the encrypted secrets DMG — Phase 8B (restore-access)
capturing branches, uncommitted work, stashes, local-only commits, and chosen kept ignored files pre-image — Phase 2C (backup-repos)
laying that carry-forward material back into re-cloned repos post-image — Phase 9B (restore-repos)
enumerating which repositories to re-clone or driving a clone loop — Phase 9B (restore-repos)
the fractogenesis-toolkit checkout itself — already installed in Phase 5 by bootstrap.sh, not re-cloned here
IDE-specific repo state (IntelliJ project files, VS Code workspace) — Phase 10 (restore-intellij.md, restore-apps.md)
Docker container/image restore — Phase 10 (restore-docker.md)
```

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
| Work identity | The default identity: `$GIT_WORK_NAME` / `$GIT_WORK_EMAIL`, using `$GIT_WORK_SSH_KEY`, cloned via the `$GIT_WORK_GITHUB_HOST` alias. Applies to any repo not under `$GIT_PERSONAL_REPO_ROOT`. |
| Personal identity | The override: `$GIT_PERSONAL_NAME` / `$GIT_PERSONAL_EMAIL`, using `$GIT_PERSONAL_SSH_KEY`, cloned via the `$GIT_PERSONAL_GITHUB_HOST` alias. Applies only inside `$GIT_PERSONAL_REPO_ROOT`. |
| `includeIf gitdir:...` | A Git config directive that pulls in another config file only when the current repo's `.git` directory lives under a specific path. How the personal identity activates without manual switching. |
| Host alias | An `~/.ssh/config` `Host` entry (e.g. `github-personal`) that maps to `HostName github.com` but forces a specific `IdentityFile`. How the SSH key gets routed without manual switching. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path this runbook reads or writes is defined here, once.

This runbook is manual and does not run a fractogenesis-toolkit entrypoint:

```text
$FRACTOGENESIS_HOME/bin/    # no primary script — this runbook is executed by hand
```

Input material laid down by earlier phases (Phase 8B):

```text
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/ssh/    # SSH keys, mounted from all-secrets-*.dmg during restore-access
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/git/    # pre-image ~/.gitconfig and ~/.config/git/ (reference only; not blindly copied)
```

Live targets this runbook writes on the reimaged Mac:

```text
~/.ssh/config                             # dual host aliases
~/.gitconfig                              # work-default with includeIf for personal
$GIT_PERSONAL_REPO_ROOT/.gitconfig        # personal identity override + core.sshCommand
~/.config/git/config                      # optional: XDG include that loads config.local
~/.config/git/config.local                # optional: XDG local overrides
$GIT_WORK_SSH_KEY, $GIT_PERSONAL_SSH_KEY  # permission-fixed, not restored here (Phase 8B owns restore)
```

Machine-local values consumed from `reimage.env`:

```text
$FRACTOGENESIS_HOME/reimage.env    # sourced at the start of every step below
```

### Environment Variables

The `reimage.env` values this runbook depends on. Paths and roots are resolved during `prepare-artifact-root.md`; the identity keys, host aliases, and default branch are recorded here in Step 1.

| Variable | Meaning |
|---|---|
| `FRACTOGENESIS_HOME` | Repository root for this toolkit checkout; where `reimage.env` lives. |
| `REIMAGE_ARTIFACT_ROOT` | Artifact root for this reimage event; used only for the input paths above. |
| `GIT_WORK_NAME` | Author name for the default work identity. |
| `GIT_WORK_EMAIL` | Author email for the default work identity. |
| `GIT_PERSONAL_NAME` | Author name for the personal identity override. |
| `GIT_PERSONAL_EMAIL` | Author email for the personal identity override. |
| `GIT_WORK_REPO_ROOT` | Directory holding work repos. Repos here inherit the global work identity. |
| `GIT_PERSONAL_REPO_ROOT` | Directory holding personal repos. `includeIf` fires only for repos under this path. |
| `GIT_WORK_GITHUB_HOST` | SSH host alias for work clones (typically `github.com`). |
| `GIT_PERSONAL_GITHUB_HOST` | SSH host alias for personal clones (typically `github-personal` or similar). |
| `GIT_WORK_SSH_KEY` | Absolute path to the work private key on disk (already restored in Phase 8B). |
| `GIT_PERSONAL_SSH_KEY` | Absolute path to the personal private key on disk (already restored in Phase 8B). |
| `GIT_DEFAULT_BRANCH` | Default branch name for `git init` (defaults to `master` when unset). |
| `GIT_INTERNAL_TLS_SKIP_HOST` | Optional. Internal Enterprise Server host (e.g. `github.internal.example`) whose TLS cert this Mac doesn't trust; scopes `sslVerify=false` to that host only. Unset = verification stays on everywhere. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 8B ([[restore-access|restore-access.md]]) is complete: the SSH keys referenced by `$GIT_WORK_SSH_KEY` and `$GIT_PERSONAL_SSH_KEY` exist on disk, the internal-CA trust is in the login keychain, and `hdiutil detach` cleaned up any mounted DMG.
- `reimage.env` is present, and you know your Git identity values (name, email, SSH key paths, host aliases). Step 1 records them into `reimage.env`; don't leave an identity value blank — a blank email silently produces a `.gitconfig` with an empty email.
- You know the SSH key fingerprints registered on GitHub for both accounts, or can look them up in a password manager. You will compare them in Step 2.

> [!bug] Troubleshooting
> `source ./reimage.env` failing with "no such file" almost always means you are not at the repository root. `pwd` should print `$FRACTOGENESIS_HOME`; `cd` there and try again.

### Confirm Your Intent

- Are you doing a **full first-time restore** (Steps 1 through 8 in order) or a **targeted rerun** of one file (e.g. re-writing `~/.ssh/config` after adding a third identity)? Both are safe; the difference is whether you also do Step 7's validation at the end.
- Do you use the **XDG local config** (`~/.config/git/config.local`) as your primary Git config, or `~/.gitconfig` only? If the answer is "only `~/.gitconfig`", skip Step 6 entirely — do not maintain both.
- Which **default branch name** does your workflow use? The runbook defaults to `master` because that is what the historical `reimage.env` shipped with; if your remote defaults to `main`, set `GIT_DEFAULT_BRANCH=main` when you record the values in Step 1.

> [!warning] Pitfall
> Do not commit `reimage.env` itself, restored `.gitconfig` files with real email addresses, or restored SSH keys. `.gitignore` should already exclude these; verify before your first commit after restore.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. `~/.ssh/config` goes down before the Git configs so `core.sshCommand` in Step 5 has a routing environment to reference; validation runs after both are written because the two paths of the trust chain can fail independently.

Every step begins with `source ./reimage.env` — Git config files do not reliably expand shell variables after they are written, so the heredocs below rely on values being resolved *in the current shell* at write time.

### Step 1 — Install Git and Confirm the Environment

Homebrew from Phase 8A is the install path. Confirm Git is available and no stale config is in the way:

```bash
brew install git
git --version
git config --global --list
```

Record your Git identity, SSH host aliases, and default branch in `reimage.env` — these are the values this runbook writes into `~/.gitconfig`, `~/.ssh/config`, and the personal-root override. Fill in the real values (leave the `GIT_PERSONAL_*` pair blank if you have no separate personal identity), then upsert them. The repository roots (`GIT_WORK_REPO_ROOT`, `GIT_PERSONAL_REPO_ROOT`) already carry over from the pre-image backup.

```bash
export GIT_WORK_NAME="Your Name"
export GIT_WORK_EMAIL="you@company.example"
export GIT_PERSONAL_NAME=""
export GIT_PERSONAL_EMAIL=""
export GIT_WORK_SSH_KEY="$HOME/.ssh/id_work"
export GIT_PERSONAL_SSH_KEY="$HOME/.ssh/id_personal"
export GIT_WORK_GITHUB_HOST="github.com"
export GIT_PERSONAL_GITHUB_HOST="github-personal"
export GIT_DEFAULT_BRANCH="master"

python3 bin/prepare-artifact-root.py \
  upsert-env \
  --env-file reimage.env \
  "GIT_WORK_NAME=$GIT_WORK_NAME" \
  "GIT_WORK_EMAIL=$GIT_WORK_EMAIL" \
  "GIT_PERSONAL_NAME=$GIT_PERSONAL_NAME" \
  "GIT_PERSONAL_EMAIL=$GIT_PERSONAL_EMAIL" \
  "GIT_WORK_SSH_KEY=$GIT_WORK_SSH_KEY" \
  "GIT_PERSONAL_SSH_KEY=$GIT_PERSONAL_SSH_KEY" \
  "GIT_WORK_GITHUB_HOST=$GIT_WORK_GITHUB_HOST" \
  "GIT_PERSONAL_GITHUB_HOST=$GIT_PERSONAL_GITHUB_HOST" \
  "GIT_DEFAULT_BRANCH=$GIT_DEFAULT_BRANCH"
```

Source the reimage environment for the rest of this runbook:

```bash
source ./reimage.env
```

Sanity-check that the identity keys resolved to non-empty values:

```bash
printf 'WORK: %s <%s>\n' "$GIT_WORK_NAME" "$GIT_WORK_EMAIL"
printf 'PERS: %s <%s>\n' "$GIT_PERSONAL_NAME" "$GIT_PERSONAL_EMAIL"
```

If any of the four fields prints blank, fill in `reimage.env` before continuing.

### Step 2 — Set Correct Permissions on Restored SSH Keys

The keys themselves were laid down by [[restore-access|restore-access.md]] in Phase 8B; this step only fixes permissions and verifies fingerprints. The SSH client refuses to use loose private keys.

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

> [!warning] Pitfall
> Do not record the real expected fingerprints in this runbook or any committed markdown. Keep them in an approved encrypted backup or password manager and compare against the live output above.

### Step 3 — Write `~/.ssh/config` with Dual Host Aliases

Write the SSH host aliases so `git@$GIT_PERSONAL_GITHUB_HOST` and `git@$GIT_WORK_GITHUB_HOST` route to the right keys automatically:

```bash
source ./reimage.env

mkdir -p ~/.ssh

cat > ~/.ssh/config <<EOF
# Personal GitHub — used for repos under the personal repo root.
# Clone personal repos as: git@${GIT_PERSONAL_GITHUB_HOST}:username/repo.git
Host ${GIT_PERSONAL_GITHUB_HOST}
    HostName github.com
    User git
    IdentityFile ${GIT_PERSONAL_SSH_KEY}
    IdentitiesOnly yes

# Work GitHub — default for all other repos.
Host ${GIT_WORK_GITHUB_HOST}
    HostName github.com
    User git
    IdentityFile ${GIT_WORK_SSH_KEY}
    IdentitiesOnly yes
EOF

chmod 600 ~/.ssh/config
```

> [!note]
> `IdentitiesOnly yes` prevents SSH from trying other loaded keys before the specified one. Without it, `ssh-agent` may silently fall back to the wrong key and authenticate as the wrong identity.

### Step 4 — Write the Global `~/.gitconfig`

Work identity is the global default; `includeIf` overrides it only inside the personal repo root.

```bash
source ./reimage.env

cat > ~/.gitconfig <<EOF
[credential]
    helper = osxkeychain

[user]
    name = ${GIT_WORK_NAME}
    email = ${GIT_WORK_EMAIL}

[includeIf "gitdir:${GIT_PERSONAL_REPO_ROOT%/}/"]
    path = ${GIT_PERSONAL_REPO_ROOT%/}/.gitconfig

[init]
    defaultBranch = ${GIT_DEFAULT_BRANCH:-master}
EOF

# Optional: skip TLS verification for ONE internal Enterprise Server host whose
# certificate this Mac doesn't trust. Leave GIT_INTERNAL_TLS_SKIP_HOST unset to
# keep verification on everywhere (the secure default).
if [ -n "${GIT_INTERNAL_TLS_SKIP_HOST:-}" ]; then
  git config --global "http.https://${GIT_INTERNAL_TLS_SKIP_HOST}/.sslVerify" false
fi
```

Validate the global identity resolves:

```bash
git config --global user.email
# Should return the value of: $GIT_WORK_EMAIL
```

> [!note]
> If the pre-image config had more than one `[user]` block, Git used the lower matching value globally. The layout above keeps a single `[user]` block on purpose — work is the deliberate global default, and the override lives in a separate file that only fires under the personal root.

> [!note]
> Skipping TLS verification is a workaround, not the goal. The cleaner long-term fix is to **trust the internal Enterprise Server's CA certificate** — import it into the login keychain with `security add-trusted-cert`, or deploy it via an MDM trust profile — then leave `GIT_INTERNAL_TLS_SKIP_HOST` unset so verification stays on everywhere. Scope the skip to a single host only while you don't yet trust that CA; never disable verification globally.

### Step 5 — Write the Personal-Root .gitconfig Override

This file activates only for repositories under `$GIT_PERSONAL_REPO_ROOT`. It changes the identity *and* pins the personal SSH key via `core.sshCommand`, so even if `~/.ssh/config` were misconfigured, personal repos would still send the right key.

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
```

`-F /dev/null` prevents `core.sshCommand` from loading any other SSH config, keeping the override clean and predictable.

Validate the conditional include fires from inside a personal repo:

```bash
source ./reimage.env

mkdir -p "$GIT_PERSONAL_REPO_ROOT/test-repo"
cd "$GIT_PERSONAL_REPO_ROOT/test-repo"
git init
git config user.email
# Should return the value of: $GIT_PERSONAL_EMAIL

cd ~
rm -rf "$GIT_PERSONAL_REPO_ROOT/test-repo"
```

### Step 6 — Optionally Wire the XDG Local Config

Skip this step if `~/.gitconfig` is your only Git config. Only do it if you intentionally use `~/.config/git/config` as the primary path and `config.local` for machine-specific overlays.

Git reads `~/.config/git/config` automatically under the XDG spec, but `config.local` is only read if it is explicitly included. Wire it up:

```bash
mkdir -p ~/.config/git
```

Add an include block to `~/.config/git/config` if not already present:

```ini
[include]
    path = ~/.config/git/config.local
```

Then write `config.local` from `reimage.env`:

```bash
source ./reimage.env

cat > ~/.config/git/config.local <<EOF
# ~/.config/git/config.local
# Local private Git configuration — loaded via ~/.config/git/config include

[credential]
    helper = osxkeychain

[user]
    name = ${GIT_WORK_NAME}
    email = ${GIT_WORK_EMAIL}

[includeIf "gitdir:${GIT_PERSONAL_REPO_ROOT%/}/"]
    path = ${GIT_PERSONAL_REPO_ROOT%/}/.gitconfig

[init]
    defaultBranch = ${GIT_DEFAULT_BRANCH:-master}
EOF

# Optional: same host-scoped skip, written into config.local. Unset the variable
# to keep verification on everywhere (the secure default).
if [ -n "${GIT_INTERNAL_TLS_SKIP_HOST:-}" ]; then
  git config --file ~/.config/git/config.local "http.https://${GIT_INTERNAL_TLS_SKIP_HOST}/.sslVerify" false
fi
```

> [!warning] Pitfall
> If `~/.gitconfig` and `~/.config/git/config.local` both exist with conflicting settings, Git merges them in load order with later values winning. Keep them consistent or consolidate to one — the XDG path is preferred on a fresh system, `~/.gitconfig` is the legacy path. Do not have them fight each other.

### Step 7 — Validate Both Identities

Test both host aliases directly against GitHub:

```bash
source ./reimage.env

ssh -T "git@${GIT_WORK_GITHUB_HOST}"
# Expected: authenticated as the work GitHub account.

ssh -T "git@${GIT_PERSONAL_GITHUB_HOST}"
# Expected: authenticated as the personal GitHub account.
```

Spot-check from an actual work repo directory:

```bash
source ./reimage.env

cd "$GIT_WORK_REPO_ROOT/<any-work-repo>"
git config user.email
# Should return the value of: $GIT_WORK_EMAIL
```

Spot-check from inside the personal repo root using a throwaway repo:

```bash
source ./reimage.env

mkdir -p "$GIT_PERSONAL_REPO_ROOT/test"
cd "$GIT_PERSONAL_REPO_ROOT/test"
git init
git config user.email
# Should return the value of: $GIT_PERSONAL_EMAIL

cd ~
rm -rf "$GIT_PERSONAL_REPO_ROOT/test"
```

Do not move on until every spot-check prints the expected value. A silent mismatch here will land in commit history later.

### Step 8 — Apply the Clone Pattern to Re-Clone Repositories

Use the templates below to re-clone repositories one at a time as you need them, or hand the completed identity plumbing off to [[restore-repos|restore-repos.md]] (Phase 9B) which reads the pre-image repository audit and emits ready-to-run `git clone` commands at scale.

**Work repos** — use the work GitHub host directly and clone into `$GIT_WORK_REPO_ROOT`:

```bash
source ./reimage.env

cd "$GIT_WORK_REPO_ROOT"
git clone "git@${GIT_WORK_GITHUB_HOST}:<work-org>/<repo>.git"
```

**Personal repos** — use the personal host alias and clone into `$GIT_PERSONAL_REPO_ROOT`:

```bash
source ./reimage.env

cd "$GIT_PERSONAL_REPO_ROOT"
git clone "git@${GIT_PERSONAL_GITHUB_HOST}:<personal-username>/<repo>.git"
```

Once cloned in the right directory, identity and key selection are automatic for every subsequent `git push`, `git pull`, and `git fetch`.

> [!warning] Pitfall
> If a personal repo was cloned with the default GitHub host by mistake, `includeIf` still sets the personal email, but `~/.ssh/config` may pick the default (work) key — this pushes commits authored as personal but sent over the work key. Fix by updating the remote:
> ```bash
> git remote set-url origin "git@${GIT_PERSONAL_GITHUB_HOST}:<personal-username>/<repo>.git"
> ```

> [!note]
> Preserved local-only material from Phase 2C ([[backup-repos|backup-repos.md]]) — stashes, local-only branches, chosen kept ignored files — is restored by Phase 9B ([[restore-repos|restore-repos.md]]), which reads the pre-image `repos.tsv` and staged ignored files and emits reviewable clone + rsync commands. Do not chase that reconciliation manually here.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The commands do X; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Whether the restored SSH keys are still the current identity or a rotated-out prior key. | Depends on rotation history the artifact drive does not carry. If unsure, generate a new key and register it upstream rather than restoring an old one. |
| Which config path to make canonical: `~/.gitconfig` or `~/.config/git/config` + `config.local`. | Both work; letting them fight each other silently breaks identity. Pick one and be consistent. |
| Whether to reinstate `git-together` and `alias git=git-together`. | Legacy workaround; only worth it if the workflow still uses paired commits. See Supplemental Reference. |
| Which repositories are worth re-cloning right now versus later. | Depends on immediate work priorities; this runbook is deliberately silent about the list. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### `ssh -T` returns "Permission denied (publickey)" for one host but not the other

The failing side's key is either missing, has the wrong permissions, or the fingerprint no longer matches what GitHub has registered. Check each in order:

```bash
source ./reimage.env
test -f "$GIT_WORK_SSH_KEY" && ls -l "$GIT_WORK_SSH_KEY"
test -f "$GIT_PERSONAL_SSH_KEY" && ls -l "$GIT_PERSONAL_SSH_KEY"
ssh-keygen -lf "$GIT_WORK_SSH_KEY.pub"
ssh-keygen -lf "$GIT_PERSONAL_SSH_KEY.pub"
```

If the file is missing, restore it from the DMG via [[restore-access|restore-access.md]] and rerun Step 2. If the fingerprint no longer matches GitHub, rotate: generate a new key, register it, and update `reimage.env`.

### `git config user.email` returns the wrong identity inside `$GIT_PERSONAL_REPO_ROOT`

Almost always the `includeIf` path is missing the trailing slash. Re-read `~/.gitconfig` and confirm the line reads exactly:

```ini
[includeIf "gitdir:${GIT_PERSONAL_REPO_ROOT%/}/"]
```

Without the trailing slash, the include may not fire for nested repos. Re-run Step 4.

### `config.local` is being silently ignored

Git does not read `config.local` automatically. It must be pulled in from `~/.config/git/config` or `~/.gitconfig` via an `[include]` block. Confirm the include exists; see Step 6.

### After a clean run, `git remote -v` on a personal repo points at the default GitHub host

The repo was cloned with the default host instead of `$GIT_PERSONAL_GITHUB_HOST`. Update the remote — no need to re-clone:

```bash
git remote set-url origin "git@${GIT_PERSONAL_GITHUB_HOST}:<personal-username>/<repo>.git"
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

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
