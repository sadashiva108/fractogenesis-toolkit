[[create-secrets-dmg#Step 5 — Clean Up Loose Plaintext After Validation|← Back to Create Secrets DMG]]

# Loose Plaintext Cleanup Sign-Off (manual items only)

Create a working copy of this file under:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-prep-checks/manual/loose-plaintext-cleanup-signoff-YYYYMMDD.md
```

The automated "what was removed / kept" record is in the generated `cleanup-*.md`
report, and DMG contents are verified in `dmg-validation-*.md` (see the runbook's
Verification Reports). This note records only the human decisions. Fill it in
before running `cleanup --force`. These rows roll up to the Phase 6B sign-off in
`reimage-prep-checks.md`.

## Manual judgment

| Item | Confirmed | Notes |
|---|---|---|
| The DMG password is saved in an approved password manager | `[ ]` | |
| I reviewed the `dmg-validation-*.md` report and it had no FAIL | `[ ]` | |
| Any category the cleanup KEPT (not in the DMG) is intentional | `[ ]` | |

## Cleanup scope

```text
[ ] Full cleanup (cleanup --force)
[ ] Partial (kept one or more categories via --keep, or by hand)
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
