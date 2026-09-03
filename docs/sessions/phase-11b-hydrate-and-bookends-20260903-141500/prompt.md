# Session prompt — Phase 11B: hydrate, bookends, and the seven merged findings

**Written 2026-09-03, part-way through the session it briefs.** This is not a
reconstruction of the span already worked — Revisions 147 through 159 and 167 ran
on turn-by-turn direction, under no prompt, and inventing one after the fact would
put a fabricated artifact where §4d expects a real one. This prompt covers what
the bundle holds **from here**: seven findings merged in by the owner, and two
debts the session carries.

## Reading order

1. `.github/copilot-instructions.md` — the instruction set. Sections 4b–4d define
   the bundle layout, the status and state vocabularies, and the numbering rule.
   Read it before anything else, every time, regardless of state or scope.
2. `docs/legend.md` — the five finding statuses, the five session states, and the
   three kinds of write.
3. `docs/architecture/findings-and-sessions.md` — why the bundles are shaped as
   they are.
4. This bundle's `metadata.md` — who this session is, what it has written, and the
   two debts below.
5. This bundle's `findings-manifest.md` — the seven findings, and why `0027` is
   recorded here but not owned.
6. `docs/sessions/session-responsibilities.md` — the boundary with the concurrent
   session. Stale since 2026-09-01; `git status` is the mechanism that actually
   works. See `docs/ideas/knowing-when-it-is-safe-to-write.md`.

## What this bundle owns

Seven findings, merged by the owner on 2026-09-03 from the two `restore-repos-*`
bundles this same session produced. Five are `unresolved`:

| # | Subject |
|---:|---|
| 0008 | `carrier-services-storage` carries a remote pointing at `dotfiles` |
| 0011 | `emit_extra_remotes` re-adds the URL the clone already used |
| 0015 | The portability lint cannot see a defect that needs heredoc context |
| 0016 | `MANIFEST.txt` duplicates the category run index |
| 0017 | Every post-image-restore run on disk stops before its report |

`0006` and `0020` are `resolved`. `0027` is recorded by this session and **not
owned** — the owner said to record it and not address it, and ownership is theirs
to assign.

## The gate

Per Revisions 168 and 169: `resolving` is gated on **the whole bundle**, not one
finding. Every finding needs a decision in `decisions.md` before anything outside
`docs/` is written. Findings in one bundle bear on each other — `0016` and `0017`
both concern what a post-image-restore run records, and deciding one alone is how
a fix gets made twice.

Three kinds of write, from `docs/legend.md`:

- **Record write** — anything under `docs/`. Never gated; it is how deciding gets
  recorded.
- **Toolkit write** — any other tracked file (`bin/`, `.internal/`, the runbooks,
  `references/`, `templates/`, `.github/`, `.claude/`). Waits for `resolving`.
- **Evidence write** — the artifact root or the workspace root. Never without the
  owner saying so for that specific run.

`APPLY-MANIFEST.md` accompanies both record and toolkit writes and is gated by
neither.

## Two debts this session carries

1. **`/bin/bash -n` on real macOS Bash 3.2** is owed for Revisions 131, 142–159
   and 167, and for 116–130 before them. Every command this session ran was in a
   Linux VM with Bash 5.1 and GNU coreutils, where `mapfile`, `declare -A`,
   `sed -i` and `stat -c` all work silently. The portability lint catches the
   runtime constructs `-n` cannot see; the two are complements and only one has
   been run.
2. **`bookends/MANIFEST.md` has no rename row.** Four rows already carry
   `migrated from`; the `boundaries` → `bookends` rename added none. That is an
   evidence write and needs the owner's word for the run.

Also open, and the owner's call: whether `_pre-conversion-backup-20260902/` should
keep its original `boundaries/` and `checklist.md` names. It is a backup of the
pre-rename state, so leaving it is defensible.

## Standing rules for this session

- **Re-read the `APPLY-MANIFEST.md` header immediately before writing an entry**,
  never at task start. A concurrent session ships entries mid-task; this session
  has collided twice, once on Revision 159→167 and once on 167 itself.
- An uncommitted entry is invisible to the header the other session reads. On a
  collision, the later entry moves forward — the Revision 123 precedent.
- The concurrent session holds `.github/copilot-instructions.md`, `docs/legend.md`,
  `docs/runbook-findings/restore-apps/**` and its own bundle. Do not write those.
- Portability floor is macOS stock Bash 3.2 and BSD userland: no `mapfile`, no
  `declare -A`, no `sed -i`, no `stat -c`, no GNU-only flags. Parallel indexed
  arrays and NUL-delimited traversal.
- Validator baselines to hold: doc paths **0 MISSING / 0 ANCHOR BROKEN**; runbook
  structure **213 PASS / 5 WARN / 25 FAIL** across 27 documents; script
  portability **0 WARN / 0 FAIL**.

## Resources

| What | Path |
|---|---|
| Repository | `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit` |
| Artifact root | `/Volumes/Data/reimage-CVG-0002160-500-20260816-open` |
| Workspace root | `/Users/dkittrell/reimage-workspace` |
