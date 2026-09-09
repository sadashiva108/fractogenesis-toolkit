# Knowing what you have read

**Written:** 2026-09-09, `assurance-coverage-20260908-204724`, from the owner's  
question whether a manifest of hashes would tell a session its rules had moved.  
**Scope:** how a session could know that a rule document changed since it read it.  
**Reads against:** [`0053`](../session-management-findings/0053-the-rules-are-versioned-and-a-sessions-reading-of-them-is-not/),
[`0050`](../session-management-findings/0050-instruments-that-cannot-fire-and-one-that-unmakes-the-record/),
[`rule-enforcement-avenues.md`](../rules/rule-enforcement-avenues.md).  
**Status:** **a commission. Nothing here is decided and nothing is built.**

An intent to build gets a file here, with no status, no owner and no lifecycle —
`typed-bundles-and-work.md` §1, quoted by `rule-enforcement-avenues.md` §8, which
is a blueprint in the same position. `0053` is the reading; this is the shape.

---

## 1. The question, as the owner put it

> Maybe a manifest could be updated every commit with git hashes for all critical
> files? That way only these need to be checked and if they don't indicate any
> changes then there's no need to re-read them.

The instinct is right and the second half is the whole value: **a cheap check
that usually says *nothing moved*, so re-reading is rare rather than ritual.**

## 2. Half of it already exists, and it is not the manifest

Git stores the content hash of every tracked file at every commit:

```text
git rev-parse HEAD:.github/session-management-instructions.md
```

That is authoritative, free, and impossible to forget to update. **A manifest
listing the same hashes would be a second copy of a fact git already owns**,
maintained by a commit hook that can fail silently — and `docs/legend.md` permits
a copy only where it is generated or where a check fails when it drifts. A hash
manifest that goes stale is `0041` F6 with SHAs in place of counts, and both of
F6's instances were wrong for days while every checker passed.

**What is missing is the other operand: which version this session read.** No
field anywhere holds it. `metadata.json` records who the session is, what it
owns and where it ran; nothing records the state of the rules when it read them.

## 3. The shape

**One field.** A session's `metadata.json` gains `readAt` — for each foundational
path, the blob it was read at and the date:

```text
"readAt": {
  ".github/session-management-instructions.md": { "blob": "2f53282e", "on": "2026-09-09" },
  "docs/legend.md":                             { "blob": "…",        "on": "2026-09-09" }
}
```

**One comparison.** *Refresh* stops meaning *read it all again* and starts
meaning *find out what moved*:

```text
for each path in readAt:
    stored blob  vs  git rev-parse HEAD:<path>
```

Non-empty result names exactly the files to re-read. Empty result is the common
case and costs one `git rev-parse` per path.

**No manifest, no commit hook, nothing to keep in sync.** The only new datum is
the one nobody has.

## 4. Where it would fire

`.claude/settings.json` wires `PreToolUse` and `PostToolUse` and uses neither
`SessionStart` nor `UserPromptSubmit`. The comparison belongs in
`UserPromptSubmit`, injecting the drifted set as `additionalContext` when it is
non-empty and staying silent otherwise.

**It must not key on the word *refresh*.** In the instance `0053` records, the
owner did say refresh, and the session re-read the wrong subset. A check that
fires every turn and names the files that moved would have caught it whatever the
owner typed. Keying on a word makes the instrument depend on the phrasing of the
person it exists to protect.

## 5. The false positive, before anything is built

**First run, every session: no `readAt` exists, so every foundational file reads
as moved.** That is the retrofit trap and it would fire on every session at once.

The mitigation is the same forward-only shape `0051` D3 takes: an **absent**
baseline injects one line — *no read recorded for this session* — and the full
drift list appears only once a baseline exists. A session that has recorded
nothing is told to record, not handed eighteen paths.

**Second-order:** a file that changes for a reason that cannot affect a rule — a
typo fix, a reflow — reports as drifted and costs a re-read. That is acceptable
and should not be optimised away by trying to classify changes; a rule document
that changed is a rule document to re-read, and any cleverness there is a second
implementation of judgement.

## 6. What it cannot do

**It cannot make a session read.** It injects text; a session that skims the
injection fails identically to one that never got it. The avenue is `guard` for
the notification and `person` for the reading —
`rule-enforcement-avenues.md` §2 — and claiming otherwise would be `0041` F2, a
check quoted for a property it does not examine.

**It says nothing about untracked or uncommitted rules.** A blob exists at
`HEAD`; a rule edited and not yet committed has none. That is the correct
failure and should read as *unknown*, not as *unchanged*.

## 7. Its relationship to the watch that already exists

`doc-currency.json` watches **documents going stale against their sources** — is
`.claude/CLAUDE.md` still true about the hooks. This watches **a reader going
stale against a document**. Same mechanism, opposite direction, and they should
not be merged: one is about the tree's internal consistency, the other about a
session's knowledge of it.

**Both are unarmed today.** Arming the existing one is one command per watch and
would have caught `0053`'s instance by itself:

```text
./bin/verify-doc-currency.sh --confirm session-rules
```

**That is the cheaper half and it should land first.** This commission is worth
nothing if the instrument the repository already has stays at
`sourceDigest: null` — which is `0050` F4, and the reason `0053` records the
watch and the missing field as two findings rather than one.

## 8. What this does not settle

Which foundational paths are in scope. `.claude/CLAUDE.md` names six
destinations and `rule-enforcement-avenues.md` names a precedence order of six
ranks; those are not the same list, and choosing one is a decision rather than a
derivation.
