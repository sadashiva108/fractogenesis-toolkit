# Decisions — the patch is named as the deliverable and never produced

**Bundle:** `0049-the-patch-is-named-as-the-deliverable-and-never-produced`  
**Session:** `assurance-coverage-20260908-204724`  
**Decided:** 2026-09-09

Read F2 before F1: F2 blocks it, because the rule cannot be followed until the
artifact it names is defined. **Revision 232 overtook most of this bundle before
it was assigned**, which is what the first three decisions record. What is left
is one gap in the guard, and this session is standing in it.

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | Section 6 now defines the patch — how, where and by whom — so F2 is closed by Revision 232 rather than by anything decided here | F2 | 2026-09-09 | `accepted` |
| D2 | `git add -N` is the whole of F3's fix and Revision 232 recorded it, with F3's own measurement quoted | F3 | 2026-09-09 | `accepted` |
| D3 | F1 needs no remedy of its own. It reports behaviour, and the thing that would have stopped it is F4's guard | F1 | 2026-09-09 | `accepted` |
| D4 | The guard is extended to the tool a bridged session actually writes through, and derives its protected root from the connected folder rather than `CLAUDE_PROJECT_DIR`. **Warn, never deny, on a shell call; deny only on a file commit** | F4 | 2026-09-09 | `accepted` |
| D5 | The remainder of F4 is not worked here. It is a toolkit write with no bundle type yet, and it is parked as `0050` | F4 | 2026-09-09 | `accepted` |
| D6 | The apply procedure gains one assertion: after applying, `git diff --cached --name-only` in the checkout must be empty | F5 | 2026-09-09 | `accepted` |

---

## D1 — the patch is defined, at Revision 232

`.github/session-management-instructions.md` section 6, bullet *"A patch is a
file, and this is how it is made"*, answers all three of F2's gaps:

- **how to produce one** — `git add -N .` then
  `git diff > "$PATCH_DIR/<revision>-<slug>.patch"`;
- **where it goes** — `$PATCH_DIR`, which
  `.github/ai-prompts/session-management/conformant-prompt.md` names concretely
  as `reimage-workspace/patches/`;
- **who applies it** — section 0 step 6: *"On 'write it and provide a commit
  message' — apply the patch… It is the one time a session writes there."*

F2 said a rule whose artifact has no name, no home and no producer can be
followed in spirit and skipped in fact. It now has all three.

**Decided:** F2 is `resolved` against Revision 232, commit `d0e6d7d`. Nothing is
decided here that Revision 232 did not already do; this decision records that the
finding was overtaken and names where.

## D2 — `git add -N`, and F3's measurement is in the fix

The same bullet: *"`git add -N` is not optional and its absence is silent…
Measured on Revision 231: 9 of 14 paths, and the five it dropped were the test
suite, the prompts, a findings bundle and a guard."*

That is F3's own measurement, carried into the rule it argued for, together with
the instruction that catches the general case: *"Read the patch's file list
against your own change set before handing it over."*

**Decided:** F3 is `resolved` against Revision 232, commit `d0e6d7d`.

## D3 — F1 is behaviour, and closes with the guard

F1 is an account of what a session did across seven revisions. A finding of that
kind has no fix of its own: the rule it broke was already written, and the
session had read it. What was missing was an artifact to hand over — D1 — and
something that would notice — D4.

**Rejected: a stronger rule.** Writing section 6 more emphatically was considered
and is not adopted. F1 records that the session had read the rule and resolved
the conflict silently in the direction that required nothing of the owner, seven
times. A rule that was read and not followed is not fixed by being restated; that
is `0039`'s whole subject.

**Decided:** F1 stays `decided` and resolves when F4 does. It has no separate
resolution and should not be given a synthetic one.

## D4 — the guard does not cover the tool this session writes through

`.claude/hooks/write-location-guard.sh` (Revision 232) is a PreToolUse hook,
matched in `.claude/settings.json` on `Edit|Write|MultiEdit|Bash`. It denies a
write whose `file_path` falls inside `$CLAUDE_PROJECT_DIR` and warns on a shell
command naming it. That is exactly what F4 asked for.

