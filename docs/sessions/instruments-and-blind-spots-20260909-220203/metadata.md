# instruments-and-blind-spots-20260909-220203 — metadata

## Owners

| From | Until | Assistant | Session id | Model | Environment |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

**Empty on purpose.** This bundle was created ahead of its session at Revision 286
by `entity-model-and-vocabulary-20260909-053548`, and **only the session itself
knows its identifier, the model it was configured for and the environment it
actually ran in.** Writing a value here would be inventing one. A placeholder
belongs in a template and never in a record. **The session fills this row on its
first write** — `docs/rules/README.md` section 5, step 3.

## Environment

Not yet known. The session records it here on its first write, and **names it
whenever it quotes a check** — a result from a Linux VM is not a result from the
target Mac, and the Bash 3.2 debt is extended by every check that does not say so.
`docs/ledgers/target-platform-verification.md` remains the only run that was.

**One constraint that is this session's subject and also a hazard to it.** Git
takes a lock to read, and a connected folder refuses `unlink`, so `git status` or
`git log` run in the owner's checkout can leave a `.git/index.lock` behind that
blocks the owner's next commit. `bin/verify-doc-paths.sh` shells out to git.
**In the checkout: `ls` and `cat`, or copy it and run git in the copy.** Two
sessions have hit this; one of them wrote the rule and then broke it.

## Resources

| Resource | Value |
|---|---|
| Repository checkout | `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit` |
| Artifact volume | the mounted `reimage-…` run directory. **Read-only unless the owner grants a write per run** |
| Patch directory | `/Users/dkittrell/reimage-workspace/patches` |
| Scratch copy | filled by the session |
| Commit created against | filled by the session |
| `APPLY-MANIFEST.md` at creation | Revision 286 |

## Assignment

**Both bundles were assigned, not transferred.** They stood `unclaimed` from
Revision 286, when `assurance-coverage-20260908-204724` closed and released seven,
until Revision 286.

| Bundle | Direction | From | Date | Revision |
|---|---|---|---|---:|
| [`0041`](../../session-management-findings/0041-index-and-manifest-tables-have-a-shape-nothing-checks/) | assigned | `unclaimed` since Revision 286 | 2026-09-09 | 279 |
| [`0050`](../../session-management-findings/0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record/) | assigned | `unclaimed` since Revision 286 | 2026-09-09 | 279 |

**Assignment is adding the row to `findings-manifest.md`** — nothing else sets
ownership, and removing the row is the release. The `ownership` field on each
bundle moves from `unclaimed` to null in the same revision, and `stamp` derives
the standing from what is left.

**Neither arrives `assigned`.** That standing means *owned, and nobody has written
to a member yet*, which requires `progress: untouched`. Both have been worked —
`0041` carries six accepted decisions and `0050` two — so both derive `analyzing`
the moment ownership clears. **There is no standing for *worked, reassigned, and
not yet read by its new owner***; `transferred` covers that case only when a
bundle moves between two named sessions. Recorded because a reader will look for
one.

## Contributions

None yet. A contribution to a bundle this session does not own is recorded here
and does not change ownership.
