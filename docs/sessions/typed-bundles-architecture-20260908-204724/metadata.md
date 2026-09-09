# typed-bundles-architecture-20260908-204724 — metadata

## Owners

| From | Until | Assistant | Session id | Model | Environment |
|---|---|---|---|---|---|
| 2026-09-09 | — | Claude | `session_01QvZrvKpoKwCmyLNjzXzCdQ` | `claude-opus-5` | Linux VM on the owner's Mac, reached through the desktop bridge. Bash 5.1.16(1) aarch64, GNU coreutils 8.32, Python 3.10.12. **Not macOS.** |

**Filled by the session on its first write, Revision 239.** It was empty on purpose until then.
Only the session itself knows its identifier, the model it was configured for and
the environment it actually runs in, and this bundle was created ahead of it by
`allocation-and-inquiry-design-20260906-233205` on the owner's allocation. Writing
a value here would be inventing one, which is the placeholder rule. `metadata.md`
stays authoritative for who has owned this bundle.

## Environment

Every check quoted by this session ran here, not on the target Mac, so the Bash 3.2 debt is extended and not paid. One operating constraint of this environment is not stated in any document: **git takes a lock to read**, and the connected folder refuses `unlink`, so `git status` or `git log` run in the owner's checkout can leave a `.git/index.lock` behind that blocks the owner's next commit. This session did exactly that on 2026-09-09 and the owner's commit cleared it. Standing rule adopted from that point: `ls` and `cat` in the checkout, every git command in the scratch copy. The finding this belongs to is `0038`'s subject and is not yet recorded.

## Resources

| Resource | Value |
|---|---|
| Repository checkout | `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit` |
| Scratch copy | `/sessions/rcw-01qvzrvkpokwcmylnjzxzcdq/scratch/fractogenesis-toolkit` |
| Commit copied from | `52a4376` |
| Patch directory | `/Users/dkittrell/reimage-workspace/patches` |
| `APPLY-MANIFEST.md` at creation | Revision 236 |

## Assignment

| Bundle | Path | Assigned | Status at assignment |
|---|---|---|---|
| 0037 | [`0037-findings-architecture-conformance`](../../session-management-findings/0037-findings-architecture-conformance/) | 2026-09-09 | Assigned. Not yet read |
| 0038 | [`0038-sessions-write-into-the-tree-the-owner-commits-from`](../../session-management-findings/0038-sessions-write-into-the-tree-the-owner-commits-from/) | 2026-09-09 | Assigned. Not yet read |
| 0045 | [`0045-a-session-whose-output-is-not-a-bundle-has-no-state`](../../session-management-findings/0045-a-session-whose-output-is-not-a-bundle-has-no-state/) | 2026-09-09 | Assigned. Not yet read |
| 0047 | [`0047-the-tree-carries-drift-no-check-looks-for`](../../session-management-findings/0047-the-tree-carries-drift-no-check-looks-for/) | 2026-09-09 | Assigned. Not yet read |
| 0048 | [`0048-the-session-capacity-limit-has-no-datum`](../../session-management-findings/0048-the-session-capacity-limit-has-no-datum/) | 2026-09-09 | Assigned. Not yet read |

Ownership is not stated in this file. It is derived by scanning
`findings-manifest.md` across `docs/sessions/`, which is the rule Revision 222
installed — **adding the manifest row IS the assignment**, and removing it is the
release.

## Transfers

| Bundle | Direction | From / To | Date | Revision |
|---|---|---|---|---:|
| [`0039`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | in | `session-management-re-evaluation-20260906-110105` | 2026-09-09 | 248 |

A transfer is a change of ownership and this file is authoritative for who held
what and when, which is why it is recorded on both sides. `0039` stands
`transferred` until this session's first write to it **as owner**; F21, F22,
F23 and D21 were written here as contributions while the bundle was owned
elsewhere, and a contribution is not an act of ownership.

## Contributions

| Bundle | Date | Contribution |
|---|---|---|
| [`0039`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | 2026-09-09 | F21 — nothing checks that a vocabulary change reached the prose; five consecutive revisions, measured |
| [`0039`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | 2026-09-09 | F22 — the `state-schema` currency watch is correct, unarmed, and cannot report drift |
| [`0039`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | 2026-09-09 | F23 and D21 — §7's commit-message rule states what the block excludes and never that there is one |

A contribution to a bundle this session does not own is recorded here and does
not change ownership. `0039` is owned by
`session-management-re-evaluation-20260906-110105`.
