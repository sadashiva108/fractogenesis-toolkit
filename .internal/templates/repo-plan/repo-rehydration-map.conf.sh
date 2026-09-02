# REPO PLAN -- REHYDRATION MAP (OVERRIDES ONLY)
# Sourced by bin/restore-repos.sh. One `repo_map_add` call per override.
#
# Most keys are derived, not declared. A source with KEYED_BY=repo-name finds
# its bundle by the repository's name; one with KEYED_BY=pre-image-path finds it
# by the audit's path minus PATH_ROOT. Both are right for the great majority of
# repositories, and this file should be EMPTY on a machine where they hold.
#
# It exists for the cases the derivation gets wrong:
#
#   - a source with KEYED_BY=declared, which has no derivation at all;
#   - a bundle that belongs to a grouping project rather than to one repository,
#     where only a person can say which repository should receive it;
#   - a repository whose pre-image path moved between the audit and the reimage,
#     so the derived key names a directory that is not there;
#   - a bundle that is not shaped like a repository root, and lands somewhere
#     other than the top of the working tree.
#
# REPO_NAME         Required. Which repository receives it.
# ARTIFACT_TYPE     Required. Which source, from repo-rehydration-sources.
# ARTIFACT_SUBPATH  The key under that source's ARTIFACT_ROOT, replacing
#                   whatever the source would have derived.
# LOCAL_REPO_PATH   Where it lands, when the destination is not the repository's
#                   own root as resolved from the selected-candidates file.
#
# An override here beats the derivation. Nothing else does, so a wrong key is
# fixed in one place.

# repo_map_add \
#   REPO_NAME=example-service \
#   ARTIFACT_TYPE=project-metadata \
#   ARTIFACT_SUBPATH=example-group/example-service

# repo_map_add \
#   REPO_NAME=example-service \
#   ARTIFACT_TYPE=example-declared-source \
#   ARTIFACT_SUBPATH=some/place/example-service \
#   LOCAL_REPO_PATH="$LOCAL_WORK_REPO_ROOT/example-group/example-service"
