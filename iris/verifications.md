# Built-in verifications

> **Written before the genus rename, and checked against it at Revision 274.**
> Its measurements were taken against the tree and are current. Its vocabulary
> predates `members[]` and the four genera, so where it says *finding* it means
> what [vocabulary.md](vocabulary.md) now calls a **member**, and where it names
> a *bundle* the unit noun is under review. **No contradiction with the current
> vocabulary was found in it** — the check was for the session state `withdrawn`,
> which is now `dissolved`, and for the retired `findings[]` key. Neither
> appears. `vocabulary.md` is authoritative where the two ever disagree.
> **Role.** The reference for everything in this repository that stops a person or an
> AI doing something stupid, and everything that catches drift. It is authoritative
> for **what each instrument examines, what it does not examine, how to run it, and
> its standing baseline** — so that a reader can tell a real regression from a
> failure the tree has carried for weeks. It is not authoritative for any rule: a
> rule's home is `docs/legend.md`, `.github/session-management-instructions.md` or
> `.github/toolkit-instructions.md`, and this file cites them.
>
> **Every number below was measured** on 2026-09-09 in a scratch copy at
> `6ddb823` plus this session's uncommitted work: 54 findings bundles, 191
> findings, 134 decisions across four findings trees, 11 sessions, 65
> `metadata.json` files. Re-run the commands; do not quote these figures forward.
>
> **Never quote an OK total as a signal of health.** The OK total moves whenever
> anyone parks a note. `MISSING`, `FAIL` and `WARN` are the rows that mean
> something. This is the repository's own rule, taken from `0036`.

## Contents

