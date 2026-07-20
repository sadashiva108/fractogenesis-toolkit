[← Back to Mac Reimaging Guide](../reimaging-guide.md)

# Master Directory Reference

**Last Updated:** 2026-07-19

This is the consolidated `$REIMAGE_ARTIFACT_ROOT` directory map for the Mac reimage workflow.

It combines the currently documented backup, capture, validation, and post-image artifact locations from:

- `backup-apps.md`
- `backup-file-reference.md`
- `backup-home.md`
- `backup-intellij.md`
- `backup-repos.md`
- `capture-initial-reimaged-system.md`
- `capture-managed-inventory.md`
- `capture-office-stability-audit.md`
- `capture-performance-audit.md`
- `capture-system-inventory.md`
- `capture-validated-reimaged-system.md`
- `capture-workflow-snapshot.md`
- `enroll-and-stabilize.md`
- `prepare-artifact-root.md`
- `reimage-prep-evidence.md`
- `reimaged-system-evidence.md`
- `restore-apps.md`
- `restore-intellij.md`
- `stage-cert-keychain.md`

Use this file when you want one place to see the intended artifact layout without jumping between multiple phase guides.

> [!tip]
> The sections below use **collapsible Obsidian callouts**. Click the triangle beside each path to expand or collapse it.

---

## Table of Contents

- [[#Master Root Layout|Master Root Layout]]
- [[#Collapsible Directory Sections|Collapsible Directory Sections]]
- [[#License Keys and Activation Material|License Keys and Activation Material]]

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
└── workflow-snapshot/
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
> │   ├── latest-enrollment-capture.txt
> │   └── capture-enrollment-YYYYMMDD-HHMMSS/
> │       ├── enrollment-capture.md
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
> └── runs/
>     ├── pre-image-YYYYMMDD-HHMMSS/
>     │   ├── repo-audit-summary.txt
>     │   ├── repos.tsv
>     │   ├── tracked-changes.tsv
>     │   ├── local-only-commits.tsv
>     │   ├── stashes.tsv
>     │   ├── untracked-nonignored.tsv
>     │   └── ignored-files.tsv
>     └── post-image-YYYYMMDD-HHMMSS/
>         └── ...
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/secrets-encrypted/
> ├── all-secrets-YYYYMMDD-HHMMSS.dmg
> ├── all-secrets-YYYYMMDD-HHMMSS-manifest.txt
> ├── RESTORE-README.md
> ├── certs/
> │   ├── README.md
> │   ├── java-security/
> │   ├── keychain-manual-exports/
> │   │   ├── README.md
> │   │   └── keychain-export-summary-YYYYMMDD-HHMMSS.md
> │   ├── loose-candidates-selected/
> │   ├── project-local/
> │   └── tool-local/
> ├── chrome/
> │   ├── Chrome Passwords YYYYMMDD-HHMMSS.csv    # if exported
> │   └── README.md
> ├── cli-credentials/
> ├── cloud/
> │   └── aws/
> ├── docker/
> │   └── config.json
> ├── extra-secrets-certs-review/
> │   ├── MANIFEST.md
> │   ├── staging-category-rules-YYYYMMDD-HHMMSS.md
> │   └── *.tsv / *.txt review reports
> ├── git/
> ├── gnupg/
> ├── kube/
> │   └── config
> ├── licenses/                                  # manual freeform staging, if applicable -- no fixed filenames
> ├── package-managers/
> ├── postman/
> │   ├── environments/                           # if exported
> │   ├── vault-if-export-allowed/                # if exported
> │   └── README.md
> ├── raycast/
> │   ├── quicklinks-if-sensitive/
> │   │   └── raycast-quicklinks-YYYYMMDD-HHMMSS.json   # if sensitive/unreviewed
> │   └── raycast-settings-and-data-YYYYMMDD-HHMMSS.rayconfig   # if exported
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
> scripts/backup-time-machine.sh   runtime operations: start, monitor, complete, logs, compare, verify, mount/unmount, diagnose, eject
> scripts/capture-time-machine.sh  read-only captures: pre-run bundle, verify-volume, final checklist
> ```

> [!example]- `$REIMAGE_ARTIFACT_ROOT/workflow-snapshot/`
> ```text
> $REIMAGE_ARTIFACT_ROOT/workflow-snapshot/
> ├── README.md
> ├── reimage-workflow-docs/
> │   ├── *.md
> │   └── templates/
> ├── latest-pre-image-workflow-snapshot.txt
> ├── latest-pre-image-workflow-snapshot -> pre-image-workflow-snapshot-YYYYMMDD-HHMMSS
> └── pre-image-workflow-snapshot-YYYYMMDD-HHMMSS/
>     ├── README.md
>     └── logs/
>         └── latest-aliases.txt
> ```


[[#Table of Contents|⬆ Back to Table of Contents]]

---
