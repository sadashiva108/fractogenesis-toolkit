# Session prompt — four pre-image runbook findings: read them, decide nothing

    Finding 0025 — docs/runbook-findings/backup-repos/0025-staged-ignored-files-live-parent-root-bundles/
    (runbook: backup-repos.md)

    Finding 0013 — docs/runbook-findings/capture-office-stability/0013-office-stability-checklists-are-evidence-bundles/
    (runbook: capture-office-stability.md)

    Finding 0007 — docs/runbook-findings/stage-loose-secrets/0007-content-scans-keeps-a-bespoke-index/
    (runbook: stage-loose-secrets.md)

    Finding 0019 — docs/runbook-findings/reimage-prep-checks/0019-reimage-checklist-repo-audit-manifest-header/
    (runbook: reimage-prep-checks.md)

## This session's only task

**Read everything named below and report what you understand. Nothing else.**

Do not decide anything. Do not propose a fix. Do not write, edit, create, move,
rename or delete any file — not in the repository, not in the artifact root, not
in the workspace root. Do not write an `APPLY-MANIFEST.md` entry beyond the one
for your own bundle described above.

The owner will say when to write. Until then the correct output of this session
is a report in the conversation and nothing on disk.

That constraint is deliberate and it is the point of the session. Two of these
four findings are entangled with work another session still holds, and one of
them says in its own text that the fix belongs in somebody else's task. A session
that starts fixing before it has read all four will make exactly the mistake the
findings describe.

## Read, in this order

1. **`.github/copilot-instructions.md`** — the instruction set. Sections 4b–4d
   define the bundle layout, the status and state vocabularies, and the numbering
   rule. Required first reading for every session, always.
2. **`docs/legend.md`** — the five finding statuses, the five session states, and
   the three kinds of write (record, toolkit, evidence). Note that a **record
   write** is ungated in general and is still not permitted in this session.
3. **`docs/architecture/findings-and-sessions.md`** — why the bundles are shaped
   as they are.
4. **This bundle's `findings-manifest.md`** — the four findings assigned here and
   what each one owes.
5. **The four `findings.md` files** named at the top, in the order listed. Read
   the bundle itself, not a summary of it.
6. **`docs/ledgers/artifact-migration-2026-09-02.md`** — Table 3 especially, and
   exception E5, which is where `0013`'s directory move is recorded as still owed.
7. **`docs/architecture/sign-off-consolidation.md`** — D6 defines what
   `checklists/` is allowed to mean, which is why `0013` is a naming defect and
   not a preference. §4 carries the `record_check WARN` defect `0013` says to fix
   in the same pass.
8. **`docs/sessions/run-index-design-20260901-000000/`** — the bundle these four
   findings came from. Read `handoff-20260902-000000.md` §4 ("What is next"),
   which describes **item 4**, and `findings-manifest.md`, which lists the ten
   findings it still holds.
9. **`docs/cross-cutting-findings/0009-dated-artifacts-cite-run-ids-a-rename-breaks/findings.md`**
   — every conversion in this area is a rename, and a rename breaks citations
   already written against the old name.
10. **`docs/cross-cutting-findings/0028-sessions-write-into-the-tree-the-owner-commits-from/findings.md`**
    — why this session composes nothing in the working tree. Owned by the
    `restore-apps-outstanding-20260903-000000` session; read it, do not touch it.

Then, for context on what the findings are about, read the four runbooks —
`backup-repos.md`, `capture-office-stability.md`, `stage-loose-secrets.md`,
`reimage-prep-checks.md` — and `.internal/artifact-runs.sh`, which is the run
index every one of these findings circles.

## What you are inheriting, and the two entanglements

All four findings were recorded by session `01KcZvrKMgfenhrT9DvxW9Jk` and were
owned by `run-index-design-20260901-000000`, which is in state `handoff` with
**item 4 unstarted**. The owner reassigns these four to you. That session keeps
its other ten findings and keeps item 4.

**Entanglement 1 — `0013` says its fix belongs to item 4.** In its own words the
disposition is *"fold into item 4's conversion of `office-stability/`"*, and it
explicitly warns against an interim rename because it would move the same
directories twice. Item 4 is still `run-index-design`'s. So this bundle owns the
finding and does not own the work that resolves it. Report that; do not try to
settle it.

**Entanglement 2 — `reimage-prep-checks/` is on item 4's candidate list.** The
handoff names it among the six categories item 4 audits. `0019` itself is
`resolved` and closed by Revision 129, so the overlap may be harmless — but
confirm that from the documents rather than assuming.

Two of the four — `0007` and `0019` — are already `resolved`. They are assigned
here so this bundle answers for the whole set, not because they need work. Read
them for the reasoning they preserve; `0007` in particular records what the
conversion turned up.

## Report this back, in the conversation only

- One paragraph per finding: what it says, its status, and what it would take to
  resolve it — described, not decided.
- Where the four touch each other and where they touch item 4.
- Anything in the four findings that the documents you read contradict, or that
  the tree no longer matches. Several of these notes are from 2026-09-01 and the
  tree has moved since.
- What you would need from the owner before any of it could be worked.

## Ground rules that apply the moment writing is authorised

Read these now so nothing is a surprise later.

- **The scratch-copy rules above this prompt apply for the whole session**:
  compose in the copy, keep it at one stable path, refresh it whenever a push
  lands and before deriving any patch, read every patch's file list, apply only on
  the owner's word, and never run `git commit`, `git push` or `git add`. The
  reasoning is finding `0028`.
- **Take the revision number at apply time**, from the `APPLY-MANIFEST.md` header
  read at that moment — never at write time. A concurrent session ships entries
  mid-task, and a number held while another session can take it is how two
  Revision 167s came to exist on 2026-09-03.
- **The gate is the whole bundle.** `resolving` begins only when every finding in
  a bundle has a decision in `decisions.md`, and nothing outside `docs/` is
  written before it.
- **Evidence writes need the owner, per run.** A session has no write permission
  to the artifact root by default; the owner grants it to one session at a time.
- **Portability floor is macOS stock Bash 3.2 and BSD userland.** No `mapfile`, no
  `declare -A`, no `sed -i`, no `stat -c`, no GNU-only flags. Prefer parallel
  indexed arrays and NUL-delimited traversal.
- **Validator baselines to hold:** doc paths **0 MISSING / 0 ANCHOR BROKEN**;
  runbook structure **213 PASS / 5 WARN / 25 FAIL** across 27 documents; script
  portability **0 WARN / 0 FAIL**. Do not quote the `OK` total as a baseline —
  finding `0026` explains why it moves for reasons unrelated to your work.

## Who else is writing

`restore-apps-outstanding-20260903-000000` is `owned` and active. It holds
`.github/copilot-instructions.md`, `docs/legend.md`,
`docs/runbook-findings/restore-apps/`, findings `0001`, `0027` and `0028`, and its
own bundle. Read those; do not write them.

`git status` is the only mechanism that has reliably shown another session's
uncommitted work. `docs/sessions/session-responsibilities.md` exists for this and
has been stale since 2026-09-01 — see
`docs/ideas/knowing-when-it-is-safe-to-write.md`.

## Resources

| What | Path |
|---|---|
| Repository | `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit` |
| Artifact root | `/Volumes/Data/reimage-CVG-0002160-500-20260816-open` |
| Workspace root | `/Users/dkittrell/reimage-workspace` |

The artifact root is **read-only to this session** and stays that way until the
owner says otherwise for a specific run.
