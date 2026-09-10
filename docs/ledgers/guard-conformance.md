# Guard conformance

**What this is.** Every pass performed over the hooks in `.claude/hooks/` under
the rule Revision 280 put into `.github/session-management-instructions.md` §6 —
that an instrument which refuses a write is installed warn-only, is shown **not
to fire on correct work** and **to fire on a case it should catch**, and is
promoted to a refusal only then, as a recorded act.

**Why it exists.** The three hooks were installed at Revisions 231, 232 and 246,
each after a rule had already been broken, and **none was run against the tree
first, because nothing said to.** `0047` F6 is that reading; Revision 280 is the
rule; this is where the passes it requires are kept.

**Every value, never a verdict.** A verdict cannot be compared against a later
run. The question is not *did it pass* but *what did it do*, and to what.

**Who runs it.** Any session, in its own copy. Nothing here touches the owner's
checkout: the hooks are fed synthetic payloads on stdin and their stdout is read.

---

## 2026-09-10 — commit `f7ce252`, Revision 281

**Method.** Each hook invoked directly with one JSON object on stdin, as the
harness invokes it. `CLAUDE_PROJECT_DIR` set to the owner's checkout, which is
what the harness sets it to. **Direction A** feeds every tracked file in the tree
as an `Edit` at a path in a session copy — 473 paths, the whole tree, which is
what *correct work* looks like. **Direction B** feeds one write into the owner's
checkout, and one `cp` into it through `Bash`.

### What each hook is

| Hook | Event | Can it refuse? |
|---|---|---|
| `write-location-guard.sh` | `PreToolUse` on `Edit\|Write\|MultiEdit\|Bash` | **yes** — emits `permissionDecision: deny` |
| `session-guard.sh` | `PostToolUse` on `Edit\|Write\|MultiEdit` | **no.** Its own header: *"It always exits 0. PostToolUse runs AFTER the edit; there is nothing left to block"* |
| `runbook-guard.sh` | `PostToolUse` on `Edit\|Write\|MultiEdit` | **no**, same, and it says so the same way |

**Two of the three cannot refuse anything, by construction and by their own
statement.** Revision 280's rule governs one hook here. The other two are
annotators, permanently warn-only, and there is nothing to promote.

### Direction A — 473 paths, every tracked file, as a write in a session copy

| Hook | DENY | note | error |
|---|---:|---:|---:|
| `write-location-guard.sh` | **0** | 0 | 0 |
| `session-guard.sh` | 0 | **0** | 0 |
| `runbook-guard.sh` | 0 | **0** | 0 |

**The first row is a pass.** The guard refuses nothing across the whole tree when
the destination is a session copy, which is what it is for.

**The other two rows are the finding.** Both annotators produced **nothing on any
of 473 paths** — and both do fire when the same path is inside
`CLAUDE_PROJECT_DIR`: `session-guard` on a findings document, `runbook-guard` on
`bin/backup-repos.sh`. **They are scoped to the one directory a session must
never write in.** `0038` F9.

### Direction B — a case each should catch

| Hook | `Edit` into the checkout | `cp … <checkout>` via `Bash` |
|---|---|---|
| `write-location-guard.sh` | **DENY** | **warn only** |
| `session-guard.sh` | silent | silent |
| `runbook-guard.sh` | silent | silent |

**The guard fires, and on the wrong half.** It **denies** an `Edit` into the
checkout and only **warns** on a `cp` into it — and `0049` F4 records that the
Revision 231 guard matched `Edit|Write|MultiEdit` while *"every one of the writes
it was meant to catch was a `cp` inside a Bash call."* **The class that has
actually occurred is the class it warns about.**

### What this pass cannot show

**That the guard is ever invoked.** These payloads were fed to it by hand.
`0045` F4 measures the other half and is not superseded by anything here: the
matchers name `Bash`, a session reaching the checkout through a desktop bridge
calls `mcp__remote-devices__device_bash`, and the hook **has never evaluated a
single write made by this session** — including two into the owner's checkout
that were caught by hand. **A program that behaves correctly when run and is
never run is exactly what Revision 280's second direction exists to separate**,
and one pass over synthetic input cannot separate it. What would is a payload the
harness itself produced, and nothing records one.

### Standing baseline

```text
write-location-guard.sh   A 0 deny / 473 paths        B deny on Edit, warn on Bash
session-guard.sh          A 0 notes / 473 paths       B silent
runbook-guard.sh          A 0 notes / 473 paths       B silent
```

**Neither annotator has been promoted and neither can be.** The guard is not
promoted here either: it already refuses, was never installed warn-only, and
Revision 280's rule is not retroactive — what it is owed is this pass, which is
now on record, and the invocation evidence `0045` F4 says does not exist.
