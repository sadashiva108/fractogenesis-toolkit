# REPO PLAN -- REHYDRATION SOURCES
# Where content comes back from AFTER a repository is cloned. Sourced by
# bin/restore-repos.sh. One `repo_source_add` call per source.
#
# Cloning restores what Git tracked. Everything a working tree needs and Git
# ignores -- kept ignored files, gitignored secrets, IDE project metadata --
# comes from somewhere else, and each somewhere is keyed differently. This file
# is the registry of those places, so adding one later is a call here rather
# than a script change.
#
# ARTIFACT_TYPE  Required. Short id. Named by the map, by `--hydrate --stage`,
#                and in the run's status report and in hydrated.md.
# ARTIFACT_ROOT  Required. The source root. $REIMAGE_ARTIFACT_ROOT expands when
#                this file is sourced; write $DMG_MOUNT SINGLE-QUOTED so it
#                stays literal and is substituted at run time.
# KEYED_BY       How a repository's bundle is found under ARTIFACT_ROOT:
#                  repo-name       the bundle directory is REPO_NAME
#                  pre-image-path  the audit's pre-image path, relative to
#                                  PATH_ROOT
#                  declared        no derivation; reachable only through
#                                  repo-rehydration-map.conf.sh
# PATH_ROOT      Required when KEYED_BY=pre-image-path. The root the capture
#                walked, stripped from the audit path to give the key.
# REQUIRES       artifact-root | dmg. A dmg source with no image attached is
#                recorded `blocked`, not failed -- attach it later and rerun.
# MODE           merge   rsync -a into the repository
#                report  list what exists and restore nothing
# DESCRIPTION    One line. Appears in the status report.
#
# Sources apply in the order listed.
#
# MODE=report is the honest setting for a source whose layout has not been seen.
# It surfaces what is there without guessing where it belongs.

# repo_source_add \
#   ARTIFACT_TYPE=ignored-files \
#   ARTIFACT_ROOT="$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live" \
#   KEYED_BY=repo-name \
#   REQUIRES=artifact-root \
#   MODE=merge \
#   DESCRIPTION="Reviewed kept ignored files staged during the backup phase"

# repo_source_add \
#   ARTIFACT_TYPE=repo-secrets \
#   ARTIFACT_ROOT='$DMG_MOUNT/repos-gitignored' \
#   KEYED_BY=repo-name \
#   REQUIRES=dmg \
#   MODE=merge \
#   DESCRIPTION="Gitignored secret-shaped files, encrypted into the secrets image"

# repo_source_add \
#   ARTIFACT_TYPE=project-metadata \
#   ARTIFACT_ROOT="$REIMAGE_ARTIFACT_ROOT/app-settings-backup/intellij/project-metadata" \
#   KEYED_BY=pre-image-path \
#   PATH_ROOT="<the projects root the capture walked>" \
#   REQUIRES=artifact-root \
#   MODE=merge \
#   DESCRIPTION="Per-project IDE metadata, keyed by path under the projects root"
