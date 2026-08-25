#!/usr/bin/env bash
# =============================================================================
# restore-state-targets.conf.sh
#
# The one definition of which paths a state walk observes. Sourced -- never run.
#
# TWO CALLERS, ONE LIST. bin/record-restore-state.sh walks these within a restore
# phase (before/after), and bin/capture-system-state.sh walks the same set on
# either side of the erase. A delta joins two walks on their absolute path, so a
# path present in one caller's list and absent from the other appears as `added`
# or `**removed**` -- a difference the machine never had. Two copies of this
# table would drift, and the first symptom would be a comparison lying
# confidently rather than failing.
#
# Format, `@@`-delimited because a spec contains `/`, `$`, `.` and `-`:
#
#   mode @@ spec @@ what this path is for
#
#   file     one path, hashed
#   tree     recurse, including directories so an empty one is still a row
#   shallow  depth 1 only
#
# The notes name restore-access steps because that runbook is what made each
# path interesting. A pre-image walk records them for the same reason: they are
# the paths the reimage has to put back.
# =============================================================================

restore_state_targets() {
  cat <<'TARGETS'
tree@@~/.ssh/@@Step 3 — keys, config, known_hosts
file@@~/.gitconfig@@Step 3 — Git identity (Phase 11A owns the content)
tree@@~/.config/git/@@Step 3 — XDG-located Git config
tree@@~/Library/Keychains/@@Steps 4-5 — user keychains; these churn on every access
file@@/Library/Keychains/System.keychain@@Step 5 — system-domain trust, only if that form is used
shallow@@$JAVA_HOME/lib/security/@@Step 6 — jssecacerts, pinned to the Phase 10A JDK
tree@@~/.certs/@@Step 7 — corp-root.pem, the bundle non-keychain tools read
file@@~/.npmrc@@Step 7 — npm config set cafile
file@@~/.config/pip/pip.conf@@Step 7 — pip config set global.cert
file@@~/.zprofile@@Step 7 appends CA exports; Step 8 may merge over it
file@@~/.zshrc@@Step 8 — selective merge
file@@~/.bash_profile@@Step 8 — selective merge
file@@~/.bashrc@@Step 8 — selective merge
file@@~/.shell_common.sh@@Step 8 — selective merge
file@@~/.shell_local.sh@@Step 8 — selective merge
shallow@@~/.config/@@Step 8 — depth 1 only; the subtrees here are not this phase's
shallow@@~/.kube/@@Step 8 — cluster config
shallow@@~/.cf/@@Step 8 — Cloud Foundry CLI state
shallow@@~/.azure/@@Step 8 — Azure CLI state
TARGETS
}
