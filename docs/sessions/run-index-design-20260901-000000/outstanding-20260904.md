# Outstanding — 2026-09-04

Written by `run-index-design-20260901-000000` on 2026-09-04, at the owner's
instruction ("write all outstanding"), and rewritten after the two pushes that
landed as Revisions 195 and 196. Everything below was re-verified against live
`HEAD` `3604743` and against the artifact volume on the day it was written; no
claim here is carried forward from an earlier reading without being checked
again, because the first draft of this file had three claims that the two pushes
had already made false.

This is a record write. It states what is owed and by whom; it decides nothing
and resolves nothing.

---

## 1 — What the two pushes closed

Three things this session was carrying are done, and one of them is done because
somebody else caught this session's mistake.

**`0030` is `resolved`.** Its finding 3 was assigned to this session and decided
by it as D7, under the owner's override of 2026-09-04. D7's toolkit write has
since been made by `pre-image-capture-conformance-20260903-194532`:
`artifact_run_record_rename()` is in `.internal/artifact-runs.sh` at line 668,
with the full rename procedure at line 735 and the header rule that explains it.

**D7's closing claim was wrong, and this session did not notice.** D7 asserted
that every finding in `0030` then carried a decision, which is the condition the
`resolving` gate turns on. Finding 1 did not — as D7's own text says two
paragraphs earlier. The other session found it, added D8 (deferring detection
with a measurement rather than rejecting it), and held its toolkit write in its
composing copy until the gate closed honestly. That is recorded in
`docs/cross-cutting-findings/0030-.../resolutions.md`, and it is the single most
useful correction anybody has made to this session's work: the gate is only worth
having if the session standing at it reads its own bundle rather than its own
summary.

**`0032` is `resolved`** and produced `bin/verify-findings-structure.sh` — a
fifth validator checking two things nothing checked: that every data row has its
own table's column count, and that every bundle's `STATUS-` tag agrees with its
`INDEX.md` row.

**`0035` exists and is `resolved`** — *a lineage rename is a procedure, not an
operation.*

---

## 2 — Owed by this session, still open

### 2.1 Four pins on `bookends/` — **done 2026-09-04 under an owner's grant**

The owner named four lineages whose official run must be a later one than the
first-wins rule computes. All four are now pinned: a `pin` row in
`reimaged-system/bookends/MANIFEST.md` and a `PINNED-OFFICIAL.txt` inside each
run.

| Lineage | Pinned to | What first-wins computes |
|---|---|---|
| `restore-repos-entry` | `20260902-160157` | `20260825-033849` |
| `restore-git-entry` | `20260901-083539` | `20260824-174717` |
| `restore-access-entry` | `20260824-063529` | `20260820-011553` |
| `restore-apps-entry` | `20260825-065638` | `20260825-042828` |

**They were load-bearing, and the counterfactual was measured rather than
asserted.** Before the pins, all four `official/<context>.txt` pointers already
read the wanted run — by coincidence, not by pin: they were the old latest-wins
result, unrebuilt since Revision 193 made `entry` first-wins. A rebuild of the
category with the four `pin` rows and markers stripped puts every one of them on
the left-hand column. With the pins in place a full `artifact_runs_rebuild` moves
nothing.

**One claim in this file's own first draft was wrong, and the measurement is what
caught it.** The draft said the flip would happen silently. It would not:
Revision 193's own reporting fires on each of the four —
*`'restore-git-entry': official is restore-git-entry-20260824-174717;
restore-git-entry-20260901-083539 is newer and not official`* — and names the
`artifact_run_set_official` call that would settle it. The hazard was a loud
report nobody was there to read, not a silent loss, and the distinction matters
because it is the difference between a missing check and a missing reader.

**The blast radius was exactly four, which was also measured.** Every other
multi-run lineage in `bookends/` sits at a latest-wins point — nine of them, all
`exit` — so the rule change had no other subject in that category and the rebuild
that followed the pins changed no pointer anywhere.

### 2.2 Three retroactive `rename` rows — **done 2026-09-04 under the same grant**

Owed by D7, across two categories, and unperformable when D7 was written because
no helper emitted the row.

| Category | Surviving context | Former context |
|---|---|---|
| `office-stability/` | `pre-image-office-stability-assessment` | `pre-image-office-stability-checklist` |
| `office-stability/` | `pre-image-office-stability-evidence` | `pre-image-office-stability` |
| `reimaged-system/comparisons/` | `restore-runtime-inventory-diff` | `post-image-restore-runtime-diff` |

The two `office-stability` rows carry `unknown` in the Point column, because
neither context name ends in a known point — which is what D7's own worked
example shows, so the shape is as decided rather than a degradation. No pointer
moved in either category, as `artifact_run_record_rename` promises and as the
before/after comparison confirms.

The third row is the one D7 called the proof: `post-image-` appeared zero times
in that manifest, so until now the only surviving evidence of the former name was
the broken citation in
`bookends/runs/restore-runtime-exit-20260820-032645/bookend.md`. It is recoverable
from the index for the first time.

### 2.3 `0014` — `STATUS-unresolved`, owned here

*Orphaned comparison lineage `runtime-version-comparison`.* Still unresolved,
and still visible on the volume:
`reimaged-system/comparisons/official/restore-runtime-version-comparison.txt`
points at the orphan.

### 2.4 `0021` — `STATUS-unresolved`, owned here

*`restore-access-exit` predates its own state walk.* Untouched.

### 2.5 `rm -d .internal/restore` on each checkout

