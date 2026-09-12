
# Big Picture

I want to step back and see the "Big Picture" this isn't an idea as such but more of clarifying what we have, asking if it's what we want, and saying what needs to change and what's missing.

## Architecture Review (Audit what we know today and what still stands, and decide what we want to change, and document what is missing)

A. Review what IRIS does. What it is purpose and why do we care?
B. Identify named layers in IRIS design (each of these layers may be listed as a focus group below)
   I use layer instead of component because it's about system behavior not what it's comprised of. 
C. Identify the scope of each layer.
D. Identify the responsibilities of each layer.
E. Do any layers overlap? If so how so? Map out these layer interactions.
F. Are there any mutually exclusive layers? Is it independent of changes in the design of another layer?
E. What layers are missing?

## Focus Groups (May change depending on what comes out of the Design Review)

### Documentation: 

All `IRIS` system layers require documentation.
We need to discuss what is meant by `documentation` and what types exist or need to exist.
How and when to create new documentation or modify existing and by whom or what process?
Adhere to `single source of truth` where possible.
How do we avoid documentation drift?
`System Documentation` shouldn't lag the system.
`Ideation Documentaton` is ahead of the system and is only in potential. Numerous idea candidates may be proposed but many will be rejected or not acted upon. An accepted idea candidate becomes a commission.
`Commission Documentation` is ahead of the system and is eventual but ammendable. 
`Blueprint Documentation` bridges the gap from current state to future state. It is more technical than commission documentation and closes the gap between current IRIS and future IRIS and how to go from current to future. It's the implementation instructions for how to build it.
`Charter Documentation` is the authorization to build and the set of blueprints at that point in time will be capture as a version. 
`Change Request Documentation` realistically there will be changes to the system or even a proposed design or even the blueprints for implementing that design. Change Requests need to be documented, but where, when and how? A vocabulary needs to be established.
- Amendments to Blueprints
- Amendments during the Implementation or Build
- Amendments to the existing system - Is it a commission or something else?

### Transitions: 
`IRIS` is static without them, they drive the systems' movement.
There can't be transitions without state. 

A. Which layers are dynamic and have state?
B. Which components in that layer hold state?
C. What are their stateful properties and the vocabulary surrounding them?

D. Identify The Transitions
Define a components `transition space` by finding the complete mapping of its dynamic properties and their valid successor values.

E. When Do They Change and Why and by Whom
For each layer, for each component, for each transiton in it's `transition space` define when, why, and by whom does the state change.

F. Privileges
For each layer, for each component, for each possible state, what are its privileges?

G. Notification
Who knows when a transition occurs?
What is the mechanism for notification?
Are there gaps?

### Detection and Verification
`IRIS` verifies documents. It has never verified an event.
Verification depends on detection: you cannot check a transition that nothing emits.

**The evidence, measured 2026-09-11.** Five projections disagreed with their source
across 613 rows and **not one was found by an instrument** — two by the owner
reading rows by eye, two by sessions rechecking their own work, one by a session
reading its own table back after being questioned.
`verify-findings-structure.sh` **passed 70 of 70 while a session manifest's copy of
a standing was wrong**, because a session manifest is not on the path it walks. The
check was correct, ran, and reported nothing. It was pointed at a file rather than
at the event *a standing moved*.

#### Detection

A. What is an event here? Today a member moves because someone edits
   `metadata.json`. Nothing emits *`0047` F13 moved `framing` → `resolved`*. The
   change is visible; the event is not; the reason is in prose.
B. `state-as-data.md` §6.1 is already the derivation graph — eleven outputs, one
   row per source, each column's origin named — **and nothing executes it.**
   Measured: **zero generated regions exist in the tree.** Making §6.1 data rather
   than documentation is the cheapest first move on this page, because the design
   exists, the population is known, and only the mechanism is absent.
C. Which invalidations can only be known by the actor, and must be **declared** at
   the moment of the act? Which can be **derived** from the graph in B?
D. Is anything genuinely global besides **staleness at read time** — a session
   holding an old version of a rule? That is `0053`, already recorded.

