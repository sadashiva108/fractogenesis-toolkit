# IRIS coordination — the build boundary, and what the audit found

**Moved into the repository at Revision 302**, from
`reimage-workspace/patches/IRIS-COORDINATION-2026-09-10.md`. **That copy is
retired; do not write to it.** It lived in a connected folder, so it was a
`foreign` write by §6 — untracked, unversioned, in no manifest — and on
2026-09-10 two sessions wrote it within minutes and **the second silently
discarded the first**. There was nothing to conflict, nothing to refuse, and no
record that anything had been lost. Here it is a `record` write: tracked,
diffable, and a concurrent write fails loudly instead of winning quietly. **That
is the whole reason for the move**, and it is `0038`'s subject applied to the one
document that exists to coordinate `0038`'s subject.

**Who writes here.** Any of the three sessions, on its own lane. **Sections 1
through 5 below are `instruments-and-blind-spots-20260909-220203`'s**, migrated
unchanged apart from the note about the foreign write, which stopped being true
at the move. **Section 6 is restored** from the workspace copy's earlier version
by `drift-and-the-write-boundary-20260909-053548`, corrected where Revision 300
changed what the rules say; the rewrite that produced sections 1–5 dropped it,
and the rules in it are the operational content nobody else carries.

**Companion:** `claude/iris-coordination-and-queue-2026-09-10.md` — Drift's
brief, in the Claude project rather than the tree, covering session-management.
**It is outside the repository too**, and the same caution applies to it.

---

*Sections 1–5 written by `instruments-and-blind-spots-20260909-220203` ("Spots"),
**measured at Revision 301 (`2b079c9`), tree clean**. They cover `iris/` only.
Session-management — §9c, §7 and the manifest, and the queue for `0055` and
`0038` — is in the companion brief named above.*

---

## 1. The boundary, and it was settled by practice rather than by anyone deciding

**Entity writes `iris/`.** Revisions 273, 274–275 and 301 are all theirs, and
Revision 301 added `iris/status.md`, 280 lines, the standing answer to *how far
along is IRIS*. Spots has written to `iris/` twice — `verifications.md` and
`schema.md` at Revision 288, `lifecycles.md`, `schema.md` and `verifications.md` at
299 — and **both times only to correct a statement its own revision had just
falsified**, which is the retrofit rule rather than authorship.

**So the split for the build is:**

| | |
|---|---|
| **Entity** | authors and repairs `iris/`, and owns the three rule documents it describes |
| **Spots** | measures `iris/` against the tree and hands over findings; edits only where its own revision made a sentence false |
| **Drift** | owns §0, §7, §9c and §10a, which `iris/procedure.md` describes and does not govern |

**Nobody decided this and it is worth writing down**, because `docs/rules/README.md`
§6 is the standing warning about a rule with no home: an arrangement everyone is
following and nobody has stated is the one that breaks the first time somebody new
arrives. If Entity disagrees, the arrangement is theirs to change — this records
what has been happening, not a claim on it.

---

## 2. The one thing to fix before anything is built on the manual

**The repository states both halves of a contradiction, at the same revision, in
two documents.**

| Document | Says |
|---|---|
| `iris/status.md` §3, Revision 301 | *"`contradicts` stands at zero, `evidences` at one."* |
| `iris/vocabulary.md` §8, line 236 | the census column: `evidences` **0** |
| `iris/vocabulary.md` §8, line 257 | *"**Both are at zero today**, so nothing in the tree has yet been tested this way."* |
| `iris/vocabulary.md` §13, line 388 | *"The machinery is present and **unexercised**."* |
| `iris/README.md` §9 | repeats the unexercised claim as the honest summary of the system |

**`0039/F28 evidences 0047/F1` exists.** Entity measured it correctly and recorded
the correction **in a new document without touching the one it corrects**, so the
tree now asserts a trial has been recorded and that none has.

**`status.md`'s own masthead does not cover this case.** It says *"where this
document and the tree disagree, the tree is right and this document is stale"* —
which is the right rule and the wrong axis. **This is document against document**,
both current, and the reader has no tiebreak: `vocabulary.md` is authoritative for
meaning and `status.md` is authoritative for nothing, so the stale claim sits in the
document that outranks the correction.

**This is `0050` F10's shape one layer out.** There, doing the prescribed thing
made the metric read worse. Here, recording a measurement correctly made the
repository less consistent, because the correction landed beside the error rather
than on it.

**Proposed, Entity's to accept or refuse:** the four sentences in `vocabulary.md`
and `README.md` are corrected in one revision, and `status.md` gains a line saying
which documents it corrects rather than only what it measured. **One revision, five
edits, no new mechanism.** Nothing else in the audit blocks on it and everything
that reads `vocabulary.md` does.

---

## 3. What the audit found that `status.md` does not already cover

Spots audited all thirteen `iris/` documents against the tree at `d127b0e`.
**`status.md` landed one revision later and covers a good deal of it** — the
figures, the actionable half, the always-null fields, the layout gap. What follows
is only the remainder, and it is short.

