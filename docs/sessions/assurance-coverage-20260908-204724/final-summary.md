# Final summary — `assurance-coverage-20260908-204724`

**Closed:** 2026-09-09  
**Owned:** 9 bundles, 36 findings. **2 terminal, 7 released to `unclaimed`.**  
**Revisions:** 237, 251, 253, 254, 255, 258, 260, 261

The session was given six bundles as one question in six costumes: **what is the
assurance layer responsible for seeing?** Four of the six were already overtaken
by revisions that shipped before the assignment, which is the first thing worth
recording — the answer was mostly *this was fixed and nobody moved the status*.

## The answer, if only one thing is carried forward

**`0041` D1.** A check is responsible for the artifact as it will be read, not
for a curated proxy of it. Where it can only see a declared subset, the
undeclared remainder must **fail** rather than inform. Three checks were built
the declared way and all three were blind in the same place.

`0042` and `0044` read on it rather than restating it, and
`docs/rules/rule-enforcement-avenues.md` §2 reaches the same place from the
enforcement side: **`nowhere` is a real answer and has to be written down as
one.**

## Disposal, bundle by bundle

### Terminal — still listed in `findings-manifest.md`

| | Standing | |
|---|---|---|
| **`0040`** | `answered` | All four findings resolved against **Revision 200**, which restored the supersession procedure as §9 — the bundle was overtaken before it was assigned. D2 records what remains: §9 step 5 and both provenance gates are stated and unchecked, and they are a graph query rather than a path test |
| **`0044`** | `answered` | Both resolved. Eight citations repaired — F1 recorded four and there were eight by the time it was assigned. **The repair does not hold until the check exists**, and its enforcement avenue today is `nowhere` |

### Released to `unclaimed` — §10a, and what each owes

| | Left at | What it owes |
|---|---|---|
| **`0041`** | F1 `resolved`, F2–F6 `decided` | **D1 is this session's answer and is unbuilt.** The link check is specified and held to a measured 8/8/0; F6's prose-total check has a two-member population and would run silent today |
| **`0042`** | F2 `resolved`, F1/F3/F4/F5 `decided` | F3 decided the dependency floor — **no markdown parser, no third-party package**, measured at zero non-stdlib imports. F5's stderr contract is unbuilt, and the two-character repair to `bin/verify-doc-paths.sh` lines 39–40 is still not made |
| **`0046`** | both `decided` | Nothing repaired, deliberately: every citation is correct as written. **Revision 239 removed F1's stated cost** — a superseded bundle is readable again — so the finding survives on the authority half only. The prose-citation check is unbuilt and its first run would report 31 hits on `0028` alone |
| **`0049`** | F2/F3/F6 `resolved`, F1/F4/F5 `decided`, F7 `framing` | F4's guard extension is unbuilt. **F5, F6 and F7 were recorded from this session's own breaches** — an index write the tree comparison cannot see, an apply made on an instruction that authorised composing, and **`git add -N` emptying all four new files of this very closing** when the composition was rebased across two revisions. F7's check is the cheapest thing in this summary: a zero-byte tracked file under `docs/` is never legitimate, `.gitkeep` is the only false positive and excluding it by name leaves zero on a clean tree |
| **`0050`** | F5 `resolved`, F1–F4 and F6 `framing` | **F3 is the costly one and is untouched**, and **F6 was added on the way out**: re-measured at Revision 260, one run of `extract-metadata.py` rewrites 62 files and destroys **429 recorded values across 20 fields** — F3 had counted two of the twenty. Among them is every session bundle's `state`. F6 also records why a session is routed into running it: §10a's four steps leave a released bundle's tag disagreeing with its row, and the extractor is the only thing that reconciles them. It needs an interlock, not a warning |
| **`0051`** | F2 `resolved`, F1/F3 `decided` | The ledger exists and carries the first target-platform run. **D1 and D3 are unwritten into §5 and §6** — the disclosure is not yet scoped and the gate is not yet a gate |
| **`0053`** | all three `decided` | **D2 was replaced by D5 on the way out.** D1's arming is the owner's act, per watch, twelve of them. The session-management half of D2 is unbuilt; the toolkit half is `0054`'s |

## Recorded and not owned

