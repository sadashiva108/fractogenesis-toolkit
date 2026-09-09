# Target-platform verification

**What this is.** Every run of this repository's checks on the platform the
toolkit actually targets — **macOS stock Bash 3.2 and BSD userland** — recorded
beside the same run on the session platform, so the two can be compared rather
than assumed equal.

**Why it exists.** A session cannot reach the target. The session shell is a
Linux VM running *on* the owner's Mac, not macOS, so every number a session
reports is Linux with GNU coreutils. Until this file there was nowhere to put a
run that was not, and the first one ever performed would have survived as
terminal scrollback. `0051` F2.

**Who runs it.** The owner, at a terminal. `0051` D3 makes that the avenue
deliberately — `docs/rules/rule-enforcement-avenues.md` §5.1 is exact that
nothing can see who is writing, and here the actor is not a session at all.

**Invoke the target shell explicitly.** `#!/usr/bin/env bash` resolves to
Homebrew's Bash 5 where one is installed, so `./bin/<check>.sh` may test the
session platform twice. `/bin/bash ./bin/<check>.sh` is the difference.

**Every value, never a verdict.** A verdict cannot be compared against a later
run, and the question this file answers is never *did it pass* but *did it
differ*.

---

## 2026-09-09 — commit `4b721e7`, Revision 250

| | |
|---|---|
| Target | `GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)`, `/bin/bash` |
| Session platform | Linux VM, `GNU bash 5.1.16(1)-release (aarch64)`, GNU coreutils |
| Tree | commit `4b721e7`, clean, no uncommitted work |
| Run by | the owner, in Terminal.app |
| Occasion | the first target-platform run this repository has had |

| Check | Value | Target | Session |
|---|---|---:|---:|
| `verify-script-portability.sh` | Files | 90 | 90 |
| | CLEAN | 90 | 90 |
| | SUPPRESSED | 2 | 2 |
| | WARN | 0 | 0 |
| | FAIL | 0 | 0 |
| `verify-doc-paths.sh --all` | Documents | 215 | 215 |
| | OK | 1835 | 1835 |
| | WARN | 277 | 277 |
| | SKIP | 10 | 10 |
| | PROPOSED | 11 | 11 |
| | HISTORICAL | 62 | 62 |
| | MISSING | 0 | 0 |
| | ANCHOR OK | 1156 | 1156 |
| | ANCHOR BROKEN | 0 | 0 |
| `verify-session-findings.sh headers` | OK | 1029 | 1029 |
| | FAIL | 11 | 11 |
| | failing bundles | `0030` ×8, `0035` ×3 | `0030` ×8, `0035` ×3 |

**Eighteen values, no divergence.**

**And one defect reproduced on the target.** `bin/verify-doc-paths.sh` printed

```text
./bin/verify-doc-paths.sh: line 39: reading: command not found
./bin/verify-doc-paths.sh: line 40: rather: command not found
```

under Bash 3.2 exactly as under Bash 5 — both lines, to stderr, exit status 0.
That moves `0042` F5 from inferred to confirmed, and it is the reason this run
was worth recording rather than merely passing.

### What this run does and does not license

**It supports** the standing claim that `verify-script-portability.sh`'s result
carries from the session platform to the target: it reads for constructs rather
than executing them, and it agreed to the digit.

**It does not support** a general claim that the checks are platform-independent.
Three checks were run of the eleven instruments in `bin/`. `verify-runbook-structure.sh`,
`verify-session-findings.sh structure` and `counts`, `verify-doc-currency.sh`,
`verify-artifact-config.sh`, `plan-findings-work.sh check`, `review-changes.sh`
and `test-session-management.sh` **were not run on the target and are unmeasured
there.**

**It says nothing about the runbook scripts**, which are the executables that
actually run during a reimage. Nothing in `bin/backup-*.sh`, `capture-*.sh`,
`restore-*.sh` or `record-*.sh` has been exercised on the target by this or any
recorded run.
