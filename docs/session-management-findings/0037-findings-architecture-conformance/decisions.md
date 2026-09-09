# Decisions — the findings-and-sessions architecture disagrees with itself

**Bundle:** `0037-findings-architecture-conformance`  
**Session:** `typed-bundles-architecture-20260908-204724`  
**Decided:** 2026-09-09

**This bundle had no `decisions.md` until now, and that is not an oversight.** Its
predecessor `0027` decided all seven findings and resolved them at commit
`88aed77`; Revision 224 removed the cloned copies from this bundle because they
were byte-identical to `0027`'s and headed with `0027`'s name, which is the clean
slate `0039` D12 requires. What the clone could not carry was that **`1c48deb`
then dropped the rules those resolutions had installed.** The three decisions
below are taken against the tree as it stands, not against `0027`'s.

## Decisions

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | The required-reading rule survives its home being deleted: it is restated in `.github/session-management-instructions.md` and binds every `prompt.md` written from now. **Existing prompts are evidence and are not rewritten** | F2 | 2026-09-09 | `accepted` |
| D2 | The migrated-bundle carve-out is restored: a bundle migrated from an already-closed record carries `resolutions.md` and no `decisions.md`, and its `resolutions.md` says so. **One decision answers this bundle's F5 and `0047` F4**, which are the same reading in two bundles | F5 | 2026-09-09 | `accepted` |
| D3 | F1, F3, F4, F6 and F7 were resolved in `0027`, regressed by `1c48deb`, and hold again against the files that replaced it. Each is resolved here against where its rule now lives, and the regression is named rather than smoothed over | F1, F3, F4, F6, F7 | 2026-09-09 | `accepted` |

## D1 — the required-reading rule survives, forward only

`0027` D2 scoped the rule to prompts that can still start a session and gave
`run-index-design` a reading order. `1c48deb` deleted §4d, so the rule has no
home and nine prompts now name the instruction set at lines 44, 37, 37, 25, 12
and 6.

**Rejected — let the rule die with §4d.** Defensible, and it nearly won: Revision
241 gave both prompts a table of contents, which does the same job better than a
mandatory first item. It loses the property the rule exists for, which is that a
session cannot begin without being told where the rules are.

**Rejected — retrofit all nine prompts.** Five belong to sessions that are
`closed` or `handoff`. A closed session's prompt records what that session was
told, and rewriting it is what §9 spends three prohibitions preventing.

**Not decided here**: where in the instruction set it lands, and whether the
table of contents Revision 241 added satisfies it. That is the carrying out.

## D2 — the carve-out is restored, and it answers two bundles

The sentence `1c48deb` dropped read:

```text
A bundle MIGRATED from an already-closed record carries `resolutions.md` and no
`decisions.md`, because the deciding happened before this lifecycle existed; its
`resolutions.md` says so.
```

Ten bundles are in that class today and read as non-conforming against a rule
nobody intends.

**Rejected — write `decisions.md` into the ten.** It would invent deliberation
that never happened, which is the evidence rule broken in the direction of
tidiness. `0047` F4 reaches the same conclusion independently.

**Rejected — leave it undecided.** It is the reason ten bundles fail a rule by
accident, and it has been undecided since Revision 203.

**The owner's standing preference is the opposite of this decision and is
recorded deliberately.** Retrofitting older evidence to match the current shape
is preferred wherever it is possible; here it is not, because the missing
document records deliberation that did not occur. **What is owed instead is a
migration plan requirement for breaking changes**, so that the next format change
states what happens to what predates it. Parked as `0052` F2.

**Edge asserted**: `0037/F5 co-decides 0047/F4`.

## D3 — resolved once, regressed, and resolved again

Five findings hold again, each against a different file from the one `0027`
closed them in. The regression is one commit — `1c48deb`, which split
`.github/copilot-instructions.md` and dropped fifteen rules with no decision
recording the removal, `0039` being the bundle for that.

**Rejected — reopen instead of resolve.** `reopened` reaches only what is
`resolved`, and these read `framing`: the clean slate put them there. The
vocabulary has no move for *resolved by a predecessor, regressed, and true
again*, and inventing one for five rows is not worth it.

**Rejected — resolve with `—` in `Resolved by`.** The citation would resolve to
nothing and §11 requires every `D<n>` cited to exist in this bundle. This
decision exists so the five rows can cite something real.

**What this decision does not claim**: that the regression was detected. It was
not. Nothing re-verifies a resolution once written, and that is parked as `0052`
F1.