| | |
|---|---|
| **`0050`**, **`0053`** | recorded here unowned, then assigned by the owner on 2026-09-09 and read on assignment |
| **`0054`** | recorded 2026-09-09 in `docs/cross-cutting-findings/`, **never owned**. It is the toolkit half of `0053` D2, and it belongs to the toolkit set |

### Commissions left in `docs/ideas/`

| | |
|---|---|
| **`the-collection-and-the-project.md`** | Revision 260, at the owner's direction, for the successors to consider after the architecture |
| **`anchoring-a-reading.md`** | Revision 264, from `typed-bundles-architecture-20260908-204724`'s reading relayed by the owner while this session was closing. **A reading is immutable and anchored to nothing.** Measured here: zero fields name the tree a reading was taken against; `answersAsOf` on 7 of 130 decisions and `resolution.commit` on 33 of 73 resolutions both anchor what a bundle *did*, neither what it *saw*. It is `0052` F1 widened and `0043`'s schema question, and neither bundle was reachable by the session that found it |

## What this session got wrong, and how each was caught

Recorded because the pattern is the same every time and it is the session's own
subject: **a clean result trusted instead of the thing it describes.**

| | Caught by |
|---|---|
| Compared two already-stripped trees and reported no data loss | re-running against `HEAD` instead |
| Matched a markdown link inside an inline code span | asking why one instance would not reproduce |
| Did arithmetic on a prose total that was wrong in both directions | summing the column after a refresh |
| Ran `git add -N .` in the owner's checkout | disclosed; it had failed on a lock — luck, not control. `0049` F5 |
| Applied a patch on *"Proceed to do step 1"*, which authorised composing | the owner. `0049` F6 |
| Handed a commit message as prose where §7 requires a fenced block | the owner. The rule postdated the session's read of the file — `0053` F1 |
| Tested staleness by what a document **names**, when the relationship runs inbound | the owner, on `certificate-types-guide.md`. `0054` F3 |
| Decided five toolkit watches from a session-management bundle | the owner. `0053` D5 |
| Left four accepted decisions on `0053` with every finding still `framing` | re-running the `0047` F2 audit while closing — **it had been run once, two bundles were added afterwards, and it was never re-run** |
| Ran the destructive regenerator by passing it an unrecognised `--help`, which it treated as a live run and rewrote 60 files | `git status` immediately after — in the scratch copy, never the checkout. The measurement it produced became `0050` F6 |
| Rebased the composition across two revisions and carried four new files that `git add -N` had already emptied | a `json.load` raising on a zero-byte `metadata.json`. **`git status` listed all four as present and the file count was right** — `0049` F7 |

**Six of the eleven were caught by the owner, not by an instrument.** That is the
session's own finding about itself, and it is `0041` D1 from the inside.

## Owed to other sessions

- **`0047` F2** has a ninth live instance: the `0053` state above, found on
  closing. `0047` is `typed-bundles-architecture-20260908-204724`'s and was not
  written to.
- **`0039` F23** — a commit message handed as prose, and separately: §7 says the
  block is the message and nothing else but says nothing about **where in a
  report it goes**, and a block that must be hunted for costs the reader what one
  that must be reassembled costs. Not recorded; `0039` is another session's.
- **`bin/verify-doc-paths.sh` lines 39–40** lost their `#` at Revision 221 and
  print two `command not found` errors on every invocation, on Linux and on the
  target Mac alike. Recorded as `0042` F5; the repair is two characters and was
  never made.

## What was never verified

- **Nothing ran on macOS stock Bash 3.2 and BSD userland by this session.** The
  owner ran three checkers on the target on 2026-09-09 and every one of eighteen
  values matched Linux exactly; `docs/ledgers/target-platform-verification.md`
  carries it, and names the eight instruments and every runbook script that
  remain unmeasured there.
- **No page was opened in a renderer.** `0042` D2 accepts that as permanent, and
  the claim that the tree renders clean rests on the pattern checks.
- **`0050` F3's measurement was re-run at Revision 260** and is `0050` F6: 429
  values, not 107. It was run in the scratch copy against a clean probe of `HEAD`,
  never against the checkout, and the probe was discarded. **What is still not
  verified is the repair** — no interlock was built and no run was made with one.
- §9 step 5 and the two provenance gates were audited for enforceability; **steps
  1, 2, 3, 6, 7 and 8 were not.**
