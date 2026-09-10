# Instrument firing

**What this is.** For every instrument in this repository, the two facts that
decide whether it protects anything: **is it reached**, and **can it fire**. Each
entry is a dated measurement against a named commit.

**Why it exists.** `iris/verifications.md` answers *what does each instrument
examine and what does it not*, and it answers it well. It does not answer *does
this one run, and can it ever say no* — and that is the question `0050` is about.
A survey states a design; this states a state of the world, and the two go stale
at different rates. **The prompt that opened this session asked for the answer to
exist as a record rather than only as a survey**, and this is that record.

**Two questions, not one, and they fail independently.**

| | |
|---|---|
| **Reached** | is the instrument invoked by something a session runs without being told to? |
| **Firable** | on some input, can it produce an adverse verdict at all? |

**An instrument that fails either protects nothing, and they look identical in
every report** — silence. That is `0050`'s whole subject: *"a check that passes
because it never ran is indistinguishable in every report from a check that ran
and found nothing."*

**Never a verdict, always a value.** A verdict cannot be compared against a later
run.

**Who runs it.** Any session, in its own copy. Nothing here touches the owner's
checkout.

---

## 2026-09-10 — commit `853179d`, Revision 296

**Method.** *Reached* is measured three ways: membership of
`bin/verify-session-findings.sh`'s dispatch table, membership of the `all` group
it runs by default, and `grep` for an executing caller across every `*.sh`,
`*.json` and `*.yml` in the tree. *Firable* is measured by running the instrument
and reading its exit status and its output, not by reading its source.
**Measured in a Linux VM under Bash 5.1.16 and GNU coreutils, not the macOS Bash
3.2 target.**

### The table

| Instrument | Reached | Firable | Measured |
|---|---|---|---|
| `… counts` | **yes** — in `all` | **yes** | FAIL 0. Fired twice tonight on the session that built its newest section |
| `… headers` | **yes** — in `all` | **yes** | FAIL 11, the standing baseline in `0030` and `0035` |
| `… structure` | **yes** — in `all` | **yes** | FAIL 0 |
| `… completeness` | **yes** — in `all` | **yes** | 0 problems. Fired tonight on a `—` written where `null` belongs |
| `… manifest-revision` | **partly** — in the dispatch table, **excluded from `all`**, group `report` | **no** — a report; always exits 0 | Reports 297. Its one warning about a number taken in the log prints **on stderr under `--verbose` only** |
| `bin/verify-manifest-coverage.sh` | **NO** — not in the table, not in `all`, **no executing caller anywhere in the tree** | **yes**, and correctly | MISSING 0, ORPHANED 6, DUPLICATE 1 against a baseline of 0/3/1 |
| `bin/plan-findings-work.sh check` | **no** — standalone | **NO** — prints and returns; `main()` never calls `sys.exit` for it | **18 conformance rows, exit 0.** Anything gating on it passes |
| `bin/plan-findings-work.sh stamp` | **no** — standalone | n/a — a writer, not a check | `--dry-run` would write 0 records |
| `bin/verify-doc-currency.sh` | **no** — standalone | **NO for its own subject** | 7 watches, **0 armed**: every `sourceDigest` is `null`, so `evaluate()` returns `UNCONFIRMED` and `DRIFTED` is unreachable. Exit 1 only because four are `critical` |
| `bin/verify-doc-paths.sh` | **no** — standalone | **yes** | 0 MISSING, 0 DECAYED, exit 0 — **and two `command not found` errors on every invocation**, unread since Revision 221 |
| `bin/verify-runbook-structure.sh` | **no** — standalone | **yes** | 213 PASS / 25 FAIL, a standing baseline |
| `bin/verify-script-portability.sh` | **no** — standalone | **yes** | CLEAN 91, WARN 0, FAIL 0 — **a reading of source, never a run on the target** |
| `bin/test-session-management.sh` | **no** — standalone, **no caller** | **yes**, against fixtures | 69 tests, all passing. It never reads `docs/` |
| `bin/review-changes.sh` | **no** — standalone, **no caller** | n/a — a reading aid | Runs `git add -N .` |
| `check-metadata-completeness.py` | **yes** — `check-completeness.sh` `exec`s it | **yes** | **Its own file as of Revision 299.** It was `extract-metadata.py --check`, one argv token from a half that destroyed 740 values; that half is deleted and this one writes nothing |
| `.claude/hooks/write-location-guard.sh` | **NO for this session** | **yes** in principle | Matches `Edit\|Write\|MultiEdit\|Bash`; `.claude/settings.json` names `remote-devices` **0 times**. Has never evaluated a write from a bridged session |
| `.claude/hooks/session-guard.sh` | conditionally | **NO** — `PostToolUse`; its own header says it always exits 0 | 0 notes on 473 tracked files |
| `.claude/hooks/runbook-guard.sh` | conditionally | **NO** — same | 0 notes on 473 tracked files |
| the `STATUS-superseded` exemption in `… headers` | reached | **NO** | Guards on `[ ! -f "$dir/STATUS-superseded" ]`; **0 such files exist**, so the condition is always true — `0050` F2 |

