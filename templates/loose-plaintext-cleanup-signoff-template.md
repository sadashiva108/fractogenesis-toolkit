[[create-secrets-dmg#Clean Up Loose Plaintext After Validation|← Back to Create Secrets DMG]]

# Loose Plaintext Cleanup Sign-Off Template

Create a working copy of this file under:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/loose-plaintext-cleanup-signoff-YYYYMMDD.md
```

Fill it in before removing loose plaintext staging in [[create-secrets-dmg#Clean Up Loose Plaintext After Validation|Create Secrets DMG → Clean Up Loose Plaintext After Validation]]. Every prerequisite must be true before cleanup, because cleanup deletes plaintext secrets. These rows roll up to the Phase 4B sign-off in `reimage-prep-checks.md`.

## Mounted DMG

| Item | Value |
|---|---|
| DMG path | `TODO` |
| Volume name | `TODO` |

## Cleanup prerequisites

| Prerequisite | Why it matters | Status / Notes |
|---|---|---|
| DMG exists and mounts successfully | Cleanup is unsafe until the encrypted restore artifact is confirmed readable. | `TODO` |
| DMG password saved in an approved password manager | The restore path must not depend on memory or an untracked note. | `TODO` |
| Core secret directories present in the mounted DMG | At minimum GPG private keys and SSH keys, plus other foundational restore material for this machine. | `TODO` |
| Java trust overrides present, if expected | `certs/java-security/` must be inside the mounted DMG before loose truststore staging is removed. | `TODO` |
| Manual app exports present, if exported | Chrome, Postman, and Raycast exports must be inside the mounted DMG before loose plaintext app staging is deleted. | `TODO` |
| Manual Keychain exports and records present, if created | `certs/keychain-manual-exports/` plus the export summary, checklist, restore notes, and any PEM must survive inside the DMG before cleanup. | `TODO` |
| Private-key-bearing exports present only inside the DMG | `.p12`, `.pfx`, `.jks`, `.keystore`, and `*.key` files must not remain as loose plaintext staging after cleanup. | `TODO` |
| Phase 2E selected cert material present, if staged | `certs/loose-candidates-selected/`, `certs/project-local/`, and `certs/tool-local/` must be preserved in the mounted DMG before removal. | `TODO` |
| Phase 2E review artifacts present | The current `extra-secrets-certs-review/` report set, and configured staged-file reports if used, should be inside the mounted DMG first. | `TODO` |
| Manifest and RESTORE-README exist | `all-secrets-*-manifest.txt` and `RESTORE-README.md` should still exist after cleanup. | `TODO` |

## Cleanup scope

```text
[ ] Full loose staging cleanup
[ ] Partial cleanup with intentional leftovers
```

## Intentional leftovers and why

```text
TODO
```

## Evidence

| Item | Value |
|---|---|
| Completed by | `TODO` |
| Date | `TODO` |
