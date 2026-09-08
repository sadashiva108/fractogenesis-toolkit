# Prompt — session management re-evaluation

This session was started on 2026-09-06 from `conformant-prompt.md` and
`session-management-prompt.md` as they stood **before** that day's revisions, and
was handed `prompt-amendments-20260906.md` in flight. Where the amendments
contradict the two prompts, the amendments win.

**This copy tracks rather than freezes.** The three files below are reproduced
from `/Users/dkittrell/reimage-workspace/session-prompts/` as they stand at
Revision 207, which is what a session cloned today would be given — not as they
stood when this session began. It is refreshed whenever either prompt changes,
per *Standing constraints*: retrofit rather than leave half a change behind. The
exception there covers evidence, and a prompt is not evidence.

---

## Part 1 — the conformant prompt

# Conformant session prompt

**Last updated:** 2026-09-06 14:45 EST  
**Current as of:** `APPLY-MANIFEST.md` Revision 206

If the repository is past that revision, this file may have fallen behind — say so
rather than following it where it disagrees with `docs/legend.md` or the
instruction sets.

Paste this in full when opening a new session, then paste the session-specific
prompt beneath it. This half is the same for every session and is kept current as
the rules change — that is what *conformant* means. The half you add underneath
is what makes the session yours.

---

## Read these first, in this order, before doing anything

1. `.github/copilot-instructions.md` — points at the two instruction sets
2. `.github/session-management-instructions.md` — how work is recorded
3. `docs/legend.md` — every finding status, bundle status and session state
4. `.github/toolkit-instructions.md` — the project's own subject, if your work touches it
5. `docs/INDEX.md`, then the INDEX.md of whichever findings tree you are working in

Do not begin work, and do not answer questions about the repository, before 1
through 3. They are short. **The vocabulary in them is not guessable**, and a
session that guesses produces a bundle somebody else has to correct.

## Connected folders

