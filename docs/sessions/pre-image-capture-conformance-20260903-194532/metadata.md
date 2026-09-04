# Session metadata — pre-image-capture-conformance

Authoritative for who and what has owned this bundle. `docs/sessions/INDEX.md`
carries the state and points here.

## Owners

| From | Until | Assistant | Session id | Model | Environment |
|---|---|---|---|---|---|
| 2026-09-03 | — | Claude | `session_01PcgHu9kz9Hm5RatLQuFR8H` | configured `claude-opus-5` | Linux VM on the owner's Mac, Ubuntu 22.04, Bash 5.1.16, GNU coreutils, aarch64 |

Transcript: `https://claude.ai/code/session_01PcgHu9kz9Hm5RatLQuFR8H`

The identifier is the one the harness writes into the `Claude-Session` trailer of
every commit this session authored, so a commit can be traced back to the bundle
and the bundle to the transcript. The configured model is what the session was
started as; the model actually serving any given turn can differ and is not
recorded anywhere the session can read.

## Environment

The assistant runs in an Anthropic-hosted cloud container. **Every command this
session ran executed somewhere else** — a Linux VM on the owner's machine,
reached over the desktop bridge, with the repository mounted into it. Ubuntu
22.04, Bash 5.1.16, GNU coreutils, aarch64 — **not** macOS, and not the cloud
container either. `mapfile`, `declare -A`, `sed -i` and `stat -c` all work
silently there.

**`/bin/bash -n` against real macOS Bash 3.2 is owed for every revision this
session touches, as it is for Revisions 116 onward.** Nothing this session
validated was validated on the target platform.

## Scratch path

Nothing is composed in the working tree. This session works in a copy of the
repository held outside every connected folder, at one stable path for the
whole session:

```text
/sessions/rcw-01pcghu9kz9hm5ratlqufr8h/scratch/fractogenesis-toolkit
```

The copy was taken from the live tree at `46dab58` with `git status` clean, and
is refreshed whenever a push lands and immediately before any patch is derived
from it — refreshed to `8f1ce13` on 2026-09-03, after Revision 177 landed. The reasoning is
[`docs/cross-cutting-findings/0028-sessions-write-into-the-tree-the-owner-commits-from/findings.md`](../../cross-cutting-findings/0028-sessions-write-into-the-tree-the-owner-commits-from/findings.md).
The copy is session-local scratch and dies with the session: unapplied work is
lost if the session ends unexpectedly.

## Resources it worked against

| What | Path |
|---|---|
| Repository | `/Users/dkittrell/workspace/shiva/fractogenesis-toolkit` |
| Artifact root | `/Volumes/Data/reimage-CVG-0002160-500-20260816-open` |
| Workspace root | `/Users/dkittrell/reimage-workspace` |

The artifact root is **read-only to this session** and was not connected, read or
written. The workspace root likewise. Nothing outside `docs/` is written by this
session at all.

## Contributions so far

None. This session is a reading session: its output is a report in the
conversation and this bundle.
