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

| Resource | Value | What it meant in practice |
|---|---|---|
| Repository checkout | `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit` | **`ls` and `cat` only.** Git takes a lock to read, the connected folder refuses `unlink`, and a `.git/index.lock` left here blocks the owner's next commit. This session caused that twice before adopting the rule, and `bin/verify-doc-paths.sh` shells out to git, so the checks moved to scratch with everything else. Every apply was a whole-file copy from scratch, never `git apply` |
| Scratch copy | `/sessions/rcw-01qvzrvkpokwcmylnjzxzcdq/scratch/fractogenesis-toolkit` | Where every revision was composed and verified and where every git command ran. Reset hard to `origin/main` before each revision, which made a rebase after a number collision a replay rather than a merge. Dies with the session |
| Commit copied from | `52a4376` | Revision 238's, and **the only tree state this record names.** The session went on to work against `13b00b3` (260), `2dfcaa6` (261), `3f367db` (262), `f345f3e` (263) and `d9996f5` (264), and no field records any of them — `0053`'s subject, and `0043` F10's one level up |
| Patch directory | `/Users/dkittrell/reimage-workspace/patches` | Three patches, named by revision: 261, 262, 263. The **review artefact**, not the delivery mechanism |
| Artifact volume | the mounted `reimage-CVG-0002160-500-20260816-open` run directory | **Connected and in scope for the whole session, and never read or written by it.** Recorded because *available and unused* is a fact about a session, and an absent row reads as *not connected* |
| `APPLY-MANIFEST.md` at creation | Revision 236 | The bundle was created at 237, one revision later |

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
| [`0037`](../../session-management-findings/0037-findings-architecture-conformance/) | out | `entity-model-and-vocabulary-20260909-053548` | 2026-09-09 | 261 |
| [`0039`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | out | `entity-model-and-vocabulary-20260909-053548` | 2026-09-09 | 261 |
| [`0045`](../../session-management-findings/0045-a-session-whose-output-is-not-a-bundle-has-no-state/) | out | `entity-model-and-vocabulary-20260909-053548` | 2026-09-09 | 261 |
| [`0048`](../../session-management-findings/0048-the-session-capacity-limit-has-no-datum/) | out | `entity-model-and-vocabulary-20260909-053548` | 2026-09-09 | 261 |
| [`0038`](../../session-management-findings/0038-sessions-write-into-the-tree-the-owner-commits-from/) | out | `drift-and-the-write-boundary-20260909-053548` | 2026-09-09 | 261 |
| [`0047`](../../session-management-findings/0047-the-tree-carries-drift-no-check-looks-for/) | out | `drift-and-the-write-boundary-20260909-053548` | 2026-09-09 | 261 |

A transfer is a change of ownership and this file is authoritative for who held
what and when, which is why it is recorded on both sides. `0039` stands
`transferred` until this session's first write to it **as owner**; F21, F22,
F23 and D21 were written here as contributions while the bundle was owned
elsewhere, and a contribution is not an act of ownership.

**Six transfers out at Revision 261, and nothing released to `unclaimed`.** The
session stands `handoff`, owns nothing, and every bundle it held has a named
owner from the moment that revision is committed —
`docs/sessions/INDEX.md`'s condition that a session may not end leaving a bundle
owned by a session that has stopped. **`0039` leaves having arrived by transfer**,
so this table records both legs of its journey and is the only place they sit
together. `0052`, recorded here and never owned, is not in this table: it was
`unclaimed`, and an assignment is not a transfer. The record is
[`handoff-20260909-053548.md`](handoff-20260909-053548.md).

## Contributions

| Bundle | Date | Contribution |
|---|---|---|
| [`0039`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | 2026-09-09 | F21 — nothing checks that a vocabulary change reached the prose; five consecutive revisions, measured |
| [`0039`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | 2026-09-09 | F22 — the `state-schema` currency watch is correct, unarmed, and cannot report drift |
| [`0039`](../../session-management-findings/0039-the-instruction-set-lags-the-rules-it-governs/) | 2026-09-09 | F23 and D21 — §7's commit-message rule states what the block excludes and never that there is one |
| [`0043`](../../session-management-findings/0043-framework-state-lives-in-documents-not-data/) | 2026-09-09 | F10 — a terminal session's disposal exists only in prose: the `ended` lists went unpopulated on all eleven sessions across 230 revisions, and the prose standing in for them misattributed two revisions in this session's own record |

A contribution to a bundle this session does not own is recorded here and does
not change ownership. **The three `0039` rows were written while that bundle was
owned by `session-management-re-evaluation-20260906-110105`**; it has since passed
through this session and, at Revision 261, to
`entity-model-and-vocabulary-20260909-053548`. The rows are left as written —
they record what was true when they were made, and a contribution is dated to the
ownership it was made under.

**`0043` F10 was contributed after this session declared `handoff`**, which is
stated rather than hidden: a session that has handed off takes no new *work*, and
`live_sessions()` excludes it from allocation, but nothing stops it recording a
fact it found while closing — and this one was found in its own `ended` block,
by the owner opening the file. `0043` is owned by
`session-management-re-evaluation-20260906-110105`, which stands `handoff` with
no successor, and is **deliberately open** so that a session records there rather
than opening a near-duplicate beside it.
