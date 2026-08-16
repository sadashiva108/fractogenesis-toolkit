# Paths you have reviewed and decided are NOT secrets, so the Phase 3B tooling
# stops treating them as findings.
#
# This fragment is OPTIONAL. With no entries, every credential-shaped file is a
# finding — which is the correct default.
#
# Format: one entry per line, "path-glob|reason". Both fields are required.
#   - path-glob is matched against the path as the report prints it: relative to
#     $REIMAGE_ARTIFACT_ROOT, no leading slash. Shell glob, not a regex.
#   - reason is free text and is shown next to the path in every report.
#
# The reason is not decoration. Six weeks later, an excepted path with no note
# is indistinguishable from one you meant to come back to and forgot — which is
# exactly the state this whole phase exists to prevent. Date it and say what you
# checked.
#
# Effect of an entry:
#   bin/report-loose-secrets.sh    reports the path as ACCEPTED with its reason,
#                                  and does not count it toward OUTSIDE.
#   bin/stage-loose-secrets.sh     leaves the file where it is.
#
# This is the DURABLE form. It lives under $REIMAGE_WORKSPACE_ROOT with your
# other reviewed selections, so it survives re-runs and the erase itself. For
# "not this run, I am still deciding", use stage-loose-secrets.sh --keep GLOB
# instead — that is per-invocation, records nothing, and the report still counts
# the file, which is the point: an undecided file should keep showing up.
#
# Excepting something does not make it safe. It records that YOU decided it is
# safe. Nothing here is verified by reading the file.
#
# Examples:
#   "public-certs/*|public chain, no private key — verified 2026-08-16"
#   "home-files-backup/proj/settings.xml|Maven mirrors only, no server creds — 2026-08-16"

LOOSE_SECRET_EXCEPTIONS=(
)
