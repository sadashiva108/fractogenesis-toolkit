# The index and manifest tables have a shape nothing checks

**Recorded:** 2026-09-03, from breaking two of them and not noticing.  
**Session:** `session_01PcgHu9kz9Hm5RatLQuFR8H`  
**Severity:** low per instance, and it defeats the check a session actually runs. Every validator in the repository passed on both broken rows.  
**Scope:** instruction set. §§4c–4d define these tables; nothing validates them. Whether the *fix* belongs here is finding F3.  
**Relates to:** [`0032`](../../instruction-set-findings/0032-index-and-manifest-tables-have-a-shape-nothing-checks/) — **supersedes it.** The original is retained at `docs/instruction-set-findings/0032-index-and-manifest-tables-have-a-shape-nothing-checks/`, still listed by the session that held it, its reading unchanged and its files brought onto the schema in Revision 203. Authority for this reading lives here.  
**Relates to:** `0031` — the same section, §4c, from the other side: `0031` is a rule that is missing, this is a rule that exists and is unenforced.

**Contributed to:** finding F4 was added 2026-09-04 by
`restore-apps-outstanding-20260903-000000` while this bundle is `unresolved`,
which `docs/legend.md` opens to any session. The bundle is unchanged otherwise
and `pre-image-capture-conformance-20260903-194532` still owns it.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | The indexes and manifests have a required column shape that no check enforces | `framing` |
| F2 | `verify-doc-paths.sh` gives false assurance on a malformed row, because links are not shape | `framing` |
| F3 | The fix is a lint, so this bundle may be in the wrong tree | `framing` |
| F4 | A patch containing a deletion under-applies silently, and every check passes | `framing` |
| F5 | Nothing compares a resolution's claim against the tree | `framing` |

---

### F1 — a required shape, unenforced

`.github/copilot-instructions.md` §4c and §4d, and the indexes themselves, fix
the columns of five kinds of table: the three findings indexes, the sessions
index, and every session's `findings-manifest.md`. A row with the wrong number of
cells renders as a shifted or truncated row and reads as data.

Two were produced in one sitting, by one session, in one revision:

| Row | File | Cells | Wanted |
|---|---|---:|---:|
| `0009` | `docs/cross-cutting-findings/INDEX.md` | 8 | 7 |
| `0013` | `docs/runbook-findings/INDEX.md` | 9 | 8 |

Both from the same cause: an edit that stripped a trailing `| — |` from the Notes
cell and appended a replacement, leaving `||` where the Session cell ended. Both
were found only because the owner asked for an unrelated change to the `0009`
row, which required reading it column by column. Nothing else would have surfaced
them.

The near miss belongs with them. Earlier in the same session the `phase-11b` row
in `docs/sessions/INDEX.md` was reported to the owner as malformed and was not —
that table had gained a `Bundles` column, and the row was correct. A pipe count
without the header is not a check, and a session doing it by eye will produce both
error directions.

#### Two more shapes the check does not reach, recorded 2026-09-06

**The `Bundle:` field is wrong in all ten `decisions.md` and `resolutions.md` in
this tree.** Every one carries the number of the bundle it was cloned from rather
than the one it sits in: `0037`'s says `0027`, `0038`'s says `0028`, `0039`'s
says `0029`, `0040`'s and `0041`'s carry the full `0031-` and `0032-` directory
names, and `0036`'s says `0026-`. `bin/verify-findings-headers.sh` makes 902
assertions about these files. It checks that `Bundle:` is **present**; it never
checks its **value**. That is this finding exactly — a required shape, stated in
section 11, with no check behind it — and the value is derivable from the
directory the file is in, so the check is a comparison rather than a judgement.

**A tag may say `resolved` over finding rows that never moved.** Revision 197
found four such bundles — `0030`, `0031`, `0032`, `0035` — and two other sessions
independently reached the same conclusion about the fix: a **third invariant** in
`bin/verify-findings-structure.sh`, which today compares the tag against the
index row and never opens `findings.md`. It has one dependency worth naming,
raised by `run-index-design-20260901-000000`: a bundle with no per-finding table
is legal when it holds one finding, and that fact is owned by
`verify-findings-counts.sh`. Crossing that boundary is what D1 declined to do,
so the two scripts have to agree about it before either can carry the rule.

Neither of these was caught by anything. Both were found by a person reading a
column.

### F2 — the check that runs gives the wrong assurance

`./bin/verify-doc-paths.sh --all` reported **0 MISSING / 0 ANCHOR BROKEN** on both
malformed rows, correctly: every link in them resolved. Link resolution and table
shape are different properties, and the one that is checked is not the one that
broke.

