# Session metadata — restore-apps-outstanding

Authoritative for who and what has owned this bundle. `docs/sessions/INDEX.md`
carries the state and points here.

## Owners

| From | Until | Assistant | Session id | Model | Environment |
|---|---|---|---|---|---|
| 2026-09-03 | — | Claude | `session_016EbjB7M527qEFqZFzpv2C9` | configured `claude-opus-5` | Linux VM, Bash 5.1, GNU coreutils |

Transcript: `https://claude.ai/code/session_016EbjB7M527qEFqZFzpv2C9`

The identifier is the one the harness writes into the `Claude-Session` trailer of
every commit this session authored, so a commit can be traced back to the bundle
and the bundle to the transcript. The configured model is what the session was
started as; the model actually serving any given turn can differ and is not
recorded anywhere the session can read.

## Environment

Every command this session ran executed in a Linux VM on the owner's machine,
with the repository and the artifact volume mounted into it — **not** on macOS.
Bash 5.1 with GNU coreutils, where `mapfile`, `declare -A`, `sed -i` and
`stat -c` all work silently.

**`/bin/bash -n` against real macOS Bash 3.2 is owed for every revision this
session wrote (160–165) and for Revisions 116–159 before it.** Nothing this
session validated was validated on the target platform.

## Resources it worked against

| What | Path |
|---|---|
| Repository | `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit` |
| Artifact root | `/Volumes/Data/reimage-CVG-0002160-500-20260816-open` |
| Workspace root | `/Users/dkittrell/reimage-workspace` — the clone plan and the Docker capture |

All three were read-only for the whole session except the repository working
tree. Nothing on the artifact volume was modified.

## Contributions so far

Revisions 160 through 165, uncommitted at the time of writing except Revisions
160–163, which shipped as `e13f59d`. Finding bundle `0001`.
