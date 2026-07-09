# IT Reimage Confirmation Template

Create a working copy of this file outside this repo, for example:

```text
$HOME/Documents/reimage-planning/it-reimage-confirmation-YYYYMMDD.md
```

Fill it in during [[reimaging-guide#Phase 0 — Confirm the Reimage Plan with IT|Phase 0 — Confirm the Reimage Plan with IT]], then copy the filled version into:

```text
$REIMAGE_ARTIFACT_ROOT/reimage-plan/it-reimage-confirmation-YYYYMMDD.md
```

during [[reimaging-guide#Phase 1 — Prepare the External Artifact Root|Phase 1 — Prepare the External Artifact Root]] after the external root and `reimage-plan/` directory exist.

This confirmation matters because it records the approved wipe method, owner, timing, and restore constraints before anything destructive starts.

## IT confirmation table

| Question | Answer / Notes |
|---|---|
| Who initiates the reimage? | `TODO` |
| Is this IT-initiated, Company Portal self-service, Apple Erase Assistant, or macOS Recovery? | `TODO` |
| Is the Mac erased, refreshed, repaired, or re-enrolled? | `TODO` |
| Will local user data be wiped? | `TODO` |
| Will FileVault be rotated, escrowed, or re-enabled automatically? | `TODO` |
| Will the same hostname / asset name be preserved? | `TODO` |
| Will the same local username be recreated? | `TODO` |
| Will admin rights be available temporarily for setup? | `TODO` |
| Will Microsoft Office be installed by Company Portal, Intune, Microsoft AutoUpdate, or another channel? | `TODO` |
| Should Apple ID / iCloud be signed out before handoff? | `TODO` |
| Should OneDrive be unlinked before handoff? | `TODO` |
| Should Time Machine be run first? | `TODO` |
| Should the external `Data` drive be disconnected before reimage starts? | Yes. Disconnect after final verification. |

## Suggested message to IT

```text
Before I proceed with the reimage, can you confirm the approved process for this Mac?

I need to know whether this will be IT-initiated or self-service, whether local user data will be erased, how Company Portal / Intune will participate, and whether I should sign out of Apple ID, OneDrive, Office, or anything else before handoff.

I also need to know whether Office will be installed from one approved channel after the reimage, since Outlook and OneNote have had closure/update issues.
```

## Evidence

| Item | Value |
|---|---|
| Confirmation received from | `TODO` |
| Confirmation date/time | `TODO` |
| Channel | `TODO` |
| Link/screenshot saved at | `TODO` |
