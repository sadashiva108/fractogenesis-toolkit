# fractogenesis-toolkit

Runbooks and scripts for reimaging a Mac (Windows/Linux/other-device reimage workflows may join this repo later — see [Future Workflows](#future-workflows)). Split out from a personal reference vault into its own repo because restore-phase steps need to be runnable on a freshly erased Mac that hasn't cloned anything yet — see [Why a Separate Repo](#why-a-separate-repo).

---

## Table of Contents

- [Quickstart](#quickstart)
- [Getting the Toolkit onto a Freshly Reimaged Mac](#getting-the-toolkit-onto-a-freshly-reimaged-mac)
  - [Primary Path — curl](#primary-path--curl)
  - [Fallback Path — Jump Drive](#fallback-path--jump-drive)
- [Repository Structure](#repository-structure)
- [Why a Separate Repo](#why-a-separate-repo)
- [Naming Conventions](#naming-conventions)
- [Keeping the Jump Drive Current](#keeping-the-jump-drive-current)
- [Future Workflows](#future-workflows)
- [Status](#status)

---

## Quickstart

Start at [`reimaging-guide.md`](reimaging-guide.md) — it sequences every phase of the reimage and links out to each individual runbook.

If you're picking this up mid-reimage on a freshly erased Mac with no local checkout yet, skip straight to [Getting the Toolkit onto a Freshly Reimaged Mac](#getting-the-toolkit-onto-a-freshly-reimaged-mac).

---

## Getting the Toolkit onto a Freshly Reimaged Mac

Right after Erase All Content and Settings, there's no repo, no SSH key, and no `git` (installing it triggers an Xcode Command Line Tools popup and a large download). Two ways to get this repo's contents onto the machine before any of that exists:

### Primary Path — curl

Once the Mac has Wi-Fi (available as early as the Intune/O365 enrollment step), fetch and run the bootstrap script directly — no `git`, no auth, no prior setup required:

```bash
curl -fsSL <gist-or-raw-url-here>/bootstrap.sh | bash
```

This installs the toolkit to `$HOME/reimage-toolkit`.

### Fallback Path — Jump Drive

If there's no network yet (captive portal, delayed profile push, etc.), use a small dedicated USB stick prepared ahead of time — see [Keeping the Jump Drive Current](#keeping-the-jump-drive-current) for how the stick's contents get built and refreshed.

```bash
bash /Volumes/<stick-name>/bootstrap.sh /Volumes/<stick-name>/fractogenesis-toolkit.tar.gz
```

`bootstrap.sh` supports both paths with the same logic: no argument fetches from GitHub via curl; a tarball path installs from that file directly, checksum-verified first. See the script's own header comment for details.

---

## Repository Structure

```text
fractogenesis-toolkit/
├── README.md
├── bootstrap.sh                  # the one file fetched before anything else exists
├── reimaging-guide.md            # start here — sequences every phase
├── <phase-runbooks>.md           # one runbook per phase, verb-first names
├── references/                  # strategy guides, file references, evidence indexes
├── templates/                   # sign-off templates, confirmation forms, cheatsheets
├── bin/                          # entrypoint scripts — run directly, one per runbook
└── .internal/                    # sourced-only helpers — never run directly
    ├── apps/
    ├── git/
    └── templates/                # config fragments sourced by .internal scripts
```

- **`bin/`** — anything a person runs directly. Verb-first names matching their runbook (`backup-apps.sh` ↔ `backup-apps.md`).
- **`.internal/`** — anything only ever `source`d by another script, never run standalone. No verb-prefix requirement here — the directory itself is the "don't run this" signal. Grouped into subfolders (`apps/`, `git/`) where several helpers serve one concern.
- **`.share/`** — reserved for scripts genuinely reused across repos (this one, a future backup-workflow repo, a future performance-investigation repo, etc.). Empty for now; see [Future Workflows](#future-workflows).

---

## Why a Separate Repo

This used to live inside a general-purpose personal reference vault (Obsidian-based, markdown-only). Two problems with that:

1. **Obsidian is a documentation tool, not a script host.** Mixing scripts into a markdown vault meant treating it as a Swiss Army knife it was never designed to be.
2. **Restore-phase scripts need to run before the vault is reachable again.** SSH keys, Git identity, and the vault checkout itself are all things later phases of this workflow *restore* — so the tooling that does the restoring can't depend on already having them. A small, standalone, publicly-fetchable repo with no secrets in it sidesteps that chicken-and-egg problem entirely.

The original vault-hosted version of this workflow is left in place, untouched, as a fallback until this repo is proven out across a real reimage end to end.

---

## Naming Conventions

- Runbooks and their matching top-level script share a name (`backup-apps.md` ↔ `bin/backup-apps.sh`) — same tool, discoverable by one name from either direction.
- Runbook/script prefixes signal the action: `prepare-`, `backup-`, `capture-`, `restore-`, `stage-`, `create-`, `enroll-`, `validate-`.
- Nothing in this repo should require secrets or company-specific values to be useful on its own — machine-specific values belong in a local, untracked `reimage.env`, not in any committed file.

---

## Keeping the Jump Drive Current

```bash
bin/build-jump-drive-payload.sh /path/to/this/repo /path/to/output-dir
```

Produces a checksummed, versioned tarball (commit hash + build date baked in as `.toolkit-version`) suitable for copying onto the fallback jump drive alongside `bootstrap.sh`. Re-run this shortly before any reimage to keep the stick's contents current — the version stamp printed after install tells you at a glance how stale a given stick's copy is.

---

## Future Workflows

Scripts here are being kept parameterized (taking paths/targets as arguments rather than reaching into workflow-specific globals) where practical, so they can be pulled into other workflows later without a rewrite:

- A routine-backup workflow (not tied to a reimage event)
- A performance-investigation / diagnostics workflow
- A parallel reimage workflow for a second machine running CubeOS and Arch, plus an external Tails drive

None of these exist yet. When a script is genuinely needed by more than one of these, it moves into `.share/` (or a separate shared-toolkit repo, if the reuse is broad enough to warrant one) rather than being copy-pasted between repos.

---

## Status

Early and actively being restructured — file names, directory layout, and this README are all subject to change as the migration from the original reference-vault version completes.
