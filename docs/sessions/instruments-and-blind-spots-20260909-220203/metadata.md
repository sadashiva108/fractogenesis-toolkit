# instruments-and-blind-spots-20260909-220203 — metadata

## Owners

| From | Until | Assistant | Session id | Model | Environment |
|---|---|---|---|---|---|
| 2026-09-10 | — | Claude | `session_01Fo6sBeux1JTyDzgKhCx2KU` | `claude-opus-5` | Linux VM on the owner's machine, Bash 5.1.16, GNU awk 5.1.0, aarch64 — **not the macOS Bash 3.2 target** |

**Filled on this session's first write, at Revision 288**, which is what
`docs/rules/README.md` section 5 step 3 says the empty row was waiting for. The
row it replaced read `—` in every column and said so on purpose: the bundle was
created ahead of the session at Revision 286 by
`entity-model-and-vocabulary-20260909-053548`, and only the session knows its own
identifier, model and environment.

**The Model column names what this session was configured for, not what served
it.** The two can differ and the record cannot tell them apart from inside, so
the column is the configuration and this sentence is the caveat.

**The environment is two machines and the record has to say which.** The
assistant runs in a cloud container; the repository is reached through a desktop
bridge to the owner's Mac, where a local Linux VM holds the scratch copy and runs
every command. **So every number this session quotes was measured in that VM under
Bash 5.1.16 and GNU coreutils** — where `mapfile`, `declare -A`, `sed -i` and
GNU-only flags all work silently. `verify-script-portability.sh` is what stands in
for the target platform, and it is a reading of the source rather than a run:
**CLEAN 91, WARN 0, FAIL 0**, which says the new code needs nothing newer than
Bash 3.2 and does not say it was executed there.

## Environment

Recorded in the Owners row above at Revision 288. The session **names it
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
| Scratch copy | `/sessions/rcw-01fo6sbeux1jtydzgkhcx2ku/scratch/work`, inside the Linux VM on the owner's machine. **This path does not exist on the Mac and dies with the session** — the patch in the directory above is the surviving artifact |
| Commit created against | `777f468` — Revision 287 |
| `APPLY-MANIFEST.md` at creation | Revision 286 |

## Assignment

**Both bundles were assigned, not transferred.** They stood `unclaimed` from
**Revision 264**, when `assurance-coverage-20260908-204724` closed and released
seven, until **Revision 286**.

**Three numbers in this section were wrong when the session opened it**, and are
corrected here rather than left: the sentence above read *from Revision 286 …
until Revision 286*, and the table below carried **279** in a column headed
Revision. `APPLY-MANIFEST.md` Revision 286 has it right — *both `unclaimed` since
Revision 264* — so the entry and the record it describes disagreed from the moment
both were written. **This is `0052` F1's shape inside the document that seeds a
session**: not a resolution reverted, but a fact recorded twice and only one copy
maintained.

| Bundle | Direction | From | Date | Revision |
|---|---|---|---|---:|
| [`0041`](../../session-management-findings/0041-index-and-manifest-tables-have-a-shape-nothing-checks/) | assigned | `unclaimed` since Revision 264 | 2026-09-09 | 286 |
| [`0050`](../../session-management-findings/0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record/) | assigned | `unclaimed` since Revision 264 | 2026-09-09 | 286 |

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

**One relay received, 2026-09-10**, from `entity-model-and-vocabulary-20260909-053548`
by way of the owner: a reading this session had taken — that Revision 285's work
was lost — is **overtaken**, the seed and both assignments having landed as
Revision 286 inside commit `777f468`. The second half of that reading stands and
was strengthened by the relay, and is recorded as `0050` F7. **A relay is not a
contribution to a bundle and is recorded here because it changed this session's
own reading**, which the Contributions table has no row shape for.
