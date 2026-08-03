[[create-secrets-dmg#Validate the Mounted DMG|← Back to Create Secrets DMG]]

# Manual-Export Pass Criteria Template

Create a working copy of this file under:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/manual-export-pass-criteria-YYYYMMDD.md
```

Fill it in while validating the mounted `all-secrets-*.dmg` in [[create-secrets-dmg#Validate the Mounted DMG|Create Secrets DMG → Validate the Mounted DMG]], before any loose plaintext staging is removed. It records that each intentionally exported category is inside the encrypted image. A category you intentionally skipped does not need to be present — note the skip. These rows roll up to the Phase 4B sign-off in `reimage-prep-checks.md`.

## Mounted DMG

| Item | Value |
|---|---|
| DMG path | `TODO` |
| Volume name | `TODO` |

## Pass criteria

| Capture area | Pass criteria | Status / Notes |
|---|---|---|
| Manual app exports | Chrome password CSV, Postman secret-bearing environments/Vault exports, Raycast `.rayconfig`, and sensitive Raycast Quick Links JSON are present inside the mounted DMG, if exported. | `TODO` |
| Keychain manual exports | `certs/keychain-manual-exports/` holds the intended exported certificates and identities, if exported. | `TODO` |
| Keychain records and PEM review | `certs/keychain-manual-exports/keychain-export-summary-*.md`, plus `extra-secrets-certs-review/decisions/keychain-manual-export-checklist-*.md.proposed` and `extra-secrets-certs-review/decisions/cert-restore-notes-*.md.proposed`, are present when created, and any `user-public-certificates-*.pem` has balanced BEGIN/END certificate blocks. | `TODO` |
| CA, developer, device, and tool exports | Internal CA chain plus tool-local, proxy/security root, MDM/device, Apple developer/provisioning, Apple root, and `com.apple.*` exports are present when manually exported. | `TODO` |
| Private-key-bearing artifacts | Any exported `.p12`, `.pfx`, `.jks`, `.keystore`, or `*.key` files exist only inside the encrypted DMG before loose cleanup. | `TODO` |
| Phase 2E selected cert material | `certs/loose-candidates-selected/`, `certs/project-local/`, and `certs/tool-local/` contain the intentionally staged selections, if used. | `TODO` |
| Phase 2E review artifacts | The current `extra-secrets-certs-review/` tree (`discovery/`, `plan/`, `decisions/`, and `MANIFEST.md`, including `discovery/configured-staged-files-*.tsv` when fragments were used) is present. | `TODO` |
| Public reference inventory | `public-certs/certs/keychain-cert-export-inventory-*.md` was reviewed as reference material — it is intentionally **not** inside the encrypted DMG. | `TODO` |
| Java trust overrides | `certs/java-security/` contains `jssecacerts` only when expected for the target JDK/JBR set. | `TODO` |

## Skipped categories and why

```text
TODO
```

## Evidence

| Item | Value |
|---|---|
| Completed by | `TODO` |
| Date | `TODO` |
