# The rules, by type and by home

> **DRAFT — Revision 273.** Written before the genus rename landed, so it still
> says `findings[]` where the schema now says `members[]`, and *finding* where
> the vocabulary now says *member*. **Its measurements and its findings about the
> code are current and were taken against the tree**; its vocabulary is not.
> [vocabulary.md](vocabulary.md) is authoritative where the two disagree.

> **Role.** The map of the rule set: what kinds of rule this framework has, which
> document is authoritative for each kind, and what happens when two documents
> answer the same question differently. It is authoritative for **nothing but the
> map** — every rule named below is named only closely enough to be recognised,
> and the link beside it is where it actually lives.
>
> **This file must not become a second copy.** The framework's whole failure mode
> is a rule restated somewhere nothing checks; a map that quotes its territory is
> that failure with a table of contents. Where a sentence here reads like a rule,
> it is a label — go to the home.
>
> **Every count below was measured** on 2026-09-09 in a scratch copy at `6ddb823`
> plus this session's uncommitted work, with `APPLY-MANIFEST.md` at **Revision
> 269**. Re-measure; do not quote these forward.
>
> **Rank 4** of 6 — a convenience, like a prompt. The order is in
> [`../.github/copilot-instructions.md`](../.github/copilot-instructions.md) and
> nowhere else.

## Contents

