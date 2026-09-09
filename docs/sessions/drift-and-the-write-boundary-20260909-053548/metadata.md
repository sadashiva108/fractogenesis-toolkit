# drift-and-the-write-boundary-20260909-053548 — metadata

## Owners

| From | Until | Assistant | Session id | Model | Environment |
|---|---|---|---|---|---|
| 2026-09-09 | — | Claude | `session_01H9nWPECCmRoZDipJSYA2iS` | `claude-opus-5` | Ubuntu 22.04 aarch64 VM on the owner's Mac, GNU Bash 5.1.16, Python 3.10.12 |

**The row was empty on purpose until this revision.** The bundle was created
ahead of its session at Revision 261 by
`typed-bundles-architecture-20260908-204724`, and only the session itself knows
its identifier, the model it was configured for and the environment it actually
ran in. It is filled here, at this session's first write —
`docs/rules/README.md` section 5, step 3.

**`claude-opus-5` is the model this session was configured for**, which is the
field's question. The harness withholds the model actually serving a turn and it
can differ, so *configured for* is the fact available and the only one recorded.
Transcript: `https://claude.ai/code/session_01H9nWPECCmRoZDipJSYA2iS`.

## Environment

**Two machines, and every number in this session's revisions comes from the
second.** The assistant runs in an ephemeral Linux container in Anthropic's
cloud; that container reaches the owner's Mac over the desktop bridge, and the
bridge provides a shell in a **Linux VM on the Mac** with the connected folder
mounted into it. The scratch copy, the checkers and the test suite all run in
that VM.

| | |
|---|---|
| Kernel | `Linux 6.8.0-136-generic #136~22.04.1-Ubuntu SMP aarch64` |
| Shell | `GNU bash, version 5.1.16(1)-release (aarch64-unknown-linux-gnu)` |
| Python | `3.10.12` |

**This is not the target.** The repository targets macOS stock Bash 3.2 and
nothing here reaches it, so **every check this session quotes was run under Bash
5.1 with GNU coreutils** and is a different claim from the same check on the Mac.
`docs/ledgers/target-platform-verification.md` carries the only run this
repository has had on the target — three checkers under `/bin/bash` 3.2.57
against `4b721e7` — and this session adds nothing to it.

**One constraint follows from the bridge and it is this session's own subject.**
The mount refuses `unlink`, and git takes a lock to read, so a `git status`, a
`git log` or `bin/verify-doc-paths.sh` run in the owner's checkout can leave a
`.git/index.lock` behind that blocks the owner's next commit. **In the checkout:
`ls` and `cat` only.** Every git command, every checker and every test in this
session ran in the scratch copy.

**One constraint that is this session's own subject.** Git takes a lock to read,
and the connected folder refuses `unlink`, so `git status` or `git log` run in the
owner's checkout can leave a `.git/index.lock` behind that blocks the owner's next
commit. `bin/verify-doc-paths.sh` shells out to git, so running the checks there
does it too. **In the checkout: `ls` and `cat`. Every git command and every check
in the scratch copy.** That is `0038`'s subject arriving as an operating rule
before it arrives as a finding.

## Resources

| Resource | Value |
|---|---|
| Repository checkout | `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit` |
| Artifact volume | the mounted `reimage-…` run directory. **Read-only unless the owner grants a write per run** |
| Patch directory | `/Users/dkittrell/reimage-workspace/patches` |
| Scratch copy | `/sessions/rcw-01h9nwpeccmrozdipjsya2is/scratch/fg-268` — in the bridge VM, outside every connected folder. **It dies with the session.** The first copy was composed against Revision 263 and abandoned when the checkout moved to 267 |
| Commit created against | `13b00b3` (Revision 260) |
| `APPLY-MANIFEST.md` at creation | Revision 261 |
| Commit worked against | `c2e2f01` (Revision 267). Composed against `f345f3e` (Revision 263) and rebased onto it |

## Assignment

| Bundle | Path | Assigned | Standing at assignment |
|---|---|---|---|
| 0052 | [`0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check`](../../session-management-findings/0052-a-change-that-invalidates-earlier-work-has-no-plan-and-no-check/) | 2026-09-09 | `unclaimed`. Both findings `un-started`; nobody has written to it |

Ownership is not stated in this file. It is derived by scanning
`findings-manifest.md` across `docs/sessions/`, which is the rule Revision 222
installed — **adding the manifest row IS the assignment**, and removing it is the
release.

## Transfers

| Bundle | Direction | From / To | Date | Revision |
|---|---|---|---|---:|
| [`0038`](../../session-management-findings/0038-sessions-write-into-the-tree-the-owner-commits-from/) | in | `typed-bundles-architecture-20260908-204724` | 2026-09-09 | 261 |
| [`0047`](../../session-management-findings/0047-the-tree-carries-drift-no-check-looks-for/) | in | `typed-bundles-architecture-20260908-204724` | 2026-09-09 | 261 |

A transfer is a change of ownership and this file is authoritative for who held
what and when, which is why it is recorded on both sides. **`0052` is not in this
table**: it was `unclaimed`, owned by nobody, so there was no one to transfer it
from — the manifest row is an assignment.

## Contributions

A contribution to a bundle this session does not own is recorded here and does
not change ownership — and **a contribution does not clear a transfer either**,
which is why *first write **as owner*** is the wording in the manifest.

| Bundle | Date | Contribution |
|---|---|---|
| [`0039`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | 2026-09-09 | **F24** — `decisions.md` carries one `Session:` field and the Decisions table has no column for it, so a decision written by a session that does not own the bundle cannot be attributed, though §4 invites exactly that write. Found while recording D2, D3 and D4 into `0047`, whose D1 belongs to another session. **F25** — *What another session may do* carries seven of the eight standings and not `transferred`, which is the standing `0039` is in; writing F24 into it is the instruction and the finding at once |
