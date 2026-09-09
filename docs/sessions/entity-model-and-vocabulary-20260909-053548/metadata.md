# entity-model-and-vocabulary-20260909-053548 — metadata

## Owners

| From | Until | Assistant | Session id | Model | Environment |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

**Empty on purpose.** This bundle was created ahead of its session at Revision
261 by `typed-bundles-architecture-20260908-204724`, and **only the session
itself knows its identifier, the model it was configured for and the environment
it actually runs in.** Writing a value here would be inventing one. A placeholder
belongs in a template and never in a record. **The session fills this row on its
first write** — `docs/rules/README.md` section 5, step 3, which
`typed-bundles-architecture-20260908-204724` tested on itself at Revisions 237
and 239.

## Environment

Not yet known. The session records it here on its first write, and names it
whenever it quotes a check — a result from a Linux VM is not a result from the
target Mac, and the Bash 3.2 debt is extended by every check that does not say so.

**One constraint the outgoing session learned the hard way and it is not in any
instruction set.** Git takes a lock to read, and the connected folder refuses
`unlink`, so `git status` or `git log` run in the owner's checkout can leave a
`.git/index.lock` behind that blocks the owner's next commit.
`bin/verify-doc-paths.sh` shells out to git, so running the checks there does it
too. **In the checkout: `ls` and `cat`. Every git command and every check in the
scratch copy.**

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

Nothing here was assigned. All four arrived by **transfer**.

## Transfers

| Bundle | Direction | From / To | Date | Revision |
|---|---|---|---|---:|
| [`0037`](../../session-management-findings/0037-findings-architecture-conformance/) | in | `typed-bundles-architecture-20260908-204724` | 2026-09-09 | 261 |
| [`0039`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | in | `typed-bundles-architecture-20260908-204724` | 2026-09-09 | 261 |
| [`0045`](../../session-management-findings/0045-a-session-whose-output-is-not-a-bundle-has-no-state/) | in | `typed-bundles-architecture-20260908-204724` | 2026-09-09 | 261 |
| [`0048`](../../session-management-findings/0048-the-session-capacity-limit-has-no-datum/) | in | `typed-bundles-architecture-20260908-204724` | 2026-09-09 | 261 |

A transfer is a change of ownership and this file is authoritative for who held
what and when, which is why it is recorded on both sides. **`0039` arrived here
having itself arrived by transfer at Revision 248** — from
`session-management-re-evaluation-20260906-110105`, which stands `handoff` with
no successor. This is its second move, and the record of both is in this table
and in the outgoing session's.

Ownership is not stated in this file. It is derived by scanning
`findings-manifest.md` across `docs/sessions/`, which is the rule Revision 222
installed — **adding the manifest row IS the assignment**, and removing it is the
release.

## Contributions

None yet. A contribution to a bundle this session does not own is recorded here
and does not change ownership — and **a contribution does not clear a transfer
either**, which is why *first write **as owner*** is the wording in the manifest.
