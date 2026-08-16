# STAGED CERTS — LOOSE CANDIDATES SELECTED
# Reviewed loose cert/key/truststore paths staged into
# secrets-encrypted/certs/loose-candidates-selected/. Sourced by stage-certs-keychain.sh.
#
# Format: one absolute path per entry — files or directories.
#
# Leave out anything Phase 3C already auto-captures, such as ~/.keystore,
# home-root *.jks, Desktop/Downloads cert bundles found by create-secrets-dmg.sh,
# and jssecacerts from JAVA_HOME, installed JDKs, or IntelliJ JBR.

STAGED_CERTS_LOOSE_CANDIDATES_SELECTED=(
  # "$HOME/path/to/local-only-required-file.p12"
)
