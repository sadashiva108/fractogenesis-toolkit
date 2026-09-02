[← Back to Mac Reimaging Guide](../reimaging-guide.md)

# Master Directory Reference

**Last Updated:** 2026-08-17

This is the consolidated `$REIMAGE_ARTIFACT_ROOT` directory map for the Mac reimage workflow.

It consolidates the artifact locations documented across the workflow — preparation, backup and staging, capture, validation, and post-image restore. Every runbook and reference below documents at least one path under `$REIMAGE_ARTIFACT_ROOT`; each group is alphabetical.

**Preparation**

- `prepare-artifact-root.md`

**Backup and staging**

- `backup-apps.md`
- `backup-home.md`
- `backup-intellij.md`
- `backup-repos.md`
- `create-secrets-dmg.md`
- `stage-certs-keychain.md`
- `stage-loose-secrets.md`

**Capture and evidence**

- `capture-managed-inventory.md`
- `capture-office-stability.md`
- `capture-performance-audit.md`
- `capture-system-inventory.md`
- `capture-toolkit-snapshot.md`
- `run-time-machine.md`

**Validation and sign-off**

- `reimage-prep-checks.md`
- `reimaged-system-checks.md`
- `verify-reimaged-system.md`

**Post-image restore**

- `enroll-and-stabilize.md`
- `restore-access.md`
- `restore-apps.md`
- `restore-docker.md`
- `restore-git.md`
- `restore-home.md`
- `restore-intellij.md`
- `restore-repos.md`
- `restore-runtime.md`

**Cross-cutting references**

- `references/backup-file-reference.md`
- `references/environment-variable-reference.md`
- `references/reimage-prep-evidence.md`
- `references/reimaged-system-evidence.md`
- `reimaging-scripts-guide.md`
- `references/restore-file-reference.md`

Use this file when you want one place to see the intended artifact layout without jumping between multiple phase guides.

> [!tip]
> The sections below use **collapsible Obsidian callouts**. Click the triangle beside each path to expand or collapse it.

---

## Table of Contents