- [1. What drift is here, and the four places it enters](#1-what-drift-is-here-and-the-four-places-it-enters)
- [2. The instrument table](#2-the-instrument-table)
- [3. Derivation as prevention](#3-derivation-as-prevention)
- [4. Single source of truth, and projections](#4-single-source-of-truth-and-projections)
- [5. Schema sections versus free-form sections](#5-schema-sections-versus-free-form-sections)
- [6. No hardcoding](#6-no-hardcoding)
- [7. Instruments that cannot fire, and one that must never be run](#7-instruments-that-cannot-fire-and-one-that-must-never-be-run)
- [8. What nothing checks at all](#8-what-nothing-checks-at-all)

---

## 1. What drift is here, and the four places it enters

Drift is a statement that was true when it was written and is not true now, with
nothing between the two moments that would say so. It is not a wrong statement —
a wrong statement is a defect and someone can argue with it. Drift is a *correct*
statement about a tree that has moved.

It enters in four places, and the instruments in section 2 are unevenly
distributed across them.

**The record** — the findings trees and the sessions. A finding has a `status`, a
bundle has a `standing`, a session has a `state`, and each of the three is
displayed in more places than it is stored. A count in an index, a standing in an
`INDEX.md` row, a state in a manifest: each is a copy of something a file owns,
and each can go stale silently. This is the best-covered surface — four checks
watch it.

**The tree** — the files themselves. A script moves and a document goes on naming
its old path. A directory is created and a coverage sweep that keeps its own copy
of the directory list never sees it. `verify-doc-paths.sh` and
`verify-doc-currency.sh` cover parts of this; `0050` F5 is what happens where
they do not.

**The rules** — the instruction sets, the legend, the prompts. A rule is edited in
its home and a prompt goes on paraphrasing the old one. `verify-doc-currency.sh`
is the only instrument aimed here, and its seven watches have never been armed
(section 7). A live instance: `verify-findings-counts.sh` and
`.github/toolkit-instructions.md` both cite *`.github/copilot-instructions.md`
section 4b* as the home of the one-fact-one-home rule. That file has five
headings and no numbered sections at all. The rule's live text is at
`docs/architecture/state-as-data.md:290`. Two instruments cite a section that no
longer exists, and nothing failed.

**The instruments themselves** — a check that no longer looks at what it claims
to, or that cannot fire. This surface has no coverage whatever: no check reads a
checker's output, and `0042` F5 records `verify-doc-paths.sh` printing two
`command not found` errors on every invocation for thirteen revisions with nobody
noticing. It still does, from lines 39–40 of its own usage block, where two
comment lines lost their leading `#`.

[&#8593; Contents](#contents)

---

## 2. The instrument table

Run everything from the repository root. All but two of the 47 `bin/*.sh` scripts
self-locate anyway (section 6), so the working directory is a convention rather
than a requirement.

| Instrument | Examines | Does **not** examine | Run it | Standing baseline (measured) |
|---|---|---|---|---|
| `bin/verify-session-findings.sh` | Dispatcher. Resolves a subcommand from one table and runs it from the root. Prints one summary. | Anything not in its table — deliberately not `verify-doc-paths.sh`, `verify-runbook-structure.sh`, `verify-script-portability.sh`, which belong to the reimage workflow rather than to this framework | `./bin/verify-session-findings.sh` (= `all`) | **exit 1 on a clean tree**, because `headers` fails. `list` and `manifest-revision` exit 0 |
| `… counts` | Every displayed count against the file that owns it: a bundle's `Findings` against its own finding table; a session's `Bundles` and `Findings` against its `findings-manifest.md`; and, since Revision 288, **every prose total of the form `N bundles · M findings` against the table it sits beneath** | Whether the counted thing is the right thing in any other sense; anything not a count. A total in a document that holds no bundle-numbered table is not read — it is a quotation, not a claim | `./bin/verify-session-findings.sh counts` | **FAIL 0** at Revision 288, after the one its fourth section raised was repaired |
| `… headers` | The `findings.md` header schema — required fields, no off-schema field, field order, one field per line with hard breaks; the finding-table shape; the six finding statuses; F- and D-number cross-references; that every decision cites a finding (0039 D15); fenced-not-indented code blocks | The rendered page; whether a header's *content* is true; `Scope` is never required | `./bin/verify-session-findings.sh headers [--verbose]` | **OK 1353, FAIL 11 — this is the baseline, not a regression.** All 11 are D15 uncited decisions in two bundles: `0030` (D1–D8) and `0035` (D1–D3). See the note below the table |
| `… structure` | Two invariants nothing else tests: every data row carries its own table's cell count, per table not per file; and every bundle's **derived** standing agrees with its `INDEX.md` row | Blank cells (legal, meaning "same as above"); table content; anything outside the four `INDEX.md` / `findings-manifest.md` shapes | `./bin/verify-session-findings.sh structure [--verbose]` | **OK 68, FAIL 0** |
| `… completeness` | Whether each `metadata.json` carries everything the markdown it came from holds. The only one that asks whether something is **missing** rather than whether what is present is well formed | Well-formedness (the other three do that); anything the extractor never tried to capture | `./bin/verify-session-findings.sh completeness` | **0 completeness problems** |
| `… manifest-revision` | The next free `APPLY-MANIFEST.md` revision, scanning both the header block and the entry headings, so an uncommitted entry is visible | Whether a change actually took a revision — it reads the manifest, not the log | `./bin/verify-session-findings.sh manifest-revision` | Reports **270**. A report, not a verdict; excluded from `all` for that reason |
| `bin/verify-doc-currency.sh` | Asserted source→dependent edges. Digests each watch's sources and reports `DRIFTED`, `UNCONFIRMED` or `current` | Anything not asserted in `doc-currency.json`. Nothing is inferred from similarity, filename or proximity — by design | `./bin/verify-doc-currency.sh` | **7 watches, 0 drifted, 7 UNCONFIRMED; exit 1** (four are `critical`). `0 drifted` is not health — see section 7 |
| `… --coverage` | What is swept and unwatched. Roots are derived from `docs/INDEX.md` plus `alsoWalk`, minus declared exclusions | `bin/`, `.internal/`, `.share/`, `templates/` — none is a swept root | `./bin/verify-doc-currency.sh --coverage` | **30 files watched, 65 unwatched; exit 0.** Swept: `.claude`, `.github`, `docs/architecture`, `docs/ideas`, `docs/ledgers`, `docs/rules`, `references` |
| `bin/plan-findings-work.sh check` | Every comparison the four checkers do not make, over `metadata.json`: vocabulary membership, orphans, dangling citations, decisions and resolutions ahead of their findings, edges into superseded bundles, and `UNSTAMPED` / `STORED-DISAGREES` on all three derived fields | Markdown. It reads only the data. Superseding clones are exempt from the two ordering comparisons (`0047` F5) | `./bin/plan-findings-work.sh check` | **43 findings across 54 bundles, and it exits 0 regardless** — `UNCITED-DECISION` 21, `RESOLUTION-AHEAD-OF-FINDING` 11, `CLOSED-BUNDLE-LIVE-FINDING` 8, `ORPHAN` 2, `DECISION-AHEAD-OF-FINDING` 1. **Zero `UNSTAMPED`, zero `STORED-DISAGREES`** |
| `bin/plan-findings-work.sh stamp` | Writes `standing` and `progress` onto every bundle and `state` onto every session, from what they derive from | Nothing else. It is a writer, not a check | `./bin/plan-findings-work.sh stamp [--dry-run]` | **`--dry-run`: would write 0 records.** Every derived field agrees with its derivation |
| `bin/test-session-management.sh` | Contracts and regressions of the framework's logic, against fixtures: the derivation ladder, the three vocabularies, permission shape, cross-file agreement, the allocator, the interviewer, and named regressions from `0046`, `0047`, R197 and R229 | The tree. It never reads `docs/`; a fixture passing says nothing about a real bundle | `./bin/test-session-management.sh [-v]` | **54 tests, all OK, exit 0** |
| `bin/review-changes.sh` | This session's change set, grouped by area, counted, with rule/hook/prompt files and deletion-only files flagged for close reading | Correctness of anything. It is a reading aid, not a check. **It runs `git add -N .`** — see the caution below | `./bin/review-changes.sh [--files] [--patch PATH]` | **16 files, +1108 / −46; nothing flagged**, exit 0 |
| `bin/verify-doc-paths.sh` | Repository paths named in documents, plus wikilink anchors. `PROPOSED` and `HISTORICAL` markers keep a not-yet-built path and a path-as-it-stood from reading as `MISSING` | By default only 10 documents: `README.md`, `.claude/CLAUDE.md`, `.github/copilot-instructions.md` and everything under `.github/guides` and `.github/ai-prompts`. **`session-management-instructions.md`, `toolkit-instructions.md` and `docs/legend.md` are not in the default set.** Relative links are not extracted at all (`0044`) | `./bin/verify-doc-paths.sh` / `--all` | Default: **MISSING 0, WARN 0, SKIP 7**, exit 0. `--all` over 255 documents: **MISSING 0, ANCHOR BROKEN 0, WARN 281, PROPOSED 13, HISTORICAL 69**, exit 0. Also prints **two `command not found` errors every run** |
| `bin/verify-runbook-structure.sh` | Runbook structural rules from `.github/ai-prompts/runbook-prompts/runbook-prompt.md` | Anything outside the 27 runbooks; content | `./bin/verify-runbook-structure.sh` | **PASS 213, WARN 5, FAIL 25, exit 1 — a standing baseline.** Codes are `NO-NOTE`, `LEGEND`, `PITFALL` |
| `bin/verify-script-portability.sh` | Bash 3.2 + BSD userland compatibility across 90 scripts, by reading rather than executing | Behaviour. It never runs anything | `./bin/verify-script-portability.sh` | **CLEAN 90, WARN 0, FAIL 0, SUPPRESSED 2**, exit 0 |
| `.claude/hooks/*.sh` | Three `PreToolUse` guards: `runbook-guard.sh`, `session-guard.sh`, `write-location-guard.sh`. The last refuses a write inside the owner's checkout | The tools a bridged session actually writes through — section 7 | Automatic, via `.claude/settings.json` | Cannot fire for a bridged session |

**Reading the `headers` baseline.** `verify-session-findings.sh --help` names six
bundles as the standing baseline: `0005`, `0012`, `0013`, `0025`, `0030`, `0035`.
Measured today, rows come from **two** of the six. The script deliberately
hard-codes no count — quoting a stale total as a baseline is `0036` exactly — but
the bundle list is itself a copy, and four sixths of it has gone stale: section
1's fourth surface, in the file that warns about it. Ten further rows in `0031`
and `0032` are exempt by design, being `superseded` frozen evidence.

**Caution on `review-changes.sh`.** `git add -N` records a new file against the
empty blob. `0049` F7 records a later `git checkout -f` truncating all four of a
closing's new files to zero — 22,813 bytes — while `git status` went on listing
them as `A`, caught by a `json.load` raising and by nothing else.

[&#8593; Contents](#contents)

---

## 3. Derivation as prevention

Three fields are derived and then stored: a bundle's `standing` and `progress`,
and a session's `state`. `docs/legend.md` says they are written by
`./bin/plan-findings-work.sh stamp` **and by nothing else.**

The prevention is in the shape, not in a rule anyone has to remember:

- `stamp` computes each value from what it derives from — finding statuses,
  ownership, lineage, and for a session, what it owns and whether `ended.on` is
  set — and writes it in place, preserving key order.
- `check` compares the stored value against a fresh derivation and reports
  **`UNSTAMPED`** when a field is `null` (`"progress is null -- run stamp"`) and
  **`STORED-DISAGREES`** when the stored value and the derivation differ
  (`"standing says X, the record derives Y"`).
- Measured now: `check` reports **zero of each**, and `stamp --dry-run` **would
  write 0 records**. Those two facts together are what "the derivations are
  current" means. Neither alone is.

**A hand-edited status is a defect, not a shortcut.** If a person sets `standing`
by hand and it happens to match, nothing catches it and nothing was gained. If it
does not match, `check` reports `STORED-DISAGREES` and the hand-written value is
what gets discarded. The value carries no information the derivation does not
already have; writing it by hand only removes the guarantee that it was derived.
The test suite pins this: `test_a_null_standing_is_reported_as_unstamped`,
`test_a_stored_value_that_drifts_is_caught`, `test_stamping_makes_the_check_pass`.

One documented exception exists, and it is a repair rather than a practice.
`0050` F6 records that section 10a releases a bundle in four steps, none of them
*regenerate*, so a release leaves the stored `ownership` disagreeing with the
index row — measured there as 65 OK / 0 FAIL becoming 59 OK / 7 FAIL in
`structure`. The advertised cure is the instrument that must never be run
(section 7), so those fields were set by hand and the record says so. That is the
correct handling of a procedure gap: name it, do the safe thing, run `stamp`, then
let `check` name what was missed.

[&#8593; Contents](#contents)

---

## 4. Single source of truth, and projections

The rule, whose live text is `docs/architecture/state-as-data.md:290`: **a fact
has one home, and a copy is permitted only where it is generated, or where a
check fails when it drifts.**

A projection is therefore legitimate in exactly two conditions:

| Projection | Home | What makes the copy legal |
|---|---|---|
| A findings index row's `Findings` count | the per-finding table in that bundle's `findings.md` | `counts` fails when it drifts |
| A session row's `Bundles` | rows in its `findings-manifest.md` | `counts` fails when it drifts |
| A session row's `Findings` | the sum of those bundles' counts | `counts` fails when it drifts |
| A bundle's `standing` in its `INDEX.md` row | the derivation over `metadata.json` | `structure` fails when it drifts |
| `standing`, `progress`, `state` in `metadata.json` | the derivation | generated by `stamp`; `check` fails when it drifts |
| The subcommand list in `verify-session-findings.sh` | `check_table()` | the usage text, the `list` output, the group expansion and the dispatch all read that one function, so a second list cannot exist |
| Coverage roots in `doc_currency.py` | `docs/INDEX.md` | derived at read time — this was a stale second copy until `0050` F5 |

The defect the counts check exists for is subtler than a wrong number:
`docs/sessions/INDEX.md` once carried a column headed `Findings` holding a count
of **bundles** — an accurate count of the wrong thing, which no self-consistency
check could catch. Each figure is therefore compared against a *named* source,
never against another display of itself.

Two copies in the tree today satisfy neither condition, and both are named above:
the `§4b` citation in `verify-findings-counts.sh` and `toolkit-instructions.md`
pointing at a section that no longer exists, and the six-bundle baseline list in
`verify-session-findings.sh` of which two are still true.

[&#8593; Contents](#contents)

---

## 5. Schema sections versus free-form sections

The framework enforces shape where a vocabulary must stay fixed, and enforces
nothing where a rigid shape would manufacture content. Both halves are deliberate.

**Enforced shape** — checked by `headers`, `structure` and `counts`:

- `findings.md` header: `Recorded`, `Session`, `Severity` required; `Felt at`,
  `Scope`, `Read`, `Relates to` optional; that order; **no other field in the
  block**; one field per line, every line but the last ending in two spaces.
- The finding table `| # | Finding | Status |`, required even for a single
  finding, with no `Decided` column — "decided" is a status, not a column.
- `Status` cells: one of the six finding statuses and nothing else.
- `decisions.md` / `resolutions.md`: `Bundle` and `Session` required; the field is
  `Bundle`, never `Findings bundle`; `Read`, never `Read against`; **no `Status`
  field at all** — that would be a third copy of a bundle's standing, and 17 had
  gone stale by Revision 202.
- `findings-manifest.md` and `metadata.md`: fixed table columns.
- Code blocks fenced with ` ``` `, tagged `text` and never `markdown`, never
  indented four spaces.

The schema exists because it was arrived at by counting: **seventeen distinct
field names across forty-one readings**, several the same capture under a
different word, and two that actively misled. A schema nothing checks becomes
seventeen names again.

The schema fixes the **vocabulary**, not the content. `Scope` is optional
precisely because requiring it would mean inventing one for the 26 readings that
never had one — "which is not a checker's business."

**Deliberately narrative** — `prompt.md`, `handoff-<stamp>.md` and
`final-summary.md` have **no schema**, on the stated ground that a rigid one
produces empty headings. A required minimum only: a prompt names its reading
order and its task; a handoff names what transfers, what is known broken and what
is owed; a final summary names every bundle the session owned and that bundle's
disposal, by name. Nothing checks any of it.

The prose bodies of `findings.md`, `decisions.md` and `resolutions.md` below the
header are free-form for the same reason, and `0039` F21 gives the argument
against changing that: a presence check on a rejected alternative would
manufacture the thing it looks for.

**Reformatting is not a change.** Bringing a file onto these shapes — renaming a
field, reordering a header, moving an off-schema field into prose — is not an edit
to the reading, and does not need `reopened` even on a `resolved` or `superseded`
bundle. What is frozen is the content.

[&#8593; Contents](#contents)

---

## 6. No hardcoding

**Scripts self-locate.** An entrypoint resolves its own directory from
`BASH_SOURCE`, climbs a fixed number of levels to the root, and `cd`s there.
Measured: **45 of 47 `bin/*.sh` do this**; the two that do not,
`check-reimage-env.sh` and `setup-reimage-env.sh`, are documented run-from-here
diagnostics. The helpers under `.internal/ai-scripts/session-management/` climb
three levels rather than one and each carries a comment saying so, because moving
a script between depths without editing that line is a failure already hit here.

`verify-session-findings.sh` exists partly for this: `verify-findings-structure.sh`
once tested `-d docs` against whatever the current directory happened to be, so
running it elsewhere reported "run from the repository root" — operator error
rather than a script unable to find itself.

**`REIMAGE_ROOT` was retired as a variable.** `bin/prepare-artifact-root.py` says
so at line 11 and self-locates instead. Nothing needs to be told where the repo is.

**`reimage.env` / `reimage.env.example`.** `reimage.env.example` is committed and
is the contract; `reimage.env` is local, machine-specific, listed in `.gitignore`
alongside `reimage.env.stale-*`, and `git ls-files` confirms **only the example is
tracked**. The example states its own rules: resolved absolute values only, no
`${VAR:-...}`, no `$HOME/...`, no `$EXTERNAL_DATA_VOLUME/...` inside a value.
`.envrc` exports `FRACTOGENESIS_HOME="$(pwd)"`, sources `reimage.env` through
`dotenv` when present, and does `PATH_add bin`.

**Loader discipline.** `.internal/load-reimage-config.sh` is sourced-only: it
returns 2 on failure rather than exiting, and its single `exit 2` refuses direct
execution. Entrypoints use `set -euo pipefail`; aggregate validators deliberately
do not, because aborting on the first miss would hide the rest.

**Never commit:** `reimage.env`, any `reimage.env.stale-*`, and any hardcoded
personal or company path, secret, or live placeholder path.

**Measured drift here, unwatched by anything:** the example declares **14**
`export` keys, the local `reimage.env` declares **29**; fifteen live keys have no
example counterpart, and `REIMAGE_ARTIFACT_ROOT` — which the example declares and
scripts read — is absent from the local file. `bin/check-reimage-env.sh` is
diagnostic-only and greps four key names; nothing compares the two files.

[&#8593; Contents](#contents)

---

## 7. Instruments that cannot fire, and one that must never be run

`docs/rules/rule-enforcement-avenues.md` §6 states the count from the other side:
**six instruments here have reported failure against a healthy tree on their
first run.** Below is the opposite failure — instruments that report success
because they cannot report anything else.

**1. `.claude/hooks/write-location-guard.sh` cannot fire for a bridged session.**
Recorded by **`0050`, finding F1**. `.claude/settings.json` matches it on
`Edit|Write|MultiEdit|Bash`. A session bridged to the owner's machine writes
through `mcp__remote-devices__device_bash` and
`mcp__remote-devices__device_commit_files`; neither name matches, so the hook does
not run at all. This document was written through `device_bash`, which is the
demonstration.

**2. The `superseded` exemption in `verify-findings-headers.sh` can never apply.**
Recorded by **`0050`, finding F2**. The finding-status check is guarded by
`[ ! -f "$dir/STATUS-superseded" ]`. Revision 222 deleted every `STATUS-` tag file:
measured, **0 remain in the tree**, so the guard is always true and the exemption
is unreachable. (The D15 citation check has a *separate*, working exemption that
reads `supersededBy` from `metadata.json`. Only the status-vocabulary exemption is
dead.)

**3. No `doc-currency` watch has ever been armed.** `0039` F22 recorded this for
the `agent-config` watch. Measured across all seven: `sourceDigest` is `null` on
every one, so `evaluate()` returns `UNCONFIRMED` and `DRIFTED` is unreachable
until somebody runs `--confirm`. **`0 drifted` is not a health signal; it is the
only value the field can hold.** Exit is still 1: four of the seven are `critical`.

**4. `plan-findings-work.sh check` cannot gate anything.** `cmd_check` prints and
returns `None`, and `main()` never calls `sys.exit` for it. Measured: **43
conformance findings, exit status 0.** Anything that gates on its exit code passes.

**5. `bin/verify-doc-paths.sh` is not read by anything, including when it is
broken.** `0042` F5: it has printed two `command not found` errors per invocation
since Revision 221, past six instruments and thirteen revisions. It still does,
from lines 39–40, and the run still exits 0.

### `extract-metadata.py` must never be run

Recorded by **`0050`, findings F3 and F6**, and stated in `APPLY-MANIFEST.md`
Revision 263 as *one instrument must never be run*. It regenerates every
`metadata.json` from the markdown, and on a healthy tree it unmakes the record.

The claim in the manifest is 62 files, 429 recorded values, 20 fields, measured at
Revision 260. **I re-measured it here** by copying the tree to a throwaway
location, snapshotting all 65 `metadata.json` files, running the script with no
arguments, and diffing:

| | measured today |
|---|---:|
| `metadata.json` files rewritten | **65 of 65** |
| recorded values destroyed | **601** |
| distinct field names losing a value | **38** |
| `edges` entries | **59 → 31** |
| bundles carrying a `standing` | **54 → 0** |
| records carrying a `state` | **11 → 0** |

These are larger than the manifest's figures because the tree has grown since
Revision 260 and this flattening counts each nested `edges[]` key separately; the
claim is confirmed in kind and direction. **Every bundle's `standing` and every
session's `state` are emptied** — `docs/legend.md` gives a session exactly three
live values, and one run leaves all eleven with none. The instrument that exists to
make the data authoritative is the one thing that can empty it.

**It has no safe no-op.** The plain invocation writes; `--dry-run` is the only
non-writing path, and the run that first measured the damage was an unrecognised
`--help` that the script treated as live — anything that is not exactly
`--dry-run` or `--check` is a live run. The stamped values re-derive with
`plan-findings-work.sh stamp`; **the asserted edges do not.**

The safe act, when a release or a transfer has left `structure` failing: set
`ownership` by hand, run `./bin/plan-findings-work.sh stamp`, then run
`./bin/plan-findings-work.sh check` and let it name what was missed.

[&#8593; Contents](#contents)

---

## 8. What nothing checks at all

**The rendered page.** `0042` F1: every checker reads the markdown as text — grep,
awk, pipe counting. None renders it. A file can be correct as text and wrong as a
page, and `0042` F2 records three consecutive revisions shipping a rendering
defect that all six checkers passed; each was found by the owner opening the page.
`0042` F3 decided against the remedy: no markdown parser and no third-party
package, the floor being zero non-stdlib imports across the tree.

**Session identity, and therefore every load-bearing permission.**
`rule-enforcement-avenues.md` §5.1 and `0045` F3: only the owning session opens a
finding, from `decided` onward only the owner records, `resolved` is frozen. A
guard sees a tool call and a path, never which session is writing. **The
framework's central permission is unenforceable**, and a check written against
*who may* would pass vacuously. §5.1 is explicit that this is an argument for
knowing the permissions are conventions, not for building an identity mechanism.

**The commit message and everything handed over in conversation.** §5.2 and `0039`
D21: the commit message never reaches a tracked file, so no guard, check or
generator can see it — the owner is the only instrument. Reviews, recommendations
and disclosures of what was not checked are in the same position.

**Whether a change took a manifest revision.** §4.1: Revisions 241 through 246
were composed, verified, applied and committed with **no entry**, while
`check-manifest-revision.sh` reported the numbers free the whole time — it reads
the manifest, not the log. Revision 247 reconstructed six entries after the fact.
This is the highest-value guard not built.

**And the inverse of it, which is worse.** `0050` F7, recorded 2026-09-10:
nothing compares what a commit **message** asserts against what the commit
**contains**. Three instances measured — `636eba0` titled *Revision 271* adds
Revision 270, `889b8ac` titled *Revision 285* adds Revision 284, both another
session's; `777f468` titled *Revision 287* adds 286 and 287, both its author's and
therefore legitimate. **The discriminator is whose revision, not how many**, since
Revision 266 established that a commit may carry several. The cost is not
cosmetic: `check-manifest-revision.sh` has read commit subjects since Revision 278
(`0047` F12), so **a mis-scoped subject consumes a number** — `APPLY-MANIFEST.md`
runs 287 · 286 · 284 and **no entry is numbered 285, nor can one be**. The
instrument that reads the log correctly is what makes a wrong sentence
irreversible.

**The quality of a reading.** §5.3 and `0039` F21: whether a decision's rejected
alternatives are real, whether a severity is honest, whether prose restates a fact
a table derives. None is decidable, and a presence check would manufacture what it
looks for. One tractable slice is named and unbuilt: assert that no word from one
vocabulary appears in a table headed by another.

**Which tree a reading was taken against.** `docs/ideas/anchoring-a-reading.md`:
**zero fields anchor a reading.** `schemaVersion` is `1` on all 65 files and
versions the shape, not the tree. The mechanism exists twice and on the wrong half
of the object — `answersAsOf` on 7 of 130 decisions, `resolution.commit` on 33 of
73 resolutions — both anchoring what a bundle *did*, neither what it *saw*.

**Most of the executable tree.** Measured: **112 files** under `bin/`,
`.internal/`, `.share/` and `templates/` carry a `.sh`, `.py`, `.md` or `.json`
extension; **9** appear in a `doc-currency` watch; the remaining **103 are neither
watched nor reported as unwatched**, those directories not being swept roots — the
same shape as `0050` F5, one directory over, and unfixed.

**`reimage.env.example` against reality.** Nothing checks that the example covers
the keys the scripts read, nor that a local `reimage.env` carries what the example
declares. Section 6 measures the current gap at 15 keys one way and one the other.

**What a checker emits.** `0042` F5. No instrument reads another instrument's
output, which is why item 5 in section 7 survived thirteen revisions, and why the
first four items in that section survived at all.

[&#8593; Contents](#contents)
