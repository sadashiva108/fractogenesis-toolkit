# APPLY-MANIFEST.md is on every session's path and grows without bound

**Recorded:** 2026-09-10, by `drift-and-the-write-boundary-20260909-053548`, which does not own it  
**Session:** `drift-and-the-write-boundary-20260909-053548`  
**Severity:** moderate. The file is read by every revision to take a number and appended by every revision to record one, so its cost is paid by every session at once; and it is the file that conflicts in every rebase  
**Felt at:** `APPLY-MANIFEST.md`; `.share/check-manifest-revision.sh`; every rebase performed on 2026-09-10  
**Scope:** the manifest and what reads it. The rules governing it are §7, which is `entity-model-and-vocabulary-20260909-053548`'s  
**Relates to:** `0038` — every session writes into this one file

## Contributions

| Session | Date | Contribution |
|---|---|---|
| `drift-and-the-write-boundary-20260909-053548` | 2026-09-10 | Recorded both findings from measurements taken while rebasing onto the file three times |

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | `APPLY-MANIFEST.md` is read and appended by every session and grows without bound, so its cost rises for everyone at once and no rule bounds it | `framing` |
| F2 | The manifest is the file that conflicts in every rebase, because every session appends at the same place | `framing` |

## F1 — one file on every session's read path, growing without a bound

**Measured 2026-09-10 at Revision 298**, in a clone of the owner's checkout:

| | |
|---|---:|
| size | **1,247,521 bytes (1.19 MB)** |
| lines | 18,120 |
| entries | 468 |
| growth, last 30 commits | **+180,670 bytes**, across two days |
| growth per revision, last 10 | **+8,162 bytes** mean, range 5,172–13,118 |

**Every session reads it and every session appends to it.**
`.share/check-manifest-revision.sh` scans it to take a revision number, which §7
requires of every revision, so the file is on the path of every act this
framework performs. **Nothing bounds it and nothing prunes it**, and the entries
are the framework's only durable account of why each revision exists, so deleting
them is not available.

**The owner has raised the read cost twice** — *"APPLY-MANIFEST.md is slow at
loading and getting big"* — and until this record it was written down nowhere,
which is `0054`'s shape: a document that changes without anything watching it,
here a document that grows without anything watching it.

**What is not claimed.** No remedy is proposed. Splitting by revision range,
archiving closed entries, or moving the body out of the file each session must
read are all plausible and each changes what §7 governs. **§7 is
`entity-model-and-vocabulary-20260909-053548`'s**, and a bundle recorded by a
session that does not own the section is a reading, not a decision.

## F2 — the conflict is structural, not incidental

**Three of three rebases performed by this session conflicted on this file**, and
on nothing else except the two `INDEX.md`s. Every session inserts its entry at the
same place — the top — so two sessions composing concurrently always collide
there, whatever else they touched.

**This is `0038`'s subject with a single named file.** `0038` records that
sessions compose in the tree the owner commits from; F2 records that one file
guarantees the collision even when they do not otherwise overlap. The cost is
paid on every rebase by whichever session applies second.

**Not the same as F1 and recorded separately**: a remedy for size — archiving old
entries — does nothing for the conflict, because the collision is at the head of
the file where the newest entry goes. A remedy for the conflict — appending at
the tail, or one file per revision — would change what a reader and
`check-manifest-revision.sh` must do, and that is §7's to decide.
