# Findings owned — `phase-11b-hydrate-and-bookends-20260903-141500`

Authoritative record of the findings bundles this session owns.
`docs/sessions/INDEX.md` carries the count and points here rather than restating
the list. Each bundle's own index row names this session in return.

Statuses are defined in [`docs/legend.md`](../../legend.md).

| # | Bundle | Kind | Subject | Findings | Status |
|---:|---|---|---|---:|---|
| 0006 | [`0006-caller-environment-precedence-covers-only-listed-keys`](../../cross-cutting-findings/0006-caller-environment-precedence-covers-only-listed-keys/) | cross-cutting | Caller-environment precedence holds only for the keys `artifact-config.sh` lists | 1 | `resolved` |
| 0020 | [`0020-repo-audit-tsv-column-shift`](../../runbook-findings/restore-repos/0020-repo-audit-tsv-column-shift/) | runbook | `repos.tsv` remote column is shifted by embedded tabs | 1 | `resolved` |

## Where these came from

All seven were recorded by this same session under two earlier briefs, and were
listed in the manifests of the bundles those briefs produced — `0006`, `0008`,
`0011`, `0016`, `0017` and `0020` under `restore-repos-refactor-20260902-000000`,
`0015` under `restore-repos-clone-plan-20260902-000000`. The owner merged them
here on 2026-09-03, and on the same day the two closed bundles were absorbed into
this one — their documents are the `prompt-`, `metadata-` and `brief-summary-`
files beside this manifest.

Ownership had followed the brief a finding was recorded under. That rule fails
when a session outlives its briefs, which this one did: both of those bundles are
correctly `closed` — their briefs finished — and five of the seven findings are
still `unresolved`. A closed bundle cannot work a finding, so the findings sat
against an owner that had, by its own state, stopped. Ownership follows the
session that can still act, and for these seven that is this bundle.

Nothing about the findings themselves changed. Each bundle's `**Found:**` line
still names `session_019yzcjm2QneJ5ymVEQDi1bu`, which is the same session in all
three cases — that is what made the merge a consolidation rather than a transfer.

The two closed manifests are now pointers here and list nothing, so a finding is
listed under exactly one owner.

## Recorded but not owned

`0027-findings-architecture-conformance` was recorded by this session in
Revision 167, at the owner's request and with the explicit instruction not to
address it. Recording a finding and owning one are different acts: recording is
the reading, owning is a commitment to work it. The owner assigns ownership and
has not assigned this one — `0027`'s index row reads `—` and that is correct.

## At closing, 2026-09-03

This session is `closed`. Its two `resolved` findings — `0006` and `0020` — stay
listed above; a resolved finding needs nobody.

The five `unresolved` ones — `0008`, `0011`, `0015`, `0016`, `0017` — were
**unowned** by the owner at closing and their INDEX rows read `—`. A closed bundle
has, by its own state, stopped, and leaving an open finding under one is the defect
Revision 175 removed from the two `restore-repos` bundles. They are unassigned, not
abandoned. They remain in the table above because this session found and held them,
and the table is the record of that.


**2026-09-06 — five bundles disowned.** This session is `closed`; `0008`, `0011`,
`0015`, `0016` and `0017` were never resolved and a closed session may not leave a
finding owned by a session that has stopped. They are `unclaimed` and wait for the
owner to assign them. `0006` and `0020` are `resolved` and stay listed here.