### What the table says

**Four instruments run without being asked.** `counts`, `headers`, `structure`
and `completeness` — that is the whole of `all`, and it is the whole of what a
session gets for free. Every other row is reached only by a session that already
knows to reach for it.

**Six cannot produce an adverse verdict at all.** `manifest-revision` by design;
`plan-findings-work.sh check` because `main()` never exits on it; every
`doc-currency` watch because none is armed; both `PostToolUse` annotators by
construction and by their own headers; and the `STATUS-superseded` exemption
because its subject was deleted at Revision 222.

**One is correct, fires, and is reached by nothing.** `verify-manifest-coverage.sh`
is `0050` F8, and tonight is its evidence: across five commits `MISSING` went
0 → 2 → 0 and `ORPHANED` 3 → 6, and **not one of those movements appeared in any
check a session runs.** The four instruments in `all` held their baselines exactly
throughout.

**The four in `all` all fired tonight, on the session running them.** `counts`
twice, on drift introduced by the session that had just written the section
catching it; `completeness` once, on a `—` written into a JSON field where `null`
belongs. **That is the shape of a working instrument** — it catches its author,
not only strangers — and it is what the six above cannot do to anybody.

### The counter-example, and it is the cheapest pass in the ledger

**An instrument that never ran, against a proposal tested on its own author and
withdrawn before shipping.** `drift-and-the-write-boundary-20260909-053548`
proposed *every bundle named in a commit message must be touched by that commit*,
ran it against the commit that proposed it, and it raised that commit — a message
may legitimately cite a bundle it does not change, so the rule cannot separate an
assertion from a citation. It was withdrawn.

**The withdrawal cost one run, because the case was to hand.** §6 requires a
guard be shown *to fire on a case it should catch*, and the cheapest possible form
of that is to run it on the change that proposes it. **That is the fourth instance
of `0041` D1's matcher problem and the second caught before shipping**, against
seven that shipped and failed loudly on first contact.

**Set beside `verify-manifest-coverage.sh`, the pair is the whole argument.** One
instrument was built correctly and never run, and cost two `MISSING` rows nobody
saw for four commits. One proposal was run once, on itself, and cost nothing.
**The difference is not care taken in the design; it is whether anybody executed
it against a real case.**

### What this ledger does not answer

**Whether a reached, firable instrument examines the right thing.**
`iris/verifications.md` owns that and this file does not restate it.

**Whether `ORPHANED 6` is worse than `ORPHANED 3`.** It is not, and the number
cannot say so — `0050` F10. Three of the six arrived by repair and are the tool
working; the count treats them identically to the three that arrived by split.
**A row in this ledger marked *firable* is not a row that can be gated on.**

**Whether any of this holds on the target platform.** Every figure here was taken
in a Linux VM. `verify-script-portability.sh` is the only instrument aimed at that
gap and it reads source rather than running it.

---

## 2026-09-10 — commit to be taken, Revision 299

**What changed.** `0050` D3 carried out. `extract-metadata.py` is deleted; its
`--check` half is `.internal/ai-scripts/session-management/check-metadata-completeness.py`.

**Re-measured, the rows that moved:**

| Instrument | Reached | Firable | Measured |
|---|---|---|---|
| `check-metadata-completeness.py` | **yes** — `check-completeness.sh` `exec`s it | **yes** | 0 problems on the tree. **Fired on all three of its classes** in a throwaway: a dash where `null` belongs, a bold marker in an `ATOMIC` value, and a markdown row that did not become an object |
| `extract-metadata.py` | — | — | **gone** |

**Three capabilities went with it, and all three lived in code nobody was
permitted to run.**

| What | What it did | State now |
|---|---|---|
| the `unclaimed` derivation | scanned every manifest and wrote `"ownership": "unclaimed"` into any bundle no live one listed | **nothing derives it.** `0050` F6's by-hand procedure is now the only one, which it already was in practice |
| `provenance()` | enforced the supersession **coverage** and **exclusivity** gates | **no live enforcer.** They ran only during extraction, and `0050` F3 established extraction must not happen — **so the gates were unenforceable for as long as they were documented**, and the deletion makes that visible rather than causing it |
| `derive_progress` | a second derivation returning member statuses as bundle progress — the collision Revision 233 separated | **removed, and this one is a gain**: one derivation remains where there were two, and the deleted one was the wrong one |

**The first two are `0050` F8's class, found by removing the thing rather than by
running it.** An instrument nobody may run is indistinguishable from an absent
one until somebody deletes it and reads what stopped being true.

**Numbers.** `counts` FAIL 0; `headers` FAIL 11, unmoved; `structure` FAIL 0;
completeness **0 problems, now from its own file**; suite 69 passing;
`stamp --dry-run` writes nothing. doc-paths `--all` **MISSING 8 → 10**: three
records cite the deleted path, one of which is marked here and two of which
belong to other sessions and are flagged rather than edited. Linux VM, Bash
5.1.16, **not the macOS Bash 3.2 target**.

