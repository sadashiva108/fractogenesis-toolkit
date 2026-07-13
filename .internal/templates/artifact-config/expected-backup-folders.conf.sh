# expected-backup-folders.conf.sh
# Sourced by artifact-config.sh. Defines the top-level folder names
# reimage-checklist.sh checks for directly under $REIMAGE_ARTIFACT_ROOT.
#
# This list is sourced from reimage-checklist.sh's own "Backup Root
# Subdirectories" check (record_section "Backup Root Subdirectories"),
# not fabricated -- it's the real expected set as of this migration.

EXPECTED_BACKUP_FOLDERS=(
  app-backups
  repo-audit-reports
  gitignore-superset
  secrets-encrypted
)
