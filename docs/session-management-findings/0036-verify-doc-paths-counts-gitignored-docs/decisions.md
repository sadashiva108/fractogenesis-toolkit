# Decisions — `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold

**Bundle:** `0036-verify-doc-paths-counts-gitignored-docs`  
**Session:** `session-management-re-evaluation-20260906-110105` (`session_01FhFbEgG4wmrtJqUCcryNVQ`)  
**Recorded:** 2026-09-06, after measuring what scanning `docs/` finds.

This bundle has had no `decisions.md` since it was written on 2026-09-01. It was
closed by Revision 130 without one — option (i) was applied, and options (ii) and
(iii) were left open in prose. Reopening it is what surfaced that the closing
decision was never recorded anywhere a reader could find it.

## Decisions

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | Option (iv): scan `docs/`, and let a reading declare a path *proposed* so a citation to something that does not exist yet is not a broken citation | F1 | 2026-09-07 | `accepted` |

## D1 — how `docs/` is checked, if at all

**Decided 2026-09-07: option (iv).** `docs/` is scanned, and a reading may
declare a path *proposed*, so that a citation to something which does not exist
yet is not counted as a broken one.

The measurement the four options rest on is in `findings.md` and is not repeated.
What decided it: scanning finds **10 MISSING and 2 ANCHOR BROKEN** where the
pruned tree reports 0 and 0 — and of the twelve, **only the two anchors are real
defects.** Seven are paths a reading proposes; three are sentences documenting a
rename, which name an old path in order to say it is old. Option (iv) is the only
one of the four that separates those two populations instead of trading one
against the other, and under it **MISSING under `docs/` reads 2 rather than 12.**

The three options not taken are below with what each costs, kept because a
decision without its rejected alternatives is an assertion.

### (i) Keep the prune — what is in place today

`docs/` is not scanned. The OK total is stable against parked notes.

**Costs.** Ten MISSING and two ANCHOR BROKEN stay invisible, three of the ten
being genuinely stale citations and both anchors being self-references inside
architecture records. Every future one is invisible too. The exclusion's stated
reason has been false since Revision 162, so the comment at
`bin/verify-doc-paths.sh:174` would have to be rewritten to say something true —
which is the argument against, stated plainly: there is no longer a reason to
give.

### (ii) Scan `docs/` and report it as a second total

Two OK totals, one stable and one that moves.

**Costs.** More code in a lint nobody asked to grow, and two baselines quoted in
every manifest entry. It does not touch the seven false positives — they appear
under the second total every run.

### (iii) Scan everything, and stop quoting `OK` — the option open since 2026-09-01

One total, explicitly not a baseline. `MISSING` and `ANCHOR BROKEN` are the rows
that mean anything and both are already required by the conformant prompt.

**Costs.** **Seven standing false positives**, every run, forever. That is the
objection `0037` D6 made in another context and it holds here: a reader who
learns to ignore seven MISSING lines is a reader who will ignore the eighth. It
is nearly free to adopt and it makes the check less trustworthy, not more.

### (iv) Scan `docs/`, and let a reading say a path is proposed — **accepted**

The option the measurement points at, and the only one that separates the two
defects instead of trading them.

A path a reading *proposes* is not a broken citation. Two shapes:

- **A marker in the document** — `` `bin/verify-index-tables.sh` (proposed) `` —
  which the checker skips. Explicit, costs a convention, and every existing
  instance has to be marked.
- **The checker demotes MISSING to WARN inside `docs/*-findings/` and
  `docs/ideas/`**, where proposing is the point, and leaves MISSING as MISSING
  everywhere else under `docs/`. No new convention, no retrofit, and it is wrong
  in exactly one direction: a genuinely stale citation inside a findings bundle
  reads as WARN rather than MISSING.

Under either shape, **MISSING under `docs/` today would be 3, not 10**, and all
three are in one file.

**Costs.** Real work in the checker rather than a flag, and the second shape
guesses from a directory name what the first shape states outright.

### What is not in scope here

The three stale citations and the two broken anchors are corrections, not
findings, and they belong to whoever owns those files. `0041` finding 3's
question — whether a bundle whose fix is a lint belongs in this tree — reaches
this bundle too, and is not answered here.

### The shape, left to whoever implements it

Two shapes are set out above and **neither is chosen here**, because they differ
only in cost and the cost is not knowable until the checker is written. The
marker is explicit and needs every existing instance marked; the directory rule
needs no retrofit and infers from a path what the marker would state. **The
owner's own artifact volume already uses a `.proposed` suffix** on files under
`extra-secrets-certs-review/`, which is the same idea one layer down — a marker
saying *this is a proposal* — and is prior art for the vocabulary if not for the
placement.

**Two things the implementation owes, from the same measurement.**

The **three rename-documenting citations** are not proposals and not defects. A
sentence that names an old path *in order to say it is old* is the record working
correctly, which is the reason `APPLY-MANIFEST.md` is excluded and is stated in
`bin/verify-doc-paths.sh` itself as the first of the two reasons `docs/` was
pruned. **That first reason is true and survives this decision.** Only the
second — *gitignored working notes that never reach a fresh clone* — is false,
and has been since Revision 162. The comment says both and must be corrected to
say one.

And the **two real anchors** should be repaired in the same revision, since they
are what the change exists to surface:
`docs/architecture/restore-docker-teardown-and-test.md` points at
`[[#What to add to restore-docker.md]]` where its own heading carries backticks,
and `docs/architecture/time-machine-run-index.md` points at
`[[#9. Open decisions]]` where the heading was renamed to *9. Decisions — both
settled*.

**F1 is `decided`. The change to `bin/verify-doc-paths.sh` is a toolkit write,
now permitted, and is deliberately not made in the same revision as the
decision** — it moves a baseline every manifest entry quotes, and that belongs in
its own reviewable change.
