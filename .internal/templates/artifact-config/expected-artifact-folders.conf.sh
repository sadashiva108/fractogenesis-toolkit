# expected-artifact-folders.conf.sh
# Sourced by artifact-config.sh. Defines the top-level folder names
# reimage-checklist.sh checks for directly under $REIMAGE_ARTIFACT_ROOT.
#
# This list is sourced from reimage-checklist.sh's own "Artifact Root
# Subdirectories" check (record_section "Artifact Root Subdirectories"),
# not fabricated -- it's the real expected set as of this migration.

EXPECTED_ARTIFACT_FOLDERS=(
  app-backups
  gitignore-superset
  local-files
  reimage-plan
  reimage-prep-checks
  reimaged-system
  repo-audit-reports
  secrets-encrypted
  selected-ignored-files
  selected-ignored-files-filtered-dryrun
  time-machine
  workflow-snapshot
)
