# STAGED CERTS — TOOL LOCAL
# Reviewed tool-local cert/key/truststore paths staged into
# secrets-encrypted/certs/tool-local/. Sourced by stage-certs-keychain.sh.
#
# Format: one absolute path per entry — files or directories.
#
# For local proxy, SDK, CLI, or tool-specific certificate material not already
# auto-captured by Phase 3C and still required after reimage.

STAGED_CERTS_TOOL_LOCAL=(
  # "$HOME/.tool/Certificates/internal-root.pem"
)