**On an "all-seeing" entity.** Worth stating the objection early, because IRIS
already has one that does not work: `verify-manifest-coverage.sh` is correct, fires
correctly, and **is executed by nothing** — not in the dispatcher, not in `all`, no
caller in the tree (`0050` F8). A global watcher fails the same way: it must be
invoked, it must know every derivation, and the day it misses one nobody finds out.
The actor knows what it changed; a watcher has to infer it. **Prefer declaration at
the act over inference after it** — which is `0038` D9, and the single lesson that
recurred in five different disguises over two days.

#### Verification

Four positions relative to an act. `IRIS` has the last one.

| When | Question | Fails how | Today |
|---|---|---|---|
| **before** | may this actor do this at all? | refuses | §6's gates, by discipline only |
| **during** | is the act well-formed? | aborts | nothing |
| **immediately after** | are its consequences complete? | reports | nothing |
| **eventually** | is the tree still consistent? | reports | every checker we have |

E. The gap is the third row, and every projection drift lived in it: the act was
   legal, the act was well-formed, the tree was inconsistent, and the sweep that
   would notice runs when someone remembers.
F. Which verifications are **atomic to one act** and which are **rollups** over
   derived or aggregate state? A total summed from its rows is a rollup; a standing
   derived from members is atomic to a member move.
G. A guard **refuses** and a checker **reports**. Revision 280 requires a guard to
   be shown both not to fire on correct work **and** to fire on a case it should
   catch. Does that bar apply to an immediately-after check, which reports but is
   bound to an act?
H. What happens when detection is unavailable? **A check that cannot observe its
   event must say so rather than pass.** Every silent pass in this system has cost
   more than a loud failure.

#### What to be careful of, from the record

- **A count cannot distinguish a row nobody cleared from a row nobody may clear.**
  Those are opposite signals — one means the framework is failing, the other means
  it is working — and they read identically. `0047` F9, which recurred *inside* the
  ledger built to prevent it.
- **A metric can acquire a vote it should not have.** `0050` F10: writing a correct
  late entry moved `ORPHANED` further from its baseline, so the instrument argued
  against its own repair.
- **The population is never what you think.** `0041` D6 predicted a silent first run
  because both known instances were repaired, was built anyway, and fired on a third
  nobody had counted. **Expect the first run of any detection layer to report
  nothing, and do not read that as working.**
- **A defect invisible in the owner's tree stays invisible.** `0012` D2 was accepted
  2026-09-04 and went uncarried-out for **115 revisions** — an empty untracked
  directory that made ten citations resolve for one person and break for everyone.
  It was found because a figure disagreed between a checkout and a clone.
- **Describing a defect can create one.** Citations of that directory grew from 10
  to 17 across four revisions, because every document written *about* it cited it.

### Versioned Layers
APPLY-MANIFEST.md is growing too large and not maintainable in its current state.
Instead, adapt to a rolling manifest that is timestamped with older ones compressed similar to logs.

A. What Gets Versioning and Why
B. What kind of Versions Control for Each Versioned Layer
C. Who Controls Versions
D. Who Detects a Version and for What Purpose?
E. Explore Using Versioning for Drift Prevention

### Where Is Home
`IRIS` is built to be project agnostic so it's system files need to live outside the project that uses it.
However, `IRIS` is not stateless in conjuction with project use, it develops project memory.

A. Where does `IRIS` live?
B. Where does the `memory space` generated by `IRIS` live?
C. Which files in the project need to be added or changed when using `IRIS`?
D. Where does the versioning live?

### Generated Files
`IRIS` creates many different types of entities and are required to benefit from its capabilities.

A. What are the various file types and/or bundles that get generated?
C. Audit Reports
D. Checker Reports
E. Version Control Files
F. Architecture
G. Ideas
H. Session Bundles
I. Reasonables and Actionables

### Rules, Instruction Sets, Prompts, and Instruments
What are these? How do they differ? Who controls their creation and maintenance?
Which ones are part of `IRIS` itself versus `IRIS` project use?