# Extra credential-shaped filename patterns, added to the built-in floor.
#
# This fragment is OPTIONAL. Every script that needs to recognise a
# credential-shaped file already carries a built-in floor list (defined in
# .internal/artifact-config.sh as SECRET_SHAPES_FLOOR); this fragment only ever
# ADDS to it. There is deliberately no way to remove a floor shape:
#
#   - The floor is a security minimum. A workspace copy that silently dropped a
#     shape would weaken protection with no signal, which is exactly how the
#     external copy ended up with no secret filtering at all while the OneDrive
#     copy had twenty-two shapes.
#   - Nothing is lost to an over-broad shape. A match is not deleted, it is
#     staged into secrets-encrypted/staged-loose/ and encrypted into the Phase
#     3C DMG. The cost of a false positive is "this file is in the DMG instead
#     of the plaintext backup", not "this file is gone".
#
# Patterns are shell globs matched against the FILENAME only, never the path.
# They are consumed by bin/check-loose-secrets.sh (reports) and
# bin/stage-loose-secrets.sh (moves), so one line here changes both.
#
# Add shapes specific to this machine or employer, for example:
#   "*.acme-token"
#   "vault-*.yml"

SECRET_SHAPES_EXTRA=(
)
