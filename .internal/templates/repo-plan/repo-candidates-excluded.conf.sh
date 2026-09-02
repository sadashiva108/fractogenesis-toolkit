# REPO PLAN -- EXCLUDED CANDIDATES
# Repositories in the pre-image audit that are deliberately not being restored.
# Sourced by bin/restore-repos.sh. One `repo_plan_exclude` call each.
#
# REPO_NAME  Required. As the audit recorded it.
# REASON     Required. Why. This is the point of the file.
#
# This is not the same as leaving a repository out. bin/record-restore-exit.sh
# carries a manual row -- "Repositories left unrestored are a decision" -- and
# this file is what answers it. Absence cannot: a repository nobody decided
# about and a repository deliberately dropped look identical when both are
# simply missing.
#
# A reason ages better than it reads. "archived" tells the next person nothing;
# "archived 2025, content folded into <other repo>" tells them where to look.

# repo_plan_exclude \
#   REPO_NAME=example-retired-service \
#   REASON="archived 2025; content folded into example-service"

# repo_plan_exclude \
#   REPO_NAME=example-scratch \
#   REASON="scratch clone of an upstream repo; nothing local was ever committed"
