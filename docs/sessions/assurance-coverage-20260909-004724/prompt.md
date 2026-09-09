# Prompt — assurance-coverage

## The conformant half

Opened against the session management set as it stood at **Revision 237**.
Section 0 of `.github/session-management-instructions.md` is the working cycle
and it is not optional: compose in a scratch tree, verify there, produce a patch,
report a review, wait, and apply only on *write it and provide a commit message*.
The owner commits and pushes. This session does not `git add`, commit or push in
the checkout.

## The session half

**You are the assurance session.** You own `0040`, `0041`, `0042`, `0044`,
`0046`, `0049` — 6 bundles, 21 findings.

Your bundles are one question in six costumes:

> **What is the assurance layer responsible for seeing?**

Every finding you hold is the same event. A check ran. It passed. It was not
looking at the thing that was wrong.

| | In the finding's own words |
|---|---|
| `0041/F2` | the check that runs gives the wrong assurance |
| `0041/F4` | a patch containing a deletion under-applies silently, and every check passes |
| `0042/F2` | three consecutive revisions shipped a rendering defect that all six checkers passed |
| `0046/F2` | the path resolves, so nothing looks broken |
| `0049/F4` | nothing would have noticed |

**Do not treat these as six gaps to plug.** A list of missing checks is what this
repository already produces, and it is why the list keeps growing.

Your jobs, in order. The order is the graph's, not the owner's:

1. **`0049` first, and F2 before F1** — F2 blocks F1: the rule cannot be followed
   until the artifact it names is defined. **Check before you design**: Revision
   232 added a patch definition to `.github/session-management-instructions.md`
   section 6 and a PreToolUse guard, so part of `0049` may already be overtaken.
   Say which part, with the revision, rather than assuming either way.
2. **The coverage question — `0044`, `0046` and `0041/F2` together.**
   `0041/F2 co-decides 0044/F1`: both ask what `verify-doc-paths.sh` is
   responsible for covering, and one answer settles both. `0046/F2 constrains
   0044/F2`. Answer the coverage question once; do not answer it three times.
3. **`0042` with `0041/F1`** — co-decided: a checker that reads only the source
   and a required shape nothing checks are one problem. `0042/F3 blocks 0042/F1`:
   a rendering check needs a markdown parser the repository does not have. That
   is a real dependency decision — python3 is already a dependency via
   `prepare-artifact-root.py`, and the portability floor is **macOS stock Bash
   3.2 and BSD userland**. Decide it explicitly.
4. **`0040` last** — supersession when the owning session is gone. It touches
   `0046/F1` and is otherwise the loose end of the set.

## The live instance you are handed

Revision 236 fixed three defects in `docs/legend.md` that six checkers had passed
for ten revisions. `verify-doc-currency.sh` should have caught the third — a
decision in `state-as-data.md` contradicting `legend.md`. **The edge exists.** The
`state-schema` watch is `critical`, its source is `state-as-data.md`, and
`legend.md` is among its dependents, asserted at Revision 232 — the same revision
that took the contradicting decision.

**It has never fired and it cannot.** Every watch carries `"sourceDigest": null`,
and `doc_currency.py:evaluate()` tests the null before it compares, so a watch
with no baseline reports `UNCONFIRMED` and can never reach `DRIFTED`. `--confirm`
is the only thing that writes a digest, it is `manual` on every critical watch,
and no revision has run it. `cmd_check` also returns 1 for any critical watch
that is not `current` — which since Revision 232 has meant *not armed* — so the
tool has exited non-zero on every run it has ever had, while
`bin/verify-doc-currency.sh` line 11 promises *"Exits non-zero when a `critical`
watch has drifted."*

**The instrument is right about the tree and has never been in a position to say
so.** `0047` F5 reads the family pattern as *the half that reads the tree is
wrong, not the half that judges it*; this one fits neither half, and that gap is
yours. Arming it is one command and was deliberately not run — the decision is
yours to shape, not to inherit.

**Do not implement.** Building a check is a doing bundle and those do not exist
yet; `docs/architecture/typed-bundles-and-work.md` is the draft that would create
them, and it belongs to `typed-bundles-architecture-20260909-004724`.

## What is not yours

`0037`, `0038`, `0045`, `0047`, `0048` belong to
`typed-bundles-architecture-20260909-004724`. Two `relates-to` edges cross
to them. `relates-to` carries no dispatch constraint, so you are not blocked, and
you do not read or write those bundles.

**`0039` is open to any session and the architecture session is writing to it
right now.** Do not record there. Put anything that belongs in `0039` into your
report and let the owner place it.

## One standing warning about your own subject

**Every check this repository has shipped failed against a healthy tree on its
first run** — `0041`'s lint at 36, `0042` F4's audit at 131 of which 128 were its
own, the completeness check at 18 false positives, the one-way guard, the drift
sweep at 65 of 77, and now a currency checker that has exited non-zero on every
run it has had. That is six. **Whatever you propose, propose the false positive
it will produce first.**
