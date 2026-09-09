# entity-model-and-vocabulary-20260909-053548 — metadata

## Owners

| From | Until | Assistant | Session id | Model | Environment |
|---|---|---|---|---|---|
| 2026-09-09 | — | Claude | `session_01LSgzo7EtPPVJ1gG8s4NVNW` | `claude-opus-5` | Linux VM on the owner's Mac, aarch64, Bash 5.1.16, GNU coreutils 8.32, Python 3.10.12 |

**Filled on this session's first write**, which is `0037` F8. **`claude-opus-5` is
the model this session was configured for**, which is what the field asks; the
harness withholds the identity of the model actually serving any given turn and it
may differ, recorded so a later reader knows the claim's exact reach.

**Was empty on purpose.** This bundle was created ahead of its session at Revision
261 by `typed-bundles-architecture-20260908-204724`, and **only the session
itself knows its identifier, the model it was configured for and the environment
it actually runs in.** Writing a value here would be inventing one. A placeholder
belongs in a template and never in a record. **The session fills this row on its
first write** — `docs/rules/README.md` section 5, step 3, which
`typed-bundles-architecture-20260908-204724` tested on itself at Revisions 237
and 239.

## Environment

**Not macOS, and no check quoted by this session is a target-platform result.**
Every command, check and patch runs in a Linux VM on the owner's Mac — aarch64,
Bash 5.1.16, GNU coreutils 8.32, Python 3.10.12 — reached through the desktop
bridge, against a scratch copy outside the checkout. The repository targets macOS
stock Bash 3.2; **the debt is extended, not paid.**

**The assistant does not run on the owner's machine.** It runs in a cloud
container with no access to the owner's filesystem except through that bridge, so
*where a check ran* and *where the session ran* are two facts, and this field is
asking about the first.

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
| Scratch copy | `/sessions/rcw-01lsgzo7etppvj1gg8s4nvnw/scratch/fractogenesis-toolkit`, in the Linux VM, outside the checkout and outside every connected folder. It dies with the session |
| Commit created against | `c2e2f01` (Revision 267), **plus Revision 268 applied to the checkout and not yet committed.** The scratch copy is baselined on that working tree, so the diff carries only this session's work |
| `APPLY-MANIFEST.md` at creation | Revision 261. **The head was 268 when this session began writing** — the checkout moved six revisions between the bundle being created and the session opening |

## Assignment

Nothing here was assigned. All four arrived by **transfer**.

## Transfers

| Bundle | Direction | From / To | Date | Revision |
|---|---|---|---|---:|
| [`0037`](../../session-management-findings/0037-findings-architecture-conformance/) | in | `typed-bundles-architecture-20260908-204724` | 2026-09-09 | 261 |
| [`0039`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | in | `typed-bundles-architecture-20260908-204724` | 2026-09-09 | 261 |
| [`0045`](../../session-management-findings/0045-a-session-whose-output-is-not-a-bundle-has-no-state/) | in | `typed-bundles-architecture-20260908-204724` | 2026-09-09 | 261 |
| [`0048`](../../session-management-findings/0048-the-session-capacity-limit-has-no-datum/) | in | `typed-bundles-architecture-20260908-204724` | 2026-09-09 | 261 |
| [`0043`](../../session-management-findings/0043-framework-state-lives-in-documents-not-data/) | in | `session-management-re-evaluation-20260906-110105` | 2026-09-09 | — |

A transfer is a change of ownership and this file is authoritative for who held
what and when, which is why it is recorded on both sides. **`0043`'s revision is
`—` because the number is taken at apply time** and this table is written while
composing; it is filled when the entry is written.

**`0043` moved at the owner's direction and not from an allocation.** Its holder
stands `handoff` with no successor, and `findings[]` → `members[]` is a schema
decision — closing deciding, which only an owner may do. **`0036` was considered
in the same operation and deliberately not moved**: it stands `answered`, and §10
permits a transfer only while a bundle is `un-started`, `reopened` or `analyzing`. **`0039` arrived here
having itself arrived by transfer at Revision 248** — from
`session-management-re-evaluation-20260906-110105`, which stands `handoff` with
no successor. This is its second move, and the record of both is in this table
and in the outgoing session's.

Ownership is not stated in this file. It is derived by scanning
`findings-manifest.md` across `docs/sessions/`, which is the rule Revision 222
installed — **adding the manifest row IS the assignment**, and removing it is the
release.

## Contributions

None. A contribution to a bundle this session does not own is recorded here and
does not change ownership — and **a contribution does not clear a transfer
either**, which is why *first write **as owner*** is the wording in the manifest.
That wording is now `0039` D24 rather than a practice: the owner ruled on
2026-09-09 that a status moves on a material change to the record, and a read is
not one.