This is the shape of `0026`'s argument from a different angle. There, a baseline
that moves for reasons unrelated to the change makes *"I did not cause it"*
indistinguishable from *"I did not look"*. Here, a validator that passes on a
defect it does not examine makes *"the lints are clean"* indistinguishable from
*"the lints do not cover this"*. A session that quotes a clean run as evidence the
indexes are well-formed is quoting the wrong file.

A shape check is cheap and total: read the header row, count `|` in every data
row, report the ones that disagree. It is the check that was run by hand to find
these two, and it takes about fifteen lines of Bash 3.2.

### F4 — a patch containing a deletion under-applies silently, and every check passes

**Contributed 2026-09-04** by `restore-apps-outstanding-20260903-000000`, from
the fourth instance. The first three were this bundle's own session's.

`git apply` cannot unlink a file in the connected folder — the mount refuses it —
so on a patch that deletes something, **git downgrades the failure to a warning,
applies everything else, and exits 0.** Creating works; deleting does not. The
new file lands, the old one survives, and the command reports success.

Stated that way the defect is a mount permission interacting with git's error
handling, not something about renames. It predicts the general case: **any patch
containing a deletion under-applies.** A `STATUS-` tag rename is simply the
common one, because every status transition is a delete plus a create.

#### Four instances, and it recurred after it was known

| Revision | Bundle | Left behind |
|---|---|---|
| 183 | `0009` | `STATUS-unresolved` beside `STATUS-superseded` |
| 183 | `0013` | `STATUS-unresolved` beside `STATUS-in-progress` |
| 187 | `0013` | `STATUS-unresolved`, again |
| 188 | `0029` | `STATUS-unresolved` beside `STATUS-in-progress` |

**None of the four reached the history.** Checked with `git ls-tree -r` across
every commit of 2026-09-03 and 04: no commit contains two tags for one bundle. So
the cost to date has been paid entirely in attention — a person noticing, four
times — which is the same currency findings F1 and F2 were paid in and the reason
this belongs with them rather than in a bundle of its own.

That it recurred at Revision 187, after 183 had already been seen and cleared, is
the argument. A habit did not survive four days.

#### Why no check caught it

All four validators passed with two tags present, each correctly:

- `verify-doc-paths.sh` — both tags exist, so every path resolves. Finding 2's
  argument exactly: existence and correctness are different properties.
- `verify-findings-counts.sh` — reads finding tables, never opens a bundle
  directory.
- the other two — scripts and runbook structure; not their subject.

And §4c states the rule the whole time: *"a bundle whose tag disagrees with its
INDEX.md row is a bug in whoever moved it last."* Stated, and unenforced. The
check is one line of shape: **exactly one `STATUS-*` per bundle directory, and it
agrees with the index row.** It is the same kind of check finding F1 asks for,
against the same kind of rule, and it would be in the same script.

#### The refusal is not specific to deletion

**Recorded 2026-09-06** by `session-management-re-evaluation-20260906-110105`,
from three applies in Revisions 206 and 207. **None of them deleted or renamed
anything.** Every one reported `unable to unlink ... Operation not permitted` —
on `APPLY-MANIFEST.md`, on `docs/sessions/INDEX.md`, on the session bundle's
`prompt.md` — every one exited 0, and every one landed correctly, verified by
`cmp` on each touched path against the composing copy.

`git apply` modifies a file by writing a replacement and unlinking the original,
so **the mount's refusal fires on plain modification too.** The difference is
recovery, not exposure: on a modification git has a fallback and the content
lands; on a deletion there is nothing to fall back to, so the file survives.

**What this changes is the detection rule.** This finding is right that the
failure is downgraded to a warning — and a reader takes from that *watch for the
warning*. That does not work: the warning appears on patches that applied
perfectly, three times in one afternoon, and `git status` in the checkout emits
it for `.git/index.lock` with no patch involved at all. The warning cannot
separate a dropped deletion from a clean apply. Neither can the exit code, and
neither can a checksum of the files the patch names. **Only comparing the two
trees can** — `diff -r` of the copy against the checkout, or `cmp` per touched
path.

What this finding has exactly right and should keep: creating works and deleting
does not; this is a mount permission meeting git's error handling rather than
anything about renames; and a `STATUS-` tag rename is the common instance rather
than the mechanism.

**Not tested here.** This session did not deliberately apply a deletion-bearing
patch to confirm the drop — the four instances above are the evidence for that
half, and these three are the evidence for the modification half. Whether
`git apply --3way` or `patch(1)` behave differently is untested.

