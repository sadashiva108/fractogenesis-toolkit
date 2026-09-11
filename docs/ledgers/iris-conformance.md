# IRIS conformance

**What this is.** Every audit of the `iris/` documents against the tree they
describe. Each entry is a dated measurement against a named commit.

**Why it exists.** `iris/` is the manual and it is full of measured figures —
counts of bundles, members, edges, sessions and tests, and censuses of which
values are in use. **A measured figure in a document is a copy**, and
`docs/legend.md` permits a copy only where it is generated or where a check fails
when it drifts. **None of these is generated and nothing checks any of them.**
`verify-doc-paths.sh` resolves the paths and no instrument reads the numbers.

**Never a verdict, always a value.** A verdict cannot be compared against a later
run.

**Who runs it.** Any session, in its own copy, before building anything on what
the manual says.

---

## 2026-09-10 — commit `d127b0e`, Revision 299

**Method.** Figures re-derived from every `metadata.json` under `docs/` by direct
count; the suite by running it; paths by resolving each backticked repository path
cited anywhere in `iris/` and, where it did not resolve, searching the tree for a
file of that name. **Measured in a Linux VM under Bash 5.1.16, not the macOS Bash
3.2 target.**

**And measured in a copy of the owner's checkout, which is not a clone.**
`drift-and-the-write-boundary-20260909-053548` measured the difference on
`verify-doc-paths.sh`: **`MISSING` reads 10 in the checkout and 20 in a clone of
the same commit**, the gap being untracked files under `.internal/restore/` that
a clone does not carry. That is `0038` F12, `framing` and decided by nobody.
**Every figure in this ledger is derived from tracked records and is unaffected**
— `metadata.json` files, members, decisions, edges, sessions and the suite are all
tracked — **but the path resolution is not**, because a cited path may resolve to
an untracked file. Re-run in a clone before quoting the path rows forward. **The
same caveat applies to `docs/ledgers/instrument-firing.md`**, whose doc-paths
figures were taken the same way and say so nowhere.

### The figures

| Figure | The manual says | Measured | Documents carrying it |
|---|---:|---:|---:|
| findings bundles | 54 | **54** | 2 |
| members | 191 | **211** | 3, seven mentions |
| decisions | 143 / **134** | **155** | 2, and they disagreed |
| edges | 59 | **70** | 2, three mentions |
| sessions | 11 | **12** | 3, five mentions |
| `metadata.json` files | 65 | **66** | 2, five mentions |
| tests in the suite | 67 | **69** | 1 |

**One of seven still holds.** And `schema.md` said 143 decisions where
`verifications.md` said 134, in documents written days apart against the same
tree — **a disagreement no reader could have adjudicated at the time**, which is
worse than either being stale.

**One document says how to read it.** `verifications.md`: *"Re-run the commands;
do not quote these figures forward."* `prism.md` and `lumen.md` carry the same
191 with no such line.

### The edge census

`vocabulary.md` §8's **In the tree** column, against every `metadata.json`:

| Kind | Claimed | Actual |
|---|---:|---:|
| `blocks` | 5 | **7** |
| `constrains` | 3 | **4** |
| `evidences` | 0 | **1** |
| `relates-to` | 16 | **23** |
| the other eight | — | agree |

**The `evidences` row is load-bearing.** §13 closes on *"the machinery is present
and unexercised"*, §8 says *"both are at zero today, so nothing in the tree has
yet been tested this way"*, and `README.md` §9 repeats it as the honest summary of
the system. **`0039/F28 evidences 0047/F1` exists.** A trial has been recorded,
and the only thing that would have shown it is a hand-typed column.

### The paths

**96 distinct repository paths are cited across `iris/`.** All but four resolve,
and of those four two are declared:

| Path | State |
|---|---|
| `.iris/config.json` | **declared absent** by `directory-reference.md` §5 — the described layout, honestly marked |
| `record/REVISIONS.md` | **declared absent** by the same table |
| `lib/plan_findings_work.py` | **wrong.** `vocabulary.md` line 11, in the sentence that makes the code the tiebreak. There is no `lib/` |
| `manifest.md` | **wrong.** `vocabulary.md` §6, the `Produces` column for session state `active`. The file is `findings-manifest.md` and `docs/legend.md` says so |

**Neither wrong path is caught by `verify-doc-paths.sh`**: neither is rooted at a
`REPO_DIRS` component, and the bare-filename fallback resolves
`plan_findings_work.py` elsewhere in the tree. **They are wrong in a way that
reads as right to the checker.**

### What is specified and has never run

