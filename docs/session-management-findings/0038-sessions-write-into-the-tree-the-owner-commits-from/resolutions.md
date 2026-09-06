# Resolutions — sessions write into the tree the owner commits from

**Findings bundle:** `0028` · **Status:** `resolved`, 2026-09-04.
**Owner:** `restore-apps-outstanding-20260903-000000`.
**Decisions:** `decisions.md`, four across six findings.

The reasoning is in `decisions.md` and is not repeated. This file records what
was actually done.

| # | Finding | Resolved by |
|---:|---|---|
| 1 | Two sessions' uncommitted work interleaves in shared files | The composition rule in §3 and `docs/legend.md` |
| 2 | A revision's validator baselines are measured on another session's tree | The same rule — validators run in the copy |
| 3 | A session's work has no diff boundary | The same rule — the patch is the unit |
| 4 | Backing out one session's change is surgical | The same rule — declining a patch replaces reversal |
| 5 | A session can amend a revision the owner has already committed | Numbering at apply time, and `bin/check-manifest-revision.sh` |
| 6 | The write discipline does not distinguish where a write is composed | A separate section in `docs/legend.md`, orthogonal to the categories |

---

## What changed

**`.github/copilot-instructions.md` section 3** — the version-control block is
rewritten around composition. *"Leave your work uncommitted in the working tree"*
is gone; a session now copies the checkout to session-local storage, edits and
validates there, and hands over a `git diff`. Four points that the practice
turned out to need are stated rather than left to be rediscovered: validate in
the copy because only there do the numbers describe your own change; `git
apply --check` before applying and say so; staging inside your own copy is not a
write to the owner's repository, while staging in the owner's checkout still is;
and a copy in session-local storage dies with the session, so hand over at
stopping points and say when work exists only there.

A further point covers finding 5: **the revision number is taken at apply time**,
with `./bin/check-manifest-revision.sh` run against the tree being applied to.

**`bin/check-manifest-revision.sh`** — new. Prints the next free
`APPLY-MANIFEST.md` revision number by scanning **both** places a number can be
taken: the `**Revision N**` header block and the `## Revision N` entry headings.
The second is the point. The rule it replaces read the header block alone, so an
entry written but not yet committed was invisible to it — which is why two
sessions following that rule exactly both took 167, and why it happened again two
revisions later. `--free N` tests a composed entry's number, `--current` reports
the highest taken, and `--verbose` names the highest found in each place, so a
header that lags its entries is visible rather than inferred.

**`docs/legend.md`** — a new section, *Where a write is composed*, after the
write categories. It states the rule for all three categories at once, gives the
table separating what each rule varies by, and records the cost — a copy in
session-local storage dies with the session — rather than arguing it away. It
also notes that evidence writes were already solved this way by a different
route: no write permission by default, granted by the owner one run at a time.

**`docs/ideas/knowing-when-it-is-safe-to-write.md`** — half of this idea has been
decided and built, so that half leaves the idea. The revision-number question,
its three candidate shapes and the collision that prompted it are removed and
replaced by a pointer here; what remains is the second question, which files are
safe to touch. Its *what exists today* section gains the thing this resolution
took away: `git status` was the only mechanism that ever worked, and now that
sessions compose in their own copies the owner's tree is usually clean, so it no
longer shows a concurrent session at all. **That observability has not been
replaced.** The file keeps its name — eight documents cite it, and `0009` is
about exactly that.

**`docs/sessions/session-responsibilities.md`** — the shared-rules block carried
the superseded numbering rule, a hard-coded *"at Revision 130"*, and the claim
that `docs/` is gitignored. It now states the composition rule, the
apply-time numbering rule, that all of `docs/` is tracked, and — since the file
describes two sessions from 2026-09-01 and has tracked none since — that its
numbers and dates are a snapshot and are not maintained.

## Found while resolving, and fixed

Two counts stated away from the lists they count, both wrong since Revision 180
made one vocabulary six and the other four:

- §4c said **THE FIVE STATUSES**; `docs/legend.md` has six.
- §4d said **THE FIVE STATES**; `docs/legend.md` has four.

Both now say *the statuses* and *the states* with no number, which is §4b's own
one-home rule applied to the sentence that points at the home. A count restated
beside a pointer to the list is the unchecked copy the rule forbids, and these
two are the proof: the revision that changed both vocabularies did not think to
look for a number two sections away.

A third, in `docs/legend.md`: the `└── any session may write ──┘` separator
appeared twice, once correctly under the diagram and once stranded below the
`superseded`/`withdrawn` paragraph. Removed.

And the new script's first name, `next-manifest-revision.sh`, broke the
verb-first naming rule in §3 — caught before it was validated, renamed to
`check-manifest-revision.sh` beside `check-reimage-env.sh`. §3's prefix list was
itself incomplete: `check-` and `verify-` are both in use in `bin/` and neither
was listed. Both added.

## What this resolution does not do

**The instruction set has not adopted the write-category vocabulary.**
`docs/legend.md` still says sections 4b through 4d *"predate this vocabulary and
say the same things at greater length"*, and that adoption is still owed. It
belongs to `0029`, which reads the instruction set as a whole, and doing it here
would be the second session in two days to edit those sections around a different
concern.

**Nothing enforces the composition rule.** It is a rule a session follows, not
one a check catches. The signal that a session did not follow it is a dirty
working tree in the owner's checkout, which the owner sees in `git status` — the
same manual look this bundle relied on.

**The second half of `knowing-when-it-is-safe-to-write.md` is untouched.** Which
files another session is holding open remains unanswered, and is now slightly
harder to answer than before.

## Validation

Run in the scratch copy against this change alone.

| Check | Result | Against baseline |
|---|---|---|
| `verify-doc-paths.sh --all` | 774 OK / 0 MISSING / 1108 ANCHOR OK / 0 ANCHOR BROKEN | unchanged |
| `verify-runbook-structure.sh` | 213 PASS / 5 WARN / 25 FAIL | unchanged |
| `verify-script-portability.sh` | 83 clean / 0 WARN / 0 FAIL | 82 before — the new script is the difference |
| `verify-findings-counts.sh` | 37 OK / 0 FAIL | unchanged |
| `bash -n bin/check-manifest-revision.sh` | passes | — |

The new script was also exercised directly: `--free` on a taken number exits 1
and on a free one exits 0; a bad option and a non-numeric argument both exit 2;
and against a fixture whose header block says 5 while an entry heading says 7 it
returns 8 and reports that an entry exists the header does not summarise — the
collision case, in the one place the old rule could not look.

The environment was a Linux VM (Bash 5.1, GNU coreutils) on the owner's Mac, not
macOS. `/bin/bash -n` against stock Bash 3.2 remains owed for Revisions 116
onward and now covers a script written today.

The commit hash and the manifest revision for this resolution are in
`APPLY-MANIFEST.md`; this bundle's row in
[`../INDEX.md`](../INDEX.md) names them.
