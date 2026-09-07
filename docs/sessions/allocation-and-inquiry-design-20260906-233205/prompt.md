# Prompt — allocation-and-inquiry-design

## The conformant half

This session was opened with the workspace's conformant session prompt as it
stood at **Revision 206**. **Refreshed 2026-09-07 against Revision 217**, which
is the tree this session is now working on.

**What changed under it since it was pasted, in order:** `0043` was recorded and
is deliberately open (R210); this session's own architecture landed (R211); the
allocator was run and corrected the record that proposed it (R214); the edge
contract became `0043` D1 and D2 (R215); `docs/architecture/state-as-data.md`
designed the format the graph reads (R216); and **six rules that had accumulated
in the conformant prompt itself were installed in the instruction set under an
owner override** (R217), which is `0039` F9. That last one matters to this file:
the conformant prompt is no longer the only home for those rules, and where it
still states them it is a copy.

**The verbatim copy is owed here and is not yet in place.** The conformant prompt
lives in `/Users/dkittrell/reimage-workspace`, which is not a connected folder
for this session, so it cannot be copied in without inventing it. It is recorded
by revision rather than transcribed from memory, and the copy lands when that
folder is connected.

Nothing in Revisions 207 through 210 contradicts the conformant prompt. What it
does not yet carry: `0043` exists and is open to any session; the manifest
revision has moved from 206 to 210.

## The session half

Design one architecture from two briefs the owner wrote separately —
`findingsbundlesallocationandprioritization.md` and
`presentfindingsbylogicprioritizaton.md`. They are one problem: both are
orderings over a graph of findings. Allocation partitions that graph; inquiry
traverses it.

The goal is a better working experience for the owner — less to read in each
response, fewer decisions per turn, and no loss of precision in the mechanics —
while every connection, state change, rule, validation and detection in the
existing framework is accounted for rather than approximated.

### Reading order

1. `.github/copilot-instructions.md`
2. `.github/session-management-instructions.md`
3. `docs/legend.md`
4. `docs/INDEX.md`, then the four findings `INDEX.md` and `docs/sessions/INDEX.md`
5. `docs/architecture/findings-and-sessions.md` and
   `docs/architecture/transferring-part-of-a-bundle.md`
6. `docs/ideas/knowing-when-it-is-safe-to-write.md`
7. `docs/session-management-findings/0043-framework-state-lives-in-documents-not-data/`

### The task, in order

1. Merge the two briefs into one design. **Done as an outline; not yet written.**
2. Settle the allocation unit. **Decided 2026-09-06: bundles stay atomic** —
   option A/C of `docs/architecture/transferring-part-of-a-bundle.md`, modelling
   at finding level, allocating whole bundles. Chosen on limited owner time and
   on the argument that finer ownership improves throughput rather than
   detection. **The architecture must instrument the cost of that choice** so the
   revisit is driven by a measured number rather than another estimate.
3. Record this session's input to `0043`, which is `framing` and open, rather
   than opening a bundle beside it.
4. Write the architecture to `docs/architecture/`, composed in scratch and shown
   inline first.
5. Demonstrate it against the real queue, then against a deliberately bad
   allocation and with the ranking disabled, so the difference is visible.
   **The allocator half is done** — Revision 214, recorded in
   `docs/ledgers/allocation-evidence.md`, including the defect the run found in
   section 4.2 of the record that proposed it. **The interviewer half is not
   run**, and it is the half carrying the cognitive-load claim.

### Decisions this session has taken

| | |
|---|---|
| bundles stay atomic | owner, 2026-09-06. `allocation-and-inquiry.md` §12 |
| ordering is a typed edge | `0039` D5, 2026-09-06, superseding D4 |
| the objective needs a `pull` term | found by running it, R214, `allocation-and-inquiry.md` §4.2 |
| pre-registration before every run | `docs/ledgers/allocation-evidence.md` |

### Standing constraints on the design

- Project-agnostic and assistant-agnostic. It must degrade to a session reading
  the instruction set and doing it by hand.
- No service in front of the filesystem. `docs/architecture/findings-and-sessions.md`
  section 11 rejects that explicitly, and the rejection stands.
- The owner assigns; a session never takes. Anything the allocator produces is a
  proposal.
- A fact has one home. Anything derived is regenerated or checked, never typed.
- Composed in a copy, handed over as a patch, applied by the owner.

### How the owner wants this session to run

One deliverable at a time. Findings before edits. Nothing written to the
checkout until the owner says to write it; drafts are shown inline. A second
defect found while fixing the first is parked as a finding, and named in the
summary.
