# drift-and-the-write-boundary-20260909-053548 — metadata

## Owners

| From | Until | Assistant | Session id | Model | Environment |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

**Empty on purpose.** This bundle was created ahead of its session at Revision
261 by `typed-bundles-architecture-20260908-204724`, and **only the session
itself knows its identifier, the model it was configured for and the environment
it actually runs in.** Writing a value here would be inventing one. A placeholder
belongs in a template and never in a record. **The session fills this row on its
first write** — `docs/rules/README.md` section 5, step 3.

## Environment

Not yet known. The session records it here on its first write, and names it
whenever it quotes a check — a result from a Linux VM is not a result from the
target Mac, and the Bash 3.2 debt is extended by every check that does not say so.
**This session quotes checkers for a living**, so the environment line matters
more here than anywhere: `docs/ledgers/target-platform-verification.md` carries
the only run this repository has had on the target, three checkers under
`/bin/bash` 3.2.57 against `4b721e7`.

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
| Scratch copy | filled by the session |
| Commit created against | `13b00b3` (Revision 260) |
| `APPLY-MANIFEST.md` at creation | Revision 261 |

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

None yet. A contribution to a bundle this session does not own is recorded here
and does not change ownership — and **a contribution does not clear a transfer
either**, which is why *first write **as owner*** is the wording in the manifest.
