# Conformant session prompt

**Last updated:** 2026-09-08 10:14 EST  
**Current as of:** `APPLY-MANIFEST.md` Revision 221

If the repository is past that revision, this file may have fallen behind — say so
rather than following it where it disagrees with `docs/legend.md` or the
instruction sets.

Paste this in full when opening a new session, then paste the session-specific
prompt beneath it. This half is the same for every session and is kept current as
the rules change — that is what *conformant* means. The half you add underneath
is what makes the session yours.

---

## Table of Contents

- [[#Read these first, in this order, before doing anything|Read these first, in this order]]
- [[#Connected folders|Connected folders]]
- [[#Create your session bundle first|Create your session bundle first]]
- [[#The statuses, in one paragraph|The statuses, in one paragraph]]
- [[#The conventions, where they live|The conventions, where they live]]
- [[#The rules you will break if nobody tells you|The rules you will break if nobody tells you]]
- [[#Before you hand anything over|Before you hand anything over]]
- [[#What is in flight right now|What is in flight right now]]
- [[#What to do when you find something|What to do when you find something]]
- [[#Markdown is what it renders as, not what it says|Markdown is what it renders as, not what it says]]
- [[#How the owner wants a session to run|How the owner wants a session to run]]
- [[#Standing constraints|Standing constraints]]

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
- **workspace** — `/Users/dkittrell/reimage-workspace` (scratch and patches)

**This file lives in the repository**, at
`.github/ai-prompts/session-management/conformant-prompt.md`, as of Revision 231.
It was in the workspace until then, which is `0039` F9: outside a fresh clone,
taking no revision, and invisible to every checker. **Any copy still in
`reimage-workspace/session-prompts/` is stale and should be deleted.**

## Create your session bundle first

```text
docs/sessions/<title>-<stamp>/
```

`<title>` is a short readable scope. `<stamp>` is `YYYYMMDD-HHMMSS` in
**America/New_York** — the zone is named, not left as *local time*, because you
are almost certainly on a UTC clock and *local* read as your own puts your stamp
hours ahead of a bundle created before it. The same zone governs every
`Recorded:` date. A stamp already written is evidence and is never restamped.
The name is fixed at creation — renaming it breaks every prompt, handoff and
index row written against it.

It needs, from the moment it exists: `metadata.json` carrying `state`, `prompt.md` holding this
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

**What assignment does, in order.** The owner assigns; you do not take.
**There are no tag files** — `STATUS-` and `STATE-` were removed at Revision 222
and every one of these values lives in `metadata.json`, derived and stamped by
`./bin/plan-findings-work.sh stamp`, never written by hand.

On assignment the bundle's `ownership` becomes null — owned is the absence of a
declared ownership, and the manifest is what says who — its `standing` derives to
`assigned` with every finding still `un-started` and its `progress` to `untouched`, and your session's `state`
derives to `active`. **Your first reading is the transition**: every finding
becomes `framing` and the bundle's standing derives to `analyzing`. Nothing else
moves them, and no session but the owner can perform that first read.

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

**Six of these now live in the repository.** Revision 217 installed them in
`.github/session-management-instructions.md` under an owner override, after
`0039` F9 recorded that they had accumulated *here* — in a file outside the
repository, absent from a fresh clone, taking no revision, and invisible to every
checker. **Where this section and the instruction set both state a rule, the
instruction set is the home and this is the copy.** Trimming the copies is
`0039` F9's business and is not done; until it is, read any disagreement as this
file being behind.

**Never commit, never push, never `git add` in the owner's checkout.** The owner
reviews and commits everything.

**Compose outside the checkout.** Copy the repository to session-local storage,
edit there, run the validators there, `git diff` and hand over a patch. Working
directly in the owner's tree produces a diff that cannot be committed apart from
whatever else is in flight.

**Wait to be asked before applying a patch, and then apply it yourself.**
Composing is not delivering. Show what you made; the owner says when it lands.

**"Write it" is the ask.** So are "save it", "do it" and "apply it". The session
applies the patch to the checkout, verifies by comparing trees, and reports what
landed. It does NOT hand over a list of commands and wait -- that makes the owner
the one running the apply, which is slower and puts the verification in the
wrong hands. Offer the commands only as an alternative, or when the owner asks
for them. What the session still never does is `git add`, `git commit` or
`git push`: the owner commits.

**"Add a commit message" means supply the block**, in the reply, as the message
and nothing else -- no `git commit`, no `-m`, no quoting wrapper.

**A file the owner has to open lives on the owner's machine.** Session scratch
sits inside the Linux VM, at a path that does not exist on the Mac. A patch, an
export or anything else handed over goes into a connected folder --
`reimage-workspace/patches/` for a patch -- and is named by its path there.
Handing over a VM path is handing over nothing.

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
**a rename or a deletion is a delete plus a create**. Status changes no longer
are — the tag files went at Revision 222 and a standing is now a value inside
`metadata.json`, so a status change is an ordinary diff. The grant is per folder,
for the session, and **does not survive a bridge reconnect**: if the link drops
and comes back, request it again rather than discovering it mid-apply. If it is
declined or goes unanswered, move the file into a `_to_delete/` subfolder under
the same connected folder and tell the owner — never leave two tags on one
bundle. **This remedy is now in the session management set, section 6**, as of
Revision 211; it was owed there since it was first written down here.

**And a tag change is invisible to the patch itself.** `STATUS-` and `STATE-`
files are **empty**, and `diff` emits no hunks for an empty file — it reports
`Only in …`, which is not patch content. So a patch derived from your copy
carries every prose change and **none of the tag renames**, and `git apply`
reports success having done half the work. Do the renames explicitly with `rm`
and `touch` beside the patch, and verify by comparing the two trees, never by
the patch's file list. Six tag changes crossed that way at Revision 208 and one
at Revision 210; both times the patch looked complete.

**Expect a trailing-whitespace warning and do not act on it.** The header schema
requires two trailing spaces on every line of a header block but the last, so
`git apply` warns on every conformant header you hand it. Stripping them to
silence the warning breaks the rendering the schema exists to protect.

**Take the `APPLY-MANIFEST.md` revision number at apply time**, with
`./bin/check-manifest-revision.sh` against the tree being applied to. Never while
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
**0 MISSING / 0 ANCHOR BROKEN**; the three findings checks **0 FAIL** — at
Revision 211 that is headers **928 OK**, structure **54 OK**, counts **54 OK**. A number
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

Three things they do **not** cover, so do not quote them as though they do.
**No check compares a bundle's derived status against its own finding rows** —
Revision 197 found four `resolved` bundles whose rows had never moved. **No
check covers a prose total at the foot of a `findings-manifest.md`** — at
Revision 212 one read *7 bundles · 36 findings* where its bundles held 37, and
`verify-findings-counts.sh` reported **54 OK before and after**; it checks the
per-bundle cells and the session's index counts, not the sentence beneath them.
And **no check reads the rendered page**; every one of them reads the source, which is the
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

**`verify-doc-paths.sh` never reads `docs/`, with or without `--all`.** Tested
2026-09-06 by breaking a link inside a findings bundle: neither mode reported it.
The `find` at `bin/verify-doc-paths.sh:185` prunes `./docs/*` unconditionally;
`--all` widens the **document set** from a hard-coded list of 98 to every tracked
Markdown file **except** `docs/`, `.github/ai-templates/` and `APPLY-MANIFEST.md`
— 778 paths, 1108 anchors, none of them under `docs/`.

Still pass `--all`; 778 checked beats 98. But **every link in every findings
index, every session manifest and every bundle is unverified**, and a clean run
says nothing about them. **`0044` is the first proof that this costs something**:
four session citations in `docs/cross-cutting-findings/INDEX.md` resolve to
nothing, and the majority spelling in that file is the broken one. That is `0036`, and the exclusion's stated reason —
*"gitignored working notes … they never reach a fresh clone"* — has been false
since Revision 162. Quote `MISSING` and `ANCHOR BROKEN`, never `OK`.

## What is in flight right now

Two sessions are working and both touch how the framework itself is recorded.
Read these before you record anything about statuses, schemas or the indexes.

- **`0043`** — the framework stores its own state in the format it displays it
  in. Six findings, `analyzing`, and **deliberately open**: every finding is
  `framing`, so any session may record to it and you should, rather than opening
  a near-duplicate beside it. The owner's draft JSON configs are the live work.
- **`0044`** — `unclaimed`, owned by nobody, and not to be opened until the owner
  assigns it.
- **`docs/architecture/allocation-and-inquiry.md`** — how `unclaimed` bundles get
  proposed to sessions and how a session decides what to ask next. If your work
  touches ordering, dependencies between findings, or how much you put in a
  response, read it first.

**The JSON is designed and is no longer a question.** `0043` D1 and D2 carry the
contract; `docs/architecture/state-as-data.md` carries the two schemas, the
generation map and the migration. The three *declared* bundle statuses became
`ownership` and `lineage`, leaving `progress` derived and the ladder five rows
rather than eight. **Read it before writing anything that reads a status or a
count.**

**Two more `unclaimed` bundles exist and neither is owned:** `0044`, four broken
citations inside the region `verify-doc-paths.sh` cannot see, and `0045`, a
session that owns no bundle reading `available` however much it has done. The
allocator half of `allocation-and-inquiry.md` has been run — Revision 214, with
the run and the defect it found in `docs/ledgers/allocation-evidence.md`.

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
