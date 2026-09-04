# Resolutions — `office-stability/checklists/` does not hold checklists

**Bundle:** `0013-office-stability-checklists-are-evidence-bundles` · **Status:** `resolved`
**Recorded:** 2026-09-03, session `session_01PcgHu9kz9Hm5RatLQuFR8H`.

The finding is closed by work that had already shipped, plus one edit made here.

| What | Resolved by | Where |
|---|---|---|
| `checklists/` holds evidence bundles that are really runs | **Revision 138** | Bundles moved to `office-stability/runs/` under two lineages; `checklists/` removed; the assessment sign-off extracted to `office-stability/sign-offs/`. Verified on the volume 2026-09-03 |
| The producer emits manual items as `record_check WARN` rows inside the automated table | **Revision 137** | `office-stability-checklist.sh` became `bin/assess-office-stability.sh`; the rows became `signoff_begin` / `signoff_row` at lines 713–727 |
| `latest-pre-image-office-stability-checklist.txt`, a legacy pointer | **Revision 138** | Replaced by `official/`. The old pointer survives only in `_pre-conversion-backup-20260902/` |
| The two lineage names were nowhere defined | **this revision** | `capture-office-stability.md` → `### Terminology` gains an `Evidence` row and an `Assessment` row |

## The one edit made here

`capture-office-stability.md`, two rows in the `Terminology` table:

> **Evidence** — the collector's run, `<phase>-office-stability-evidence`. Holds
> the numbered section files, the run summary, and the baseline ZIP. Written by
> `capture-office-stability.sh` at Step 3.
>
> **Assessment** — the assessor's run, `<phase>-office-stability-assessment`.
> Holds its verdict and the per-check evidence behind that verdict. Written by
> `assess-office-stability.sh` at Step 4.

Placed after *Workload snapshot* and before *Phase*, per the runbook prompt's rule
that ambiguous domain terms are defined in the glossary before the steps rely on
them — Step 3 is the first step that does. `**Last updated:**` moved to
2026-09-03. Nothing else in the runbook changed.

The distinction was already stated, once, in a Bundle Layout sentence. Decision 3
records why that was not enough: the table exists to answer *which lineage is
which*, defines six terms, and did not define these two — which is why the
question had to be settled from the volume rather than from the document.

## What was decided and not done

The two lineages stand and the names are correct: `assessment` names the run that
holds the verdict. The single lineage `findings.md` proposed was rejected, and so
was swapping the names — decision 2 carries both, with the reasons.

The `--phase` values in the `Phase` row still read `pre-reimage` / `post-reimage`,
and that is correct: `capture-office-stability.sh` maps its internal label to the
`pre-image` run context deliberately, commented at line 495, with a reader
depending on the old prefix at `reimage-checklist.sh:1609`. Decision 5 rejected
folding that into this edit.

## Still owed by others, named in decision 5

Not this bundle's, and listed so they are not rediscovered: `0030` holds the
missing `rename` row in `office-stability/MANIFEST.md` and the two README
citations it repaired; and `sign-off-consolidation.md` §4 and §6 and
`evidence-conformance.md` Table 3 and line 213 still describe the
pre-Revision-138 shape and the renamed producer. That last one has no bundle.

## Validation

Documentation lint: 0 MISSING, 0 ANCHOR BROKEN. Runbook structure 213 PASS /
5 WARN / 25 FAIL across 27 documents, unchanged — the edited runbook gains no
section, so the Table of Contents is untouched. No script changed, so no
portability run was owed and no new macOS Bash 3.2 debt was taken. Ran on Linux
with Bash 5.1; nothing here was validated on the target Mac, and nothing here is
executable.

Composed in a copy outside the owner's checkout and handed over as a patch, per
`0028`; revision number taken at apply time with
`./bin/check-manifest-revision.sh`.
