# Decisions — no check reads the rendered page

**Bundle:** `0042-no-check-reads-the-rendered-page`  
**Session:** `assurance-coverage-20260908-204724`  
**Decided:** 2026-09-09

F3 blocks F1 and is decided first: it is a dependency question, and the finding
was recorded rather than fixed precisely because the owner had not been asked.

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | **No markdown parser and no third-party package.** The dependency floor is Python 3 standard library plus POSIX shell, and it is now stated rather than assumed | F3 | 2026-09-09 | `accepted` |
| D2 | F1 is answered by narrowing the surface, not by building a renderer. *"No check reads the rendered page"* is accepted as a permanent property | F1 | 2026-09-09 | `accepted` |
| D3 | F2 is overtaken. All three defects were in the header block, and all three constructs are checked | F2 | 2026-09-09 | `accepted` |
| D4 | F4: commit the audit's **rule list**, not the audit. The seventh property becomes a named unchecked gap | F4 | 2026-09-09 | `accepted` |
| D5 | A checker's own output is an artifact nothing examines. The suite asserts that each checker is silent on stderr against a declared allow-list of one | F5 | 2026-09-09 | `accepted` |

---

## D1 — the floor is the standard library, and python3 was never the question

F3 frames the cost as *"a markdown parser, which is a dependency the repository
does not have"*, and reasons from the Bash 3.2 portability floor. **The framing is
wrong on python3 and right on the thing underneath it.**

`python3` is already load-bearing. **Seventeen shell scripts invoke it**, among
them `bin/backup-repos.sh`, `bin/reimage-checklist.sh` and
`bin/capture-system-inventory.sh` — entrypoints that run on the target Mac during
a reimage. `bin/verify-doc-currency.sh` exits 2 without it. A rule that treats
python3 as an unpaid cost is a rule the repository broke long ago and depends on.

What the repository genuinely does not have is a **third-party package**.
Measured across every `.py` file in the tree on 2026-09-09, the complete import
set is: `__future__ argparse collections csv dataclasses datetime difflib
filecmp fnmatch hashlib json os pathlib re shlex shutil subprocess sys typing`.
**Zero non-stdlib imports.** That is a clean line, it is checkable by the same
`grep` that produced it, and a CommonMark parser crosses it.

**So the floor is stated: Python 3 standard library and POSIX shell, with Bash
3.2 and BSD userland for anything written in shell.** F3's option (i) is
rejected, and option (ii) — run if a parser is present, skip if not — is rejected
with it, for F3's own reason: a check that silently does nothing is worse than no
check, and `0050` F1 and F2 are two live instances of exactly that.

**Two measurements argue this rather than taste.** F2's evidence is that the
pattern approach worked: option (iv) was taken at Revisions 202 and 203 and is
enforced today. F4's evidence is that the parser approach's own first run
reported **131 failures of which 128 were bugs in the audit** — a 98%
false-positive rate, the worst first run in a repository whose standing warning
is that six checks in a row failed against a healthy tree.

**And a rendering check would have caught none of this session's findings.** The
unarmed watch, the link extractor, the dead exemption, the blind guard and the
destructive extractor are all source-level. Every one of them renders perfectly.

## D2 — narrow the surface, and stop the prompt overstating the gap

F1 is true and stays true: every checker reads the source. **Accepted as a
permanent property rather than a gap awaiting a fix.** What replaces the missing
check is the constraint set — forbid the constructs whose rendering is
renderer-dependent, and check for those — which exists and holds.

One thing does change. `.github/ai-prompts/session-management/conformant-prompt.md`
says *"no check reads the rendered page… it is why the instruction to open the
page yourself is an instruction rather than a check"*, and stops there. A session
reads that as *nothing in this area is covered*, when three named constructs are.
**The instruction is for constructs nobody has met yet**, and the prompt should
say which three are already caught so a reader can tell the two apart.

**Not carried out here.** Editing the conformant prompt is a record write and
would be in scope, but the sentence sits inside the paragraph `0042` F1 and
`0036` share, and `0044` D1's repair has already touched the neighbouring claim.
Left for the owner to place in one edit rather than two sessions editing one
paragraph — section 6, *one file, one owner*.

