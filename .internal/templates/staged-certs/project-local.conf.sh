# STAGED CERTS — PROJECT LOCAL
# Reviewed project-local cert/key/truststore paths staged into
# secrets-encrypted/certs/project-local/. Sourced by stage-certs-keychain.sh.
#
# Format: one absolute path per entry — files or directories.
#
# For repo-adjacent or workspace-local certificate material not already
# auto-captured by Phase 3C and still required after reimage.

STAGED_CERTS_PROJECT_LOCAL=(
  # "$HOME/Development/example-project/local-dev-certs/dev-client-cert.pem"
)
