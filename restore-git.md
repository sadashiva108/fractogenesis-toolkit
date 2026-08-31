[[reimaging-guide#Phase 11A — Restore Git|← Back to Mac Reimaging Guide]]

# Restore Git

**Last updated:** 2026-08-25

Restore the Git identity plumbing on the reimaged Mac so both work and personal GitHub accounts route automatically based on where a repository lives on disk. This runbook wires up the dual-identity `~/.gitconfig` (work as default, `includeIf` override under the personal repo root), lays down the matching `~/.ssh/config` host aliases, validates both identities, and leaves you with a `git clone` template that Phase 11B then applies at scale against the pre-image repository audit. It does not enumerate a repo list, drive a clone loop, or restore preserved local branches or stashes — that carry-forward work belongs to Phase 11B.

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
    - [[#Account Access — Tokens, 2FA, and Key Rotation|Account Access — Tokens, 2FA, and Key Rotation]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 0 — Record Prerequisites and the Before-State|Step 0 — Record Prerequisites and the Before-State]]
    - [[#Step 1 — Install Git and Confirm the Environment|Step 1 — Install Git and Confirm the Environment]]
    - [[#Step 2 — Set Correct Permissions on Restored SSH Keys|Step 2 — Set Correct Permissions on Restored SSH Keys]]
    - [[#Step 3 — Write `~/.ssh/config` with Dual Host Aliases|Step 3 — Write `~/.ssh/config` with Dual Host Aliases]]
    - [[#Step 4 — Write the Global `~/.gitconfig`|Step 4 — Write the Global `~/.gitconfig`]]
    - [[#Step 5 — Write the Personal-Root .gitconfig Override|Step 5 — Write the Personal-Root .gitconfig Override]]
    - [[#Step 6 — Optionally Wire the XDG Local Config|Step 6 — Optionally Wire the XDG Local Config]]
    - [[#Step 7 — Validate Both Identities|Step 7 — Validate Both Identities]]
    - [[#Step 8 — Compare Restored State Against Captured Inventories|Step 8 — Compare Restored State Against Captured Inventories]]
    - [[#Step 9 — Close Out the Exit Criteria|Step 9 — Close Out the Exit Criteria]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Optional Maintenance — Update All Local Repos|Optional Maintenance — Update All Local Repos]]
    - [[#Optional — git-together Legacy Notes|Optional — git-together Legacy Notes]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

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
| Work identity | The default identity: `$GIT_WORK_NAME` / `$GIT_WORK_EMAIL`, using `$GIT_WORK_SSH_KEY`, cloned via the `$GIT_WORK_GITHUB_HOST` alias. Applies to any repo not under `$GIT_PERSONAL_REPO_ROOT`. |
| Personal identity | The override: `$GIT_PERSONAL_NAME` / `$GIT_PERSONAL_EMAIL`, using `$GIT_PERSONAL_SSH_KEY`, cloned via the `$GIT_PERSONAL_GITHUB_HOST` alias. Applies only inside `$GIT_PERSONAL_REPO_ROOT`. |
| `includeIf gitdir:...` | A Git config directive that pulls in another config file only when the current repo's `.git` directory lives under a specific path. How the personal identity activates without manual switching. |
| Host entry | An `~/.ssh/config` `Host` block that forces a specific `IdentityFile` for one server. `Host` is the name you type; `HostName` is where SSH actually connects. When the two identities live on different servers — a GitHub Enterprise instance and public GitHub — each block names its own real host, and the two values must match or SSH connects to the wrong server. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path this runbook reads or writes is defined here, once.

This runbook is manual and does not run a fractogenesis-toolkit entrypoint:

```text
$FRACTOGENESIS_HOME/bin/    # no primary script — this runbook is executed by hand
```

Input material laid down by earlier phases (Phase 10B):

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
$GIT_WORK_SSH_KEY, $GIT_PERSONAL_SSH_KEY  # permission-fixed, not restored here (Phase 10B owns restore)
```

Machine-local values consumed from `reimage.env`:

```text
$FRACTOGENESIS_HOME/reimage.env    # sourced at the start of every step below
```

### Environment Variables

The `reimage.env` values this runbook depends on. Paths and roots are resolved during `prepare-artifact-root.md`; the identity keys, host aliases, and default branch are recorded here in Step 1.

| Variable | Meaning |
|---|---|
| `FRACTOGENESIS_HOME` | Repository root for this toolkit checkout; where `reimage.env` lives. Set by your shell startup / `.envrc`, not stored in `reimage.env`. |
| `REIMAGE_ARTIFACT_ROOT` | Artifact root for this reimage event; used only for the input paths above. |
| `GIT_WORK_NAME` | Author name for the default work identity. |
| `GIT_WORK_EMAIL` | Author email for the default work identity. |
| `GIT_PERSONAL_NAME` | Author name for the personal identity override. |
| `GIT_PERSONAL_EMAIL` | Author email for the personal identity override. |
| `GIT_WORK_REPO_ROOT` | Directory holding work repos. Repos here inherit the global work identity. |
| `GIT_PERSONAL_REPO_ROOT` | Directory holding personal repos. `includeIf` fires only for repos under this path. |
| `GIT_WORK_GITHUB_HOST` | Host SSH connects to for work clones — a GitHub Enterprise instance such as `github.example.com`, or `github.com`. Written as both `Host` and `HostName` in `~/.ssh/config`, so it must resolve. |
| `GIT_PERSONAL_GITHUB_HOST` | Host SSH connects to for personal clones, usually `github.com`. Written as both `Host` and `HostName`, so it must resolve. |
| `GIT_WORK_SSH_KEY` | Absolute path to the work private key on disk (already restored in Phase 10B). |
| `GIT_PERSONAL_SSH_KEY` | Absolute path to the personal private key on disk (already restored in Phase 10B). |
| `GIT_DEFAULT_BRANCH` | Default branch name for `git init` (defaults to `main` when unset). |
| `GIT_INTERNAL_TLS_SKIP_HOST` | Optional. Internal Enterprise Server host (e.g. `github.internal.example`) whose TLS cert this Mac doesn't trust; scopes `sslVerify=false` to that host only. Unset = verification stays on everywhere. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phase 10B ([[restore-access|restore-access.md]]) is complete: the SSH keys referenced by `$GIT_WORK_SSH_KEY` and `$GIT_PERSONAL_SSH_KEY` exist on disk, the internal-CA trust is in the login keychain, and `hdiutil detach` cleaned up any mounted DMG.
- `reimage.env` is present, and you know your Git identity values (name, email, SSH key paths, host aliases). Step 1 records them into `reimage.env`; don't leave an identity value blank — a blank email silently produces a `.gitconfig` with an empty email.
- You know the SSH key fingerprints registered on GitHub for both accounts, or can look them up in a password manager. You will compare them in Step 2.

> [!bug] Troubleshooting
> `source ./reimage.env` failing with "no such file" almost always means you are not at the repository root. `pwd` should print `$FRACTOGENESIS_HOME`; `cd` there and try again.

### Confirm Your Intent

- Are you doing a **full first-time restore** (Steps 1 through 8 in order) or a **targeted rerun** of one file (e.g. re-writing `~/.ssh/config` after adding a third identity)? Both are safe; the difference is whether you also do Step 7's validation at the end.
- Do you use the **XDG local config** (`~/.config/git/config.local`) as your primary Git config, or `~/.gitconfig` only? If the answer is "only `~/.gitconfig`", skip Step 6 entirely — do not maintain both.
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

> [!note]
> Every block in this runbook shows a `--dry-run` line above the real one. It
> prints the table and writes nothing. On **0b** that preview is worth more than
> anywhere else: `before` is a first-wins point, so the first capture recorded is
> the one that stays official, and a mistimed one cannot be replaced — only
> annotated with a pin explaining why it is wrong. Read the target list, confirm
> it describes a machine this phase has not touched, then record.

> [!warning] Pitfall
> **0b expires and 0a does not.** The prerequisite check is rerunnable at any
> point and costs nothing to repeat. The before-state is gone the moment Step 3
> rewrites `~/.ssh/config` — Step 3 replaces that file wholesale rather than
> appending to it — and Step 4 writes `~/.gitconfig`. Take 0b before Step 1.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 1 — Install Git and Confirm the Environment

Homebrew from Phase 10A is the install path. Confirm Git is available and no stale config is in the way:

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
export GIT_WORK_GITHUB_HOST="github.example.com"
export GIT_PERSONAL_GITHUB_HOST="github.com"
export GIT_DEFAULT_BRANCH="main"

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

> [!warning] Pitfall
> Do not record the real expected fingerprints in this runbook or any committed markdown. Keep them in an approved encrypted backup or password manager and compare against the live output above.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Write `~/.ssh/config` with Dual Host Aliases

Write the SSH host aliases so `git@$GIT_PERSONAL_GITHUB_HOST` and `git@$GIT_WORK_GITHUB_HOST` route to the right keys automatically:

```bash
source ./reimage.env

mkdir -p ~/.ssh

cat > ~/.ssh/config <<EOF
# Personal GitHub — used for repos under the personal repo root.
# Clone personal repos as: git@${GIT_PERSONAL_GITHUB_HOST}:username/repo.git
Host ${GIT_PERSONAL_GITHUB_HOST}
    HostName ${GIT_PERSONAL_GITHUB_HOST}
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

Each `hostname` must match the host you asked for, and each `identityfile` must name that side's key. A `hostname` still reading `${...}` means the block was pasted as text rather than run, and the variables were never substituted — SSH lowercases the value, so it appears as `${git_work_github_host}` rather than the spelling in the file. Two different hosts resolving to the *same* `hostname` means both identities point at one server, which authenticates as whichever account owns the first key offered.

> [!note]
> `IdentitiesOnly yes` prevents SSH from trying other loaded keys before the specified one. Without it, `ssh-agent` may silently fall back to the wrong key and authenticate as the wrong identity.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Write the Global `~/.gitconfig`

Work identity is the global default; `includeIf` overrides it only inside the personal repo root.

`cat >` truncates `~/.gitconfig`, and [[restore-access|restore-access.md]] Step 7 may have written `http.sslCAInfo` into it pointing at the combined corporate CA bundle. The block below reads that value before the rewrite and puts it back after, so writing the identity cannot silently undo the trust configuration every HTTPS remote depends on. Nothing here needs to know the bundle path — `restore-access` stays its only owner.

The last conditional scopes `sslVerify=false` to a single internal Enterprise Server host whose certificate this Mac does not trust. Leave `GIT_INTERNAL_TLS_SKIP_HOST` unset — that is the secure default — and set it only if Step 7 shows that host genuinely failing to verify.

```bash
source ./reimage.env

SAVED_CA_INFO="$(git config --global --get http.sslCAInfo 2>/dev/null || true)"

cat > ~/.gitconfig <<EOF
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

if [ -n "${GIT_INTERNAL_TLS_SKIP_HOST:-}" ]; then
  git config --global "http.https://${GIT_INTERNAL_TLS_SKIP_HOST}/.sslVerify" false
fi
```

Validate the global identity resolves, and that the CA bundle survived the rewrite:

```bash
git config --global user.email
git config --global --get http.sslCAInfo
```

The first returns `$GIT_WORK_EMAIL`. The second returns the bundle path if Step 7 of `restore-access` set one, and nothing at all if it did not — an empty result is only correct on a Mac with no corporate TLS interception.

> [!note]
> If the pre-image config had more than one `[user]` block, Git used the lower matching value globally. The layout above keeps a single `[user]` block on purpose — work is the deliberate global default, and the override lives in a separate file that only fires under the personal root.

> [!note]
> Skipping TLS verification is a workaround, not the goal. The cleaner long-term fix is to **trust the internal Enterprise Server's CA certificate** — import it into the login keychain with `security add-trusted-cert`, or deploy it via an MDM trust profile — then leave `GIT_INTERNAL_TLS_SKIP_HOST` unset so verification stays on everywhere. Scope the skip to a single host only while you don't yet trust that CA; never disable verification globally.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Write the Personal-Root .gitconfig Override

This file activates only for repositories under `$GIT_PERSONAL_REPO_ROOT`. It changes the identity *and* pins the personal SSH key via `core.sshCommand`, so even if `~/.ssh/config` were misconfigured, personal repos would still send the right key.

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
  echo "GIT_PERSONAL_REPO_ROOT is not set — run this from the repository root"
else
  mkdir -p "$GIT_PERSONAL_REPO_ROOT/test-repo"
  ( cd "$GIT_PERSONAL_REPO_ROOT/test-repo" && git init && git config --show-origin user.email )
  rm -rf "$GIT_PERSONAL_REPO_ROOT/test-repo"
fi
```

`--show-origin` names the file the value came from, which is the whole question here. Expect `file:$GIT_PERSONAL_REPO_ROOT/.gitconfig` followed by `$GIT_PERSONAL_EMAIL`. An origin of `~/.gitconfig` with a work address means the include did not fire — either the override file is missing, or the `gitdir:` pattern does not match this path. Without `--show-origin` those two causes look identical.

The `cd` is inside a subshell and there is no `cd ~`, so the shell you are typing in never leaves the repository root. That matters for more than tidiness: a directory-scoped environment loader such as `direnv` unloads `reimage.env` the moment you leave, which empties `$GIT_PERSONAL_REPO_ROOT` and makes the cleanup on the next line silently skip. The empty-variable branch exists for the same reason — with no root set, `mkdir -p "/test-repo"` and `cd` both fail, and `git init` would otherwise run in whatever directory you happened to be standing in.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

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

Then write `config.local` from `reimage.env`. The trailing conditional is the same host-scoped TLS skip as Step 4, written into this file instead; leave `GIT_INTERNAL_TLS_SKIP_HOST` unset to keep verification on everywhere.

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
    defaultBranch = ${GIT_DEFAULT_BRANCH:-main}
EOF

if [ -n "${GIT_INTERNAL_TLS_SKIP_HOST:-}" ]; then
  git config --file ~/.config/git/config.local "http.https://${GIT_INTERNAL_TLS_SKIP_HOST}/.sslVerify" false
fi
```

> [!warning] Pitfall
> If `~/.gitconfig` and `~/.config/git/config.local` both exist with conflicting settings, Git merges them in load order with later values winning. Keep them consistent or consolidate to one — the XDG path is preferred on a fresh system, `~/.gitconfig` is the legacy path. Do not have them fight each other.

> [!bug] Troubleshooting
> If values you wrote into `config.local` have no effect on `git config` output, see [[#`config.local` is being silently ignored|`config.local` is being silently ignored]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 7 — Validate Both Identities

Test each host directly. Each command should greet you as the matching GitHub account — the work host as the work account, the personal host as the personal one. A greeting naming the *wrong* account means the two `Host` blocks are routing to the same server or the same key:

```bash
source ./reimage.env

ssh -T "git@${GIT_WORK_GITHUB_HOST}"

ssh -T "git@${GIT_PERSONAL_GITHUB_HOST}"
```

> [!bug] Troubleshooting
> If one host authenticates and the other returns `Permission denied (publickey)`, see [[#`ssh -T` returns "Permission denied (publickey)" for one host but not the other|`ssh -T` returns "Permission denied (publickey)" for one host but not the other]].

Spot-check from inside the work repo root using a throwaway repo. No work repo is cloned yet — Phase 11B ([[restore-repos|restore-repos.md]]) does that, and it runs after this phase — so create a scratch repo rather than `cd`-ing into one that does not exist:

```bash
source ./reimage.env

if [ -z "${GIT_WORK_REPO_ROOT:-}" ]; then
  echo "GIT_WORK_REPO_ROOT is not set — run this from the repository root"
else
  mkdir -p "$GIT_WORK_REPO_ROOT/test"
  ( cd "$GIT_WORK_REPO_ROOT/test" && git init && git config --show-origin user.email )
  rm -rf "$GIT_WORK_REPO_ROOT/test"
fi
```

Expect an origin of `~/.gitconfig` and `$GIT_WORK_EMAIL`. This path is outside the personal root, so the global default applies and `includeIf` must not fire — an origin pointing at the personal-root file here means the `gitdir:` pattern is too broad.

Spot-check from inside the personal repo root using the same throwaway technique:

```bash
source ./reimage.env

if [ -z "${GIT_PERSONAL_REPO_ROOT:-}" ]; then
  echo "GIT_PERSONAL_REPO_ROOT is not set — run this from the repository root"
else
  mkdir -p "$GIT_PERSONAL_REPO_ROOT/test"
  ( cd "$GIT_PERSONAL_REPO_ROOT/test" && git init && git config --show-origin user.email )
  rm -rf "$GIT_PERSONAL_REPO_ROOT/test"
fi
```

Expect an origin of `$GIT_PERSONAL_REPO_ROOT/.gitconfig` and `$GIT_PERSONAL_EMAIL`. A work address means the override from Step 5 is missing or the `includeIf` path does not match — Git ignores a missing include file silently, so this check is what catches it.

Do not move on until every spot-check prints the expected value. A silent mismatch here will land in commit history later.

Each block removes its own throwaway repository. Confirm none survived — `ls -d "$GIT_WORK_REPO_ROOT"/test "$GIT_PERSONAL_REPO_ROOT"/test 2>/dev/null` should print nothing. A leftover is not cosmetic: [[backup-repos|backup-repos.md]] discovers repositories with `find <root> -type d -name .git`, so an abandoned scratch repo in a clone root is counted as a real one by the Phase 11B audit and every comparison built on it.

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
you close it: `ssh -T` fails identically for an unregistered key and for the
wrong key, so no script can tell the difference between the two.

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
| Which config path to make canonical: `~/.gitconfig` or `~/.config/git/config` + `config.local`. | Both work; letting them fight each other silently breaks identity. Pick one and be consistent. |
| Whether to reinstate `git-together` and `alias git=git-together`. | Legacy workaround; only worth it if the workflow still uses paired commits. See Supplemental Reference. |
| Which repositories are worth re-cloning right now versus later. | Depends on immediate work priorities; this runbook is deliberately silent about the list. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Four failures here either span more than one step or have a fix long enough to break a step's flow. Each is reached from a callout in the step that surfaces it.

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

Git does not read `config.local` automatically. It must be pulled in from `~/.config/git/config` or `~/.gitconfig` via an `[include]` block. Confirm the include exists; Step 6 writes it.

[[#Step 7 — Validate Both Identities|⮕ Continue to Step 7 — Validate Both Identities]]

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
