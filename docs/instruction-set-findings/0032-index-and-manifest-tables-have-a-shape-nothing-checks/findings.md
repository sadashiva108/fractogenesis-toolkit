# The index and manifest tables have a shape nothing checks

**Recorded:** 2026-09-03, session `session_01PcgHu9kz9Hm5RatLQuFR8H`, from
breaking two of them and not noticing.
**Relates to:** `0031` — the same section, §4c, from the other side: `0031` is a
rule that is missing, this is a rule that exists and is unenforced.
**Contributed to:** finding 4 was added 2026-09-04 by
`restore-apps-outstanding-20260903-000000` while this bundle is `unresolved`,
which `docs/legend.md` opens to any session. The bundle is unchanged otherwise
and `pre-image-capture-conformance-20260903-194532` still owns it.
**Severity:** low per instance, and it defeats the check a session actually runs.
Every validator in the repository passed on both broken rows.
**Scope:** instruction set. §§4c–4d define these tables; nothing validates them.
Whether the *fix* belongs here is finding 3.

## Findings

| # | Finding | Status |
|---:|---|---|
| 1 | The indexes and manifests have a required column shape that no check enforces | `unresolved` |
| 2 | `verify-doc-paths.sh` gives false assurance on a malformed row, because links are not shape | `unresolved` |
| 3 | The fix is a lint, so this bundle may be in the wrong tree | `unresolved` |
| 4 | A patch containing a deletion under-applies silently, and every check passes | `unresolved` |

---

### 1 — a required shape, unenforced

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

### 2 — the check that runs gives the wrong assurance

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

### 4 — a patch containing a deletion under-applies silently, and every check passes

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
times — which is the same currency findings 1 and 2 were paid in and the reason
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
agrees with the index row.** It is the same kind of check finding 1 asks for,
against the same kind of rule, and it would be in the same script.

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

### 3 — this may be in the wrong tree

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
and because if the answer is *cross-cutting*, `0027` finding 1's question
(*where is a rule allowed to live*) reaches this bundle too.