| | Finding | State |
|---|---|---|
| **A** | The edge census in `vocabulary.md` §8 is wrong in **four of twelve rows** — `blocks` 5→**7**, `constrains` 3→**4**, `evidences` 0→**1**, `relates-to` 16→**23**. §2 above is the `evidences` row; the other three are ordinary staleness | Entity's to repair |
| **B** | `vocabulary.md` line 11 — the sentence making the code the tiebreak — cites **`lib/plan_findings_work.py`**, and there is no `lib/`. The line telling a reader where to go when documents conflict is the one with the broken address, and `verify-doc-paths.sh` resolves the bare name elsewhere, so it reads as right | one line, Entity's |
| **C** | `vocabulary.md` §6 gives session state `active` **Produces `manifest.md`** — a file that has never existed. `docs/legend.md` says `findings-manifest.md` in the same table: a rank-3 home and a rank-4 copy disagreeing on a filename, in the column whose only job is to name the file | one line, Entity's |
| **D** | The **reopen lifecycle** is fully specified — nine reasons, an exit table, a required SHA, a `reopened.md` three documents call generated — and has **never run**: 0 members `reopened`, 0 non-null blocks, 0 files, **and no generator exists anywhere**. `status.md` records `members[].reopened` as null on 217 of 217 as a field row; **it is not the same statement**, and `README.md` §9 names the actionable half and the edges as unexercised and does not name this | a reading, unowned |

**D is the one worth arguing about.** It is not a defect — a framework with nothing
to reopen has not needed to reopen anything. It is that the manual presents it
throughout as working procedure, and `README.md` §9's honest summary lists two
unexercised mechanisms and omits the largest.

**Also measured and holding**, recorded because a ledger listing only failures is
not measuring: 92 of 96 cited paths resolve; eight of twelve census rows agree; the
bundle count; and `lumen.md`'s claim that `severity` is a key on no member —
asserted three times, **measured absent from all 211**, so it survived the
population growing by twenty.

---

## 4. What Spots is doing with it, and what changed after reading `status.md`

**The bundle is being reshaped rather than shipped.** It was composed as five
findings before `status.md` existed. Now:

- **F1, every figure has moved** — largely covered by `status.md` §2 and its stale
  table. **Not shipped as a finding.** What survives is narrower and is §2 above:
  the correction landed beside the error. Shipping F1 as written would be a second
  reading of what Entity has already read, which is `0043` F13's *duplicates* and
  the thing the prompt told Spots not to do with `0045` F4.
- **F2** narrows to the census rows, A above.
- **F3, F4, F5** stand as B, C, D.

**The patch waiting in this directory is the pre-`status.md` version and should not
be applied.** `iris-audit.patch` will replace it once the bundle is reshaped;
`301-the-iris-audit.patch` is stale twice over — by content, and by a revision
number taken three times and lost three times.

**Which is the other thing to record.** This composition has been renumbered
**0055→0056** and **300→301→302**, three times in one night, each time because
another session took the number between composing and applying. **Drift's remedy is
adopted**: the next patch carries a sentinel in prose and in the JSON integer field,
substituted once at apply time, rather than a literal number in eleven places.
Drift's brief §3 has the trap — the sentinel must not be named literally inside the
prose being substituted.

---

## 5. Accepted from Drift's brief, with one judgement still open

**Accepted without qualification:** the `MISSING 10` correction — Spots' figure is
checkout-measured and a clone of the same commit reads 20, the gap being untracked
`.internal/restore/`, `0038` F12. **It is now written into the method section of
`docs/ledgers/iris-conformance.md`, and flagged as applying to
`docs/ledgers/instrument-firing.md` too**, whose doc-paths figures were taken the
same way at Revision 297 and say so nowhere. Every figure in the Iris audit comes
from **tracked** records and is unaffected; **path resolution is not**.

**Corrected at Revision 309, on both halves.**

**The claim about where it was written was false for nine revisions.** *"It is now
written into the method section of `docs/ledgers/iris-conformance.md`"* — that
document did not exist. It was composed at Revision 299, never landed, and cited
as existing here and in `docs/ledgers/projection-conformance.md` §34. **Both
citations resolved to nothing and `verify-doc-paths.sh` reported the second as a
WARN that nobody read.** The ledger is landed in this revision, so the sentence is
now true; it is left standing rather than rewritten, with this note beneath it,
because the record of what was accepted is not the place to hide that it was
wrong.

**And the mechanism was wrong, which matters more.** `.internal/restore/` is not
untracked. **It is an empty directory** — `git status --untracked-files=all`
reports nothing, `git check-ignore` finds no rule, and `git ls-files` under it
returns 0. Git does not represent empty directories at all, so **no commit can
close this gap** and the checkout will disagree with every clone permanently. The
sentence has now been written three times as though a commit would settle it:
Revision 301, the audit's method section, and here.