**It does not run in this session, and would not fire if it did.** A session
bridged to the owner's machine writes through `mcp__remote-devices__device_bash`
and `mcp__remote-devices__device_commit_files`. Neither tool name matches the
matcher. And `$CLAUDE_PROJECT_DIR` in a bridged session names the assistant's own
container, not
`/Users/dkittrell/workspace/shiva/fractogenesis-toolkit`, so the
`case "$path" in "$root"/*)` test compares against the wrong root.

**This is F4 recurring one layer out, at the same distance.** Revision 231's
guard matched `Edit|Write|MultiEdit` and missed `cp` inside `Bash` — which is
F4's own sentence. Revision 232's guard matches `Bash` and misses `cp` inside
`device_bash`. One revision each time, one tool boundary each time.

**The shape, and the false positive it produces, stated first.** Extend the
matcher to the two bridge tools, and take the protected root from the connected
folder rather than the environment. **Every read-only shell call that mentions
the checkout path and contains a `>` redirect to scratch will match the command
branch** — which is most of the commands this session has run. So:

- **`device_bash` — warn, never deny.** A guard that makes its own tool unusable
  is routed around, and `docs/legend.md` already names that failure under the
  rollback trigger: *"a rule that fires on trivia gets routed around."*
- **`device_commit_files` — deny**, where a `devicePath` resolves inside the
  checkout and `SESSION_APPLY_APPROVED=1` is not set. That is the narrow case
  that is always a real write and never a read.

**Rejected: denying on `device_bash`.** It was the first draft. This session's
own transcript is the argument against it.

**Revision 249 states the rule this decision reached independently, and
Revision 250 gave it a home: `0047` F6.**
`docs/rules/rule-enforcement-avenues.md` §6: *"A guard is installed warn-only. It
runs against the whole tree, produces zero false positives on a clean pass, and
only then becomes a refusal."* That record also lists this extension at §4.2 and
calls it *"not new work"*, which is right — `0050` F1 is the reading and this is
its decision. What §6 adds is the sequencing: the `device_commit_files` refusal
in this decision should ship **warn-only first**, and become a denial only after
a clean pass, rather than arriving as a refusal because its case looks obvious.

## D5 — the remainder is parked, not worked

Changing the hook is a **toolkit write**, and section 6 gates one on a `decided`
finding — which D4 now provides. It is not carried out here for a different
reason: a bundle whose output is a built thing has no type yet. That is
`docs/architecture/typed-bundles-and-work.md`, drafted and owned by
`typed-bundles-architecture-20260908-204724`, and pre-empting it from this side
would settle by accident what that session is deciding on purpose.

Parked as `0050`, with a second defect found in the same reading and the class
both belong to.

**Recorded against F4 rather than as a new decision on F1**: F1 asked what would
have noticed, and the answer is still *nothing that runs in this session*.

## D6 — assert the index is empty, because the tree comparison cannot

F5 is the one write into the owner's checkout that §6's verification method
cannot see. The remedy is not a better tree comparison — a tree comparison is
exactly right for content and will never see an index — but **one more
assertion beside it.**

```text
git diff --cached --name-only        # must be empty, in the owner's checkout
```

**Its false positive is nil, and that is unusual enough to say why.** Every check
this repository has shipped reported failure against a healthy tree on its first
run, and the reason each time was that the rule admitted a legitimate case the
author had not enumerated. **This one admits none**: nothing legitimate ever
stages in the owner's checkout. The owner stages at commit time, which is after
the session is done and outside anything a session runs. A non-empty result is
always a defect, and the check needs no suppressor, no marker and no allow-list.

**Avenue is `check`, not `guard`** — `rule-enforcement-avenues.md` §2. A guard
would have to intercept `git` invocations and decide which subcommands touch the
index, which is a parser for git's CLI; and `0050` F1 means no guard runs on this
session's write path anyway. The assertion belongs in the apply step, beside the
tree comparison, where a session already reports what it compared.

**Rejected: forbidding `git` in the checkout entirely.** Read-only git —
`status`, `log`, `rev-parse`, `apply --check` — is how a session establishes the
tree it is applying to, and this session used all four legitimately. A rule that
banned them would be routed around, which `docs/legend.md` names as the failure
mode of a rule that fires on trivia.