- [1. The six ranks](#1-the-six-ranks)
- [2. The layers](#2-the-layers)
- [3. Rules by type](#3-rules-by-type)
- [4. Where a rule is allowed to live](#4-where-a-rule-is-allowed-to-live)
- [5. Rules with no home](#5-rules-with-no-home)
- [6. Rules whose homes disagree](#6-rules-whose-homes-disagree)
- [7. Enforceable, and merely conventional](#7-enforceable-and-merely-conventional)
- [8. Reading order for someone arriving cold](#8-reading-order-for-someone-arriving-cold)

---

## 1. The six ranks

The precedence order is stated **once**, in
[`.github/copilot-instructions.md`](../.github/copilot-instructions.md), in a
six-row table. Nothing else states it and nothing else may. This section says
what the ranks are *for*; the table itself says what each one is.

| Rank | What sits there | What kind of authority that is |
|---:|---|---|
| 1 | `metadata.json`, `.internal/ai-scripts/session-management/plan_findings_work.py` | the thing itself, not a description of it |
| 2 | an `accepted` decision in a bundle's `decisions.md` | a judgement already taken, which a document may not yet have caught up with |
| 3 | `docs/legend.md`; `.github/session-management-instructions.md`; `.github/toolkit-instructions.md` | the rule documents, coequal **in their own domains** |
| 4 | `.github/ai-prompts/**`, `.github/guides/**`, `.claude/CLAUDE.md`, `docs/rules/README.md` | copies for convenience |
| 5 | `docs/architecture/**` | reasoning. Cited, not obeyed |
| 6 | `APPLY-MANIFEST.md` | evidence of what was true when written. **Never** a current rule |

**What wins.** Highest rank. A document disagreeing with something above it is a
**defect, not a rule** — the router says so in one sentence, and the obligation
is to record it rather than follow it.

**Rank 3 is coequal, not tied.** The three documents do not overlap, so a genuine
rank-3 disagreement is a boundary error — and section 6 has three live ones.
**Rank 2 is the one people forget:** an `accepted` decision outranks every
document that has not yet been edited to match it. Section 6 turns on that.

**Twelve documents declare a rank in a masthead** — 3 at rank 3, 9 at rank 4. The
router declares none, correctly: it is where the ranks are stated. Two
rule-bearing sets declare none and should —
[`rule-enforcement-avenues.md`](rules/rule-enforcement-avenues.md), which has no
masthead at all, and the ten files under `docs/architecture/`.

---

## 2. The layers

Four distinct questions, four homes. Almost every misfiled rule in section 5 is a
rule that answered one question and was written into the home of another.

### What a word MEANS — `docs/legend.md`

[`docs/legend.md`](legend.md) (554 lines) is the vocabulary and **only** the
vocabulary: every finding status, bundle standing, session state, supporting
discriminator, edge kind and term of art. Its masthead disclaims permission,
procedure and current values explicitly.

It is **project-agnostic by rule** — it forbids itself an example that only makes
sense in one project, because the next project inherits the file.

### WHEN something is allowed, and in what order — `.github/session-management-instructions.md`

[`.github/session-management-instructions.md`](../.github/session-management-instructions.md)
(979 lines) is the procedure: the working cycle, permission, the write
categories' gating, superseding, transferring, releasing, resolving, the schemas,
the manifest. It is authoritative for *when* and *in what order*, and it points
at the legend for every meaning.

The split between the two is `0039` D2, carried out by D13. Before it the legend
held both and §6 pointed back at it for the gating, so **the two files agreed
with each other and both disagreed with the decision**.

### The PROJECT's own conventions — `.github/toolkit-instructions.md`

[`.github/toolkit-instructions.md`](../.github/toolkit-instructions.md) (73
lines) owns the reimaging workflow: runbooks, scripts, the artifact volume, the
lints, the naming and portability conventions. It says nothing about sessions;
the session management set says nothing about reimaging. The two are disjoint,
and neither is above the other.

### Convenience, and copies — the prompts and the front door

Nine documents at rank 4. Three shapes:

| | | |
|---|---|---|
| a **pointer** | [`.claude/CLAUDE.md`](../.claude/CLAUDE.md), [`.github/ai-prompts/README.md`](../.github/ai-prompts/README.md) | authoritative for nothing; names where things are |
| a **copy** | [`conformant-prompt.md`](../.github/ai-prompts/session-management/conformant-prompt.md) (630 lines), [`session-management-prompt.md`](../.github/ai-prompts/session-management/session-management-prompt.md) (248), [`script-types-and-locations.md`](../.github/guides/script-types-and-locations.md) (244) | restates rules so they can be pasted or read in place. **Never wins a disagreement** |
| an **inventory or a door** | [`what-a-session-is-given.md`](../.github/ai-prompts/session-management/what-a-session-is-given.md) (102), [`docs/rules/README.md`](rules/README.md) (196) | authoritative for one narrow thing each; pointing everywhere else |

Two of these declare how stale they are.
[`conformant-prompt.md`](../.github/ai-prompts/session-management/conformant-prompt.md)
says *current as of Revision 221*; the manifest head is **269**, so it is 48
revisions behind and says to treat any disagreement as its own defect.
[`session-management-prompt.md`](../.github/ai-prompts/session-management/session-management-prompt.md)
says 238, thirty-one behind.

**Two documents are authoritative for exactly one section each.**
[`docs/rules/README.md`](rules/README.md) is authoritative only for *What nothing
else tells you* (§6) — everywhere else it points, and where it disagrees with what
it points at, the other wins.
[`what-a-session-is-given.md`](../.github/ai-prompts/session-management/what-a-session-is-given.md)
is authoritative for the *inventory* of what a session receives and for nothing
in the contents of anything it lists.

---

## 3. Rules by type

Six types. The type predicts the home, and a rule filed against its type is
almost always filed correctly.

| Type | Answers | Home | Example, named not restated |
|---|---|---|---|
| **vocabulary** | what does this word mean | [`docs/legend.md`](legend.md) | what `framing` is; what `answered` is; what an `evidences` edge asserts |
| **permission** | who may do this, and to what | [`docs/legend.md`](legend.md) *Who may write to a findings bundle*; [instruction set §4](../.github/session-management-instructions.md) | *only the owning session opens a finding*; *`resolved` is frozen* |
| **ordering** | what must happen before what | [instruction set §0, §9, §9a, §9b, §10, §10a](../.github/session-management-instructions.md) | the working cycle's seven steps; the five steps of a transfer |
| **write-gating** | may this write happen at all | [instruction set §6](../.github/session-management-instructions.md) | *a record write is never gated*; *a toolkit write is gated on a `decided` finding*; *an evidence write is granted per run* |
| **schema** | what shape must this file have | [instruction set §11](../.github/session-management-instructions.md); `plan_findings_work.py` for the data | the header block's one-field-one-line-and-a-hard-break rule; the closed outcome set |
| **convention only** | how we do it here | [`.github/toolkit-instructions.md`](../.github/toolkit-instructions.md) | verb-first filenames; Bash 3.2 portability; run from the repository root |

**Three observations that matter more than the table.** The **write categories
are split by design** — what each write *is* lives in the legend, *when each is
allowed* lives in §6, and the halves must not drift back together (`0039` D2,
D13). **Permission and vocabulary share a page and are not the same type**: the
legend carries permission tables because permission is expressed in the
vocabulary's words, which is exactly how `0039` F21's defect got in — a table of
bundle standings carrying two finding statuses. And **a convention is not a weak
rule**; it is one whose answer would differ in another project. Section 4 is the
test.

---

## 4. Where a rule is allowed to live

One question decides it, and the router states it:

> **Would this still be true in a project that did something else entirely?**

**Yes** — it belongs in the session management set or the legend. Sessions,
findings, statuses, who may write and when, how a change reaches the owner: the
same everywhere.

**No** — it belongs in the toolkit set. Phases, runbooks, the artifact volume,
recorders, lints, Bash 3.2.

The router gives the discriminating case: *a defect in `bin/reindex-artifact-runs.sh`
is the toolkit's; a defect in the rule that says when a session may edit it is
session management.*

**Three secondary tests, each of which has already caught something.**

1. **Is it a meaning or a permission?** If a session could obey it without
   knowing what any word means, it is procedure. `0039` F6 is what the wrong
   answer costs: state names in one file, state requirements in another, each
   correct and neither sufficient.
2. **Would a fresh clone contain it?** `0039` F9 is the class where the answer is
   no. A rule outside the repository takes no revision, appears in no manifest
   entry, and is invisible to every checker that self-locates.
3. **Is anything told to read it?** `0039` F5: *nothing says `docs/legend.md` is
   normative* — five rules ended up somewhere sessions were not told to look.

**And the rule about copies.** A fact has one home; a copy is permitted only
where it is generated, or where a check fails when it drifts. Its home is
[instruction set §8](../.github/session-management-instructions.md); section 6
records that two scripts and the toolkit set cite a different address for it.

---

## 5. Rules with no home

**`0039` F9 owns this class** — *six rules live outside the repository entirely* —
and `0039` F21 is the standing warning that **nothing checks whether a rule
reached the prose**. Both stand `framing`.

F9's own six have since landed: all six now sit in the instruction set at §5, §6,
§8 and §11, and the prompt that held them is in the repository as of Revision
231. **The class did not close with them.** Ten more, measured today.

| # | The rule, named only | Where it is stated today | Where it belongs |
|---:|---|---|---|
| 1 | **A findings bundle exists before the session that owns it; a session cannot create its own** | [`docs/rules/README.md` §5](rules/README.md) — which says in the same paragraph *this paragraph is the only place that says so* | instruction set §5, which gives the layout and never says who creates it or when |
| 2 | **The owner's gate is the commit; in the legend's permission tables *the owner* means the owning session** | [`docs/rules/README.md` §6](rules/README.md) | the legend, where the ambiguous word is |
| 3 | **Never quote an `OK` total as a signal of health** | [`docs/rules/README.md` §6](rules/README.md), and `0036` | instruction set §8, beside *know what each check does not examine* |
| 4 | **Read the tree before you write the finding** — check what a finding claims against the tree as it stands | [`docs/rules/README.md` §6](rules/README.md) | instruction set §8 |
| 5 | **Run the checks in your scratch copy, never in the owner's checkout**, because `git` takes a lock the mount cannot clean up | [`docs/rules/README.md` §6](rules/README.md) | instruction set §0 or §6 |
| 6 | **Take the bundle number immediately before writing**, not while composing | [`docs/rules/README.md` §6](rules/README.md). §7 says it for the *revision* number only | instruction set §7, or §3 |
| 7 | **Reading the owner's checkout without leaving a lock** — `git --no-optional-locks status --porcelain`, or copy the checkout and run git in the copy | `APPLY-MANIFEST.md` Revisions 268 and 269 **only**, both saying it belongs in §0 and both declining to put it there | instruction set §0 step 6. `0038`'s to decide |
| 8 | **A guard is installed warn-only** — clean pass on the whole tree before it becomes a refusal | [`rule-enforcement-avenues.md` §6](rules/rule-enforcement-avenues.md), a document whose own header says *nothing here is decided* | undecided. §9 there names `0047` as the vehicle and records that it is not written |
| 9 | **Keep the scratch copy at one stable path; refresh it before deriving any patch** | [`conformant-prompt.md`](../.github/ai-prompts/session-management/conformant-prompt.md) *The rules you will break if nobody tells you* | instruction set §6, beside *a copy in session-local storage dies with the session* |
| 10 | **`prompt.md` tracks** — refresh the copy in the session directory when the prompt changes, and say which revision it holds | [`conformant-prompt.md`](../.github/ai-prompts/session-management/conformant-prompt.md) | instruction set §5, which requires `prompt.md` and says nothing about keeping it current |

**Two more that are stated nowhere at all**, found by looking for the statement
and not finding it:

- **A file the owner has to open lives on the owner's machine.** Session scratch
  is inside a Linux VM at a path that does not exist on the Mac; a patch goes to
  a connected folder and is named by its path there. The rule is in the
  conformant prompt; the instruction set names `PATCH_DIR` twice and never says
  the handover path must be one the owner can open.
- **Artifact naming, timestamping, retention and pointer policy are runbook-level
  decisions, and options are presented before any is changed.** In the conformant
  prompt. The toolkit set's nearest sentence forbids altering them without a
  request, which is a narrower rule.

**What the pattern is.** Nine of the twelve are in a rank-4 document. That is F9
restated with a better address: the overflow no longer leaves the repository, it
collects in the copies — the one place a session may still write, because a
toolkit write is gated on a `decided` finding and the findings that would carry
these are all `framing`. **The gate is working, and this is its exhaust.**

---

## 6. Rules whose homes disagree

Six. Each names both sides and which rank settles it.

### 6.1 Does a read move a status, or does a write?

**The live one, and the largest.**

| Side | Says | Rank |
|---|---|---|
| [`docs/legend.md`](legend.md) line 199 | *Reading is the transition; nothing else moves them* | 3 |
| [instruction set §10](../.github/session-management-instructions.md) line 680 | *The transfer ends when the target session reads the bundle* | 3 |
| [`conformant-prompt.md`](../.github/ai-prompts/session-management/conformant-prompt.md) *What assignment does* | *Your first reading is the transition … Nothing else moves them* | 4 |
| [`docs/legend.md`](legend.md) lines 69 and 546 | *A status does not move because someone read the finding*; *a status moves on a write, not a read* | 3 |
| **`0039` D24**, `accepted` 2026-09-09 | a status moves on a **material change to the record**, and a read is not one | **2** |

**Rank 2 wins: the write.** D24 states in terms that line 199 goes and §10's
sentence goes with it, and **neither edit has been made** — D24 does not carry
itself out, because those paragraphs are what `0039` D23 rewrites. So one rank-3
document contradicts itself in three places, a second rank-3 document sides with
the minority, and a rank-4 copy repeats the minority. `0045` F3 supplies the
second leg: *the target read it* is unverifiable by construction, *the target
wrote to it* is a diff.

### 6.2 Is a `retired` bundle readable?

[`docs/legend.md`](legend.md) *What another session may do* puts `retired` — every
finding `withdrawn` — under **nothing is readable**, and its third row ends
`withdrawn` — not readable. The same file's *A finding* makes a `withdrawn`
finding readable by any session. **Both sides are rank 3 and in one file.**
Revision 239 declined to decide it in a repair and left the two cells standing;
`0039` F21 owns the question. **Nothing settles it today.**

### 6.3 Where does the one-fact-one-home rule live?

| Side | Says |
|---|---|
| [instruction set §8](../.github/session-management-instructions.md) line 459 | states the rule. Rank 3 |
| [`.github/toolkit-instructions.md`](../.github/toolkit-instructions.md) line 37, and `.internal/ai-scripts/session-management/verify-findings-counts.sh` line 17 and `verify-findings-structure.sh` line 16 | cite **`.github/copilot-instructions.md` section 4b** as its home |

**§8 wins**; the citation is the defect. `.github/copilot-instructions.md` is 73
lines with five headings and **no numbered sections at all** — section 4b was
deleted with §§4b–4d at commit `1c48deb`, and `0039` D13 re-ruled the address.
Two instruments and a rank-3 document cite a section that does not exist, and
nothing fails.

### 6.4 Who creates the session directory?

[`docs/rules/README.md` §5](rules/README.md) (rank 4): *whoever opens the work
creates the bundle first; the person pastes the prompts second.*
[`conformant-prompt.md`](../.github/ai-prompts/session-management/conformant-prompt.md)
(rank 4) instructs the session to create its own directory first.
[`docs/legend.md`](legend.md) (rank 3) says both — that a session *creates its
own bundle*, and later that the directory is created when the repository owner
opens a new chat and pastes the instruction set and prompt.

**Rank 3 wins and contradicts itself**, so nothing settles it. The README's claim
to be *the only place that says so* is false in the direction that matters: the
legend says the opposite twice.

### 6.5 Which helper takes the manifest revision number?

[instruction set §7](../.github/session-management-instructions.md) (rank 3):
`./bin/verify-session-findings.sh manifest-revision`.
[`conformant-prompt.md`](../.github/ai-prompts/session-management/conformant-prompt.md)
(rank 4) and [`rule-enforcement-avenues.md` §4.1](rules/rule-enforcement-avenues.md):
`./bin/check-manifest-revision.sh`.

**§7 wins, and the tree agrees**: `bin/check-manifest-revision.sh` **does not
exist**. It moved; the copies did not follow. Six documents still name it.

### 6.6 Where do the repository-wide script conventions live?

[`.github/guides/script-types-and-locations.md`](../.github/guides/script-types-and-locations.md)
disagrees **with itself**: its masthead names
[`.github/toolkit-instructions.md`](../.github/toolkit-instructions.md) as the
home, its opening paragraph names `.github/copilot-instructions.md`.
[`.claude/CLAUDE.md`](../.claude/CLAUDE.md) makes the same error, describing the
router as carrying *build/lint commands, architecture, conventions, and the
loader/entrypoint/helper rules* — which is a description of the toolkit set.

**The toolkit set wins**; the router is authoritative for routing and precedence
and explicitly not for the rules. Both offenders are rank 4.

---

## 7. Enforceable, and merely conventional

Four avenues, and the fourth is a real answer:
[`docs/rules/rule-enforcement-avenues.md` §2](rules/rule-enforcement-avenues.md)
names them — **guard**, **check**, **person**, **nowhere** — and argues that a
rule with no avenue is not thereby unimportant; saying so is what stops it being
quoted as enforced.

**What is actually held today.** Three guards in `.claude/hooks/`, wired by
`.claude/settings.json`: `write-location-guard.sh` on `PreToolUse`, and
`runbook-guard.sh` and `session-guard.sh` on `PostToolUse`. **Only the first can
refuse anything** — the other two run after the edit and exit 0 by construction,
reporting a rule as context. Each was installed after a rule was broken, which is
the pattern that document exists to stop.

**The central permissions cannot be enforced at all.** `0045` F3:

> a session cannot describe **who it is** to any instrument at all.

Every load-bearing permission is keyed on session identity — *only the owning
session opens a finding*, *from `decided` onward only the owner records*,
*`resolved` is frozen*, *a transfer clears on the target's first write as owner*.
A guard sees a tool call and a path; a checker sees the tree; **neither sees a
session.** There is no identifier in the environment to trust, and the scratch
path is a convention rather than a declaration.

So a check written against *who may* would assert something it cannot see and
**pass vacuously** — `0039` F15 records that exact failure in a different check.

**Why the difference is not admitted often enough.** Three reasons, all
documented:

1. **The rules are written in the same voice.** *Only the owning session opens a
   finding* and *every line but the last ends with two spaces* read identically
   on the page. One a script checks; the other nothing can.
2. **A vacuous pass looks like health.** `0045` F3's stated cost is not that the
   permissions are broken but that they are *described as rules and quoted as
   though something holds them*.
3. **Nothing checks the prose.** `0039` F21 measured it: with the pre-repair
   legend restored over the repaired file, every check returns byte-identical
   output. **The repair moves no number.** So a rule that never reached its home
   costs nothing until someone opens the file cold — which at F21's five
   revisions happened every time, late, and by a session other than the writer.

The honest statement, and it is `rule-enforcement-avenues.md` §5.1's:
**the framework's central permission is unenforceable, and the argument is not
for adding an identity mechanism but for not writing checks that pretend
otherwise.** Whether that is a defect to fix or a property to document is
`0045`'s to take, and nothing has taken it.

---

## 8. Reading order for someone arriving cold

The front door is [`docs/rules/README.md`](rules/README.md) and it carries its own
four-step order with line counts. This is the order for someone whose question is
specifically *where does a rule live*.

| # | Read | Lines | For |
|---:|---|---:|---|
| 1 | [`.github/copilot-instructions.md`](../.github/copilot-instructions.md) | 73 | the six ranks, and the *would this still be true elsewhere* test. Stated once, here |
| 2 | [`docs/rules/README.md`](rules/README.md) §6 | 196 | *What nothing else tells you* — the only section it is authoritative for, and the shortest route to the rules that have no other home |
| 3 | [`docs/legend.md`](legend.md) | 554 | what every word means. **Not guessable** |
| 4 | [`.github/session-management-instructions.md`](../.github/session-management-instructions.md) §0 | 979 | the working cycle. Then the rest, in order |
| 5 | this file, sections 5 and 6 | — | what is missing and what disagrees, before you trust a sentence you find in a copy |
| 6 | [`.github/toolkit-instructions.md`](../.github/toolkit-instructions.md) | 73 | only if the work touches the reimaging workflow |

**Then, and only then, a prompt.** Both declare a revision they are current as of
and both are behind the manifest head. Read them as copies: where one disagrees
with a home, the home wins and the copy is the defect. **A rank-4 document is not
a lesser rule — it is a restatement**, which means the thing it restates can move
without it. Nine of the twelve homeless rules in section 5 sit in one, and five
of the six disagreements in section 6 involve one.

## Provenance

**This file states where things are. Why each is where it is lives in the bundle
that decided it.**

| Part | Where the reasoning lives |
|---|---|
| The six ranks | `.github/copilot-instructions.md`, which states them and is the only place that may |
| Meaning versus procedure | `0039` D2, carried out by D13 |
| The write categories, and `foreign` | `0039` D13 and D19 |
| That `docs/rules/` exists at all | `0039` D22, and `rule-enforcement-avenues.md` §10.1, which names it as an open question rather than a settled one |
| Rules with no home | `0039` F9 owns the class; F1 and F5 are its ancestors, F6 its smallest instance |
| That nothing checks whether a rule reached the prose | `0039` F21 |
| A read does not move a status | `0039` F26 and D24, `accepted` at Revision 269 and **not yet carried out** |
| Permissions are conventions | `0045` F3; `docs/rules/rule-enforcement-avenues.md` §5.1 |

<!-- historical: bin/check-manifest-revision.sh -->
<!-- The path above is cited by this document as a CLAIM MADE ELSEWHERE that
     does not resolve -- section 6 records it as a disagreement. `verify-doc-paths.sh`
     has no marker for "a path this document is reporting as broken", so
     `historical` is used: it is the marker that means do not repair this, and
     repairing it here would delete the finding. The missing marker is itself a
     small gap in the checker and is recorded rather than worked around silently. -->
