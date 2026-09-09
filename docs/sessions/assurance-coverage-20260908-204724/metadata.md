# assurance-coverage-20260908-204724 — metadata

## Owners

| From | Until | Assistant | Session id | Model | Environment |
|---|---|---|---|---|---|
| 2026-09-09 | — | Claude | `session_01Wd7US5C5Msr594vNidboLn` | `claude-opus-5` | Linux VM, Bash 5.1.16(1) aarch64, GNU coreutils. **Not macOS.** |

Transcript link: `https://claude.ai/code/session_01Wd7US5C5Msr594vNidboLn`

The row was empty at creation because this bundle was made ahead of the session
by `allocation-and-inquiry-design-20260906-233205` on the owner's allocation, and
only the session knows these values. It is filled here on the session's first
write, which is what `metadata.md` said would happen.

## Environment

Every command this session ran executed in a Linux virtual machine with GNU
coreutils and Bash 5.1.16 on aarch64, reached over the desktop bridge. The
repository targets **macOS stock Bash 3.2 and BSD userland**, and this session
has run nothing there. **No number in these records is a claim about the target
platform.** `bin/verify-script-portability.sh` is the only check whose Linux
result carries to macOS, because it reads for constructs rather than executing
them.

The configured model identifier is `claude-opus-5`. The model actually serving a
turn can differ from the configured one, so this records what it was configured
for, which is the only thing the session can state as fact.

**This session writes through the desktop bridge**, not through the assistant's
own file tools. That is why `0050` F1 exists: the guard installed at Revision 232
to catch a write into the checkout matches `Edit|Write|MultiEdit|Bash` and does
not see either bridge tool, so **nothing guarded any write this session made.**
The composing rule was followed by discipline, in a scratch copy at the path
below, and verified by `git status` in the checkout rather than by any guard.

## Resources

| Resource | Value |
|---|---|
| Repository checkout | `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit` |
| Scratch copy | `/sessions/rcw-01wd7us5c5msr594vnidboln/scratch/fractogenesis-toolkit` — dies with the session |
| Commit copied from | `52a4376` — Revision 238, clean tree, no uncommitted work |
| `APPLY-MANIFEST.md` at copy time | Revision 238 applied; 239 next free |
| Artifact root | `/Volumes/Data/reimage-CVG-0002160-500-20260816-open` — connected, not mounted, not read |

The scratch copy was taken from a **clean** checkout, so every path in the patch
derived from it is this session's own. That was checked with `git status --short`
before the copy and the file list was read against the change set before the
patch was handed over — `0049` F3.

## Assignment

| Bundle | Path | Assigned | Standing after the first reading |
|---|---|---|---|
| 0040 | [`0040-superseding-a-bundle-whose-session-is-gone`](../../session-management-findings/0040-superseding-a-bundle-whose-session-is-gone/) | 2026-09-09 | `answered` — all four resolved against Revision 200 |
| 0041 | [`0041-index-and-manifest-tables-have-a-shape-nothing-checks`](../../session-management-findings/0041-index-and-manifest-tables-have-a-shape-nothing-checks/) | 2026-09-09 | `analyzing` — F1 resolved, four `decided` |
| 0042 | [`0042-no-check-reads-the-rendered-page`](../../session-management-findings/0042-no-check-reads-the-rendered-page/) | 2026-09-09 | `analyzing` — F2 resolved, three `decided` |
| 0044 | [`0044-citations-under-docs-resolve-nowhere-and-nothing-reads-them`](../../session-management-findings/0044-citations-under-docs-resolve-nowhere-and-nothing-reads-them/) | 2026-09-09 | `answered` — both resolved, tree repaired |
| 0046 | [`0046-supersession-moves-authority-and-leaves-every-citation-behind`](../../session-management-findings/0046-supersession-moves-authority-and-leaves-every-citation-behind/) | 2026-09-09 | `analyzing` — both `decided`, nothing repaired on purpose |
| 0049 | [`0049-the-patch-is-named-as-the-deliverable-and-never-produced`](../../session-management-findings/0049-the-patch-is-named-as-the-deliverable-and-never-produced/) | 2026-09-09 | `analyzing` — F2 and F3 resolved against Revision 232 |

| 0050 | [`0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record`](../../session-management-findings/0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record/) | 2026-09-09 | `analyzing` — recorded here unowned, assigned the same day; F5 added on the first reading |
| 0053 | [`0053-the-rules-are-versioned-and-a-sessions-reading-of-them-is-not`](../../session-management-findings/0053-the-rules-are-versioned-and-a-sessions-reading-of-them-is-not/) | 2026-09-09 | `analyzing` — recorded here unowned, assigned the same day; F3 added on the first reading |

Ownership is not stated in this file. It is derived by scanning
`findings-manifest.md` across `docs/sessions/`, which is the rule Revision 222
installed — **adding the manifest row IS the assignment**, and removing it is the
release.

## Contributions

| Bundle | Date | Contribution |
|---|---|---|
| `0050` | 2026-09-09 | Recorded the bundle from the reading that decided `0049` and `0042`. **Not owned** — three of its four fixes are toolkit writes and the bundle type for those does not exist yet |
| — | 2026-09-09 | Wrote `docs/ideas/the-collection-and-the-project.md`, a commission for separating the collection management system from the project. Not a bundle contribution — a commission has no bundle to belong to yet, which is the document's own subject |
