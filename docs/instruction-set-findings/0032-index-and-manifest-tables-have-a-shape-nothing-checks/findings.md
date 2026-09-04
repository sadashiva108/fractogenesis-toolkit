# The index and manifest tables have a shape nothing checks

**Recorded:** 2026-09-03, session `session_01PcgHu9kz9Hm5RatLQuFR8H`, from
breaking two of them and not noticing.
**Relates to:** `0031` — the same section, §4c, from the other side: `0031` is a
rule that is missing, this is a rule that exists and is unenforced.
**Severity:** low per instance, and it defeats the check a session actually runs.
Every validator in the repository passed on both broken rows.
**Scope:** instruction set. §§4c–4d define these tables; nothing validates them.
Whether the *fix* belongs here is finding 3.

## Findings

| # | Finding | Status |
|---:|---|---|
| 1 | The indexes and manifests have a required column shape that no check enforces | `unresolved` |
| 2 | `verify-doc-paths.sh` gives false assurance on a malformed row, because links are not shape | `unresolved` |
| 3 | The fix is a lint, so this bundle may be in the wrong tree | `unresolved` |

---

### 1 — a required shape, unenforced

`.github/copilot-instructions.md` §4c and §4d, and the indexes themselves, fix
the columns of five kinds of table: the three findings indexes, the sessions
index, and every session's `findings-manifest.md`. A row with the wrong number of
cells renders as a shifted or truncated row and reads as data.

Two were produced in one sitting, by one session, in one revision:

| Row | File | Cells | Wanted |
|---|---|---:|---:|
| `0009` | `docs/cross-cutting-findings/INDEX.md` | 8 | 7 |
| `0013` | `docs/runbook-findings/INDEX.md` | 9 | 8 |

Both from the same cause: an edit that stripped a trailing `| — |` from the Notes
cell and appended a replacement, leaving `||` where the Session cell ended. Both
were found only because the owner asked for an unrelated change to the `0009`
row, which required reading it column by column. Nothing else would have surfaced
them.

The near miss belongs with them. Earlier in the same session the `phase-11b` row
in `docs/sessions/INDEX.md` was reported to the owner as malformed and was not —
that table had gained a `Bundles` column, and the row was correct. A pipe count
without the header is not a check, and a session doing it by eye will produce both
error directions.

### 2 — the check that runs gives the wrong assurance

`./bin/verify-doc-paths.sh --all` reported **0 MISSING / 0 ANCHOR BROKEN** on both
malformed rows, correctly: every link in them resolved. Link resolution and table
shape are different properties, and the one that is checked is not the one that
broke.

This is the shape of `0026`'s argument from a different angle. There, a baseline
that moves for reasons unrelated to the change makes *"I did not cause it"*
indistinguishable from *"I did not look"*. Here, a validator that passes on a
defect it does not examine makes *"the lints are clean"* indistinguishable from
*"the lints do not cover this"*. A session that quotes a clean run as evidence the
indexes are well-formed is quoting the wrong file.

A shape check is cheap and total: read the header row, count `|` in every data
row, report the ones that disagree. It is the check that was run by hand to find
these two, and it takes about fifteen lines of Bash 3.2.

### 3 — this may be in the wrong tree

Recorded rather than resolved, because the two tests disagree.

`docs/INDEX.md` describes `instruction-set-findings/` as findings about *the rules
a session works under*. The table shapes are such a rule, defined in §§4c–4d, and
`docs/architecture/findings-and-sessions.md` §11.1 already argues that the
structure's invariants are *"currently discipline"* and that write-time
enforcement is the highest-value addition available — which is where this belongs
by subject.

But §4c's own classification test is **where the fix lands**, and the fix is a
lint: a new `bin/verify-index-tables.sh`, or a section added to
`verify-doc-paths.sh`. That is shared machinery, which is
`docs/cross-cutting-findings/`.

The owner routed it here. It is noted because the routing is genuinely arguable
and a later reader should see that it was a choice rather than an oversight —
and because if the answer is *cross-cutting*, `0027` finding 1's question
(*where is a rule allowed to live*) reaches this bundle too.