- **repo** — `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit`
- **artifact root** — `/Volumes/Data/reimage-CVG-0002160-500-20260816-open`
- **workspace** — `/Users/dkittrell/reimage-workspace` (this file's home)

## Create your session bundle first

```text
docs/sessions/<title>-<stamp>/
```

`<title>` is a short readable scope. `<stamp>` is `YYYYMMDD-HHMMSS`, local time.
The name is fixed at creation — renaming it breaks every prompt, handoff and
index row written against it.

It needs, from the moment it exists: `STATE-available`, `prompt.md` holding this
prompt and yours, and `metadata.md`. Add a row to `docs/sessions/INDEX.md`.

`metadata.md` records the assistant, its session identifier and transcript link
where exposed, the model it was configured for, **the environment it actually ran
in**, and the date. That environment line matters: this repository targets macOS
stock Bash 3.2 and you are almost certainly on Linux with Bash 5 and GNU
coreutils. Name where a check ran; never report a Linux result as verified.

**Every value in it is resolved. No placeholders.** Not `<repo>`, not
`<workspace>`, not `<EVIDENCE_ROOT>` — the absolute path, the real identifier,
the actual commit. A `metadata.md` is read years later by someone with no other
source and no way to expand a placeholder, and an unresolved one there is
indistinguishable from a fact nobody recorded. The same holds for every document
in a bundle. A placeholder belongs in a schema or a template, never in a record.

**`prompt.md` tracks.** When the conformant prompt or your session prompt
changes, refresh the copy in your bundle and say which revision it now holds. A
prompt is what a session is expected to follow, not a souvenir of what it was
handed.

You are `available` until you own a findings bundle. Owning one makes you
`active`. The owner assigns bundles; recording one does not make you its owner.

## The statuses, in one paragraph

A **finding** is `un-started`, `framing`, `decided`, `resolved`, `reopened` or
`withdrawn`. A **bundle's** status is *derived* from its findings by a ladder in
`docs/legend.md` — read it in order, first row that matches wins. Three statuses
mean *nobody has looked at this yet* and behave identically: `un-started` and
`reopened` on a finding, `transferred` on a bundle. All three are invisible to
every session but the owner, and **the owner's first reading is what moves them
on**.

**`unclaimed` is the status you will meet first.** It is the ladder's first row
— one of the two that are about **ownership rather than progress** — and it means
no session owns the bundle: parked and closed to every session until the owner
assigns it, listed in no `findings-manifest.md`, carried only by its index row.
**No finding is ever `unclaimed`**; it belongs to a bundle and to nothing else.

**Your queue is what the owner assigned you, not what `ls` returns.** A tree can
hold `unclaimed` bundles that have nothing to do with your brief. Reading one
because it is there is how a session takes work nobody gave it.

**What assignment does, in order.** The owner assigns; you do not take. On
assignment the bundle becomes `STATUS-un-started` with every finding in it
`un-started`, and your session bundle drops `STATE-available` for `STATE-active`.
**Your first reading is the transition**: the bundle becomes `STATUS-analyzing`
and every finding in it becomes `framing`. Nothing else moves them, and no
session but the owner can perform that first read.

**While a finding is `framing`, any session may record to it** — sharpen the
reading, and equally write a decision, reject one or refine one. Deciding is not
the owner's privilege; *closing* the deciding is, and that is `decided`. From
there only the owner records. `resolved` is frozen and `reopened` is the only
door back.

## The conventions, where they live

Read the one that matches what you are about to touch. Do not infer a convention
from the file you are editing — several predate the rule they appear to follow.

| Editing | Read first |
|---|---|
| a runbook | `.github/ai-prompts/runbook-prompts/runbook-prompt.md` |
| a `bin/` or `.internal/` script | `.github/ai-prompts/script-prompts/bash-script-authoring-and-review.md` |
| adding a new script | `.github/guides/script-types-and-locations.md` — where it goes, by what kind it is |

**Artifact naming, timestamping, retention and pointer policy are runbook-level
decisions.** Present options with trade-offs before changing any of them; do not
decide one in passing while fixing something else.

## The rules you will break if nobody tells you

**Never commit, never push, never `git add` in the owner's checkout.** The owner
reviews and commits everything.

**Compose outside the checkout.** Copy the repository to session-local storage,
edit there, run the validators there, `git diff` and hand over a patch. Working
directly in the owner's tree produces a diff that cannot be committed apart from
whatever else is in flight.

**Wait to be asked before applying a patch.** Composing is not delivering. Show
what you made; the owner says when it lands.

**`git apply` exits 0 whether or not it did what you asked.** It cannot unlink on
a connected folder and downgrades that failure to a warning. **This is not only
about deletions** — `git apply` modifies an existing file by writing a
replacement and unlinking the original, so the refusal fires on plain
modification too, and whether the content lands then depends on a fallback. A
patch carrying a deletion lands incomplete; a patch carrying only modifications
may land perfectly. **The exit status distinguishes none of it, and neither does
any checker.**

Verify by **comparing the two trees** — `diff -r` of your copy against the
checkout — or `cmp` on every path the patch touched. Not the exit status. Not a
checksum of the files the patch names, because that only sees files the patch
carries as content and a deleted file carries none.

**Ask for delete permission before you apply, not after it fails.** The connected
folder refuses `unlink` until the owner grants deletion for that folder. If your
patch deletes or renames anything, request it **before** applying — and note that
**every status transition is a delete plus a create**, so this bites every
`STATUS-` and `STATE-` tag change you will ever make. The grant is per folder,
for the session, and **does not survive a bridge reconnect**: if the link drops
and comes back, request it again rather than discovering it mid-apply. If it is
declined or goes unanswered, move the file into a `_to_delete/` subfolder under
the same connected folder and tell the owner — never leave two tags on one
bundle. This remedy is not yet in either instruction set; it is owed there.

**Expect a trailing-whitespace warning and do not act on it.** The header schema
requires two trailing spaces on every line of a header block but the last, so
`git apply` warns on every conformant header you hand it. Stripping them to
silence the warning breaks the rendering the schema exists to protect.

**Take the `APPLY-MANIFEST.md` revision number at apply time**, with
`./bin/verify-session-findings.sh manifest-revision` against the tree being applied to. Never while
composing.

**One file, one owner.** More than one session may be writing. Read freely; edit
only what your bundles cover, and flag rather than edit anything on the other
side. `git status` in the owner's checkout no longer shows you a concurrent
session, because everyone composes in their own copy — so the boundary is the
manifests, not the diff.

**Keep your scratch copy at one stable path**, refresh it whenever a push lands
and again before deriving any patch, and read every patch's file list before
handing it over. A patch derived from a stale copy applies cleanly and silently
undoes someone else's work.

**Anything you run against the artifact volume is read-only** unless the owner
has said otherwise, for that run. Those are dated records of a machine that no
longer exists in that state. **If a change to it is authorised, back it up first**
— it is not under version control.

## Before you hand anything over

Run every checker, in your copy, and report the numbers:

```text
./bin/verify-doc-paths.sh --all
./bin/verify-runbook-structure.sh
./bin/verify-script-portability.sh
./bin/verify-findings-counts.sh
./bin/verify-findings-structure.sh
./bin/verify-findings-headers.sh
```

**Baselines to compare against, not to zero.** Runbook structure **213 PASS / 5
WARN / 25 FAIL** across 27 documents; portability **0 WARN / 0 FAIL**; doc paths
**0 MISSING / 0 ANCHOR BROKEN**; the three findings checks **0 FAIL**. A number
that moves is either your bug or your improvement — say which.

**Do not quote the `OK` totals as a baseline.** They move whenever anyone parks a
note, which is what made them useless as a signal. `MISSING`, `ANCHOR BROKEN`,
`WARN` and `FAIL` are the rows that mean something.

**The portability floor is macOS stock Bash 3.2 and BSD userland.** No `mapfile`,
no `declare -A`, no `sed -i`, no `stat -c`, no GNU-only flags. Prefer parallel
indexed arrays and NUL-delimited traversal. You are almost certainly on Linux
with Bash 5 and GNU coreutils, where every one of those works silently —
`verify-script-portability.sh` catches what `bash -n` cannot see, and neither
substitutes for the other.

Two things they do **not** cover, so do not quote them as though they do.
**No check compares a bundle's derived status against its own finding rows** —
Revision 197 found four `resolved` bundles whose rows had never moved. And **no
check reads the rendered page**; every one of them reads the source, which is the
section above. That second one is `0042`, recorded in Revision 204 with the four
options for fixing it and none of them costed — it is open, and it is why the
instruction to open the page yourself is an instruction rather than a check.

**Every check here answers whether a document is well formed. None answers
whether it is complete.** They are different questions and the second one has no
checker at all: a file that lost half its content still has a valid header, a
well-shaped table and a clean render, and passes all six. Opening the page does
not catch it either — **rendering cannot show you content that is not there.**

So when you generate or rebuild a document, verify its content is present, by
its source: every line of the input accounted for, every section that should
exist existing. This is not hypothetical. Rebuilding a `prompt.md` with
`{ sed -n '1,11p' file; …; } > file` truncated the file before `sed` opened it,
silently dropped its first eleven lines, and passed every check and a render
inspection. **Never redirect into a file you are reading from** — write to a
temporary file and move it into place.

`verify-doc-paths.sh` **without `--all` scans the `.github` surface only** — 98
paths and no anchors at all. Always pass `--all`, which reaches `docs/` as well:
778 paths and 1108 anchors. `0036` is about that flag's OK total moving whenever
anyone parks a note, not about `docs/` being unscanned.

## What to do when you find something

Park it as a findings bundle rather than widening the task. Finding a second
defect while fixing the first is normal; fixing both in one change is how a small
edit becomes an unreviewable one. Say in your summary that you parked it.

Take the next free number immediately before writing — another session may have
taken the one you saw.

Its `findings.md` follows the schema in section 11.

**Required: `Recorded:`, `Session:`, `Severity:`. Optional: `Felt at:`,
`Scope:`, `Read:`, `Relates to:`. No other field appears in the header** — that
is the rule the whole schema rests on.

`Recorded:` is the date and the occasion. **`Session:` is its own field**, never
packed into that sentence; it holds the session-bundle name, the identifier, or
both, and `—` where none was ever recorded. `Read:` is a bulleted list of what
the reading was taken against, not a sentence with commas in it.

Then a `Findings` table numbered `F1`, `F2` — **required even when the bundle
holds one finding**, and its `Status` cell holds one of the six finding statuses
and nothing else.

`decisions.md` and `resolutions.md` take `Bundle:`, `Session:`, and the date the
work was done. **Neither carries a `Status:` field**: the `STATUS-` tag and the
index row own the status, and a third copy is a copy that will contradict them.
Decisions are `D1`, `D2` and name the findings they answer; resolutions name the
finding by number alone and the decision that resolved it, with `Revision` and
`Commit` as separate fields. Every `F<n>` and `D<n>` cited on one side must exist
on the other.

## Markdown is what it renders as, not what it says

**Every checker in `bin/` reads the source.** Three revisions in a row shipped a
defect that was invisible there and obvious the moment somebody opened the page:
a header that read fine as text and rendered as one run-on paragraph, and a
schema example that rendered as live markdown — the specification displaying as
the defect it specifies against.

Three rules follow, and they are checked:

- **One field, one source line, and every line but the last ends with two
  spaces.** Markdown joins consecutive lines into one paragraph. Without the hard
  breaks, five labelled facts render as a single sentence with the names buried
  in it. A long value stays on its one line; wrapping it is what breaks the
  block.
- **Fence every example with ` ``` `, never four-space indentation.** Renderers
  disagree about the indented form, and one of them processed section 11's own
  schema example as markdown.
- **Tag the fence `text`, never `markdown`.** Some renderers read that tag as
  *render this as markdown* and interpret the example instead of showing it.
  `text` is inert everywhere.

**Open what you wrote in a renderer before you hand it over.** Not the source —
the page. That is where the last three defects were found, every time by the
owner rather than by a check.

## How the owner wants a session to run

- **Show findings before edits.** A numbered plan, approved, then the change.
- **One deliverable at a time.** Do not batch four items into one turn.
- **When you find a second defect while fixing the first, park it and keep
  going.** Say at the end what you parked.
- **Name the environment every check ran in.** *"Tested on Linux"* and *"tested on
  the target Mac"* are different claims.
- **When asked for a commit message**: short subject, a line or two of body,
  ending with the `Co-Authored-By` and `Claude-Session` trailers. The manifest
  entry holds the reasoning; the message points at it. **The block is the message
  and nothing else** — no `git commit`, no `-m`, no quoting wrapper. The owner
  commits with a plain `git commit` and pastes into the editor. Commands and
  reminders go in the conversation beside the block, never inside it.

## Standing constraints

- The owner commits. You never do.
- A fact has one home. A copy is permitted only where it is generated, or where a
  check fails when it drifts.
- **Retrofit; never leave half a change behind.** When a rule changes, bring the
  existing records onto it rather than applying it only to what comes next. A
  tree where some documents follow the rule and some do not teaches the next
  session the wrong thing, and partial conformance is harder to read than none.
  **The one exception is data captured at a point in time that cannot be
  recreated** — a dated artifact, a measurement, a commit hash, a session
  identifier, what a `metadata.md` recorded about a run that has ended. That is
  evidence, and evidence is never rewritten to match a later rule.
- Say what you did not check, as plainly as what you did.
- If a rule here contradicts `docs/legend.md` or the instruction sets, they win
  and the contradiction is itself a finding.

---

## Part 2 — the session prompt

# Session prompt — session management

**Last updated:** 2026-09-06 11:00 EST  
**Current as of:** `APPLY-MANIFEST.md` Revision 205

If the repository is past that revision, this file may have fallen behind — say so
rather than following it where it disagrees with `docs/legend.md` or the
instruction sets.

Paste **after** `conformant-prompt.md`. That one says how any session works; this
one says what *this* session is for.

---

## Your subject

**How sessions and findings bundles themselves work** — the statuses, the states,
the rules binding them, the instruction set that carries those rules, and the
checks that hold them. Not the project's own subject; that belongs to sessions
working from `.github/toolkit-instructions.md`.

Your findings tree is `docs/session-management-findings/`. Nothing that is not
strictly about session management goes in it, and the test is one question:
**would this finding still exist in a project that did something else entirely?**

## What is waiting for you

Seven bundles, all `unclaimed` — parked and closed to every session until the
owner assigns them to you. Read them in this order; the first two are the ground
the others stand on.

| | |
|---|---|
| `0037` | The findings architecture disagrees with itself and with the tree |
| `0038` | Sessions compose their changes in the tree the owner commits from |
| `0039` | The instruction set lags the rules it governs — 7 decided, 1 never decided |
| `0036` | `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold |
| `0040` | Superseding a bundle whose session is gone is instructed but never defined |
| `0041` | The index and manifest tables have a shape nothing checks |
| `0042` | No check reads the rendered page — recorded 2026-09-06, supersedes nothing |

Each supersedes an original that stays where it was — same number minus ten,
still in its old tree, still listed by the session that held it, `superseded`.
**Read the originals.** They carry the reasoning, and `0037` and `0038` are fully
resolved readings whose resolutions are the thing in question.

**Their readings are unchanged; their files are not.** Revision 203 brought all
three onto the header schema, after they had been held back from three revisions
of reformatting on a rule that turned out to be wrong in its reach — `0041`
states the defect it rests on in its own findings table, so the evidence never
depended on the original staying misshapen. Reformatting is not an edit to the
reading. Editing what one of them *says* still is, and still needs `reopened`.

## Read, in this order

1. `docs/legend.md` again, closely — you are about to re-evaluate it
2. `.github/session-management-instructions.md` end to end
3. `docs/architecture/findings-and-sessions.md` — why the shape is what it is,
   and its section 12, which is a list of open questions nobody has answered
4. `docs/architecture/transferring-part-of-a-bundle.md` — three options, none chosen
5. The six bundles below, in the order given
6. `docs/sessions/session-responsibilities.md` — **a dated record, not rules.**
   It opens with a table of what has superseded each of its claims

## The owner's brief

The architecture carries inconsistencies and contradictions, **including among
the resolved bundles**. Re-evaluate from the ground up. The vocabulary was
rebuilt in Revisions 198–203 and is current; what has not been re-read is whether
the decisions underneath it still hold.

## Report before you change anything

The owner reads findings before edits. For each bundle, in the conversation:

- **One paragraph**: what it says, its status, and what resolving it would take —
  described, not decided.
- **Where it touches the others.** Several of these were filed apart while being
  the same subject, which is why they are now in one tree.
- **Anything in it the tree no longer matches.** These readings are from
  2026-09-01 onward and the vocabulary changed under them in Revisions 198–201.
  A reading that describes `in progress` or `resolving` is describing a status
  that no longer exists — say so rather than translating silently.
- **What you would need from the owner** before any of it could be worked.

## What is already known to be wrong

Not a survey. These came up in the course of other work and were recorded rather
than fixed — expect more.

- **`verify-doc-paths.sh`'s OK total cannot be a baseline.** With `--all` it
  reaches `docs/` — 778 paths, 1108 anchors — and that figure moves whenever
  anyone parks a note. Without the flag it covers the `.github` surface only: 98
  paths and no anchors at all, on an exclusion whose stated reason —
  *"gitignored working notes … they never reach a fresh clone"* — has been false
  since Revision 162. That is `0036`. Quote `MISSING` and `ANCHOR BROKEN`, never
  `OK`.
- **No check reads the rendered page.** Every checker in `bin/` reads the source,
  and Revisions 201, 202 and 203 each shipped a defect visible only once the page
  was rendered — each found by the owner opening the file, none by a session.
  **This is `0042`**, recorded in Revision 204. Its F3 is the live question:
  a rendering check needs a CommonMark parser, which is a dependency this
  repository does not have, and four options are set out with none costed. The
  decision is the owner's. Read F4 before proposing one — the audit that did find
  these reported 131 failures on its first run, of which **128 were bugs in the
  audit**.
- **No check compares a bundle's derived status against its own finding rows.**
  Revision 197 found four `resolved` bundles whose rows had never moved. Two were
  corrected in Revision 200; the check still does not exist.
- **The rollup in `docs/runbook-findings/INDEX.md` has 27 unchecked derived
  figures** — nine runbooks × bundles, findings, resolved. Added in Revision 190,
  reconciled by hand, and `verify-findings-counts.sh` still has no rule for them.
  **This is an unpaid debt from the session that wrote it.**
- **`0039` finding 8 is undecided** — the composition rule says *where* a change
  is composed and never said *when* it is handed over. It is the reason `0039`
  never closed.
- **`0041` finding 3 and `0039` D3 disagree** on how a bundle is classified:
  *classify by subject* against §4c's *where the fix lands*.
- **`transferred` and the per-finding case.** Bundle-level transfer is
  implemented; transferring part of a bundle is not, and the options are in
  `docs/architecture/transferring-part-of-a-bundle.md`. It ends on the question
  that decides it: **is a bundle a unit of ownership, or a unit of reading?**

## What is settled and should not be re-litigated without cause

Recorded so you know what is load-bearing rather than accidental.

- **Status is carried by the finding; the bundle derives it** by an ordered
  ladder. That inversion is what removed the hand-maintained statuses.
- **Three statuses mean *nobody has looked yet*** and behave identically:
  `un-started`, `reopened`, `transferred`. Reading is the transition.
- **`resolved` is frozen and `reopened` is the only door** — revising settled
  work is a declared act, not a quiet correction.
- **Reformatting is not a change**, and does not need `reopened`. Bringing a file
  onto the header schema — renaming a field, reordering, moving an off-schema
  field into prose, building a table from what is already there — is not an edit
  to the reading. What is frozen is the content.
- **The header schema**, section 11: `Recorded`, `Session` and `Severity`
  required, `Felt at`, `Scope`, `Read` and `Relates to` optional, **no other
  field in the header**. `Session` is never packed into another field's value.
  Findings are `F1`, `F2`; decisions are `D1`, `D2` and cite the findings they
  answer; resolutions point at the decision, with `Revision` and `Commit` as
  separate fields. **Neither `decisions.md` nor `resolutions.md` carries a
  `Status:` field** — the tag and the index row own the status.
- **A field and its value own a rendered line.** One field per source line, two
  trailing spaces on every line but the last, examples fenced with ` ``` ` and
  tagged `text` rather than `markdown`. This is the rule three consecutive
  revisions broke, each in a different way, and each time it was the owner
  opening the page that caught it.
- **The session management set and `docs/legend.md` are project-agnostic** and
  measure zero project-specific references. Keep them that way; a template for
  the third file is in `../instructions-templates/`.

## What you own, and what you must not touch

Your tree is `docs/session-management-findings/`. The rules live in
`.github/session-management-instructions.md` and `docs/legend.md`, and those two
are **project-agnostic by design** — they measure zero project-specific
references and a checker is not what holds that, you are. If a change would put
this project's name, paths, revision numbers or finding numbers into either file,
it belongs in `.github/toolkit-instructions.md` instead.

**One file, one owner.** Other sessions are working the project's own trees. The
runbooks, `bin/`, `.internal/` and `.github/toolkit-instructions.md` are theirs;
flag rather than edit. The boundary is the manifests, not the diff — everyone
composes in their own copy, so the owner's checkout is clean even when three
sessions are mid-change.

## What this session owes when it ends

Every bundle it owns, disposed by name in `final-summary.md`. A session may not
end leaving a bundle owned by a session that has stopped — the unfinished ones
become `unclaimed` and go back to the queue, which is what happened to
`phase-11b-hydrate-and-bookends`'s five in Revision 200 and to `0001` in
Revision 205.

**`closed` means every bundle it owns is terminal** — `resolved`, `superseded` or
`withdrawn` — **and any that is not has been released to `unclaimed`.** The
legend required them all to be `resolved` until Revision 205, which no session
whose work had been superseded could ever satisfy.

Releasing a bundle is not a way of finishing it. Say in the summary what was
answered and what was never read, and leave any status the owner alone may set —
moving a finding to `decided` is the owner's act — for whoever takes it next.

---

## Part 3 — amendments issued in flight, 2026-09-06

# Amendments to the prompts you were given

**Last updated:** 2026-09-06 11:00 EST  
**Covers:** `APPLY-MANIFEST.md` Revisions 201–205

Paste this into a session that was started from `conformant-prompt.md` and
`session-management-prompt.md` **before 2026-09-06**. Where this contradicts what
you were given, this wins. Both prompt files are now current; this exists only so
a session already running does not have to be restarted.

Revisions 201 to 205 landed after those prompts were written.

---

## 1. The header schema gained two fields and lost one

**Required is now `Recorded:`, `Session:`, `Severity:`.** Optional is `Felt at:`,
`Scope:`, `Read:`, `Relates to:`. No other field appears in the header.

- **`Session:` is its own field.** It was packed into `Recorded:` — *"2026-09-01,
  session `01KcZ…`, item 2"*. `Recorded:` now carries the date and the occasion
  only. `Session:` holds the session-bundle name, the identifier, or both, and
  **`—` where none was ever recorded** — 23 headers hold a dash. Do not invent one
  to fill the field.
- **`Read:` is new and optional**: what the reading was taken against, as a
  **bulleted list** under the field, not a sentence with commas in it.
  `decisions.md` called this `Read against:`; that name is retired.
- **`decisions.md` and `resolutions.md` carry no `Status:` field.** Nor
  `Status when opened:` nor `Status now:`. The `STATUS-` tag and the index row own
  the status; 43 copies were removed and 17 of them had already gone stale.

The `Findings` table is **required even for a single-finding bundle**, and its
`Status` cell holds one of the six finding statuses and nothing else — no note
about which decision settled it.

Findings are `F1`, decisions are `D1`, resolutions name the finding by number
alone and the decision that resolved it. **Every `F<n>` and `D<n>` cited on one
side must exist on the other**, and `bin/verify-findings-headers.sh` checks it.

## 2. Markdown is what it renders as, not what it says

Three rules, all checked, all learned the hard way:

- **One field, one source line, and every line but the last ends with two
  spaces.** Markdown joins consecutive lines into one paragraph. Without the hard
  breaks the whole header renders as a single run-on sentence. A long value stays
  on its one line; wrapping it is what breaks the block.
- **Fence every example with ``` — never four-space indentation.**
- **Tag the fence `text`, never `markdown`.** Some renderers read that tag as
  *render this as markdown* and interpret the example instead of showing it.

**Open what you wrote in a renderer before handing it over.** Every checker in
`bin/` reads the source. Revisions 201, 202 and 203 each shipped a defect
invisible there and obvious on the page, and every one was found by the owner
rather than by a check.

## 3. `verify-doc-paths.sh` — the old claim was wrong

You may have been told it *"does not scan `docs/` at all"*. That is true only
without the flag: bare, it covers the `.github` surface — 98 paths, no anchors.
**With `--all` it reaches `docs/`: 778 paths, 1108 anchors.** Always pass
`--all`. `0036` is about that OK total moving whenever anyone parks a note, not
about `docs/` being unscanned. Quote `MISSING` and `ANCHOR BROKEN`, never `OK`.

## 4. The superseded originals were reformatted

You may have been told the originals of `0036`–`0041` are *"unedited"* and not to
touch them. **Their readings are unchanged; their files are not.** Revision 203
brought `0026`–`0032` onto the header schema. Reformatting is not an edit to the
reading. Changing what one of them **says** still is, and still needs `reopened`.

## 5. There is a seventh bundle: `0042`

`docs/session-management-findings/0042-no-check-reads-the-rendered-page/` —
four findings, `unclaimed`, recorded in Revision 204. It supersedes nothing.

**No check reads the rendered page**; three consecutive revisions shipped defects
of that kind while all six checkers passed. Its **F3 is the open question**: a
rendering check needs a CommonMark parser, a dependency this repository does not
have, and four options are set out with none costed. **That decision is the
owner's, not yours.** Read F4 before proposing one — the audit that did find
these reported 131 failures on its first run, of which 128 were bugs in the
audit.

The tree is **7 bundles, 34 findings**, all `unclaimed`.

## 6. `closed` admits every terminal status

`docs/legend.md` defined `closed` as *"every bundle it owns is `resolved`"*. It
now reads: **every bundle it owns is terminal — `resolved`, `superseded` or
`withdrawn` — and any that is not has been released to `unclaimed`.** The old
wording meant no session whose work had been superseded could ever close.

## 7. `0001` is back in the queue, and carries an open question

`0001-restore-repos-evidence` was released to `unclaimed` in Revision 205 when
`restore-apps-outstanding-20260903-000000` closed. It is not yours — it is a
runbook bundle — but one thing in it is a session-management question and may
reach you:

**Its F1 reads `framing` while its own prose says nothing about it is
outstanding**, which under the current vocabulary is `decided`. Moving a finding
there is the owner's act. It was asked twice and not answered, and the bundle's
derived status depends on it. `0009`'s single finding carries `un-started`, which
understates a reading that did happen — also unanswered.

## 8. Numbers that moved

| | |
|---|---|
| Current revision | **205** |
| Vocabulary rebuilt in | Revisions 198–205 |
| `verify-findings-headers.sh` | 889 checks — it was 205 when the prompts were written |
| `verify-findings-structure.sh` | 51 |
| `verify-findings-counts.sh` | 50 |
| `verify-doc-paths.sh --all` | 778 paths, 1108 anchors, 0 broken |
| `verify-runbook-structure.sh` | 213 PASS / 5 WARN / 25 FAIL — unchanged baseline |
| Next free bundle number | **0043** |

<!-- historical: bin/verify-findings-headers.sh -->