The directory is still present in this session's copy. `0012`'s D2 settled that
it is removed locally rather than fixed in the tree — it was never tracked, so no
patch can carry its deletion. This is a per-checkout instruction, not a change,
and it is written here so that it is not lost when this session is.

### 2.6 `/bin/bash -n` under macOS stock Bash 3.2

Owed for Revisions 116 through 196. Every period of this session's ownership has
run on Linux with Bash 5.x, where `mapfile`, `declare -A`, `sed -i` and
`stat -c` all work and none of them works on the target. The debt is unchanged
and grows with anything this session writes.

---

## 3 — Corrections owed inside this session's own bundle

**`findings-manifest.md`'s `0030` note is stale in three ways.** It says the
bundle "is `in progress`" (it is `resolved`), that "`0030` cannot advance until
finding 3 is decided" (it was, as D7), and that "a bundle owned elsewhere is
blocked here" (it is not any more). The note's *structural* point still stands
and should survive the rewrite: a finding-level assignment across bundles has no
shape in the instruction set, section 4d's manifest being per-bundle throughout,
and the counts must stay `10`/`10` for `verify-findings-counts.sh`. The note
should become a past-tense record of how that gap was navigated once, and should
say that D7 was written under an owner's override and that its closing claim was
wrong.

**`docs/sessions/session-responsibilities.md` describes a pairing that no longer
exists.** It was written 2026-09-01 and names the two sessions running then. The
concurrent session is now `pre-image-capture-conformance-20260903-194532`. Whether
that file is refreshed, superseded, or retired is the owner's call; it is flagged
rather than edited because the half of it this session does not own is not this
session's to rewrite.

---

## 4 — Found, and belonging somewhere other than here

### 4.1 Four `resolved` bundles carry per-finding rows that read `in progress`

`docs/legend.md` states the rule plainly: *"the bundle cannot be `resolved` while
any row is not."* Four bundles are `STATUS-resolved` with rows that have never
moved:

| Bundle | Rows still `in progress` |
|---|---|
| `0030-renames-break-citations-and-which-may-be-repaired` | 5 of 5 |
| `0035-a-lineage-rename-is-a-procedure-not-an-operation` | 3 of 3 |
| `0031-superseding-a-bundle-whose-session-is-gone` | 4 of 4 |
| `0032-index-and-manifest-tables-have-a-shape-nothing-checks` | 4 of 4 |

All four are owned by `pre-image-capture-conformance-20260903-194532`. Two of
them are `0032` itself and the bundle `0032`'s validator was written to protect.

**`bin/verify-findings-structure.sh` passes all four, and correctly so.** Its
header names its two invariants exactly: column count per table, and the bundle's
tag against its `INDEX.md` row. Per-finding status coherence is a third
invariant, and it is the one the legend states in prose. The validator is not at
fault; the check that would have caught this does not exist. That it was missed
by the validator written for precisely this class of defect is the interesting
part of the finding, not an indictment of it.

Note the defect is confined to bundles that carry the table. `0005` and `0012`
carry no per-finding status table at all — they predate the convention — so they
are not instances, though whether a resolved bundle should be *required* to carry
one is the same question from the other side.

**Routing.** All four bundles are `resolved` and therefore closed; this is not a
contribution to any of them. It wants a new bundle, or a supersession of `0032`.
The owner decides which, and this session does not own it either way.

### 4.2 Eight volume-side citations of a run id a rename removed

Re-censused today; unchanged. Six `bookend.md` files, plus
`comparisons/MANIFEST.md` and
`comparisons/official/restore-runtime-version-comparison.txt`, cite
`post-image-restore-runtime-diff-20260820-032625` or
`runtime-version-comparison-20260819-121523`. `0030`'s D5 had queued one of them.
`0030` is now closed, so the remaining seven need a new bundle or a supersession
rather than a contribution — and they overlap `0014`, which is open and owned
here.

### 4.3 Table 3's banner is false wholesale

`docs/ledgers/evidence-conformance.md:82` still reads **"No artifact was
migrated"**, untrue since Revision 138. `0013`'s decisions already routed this —
*"Wants its own cross-cutting bundle"* — and nobody has opened it. `docs/ledgers/`
holds that a ledger is re-derived and replaced rather than patched, which is why
this is larger than a three-passage edit.

### 4.4 `0034` is unowned

*`restore-git.md` Step 0a names two rows the recorder no longer emits.* Recorded
by this session while resolving `0005` D6, left `STATUS-unresolved` and
deliberately unowned, because the runbook is the owner's active work.

---

## 5 — The limits this list is written inside

**Evidence writes need the owner, per run.** The artifact root is read-only to
this session by default. Items 2.1 and 2.2 were performed on 2026-09-04 under a
grant covering those seven writes and nothing else; the root is read-only again.

**`git apply` cannot carry this repository's whole state.** It under-applies a
deletion against the connected folder while exiting 0 (`0032` finding 4), and it
cannot carry a file with no content at all — the `STATUS-` markers are 0 bytes,
so `diff` emits no hunk and `diff -ruN` emits no `new file mode`. Revisions since
193 have been applied by direct copy, with `git status` and `git diff --summary`
as the review surface. Any list of "what this patch changes" that is derived from
a diff will under-report by exactly the files that matter most to a bundle's
status.

**The composition rule says where a change is composed and never says when it is
handed over** — `0029` finding 8, and the reason this file stops in the composing
copy rather than arriving in the tree.
