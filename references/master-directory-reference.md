[← Back to Mac Reimaging Guide](../reimaging-guide.md)

# Master Directory Reference

**Last Updated:** 2026-07-21

This is the consolidated `$REIMAGE_ARTIFACT_ROOT` directory map for the Mac reimage workflow.

It combines the currently documented backup, capture, validation, and post-image artifact locations from:

- `backup-apps.md`
- `backup-file-reference.md`
- `backup-home.md`
- `backup-intellij.md`
- `backup-repos.md`
- `verify-reimaged-system.md`
- `capture-managed-inventory.md`
- `capture-office-stability.md`
- `capture-performance-audit.md`
- `capture-system-inventory.md`
- `capture-toolkit-snapshot.md`
- `enroll-and-stabilize.md`
- `prepare-artifact-root.md`
- `reimage-prep-evidence.md`
- `reimaged-system-checks.md`
- `reimaged-system-evidence.md`
- `restore-apps.md`
- `restore-intellij.md`
- `stage-certs-keychain.md`

Use this file when you want one place to see the intended artifact layout without jumping between multiple phase guides.

> [!tip]
> The sections below use **collapsible Obsidian callouts**. Click the triangle beside each path to expand or collapse it.

---

## Table of Contents

- [[#Where Files Are Read From|Where Files Are Read From]]
- [[#Master Root Layout|Master Root Layout]]
- [[#Collapsible Directory Sections|Collapsible Directory Sections]]
- [[#License Keys and Activation Material|License Keys and Activation Material]]

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

These ship as generic templates with example paths, get copied into the workspace
once, and are edited for this Mac. They cannot live on the artifact root because
they are read *before it exists* — `EXPECTED_ARTIFACT_FOLDERS` is what Phase 1
uses to create it. Both resolvers prefer the workspace copy and fall back to the
committed templates, and both warn when `REIMAGE_WORKSPACE_ROOT` is set but the
directory is missing, because a silent fallback means running against generic
example targets.

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
`$REIMAGE_WORKSPACE_ROOT/enrollment/` when the drive is not mounted. In every case
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
> │   │   ├── scratches-and-consoles/
> │   │   └── manifests/
> │   ├── logs/
> │   │   ├── IntelliJIdeaYYYY.N/
> │   │   └── system-cache-not-copied.txt
> │   ├── manifests/
> │   ├── manual-settings-export/
> │   │   └── IntelliJ-settings-YYYYMMDD-HHMMSS.zip
> │   ├── project-metadata/
> │   ├── restore-notes/
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

> [!example]- `$REIMAGE_ARTIFACT_ROOT/managed-inventory/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/managed-inventory/
> ├── pre-image-YYYYMMDD-HHMMSS/
> │   ├── 01-enrollment-status.txt
> │   ├── 02-profiles-configuration.txt
> │   ├── 03-installed-app-bundles.txt
> │   ├── 04-installed-package-receipts.txt
> │   ├── 05-background-managed-components.txt
> │   ├── 06-managed-preference-payloads.txt
> │   ├── 07-gaig-filter-pass.txt
> │   └── MANIFEST.txt
> └── post-image-YYYYMMDD-HHMMSS/
>     ├── 01-enrollment-status.txt
>     ├── 02-profiles-configuration.txt
>     ├── 03-installed-app-bundles.txt
>     ├── 04-installed-package-receipts.txt
>     ├── 05-background-managed-components.txt
>     ├── 06-managed-preference-payloads.txt
>     ├── 07-gaig-filter-pass.txt
>     └── MANIFEST.txt
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/office-stability/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/office-stability/
> ├── office-stability-summary-YYYYMMDD-HHMMSS.md
> ├── pre-reimage-office-baseline-YYYYMMDD-HHMMSS/
> │   ├── 00-baseline-window.txt
> │   ├── 01-crash-reports-newer-than-marker.txt
> │   ├── 02-office-bundle-status.txt
> │   ├── 03-outlook-onenote-process-transitions.txt
> │   ├── 04-watcher-installer-office-signals.txt
> │   ├── 05-install-log-office-events-tail.txt
> │   ├── 06-autoupdate-office-events-tail.txt
> │   ├── 07-unified-log-office-since-marker.txt
> │   ├── 08-watcher-running-status.txt
> │   └── office-stability-summary.md
> ├── pre-reimage-office-baseline-YYYYMMDD-HHMMSS.zip
> ├── post-reimage-office-baseline-YYYYMMDD-HHMMSS/
> │   └── ...
> ├── post-reimage-office-baseline-YYYYMMDD-HHMMSS.zip
> └── checklists/
>     ├── latest-pre-image-office-stability-checklist.txt
>     ├── latest-post-image-office-stability-checklist.txt
>     ├── pre-image-office-stability-checklist-YYYYMMDD-HHMMSS/
>     │   ├── README.md
>     │   ├── pre-image-office-stability-checklist.md
>     │   ├── logs/
>     │   │   ├── commands.log
>     │   │   └── errors.log
>     │   ├── watcher/
>     │   │   ├── marker-timestamp.txt
>     │   │   ├── watcher-running-processes.txt
>     │   │   ├── latest-watcher-tail-800.txt
>     │   │   └── watcher-installer-office-signals.txt
>     │   ├── processes/
>     │   │   └── outlook-onenote-process-transitions.txt
>     │   └── system/
>     │       ├── installer-update-management-processes.txt
>     │       ├── office-crash-reports-after-marker.txt
>     │       ├── office-bundle-status.txt
>     │       ├── install-log-office-events-tail.txt
>     │       └── autoupdate-office-events-tail.txt
>     └── post-image-office-stability-checklist-YYYYMMDD-HHMMSS/
>         └── ...
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/performance-audit/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/performance-audit/
> ├── pre-image-performance-audit-clean-boot-YYYYMMDD-HHMMSS/
> ├── pre-image-performance-audit-normal-workload-YYYYMMDD-HHMMSS/
> ├── pre-image-performance-audit-active-dev-YYYYMMDD-HHMMSS/
> ├── post-image-performance-audit-clean-boot-YYYYMMDD-HHMMSS/
> ├── post-image-performance-audit-normal-workload-YYYYMMDD-HHMMSS/
> ├── post-image-performance-audit-active-dev-YYYYMMDD-HHMMSS/
> ├── rollup-summary/
> │   └── <phase>-YYYYMMDD-HHMMSS/
> │       ├── performance-rollup-summary.md
> │       └── summary/
> └── <phase>-performance-audit-<scenario>-YYYYMMDD-HHMMSS/
>     ├── README.md
>     ├── manifest.txt
>     ├── manual-observations.md
>     ├── workload-reproduction-config.md
>     ├── docker/
>     ├── intellij/
>     ├── logs/
>     ├── mac-memory-health-output/
>     ├── memory/
>     ├── processes/
>     ├── raw/
>     ├── responsiveness/
>     └── system/
> ```

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
> ├── reimage-checklist-YYYYMMDD-HHMMSS.md
> ├── latest-reimage-checklist.txt
> └── manual/
>     └── manual-app-export-and-sync-signoff-YYYYMMDD.md
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/reimaged-system/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/reimaged-system/
> ├── enrollment/
> │   ├── latest-enrollment-record.txt
> │   └── record-enrollment-YYYYMMDD-HHMMSS/
> │       ├── enrollment-record.md
> │       ├── MANIFEST.txt
> │       └── raw/
> │           ├── 01-enrollment-status.txt
> │           ├── 02-profiles-list.txt
> │           ├── 03-filevault-status.txt
> │           ├── 04-managed-apps.txt
> │           ├── 05-managed-processes.txt
> │           ├── 06-macos-version.txt
> │           └── 07-softwareupdate-list.txt
> ├── checklists/
> │   ├── reimage-checklist-YYYYMMDD-HHMMSS.md
> │   └── latest-reimage-checklist.txt
> ├── latest-initial-reimaged-system-bundle.txt
> ├── initial-reimaged-system-YYYYMMDD-HHMMSS/
> │   ├── README.md
> │   ├── initial-checklist.md
> │   ├── manual-captures-required.md
> │   ├── restart-checkpoints.md
> │   ├── time-machine-reimaged-system-plan.md
> │   ├── checks/
> │   ├── logs/
> │   │   ├── commands.log
> │   │   └── errors.log
> │   └── raw/
> │       ├── applications-managed.txt
> │       ├── backup-root-spotcheck.txt
> │       ├── brew-version.txt
> │       ├── computer-name.txt
> │       ├── date.txt
> │       ├── filevault.txt
> │       ├── git-version.txt
> │       ├── hardware.txt
> │       ├── host-name.txt
> │       ├── hostname.txt
> │       ├── local-host-name.txt
> │       ├── managed-processes.txt
> │       ├── network-github.txt
> │       ├── network-microsoft.txt
> │       ├── network-ping.txt
> │       ├── profiles-enrollment.txt
> │       ├── profiles-list.txt
> │       ├── softwareupdate-list.txt
> │       ├── sw_vers.txt
> │       ├── time-machine-destination.txt
> │       ├── time-machine-latest.txt
> │       ├── uname.txt
> │       ├── volumes.txt
> │       ├── whoami.txt
> │       └── xcode-select.txt
> ├── restore-notes/
> ├── restarts/
> └── time-machine/
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/repo-audit-reports/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/repo-audit-reports/
> ├── MANIFEST.md
> ├── latest-run.txt
> ├── latest-post-image-restore.txt
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
> ├── all-secrets-YYYYMMDD-HHMMSS-manifest.txt   # created by create-secrets-dmg (Phase 3B, not yet run)
> ├── all-secrets-YYYYMMDD-HHMMSS.dmg            # created by create-secrets-dmg (Phase 3B, not yet run)
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
> ├── cli-credentials/
> │   └── gh/
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
> │       └── phase2f-rerun-required-YYYYMMDD-HHMMSS.md
> ├── git/                                   # created by create-secrets-dmg (Phase 3B); ~/.git-credentials if present
> ├── gnupg/
> ├── intellij/
> ├── kube/
> │   └── config
> ├── licenses/                              # created by create-secrets-dmg (Phase 3B); manual freeform staging
> ├── package-managers/                      # created by create-secrets-dmg (Phase 3B); .npmrc/.pypirc/etc.
> ├── postman/
> │   ├── environments/                      # if exported
> │   ├── README.md
> │   └── vault-if-export-allowed/           # if exported
> ├── RESTORE-README.md                      # created by create-secrets-dmg (Phase 3B, not yet run)
> └── ssh/
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/size-audit-reports/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/size-audit-reports/
> ├── MANIFEST.md
> ├── latest-run.txt
> └── runs/
>     ├── pre-image-YYYYMMDD-HHMMSS/
>     │   └── size-audit-report.txt
>     └── post-image-YYYYMMDD-HHMMSS/
>         └── ...
> ```

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
> ├── pre-image-YYYYMMDD-HHMMSS/
> │   ├── MANIFEST.txt
> │   ├── Brewfile
> │   ├── dotfiles/
> │   ├── 01-hardware.txt
> │   ├── 02-macos.txt
> │   ├── 03-disk.txt
> │   ├── 04-display.txt
> │   ├── 05-apps.txt
> │   ├── 06-homebrew.txt
> │   ├── 07-shell.txt
> │   ├── 08-git.txt
> │   ├── 09-python.txt
> │   ├── 10-java.txt
> │   ├── 11-node.txt
> │   ├── 12-docker.txt
> │   ├── 13-network.txt
> │   ├── 14-cloud.txt
> │   ├── 15-env.txt
> │   └── 16-certs.txt
> └── post-image-YYYYMMDD-HHMMSS/
>     ├── MANIFEST.txt
>     ├── Brewfile
>     ├── dotfiles/
>     ├── 01-hardware.txt
>     ├── 02-macos.txt
>     ├── 03-disk.txt
>     ├── 04-display.txt
>     ├── 05-apps.txt
>     ├── 06-homebrew.txt
>     ├── 07-shell.txt
>     ├── 08-git.txt
>     ├── 09-python.txt
>     ├── 10-java.txt
>     ├── 11-node.txt
>     ├── 12-docker.txt
>     ├── 13-network.txt
>     ├── 14-cloud.txt
>     ├── 15-env.txt
>     └── 16-certs.txt
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/time-machine/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/time-machine/
> ├── completion-check-YYYYMMDD-HHMMSS.md
> ├── final-time-machine-checklist-YYYYMMDD-HHMMSS.md
> ├── compare-YYYYMMDD-HHMMSS.txt
> ├── logs-YYYYMMDD-HHMMSS.txt
> ├── verifychecksums-YYYYMMDD-HHMMSS.txt
> ├── diskutil-verifyvolume-applebackups-YYYYMMDD-HHMMSS.txt
> ├── diagnose-YYYYMMDD-HHMMSS.txt
> └── pre-image-time-machine-status-YYYYMMDD-HHMMSS/
>     ├── README.md
>     ├── time-machine-pre-run.md
>     ├── time-machine-status.md
>     └── raw/
>         ├── backup-root-spot-check.txt
>         ├── cloud-sync-process-hints.txt
>         ├── diskutil-applebackups.txt
>         ├── diskutil-applebackups-snapshots.txt
>         ├── diskutil-verifyvolume-applebackups.txt
>         ├── diskutil-data.txt
>         ├── tmutil-currentphase.txt
>         ├── tmutil-destinationinfo.txt
>         ├── tmutil-isexcluded-applebackups.txt
>         ├── tmutil-isexcluded-data.txt
>         ├── tmutil-latestbackup-targeted-applebackups.txt
>         ├── tmutil-latestbackup.txt
>         ├── tmutil-listbackups-targeted-applebackups.txt
>         ├── tmutil-listbackups.txt
>         ├── tmutil-status.txt
>         └── volumes.txt
> ```
>
> Script ownership:
>
> ```text
> bin/run-time-machine.sh   runtime operations: start, monitor, complete, logs, compare, verify, mount/unmount, diagnose, eject
> bin/capture-time-machine.sh  read-only captures: pre-run bundle, verify-volume, final checklist
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/toolkit-snapshot/
> ├── README.md
> ├── latest-docs/
> │   ├── *.md
> │   └── templates/
> ├── latest-pre-image-toolkit-snapshot.txt
> ├── latest-pre-image-toolkit-snapshot -> pre-image-toolkit-snapshot-YYYYMMDD-HHMMSS
> └── pre-image-toolkit-snapshot-YYYYMMDD-HHMMSS/
>     ├── README.md
>     └── logs/
>         └── latest-aliases.txt
> ```


[[#Table of Contents|⬆ Back to Table of Contents]]

---