**This decision is `accepted`, not `deferred`.** It could be `deferred` on the
argument that the rendering surface may grow and a parser may pay later. It is
not, because `deferred` requires naming what it waits on, and the honest answer
is *a construct that is not one of the three* — which is a thing nobody can
schedule. If one appears, this is `reopened` with `new-information`, which is the
door built for it.

## D3 — F2 is overtaken

All three defects F2 tabulates were in the header block:

| Revision | Defect | Now checked by |
|---|---|---|
| 201 | five header fields joined into one paragraph | the two-space rule, `verify-findings-headers.sh` |
| 202 | schema example fenced by four-space indentation | the fence rule, same script |
| 203 | the same example fenced and tagged `markdown` | `grep -q '^\`\`\`markdown$'`, same script |

Built across Revisions 202 and 203, commits `b5a78e5` and `74e5790`. Tree state
on 2026-09-09: **0 fences tagged `markdown`**, and the header block carries
**1015 assertions**.

`0041` F1 is co-decided with F1 of this bundle and lands the same way: the shape
that had no check has one, and what survives is D1 of `0041` — the general
property, not either instance.

## D4 — commit the rule list, not the audit

F4 is right that the assurance is unreproducible and right that it matters. The
remedy is not to commit the parser.

**The audit's value was its seven properties, not its implementation.** Six are
pattern-checkable and are checked. The seventh — *no literal markdown surviving
into rendered prose* — is not, and cannot be without the parser D1 rejects.

**So it becomes a named gap rather than a silent one**, in the conformant
prompt's *what the checks do not cover* paragraph, beside the two already there.
That paragraph is this repository's one honest inventory of its own blind spots,
and a gap listed there has a different character from a gap nobody wrote down:
`0044` F1 exists because `0036` put one there.

**Rejected: committing the audit under `bin/`.** It would install a script that
needs a package the repository does not carry, whose first run was 98% wrong, to
close a gap `0050` F1 and F2 show is more often caused by instruments that exist
and cannot fire than by instruments that are missing.

## D5 — the checker's own output is the artifact nobody reads

F5 is D2's argument with an instance: F1 says no check reads what a document
renders as, and this is the same blindness one layer up, where **no check reads
what a check emits.**

**The repair is two characters** — restore the `#` on lines 39 and 40 of
`bin/verify-doc-paths.sh`. **It is not carried out here.** That is a toolkit
write, in the same script `0044` D3 leaves alone for the same reason: the bundle
type for work whose output is a built thing is
`docs/architecture/typed-bundles-and-work.md`, and it is another session's. The
finding is `decided`, which satisfies section 6's gate whenever that session or
the owner takes it.

### The check, and its first-run false positive, measured

**Assert that each checker writes nothing to stderr on a healthy tree**, as a
contract in `bin/test-session-management.sh` rather than as a seventh checker —
the suite already runs, already fails loudly, and a checker that checks checkers
would need something behind it in turn.

Measured on the clean tree at Revision 238, commit `52a4376`, capturing stderr
only across all eleven instruments in `bin/`:

| | instruments | stderr lines |
|---|---:|---|
| silent | **9** | 0 |
| `bin/verify-doc-paths.sh` | 1 | **2 — the real defect** |
| `bin/test-session-management.sh` | 1 | 60 — `unittest` writes its progress to stderr **by design** |

**Two raise, one is real, one is a false positive**, and the suppressor is a
declared allow-list of exactly one name rather than a pattern. A pattern would be
the mistake `0041` D1 records: a rule admitted on a shape rather than on an
instance.

**Not claimed: that stderr silence is the right invariant on an unhealthy tree.**
A checker that meets a genuinely broken tree may have something to say on stderr
and should. The contract is *silent on a tree where every check passes*, which is
the state the suite already constructs for itself.

**Rejected: making it a seventh checker in `bin/`.** It would be an instrument
whose own output nothing reads, which is the finding.

`docs/rules/rule-enforcement-avenues.md` §2 puts this at **check** rather than
guard, and §6 gives the reason a contract in the suite is the right home: a
checker that is wrong wastes an hour, a guard that is wrong stops the work. This
one has no write to intercept in any case — a checker's output exists only after
the checker has run.

