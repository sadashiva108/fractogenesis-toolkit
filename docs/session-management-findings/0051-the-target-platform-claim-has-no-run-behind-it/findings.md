# The target-platform claim has no run behind it, nowhere to record one, and no gate that needs one

**Recorded:** 2026-09-09, after the owner asked what would resolve a disclosure every session repeats.  
**Session:** `assurance-coverage-20260908-204724`  
**Severity:** F1 is low and permanent — no session can ever close it, which is the part worth writing down. F2 is the one that costs: with nowhere to record a target run, the first one ever performed would have been lost, and it produced the only cross-platform evidence this repository has.  
**Felt at:** every session `metadata.md` and every handover report since Revision 206; `.github/session-management-instructions.md` §5 and §6; `docs/ledgers/`  
**Scope:** session management for the rule, the toolkit set for the platform it names. `0039` D2's split applied to verification.  
**Relates to:** `0042` — its F5 was inferred from a Linux run and is now confirmed on the target; this bundle is why that confirmation had nowhere to live  
**Relates to:** `0041` — its D5 requires a resolution to name a verifiable referent. A platform is part of the referent and the schema has no field for it

**Read:**

- `.github/session-management-instructions.md` §5, §6 and §9b
- `.github/toolkit-instructions.md`, the portability paragraphs
- `bin/verify-script-portability.sh` in full
- every `metadata.md` under `docs/sessions/`
- the owner's macOS run of three checkers, 2026-09-09

Recorded by the session that hit it. **Owned here**, at the owner's direction on
2026-09-09, and decided the same day.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | No session can reach the target platform, and the disclosure that says so is repeated where it cannot apply | `decided` |
| F2 | A run on the target platform has nowhere to be recorded, so the first one ever performed nearly was not | `resolved` |
| F3 | Nothing requires a target-platform run before a script finding may be resolved | `decided` |

## F1 — the gap is real, permanent, and mostly already closed

Every session's `metadata.md` and every handover says some form of *nothing ran
on macOS stock Bash 3.2 and BSD userland; every number is Linux/GNU.* It is true.
It is also **three claims in one sentence**, and two of them are not open:

| Layer | Covered by |
|---|---|
| Bash 4+ syntax — `mapfile`, `declare -A`, `readarray` | `bin/verify-script-portability.sh`, which **reads rather than executes**, so a Linux result carries |
| GNU-only flags — `sed -i`, `stat -c`, long options | the same lint, which names each explicitly |
| runtime behaviour under a real Bash 3.2 and BSD userland | **nothing** |

**Only the third is open, and no session can close it.** The session shell is a
Linux VM running *on* the owner's Mac — not macOS. Tested 2026-09-09: the VM has
no `bash` 3.x, `apt` offers only 5.1, and its egress refuses `ftp.gnu.org`; the
cloud container refuses the same host and gates the GitHub mirror. **A target
platform cannot be manufactured on either side of the bridge**, and a future
session reading this should not spend time trying.

**The cost is not the gap. It is the disclosure appearing where the gap cannot
bite.** A change set touching only `docs/` runs no script differently, so the
sentence is true and irrelevant — and a disclosure that appears on every report
regardless of whether it applies teaches a reader to skip the one where it
matters. That is `0026`'s argument about a baseline that moves for unrelated
reasons, in the disclosure layer.

## F2 — the first target run had nowhere to go

On 2026-09-09 the owner ran three checkers on the Mac, under
`/bin/bash` — **GNU bash 3.2.57(1)-release (arm64-apple-darwin25)**, the exact
shell the toolkit set names as the target — against commit `4b721e7`, Revision
250, a clean tree.

**Every number matched the Linux run on the same commit, exactly:**

| Check | Value | macOS 3.2.57 | Linux 5.1.16 |
|---|---|---:|---:|
| portability | Files · CLEAN · SUPPRESSED · WARN · FAIL | 90 · 90 · 2 · 0 · 0 | **same** |
| doc-paths `--all` | Documents · OK · WARN · SKIP | 215 · 1835 · 277 · 10 | **same** |
| doc-paths `--all` | PROPOSED · HISTORICAL · MISSING | 11 · 62 · 0 | **same** |
| doc-paths `--all` | ANCHOR OK · ANCHOR BROKEN | 1156 · 0 | **same** |
| headers | OK · FAIL, and the same eleven rows | 1029 · 11 | **same** |

**Eighteen values, no divergence.** And `0042` F5 reproduced on the target:
`bin/verify-doc-paths.sh` printed both `command not found` lines under Bash 3.2
exactly as it does under Bash 5, which moves that finding from inferred to
confirmed.

**This is the only cross-platform evidence the repository has ever had, and until
this bundle there was no file it belonged in.** A session `metadata.md` records
the environment a *session* ran in, which is the wrong object; a `resolutions.md`
row has `Revision` and `Commit` and no field for a platform. The run would have
survived as terminal scrollback and nothing else.

## F3 — nothing requires the run

§6 gates a toolkit write on a `decided` finding. §9b sets out how a finding is
resolved. **Neither mentions the platform**, so a script change may be composed,
verified on Linux, applied and resolved without anyone having run it where it
will actually run.

Nothing has gone wrong because of this yet, and the reason is that
`verify-script-portability.sh` catches the two static layers well — 90 files
clean on both platforms. **The exposure is the third layer**: a script that runs
on both and behaves differently, which no check in this repository would see and
no rule currently asks about.

This is the same shape as `0041` F5. There, `resolved` asserts something about
the tree that nothing examines. Here, a resolved script finding asserts something
about a platform that nothing examines and nobody was required to visit.
