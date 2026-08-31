[[create-secrets-dmg#Step 4 — Validate the Mounted DMG|← Back to Create Secrets DMG]]

# Manual-Export Pass Criteria (manual items only)

Create a working copy of this file under:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/manual-export-pass-criteria-YYYYMMDD.md
```

The automated presence, PEM-balance, and manifest checks are in the generated
`dmg-validation-*.md` report (see the runbook's Verification Reports). This note
records only what a script cannot judge. Fill it in after running `validate`,
before `cleanup --force`. These rows roll up to the Phase 6B sign-off in
`reimage-prep-checks.md`.

## Mounted DMG (from the validation report)

| Item | Value |
|---|---|
| DMG file | `TODO` |
| Validation report | `TODO` |

## Manual judgment

| Item | Confirmed | Notes |
|---|---|---|
| DMG password saved in an approved password manager | `[ ]` | |
| Every category I *intended* to export is present (intent is mine to judge) | `[ ]` | |
| Managed / non-exportable Keychain identities are documented, not silently missing | `[ ]` | |
| Any certificate copied to `public-certs/` was confirmed public-only | `[ ]` | |
| Java trust overrides in the DMG match the JDKs I actually need | `[ ]` | |
| Custom apps staged outside `secrets-encrypted/` were verified by hand | `[ ]` | |

## Skipped categories and why

```text
TODO
```

## Evidence

| Item | Value |
|---|---|
| Completed by | `TODO` |
| Date | `TODO` |
