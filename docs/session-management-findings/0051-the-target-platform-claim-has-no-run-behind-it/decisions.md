# Decisions — the target-platform claim has no run behind it

**Bundle:** `0051-the-target-platform-claim-has-no-run-behind-it`  
**Session:** `assurance-coverage-20260908-204724`  
**Decided:** 2026-09-09

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | The disclosure is scoped: `metadata.md` always records the environment, and a report carries the untested-on-target sentence **only when the change set contains a `bin/` or `.internal/` executable** | F1 | 2026-09-09 | `accepted` |
| D2 | A target-platform run is recorded in `docs/ledgers/target-platform-verification.md`: date, commit, platform, shell version, what was run and every value, beside the same run on the session platform | F2 | 2026-09-09 | `accepted` |
| D3 | A finding whose scope includes an executable may not go `resolved` until a target-platform run is recorded for it. **A record write owes nothing** | F3 | 2026-09-09 | `accepted` |

---

## D1 — say it where it can bite, and nowhere else

The environment line in `metadata.md` stays exactly as it is. It is a fact about
the session, §5 requires it, and it is right.

**What changes is the report.** The untested-on-target sentence is owed when the
change set contains a `bin/` or `.internal/` executable, and is not owed
otherwise. The patch that carries this bundle touches only `docs/`; no script
runs differently because of it, and saying *nothing ran on macOS* there is true
and inert.

**Rejected: dropping it entirely.** It is load-bearing exactly when a script
changes, which is when somebody needs to see it.

**Rejected: keeping it unconditional.** That is the status quo, and the status
quo is why the owner asked. A sentence that appears whether or not it applies
carries no information, and a reader who has skipped it twenty times will skip
the twenty-first.

**Not decided here: the wording.** §5's environment requirement and the report
convention live in `.github/session-management-instructions.md`, which is a
**toolkit write** under `docs/legend.md`'s categories — `.github/` is not under
`docs/`. §6 gates one on a `decided` finding, which F1 now is. The edit is
specified and not made here, for the same reason `0044` D3 and `0040` D2 leave
theirs: the bundle type for work whose output is a built thing is
`docs/architecture/typed-bundles-and-work.md`, and it is another session's.

## D2 — the run gets a home, and the home is a ledger

**Carried out.** `docs/ledgers/target-platform-verification.md` exists as of this
bundle and carries the 2026-09-09 run as its first row.

A ledger rather than a field on a resolution, for three reasons. A run covers
**several** scripts at once, so it is not a property of one finding. It is
**dated evidence**, which is what `docs/ledgers/` is for and what
`docs/INDEX.md` says it holds. And a resolution's `Revision` and `Commit` are
already the two fields §11 gives it; adding a third that is usually empty would
put a placeholder in a record, which the placeholder rule forbids.

**What the ledger must carry, and why each:** the **commit**, because a run
against an unnamed tree proves nothing; the **platform and shell version**,
because *"tested on the Mac"* and *"tested under 3.2.57"* are different claims;
**every value**, not a verdict, because a verdict cannot be compared against a
later run; and **the same run on the session platform beside it**, because the
question is never *did it pass* but *did it differ*.

**The first row already earns the file.** Eighteen values, macOS Bash 3.2.57
against Linux Bash 5.1.16, zero divergence — and `0042` F5 reproducing on the
target, which moves that finding from inferred to confirmed. None of that had
anywhere to live an hour ago.

## D3 — a gate, not a disclaimer

**A record write owes nothing.** Gating it would be absurd: no script changed, so
there is nothing a platform could disagree about.

**A finding whose `Scope:` includes an executable may not go `resolved` until a
target run is recorded for it.** That is the same move §9b already makes for the
resolutions row — write the evidence, then move the status — applied to the one
claim the row cannot make.

**Rejected: gating the toolkit write itself.** Requiring a target run before the
write would mean the owner running a script that does not exist yet. The write
happens on Linux like everything else; the **status** is what waits.

**Rejected: requiring it for every finding.** Most findings here are about
documents. `0051` would then owe a macOS run for its own resolution, which is the
rule eating itself.

**What this costs, stated plainly.** It puts a step on the owner's desk that
nobody else can perform — §5.1 of `docs/rules/rule-enforcement-avenues.md` is
exact that a guard cannot see who is writing, and here the actor is not a session
at all. **Its avenue is `person`**, deliberately, and D1's scoping is what keeps
that from being asked for on work that does not need it.

**The check it implies, and its false positive.** A checker could compare each
`resolved` finding whose `Scope:` names `bin/` or `.internal/` against the ledger
and report the ones with no row. **Its first run reports every such finding in
the tree**, because the ledger starts today and every prior resolution predates
it — the retrofit trap, and the largest first-run false-positive count any
instrument here would produce. So the rule is **forward-only from Revision 251**,
and the checker, if built, takes the ledger's own start date as its floor.
