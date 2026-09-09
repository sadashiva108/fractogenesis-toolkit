# Prompt — typed-bundles-architecture

## The conformant half

Opened against the session management set as it stood at **Revision 236**.
Section 0 of `.github/session-management-instructions.md` is the working cycle
and it is not optional: compose in a scratch tree, verify there, produce a patch,
report a review, wait, and apply only on *write it and provide a commit message*.
The owner commits and pushes. This session does not `git add`, commit or push in
the checkout.

## The session half

**You are the architecture session.** You own `0037`, `0038`, `0045`, `0047`,
`0048` — 5 bundles, 23 findings.

You carry `docs/architecture/typed-bundles-and-work.md`, **a DRAFT, not a design
to be built.** Sections 2 and 3 are firm; argue with the rest.

The model as it stands:

```
findings   — a reading of something that EXISTS. Research belongs here.
             Items F1..Fn. Terminates at `answered`.
commission — an INTENT TO BUILD. Produces a blueprint under docs/architecture/.
             Items Q1..Qn. Terminates at `answered`.
doing      — implement / refactor / retrofit / bugfix / verify. The kind IS
             the type. Items are tasks, T1..Tn.

A doing bundle is dispatchable only when every bundle it `serves` is `decided`.
An answer may be followed by nothing, by a doing bundle, or by another
reasoning bundle it `evidences`. The graph is directed, not a pipeline.
```

Your jobs, in order:

1. `docs/legend.md` is owed a finding: **a finding may record a fact
   established, not only a defect**, and *what it costs to leave* is severity's
   business. `0037` is where it belongs. Record it before designing past it.
2. `0045` and `0048` against section 4.6 — the session/agent boundary is only as
   good as what a session record can say about itself. **This session bundle is
   itself a live instance of `0045` F1**: it was created `available`, owning
   nothing, and the vocabulary had no way to say *assigned and not yet started*.
3. Open question 6.4: **nothing checks that breadth was preserved**, and section
   3 makes that the load-bearing property of the whole design.
4. `metadata.json` shapes for `commission` and a doing bundle, against
   `docs/architecture/state-as-data.md`.

**Do not implement.** Building is a doing bundle and those do not exist yet.

## What is not yours

`0040`, `0041`, `0042`, `0044`, `0046`, `0049` belong to
`assurance-coverage-20260908-204724`. Two `relates-to` edges cross to
them — `0049/F1 -> 0038/F1` and `0044/F1 -> 0047/F3`. `relates-to` carries no
dispatch constraint, so you are not blocked, and you do not read or write those
bundles. Route anything you need through the owner.

`0039` is open to any session and **the assurance session is told not to write
there while you are.** F21 and F22 are yours to place.