| Mechanism | Specified in | Instances |
|---|---|---:|
| the reopen lifecycle — nine reasons, an exit table, a required SHA | §9a, `docs/legend.md`, three `iris/` documents | **0 members, 0 blocks** |
| `reopened.md`, *"GENERATED … do not hand-write it"* | §9a, `lifecycles.md`, `schema.md`, `coverage-procedure.md` | **0 files, and no generator exists** |
| `charter` and `remedy` genera | `shapes.md`, `vocabulary.md` | **0 bundles** — `README.md` §9 says so |
| `contradicts` edges | `vocabulary.md` §8 | **0** |

**`README.md` §9 names the actionable half and the edges as present-and-unexercised
and does not name the reopen lifecycle**, which is the larger of the three and the
only one presented throughout as working procedure.

### What held

**Recorded because a ledger that lists only failures is not measuring.** The
bundle count, 54. Eight of twelve edge rows. Ninety-two of ninety-six paths.
`lumen.md`'s claim that `severity` is a key on no member — asserted three times,
measured absent from all **211**, so it survived the tree growing by twenty. And
`directory-reference.md` §5, which states its own described-versus-actual gap in a
table and is the model for how the rest of these figures should read.

### What this ledger does not answer

**Whether any `iris/` document is wrong about a rule**, as opposed to a number or
a path. That is a reading, and this is a measurement.

**Whether the figures should be generated rather than written.** Every one is
derivable by one query. Nothing here proposes the generator; `0057` F1 records the
condition and `0050` F8 is the standing warning about building an instrument
nobody runs.

---

## 2026-09-11 — commit `fc2836b`, Revision 309

**Why there is a second entry before the first one was ever committed.** The entry
above was composed at Revision 299 and sat unlanded for nine revisions, cited by
two documents as though it existed. **A ledger whose subject is that measured
figures go stale, held back until its own figures went stale**, is the finding it
records happening to it. It is landed as measured on 2026-09-10 and corrected
here rather than rewritten, because an entry is a dated measurement and editing
one destroys the only thing it is for.

### The entry above explains the tree gap wrongly, and the mechanism matters

**The figures were right; the cause was not.** It says the checkout-versus-clone
gap is *"untracked files under `.internal/restore/` that a clone does not carry"*.
Measured at this commit: **`.internal/restore/` holds no files at all. It is an
empty directory.**

| | |
|---|---|
| `git status --untracked-files=all` | reports **nothing** — git does not represent empty directories |
| `git check-ignore -v` | **not ignored**; there is no rule to remove |
| `git ls-files` under it | **0** |
| entries inside it | **1** — itself |

**This is not a file somebody forgot to commit.** No `git add` can put it in the
repository, so the checkout and every clone disagree permanently, and the
disagreement is invisible to every git command in both directions. That is a
sharper statement of `0038` F12 than *untracked files*, and it is why the same
sentence has been written three times — Revision 301, the entry above, and
`IRIS-COORDINATION.md` §5 — each time as though a commit would settle it.

### `0038` F12, measured at this commit

Both trees carry identical tracked content: `git archive HEAD` extracted beside
the checkout differs only by `.DS_Store`, `.idea/`, and the empty directory.

| `verify-doc-paths.sh` | checkout | clone | gap |
|---|---:|---:|---:|
| `--all` MISSING | **8** | **21** | **13** |
| `--all` WARN | 301 | 301 | 0 |
| **default set — what a session actually runs** | **0** | **0** | **0** |

**All thirteen are one path in two spellings** — `.internal/restore` and
`.internal/restore/` — cited across six documents. Nothing else differs.

**Writing this entry made the number worse, and that is not a reason to word around
it.** A clone of `fc2836b` reads MISSING **21**; a clone carrying this revision
reads **24**. The three are this entry and the `IRIS-COORDINATION.md` correction
naming the path they are about. **The metric penalises documenting the defect** —
`0050` F10's shape one layer out, where clearing a `MISSING` required creating a
permanent `ORPHANED`. The alternative was to name the path without backticks so
the checker would not see it, which is gaming a count rather than reporting one.
In the owner's checkout all three resolve and the figure does not move.

**So F12 is true and has never cost a session anything.** Every check a session is
told to run reads 0/0 in both trees. The divergence exists only under `--all`,
which no runbook, dispatcher or prompt invokes. **That is the finding's real
shape: a correct measurement of a mode nobody uses**, and it belongs beside
`0050` F8 rather than beside a defect anybody is being harmed by today.

**And it is already decided.** `0012` D2, accepted at **Revision 193** — *"the
empty directory is removed locally, and that is not a repository change"* — was
never carried out. Two and a half months and one hundred and fifteen revisions
later the directory is still there. **The remedy for F12 is not new work; it is a
decision nobody closed**, and `0012` F1 also carries D1, which already ruled that
the sentences citing the path should be rewritten rather than the directory
created.

`0038` is `drift-and-the-write-boundary-20260909-053548`'s bundle. **This is a
measurement contributed to it, not a decision taken in it.**

