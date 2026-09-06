# Sessions write into the tree the owner commits from

**Found:** 2026-09-03, session `session_019yzcjm2QneJ5ymVEQDi1bu`, on the owner's
observation that a session should hold its changes until told to release them.
Read: the day's own working tree, `git status` and `git log` across the two
concurrent sessions, `docs/ideas/knowing-when-it-is-safe-to-write.md`,
`0026-verify-doc-paths-counts-gitignored-docs`, `docs/legend.md`,
`.github/copilot-instructions.md` §§4b–4d, and all 27 existing findings bundles
checked for overlap.
**Severity:** two findings are high. Both are silent — nothing fails, and the
damage is to what the record can be trusted to mean.
**Scope:** cross-cutting. Tracked files only; the artifact volume is out of scope
and finding 6 says why.

## What is not the problem

Stated first, because the obvious reading of this bundle is "writing is unsafe"
and that is not what was found.

- **No work was lost.** Both revision-number collisions were caught and resolved
  by the existing precedent. The duplicated session bundle was caught and deleted.
- **The re-read-the-header rule works as written.** It was followed exactly, by
  both sessions, and still collided — which is a property of *when* the number is
  taken, not of anyone's compliance.
- **`git status` works.** It is the only mechanism in the current arrangement that
  actually detected a concurrent session's work, and it detected it every time
  someone looked.
- **The artifact volume is already serialised.** A session has no write permission
  to it by default, and the owner grants it to one session at a time.

## Findings

| # | Finding | Status |
|---|---|---|
| 1 | Two sessions' uncommitted work interleaves in shared files, so neither can be committed alone | `resolved` — 1.1, see `resolutions.md` |
| 2 | A revision's claimed validator baselines are measured on a tree containing another session's work | `resolved` |
| 3 | A session's work has no diff boundary, so the owner cannot review it as a unit | `resolved` |
| 4 | Backing out one session's change is surgical, because `git checkout` would take the other's too | `resolved` |
| 5 | A session can amend a revision the owner has already committed | `resolved` |
| 6 | The write discipline does not distinguish the write kinds `docs/legend.md` now names | `resolved` — 6.1, see `resolutions.md` |

Findings 1 and 2 are the high ones. The revision-number collision that prompted
the day's investigation is **not** a finding here — it is recorded in
`docs/ideas/knowing-when-it-is-safe-to-write.md`, along with three candidate
shapes for fixing it. This bundle is the reading of what the shared working tree
costs; that idea is one proposal against it. They should be read together and
resolved together.

### 1 — two sessions' work interleaves in files neither owns alone

Observed 2026-09-03. Both sessions edited `APPLY-MANIFEST.md` and
`docs/sessions/INDEX.md` in the same sitting, without conflict and without either
noticing until asked. At the point the owner tried to commit, the working tree
held Revision 167 (this session) and Revisions 166, 168 and 169 (the concurrent
one) in one file, and a row edit from each in the other.

Path-scoped staging cannot separate them: `git add <path>` takes the whole file.
The honest options were one commit covering both sessions, or `git add -p` hunk by
hunk on the two shared files. The owner took the first, and the resulting commit
attributes two sessions' work to one.

Every other file that day split cleanly by path. The two that did not are the two
that every session must write to — the manifest and the session index — so this is
not an unlucky overlap. It is structural, and it recurs on every concurrent
sitting.

That is the part `docs/ideas/knowing-when-it-is-safe-to-write.md` does not reach.
Its three shapes for knowing what is safe to write — a bundle declaring the files
it holds, deriving the answer from `git status`, a hook refusing an edit another
bundle claims — all work by keeping two sessions off the same file. Neither of
these two files can be kept off. Every session writes a manifest entry, and every
session bundle has a row in the index, so on those two the shapes degrade to
*wait your turn*, which is a schedule rather than a mechanism.

### 2 — a revision's validation is measured on somebody else's tree

Every `APPLY-MANIFEST.md` entry ends with a validation block: doc-path counts,
runbook structure counts, portability counts. The convention is that those numbers
belong to that revision.

**`0026` already made this argument**, on 2026-09-01 and about a different cause:
*"the honest response, 'the count moved and I did not cause it', is
indistinguishable from not having looked."* Read it first — the case for why an
unattributable baseline is worthless is made there and is not restated here.

What is new is the cause. `0026` is about the scanner's **scope**: it counted
`docs/`, so any parked note moved the total, and Revision 130 closed it by pruning
`docs/`. This is about **attribution**: the tree being measured also holds another
session's uncommitted work. Pruning a directory does not touch it, because the
concurrent session edits `.github/`, `bin/` and `docs/legend.md` too.

Observed: Revision 170 of this session reports **774 OK / 0 MISSING**,
**213 PASS / 5 WARN / 25 FAIL** and **81 clean**, measured with the concurrent
session's uncommitted edits to `.github/copilot-instructions.md`, `docs/legend.md`,
`docs/runbook-findings/restore-apps/**` and its own bundle in the same tree. True
of the tree, not attributable to the revision, and the entry does not say so.

