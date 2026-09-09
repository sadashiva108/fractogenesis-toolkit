# The rules are versioned and a session's reading of them is not

**Recorded:** 2026-09-09, after a session followed a rule that had been replaced four revisions earlier and the owner asked how it had missed it.  
**Session:** `assurance-coverage-20260908-204724`  
**Severity:** F1 is the mechanism and is moderate — it costs a wrong rule followed confidently, which is worse than a rule not found. F2 is the instrument that exists for it and has never been in a position to fire.  
**Felt at:** every session bundle's `metadata.json`; `.internal/ai-scripts/session-management/doc-currency.json`; `.claude/settings.json`  
**Scope:** session management. The fix is one field, one comparison, and arming a watch that already exists.  
**Relates to:** `0050` — F2 here is that bundle's F4 with an instance attached; the `session-rules` watch is F4's first member  
**Relates to:** `0039` — its F22 records the same watch unarmed from the configuration side  
**Relates to:** `0041` — its D1 is why an unarmed watch is worse than an absent one: the run reports clean and the gap is free

**Read:**

- `.claude/CLAUDE.md` and `.github/copilot-instructions.md`, following the pointer chain
- `.github/session-management-instructions.md` at blob `2f53282e` and at `08332e73`
- `.internal/ai-scripts/session-management/doc_currency.py` and `doc-currency.json`
- `.claude/settings.json`, and the hook events it does not use

Recorded by the session that hit it, and **assigned to it by the owner on
2026-09-09**, together with `0050`. Read on assignment, so every finding is
`framing`.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | A session records what it read and never which version, so nothing can tell it a rule has moved | `framing` |
| F2 | The instrument that would say so is `critical`, correct, and has never been armed | `framing` |
| F3 | No watch covers `references/`, `docs/rules/`, or most of `docs/architecture/` | `framing` |

## F1 — a read is a point-in-time fact and the record does not treat it as one

`.claude/CLAUDE.md` names `.github/session-management-instructions.md` as
**required reading before any write under `docs/`**. One hop, unambiguous, and
the pointer chain is not at fault.

**What the record has no field for is which version was read.** A session's
`metadata.json` carries `owners`, `resources`, `transcript` and `scratchPath`;
its `metadata.md` carries the environment it ran in. Every one of those is a
fact about the session. **None is a fact about the state of the rules when it
read them**, and the rules are versioned files in a repository that moved
**fourteen revisions between Revision 238 and Revision 252 on one day.**

### The instance

| | |
|---|---|
| Read in full at session start, blob | `2f53282e` — Revision 234 plus uncommitted 235-236 |
| The commit-message rule requiring a fenced block entered at | **Revision 240**, commit `43714f6`, blob `08332e73` |
| Occurrences of that rule in the version read | **0** |
| What the session did | handed the message over as prose, which is the defect `0039` F23 records |

**And the owner had said to re-read.** The instruction was *"reread starting from
`.claude/CLAUDE.md` then again starting from `.github/copilot-instructions.md`…
to ensure you are examining the most recent changes and the critical ones."* The
session re-read both of those, and five findings bundles, **and skipped the file
the rule was in**, because it had already read it once.

**That is the finding.** Not that the session was lazy — it re-read on
instruction — but that *already read it* is a claim nobody can check, including
the session making it. The comparison that would settle it needs no new
machinery: `git rev-parse HEAD:<path>` returns the blob a file is at now, and git
has stored it all along. **What is missing is the other operand.**

### What it is not

**Not a missing manifest.** A file listing the hashes of critical documents,
refreshed by a commit hook, would be a second copy of a fact git already owns and
a hook that can fail silently — which is `0041` F6 with SHAs in place of counts,
and both of F6's instances were wrong for days. The current hash is free and
authoritative. **Only the baseline is absent.**

## F2 — the watch is correct, critical, and has never been armed

`.internal/ai-scripts/session-management/doc-currency.json` carries a watch built
for exactly this: id `session-rules`, tier `critical`, sources
`.github/session-management-instructions.md` and `docs/legend.md`, dependents
both session prompts, `.claude/CLAUDE.md`,
`docs/architecture/findings-and-sessions.md` and
`docs/sessions/session-responsibilities.md`.

**Every field is right and it cannot fire.** `sourceDigest` is `null` and
`confirmedAt` is `null`, and `doc_currency.py`'s `evaluate()` tests the null
before it compares, so the watch reports `UNCONFIRMED` and can never reach
`DRIFTED`. Seven watches, **zero armed**, since Revision 232 created them.

Arming it is one command per watch. It was not run, and nothing reports that it
was not run except `--coverage`, which returns 0.

**This is `0050` F4's first member with the cost attached.** That finding names
four instruments that are correct and cannot do their job; this is what one of
them not doing its job actually produced — a session following a rule that had
been replaced, on the day the owner asked it to check for exactly that.

**And it is `0041` D1's argument at the smallest scale.** An unarmed watch is
worse than an absent one: the run is clean, the non-zero exit is explained away
as *never confirmed*, and the gap costs nothing to leave. A gap that is visible
and free is a gap.

## F3 — the categories a reader most needs watched have no watch at all

The seven watches cover 30 files. Their dependents are the two session prompts,
`.claude/CLAUDE.md`, `README.md`, three architecture records, one ledger and the
session-management scripts and tests.

**Nothing watches:**

| Category | Files | Watched |
|---|---:|---|
| `references/` — the toolkit's reference documents | 11 | **0** |
| `docs/rules/` | 1 | **0** |
| `docs/architecture/` | 11 | 4 |
| `docs/ledgers/` | 6 | 1 |
| repository-root runbooks | 31 | 0 |

Every one of those describes something that lives elsewhere and changes without
them. `references/environment-variable-reference.md` describes `reimage.env.example`,
which is a **source** in the `environment` watch and has no edge to the reference.
`references/toolkit-environment-reference.md` and
`references/master-directory-reference.md` are in the same position.

**This is not the same finding as F2.** F2 is that the watches which exist have
never been armed. F3 is that the watches which would cover these categories were
never written. Arming fixes nothing here, and extending fixes nothing while
unarmed — which is why the order matters and why they are two findings.