- [[#Where Files Are Read From|Where Files Are Read From]]
- [[#Master Root Layout|Master Root Layout]]
- [[#Collapsible Directory Sections|Collapsible Directory Sections]]

---

## Where Files Are Read From

Some files exist in both `$REIMAGE_WORKSPACE_ROOT` and `$REIMAGE_ARTIFACT_ROOT`.
Which copy a script actually reads is not arbitrary — it follows from when the
file has to be readable and who owns its content. There are three categories.

**Machine-customized config — read from the workspace, never written to the
artifact root.**

| Directory | Template shipped at | Read from | Seeded by |
|---|---|---|---|
| `artifact-config/` | `.internal/templates/artifact-config/` | `$REIMAGE_WORKSPACE_ROOT/artifact-config/` | `prepare-artifact-root.py init-artifact-config` |
| `staged-certs/` | `.internal/templates/staged-certs/` | `$REIMAGE_WORKSPACE_ROOT/staged-certs/` | `stage-certs-keychain.sh init-staged-certs-config` |
| `intellij-review/` | none — generated from seed lists | `$REIMAGE_WORKSPACE_ROOT/intellij-review/` | `backup-apps.sh --init-intellij-review` |

These get copied or generated into the workspace once and are edited for this Mac.
The first two ship as generic templates with example paths and cannot live on the
artifact root because they are read *before it exists* — `EXPECTED_ARTIFACT_FOLDERS`
is what Phase 1 uses to create it. All three resolvers prefer the workspace copy.

`artifact-config/` and `staged-certs/` fall back to the committed templates and warn
when `REIMAGE_WORKSPACE_ROOT` is set but the directory is missing, because a silent
fallback means running against generic example targets.

`intellij-review/` differs on both counts, deliberately. There is no committed
template tier: both files are generated from the seed lists in
`.internal/apps/backup-intellij-state.sh`, so the script stays the single source of
the patterns and a stale committed copy cannot drift from it. And the fallback is
the artifact root rather than a template, which is the pre-existing behavior and
harmless — so it warns about nothing. The cost of skipping the workspace copy is
not a wrong run, only selections that die with the drive.

**Per-run generated files — written to and read from the artifact root.**

`gitignore-superset/` is the current example. `backup-repos.sh` resolves all of
its inputs from `$REIMAGE_ARTIFACT_ROOT/gitignore-superset/`. Three of those files
are operator-maintained rather than regenerated — `backup-exclude-list.txt`,
`secrets-patterns.txt`, and `gitignore-review-template.direct-nonsecret-recommended.txt`
— so the audit run seeds them from `.internal/templates/gitignore-superset/` on
first use and never overwrites them afterwards.

Workspace copies of these files are a **manual stash**, moved only by the `cp -p`
pairs in the runbook, so decisions survive a new artifact root. Nothing reads them
directly. Restore a stashed copy *before* the audit run and pass
`--preserve-selections`; restoring afterwards overwrites freshly generated content.

**Pre-root staging — workspace until the artifact root exists, then promoted.**

The filled IT confirmation is written to `$REIMAGE_WORKSPACE_ROOT/reimage-confirmation/`
and copied into the artifact root by Phase 1. Long-running performance and Office
evidence stages locally the same way. `record-enrollment.sh` falls back to
`$REIMAGE_WORKSPACE_ROOT/` when the drive is not mounted, creating the same
`restarts/` and `boundaries/` categories under it. In every case
the workspace is authoritative only until the artifact root is available; after
that the artifact root is.

**Adding a new file?** Ask when it must first be readable. Before the artifact root
exists, or hand-edited per machine → category one. Produced by a run and belonging
with that run's evidence → category two. Staged early and promoted once → category
three.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Master Root Layout

This tree shows the full superset of top-level directories that can appear
under `$REIMAGE_ARTIFACT_ROOT` across every phase in the workflow, including
situational phases that only apply for certain reimage reasons (such as a
performance or Office-stability symptom). A given reimage run may populate
some or all of them, depending on which situational phases apply. Child
directories are omitted here and shown instead in each directory's own
collapsible section below, consistent with every other top-level entry in
this reference.

```text
$REIMAGE_ARTIFACT_ROOT/
├── app-settings-backup/
├── gitignore-superset/
├── home-files-backup/
├── loose-secrets-reports/
├── managed-inventory/
├── office-stability/
├── performance-audit/
├── public-certs/
├── reimage-confirmation/
├── reimage-prep-checks/
├── reimaged-system/
├── repo-audit-reports/
├── secrets-encrypted/
├── size-audit-reports/
├── staged-ignored-files/
├── system-inventory/
├── time-machine/
└── toolkit-snapshot/
```

Not every run creates every folder immediately. Some folders are phase-specific, optional, or only appear when a related script or manual step is used.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Collapsible Directory Sections

> [!example]- `$REIMAGE_ARTIFACT_ROOT/app-settings-backup/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/app-settings-backup/
> ├── MANIFEST.md
> ├── candidate-review/
> │   └── app-backup-candidates-YYYYMMDD-HHMMSS/
> │       ├── app-backup-candidates.md
> │       ├── known-app-candidates.tsv
> │       ├── related-app-review.tsv
> │       └── raw/
> ├── chrome/
> │   ├── bookmarks_YYYYMMDD-HHMMSS.html
> │   ├── chrome-export-inventory-YYYYMMDD-HHMMSS.md
> │   └── README.md
> ├── claude/
> │   └── com.anthropic.claudefordesktop.plist
> ├── docker/
> │   ├── settings-store.json
> │   ├── daemon.json
> │   ├── contexts/
> │   ├── image-inventory.txt
> │   ├── container-inventory.txt
> │   └── compose-projects.txt
> ├── intellij/
> │   ├── IntelliJIdeaYYYY.N/
> │   │   ├── config-copy/
> │   │   └── scratches-and-consoles/
> │   ├── logs/
> │   │   ├── IntelliJIdeaYYYY.N/
> │   │   └── system-cache-not-copied.txt
> │   ├── manifests/
> │   ├── manual-settings-export/
> │   │   └── IntelliJ-settings-YYYYMMDD-HHMMSS.zip
> │   ├── project-metadata/
> │   ├── restore-notes/
> │   ├── secret-review/          # evidence copy; originals in the workspace
> │   │   ├── README.md
> │   │   ├── intellij-secret-review-template.txt
> │   │   └── intellij-plaintext-exclude-list.txt
> │   └── README.md
> ├── obsidian/
> │   ├── global-settings/
> │   └── vault-copy/
> ├── postman/
> │   ├── collections/
> │   ├── environments-redacted/
> │   ├── inventory/
> │   │   └── postman-vault-inventory-YYYYMMDD-HHMMSS.md
> │   └── README.md
> ├── raycast/
> │   ├── raycast-quicklinks-YYYYMMDD-HHMMSS.json
> │   ├── raycast-export-inventory-YYYYMMDD-HHMMSS.md
> │   └── README.md
> ├── terminal/
> │   ├── <profile-name>.terminal
> │   └── window-size-note.txt
> └── vscode/
>     ├── extensions.txt
>     └── user/
>         ├── keybindings.json
>         ├── profiles/
>         ├── settings.json
>         └── snippets/
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/gitignore-superset/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/gitignore-superset/
> ├── summary.txt
> ├── gitignore-files.tsv
> ├── gitignore-files-review.txt
> ├── gitignore-concatenated-with-sources.txt
> ├── gitignore-patterns-all.tsv
> ├── gitignore-patterns-all-review.txt
> ├── gitignore-patterns-superset.txt
> ├── gitignore-patterns-superset-with-counts.tsv
> ├── gitignore-pattern-sources.tsv
> ├── gitignore-pattern-sources-review.txt
> ├── gitignore-review-template.txt
> └── backup-exclude-list.txt
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/home-files-backup/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/home-files-backup/
> ├── home/
> │   ├── claude-artifacts/
> │   ├── claude-code/
> │   ├── Desktop/
> │   ├── Documents/
> │   ├── Movies/
> │   ├── Music/
> │   ├── Pictures/
> │   ├── scripts/
> │   └── config-files-backups/
> ├── dotfiles/
> │   ├── .bash_profile
> │   ├── .bashrc
> │   ├── .gitconfig
> │   ├── .shell_aliases.sh
> │   ├── .shell_common.sh
> │   ├── .shell_local.sh
> │   ├── .zshenv
> │   ├── .aliases
> │   ├── .exports
> │   ├── .functions
> │   ├── .zprofile
> │   ├── .zshrc
> │   ├── azure/
> │   ├── cf/
> │   ├── config/
> │   ├── copilot/
> │   │   ├── ide/
> │   │   ├── instructions/
> │   │   └── prompts/
> │   ├── dotfiles.falkor.d/
> │   ├── fiddler/
> │   └── kube/
> └── MANIFEST.md
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/loose-secrets-reports/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/loose-secrets-reports/
> ├── MANIFEST.md
> ├── content-scans/
> │   ├── MANIFEST.md
> │   ├── latest-run.txt
> │   └── runs/
> │       └── <context>-YYYYMMDD-HHMMSS/
> ├── findings-ledger.tsv
> ├── loose-secrets-index.md
> ├── official/
> │   └── <context>.txt
> ├── open-findings.md
> └── runs/
>     └── <context>-YYYYMMDD-HHMMSS/
>         ├── findings.tsv
>         └── loose-secrets-report.txt
> ```
>
> `<context>` is `pre-image` for the Phase 3B sweep and `pre-image-<label>` for a
> re-check. `content-scans/` is written by `backup-home.md` and keeps its own
> bespoke index rather than the shared one.

> [!example]- `$REIMAGE_ARTIFACT_ROOT/managed-inventory/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/managed-inventory/
> ├── MANIFEST.md                          # append-only index of completed runs
> ├── official/
> │   ├── pre-image.txt                     # → runs/pre-image-YYYYMMDD-HHMMSS
> │   └── post-image.txt                    # → runs/post-image-YYYYMMDD-HHMMSS
> └── runs/
>     ├── pre-image-YYYYMMDD-HHMMSS/
>     │   ├── 01-enrollment-status.txt
>     │   ├── 02-profiles-configuration.txt
>     │   ├── 03-installed-app-bundles.txt
>     │   ├── 04-installed-package-receipts.txt
>     │   ├── 05-background-managed-components.txt
>     │   ├── 06-managed-preference-payloads.txt
>     │   ├── 07-company-filter-pass.txt
>     │   └── MANIFEST.txt
>     └── post-image-YYYYMMDD-HHMMSS/
>         ├── 01-enrollment-status.txt
>         ├── 02-profiles-configuration.txt
>         ├── 03-installed-app-bundles.txt
>         ├── 04-installed-package-receipts.txt
>         ├── 05-background-managed-components.txt
>         ├── 06-managed-preference-payloads.txt
>         ├── 07-company-filter-pass.txt
>         └── MANIFEST.txt
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/office-stability/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/office-stability/
> ├── MANIFEST.md
> ├── official/
> │   ├── <phase>-office-stability-assessment.txt
> │   └── <phase>-office-stability-evidence.txt
> ├── runs/
> │   ├── <phase>-office-stability-assessment-YYYYMMDD-HHMMSS/
> │   │   ├── README.md
> │   │   ├── logs/
> │   │   │   ├── commands.log
> │   │   │   └── errors.log
> │   │   ├── office-stability-assessment.md
> │   │   ├── processes/
> │   │   │   └── outlook-onenote-process-transitions.txt
> │   │   ├── system/
> │   │   │   ├── autoupdate-office-events-tail.txt
> │   │   │   ├── install-log-office-events-tail.txt
> │   │   │   ├── office-bundle-status.txt
> │   │   │   └── office-crash-reports-after-marker.txt
> │   │   └── watcher/
> │   │       ├── latest-watcher-tail-800.txt
> │   │       ├── marker-timestamp.txt
> │   │       ├── watcher-installer-office-signals.txt
> │   │       └── watcher-running-processes.txt
> │   └── <phase>-office-stability-evidence-YYYYMMDD-HHMMSS/
> │       ├── 00-baseline-window.txt
> │       ├── 01-crash-reports-newer-than-marker.txt
> │       ├── 02-office-bundle-status.txt
> │       ├── 03-outlook-onenote-process-transitions.txt
> │       ├── 04-watcher-installer-office-signals.txt
> │       ├── 05-install-log-office-events-tail.txt
> │       ├── 06-autoupdate-office-events-tail.txt
> │       ├── 07-unified-log-office-since-marker.txt
> │       ├── 08-watcher-running-status.txt
> │       ├── <phase>-office-baseline-YYYYMMDD-HHMMSS.zip
> │       └── office-stability-summary.md
> ├── sign-offs/
> │   └── <phase>-office-stability-assessment-YYYYMMDD-HHMMSS.md
> └── watcher-history/
> ```
>
> Two lineages: `capture-office-stability.sh` gathers the evidence window,
> `assess-office-stability.sh` evaluates it. `watcher-history/` carries evidence
> forward from an earlier Office incident and stays outside the run index.

> [!example]- `$REIMAGE_ARTIFACT_ROOT/performance-audit/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/performance-audit/
> ├── MANIFEST.md
> ├── official/
> │   └── <phase>-performance-audit-<scenario>.txt
> ├── rollup-summary/
> │   └── <phase>-YYYYMMDD-HHMMSS/
> │       ├── performance-rollup-summary.md
> │       └── summary/
> └── runs/
>     └── <phase>-performance-audit-<scenario>-YYYYMMDD-HHMMSS/
>         ├── README.md
>         ├── docker/
>         ├── intellij/
>         ├── logs/
>         ├── mac-memory-health-output/
>         ├── manifest.txt
>         ├── manual-observations.md
>         ├── memory/
>         ├── processes/
>         ├── raw/
>         ├── responsiveness/
>         ├── system/
>         └── workload-reproduction-config.md
> ```
>
> `<scenario>` is one of `clean-boot`, `normal-workload`, `active-dev`, and each
> is its own lineage with its own pointer. `rollup-summary/` derives from the
> external helper's long-lived history rather than from these runs, so it sits
> beside the index rather than inside it.

> [!example]- `$REIMAGE_ARTIFACT_ROOT/public-certs/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/public-certs/
> └── certs/
>     ├── README.md
>     ├── keychain-cert-export-inventory-YYYYMMDD-HHMMSS.md
>     └── *.cer / *.pem                          # optional public-only convenience copies
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/reimage-confirmation/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/reimage-confirmation/
> └── it-reimage-confirmation-YYYYMMDD.md
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/
> ├── MANIFEST.md
> ├── manual/
> │   ├── loose-plaintext-cleanup-signoff-YYYYMMDD.md
> │   └── manual-export-pass-criteria-YYYYMMDD.md
> ├── official/
> │   └── pre-image.txt
> ├── runs/
> │   └── pre-image-YYYYMMDD-HHMMSS/
> │       └── reimage-checklist.md
> ├── secrets-dmg/
> │   ├── cleanup-YYYYMMDD-HHMMSS.md
> │   ├── dmg-validation-YYYYMMDD-HHMMSS.md
> │   └── staging-verification-YYYYMMDD-HHMMSS.md
> └── sign-offs/
>     └── reimage-prep-checks-YYYYMMDD-HHMMSS.md
> ```
>
> `manual/` and `secrets-dmg/` hold notes other phases wrote and Phase 6B reads;
> neither is a run lineage. The post-image capstone is the same script under
> `--phase post`, and lives under `reimaged-system/checklists/`.

> [!example]- `$REIMAGE_ARTIFACT_ROOT/reimaged-system/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/reimaged-system/
> ├── boundaries/
> │   ├── MANIFEST.md
> │   ├── official/
> │   │   └── <runbook>-<point>.txt
> │   └── runs/
> │       └── <runbook>-<point>-YYYYMMDD-HHMMSS/
> │           └── checklist.md
> ├── checklists/
> │   ├── MANIFEST.md
> │   ├── official/
> │   │   └── post-image.txt
> │   └── runs/
> │       └── post-image-YYYYMMDD-HHMMSS/
> │           └── reimage-checklist.md
> ├── comparisons/
> │   ├── MANIFEST.md
> │   ├── official/
> │   │   └── <runbook>-<what>-diff.txt
> │   └── runs/
> │       └── <runbook>-<what>-diff-YYYYMMDD-HHMMSS/
> │           ├── comparison.md
> │           └── rows.tsv
> ├── enrollment/                       # Phase 8 screenshots only — the records live under restarts/
> ├── restarts/
> │   ├── MANIFEST.md
> │   ├── official/
> │   │   └── <runbook>-<point>.txt
> │   └── runs/
> │       └── <runbook>-<point>-YYYYMMDD-HHMMSS/
> ├── restore-notes/
> ├── sign-offs/
> │   └── <run-id>.md
> └── state/
>     ├── MANIFEST.md
>     ├── official/
>     │   └── <runbook>-<point>.txt
>     └── runs/
>         └── <runbook>-<point>-YYYYMMDD-HHMMSS/
> ```
>
> `boundaries/`, `checklists/`, `comparisons/`, `state/` and `restarts/` are run categories with
> one shape: `runs/<context>-YYYYMMDD-HHMMSS/` holding a single run's files,
> `official/<context>.txt` naming the run that counts, and an append-only
> `MANIFEST.md` indexing every completed run. Officialness is computed from the
> manifest rather than stored there, so `official/` can be regenerated from it.
> `boundaries/` uses the points `entry` and `exit` — one pair per runbook, written
> by that runbook's Step 0 and its close-out. `state/` uses `before`, `after` and
> `delta`; `restarts/` uses `initial`, `pre-restart` and `post-restart`. `before`
> and `pre-restart` are **first-wins**: the first recording of that point stays
> official, because a later one describes a machine the phase has already changed.
> Every other point is latest-wins.
>
> `checklists/` holds the post-image capstone, written by
> `bin/reimage-checklist.sh --phase post`. Its pre-image counterpart is the same
> script under `--phase pre`, writing to `reimage-prep-checks/` at the artifact
> root, because `reimaged-system/` is post-image by construction.
>
> Two categories are deliberately outside that shape, because a run category
> replaces its contents and neither of these may be replaced.
>
> `sign-offs/` holds the rows a person answers, one file per run, named for the
> run so `Answered against` in each row points at something real. A purely manual
> artifact generated inside a run lands here too, whole, because a rerun replaces
> the run directory and would take the answers with it.
> A new run copies the previous file forward rather than starting blank, so an
> answer survives a rerun and its age stays visible: a row still naming an older
> run is *carried*, not re-verified. It is not run-indexed on purpose —
> officialness under `official/` is computed latest-wins, so keeping an answered
> file authoritative would depend on remembering to pin it after every edit,
> which is the same failure it exists to prevent.
>
> `restore-notes/` holds prose: the generated plan-notes the Phase 12 restore
> scripts write, the per-pass worksheets, and one append-only `decisions.md` per
> reimage event carrying the exceptions a row cannot hold — why a delta is
> expected, what was retired, what was not restored. Dated files would scatter
> that across the drive; a decision is not superseded by a later decision the way
> a capture is superseded by a later capture, so there is nothing to date.
> `bin/record-decision.sh` appends to it and can be asked, with `--check`,
> whether a comparison that keeps flagging something was already decided.
>
> Every post-image artifact lands under `reimaged-system/`. Unlike the pre-image
> phases, which each add a top-level directory to the artifact root, the restore
> and validation half writes only into subfolders here.



> [!example]- `$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/repo-audit-reports/
> ├── MANIFEST.md
> ├── repo-audit-index.md
> ├── official/
> │   ├── pre-image.txt
> │   └── post-image-restore.txt
> └── runs/
>     ├── pre-image-YYYYMMDD-HHMMSS/
>     │   ├── repo-audit-summary.txt
>     │   ├── repos.tsv
>     │   ├── tracked-changes.tsv
>     │   ├── local-only-commits.tsv
>     │   ├── stashes.tsv
>     │   ├── untracked-nonignored.tsv
>     │   └── ignored-files.tsv
>     └── post-image-restore-YYYYMMDD-HHMMSS/
>         ├── restore-status.md
>         ├── clone-commands.sh
>         └── rsync-ignored-files.sh
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/
> ├── all-secrets-YYYYMMDD-HHMMSS-manifest.txt   # created by create-secrets-dmg (Phase 3C, not yet run)
> ├── all-secrets-YYYYMMDD-HHMMSS.dmg            # created by create-secrets-dmg (Phase 3C, not yet run)
> ├── certs/
> │   ├── .keystore
> │   ├── java-security/                          # Java jssecacerts overrides + per-JDK dirs
> │   │   ├── java-jssecacerts-inventory.md
> │   │   └── <jdk-name>.jdk/
> │   ├── keychain-manual-exports/
> │   │   ├── keychain-export-summary-YYYYMMDD-HHMMSS.md
> │   │   └── README.md
> │   ├── loose-candidates-selected/
> │   ├── project-local/
> │   └── tool-local/
> ├── chrome/
> │   └── Chrome Passwords.csv                    # if exported
> ├── claude/
> │   └── claude_desktop_config.json
> ├── claude-code/
> │   ├── .claude.json                       # MCP server definitions, account + org identifiers
> │   └── .claude.json.bak-rally
> ├── cli-credentials/
> │   └── gh/
> ├── cloud/                                      # staged by backup-home (Phase 2B); excluded from the DMG — AWS re-auth after reimage
> │   └── aws/
> ├── docker/
> │   └── config.json
> ├── extra-secrets-certs-review/           # cert/Keychain review area (Phase 3A)
> │   ├── decisions/                         # plan + keychain-detail write here
> │   │   ├── cert-restore-notes-YYYYMMDD-HHMMSS.md.proposed
> │   │   └── keychain-manual-export-checklist-YYYYMMDD-HHMMSS.md.proposed
> │   ├── discovery/                         # scan writes here
> │   │   ├── all-cert-keychain-discovery-YYYYMMDD-HHMMSS.tsv
> │   │   ├── cert-key-file-candidates-YYYYMMDD-HHMMSS.tsv
> │   │   ├── configured-staged-files-YYYYMMDD-HHMMSS.tsv
> │   │   ├── credential-file-candidates-YYYYMMDD-HHMMSS.tsv
> │   │   ├── filesystem-cert-material-YYYYMMDD-HHMMSS.tsv
> │   │   ├── java-truststore-candidates-YYYYMMDD-HHMMSS.txt
> │   │   ├── keychain-certificate-catalog-YYYYMMDD-HHMMSS.tsv
> │   │   ├── keychain-certificate-inventory-YYYYMMDD-HHMMSS.txt
> │   │   ├── keychain-identities-YYYYMMDD-HHMMSS.txt
> │   │   ├── keychain-identity-catalog-YYYYMMDD-HHMMSS.tsv
> │   │   ├── staging-candidates-YYYYMMDD-HHMMSS.tsv
> │   │   └── staging-category-rules-YYYYMMDD-HHMMSS.md
> │   ├── MANIFEST.md                        # live index, regenerated by scan/plan/keychain-detail
> │   ├── plan/                              # plan writes here
> │   │   ├── cert-keychain-normalized-plan-YYYYMMDD-HHMMSS.tsv
> │   │   ├── cert-keychain-normalized-plan-primary-YYYYMMDD-HHMMSS.tsv
> │   │   ├── cert-keychain-normalized-plan-summary-YYYYMMDD-HHMMSS.md
> │   │   ├── cleaned-inputs-YYYYMMDD-HHMMSS/            # cleaned copies of the discovery inputs
> │   │   │   ├── all-cert-keychain-discovery-YYYYMMDD-HHMMSS.clean.tsv
> │   │   │   ├── cert-key-file-candidates-YYYYMMDD-HHMMSS.clean.tsv
> │   │   │   ├── clean-input-summary.md
> │   │   │   ├── configured-staged-files-YYYYMMDD-HHMMSS.clean.tsv
> │   │   │   ├── credential-file-candidates-YYYYMMDD-HHMMSS.clean.tsv
> │   │   │   ├── filesystem-cert-material-YYYYMMDD-HHMMSS.clean.tsv
> │   │   │   ├── keychain-certificate-catalog-YYYYMMDD-HHMMSS.clean.tsv
> │   │   │   ├── keychain-identity-catalog-YYYYMMDD-HHMMSS.clean.tsv
> │   │   │   └── staging-candidates-YYYYMMDD-HHMMSS.clean.tsv
> │   │   ├── gitignored-secret-generated-noise-filtered-YYYYMMDD-HHMMSS.tsv   # only when noise is filtered (absent this run)
> │   │   ├── out-of-cert-scope-secret-material-YYYYMMDD-HHMMSS.tsv
> │   │   └── proposed-staged-certs/
> │   │       ├── project-local.conf.sh.proposed
> │   │       └── proposed-staged-certs-summary-YYYYMMDD-HHMMSS.md.proposed
> │   └── state/                             # scan writes here
> │       ├── certs-staging-state-latest.tsv
> │       └── secrets-dmg-rebuild-required-YYYYMMDD-HHMMSS.md
> ├── git/                                   # created by create-secrets-dmg (Phase 3C); ~/.git-credentials if present
> ├── gnupg/
> ├── intellij/                                # staged by backup-intellij (Phase 2D); buckets named for the root each file came from
> │   ├── ide-config/                          # relative to ~/Library/Application Support/JetBrains/
> │   └── projects/                            # relative to $GIT_WORK_REPO_ROOT
> ├── kube/
> │   └── config
> ├── licenses/                              # created by create-secrets-dmg (Phase 3C); manual freeform staging
> ├── package-managers/                      # created by create-secrets-dmg (Phase 3C); .npmrc/.pypirc/etc.
> ├── postman/
> │   ├── environments/                      # if exported
> │   ├── README.md
> │   └── vault-if-export-allowed/           # if exported
> ├── RESTORE-README.md                      # created by create-secrets-dmg (Phase 3C, not yet run)
> ├── ssh/
> └── staged-loose/                          # written by stage-loose-secrets.sh (Phase 3B)
>     ├── MANIFEST.tsv                       # when, source path, staged path — restore reads this
>     └── <original-relative-path>           # e.g. home-files-backup/proj/id_rsa
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/size-audit-reports/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/size-audit-reports/
> ├── MANIFEST.md
> ├── official/
> │   └── <context>.txt
> ├── runs/
> │   └── <context>-YYYYMMDD-HHMMSS/
> │       └── size-audit-report.txt
> └── size-audit-index.md
> ```
>
> `<context>` names the phase and the caller — `pre-image-backup-repos`,
> `pre-image-run-time-machine` — so a free-space check taken before one phase does
> not supersede the check taken before another.

> [!example]- `$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/staged-ignored-files/
> ├── dryrun/
> │   ├── summary.txt
> │   ├── candidates.tsv
> │   └── excluded.tsv
> ├── dryrun-filtered/
> │   ├── summary.txt
> │   ├── candidates.tsv
> │   └── excluded.tsv
> └── live/
>     ├── summary.txt
>     ├── candidates.tsv
>     ├── excluded.tsv
>     ├── copied.tsv
>     ├── copy-failed.tsv
>     └── <repo-label>/
>         └── <relative-path-within-repo>
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/system-inventory/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/system-inventory/
> ├── version-inventory.txt
> ├── MANIFEST.md                          # append-only index of completed runs
> ├── official/
> │   ├── pre-image.txt                     # → runs/pre-image-YYYYMMDD-HHMMSS
> │   └── post-image.txt                    # → runs/post-image-YYYYMMDD-HHMMSS
> └── runs/
>     ├── pre-image-YYYYMMDD-HHMMSS/
>     │   ├── MANIFEST.txt
>     │   ├── Brewfile
>     │   ├── dotfiles/
>     │   ├── 01-hardware.txt
>     │   ├── 02-macos.txt
>     │   ├── 03-disk.txt
>     │   ├── 04-display.txt
>     │   ├── 05-apps.txt
>     │   ├── 06-homebrew.txt
>     │   ├── 07-shell.txt
>     │   ├── 08-git.txt
>     │   ├── 09-python.txt
>     │   ├── 10-java.txt
>     │   ├── 11-node.txt
>     │   ├── 12-docker.txt
>     │   ├── 13-network.txt
>     │   ├── 14-cloud.txt
>     │   ├── 15-env.txt
>     │   └── 16-certs.txt
>     └── post-image-YYYYMMDD-HHMMSS/
>         ├── MANIFEST.txt
>         ├── Brewfile
>         ├── dotfiles/
>         ├── 01-hardware.txt
>         ├── 02-macos.txt
>         ├── 03-disk.txt
>         ├── 04-display.txt
>         ├── 05-apps.txt
>         ├── 06-homebrew.txt
>         ├── 07-shell.txt
>         ├── 08-git.txt
>         ├── 09-python.txt
>         ├── 10-java.txt
>         ├── 11-node.txt
>         ├── 12-docker.txt
>         ├── 13-network.txt
>         ├── 14-cloud.txt
>         ├── 15-env.txt
>         └── 16-certs.txt
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/time-machine/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/time-machine/
> ├── MANIFEST.md
> ├── official/
> │   ├── <phase>-compare.txt
> │   ├── <phase>-completion-check.txt
> │   ├── <phase>-diagnose.txt
> │   ├── <phase>-diskutil-verify.txt
> │   ├── <phase>-evidence-summary.txt
> │   ├── <phase>-logs.txt
> │   ├── <phase>-status-bundle.txt
> │   ├── <phase>-status.txt
> │   └── <phase>-verifychecksums.txt
> ├── runs/
> │   ├── <phase>-compare-YYYYMMDD-HHMMSS/
> │   │   └── compare.txt
> │   ├── <phase>-completion-check-YYYYMMDD-HHMMSS/
> │   │   └── completion-check.md
> │   ├── <phase>-diagnose-YYYYMMDD-HHMMSS/
> │   │   └── diagnose.txt
> │   ├── <phase>-diskutil-verify-YYYYMMDD-HHMMSS/
> │   │   └── diskutil-verify.txt
> │   ├── <phase>-evidence-summary-YYYYMMDD-HHMMSS/
> │   │   └── evidence-summary.md
> │   ├── <phase>-logs-YYYYMMDD-HHMMSS/
> │   │   └── logs.txt
> │   ├── <phase>-status-YYYYMMDD-HHMMSS/
> │   │   └── status.txt
> │   ├── <phase>-status-bundle-YYYYMMDD-HHMMSS/
> │   │   ├── README.md
> │   │   ├── raw/
> │   │   │   ├── backup-root-spot-check.txt
> │   │   │   ├── cloud-sync-process-hints.txt
> │   │   │   ├── diskutil-applebackups-snapshots.txt
> │   │   │   ├── diskutil-applebackups.txt
> │   │   │   ├── diskutil-data.txt
> │   │   │   ├── diskutil-verifyvolume-applebackups.txt
> │   │   │   ├── tmutil-currentphase.txt
> │   │   │   ├── tmutil-destinationinfo.txt
> │   │   │   ├── tmutil-isexcluded-applebackups.txt
> │   │   │   ├── tmutil-isexcluded-data.txt
> │   │   │   ├── tmutil-latestbackup-targeted-applebackups.txt
> │   │   │   ├── tmutil-latestbackup.txt
> │   │   │   ├── tmutil-listbackups-targeted-applebackups.txt
> │   │   │   ├── tmutil-listbackups.txt
> │   │   │   ├── tmutil-status.txt
> │   │   │   └── volumes.txt
> │   │   ├── time-machine-pre-run.md
> │   │   └── time-machine-status.md
> │   └── <phase>-verifychecksums-YYYYMMDD-HHMMSS/
> │       └── verifychecksums.txt
> └── sign-offs/
>     └── <phase>-evidence-summary-YYYYMMDD-HHMMSS.md
> ```
>
> One lineage per subcommand, so each kind of evidence supersedes only its own
> kind. `<phase>` is `pre-image` at Phase 5 and `post-image` at Phase 16 — both
> halves share this category, which is why the context carries the phase and the
> directory does not.
>
> Script ownership:
>
> ```text
> bin/run-time-machine.sh   runtime operations: start, monitor, complete, logs, compare, verify, mount/unmount, diagnose, eject
> bin/record-time-machine-evidence.sh  read-only captures: pre-run status bundle, verify-volume, evidence summary
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/
> ├── MANIFEST.md
> ├── README.md
> ├── official/
> │   ├── <context>-toolkit-config.txt
> │   └── <context>-toolkit-snapshot.txt
> └── runs/
>     ├── <context>-toolkit-config-YYYYMMDD-HHMMSS/
>     │   ├── README.md
>     │   ├── config/
>     │   └── logs/
>     └── <context>-toolkit-snapshot-YYYYMMDD-HHMMSS/
>         ├── README.md
>         ├── config/
>         │   ├── SOURCES.txt
>         │   ├── artifact-config/
>         │   ├── reimage.env
>         │   └── staged-certs/
>         ├── docs/
>         │   ├── templates/
>         │   └── *.md
>         └── logs/
>             └── run-location.txt
> ```
>
> There are no symlinks and no `latest-*.txt` in this category. The stable path a
> restore-time reader needs is `official/<context>-toolkit-snapshot.txt`, a
> one-line file holding `runs/<id>`, readable with `cat` on a Mac with nothing
> installed — which is what the symlink was for.


[[#Table of Contents|⬆ Back to Table of Contents]]

---