`0026` is `resolved`, so it cannot carry this; a closed bundle reopened for an
unrelated mechanism stops being a record of what was decided. But its undecided
option **(iii)** — stop quoting an `OK` baseline in session briefs, track only
`MISSING` and `ANCHOR BROKEN` — is live, costs nothing, and would blunt this
finding without addressing it. Whoever decides this bundle should decide that
option with it.

### 3 — no diff boundary, so no unit to review

The owner's review surface for a session's work is `git status` and `git diff` on
a mixed tree. There is no artifact that says *these are the changes this session
is proposing*, so review is either all of it or a file at a time, and the
distinction between "reviewed and accepted" and "committed because it was there"
is not recorded anywhere.

This is what makes the owner's stated preference — draft first, write on the
word — unenforceable today. A session that writes as it goes has already spent
the reviewable moment by the time it reports.

### 4 — backing out is surgical

Revision 156 of this session substituted `bookend` for `checklist` in fourteen
places that should not have changed, one of which — `restore-repos.md:695`,
"Phase 14's checklist" — named the pre-image capstone and was flatly wrong. The
concurrent session found them.

The reversal was fourteen hand edits verified one at a time against
`git show 9fea5eb`, because `git checkout -- <file>` would have discarded the
correct substitutions in the same files, and by then the concurrent session was
also writing. A session's mistake is only cheaply revertible while its changes are
separable from everyone else's.

### 5 — a session can amend what the owner has already committed

Also 2026-09-03: this session amended Revision 150 while the owner was committing,
having read the manifest before their commit landed. It was backed out and written
as Revision 151 instead.

The failure is not the amendment; it is that nothing prevented it. A session
writing into the tree the owner commits from is writing into a moving target, and
the window between reading a file and writing it is exactly the window in which
the owner's commit happens.

### 6 — the write kinds are named but the discipline is not

Revision 169 gave `docs/legend.md` three categories: a **record write** under
`docs/`, ungated; a **toolkit write** to any other tracked file, gated on
`resolving`; an **evidence write** to the artifact or workspace root, needing the
owner's word for the specific run.

The categories say *when* a write is allowed. They say nothing about *where it is
composed*, and findings 1 through 5 are all about composition. Record writes are
ungated and are precisely the ones that collided today — the manifest and the
indexes are all under `docs/` or accompany it.

Evidence writes are the exception that shows the shape of the answer: they are
already safe, and not because of a rule anyone remembers. A session has no write
permission to the artifact volume by default, and the owner grants it to one
session at a time. Serialisation by permission, decided per run. Tracked files
have no equivalent.

## A tested alternative, offered as evidence not as a decision

Measured 2026-09-03 on this machine, so that whoever decides this bundle knows the
cost is not hypothetical.

The three validators self-locate their repository root from `BASH_SOURCE`
(`REPO_ROOT="$SCRIPT_DIR/.."`) and none of them invokes git — `verify-doc-paths.sh`
only prunes `.git` from its `find` traversal. A plain copy of the repository is
therefore a fully working tree for validation.

| | Copy outside the connected folders | Connected folder |
|---|---|---|
| doc paths | 774 OK / 0 MISSING / 0 ANCHOR BROKEN | identical |
| runbook structure | 213 PASS / 5 WARN / 25 FAIL, 27 docs | identical |
| script portability | 81 clean / 0 WARN / 0 FAIL | identical |

The copy is 5.8M without `.git` and 22M with, taking 0.15s and 0.54s. With `.git`
included the copy is a real working tree, so `git diff` there produces a patch;
`git apply --check` accepted that patch against the live repository with the live
working tree left untouched, verified by `git status` immediately after.

That answers findings 2 and 3 directly — validation runs against one session's
changes alone, and the patch is the reviewable unit. It answers 1, 4 and 5 by
removing the shared tree they all depend on. It does not answer the revision
number, which is `docs/ideas/knowing-when-it-is-safe-to-write.md`'s second shape:
take the number at apply time, when only one session is writing.

What it does not solve is worth recording with it. A copy in session-local scratch
dies with the session, so unapplied work is lost if a session ends unexpectedly —
it survives context compaction, which is the larger risk, but not termination.
And it is the same Linux VM with Bash 5.1 and GNU coreutils: **`/bin/bash -n`
against real macOS Bash 3.2 remains owed for Revisions 116–170** and no scratch
arrangement reaches it.

## What it costs to leave

Findings 1, 4 and 5 cost effort and attention, and were all absorbed today without
loss — that is the argument for treating this as unresolved rather than urgent.

Finding 3 costs the owner the review they asked for: the preference is stated, and
the arrangement makes it unenforceable.

Finding 2 is the one that compounds. Every revision written under a shared tree
records a baseline that cannot be attributed to it, and those baselines are what
the next reader compares against. Nothing detects it, nothing fails, and the
record quietly stops meaning what it says.
