# REPO PLAN -- SELECTED CANDIDATES
# Which repositories to clone, from which remote, and where they land.
# Sourced by bin/restore-repos.sh. One `repo_plan_add` call per repository.
#
# Format: named keys, in any order. Unknown keys are an error naming the
# repository, so a typo cannot become a silently shifted value.
#
# REPO_NAME         Required. The repository's name as the pre-image audit
#                   recorded it. Also the default bundle key for every
#                   rehydration source, and the default clone directory name.
# REMOTE_NAME       Which recorded remote becomes `origin`.
#                   Default: origin, or the only remote when there is one.
# REMOTE_FETCH_URL  That remote's fetch URL.
#                   Default: looked up in the audit by REPO_NAME + REMOTE_NAME.
# LOCAL_REPO_PATH   Absolute destination. A root plus a path, so nesting and
#                   renaming both fall out of it.
#                   Default: the routed root plus REPO_NAME.
#
# Only REPO_NAME is required. A repository going to its routed root under its
# own name is one line; everything else is stated only where it differs.
#
# Routing, when LOCAL_REPO_PATH is omitted: the `origin` remote's HOST decides.
# GIT_PERSONAL_GITHUB_HOST with an owner matching GIT_PERSONAL_GITHUB_OWNER
# routes to LOCAL_PERSONAL_REPO_ROOT; GIT_WORK_GITHUB_HOST routes to
# LOCAL_WORK_REPO_ROOT; anything else routes to the work root and prints why.
# The pre-image directory is never consulted -- it says nothing about who owns
# the remote, and the root is what `includeIf` uses to decide commit identity.
#
# A repository in the audit and in neither this file nor
# repo-candidates-excluded.conf.sh is UNREVIEWED: reported every run, never
# cloned, never silently skipped.

# repo_plan_add \
#   REPO_NAME=example-service \
#   LOCAL_REPO_PATH="$LOCAL_WORK_REPO_ROOT/example-group/example-service"

# repo_plan_add \
#   REPO_NAME=example-toolkit \
#   REMOTE_NAME=personal \
#   LOCAL_REPO_PATH="$LOCAL_PERSONAL_REPO_ROOT/example-toolkit"