### The figures, re-measured

`iris/` is now **fourteen documents**, not thirteen; `status.md` arrived at
Revision 301.

| Figure | The manual said, at R299 | Measured R299 | **Measured now** |
|---|---:|---:|---:|
| findings bundles | 54 | 54 | **56** |
| members | 191 | 211 | **224** |
| decisions | 143 / 134 | 155 | **165** |
| edges | 59 | 70 | **77** |
| sessions | 11 | 12 | **12** |
| `metadata.json` files | 65 | 66 | **68** |
| tests in the suite | 67 | 69 | **74** |

**The one figure that held at Revision 299 no longer holds.** The bundle count was
54 and correct; it is 56 and the manual still says 54. **Seven of seven have now
moved**, which is `0057` F1 stated as a measurement rather than as a claim.

### What changed the arithmetic: three sections are now generated, and nothing runs the generator

**Revision 301 built `measure-iris-status.py`** and put `iris/status.md`'s three
measured sections between `<!-- MEASURED:… -->` markers, precisely so no number in
them would be hand-carried. **It worked. It was then never run again.**

Run at this commit against the committed tree, it rewrote **3 of 3 blocks**:

| | committed | regenerated |
|---|---:|---:|
| dossiers | 55 | **56** |
| members | 217 | **224** |
| edges | 73 | **77** |
| `APPLY-MANIFEST.md` | 1.21 MB, 18,126 lines, 471 entries | **1.25 MB, 18,140 lines, 478 entries** |

Two roots also moved and the `relates-to` / `carried` rows swapped order.

**Nothing in the tree executes it.** It is named in `iris/status.md`'s prose, in
one findings document and in the manifest — and in no dispatcher, no `bin/`
entrypoint, no `verify.sh` group and no prompt. **It is correct, it fires, and it
is reached by nothing**, which is `0050` F8 exactly, third instance, and the first
one where the unrun instrument is a *generator* — so its silence does not leave a
question unanswered, it leaves a wrong answer published. It is idempotent: a
second run changes nothing further.

**The generated blocks are regenerated in this revision.** That repairs the
figures and does not repair the cause.

**Every figure in this entry is measured at `fc2836b`, before this revision's own
writing.** `status.md` as landed reads **57 dossiers, 229 members, 79 edges**,
because this revision adds `0057` and its two edges. **The entry is one revision
behind the tree the moment it is committed, and saying so is the only honest
option available** — a measurement names a commit, and the commit it names can
never be the one that carries it. That is not a defect in the method; it is why
the ledger's opening sentence says *never a verdict, always a value*, and why the
three generated blocks exist. Re-run before quoting anything here forward.

### The audit's own claims, re-verified

| Claim | State now |
|---|---|
| `evidences` stands at 1, not 0 — the row §13 and `README.md` §9 rest on | **holds.** Still exactly 1 |
| `contradicts`, `duplicates`, `generalises`, `serves` at zero | **holds.** All four still 0 |
| `charter` and `remedy` genera unused | **holds** — but `commission` is no longer 0; there is 1, so the *four genera are unused* form of the claim is now wrong |
| the reopen lifecycle has never run | **holds.** 0 members carry `reopened`; 0 `reopened.md` files; no generator exists |
| `severity` is a key on no member | **holds**, now across all **224** rather than 211 |
| `lib/plan_findings_work.py` does not exist and is cited in the tiebreak sentence | **holds** — `vocabulary.md:11`, and **`verify-doc-paths.sh` still does not report it at all** |
| `manifest.md` does not exist and is cited in `vocabulary.md` §6 | **holds at line 186, but the audit's account of it does not** |

**The correction is to the audit, not to the tree.** It says *"neither wrong path
is caught by `verify-doc-paths.sh`"*. Run over the fourteen `iris/` documents,
`manifest.md` **is** caught — `WARN  manifest.md (no file by this name anywhere in
the repo)`. `lib/plan_findings_work.py` is not caught, and that is the sharper
half: **one is surfaced and ignored, the other is invisible.** Lumping them made
the weaker case.

**Paths over the manual, in the instrument's own units**: OK 172, WARN 6, DECAYED
1, **MISSING 0**, ANCHOR BROKEN 0. The six warnings are three bare filenames —
`reopened.md`, `extract-metadata.py`, `manifest.md` — two of which are findings in
their own right.

### What this entry does not answer

**Whether the figures in the manual should be generated.** Three of them now are,
and this entry is what a generator nobody runs looks like from outside. The other
four documents carrying figures have no markers and no generator, and `0057` F1
records the condition rather than proposing the fix.

**Whether `0038` F12 should be repaired.** It is `0012` D2's to close and
`drift-and-the-write-boundary-20260909-053548`'s to judge. The measurement is
here; the act is not.
