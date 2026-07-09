# App Backup and Cloud Sync Sign-Off Template

Create a working copy of this file under:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/manual-app-export-and-sync-signoff-YYYYMMDD.md
```

Fill it in only for the manual rows that `reimage-checklist.sh` cannot prove automatically: VS Code Settings Sync state, OneDrive/iCloud sync completion, and export-password custody. Automated rows (Chrome bookmarks/password CSV staged, Postman exports, Keychain manual exports staged, certificate/Keychain review inventory) are already covered by the generated report — use this note only to record the remaining manual confirmation.

## Summary

| Item | Status | Evidence / Notes |
|---|---|---|
| Chrome bookmarks exported or Chrome sync confirmed | `TODO` |  |
| Chrome password CSV exported to secret-bearing staging or intentionally skipped | `TODO` |  |
| Postman collections exported or intentionally skipped | `TODO` |  |
| Postman environments/vault handled as secret-bearing, redacted, or intentionally skipped | `TODO` |  |
| Optional app backups reviewed, if used | `TODO` |  |
| Certificate/Keychain directories created and reviewed | `TODO` |  |
| Keychain/certificate exports staged under `secrets-encrypted/certs/` or intentionally skipped | `TODO` |  |
| Export passwords saved only in approved password manager, if applicable | `TODO` |  |
| VS Code Settings Sync state confirmed | `TODO` |  |
| OneDrive sync has no pending uploads | `TODO` |  |
| iCloud Drive sync has no pending uploads, if used | `TODO` |  |

## Sign-off

- [ ] App backups are complete or intentionally skipped.
- [ ] Optional app backups are complete or intentionally skipped.
- [ ] Certificate and Keychain exports are staged or intentionally skipped.
- [ ] Cloud sync state is known and recorded.
- [ ] Any cloud copy being relied on has been spot-checked outside the local folder.
- [ ] No secret-bearing files, certificate private keys, `.p12` / `.pfx` files, keystores, Chrome password CSVs, or unreviewed exports were placed loose in OneDrive or iCloud.
- [ ] This note has been reviewed before Phase 4B final validation.

## Evidence

| Item | Value |
|---|---|
| Completed by | `TODO` |
| Date | `TODO` |
