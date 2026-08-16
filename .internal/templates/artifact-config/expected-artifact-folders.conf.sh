# expected-artifact-folders.conf.sh
# Sourced by artifact-config.sh. This is the CREATION list: the top-level
# folders prepare-artifact-root creates under $REIMAGE_ARTIFACT_ROOT in Phase 1,
# and the set backup-apps.sh --preflight and capture-size-audit.sh count against
# to tell you whether Phase 1 has run.
#
# It is deliberately NOT the same as reimage-checklist.sh's "Backup Root
# Subdirectories" check. That one asks a different question — which folders must
# be NON-EMPTY at sign-off — so it keeps its own list and must not be pointed at
# this one. A folder can legitimately be created here and still be empty.
#
# What is here, and what is deliberately not:
#   - The backup and staging roots every reimage produces.
#   - managed-inventory and system-inventory: captures, but assumed wanted by
#     default, so they are scaffolded up front.
#   - office-stability and performance-audit are NOT here on purpose. They are
#     optional captures, only worth running when Office instability or a
#     performance problem is part of why the machine is being reimaged. Their
#     runbooks create them on demand; most reimages never need them.
#
# Adding a name here means Phase 1 creates it and every preflight counts it.
# Adding an optional capture would report it missing on machines that never
# run it.

EXPECTED_ARTIFACT_FOLDERS=(
  "app-settings-backup"
  "gitignore-superset"
  "home-files-backup"
  "loose-secrets-reports"
  "managed-inventory"
  "public-certs"
  "reimage-confirmation"
  "reimage-prep-checks"
  "reimaged-system"
  "repo-audit-reports"
  "secrets-encrypted"
  "size-audit-reports"
  "staged-ignored-files"
  "system-inventory"
  "time-machine"
  "toolkit-snapshot"
)