**And the remedy is still missing from the record.** Request delete permission
for the connected folder *before* applying a patch that deletes or renames, and
again after any bridge reconnect, because the grant does not survive one — which
the operational note below already records while assuming the reader knew to ask.
Nothing in either instruction set, `docs/legend.md`, or the conformant prompt
said to ask. It went into the conformant prompt on 2026-09-06 and is owed to
`.github/session-management-instructions.md` section 6.

#### The apply step has the same blind spot

The second half is not about tags at all. **`git apply` exiting 0 means a session
cannot report "the patch applied cleanly" from the exit status**, which is what
`0028`'s composition rule instructs it to do. Revision 182 wrote *"run `git apply
--check` before applying and say so"* into §3, and `--check` passes on exactly the
patch that will under-apply, because it validates the diff against the tree
rather than the filesystem's permissions.

The verification that was run afterwards had the blind spot too: the applied
files were compared to the composed files by checksum, all five matched, and the
deletion was not among them — **a checksum comparison only sees files the patch
names as content.** A verification that catches this compares the two trees, not
the two file lists.

#### One operational note, from the other session

The delete permission granted for a connected folder **does not survive a bridge
reconnect.** It was granted, the desktop link dropped and returned, and the next
`rm` failed with `Operation not permitted` mid-apply. Any procedure written
against "deletion is enabled for the rest of the session" is written against
something that can lapse without notice.

---

### F5 — nothing compares a resolution's claim against the tree

**Recorded 2026-09-06** by `session-management-re-evaluation-20260906-110105`,
from verifying all 25 resolution claims in this tree against the repository.

`resolutions.md` is the one document in the bundle shape that makes a **factual
claim about the tree**: *this was done, here, in this revision*. It is the only
one with an external referent, and it is the only one nothing checks.
`verify-findings-headers.sh` confirms that every `F<n>` and `D<n>` a resolution
cites exists on the other side — a claim about the bundle's internal
consistency. Whether the thing a resolution says was done was done is not
examined by any of the six checkers.

Twenty-two of the twenty-five hold. **Three do not, and they fail in three
different ways**, which is the argument that this is a class rather than three
mistakes:

| | Claim | What is actually true |
|---|---|---|
| `0037` F5 | the migrated-bundle carve-out landed in §4c | it landed, and commit `1c48deb` dropped it |
| `0037` F2 | required reading scoped to prompts that can still start a session | the scoping landed; the rule it scoped was then deleted |
| `0041` F3 | *"stays in `docs/session-management-findings/`"* | the supersession moved it cross-tree |

None is a false statement at the time it was written. Each became false
afterwards, silently, and **a bundle carrying `resolved` is exactly the object
nobody re-reads.**

This is finding 2 one level up. There, a validator passed on a property it does
not examine. Here, `resolved` asserts a property nothing examines at all — and
`resolved` is frozen, so the assertion hardens.

**What a check could reach, and what it cannot.** *Revision* and *Commit* are
mechanical: a revision must exist in `APPLY-MANIFEST.md`, a commit must resolve
in the log. *What was done* is prose and no checker will judge it. The honest
middle is to require that a resolution name a **verifiable referent** — a file
and a construct in it, so that `grep` can answer — rather than a section number
in a file that may be renamed out from under it. All three failures above cite
`§4c`, a section that no longer exists.

### F3 — this may be in the wrong tree

Recorded rather than resolved, because the two tests disagree.

`docs/INDEX.md` describes `instruction-set-findings/` as findings about *the rules
a session works under*. The table shapes are such a rule, defined in §§4c–4d, and
`docs/architecture/findings-and-sessions.md` §11.1 already argues that the
structure's invariants are *"currently discipline"* and that write-time
enforcement is the highest-value addition available — which is where this belongs
by subject.

But §4c's own classification test is **where the fix lands**, and the fix is a
lint: a new `bin/verify-index-tables.sh`, or a section added to
`verify-doc-paths.sh`. That is shared machinery, which is
`docs/cross-cutting-findings/`.

The owner routed it here. It is noted because the routing is genuinely arguable
and a later reader should see that it was a choice rather than an oversight —
and because if the answer is *cross-cutting*, `0027` finding F1's question
(*where is a rule allowed to live*) reaches this bundle too.

<!-- historical: bin/verify-findings-headers.sh -->
<!-- historical: bin/verify-findings-structure.sh -->
<!-- proposed: bin/verify-index-tables.sh -->