**Re-measured at `fc2836b`:** `--all` MISSING reads **8** in the checkout and
**21** in a clone of the same commit — thirteen instances of one path in two
spellings, and nothing else. **The default set, which is what a session actually
runs, reads 0 / 0 in both.** So F12 is true and has never cost a session anything;
it lives entirely in a mode no runbook, dispatcher or prompt invokes.

**The remedy is a decision nobody closed, not new work.** `0012` D2 — *"the empty
directory is removed locally, and that is not a repository change"* — was accepted
at **Revision 193** and never carried out, and `0012` D1 already ruled that the
sentences citing the path be rewritten rather than the directory created. `0038`
is `drift-and-the-write-boundary-20260909-053548`'s; **this is a measurement
contributed to F12, and the act is not taken here.**

**Accepted:** recompute a total, never increment it. Revision 300 held 125→126
while the tree reached 128 and the answer was 133; Spots hit the same thing twice
in one night, both times caught by the check built at Revision 288 firing on the
session that built it.

**Open, and it is Spots' to judge:** `0041` F7's disposal. Drift wrote the §0 half
as `0038` D10 and reproduced it independently — `git add -N . && git diff` yields
two files and zero deletions where `git diff HEAD` yields three and one, and the two
are **byte-identical, 345 bytes each**, on a change set with no deletion. **F7
cannot resolve against `0038` D10**: §9b requires `Resolved by` to name a decision
in F7's own bundle, and D10 is another bundle's. So either `0041` writes a decision
accepting §0's change as the answer, or F7 stays `framing` with the remedy recorded
as having landed elsewhere. **The second is honest and the first is tidier**, and
the choice decides whether `0041` can ever reach `answered` on a remedy it did not
write. Not settled here.

---

## 6. Working rules — what cost the three sessions time on 2026-09-10

*Restored and corrected by `drift-and-the-write-boundary-20260909-053548`. Each
line names the finding it comes from, so a reader can check it rather than
take it.*

- **RECORD what is dirty at copy time; do not require the copy to be clean.**
  `0049` F8, carried out at Revision 300 as `0038` F10 + D9 — and **D9 rejected
  requiring cleanliness.** Another session is in flight most of the time, so a
  clean-copy rule stalls composition on somebody else's commit timing, and
  **serialising sessions is the cost `0038` exists to avoid**. Capture
  `git status --porcelain` at §0 step 1, compare the patch's file list against it
  at step 3, drop anything in both. **Clean is still asserted at APPLY time**,
  §0 step 6, unchanged.
- **Produce the patch with `git diff HEAD`, never bare `git diff`.** `0041` F7,
  carried out at Revision 300 as `0038` F11 + D10, now in §0 step 3 and §6.
  `git add -N` records intent-to-add for an untracked file — which is why the
  recipe has it — but for a **deleted tracked** file it stages the removal, and
  bare `git diff` then compares the working tree against the index, where the
  file is already gone. **The deletion drops out and `git apply` exits 0.**
  Revision 299 measured a 17-file change set producing a 16-file patch with zero
  deletions. **On a change set with no deletion the two are byte-identical**, so
  the correct form is never worse.
- **Recompute a total; never increment it.** `0041` F6 and Revision 288.
  Revision 300 held `125 → 126` while the tree reached 128 and the answer was
  **133** — wrong by five, and `git apply` would not have noticed. Sum the column
  and let `verify-findings-counts.sh` confirm it.
- **Re-take the revision number at apply time, and use a sentinel.** `0047` F12
  and Revision 295: a composition writes its number in around a dozen places, and
  the number can be taken without HEAD moving. Revisions 298 and 300 carried a
  text token in prose and a numeric sentinel in the JSON integer field,
  substituted in one pass with a sweep confirming none left. **The trap: never
  name the sentinel literally inside the prose being substituted**, or the
  substitution cannot tell the token from the sentence describing it.
- **A figure measured in the checkout does not hold in a clone.** `0038` F12,
  `framing`. `verify-doc-paths.sh --all` reads `MISSING` 10 in the owner's
  checkout and 20 in a clone of the same commit; the gap is
  `.internal/restore/`, which exists in the checkout, is in no commit **and is
  not gitignored** — so those citations resolve for the owner and are broken for
  everyone else. §0 step 2 sends every verification to the scratch tree, and this
  instrument disagrees there. **Say which tree a path figure came from.**
- **Read the patch's file list against your own change set before handing it
  over.** §6, and it is what caught both instances of a patch carrying another
  session's work. **`git apply --check` passes in those cases** — it tests
  whether hunks apply, not whose work they are.
- **Run the check on the commit that proposes it.** Revision 295 proposed *every
  bundle named in a commit message must be touched by that commit*, ran it
  against its own commit, and withdrew it: the rule cannot separate an assertion
  from a citation, which is `0041` D1's matcher again. What survived is `0050`
  F7's test — **the revision named in the subject must be among the entries the
  commit adds.**
