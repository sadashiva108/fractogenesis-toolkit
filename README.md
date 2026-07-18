# fractogenesis-toolkit

Runbooks and scripts for reimaging a Mac (Windows/Linux/other-device reimage workflows may join this repo later — see [Future Workflows](#future-workflows)). Split out from a personal reference vault into its own repo because restore-phase steps need to be runnable on a freshly erased Mac that hasn't cloned anything yet — see [Why a Separate Repo](#why-a-separate-repo).

---

## Table of Contents

- [Quickstart](#quickstart)
- [Repository Structure](#repository-structure)
- [Naming Conventions](#naming-conventions)
- [Future Workflows](#future-workflows)
- [Status](#status)

---

## Quickstart

Start at [`reimaging-guide.md`](./reimaging-guide.md) — it sequences every phase of the reimage and links out to each individual runbook.

If you're picking this up mid-reimage on a freshly erased Mac with no local checkout yet, see [`reimage-guide-access.md`](./reimage-guide-access.md).

---

## Repository Structure

```text
<repo-root>/
├── README.md
├── bootstrap.sh                  # the one file fetched before anything else exists
├── reimaging-guide.md            # start here — sequences every phase
├── reimage-guide-access.md       # Phase 4A — validate curl/jump-drive access before erasing
├── <phase-runbooks>.md           # one runbook per phase, verb-first names
├── references/
│   └── restore-strategy-guide.md # includes why the guide-access mechanism exists
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

## Naming Conventions

- Runbooks and their matching top-level script share a name (`backup-apps.md` ↔ `bin/backup-apps.sh`) — same tool, discoverable by one name from either direction.
- Runbook/script prefixes signal the action: `prepare-`, `backup-`, `capture-`, `restore-`, `stage-`, `create-`, `enroll-`, `validate-`.
- Nothing in this repo should require secrets or company-specific values to be useful on its own — machine-specific values belong in a local, untracked `reimage.env`, not in any committed file.

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
